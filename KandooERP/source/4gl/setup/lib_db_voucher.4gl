GLOBALS "lib_db_globals.4gl"

# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getVoucherCount()
# FUNCTION voucherLookupFilterDataSourceCursor(pRecVoucherFilter)
# FUNCTION voucherLookupSearchDataSourceCursor(p_RecVoucherSearch)
# FUNCTION VoucherLookupFilterDataSource(pRecVoucherFilter)
# FUNCTION voucherLookup_filter(pVoucherCode)
# FUNCTION import_voucher()
# FUNCTION exist_voucherRec(p_cmpy_code, p_vouch_code)
# FUNCTION delete_voucher_all()
# FUNCTION voucherMenu()						-- Offer different OPTIONS of this library via a menu

# Voucher record types
	DEFINE t_recVoucher  
		TYPE AS RECORD
			vouch_code LIKE voucher.vouch_code,
			inv_text LIKE voucher.inv_text
		END RECORD 

	DEFINE t_recVoucherFilter  
		TYPE AS RECORD
			filter_vouch_code LIKE voucher.vouch_code,
			filter_inv_text LIKE voucher.inv_text
		END RECORD 

	DEFINE t_recVoucherSearch  
		TYPE AS RECORD
			filter_any_field STRING
		END RECORD 		

	DEFINE t_recVoucher_noCmpyId 
		TYPE AS RECORD 
    vend_code LIKE voucher.vend_code,
    vouch_code LIKE voucher.vouch_code,
    inv_text LIKE voucher.inv_text,
    po_num LIKE voucher.po_num,
    vouch_date LIKE voucher.vouch_date,
    entry_code LIKE voucher.entry_code,
    entry_date LIKE voucher.entry_date,
    sales_text LIKE voucher.sales_text,
    term_code LIKE voucher.term_code,
    tax_code LIKE voucher.tax_code,
    goods_amt LIKE voucher.goods_amt,
    tax_amt LIKE voucher.tax_amt,
    total_amt LIKE voucher.total_amt,
    paid_amt LIKE voucher.paid_amt,
    dist_qty LIKE voucher.dist_qty,
    dist_amt LIKE voucher.dist_amt,
    poss_disc_amt LIKE voucher.poss_disc_amt,
    taken_disc_amt LIKE voucher.taken_disc_amt,
    paid_date LIKE voucher.paid_date,
    due_date LIKE voucher.due_date,
    disc_date LIKE voucher.disc_date,
    hist_flag LIKE voucher.hist_flag,
    jour_num LIKE voucher.jour_num,
    post_flag LIKE voucher.post_flag,
    year_num LIKE voucher.year_num,
    period_num LIKE voucher.period_num,
    pay_seq_num LIKE voucher.pay_seq_num,
    line_num LIKE voucher.line_num,
    com1_text LIKE voucher.com1_text,
    com2_text LIKE voucher.com2_text,
    hold_code LIKE voucher.hold_code,
    jm_post_flag LIKE voucher.jm_post_flag,
    approved_by_code LIKE voucher.approved_by_code,
    approved_code LIKE voucher.approved_code,
    approved_date LIKE voucher.approved_date,
    split_from_num LIKE voucher.split_from_num,
    currency_code LIKE voucher.currency_code,
    conv_qty LIKE voucher.conv_qty,
    post_date LIKE voucher.post_date,
    source_ind LIKE voucher.source_ind,
    source_text LIKE voucher.source_text,
    withhold_tax_ind LIKE voucher.withhold_tax_ind,
    source_code LIKE voucher.source_code,
    disp_code LIKE voucher.disp_code,
    batch_num LIKE voucher.batch_num
	END RECORD	


	
########################################################################################
# FUNCTION voucherMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION voucherMenu()
	MENU
		ON ACTION "Import"
			CALL import_voucher()
		ON ACTION "Export"
			CALL unload_voucher()
		#ON ACTION "Import"
		#	CALL import_voucher()
		ON ACTION "Delete All"
			CALL delete_voucher_all()
		ON ACTION "Count"
			CALL getVoucherCount() --Count all voucher rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getVoucherCount()
#-------------------------------------------------------
# Returns the number of Voucher entries for the current company
########################################################################################
FUNCTION getVoucherCount()
	DEFINE ret_VoucherCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_Voucher CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM Voucher ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_Voucher.DECLARE(sqlQuery) #CURSOR FOR getVoucher
	CALL c_Voucher.SetResults(ret_VoucherCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_Voucher.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_VoucherCount = -1
	ELSE
		CALL c_Voucher.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of Vouchers:", trim(ret_VoucherCount) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("Voucher Count", tempMsg,"info") 	
	END IF

	RETURN ret_VoucherCount
END FUNCTION

########################################################################################
# FUNCTION voucherLookupFilterDataSourceCursor(pRecVoucherFilter)
#-------------------------------------------------------
# Returns the Voucher CURSOR for the lookup query
########################################################################################
FUNCTION voucherLookupFilterDataSourceCursor(pRecVoucherFilter)
	DEFINE pRecVoucherFilter OF t_recVoucherFilter
	DEFINE sqlQuery STRING
	DEFINE c_Voucher CURSOR
	
	LET sqlQuery =	"SELECT ",
									"voucher.vouch_code, ", 
									"voucher.inv_text ",
									"FROM voucher ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF pRecVoucherFilter.filter_vouch_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND vouch_code LIKE '", pRecVoucherFilter.filter_vouch_code CLIPPED, "%' "  
	END IF									

	IF pRecVoucherFilter.filter_inv_text IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND inv_text LIKE '", pRecVoucherFilter.filter_inv_text CLIPPED, "%' "  
	END IF	
	
			
	LET sqlQuery = sqlQuery, " ORDER BY vouch_code"

	CALL c_voucher.DECLARE(sqlQuery)
		
	RETURN c_voucher
END FUNCTION



########################################################################################
# voucherLookupSearchDataSourceCursor(p_RecVoucherSearch)
#-------------------------------------------------------
# Returns the Voucher CURSOR for the lookup query
########################################################################################
FUNCTION voucherLookupSearchDataSourceCursor(p_RecVoucherSearch)
	DEFINE p_RecVoucherSearch OF t_recVoucherSearch  
	DEFINE sqlQuery STRING
	DEFINE c_Voucher CURSOR
	
	LET sqlQuery =	"SELECT ",
									"voucher.vouch_code, ", 
									"voucher.inv_text ",
 
									"FROM voucher ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
	
	IF p_RecVoucherSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((vouch_code LIKE '", p_RecVoucherSearch.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR inv_text LIKE '",   p_RecVoucherSearch.filter_any_field CLIPPED, "%') "  
  						
	END IF


	IF p_RecVoucherSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, "ORDER BY vouch_code"

	CALL c_voucher.DECLARE(sqlQuery) #CURSOR FOR voucher
	
	RETURN c_voucher
END FUNCTION


########################################################################################
# FUNCTION VoucherLookupFilterDataSource(pRecVoucherFilter)
#-------------------------------------------------------
# CALLS VoucherLookupFilterDataSourceCursor(pRecVoucherFilter) with the VoucherFilter data TO get a CURSOR
# Returns the Voucher list array arrVoucherList
########################################################################################
FUNCTION VoucherLookupFilterDataSource(pRecVoucherFilter)
	DEFINE pRecVoucherFilter OF t_recVoucherFilter
	DEFINE recVoucher OF t_recVoucher
	DEFINE arrVoucherList DYNAMIC ARRAY OF t_recVoucher 
	DEFINE c_Voucher CURSOR
	DEFINE retError SMALLINT
		
	CALL VoucherLookupFilterDataSourceCursor(pRecVoucherFilter.*) RETURNING c_Voucher
	
	CALL arrVoucherList.CLEAR()

	CALL c_Voucher.SetResults(recVoucher.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Voucher.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Voucher.FetchNext()=0)
		CALL arrVoucherList.append([recVoucher.vouch_code, recVoucher.inv_text])
	END WHILE	

	END IF
	
	IF arrVoucherList.getSize() = 0 THEN
		ERROR "No voucher's found with the specified filter criteria"
	END IF
	
	RETURN arrVoucherList
END FUNCTION	

########################################################################################
# FUNCTION VoucherLookupSearchDataSource(pRecVoucherFilter)
#-------------------------------------------------------
# CALLS VoucherLookupSearchDataSourceCursor(pRecVoucherFilter) with the VoucherFilter data TO get a CURSOR
# Returns the Voucher list array arrVoucherList
########################################################################################
FUNCTION VoucherLookupSearchDataSource(p_recVoucherSearch)
	DEFINE p_recVoucherSearch OF t_recVoucherSearch	
	DEFINE recVoucher OF t_recVoucher
	DEFINE arrVoucherList DYNAMIC ARRAY OF t_recVoucher 
	DEFINE c_Voucher CURSOR
	DEFINE retError SMALLINT	
	CALL VoucherLookupSearchDataSourceCursor(p_recVoucherSearch) RETURNING c_Voucher
	
	CALL arrVoucherList.CLEAR()

	CALL c_Voucher.SetResults(recVoucher.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Voucher.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Voucher.FetchNext()=0)
		CALL arrVoucherList.append([recVoucher.vouch_code, recVoucher.inv_text])
	END WHILE	

	END IF
	
	IF arrVoucherList.getSize() = 0 THEN
		ERROR "No voucher's found with the specified filter criteria"
	END IF
	
	RETURN arrVoucherList
END FUNCTION


########################################################################################
# FUNCTION voucherLookup_filter(pVoucherCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Voucher code vouch_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL VoucherLookupFilterDataSource(recVoucherFilter.*) RETURNING arrVoucherList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Voucher Code vouch_code
#
# Example:
# 			LET pr_Voucher.vouch_code = VoucherLookup(pr_Voucher.vouch_code)
########################################################################################
FUNCTION voucherLookup_filter(pVoucherCode)
	DEFINE pVoucherCode LIKE Voucher.vouch_code
	DEFINE arrVoucherList DYNAMIC ARRAY OF t_recVoucher
	DEFINE recVoucherFilter OF t_recVoucherFilter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wVoucherLookup WITH FORM "VoucherLookup_filter"


	CALL VoucherLookupFilterDataSource(recVoucherFilter.*) RETURNING arrVoucherList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recVoucherFilter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL VoucherLookupFilterDataSource(recVoucherFilter.*) RETURNING arrVoucherList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrVoucherList TO scVoucherList.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pVoucherCode = arrVoucherList[idx].vouch_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recVoucherFilter.filter_vouch_code IS NOT NULL
			OR recVoucherFilter.filter_inv_text IS NOT NULL

		THEN
			LET recVoucherFilter.filter_vouch_code = NULL
			LET recVoucherFilter.filter_inv_text = NULL

			CALL VoucherLookupFilterDataSource(recVoucherFilter.*) RETURNING arrVoucherList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_vouch_code"
		IF recVoucherFilter.filter_vouch_code IS NOT NULL THEN
			LET recVoucherFilter.filter_vouch_code = NULL
			CALL VoucherLookupFilterDataSource(recVoucherFilter.*) RETURNING arrVoucherList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_inv_text"
		IF recVoucherFilter.filter_inv_text IS NOT NULL THEN
			LET recVoucherFilter.filter_inv_text = NULL
			CALL VoucherLookupFilterDataSource(recVoucherFilter.*) RETURNING arrVoucherList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wVoucherLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pVoucherCode	
END FUNCTION				
		

########################################################################################
# FUNCTION voucherLookup(pVoucherCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Voucher code vouch_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL VoucherLookupSearchDataSource(recVoucherFilter.*) RETURNING arrVoucherList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Voucher Code vouch_code
#
# Example:
# 			LET pr_Voucher.vouch_code = VoucherLookup(pr_Voucher.vouch_code)
########################################################################################
FUNCTION voucherLookup(pVoucherCode)
	DEFINE pVoucherCode LIKE Voucher.vouch_code
	DEFINE arrVoucherList DYNAMIC ARRAY OF t_recVoucher
	DEFINE recVoucherSearch OF t_recVoucherSearch	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wVoucherLookup WITH FORM "voucherLookup"

	CALL VoucherLookupSearchDataSource(recVoucherSearch.*) RETURNING arrVoucherList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recVoucherSearch.* WITHOUT DEFAULTS 
			
		ON ACTION "UPDATE-FILTER"
			CALL VoucherLookupSearchDataSource(recVoucherSearch.*) RETURNING arrVoucherList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrVoucherList TO scVoucherList.* 
		BEFORE ROW
			IF arrVoucherList.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pVoucherCode = arrVoucherList[idx].vouch_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recVoucherSearch.filter_any_field IS NOT NULL

		THEN
			LET recVoucherSearch.filter_any_field = NULL

			CALL VoucherLookupSearchDataSource(recVoucherSearch.*) RETURNING arrVoucherList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_vouch_code"
		IF recVoucherSearch.filter_any_field IS NOT NULL THEN
			LET recVoucherSearch.filter_any_field = NULL
			CALL VoucherLookupSearchDataSource(recVoucherSearch.*) RETURNING arrVoucherList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wVoucherLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pVoucherCode	
END FUNCTION				

############################################
# FUNCTION import_voucher()
############################################
FUNCTION import_voucher()
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
	DEFINE p_inv_text LIKE company.name_text
	DEFINE p_country_text LIKE country.country_text
	DEFINE p_language_text LIKE language.language_text
	DEFINE load_file STRING
	DEFINE tmpMsg STRING
	
	DEFINE rec_voucher OF t_recVoucher_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wVoucherImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import Voucher List Data (table: voucher)" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_voucher
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_voucher(	    
    vend_code CHAR(8),
    vouch_code INTEGER,
    inv_text CHAR(20),
    po_num INTEGER,
    vouch_date DATE,
    entry_code CHAR(8),
    entry_date DATE,
    sales_text CHAR(20),
    term_code CHAR(3),
    tax_code CHAR(3),
    goods_amt DECIMAL(16,2),
    tax_amt DECIMAL(16,2),
    total_amt DECIMAL(16,2),
    paid_amt DECIMAL(16,2),
    dist_qty float,
    dist_amt DECIMAL(16,2),
    poss_disc_amt DECIMAL(16,2),
    taken_disc_amt DECIMAL(16,2),
    paid_date DATE,
    due_date DATE,
    disc_date DATE,
    hist_flag CHAR(1),
    jour_num INTEGER,
    post_flag CHAR(1),
    year_num SMALLINT,
    period_num SMALLINT,
    pay_seq_num SMALLINT,
    line_num SMALLINT,
    com1_text CHAR(30),
    com2_text CHAR(30),
    hold_code CHAR(2),
    jm_post_flag CHAR(1),
    approved_by_code CHAR(8),
    approved_code CHAR(1),
    approved_date DATE,
    split_from_num INTEGER,
    currency_code CHAR(3),
    conv_qty float,
    post_date DATE,
    source_ind CHAR(1),
    source_text CHAR(8),
    withhold_tax_ind CHAR(1),
    source_code CHAR(1),
    disp_code CHAR(2),
    batch_num INTEGER
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_voucher	#we need TO INITIALIZE it, delete all rows
		END IF
		
		WHENEVER ERROR STOP	
----------------------------------------------		

	# for certain tables, we need TO know the country code TO identify the right data SET in the templates
	IF gl_setupRec_default_company.cmpy_code IS NOT NULL THEN
		CALL get_company_info (gl_setupRec_default_company.cmpy_code) 
		RETURNING p_inv_text,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text

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
	#	OPEN WINDOW wVoucherImport WITH FORM "per/setup/lib_db_data_import_01"
	#	DISPLAY "Chart of Accounts Import" TO header_text

	
		IF cmpy_code_provided = FALSE THEN

			INPUT gl_setupRec_default_company.cmpy_code, gl_setupRec_default_company.country_code,gl_setupRec_default_company.language_code 
			WITHOUT DEFAULTS 
			FROM inputRec3.*
			
				AFTER FIELD cmpy_code
					CALL get_company_info (gl_setupRec_default_company.cmpy_code)
					RETURNING p_inv_text,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text

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
							DISPLAY p_inv_text,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text 
							TO company.inv_text,country_code,country_text,language_code,language_text
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
					CLOSE WINDOW wVoucherImport
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/voucher-",gl_setupRec_default_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("Chart of Accounts Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_voucher
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_voucher
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_voucher
			LET importReport = importReport, "Code:", trim(rec_voucher.vouch_code) , "     -     Desc:", trim(rec_voucher.inv_text), "\n"
					
			INSERT INTO voucher VALUES(
			gl_setupRec_default_company.cmpy_code,
			rec_voucher.*
			
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_voucher.vouch_code) , "     -     Desc:", trim(rec_voucher.inv_text), " ->DUPLICATE = Ignored !\n"
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
		
		CLOSE WINDOW wVoucherImport
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_voucherRec(p_cmpy_code, p_vouch_code)
########################################################
FUNCTION exist_voucherRec(p_cmpy_code, p_vouch_code)
	DEFINE p_cmpy_code LIKE voucher.cmpy_code
	DEFINE p_vouch_code LIKE voucher.vouch_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM voucher 
     WHERE cmpy_code = p_cmpy_code
     AND vouch_code = p_vouch_code

	DROP TABLE temp_voucher
	CLOSE WINDOW wVoucherImport
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_voucher()
###############################################################
FUNCTION unload_voucher(p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile STRING
	
	LET unloadFile = "unl/voucher-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 
	UNLOAD TO unloadFile 
		SELECT * FROM voucher ORDER BY cmpy_code, vouch_code ASC
	
	LET tmpMsg = "All voucher data were exported/written TO:\n", unloadFile
	CALL fgl_winmessage("voucher Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION
###############################################################
# FUNCTION delete_voucher_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_voucher_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE voucher.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wvoucherImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "voucher Type Delete" TO header_text
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
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing voucher table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM voucher
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table voucher!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table voucher where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wVoucherImport		
END FUNCTION	