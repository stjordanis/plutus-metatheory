\begin{code}
module Everything where

-- Types

import Type
import Type.RenamingSubstitution
import Type.Reduction
import Type.Equality

-- a beta NBE algorithm and accompanying soundness, completeness and
-- stability proofs and necessary equipment for substituting into
-- normal types by embedding back into syntax, substituting and
-- renormalising


import Type.BetaNormal
import Type.BetaNBE
import Type.BetaNBE.Soundness
import Type.BetaNBE.Completeness
import Type.BetaNBE.Stability
import Type.BetaNBE.RenamingSubstitution
-- a complete attempt to index terms by syntactic types where
-- conversion takes an equation as an argument. Evaluation only works
-- in the absense of conversions in terms.

-- Builtins
import Builtin.Signature
import Builtin.Constant.Type
import Builtin.Constant.Term

import Declarative.Term
import Declarative.Term.RenamingSubstitution
import Declarative.Term.Reduction
import Declarative.Evaluation

import Declarative.Examples
import Declarative.StdLib.Unit
import Declarative.StdLib.Bool
import Declarative.StdLib.Function
import Declarative.StdLib.ChurchNat
import Declarative.StdLib.Nat
import Declarative.test.Main

-- Terms, reduction and evaluation where terms are indexed by normal
-- types

import Algorithmic.Term
import Algorithmic.Term.RenamingSubstitution
import Algorithmic.Term.Reduction
import Algorithmic.Evaluation
import Algorithmic.Examples
import Algorithmic.Main
import Algorithmic.Soundness
import Algorithmic.Completeness

-- Terms, that carry witnesses of their type's reduction to normal form

import AlgorithmicRed.Term
import AlgorithmicRed.Term.RenamingSubstitution
\end{code}
