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

#  This module contains the functions needed TO UPDATE a
#  RECORD in the rptcol table.


###########################################################################
# FUNCTION col_updt(fv_col_shuffle)
# 
# FUNCTION            :   col_updt
# Description         :   This FUNCTION allows the user TO UPDATE an existing
#                         row in the rptcol table. It performs the appropriate
#                         uniqueness AND NOT NULL checks on the VALUES entered
# Incoming parameters :   fv_col_shuffle flag SET WHEN inserting columns.
# RETURN parameters   :   None
# Impact GLOBALS      :   None
# perform screens     :   col_maint
#
###########################################################################
FUNCTION col_updt(fv_col_shuffle) 

	DEFINE fv_idx, 
	fv_scr, 
	fv_cnt, 
	fv_col_width, 
	fv_width_tot INTEGER, 
	fv_ans CHAR(1) , 
	fv_col_shuffle, 
	fv_colcode_added, 
	fv_colid_added, 
	fv_count SMALLINT 

	DEFINE fv_seq_num LIKE colitem.seq_num, 
	fv_amt_picture LIKE rptcol.amt_picture, 
	fv_col_id LIKE rptcol.col_id 

	IF fv_col_shuffle != true AND fv_col_shuffle != false THEN 
		LET fv_col_shuffle = false 
	END IF 

	# IF we are adding a COLUMN id TO an existing col code, we want TO bypass the
	# updating of the COLUMN code details
	LET fv_colcode_added = false 
	LET fv_colid_added = false 
	LET gr_rptcol.col_code = gr_rptcolgrp.col_code 

	CASE 
		WHEN fv_col_shuffle = true #insert COLUMN 
			GOTO updt_colid 

		WHEN gr_rptcolgrp.colrptg_type IS NULL #new colcode AND id 
			LET fv_colcode_added = true 
			LET fv_colid_added = true 

		WHEN gr_rptcol.col_id IS NULL 
			LET fv_colid_added = true 
			GOTO updt_colid 
			#  OTHERWISE                                      #Update existing col id
	END CASE 

	DISPLAY "" at 2,1 
	
	INPUT BY NAME 
		gr_rptcolgrp.colgrp_desc, 
		gr_rptcolgrp.colrptg_type WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","TGW3f","input-colgrp_desc-1") -- albo kd-515 

		ON ACTION "WEB-HELP" -- albo kd-378 
			CALL onlinehelp(getmoduleid(),null) 


				ON ACTION "LOOKUP" ---------- browse infield(colrptg_type) 
					CALL show_rpttype(gr_rptcolgrp.colrptg_type) 
					RETURNING gr_rptcolgrp.colrptg_type 
					DISPLAY BY NAME gr_rptcolgrp.colrptg_type 

		AFTER FIELD colgrp_desc 
			IF gr_rptcolgrp.colgrp_desc IS NULL	OR gr_rptcolgrp.colgrp_desc = " " THEN 
				ERROR "Group description must be entered" 
				NEXT FIELD colgrp_desc 
			END IF 

		AFTER FIELD colrptg_type 
			IF gr_rptcolgrp.colrptg_type IS NULL OR gr_rptcolgrp.colrptg_type = " " THEN 
				ERROR "Reporting type must be entered - try lookup" 
				NEXT FIELD colrptg_type 
			END IF 

			SELECT * INTO gr_rpttype.* 
			FROM rpttype 
			WHERE rpttype_id = gr_rptcolgrp.colrptg_type 
			IF status = notfound THEN 
				ERROR "Invalid REPORT type code. ", "Please enter another" 
				NEXT FIELD colrptg_type 
			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 
	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		CASE 
			WHEN fv_col_shuffle = true 
				ERROR "Insert aborted" 
			WHEN fv_colcode_added 
				ERROR "Add aborted" 
			WHEN fv_colid_added 
				ERROR "Add aborted" 
			OTHERWISE 
				ERROR "Update aborted" 
		END CASE 
		RETURN 
	END IF 

	LABEL updt_colid: 

	#IF adding a new COLUMN, SET AND DISPLAY defaults
	IF fv_colid_added THEN 
		#Work out the next col_id number
		SELECT max(col_id) INTO gr_rptcol.col_id 
		FROM rptcol 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND col_code = gr_rptcol.col_code 

		IF gr_rptcol.col_id IS NULL OR gr_rptcol.col_id = 0 THEN 
			LET gr_rptcol.col_id = 1 
		ELSE 
			LET gr_rptcol.col_id = gr_rptcol.col_id + 1 
		END IF 

		DISPLAY BY NAME gr_rptcol.col_id 
	END IF 

	#DISPLAY "" AT 2,1
	#DISPLAY "F7 Analysis across, ACC TO accept changes, OR INT TO cancel" AT 2,1
	#  ATTRIBUTE(yellow)
	LET msgresp = kandoomsg("G",1605," ") 

	LET gv_coldesc_cnt = 3 
	
	INPUT 
		ga_rptcoldesc[1].col_desc, 
		ga_rptcoldesc[2].col_desc, 
		ga_rptcoldesc[3].col_desc, 
		gr_rptcol.width, 
		gr_rptcol.amt_picture, 
		gr_rptcol.curr_type, 
		gr_rptcol.print_flag	WITHOUT DEFAULTS 
	FROM 
		sa_rptcol[1].col_desc, 
		sa_rptcol[2].col_desc, 
		sa_rptcol[3].col_desc, 
		rptcol.width, 
		rptcol.amt_picture, 
		curr_type, 
		print_flag 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","TGW3f","input-col_desc-1") -- albo kd-515 

		ON ACTION "WEB-HELP" -- albo kd-378 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (f7) #segment entry OF analysis across type report. 
			IF gr_rptcol.col_uid IS NULL THEN 
				ERROR "Column header details must be saved before entering ", 
				"Segment maintenance " 
			ELSE 
				CALL seg_anal_across(gr_rptcol.col_uid) 
			END IF 

		BEFORE FIELD width 
			# Default the COLUMN width TO the maximum COLUMN header length.
			LET fv_col_width = 0 
			FOR fv_idx = 1 TO gv_coldesc_cnt 
				IF length( ga_rptcoldesc[fv_idx].col_desc ) > fv_col_width THEN 
					LET fv_col_width = length( ga_rptcoldesc[fv_idx].col_desc ) 
				END IF 
			END FOR 

			IF gr_rptcol.width IS NULL THEN 
				LET gr_rptcol.width = fv_col_width + 1 
				DISPLAY BY NAME gr_rptcol.width 
			END IF 

		BEFORE FIELD amt_picture 
			# Default
			IF fv_colid_added THEN #new COLUMN 
				IF gr_rptcol.amt_picture IS NULL 
				OR gr_rptcol.amt_picture = " " THEN 
					INITIALIZE fv_amt_picture TO NULL 
					DECLARE picture_curs CURSOR FOR 
					SELECT amt_picture, 
					col_id 
					FROM rptcol 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND col_code = gr_rptcolgrp.col_code 
					ORDER BY col_id desc 

					FOREACH picture_curs INTO fv_amt_picture, fv_col_id 
						IF fv_amt_picture IS NULL 
						OR fv_amt_picture = " " THEN 
							CONTINUE FOREACH 
						ELSE 
							EXIT FOREACH 
						END IF 
					END FOREACH 

					IF fv_amt_picture IS NULL 
					OR fv_amt_picture = " " THEN 
						LET fv_amt_picture = "(((,(((,((&.&&)" 
					END IF 

					LET gr_rptcol.amt_picture = fv_amt_picture 
					DISPLAY BY NAME gr_rptcol.amt_picture 
				END IF 
			END IF 

		BEFORE FIELD curr_type 
			IF gr_rptcol.curr_type IS NULL THEN 
				LET gr_rptcol.curr_type = "B" 
			END IF 

		BEFORE FIELD print_flag 
			IF gr_rptcol.print_flag IS NULL THEN 
				LET gr_rptcol.print_flag = "Y" 
			END IF 

		AFTER FIELD width 
			IF gr_rptcol.width IS NULL THEN 
				LET gr_rptcol.width = fv_col_width 
				DISPLAY BY NAME gr_rptcol.width 
			END IF 

			IF gr_rptcol.width > 60 THEN 
				LET gr_rptcol.width = 60 
				ERROR " Individual COLUMN width IS a maximum of 60 " 
				DISPLAY BY NAME gr_rptcol.width 
			END IF 

			#  Check the total width of the REPORT, IF COLUMN IS TO be printed.
			#  Must be less than 132.

			IF gr_rptcol.print_flag = "Y" THEN 
				SELECT sum(width) INTO fv_width_tot 
				FROM rptcol 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND col_code = gr_rptcol.col_code 
				AND col_id <> gr_rptcol.col_id 
				AND print_flag = "Y" 

				LET fv_width_tot = fv_width_tot + gr_rptcol.width 

				IF fv_width_tot > 132 AND gr_rptcol.width != 0 THEN 
					ERROR "Total width exceeds 132 FOR all columns in this REPORT." 
					LET gr_rptcol.width = 132 - fv_width_tot 
					DISPLAY BY NAME gr_rptcol.width 
					NEXT FIELD rptcol.width 
				END IF 
			END IF 

			#Check that the COLUMN header description length
			#does NOT exceed the COLUMN width.
			IF gr_rptcol.width > 0 AND gr_rptcol.width < (fv_col_width + 1) THEN 
				ERROR "Warning: Column Width IS less than Column Description " 
			END IF 

		AFTER FIELD amt_picture 
			IF gr_rptcol.amt_picture IS NOT NULL 
			AND gr_rptcol.amt_picture <> " " THEN 
				IF length(gr_rptcol.amt_picture clipped) > gr_rptcol.width THEN 
					ERROR "Format length IS too long FOR width" 
					NEXT FIELD rptcol.width 
				END IF 
			END IF 

		AFTER FIELD curr_type 
			IF gr_rptcol.curr_type IS NULL THEN 
				ERROR "Currency type must be entered" 
				NEXT FIELD curr_type 
			END IF 

			IF NOT gr_rptcol.curr_type matches "[BT]" THEN 
				ERROR "Currency type must be Base/Transaction" 
				NEXT FIELD curr_type 
			END IF 

		AFTER FIELD print_flag 
			IF gr_rptcol.print_flag IS NULL THEN 
				ERROR "Print indicator must be entered" 
				NEXT FIELD print_flag 
			END IF 

			IF NOT gr_rptcol.print_flag matches "[YN]" THEN 
				ERROR "Please enter (Y)es OR (N)o" 
				NEXT FIELD print_flag 
			END IF 
	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		CASE 
			WHEN fv_col_shuffle = true 
				ERROR "Insert aborted" 
			WHEN fv_colcode_added 
				ERROR "Add aborted" 
			WHEN fv_colid_added 
				ERROR "Add aborted" 
			OTHERWISE 
				ERROR "Update aborted" 
		END CASE 
		RETURN 
	END IF 

	# fv_colid_added indicates the adding of a COLUMN id
	# fv_colcode_added indicates the adding of both a COLUMN code AND COLUMN id

	IF fv_colcode_added THEN 
		INSERT INTO rptcolgrp 
		VALUES (glob_rec_kandoouser.cmpy_code, gr_rptcolgrp.col_code, 
		gr_rptcolgrp.colrptg_type, gr_rptcolgrp.colgrp_desc) 
	ELSE 
		UPDATE rptcolgrp 
		SET (colrptg_type, colgrp_desc) 
		= (gr_rptcolgrp.colrptg_type, gr_rptcolgrp.colgrp_desc) 
		WHERE cmpy_code = gr_rptcolgrp.cmpy_code 
		AND col_code = gr_rptcolgrp.col_code 
	END IF 

	#Save added/UPDATE REPORT COLUMN header details.
	CALL save_rptcol(gr_rptcol.col_id, fv_col_shuffle) 
	RETURNING gr_rptcol.col_uid 

	#DISPLAY "" AT 2,1
	#DISPLAY "F1 TO add, F2 TO delete, F7 analysis, ACC TO accept, INT TO cancel"
	#     AT 2,1  ATTRIBUTE(yellow)
	LET msgresp = kandoomsg("G",1606," ") 

	CALL set_count(gv_colitem_cnt) 
	INPUT ARRAY ga_colitem WITHOUT DEFAULTS 
	FROM sa_colitem.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","TGW3f","input-arr-ga_colitem-1") -- albo kd-515 

		ON ACTION "WEB-HELP" -- albo kd-378 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (f7) #segment entry OF analysis across type report. 
			CALL seg_anal_across(gr_rptcol.col_uid) 

		BEFORE ROW 
			LET fv_idx = arr_curr() 
			LET fv_scr = scr_line() 
			LET fv_seq_num = ga_colitem[fv_idx].seq_num 
			LET gv_colitem_cnt = arr_count() 
			IF gv_colitem_cnt > 20 THEN 
				ERROR "Maximum Number of Column Items IS 20" 
				LET gv_colitem_cnt = 20 
				NEXT FIELD col_item 
			END IF 

		AFTER ROW 
			#Get the item_type FROM mrwitem table.
			SELECT item_desc 
			INTO ga_colitem[fv_idx].item_desc 
			FROM mrwitem 
			WHERE item_id = ga_colitem[fv_idx].col_item 

			IF status = notfound THEN 
				LET ga_colitem[fv_idx].item_desc = NULL 
			ELSE 
				DISPLAY ga_colitem[fv_idx].item_desc 
				TO sa_colitem[fv_scr].item_desc 

				#Update ARRAY COLUMN item information in temp table
				UPDATE colitem 
				SET col_item = ga_colitem[fv_idx].col_item, 
				item_operator = ga_colitem[fv_idx].item_operator 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND col_code = gr_rptcolgrp.col_code 
				AND col_uid = gr_rptcol.col_uid 
				AND seq_num = ga_colitem[fv_idx].seq_num 
			END IF 

				ON ACTION "LOOKUP" infield(item_operator)---------- browse infield(item_operator) 
					CALL show_operator(ga_colitem[fv_idx].item_operator) 
					RETURNING ga_colitem[fv_idx].item_operator 
					DISPLAY BY NAME ga_colitem[fv_idx].item_operator 

				ON ACTION "LOOKUP" infield(col_item) ---------- browse infield(col_item) 
					CALL show_mrwitem(ga_colitem[fv_idx].col_item) 
					RETURNING ga_colitem[fv_idx].col_item 

					SELECT item_desc INTO ga_colitem[fv_idx].item_desc 
					FROM mrwitem 
					WHERE item_id = ga_colitem[fv_idx].col_item 

					DISPLAY BY NAME ga_colitem[fv_idx].col_item, 
					ga_colitem[fv_idx].item_desc 


		AFTER DELETE 
			# delete seq_num line.
			CALL delete_col(gr_rptcol.col_uid, fv_seq_num, fv_idx, fv_scr) 

		BEFORE INSERT 
			# Increment seq_num lines.
			CALL increment_lines(gr_rptcol.col_uid, fv_seq_num, fv_idx, fv_scr) 
			RETURNING fv_seq_num 

		AFTER INSERT 
			IF NOT (int_flag OR quit_flag) THEN 
				INSERT INTO colitem 
				VALUES ( glob_rec_kandoouser.cmpy_code, 
				gr_rptcol.col_code, 
				gr_rptcol.col_uid, 
				ga_colitem[fv_idx].seq_num, 
				ga_colitem[fv_idx].col_item, 
				ga_colitem[fv_idx].item_operator) 
			END IF 

		AFTER FIELD col_item 
			SELECT * INTO gr_mrwitem.* 
			FROM mrwitem 
			WHERE item_id = ga_colitem[fv_idx].col_item 

			IF status = notfound THEN 
				INITIALIZE gr_mrwitem.* TO NULL 
				ERROR "Invalid COLUMN item code." 
				NEXT FIELD col_item 
			END IF 

			IF gr_mrwitem.item_type = gr_mrwparms.constant_item_type THEN 
				SELECT count(*) 
				INTO fv_count 
				FROM colitem 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND col_code = gr_rptcolgrp.col_code 
				AND col_uid = gr_rptcol.col_uid 
				AND seq_num <> ga_colitem[fv_idx].seq_num 
				IF fv_count > 0 THEN 
					ERROR "You can only have one item with this item type" 
					NEXT FIELD col_item 
				END IF 
			END IF 

			IF ga_colitem[fv_idx].item_operator IS NULL 
			OR ga_colitem[fv_idx].item_operator = " " THEN 
				CASE 
					WHEN gr_mrwitem.item_type = gr_mrwparms.constant_item_type 
					WHEN gr_mrwitem.item_type = gr_mrwparms.blank_item_type 
					WHEN gr_mrwitem.item_type = gr_mrwparms.curr_item_type 
					OTHERWISE 
						ERROR "Item operator must be entered with this item type" 
						NEXT FIELD item_operator 
				END CASE 
			END IF 

		BEFORE FIELD item_desc 
			IF maint_col_details(gr_rptcol.col_uid, fv_idx, fv_scr) THEN 
				NEXT FIELD col_item 
			END IF 
			NEXT FIELD item_operator 

		AFTER FIELD item_operator 
			#Only allow '+' OR '-' FOR the first ARRAY element.
			IF fv_idx = 1 THEN 
				CASE 
					WHEN ga_colitem[fv_idx].item_operator = gr_mrwparms.add_op 
					WHEN ga_colitem[fv_idx].item_operator = gr_mrwparms.sub_op 
					WHEN ga_colitem[fv_idx].item_operator = " " 
					WHEN ga_colitem[fv_idx].item_operator IS NULL 
						LET ga_colitem[fv_idx].item_operator = " " 
					OTHERWISE 
						ERROR "Invalid mathematical operator. Please try again." 
						NEXT FIELD item_operator 
				END CASE 
			ELSE 
				CASE 
					WHEN ga_colitem[fv_idx].item_operator = gr_mrwparms.add_op 
					WHEN ga_colitem[fv_idx].item_operator = gr_mrwparms.sub_op 
					WHEN ga_colitem[fv_idx].item_operator = gr_mrwparms.mult_op 
					WHEN ga_colitem[fv_idx].item_operator = gr_mrwparms.div_op 
					WHEN ga_colitem[fv_idx].item_operator = " " 
					WHEN ga_colitem[fv_idx].item_operator IS NULL 
						LET ga_colitem[fv_idx].item_operator = " " 
					OTHERWISE 
						ERROR "Invalid mathematical operator. Please try again." 
						NEXT FIELD item_operator 
				END CASE 
			END IF 

		AFTER INPUT 

			IF NOT (int_flag OR quit_flag) THEN 
				#Get the item_type FROM mrwitem table.
				SELECT item_desc INTO ga_colitem[fv_idx].item_desc 
				FROM mrwitem 
				WHERE item_id = ga_colitem[fv_idx].col_item 

				DISPLAY ga_colitem[fv_idx].item_desc 
				TO sa_colitem[fv_scr].item_desc 

				#Update ARRAY COLUMN item information in temp table
				UPDATE colitem 
				SET col_item = ga_colitem[fv_idx].col_item, 
				item_operator = ga_colitem[fv_idx].item_operator 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND col_code = gr_rptcolgrp.col_code 
				AND col_uid = gr_rptcol.col_uid 
				AND seq_num = ga_colitem[fv_idx].seq_num 
			END IF 

	END INPUT 
	LET gv_colitem_cnt = arr_count() 

	IF int_flag OR quit_flag THEN 
		CASE 
			WHEN fv_col_shuffle = true 
				ERROR "Insert aborted" 
			WHEN fv_colcode_added 
				ERROR "Add aborted" 
			WHEN fv_colid_added 
				ERROR "Add aborted" 
			OTHERWISE 
				ERROR "Update aborted" 
		END CASE 
	END IF 

	LET int_flag = false 
	LET quit_flag = false 

END FUNCTION 
###########################################################################
# FUNCTION col_updt(fv_col_shuffle)
###########################################################################


###########################################################################
# FUNCTION increment_lines(fv_col_uid, fv_seq_num, fv_idx, fv_scr)
#
# FUNCTION:     increment seq_num lines
#  Description:  This FUNCTION increments the seq_num numbers FOR each
#                line in the temp table colitem WHEN inserting new rows.
#
###########################################################################
FUNCTION increment_lines(fv_col_uid, fv_seq_num, fv_idx, fv_scr) 

	DEFINE fv_seq_num, 
	fv_updt_seq, 
	fv_col_uid, 
	fv_num, 
	fv_idx, 
	fv_scr INTEGER 

	#IF fv_seq_num = 0 THEN seq_num = max(seq_num) + 1
	IF fv_seq_num = 0 OR fv_seq_num IS NULL THEN 

		SELECT max(seq_num) + 1 INTO fv_seq_num 
		FROM colitem 
		WHERE col_uid = fv_col_uid 

		IF fv_seq_num IS NULL THEN 
			LET fv_seq_num = 1 
		END IF 

	END IF 

	INITIALIZE ga_colitem[fv_idx].* TO NULL 
	LET ga_colitem[fv_idx].seq_num = fv_seq_num 

	DISPLAY ga_colitem[fv_idx].seq_num TO sa_colitem[fv_scr].seq_num 

	CLEAR item_operator[fv_scr], 
	col_item[fv_scr], 
	id_col_id[fv_scr], 
	item_desc[fv_scr] 

	DECLARE inc_udpt_curs CURSOR FOR 
	SELECT seq_num 
	FROM colitem 
	WHERE col_uid = fv_col_uid 
	AND seq_num >= fv_seq_num 
	ORDER BY seq_num desc 

	FOREACH inc_udpt_curs INTO fv_updt_seq 

		UPDATE colitem 
		SET seq_num = seq_num + 1 
		WHERE col_uid = fv_col_uid 
		AND seq_num >= fv_updt_seq 

		UPDATE colitemval 
		SET seq_num = seq_num + 1 
		WHERE col_uid = fv_col_uid 
		AND seq_num >= fv_updt_seq 

		UPDATE colitemdetl 
		SET seq_num = seq_num + 1 
		WHERE col_uid = fv_col_uid 
		AND seq_num >= fv_updt_seq 

		UPDATE colitemcolid 
		SET seq_num = seq_num + 1 
		WHERE col_uid = fv_col_uid 
		AND seq_num >= fv_updt_seq 

	END FOREACH 

	DECLARE inc_curs CURSOR FOR 
	SELECT seq_num 
	FROM colitem 
	WHERE col_uid = fv_col_uid 
	AND seq_num >= fv_seq_num 
	ORDER BY seq_num 

	# Maintain line number ORDER.
	LET fv_idx = fv_idx + 1 
	FOREACH inc_curs INTO ga_colitem[fv_idx].seq_num 

		IF fv_scr < 5 THEN 
			LET fv_scr = fv_scr + 1 
			DISPLAY ga_colitem[fv_idx].seq_num 
			TO sa_colitem[fv_scr].seq_num 
		END IF 
		LET fv_idx = fv_idx + 1 
	END FOREACH 

	CLOSE inc_curs 

	RETURN fv_seq_num 

END FUNCTION 
###########################################################################
# FUNCTION increment_lines(fv_col_uid, fv_seq_num, fv_idx, fv_scr)
###########################################################################


###########################################################################
# FUNCTION increment_lines(fv_col_uid, fv_seq_num, fv_idx, fv_scr)
#
# FUNCTION:     decrement seq_num lines
#  Description:  This FUNCTION decrements the seq_num numbers FOR each
#                line in the temp table colitem WHEN deleting rows.
#
###########################################################################
FUNCTION decrement_lines(fv_seq_num, fv_col_uid, fv_idx, fv_scr) 

	DEFINE fv_seq_num, 
	fv_col_uid, 
	fv_idx, 
	fv_num, 
	fv_scr INTEGER, 
	fv_s1 CHAR(500) 


	UPDATE colitem 
	SET seq_num = seq_num - 1 
	WHERE col_uid = fv_col_uid 
	AND seq_num > fv_seq_num 

	UPDATE colitemval 
	SET seq_num = seq_num - 1 
	WHERE col_uid = fv_col_uid 
	AND seq_num > fv_seq_num 

	UPDATE colitemdetl 
	SET seq_num = seq_num - 1 
	WHERE col_uid = fv_col_uid 
	AND seq_num > fv_seq_num 

	UPDATE colitemcolid 
	SET seq_num = seq_num - 1 
	WHERE col_uid = fv_col_uid 
	AND seq_num > fv_seq_num 


	DECLARE dec_curs CURSOR FOR 
	SELECT seq_num 
	FROM colitem 
	WHERE col_uid = fv_col_uid 
	AND seq_num >= fv_seq_num 
	ORDER BY seq_num 


	# Maintain line number ORDER.
	FOREACH dec_curs INTO ga_colitem[fv_idx].seq_num 
		IF fv_scr < 5 THEN 
			DISPLAY ga_colitem[fv_idx].seq_num 
			TO sa_colitem[fv_scr].seq_num 
			LET fv_scr = fv_scr + 1 
		END IF 
		LET fv_idx = fv_idx + 1 
	END FOREACH 

	CLOSE dec_curs 

	# Null the last seq_num member of the array.

	LET ga_colitem[fv_idx].seq_num = NULL 
	LET ga_colitem[fv_idx].col_item = NULL 

END FUNCTION 
###########################################################################
# END FUNCTION increment_lines(fv_col_uid, fv_seq_num, fv_idx, fv_scr)
###########################################################################

###########################################################################
# FUNCTION maint_col_details(fv_col_uid, fv_idx, fv_scr)
#
# FUNCTION TO CALL the correct COLUMN information FOR each COLUMN type.
###########################################################################
FUNCTION maint_col_details(fv_col_uid, fv_idx, fv_scr) 

	DEFINE fv_idx, 
	fv_scr, 
	fv_col_uid, 
	fv_seq_num INTEGER 

	#Get the item_type FROM mrwitem table.
	SELECT mrwitem.* INTO gr_mrwitem.* 
	FROM mrwitem 
	WHERE item_id = ga_colitem[fv_idx].col_item 

	LET ga_colitem[fv_idx].id_col_id = NULL 
	LET ga_colitem[fv_idx].item_desc = gr_mrwitem.item_desc 

	DISPLAY ga_colitem[fv_idx].item_desc TO sa_colitem[fv_scr].item_desc 

	# Check the item type against the mrwparms table.
	CASE 
		WHEN gr_mrwparms.time_item_type = gr_mrwitem.item_type 
			CALL time_maint(ga_colitem[fv_idx].seq_num, fv_col_uid) 

		WHEN gr_mrwparms.column_item_type = gr_mrwitem.item_type 
			CALL column_maint(ga_colitem[fv_idx].seq_num, fv_col_uid) 
			DISPLAY ga_colitem[fv_idx].id_col_id TO sa_colitem[fv_scr].id_col_id 

		WHEN gr_mrwparms.value_item_type = gr_mrwitem.item_type 
			CALL value_maint(ga_colitem[fv_idx].seq_num, fv_col_uid) 

		WHEN gr_mrwparms.constant_item_type = gr_mrwitem.item_type 

		WHEN gr_mrwparms.blank_item_type = gr_mrwitem.item_type 

		WHEN gr_mrwparms.curr_item_type = gr_mrwitem.item_type 

		WHEN ga_colitem[fv_idx].col_item IS NULL 
			RETURN true 

		OTHERWISE 
			ERROR "Invalid COLUMN type - please try again" 
			RETURN true 
	END CASE 

	RETURN false 
END FUNCTION 
###########################################################################
# END FUNCTION maint_col_details(fv_col_uid, fv_idx, fv_scr)
###########################################################################


###########################################################################
# FUNCTION save_rptcol(fv_col_id, fv_col_shuffle)
# 
# function:        save REPORT COLUMN header details.
# description:    This FUNCTION saves the REPORT COLUMN header details
#                plus also shuffles any columns along IF needed.
#
###########################################################################
FUNCTION save_rptcol(fv_col_id, fv_col_shuffle) 
	DEFINE fv_updt_id, 
	fv_idx, 
	fv_col_id, 
	fv_col_uid, 
	fv_col_shuffle INTEGER 

	IF fv_col_shuffle THEN 
		DECLARE shuf_cur CURSOR FOR 
		SELECT col_id 
		FROM rptcol 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND col_code = gr_rptcolgrp.col_code 
		AND col_id >= fv_col_id 
		ORDER BY col_id desc 

		FOREACH shuf_cur INTO fv_updt_id 
			UPDATE rptcol 
			SET col_id = col_id + 1 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND col_code = gr_rptcolgrp.col_code 
			AND col_id = fv_updt_id 

		END FOREACH 

	END IF 

	#Get the unique rptcol identifier.
	SELECT col_uid INTO fv_col_uid 
	FROM rptcol 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND col_code = gr_rptcolgrp.col_code 
	AND col_id = fv_col_id 

	IF status = notfound THEN 
		INSERT INTO rptcol VALUES ( 
			glob_rec_kandoouser.cmpy_code, 
			gr_rptcolgrp.col_code, 
			gr_rptcol.col_id, 
			0, 
			gr_rptcol.width, 
			gr_rptcol.amt_picture, 
			gr_rptcol.curr_type, 
			gr_rptcol.print_flag ) 

		LET fv_col_uid = sqlca.sqlerrd[2] 
	ELSE 
		UPDATE rptcol 
		SET width = gr_rptcol.width, 
		amt_picture = gr_rptcol.amt_picture, 
		curr_type = gr_rptcol.curr_type, 
		print_flag = gr_rptcol.print_flag 
		WHERE col_uid = fv_col_uid 
	END IF 

	#Remove the old description lines TO INSERT the new.
	DELETE FROM rptcoldesc 
	WHERE col_uid = fv_col_uid 

	FOR fv_idx = 1 TO 3 #fixed number OF REPORT descriptions. 
		INSERT INTO rptcoldesc VALUES ( glob_rec_kandoouser.cmpy_code, 
		gr_rptcolgrp.col_code, 
		fv_col_uid, 
		fv_idx, 
		ga_rptcoldesc[fv_idx].col_desc) 
	END FOR 

	RETURN fv_col_uid 

END FUNCTION 
###########################################################################
# END FUNCTION save_rptcol(fv_col_id, fv_col_shuffle)
###########################################################################


###########################################################################
# FUNCTION delete_col(fv_col_uid, fv_seq_num, fv_idx, fv_scr)
#
# FUNCTION:        delete_col
#  Description:     Deletes FROM REPORT COLUMN item table.
###########################################################################
FUNCTION delete_col(fv_col_uid, fv_seq_num, fv_idx, fv_scr) 
	DEFINE fv_idx, 
	fv_scr, 
	fv_seq_num, 
	fv_col_uid INTEGER 

	IF fv_col_uid IS NOT NULL THEN 

		# Delete row FROM rptcol table.
		DELETE FROM colitem 
		WHERE col_uid = fv_col_uid 
		AND seq_num = fv_seq_num 

		CALL delete_col_types(fv_seq_num, fv_col_uid) 
	END IF 

	# decrement line_id lines.
	CALL decrement_lines(fv_seq_num, fv_col_uid, fv_idx, fv_scr) 

END FUNCTION 
###########################################################################
# END FUNCTION delete_col(fv_col_uid, fv_seq_num, fv_idx, fv_scr)
###########################################################################


###########################################################################
# FUNCTION delete_col_types(fv_seq_num, fv_col_uid)
# FUNCTION:        delete COLUMN types
#  Description:     Deletes FROM REPORT columns tables as shown in code.
#
###########################################################################
FUNCTION delete_col_types(fv_seq_num, fv_col_uid) 

	DEFINE fv_col_uid, 
	fv_seq_num INTEGER 

	DELETE FROM colitemval 
	WHERE col_uid = fv_col_uid 
	AND seq_num = fv_seq_num 

	DELETE FROM colitemdetl 
	WHERE col_uid = fv_col_uid 
	AND seq_num = fv_seq_num 

	DELETE FROM colitemcolid 
	WHERE col_uid = fv_col_uid 
	AND seq_num = fv_seq_num 

END FUNCTION 
###########################################################################
# END FUNCTION delete_col_types(fv_seq_num, fv_col_uid)
###########################################################################