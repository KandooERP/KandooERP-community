# module generated by KandooERP Ffg(c)
# Generated on 2019-12-09 13:43:30
# Main template I:\Users\BeGooden-IT\git\KandooERP\KandooERP\Resources\Utilities\Perl\Ffg/templates/module/parent-form-basic.mtplt
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl"

GLOBALS 
	DEFINE glob_dbsname LIKE dbschema_properties.dbsname 
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
END GLOBALS 

DEFINE m_program CHAR(30) 

DEFINE m_dbschema_properties RECORD LIKE dbschema_properties.* 

# define type for parent table primary key 
DEFINE t_pky_dbschema_properties TYPE AS RECORD 
		dbsname LIKE dbschema_properties.dbsname # nchar(32) 
END RECORD 

# define type for form record
DEFINE t_frmschema_fix_mngr TYPE AS RECORD 
	dbsname LIKE dbschema_properties.dbsname, # nchar(48) 
	dbsvendor LIKE dbschema_properties.dbsvendor, # nchar(32) 
	snapshot_date LIKE dbschema_properties.snapshot_date, # DATE 
	last_patch_date LIKE dbschema_properties.last_patch_date, # DATE 
	last_patch_apply LIKE dbschema_properties.last_patch_apply, # DATETIME year TO second 
	build_id LIKE dbschema_properties.build_id, # nchar(32) 
	last_patch_ok_scripts LIKE dbschema_properties.last_patch_ok_scripts, # SMALLINT 
	last_patch_ko_scripts LIKE dbschema_properties.last_patch_ko_scripts # SMALLINT 
END RECORD 

# define type for table row image
DEFINE t_tbl_schema_fix_mngr TYPE AS RECORD 
	dbsname LIKE dbschema_properties.dbsname, # nchar(48) 
	dbsvendor LIKE dbschema_properties.dbsvendor, # nchar(32) 
	snapshot_date LIKE dbschema_properties.snapshot_date, # DATE 
	last_patch_date LIKE dbschema_properties.last_patch_date, # DATE 
	last_patch_apply LIKE dbschema_properties.last_patch_apply, # DATETIME year TO second 
	build_id LIKE dbschema_properties.build_id, # nchar(32) 
	last_patch_ok_scripts LIKE dbschema_properties.last_patch_ok_scripts, # SMALLINT 
	last_patch_ko_scripts LIKE dbschema_properties.last_patch_ko_scripts # SMALLINT 
END RECORD 

FUNCTION UT1_schema_fix_mngr_chl_whenever_sqlerror ()
    # this code instanciates the default sql errors handling for all the code lines below this function
    # it is a compiler preprocessor instruction. It is not necessary to execute that function
    WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
END FUNCTION

MAIN 
	DEFER interrupt 
	#@G00014

	CALL setModuleId("UT1") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_u_ut() #init utility module 

	CALL main_schema_fix_mngr_dbschema_properties() 


END MAIN 


##########################################################################
FUNCTION mc_schema_fix_mngr_sccs() 
	## definition variable sccs
	DEFINE sccs_var CHAR(70) 
	LET sccs_var="%W% %D%" 
END FUNCTION 
##########################################################################
FUNCTION main_schema_fix_mngr_dbschema_properties () 
	## this module's main function called by MAIN

	OPEN WINDOW f_dbschema_status with FORM "f_dbschema_status" 
	#		                                                                                                                         	#@G00037
	CALL menu_schema_fix_mngr_dbschema_properties() 

	CLOSE WINDOW f_dbschema_status 

END FUNCTION 


######################################################################
FUNCTION menu_schema_fix_mngr_dbschema_properties () 
	## menu_schema_fix_mngr_dbschema_properties
	## the top level menu
	## input arguments: none
	## output arguments: none
	DEFINE nbsel_dbschema_properties INTEGER 
	DEFINE sql_stmt_status INTEGER 
	DEFINE record_num INTEGER 
	DEFINE ACTION SMALLINT 
	DEFINE xnumber SMALLINT 
	DEFINE arr_elem_num SMALLINT 
	DEFINE pky_dbschema_properties t_pky_dbschema_properties 
	DEFINE frmschema_fix_mngr t_frmschema_fix_mngr 
	DEFINE tbl_schema_fix_mngr t_tbl_schema_fix_mngr 
	DEFINE record_found INTEGER 
	DEFINE lookup_status INTEGER 
	DEFINE array_size,successful_scripts,skipped_scripts,failed_scripts INTEGER
	DEFINE where_clause STRING
	DEFINE pwd_dir,temp_filename STRING

	DEFINE l_rec_properties_dummy t_tbl_schema_fix_mngr
	
	LET nbsel_dbschema_properties = 0 
--	CALL sql_prepare_queries_schema_fix_mngr_dbschema_properties () # INITIALIZE all cursors ON master TABLE 
--	CALL sql_prepare_queries_schema_fix_mngr_dbschema_fix()
{
	LET local_patch_home_directory = fgl_getenv("KANDOO_ROOTDIR"),"/Resources/database/",frmschema_fix_mngr.dbsvendor CLIPPED,"/schema_change_scripts"
	CALL util.REGEX.replace(local_patch_home_directory,/\\/g,"/") returning local_patch_home_directory
	IF NOT os.path.exists(local_patch_home_directory) THEN
		ERROR "Cannot find the Directory where db patches are stored, please check KANDOO_ROOTDIR env variable",local_patch_home_directory
		SLEEP 5
		EXIT PROGRAM
	END IF
}
	LET log_filename = os.Path.pwd(),"/",fgl_getenv("KANDOO_LOG_PATH"),"/UT1_schema_fix_mngr.log" 
	LET log_filename = util.REGEX.replace(log_filename,/\\/g,"/")
	LET log_handle = base.channel.create()
	CALL log_handle.openfile(log_filename, "a") 
	CALL log_handle.setDelimiter("	")
	 
	MENU "dbschema_properties" 
		BEFORE MENU 
			HIDE OPTION "Next","Previous","EDIT","DELETE","History of DB Patches (View)","Query DB Patch History","New DB Patches (View)","Apply DBPatches",
			"Submit New DB Patch"," DBPatches","CompareDBPatches"
			
		COMMAND "Connect to Database" "Connect to your Kandoo Database" 
			#@G00075
			MESSAGE "" 
			INITIALIZE frmschema_fix_mngr.* TO NULL 
			CLEAR FORM 
			DISPLAY BY NAME frmschema_fix_mngr.* 
			HIDE option "Next","Previous" 
			LET user_is_dba = false

			CALL frm_qbe_dbschema_properties() RETURNING where_clause
			IF where_clause IS NULL THEN
				EXIT MENU
			END IF
			--LET xnumber = sql_get_qbe_count_dbschema_properties(where_clause)  
			CALL sql_opn_pky_scr_curs_dbschema_properties(where_clause) RETURNING nbsel_dbschema_properties,sql_stmt_status
			
			IF nbsel_dbschema_properties > 0 THEN
				SHOW OPTION "History of DB Patches (View)","Query DB Patch History","New DB Patches (View)","Apply DBPatches"," DBPatches","CompareDBPatches"
				CALL sql_nxtprev_dbschema_properties(1) RETURNING record_found, 
				pky_dbschema_properties.* 
				LET glob_dbsname =  pky_dbschema_properties.dbsname
				CASE 
					WHEN record_found = 1 
						LET record_num = 1 
						CALL sql_fetch_full_row_dbschema_properties (pky_dbschema_properties.*) 
						RETURNING record_found,frmschema_fix_mngr.* 

						# set the local patch home directory
						LET local_patch_home_directory = fgl_getenv("KANDOO_ROOTDIR"),"/Resources/database/",frmschema_fix_mngr.dbsvendor CLIPPED,"/schema_change_scripts"
						CALL util.REGEX.replace(local_patch_home_directory,/\\/g,"/") returning local_patch_home_directory
						IF NOT os.path.exists(local_patch_home_directory) THEN
							ERROR "Cannot find the Directory where db patches are stored, please check KANDOO_ROOTDIR env variable",local_patch_home_directory
							SLEEP 5
							EXIT PROGRAM
						END IF
						CALL frm_display_schema_fix_mngr(frmschema_fix_mngr.*)  
						
						# Check the last backup, because it is safer to run apply_db_patch with a backup
						SELECT max(dbinfo("utc_to_datetime",level0)) 
						INTO last_valid_backup 
						FROM sysmaster:sysdbstab 
						WHERE NAME NOT matches "*temp*" 
					
						PREPARE p_get_hostname FROM "SELECT dbinfo('dbhostname') from systables where tabid = 1" 
						DECLARE c_get_hostname CURSOR FOR p_get_hostname 
						OPEN c_get_hostname 
						FETCH c_get_hostname INTO host_name 
					
						DISPLAY BY NAME last_valid_backup,host_name,dbserver_name 
						LET errors_directory = "C:\\temp" 

						CALL initialize_array_dbschema_fix() 
						LET arr_elem_num = display_array_from_fky_dbschema_fix (pky_dbschema_properties.*,true,true) 
						SHOW option "History of DB Patches (View)","New DB Patches (View)","Apply New DB Patches" 
						#@G00097
					WHEN record_found = -1 
						ERROR "This row is unreachable ",sqlca.sqlcode 
				END CASE 
				IF nbsel_dbschema_properties > 1 THEN 
					SHOW option "Next" 
					NEXT option "Next" 
				END IF 
				SHOW option "EDIT","DELETE" 
			ELSE 
				ERROR "No row matches the criteria" 
				NEXT option "Query" 
			END IF 

			--COMMAND KEY (tab) "History of DB Patches (View)"
			-- CALL display_array_from_fky_dbschema_fix (pky_dbschema_properties.*,True)
			-- COMMAND KEY (shift-tab) "Edit Array dbschema_fix"
			--		CALL frm_edit_array_dbschema_fix (pky_dbschema_properties.*,True)
			#@G00111
		COMMAND "Next" "Display Next record dbschema_properties" 
			#@G00113
			MESSAGE "" 
			CLEAR FORM 
			INITIALIZE frmschema_fix_mngr.* TO NULL 

			IF record_num <= nbsel_dbschema_properties THEN 
				CALL sql_nxtprev_dbschema_properties(1) RETURNING record_found, 
				pky_dbschema_properties.* 


				CASE 
					WHEN record_found = 0 
						ERROR "fetch Last record of this selection dbschema_properties" 
					WHEN record_found = -1 
						ERROR "This row is unreachable ",sqlca.sqlcode 
					WHEN record_found = 1 
						LET record_num = record_num + 1 
						CALL sql_fetch_full_row_dbschema_properties (pky_dbschema_properties.*) 
						RETURNING record_found,frmschema_fix_mngr.* 


						CALL frm_display_schema_fix_mngr(frmschema_fix_mngr.*) 
						CALL initialize_array_dbschema_fix() 
						LET arr_elem_num = display_array_from_fky_dbschema_fix (pky_dbschema_properties.*,true,true) 
						SHOW option "History of DB Patches (View)","New DB Patches (View)","Apply New DB Patches"
						#@G00135


						IF record_num >= nbsel_dbschema_properties THEN 
							HIDE option "Next" 
						END IF 
						IF record_num > 1 THEN 
							SHOW option "Previous" 
						ELSE 
							HIDE option "Previous" 
						END IF 
				END CASE 
			ELSE 
				ERROR " Please set query criteria previously dbschema_properties " 
				NEXT option "Query" 
			END IF 
			--		COMMAND KEY (tab) "History of DB Patches (View)"
			--			CALL display_array_from_fky_dbschema_fix (pky_dbschema_properties.*,True)
			--		COMMAND KEY (shift-tab) "Edit Array dbschema_fix"
			--			CALL frm_edit_array_dbschema_fix (pky_dbschema_properties.*,True)
			#@G00151

		COMMAND "Previous" "Display Previous Record dbschema_properties" 
			MESSAGE "" 
			CLEAR FORM 
			INITIALIZE frmschema_fix_mngr.* TO NULL 

			IF record_num >= 1 THEN 
				CALL sql_nxtprev_dbschema_properties(-1) RETURNING record_found, 
				pky_dbschema_properties.* 
				CASE 
					WHEN record_found = 0 
						ERROR "fetch First record of this selection dbschema_properties" 
					WHEN record_found < -1 
						ERROR "This row is unreachable ",sqlca.sqlcode 
					WHEN record_found = 1 
						LET record_num = record_num - 1 
						CALL sql_fetch_full_row_dbschema_properties (pky_dbschema_properties.*) 
						RETURNING record_found,frmschema_fix_mngr.* 

						CALL frm_display_schema_fix_mngr(frmschema_fix_mngr.*) 
						CALL initialize_array_dbschema_fix() 
						LET arr_elem_num = display_array_from_fky_dbschema_fix (pky_dbschema_properties.*,true,true) 
						SHOW option "History of DB Patches (View)","Edit Array dbschema_fix" 
						#@G00175
						IF record_num = 1 THEN 
							HIDE option "Previous" 
						END IF 
						IF record_num < nbsel_dbschema_properties THEN 
							SHOW option "Next" 
						ELSE 
							HIDE option "Next" 
						END IF 
				END CASE 
			ELSE 
				ERROR " Please set query criteria previously dbschema_properties " 
				NEXT option "Query" 
			END IF 

		COMMAND "History of DB Patches (View)" "View the history of applied and checked db patches for this database" 
			CALL display_array_from_fky_dbschema_fix (pky_dbschema_properties.*,true,false)
			
		COMMAND "Query DB Patch History" "Query the history of applied and checked db patches" 
			CALL frm_qbe_dbschema_fix () RETURNING where_clause
			CALL sql_open_array_crs_qbe_arraydbschema_fix(where_clause)
			CALL display_array_from_qbe_dbschema_fix (where_clause,true,false)  

		--COMMAND "Edit DB Patch History" "Edit the history of applied and checked db patches" 
			-- CALL frm_edit_array_dbschema_fix (pky_dbschema_properties.*,true) 

		COMMAND "New DB Patches (View)" "Display patches created after last application"
			CALL initialize_array_dbschema_fix()
			CALL view_new_dbpatches()
		
		COMMAND "Submit New DB Patch" "Create and submit a new database patch to Kandoo DB Architects "
			CALL submit_new_db_patch()

		COMMAND "CompareDBPatches"
			CALL initialize_array_dbschema_fix()
			CALL diff_with_reference_database()
			
		COMMAND "Apply DBPatches" "Check New patches to be applied or apply the new patches" 
			CALL apply_db_patch_main (pky_dbschema_properties.*) 
			# LET arr_elem_num = display_array_from_fky_dbschema_fix (pky_dbschema_properties.*,False)

		COMMAND "Exit" "Exit program" 
			#@G00237
			MESSAGE "" 
			EXIT MENU 
	END MENU 
	CALL log_handle.close()
END FUNCTION 

#######################################################################
FUNCTION frm_qbe_dbschema_properties() 
	## frm_qbe_dbschema_properties_f_dbschema_status : Query By Example on table dbschema_properties
	## Input selection criteria,
	## prepare the query,
	## open the data set
	DEFINE rec_dbschema_properties,where_clause,temp_where_clause STRING 
	DEFINE connection_string STRING 
	DEFINE xnumber,sql_stmt_status INTEGER 
	DEFINE l_pky t_pky_dbschema_properties 
	DEFINE frmschema_fix_mngr t_frmschema_fix_mngr 
	DEFINE reply CHAR(5) 
	DEFINE match util.match_results
	DEFINE user_name,passwd CHAR(32) 

	LET xnumber = 0 
	MESSAGE "Please input query criteria" 
	# initialize record and display blank
	CLEAR FORM 
	INITIALIZE frmschema_fix_mngr.* TO NULL 
	DISPLAY BY NAME frmschema_fix_mngr.* 

	OPTIONS INPUT NO WRAP 
	INPUT BY NAME frmschema_fix_mngr.dbsname,user_name,passwd
		BEFORE INPUT
			CALL dialog.setActionHidden("ACCEPT","TRUE")
			CALL dialog.setActionHidden("CANCEL","TRUE")
			
		AFTER FIELD dbsname
			IF frmschema_fix_mngr.dbsname IS NULL THEN
				NEXT FIELD dbsname
			ELSE 
				IF frmschema_fix_mngr.dbsname NOT MATCHES "*@*" THEN
					# this database is not sitting in another INFORMIXSERVER 
					LET dbserver_name = establish_db_connection(frmschema_fix_mngr.dbsname,"","")
					ACCEPT INPUT
				END IF
			END IF
		AFTER FIELD passwd
			IF user_name IS NOT NULL AND passwd IS NOT NULL THEN
				LET dbserver_name = establish_db_connection(frmschema_fix_mngr.dbsname,user_name clipped,passwd clipped)
				IF dbserver_name IS NOT NULL THEN
					# check database permissions of this user: if user is "D" (dba), he can perform ut1 dba operations (force etc ...)
					CALL sql_prepare_queries_schema_fix_mngr_dbschema_properties () # INITIALIZE all cursors ON master TABLE 
					CALL sql_prepare_queries_schema_fix_mngr_dbschema_fix()
					SELECT 1 INTO xnumber
					FROM sysusers
					WHERE username = user_name
					AND usertype = "D"
					IF sqlca.sqlcode = 0 THEN
						LET user_is_dba = true
					ELSE
						LET user_is_dba = false
					END IF
				ELSE
					ERROR "Cannot connect: wrong user or password"
					NEXT FIELD dbsname
				END IF
			ELSE
				NEXT FIELD dbsname
			END IF
				
		AFTER INPUT 
			IF dbserver_name IS NULL THEN
				CALL fgl_winmessage("Database cannot be opened, please check db name and INFORMIXSERVER",frmschema_fix_mngr.dbsname,"error")
				NEXT FIELD  dbsname
			END IF
			LET where_clause = "dbsname = ",ascii(34),frmschema_fix_mngr.dbsname CLIPPED,ascii(34) 
	END INPUT 

	# remove the @ part of the dbs name
	LET temp_where_clause = where_clause 
	LET where_clause = util.REGEX.replace(temp_where_clause,/@\w+/,"") 
	IF int_flag = true THEN 
		MESSAGE "Quit with quit key" 
		LET int_flag=0 
		RETURN NULL
	ELSE 
		RETURN where_clause
	END IF 
	RETURN where_clause 
END FUNCTION ## frm_qbe_dbschema_properties 


#######################################################################
# frm_Display_schema_fix_mngr_f_dbschema_status : displays the form record after reading and displays lookup records if any
# inbound: Form record.*
FUNCTION frm_display_schema_fix_mngr(frmschema_fix_mngr) 
	DEFINE frmschema_fix_mngr t_frmschema_fix_mngr 
	DEFINE script_file,log_file STRING 


	#@G00306
	DISPLAY BY NAME frmschema_fix_mngr.* 
	#@G00309


END FUNCTION # frm_display_schema_fix_mngr_f_dbschema_status 

####################################################################
## frm_Insert_schema_fix_mngr_f_dbschema_status: add a new dbschema_properties row
FUNCTION frm_insert_schema_fix_mngr() 
	DEFINE sql_stmt_status SMALLINT 
	DEFINE rows_count SMALLINT 
	DEFINE nbre_dbschema_properties ,action SMALLINT 
	DEFINE frmschema_fix_mngr t_frmschema_fix_mngr 
	DEFINE tbl_schema_fix_mngr t_tbl_schema_fix_mngr 

	CLEAR FORM 
	INITIALIZE frmschema_fix_mngr.* TO NULL 

	WHILE true 
		LET int_flag = false 
		INPUT BY NAME frmschema_fix_mngr.dbsname, 
		frmschema_fix_mngr.last_patch_ok_scripts, 
		frmschema_fix_mngr.last_patch_ko_scripts 

		#@G00334
		WITHOUT DEFAULTS 
		#@G00335


		#@G00336
		#@G00336
		END INPUT 
		IF int_flag = true THEN 
			# Resign from input
			LET int_flag=false 
			DISPLAY BY NAME frmschema_fix_mngr.* 
			MESSAGE "Quit with quit key Control-C" 
			EXIT WHILE 
		END IF 


		CALL confirm_operation(3,10,"Insert") RETURNING ACTION 
		CASE ACTION 
			WHEN 0 # i want TO edit the input, remains displayed 'as is' 
				CONTINUE WHILE # ON laisse tout affiche comme tel 

			WHEN 2 # ON valide la transaction 
				BEGIN WORK 
					#@G00352
					CALL set_table_record_f_dbschema_status_dbschema_properties('+',frmschema_fix_mngr.*) 
					RETURNING tbl_schema_fix_mngr.* 
					CALL sql_insert_dbschema_properties(tbl_schema_fix_mngr.*) 
					RETURNING sql_stmt_status, tbl_schema_fix_mngr.dbsname 
					#@G00356

					CASE 
						WHEN sql_stmt_status = 0 
							MESSAGE "Insert dbschema_properties Successful operation" 
				COMMIT WORK 
						#@G00361
						WHEN sql_stmt_status < 0  
							CALL display_error_and_decide("Insert dbschema_properties:failed",sqlerrmessage,"") 
				ROLLBACK WORK 

					END CASE 
					EXIT WHILE 

			WHEN 0 
				ROLLBACK WORK 
				#@G00369
				EXIT WHILE 
		END CASE 
	END WHILE 
	# tbl_schema_fix_mngr
	RETURN sql_stmt_status, tbl_schema_fix_mngr.dbsname 
	#@G00374
END FUNCTION ## frm_insert_schema_fix_mngr_f_dbschema_status 

#######################################################################
# frm_Edit_schema_fix_mngr_f_dbschema_status : Edit a dbschema_properties RECORD
# inbound: table primary key
FUNCTION frm_edit_schema_fix_mngr(pky,frmschema_fix_mngr) 
	DEFINE ACTION SMALLINT 
	DEFINE sql_stmt_status,dummy SMALLINT 

	DEFINE tbl_schema_fix_mngr t_tbl_schema_fix_mngr 
	DEFINE frmschema_fix_mngr t_frmschema_fix_mngr 
	DEFINE savschema_fix_mngr t_frmschema_fix_mngr 
 
	#@G00395
	DEFINE rows_count SMALLINT 
	DEFINE pky t_pky_dbschema_properties 

	## check if record can be accessed
	WHILE true 
		LET int_flag = false 
		# Save Screen Record values before altering
		LET savschema_fix_mngr.* = frmschema_fix_mngr.* 
		BEGIN WORK 
			EXECUTE immediate "SET ISOLATION TO COMMITTED READ RETAIN UPDATE LOCKS" 
			WHENEVER SQLERROR CONTINUE 
			OPEN crs_upd_dbschema_properties USING pky.* 
			FETCH crs_upd_dbschema_properties INTO dummy 
			IF sqlca.sqlcode = -244 THEN ERROR "THIS ROW IS BEING MODIFIED" 
				ROLLBACK WORK EXIT WHILE END IF 
				WHENEVER SQLERROR stop 
				#@G00413
				INPUT BY NAME frmschema_fix_mngr.dbsname, 
				frmschema_fix_mngr.last_patch_ok_scripts, 
				frmschema_fix_mngr.last_patch_ko_scripts 

				#@G00414
				WITHOUT DEFAULTS 
				#@G00415


				#@G00416


				#@G00417
				END INPUT 
				IF int_flag = true THEN 
					LET int_flag=false 
					# Restore previous value
					LET frmschema_fix_mngr.* = savschema_fix_mngr.* 
					DISPLAY BY NAME frmschema_fix_mngr.* 
					#@G00423
					EXECUTE immediate "SET ISOLATION TO COMMITTED READ" 
					ROLLBACK WORK 
					MESSAGE "$CancelCom Control-C" 
					EXIT WHILE 
				END IF 


				CALL confirm_operation(4,10,MODE_CLASSIC_EDIT) RETURNING ACTION 


				CASE 
					WHEN ACTION = 0 
						# Redo, leave values as modified
						CONTINUE WHILE 
					WHEN ACTION = 1 
						# Resign, restore original values
						LET frmschema_fix_mngr.* = savschema_fix_mngr.* 
						DISPLAY BY NAME frmschema_fix_mngr.* 
						EXECUTE immediate "SET ISOLATION TO COMMITTED READ" 
						ROLLBACK WORK 
						EXIT WHILE # CANCEL operation 


					WHEN ACTION = 2 
						# confirm update
						CALL set_table_record_f_dbschema_status_dbschema_properties("#",frmschema_fix_mngr.*) 
						RETURNING tbl_schema_fix_mngr.* 


						# Perform the prepared update statement
						LET sql_stmt_status = sql_edit_dbschema_properties(pky.*,tbl_schema_fix_mngr.*) 
						CASE 
							WHEN sql_stmt_status = 0 
								MESSAGE "Edit dbschema_properties Successful operation" 
								EXECUTE immediate "SET ISOLATION TO COMMITTED READ" 
							COMMIT WORK 
							#@G00455
							WHEN sql_stmt_status < 0  
								CALL display_error_and_decide("Update dbschema_properties:failed",sqlerrmessage,"")
								EXECUTE immediate "SET ISOLATION TO COMMITTED READ" 
								ROLLBACK WORK 
								#@G00459
						END CASE 
						EXIT WHILE 
				END CASE 
			END WHILE 
			RETURN sql_stmt_status 
END FUNCTION ## frm_edit_schema_fix_mngr(pky) 




#######################################################################
# DELETE A dbschema_properties row
# inbound: table primary key
FUNCTION frm_delete_schema_fix_mngr(pky) 
	DEFINE ACTION SMALLINT 
	DEFINE dummy SMALLINT 
	DEFINE sql_stmt_status SMALLINT 
	DEFINE pky t_pky_dbschema_properties 

	WHILE true 
		CALL confirm_operation(5,10,"Delete") RETURNING ACTION 
		BEGIN WORK 
			EXECUTE immediate "SET ISOLATION TO COMMITTED READ RETAIN UPDATE LOCKS" 
			WHENEVER SQLERROR CONTINUE 
			OPEN crs_upd_dbschema_properties USING pky.* 
			FETCH crs_upd_dbschema_properties INTO dummy 
			IF sqlca.sqlcode = -244 THEN ERROR "THIS ROW IS BEING MODIFIED" 
				ROLLBACK WORK EXIT WHILE END IF 
				WHENEVER SQLERROR stop 
				#@G00488
				CASE 
					WHEN ACTION = 0 OR ACTION = 1 
						# can the delete operation
						EXIT WHILE 
					WHEN ACTION = 2 
						# Validate the delete operation
						CALL sql_delete_dbschema_properties(pky.*) RETURNING sql_stmt_status 
						CASE 
							WHEN sql_stmt_status = 0 
								MESSAGE "Delete dbschema_properties Successful operation" 
							COMMIT WORK 
							#@G00499


							WHEN sql_stmt_status < 0  
								CALL display_error_and_decide("Delete dbschema_properties:failed",sqlerrmessage,"")
								
								ROLLBACK WORK 
								#@G00503
						END CASE 
						EXIT WHILE 
				END CASE 
			END WHILE 
			RETURN sql_stmt_status 
END FUNCTION ## frm_delete_schema_fix_mngr(pky) 


#########################################################################
#  Build, prepare, declare and initialize main queries and cursors
FUNCTION sql_prepare_queries_schema_fix_mngr_dbschema_properties () 
	DEFINE query_text STRING 


	# PREPARE cursor for full master table row contents, access by primary key
	LET query_text= 
	"SELECT dbsname,dbsvendor,snapshot_date,last_patch_date,last_patch_apply,build_id,last_patch_ok_scripts,last_patch_ko_scripts ", #@g00518 
	" FROM dbschema_properties ", 
	"WHERE dbsname = ? " #@g00520 


	PREPARE sel_mrw_dbschema_properties FROM query_text 
	DECLARE crs_row_dbschema_properties CURSOR FOR sel_mrw_dbschema_properties 

	# PREPARE cursor for row test / check if locked
	LET query_text= "SELECT dbsname 
	", #@G00526 
	" FROM dbschema_properties ", 
	" WHERE dbsname = ? " #@g00528 


	PREPARE sel_pky_dbschema_properties FROM query_text 
	DECLARE crs_pky_dbschema_properties CURSOR FOR sel_pky_dbschema_properties 


	# PREPARE cursor for SELECT FOR UPDATE
	LET query_text= "SELECT dbsname 
	", #@G00534 
	" FROM dbschema_properties ", 
	" WHERE dbsname = ? ", #@g00536 
	" FOR UPDATE" 


	PREPARE sel_upd_dbschema_properties FROM query_text 
	DECLARE crs_upd_dbschema_properties CURSOR FOR sel_upd_dbschema_properties 


	# PREPARE INSERT statement
	LET query_text = 
	"INSERT INTO dbschema_properties ( dbsname,dbsvendor,snapshot_date,last_patch_date,last_patch_apply,build_id,last_patch_ok_scripts,last_patch_ko_scripts 
	)", #@G00544 
	" VALUES ( ?,?,?,?,?,?,?,? 
	)" #@G00545 
	PREPARE pr_ins_dbschema_properties FROM query_text 


	# PREPARE UPDATE statement
	LET query_text= 
	"UPDATE dbschema_properties ", 
	"SET ( dbsvendor,snapshot_date,last_patch_date,last_patch_apply,build_id,last_patch_ok_scripts,last_patch_ko_scripts 
	)", #@G00551 
	" = ( ?,?,?,?,?,?,? 
	)", #@G00552 
	" WHERE dbsname = ? " #@g00553 
	PREPARE pr_upd_dbschema_properties FROM query_text 


	# PREPARE DELETE statement
	LET query_text= "DELETE FROM dbschema_properties ", 
	" WHERE dbsname = ? " #@g00558 


	PREPARE pr_del_dbschema_properties FROM query_text 


END FUNCTION ## sql_prepare_queries_schema_fix_mngr_dbschema_properties 

#########################################################
FUNCTION sql_opn_pky_scr_curs_dbschema_properties(where_clause) 
	## Build the query generated by CONSTRUCT BY NAME,
	# First count the records matching where_clause criteria then
	## Declare and open the cursor
	## inbound param: query predicate
	## outbound parameters: records number and query status
	DEFINE where_clause STRING 
	DEFINE sql_stmt STRING 
	DEFINE rows_count INTEGER 
	DEFINE lsql_stmt_status INTEGER 
	# define primary_key record
	DEFINE l_pky t_pky_dbschema_properties 
	# First count rows matching criteria
	LET sql_stmt = 
	"SELECT count(*) FROM dbschema_properties", 
	" WHERE ",where_clause clipped 

	PREPARE prp_cnt_dbschema_properties FROM sql_stmt 
	DECLARE crs_cnt_dbschema_properties CURSOR FOR prp_cnt_dbschema_properties 

	OPEN crs_cnt_dbschema_properties 
	SET ISOLATION TO dirty read 
	WHENEVER SQLERROR CONTINUE 
	FETCH crs_cnt_dbschema_properties INTO rows_count 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 
	SET ISOLATION TO committed read 

	# if FETCH fails, count = 0, the, get back to query
	IF sqlca.sqlcode OR rows_count = 0 THEN 
		LET rows_count =0 
	ELSE
		# prepare and declare the scroll cursor on primary key
		LET sql_stmt = "SELECT dbsname ",
		" FROM dbschema_properties ", 
		"WHERE ",where_clause clipped, 
		" ORDER BY dbsname " 
	
		PREPARE p_fetch_dbschema_properties FROM sql_stmt 
		# crs_scrl_pky_dbschema_properties  : the first cursor selects all the primary keys (not all the table columns)
		DECLARE crs_scrl_pky_dbschema_properties SCROLL CURSOR with HOLD 
		FOR p_fetch_dbschema_properties #@g00633 
	
		WHENEVER SQLERROR CONTINUE 
		OPEN crs_scrl_pky_dbschema_properties  
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	END IF 

	RETURN rows_count,sqlca.sqlcode 
END FUNCTION ## sql_opn_pky_scr_curs_dbschema_properties 


#######################################################################
FUNCTION sql_nxtprev_dbschema_properties(offset) 
	## sql_nxtprev_dbschema_properties : FETCH NEXT OR PREVIOUS RECORD
	DEFINE offset SMALLINT 
	DEFINE lsql_stmt_status,record_found INTEGER 
	DEFINE pky t_pky_dbschema_properties 
	DEFINE frmschema_fix_mngr t_frmschema_fix_mngr 

	WHENEVER SQLERROR CONTINUE 
	FETCH relative offset crs_scrl_pky_dbschema_properties  INTO pky.* 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 


	CASE 
		WHEN sqlca.sqlcode = 100 
			LET record_found = 0 


		WHEN sqlca.sqlcode < 0 
			LET record_found = -1 
		OTHERWISE 
			LET lsql_stmt_status = 1 
			LET record_found = 1 
			#CALL sql_fetch_full_row_dbschema_properties (pky.*)
			#RETURNING record_found,frmschema_fix_mngr.*


	END CASE 
	RETURN record_found,pky.* 
END FUNCTION ## sql_nxtprev_dbschema_properties 


#########################################################################################
FUNCTION sql_fetch_full_row_dbschema_properties(pky_dbschema_properties) 
	# sql_fetch_full_row_dbschema_properties : read a complete row accessing by primary key
	# inbound parameter : primary key
	# outbound parameter: sql_stmt_status and row contents
	DEFINE sql_stmt_status SMALLINT 
	DEFINE pky_dbschema_properties t_pky_dbschema_properties 
	DEFINE tbl_schema_fix_mngr t_tbl_schema_fix_mngr 
	DEFINE frmschema_fix_mngr t_frmschema_fix_mngr 

	# read the table, access on primary key
	# WHENEVER SQLERROR CONTINUE
	OPEN crs_row_dbschema_properties 
	USING pky_dbschema_properties.* 


	FETCH crs_row_dbschema_properties INTO tbl_schema_fix_mngr.* 

	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 
	CASE 
		WHEN sqlca.sqlcode = 100 
			LET sql_stmt_status = 0 
		WHEN sqlca.sqlcode < 0 
			LET sql_stmt_status = -1 
		OTHERWISE 
			LET sql_stmt_status = 1 
			LET glob_rec_dbschema_properties.* = tbl_schema_fix_mngr.* 
			# DISPLAY glob_rec_dbschema_properties.*
			CALL set_form_record_schema_fix_mngr(tbl_schema_fix_mngr.*) 
			RETURNING frmschema_fix_mngr.* 
			LET glob_rec_dbschema_properties.* = tbl_schema_fix_mngr.* 
	END CASE 
	RETURN sql_stmt_status,frmschema_fix_mngr.* 
END FUNCTION ## sql_fetch_full_row_dbschema_properties 


########################################################################
FUNCTION sql_insert_dbschema_properties(tbl_schema_fix_mngr) 
	## INSERT in table dbschema_properties
	DEFINE lsql_stmt_status INTEGER 
	DEFINE rows_count SMALLINT 
	DEFINE pky t_pky_dbschema_properties 
	DEFINE tbl_schema_fix_mngr t_tbl_schema_fix_mngr 
	WHENEVER SQLERROR CONTINUE 
	EXECUTE pr_ins_dbschema_properties 
	USING tbl_schema_fix_mngr.dbsname, 
	tbl_schema_fix_mngr.dbsvendor, 
	tbl_schema_fix_mngr.snapshot_date, 
	tbl_schema_fix_mngr.last_patch_date, 
	tbl_schema_fix_mngr.last_patch_apply, 
	tbl_schema_fix_mngr.build_id, 
	tbl_schema_fix_mngr.last_patch_ok_scripts, 
	tbl_schema_fix_mngr.last_patch_ko_scripts 
	#@G00725
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 


	IF sqlca.sqlcode < 0 THEN 
		LET lsql_stmt_status = -1 
	ELSE 
		LET lsql_stmt_status = 0 
		#@G00732


	END IF 
	RETURN lsql_stmt_status,pky.* 
END FUNCTION ## sql_insert_dbschema_properties 


########################################################################
FUNCTION sql_edit_dbschema_properties(pky,tbl_schema_fix_mngr) 
	## sql_Edit_dbschema_properties :update dbschema_properties record
	DEFINE lsql_stmt_status INTEGER 
	DEFINE pky t_pky_dbschema_properties 
	DEFINE tbl_schema_fix_mngr t_tbl_schema_fix_mngr 

	WHENEVER SQLERROR CONTINUE 
	EXECUTE pr_upd_dbschema_properties 
	USING tbl_schema_fix_mngr.dbsvendor, 
	tbl_schema_fix_mngr.snapshot_date, 
	tbl_schema_fix_mngr.last_patch_date, 
	tbl_schema_fix_mngr.last_patch_apply, 
	tbl_schema_fix_mngr.build_id, 
	tbl_schema_fix_mngr.last_patch_ok_scripts, 
	tbl_schema_fix_mngr.last_patch_ko_scripts 
	, #@g00751 
	pky.* 


	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 
	IF sqlca.sqlcode < 0 THEN 


		LET lsql_stmt_status = -1 
	ELSE 
		LET lsql_stmt_status = 0 
	END IF 
	RETURN lsql_stmt_status 
END FUNCTION ## sql_edit_dbschema_properties 


##############################################################################################
FUNCTION sql_delete_dbschema_properties(pky) 
	## sql_Delete_dbschema_properties :delete current row in table dbschema_properties
	DEFINE lsql_stmt_status SMALLINT 
	DEFINE pky t_pky_dbschema_properties 

	WHENEVER SQLERROR CONTINUE 
	EXECUTE pr_del_dbschema_properties 
	USING pky.* 


	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 
	IF sqlca.sqlcode < 0 THEN 
		LET lsql_stmt_status = -1 
	ELSE 
		LET lsql_stmt_status=0 
	END IF 
	RETURN lsql_stmt_status 
END FUNCTION ## sql_delete_dbschema_properties 


################################################################################
FUNCTION sql_status_pk_dbschema_properties(pky) 
	##   sql_status_pk_dbschema_properties : Check if primary key exists
	## inbound parameter : record of primary key
	## outbound parameter:  status > 0 if exists, 0 if no record, < 0 if error
	DEFINE pky t_pky_dbschema_properties 
	DEFINE pk_status INTEGER 


	WHENEVER SQLERROR CONTINUE 
	OPEN crs_pky_dbschema_properties USING pky.* 
	FETCH crs_pky_dbschema_properties 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 


	CASE sqlca.sqlcode 
		WHEN 0 
			LET pk_status = 1 
		WHEN 100 
			LET pk_status = 0 
		WHEN sqlca.sqlerrd[2] = 104 
			LET pk_status = -1 # RECORD locked 
		WHEN sqlca.sqlcode < 0 
			LET pk_status = sqlca.sqlcode 
	END CASE 


	RETURN pk_status 
END FUNCTION ## sql_status_pk_dbschema_properties 


################################################################################################
FUNCTION set_form_record_schema_fix_mngr(tbl_contents) 
	## set_form_record_schema_fix_mngr_f_dbschema_status: assigns table values to form fields values
	DEFINE frm_contents t_frmschema_fix_mngr 
	DEFINE tbl_contents t_tbl_schema_fix_mngr 

	INITIALIZE frm_contents.* TO NULL 
	LET frm_contents.dbsname = tbl_contents.dbsname 
	LET frm_contents.dbsvendor = tbl_contents.dbsvendor 
	LET frm_contents.snapshot_date = tbl_contents.snapshot_date 
	LET frm_contents.last_patch_date = tbl_contents.last_patch_date 
	LET frm_contents.last_patch_apply = tbl_contents.last_patch_apply 
	LET frm_contents.build_id = tbl_contents.build_id 
	LET frm_contents.last_patch_ok_scripts = tbl_contents.last_patch_ok_scripts 
	LET frm_contents.last_patch_ko_scripts = tbl_contents.last_patch_ko_scripts 
	#@G00834
	RETURN frm_contents.* 
END FUNCTION ## set_form_recordschema_fix_mngr_f_dbschema_status 


################################################################################################
FUNCTION set_table_record_f_dbschema_status_dbschema_properties(sql_stmt,frm_contents) 
	## set_table_record_f_dbschema_status_dbschema_properties: assigns form fields value to table values
	DEFINE sql_stmt SMALLINT # + => insert, # => UPDATE 
	DEFINE pky t_pky_dbschema_properties 
	DEFINE frm_contents t_frmschema_fix_mngr 
	DEFINE tbl_contents t_tbl_schema_fix_mngr 


	INITIALIZE tbl_contents.* TO NULL 
	CASE sql_stmt 
		WHEN "+" # PREPARE RECORD FOR INSERT 
			LET tbl_contents.dbsname = frm_contents.dbsname 
			-- LET tbl_contents.dbsvendor = YOUR VALUE
			-- LET tbl_contents.snapshot_date = YOUR VALUE
			-- LET tbl_contents.last_patch_date = YOUR VALUE
			-- LET tbl_contents.last_patch_apply = YOUR VALUE
			-- LET tbl_contents.build_id = YOUR VALUE
			LET tbl_contents.last_patch_ok_scripts = frm_contents.last_patch_ok_scripts 
			LET tbl_contents.last_patch_ko_scripts = frm_contents.last_patch_ko_scripts 
			#@G00865
		WHEN "#" # PREPARE RECORD FOR UPDATE 
			LET tbl_contents.dbsname = frm_contents.dbsname 
			-- LET tbl_contents.dbsvendor = YOUR VALUE
			-- LET tbl_contents.snapshot_date = YOUR VALUE
			-- LET tbl_contents.last_patch_date = YOUR VALUE
			-- LET tbl_contents.last_patch_apply = YOUR VALUE
			-- LET tbl_contents.build_id = YOUR VALUE
			LET tbl_contents.last_patch_ok_scripts = frm_contents.last_patch_ok_scripts 
			LET tbl_contents.last_patch_ko_scripts = frm_contents.last_patch_ko_scripts 
			#@G00875
	END CASE 


	RETURN tbl_contents.* 
END FUNCTION ## set_table_recordf_dbschema_status_dbschema_properties 

FUNCTION fetch_and_display_dbschema_properties (pky)
	DEFINE pky t_pky_dbschema_properties
	DEFINE record_found SMALLINT
	DEFINE frmschema_fix_mngr t_frmschema_fix_mngr 

	CALL sql_fetch_full_row_dbschema_properties (pky.*) 
	RETURNING record_found,frmschema_fix_mngr.* 
	CALL frm_display_schema_fix_mngr(frmschema_fix_mngr.*)
END FUNCTION

FUNCTION establish_db_connection(connection_string,user_name,passwd)
	DEFINE connection_string STRING
	DEFINE l_dbserver_name STRING
	DEFINE sql_stmt STRING
	DEFINE match util.match_results
	DEFINE i_user_name char(32)
	DEFINE i_passwd CHAR(32)
	--DEFINE user_name char(32)
	DEFINE user_name char(8)
	--DEFINE passwd CHAR(32)
	DEFINE passwd CHAR(16)
	
	LET match = util.regex.search(connection_string,/(\w+)@(\w+)/)
	IF match THEN 
		# We are connecting to a database on another instance
		# in that case we ask for login password
		LET l_dbserver_name = match.str(2)  
		
		WHENEVER SQLERROR CONTINUE
		CLOSE DATABASE
		DISCONNECT CURRENT		# In case there is already an active connection
		# if we connect to a remote database, user and password are required
		CONNECT TO connection_string user user_name USING passwd
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 
		IF sqlca.sqlcode < 0 THEN 
			ERROR "Cannot connect to this remote database ",connection_string," Error ",sqlca.sqlcode 
			LET l_dbserver_name = NULL 
		END IF 
	ELSE 
		# We consider 'local/usual' instance is OK, no login password requested
		 
		# close previous connection
		WHENEVER SQLERROR CONTINUE
		CLOSE database
		DISCONNECT CURRENT
		--LET sql_stmt = "DATABASE ",connection_string
		--EXECUTE IMMEDIATE sql_stmt
		CONNECT TO connection_string
		LET l_dbserver_name = fgl_getenv("INFORMIXSERVER") 
		LET connection_string = trim(connection_string),"@",l_dbserver_name
		DISPLAY connection_string TO dbsname
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
		IF sqlca.sqlcode < 0 THEN
			LET l_dbserver_name = ""
		END IF
	END IF
	
	RETURN l_dbserver_name
END FUNCTION

FUNCTION kandoo_any_errors_handler ()
DEFINE aa integer
LET aa=1
END FUNCTION