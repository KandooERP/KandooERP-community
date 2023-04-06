{
###########################################################################
# This program IS free software; you can redistribute it AND/OR modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2 of the License, OR (at your
# option) any later version.
#
# This program IS distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License FOR more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; IF NOT, write TO the Free Software Foundation, Inc.,
# 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
###########################################################################

	Source code beautified by beautify.pl on 2020-01-03 18:54:43	$Id: $
}



# U21 allows the menuing system TO be altered


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../utility/U_UT_GLOBALS.4gl" 

GLOBALS 
	DEFINE pr_menu1 RECORD LIKE menu1.*
	DEFINE pr_menu2 RECORD LIKE menu2.*
	DEFINE pr_menu3 RECORD LIKE menu3.*
	DEFINE pa_menu1 array[40] OF RECORD 
		menu1_code LIKE menu1.menu1_code, 
		prosper_flag LIKE menu1.prosper_flag, 
		name_text LIKE menu1.name_text, 
		password_text LIKE menu1.password_text, 
		security_ind LIKE menu1.security_ind 
	END RECORD 
	DEFINE pa_menu2 array[40] OF RECORD 
		menu2_code LIKE menu2.menu2_code, 
		name_text LIKE menu2.name_text, 
		password_text LIKE menu2.password_text, 
		security_ind LIKE menu2.security_ind 
	END RECORD 
	DEFINE pa_menu3 array[40] OF RECORD 
		menu3_code LIKE menu3.menu3_code, 
		name_text LIKE menu3.name_text, 
		password_text LIKE menu3.password_text, 
		security_ind LIKE menu3.security_ind, 
		run_text LIKE menu3.run_text 
	END RECORD 
	DEFINE save_scrn SMALLINT
	DEFINE store_scrn SMALLINT
	DEFINE store_idx SMALLINT
	DEFINE save_idx SMALLINT
	DEFINE idx SMALLINT
	DEFINE id_flag SMALLINT 
	DEFINE scrn SMALLINT 
	DEFINE cnt SMALLINT 
	DEFINE err_flag SMALLINT 	
	DEFINE ans CHAR(2) 
--	DEFINE glob_rec_kandoouser RECORD LIKE kandoouser.* 
END GLOBALS 


###################################################################
# MAIN
#
#
###################################################################
MAIN 

	CALL setModuleId("U21") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_u_ut() #init utility module 

	CALL fgl_winmessage("This will be removed","This program will be replaced by the new menu manager","info") 
	WHILE true 
		IF NOT doit() THEN 
			EXIT WHILE 
		END IF 
	END WHILE 
END MAIN 


FUNCTION doit() 
	DEFINE l_msgresp LIKE language.yes_flag

	DECLARE c_l1 CURSOR FOR 
	SELECT * INTO pr_menu1.* FROM menu1 
	ORDER BY menu1_code 
	LET idx = 0 
	FOREACH c_l1 
		LET idx = idx + 1 
		LET pa_menu1[idx].menu1_code = pr_menu1.menu1_code 
		LET pa_menu1[idx].prosper_flag = pr_menu1.prosper_flag 
		LET pa_menu1[idx].name_text = pr_menu1.name_text 
		LET pa_menu1[idx].password_text = pr_menu1.password_text 
		LET pa_menu1[idx].security_ind = pr_menu1.security_ind 
	END FOREACH 
	CALL set_count (idx) 
	OPEN WINDOW lev1 with FORM "U104" 
	CALL windecoration_u("U104") 

	LET l_msgresp = kandoomsg("U",1003,"") 
	#1003 " F1 TO add - F2 TO delete - RETURN on Line TO Edit

	INPUT ARRAY pa_menu1 WITHOUT DEFAULTS FROM sa_menu1.* ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","U21","input-arr-menu1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			LET pr_menu1.menu1_code = pa_menu1[idx].menu1_code 
			LET pr_menu1.prosper_flag = pa_menu1[idx].prosper_flag 
			LET pr_menu1.name_text = pa_menu1[idx].name_text 
			LET pr_menu1.password_text = pa_menu1[idx].password_text 
			LET pr_menu1.security_ind = pa_menu1[idx].security_ind 
			LET id_flag = 0 


		ON ACTION edit 
			NEXT FIELD prosper_flag 

		BEFORE FIELD prosper_flag 
			LET save_idx = idx 
			LET save_scrn = scrn 
			CALL changor() 
			CLOSE WINDOW lev2 
			LET idx = save_idx 
			LET scrn = save_scrn 
			SELECT * INTO pr_menu1.* FROM menu1 
			WHERE menu1_code = pa_menu1[idx].menu1_code 
			LET pa_menu1[idx].prosper_flag = pr_menu1.prosper_flag 
			LET pa_menu1[idx].name_text = pr_menu1.name_text 
			LET pa_menu1[idx].password_text = pr_menu1.password_text 
			LET pa_menu1[idx].security_ind = pr_menu1.security_ind 
			DISPLAY pa_menu1[idx].* TO sa_menu1[scrn].* 

			NEXT FIELD menu1_code 

		AFTER DELETE 
			LET id_flag = -1 
			DELETE FROM menu1 WHERE menu1_code = pr_menu1.menu1_code 
			DELETE FROM menu2 WHERE menu1_code = pr_menu1.menu1_code 
			DELETE FROM menu3 WHERE menu1_code = pr_menu1.menu1_code 

		BEFORE INSERT 
			LET save_idx = idx 
			LET save_scrn = scrn 
			CALL addor() 
			CLOSE WINDOW lev2 
			LET idx = save_idx 
			LET scrn = save_scrn 
			SELECT * INTO pr_menu1.* FROM menu1 
			WHERE menu1_code = pa_menu1[idx].menu1_code 
			LET pa_menu1[idx].prosper_flag = pr_menu1.prosper_flag 
			LET pa_menu1[idx].name_text = pr_menu1.name_text 
			LET pa_menu1[idx].password_text = pr_menu1.password_text 
			LET pa_menu1[idx].security_ind = pr_menu1.security_ind 
			DISPLAY pa_menu1[idx].* TO sa_menu1[scrn].* 

			NEXT FIELD menu1_code 

		ON KEY (control-w) 
			CALL kandoohelp("") 

	END INPUT 

	CLOSE WINDOW lev1 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN true 
	END IF 
END FUNCTION 


FUNCTION addor() 
	DEFINE l_msgresp LIKE language.yes_flag
	
	OPEN WINDOW lev2 with FORM "U105" 
	CALL windecoration_u("U105") 

	INITIALIZE pr_menu1.* TO NULL 
	LET pr_menu1.security_ind = "1" 
	DISPLAY BY NAME pr_menu1.security_ind 

	LET l_msgresp = kandoomsg("U",1520,"1") 
	#1520 Enter Level 1 Menu Details - ESC TO Continue
	INPUT BY NAME pr_menu1.menu1_code, 
	pr_menu1.name_text, 
	pr_menu1.prosper_flag, 
	pr_menu1.password_text, 
	pr_menu1.security_ind WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","U21","input-menu1-1") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		AFTER FIELD prosper_flag 
			DISPLAY BY NAME pr_menu1.prosper_flag 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 
			LET status = 0 
			LET id_flag = -1 
			LET err_flag = 0 
			IF (pr_menu1.menu1_code IS NOT null) THEN 
				SELECT * FROM menu1 
				WHERE menu1_code = pr_menu1.menu1_code 
				IF status != notfound THEN 
					LET l_msgresp = kandoomsg("U",9104,"") 
					#9104 RECORD already exists
					NEXT FIELD menu1_code 
				END IF 
				INSERT INTO menu1 VALUES (pr_menu1.*) 
				IF (status < 0) THEN 
					LET err_flag = -1 
				END IF 
			ELSE 
				LET err_flag = -1 
			END IF 
			IF (err_flag < 0) THEN 
				LET l_msgresp=kandoomsg("U",9125,"") 
				#U9125 An error has occurred.  Please re-enter informaiton
				LET err_flag = 0 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 
	END IF 
	LET l_msgresp = kandoomsg("U",1003,"") 
	#1003 " F1 TO add - F2 TO delete - RETURN on Line TO Edit
	INPUT ARRAY pa_menu2 WITHOUT DEFAULTS FROM sa_menu2.* 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","U21","input-arr-menu2-1") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		BEFORE ROW 
			INITIALIZE pr_menu2.* TO NULL 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			LET pr_menu2.menu2_code = pa_menu2[idx].menu2_code 
			LET pr_menu2.name_text = pa_menu2[idx].name_text 
			LET pr_menu2.password_text = pa_menu2[idx].password_text 
			LET pr_menu2.security_ind = pa_menu2[idx].security_ind 
		AFTER INSERT 
			IF pa_menu2[idx].menu2_code IS NOT NULL 
			AND pr_menu1.menu1_code IS NOT NULL THEN 
				LET pr_menu2.menu1_code = pr_menu1.menu1_code 
				LET pr_menu2.menu2_code = pa_menu2[idx].menu2_code 
				LET pr_menu2.name_text = pa_menu2[idx].name_text 
				LET pr_menu2.prosper_flag = "G" 
				LET pr_menu2.password_text = pa_menu2[idx].password_text 
				LET pr_menu2.security_ind = pa_menu2[idx].security_ind 
				LET status = 0 
				LET id_flag = -1 
				LET err_flag = 0 
				IF (pr_menu2.menu2_code IS NOT null) THEN 
					LET pr_menu2.menu1_code = pr_menu1.menu1_code 
					INSERT INTO menu2 VALUES (pr_menu2.*) 
					IF (status < 0) THEN 
						LET err_flag = -1 
					END IF 
				ELSE 
					LET err_flag = -1 
				END IF 
				IF (err_flag < 0) THEN 
					LET l_msgresp=kandoomsg("U",9125,"") 
					#U9125 An error has occurred.  Please re-enter informaiton
					LET err_flag = 0 
				END IF 
			END IF 
		AFTER ROW 
			IF (pa_menu2[idx].menu2_code IS NOT NULL 
			AND pr_menu1.menu1_code IS NOT null) 
			AND (pr_menu2.menu2_code != pa_menu2[idx].menu2_code 
			OR pr_menu2.name_text != pa_menu2[idx].name_text 
			OR pr_menu2.password_text != pa_menu2[idx].password_text 
			OR pr_menu2.security_ind != pa_menu2[idx].security_ind) THEN 
				UPDATE menu2 
				SET menu2_code = pa_menu2[idx].menu2_code, 
				name_text = pa_menu2[idx].name_text, 
				password_text = pa_menu2[idx].password_text, 
				security_ind = pa_menu2[idx].security_ind 
				WHERE menu2_code = pr_menu2.menu2_code AND 
				menu1_code = pr_menu1.menu1_code 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 
END FUNCTION 


FUNCTION changor()
	DEFINE l_msgresp LIKE language.yes_flag 
	
	OPEN WINDOW lev2 with FORM "U105" 
	CALL windecoration_u("U105") 

	SELECT * INTO pr_menu1.* FROM menu1 
	WHERE menu1.menu1_code = pr_menu1.menu1_code 
	DECLARE pl2 CURSOR FOR 
	SELECT * INTO pr_menu2.* FROM menu2 
	WHERE menu1_code = pr_menu1.menu1_code 
	AND menu2_code != "X" 
	ORDER BY menu2_code 
	LET idx = 0 
	LET cnt = 1 
	FOREACH pl2 
		LET idx = idx + 1 
		LET scrn = scr_line() 
		LET pa_menu2[idx].menu2_code = pr_menu2.menu2_code 
		LET pa_menu2[idx].name_text = pr_menu2.name_text 
		LET pa_menu2[idx].password_text = pr_menu2.password_text 
		LET pa_menu2[idx].security_ind = pr_menu2.security_ind 
		IF cnt <= 10 THEN 
			DISPLAY pr_menu2.menu2_code TO sa_menu2[cnt].menu2_code 

			DISPLAY pr_menu2.name_text TO sa_menu2[cnt].name_text 

			DISPLAY pr_menu2.password_text TO sa_menu2[cnt].password_text 

			DISPLAY pr_menu2.security_ind TO sa_menu2[cnt].security_ind 

			LET cnt = cnt + 1 
		END IF 
		IF idx >= 40 THEN 
			EXIT FOREACH 
		END IF 
	END FOREACH 

	CALL set_count(idx) 
	DISPLAY BY NAME pr_menu1.menu1_code 

	DISPLAY BY NAME pr_menu1.security_ind 

	LET l_msgresp = kandoomsg("U",1520,"1") 
	#1520 Enter Level 1 Menu Details - ESC TO Continue

	INPUT BY NAME pr_menu1.name_text, 
	pr_menu1.prosper_flag, 
	pr_menu1.password_text, 
	pr_menu1.security_ind WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","U21","input-menu1-security") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		AFTER FIELD prosper_flag 
			DISPLAY BY NAME pr_menu1.prosper_flag 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 
			IF pr_menu1.menu1_code IS NOT NULL THEN 
				UPDATE menu1 
				SET * = pr_menu1.* 
				WHERE menu1_code = pr_menu1.menu1_code 
			END IF 

		ON KEY (control-w) 
			CALL kandoohelp("") 

	END INPUT 
	###################

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 
	END IF 
	LET l_msgresp = kandoomsg("U",1003,"") 
	#1003 " F1 TO add - F2 TO delete - RETURN on Line TO Edit

	INPUT ARRAY pa_menu2 WITHOUT DEFAULTS FROM sa_menu2.* ATTRIBUTE(UNBUFFERED) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","U21","input-arr-menu2-2") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		BEFORE ROW 
			INITIALIZE pr_menu2.* TO NULL 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			LET pr_menu2.menu2_code = pa_menu2[idx].menu2_code 
			LET pr_menu2.name_text = pa_menu2[idx].name_text 
			LET pr_menu2.password_text = pa_menu2[idx].password_text 
			LET pr_menu2.security_ind = pa_menu2[idx].security_ind 

		ON ACTION "EDIT" 
			NEXT FIELD name_text 

		BEFORE FIELD name_text 
			LET store_idx = idx 
			LET store_scrn = scrn 

			CALL changor2() 

			CLOSE WINDOW lev3 

			LET idx = store_idx 
			LET scrn = store_scrn 

			SELECT * INTO pr_menu2.* FROM menu2 
			WHERE menu2_code = pa_menu2[idx].menu2_code 
			AND menu1_code = pr_menu1.menu1_code 

			LET pa_menu2[idx].menu2_code = pr_menu2.menu2_code 
			LET pa_menu2[idx].name_text = pr_menu2.name_text 
			LET pa_menu2[idx].password_text = pr_menu2.password_text 
			LET pa_menu2[idx].security_ind = pr_menu2.security_ind 
			DISPLAY pa_menu2[idx].* TO sa_menu2[scrn].* 

			NEXT FIELD menu2_code 

		BEFORE INSERT 
			LET store_idx = idx 
			LET store_scrn = scrn 

			CALL addor2() 
			CLOSE WINDOW lev3 

			LET idx = store_idx 
			LET scrn = store_scrn 

			SELECT * INTO pr_menu2.* FROM menu2 
			WHERE menu2_code = pa_menu2[idx].menu2_code 
			AND menu1_code = pr_menu1.menu1_code 
			LET pa_menu2[idx].menu2_code = pr_menu2.menu2_code 
			LET pa_menu2[idx].name_text = pr_menu2.name_text 
			LET pa_menu2[idx].password_text = pr_menu2.password_text 
			LET pa_menu2[idx].security_ind = pr_menu2.security_ind 
			DISPLAY pa_menu2[idx].* TO sa_menu2[scrn].* 

			NEXT FIELD menu2_code 

		AFTER DELETE 
			DELETE FROM menu2 
			WHERE menu2_code = pr_menu2.menu2_code 
			AND menu1_code = pr_menu1.menu1_code 

			DELETE FROM menu3 
			WHERE menu1_code = pr_menu1.menu1_code 
			AND menu2_code = pr_menu2.menu2_code 

			NEXT FIELD menu2_code 

		ON KEY (control-w) 
			CALL kandoohelp("") 

	END INPUT 
	#############################

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 

END FUNCTION 


FUNCTION addor2()
	DEFINE l_msgresp LIKE language.yes_flag  
	DEFINE pr_temp_text CHAR(15) 

	OPEN WINDOW lev3 with FORM "U106" 
	CALL windecoration_u("U106") 

	INITIALIZE pr_menu2.* TO NULL 
	LET pr_menu2.security_ind = "1" 
	DISPLAY BY NAME pr_menu2.security_ind 

	LET l_msgresp = kandoomsg("U",1520,"2") 
	#1520 Enter Level 2 Menu Details - ESC TO Continue
	INPUT BY NAME pr_menu2.menu2_code, 
	pr_menu2.name_text, 
	pr_menu2.prosper_flag, 
	pr_menu2.password_text WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","U21","input-menu2-2") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		AFTER FIELD prosper_flag 
			DISPLAY BY NAME pr_menu2.prosper_flag 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 
			LET status = 0 
			LET id_flag = -1 
			LET err_flag = 0 
			IF (pr_menu2.menu2_code IS NOT null) THEN 
				LET pr_menu2.menu1_code = pr_menu1.menu1_code 
				SELECT * FROM menu2 
				WHERE menu1_code = pr_menu2.menu1_code 
				AND menu2_code = pr_menu2.menu2_code 
				IF status != notfound THEN 
					LET l_msgresp = kandoomsg("U",9104,"") 
					#9104 RECORD already exists
					NEXT FIELD menu2_code 
				END IF 
				INSERT INTO menu2 VALUES (pr_menu2.*) 
				IF (status < 0) THEN 
					LET err_flag = -1 
				END IF 
			ELSE 
				LET err_flag = -1 
			END IF 
			IF (err_flag < 0) THEN 
				LET l_msgresp=kandoomsg("U",9125,"") 
				#U9125 An error has occurred.  Please re-enter informaiton
				LET err_flag = 0 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 
	END IF 
	LET l_msgresp = kandoomsg("U",1003,"") 
	#1003 " F1 TO add - F2 TO delete - RETURN on Line TO Edit
	INPUT ARRAY pa_menu3 WITHOUT DEFAULTS FROM sa_menu3.* 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","U21","input-arr-menu3-1") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		BEFORE ROW 
			INITIALIZE pr_menu3.* TO NULL 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			LET pr_menu3.menu3_code = pa_menu3[idx].menu3_code 
			LET pr_menu3.name_text = pa_menu3[idx].name_text 
			LET pr_menu3.password_text = pa_menu3[idx].password_text 
			LET pr_menu3.security_ind = pa_menu3[idx].security_ind 
			LET pr_menu3.run_text = pa_menu3[idx].run_text 
		BEFORE FIELD run_text 
			IF pa_menu3[idx].run_text IS NULL THEN 
				LET pa_menu3[idx].run_text = pr_menu1.menu1_code, 
				pr_menu2.menu2_code, 
				pa_menu3[idx].menu3_code,".4gi" 
				DISPLAY pa_menu3[idx].run_text TO sa_menu3[scrn].run_text 

			END IF 
		AFTER FIELD run_text 
			IF pa_menu3[idx].run_text IS NOT NULL THEN 
				LET pr_temp_text = pa_menu3[idx].run_text[1,3] 
				SELECT unique 1 FROM menu4 
				WHERE menu_code = pr_temp_text 
				IF status = notfound THEN 
					LET l_msgresp=kandoomsg("U",7028,"") 
					#U7028 This IS NOT a standard installation...
				END IF 
			END IF 
		AFTER INSERT 
			IF pa_menu3[idx].menu3_code IS NOT NULL 
			AND pr_menu2.menu2_code IS NOT NULL 
			AND pr_menu1.menu1_code IS NOT NULL THEN 
				LET pr_menu3.menu2_code = pr_menu2.menu2_code 
				LET pr_menu3.menu1_code = pr_menu1.menu1_code 
				LET pr_menu3.menu3_code = pa_menu3[idx].menu3_code 
				LET pr_menu3.name_text = pa_menu3[idx].name_text 
				LET pr_menu3.prosper_code = "G" 
				LET pr_menu3.password_text = pa_menu3[idx].password_text 
				LET pr_menu3.security_ind = pa_menu3[idx].security_ind 
				LET pr_menu3.run_text = pa_menu3[idx].run_text 
				LET status = 0 
				LET id_flag = -1 
				LET err_flag = 0 
				IF (pr_menu3.menu3_code IS NOT null) THEN 
					INSERT INTO menu3 VALUES (pr_menu3.*) 
					IF (status < 0) THEN 
						LET err_flag = -1 
					END IF 
				ELSE 
					LET err_flag = -1 
				END IF 
				IF (err_flag < 0) THEN 
					LET l_msgresp=kandoomsg("U",9125,"") 
					#U9125 An error has occurred.  Please re-enter informaiton
					LET err_flag = 0 
				END IF 
			END IF 
		AFTER ROW 
			IF pa_menu3[idx].security_ind IS NULL THEN 
				LET pa_menu3[idx].security_ind = 1 
			END IF 
			IF (pa_menu3[idx].menu3_code IS NOT NULL 
			AND pr_menu2.menu2_code IS NOT NULL 
			AND pr_menu1.menu1_code IS NOT null) THEN 
				UPDATE menu3 
				SET menu3_code = pa_menu3[idx].menu3_code, 
				name_text = pa_menu3[idx].name_text, 
				password_text = pa_menu3[idx].password_text, 
				security_ind = pa_menu3[idx].security_ind, 
				run_text = pa_menu3[idx].run_text 
				WHERE menu3_code = pr_menu3.menu3_code 
				AND menu1_code = pr_menu1.menu1_code 
				AND menu2_code = pr_menu2.menu2_code 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	UPDATE menu2 
	SET security_ind = (SELECT (min (menu3.security_ind)) FROM menu3 
	WHERE menu1_code = pr_menu1.menu1_code 
	AND menu2_code = pr_menu2.menu2_code) 
	WHERE menu2_code = pr_menu2.menu2_code 
	AND menu1_code = pr_menu1.menu1_code 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 
END FUNCTION 


FUNCTION changor2() 
	DEFINE pr_temp_text CHAR(15) 
	DEFINE l_msgresp LIKE language.yes_flag 
	
	OPEN WINDOW lev3 with FORM "U106" 
	CALL windecoration_u("U106") 

	SELECT * INTO pr_menu2.* FROM menu2 
	WHERE menu2.menu2_code = pr_menu2.menu2_code 
	AND menu2.menu1_code = pr_menu1.menu1_code 
	DECLARE pl3 CURSOR FOR 
	SELECT * INTO pr_menu3.* FROM menu3 
	WHERE menu1_code = pr_menu1.menu1_code 
	AND menu2_code = pr_menu2.menu2_code 
	ORDER BY menu3_code 
	LET idx = 0 
	LET cnt = 1 

	FOREACH pl3 
		LET idx = idx + 1 
		LET scrn = scr_line() 
		LET pa_menu3[idx].menu3_code = pr_menu3.menu3_code 
		LET pa_menu3[idx].name_text = pr_menu3.name_text 
		LET pa_menu3[idx].password_text = pr_menu3.password_text 
		LET pa_menu3[idx].security_ind = pr_menu3.security_ind 
		LET pa_menu3[idx].run_text = pr_menu3.run_text 
		IF cnt <= 10 THEN 
			DISPLAY pr_menu3.menu3_code TO sa_menu3[cnt].menu3_code 

			DISPLAY pr_menu3.name_text TO sa_menu3[cnt].name_text 

			DISPLAY pr_menu3.password_text TO sa_menu3[cnt].password_text 

			DISPLAY pr_menu3.security_ind TO sa_menu3[cnt].security_ind 

			DISPLAY pr_menu3.run_text TO sa_menu3[cnt].run_text 

			LET cnt = cnt + 1 
		END IF 

		IF idx >= 40 THEN 
			EXIT FOREACH 
		END IF 
	END FOREACH 

	CALL set_count(idx) 

	DISPLAY BY NAME pr_menu2.menu2_code 

	DISPLAY BY NAME pr_menu2.security_ind 

	LET l_msgresp = kandoomsg("U",1520,"2") 
	#1520 Enter Level 2 Menu Details - ESC TO Continue

	INPUT BY NAME pr_menu2.name_text, 
	pr_menu2.prosper_flag, 
	pr_menu2.password_text WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","U21","input-menu2-name") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		AFTER FIELD prosper_flag 
			DISPLAY BY NAME pr_menu2.prosper_flag 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 

			IF pr_menu2.menu2_code IS NOT NULL THEN 
				UPDATE menu2 
				SET * = pr_menu2.* 
				WHERE menu2_code = pr_menu2.menu2_code 
				AND menu1_code = pr_menu1.menu1_code 
			END IF 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	######################
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 
	END IF 
	LET l_msgresp = kandoomsg("U",1003,"") 
	#1003 " F1 TO add - F2 TO delete - RETURN on Line TO Edit

	INPUT ARRAY pa_menu3 WITHOUT DEFAULTS FROM sa_menu3.* ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","U21","input-arr-menu3-2") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		BEFORE ROW 
			INITIALIZE pr_menu3.* TO NULL 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			LET pr_menu3.menu3_code = pa_menu3[idx].menu3_code 
			LET pr_menu3.name_text = pa_menu3[idx].name_text 
			LET pr_menu3.password_text = pa_menu3[idx].password_text 
			LET pr_menu3.security_ind = pa_menu3[idx].security_ind 
			LET pr_menu3.run_text = pa_menu3[idx].run_text 

		BEFORE FIELD run_text 
			IF pa_menu3[idx].run_text IS NULL THEN 
				LET pa_menu3[idx].run_text = pr_menu1.menu1_code, 
				pr_menu2.menu2_code, 
				pa_menu3[idx].menu3_code,".4gi" 
				DISPLAY pa_menu3[idx].run_text TO sa_menu3[scrn].run_text 

			END IF 

		AFTER FIELD run_text 
			IF pa_menu3[idx].run_text IS NOT NULL THEN 
				LET pr_temp_text = pa_menu3[idx].run_text[1,3] 
				SELECT unique 1 FROM menu4 
				WHERE menu_code = pr_temp_text 
				IF status = notfound THEN 
					LET l_msgresp=kandoomsg("U",7028,"") 
					#U7028 This IS NOT a standard instalation...
				END IF 
			END IF 

		AFTER INSERT 
			IF pa_menu3[idx].menu3_code IS NOT NULL THEN 
				LET pr_menu3.menu3_code = pa_menu3[idx].menu3_code 
				LET pr_menu3.menu1_code = pr_menu1.menu1_code 
				LET pr_menu3.menu2_code = pr_menu2.menu2_code 
				LET pr_menu3.name_text = pa_menu3[idx].name_text 
				LET pr_menu3.prosper_code = "G" 
				LET pr_menu3.password_text = pa_menu3[idx].password_text 
				LET pr_menu3.security_ind = pa_menu3[idx].security_ind 
				LET pr_menu3.run_text = pa_menu3[idx].run_text 
				INSERT INTO menu3 VALUES (pr_menu3.*) 
			END IF 

		AFTER ROW 
			IF (pr_menu1.menu1_code IS NOT NULL 
			AND pr_menu2.menu2_code IS NOT NULL 
			AND pa_menu3[idx].menu3_code IS NOT null) THEN 
				UPDATE menu3 
				SET menu3_code = pa_menu3[idx].menu3_code, 
				name_text = pa_menu3[idx].name_text, 
				password_text = pa_menu3[idx].password_text, 
				security_ind = pa_menu3[idx].security_ind, 
				run_text = pa_menu3[idx].run_text 
				WHERE menu3_code = pr_menu3.menu3_code 
				AND menu1_code = pr_menu1.menu1_code 
				AND menu2_code = pr_menu2.menu2_code 
			END IF 

		AFTER DELETE 
			DELETE FROM menu3 
			WHERE menu3_code = pr_menu3.menu3_code 
			AND menu1_code = pr_menu1.menu1_code 
			AND menu2_code = pr_menu2.menu2_code 

		ON KEY (control-w) 
			CALL kandoohelp("") 

	END INPUT 
	###############################

	UPDATE menu2 
	SET security_ind = (SELECT min (menu3.security_ind) FROM menu3 
	WHERE menu1_code = pr_menu1.menu1_code 
	AND menu2_code = pr_menu2.menu2_code) 
	WHERE menu2_code = pr_menu2.menu2_code 
	AND menu1_code = pr_menu1.menu1_code 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 
END FUNCTION 
