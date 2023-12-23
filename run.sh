#/bin/sh
make -C samples/program --no-print-directory
cp samples/program/build/prog.hex samples/program.hex

./build/wivcpu