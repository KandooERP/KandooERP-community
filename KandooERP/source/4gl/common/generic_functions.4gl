############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl"

#renamed.. was FUNCTION error_display(mesg)  ... but this function name exists already multiple times in the orginal kandoo sources
FUNCTION db_error_display(p_msg,p_sqlca_sqlcode) 
	DEFINE p_msg char(30) 
	DEFINE p_sqlca_sqlcode SMALLINT
	DEFINE l_error_message STRING 
	CALL errorlog(sqlerrmessage) 

	LET l_error_message = p_msg clipped, " ",sqlca.sqlcode," ",sqlca.sqlerrd[2]," ",sqlca.sqlerrm clipped 
	CALL fgl_winmessage("Type OK TO continue",l_error_message,"error") 
END FUNCTION 


{
FUNCTION error_mngmt()
	DEFINE err_context
	RECORD
   logname       CHAR(8),
   terminal      CHAR(8),
   text_err      CHAR(80)
	END RECORD


	DEFINE fgl_err integer
	DEFINE isam_err integer
	DEFINE fullerrorMESSAGE String

	LET fgl_err = sqlca.sqlcode
	LET isam_err = sqlca.sqlerrd[2]
END FUNCTION
}
{
FUNCTION confirm_operation(xpos,ypos,msg)
	DEFINE xpos,ypos SMALLINT
	DEFINE msg char(40)
	DEFINE reply CHAR(5)
	DEFINE Xaction smallint
	DEFINE prpmsg char(60)
	LET reply = fgl_winbutton("",msg,"Yes","Yes|No|Cancel","question",0)
	CASE
	WHEN reply = "Yes"
		LET Xaction= 2
	WHEN reply = "No"
		LET Xaction= 1
	WHEN reply = "Cancel"
		LET Xaction= 0
	OTHERWISE
		LET Xaction= 1
	END CASE
	RETURN Xaction
END FUNCTION		## confirm_operation
}

{
FUNCTION display_error(mesg)
	DEFINE mesg char(30)
	DEFINE error_MESSAGE STRING
#	CALL Errorlog(sqlerrMESSAGE)
#
#	LET error_MESSAGE = mesg clipped, " ",sqlca.sqlcode," ",sqlca.sqlerrd[2]," ",sqlca.sqlerrm clipped
#	CALL fgl_winmessage("Type OK TO continue",error_MESSAGE,"error")
END FUNCTION
}
{

FUNCTION init_program(dbname,progname)
	DEFINE progname CHAR(8)
	DEFINE dbname CHAR(8)
	DEFINE query char(100)
	DEFINE logdir char(128)
	DEFINE logfile char(128)

	WHENEVER ERROR CALL error_mngmt
	LET logdir=fgl_getenv("LOGDIR")
	IF length(logdir) = 0 THEN
	   LET logdir="."
	END IF
	LET logfile=logdir clipped,"/",progname clipped,".log"
	CALL STARTLOG (logfile)
	LET query = "database ",dbname clipped
	PREPARE openbase FROM query
	EXECUTE openbase
	WHENEVER ERROR CONTINUE
	IF sqlca.sqlcode < 0 THEN
	   ERROR "The database is not available ",dbname
	   exit program
	END IF
	WHENEVER ERROR CALL error_mngmt
END FUNCTION
}
{
FUNCTION get_sr_number(l_cmpy_code)
	DEFINE l_cmpy_code LIKE sr_xxx
	DEFINE curr_date DATETIME YEAR TO MONTH
	DEFINE l_ticket_number CHAR(16)
	DEFINE ticket_num BIGINT
	DEFINE ord_num CHAR(8)
	LET curr_date = current
	SELECT seq_srv_request.NEXTVAL
	INTO ticket_num
	FROM systables WHERE tabid = 1
	LET ord_num = ticket_num USING "&&&&&&#"
	LET l_ticket_number = curr_date, "-",ord_num
	RETURN l_ticket_number
END FUNCTION
}
