##############################################################################################
#TABLE vendor
##############################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"
############################################################
# FUNCTION db_term_get_count()
#
# Return total number of rows in vendor FROM current company
############################################################
FUNCTION db_vendor_get_count()
	DEFINE ret INT
	
	SQL
		SELECT count(*) 
		INTO $ret 
		FROM vendor 
		WHERE vendor.cmpy_code = $glob_rec_kandoouser.cmpy_code
	END SQL
	
	RETURN ret
END FUNCTION


############################################################
# FUNCTION db_vendor_pk_exists(p_ui_mode,p_vend_code)
#
# Validate PK - Unique
############################################################
FUNCTION db_vendor_pk_exists(p_ui_mode,p_vend_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_vend_code LIKE vendor.vend_code
	DEFINE l_ret INT
	DEFINE l_msg STRING
	
	IF p_vend_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Vendor Code can NOT be empty"
		END IF
		RETURN FALSE
	END IF
			
	SQL
		SELECT count(*) 
		INTO $l_ret 
		FROM vendor 
		WHERE vendor.cmpy_code = $glob_rec_kandoouser.cmpy_code 
		AND vendor.vend_code = $p_vend_code		
	END SQL

	IF l_ret > 0 THEN
		RETURN TRUE
	ELSE
		IF p_ui_mode != UI_OFF THEN
			LET l_msg = "No Vendor found with the vendor code ", trim(p_vend_code)
			ERROR l_msg
		END IF

		RETURN FALSE
	END IF	
END FUNCTION


############################################################
# FUNCTION db_vendor_get_rec(p_ui_mode,p_vend_code)
#
#
############################################################
FUNCTION db_vendor_get_rec(p_ui_mode,p_vend_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_vend_code LIKE vendor.vend_code
	DEFINE l_rec_vendor RECORD LIKE vendor.*

	IF p_vend_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Vendor Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	SQL
		SELECT *
		INTO $l_rec_vendor.*
		FROM vendor
			WHERE vend_code = $p_vend_code
				AND cmpy_code = $glob_rec_kandoouser.cmpy_code
	END SQL 

	IF sqlca.sqlcode != 0 THEN 
		IF p_ui_mode != UI_OFF THEN
			ERROR "Vendor with Vendor Code ",trim(p_vend_code),  "NOT found"
		END IF
		RETURN NULL
	ELSE
		RETURN l_rec_vendor.*
	END IF 
END FUNCTION 


########################################################################################################################
#
# ARRAY DATASOURCE
#
########################################################################################################################


############################################################
# FUNCTION db_vendor_get_arr_rec_short(p_where_text)
# RETURN l_arr_rec_vendor 
# Return vendor rec array
############################################################
FUNCTION db_vendor_get_arr_rec_vc_nt_ct(p_where_text)
	DEFINE p_where_text STRING
	DEFINE l_query_text VARCHAR(500)
	DEFINE l_rec_vendor OF t_rec_vendor_vc_nt_ct
	DEFINE l_arr_rec_vendor DYNAMIC ARRAY OF t_rec_vendor_vc_nt_ct	
	#DEFINE l_arr_rec_vendor DYNAMIC ARRAY OF
	#	RECORD
	#		vendor_code LIKE vendor.vendor_code,
	#		desc_text LIKE vendor.desc_text
	#	END RECORD
	DEFINE l_idx SMALLINT --loop control
	DEFINE l_msgresp LIKE language.yes_flag


  LET l_msgresp = kandoomsg("U",1002,"")
  #1002 " Searching database - please wait"

	LET l_query_text = "SELECT vend_code, name_text, contact_text FROM vendor ",
                        "WHERE cmpy_code =\"",glob_rec_kandoouser.cmpy_code,"\" "

	IF p_where_text IS NOT NULL THEN                        
		LET l_query_text =  l_query_text CLIPPED, " AND ", trim(p_where_text), " "
	END IF
			                      
	LET l_query_text =  l_query_text CLIPPED,
			"ORDER BY ",
				"vend_code"
				
	PREPARE s_vendor FROM l_query_text
	DECLARE c_vendor CURSOR FOR s_vendor


   LET l_idx = 0
   FOREACH c_vendor INTO l_rec_vendor.*
      LET l_idx = l_idx + 1
      LET l_arr_rec_vendor[l_idx].vend_code = l_rec_vendor.vend_code
      LET l_arr_rec_vendor[l_idx].name_text = l_rec_vendor.name_text
      LET l_arr_rec_vendor[l_idx].contact_text = l_rec_vendor.contact_text
      
   END FOREACH

	RETURN l_arr_rec_vendor  
END FUNCTION	


########################################################################################################################
#
# Field Accessor
#
########################################################################################################################

############################################################
# FUNCTION db_vendor_get_name_text(p_ui_mode,p_vend_code)
#
# Return vendor name vendor.name_text
############################################################
FUNCTION db_vendor_get_name_text(p_ui_mode,p_vend_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_vend_code LIKE vendor.vend_code
	DEFINE l_vend_name LIKE vendor.name_text
	
	IF p_vend_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Vendor Code can not be empty"
		END IF
		RETURN NULL
	END IF

	SELECT name_text INTO l_vend_name
	FROM vendor
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	AND 
			vend_code = p_vend_code
	
	IF STATUS = NOTFOUND THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Vendor Description with Code ",trim(p_vend_code),  "NOT found"
		END IF			
		LET l_vend_name = NULL
	ELSE
		#
	END IF	
	
	RETURN l_vend_name
END FUNCTION


############################################################
# FUNCTION db_vendor_get_currency_code(p_vend_code)
#
# Return vendor name vendor.currency_code
############################################################
FUNCTION db_vendor_get_currency_code(p_ui_mode,p_vend_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_vend_code LIKE vendor.vend_code
	DEFINE l_currency_code LIKE vendor.currency_code
	DEFINE l_cmpy_code LIKE company.cmpy_code
	
	IF p_vend_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Vendor Code can not be empty"
		END IF
		RETURN NULL
	END IF
	
	LET l_cmpy_code = getCurrentUser_cmpy_code()

	
		SELECT currency_code 
		INTO l_currency_code
		FROM vendor
		WHERE cmpy_code = l_cmpy_code
		AND vend_code  = p_vend_code
	
	
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Vendor Description with Code ",trim(p_vend_code),  "NOT found"
		END IF			
		LET l_currency_code = NULL
	ELSE
		#
	END IF	
	
	RETURN l_currency_code
END FUNCTION


############################################################
# FUNCTION db_vendor_get_tax_code(p_ui_mode,p_vend_code)
#
# Return vendor name vendor.currency_code
############################################################
FUNCTION db_vendor_get_tax_code(p_ui_mode,p_vend_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_vend_code LIKE vendor.vend_code
	DEFINE l_tax_code LIKE vendor.tax_code
	DEFINE l_cmpy_code LIKE company.cmpy_code
	
	IF p_vend_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Vendor Code can not be empty"
		END IF
		RETURN NULL
	END IF
	
	LET l_cmpy_code = getCurrentUser_cmpy_code()

	
		SELECT tax_code 
		INTO l_tax_code
		FROM vendor
		WHERE cmpy_code = l_cmpy_code
		AND vend_code  = p_vend_code
	
	
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Vendor Description with Code ",trim(p_vend_code),  "NOT found"
		END IF			
		LET l_tax_code = NULL
	ELSE
		#
	END IF	
	
	RETURN l_tax_code
END FUNCTION

############################################################
# FUNCTION db_vendor_get_country_code(p_vend_code)
#
# Return vendor name vendor.country_code
############################################################
FUNCTION db_vendor_get_country_code(p_ui_mode,p_vend_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_vend_code LIKE vendor.vend_code
	DEFINE l_country_code LIKE vendor.country_code
	DEFINE l_cmpy_code LIKE company.cmpy_code
	
	IF p_vend_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Vendor Code can not be empty"
		END IF
		RETURN NULL
	END IF
	
	LET l_cmpy_code = getCurrentUser_cmpy_code()

	
		SELECT country_code 
		INTO l_country_code
		FROM vendor
		WHERE cmpy_code = l_cmpy_code
		AND vend_code  = p_vend_code
	
	
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Vendor Description with Code ",trim(p_vend_code),  "NOT found"
		END IF			
		LET l_country_code = NULL
	ELSE
		#
	END IF	
	
	RETURN l_country_code
END FUNCTION

############################################################
# FUNCTION db_vendor_get_city_text(p_vend_code)
#
# Return vendor name vendor.city_text
############################################################
FUNCTION db_vendor_get_city_text(p_ui_mode,p_vend_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_vend_code LIKE vendor.vend_code
	DEFINE l_city_text LIKE vendor.city_text
	DEFINE l_cmpy_code LIKE company.cmpy_code
	
	IF p_vend_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Vendor Code can not be empty"
		END IF
		RETURN NULL
	END IF
	
	LET l_cmpy_code = getCurrentUser_cmpy_code()

	
		SELECT city_text 
		INTO l_city_text
		FROM vendor
		WHERE cmpy_code = l_cmpy_code
		AND vend_code  = p_vend_code
	
	
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Vendor Description with Code ",trim(p_vend_code),  "NOT found"
		END IF			
		LET l_city_text = NULL
	ELSE
		#
	END IF	
	
	RETURN l_city_text
END FUNCTION

############################################################
# FUNCTION db_vendor_get_state_code(p_vend_code)
#
# Return vendor name vendor.state_code
############################################################
FUNCTION db_vendor_get_state_code(p_ui_mode,p_vend_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_vend_code LIKE vendor.vend_code
	DEFINE l_state_code LIKE vendor.state_code
	DEFINE l_cmpy_code LIKE company.cmpy_code
	
	IF p_vend_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Vendor Code can not be empty"
		END IF
		RETURN NULL
	END IF
	
	LET l_cmpy_code = getCurrentUser_cmpy_code()

	
		SELECT state_code 
		INTO l_state_code
		FROM vendor
		WHERE cmpy_code = l_cmpy_code
		AND vend_code  = p_vend_code
	
	
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Vendor Description with Code ",trim(p_vend_code),  "NOT found"
		END IF			
		LET l_state_code = NULL
	ELSE
		#
	END IF	
	
	RETURN l_state_code
END FUNCTION

########################################################################################################################
#
# LOOKUP
#
########################################################################################################################

########################################################################################
# FUNCTION vendorLookup(pVendorCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Vendor code vend_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL VendorLookupSearchDataSource(recVendorFilter.*) RETURNING arrVendorList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Vendor Code vend_code
#
# Example:
# 			LET pr_Vendor.vend_code = VendorLookup(pr_Vendor.vend_code)
########################################################################################
FUNCTION vendorLookup(pVendorCode)
	DEFINE pVendorCode LIKE Vendor.vend_code
	DEFINE arrVendorList DYNAMIC ARRAY OF t_rec_vendor_vc_nt
	DEFINE recVendorSearch OF t_rec_vendor_search	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wVendorLookup WITH FORM "P127"  #used TO be "vendorLookup"
	CALL winDecoration_p("P127")  -- albo  KD-752

	CALL VendorLookupSearchDataSource(recVendorSearch.*) RETURNING arrVendorList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recVendorSearch.* WITHOUT DEFAULTS 
			
		ON ACTION "UPDATE-FILTER"
			CALL arrVendorList.clear()
			CALL VendorLookupSearchDataSource(recVendorSearch.*) RETURNING arrVendorList
			DISPLAY arrVendorList.getSize() TO lbResultCount
			DISPLAY db_vendor_get_count() TO lbTotalCount
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrVendorList TO scVendorList.* 
		BEFORE ROW
			IF arrVendorList.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pVendorCode = arrVendorList[idx].vend_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recVendorSearch.filter_any_field IS NOT NULL	THEN
			LET recVendorSearch.filter_any_field = NULL
			CALL VendorLookupSearchDataSource(recVendorSearch.*) RETURNING arrVendorList
			DISPLAY arrVendorList.getSize() TO lbResultCount
			DISPLAY db_vendor_get_count() TO lbTotalCount
		
			CALL ui.interface.refresh()			
		END IF

	#ON ACTION "clearFilter_vend_code"
	#	IF recVendorSearch.filter_any_field IS NOT NULL THEN
	#		LET recVendorSearch.filter_any_field = NULL
	#		CALL VendorLookupSearchDataSource(recVendorSearch.*) RETURNING arrVendorList
	#		CALL ui.interface.refresh()
	#	END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wVendorLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pVendorCode	
END FUNCTION				


########################################################################################
# vendorLookupSearchDataSourceCursor(p_RecVendorSearch)
#-------------------------------------------------------
# Returns the Vendor CURSOR for the lookup query
########################################################################################
FUNCTION vendorLookupSearchDataSourceCursor(p_RecVendorSearch)
	DEFINE p_RecVendorSearch OF t_rec_vendor_search  
	DEFINE sqlQuery STRING
	DEFINE c_Vendor CURSOR
	
	LET sqlQuery =	"SELECT ",
									"vendor.vend_code, ", 
									"vendor.name_text ",
 
									"FROM vendor ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
	
	IF p_RecVendorSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((vend_code LIKE '", p_RecVendorSearch.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR name_text LIKE '",   p_RecVendorSearch.filter_any_field CLIPPED, "%') "  
  						
	END IF


	IF p_RecVendorSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, "ORDER BY vend_code"

	CALL c_vendor.DECLARE(sqlQuery) #CURSOR FOR vendor
	
	RETURN c_vendor
END FUNCTION


########################################################################################
# FUNCTION VendorLookupFilterDataSource(pRecVendorFilter)
#-------------------------------------------------------
# CALLS VendorLookupFilterDataSourceCursor(pRecVendorFilter) with the VendorFilter data TO get a CURSOR
# Returns the Vendor list array arrVendorList
########################################################################################
FUNCTION VendorLookupFilterDataSource(pRecVendorFilter)
	DEFINE pRecVendorFilter OF t_rec_vendor_filter
	DEFINE recVendor OF t_rec_vendor_vc_nt
	DEFINE arrVendorList DYNAMIC ARRAY OF t_rec_vendor_vc_nt 
	DEFINE c_Vendor CURSOR
	DEFINE retError SMALLINT
		
	CALL VendorLookupFilterDataSourceCursor(pRecVendorFilter.*) RETURNING c_Vendor
	
	CALL arrVendorList.CLEAR()

	CALL c_Vendor.SetResults(recVendor.*)  --define variable for result output

	
	LET retError = c_Vendor.OPEN()
	

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Vendor.FetchNext()=0)
		CALL arrVendorList.append([recVendor.vend_code, recVendor.name_text])
	END WHILE	

	END IF
	
	IF arrVendorList.getSize() = 0 THEN
		ERROR "No vendor's found with the specified filter criteria"
	END IF
	
	RETURN arrVendorList
END FUNCTION	

########################################################################################
# FUNCTION VendorLookupSearchDataSource(pRecVendorFilter)
#-------------------------------------------------------
# CALLS VendorLookupSearchDataSourceCursor(pRecVendorFilter) with the VendorFilter data TO get a CURSOR
# Returns the Vendor list array arrVendorList
########################################################################################
FUNCTION VendorLookupSearchDataSource(p_recVendorSearch)
	DEFINE p_recVendorSearch OF t_rec_vendor_search	
	DEFINE recVendor OF t_rec_vendor_vc_nt
	DEFINE arrVendorList DYNAMIC ARRAY OF t_rec_vendor_vc_nt 
	DEFINE c_Vendor CURSOR
	DEFINE retError SMALLINT	
	CALL VendorLookupSearchDataSourceCursor(p_recVendorSearch) RETURNING c_Vendor
	
	CALL arrVendorList.CLEAR()

	CALL c_Vendor.SetResults(recVendor.*)  --define variable for result output

	
	LET retError = c_Vendor.OPEN()
	

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Vendor.FetchNext()=0)
		CALL arrVendorList.append([recVendor.vend_code, recVendor.name_text])
	END WHILE	

	END IF
	
	IF arrVendorList.getSize() = 0 THEN
		ERROR "No vendor's found with the specified filter criteria"
	END IF
	
	RETURN arrVendorList
END FUNCTION


########################################################################################
# FUNCTION vendorLookup_filter(pVendorCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Vendor code vend_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL VendorLookupFilterDataSource(recVendorFilter.*) RETURNING arrVendorList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Vendor Code vend_code
#
# Example:
# 			LET pr_Vendor.vend_code = VendorLookup(pr_Vendor.vend_code)
########################################################################################
FUNCTION vendorLookup_filter(pVendorCode)
	DEFINE pVendorCode LIKE Vendor.vend_code
	DEFINE arrVendorList DYNAMIC ARRAY OF t_rec_vendor_vc_nt
	DEFINE recVendorFilter OF t_rec_vendor_filter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wVendorLookup WITH FORM "VendorLookup_filter"
   CALL winDecoration_p("VendorLookup_filter")  -- albo  KD-752

	CALL VendorLookupFilterDataSource(recVendorFilter.*) RETURNING arrVendorList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recVendorFilter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL VendorLookupFilterDataSource(recVendorFilter.*) RETURNING arrVendorList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrVendorList TO scVendorList.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pVendorCode = arrVendorList[idx].vend_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recVendorFilter.filter_vend_code IS NOT NULL
			OR recVendorFilter.filter_name_text IS NOT NULL

		THEN
			LET recVendorFilter.filter_vend_code = NULL
			LET recVendorFilter.filter_name_text = NULL

			CALL VendorLookupFilterDataSource(recVendorFilter.*) RETURNING arrVendorList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_vend_code"
		IF recVendorFilter.filter_vend_code IS NOT NULL THEN
			LET recVendorFilter.filter_vend_code = NULL
			CALL VendorLookupFilterDataSource(recVendorFilter.*) RETURNING arrVendorList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_name_text"
		IF recVendorFilter.filter_name_text IS NOT NULL THEN
			LET recVendorFilter.filter_name_text = NULL
			CALL VendorLookupFilterDataSource(recVendorFilter.*) RETURNING arrVendorList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wVendorLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pVendorCode	
END FUNCTION				
		

########################################################################################
# FUNCTION vendorLookupFilterDataSourceCursor(pRecVendorFilter)
#-------------------------------------------------------
# Returns the Vendor CURSOR for the lookup query
########################################################################################
FUNCTION vendorLookupFilterDataSourceCursor(pRecVendorFilter)
	DEFINE pRecVendorFilter OF t_rec_vendor_filter
	DEFINE sqlQuery STRING
	DEFINE c_Vendor CURSOR
	
	LET sqlQuery =	"SELECT ",
									"vendor.vend_code, ", 
									"vendor.name_text ",
									"FROM vendor ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF pRecVendorFilter.filter_vend_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND vend_code LIKE '", pRecVendorFilter.filter_vend_code CLIPPED, "%' "  
	END IF									

	IF pRecVendorFilter.filter_name_text IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND name_text LIKE '", pRecVendorFilter.filter_name_text CLIPPED, "%' "  
	END IF	
	
			
	LET sqlQuery = sqlQuery, " ORDER BY vend_code"

	CALL c_vendor.DECLARE(sqlQuery)
		
	RETURN c_vendor
END FUNCTION


		