############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 

#####################################################################
# FUNCTION rpt_set_kandooreport_defaults(NULL)
#
# Set the default report parameters
#####################################################################
FUNCTION rpt_set_kandooreport_defaults(p_rec_kandooreport) #(glob_rec_kandooreport.menupath_text,glob_rec_kandooreport.report_code)
	DEFINE p_rec_kandooreport RECORD LIKE kandooreport.*
#	DEFINE p_module_id NCHAR(3)
#	DEFINE p_report_code_module_id LIKE kandooreport.report_code  #NCHAR(10) - usually module code or with appendix for multiple reports in one and the same module
	DEFINE l_msg STRING

	
--	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	IF p_rec_kandooreport.cmpy_code IS NULL THEN  
		CALL fgl_winmessage("4GL ERROR","Invalid l_rec_kandooreport.cmpy_code=NULL argument used in rpt_set_kandooreport_defaults()","ERROR")
	END IF
	IF p_rec_kandooreport.report_code IS NULL THEN  
		CALL fgl_winmessage("4GL ERROR","Invalid l_rec_kandooreport.report_code=NULL argument used in rpt_set_kandooreport_defaults()","ERROR")
	END IF
	IF p_rec_kandooreport.menupath_text IS NULL THEN  
		CALL fgl_winmessage("4GL ERROR","Invalid l_rec_kandooreport.menupath_text=NULL argument used in rpt_set_kandooreport_defaults()","ERROR")
	END IF
	IF p_rec_kandooreport.language_code IS NULL THEN  
		CALL fgl_winmessage("4GL ERROR","Invalid l_rec_kandooreport.language_code=NULL argument used in rpt_set_kandooreport_defaults()","ERROR")
	END IF
	IF p_rec_kandooreport.country_code IS NULL THEN  
		CALL fgl_winmessage("4GL ERROR","Invalid l_rec_kandooreport.country_code=NULL argument used in rpt_set_kandooreport_defaults()","ERROR")
	END IF
	
	CASE p_rec_kandooreport.report_code[1]
		WHEN "A"
			CALL rpt_set_kandooreport_defaults_A_AR(p_rec_kandooreport.*)
			RETURNING p_rec_kandooreport.*
		WHEN "C" #COMMON
			CALL rpt_set_kandooreport_defaults_C_COMMON(p_rec_kandooreport.*)
			RETURNING p_rec_kandooreport.*
		WHEN "E"
			CALL rpt_set_kandooreport_defaults_E_EO(p_rec_kandooreport.*)
			RETURNING p_rec_kandooreport.*
		
		WHEN "F"
			CALL rpt_set_kandooreport_defaults_F_FA(p_rec_kandooreport.*)
			RETURNING p_rec_kandooreport.*
		
		WHEN "G"
			CALL rpt_set_kandooreport_defaults_G_GL(p_rec_kandooreport.*)
			RETURNING p_rec_kandooreport.*
		
		WHEN "I"
			CALL rpt_set_kandooreport_defaults_I_IN(p_rec_kandooreport.*)
			RETURNING p_rec_kandooreport.*
		
		WHEN "J"
			CALL rpt_set_kandooreport_defaults_J_JM(p_rec_kandooreport.*)
			RETURNING p_rec_kandooreport.*
		
		WHEN "K"
			CALL rpt_set_kandooreport_defaults_K_SS(p_rec_kandooreport.*)
			RETURNING p_rec_kandooreport.*
		
		WHEN "L"
			CALL rpt_set_kandooreport_defaults_L_LC(p_rec_kandooreport.*)
			RETURNING p_rec_kandooreport.*
		
		WHEN "M"
			CALL rpt_set_kandooreport_defaults_M_MN(p_rec_kandooreport.*)
			RETURNING p_rec_kandooreport.*
		
		WHEN "N"
			CALL rpt_set_kandooreport_defaults_N_RE(p_rec_kandooreport.*)
			RETURNING p_rec_kandooreport.*
		
		WHEN "P"
			CALL rpt_set_kandooreport_defaults_P_AP(p_rec_kandooreport.*)
			RETURNING p_rec_kandooreport.*
		
		WHEN "Q"
			CALL rpt_set_kandooreport_defaults_Q_QE(p_rec_kandooreport.*)
			RETURNING p_rec_kandooreport.*
		
		WHEN "R"
			CALL rpt_set_kandooreport_defaults_R_PU(p_rec_kandooreport.*)
			RETURNING p_rec_kandooreport.*
			
		WHEN "T"
			CALL rpt_set_kandooreport_defaults_T_TGW(p_rec_kandooreport.*)
			RETURNING p_rec_kandooreport.*		
			
		WHEN "U"
			CALL rpt_set_kandooreport_defaults_U_UT(p_rec_kandooreport.*)
			RETURNING p_rec_kandooreport.*
		
		WHEN "W"
			CALL rpt_set_kandooreport_defaults_W_WO(p_rec_kandooreport.*)
			RETURNING p_rec_kandooreport.*

		OTHERWISE
			#INITIALIZE p_rec_kandooreport.* TO NULL
			LET p_rec_kandooreport.header_text = "MISSING IN DEFAULT TEMPLATES"
	END CASE

	IF p_rec_kandooreport.menupath_text IS NULL THEN
		LET l_msg = "FUNCTION rpt_set_kandooreport_defaults(p_rec_kandooreport)\n"
		LET l_msg = l_msg CLIPPED, "Could not find default template for kandooreport\n"
		LET l_msg = l_msg CLIPPED, "module_id/menupath_text=",trim(p_rec_kandooreport.menupath_text), "\n"
		LET l_msg = l_msg CLIPPED, "kandooreport.report_code=", trim(p_rec_kandooreport.report_code) 
		CALL fgl_winmessage("Internal 4GL-ERROR",l_msg,"ERROR")
	END IF
	

	RETURN p_rec_kandooreport.* 
END FUNCTION 