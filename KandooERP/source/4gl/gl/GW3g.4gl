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

	Source code beautified by beautify.pl on 2020-01-03 14:28:57	$Id: $
}



############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS "../gl/GW3_GLOBALS.4gl" 

############################################################
# FUNCTION col_insert()
#
#
############################################################
FUNCTION col_insert() 
	DEFINE l_col_id LIKE rptcol.col_id 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	CALL get_col(glob_rec_rpthead.rpt_id) 
	RETURNING glob_rec_rpthead.rpt_id, l_col_id 

	IF l_col_id IS NULL THEN 
		LET l_msgresp = kandoomsg("G",9206,"") 
		#9206 No Records Selected; Use Query Option.
	ELSE 
		CALL insert_col_add(l_col_id) 
	END IF 
	OPTIONS INSERT KEY f1, 
	DELETE KEY f2 
END FUNCTION 



############################################################
# FUNCTION insert_col_add(l_col_id)
#
#
############################################################
FUNCTION insert_col_add(l_col_id) 
	DEFINE l_idx INTEGER 
	DEFINE l_scr INTEGER 
	DEFINE l_cnt INTEGER 
	DEFINE l_width_tot INTEGER 
	DEFINE l_field CHAR(10) 
	DEFINE l_col_id LIKE rptcol.col_id 
	DEFINE l_rec_mrwitem RECORD LIKE mrwitem.* 

	CLEAR FORM 
	INITIALIZE glob_rec_rptcol TO NULL 
	#   assign the default VALUES
	LET glob_rec_rptcol.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET glob_rec_rptcol.rpt_id = glob_rec_rpthead.rpt_id 
	LET glob_rec_rptcol.col_id = l_col_id 
	IF glob_rec_rptcol.col_id IS NULL OR glob_rec_rptcol.col_id = 0 THEN 
		LET glob_rec_rptcol.col_id = 1 
	END IF 
	LET glob_rec_rptcol.amt_picture = glob_rec_rpthead.amt_picture 
	DISPLAY BY NAME glob_rec_rpthead.rpt_id, 
	glob_rec_rpthead.rpt_text, 
	glob_rec_rptcol.col_id, 
	glob_rec_rptcol.amt_picture 

	#Clear rptcoldesc array
	FOR l_idx = 1 TO 3 
		INITIALIZE glob_arr_recrptcoldesc[l_idx] TO NULL 
	END FOR 

	#Clear colitem array
	FOR l_idx = 1 TO glob_colitem_cnt 
		INITIALIZE glob_arr_reccolitem[l_idx] TO NULL 
	END FOR 

	#Set Default add attributes
	LET glob_colitem_cnt = 0 
	CALL col_updt(true) 
END FUNCTION 



############################################################
# FUNCTION get_col(p_rpt_id)
#
#
############################################################
FUNCTION get_col(p_rpt_id) 
	DEFINE p_rpt_id LIKE rptcol.rpt_id 
	DEFINE l_col_id LIKE rptcol.col_id 
	DEFINE l_arr_rec_rptcol DYNAMIC ARRAY OF RECORD # array[50] OF RECORD 
		rpt_id LIKE rpthead.rpt_id, 
		col_id LIKE rptcol.col_id, 
		col_desc LIKE rptcoldesc.col_desc 
	END RECORD 
	DEFINE l_pa_totsize SMALLINT #the size OF the program ARRAY (50) 
	DEFINE l_idx SMALLINT #fv_scrn 
	DEFINE l_counter SMALLINT #fv_scrn 
	DEFINE l_s1 CHAR(600) 
	DEFINE l_reselect SMALLINT #true/false 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_pa_totsize = 50 

	OPEN WINDOW g511 with FORM "G511" 
	CALL windecoration_g("G511") 


	LET l_reselect = true 
	WHILE l_reselect 
		#SET up the form
		CLEAR FORM 
		LET glob_query_1 = "rpthead.rpt_id = '",glob_rec_rpthead.rpt_id, "' " 
		IF glob_scurs_col_open THEN 
			CALL close_scurs_col() 
		END IF 
		CALL col_curs() 
		#get the CURSOR information INTO the program array
		LET l_counter = 0 
		WHILE true 
			IF l_counter = 0 THEN 
				IF base_first_col() THEN 
					EXIT WHILE 
				END IF 
			ELSE 
				IF base_next_col() THEN 
					EXIT WHILE 
				END IF 
			END IF 
			LET l_counter = l_counter + 1 
			LET l_arr_rec_rptcol[l_counter].rpt_id = glob_rec_rpthead.rpt_id 
			IF glob_rec_rptcol.col_id > 0 OR glob_rec_rptcol.col_id IS NOT NULL THEN 
				LET l_arr_rec_rptcol[l_counter].col_id = glob_rec_rptcol.col_id 
				SELECT col_desc INTO l_arr_rec_rptcol[l_counter].col_desc 
				FROM rptcoldesc 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND rpt_id = glob_rec_rptcol.rpt_id 
				AND col_uid = glob_rec_rptcol.col_uid 
				AND seq_num = 1 
			END IF 
			IF l_counter >= l_pa_totsize THEN 
				LET l_msgresp = kandoomsg("U",6100,l_counter) 
				#6100 First ??? records selected more may exist.
				EXIT WHILE 
			END IF 
		END WHILE #true 

		LET l_msgresp = kandoomsg("U",9113,l_counter) 
		#9113 ??? records selected.
		IF l_counter > 0 THEN 
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

		LET glob_num_rows = l_counter 
		IF l_counter = 0 THEN 
			CLOSE WINDOW g511 
			RETURN p_rpt_id 
		END IF 
		LET l_msgresp = kandoomsg("G",1071,"") 
		#1071 F3/F4 TO Page Up/Down;  OK TO SELECT
		CALL set_count(l_counter) 
		LET l_reselect = false 

		INPUT ARRAY l_arr_rec_rptcol WITHOUT DEFAULTS FROM sa_rptcol.* attributes(UNBUFFERED) 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","GW3g","inp-arr-rptcol") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 


			BEFORE ROW 
				LET l_idx = arr_curr() 
				#LET fv_scrn = scr_line()
				LET l_counter = arr_count() 
				IF l_idx <= l_counter THEN 
					#DISPLAY l_arr_rec_rptcol[l_idx].* TO sa_rptcol[fv_scrn].*

					LET glob_rec_rptcol.rpt_id = l_arr_rec_rptcol[l_idx].rpt_id 
				END IF 

			AFTER ROW 
				IF l_idx <= l_counter THEN 
					#DISPLAY l_arr_rec_rptcol[l_idx].* TO sa_rptcol[fv_scrn].*

					IF base_abs_col(l_idx) THEN 
						LET l_msgresp = kandoomsg("U",9910,"") 
						#9910 "Record NOT found"
					END IF 
				END IF 

			AFTER INPUT 
				LET l_idx = arr_curr() 
				#LET fv_scrn = scr_line()
				LET l_col_id = l_arr_rec_rptcol[l_idx].col_id 
				#       ON KEY (control-w)
				#          CALL kandoohelp("")
		END INPUT 

	END WHILE #l_reselect 

	CLOSE WINDOW g511 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 

	RETURN glob_rec_rptcol.rpt_id, l_col_id 
END FUNCTION 
