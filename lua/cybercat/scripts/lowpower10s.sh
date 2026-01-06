#!/bin/bash
if [ "$(pmset -g | grep lowpowermode | awk '{print $2}')" -eq 1 ]; then
  sudo pmset -a lowpowermode 0
  sleep 10
  sudo pmset -a lowpowermode 1
fi

# !/bin/sh
# sudo pmset -a lowpowermode 1
# sleep 10
# sudo pmset -a lowpowermode 0
