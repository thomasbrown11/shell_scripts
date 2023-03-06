#!/bin/zsh

#target AirPlay controller
airplay=/System/Library/CoreServices/AirPlayUIAgent.app/Contents/MacOS/AirPlayUIAgent

#manipulate priveleges

#revoke all airplay access
sudo chmod 000 $airplay


#AIRPLAY=/System/Library/CoreServices/AirPlayUIAgent.app/Contents/MacOS/AirPlayUIAgent
#
#disable() {
#    echo "Disabling airplay\n"
#    sudo chmod 000 $AIRPLAY
#}
#
#enable(){
#    echo "Enabling Airplay Agent\n"
#    sudo chmod 755 $AIRPLAY
#}
#
#status(){
#    stat=`stat -f %p $AIRPLAY`
#    if [[ stat -eq '100755' ]] ; then
#        echo "Airplay is enabled\n"
#    elif [[ stat -eq '100000' ]] ; then
#        echo "Airplay is disabled\n"
#    fi
#
#}
#
#case $1 in
#    enable)
#        enable
#        ;;
#    disable)
#        disable
#        ;;
#    status)
#        status
#        ;;
#    *)
#        echo "Commands to use enable|disalbe"
#        exit 1
#        ;;
#esac
#
#exit 0
