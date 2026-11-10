import OAI.Algorithms.SubexponentialSAT.Ibex.ArchitectureCNF

namespace OAI.Algorithms.SubexponentialSAT.Ibex

open SubexponentialSAT.SAT

def selectedAssignment : Assignment Var :=
  fun v =>
    match v with
    | .branchTargetALU => true
    | .writebackStage => true
    | .secureIbex => true
    | .rv32bHigh => true
    | .rv32bLow => false
    | .rv32mHigh => true
    | .rv32mLow => false
    | .regFile => false

def selectedArchitecture : Architecture :=
  decodeArchitecture selectedAssignment

theorem selectedAssignment_sat :
    architectureCNF.eval selectedAssignment = true := by
  decide

theorem selectedArchitecture_decodes :
    selectedArchitecture =
      { branchTargetALU := true
        writebackStage := true
        secureIbex := true
        rv32b := .full
        rv32m := .fast
        regFile := false } := by
  rfl

end OAI.Algorithms.SubexponentialSAT.Ibex
