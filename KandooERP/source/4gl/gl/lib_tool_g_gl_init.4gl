############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 

############################################################
# FUNCTION init_g_gl()
#
# Initialise G/GL Module
# This record keeps most GL setup options/configuration details
############################################################
FUNCTION init_g_gl() 
	DEFINE l_msgresp LIKE language.yes_flag 

	SELECT glparms.* 
	INTO glob_rec_glparms.* 
	FROM glparms 
	WHERE glparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND glparms.key_code = "1" 

	#Could do with a better error message - GL not setup correctly???
	IF STATUS = NOTFOUND THEN 
		LET glob_gl_setup = FALSE 
		--CALL fgl_winmessage("General Ledger not setup correctly","Contact your administrator - General Ledger is not setup correctly (GZP/LZP)","error")
		LET l_msgresp = kandoomsg("U",5107,"") 
		#5107 General Ledger Parameters NOT SET up; Refer Menu GZP.
		CALL fgl_winmessage("5107 General Ledger Parameters NOT SET up",l_msgresp,"error") 
	ELSE 
		LET glob_gl_setup = TRUE 
	END IF 
END FUNCTION 


#HuHo thinking about to move this recod to modular scope and only access it via accessor methods
FUNCTION get_gl_setup_state() 
	RETURN glob_gl_setup 
END FUNCTION 

FUNCTION set_gl_setup_state(p_gl_setup) 
	DEFINE p_gl_setup boolean 
	LET glob_gl_setup = p_gl_setup 
END FUNCTION 


FUNCTION get_gl_setup_record() 
	RETURN glob_rec_glparms.* 
END FUNCTION 

FUNCTION set_gl_setup_record(p_rec_glparms) 
	DEFINE p_rec_glparms RECORD LIKE glparms.* 
	LET glob_rec_glparms.* = p_rec_glparms.* 
END FUNCTION 

FUNCTION get_gl_setup_cash_book_installed() 
	RETURN glob_rec_glparms.cash_book_flag 
END FUNCTION 
