###########################################################################
# This program IS free software; you can redistribute it AND/OR modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2 of the License, OR (at your
# option) any later version.
#
# This program IS distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License FOR more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; IF NOT, write TO the Free Software Foundation, Inc.,
# 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
###########################################################################
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

###########################################################################
# FUNCTION create_table(p_db_table,p_tmp_table,p_columns,p_log_ind)
#
#FUNCTION that creates temporary tables
###########################################################################
FUNCTION create_table(p_db_table,p_tmp_table,p_columns,p_log_ind) 
	DEFINE p_db_table CHAR(50) 
	DEFINE p_tmp_table CHAR(50) 
	DEFINE p_columns CHAR(500) 
	DEFINE p_log_ind CHAR(1) 
	DEFINE l_rec_systables RECORD # DEFINE COLUMNS as RECORD depends ON engine 
		tabname CHAR(128), 
		tabid INTEGER 
	END RECORD 
	DEFINE l_rec_syscolumns RECORD # DEFINE COLUMNS as RECORD depends ON engine 
		tabid INTEGER, 
		colno SMALLINT, 
		colname CHAR(128), 
		coltype SMALLINT, 
		collength SMALLINT 
	END RECORD 
	DEFINE l_create_text STRING 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE l_datatype CHAR(40) 
	DEFINE l_cnt SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE i SMALLINT
	DEFINE l_msg STRING
	
	DEFER QUIT 
	DEFER INTERRUPT 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 
	
	IF fgl_find_table(p_tmp_table) THEN #HuHo 8.10.2020
		LET l_msg = "Table ", trim(p_tmp_table), " already exists!\nTemp table with this name will not be re-created"
		CALL fgl_winmessage("ERROR",l_msg,"ERROR")
	END IF
	
	IF TRUE THEN 
		#Try using this method FOR all databases
		#IF it wont work, THEN this will be used FOR non-Informix only

		LET l_create_text = 
		"SELECT * FROM ", p_db_table CLIPPED, 
		" WHERE rowid = -1 INTO temp ", p_tmp_table CLIPPED 
		IF p_log_ind = 'Y' THEN 
			LET l_create_text = l_create_text CLIPPED 
		ELSE 
			LET l_create_text = l_create_text CLIPPED," with no log" 
		END IF 

		#p_columns IS used TO vreate tables with only specified columns
		#instad of all columns FROM source table. We can do it IF we have
		#TO by replacing * in SELECT above. Lets see IF we have TO:
		IF p_columns IS NOT NULL THEN 
			ERROR "Bugger - we have TO... see tablefunc.4gl" 
			SLEEP 5 
			EXIT program (4) 
		END IF 

		PREPARE s_createtable1 FROM l_create_text 
		EXECUTE s_createtable1 

		RETURN 
	END IF 

	IF p_columns IS NOT NULL THEN 
		LET l_where_text = "colname in(","\"" 
		FOR i = 1 TO length(p_columns) 
			IF p_columns[i] != " " THEN 
				LET l_where_text = l_where_text CLIPPED,p_columns[i] 
			ELSE 
				IF i != length(p_columns) THEN 
					LET l_where_text = l_where_text CLIPPED,"\"",",","\"" 
				END IF 
			END IF 
		END FOR 
		LET l_where_text = l_where_text CLIPPED,"\"",")" 
	ELSE 
		LET l_where_text = "1=1" 
	END IF 

	SELECT tabname,tabid INTO l_rec_systables.* FROM systables 
	WHERE tabname = p_db_table 

	LET l_query_text = 
	"SELECT tabid,colno,colname,p_coltype,p_collength ", 
	" FROM syscolumns ", 
	" WHERE tabid = ",l_rec_systables.tabid, 
	" AND ",l_where_text, 
	" ORDER BY colno" 

	PREPARE s_syscolumns FROM l_query_text 
	DECLARE c_syscolumns CURSOR FOR s_syscolumns 

	LET l_query_text = 
	"SELECT count(*) ", 
	" FROM syscolumns ", 
	" WHERE tabid = ",l_rec_systables.tabid, 
	" AND ",l_where_text 
	PREPARE s_syscnt FROM l_query_text 
	DECLARE c_syscnt CURSOR FOR s_syscnt 

	OPEN c_syscnt 
	FETCH c_syscnt INTO l_cnt 
	CLOSE c_syscnt 

	LET l_create_text = "CREATE TEMP TABLE ",p_tmp_table CLIPPED,"(" 
	LET i = 0 

	FOREACH c_syscolumns INTO l_rec_syscolumns.* 
		LET i = i + 1 
		### p_coltype IS converted TO mod 16 so that 'NOT NULL' IS NOT added
		### TO the COLUMN definition.IF p_coltype = 6 (serial) it IS modified
		### TO equal an INTEGER
		LET l_rec_syscolumns.coltype = l_rec_syscolumns.coltype mod 16 
		IF l_rec_syscolumns.coltype = 6 THEN 
			LET l_rec_syscolumns.coltype = 2 
		END IF 
		LET l_datatype = 
		column_defintion(l_rec_syscolumns.coltype,l_rec_syscolumns.collength) 
		IF i = l_cnt THEN 
			LET l_create_text = l_create_text CLIPPED, 
			l_rec_syscolumns.colname CLIPPED," ", 
			l_datatype CLIPPED 
		ELSE 
			LET l_create_text = l_create_text CLIPPED, 
			l_rec_syscolumns.colname CLIPPED," ", 
			l_datatype CLIPPED,", " 
		END IF 
	END FOREACH 

	IF p_log_ind = 'Y' THEN 
		LET l_create_text = l_create_text CLIPPED,")" 
	ELSE 
		LET l_create_text = l_create_text CLIPPED,") with no log" 
	END IF 

	IF FALSE THEN 
		DISPLAY "p_db_table=", p_db_table CLIPPED 
		DISPLAY "p_tmp_table=", p_tmp_table CLIPPED 
		DISPLAY "p_columns=", p_columns CLIPPED 
		DISPLAY "p_log_ind=", p_log_ind CLIPPED 
		DISPLAY "l_create_text=", l_create_text CLIPPED 
		EXIT program 
	END IF 

	PREPARE s_createtable FROM l_create_text 
	EXECUTE s_createtable 
END FUNCTION 
############################################################
# END FUNCTION create_table(p_db_table,p_tmp_table,p_columns,p_log_ind)
############################################################


############################################################
# FUNCTION column_defintion(p_coltype,p_collength)
#
# This FUNCTION, WHEN given the Column Type AND Column Length (as defined
# in the SYSCOLUMNS table),returns a string that represents the SQL data type
############################################################
FUNCTION column_defintion(p_coltype,p_collength) 
	DEFINE p_coltype SMALLINT 
	DEFINE p_collength SMALLINT 
	DEFINE l_datatype SMALLINT 
	DEFINE l_nulltype SMALLINT 
	DEFINE l_numlength CHAR(6) 
	DEFINE l_numdigits CHAR(6) 
	DEFINE l_numplaces CHAR(6) 
	DEFINE r_coldef CHAR(40) 

	LET l_datatype = p_coltype mod 16 
	LET l_nulltype = p_coltype / 256 
	LET l_numlength = p_collength USING "<<<<<&" 
	LET l_numdigits = (p_collength / 256) USING "<<<<<&" 
	LET l_numplaces = (p_collength mod 256) USING "<<<<<&" 

	CASE l_datatype 
		WHEN 0 
			LET r_coldef = "CHAR(", l_numlength CLIPPED, ")" 
		WHEN 1 
			LET r_coldef = "SMALLINT" 
		WHEN 2 
			LET r_coldef = "INTEGER" 
		WHEN 3 
			LET r_coldef = "float" 
		WHEN 4 
			LET r_coldef = "smallfloat" 
		WHEN 5 
			IF l_numplaces = 255 THEN 
				LET r_coldef = 
				"decimal(",l_numdigits CLIPPED,")" 
			ELSE 
				LET r_coldef = 
				"decimal(", l_numdigits CLIPPED, ",", l_numplaces CLIPPED, ")" 
			END IF 
		WHEN 6 
			LET r_coldef = "serial" 
		WHEN 7 
			LET r_coldef = "date" 
		WHEN 8 
			LET r_coldef = 
			"money(", l_numdigits CLIPPED, ",", l_numplaces CLIPPED, ")" 
		WHEN 10 
			LET r_coldef = "datetime ",fix_dt(p_collength) CLIPPED 
		WHEN 11 
			LET r_coldef = "byte" 
		WHEN 12 
			LET r_coldef = "text" 
		WHEN 13 
			LET r_coldef = 
			"varchar(", l_numplaces CLIPPED, ",", l_numdigits CLIPPED, ")" 
		WHEN 14 
			#LET r_coldef = "interval(", l_numdigits CLIPPED, ")"
			LET r_coldef = "interval ",fix_dt(p_collength) CLIPPED 
		OTHERWISE 
			LET r_coldef = "type", l_datatype, "(", l_numlength CLIPPED, ")" 
	END CASE 

	IF l_nulltype > 0 THEN 
		LET r_coldef = r_coldef CLIPPED," NOT null" 
	END IF 

	RETURN r_coldef 
END FUNCTION 
############################################################
# END FUNCTION column_defintion(p_coltype,p_collength)
############################################################


############################################################
# FUNCTION fix_dt(p_num)
#
#
############################################################
FUNCTION fix_dt(p_num) 
	DEFINE p_num INTEGER 
	DEFINE l_arr_rec_datetype ARRAY[16] OF CHAR(11) 
	DEFINE i SMALLINT 
	DEFINE j SMALLINT 
	DEFINE r_strg CHAR(20)

	LET l_arr_rec_datetype[1] = "year" 
	LET l_arr_rec_datetype[3] = "month" 
	LET l_arr_rec_datetype[5] = "day" 
	LET l_arr_rec_datetype[7] = "hour" 
	LET l_arr_rec_datetype[9] = "minute" 
	LET l_arr_rec_datetype[11] = "second" 
	LET l_arr_rec_datetype[12] = "fraction(1)" 
	LET l_arr_rec_datetype[13] = "fraction(2)" 
	LET l_arr_rec_datetype[14] = "fraction(3)" 
	LET l_arr_rec_datetype[15] = "fraction(4)" 
	LET l_arr_rec_datetype[16] = "fraction(5)" 
	LET i = ((p_num mod 16) mod 12) + 1 
	LET j = ((p_num / 16) mod 16) + 1 
	LET r_strg = l_arr_rec_datetype[j] CLIPPED, " TO ",l_arr_rec_datetype[i] CLIPPED 

	RETURN r_strg 
END FUNCTION 
############################################################
# END FUNCTION fix_dt(p_num)
############################################################


############################################################
# FUNCTION create_table_new (p_source_table,p_target_table,p_columns,p_is_log,p_table_type)
#
# this function has the same functinality as create_table, but takes benefits of more recent SQL syntax
############################################################
FUNCTION create_table_new (p_source_table,p_target_table,p_columns,p_is_log,p_table_type) 
	DEFINE p_source_table CHAR(50) 
	DEFINE p_target_table CHAR(50) 
	DEFINE p_columns CHAR(500) 
	DEFINE p_is_log CHAR(1) 
	DEFINE p_table_type STRING 
	DEFINE l_log_table CHAR(12)
	DEFINE l_temp_table CHAR(6) 
	DEFINE l_rec_systables RECORD # DEFINE COLUMNS as RECORD depends ON engine 
		tabname CHAR(128), 
		tabid INTEGER 
	END RECORD 
	DEFINE l_rec_syscolumns RECORD # DEFINE COLUMNS as RECORD depends ON engine 
		tabid INTEGER, 
		colno SMALLINT, 
		colname CHAR(128), 
		coltype SMALLINT, 
		collength SMALLINT 
	END RECORD 
	DEFINE l_create_text STRING 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE l_datatype CHAR(40) 
	DEFINE l_cnt SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE i SMALLINT
	DEFINE l_msg STRING
	
	IF fgl_find_table(p_target_table) THEN #HuHo 8.10.2020
		LET l_msg = "Table ", trim(p_target_table), " already exists!\nTemp table with this name will not be re-created"
		CALL fgl_winmessage("ERROR",l_msg,"ERROR")
	END IF

	CASE 
		WHEN p_table_type IS NULL 
			LET p_table_type = "TEMP" 
		WHEN p_table_type matches "RAW" 
		WHEN p_table_type matches "TEMP" 
		OTHERWISE 
			RETURN -1 
	END CASE 

	# to be checked yet .... will do later ericv
	CASE 
		WHEN p_is_log IS NULL 
			LET p_is_log = "N" 
			IF p_table_type = "Y" THEN 
				LET l_log_table = "WITH log" 
			ELSE 
				LET l_log_table = "RAW" 
			END IF 
		WHEN p_is_log matches "[Yy]" 
			LET p_is_log = "Y" 
		WHEN p_is_log matches "[Nn]" 
			LET p_is_log = "N" 
		OTHERWISE 
			RETURN -1 
	END CASE 

	# create table my_coa as select "username" as username,* from coa where 1 = 0;
	LET l_create_text = 
	"CREATE ",p_table_type," TABLE ",p_target_table, 
	" AS SELECT * FROM ",p_source_table CLIPPED, 
	" WHERE 1 = 0 " 

	IF false THEN 
		#Try using this method FOR all databases
		#IF it wont work, THEN this will be used FOR non-Informix only

		LET l_create_text = 
		"SELECT * FROM ", p_source_table CLIPPED, 
		" WHERE rowid = -1 INTO temp ", p_target_table CLIPPED 

		IF p_is_log = 'Y' THEN 
			LET l_create_text = l_create_text CLIPPED 
		ELSE 
			LET l_create_text = l_create_text CLIPPED," with no log" 
		END IF 


		#p_columns IS used TO vreate tables with only specified columns
		#instad of all columns FROM source table. We can do it IF we have
		#TO by replacing * in SELECT above. Lets see IF we have TO:
		IF p_columns IS NOT NULL THEN 
			ERROR "Bugger - we have TO... see tablefunc.4gl" 
			SLEEP 5 
			EXIT program (4) 
		END IF 

		PREPARE stmt_crt_tbl FROM l_create_text 
		EXECUTE stmt_crt_tbl 

		RETURN 
	END IF 


	IF p_columns IS NOT NULL THEN 
		LET l_where_text = "colname in(","\"" 
		FOR i = 1 TO length(p_columns) 
			IF p_columns[i] != " " THEN 
				LET l_where_text = l_where_text CLIPPED,p_columns[i] 
			ELSE 
				IF i != length(p_columns) THEN 
					LET l_where_text = l_where_text CLIPPED,"\"",",","\"" 
				END IF 
			END IF 
		END FOR 
		LET l_where_text = l_where_text CLIPPED,"\"",")" 
	ELSE 
		LET l_where_text = "1=1" 
	END IF 

	SELECT tabname,tabid INTO l_rec_systables.* FROM systables 
	WHERE tabname = p_source_table 

	LET l_query_text = 
	"SELECT tabid,colno,colname,l_coltype,l_collength ", 
	" FROM syscolumns ", 
	" WHERE tabid = ",l_rec_systables.tabid, 
	" AND ",l_where_text, 
	" ORDER BY colno" 

	PREPARE p_syscolumns2 FROM l_query_text 
	DECLARE c_syscolumns2 CURSOR FOR p_syscolumns2 

	LET l_query_text = 
	"SELECT count(*) ", 
	" FROM syscolumns ", 
	" WHERE tabid = ",l_rec_systables.tabid, 
	" AND ",l_where_text 
	PREPARE p_syscnt2 FROM l_query_text 
	DECLARE c_syscnt2 CURSOR FOR p_syscnt2 

	OPEN c_syscnt2 
	FETCH c_syscnt2 INTO l_cnt 
	CLOSE c_syscnt2 

	LET l_create_text = "CREATE TEMP TABLE ",p_target_table CLIPPED,"(" 
	LET i = 0 

	FOREACH c_syscolumns2 INTO l_rec_syscolumns.* 
		LET i = i + 1 
		### l_coltype IS converted TO mod 16 so that 'NOT NULL' IS NOT added
		### TO the COLUMN definition.IF l_coltype = 6 (serial) it IS modified
		### TO equal an INTEGER
		LET l_rec_syscolumns.coltype = l_rec_syscolumns.coltype mod 16 
		IF l_rec_syscolumns.coltype = 6 THEN 
			LET l_rec_syscolumns.coltype = 2 
		END IF 
		LET l_datatype = 
		column_defintion(l_rec_syscolumns.coltype,l_rec_syscolumns.collength) 
		IF i = l_cnt THEN 
			LET l_create_text = l_create_text CLIPPED, 
			l_rec_syscolumns.colname CLIPPED," ", 
			l_datatype CLIPPED 
		ELSE 
			LET l_create_text = l_create_text CLIPPED, 
			l_rec_syscolumns.colname CLIPPED," ", 
			l_datatype CLIPPED,", " 
		END IF 
	END FOREACH 

	IF p_is_log = 'Y' THEN 
		LET l_create_text = l_create_text CLIPPED,")" 
	ELSE 
		LET l_create_text = l_create_text CLIPPED,") with no log" 
	END IF 

	IF false THEN 
		DISPLAY "p_source_table=", p_source_table CLIPPED 
		DISPLAY "p_target_table=", p_target_table CLIPPED 
		DISPLAY "p_columns=", p_columns CLIPPED 
		DISPLAY "p_is_log=", p_is_log CLIPPED 
		DISPLAY "l_create_text=", l_create_text CLIPPED 
		EXIT program 
	END IF 

	PREPARE p_createtable2 FROM l_create_text 
	EXECUTE p_createtable2 
END FUNCTION 
############################################################
# END FUNCTION create_table_new (p_source_table,p_target_table,p_columns,p_is_log,p_table_type)
############################################################

############################################################
# FUNCTION create_external_table_sameas (p_source_table,p_infile_fullpath,p_errors_directory,p_create_mode,p_max_errnum,p_delimiter_char)
#
# This function creates an external table
############################################################
FUNCTION create_external_table_sameas (p_source_table,p_infile_fullpath,p_errors_directory,p_create_mode,p_max_errnum,p_delimiter_char)
	DEFINE p_source_table STRING
	DEFINE p_infile_fullpath STRING
	DEFINE p_errors_directory STRING
	DEFINE p_create_mode STRING
	DEFINE p_max_errnum BIGINT
	DEFINE p_delimiter_char CHAR(1)
	DEFINE l_ext_table_name STRING
	DEFINE l_sql_stmt STRING
	
	IF p_delimiter_char IS NULL THEN
		LET p_delimiter_char = "|"
	END IF
	
	LET l_ext_table_name = "ext_",p_source_table
	LET l_sql_stmt = "CREATE EXTERNAL TABLE ",l_ext_table_name,
	" SAMEAS ",p_source_table,
	" USING (DATAFILES (\"DISK:",p_infile_fullpath,"\"), ", 
	" DELIMITER \"",p_delimiter_char,"\", ",
	" MAXERRORS ",p_max_errnum," , ",
	" REJECTFILE \"",p_errors_directory,"/",p_source_table,".rej ","\",",p_create_mode,")" 
	
	PREPARE p_crtbll_stmt FROM l_sql_stmt
	EXECUTE p_crtbll_stmt

	IF sqlca.sqlcode < 0 THEN
		ERROR "Error"
	ELSE
		ERROR "OK"
	END IF

	RETURN sqlca.sqlcode
END FUNCTION
############################################################
# END FUNCTION create_external_table_sameas (p_source_table,p_infile_fullpath,p_errors_directory,p_create_mode,p_max_errnum,p_delimiter_char)
############################################################