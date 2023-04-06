GLOBALS "../../_qxt_toolbox/menu/4gl/_qxt_menu_deploy_db_globals.4gl"

###################################################################################
# NOTE !
#
# These are the legacy/original menu table data 
#
###################################################################################

###################################################################################
# GLOBALS
###################################################################################
GLOBALS
  #DEFINE window_open SMALLINT
  DEFINE
    monitor STRING, --CHAR(5000),
    retval SMALLINT,
    db_state_str VARCHAR(100),
    db_connect_msg VARCHAR(200),
    db_name VARCHAR(40),
    db_version VARCHAR(10),
    db_build VARCHAR(10),
    qxt_db_state SMALLINT,
    table_name_list   DYNAMIC ARRAY OF VARCHAR(18),
    inst_table_count      SMALLINT,
    #qxt_table_count       SMALLINT,
    qxt_table_count       SMALLINT
    #app_type              SMALLINT
END GLOBALS


MAIN
	CALL fgl_setenv("setup_silent","1")
	
	LET setup_silent = 1
	
	CALL silentMenuTableLoad()
END MAIN