\begin{code}
module Declarative.Term.RenamingSubstitution where
\end{code}

## Imports

\begin{code}
open import Function using (id; _∘_)
open import Relation.Binary.PropositionalEquality
  renaming (subst to substEq) using (_≡_; refl; cong; cong₂; trans; sym)
open import Data.Unit

open import Type
import Type.RenamingSubstitution as ⋆
open import Type.Equality
open import Builtin.Signature
  Ctx⋆ Kind ∅ _,⋆_ * # _∋⋆_ Z S _⊢⋆_ ` con boolean size⋆
open import Builtin.Constant.Term Ctx⋆ Kind * # _⊢⋆_ con size⋆
open import Declarative.Term
\end{code}


## Renaming
\begin{code}
Ren : ∀ Γ Δ → ⋆.Ren ∥ Γ ∥ ∥ Δ ∥ → Set
Ren Γ Δ ρ = ∀ {J} {A : ∥ Γ ∥ ⊢⋆ J} → Γ ∋ A → Δ ∋ ⋆.rename ρ A
\end{code}


\begin{code}
ext : ∀ {Γ Δ}
  → (ρ⋆ : ⋆.Ren ∥ Γ ∥ ∥ Δ ∥)
  → Ren Γ Δ ρ⋆
    ------------------------------------------------------------
  → (∀ {K }{B : ∥ Γ ∥ ⊢⋆ K} → Ren (Γ , B) (Δ , ⋆.rename ρ⋆ B) ρ⋆)
ext ρ⋆ ρ Z     = Z
ext ρ⋆ ρ (S x) = S (ρ x)
\end{code}

\begin{code}
ext⋆ : ∀ {Γ Δ}
  → (ρ⋆ : ⋆.Ren ∥ Γ ∥ ∥ Δ ∥)
  → Ren Γ Δ ρ⋆
    ----------------------------------------
  → ∀ {K} → Ren (Γ ,⋆ K) (Δ ,⋆ K) (⋆.ext ρ⋆)
ext⋆ {Γ}{Δ} ρ⋆ ρ {K}{A} (T x) =
  substEq (λ A → Δ ,⋆ K ∋ A)
          (trans (sym (⋆.rename-comp _)) (⋆.rename-comp _))
          (T (ρ x))
\end{code}

\begin{code}
renameTermCon : ∀ {Φ Ψ}
  → (ρ⋆ : ∀ {J} → Φ ∋⋆ J → Ψ ∋⋆ J)
    -----------------------------------------------------
  → ({A : Φ ⊢⋆ *} → TermCon A → TermCon (⋆.rename ρ⋆ A ))
renameTermCon ρ⋆ (integer s i p)    = integer s i p
renameTermCon ρ⋆ (bytestring s b p) = bytestring s b p
renameTermCon ρ⋆ (size s)           = size s
\end{code}

\begin{code}
open import Data.Product renaming (_,_ to _,,_)
open import Data.List

rename : ∀ {Γ Δ}
  → (ρ⋆ : ⋆.Ren ∥ Γ ∥ ∥ Δ ∥)
  → Ren Γ Δ ρ⋆
    ------------------------
  → (∀ {J} {A : ∥ Γ ∥ ⊢⋆ J} → Γ ⊢ A → Δ ⊢ ⋆.rename ρ⋆ A )

renameTel : ∀ {Γ Γ' Δ}
 → (ρ⋆ : ⋆.Ren ∥ Γ ∥ ∥ Γ' ∥)
 → Ren Γ Γ' ρ⋆
 → {σ : ⋆.Sub Δ ∥ Γ ∥}
 → {As : List (Δ ⊢⋆ *)}
 → Tel Γ Δ σ As
 → Tel Γ' Δ (⋆.rename ρ⋆ ∘ σ) As

renameTel ρ⋆ ρ {As = []}     _         = _
renameTel ρ⋆ ρ {As = A ∷ As} (M ,, Ms) =
  substEq (_ ⊢_) (sym (⋆.rename-subst A)) (rename ρ⋆ ρ M) ,, renameTel ρ⋆ ρ Ms

rename ρ⋆ ρ (` x)    = ` (ρ x)
rename ρ⋆ ρ (ƛ N)    = ƛ (rename ρ⋆ (ext ρ⋆ ρ) N)
rename ρ⋆ ρ (L · M)  = rename ρ⋆ ρ L · rename ρ⋆ ρ M 
rename ρ⋆ ρ (Λ N)    = Λ (rename (⋆.ext ρ⋆) (ext⋆ ρ⋆ ρ) N )
rename {Γ}{Δ} ρ⋆ ρ (_·⋆_ {B = B} t A) =
  substEq (λ A → Δ ⊢ A)
          ( trans (sym (⋆.subst-rename B))
                 (trans (⋆.subst-cong (⋆.rename-subst-cons ρ⋆ A) B)
                        (⋆.rename-subst B) ) )
          (rename ρ⋆ ρ t ·⋆ ⋆.rename ρ⋆ A)
rename ρ⋆ ρ (wrap1 pat arg t) = wrap1 _ _ (rename ρ⋆ ρ t)
rename ρ⋆ ρ (unwrap1 t)       = unwrap1 (rename ρ⋆ ρ t)
rename ρ⋆ ρ (conv p t) = conv (rename≡β ρ⋆ p) (rename ρ⋆ ρ t)
rename ρ⋆ ρ (con cn)   = con (renameTermCon ρ⋆ cn)
rename {Γ} {Δ} ρ⋆ ρ (builtin bn σ X ) = substEq
  (Δ ⊢_)
  (⋆.rename-subst (proj₂ (proj₂ (SIG bn))))
  (builtin bn (⋆.rename ρ⋆ ∘ σ) (renameTel ρ⋆ ρ X)) 
rename ρ⋆ ρ (error A) = error (⋆.rename ρ⋆ A)
\end{code}

\begin{code}
weaken : ∀ {Φ J}{A : ∥ Φ ∥ ⊢⋆ J}{K}{B : ∥ Φ ∥ ⊢⋆ K}
  → Φ ⊢ A
    -------------
  → Φ , B ⊢ A
weaken {Φ}{J}{A}{K}{B} x =
  substEq (λ x → Φ , B ⊢ x)
          (⋆.rename-id A)
          (rename id
                  (λ x → substEq (λ A → Φ , B ∋ A) (sym (⋆.rename-id _)) (S x))
                  x)
\end{code}

\begin{code}
weaken⋆ : ∀ {Φ J}{A : ∥ Φ ∥ ⊢⋆ J}{K}
  → Φ ⊢ A
    ------------------
  → Φ ,⋆ K ⊢ ⋆.weaken A
weaken⋆ x = rename _∋⋆_.S _∋_.T x
\end{code}

## Substitution
\begin{code}
Sub : ∀ Γ Δ → ⋆.Sub ∥ Γ ∥ ∥ Δ ∥ → Set
Sub Γ Δ σ = ∀ {J} {A : ∥ Γ ∥ ⊢⋆ J} → Γ ∋ A → Δ ⊢ ⋆.subst σ A
\end{code}


\begin{code}
exts : ∀ {Γ Δ}
  → (σ⋆ : ∀ {K} → ∥ Γ ∥ ∋⋆ K → ∥ Δ ∥ ⊢⋆ K)
  → (∀ {J} {A : ∥ Γ ∥ ⊢⋆ J} → Γ ∋ A → Δ ⊢ ⋆.subst σ⋆ A)
    ---------------------------------------------------
  → (∀ {J} {K} {A : ∥ Γ ∥ ⊢⋆ J} {B : ∥ Γ ∥ ⊢⋆ K}
     → Γ , B ∋ A
     -------------------------------
     → Δ , ⋆.subst σ⋆ B ⊢ ⋆.subst σ⋆ A)
exts σ⋆ σ Z     = ` Z
exts σ⋆ σ (S x) = weaken (σ x)
\end{code}

\begin{code}
exts⋆ : ∀ {Γ Δ}
  → (σ⋆ : ∀ {K} → ∥ Γ ∥ ∋⋆ K → ∥ Δ ∥ ⊢⋆ K)
  → (∀ {J} {A : ∥ Γ ∥ ⊢⋆ J} → Γ ∋ A → Δ ⊢ ⋆.subst σ⋆ A)
    ---------------------------------------------------
  → (∀ {J K}{A : ∥ Γ ,⋆ K ∥ ⊢⋆ J}
     → Γ ,⋆ K ∋ A 
       -------------------------------
     → Δ ,⋆ K ⊢ ⋆.subst (⋆.exts σ⋆) A )
exts⋆ {Γ}{Δ} σ⋆ σ {J}{K}(T {A = A} x) =
  substEq (λ x → Δ ,⋆ K ⊢ x)
          (trans (sym (⋆.rename-subst A))
                 (⋆.subst-rename A))
          (weaken⋆ (σ x))

\end{code}

\begin{code}
substTermCon : ∀ {Φ Ψ}
  → (σ⋆ : ∀ {J} → Φ ∋⋆ J → Ψ ⊢⋆ J)
    ------------------------
  → ({A : Φ ⊢⋆ *} → TermCon A → TermCon (⋆.subst σ⋆ A ))
substTermCon σ⋆ (integer s i p)    = integer s i p
substTermCon σ⋆ (bytestring s b p) = bytestring s b p
substTermCon σ⋆ (size s)           = size s
\end{code}


\begin{code}
subst : ∀ {Γ Δ}
  → (σ⋆ : ∀ {K} → ∥ Γ ∥ ∋⋆ K → ∥ Δ ∥ ⊢⋆ K)
  → (∀ {J} {A : ∥ Γ ∥ ⊢⋆ J} → Γ ∋ A → Δ ⊢ ⋆.subst σ⋆ A)
    ---------------------------------------------------
  → (∀ {J} {A : ∥ Γ ∥ ⊢⋆ J} → Γ ⊢ A → Δ ⊢ ⋆.subst σ⋆ A)

substTel : ∀ {Γ Γ' Δ}
 → (σ⋆ : ⋆.Sub ∥ Γ ∥ ∥ Γ' ∥)
 → Sub Γ Γ' σ⋆
 → {σ' : ⋆.Sub Δ ∥ Γ ∥}
 → {As : List (Δ ⊢⋆ *)}
 → Tel Γ Δ σ' As
 → Tel Γ' Δ (⋆.subst σ⋆ ∘ σ') As
substTel σ⋆ σ {As = []}     _         = _
substTel σ⋆ σ {As = A ∷ As} (M ,, Ms) =
  substEq (_ ⊢_) (sym (⋆.subst-comp A)) (subst σ⋆ σ M) ,, substTel σ⋆ σ Ms

subst σ⋆ σ (` k)                     = σ k
subst σ⋆ σ (ƛ N)                     = ƛ (subst σ⋆ (exts σ⋆ σ) N)
subst σ⋆ σ (L · M)                   = subst σ⋆ σ L · subst σ⋆ σ M
subst σ⋆ σ (Λ N)                     = Λ (subst (⋆.exts σ⋆) (exts⋆ σ⋆ σ) N)
subst {Γ}{Δ} σ⋆ σ (_·⋆_ {B = B} L M) =
  substEq (λ A → Δ ⊢ A)
          (trans (sym (⋆.subst-comp B))
                 (trans (⋆.subst-cong (⋆.subst-subst-cons σ⋆ M)
                                    B)
                        (⋆.subst-comp B)))
          (subst σ⋆ σ L ·⋆ ⋆.subst σ⋆ M)
subst σ⋆ σ (wrap1 pat arg t) = wrap1 _ _ (subst σ⋆ σ t)
subst σ⋆ σ (unwrap1 t)       = unwrap1 (subst σ⋆ σ t)
subst σ⋆ σ (conv p t) = conv (subst≡β σ⋆ p) (subst σ⋆ σ t)
subst σ⋆ σ (con cn) = con (substTermCon σ⋆ cn)
subst {Γ}{Γ'} σ⋆ σ (builtin bn σ' tel ) = substEq
  (Γ' ⊢_)
  (⋆.subst-comp (proj₂ (proj₂ (SIG bn))))
  (builtin bn (⋆.subst σ⋆ ∘ σ') (substTel σ⋆ σ tel))
subst σ⋆ σ (error A) = error (⋆.subst σ⋆ A)
\end{code}

\begin{code}

substcons : ∀{Γ Δ} →
  (σ⋆ : ∀{K} → ∥ Γ ∥  ∋⋆ K → ∥ Δ ∥ ⊢⋆ K)
  → (∀ {J}{A : ∥ Γ ∥ ⊢⋆ J} → Γ ∋ A → Δ ⊢ ⋆.subst σ⋆ A)
  → ∀{J}{A : ∥ Γ ∥ ⊢⋆ J}
  → (t : Δ ⊢ ⋆.subst σ⋆ A)
    ---------------------
  → (∀ {J} {B : ∥ Γ ∥ ⊢⋆ J} → Γ , A ∋ B → Δ ⊢ ⋆.subst σ⋆ B)
substcons σ⋆ σ t Z     = t
substcons σ⋆ σ t (S x) = σ x
\end{code}

\begin{code}
_[_] : ∀ {J Γ} {A B : ∥ Γ ∥ ⊢⋆ J}
        → Γ , B ⊢ A
        → Γ ⊢ B 
          ---------
        → Γ ⊢ A
_[_]  {J} {Γ}{A}{B} t s =
  substEq (λ A → Γ ⊢ A)
          (⋆.subst-id A)
          (subst `
                 (substcons `
                            (λ x → substEq (λ A → Γ ⊢ A)
                                           (sym (⋆.subst-id _))
                                           (` x))
                            (substEq (λ A → Γ ⊢ A) (sym (⋆.subst-id B)) s))
                 t) 
\end{code}

\begin{code}
_[_]⋆ : ∀ {J Γ K} {B : ∥ Γ ,⋆ K ∥ ⊢⋆ J}
        → Γ ,⋆ K ⊢ B
        → (A : ∥ Γ ∥ ⊢⋆ K)
          ---------
        → Γ ⊢ B ⋆.[ A ]
_[_]⋆ {J}{Γ}{K}{B} t A =
  subst (⋆.subst-cons ` A)
        (λ{(T {A = A'} x) → substEq (λ A → Γ ⊢ A)
                                     (trans (sym (⋆.subst-id A'))
                                     (⋆.subst-rename A'))
                                     (` x)})
          t
\end{code}
