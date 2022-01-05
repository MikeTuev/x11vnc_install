# x11vnc_install
x11vnc installation script for Debian11 with support of autostart in multi-user environment

1. Put installation script file x11vnc_install.sh to the user home directory /home/<username>. Installation script tested only on Debian 11 OS with Gnome desktop environment. It has some untrivial tricks to get it working within logging in screen and automatically restarts when user logging in. When logging in or when logging out back to the greeter, x11vnc is killed and restarted with the new display. Which means that the vnc client disconnects and has to be reconnected.
3. su
4. chmod +x x11vnc_install.sh
5. ./x11vnc_install.sh

Now x11vnc should be started automatically

  
