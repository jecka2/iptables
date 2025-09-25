#!/bin/bash
HOST=192.168.255.1
ARG=8881 7777 9991
shift
for ARG in "$@"
do
        sudo nmap -Pn --max-retries 0 -p $ARG $HOST
done