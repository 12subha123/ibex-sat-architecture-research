import OAI.Algorithms.SubexponentialSAT.SAT

namespace OAI.Algorithms.SubexponentialSAT.Ibex

open SubexponentialSAT.SAT

inductive Var
  | branchTargetALU
  | writebackStage
  | secureIbex
  | rv32bHigh
  | rv32bLow
  | rv32mHigh
  | rv32mLow
  | regFile
  deriving DecidableEq

instance : Fintype Var where
  elems := {
    .branchTargetALU, .writebackStage, .secureIbex,
    .rv32bHigh, .rv32bLow, .rv32mHigh, .rv32mLow, .regFile
  }
  complete := by
    intro x
    cases x <;> simp

private def lit (v : Var) (positive : Bool) : Literal Var :=
  ⟨v, positive⟩

def rv32bClause : Clause Var :=
  {lit .rv32bHigh false, lit .rv32bLow false}

def secureMultiplierClause : Clause Var :=
  {lit .secureIbex false, lit .rv32mHigh true, lit .rv32mLow true}

def architectureCNF : CNF Var :=
  {rv32bClause, secureMultiplierClause}

theorem architectureCNF_width :
    WidthAtMost 3 architectureCNF := by
  intro C hC
  simp only [architectureCNF, Finset.mem_insert, Finset.mem_singleton] at hC
  rcases hC with h | h
  · subst C
    simp [rv32bClause, lit]
  · subst C
    simp [secureMultiplierClause, lit]

end OAI.Algorithms.SubexponentialSAT.Ibex

namespace OAI.Algorithms.SubexponentialSAT.Ibex

set_option maxRecDepth 10000
theorem architectureCNF_count :
    SubexponentialSAT.SAT.count architectureCNF = 168 := by
  decide

end OAI.Algorithms.SubexponentialSAT.Ibex

namespace OAI.Algorithms.SubexponentialSAT.Ibex

open SubexponentialSAT.SAT
theorem architectureCNF_sat_iff (a : Assignment Var) :
    architectureCNF.eval a = true ↔
      (a Var.rv32bHigh = false ∨ a Var.rv32bLow = false) ∧
      (a Var.secureIbex = false ∨
       a Var.rv32mHigh = true ∨ a Var.rv32mLow = true) := by
  simp [architectureCNF, CNF.eval, rv32bClause,
    secureMultiplierClause, Clause.eval, lit]

end OAI.Algorithms.SubexponentialSAT.Ibex

namespace OAI.Algorithms.SubexponentialSAT.Ibex

open SubexponentialSAT.SAT

inductive RV32BMode
  | none
  | balanced
  | full
  deriving DecidableEq

instance : Fintype RV32BMode where
  elems := {.none, .balanced, .full}
  complete := by
    intro x
    cases x <;> simp

inductive RV32MMode
  | none
  | slow
  | fast
  | singleCycle
  deriving DecidableEq

instance : Fintype RV32MMode where
  elems := {.none, .slow, .fast, .singleCycle}
  complete := by
    intro x
    cases x <;> simp

structure Architecture where
  branchTargetALU : Bool
  writebackStage : Bool
  secureIbex : Bool
  rv32b : RV32BMode
  rv32m : RV32MMode
  regFile : Bool
  deriving DecidableEq, Fintype

def encodeRV32BHigh : RV32BMode → Bool
  | .full => true
  | _ => false

def encodeRV32BLow : RV32BMode → Bool
  | .balanced => true
  | _ => false

def decodeRV32B (high low : Bool) : RV32BMode :=
  match high, low with
  | false, false => .none
  | false, true => .balanced
  | true, false => .full
  | true, true => .none

def encodeRV32MHigh : RV32MMode → Bool
  | .fast => true
  | .singleCycle => true
  | _ => false

def encodeRV32MLow : RV32MMode → Bool
  | .slow => true
  | .singleCycle => true
  | _ => false

def decodeRV32M (high low : Bool) : RV32MMode :=
  match high, low with
  | false, false => .none
  | false, true => .slow
  | true, false => .fast
  | true, true => .singleCycle

def encodeArchitecture (A : Architecture) : Assignment Var :=
  fun v =>
    match v with
    | .branchTargetALU => A.branchTargetALU
    | .writebackStage => A.writebackStage
    | .secureIbex => A.secureIbex
    | .rv32bHigh => encodeRV32BHigh A.rv32b
    | .rv32bLow => encodeRV32BLow A.rv32b
    | .rv32mHigh => encodeRV32MHigh A.rv32m
    | .rv32mLow => encodeRV32MLow A.rv32m
    | .regFile => A.regFile

def decodeArchitecture (a : Assignment Var) : Architecture where
  branchTargetALU := a .branchTargetALU
  writebackStage := a .writebackStage
  secureIbex := a .secureIbex
  rv32b := decodeRV32B (a .rv32bHigh) (a .rv32bLow)
  rv32m := decodeRV32M (a .rv32mHigh) (a .rv32mLow)
  regFile := a .regFile

end OAI.Algorithms.SubexponentialSAT.Ibex

namespace OAI.Algorithms.SubexponentialSAT.Ibex

theorem decodeRV32B_encode (m : RV32BMode) :
    decodeRV32B (encodeRV32BHigh m) (encodeRV32BLow m) = m := by
  cases m <;> rfl

theorem decodeRV32M_encode (m : RV32MMode) :
    decodeRV32M (encodeRV32MHigh m) (encodeRV32MLow m) = m := by
  cases m <;> rfl

theorem decodeArchitecture_encodeArchitecture (A : Architecture) :
    decodeArchitecture (encodeArchitecture A) = A := by
  cases A with
  | mk branch writeback secure b m reg =>
      simp [decodeArchitecture, encodeArchitecture,
        decodeRV32B_encode, decodeRV32M_encode]

end OAI.Algorithms.SubexponentialSAT.Ibex

namespace OAI.Algorithms.SubexponentialSAT.Ibex

open SubexponentialSAT.SAT

theorem encodeArchitecture_decodeArchitecture
    (a : Assignment Var)
    (ha : architectureCNF.eval a = true) :
    encodeArchitecture (decodeArchitecture a) = a := by
  have hvalid := (architectureCNF_sat_iff a).mp ha
  funext v
  cases v with
  | branchTargetALU => rfl
  | writebackStage => rfl
  | secureIbex => rfl
  | regFile => rfl
  | rv32bHigh =>
      change encodeRV32BHigh
        (decodeRV32B (a Var.rv32bHigh) (a Var.rv32bLow)) =
        a Var.rv32bHigh
      cases hb : a Var.rv32bHigh <;>
        cases lb : a Var.rv32bLow <;>
        simp_all [decodeRV32B, encodeRV32BHigh]
  | rv32bLow =>
      change encodeRV32BLow
        (decodeRV32B (a Var.rv32bHigh) (a Var.rv32bLow)) =
        a Var.rv32bLow
      cases hb : a Var.rv32bHigh <;>
        cases lb : a Var.rv32bLow <;>
        simp_all [decodeRV32B, encodeRV32BLow]
  | rv32mHigh =>
      change encodeRV32MHigh
        (decodeRV32M (a Var.rv32mHigh) (a Var.rv32mLow)) =
        a Var.rv32mHigh
      cases hb : a Var.rv32mHigh <;>
        cases lb : a Var.rv32mLow <;>
        simp [decodeRV32M, encodeRV32MHigh, hb, lb]
  | rv32mLow =>
      change encodeRV32MLow
        (decodeRV32M (a Var.rv32mHigh) (a Var.rv32mLow)) =
        a Var.rv32mLow
      cases hb : a Var.rv32mHigh <;>
        cases lb : a Var.rv32mLow <;>
        simp [decodeRV32M, encodeRV32MLow, hb, lb]

end OAI.Algorithms.SubexponentialSAT.Ibex

namespace OAI.Algorithms.SubexponentialSAT.Ibex

theorem encodeArchitecture_sat_iff (A : Architecture) :
    architectureCNF.eval (encodeArchitecture A) = true ↔
      (A.secureIbex = false ∨ A.rv32m ≠ RV32MMode.none) := by
  rw [architectureCNF_sat_iff]
  cases A with
  | mk branch writeback secure b m reg =>
      cases b <;> cases secure <;> cases m <;>
        simp [encodeArchitecture, encodeRV32BHigh, encodeRV32BLow,
          encodeRV32MHigh, encodeRV32MLow]

end OAI.Algorithms.SubexponentialSAT.Ibex

namespace OAI.Algorithms.SubexponentialSAT.Ibex

/-- Architectures satisfying the verified SecureIbex/RV32M constraint. -/
def Architecture.Valid (A : Architecture) : Prop :=
  A.secureIbex = false ∨ A.rv32m ≠ RV32MMode.none

/-- Valid architectures and satisfying CNF assignments are in bijection. -/
def validArchitectureEquivSatisfyingAssignment :
    {A : Architecture // Architecture.Valid A} ≃
    {a : OAI.Algorithms.SubexponentialSAT.SAT.Assignment Var // architectureCNF.eval a = true} where
  toFun A :=
    ⟨encodeArchitecture A.val,
      (encodeArchitecture_sat_iff A.val).2 A.property⟩
  invFun a :=
    ⟨decodeArchitecture a.val,
      (encodeArchitecture_sat_iff (decodeArchitecture a.val)).1
        (by
          rw [encodeArchitecture_decodeArchitecture a.val a.property]
          exact a.property)⟩
  left_inv A := by
    apply Subtype.ext
    exact decodeArchitecture_encodeArchitecture A.val
  right_inv a := by
    apply Subtype.ext
    exact encodeArchitecture_decodeArchitecture a.val a.property

end OAI.Algorithms.SubexponentialSAT.Ibex

namespace OAI.Algorithms.SubexponentialSAT.Ibex

instance (A : Architecture) : Decidable (Architecture.Valid A) := by
  unfold Architecture.Valid
  infer_instance

instance validArchitectureFintype :
    Fintype {A : Architecture // Architecture.Valid A} :=
  Fintype.subtype
    (Finset.univ.filter fun A : Architecture => Architecture.Valid A)
    (by
      intro A
      simp)

/-- The provisional six-field model has exactly 168 valid architectures. -/
theorem validArchitecture_count :
    Fintype.card {A : Architecture // Architecture.Valid A} = 168 := by
  calc
    Fintype.card {A : Architecture // Architecture.Valid A} =
        Fintype.card
          {a : OAI.Algorithms.SubexponentialSAT.SAT.Assignment Var //
            architectureCNF.eval a = true} :=
      Fintype.card_congr validArchitectureEquivSatisfyingAssignment
    _ = OAI.Algorithms.SubexponentialSAT.SAT.count architectureCNF :=
      (OAI.Algorithms.SubexponentialSAT.SAT.count_eq_card_subtype
        architectureCNF).symm
    _ = 168 := architectureCNF_count

end OAI.Algorithms.SubexponentialSAT.Ibex
