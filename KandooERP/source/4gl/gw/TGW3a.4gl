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

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "T_GW_GLOBALS.4gl" 
GLOBALS "TGW3_GLOBALS.4gl" 

###########################################################################
#    This module contains the functions needed TO add a
#    new RECORD TO the rptcol table.
###########################################################################


###########################################################################
# FUNCTION col_add() 
###########################################################################
# FUNCTION            :   col_add
# Description         :   This FUNCTION allows the user TO add a new
#                         row TO the rptcol table. It performs the appropriate
#                         uniqueness AND NOT NULL checks on the VALUES entered
# Incoming parameters :   None
# RETURN parameters   :   None
# Impact GLOBALS      :   None
# perform screens     :   col_maint
# 
###########################################################################
FUNCTION col_add() 

	DEFINE fv_idx, 
	fv_scrn, 
	fv_cnt, 
	fv_width_tot INTEGER, 
	fv_field CHAR(10) 

	DEFINE fr_mrwitem RECORD LIKE mrwitem.* 

	CLEAR FORM 


	# "Press ACC TO accept, OR INT TO cancel" AT 2,1
	LET msgresp = kandoomsg("A",1511," ") 

	INPUT BY NAME gr_rptcolgrp.col_code 
	WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","TGW3a","input-col_code-1") -- albo kd-515 

		ON ACTION "WEB-HELP" -- albo kd-378 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD col_code 
			IF gr_rptcolgrp.col_code IS NULL 
			OR gr_rptcolgrp.col_code = " " THEN 
				ERROR "Column code must be entered" 
				NEXT FIELD col_code 
			END IF 

			SELECT * 
			INTO gr_rptcolgrp.* 
			FROM rptcolgrp 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
			col_code = gr_rptcolgrp.col_code 

			IF status = notfound THEN 
				IF upshift(kandoomsg ("G",9600,"")) = "Y" THEN 
					INITIALIZE gr_rptcol.* TO NULL 
					INITIALIZE gr_rptcolgrp.colgrp_desc TO NULL 
					INITIALIZE gr_rptcolgrp.colrptg_type TO NULL 
				ELSE 
					NEXT FIELD col_code 
				END IF 
			ELSE 
				DISPLAY BY NAME gr_rptcolgrp.colgrp_desc, 
				gr_rptcolgrp.colrptg_type 
				INITIALIZE gr_rptcol.* TO NULL 
			END IF 
	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 
	END IF 

	FOR fv_idx = 1 TO 3 
		INITIALIZE ga_rptcoldesc[fv_idx] TO NULL 
	END FOR 

	FOR fv_idx = 1 TO gv_colitem_cnt 
		INITIALIZE ga_colitem[fv_idx] TO NULL 
	END FOR 

	#Set Default add attributes
	LET gv_colitem_cnt = 0 

	CALL col_updt(false) 

	IF gv_scurs_col_open THEN 
		CALL col_curs() 
		CALL last_col(false) 
	END IF 

END FUNCTION 
###########################################################################
# END FUNCTION col_add() 
###########################################################################


 
###########################################################################
# FUNCTION seg_anal_across(fv_col_uid)
#
# FUNCTION:        seg_anal_across()
# Description:     FUNCTION FOR entry of analysis across section REPORT.
###########################################################################
FUNCTION seg_anal_across(fv_col_uid) 

	DEFINE fa_segcol array[100] OF RECORD 
		start_num LIKE rptcolaa.start_num, 
		flex_clause LIKE rptcolaa.flex_clause 
	END RECORD 

	DEFINE fr_rptcolaa RECORD LIKE rptcolaa.*, 
	fv_col_uid, 
	fv_saa_cnt, 
	fv_scrn, 
	fv_idx INTEGER 

	IF gr_rptcolgrp.colrptg_type != gr_mrwparms.analacross_type THEN 
		ERROR "Column IS NOT an Analysis across type." 
		RETURN 
	END IF 

	OPEN WINDOW g530 with FORM "TG530" 
	CALL windecoration_t("TG530") -- albo kd-768 

	DECLARE segcol_curs CURSOR FOR 
	SELECT rptcolaa.* 
	FROM rptcolaa 
	WHERE rptcolaa.col_uid = fv_col_uid 

	LET fv_saa_cnt = 0 
	FOREACH segcol_curs INTO fr_rptcolaa.* 
		LET fv_saa_cnt = fv_saa_cnt + 1 
		LET fa_segcol[fv_saa_cnt].start_num = fr_rptcolaa.start_num 
		LET fa_segcol[fv_saa_cnt].flex_clause = fr_rptcolaa.flex_clause 

		IF fv_saa_cnt < 6 THEN 
			DISPLAY fa_segcol[fv_saa_cnt].start_num TO sa_segcol[fv_saa_cnt].start_num 
			DISPLAY fa_segcol[fv_saa_cnt].flex_clause TO sa_segcol[fv_saa_cnt].flex_clause 
		END IF 
	END FOREACH 

	CALL set_count(fv_saa_cnt) 
	
	INPUT ARRAY fa_segcol WITHOUT DEFAULTS FROM sa_segcol.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","TGW3a","input-arr-fa_segcol-1") -- albo kd-515 

		ON ACTION "WEB-HELP" -- albo kd-378 
			CALL onlinehelp(getmoduleid(),null) 


				ON ACTION "LOOKUP" infield(start_num) ---------- browse infield(start_num) 
					LET fa_segcol[fv_idx].start_num = strucdwind(glob_rec_kandoouser.cmpy_code) 
					DISPLAY fa_segcol[fv_idx].start_num 
					TO sa_segcol[fv_scrn].start_num 

				ON ACTION "LOOKUP" infield(flex_clause)---------- browse infield(flex_clause) 
					CALL show_flex(glob_rec_kandoouser.cmpy_code, fa_segcol[fv_idx].start_num) 
					RETURNING fa_segcol[fv_idx].flex_clause 

					DISPLAY fa_segcol[fv_idx].flex_clause TO sa_segcol[fv_scrn].flex_clause 


		BEFORE ROW 
			LET fv_idx = arr_curr() 
			LET fv_scrn = scr_line() 
			IF fv_idx > 99 THEN 
				ERROR "Maximum number of rows IS 100." 
				LET fv_idx = 100 
				NEXT FIELD start_num 
			END IF 


		BEFORE FIELD start_num 
			IF fa_segcol[fv_idx].start_num = 0 THEN 
				LET fa_segcol[fv_idx].start_num = NULL 
			END IF 

		AFTER FIELD start_num 
			IF fa_segcol[fv_idx].start_num IS NULL THEN 
				#         ERROR "Start number must be entered - try lookup"
				#         NEXT FIELD start_num
			ELSE 
				# Check that this IS a valid start_num FROM within the structure table.
				SELECT * 
				FROM structure 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND start_num = fa_segcol[fv_idx].start_num 
				AND type_ind = "S" 

				IF status THEN 
					ERROR "Invalid start number FROM within the account structure." 
					NEXT FIELD start_num 
				END IF 
			END IF 

		AFTER FIELD flex_clause 
			IF fa_segcol[fv_idx].flex_clause IS NULL THEN 
				ERROR "Segment clause must be entered" 
				NEXT FIELD flex_clause 
			END IF 
	END INPUT 

	LET fv_saa_cnt = arr_count() 

	IF NOT (int_flag OR quit_flag) THEN 
		DELETE FROM rptcolaa 
		WHERE col_uid = fv_col_uid 

		FOR fv_idx = 1 TO fv_saa_cnt 
			IF fa_segcol[fv_idx].start_num IS NOT NULL 
			AND fa_segcol[fv_idx].flex_clause IS NOT NULL THEN 
				INSERT INTO rptcolaa VALUES ( glob_rec_kandoouser.cmpy_code, 
				gr_rptcol.col_code, 
				fv_col_uid, 
				fv_idx, 
				fa_segcol[fv_idx].start_num, 
				fa_segcol[fv_idx].flex_clause) 
			END IF 
		END FOR 
	END IF 

	LET int_flag = false 
	LET quit_flag = false 

	CLOSE WINDOW g530 

END FUNCTION 
###########################################################################
# END FUNCTION seg_anal_across(fv_col_uid)
###########################################################################


###########################################################################
# FUNCTION time_maint(fv_seq_num, fv_col_uid) 
#
#
###########################################################################
FUNCTION time_maint(fv_seq_num, fv_col_uid) 

	DEFINE fv_idx, 
	fv_col_uid, 
	fv_seq_num INTEGER, 
	fr_colitemdetl RECORD LIKE colitemdetl.* 


	OPEN WINDOW g514 with FORM "TG514" 
	CALL windecoration_t("TG514") -- albo kd-768 

	IF fv_col_uid > 0 AND fv_col_uid IS NOT NULL THEN 
		SELECT * INTO fr_colitemdetl.* 
		FROM colitemdetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND col_code = gr_rptcol.col_code 
		AND col_uid = fv_col_uid 
		AND seq_num = fv_seq_num 

	END IF 

	IF fr_colitemdetl.year_num IS NULL THEN 
		LET fr_colitemdetl.year_num = 0 
	END IF 

	IF fr_colitemdetl.year_type IS NULL THEN 
		LET fr_colitemdetl.year_type = gr_mrwparms.offset_type 
	END IF 

	IF fr_colitemdetl.period_num IS NULL THEN 
		LET fr_colitemdetl.period_num = 0 
	END IF 

	IF fr_colitemdetl.period_type IS NULL THEN 
		LET fr_colitemdetl.period_type = gr_mrwparms.offset_type 
	END IF 

	DISPLAY BY NAME 
		ga_colitem[fv_seq_num].col_item, 
		ga_colitem[fv_seq_num].item_desc attribute(yellow) 

	#MESSAGE "ACC TO accept, INT TO cancel" attribute (yellow)
	LET msgresp = kandoomsg("A",1511," ") 

	INPUT BY NAME 
		fr_colitemdetl.year_num, 
		fr_colitemdetl.year_type, 
		fr_colitemdetl.period_num, 
		fr_colitemdetl.period_type WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","TGW3a","input-year_num-1") -- albo kd-515 

		ON ACTION "WEB-HELP" -- albo kd-378 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE FIELD year_num 
			DISPLAY "" at 10,2 
			DISPLAY "" at 11,2 
			DISPLAY "Year relative TO current year eg. -100, 0, 100" at 10,2 
			DISPLAY "OR Specific year eg. 19XX" at 11,2 

		BEFORE FIELD year_type 
			DISPLAY "" at 10,2 
			DISPLAY "" at 11,2 
			DISPLAY "DEFINE value entered in Year Number as " at 10,2 
			DISPLAY " O = Offset value OR S = Specific Year. " at 11,2 

		BEFORE FIELD period_num 
			DISPLAY "" at 10,2 
			DISPLAY "" at 11,2 
			DISPLAY "Period relative TO current period." at 10,2 
			DISPLAY "OR Specific Period" at 11,2 

		BEFORE FIELD period_type 
			DISPLAY "" at 10,2 
			DISPLAY "" at 11,2 
			DISPLAY "DEFINE value entered in Period Number as " at 10,2 
			DISPLAY " O = Offset value OR S = Specific Period. " at 11,2 

		AFTER FIELD year_num 
			IF fr_colitemdetl.year_num IS NULL THEN 
				ERROR "Year number must be entered" 
				NEXT FIELD year_num 
			END IF 

		AFTER FIELD year_type 
			IF fr_colitemdetl.year_type IS NULL THEN 
				ERROR "Year type must be entered" 
				NEXT FIELD year_type 
			END IF 

			IF fr_colitemdetl.year_type NOT matches "[OS]" THEN 
				ERROR "Must be 'O' FOR Offset OR 'S' FOR Specific" 
				NEXT FIELD year_type 
			END IF 

			IF fr_colitemdetl.year_type = gr_mrwparms.offset_type THEN 
				IF fr_colitemdetl.year_num >= -100 
				AND fr_colitemdetl.year_num <= 100 THEN 
				ELSE 
					ERROR "Invalid offset year range. Valid range IS -100 TO 100." 
					NEXT FIELD year_num 
				END IF 
			END IF 

			IF fr_colitemdetl.year_type = gr_mrwparms.specific_type THEN 
				SELECT unique year_num FROM period 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND year_num = fr_colitemdetl.year_num 

				IF status = notfound THEN 
					ERROR "Invalid year number." 
					NEXT FIELD year_num 
				END IF 
			END IF 


		AFTER FIELD period_type 
			IF fr_colitemdetl.period_type IS NULL THEN 
				ERROR "Period type must be entered" 
				NEXT FIELD period_type 
			END IF 

			IF fr_colitemdetl.period_type NOT matches "[OS]" THEN 
				ERROR "Must be 'O' FOR Offset OR 'S' FOR Specific" 
				NEXT FIELD period_type 
			END IF 

			IF fr_colitemdetl.period_type = gr_mrwparms.specific_type THEN 
				SELECT unique period_num FROM period 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND period_num = fr_colitemdetl.period_num 

				IF status = notfound THEN 
					ERROR "Invalid period number." 
					NEXT FIELD period_num 
				END IF 
			END IF 

			IF fr_colitemdetl.year_type = gr_mrwparms.specific_type 
			AND fr_colitemdetl.period_type = gr_mrwparms.specific_type THEN 

				SELECT * FROM period 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND year_num = fr_colitemdetl.year_num 
				AND period_num = fr_colitemdetl.period_num 

				IF status = notfound THEN 
					ERROR "Invalid period number." 
					NEXT FIELD period_num 
				END IF 
			END IF 

		AFTER INPUT 
			IF fr_colitemdetl.year_num IS NULL THEN 
				ERROR "Year number must be entered" 
				NEXT FIELD year_num 
			END IF 

			IF fr_colitemdetl.year_type IS NULL THEN 
				ERROR "Year type must be entered" 
				NEXT FIELD year_type 
			END IF 

			IF fr_colitemdetl.year_type NOT matches "[OS]" THEN 
				ERROR "Must be 'O' FOR Offset OR 'S' FOR Specific" 
				NEXT FIELD year_type 
			END IF 

			IF fr_colitemdetl.year_type = gr_mrwparms.offset_type THEN 
				IF fr_colitemdetl.year_num >= -100 
				AND fr_colitemdetl.year_num <= 100 THEN 
				ELSE 
					ERROR "Invalid offset year range. Valid range IS -100 TO 100." 
					NEXT FIELD year_num 
				END IF 
			END IF 

			IF fr_colitemdetl.year_type = gr_mrwparms.specific_type THEN 
				SELECT unique year_num FROM period 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND year_num = fr_colitemdetl.year_num 

				IF status = notfound THEN 
					ERROR "Invalid year number." 
					NEXT FIELD year_num 
				END IF 
			END IF 

			IF fr_colitemdetl.period_type IS NULL THEN 
				ERROR "Period type must be entered" 
				NEXT FIELD period_type 
			END IF 

			IF fr_colitemdetl.period_type IS NULL THEN 
				ERROR "Period type must be entered" 
				NEXT FIELD period_type 
			END IF 

			IF fr_colitemdetl.period_type NOT matches "[OS]" THEN 
				ERROR "Must be 'O' FOR Offset OR 'S' FOR Specific" 
				NEXT FIELD period_type 
			END IF 

			IF fr_colitemdetl.period_type = gr_mrwparms.specific_type THEN 
				SELECT unique period_num FROM period 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND period_num = fr_colitemdetl.period_num 

				IF status = notfound THEN 
					ERROR "Invalid period number." 
					NEXT FIELD period_num 
				END IF 
			END IF 

			IF fr_colitemdetl.year_type = gr_mrwparms.specific_type 
			AND fr_colitemdetl.period_type = gr_mrwparms.specific_type THEN 

				SELECT * FROM period 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND year_num = fr_colitemdetl.year_num 
				AND period_num = fr_colitemdetl.period_num 

				IF status = notfound THEN 
					ERROR "Invalid period number." 
					NEXT FIELD period_num 
				END IF 
			END IF 


	END INPUT 

	IF NOT (int_flag OR quit_flag) THEN 
		CALL delete_col_types(fv_seq_num, fv_col_uid) 

		INSERT INTO colitemdetl VALUES ( 
			glob_rec_kandoouser.cmpy_code, 
			gr_rptcol.col_code, 
			fv_col_uid, 
			fv_seq_num, 
			fr_colitemdetl.year_num, 
			fr_colitemdetl.year_type, 
			fr_colitemdetl.period_num, 
			fr_colitemdetl.period_type ) 

	END IF 

	LET int_flag = false 
	LET quit_flag = false 

	CLOSE WINDOW g514 

END FUNCTION 
###########################################################################
# END FUNCTION time_maint(fv_seq_num, fv_col_uid) 
###########################################################################
 


###########################################################################
# FUNCTION column_maint(fv_seq_num, fv_col_uid)
#
#
###########################################################################
FUNCTION column_maint(fv_seq_num, fv_col_uid) 

	DEFINE fv_idx, 
	fv_col_uid, 
	fv_seq_num INTEGER, 
	fr_colitemcolid RECORD LIKE colitemcolid.* 

	OPEN WINDOW g512 with FORM "TG512" 
	CALL windecoration_t("TG512") -- albo kd-768 

	IF fv_col_uid > 0 AND fv_col_uid IS NOT NULL THEN 
		SELECT * 
		INTO fr_colitemcolid.* 
		FROM colitemcolid 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND col_code = gr_rptcol.col_code 
		AND col_uid = fv_col_uid 
		AND seq_num = fv_seq_num 

	END IF 

	DISPLAY BY NAME ga_colitem[fv_seq_num].col_item, 
	ga_colitem[fv_seq_num].item_desc attribute(yellow) 

	#MESSAGE "ACC TO accept, INT TO cancel"
	LET msgresp = kandoomsg("A",1511," ") 

	INPUT BY NAME fr_colitemcolid.id_col_id WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","TGW3a","input-id_col_id-1") -- albo kd-515 

		ON ACTION "WEB-HELP" -- albo kd-378 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD id_col_id 
			IF fr_colitemcolid.id_col_id IS NULL THEN 
				ERROR "Column identifier must be entered" 
				NEXT FIELD id_col_id 
			END IF 

			IF fr_colitemcolid.id_col_id < gr_rptcol.col_id THEN 
				SELECT col_id 
				FROM rptcol 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND col_code = gr_rptcol.col_code 
				AND col_id = fr_colitemcolid.id_col_id 

				IF status = notfound THEN 
					ERROR "Invalid Column identifier." 
					LET fr_colitemcolid.id_col_id = 0 
					NEXT FIELD id_col_id 
				END IF 
			ELSE 
				ERROR "Column identifier must be less than the current COLUMN id." 
				LET fr_colitemcolid.id_col_id = 0 
				NEXT FIELD id_col_id 
			END IF 
	END INPUT 

	IF NOT (int_flag OR quit_flag) THEN 
		LET ga_colitem[fv_seq_num].id_col_id = fr_colitemcolid.id_col_id 

		CALL delete_col_types(fv_seq_num, fv_col_uid) 

		INSERT INTO colitemcolid VALUES ( glob_rec_kandoouser.cmpy_code, 
		gr_rptcol.col_code, 
		fv_col_uid, 
		fv_seq_num, 
		fr_colitemcolid.id_col_id ) 

	END IF 

	LET int_flag = false 
	LET quit_flag = false 

	CLOSE WINDOW g512 

END FUNCTION 
###########################################################################
# END FUNCTION column_maint(fv_seq_num, fv_col_uid)
###########################################################################


###########################################################################
# FUNCTION value_maint(fv_seq_num, fv_col_uid)
#
#
###########################################################################
FUNCTION value_maint(fv_seq_num, fv_col_uid) 

	DEFINE fv_idx, 
	fv_col_uid, 
	fv_seq_num INTEGER 

	DEFINE fr_colitemval RECORD LIKE colitemval.* 

	OPEN WINDOW g515 with FORM "TG515" 
	CALL windecoration_t("TG515") -- albo kd-768 

	IF fv_col_uid > 0 AND fv_col_uid IS NOT NULL THEN 

		SELECT * INTO fr_colitemval.* 
		FROM colitemval 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND col_code = gr_rptcol.col_code 
		AND col_uid = fv_col_uid 
		AND seq_num = fv_seq_num 

	END IF 

	DISPLAY BY NAME 
		ga_colitem[fv_seq_num].col_item, 
		ga_colitem[fv_seq_num].item_desc attribute(yellow) 

	#MESSAGE "ACC TO accept, INT TO cancel"
	LET msgresp = kandoomsg("A",1511," ") 

	INPUT BY NAME fr_colitemval.item_value WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","TGW3a","input-item_value-1") -- albo kd-515 

		ON ACTION "WEB-HELP" -- albo kd-378 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD item_value 
			IF fr_colitemval.item_value IS NULL THEN 
				ERROR "Value must be entered" 
				NEXT FIELD item_value 
			END IF 
	END INPUT 

	IF NOT (int_flag OR quit_flag) THEN 
		CALL delete_col_types(fv_seq_num, fv_col_uid) 

		INSERT INTO colitemval VALUES ( 
			glob_rec_kandoouser.cmpy_code, 
			gr_rptcol.col_code, 
			fv_col_uid, 
			fv_seq_num, 
			fr_colitemval.item_value ) 
	END IF 

	LET int_flag = false 
	LET quit_flag = false 

	CLOSE WINDOW g515 

END FUNCTION 
###########################################################################
# END FUNCTION value_maint(fv_seq_num, fv_col_uid)
###########################################################################