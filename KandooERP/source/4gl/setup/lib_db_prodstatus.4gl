GLOBALS "lib_db_globals.4gl"

# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getprodstatusCount()
# FUNCTION prodstatusLookupFilterDataSourceCursor(precprodstatusFilter)
# FUNCTION prodstatusLookupSearchDataSourceCursor(p_recprodstatusSearch)
# FUNCTION prodstatusLookupFilterDataSource(precprodstatusFilter)
# FUNCTION prodstatusLookup_filter(pprodstatusCode)
# FUNCTION import_prodstatus()
# FUNCTION exist_prodstatusRec(p_cmpy_code, p_ware_code)
# FUNCTION delete_prodstatus_all()
# FUNCTION prodstatusMenu()						-- Offer different OPTIONS of this library via a menu

# prodstatus record types
	DEFINE t_recprodstatus  
		TYPE AS RECORD
			part_code LIKE prodstatus.part_code,
			ware_code LIKE prodstatus.ware_code
			#name_text LIKE prodstatus.name_text
		END RECORD 

	DEFINE t_recprodstatusFilter  
		TYPE AS RECORD
			filter_part_code LIKE prodstatus.part_code,
			filter_ware_code LIKE prodstatus.ware_code
			#filter_name_text LIKE prodstatus.name_text
		END RECORD 

	DEFINE t_recprodstatusSearch  
		TYPE AS RECORD
			filter_any_field STRING
		END RECORD 		

	DEFINE t_recprodstatus_noCmpyId 
		TYPE AS RECORD 
    part_code LIKE prodstatus.part_code,
    ware_code LIKE prodstatus.ware_code,
    onhand_qty LIKE prodstatus.onhand_qty,
    onord_qty LIKE prodstatus.onord_qty,
    reserved_qty LIKE prodstatus.reserved_qty,
    back_qty LIKE prodstatus.back_qty,
    forward_qty LIKE prodstatus.forward_qty,
    reorder_point_qty LIKE prodstatus.reorder_point_qty,
    reorder_qty LIKE prodstatus.reorder_qty,
    max_qty LIKE prodstatus.max_qty,
    critical_qty LIKE prodstatus.critical_qty,
    special_flag LIKE prodstatus.special_flag,
    list_amt LIKE prodstatus.list_amt,
    price1_amt LIKE prodstatus.price1_amt,
    price2_amt LIKE prodstatus.price2_amt,
    price3_amt LIKE prodstatus.price3_amt,
    price4_amt LIKE prodstatus.price4_amt,
    price5_amt LIKE prodstatus.price5_amt,
    price6_amt LIKE prodstatus.price6_amt,
    price7_amt LIKE prodstatus.price7_amt,
    price8_amt LIKE prodstatus.price8_amt,
    price9_amt LIKE prodstatus.price9_amt,
    status_ind LIKE prodstatus.status_ind,
    status_date LIKE prodstatus.status_date,
    nonstk_pick_flag LIKE prodstatus.nonstk_pick_flag,
    pricel_per LIKE prodstatus.pricel_per,
    pricel_ind LIKE prodstatus.pricel_ind,
    price1_per LIKE prodstatus.price1_per,
    price1_ind LIKE prodstatus.price1_ind,
    price2_per LIKE prodstatus.price2_per,
    price2_ind LIKE prodstatus.price2_ind,
    price3_per LIKE prodstatus.price3_per,
    price3_ind LIKE prodstatus.price3_ind,
    price4_per LIKE prodstatus.price4_per,
    price4_ind LIKE prodstatus.price4_ind,
    price5_per LIKE prodstatus.price5_per,
    price5_ind LIKE prodstatus.price5_ind,
    price6_per LIKE prodstatus.price6_per,
    price6_ind LIKE prodstatus.price6_ind,
    price7_per LIKE prodstatus.price7_per,
    price7_ind LIKE prodstatus.price7_ind,
    price8_per LIKE prodstatus.price8_per,
    price8_ind LIKE prodstatus.price8_ind,
    price9_per LIKE prodstatus.price9_per,
    price9_ind LIKE prodstatus.price9_ind,
    last_list_date LIKE prodstatus.last_list_date,
    last_price_date LIKE prodstatus.last_price_date,
    est_cost_amt LIKE prodstatus.est_cost_amt,
    act_cost_amt LIKE prodstatus.act_cost_amt,
    wgted_cost_amt LIKE prodstatus.wgted_cost_amt,
    for_cost_amt LIKE prodstatus.for_cost_amt,
    for_curr_code LIKE prodstatus.for_curr_code,
    last_cost_date LIKE prodstatus.last_cost_date,
    bin1_text LIKE prodstatus.bin1_text,
    bin2_text LIKE prodstatus.bin2_text,
    bin3_text LIKE prodstatus.bin3_text,
    last_sale_date LIKE prodstatus.last_sale_date,
    last_receipt_date LIKE prodstatus.last_receipt_date,
    seq_num LIKE prodstatus.seq_num,
    phys_count_qty LIKE prodstatus.phys_count_qty,
    stocked_flag LIKE prodstatus.stocked_flag,
    last_stcktake_date LIKE prodstatus.last_stcktake_date,
    stcktake_days LIKE prodstatus.stcktake_days,
    min_ord_qty LIKE prodstatus.min_ord_qty,
    replenish_ind LIKE prodstatus.replenish_ind,
    abc_ind LIKE prodstatus.abc_ind,
    avg_qty LIKE prodstatus.avg_qty,
    avg_cost_amt LIKE prodstatus.avg_cost_amt,
    stockturn_qty LIKE prodstatus.stockturn_qty,
    transit_qty LIKE prodstatus.transit_qty,
    sale_tax_code LIKE prodstatus.sale_tax_code,
    purch_tax_code LIKE prodstatus.purch_tax_code,
    sale_tax_amt LIKE prodstatus.sale_tax_amt,
    purch_tax_amt LIKE prodstatus.purch_tax_amt
    
	END RECORD	


	
########################################################################################
# FUNCTION prodstatusMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION prodstatusMenu()
	MENU
		ON ACTION "Import"
			CALL import_prodstatus()
		ON ACTION "Export"
			CALL unload_prodstatus()
		#ON ACTION "Import"
		#	CALL import_prodstatus()
		ON ACTION "Delete All"
			CALL delete_prodstatus_all()
		ON ACTION "Count"
			CALL getprodstatusCount() --Count all prodstatus rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getprodstatusCount()
#-------------------------------------------------------
# Returns the number of prodstatus entries for the current company
########################################################################################
FUNCTION getprodstatusCount()
	DEFINE ret_prodstatusCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_prodstatus CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM prodstatus ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_prodstatus.DECLARE(sqlQuery) #CURSOR FOR getprodstatus
	CALL c_prodstatus.SetResults(ret_prodstatusCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_prodstatus.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_prodstatusCount = -1
	ELSE
		CALL c_prodstatus.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of customer parts:", trim(ret_prodstatusCount) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("Customer Part Count (table prodstatus)", tempMsg,"info") 	
	END IF

	RETURN ret_prodstatusCount
END FUNCTION


############################################
# FUNCTION import_prodstatus()
############################################
FUNCTION import_prodstatus()
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
	DEFINE p_name_text LIKE company.name_text
	DEFINE p_country_text LIKE country.country_text
	DEFINE p_language_text LIKE language.language_text
	DEFINE load_file STRING
	DEFINE tmpMsg STRING
	
	DEFINE rec_prodstatus OF t_recprodstatus_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wprodstatusImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import Product Status List Data (table: prodstatus)" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_prodstatus
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_prodstatus(	    
    part_code CHAR(15),
    ware_code CHAR(3),
    onhand_qty float,
    onord_qty float,
    reserved_qty float,
    back_qty float,
    forward_qty float,
    reorder_point_qty float,
    reorder_qty float,
    max_qty float,
    critical_qty float,
    special_flag CHAR(1),
    list_amt DECIMAL(16,4),
    price1_amt DECIMAL(16,4),
    price2_amt DECIMAL(16,4),
    price3_amt DECIMAL(16,4),
    price4_amt DECIMAL(16,4),
    price5_amt DECIMAL(16,4),
    price6_amt DECIMAL(16,4),
    price7_amt DECIMAL(16,4),
    price8_amt DECIMAL(16,4),
    price9_amt DECIMAL(16,4),
    status_ind CHAR(1),
    status_date DATE,
    nonstk_pick_flag CHAR(1),
    pricel_per float,
    pricel_ind CHAR(1),
    price1_per float,
    price1_ind CHAR(1),
    price2_per float,
    price2_ind CHAR(1),
    price3_per float,
    price3_ind CHAR(1),
    price4_per float,
    price4_ind CHAR(1),
    price5_per float,
    price5_ind CHAR(1),
    price6_per float,
    price6_ind CHAR(1),
    price7_per float,
    price7_ind CHAR(1),
    price8_per float,
    price8_ind CHAR(1),
    price9_per float,
    price9_ind CHAR(1),
    last_list_date DATE,
    last_price_date DATE,
    est_cost_amt DECIMAL(16,4),
    act_cost_amt DECIMAL(16,4),
    wgted_cost_amt DECIMAL(16,4),
    for_cost_amt DECIMAL(16,4),
    for_curr_code CHAR(3),
    last_cost_date DATE,
    bin1_text CHAR(15),
    bin2_text CHAR(15),
    bin3_text CHAR(15),
    last_sale_date DATE,
    last_receipt_date DATE,
    seq_num INTEGER,
    phys_count_qty float,
    stocked_flag CHAR(1),
    last_stcktake_date DATE,
    stcktake_days SMALLINT,
    min_ord_qty float,
    replenish_ind CHAR(1),
    abc_ind CHAR(1),
    avg_qty float,
    avg_cost_amt DECIMAL(16,4),
    stockturn_qty float,
    transit_qty float,
    sale_tax_code CHAR(3),
    purch_tax_code CHAR(3),
    sale_tax_amt DECIMAL(16,4),
    purch_tax_amt DECIMAL(16,4)
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_prodstatus	#we need TO INITIALIZE it, delete all rows
		END IF
		
		WHENEVER ERROR STOP	
----------------------------------------------		

	# for certain tables, we need TO know the country code TO identify the right data SET in the templates
	IF gl_setupRec_default_company.cmpy_code IS NOT NULL THEN
		CALL get_company_info (gl_setupRec_default_company.cmpy_code) 
		RETURNING p_name_text,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text

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
	#	OPEN WINDOW wprodstatusImport WITH FORM "per/setup/lib_db_data_import_01"
	#	DISPLAY "Chart of Accounts Import" TO header_text

	
		IF cmpy_code_provided = FALSE THEN

			INPUT gl_setupRec_default_company.cmpy_code, gl_setupRec_default_company.country_code,gl_setupRec_default_company.language_code 
			WITHOUT DEFAULTS 
			FROM inputRec3.*
			
				AFTER FIELD cmpy_code
					CALL get_company_info (gl_setupRec_default_company.cmpy_code)
					RETURNING p_name_text,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text

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
							DISPLAY p_name_text,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text 
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
					CLOSE WINDOW wprodstatusImport
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/prodstatus-",gl_setupRec_default_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("Product Status (prodstatus) Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_prodstatus
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_prodstatus
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_prodstatus
			LET importReport = importReport, "Code:", trim(rec_prodstatus.ware_code) , "     -     Desc:", trim(rec_prodstatus.part_code), "\n"
					
			INSERT INTO prodstatus VALUES(
			gl_setupRec_default_company.cmpy_code,
			rec_prodstatus.*
			
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_prodstatus.ware_code) , "     -     Desc:", trim(rec_prodstatus.part_code), " ->DUPLICATE = Ignored !\n"
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
		
		CLOSE WINDOW wprodstatusImport
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_prodstatusRec(p_cmpy_code, p_ware_code)
########################################################
FUNCTION exist_prodstatusRec(p_cmpy_code, p_ware_code)
	DEFINE p_cmpy_code LIKE prodstatus.cmpy_code
	DEFINE p_ware_code LIKE prodstatus.ware_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM prodstatus 
     WHERE cmpy_code = p_cmpy_code
     AND ware_code = p_ware_code

	DROP TABLE temp_prodstatus
	CLOSE WINDOW wprodstatusImport
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_prodstatus()
###############################################################
FUNCTION unload_prodstatus(p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile STRING
	
	LET unloadFile = "unl/prodstatus-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 
	UNLOAD TO unloadFile SELECT * FROM prodstatus ORDER BY cmpy_code, ware_code ASC
	
	LET tmpMsg = "All Product Statuss (prodstatus) data were exported/written TO:\n", unloadFile
	CALL fgl_winmessage("prodstatus Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION
###############################################################
# FUNCTION delete_prodstatus_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_prodstatus_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE prodstatus.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wprodstatusImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Delete Product Statuss (table: prodstatus)" TO header_text
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
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing Product Statuss (prodstatus) table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM prodstatus
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table prodstatus!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table prodstatus where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wprodstatusImport		
END FUNCTION	