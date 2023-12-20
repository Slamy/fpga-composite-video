SCRIPT=$(realpath "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
cd $SCRIPTPATH

openFPGALoader -f -c ft2232 ./impl/pnr/fpga_pong.fs
