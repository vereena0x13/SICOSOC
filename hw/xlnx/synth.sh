#!/bin/bash

if [ ! -d vprj ]; then
    mkdir vprj
fi

vivado -mode batch -log top.log -source top.tcl