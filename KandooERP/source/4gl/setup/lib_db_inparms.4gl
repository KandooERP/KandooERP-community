GLOBALS "lib_db_globals.4gl"

# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getInParms_Count()
# FUNCTION inparms_LookupFilterDataSourceCursor(pRecInParms_Filter)
# FUNCTION inparms_LookupSearchDataSourceCursor(p_RecInParms_Search)
# FUNCTION InParms_LookupFilterDataSource(pRecInParms_Filter)
# FUNCTION inparms_Lookup_filter(p_parm_code)
# FUNCTION import_inparms()
# FUNCTION exist_inparms_Rec(p_cmpy_code, p_parm_code)
# FUNCTION delete_inparms_all()
# FUNCTION inParmsMenu()						-- Offer different OPTIONS of this library via a menu

# InParms  record types
	DEFINE t_recInParms   
		TYPE AS RECORD
			parm_code LIKE inparms.parm_code,
			ref1_text LIKE inparms.ref1_text
		END RECORD 

	DEFINE t_recInParms_Filter  
		TYPE AS RECORD
			filter_parm_code LIKE inparms.parm_code,
			filter_ref1_text LIKE inparms.ref1_text
		END RECORD 

	DEFINE t_recInParms_Search  
		TYPE AS RECORD
			filter_any_field STRING
		END RECORD 		

	DEFINE t_recInParms_noCmpyId 
		TYPE AS RECORD 
    parm_code LIKE inparms.parm_code,
    inv_journal_code LIKE inparms.inv_journal_code,
    last_post_date LIKE inparms.last_post_date,
    last_del_date LIKE inparms.last_del_date,
    last_cost_date LIKE inparms.last_cost_date,
    next_work_num LIKE inparms.next_work_num,
    auto_trans_flag LIKE inparms.auto_trans_flag,
    next_trans_num LIKE inparms.next_trans_num,
    auto_issue_flag LIKE inparms.auto_issue_flag,
    next_issue_num LIKE inparms.next_issue_num,
    auto_adjust_flag LIKE inparms.auto_adjust_flag,
    next_adjust_num LIKE inparms.next_adjust_num,
    auto_recpt_flag LIKE inparms.auto_recpt_flag,
    next_recpt_num LIKE inparms.next_recpt_num,
    int_place_num LIKE inparms.int_place_num,
    dec_place_num LIKE inparms.dec_place_num,
    gl_post_flag LIKE inparms.gl_post_flag,
    gl_del_flag LIKE inparms.gl_del_flag,
    hist_flag LIKE inparms.hist_flag,
    cycle_num  LIKE inparms.cycle_num,
    cost_ind LIKE inparms.cost_ind,
    ref1_text LIKE inparms.ref1_text,
    ref2a_text LIKE inparms.ref2a_text,
    ref2b_text LIKE inparms.ref2b_text,
    ref_reqd_ind LIKE inparms.ref_reqd_ind,
    mast_ware_code LIKE inparms.mast_ware_code,
    ref1_ind LIKE inparms.ref1_ind,
    ref2_text LIKE inparms.ref2_text,
    ref2_ind LIKE inparms.ref2_ind,
    ref3_text LIKE inparms.ref3_text,
    ref3_ind LIKE inparms.ref3_ind,
    ref4_text LIKE inparms.ref4_text,
    ref4_ind LIKE inparms.ref4_ind,
    ref5_text LIKE inparms.ref5_text,
    ref5_ind LIKE inparms.ref5_ind,
    ref6_text LIKE inparms.ref6_text,
    ref6_ind LIKE inparms.ref6_ind,
    ref7_text LIKE inparms.ref7_text,
    ref7_ind LIKE inparms.ref7_ind,
    ref8_text LIKE inparms.ref8_text,
    ref8_ind LIKE inparms.ref8_ind,
    auto_class_flag LIKE inparms.auto_class_flag,
    next_class_num LIKE inparms.next_class_num,
    ibt_ware_code LIKE inparms.ibt_ware_code,
    rec_post_flag LIKE inparms.rec_post_flag,
    barcode_type LIKE inparms.barcode_type,
    barcode_flag LIKE inparms.barcode_flag,
    next_barcode_num LIKE inparms.next_barcode_num 
	END RECORD	

	
########################################################################################
# FUNCTION inParmsMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION inParmsMenu()
	MENU
		ON ACTION "Import"
			CALL import_inparms()
		ON ACTION "Export"
			CALL unload_inparms()
		#ON ACTION "Import"
		#	CALL import_inparms()
		ON ACTION "Delete All"
			CALL delete_inparms_all()
		ON ACTION "Count"
			CALL getInParms_Count() --Count all inparms  rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getInParms_Count()
#-------------------------------------------------------
# Returns the number of InParms  entries for the current company
########################################################################################
FUNCTION getInParms_Count()
	DEFINE ret_InParms_Count SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_InParms  CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM InParms ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_inparms.DECLARE(sqlQuery) #CURSOR FOR getInParms 
	CALL c_inparms.SetResults(ret_InParms_Count)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_inparms.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_InParms_Count = -1
	ELSE
		CALL c_inparms.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of Product IN Parameter Sets:", trim(ret_InParms_Count) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("IN Parameter Set Count", tempMsg,"info") 	
	END IF

	RETURN ret_InParms_Count
END FUNCTION

########################################################################################
# FUNCTION inparms_LookupFilterDataSourceCursor(pRecInParms_Filter)
#-------------------------------------------------------
# Returns the InParms  CURSOR for the lookup query
########################################################################################
FUNCTION inparms_LookupFilterDataSourceCursor(pRecInParms_Filter)
	DEFINE pRecInParms_Filter OF t_recInParms_Filter
	DEFINE sqlQuery STRING
	DEFINE c_InParms  CURSOR
	
	LET sqlQuery =	"SELECT ",
									"inparms.parm_code, ", 
									"inparms.ref1_text ",
									"FROM inparms  ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF pRecInParms_Filter.filter_parm_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND parm_code LIKE '", pRecInParms_Filter.filter_parm_code CLIPPED, "%' "  
	END IF									

	IF pRecInParms_Filter.filter_ref1_text IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ref1_text LIKE '", pRecInParms_Filter.filter_ref1_text CLIPPED, "%' "  
	END IF	
	
			
	LET sqlQuery = sqlQuery, " ORDER BY parm_code"

	CALL c_inparms.DECLARE(sqlQuery)
		
	RETURN c_inparms 
END FUNCTION



########################################################################################
# inparms_LookupSearchDataSourceCursor(p_RecInParms_Search)
#-------------------------------------------------------
# Returns the InParms  CURSOR for the lookup query
########################################################################################
FUNCTION inparms_LookupSearchDataSourceCursor(p_RecInParms_Search)
	DEFINE p_RecInParms_Search OF t_recInParms_Search  
	DEFINE sqlQuery STRING
	DEFINE c_InParms  CURSOR
	
	LET sqlQuery =	"SELECT ",
									"inparms.parm_code, ", 
									"inparms.ref1_text ",
 
									"FROM inparms  ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
	
	IF p_RecInParms_Search.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((parm_code LIKE '", p_RecInParms_Search.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR ref1_text LIKE '",   p_RecInParms_Search.filter_any_field CLIPPED, "%') "  
  						
	END IF


	IF p_RecInParms_Search.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, "ORDER BY parm_code"

	CALL c_inparms.DECLARE(sqlQuery) #CURSOR FOR inparms 
	
	RETURN c_inparms 
END FUNCTION


########################################################################################
# FUNCTION InParms_LookupFilterDataSource(pRecInParms_Filter)
#-------------------------------------------------------
# CALLS InParms_LookupFilterDataSourceCursor(pRecInParms_Filter) with the InParms_Filter data TO get a CURSOR
# Returns the InParms  list array arrInParms_List
########################################################################################
FUNCTION InParms_LookupFilterDataSource(pRecInParms_Filter)
	DEFINE pRecInParms_Filter OF t_recInParms_Filter
	DEFINE recInParms  OF t_recInParms 
	DEFINE arrInParms_List DYNAMIC ARRAY OF t_recInParms  
	DEFINE c_InParms  CURSOR
	DEFINE retError SMALLINT
		
	CALL InParms_LookupFilterDataSourceCursor(pRecInParms_Filter.*) RETURNING c_InParms 
	
	CALL arrInParms_List.CLEAR()

	CALL c_inparms.SetResults(recinparms.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_inparms.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_inparms.FetchNext()=0)
		CALL arrInParms_List.append([recinparms.parm_code, recinparms.ref1_text])
	END WHILE	

	END IF
	
	IF arrInParms_List.getSize() = 0 THEN
		ERROR "No inparms 's found with the specified filter criteria"
	END IF
	
	RETURN arrInParms_List
END FUNCTION	

########################################################################################
# FUNCTION InParms_LookupSearchDataSource(pRecInParms_Filter)
#-------------------------------------------------------
# CALLS InParms_LookupSearchDataSourceCursor(pRecInParms_Filter) with the InParms_Filter data TO get a CURSOR
# Returns the InParms  list array arrInParms_List
########################################################################################
FUNCTION InParms_LookupSearchDataSource(p_recInParms_Search)
	DEFINE p_recInParms_Search OF t_recInParms_Search	
	DEFINE recInParms  OF t_recInParms 
	DEFINE arrInParms_List DYNAMIC ARRAY OF t_recInParms  
	DEFINE c_InParms  CURSOR
	DEFINE retError SMALLINT	
	CALL InParms_LookupSearchDataSourceCursor(p_recInParms_Search) RETURNING c_InParms 
	
	CALL arrInParms_List.CLEAR()

	CALL c_inparms.SetResults(recinparms.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_inparms.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_inparms.FetchNext()=0)
		CALL arrInParms_List.append([recinparms.parm_code, recinparms.ref1_text])
	END WHILE	

	END IF
	
	IF arrInParms_List.getSize() = 0 THEN
		ERROR "No inparms 's found with the specified filter criteria"
	END IF
	
	RETURN arrInParms_List
END FUNCTION


########################################################################################
# FUNCTION inparms_Lookup_filter(p_parm_code)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required InParms  code parm_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL InParms_LookupFilterDataSource(recInParms_Filter.*) RETURNING arrInParms_List
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the InParms  Code parm_code
#
# Example:
# 			LET pr_inparms.parm_code = InParms_Lookup(pr_inparms.parm_code)
########################################################################################
FUNCTION inparms_Lookup_filter(p_parm_code)
	DEFINE p_parm_code LIKE inparms.parm_code
	DEFINE arrInParms_List DYNAMIC ARRAY OF t_recInParms 
	DEFINE recInParms_Filter OF t_recInParms_Filter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wInParms_Lookup WITH FORM "InParms_Lookup_filter"


	CALL InParms_LookupFilterDataSource(recInParms_Filter.*) RETURNING arrInParms_List

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recInParms_Filter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL InParms_LookupFilterDataSource(recInParms_Filter.*) RETURNING arrInParms_List
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrInParms_List TO scInParms_List.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  p_parm_code = arrInParms_List[idx].parm_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recInParms_Filter.filter_parm_code IS NOT NULL
			OR recInParms_Filter.filter_ref1_text IS NOT NULL

		THEN
			LET recInParms_Filter.filter_parm_code = NULL
			LET recInParms_Filter.filter_ref1_text = NULL

			CALL InParms_LookupFilterDataSource(recInParms_Filter.*) RETURNING arrInParms_List
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_parm_code"
		IF recInParms_Filter.filter_parm_code IS NOT NULL THEN
			LET recInParms_Filter.filter_parm_code = NULL
			CALL InParms_LookupFilterDataSource(recInParms_Filter.*) RETURNING arrInParms_List
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_ref1_text"
		IF recInParms_Filter.filter_ref1_text IS NOT NULL THEN
			LET recInParms_Filter.filter_ref1_text = NULL
			CALL InParms_LookupFilterDataSource(recInParms_Filter.*) RETURNING arrInParms_List
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wInParms_Lookup

	OPTIONS INPUT NO WRAP	
	
	RETURN p_parm_code	
END FUNCTION				
		

########################################################################################
# FUNCTION inparms_Lookup(p_parm_code)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required InParms  code parm_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL InParms_LookupSearchDataSource(recInParms_Filter.*) RETURNING arrInParms_List
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the InParms  Code parm_code
#
# Example:
# 			LET pr_inparms.parm_code = InParms_Lookup(pr_inparms.parm_code)
########################################################################################
FUNCTION inparms_Lookup(p_parm_code)
	DEFINE p_parm_code LIKE inparms.parm_code
	DEFINE arrInParms_List DYNAMIC ARRAY OF t_recInParms 
	DEFINE recInParms_Search OF t_recInParms_Search	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wInParms_Lookup WITH FORM "inparms_Lookup"

	CALL InParms_LookupSearchDataSource(recInParms_Search.*) RETURNING arrInParms_List

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recInParms_Search.* WITHOUT DEFAULTS 
			
		ON ACTION "UPDATE-FILTER"
			CALL InParms_LookupSearchDataSource(recInParms_Search.*) RETURNING arrInParms_List
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrInParms_List TO scInParms_List.* 
		BEFORE ROW
			IF arrInParms_List.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  p_parm_code = arrInParms_List[idx].parm_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recInParms_Search.filter_any_field IS NOT NULL

		THEN
			LET recInParms_Search.filter_any_field = NULL

			CALL InParms_LookupSearchDataSource(recInParms_Search.*) RETURNING arrInParms_List
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_parm_code"
		IF recInParms_Search.filter_any_field IS NOT NULL THEN
			LET recInParms_Search.filter_any_field = NULL
			CALL InParms_LookupSearchDataSource(recInParms_Search.*) RETURNING arrInParms_List
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wInParms_Lookup

	OPTIONS INPUT NO WRAP	
	
	RETURN p_parm_code	
END FUNCTION				

############################################
# FUNCTION import_inparms()
############################################
FUNCTION import_inparms()
	DEFINE recCount SMALLINT
	
	DEFINE msgString STRING
	DEFINE importReport STRING
		
  DEFINE driver_error  STRING
  DEFINE native_error  STRING
  DEFINE native_code  INTEGER
	
	DEFINE count_rows_processed INT
	DEFINE count_rows_inserted INT
	DEFINE count_insert_errors INT
	DEFINE count_already_exist INT
	 
	DEFINE cmpy_code_provided BOOLEAN
	DEFINE p_ref1_text LIKE company.name_text
	DEFINE p_country_text LIKE country.country_text
	DEFINE p_language_text LIKE language.language_text
	DEFINE load_file STRING
	DEFINE tmpMsg STRING
	
	DEFINE rec_inparms  OF t_recInParms_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wInParms_Import WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import IN Parameter List Data (table: inparms )" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_inparms 
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_inparms (
	    parm_code CHAR(1),
	    inv_journal_code CHAR(3),
	    last_post_date DATE,
	    last_del_date DATE,
	    last_cost_date DATE,
	    next_work_num INTEGER,
	    auto_trans_flag CHAR(1),
	    next_trans_num INTEGER,
	    auto_issue_flag CHAR(1),
	    next_issue_num INTEGER,
	    auto_adjust_flag CHAR(1),
	    next_adjust_num INTEGER,
	    auto_recpt_flag CHAR(1),
	    next_recpt_num INTEGER,
	    int_place_num SMALLINT,
	    dec_place_num SMALLINT,
	    gl_post_flag CHAR(1),
	    gl_del_flag CHAR(1),
	    hist_flag CHAR(1),
	    cycle_num SMALLINT,
	    cost_ind CHAR(1),
	    ref1_text CHAR(20),
	    ref2a_text CHAR(10),
	    ref2b_text CHAR(10),
	    ref_reqd_ind CHAR(1),
	    mast_ware_code CHAR(3),
	    ref1_ind CHAR(1),
	    ref2_text CHAR(20),
	    ref2_ind CHAR(1),
	    ref3_text CHAR(20),
	    ref3_ind CHAR(1),
	    ref4_text CHAR(20),
	    ref4_ind CHAR(1),
	    ref5_text CHAR(20),
	    ref5_ind CHAR(1),
	    ref6_text CHAR(20),
	    ref6_ind CHAR(1),
	    ref7_text CHAR(20),
	    ref7_ind CHAR(1),
	    ref8_text CHAR(20),
	    ref8_ind CHAR(1),
	    auto_class_flag CHAR(1),
	    next_class_num INTEGER,
	    ibt_ware_code CHAR(3),
	    rec_post_flag CHAR(1),
	    barcode_type CHAR(8),
	    barcode_flag CHAR(1),
	    next_barcode_num INTEGER
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_inparms 	#we need TO INITIALIZE it, delete all rows
		END IF
		
		WHENEVER ERROR STOP	
----------------------------------------------		

	# for certain tables, we need TO know the country code TO identify the right data SET in the templates
	IF gl_setupRec_default_company.cmpy_code IS NOT NULL THEN
		CALL get_company_info (gl_setupRec_default_company.cmpy_code) 
		RETURNING p_ref1_text,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text

		CASE 
			WHEN gl_setupRec_default_company.country_code = "NUL"
				LET msgString = "Company's country code ->",trim(gl_setupRec_default_company.cmpy_code), "<-does NOT exist"
				CALL fgl_winmessage("Company country code does NOT exist",msgString,"error")
				LET cmpy_code_provided = FALSE
				RETURN		
			WHEN gl_setupRec_default_company.country_code = "0"
				--company code comp_code does NOT exist
				LET msgString = "Company code ->",trim(gl_setupRec_default_company.cmpy_code), "<-does NOT exist"
				CALL fgl_winmessage("Company does NOT exist",msgString,"error")
				LET cmpy_code_provided = FALSE
				RETURN
			OTHERWISE
				LET cmpy_code_provided = TRUE
		END CASE				

	END IF

--------------------------------------------------------------- before ---------------------------------------------------------------------
	
	IF gl_setupRec.silentMode = 0 THEN	
	#	OPEN WINDOW wInParms_Import WITH FORM "per/setup/lib_db_data_import_01"
	#	DISPLAY "Chart of Accounts Import" TO header_text

	
		IF cmpy_code_provided = FALSE THEN

			INPUT gl_setupRec_default_company.cmpy_code, gl_setupRec_default_company.country_code,gl_setupRec_default_company.language_code 
			WITHOUT DEFAULTS 
			FROM inputRec3.*
			
				AFTER FIELD cmpy_code
					CALL get_company_info (gl_setupRec_default_company.cmpy_code)
					RETURNING p_ref1_text,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text

					CASE 
						WHEN gl_setupRec_default_company.country_code = "NUL"
							LET msgString = "Company's country code ->",trim(gl_setupRec_default_company.cmpy_code), "<-does NOT exist"
							CALL fgl_winmessage("Company country code does NOT exist",msgString,"error")
							LET cmpy_code_provided = FALSE
							RETURN		
						WHEN gl_setupRec_default_company.country_code = "0"
							--company code comp_code does NOT exist
							LET msgString = "Company code ->",trim(gl_setupRec_default_company.cmpy_code), "<-does NOT exist"
							CALL fgl_winmessage("Company does NOT exist",msgString,"error")
							LET cmpy_code_provided = FALSE
							RETURN
						OTHERWISE
							LET cmpy_code_provided = TRUE
							DISPLAY p_ref1_text,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text 
							TO company.name_text,country_code,country_text,language_code,language_text
					END CASE 
			END INPUT

		ELSE
			IF gl_setupRec.silentMode = FALSE THEN	
				DISPLAY gl_setupRec_default_company.cmpy_code TO cmpy_code

				INPUT gl_setupRec_default_company.cmpy_code, gl_setupRec_default_company.country_code,gl_setupRec_default_company.language_code
					WITHOUT DEFAULTS 
					FROM inputRec3.*  
				END INPUT
				
				IF int_flag THEN
					LET int_flag = FALSE
					CLOSE WINDOW wInParms_Import
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/inparms-",gl_setupRec_default_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("InParms Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_inparms 
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_inparms 
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_inparms 
			LET importReport = importReport, "Code:", trim(rec_inparms.parm_code) , "     -     Desc:", trim(rec_inparms.ref1_text), "\n"
					
			INSERT INTO inparms  VALUES(
			gl_setupRec_default_company.cmpy_code,
			rec_inparms.*
			
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_inparms.parm_code) , "     -     Desc:", trim(rec_inparms.ref1_text), " ->DUPLICATE = Ignored !\n"
					LET count_already_exist = count_already_exist +1
				OTHERWISE	
					LET count_insert_errors = count_insert_errors +1
				 	LET driver_error = fgl_driver_error()
				 	LET native_error = fgl_native_error()
				 	LET native_code = fgl_native_code()
				
					LET importReport = importReport, "ERROR STATUS:\t", trim(STATUS), "\n"
					LET importReport = importReport, "sqlca.sqlcode:\t",trim(sqlca.sqlcode), "\n" 
					LET importReport = importReport, "driver_error:\t", trim(driver_error), "\n"
					LET importReport = importReport, "native_error:\t", trim(native_error), "\n"
					LET importReport = importReport, "native_code:\t",  trim(native_code), "\n"					
			END CASE
			
			LET count_rows_processed= count_rows_processed + 1
		
		END FOREACH

	END IF

	WHENEVER ERROR STOP

	IF gl_setupRec.silentMode = FALSE THEN
			
		DISPLAY BY NAME count_rows_processed
		DISPLAY BY NAME count_rows_inserted
		DISPLAY BY NAME count_insert_errors
		DISPLAY BY NAME count_already_exist
		
		INPUT BY NAME importReport WITHOUT DEFAULTS
			ON ACTION "Done"
				EXIT INPUT
		END INPUT
		
		CLOSE WINDOW wInParms_Import
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_inparms_Rec(p_cmpy_code, p_parm_code)
########################################################
FUNCTION exist_inparms_Rec(p_cmpy_code, p_parm_code)
	DEFINE p_cmpy_code LIKE inparms.cmpy_code
	DEFINE p_parm_code LIKE inparms.parm_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM inparms  
     WHERE cmpy_code = p_cmpy_code
     AND parm_code = p_parm_code

	DROP TABLE temp_inparms 
	CLOSE WINDOW wInParms_Import
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_inparms()
###############################################################
FUNCTION unload_inparms (p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile STRING
	
	LET unloadFile = "unl/inparms-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 
	UNLOAD TO unloadFile 
		SELECT * FROM inparms ORDER BY cmpy_code, parm_code ASC
	
	LET tmpMsg = "All inparms data were exported/written TO:\n", unloadFile
	CALL fgl_winmessage("inparms Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION
###############################################################
# FUNCTION delete_inparms_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_inparms_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE inparms.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wInParms_Import WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Product Main Group (inparms) Delete" TO header_text
	END IF

	
	IF gl_setupRec_default_company.cmpy_code IS NOT NULL THEN
		IF NOT db_company_pk_exists(UI_OFF,gl_setupRec_default_company.cmpy_code) THEN
		#IF NOT exist_company(gl_setupRec_default_company.cmpy_code) THEN  --company code comp_code does NOT exist
			LET msgString = "Company code ->",trim(gl_setupRec_default_company.cmpy_code), "<-does NOT exist"
			CALL fgl_winmessage("Company does NOT exist",msgString,"error")
			RETURN
		END IF
			LET cmpy_code_provided = TRUE
	ELSE
			LET cmpy_code_provided = FALSE				

	END IF

	IF cmpy_code_provided = FALSE THEN

		INPUT gl_setupRec_default_company.cmpy_code WITHOUT DEFAULTS FROM cmpy_code 
		END INPUT

	ELSE

		IF gl_setupRec.silentMode = 0 THEN 	
			DISPLAY gl_setupRec_default_company.cmpy_code TO cmpy_code
		END IF	
	END IF

	
	IF gl_setupRec.silentMode = 0 THEN --no ui
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing inparms table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM inparms
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table inparms!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table inparms where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wInParms_Import		
END FUNCTION	