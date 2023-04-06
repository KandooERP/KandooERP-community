############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl"
{
FUNCTION error_mngmt()		                                                                                                   	
	DEFINE err_context 
	RECORD		                                                                                                
   logname       CHAR(8),		                                                                                                
   terminal      CHAR(8),		                                                                                                
   text_err      CHAR(80)		                                                                                                
	END RECORD		                                                                                                               	


	DEFINE fgl_err INTEGER
	DEFINE isam_err INTEGER
	DEFINE fullerrorMESSAGE String

	LET fgl_err = sqlca.sqlcode
	LET isam_err = sqlca.sqlerrd[2]
END FUNCTION

FUNCTION confirm_operation(xpos,ypos,msg)
	DEFINE xpos,ypos SMALLINT
	DEFINE msg CHAR(40)
	DEFINE reply CHAR(5)
	DEFINE Xaction SMALLINT
	DEFINE prpmsg CHAR(60)
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

FUNCTION display_eric_error(mesg)
	DEFINE mesg CHAR(30)		                                                                                                    
	DEFINE error_MESSAGE STRING		                                                                                             	
#	CALL Errorlog(sqlerrMESSAGE)
#			                                                                                            
#	LET error_MESSAGE = mesg clipped, " ",sqlca.sqlcode," ",sqlca.sqlerrd[2]," ",sqlca.sqlerrm clipped
#	CALL fgl_winmessage("Type OK TO continue",error_MESSAGE,"error")
END FUNCTION


FUNCTION init_program(dbname,progname)
	DEFINE progname CHAR(8)
	DEFINE dbname CHAR(8)
	DEFINE query CHAR(100)
	DEFINE logdir CHAR(128)
	DEFINE logfile CHAR(128)

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
	   ERROR "The database IS NOT available ",dbname		                                                                          	
	   EXIT PROGRAM		                                                                                                         	
	END IF		                                                                                                                  	
	WHENEVER ERROR CALL error_mngmt		                                                                                         	
END FUNCTION		                   

}
FUNCTION get_sr_number(l_cmpy_code)
	DEFINE l_cmpy_code CHAR(2)
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

