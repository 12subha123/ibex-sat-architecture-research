#!/usr/bin/env python3
import json
from pathlib import Path

# Variable numbering follows ArchitectureCNF.lean.
names = [
    "branchTargetALU",
    "writebackStage",
    "secureIbex",
    "rv32bHigh",
    "rv32bLow",
    "rv32mHigh",
    "rv32mLow",
    "regFile",
]

# (!rv32bHigh OR !rv32bLow)
# (!secureIbex OR rv32mHigh OR rv32mLow)
clauses = [
    [-4, -5],
    [-3, 6, 7],
]

def propagate(clauses, assignment):
    while True:
        changed = False
        for clause in clauses:
            if any(
                (lit > 0 and assignment.get(abs(lit)) is True)
                or (lit < 0 and assignment.get(abs(lit)) is False)
                for lit in clause
            ):
                continue
            remaining = [lit for lit in clause if abs(lit) not in assignment]
            if not remaining:
                return None
            if len(remaining) == 1:
                lit = remaining[0]
                assignment[abs(lit)] = lit > 0
                changed = True
        if not changed:
            return assignment

def solve(clauses, assignment=None):
    assignment = propagate(clauses, dict(assignment or {}))
    if assignment is None:
        return None
    if all(any(
        (lit > 0 and assignment.get(abs(lit)) is True)
        or (lit < 0 and assignment.get(abs(lit)) is False)
        for lit in clause
    ) for clause in clauses):
        return assignment
    var = next(i for i in range(1, len(names) + 1) if i not in assignment)
    for value in (True, False):
        result = solve(clauses, {**assignment, var: value})
        if result is not None:
            return result
    return None

# Deterministic SAT solving, with a preference for enabling the two
# performance-related Boolean options. These are preferences, not proofs
# of PPA optimality.
result = solve(clauses, {1: True, 2: True})
if result is None:
    raise SystemExit("UNSAT")

result = {name: result.get(i, False) for i, name in enumerate(names, 1)}

out = Path("build-candidates/sat_selected")
out.mkdir(parents=True, exist_ok=True)

(out / "sat_assignment.json").write_text(json.dumps({
    "model": "ArchitectureCNF",
    "scope": "six-field provisional model",
    "solver": "Python DPLL",
    "selection": "SAT witness with BranchTargetALU and WritebackStage preferred true",
    "assignment": result,
    "cnf_clauses": clauses,
    "status": "SAT",
    "rtl_mapping_status": "Pending Lean encoding correspondence"
}, indent=2) + "\n")

with Path("sat/ibex_architecture.cnf").open("w") as f:
    f.write("c Provisional Ibex ArchitectureCNF\n")
    f.write(f"p cnf {len(names)} {len(clauses)}\n")
    for clause in clauses:
        f.write(" ".join(map(str, clause)) + " 0\n")

print("SAT")
print(json.dumps(result, indent=2))
print("Saved build-candidates/sat_selected/sat_assignment.json")
print("Saved sat/ibex_architecture.cnf")
