#!/bin/bash
#
# script to create a user / database in mysql
#

echo -n "Enter Database Name to be created: "
read dbname
echo -n "Enter User to be created: "
read user
echo -n "Enter Password for $user: "
read password

if [ -z $dbname -o -z $user -o -z $password ]; then
	echo "All details are required, exiting."
	exit 1
fi

cat << EOF >> /tmp/$$.sql
CREATE DATABASE $dbname DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE USER '$user'@'localhost' identified by '$password';
GRANT select,insert,update,delete,create,alter,index,drop ON  \`$dbname\`.* TO '$user'@'localhost';
FLUSH PRIVILEGES;
EOF

cat /tmp/$$.sql
mysql -u root -h localhost -p < /tmp/$$.sql
rm -f /tmp/$$.sql