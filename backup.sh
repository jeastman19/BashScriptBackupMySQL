#!/bin/bash

##################################
# include Env Variables
##################################
source backup.env


# Linux bin paths
MYSQL="$(which mysql)"
MYSQLDUMP="$(which mysqldump)"
GZIP="$(which gzip)"


# Get date in yyyy-mm-dd format
NOW="$(date +"%Y-%m-%d_%s")"


# Create Backup sub-directories
MBD="$DEST/$NOW/mysql"
install -d $MBD

# List of database to be ignored
SKIP="information_schema
another_one_db"

# Get all databases
DBS="$($MYSQL -h $MyHOST -u $MyUSER -p$MyPASS -Bse 'show databases')"

# Generate the dump of the databases
for db in $DBS
do
    skipdb=-1
    if [ "$SKIP" != "" ]; then
      for i in $SKIP; do
        [ "$db" == "$i" ] && skipdb=1 || :
      done
    fi
 
    if [ "$skipdb" == "-1" ] ; then
      FILE="$MBD/$db.sql"
      $MYSQLDUMP -h $MyHOST -u $MyUSER -p$MyPASS $db > $FILE
    fi
done

# Compress the backrest
cd $DEST
tar -cf $NOW.tar $NOW
$GZIP -9 $NOW.tar

# Send notification by email (EMAIL = true)
if [ ! -z "$MAIL" ]; then
  curl -s --user "api:$MAILGUN_APIKEY" \
      https://api.mailgun.net/v3/$MAILGUN_DOMAIN/messages \
      -F from=$EMAIL_FROM \
      -F to=$EMAIL_TO \
      -F subject=$EMAIL_SUBJECT \
      -F text="MySQL backup is completed! Backup name is $NOW.tar.gz"
fi

# Remove the dump file
rm -rf $NOW

# Remove backups prior to the expiration period (DAY = 3)
find $DEST -mtime +$DAYS -exec rm -f {} \;
