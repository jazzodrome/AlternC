#!/bin/bash

# This script look in the database wich mail should be DELETEd

# Source some configuration file
for CONFIG_FILE in \
      /etc/alternc/local.sh \
      /usr/lib/alternc/functions.sh
  do
    if [ ! -r "$CONFIG_FILE" ]; then
        echo "Can't access $CONFIG_FILE."
        exit 1
    fi
    . "$CONFIG_FILE"
done

#FIXME: do the lock

#FIXME: this var should be define by local.sh
ALTERNC_MAIL_LOC="/var/alternc/mail"

# List the local addresses to DELETE
# Foreach => Mark for deleting and start deleting the files
# If process is interrupted, the row isn't deleted. We have to force it by reseting mail_action to 'DELETE'
mysql_query "SELECT id, quote(replace(path,'!','\\!')) FROM mailbox WHERE mail_action='DELETE';"|while read id path ; do
  mysql_query "UPDATE mailbox set mail_action='DELETING' WHERE id=$id;"
  # Check there is no instruction of changing directory, and check the first part of the string
  if [[ "$path" =~ '../' || "$path" =~ '/..' || ! "'$ALTERNC_MAIL_LOC" == "${path:0:$((${#ALTERNC_MAIL_LOC}+1))}" ]] ; then
    echo "Error : this directory will not be deleted, pattern incorrect"
    continue
  fi
  test -d $path && nice 10 rm -rf $path 
  mysql_query "DELETE FROM mailbox WHERE id=$id;"
done

# List the adresses to DELETE
# Delete if only if there isn't any mailbox refering to it
mysql_query "DELETE FROM a using address a, mailbox m  WHERE a.mail_action='DELETE' OR a.mail_action='DELETING' AND a.id != m.address_id;"

