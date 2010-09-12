#!/bin/bash

HOSTS="nang.kicks-ass.net"

COUNT=4
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@" >> /var/log/rsyncFreeNAS
echo "Starting rsync attempt at `date`" >> /var/log/rsyncFreeNAS
for myHost in $HOSTS
do
  count=$(ping -c $COUNT $myHost | grep 'received' | awk -F',' '{ print $2 }' | awk '{ print $1 }')
  if [ $count -eq 0 ]; then
    # 100% failed 
    echo "Host : $myHost is down (ping failed) at $(date)" >> /var/log/rsyncFreeNAS
  else
    echo "Host : $myHost is up at $(date)" >> /var/log/rsyncFreeNAS
    #rsync -aP /home/josh/programming/* josh@$HOSTS:home >> /var/log/rsyncFreeNAS 
    rsync -aHvz -e ssh /home/josh/programming/* root@192.168.1.250:/mnt/storage/Config/home >> /var/log/rsyncFreeNAS 
  fi
done
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@" >> /var/log/rsyncFreeNAS
