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

	Source code beautified by beautify.pl on 2020-01-03 10:10:03	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "T_GW_GLOBALS.4gl" 
GLOBALS "TGW3_GLOBALS.4gl" 

# This process will use SCREEN col_brws.frm TO enable the viewing of the
# rptcol tables.


FUNCTION col_brws(fv_col_code) 

	DEFINE 
	fv_col_code LIKE rptcol.col_code, 

	fa_rptcol array[50] OF RECORD 
		col_code LIKE rptcolgrp.col_code, 
		col_id LIKE rptcol.col_id, 
		col_desc LIKE rptcoldesc.col_desc END RECORD, 

		fv_pa_totsize SMALLINT, #the size OF the program ARRAY (50) 
		fv_scrn, fv_idx, fv_counter SMALLINT, 
		fv_s1 CHAR(600), 
		fv_reselect SMALLINT 

		LET fv_pa_totsize = 50 

		OPEN WINDOW g511 with FORM "TG511" 
		CALL windecoration_t("TG511") -- albo kd-768 

		LET fv_reselect = true 

		WHILE fv_reselect 
			CLEAR FORM 
			IF gv_query_1 IS NULL THEN 
				#MESSAGE "Enter criteria, ACC TO start query"
				#    ATTRIBUTE(yellow)
				LET msgresp = kandoomsg("U",1001," ") 
				CALL close_scurs_col() 
				CONSTRUCT gv_query_1 
				ON rptcol.col_code, 
				rptcol.col_id, 
				rptcoldesc.col_desc 
				FROM rptcol[1].col_code, 
				rptcol[1].col_id, 
				rptcoldesc[1].col_desc 

					BEFORE CONSTRUCT 
						CALL publish_toolbar("kandoo","TGW3b","construct-col_code-1") -- albo kd-515 

					ON ACTION "WEB-HELP" -- albo kd-378 
						CALL onlinehelp(getmoduleid(),null) 

				END CONSTRUCT 

				IF int_flag OR quit_flag THEN 
					LET int_flag = false 
					LET quit_flag = false 
					CLOSE WINDOW g511 
					RETURN fv_col_code 
				END IF 
			END IF 

			IF gv_scurs_col_open THEN 
				#do nothing
			ELSE 
				CALL col_curs() 
			END IF 

			LET fv_counter = 0 
			WHILE true 
				IF fv_counter = 0 THEN 
					IF base_first_col() THEN 
						ERROR "No records match selection criteria" 
						SLEEP 1 
						EXIT WHILE 
					END IF 
				ELSE 
					IF base_next_col() THEN 
						EXIT WHILE 
					END IF 
				END IF 

				LET fv_counter = fv_counter + 1 
				LET fa_rptcol[fv_counter].col_code = gr_rptcolgrp.col_code 
				IF gr_rptcol.col_id > 0 OR gr_rptcol.col_id IS NOT NULL THEN 
					LET fa_rptcol[fv_counter].col_id = gr_rptcol.col_id 
					SELECT col_desc INTO fa_rptcol[fv_counter].col_desc 
					FROM rptcoldesc 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND col_code = gr_rptcol.col_code 
					AND col_uid = gr_rptcol.col_uid 
					AND seq_num = 1 
				END IF 

				MESSAGE gr_rptcolgrp.col_code 

				IF fv_counter >= fv_pa_totsize THEN 
					MESSAGE "Only the first ", fv_pa_totsize, " records selected" 
					SLEEP 1 
					MESSAGE "Use more restrictive criteria in QBE" 
					SLEEP 1 
					EXIT WHILE 
				END IF 

			END WHILE 

			MESSAGE fv_counter, " records found" 

			IF fv_counter > 0 THEN 
				#do nothing yet
			ELSE 
				#we will INITIALIZE the query text TO NULL TO prevent the browse
				#window FROM automatically exiting in the future
				INITIALIZE gv_query_1 TO NULL 

				#AND INITIALIZE the argument TO NULL so the calling process doesn't
				#reselect it
				INITIALIZE fv_col_code TO NULL 

				#AND also INITIALIZE the gr_rptcol.* RECORD TO NULL as it seems
				#TO want TO take on the last RECORD of the rpthead tables VALUES
				INITIALIZE gr_rptcol.* TO NULL 

				CALL close_scurs_col() 
			END IF 

			SLEEP 1 

			LET gv_num_rows = fv_counter 

			IF fv_counter = 0 THEN 
				CLOSE WINDOW g511 
				RETURN fv_col_code 
			END IF 

			#    MESSAGE "ACC TO SELECT, INT TO abort"
			#        ATTRIBUTE(yellow)
			LET msgresp = kandoomsg("A",1513," ") 

			CALL set_count(fv_counter) 

			LET fv_reselect = false 

			INPUT ARRAY fa_rptcol 
			WITHOUT DEFAULTS 
			FROM sa_rptcol.* 

				BEFORE INPUT 
					CALL publish_toolbar("kandoo","TGW3b","input-arr-fa_rptcol-1") -- albo kd-515 

				ON ACTION "WEB-HELP" -- albo kd-378 
					CALL onlinehelp(getmoduleid(),null) 

				ON KEY (F9) 
					LET fv_reselect = true 
					INITIALIZE gv_query_1 TO NULL 
					EXIT INPUT 

				BEFORE ROW 
					LET fv_idx = arr_curr() 
					LET fv_scrn = scr_line() 
					LET fv_counter = arr_count() 
					IF fv_idx <= fv_counter THEN 
						DISPLAY fa_rptcol[fv_idx].* 
						TO sa_rptcol[fv_scrn].* 
						attribute(magenta) 
						LET gr_rptcol.col_code = fa_rptcol[fv_idx].col_code 
					END IF 

				AFTER ROW 
					IF fv_idx <= fv_counter THEN 
						DISPLAY fa_rptcol[fv_idx].* TO sa_rptcol[fv_scrn].* 
						attribute(normal) 
						IF base_abs_col(fv_idx) THEN 
							ERROR "Record NOT found" 
						END IF 
					END IF 

				AFTER INPUT 
					IF gr_rptcolgrp.col_code IS NULL THEN 
						LET gr_rptcolgrp.col_code = fv_col_code 
						LET gr_rptcol.col_code = fv_col_code 
						LET gr_rptcol.col_id = 1 
					END IF 

			END INPUT 

		END WHILE 

		CLOSE WINDOW g511 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		END IF 

		RETURN gr_rptcol.col_code 

END FUNCTION 
