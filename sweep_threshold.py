#!/usr/bin/env python3

import subprocess
import re
import csv
from pathlib import Path

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

BASE = Path("spice/lif_threshold_tb.spice")
OUT_DIR = Path("sweep_threshold")
OUT_DIR.mkdir(exist_ok=True)

IIN_VALUES = [
    ("4n",  4.0),
    ("5n",  5.0),
    ("6n",  6.0),
    ("7n",  7.0),
    ("8n",  8.0),
    ("9n",  9.0),
    ("10n", 10.0),
]

results = []

# ------------------------------------------------------------
# Run sweep
# ------------------------------------------------------------

for spice_value, iin_na in IIN_VALUES:

    netlist = OUT_DIR / f"lif_threshold_{spice_value}.spice"
    logfile = OUT_DIR / f"lif_threshold_{spice_value}.log"

    # Replace IIN only
    text = BASE.read_text()

    text = re.sub(
        r"\.param IIN\s*=.*",
        f".param IIN   = {spice_value}",
        text
    )

    netlist.write_text(text)

    print(f"Running IIN = {iin_na:g} nA ...")

    with logfile.open("w") as f:
        subprocess.run(
            ["ngspice", "-b", str(netlist)],
            stdout=f,
            stderr=subprocess.STDOUT,
            check=False
        )

    log = logfile.read_text()

    # --------------------------------------------------------
    # Extract t_cross
    # --------------------------------------------------------

    match = re.search(
        r"t_cross\s*=\s*([0-9.eE+-]+)",
        log
    )

    if match:
        t_cross_s = float(match.group(1))
        t_cross_us = t_cross_s * 1e6

        print(
            f"  IIN = {iin_na:g} nA"
            f" -> t_cross = {t_cross_us:.3f} us"
        )

        results.append(
            (iin_na, t_cross_us)
        )

    else:
        print(
            f"  IIN = {iin_na:g} nA"
            f" -> NO CROSSING"
        )

        results.append(
            (iin_na, None)
        )

# ------------------------------------------------------------
# Save CSV
# ------------------------------------------------------------

csv_file = OUT_DIR / "iin_vs_tcross.csv"

with csv_file.open("w", newline="") as f:

    writer = csv.writer(f)

    writer.writerow([
        "IIN_nA",
        "t_cross_us"
    ])

    for iin, tcross in results:
        writer.writerow([
            iin,
            "" if tcross is None else tcross
        ])

print()
print("========================================")
print("IIN vs t_cross")
print("========================================")

for iin, tcross in results:

    if tcross is None:
        print(
            f"{iin:6.2f} nA    NO CROSSING"
        )
    else:
        print(
            f"{iin:6.2f} nA    "
            f"{tcross:10.3f} us"
        )

print()
print(f"CSV saved to: {csv_file}")
