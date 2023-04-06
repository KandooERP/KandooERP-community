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
# \brief module - U1D.4gl
# Purpose - Userref Table Maintainence Program
#           Adds, deletes AND maintains possible VALUES
#           of user defined prompts.
#
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../utility/U_UT_GLOBALS.4gl" 

GLOBALS 
	DEFINE pa_userref array[250] OF RECORD 
		source_ind LIKE userref.source_ind, 
		ref_ind LIKE userref.ref_ind, 
		ref_code LIKE userref.ref_code, 
		ref_desc_text LIKE userref.ref_desc_text 
	END RECORD 
	DEFINE arr_size SMALLINT 
	DEFINE formname CHAR(15) 
	DEFINE pv_source_ind CHAR(1) 
	DEFINE pv_ref_ind CHAR(1) 
	DEFINE ans CHAR(1)
END GLOBALS 


###################################################################
# MAIN
#
#
###################################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("U1D") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_u_ut() #init utility module 

	OPEN WINDOW u138 with FORM "U138" 
	CALL windecoration_u("U138") 


	WHILE select_refs() 
		CALL scan_refs(arr_size) 
	END WHILE 

	CLOSE WINDOW u138 

END MAIN 



FUNCTION select_refs() 
	DEFINE 
	pr_userref RECORD LIKE userref.*, 
	where_text CHAR(100), 
	query_text CHAR(200), 
	idx SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag
	
	CLEAR FORM 
	LET l_msgresp = kandoomsg("U",1001,"") 
	IF num_args() > 0 THEN 
		LET pv_source_ind = arg_val(1) 
		LET pv_ref_ind = arg_val(2) 

		DISPLAY pv_source_ind, pv_ref_ind 
		TO source_ind, ref_ind 

		CONSTRUCT BY NAME where_text ON ref_code, 
		ref_desc_text 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","U1D","construct-userref-1") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 


		LET query_text = "SELECT * ", 
		"FROM userref ", 
		"WHERE cmpy_code = \"", glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND source_ind = \"", arg_val(1),"\" ", 
		"AND ref_ind = \"", arg_val(2),"\" ", 
		"AND ", where_text clipped," ", 
		"ORDER BY cmpy_code,", 
		"source_ind,", 
		"ref_ind,", 
		"ref_code" 
	ELSE 
		CONSTRUCT BY NAME where_text ON source_ind, 
		ref_ind, 
		ref_code, 
		ref_desc_text 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","U1D","construct-userref-2") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 


		LET query_text = "SELECT * ", 
		"FROM userref ", 
		"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND ", where_text clipped," ", 
		"ORDER BY cmpy_code,", 
		"source_ind,", 
		"ref_ind,", 
		"ref_code" 
	END IF 


	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

	PREPARE s_userref FROM query_text 
	DECLARE c_userref CURSOR FOR s_userref 
	LET idx = 0 

	FOREACH c_userref INTO pr_userref.* 
		LET idx = idx + 1 
		LET pa_userref[idx].source_ind = pr_userref.source_ind 
		LET pa_userref[idx].ref_ind = pr_userref.ref_ind 
		LET pa_userref[idx].ref_code = pr_userref.ref_code 
		LET pa_userref[idx].ref_desc_text = pr_userref.ref_desc_text 

		IF idx = 250 THEN 
			LET l_msgresp = kandoomsg("U",6100,idx) 
			SLEEP 2 
			EXIT FOREACH 
		END IF 
	END FOREACH 
	LET l_msgresp = kandoomsg("U",9113,idx) 
	LET arr_size = idx 
	RETURN true 

END FUNCTION 



FUNCTION scan_refs(idx) 

	DEFINE pr_userref RECORD LIKE userref.*, 
	idx, scrn, 
	cnt, 
	delete_flag, 
	insert_flag SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag
	
	CALL set_count(idx) 
	LET delete_flag = false 
	LET insert_flag = false 

	LET l_msgresp = kandoomsg("U",1004,"") 
	INPUT ARRAY pa_userref WITHOUT DEFAULTS FROM sr_userref.* 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","U1D","input-arr-userref") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 

			LET pr_userref.source_ind = pa_userref[idx].source_ind 
			LET pr_userref.ref_ind = pa_userref[idx].ref_ind 
			LET pr_userref.ref_code = pa_userref[idx].ref_code 
			LET pr_userref.ref_desc_text = pa_userref[idx].ref_desc_text 





			LET delete_flag = false 

			IF pa_userref[idx].source_ind IS NULL THEN 
				LET insert_flag = true 
			END IF 

		BEFORE INSERT 
			LET insert_flag = true 

			IF num_args() > 0 THEN 
				LET pa_userref[idx].source_ind = arg_val(1) 
				LET pa_userref[idx].ref_ind = arg_val(2) 
				DISPLAY pa_userref[idx].* TO sr_userref[scrn].* 
			END IF 


		BEFORE DELETE 
			LET delete_flag = true 


		ON KEY (accept) 
			EXIT INPUT 

		BEFORE FIELD source_ind 
			IF num_args() > 0 THEN 
				NEXT FIELD ref_code 
			END IF 

		AFTER FIELD source_ind 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 

			IF pa_userref[idx].source_ind IS NULL THEN 
				IF idx = arr_count() AND 
				fgl_lastkey() = fgl_keyval("up") THEN 
					# do nothing
				ELSE 
					LET l_msgresp = kandoomsg("U",9102,"") 
					NEXT FIELD source_ind 
				END IF 
			ELSE 
				IF fgl_lastkey() = fgl_keyval("down") AND 
				pa_userref[idx].ref_ind IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 
					NEXT FIELD ref_ind 
				END IF 
			END IF 

		BEFORE FIELD ref_ind 
			IF num_args() > 0 THEN 
				NEXT FIELD ref_code 
			END IF 

		AFTER FIELD ref_ind 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 

			IF pa_userref[idx].ref_ind IS NULL THEN 
				IF idx = arr_count() AND 
				fgl_lastkey() = fgl_keyval("up") THEN 
					# do nothing
				ELSE 
					LET l_msgresp = kandoomsg("U",9102,"") 
					NEXT FIELD ref_ind 
				END IF 
			ELSE 
				IF fgl_lastkey() = fgl_keyval("down") AND 
				pa_userref[idx].ref_code IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 
					NEXT FIELD ref_code 
				END IF 
			END IF 

		AFTER FIELD ref_code 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 

			IF pa_userref[idx].ref_code IS NULL THEN 
				IF idx = arr_count() AND 
				fgl_lastkey() = fgl_keyval("up") THEN 
					# do nothing
				ELSE 
					LET l_msgresp = kandoomsg("U",9102,"") 
					NEXT FIELD ref_code 
				END IF 


			ELSE 
				IF insert_flag OR 
				pa_userref[idx].source_ind != pr_userref.source_ind OR 
				pa_userref[idx].ref_ind != pr_userref.ref_ind OR 
				pa_userref[idx].ref_code != pr_userref.ref_code THEN 

					IF test_exists(pa_userref[idx].source_ind, 
					pa_userref[idx].ref_ind, 
					pa_userref[idx].ref_code) THEN 
						LET l_msgresp = kandoomsg("U",9104,"") 
						NEXT FIELD source_ind 
					END IF 
				END IF 
			END IF 

		AFTER DELETE 
			DELETE FROM userref 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND source_ind = pr_userref.source_ind 
			AND ref_ind = pr_userref.ref_ind 
			AND ref_code = pr_userref.ref_code 

		AFTER ROW 
			IF pa_userref[idx].source_ind IS NOT NULL AND 
			pa_userref[idx].ref_ind IS NOT NULL AND 
			pa_userref[idx].ref_code IS NOT NULL THEN 

				IF NOT delete_flag THEN 
					IF insert_flag THEN 
						IF test_exists(pa_userref[idx].source_ind, 
						pa_userref[idx].ref_ind, 
						pa_userref[idx].ref_code) THEN 
							LET l_msgresp = kandoomsg("U",9104,"") 
							NEXT FIELD source_ind 
						ELSE 
							INSERT INTO userref 
							VALUES (glob_rec_kandoouser.cmpy_code, 
							pa_userref[idx].source_ind, 
							pa_userref[idx].ref_code, 
							pa_userref[idx].ref_desc_text, 
							pa_userref[idx].ref_ind) 
						END IF 
					ELSE 

						IF pa_userref[idx].source_ind != pr_userref.source_ind OR 
						pa_userref[idx].ref_ind != pr_userref.ref_ind OR 
						pa_userref[idx].ref_code != pr_userref.ref_code OR 
						pa_userref[idx].ref_desc_text != 
						pr_userref.ref_desc_text THEN 

							IF pa_userref[idx].source_ind != pr_userref.source_ind 
							OR pa_userref[idx].ref_ind != pr_userref.ref_ind 
							OR pa_userref[idx].ref_code != pr_userref.ref_code THEN 

								IF test_exists(pa_userref[idx].source_ind, 
								pa_userref[idx].ref_ind, 
								pa_userref[idx].ref_code) THEN 
									LET l_msgresp = kandoomsg("U",9104,"") 
									NEXT FIELD source_ind 
								END IF 
							END IF 

							UPDATE userref 
							SET source_ind = pa_userref[idx].source_ind, 
							ref_code = pa_userref[idx].ref_code, 
							ref_desc_text = pa_userref[idx].ref_desc_text, 
							ref_ind = pa_userref[idx].ref_ind 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND source_ind = pr_userref.source_ind 
							AND ref_ind = pr_userref.ref_ind 
							AND ref_code = pr_userref.ref_code 
						END IF 
					END IF 
				END IF 
			END IF 

			LET insert_flag = false 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 

	LET int_flag = false 
	LET quit_flag = false 

END FUNCTION 


FUNCTION test_exists(pr_source, pr_ref_ind, pr_ref_code) 

	DEFINE pr_source LIKE userref.source_ind, 
	pr_ref_ind LIKE userref.ref_ind, 
	pr_ref_code LIKE userref.ref_code, 
	cnt SMALLINT 

	LET cnt = 0 

	SELECT count(*) 
	INTO cnt 
	FROM userref 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND source_ind = pr_source 
	AND ref_ind = pr_ref_ind 
	AND ref_code = pr_ref_code 

	RETURN cnt 

END FUNCTION 


