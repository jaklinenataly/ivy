module EvmL.Syntax where

type Name = String

data OpType =
    OpAdd
  | OpMul
  | OpSub
  | OpDiv
  deriving Show

data Expr =
    PrimInt Integer
  | Identifier String
  | VarDecl String Expr
  | BinaryOp OpType Expr Expr
  deriving Show
