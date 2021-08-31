#!/bin/bash

apt-get update
apt-get install x11vnc -y
passwordfile='/etc/x11vnc.pass'
servicefile='/etc/systemd/system/x11vnc.service'
timerfile='/etc/systemd/system/x11vnc.timer'
script='/etc/x11vncstart.sh'
x11vnckillfile='/etc/x11vnc_kill_gdm.sh'
Postloginscriptfile='/etc/gdm3/PostLogin/x11vnckill'

x11vnc -storepasswd $passwordfile

cat >$servicefile <<'EOT'
[Unit]
Description=Start x11vnc at startup.
After=multi-user.target display-manager.service

[Service]
Type=simple
ExecStart=/etc/x11vncstart.sh
Restart=always
RestartSec=3

[Install]
WantedBy=graphical.target
WantedBy=multi-user.target
EOT

cat >$script <<'EOT'
#!/bin/bash

# list login sessions
sessions=$(loginctl --no-legend | awk '{print $1}')
for session_id in $sessions
do
    session_attributes=$(loginctl show-session $session_id)
    IFS=$'\n'
    for a in $session_attributes
    do
        declare $a
    done
    # look for the login session which is x11 and active
    if [ $Type = 'x11' ] && [ $Active = 'yes' ]
    then
        break
    fi
done

# Now we should have the variables for the active login session
pid=$( ps -C gnome-session-binary -o lsession,pid,user,args | awk -v session_id=$session_id -F' ' '$1 == session_id' | awk '{print $2}' )
echo pid $pid
display_id=$(cat /proc/${pid}/environ | tr '\0' '\n' | grep DISPLAY | cut -d= -f2)
echo disp $display_id

ps -C x11vnc u > /dev/null
status=$?
echo sta $status
if [ $status = 0 ]
then
    x11vnc_port=$(ss -tulpn4 | grep x11vnc | tr -s ' ' | cut -d' ' -f5 | cut -d\: -f2)
else
    X11VNC_AVOID_WINDOWS=never
    x11vnc_port=$(/usr/bin/x11vnc -o /var/log/x11vnc.log -noxdamage -display $display_id -auth /run/user/$User/gdm/Xauthority -rfbauth /etc/x11vnc.pass -repeat -shared -rfbport 5900)
fi
EOT
chmod +x $script

cat >$x11vnckillfile <<'EOT'
x11vnc_pid=$(ps -C x11vnc -F | grep 'display \:0.*gdm' | tr -s ' ' | cut -d' ' -f2)
echo killing ${x11vnc_pid}
kill ${x11vnc_pid}
EOT
chmod +x $x11vnckillfile

cat >$Postloginscriptfile <<'EOT'
#!/bin/sh
/etc/x11vnc_kill_gdm.sh
EOT
chmod +x $Postloginscriptfile


sed -i -e 's/WaylandEnable=true/WaylandEnable=false/g' /etc/gdm3/custom.conf
sed -i -e 's/#WaylandEnable=false/WaylandEnable=false/g' /etc/gdm3/custom.conf



systemctl daemon-reload
systemctl enable x11vnc.service
systemctl restart x11vnc.service
