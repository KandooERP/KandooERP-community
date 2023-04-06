GLOBALS "lib_db_globals.4gl"

# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getWarehouseCount()
# FUNCTION warehouseLookupFilterDataSourceCursor(pRecWarehouseFilter)
# FUNCTION warehouseLookupSearchDataSourceCursor(p_RecWarehouseSearch)
# FUNCTION WarehouseLookupFilterDataSource(pRecWarehouseFilter)
# FUNCTION warehouseLookup_filter(pWarehouseCode)
# FUNCTION import_warehouse()
# FUNCTION exist_warehouseRec(p_cmpy_code, p_ware_code)
# FUNCTION delete_warehouse_all()
# FUNCTION warehouseMenu()						-- Offer different OPTIONS of this library via a menu

# Warehouse record types
	DEFINE t_recWarehouse  
		TYPE AS RECORD
			ware_code LIKE warehouse.ware_code,
			desc_text LIKE warehouse.desc_text
		END RECORD 

	DEFINE t_recWarehouseFilter  
		TYPE AS RECORD
			filter_ware_code LIKE warehouse.ware_code,
			filter_desc_text LIKE warehouse.desc_text
		END RECORD 

	DEFINE t_recWarehouseSearch  
		TYPE AS RECORD
			filter_any_field STRING
		END RECORD 		

	DEFINE t_recWarehouse_noCmpyId 
		TYPE AS RECORD 
    ware_code LIKE warehouse.ware_code,
    desc_text LIKE warehouse.desc_text,    
    addr1_text LIKE warehouse.addr1_text,
    addr2_text LIKE warehouse.addr2_text,
    city_text LIKE warehouse.city_text,
    state_code LIKE warehouse.state_code,
    post_code LIKE warehouse.post_code,
    country_code LIKE warehouse.country_code,
    contact_text LIKE warehouse.contact_text,
    tele_text LIKE warehouse.tele_text,
    auto_run_num LIKE warehouse.auto_run_num,
    back_order_ind LIKE warehouse.back_order_ind,
    confirm_flag LIKE warehouse.confirm_flag,
    pick_flag LIKE warehouse.pick_flag,
    pick_print_code LIKE warehouse.pick_print_code,
    connote_flag LIKE warehouse.connote_flag,
    connote_print_code LIKE warehouse.connote_print_code,
    ship_label_flag LIKE warehouse.ship_label_flag,
    ship_print_code LIKE warehouse.ship_print_code,
    inv_flag LIKE warehouse.inv_flag,
    inv_print_code LIKE warehouse.inv_print_code,
    acct_mask_code LIKE warehouse.acct_mask_code,
    next_pick_num LIKE warehouse.next_pick_num,
    pick_reten_num LIKE warehouse.pick_reten_num,
    next_sched_date LIKE warehouse.next_sched_date,
    cart_area_code LIKE warehouse.cart_area_code,
    map_gps_coordinates LIKE warehouse.map_gps_coordinates,
    waregrp_code LIKE warehouse.waregrp_code
	END RECORD	


	
########################################################################################
# FUNCTION warehouseMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION warehouseMenu()
	MENU
		ON ACTION "Import"
			CALL import_warehouse()
		ON ACTION "Export"
			CALL unload_warehouse()
		#ON ACTION "Import"
		#	CALL import_warehouse()
		ON ACTION "Delete All"
			CALL delete_warehouse_all()
		ON ACTION "Count"
			CALL getWarehouseCount() --Count all warehouse rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getWarehouseCount()
#-------------------------------------------------------
# Returns the number of Warehouse entries for the current company
########################################################################################
FUNCTION getWarehouseCount()
	DEFINE ret_WarehouseCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_Warehouse CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM Warehouse ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_Warehouse.DECLARE(sqlQuery) #CURSOR FOR getWarehouse
	CALL c_Warehouse.SetResults(ret_WarehouseCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_Warehouse.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_WarehouseCount = -1
	ELSE
		CALL c_Warehouse.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of Warehouse(s) :", trim(ret_WarehouseCount) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("Warehouse Count", tempMsg,"info") 	
	END IF

	RETURN ret_WarehouseCount
END FUNCTION

########################################################################################
# FUNCTION warehouseLookupFilterDataSourceCursor(pRecWarehouseFilter)
#-------------------------------------------------------
# Returns the Warehouse CURSOR for the lookup query
########################################################################################
FUNCTION warehouseLookupFilterDataSourceCursor(pRecWarehouseFilter)
	DEFINE pRecWarehouseFilter OF t_recWarehouseFilter
	DEFINE sqlQuery STRING
	DEFINE c_Warehouse CURSOR
	
	LET sqlQuery =	"SELECT ",
									"warehouse.ware_code, ", 
									"warehouse.desc_text ",
									"FROM warehouse ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF pRecWarehouseFilter.filter_ware_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ware_code LIKE '", pRecWarehouseFilter.filter_ware_code CLIPPED, "%' "  
	END IF									

	IF pRecWarehouseFilter.filter_desc_text IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND desc_text LIKE '", pRecWarehouseFilter.filter_desc_text CLIPPED, "%' "  
	END IF	
	
			
	LET sqlQuery = sqlQuery, " ORDER BY ware_code"

	CALL c_warehouse.DECLARE(sqlQuery)
		
	RETURN c_warehouse
END FUNCTION



########################################################################################
# warehouseLookupSearchDataSourceCursor(p_RecWarehouseSearch)
#-------------------------------------------------------
# Returns the Warehouse CURSOR for the lookup query
########################################################################################
FUNCTION warehouseLookupSearchDataSourceCursor(p_RecWarehouseSearch)
	DEFINE p_RecWarehouseSearch OF t_recWarehouseSearch  
	DEFINE sqlQuery STRING
	DEFINE c_Warehouse CURSOR
	
	LET sqlQuery =	"SELECT ",
									"warehouse.ware_code, ", 
									"warehouse.desc_text ",
 
									"FROM warehouse ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
	
	IF p_RecWarehouseSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((ware_code LIKE '", p_RecWarehouseSearch.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR desc_text LIKE '",   p_RecWarehouseSearch.filter_any_field CLIPPED, "%') "  
  						
	END IF


	IF p_RecWarehouseSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, "ORDER BY ware_code"

	CALL c_warehouse.DECLARE(sqlQuery) #CURSOR FOR warehouse
	
	RETURN c_warehouse
END FUNCTION


########################################################################################
# FUNCTION WarehouseLookupFilterDataSource(pRecWarehouseFilter)
#-------------------------------------------------------
# CALLS WarehouseLookupFilterDataSourceCursor(pRecWarehouseFilter) with the WarehouseFilter data TO get a CURSOR
# Returns the Warehouse list array arrWarehouseList
########################################################################################
FUNCTION WarehouseLookupFilterDataSource(pRecWarehouseFilter)
	DEFINE pRecWarehouseFilter OF t_recWarehouseFilter
	DEFINE recWarehouse OF t_recWarehouse
	DEFINE arrWarehouseList DYNAMIC ARRAY OF t_recWarehouse 
	DEFINE c_Warehouse CURSOR
	DEFINE retError SMALLINT
		
	CALL WarehouseLookupFilterDataSourceCursor(pRecWarehouseFilter.*) RETURNING c_Warehouse
	
	CALL arrWarehouseList.CLEAR()

	CALL c_Warehouse.SetResults(recWarehouse.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Warehouse.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Warehouse.FetchNext()=0)
		CALL arrWarehouseList.append([recWarehouse.ware_code, recWarehouse.desc_text])
	END WHILE	

	END IF
	
	IF arrWarehouseList.getSize() = 0 THEN
		ERROR "No warehouse's found with the specified filter criteria"
	END IF
	
	RETURN arrWarehouseList
END FUNCTION	

########################################################################################
# FUNCTION WarehouseLookupSearchDataSource(pRecWarehouseFilter)
#-------------------------------------------------------
# CALLS WarehouseLookupSearchDataSourceCursor(pRecWarehouseFilter) with the WarehouseFilter data TO get a CURSOR
# Returns the Warehouse list array arrWarehouseList
########################################################################################
FUNCTION WarehouseLookupSearchDataSource(p_recWarehouseSearch)
	DEFINE p_recWarehouseSearch OF t_recWarehouseSearch	
	DEFINE recWarehouse OF t_recWarehouse
	DEFINE arrWarehouseList DYNAMIC ARRAY OF t_recWarehouse 
	DEFINE c_Warehouse CURSOR
	DEFINE retError SMALLINT	
	CALL WarehouseLookupSearchDataSourceCursor(p_recWarehouseSearch) RETURNING c_Warehouse
	
	CALL arrWarehouseList.CLEAR()

	CALL c_Warehouse.SetResults(recWarehouse.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Warehouse.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Warehouse.FetchNext()=0)
		CALL arrWarehouseList.append([recWarehouse.ware_code, recWarehouse.desc_text])
	END WHILE	

	END IF
	
	IF arrWarehouseList.getSize() = 0 THEN
		ERROR "No warehouse's found with the specified filter criteria"
	END IF
	
	RETURN arrWarehouseList
END FUNCTION


########################################################################################
# FUNCTION warehouseLookup_filter(pWarehouseCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Warehouse code ware_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL WarehouseLookupFilterDataSource(recWarehouseFilter.*) RETURNING arrWarehouseList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Warehouse Code ware_code
#
# Example:
# 			LET pr_Warehouse.ware_code = WarehouseLookup(pr_Warehouse.ware_code)
########################################################################################
FUNCTION warehouseLookup_filter(pWarehouseCode)
	DEFINE pWarehouseCode LIKE Warehouse.ware_code
	DEFINE arrWarehouseList DYNAMIC ARRAY OF t_recWarehouse
	DEFINE recWarehouseFilter OF t_recWarehouseFilter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wWarehouseLookup WITH FORM "WarehouseLookup_filter"


	CALL WarehouseLookupFilterDataSource(recWarehouseFilter.*) RETURNING arrWarehouseList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recWarehouseFilter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL WarehouseLookupFilterDataSource(recWarehouseFilter.*) RETURNING arrWarehouseList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrWarehouseList TO scWarehouseList.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pWarehouseCode = arrWarehouseList[idx].ware_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recWarehouseFilter.filter_ware_code IS NOT NULL
			OR recWarehouseFilter.filter_desc_text IS NOT NULL

		THEN
			LET recWarehouseFilter.filter_ware_code = NULL
			LET recWarehouseFilter.filter_desc_text = NULL

			CALL WarehouseLookupFilterDataSource(recWarehouseFilter.*) RETURNING arrWarehouseList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_ware_code"
		IF recWarehouseFilter.filter_ware_code IS NOT NULL THEN
			LET recWarehouseFilter.filter_ware_code = NULL
			CALL WarehouseLookupFilterDataSource(recWarehouseFilter.*) RETURNING arrWarehouseList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_desc_text"
		IF recWarehouseFilter.filter_desc_text IS NOT NULL THEN
			LET recWarehouseFilter.filter_desc_text = NULL
			CALL WarehouseLookupFilterDataSource(recWarehouseFilter.*) RETURNING arrWarehouseList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wWarehouseLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pWarehouseCode	
END FUNCTION				
		

########################################################################################
# FUNCTION warehouseLookup(pWarehouseCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Warehouse code ware_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL WarehouseLookupSearchDataSource(recWarehouseFilter.*) RETURNING arrWarehouseList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Warehouse Code ware_code
#
# Example:
# 			LET pr_Warehouse.ware_code = WarehouseLookup(pr_Warehouse.ware_code)
########################################################################################
FUNCTION warehouseLookup(pWarehouseCode)
	DEFINE pWarehouseCode LIKE Warehouse.ware_code
	DEFINE arrWarehouseList DYNAMIC ARRAY OF t_recWarehouse
	DEFINE recWarehouseSearch OF t_recWarehouseSearch	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wWarehouseLookup WITH FORM "warehouseLookup"

	CALL WarehouseLookupSearchDataSource(recWarehouseSearch.*) RETURNING arrWarehouseList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recWarehouseSearch.* WITHOUT DEFAULTS 
			
		ON ACTION "UPDATE-FILTER"
			CALL WarehouseLookupSearchDataSource(recWarehouseSearch.*) RETURNING arrWarehouseList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrWarehouseList TO scWarehouseList.* 
		BEFORE ROW
			IF arrWarehouseList.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pWarehouseCode = arrWarehouseList[idx].ware_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recWarehouseSearch.filter_any_field IS NOT NULL

		THEN
			LET recWarehouseSearch.filter_any_field = NULL

			CALL WarehouseLookupSearchDataSource(recWarehouseSearch.*) RETURNING arrWarehouseList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_ware_code"
		IF recWarehouseSearch.filter_any_field IS NOT NULL THEN
			LET recWarehouseSearch.filter_any_field = NULL
			CALL WarehouseLookupSearchDataSource(recWarehouseSearch.*) RETURNING arrWarehouseList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wWarehouseLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pWarehouseCode	
END FUNCTION				

############################################
# FUNCTION import_warehouse()
############################################
FUNCTION import_warehouse()
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
	
	DEFINE rec_warehouse OF t_recWarehouse_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wWarehouseImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import Warehouse Group List Data (table: warehouse)" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_warehouse
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_warehouse(	    
    ware_code CHAR(3),
    desc_text CHAR(30),
    addr1_text CHAR(40),
    addr2_text CHAR(40),
    city_text CHAR(40),
    state_code CHAR(6),
    post_code CHAR(10),
    country_code CHAR(40),
    contact_text CHAR(40),
    tele_text CHAR(20),
    auto_run_num SMALLINT,
    back_order_ind CHAR(1),
    confirm_flag CHAR(1),
    pick_flag CHAR(1),
    pick_print_code CHAR(20),
    connote_flag CHAR(1),
    connote_print_code CHAR(20),
    ship_label_flag CHAR(1),
    ship_print_code CHAR(20),
    inv_flag CHAR(1),
    inv_print_code CHAR(20),
    acct_mask_code CHAR(18),
    next_pick_num INTEGER,
    pick_reten_num INTEGER,
    next_sched_date datetime year TO minute,
    cart_area_code CHAR(3),
    map_gps_coordinates CHAR(10),
    waregrp_code CHAR(8)
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_warehouse	#we need TO INITIALIZE it, delete all rows
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
	#	OPEN WINDOW wWarehouseImport WITH FORM "per/setup/lib_db_data_import_01"
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
							TO company.desc_text,country_code,country_text,language_code,language_text
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
					CLOSE WINDOW wWarehouseImport
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/warehouse-",gl_setupRec_default_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("Chart of Accounts Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_warehouse
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_warehouse
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_warehouse
			LET importReport = importReport, "Code:", trim(rec_warehouse.ware_code) , "     -     Desc:", trim(rec_warehouse.desc_text), "\n"
					
			INSERT INTO warehouse VALUES(
			gl_setupRec_default_company.cmpy_code,
			rec_warehouse.*
			
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_warehouse.ware_code) , "     -     Desc:", trim(rec_warehouse.desc_text), " ->DUPLICATE = Ignored !\n"
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
		
		CLOSE WINDOW wWarehouseImport
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_warehouseRec(p_cmpy_code, p_ware_code)
########################################################
FUNCTION exist_warehouseRec(p_cmpy_code, p_ware_code)
	DEFINE p_cmpy_code LIKE warehouse.cmpy_code
	DEFINE p_ware_code LIKE warehouse.ware_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM warehouse 
     WHERE cmpy_code = p_cmpy_code
     AND ware_code = p_ware_code

	DROP TABLE temp_warehouse
	CLOSE WINDOW wWarehouseImport
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_warehouse()
###############################################################
FUNCTION unload_warehouse(p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile STRING
	
	LET unloadFile = "unl/warehouse-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 
	UNLOAD TO unloadFile 
		SELECT * FROM warehouse ORDER BY cmpy_code, ware_code ASC
	
	LET tmpMsg = "All warehouse data were exported/written TO:\n", unloadFile
	CALL fgl_winmessage("warehouse Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION
###############################################################
# FUNCTION delete_warehouse_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_warehouse_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE warehouse.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wwarehouseImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "warehouse Type Delete" TO header_text
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
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing warehouse table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM warehouse
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table warehouse!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table warehouse where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wWarehouseImport		
END FUNCTION	