import Mathlib

/-!
# The Wallace problem in ZFC: statement surface

This is the small, human-auditable statement surface for two headline
results of Trianon Fraga and de Oliveira Rodrigues, *The Wallace problem and
countably compact torsion-free Abelian groups in ZFC* (arXiv:2608.17317v1).
It imports only Mathlib and deliberately contains one proof hole for each
advertised theorem; `Solution.lean` supplies the proofs from the pinned
formalization.

The first theorem is universal over torsion-free Abelian groups of cardinality
continuum. The second gives the negative answer to Wallace's question: a
commutative Tychonoff countably compact cancellative topological monoid that is
not a group. These results belong to topological algebra and general topology,
with a natural audience among researchers in topological groups and semigroups.

Here “in ZFC” is represented by a classical Lean proof with no project-specific
or additional set-theoretic axiom. Comparator checks that the Solution proofs
use only `propext`, `Classical.choice`, and `Quot.sound`. Lean's type theory,
kernel, and the pinned Mathlib definitions remain the trusted formal boundary.
-/

open Cardinal Filter Topology

namespace Wallace.Palomar

/-- Every torsion-free Abelian group `G` of cardinality continuum admits a
Hausdorff countably compact group topology in which every convergent sequence
is eventually constant. The theorem is stated for `G : Type` (universe zero),
matching the continuum-sized groups considered in the paper. -/
theorem torsionFreeAbelianGroup_mainTheorem
    (G : Type) [AddCommGroup G] [IsAddTorsionFree G]
    (hcard : #G = 𝔠) :
    ∃ topology : TopologicalSpace G,
      @IsTopologicalAddGroup G topology _ ∧
      @T2Space G topology ∧
      @CountablyCompactSpace G topology ∧
      (∀ (s : ℕ → G) (x : G),
        Tendsto s atTop (@nhds G topology x) →
          ∀ᶠ n in atTop, s n = x) := by
  sorry

/-- There exists a commutative Tychonoff countably compact topological
additive monoid with two-sided cancellation and a noninvertible element. In
particular, it is not a group and gives the paper's negative answer to
Wallace's question. -/
theorem commutativeTychonoffWallaceCounterexampleExists :
    ∃ (S : Type) (topology : TopologicalSpace S) (monoid : AddCommMonoid S),
      @ContinuousAdd S topology monoid.toAdd ∧
      @IsCancelAdd S monoid.toAdd ∧
      @T2Space S topology ∧
      @T35Space S topology ∧
      @CountablyCompactSpace S topology ∧
      ∃ x : S, ¬ @IsAddUnit S monoid.toAddMonoid x := by
  sorry

end Wallace.Palomar
