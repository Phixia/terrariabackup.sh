#!/bin/bash
#Anders Nelson
#2014-7-15
#The Purpose of this script is to take scheduled backups of a terraria server implementing backup rotation to keep daily,weekly,monthly,and yearly backups.
#I borrowed heavily from Andrew Howards backup.sh script

#First let's determine how many of each type of backup we want to keep
DAILY=14
WEEKLY=12
MONTHLY=24
YEARLY=10

#define our backup directory here lets grab the server logs too!
BACKUPLOGDIR=
BACKUPWORLDDIR=
LOGDIR=
WORLDDIR=
WORLD=
DATE=$(date +"%F")
SERVERLOG=

#Concurrency Check to make sure we only have one instance of the script running at a time (shamelessly plagurized that from Andrew Howard)
LOCK_FILE=/tmp/`basename $0`.lock
function cleanup {
 echo "Caught exit signal - deleting trap file"
 rm -f $LOCK_FILE
 exit 2
}
trap 'cleanup' 1 2 9 15 17 19 23 EXIT
(set -C; : > $LOCK_FILE) 2> /dev/null
if [ $? != "0" ]; then
 echo "Lock File exists - exiting"
 exit 1
fi

# Create directory structure if it does not exist

mkdir -p $BACKUPLOGDIR/daily \
	 $BACKUPLOGDIR/weekly \
	 $BACKUPLOGDIR/monthly \
	 $BACKUPLOGDIR/yearly \
	 $BACKUPWORLDDIR/daily \
         $BACKUPWORLDDIR/weekly \
	 $BACKUPWORLDDIR/monthly \
         $BACKUPWORLDDIR/yearly 


#First we need to stop our server
/etc/init.d/terraria-server stop

#First we take care of the world file
cat $WORLDDIR/$WORLD | gzip > $BACKUPWORLDDIR/daily/$WORLD.$DATE.gz 
/usr/sbin/tmpreaper -m ${DAILY}d $BACKUPWORLDDIR/daily

#Check if this is a Sunday run
if  [ $( date +%w ) -eq 0 ]; then
  cp $BACKUPWORLDDIR/daily/$WORLD.$DATE.gz $BACKUPWORLDDIR/weekly/$WORLD.$DATE.gz
  /usr/sbin/tmpreaper -m $(($WEEKLY * 7 ))d $BACKUPWORLDDIR/weekly
fi

#Check if 1st of the Month
if [ $( date +%d ) -eq 01  ]; then
  cp $BACKUPWORLDDIR/daily/$WORLD.$DATE.gz $BACKUPWORLDDIR/monthly/$WORLD.$DATE.gz
  /usr/sbin/tmpreaper -m $(( $MONTHLY * 31 ))d $BACKUPWORLDDIR/monthly

#Check if Jan
    if [ $( date +%m ) -eq 01  ]; then
      cp $BACKUPWORLDDIR/daily/$WORLD.$DATE.gz $BACKUPWORLDDIR/yearly/$WORLD.$DATE.gz
      /usr/sbin/tmpreaper -m $(( $YEARLY * 365 ))d $BACKUPWORLDDIR/yearly
    fi
fi
#repeat for the server logs @@@@@ CHECK THIS? @@@@@@@
for x in `ls $LOGDIR | grep $DATE` ;do cat $x | gzip > $BACKUPLOGDIR/daily/$x.log.gz; done 
/usr/sbin/tmpreaper -m ${DAILY}d $BACKUPLOGDIR/daily

#Check if a Sunday run
if  [ $( date +%w ) -eq 0 ]; then
  cp $BACKUPLOGDIR/daily/$DATE.log.gz $BACKUPLOGDIR/weekly/$DATE.log.gz
  /usr/sbin/tmpreaper -m $(($WEEKLY * 7 ))d $BACKUPLOGDIR/weekly
fi
#Check if 1st of the Month
if [ $( date +%d ) -eq 01  ]; then
  cp $BACKUPLOGDIR/daily/$DATE.log.gz $BACKUPLOGDIR/monthly/$DATE.log.gz
  /usr/sbin/tmpreaper -m $(( $MONTHLY * 31 ))d $BACKUPLOGDIR/monthly
#If it is the first of the month and Jan do a yearly backup
  if [ $( date +%m ) -eq 01  ]; then
    cp $BACKUPLOGDIR/daily/$DATE.log.gz $BACKUPLOGDIR/yearly/$DATE.log.gz
    /usr/sbin/tmpreaper -m $(( $YEARLY * 365 ))d $BACKUPLOGDIR/yearly
  fi
fi

# Also need to get a copy of the ServerLog.txt
cat $SERVERLOG | gzip > $BACKUPLOGDIR/daily/$DATE.ServerLog.gz && cat /dev/null> $SERVERLOG
/usr/sbin/tmpreaper -m ${DAILY}d $BACKUPLOGDIR/daily

if  [ $( date +%w ) -eq 0 ]; then
  cp $BACKUPLOGDIR/daily/$DATE.ServerLog.gz $BACKUPLOGDIR/weekly/$DATE.ServerLog.gz
  /usr/sbin/tmpreaper -m $(($WEEKLY * 7 ))d $BACKUPLOGDIR/weekly
fi
#Check if 1st of the Month
if [ $( date +%d ) -eq 01  ]; then
  cp $BACKUPLOGDIR/daily/$DATE.ServerLog.gz $BACKUPLOGDIR/monthly/$DATE.ServerLog.gz
  /usr/sbin/tmpreaper -m $(( $MONTHLY * 31 ))d $BACKUPLOGDIR/monthly
#If it is the first of the month and Jan do a yearly backup
  if [ $( date +%m ) -eq 01  ]; then
    cp $BACKUPLOGDIR/daily/$DATE.ServerLog.gz $BACKUPLOGDIR/yearly/$DATE.ServerLog.gz
    /usr/sbin/tmpreaper -m $(( $YEARLY * 365 ))d $BACKUPLOGDIR/yearly
  fi
fi


#Restart server
/etc/init.d/terraria-server start

exit
