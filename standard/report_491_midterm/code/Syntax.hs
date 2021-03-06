-- code/Syntax.hs

data Op =
    OpAdd
  | OpMul
  | OpSub
  | OpDiv
  deriving Show

type Length = Integer
type Index = Integer

data PrimType =
    TInt
  | TChar
  | Array Length PrimType
  deriving (Eq, Show)

data Expr =
    IntExpr Integer
  | CharExpr Char
  | Identifier Name
  | VarDecl PrimType Name
  | Assignment Name Expr
  | ArrAssignment Name Index Expr
  | BinaryOp Op Expr Expr
  | Times Integer Block
  | Debug Expr
  deriving Show
