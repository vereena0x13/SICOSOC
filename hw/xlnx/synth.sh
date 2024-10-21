#!/bin/bash

if [ ! -d vprj ]; then
    mkdir vprj
fi

cd vprj
vivado -mode batch -log top.log -source ../top.tcl