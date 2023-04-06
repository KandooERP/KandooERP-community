GLOBALS "../common/glob_GLOBALS.4gl"
DEFINE l_crs_isolation CURSOR

# This functions resets isolation mode to default mode
FUNCTION reset_isolation_mode()
	DEFINE p_set_isolation_mode PREPARED
	DEFINE l_stmt STRING
	LET l_stmt = "SET ISOLATION TO ",g_default_isolation_mode
	CALL p_set_isolation_mode.Prepare(l_stmt)
	CALL p_set_isolation_mode.Execute()
	RETURN sqlca.sqlcode
END FUNCTION

# This functions gets Kandoo Default isolation mode at start of kandoo
# it assigns the value to the global g_default_isolation_mode
FUNCTION get_default_isolation_mode()
	DEFINE sql_stmt STRING

	LET sql_stmt = 
	" SELECT CASE ",
	" WHEN isolevel = 0 THEN 'NOTRANS' ",
	" WHEN isolevel = 1 THEN 'DIRTY READ' ",
	"WHEN isolevel = 2 THEN  'COMMITTED READ' ",
	" WHEN isolevel = 3 THEN  'CURSOR STABILITY' ",
	" WHEN isolevel = 5 THEN  'REPEATABLE READ' ",
	" WHEN isolevel = 7 THEN  'DIRTY READ RETAIN UPDATE LOCKS' ",
	" WHEN isolevel =  8 THEN  'COMMITTED READ RETAIN UPDATE LOCKS' ",
	" WHEN isolevel = 9 THEN  'CURSOR STABILITY RETAIN UPDATE LOCKS' ",
	" WHEN isolevel = 11 THEN  'COMMITTED READ LAST COMMITTED' ",
	" ELSE NULL	END ",
	" FROM sysmaster:sysrstcb R, ", 
	" sysmaster:systxptab T ", 
	" WHERE R.sid = DBINFO('sessionid') ", 
	" AND  T.address = R.txp "
	CALL l_crs_isolation.Declare(sql_stmt)
	CALL l_crs_isolation.Open()
	CALL l_crs_isolation.FetchNext(g_default_isolation_mode) 

#	LET g_default_isolation_mode = "COMMITTED READ" #Eric default / needs to do
END FUNCTION

# This functions returns the Kandoo current isolation mode
# 
FUNCTION get_current_isolation_mode()
	DEFINE l_isolation_mode CHAR(64)
	# The cursor is already declared because it is a modular variable
	CALL l_crs_isolation.Open()
	CALL l_crs_isolation.FetchNext(l_isolation_mode)
	RETURN l_isolation_mode
	#RETURN "COMMITTED READ" #Eric default / needs to do
END FUNCTION