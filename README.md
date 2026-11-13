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

A separate historical RTL lint/elaboration run on November 5, 2026, contains
168 unique candidate IDs, with no duplicate IDs: 18 `PASS_CLEAN` and 150
`PASS_WITH_WARNINGS`, all with zero reported errors. This historical set does
**not** include the SAT-selected configuration. These results therefore do
not establish RTL validation of the selected candidate or functional
correctness of all 168 configurations.

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

**Candidate A comparison limitation:** The preserved converted RTL files
have different `ibex_core` interfaces: Candidate A has 61 ports, while the
SAT-selected conversion has 105. The 44 additional SAT-side ports are
RVFI-related outputs. Candidate A's `sat_assignment.json` identifies it
as a satisfying witness of the six-field provisional CNF, but its SV2V
logs are empty and the preserved artifacts do not establish its exact RTL
source revision or conversion source list. Consequently, Candidate A's
existing physical results are not a controlled baseline for comparative
PPA claims. A matched-feature synthesis run is exploratory evidence only;
it does not establish that either RTL implementation is architecturally
or physically superior.

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
| Nets | 42,068 |
| Detailed-placement failures | 0 |
| HPWL before legalization | 565,793.6 |
| HPWL after legalization | 593,217.5 |
| Die dimensions | 413.785 x 413.785 um |

Placement completed without detailed-placement failures. Detailed routing
also completed, with zero final router DRC violations. Routed wirelength was
813,605 um and the router reported 328,487 vias.

**Important limitations:** congestion was not measured or reported. Global-route
timing is exploratory only; final extracted timing and sign-off timing are
not established. The placement flow emitted a warning about zero default
wire capacitance. Signal-metal area is available only as a nominal-width
wirelength estimate, not an exact geometric area.

## Research status

| Roadmap step | Current status |
|---|---|
| 1. Expand the RTL-constrained architecture model | Partial |
| 2. Eliminate duplicate representations | Canonicalization proved for the modeled representation; full RTL-space coverage pending |
| 3. Develop exact-count-guided exploration | Provisional count of 168 and theorem-level algorithm-existence bridge; native algorithm execution not demonstrated |
| 4. Select promising candidates | One satisfying SAT witness selected using heuristics; no PPA-optimality proof |
| 5. Elaborate and functionally verify candidates | Selected configuration lint/elaboration and five targeted functional simulations passed; warnings and test scope documented |
| 6. Synthesize and compare area and timing | One selected configuration synthesized; controlled multi-candidate PPA comparison incomplete |
| 7. Placement and routing | Placement and detailed routing completed; zero final router DRC violations |
| 8. Compare physical metrics | Routed wirelength and vias measured; signal-metal area estimated; congestion and final extracted/sign-off timing unavailable |
| 9. Identify and validate the best practical architecture | Pending |

This repository is an intermediate research artifact. The SAT-selected
configuration passed lint/elaboration with warnings (three `UNOPTFLAT`
warnings; zero errors) and five targeted functional simulations:

- Custom functional test: signature `0x13579bdf`, 26 cycles.
- RV32I test: signature `0x0000002a`, 220 cycles.
- RV32M test: signature `0x0000002a`, 332 cycles.
- Extended RV32I test: signature `0x0000002a`, 239 cycles.
- Firmware smoke test: signature `0x0000002a`, 21 cycles.

Each simulation ended through software-requested `$finish`. These are
targeted functional tests, not a full RISC-V compliance-suite result or a
formal equivalence proof. The historical 168-candidate lint/elaboration
run is a separate dataset and does not include the SAT-selected candidate.

The selected configuration completed placement and detailed routing, with
zero final detailed-router DRC violations. Its routed wirelength was
813,605 um and the router reported 328,487 vias. Congestion was not measured,
and final extracted/sign-off timing was not established. The available
Candidate A comparison is not controlled, so no candidate is established
as physically superior. The project does not claim exhaustive architecture
exploration or a globally optimal architecture.

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
