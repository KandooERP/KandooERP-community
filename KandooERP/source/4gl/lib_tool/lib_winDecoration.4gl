############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"

############################################################
# FUNCTION winDecoration(p_winname)
#
#
############################################################
FUNCTION windecoration(p_winname) 
	DEFINE p_winname STRING 
	DEFINE l_errmsg STRING 
	DEFINE l_trlstd_messages INTEGER 
	DEFINE l_language LIKE attributes_translation.language 

-- alch locale catalogue will be used at runtime
	# If user's language is not English, translate the form
--	IF ( glob_rec_kandoouser.language_code <> "ENG" ) THEN 
--		# Check is the forms are translated for this language
--		SELECT count(*) 
--		INTO l_trlstd_messages 
--		FROM attributes_translation 
--		WHERE language = glob_rec_kandoouser.language_code 
--		IF l_trlstd_messages > 1000 THEN 
--			CALL translate_form (glob_rec_kandoouser.language_code,p_winname) 
--		END IF 
--	END IF 

	WHENEVER ERROR CONTINUE 
	DISPLAY glob_rec_company.cmpy_code TO hdr_cmpy_code
	DISPLAY glob_rec_company.name_text TO hdr_cmpy_name

	CASE p_winname[1] 
		WHEN "A" 
			CALL windecoration_a(p_winname) 

		WHEN "E" 
			CALL windecoration_e(p_winname) 

		WHEN "F" 
			CALL windecoration_f(p_winname) 

		WHEN "G" 
			CALL windecoration_g(p_winname) 


		WHEN "I" 
			CALL windecoration_i(p_winname) 

		WHEN "J" 
			CALL windecoration_j(p_winname) 

		WHEN "K" 
			CALL windecoration_k(p_winname) 

		WHEN "L" 
			CALL windecoration_l(p_winname) 

		WHEN "N" 
			CALL windecoration_n(p_winname) 

		WHEN "M" 
			CALL windecoration_m(p_winname) 

		WHEN "P" 
			CALL windecoration_p(p_winname) 

		WHEN "Q" 
			CALL windecoration_q(p_winname) 

		WHEN "R" 
			CALL windecoration_r(p_winname) 

		WHEN "S" 
			CALL windecoration_s(p_winname) 

		WHEN "T" 
			CALL windecoration_t(p_winname) 

		WHEN "U" 
			CALL windecoration_u(p_winname) 

		WHEN "W" 
			CALL windecoration_w(p_winname) 

		OTHERWISE 
			LET l_errmsg = "Invalid Window name passed TO winDecorcation(", trim(p_winname), ")" 
			CALL fgl_winmessage("Internal 4GL Error",l_errmsg, "error") 
	END CASE 

	WHENEVER ERROR stop 

END FUNCTION 
############################################################
# END FUNCTION winDecoration(p_winname)
############################################################