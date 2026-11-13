# IBEX0165 Physical-Design Evaluation

## 1. Placement

Tool: OpenROAD

| Metric | Measured result |
|---|---:|
| Placed standard-cell area | 68,798.8053 µm² |
| Placed instances | 35,908 |
| Nets | 42,068 |
| Detailed-placement failures | 0 |
| Core area | 154,322.560 µm² |
| Die dimensions | 413.785 × 413.785 µm |
| Placement utilization | 44.581% |
| HPWL before legalization | 565,793.6 µm |
| HPWL after legalization | 593,217.5 µm |

Placement completed without detailed-placement failures.

## 2. Detailed Routing

Tool: OpenROAD detailed router

| Metric | Measured result |
|---|---:|
| Total routed wirelength | 813,605 µm |
| Total vias | 328,487 |
| Final router DRC violations | 0 |
| Routed net entries in DEF | 42,070 |
| Parsed route segments | 337,615 |

The authoritative routing log reports completion of detailed routing and
zero final router DRC violations. The final detailed-route DRC report is
empty. This is a router result, not independent foundry sign-off.

### 2.1 Routed wirelength by layer

| Layer | DEF wirelength (µm) | Segments |
|---|---:|---:|
| metal1 | 0.00 | 0 |
| metal2 | 279,625.45 | 194,419 |
| metal3 | 381,830.17 | 128,037 |
| metal4 | 112,162.52 | 13,285 |
| metal5 | 34,456.67 | 1,628 |
| metal6 | 3,681.30 | 236 |
| metal7 | 1,535.56 | 8 |
| metal8 | 6.40 | 1 |
| metal9 | 307.20 | 1 |
| metal10 | 0.00 | 0 |

Parsed DEF wirelength totals 813,605.28 µm, agreeing with the router's
813,605 µm total to within 0.28 µm.

## 3. Signal-Metal Area Estimate

Nominal routing widths were checked against the Nangate45 technology LEF.

| Layer | Nominal width (µm) |
|---|---:|
| metal1 | 0.070 |
| metal2 | 0.070 |
| metal3 | 0.070 |
| metal4 | 0.140 |
| metal5 | 0.140 |
| metal6 | 0.140 |
| metal7 | 0.400 |
| metal8 | 0.400 |
| metal9 | 0.800 |
| metal10 | 0.800 |

Applying nominal width × parsed centerline wirelength gives:

- Estimated aggregate signal-metal area: **68,206.51 µm²**
- Equivalent: **0.068207 mm²**

This is an estimate, not an exact geometric union area. It can double-count
overlaps and junctions and does not include via or obstruction geometry.
It assumes nominal layer widths and does not replace polygon-based area
extraction.

## 4. Timing and Congestion

The available global-route timing report uses estimated parasitics and
exploratory constraints (10 ns clock, 1 ns interface delay, and 5 fF
output load).

| Timing check | Slack | Reported status |
|---|---:|---|
| Main core synchronous setup | +1.23 ns | MET |
| Gated-clock setup | +4.70 ns | MET |
| Recovery | -0.26 ns | VIOLATED |

These are global-route estimates, not final extracted timing or sign-off
timing. The placement flow also reported a zero default wire-capacitance
warning.

**Congestion:** Not measured or reported in the available results.
Global-route guide coverage is not a congestion measurement, so no
congestion or overflow conclusion is claimed.

## 5. Interpretation

The selected IBEX0165 configuration completed placement and detailed
routing in the available OpenROAD flow. The final detailed router reported
zero DRC violations. The available data supports reporting placement area,
routed wirelength, via count, and a nominal-width signal-metal estimate.

It does not establish foundry sign-off, congestion-free routing, final
extracted timing closure, or global optimality across the Ibex architecture
space.

## 6. Functional RTL Tests

Five targeted assembly/firmware simulations were executed on the selected
IBEX0165 Verilator build. Each log records the expected signature and a
software-requested Verilog `$finish`.

| Test | Observed signature | Executed cycles | Simulation termination |
|---|---:|---:|---|
| Custom IBEX0165 signature | `0x13579bdf` | 26 | `$finish` |
| RV32I | `0x0000002a` | 220 | `$finish` |
| RV32M | `0x0000002a` | 332 | `$finish` |
| Extended RV32I | `0x0000002a` | 239 | `$finish` |
| Firmware smoke | `0x0000002a` | 21 | `$finish` |

The custom test uses its own signature location; the other four runs
report the `0x0000002a` signature. The cycle counts and signatures above
are transcribed from the corresponding preserved simulation logs.

**Scope limitation:** These are targeted functional simulations, not a
claim that the complete official RISC-V compliance suite was run. They
do not establish formal equivalence between the selected RTL and a
reference implementation.

## 7. Evidence and Reproducibility

Primary evidence is retained in the repository's build and routing
artifacts, including the successful detailed-route log, final detailed
route DEF, placement log, global-route timing log, and functional
simulation log.

The reported results describe the selected IBEX0165 implementation and
the specific tool, platform, PDK, and constraints used in this experiment.
