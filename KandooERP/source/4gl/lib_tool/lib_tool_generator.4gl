############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl"

FUNCTION error_mngmt() 
	DEFINE err_context 
	RECORD 
		logname CHAR(8), 
		terminal CHAR(8), 
		text_err CHAR(80) 
	END RECORD 


	DEFINE fgl_err INTEGER 
	DEFINE isam_err INTEGER 
	DEFINE fullerrormessage STRING 

	LET fgl_err = sqlca.sqlcode 
	LET isam_err = sqlca.sqlerrd[2] 
END FUNCTION 

FUNCTION confirm_operation(xpos,ypos,msg) 
	DEFINE xpos,ypos SMALLINT 
	DEFINE msg CHAR(40) 
	DEFINE reply CHAR(5) 
	DEFINE xaction SMALLINT 
	DEFINE prpmsg CHAR(60) 
	LET reply = fgl_winbutton("",msg,"Yes","Yes|No|Cancel","question",0) 
	CASE 
		WHEN reply = "Yes" 
			LET xaction= 2 
		WHEN reply = "No" 
			LET xaction= 1 
		WHEN reply = "Cancel" 
			LET xaction= 0 
		OTHERWISE 
			LET xaction= 1 
	END CASE 
	RETURN xaction 
END FUNCTION ## confirm_operation 

FUNCTION display_eric_error(mesg) 
	DEFINE mesg CHAR(30) 
	DEFINE error_message STRING 
	#	CALL Errorlog(sqlerrmessage)
	#
	#	LET error_message = mesg clipped, " ",sqlca.sqlcode," ",sqlca.sqlerrd[2]," ",sqlca.sqlerrm clipped
	#	CALL fgl_winmessage("Type OK TO continue",error_message,"error")
END FUNCTION 


FUNCTION init_program(dbname,progname) 
	DEFINE progname STRING 
	DEFINE dbname STRING 
	DEFINE query STRING 
	DEFINE logdir STRING 
	DEFINE logfile STRING 

	WHENEVER ERROR CALL error_mngmt 
	LET logdir=fgl_getenv("LOGDIR") 
	IF length(logdir) = 0 THEN 
		LET logdir="." 
	END IF 
	LET logfile=logdir clipped,"/",progname clipped,".log" 
	CALL startlog (logfile) 
	LET query = "database ",dbname clipped 
	PREPARE openbase FROM query 
	EXECUTE openbase 
	WHENEVER ERROR CONTINUE 
	IF sqlca.sqlcode < 0 THEN 
		ERROR "The database IS NOT available ",dbname 
		EXIT program 
	END IF 
	WHENEVER ERROR CALL error_mngmt 
END FUNCTION 


FUNCTION get_sr_number(l_cmpy_code) 
	DEFINE l_cmpy_code LIKE company.cmpy_code 
	DEFINE curr_date DATETIME year TO month 
	DEFINE l_ticket_number CHAR(16) 
	DEFINE ticket_num BIGINT 
	DEFINE ord_num CHAR(8) 
	LET curr_date = CURRENT 
	SELECT seq_srv_request.nextval 
	INTO ticket_num 
	FROM systables WHERE tabid = 1 
	LET ord_num = ticket_num USING "&&&&&&#" 
	LET l_ticket_number = curr_date, "-",ord_num 
	RETURN l_ticket_number 
END FUNCTION 

