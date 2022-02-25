#!/bin/bash

# create checksum file if neccessary
if [ ! -f ./checksums.md5 ]
then
    touch checksums.md5
fi

# get files in directory (recursive) and list in checksum file
DIR_FILES=$(find . -type f ! -name 'checksums.md5' | sort -V | tr -d '\0')
MD5_FILES=$(cat checksums.md5 | cut -c 35- | sort -V | tr -d '\0')

# get list of new and deleted files
NEW_FILES=$(diff --new-line-format="" --unchanged-line-format="" \
            <(echo "${DIR_FILES}") <(echo "${MD5_FILES}"))
DEL_FILES=$(diff --new-line-format="" --unchanged-line-format="" \
            <(echo "${MD5_FILES}") <(echo "${DIR_FILES}"))

# deal with new files
if [ ! -z "${NEW_FILES}" ]
then
    # list new files and add checksums
    echo 'new files:'
    echo '----------'
    echo "${NEW_FILES}" | while IFS= read -r FILE
    do
        echo "${FILE}"
        md5sum "${FILE}" >> checksums.md5
    done
    echo
    
    # sort the checksum file again
    sort -o checksums.md5 -k 2 -V checksums.md5
fi

# deal with deleted files
if [ ! -z "${DEL_FILES}" ]
then
    # list deleted files
    echo 'deleted files:'
    echo '--------------'
    echo "${DEL_FILES}"
    echo
    
    # ask if checksums of deleted files should be removed
    read -p "Remove the checksums for these files? [y/N] " -n 1 -r REPLY
    echo
    if [[ ! ${REPLY} =~ ^[Yy]$ ]]
    then
        exit
    fi
    
    # remove checksums of deleted files
    echo "${DEL_FILES}" | while IFS= read -r FILE
    do
        LINE_NUM=$(cat checksums.md5 | grep -Fn "  ${FILE}" | cut -f1 -d':')
        if [ $(echo "${LINE_NUM}" | wc -l) -ne 1 ]
        then
            echo "Multiple checksums for ${FILE} ... skipping" 1>&2
            continue
        fi
        sed -i "${LINE_NUM}d" checksums.md5
    done
fi
