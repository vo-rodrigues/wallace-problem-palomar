import Wallace

/-!
# Proved solutions for the Palomar statement surface

The substantive proof is the `lean/` project in
`vo-rodrigues/wallace-problem-zfc-paper`, pinned by `lake-manifest.json` and
`formalization.yaml`. This module exposes two headline results with the
same Mathlib-only types used in `Challenge.lean`.
-/

open Cardinal Filter Topology

namespace Wallace.Palomar

noncomputable section

theorem torsionFreeAbelianGroup_mainTheorem
    (G : Type) [AddCommGroup G] [IsAddTorsionFree G]
    (hcard : #G = 𝔠) :
    ∃ topology : TopologicalSpace G,
      @IsTopologicalAddGroup G topology _ ∧
      @T2Space G topology ∧
      @CountablyCompactSpace G topology ∧
      (∀ (s : ℕ → G) (x : G),
        Tendsto s atTop (@nhds G topology x) →
          ∀ᶠ n in atTop, s n = x) :=
  Wallace.torsionFreeAbelianGroup_mainTheorem_exact G hcard

theorem commutativeTychonoffWallaceCounterexampleExists :
    ∃ (S : Type) (topology : TopologicalSpace S) (monoid : AddCommMonoid S),
      @ContinuousAdd S topology monoid.toAdd ∧
      @IsCancelAdd S monoid.toAdd ∧
      @T2Space S topology ∧
      @T35Space S topology ∧
      @CountablyCompactSpace S topology ∧
      ∃ x : S, ¬ @IsAddUnit S monoid.toAddMonoid x := by
  obtain ⟨S, topology, monoid, hT35, hwallace⟩ :=
    Wallace.commutativeTychonoffWallaceCounterexampleExists
  exact ⟨S, topology, monoid, hwallace.1, hwallace.2.1,
    hwallace.2.2.1, hT35, hwallace.2.2.2.1, hwallace.2.2.2.2⟩

end

end Wallace.Palomar
