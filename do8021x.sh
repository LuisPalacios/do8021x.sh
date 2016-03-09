#!/bin/bash
#
# By Luis Palacios, 2016.
#
# Run wpa_supplicant without storing user/password for a
# wired 802.1x connection. Notice that the user/password will
# only exist in memory. This is a CLI solution, no GUI.
#

# Variables
export WPA_PROGRAM=/usr/sbin/wpa_supplicant
export INTERFACE=eth1
export FIFO=/tmp/wpaconf

# Usage
#
usage() {
    echo "do8021x.sh. Copyright (c) 2016 LuisPa"
    echo "Usage: do8021x.sh [-k]"
    echo "     -k     Kill/Stop running supplicant."
    echo " "
    exit -1  # Salimos
}

# Kill the running supplicants
#
kill_supplicants() {
    PIDS=$(pidof ${WPA_PROGRAM})
    numPIDS=`echo ${PIDS} | wc -w`
    if [ ${numPIDS} == "0" ]; then
	echo "There are no running Supplicants"
    else
	echo "Stopping supplicant(s)."
	kill ${PIDS}
    fi    
}

# Arguments
#
while getopts "k" Option
do
    case $Option in

	k)
	    kill_supplicants
	    exit
	    ;;

	*)
            usage
            ;;
    esac
done

# Trap EXIT
trap letsExit EXIT
function letsExit() {
    # If still around, make sure FIFO is deleted
    rm -f ${FIFO}
    exit
}

# Control 
case "$(pidof ${WPA_PROGRAM} | wc -w)" in

    0)  echo "Restarting..."

	# Ask for user/password
	echo Starting 802.1x.
	echo -n "User: "
	read USER
	echo -n "Password: "
	read -s PASS

	# Create FIFO file 
	mkfifo ${FIFO}

	# Write into FIFO file (in the background). This cat will finish
	# as soon as wpa_supplicant reads the file, so it will vanish
	# almost inmediately
	cat > ${FIFO} <<-EOF_CONF &

        ctrl_interface=/var/run/wpa_supplicant
        ctrl_interface_group=0
        eapol_version=2
        ap_scan=0
        fast_reauth=1
        network={
            key_mgmt=IEEE8021X
            eap=FAST TTLS PEAP
            identity="${USER}"
            password="${PASS}"
            phase1="peapver=1"
            phase2="auth=MSCHAPV2"
            eapol_flags=0
        }
EOF_CONF
	
	# Run the wpa_supplicant program which will read from
	# the FIFO (which is already waiting for a reader, see previous 'cat')
	${WPA_PROGRAM} -B -t -D wired -i ${INTERFACE} -c ${FIFO} > /dev/null 2>&1
	
	# Delete FIFO file.
	sleep 1
	rm ${FIFO}
	echo
	echo Supplicant started
	;;
    
    1)  # all ok
	echo "Supplicant is currently running"
	;;

    *)  # Should never happend but looks like multiple supplicants
	echo "Looks like we have multiple supplicants, kill them all..."
	kill_supplicants
	;;

esac