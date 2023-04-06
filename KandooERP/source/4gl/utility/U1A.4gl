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
# \brief module - U1A.4gl
# Purpose - syslocks maintenance program
#
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

	CALL setModuleId("U1A") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_u_ut() #init utility module 

	OPEN WINDOW u204 with FORM "U204" 
	CALL windecoration_u("U204") 

	CALL scan_syslocks() 
	CLOSE WINDOW u204 
END MAIN 


FUNCTION scan_syslocks() 
	DEFINE 
	pr_syslocks RECORD LIKE syslocks.*, 
	pa_syslocks array[1000] OF RECORD 
		scroll_flag CHAR(1), 
		module_code LIKE syslocks.module_code, 
		program_name_text LIKE syslocks.program_name_text, 
		retry_num LIKE syslocks.retry_num 
	END RECORD, 
	idx, scrn SMALLINT, 
	pr_mode CHAR(4) 
	DEFINE l_msgresp LIKE language.yes_flag
	
	DECLARE c_syslocks CURSOR FOR 
	SELECT * FROM syslocks 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	ORDER BY module_code, program_name_text 
	LET idx = 0 
	FOREACH c_syslocks INTO pr_syslocks.* 
		LET idx = idx + 1 
		LET pa_syslocks[idx].module_code = pr_syslocks.module_code 
		LET pa_syslocks[idx].program_name_text = pr_syslocks.program_name_text 
		LET pa_syslocks[idx].retry_num = pr_syslocks.retry_num 
		IF idx > 1000 THEN 
			LET l_msgresp = kandoomsg("U",6100,idx) 
			#6100 First idx records selected
			EXIT FOREACH 
		END IF 
	END FOREACH 
	LET l_msgresp = kandoomsg("U",9113,idx) 
	#9113 idx records selected
	IF idx = 0 THEN 
		LET idx = 1 
		INITIALIZE pa_syslocks[idx].* TO NULL 
	END IF 
	CALL set_count(idx) 
	LET l_msgresp = kandoomsg("U",1003,"") 
	#1003 "F1 TO add - F2 TO Delete - RETURN on line TO Edit"
	INPUT ARRAY pa_syslocks WITHOUT DEFAULTS FROM sr_syslocks.* 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","U1A","input-arr-syslocks") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		BEFORE FIELD scroll_flag 
			OPTIONS INSERT KEY f1, 
			DELETE KEY f2 
			LET scrn = scr_line() 
			LET idx = arr_curr() 
			DISPLAY pa_syslocks[idx].* TO sr_syslocks[scrn].* 

			LET pr_mode = MODE_CLASSIC_EDIT 
		BEFORE INSERT 
			INITIALIZE pr_syslocks.* TO NULL 
			LET pr_mode = MODE_CLASSIC_ADD
			NEXT FIELD module_code 
		AFTER FIELD scroll_flag 
			DISPLAY pa_syslocks[idx].* TO sr_syslocks[scrn].* 

			LET pr_syslocks.module_code = pa_syslocks[idx].module_code 
			LET pr_syslocks.program_name_text = pa_syslocks[idx].program_name_text 
			LET pr_syslocks.retry_num = pa_syslocks[idx].retry_num 
			IF fgl_lastkey() = fgl_keyval("down") 
			AND arr_curr() >= arr_count() THEN 
				LET l_msgresp = kandoomsg("U",9001,"") 
				#9001 There no more rows...
				NEXT FIELD scroll_flag 
			END IF 
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF pa_syslocks[idx+1].retry_num IS NULL 
				OR pa_syslocks[idx+1].retry_num = 0 THEN 
					LET l_msgresp = kandoomsg("U",9001,"") 
					#9001 There no more rows...
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
			IF fgl_lastkey() = fgl_keyval("nextpage") 
			AND (pa_syslocks[idx+15].retry_num IS NULL 
			OR pa_syslocks[idx+15].retry_num = 0) THEN 
				LET l_msgresp = kandoomsg("U",9001,"") 
				#9001 No more rows in this direction
				NEXT FIELD scroll_flag 
			END IF 
		BEFORE FIELD module_code 
			OPTIONS INSERT KEY f36, 
			DELETE KEY f36 
		AFTER FIELD module_code 
			CASE 
				WHEN fgl_lastkey() = fgl_keyval("accept") 
					OR fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("down") 
					IF fgl_lastkey() = fgl_keyval("accept") THEN 
						IF pa_syslocks[idx].retry_num IS NULL 
						OR pa_syslocks[idx].retry_num <= 0 THEN 
							LET l_msgresp = kandoomsg("U",9005,"0") 
							#9005 "You must enter a number greater than 0"
							NEXT FIELD retry_num 
						END IF 
						IF pa_syslocks[idx].retry_num > 10 THEN 
							LET l_msgresp = kandoomsg("U",6001,"") 
							#6001 "WARNING: Should enter less than 10 in retry"
						END IF 
						NEXT FIELD scroll_flag 
					END IF 
					NEXT FIELD program_name_text 
				WHEN fgl_lastkey() = fgl_keyval("left") 
					OR fgl_lastkey() = fgl_keyval("up") 
					NEXT FIELD module_code 
				OTHERWISE 
					NEXT FIELD module_code 
			END CASE 
		AFTER FIELD program_name_text 
			CASE 
				WHEN fgl_lastkey() = fgl_keyval("accept") 
					OR fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("down") 
					IF fgl_lastkey() = fgl_keyval("accept") THEN 
						IF pa_syslocks[idx].retry_num IS NULL 
						OR pa_syslocks[idx].retry_num <= 0 THEN 
							LET l_msgresp = kandoomsg("U",9005,"0") 
							#9005 "You must enter a number greater than 0"
							NEXT FIELD retry_num 
						END IF 
						IF pa_syslocks[idx].retry_num > 10 THEN 
							LET l_msgresp = kandoomsg("U",6001,"") 
							#6001 "WARNING: Should enter less than 10 in retry"
						END IF 
						NEXT FIELD scroll_flag 
					END IF 
					NEXT FIELD retry_num 
				WHEN fgl_lastkey() = fgl_keyval("left") 
					OR fgl_lastkey() = fgl_keyval("up") 
					NEXT FIELD module_code 
				OTHERWISE 
					NEXT FIELD program_name_text 
			END CASE 
		AFTER FIELD retry_num 
			CASE 
				WHEN fgl_lastkey() = fgl_keyval("accept") 
					OR fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("down") 
					IF pa_syslocks[idx].retry_num IS NULL 
					OR pa_syslocks[idx].retry_num <= 0 THEN 
						LET l_msgresp = kandoomsg("U",9005,"0") 
						#9005 "You must enter a number greater than 0"
						NEXT FIELD retry_num 
					END IF 
					IF pa_syslocks[idx].retry_num > 10 THEN 
						LET l_msgresp = kandoomsg("U",6001,"") 
						#6001 "WARNING: Should enter less than 10 in retry"
					END IF 
					NEXT FIELD scroll_flag 
				WHEN fgl_lastkey() = fgl_keyval("left") 
					OR fgl_lastkey() = fgl_keyval("up") 
					NEXT FIELD program_name_text 
				OTHERWISE 
					NEXT FIELD retry_num 
			END CASE 
		AFTER ROW 
			DISPLAY pa_syslocks[idx].* TO sr_syslocks[scrn].* 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				IF NOT (infield(scroll_flag)) THEN 
					IF pr_mode = MODE_CLASSIC_ADD THEN 
						FOR idx = arr_curr() TO arr_count() 
							LET pa_syslocks[idx].* = pa_syslocks[idx+1].* 
							IF idx = arr_count() THEN 
								INITIALIZE pa_syslocks[idx].* TO NULL 
							END IF 
							IF scrn <= 15 THEN 
								DISPLAY pa_syslocks[idx].* TO sr_syslocks[scrn].* 

								LET scrn = scrn + 1 
							END IF 
						END FOR 
						LET scrn = scr_line() 
						LET int_flag = false 
						LET quit_flag = false 
						NEXT FIELD scroll_flag 
					ELSE 
						LET pa_syslocks[idx].module_code = pr_syslocks.module_code 
						LET pa_syslocks[idx].program_name_text = 
						pr_syslocks.program_name_text 
						LET pa_syslocks[idx].retry_num = pr_syslocks.retry_num 
						LET int_flag = false 
						LET quit_flag = false 
						NEXT FIELD scroll_flag 
					END IF 
				END IF 
			END IF 
	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 
	END IF 
	GOTO bypass 
	LABEL recovery: 
	IF error_recover("",STATUS) != "Y" THEN 
		EXIT program 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		DELETE FROM syslocks 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		FOR idx = 1 TO arr_count() 
			IF pa_syslocks[idx].retry_num IS NULL 
			OR pa_syslocks[idx].retry_num = 0 THEN 
				CONTINUE FOR 
			END IF 
			LET pr_syslocks.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET pr_syslocks.module_code = pa_syslocks[idx].module_code 
			LET pr_syslocks.program_name_text = pa_syslocks[idx].program_name_text 
			LET pr_syslocks.retry_num = pa_syslocks[idx].retry_num 
			INSERT INTO syslocks VALUES (pr_syslocks.*) 
		END FOR 
	COMMIT WORK 
END FUNCTION