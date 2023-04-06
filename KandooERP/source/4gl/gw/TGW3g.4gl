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

	Source code beautified by beautify.pl on 2020-01-03 10:10:04	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "T_GW_GLOBALS.4gl" 
GLOBALS "TGW3_GLOBALS.4gl" 

FUNCTION col_insert() 

	DEFINE fv_col_id LIKE rptcol.col_id 

	CALL get_col(gr_rptcolgrp.col_code) 
	RETURNING fv_col_id 

	IF int_flag OR quit_flag THEN 
		ERROR "Insert aborted" 
		RETURN 
	END IF 

	IF fv_col_id IS NULL THEN 
		ERROR "Invalid col_id" 
	ELSE 
		CALL insert_col_add(fv_col_id) 
	END IF 

	IF int_flag OR quit_flag THEN 
		ERROR "Insert aborted" 
	ELSE 
		MESSAGE " Insert successful" 
	END IF 

END FUNCTION 

FUNCTION insert_col_add(fv_col_id) 

	DEFINE fv_idx, 
	fv_scr, 
	fv_cnt, 
	fv_width_tot INTEGER, 
	fv_field CHAR(10), 
	fv_col_id LIKE rptcol.col_id 

	DEFINE fr_mrwitem RECORD LIKE mrwitem.* 

	CLEAR FORM 

	#DISPLAY "" AT 2,1
	#DISPLAY "Press ACC TO except the addition, OR INT TO cancel it" AT 2,1
	LET msgresp = kandoomsg("A",1511," ") 

	INITIALIZE gr_rptcol TO NULL 

	LET gr_rptcol.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET gr_rptcol.col_code = gr_rptcolgrp.col_code 
	LET gr_rptcol.col_id = fv_col_id 

	IF gr_rptcol.col_id IS NULL OR gr_rptcol.col_id = 0 THEN 
		LET gr_rptcol.col_id = 1 
	END IF 

	DISPLAY BY NAME gr_rptcolgrp.col_code, 
	gr_rptcolgrp.colgrp_desc, 
	gr_rptcolgrp.colrptg_type, 
	gr_rptcol.col_id, 
	gr_rptcol.amt_picture 

	FOR fv_idx = 1 TO 3 
		INITIALIZE ga_rptcoldesc[fv_idx] TO NULL 
	END FOR 

	FOR fv_idx = 1 TO gv_colitem_cnt 
		INITIALIZE ga_colitem[fv_idx] TO NULL 
	END FOR 

	#Set Default add attributes
	LET gv_colitem_cnt = 0 

	CALL col_updt(true) 

END FUNCTION 

FUNCTION get_col(fv_col_code) 

	DEFINE 
	fv_col_code LIKE rptcol.col_code, 
	fv_col_id LIKE rptcol.col_id, 

	fa_rptcol array[50] OF RECORD 
		col_code LIKE rptcolgrp.col_code, 
		col_id LIKE rptcol.col_id, 
		col_desc LIKE rptcoldesc.col_desc END RECORD, 

		fr_rptcol RECORD 
			rpt_rowid INTEGER, 
			col_code LIKE rptcol.col_code, 
			col_rowid INTEGER, 
			col_id LIKE rptcol.col_id, 
			col_uid LIKE rptcol.col_uid 
		END RECORD, 

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

			LET fv_counter = 0 

			LET fv_s1 = "SELECT rptcolgrp.rowid, rptcolgrp.col_code, ", 
			"rptcol.rowid, rptcol.col_id, rptcol.col_uid ", 
			"FROM rptcolgrp, outer(rptcol) ", 
			"WHERE rptcolgrp.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
			"AND rptcolgrp.cmpy_code = rptcol.cmpy_code ", 
			"AND rptcolgrp.col_code = rptcol.col_code ", 
			"AND rptcolgrp.col_code = '", fv_col_code, "' ", 
			" ORDER BY 2, 4" 

			PREPARE s1 FROM fv_s1 
			DECLARE fv_scurs_col 
			SCROLL CURSOR with HOLD 
			FOR s1 

			OPEN fv_scurs_col 

			FETCH FIRST fv_scurs_col INTO fr_rptcol.* 

			IF status = notfound THEN 
				ERROR "No records match selection criteria" 
			ELSE 
				WHILE true 
					LET fv_counter = fv_counter + 1 
					LET fa_rptcol[fv_counter].col_code = gr_rptcolgrp.col_code 
					IF fr_rptcol.col_id > 0 OR fr_rptcol.col_id IS NOT NULL THEN 
						LET fa_rptcol[fv_counter].col_id = fr_rptcol.col_id 
						SELECT col_desc INTO fa_rptcol[fv_counter].col_desc 
						FROM rptcoldesc 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND col_code = fr_rptcol.col_code 
						AND col_uid = fr_rptcol.col_uid 
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

					FETCH NEXT fv_scurs_col INTO fr_rptcol.* 
					IF status THEN 
						EXIT WHILE 
					END IF 

				END WHILE 

				MESSAGE fv_counter, " records found" 

			END IF 

			IF fv_counter > 0 THEN 
				#do nothing yet
			ELSE 
				#AND INITIALIZE the argument TO NULL so the calling process doesn't
				#reselect it
				INITIALIZE fv_col_code TO NULL 

				#AND also INITIALIZE the gr_rptcol.* RECORD TO NULL as it seems
				#TO want TO take on the last RECORD of the rpthead tables VALUES
				INITIALIZE gr_rptcol.* TO NULL 
			END IF 

			LET gv_num_rows = fv_counter 

			IF fv_counter = 0 THEN 
				CLOSE WINDOW g511 
				RETURN fv_col_code 
			END IF 

			CALL set_count(fv_counter) 

			LET fv_reselect = false 

			#MESSAGE "[ACC] Insert a new COLUMN above  [INT] Exit/Cancel"
			LET msgresp = kandoomsg("U",1512," ") 
			INPUT ARRAY fa_rptcol 
			WITHOUT DEFAULTS 
			FROM sa_rptcol.* 

				BEFORE INPUT 
					CALL publish_toolbar("kandoo","TGW3g","input-arr-fa_rptcol-1") -- albo kd-515 

				ON ACTION "WEB-HELP" -- albo kd-378 
					CALL onlinehelp(getmoduleid(),null) 

				BEFORE ROW 
					LET fv_idx = arr_curr() 
					LET fv_scrn = scr_line() 

					LET fv_counter = arr_count() 
					IF fv_idx <= fv_counter THEN 
						DISPLAY fa_rptcol[fv_idx].* 
						TO sa_rptcol[fv_scrn].* 

						LET fr_rptcol.col_code = fa_rptcol[fv_idx].col_code 
					END IF 

				AFTER ROW 
					IF fv_idx <= fv_counter THEN 
						DISPLAY fa_rptcol[fv_idx].* TO sa_rptcol[fv_scrn].* 
						attribute(normal) 
					END IF 

				AFTER INPUT 

					LET fv_idx = arr_curr() 
					LET fv_scrn = scr_line() 
					LET fv_col_id = fa_rptcol[fv_idx].col_id 
			END INPUT 

		END WHILE 

		CLOSE WINDOW g511 

		IF int_flag OR quit_flag THEN 
			INITIALIZE fv_col_id TO NULL 
		END IF 

		RETURN fv_col_id 

END FUNCTION 
