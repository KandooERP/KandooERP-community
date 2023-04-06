###########################################################################
# Module Scope Variables
###########################################################################
DEFINE ml_db VARCHAR(30) --db NAME 
DEFINE ml_db_set boolean --true = variable initialized/set false=not initialized 

###########################################################################
# FUNCTION set_db(p_db)
#
# Accessor Method for ml_db
# DEFINE ml_db VARCHAR(30)  --db name
# DEFINE ml_db_set BOOLEAN --TRUE = variable INITIALIZEd/SET FALSE=NOT INITIALIZEd
###########################################################################
FUNCTION set_db(p_db) 
	DEFINE p_db STRING 

	IF p_db IS NOT NULL THEN 
		LET ml_db = p_db 
		CALL fgl_setenv("DB",ml_db) 
		CALL fgl_setenv("KANDOODB",ml_db) 
		LET ml_db_set = true 
	END IF 
END FUNCTION 


###########################################################################
# FUNCTION get_db()
#
# Accessor Method for ml_db_set = STATUS, if DB was SET
###########################################################################
FUNCTION get_db() 

	IF ml_db_set = false THEN 
		IF (fgl_getenv("DB") IS null) AND (fgl_getenv("KANDOODB") IS null) THEN 
			#use defaut kandoodb
			CALL fgl_setenv("KANDOODB","kandoodb") 
			CALL fgl_setenv("DB","kandoodb") 
			CALL set_db("kandoodb") 
		ELSE 
			IF fgl_getenv("KANDOODB") IS NOT NULL THEN 
				CALL set_db(trim(fgl_getenv("KANDOODB"))) 
			ELSE 
				CALL set_db(trim(fgl_getenv("DB"))) 
			END IF 
		END IF 
	END IF 

	RETURN ml_db 
END FUNCTION 


###########################################################################
# FUNCTION get_db_set()
#
# Accessor Method for ml_db_set  = STATUS, if DB was SET
###########################################################################
FUNCTION get_db_set() 
	RETURN ml_db_set 
END FUNCTION 


########################################################
# FUNCTION connect_db(db_name)
#
#
########################################################
FUNCTION connect_db(db_name) 
	DEFINE db_name VARCHAR(50) 
	DEFINE sqlr SMALLINT 
	DEFINE dbstatus SMALLINT 
	DEFINE db_state_str VARCHAR(100) 
	DEFINE msgerror STRING 
	DEFINE includeauthenticationinfo boolean --by default off - in CASE it IS sent TO i.e. querix but the user can turn it ON IF it IS used FOR their internal usage 
	DEFINE informixpassparthiddenstring STRING -- i.e. treehouse -> t*******e 
	DEFINE l_rec_dbstatus RECORD 
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

	LET includeauthenticationinfo = false --no db password etc.. IS included in the REPORT 
	WHENEVER ERROR CONTINUE 
	#DATABASE db_name
	DISCONNECT all -- alch 2019.12.11 - replace TO disconenct default WHEN it will be fixed 
	CONNECT TO db_name -- alch kd-877: allow switching between informix servers 
	LET dbstatus = status 
	LET sqlr = sqlca.sqlcode 
	LET l_rec_dbstatus.dbname = db_name 
	LET l_rec_dbstatus.db_status = status 
	LET l_rec_dbstatus.sqlca_sqlcode = sqlca.sqlcode 
	LET l_rec_dbstatus.driver_error = fgl_driver_error() 
	LET l_rec_dbstatus.native_code = fgl_native_code() 
	LET l_rec_dbstatus.native_error = fgl_native_error() 
	LET l_rec_dbstatus.error_text = fgl_gethelp(dbstatus) 
	LET l_rec_dbstatus.db_type = db_get_database_type() 
	LET l_rec_dbstatus.db_type_name = getdbtypename(l_rec_dbstatus.db_type) 
	LET l_rec_dbstatus.dbpath = fgl_getenv("DBPATH") 
	LET l_rec_dbstatus.lycia_db_driver = fgl_getenv("LYCIA_DB_DRIVER") 
	LET l_rec_dbstatus.logname = fgl_getenv("LOGNAME") 
	IF includeauthenticationinfo THEN 
		LET l_rec_dbstatus.informixpass = fgl_getenv("INFORMIXPASS") --show REAL password !!! security) 
	ELSE 
		LET l_rec_dbstatus.informixpass = informixpassparthiddenstring --show decripted password 
	END IF 
	LET l_rec_dbstatus.db_locale = fgl_getenv("DB_LOCALE") 
	LET l_rec_dbstatus.informixserver = fgl_getenv("INFORMIXSERVER") 
	LET l_rec_dbstatus.informixdir = fgl_getenv("INFORMIXDIR") 
	LET l_rec_dbstatus.oracle_sid = fgl_getenv("ORACLE_SID") 
	LET l_rec_dbstatus.oracle_home = fgl_getenv("ORACLE_HOME") 
	LET l_rec_dbstatus.odbc_dsn = fgl_getenv("ODBC_DSN") 
	LET l_rec_dbstatus.sqlserver = fgl_getenv("SQLSERVER") 
	LET l_rec_dbstatus.db2dir = fgl_getenv("DB2DIR") 
	LET l_rec_dbstatus.db2instance = fgl_getenv("DB2INSTANCE") 
	WHENEVER ERROR stop 
	
	# retrieve the default isolation level
	CALL get_default_isolation_mode()
	IF dbstatus <> 0 THEN 
		CASE 
			WHEN (sqlr = -329 OR sqlr = -827) 
				LET db_state_str = db_name clipped, ": Database NOT found OR no system permission." 
				ERROR db_state_str clipped 
			WHEN (sqlr = -349) 
				LET db_state_str = db_name clipped, " NOT opened, you do NOT have Connect privilege - SQL Code:", sqlr 
				ERROR db_state_str clipped 
			WHEN (sqlr = -354) 
				LET db_state_str = db_name clipped, ": Incorrect database name FORMAT. - SQL Code:", sqlr 
				ERROR db_state_str clipped 
			WHEN (sqlr = -377) 
				LET db_state_str = "connect_db() called with a transaction still incomplete - SQL Code:", sqlr 
				ERROR db_state_str clipped 
			WHEN (sqlr = -512) 
				LET db_state_str = "Unable TO OPEN in exclusive mode, db IS probably in use - SQL Code:", sqlr 
				ERROR db_state_str clipped 
			WHEN (sqlr = -908) 
				LET db_state_str = "Attempt TO connect TO database server (servername) failed - SQL Code:", sqlr 
				ERROR db_state_str clipped 
			WHEN (sqlr = 0) 
				LET db_state_str = "Connection successful - SQL Code:", sqlr 
				MESSAGE db_state_str clipped 
			OTHERWISE 
				LET db_state_str = "Other error - SQL Code:", sqlr 
				ERROR db_state_str clipped 
				CALL fgl_winmessage("Error when trying TO connect TO DB",db_state_str,"error") 
		END CASE 

		LET msgerror = "DB:", trim(db_name), " - ", db_state_str, " - ", dbstatus 
		CALL fgl_winmessage("DB-Error",msgError,"error") 

		OPEN WINDOW w_dberror with FORM "form/4gl_environment_sql_error" 
		DISPLAY BY NAME l_rec_dbstatus.* 

		MENU 
			ON ACTION "ACCEPT" 
				EXIT program 
			ON ACTION "CANCEL" 
				EXIT program 
		END MENU 

		CLOSE WINDOW w_dberror 
	END IF 

	RETURN dbstatus, db_state_str 
END FUNCTION 
