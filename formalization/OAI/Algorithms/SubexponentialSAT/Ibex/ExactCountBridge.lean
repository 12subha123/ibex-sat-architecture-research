import OAI.Algorithms.SubexponentialSAT.Ibex.ArchitectureCNF
import OAI.Algorithms.SubexponentialSAT.Main
import OAI.Algorithms.SubexponentialSAT.SqrtLogSpace.Final
import OAI.Algorithms.SubexponentialSAT.SqrtLogSpace.VisitedTape
import OAI.Algorithms.SubexponentialSAT.SqrtLogSpace.EncodingBounds

namespace OAI.Algorithms.SubexponentialSAT.Ibex

open OAI.Algorithms.SubexponentialSAT
open OAI.Algorithms.SubexponentialSAT.SAT
open OAI.Algorithms.SubexponentialSAT.SqrtLogSpace

/-- Reindex the eight Ibex variables by Fin 8. -/
noncomputable def varEquivFin : Var ≃ Fin 8 := by
  have h : Fintype.card Var = 8 := by
    decide
  exact (Fintype.equivFin Var).trans (finCongr h)

/-- Transport a literal to the Fin 8 variable domain. -/
noncomputable def transportLiteral (l : Literal Var) :
    Literal (Fin 8) :=
  ⟨varEquivFin l.variable, l.positive⟩

/-- Transport a clause by renaming its variables. -/
noncomputable def transportClause (C : Clause Var) :
    Clause (Fin 8) :=
  C.image transportLiteral

/-- The Ibex architecture CNF represented over Fin 8. -/
noncomputable def ibexCNF : CNF (Fin 8) :=
  architectureCNF.image transportClause

theorem transportLiteral_injective :
    Function.Injective transportLiteral := by
  intro x y h
  cases x with
  | mk xv xp =>
    cases y with
    | mk yv yp =>
      simp [transportLiteral] at h
      cases h.1
      cases h.2
      rfl

theorem transportClause_card (C : Clause Var) :
    (transportClause C).card = C.card := by
  unfold transportClause
  rw [Finset.card_image_iff]
  intro x hx y hy hxy
  exact transportLiteral_injective hxy

theorem ibexCNF_width : WidthAtMost 3 ibexCNF := by
  intro C hC
  unfold ibexCNF at hC
  simp only [Finset.mem_image] at hC
  obtain ⟨D, hD, hEq⟩ := hC
  rw [← hEq, transportClause_card]
  exact architectureCNF_width D hD

end OAI.Algorithms.SubexponentialSAT.Ibex

namespace OAI.Algorithms.SubexponentialSAT.Ibex

open OAI.Algorithms.SubexponentialSAT.SAT
open OAI.Algorithms.SubexponentialSAT.SqrtLogSpace

/-- Convert logical equivalence into equality of Boolean decisions. -/
theorem decide_congr_local {P Q : Prop}
    [Decidable P] [Decidable Q] (h : P ↔ Q) :
    decide P = decide Q := by
  by_cases hp : P
  · have hq : Q := h.mp hp
    simp [hp, hq]
  · have hq : ¬ Q := fun hq => hp (h.mpr hq)
    simp [hp, hq]

/-- Transport an assignment from Var to Fin 8. -/
noncomputable def transportAssignment
    (a : Assignment Var) : Assignment (Fin 8) :=
  fun i => a (varEquivFin.symm i)

/-- Transport an assignment back from Fin 8 to Var. -/
noncomputable def untransportAssignment
    (a : Assignment (Fin 8)) : Assignment Var :=
  fun v => a (varEquivFin v)

theorem transportLiteral_eval (a : Assignment Var)
    (l : Literal Var) :
    (transportLiteral l).eval (transportAssignment a) = l.eval a := by
  simp [Literal.eval, transportLiteral, transportAssignment]

theorem transportClause_eval (a : Assignment Var)
    (C : Clause Var) :
    (transportClause C).eval (transportAssignment a) = C.eval a := by
  unfold Clause.eval
  apply decide_congr_local
  constructor
  · rintro ⟨l, hl, he⟩
    rcases Finset.mem_image.mp hl with ⟨l0, hl0, rfl⟩
    exact ⟨l0, hl0, by simpa [transportLiteral_eval] using he⟩
  · rintro ⟨l, hl, he⟩
    exact ⟨transportLiteral l,
      Finset.mem_image.mpr ⟨l, hl, rfl⟩,
      by simpa [transportLiteral_eval] using he⟩

theorem ibexCNF_eval (a : Assignment Var) :
    ibexCNF.eval (transportAssignment a) =
      architectureCNF.eval a := by
  apply Bool.eq_iff_iff.mpr
  rw [CNF.eval_eq_true, CNF.eval_eq_true]
  constructor
  · intro h D hD
    have hD' :
        transportClause D ∈ ibexCNF := by
      exact Finset.mem_image.mpr ⟨D, hD, rfl⟩
    have hc := h (transportClause D) hD'
    rw [transportClause_eval] at hc
    exact hc
  · intro h C hC
    unfold ibexCNF at hC
    rcases Finset.mem_image.mp hC with ⟨D, hD, rfl⟩
    have hc := h D hD
    rw [transportClause_eval]
    exact hc

/-- The assignment spaces are equivalent under variable renaming. -/
noncomputable def assignmentEquiv :
    Assignment Var ≃ Assignment (Fin 8) where
  toFun := transportAssignment
  invFun := untransportAssignment
  left_inv := by
    intro a
    funext v
    simp [transportAssignment, untransportAssignment]
  right_inv := by
    intro a
    funext i
    simp [transportAssignment, untransportAssignment]

/-- Satisfying assignments are preserved bijectively. -/
noncomputable def satisfyingAssignmentEquiv :
    {a : Assignment Var // architectureCNF.eval a = true} ≃
    {a : Assignment (Fin 8) // ibexCNF.eval a = true} where
  toFun a :=
    ⟨transportAssignment a.val, by
      rw [ibexCNF_eval]
      exact a.property⟩
  invFun a := by
    refine ⟨untransportAssignment a.val, ?_⟩
    have h := ibexCNF_eval (untransportAssignment a.val)
    have h' :
        ibexCNF.eval
            (transportAssignment (untransportAssignment a.val)) =
          ibexCNF.eval a.val :=
      congrArg (fun x : Assignment (Fin 8) => ibexCNF.eval x)
        (assignmentEquiv.right_inv a.val)
    exact (h.symm.trans h').trans a.property
  left_inv := by
    intro a
    apply Subtype.ext
    exact assignmentEquiv.left_inv a.val
  right_inv := by
    intro a
    apply Subtype.ext
    exact assignmentEquiv.right_inv a.val

/-- Exact count is unchanged by the Fin 8 transport. -/
theorem ibexCNF_count : SAT.count ibexCNF = 168 := by
  calc
    SAT.count ibexCNF =
        Fintype.card
          {a : Assignment (Fin 8) // ibexCNF.eval a = true} :=
      SAT.count_eq_card_subtype ibexCNF
    _ = Fintype.card
          {a : Assignment Var // architectureCNF.eval a = true} :=
      Fintype.card_congr satisfyingAssignmentEquiv.symm
    _ = SAT.count architectureCNF :=
      SAT.count_eq_card_subtype architectureCNF
    _ = 168 := architectureCNF_count


/-- The verified width-3 exact-counting machine applies to the encoded Ibex
architecture CNF, whose exact number of satisfying assignments is 168. -/
theorem ibex_exact_count_algorithm_exists :
    ∃ (machine : Computation.PrimitiveMachine)
      (countTape answerTape : Fin machine.tapeCount)
      (C A S : ℝ) (d e : ℕ),
      0 < C ∧ 0 < A ∧ 0 < S ∧ 0 < d ∧ 0 < e ∧
      ∀ (n : ℕ) (F : SAT.CNF (Fin n)), SAT.WidthAtMost 3 F →
        ∃ (time : ℕ) (final : LocatedCfg machine),
          Computation.Trace (locatedStep machine) time
            (locatedInit machine (Encoding.encodeCNF F)) final ∧
          final.config.tapes countTape =
            Turing.Tape.mk₁ ((countWord (SAT.count F)).map some) ∧
          final.config.tapes answerTape =
            Turing.Tape.mk₁ [some (decide (0 < SAT.count F))] ∧
          final.config.state = Sum.inl (decide (0 < SAT.count F)) ∧
          BinaryArithmetic.toNat (countWord (SAT.count F)) = SAT.count F ∧
          (countWord (SAT.count F)).length ≤ n + 1 ∧
          (time : ℝ) ≤
            OAI.Algorithms.SubexponentialSAT.SqrtLog.Statement.runtimeBound
              C A d (Encoding.formulaBitLength F) n ∧
          ∀ (prefixSteps : ℕ) (intermediate : LocatedCfg machine),
            prefixSteps ≤ time →
            Computation.Trace (locatedStep machine) prefixSteps
              (locatedInit machine (Encoding.encodeCNF F)) intermediate →
            (visitedSpace intermediate : ℝ) ≤
              S * ((Encoding.formulaBitLength F : ℝ) + 1) ^ e := by
  exact OAI.Algorithms.SubexponentialSAT.SqrtLogSpace.exact_count_and_sat
    3 (by omega)

end OAI.Algorithms.SubexponentialSAT.Ibex
