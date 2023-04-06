# used TO be in secufunc.4gl - FOR manufacturing

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 


############################################################
# FUNCTION kandoomenu(p_source_ind, p_menu_num)
#
#
############################################################
FUNCTION kandoomenu(p_source_ind, p_menu_num) 
	DEFINE p_source_ind LIKE menunames.source_ind 
	DEFINE p_menu_num LIKE menunames.menu_num 
	DEFINE l_rec_menunames RECORD LIKE menunames.* 

	# Get the menu
	SELECT * INTO l_rec_menunames.* FROM menunames 
	WHERE language_code = glob_rec_kandoouser.language_code 
	AND source_ind = p_source_ind 
	AND menu_num = p_menu_num 
	IF status = notfound THEN 
		CALL menu_error(p_source_ind, p_menu_num, glob_rec_kandoouser.language_code) 
		SLEEP 3 
		IF glob_rec_kandoouser.language_code != "ENG" THEN 
			SELECT * INTO l_rec_menunames.* FROM menunames 
			WHERE language_code = "ENG" 
			AND source_ind = p_source_ind 
			AND menu_num = p_menu_num 
			IF status = notfound THEN 
				CALL menu_error(p_source_ind, p_menu_num, "ENG") 
				SLEEP 5 
				EXIT program 
			END IF 
		ELSE 
			EXIT program 
		END IF 
	END IF 

	#Get standards
	IF l_rec_menunames.ref1_code IS NOT NULL THEN 
		CALL kandoomenu_std(l_rec_menunames.ref1_code, l_rec_menunames.cmd1_code, 
		l_rec_menunames.cmd1_text) 
		RETURNING l_rec_menunames.cmd1_code, l_rec_menunames.cmd1_text 
	END IF 
	IF l_rec_menunames.ref2_code IS NOT NULL THEN 
		CALL kandoomenu_std(l_rec_menunames.ref2_code, l_rec_menunames.cmd2_code, 
		l_rec_menunames.cmd2_text) 
		RETURNING l_rec_menunames.cmd2_code, l_rec_menunames.cmd2_text 
	END IF 
	IF l_rec_menunames.ref3_code IS NOT NULL THEN 
		CALL kandoomenu_std(l_rec_menunames.ref3_code, l_rec_menunames.cmd3_code, 
		l_rec_menunames.cmd3_text) 
		RETURNING l_rec_menunames.cmd3_code, l_rec_menunames.cmd3_text 
	END IF 
	IF l_rec_menunames.ref4_code IS NOT NULL THEN 
		CALL kandoomenu_std(l_rec_menunames.ref4_code, l_rec_menunames.cmd4_code, 
		l_rec_menunames.cmd4_text) 
		RETURNING l_rec_menunames.cmd4_code, l_rec_menunames.cmd4_text 
	END IF 
	IF l_rec_menunames.ref5_code IS NOT NULL THEN 
		CALL kandoomenu_std(l_rec_menunames.ref5_code, l_rec_menunames.cmd5_code, 
		l_rec_menunames.cmd5_text) 
		RETURNING l_rec_menunames.cmd5_code, l_rec_menunames.cmd5_text 
	END IF 
	IF l_rec_menunames.ref6_code IS NOT NULL THEN 
		CALL kandoomenu_std(l_rec_menunames.ref6_code, l_rec_menunames.cmd6_code, 
		l_rec_menunames.cmd6_text) 
		RETURNING l_rec_menunames.cmd6_code, l_rec_menunames.cmd6_text 
	END IF 
	IF l_rec_menunames.ref7_code IS NOT NULL THEN 
		CALL kandoomenu_std(l_rec_menunames.ref7_code, l_rec_menunames.cmd7_code, 
		l_rec_menunames.cmd7_text) 
		RETURNING l_rec_menunames.cmd7_code, l_rec_menunames.cmd7_text 
	END IF 
	IF l_rec_menunames.ref8_code IS NOT NULL THEN 
		CALL kandoomenu_std(l_rec_menunames.ref8_code, l_rec_menunames.cmd8_code, 
		l_rec_menunames.cmd8_text) 
		RETURNING l_rec_menunames.cmd8_code, l_rec_menunames.cmd8_text 
	END IF 
	IF l_rec_menunames.ref9_code IS NOT NULL THEN 
		CALL kandoomenu_std(l_rec_menunames.ref9_code, l_rec_menunames.cmd9_code, 
		l_rec_menunames.cmd9_text) 
		RETURNING l_rec_menunames.cmd9_code, l_rec_menunames.cmd9_text 
	END IF 
	RETURN l_rec_menunames.* 
END FUNCTION # kandoomenu 


############################################################
# FUNCTION kandoomenu_std(p_ref_code, p_cmd_code, p_cmd_text)
#
#
############################################################
FUNCTION kandoomenu_std(p_ref_code, p_cmd_code, p_cmd_text) 
	DEFINE p_ref_code LIKE cmdstandard.ref_code 
	DEFINE p_cmd_code LIKE cmdstandard.cmd_code 
	DEFINE p_cmd_text LIKE cmdstandard.cmd_text 
	DEFINE l_rec_cmdstandard RECORD LIKE cmdstandard.* 

	SELECT * INTO l_rec_cmdstandard.* 
	FROM cmdstandard 
	WHERE cmdstandard.language_code = glob_rec_kandoouser.language_code 
	AND cmdstandard.ref_code = p_ref_code 

	IF status = notfound THEN 
		IF glob_rec_kandoouser.language_code != "ENG" THEN 
			SELECT * INTO l_rec_cmdstandard.* 
			FROM cmdstandard 
			WHERE cmdstandard.language_code = "ENG" 
			AND cmdstandard.ref_code = p_ref_code 
			IF status = notfound THEN 
				RETURN p_cmd_code, p_cmd_text 
			ELSE 
				RETURN l_rec_cmdstandard.cmd_code, l_rec_cmdstandard.cmd_text 
			END IF 
		ELSE 
			RETURN p_cmd_code, p_cmd_text 
		END IF 
	END IF 
	RETURN l_rec_cmdstandard.cmd_code, l_rec_cmdstandard.cmd_text 
END FUNCTION # kandoomenu_std 



############################################################
# FUNCTION menu_error(p_source_ind, p_menu_num, p_language_code)
#
#
############################################################
FUNCTION menu_error(p_source_ind, p_menu_num, p_language_code) 
	DEFINE p_source_ind LIKE menunames.source_ind 
	DEFINE p_menu_num LIKE menunames.menu_num 
	DEFINE p_language_code LIKE menunames.language_code 
	DEFINE l_spaces CHAR(400) 
	DEFINE l_baseprogname STRING 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_spaces[001,080]="Max Menu Error - Menu Not Found." 
	LET l_spaces[081,160]=" Language Code = ", p_language_code 
	LET l_spaces[161,240]=" Source Indicator = ", p_source_ind 
	LET l_spaces[241,320]=" Menu number = ", p_menu_num 


	LET l_spaces[321,400]=" Calling Program = ",get_baseProgName(), "." 

	CALL errorlog(l_spaces) 
	LET l_msgresp = kandoomsg("U", 9507, "") 
	#9507 Menu Library Error - refer get_settings_logFile()
END FUNCTION 
