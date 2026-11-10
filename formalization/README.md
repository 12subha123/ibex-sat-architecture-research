# Lean formalization dependencies

The four Ibex-specific modules in this directory import the wider
`OAI.Algorithms.SubexponentialSAT` library.

The development reference was:
https://github.com/openai/math

Pinned reference commit:
`4eaee87548250b2682affda7d05d947c05554bae`

The upstream source is not vendored in this research repository.

The project uses Lean `leanprover/lean4:v4.34.1` and the mathlib revision
pinned in `lake-manifest.json`.

For a reproducible build, check out the referenced upstream commit, make
its `lean/OAI` source tree available to this Lean project, and run
`lake build` from this directory.

The four Ibex modules are under
`OAI/Algorithms/SubexponentialSAT/Ibex/`.
