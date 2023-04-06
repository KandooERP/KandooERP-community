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

	Source code beautified by beautify.pl on 2020-01-03 10:10:02	$Id: $
}




# This process will use SCREEN brwsrpt.frm TO enable the viewing of the
# rpthead table.

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "T_GW_GLOBALS.4gl" 
GLOBALS "TGW2_GLOBALS.4gl" 

FUNCTION hdr_brws(fv_rpt_id) 

	DEFINE 
	fv_rpt_id LIKE rpthead.rpt_id, 

	fa_rpthead array[50] OF RECORD 
		rpt_id LIKE rpthead.rpt_id, 
		rpt_text LIKE rpthead.rpt_text 
	END RECORD, 

	fv_pa_totsize SMALLINT, #the size OF the program ARRAY (50) 
	fv_scrn, fv_idx, fv_counter SMALLINT, 
	fv_s1 CHAR(600), 
	fv_reselect SMALLINT 

	LET fv_pa_totsize = 50 

	OPEN WINDOW g501 with FORM "TG501" 
	CALL windecoration_t(formname) -- albo kd-768 

	LET fv_reselect = true 

	WHILE fv_reselect 

		CLEAR FORM 

		IF gv_query_1 IS NULL THEN 
			#MESSAGE "Enter criteria, ACC TO start query"
			#    ATTRIBUTE(yellow)
			LET msgresp = kandoomsg("U",1001," ") 
			CALL close_scurs_hdr() 
			CONSTRUCT gv_query_1 
			ON rpthead.rpt_id, 
			rpthead.rpt_text 
			FROM rpthead[1].rpt_id, 
			rpthead[1].rpt_text 

				BEFORE CONSTRUCT 
					CALL publish_toolbar("kandoo","TGW2b","construct-rpthead-1") -- albo kd-515 

				ON ACTION "WEB-HELP" -- albo kd-378 
					CALL onlinehelp(getmoduleid(),null) 

			END CONSTRUCT 

			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				CLOSE WINDOW g501 
				RETURN fv_rpt_id 
			END IF 
		END IF 

		IF gv_scurs_hdr_open THEN 
			#do nothing
		ELSE 
			CALL hdr_curs() 
		END IF 

		LET fv_counter = 0 

		WHILE true 
			IF fv_counter = 0 THEN 
				IF base_first_hdr() THEN 
					ERROR "No records match selection criteria" 
					SLEEP 1 
					EXIT WHILE 
				END IF 
			ELSE 
				IF base_next_hdr() THEN 
					EXIT WHILE 
				END IF 
			END IF 
			LET fv_counter = fv_counter + 1 
			LET fa_rpthead[fv_counter].rpt_id = gr_rpthead.rpt_id 
			LET fa_rpthead[fv_counter].rpt_text = gr_rpthead.rpt_text 

			MESSAGE gr_rpthead.rpt_id 

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
			INITIALIZE fv_rpt_id TO NULL 

			#AND also INITIALIZE the gr_rpthead.* RECORD TO NULL as it seems
			#TO want TO take on the last RECORD of the rpthead tables VALUES
			INITIALIZE gr_rpthead.* TO NULL 

			CALL close_scurs_hdr() 
		END IF 
		SLEEP 1 
		LET gv_num_rows = fv_counter 
		IF fv_counter = 0 THEN 
			CLOSE WINDOW g501 
			RETURN fv_rpt_id 
		END IF 

		# MESSAGE "ACC TO SELECT; INT TO abort;"
		#     ATTRIBUTE(yellow)
		LET msgresp = kandoomsg("A",1513," ") 

		CALL set_count(fv_counter) 

		LET fv_reselect = false 

		INPUT ARRAY fa_rpthead 
		WITHOUT DEFAULTS 
		FROM sa_rpthead.* 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","TGW2b","input-arr-fa_rpthead-1") -- albo kd-515 

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
					DISPLAY fa_rpthead[fv_idx].* 
					TO sa_rpthead[fv_scrn].* 
					attribute(magenta) 
					LET gr_rpthead.rpt_id = fa_rpthead[fv_idx].rpt_id 
				END IF 

			AFTER ROW 
				IF fv_idx <= fv_counter THEN 
					DISPLAY fa_rpthead[fv_idx].* TO sa_rpthead[fv_scrn].* 
					attribute(normal) 
					IF base_abs_hdr(fv_idx) THEN 
						ERROR "Record NOT found" 
					END IF 
				END IF 

			AFTER INPUT 
				IF gr_rpthead.rpt_id IS NULL THEN 
					LET gr_rpthead.rpt_id = fv_rpt_id 
				END IF 

		END INPUT 

	END WHILE 

	CLOSE WINDOW g501 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 

	RETURN gr_rpthead.rpt_id 

END FUNCTION 
