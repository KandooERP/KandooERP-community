###################################################################################
# GLOBALS
###################################################################################
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS

  DEFINE t_database_info TYPE AS 
    RECORD
      db_version VARCHAR(10),
      db_build   VARCHAR(10),
      db_other   vARCHAR(10)
    END RECORD

END GLOBALS
