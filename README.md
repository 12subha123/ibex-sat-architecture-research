# SAT-Guided Ibex Architecture Research

A research prototype exploring SAT-based encoding, formal reasoning,
architecture candidate selection, and physical implementation of Ibex CPU
configurations.

This repository records a provisional architecture model and one
SAT-selected candidate. It does **not** establish a globally optimal Ibex
architecture.

## Research roadmap

1. Expand the six-field provisional model into a more complete RTL-constrained Ibex architecture space.
2. Eliminate duplicate architecture representations in the expanded model.
3. Develop exact-count-guided architecture exploration.
4. Select promising candidate architectures.
5. Elaborate and functionally verify the candidate RTL configurations.
6. Synthesize candidates and compare standard-cell area and timing.
7. Perform placement and routing.
8. Compare wirelength, signal-metal area, congestion, timing and area.
9. Identify and validate the best practical architecture.

## Provisional SAT model

The current ArchitectureCNF uses eight Boolean variables to encode six
architecture settings. RV32B and RV32M each use two Boolean encoding bits.

Its clauses are:

- `(!rv32bHigh OR !rv32bLow)`
- `(!secureIbex OR rv32mHigh OR rv32mLow)`

The provisional CNF has **168 satisfying assignments**. This count applies
only to this CNF, not the complete RTL-constrained Ibex architecture space.

The Python DPLL solver prefers BranchTargetALU and WritebackStage enabled.
These are selection heuristics, not a PPA optimization proof.

## SAT-selected candidate

| Setting | Value |
|---|---|
| BranchTargetALU | 1 |
| WritebackStage | 1 |
| SecureIbex | 1 |
| RV32B | RV32BFull |
| RV32M | RV32MFast |
| RegFile | RegFileFF |

The Lean theorem proves that this assignment satisfies the provisional CNF
and decodes to the architecture shown above.

**Candidate A is separate.** `sat/connect_sat_to_ibex.py` generates a
different baseline configuration. Candidate A is not the SAT-selected
candidate used for the synthesis and placement measurements.

## Lean formalization

The Ibex-specific Lean development contains four modules:

- `ArchitectureCNF.lean`: provisional Boolean encoding and exact count.
- `ExpandedArchitecture.lean`: expanded architecture fields and canonicalization.
- `SATSelectedCandidate.lean`: SAT witness and decoding theorem.
- `ExactCountBridge.lean`: finite-variable bridge for the provisional CNF.

The expanded model contains additional architecture fields, but its validity
constraints are incomplete. Canonicalization is proved for the modeled
representation; completeness and exact correspondence with all legal Ibex
RTL configurations are not established.

The exact-count bridge preserves the provisional CNF count of 168. It does
not execute the subexponential counting algorithm on the expanded Ibex
architecture space.

The wider `OAI.Algorithms.SubexponentialSAT` dependency is not vendored here.
See [formalization/README.md](formalization/README.md) for dependency details.

## Synthesis

The SAT-selected candidate was synthesized using Yosys and SV2V with the
Nangate45 standard-cell library.

The RVFI-enabled conversion encountered a Yosys parser limitation.
Synthesis therefore used a separate configuration without RVFI. This is
synthesis evidence, not functional verification.

Reported results:

| Metric | Result |
|---|---:|
| Initial mapped cell count | 36,012 |
| Initial mapped area | 62,023.752 |
| Latch-mapped cell area | 62,026.412 |
| Explicitly mapped clock-gating latch | 1 DLL_X1 |

The clock-latch mapping check found zero remaining `$dlatch` cells and
exactly one `DLL_X1`. These results describe this synthesis configuration,
not a comparison across the full architecture space.

## Placement

The latch-mapped synthesis netlist was placed using OpenROAD.

| Metric | Result |
|---|---:|
| Placed standard-cell area | 68,798.8053 |
| Placed components | 35,908 |
| Nets | 42,070 |
| Detailed-placement failures | 0 |
| HPWL before legalization | 565,793.6 |
| HPWL after legalization | 593,217.5 |
| Die dimensions | 827.57 x 827.57 um |

Placement completed without detailed-placement failures. These are
placement-stage measurements, not routed results.

**Important limitations:** routing has not been completed. Wire RC was not
configured for meaningful parasitic timing estimation, and the placement
flow emitted a warning about the zero default wire-capacitance corner.
No sign-off timing, congestion, or signal-metal-area result is claimed.

## Research status

| Roadmap step | Current status |
|---|---|
| 1. Expand the RTL-constrained architecture model | Partial |
| 2. Eliminate duplicate representations | Canonicalization developed; full coverage pending |
| 3. Develop exact-count-guided exploration | Provisional exact count only |
| 4. Select promising candidates | One SAT witness selected |
| 5. Elaborate and functionally verify candidates | Pending |
| 6. Synthesize and compare area and timing | One candidate synthesized |
| 7. Placement and routing | Placement completed; routing pending |
| 8. Compare physical metrics | Partial placement metrics available |
| 9. Identify and validate the best practical architecture | Pending |

This repository is an intermediate research artifact. It does not claim
functional RTL verification, exhaustive architecture exploration, a
completed routing flow, or a globally optimal architecture.

The physical-design scripts reference development-machine tool and PDK
paths. The PDK and external tool installations are not included.

## Repository contents

- `formalization/`: Ibex-specific Lean modules and Lean project metadata.
- `sat/`: provisional CNF, Python DPLL solver, and RTL candidate connector.
- `results/`: SAT-selected assignment with its current verification status.
- `physical-design/sat-candidate/`: synthesis netlists, scripts, logs, and
  placement output for the SAT-selected candidate.

The provisional SAT model, expanded Lean model, selected witness, and
physical-design artifacts represent distinct stages of the research.
Their results must not be treated as interchangeable.

## Scope of claims

All counts and measurements in this repository are limited to the stated
models, configurations, and tool runs. Further RTL correspondence,
functional verification, architecture-space completeness, routed PPA
analysis, and candidate comparison remain research tasks.
