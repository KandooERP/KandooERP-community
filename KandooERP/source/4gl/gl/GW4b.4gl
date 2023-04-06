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

	Source code beautified by beautify.pl on 2020-01-03 14:28:58	$Id: $
}


############################################################
# This process will use SCREEN brwsrpt.per TO enable the viewing of the
# rpthead table.
############################################################

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS "../gl/GW4_GLOBALS.4gl" 


############################################################
# FUNCTION line_brws(p_rpt_id)
#
#
############################################################
FUNCTION line_brws(p_rpt_id) 
	DEFINE p_rpt_id LIKE rpthead.rpt_id 
	DEFINE l_arr_rec_rpthead DYNAMIC ARRAY OF RECORD -- array[50] OF RECORD 
		rpt_id LIKE rpthead.rpt_id, 
		rpt_text LIKE rpthead.rpt_text, 
		rpt_type LIKE rpthead.rpt_type 
	END RECORD 
	DEFINE l_pa_totsize SMALLINT #the size OF the program ARRAY (50) 
	DEFINE l_idx SMALLINT 
	DEFINE l_counter SMALLINT 
	DEFINE l_s1 CHAR(600) 
	DEFINE l_reselect SMALLINT #true/false 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_pa_totsize = 50 

	OPEN WINDOW g501 with FORM "G501" 
	CALL windecoration_g("G501") 

	LET l_reselect = true 
	WHILE l_reselect 
		#SET up the form
		CLEAR FORM 
		IF glob_query_1 IS NULL THEN 
			LET l_msgresp = kandoomsg("U",1001,"") 
			#1001 Enter selection criteria; OK TO continue.
			CALL close_scurs_line() 
			#get the users query criteria
			CONSTRUCT glob_query_1 
			ON rpthead.rpt_id, 
			rpthead.rpt_text, 
			rpthead.rpt_type 
			FROM rpthead[1].rpt_id, 
			rpthead[1].rpt_text, 
			rpthead[1].rpt_type 
				BEFORE CONSTRUCT 
					CALL publish_toolbar("kandoo","GW4b","construct-rpthead") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
			END CONSTRUCT 

			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				CLOSE WINDOW g501 
				RETURN p_rpt_id 
			END IF 
		END IF 

		LET l_msgresp = kandoomsg("U",1002,"") 
		#1002 Searching Database - Please Wait
		IF gv_scurs_line_open THEN 
		ELSE 
			CALL line_curs() 
		END IF #gv_scurs_line_open THEN 
		#get the CURSOR information INTO the program array

		LET l_counter = 0 
		WHILE true 
			IF l_counter = 0 THEN 
				IF base_first_line() THEN 
					EXIT WHILE 
				END IF 
			ELSE 
				IF base_next_line() THEN 
					EXIT WHILE 
				END IF 
			END IF 
			LET l_counter = l_counter + 1 
			LET l_arr_rec_rpthead[l_counter].rpt_id = glob_rec_rpthead.rpt_id 
			LET l_arr_rec_rpthead[l_counter].rpt_text = glob_rec_rpthead.rpt_text 
			LET l_arr_rec_rpthead[l_counter].rpt_type = glob_rec_rpthead.rpt_type 
			IF l_counter >= l_pa_totsize THEN 
				LET l_msgresp = kandoomsg("U",6100,l_counter) 
				#6100 Frist l_counter records selected
				EXIT WHILE 
			END IF 
		END WHILE 

		LET l_msgresp = kandoomsg("U",9113,l_counter) 
		#9113 l_counter records selected
		IF l_counter > 0 THEN 
			#do nothing yet
		ELSE 
			#we will INITIALIZE the query text TO NULL TO prevent the browse
			#window FROM automatically exiting in the future
			INITIALIZE glob_query_1 TO NULL 
			#AND INITIALIZE the argument TO NULL so the calling process doesn't
			#reselect it
			INITIALIZE p_rpt_id TO NULL 
			#AND also INITIALIZE the glob_rec_rpthead.* RECORD TO NULL as it seems
			#TO want TO take on the last RECORD of the rpthead tables VALUES
			INITIALIZE glob_rec_rpthead.* TO NULL 
			CALL close_scurs_line() 
		END IF 

		SLEEP 1 
		--    LET gv_num_rows = l_counter
		IF l_counter = 0 THEN 
			CLOSE WINDOW g501 
			RETURN p_rpt_id 
		END IF 
		LET l_msgresp = kandoomsg("G",1071,"") 
		#1071 F3/F4 TO Page Fwd/Bwd; OK TO SELECT.
		CALL set_count(l_counter) 
		LET l_reselect = false 

		OPTIONS INSERT KEY f36, 
		DELETE KEY f36 

		INPUT ARRAY l_arr_rec_rpthead WITHOUT DEFAULTS FROM sa_rpthead.* attributes(UNBUFFERED) 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","GW4b","inp-arr-rpthead") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON KEY (F9) 
				LET l_reselect = true 
				INITIALIZE glob_query_1 TO NULL 
				EXIT INPUT 
			BEFORE ROW 
				LET l_idx = arr_curr() 
				#LET fv_scrn = scr_line()
				LET l_counter = arr_count() 
				IF l_idx <= l_counter THEN 
					#DISPLAY l_arr_rec_rpthead[l_idx].* TO sa_rpthead[fv_scrn].*

					LET glob_rec_rpthead.rpt_id = l_arr_rec_rpthead[l_idx].rpt_id 
				END IF 
			AFTER ROW 
				IF l_idx <= l_counter THEN 
					#DISPLAY l_arr_rec_rpthead[l_idx].* TO sa_rpthead[fv_scrn].*

					IF base_abs_line(l_idx) THEN 
						LET l_msgresp = kandoomsg("U",9910,"") 
						#9910 RECORD Not Found
					END IF 
				END IF 
			AFTER INPUT 
				IF glob_rec_rpthead.rpt_id IS NULL THEN 
					LET glob_rec_rpthead.rpt_id = p_rpt_id 
				END IF 
				--       ON KEY (control-w)
				--          CALL kandoohelp("")
		END INPUT 

		OPTIONS INSERT KEY f1, 
		DELETE KEY f2 

	END WHILE #l_reselect 

	CLOSE WINDOW g501 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 

	RETURN glob_rec_rpthead.rpt_id 
END FUNCTION #brwsrpt 
