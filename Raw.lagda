\begin{code}
module Raw where
\end{code}

\begin{code}
open import Agda.Builtin.String

open import Builtin.Constant.Type
\end{code}

The raw un-scope-checked and un-type-checked syntax

\begin{code}

data RawKind : Set where
  *   : RawKind
  _⇒_ : RawKind → RawKind → RawKind

data RawTy : Set where
  `   : String → RawTy
  _⇒_ : RawTy → RawTy → RawTy
  Π   : String → RawKind → RawTy → RawTy
  ƛ   : String → RawKind → RawTy → RawTy
  _·_ : RawTy → RawTy → RawTy
  con : TyCon → RawTy

open import Data.Nat
open import Data.Integer

data RawTermCon : Set where
  integer : ℕ → ℤ → RawTermCon
  bytestring : ℕ → ByteString → RawTermCon
  size : ℕ → RawTermCon
  string : String → RawTermCon

data RawTm : Set where
  `    : String → RawTm
  Λ    : String → RawKind → RawTm → RawTm
  _·⋆_ : RawTm → RawTy → RawTm
  ƛ    : String → RawTy → RawTm → RawTm
  _·_  : RawTm → RawTm → RawTm
  con  : RawTermCon → RawTm

{-# FOREIGN GHC import Raw #-}
{-# COMPILE GHC RawTermCon = data RConstant (RConInt | RConBS | RConSize | RConStr) #-}
{-# COMPILE GHC RawTm = data RTerm (RVar | RTLambda  | RTApp | RLambda  | RApp | RCon) #-}
{-# COMPILE GHC RawTy = data RType (RTyVar | RTyFun | RTyPi | RTyLambda | RTyApp | RTyCon) #-}
{-# COMPILE GHC RawKind = data RKind (RKiStar | RKiFun) #-}
\end{code}
