GLOBALS "lib_db_globals.4gl"

# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getProductCount()
# FUNCTION productLookupFilterDataSourceCursor(pRecProductFilter)
# FUNCTION productLookupSearchDataSourceCursor(p_RecProductSearch)
# FUNCTION ProductLookupFilterDataSource(pRecProductFilter)
# FUNCTION productLookup_filter(pProductCode)
# FUNCTION import_product()
# FUNCTION exist_productRec(p_cmpy_code, p_part_code)
# FUNCTION delete_product_all()
# FUNCTION productMenu()						-- Offer different OPTIONS of this library via a menu

# Product record types
	DEFINE t_recProduct  
		TYPE AS RECORD
			part_code LIKE product.part_code,
			desc_text LIKE product.desc_text
		END RECORD 

	DEFINE t_recProductFilter  
		TYPE AS RECORD
			filter_part_code LIKE product.part_code,
			filter_desc_text LIKE product.desc_text
		END RECORD 

	DEFINE t_recProductSearch  
		TYPE AS RECORD
			filter_any_field STRING
		END RECORD 		

	DEFINE t_recProduct_noCmpyId 
		TYPE AS RECORD 
    part_code LIKE product.part_code,
    desc_text LIKE product.desc_text,
    desc2_text  LIKE product.desc2_text,
    cat_code  LIKE product.cat_code,
    class_code  LIKE product.class_code,
    ref_code  LIKE product.ref_code,
    alter_part_code  LIKE product.alter_part_code,
    super_part_code  LIKE product.super_part_code,
    compn_part_code  LIKE product.compn_part_code,
    tariff_code  LIKE product.tariff_code,
    oem_text  LIKE product.oem_text,
    weight_qty  LIKE product.weight_qty,
    cubic_qty  LIKE product.cubic_qty,
    serial_flag  LIKE product.serial_flag,
    setup_date  LIKE product.setup_date,
    target_turn_qty  LIKE product.target_turn_qty,
    stock_turn_qty  LIKE product.stock_turn_qty,
    stock_days_num  LIKE product.stock_days_num,
    last_calc_date  LIKE product.last_calc_date,
    pur_uom_code  LIKE product.pur_uom_code,
    pur_stk_con_qty  LIKE product.pur_stk_con_qty,
    stock_uom_code  LIKE product.stock_uom_code,
    stk_sel_con_qty  LIKE product.stk_sel_con_qty,
    sell_uom_code  LIKE product.sell_uom_code,
    outer_qty  LIKE product.outer_qty,
    outer_sur_per  LIKE product.outer_sur_per,
    bar_code_text  LIKE product.bar_code_text,
    days_lead_num  LIKE product.days_lead_num,
    vend_code  LIKE product.vend_code,
    min_ord_qty  LIKE product.min_ord_qty,
    days_warr_num  LIKE product.days_warr_num,
    inven_method_ind  LIKE product.inven_method_ind,
    total_tax_flag  LIKE product.total_tax_flag,
    status_ind  LIKE product.status_ind,
    status_date  LIKE product.status_date,
    short_desc_text  LIKE product.short_desc_text,
    min_month_amt  LIKE product.min_month_amt,
    min_quart_amt  LIKE product.min_quart_amt,
    min_year_amt  LIKE product.min_year_amt,
    prodgrp_code  LIKE product.prodgrp_code,
    maingrp_code  LIKE product.maingrp_code,
    back_order_flag  LIKE product.back_order_flag,
    disc_allow_flag  LIKE product.disc_allow_flag,
    bonus_allow_flag  LIKE product.bonus_allow_flag,
    trade_in_flag  LIKE product.trade_in_flag,
    price_inv_flag  LIKE product.price_inv_flag,
    ref1_code  LIKE product.ref1_code,
    ref2_code  LIKE product.ref2_code,
    ref3_code  LIKE product.ref3_code,
    ref4_code  LIKE product.ref4_code,
    ref5_code  LIKE product.ref5_code,
    ref6_code  LIKE product.ref6_code,
    ref7_code  LIKE product.ref7_code,
    ref8_code  LIKE product.ref8_code,
    price_uom_code  LIKE product.price_uom_code,
    area_qty  LIKE product.area_qty,
    length_qty  LIKE product.length_qty,
    pack_qty  LIKE product.pack_qty,
    dg_code  LIKE product.dg_code,
    ware_code  LIKE product.ware_code
	END RECORD	

	
########################################################################################
# FUNCTION productMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION productMenu()
	MENU
		ON ACTION "Import"
			CALL import_product()
		ON ACTION "Export"
			CALL unload_product()
		#ON ACTION "Import"
		#	CALL import_product()
		ON ACTION "Delete All"
			CALL delete_product_all()
		ON ACTION "Count"
			CALL getProductCount() --Count all product rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getProductCount()
#-------------------------------------------------------
# Returns the number of Product entries for the current company
########################################################################################
FUNCTION getProductCount()
	DEFINE ret_ProductCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_Product CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM Product ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_Product.DECLARE(sqlQuery) #CURSOR FOR getProduct
	CALL c_Product.SetResults(ret_ProductCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_Product.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_ProductCount = -1
	ELSE
		CALL c_Product.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of Products:", trim(ret_ProductCount) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("Product Count", tempMsg,"info") 	
	END IF

	RETURN ret_ProductCount
END FUNCTION

########################################################################################
# FUNCTION productLookupFilterDataSourceCursor(pRecProductFilter)
#-------------------------------------------------------
# Returns the Product CURSOR for the lookup query
########################################################################################
FUNCTION productLookupFilterDataSourceCursor(pRecProductFilter)
	DEFINE pRecProductFilter OF t_recProductFilter
	DEFINE sqlQuery STRING
	DEFINE c_Product CURSOR
	
	LET sqlQuery =	"SELECT ",
									"product.part_code, ", 
									"product.desc_text ",
									"FROM product ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF pRecProductFilter.filter_part_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND part_code LIKE '", pRecProductFilter.filter_part_code CLIPPED, "%' "  
	END IF									

	IF pRecProductFilter.filter_desc_text IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND desc_text LIKE '", pRecProductFilter.filter_desc_text CLIPPED, "%' "  
	END IF	
	
			
	LET sqlQuery = sqlQuery, " ORDER BY part_code"

	CALL c_product.DECLARE(sqlQuery)
		
	RETURN c_product
END FUNCTION



########################################################################################
# productLookupSearchDataSourceCursor(p_RecProductSearch)
#-------------------------------------------------------
# Returns the Product CURSOR for the lookup query
########################################################################################
FUNCTION productLookupSearchDataSourceCursor(p_RecProductSearch)
	DEFINE p_RecProductSearch OF t_recProductSearch  
	DEFINE sqlQuery STRING
	DEFINE c_Product CURSOR
	
	LET sqlQuery =	"SELECT ",
									"product.part_code, ", 
									"product.desc_text ",
 
									"FROM product ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
	
	IF p_RecProductSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((part_code LIKE '", p_RecProductSearch.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR desc_text LIKE '",   p_RecProductSearch.filter_any_field CLIPPED, "%') "  
  						
	END IF


	IF p_RecProductSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, "ORDER BY part_code"

	CALL c_product.DECLARE(sqlQuery) #CURSOR FOR product
	
	RETURN c_product
END FUNCTION


########################################################################################
# FUNCTION ProductLookupFilterDataSource(pRecProductFilter)
#-------------------------------------------------------
# CALLS ProductLookupFilterDataSourceCursor(pRecProductFilter) with the ProductFilter data TO get a CURSOR
# Returns the Product list array arrProductList
########################################################################################
FUNCTION ProductLookupFilterDataSource(pRecProductFilter)
	DEFINE pRecProductFilter OF t_recProductFilter
	DEFINE recProduct OF t_recProduct
	DEFINE arrProductList DYNAMIC ARRAY OF t_recProduct 
	DEFINE c_Product CURSOR
	DEFINE retError SMALLINT
		
	CALL ProductLookupFilterDataSourceCursor(pRecProductFilter.*) RETURNING c_Product
	
	CALL arrProductList.CLEAR()

	CALL c_Product.SetResults(recProduct.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Product.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Product.FetchNext()=0)
		CALL arrProductList.append([recProduct.part_code, recProduct.desc_text])
	END WHILE	

	END IF
	
	IF arrProductList.getSize() = 0 THEN
		ERROR "No products found with the specified filter criteria"
	END IF
	
	RETURN arrProductList
END FUNCTION	

########################################################################################
# FUNCTION ProductLookupSearchDataSource(pRecProductFilter)
#-------------------------------------------------------
# CALLS ProductLookupSearchDataSourceCursor(pRecProductFilter) with the ProductFilter data TO get a CURSOR
# Returns the Product list array arrProductList
########################################################################################
FUNCTION ProductLookupSearchDataSource(p_recProductSearch)
	DEFINE p_recProductSearch OF t_recProductSearch	
	DEFINE recProduct OF t_recProduct
	DEFINE arrProductList DYNAMIC ARRAY OF t_recProduct 
	DEFINE c_Product CURSOR
	DEFINE retError SMALLINT	
	CALL ProductLookupSearchDataSourceCursor(p_recProductSearch) RETURNING c_Product
	
	CALL arrProductList.CLEAR()

	CALL c_Product.SetResults(recProduct.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Product.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Product.FetchNext()=0)
		CALL arrProductList.append([recProduct.part_code, recProduct.desc_text])
	END WHILE	

	END IF
	
	IF arrProductList.getSize() = 0 THEN
		ERROR "No products found with the specified filter criteria"
	END IF
	
	RETURN arrProductList
END FUNCTION


########################################################################################
# FUNCTION productLookup_filter(pProductCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Product code part_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL ProductLookupFilterDataSource(recProductFilter.*) RETURNING arrProductList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Product Code part_code
#
# Example:
# 			LET pr_Product.part_code = ProductLookup(pr_Product.part_code)
########################################################################################
FUNCTION productLookup_filter(pProductCode)
	DEFINE pProductCode LIKE Product.part_code
	DEFINE arrProductList DYNAMIC ARRAY OF t_recProduct
	DEFINE recProductFilter OF t_recProductFilter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wProductLookup WITH FORM "ProductLookup_filter"


	CALL ProductLookupFilterDataSource(recProductFilter.*) RETURNING arrProductList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recProductFilter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL ProductLookupFilterDataSource(recProductFilter.*) RETURNING arrProductList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrProductList TO scProductList.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pProductCode = arrProductList[idx].part_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recProductFilter.filter_part_code IS NOT NULL
			OR recProductFilter.filter_desc_text IS NOT NULL

		THEN
			LET recProductFilter.filter_part_code = NULL
			LET recProductFilter.filter_desc_text = NULL

			CALL ProductLookupFilterDataSource(recProductFilter.*) RETURNING arrProductList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_part_code"
		IF recProductFilter.filter_part_code IS NOT NULL THEN
			LET recProductFilter.filter_part_code = NULL
			CALL ProductLookupFilterDataSource(recProductFilter.*) RETURNING arrProductList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_desc_text"
		IF recProductFilter.filter_desc_text IS NOT NULL THEN
			LET recProductFilter.filter_desc_text = NULL
			CALL ProductLookupFilterDataSource(recProductFilter.*) RETURNING arrProductList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wProductLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pProductCode	
END FUNCTION				
		

########################################################################################
# FUNCTION productLookup(pProductCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Product code part_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL ProductLookupSearchDataSource(recProductFilter.*) RETURNING arrProductList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Product Code part_code
#
# Example:
# 			LET pr_Product.part_code = ProductLookup(pr_Product.part_code)
########################################################################################
FUNCTION productLookup(pProductCode)
	DEFINE pProductCode LIKE Product.part_code
	DEFINE arrProductList DYNAMIC ARRAY OF t_recProduct
	DEFINE recProductSearch OF t_recProductSearch	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wProductLookup WITH FORM "productLookup"

	CALL ProductLookupSearchDataSource(recProductSearch.*) RETURNING arrProductList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recProductSearch.* WITHOUT DEFAULTS 
			
		ON ACTION "UPDATE-FILTER"
			CALL ProductLookupSearchDataSource(recProductSearch.*) RETURNING arrProductList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrProductList TO scProductList.* 
		BEFORE ROW
			IF arrProductList.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pProductCode = arrProductList[idx].part_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recProductSearch.filter_any_field IS NOT NULL

		THEN
			LET recProductSearch.filter_any_field = NULL

			CALL ProductLookupSearchDataSource(recProductSearch.*) RETURNING arrProductList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_part_code"
		IF recProductSearch.filter_any_field IS NOT NULL THEN
			LET recProductSearch.filter_any_field = NULL
			CALL ProductLookupSearchDataSource(recProductSearch.*) RETURNING arrProductList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wProductLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pProductCode	
END FUNCTION				

############################################
# FUNCTION import_product()
############################################
FUNCTION import_product()
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
	DEFINE p_desc_text LIKE company.name_text
	DEFINE p_country_text LIKE country.country_text
	DEFINE p_language_text LIKE language.language_text
	DEFINE load_file STRING
	DEFINE tmpMsg STRING
	
	DEFINE rec_product OF t_recProduct_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wProductImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import Product (List) Data (table: product)" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_product
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_product(
    part_code CHAR(15),
    desc_text CHAR(36),
    desc2_text CHAR(36),
    cat_code CHAR(3),
    class_code CHAR(8),
    ref_code CHAR(10),
    alter_part_code CHAR(15),
    super_part_code CHAR(15),
    compn_part_code CHAR(15),
    tariff_code CHAR(12),
    oem_text CHAR(30),
    weight_qty float,
    cubic_qty float,
    serial_flag CHAR(1),
    setup_date DATE,
    target_turn_qty float,
    stock_turn_qty float,
    stock_days_num DECIMAL(7,0),
    last_calc_date DATE,
    pur_uom_code CHAR(4),
    pur_stk_con_qty float,
    stock_uom_code CHAR(4),
    stk_sel_con_qty float,
    sell_uom_code CHAR(4),
    outer_qty DECIMAL(7),
    outer_sur_per DECIMAL(6,3),
    bar_code_text CHAR(20),
    days_lead_num SMALLINT,
    vend_code CHAR(8),
    min_ord_qty float,
    days_warr_num INTEGER,
    inven_method_ind CHAR(1),
    total_tax_flag CHAR(1),
    status_ind CHAR(1),
    status_date DATE,
    short_desc_text CHAR(15),
    min_month_amt DECIMAL(16,2),
    min_quart_amt DECIMAL(16,2),
    min_year_amt DECIMAL(16,2),
    prodgrp_code CHAR(3),
    maingrp_code CHAR(3),
    back_order_flag CHAR(1),
    disc_allow_flag CHAR(1),
    bonus_allow_flag CHAR(1),
    trade_in_flag CHAR(1),
    price_inv_flag CHAR(1),
    ref1_code CHAR(10),
    ref2_code CHAR(10),
    ref3_code CHAR(10),
    ref4_code CHAR(10),
    ref5_code CHAR(10),
    ref6_code CHAR(10),
    ref7_code CHAR(10),
    ref8_code CHAR(10),
    price_uom_code CHAR(4),
    area_qty float,
    length_qty float,
    pack_qty float,
    dg_code CHAR(3),
    ware_code CHAR(3)
    
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_product	#we need TO INITIALIZE it, delete all rows
		END IF
		
		WHENEVER ERROR STOP	
----------------------------------------------		

	# for certain tables, we need TO know the country code TO identify the right data SET in the templates
	IF gl_setupRec_default_company.cmpy_code IS NOT NULL THEN
		CALL get_company_info (gl_setupRec_default_company.cmpy_code) 
		RETURNING p_desc_text,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text

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
	#	OPEN WINDOW wProductImport WITH FORM "per/setup/lib_db_data_import_01"
	#	DISPLAY "Chart of Accounts Import" TO header_text

	
		IF cmpy_code_provided = FALSE THEN

			INPUT gl_setupRec_default_company.cmpy_code, gl_setupRec_default_company.country_code,gl_setupRec_default_company.language_code 
			WITHOUT DEFAULTS 
			FROM inputRec3.*
			
				AFTER FIELD cmpy_code
					CALL get_company_info (gl_setupRec_default_company.cmpy_code)
					RETURNING p_desc_text,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text

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
							DISPLAY p_desc_text,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text 
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
					CLOSE WINDOW wProductImport
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/product-",gl_setupRec_default_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("Chart of Accounts Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_product
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_product
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_product
			LET importReport = importReport, "Code:", trim(rec_product.part_code) , "     -     Desc:", trim(rec_product.desc_text), "\n"
					
			INSERT INTO product VALUES(
			gl_setupRec_default_company.cmpy_code,
			rec_product.*
			
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_product.part_code) , "     -     Desc:", trim(rec_product.desc_text), " ->DUPLICATE = Ignored !\n"
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
		
		CLOSE WINDOW wProductImport
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_productRec(p_cmpy_code, p_part_code)
########################################################
FUNCTION exist_productRec(p_cmpy_code, p_part_code)
	DEFINE p_cmpy_code LIKE product.cmpy_code
	DEFINE p_part_code LIKE product.part_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM product 
     WHERE cmpy_code = p_cmpy_code
     AND part_code = p_part_code

	DROP TABLE temp_product
	CLOSE WINDOW wProductImport
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_product()
###############################################################
FUNCTION unload_product(p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile STRING
	
	LET unloadFile = "unl/product-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 
	UNLOAD TO unloadFile 
		SELECT * FROM product ORDER BY cmpy_code, part_code ASC
	
	LET tmpMsg = "All product data were exported/written TO:\n", unloadFile
	CALL fgl_winmessage("product Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION
###############################################################
# FUNCTION delete_product_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_product_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE product.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wproductImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Product Group (product) Delete" TO header_text
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
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing product table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM product
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table product!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table product where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wProductImport		
END FUNCTION	