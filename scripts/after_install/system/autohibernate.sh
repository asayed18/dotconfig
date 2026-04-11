#!/bin/bash
# Script name: /lib/elogind/system-sleep/autohibernate.sh
# Purpose: Auto hibernates after a period of sleep
# Edit the "autohibernate" variable below to set the number of seconds to sleep.

curtime=$(date +%s)

# 60 Minutes should be fine
autohibernate=3600

echo "$curtime $1" >>/tmp/autohibernate.log


if [ "$1" = "pre" ]
then
        if [ "$2" = "suspend" ]
        then
                # Suspending.  Record current time, and set a wake up timer.
                echo "$curtime" >/var/run/rtchibernate.lock
                rtcwake -m no -s $autohibernate
        fi
	xflock4
fi

if [ "$1" = "post" ]
then

        if [ "$2" = "suspend" ]
        then
                # Coming out of sleep
                sustime=$(cat /var/run/rtchibernate.lock)
                rm /var/run/rtchibernate.lock

                # Did we wake up due to the rtc timer above?
                if [ $(($curtime - $sustime)) -ge $autohibernate ]
                then
                        # Then hibernate
                        /bin/loginctl hibernate
                else
                        # Otherwise cancel the rtc timer and wake up normally.
                        rtcwake -m no -s 1
                fi
        fi
	echo "betterlock" >> /tmp/autohibernate.log
fi
