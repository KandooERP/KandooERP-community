if [ $# -ne 1 ]
then
	echo "usage: export_previous_version.sh <database name>"
	return 1
else
	database_name=$1
fi
previous_db_name=${database_name}_previous
previous_db_dbspace=data03

export_location=/tmp/previous_db/$database_name
if [ -d $export_location ]
then
	a=1
else
	mkdir -p $export_location
fi
cd $export_location
if [ -d ${database_name}.exp ]
then
	rm -rf ${database_name}.exp
fi
echo -n "exporting database ${database_name} ..."
dbexport -d ${database_name} -ss >/dev/null
if [ $? -eq 0 ]
then
	echo "successful!"
	if [ -d ${previous_db_name}.exp ]
	then
		rm -rf ${previous_db_name}.exp
	fi
	mv ${database_name}.exp/${database_name}.sql  ${database_name}.exp/${previous_db_name}.sql
	mv ${database_name}.exp ${previous_db_name}.exp
	echo "Ready to drop former backup database (Y/N) ? "
	read reply
	if [ "$reply" == "Y" ]
	then
		echo "drop database if exists $previous_db_name" | dbaccess -
		if [ $? -eq 0 ]
		then
			echo -n "importing database $previous_db_name ..."
			dbimport  $previous_db_name -d $previous_db_dbspace >/dev/null
			if [ $? -eq 0 ]
			then
				echo " OK!"
				echo -n "switching database to logged mode "
				ondblog $previous_db_name buf
				ontape -s -L 0 -t /dev/null
			fi
		fi
	else
		echo "exiting procedure, probably someone is connected to the database"
		exit 1
	fi
fi
	
