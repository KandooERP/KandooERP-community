############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../utility/UT1_GLOBALS.4gl"
GLOBALS 
	DEFINE glob_dbsname LIKE dbschema_properties.dbsname
	-- DEFINE glob_dbsvendor LIKE dbschema_properties.dbsvendor 
	DEFINE glob_rec_dbschema_properties RECORD LIKE dbschema_properties.* 
	DEFINE local_patch_home_directory STRING 
	DEFINE wrong_files_list,error_files_list DYNAMIC ARRAY OF STRING 
	DEFINE script_files_list DYNAMIC ARRAY OF STRING 
	DEFINE errors_directory STRING 
	DEFINE dbserver_name STRING 
	DEFINE host_name CHAR(64) 
	DEFINE last_valid_backup DATETIME year TO second 
	DEFINE log_handle base.channel
	DEFINE log_filename STRING
	DEFINE user_is_dba BOOLEAN
	DEFINE glb_prp_ins_dbschema_fix_log PREPARED
	DEFINE glb_prp_ins_dbschema_fix_errors PREPARED
END GLOBALS 

# module scope variables
--DEFINE local_patch_home_directory STRING 
DEFINE specific_script_name STRING 
DEFINE startdate DATE 
DEFINE excludepatchnames STRING 
DEFINE dir_name,file_name STRING
DEFINE error_handle base.channel 
DEFINE time_stamp DATETIME YEAR TO SECOND
DEFINE transaction_started boolean
DEFINE pr_ins_dbschema_fix PREPARED
DEFINE modu_session_start_ts DATETIME YEAR TO SECOND

DEFINE modu_rec_dbschema_fix OF dt_rec_dbschema_fix

# this modules handles the application of dbschema fix scripts ( formerly apply_db_patch.pl )
# General behaviour: the program looks in the Resource/database.../schema change directory for all the scripts that have no been applied yet
# it inserts each script's references in the dbschema_fix table and update the dbschema_properties table which contains the global status of the database

FUNCTION UT1_apply_db_patches_whenever_sqlerror ()
    # this code instanciates the default sql errors handling for all the code lines below this function
    # it is a compiler preprocessor instruction. It is not necessary to execute that function
    WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
END FUNCTION

FUNCTION apply_db_patch_main (pky_dbschema_properties) 
	DEFINE pky_dbschema_properties RECORD 
		dbsname LIKE dbschema_properties.dbsname # nchar(32) 
	END RECORD 
	DEFINE i SMALLINT 
	DEFINE array_size,successful_scripts,skipped_scripts,waiting_scripts,failed_scripts INTEGER 
	DEFINE status_message STRING 

	DEFINE session_id BIGINT
	DEFINE current_user NCHAR(32)
	DEFINE db_owner NCHAR(32)
	DEFINE l_msg STRING	
	DEFINE log_file TEXT
	DEFINE l_arr_loglines DYNAMIC ARRAY OF STRING

	# check that the user connected has dba permissions on this database
	SQL 
	SELECT dbinfo('dbname') 
	INTO $glob_dbsname 
	FROM systables 
	WHERE tabid = 1; 
	END SQL 

	SQL 
	SELECT dbinfo('sessionid') as my_sessionid 
	INTO $session_id 
	FROM systables 
	WHERE tabname = 'systables'; 
	END SQL 
	
	SELECT s.username 
	INTO current_user
	FROM sysmaster:syssessions s
	WHERE s.sid = session_id 
	
	SELECT owner INTO db_owner
	FROM sysmaster:sysdatabases 
	WHERE sysmaster:sysdatabases.name = glob_dbsname
	
	IF current_user <> "informix" AND current_user <> db_owner THEN
		ERROR "You are not allowed to apply database patches, please check with you DBA"
		RETURN
	END IF

	OPEN WINDOW f_apply_db_patch with FORM "f_apply_db_patch" 
	DISPLAY glob_dbsname TO dbsname
	LET specific_script_name = NULL 
	LET startdate = NULL 
	LET excludepatchnames = NULL 

	# Check the last backup, because it is safer to run apply_db_patch with a backup
	SELECT max(dbinfo("utc_to_datetime",level0)) 
	INTO last_valid_backup 
	FROM sysmaster:sysdbstab 
	WHERE NAME NOT MATCHES "*temp*" 

	PREPARE p_get_hostname FROM "SELECT dbinfo('dbhostname') from systables where tabid = 1" 
	DECLARE c_get_hostname CURSOR FOR p_get_hostname 
	OPEN c_get_hostname 
	FETCH c_get_hostname INTO host_name 

	DISPLAY BY NAME glob_rec_dbschema_properties.dbsvendor,last_valid_backup,dbserver_name,host_name 
	LET modu_session_start_ts = current

	MENU "New Patches"
	
		COMMAND "Input Criteria" "Input criteria for new patches handling"
		
			INPUT BY NAME specific_script_name, 
			startdate, 
			excludepatchnames, 
			errors_directory 
			WITHOUT DEFAULTS 
			--	BEFORE INPUT 
			--		CALL DIALOG.SetActionHidden("ACCEPT", true) 
			--		CALL DIALOG.SetActionHidden("CANCEL", true) 
		
		--		ON ACTION "RUN ACTION" 
		--			CALL apply_db_patch (pky_dbschema_properties.dbsvendor) 
		--			RETURNING array_size,successful_scripts,skipped_scripts,failed_scripts 
		--			LET i = 1  
			END INPUT 
		
		COMMAND "Check New Patches" "Check the syntax of patches created after last apply"
			CALL apply_db_patch (pky_dbschema_properties.dbsname,"check",".*") 
			RETURNING array_size,successful_scripts,skipped_scripts,waiting_scripts,failed_scripts
			LET status_message = "Total scripts checked ", array_size USING "###&",", Successful: ",successful_scripts USING "###&", 
			", Skipped: ",skipped_scripts USING "###&"," , Failed " ,failed_scripts USING "###&" 
			EXIT MENU
			
		COMMAND "Test New Patches" "Test execution of new DB patches, but ROLLBACK them"
			CALL apply_db_patch (pky_dbschema_properties.dbsname,"test",".*") 
			RETURNING array_size,successful_scripts,skipped_scripts,waiting_scripts,failed_scripts
			LET status_message = "Total scripts tested ", array_size USING "###&",", Successful: ",successful_scripts USING "###&", 
			", Skipped: ",skipped_scripts USING "###&"," , Failed " ,failed_scripts USING "###&" 
			EXIT MENU
			
		COMMAND "Execute New Patches" "Execute patches created after last apply"
			CALL apply_db_patch (pky_dbschema_properties.dbsname,"execute",".*") 
			RETURNING array_size,successful_scripts,skipped_scripts,waiting_scripts,failed_scripts
			LET status_message = "Total scripts executed ", array_size USING "###&",", Successful: ",successful_scripts USING "###&", 
			", Skipped: ",skipped_scripts USING "###&"," , Waiting for dependency: ",waiting_scripts USING "###&"," , Failed " ,failed_scripts USING "###&" 
			EXIT MENU
			
		COMMAND "View Log" "View global log file"
			CALL read_log_file (log_filename,pky_dbschema_properties.dbsname,"2020-10-01 00:00:00","","","")
			RETURNING l_arr_loglines
			
		COMMAND "RETURN TO PATCH LIST" "Return to Patch List"
			EXIT MENU
	END MENU
 		
	CLOSE WINDOW f_apply_db_patch
	
	SELECT last_patch_date,last_patch_apply,last_patch_ok_scripts,last_patch_ko_scripts
	INTO glob_rec_dbschema_properties.last_patch_date, glob_rec_dbschema_properties.last_patch_apply, 
		glob_rec_dbschema_properties.last_patch_ok_scripts, glob_rec_dbschema_properties.last_patch_ko_scripts
	FROM dbschema_properties
	WHERE dbschema_properties.dbsname = glob_rec_dbschema_properties.dbsname
	
	DISPLAY BY NAME glob_rec_dbschema_properties.last_patch_date, glob_rec_dbschema_properties.last_patch_apply, 
	glob_rec_dbschema_properties.last_patch_ok_scripts, glob_rec_dbschema_properties.last_patch_ko_scripts
	
	LET array_size = display_array_from_fky_dbschema_fix (glob_rec_dbschema_properties.dbsname,True,false)
	 
	DISPLAY BY NAME status_message 
	CALL log_handle.close() 
END FUNCTION 

FUNCTION apply_db_patch (dbsname,actionrequested,patch_name_expr) 
	DEFINE dbsname LIKE dbschema_properties.dbsname
	DEFINE actionrequested STRING
	DEFINE patch_name_expr STRING
	DEFINE dir_name,file_name STRING 
	DEFINE file_handle base.channel 
	DEFINE rs STRING 
	DEFINE var_name,var_value STRING 
	DEFINE r bool 
	DEFINE regexp,regexp_quotes util.regex 
	DEFINE match_rslt util.match_results 
	DEFINE res boolean 
	DEFINE ffg_dir,tmplt_dir,entry STRING 
	DEFINE dir_handle,mdx,fdx,ddx INTEGER 
	DEFINE directory_list DYNAMIC ARRAY OF STRING
	DEFINE file_suffix STRING 
	DEFINE file_dates STRING 
	DEFINE file_date DATE 
	DEFINE line_contents STRING 
	DEFINE varstring DYNAMIC ARRAY OF STRING 
	DEFINE patch_list DYNAMIC ARRAY OF STRING 
	DEFINE snapshot_date_us STRING 
	DEFINE last_patch_date_us STRING 
	DEFINE fix_tabname STRING 
	DEFINE patch_status LIKE dbschema_fix.fix_status
	DEFINE patch_name LIKE dbschema_fix.fix_name
	DEFINE fix_operation STRING 
	DEFINE fullpath,error_filename STRING 
	DEFINE wrong_part,error_message STRING 
	DEFINE filename_format_ok,successful_scripts,failed_scripts,skipped_scripts,waiting_scripts SMALLINT 
	DEFINE filename_format_ko SMALLINT 
	DEFINE status_message,log_message STRING 
	DEFINE sql_stmt STRING 
	DEFINE latest_success_create_date,latest_failed_create_date DATE 
	DEFINE this_fix_exists BOOLEAN
	DEFINE is_a_procedure BOOLEAN

	 
	DEFINE exec_status,array_size INTEGER 


	LET time_stamp = current
	CALL log_handle.write([time_stamp,"--------------------------------------------------------------------------------------------"])
	CALL log_handle.write([time_stamp,"database ",glob_dbsname," on ",dbserver_name," starting apply_db_patch_session ",actionrequested," db patches"])
	# reformat the dates to be compatible with file name's date
	LET snapshot_date_us = glob_rec_dbschema_properties.snapshot_date USING "yyyymmdd" 
	LET last_patch_date_us = glob_rec_dbschema_properties.last_patch_date USING "yyyymmdd" 
	
	CALL os.path.diropen(local_patch_home_directory) RETURNING dir_handle 
	CALL os.Path.dirsort("name",1) 
	LET entry ="#!%$" 
	LET mdx=0 
	LET fdx=0 
	LET filename_format_ok = 0 
	LET filename_format_ko = 0 
	CALL script_files_list.Clear()
	# scan the directory containing the patch scripts	and retain only the ones that have correct names
	WHILE entry IS NOT NULL 
		# read the directory with  sort on file names (i.e. on patch date descending )
		# put the applicable scripts in the array script_files_list

		CALL os.path.dirnext(dir_handle) RETURNING entry
		IF util.regex.search(entry,/^\s*$|^\.|\.sh|\.pl/) THEN
			CONTINUE WHILE
		END IF 
		
		IF  os.Path.isdirectory(entry) THEN
			CONTINUE WHILE
		END IF 		
		
		IF entry IS NULL THEN 
			EXIT WHILE 
		END IF 
		# DISPLAY ">> ",entry
		#LET match_rslt = util.regex.search(entry,/^(20\d\d\d\d\d\d).*\-(\w+)\-(\w+)/) 
		LET match_rslt = util.regex.search(entry,/^(20\d\d\d\d\d\d)\.*\d*\-(\w+)\-(\w+)/)
		IF (match_rslt ) THEN
			# Check that the start of the file name is a real date
			# the file name has the right format: yyyymmdd(.nnn)-tablename-operation.sql
			LET file_suffix = match_rslt.suffix()
			LET file_dates=match_rslt.str(1)
			LET file_dates = file_dates[7,8],"/",file_dates[5,6],"/",file_dates[1,4]
			LET file_date = DATE(file_dates)

			IF file_date IS NULL THEN
				LET time_stamp = current
				CALL log_handle.write([time_stamp,entry clipped,"File name format is not supported (incorrect date),rejecting patch"])
				CONTINUE WHILE 
			END IF

			IF file_date < glob_rec_dbschema_properties.snapshot_date 
			OR file_date < glob_rec_dbschema_properties.last_patch_date 
			OR file_suffix != ".sql" THEN 
				# check if the file date is anterior to last patch date or, if null, inferior to snapshot date, skip that script
				CONTINUE WHILE 
			END IF
			LET patch_name = match_rslt.str(0) 
			LET fix_tabname = match_rslt.str(2)
			
			# Check if the patch is already in dbschema_fix
			SELECT fix_status 
			INTO patch_status  
			FROM dbschema_fix 
			WHERE fix_name = patch_name 
			AND fix_dbsname = glob_rec_dbschema_properties.dbsname 
		
			CASE sqlca.sqlcode 
				WHEN 0 
					LET this_fix_exists = true
				WHEN 100 
					LET this_fix_exists = false 
			END CASE
			CASE 
				WHEN actionrequested MATCHES "view*" AND this_fix_exists = FALSE 
					LET filename_format_ok = filename_format_ok + 1
					LET script_files_list[filename_format_ok] = entry
				WHEN actionrequested NOT MATCHES "view*" AND this_fix_exists = FALSE
					LET filename_format_ok = filename_format_ok + 1
					LET script_files_list[filename_format_ok] = entry
				WHEN actionrequested NOT MATCHES "view*" AND this_fix_exists = TRUE AND patch_status NOT MATCHES "OK*"
					LET filename_format_ok = filename_format_ok + 1
					LET script_files_list[filename_format_ok] = entry
				OTHERWISE
					
			END CASE 
		ELSE 
			IF entry NOT MATCHES "*.unl" AND entry NOT MATCHES "*.pl" AND entry NOT MATCHES "*.sh" THEN		# .unl are tolerated in this directory
				LET filename_format_ko = filename_format_ko + 1 
				LET wrong_files_list[filename_format_ko] = entry
				LET time_stamp = current
				CALL log_handle.write([time_stamp,entry clipped,"File name format is not supported,rejecting patch"])
			END IF
			CONTINUE WHILE 
		END IF 
	END WHILE 
	
	LET entry ="#!%$" 
	LET successful_scripts = 0 
	LET failed_scripts = 0 
	LET array_size = script_files_list.getsize() 
	IF array_size = 0 THEN
		ERROR "There are no db patches matching your request"
		LET time_stamp = current
		CALL log_handle.write([time_stamp,"There are no db patches matching your request",""])
	END IF
	
	# scan the script_files_list list in the directory
	FOR ddx = 1 TO array_size 
		LET fullpath = local_patch_home_directory,"/",script_files_list[ddx]
		LET match_rslt = util.regex.search(fullpath,/([\w\-\.]+)\.sql/) 
		LET error_filename = errors_directory,"/",match_rslt.str(1),".err" 
		LET error_handle = base.channel.create()
		CALL error_handle.openfile(error_filename, "w") 
		IF os.path.exists(fullpath) THEN 
			# parse this script ( just for view, check or execute )
			# if checked or executed, the script is inserted/updated in dbschema_fix
			DISPLAY script_files_list[ddx]," starting script"
			LET time_stamp = current
			CALL log_handle.write([time_stamp,script_files_list[ddx],"starting script"])

			CALL parse_script_file (actionrequested,fullpath,ddx) 
				RETURNING exec_status,error_files_list[ddx] 
			CASE exec_status 
				WHEN 0 
					LET successful_scripts = successful_scripts + 1
					DISPLAY "       script completed successfully"
					LET time_stamp = current
					CALL log_handle.write([time_stamp,"       script completed successfully"]) 
				WHEN -1 
					LET skipped_scripts = skipped_scripts + 1 
					DISPLAY "       script already completed (skipped)"
					LET time_stamp = current
					CALL log_handle.write([time_stamp,"       script already completed (skipped)"])
				WHEN -2 
					LET waiting_scripts = waiting_scripts + 1 
					DISPLAY "       script waiting for dependency (skipped)"
					LET time_stamp = current
					CALL log_handle.write([time_stamp,"       script waiting for dependency (skipped)"])
				WHEN -3 
					LET skipped_scripts = skipped_scripts + 1 
					DISPLAY "       script declared as ignored (skipped)"
					LET time_stamp = current
					CALL log_handle.write([time_stamp,"       script declared as ignored or deleted (skipped)"])
				OTHERWISE  
					DISPLAY "       SCRIPT FAILED",exec_status,"ERRORS"
					LET time_stamp = current
					CALL log_handle.write([time_stamp,"       SCRIPT FAILED",exec_status,"ERRORS"])
					LET failed_scripts = failed_scripts + 1 
			END CASE 
		ELSE 
			LET error_message = "Script file missing ",fullpath clipped 
			ERROR error_message  
			CALL error_handle.writeline(error_message) 
		END IF 
		CALL error_handle.close()
	END FOR 

	# Update agregate data of dbschema_properties from dbschema_fix (last valid patch date, last patch apply date and stats)
	IF actionrequested = "execute" THEN 
		# Now Update dbschema_properties with aggregate data
		# First detect the first date having scripts failed or waiting for dependency
		# the execution will try to replay all the scripts from that date
		SELECT min(fix_create_date)
		INTO latest_failed_create_date
		FROM dbschema_fix
		WHERE fix_status IN ('KO','WAD') 
		IF latest_failed_create_date IS NULL or sqlca.sqlcode = 100 THEN
			# If no patch in KO or WAD, then apply last patch create date 
			SELECT max(fix_create_date)
			INTO latest_failed_create_date
			FROM dbschema_fix
			WHERE fix_status matches 'OK*' 
		END IF 

		# THen get the latest date when ALL the patches have been applied successfully <= latest date with errors
		# this will give the date from which scripts can be executed next time
		SELECT max(fix_create_date)
		INTO latest_success_create_date
		FROM dbschema_fix
		WHERE fix_status matches 'OK*' 
		AND fix_create_date <= latest_failed_create_date
		IF latest_success_create_date IS NULL THEN 
			LET latest_success_create_date = latest_failed_create_date 
		END IF 
		
		LET time_stamp = current
		DISPLAY "successful: ",successful_scripts," skipped:",skipped_scripts," waiting for dependency:",waiting_scripts," failed:",failed_scripts
		DISPLAY "Please check details in log file : ",log_filename
		CALL log_handle.write([time_stamp,"successful: ",successful_scripts,"skipped:",skipped_scripts,"waiting for dependency:",waiting_scripts,"failed:",failed_scripts])
		CALL log_handle.write([time_stamp,"First failed patch date: ",latest_success_create_date])
		CALL log_handle.write([time_stamp,"    database ",glob_dbsname,"closing apply_db_patch_session"])
		
		WHENEVER SQLERROR CONTINUE
		UPDATE dbschema_properties 
		SET (last_patch_date,last_patch_apply,last_patch_ok_scripts,last_patch_ko_scripts) 
		= ( latest_success_create_date,current,successful_scripts,failed_scripts) 
		WHERE dbschema_properties.dbsname = glob_rec_dbschema_properties.dbsname
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
		
		IF sqlca.sqlerrd[3] != 1 THEN
			ERROR "Could not update  dbschema_properties"
		END IF
		
	END IF 

	RETURN array_size,successful_scripts,skipped_scripts,waiting_scripts,failed_scripts 
END FUNCTION 

FUNCTION parse_script_file (actionrequested,fullpath,scriptnum) 
# Read this script, parse its syntax, and according to actionrequested, does nothing, tests prepared stmt or execute the statements
# each sql statement will have one row in dbschema_fix_log and eventually  dbschema_fix_errors
	DEFINE actionrequested STRING
	DEFINE fullpath STRING 
	DEFINE scriptnum SMALLINT 
	DEFINE line_contents STRING 
	DEFINE sql_script_handle,error_handle base.channel 
	DEFINE regexp,regexp_quotes util.regex 
	DEFINE match_rslt util.match_results 
	DEFINE patch_author,patch_comments STRING 
	DEFINE patch_dates CHAR(10) 
	DEFINE patch_name LIKE dbschema_fix.fix_name 
	DEFINE patch_type LIKE dbschema_fix.fix_type 
	DEFINE patch_description LIKE dbschema_fix.fix_abstract 
	DEFINE patch_tables_list LIKE dbschema_fix.fix_tableslist 
	DEFINE filename_date LIKE dbschema_fix.fix_create_date 
	DEFINE patch_date LIKE dbschema_fix.fix_create_date
	DEFINE patch_apply_datetime LIKE dbschema_fix.fix_apply_date 
	DEFINE patch_dependencies LIKE dbschema_fix.fix_dependencies 
	DEFINE patch_status LIKE dbschema_fix.fix_status 
	DEFINE patch_id LIKE dbschema_fix.fix_id 
	DEFINE sql_statement STRING 
	DEFINE i,script_stmt_number,script_successed_stmts,script_failed_stmts INTEGER 
	DEFINE adding_commit_stmt boolean 
	DEFINE end_of_statement STRING
	DEFINE error_message STRING 
	DEFINE error_filename STRING 
	DEFINE skip_errnum INTEGER
	DEFINE forced_status STRING
	DEFINE load_file,insert_stmt STRING
	DEFINE error_line STRING 
	DEFINE line_number SMALLINT 
	DEFINE this_fix_exists boolean 
	DEFINE this_patch_header_is_ok SMALLINT
	DEFINE execute_this_patch,waiting_on_dependency boolean
	DEFINE stmt_success,stmt_failed SMALLINT
	DEFINE is_a_procedure BOOLEAN
	DEFINE is_a_function BOOLEAN
	DEFINE prep_stmt PREPARED

	# script file
	LET patch_name = util.REGEX.replace(os.Path.basename(fullpath),/\.sql/,"") 

	# Check if patch has been executed and status ( OK,ok, ko or KO )
	LET this_fix_exists = false 
	LET waiting_on_dependency = false
	SELECT fix_apply_date,fix_status,fix_dependencies,fix_id 
	INTO patch_apply_datetime,patch_status,patch_dependencies,patch_id 
	FROM dbschema_fix 
	WHERE fix_name = patch_name 
	AND fix_dbsname = glob_rec_dbschema_properties.dbsname 

	CASE sqlca.sqlcode 
		WHEN 0 
			IF patch_apply_datetime IS NOT NULL THEN
				CASE  
					WHEN patch_status MATCHES "OK*" 
						# This batch has already been executed successfully, return "skip"
						RETURN -1,"" 
					WHEN patch_status = "IGN"
						# ignore this patch / special procedure handle with care
						RETURN -3
					WHEN patch_status = "DEL"
						# patch deleted, somewhat equivalent to IGNORE
						RETURN -3
					OTHERWISE 
						# We can re-execute
						LET this_fix_exists = true 
				END CASE
			ELSE 
				# datetime IS null > has not been executed, we can re-execute
				LET this_fix_exists = true 
			END IF 

		WHEN 100 
			LET this_fix_exists = false
			LET patch_id = 0 
	END CASE 

	LET sql_script_handle = base.channel.create() 
	CALL sql_script_handle.openfile(fullpath, "r") 

	# All scripts will be a transaction
	# only the case of "force" will handle transactions specifically
	IF NOT transaction_started 
	AND ( actionrequested = "execute" OR actionrequested = "force" ) THEN 
		BEGIN WORK 
		LET transaction_started = true 
	END IF 


	# make error file name
	LET match_rslt = util.regex.search(fullpath,/([\w\-\.]+)\.sql/) 
	LET error_filename = errors_directory,"/",match_rslt.str(1),".err" 

	LET match_rslt = util.regex.search(fullpath,/(20\d\d)(\d\d)(\d\d).*\-(\w+)\-(\w+)\.sql/) 
	IF (match_rslt) THEN 
		LET patch_dates = match_rslt.str(3),"/",match_rslt.str(2),"/",match_rslt.str(1) 
		LET filename_date = date(patch_dates) 
		LET patch_date = filename_date
		LET patch_type = match_rslt.str(5) 
	END IF 

	# read the script file
	LET script_stmt_number = 0 
	LET script_successed_stmts = 0 
	LET script_failed_stmts = 0 
	LET adding_commit_stmt = false 
	LET execute_this_patch = true


	LET line_number = 0 

	# force patch_dependencies in case the dependencies line is not in the script
	LET patch_dependencies = "none" 
	INITIALIZE patch_description TO NULL
	INITIALIZE patch_tables_list TO NULL
	INITIALIZE patch_author TO NULL
	LET this_patch_header_is_ok = 0  #  we assume the patch is not OK until we proove it is
	INITIALIZE end_of_statement TO NULL
	
	WHILE NOT sql_script_handle.iseof()
	# read the script lines
	# first check the header and take its values for further display 
		LET line_contents = sql_script_handle.readline() 
		LET line_number = line_number + 1 
		IF util.regex.search(line_contents,/^\s*$/) THEN 
			CONTINUE WHILE 
		END IF
 
		LET match_rslt = util.regex.search(line_contents,/--# description:\s*(.*)/) 
		IF ( match_rslt ) THEN 
			LET patch_description = match_rslt.str(1) 
			CONTINUE WHILE 
		END IF 
		
		LET match_rslt = util.regex.search(line_contents,/--# tables list:\s*(.*)/) 
		IF ( match_rslt ) THEN 
			LET patch_tables_list = match_rslt.str(1) 
			CONTINUE WHILE 
		END IF 

		LET match_rslt = util.regex.search(line_contents,/--# author:\s*(.*)/) 
		IF ( match_rslt ) THEN 
			LET patch_author = match_rslt.str(1) 
			CONTINUE WHILE 
		END IF 

		LET match_rslt = util.regex.search(line_contents,/--# dependencies:\s*(.*)/) 
		# Check if this patch depends on another patch: dependencies name must be a script named as all other scripts, i.e yyyymmdd-tablename-dependency
		# the patch must have been applied successfully ( status = OK )
		IF ( match_rslt ) THEN 	
			LET patch_dependencies = match_rslt.str(1)
			# Check that what is after dependencies: is a patch name or not
			LET match_rslt = util.regex.search(patch_dependencies,/\b20\d\d\d\d\d\d.*\-\w+\-\w+\b/) 
			IF ( match_rslt ) THEN 	
				LET patch_dependencies = match_rslt.str(0) 
				SELECT fix_status
				INTO patch_status
				FROM dbschema_fix
				WHERE fix_name = patch_dependencies
				CASE
					WHEN sqlca.sqlcode = 0 AND patch_status matches "OK*" 
						LET execute_this_patch = true
					OTHERWISE
						ERROR "Please execute patch ",patch_dependencies
						LET execute_this_patch = false
						LET waiting_on_dependency = true
						EXIT WHILE
				END CASE
			ELSE
				LET patch_dependencies = "N/A"
			END IF
				  
			CONTINUE WHILE 
		END IF 

		LET match_rslt = util.regex.search(line_contents,/--# more comments:\s*(.*)/) 
		IF ( match_rslt ) THEN 
			LET patch_comments = match_rslt.str(1) 	
			CONTINUE WHILE 
		END IF 

		# Now check if we have all the not null values
		IF patch_description IS NULL THEN	
			LET time_stamp = current
			ERROR "Patch description is empty rejecting script"
			CALL log_handle.write([time_stamp,"Patch description is empty","rejecting script"])
			EXIT WHILE
		END IF

		IF patch_tables_list IS NULL THEN
			LET time_stamp = current
			ERROR "Tables list is empty, rejecting script"
			CALL log_handle.write([time_stamp,"Tables list is empty","rejecting script"])
			EXIT WHILE
		END IF

		IF patch_author IS NULL THEN
			ERROR "Patch author is empty, please check patch"
			CALL log_handle.write([time_stamp,"Patch author is empty","rejecting script"])
			EXIT WHILE 
		END IF

		# after all those tests, the patch syntax is OK
		LET this_patch_header_is_ok = 1
		# handle errors with --# on exception -NNN or --# on exception stop
		# for now on exception works only for 1 statement
		LET match_rslt = util.regex.search(line_contents,/on\s+exception\s+(-\d+)\s+status\s*=\s*(\w+)/im)
		IF ( match_rslt ) THEN
			LET skip_errnum = match_rslt.str(1)
			LET forced_status = match_rslt.str(2)
			LET match_rslt = util.regex.search(skip_errnum,/stop/i) 
			CONTINUE WHILE 
		END IF

		LET match_rslt = util.regex.search(line_contents,/^--/) 
		IF ( match_rslt ) THEN 
			CONTINUE WHILE 
		END IF 
		
		# Special case of CREATE PROCEDURE/FUNCTION that is multi-line and finishes by END PROCEDURE/FUNCTION
		LET match_rslt = util.regex.search(line_contents,/^\s*CREATE\s+(PROCEDURE)\s|^\s*CREATE\s+(FUNCTION)\s/i) 
		IF  ( match_rslt  )  THEN
			IF end_of_statement IS NULL THEN
				CASE
					WHEN upshift(match_rslt.str(1)) = "PROCEDURE"
						LET is_a_procedure = TRUE
						LET end_of_statement = "END PROCEDURE"
						LET is_a_function = FALSE
					WHEN upshift(match_rslt.str(1)) = "FUNCTION"
						LET is_a_procedure = FALSE
						LET end_of_statement = "END FUNCTION"
						LET is_a_function = TRUE
				END CASE
			END IF
		ELSE
			IF end_of_statement IS NULL THEN
				LET end_of_statement = ";"
				LET is_a_function = FALSE
				LET is_a_procedure = FALSE				
			END IF
		END IF

		# At this stage, any line is an sql statement or part of sql statement
		LET sql_statement = sql_statement," ",line_contents 
		--LET match_rslt = util.regex.search(line_contents,/\;/) 
		LET match_rslt = util.regex.search(line_contents,end_of_statement) # catch end of statement 

		IF  ( match_rslt )  THEN
			IF actionrequested != "view" THEN
				# view -> just list the script, other options test or execute the script
				# ';' means the end of the statement
				IF NOT is_a_procedure THEN
					LET sql_statement = util.REGEX.replace(sql_statement,/;.*/,"")
				END IF
				IF  util.regex.search(line_contents,/begin work|commit work|rollback work/) THEN
					# skip begin, commit and rollback, they are executed by this program
					LET sql_statement = NULL
					CONTINUE WHILE
				END IF
				IF execute_this_patch = true THEN
					# Execute one SQL statement
					LET patch_apply_datetime = CURRENT 
					LET modu_rec_dbschema_fix.fix_name = patch_name
					LET script_stmt_number = script_stmt_number + 1 
					CALL execute_this_sql_statement(actionrequested,sql_statement,line_number,skip_errnum,forced_status,patch_name,patch_id)
					RETURNING stmt_success
					IF stmt_success = 0 THEN
						LET script_failed_stmts = script_failed_stmts + 1
					ELSE
						LET script_successed_stmts = script_successed_stmts + 1
					END IF					
					INITIALIZE sql_statement TO NULL
					INITIALIZE end_of_statement TO NULL
					# Reset skip_errnum
					LET skip_errnum = NULL
					LET forced_status = NULL
					IF sql_script_handle.iseof() THEN 
						EXIT WHILE 
					END IF 
				END IF
			END IF 
		END IF
 
	END WHILE
	
	IF sql_statement IS NOT NULL AND actionrequested <> "view" THEN
		# proceed last statement just  in case ';' has been forgotten at the end
		CALL execute_this_sql_statement(actionrequested,sql_statement,line_number,skip_errnum,forced_status,patch_name,patch_id)
		RETURNING stmt_success

		IF stmt_success = 0 THEN
			LET script_failed_stmts = script_failed_stmts + 1
		ELSE
			LET script_successed_stmts = script_successed_stmts + 1
		END IF
		# reset both flags
		LET is_a_procedure = FALSE
		LET is_a_function = FALSE
		
	END IF

	CALL sql_script_handle.close() 
 
 
	LET modu_rec_dbschema_fix.fix_abstract = patch_description 
	LET modu_rec_dbschema_fix.fix_tableslist = patch_tables_list 

	IF actionrequested = "view" THEN 
		LET modu_rec_dbschema_fix.fix_status = "NEW" 
		# View only, no sql operations involved
--		RETURN 0,"" 
	END IF 

	IF script_failed_stmts = 0 THEN 
		# zero error in the whole script: the script is successful
		# delete the error file if no errors
		CALL os.path.delete(error_filename) RETURNING status 
		LET error_filename = NULL 
		CASE
			WHEN waiting_on_dependency = true
				LET modu_rec_dbschema_fix.fix_status = "WAD"
				LET modu_rec_dbschema_fix.fix_apply_date = NULL
				CALL add_new_dbschema_fix_element(modu_rec_dbschema_fix.*)
			WHEN actionrequested = "execute" 
				LET modu_rec_dbschema_fix.fix_status = "OK" 
				LET modu_rec_dbschema_fix.fix_apply_date = patch_apply_datetime 
			WHEN actionrequested = "force" 
				LET modu_rec_dbschema_fix.fix_status = "OKF" 
				LET modu_rec_dbschema_fix.fix_apply_date = patch_apply_datetime
			WHEN actionrequested = "check" 
				LET modu_rec_dbschema_fix.fix_status = "ok" 
				LET modu_rec_dbschema_fix.fix_apply_date = NULL
			WHEN actionrequested = "test" 
				LET modu_rec_dbschema_fix.fix_status = "ok" 
				LET modu_rec_dbschema_fix.fix_apply_date = NULL 
 			WHEN actionrequested = "view"
				LET modu_rec_dbschema_fix.fix_status = "NE"
				CALL add_new_dbschema_fix_element(modu_rec_dbschema_fix.*)
			OTHERWISE 
				LET modu_rec_dbschema_fix.fix_status = "??" 
		END CASE 
	ELSE 
		# the script has at least one error, it is failed
		CASE actionrequested 
			WHEN "execute" 
				LET modu_rec_dbschema_fix.fix_status = "KO" 
				LET modu_rec_dbschema_fix.fix_apply_date = NULL
			WHEN "force" 
				LET modu_rec_dbschema_fix.fix_status = "FKO" 
				LET modu_rec_dbschema_fix.fix_apply_date = NULL
			WHEN "check" 
				LET modu_rec_dbschema_fix.fix_status = "ko" 
				LET modu_rec_dbschema_fix.fix_apply_date = NULL
			WHEN "test" 
				LET modu_rec_dbschema_fix.fix_status = "ko" 
				LET modu_rec_dbschema_fix.fix_apply_date = NULL  
			OTHERWISE 
				LET modu_rec_dbschema_fix.fix_status = "??" 
		END CASE 
	END IF 
	
	IF actionrequested != "view" THEN
		
 		#  set the latest successful patch date for the dbschema_properties table 
		#LET latest_patch_date = patch_date
		IF transaction_started = true THEN 
			IF script_failed_stmts = 0 THEN
				# the script file is considered as ONE TRANSACTION, so we try to commit at the end of the file
				WHENEVER SQLERROR CONTINUE 
				IF actionrequested = "execute" OR actionrequested = "force" THEN 
					COMMIT WORK
					LET transaction_started = false
					IF sqlca.sqlcode < 0 THEN
						# error can happen at commit time namedly for constraint violations
						ROLLBACK WORK
						LET transaction_started = false
						DISPLAY 					      "       KO: ERROR",sqlca.sqlcode," isam error ",sqlca.sqlerrd[2],"COMMIT WORK"
						CALL log_handle.write([time_stamp,"       KO: ERROR ",sqlca.sqlcode," isam error ",sqlca.sqlerrd[2],"COMMIT WORK"])
						LET script_failed_stmts = script_failed_stmts + 1
						LET script_successed_stmts = script_successed_stmts -1
						CALL glb_prp_ins_dbschema_fix_log.Execute(modu_session_start_ts,patch_id,99999,"COMMIT WORK" ,time_stamp,"KO",sqlca.sqlcode,sqlca.sqlerrd[2],glob_rec_kandoouser.sign_on_code,"0:00:00")
						CALL glb_prp_ins_dbschema_fix_errors.Execute(modu_session_start_ts,patch_id,99999,error_message)						
					END IF
				ELSE
					# case of TEST which rolls back the whole transaction
					ROLLBACK WORK
					LET transaction_started = false
				END IF 
				LET transaction_started = false 
			ELSE 
				ERROR "One of the statements failed, rollback" 
				ROLLBACK WORK 
				LET transaction_started = false 
			END IF
			WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
			# Force set constraints to IMMEDIATE, in case it has been set to DEFERRED
--			CALL prep_stmt.Prepare("SET CONSTRAINTS ALL IMMEDIATE", 1)
--			CALL prep_stmt.Execute()
		END IF
		
		

		# the dbschema_fix row is inserted or update out of the transaction
		# INSERT or UPDATE the dbschmea_fix record
		# First attempt an insert, if already exists, update the row with apply datetime and status
		IF this_patch_header_is_ok = 1 THEN   # check that the patch header is compliant with header rules
			IF this_fix_exists = false AND actionrequested != "view" THEN 
				# sensitive operation must be in a new transaction
				BEGIN WORK
				INSERT INTO dbschema_fix (fix_name,fix_dbvendor,fix_abstract,fix_type,fix_dependencies,fix_tableslist,fix_create_date,fix_apply_date,fix_status,fix_dbsname,fix_id) 
				VALUES (patch_name,glob_rec_dbschema_properties.dbsvendor,patch_description,patch_type, 
				patch_dependencies,patch_tables_list,patch_date, 
				modu_rec_dbschema_fix.fix_apply_date, 
				modu_rec_dbschema_fix.fix_status,glob_rec_dbschema_properties.dbsname,0)
				LET patch_id = sqlca.sqlerrd[2]
				
				# since fix_log has been inserted previously with fix_id = 0, we update with the right value
				UPDATE  dbschema_fix_log SET fix_id = patch_id
				WHERE fix_id = 0
				
				UPDATE  dbschema_fix_errors SET fix_id = patch_id
				WHERE fix_id = 0
				COMMIT WORK
				
			ELSE 
				--IF modu_rec_dbschema_fix.fix_status <> patch_status THEN
					# sensitive operation must be in a new transaction
					BEGIN WORK
					UPDATE dbschema_fix 
					SET ( fix_apply_date,fix_status) = (modu_rec_dbschema_fix.fix_apply_date,modu_rec_dbschema_fix.fix_status) 
					WHERE fix_name = patch_name 
					AND fix_dbsname = glob_rec_dbschema_properties.dbsname
					# since fix_log has been inserted previously with fix_id = 0, we update with the right value
					--SELECT fix_id
					--INTO l_fix_id
					--FROM dbschema_fix 
					--WHERE fix_name = patch_name
					
					--UPDATE  dbschema_fix_log SET fix_id = l_fix_id
					--WHERE fix_id = 0
					
					--UPDATE  dbschema_fix_errors SET fix_id = l_fix_id
					--WHERE fix_id = 0					
					COMMIT WORK
				--END IF
			END IF
		END IF
	END IF 

	CASE
		WHEN script_failed_stmts > 0 
			RETURN script_failed_stmts,error_filename 
		WHEN waiting_on_dependency = true 
			RETURN -2,""
		OTHERWISE 
			RETURN 0,""
	END CASE 	
END FUNCTION 		# parse_script_file

FUNCTION load_from_external_table(sql_statement) 
	# this function will simulates the load command using an external table
	DEFINE sql_statement STRING 
	DEFINE match_rslt util.match_results 

	-- LET match_rslt = util.regex.search(sql_statement,/load FROM \s+\"([\w\-]+)\"/) 
END FUNCTION  # load_from_external_table

FUNCTION execute_this_sql_statement(p_actionrequested,p_sql_statement,p_line_number,p_skip_errnum,p_forced_status,p_patch_name,p_patch_id)
	DEFINE p_actionrequested STRING
	DEFINE p_sql_statement STRING
	DEFINE p_line_number INTEGER
	DEFINE p_patch_name STRING
	DEFINE load_file,infile STRING
	DEFINE load_stmt STRING
	DEFINE p_skip_errnum INTEGER
	DEFINE p_forced_status STRING
	DEFINE p_patch_id LIKE dbschema_fix.fix_id
	DEFINE i SMALLINT
	DEFINE script_successed_stmt SMALLINT
	DEFINE script_failed_stmts SMALLINT 
	DEFINE error_message STRING 
	DEFINE error_line STRING
	DEFINE is_load_unload BOOLEAN
	DEFINE match_rslt util.match_results
	DEFINE reg_exp util.regex
	DEFINE load_status INTEGER
	DEFINE exec_sql_code,exec_isam_code INTEGER
	DEFINE prep_sql_code,prep_isam_code INTEGER
	DEFINE load_sql_code,load_isam_code INTEGER
	DEFINE l_response_time INTERVAL HOUR TO SECOND
	
	IF util.regex.match(p_sql_statement,/begin work/i) 
	AND p_actionrequested = "execute" THEN 
		# since we forced BEGIN WORK, we skip this line
		LET p_sql_statement = NULL 
		--CONTINUE WHILE
		RETURN 0
	END IF 
	
	IF util.regex.match(p_sql_statement,/commit work|rollback work/i)
	AND p_actionrequested = "execute" THEN 
		# since we forced BEGIN WORK, we skip this line
		LET p_sql_statement = NULL 
		--CONTINUE WHILE
		RETURN 0
	END IF 
	
	LET match_rslt = util.regex.search(p_sql_statement,/load from|unload to/im)
	# LET is_load_unload = util.regex.match(p_sql_statement,/load from/i)
	IF (match_rslt) THEN
		LET  is_load_unload = TRUE
	ELSE
		LET  is_load_unload = FALSE
	END IF
	IF  is_load_unload = false THEN
		# Regular PREPARE/EXECUTE. Load and unload must be prepared in a specific way	 
		WHENEVER SQLERROR CONTINUE 
		PREPARE p_statement FROM p_sql_statement
		LET prep_sql_code = sqlca.sqlcode
		LET prep_isam_code = sqlca.sqlerrd[2]
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
		CASE
			# testing the PREPARE statement
			WHEN prep_sql_code = 0 
				CASE  
					WHEN p_actionrequested = "check" 
						LET script_successed_stmt = 1
						DISPLAY "       ok",p_sql_statement
						LET time_stamp = current
						CALL log_handle.write([time_stamp,"       ok",p_sql_statement])
					WHEN p_actionrequested = "execute" OR p_actionrequested = "force" OR p_actionrequested = "test"
						# execute the statement

						WHENEVER SQLERROR CONTINUE
						# Execute the statement
						EXECUTE p_statement 
						LET exec_sql_code = sqlca.sqlcode
						LET exec_isam_code = sqlca.sqlerrd[2]
						
						LET l_response_time = current - time_stamp
						WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
						# Testing the EXECUTE statement
						CASE 
							WHEN exec_sql_code = 0 
								LET script_successed_stmt = 1
								LET time_stamp = current
								DISPLAY "       OK",p_sql_statement
								CALL log_handle.write([time_stamp,"       OK",p_sql_statement])  
								CALL glb_prp_ins_dbschema_fix_log.Execute(modu_session_start_ts,p_patch_id,p_line_number,p_sql_statement,time_stamp,"OK",0,0,glob_rec_kandoouser.sign_on_code,l_response_time)
							WHEN exec_sql_code = p_skip_errnum
								# on exception case: the query is considered as OK altjough it is not, but acceptable
								LET script_successed_stmt = 1
								LET time_stamp = current
								DISPLAY "       ",p_forced_status,"(",exec_sql_code USING "<<<<<",")",p_sql_statement
								CALL log_handle.write([time_stamp,"       ",p_forced_status,"(",exec_sql_code USING "<<<<<",")",p_sql_statement])
								CALL glb_prp_ins_dbschema_fix_log.Execute(modu_session_start_ts,p_patch_id,p_line_number,p_sql_statement,time_stamp,"OKE",0,0,glob_rec_kandoouser.sign_on_code,l_response_time)
							WHEN exec_sql_code < 0
								LET time_stamp = current
								LET script_successed_stmt = 0
								DISPLAY "       KO: ERROR",exec_sql_code," isam error ",exec_isam_code,p_sql_statement
								CALL log_handle.write([time_stamp,"       KO: ERROR ",exec_sql_code," isanm error ",exec_isam_code,p_sql_statement])
								ERROR "Sql Statement EXECUTE did not work",p_sql_statement,exec_sql_code 
								LET script_failed_stmts = 1 
								LET error_message = util.REGEX.replace(sqlerrmessage,/\n|\s+/,/ /) --sqlca.sqlerrm 
								LET error_line = "Line ",p_line_number," : error ",exec_sql_code," isam error: ",exec_isam_code," at position ",sqlca.sqlerrd[5] 
								CALL error_handle.writeline(p_sql_statement) 
								CALL error_handle.writeline(error_line) 
								CALL error_handle.writeline(error_message) 
								CALL glb_prp_ins_dbschema_fix_log.Execute(modu_session_start_ts,p_patch_id,p_line_number,p_sql_statement,time_stamp,"KO",exec_sql_code,exec_isam_code,glob_rec_kandoouser.sign_on_code,l_response_time)
								CALL glb_prp_ins_dbschema_fix_errors.Execute(modu_session_start_ts,p_patch_id,p_line_number,error_message)
								# check sqlca.sqlerrd xxx
								IF p_actionrequested = "execute" OR p_actionrequested = "force" THEN 
									--ROLLBACK WORK 
									--LET transaction_started = false 
								END IF 
						END CASE 
				END CASE 
			WHEN prep_sql_code = p_skip_errnum
				LET script_successed_stmt = 1
				LET time_stamp = current
				DISPLAY "           ",p_forced_status,"(",prep_sql_code USING "<<<<<",")",p_sql_statement
				CALL log_handle.write([time_stamp,"       ",p_forced_status,"(",prep_sql_code USING "<<<<<",")",p_sql_statement])
			
			WHEN prep_sql_code < 0
				LET time_stamp = current
				LET script_successed_stmt = 0
				DISPLAY "       KO: ERROR ",prep_sql_code," isam error ",prep_isam_code,p_sql_statement
				CALL log_handle.write([time_stamp,"       KO: ERROR ",prep_sql_code," isam error ",prep_isam_code,p_sql_statement])
				ERROR "Sql Statement PREPARE did not work",p_sql_statement,prep_sql_code 
				LET script_failed_stmts =  1 
				LET error_message = util.REGEX.replace(sqlerrmessage,/\s+/,/ /) --sqlca.sqlerrm 
				LET error_line = "Line ",p_line_number," : error ",prep_sql_code," isam error: ",prep_isam_code," at position ",sqlca.sqlerrd[5] 
				CALL error_handle.writeline(p_sql_statement) 
				CALL error_handle.writeline(error_line) 
				CALL error_handle.writeline(error_message)
				CALL glb_prp_ins_dbschema_fix_log.Execute(modu_session_start_ts,p_patch_id,p_line_number,p_sql_statement,time_stamp,"KO",prep_sql_code,prep_isam_code,glob_rec_kandoouser.sign_on_code,l_response_time)
				CALL glb_prp_ins_dbschema_fix_errors.Execute(modu_session_start_ts,p_patch_id,p_line_number,error_message)				
				RETURN  script_successed_stmt
		END CASE 
	ELSE		
		# Specific case for load and unload: they cannot be prepared 'as is'
		LET match_rslt = util.regex.search(p_sql_statement,/load from\s+"*(.*)"*\s+(insert into \w+)/im)
		# if this is a load statement
		IF match_rslt THEN
			LET reg_exp = "/\\/g"
			LET infile = match_rslt.str(1)
			LET load_stmt = match_rslt.str(2)
			--LET load_file = os.Path.join(local_patch_home_directory,infile)
			
			LET load_file = local_patch_home_directory,"/",infile
			LET load_file = util.REGEX.replace(load_file,"/\\/g","/") 
			--LET load_file = util.REGEX.replace(load_file,/\\/g,"\\/")
			WHENEVER ERROR CONTINUE
			IF os.path.exists(load_file) = false THEN
				LET load_sql_code = -2
				LET load_isam_code = -2
			ELSE
				IF p_actionrequested = "execute" THEN
					LOAD FROM load_file load_stmt
					LET l_response_time = current - time_stamp
					-- LET load_status = status
					LET load_sql_code = sqlca.sqlcode
					LET load_isam_code = sqlca.sqlerrd[2]
					
				END IF
			END IF
			WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
			CASE 
				WHEN load_sql_code = 0
					# for the load statement, we better test status ...
					LET script_successed_stmt = 1
					LET time_stamp = current
					DISPLAY "       OK",p_sql_statement
					CALL log_handle.write([time_stamp,"       OK",p_sql_statement])	
					CALL glb_prp_ins_dbschema_fix_log.Execute(modu_session_start_ts,0,p_line_number,p_sql_statement,time_stamp,"OK",0,0,glob_rec_kandoouser.sign_on_code,l_response_time)			
				WHEN load_sql_code = -2
					LET time_stamp = current
					DISPLAY "       KO: ERROR",load_sql_code,"isam error",load_isam_code,p_sql_statement
					LET script_successed_stmt = 0
					CALL log_handle.write([time_stamp,"       KO: ERROR FILE not found, isam error",load_isam_code,p_sql_statement]) 
					ERROR "Load Statement  did not work",p_sql_statement," File not found" 
					LET script_failed_stmts =  1 
					LET error_message = sqlerrmessage 
					LET error_line = "Line ",p_line_number," : error ","File not FOUND"," isam error: ",load_isam_code," at position ",sqlca.sqlerrd[5] 
					CALL error_handle.writeline(p_sql_statement) 
					CALL error_handle.writeline(error_line) 
					CALL error_handle.writeline(error_message)
					CALL glb_prp_ins_dbschema_fix_log.Execute(modu_session_start_ts,p_patch_id,p_line_number,p_sql_statement,time_stamp,"KO",-1,0,glob_rec_kandoouser.sign_on_code,l_response_time)
					CALL glb_prp_ins_dbschema_fix_errors.Execute(modu_session_start_ts,p_patch_id,p_line_number,error_message)
				WHEN load_sql_code < 0
					LET time_stamp = current
					DISPLAY "       KO: ERROR",load_sql_code,"isam error",load_isam_code,p_sql_statement
					LET script_successed_stmt = 0
					CALL log_handle.write([time_stamp,"       KO: ERROR",load_sql_code,"isam error",load_isam_code,p_sql_statement]) 
					ERROR "Load Statement  did not work",p_sql_statement,load_sql_code 
					LET script_failed_stmts =  1 
					LET error_message = util.REGEX.replace(sqlerrmessage,/\n|\s+/,/ /) --sqlca.sqlerrm 
					LET error_line = "Line ",p_line_number," : error ",load_sql_code," isam error: ",load_isam_code," at position ",sqlca.sqlerrd[5] 
					CALL error_handle.writeline(p_sql_statement) 
					CALL error_handle.writeline(error_line) 
					CALL error_handle.writeline(error_message)
					CALL glb_prp_ins_dbschema_fix_log.Execute(modu_session_start_ts,p_patch_id,p_line_number,p_sql_statement,time_stamp,"KO",sqlca.sqlcode,load_isam_code,glob_rec_kandoouser.sign_on_code,l_response_time)
					CALL glb_prp_ins_dbschema_fix_errors.Execute(modu_session_start_ts,p_patch_id,p_line_number,error_message)
			END CASE
		END IF
		
		LET match_rslt = util.regex.search(p_sql_statement,/unload to\s+(.*)\s+(SELECT .*)/im) 
		# if this is an unload statement
		IF match_rslt THEN
			LET infile = match_rslt.str(1)
			LET load_stmt = match_rslt.str(2)
			LET load_file = local_patch_home_directory,"/",infile
			IF os.Path.writable(os.Path.dirname(load_file)) = false THEN
				LET sqlca.sqlcode = -1
			ELSE
				WHENEVER SQLERROR CONTINUE
				IF p_actionrequested = "execute" THEN
					UNLOAD TO load_file load_stmt
					LET load_sql_code = sqlca.sqlcode
					LET load_isam_code = sqlca.sqlerrd[2]
					LET l_response_time = current - time_stamp
				END IF
				WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
			END IF
			CASE
				WHEN load_sql_code = 0 
					LET script_successed_stmt = 1
					DISPLAY "    OK ",p_sql_statement
					CALL glb_prp_ins_dbschema_fix_log.Execute(modu_session_start_ts,p_patch_id,p_line_number,p_sql_statement,time_stamp,"OK",0,0,glob_rec_kandoouser.sign_on_code,l_response_time)
				WHEN load_sql_code < 0
					LET script_successed_stmt = 0
					DISPLAY "    KO ",p_sql_statement
					ERROR "Load Statement  did not work",p_sql_statement,load_sql_code 
					LET script_failed_stmts =  1 
					LET error_message = util.REGEX.replace(sqlerrmessage,/\n|\s+/,/ /) 
					LET error_line = "Line ",p_line_number," : error ",load_sql_code," isam error: ",load_isam_code," at position ",sqlca.sqlerrd[5] 
					CALL error_handle.writeline(p_sql_statement) 
					CALL error_handle.writeline(error_line) 
					CALL error_handle.writeline(error_message)
					CALL glb_prp_ins_dbschema_fix_log.Execute(modu_session_start_ts,p_patch_id,p_line_number,p_sql_statement,time_stamp,"KO",-1,0,glob_rec_kandoouser.sign_on_code,l_response_time)
					CALL glb_prp_ins_dbschema_fix_errors.Execute(modu_session_start_ts,p_patch_id,p_line_number,error_message)
			END CASE
		END IF
	END IF
	#IF error_message IS NOT NULL THEN
	LET p_sql_statement = NULL 
	# Return 0 means script has errors, Return 1 means script is sucessful
	RETURN script_successed_stmt
 
END FUNCTION	#execute_this_sql_statement

FUNCTION view_new_dbpatches()
	DEFINE array_size,successful_scripts,skipped_scripts,failed_scripts,arr_elem_num INTEGER
	DEFINE status_message,specific_script_name STRING

	CALL apply_db_patch (glob_rec_dbschema_properties.dbsname,"view",".*") 
	RETURNING array_size,successful_scripts,skipped_scripts,failed_scripts
	LET status_message = "Total New Scripts ", array_size USING "###&",", Successful: ",successful_scripts USING "###&", 
	", Skipped: ",skipped_scripts USING "###&"," , Failed " ,failed_scripts USING "###&" 
	
	LET arr_elem_num = display_array_from_fky_dbschema_fix (glob_rec_dbschema_properties.dbsname,false,false)	

END FUNCTION

FUNCTION force_new_patch_execution(p_specific_script_name)
	DEFINE p_specific_script_name STRING
	DEFINE fullpath,error_filename,connection_string,dbserver_name STRING
	DEFINE exec_status SMALLINT
	DEFINE match_rslt util.match_results 
	DEFINE time_stamp DATETIME YEAR TO SECOND
	DEFINE successful_scripts,skipped_scripts,waiting_scripts,failed_scripts SMALLINT
	
	-- INPUT BY NAME p_specific_script_name
	LET fullpath = local_patch_home_directory,"/",p_specific_script_name,".sql"
	LET match_rslt = util.regex.search(fullpath,/([\w\-\.]+)\.sql/) 
	LET error_filename = errors_directory,"/",match_rslt.str(1),".err" 
	LET error_handle = base.channel.create()
	CALL error_handle.openfile(error_filename, "w") 
	LET time_stamp = current
	IF os.path.exists(fullpath) THEN 
		LET time_stamp = current
		CALL log_handle.write([time_stamp,"--------------------------------------------------------------------------------------------"])
		CALL log_handle.write([time_stamp,"database ",glob_dbsname," on ",dbserver_name," starting apply_db_patch_session ","Force a db patch"])
		CALL log_handle.write([time_stamp,p_specific_script_name])
		CALL parse_script_file ("force",fullpath,1)
		RETURNING exec_status,error_filename
	ELSE
		ERROR "This patch does not exist, please check ",fullpath
		LET exec_status = 1
	END IF
	
	IF exec_status = 0 THEN
		DISPLAY "The script has been executed successfully"
		LET successful_scripts = 1
		LET skipped_scripts = 0
		LET waiting_scripts = 0
		LET failed_scripts = 0
	ELSE
		ERROR "The script has been executed with failures"
		LET successful_scripts = 0
		LET skipped_scripts = 0
		LET waiting_scripts = 0
		LET failed_scripts = 1
	END IF
	RETURN 1,successful_scripts,skipped_scripts,waiting_scripts,failed_scripts
	
END FUNCTION



FUNCTION submit_new_db_patch()
	DISPLAY "To be implemented soon"
	# good opportunity to place a web service accessing to the kandoo_ref instance, but read only
END FUNCTION

FUNCTION read_log_file (p_fullpath,p_dbsname,p_startdate,p_enddate,p_patchname,p_tableslist) 
# Read a log file, returns a dynamic array 1 element per line 
	
	DEFINE p_fullpath STRING 
	DEFINE p_dbsname STRING
	DEFINE p_patchname STRING
	DEFINE p_startdate,p_enddate datetime year to second
	DEFINE p_tableslist STRING
	DEFINE scriptnum SMALLINT 
	DEFINE line_contents STRING 
	DEFINE logfile_handle base.channel 
	DEFINE regexp,regexp_quotes util.regex 
	DEFINE match_rslt util.match_results 
 	DEFINE l_arr_logfile_lines DYNAMIC ARRAY OF STRING
 	DEFINE line_timestamp,start_read,end_read  datetime year to second
 	DEFINE read_time INTERVAL hour to second
 	DEFINE line_number INTEGER
	DEFINE line_database STRING
	DEFINE line_servername STRING
	DEFINE line_operation STRING
	DEFINE line_patchname STRING
 	
	DEFINE i,script_stmt_number,script_successed_stmts,script_failed_stmts INTEGER 
	DEFINE adding_commit_stmt boolean 
	DEFINE error_message STRING 
	DEFINE error_filename STRING 

	DEFINE error_line STRING 

	LET logfile_handle = base.channel.create() 
	CALL logfile_handle.openfile(p_fullpath, "r") 
	IF p_startdate IS NULL THEN
		LET p_startdate = "1900-01-01 00:00:00"
	END IF
		IF p_enddate IS NULL THEN
		LET p_enddate = "3000-01-01 00:00:00"
	END IF

	LET line_number = 0 
	LET start_read = current
	--CREATE TEMP TABLE ut1_log ( timestamp datetime year to second,contents LVARCHAR(256)) WITH NO LOG
	CREATE TABLE ut1_log ( timestamp datetime year to second,contents LVARCHAR(256))
	{
	--PREPARE p_ins_ut1_log FROM "INSERT INTO ut1_log VALUES (?,?)"
	load from  p_fullpath insert into ut1_log
	
	WHILE NOT logfile_handle.iseof()
	# read the script lines
	# first check the header and take its values for further display 
		LET line_contents = logfile_handle.readline() 
		LET line_number = line_number + 1 
		IF length(line_contents clipped) = 0 THEN
		--IF util.regex.search(line_contents,/^\s*$/) THEN 
			CONTINUE WHILE 
		END IF
		LET line_timestamp = line_contents[1,19]
		IF line_timestamp < p_startdate THEN
			CONTINUE WHILE
		END IF
		IF line_timestamp > p_enddate THEN
			EXIT WHILE
		END IF
		LET line_contents = line_contents[19,256]
		EXECUTE p_ins_ut1_log USING line_timestamp,line_contents
		CONTINUE WHILE
--		LET line_contents = util.REGEX.replace(line_contents,/\n/,"") 
--		LET l_arr_logfile_lines[line_number] = line_contents
		
		# Parse file elements
		# Start of session
		# 2020-11-04 04:39:01	database	kandoodb_demo	 on	kandoo_ref_tcp	 starting apply_db_patch_session	execute	 db patches
		
		LET match_rslt = util.regex.search(line_contents,/(20\d\d\-\d\d\-\d\d\s\d\d:\d\d:\d\d)\sdatabase(\w+)\s+on\s+(\w+)\s+starting apply_db_patch_session\s+(.*)/) 
		IF (match_rslt) THEN
			LET line_timestamp = match_rslt.str(1)
			LET line_database = match_rslt.str(2)
			LET line_servername = match_rslt.str(3)
			LET line_operation = match_rslt.str(4)
--			IF line_timestamp < p_startdate THEN
--				CONTINUE WHILE
--			END IF
--			IF line_timestamp > p_enddate THEN
--				EXIT WHILE
--			END IF 
		END IF
		# Script start
		# 2020-11-04 04:44:48	20201028-qxt_menu_tables-datload.sql	starting script	
		LET match_rslt = util.regex.search(line_contents,/(20\d\d\-\d\d\-\d\d\s\d\d:\d\d:\d\d)\s+(20\d\d)(\d\d)(\d\d).*\-(\w+)\-(\w+)\.sql\s+starting script/) 
		IF (match_rslt) THEN
			LET line_timestamp = match_rslt.str(1)
			LET line_patchname = match_rslt.str(2)
		END IF
		# remove crlf
		LET line_contents = util.REGEX.replace(line_contents,/\n/,"")
		LET l_arr_logfile_lines[line_number] = line_contents
 	END WHILE
}
	LET end_read = current
	LET read_time = end_read - start_read
	RETURN l_arr_logfile_lines
 	
END FUNCTION # read_log_file
	