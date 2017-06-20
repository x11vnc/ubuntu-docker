#!/bin/bash

# Start up VNC server and launch xlsession and novnc

# Author: Xiangmin Jiao <xmjiao@gmail.com>

# Copyright Xiangmin Jiao 2017. All rights reserved.

# Start up xdummy with the given size
RESOLUT="${RESOLUT:-1440x900}"
SIZE=`echo $RESOLUT | sed -e "s/x/ /"`
grep -s -q $RESOLUT $DOCKER_HOME/.config/xorg.conf && \
perl -i -p -e "s/Virtual \d+ \d+/Virtual $SIZE/" $DOCKER_HOME/.config/xorg.conf

Xorg -noreset -logfile $DOCKER_HOME/.log/Xorg.log -config $DOCKER_HOME/.config/xorg.conf :0 2> $DOCKER_HOME/.log/Xorg_err.log &
sleep 0.1

# startup lxsession with proper environment variables
export DISPLAY=:0.0
export HOME=$DOCKER_HOME
export SHELL=$DOCKER_SHELL
export USER=$DOCKER_USER
export LOGFILE=$DOCKER_USER

eval `ssh-agent` > /dev/null

/usr/bin/lxsession -s LXDE -e LXDE > $DOCKER_HOME/.log/lxsession.log 2>&1 &

(COUNTER=0; while [ $COUNTER -lt 100 ]; do WIN="$(xdotool search --name Error)"; if [ -n "$WIN" ]; then xdotool key --window $WIN space; echo "Resolved error $WIN after $COUNTER iterations"; break; fi; sleep 0.1; let COUNTER=COUNTER+1; done) &

# startup x11vnc with a new password
export VNCPASS=`openssl rand -base64 6 | sed 's/\//-/'`

x11vnc -storepasswd $VNCPASS ~/.vnc/passwd > $DOCKER_HOME/.log/x11vnc.log 2>&1
x11vnc -display :0 -xkb -forever -shared  -usepw >> $DOCKER_HOME/.log/x11vnc.log 2>&1 &

echo "Open your web browser with URL:"
echo "    http://localhost:6080/vnc.html?resize=downscale&autoconnect=1&password=$VNCPASS"

# startup novnc
/usr/local/noVNC/utils/launch.sh --listen 6080 > $DOCKER_HOME/.log/novnc.log 2>&1
