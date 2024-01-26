set -e

verible-verilog-format --inplace --indentation_spaces 4 ../rtl/filter/* ../rtl/*

echo "Finished!"
