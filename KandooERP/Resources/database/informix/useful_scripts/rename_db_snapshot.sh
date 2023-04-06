#!/bin/bash
set -x
if [ "$KANDOO_ROOTDIR" == "" ]
then
    echo "Please set KANDOO_ROOTDIR env var value "
    exit 1
fi

while getopts ":s:f:d:" option
do
    case ${option} in
        s)
            source_dbname=${OPTARG}
        ;;
        f)
            folder=${OPTARG}
        ;;
        d)
            if [ "$KANDOO_ROOTDIR" == "" ]
            then
                destination_dbname=kandoodb
            else
                destination_dbname=${OPTARG}
            fi
        ;;
        \?)
            echo "usage $0 -s <source db name> -f <db_snapshots folder name> [ -d <destination db name> ]"
        return 1
        ;;
    esac
done

rm -r  ${KANDOO_ROOTDIR}/Resources/database/informix/db_snapshots/${folder}/${destination_dbname}.exp
mv ${KANDOO_ROOTDIR}/Resources/database/informix/db_snapshots/${folder}/${source_dbname}.exp ${KANDOO_ROOTDIR}/Resources/database/informix/db_snapshots/${folder}/${destination_dbname}.exp
mv ${KANDOO_ROOTDIR}/Resources/database/informix/db_snapshots/${folder}/${destination_dbname}.exp/${source_dbname}.sql ${KANDOO_ROOTDIR}/Resources/database/informix/db_snapshots/${folder}/${destination_dbname}.exp/${destination_dbname}.sql
find ${KANDOO_ROOTDIR}/Resources/database/informix/db_snapshots/${folder}/${destination_dbname}.exp/ -type f -exec sed -i 's/'"${source_dbname}"'/'"${destination_dbname}"'/' {} \;

