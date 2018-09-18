\begin{code}
module ValueTypes.Term where
\end{code}

## Imports

\begin{code}
open import Type
open import Type.RenamingSubstitution
open import Type.Normal
open import Type.BSN
\end{code}

## Fixity declarations

To begin, we get all our infix declarations out of the way.
We list separately operators for judgements, types, and terms.
\begin{code}
infix  4 _∋_
infix  4 _⊢_
infixl 5 _,_
\end{code}

## Contexts and erasure

We need to mutually define contexts and their
erasure to type contexts.
\begin{code}
data Ctx : Set
∥_∥ : Ctx → Ctx⋆
\end{code}

A context is either empty, or extends a context by
a type variable of a given kind, or extends a context
by a variable of a given type.
\begin{code}
data Ctx where
  ∅ : Ctx
  _,⋆_ : Ctx → Kind → Ctx
  _,_ : ∀ {J} (Γ : Ctx) → ∥ Γ ∥ ⊢V⋆ J → Ctx
\end{code}
Let `Γ` range over contexts.  In the last rule,
the type is indexed by the erasure of the previous
context to a type context and a kind.

The erasure of a context is a type context.
\begin{code}
∥ ∅ ∥       =  ∅
∥ Γ ,⋆ J ∥  =  ∥ Γ ∥ ,⋆ J
∥ Γ , A ∥   =  ∥ Γ ∥
\end{code}

## Variables

A variable is indexed by its context and type.
\begin{code}
data _∋_ : ∀ {J} (Γ : Ctx) → ∥ Γ ∥ ⊢V⋆ J → Set where

  Z : ∀ {Γ J} {A : ∥ Γ ∥ ⊢V⋆ J}
      ----------
    → Γ , A ∋ A

  S : ∀ {Γ J K} {A : ∥ Γ ∥ ⊢V⋆ J} {B : ∥ Γ ∥ ⊢V⋆ K}
    → Γ ∋ A
      ----------
    → Γ , B ∋ A

  T : ∀ {Γ J K} {A : ∥ Γ ∥ ⊢V⋆ J}
    → Γ ∋ A
      -------------------
    → Γ ,⋆ K ∋ weakenV A
\end{code}
Let `x`, `y` range over variables.

## Terms

A term is indexed over by its context and type.  A term is a variable,
an abstraction, an application, a type abstraction, or a type
application.
\begin{code}
data _⊢_ : ∀ {J} (Γ : Ctx) → ∥ Γ ∥ ⊢V⋆ J → Set where

  ` : ∀ {Γ J} {A : ∥ Γ ∥ ⊢V⋆ J}
    → Γ ∋ A
      ------
    → Γ ⊢ A

  ƛ : ∀ {Γ A B}
    → Γ , A ⊢ B
      -----------
    → Γ ⊢ A ⇒ B

  _·_ : ∀ {Γ A B}
    → Γ ⊢ A ⇒ B
    → Γ ⊢ A
      -----------
    → Γ ⊢ B

  Λ : ∀ {Γ K Δ}
    → {B : Δ ,⋆ K ⊢⋆ *}
    → {vs : Env⋆ ∥ Γ ∥ Δ}
    → Γ ,⋆ K ⊢ eval B (extEnv vs)
      ----------
    → Γ ⊢ Π B vs

  _·⋆_ : ∀ {Γ K Δ}
    → {B : Δ ,⋆ K ⊢⋆ *}
    → {vs : Env⋆ ∥ Γ ∥ Δ}
    → Γ ⊢ Π B vs
    → (A : ∥ Γ ∥ ⊢V⋆ K)
      ---------------
    → Γ ⊢ eval B (vs ,,⋆ A)

  wrap : ∀{Γ Δ}
    → {B : Δ ,⋆ * ⊢⋆ *}
    → {vs : Env⋆ ∥ Γ ∥ Δ}
    → (M : Γ ⊢ eval B (vs ,,⋆ μ B vs ))
    → Γ ⊢ μ B vs

  unwrap : ∀{Γ Δ}
    → {B : Δ ,⋆ * ⊢⋆ *}
    → {vs : Env⋆ ∥ Γ ∥ Δ}
    → (M : Γ ⊢ μ B vs)
    → Γ ⊢ eval B (vs ,,⋆ μ B vs)
{-
  conv : ∀{Γ}{A A' : ∥ Γ ∥ ⊢V⋆ *}
    → A V≡ A'
    → Γ ⊢ A
    → Γ ⊢ A' -}
\end{code}