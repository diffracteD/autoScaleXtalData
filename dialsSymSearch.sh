#!/bin/bash

#Uses Dials3.2
#AbhisekMondal_Jul17-2025
#UCSF
#tries to find spots and indexes. Keep doing it by chaning picking parameters till it can find a solution.
#particularly helpful for running and automated search for multiple lattice issue.
#
#

# Input image path (update if needed)
image_path="/net/LabShare/Synchrotron_Data2/20220516_ALS8.3.1/MNR04_11/MNR04_11_1_*.cbf"

# Thresholds and gains to iterate over
thresholds=(2 3 5 10 15)
gains=(1.0 2.0)

# Output base directory
base_output_dir="dials_3.2_trials"

# Loop over gain and threshold combinations
for gain in "${gains[@]}"; do
  for thresh in "${thresholds[@]}"; do
    label="gain${gain}_thresh${thresh}"
    output_dir="${base_output_dir}/thresh${thresh}_gain${gain}"

    echo "=============================="
    echo "Processing $label"
    echo "Working directory: $output_dir"
    echo "=============================="

    mkdir -p "$output_dir"
    cd "$output_dir" || exit 1

    echo "Running dials.import..."
    dials.import "$image_path" | tee import.log
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
      echo "Import failed for $label"
      cd - > /dev/null || exit 1
      continue
    fi

    echo "Running dials.find_spots with threshold=$thresh, gain=$gain..."
    dials.find_spots imported.expt gain=$gain threshold=$thresh | tee find_spots.log
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
      echo "Spot finding failed for $label"
      cd - > /dev/null || exit 1
      continue
    fi

    echo "Skipping spot_counts_per_image due to known bug in DIALS 3.2.1"

    echo "Running dials.index for potential multi-lattice case..."
    dials.index imported.expt strong.refl \
      detector.fix=distance beam.fix=wavelength \
      max_lattices=5 | tee index.log

    if [ ${PIPESTATUS[0]} -eq 0 ]; then
      echo "Indexing succeeded for $label"
    else
      echo "Indexing failed for $label"
    fi

    cd - > /dev/null || exit 1
  done
done
