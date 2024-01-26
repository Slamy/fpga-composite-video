set -e

# Ignore *.v files as this is only uart_tx.v and uart_rx.v
# which is not written by me
verible-verilog-lint --rules_config_search ../rtl/*.sv ../rtl/*.svh

echo "Finished!"
