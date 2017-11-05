{-# LANGUAGE OverloadedStrings #-}

module Ivy.EvmAPI.Instruction where

--------------------------------------------------------------------------------
import           Control.Arrow
import           Control.Applicative
import           Control.Monad.Except
import           Control.Monad.Logger.CallStack (logInfo)
import           Control.Lens hiding (op)
import           Control.Monad.State
import           Control.Monad.Writer
import qualified Data.Text              as T
import           Text.Printf
--------------------------------------------------------------------------------
import           Ivy.Codegen.Types
import qualified Ivy.Syntax             as S
--------------------------------------------------------------------------------

data Instruction =
    STOP
  | ADD
  | MUL
  | SUB
  | DIV
  | ISZERO
  | POP
  | MLOAD
  | MSTORE
  | MSTORE8
  | JUMP
  | JUMPI
  | PC
  | JUMPDEST
  | PUSH1
  | PUSH2
  | PUSH32
  | DUP1
  | DUP2
  | SWAP1
  | SWAP2
  | LOG0
  | LOG1
  | LOG2
  | RETURN
  | ADDRESS

type Opcode = Integer

toInstrCode :: Instruction -> (Opcode, Integer)
toInstrCode STOP     = (0x00, 1)
toInstrCode ADD      = (0x01, 1)
toInstrCode MUL      = (0x02, 1)
toInstrCode SUB      = (0x03, 1)
toInstrCode DIV      = (0x04, 1)
toInstrCode ISZERO   = (0x15, 1)
toInstrCode POP      = (0x50, 1)
toInstrCode MLOAD    = (0x51, 1)
toInstrCode MSTORE   = (0x52, 1)
toInstrCode MSTORE8  = (0x53, 1)
toInstrCode JUMP     = (0x56, 1)
toInstrCode JUMPI    = (0x57, 1)
toInstrCode PC       = (0x58, 1)
toInstrCode JUMPDEST = (0x5b, 1)
toInstrCode PUSH1    = (0x60, 1)
toInstrCode PUSH2    = (0x61, 2)
toInstrCode PUSH32   = (0x7f, 32)
toInstrCode DUP1     = (0x80, 1)
toInstrCode DUP2     = (0x81, 1)
toInstrCode SWAP1    = (0x90, 1)
toInstrCode SWAP2    = (0x91, 1)
toInstrCode LOG0     = (0xA0, 1)
toInstrCode LOG1     = (0xA1, 1)
toInstrCode LOG2     = (0xA2, 1)
toInstrCode RETURN   = (0xf3, 1)
toInstrCode ADDRESS  = (0x30, 1)

-- | Instructions other than JUMP and JUMPI increase PC by 1.
-- See equation (136) in paper http://gavwood.com/paper.pdf
addBC :: Integer -> Evm ()
addBC val =
  byteCode <>= T.pack (printf "%064x" val)

op :: Instruction -> Evm ()
op instr = do
  let (opcode, pcIncr) = toInstrCode instr
  pc += pcIncr
  byteCode <>= T.pack (printf "%02x" opcode)

-- I forgot what this does after 10 minutes
op2 :: Instruction -> Integer -> Evm ()
op2 = curry ((op *** addBC) >>> uncurry (>>))
