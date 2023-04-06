GLOBALS "../common/glob_GLOBALS.4gl" 

#HuHo
# V1 24.03.2005 (Hydra 4.2 CMS-Demo)
# V2 06.02.2011 Adopted for Lycia 1
# V3 30.08.2016 Adopted for Lycia 2
# V4 17.10.2018 Adopted for Lycia 3


############################
# Report Files
DEFINE env_report STRING 
DEFINE reginfo text 
DEFINE systeminfo text 
DEFINE reportfilename VARCHAR(200) 
DEFINE reportfile text 
DEFINE includeauthenticationinfo boolean --by default off - in CASE it IS sent TO i.e. querix but the user can turn it ON IF it IS used FOR their internal usage 
DEFINE informixpassparthiddenstring STRING -- i.e. treehouse -> t*******e 
DEFINE r_db_type STRING 
DEFINE tmpstr STRING 
DEFINE rec_customer 
RECORD 
	customername VARCHAR(100), 
	customeremailaddress VARCHAR(100), 
	customercompany VARCHAR(100), 
	customerbrowser VARCHAR(100), 
	customerrunfromlocation SMALLINT, --tool was RUN lyciastudio, independent, remote 
	customercss SMALLINT, 
	customerqxtheme SMALLINT, 
	customerjavascript boolean, 
	customervdom SMALLINT, 
	customercsources boolean, 
	customerjavasources boolean, 
	customerincludeenvironmentvariables boolean, 
	customerincludesystemreport boolean, 
	customerincluderegistryinformation boolean, 
	customermessage VARCHAR(2000) 

END RECORD 

DEFINE modu_rec_dbstatus RECORD 
	dbname VARCHAR(50), 
	db_status VARCHAR(50), 
	sqlca_sqlcode VARCHAR(50), 
	driver_error VARCHAR(500), 
	native_code VARCHAR(500), 
	native_error VARCHAR(500), 
	error_text VARCHAR(2000), 
	db_type VARCHAR(5), 
	db_type_name VARCHAR(100), 
	dbpath string, ##varchar(500), 
	lycia_db_driver VARCHAR(100), 
	logname VARCHAR(100), 
	informixpass VARCHAR(100), 
	db_locale VARCHAR(100), 
	informixserver VARCHAR(100), 
	informixdir VARCHAR(100), 
	oracle_sid VARCHAR(100), 
	oracle_home VARCHAR(100), 
	odbc_dsn VARCHAR(100), 
	sqlserver VARCHAR(100), 
	db2dir VARCHAR(100), 
	db2instance VARCHAR(100) 

END RECORD 



DEFINE rec_main 
RECORD 
	lycia_version string, 
	frontendname string, 
	frontendversion string, 
	gui_misc_version string, 
	server_os_name STRING 
END RECORD 

DEFINE modu_rec_general RECORD 
	lycia_version string, 
	frontendname string, 
	frontendversion string, 
	gui_misc_version string, 
	server_os string, 
	server_os_name string, 
	uitype string, 
	child_process string, 
	dbpath string, 
	env_dbdate string, 
	dbtime string, 
	dbmoney string, 
	db_locale string, 
	client_locale string, 
	lycia_config_path STRING 
END RECORD 


DEFINE rec_server RECORD 
	qx_server_host string, 
	qx_server_ip string, 
	qx_session_id string, 
	qx_command_id string, 
	qx_process_id string, 
	qx_child string, 
	server_hostname string, 
	server_ipaddress STRING 
END RECORD 


DEFINE rec_client RECORD 
	frontendname string, 
	qx_client_host string, 
	qx_client_ip string, 
	gui_systemnetwork_hostname string, 
	gui_systemnetwork_ippaddress string, 
	gui_systemnetwork_sessionid string, 
	gui_systemnetwork_commandid string, 
	gui_systemnetwork_processid string, 
	ld_library_path STRING --linux/unix ld lib path 
END RECORD 


DEFINE rec_lycia --lycia environment variables 
RECORD 
	lycia_version string, 
	lycia_dir string, 
	lycia_driver_path string, 
	lycia_db_driver string, 
	lycia_config string, 
	lycia_conv_form_max_height string, 
	lycia_conv_form_max_width string, 
	lycia_db_namemap string, 
	lycia_lic_key string, 
	lycia_msgpath string, 
	lycia_path string, 
	lycia_per_convert_checkbox string, 
	lycia_post_mortem_length string, 
	lycia_severity string, 
	lycia_config_path string, 
	lycia_system_action_defaults string, 
	lycia_system_resources string, 
	lycia_system_theme_css string, 
	lycia_system_theme_qx STRING 
END RECORD 


DEFINE modu_rec_env RECORD--div. environment variables 
	lycia_dir string, 
	msgpath string, 
	screen_lines string, 
	screen_columns string, 
	lycia_driver_path string, 
	fglprofile string, 
	qxdebug string, 
	qxbreakch_start string, 
	qxbreakch_end string, 
	path string, 
	fglimagepath string, 
	qx_menu_window string, 
	classpath string, 
	env_temp string, 
	tmp string, 
	qxss_db_is_dsn string, 

	allusersprofile string, 
	axis2c_home string, 
	fglldpath string, 
	fglswaggerpath STRING 
END RECORD 


DEFINE rec_envqx --div. environment variables 
RECORD 
	qxclientaddress string, 
	qxguiifd string, 
	qxguiofd string, 
	qxguisocketfd string, 
	qxhost string, 
	qxindextablespace string, 
	qxora_noouter_nullop string, 
	qxport string, 
	qxrep_spaces string, 
	qxsslcertname string, 
	qxsslpass string, 
	qxsslprivatekeyname string, 
	qxssl_timeout string, 
	qxstdtablespace string, 
	qxtmptablespace STRING 
END RECORD 



DEFINE rec_envqx_ --div. environment variables 
RECORD 
	qx_aot string, 
	qx_child string, 
	qx_cid string, 
	qx_clear_dynamic_label string, 
	qx_clear_static_label string, 
	qx_client_host string, 
	qx_client_ip string, 
	qx_compat string, 
	qx_debug_hosts string, 
	qx_dump_passes string, 
	qx_headless_console string, 
	qx_headless_mode string, 
	qx_lognativesqlerrors string, 
	qx_log_dir string, 
	qx_mdi string, 
	qx_menu_window string, 
	qx_menu_window_new_child string, 
	qx_native_linker string, 
	qx_no_clean_linker_files string, 
	qx_opt_level string, 
	qx_process_id string, 
	qx_qrun_dump string, 
	qx_qrun_port string, 
	qx_resource_unlock string, 
	qx_rest_value_xml string, 
	qx_run_arg_pref string, 
	qx_session_id string, 
	qx_show_window string, 
	qx_size_dimension string, 

	qx_sqlscope_on string, 
	qx_starter_debug_logging string, 
	qx_starter_redirect_std_out string, 
	qx_ui_mode_override string, 
	qx_use_simple_cache_path string, 
	qx_verbose_cache string, 
	qx_verify_after STRING 

END RECORD 

DEFINE rec_c_compiler 
RECORD 
	c_interface_locale string, 
	fglc_tracegen string, 
	fglc_traceproc string, 
	fglc_traceprocerrs string, 
	fglc_yydebug string, 
	vc_devenvdir string, --visual c 
	vc_include string, --visual c 
	vc_lib string, --visual c 
	vc_libpath string, --visual c 
	vc_vcinstalldir string, --visual c 
	vc_visualstudioversion STRING --visual c 

END RECORD 

DEFINE rec_os --operating system 
RECORD 
	username string, 
	system_username string, 
	server_os string, 
	server_os_name string, 
	java_home STRING 
END RECORD 

DEFINE rec_db --db general 
RECORD 
	lycia_db_driver string, 
	dbpath STRING 
END RECORD 


DEFINE rec_informix 
RECORD 
	logname string, 
	informixpass string, 
	dbpath string, 
	db_locale string, 
	informixserver string, 
	informixdir string, 
	informixsqlhosts string, 
	client_locale string, 
	qxss_db_is_dsn string, 
	delimident string, 
	dbdelimiter string, 
	dbformat string, 
	db_name string, 
	db_name_full string, 
	db_major_version string, 
	db_infversionos string, 
	db_os string, 
	dbhostname string, 
	dbname string, 
	sessionid string, 
	dbcentury string, 
	onconfig STRING 
END RECORD 

DEFINE rec_oracle 
RECORD 
--Oracle DB
	oracle_sid string, 
	oracle_home STRING 
END RECORD 




DEFINE rec_sqlserver 
RECORD 
--SQL-SERVER Microsoft
	odbc_dsn string, 
	sqlserver STRING 
END RECORD 

DEFINE rec_db2 
RECORD 
--SQL-SERVER Microsoft
	db2dir string, 
	db2instance STRING 
END RECORD 



DEFINE rec_birt 
RECORD 
	birt_libdir STRING 
END RECORD 

###########################################################################################################
# FUNCTION retrievelyciasystemenvironment(p_windowtype)
#
#
###########################################################################################################
FUNCTION retrievelyciasystemenvironment(p_windowtype) 
	DEFINE p_windowtype CHAR 
	DEFINE inp_char CHAR 
	DEFINE temp_string VARCHAR(1000) 
	DEFINE db_name CHAR(64) 

	LET includeauthenticationinfo = false --no db password etc.. IS included in the REPORT 
	LET reportfilename = "LyciaSystemReport.txt" 

	LET informixpassparthiddenstring = hideStringPartial(fgl_getenv("INFORMIXPASS")) 

	IF p_windowtype = "w" OR p_windowtype = "W" THEN 
		CALL fgl_window_open("w_about",5,5,"form/kandoo_environment",TRUE) --window screen 
	ELSE 
		CALL fgl_window_open("w_about",5,5,"form/kandoo_environment",FALSE) --full screen 
	END IF 
	CALL ui.Interface.setText("Sys Info") 
	CALL ui.interface.refresh() 
	##########################
	# Need DB connection for DB information

	#IF fgl_getenv("qx_child") THEN
	LET db_name = trim(get_db()) --get the dbname FROM the url/environment 
	#END IF

--	LET db_name = get_db() #fgl_winprompt(1,1,"Enter your Database Name",trim(db_name),30,0) 


	############################################################################################
	# Get the different system details, store them (OR later REPORT geneartion) AND display
	############################################################################################


	#Main Area (top panel) -------------------------------------------------------


	LET rec_main.lycia_version = fgl_getversion() 
	DISPLAY rec_main.lycia_version TO main_lycia_version 

	LET rec_main.frontendname = ui.interface.getfrontendname() 
	DISPLAY rec_main.frontendname TO main_frontendname 

	LET rec_main.frontendversion = ui.interface.getfrontendversion() 
	DISPLAY rec_main.frontendversion TO main_frontendversion 

	LET rec_main.gui_misc_version = fgl_getproperty("gui", "gui.misc.version", "") 
	DISPLAY rec_main.gui_misc_version TO main_gui_misc_version 

	LET rec_main.server_os_name = get_server_os_name(modu_rec_general.server_os) 
	DISPLAY rec_main.server_os_name TO main_server_os_name 


	#KandooUser -------------------------------------------

	DISPLAY glob_rec_kandoouser.login_name TO ku_user_code 
	DISPLAY glob_rec_kandoouser.sign_on_code TO ku_sign_on_code 
	DISPLAY glob_rec_kandoouser.name_text TO ku_name_text 
	DISPLAY glob_rec_kandoouser.security_ind TO ku_security_ind 
	DISPLAY glob_rec_kandoouser.password_text TO ku_password_text 
	DISPLAY glob_rec_kandoouser.language_code TO ku_language_code 
	DISPLAY glob_rec_kandoouser.cmpy_code TO ku_cmpy_code 
	DISPLAY glob_rec_kandoouser.acct_mask_code TO ku_acct_mask_code 
	DISPLAY glob_rec_kandoouser.profile_code TO ku_profile_code 
	DISPLAY glob_rec_kandoouser.access_ind TO ku_access_ind 
	DISPLAY glob_rec_kandoouser.sign_on_date TO ku_sign_on_date 
	DISPLAY glob_rec_kandoouser.print_text TO ku_print_text 
	DISPLAY glob_rec_kandoouser.act_spawn_num TO ku_act_spawn_num 
	DISPLAY glob_rec_kandoouser.max_spawn_num TO ku_max_spawn_num 
	DISPLAY glob_rec_kandoouser.group_code TO ku_group_code 
	DISPLAY glob_rec_kandoouser.signature_text TO ku_signature_text 
	DISPLAY glob_rec_kandoouser.passwd_ind TO ku_passwd_ind 
	DISPLAY glob_rec_kandoouser.memo_pri_ind TO ku_memo_pri_ind 
	DISPLAY glob_rec_kandoouser.email TO ku_email 

	#Language -------------------------------------------


	DISPLAY glob_rec_kandoouser.language_code TO lang_language_code 
	DISPLAY db_language_get_language_text(glob_rec_kandoouser.language_code) TO lang_language_text 
	DISPLAY db_language_get_yes_flag(glob_rec_kandoouser.language_code) TO lang_yes_flag 
	DISPLAY db_language_get_no_flag(glob_rec_kandoouser.language_code) TO lang_no_flag 
	DISPLAY db_language_get_national_text(glob_rec_kandoouser.language_code) TO lang_national_text 
	DISPLAY db_glparms_get_base_currency_code("1") TO locale_dbmoney 
	DISPLAY db_currency_get_symbol_text(db_glparms_get_base_currency_code("1")) TO locale_currency_symbol_text 
	#Misc Globals  -------------------------------------------
	#DISPLAY glob_callingprog TO glob_callingprog
	#DISPLAY glob_callingprog_ext TO glob_callingprog_ext
	#DISPLAY glob_msg1_text TO glob_msg1_text
	#DISPLAY glob_msg2_text TO glob_msg2_text

	#DISPLAY glob_admin_code TO 	glob_admin_code
	#DISPLAY GL_LANG TO GL_LANG
	#DISPLAY GL_LOGIN_USER_ID TO GL_LOGIN_USER_ID
	#DISPLAY GL_LOGIN_NAME TO GL_LOGIN_NAME
	#DISPLAY GL_LOGIN_PASSWORD TO GL_LOGIN_PASSWORD



	#General -------------------------------------------
	LET modu_rec_general.lycia_version = fgl_getversion() 
	DISPLAY modu_rec_general.lycia_version TO gen_lycia_version 

	LET modu_rec_general.frontendname = ui.interface.getfrontendname() 
	DISPLAY rec_main.frontendname TO gen_frontendname 

	LET modu_rec_general.frontendversion = ui.interface.getfrontendversion() 
	DISPLAY modu_rec_general.frontendversion TO gen_frontendversion 

	LET modu_rec_general.gui_misc_version = fgl_getproperty("gui", "gui.misc.version", "") 
	DISPLAY modu_rec_general.gui_misc_version TO gen_gui_misc_version 

	LET modu_rec_general.server_os = fgl_arch() 
	DISPLAY modu_rec_general.server_os TO gen_server_os 

	LET modu_rec_general.server_os_name = get_server_os_name(modu_rec_general.server_os) 
	DISPLAY modu_rec_general.server_os_name TO gen_server_os_name 

	LET modu_rec_general.uitype = fgl_getuitype() 
	DISPLAY modu_rec_general.uitype TO gen_uitype 

	LET modu_rec_general.child_process = fgl_getenv("qx_child") 
	DISPLAY modu_rec_general.child_process TO gen_child_process 

	LET modu_rec_general.dbpath = fgl_getenv("DBPATH") 
	DISPLAY modu_rec_general.dbpath TO gen_dbpath 

	LET modu_rec_general.dbmoney = fgl_getenv("DBMONEY") 
	DISPLAY modu_rec_general.dbmoney TO gen_dbmoney 

	LET modu_rec_general.db_locale= fgl_getenv("DB_LOCALE") 
	DISPLAY modu_rec_general.db_locale TO gen_db_locale 

	LET modu_rec_general.env_dbdate = fgl_getenv("DBDATE") 
	DISPLAY modu_rec_general.env_dbdate TO gen_dbdate 

	LET modu_rec_general.dbtime = fgl_getenv("DBTIME") 
	DISPLAY modu_rec_general.dbtime TO gen_dbtime 

	LET modu_rec_general.client_locale = fgl_getenv("CLIENT_LOCALE") 
	DISPLAY modu_rec_general.client_locale TO gen_client_locale 

	LET modu_rec_general.lycia_config_path = fgl_getenv("LYCIA_CONFIG_PATH") 
	DISPLAY modu_rec_general.lycia_config_path TO gen_lycia_config_path 



	#Server--------------------------------------------------------------
	LET rec_server.qx_server_host = fgl_getenv("QX_SERVER_HOST") 
	DISPLAY rec_server.qx_server_host TO server_qx_server_host 

	LET rec_server.qx_server_ip = fgl_getenv("QX_SERVER_IP") 
	DISPLAY rec_server.qx_server_ip TO server_qx_server_ip 

	LET rec_server.qx_session_id = fgl_getenv("QX_SESSION_ID") 
	DISPLAY rec_server.qx_session_id TO server_qx_session_id 

	LET rec_server.qx_command_id = fgl_getenv("QX_COMMAND_ID") 
	DISPLAY rec_server.qx_command_id TO server_qx_command_id 

	LET rec_server.qx_process_id = fgl_getenv("QX_PROCESS_ID") 
	DISPLAY rec_server.qx_process_id TO server_qx_process_id 

	LET rec_server.qx_child = fgl_getenv("QX_CHILD") 
	DISPLAY rec_server.qx_child TO server_qx_child 

	LET rec_server.server_hostname = fgl_getproperty("server", "system.network", "hostname") 
	DISPLAY rec_server.server_hostname TO server_systemnetworkhostname 

	LET rec_server.server_ipaddress = fgl_getproperty("server", "system.network", "ipaddress") 
	DISPLAY rec_server.server_ipaddress TO server_systemnetworkipaddress 

	#Client --------------------------------------------------------------------

	LET rec_client.frontendname = ui.interface.getfrontendname() 
	DISPLAY rec_client.frontendname TO client_frontendname 

	LET rec_client.qx_client_host = fgl_getenv("QX_CLIENT_HOST") 
	DISPLAY rec_client.qx_client_host TO client_qx_client_host 

	LET rec_client.qx_client_ip = fgl_getenv("QX_CLIENT_IP") 
	DISPLAY rec_client.qx_client_ip TO client_qx_client_ip 

	LET rec_client.gui_systemnetwork_hostname = fgl_getproperty("gui", "system.network", "hostname") 
	DISPLAY rec_client.gui_systemnetwork_hostname TO client_gui_systemnetwork_hostname 

	LET rec_client.gui_systemnetwork_ippaddress = fgl_getproperty("gui", "system.network", "ipaddress") 
	DISPLAY rec_client.gui_systemnetwork_ippaddress TO client_gui_systemnetwork_ippaddress 

	LET rec_client.gui_systemnetwork_sessionid = fgl_getproperty("gui", "system.network", "sessionid") 
	DISPLAY rec_client.gui_systemnetwork_sessionid TO client_gui_systemnetwork_sessionid 

	LET rec_client.gui_systemnetwork_commandid = fgl_getproperty("gui", "system.network", "commandid") 
	DISPLAY rec_client.gui_systemnetwork_commandid TO client_gui_systemnetwork_commandid 

	LET rec_client.gui_systemnetwork_processid = fgl_getproperty("gui", "system.network", "processid") 
	DISPLAY rec_client.gui_systemnetwork_processid TO client_gui_systemnetwork_processid 

	LET rec_client.ld_library_path = fgl_getenv("LD_LIBRARY_PATH") --unix only 
	DISPLAY rec_client.ld_library_path TO client_ld_library_path 



#Lycia
	LET rec_lycia.lycia_version = fgl_getversion() 
	DISPLAY rec_lycia.lycia_version TO lyc_lycia_version 


	LET rec_lycia.lycia_dir = fgl_getenv("LYCIA_DIR") 
	DISPLAY rec_lycia.lycia_dir TO lyc_lycia_dir 


	LET rec_lycia.lycia_driver_path = fgl_getenv("LYCIA_DRIVER_PATH") 
	DISPLAY rec_lycia.lycia_driver_path TO lyc_lycia_driver_path 

	LET rec_lycia.lycia_db_driver = fgl_getenv("LYCIA_DB_DRIVER") 
	DISPLAY rec_lycia.lycia_db_driver TO lyc_lycia_db_driver 

	LET rec_lycia.lycia_config = fgl_getenv("LYCIA_CONFIG") 
	DISPLAY rec_lycia.lycia_config TO lyc_lycia_config 

	LET rec_lycia.lycia_conv_form_max_height = fgl_getenv("LYCIA_CONV_FORM_MAX_HEIGHT") 
	DISPLAY rec_lycia.lycia_conv_form_max_height TO lyc_lycia_conv_form_max_height 

	LET rec_lycia.lycia_conv_form_max_width = fgl_getenv("LYCIA_CONV_FORM_MAX_WIDTH") 
	DISPLAY rec_lycia.lycia_conv_form_max_width TO lyc_lycia_conv_form_max_width 

	LET rec_lycia.lycia_db_namemap = fgl_getenv("LYCIA_DB_NAMEMAP") 
	DISPLAY rec_lycia.lycia_db_namemap TO lyc_lycia_db_namemap 

	LET rec_lycia.lycia_lic_key = fgl_getenv("LYCIA_LIC_KEY") 
	DISPLAY rec_lycia.lycia_lic_key TO lyc_lycia_lic_key 

	LET rec_lycia.lycia_msgpath = fgl_getenv("LYCIA_MSGPATH") 
	DISPLAY rec_lycia.lycia_msgpath TO lyc_lycia_msgpath 

	LET rec_lycia.lycia_path = fgl_getenv("LYCIA_PATH") 
	DISPLAY rec_lycia.lycia_path TO lyc_lycia_path 

	LET rec_lycia.lycia_per_convert_checkbox = fgl_getenv("LYCIA_PER_CONVERT_CHECKBOX") 
	DISPLAY rec_lycia.lycia_per_convert_checkbox TO lyc_lycia_per_convert_checkbox 

	LET rec_lycia.lycia_post_mortem_length = fgl_getenv("LYCIA_POST_MORTEM_LENGTH") 
	DISPLAY rec_lycia.lycia_post_mortem_length TO lyc_lycia_post_mortem_length 

	LET rec_lycia.lycia_severity = fgl_getenv("LYCIA_SEVERITY") 
	DISPLAY rec_lycia.lycia_severity TO lyc_lycia_severity 

	LET rec_lycia.lycia_config_path = fgl_getenv("LYCIA_CONFIG_PATH") 
	DISPLAY rec_lycia.lycia_config_path TO lyc_lycia_config_path 



	LET rec_lycia.lycia_system_action_defaults = fgl_getenv("LYCIA_SYSTEM_ACTION_DEFAULTS") 
	DISPLAY rec_lycia.lycia_system_action_defaults TO lyc_lycia_system_action_defaults 

	LET rec_lycia.lycia_system_resources = fgl_getenv("LYCIA_SYSTEM_RESOURCES") 
	DISPLAY rec_lycia.lycia_system_resources TO lyc_lycia_system_resources 

	LET rec_lycia.lycia_system_theme_css = fgl_getenv("LYCIA_SYSTEM_THEME_CSS") 
	DISPLAY rec_lycia.lycia_system_theme_css TO lyc_lycia_system_theme_css 

	LET rec_lycia.lycia_system_theme_qx = fgl_getenv("LYCIA_SYSTEM_THEME_QX") 
	DISPLAY rec_lycia.lycia_system_theme_qx TO lyc_lycia_system_theme_qx 


	#Environment variables ---------------------------------------------------------------
	LET modu_rec_env.lycia_dir = fgl_getenv("LYCIA_DIR") 
	DISPLAY modu_rec_env.lycia_dir TO env_lycia_dir 

	LET modu_rec_env.msgpath = fgl_getenv("MSGPATH") 
	DISPLAY modu_rec_env.msgpath TO env_msgpath 

	LET modu_rec_env.screen_lines = fgl_getenv("LINES") 
	DISPLAY modu_rec_env.screen_lines TO env_lines 

	LET modu_rec_env.screen_columns = fgl_getenv("COLUMNS") 
	DISPLAY modu_rec_env.screen_columns TO env_columns 

	LET modu_rec_env.lycia_driver_path = fgl_getenv("LYCIA_DRIVER_PATH") 
	DISPLAY modu_rec_env.lycia_driver_path TO env_lycia_driver_path 

	LET modu_rec_env.fglprofile = fgl_getenv("FGLPROFILE") 
	DISPLAY modu_rec_env.fglprofile TO env_fglprofile 

	LET modu_rec_env.qxdebug = fgl_getenv("QXDEBUG") 
	DISPLAY modu_rec_env.qxdebug TO env_qxdebug 

	LET modu_rec_env.qxbreakch_start = fgl_getenv("QXBREAKCH_START") 
	DISPLAY modu_rec_env.qxbreakch_start TO env_qxbreakch_start 

	LET modu_rec_env.qxbreakch_end = fgl_getenv("QXBREAKCH_END") 
	DISPLAY modu_rec_env.qxbreakch_end TO env_qxbreakch_end 

	LET modu_rec_env.path = fgl_getenv("PATH") 
	DISPLAY modu_rec_env.path TO env_path 

	LET modu_rec_env.fglimagepath = fgl_getenv("FGLIMAGEPATH") 
	DISPLAY modu_rec_env.fglimagepath TO env_fglimagepath 

	LET modu_rec_env.qx_menu_window = fgl_getenv("QX_MENU_WINDOW") 
	DISPLAY modu_rec_env.qx_menu_window TO env_qx_menu_window 

	LET modu_rec_env.classpath = fgl_getenv("CLASSPATH") 
	DISPLAY modu_rec_env.classpath TO env_classpath 

	LET modu_rec_env.env_temp = fgl_getenv("TEMP") 
	DISPLAY modu_rec_env.env_temp TO env_temp 

	LET modu_rec_env.tmp = fgl_getenv("TMP") 
	DISPLAY modu_rec_env.tmp TO env_tmp 

	LET modu_rec_env.qxss_db_is_dsn = fgl_getenv("QXSS_DB_IS_DSN") 
	DISPLAY modu_rec_env.qxss_db_is_dsn TO env_qxss_db_is_dsn 


	LET modu_rec_env.allusersprofile = fgl_getenv("ALLUSERSPROFILE") 
	DISPLAY modu_rec_env.allusersprofile TO env_allusersprofile 

	LET modu_rec_env.axis2c_home = fgl_getenv("AXIS2C_HOME") 
	DISPLAY modu_rec_env.axis2c_home TO env_axis2c_home 

	LET modu_rec_env.fglldpath = fgl_getenv("FGLLDPATH") 
	DISPLAY modu_rec_env.fglldpath TO env_fglldpath 

	LET modu_rec_env.fglswaggerpath = fgl_getenv("FGLSWAGGERPATH") 
	DISPLAY modu_rec_env.fglswaggerpath TO env_fglswaggerpath 


	# QX<name> Environment Variables ----------------------------------------------------------------------

	LET rec_envqx.qxclientaddress = fgl_getenv("QXCLIENTADDRESS") 
	DISPLAY rec_envqx.qxclientaddress TO envqxqxclientaddress 
	LET rec_envqx.qxguiifd = fgl_getenv("QXGUIIFD") 
	DISPLAY rec_envqx.qxguiifd TO envqxqxguiifd 
	LET rec_envqx.qxguiofd = fgl_getenv("QXGUIOFD") 
	DISPLAY rec_envqx.qxguiofd TO envqxqxguiofd 
	LET rec_envqx.qxguisocketfd = fgl_getenv("QXGUISOCKETFD") 
	DISPLAY rec_envqx.qxguisocketfd TO envqxqxguisocketfd 
	LET rec_envqx.qxhost = fgl_getenv("QXHOST") 
	DISPLAY rec_envqx.qxhost TO envqxqxhost 
	LET rec_envqx.qxindextablespace = fgl_getenv("QXINDEXTABLESPACE") 
	DISPLAY rec_envqx.qxindextablespace TO envqxqxindextablespace 
	LET rec_envqx.qxora_noouter_nullop = fgl_getenv("QXORA_NOOUTER_NULLOP") 
	DISPLAY rec_envqx.qxora_noouter_nullop TO envqxqxora_noouter_nullop 
	LET rec_envqx.qxport = fgl_getenv("QXPORT") 
	DISPLAY rec_envqx.qxport TO envqxqxport 
	LET rec_envqx.qxrep_spaces = fgl_getenv("QXREP_SPACES") 
	DISPLAY rec_envqx.qxrep_spaces TO envqxqxrep_spaces 
	LET rec_envqx.qxsslcertname = fgl_getenv("QXSSLCERTNAME") 
	DISPLAY rec_envqx.qxsslcertname TO envqxqxsslcertname 
	LET rec_envqx.qxsslpass = fgl_getenv("QXSSLPASS") 
	DISPLAY rec_envqx.qxsslpass TO envqxqxsslpass 
	LET rec_envqx.qxsslprivatekeyname = fgl_getenv("QXSSLPRIVATEKEYNAME") 
	DISPLAY rec_envqx.qxsslprivatekeyname TO envqxqxsslprivatekeyname 
	LET rec_envqx.qxssl_timeout = fgl_getenv("QXSSL_TIMEOUT") 
	DISPLAY rec_envqx.qxssl_timeout TO envqxqxssl_timeout 
	LET rec_envqx.qxstdtablespace = fgl_getenv("QXSTDTABLESPACE") 
	DISPLAY rec_envqx.qxstdtablespace TO envqxqxstdtablespace 
	LET rec_envqx.qxtmptablespace = fgl_getenv("QXTMPTABLESPACE") 
	DISPLAY rec_envqx.qxtmptablespace TO envqxqxtmptablespace 


	# QX_<name> Environment Variables ----------------------------------------------------------------------

	LET rec_envqx_.qx_aot = fgl_getenv("QX_AOT") 
	DISPLAY rec_envqx_.qx_aot TO envqx_qx_aot 
	LET rec_envqx_.qx_child = fgl_getenv("QX_CHILD") 
	DISPLAY rec_envqx_.qx_child TO envqx_qx_child 
	LET rec_envqx_.qx_cid = fgl_getenv("QX_CID") 
	DISPLAY rec_envqx_.qx_cid TO envqx_qx_cid 
	LET rec_envqx_.qx_clear_dynamic_label = fgl_getenv("QX_CLEAR_DYNAMIC_LABEL") 
	DISPLAY rec_envqx_.qx_clear_dynamic_label TO envqx_qx_clear_dynamic_label 
	LET rec_envqx_.qx_clear_static_label = fgl_getenv("QX_CLEAR_STATIC_LABEL") 
	DISPLAY rec_envqx_.qx_clear_static_label TO envqx_qx_clear_static_label 
	LET rec_envqx_.qx_client_host = fgl_getenv("QX_CLIENT_HOST") 
	DISPLAY rec_envqx_.qx_client_host TO envqx_qx_client_host 
	LET rec_envqx_.qx_client_ip = fgl_getenv("QX_CLIENT_IP") 
	DISPLAY rec_envqx_.qx_client_ip TO envqx_qx_client_ip 
	LET rec_envqx_.qx_compat = fgl_getenv("QX_COMPAT") 
	DISPLAY rec_envqx_.qx_compat TO envqx_qx_compat 
	LET rec_envqx_.qx_debug_hosts = fgl_getenv("QX_DEBUG_HOSTS") 
	DISPLAY rec_envqx_.qx_debug_hosts TO envqx_qx_debug_hosts 
	LET rec_envqx_.qx_dump_passes = fgl_getenv("QX_DUMP_PASSES") 
	DISPLAY rec_envqx_.qx_dump_passes TO envqx_qx_dump_passes 
	LET rec_envqx_.qx_headless_console = fgl_getenv("QX_HEADLESS_CONSOLE") 
	DISPLAY rec_envqx_.qx_headless_console TO envqx_qx_headless_console 
	LET rec_envqx_.qx_headless_mode = fgl_getenv("QX_HEADLESS_MODE") 
	DISPLAY rec_envqx_.qx_headless_mode TO envqx_qx_headless_mode 
	LET rec_envqx_.qx_lognativesqlerrors = fgl_getenv("QX_LOGNATIVESQLERRORS") 
	DISPLAY rec_envqx_.qx_lognativesqlerrors TO envqx_qx_lognativesqlerrors 
	LET rec_envqx_.qx_log_dir = fgl_getenv("QX_LOG_DIR") 
	DISPLAY rec_envqx_.qx_log_dir TO envqx_qx_log_dir 
	LET rec_envqx_.qx_mdi = fgl_getenv("QX_MDI") 
	DISPLAY rec_envqx_.qx_mdi TO envqx_qx_mdi 
	LET rec_envqx_.qx_menu_window = fgl_getenv("QX_MENU_WINDOW") 
	DISPLAY rec_envqx_.qx_menu_window TO envqx_qx_menu_window 
	LET rec_envqx_.qx_menu_window_new_child = fgl_getenv("QX_MENU_WINDOW_NEW_CHILD") 
	DISPLAY rec_envqx_.qx_menu_window_new_child TO envqx_qx_menu_window_new_child 
	LET rec_envqx_.qx_native_linker = fgl_getenv("QX_NATIVE_LINKER") 
	DISPLAY rec_envqx_.qx_native_linker TO envqx_qx_native_linker 
	LET rec_envqx_.qx_no_clean_linker_files = fgl_getenv("QX_NO_CLEAN_LINKER_FILES") 
	DISPLAY rec_envqx_.qx_no_clean_linker_files TO envqx_qx_no_clean_linker_files 
	LET rec_envqx_.qx_opt_level = fgl_getenv("QX_OPT_LEVEL") 
	DISPLAY rec_envqx_.qx_opt_level TO envqx_qx_opt_level 
	LET rec_envqx_.qx_process_id = fgl_getenv("QX_PROCESS_ID") 
	DISPLAY rec_envqx_.qx_process_id TO envqx_qx_process_id 
	LET rec_envqx_.qx_qrun_dump = fgl_getenv("QX_QRUN_DUMP") 
	DISPLAY rec_envqx_.qx_qrun_dump TO envqx_qx_qrun_dump 
	LET rec_envqx_.qx_qrun_port = fgl_getenv("QX_QRUN_PORT") 
	DISPLAY rec_envqx_.qx_qrun_port TO envqx_qx_qrun_port 
	LET rec_envqx_.qx_resource_unlock = fgl_getenv("QX_RESOURCE_UNLOCK") 
	DISPLAY rec_envqx_.qx_resource_unlock TO envqx_qx_resource_unlock 
	LET rec_envqx_.qx_rest_value_xml = fgl_getenv("QX_REST_VALUE_XML") 
	DISPLAY rec_envqx_.qx_rest_value_xml TO envqx_qx_rest_value_xml 
	LET rec_envqx_.qx_run_arg_pref = fgl_getenv("QX_RUN_ARG_PREF") 
	DISPLAY rec_envqx_.qx_run_arg_pref TO envqx_qx_run_arg_pref 
	LET rec_envqx_.qx_session_id = fgl_getenv("QX_SESSION_ID") 
	DISPLAY rec_envqx_.qx_session_id TO envqx_qx_session_id 
	LET rec_envqx_.qx_show_window = fgl_getenv("QX_SHOW_WINDOW") 
	DISPLAY rec_envqx_.qx_show_window TO envqx_qx_show_window 
	LET rec_envqx_.qx_size_dimension = fgl_getenv("QX_SIZE_DIMENSION") 
	DISPLAY rec_envqx_.qx_size_dimension TO envqx_qx_size_dimension 
	LET rec_envqx_.qx_sqlscope_on = fgl_getenv("QX_SQLSCOPE_ON") 
	DISPLAY rec_envqx_.qx_sqlscope_on TO envqx_qx_sqlscope_on 
	LET rec_envqx_.qx_starter_debug_logging = fgl_getenv("QX_STARTER_DEBUG_LOGGING") 
	DISPLAY rec_envqx_.qx_starter_debug_logging TO envqx_qx_starter_debug_logging 
	LET rec_envqx_.qx_starter_redirect_std_out = fgl_getenv("QX_STARTER_REDIRECT_STD_OUT") 
	DISPLAY rec_envqx_.qx_starter_redirect_std_out TO envqx_qx_starter_redirect_std_out 
	LET rec_envqx_.qx_ui_mode_override = fgl_getenv("QX_UI_MODE_OVERRIDE") 
	DISPLAY rec_envqx_.qx_ui_mode_override TO envqx_qx_ui_mode_override 
	LET rec_envqx_.qx_use_simple_cache_path = fgl_getenv("QX_USE_SIMPLE_CACHE_PATH") 
	DISPLAY rec_envqx_.qx_use_simple_cache_path TO envqx_qx_use_simple_cache_path 
	LET rec_envqx_.qx_verbose_cache = fgl_getenv("QX_VERBOSE_CACHE") 
	DISPLAY rec_envqx_.qx_verbose_cache TO envqx_qx_verbose_cache 
	LET rec_envqx_.qx_verify_after = fgl_getenv("QX_VERIFY_AFTER") 
	DISPLAY rec_envqx_.qx_verify_after TO envqx_qx_verify_after 


	# C-Compiler/Sources ----------------------------------------------------------------------
	LET rec_c_compiler.c_interface_locale = fgl_getenv("C_INTERFACE_LOCALE") 
	DISPLAY rec_c_compiler.c_interface_locale TO c_c_interface_locale 

	LET rec_c_compiler.fglc_tracegen = fgl_getenv("FGLC_TRACEGEN") 
	DISPLAY rec_c_compiler.fglc_tracegen TO c_fglc_tracegen 

	LET rec_c_compiler.fglc_traceproc = fgl_getenv("FGLC_TRACEPROC") 
	DISPLAY rec_c_compiler.fglc_traceproc TO c_fglc_traceproc 

	LET rec_c_compiler.fglc_traceprocerrs = fgl_getenv("FGLC_TRACEPROCERRS") 
	DISPLAY rec_c_compiler.fglc_traceprocerrs TO c_fglc_traceprocerrs 

	LET rec_c_compiler.fglc_yydebug = fgl_getenv("FGLC_YYDEBUG") 
	DISPLAY rec_c_compiler.fglc_yydebug TO c_fglc_yydebug 

	LET rec_c_compiler.vc_devenvdir = fgl_getenv("DevEnvDir") 
	DISPLAY rec_c_compiler.vc_devenvdir TO c_vc_devenvdir 

	LET rec_c_compiler.vc_include = fgl_getenv("INCLUDE") 
	DISPLAY rec_c_compiler.vc_include TO c_vc_include 

	LET rec_c_compiler.vc_lib = fgl_getenv("LIB") 
	DISPLAY rec_c_compiler.vc_lib TO c_vc_lib 

	LET rec_c_compiler.vc_libpath = fgl_getenv("LIBPATH") 
	DISPLAY rec_c_compiler.vc_libpath TO c_vc_libpath 

	LET rec_c_compiler.vc_vcinstalldir = fgl_getenv("VCINSTALLDIR") 
	DISPLAY rec_c_compiler.vc_vcinstalldir TO c_vc_vcinstalldir 

	LET rec_c_compiler.vc_visualstudioversion = fgl_getenv("VisualStudioVersion") 
	DISPLAY rec_c_compiler.vc_visualstudioversion TO c_vc_visualstudioversion 



	# OS ----------------------------------------------------------------------
	LET rec_os.username = fgl_username() 
	DISPLAY rec_os.username TO os_username 

	LET rec_os.system_username = fgl_getproperty("system","username") 
	DISPLAY rec_os.system_username TO os_system_username 

	LET rec_os.server_os = fgl_arch() 
	DISPLAY rec_os.server_os TO os_server_os 

	LET rec_os.server_os_name = get_server_os_name(modu_rec_general.server_os) 
	DISPLAY rec_os.server_os_name TO os_server_os_name 

	LET rec_os.java_home = fgl_getenv("JAVA_HOME") 
	DISPLAY rec_os.java_home TO os_java_home 

	#DB-General  ----------------------------------------------------------------------
	LET rec_db.lycia_db_driver = fgl_getenv("LYCIA_DB_DRIVER") 
	DISPLAY rec_db.lycia_db_driver TO envdb_lycia_db_driver 

	LET rec_db.dbpath = fgl_getenv("DBPATH") 
	DISPLAY rec_db.dbpath TO envdb_dbpath 




	########################################################################################
	#Informix related env variables

	#sensitive information
	LET rec_informix.logname = fgl_getenv("LOGNAME") 
	IF includeauthenticationinfo THEN 
		LET rec_informix.informixpass = fgl_getenv("INFORMIXPASS") --show REAL password !!! security) 
	ELSE 
		LET rec_informix.informixpass = informixpassparthiddenstring --show decripted password 
	END IF 
	#--------

	LET rec_informix.dbpath = fgl_getenv("DBPATH") 
	LET rec_informix.db_locale = fgl_getenv("DB_LOCALE") 
	LET rec_informix.informixserver = fgl_getenv("INFORMIXSERVER") 
	LET rec_informix.informixdir = fgl_getenv("INFORMIXDIR") 
	LET rec_informix.informixsqlhosts = fgl_getenv("INFORMIXSQLHOSTS") 
	LET rec_informix.client_locale = fgl_getenv("CLIENT_LOCALE") 
	LET rec_informix.qxss_db_is_dsn = fgl_getenv("QXSS_DB_IS_DSN") 
	LET rec_informix.delimident = fgl_getenv("DELIMIDENT") 
	LET rec_informix.dbdelimiter = fgl_getenv("DBDELIMITER") 
	LET rec_informix.dbcentury = fgl_getenv("DBCENTURY") 
	LET rec_informix.dbformat = fgl_getenv("DBFORMAT") 
	LET rec_informix.onconfig = fgl_getenv("ONCONFIG") 

	WHENEVER ERROR CONTINUE 

	SQL 
	SELECT FIRST 1 dbinfo('version', 'major') FROM systables INTO $temp_string WHERE tabid = 1; 
	END SQL 
	LET rec_informix.db_name = temp_string 


	SQL 
	SELECT FIRST 1 dbinfo("version", "full") 
	INTO $temp_string 
	FROM systables; 
	END SQL 
	LET rec_informix.db_name_full = temp_string 

	SQL 
	SELECT FIRST 1 dbinfo("version", "major") 
	INTO $temp_string 
	FROM systables; 
	END SQL 
	LET rec_informix.db_major_version = temp_string 

	SQL 
	SELECT FIRST 1 dbinfo("version", "os") 
	INTO $temp_string 
	FROM systables; 
	END SQL 
	LET rec_informix.db_infversionos = temp_string 

	SQL 
	SELECT dbinfo('dbhostname') 
	INTO $temp_string 
	FROM systables 
	WHERE tabid = 1; 
	END SQL 
	LET rec_informix.dbhostname = temp_string 

	SQL 
	SELECT dbinfo('dbname') 
	INTO $temp_string 
	FROM systables 
	WHERE tabid = 1; 
	END SQL 
	LET rec_informix.dbname = temp_string 

	SQL 
	SELECT dbinfo('sessionid') as my_sessionid 
	INTO $temp_string 
	FROM systables 
	WHERE tabname = 'systables'; 
	END SQL 
	LET rec_informix.sessionid = temp_string 

	WHENEVER ERROR STOP 


	DISPLAY rec_informix.logname TO inf_logname 
	DISPLAY rec_informix.informixpass TO inf_informixpass 
	DISPLAY rec_informix.dbpath TO inf_dbpath 
	DISPLAY rec_informix.db_locale TO inf_db_locale 
	DISPLAY rec_informix.informixserver TO inf_informixserver 
	DISPLAY rec_informix.informixdir TO inf_informixdir 
	DISPLAY rec_informix.informixsqlhosts TO inf_informixsqlhosts 
	DISPLAY rec_informix.client_locale TO inf_client_locale 
	DISPLAY rec_informix.qxss_db_is_dsn TO inf_qxss_db_is_dsn 
	DISPLAY rec_informix.delimident TO inf_delimident 
	DISPLAY rec_informix.dbdelimiter TO inf_dbdelimiter 

	DISPLAY rec_informix.dbcentury TO inf_dbcentury 
	DISPLAY rec_informix.dbformat TO inf_dbformat 


	DISPLAY rec_informix.db_name TO inf_versionservertype 
	DISPLAY rec_informix.db_name_full TO inf_versionfull 
	DISPLAY rec_informix.db_major_version TO inf_versionmajor 
	DISPLAY rec_informix.db_infversionos TO inf_versionos 
	DISPLAY rec_informix.dbhostname TO inf_dbhostname 
	DISPLAY rec_informix.dbname TO inf_dbname 
	DISPLAY rec_informix.sessionid TO inf_sessionid 
	DISPLAY rec_informix.onconfig TO inf_onconfig 




	###############################################################################

	#Oracle
	LET rec_oracle.oracle_sid = fgl_getenv("ORACLE_SID") 
	DISPLAY rec_oracle.oracle_sid TO oracle_oracle_sid 
	LET rec_oracle.oracle_home = fgl_getenv("ORACLE_HOME") 
	DISPLAY rec_oracle.oracle_home TO oracle_oracle_home 



	# SQL Server ##########################
	LET rec_sqlserver.odbc_dsn = fgl_getenv("ODBC_DSN") 
	DISPLAY rec_sqlserver.odbc_dsn TO sqlserver_odbc_dsn 

	LET rec_sqlserver.sqlserver = fgl_getenv("SQLSERVER") 
	DISPLAY rec_sqlserver.sqlserver TO sqlserver_sqlserver 





	# DB2 ##########################
	LET rec_db2.db2dir = fgl_getenv("DB2DIR") 
	DISPLAY rec_db2.db2dir TO db2_db2dir 
	LET rec_db2.db2instance = fgl_getenv("DB2INSTANCE") 
	DISPLAY rec_db2.db2instance TO db2_db2instance 


	#BIRT -----------------------------------------------------------
	LET rec_birt.birt_libdir = fgl_getenv("BIRT_LIBDIR") 
	DISPLAY rec_birt.birt_libdir TO birt_birt_libdir 


	# END OF Retrieving the System Information
	################################################################################

	MENU 
		BEFORE MENU 
			CALL dialog.setActionHidden("CANCEL",TRUE) 
--			CALL dialog.setActionHidden("ACCEPT",TRUE) 
			DISPLAY get_debug() TO checkbox_debug 

			DISPLAY get_url_mode() TO url_mode 
			DISPLAY get_db() TO url_kandoodb 
			DISPLAY get_db() TO url_db 
			DISPLAY get_ku_sign_on_code() TO url_sign_on_code 
			DISPLAY get_settings_maxchildlaunch() TO url_max_child 
			DISPLAY get_ku_password_text() TO url_password_text 
			DISPLAY get_ku_login_name() TO url_login_name 
			DISPLAY get_ku_email() TO url_email 
			DISPLAY get_url_vendor_code() TO url_vendor_code 
			DISPLAY get_url_company_code() TO url_company_code 
			DISPLAY get_url_cust_code() TO url_customer_code 
			DISPLAY get_url_invoice_number() TO url_invoice_number 
			DISPLAY get_url_cashreceipt_number() TO url_cashreceipt_number 
			DISPLAY get_url_credit_number() TO url_credit_number 
			DISPLAY get_url_bankdepartment_number() TO url_bankdepartment_number 
			DISPLAY get_url_batch_number() TO url_batch_number 
			DISPLAY get_url_invoice_text() TO url_invoice_text 
			DISPLAY get_url_credit_text() TO url_credit_text 
			DISPLAY get_url_load_file() TO url_load_file 
			#DISPLAY get_url_file_list_element(1) TO url_file_list #produces ugly error messages when it is not set
			DISPLAY get_url_query_text() TO url_query_text 
			DISPLAY get_url_file_path() TO url_file_path 
			DISPLAY get_url_file_name() TO url_file_name 
			DISPLAY get_url_int1() TO url_int1 
			DISPLAY get_url_int2() TO url_int2 
			DISPLAY get_url_str1() TO url_str1 
			DISPLAY get_url_str2() TO url_str2 
			DISPLAY get_url_id_int() TO url_id_int 
			DISPLAY get_url_id_char() TO url_id_char 
			DISPLAY get_url_char() TO url_char 
			DISPLAY get_debug() TO url_debug 
			DISPLAY get_url_order() TO url_order 
			DISPLAY get_url_tb_project_name() TO url_tb_project_name 
			DISPLAY get_url_tb_module_name() TO url_tb_module_name 
			DISPLAY get_url_tb_menu_name() TO url_tb_menu_name 
			DISPLAY get_url_tb_user_name() TO url_tb_user_name 
			DISPLAY get_url_vdom() TO url_vdom 


		ON ACTION "Debug" 
			IF get_debug() = false THEN 
				CALL set_debug(true) 
			ELSE 
				CALL set_debug(false) 
			END IF 
			DISPLAY get_debug() TO checkbox_debug 

		ON ACTION "Report" 
			OPEN WINDOW wsubmission with FORM "form/4gl_questionaire" 
			LET rec_customer.customerincludeenvironmentvariables = true 
			LET rec_customer.customerincludesystemreport = true 
			LET rec_customer.customerincluderegistryinformation = true 
			LET rec_customer.customerrunfromlocation = 1 
			LET rec_customer.customercss = false 
			LET rec_customer.customerqxtheme = false 

			LET rec_customer.customerjavascript = false 
			LET rec_customer.customervdom = false 
			LET rec_customer.customercsources = false 
			LET rec_customer.customerjavasources = false 


			INPUT BY NAME rec_customer.* WITHOUT DEFAULTS 

			#MESSAGE "This will take about 30 seconds depending on your system"
			CLOSE WINDOW wsubmission 
			CALL writelyciareportfile() 

			#START REPORT lycia_system_report TO PIPE "more > REPORT.out"
			#	   OUTPUT TO REPORT lycia_system_report("donated by Hubert")
			#	FINISH REPORT lycia_system_report


			{
					MENU
						ON ACTION "Tab"
							CALL fgl_report_type("my_pipe","new_window")  # OR q4gl_add_user_report_type("note","text")
							START REPORT lycia_system_report TO PIPE "my_pipe"
								   OUTPUT TO REPORT lycia_system_report("donated by Hubert")
								   FINISH REPORT lycia_system_report
							EXIT MENU

						ON ACTION "PIPE>FILE"
							START REPORT lycia_system_report TO PIPE "more > REPORT.out"
								   OUTPUT TO REPORT lycia_system_report("donated by Hubert")
					   		FINISH REPORT lycia_system_report
							EXIT MENU

						ON ACTION "Report"
			#START REPORT lycia_system_report TO PRINTER
							START REPORT lycia_system_report TO PIPE "my_pipe"
							OUTPUT TO REPORT lycia_system_report("donated by Hubert")
							FINISH REPORT lycia_system_report
							EXIT MENU


						ON ACTION "File Dialog"
							CALL fgl_report_type("my_pipe","shell_open")  # OR q4gl_add_user_report_type()
							START REPORT lycia_system_report TO PIPE "my_pipe"
								   OUTPUT TO REPORT lycia_system_report("donated by Hubert")
								   FINISH REPORT lycia_system_report
							EXIT MENU

			###############################################################################
						ON ACTION "Download"
							CALL fgl_report_type("my_pipe","download")  # OR q4gl_add_user_report_type("note","text")
							START REPORT lycia_system_report TO PIPE "my_pipe"
								   OUTPUT TO REPORT lycia_system_report("donated by Hubert")
								   FINISH REPORT lycia_system_report
							EXIT MENU

			##############################################################################

						ON ACTION "PRINT"
							CALL fgl_report_type("my_pipe","PRINT")  # OR q4gl_add_user_report_type("note","text")
							START REPORT lycia_system_report TO PIPE "my_pipe"
								   OUTPUT TO REPORT lycia_system_report("donated by Hubert")
								   FINISH REPORT lycia_system_report
							EXIT MENU


						ON ACTION "Console Window"
							CALL fgl_report_type("my_pipe","text_viewer")  # OR q4gl_add_user_report_type("note","text")
							START REPORT lycia_system_report TO PIPE "my_pipe"
								   OUTPUT TO REPORT lycia_system_report("donated by Hubert")
								   FINISH REPORT lycia_system_report
							EXIT MENU

						ON ACTION "Default"
							CALL fgl_report_type("my_pipe","default")  # OR q4gl_add_user_report_type("note","text")
							START REPORT lycia_system_report TO PIPE "my_pipe"
								   OUTPUT TO REPORT lycia_system_report("donated by Hubert")
								   FINISH REPORT lycia_system_report
							EXIT MENU


						ON ACTION "Inject"
							CALL fgl_report_type("my_pipe","inject")  # OR q4gl_add_user_report_type("note","text")
							START REPORT lycia_system_report TO PIPE "my_pipe"
								   OUTPUT TO REPORT lycia_system_report("donated by Hubert")
								   FINISH REPORT lycia_system_report
							EXIT MENU

						ON ACTION "CANCEL"
							EXIT MENU
					END MENU
			}

				ON ACTION "getSystemInfo" 
					CALL getsysteminfo() 

				ON ACTION "getRegistryInfo" 
					CASE fgl_arch() 
						WHEN "nt" 
							RUN "system/win_reg_query.bat" 
						WHEN "lnx" 
							CALL os.Path.chrwx("lnx_reg_query.sh", "508") # chmod 774 lnx_reg_query.sh 
							RUN "system/lnx_reg_query.sh" 
					END CASE 

					LOCATE reginfo in file "regrep.txt" 
					DISPLAY reginfo TO systeminfo 


				ON ACTION "WEB-HELP" 
					CALL onlineHelp(NULL,"Environment") 

				ON ACTION ("Exit","ACCEPT") 
					EXIT MENU 

	END MENU 

	CALL fgl_window_close("w_about") 

END FUNCTION 


##############################################################
# FUNCTION get_database_type()
##############################################################
FUNCTION get_database_type() 
	DEFINE db_type_info VARCHAR(100) 
	DEFINE ret_str VARCHAR(120) 
	DEFINE db_type CHAR(3) 

	######################################################################
	LET db_type = db_get_database_type() 
	######################################################################

	CASE db_type 
		WHEN "IFX" 
			LET db_type_info = "Informix Database" 
		WHEN "ORA" 
			LET db_type_info = "Oracle Database" 
		WHEN "MSV" 
			LET db_type_info = "MS-SQL Server Database" 
		WHEN "DB2" 
			LET db_type_info = "DB2 Database" 
		WHEN "MYS" 
			LET db_type_info = "My SQL Database" 
		WHEN "PGS" 
			LET db_type_info = "PostgreSQL Database" 
		WHEN "PEV" 
			LET db_type_info = "Pervasive Database" 
		WHEN "MDB" 
			LET db_type_info = "MAXDB (SAP-MySQL) Database" 
		WHEN "SYB" 
			LET db_type_info = "Sybase Database" 
		WHEN "FIB" 
			LET db_type_info = "Firebird Database" 
		WHEN "ADB" 
			LET db_type_info = "Adabase Database" 

		OTHERWISE 
			LET db_type_info = "Unknown" 

	END CASE 
	LET ret_str = db_type clipped, " = ", db_type_info 
	RETURN ret_str 
END FUNCTION 

{
##############################################################
# FUNCTION prog_arguments()
##############################################################
FUNCTION prog_arguments() 
	DEFINE PROG_CHILD VARCHAR(200), i, sl int 

	FOR i = 0 TO num_args() 
		LET PROG_CHILD = trim(PROG_CHILD) , trim(arg_val(i)) , " /" 
	END FOR 

	LET sl = length(PROG_CHILD) 
	LET PROG_CHILD[sl] = "" --overwrite the final slash at the ending 

	RETURN PROG_CHILD 

END FUNCTION 
}

##############################################################
# FUNCTION writeLyciaReportFile()
#
#
##############################################################
FUNCTION writelyciareportfile() 
	#DEFINE SystemInfo TEXT
	DEFINE cmdrunstring STRING 
	DEFINE temp_string STRING 


	CASE fgl_arch() 
		WHEN "nt" 


			{			LET cmdRunString = "type REPORT.out > ", reportFileName
			    	RUN cmdRunString

			#Get Windows Registry information
			    	RUN "system/win_reg_query.bat"

						LET cmdRunString = "type regrep.txt >> ", reportFileName
			    	RUN cmdRunString


			#systeminfo.txt
			    	RUN "systeminfo > systeminfo.txt"

						LET cmdRunString = "type systeminfo.txt >> ", reportFileName
			    	RUN cmdRunString
			}


			IF rec_customer.customerincluderegistryinformation THEN 
				#Get Windows Registry information
				MESSAGE "Generating Windows Registry Report" 
				RUN "system/win_reg_query.bat" 
			END IF 

			IF rec_customer.customerincludesystemreport THEN 
				#systeminfo.txt
				MESSAGE "Generating OS SystemInfo Report (takes ~30 seconds)" 
				RUN "system/systeminfo > systeminfo.txt" 
			END IF 


			#Create REPORT on environment variables etc.. AND include the registry AND systeminfo files
			START REPORT lycia_system_report TO reportfilename #pipe "more > REPORT.out" 
			OUTPUT TO REPORT lycia_system_report("donated by Hubert") 
			FINISH REPORT lycia_system_report 

			LOCATE reportfile in file reportfilename 
			DISPLAY reportfile TO systeminfo 

		WHEN "lnx" 

			IF rec_customer.customerincluderegistryinformation THEN 
				#Get Windows Registry information
				MESSAGE "Generating Linux Environment Report" 
				CALL os.Path.chrwx("lnx_reg_query.sh", "508") # chmod 774 lnx_reg_query.sh 
				RUN "lnx_reg_query.sh" 
			END IF 

			IF rec_customer.customerincludesystemreport THEN 
				#systeminfo.txt
				MESSAGE "Generating OS SystemInfo Report" 
				CALL os.Path.chrwx("systeminfo.sh", "508") # chmod 774 systeminfo.sh 
				RUN "systeminfo.sh" 
			END IF 

			#Create REPORT on environment variables etc.. AND include the registry AND systeminfo files
			START REPORT lycia_system_report TO reportfilename #pipe "more > REPORT.out" 
			OUTPUT TO REPORT lycia_system_report("donated by Hubert") 
			FINISH REPORT lycia_system_report 

			LOCATE reportfile in file reportfilename 
			DISPLAY reportfile TO systeminfo 

		OTHERWISE 
			LET cmdrunstring = "cat REPORT.out >", reportfilename 
			RUN cmdrunstring 

			RUN "cat /proc/meminfo >systeminfo.txt" 
			RUN "cat /proc/cpuinfo >>systeminfo.txt" 

			LET cmdrunstring = "cat systeminfo.txt >>", reportfilename 
			RUN cmdrunstring 

	END CASE 

	LOCATE reportfile in file reportfilename 
	DISPLAY reportfile TO systeminfo 

	#Download the REPORT file
	IF fgl_download(reportfilename, reportfilename) = false THEN 
		LET temp_string = "Could NOT download ", fgl_getenv("HOMEPATH") clipped, reportfilename clipped 
		CALL fgl_winmessage("Error when downloading the REPORT file",temp_string,"error") 
	ELSE 
		LET temp_string = "Downloaded the REPORT file ", fgl_getenv("HOMEPATH") clipped, reportfilename clipped 
		CALL fgl_winmessage("Report File Download",temp_string,"info") 
	END IF 


END FUNCTION 

########################################################
# FUNCTION getDBTypeName(pDB_type)
########################################################
FUNCTION getdbtypename(pdb_type) 
	DEFINE pdb_type VARCHAR(5) 

	CASE pdb_type 
		WHEN "IFX" 
			RETURN "You are connected TO an Informix Database" 
		WHEN "ORA" 
			RETURN "You are connected TO an Oracle Database" 
		WHEN "MSV" 
			RETURN "You are connected TO an MS-SQL Server Database" 
		WHEN "DB2" 
			RETURN "You are connected TO an DB2 Database" 
		WHEN "MYS" 
			RETURN "You are connected TO an My SQL Database" 
		WHEN "PGS" 
			RETURN "You are connected TO an PostgreSQL Database" 
		WHEN "PEV" 
			RETURN "You are connected TO an Pervasive Database" 
		WHEN "MDB" 
			RETURN "You are connected TO an MAXDB (SAP-MySQL) Database" 
		WHEN "SYB" 
			RETURN "You are connected TO an Sybase Database" 
		WHEN "FIB" 
			RETURN "You are connected TO an Firebird Database" 
		WHEN "ADB" 
			RETURN "You are connected TO an Adabase Database" 

		OTHERWISE 
			RETURN "Unknown Database Type (OR failed TO connect)" 

	END CASE 
END FUNCTION 


##################################################
# Get OS System information
##################################################
FUNCTION getsysteminfo() 

	CASE fgl_arch() 
		WHEN "nt" 
			RUN "systeminfo >systeminfo.txt" 
		WHEN "lnx" 
			CALL os.Path.chrwx("systeminfo.sh", "508") # chmod 774 systeminfo.sh 
			RUN "systeminfo.sh" 

		OTHERWISE 
			RUN "cat /proc/meminfo >systeminfo.txt" 
			RUN "cat /proc/cpuinfo >>systeminfo.txt" 
	END CASE 

	LOCATE systeminfo in file "systeminfo.txt" 

	DISPLAY BY NAME systeminfo 

END FUNCTION 


###################################################
FUNCTION get_server_os_name(pserveros) 
	DEFINE pserveros STRING 
	DEFINE retserverosname STRING 

	CASE fgl_arch() 

		WHEN "nt" 
			LET retserverosname = "nt = Windows" 

		WHEN "lnx" 
			LET retserverosname = "lnx = Linux" 

		WHEN "sun" 
			LET retserverosname = "sun = 32-bit Sun Solaris" 

		WHEN "s64" 
			LET retserverosname = "s64 = 64-bit Sun Solaris" 

		WHEN "hp" 
			LET retserverosname = "hp = 32-bit HP-UX PA-RISC" 

		WHEN "h64" 
			LET retserverosname = "h64 = 64-bit HP-UX PA-RISC" 

		WHEN "i32" 
			LET retserverosname = "i32 = 32-bit HP-UX Itanium" 

		WHEN "i64" 
			LET retserverosname = "i64 = 64-bit HP-UX Itanium" 

		WHEN "dec" 
			LET retserverosname = "dec = Compaq Tru64" 

		WHEN "s86" 
			LET retserverosname = "s86 = Sun Solaris x86" 

		WHEN "aix" 
			LET retserverosname = "aix = IBM AIX 4.31" 

		WHEN "a64" 
			LET retserverosname = "a64 = IBM AIX 5L" 
		WHEN "ncr" 
			LET retserverosname = "ncr = NCR MP-RAS" 

	END CASE 

	RETURN retserverosname 

END FUNCTION 



######################################################
#REPORT lycia_system_report()
######################################################
REPORT lycia_system_report(dummy) 
	DEFINE dummy varchar(100) 

	OUTPUT 
	bottom margin 1 
	top margin 1 
	PAGE length 64 
	right margin 132 

	FORMAT 
	#  ON EVERY ROW
	#      PRINT dummy



		FIRST PAGE HEADER 
			SKIP 1 LINES 
			PRINT COLUMN 1, "Lycia System Environment Report" 
			SKIP 1 LINES 
			PRINT COLUMN 1, "Executing date: ", today USING "dd mmm. yyyy" -- "Executing date: " 
			PRINT COLUMN 1, "Executing time: ", time -- "Executing date: " 
		ON EVERY ROW 

			SKIP 3 LINES 
			PRINT "##################################################################################" 
			PRINT "# #" 
			PRINT "# Customer/User Details #" 
			PRINT "# #" 
			PRINT "##################################################################################" 
			SKIP 3 LINES 

			PRINT COLUMN 1, "Customer Name:", 
			COLUMN 25, rec_customer.customername 
			PRINT COLUMN 1, "E-Mail Address:", 
			COLUMN 25, rec_customer.customeremailaddress 
			PRINT COLUMN 1, "Company:", 
			COLUMN 25, rec_customer.customercompany 
			PRINT COLUMN 1, "Browser Details:", 
			COLUMN 25, rec_customer.customerbrowser 

			PRINT COLUMN 1, "Tool launch location:", 
			COLUMN 25, trim(rec_customer.customerRunFromLocation), 
			COLUMN 40, "1=LyciaStudio, 2=Dev Browser,3=Remote Browser" 


			PRINT COLUMN 1, "App uses custom CSS:", 
			COLUMN 25, trim(rec_customer.customerCss) 
			PRINT COLUMN 1, "App uses custom QxTheme:", 
			COLUMN 25, trim(rec_customer.customerQxTheme) 


			PRINT COLUMN 1, "App uses Cl. JavaScript:", 
			COLUMN 25, rec_customer.customerjavascript 
			PRINT COLUMN 1, "Using VDOM:", 
			COLUMN 25, trim(rec_customer.customerVDOM) 
			PRINT COLUMN 1, "App uses custom QxTheme:", 
			COLUMN 25, rec_customer.customercsources 
			PRINT COLUMN 1, "App uses custom QxTheme:", 
			COLUMN 25, rec_customer.customerjavasources 



			PRINT COLUMN 1, "Incl. Environment:", 
			COLUMN 25, rec_customer.customerincludeenvironmentvariables 
			PRINT COLUMN 1, "Incl. SystemReport:", 
			COLUMN 25, rec_customer.customerincludesystemreport 
			PRINT COLUMN 1, "Incl. Registry:", 
			COLUMN 25, rec_customer.customerincluderegistryinformation 
			PRINT COLUMN 1, "Customer Message:", 
			COLUMN 25, rec_customer.customermessage wordwrap 



			SKIP 3 LINES 
			PRINT "##################################################################################" 
			PRINT "# #" 
			PRINT "# Lycia Environment AND internal properties #" 
			PRINT "# #" 
			PRINT "##################################################################################" 
			SKIP 3 LINES 

			PRINT COLUMN 1, "Lycia Version:", 
			COLUMN 25, rec_main.lycia_version 
			PRINT COLUMN 1, "Client Type:", 
			COLUMN 25, rec_main.frontendname 
			PRINT COLUMN 1, "Client Version:", 
			COLUMN 25, rec_main.frontendversion 
			PRINT COLUMN 1, "GUI Misc. Version:", 
			COLUMN 25, rec_main.gui_misc_version 
			PRINT COLUMN 1, "App Server OS:", 
			COLUMN 25, rec_main.server_os_name 

			SKIP 1 LINES 
			PRINT "----- General --------------------------------------------------------------------" 
			SKIP 1 LINES 
			PRINT COLUMN 1, "Lycia Version:", 
			COLUMN 25, modu_rec_general.lycia_version 
			PRINT COLUMN 1, "Client Type:", 
			COLUMN 25, modu_rec_general.frontendname 
			PRINT COLUMN 1, "Client Version:", 
			COLUMN 25, modu_rec_general.frontendversion 
			PRINT COLUMN 1, "GUI Misc. Version:", 
			COLUMN 25, modu_rec_general.gui_misc_version 
			PRINT COLUMN 1, "App-Server OS :", 
			COLUMN 25, modu_rec_general.server_os 
			PRINT COLUMN 1, "App-Server OS Name:", 
			COLUMN 25, modu_rec_general.server_os_name 
			PRINT COLUMN 1, "UI Type:", 
			COLUMN 25, modu_rec_general.uitype 
			PRINT COLUMN 1, "Child process:", 
			COLUMN 25, modu_rec_general.child_process 
			PRINT COLUMN 1, "DBPATH:", 
			COLUMN 25, modu_rec_general.dbpath 
			PRINT COLUMN 1, "DBDATE:", 
			COLUMN 25, modu_rec_general.env_dbdate 
			PRINT COLUMN 1, "DBTIME:", 
			COLUMN 25, modu_rec_general.dbtime 
			PRINT COLUMN 1, "DBMONEY:", 
			COLUMN 25, modu_rec_general.dbmoney 
			PRINT COLUMN 1, "DB_LOCALE:", 
			COLUMN 25, modu_rec_general.db_locale 
			PRINT COLUMN 1, "CLIENT_LOCALE:", 
			COLUMN 25, modu_rec_general.client_locale 

			SKIP 1 LINES 
			PRINT "----- Server ---------------------------------------------------------------------" 
			SKIP 1 LINES 
			PRINT COLUMN 1, "Host Name:", 
			COLUMN 25, rec_server.qx_server_host 
			PRINT COLUMN 1, "IP-Address:", 
			COLUMN 25, rec_server.qx_server_ip 
			PRINT COLUMN 1, "Session ID:", 
			COLUMN 25, rec_server.qx_session_id 
			PRINT COLUMN 1, "Command ID:", 
			COLUMN 25, rec_server.qx_command_id 
			PRINT COLUMN 1, "Process ID:", 
			COLUMN 25, rec_server.qx_process_id 
			PRINT COLUMN 1, "QX_CHILD:", 
			COLUMN 25, rec_server.qx_child 
			PRINT COLUMN 1, "Host Name:", 
			COLUMN 25, rec_server.server_hostname 
			PRINT COLUMN 1, "IP-Address:", 
			COLUMN 25, rec_server.server_ipaddress 

			SKIP 1 LINES 
			PRINT "----- Client ---------------------------------------------------------------------" 
			SKIP 1 LINES 
			PRINT COLUMN 1, "Client Type:", 
			COLUMN 25, rec_client.frontendname 
			PRINT COLUMN 1, "Host Name:", 
			COLUMN 25, rec_client.qx_client_host 
			PRINT COLUMN 1, "IP-Address:", 
			COLUMN 25, rec_client.qx_client_ip 
			PRINT COLUMN 1, "Host Name:", 
			COLUMN 25, rec_client.gui_systemnetwork_hostname 
			PRINT COLUMN 1, "IP-Address:", 
			COLUMN 25, rec_client.gui_systemnetwork_ippaddress 
			PRINT COLUMN 1, "Session ID:", 
			COLUMN 25, rec_client.gui_systemnetwork_sessionid 
			PRINT COLUMN 1, "Command ID:", 
			COLUMN 25, rec_client.gui_systemnetwork_commandid 
			PRINT COLUMN 1, "Process Id:", 
			COLUMN 25, rec_client.gui_systemnetwork_processid 
			PRINT COLUMN 1, "LD_LIBRARY_PATH:", 
			COLUMN 25, rec_client.ld_library_path 




			SKIP 1 LINES 
			PRINT "----- Lycia Environment ----------------------------------------------------------------" 
			SKIP 1 LINES 
			PRINT COLUMN 1, "Lycia Version:", 
			COLUMN 25, rec_lycia.lycia_version 
			PRINT COLUMN 1, "LYCIA_DIR:", 
			COLUMN 25, rec_lycia.lycia_dir 
			PRINT COLUMN 1, "LYCIA_DRIVER_PATH:", 
			COLUMN 25, rec_lycia.lycia_driver_path 
			PRINT COLUMN 1, "LYCIA_DB_DRIVER:", 
			COLUMN 25, rec_lycia.lycia_db_driver 
			PRINT COLUMN 1, "LYCIA_CONFIG:", 
			COLUMN 25, rec_lycia.lycia_config 
			PRINT COLUMN 1, "LYCIA_CONFIG_PATH:", 
			COLUMN 25, rec_lycia.lycia_config_path 
			PRINT COLUMN 1, "LYCIA_CONV_FORM_MAX_HEIGHT:", 
			COLUMN 25, rec_lycia.lycia_conv_form_max_height 
			PRINT COLUMN 1, "LYCIA_CONV_FORM_MAX_WIDTH:", 
			COLUMN 25, rec_lycia.lycia_conv_form_max_width 
			PRINT COLUMN 1, "LYCIA_DB_NAMEMAP:", 
			COLUMN 25, rec_lycia.lycia_db_namemap 
			PRINT COLUMN 1, "LYCIA_LIC_KEY:", 
			COLUMN 25, rec_lycia.lycia_lic_key 
			PRINT COLUMN 1, "LYCIA_MSGPATH:", 
			COLUMN 25, rec_lycia.lycia_msgpath 
			PRINT COLUMN 1, "LYCIA_PATH:", 
			COLUMN 25, rec_lycia.lycia_path 
			PRINT COLUMN 1, "LYCIA_PER_CONVERT_CHECKBOX:", 
			COLUMN 25, rec_lycia.lycia_per_convert_checkbox 
			PRINT COLUMN 1, "LYCIA_POST_MORTEM_LENGTH:", 
			COLUMN 25, rec_lycia.lycia_post_mortem_length 
			PRINT COLUMN 1, "LYCIA_SEVERITY:", 
			COLUMN 25, rec_lycia.lycia_severity 
			PRINT COLUMN 1, "LYCIA_SYSTEM_ACTION_DEFAULTS:", 
			COLUMN 25, rec_lycia.lycia_system_action_defaults 
			PRINT COLUMN 1, "LYCIA_SYSTEM_RESOURCES:", 
			COLUMN 25, rec_lycia.lycia_system_resources 
			PRINT COLUMN 1, "LYCIA_SYSTEM_THEME_CSS:", 
			COLUMN 25, rec_lycia.lycia_system_theme_css 
			PRINT COLUMN 1, "LYCIA_SYSTEM_THEME_QX:", 
			COLUMN 25, rec_lycia.lycia_system_theme_qx 

			SKIP 1 LINES 
			PRINT "----- Environment ----------------------------------------------------------------" 
			SKIP 1 LINES 
			PRINT COLUMN 1, "LYCIA_DIR:", 
			COLUMN 25, modu_rec_env.lycia_dir 
			PRINT COLUMN 1, "MSGPATH:", 
			COLUMN 25, modu_rec_env.msgpath 
			PRINT COLUMN 1, "LINES:", 
			COLUMN 25, modu_rec_env.screen_lines 
			PRINT COLUMN 1, "COLUMNS:", 
			COLUMN 25, modu_rec_env.screen_columns 
			PRINT COLUMN 1, "LYCIA_DRIVER_PATH:", 
			COLUMN 25, modu_rec_env.lycia_driver_path 
			PRINT COLUMN 1, "FGLPROFILE:", 
			COLUMN 25, modu_rec_env.fglprofile 
			PRINT COLUMN 1, "QXDEBUG:", 
			COLUMN 25, modu_rec_env.qxdebug 
			PRINT COLUMN 1, "QXBREAKCH_START:", 
			COLUMN 25, modu_rec_env.qxbreakch_start 
			PRINT COLUMN 1, "QXBREAKCH_END:", 
			COLUMN 25, modu_rec_env.qxbreakch_end 
			PRINT COLUMN 1, "PATH:", 
			COLUMN 25, modu_rec_env.path wordwrap 
			PRINT COLUMN 1, "FGLIMAGEPATH:", 
			COLUMN 25, modu_rec_env.fglimagepath 
			PRINT COLUMN 1, "QX_MENU_WINDOW:", 
			COLUMN 25, modu_rec_env.qx_menu_window 
			PRINT COLUMN 1, "CLASSPATH:", 
			COLUMN 25, modu_rec_env.classpath 
			PRINT COLUMN 1, "TEMP:", 
			COLUMN 25, modu_rec_env.env_temp 
			PRINT COLUMN 1, "TMP:", 
			COLUMN 25, modu_rec_env.tmp 
			PRINT COLUMN 1, "QXSS_DB_IS_DSN:", 
			COLUMN 25, modu_rec_env.qxss_db_is_dsn 

			PRINT COLUMN 1, "ALLUSERSPROFILE:", 
			COLUMN 25, modu_rec_env.allusersprofile 
			PRINT COLUMN 1, "AXIS2C_HOME:", 
			COLUMN 25, modu_rec_env.axis2c_home 
			PRINT COLUMN 1, "FGLLDPATH:", 
			COLUMN 25, modu_rec_env.fglldpath 


			SKIP 1 LINES 
			PRINT "----- QX<name< Environment Variables------------------------------------------" 
			SKIP 1 LINES 
			PRINT COLUMN 1, "QXCLIENTADDRESS:", 
			COLUMN 25, rec_envqx.qxclientaddress 
			PRINT COLUMN 1, "QXGUIIFD:", 
			COLUMN 25, rec_envqx.qxguiifd 
			PRINT COLUMN 1, "QXGUIOFD:", 
			COLUMN 25, rec_envqx.qxguiofd 
			PRINT COLUMN 1, "QXGUISOCKETFD:", 
			COLUMN 25, rec_envqx.qxguisocketfd 
			PRINT COLUMN 1, "QXHOST:", 
			COLUMN 25, rec_envqx.qxhost 
			PRINT COLUMN 1, "QXINDEXTABLESPACE:", 
			COLUMN 25, rec_envqx.qxindextablespace 
			PRINT COLUMN 1, "QXORA_NOOUTER_NULLOP:", 
			COLUMN 25, rec_envqx.qxora_noouter_nullop 
			PRINT COLUMN 1, "QXPORT:", 
			COLUMN 25, rec_envqx.qxport 
			PRINT COLUMN 1, "QXREP_SPACES:", 
			COLUMN 25, rec_envqx.qxrep_spaces 
			PRINT COLUMN 1, "QXSSLCERTNAME:", 
			COLUMN 25, rec_envqx.qxsslcertname 
			PRINT COLUMN 1, "QXSSLPASS:", 
			COLUMN 25, rec_envqx.qxsslpass 
			PRINT COLUMN 1, "QXSSLPRIVATEKEYNAME:", 
			COLUMN 25, rec_envqx.qxsslprivatekeyname 
			PRINT COLUMN 1, "QXSSL_TIMEOUT:", 
			COLUMN 25, rec_envqx.qxssl_timeout 
			PRINT COLUMN 1, "QXSTDTABLESPACE:", 
			COLUMN 25, rec_envqx.qxstdtablespace 
			PRINT COLUMN 1, "QXTMPTABLESPACE:", 
			COLUMN 25, rec_envqx.qxtmptablespace 



			SKIP 1 LINES 
			PRINT "----- QX_<name< Environment Variables------------------------------------------" 
			SKIP 1 LINES 
			PRINT COLUMN 1, "QX_AOT:", 
			COLUMN 25, rec_envqx_.qx_aot 
			PRINT COLUMN 1, "QX_CHILD:", 
			COLUMN 25, rec_envqx_.qx_child 
			PRINT COLUMN 1, "QX_CID:", 
			COLUMN 25, rec_envqx_.qx_cid 
			PRINT COLUMN 1, "QX_CLEAR_DYNAMIC_LABEL:", 
			COLUMN 25, rec_envqx_.qx_clear_dynamic_label 
			PRINT COLUMN 1, "QX_CLEAR_STATIC_LABEL:", 
			COLUMN 25, rec_envqx_.qx_clear_static_label 
			PRINT COLUMN 1, "QX_CLIENT_HOST:", 
			COLUMN 25, rec_envqx_.qx_client_host 
			PRINT COLUMN 1, "QX_CLIENT_IP:", 
			COLUMN 25, rec_envqx_.qx_client_ip 
			PRINT COLUMN 1, "QX_COMPAT:", 
			COLUMN 25, rec_envqx_.qx_compat 
			PRINT COLUMN 1, "QX_DEBUG_HOSTS:", 
			COLUMN 25, rec_envqx_.qx_debug_hosts 
			PRINT COLUMN 1, "QX_DUMP_PASSES:", 
			COLUMN 25, rec_envqx_.qx_dump_passes 
			PRINT COLUMN 1, "QX_HEADLESS_CONSOLE:", 
			COLUMN 25, rec_envqx_.qx_headless_console 
			PRINT COLUMN 1, "QX_HEADLESS_MODE:", 
			COLUMN 25, rec_envqx_.qx_headless_mode 
			PRINT COLUMN 1, "QX_HEADLESS_MODE:", 
			COLUMN 25, rec_envqx_.qx_headless_mode 
			PRINT COLUMN 1, "QX_LOGNATIVESQLERRORS:", 
			COLUMN 25, rec_envqx_.qx_lognativesqlerrors 
			PRINT COLUMN 1, "QX_LOG_DIR:", 
			COLUMN 25, rec_envqx_.qx_log_dir 
			PRINT COLUMN 1, "QX_MDI:", 
			COLUMN 25, rec_envqx_.qx_mdi 
			PRINT COLUMN 1, "QX_MENU_WINDOW:", 
			COLUMN 25, rec_envqx_.qx_menu_window 
			PRINT COLUMN 1, "QX_MENU_WINDOW_NEW_CHILD:", 
			COLUMN 25, rec_envqx_.qx_menu_window_new_child 
			PRINT COLUMN 1, "QX_NATIVE_LINKER:", 
			COLUMN 25, rec_envqx_.qx_native_linker 
			PRINT COLUMN 1, "QX_NO_CLEAN_LINKER_FILES:", 
			COLUMN 25, rec_envqx_.qx_no_clean_linker_files 
			PRINT COLUMN 1, "QX_OPT_LEVEL:", 
			COLUMN 25, rec_envqx_.qx_opt_level 
			PRINT COLUMN 1, "QX_PROCESS_ID:", 
			COLUMN 25, rec_envqx_.qx_process_id 
			PRINT COLUMN 1, "QX_QRUN_DUMP:", 
			COLUMN 25, rec_envqx_.qx_qrun_dump 
			PRINT COLUMN 1, "QX_QRUN_PORT:", 
			COLUMN 25, rec_envqx_.qx_qrun_port 
			PRINT COLUMN 1, "QX_RESOURCE_UNLOCK:", 
			COLUMN 25, rec_envqx_.qx_resource_unlock 
			PRINT COLUMN 1, "QX_REST_VALUE_XML:", 
			COLUMN 25, rec_envqx_.qx_rest_value_xml 
			PRINT COLUMN 1, "QX_RUN_ARG_PREF:", 
			COLUMN 25, rec_envqx_.qx_run_arg_pref 
			PRINT COLUMN 1, "QX_SESSION_ID:", 
			COLUMN 25, rec_envqx_.qx_session_id 
			PRINT COLUMN 1, "QX_SHOW_WINDOW:", 
			COLUMN 25, rec_envqx_.qx_show_window 
			PRINT COLUMN 1, "QX_SIZE_DIMENSION:", 
			COLUMN 25, rec_envqx_.qx_size_dimension 
			PRINT COLUMN 1, "QX_SQLSCOPE_ON:", 
			COLUMN 25, rec_envqx_.qx_sqlscope_on 
			PRINT COLUMN 1, "QX_STARTER_DEBUG_LOGGING:", 
			COLUMN 25, rec_envqx_.qx_starter_debug_logging 
			PRINT COLUMN 1, "QX_STARTER_REDIRECT_STD_OUT:", 
			COLUMN 25, rec_envqx_.qx_starter_redirect_std_out 
			PRINT COLUMN 1, "QX_UI_MODE_OVERRIDE:", 
			COLUMN 25, rec_envqx_.qx_ui_mode_override 
			PRINT COLUMN 1, "QX_USE_SIMPLE_CACHE_PATH:", 
			COLUMN 25, rec_envqx_.qx_use_simple_cache_path 
			PRINT COLUMN 1, "QX_VERBOSE_CACHE:", 
			COLUMN 25, rec_envqx_.qx_verbose_cache 
			PRINT COLUMN 1, "QX_VERIFY_AFTER:", 
			COLUMN 25, rec_envqx_.qx_verify_after 

			SKIP 1 LINES 
			PRINT "----- C-Compiler/Sources --------------------------------------------------" 
			SKIP 1 LINES 
			PRINT COLUMN 1, "C_INTERFACE_LOCALE:", 
			COLUMN 25, rec_c_compiler.c_interface_locale 
			PRINT COLUMN 1, "FGLC_TRACEGEN:", 
			COLUMN 25, rec_c_compiler.fglc_tracegen 
			PRINT COLUMN 1, "FGLC_TRACEPROC:", 
			COLUMN 25, rec_c_compiler.fglc_traceproc 
			PRINT COLUMN 1, "FGLC_TRACEPROCERRS:", 
			COLUMN 25, rec_c_compiler.fglc_traceprocerrs 
			PRINT COLUMN 1, "FGLC_YYDEBUG:", 
			COLUMN 25, rec_c_compiler.fglc_yydebug 

			PRINT COLUMN 1, "VC_DevEnvDir:", 
			COLUMN 25, rec_c_compiler.vc_devenvdir 
			PRINT COLUMN 1, "VC_INCLUDE:", 
			COLUMN 25, rec_c_compiler.vc_include 
			PRINT COLUMN 1, "VC_LIB:", 
			COLUMN 25, rec_c_compiler.vc_lib 
			PRINT COLUMN 1, "VC_LIBPATH:", 
			COLUMN 25, rec_c_compiler.vc_libpath 
			PRINT COLUMN 1, "VC_VCINSTALLDIR:", 
			COLUMN 25, rec_c_compiler.vc_vcinstalldir 
			PRINT COLUMN 1, "VC_VisualStudioVersion:", 
			COLUMN 25, rec_c_compiler.vc_visualstudioversion 




			SKIP 1 LINES 
			PRINT "----- OS ----------------------------------------------------------------" 
			SKIP 1 LINES 
			PRINT COLUMN 1, "User Name:", 
			COLUMN 25, rec_os.username 
			PRINT COLUMN 1, "User Name:", 
			COLUMN 25, rec_os.system_username 
			PRINT COLUMN 1, "App-Server OS:", 
			COLUMN 25, rec_os.server_os 
			PRINT COLUMN 1, "App-Server OS Det.:", 
			COLUMN 25, rec_os.server_os_name 



			SKIP 1 LINES 
			PRINT "----- DB General ----------------------------------------------------------------" 
			SKIP 1 LINES 
			PRINT COLUMN 1, "LYCIA_DB_DRIVER:", 
			COLUMN 25, rec_db.lycia_db_driver 
			PRINT COLUMN 1, "DBPATH:", 
			COLUMN 25, rec_db.dbpath 




			SKIP 1 LINES 
			PRINT "----- DB-Informix --------------------------------------------------------" 
			SKIP 1 LINES 
			PRINT COLUMN 1, "LOGNAME:", 
			COLUMN 25, rec_informix.logname 

			PRINT COLUMN 1, "INFORMIXPASS:", 
			COLUMN 25, rec_informix.informixpass 


			PRINT COLUMN 1, "DBPATH:", 
			COLUMN 25, rec_informix.dbpath 
			PRINT COLUMN 1, "DB_LOCALE:", 
			COLUMN 25, rec_informix.db_locale 
			PRINT COLUMN 1, "INFORMIXSERVER:", 
			COLUMN 25, rec_informix.informixserver 
			PRINT COLUMN 1, "INFORMIXDIR:", 
			COLUMN 25, rec_informix.informixdir 
			PRINT COLUMN 1, "INFORMIXSQLHOSTS:", 
			COLUMN 25, rec_informix.informixsqlhosts 
			PRINT COLUMN 1, "CLIENT_LOCALE:", 
			COLUMN 25, rec_informix.client_locale 
			PRINT COLUMN 1, "QXSS_DB_IS_DSN:", 
			COLUMN 25, rec_informix.qxss_db_is_dsn 
			PRINT COLUMN 1, "DELIMIDENT:", 
			COLUMN 25, rec_informix.delimident 
			PRINT COLUMN 1, "DBDELIMITER:", 
			COLUMN 25, rec_informix.dbdelimiter 
			PRINT COLUMN 1, "DBFORMAT:", 
			COLUMN 25, rec_informix.dbformat 


			PRINT COLUMN 1, "DB-Name:", 
			COLUMN 25, rec_informix.db_name 
			PRINT COLUMN 1, "DB-Name Det.:", 
			COLUMN 25, rec_informix.db_name_full 
			PRINT COLUMN 1, "DB Major Version:", 
			COLUMN 25, rec_informix.db_major_version 
			PRINT COLUMN 1, "Version OS:", 
			COLUMN 25, rec_informix.db_infversionos 
			PRINT COLUMN 1, "DB-OS:", 
			COLUMN 25, rec_informix.db_os 
			PRINT COLUMN 1, "DbHostName:", 
			COLUMN 25, rec_informix.dbhostname 
			PRINT COLUMN 1, "DbName:", 
			COLUMN 25, rec_informix.dbname 
			PRINT COLUMN 1, "sessionid:", 
			COLUMN 25, rec_informix.sessionid 

			SKIP 1 LINES 
			PRINT "----- Oracle ---------------------------------------------------------" 
			SKIP 1 LINES 
			PRINT COLUMN 1, "ORACLE_SID:", 
			COLUMN 25, rec_oracle.oracle_sid 
			PRINT COLUMN 1, "ORACLE_HOME:", 
			COLUMN 25, rec_oracle.oracle_home 

			SKIP 1 LINES 
			PRINT "----- SQL-Server -----------------------------------------------------" 
			SKIP 1 LINES 
			PRINT COLUMN 1, "ODBC_DSN:", 
			COLUMN 25, rec_sqlserver.odbc_dsn 
			PRINT COLUMN 1, "SQLSERVER:", 
			COLUMN 25, rec_sqlserver.sqlserver 

			SKIP 1 LINES 
			PRINT "----- DB2 ------------------------------------------------------------" 
			SKIP 1 LINES 
			PRINT COLUMN 1, "DB2DIR:", 
			COLUMN 25, rec_db2.db2dir 
			PRINT COLUMN 1, "DB2INSTANCE:", 
			COLUMN 25, rec_db2.db2instance 


			SKIP 1 LINES 
			PRINT "----- BIRT -----------------------------------------------------------" 
			SKIP 1 LINES 
			PRINT COLUMN 1, "BIRT_LIBDIR:", 
			COLUMN 25, rec_birt.birt_libdir 

			WHENEVER ERROR CONTINUE #in case, we have some file access problem 

			SKIP 3 LINES 
			PRINT "##################################################################################" 
			PRINT "# #" 
			PRINT "# Windows Registry #" 
			PRINT "# #" 
			PRINT "##################################################################################" 
			SKIP 3 LINES 

			PRINT file "regrep.txt" 

			SKIP 3 LINES 
			PRINT "##################################################################################" 
			PRINT "# #" 
			PRINT "# OS System Info #" 
			PRINT "# #" 
			PRINT "##################################################################################" 
			SKIP 3 LINES 

			PRINT file "systeminfo.txt" 

			SKIP 3 LINES 
			PRINT "##################################################################################" 
			PRINT "# #" 
			PRINT "# LYCIA_SYSTEM_ACTION_DEFAULTS #" 
			PRINT "# #" 
			PRINT "##################################################################################" 
			SKIP 3 LINES 

			PRINT file rec_lycia.lycia_system_action_defaults 


			SKIP 3 LINES 
			PRINT "##################################################################################" 
			PRINT "# #" 
			PRINT "# FGLPROFILE #" 
			PRINT "# #" 
			PRINT "##################################################################################" 
			SKIP 3 LINES 

			PRINT file modu_rec_env.fglprofile 



			SKIP 3 LINES 
			PRINT "##################################################################################" 
			PRINT "# #" 
			PRINT "# listener.xml (if/when located in LYCIA_CONFIG_PATH #" 
			PRINT "# #" 
			PRINT "##################################################################################" 
			SKIP 3 LINES 


			LET tmpstr = trim(modu_rec_general.lycia_config_path), "/listener.xml" 
			PRINT file tmpstr 

			SKIP 3 LINES 
			PRINT "##################################################################################" 
			PRINT "# #" 
			PRINT "# End of the Lyica System Report #" 
			PRINT "# #" 
			PRINT "##################################################################################" 


			#PAGE TRAILER
			#  SKIP 3 LINES
			#  PRINT COLUMN 45, "Page ## / ##", PAGENO USING "## /", (COUNT(*) + 1 + (5 - ((COUNT(*) + 1) mod 5))) / 5 USING "##" -- "Page ## / ##"

			WHENEVER ERROR stop 

END REPORT 