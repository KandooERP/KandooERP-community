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

	Source code beautified by beautify.pl on 2020-01-03 14:28:56	$Id: $
}



#  This module contains the functions needed TO change a
#  RECORD in rpthead table.
#
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS "GW2_GLOBALS.4gl" 


###############################################################################
# FUNCTION hdr_updt()
#
#
###############################################################################
FUNCTION hdr_updt() 
	DEFINE l_rpt_type LIKE rpthead.rpt_type 
	DEFINE l_ans CHAR(1) 
	DEFINE l_counter INTEGER 
	DEFINE l_del_colaa INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 


	LET l_msgresp = kandoomsg("G",1065,"") 
	#1065 Enter Report Header Details; OK TO Continue.
	LET glob_rec_rpthead.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET l_del_colaa = false # SET DELETE redundant rptcolaa flag. 
	LET int_flag = false 
	LET quit_flag = false 

	INPUT BY NAME glob_rec_rpthead.rpt_text, 
	glob_rec_rpthead.rpt_desc1, 
	glob_rec_rpthead.rpt_desc2, 
	glob_rec_rpthead.rpt_desc_position, 
	glob_rec_rpthead.rpt_type, 
	glob_rec_rpthead.rnd_code, 
	glob_rec_rpthead.sign_code, 
	glob_rec_rpthead.amt_picture, 
	glob_rec_rpthead.always_print_line, 
	glob_rec_rpthead.col_hdr_per_page, 
	glob_rec_rpthead.std_head_per_page WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GW2f","inp-rep") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield(rpt_desc_position) 
			CALL show_rptpos(glob_rec_rpthead.rpt_desc_position) 
			RETURNING glob_rec_rpthead.rpt_desc_position 
			DISPLAY BY NAME glob_rec_rpthead.rpt_desc_position 


		ON ACTION "LOOKUP" infield(rpt_type) 
			CALL show_rpttype(glob_rec_rpthead.rpt_type) 
			RETURNING glob_rec_rpthead.rpt_type 
			DISPLAY BY NAME glob_rec_rpthead.rpt_type 


		ON ACTION "LOOKUP" infield(rnd_code) 
			CALL show_rndcode(glob_rec_rpthead.rnd_code) 
			RETURNING glob_rec_rpthead.rnd_code 
			DISPLAY BY NAME glob_rec_rpthead.rnd_code 


		ON ACTION "LOOKUP" infield(sign_code) 
			CALL show_signcode(glob_rec_rpthead.sign_code) 
			RETURNING glob_rec_rpthead.sign_code 
			DISPLAY BY NAME glob_rec_rpthead.sign_code 


		AFTER FIELD rpt_desc_position 
			#Check that the rpt_desc_position code exist.
			SELECT * INTO glob_rec_rptpos.* FROM rptpos 
			WHERE rptpos_id = glob_rec_rpthead.rpt_desc_position 
			IF status = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("U",9105,"") 
				#9105 RECORD NOT found; Try Window.
				NEXT FIELD rpt_desc_position 
			END IF 
			DISPLAY BY NAME glob_rec_rptpos.rptpos_desc 

		AFTER FIELD rpt_type 
			#Check that the rpt_type code exist.
			SELECT * INTO glob_rec_rpttype.* FROM rpttype 
			WHERE rpttype_id = glob_rec_rpthead.rpt_type 

			IF status = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("U",9105,"") 
				#9105 RECORD NOT found; Try Window.
				NEXT FIELD rpt_type 
			ELSE 
				# IF the rpt type differs FROM the original rpt type
				# THEN check IF the original rpt type IS an analysis across
				# type in rptcolaa.
				SELECT rpt_type INTO l_rpt_type 
				FROM rpthead 
				WHERE cmpy_code = glob_rec_rpthead.cmpy_code 
				AND rpt_id = glob_rec_rpthead.rpt_id 

				IF glob_rec_rpthead.rpt_type != l_rpt_type AND NOT l_del_colaa THEN 
					#Check IF there are any rptcolaa rows.
					SELECT count(*) INTO l_counter 
					FROM rptcolaa 
					WHERE cmpy_code = glob_rec_rpthead.cmpy_code 
					AND rpt_id = glob_rec_rpthead.rpt_id 

					IF l_counter > 0 THEN 
						LET l_msgresp = kandoomsg("G",9103,"") 
						LET l_ans = kandoomsg("G",3506,"") 

						IF l_ans = "Y" THEN 
							LET l_del_colaa = true 
						ELSE 
							LET l_del_colaa = false 
							LET glob_rec_rpthead.rpt_type = l_rpt_type 
							DISPLAY BY NAME glob_rec_rpthead.rpt_type 

							NEXT FIELD rpt_type 
						END IF 
					END IF 
				END IF 

			END IF 

			DISPLAY BY NAME glob_rec_rpttype.rpttype_desc 



		AFTER FIELD rnd_code 

			#Check that the rnd_code code exist.
			SELECT * INTO glob_rec_rndcode.* FROM rndcode 
			WHERE rnd_code = glob_rec_rpthead.rnd_code 

			IF status = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("U",9105,"") 
				#9105 RECORD NOT found; Try Window.
				NEXT FIELD rnd_code 
			END IF 

			DISPLAY BY NAME glob_rec_rndcode.rnd_desc 


		AFTER FIELD sign_code 

			#Check that the sign_code code exist.
			SELECT * INTO glob_rec_signcode.* FROM signcode 
			WHERE sign_code = glob_rec_rpthead.sign_code 
			IF status = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("U",9105,"") 
				#9105 RECORD NOT found; Try Window.
				NEXT FIELD sign_code 
			END IF 
			DISPLAY BY NAME glob_rec_signcode.sign_desc 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 

			CASE 
				WHEN glob_rec_rpthead.rpt_desc_position IS NULL 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD rpt_desc_position 
				WHEN glob_rec_rpthead.rpt_type IS NULL 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD rpt_type 
				WHEN glob_rec_rpthead.rnd_code IS NULL 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD rnd_code 
				WHEN glob_rec_rpthead.sign_code IS NULL 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD sign_code 
				WHEN glob_rec_rpthead.col_hdr_per_page IS NULL 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD col_hdr_per_page 
				WHEN glob_rec_rpthead.std_head_per_page IS NULL 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD std_head_per_page 
			END CASE 

			UPDATE rpthead 
			SET rpthead.* = glob_rec_rpthead.* 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND rpt_id = glob_rec_rpthead.rpt_id 

			IF status THEN 
				LET l_msgresp = kandoomsg("I",9227,"") 
				#9227 Update Failed; Please Try Again
				NEXT FIELD rpt_text 
			END IF 

			# IF TRUE THEN delete all associated rptcolaa rows.
			IF l_del_colaa THEN 
				DELETE FROM rptcolaa 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND rpt_id = glob_rec_rpthead.rpt_id 
			END IF 

			--	   ON KEY (control-w)
			--	      CALL kandoohelp("")

	END INPUT 
	####################################

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 

END FUNCTION 



