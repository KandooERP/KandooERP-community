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

#  This process will use SCREEN brwsrpt.frm TO enable the viewing of the
#  rpthead table.

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS "../gl/GW5_GLOBALS.4gl" 


############################################################
# FUNCTION def_brws(l_rpt_id,p_filter)
#
#
############################################################
FUNCTION def_brws(l_rpt_id,p_filter) 
	DEFINE l_rpt_id LIKE rpthead.rpt_id 
	DEFINE p_filter boolean 
	DEFINE l_arr_rec_rpthead DYNAMIC ARRAY OF RECORD -- array[51] OF RECORD 
		rpt_id LIKE rpthead.rpt_id, 
		rpt_text LIKE rpthead.rpt_text, 
		rpt_type LIKE rpthead.rpt_type 
	END RECORD 
	DEFINE l_r_rpt_id LIKE rpthead.rpt_id 
	DEFINE l_pa_totsize SMALLINT #the size OF the program ARRAY (50) 
	DEFINE l_idx SMALLINT --fv_scrn, 
	DEFINE l_counter SMALLINT 
	--	DEFINE l_s1 CHAR(600)
	DEFINE l_reselect SMALLINT #true/false 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_pa_totsize = 50 

	OPEN WINDOW G501 with FORM "G501" 
	CALL windecoration_g("G501") 

	IF p_filter THEN 

		--	LET l_reselect = TRUE

		--	WHILE l_reselect
		CLEAR FORM 
		IF glob_query_1 IS NULL THEN 
			LET l_msgresp = kandoomsg("U",1001,"")			#1001 Enter Selection Criteria - OK TO Continue
			CALL close_scurs_def() 
			#get the users query criteria
			CONSTRUCT glob_query_1 ON 
				rpthead.rpt_id, 
				rpthead.rpt_text, 
				rpthead.rpt_type 
			FROM 
				rpthead[1].rpt_id, 
				rpthead[1].rpt_text, 
				rpthead[1].rpt_type 
				BEFORE CONSTRUCT 
					CALL publish_toolbar("kandoo","GW5b","construct-rpthead") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
			END CONSTRUCT 

			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				CLOSE WINDOW g501 
				IF l_rpt_id IS NOT NULL THEN 
					RETURN l_rpt_id 
				ELSE 
					LET glob_query_1 = " 1=1 " 
				END IF 
			END IF 
		END IF 

	ELSE 
		LET glob_query_1 = " 1=1 " 
	END IF 

	LET l_msgresp = kandoomsg("U",1002,"")	#1002 Searching Database - Please Wait
	IF glob_scurs_def_open THEN 
		#do nothing
	ELSE 
		CALL def_curs() 
	END IF 
	#get the CURSOR information INTO the program array

	LET l_counter = 0 
	WHILE true 
		IF l_counter = 0 THEN 
			IF base_first_def() THEN 
				EXIT WHILE 
			END IF 
		ELSE 
			IF base_next_def() THEN 
				EXIT WHILE 
			END IF 
		END IF 
		
		LET l_counter = l_counter + 1 
		LET l_arr_rec_rpthead[l_counter].rpt_id = glob_rec_rpthead.rpt_id 
		LET l_arr_rec_rpthead[l_counter].rpt_text = glob_rec_rpthead.rpt_text 
		LET l_arr_rec_rpthead[l_counter].rpt_type = glob_rec_rpthead.rpt_type 
		IF l_counter >= l_pa_totsize THEN 
			LET l_msgresp = kandoomsg("U",6100,l_counter)		#6100 First l_counter records selected.
			EXIT WHILE 
		END IF 
	END WHILE 

	LET l_msgresp = kandoomsg("U",9113,l_counter)#9113 l_counter records selected.
	IF l_counter > 0 THEN 
		#do nothing yet
	ELSE 
		#we will INITIALIZE the query text TO NULL TO prevent the browse
		#window FROM automatically exiting in the future
		INITIALIZE glob_query_1 TO NULL 

		#AND INITIALIZE the argument TO NULL so the calling process doesn't
		#reselect it
		INITIALIZE l_rpt_id TO NULL 

		#AND also INITIALIZE the glob_rec_rpthead.* RECORD TO NULL as it seems
		#TO want TO take on the last RECORD of the rpthead tables VALUES
		INITIALIZE glob_rec_rpthead.* TO NULL 

		CALL close_scurs_def() 
	END IF 

	--    LET gv_num_rows = l_counter
	IF l_counter = 0 THEN 
		CLOSE WINDOW g501 
		RETURN l_rpt_id 
	END IF 
	
	LET l_msgresp = kandoomsg("G",1093,"") #1093 OK TO SELECT; F9 Reselect.

	--    CALL set_count(l_counter)
	LET l_reselect = false 
	--    INPUT ARRAY l_arr_rec_rpthead WITHOUT DEFAULTS FROM sa_rpthead.* ATTRIBUTES(UNBUFFERED)

	DISPLAY ARRAY l_arr_rec_rpthead TO sa_rpthead.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","GW5b","inp-arr-rpthead") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION ("ACCEPT","DOUBLECLICK") 
			--        ON KEY (F9)
			LET l_reselect = true 
			INITIALIZE glob_query_1 TO NULL 
			EXIT DISPLAY 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			IF l_idx > 0 THEN 
				#LET fv_scrn = scr_line()
				LET l_counter = arr_count() 
				IF l_idx <= l_counter THEN 
					#DISPLAY l_arr_rec_rpthead[l_idx].* TO sa_rpthead[fv_scrn].*

					LET glob_rec_rpthead.rpt_id = l_arr_rec_rpthead[l_idx].rpt_id 
				END IF 
				LET l_r_rpt_id = l_arr_rec_rpthead[l_idx].rpt_id 

				LET l_arr_rec_rpthead[l_idx].rpt_id = l_r_rpt_id 

			END IF 

			--			ON ACTION ("ACCEPT","DOUBLECLICK")
			--        AFTER FIELD rpt_id
			--           LET l_arr_rec_rpthead[l_idx].rpt_id = l_r_rpt_id
			#DISPLAY l_arr_rec_rpthead[l_idx].* TO sa_rpthead[fv_scrn].*

			--           IF l_arr_rec_rpthead[l_idx+1].rpt_id IS NULL
			--           AND fgl_lastkey() = fgl_keyval("down") THEN
			--              LET l_msgresp = kandoomsg("U",9001,"")
			--              #9001 There are no more rows in the direction ...
			--              NEXT FIELD rpt_id
			--           END IF

			--        BEFORE FIELD rpt_text
			--           NEXT FIELD rpt_id

			--        AFTER ROW
			--            IF l_idx <= l_counter THEN
			--                #DISPLAY l_arr_rec_rpthead[l_idx].* TO sa_rpthead[fv_scrn].*
			--
			--                IF base_abs_def(l_idx) THEN
			--                    LET l_msgresp = kandoomsg("U",9910,"")
			--                    #9910 "Record NOT found"
			--                END IF
			--            END IF

	END DISPLAY 

	--END WHILE

	CLOSE WINDOW g501 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN "" 
	END IF 

	RETURN glob_rec_rpthead.rpt_id 
END FUNCTION 
############################################################
# END FUNCTION def_brws(l_rpt_id,p_filter)
############################################################