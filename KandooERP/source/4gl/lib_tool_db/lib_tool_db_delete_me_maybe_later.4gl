{
#HuHo 
# V1 24.03.2005 (Hydra 4.2 CMS-Demo)
# V2 06.02.2011 Adopted for Lycia 1
# V2 30.08.2016 Adopted for Lycia 2
# V3 17.10.2018 Adopted for Lycia 3


############################
# Report Files
	DEFINE env_report STRING
  DEFINE regInfo TEXT
  DEFINE SystemInfo TEXT
	DEFINE reportFileName VARCHAR(200)
	DEFINE reportFile TEXT
	DEFINE includeAuthenticationInfo BOOLEAN  --by default off - in case it IS sent TO i.e. querix BUT the user can turn it on if it IS used for their internal usage
	DEFINE informixPassPartHiddenString STRING  -- i.e. Treehouse -> T*******e
  DEFINE r_db_type STRING
	DEFINE tmpStr STRING
	DEFINE rec_customer 
		RECORD
			customerName VARCHAR(100),
			customerEmailAddress VARCHAR(100),
			customerCompany VARCHAR(100),
			customerBrowser VARCHAR(100),
			customerRunFromLocation SMALLINT,  --tool was run lyciaStudio, independent, remote 
			customerCss SMALLINT,
			customerQxTheme SMALLINT,
			customerJavaScript BOOLEAN,
			customerVDOM SMALLINT,
			customerCSources BOOLEAN,
			customerJavaSources BOOLEAN,
			customerIncludeEnvironmentVariables BOOLEAN,
			customerIncludeSystemReport BOOLEAN,
			customerIncludeRegistryInformation BOOLEAN,			
			customerMessage VARCHAR(2000)
			
		END RECORD
	
	DEFINE rec_dbStatus 
		RECORD
			dbName VARCHAR(50),
			STATUS VARCHAR(50),
			SQLCA_SQLCODE VARCHAR(50),
			driver_error VARCHAR(500),
			native_code VARCHAR(500),
			native_error VARCHAR(500),
			error_text  VARCHAR(2000),
			db_type VARCHAR(5),
			db_type_name VARCHAR(100),
			dbpath  STRING, ##VARCHAR(500),
			LYCIA_DB_DRIVER  VARCHAR(100),
			LOGNAME  VARCHAR(100),
			INFORMIXPASS  VARCHAR(100),
			DB_LOCALE  VARCHAR(100),
			INFORMIXSERVER  VARCHAR(100),
			INFORMIXDIR  VARCHAR(100),
			ORACLE_SID  VARCHAR(100),
			ORACLE_HOME  VARCHAR(100),
			ODBC_DSN  VARCHAR(100),
			SQLSERVER  VARCHAR(100),
			DB2DIR  VARCHAR(100),
			DB2INSTANCE  VARCHAR(100)
			
		END RECORD


	
	DEFINE rec_main 
		RECORD
			lycia_version STRING,
			frontEndName STRING,		
			frontEndVersion STRING, 
			gui_misc_version STRING,
			server_os_name STRING
		END RECORD

	DEFINE rec_general 
		RECORD
			lycia_version STRING,
			frontEndName STRING,	
			frontEndVersion STRING,
			gui_misc_version STRING,
			server_os STRING,
			server_os_name STRING,
			uitype STRING,
			child_process STRING,
			dbpath STRING,
			dbdate STRING,
			dbtime STRING,
			dbmoney STRING,
			db_locale STRING,
			client_locale STRING,
			LYCIA_CONFIG_PATH STRING
		END RECORD


	DEFINE rec_server 
		RECORD
			qx_server_host STRING,
			qx_server_ip STRING,	
			qx_session_id STRING,
			qx_command_id STRING,
			qx_process_id STRING,
			qx_child STRING,
			server_hostname STRING,
			server_ipaddress STRING
		END RECORD


	DEFINE rec_client
		RECORD
			frontEndName STRING,		
			qx_client_host STRING,		
			qx_client_ip STRING,
			gui_systemNetwork_hostname STRING,
			gui_systemNetwork_iPpaddress STRING,
			gui_systemNetwork_sessionid STRING,
			gui_systemNetwork_commandid STRING,
			gui_systemNetwork_processID STRING,
			LD_LIBRARY_PATH STRING  --linux/unix LD lib path
		END RECORD


	DEFINE rec_lycia  --Lycia Environment Variables
		RECORD
			lycia_version STRING,		
			LYCIA_DIR STRING,
			LYCIA_DRIVER_PATH STRING,
			LYCIA_DB_DRIVER STRING,						
			LYCIA_CONFIG STRING,	
			LYCIA_CONV_FORM_MAX_HEIGHT STRING,	
			LYCIA_CONV_FORM_MAX_WIDTH STRING,	
			LYCIA_DB_NAMEMAP STRING,	
			LYCIA_LIC_KEY STRING,	
			LYCIA_MSGPATH STRING,	
			LYCIA_PATH STRING,	
			LYCIA_PER_CONVERT_CHECKBOX STRING,	
			LYCIA_POST_MORTEM_LENGTH STRING,	
			LYCIA_SEVERITY STRING,	
			LYCIA_CONFIG_PATH STRING,
			LYCIA_SYSTEM_ACTION_DEFAULTS  STRING,	
			LYCIA_SYSTEM_RESOURCES STRING,	
			LYCIA_SYSTEM_THEME_CSS STRING,	
			LYCIA_SYSTEM_THEME_QX STRING
		END RECORD


	DEFINE rec_env  --Div. Environment Variables
		RECORD
			LYCIA_DIR STRING,
			MSGPATH STRING,
			LINES STRING,
			COLUMNS STRING,
			LYCIA_DRIVER_PATH STRING,
			FGLPROFILE STRING,
			QXDEBUG STRING,
			QXBREAKCH_START STRING,
			QXBREAKCH_END STRING,
			PATH STRING,
			FGLIMAGEPATH STRING,
			QX_MENU_WINDOW STRING,
			CLASSPATH STRING,
			TEMP STRING,
			TMP STRING,
			QXSS_DB_IS_DSN STRING,
			
			ALLUSERSPROFILE STRING,
			AXIS2C_HOME STRING,
			FGLLDPATH STRING,			
			FGLSWAGGERPATH STRING
		END RECORD


	DEFINE rec_envQx  --Div. Environment Variables
		RECORD
			QXCLIENTADDRESS STRING,
			QXGUIIFD STRING,
			QXGUIOFD STRING,
			QXGUISOCKETFD STRING,
			QXHOST STRING,
			QXINDEXTABLESPACE STRING,
			QXORA_NOOUTER_NULLOP STRING,
			QXPORT STRING,
			QXREP_SPACES STRING,
			QXSSLCERTNAME STRING,
			QXSSLPASS STRING,
			QXSSLPRIVATEKEYNAME STRING,
			QXSSL_TIMEOUT STRING,
			QXSTDTABLESPACE STRING,
			QXTMPTABLESPACE STRING
		END RECORD



	DEFINE rec_envQx_  --Div. Environment Variables
		RECORD
			QX_AOT STRING,
			QX_CHILD STRING,
			QX_CID STRING,
			QX_CLEAR_DYNAMIC_LABEL STRING,
			QX_CLEAR_STATIC_LABEL STRING,
			QX_CLIENT_HOST STRING,
			QX_CLIENT_IP STRING,
			QX_COMPAT STRING,
			QX_DEBUG_HOSTS STRING,
			QX_DUMP_PASSES STRING,
			QX_HEADLESS_CONSOLE STRING,
			QX_HEADLESS_MODE STRING,
			QX_LOGNATIVESQLERRORS STRING,
			QX_LOG_DIR STRING,
			QX_MDI STRING,
			QX_MENU_WINDOW STRING,
			QX_MENU_WINDOW_NEW_CHILD STRING,
			QX_NATIVE_LINKER STRING,
			QX_NO_CLEAN_LINKER_FILES STRING,
			QX_OPT_LEVEL STRING,
			QX_PROCESS_ID STRING,
			QX_QRUN_DUMP STRING,
			QX_QRUN_PORT STRING,
			QX_RESOURCE_UNLOCK STRING,
			QX_REST_VALUE_XML STRING,
			QX_RUN_ARG_PREF STRING,
			QX_SESSION_ID STRING,
			QX_SHOW_WINDOW STRING,
			QX_SIZE_DIMENSION STRING,
			
			QX_SQLSCOPE_ON STRING,
			QX_STARTER_DEBUG_LOGGING STRING,
			QX_STARTER_REDIRECT_STD_OUT STRING,
			QX_UI_MODE_OVERRIDE STRING,
			QX_USE_SIMPLE_CACHE_PATH STRING,
			QX_VERBOSE_CACHE STRING,
			QX_VERIFY_AFTER STRING

		END RECORD
		
	DEFINE rec_c_compiler
		RECORD
			C_INTERFACE_LOCALE STRING,
			FGLC_TRACEGEN STRING,
			FGLC_TRACEPROC STRING,
			FGLC_TRACEPROCERRS STRING,
			FGLC_YYDEBUG STRING,
			VC_DevEnvDir STRING,  --Visual C
			VC_INCLUDE STRING, --Visual C
			VC_LIB STRING, --Visual C
			VC_LIBPATH STRING,	 --Visual C
			VC_VCINSTALLDIR STRING, --Visual C
			VC_VisualStudioVersion STRING --Visual C
						
		END RECORD

	DEFINE rec_os  --Operating System
		RECORD
			username STRING,
			system_username STRING,
			server_os STRING,
			server_os_name STRING,
			JAVA_HOME STRING		
		END RECORD

	DEFINE rec_db  --DB General
		RECORD
			LYCIA_DB_DRIVER STRING,
			DBPATH STRING	
		END RECORD


	DEFINE rec_informix 
		RECORD
			logname STRING,
			informixPass STRING,
			dbPath STRING,
			db_Locale STRING,
			informixServer STRING,
			informixDir STRING,
			informixSqlHosts STRING,
			client_locale STRING,
			qxss_db_is_dsn STRING,
			delimident STRING,
			DBDELIMITER STRING,		
			DBFORMAT STRING,	
			db_name STRING,
			db_name_full STRING,
			db_major_version STRING,
			db_infVersionOS STRING,
			db_os STRING,
			dbhostname STRING,	
			dbname STRING,	
			sessionid STRING,	
			DBCENTURY STRING,
			ONCONFIG STRING						
		END RECORD

DEFINE rec_oracle
    RECORD 
      --Oracle DB
      ORACLE_SID STRING,
      ORACLE_HOME STRING
    END RECORD




DEFINE rec_sqlServer 
    RECORD 
      --SQL-SERVER Microsoft
      ODBC_DSN STRING, 
      SQLSERVER STRING
    END RECORD

DEFINE rec_db2 
    RECORD 
      --SQL-SERVER Microsoft
      DB2DIR STRING, 
      DB2INSTANCE STRING
    END RECORD
    


	DEFINE rec_birt 
		RECORD
			BIRT_LIBDIR STRING
		END RECORD

###########################################################################################################
# FUNCTION retrieveLyciaSystemEnvironment()
#
#
###########################################################################################################
FUNCTION retrieveLyciaSystemEnvironment("F")
  DEFINE inp_char CHAR
	DEFINE temp_string VARCHAR(1000)
	DEFINE db_name CHAR(64)
	
	LET includeAuthenticationInfo = FALSE  --no db password etc.. IS included in the REPORT
	LET reportFileName = "LyciaSystemReport.txt"

	LET informixPassPartHiddenString = hideStringPartial(fgl_getenv("INFORMIXPASS"))

    		
  CALL fgl_window_open("w_about",5,5,"form/4gl_environment",FALSE)  --full SCREEN
	CALL ui.Interface.setText("Sys Info")
	CALL ui.interface.refresh()
##########################
# Need DB connection for DB information

	#IF fgl_getenv("qx_child") THEN
	LET db_name = trim(get_db())  --get the dbName FROM the URL/environment
	#END IF
	


	#IF NUM_ARGS() < 0 THEN
	#	LET db_name = ARG_VAL(1)
	#ELSE
		LET db_name = fgl_winprompt(1,1,"Enter your Database Name",trim(db_name),30,0)
		IF db_name IS NULL THEN
			#EXIT PROGRAM
		ELSE
			CALL connect_db(db_name)			
		END IF

	

    
	############################################################################################
	# Get the different system details, store them (OR later REPORT geneartion) AND display
	############################################################################################


	#Main Area (top panel) -------------------------------------------------------


	LET rec_main.lycia_version = fgl_getversion() 
	DISPLAY rec_main.lycia_version TO main_lycia_version
	
	LET rec_main.frontEndName = ui.Interface.getFrontEndName()
	DISPLAY rec_main.frontEndName TO main_frontEndName

	LET rec_main.frontEndVersion = ui.Interface.getFrontEndVersion()
	DISPLAY rec_main.frontEndVersion TO main_frontEndVersion
	
	LET rec_main.gui_misc_version = fgl_getproperty("gui", "gui.misc.version", "")
	DISPLAY rec_main.gui_misc_version TO main_gui_misc_version
		
	LET rec_main.server_os_name = get_server_os_name(rec_general.server_os)
	DISPLAY rec_main.server_os_name TO main_server_os_name
	
	#General -------------------------------------------
	LET rec_general.lycia_version = fgl_getversion()
	DISPLAY rec_general.lycia_version TO gen_lycia_version 
	 
	LET rec_general.frontEndName = ui.Interface.getFrontEndName()
	DISPLAY rec_main.frontEndName TO gen_frontEndName

	LET rec_general.frontEndVersion = ui.Interface.getFrontEndVersion()
	DISPLAY rec_general.frontEndVersion TO gen_frontEndVersion
	
	LET rec_general.gui_misc_version = fgl_getproperty("gui", "gui.misc.version", "")
	DISPLAY rec_general.gui_misc_version TO gen_gui_misc_version	

	LET rec_general.server_os = fgl_arch()
	DISPLAY rec_general.server_os TO gen_server_os
	
	LET rec_general.server_os_name = get_server_os_name(rec_general.server_os)
	DISPLAY rec_general.server_os_name TO gen_server_os_name
	
	LET rec_general.uiType = fgl_getuitype()
	DISPLAY rec_general.uiType TO gen_uiType

	LET rec_general.child_process = fgl_getenv("qx_child")
	DISPLAY rec_general.child_process TO gen_child_process

	LET rec_general.dbpath = fgl_getenv("DBPATH")
	DISPLAY rec_general.dbpath TO gen_DBPATH

	LET rec_general.dbmoney = fgl_getenv("DBMONEY")
	DISPLAY rec_general.dbmoney TO gen_DBMONEY

	LET rec_general.db_locale= fgl_getenv("DB_LOCALE")
	DISPLAY rec_general.db_locale TO gen_DB_LOCALE

	LET rec_general.dbdate = fgl_getenv("DBDATE")
	DISPLAY rec_general.dbdate TO gen_DBDATE

	LET rec_general.dbtime = fgl_getenv("DBTIME")
	DISPLAY rec_general.dbtime TO gen_DBTIME

	LET rec_general.client_locale = fgl_getenv("CLIENT_LOCALE")
	DISPLAY rec_general.client_locale TO gen_CLIENT_LOCALE

	LET rec_general.LYCIA_CONFIG_PATH = fgl_getenv("LYCIA_CONFIG_PATH")
	DISPLAY rec_general.LYCIA_CONFIG_PATH TO gen_LYCIA_CONFIG_PATH



	#Server--------------------------------------------------------------
	LET rec_server.qx_server_host = fgl_getenv("QX_SERVER_HOST")
	DISPLAY rec_server.qx_server_host TO server_QX_SERVER_HOST
	
	LET rec_server.qx_server_ip = fgl_getenv("QX_SERVER_IP") 
	DISPLAY rec_server.qx_server_ip TO server_QX_SERVER_IP
	
	LET rec_server.qx_session_id = fgl_getenv("QX_SESSION_ID") 
	DISPLAY rec_server.qx_session_id TO server_QX_SESSION_ID
	
	LET rec_server.qx_command_id = fgl_getenv("QX_COMMAND_ID")
	DISPLAY rec_server.qx_command_id TO server_QX_COMMAND_ID
	
	LET rec_server.qx_process_id = fgl_getenv("QX_PROCESS_ID")
	DISPLAY rec_server.qx_process_id TO server_QX_PROCESS_ID
	
	LET rec_server.qx_child = fgl_getenv("QX_CHILD")
	DISPLAY rec_server.qx_child TO server_QX_CHILD
	
	LET rec_server.server_hostname = fgl_getproperty("server", "system.network", "hostname")
	DISPLAY rec_server.server_hostname TO server_SystemNetworkHostname
	
	LET rec_server.server_ipaddress = fgl_getproperty("server", "system.network", "ipaddress")
	DISPLAY rec_server.server_ipaddress TO server_SystemNetworkIpaddress
				
	#Client --------------------------------------------------------------------

	LET rec_client.frontEndName = ui.Interface.getFrontEndName()
	DISPLAY rec_client.frontEndName TO client_frontEndName

	LET rec_client.qx_client_host = fgl_getenv("QX_CLIENT_HOST")
	DISPLAY rec_client.qx_client_host TO client_QX_CLIENT_HOST

	LET rec_client.qx_client_ip = fgl_getenv("QX_CLIENT_IP")
	DISPLAY rec_client.qx_client_ip TO client_QX_CLIENT_IP

	LET rec_client.gui_systemNetwork_hostname = fgl_getproperty("gui", "system.network", "hostname")
	DISPLAY rec_client.gui_systemNetwork_hostname TO client_gui_systemNetwork_hostname

	LET rec_client.gui_systemNetwork_iPpaddress = fgl_getproperty("gui", "system.network", "ipaddress")
	DISPLAY rec_client.gui_systemNetwork_iPpaddress TO client_gui_systemNetwork_iPpaddress

	LET rec_client.gui_systemNetwork_sessionid = fgl_getproperty("gui", "system.network", "sessionid")
	DISPLAY rec_client.gui_systemNetwork_sessionid TO client_gui_systemNetwork_sessionid

	LET rec_client.gui_systemNetwork_commandid = fgl_getproperty("gui", "system.network", "commandid")
	DISPLAY rec_client.gui_systemNetwork_commandid TO client_gui_systemNetwork_commandid

	LET rec_client.gui_systemNetwork_processID = fgl_getproperty("gui", "system.network", "processid")
	DISPLAY rec_client.gui_systemNetwork_processID TO client_gui_systemNetwork_processID

	LET rec_client.LD_LIBRARY_PATH = fgl_getenv("LD_LIBRARY_PATH") --unix only
	DISPLAY rec_client.LD_LIBRARY_PATH TO client_LD_LIBRARY_PATH




	LET rec_lycia.lycia_version = fgl_getversion() 
	DISPLAY rec_lycia.lycia_version TO lyc_lycia_version


	LET rec_lycia.LYCIA_DIR = fgl_getenv("LYCIA_DIR")
	DISPLAY rec_lycia.LYCIA_DIR TO lyc_LYCIA_DIR


	LET rec_lycia.LYCIA_DRIVER_PATH = fgl_getenv("LYCIA_DRIVER_PATH")
	DISPLAY rec_lycia.LYCIA_DRIVER_PATH TO lyc_LYCIA_DRIVER_PATH

	LET rec_lycia.LYCIA_DB_DRIVER = fgl_getenv("LYCIA_DB_DRIVER")
	DISPLAY rec_lycia.LYCIA_DB_DRIVER TO lyc_LYCIA_DB_DRIVER

	LET rec_lycia.LYCIA_CONFIG = fgl_getenv("LYCIA_CONFIG")
	DISPLAY rec_lycia.LYCIA_CONFIG TO lyc_LYCIA_CONFIG

	LET rec_lycia.LYCIA_CONV_FORM_MAX_HEIGHT = fgl_getenv("LYCIA_CONV_FORM_MAX_HEIGHT")
	DISPLAY rec_lycia.LYCIA_CONV_FORM_MAX_HEIGHT TO lyc_LYCIA_CONV_FORM_MAX_HEIGHT

	LET rec_lycia.LYCIA_CONV_FORM_MAX_WIDTH = fgl_getenv("LYCIA_CONV_FORM_MAX_WIDTH")
	DISPLAY rec_lycia.LYCIA_CONV_FORM_MAX_WIDTH TO lyc_LYCIA_CONV_FORM_MAX_WIDTH

	LET rec_lycia.LYCIA_DB_NAMEMAP = fgl_getenv("LYCIA_DB_NAMEMAP")
	DISPLAY rec_lycia.LYCIA_DB_NAMEMAP TO lyc_LYCIA_DB_NAMEMAP

	LET rec_lycia.LYCIA_LIC_KEY = fgl_getenv("LYCIA_LIC_KEY")
	DISPLAY rec_lycia.LYCIA_LIC_KEY TO lyc_LYCIA_LIC_KEY

	LET rec_lycia.LYCIA_MSGPATH = fgl_getenv("LYCIA_MSGPATH")
	DISPLAY rec_lycia.LYCIA_MSGPATH TO lyc_LYCIA_MSGPATH

	LET rec_lycia.LYCIA_PATH = fgl_getenv("LYCIA_PATH")
	DISPLAY rec_lycia.LYCIA_PATH TO lyc_LYCIA_PATH

	LET rec_lycia.LYCIA_PER_CONVERT_CHECKBOX = fgl_getenv("LYCIA_PER_CONVERT_CHECKBOX")
	DISPLAY rec_lycia.LYCIA_PER_CONVERT_CHECKBOX TO lyc_LYCIA_PER_CONVERT_CHECKBOX

	LET rec_lycia.LYCIA_POST_MORTEM_LENGTH = fgl_getenv("LYCIA_POST_MORTEM_LENGTH")
	DISPLAY rec_lycia.LYCIA_POST_MORTEM_LENGTH TO lyc_LYCIA_POST_MORTEM_LENGTH

	LET rec_lycia.LYCIA_SEVERITY = fgl_getenv("LYCIA_SEVERITY")
	DISPLAY rec_lycia.LYCIA_SEVERITY TO lyc_LYCIA_SEVERITY

	LET rec_lycia.LYCIA_CONFIG_PATH = fgl_getenv("LYCIA_CONFIG_PATH")
	DISPLAY rec_lycia.LYCIA_CONFIG_PATH TO lyc_LYCIA_CONFIG_PATH



	LET rec_lycia.LYCIA_SYSTEM_ACTION_DEFAULTS = fgl_getenv("LYCIA_SYSTEM_ACTION_DEFAULTS")
	DISPLAY rec_lycia.LYCIA_SYSTEM_ACTION_DEFAULTS TO lyc_LYCIA_SYSTEM_ACTION_DEFAULTS

	LET rec_lycia.LYCIA_SYSTEM_RESOURCES = fgl_getenv("LYCIA_SYSTEM_RESOURCES")
	DISPLAY rec_lycia.LYCIA_SYSTEM_RESOURCES TO lyc_LYCIA_SYSTEM_RESOURCES

	LET rec_lycia.LYCIA_SYSTEM_THEME_CSS = fgl_getenv("LYCIA_SYSTEM_THEME_CSS")
	DISPLAY rec_lycia.LYCIA_SYSTEM_THEME_CSS TO lyc_LYCIA_SYSTEM_THEME_CSS

	LET rec_lycia.LYCIA_SYSTEM_THEME_QX = fgl_getenv("LYCIA_SYSTEM_THEME_QX")
	DISPLAY rec_lycia.LYCIA_SYSTEM_THEME_QX TO lyc_LYCIA_SYSTEM_THEME_QX

	
	#Environment variables ---------------------------------------------------------------
	LET rec_env.LYCIA_DIR = fgl_getenv("LYCIA_DIR")
	DISPLAY rec_env.LYCIA_DIR TO env_LYCIA_DIR

	LET rec_env.MSGPATH = fgl_getenv("MSGPATH")
	DISPLAY rec_env.MSGPATH TO env_MSGPATH

	LET rec_env.LINES = fgl_getenv("LINES")
	DISPLAY rec_env.LINES TO env_LINES

	LET rec_env.COLUMNS = fgl_getenv("COLUMNS")
	DISPLAY rec_env.COLUMNS TO env_COLUMNS

	LET rec_env.LYCIA_DRIVER_PATH = fgl_getenv("LYCIA_DRIVER_PATH")
	DISPLAY rec_env.LYCIA_DRIVER_PATH TO env_LYCIA_DRIVER_PATH

	LET rec_env.FGLPROFILE = fgl_getenv("FGLPROFILE")
	DISPLAY rec_env.FGLPROFILE TO env_FGLPROFILE

	LET rec_env.QXDEBUG = fgl_getenv("QXDEBUG")
	DISPLAY rec_env.QXDEBUG TO env_QXDEBUG

	LET rec_env.QXBREAKCH_START = fgl_getenv("QXBREAKCH_START")
	DISPLAY rec_env.QXBREAKCH_START TO env_QXBREAKCH_START

	LET rec_env.QXBREAKCH_END = fgl_getenv("QXBREAKCH_END")
	DISPLAY rec_env.QXBREAKCH_END TO env_QXBREAKCH_END

	LET rec_env.PATH = fgl_getenv("PATH")
	DISPLAY rec_env.PATH TO env_PATH

	LET rec_env.FGLIMAGEPATH = fgl_getenv("FGLIMAGEPATH")
	DISPLAY rec_env.FGLIMAGEPATH TO env_FGLIMAGEPATH

	LET rec_env.QX_MENU_WINDOW = fgl_getenv("QX_MENU_WINDOW")
	DISPLAY rec_env.QX_MENU_WINDOW TO env_QX_MENU_WINDOW

	LET rec_env.CLASSPATH = fgl_getenv("CLASSPATH")
	DISPLAY rec_env.CLASSPATH TO env_CLASSPATH

	LET rec_env.TEMP = fgl_getenv("TEMP")
	DISPLAY rec_env.TEMP TO env_TEMP

	LET rec_env.TMP = fgl_getenv("TMP")
	DISPLAY rec_env.TMP TO env_TMP

	LET rec_env.QXSS_DB_IS_DSN = fgl_getenv("QXSS_DB_IS_DSN")
	DISPLAY rec_env.QXSS_DB_IS_DSN TO env_QXSS_DB_IS_DSN	


	LET rec_env.ALLUSERSPROFILE = fgl_getenv("ALLUSERSPROFILE")
	DISPLAY rec_env.ALLUSERSPROFILE TO env_ALLUSERSPROFILE	

	LET rec_env.AXIS2C_HOME = fgl_getenv("AXIS2C_HOME")
	DISPLAY rec_env.AXIS2C_HOME TO env_AXIS2C_HOME	

	LET rec_env.FGLLDPATH = fgl_getenv("FGLLDPATH")
	DISPLAY rec_env.FGLLDPATH TO env_FGLLDPATH

	LET rec_env.FGLSWAGGERPATH = fgl_getenv("FGLSWAGGERPATH")
	DISPLAY rec_env.FGLSWAGGERPATH TO env_FGLSWAGGERPATH


	# QX<name> Environment Variables ----------------------------------------------------------------------

	LET rec_envQx.QXCLIENTADDRESS = fgl_getenv("QXCLIENTADDRESS")
	DISPLAY rec_envQx.QXCLIENTADDRESS TO envqxQXCLIENTADDRESS
	LET rec_envQx.QXGUIIFD = fgl_getenv("QXGUIIFD")
	DISPLAY rec_envQx.QXGUIIFD TO envqxQXGUIIFD
	LET rec_envQx.QXGUIOFD = fgl_getenv("QXGUIOFD")
	DISPLAY rec_envQx.QXGUIOFD TO envqxQXGUIOFD
	LET rec_envQx.QXGUISOCKETFD = fgl_getenv("QXGUISOCKETFD")
	DISPLAY rec_envQx.QXGUISOCKETFD TO envqxQXGUISOCKETFD
	LET rec_envQx.QXHOST = fgl_getenv("QXHOST")
	DISPLAY rec_envQx.QXHOST TO envqxQXHOST
	LET rec_envQx.QXINDEXTABLESPACE = fgl_getenv("QXINDEXTABLESPACE")
	DISPLAY rec_envQx.QXINDEXTABLESPACE TO envqxQXINDEXTABLESPACE
	LET rec_envQx.QXORA_NOOUTER_NULLOP = fgl_getenv("QXORA_NOOUTER_NULLOP")
	DISPLAY rec_envQx.QXORA_NOOUTER_NULLOP TO envqxQXORA_NOOUTER_NULLOP
	LET rec_envQx.QXPORT = fgl_getenv("QXPORT")
	DISPLAY rec_envQx.QXPORT TO envqxQXPORT
	LET rec_envQx.QXREP_SPACES = fgl_getenv("QXREP_SPACES")
	DISPLAY rec_envQx.QXREP_SPACES TO envqxQXREP_SPACES
	LET rec_envQx.QXSSLCERTNAME = fgl_getenv("QXSSLCERTNAME")
	DISPLAY rec_envQx.QXSSLCERTNAME TO envqxQXSSLCERTNAME
	LET rec_envQx.QXSSLPASS = fgl_getenv("QXSSLPASS")
	DISPLAY rec_envQx.QXSSLPASS TO envqxQXSSLPASS
	LET rec_envQx.QXSSLPRIVATEKEYNAME = fgl_getenv("QXSSLPRIVATEKEYNAME")
	DISPLAY rec_envQx.QXSSLPRIVATEKEYNAME TO envqxQXSSLPRIVATEKEYNAME
	LET rec_envQx.QXSSL_TIMEOUT = fgl_getenv("QXSSL_TIMEOUT")
	DISPLAY rec_envQx.QXSSL_TIMEOUT TO envqxQXSSL_TIMEOUT
	LET rec_envQx.QXSTDTABLESPACE = fgl_getenv("QXSTDTABLESPACE")
	DISPLAY rec_envQx.QXSTDTABLESPACE TO envqxQXSTDTABLESPACE
	LET rec_envQx.QXTMPTABLESPACE = fgl_getenv("QXTMPTABLESPACE")
	DISPLAY rec_envQx.QXTMPTABLESPACE TO envqxQXTMPTABLESPACE


	# QX_<name> Environment Variables ----------------------------------------------------------------------

	LET rec_envQx_.QX_AOT = fgl_getenv("QX_AOT")
	DISPLAY rec_envQx_.QX_AOT TO envQx_QX_AOT
	LET rec_envQx_.QX_CHILD = fgl_getenv("QX_CHILD")
	DISPLAY rec_envQx_.QX_CHILD TO envQx_QX_CHILD
	LET rec_envQx_.QX_CID = fgl_getenv("QX_CID")
	DISPLAY rec_envQx_.QX_CID TO envQx_QX_CID
	LET rec_envQx_.QX_CLEAR_DYNAMIC_LABEL = fgl_getenv("QX_CLEAR_DYNAMIC_LABEL")
	DISPLAY rec_envQx_.QX_CLEAR_DYNAMIC_LABEL TO envQx_QX_CLEAR_DYNAMIC_LABEL
	LET rec_envQx_.QX_CLEAR_STATIC_LABEL = fgl_getenv("QX_CLEAR_STATIC_LABEL")
	DISPLAY rec_envQx_.QX_CLEAR_STATIC_LABEL TO envQx_QX_CLEAR_STATIC_LABEL
	LET rec_envQx_.QX_CLIENT_HOST = fgl_getenv("QX_CLIENT_HOST")
	DISPLAY rec_envQx_.QX_CLIENT_HOST TO envQx_QX_CLIENT_HOST
	LET rec_envQx_.QX_CLIENT_IP = fgl_getenv("QX_CLIENT_IP")
	DISPLAY rec_envQx_.QX_CLIENT_IP TO envQx_QX_CLIENT_IP
	LET rec_envQx_.QX_COMPAT = fgl_getenv("QX_COMPAT")
	DISPLAY rec_envQx_.QX_COMPAT TO envQx_QX_COMPAT
	LET rec_envQx_.QX_DEBUG_HOSTS = fgl_getenv("QX_DEBUG_HOSTS")
	DISPLAY rec_envQx_.QX_DEBUG_HOSTS TO envQx_QX_DEBUG_HOSTS
	LET rec_envQx_.QX_DUMP_PASSES = fgl_getenv("QX_DUMP_PASSES")
	DISPLAY rec_envQx_.QX_DUMP_PASSES TO envQx_QX_DUMP_PASSES
	LET rec_envQx_.QX_HEADLESS_CONSOLE = fgl_getenv("QX_HEADLESS_CONSOLE")
	DISPLAY rec_envQx_.QX_HEADLESS_CONSOLE TO envQx_QX_HEADLESS_CONSOLE
	LET rec_envQx_.QX_HEADLESS_MODE = fgl_getenv("QX_HEADLESS_MODE")
	DISPLAY rec_envQx_.QX_HEADLESS_MODE TO envQx_QX_HEADLESS_MODE
	LET rec_envQx_.QX_LOGNATIVESQLERRORS = fgl_getenv("QX_LOGNATIVESQLERRORS")
	DISPLAY rec_envQx_.QX_LOGNATIVESQLERRORS TO envQx_QX_LOGNATIVESQLERRORS
	LET rec_envQx_.QX_LOG_DIR = fgl_getenv("QX_LOG_DIR")
	DISPLAY rec_envQx_.QX_LOG_DIR TO envQx_QX_LOG_DIR
	LET rec_envQx_.QX_MDI = fgl_getenv("QX_MDI")
	DISPLAY rec_envQx_.QX_MDI TO envQx_QX_MDI
	LET rec_envQx_.QX_MENU_WINDOW = fgl_getenv("QX_MENU_WINDOW")
	DISPLAY rec_envQx_.QX_MENU_WINDOW TO envQx_QX_MENU_WINDOW
	LET rec_envQx_.QX_MENU_WINDOW_NEW_CHILD = fgl_getenv("QX_MENU_WINDOW_NEW_CHILD")
	DISPLAY rec_envQx_.QX_MENU_WINDOW_NEW_CHILD TO envQx_QX_MENU_WINDOW_NEW_CHILD
	LET rec_envQx_.QX_NATIVE_LINKER = fgl_getenv("QX_NATIVE_LINKER")
	DISPLAY rec_envQx_.QX_NATIVE_LINKER TO envQx_QX_NATIVE_LINKER
	LET rec_envQx_.QX_NO_CLEAN_LINKER_FILES = fgl_getenv("QX_NO_CLEAN_LINKER_FILES")
	DISPLAY rec_envQx_.QX_NO_CLEAN_LINKER_FILES TO envQx_QX_NO_CLEAN_LINKER_FILES
	LET rec_envQx_.QX_OPT_LEVEL = fgl_getenv("QX_OPT_LEVEL")
	DISPLAY rec_envQx_.QX_OPT_LEVEL TO envQx_QX_OPT_LEVEL
	LET rec_envQx_.QX_PROCESS_ID = fgl_getenv("QX_PROCESS_ID")
	DISPLAY rec_envQx_.QX_PROCESS_ID TO envQx_QX_PROCESS_ID
	LET rec_envQx_.QX_QRUN_DUMP = fgl_getenv("QX_QRUN_DUMP")
	DISPLAY rec_envQx_.QX_QRUN_DUMP TO envQx_QX_QRUN_DUMP
	LET rec_envQx_.QX_QRUN_PORT = fgl_getenv("QX_QRUN_PORT")
	DISPLAY rec_envQx_.QX_QRUN_PORT TO envQx_QX_QRUN_PORT
	LET rec_envQx_.QX_RESOURCE_UNLOCK = fgl_getenv("QX_RESOURCE_UNLOCK")
	DISPLAY rec_envQx_.QX_RESOURCE_UNLOCK TO envQx_QX_RESOURCE_UNLOCK
	LET rec_envQx_.QX_REST_VALUE_XML = fgl_getenv("QX_REST_VALUE_XML")
	DISPLAY rec_envQx_.QX_REST_VALUE_XML TO envQx_QX_REST_VALUE_XML
	LET rec_envQx_.QX_RUN_ARG_PREF = fgl_getenv("QX_RUN_ARG_PREF")
	DISPLAY rec_envQx_.QX_RUN_ARG_PREF TO envQx_QX_RUN_ARG_PREF
	LET rec_envQx_.QX_SESSION_ID = fgl_getenv("QX_SESSION_ID")
	DISPLAY rec_envQx_.QX_SESSION_ID TO envQx_QX_SESSION_ID
	LET rec_envQx_.QX_SHOW_WINDOW = fgl_getenv("QX_SHOW_WINDOW")
	DISPLAY rec_envQx_.QX_SHOW_WINDOW TO envQx_QX_SHOW_WINDOW
	LET rec_envQx_.QX_SIZE_DIMENSION = fgl_getenv("QX_SIZE_DIMENSION")
	DISPLAY rec_envQx_.QX_SIZE_DIMENSION TO envQx_QX_SIZE_DIMENSION
	LET rec_envQx_.QX_SQLSCOPE_ON = fgl_getenv("QX_SQLSCOPE_ON")
	DISPLAY rec_envQx_.QX_SQLSCOPE_ON TO envQx_QX_SQLSCOPE_ON
	LET rec_envQx_.QX_STARTER_DEBUG_LOGGING = fgl_getenv("QX_STARTER_DEBUG_LOGGING")
	DISPLAY rec_envQx_.QX_STARTER_DEBUG_LOGGING TO envQx_QX_STARTER_DEBUG_LOGGING
	LET rec_envQx_.QX_STARTER_REDIRECT_STD_OUT = fgl_getenv("QX_STARTER_REDIRECT_STD_OUT")
	DISPLAY rec_envQx_.QX_STARTER_REDIRECT_STD_OUT TO envQx_QX_STARTER_REDIRECT_STD_OUT
	LET rec_envQx_.QX_UI_MODE_OVERRIDE = fgl_getenv("QX_UI_MODE_OVERRIDE")
	DISPLAY rec_envQx_.QX_UI_MODE_OVERRIDE TO envQx_QX_UI_MODE_OVERRIDE
	LET rec_envQx_.QX_USE_SIMPLE_CACHE_PATH = fgl_getenv("QX_USE_SIMPLE_CACHE_PATH")
	DISPLAY rec_envQx_.QX_USE_SIMPLE_CACHE_PATH TO envQx_QX_USE_SIMPLE_CACHE_PATH
	LET rec_envQx_.QX_VERBOSE_CACHE = fgl_getenv("QX_VERBOSE_CACHE")
	DISPLAY rec_envQx_.QX_VERBOSE_CACHE TO envQx_QX_VERBOSE_CACHE
	LET rec_envQx_.QX_VERIFY_AFTER = fgl_getenv("QX_VERIFY_AFTER")
	DISPLAY rec_envQx_.QX_VERIFY_AFTER TO envQx_QX_VERIFY_AFTER


	# C-Compiler/Sources ----------------------------------------------------------------------
	LET rec_c_compiler.C_INTERFACE_LOCALE = fgl_getenv("C_INTERFACE_LOCALE")
	DISPLAY rec_c_compiler.C_INTERFACE_LOCALE TO c_C_INTERFACE_LOCALE

	LET rec_c_compiler.FGLC_TRACEGEN = fgl_getenv("FGLC_TRACEGEN")
	DISPLAY rec_c_compiler.FGLC_TRACEGEN TO c_FGLC_TRACEGEN

	LET rec_c_compiler.FGLC_TRACEPROC = fgl_getenv("FGLC_TRACEPROC")
	DISPLAY rec_c_compiler.FGLC_TRACEPROC TO c_FGLC_TRACEPROC

	LET rec_c_compiler.FGLC_TRACEPROCERRS = fgl_getenv("FGLC_TRACEPROCERRS")
	DISPLAY rec_c_compiler.FGLC_TRACEPROCERRS TO c_FGLC_TRACEPROCERRS

	LET rec_c_compiler.FGLC_YYDEBUG = fgl_getenv("FGLC_YYDEBUG")
	DISPLAY rec_c_compiler.FGLC_YYDEBUG TO c_FGLC_YYDEBUG

	LET rec_c_compiler.VC_DevEnvDir = fgl_getenv("DevEnvDir")
	DISPLAY rec_c_compiler.VC_DevEnvDir TO c_VC_DevEnvDir

	LET rec_c_compiler.VC_INCLUDE = fgl_getenv("INCLUDE")
	DISPLAY rec_c_compiler.VC_INCLUDE TO c_VC_INCLUDE

	LET rec_c_compiler.VC_LIB = fgl_getenv("LIB")
	DISPLAY rec_c_compiler.VC_LIB TO c_VC_LIB

	LET rec_c_compiler.VC_LIBPATH = fgl_getenv("LIBPATH")
	DISPLAY rec_c_compiler.VC_LIBPATH TO c_VC_LIBPATH

	LET rec_c_compiler.VC_VCINSTALLDIR = fgl_getenv("VCINSTALLDIR")
	DISPLAY rec_c_compiler.VC_VCINSTALLDIR TO c_VC_VCINSTALLDIR

	LET rec_c_compiler.VC_VisualStudioVersion = fgl_getenv("VisualStudioVersion")
	DISPLAY rec_c_compiler.VC_VisualStudioVersion TO c_VC_VisualStudioVersion



	# OS ----------------------------------------------------------------------
	LET rec_os.username = fgl_username()
	DISPLAY rec_os.username TO os_username	
	
	LET rec_os.system_username = fgl_getproperty("system","username")
	DISPLAY rec_os.system_username TO os_system_username	

	LET rec_os.server_os = fgl_arch()
	DISPLAY rec_os.server_os TO os_server_os
	
	LET rec_os.server_os_name = get_server_os_name(rec_general.server_os)
	DISPLAY rec_os.server_os_name TO os_server_os_name
	
	LET rec_os.JAVA_HOME = fgl_getenv("JAVA_HOME")
	DISPLAY rec_os.JAVA_HOME TO os_JAVA_HOME
	
	#DB-General  ----------------------------------------------------------------------
	LET rec_db.LYCIA_DB_DRIVER = fgl_getenv("LYCIA_DB_DRIVER")
	DISPLAY rec_db.LYCIA_DB_DRIVER TO envdb_LYCIA_DB_DRIVER

	LET rec_db.DBPATH = fgl_getenv("DBPATH")
	DISPLAY rec_db.DBPATH TO envdb_DBPATH		




	########################################################################################
	#Informix related env variables

	#sensitive information	
	LET rec_informix.logname = fgl_getenv("LOGNAME")
	IF includeAuthenticationInfo THEN
		LET rec_informix.informixPass = fgl_getenv("INFORMIXPASS")  --show real password !!! security)
	ELSE 
		LET rec_informix.informixPass = informixPassPartHiddenString  --show decripted password
	END IF 
	#--------

	LET rec_informix.dbPath = fgl_getenv("DBPATH") 
	LET rec_informix.db_Locale = fgl_getenv("DB_LOCALE") 
	LET rec_informix.informixServer = fgl_getenv("INFORMIXSERVER") 
	LET rec_informix.informixDir = fgl_getenv("INFORMIXDIR") 
	LET rec_informix.informixSqlHosts = fgl_getenv("INFORMIXSQLHOSTS") 
	LET rec_informix.client_locale = fgl_getenv("CLIENT_LOCALE") 
	LET rec_informix.qxss_db_is_dsn = fgl_getenv("QXSS_DB_IS_DSN") 
	LET rec_informix.delimident = fgl_getenv("DELIMIDENT") 
	LET rec_informix.DBDELIMITER = fgl_getenv("DBDELIMITER") 
	LET rec_informix.DBCENTURY = fgl_getenv("DBCENTURY") 
	LET rec_informix.DBFORMAT = fgl_getenv("DBFORMAT") 
	LET rec_informix.ONCONFIG = fgl_getenv("ONCONFIG") 



	SQL
		SELECT FIRST 1  DBINFO('version', 'major')    FROM systables    INTO $temp_string WHERE tabid = 1;
	END SQL
	LET rec_informix.db_name = temp_string	


	SQL
		SELECT FIRST 1 DBINFO("version", "full") 
			INTO $temp_string 
			FROM systables;
	END SQL
	LET rec_informix.db_name_full = temp_string	

	SQL
		SELECT FIRST 1 DBINFO("version", "major") 
			INTO $temp_string 
			FROM systables;
	END SQL
	LET rec_informix.db_major_version = temp_string	

	SQL
		SELECT FIRST 1 DBINFO("version", "os") 
			INTO $temp_string 
			FROM systables;
	END SQL
	LET rec_informix.db_infVersionOS = temp_string		

	SQL
		SELECT DBINFO('dbhostname') 	
			INTO $temp_string 
			FROM systables
			WHERE tabid = 1;
	END SQL
	LET rec_informix.dbhostname = temp_string		

	SQL
		SELECT DBINFO('dbname') 
			INTO $temp_string 
			FROM systables
			WHERE tabid = 1;
	END SQL
	LET rec_informix.dbname = temp_string		
	
	SQL   
		SELECT DBINFO('sessionid') AS my_sessionid
			INTO $temp_string 
			FROM systables
			WHERE tabname = 'systables';
	END SQL   
	LET rec_informix.sessionid = temp_string		      



	
	DISPLAY rec_informix.logname TO inf_LogName
	DISPLAY rec_informix.informixPass TO inf_InformixPass
	DISPLAY rec_informix.dbPath TO inf_DbPath
	DISPLAY rec_informix.db_Locale TO inf_Db_Locale
	DISPLAY rec_informix.informixServer TO inf_InformixServer
	DISPLAY rec_informix.informixDir TO inf_InformixDir
	DISPLAY rec_informix.informixSqlHosts TO inf_InformixSqlHosts
	DISPLAY rec_informix.client_locale TO inf_Client_Locale
	DISPLAY rec_informix.qxss_db_is_dsn TO inf_Qxss_Db_Is_Dsn
	DISPLAY rec_informix.delimident TO inf_Delimident
	DISPLAY rec_informix.DBDELIMITER TO inf_DBDELIMITER
	
	DISPLAY rec_informix.DBCENTURY TO inf_DBCENTURY
	DISPLAY rec_informix.DBFORMAT TO inf_DBFORMAT

	
	DISPLAY rec_informix.db_name TO inf_VersionServerType
	DISPLAY rec_informix.db_name_full TO inf_VersionFull
	DISPLAY rec_informix.db_major_version TO inf_VersionMajor		
	DISPLAY rec_informix.db_infVersionOS TO inf_VersionOS		
	DISPLAY rec_informix.dbhostname TO inf_DbHostName	
	DISPLAY rec_informix.dbname TO inf_DbName	
	DISPLAY rec_informix.sessionid TO inf_SessionId	
	DISPLAY rec_informix.ONCONFIG TO inf_ONCONFIG
	



	###############################################################################
	
	#Oracle
	LET rec_oracle.ORACLE_SID = fgl_getenv("ORACLE_SID")
	DISPLAY rec_oracle.ORACLE_SID TO oracle_ORACLE_SID
	LET rec_oracle.ORACLE_HOME = fgl_getenv("ORACLE_HOME")
	DISPLAY rec_oracle.ORACLE_HOME TO oracle_ORACLE_HOME



	# SQL Server ##########################  
	LET rec_sqlServer.ODBC_DSN = fgl_getenv("ODBC_DSN")
	DISPLAY rec_sqlServer.ODBC_DSN TO sqlServer_ODBC_DSN
	
	LET rec_sqlServer.SQLSERVER = fgl_getenv("SQLSERVER")
	DISPLAY rec_sqlServer.SQLSERVER TO sqlServer_SQLSERVER
	
	

	

	# DB2 ##########################    
	LET rec_db2.DB2DIR = fgl_getenv("DB2DIR")
	DISPLAY rec_db2.DB2DIR TO db2_DB2DIR
	LET rec_db2.DB2INSTANCE = fgl_getenv("DB2INSTANCE")
	DISPLAY rec_db2.DB2INSTANCE TO db2_DB2INSTANCE


	#BIRT -----------------------------------------------------------
	LET rec_birt.BIRT_LIBDIR = fgl_getenv("BIRT_LIBDIR")
	DISPLAY rec_birt.BIRT_LIBDIR TO birt_BIRT_LIBDIR


# END OF Retrieving the System Information
################################################################################

  MENU
  	BEFORE MENU
  		CALL dialog.setActionHidden("CANCEL",TRUE)
  		CALL dialog.setActionHidden("ACCEPT",TRUE)  	

	ON ACTION "Report"
	OPEN WINDOW wSubmission WITH FORM "form/4gl_questionaire"
		LET rec_customer.customerIncludeEnvironmentVariables = TRUE
		LET rec_customer.customerIncludeSystemReport = TRUE
		LET rec_customer.customerIncludeRegistryInformation = TRUE
		LET rec_customer.customerRunFromLocation = 1
		LET rec_customer.customerCss = FALSE
		LET rec_customer.customerQxTheme = FALSE

		LET rec_customer.customerJavaScript = FALSE
		LET rec_customer.customerVDOM = FALSE
		LET rec_customer.customerCSources = FALSE
		LET rec_customer.customerJavaSources = FALSE

		
		INPUT BY NAME rec_customer.* WITHOUT DEFAULTS

		#MESSAGE "This will take about 30 seconds depending on your system"
		CLOSE WINDOW wSubmission
		CALL writeLyciaReportFile()

				#START REPORT lycia_system_report TO PIPE "more > REPORT.out"
				#	   OUTPUT TO REPORT lycia_system_report("donated by Hubert")
		   	#	FINISH REPORT lycia_system_report			


      
    ON ACTION "getSystemInfo"
    	CALL getSystemInfo()

    ON ACTION "getRegistryInfo"
      	CASE fgl_arch()
    		WHEN "nt"
    			RUN "system/win_reg_query.bat"
    		WHEN "lnx"
    			CALL os.Path.chrwx("lnx_reg_query.sh", "508") # chmod 774 lnx_reg_query.sh
    			RUN "system/lnx_reg_query.sh"
    	END CASE
    	
      	LOCATE regInfo IN FILE "regrep.txt"
      	DISPLAY regInfo TO SystemInfo

    	
    ON ACTION "HELP"
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
  DEFINE 
    db_type_info VARCHAR(100),
    ret_str VARCHAR(120),
    db_type CHAR(3)

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
  LET ret_str = db_type CLIPPED, " = ", db_type_info
  RETURN ret_str
ENd FUNCTION


##############################################################
# FUNCTION prog_arguments()
##############################################################
FUNCTION prog_arguments()
  DEFINE PROG_CHILD VARCHAR(200), i, sl INT

  FOR i = 0 TO NUM_ARGS()
    LET PROG_CHILD = trim(PROG_CHILD) , trim(ARG_VAL(i)) , " /"
  END FOR  

  LET sl = length(PROG_CHILD)
  LET PROG_CHILD[sl] = ""  --overwrite the final slash at the ending

  RETURN PROG_CHILD

ENd FUNCTION


##############################################################
# FUNCTION writeLyciaReportFile()
#
#
##############################################################
FUNCTION writeLyciaReportFile()
  #DEFINE SystemInfo TEXT
	DEFINE cmdRunString STRING
	DEFINE temp_string STRING

	
  CASE fgl_arch()
    WHEN "nt"


--			LET cmdRunString = "type REPORT.out > ", reportFileName 
--    	RUN cmdRunString

--			#Get Windows Registry information
--    	RUN "system/win_reg_query.bat"

--			LET cmdRunString = "type regrep.txt >> ", reportFileName 
--    	RUN cmdRunString
    	

--		  #systeminfo.txt 		     
--    	RUN "system/systeminfo > systeminfo.txt"

--			LET cmdRunString = "type systeminfo.txt >> ", reportFileName 
--    	RUN cmdRunString



		IF rec_customer.customerIncludeRegistryInformation THEN
			#Get Windows Registry information
			MESSAGE "Generating Windows Registry Report"
    		RUN "system/win_reg_query.bat"
    	END IF

		IF rec_customer.customerIncludeSystemReport THEN
			#systeminfo.txt 		     
			MESSAGE "Generating OS SystemInfo Report (takes ~30 seconds)"
	    	RUN "system/systeminfo > systeminfo.txt"
		END IF

    	
    	#Create REPORT on environment variables etc.. AND include the registry AND systeminfo files
		START REPORT lycia_system_report TO reportFileName  #PIPE "more > REPORT.out"
			OUTPUT TO REPORT lycia_system_report("donated by Hubert")
		FINISH REPORT lycia_system_report		

    	LOCATE reportFile IN FILE reportFileName
      	DISPLAY reportFile TO SystemInfo
    	
    WHEN "lnx"
    
    	IF rec_customer.customerIncludeRegistryInformation THEN
			#Get Windows Registry information
			MESSAGE "Generating Linux Environment Report"
			CALL os.Path.chrwx("lnx_reg_query.sh", "508") # chmod 774 lnx_reg_query.sh
    		RUN "lnx_reg_query.sh"
    	END IF

		IF rec_customer.customerIncludeSystemReport THEN
			#systeminfo.txt 		     
			MESSAGE "Generating OS SystemInfo Report"
        	CALL os.Path.chrwx("systeminfo.sh", "508") # chmod 774 systeminfo.sh
    		RUN "systeminfo.sh"
		END IF
    	
    	#Create REPORT on environment variables etc.. AND include the registry AND systeminfo files
		START REPORT lycia_system_report TO reportFileName  #PIPE "more > REPORT.out"
			OUTPUT TO REPORT lycia_system_report("donated by Hubert")
		FINISH REPORT lycia_system_report		

    	LOCATE reportFile IN FILE reportFileName
      	DISPLAY reportFile TO SystemInfo
    	
    OTHERWISE
    	LET cmdRunString = "cat REPORT.out >", reportFileName 
    	RUN cmdRunString
    	
	    RUN "cat /proc/meminfo >systeminfo.txt"
	    RUN "cat /proc/cpuinfo >>systeminfo.txt"

    	LET cmdRunString = "cat systeminfo.txt >>", reportFileName 
    	RUN cmdRunString
	    
	END CASE
    
	LOCATE reportFile IN FILE reportFileName
	DISPLAY reportFile TO SystemInfo

	#Download the REPORT file
	IF fgl_download(reportFileName, reportFileName) = FALSE THEN
		LET temp_string = "Could NOT download ", fgl_getenv("HOMEPATH") CLIPPED, reportFileName CLIPPED
		CALL fgl_winmessage("Error when downloading the REPORT file",temp_string,"error")
	ELSE
		LET temp_string = "Downloaded the REPORT file ", fgl_getenv("HOMEPATH") CLIPPED, reportFileName CLIPPED
		CALL fgl_winmessage("Report File Download",temp_string,"info")
	END IF	


END FUNCTION

########################################################
# FUNCTION getDBTypeName(pDB_type)
########################################################
FUNCTION getDBTypeName(pDB_type)
	DEFINE pDB_type VARCHAR(5)
	
  CASE pDB_type
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
FUNCTION getSystemInfo()

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

    LOCATE SystemInfo IN FILE "systeminfo.txt"
    
    DISPLAY BY NAME SystemInfo
     
END FUNCTION


###################################################
FUNCTION get_server_os_name(pServerOS)
	DEFINE pServerOS STRING
	DEFINE retServerOSName STRING

  CASE fgl_arch()

    WHEN "nt"
      LET retServerOSName = "nt  = Windows" 

    WHEN "lnx"
      LET retServerOSName = "lnx = Linux" 

    WHEN "sun"
      LET retServerOSName = "sun = 32-bit Sun Solaris" 

    WHEN "s64"
      LET retServerOSName = "s64 = 64-bit Sun Solaris"  

    WHEN "hp"
      LET retServerOSName = "hp  = 32-bit HP-UX PA-RISC"  

    WHEN "h64"
      LET retServerOSName = "h64  = 64-bit HP-UX PA-RISC" 

    WHEN "i32"
      LET retServerOSName = "i32  = 32-bit HP-UX Itanium"  

    WHEN "i64"
      LET retServerOSName = "i64  = 64-bit HP-UX Itanium"

    WHEN "dec"
      LET retServerOSName = "dec  = Compaq Tru64" 

    WHEN "s86"
      LET retServerOSName = "s86  = Sun Solaris x86" 

    WHEN "aix"
      LET retServerOSName = "aix  = IBM AIX 4.31"  

    WHEN "a64"
      LET retServerOSName = "a64  = IBM AIX 5L" 
    WHEN "ncr"
      LET retServerOSName = "ncr  = NCR MP-RAS"  

  END CASE

	RETURN retServerOSName
  
  END FUNCTION


      
######################################################
#REPORT lycia_system_report()  
######################################################
REPORT lycia_system_report(dummy) 
DEFINE dummy varchar(100) 

  OUTPUT
    BOTTOM MARGIN 1
    TOP MARGIN 1
    PAGE LENGTH 64
    RIGHT MARGIN 132

  FORMAT
    #  ON EVERY ROW 
   #      PRINT dummy         



    FIRST PAGE HEADER
      SKIP 1 LINES
      PRINT COLUMN 1, "Lycia System Environment Report"
      SKIP 1 LINES
      PRINT COLUMN 1, "Executing date: ", TODAY USING "dd mmm. yyyy" -- "Executing date: "
      PRINT COLUMN 1, "Executing time: ", TIME -- "Executing date: "
     ON EVERY ROW 

			SKIP 3 LINES    
			PRINT "##################################################################################"        
			PRINT "#                                                                                #"			
      PRINT "# Customer/User Details                                                          #"
			PRINT "#                                                                                #"			
      PRINT "##################################################################################"        
      SKIP 3 LINES

      PRINT COLUMN 1,  "Customer Name:",
            COLUMN 25, rec_customer.customerName
      PRINT COLUMN 1,  "E-Mail Address:",
            COLUMN 25, rec_customer.customerEmailAddress
      PRINT COLUMN 1,  "Company:",
            COLUMN 25, rec_customer.customerCompany
      PRINT COLUMN 1,  "Browser Details:",      
            COLUMN 25, rec_customer.customerBrowser

      PRINT COLUMN 1,  "Tool launch location:",      
            COLUMN 25, trim(rec_customer.customerRunFromLocation),
            COLUMN 40, "1=LyciaStudio, 2=Dev Browser,3=Remote Browser"
            
            
      PRINT COLUMN 1,  "App uses custom CSS:",      
            COLUMN 25, trim(rec_customer.customerCss)
      PRINT COLUMN 1,  "App uses custom QxTheme:",      
            COLUMN 25, trim(rec_customer.customerQxTheme)
            
            
      PRINT COLUMN 1,  "App uses Cl. JavaScript:",      
            COLUMN 25, rec_customer.customerJavaScript
      PRINT COLUMN 1,  "Using VDOM:",      
            COLUMN 25, trim(rec_customer.customerVDOM)
      PRINT COLUMN 1,  "App uses custom QxTheme:",      
            COLUMN 25, rec_customer.customerCSources
      PRINT COLUMN 1,  "App uses custom QxTheme:",      
            COLUMN 25, rec_customer.customerJavaSources
            

            
      PRINT COLUMN 1,  "Incl. Environment:",
            COLUMN 25, rec_customer.customerIncludeEnvironmentVariables
      PRINT COLUMN 1,  "Incl. SystemReport:",
            COLUMN 25, rec_customer.customerIncludeSystemReport
      PRINT COLUMN 1,  "Incl. Registry:",
            COLUMN 25, rec_customer.customerIncludeRegistryInformation
      PRINT COLUMN 1,  "Customer Message:",
            COLUMN 25, rec_customer.customerMessage WORDWRAP
            


			SKIP 3 LINES    
			PRINT "##################################################################################"        
			PRINT "#                                                                                #"			
      PRINT "# Lycia Environment AND internal properties                                      #"
			PRINT "#                                                                                #"			
      PRINT "##################################################################################"        
      SKIP 3 LINES

      PRINT COLUMN 1,  "Lycia Version:",
            COLUMN 25, rec_main.lycia_version
      PRINT COLUMN 1,  "Client Type:",
            COLUMN 25, rec_main.frontEndName
      PRINT COLUMN 1,  "Client Version:",
            COLUMN 25, rec_main.frontEndVersion
      PRINT COLUMN 1,  "GUI Misc. Version:",
            COLUMN 25, rec_main.gui_misc_version
      PRINT COLUMN 1,  "App Server OS:",
            COLUMN 25, rec_main.server_os_name

			SKIP 1 LINES
      PRINT "----- General --------------------------------------------------------------------"
      SKIP 1 LINES
      PRINT COLUMN 1,  "Lycia Version:",
            COLUMN 25, rec_general.lycia_version
      PRINT COLUMN 1,  "Client Type:",
            COLUMN 25, rec_general.frontEndName
      PRINT COLUMN 1,  "Client Version:",
            COLUMN 25, rec_general.frontEndVersion
      PRINT COLUMN 1,  "GUI Misc. Version:",
            COLUMN 25, rec_general.gui_misc_version
      PRINT COLUMN 1,  "App-Server OS :",
            COLUMN 25, rec_general.server_os
      PRINT COLUMN 1,  "App-Server OS Name:",
            COLUMN 25, rec_general.server_os_name
      PRINT COLUMN 1,  "UI Type:",
            COLUMN 25, rec_general.uitype
      PRINT COLUMN 1,  "Child process:",
            COLUMN 25, rec_general.child_process
      PRINT COLUMN 1,  "DBPATH:",
            COLUMN 25, rec_general.dbpath
      PRINT COLUMN 1,  "DBDATE:",
            COLUMN 25, rec_general.dbdate
      PRINT COLUMN 1,  "DBTIME:",
            COLUMN 25, rec_general.dbtime           
      PRINT COLUMN 1,  "DBMONEY:",
            COLUMN 25, rec_general.dbmoney
      PRINT COLUMN 1,  "DB_LOCALE:",
            COLUMN 25, rec_general.db_locale
      PRINT COLUMN 1,  "CLIENT_LOCALE:",
            COLUMN 25, rec_general.client_locale

			SKIP 1 LINES
      PRINT "----- Server ---------------------------------------------------------------------"
      SKIP 1 LINES
      PRINT COLUMN 1,  "Host Name:",
            COLUMN 25, rec_server.qx_server_host
      PRINT COLUMN 1,  "IP-Address:",
            COLUMN 25, rec_server.qx_server_ip
      PRINT COLUMN 1,  "Session ID:",
            COLUMN 25, rec_server.qx_session_id
      PRINT COLUMN 1,  "Command ID:",
            COLUMN 25, rec_server.qx_command_id
      PRINT COLUMN 1,  "Process ID:",
            COLUMN 25, rec_server.qx_process_id
      PRINT COLUMN 1,  "QX_CHILD:",
            COLUMN 25, rec_server.qx_child
      PRINT COLUMN 1,  "Host Name:",
            COLUMN 25, rec_server.server_hostname
      PRINT COLUMN 1,  "IP-Address:",
            COLUMN 25, rec_server.server_ipaddress

			SKIP 1 LINES
      PRINT "----- Client ---------------------------------------------------------------------"
      SKIP 1 LINES
      PRINT COLUMN 1,  "Client Type:",
            COLUMN 25, rec_client.frontEndName
      PRINT COLUMN 1,  "Host Name:",
            COLUMN 25, rec_client.qx_client_host
      PRINT COLUMN 1,  "IP-Address:",
            COLUMN 25, rec_client.qx_client_ip
      PRINT COLUMN 1,  "Host Name:",
            COLUMN 25, rec_client.gui_systemNetwork_hostname
      PRINT COLUMN 1,  "IP-Address:",
            COLUMN 25, rec_client.gui_systemNetwork_iPpaddress
      PRINT COLUMN 1,  "Session ID:",
            COLUMN 25, rec_client.gui_systemNetwork_sessionid
      PRINT COLUMN 1,  "Command ID:",
            COLUMN 25, rec_client.gui_systemNetwork_commandid
      PRINT COLUMN 1,  "Process Id:",
            COLUMN 25, rec_client.gui_systemNetwork_processID
      PRINT COLUMN 1,  "LD_LIBRARY_PATH:",
            COLUMN 25, rec_client.LD_LIBRARY_PATH




			SKIP 1 LINES
      PRINT "----- Lycia Environment ----------------------------------------------------------------"
      SKIP 1 LINES
      PRINT COLUMN 1,  "Lycia Version:",
            COLUMN 25, rec_lycia.lycia_version
      PRINT COLUMN 1,  "LYCIA_DIR:",
            COLUMN 25, rec_lycia.LYCIA_DIR
      PRINT COLUMN 1,  "LYCIA_DRIVER_PATH:",
            COLUMN 25, rec_lycia.LYCIA_DRIVER_PATH
      PRINT COLUMN 1,  "LYCIA_DB_DRIVER:",
            COLUMN 25, rec_lycia.LYCIA_DB_DRIVER
      PRINT COLUMN 1,  "LYCIA_CONFIG:",
            COLUMN 25, rec_lycia.LYCIA_CONFIG
      PRINT COLUMN 1,  "LYCIA_CONFIG_PATH:",
            COLUMN 25, rec_lycia.LYCIA_CONFIG_PATH
      PRINT COLUMN 1,  "LYCIA_CONV_FORM_MAX_HEIGHT:",
            COLUMN 25, rec_lycia.LYCIA_CONV_FORM_MAX_HEIGHT
      PRINT COLUMN 1,  "LYCIA_CONV_FORM_MAX_WIDTH:",
            COLUMN 25, rec_lycia.LYCIA_CONV_FORM_MAX_WIDTH
      PRINT COLUMN 1,  "LYCIA_DB_NAMEMAP:",
            COLUMN 25, rec_lycia.LYCIA_DB_NAMEMAP
      PRINT COLUMN 1,  "LYCIA_LIC_KEY:",
            COLUMN 25, rec_lycia.LYCIA_LIC_KEY
      PRINT COLUMN 1,  "LYCIA_MSGPATH:",
            COLUMN 25, rec_lycia.LYCIA_MSGPATH
      PRINT COLUMN 1,  "LYCIA_PATH:",
            COLUMN 25, rec_lycia.LYCIA_PATH
      PRINT COLUMN 1,  "LYCIA_PER_CONVERT_CHECKBOX:",
            COLUMN 25, rec_lycia.LYCIA_PER_CONVERT_CHECKBOX
      PRINT COLUMN 1,  "LYCIA_POST_MORTEM_LENGTH:",
            COLUMN 25, rec_lycia.LYCIA_POST_MORTEM_LENGTH
      PRINT COLUMN 1,  "LYCIA_SEVERITY:",
            COLUMN 25, rec_lycia.LYCIA_SEVERITY
      PRINT COLUMN 1,  "LYCIA_SYSTEM_ACTION_DEFAULTS:",
            COLUMN 25, rec_lycia.LYCIA_SYSTEM_ACTION_DEFAULTS
      PRINT COLUMN 1,  "LYCIA_SYSTEM_RESOURCES:",
            COLUMN 25, rec_lycia.LYCIA_SYSTEM_RESOURCES
      PRINT COLUMN 1,  "LYCIA_SYSTEM_THEME_CSS:",
            COLUMN 25, rec_lycia.LYCIA_SYSTEM_THEME_CSS
      PRINT COLUMN 1,  "LYCIA_SYSTEM_THEME_QX:",
            COLUMN 25, rec_lycia.LYCIA_SYSTEM_THEME_QX

			SKIP 1 LINES
      PRINT "----- Environment ----------------------------------------------------------------"
      SKIP 1 LINES
      PRINT COLUMN 1,  "LYCIA_DIR:",
            COLUMN 25, rec_env.LYCIA_DIR
      PRINT COLUMN 1,  "MSGPATH:",
            COLUMN 25, rec_env.MSGPATH
      PRINT COLUMN 1,  "LINES:",
            COLUMN 25, rec_env.LINES
      PRINT COLUMN 1,  "COLUMNS:",
            COLUMN 25, rec_env.COLUMNS
      PRINT COLUMN 1,  "LYCIA_DRIVER_PATH:",
            COLUMN 25, rec_env.LYCIA_DRIVER_PATH
      PRINT COLUMN 1,  "FGLPROFILE:",
            COLUMN 25, rec_env.FGLPROFILE
      PRINT COLUMN 1,  "QXDEBUG:",
            COLUMN 25, rec_env.QXDEBUG
      PRINT COLUMN 1,  "QXBREAKCH_START:",
            COLUMN 25, rec_env.QXBREAKCH_START
      PRINT COLUMN 1,  "QXBREAKCH_END:",
            COLUMN 25, rec_env.QXBREAKCH_END
      PRINT COLUMN 1,  "PATH:",
            COLUMN 25, rec_env.PATH WORDWRAP
      PRINT COLUMN 1,  "FGLIMAGEPATH:",
            COLUMN 25, rec_env.FGLIMAGEPATH
      PRINT COLUMN 1,  "QX_MENU_WINDOW:",
            COLUMN 25, rec_env.QX_MENU_WINDOW
      PRINT COLUMN 1,  "CLASSPATH:",
            COLUMN 25, rec_env.CLASSPATH
      PRINT COLUMN 1,  "TEMP:",
            COLUMN 25, rec_env.TEMP
      PRINT COLUMN 1,  "TMP:",
            COLUMN 25, rec_env.TMP
      PRINT COLUMN 1,  "QXSS_DB_IS_DSN:",
            COLUMN 25, rec_env.QXSS_DB_IS_DSN

      PRINT COLUMN 1,  "ALLUSERSPROFILE:",
            COLUMN 25, rec_env.ALLUSERSPROFILE
      PRINT COLUMN 1,  "AXIS2C_HOME:",
            COLUMN 25, rec_env.AXIS2C_HOME
      PRINT COLUMN 1,  "FGLLDPATH:",
            COLUMN 25, rec_env.FGLLDPATH


			SKIP 1 LINES
      PRINT "----- QX<name< Environment Variables------------------------------------------"
      SKIP 1 LINES
      PRINT COLUMN 1,  "QXCLIENTADDRESS:",
            COLUMN 25, rec_envQx.QXCLIENTADDRESS
      PRINT COLUMN 1,  "QXGUIIFD:",
            COLUMN 25, rec_envQx.QXGUIIFD
      PRINT COLUMN 1,  "QXGUIOFD:",
            COLUMN 25, rec_envQx.QXGUIOFD
      PRINT COLUMN 1,  "QXGUISOCKETFD:",
            COLUMN 25, rec_envQx.QXGUISOCKETFD
      PRINT COLUMN 1,  "QXHOST:",
            COLUMN 25, rec_envQx.QXHOST
      PRINT COLUMN 1,  "QXINDEXTABLESPACE:",
            COLUMN 25, rec_envQx.QXINDEXTABLESPACE
      PRINT COLUMN 1,  "QXORA_NOOUTER_NULLOP:",
            COLUMN 25, rec_envQx.QXORA_NOOUTER_NULLOP
      PRINT COLUMN 1,  "QXPORT:",
            COLUMN 25, rec_envQx.QXPORT
      PRINT COLUMN 1,  "QXREP_SPACES:",
            COLUMN 25, rec_envQx.QXREP_SPACES
      PRINT COLUMN 1,  "QXSSLCERTNAME:",
            COLUMN 25, rec_envQx.QXSSLCERTNAME
      PRINT COLUMN 1,  "QXSSLPASS:",
            COLUMN 25, rec_envQx.QXSSLPASS
      PRINT COLUMN 1,  "QXSSLPRIVATEKEYNAME:",
            COLUMN 25, rec_envQx.QXSSLPRIVATEKEYNAME
      PRINT COLUMN 1,  "QXSSL_TIMEOUT:",
            COLUMN 25, rec_envQx.QXSSL_TIMEOUT
      PRINT COLUMN 1,  "QXSTDTABLESPACE:",
            COLUMN 25, rec_envQx.QXSTDTABLESPACE
      PRINT COLUMN 1,  "QXTMPTABLESPACE:",
            COLUMN 25, rec_envQx.QXTMPTABLESPACE



			SKIP 1 LINES
      PRINT "----- QX_<name< Environment Variables------------------------------------------"
      SKIP 1 LINES
      PRINT COLUMN 1,  "QX_AOT:",
            COLUMN 25, rec_envQx_.QX_AOT
      PRINT COLUMN 1,  "QX_CHILD:",
            COLUMN 25, rec_envQx_.QX_CHILD
      PRINT COLUMN 1,  "QX_CID:",
            COLUMN 25, rec_envQx_.QX_CID
      PRINT COLUMN 1,  "QX_CLEAR_DYNAMIC_LABEL:",
            COLUMN 25, rec_envQx_.QX_CLEAR_DYNAMIC_LABEL
      PRINT COLUMN 1,  "QX_CLEAR_STATIC_LABEL:",
            COLUMN 25, rec_envQx_.QX_CLEAR_STATIC_LABEL
      PRINT COLUMN 1,  "QX_CLIENT_HOST:",
            COLUMN 25, rec_envQx_.QX_CLIENT_HOST
      PRINT COLUMN 1,  "QX_CLIENT_IP:",
            COLUMN 25, rec_envQx_.QX_CLIENT_IP
      PRINT COLUMN 1,  "QX_COMPAT:",
            COLUMN 25, rec_envQx_.QX_COMPAT
      PRINT COLUMN 1,  "QX_DEBUG_HOSTS:",
            COLUMN 25, rec_envQx_.QX_DEBUG_HOSTS
      PRINT COLUMN 1,  "QX_DUMP_PASSES:",
            COLUMN 25, rec_envQx_.QX_DUMP_PASSES
      PRINT COLUMN 1,  "QX_HEADLESS_CONSOLE:",
            COLUMN 25, rec_envQx_.QX_HEADLESS_CONSOLE
      PRINT COLUMN 1,  "QX_HEADLESS_MODE:",
            COLUMN 25, rec_envQx_.QX_HEADLESS_MODE
      PRINT COLUMN 1,  "QX_HEADLESS_MODE:",
            COLUMN 25, rec_envQx_.QX_HEADLESS_MODE
      PRINT COLUMN 1,  "QX_LOGNATIVESQLERRORS:",
            COLUMN 25, rec_envQx_.QX_LOGNATIVESQLERRORS
      PRINT COLUMN 1,  "QX_LOG_DIR:",
            COLUMN 25, rec_envQx_.QX_LOG_DIR
      PRINT COLUMN 1,  "QX_MDI:",
            COLUMN 25, rec_envQx_.QX_MDI
      PRINT COLUMN 1,  "QX_MENU_WINDOW:",
            COLUMN 25, rec_envQx_.QX_MENU_WINDOW
      PRINT COLUMN 1,  "QX_MENU_WINDOW_NEW_CHILD:",
            COLUMN 25, rec_envQx_.QX_MENU_WINDOW_NEW_CHILD
      PRINT COLUMN 1,  "QX_NATIVE_LINKER:",
            COLUMN 25, rec_envQx_.QX_NATIVE_LINKER
      PRINT COLUMN 1,  "QX_NO_CLEAN_LINKER_FILES:",
            COLUMN 25, rec_envQx_.QX_NO_CLEAN_LINKER_FILES
      PRINT COLUMN 1,  "QX_OPT_LEVEL:",
            COLUMN 25, rec_envQx_.QX_OPT_LEVEL
      PRINT COLUMN 1,  "QX_PROCESS_ID:",
            COLUMN 25, rec_envQx_.QX_PROCESS_ID
      PRINT COLUMN 1,  "QX_QRUN_DUMP:",
            COLUMN 25, rec_envQx_.QX_QRUN_DUMP
      PRINT COLUMN 1,  "QX_QRUN_PORT:",
            COLUMN 25, rec_envQx_.QX_QRUN_PORT
      PRINT COLUMN 1,  "QX_RESOURCE_UNLOCK:",
            COLUMN 25, rec_envQx_.QX_RESOURCE_UNLOCK
      PRINT COLUMN 1,  "QX_REST_VALUE_XML:",
            COLUMN 25, rec_envQx_.QX_REST_VALUE_XML
      PRINT COLUMN 1,  "QX_RUN_ARG_PREF:",
            COLUMN 25, rec_envQx_.QX_RUN_ARG_PREF
      PRINT COLUMN 1,  "QX_SESSION_ID:",
            COLUMN 25, rec_envQx_.QX_SESSION_ID
      PRINT COLUMN 1,  "QX_SHOW_WINDOW:",
            COLUMN 25, rec_envQx_.QX_SHOW_WINDOW
      PRINT COLUMN 1,  "QX_SIZE_DIMENSION:",
            COLUMN 25, rec_envQx_.QX_SIZE_DIMENSION
      PRINT COLUMN 1,  "QX_SQLSCOPE_ON:",
            COLUMN 25, rec_envQx_.QX_SQLSCOPE_ON
      PRINT COLUMN 1,  "QX_STARTER_DEBUG_LOGGING:",
            COLUMN 25, rec_envQx_.QX_STARTER_DEBUG_LOGGING
      PRINT COLUMN 1,  "QX_STARTER_REDIRECT_STD_OUT:",
            COLUMN 25, rec_envQx_.QX_STARTER_REDIRECT_STD_OUT
      PRINT COLUMN 1,  "QX_UI_MODE_OVERRIDE:",
            COLUMN 25, rec_envQx_.QX_UI_MODE_OVERRIDE
      PRINT COLUMN 1,  "QX_USE_SIMPLE_CACHE_PATH:",
            COLUMN 25, rec_envQx_.QX_USE_SIMPLE_CACHE_PATH
      PRINT COLUMN 1,  "QX_VERBOSE_CACHE:",
            COLUMN 25, rec_envQx_.QX_VERBOSE_CACHE
      PRINT COLUMN 1,  "QX_VERIFY_AFTER:",
            COLUMN 25, rec_envQx_.QX_VERIFY_AFTER

			SKIP 1 LINES
      PRINT "----- C-Compiler/Sources --------------------------------------------------"
      SKIP 1 LINES
      PRINT COLUMN 1,  "C_INTERFACE_LOCALE:",
            COLUMN 25, rec_c_compiler.C_INTERFACE_LOCALE
      PRINT COLUMN 1,  "FGLC_TRACEGEN:",
            COLUMN 25, rec_c_compiler.FGLC_TRACEGEN
      PRINT COLUMN 1,  "FGLC_TRACEPROC:",
            COLUMN 25, rec_c_compiler.FGLC_TRACEPROC
      PRINT COLUMN 1,  "FGLC_TRACEPROCERRS:",
            COLUMN 25, rec_c_compiler.FGLC_TRACEPROCERRS
      PRINT COLUMN 1,  "FGLC_YYDEBUG:",
            COLUMN 25, rec_c_compiler.FGLC_YYDEBUG

      PRINT COLUMN 1,  "VC_DevEnvDir:",
            COLUMN 25, rec_c_compiler.VC_DevEnvDir
      PRINT COLUMN 1,  "VC_INCLUDE:",
            COLUMN 25, rec_c_compiler.VC_INCLUDE
      PRINT COLUMN 1,  "VC_LIB:",
            COLUMN 25, rec_c_compiler.VC_LIB
      PRINT COLUMN 1,  "VC_LIBPATH:",
            COLUMN 25, rec_c_compiler.VC_LIBPATH
      PRINT COLUMN 1,  "VC_VCINSTALLDIR:",
            COLUMN 25, rec_c_compiler.VC_VCINSTALLDIR
      PRINT COLUMN 1,  "VC_VisualStudioVersion:",
            COLUMN 25, rec_c_compiler.VC_VisualStudioVersion




			SKIP 1 LINES
      PRINT "----- OS ----------------------------------------------------------------"
      SKIP 1 LINES
      PRINT COLUMN 1,  "User Name:",
            COLUMN 25, rec_os.username
      PRINT COLUMN 1,  "User Name:",
            COLUMN 25, rec_os.system_username
      PRINT COLUMN 1,  "App-Server OS:",
            COLUMN 25, rec_os.server_os
      PRINT COLUMN 1,  "App-Server OS Det.:",
            COLUMN 25, rec_os.server_os_name



			SKIP 1 LINES
      PRINT "----- DB General ----------------------------------------------------------------"
      SKIP 1 LINES
      PRINT COLUMN 1,  "LYCIA_DB_DRIVER:",
            COLUMN 25, rec_db.LYCIA_DB_DRIVER
      PRINT COLUMN 1,  "DBPATH:",
            COLUMN 25, rec_db.DBPATH
		
	
				
			
			SKIP 1 LINES						           
      PRINT "----- DB-Informix --------------------------------------------------------"
      SKIP 1 LINES
      PRINT COLUMN 1,  "LOGNAME:",
            COLUMN 25, rec_informix.logname
      
      PRINT COLUMN 1,  "INFORMIXPASS:",
      	    COLUMN 25, rec_informix.informixPass


      PRINT COLUMN 1,  "DBPATH:",
            COLUMN 25, rec_informix.dbPath
      PRINT COLUMN 1,  "DB_LOCALE:",
            COLUMN 25, rec_informix.db_Locale
      PRINT COLUMN 1,  "INFORMIXSERVER:",
            COLUMN 25, rec_informix.informixServer
      PRINT COLUMN 1,  "INFORMIXDIR:",
            COLUMN 25, rec_informix.informixDir
      PRINT COLUMN 1,  "INFORMIXSQLHOSTS:",
            COLUMN 25, rec_informix.informixSqlHosts
      PRINT COLUMN 1,  "CLIENT_LOCALE:",
            COLUMN 25, rec_informix.client_locale
      PRINT COLUMN 1,  "QXSS_DB_IS_DSN:",
            COLUMN 25, rec_informix.qxss_db_is_dsn
      PRINT COLUMN 1,  "DELIMIDENT:",
            COLUMN 25, rec_informix.delimident
      PRINT COLUMN 1,  "DBDELIMITER:",
            COLUMN 25, rec_informix.DBDELIMITER
      PRINT COLUMN 1,  "DBFORMAT:",
            COLUMN 25, rec_informix.DBFORMAT
            
            
      PRINT COLUMN 1,  "DB-Name:",
            COLUMN 25, rec_informix.db_name
      PRINT COLUMN 1,  "DB-Name Det.:",
            COLUMN 25, rec_informix.db_name_full
      PRINT COLUMN 1,  "DB Major Version:",
            COLUMN 25, rec_informix.db_major_version
      PRINT COLUMN 1,  "Version OS:",
            COLUMN 25, rec_informix.db_infVersionOS
      PRINT COLUMN 1,  "DB-OS:",
            COLUMN 25, rec_informix.db_os
      PRINT COLUMN 1,  "DbHostName:",
            COLUMN 25, rec_informix.dbhostname
      PRINT COLUMN 1,  "DbName:",
            COLUMN 25, rec_informix.dbname
      PRINT COLUMN 1,  "sessionid:",
            COLUMN 25, rec_informix.sessionid

			SKIP 1 LINES
      PRINT "----- Oracle ---------------------------------------------------------"
      SKIP 1 LINES
      PRINT COLUMN 1,  "ORACLE_SID:",
            COLUMN 25, rec_oracle.ORACLE_SID
      PRINT COLUMN 1,  "ORACLE_HOME:",
            COLUMN 25, rec_oracle.ORACLE_HOME
                
			SKIP 1 LINES
      PRINT "----- SQL-Server -----------------------------------------------------"
      SKIP 1 LINES
      PRINT COLUMN 1,  "ODBC_DSN:",
            COLUMN 25, rec_sqlServer.ODBC_DSN
      PRINT COLUMN 1,  "SQLSERVER:",
            COLUMN 25, rec_sqlServer.SQLSERVER

			SKIP 1 LINES
      PRINT "----- DB2 ------------------------------------------------------------"
      SKIP 1 LINES
      PRINT COLUMN 1,  "DB2DIR:",
            COLUMN 25, rec_db2.DB2DIR
      PRINT COLUMN 1,  "DB2INSTANCE:",
            COLUMN 25, rec_db2.DB2INSTANCE


			SKIP 1 LINES            
      PRINT "----- BIRT -----------------------------------------------------------"
      SKIP 1 LINES
      PRINT COLUMN 1,  "BIRT_LIBDIR:",
            COLUMN 25, rec_birt.BIRT_LIBDIR

	  #in case, we have some file access problem

			SKIP 3 LINES    
			PRINT "##################################################################################"        
			PRINT "#                                                                                #"			
      PRINT "# Windows Registry                                                               #"
			PRINT "#                                                                                #"			
      PRINT "##################################################################################"        
      SKIP 3 LINES

			PRINT FILE "regrep.txt"

			SKIP 3 LINES            
			PRINT "##################################################################################"        
			PRINT "#                                                                                #"			
      PRINT "# OS System Info                                                                 #"
			PRINT "#                                                                                #"			
			PRINT "##################################################################################"        
      SKIP 3 LINES

			PRINT FILE "systeminfo.txt"

			SKIP 3 LINES            
			PRINT "##################################################################################"        
			PRINT "#                                                                                #"			
      PRINT "# LYCIA_SYSTEM_ACTION_DEFAULTS                                                                 #"
			PRINT "#                                                                                #"			
			PRINT "##################################################################################"        
      SKIP 3 LINES

			PRINT FILE rec_lycia.LYCIA_SYSTEM_ACTION_DEFAULTS


			SKIP 3 LINES            
			PRINT "##################################################################################"        
			PRINT "#                                                                                #"			
      PRINT "# FGLPROFILE                                                                     #"
			PRINT "#                                                                                #"			
			PRINT "##################################################################################"        
      SKIP 3 LINES

			PRINT FILE rec_env.FGLPROFILE



			SKIP 3 LINES            
			PRINT "##################################################################################"        
			PRINT "#                                                                                #"			
      PRINT "# listener.xml (if/when located in LYCIA_CONFIG_PATH                             #"
			PRINT "#                                                                                #"			
			PRINT "##################################################################################"        
      SKIP 3 LINES


			LET tmpStr = trim(rec_general.LYCIA_CONFIG_PATH), "/listener.xml"
			PRINT FILE tmpStr
			
			SKIP 3 LINES            
			PRINT "##################################################################################"        
			PRINT "#                                                                                #"			
      PRINT "# End of the Lyica System Report                                                 #"
			PRINT "#                                                                                #"			
			PRINT "##################################################################################"        


    #PAGE TRAILER
    #  SKIP 3 LINES
    #  PRINT COLUMN 45, "Page ## / ##", PAGENO USING "## /", (COUNT(*) + 1 + (5 - ((COUNT(*) + 1) mod 5))) / 5 USING "##" -- "Page ## / ##"

	

END REPORT

 } 