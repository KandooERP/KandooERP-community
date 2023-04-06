# module generated by Querix Ffg(c)
# Generated on 2019-07-24 14:04:32
# Main template I:\Users\BeGooden-IT\git\KandooERP\KandooERP\Resources\Utilities\Perl\Ffg/templates/module/standalone-form-basic.mtplt


DEFINE cb_country_code ui.combobox 
#@G00005
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
DEFINE m_program CHAR(30) 


DEFINE lku_country RECORD 
	country_text LIKE country.country_text # nvarchar(60) 

END RECORD 
#@G00010
DEFINE g_state RECORD LIKE state.* 


MAIN 
	#Initial UI Init
	CALL setModuleId("UT3") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_u_ut() #init utility module 


	#@G00015
	# WHENEVER ERROR CALL error_mngmt
	# CALL ui_init(0)
	LET m_program="p_y_state_tbl_mngrmt_state" 


	CALL main_y_state_tbl_mngrmt_state() 


END MAIN 


##########################################################################
FUNCTION mc_y_state_tbl_mngrmt_sccs() 
	## definition variable sccs
	DEFINE sccs_var CHAR(70) 
	LET sccs_var="%W% %D%" 
END FUNCTION 
##########################################################################
FUNCTION main_y_state_tbl_mngrmt_state () 
	## this module's main function called by MAIN

	OPEN WINDOW f_state with FORM "U803_state_tbl_mngr" 
	CALL windecoration_u("U803_state_tbl_mngr") 
	--CALL init_widgets_y_state_tbl_mngrmt()  ??
	#@G00036


	CALL sql_prepare_queries_y_state_tbl_mngrmt_state () # INITIALIZE all cursors ON master TABLE 


	CALL menu_y_state_tbl_mngrmt_state() 


	CLOSE WINDOW f_state 


END FUNCTION 


######################################################################
FUNCTION menu_y_state_tbl_mngrmt_state () 
	## menu_y_state_tbl_mngrmt_state
	## the top level menu
	## input arguments: none
	## output arguments: none
	DEFINE nbsel_state INTEGER 
	DEFINE sql_stmt_status INTEGER 
	DEFINE record_num INTEGER 
	DEFINE ACTION SMALLINT 
	DEFINE xnumber SMALLINT 
	DEFINE arr_elem_num SMALLINT 
	DEFINE pky_state RECORD 
		country_code LIKE state.country_code, # nchar(3) 
		state_code LIKE state.state_code # nchar(6) 
		#@G00059
	END RECORD 
	DEFINE frm_y_state_tbl_mngrmt RECORD 
		country_code LIKE state.country_code, # nchar(3) 
		state_code LIKE state.state_code, # nchar(6) 
		state_code_iso366_2 LIKE state.state_code_iso366_2, # nchar(10) 
		state_text LIKE state.state_text, # nchar(30) 
		state_text_enu LIKE state.state_text_enu # nchar(30) 
		#@G00062
	END RECORD 


	DEFINE tbl_y_state_tbl_mngrmt RECORD 
		country_code LIKE state.country_code, # nchar(3) 
		state_code LIKE state.state_code, # nchar(6) 
		state_code_iso366_2 LIKE state.state_code_iso366_2, # nchar(10) 
		state_text LIKE state.state_text, # nchar(30) 
		state_text_enu LIKE state.state_text_enu # nchar(30) 
		#@G00066
	END RECORD 


	DEFINE record_found INTEGER 
	DEFINE lookup_status INTEGER 


	LET nbsel_state = 0 
	MENU "state" 
		BEFORE MENU 
			HIDE option "Next","Previous","EDIT","DELETE" 
		COMMAND "Query" "Query data with multiple criteria state" 
			#@G00076
			MESSAGE "" 
			INITIALIZE frm_y_state_tbl_mngrmt.* TO NULL 
			CLEAR FORM 
			DISPLAY BY NAME frm_y_state_tbl_mngrmt.* 
			HIDE option "Next","Previous" 


			CALL frm_query_y_state_tbl_mngrmt() RETURNING nbsel_state 
			IF nbsel_state > 0 THEN 
				CALL sql_nxtprev_state(1) RETURNING record_found, 
				pky_state.* 


				CASE 
					WHEN record_found = 1 
						LET record_num = 1 
						CALL sql_fetch_full_row_state (pky_state.*) 
						RETURNING record_found,frm_y_state_tbl_mngrmt.* 
						CALL frm_display_y_state_tbl_mngrmt(frm_y_state_tbl_mngrmt.*) 
						MESSAGE record_num,"/",nbsel_state 
					WHEN record_found = -1 
						ERROR "This row is unreachable ",sqlca.sqlcode 
				END CASE 
				IF nbsel_state > 1 THEN 
					SHOW option "Next" 
					NEXT option "Next" 
				END IF 
				SHOW option "EDIT","DELETE" 
			ELSE 
				ERROR "No row matches the criteria" 
				NEXT option "Query" 
			END IF 


		COMMAND "Next" "Display Next record state" 
			#@G00107
			MESSAGE "" 
			CLEAR FORM 
			INITIALIZE frm_y_state_tbl_mngrmt.* TO NULL 


			IF record_num <= nbsel_state THEN 
				CALL sql_nxtprev_state(1) RETURNING record_found, 
				pky_state.* 


				CASE 
					WHEN record_found = 0 
						ERROR "FETCH Last record of this selection state" 
					WHEN record_found = -1 
						ERROR "This row is unreachable ",sqlca.sqlcode 
					WHEN record_found = 1 
						LET record_num = record_num + 1 
						MESSAGE record_num,"/",nbsel_state 
						CALL sql_fetch_full_row_state (pky_state.*) 
						RETURNING record_found,frm_y_state_tbl_mngrmt.* 


						CALL frm_display_y_state_tbl_mngrmt(frm_y_state_tbl_mngrmt.*) 


						IF record_num >= nbsel_state THEN 
							HIDE option "Next" 
						END IF 
						IF record_num > 1 THEN 
							SHOW option "Previous" 
						ELSE 
							HIDE option "Previous" 
						END IF 
				END CASE 
			ELSE 
				ERROR " Please set query criteria previously state " 
				NEXT option "Query" 
			END IF 


		COMMAND "Previous" "Display Previous Record state" 
			#@G00142
			MESSAGE "" 
			CLEAR FORM 
			INITIALIZE frm_y_state_tbl_mngrmt.* TO NULL 

			IF record_num >= 1 THEN 
				CALL sql_nxtprev_state(-1) RETURNING record_found, 
				pky_state.* 
				CASE 
					WHEN record_found = 0 
						ERROR "FETCH First record of this selection state" 
					WHEN record_found < -1 
						ERROR "This row is unreachable ",sqlca.sqlcode 
					WHEN record_found = 1 
						LET record_num = record_num - 1 
						MESSAGE record_num,"/",nbsel_state 
						CALL sql_fetch_full_row_state (pky_state.*) 
						RETURNING record_found,frm_y_state_tbl_mngrmt.* 

						CALL frm_display_y_state_tbl_mngrmt(frm_y_state_tbl_mngrmt.*) 


						IF record_num = 1 THEN 
							HIDE option "Previous" 
						END IF 
						IF record_num < nbsel_state THEN 
							SHOW option "Next" 
						ELSE 
							HIDE option "Next" 
						END IF 
				END CASE 
			ELSE 
				ERROR " Please set query criteria previously state " 
				NEXT option "Query" 
			END IF 


		COMMAND "INSERT" "Add a new record state" 
			#@G00177
			CALL frm_insert_y_state_tbl_mngrmt() RETURNING sql_stmt_status,pky_state.* 


		COMMAND "EDIT" "Modify current record state" 
			#@G00182

			IF nbsel_state THEN 
				IF sql_status_pk_state(pky_state.*) < 0 THEN 
					ERROR "is locked " 
					NEXT option "Next" 
				ELSE 
					CALL frm_edit_y_state_tbl_mngrmt(pky_state.*,frm_y_state_tbl_mngrmt.*) 
					RETURNING sql_stmt_status 
				END IF 
			ELSE 
				ERROR "Please set query criteria previously state" 
				NEXT option "Query" 
			END IF 


		COMMAND "DELETE" "Suppress current record state" 
			#@G00197
			MESSAGE "" 
			IF nbsel_state THEN 
				IF sql_status_pk_state(pky_state.*) < 0 THEN 
					ERROR "is locked " 
					NEXT option "Next" 
				END IF 
				WHILE true 
					CALL confirm_operation(5,10,"Delete") RETURNING ACTION 
					CASE 
						WHEN ACTION = 0 OR ACTION = 1 
							EXIT WHILE # degage abandon 
						WHEN ACTION = 2 
							CALL frm_delete_y_state_tbl_mngrmt(pky_state.*) 
							RETURNING sql_stmt_status 
							EXIT WHILE 
					END CASE 
				END WHILE 
			ELSE 
				ERROR "Please set query criteria previously state " 
				NEXT option "Query" 
			END IF 


		COMMAND "Exit" "Exit program" 
			#@G00220
			MESSAGE "" 
			EXIT MENU 
	END MENU 
END FUNCTION 


#######################################################################
FUNCTION frm_query_y_state_tbl_mngrmt() 
	## frm_Query_y_state_tbl_mngrmt_f_state : Query By Example on table state
	## Input selection criteria,
	## prepare the query,
	## OPEN the data set
	DEFINE rec_state,where_clause STRING 
	DEFINE xnumber,sql_stmt_status INTEGER 
	DEFINE l_pky RECORD 
		country_code LIKE state.country_code, # nchar(3) 
		state_code LIKE state.state_code # nchar(6) 
		#@G00235
	END RECORD 
	DEFINE frm_y_state_tbl_mngrmt RECORD 
		country_code LIKE state.country_code, # nchar(3) 
		state_code LIKE state.state_code, # nchar(6) 
		state_code_iso366_2 LIKE state.state_code_iso366_2, # nchar(10) 
		state_text LIKE state.state_text, # nchar(30) 
		state_text_enu LIKE state.state_text_enu # nchar(30) 
		#@G00238
	END RECORD 


	DEFINE reply CHAR(5) 
	LET xnumber = 0 
	MESSAGE "Please input query criteria" 
	# initialize record and display blank
	CLEAR FORM 
	INITIALIZE frm_y_state_tbl_mngrmt.* TO NULL 
	DISPLAY BY NAME frm_y_state_tbl_mngrmt.* 




	CONSTRUCT BY NAME where_clause ON state.country_code, 
	state.state_code, 
	state.state_code_iso366_2, 
	state.state_text, 
	state.state_text_enu 

	#@G00250
	#@G00250


	## Check whether criteria have been entered
		AFTER CONSTRUCT 
			IF NOT field_touched(state.*) AND NOT int_flag THEN 
				LET reply = fgl_winbutton("","Select all rows, are you sure?","Yes","Yes|No","question",0) 
				CASE 
					WHEN reply matches "Yes" 
						EXIT CONSTRUCT 
					OTHERWISE # saisie d'un critere de selection 
						ERROR "Please input a least one criteria" 
						CONTINUE CONSTRUCT 
				END CASE 
			END IF 
	END CONSTRUCT 


	IF int_flag = true THEN 
		MESSAGE "Quit with quit key" 
		LET int_flag=0 
	ELSE 
		LET xnumber = sql_get_qbe_count_state(where_clause) 
		IF xnumber > 0 THEN 
			LET sql_stmt_status = sql_opn_pky_scr_curs_state(where_clause) 
		ELSE 
			RETURN -1 
		END IF 


	END IF 
	RETURN xnumber 
END FUNCTION ## query_state 


#######################################################################
# frm_Display_y_state_tbl_mngrmt_f_state : displays the form record AFTER reading and displays lookup records if any
# inbound: Form record.*
FUNCTION frm_display_y_state_tbl_mngrmt(frm_y_state_tbl_mngrmt) 
	DEFINE frm_y_state_tbl_mngrmt RECORD 
		country_code LIKE state.country_code, # nchar(3) 
		state_code LIKE state.state_code, # nchar(6) 
		state_code_iso366_2 LIKE state.state_code_iso366_2, # nchar(10) 
		state_text LIKE state.state_text, # nchar(30) 
		state_text_enu LIKE state.state_text_enu # nchar(30) 
		#@G00286
	END RECORD 


	DEFINE lookup_status INTEGER 
	DEFINE lku_country RECORD 
		country_text LIKE country.country_text # nvarchar(60) 

	END RECORD 
	#@G00290
	CLEAR FORM 
	DISPLAY BY NAME frm_y_state_tbl_mngrmt.* 


	IF frm_y_state_tbl_mngrmt.country_code IS NOT NULL THEN 
		CALL lookup_state_country(frm_y_state_tbl_mngrmt.country_code) 
		RETURNING lookup_status, 
		lku_country.country_text 

		CASE 
			WHEN lookup_status = 0 
				DISPLAY 
				lku_country.country_text 

				TO 
				country.country_text 

			WHEN lookup_status = 100 
				#ERROR " "
				#NEXT FIELD country_code
			WHEN lookup_status < 0 
				#ERROR " "
				#NEXT FIELD country_code
		END CASE 
	END IF 

	DISPLAY BY NAME lku_country.country_text 

	#@G00308


END FUNCTION # frm_display_y_state_tbl_mngrmt_f_state 




####################################################################
## frm_Insert_y_state_tbl_mngrmt_f_state: add a new state row
FUNCTION frm_insert_y_state_tbl_mngrmt() 
	DEFINE sql_stmt_status SMALLINT 
	DEFINE rows_count SMALLINT 
	DEFINE nbre_state ,action SMALLINT 
	DEFINE frm_y_state_tbl_mngrmt RECORD 
		country_code LIKE state.country_code, # nchar(3) 
		state_code LIKE state.state_code, # nchar(6) 
		state_code_iso366_2 LIKE state.state_code_iso366_2, # nchar(10) 
		state_text LIKE state.state_text, # nchar(30) 
		state_text_enu LIKE state.state_text_enu # nchar(30) 
		#@G00320
	END RECORD 


	DEFINE tbl_y_state_tbl_mngrmt RECORD 
		country_code LIKE state.country_code, # nchar(3) 
		state_code LIKE state.state_code, # nchar(6) 
		state_code_iso366_2 LIKE state.state_code_iso366_2, # nchar(10) 
		state_text LIKE state.state_text, # nchar(30) 
		state_text_enu LIKE state.state_text_enu # nchar(30) 
		#@G00324
	END RECORD 


	DEFINE lookup_status INTEGER 
	DEFINE lku_country RECORD 
		country_text LIKE country.country_text # nvarchar(60) 

	END RECORD 
	#@G00328


	CLEAR FORM 
	INITIALIZE frm_y_state_tbl_mngrmt.* TO NULL 


	WHILE true 
		LET int_flag = false 
		INPUT BY NAME frm_y_state_tbl_mngrmt.country_code, 
		frm_y_state_tbl_mngrmt.state_code, 
		frm_y_state_tbl_mngrmt.state_code_iso366_2, 
		frm_y_state_tbl_mngrmt.state_text, 
		frm_y_state_tbl_mngrmt.state_text_enu 

		#@G00335
		WITHOUT DEFAULTS 
			AFTER FIELD country_code 
				IF frm_y_state_tbl_mngrmt.country_code IS NULL THEN 
					ERROR "This field is required" 
					NEXT FIELD country_code 
				END IF 
				IF sql_status_pk_state(frm_y_state_tbl_mngrmt.country_code,frm_y_state_tbl_mngrmt.state_code) THEN 
					ERROR "state: already exists" 
					NEXT FIELD country_code 
				END IF 
				IF frm_y_state_tbl_mngrmt.country_code IS NOT NULL THEN 
					CALL lookup_state_country(frm_y_state_tbl_mngrmt.country_code) 
					RETURNING lookup_status, 
					lku_country.country_text 

					CASE 
						WHEN lookup_status = 0 
							DISPLAY 
							lku_country.country_text 

							TO 
							country.country_text 

						WHEN lookup_status = 100 
							ERROR " " 
							NEXT FIELD country_code 
						WHEN lookup_status < 0 
							ERROR " " 
							NEXT FIELD country_code 
					END CASE 
				END IF 
			AFTER FIELD state_code 
				IF frm_y_state_tbl_mngrmt.state_code IS NULL THEN 
					ERROR "This field is required" 
					NEXT FIELD state_code 
				END IF 
				IF sql_status_pk_state(frm_y_state_tbl_mngrmt.country_code,frm_y_state_tbl_mngrmt.state_code) THEN 
					ERROR "state: already exists" 
					NEXT FIELD state_code 
				END IF 
				#@G00368


				#@G00369
				#@G00369
		END INPUT 
		IF int_flag = true THEN 
			# Resign from input
			LET int_flag=false 
			DISPLAY BY NAME frm_y_state_tbl_mngrmt.* 
			MESSAGE "Quit with quit key Control-C" 
			EXIT WHILE 
		END IF 


		CALL confirm_operation(3,10,"Insert") RETURNING ACTION 
		CASE ACTION 
			WHEN 0 # i want TO edit the input, remains displayed 'as is' 
				CONTINUE WHILE # ON laisse tout affiche comme tel 


			WHEN 2 # ON valide la transaction 
				BEGIN WORK 
					#@G00385
					CALL set_table_record_f_state_state(1,frm_y_state_tbl_mngrmt.*) 
					RETURNING tbl_y_state_tbl_mngrmt.* 
					CALL sql_insert_state(tbl_y_state_tbl_mngrmt.*) 
					RETURNING sql_stmt_status, tbl_y_state_tbl_mngrmt.country_code,tbl_y_state_tbl_mngrmt.state_code 
					#@G00389


					CASE 
						WHEN sql_stmt_status = 0 
							MESSAGE "Insert state Successful operation" 
						COMMIT WORK 
						#@G00394
						WHEN sql_stmt_status < 0 
							CALL display_error2("Insert state:failed ") 
							ROLLBACK WORK 
							#@G00397
					END CASE 
					EXIT WHILE 


			WHEN 0 
				ROLLBACK WORK 
				#@G00402
				EXIT WHILE 
		END CASE 
	END WHILE 
	# tbl_y_state_tbl_mngrmt
	RETURN sql_stmt_status, tbl_y_state_tbl_mngrmt.country_code,tbl_y_state_tbl_mngrmt.state_code 
	#@G00407
END FUNCTION ## frm_insert_y_state_tbl_mngrmt_f_state 




#######################################################################
# frm_Edit_y_state_tbl_mngrmt_f_state : Edit a state RECORD
# inbound: table primary key
FUNCTION frm_edit_y_state_tbl_mngrmt(pky,frm_y_state_tbl_mngrmt) 
	DEFINE ACTION SMALLINT 
	DEFINE sql_stmt_status,dummy SMALLINT 


	DEFINE tbl_y_state_tbl_mngrmt RECORD 
		country_code LIKE state.country_code, # nchar(3) 
		state_code LIKE state.state_code, # nchar(6) 
		state_code_iso366_2 LIKE state.state_code_iso366_2, # nchar(10) 
		state_text LIKE state.state_text, # nchar(30) 
		state_text_enu LIKE state.state_text_enu # nchar(30) 
		#@G00419
	END RECORD 


	DEFINE frm_y_state_tbl_mngrmt RECORD 
		country_code LIKE state.country_code, # nchar(3) 
		state_code LIKE state.state_code, # nchar(6) 
		state_code_iso366_2 LIKE state.state_code_iso366_2, # nchar(10) 
		state_text LIKE state.state_text, # nchar(30) 
		state_text_enu LIKE state.state_text_enu # nchar(30) 
		#@G00423
	END RECORD 


	DEFINE sav_y_state_tbl_mngrmt RECORD 
		country_code LIKE state.country_code, # nchar(3) 
		state_code LIKE state.state_code, # nchar(6) 
		state_code_iso366_2 LIKE state.state_code_iso366_2, # nchar(10) 
		state_text LIKE state.state_text, # nchar(30) 
		state_text_enu LIKE state.state_text_enu # nchar(30) 
		#@G00427
	END RECORD 
	DEFINE lookup_status INTEGER 
	#@G00429
	DEFINE rows_count SMALLINT 
	DEFINE pky RECORD 
		country_code LIKE state.country_code, # nchar(3) 
		state_code LIKE state.state_code # nchar(6) 
		#@G00432
	END RECORD 


	## check if record can be accessed
	WHILE true 
		LET int_flag = false 
		# Save Screen Record values before altering
		LET sav_y_state_tbl_mngrmt.* = frm_y_state_tbl_mngrmt.* 
		BEGIN WORK 
			EXECUTE immediate "SET ISOLATION TO COMMITTED READ RETAIN UPDATE LOCKS" 
			WHENEVER ERROR CONTINUE 
			OPEN crs_upd_state USING pky.* 
			FETCH crs_upd_state INTO dummy 
			IF sqlca.sqlcode = -244 THEN ERROR "THIS ROW IS BEING MODIFIED" 
				ROLLBACK WORK EXIT WHILE END IF 
				WHENEVER ERROR stop 
				#@G00447


				INPUT BY NAME frm_y_state_tbl_mngrmt.state_code_iso366_2, 
				frm_y_state_tbl_mngrmt.state_text, 
				frm_y_state_tbl_mngrmt.state_text_enu 

				#@G00449
				WITHOUT DEFAULTS 
				#@G00450


				#@G00451


				#@G00452
				END INPUT 
				IF int_flag = true THEN 
					LET int_flag=false 
					# Restore previous value
					LET frm_y_state_tbl_mngrmt.* = sav_y_state_tbl_mngrmt.* 
					DISPLAY BY NAME frm_y_state_tbl_mngrmt.* 
					DISPLAY BY NAME 
					lku_country.country_text 

					#@G00458
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
						LET frm_y_state_tbl_mngrmt.* = sav_y_state_tbl_mngrmt.* 
						DISPLAY BY NAME frm_y_state_tbl_mngrmt.* 
						EXECUTE immediate "SET ISOLATION TO COMMITTED READ" 
						ROLLBACK WORK 
						EXIT WHILE # CANCEL operation 


					WHEN ACTION = 2 
						# confirm update
						CALL set_table_record_f_state_state(2,frm_y_state_tbl_mngrmt.*) 
						RETURNING tbl_y_state_tbl_mngrmt.* 


						# Perform the prepared update statement
						LET sql_stmt_status = sql_edit_state(pky.*,tbl_y_state_tbl_mngrmt.*) 
						CASE 
							WHEN sql_stmt_status = 0 
								MESSAGE "Edit state Successful operation" 
								EXECUTE immediate "SET ISOLATION TO COMMITTED READ" 
							COMMIT WORK 
							#@G00490
							WHEN sql_stmt_status < 0 
								CALL display_error2("Edit state:failed ") 
								EXECUTE immediate "SET ISOLATION TO COMMITTED READ" 
								ROLLBACK WORK 
								#@G00494
						END CASE 
						EXIT WHILE 
				END CASE 
			END WHILE 
			RETURN sql_stmt_status 
END FUNCTION ## frm_edit_y_state_tbl_mngrmt(pky) 




#######################################################################
# DELETE A state row
# inbound: table primary key
FUNCTION frm_delete_y_state_tbl_mngrmt(pky) 
	DEFINE ACTION SMALLINT 
	DEFINE dummy SMALLINT 
	DEFINE sql_stmt_status SMALLINT 
	DEFINE pky RECORD 
		country_code LIKE state.country_code, # nchar(3) 
		state_code LIKE state.state_code # nchar(6) 
		#@G00511
	END RECORD 


	WHILE true 
		CALL confirm_operation(5,10,"Delete") RETURNING ACTION 
		BEGIN WORK 
			EXECUTE immediate "SET ISOLATION TO COMMITTED READ RETAIN UPDATE LOCKS" 
			WHENEVER ERROR CONTINUE 
			OPEN crs_upd_state USING pky.* 
			FETCH crs_upd_state INTO dummy 
			IF sqlca.sqlcode = -244 THEN ERROR "THIS ROW IS BEING MODIFIED" 
				ROLLBACK WORK EXIT WHILE END IF 
				WHENEVER ERROR stop 
				#@G00523
				CASE 
					WHEN ACTION = 0 OR ACTION = 1 
						# can the delete operation
						EXIT WHILE 
					WHEN ACTION = 2 
						# Validate the delete operation
						CALL sql_delete_state(pky.*) RETURNING sql_stmt_status 
						CASE 
							WHEN sql_stmt_status = 0 
								MESSAGE "Delete state Successful operation" 
							COMMIT WORK 
							#@G00534


							WHEN sql_stmt_status < 0 
								CALL display_error2("Delete state:failed ") 
								ROLLBACK WORK 
								#@G00538
						END CASE 
						EXIT WHILE 
				END CASE 
			END WHILE 
			RETURN sql_stmt_status 
END FUNCTION ## frm_delete_y_state_tbl_mngrmt(pky) 


#########################################################################
#  Build, prepare, declare and initialize main queries and cursors
FUNCTION sql_prepare_queries_y_state_tbl_mngrmt_state () 
	DEFINE query_text STRING 


	# PREPARE cursor for full master table row contents, access by primary key
	LET query_text= 
	"SELECT country_code,state_code,state_code_iso366_2,state_text,state_text_enu 
	", #@G00553 
	" FROM state ", 
	" WHERE country_code = ? ", 
	" AND state_code = ? ", 
	"ORDER BY country_code,state_code" #@g00556 


	PREPARE sel_mrw_state FROM query_text 
	DECLARE crs_row_state CURSOR FOR sel_mrw_state 


	# PREPARE cursor for row test / check if locked
	LET query_text= "SELECT country_code,state_code 
	", #@G00562 
	" FROM state ", 
	" WHERE country_code = ? 
	AND state_code = ? " #@G00565 


	PREPARE sel_pky_state FROM query_text 
	DECLARE crs_pky_state CURSOR FOR sel_pky_state 


	# PREPARE cursor for SELECT FOR UPDATE
	LET query_text= "SELECT country_code,state_code 
	", #@G00571 
	" FROM state ", 
	" WHERE country_code = ? 
	AND state_code = ? ", #@G00574 
	" FOR UPDATE" 


	PREPARE sel_upd_state FROM query_text 
	DECLARE crs_upd_state CURSOR FOR sel_upd_state 


	# PREPARE INSERT statement
	LET query_text = 
	"INSERT INTO state ( country_code,state_code,state_code_iso366_2,state_text,state_text_enu 
	)", #@G00582 
	" VALUES ( ?,?,?,?,? 
	)" #@G00583 
	PREPARE pr_ins_state FROM query_text 


	# PREPARE UPDATE statement
	LET query_text= 
	"UPDATE state ", 
	"SET ( state_code_iso366_2,state_text,state_text_enu 
	)", #@G00589 
	" = ( ?,?,? 
	)", #@G00590 
	" WHERE country_code = ? 
	AND state_code = ? " #@G00592 
	PREPARE pr_upd_state FROM query_text 


	# PREPARE DELETE statement
	LET query_text= "DELETE FROM state ", 
	" WHERE country_code = ? 
	AND state_code = ? " #@G00598 


	PREPARE pr_del_state FROM query_text 


END FUNCTION ## sql_prepare_queries_y_state_tbl_mngrmt_state 




#########################################################
# Open the QBE cursor,
# counts returned rows_count,
# OPEN the data set,
# FETCH first row
# inbound parameter: query predicate
# outbound parameters: number of rows retried
FUNCTION sql_get_qbe_count_state(qry_stmt) 
	DEFINE qry_stmt STRING 
	DEFINE rec_state STRING 
	DEFINE rows_count INTEGER 
	DEFINE lsql_stmt_status INTEGER 


	# define primary_key record
	DEFINE l_pky RECORD 
		country_code LIKE state.country_code, # nchar(3) 
		state_code LIKE state.state_code # nchar(6) 
		#@G00620
	END RECORD 


	LET rec_state = 
	"SELECT count(*) FROM state", 
	" WHERE ",qry_stmt clipped 




	PREPARE prp_cnt_state FROM rec_state 
	DECLARE crs_cnt_state CURSOR FOR prp_cnt_state 


	OPEN crs_cnt_state 
	SET ISOLATION TO dirty read 
	WHENEVER ERROR CONTINUE 
	FETCH crs_cnt_state INTO rows_count 
	WHENEVER ERROR CALL error_mngmt 
	SET ISOLATION TO committed read 


	# if FETCH fails, count = 0, the, get back to query
	IF sqlca.sqlcode OR rows_count = 0 THEN 
		LET rows_count =0 
	END IF 
	FREE crs_cnt_state 
	RETURN rows_count 
END FUNCTION ## sql_get_qbe_count_state 


#########################################################
FUNCTION sql_opn_pky_scr_curs_state(qry_stmt) 
	## Build the query generated by CONSTRUCT BY NAME,
	## Declare and OPEN the cursor
	## inbound param: query predicate
	## outbound parameter: query status
	DEFINE qry_stmt STRING 
	DEFINE rec_state STRING 
	DEFINE rows_count INTEGER 
	DEFINE lsql_stmt_status INTEGER 


	# define primary_key record
	DEFINE l_pky RECORD 
		country_code LIKE state.country_code, # nchar(3) 
		state_code LIKE state.state_code # nchar(6) 
		#@G00659
	END RECORD 


	# display the selected columns


	LET rec_state = "SELECT country_code,state_code 
	", #@G00664 
	" FROM state ", 
	"WHERE ",qry_stmt clipped, 
	" ORDER BY country_code,state_code 
	" #@G00667 


	PREPARE rech_crs_ FROM rec_state 


	# crs_scrl_crs_ : the first cursor selects all the primary keys (not all the table columns)


	DECLARE crs_scrl_crs_ SCROLL CURSOR with HOLD 
	FOR rech_crs_ #@g00673 


	WHENEVER ERROR CONTINUE 
	OPEN crs_scrl_crs_ 
	WHENEVER ERROR CALL error_mngmt 


	RETURN sqlca.sqlcode 
END FUNCTION ## sql_opn_pky_scr_curs_state 


#######################################################################
FUNCTION sql_nxtprev_state(offset) 
	## sql_nxtprev_state : FETCH NEXT OR PREVIOUS RECORD
	DEFINE offset SMALLINT 
	DEFINE lsql_stmt_status,record_found INTEGER 
	DEFINE pky RECORD 
		country_code LIKE state.country_code, # nchar(3) 
		state_code LIKE state.state_code # nchar(6) 
		#@G00688
	END RECORD 
	DEFINE frm_y_state_tbl_mngrmt RECORD 
		country_code LIKE state.country_code, # nchar(3) 
		state_code LIKE state.state_code, # nchar(6) 
		state_code_iso366_2 LIKE state.state_code_iso366_2, # nchar(10) 
		state_text LIKE state.state_text, # nchar(30) 
		state_text_enu LIKE state.state_text_enu # nchar(30) 
		#@G00691
	END RECORD 


	WHENEVER ERROR CONTINUE 
	FETCH relative offset crs_scrl_crs_ INTO pky.* 
	WHENEVER ERROR CALL error_mngmt 


	CASE 
		WHEN sqlca.sqlcode = 100 
			LET record_found = 0 


		WHEN sqlca.sqlcode < 0 
			LET record_found = -1 
		OTHERWISE 
			LET lsql_stmt_status = 1 
			LET record_found = 1 
			#CALL sql_FETCH_full_row_state (pky.*)
			#RETURNING record_found,frm_y_state_tbl_mngrmt.*


	END CASE 
	RETURN record_found,pky.* 
END FUNCTION ## sql_nxtprev_state 


#########################################################################################
FUNCTION sql_fetch_full_row_state(pky_state) 
	# sql_FETCH_full_row_state : read a complete row accessing by primary key
	# inbound parameter : primary key
	# outbound parameter: sql_stmt_status and row contents
	DEFINE sql_stmt_status SMALLINT 
	DEFINE pky_state RECORD 
		country_code LIKE state.country_code, # nchar(3) 
		state_code LIKE state.state_code # nchar(6) 
		#@G00721
	END RECORD 
	DEFINE tbl_y_state_tbl_mngrmt RECORD 
		country_code LIKE state.country_code, # nchar(3) 
		state_code LIKE state.state_code, # nchar(6) 
		state_code_iso366_2 LIKE state.state_code_iso366_2, # nchar(10) 
		state_text LIKE state.state_text, # nchar(30) 
		state_text_enu LIKE state.state_text_enu # nchar(30) 
		#@G00724
	END RECORD 
	DEFINE frm_y_state_tbl_mngrmt RECORD 
		country_code LIKE state.country_code, # nchar(3) 
		state_code LIKE state.state_code, # nchar(6) 
		state_code_iso366_2 LIKE state.state_code_iso366_2, # nchar(10) 
		state_text LIKE state.state_text, # nchar(30) 
		state_text_enu LIKE state.state_text_enu # nchar(30) 
		#@G00727
	END RECORD 


	DEFINE lookup_status INTEGER 
	DEFINE lku_country RECORD 
		country_text LIKE country.country_text # nvarchar(60) 

	END RECORD 
	#@G00731


	# read the table, access on primary key
	WHENEVER ERROR CONTINUE 
	OPEN crs_row_state 
	USING pky_state.* 


	FETCH crs_row_state INTO tbl_y_state_tbl_mngrmt.* 


	WHENEVER ERROR CALL error_mngmt 
	CASE 
		WHEN sqlca.sqlcode = 100 
			LET sql_stmt_status = 0 
		WHEN sqlca.sqlcode < 0 
			LET sql_stmt_status = -1 
		OTHERWISE 
			LET sql_stmt_status = 1 
			CALL set_form_record_y_state_tbl_mngrmt(tbl_y_state_tbl_mngrmt.*) 
			RETURNING frm_y_state_tbl_mngrmt.* 
	END CASE 
	RETURN sql_stmt_status,frm_y_state_tbl_mngrmt.* 
END FUNCTION ## sql_fetch_full_row_state 


########################################################################
FUNCTION sql_insert_state(tbl_y_state_tbl_mngrmt) 
	## INSERT in table state
	DEFINE lsql_stmt_status INTEGER 
	DEFINE rows_count SMALLINT 
	DEFINE pky RECORD 
		country_code LIKE state.country_code, # nchar(3) 
		state_code LIKE state.state_code # nchar(6) 
		#@G00760
	END RECORD 
	DEFINE tbl_y_state_tbl_mngrmt RECORD 
		country_code LIKE state.country_code, # nchar(3) 
		state_code LIKE state.state_code, # nchar(6) 
		state_code_iso366_2 LIKE state.state_code_iso366_2, # nchar(10) 
		state_text LIKE state.state_text, # nchar(30) 
		state_text_enu LIKE state.state_text_enu # nchar(30) 
		#@G00763
	END RECORD 
	WHENEVER ERROR CONTINUE 
	EXECUTE pr_ins_state 
	USING tbl_y_state_tbl_mngrmt.country_code, 
	tbl_y_state_tbl_mngrmt.state_code, 
	tbl_y_state_tbl_mngrmt.state_code_iso366_2, 
	tbl_y_state_tbl_mngrmt.state_text, 
	tbl_y_state_tbl_mngrmt.state_text_enu 
	#@G00767
	WHENEVER ERROR CALL error_mngmt 


	IF sqlca.sqlcode < 0 THEN 
		LET lsql_stmt_status = -1 
	ELSE 
		LET lsql_stmt_status = 0 
		#@G00774


	END IF 
	RETURN lsql_stmt_status,pky.* 
END FUNCTION ## sql_insert_state 


########################################################################
FUNCTION sql_edit_state(pky,tbl_y_state_tbl_mngrmt) 
	## sql_Edit_state :update state record
	DEFINE lsql_stmt_status INTEGER 
	DEFINE pky RECORD 
		country_code LIKE state.country_code, # nchar(3) 
		state_code LIKE state.state_code # nchar(6) 
		#@G00785
	END RECORD 
	DEFINE tbl_y_state_tbl_mngrmt RECORD 
		country_code LIKE state.country_code, # nchar(3) 
		state_code LIKE state.state_code, # nchar(6) 
		state_code_iso366_2 LIKE state.state_code_iso366_2, # nchar(10) 
		state_text LIKE state.state_text, # nchar(30) 
		state_text_enu LIKE state.state_text_enu # nchar(30) 
		#@G00788
	END RECORD 


	WHENEVER ERROR CONTINUE 
	EXECUTE pr_upd_state 
	USING tbl_y_state_tbl_mngrmt.state_code_iso366_2, 
	tbl_y_state_tbl_mngrmt.state_text, 
	tbl_y_state_tbl_mngrmt.state_text_enu 
	, #@g00793 
	pky.* 


	WHENEVER ERROR CALL error_mngmt 
	IF sqlca.sqlcode < 0 THEN 


		LET lsql_stmt_status = -1 
	ELSE 
		LET lsql_stmt_status = 0 
	END IF 
	RETURN lsql_stmt_status 
END FUNCTION ## sql_edit_state 


##############################################################################################
FUNCTION sql_delete_state(pky) 
	## sql_Delete_state :delete current row in table state
	DEFINE lsql_stmt_status SMALLINT 
	DEFINE pky RECORD 
		country_code LIKE state.country_code, # nchar(3) 
		state_code LIKE state.state_code # nchar(6) 
		#@G00811
	END RECORD 


	WHENEVER ERROR CONTINUE 
	EXECUTE pr_del_state 
	USING pky.* 


	WHENEVER ERROR CALL error_mngmt 
	IF sqlca.sqlcode < 0 THEN 
		LET lsql_stmt_status = -1 
	ELSE 
		LET lsql_stmt_status=0 
	END IF 
	RETURN lsql_stmt_status 
END FUNCTION ## sql_delete_state 


################################################################################
FUNCTION sql_status_pk_state(pky) 
	##   sql_status_pk_state : Check if primary key exists
	## inbound parameter : record of primary key
	## outbound parameter:  status > 0 if exists, 0 if no record, < 0 if error
	DEFINE pky RECORD 
		country_code LIKE state.country_code, # nchar(3) 
		state_code LIKE state.state_code # nchar(6) 
		#@G00833
	END RECORD 
	DEFINE pk_status INTEGER 


	WHENEVER ERROR CONTINUE 
	OPEN crs_pky_state USING pky.* 
	FETCH crs_pky_state 
	WHENEVER ERROR CALL error_mngmt 


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
END FUNCTION ## sql_status_pk_state 


################################################################################################
FUNCTION set_form_record_y_state_tbl_mngrmt(tbl_contents) 
	## set_form_record_y_state_tbl_mngrmt_f_state: assigns table values to form fields values
	DEFINE frm_contents RECORD 
		country_code LIKE state.country_code, # nchar(3) 
		state_code LIKE state.state_code, # nchar(6) 
		state_code_iso366_2 LIKE state.state_code_iso366_2, # nchar(10) 
		state_text LIKE state.state_text, # nchar(30) 
		state_text_enu LIKE state.state_text_enu # nchar(30) 
		#@G00860
	END RECORD 


	DEFINE tbl_contents RECORD 
		country_code LIKE state.country_code, # nchar(3) 
		state_code LIKE state.state_code, # nchar(6) 
		state_code_iso366_2 LIKE state.state_code_iso366_2, # nchar(10) 
		state_text LIKE state.state_text, # nchar(30) 
		state_text_enu LIKE state.state_text_enu # nchar(30) 
		#@G00864
	END RECORD 


	INITIALIZE frm_contents.* TO NULL 
	LET frm_contents.country_code = tbl_contents.country_code 
	LET frm_contents.state_code = tbl_contents.state_code 
	LET frm_contents.state_code_iso366_2 = tbl_contents.state_code_iso366_2 
	LET frm_contents.state_text = tbl_contents.state_text 
	LET frm_contents.state_text_enu = tbl_contents.state_text_enu 
	#@G00873
	RETURN frm_contents.* 
END FUNCTION ## set_form_recordy_state_tbl_mngrmt_f_state 


################################################################################################
FUNCTION set_table_record_f_state_state(sql_stmt,frm_contents) 
	## set_table_record_f_state_state: assigns form fields value to table values
	DEFINE sql_stmt SMALLINT # 1 => insert, 2 => UPDATE 
	DEFINE pky RECORD 
		country_code LIKE state.country_code, # nchar(3) 
		state_code LIKE state.state_code # nchar(6) 
		#@G00882
	END RECORD 


	DEFINE frm_contents RECORD 
		country_code LIKE state.country_code, # nchar(3) 
		state_code LIKE state.state_code, # nchar(6) 
		state_code_iso366_2 LIKE state.state_code_iso366_2, # nchar(10) 
		state_text LIKE state.state_text, # nchar(30) 
		state_text_enu LIKE state.state_text_enu # nchar(30) 
		#@G00886
	END RECORD 


	DEFINE tbl_contents RECORD 
		country_code LIKE state.country_code, # nchar(3) 
		state_code LIKE state.state_code, # nchar(6) 
		state_code_iso366_2 LIKE state.state_code_iso366_2, # nchar(10) 
		state_text LIKE state.state_text, # nchar(30) 
		state_text_enu LIKE state.state_text_enu # nchar(30) 
		#@G00890
	END RECORD 


	INITIALIZE tbl_contents.* TO NULL 
	LET tbl_contents.country_code = frm_contents.country_code 
	LET tbl_contents.state_code = frm_contents.state_code 
	LET tbl_contents.state_code_iso366_2 = frm_contents.state_code_iso366_2 
	LET tbl_contents.state_text = frm_contents.state_text 
	LET tbl_contents.state_text_enu = frm_contents.state_text_enu 
	#@G00899


	RETURN tbl_contents.* 
END FUNCTION ## set_table_recordf_state_state 


FUNCTION lookup_state_country(l_country_code) 
	DEFINE l_country_code nchar(3) 
	DEFINE l_country_text nvarchar(60) 
	WHENEVER ERROR CONTINUE 
	SELECT country_text 
	INTO l_country_text 
	FROM country 
	WHERE 
	country_code = l_country_code 
	IF sqlca.sqlcode = 100 THEN 
		LET l_country_text = NULL 
	END IF 
	WHENEVER ERROR CALL error_mngmt 
	RETURN sqlca.sqlcode,l_country_text 
END FUNCTION 

#@G00918


FUNCTION init_widgets_y_state_tbl_mngrmt () 
	CALL init_combobox_country_code () 
END FUNCTION # init_widgets_y_state_tbl_mngrmt () 

FUNCTION init_combobox_country_code () 
	DEFINE l_country_code LIKE state.country_code 
	LET cb_country_code = ui.Combobox.ForName("country_code") 
	DECLARE crs_cb_country_code CURSOR FOR SELECT country_code FROM country ORDER BY country_code 
	FOREACH crs_cb_country_code INTO l_country_code 
		CALL cb_country_code.additem (l_country_code) 
	END FOREACH 
END FUNCTION # init_combobox_country_code 
#@G00933


#@G00935


#@G00937
