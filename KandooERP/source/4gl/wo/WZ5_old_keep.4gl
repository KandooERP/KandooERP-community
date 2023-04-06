############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS "W_WO_GLOBALS.4gl"

############################################################
# MAIN
#
# \brief module PZ5  This Program allows the user TO enter AND maintain Vendor Types
############################################################
MAIN
	DEFINE l_rec_location RECORD LIKE location.*
	DEFINE l_arr_rec_location DYNAMIC ARRAY OF
		RECORD
			cmpy           LIKE location.cmpy_code,
			type_text           LIKE vendortype.type_text
		END RECORD
	DEFINE l_arr_select DYNAMIC ARRAY OF LIKE vendortype.type_code
	DEFINE l_arr_idx SMALLINT
	DEFINE l_msgStr STRING	 
	DEFINE l_msgresp LIKE language.yes_flag
	DEFINE l_del_count SMALLINT
	DEFINE l_idx SMALLINT

	#Initial UI Init
	CALL setModuleId("WZ5")
	CALL ui_init(0)	

	DEFER QUIT
	DEFER INTERRUPT

	CALL authenticate(getModuleId()) #authenticate
	CALL init_w_wo() #init P/AP module

	CALL location_scan()
	
END MAIN	


FUNCTION db_location_list_dataSource(p_filter,p_cmpy_code)
	DEFINE p_filter BOOLEAN
	DEFINE p_cmpy_code LIKE location.cmpy_code
	DEFINE l_rec_location t_rec_location_cc_lc_dt_ad
	DEFINE l_arr_rec_location DYNAMIC ARRAY OF t_rec_location_cc_lc_dt_ad
#	DEFINE l_arr_rec_location DYNAMIC ARRAY OF
#		RECORD
#			cmpy_code            char(2),
#			locn_code            nchar(3),
#			desc_text            nvarchar(40,0),
#			addr1_text           nvarchar(40,0),
#			city_text            nvarchar(40,0),
#			country_code         nchar(3)
#		END RECORD
	DEFINE l_msgresp LIKE language.yes_flag		

	DEFINE l_idx SMALLINT
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING		

	IF p_filter THEN
   CLEAR FORM
   LET l_msgresp = kandoomsg("U",1001,"")
   #1001 " Enter Selection Criteria;  OK TO Continue"
   CONSTRUCT BY NAME l_where_text on locn_code,
                                   desc_text,
                                   addr1_text,
                                   city_text,
                                   country_code

   	BEFORE CONSTRUCT
   		CALL publish_toolbar("kandoo","U52","construct-location-list") 

		ON ACTION "WEB-HELP"
			CALL onlineHelp(getModuleId(),NULL)
			
			ON ACTION "actToolbarManager"
		 	CALL setupToolbar()
			
	END CONSTRUCT
	

   IF int_flag OR quit_flag THEN
      LET int_flag = FALSE
      LET quit_flag = FALSE
      LET l_where_text = " 1=1 "
   END IF
   
   ELSE
   	LET l_where_text = " 1=1 "
   END IF
   
   LET l_msgresp = kandoomsg("U",1002,"")
   #1002 " Searching database;  OK TO Continue.
   LET l_query_text = "SELECT cmpy_code, locn_code,  desc_text, addr1_text,city_text, country_code ",
                    "FROM location ",
                    "WHERE ", l_where_text clipped, " "

		IF p_cmpy_code IS NOT NULL THEN
			LET l_query_text =  l_query_text, " AND cmpy_code = '", p_cmpy_code CLIPPED, "' "	
		END IF                    
                    
			LET l_query_text =  l_query_text, "ORDER BY cmpy_code, locn_code, country_code, desc_text"

   PREPARE s_location FROM l_query_text
   DECLARE c_location CURSOR FOR s_location
   
	LET l_idx = 0
	FOREACH c_location INTO l_rec_location.*
		LET l_idx = l_idx + 1   
		LET l_arr_rec_location[l_idx].* = l_rec_location.*
	END FOREACH

   LET l_msgresp = kandoomsg("U",9113,l_arr_rec_location.getLength())
   #9113 l_idx records selected

	RETURN l_arr_rec_location
END FUNCTION	

##########################################################################
# FUNCTION location_scan()
#
#
##########################################################################
FUNCTION location_scan()
	DEFINE l_arr_rec_location DYNAMIC ARRAY OF t_rec_location_cc_lc_dt_ad
#	DEFINE l_arr_rec_location DYNAMIC ARRAY OF
#		RECORD
#			cmpy_code            char(2),
#			locn_code            nchar(3),
#			desc_text            nvarchar(40,0),
#			addr1_text           nvarchar(40,0),
#			city_text            nvarchar(40,0),
#			country_code         nchar(3)
#		END RECORD

	OPEN WINDOW w121 WITH FORM "W121"

	CALL db_location_list_dataSource(FALSE,glob_rec_kandoouser.cmpy_code) RETURNING l_arr_rec_location

	DISPLAY ARRAY l_arr_rec_location TO sr_location.*
	
	END DISPLAY

	CLOSE WINDOW w121

	
END FUNCTION	

