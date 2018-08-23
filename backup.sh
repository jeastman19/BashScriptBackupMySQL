#!/bin/bash
# Shell script to backup MySQL database


##################################
# include Env Variables
##################################
source backup.env



# Linux bin paths
MYSQL="$(which mysql)"
MYSQLDUMP="$(which mysqldump)"
GZIP="$(which gzip)"


# Get date in dd-mm-yyyy format
NOW="$(date +"%d-%m-%Y_%s")"


# Create Backup sub-directories
MBD="$DEST/$NOW/mysql"
install -d $MBD

# DB skip list
SKIP="information_schema
another_one_db"

# Get all databases
DBS="$($MYSQL -h $MyHOST -u $MyUSER -p$MyPASS -Bse 'show databases')"

# Archive database dumps
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

# Archive the directory, send mail and cleanup
cd $DEST
tar -cf $NOW.tar $NOW
$GZIP -9 $NOW.tar

if [ ! -z "$MAIL" ]; then
  curl -s --user "api:$MAILGUN_APIKEY" \
      https://api.mailgun.net/v3/$MAILGUN_DOMAIN/messages \
      -F from=$EMAIL_FROM \
      -F to=$EMAIL_TO \
      -F subject=$EMAIL_SUBJECT \
      -F text="MySQL backup is completed! Backup name is $NOW.tar.gz"
fi

rm -rf $NOW

# Remove old files
find $DEST -mtime +$DAYS -exec rm -f {} \;
