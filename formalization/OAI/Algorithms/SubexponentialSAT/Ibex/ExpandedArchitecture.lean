import OAI.Algorithms.SubexponentialSAT.Ibex.ArchitectureCNF

namespace OAI.Algorithms.SubexponentialSAT.Ibex

inductive BaseIsaMode
  | rv32i
  | cheriot
  deriving DecidableEq, Repr

inductive RV32ZCMode
  | zca
  | zcaZcb
  | zcaZcmp
  | zcaZcbZcmp
  deriving DecidableEq, Repr

inductive RegFileMode
  | ff
  | fpga
  | latch
  deriving DecidableEq, Repr

structure ExpandedArchitecture where
  baseIsa : BaseIsaMode
  rv32e : Bool
  rv32m : RV32MMode
  rv32b : RV32BMode
  rv32zc : RV32ZCMode
  regFile : RegFileMode
  branchTargetALU : Bool
  writebackStage : Bool
  secureIbex : Bool
  pmpEnable : Bool
  pmpGranularity : Nat
  pmpNumRegions : Nat
  mhpmCounterNum : Nat
  mhpmCounterWidth : Nat
  icache : Bool
  icacheECC : Bool
  icacheScramble : Bool
  icacheScrNumPrinceRoundsHalf : Nat
  icacheTweakInfection : Bool
  branchPredictor : Bool
  dbgTriggerEn : Bool
  dbgHwBreakNum : Nat
  memECC : Bool
  memDataWidth : Nat
  lockstepOffset : Nat
  cheriRevBitmapAddrWidth : Nat
  cheriRevBitmapBaseAddr : Nat
  deriving DecidableEq

/-- Replace inactive conditional settings with one canonical representative. -/
def canonicalize (A : ExpandedArchitecture) : ExpandedArchitecture :=
  { A with
    pmpGranularity := if A.pmpEnable then A.pmpGranularity else 0
    pmpNumRegions := if A.pmpEnable then A.pmpNumRegions else 4
    mhpmCounterWidth :=
      if A.mhpmCounterNum > 0 then A.mhpmCounterWidth else 40
    dbgHwBreakNum := if A.dbgTriggerEn then A.dbgHwBreakNum else 1
    lockstepOffset := if A.secureIbex then A.lockstepOffset else 1
    icacheECC := if A.icache then A.icacheECC else false
    icacheTweakInfection :=
      if A.icache then A.icacheTweakInfection else false
    icacheScrNumPrinceRoundsHalf :=
      if A.icacheScramble then A.icacheScrNumPrinceRoundsHalf else 2
    cheriRevBitmapAddrWidth :=
      if A.baseIsa = .cheriot then A.cheriRevBitmapAddrWidth else 11
    cheriRevBitmapBaseAddr :=
      if A.baseIsa = .cheriot then A.cheriRevBitmapBaseAddr else 0 }

/-- RTL-derived and documented constraints audited so far. -/
def ExpandedArchitecture.Valid (A : ExpandedArchitecture) : Prop :=
  (A.secureIbex = true → A.rv32m ≠ .none) ∧
  (A.baseIsa = .cheriot → A.writebackStage = true) ∧
  (A.pmpEnable = true →
    A.pmpGranularity ≤ 31 ∧ 1 ≤ A.pmpNumRegions ∧ A.pmpNumRegions ≤ 16) ∧
  (A.mhpmCounterNum ≤ 10) ∧
  (A.mhpmCounterNum > 0 →
    1 ≤ A.mhpmCounterWidth ∧ A.mhpmCounterWidth ≤ 64) ∧
  (A.dbgTriggerEn = true → 1 ≤ A.dbgHwBreakNum) ∧
  (A.secureIbex = true → 1 ≤ A.lockstepOffset) ∧
  (A.icacheScramble = true →
    1 ≤ A.icacheScrNumPrinceRoundsHalf ∧
    A.icacheScrNumPrinceRoundsHalf ≤ 5) ∧
  (A.baseIsa = .cheriot →
    1 ≤ A.cheriRevBitmapAddrWidth ∧
    A.cheriRevBitmapAddrWidth ≤ 26 ∧
    A.cheriRevBitmapBaseAddr % 4 = 0) ∧
  (A.memDataWidth = 32 ∨ A.memDataWidth = 39)

/-- Canonical forms are fixed points of canonicalization. -/
def IsCanonical (A : ExpandedArchitecture) : Prop :=
  canonicalize A = A

theorem canonicalize_idempotent (A : ExpandedArchitecture) :
    canonicalize (canonicalize A) = canonicalize A := by
  cases A <;> simp [canonicalize] <;> aesop

theorem canonicalize_isCanonical (A : ExpandedArchitecture) :
    IsCanonical (canonicalize A) := by
  exact canonicalize_idempotent A

end OAI.Algorithms.SubexponentialSAT.Ibex
