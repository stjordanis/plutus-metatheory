\begin{code}
module Type.BetaEtaNBEWithProofs where
\end{code} where

## Imports

\begin{code}
open import Type
open import Type.BetaEtaNormal
open import Type.RenamingSubstitution

open import Relation.Binary.HeterogeneousEquality
  renaming (subst to substEq;  [_] to [_]≅)
open import Function
open import Data.Product

-- functional extensionality
postulate funext : {A : Set}{B : A → Set}{f : ∀ a → B a}{g : ∀ a → B a} →
                (∀ a → f a ≅ g a) → f ≅ g

postulate funiext : {A : Set}{B : A → Set}{f : ∀{a} → B a}{g : ∀{a} → B a} → 
               (∀ a → f {a} ≅ g {a}) → 
               _≅_ {_}{ {a : A} → B a} f { {a : A} → B a} g

ir : ∀{A A' : Set} → {a : A} → {a' : A'} → {p q : a ≅ a'} → p ≅ q
ir {p = refl} {q = refl} = refl

Σeq : {A : Set} {B : A → Set} → {a : A} → {a' : A}(p : a ≅ a') → {b : B a} → {b' : B a'} → substEq B p b ≅ b' → _,_ {B = B} a b ≅ _,_ {B = B} a' b'
Σeq refl refl = refl

fixtypes : ∀{A A' A'' A''' : Set}{a : A}{a' : A'}{a'' : A''}{a''' : A'''} → {p : a ≅ a'} → {q : a'' ≅ a'''} → a' ≅ a'' → p ≅ q
fixtypes {p = refl} {q = refl} refl = refl

ifcong : {A : Set}{B : A → Set}{f f' : {a : A} → B a} → _≅_ {_}{ {a : A} → B a } f { {a : A} → B a } f' → (a : A) → f {a} ≅ f' {a}
ifcong refl a = refl


fcong : ∀{A B : Set} → {f f' : A → B} → f ≅ f' → (a : A) → f a ≅ f' a
fcong refl a = refl
\end{code}


\begin{code}
Ren : Ctx⋆ → Ctx⋆ → Set
Ren Δ Γ = ∀{J} → Δ ∋⋆ J → Γ ∋⋆ J
\end{code}

\begin{code}
mutual
  Val : Ctx⋆ → Kind → Set
  Val Γ * = Γ ⊢Nf⋆ *
  Val Γ (K ⇒ J) = Σ (∀{Δ} → Ren Γ Δ → Val Δ K → Val Δ J) λ f → ∀{Δ Δ'}
    (ρ : Ren Γ Δ)
    (ρ' : Ren Δ Δ')
    (v : Val Δ K)
    → renval J ρ' (f ρ v) ≅ f (ρ' ∘ ρ) (renval K ρ' v)

  renval : ∀{Γ Δ} σ → Ren Γ Δ → Val Γ σ → Val Δ σ
  renval * ρ v = renameNf ρ v
  renval (K ⇒ J) ρ (f , p) = (λ ρ' v → f (ρ' ∘ ρ) v) , λ ρ' ρ'' v → p (ρ' ∘ ρ) ρ'' v

renvalcomp : ∀{Γ Δ E K} → (ρ : Ren Γ Δ) → (ρ' : Ren Δ E) → (v : Val Γ K) → renval K ρ' (renval K ρ v) ≅ renval K (ρ' ∘ ρ) v 
renvalcomp {K = *} ρ ρ' v = sym (≡-to-≅ (renameNf-comp ρ ρ' v))
renvalcomp {K = K ⇒ J} ρ ρ' v =
  Σeq refl
      (funiext (λ Δ → funiext (λ Δ' → funext (λ ρ'' → funext (λ ρ''' → funext (λ v' → ir))))))

mutual
  reify : ∀{Γ} K → Val Γ K → Γ ⊢Nf⋆ K
  reify * n = n
  reify (K ⇒ J) (f , p) = ƛ (reify J (f S (reflect K (` Z)))) 
  
  reflect : ∀{Γ} K → Γ ⊢NeN⋆ K → Val Γ K
  reflect * n = ne n
  reflect (K ⇒ J) f =
    (λ ρ x → reflect J (renameNeN ρ f · (reify K x)))
    , λ ρ ρ' v → trans (rename-reflect J ρ' (renameNeN ρ f · reify K v))
                       (cong₂ (λ x y → reflect J (x · y))
                              (sym (≡-to-≅ (renameNeN-comp ρ ρ' _)))
                              (rename-reify K ρ' v))

  rename-reify : ∀{Γ Δ} K (ρ : Ren Γ Δ)(n : Val Γ K) → renameNf ρ (reify K n) ≅ reify K (renval K ρ n)
  rename-reify * ρ n  = refl
  rename-reify (K ⇒ J) ρ (f , p) =
    cong ƛ (trans (rename-reify J (ext ρ) (f S (reflect K (` Z))))
                  (cong (reify J) (trans (p S (ext ρ) (reflect K (` Z))) (cong (f (S ∘ ρ)) (rename-reflect K (ext ρ) (` Z))))))

  rename-reflect : ∀{Γ Δ} K (ρ : Ren Γ Δ)(n : Γ ⊢NeN⋆ K) → renval K ρ (reflect K n) ≅ reflect K (renameNeN ρ n)
  rename-reflect * ρ n = refl
  rename-reflect (K ⇒ J) ρ n = Σeq (funiext (λ Γ → funext (λ (ρ' : Ren _ _) → funext (λ v → cong (λ f → reflect J (f · reify K v)) (≡-to-≅ (renameNeN-comp ρ ρ' n)))))) (funiext (λ Δ → funiext (λ Δ → funext (λ ρ' → funext (λ ρ'' → funext (λ v → fixtypes (trans (cong₂ (λ n₁ v₁ → reflect J (n₁ · v₁)) (≡-to-≅ (renameNeN-comp ρ' ρ'' (renameNeN ρ n))) (sym (rename-reify K ρ'' v))) (sym (rename-reflect J ρ'' (renameNeN ρ' (renameNeN ρ n) · reify K v))))))))))

{-
-- A Partial equivalence relation on values: 'equality on values'
PER : ∀{Γ} K → Val Γ K → Val Γ K → Set
PER *       v v' = reify * v ≅ reify * v'
PER (K ⇒ J) f f' = ∀{Δ}
 → (ρ : Ren _ Δ)
 → {v v' : Val Δ K}
 → PER K v v'
 → PER J (f ρ v) (f' ρ v')  


symPER : ∀{Γ} K {v v' : Val Γ K} → PER K v v' → PER K v' v
symPER *       p = sym p
symPER (K ⇒ J) p = λ ρ q → symPER J (p ρ (symPER K q))

transPER : ∀{Γ} K {v v' v'' : Val Γ K} → PER K v v' → PER K v' v'' → PER K v v''
transPER * p q = trans p q
transPER (K ⇒ J) p q = λ ρ r
  → transPER J (p ρ r) (q ρ (transPER K (symPER K r) r))

reflPER : ∀{Γ} K {v v' : Val Γ K} → PER K v v' → PER K v v
reflPER K p = transPER K p (symPER K p)

mutual
  reifyPER : ∀{Γ} K {v v' : Val Γ K}
    → PER K v v'
    → reify K v ≅ reify K v'
  reifyPER *       p = p
  reifyPER (K ⇒ J) p = cong ƛ (reifyPER J (p S (reflectPER K (refl {x = ` Z})))) 
  
  reflectPER  : ∀{Γ} K {n n' : Γ ⊢NeN⋆ K}
    → n ≅ n'
    → PER K (reflect K n) (reflect K n')
  reflectPER *       p = cong ne p
  reflectPER (K ⇒ J) p =
   λ ρ q → reflectPER J (cong₂ _·_ (cong (renameNeN ρ) p) (reifyPER K q))
-}
\end{code}
  
\begin{code}
Env : Ctx⋆ → Ctx⋆ → Set
Env Δ Γ = ∀{J} → Δ ∋⋆ J → Val Γ J

_,,⋆_ : ∀{Δ Γ} → (σ : Env Γ Δ) → ∀{K}(A : Val Δ K) → Env (Γ ,⋆ K) Δ
(σ ,,⋆ A) Z = A
(σ ,,⋆ A) (S x) = σ x
\end{code}

\begin{code}
mutual
  eval : ∀{Γ Δ K} → Δ ⊢⋆ K → (∀{J} → Δ ∋⋆ J → Val Γ J)  → Val Γ K
  eval (` x)    ρ = ρ x
  eval (Π B)    ρ = Π (eval B ((renval _ S ∘ ρ) ,,⋆ reflect _ (` Z)))
  eval (A ⇒ B) ρ = eval A ρ ⇒ eval B ρ
  eval (ƛ B)    ρ = (λ ρ' v → eval B ((renval _ ρ' ∘ ρ) ,,⋆ v)) ,
    λ ρ' ρ'' v → trans (rename-eval ((renval _ ρ' ∘ ρ) ,,⋆ v) ρ'' B) (cong (λ (γ : Env _ _) → eval B γ) (funiext (λ J → funext (λ { Z → refl ; (S a) → renvalcomp ρ' ρ'' (ρ a)}))))
  eval (A · B) ρ = proj₁ (eval A ρ) id (eval B ρ)
  eval (μ B)    ρ = μ (eval B ((renval _ S ∘ ρ) ,,⋆ reflect _ (` Z)))
  
  rename-eval : ∀{Γ Δ Δ₁ σ} → (γ : Env Γ Δ)(ρ : Ren Δ Δ₁)(t : Γ ⊢⋆ σ) → renval σ ρ (eval t γ) ≅ eval t (renval _ ρ ∘ γ)
  rename-eval γ ρ (` x) = refl
  rename-eval γ ρ (Π t) = cong Π (trans (rename-eval ((renval _ S ∘ γ) ,,⋆ reflect _ (` Z)) (ext ρ) t) (cong (eval t) (funiext (λ a → funext (λ { Z → rename-reflect _ (ext ρ) (` Z) ; (S a₁) → trans (renvalcomp S (ext ρ) (γ a₁)) (sym (renvalcomp ρ S (γ a₁)))}))))) 
  rename-eval γ ρ (A ⇒ B) = cong₂ _⇒_ (rename-eval γ ρ A ) (rename-eval γ ρ B)
  rename-eval γ ρ (ƛ t) = Σeq (funiext (λ a → funext (λ (a₁ : Ren _ _) → funext (λ a₂ → cong (eval t) (funiext (λ a₃ → funext (λ { Z → refl ; (S a₄) → sym (renvalcomp ρ a₁ (γ a₄)) }))))))) (funiext (λ a → funiext (λ a₁ → funext (λ a₂ → funext (λ a₃ → funext (λ a₄ → fixtypes (trans (cong (eval t) (funiext (λ a₅ → funext (λ { Z → refl ; (S a₆) → sym (renvalcomp a₂ a₃ (renval _ ρ (γ a₆)))})))) (sym (rename-eval ((renval _ a₂ ∘ renval _ ρ ∘ γ) ,,⋆ a₄) a₃ t)) )))))))
  rename-eval γ ρ (A · B) = trans (proj₂ (eval A γ) id ρ (eval B γ)) (trans (cong (proj₁ (eval A γ) ρ) (rename-eval γ ρ B)) (cong (λ f → f (eval B (renval _ ρ ∘ γ))) ((fcong (ifcong (cong proj₁ (rename-eval γ ρ A)) _) id)) ))
  rename-eval γ ρ (μ t) = cong μ (trans (rename-eval ((renval _ S ∘ γ) ,,⋆ reflect _ (` Z)) (ext ρ) t) (cong (eval t) (funiext (λ a → funext (λ { Z → rename-reflect _ (ext ρ) (` Z) ; (S a₁) → trans (renvalcomp S (ext ρ) (γ a₁)) (sym (renvalcomp ρ S (γ a₁)))}))))) 
\end{code}

\begin{code}
eval-cong : ∀ {Φ Ψ}(f g : ∀ {J} → Φ ∋⋆ J → Val Ψ J)
  → (∀ {J}(x : Φ ∋⋆ J) → f x ≅ g x)
  → ∀{K}(A : Φ ⊢⋆ K)
    -------------------------
  → eval A f ≅ eval A g
eval-cong f g p (` x) = p x
eval-cong f g p (Π A) = cong _⊢Nf⋆_.Π (eval-cong _ _ (λ { Z → refl ; (S x) → cong (renval _ S) (p x)}) A)
eval-cong f g p (A ⇒ B) = cong₂ _⇒_ (eval-cong f g p A) (eval-cong f g p B)
eval-cong f g p (ƛ A) = Σeq (funiext (λ Δ → funext λ ρ' → funext (λ v → eval-cong _ _ (λ { Z → refl ; (S x) → cong (renval _ ρ') (p x)}) A)))
                            (funiext (λ Δ → funiext λ Δ' → funext (λ ρ → funext (λ ρ' → funext λ v →
                               fixtypes (trans (eval-cong _ _ (λ { Z → refl ; (S x) → sym (renvalcomp ρ ρ' (g x))}) A)
                                               (sym (rename-eval ((renval _ ρ ∘ g) ,,⋆ v) ρ' A)))))))
eval-cong {Ψ = Ψ} f g p (_·_ {K = K}{J = J} A B) = cong₂ (λ (f : Val Ψ (K ⇒ J))(v : Val Ψ K) → proj₁ f id v) (eval-cong _ _ p A) (eval-cong _ _ p B) 
eval-cong f g p (μ A) = cong _⊢Nf⋆_.μ (eval-cong _ _ (λ { Z → refl ; (S x) → cong (renval _ S) (p x)}) A)
\end{code}

\begin{code}
idEnv : ∀ {Γ} → Env Γ Γ
idEnv x = reflect _ (` x)
\end{code}

\begin{code}
nf : ∀{Γ K} → Γ ⊢⋆ K → Γ ⊢Nf⋆ K
nf t = reify _ (eval t idEnv)
\end{code}

# stability

\begin{code}
mutual
  stability : ∀{Γ K}(n : Γ ⊢Nf⋆ K) → nf (embNf n) ≅ n
  stability (Π B) = cong Π (trans (eval-cong _ _ (λ { Z → refl ; (S x) → rename-reflect _ S (` x)}) (embNf B)) (stability B))
  stability (A ⇒ B) = cong₂ _⇒_ (stability A) (stability B)
  stability (ƛ B) = cong _⊢Nf⋆_.ƛ (trans (cong (reify _) ( (eval-cong _ _ (λ { Z → refl ; (S x) → rename-reflect _ S (` x)}) (embNf B)))) (stability B))
  stability (μ B) = cong μ (trans (eval-cong _ _ (λ { Z → refl ; (S x) → rename-reflect _ S (` x)}) (embNf B)) (stability B))
  stability (ne n) = stabilityNeN n
  
  stabilityNeN : ∀{Γ K}(n : Γ ⊢NeN⋆ K) → eval (embNeN n) idEnv ≅ reflect _ n
  stabilityNeN (` x) = refl
  stabilityNeN (n · n') = trans
                            (fcong (fcong (ifcong (cong proj₁ (stabilityNeN n)) _) id)
                             (eval (embNf n') idEnv))
                            (cong₂ (λ n n' → reflect _ (n · n')) (≡-to-≅ (renameNeN-id n)) (stability n'))
\end{code}

# substitution

\begin{code}
Sub : Ctx⋆ → Ctx⋆ → Set
Sub Δ Γ = ∀{J} → Δ ∋⋆ J → Γ ⊢Nf⋆ J
\end{code}

\begin{code}
extsNf : ∀ {Φ Ψ}
  → (∀ {J} → Φ ∋⋆ J → Ψ ⊢Nf⋆ J)
    -------------------------------------
  → (∀ {J K} → Φ ,⋆ K ∋⋆ J → Ψ ,⋆ K ⊢Nf⋆ J)
extsNf σ Z      =  reify _ (reflect _ (` Z)) --  (` Z)
extsNf σ (S α)  =  weakenNf (σ α)
\end{code}

\begin{code}
substNf : ∀ {Φ Ψ}
  → (∀ {J} → Φ ∋⋆ J → Ψ ⊢Nf⋆ J)
    -------------------------
  → (∀ {J} → Φ ⊢Nf⋆ J → Ψ ⊢Nf⋆ J)
substNf ρ n = nf (subst (embNf ∘ ρ) (embNf n))
\end{code}

\begin{code}
_[_]Nf : ∀ {Φ J K}
        → Φ ,⋆ K ⊢Nf⋆ J
        → Φ ⊢Nf⋆ K 
          ------
        → Φ ⊢Nf⋆ J
B [ A ]Nf = nf (embNf B [ embNf A ])
\end{code}

\begin{code}
eval-rename : ∀{Γ Δ E K}
  → (α : Ren Γ Δ)
  → (β : Env Δ E)
  → (A : Γ ⊢⋆ K)
  → eval A (β ∘ α) ≅ eval (rename α A) β
eval-rename α β (` x) = refl
eval-rename α β (Π A) =
  cong Π (trans (eval-cong _ _ (λ { Z → refl ; (S x) → refl}) A)
                (eval-rename (ext α) ((renval _ S ∘ β) ,,⋆ reflect _ (` Z)) A))
eval-rename α β (A ⇒ B) = cong₂ _⇒_ (eval-rename α β A) (eval-rename α β B)
eval-rename α β (ƛ A) =
  Σeq (funiext λ Δ → funext λ (ρ : Ren _ _) → funext λ v →
        trans (eval-cong _ _ (λ { Z → refl ; (S x) → refl}) A)
              (eval-rename (ext α) ((renval _ ρ ∘ β) ,,⋆ v) A))
      (funiext λ Δ → funiext λ Δ' → funext λ ρ → funext λ ρ' → funext λ v → fixtypes (trans (eval-cong _ _ (λ { Z → refl ; (S x) → sym (renvalcomp ρ ρ' (β x))}) (rename (ext α) A)) (sym (rename-eval ((renval _ ρ ∘ β) ,,⋆ v) ρ' (rename (ext α) A)))  ) )
eval-rename {E = Ψ} α β (_·_ {K = K}{J = J} A B) =
  cong₂ (λ (f : Val Ψ (K ⇒ J))(v : Val Ψ K) → proj₁ f id v) (eval-rename α β A) (eval-rename α β B)
eval-rename α β (μ A) =
  cong μ (trans (eval-cong _ _ (λ { Z → refl ; (S x) → refl}) A)
                (eval-rename (ext α) ((renval _ S ∘ β) ,,⋆ reflect _ (` Z)) A))

\end{code}

The below definitions are needed for the using normal forms as types
of terms, they are not needed for an ordinary nomalisation proof.

\begin{code}
rename[]Nf : ∀{Γ Δ K J}
  (ρ : ∀{K} → Γ ∋⋆ K → Δ ∋⋆ K)
  → (A : Γ ⊢Nf⋆ K)
  → (B : Γ ,⋆ K ⊢Nf⋆ J)
  → renameNf ρ (B [ A ]Nf) ≅ renameNf (ext ρ) B [ renameNf ρ A ]Nf
rename[]Nf {Γ}{Δ}{K}{J} ρ A B =
  trans (rename-reify _ ρ (eval (embNf B [ embNf A ]) idEnv))
        (cong (reify _)
              (trans (rename-eval idEnv ρ (embNf B [ embNf A ]))
                     (trans (trans (eval-cong _ _ (rename-reflect _ ρ ∘ `) (embNf B [ embNf A ]) ) (eval-rename ρ idEnv (embNf B [ embNf A ])))
                            (cong (λ (t : Δ ⊢⋆ J) → eval t (idEnv {Δ})) (trans (trans (trans (sym (≡-to-≅ (rename-subst (subst-cons ` (embNf A)) ρ (embNf B)))) (sym (≡-to-≅ (subst-cong _ _ (rename-subst-cons ρ (embNf A) ) (embNf B))))) (≡-to-≅ (subst-rename (ext ρ) (subst-cons ` (rename ρ (embNf A))) (embNf B)))) (cong₂ (λ (A : Δ ⊢⋆ K)(B : Δ ,⋆ K ⊢⋆ J) → subst (subst-cons ` A) B) (sym (≡-to-≅ (rename-embNf ρ A))) (sym (≡-to-≅ (rename-embNf (ext ρ) B)))) )) )))
\end{code}

{-
\begin{code}
postulate
 subst[]Nf : ∀{Γ Δ K J}
  (ρ : ∀{K} → Γ ∋⋆ K → Δ ⊢Nf⋆ K)
  → (A : Γ ⊢Nf⋆ K)
  → (B : Γ ,⋆ K ⊢Nf⋆ J)
  → substNf ρ (B [ A ]Nf) ≅ reify _ (eval (subst (exts (embNf ∘ ρ)) (embNf B)) ((renval _ S ∘ reflect _ ∘ `) ,,⋆ reflect _ (` Z))) [ substNf ρ A ]Nf
  -- substNf (extsNf ρ) B [ substNf ρ A ]Nf 
\end{code}

## substNf-id: 
* I think this is needed to define _[_] for terms and it relies on stability.
* Stability doesn't hold if you have an eta expanding reify and don't enforce eta expansion in normal forms.
* Stability does hold if you enforce eta expansion in normal forms (by only embedding neutrals at base type) and I think substNf-id should hold too.
* However, I don't think the approach to reasoning about 'equal' values in this file is extensional enough to prove it.

\begin{code}
postulate
  substNf-id : ∀ {Φ J}
    → (n : Φ ⊢Nf⋆ J)
    → substNf (nf ∘ `) n ≅ n
\end{code}

\begin{code}
postulate
 substNf-renameNf : ∀{Φ Ψ Θ}
  (g : ∀ {J} → Φ ∋⋆ J → Ψ ∋⋆ J)
  (f : ∀ {J} → Ψ ∋⋆ J → Θ ⊢Nf⋆ J)
  → ∀{J}(A : Φ ⊢Nf⋆ J)
    -----------------------------------------
  → substNf (f ∘ g) A ≅ substNf f (renameNf g A)
\end{code}

\begin{code}
postulate
 renameNf-substNf : ∀{Φ Ψ Θ}
  (g : ∀ {J} → Φ ∋⋆ J → Ψ ⊢Nf⋆ J)
  (f : ∀ {J} → Ψ ∋⋆ J → Θ ∋⋆ J)
  → ∀{J}(A : Φ ⊢Nf⋆ J)
    -------------------------------------------------
  → substNf (renameNf f ∘ g) A ≅ renameNf f (substNf g A)
\end{code}
-}
\begin{code}
substNf-cons : ∀{Φ Ψ} → (∀{K} → Φ ∋⋆ K → Ψ ⊢Nf⋆ K) → ∀{J}(A : Ψ ⊢Nf⋆ J) →
             (∀{K} → Φ ,⋆ J ∋⋆ K → Ψ ⊢Nf⋆ K)
substNf-cons f A Z = A
substNf-cons f A (S x) = f x
\end{code}
