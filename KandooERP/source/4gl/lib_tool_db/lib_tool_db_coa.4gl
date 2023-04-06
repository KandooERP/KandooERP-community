##############################################################################################
# TABLE COA
# NOTE: This Module is linked with lib_tool (not lib_tool_db) because it is required by ALL (or most) programs i.e. due to authentication
##############################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"

# FUNCTION db_coa_get_count_silent(p_silentMode)
# FUNCTION db_coa_get_lookupFilterDataSourceCursor(pRecCoaFilter)
# FUNCTION db_coa_get_lookupFilterDataSourceCursor(pRecCoaFilter)
# FUNCTION db_coa_get_lookupFilterDataSource(pRecCoaFilter)
# FUNCTION db_coa_get_lookup_filter(pCoaCode)
# FUNCTION db_coa_import(p_silentMode,p_start_year_num,p_start_period_num,p_end_year_num,p_end_period_num)
# FUNCTION db_coa_pk_exists(p_ui,p_acct_code)
# FUNCTION db_coa_delete_all()

##########################################################
# MODULE Scope Variables
##########################################################
# Coa record types
	DEFINE t_recCoa TYPE AS RECORD
			acct_code LIKE coa.acct_code,
			desc_text LIKE coa.desc_text,
			group_code LIKE coa.group_code
		END RECORD 

	DEFINE t_recCoaFilter TYPE AS RECORD
			filter_acct_code LIKE coa.acct_code,
			filter_desc_text LIKE coa.desc_text,
			filter_group_code LIKE coa.group_code
		END RECORD 

	DEFINE t_recCoaSearch TYPE AS RECORD
			filter_any_field STRING,
			filter_group_code LIKE coa.group_code
		END RECORD 		

############################################################
# FUNCTION db_coa_get_count()
#
# Return total number of rows in coa FROM current company
############################################################
FUNCTION db_coa_get_count()
	DEFINE ret INT

	SELECT count(*) 
	INTO ret 
	FROM coa 
	WHERE voucher.cmpy_code = glob_rec_kandoouser.cmpy_code

	RETURN ret
END FUNCTION
############################################################
# END FUNCTION db_coa_get_count()
############################################################


########################################################################################
# FUNCTION db_coa_get_count_silent(p_silentMode)
#-------------------------------------------------------
# Returns the number of Coa entries for the current company
########################################################################################
FUNCTION db_coa_get_count_silent(p_silentMode)
	DEFINE p_silentMode SMALLINT 
	DEFINE ret_CoaCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_Coa CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM Coa ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_Coa.DECLARE(sqlQuery) #CURSOR FOR getCoa
	CALL c_Coa.SetResults(ret_CoaCount)  --define variable for result output
	
	
	LET retError = c_Coa.OPEN()
	

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_CoaCount = -1
	ELSE
		CALL c_Coa.FetchNext()
	END IF

	IF p_silentMode = 0 THEN
		LET tempMsg = "Number of COA entries:", trim(ret_CoaCount) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("COA Count", tempMsg,"info") 	
	END IF


	RETURN ret_CoaCount
END FUNCTION
########################################################################################
# END FUNCTION db_coa_get_count_silent(p_silentMode)
########################################################################################


######################################################
# FUNCTION db_coa_pk_exists(p_ui,p_acct_code)
######################################################
#	CONSTANT UI_OFF SMALLINT = 0
#	CONSTANT UI_ON SMALLINT = 1
#	CONSTANT UI_FK SMALLINT = 2
#	CONSTANT UI_PK SMALLINT = 3
############################################################
FUNCTION db_coa_pk_exists(p_ui_mode,p_op_mode,p_acct_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_op_mode SMALLINT
	DEFINE p_acct_code LIKE coa.acct_code
	DEFINE recCount INT
	DEFINE ret BOOLEAN	

	IF p_acct_code IS NULL THEN
		IF p_ui_mode >= UI_ON THEN
			ERROR "GL-COA code can not be empty"
			#LET msgresp = kandoomsg("G",9178,"")
			#9178 Bank/State/Branchs must NOT be NULL
		END IF
		RETURN FALSE
	END IF

		SELECT COUNT(*) INTO recCount FROM coa 
     WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
     AND acct_code = p_acct_code
		
	
##
	IF recCount > 0 THEN
		LET ret = TRUE	
		CASE p_op_mode
			WHEN MODE_INSERT
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "GL-COA Code already exists! (", trim(p_acct_code), ")"
					WHEN UI_FK
						#No MESSAGE
					OTHERWISE
						#No MESSAGE
				END CASE

			WHEN MODE_UPDATE
				CASE p_ui_mode
					WHEN UI_PK
						#No MESSAGE
					WHEN UI_FK
						#ERROR "GL-COA Code does not exists! (", trim(p_acct_code), ")"
					OTHERWISE
						#No MESSAGE
				END CASE

			WHEN MODE_DELETE
				CASE p_ui_mode
					WHEN UI_PK
						#No MESSAGE
					WHEN UI_FK
						#ERROR "GL-COA Code does not exists! (", trim(p_acct_code), ")"
					OTHERWISE
						#No MESSAGE
				END CASE
		END CASE

	ELSE

		LET ret = FALSE	
		CASE p_op_mode
			WHEN MODE_INSERT
				CASE p_ui_mode
					WHEN UI_PK
						#No MESSAGE
					WHEN UI_FK
						ERROR "GL-COA Code does not exists! (", trim(p_acct_code), ")"
					OTHERWISE
						#No MESSAGE
				END CASE

			WHEN MODE_UPDATE
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "GL-COA Code does not exists! (", trim(p_acct_code), ")"
					WHEN UI_FK
						#No MESSAGE
					OTHERWISE
						#No MESSAGE
				END CASE

			WHEN MODE_DELETE
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "GL-COA Code does not exists! (", trim(p_acct_code), ")"
					WHEN UI_FK
						#No MESSAGE
					OTHERWISE
						#No MESSAGE
				END CASE
		END CASE
	END IF
	
	RETURN ret
END FUNCTION
######################################################
# FUNCTION db_coa_pk_exists(p_ui_mode,p_op_mode,p_acct_code)
######################################################


############################################################
#FUNCTION db_coa_get_desc_text(p_ui_mode,p_acct_code)
# RETURN l_ret_desc_text 
#
# Get description text of coa record
############################################################
FUNCTION db_coa_get_desc_text(p_ui_mode,p_acct_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_acct_code LIKE coa.acct_code
	DEFINE l_ret_desc_text LIKE coa.desc_text


	IF p_acct_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN	
			ERROR "coa Code can NOT be empty"
		END IF
			RETURN NULL
	END IF

	SELECT desc_text 
	INTO l_ret_desc_text 
	FROM coa 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				
	AND coa.acct_code = p_acct_code
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "coa Description with Code ",trim(p_acct_code),  " NOT found"
		END IF			
		LET l_ret_desc_text = NULL
	ELSE
		#
	END IF	
	RETURN l_ret_desc_text
END FUNCTION
############################################################
# END FUNCTION db_coa_get_desc_text(p_ui_mode,p_acct_code)
############################################################


############################################################
# FUNCTION db_coa_get_rec(p_ui_mode,p_acct_code)
#
#
############################################################
FUNCTION db_coa_get_rec(p_ui_mode,p_acct_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_acct_code LIKE coa.acct_code

	DEFINE l_rec_coa RECORD LIKE coa.*

	IF p_acct_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Can not retrieve record with empty COA code"
		END IF	

		RETURN NULL
	END IF 

  SELECT *
    INTO l_rec_coa.*
    FROM coa
   WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
   	AND acct_code= p_acct_code
	
	IF sqlca.sqlcode != 0 THEN 
   	IF p_ui_mode != UI_OFF THEN 
      ERROR "COA with acct_code=", trim(p_acct_code), " NOT found"
			RETURN NULL
		END IF
   ELSE
		RETURN l_rec_coa.*		                                                                                                
	END IF	         
END FUNCTION	
############################################################
# END FUNCTION db_coa_get_rec(p_ui_mode,p_acct_code)
############################################################


########################################################################################################################
#
# ARRAY DATASOURCE
#
########################################################################################################################


############################################################
# FUNCTION db_coa_get_arr_rec(p_where_text)
# RETURN l_arr_rec_coa 
# Return coa rec array
############################################################
FUNCTION db_coa_get_arr_rec(p_where_text)
	DEFINE p_where_text STRING
	DEFINE l_query_text STRING
	DEFINE l_rec_coa RECORD LIKE coa.*
	DEFINE l_arr_rec_coa DYNAMIC ARRAY OF RECORD LIKE coa.*
	DEFINE l_idx SMALLINT --loop control

	LET l_query_text = "SELECT * FROM coa ",
                        "WHERE cmpy_code =\"",glob_rec_kandoouser.cmpy_code,"\" "

	IF p_where_text IS NOT NULL THEN                        
		LET l_query_text =  l_query_text CLIPPED, " AND ", trim(p_where_text), " "
	END IF
			                      
	LET l_query_text =  l_query_text CLIPPED,
			"ORDER BY ",
				"acct_code,"
				
	PREPARE s_coa FROM l_query_text
	DECLARE c_coa CURSOR FOR s_coa

	LET l_idx = 0
	FOREACH c_coa INTO l_rec_coa.*
		LET l_idx = l_idx + 1
		LET l_arr_rec_coa[l_idx].* = l_rec_coa.*
	END FOREACH
 
	FREE c_coa
	
	RETURN l_arr_rec_coa  
END FUNCTION	
############################################################
# END FUNCTION db_coa_get_arr_rec(p_where_text)
############################################################


############################################################
# FUNCTION db_coa_get_arr_rec_short(p_where_text)
# RETURN l_arr_rec_coa 
# Return coa rec array
############################################################
FUNCTION db_coa_get_arr_rec_short(p_where_text)
	DEFINE p_where_text STRING
	DEFINE l_query_text STRING
	DEFINE l_rec_coa RECORD LIKE coa.*

	DEFINE l_arr_rec_coa DYNAMIC ARRAY OF RECORD 
		acct_code LIKE coa.acct_code,
		desc_text LIKE coa.desc_text,
		type_ind LIKE coa.type_ind,
		is_nominalcode LIKE coa.is_nominalcode
	END RECORD

	DEFINE l_idx SMALLINT --loop control

	LET l_query_text = "SELECT acct_code,desc_text,type_ind,is_nominalcode FROM coa ",
                        "WHERE cmpy_code =\"",glob_rec_kandoouser.cmpy_code,"\" "

	IF p_where_text IS NOT NULL THEN                        
		LET l_query_text =  l_query_text CLIPPED, " AND ", trim(p_where_text), " "
	END IF
			                      
	LET l_query_text =  l_query_text CLIPPED, " ",
			" ORDER BY ",
				"acct_code" -- HuHo: had to remove tpye_ind due to multiple divisions -> albo				 #"type_ind, acct_code" -- albo

	PREPARE s_coa_short FROM l_query_text
	DECLARE crs_coa_scan CURSOR FOR s_coa_short


	LET l_idx = 1
	FOREACH crs_coa_scan INTO l_arr_rec_coa[l_idx].acct_code,		
		l_arr_rec_coa[l_idx].desc_text,
		l_arr_rec_coa[l_idx].type_ind,
		l_arr_rec_coa[l_idx].is_nominalcode
		LET l_idx = l_idx + 1
	END FOREACH

	FREE crs_coa_scan

	RETURN l_arr_rec_coa  
END FUNCTION	# db_coa_get_arr_rec_short
############################################################
# END FUNCTION db_coa_get_arr_rec_short(p_where_text)
############################################################


############################################################
# FUNCTION db_coa_get_arr_tree ()
# this function reads the coa to present it in a form tree widget 
#
############################################################
FUNCTION db_coa_get_arr_tree ()
	DEFINE idx SMALLINT
	DEFINE sql_statement STRING
	DEFINE l_arr_rec_coa_tree DYNAMIC ARRAY OF RECORD # t_rec_coa_for_tree
		description NCHAR(120),
		id LIKE coa.acct_code,
		parentid LIKE coa.parentid
	END RECORD
	DEFINE crs_scan_coa_tree CURSOR

	# Now display the template in the tree view
	CALL l_arr_rec_coa_tree.Clear()
	
	LET sql_statement =
	" SELECT trim(acct_code)||' - '||desc_text,acct_code,parentid ",
	" FROM coa ",
	" WHERE cmpy_code = ? ", --glob_rec_company.cmpy_code
	" ORDER BY acct_code "
 
	CALL crs_scan_coa_tree.Declare(sql_statement)
	CALL crs_scan_coa_tree.Open(glob_rec_company.cmpy_code)
	LET idx = 1

	WHILE crs_scan_coa_tree.FetchNext(l_arr_rec_coa_tree[idx].description,l_arr_rec_coa_tree[idx].id,l_arr_rec_coa_tree[idx].parentid ) = 0
		LET idx = idx + 1
	END WHILE

	RETURN l_arr_rec_coa_tree

END FUNCTION		# db_coa_get_arr_tree
############################################################
# END FUNCTION db_coa_get_arr_tree ()
############################################################


########################################################################################################################
# 
# UPDATE INSERT DELETE row from DB
#
########################################################################################################################


############################################################
# FUNCTION db_coa_update(p_rec_coa)
# RETURN STATUS
#
############################################################
FUNCTION db_coa_update(p_rec_coa)
	DEFINE p_rec_coa RECORD LIKE coa.*

	IF p_rec_coa IS NULL THEN
		ERROR "Can not update empty COA record"
		RETURN -1
	ELSE
		IF (p_rec_coa.cmpy_code IS NULL) OR (p_rec_coa.acct_code IS NULL) OR (p_rec_coa.desc_text IS NULL) OR (p_rec_coa.type_ind IS NULL) THEN
			ERROR "Can not update incomplete COA record"
			RETURN -1
		END IF
	END IF

	
	UPDATE coa
	SET * = p_rec_coa.*
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
	AND acct_code = p_rec_coa.acct_code

	WHENEVER ERROR STOP
	RETURN sqlca.sqlcode

END FUNCTION
############################################################
# END FUNCTION db_coa_update(p_rec_coa)
############################################################


############################################################
# FUNCTION db_coa_insert(p_rec_coa)
#
#
############################################################
FUNCTION db_coa_insert(p_rec_coa)
	DEFINE p_rec_coa RECORD LIKE coa.*

	INSERT INTO coa
   VALUES(p_rec_coa.*)

	RETURN STATUS
END FUNCTION
############################################################
# END FUNCTION db_coa_insert(p_rec_coa)
############################################################


############################################################
# FUNCTION db_coa_delete(p_ui_mode,p_confirm,p_acct_code)
#
#
############################################################
FUNCTION db_coa_delete(p_ui_mode,p_confirm,p_acct_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_confirm BOOLEAN #is operator requested to confirm this operation / independent of ui mode
	DEFINE p_acct_code LIKE coa.acct_code
	DEFINE l_old_limit_amt        LIKE fundsapproved.limit_amt	
	DEFINE l_msgresp LIKE language.yes_flag	
	DEFINE l_sql_stmt_status SMALLINT	
	DEFINE l_msg_str STRING

	IF p_confirm = UI_CONFIRM_ON THEN
		LET l_msg_str = "Delete COA Nominal Code ", trim(p_acct_code), " ?"
		IF NOT promptTF("Delete COA Nominal Code",l_msg_str,TRUE) THEN
			RETURN -10
		END IF
	END IF

	IF p_acct_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET l_msg_str = "Nominal Code code can not be empty ! (Nominal Code / Account Code =", trim(p_acct_code), ")"  
			ERROR l_msg_str
		END IF
		RETURN -1
	END IF
		
#		SELECT unique(1) FROM purchhead
#		 WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
#		   AND coa_code = p_acct_code


#	IF NOT(STATUS = NOTFOUND) THEN
#		ERROR kandoomsg2("P",9554,"")	#9553 Cannot delete P.O. type as its IS being used by ...
#		RETURN -1
#	END IF

	SELECT * FROM coa
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
		AND acct_code = p_acct_code

		   
	IF sqlca.sqlcode != 0 THEN
		ERROR "Can not delete COA because ", p_acct_code, " does not exist!"
		RETURN -1
	END IF
	
	DELETE FROM coa
	WHERE acct_code = p_acct_code
	AND cmpy_code = glob_rec_kandoouser.cmpy_code

	DELETE FROM account
	WHERE acct_code = p_acct_code
	AND cmpy_code = glob_rec_kandoouser.cmpy_code

	DELETE FROM accounthist
	WHERE acct_code = p_acct_code
	AND cmpy_code = glob_rec_kandoouser.cmpy_code

	DELETE FROM accountledger
	WHERE acct_code = p_acct_code
	AND cmpy_code = glob_rec_kandoouser.cmpy_code

	SELECT limit_amt INTO l_old_limit_amt 
	FROM fundsapproved
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
	AND acct_code = p_acct_code
 
	INSERT INTO fundaudit VALUES(glob_rec_kandoouser.cmpy_code,
		                             p_acct_code,
		                             l_old_limit_amt,
		                             0,
		                             today,
		                             glob_rec_kandoouser.sign_on_code)

	DELETE FROM fundsapproved
	WHERE acct_code = p_acct_code
	AND cmpy_code = glob_rec_kandoouser.cmpy_code



#                  SELECT limit_amt INTO l_old_limit_amt FROM fundsapproved
#                   WHERE cmpy_code = l_rec_fundsapproved.cmpy_code
#                     AND acct_code = l_rec_fundsapproved.acct_code
#                  INSERT INTO fundaudit VALUES(glob_rec_kandoouser.cmpy_code,
#                                               glob_arr_rec_coa[l_idx].acct_code,
#                                               l_old_limit_amt,
#                                               0,
#                                               today,
#                                               glob_rec_kandoouser.sign_on_code)
#                  DELETE FROM fundsapproved
#                   WHERE acct_code = glob_arr_rec_coa[l_idx].acct_code
#                     AND cmpy_code = glob_rec_kandoouser.cmpy_code


	
	IF sqlca.sqlcode < 0 THEN   		                                                                                        
		LET l_sql_stmt_status = -1		                                                                                              	
	ELSE		                                                                                                                    
		LET l_sql_stmt_status=0		                                                                                                
	END IF		             
	                                                                                                     
	RETURN l_sql_stmt_status	
		  
END FUNCTION	         
############################################################
# END FUNCTION db_coa_delete(p_ui_mode,p_confirm,p_acct_code)
############################################################


########################################################################################
# FUNCTION db_coa_get_lookup(pCoaCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Coa code acct_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL db_coa_get_lookupSearchDataSource(recCoaFilter.*) RETURNING arrCoaList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Coa Code acct_code
#
# Example:
# 			LET pr_Coa.acct_code = db_coa_get_lookup(pr_Coa.acct_code)
########################################################################################
FUNCTION db_coa_get_lookup(pCoaCode)
	DEFINE pCoaCode LIKE Coa.acct_code
	DEFINE arrCoaList DYNAMIC ARRAY OF t_recCoa
	DEFINE recCoaSearch OF t_recCoaSearch	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wCoaLookup WITH FORM "G116"   # used to be "db_coa_get_lookup" (G116 or G117 will be used)

	CALL comboList_groupCode("group_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
	CALL comboList_groupCode("filter_group_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 

	CALL db_coa_get_lookupSearchDataSource(recCoaSearch.*) RETURNING arrCoaList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recCoaSearch.* WITHOUT DEFAULTS 
			
		ON ACTION "UPDATE-FILTER"
			CALL db_coa_get_lookupSearchDataSource(recCoaSearch.*) RETURNING arrCoaList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrCoaList TO scCoaList.* 
		BEFORE ROW
			IF arrCoaList.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pCoaCode = arrCoaList[idx].acct_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recCoaSearch.filter_any_field IS NOT NULL
			OR recCoaSearch.filter_group_code IS NOT NULL
		THEN
			LET recCoaSearch.filter_any_field = NULL

			LET recCoaSearch.filter_group_code = NULL
			CALL db_coa_get_lookupSearchDataSource(recCoaSearch.*) RETURNING arrCoaList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_acct_code"
		IF recCoaSearch.filter_any_field IS NOT NULL THEN
			LET recCoaSearch.filter_any_field = NULL
			CALL db_coa_get_lookupSearchDataSource(recCoaSearch.*) RETURNING arrCoaList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_group_code"
		IF recCoaSearch.filter_group_code IS NOT NULL THEN		
			LET recCoaSearch.filter_group_code = NULL
			CALL db_coa_get_lookupSearchDataSource(recCoaSearch.*) RETURNING arrCoaList
			CALL ui.interface.refresh()
		END IF			
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wCoaLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pCoaCode	
END FUNCTION				
########################################################################################
# END FUNCTION db_coa_get_lookup(pCoaCode)
########################################################################################


########################################################################################
# FUNCTION db_coa_get_lookupFilterDataSource(pRecCoaFilter)
#-------------------------------------------------------
# CALLS db_coa_get_lookupFilterDataSourceCursor(pRecCoaFilter) with the CoaFilter data TO get a CURSOR
# Returns the Coa list array arrCoaList
########################################################################################
FUNCTION db_coa_get_lookupFilterDataSource(pRecCoaFilter)
	DEFINE pRecCoaFilter OF t_recCoaFilter
	DEFINE recCoa OF t_recCoa
	DEFINE arrCoaList DYNAMIC ARRAY OF t_recCoa 
	DEFINE c_Coa CURSOR
	DEFINE retError SMALLINT
		
	CALL db_coa_get_lookupFilterDataSourceCursor(pRecCoaFilter.*) RETURNING c_Coa
	
	CALL arrCoaList.CLEAR()

	CALL c_Coa.SetResults(recCoa.*)  --define variable for result output

	
	LET retError = c_Coa.OPEN()
	

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Coa.FetchNext()=0)
		CALL arrCoaList.append([recCoa.acct_code, recCoa.desc_text,recCoa.group_code])
	END WHILE	

	END IF
	
	IF arrCoaList.getSize() = 0 THEN
		ERROR "No COA's found with the specified filter criteria"
	END IF
	
	RETURN arrCoaList
END FUNCTION	
########################################################################################
# END FUNCTION db_coa_get_lookupFilterDataSource(pRecCoaFilter)
########################################################################################


########################################################################################
# FUNCTION db_coa_get_lookupSearchDataSource(pRecCoaFilter)
#-------------------------------------------------------
# CALLS db_coa_get_lookupSearchDataSourceCursor(pRecCoaFilter) with the CoaFilter data TO get a CURSOR
# Returns the Coa list array arrCoaList
########################################################################################
FUNCTION db_coa_get_lookupSearchDataSource(p_recCoaSearch)
	DEFINE p_recCoaSearch OF t_recCoaSearch	
	DEFINE recCoa OF t_recCoa
	DEFINE arrCoaList DYNAMIC ARRAY OF t_recCoa 
	DEFINE c_Coa CURSOR
	DEFINE retError SMALLINT	
	CALL db_coa_get_lookupSearchDataSourceCursor(p_recCoaSearch.*) RETURNING c_Coa
	
	CALL arrCoaList.CLEAR()

	CALL c_Coa.SetResults(recCoa.*)  --define variable for result output

	
	LET retError = c_Coa.OPEN()
	

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Coa.FetchNext()=0)
		CALL arrCoaList.append([recCoa.acct_code, recCoa.desc_text,recCoa.group_code])
	END WHILE	

	END IF
	
	IF arrCoaList.getSize() = 0 THEN
		ERROR "No COA's found with the specified filter criteria"
	END IF
	
	RETURN arrCoaList
END FUNCTION
########################################################################################
# END FUNCTION db_coa_get_lookupSearchDataSource(pRecCoaFilter)
########################################################################################


########################################################################################
# FUNCTION db_coa_get_lookup_filter(pCoaCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Coa code acct_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL db_coa_get_lookupFilterDataSource(recCoaFilter.*) RETURNING arrCoaList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Coa Code acct_code
#
# Example:
# 			LET pr_Coa.acct_code = db_coa_get_lookup(pr_Coa.acct_code)
########################################################################################
FUNCTION db_coa_get_lookup_filter(pCoaCode)
	DEFINE pCoaCode LIKE Coa.acct_code
	DEFINE arrCoaList DYNAMIC ARRAY OF t_recCoa
	DEFINE recCoaFilter OF t_recCoaFilter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wCoaLookup WITH FORM "G116"   # used to be "db_coa_get_lookup_filter" (G116 or G117 will be used)

	CALL comboList_groupCode("group_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
	CALL comboList_groupCode("filter_group_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 

	CALL db_coa_get_lookupFilterDataSource(recCoaFilter.*) RETURNING arrCoaList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recCoaFilter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL db_coa_get_lookupFilterDataSource(recCoaFilter.*) RETURNING arrCoaList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrCoaList TO scCoaList.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pCoaCode = arrCoaList[idx].acct_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recCoaFilter.filter_acct_code IS NOT NULL
			OR recCoaFilter.filter_desc_text IS NOT NULL
			OR recCoaFilter.filter_group_code IS NOT NULL
		THEN
			LET recCoaFilter.filter_acct_code = NULL
			LET recCoaFilter.filter_desc_text = NULL
			LET recCoaFilter.filter_group_code = NULL
			CALL db_coa_get_lookupFilterDataSource(recCoaFilter.*) RETURNING arrCoaList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_acct_code"
		IF recCoaFilter.filter_acct_code IS NOT NULL THEN
			LET recCoaFilter.filter_acct_code = NULL
			CALL db_coa_get_lookupFilterDataSource(recCoaFilter.*) RETURNING arrCoaList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_desc_text"
		IF recCoaFilter.filter_desc_text IS NOT NULL THEN
			LET recCoaFilter.filter_desc_text = NULL
			CALL db_coa_get_lookupFilterDataSource(recCoaFilter.*) RETURNING arrCoaList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_group_code"
		IF recCoaFilter.filter_group_code IS NOT NULL THEN		
			LET recCoaFilter.filter_group_code = NULL
			CALL db_coa_get_lookupFilterDataSource(recCoaFilter.*) RETURNING arrCoaList
			CALL ui.interface.refresh()
		END IF			
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wCoaLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pCoaCode	
END FUNCTION				
########################################################################################
# END FUNCTION db_coa_get_lookup_filter(pCoaCode)
########################################################################################

		
########################################################################################
# FUNCTION db_coa_get_lookupFilterDataSourceCursor(pRecCoaFilter)
#-------------------------------------------------------
# Returns the Coa CURSOR for the lookup query
########################################################################################
FUNCTION db_coa_get_lookupFilterDataSourceCursor(pRecCoaFilter)
	DEFINE pRecCoaFilter OF t_recCoaFilter
	DEFINE sqlQuery STRING
	DEFINE c_Coa CURSOR
	
	LET sqlQuery =	"SELECT ",
									"coa.acct_code, ", 
									"coa.desc_text, ",
									"coa.group_code ", 
									"FROM coa ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF pRecCoaFilter.filter_acct_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND acct_code LIKE '", pRecCoaFilter.filter_acct_code CLIPPED, "%' "  
	END IF									

	IF pRecCoaFilter.filter_desc_text IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND desc_text LIKE '", pRecCoaFilter.filter_desc_text CLIPPED, "%' "  
	END IF	
	
	IF pRecCoaFilter.filter_group_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND group_code LIKE '", pRecCoaFilter.filter_group_code CLIPPED, "%' "  
	END IF	
			
	LET sqlQuery = sqlQuery, " ORDER BY acct_code"

	CALL c_coa.DECLARE(sqlQuery)
		
	RETURN c_coa
END FUNCTION
########################################################################################
# END FUNCTION db_coa_get_lookupFilterDataSourceCursor(pRecCoaFilter)
########################################################################################


########################################################################################
# FUNCTION db_coa_get_lookupSearchDataSourceCursor(p_RecCoaSearch)
#-------------------------------------------------------
# Returns the Coa CURSOR for the lookup query
########################################################################################
FUNCTION db_coa_get_lookupSearchDataSourceCursor(p_RecCoaSearch)
	DEFINE p_RecCoaSearch OF t_recCoaSearch  
	DEFINE sqlQuery STRING
	DEFINE c_Coa CURSOR
	
	LET sqlQuery =	"SELECT ",
									"coa.acct_code, ", 
									"coa.desc_text, ",
									"coa.group_code ", 
									"FROM coa ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
	
	IF p_RecCoaSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((acct_code LIKE '", p_RecCoaSearch.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR desc_text LIKE '",   p_RecCoaSearch.filter_any_field CLIPPED, "%') "  
		#LET sqlQuery = sqlQuery, "OR group_code LIKE '",  p_RecCoaSearch.filter_any_field CLIPPED, "%' )"  						
	END IF

	
	IF p_RecCoaSearch.filter_group_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND group_code LIKE '", p_RecCoaSearch.filter_group_code CLIPPED, "%' "  
	END IF	

	IF p_RecCoaSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, "ORDER BY acct_code"

	CALL c_coa.DECLARE(sqlQuery) #CURSOR FOR COA
	
	RETURN c_coa
END FUNCTION
########################################################################################
# END FUNCTION db_coa_get_lookupSearchDataSourceCursor(p_RecCoaSearch)
########################################################################################

	
########################################################################
# FUNCTION acct_type(p_cmpy, p_acct_code, p_type_ind, p_verbose_flag)
#
# FUNCTION acct_type  - Replaces bk_ac_ck - Checks FOR correct type of account
#          parameters - p_cmpy
#                       p_acct_code  (Account TO be checked)
#                       p_type_ind   (Type of account required -
#                                      "1" = Can Be Normal Transaction
#                                      "2" = Can Be Control Bank
#                                      "3" = Can Be Control Other
#                                      "4" = Is Control Bank
#                       p_verbose_flag ("Y" DISPLAY errors
#                                        "N" No Display
#          returns TRUE IF passed account IS correct FOR p_type_ind
#          returns FALSE OTHERWISE.
########################################################################
--acct_type(glob_rec_kandoouser.cmpy_code,l_rec_coa.acct_code,glob_fv_cash_book,"Y")
FUNCTION acct_type(p_cmpy, p_acct_code, p_type_ind, p_verbose_flag) #KA,KAU-002-1200,4
	DEFINE p_cmpy               LIKE bank.cmpy_code
	DEFINE p_acct_code       LIKE bank.acct_code ## GL account we are checking
	DEFINE p_verbose_flag    CHAR(1) ## Y Display, N Don't Display
	DEFINE p_type_ind        CHAR(1)
	DEFINE l_rec_arparms RECORD LIKE arparms.*
	DEFINE l_rec_apparms RECORD LIKE apparms.*
	DEFINE l_msgresp LIKE language.yes_flag   

	#HuHo
	IF p_verbose_flag <> "Y" AND p_verbose_flag <> "N" THEN
		LET p_verbose_flag = "N"
	END IF 

	IF get_debug() THEN
		DISPLAY "!!!!"
		DISPLAY "p_type_ind=", p_type_ind
	END IF

   CASE p_type_ind
   
			-----------------------------------------------------------------------------------------------
   
   		# COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION = 1
      WHEN COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION # Can NOT be control account
         SELECT *
            FROM glparms
            WHERE cmpy_code = p_cmpy
             AND key_code = "1"
             AND cash_book_flag = "Y"
         IF sqlca.sqlcode = 0 THEN
	            SELECT unique 1
	               FROM bank
	               WHERE cmpy_code = p_cmpy
	                AND acct_code = p_acct_code
            IF sqlca.sqlcode = 0 THEN
               IF p_verbose_flag = "Y"
                OR p_verbose_flag IS NULL THEN
                  ERROR kandoomsg2("G", 9111, "")       #9111 Bank Acount Codes must NOT be used
               END IF
               RETURN FALSE
            END IF
         END IF

         SELECT * INTO l_rec_arparms.*
            FROM arparms
            WHERE cmpy_code = p_cmpy
             AND gl_flag = "Y"

         IF sqlca.sqlcode = 0 THEN
            IF p_acct_code = l_rec_arparms.ar_acct_code
             OR p_acct_code = l_rec_arparms.cash_acct_code THEN
               IF p_verbose_flag = "Y"
                OR p_verbose_flag IS NULL THEN
                  ERROR kandoomsg2("G", 9202, "")    #9111 Subsidiary Control Account Must Not Be Used
               END IF
               RETURN FALSE
            END IF
            SELECT unique 1
               FROM customertype
               WHERE cmpy_code = p_cmpy
                AND ar_acct_code = p_acct_code
            IF sqlca.sqlcode = 0 THEN
               IF p_verbose_flag = "Y"
                OR p_verbose_flag IS NULL THEN
                  ERROR kandoomsg2("G", 9202, "")        #9111 Subsidiary Control Account Must Not Be Used
               END IF
               RETURN FALSE
            END IF
         END IF

         SELECT * INTO l_rec_apparms.*
            FROM apparms
            WHERE cmpy_code = p_cmpy
             AND gl_flag = "Y"

         IF sqlca.sqlcode = 0 THEN
            IF p_acct_code = l_rec_apparms.pay_acct_code
             OR p_acct_code = l_rec_apparms.bank_acct_code THEN
               IF p_verbose_flag = "Y"
                OR p_verbose_flag IS NULL THEN
                  LET l_msgresp = kandoomsg("G", 9202, "")       #9111 Subsidiary Control Account Must Not Be Used
               END IF
               RETURN FALSE
            END IF
            SELECT unique 1
               FROM vendortype
               WHERE cmpy_code = p_cmpy
                AND pay_acct_code = p_acct_code
            IF sqlca.sqlcode = 0 THEN
               IF p_verbose_flag = "Y"
                OR p_verbose_flag IS NULL THEN
                  LET l_msgresp = kandoomsg("G", 9202, "")        #9111 Subsidiary Control Account Must Not Be Used
               END IF
               RETURN FALSE
            END IF
         END IF

         SELECT *
            FROM inparms
            WHERE cmpy_code = p_cmpy
             AND gl_post_flag = "Y"

         IF sqlca.sqlcode = 0 THEN
            SELECT unique 1
               FROM category
               WHERE cmpy_code = p_cmpy
                AND stock_acct_code = p_acct_code

            IF sqlca.sqlcode = 0 THEN
               IF p_verbose_flag = "Y"
                OR p_verbose_flag IS NULL THEN
                  ERROR kandoomsg2("G", 9218, "")#9218 Inventory Account must NOT be used
                  CALL fgl_winmessage("Account can not be used","Inventory Account must NOT be used\nIZP and IZ1)","error")
                  
               END IF

               RETURN FALSE
            END IF
         END IF

			-------------------------------------------------------------------------------------------------------

			# COA_ACCOUNT_REQUIRED_CAN_BE_CONTROL_BANK = 2
      WHEN COA_ACCOUNT_REQUIRED_CAN_BE_CONTROL_BANK # Can NOT be non bank control account
         SELECT * INTO l_rec_arparms.*
            FROM arparms
            WHERE cmpy_code = p_cmpy
             AND gl_flag = "Y"
         IF sqlca.sqlcode = 0 THEN
            IF p_acct_code = l_rec_arparms.ar_acct_code THEN
               IF p_verbose_flag = "Y"
                OR p_verbose_flag IS NULL THEN
                  ERROR kandoomsg2("G", 9202, "")     #9111 Subsidiary Control Account Must Not Be Used
               END IF
               RETURN FALSE
            END IF
            
            SELECT unique 1
               FROM customertype
               WHERE cmpy_code = p_cmpy
                AND ar_acct_code = p_acct_code
            IF sqlca.sqlcode = 0 THEN
               IF p_verbose_flag = "Y"
                OR p_verbose_flag IS NULL THEN
                  LET l_msgresp = kandoomsg("G", 9202, "")      #9111 Subsidiary Control Account Must Not Be Used
               END IF
               RETURN FALSE
            END IF
         END IF

         SELECT * INTO l_rec_apparms.*
            FROM apparms
            WHERE cmpy_code = p_cmpy
             AND gl_flag = "Y"
         IF sqlca.sqlcode = 0 THEN
            IF p_acct_code = l_rec_apparms.pay_acct_code THEN
               IF p_verbose_flag = "Y"
                OR p_verbose_flag IS NULL THEN
                  LET l_msgresp = kandoomsg("G", 9202, "")          #9111 Subsidiary Control Account Must Not Be Used
               END IF
               RETURN FALSE
            END IF
            SELECT unique 1
               FROM vendortype
               WHERE cmpy_code = p_cmpy
                AND pay_acct_code = p_acct_code
            IF sqlca.sqlcode = 0 THEN
               IF p_verbose_flag = "Y"
                OR p_verbose_flag IS NULL THEN
                  LET l_msgresp = kandoomsg("G", 9202, "")     #9111 Subsidiary Control Account Must Not Be Used
               END IF
               RETURN FALSE
            END IF
         END IF

         SELECT *
            FROM inparms
            WHERE cmpy_code = p_cmpy
             AND gl_post_flag = "Y"
         IF sqlca.sqlcode = 0 THEN
            SELECT unique 1
               FROM category
               WHERE cmpy_code = p_cmpy
                AND stock_acct_code = p_acct_code
            IF sqlca.sqlcode = 0 THEN
               IF p_verbose_flag = "Y"
                OR p_verbose_flag IS NULL THEN
                  #LET l_msgresp = kandoomsg("G", 9218, "")
                  CALL fgl_winmessage("Account can not be used","Inventory Account must NOT be used\nIZP and IZ1)","error")                  
                  #9218 Inventory Account must NOT be used           
               END IF
               RETURN FALSE
            END IF
         END IF
         
			-----------------------------------------------------------------------------------------------

			# COA_ACCOUNT_REQUIRED_CAN_BE_CONTROL_OTHER= 3
      WHEN COA_ACCOUNT_REQUIRED_CAN_BE_CONTROL_OTHER # Can NOT be bank control account
         SELECT *
            FROM glparms
            WHERE cmpy_code = p_cmpy
             AND key_code = "1"
             AND cash_book_flag = "Y"

         IF sqlca.sqlcode = 0 THEN
            SELECT unique 1
               FROM bank
               WHERE cmpy_code = p_cmpy
                AND acct_code = p_acct_code
            IF sqlca.sqlcode = 0 THEN
               IF p_verbose_flag = "Y"
                OR p_verbose_flag IS NULL THEN
                  LET l_msgresp = kandoomsg("G", 9111, "")
                  #9111 Bank Acount Codes must NOT be used
               END IF
               RETURN FALSE
            END IF
         END IF
         
			-----------------------------------------------------------------------------------------------
			# COA_ACCOUNT_REQUIRED_IS_CONTROL_BANK = 4

      WHEN COA_ACCOUNT_REQUIRED_IS_CONTROL_BANK # Must Be control bank account
         SELECT *
            FROM glparms
            WHERE cmpy_code = p_cmpy
             AND key_code = "1"
             AND cash_book_flag = "Y"
         IF sqlca.sqlcode = 0 THEN #0=Success/found 100=not found
            SELECT unique 1
               FROM bank
               WHERE cmpy_code = p_cmpy
                AND acct_code = p_acct_code
            IF sqlca.sqlcode = 0 THEN  #seems it returns TRUE, if this account_code is linked to a bank
               RETURN TRUE
#            ELSE
#            	ERROR "Bank for cmpy_code = ", trim(p_cmpy), " and acct_code = ", trim(p_acct_code), " not found !"
            END IF
         END IF
         IF p_verbose_flag = "Y"
          OR p_verbose_flag IS NULL THEN
           	ERROR "Bank for cmpy_code = ", trim(p_cmpy), " and acct_code = ", trim(p_acct_code), " not found !"
						SLEEP 3          
            ERROR kandoomsg2("G", 9204, "")        #9111 Bank Acount Codes NOT found
         END IF
         
         RETURN FALSE

   END CASE


   RETURN TRUE
END FUNCTION
########################################################################
# END FUNCTION acct_type(p_cmpy, p_acct_code, p_type_ind, p_verbose_flag)
########################################################################
		
		
########################################################################
# FUNCTION db_coa_acct_type_for_coa_list(p_cmpy, p_acct_code, p_type_ind, p_verbose_flag)
#
# FUNCTION acct_type  - Replaces bk_ac_ck - Checks FOR correct type of account
#          parameters - p_cmpy
#                       p_acct_code  (Account TO be checked)
#                       p_type_ind   (Type of account required -
#                                      "1" = Can Be Normal Transaction
#                                      "2" = Can Be Control Bank
#                                      "3" = Can Be Control Other
#                                      "4" = Is Control Bank
#                       p_verbose_flag ("Y" DISPLAY errors
#                                        "N" No Display
#          returns TRUE IF passed account IS correct FOR p_type_ind
#          returns FALSE OTHERWISE.
########################################################################
FUNCTION db_coa_acct_type_for_coa_list(p_cmpy, p_acct_code, p_type_ind, p_verbose_flag)
	DEFINE p_cmpy               LIKE bank.cmpy_code
	DEFINE p_acct_code       LIKE bank.acct_code ## GL account we are checking
	DEFINE p_verbose_flag    CHAR(1) ## Y Display, N Don't Display
	DEFINE p_type_ind        CHAR(1)
	DEFINE l_rec_arparms RECORD LIKE arparms.*
	DEFINE l_rec_apparms RECORD LIKE apparms.*
	DEFINE l_msgresp LIKE language.yes_flag   

	#HuHo
	IF p_verbose_flag <> "Y" AND p_verbose_flag <> "N" THEN
		LET p_verbose_flag = "N"
	END IF 

   CASE p_type_ind
   
			-----------------------------------------------------------------------------------------------
   
   		# COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION = 1
      WHEN COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION # Can NOT be control account
         SELECT *
            FROM glparms
            WHERE cmpy_code = p_cmpy
             AND key_code = "1"
             AND cash_book_flag = "Y"
         IF sqlca.sqlcode = 0 THEN
            SELECT unique 1
               FROM bank
               WHERE cmpy_code = p_cmpy
                AND acct_code = p_acct_code
            IF sqlca.sqlcode = 0 THEN
 #              IF p_verbose_flag = "Y"
 #               OR p_verbose_flag IS NULL THEN
 #                 ERROR kandoomsg2("G", 9111, "")    #9111 Bank Acount Codes must NOT be used
 #              END IF
               RETURN FALSE
            END IF
         END IF

         SELECT * INTO l_rec_arparms.*
            FROM arparms
            WHERE cmpy_code = p_cmpy
             AND gl_flag = "Y"

         IF sqlca.sqlcode = 0 THEN
            IF p_acct_code = l_rec_arparms.ar_acct_code
             OR p_acct_code = l_rec_arparms.cash_acct_code THEN
#               IF p_verbose_flag = "Y"
#                OR p_verbose_flag IS NULL THEN
#                  ERROR kandoomsg2("G", 9202, "")  #9111 Subsidiary Control Account Must Not Be Used
#               END IF
               RETURN FALSE
            END IF
            SELECT unique 1
               FROM customertype
               WHERE cmpy_code = p_cmpy
                AND ar_acct_code = p_acct_code
            IF sqlca.sqlcode = 0 THEN
 #              IF p_verbose_flag = "Y"
 #               OR p_verbose_flag IS NULL THEN
 #                 ERROR kandoomsg2("G", 9202, "")    #9111 Subsidiary Control Account Must Not Be Used
 #              END IF
               RETURN FALSE
            END IF
         END IF

------------------------------------------
         SELECT * INTO l_rec_apparms.*
            FROM apparms
            WHERE cmpy_code = p_cmpy
             AND gl_flag = "Y"

         IF sqlca.sqlcode = 0 THEN
            IF p_acct_code = l_rec_apparms.pay_acct_code
             OR p_acct_code = l_rec_apparms.bank_acct_code THEN
 #              IF p_verbose_flag = "Y"
 #               OR p_verbose_flag IS NULL THEN
 #                 ERROR kandoomsg2("G", 9202, "")  #9111 Subsidiary Control Account Must Not Be Used
 #              END IF
               RETURN FALSE
            END IF
            SELECT unique 1
               FROM vendortype
               WHERE cmpy_code = p_cmpy
                AND pay_acct_code = p_acct_code
            IF sqlca.sqlcode = 0 THEN
 #              IF p_verbose_flag = "Y"
 #               OR p_verbose_flag IS NULL THEN
 #                 ERROR kandoomsg2("G", 9202, "")  #9111 Subsidiary Control Account Must Not Be Used
 #              END IF

               RETURN FALSE
            END IF
         END IF

         SELECT *
            FROM inparms
            WHERE cmpy_code = p_cmpy
             AND gl_post_flag = "Y"

         IF sqlca.sqlcode != 0 THEN
            SELECT unique 1
               FROM category
               WHERE cmpy_code = p_cmpy
                AND stock_acct_code = p_acct_code

            IF sqlca.sqlcode = 0 THEN
#               IF p_verbose_flag = "Y"
#                OR p_verbose_flag IS NULL THEN
#                  LET l_msgresp = kandoomsg("G", 9218, "")   #9218 Inventory Account must NOT be used
#               END IF

               RETURN FALSE
            END IF
         END IF

			-------------------------------------------------------------------------------------------------------

			# COA_ACCOUNT_REQUIRED_CAN_BE_CONTROL_BANK = 2
      WHEN COA_ACCOUNT_REQUIRED_CAN_BE_CONTROL_BANK # Can NOT be non bank control account
         SELECT * INTO l_rec_arparms.*
            FROM arparms
            WHERE cmpy_code = p_cmpy
             AND gl_flag = "Y"
         IF sqlca.sqlcode = 0 THEN
            IF p_acct_code = l_rec_arparms.ar_acct_code THEN
#               IF p_verbose_flag = "Y"
#                OR p_verbose_flag IS NULL THEN
#                  LET l_msgresp = kandoomsg("G", 9202, "")    #9111 Subsidiary Control Account Must Not Be Used
#               END IF
               RETURN FALSE
            END IF
            SELECT unique 1
               FROM customertype
               WHERE cmpy_code = p_cmpy
                AND ar_acct_code = p_acct_code
            IF sqlca.sqlcode = 0 THEN
#               IF p_verbose_flag = "Y"
#                OR p_verbose_flag IS NULL THEN
#                  ERROR kandoomsg2("G", 9202, "")    #9111 Subsidiary Control Account Must Not Be Used
#               END IF
               RETURN FALSE
            END IF
         END IF

         SELECT * INTO l_rec_apparms.*
            FROM apparms
            WHERE cmpy_code = p_cmpy
             AND gl_flag = "Y"
         IF sqlca.sqlcode = 0 THEN
            IF p_acct_code = l_rec_apparms.pay_acct_code THEN
#               IF p_verbose_flag = "Y"
#                OR p_verbose_flag IS NULL THEN
#                  ERROR kandoomsg2("G", 9202, "")   #9111 Subsidiary Control Account Must Not Be Used
#               END IF
               RETURN FALSE
            END IF
            SELECT unique 1
               FROM vendortype
               WHERE cmpy_code = p_cmpy
                AND pay_acct_code = p_acct_code
            IF sqlca.sqlcode = 0 THEN
#               IF p_verbose_flag = "Y"
#                OR p_verbose_flag IS NULL THEN
#                  ERROR kandoomsg2("G", 9202, "")    #9111 Subsidiary Control Account Must Not Be Used
#               END IF
               RETURN FALSE
            END IF
         END IF

         SELECT *
            FROM inparms
            WHERE cmpy_code = p_cmpy
             AND gl_post_flag = "Y"
         IF sqlca.sqlcode = 0 THEN
            SELECT unique 1
               FROM category
               WHERE cmpy_code = p_cmpy
                AND stock_acct_code = p_acct_code
            IF sqlca.sqlcode = 0 THEN
#               IF p_verbose_flag = "Y"
#                OR p_verbose_flag IS NULL THEN
#                  LET l_msgresp = kandoomsg("G", 9218, "")   #9218 Inventory Account must NOT be used           
#               END IF
               RETURN FALSE
            END IF
         END IF
         
			-----------------------------------------------------------------------------------------------

			# COA_ACCOUNT_REQUIRED_CAN_BE_CONTROL_OTHER= 3
      WHEN COA_ACCOUNT_REQUIRED_CAN_BE_CONTROL_OTHER # Can NOT be bank control account
         SELECT *
            FROM glparms
            WHERE cmpy_code = p_cmpy
             AND key_code = "1"
             AND cash_book_flag = "Y"

         IF sqlca.sqlcode = 0 THEN
            SELECT unique 1
               FROM bank
               WHERE cmpy_code = p_cmpy
                AND acct_code = p_acct_code
            IF sqlca.sqlcode = 0 THEN
#               IF p_verbose_flag = "Y"
#                OR p_verbose_flag IS NULL THEN
#                  LET l_msgresp = kandoomsg("G", 9111, "")    #9111 Bank Acount Codes must NOT be used
#               END IF
               RETURN FALSE
            END IF
         END IF
         
			-----------------------------------------------------------------------------------------------
			# COA_ACCOUNT_REQUIRED_IS_CONTROL_BANK = 4

      WHEN COA_ACCOUNT_REQUIRED_IS_CONTROL_BANK # Must Be control bank account
         SELECT *
            FROM glparms
            WHERE cmpy_code = p_cmpy
             AND key_code = "1"
             AND cash_book_flag = "Y"
         IF sqlca.sqlcode = 0 THEN
            SELECT unique 1
               FROM bank
               WHERE cmpy_code = p_cmpy
                AND acct_code = p_acct_code
            IF sqlca.sqlcode = 0 THEN
               RETURN TRUE
            END IF
         END IF
#         IF p_verbose_flag = "Y"
#          OR p_verbose_flag IS NULL THEN
#            ERROR kandoomsg2("G", 9204, "")   #9111 Bank Acount Codes NOT found
#         END IF
         
         RETURN FALSE

   END CASE

   RETURN TRUE
END FUNCTION
########################################################################
# END FUNCTION db_coa_acct_type_for_coa_list(p_cmpy, p_acct_code, p_type_ind, p_verbose_flag)
########################################################################

# get full record, no GUI involved
FUNCTION coa_get_full_record(p_acct_code)
	DEFINE p_acct_code LIKE coa.acct_code
	DEFINE l_rec_coa RECORD LIKE coa.*

	WHENEVER SQLERROR CONTINUE
      SELECT *
        INTO l_rec_coa.*
        FROM coa
       WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
       	AND acct_code= p_acct_code
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	RETURN sqlca.sqlcode,l_rec_coa.*	
END FUNCTION # category_get_full_record

# get full record, no GUI involved
FUNCTION coa_get_account_name(p_acct_code)
	DEFINE p_acct_code LIKE coa.acct_code
	DEFINE l_account_name LIKE coa.desc_text

	WHENEVER SQLERROR CONTINUE
      SELECT desc_text
        INTO l_account_name
        FROM coa
       WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
       	AND acct_code= p_acct_code
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	
	RETURN sqlca.sqlcode,l_account_name	
END FUNCTION # category_get_full_record

FUNCTION check_prykey_exists_coa(p_cmpy_code,p_acct_code)
	DEFINE p_cmpy_code LIKE coa.cmpy_code
	DEFINE p_acct_code LIKE coa.acct_code
	DEFINE prykey_exists BOOLEAN
	# initialize prykey_exists to false. If key is found, it is set to 'true'
	LET prykey_exists = FALSE
	SELECT TRUE
	INTO prykey_exists
	FROM coa
	WHERE cmpy_code = p_cmpy_code
	AND acct_code = p_acct_code 

	RETURN prykey_exists
END FUNCTION #check_prykey_exists_arparms()
