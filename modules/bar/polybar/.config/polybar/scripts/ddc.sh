#!/bin/sh

case $1 in 
  toggle) 
    printf "off"
    ;;
  increase)
    ddcutil setvcp 10 + 25;
    echo "";
    ;;
  decrease)
    ddcutil setvcp 10 - 25;
    echo ""
    ;;
  brightness)
    # printf "%dK" $(ddcutil getvcp 10 | grep -oP 'value.*\K\d+');
    echo ""
    ;;
esac