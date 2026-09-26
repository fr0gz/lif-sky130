# Automated Layout Evidence

This directory contains selected artifacts produced during automated
SKY130 layout generation using the KLayout database API.

## Layout artifacts

- `artifacts/gds/inverter/inv_routed_v4.gds`
  - Final inverter routing artifact selected from the layout-generation experiments.
- `artifacts/gds/lif/lif_physical_cell_v2.gds`
  - LIF physical-cell layout artifact.

## Verification evidence

- `artifacts/reports/sky130_drc.txt`
  - KLayout SKY130 DRC report for `INV_ROUTED_V4`.
  - The report contains 6 reported violations, all in M1 rules (`m1.1` and `m1.2`).

- `../../drc_lvs/lif_drc.lyrdb`
  - KLayout SKY130 DRC report for `LIF_PHYSICAL_CELL_V2`.
  - The report contains no DRC items.

- `../../drc_lvs/lvs.log`
  - LVS comparison for `LIF_PHYSICAL_CELL_V2`.
  - Hierarchical netlists match through the LIF hierarchy.
  - The final top-level comparison reports a `VSUBS` port-ordering/matching error.

These files are published as verification evidence only. The Python
KLayout API implementation used to generate and inspect the layouts is
not included in this evidence branch.
