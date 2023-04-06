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


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS "../gl/GW3_GLOBALS.4gl" 


############################################################
# FUNCTION col_brws(p_rpt_id)
#
# This process will use SCREEN col_brws.frm TO enable the viewing of the
# rptcol tables.
############################################################
FUNCTION col_brws(p_rpt_id) 
	DEFINE p_rpt_id LIKE rptcol.rpt_id 
	DEFINE l_arr_rec_rptcol DYNAMIC ARRAY OF 
	RECORD 
		rpt_id LIKE rpthead.rpt_id, 
		col_id LIKE rptcol.col_id, 
		col_desc LIKE rptcoldesc.col_desc 
	END RECORD 

	DEFINE l_pa_totsize SMALLINT #the size OF the program ARRAY (50) 
	DEFINE fv_idx SMALLINT #fv_scrn, 
	DEFINE fv_counter SMALLINT #fv_scrn, 
	DEFINE fv_s1 CHAR(600) 
	DEFINE fv_reselect SMALLINT #true/false 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_pa_totsize = 50 

	OPEN WINDOW g511 with FORM "G511" 
	CALL windecoration_g("G511") 


	LET fv_reselect = true 

	WHILE fv_reselect 
		#SET up the form
		CLEAR FORM 
		IF glob_query_1 IS NULL THEN 
			CALL close_scurs_col() 
			#get the users query criteria
			LET l_msgresp = kandoomsg("U",1001,"") 
			#1001 Enter Selection Criteria - OK TO Continue
			CONSTRUCT glob_query_1 
			ON rptcol.rpt_id, 
			rptcol.col_id, 
			rptcoldesc.col_desc 
			FROM rptcol[1].rpt_id, 
			rptcol[1].col_id, 
			rptcoldesc[1].col_desc 
				BEFORE CONSTRUCT 
					CALL publish_toolbar("kandoo","GW3b","construct-rptcol") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
			END CONSTRUCT 

			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				CLOSE WINDOW g511 
				RETURN p_rpt_id 
			END IF 
		END IF 
		LET l_msgresp = kandoomsg("U",1002,"") 
		#1002 Searching Database - Please Wait
		IF glob_scurs_col_open THEN 
			#do nothing
		ELSE 
			CALL col_curs() 
		END IF 

		#get the CURSOR information INTO the program array
		LET fv_counter = 0 
		WHILE true 
			IF fv_counter = 0 THEN 
				IF base_first_col() THEN 
					EXIT WHILE 
				END IF 
			ELSE 
				IF base_next_col() THEN 
					EXIT WHILE 
				END IF 
			END IF 

			LET fv_counter = fv_counter + 1 
			LET l_arr_rec_rptcol[fv_counter].rpt_id = glob_rec_rpthead.rpt_id 
			IF glob_rec_rptcol.col_id > 0 OR glob_rec_rptcol.col_id IS NOT NULL THEN 
				LET l_arr_rec_rptcol[fv_counter].col_id = glob_rec_rptcol.col_id 
				SELECT col_desc INTO l_arr_rec_rptcol[fv_counter].col_desc 
				FROM rptcoldesc 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND rpt_id = glob_rec_rptcol.rpt_id 
				AND col_uid = glob_rec_rptcol.col_uid 
				AND seq_num = 1 
			END IF 
			IF fv_counter >= l_pa_totsize THEN 
				LET l_msgresp = kandoomsg("U",6100,fv_counter) 
				#6100 First fv_counter records selected
				EXIT WHILE 
			END IF 
		END WHILE 
		LET l_msgresp = kandoomsg("U",9113,fv_counter) 
		#9113 "fv_counter records found"

		IF fv_counter > 0 THEN 
			#do nothing yet
		ELSE 
			#we will INITIALIZE the query text TO NULL TO prevent the browse
			#window FROM automatically exiting in the future
			INITIALIZE glob_query_1 TO NULL 

			#AND INITIALIZE the argument TO NULL so the calling process doesn't
			#reselect it
			INITIALIZE p_rpt_id TO NULL 

			#AND also INITIALIZE the glob_rec_rptcol.* RECORD TO NULL as it seems
			#TO want TO take on the last RECORD of the rpthead tables VALUES
			INITIALIZE glob_rec_rptcol.* TO NULL 

			CALL close_scurs_col() 
		END IF 

		SLEEP 1 

		LET glob_num_rows = fv_counter 

		IF fv_counter = 0 THEN 
			CLOSE WINDOW g511 
			RETURN p_rpt_id 
		END IF 


		CALL set_count(fv_counter) 

		LET fv_reselect = false 
		LET l_msgresp = kandoomsg("G",1071,"") 
		#1071 F3/F4 TO page Fwd/Bwd; OK TO SELECT

		INPUT ARRAY l_arr_rec_rptcol WITHOUT DEFAULTS FROM sa_rptcol.* attributes(UNBUFFERED) 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","GW3b","inp-arr-rptcol") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 


			ON KEY (F9) 
				LET fv_reselect = true 
				INITIALIZE glob_query_1 TO NULL 
				EXIT INPUT 

			BEFORE ROW 
				LET fv_idx = arr_curr() 
				#LET fv_scrn = scr_line()
				LET fv_counter = arr_count() 
				IF fv_idx <= fv_counter THEN 
					#DISPLAY l_arr_rec_rptcol[fv_idx].* TO sa_rptcol[fv_scrn].*

					LET glob_rec_rptcol.rpt_id = l_arr_rec_rptcol[fv_idx].rpt_id 
				END IF 

			AFTER ROW 
				IF fv_idx <= fv_counter THEN 
					#DISPLAY l_arr_rec_rptcol[fv_idx].* TO sa_rptcol[fv_scrn].*

					IF base_abs_col(fv_idx) THEN 
						LET l_msgresp = kandoomsg("U",9001,"") 
						#9001 No more rows in that direction
					END IF 
				END IF 

			AFTER INPUT 
				IF glob_rec_rpthead.rpt_id IS NULL THEN 
					LET glob_rec_rpthead.rpt_id = p_rpt_id 
					LET glob_rec_rptcol.rpt_id = p_rpt_id 
					LET glob_rec_rptcol.col_id = 1 
				END IF 
				#       ON KEY (control-w)
				#          CALL kandoohelp("")
		END INPUT 

	END WHILE #fv_reselect 

	CLOSE WINDOW g511 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF #int_flag OR quit_flag THEN 

	RETURN glob_rec_rptcol.rpt_id 
END FUNCTION #brwsrpt 
