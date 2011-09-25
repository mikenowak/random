#!/usr/bin/sh
#
# A very dirty hack to find multiple revisions of Sun Solaris patches
# in the jumpstart/patches directory.
#
# Think it was writeen by either Jo or Dennis, because I don’t recognize
# the code as mine...
#

JET_PATCHES_PATH="/export/jumpstart/patches"

# All Patches in JET
ALL_PATCHES="`/usr/bin/ls -1 ${JET_PATCHES_PATH}/* | /usr/bin/grep \"^......-..$\"`" 
# Only Unique Patches Numbers (not revisions!)
UNIQUE_PATCH_NUMBERS="`echo ${ALL_PATCHES} | /usr/bin/tr \" \" \"\n\" | /usr/bin/sed \"s/-[0-9]\{2\}//g\" | /usr/bin/uniq`"

for i in ${UNIQUE_PATCH_NUMBERS}; do
	PATCH_REVS="`echo ${ALL_PATCHES} |/usr/bin/tr \" \" \"\n\" | /usr/bin/grep \"^......-..$\" | /usr/bin/grep $i | /usr/bin/sort -nr`"
	PATCH_REVS_COUNT="`echo ${PATCH_REVS} |/usr/bin/tr \" \" \"\n\" | /usr/bin/wc -w`"
	
	if [ "${PATCH_REVS_COUNT}" -gt 1 ]; then
		TO_REMOVE="`expr ${PATCH_REVS_COUNT} - 1`"
		echo "$PATCH_REVS"
		echo "You’ve got old revision: "
		ls -d ${JET_PATCHES_PATH}/*/`echo ${PATCH_REVS} | /usr/bin/tr " " "\n" | /usr/bin/tail -${TO_REMOVE}`
	fi
done
