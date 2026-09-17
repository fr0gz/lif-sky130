#!/bin/bash

mkdir -p sweep_iin

for I in 100p 200p 500p 1n 2n 5n 10n 20n 50n
do
    echo "Running IIN=$I"

    sed "s/\.param IIN   = .*/.param IIN   = $I/" \
        spice/lif_tb.spice \
        > "sweep_iin/lif_${I}.spice"

    ngspice -b "sweep_iin/lif_${I}.spice" \
        > "sweep_iin/lif_${I}.log"

    mv lif_tb.raw "sweep_iin/lif_${I}.raw"
done

echo "Sweep complete."
