--DATABASE kandoodb
GLOBALS "../common/glob_DATABASE.4gl" 

# Vendor record types
	DEFINE t_rec_vendor_vc_nt  
		TYPE AS RECORD
			vend_code LIKE vendor.vend_code,
			name_text LIKE vendor.name_text,
			city_text LIKE vendor.city_text,
			contact_text LIKE vendor.contact_text
		END RECORD 

	DEFINE t_rec_vendor_filter  
		TYPE AS RECORD
			filter_vend_code LIKE vendor.vend_code,
			filter_name_text LIKE vendor.name_text,
			filter_city_text LIKE vendor.city_text,
			filter_contact_text LIKE vendor.contact_text
		END RECORD 
		

########################################################################################
# FUNCTION getVendorCode(pVendorName)
#-------------------------------------------------------
# Returns the vendor code (vendor.vend_code) matching the pVendorName (vendor.name_text)
########################################################################################
FUNCTION getVendorCode(pVendorName)
	DEFINE pVendorName LIKE vendor.name_text
	DEFINE ret_vend_code LIKE vendor.vend_code
	
	IF pVendorName IS NOT NULL THEN
	
		SELECT vend_code INTO ret_vend_code 
		FROM vendor 
		WHERE name_text = pVendorName
          	
	END IF
	RETURN ret_vend_code
END FUNCTION	

########################################################################################
# FUNCTION getVendorCount()
#-------------------------------------------------------
# Returns the number of vendor entries for the current company
########################################################################################
FUNCTION getVendorCount()
	DEFINE ret_venderCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_vendor CURSOR
	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM vendor ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
	CALL c_vendor.DECLARE(sqlQuery) #CURSOR FOR getVendor
	CALL c_vendor.SetResults(ret_venderCount)  --define variable for result output
	CALL c_vendor.OPEN()
	CALL c_vendor.FetchNext()

	RETURN ret_venderCount
END FUNCTION	

########################################################################################
# FUNCTION vendorLookupFilterDataSourceCursor(pRecVendorFilter)
#-------------------------------------------------------
# Returns the vendor CURSOR for the lookup query
########################################################################################
FUNCTION vendorLookupFilterDataSourceCursor(pRecVendorFilter)
	DEFINE pRecVendorFilter OF t_rec_vendor_filter
	DEFINE sqlQuery STRING
	DEFINE c_vendor CURSOR
	
	LET sqlQuery =	"SELECT ",
									"vendor.vend_code, ", 
									"vendor.name_text, ",
									"vendor.city_text, ",
									"vendor.contact_text ", 
									"FROM vendor ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF pRecVendorFilter.filter_vend_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND vend_code LIKE '", pRecVendorFilter.filter_vend_code CLIPPED, "%' "  
	END IF									

	IF pRecVendorFilter.filter_name_text IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND name_text LIKE '", pRecVendorFilter.filter_name_text CLIPPED, "%' "  
	END IF	
	
	IF pRecVendorFilter.filter_city_text IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND city_text LIKE '", pRecVendorFilter.filter_city_text CLIPPED, "%' "  
	END IF	

	IF pRecVendorFilter.filter_contact_text IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND contact_text LIKE '", pRecVendorFilter.filter_contact_text CLIPPED, "%' "  
	END IF	
			
	LET sqlQuery = sqlQuery, " ORDER BY vend_code"

	CALL c_vendor.DECLARE(sqlQuery) 
	
	RETURN c_vendor
END FUNCTION

########################################################################################
# FUNCTION vendorLookupSearchDataSourceCursor(pRecVendorFilter)
#-------------------------------------------------------
# Returns the vendor CURSOR for the lookup query
########################################################################################
FUNCTION vendorLookupSearchDataSourceCursor(p_filter_any_field)
	DEFINE sqlQuery STRING
	DEFINE c_vendor CURSOR
	DEFINE p_filter_any_field STRING
		
	LET sqlQuery =	"SELECT ",
									"vendor.vend_code, ", 
									"vendor.name_text, ",
									"vendor.city_text, ",
									"vendor.contact_text ", 
									"FROM vendor ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF p_filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND (vend_code LIKE '", p_filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR name_text LIKE '", p_filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR city_text LIKE '", p_filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR contact_text LIKE '", p_filter_any_field CLIPPED, "%' )"  						
	END IF									
			
	LET sqlQuery = sqlQuery, " ORDER BY vend_code"

	CALL c_vendor.DECLARE(sqlQuery) #CURSOR FOR getVendor

	RETURN c_vendor
END FUNCTION

########################################################################################
# FUNCTION vendorLookupFilterDataSource(pRecVendorFilter)
#-------------------------------------------------------
# CALLS vendorLookupDataSource(pRecVendorFilter) with the vendorFilter data TO get a CURSOR
# Returns the vendor list array arrVendorList
########################################################################################
FUNCTION vendorLookupFilterDataSource(pRecVendorFilter)
	DEFINE pRecVendorFilter OF t_rec_vendor_filter
	DEFINE recVendor OF t_rec_vendor_vc_nt
	DEFINE arrVendorList DYNAMIC ARRAY OF t_rec_vendor_vc_nt 
	DEFINE c_vendor CURSOR
		
	CALL vendorLookupFilterDataSourceCursor(pRecVendorFilter.*) RETURNING c_vendor
	
	CALL arrVendorList.CLEAR()

	CALL c_vendor.SetResults(recVendor.*)  --define variable for result output
	CALL c_vendor.OPEN()
	
	WHILE  (c_vendor.FetchNext()=0)
		CALL arrVendorList.append([recVendor.vend_code, recVendor.name_text,recVendor.city_text,recVendor.contact_text])
	END WHILE

	IF arrVendorList.getSize() = 0 THEN
		ERROR "No Vendors found with the specified filter criteria"
	END IF
	
	RETURN arrVendorList
END FUNCTION	


########################################################################################
# FUNCTION vendorLookupSearchDataSource(pRecVendorFilter)
#-------------------------------------------------------
# CALLS vendorLookupSearchDataSource(pRecVendorFilter) with the vendorFilter data TO get a CURSOR
# Returns the vendor list array arrVendorList
########################################################################################
FUNCTION vendorLookupSearchDataSource(p_filter_any_field)
	DEFINE p_filter_any_field STRING
	DEFINE recVendor OF t_rec_vendor_vc_nt
	DEFINE arrVendorList DYNAMIC ARRAY OF t_rec_vendor_vc_nt 
	DEFINE c_vendor CURSOR
		
	CALL vendorLookupSearchDataSourceCursor(p_filter_any_field) RETURNING c_vendor
	
	CALL arrVendorList.CLEAR()

	CALL c_vendor.SetResults(recVendor.*)  --define variable for result output
	CALL c_vendor.OPEN()
	
	WHILE  (c_vendor.FetchNext()=0)
		CALL arrVendorList.append([recVendor.vend_code, recVendor.name_text,recVendor.city_text,recVendor.contact_text])
	END WHILE

	IF arrVendorList.getSize() = 0 THEN
		ERROR "No Vendors found with the specified filter criteria"
	END IF
	
	RETURN arrVendorList
END FUNCTION	


########################################################################################
# FUNCTION vendorLookup_filter(pVendorCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required vendor code vend_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL vendorLookupSearchDataSource(recVendorFilter.*) RETURNING arrVendorList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the vendor Code vend_code
#
# Example:
# 			LET pr_vendor.vend_code = vendorLookup(pr_vendor.vend_code)
########################################################################################
FUNCTION vendorLookup_filter(pVendorCode)
	DEFINE pVendorCode LIKE vendor.vend_code
	DEFINE arrVendorList DYNAMIC ARRAY OF t_rec_vendor_vc_nt
	DEFINE recVendorFilter OF t_rec_vendor_filter	
	DEFINE idx SMALLINT
		
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wVendorLookup WITH FORM "vendorLookup_filter" 

	CALL vendorLookupFilterDataSource(recVendorFilter.*) RETURNING arrVendorList

	DISPLAY arrVendorList.getSize() TO lbResultCount
	DISPLAY getVendorCount() TO  lbTotalCount
	
	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)
	
	INPUT BY NAME recVendorFilter.* WITHOUT DEFAULTS 
						
		ON ACTION "UPDATE-FILTER"
			CALL vendorLookupSearchDataSource(recVendorFilter.*) RETURNING arrVendorList
			DISPLAY arrVendorList.getSize() TO lbResultCount
			DISPLAY getVendorCount() TO  lbTotalCount
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
				OR recVendorFilter.filter_city_text IS NOT NULL
				OR recVendorFilter.filter_contact_text IS NOT NULL
			THEN
				LET recVendorFilter.filter_vend_code = NULL
				LET recVendorFilter.filter_name_text = NULL
				LET recVendorFilter.filter_city_text = NULL
				LET recVendorFilter.filter_contact_text = NULL
				CALL vendorLookupSearchDataSource(recVendorFilter.*) RETURNING arrVendorList
				
				CALL ui.interface.refresh()
			END IF

		ON ACTION "clearFilter_vend_code"
			IF recVendorFilter.filter_vend_code IS NOT NULL THEN
				LET recVendorFilter.filter_vend_code = NULL
				CALL vendorLookupSearchDataSource(recVendorFilter.*) RETURNING arrVendorList

				CALL ui.interface.refresh()
			END IF	
			
		ON ACTION "clearFilter_name_text"
			IF recVendorFilter.filter_name_text IS NOT NULL THEN
				LET recVendorFilter.filter_name_text = NULL
				CALL vendorLookupSearchDataSource(recVendorFilter.*) RETURNING arrVendorList

				CALL ui.interface.refresh()
			END IF		
			
		ON ACTION "clearFilter_city_text"
			IF recVendorFilter.filter_city_text IS NOT NULL THEN		
				LET recVendorFilter.filter_city_text = NULL
				CALL vendorLookupSearchDataSource(recVendorFilter.*) RETURNING arrVendorList

				CALL ui.interface.refresh()
			END IF		
			
		ON ACTION "clearFilter_contact_text"
			IF recVendorFilter.filter_contact_text IS NOT NULL THEN		
				LET recVendorFilter.filter_contact_text = NULL
				CALL vendorLookupSearchDataSource(recVendorFilter.*) RETURNING arrVendorList

				CALL ui.interface.refresh()
			END IF		

		BEFORE DIALOG
			CALL publish_toolbar("kandoo","lib_db_vendor","dialog-1") 

		ON ACTION "WEB-HELP"
			CALL onlineHelp(getModuleId(),NULL)
			ON ACTION "actToolbarManager"
		 	CALL setupToolbar()		
		 		
	END DIALOG
	##########################################
		
	CLOSE WINDOW wVendorLookup
	
	OPTIONS INPUT NO WRAP
	
	RETURN pVendorCode	
END FUNCTION		

########################################################################################
# FUNCTION vendorLookup(pVendorCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required vendor code vend_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL vendorLookupDataSource(recVendorFilter.*) RETURNING arrVendorList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the vendor Code vend_code
#
# Example:
# 			LET pr_vendor.vend_code = vendorLookup(pr_vendor.vend_code)
########################################################################################
FUNCTION vendorLookup(pVendorCode)
	DEFINE pVendorCode LIKE vendor.vend_code
	DEFINE idx SMALLINT
	DEFINE arrVendorList DYNAMIC ARRAY OF t_rec_vendor_vc_nt
	DEFINE filter_any_field STRING
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wVendorLookup WITH FORM "vendorLookup" 

	CALL vendorLookupSearchDataSource(filter_any_field) RETURNING arrVendorList

	DISPLAY arrVendorList.getSize() TO lbResultCount
	DISPLAY getVendorCount() TO  lbTotalCount	
				
	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME filter_any_field WITHOUT DEFAULTS
		ON ACTION "UPDATE-FILTER"
			CALL vendorLookupFilterDataSource(filter_any_field) RETURNING arrVendorList
			DISPLAY arrVendorList.getSize() TO lbResultCount
			DISPLAY getVendorCount() TO  lbTotalCount
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
	
		
			IF filter_any_field IS NOT NULL	THEN
				LET filter_any_field = NULL
				CALL vendorLookupSearchDataSource(filter_any_field) RETURNING arrVendorList

				CALL ui.interface.refresh()
			END IF		



		BEFORE DIALOG
			CALL publish_toolbar("kandoo","lib_db_vendor","dialog-1") 

		ON ACTION "WEB-HELP"
			CALL onlineHelp(getModuleId(),NULL)
			ON ACTION "actToolbarManager"
		 	CALL setupToolbar()			
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wVendorLookup
	
	OPTIONS INPUT NO WRAP
	RETURN pVendorCode	
END FUNCTION		
	

