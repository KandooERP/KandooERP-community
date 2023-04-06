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


FUNCTION display_error2(mesg) 
	DEFINE mesg char(30) 
	DEFINE error_message STRING 
	#	CALL Errorlog(sqlerrMESSAGE)
	#
	#	LET error_MESSAGE = mesg clipped, " ",sqlca.sqlcode," ",sqlca.sqlerrd[2]," ",sqlca.sqlerrm clipped
	#	CALL fgl_winmessage("Type OK TO continue",error_MESSAGE,"error")
END FUNCTION 

FUNCTION display_eric_error(p_err_mesg) #@g00781 
	DEFINE p_err_mesg CHAR(30) #@g00782 
	DEFINE error_message STRING #@g00783 
	CALL errorlog(sqlerrmessage) #@g00784 
	LET error_message = p_err_mesg clipped, " ",sqlca.sqlcode," ",sqlca.sqlerrd[2]," ",sqlca.sqlerrm clipped #@g00785 
	CALL fgl_winmessage("Type OK TO continue",error_MESSAGE,"error") #@g00786 
END FUNCTION 

FUNCTION display_4gl_error() #@g00781 
	DEFINE mesg CHAR(30) #@g00782 
	DEFINE error_message STRING #@g00783 
	LET error_message = mesg clipped, " ",sqlca.sqlcode," ",sqlca.sqlerrd[2]," ",sqlca.sqlerrm clipped #@g00785 
	CALL errorlog(sqlerrmessage) #@g00784 
	CALL fgl_winmessage("Type OK TO continue",error_MESSAGE,"error") #@g00786 
END FUNCTION 
