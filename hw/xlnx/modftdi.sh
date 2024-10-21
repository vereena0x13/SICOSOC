#!/bin/bash
sudo su -c "modprobe ftdi_sio && echo 2a19 1005 > /sys/bus/usb-serial/drivers/ftdi_sio/new_id"