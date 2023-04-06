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

	Source code beautified by beautify.pl on 2020-01-03 09:12:27	$Id: $
}



############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 

# I58.4gl - Stock Transfers Confirmation

# define module scop variables
	DEFINE 
	modu_arr_ibtdetl DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		line_num LIKE ibtdetl.line_num, 
		part_code LIKE product.part_code, 
		prev_conf LIKE ibtdetl.conf_qty, 
		rec_qty LIKE ibtdetl.rec_qty, 
		conf_qty LIKE ibtdetl.conf_qty, 
		back_qty LIKE ibtdetl.back_qty, 
		sell_uom_code LIKE product.sell_uom_code 
	END RECORD, 
	modu_arr_save_ibtdetl DYNAMIC ARRAY OF RECORD 
		line_num LIKE ibtdetl.line_num, 
		conf_qty LIKE ibtdetl.conf_qty, 
		class_code LIKE product.class_code, 
		back_qty LIKE ibtdetl.back_qty, 
		rec_qty LIKE ibtdetl.rec_qty, 
		part_code LIKE product.part_code, 
		trf_qty LIKE ibtdetl.trf_qty, 
		status_ind LIKE ibtdetl.status_ind, 
		desc_text LIKE product.desc_text 
	END RECORD, 
	modu_rec_ibthead RECORD LIKE ibthead.*, 
	modu_delivery_date DATE, 

	modu_trans_type CHAR(1), 
	modu_orig_rev_num, rpt_pageno SMALLINT 


####################################################################
# MAIN
####################################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("I58") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 

	OPEN WINDOW i668 with FORM "I668" 
	 CALL windecoration_i("I668") -- albo kd-758 

	WHILE select_orders() 
		CALL scan_orders() 
	END WHILE 
	CLOSE WINDOW i668 
END MAIN 


FUNCTION select_orders() 
	DEFINE 
	where_text STRING ,
	query_text STRING 

	CLEAR FORM 
	LET msgresp = kandoomsg("U",1001,"") 
	#1054 Enter Selection Criteria - ESC TO Continue
	CONSTRUCT BY NAME where_text ON trans_num, 
	from_ware_code, 
	to_ware_code, 
	desc_text, 
	trans_date, 
	status_ind 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","I58","construct-trans_num-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	LET query_text = "SELECT ibthead.* FROM ibthead ", 
	"WHERE ibthead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ",
	"AND ibthead.status_ind != '", IBTHEAD_STATUS_IND_TRANSFER_CANCELLED_R, "' ", #IBTHEAD_STATUS_IND_TRANSFER_CANCELLED_R
	"AND ibthead.status_ind != '", IBTHEAD_STATUS_IND_TRANSFER_COMPLETED_C, "' ", #IBTHEAD_STATUS_IND_TRANSFER_COMPLETED_C
--	"AND ibthead.status_ind != 'R' ", 
--	"AND ibthead.status_ind != 'C' ", 
	"AND ibthead.sched_ind = '1' ", 
	"AND ",where_text clipped," ", 
	"ORDER BY from_ware_code,to_ware_code,trans_num desc" 
	WHENEVER ERROR CONTINUE 
	OPTIONS SQL interrupt ON 
	PREPARE s_ibthead FROM query_text 
	DECLARE c_ibthead CURSOR FOR s_ibthead 
	RETURN true 
END FUNCTION 		# select_orders


FUNCTION scan_orders() 
	DEFINE 
	l_scroll_flag CHAR(1), 
	l_arr_ibthead DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		trans_num LIKE ibthead.trans_num, 
		from_ware_code LIKE ibthead.from_ware_code, 
		to_ware_code LIKE ibthead.to_ware_code, 
		desc_text LIKE ibthead.desc_text, 
		trans_date LIKE ibthead.trans_date, 
		status_ind LIKE ibthead.status_ind 
	END RECORD, 
	lt_ibthead RECORD LIKE ibthead.*, 
	del_cnt,i,j,idx,scrn SMALLINT 

	LET msgresp = kandoomsg("U",1002,"") 
	#1002  Searching database - please wait
	LET idx = 0 
	FOREACH c_ibthead INTO modu_rec_ibthead.* 
		SELECT unique 1 FROM ibtdetl 
		WHERE trans_num = modu_rec_ibthead.trans_num 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND back_qty > 0 
		IF status = notfound THEN 
			CONTINUE FOREACH 
		END IF 
		LET idx = idx + 1 
		LET l_arr_ibthead[idx].scroll_flag = NULL 
		LET l_arr_ibthead[idx].trans_num = modu_rec_ibthead.trans_num 
		LET l_arr_ibthead[idx].from_ware_code = modu_rec_ibthead.from_ware_code 
		LET l_arr_ibthead[idx].to_ware_code = modu_rec_ibthead.to_ware_code 
		LET l_arr_ibthead[idx].desc_text = modu_rec_ibthead.desc_text 
		LET l_arr_ibthead[idx].trans_date = modu_rec_ibthead.trans_date 
		LET l_arr_ibthead[idx].status_ind = modu_rec_ibthead.status_ind 
		IF idx = 300 THEN 
			LET msgresp = kandoomsg("U",6100,idx) 
			EXIT FOREACH 
		END IF 
	END FOREACH 
	OPTIONS SQL interrupt off 
	WHENEVER ERROR stop 
	LET msgresp = kandoomsg("U",9113,idx) 
	#9113 idx records selected
	IF idx = 0 THEN 
		LET idx = 1 
		INITIALIZE l_arr_ibthead[1].* TO NULL 
	END IF 
	--OPTIONS DELETE KEY f36, 
	--INSERT KEY f36 
	CALL set_count(idx) 
	LET msgresp = kandoomsg("U",1051,"Confirm") 
	#1154 F3/F4 TO Page Fwd/Bwd;  ENTER on line TO Confirm
	INPUT ARRAY l_arr_ibthead WITHOUT DEFAULTS FROM sr_ibthead.* 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE FIELD scroll_flag 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			LET l_scroll_flag = l_arr_ibthead[idx].scroll_flag 
			DISPLAY l_arr_ibthead[idx].* TO sr_ibthead[scrn].* 

		AFTER FIELD scroll_flag 
			LET l_arr_ibthead[idx].scroll_flag = l_scroll_flag 
			DISPLAY l_arr_ibthead[idx].scroll_flag TO sr_ibthead[scrn].scroll_flag 

			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF arr_curr() >= arr_count() THEN 
					LET msgresp = kandoomsg("U",9001,"") 
					#9001 There no more rows...
					NEXT FIELD scroll_flag 
				END IF 
				IF l_arr_ibthead[idx+1].trans_num IS NULL THEN 
					LET msgresp = kandoomsg("U",9001,"") 
					#9001 There no more rows...
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
		BEFORE FIELD trans_num 
			IF l_arr_ibthead[idx].trans_num IS NULL THEN 
				NEXT FIELD scroll_flag 
			END IF 
			IF l_arr_ibthead[idx].status_ind = "C" THEN 
				LET msgresp = kandoomsg("I",9528,"") 
				#9528 Transfer has been completed.
				NEXT FIELD scroll_flag 
			END IF 
			LET i = arr_count() 
			CALL confirm_transfer(l_arr_ibthead[idx].trans_num) 
			SELECT status_ind INTO l_arr_ibthead[idx].status_ind FROM ibthead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND trans_num = l_arr_ibthead[idx].trans_num 
			DISPLAY l_arr_ibthead[idx].status_ind 
			TO sr_ibthead[scrn].status_ind 

			NEXT FIELD scroll_flag 
		AFTER ROW 
			DISPLAY l_arr_ibthead[idx].* TO sr_ibthead[scrn].* 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 
END FUNCTION 		# scan_orders


FUNCTION confirm_transfer(l_trans_num) 
	DEFINE 
	l_trans_num LIKE ibthead.trans_num, 
	ls_ibtdetl RECORD 
		line_num LIKE ibtdetl.line_num, 
		part_code LIKE product.part_code, 
		trf_qty LIKE ibtdetl.trf_qty, 
		conf_qty LIKE ibtdetl.conf_qty 
	END RECORD, 
	l_rec_ibtrecord RECORD 
		line_num LIKE ibtdetl.line_num, 
		part_code LIKE product.part_code, 
		rec_qty LIKE ibtdetl.trf_qty, 
		conf_qty LIKE ibtdetl.conf_qty, 
		back_qty LIKE ibtdetl.back_qty, 
		sell_uom_code LIKE product.sell_uom_code, 
		desc_text LIKE product.desc_text 
	END RECORD, 
	l_orig_part LIKE product.part_code, 
	l_orig_part2 LIKE product.part_code, 
	l_flex_part_code LIKE product.part_code, 
	l_dashes_part_code LIKE product.part_code, 
	l_save_part_code LIKE product.part_code, 
	l_save2_part_code LIKE product.part_code, 
	l_rec_ibtdetl RECORD LIKE ibtdetl.*, 
	l_rec_product RECORD LIKE product.*, 
	l_rec_product2 RECORD LIKE product.*, 
	l_rec_prodstatus RECORD LIKE prodstatus.*, 
	l_rec_class RECORD LIKE class.*, 
	l_winds_text CHAR(40), 
	l_msg, l_output CHAR(60), 
	l_rms_string, l_filter_text CHAR(100), 
	l_save_date DATE, 
	l_conf_qty LIKE ibtdetl.back_qty, 
	l_serial_cnt SMALLINT, 
	l_conf_qty_type CHAR(1), 
	l_arr_cnt, i, l_invalid_period, l_flex, idx, scrn SMALLINT 

	OPEN WINDOW i670 with FORM "I670" 
	 CALL windecoration_i("I670") -- albo kd-758 

	#   CALL serial_init(glob_rec_kandoouser.cmpy_code, "t", l_trans_num, "" )
	CALL serial_init(glob_rec_kandoouser.cmpy_code, "T", "T", l_trans_num ) 

	SELECT rev_num INTO modu_orig_rev_num FROM ibthead 
	WHERE trans_num = l_trans_num 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	SELECT * INTO modu_rec_ibthead.* FROM ibthead 
	WHERE trans_num = l_trans_num 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET msgresp = kandoomsg("U",1020,"Confirmation") 
	#1020 Enter Confirmation Details; OK TO Continue.
	FOR idx = 1 TO 520 
		INITIALIZE modu_arr_ibtdetl[idx].* TO NULL 
		INITIALIZE modu_arr_save_ibtdetl[idx].* TO NULL 
	END FOR 
	DISPLAY BY NAME l_trans_num 

	LET modu_delivery_date = today 
	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,modu_delivery_date) 
	RETURNING modu_rec_ibthead.year_num, 
	modu_rec_ibthead.period_num 
	LET l_conf_qty_type = "1" 
	INPUT BY NAME modu_delivery_date, 
	modu_rec_ibthead.year_num, 
	modu_rec_ibthead.period_num, 
	l_conf_qty_type WITHOUT DEFAULTS 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE FIELD modu_delivery_date 
			LET l_save_date = modu_delivery_date 
		AFTER FIELD modu_delivery_date 
			IF modu_delivery_date IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD modu_delivery_date 
			END IF 
			IF modu_delivery_date != l_save_date THEN 
				CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,modu_delivery_date) 
				RETURNING modu_rec_ibthead.year_num, 
				modu_rec_ibthead.period_num 
				DISPLAY BY NAME modu_rec_ibthead.year_num, 
				modu_rec_ibthead.period_num 

			END IF 
		AFTER FIELD year_num 
			IF modu_rec_ibthead.year_num IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD year_num 
			END IF 
		AFTER FIELD period_num 
			IF modu_rec_ibthead.period_num IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD period_num 
			END IF 
			CALL valid_period(glob_rec_kandoouser.cmpy_code, 
			modu_rec_ibthead.year_num, 
			modu_rec_ibthead.period_num, 
			TRAN_TYPE_INVOICE_IN) 
			RETURNING modu_rec_ibthead.year_num, 
			modu_rec_ibthead.period_num, 
			l_invalid_period 
			IF l_invalid_period THEN 
				NEXT FIELD year_num 
			END IF 
		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF modu_delivery_date IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD modu_delivery_date 
				END IF 
				IF modu_rec_ibthead.year_num IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD year_num 
				END IF 
				IF modu_rec_ibthead.period_num IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD period_num 
				END IF 
				IF l_conf_qty_type IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD l_conf_qty_type 
				END IF 
				CALL valid_period(glob_rec_kandoouser.cmpy_code, 
				modu_rec_ibthead.year_num, 
				modu_rec_ibthead.period_num, 
				TRAN_TYPE_INVOICE_IN) 
				RETURNING modu_rec_ibthead.year_num, 
				modu_rec_ibthead.period_num, 
				l_invalid_period 
				IF l_invalid_period THEN 
					NEXT FIELD year_num 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		CLOSE WINDOW i670 
		RETURN 
	END IF 
	LET msgresp = kandoomsg("U",1051,"Confirm") 
	#1051 F3/F4 TO Page Fwd/Bwd; ENTER TO Confirm
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	DECLARE c_ibtdetl CURSOR FOR 
	SELECT * FROM ibtdetl 
	WHERE trans_num = l_trans_num 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	ORDER BY line_num 
	LET idx = 0 
	FOREACH c_ibtdetl INTO l_rec_ibtdetl.* 
		LET idx = idx + 1 
		SELECT * INTO l_rec_product.* FROM product 
		WHERE part_code = l_rec_ibtdetl.part_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET modu_arr_save_ibtdetl[idx].line_num = l_rec_ibtdetl.line_num 
		LET modu_arr_save_ibtdetl[idx].conf_qty = l_rec_ibtdetl.conf_qty 
		LET modu_arr_save_ibtdetl[idx].class_code = l_rec_product.class_code 
		LET modu_arr_save_ibtdetl[idx].part_code = l_rec_product.part_code 
		LET modu_arr_save_ibtdetl[idx].back_qty = l_rec_ibtdetl.back_qty 
		LET modu_arr_save_ibtdetl[idx].rec_qty = l_rec_ibtdetl.rec_qty 
		LET modu_arr_save_ibtdetl[idx].trf_qty = l_rec_ibtdetl.trf_qty 
		LET modu_arr_save_ibtdetl[idx].desc_text = l_rec_product.desc_text 
		LET modu_arr_save_ibtdetl[idx].status_ind = l_rec_ibtdetl.status_ind 
		LET modu_arr_ibtdetl[idx].part_code = l_rec_ibtdetl.part_code 
		LET modu_arr_ibtdetl[idx].line_num = l_rec_ibtdetl.line_num 
		LET modu_arr_ibtdetl[idx].sell_uom_code = l_rec_product.sell_uom_code 
		LET modu_arr_ibtdetl[idx].rec_qty = l_rec_ibtdetl.rec_qty 
		LET modu_arr_ibtdetl[idx].prev_conf = l_rec_ibtdetl.conf_qty 
		IF l_conf_qty_type = "2" THEN 
			LET modu_arr_ibtdetl[idx].conf_qty = 0 
			LET modu_arr_ibtdetl[idx].back_qty = l_rec_ibtdetl.back_qty 
		ELSE 
			IF l_rec_ibtdetl.status_ind = IBTDETL_STATUS_IND_CANCELED_4 THEN 
				LET modu_arr_ibtdetl[idx].conf_qty = 0 
				LET modu_arr_ibtdetl[idx].back_qty = 0 
			ELSE 
				LET modu_arr_ibtdetl[idx].conf_qty = l_rec_ibtdetl.trf_qty 
				- l_rec_ibtdetl.rec_qty 
				- l_rec_ibtdetl.conf_qty 
				LET modu_arr_ibtdetl[idx].back_qty = 0 
			END IF 
		END IF 
		IF idx = 500 THEN 
			LET msgresp = kandoomsg("U",6100,idx) 
			#6100 First idx records selected
			EXIT FOREACH 
		END IF 
	END FOREACH 
	LET msgresp = kandoomsg("U",9113,idx) 
	#9113 idx records selected
	CALL set_count(idx) 
	INPUT ARRAY modu_arr_ibtdetl WITHOUT DEFAULTS FROM sr_ibtdetl.* 

		ON KEY (control-b) 
			CASE WHEN infield(part_code) 
			SELECT * INTO l_rec_product.* FROM product 
			WHERE part_code = modu_arr_ibtdetl[idx].part_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			CALL break_prod(glob_rec_kandoouser.cmpy_code, 
			l_rec_product.part_code, 
			l_rec_product.class_code,1) 
			RETURNING l_orig_part,l_dashes_part_code,l_flex_part_code,l_flex 
			LET l_filter_text = "product.part_code matches '", 
			l_orig_part clipped,"*' AND", 
			" class_code = '", 
			l_rec_product.class_code clipped,"'" 
			LET l_winds_text = show_part(glob_rec_kandoouser.cmpy_code,l_filter_text) 
			IF l_winds_text IS NOT NULL THEN 
				SELECT * INTO l_rec_product.* FROM product 
				WHERE part_code = l_winds_text 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				CALL break_prod(glob_rec_kandoouser.cmpy_code, 
				l_rec_product.part_code, 
				l_rec_product.class_code,1) 
				RETURNING l_orig_part,l_dashes_part_code,l_flex_part_code,l_flex 
				IF l_flex_part_code IS NOT NULL THEN 
					LET modu_arr_ibtdetl[idx].part_code = l_orig_part clipped, 
					l_dashes_part_code clipped, 
					l_flex_part_code 
				ELSE 
					LET modu_arr_ibtdetl[idx].part_code = l_orig_part 
				END IF 
				SELECT * INTO l_rec_product.* FROM product 
				WHERE part_code = modu_arr_ibtdetl[idx].part_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET modu_arr_save_ibtdetl[idx].desc_text = l_rec_product.desc_text 
				DISPLAY BY NAME modu_arr_save_ibtdetl[idx].desc_text 

			END IF 
			NEXT FIELD part_code 
			END CASE 
		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			NEXT FIELD scroll_flag 
		AFTER ROW 
			DISPLAY modu_arr_ibtdetl[idx].* TO sr_ibtdetl[scrn].* 

		BEFORE FIELD scroll_flag 
			LET l_rec_ibtrecord.line_num = modu_arr_ibtdetl[idx].line_num 
			LET l_rec_ibtrecord.part_code = modu_arr_ibtdetl[idx].part_code 
			LET l_rec_ibtrecord.sell_uom_code = modu_arr_ibtdetl[idx].sell_uom_code 
			LET l_rec_ibtrecord.rec_qty = modu_arr_ibtdetl[idx].rec_qty 
			LET l_rec_ibtrecord.conf_qty = modu_arr_ibtdetl[idx].conf_qty 
			LET l_rec_ibtrecord.back_qty = modu_arr_ibtdetl[idx].back_qty 
			LET l_rec_ibtrecord.desc_text = modu_arr_save_ibtdetl[idx].desc_text 
			DISPLAY modu_arr_ibtdetl[idx].* TO sr_ibtdetl[scrn].* 

			DISPLAY BY NAME modu_arr_save_ibtdetl[idx].desc_text, 
			modu_arr_save_ibtdetl[idx].trf_qty 

		AFTER FIELD scroll_flag 
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF arr_curr() >= arr_count() THEN 
					LET msgresp = kandoomsg("U",9001,"") 
					#9001 There no more rows...
					NEXT FIELD scroll_flag 
				END IF 
				IF modu_arr_ibtdetl[idx+1].line_num IS NULL THEN 
					LET msgresp = kandoomsg("U",9001,"") 
					#9001 There no more rows...
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
		BEFORE FIELD line_num 
			IF modu_arr_save_ibtdetl[idx].status_ind = "4" THEN 
				LET msgresp = kandoomsg("I",9527,"") 
				#9527 Transfer line has been cancelled.
				NEXT FIELD scroll_flag 
			END IF 
			IF modu_arr_save_ibtdetl[idx].back_qty = 0 THEN 
				LET msgresp = kandoomsg("I",9005,"") 
				#9526 This line has been fully receipted AND/OR confirmed.
				NEXT FIELD scroll_flag 
			END IF 
			IF modu_arr_ibtdetl[idx].conf_qty = 0 THEN 
				LET modu_arr_ibtdetl[idx].conf_qty = modu_arr_ibtdetl[idx].back_qty 
			END IF 
			DISPLAY modu_arr_ibtdetl[idx].* TO sr_ibtdetl[scrn].* 

			LET l_save2_part_code = modu_arr_ibtdetl[idx].part_code 
			NEXT FIELD part_code 
		BEFORE FIELD part_code 
			SELECT * INTO l_rec_class.* FROM class 
			WHERE class_code = modu_arr_save_ibtdetl[idx].class_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF l_rec_class.stock_level_ind IS NULL 
			OR l_rec_class.stock_level_ind <= 1 THEN 
				NEXT FIELD conf_qty 
			END IF 
			IF modu_arr_save_ibtdetl[idx].back_qty != modu_arr_save_ibtdetl[idx].trf_qty THEN 
				NEXT FIELD conf_qty 
			END IF 
			LET l_save_part_code = l_save2_part_code 
		AFTER FIELD part_code 
			CASE 
				WHEN fgl_lastkey() = fgl_keyval("accept") 
					OR fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("down") 
					IF modu_arr_ibtdetl[idx].part_code IS NULL THEN 
						LET msgresp = kandoomsg("U",9102,"") 
						#9102 Value Must Be Entered
						NEXT FIELD part_code 
					END IF 
					SELECT * INTO l_rec_product.* FROM product 
					WHERE part_code = modu_arr_ibtdetl[idx].part_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF status = notfound THEN 
						LET msgresp = kandoomsg("U",9105,"") 
						#9105 RECORD Not Found; Try Window
						NEXT FIELD part_code 
					END IF 
					SELECT * INTO l_rec_prodstatus.* FROM prodstatus 
					WHERE part_code = modu_arr_ibtdetl[idx].part_code 
					AND ware_code = modu_rec_ibthead.to_ware_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF status = notfound THEN 
						LET msgresp = kandoomsg("W",9156,"") 
						#9156 Product NOT AT this location - try window
						NEXT FIELD part_code 
					END IF 
					SELECT * INTO l_rec_prodstatus.* FROM prodstatus 
					WHERE part_code = modu_arr_ibtdetl[idx].part_code 
					AND ware_code = modu_rec_ibthead.from_ware_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF status = notfound THEN 
						LET msgresp = kandoomsg("W",9156,"") 
						#9156 Product NOT AT this location - try window
						NEXT FIELD part_code 
					END IF 
					FOR i = 1 TO arr_count() 
						IF modu_arr_ibtdetl[i].part_code = modu_arr_ibtdetl[idx].part_code 
						AND i <> idx THEN 
							LET msgresp = kandoomsg("I",9113,"") 
							#9113 Product has already been used
							NEXT FIELD part_code 
						END IF 
					END FOR 
					IF modu_arr_ibtdetl[idx].part_code != l_save_part_code THEN 
						SELECT * INTO l_rec_product2.* FROM product 
						WHERE part_code = l_save_part_code 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code 
						CALL break_prod(glob_rec_kandoouser.cmpy_code, 
						l_rec_product.part_code, 
						l_rec_product.class_code,1) 
						RETURNING l_orig_part,l_dashes_part_code,l_flex_part_code,l_flex 
						CALL break_prod(glob_rec_kandoouser.cmpy_code, 
						modu_arr_save_ibtdetl[idx].part_code, 
						l_rec_product2.class_code,1) 
						RETURNING l_orig_part2,l_dashes_part_code,l_flex_part_code,l_flex 
						IF l_orig_part != l_orig_part2 THEN 
							LET msgresp = kandoomsg("I",9006,"") 
							#9006 Part must have same parent as original.
							LET modu_arr_ibtdetl[idx].part_code = l_save_part_code 
							NEXT FIELD part_code 
						END IF 
						IF NOT validate_despatch_segment(glob_rec_kandoouser.cmpy_code, modu_arr_ibtdetl[idx].part_code, true) THEN 
							LET msgresp = kandoomsg("W",9503,"") 
							#9503 "Must enter up TO Despatch segment"
							NEXT FIELD part_code 
						END IF 
						LET modu_arr_ibtdetl[idx].back_qty = modu_arr_ibtdetl[idx].back_qty 
						/ l_rec_product2.stk_sel_con_qty 
						LET modu_arr_ibtdetl[idx].back_qty = modu_arr_ibtdetl[idx].back_qty 
						* l_rec_product.stk_sel_con_qty 
						LET modu_arr_save_ibtdetl[idx].trf_qty = modu_arr_save_ibtdetl[idx].trf_qty 
						/ l_rec_product2.stk_sel_con_qty 
						LET modu_arr_save_ibtdetl[idx].trf_qty = modu_arr_save_ibtdetl[idx].trf_qty 
						* l_rec_product.stk_sel_con_qty 
						LET modu_arr_save_ibtdetl[idx].back_qty = modu_arr_save_ibtdetl[idx].back_qty 
						/ l_rec_product2.stk_sel_con_qty 
						LET modu_arr_save_ibtdetl[idx].back_qty = modu_arr_save_ibtdetl[idx].back_qty 
						* l_rec_product.stk_sel_con_qty 
						LET modu_arr_ibtdetl[idx].conf_qty = modu_arr_ibtdetl[idx].conf_qty 
						/ l_rec_product2.stk_sel_con_qty 
						LET modu_arr_ibtdetl[idx].conf_qty = modu_arr_ibtdetl[idx].conf_qty 
						* l_rec_product.stk_sel_con_qty 
						LET modu_arr_save_ibtdetl[idx].desc_text = l_rec_product.desc_text 
						LET modu_arr_ibtdetl[idx].sell_uom_code = l_rec_product.sell_uom_code 
						DISPLAY modu_arr_ibtdetl[idx].conf_qty, 
						modu_arr_ibtdetl[idx].back_qty, 
						l_rec_product.sell_uom_code, 
						l_rec_product.desc_text, 
						modu_arr_save_ibtdetl[idx].trf_qty 
						TO sr_ibtdetl[scrn].conf_qty, 
						sr_ibtdetl[scrn].back_qty, 
						sr_ibtdetl[scrn].sell_uom_code, 
						desc_text, 
						trf_qty 

						IF (l_rec_prodstatus.onhand_qty - l_rec_prodstatus.back_qty 
						- l_rec_prodstatus.reserved_qty) < modu_arr_save_ibtdetl[idx].trf_qty THEN 
							LET msgresp = kandoomsg("I",9112,"") 
							#Insufficient stock available
						END IF 
					END IF 
					IF NOT validate_despatch_segment(glob_rec_kandoouser.cmpy_code, modu_arr_ibtdetl[idx].part_code, true) THEN 
						LET msgresp = kandoomsg("W",9503,"") 
						#9503 "Must enter up TO Despatch segment"
						NEXT FIELD part_code 
					END IF 
					LET l_save2_part_code = modu_arr_ibtdetl[idx].part_code 
					NEXT FIELD conf_qty 
				WHEN fgl_lastkey() = fgl_keyval("up") 
					OR fgl_lastkey() = fgl_keyval("left") 
					NEXT FIELD part_code 
				OTHERWISE 
					NEXT FIELD part_code 
			END CASE 

		BEFORE FIELD conf_qty 
			SELECT unique 1 FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = modu_arr_ibtdetl[idx].part_code 
			AND serial_flag = 'Y' 
			IF status <> notfound THEN 
				LET l_serial_cnt = serial_input(modu_arr_ibtdetl[idx].part_code, 
				modu_rec_ibthead.from_ware_code, 
				modu_arr_ibtdetl[idx].conf_qty) 
				IF l_serial_cnt < 0 THEN 
					IF l_serial_cnt = -1 THEN 
						NEXT FIELD part_code 
					ELSE 
						CALL errorlog("I58 - Fatal error in serial_input ") 
						EXIT program 
					END IF 
				ELSE 
					LET modu_arr_ibtdetl[idx].conf_qty = l_serial_cnt 
					IF modu_arr_ibtdetl[idx].conf_qty < 0 THEN 
						LET msgresp = kandoomsg("W",9188,"") 
						#9188 Quantity must be greater than zero
						NEXT FIELD scroll_flag 
					END IF 
					LET modu_arr_ibtdetl[idx].back_qty = modu_arr_save_ibtdetl[idx].trf_qty 
					- modu_arr_ibtdetl[idx].rec_qty 
					- modu_arr_save_ibtdetl[idx].conf_qty 
					- modu_arr_ibtdetl[idx].conf_qty 
					DISPLAY modu_arr_ibtdetl[idx].conf_qty, 
					modu_arr_ibtdetl[idx].back_qty 
					TO sr_ibtdetl[scrn].conf_qty, 
					sr_ibtdetl[scrn].back_qty 

					NEXT FIELD scroll_flag 
				END IF 
			END IF 
		AFTER FIELD conf_qty 
			CASE 
				WHEN fgl_lastkey() = fgl_keyval("accept") 
					OR fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("down") 
					IF modu_arr_ibtdetl[idx].conf_qty IS NULL THEN 
						LET msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered
						NEXT FIELD conf_qty 
					END IF 
					IF modu_arr_ibtdetl[idx].conf_qty < 0 THEN 
						LET msgresp = kandoomsg("W",9188,"") 
						#9188 Quantity must be greater than zero
						NEXT FIELD conf_qty 
					END IF 
					LET l_conf_qty = modu_arr_save_ibtdetl[idx].trf_qty 
					- modu_arr_ibtdetl[idx].rec_qty 
					- modu_arr_save_ibtdetl[idx].conf_qty 
					IF modu_arr_ibtdetl[idx].conf_qty > l_conf_qty THEN 
						LET msgresp = kandoomsg("U",9046,l_conf_qty) 
						#9046 Value must be less than OR equal TO 100
						NEXT FIELD conf_qty 
					ELSE 
						LET modu_arr_ibtdetl[idx].back_qty = modu_arr_save_ibtdetl[idx].trf_qty 
						- modu_arr_ibtdetl[idx].rec_qty 
						- modu_arr_save_ibtdetl[idx].conf_qty 
						- modu_arr_ibtdetl[idx].conf_qty 
						DISPLAY modu_arr_ibtdetl[idx].back_qty 
						TO sr_ibtdetl[scrn].back_qty 

					END IF 
					NEXT FIELD scroll_flag 
				WHEN fgl_lastkey() = fgl_keyval("up") 
					OR fgl_lastkey() = fgl_keyval("left") 
					NEXT FIELD part_code 
				OTHERWISE 
					NEXT FIELD conf_qty 
			END CASE 
		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				IF NOT (infield(scroll_flag)) THEN 
					LET modu_arr_ibtdetl[idx].line_num = l_rec_ibtrecord.line_num 
					LET modu_arr_ibtdetl[idx].part_code = l_rec_ibtrecord.part_code 
					LET modu_arr_ibtdetl[idx].sell_uom_code = l_rec_ibtrecord.sell_uom_code 
					LET modu_arr_ibtdetl[idx].rec_qty = l_rec_ibtrecord.rec_qty 
					LET modu_arr_ibtdetl[idx].conf_qty = l_rec_ibtrecord.conf_qty 
					LET modu_arr_ibtdetl[idx].back_qty = l_rec_ibtrecord.back_qty 
					LET modu_arr_save_ibtdetl[idx].desc_text = l_rec_ibtrecord.desc_text 
					LET int_flag = false 
					LET quit_flag = false 
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
			LET l_arr_cnt = arr_count() 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
		CLOSE WINDOW i670 
		RETURN 
	END IF 
	--   OPEN WINDOW w1 AT 10,14 with 5 rows,60 columns  -- albo  KD-758
	--      ATTRIBUTE(border, MESSAGE line 2, menu line 4)
	#ATTRIBUTE(border, menu line 4)
	#LET msgresp = kandoomsg("W",1054,"")
	MESSAGE " ENTER TO SELECT option." attribute (yellow) 
	MENU " Confirmation" 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE MENU 
			HIDE option "Print Manager" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","I58","menu-Confirmation-1") -- albo kd-505 

		COMMAND "Confirm" " Confirm the stock transfer" 
			IF write_transfer(l_trans_num) THEN 
				--            CLEAR window w1  -- albo  KD-758
				#LET msgresp = kandoomsg("I",1046,modu_rec_ibthead.trans_num)
				LET l_msg = " Stock Transfer ", 
				modu_rec_ibthead.trans_num USING "<<<<<<<<", 
				" Successfully Confirmed." 
				MESSAGE l_msg attribute(yellow) 
				LET modu_trans_type = "C" 
				HIDE option "Confirm" 
				HIDE option "Receipt" 
				SHOW option "Print Manager" 
			ELSE 
				LET msgresp = kandoomsg("W",7017,"") 
				#7017 Failed TO confirm transfer
			END IF 

		ON ACTION "Print Manager" 
			#COMMAND KEY ("P",f11) "Print" "  Print the stock transfer confirmation"
			IF modu_trans_type = "C" THEN 
				LET l_rms_string = "Stock Transfer ", 
				modu_rec_ibthead.trans_num USING "<<<<<<<<", 
				" Confirmation" 
				LET l_output = 
				init_report(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,l_rms_string) 
			ELSE 
				LET l_rms_string = "Stock Transfer ", 
				modu_rec_ibthead.trans_num USING "<<<<<<<<", 
				" Receipt" 
				LET l_output = 
				init_report(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,l_rms_string) 
			END IF 
			START REPORT confirmation_list TO l_output 
			FOR i = 1 TO l_arr_cnt 
				IF modu_arr_ibtdetl[i].line_num IS NOT NULL THEN 
					LET ls_ibtdetl.line_num = modu_arr_ibtdetl[i].line_num 
					LET ls_ibtdetl.part_code = modu_arr_ibtdetl[i].part_code 
					LET ls_ibtdetl.trf_qty = modu_arr_save_ibtdetl[i].trf_qty 
					LET ls_ibtdetl.conf_qty = modu_arr_ibtdetl[i].conf_qty 
					OUTPUT TO REPORT confirmation_list(ls_ibtdetl.*) 
				END IF 
			END FOR 
			CALL upd_reports(l_output,rpt_pageno,"80","66") 
			FINISH REPORT confirmation_list 
			CALL run_prog("URS","","","","") -- ON ACTION "Print Manager" 

		COMMAND "Receipt" " Confirm AND receipt the stock transfer" 
			IF automatic_receipt(l_trans_num) THEN 
				--            CLEAR window w1  -- albo  KD-758
				LET l_msg = " Stock Transfer ", 
				modu_rec_ibthead.trans_num USING "<<<<<<<<", 
				" Successfully Receipted." 
				MESSAGE l_msg attribute(yellow) 
				#LET msgresp = kandoomsg("I",1047,modu_rec_ibthead.trans_num)
				LET modu_trans_type = "R" 
				HIDE option "Confirm" 
				HIDE option "Receipt" 
				SHOW option "Print Manager" 
			ELSE 
				LET msgresp = kandoomsg("I",7053,"") 
				#7053 Receipt failed.
			END IF 

		COMMAND KEY(interrupt, "E")"Exit" " Exit TO stock transfer list" 
			EXIT MENU 

		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
	END MENU 
	--   CLOSE WINDOW w1  -- albo  KD-758
	CLOSE WINDOW i670 
END FUNCTION   # confirm_transfer


REPORT confirmation_list(ls_ibtdetl) 
	DEFINE 

	ls_ibtdetl RECORD 
		line_num LIKE ibtdetl.line_num, 
		part_code LIKE product.part_code, 
		trf_qty LIKE ibtdetl.trf_qty, 
		conf_qty LIKE ibtdetl.conf_qty 
	END RECORD, 
	l_rec_printcodes RECORD LIKE printcodes.*, 
	l_rec_ibtdetl RECORD LIKE ibtdetl.*, 
	l_rec_prodledg RECORD LIKE prodledg.*, 
	l_rec_src_prodstatus RECORD LIKE prodstatus.*, 
	l_rec_src_warehouse, l_rec_dest_warehouse RECORD LIKE warehouse.*,
	l_desc_text LIKE product.desc_text, 
	l_uom_code LIKE product.sell_uom_code, 
	l_stk_sel_con_qty LIKE product.stk_sel_con_qty, 
	l_trans_text CHAR(9), 
	l_ware1_ad1, 
	l_ware2_ad1, 
	l_ware1_ad2, 
	l_ware2_ad2, 
	l_ware1_ad3, 
	l_ware2_ad3 CHAR(32), 
	l_grandtotal DECIMAL(16,2), 
	l_endpage SMALLINT 

	OUTPUT 
	PAGE length 66 
	top margin 11 
	bottom margin 14 
	left margin 0 
	ORDER BY ls_ibtdetl.line_num 
	FORMAT 
		FIRST PAGE HEADER 
			LET l_endpage = false 
			LET l_grandtotal = 0 
			# Printer defaulted TO that used in Requisitions
			SELECT printcodes.* INTO l_rec_printcodes.* FROM reqparms, printcodes 
			WHERE reqparms.key_code = '1' 
			AND reqparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND printcodes.print_code = reqparms.po_print_text 
			IF status = notfound THEN 
				INITIALIZE l_rec_printcodes.* TO NULL 
			END IF 
			IF modu_trans_type = "R" THEN 
				LET l_trans_text = "Receipted" 
			ELSE 
				LET l_trans_text = "Confirmed" 
			END IF 
			LET rpt_pageno = pageno 
			SELECT * INTO l_rec_src_warehouse.* FROM warehouse 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ware_code = modu_rec_ibthead.from_ware_code 
			IF sqlca.sqlcode = notfound THEN 
				INITIALIZE l_rec_src_warehouse.* TO NULL 
			END IF 
			SELECT * INTO l_rec_dest_warehouse.* FROM warehouse 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ware_code = modu_rec_ibthead.to_ware_code 
			IF sqlca.sqlcode = notfound THEN 
				INITIALIZE l_rec_dest_warehouse.* TO NULL 
			END IF 
			PRINT ascii(l_rec_printcodes.normal_1), 
			ascii(l_rec_printcodes.normal_2), 
			ascii(l_rec_printcodes.normal_3), 
			ascii(l_rec_printcodes.normal_4), 
			ascii(l_rec_printcodes.normal_5), 
			ascii(l_rec_printcodes.normal_6), 
			ascii(l_rec_printcodes.normal_7), 
			ascii(l_rec_printcodes.normal_8), 
			ascii(l_rec_printcodes.normal_9), 
			ascii(l_rec_printcodes.normal_10) 
			PRINT COLUMN 49,'stock transfer'; 
			PRINT ascii(l_rec_printcodes.compress_1), 
			ascii(l_rec_printcodes.compress_2), 
			ascii(l_rec_printcodes.compress_3), 
			ascii(l_rec_printcodes.compress_4), 
			ascii(l_rec_printcodes.compress_5), 
			ascii(l_rec_printcodes.compress_6), 
			ascii(l_rec_printcodes.compress_7), 
			ascii(l_rec_printcodes.compress_8), 
			ascii(l_rec_printcodes.compress_9), 
			ascii(l_rec_printcodes.compress_10) 
			SKIP 2 LINES 
			LET l_ware1_ad1 = l_rec_src_warehouse.addr1_text clipped 
			LET l_ware1_ad2 = l_rec_src_warehouse.addr2_text clipped 
			LET l_ware1_ad3 = l_rec_src_warehouse.city_text 
			IF l_ware1_ad3 IS NULL THEN 
				LET l_ware1_ad3 = l_rec_src_warehouse.state_code 
			ELSE 
				LET l_ware1_ad3 = l_ware1_ad3 clipped, " ", 
				l_rec_src_warehouse.state_code clipped 
			END IF 
			IF l_ware1_ad3 IS NULL THEN 
				LET l_ware1_ad3 = l_rec_src_warehouse.post_code 
			ELSE 
				LET l_ware1_ad3 = l_ware1_ad3 clipped, " ", 
				l_rec_src_warehouse.post_code clipped, " " 
			END IF 
			IF l_ware1_ad2 IS NULL THEN 
				LET l_ware1_ad2 = l_ware1_ad3 
				INITIALIZE l_ware1_ad3 TO NULL 
			END IF 
			IF l_ware1_ad1 IS NULL THEN 
				LET l_ware1_ad1 = l_ware1_ad2 
				INITIALIZE l_ware1_ad2 TO NULL 
			END IF 
			LET l_ware2_ad1 = l_rec_dest_warehouse.addr1_text clipped 
			LET l_ware2_ad2 = l_rec_dest_warehouse.addr2_text clipped 
			LET l_ware2_ad3 = l_rec_dest_warehouse.city_text 
			IF l_ware2_ad3 IS NULL THEN 
				LET l_ware2_ad3 = l_rec_dest_warehouse.state_code 
			ELSE 
				LET l_ware2_ad3 = l_ware2_ad3 clipped, " ", 
				l_rec_dest_warehouse.state_code clipped 
			END IF 
			IF l_ware2_ad3 IS NULL THEN 
				LET l_ware2_ad3 = l_rec_dest_warehouse.post_code 
			ELSE 
				LET l_ware2_ad3 = l_ware2_ad3 clipped, " ", 
				l_rec_dest_warehouse.post_code clipped, " " 
			END IF 
			IF l_ware2_ad2 IS NULL THEN 
				LET l_ware2_ad2 = l_ware2_ad3 
				INITIALIZE l_ware2_ad3 TO NULL 
			END IF 
			IF l_ware2_ad1 IS NULL THEN 
				LET l_ware2_ad1 = l_ware2_ad2 
				INITIALIZE l_ware2_ad2 TO NULL 
			END IF 
			PRINT COLUMN 16, l_rec_src_warehouse.desc_text clipped, 
			COLUMN 54, l_rec_dest_warehouse.desc_text clipped, 
			COLUMN 86, 'Number', 
			COLUMN 96, modu_rec_ibthead.trans_num USING "<<<<<<<<" 
			PRINT COLUMN 16, l_ware1_ad1 clipped, 
			COLUMN 54, l_ware2_ad1 clipped, 
			COLUMN 86, 'Date', 
			COLUMN 96, modu_rec_ibthead.trans_date USING "dd-mm-yy" 
			PRINT COLUMN 16, l_ware1_ad2 clipped, 
			COLUMN 54, l_ware2_ad2 clipped 
			PRINT COLUMN 16, l_ware1_ad3 clipped, 
			COLUMN 54, l_ware2_ad3 clipped, 
			COLUMN 86, 'Ref:', 
			COLUMN 90, modu_rec_ibthead.desc_text[1,16] clipped 
			SKIP 1 LINES 
			PRINT COLUMN 6, 'Code', 
			COLUMN 22, 'Name', 
			COLUMN 53, 'Transferred', 
			COLUMN 67, l_trans_text 
			SKIP 1 LINES 
		PAGE HEADER 
			PRINT ascii(l_rec_printcodes.normal_1), 
			ascii(l_rec_printcodes.normal_2), 
			ascii(l_rec_printcodes.normal_3), 
			ascii(l_rec_printcodes.normal_4), 
			ascii(l_rec_printcodes.normal_5), 
			ascii(l_rec_printcodes.normal_6), 
			ascii(l_rec_printcodes.normal_7), 
			ascii(l_rec_printcodes.normal_8), 
			ascii(l_rec_printcodes.normal_9), 
			ascii(l_rec_printcodes.normal_10) 
			PRINT COLUMN 49,'stock transfer'; 
			PRINT ascii(l_rec_printcodes.compress_1), 
			ascii(l_rec_printcodes.compress_2), 
			ascii(l_rec_printcodes.compress_3), 
			ascii(l_rec_printcodes.compress_4), 
			ascii(l_rec_printcodes.compress_5), 
			ascii(l_rec_printcodes.compress_6), 
			ascii(l_rec_printcodes.compress_7), 
			ascii(l_rec_printcodes.compress_8), 
			ascii(l_rec_printcodes.compress_9), 
			ascii(l_rec_printcodes.compress_10) 
			SKIP 2 LINES 
			PRINT COLUMN 16, l_rec_src_warehouse.desc_text clipped, 
			COLUMN 54, l_rec_dest_warehouse.desc_text clipped, 
			COLUMN 86, 'Number', 
			COLUMN 96, modu_rec_ibthead.trans_num USING "<<<<<<<<" 
			PRINT COLUMN 16, l_ware1_ad1 clipped, 
			COLUMN 54, l_ware2_ad1 clipped, 
			COLUMN 86, 'Date', 
			COLUMN 96, modu_rec_ibthead.trans_date USING "dd-mm-yy" 
			PRINT COLUMN 16, l_ware1_ad2 clipped, 
			COLUMN 54, l_ware2_ad2 clipped 
			PRINT COLUMN 16, l_ware1_ad3 clipped, 
			COLUMN 54, l_ware2_ad3 clipped, 
			COLUMN 86, 'Ref:', 
			COLUMN 90, modu_rec_ibthead.desc_text[1,16] clipped 
			SKIP 1 LINES 
			PRINT COLUMN 6, 'Code', 
			COLUMN 22, 'Name', 
			COLUMN 53, 'Transferred', 
			COLUMN 67, l_trans_text 
			SKIP 1 LINES 
		ON EVERY ROW 
			SELECT * INTO l_rec_src_prodstatus.* FROM prodstatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ware_code = modu_rec_ibthead.from_ware_code 
			AND part_code = ls_ibtdetl.part_code 
			SELECT desc_text, 
			sell_uom_code, 
			stk_sel_con_qty 
			INTO l_desc_text, 
			l_uom_code, 
			l_stk_sel_con_qty 
			FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = ls_ibtdetl.part_code 
			IF sqlca.sqlcode = notfound THEN 
				LET l_desc_text = NULL 
				LET l_uom_code = NULL 
			END IF 
			PRINT COLUMN 6, ls_ibtdetl.part_code, 
			COLUMN 22, l_desc_text, 
			COLUMN 53, ls_ibtdetl.trf_qty USING "#######&.&&", 
			COLUMN 65, ls_ibtdetl.conf_qty USING "#######&.&&", 
			COLUMN 77, l_uom_code 
			PAGE TRAILER 
				SKIP 9 LINES 
				PRINT COLUMN 35, 'PRINTED', ' ', 
				today USING "dd-mm-yy", ' ', 
				time; 
				PRINT ascii(l_rec_printcodes.normal_1), 
				ascii(l_rec_printcodes.normal_2), 
				ascii(l_rec_printcodes.normal_3), 
				ascii(l_rec_printcodes.normal_4), 
				ascii(l_rec_printcodes.normal_5), 
				ascii(l_rec_printcodes.normal_6), 
				ascii(l_rec_printcodes.normal_7), 
				ascii(l_rec_printcodes.normal_8), 
				ascii(l_rec_printcodes.normal_9), 
				ascii(l_rec_printcodes.normal_10) 
END REPORT 		# confirmation_list


FUNCTION write_transfer(l_trans_num) 
	DEFINE 
	l_rec_inparms RECORD LIKE inparms.*, 
	l_rec_category RECORD LIKE category.*, 
	ls_prodledg RECORD LIKE prodledg.*, 
	l_rec_prodstatus RECORD LIKE prodstatus.*, 
	l_rec_ibtdetl RECORD LIKE ibtdetl.*, 
	l_rec_ibtload RECORD LIKE ibtload.*, 
	l_rec_product RECORD LIKE product.*,
	l_rec_src_prodstatus RECORD LIKE prodstatus.*, 
	l_rec_dst_prodstatus RECORD LIKE prodstatus.*, 
	l_rec_to_prodstatus RECORD LIKE prodstatus.*, 
	l_rec_par_prodstatus RECORD LIKE prodstatus.*, 
	l_rec_serialinfo RECORD LIKE serialinfo.*,
	l_ibt_mask_code LIKE warehouse.acct_mask_code, 
 	l_period_num LIKE ibthead.period_num, 
	l_year_num LIKE ibthead.year_num, 
 	l_rec_parent_part_code LIKE product.part_code, 
	l_rec_flex_part_code LIKE product.part_code, 
	l_dashes LIKE product.part_code,		
	l_trans_num LIKE ibthead.trans_num, 
	l_rev_num, idx, cnt, i, l_ibtcnt, l_records_cnt SMALLINT, 
	err_message CHAR(40), 
	l_flex SMALLINT 

	LET msgresp = kandoomsg("U",1005,"") 
	#1005 Updating Database
	SELECT unique * INTO l_rec_inparms.* FROM inparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	GOTO bypass 
	LABEL recovery: 
	IF error_recover(err_message, status) = "N" THEN 
		RETURN false 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		LET l_period_num = modu_rec_ibthead.period_num 
		LET l_year_num = modu_rec_ibthead.year_num 
		DECLARE c1_ibthead CURSOR FOR 
		SELECT * FROM ibthead 
		WHERE trans_num = l_trans_num 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		FOR UPDATE 
		OPEN c1_ibthead 
		FETCH c1_ibthead INTO modu_rec_ibthead.* 
		LET modu_rec_ibthead.period_num = l_period_num 
		LET modu_rec_ibthead.year_num = l_year_num 
		FOR cnt = 1 TO 500 
			IF modu_arr_ibtdetl[cnt].line_num IS NULL 
			OR modu_arr_ibtdetl[cnt].line_num = 0 THEN 
				LET cnt = cnt - 1 
				EXIT FOR 
			END IF 
		END FOR 
		FOR idx = 1 TO cnt 
			# IF a new part code flexible structure has been selected THEN alter
			# the prodstatus of both the old AND new part codes TO reflect this.
			IF modu_arr_ibtdetl[idx].part_code <> modu_arr_save_ibtdetl[idx].part_code THEN 
				SELECT * INTO l_rec_ibtdetl.* FROM ibtdetl 
				WHERE trans_num = l_trans_num 
				AND line_num = modu_arr_save_ibtdetl[idx].line_num 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status != notfound THEN 
					UPDATE prodstatus 
					SET back_qty = back_qty - l_rec_ibtdetl.trf_qty 
					WHERE part_code = l_rec_ibtdetl.part_code 
					AND ware_code = modu_rec_ibthead.from_ware_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					UPDATE prodstatus 
					SET back_qty = back_qty + modu_arr_save_ibtdetl[idx].back_qty 
					WHERE part_code = modu_arr_ibtdetl[idx].part_code 
					AND ware_code = modu_rec_ibthead.from_ware_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					UPDATE ibtdetl 
					SET part_code = modu_arr_ibtdetl[idx].part_code, 
					trf_qty = modu_arr_save_ibtdetl[idx].trf_qty 
					WHERE trans_num = l_trans_num 
					AND line_num = modu_arr_ibtdetl[idx].line_num 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				END IF 
			END IF 
		END FOR 
		FOR i = 1 TO cnt 
			IF modu_arr_ibtdetl[i].conf_qty = 0 THEN 
				CONTINUE FOR 
			END IF 
			SELECT * INTO l_rec_product.* FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = modu_arr_ibtdetl[i].part_code 
			SELECT * INTO l_rec_category.* FROM category 
			WHERE cat_code = l_rec_product.cat_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			### Source Warehouse
			DECLARE c_prodstatus CURSOR FOR 
			SELECT * FROM prodstatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ware_code = modu_rec_ibthead.from_ware_code 
			AND part_code = modu_arr_ibtdetl[i].part_code 
			FOR UPDATE 
			OPEN c_prodstatus 
			FETCH c_prodstatus INTO l_rec_src_prodstatus.* 
			LET l_rec_src_prodstatus.seq_num = l_rec_src_prodstatus.seq_num + 1 
			IF l_rec_src_prodstatus.stocked_flag = "Y" THEN 
				LET l_rec_src_prodstatus.onhand_qty = l_rec_src_prodstatus.onhand_qty 
				- modu_arr_ibtdetl[i].conf_qty 
				LET l_rec_src_prodstatus.back_qty = l_rec_src_prodstatus.back_qty 
				- modu_arr_ibtdetl[i].conf_qty 
			ELSE 
				LET l_rec_src_prodstatus.onhand_qty = 0 
			END IF 
			INITIALIZE l_rec_ibtload.* TO NULL 
			SELECT * INTO l_rec_ibtload.* FROM ibtload 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND trans_num = l_trans_num 
			AND line_num = modu_arr_ibtdetl[i].line_num 
			IF status = notfound THEN 
				INITIALIZE l_rec_ibtload.* TO NULL 
				LET l_rec_ibtload.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_rec_ibtload.trans_num = modu_rec_ibthead.trans_num 
				LET l_rec_ibtload.line_num = modu_arr_ibtdetl[i].line_num 
				LET l_rec_ibtload.pick_num = 0 
				LET l_rec_ibtload.unit_cost_amt = l_rec_src_prodstatus.wgted_cost_amt 
				LET l_rec_ibtload.unit_cart_amt = 0 
				LET l_rec_ibtload.load_qty = 0 
				LET l_rec_ibtload.rec_qty = 0 
				LET err_message = "INSERT ibtload" 
				INSERT INTO ibtload VALUES (l_rec_ibtload.*) 
			END IF 
			LET err_message = "I58 - Product Ledger Entry" 
			INITIALIZE ls_prodledg.* TO NULL 
			LET ls_prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET ls_prodledg.part_code = l_rec_src_prodstatus.part_code 
			LET ls_prodledg.ware_code = l_rec_src_prodstatus.ware_code 
			LET ls_prodledg.tran_date = modu_delivery_date 
			LET ls_prodledg.seq_num = l_rec_src_prodstatus.seq_num 
			LET ls_prodledg.trantype_ind = "T" 
			LET ls_prodledg.year_num = modu_rec_ibthead.year_num 
			LET ls_prodledg.period_num = modu_rec_ibthead.period_num 
			LET ls_prodledg.source_text = l_rec_inparms.ibt_ware_code 
			LET ls_prodledg.source_num = l_trans_num 
			LET ls_prodledg.tran_qty = 0 - modu_arr_ibtdetl[i].conf_qty 
			LET ls_prodledg.bal_amt = l_rec_src_prodstatus.onhand_qty 
			LET ls_prodledg.cost_amt = l_rec_ibtload.unit_cost_amt 
			LET ls_prodledg.sales_amt = 0 
			IF l_rec_inparms.hist_flag = "Y" THEN 
				LET ls_prodledg.hist_flag = "N" 
			ELSE 
				LET ls_prodledg.hist_flag = "Y" 
			END IF 
			LET ls_prodledg.post_flag = "N" 
			LET ls_prodledg.entry_code = glob_rec_kandoouser.sign_on_code 
			LET ls_prodledg.entry_date = today 
			# WHERE the user has only confirmed the despatch of the goods, the
			# destination warehouse IS the transfer warehouse FROM IN parameters.
			# Both prodledg entries will contain the transfer warehouse
			# adjustment account, causing the interim entries TO CLEAR
			# through the GL.  The net result IS a credit FROM the source warehouse
			# stock account AND a debit TO the transfer warehouse stock account.
			# Refer TO ISP FOR posting rules.
			LET ls_prodledg.acct_code = l_rec_category.adj_acct_code 
			SELECT acct_mask_code INTO l_ibt_mask_code FROM warehouse 
			WHERE ware_code = l_rec_inparms.ibt_ware_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			CALL build_mask(glob_rec_kandoouser.cmpy_code, 
			l_ibt_mask_code, 
			ls_prodledg.acct_code) 
			RETURNING ls_prodledg.acct_code 
			LET err_message = "I58 - 1st prodledg INSERT" 
			INSERT INTO prodledg VALUES (ls_prodledg.*) 
			LET err_message = "I58 - 1st prodstat UPDATE" 
			UPDATE prodstatus 
			SET seq_num = l_rec_src_prodstatus.seq_num, 
			onhand_qty = l_rec_src_prodstatus.onhand_qty , 
			back_qty = l_rec_src_prodstatus.back_qty 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = l_rec_src_prodstatus.part_code 
			AND ware_code = l_rec_src_prodstatus.ware_code 
			### Destination Warehouse
			DECLARE c2_prodstatus CURSOR FOR 
			SELECT * FROM prodstatus 
			WHERE prodstatus.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = modu_arr_ibtdetl[i].part_code 
			AND ware_code = l_rec_inparms.ibt_ware_code 
			FOR UPDATE 
			OPEN c2_prodstatus 
			FETCH c2_prodstatus INTO l_rec_dst_prodstatus.* 
			IF status = notfound THEN 
				#create entry
				LET l_rec_dst_prodstatus.* = l_rec_src_prodstatus.* 
				LET l_rec_dst_prodstatus.ware_code = l_rec_inparms.ibt_ware_code 
				LET l_rec_dst_prodstatus.onhand_qty = 0 
				LET l_rec_dst_prodstatus.onord_qty = 0 
				LET l_rec_dst_prodstatus.forward_qty = 0 
				LET l_rec_dst_prodstatus.reserved_qty = 0 
				LET l_rec_dst_prodstatus.back_qty = 0 
				LET l_rec_dst_prodstatus.transit_qty = 0 
				LET l_rec_dst_prodstatus.seq_num = 0 
				LET l_rec_dst_prodstatus.wgted_cost_amt = ls_prodledg.cost_amt 
				LET l_rec_dst_prodstatus.status_date = today 
				LET err_message = "I58 - 1st prodstat INSERT" 
				INSERT INTO prodstatus VALUES (l_rec_dst_prodstatus.*) 
				# check parent IF NOT there THEN add it also
				CALL break_prod(glob_rec_kandoouser.cmpy_code, l_rec_product.part_code, l_rec_product.class_code,1) 
				RETURNING l_rec_parent_part_code,l_dashes,l_rec_flex_part_code,l_flex 
				SELECT * INTO l_rec_par_prodstatus.* 
				FROM prodstatus 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = l_rec_parent_part_code 
				AND ware_code = l_rec_inparms.ibt_ware_code 
				IF status = notfound THEN 
					# create parent entry
					LET l_rec_par_prodstatus.* = l_rec_dst_prodstatus.* 
					LET l_rec_par_prodstatus.part_code = l_rec_parent_part_code 
					LET l_rec_par_prodstatus.status_date = today 
					LET err_message = "I58 - 1st parent prodstat INSERT" 
					INSERT INTO prodstatus VALUES (l_rec_par_prodstatus.*) 
				END IF 
			END IF 
			CLOSE c2_prodstatus 
			IF l_rec_dst_prodstatus.wgted_cost_amt IS NULL THEN 
				LET l_rec_dst_prodstatus.wgted_cost_amt = 0 
			END IF 
			IF (modu_arr_ibtdetl[i].conf_qty + l_rec_dst_prodstatus.onhand_qty) > 0 THEN 
				IF l_rec_dst_prodstatus.onhand_qty > 0 THEN 
					LET l_rec_dst_prodstatus.wgted_cost_amt = 
					( ( l_rec_dst_prodstatus.wgted_cost_amt 
					* l_rec_dst_prodstatus.onhand_qty) + 
					+ ( modu_arr_ibtdetl[i].conf_qty * 
					l_rec_src_prodstatus.wgted_cost_amt)) 
					/(modu_arr_ibtdetl[i].conf_qty+l_rec_dst_prodstatus.onhand_qty) 
				ELSE 
					LET l_rec_dst_prodstatus.wgted_cost_amt = 
					l_rec_src_prodstatus.wgted_cost_amt 
				END IF 
			END IF 
			LET l_rec_dst_prodstatus.onhand_qty = l_rec_dst_prodstatus.onhand_qty 
			+ modu_arr_ibtdetl[i].conf_qty 
			LET l_rec_dst_prodstatus.seq_num = l_rec_dst_prodstatus.seq_num + 1 
			INITIALIZE ls_prodledg.* TO NULL 
			LET ls_prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET ls_prodledg.part_code = modu_arr_ibtdetl[i].part_code 
			LET ls_prodledg.ware_code = l_rec_inparms.ibt_ware_code 
			LET ls_prodledg.tran_date = modu_delivery_date 
			LET ls_prodledg.seq_num = l_rec_dst_prodstatus.seq_num 
			LET ls_prodledg.trantype_ind = "T" 
			LET ls_prodledg.year_num = modu_rec_ibthead.year_num 
			LET ls_prodledg.period_num = modu_rec_ibthead.period_num 
			LET ls_prodledg.source_text = l_rec_src_prodstatus.ware_code 
			LET ls_prodledg.source_num = l_trans_num 
			LET ls_prodledg.tran_qty = modu_arr_ibtdetl[i].conf_qty 
			LET ls_prodledg.cost_amt = l_rec_ibtload.unit_cost_amt 
			LET ls_prodledg.bal_amt = l_rec_dst_prodstatus.onhand_qty 
			LET ls_prodledg.sales_amt = 0 
			IF l_rec_inparms.hist_flag = "Y" THEN 
				LET ls_prodledg.hist_flag = "N" 
			ELSE 
				LET ls_prodledg.hist_flag = "Y" 
			END IF 
			LET ls_prodledg.post_flag = "N" 
			LET ls_prodledg.entry_code = glob_rec_kandoouser.sign_on_code 
			LET ls_prodledg.entry_date = today 
			LET ls_prodledg.acct_code = l_rec_category.adj_acct_code 
			CALL build_mask(glob_rec_kandoouser.cmpy_code, l_ibt_mask_code, ls_prodledg.acct_code) 
			RETURNING ls_prodledg.acct_code 
			LET err_message = "2nd prodledg INSERT" 
			INSERT INTO prodledg VALUES (ls_prodledg.*) 
			LET err_message = "2nd prodstat UPDATE" 
			UPDATE prodstatus 
			SET seq_num = l_rec_dst_prodstatus.seq_num, 
			onhand_qty = l_rec_dst_prodstatus.onhand_qty, 
			wgted_cost_amt = l_rec_dst_prodstatus.wgted_cost_amt 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = l_rec_dst_prodstatus.part_code 
			AND ware_code = l_rec_dst_prodstatus.ware_code 
			LET err_message = "ibtdetl SELECT" 
			SELECT * INTO l_rec_ibtdetl.* FROM ibtdetl 
			WHERE trans_num = l_trans_num 
			AND line_num = modu_arr_ibtdetl[i].line_num 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET l_rec_ibtdetl.conf_qty = modu_arr_ibtdetl[i].conf_qty 
			+ modu_arr_save_ibtdetl[i].conf_qty 
			LET l_rec_ibtdetl.back_qty = l_rec_ibtdetl.trf_qty 
			- l_rec_ibtdetl.conf_qty 
			- l_rec_ibtdetl.rec_qty 
			LET err_message = "ibtdetl UPDATE" 
			UPDATE ibtdetl 
			SET conf_qty = l_rec_ibtdetl.conf_qty, 
			back_qty = l_rec_ibtdetl.back_qty 
			WHERE trans_num = l_trans_num 
			AND line_num = modu_arr_ibtdetl[i].line_num 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET err_message = "To warehouse transit qty UPDATE" 
			DECLARE c9_prodstatus CURSOR FOR 
			SELECT * FROM prodstatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = ls_prodledg.part_code 
			AND ware_code = modu_rec_ibthead.to_ware_code 
			FOR UPDATE 
			OPEN c9_prodstatus 
			FETCH c9_prodstatus INTO l_rec_to_prodstatus.* 
			UPDATE prodstatus 
			SET transit_qty = transit_qty 
			+ ls_prodledg.tran_qty 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ware_code = modu_rec_ibthead.to_ware_code 
			AND part_code = ls_prodledg.part_code 
			CLOSE c9_prodstatus 
			IF l_rec_product.serial_flag = "Y" THEN 
				LET err_message = "I58 - serial_update " 
				LET l_rec_serialinfo.cmpy_code = ls_prodledg.cmpy_code 
				LET l_rec_serialinfo.part_code = ls_prodledg.part_code 
				LET l_rec_serialinfo.trantype_ind = 'T' 
				LET status = serial_update(l_rec_serialinfo.*, 
				modu_arr_ibtdetl[i].conf_qty, '') 
				IF status <> 0 THEN 
					GOTO recovery 
					EXIT program 
				END IF 
			END IF 
		END FOR 
		SELECT count(*) INTO l_ibtcnt FROM ibtdetl 
		WHERE (conf_qty + rec_qty) < trf_qty 
		AND status_ind <> "4" 
		AND trans_num = modu_rec_ibthead.trans_num 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF l_ibtcnt = 0 THEN 
			SELECT count(*) INTO l_records_cnt FROM ibtdetl 
			WHERE rec_qty < trf_qty 
			AND status_ind <> "4" 
			AND trans_num = modu_rec_ibthead.trans_num 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF l_records_cnt = 0 THEN 
				LET modu_rec_ibthead.status_ind = IBTHEAD_STATUS_IND_TRANSFER_COMPLETED_C 
			ELSE 
				LET modu_rec_ibthead.status_ind = IBTHEAD_STATUS_IND_TRANSFER_PARTIALLY_COMPLETED_P 
			END IF 
		ELSE 
			SELECT count(*) INTO l_ibtcnt FROM ibtdetl 
			WHERE (conf_qty + rec_qty) != 0 
			AND status_ind <> "4" 
			AND trans_num = modu_rec_ibthead.trans_num 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF l_ibtcnt = 0 THEN 
				LET modu_rec_ibthead.status_ind = IBTHEAD_STATUS_IND_TRANSFER_UNDELIVERED_U 
			ELSE 
				LET modu_rec_ibthead.status_ind = IBTHEAD_STATUS_IND_TRANSFER_PARTIALLY_COMPLETED_P 
			END IF 
		END IF 
		SELECT rev_num INTO l_rev_num FROM ibthead 
		WHERE trans_num = l_trans_num 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF modu_orig_rev_num != l_rev_num THEN 
			LET msgresp = kandoomsg("W",7026,"") 
			#7026 Another user has edited this ORDER - Changes NOT saved
			LET err_message = "I59 - Another user has modified transfer" 
			ROLLBACK WORK 
			RETURN false 
		END IF 
		#Allow the UPDATE of the tran_date TO today
		UPDATE ibthead 
		SET status_ind = modu_rec_ibthead.status_ind, 
		trans_date = today, 
		rev_num = rev_num + 1 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND trans_num = modu_rec_ibthead.trans_num 
	COMMIT WORK 
	RETURN true 
END FUNCTION    # write_transfer


FUNCTION automatic_receipt(l_trans_num) 
	DEFINE 
	l_trans_num LIKE ibthead.trans_num, 
	l_rec_prodledg RECORD LIKE prodledg.*, 
	l_rec_prodstatus RECORD LIKE prodstatus.*, 
	l_rec_product RECORD LIKE product.*, 
	l_rec_src_prodstatus RECORD LIKE prodstatus.*, 
	l_rec_dst_prodstatus RECORD LIKE prodstatus.*, 
	l_rec_category RECORD LIKE category.*, 
	l_dst_mask_code LIKE warehouse.acct_mask_code, 
	ls_prodledg RECORD LIKE prodledg.*, 
	l_rec_ibtdetl RECORD LIKE ibtdetl.*, 
	l_rec_ibtload RECORD LIKE ibtload.*, 
	l_rec_warehouse RECORD LIKE warehouse.*, 
	l_rec_inparms RECORD LIKE inparms.*, 
	l_rec_serialinfo RECORD LIKE serialinfo.*, 
	l_period_num LIKE ibthead.period_num, 
	l_year_num LIKE ibthead.year_num, 
	l_rev_num, idx, i, cnt, l_ibt_cnt, l_rec_cnt SMALLINT, 
	err_message CHAR(40) 

	LET msgresp = kandoomsg("U",1005,"") 
	#1005 Updating Database
	FOR i = 1 TO 500 
		LET modu_arr_save_ibtdetl[i].rec_qty = modu_arr_ibtdetl[i].conf_qty 
		IF modu_arr_ibtdetl[i].line_num = 0 
		OR modu_arr_ibtdetl[i].line_num IS NULL THEN 
			EXIT FOR 
		END IF 
	END FOR 
	SELECT * INTO l_rec_inparms.* FROM inparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 
	GOTO bypass 
	LABEL recovery: 
	IF error_recover(err_message, status) = "N" THEN 
		RETURN false 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		LET l_period_num = modu_rec_ibthead.period_num 
		LET l_year_num = modu_rec_ibthead.year_num 
		DECLARE c2_ibthead CURSOR FOR 
		SELECT * FROM ibthead 
		WHERE trans_num = l_trans_num 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		FOR UPDATE 
		OPEN c2_ibthead 
		FETCH c2_ibthead INTO modu_rec_ibthead.* 
		LET modu_rec_ibthead.period_num = l_period_num 
		LET modu_rec_ibthead.year_num = l_year_num 
		FOR cnt = 1 TO 500 
			IF modu_arr_ibtdetl[cnt].line_num IS NULL 
			OR modu_arr_ibtdetl[cnt].line_num = 0 THEN 
				LET cnt = cnt - 1 
				EXIT FOR 
			END IF 
		END FOR 
		FOR idx = 1 TO cnt 
			# IF a new part code flexible structure has been selected THEN alter
			# the prodstatus of both the old AND new part codes TO reflect this.
			IF modu_arr_ibtdetl[idx].part_code <> modu_arr_save_ibtdetl[idx].part_code THEN 
				SELECT * INTO l_rec_ibtdetl.* FROM ibtdetl 
				WHERE trans_num = l_trans_num 
				AND line_num = modu_arr_save_ibtdetl[idx].line_num 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status != notfound THEN 
					UPDATE prodstatus 
					SET back_qty = back_qty - l_rec_ibtdetl.trf_qty 
					WHERE part_code = l_rec_ibtdetl.part_code 
					AND ware_code = modu_rec_ibthead.from_ware_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					UPDATE prodstatus 
					SET back_qty = back_qty + modu_arr_save_ibtdetl[idx].back_qty 
					WHERE part_code = modu_arr_ibtdetl[idx].part_code 
					AND ware_code = modu_rec_ibthead.from_ware_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					UPDATE ibtdetl 
					SET part_code = modu_arr_ibtdetl[idx].part_code, 
					trf_qty = modu_arr_save_ibtdetl[idx].trf_qty 
					WHERE trans_num = l_trans_num 
					AND line_num = modu_arr_ibtdetl[idx].line_num 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				END IF 
			END IF 
		END FOR 
		## Create Prodledger Entries
		FOR i = 1 TO cnt 
			SELECT * INTO l_rec_ibtdetl.* FROM ibtdetl 
			WHERE trans_num = l_trans_num 
			AND line_num = modu_arr_ibtdetl[i].line_num 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			SELECT * INTO l_rec_product.* FROM product 
			WHERE part_code = l_rec_ibtdetl.part_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 

			IF modu_arr_save_ibtdetl[i].rec_qty = 0 THEN 
				IF l_rec_product.serial_flag = "Y" THEN 
					IF l_rec_ibtdetl.status_ind = IBTDETL_STATUS_IND_CANCELED_4 THEN 
						CALL serial_delete(l_rec_ibtdetl.part_code, 
						modu_rec_ibthead.from_ware_code) 
					END IF 
				END IF 
				CONTINUE FOR 
			END IF 
			INITIALIZE l_rec_prodledg.* TO NULL 
			LET l_rec_prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET l_rec_prodledg.part_code = l_rec_ibtdetl.part_code 
			LET l_rec_prodledg.ware_code = modu_rec_ibthead.from_ware_code 
			LET l_rec_prodledg.tran_date = modu_delivery_date 
			LET l_rec_prodledg.seq_num = l_rec_ibtdetl.line_num 
			LET l_rec_prodledg.trantype_ind = "T" 
			LET l_rec_prodledg.year_num = modu_rec_ibthead.year_num 
			LET l_rec_prodledg.period_num = modu_rec_ibthead.period_num 
			LET l_rec_prodledg.source_text = modu_rec_ibthead.to_ware_code 
			LET l_rec_prodledg.source_num = l_trans_num 
			LET l_rec_prodledg.tran_qty = modu_arr_save_ibtdetl[i].rec_qty 
			LET l_rec_prodledg.bal_amt = 0 
			LET l_rec_prodledg.cost_amt = 0 
			LET l_rec_prodledg.sales_amt = 0 
			IF l_rec_inparms.hist_flag = "Y" THEN 
				LET l_rec_prodledg.hist_flag = "N" 
			ELSE 
				LET l_rec_prodledg.hist_flag = "Y" 
			END IF 
			LET l_rec_prodledg.post_flag = "N" 
			LET l_rec_prodledg.entry_code = glob_rec_kandoouser.sign_on_code 
			LET l_rec_prodledg.entry_date = today 
			SELECT * INTO l_rec_category.* FROM category 
			WHERE cat_code = l_rec_product.cat_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			### Source Warehouse
			DECLARE c1_prodstatus CURSOR FOR 
			SELECT * FROM prodstatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ware_code = l_rec_prodledg.ware_code 
			AND part_code = l_rec_prodledg.part_code 
			FOR UPDATE 
			OPEN c1_prodstatus 
			FETCH c1_prodstatus INTO l_rec_src_prodstatus.* 
			INITIALIZE l_rec_ibtload.* TO NULL 
			SELECT * INTO l_rec_ibtload.* FROM ibtload 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND trans_num = l_trans_num 
			AND line_num = modu_arr_ibtdetl[i].line_num 
			IF status = notfound THEN 
				LET l_rec_ibtload.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_rec_ibtload.trans_num = modu_rec_ibthead.trans_num 
				LET l_rec_ibtload.line_num = modu_arr_ibtdetl[i].line_num 
				LET l_rec_ibtload.pick_num = 0 
				LET l_rec_ibtload.unit_cost_amt = l_rec_src_prodstatus.wgted_cost_amt 
				LET l_rec_ibtload.unit_cart_amt = 0 
				LET l_rec_ibtload.load_qty = 0 
				LET l_rec_ibtload.rec_qty = 0 
				LET err_message = "INSERT ibtload" 
				INSERT INTO ibtload VALUES (l_rec_ibtload.*) 
			END IF 
			LET l_rec_src_prodstatus.seq_num = l_rec_src_prodstatus.seq_num + 1 
			IF l_rec_src_prodstatus.stocked_flag = "Y" THEN 
				LET l_rec_src_prodstatus.onhand_qty = l_rec_src_prodstatus.onhand_qty 
				- l_rec_prodledg.tran_qty 
				IF modu_arr_ibtdetl[i].prev_conf > 0 THEN 
					LET l_rec_src_prodstatus.back_qty = l_rec_src_prodstatus.back_qty 
					- modu_arr_save_ibtdetl[i].back_qty 
					+ (l_rec_ibtdetl.trf_qty 
					- modu_arr_ibtdetl[i].prev_conf 
					- modu_arr_ibtdetl[i].rec_qty 
					- modu_arr_save_ibtdetl[i].rec_qty) 
				ELSE 
					LET l_rec_src_prodstatus.back_qty = l_rec_src_prodstatus.back_qty 
					- (l_rec_ibtdetl.trf_qty 
					- modu_arr_ibtdetl[i].rec_qty) 

				END IF 
			ELSE 
				LET l_rec_src_prodstatus.onhand_qty = 0 
				LET l_rec_src_prodstatus.back_qty = 0 
			END IF 
			LET err_message = "I59 - Product Ledger Entry" 
			INITIALIZE ls_prodledg.* TO NULL 
			LET ls_prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET ls_prodledg.part_code = l_rec_prodledg.part_code 
			LET ls_prodledg.ware_code = l_rec_prodledg.ware_code 
			LET ls_prodledg.tran_date = l_rec_prodledg.tran_date 
			LET ls_prodledg.seq_num = l_rec_src_prodstatus.seq_num 
			LET ls_prodledg.trantype_ind = "T" 
			LET ls_prodledg.year_num = l_rec_prodledg.year_num 
			LET ls_prodledg.period_num = l_rec_prodledg.period_num 
			LET ls_prodledg.source_text = l_rec_prodledg.source_text 
			LET ls_prodledg.source_num = modu_rec_ibthead.trans_num 
			LET ls_prodledg.tran_qty = 0 - l_rec_prodledg.tran_qty 
			LET ls_prodledg.bal_amt = l_rec_src_prodstatus.onhand_qty 
			LET ls_prodledg.cost_amt = l_rec_ibtload.unit_cost_amt 
			LET ls_prodledg.sales_amt = 0 
			IF l_rec_inparms.hist_flag = "Y" THEN 
				LET ls_prodledg.hist_flag = "N" 
			ELSE 
				LET ls_prodledg.hist_flag = "Y" 
			END IF 
			LET ls_prodledg.post_flag = "N" 
			LET ls_prodledg.entry_code = glob_rec_kandoouser.sign_on_code 
			LET ls_prodledg.entry_date = today 
			# WHERE the user has confirmed the despatch AND receipt of the goods,
			# both prodledg entries will contain the destination warehouse
			# adjustment account, causing the interim entries TO CLEAR
			# through the GL.  The net result IS a credit FROM the source warehouse
			# stock account AND a debit TO the destination warehouse stock account.
			# Refer TO ISP FOR posting rules.
			LET ls_prodledg.acct_code = l_rec_category.adj_acct_code 
			SELECT acct_mask_code INTO l_dst_mask_code FROM warehouse 
			WHERE ware_code = modu_rec_ibthead.to_ware_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			CALL build_mask(glob_rec_kandoouser.cmpy_code, 
			l_dst_mask_code, 
			ls_prodledg.acct_code) 
			RETURNING ls_prodledg.acct_code 
			LET err_message = "1st prodledg INSERT" 
			INSERT INTO prodledg VALUES (ls_prodledg.*) 
			LET err_message = "1st prodstat UPDATE" 
			UPDATE prodstatus 
			SET seq_num = l_rec_src_prodstatus.seq_num, 
			onhand_qty = l_rec_src_prodstatus.onhand_qty, 
			back_qty = l_rec_src_prodstatus.back_qty 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = l_rec_prodledg.part_code 
			AND ware_code = l_rec_prodledg.ware_code 
			### Destination Warehouse
			DECLARE c3_prodstatus CURSOR FOR 
			SELECT * FROM prodstatus 
			WHERE prodstatus.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = l_rec_prodledg.part_code 
			AND ware_code = l_rec_prodledg.source_text 
			FOR UPDATE 
			OPEN c3_prodstatus 
			FETCH c3_prodstatus INTO l_rec_dst_prodstatus.* 
			IF status = notfound THEN 
				LET l_rec_dst_prodstatus.* = l_rec_src_prodstatus.* 
				LET l_rec_dst_prodstatus.ware_code = l_rec_prodledg.source_text 
				LET l_rec_dst_prodstatus.onhand_qty = 0 
				LET l_rec_dst_prodstatus.onord_qty = 0 
				LET l_rec_dst_prodstatus.forward_qty = 0 
				LET l_rec_dst_prodstatus.reserved_qty = 0 
				LET l_rec_dst_prodstatus.back_qty = 0 
				LET l_rec_dst_prodstatus.transit_qty = 0 
				LET l_rec_dst_prodstatus.seq_num = 0 
				LET l_rec_dst_prodstatus.wgted_cost_amt = ls_prodledg.cost_amt 
				LET l_rec_dst_prodstatus.status_date = today 
				LET err_message = "1st prodstat INSERT" 
				INSERT INTO prodstatus VALUES (l_rec_dst_prodstatus.*) 
			END IF 
			CLOSE c3_prodstatus 
			IF l_rec_dst_prodstatus.wgted_cost_amt IS NULL THEN 
				LET l_rec_dst_prodstatus.wgted_cost_amt = 0 
			END IF 
			IF (l_rec_dst_prodstatus.onhand_qty + l_rec_prodledg.tran_qty) > 0 THEN 
				IF l_rec_dst_prodstatus.onhand_qty > 0 THEN 
					LET l_rec_dst_prodstatus.wgted_cost_amt = 
					( ( l_rec_dst_prodstatus.wgted_cost_amt 
					* l_rec_dst_prodstatus.onhand_qty) + 
					+ ( l_rec_prodledg.tran_qty * 
					l_rec_src_prodstatus.wgted_cost_amt)) 
					/(l_rec_prodledg.tran_qty+l_rec_dst_prodstatus.onhand_qty) 
				ELSE 
					LET l_rec_dst_prodstatus.wgted_cost_amt = 
					l_rec_src_prodstatus.wgted_cost_amt 
				END IF 
			END IF 
			LET l_rec_dst_prodstatus.onhand_qty = l_rec_dst_prodstatus.onhand_qty 
			+ l_rec_prodledg.tran_qty 
			LET l_rec_dst_prodstatus.seq_num = l_rec_dst_prodstatus.seq_num + 1 
			INITIALIZE ls_prodledg.* TO NULL 
			LET ls_prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET ls_prodledg.part_code = l_rec_prodledg.part_code 
			LET ls_prodledg.ware_code = l_rec_prodledg.source_text 
			LET ls_prodledg.tran_date = modu_delivery_date 
			LET ls_prodledg.seq_num = l_rec_dst_prodstatus.seq_num 
			LET ls_prodledg.trantype_ind = "T" 
			LET ls_prodledg.year_num = l_rec_prodledg.year_num 
			LET ls_prodledg.period_num = l_rec_prodledg.period_num 
			LET ls_prodledg.source_text = l_rec_prodledg.ware_code 
			LET ls_prodledg.source_num = modu_rec_ibthead.trans_num 
			LET ls_prodledg.tran_qty = l_rec_prodledg.tran_qty 
			LET ls_prodledg.bal_amt = l_rec_dst_prodstatus.onhand_qty 
			LET ls_prodledg.cost_amt = l_rec_ibtload.unit_cost_amt 
			LET ls_prodledg.sales_amt = 0 
			IF l_rec_inparms.hist_flag = "Y" THEN 
				LET ls_prodledg.hist_flag = "N" 
			ELSE 
				LET ls_prodledg.hist_flag = "Y" 
			END IF 
			LET ls_prodledg.post_flag = "N" 
			LET ls_prodledg.entry_code = glob_rec_kandoouser.sign_on_code 
			LET ls_prodledg.entry_date = today 
			LET ls_prodledg.acct_code = l_rec_category.adj_acct_code 
			CALL build_mask(glob_rec_kandoouser.cmpy_code, 
			l_dst_mask_code, 
			ls_prodledg.acct_code) 
			RETURNING ls_prodledg.acct_code 
			LET err_message = "2nd prodledg INSERT" 
			INSERT INTO prodledg VALUES (ls_prodledg.*) 
			LET err_message = "2nd prodstat UPDATE" 
			UPDATE prodstatus 
			SET seq_num = l_rec_dst_prodstatus.seq_num, 
			onhand_qty = l_rec_dst_prodstatus.onhand_qty, 
			wgted_cost_amt = l_rec_dst_prodstatus.wgted_cost_amt 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = l_rec_dst_prodstatus.part_code 
			AND ware_code = l_rec_dst_prodstatus.ware_code 
			## Update ibtdetls with rec_qty
			LET err_message = "ibtdetl UPDATE" 
			UPDATE ibtdetl 
			SET rec_qty = rec_qty + l_rec_prodledg.tran_qty 
			WHERE trans_num = modu_rec_ibthead.trans_num 
			AND line_num = l_rec_ibtdetl.line_num 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF l_rec_product.serial_flag = "Y" THEN 
				LET err_message = "I58 - serial_update 2 " 
				LET l_rec_serialinfo.cmpy_code = ls_prodledg.cmpy_code 
				LET l_rec_serialinfo.part_code = ls_prodledg.part_code 
				LET l_rec_serialinfo.ware_code = ls_prodledg.ware_code 
				LET l_rec_serialinfo.trans_num = ls_prodledg.seq_num 
				LET l_rec_serialinfo.trantype_ind = '0' 
				LET status = serial_update(l_rec_serialinfo.*, 
				modu_arr_ibtdetl[i].conf_qty, '') 
				IF status <> 0 THEN 
					GOTO recovery 
					EXIT program 
				END IF 
			END IF 
		END FOR 
		SELECT unique 1 FROM ibtdetl 
		WHERE trans_num = modu_rec_ibthead.trans_num 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND conf_qty > 0 
		IF status = notfound THEN 
			LET modu_rec_ibthead.status_ind = IBTHEAD_STATUS_IND_TRANSFER_COMPLETED_C 
			LET err_message = "ibtdetl back qty UPDATE" 
			UPDATE ibtdetl 
			SET back_qty = 0, 
			trf_qty = conf_qty + rec_qty 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND trans_num = modu_rec_ibthead.trans_num 
			LET err_message = "I58 - serial_return " 
			LET status = serial_return('', '0') 
			IF status <> 0 THEN 
				GOTO recovery 
				EXIT program 
			END IF 
		ELSE 
			LET modu_rec_ibthead.status_ind = IBTHEAD_STATUS_IND_TRANSFER_PARTIALLY_COMPLETED_P 
			LET err_message = "ibtdetl back qty update2" 
			UPDATE ibtdetl 
			SET back_qty = trf_qty - conf_qty - rec_qty 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND trans_num = modu_rec_ibthead.trans_num 
		END IF 
		SELECT rev_num INTO l_rev_num FROM ibthead 
		WHERE trans_num = l_trans_num 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF modu_orig_rev_num != l_rev_num THEN 
			LET msgresp = kandoomsg("W",7026,"") 
			#7026 Another user has edited this ORDER - Changes NOT saved
			LET err_message = "I59 - Another user has modified transfer" 
			ROLLBACK WORK 
			RETURN false 
		END IF 
		LET err_message = "ibthead STATUS UPDATE" 
		UPDATE ibthead 
		SET status_ind = modu_rec_ibthead.status_ind, 
		rev_num = rev_num + 1 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND trans_num = modu_rec_ibthead.trans_num 
	COMMIT WORK 
	RETURN true 
END FUNCTION  # automatic_receipt
