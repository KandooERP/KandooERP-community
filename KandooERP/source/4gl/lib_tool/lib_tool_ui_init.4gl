GLOBALS "../common/glob_GLOBALS.4gl" 
################################################################################
# FUNCTION ui_init(p_options)
#
#
#################################################################################
FUNCTION ui_init(p_options) 
	DEFINE p_options SMALLINT 

	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler #By Eric SuperDbMan

	CALL set_localize_any_string() # apply lacale catalogue translation to all displayed strings
	CASE p_options 
		WHEN 0 

		WHEN 1 #external utilities programs i.e. toolbar manager 

		WHEN 2 --mdi app with transformer MENU 
			CALL ui.interface.frontcall("html5","scriptImport",["{CONTEXT}/public/querix/js/kandoo-footnote.js",""],[]) 
			CALL ui.Interface.setType("container") 
			CALL ui.Application.GetCurrent().setMenuType("Tree") 
			CALL ui.Application.GetCurrent().SetClassNames(["md-sidebar","tabbed_container"]) 
			--CALL ui.Application.GetCurrent().SetClassNames(["md-sidebar"]) 

		WHEN 3 --mdi app with transformer MENU 
			CALL ui.Interface.setType("container") 
			CALL ui.Application.GetCurrent().setMenuType("Tree") 
			CALL ui.Application.GetCurrent().SetClassNames(["md-sidebar","tabbed_container"])
			--CALL ui.Application.GetCurrent().SetClassNames(["md-sidebar"])

	END CASE 
-- alch URL args should be precessed before use
-- Init numeric variables to NULL to make logical expressions work properly
	CALL init_url_variables_null() #????? what was this about ???
	CALL readauthenticationenvvariables() #huho read authentication env variables IF set/exist 
	#Note: if both, env AND url login details are specified, URL IS getting the upper hand / url arguments overwrite environment
	CALL processurlarguments() --must be FIRST / read url/environment AND SET corresponding variables 

	#Import Client Side JavaScript
	CALL loaddefaultjavascript(p_options) 

	#------------------------------------------------------------------------
	# FROM HERE / NOW, we can show error messages on the screen / UI
	#------------------------------------------------------------------------
--	#------ LOG
--	CALL set_settings_logPath(NULL) #1.Log file path BEFORE main log file init
--	CALL set_settings_logFile(NULL) #2. Kandoo uses log path and file.. may be there is a main log file and some other log files.. no idea yet
--	CALL set_settings_reportPath(NULL) #3. Main Report path/folder for all Kandoo reports  
--	#-------

	CALL set_default_options() #huho SET default OPTIONS LIKE accept KEY 
	#LET l_progName = get_baseProgName()  --l_full_progName[1,length(l_full_progName)-length(os.Path.extension(l_full_progName))-1]  --additional -1 FOR the dot between base name AND extension

	IF (not get_db_set()) OR (get_db()="kandoodb") THEN 
		--		CALL set_db("kandoodb")  --default
		CALL connect_db(get_db()) --db NAME other than kandoodb was specified in url/argument 
	ELSE 
		CALL connect_db(get_db()) --db NAME other than kandoodb was specified in url/argument 
	END IF 

	CALL db_session_info() --huho this FUNCTION stores the DATABASE session information in global variables FOR trouble shooting (provided BY eric) 

	CASE p_options 
		WHEN 0 
			--CALL publish_toolbar("kandoo","global","global") --global toolbar configuration (entire project) 
			--CALL publish_toolbar("kandoo",getModuleId(),"global") --module-global - toolbar configuration globally FOR this module/program 
			CALL ui.interface.settext(getmenuitemlabel(getmoduleid())) 
			CALL set_dbmoney() #huho SET dbmoney env variable currency symbol based ON glparms.base_currency_code 

		WHEN 1 #external utilities programs i.e. toolbar manager 
			--CALL publish_toolbar("kandoo","global","global") --global toolbar configuration (entire project) 
			--CALL publish_toolbar("kandoo",getModuleId(),"global") --module-global - toolbar configuration globally FOR this module/program 
			CALL ui.interface.settext(getmenuitemlabel(getmoduleid())) 

		WHEN 2 --mdi app with transformer MENU 
			--			CALL ui.interface.frontcall("html5","scriptImport",["{CONTEXT}/public/querix/js/kandoo-footnote.js",""],[])
			--			CALL ui.Interface.setType("container")
			--			CALL ui.Application.GetCurrent().setMenuType("Tree")
			--			CALL ui.Application.GetCurrent().SetClassNames(["tabbed_container"])

		WHEN 3 --mdi app with transformer MENU 
			--			#CALL ui.interface.frontcall("html5","scriptImport",["{CONTEXT}/public/querix/js/kandoo-footnote.js",""],[])
			--			CALL ui.Interface.setType("container")
			--			CALL ui.Application.GetCurrent().setMenuType("Tree")
			--			CALL ui.Application.GetCurrent().SetClassNames(["tabbed_container"])

	END CASE 

	--	#Import Client Side JavaScript
	--	CALL loadDefaultJavaScript(p_options)
	
END FUNCTION 
#################################################################################
# END FUNCTION ui_init(p_options)
#################################################################################


##############################################################################################################################
# FUNCTION init_general_company_settings() #will be replaced with DB queries
#
#
##############################################################################################################################
FUNCTION init_general_company_settings() #will be replaced with DB queries

	CALL set_settings_maxListArraySize(1000) 
	CALL set_settings_maxListArraySizeSwitch(500)

	CALL set_settings_saveUnbalancedBatch(TRUE) #HuHo: was a feature request from Anna
	CALL set_settings_maxRmsrepsHistorySize(NULL)	#NULL = #DEFAULT 99999000
	CALL set_settings_maxchildlaunch(20)  
	#------ LOG
	CALL set_settings_logPath(NULL) #1.Log file path BEFORE main log file init
	--CALL set_settings_logFile(NULL) #2. Kandoo uses log path and file.. may be there is a main log file and some other log files.. no idea yet
	CALL set_settings_logFile(glob_rec_prog.prog_id) #2. Kandoo uses log path and file.. may be there is a main log file and some other log files.. no idea yet
	CALL set_settings_reportPath(NULL) #3. Main Report path/folder for all Kandoo reports  
	#-------

END FUNCTION
##############################################################################################################################
# END FUNCTION init_general_company_settings() #will be replaced with DB queries
##############################################################################################################################


##############################################################################################################################
# FUNCTION init_general_division_settings() #will be replaced with DB queries
#
#
##############################################################################################################################
FUNCTION init_general_division_settings() #will be replaced with DB queries

	CALL set_default_country_code(get_ku_country_code())
	CALL set_default_currency_code(db_company_get_currency_code(FALSE,get_ku_cmpy_code()))

	#------ LOG
	CALL set_settings_logPath(NULL) #1.Log file path BEFORE main log file init
	# Flagging log file because it contradicts what has been set on global level
	--CALL set_settings_logFile(NULL) #2. Kandoo uses log path and file.. may be there is a main log file and some other log files.. no idea yet
	CALL set_settings_reportPath(NULL) #3. Main Report path/folder for all Kandoo reports  
	#-------

END FUNCTION
##############################################################################################################################
# END FUNCTION init_general_division_settings() #will be replaced with DB queries
##############################################################################################################################


##############################################################################################################################
# FUNCTION init_general_user_settings() #will be replaced with DB queries
#
#
##############################################################################################################################
FUNCTION init_general_user_settings() #will be replaced with DB queries
	CALL set_default_hideDeletedCustomers(TRUE)
END FUNCTION
##############################################################################################################################
# END FUNCTION init_general_user_settings() #will be replaced with DB queries
##############################################################################################################################


##################################################################
# FUNCTION set_default_options()
#
# NOTE: To get a common operational feel for the user, we will work
# with the SAME OPTIONS/KEYS/BEHAVIOUR for ALL Kandoo modules
##################################################################
FUNCTION set_default_options() 
	OPTIONS INPUT WRAP 
	OPTIONS FIELD ORDER UNCONSTRAINED #we want TO give the user more freedom WHEN navigating between fields -> needs some INPUT after/before blocks adjusting #correct version -- FIELD ORDER unconstrained IS ne 
	OPTIONS ACCEPT KEY CONTROL-RETURN 
	OPTIONS INTERRUPT KEY BREAK 
	OPTIONS QUIT KEY BREAK 
	OPTIONS CANCEL KEY ESCAPE 
	OPTIONS DELETE KEY DELETE 
	OPTIONS APPEND KEY INSERT 
	DEFER INTERRUPT 

	#	OPTIONS INSERT KEY xxx

	# OPTIONS NEXT KEY
	# OPTIONS PREVIOUS KEY
END FUNCTION 
##################################################################
# END FUNCTION set_default_options()
##################################################################


##################################################################
# FUNCTION set_dbmoney()
#
# set DBMONEY env variable currency symbol based on glparms.base_currency_code
##################################################################
FUNCTION set_dbmoney() 
	--	DEFINE l_currencySymbol STRING
	--
	-- #HuHo I need Eric to show me conversationtable of international currency codes to Informix style
	--
	--	LET l_currencySymbol = db_currency_get_symbol_text(db_glparms_get_base_currency_code("1"))
	--	IF  l_currencySymbol IS NOT NULL THEN
	--		LET l_currencySymbol = l_currencySymbol, ","
	--		CALL fgl_setenv("DBMONEY",l_currencySymbol)
	--	END IF
	--	#DISPLAY "Currency Symbol:", trim( db_currency_get_symbol_text(db_glparms_get_base_currency_code("1")))
END FUNCTION 
##################################################################
# END FUNCTION set_default_options()
##################################################################