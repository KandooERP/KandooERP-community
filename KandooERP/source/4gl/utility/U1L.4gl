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

	Source code beautified by beautify.pl on 2020-01-03 18:54:42	$Id: $
}
{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module U1L allows the user TO maintain Language codes
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../utility/U_UT_GLOBALS.4gl" 

###################################################################
# MAIN
#
#
###################################################################
MAIN 

	CALL setModuleId("U1L") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_u_ut() #init utility module 

	WHILE true 
		CALL get_info() 
		CLOSE WINDOW u131 
	END WHILE 
END MAIN 


###################################################################
# FUNCTION get_info()
#
#
###################################################################
FUNCTION get_info() 
	DEFINE l_rec_language RECORD LIKE language.* 
	DEFINE l_arr_rec_language DYNAMIC ARRAY OF RECORD LIKE language.* 
	DEFINE idx SMALLINT 
	DEFINE id_flag SMALLINT 
	DEFINE cnt SMALLINT 
	DEFINE l_err_flag SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag
	
	DECLARE c_language CURSOR FOR 
	SELECT * FROM language 
	ORDER BY language_code 
	LET idx = 1 
	FOREACH c_language INTO l_arr_rec_language[idx].* 
		LET idx = idx + 1 
		IF idx > 200 THEN 
			LET l_msgresp = kandoomsg("U",6100,idx) 
			EXIT FOREACH 
		END IF 
	END FOREACH 
	LET l_msgresp = kandoomsg("U",9113,idx) 
	LET idx = idx - 1 
	CALL set_count(idx) 

	OPEN WINDOW u131 at 2,3 with FORM "U131" 
	CALL windecoration_u("U131") 

	LET l_msgresp = kandoomsg("U",1003,"") 
	#1003 F1 F2 ENTER on Line
	INPUT ARRAY l_arr_rec_language WITHOUT DEFAULTS FROM sr_language.* attribute(UNBUFFERED, append ROW = false, auto append = false) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","U1L","input-arr-language") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		BEFORE ROW 
			LET idx = arr_curr() 
			#         LET scrn = scr_line()
			LET l_rec_language.language_code = l_arr_rec_language[idx].language_code 
			LET l_rec_language.language_text = l_arr_rec_language[idx].language_text 
			LET l_rec_language.yes_flag = l_arr_rec_language[idx].yes_flag 
			LET l_rec_language.no_flag = l_arr_rec_language[idx].no_flag 
			LET id_flag = 0 

		BEFORE INSERT 
			INITIALIZE l_rec_language.* TO NULL 

		AFTER FIELD language_code 
			IF (l_arr_rec_language[idx].language_code IS null) THEN 
				IF (l_arr_rec_language[idx].language_text IS NOT null) THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 
					NEXT FIELD language_code 
				END IF 
			ELSE 
				IF (l_arr_rec_language[idx].language_code != l_rec_language.language_code 
				OR l_rec_language.language_code IS null) THEN 
					SELECT count(*) INTO cnt FROM language 
					WHERE language_code = l_arr_rec_language[idx].language_code 
					IF (cnt != 0) THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						NEXT FIELD language_code 
					END IF 
				END IF 
			END IF 

		AFTER FIELD yes_flag 
			IF l_arr_rec_language[idx].yes_flag IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				NEXT FIELD yes_flag 
			END IF 

		AFTER FIELD no_flag 
			IF l_arr_rec_language[idx].no_flag IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				NEXT FIELD no_flag 
			END IF 
			IF l_arr_rec_language[idx].yes_flag = l_arr_rec_language[idx].no_flag THEN 
				LET l_msgresp = kandoomsg("U",9029,"") 
				#9029 " Positive AND negative response must be different "
				NEXT FIELD yes_flag 
			END IF 

		AFTER INSERT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 

			LET status = 0 
			LET id_flag = -1 
			LET l_err_flag = 0 
			IF (l_arr_rec_language[idx].language_code IS NOT null) THEN 
				WHENEVER ERROR CONTINUE 
				INSERT INTO language VALUES (l_arr_rec_language[idx].*) 
				IF (status < 0) THEN 
					LET l_err_flag = -1 
				END IF 
				WHENEVER ERROR stop 
			ELSE 
				LET l_err_flag = -1 
			END IF 
			IF (l_err_flag < 0) THEN 
				LET l_msgresp = kandoomsg("L",9003,"") 
				#9003 " An error has occurred, enter information again"
				#            CLEAR sr_language[scrn].*
				LET l_err_flag = 0 
			END IF 

		AFTER DELETE 
			LET id_flag = -1 
			DELETE FROM language 
			WHERE language_code = l_rec_language.language_code 

		AFTER ROW 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 

			IF (l_arr_rec_language[idx].language_code IS NULL 
			AND l_arr_rec_language[idx].language_text IS null) THEN 
				LET id_flag = -1 
			END IF 

			IF (id_flag = 0 
			AND (l_rec_language.language_code != l_arr_rec_language[idx].language_code 
			OR l_rec_language.language_text != l_arr_rec_language[idx].language_text 
			OR l_rec_language.yes_flag != l_arr_rec_language[idx].yes_flag 
			OR l_rec_language.no_flag != l_arr_rec_language[idx].no_flag)) THEN 
				UPDATE language SET * = l_arr_rec_language[idx].* 
				WHERE language_code = l_rec_language.language_code 
			END IF 

			IF (id_flag = 0 
			AND (l_arr_rec_language[idx].language_code IS NOT NULL 
			AND l_rec_language.language_text IS null)) THEN 
				WHENEVER ERROR CONTINUE 
				INSERT INTO language VALUES (l_arr_rec_language[idx].*) 
				IF (status < 0) THEN 
					LET l_msgresp = kandoomsg("L",9003,"") 
					#9903 "An error has occurred, enter information again"
					INITIALIZE l_arr_rec_language[idx].* TO NULL 
					#               CLEAR sr_language[scrn].*
				END IF 
				WHENEVER ERROR stop 
			END IF 

			#      ON KEY (control-w)
			#         CALL kandoohelp("")

	END INPUT 

	IF int_flag OR quit_flag THEN 
		EXIT program 
	END IF 
END FUNCTION 


