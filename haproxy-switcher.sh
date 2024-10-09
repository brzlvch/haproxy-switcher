#!/bin/bash

##
## HAProxy backend server switcher
##
## bash haproxy-switcher.sh "web443/server1" -enable
## bash haproxy-switcher.sh "web443/server1" -disable
## bash haproxy-switcher.sh "web443/server1" -socket "/var/run/haproxy_foo.sock" -disable
##

HAPROXY_SOCK="/var/run/haproxy.sock"

echo -e "Starting HAProxy switcher..\n"

if ! [ -x "$(command -v socat)" ]; then

    echo "Error: \"socat\" is not installed. Use \"apt install socat\""
    echo -e "\nHAProxy switcher stoped! Bye bye!"
    exit 0;
fi

for ((i=1; i<=$#; i++)); do

    if [ ${!i} = "-d" ] || [ ${!i} = "-disable" ]; then ((i+2))

        ACTION="disable";

    elif [ ${!i} = "-e" ] || [ ${!i} = "-enable" ]; then ((i+2))

        ACTION="enable";

    elif [ ${!i} = "-s" ] || [ ${!i} = "-socket" ]; then ((i+2))

        HAPROXY_SOCK=${!i};
    else

        NODE=${!i};
    fi
done;

if [ ! -S ${HAPROXY_SOCK} ]; then

    echo "HAProxy socket file not found. Please, check your params"
	echo -e "\nHAProxy switcher stoped! Bye bye!"
	exit 0
fi

BACKEND=${NODE%/*}
SERVER=${NODE#*/}

# Проверка пустой ноды
if [[ -z $BACKEND ]] || [[ -z $SERVER ]]; then

	HAPROXY_BACKEND_LIST=$(echo "show stat" | sudo socat stdio ${HAPROXY_SOCK} | cut -d "," -f 1,2 | column -s, -t | grep "BACKEND" | awk "{print $ 1}" | uniq)

	HAPROXY_BACKENDS=($HAPROXY_BACKEND_LIST)

	echo "Available HAProxy backends:"

	i=1;

	for key in "${HAPROXY_BACKENDS[@]}"; do

		echo "$i) $key"
		i=$((i + 1));
	done

	read -p "Choose HAProxy backend (1-${#HAPROXY_BACKENDS[@]}): " BACKEND_ID

	i=1;

	for key in "${HAPROXY_BACKENDS[@]}"; do

		if [[ "$i" == "$BACKEND_ID" ]]; then

			BACKEND=${key}
			break
		fi

		i=$((i + 1));
	done

	HAPROXY_SERVER_LIST=$(echo "show stat" | sudo socat stdio ${HAPROXY_SOCK} | cut -d "," -f 1,2 | column -s, -t | grep ${BACKEND} | grep -v "BACKEND" | awk "{print $ 2}")

	HAPROXY_SERVERS=($HAPROXY_SERVER_LIST)

	echo -e "\r"
	echo "Available HAProxy server of \"${BACKEND}\":"

	i=1;

	for key in "${HAPROXY_SERVERS[@]}"; do

		echo "$i) $key"
		i=$((i + 1));
	done

	read -p "Choose HAProxy server of \"${BACKEND}\" (1-${#HAPROXY_SERVERS[@]}): " SERVER_ID

	i=1;

	for key in "${HAPROXY_SERVERS[@]}"; do

		if [[ "$i" == "$SERVER_ID" ]]; then

			SERVER=${key}
			break
		fi

		i=$((i + 1));
	done

	echo -e "\r"
fi

# Проверка пустой ноды
if [[ -z $BACKEND ]] || [[ -z $SERVER ]]; then
	
	echo "HAProxy node not found or empty. Please, check your params"
	echo -e "\nHAProxy switcher stoped! Bye bye!"
	exit 0
fi

if [[ $(echo "show stat typed" | sudo socat stdio ${HAPROXY_SOCK} | grep ${BACKEND} -A 1 | tr -d "\r\n" | grep ${SERVER} | wc -l) == 0 ]]; then

   	echo "Node \"${BACKEND}/${SERVER}\" not found. Please, check your params"
	echo -e "\nHAProxy switcher stoped! Bye bye!"
	exit 0
fi

if [[ -z $ACTION ]]; then

	echo "Available HAProxy actions:"

	echo "1) Enable"
	echo "2) Disable"

	read -p "Choose HAProxy node action: " ACTION_ID

	if [[ "$ACTION_ID" == 1 ]]; then

		ACTION="enable"

	elif [[ "$ACTION_ID" == 2 ]]; then

		ACTION="disable"
	fi

	echo -e "\r"
fi

if [[ -z $ACTION ]]; then

   	echo "Supported disable/enable actions only!"
	echo -e "\nHAProxy switcher stoped! Bye bye!"
	exit 0
fi

echo -e "Processing \"${ACTION}\" of \"${BACKEND}/${SERVER}\" server.."

COMMAND="echo \"${ACTION} server ${BACKEND}/${SERVER}\" | sudo socat stdio ${HAPROXY_SOCK}"

if eval "$COMMAND"; then

    echo "Processing done!"

else
    echo "Processing fail!"
fi

echo -e "\nHAProxy switcher completed! Bye bye!"
