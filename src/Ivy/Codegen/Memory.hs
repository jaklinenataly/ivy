{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE MultiParamTypeClasses #-}

module Ivy.Codegen.Memory where

--------------------------------------------------------------------------------
import           Control.Lens                   hiding (op, ix)
import           Control.Monad
import           Control.Monad.Except
import           Data.Functor                   (($>))
import qualified Data.Map                       as M
import           Data.Monoid
import           Control.Monad.State
--------------------------------------------------------------------------------
import           Ivy.Codegen.Types
import           Ivy.EvmAPI.Instruction
import           Ivy.Syntax
--------------------------------------------------------------------------------

class MemoryM m where
  storeAddressed
    :: Size    -- Variable size
    -> Integer -- Address of the value. Value should be loaded from this address
    -> Integer -- Address to put value on
    -> m ()
  load
    :: Size
    -> Integer
    -> m ()
  storeVal
    :: Size    -- Variable size
    -> Integer -- Actual value
    -> Integer -- Address to put value on
    -> m ()
  alloc
    :: Size
    -> m Integer
  storeMultibyte
    :: Size
    -> m ()

instance MemoryM Evm where
  storeAddressed size valAddr destAddr = do
    -- Initial state
    load size valAddr
    op (PUSH32 destAddr)
    storeMultibyte size

  load size addr = do
    op (PUSH32 (0x10 ^ (64 - 2 * sizeInt size)))
    op (PUSH32 addr)
    op MLOAD
    op DIV

  storeVal size val destAddr = do
    let endDest = sizeInt size + destAddr - 1 -- To store 8 byte on address 10, we start from 17 and go back to 10
    op (PUSH32 val)
    op (PUSH32 endDest)
    op MSTORE8
    forM_ [1..sizeInt size - 1] $ \i -> do
      op (PUSH32 (val `div` (0x100 ^ i)))
      op (PUSH32 (endDest - i))
      op MSTORE8

  alloc size = do
    memPtrs <- use memPointers
    case M.lookup size memPtrs of
      Nothing -> throwError $ InternalError $ "Pointer does not exist: " <> show size
      Just (MemBlock ix allocated) ->
        if totalMemBlockSize - allocated >= sizeInt size
          then
          let
            newPos :: Integer = (allocated + sizeInt size)
          in do
            updateMemPointer size ix newPos
            let baseAddr = calcAddr ix allocated
            let targetAddr = calcAddr ix newPos
            markMemAlloc ix targetAddr
            return baseAddr
        else do
            newIndex <- findMemspace
            let baseAddr = 0
            let targetAddr = sizeInt size
            updateMemPointer size newIndex targetAddr
            markMemAlloc newIndex targetAddr
            return (calcAddr newIndex baseAddr)

  storeMultibyte size = do
    op (PUSH32 (sizeInt size - 1))
    op ADD
    replicateM_ (fromIntegral (sizeInt size)) $ do
      -- Populate value and address for the next iteration
      op DUP2
      op DUP2

      -- Actually store the value
      op MSTORE8

      -- Decrease position by one to go left one position
      op (PUSH32 0x01)
      op SWAP1
      op SUB

      -- Shift number 8 bits right
      op (PUSH32 0x100)
      op SWAP1
      op SWAP2
      op DIV

      -- Swap to restore stack position which is like (address, value) instead of (value, address)
      op SWAP1

    -- Cleanup
    op POP
    op POP

totalMemBlockSize :: Integer
totalMemBlockSize = 32 -- There are 32 bytes in a block

-- O(n)
findMemspace
  :: (MonadState CodegenState m, MemoryM m)
  => m Integer -- newIndex
findMemspace = do
  mem <- use memory
  let msize = fromIntegral $ M.size mem
  (memory %= M.insert msize (0 :: Integer)) $> msize

calcAddr :: Integer -> Integer -> Integer
calcAddr ix allocLen = ix * totalMemBlockSize + allocLen

-- O(logn)
updateMemPointer
  :: (MonadState CodegenState m)
  => Size       -- Which mem pointer will be updated
  -> Integer    -- Index of the block
  -> Integer    -- New allocated size
  -> m ()
updateMemPointer size ix newAllocSize =
  memPointers %= M.alter alter' size
  where
    alter' :: Maybe MemBlock -> Maybe MemBlock
    alter' Nothing =
      error $ "Pointer does not exist for size: " <> show size
    alter' (Just (MemBlock _old_index _old_alloc)) =
      Just (MemBlock ix newAllocSize)

markMemAlloc
  :: MonadState CodegenState m
  => Integer
  -> Integer
  -> m ()
markMemAlloc ix toAlloc = memory %= M.alter (const (Just toAlloc)) ix

allocBulk
  :: (MonadState CodegenState m, MemoryM m)
  => Integer
  -> Size
  -> m Integer
allocBulk len size = do
  msize <- fromIntegral . M.size <$> use memory
  if sizeInt size * len <= totalMemBlockSize
     then -- There are 5 blocks of 4 bytes
       memory %= M.update (updateInc size len) msize
     else do -- There are 15 blocks of 4 bytes
       let fitinLength = totalMemBlockSize `div` sizeInt size -- 32 / 4 = 8 mem blocks can fit in
       memory %= M.update (updateInc size fitinLength) msize
       void $ allocBulk (len - fitinLength) size
  return $ calcAddr msize 0
    where
      updateInc :: Size -> Integer -> Integer -> Maybe Integer
      updateInc _ 0 allocated = Just allocated
      updateInc size' len' allocated = updateInc size' (len' - 1) (allocated + sizeInt size')

sizeof :: PrimType -> Size
sizeof TInt  = Size_8
sizeof TChar = Size_1
sizeof TBool = Size_1
sizeof other = error $ "`sizeof` is not implemented for type " <> show other

initMemPointers :: MemPointers
initMemPointers = M.fromList
  [ (Size_1, MemBlock 0 0)
  , (Size_2, MemBlock 1 0)
  , (Size_4, MemBlock 2 0)
  , (Size_8, MemBlock 3 0)
  , (Size_32, MemBlock 4 0)
  ]

initMemory :: M.Map Integer Integer
initMemory = M.fromList
  [ (0, 0)
  , (1, 0)
  , (2, 0)
  , (3, 0)
  , (4, 0)
  ]

boolToInt :: Bool -> Integer
boolToInt True  = 1
boolToInt False = 0

{-|
Given the size and necessary stack state, stores that much byte properly aligned.
For instance, we want to store 2 bytes of data at 0x0000, so we have the following stack:

00000000
327024A6

And the iterative process:

00000003
327024A6

-> MSTORE8

00000002
00327024

-> MSTORE8

00000001
00003270

-> MSTORE8

00000000
00000032

-> MSTORE8

-> EXIT

-}
sizeInt :: Size -> Integer
sizeInt Size_1  = 1
sizeInt Size_2  = 2
sizeInt Size_4  = 4
sizeInt Size_8  = 8
sizeInt Size_32 = 32
