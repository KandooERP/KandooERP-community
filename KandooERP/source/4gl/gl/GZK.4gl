# Payroll Load Parameters G456

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

	Source code beautified by beautify.pl on 2020-01-03 14:29:04	$Id: $
}




{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module GZK - allows the user TO maintain Payroll load Parameters

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 

GLOBALS 
	DEFINE glob_rec_payparms RECORD LIKE payparms.* 
	DEFINE glob_rec_journal RECORD LIKE journal.* 
	DEFINE glob_rec_coa RECORD LIKE coa.* 
END GLOBALS 


############################################################
# MAIN
############################################################
MAIN 
	DEFINE l_msgresp LIKE language.yes_flag 

	CALL setModuleId("GZK") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 

	CREATE temp TABLE t_temptable(templine CHAR(1)) with no LOG 

	OPEN WINDOW g456 with FORM "G456" 
	CALL windecoration_g("G456") 


	#Note: ONLY ONE payroll parameter per company - option add will be hidden
	#AFTER the first/only load parameter record was created
	MENU " Payroll Load Parameters" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","GZK","menu-payroll-load-paramenters") 

			IF disp_parm() THEN 
				HIDE option "ADD" 
			ELSE 
				HIDE option "Change" 
			END IF 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "New" #COMMAND "New" "Add Payroll Load Parameters"
			CALL add_parm() 
			IF disp_parm() THEN 
				HIDE option "ADD" 
				SHOW option "Change" 
			END IF 

		ON ACTION "EDIT" 	#COMMAND "EDIT" "Change Parameters"
			CALL change_parm() 
			LET l_msgresp = disp_parm() 

		ON ACTION "EXIT" #COMMAND KEY(interrupt,"E") "Exit" "RETURN TO Menus"
			EXIT MENU 
	END MENU 

	IF fgl_find_table("tempcoa") THEN
		DROP TABLE t_temptable 
	END IF

	CLOSE WINDOW g456 

END MAIN 

############################################################
# FUNCTION disp_parm()
#
#
############################################################
FUNCTION disp_parm() 

	SELECT * INTO glob_rec_payparms.* FROM payparms #huho error, returned more than one ROW 9.5.2017 
	WHERE payparms.cmpy_code = glob_rec_kandoouser.cmpy_code 

	IF status = NOTFOUND THEN 
		RETURN false 
	END IF 

	SELECT * INTO glob_rec_journal.* FROM journal 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND jour_code = glob_rec_payparms.jour_code 

	SELECT * INTO glob_rec_coa.* FROM coa 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND acct_code = glob_rec_payparms.clear_acct_code 

	DISPLAY BY NAME glob_rec_payparms.source_ind, 
	glob_rec_payparms.jour_code, 
	glob_rec_payparms.clear_acct_code, 
	glob_rec_payparms.path_name, 
	glob_rec_payparms.file_name 

	DISPLAY glob_rec_journal.desc_text TO jour_text 

	DISPLAY glob_rec_coa.desc_text TO coa_text 

	RETURN true 
END FUNCTION 


############################################################
# FUNCTION add_parm()
#
#
############################################################
FUNCTION add_parm() 

	INITIALIZE glob_rec_payparms.* TO NULL 

	IF input_parms() THEN 
		LET glob_rec_payparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
		INSERT INTO payparms VALUES (glob_rec_payparms.*) 
	END IF 
END FUNCTION 


############################################################
# FUNCTION change_parm()
#
#
############################################################
FUNCTION change_parm() 

	IF input_parms() THEN 
		LET glob_rec_payparms.cmpy_code = glob_rec_kandoouser.cmpy_code 

		UPDATE payparms 
		SET * = glob_rec_payparms.* 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

	END IF 

END FUNCTION 


############################################################
# FUNCTION input_parms()
############################################################
FUNCTION input_parms() 
	DEFINE l_path_name LIKE payparms.path_name 
	DEFINE l_temp_text CHAR(20) 
	DEFINE l_msgresp LIKE language.yes_flag 

	INPUT BY NAME glob_rec_payparms.source_ind, 
	glob_rec_payparms.jour_code, 
	glob_rec_payparms.clear_acct_code, 
	glob_rec_payparms.path_name, 
	glob_rec_payparms.file_name WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GZK","payParms1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null)
			 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (jour_code) 
			LET l_temp_text = show_jour(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET glob_rec_payparms.jour_code = l_temp_text 
				NEXT FIELD jour_code 
			END IF 

		ON ACTION "LOOKUP" infield (clear_acct_code) 
			LET l_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET glob_rec_payparms.clear_acct_code = l_temp_text 
				NEXT FIELD clear_acct_code 
			END IF 

		AFTER FIELD source_ind 
			IF glob_rec_payparms.source_ind IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				#9102  Value must be entered
				NEXT FIELD source_ind 
			END IF 

		AFTER FIELD jour_code 

			IF glob_rec_payparms.jour_code IS NULL THEN 
				LET l_msgresp = kandoomsg("G",9030,"") 
				#9030  Journal code must be entered
				NEXT FIELD jour_code 
			END IF 

			SELECT * INTO glob_rec_journal.* FROM journal 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND jour_code = glob_rec_payparms.jour_code 

			IF status = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("G",9029,"") 
				#9029  Journal code NOT found - Try Window
				NEXT FIELD jour_code 
			END IF 

			IF glob_rec_journal.gl_flag = "N" THEN 
				LET l_msgresp = kandoomsg("G",7015,"") 
				#7015  Journal NOT SET up FOR G.L
				NEXT FIELD jour_code 
			END IF 

			DISPLAY glob_rec_journal.desc_text TO jour_text 

		AFTER FIELD clear_acct_code 
			IF glob_rec_payparms.clear_acct_code IS NULL THEN 
				LET l_msgresp = kandoomsg("G",9032,"") 
				#9032  Account code must be entered
				NEXT FIELD clear_acct_code 
			END IF 

			SELECT * INTO glob_rec_coa.* FROM coa 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND acct_code = glob_rec_payparms.clear_acct_code 

			IF status = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("G",9112,"") 
				#9112  Account code NOT found - Try Window
				NEXT FIELD clear_acct_code 
			END IF 

			DISPLAY glob_rec_coa.desc_text TO coa_text 

		AFTER FIELD path_name 
			IF glob_rec_payparms.path_name IS NULL THEN 
				LET l_msgresp = kandoomsg("G",9034,"") 
				#9034  Directory must be entered
				NEXT FIELD path_name 
			END IF 

			WHENEVER ERROR CONTINUE 

			LET l_path_name = glob_rec_payparms.path_name clipped, "/tempfile" 

			UNLOAD TO l_path_name 
			SELECT * FROM t_temptable 
			IF status = -806 THEN 
				LET l_msgresp=kandoomsg("G",9140,"") 
				#9140 " Directory NOT found - Check AND re-enter"
				WHENEVER ERROR stop 
				NEXT FIELD path_name 
			END IF 
			WHENEVER ERROR stop 


		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 

				IF glob_rec_payparms.clear_acct_code IS NULL THEN 
					LET l_msgresp = kandoomsg("G",9032,"") 
					#9032  Account code must be entered
					NEXT FIELD clear_acct_code 
				END IF 

				IF glob_rec_payparms.path_name IS NULL THEN 
					LET l_msgresp = kandoomsg("G",9034,"") 
					#9034  Directory must be entered
					NEXT FIELD path_name 
				END IF 

			END IF 

		ON KEY (control-w) --help 
			CALL kandoohelp("") 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 

END FUNCTION 


