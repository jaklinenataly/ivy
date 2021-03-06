module Ivy.Error where

import           Data.Semigroup ((<>))
import           Ivy.Codegen.Types
import           Text.Parsec (ParseError)

data Error =
    Parsing ParseError
  | Codegen CodegenError

instance Show Error where
  show (Parsing err) = "Parsing Error: " <> show err
  show (Codegen err) = "Compile Error: " <> show err

