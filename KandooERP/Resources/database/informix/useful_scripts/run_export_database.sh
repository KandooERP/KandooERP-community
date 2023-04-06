#!/bin/bash
#export KANDOO_ROOTDIR=/home/informix/Projects/KandooERP/KandooERP
if [ "$KANDOO_ROOTDIR" == "" ]
then
	echo "Please set KANDOO_ROOTDIR env var value "
	exit 1
fi

while getopts ":s:f:g:" option
do
    case ${option} in
        s)
            source_dbname=${OPTARG}
        ;;
        f)
            folder=${OPTARG}
        ;;
        g)
            gitoption=${OPTARG}
        ;;
        \?)
            echo "usage $0 -s <source db name> -f <db_snapshots folder name> [ -g add/commit/push ]"
	    return 1
        ;;
    esac
done

errors_num=0;
# run the export stored procedure
dbaccess ${source_dbname} <<+
execute procedure export_kandoo_database("${KANDOO_ROOTDIR}/Resources/database/informix/db_snapshots/${folder}")
+
if [ $? != 0 ]
then
	errors_num=`expr $errors_num + 1`
	echo "export stored procedure failed!"
	exit 1
fi

# fixes dbschema incongruities where sql stmt commands are on several line
perl -lane 'BEGIN { $/=";"; } if ( $_ =~ m/in[\s\n]*demodatadbs/gsm ) { s/in[\s\n]*demodatadbs//gsm;} if ( length($_) > 3 ) { printf "%s;\n",$_ }  ' ${KANDOO_ROOTDIR}/Resources/database/informix/db_snapshots/${folder}/${source_dbname}.exp/${source_dbname}.sql > /tmp/${source_dbname}.sql
if [ $? != 0 ]
then
	errors_num=`expr $errors_num + 1`
	echo "Fix schema file failed!"
	exit 2
fi
# remove  from unl files
for file in ${KANDOO_ROOTDIR}/Resources/database/informix/db_snapshots/${folder}/${source_dbname}.exp/*.unl
do 
	perl -i.back -p -e "s/^M//;" $file
done
touch  ${KANDOO_ROOTDIR}/Resources/database/informix/db_snapshots/${folder}/${source_dbname}.exp/*.unl
touch  ${KANDOO_ROOTDIR}/Resources/database/informix/db_snapshots/${folder}/${source_dbname}.exp/*.sql
rm  ${KANDOO_ROOTDIR}/Resources/database/informix/db_snapshots/${folder}/${source_dbname}.exp/*.back

mv /tmp/${source_dbname}.sql  ${KANDOO_ROOTDIR}/Resources/database/informix/db_snapshots/${folder}/${source_dbname}.exp/${source_dbname}.sql
if [ $? != 0 ]
then
	errors_num=`expr $errors_num + 1`
	echo "Replace schema file failed!"
	exit 3
fi

# zip -r ${KANDOO_ROOTDIR}/Resources/database/informix/db_snapshots/${folder}/kandoodb.exp.zip ${KANDOO_ROOTDIR}/Resources/database/informix/db_snapshots/${folder}/${source_dbname}.exp/
set -x
cd ${KANDOO_ROOTDIR}/Resources/database/informix/db_snapshots/${folder}/
zip -r ${KANDOO_ROOTDIR}/Resources/database/informix/db_snapshots/${folder}/kandoodb.exp.zip  ./${source_dbname}.exp/
read aa
set +x
# git operations ( pushing to the db_patches branch
echo $gitoption
case ${gitoption} in
	add)
		git add  ${KANDOO_ROOTDIR}/Resources/database/informix/db_snapshots/${folder}/${source_dbname}.exp/*
		git add ${KANDOO_ROOTDIR}/Resources/database/informix/db_snapshots/${folder}/kandoodb.exp.zip
		;;
	commit)
		git add  ${KANDOO_ROOTDIR}/Resources/database/informix/db_snapshots/${folder}/${source_dbname}.exp/*
		git add ${KANDOO_ROOTDIR}/Resources/database/informix/db_snapshots/${folder}/kandoodb.exp.zip
		git commit -m "generating kandoodb community db snapshot" 
		;;
	push)
		git add  ${KANDOO_ROOTDIR}/Resources/database/informix/db_snapshots/${folder}/${source_dbname}.exp/*
		git add ${KANDOO_ROOTDIR}/Resources/database/informix/db_snapshots/${folder}/kandoodb.exp.zip
		git commit -m "generating kandoodb community db snapshot" 
		git push
		;;
	*)
		echo
		;;
esac
set +x
