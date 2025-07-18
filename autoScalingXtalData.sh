#!/bin/bash

# -------- CONFIGURE -------- #
EXAMPLE_IMAGE="/net/LabShare/Synchrotron_Data2/20220516_ALS8.3.1/MNR04_11/MNR04_11_1_00001.cbf"
OUTPUT_ROOT="./xia2_trials"
SCALING_TRIALS=(
  "gain=1.0 min_isigi=1.0 overload=2"
  "gain=1.0 min_isigi=0.5 overload=3"
)
# --------------------------- #

mkdir -p "$OUTPUT_ROOT"

# 1. Run xia2
RUN_NAME="xia2_default_run"
RUN_DIR="${OUTPUT_ROOT}/${RUN_NAME}"
XIA2_DIR="${RUN_DIR}/xia2-dials"
mkdir -p "$RUN_DIR"

echo "========================================"
echo "🔁 Running xia2 on: $EXAMPLE_IMAGE"
echo "Output: $RUN_DIR"
echo "========================================"

(
  cd "$RUN_DIR" || exit 1
  xia2 image="$EXAMPLE_IMAGE" pipeline=dials 2>&1 | tee xia2.log
)

if [[ ! -d "$XIA2_DIR" ]]; then
  echo "❌ xia2 failed. Check logs in $RUN_DIR/xia2.log"
  exit 1
fi

echo "✅ xia2 completed. Proceeding to scaling trials..."
cd "$XIA2_DIR" || exit 1

EXPT="indexed.expt"
REFL="indexed.refl"

if [[ ! -f $EXPT || ! -f $REFL ]]; then
  echo "❌ Could not find $EXPT or $REFL in $XIA2_DIR"
  exit 1
fi

# 2. Loop through trials
for trial in "${SCALING_TRIALS[@]}"; do
  GAIN=$(echo "$trial" | awk '{print $1}' | cut -d= -f2)
  ISIGI=$(echo "$trial" | awk '{print $2}' | cut -d= -f2)
  OVERLOAD=$(echo "$trial" | awk '{print $3}' | cut -d= -f2)
  TRIAL_NAME="gain${GAIN}_isig${ISIGI}_ol${OVERLOAD}"

  echo -e "\n========================================"
  echo "🔁 Running scaling: $TRIAL_NAME"
  echo "========================================"

  TRIAL_DIR="${XIA2_DIR}/scale_${TRIAL_NAME}"
  mkdir -p "$TRIAL_DIR"
  cp "$EXPT" "$REFL" "$TRIAL_DIR/"
  cd "$TRIAL_DIR" || continue

  dials.scale \
    "$EXPT" "$REFL" \
    min_isigi="$ISIGI" \
    filtering.method=overload \
    filtering.overload.cutoff="$OVERLOAD" \
    output.experiments=scaled.expt \
    output.reflections=scaled.refl 2>&1 | tee scale.log

  if grep -q "Error" scale.log || grep -q "Traceback" scale.log; then
    echo "❌ Trial $TRIAL_NAME failed."
  else
    echo "✅ Trial $TRIAL_NAME completed."
  fi

  cd "$XIA2_DIR" || break
done

echo -e "\n✅ All scaling trials finished. Check output in $XIA2_DIR"
