# Purpose - Opens a window AND allows INPUT of a part code TO image a
#           bill of resource FROM

GLOBALS "../common/glob_GLOBALS.4gl" 


FUNCTION bor_image(p_cmpy) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_formname CHAR(15) 
	DEFINE l_fv_part_code LIKE bor.parent_part_code 
	DEFINE r_fv_image_part_code LIKE bor.parent_part_code 

	OPEN WINDOW w1_m112 with FORM "M112" 
	CALL windecoration_m("M112") -- albo kd-767 

	LET l_msgresp = kandoomsg("M", 1505, "") 
	# MESSAGE "ESC TO Accept, DEL TO Exit"

	INPUT r_fv_image_part_code FROM parent_part_code 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","borimgwind","input-image_part_code") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" #ON KEY (control-b) 
			CALL show_parents(p_cmpy) RETURNING l_fv_part_code 

			IF l_fv_part_code IS NOT NULL THEN 
				LET r_fv_image_part_code = l_fv_part_code 
				NEXT FIELD parent_part_code 
			END IF 

		AFTER FIELD parent_part_code 
			IF r_fv_image_part_code IS NULL THEN 
				LET l_msgresp = kandoomsg("M", 9507, "") 
				# ERROR "Parent product code must be entered"
				NEXT FIELD parent_part_code 
			END IF 

			SELECT unique parent_part_code 
			FROM bor 
			WHERE cmpy_code = p_cmpy 
			AND parent_part_code = r_fv_image_part_code 

			IF status = notfound THEN 
				LET l_msgresp = kandoomsg("M", 9508, "") 
				# ERROR "This product has no children"
				NEXT FIELD parent_part_code 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET r_fv_image_part_code = NULL 
	END IF 

	CLOSE WINDOW w1_m112 

	RETURN r_fv_image_part_code 

END FUNCTION 
