#!/bin/bash
echo "Restarting camera..."
sudo killall obs 2>/dev/null
sudo modprobe -r uvcvideo
sleep 2
sudo modprobe uvcvideo
echo "Camera restarted. Restarting OBS..."
obs &
