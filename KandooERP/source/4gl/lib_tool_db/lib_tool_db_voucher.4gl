##############################################################################################
#TABLE voucher
##############################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"

############################################################
# FUNCTION db_voucher_get_count()
#
# Return total number of rows in voucher FROM current company
############################################################
FUNCTION db_voucher_get_count()
	DEFINE l_ret_count INT

	SELECT count(*) 
	INTO l_ret_count 
	FROM voucher 
	WHERE voucher.cmpy_code = glob_rec_kandoouser.cmpy_code
	
	RETURN l_ret_count
END FUNCTION
############################################################
# END FUNCTION db_voucher_get_count()
############################################################


############################################################
# FUNCTION db_voucher_get_count()
#
# Return total number of rows in voucher FROM current company
############################################################
FUNCTION db_voucher_get_count_by_vendor(p_vend_code)
	DEFINE p_vend_code LIKE voucher.vend_code
	DEFINE l_ret_count INT

	IF p_vend_code IS NULL THEN
		ERROR "vend_code not specified! internal error"
	END IF
	
	SELECT count(*) 
	INTO l_ret_count 
	FROM voucher 
	WHERE voucher.cmpy_code = glob_rec_kandoouser.cmpy_code
	AND vend_code = p_vend_code

	RETURN l_ret_count
END FUNCTION
############################################################
# END FUNCTION db_voucher_get_count()
############################################################


############################################################
# FUNCTION db_voucher_get_count_approved(p_approved_code)
#
# Return total number of rows in voucher FROM current company
############################################################
FUNCTION db_voucher_get_count_approved(p_approved_code)
	DEFINE p_approved_code LIKE voucher.vend_code
	DEFINE l_ret_count INT

	IF p_approved_code IS NULL THEN
		ERROR "Approval Code (approved_code) not specified! internal error"
	END IF
	
	SELECT count(*) 
	INTO l_ret_count 
	FROM voucher 
	WHERE voucher.cmpy_code = glob_rec_kandoouser.cmpy_code
	AND approved_code = p_approved_code

	RETURN l_ret_count
END FUNCTION
############################################################
# END FUNCTION db_voucher_get_count_approved(p_approved_code)
############################################################


############################################################
# FUNCTION db_voucher_pk_exists(p_vouch_code,p_vend_code)
#
# Validate PK - Unique
############################################################
#	CONSTANT UI_OFF SMALLINT = 0
#	CONSTANT UI_ON SMALLINT = 1
#	CONSTANT UI_FK SMALLINT = 2
#	CONSTANT UI_PK SMALLINT = 3
############################################################
FUNCTION db_voucher_pk_exists(p_ui,p_vouch_code,p_vend_code)
	DEFINE p_ui SMALLINT
	DEFINE p_vouch_code LIKE voucher.vouch_code
	DEFINE p_vend_code LIKE voucher.vend_code	
	DEFINE l_rec_count INT
	DEFINE l_ret_exists BOOLEAN	
--	DEFINE msgStr STRING
	
	IF p_vouch_code IS NULL THEN
		IF p_ui != UI_OFF THEN
			ERROR "Voucher Code can not be empty"	
		END IF
		RETURN FALSE
	END IF


	IF p_vend_code IS NULL THEN
		IF p_ui != UI_OFF THEN
			ERROR "Voucher Vendor Code can not be empty"	
		END IF
		RETURN FALSE
	END IF
			
	SELECT count(*) INTO l_rec_count FROM voucher 
	WHERE voucher.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND voucher.vouch_code = p_vouch_code
	AND voucher.vend_code = p_vend_code
	
	IF l_rec_count <> 0 THEN
		LET l_ret_exists = TRUE	
		IF p_ui = UI_ON THEN
			MESSAGE "Voucher Code with VendorCode exists! (", trim(p_vouch_code), "/", trim(p_vend_code)  ,")"
		END IF
		IF p_ui = UI_PK THEN
			MESSAGE "Voucher Code with VendorCode already exists! (", trim(p_vouch_code), "/", trim(p_vend_code)  ,")"
		END IF
	ELSE
		LET l_ret_exists = FALSE	
		IF p_ui = UI_FK THEN
			MESSAGE "Voucher Code with VendorCode does not exists! (", trim(p_vouch_code), "/", trim(p_vend_code)  ,")"
		END IF
	END IF
	
	RETURN l_ret_exists
END FUNCTION
############################################################
# END FUNCTION db_voucher_pk_exists(p_vouch_code,p_vend_code)
############################################################


############################################################
# FUNCTION db_voucher_get_rec(p_ui_mode,p_vouch_code,p_vend_code)
#
# RETURN l_rec_voucher.*
############################################################
FUNCTION db_voucher_get_rec(p_ui_mode,p_vouch_code,p_vend_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_vouch_code LIKE voucher.vouch_code
	DEFINE p_vend_code LIKE voucher.vend_code
	DEFINE l_rec_voucher RECORD LIKE voucher.*

	IF p_vouch_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN	
			ERROR "Invalid voucher code ", trim(p_vouch_code), " in db_voucher_get_rec()"
		END IF
		
		RETURN NULL
	END IF 
	IF p_vend_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Invalid vendor code ", trim(p_vend_code), " in db_voucher_get_rec()"
		END IF
		
		RETURN NULL
	END IF 

  SELECT *
    INTO l_rec_voucher.*
    FROM voucher
   WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
   	AND vouch_code= p_vouch_code
    AND vend_code = p_vend_code

	IF sqlca.sqlcode != 0 THEN 
   	IF p_ui_mode != UI_OFF THEN
      ERROR "Voucher with vouch_code=", trim(p_vouch_code), "/", trim(p_vend_code), " NOT found"
		END IF
		INITIALIZE l_rec_voucher.* TO NULL  
	ELSE
	END IF
		         
	RETURN l_rec_voucher.*		         
END FUNCTION	
############################################################
# END FUNCTION db_voucher_get_rec(p_ui_mode,p_vouch_code,p_vend_code)
############################################################


############################################################
# FUNCTION db_voucher_get_inv_text(p_ui_mode,p_vouch_code,p_vend_code)
# RETURN l_ret_inv_text
#
# Get invoice text of voucher record
############################################################
FUNCTION db_voucher_get_inv_text(p_ui_mode,p_vouch_code,p_vend_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_vouch_code LIKE voucher.vouch_code
	DEFINE p_vend_code LIKE voucher.vend_code
	DEFINE l_ret_inv_text LIKE voucher.inv_text

	IF p_vouch_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN	
			ERROR "Invalid voucher code ", trim(p_vouch_code), " in db_voucher_get_rec()"
		END IF
		
		RETURN NULL
	END IF 
	IF p_vend_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Invalid vendor code ", trim(p_vend_code), " in db_voucher_get_rec()"
		END IF
		
		RETURN NULL
	END IF 

	SELECT inv_text 
	INTO l_ret_inv_text 
	FROM voucher 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
	AND vouch_code= p_vouch_code
	AND vend_code = p_vend_code						  		
	
	IF sqlca.sqlcode != 0 THEN
   	IF p_ui_mode != UI_OFF THEN
      ERROR "Voucher with vouch_code=", trim(p_vouch_code), "/", trim(p_vend_code), " NOT found"
		END IF		
		LET l_ret_inv_text = NULL
	ELSE
		#
	END IF	
	
	RETURN l_ret_inv_text
END FUNCTION
############################################################
# END FUNCTION db_voucher_get_inv_text(p_ui_mode,p_vouch_code,p_vend_code)
############################################################
		

########################################################################################################################
# 
# Get Array record data from DB
#
########################################################################################################################


############################################################
# FUNCTION db_voucher_get_arr_rec_vo_ve_da_ye_pe_ta_da(p_query_type,p_query_or_where_text)
#
#
############################################################
FUNCTION db_voucher_get_arr_rec_vo_ve_da_ye_pe_ta_da(p_query_type,p_query_or_where_text)
	DEFINE p_query_type SMALLINT
	DEFINE p_query_or_where_text VARCHAR(500)
	DEFINE l_query_text VARCHAR(500)
	DEFINE l_where_text VARCHAR(500)
	DEFINE l_arr_rec_voucher DYNAMIC ARRAY OF t_rec_voucher_vo_ve_da_ye_pe_ta_da
#	DEFINE l_rec_voucher t_rec_voucher_i_d_t
	DEFINE l_idx SMALLINT
	
	#p_query_text is optional
	CASE p_query_type
		WHEN FILTER_QUERY_OFF
			LET l_query_text = 
				"SELECT vouch_code,vend_code,vouch_date,year_num,period_num,total_amt,dist_amt FROM voucher ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ", 
				"ORDER BY vouch_code, vend_code " 	


#		WHEN FILTER_QUERY_ON
#			LET l_query_text = p_query_or_where_text

		WHEN FILTER_QUERY_WHERE
			LET l_where_text = p_query_or_where_text
			LET l_query_text = 
				"SELECT vouch_code,vend_code,vouch_date,year_num,period_num,total_amt,dist_amt FROM voucher ",
				"WHERE ", l_where_text clipped," ",
				"AND cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ", 				
				"ORDER BY vouch_code, vend_code " 	

		WHEN FILTER_QUERY_SELECT
			LET l_query_text = p_query_or_where_text		
		
		OTHERWISE
			LET l_query_text = 
				"SELECT vouch_code,vend_code,vouch_date,year_num,period_num,total_amt,dist_amt FROM voucher ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ", 
				"ORDER BY vouch_code, vend_code " 	
				 				
	END CASE

	PREPARE s_voucher FROM l_query_text
	DECLARE c_voucher CURSOR FOR s_voucher

	LET l_idx = 1
	FOREACH c_voucher INTO l_arr_rec_voucher[l_idx].*
		LET l_idx = l_idx + 1
	END FOREACH

	IF sqlca.sqlcode < 0 THEN   	
		LET l_arr_rec_voucher = NULL	                                                                                        
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         
	
	FREE c_voucher
	
	RETURN l_arr_rec_voucher		                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_voucher_get_arr_rec_vo_ve_da_ye_pe_ta_da(p_query_type,p_query_or_where_text)
############################################################
		

############################################################
# FUNCTION db_voucher_get_arr_rec_vo_ve_da_ye_pe_ta_da_with_scrollflag(p_query_type,p_query_or_where_text)
#
#
############################################################
FUNCTION db_voucher_get_arr_rec_vo_ve_da_ye_pe_ta_da_with_scrollflag(p_query_type,p_query_or_where_text)
	DEFINE p_query_type SMALLINT
	DEFINE p_query_or_where_text VARCHAR(500)
	DEFINE l_query_text VARCHAR(500)
	DEFINE l_where_text VARCHAR(500)
	DEFINE l_arr_rec_voucher DYNAMIC ARRAY OF t_rec_voucher_vo_ve_da_ye_pe_ta_da_with_scrollflag
	DEFINE l_rec_voucher t_rec_voucher_vo_ve_da_ye_pe_ta_da
	DEFINE l_idx SMALLINT
	
	#p_query_text is optional
	CASE p_query_type
		WHEN FILTER_QUERY_OFF
			LET l_query_text = 
				"SELECT vouch_code,vend_code,vouch_date,year_num,period_num,total_amt,dist_amt FROM voucher ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ", 
				"ORDER BY vouch_code, vend_code " 	


#		WHEN FILTER_QUERY_ON
#			LET l_query_text = p_query_or_where_text

		WHEN FILTER_QUERY_WHERE
			LET l_where_text = p_query_or_where_text
			LET l_query_text = 
				"SELECT vouch_code,vend_code,vouch_date,year_num,period_num,total_amt,dist_amt FROM voucher ",
				"WHERE ", l_where_text clipped," ",
				"AND cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ", 				
				"ORDER BY vouch_code, vend_code " 	

		WHEN FILTER_QUERY_SELECT
			LET l_query_text = p_query_or_where_text		
		
		OTHERWISE
			LET l_query_text = 
				"SELECT vouch_code,vend_code,vouch_date,year_num,period_num,total_amt,dist_amt FROM voucher ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ", 
				"ORDER BY vouch_code, vend_code " 	
				 				
	END CASE

	PREPARE s_voucher2 FROM l_query_text
	DECLARE c_voucher2 CURSOR FOR s_voucher2

	LET l_idx = 1
	FOREACH c_voucher2 INTO l_rec_voucher.*
		LET l_arr_rec_voucher[l_idx].vouch_code = l_rec_voucher.vouch_code
		LET l_arr_rec_voucher[l_idx].vend_code = l_rec_voucher.vend_code
		LET l_arr_rec_voucher[l_idx].vouch_date = l_rec_voucher.vouch_date
		LET l_arr_rec_voucher[l_idx].year_num = l_rec_voucher.year_num
		LET l_arr_rec_voucher[l_idx].period_num = l_rec_voucher.period_num
		LET l_arr_rec_voucher[l_idx].total_amt = l_rec_voucher.total_amt
		LET l_arr_rec_voucher[l_idx].dist_amt = l_rec_voucher.dist_amt

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF
				
		LET l_idx = l_idx + 1
	END FOREACH

	IF sqlca.sqlcode < 0 THEN   	
		LET l_arr_rec_voucher = NULL	                                                                                        
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	        
	
	FREE c_voucher2 

	RETURN l_arr_rec_voucher		                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_voucher_get_arr_rec_vo_ve_da_ye_pe_ta_da_with_scrollflag(p_query_type,p_query_or_where_text)
############################################################