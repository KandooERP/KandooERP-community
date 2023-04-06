GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION windecoration_s(pwinname) 
	DEFINE pwinname STRING 
	DEFINE errmsg STRING 

	# DEFINE cb_field_name      VARCHAR(25)   --form field
	#	DEFINE pVariable SMALLINT	-- 0=first field IS variable 1= 2nd field IS variable
	#	DEFINE pSort SMALLINT  --0=Sort on first 1=Sort on 2nd
	#	DEFINE pSingle SMALLINT	--0=variable AND label 1= variable = label
	#	DEFINE pHint SMALLINT  --1 = show both VALUES in label


	CASE pwinname 
	# Prog: U11
	# User Parameters

		WHEN "setup_location" 
			DISPLAY getlangstr("lb_language") TO lb_language 
			DISPLAY getlangstr("lb_country") TO lb_country 
			DISPLAY getlangstr("lb_currency") TO lb_language 
			DISPLAY getlangstr("lb_bankFormat") TO lb_bankformat 


		WHEN "setup_gl_config" 
			DISPLAY getlangstr("lb_orgStructure") TO lb_orgstructure 
			DISPLAY getlangstr("lb_industryType") TO lb_industrytype 
			DISPLAY getlangstr("lb_startDate") TO lb_startdate 


			DISPLAY getlangstr("lb_startYear") TO lb_startyear 
			DISPLAY getlangstr("lb_startPeriod") TO lb_startperiod 
			DISPLAY getlangstr("lb_endYear") TO lb_endyear 
			DISPLAY getlangstr("lb_endPeriod") TO lb_endperiod 

		WHEN "setup_company" 
			DISPLAY getlangstr("lb_companyCode") TO lb_companycode 
			DISPLAY getlangstr("lb_company") TO lb_company 
			DISPLAY getlangstr("lb_country") TO lb_country 
			DISPLAY getlangstr("lb_bankFormat") TO lb_bankformat 
			DISPLAY getlangstr("lb_language") TO lb_language 
			DISPLAY getlangstr("lb_currency") TO lb_currency 
			DISPLAY getlangstr("lb_vat") TO lb_vat 
			DISPLAY getlangstr("lb_telex") TO lb_telex 
			DISPLAY getlangstr("lb_crn") TO lb_crn 
			DISPLAY getlangstr("lb_crn_div") TO lb_crn_div 
			DISPLAY getlangstr("lb_address") TO lb_address 
			DISPLAY getlangstr("lb_city") TO lb_city 
			DISPLAY getlangstr("lb_stateCode") TO lb_statecode 
			DISPLAY getlangstr("lb_postCode") TO lb_postcode 
			DISPLAY getlangstr("lb_tel") TO lb_tel 
			DISPLAY getlangstr("lb_fax") TO lb_fax 

		WHEN "setup_admin" 
			DISPLAY getlangstr("lb_user") TO lb_user 
			DISPLAY getlangstr("lb_userName") TO lb_username 
			DISPLAY getlangstr("lb_password") TO lb_password 
			DISPLAY getlangstr("lb_email") TO lb_email 

		WHEN "setup_lookup_data" 

		WHEN "setup_module" 

		OTHERWISE 
			LET errmsg = "Invalid Window name passed TO winDecoration_S(", trim(pwinname), ")" 
			CALL fgl_winmessage("Internal 4GL Error",errMsg, "error") 
	END CASE 

END FUNCTION 
