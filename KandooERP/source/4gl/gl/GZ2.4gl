# Journal Types Maintenance
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

	Source code beautified by beautify.pl on 2020-01-03 14:29:00	$Id: $
}



{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module GZ2 allows the user TO maintain Journals FOR each company

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 

GLOBALS 
	DEFINE doit CHAR(2) 
END GLOBALS 

############################################################
# MAIN
#
#
############################################################
MAIN 

	CALL setModuleId("GZ2") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
--	CALL init_g_gl() #init g/gl general ledger module 


	LET doit = "Y" 
	WHILE doit = "Y" 
		CALL get_info() 
		CLOSE WINDOW wg124 
	END WHILE 
END MAIN 



############################################################
# FUNCTION get_info()
#
#
############################################################
FUNCTION get_info() 
	DEFINE l_rec_journal RECORD LIKE journal.* 
	DEFINE l_arr_rec_journal array[250] OF 
	RECORD 
		jour_code LIKE journal.jour_code, 
		desc_text LIKE journal.desc_text, 
		gl_flag LIKE journal.gl_flag 
	END RECORD 
	DEFINE idx SMALLINT 
	DEFINE id_flag SMALLINT 
	DEFINE cnt SMALLINT 
	DEFINE err_flag SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	DECLARE c_journal CURSOR FOR 
	SELECT * INTO l_rec_journal.* FROM journal # l_rec_journal RECORD LIKE journal.*, 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	ORDER BY jour_code 

	LET idx = 0 
	FOREACH c_journal 
		LET idx = idx + 1 
		LET l_arr_rec_journal[idx].jour_code = l_rec_journal.jour_code 
		LET l_arr_rec_journal[idx].desc_text = l_rec_journal.desc_text 
		LET l_arr_rec_journal[idx].gl_flag = l_rec_journal.gl_flag 
		#DISPLAY "l_rec_journal.jour_code=", l_rec_journal.jour_code
		#DISPLAY "l_arr_rec_journal[idx].jour_code=", l_arr_rec_journal[idx].jour_code
		#DISPLAY "l_rec_journal.desc_text=", l_rec_journal.desc_text
		#DISPLAY "l_arr_rec_journal[idx].desc_text=", l_arr_rec_journal[idx].desc_text
		#DISPLAY "l_rec_journal.gl_flag=", l_rec_journal.gl_flag
		#DISPLAY "l_arr_rec_journal[idx].gl_flag=", l_arr_rec_journal[idx].gl_flag
	END FOREACH 
	CALL set_count(idx) 

	OPEN WINDOW wg124 with FORM "G124" 
	CALL windecoration_g("G124") 

	LET l_msgresp = kandoomsg("A",1003,"") 
	#1003 "F1 TO add, RETURN on line TO change, F2 TO delete"
	INPUT ARRAY l_arr_rec_journal WITHOUT DEFAULTS FROM sr_journal.* attributes(UNBUFFERED, append ROW = false, auto append = false) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GZ2","journalList") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		BEFORE ROW 
			LET idx = arr_curr() 
			#LET scrn = scr_line()
			LET l_rec_journal.jour_code = l_arr_rec_journal[idx].jour_code 
			LET l_rec_journal.desc_text = l_arr_rec_journal[idx].desc_text 
			LET l_rec_journal.gl_flag = l_arr_rec_journal[idx].gl_flag 
			LET id_flag = 0 

		AFTER FIELD jour_code 
			IF (l_arr_rec_journal[idx].jour_code IS null) THEN 
				IF (l_arr_rec_journal[idx].desc_text IS NOT null) THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD jour_code 
				END IF 
			ELSE 
				IF (l_arr_rec_journal[idx].jour_code != l_rec_journal.jour_code 
				OR l_rec_journal.jour_code IS null) THEN 
					SELECT count(*) INTO cnt FROM journal 
					WHERE jour_code = l_arr_rec_journal[idx].jour_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF (cnt != 0) THEN 
						LET l_msgresp = kandoomsg("U",9104,"") 
						#9104 This RECORD already exists
						NEXT FIELD jour_code 
					END IF 
				END IF 
			END IF 

		AFTER FIELD gl_flag 
			IF l_arr_rec_journal[idx].gl_flag = "N" 
			OR l_arr_rec_journal[idx].gl_flag = "Y" THEN 
			ELSE 
				LET l_msgresp = kandoomsg("U",9103,"") 
				#9103 "Flag must be Y OR N"
				NEXT FIELD gl_flag 
			END IF 

		BEFORE INSERT 
			INITIALIZE l_rec_journal.* TO NULL 
			OPTIONS INSERT KEY f36, 
			DELETE KEY f36 
		AFTER INSERT 
			OPTIONS INSERT KEY f1, 
			DELETE KEY f2 
			IF int_flag != 0 
			OR quit_flag != 0 THEN 
				EXIT PROGRAM 
			END IF 
			LET err_flag = 0 
			LET status = 0 
			LET id_flag = -1 
			LET l_rec_journal.cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF (l_arr_rec_journal[idx].jour_code IS NOT null) THEN 
				WHENEVER ERROR CONTINUE 
				INSERT INTO journal VALUES (l_rec_journal.cmpy_code, 
				l_arr_rec_journal[idx].jour_code, 
				l_arr_rec_journal[idx].desc_text, 
				l_arr_rec_journal[idx].gl_flag) 
				IF (status < 0) THEN 
					LET err_flag = -1 
				END IF 
				WHENEVER ERROR stop 
			ELSE 
				LET err_flag = -1 
			END IF 
			IF (err_flag < 0) THEN 
				LET l_msgresp = kandoomsg("L",9003,"") 
				#9003 "An error has occurred, enter information again"
				#CLEAR sr_journal[scrn].*
				LET err_flag = 0 
			END IF 

		AFTER DELETE 
			LET id_flag = -1 
			DELETE FROM journal 
			WHERE jour_code = l_rec_journal.jour_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 

		AFTER ROW 
			IF int_flag != 0 
			OR quit_flag != 0 THEN 
				EXIT PROGRAM 
			END IF 
			IF (l_arr_rec_journal[idx].jour_code IS NULL 
			AND l_arr_rec_journal[idx].desc_text IS NULL 
			AND l_arr_rec_journal[idx].gl_flag IS null) THEN 
				LET id_flag = -1 
			END IF 

			IF (id_flag = 0 
			AND (l_rec_journal.jour_code != l_arr_rec_journal[idx].jour_code 
			OR l_rec_journal.desc_text != l_arr_rec_journal[idx].desc_text 
			OR (l_rec_journal.gl_flag != l_arr_rec_journal[idx].gl_flag 
			OR l_rec_journal.gl_flag IS null))) THEN 

				#DISPLAY "l_rec_journal.jour_code=", l_rec_journal.jour_code
				#DISPLAY "l_arr_rec_journal[idx].jour_code=", l_arr_rec_journal[idx].jour_code
				#DISPLAY "l_rec_journal.desc_text=", l_rec_journal.desc_text
				#DISPLAY "l_arr_rec_journal[idx].desc_text=", l_arr_rec_journal[idx].desc_text
				#DISPLAY "l_rec_journal.gl_flag=", l_rec_journal.gl_flag
				#DISPLAY "l_arr_rec_journal[idx].gl_flag=", l_arr_rec_journal[idx].gl_flag
				#DISPLAY "l_rec_journal.cmpy_code=", l_rec_journal.cmpy_code

				UPDATE journal SET 
				jour_code = l_arr_rec_journal[idx].jour_code, 
				desc_text = l_arr_rec_journal[idx].desc_text, 
				gl_flag = l_arr_rec_journal[idx].gl_flag 
				WHERE jour_code = l_rec_journal.jour_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			END IF 

			IF (id_flag = 0 
			AND (l_arr_rec_journal[idx].jour_code IS NOT NULL 
			AND l_rec_journal.desc_text IS NULL 
			AND l_rec_journal.gl_flag IS null)) THEN 
				WHENEVER ERROR CONTINUE 
				LET l_rec_journal.cmpy_code = glob_rec_kandoouser.cmpy_code 

				#DISPLAY "l_rec_journal.jour_code=", l_rec_journal.jour_code
				#DISPLAY "l_arr_rec_journal[idx].jour_code=", l_arr_rec_journal[idx].jour_code
				#DISPLAY "l_rec_journal.desc_text=", l_rec_journal.desc_text
				#DISPLAY "l_arr_rec_journal[idx].desc_text=", l_arr_rec_journal[idx].desc_text
				#DISPLAY "l_rec_journal.gl_flag=", l_rec_journal.gl_flag
				#DISPLAY "l_arr_rec_journal[idx].gl_flag=", l_arr_rec_journal[idx].gl_flag
				#DISPLAY "l_rec_journal.cmpy_code=", l_rec_journal.cmpy_code

				INSERT INTO journal VALUES (l_rec_journal.cmpy_code, 
				l_arr_rec_journal[idx].jour_code, 
				l_arr_rec_journal[idx].desc_text, 
				l_arr_rec_journal[idx].gl_flag) 
				IF (status < 0) THEN 
					LET l_msgresp = kandoomsg("L",9003,"") 
					#9003 "An error has occurred, enter information again"
					INITIALIZE l_arr_rec_journal[idx].* TO NULL 
					#CLEAR sr_journal[scrn].*
				END IF 
				WHENEVER ERROR stop 
			END IF 

		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF (l_arr_rec_journal[idx].jour_code IS null) THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD jour_code 
				END IF 
				IF (l_arr_rec_journal[idx].desc_text IS null) THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD desc_text 
				END IF 
				IF l_arr_rec_journal[idx].gl_flag = "N" 
				OR l_arr_rec_journal[idx].gl_flag = "Y" THEN 
				ELSE 
					LET l_msgresp = kandoomsg("U",9103,"") 
					#9103 "Flag must be Y OR N"
					NEXT FIELD gl_flag 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 

	IF int_flag != 0 
	OR quit_flag != 0 THEN 
		EXIT PROGRAM 
	END IF 
END FUNCTION 


