#!/bin/ksh
#
# mail2jira_spooler.sh
#
# This script captures mails (root mail in our case) received to an alias and
# converts them into a text file, for further importing to Atlassian JIRA as
# new issues. Mail headers can be stripped out if desired, by uncomenting relevant
# section below, but I find them helpful when dealing with specific types of
# monitoring alerts - ie. COMMON ARRAY MANAGER (CAM) mail.
#
# Add the line similar to the below into your /etc/aliases
#
# mail2jira: "|/app/mail2jira/bin/mail2jira_spooler.sh jira >> /app/mail2jira/logs/mail2jira.log 2>&1"
#
#
# The objective is to keep this script to a minimum, as the main purpose here is to
# capture the mail, and once we have it we can always retry converting to a jira
# ticket but if we fail to capture then it's gone for good.

# Generate unique Filename for incomming spool with pid appended so we 
# know it's the one we are working on 
EID=`/usr/bin/date '+%m%d%Y%H%M%S'`
FNAME=${EID}.$$
WORKDIR="/app/mail2jira"

# Capture any command line arguments and write to the first line of the
# spool file these may be usefull for separate aliases when filtering is 
# needed
xdate=`date +%d%b%Y`
xtime=`date +%H:%M:%S`

/usr/bin/echo "$1 $xdate $xtime $2 $3 $4 $5 $6 $7" >${WORKDIR}/spooling/${FNAME}

# capture the stdin stream from sendmail to the file, this is the mail payload
/usr/bin/cat - >> ${WORKDIR}/spooling/${FNAME}

# Uncomment the below section if removing mail headers is desired
# lnbr=`grep -n "Date: " ${WORKDIR}/spooling/${FNAME}.mail | awk -F":" '{print $1}'`
# totln=`cat ${WORKDIR}/spooling/${FNAME}.mail |wc -l`
# bodylns=`expr $totln - $lnbr + 1`
# tail -${bodylns} ${WORKDIR}/spooling/${FNAME}.mail >> ${WORKDIR}/spooling/${FNAME}
# rm ${WORKDIR}/spooling/${FNAME}.mail

mv ${WORKDIR}/spooling/${FNAME} ${WORKDIR}/incoming/${FNAME}
chmod 666 ${WORKDIR}/incoming/${FNAME}

exit 0