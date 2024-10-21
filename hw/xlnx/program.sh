#!/bin/bash
openocd -f neso.cfg -c "init" -c "pld load 0 top.bit" -c "shutdown"