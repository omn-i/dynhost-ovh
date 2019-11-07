#!/bin/sh

PATH_LOG=/var/log/dynhost
CURRENT_DATE=`date`

CRED_FILE=`readlink -f "$0"`
CRED_FILE=`dirname "$CRED_FILE"`"/dynhost.cred"

count=`xmllint --xpath 'count(//credentials/item)' "$CRED_FILE"`

if [ -z $count ]
then
   echo "$CRED_FILE"" is invalid or doesn't exist !" >> $PATH_LOG
   echo "" >> $PATH_LOG
   exit 0
fi

CURRENT_IP=`curl -4 ifconfig.co`
if [ -z $CURRENT_IP ]
then
   echo "$CURRENT_DATE"":" >> $PATH_LOG
   echo "   CURRENT IP not retrieved" >> $PATH_LOG
   echo "" >> $PATH_LOG
   exit 0
fi

one_new=0
for i in `seq 1 $count`;
do
   HOST=`xmllint --xpath "//credentials/item[position() = $i]/host/text()" "$CRED_FILE"`
   HOST_IP=`dig +short $HOST`
   if [ -z $HOST_IP ]
   then
      echo "$CURRENT_DATE"":" >> $PATH_LOG
      echo "   HOST IP not retrieved for ""$HOST" >> $PATH_LOG
   else
      if [ "$HOST_IP" != "$CURRENT_IP" ]
      then
         one_new=1
         USER=`xmllint --xpath "//credentials/item[position() = $i]/user/text()" "$CRED_FILE"`
         PASS=`xmllint --xpath "//credentials/item[position() = $i]/pass/text()" "$CRED_FILE"`
         RES=`curl --user "$USER:$PASS" "https://www.ovh.com/nic/update?system=dyndns&hostname=$HOST&myip=$CURRENT_IP"`
         echo "$CURRENT_DATE"":" >> $PATH_LOG
         echo "         Host : ""$HOST" >> $PATH_LOG
         echo "   Current IP : ""$CURRENT_IP" >> $PATH_LOG
         echo "      Host IP : ""$HOST_IP" >> $PATH_LOG
         echo "       Result : ""$RES" >> $PATH_LOG
      fi
   fi
done

if [ $one_new = 1 ]
then
   echo "" >> $PATH_LOG
fi

exit 0
