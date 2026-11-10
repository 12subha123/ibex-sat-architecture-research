#!/usr/bin/env python3
import json
from itertools import product
from pathlib import Path

# Exact eight Boolean variables in ArchitectureCNF.lean.
VARS = (
    "branchTargetALU",
    "writebackStage",
    "secureIbex",
    "rv32bHigh",
    "rv32bLow",
    "rv32mHigh",
    "rv32mLow",
    "regFile",
)

def satisfies(a):
    # architectureCNF clauses:
    # (!rv32bHigh OR !rv32bLow)
    # (!secureIbex OR rv32mHigh OR rv32mLow)
    return (
        (not a["rv32bHigh"] or not a["rv32bLow"])
        and
        (not a["secureIbex"] or a["rv32mHigh"] or a["rv32mLow"])
    )

all_assignments = []
for bits in product((False, True), repeat=len(VARS)):
    a = dict(zip(VARS, bits))
    if satisfies(a):
        all_assignments.append(a)

assert len(all_assignments) == 168, (
    f"Expected provisional count 168, got {len(all_assignments)}"
)

# Candidate A: BranchTargetALU=1, WritebackStage=1.
# Remaining settings correspond to the stated Ibex defaults:
# SecureIbex=0, RV32B=None, RV32M=Fast, RegFile=FF.
#
# The two RV32M bits are set to 11 for the assumed Fast encoding.
candidate = {
    "branchTargetALU": True,
    "writebackStage": True,
    "secureIbex": False,
    "rv32bHigh": False,
    "rv32bLow": False,
    "rv32mHigh": True,
    "rv32mLow": True,
    "regFile": False,
}

assert satisfies(candidate), "Candidate A does not satisfy the CNF"
assert candidate in all_assignments, "Candidate A assignment missing"

result = {
    "model": "ArchitectureCNF",
    "model_scope": "six-field provisional Ibex model",
    "provisional_satisfying_assignment_count": len(all_assignments),
    "candidate": "Candidate A",
    "sat_assignment": candidate,
    "rtl_parameters": {
        "BranchTargetALU": 1,
        "WritebackStage": 1,
        "SecureIbex": 0,
        "RV32B": "RV32BNone",
        "RV32M": "RV32MFast",
        "RegFile": "RegFileFF",
    },
    "cnf_satisfied": True,
    "selection_status": "SAT witness; not PPA-optimality proof",
}

out = Path("build-candidates/candidate_a/sat_assignment.json")
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(json.dumps(result, indent=2) + "\n")

print(json.dumps(result, indent=2))
print(f"\nWrote {out}")
