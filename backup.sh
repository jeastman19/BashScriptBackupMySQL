#!/bin/bash

# See the main block at the end of the script

# get script path
SCRIPT=$(readlink -f $0);
dir_base=`dirname $SCRIPT`;


##################################
# include Env Variables
##################################
source $dir_base/backup.env


declare -a SKIP
declare -a DBS
declare DEST
declare MBD
declare NOW




# Linux bin paths
MYSQL="$(which mysql)"
MYSQLDUMP="$(which mysqldump)"
GZIP="$(which gzip)"


# Get date in yyyy-mm-dd format
function setSkipDatabase {
  SKIP=(
    "information_schema"
    "mysql"
    "performance_schema"
    "phpmyadmin"
    "sys"
  )
}

function getDate {
  NOW="$(date +"%Y-%m-%d_%s")"
}

function createBackupDirectories {
  MBD="$DEST/$NOW/mysql"
  install -d $MBD
}

function getAllDatabases {
  DBS="$($MYSQL -h $MyHOST -u $MyUSER -p$MyPASS -Bse 'show databases')"
}

function dbInSkipArray {
  local n=${#SKIP[@]}
  local value=$1

  for ((i=0;i < $n;i++)) {
    if [ "${SKIP[$i]}" == "${value}" ]; then
      echo "y"
      return 0
    fi
  }
  echo "n"
  return 1
}

function generateDumpOfDatabes {
  for db in ${DBS[@]}
  do
    if [ $(dbInSkipArray $db ) == "n" ]; then
      FILE="$MBD/$db.sql"
      $MYSQLDUMP -h $MyHOST -u $MyUSER -p$MyPASS $db > $FILE
    fi
  done
}

function compressBackrest {
  cd $DEST
  tar -cf $NOW.tar $NOW
  $GZIP -9 $NOW.tar
}

function sendMailNotification {
  if [ ! -z "$MAIL" ]; then
    curl -s --user "api:$MAILGUN_APIKEY" \
        https://api.mailgun.net/v3/$MAILGUN_DOMAIN/messages \
        -F from=$EMAIL_FROM \
        -F to=$EMAIL_TO \
        -F subject=$EMAIL_SUBJECT \
        -F text="MySQL backup is completed! Backup name is $NOW.tar.gz"
  fi
}

function removeTheDumpFile {
  rm -rf $NOW
}

function removeBackupsPriorExpirationPeriod {
  find $DEST -mtime +$DAYS -exec rm -f {} \;
}


#########
# Main
#########
setSkipDatabase
getDate
createBackupDirectories
getAllDatabases
generateDumpOfDatabes
compressBackrest
sendMailNotification
removeTheDumpFile
removeBackupsPriorExpirationPeriod
