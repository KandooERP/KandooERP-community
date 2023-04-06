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

	Source code beautified by beautify.pl on 2020-01-03 09:12:28	$Id: $
}



############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 

# I59.4gl - Stock Transfers Receipt

GLOBALS 
	DEFINE 
	pa_ibtdetl ARRAY [520] OF RECORD 
		scroll_flag CHAR(1), 
		line_num LIKE ibtdetl.line_num, 
		part_code LIKE product.part_code, 
		back_qty LIKE ibtdetl.back_qty, 
		prev_rec LIKE ibtdetl.rec_qty, 
		rec_qty LIKE ibtdetl.rec_qty, 
		conf_qty LIKE ibtdetl.conf_qty, 
		sell_uom_code LIKE product.sell_uom_code 
	END RECORD, 
	pa_saveibt ARRAY [520] OF RECORD 
		conf_qty LIKE ibtdetl.conf_qty, 
		line_num LIKE ibtdetl.line_num, 
		rec_qty LIKE ibtdetl.rec_qty, 
		part_code LIKE product.part_code, 
		trf_qty LIKE ibtdetl.trf_qty, 
		status_ind LIKE ibtdetl.status_ind, 
		desc_text LIKE product.desc_text 
	END RECORD, 
	pr_delivery_date DATE, 
	pr_part_code LIKE product.part_code, 
	pr_ibthead RECORD LIKE ibthead.*, 
	pr_orig_rev_num SMALLINT 
END GLOBALS 

####################################################################
# MAIN
####################################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("I59") 
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
	where_text CHAR(400), 
	query_text CHAR(500) 

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
			CALL publish_toolbar("kandoo","I59","construct-trans_num-1") -- albo kd-505 

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
END FUNCTION 


FUNCTION scan_orders() 
	DEFINE 
	pr_scroll_flag CHAR(1), 
	pa_ibthead array[300] OF RECORD 
		scroll_flag CHAR(1), 
		trans_num LIKE ibthead.trans_num, 
		from_ware_code LIKE ibthead.from_ware_code, 
		to_ware_code LIKE ibthead.to_ware_code, 
		desc_text LIKE ibthead.desc_text, 
		trans_date LIKE ibthead.trans_date, 
		status_ind LIKE ibthead.status_ind 
	END RECORD, 
	pt_ibthead RECORD LIKE ibthead.*, 
	del_cnt,i,j,idx,scrn SMALLINT 

	LET msgresp = kandoomsg("U",1002,"") 
	#1002  Searching database - please wait
	LET idx = 0 
	FOREACH c_ibthead INTO pr_ibthead.* 
		SELECT unique 1 FROM ibtdetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND trans_num = pr_ibthead.trans_num 
		AND conf_qty > 0 
		IF status = notfound THEN 
			CONTINUE FOREACH 
		END IF 
		LET idx = idx + 1 
		LET pa_ibthead[idx].scroll_flag = NULL 
		LET pa_ibthead[idx].trans_num = pr_ibthead.trans_num 
		LET pa_ibthead[idx].from_ware_code = pr_ibthead.from_ware_code 
		LET pa_ibthead[idx].to_ware_code = pr_ibthead.to_ware_code 
		LET pa_ibthead[idx].desc_text = pr_ibthead.desc_text 
		LET pa_ibthead[idx].trans_date = pr_ibthead.trans_date 
		LET pa_ibthead[idx].status_ind = pr_ibthead.status_ind 
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
		INITIALIZE pa_ibthead[1].* TO NULL 
	END IF 
	OPTIONS DELETE KEY f36, 
	INSERT KEY f36 
	CALL set_count(idx) 
	LET msgresp = kandoomsg("U",1051,"Receipt") 
	#1154 F3/F4 TO Page Fwd/Bwd;  ENTER on line TO Receipt
	INPUT ARRAY pa_ibthead WITHOUT DEFAULTS FROM sr_ibthead.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","I59","input-arr-pa_ibthead-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE FIELD scroll_flag 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			LET pr_scroll_flag = pa_ibthead[idx].scroll_flag 
			DISPLAY pa_ibthead[idx].* TO sr_ibthead[scrn].* 

		AFTER FIELD scroll_flag 
			LET pa_ibthead[idx].scroll_flag = pr_scroll_flag 
			DISPLAY pa_ibthead[idx].scroll_flag TO sr_ibthead[scrn].scroll_flag 

			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF arr_curr() >= arr_count() THEN 
					LET msgresp = kandoomsg("U",9001,"") 
					#9001 There no more rows...
					NEXT FIELD scroll_flag 
				END IF 
				IF pa_ibthead[idx+1].trans_num IS NULL THEN 
					LET msgresp = kandoomsg("U",9001,"") 
					#9001 There no more rows...
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
		BEFORE FIELD trans_num 
			IF pa_ibthead[idx].trans_num IS NULL THEN 
				NEXT FIELD scroll_flag 
			END IF 
			IF pa_ibthead[idx].status_ind = "C" THEN 
				LET msgresp = kandoomsg("I",9528,"") 
				#9528 Transfer has been completed.
				NEXT FIELD scroll_flag 
			END IF 
			CALL receipt_transfer(pa_ibthead[idx].trans_num) 
			SELECT status_ind INTO pa_ibthead[idx].status_ind FROM ibthead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND trans_num = pa_ibthead[idx].trans_num 
			DISPLAY pa_ibthead[idx].status_ind 
			TO sr_ibthead[scrn].status_ind 

			NEXT FIELD scroll_flag 
		AFTER ROW 
			DISPLAY pa_ibthead[idx].* TO sr_ibthead[scrn].* 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 
END FUNCTION 


FUNCTION receipt_transfer(pr_trans_num) 
	DEFINE 
	pr_trans_num LIKE ibthead.trans_num, 
	pr_ibtrec RECORD 
		line_num LIKE ibtdetl.line_num, 
		part_code LIKE product.part_code, 
		back_qty LIKE ibtdetl.back_qty, 
		conf_qty LIKE ibtdetl.conf_qty, 
		rec_qty LIKE ibtdetl.rec_qty, 
		prev_rec LIKE ibtdetl.rec_qty, 
		sell_uom_code LIKE product.sell_uom_code 
	END RECORD, 
	pr_save_date DATE, 
	pr_ibtdetl RECORD LIKE ibtdetl.*, 
	pr_product RECORD LIKE product.*, 
	pr_ser_cnt SMALLINT, 
	pr_rec_type CHAR(1), 
	pr_invalid_period, idx, scrn SMALLINT 

	OPEN WINDOW i671 with FORM "I671" 
	 CALL windecoration_i("I671") -- albo kd-758 

	CALL serial_init(glob_rec_kandoouser.cmpy_code,"t", "t", pr_trans_num ) 

	SELECT rev_num INTO pr_orig_rev_num FROM ibthead 
	WHERE trans_num = pr_trans_num 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET msgresp = kandoomsg("U",1020,"Receipt") 
	#1020 Enter Receipt Details; OK TO Continue;
	FOR idx = 1 TO 520 
		INITIALIZE pa_ibtdetl[idx].* TO NULL 
		INITIALIZE pa_saveibt[idx].* TO NULL 
	END FOR 
	DISPLAY BY NAME pr_trans_num 

	LET pr_delivery_date = today 
	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,pr_delivery_date) 
	RETURNING pr_ibthead.year_num, 
	pr_ibthead.period_num 
	LET pr_rec_type = "1" 
	INPUT BY NAME pr_delivery_date, 
	pr_ibthead.year_num, 
	pr_ibthead.period_num, 
	pr_rec_type WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","I59","input-pr_delivery_date-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE FIELD pr_delivery_date 
			LET pr_save_date = pr_delivery_date 
		AFTER FIELD pr_delivery_date 
			IF pr_delivery_date IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD pr_delivery_date 
			END IF 
			IF pr_delivery_date != pr_save_date THEN 
				CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,pr_delivery_date) 
				RETURNING pr_ibthead.year_num, 
				pr_ibthead.period_num 
				DISPLAY BY NAME pr_ibthead.year_num, 
				pr_ibthead.period_num 

			END IF 
		AFTER FIELD year_num 
			IF pr_ibthead.year_num IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD year_num 
			END IF 
		AFTER FIELD period_num 
			IF pr_ibthead.period_num IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD period_num 
			END IF 
			CALL valid_period(glob_rec_kandoouser.cmpy_code, 
			pr_ibthead.year_num, 
			pr_ibthead.period_num, 
			TRAN_TYPE_INVOICE_IN) 
			RETURNING pr_ibthead.year_num, 
			pr_ibthead.period_num, 
			pr_invalid_period 
			IF pr_invalid_period THEN 
				NEXT FIELD year_num 
			END IF 
		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF pr_delivery_date IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD pr_delivery_date 
				END IF 
				IF pr_ibthead.year_num IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD year_num 
				END IF 
				IF pr_ibthead.period_num IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD period_num 
				END IF 
				IF pr_rec_type IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD pr_rec_type 
				END IF 
				CALL valid_period(glob_rec_kandoouser.cmpy_code, 
				pr_ibthead.year_num, 
				pr_ibthead.period_num, 
				TRAN_TYPE_INVOICE_IN) 
				RETURNING pr_ibthead.year_num, 
				pr_ibthead.period_num, 
				pr_invalid_period 
				IF pr_invalid_period THEN 
					NEXT FIELD year_num 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		CLOSE WINDOW i671 
		RETURN 
	END IF 
	LET msgresp = kandoomsg("I",1130,"") 
	#1130 F3/F4 TO Page Fwd/Bwd; ENTER TO Edit
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	DECLARE c_ibtdetl CURSOR FOR 
	SELECT * FROM ibtdetl 
	WHERE trans_num = pr_trans_num 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	ORDER BY line_num 
	LET idx = 0 
	FOREACH c_ibtdetl INTO pr_ibtdetl.* 
		LET idx = idx + 1 
		SELECT * INTO pr_product.* FROM product 
		WHERE part_code = pr_ibtdetl.part_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pa_saveibt[idx].line_num = pr_ibtdetl.line_num 
		LET pa_saveibt[idx].rec_qty = pr_ibtdetl.rec_qty 
		LET pa_saveibt[idx].part_code = pr_product.part_code 
		LET pa_saveibt[idx].desc_text = pr_product.desc_text 
		LET pa_saveibt[idx].trf_qty = pr_ibtdetl.trf_qty 
		LET pa_saveibt[idx].status_ind = pr_ibtdetl.status_ind 
		LET pa_saveibt[idx].conf_qty = pr_ibtdetl.conf_qty 
		LET pa_ibtdetl[idx].line_num = pr_ibtdetl.line_num 
		LET pa_ibtdetl[idx].part_code = pr_ibtdetl.part_code 
		LET pa_ibtdetl[idx].sell_uom_code = pr_product.sell_uom_code 
		LET pa_ibtdetl[idx].prev_rec = pr_ibtdetl.rec_qty 
		LET pa_ibtdetl[idx].back_qty = pr_ibtdetl.back_qty 
		IF pr_rec_type = "1" THEN 
			LET pa_ibtdetl[idx].rec_qty = pr_ibtdetl.conf_qty 
			LET pa_ibtdetl[idx].conf_qty = 0 
		ELSE 
			LET pa_ibtdetl[idx].rec_qty = 0 
			LET pa_ibtdetl[idx].conf_qty = pr_ibtdetl.conf_qty 
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
	INPUT ARRAY pa_ibtdetl WITHOUT DEFAULTS FROM sr_ibtdetl.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","I59","input-arr-pa_ibtdetl-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			NEXT FIELD scroll_flag 
		AFTER ROW 
			DISPLAY pa_ibtdetl[idx].* TO sr_ibtdetl[scrn].* 

		BEFORE FIELD scroll_flag 
			LET pr_ibtrec.line_num = pa_ibtdetl[idx].line_num 
			LET pr_ibtrec.part_code = pa_ibtdetl[idx].part_code 
			LET pr_ibtrec.sell_uom_code = pa_ibtdetl[idx].sell_uom_code 
			LET pr_ibtrec.back_qty = pa_ibtdetl[idx].back_qty 
			LET pr_ibtrec.conf_qty = pa_ibtdetl[idx].conf_qty 
			LET pr_ibtrec.rec_qty = pa_ibtdetl[idx].rec_qty 
			LET pr_ibtrec.prev_rec = pa_ibtdetl[idx].prev_rec 
			DISPLAY pa_ibtdetl[idx].* TO sr_ibtdetl[scrn].* 

			DISPLAY BY NAME pa_saveibt[idx].desc_text, 
			pa_saveibt[idx].trf_qty 

		AFTER FIELD scroll_flag 
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF arr_curr() >= arr_count() THEN 
					LET msgresp = kandoomsg("U",9001,"") 
					#9001 There no more rows...
					NEXT FIELD scroll_flag 
				END IF 
				IF pa_ibtdetl[idx+1].line_num IS NULL THEN 
					LET msgresp = kandoomsg("U",9001,"") 
					#9001 There no more rows...
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
		BEFORE FIELD line_num 
			IF pa_saveibt[idx].status_ind = "4" THEN 
				LET msgresp = kandoomsg("I",9527,"") 
				#9527 Transfer line has been cancelled.
				NEXT FIELD scroll_flag 
			END IF 
			IF pa_saveibt[idx].conf_qty = 0 THEN 
				LET msgresp = kandoomsg("I",9526,"") 
				#9526 This line has no confirmed stock.
				NEXT FIELD scroll_flag 
			END IF 
			IF pa_ibtdetl[idx].rec_qty = 0 
			OR pa_ibtdetl[idx].rec_qty IS NULL THEN 
				LET pa_ibtdetl[idx].rec_qty = pa_ibtdetl[idx].conf_qty 
			END IF 
			DISPLAY pa_ibtdetl[idx].* TO sr_ibtdetl[scrn].* 

			NEXT FIELD rec_qty 

		BEFORE FIELD rec_qty 
			SELECT unique 1 FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pa_ibtdetl[idx].part_code 
			AND serial_flag = 'Y' 
			IF status <> notfound THEN 
				#            IF  fgl_lastkey() = fgl_keyval("up")
				#             OR fgl_lastkey() = fgl_keyval("left")
				#                LET pr_direction = 'U'
				#            ELSE
				#                LET pr_direction = 'D'
				#            END IF

				LET pr_ser_cnt = serial_input(pa_ibtdetl[idx].part_code, 
				pr_ibthead.from_ware_code, 
				pa_ibtdetl[idx].rec_qty) 
				IF pr_ser_cnt < 0 THEN 
					IF pr_ser_cnt = -1 THEN 
						NEXT FIELD part_code 
					ELSE 
						CALL errorlog("I59 - Fatal error in serial_input ") 
						EXIT program 
					END IF 
				ELSE 
					LET pa_ibtdetl[idx].rec_qty = pr_ser_cnt 
					LET pa_ibtdetl[idx].conf_qty = pa_saveibt[idx].conf_qty 
					- pa_ibtdetl[idx].rec_qty 
					DISPLAY pa_ibtdetl[idx].rec_qty, 
					pa_ibtdetl[idx].conf_qty 
					TO sr_ibtdetl[scrn].rec_qty, 
					sr_ibtdetl[scrn].conf_qty 

					NEXT FIELD scroll_flag 
					#               IF pr_direction = 'U' THEN
					#               OTHERWISE
					#                  NEXT FIELD rec_qty
				END IF 
			END IF 

		AFTER FIELD rec_qty 
			CASE 
				WHEN fgl_lastkey() = fgl_keyval("accept") 
					OR fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("down") 
					IF pa_ibtdetl[idx].rec_qty IS NULL THEN 
						LET msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered
						NEXT FIELD rec_qty 
					END IF 
					IF pa_ibtdetl[idx].rec_qty < 0 THEN 
						LET msgresp = kandoomsg("W",9188,"") 
						#9188 Quantity must be greater than zero
						NEXT FIELD rec_qty 
					END IF 
					IF pa_ibtdetl[idx].rec_qty > pa_saveibt[idx].conf_qty THEN 
						LET msgresp = kandoomsg("U",9046,pa_saveibt[idx].conf_qty) 
						#9046 Value must be less than OR equal TO 10
						NEXT FIELD rec_qty 
					END IF 
					LET pa_ibtdetl[idx].conf_qty = pa_saveibt[idx].conf_qty 
					- pa_ibtdetl[idx].rec_qty 
					DISPLAY pa_ibtdetl[idx].conf_qty 
					TO sr_ibtdetl[scrn].conf_qty 

					NEXT FIELD scroll_flag 
				WHEN fgl_lastkey() = fgl_keyval("up") 
					OR fgl_lastkey() = fgl_keyval("left") 
					NEXT FIELD rec_qty 
				OTHERWISE 
					NEXT FIELD rec_qty 
			END CASE 
		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				IF NOT (infield(scroll_flag)) THEN 
					LET pa_ibtdetl[idx].line_num = pr_ibtrec.line_num 
					LET pa_ibtdetl[idx].part_code = pr_ibtrec.part_code 
					LET pa_ibtdetl[idx].sell_uom_code = pr_ibtrec.sell_uom_code 
					LET pa_ibtdetl[idx].back_qty = pr_ibtrec.back_qty 
					LET pa_ibtdetl[idx].conf_qty = pr_ibtrec.conf_qty 
					LET pa_ibtdetl[idx].rec_qty = pr_ibtrec.rec_qty 
					LET pa_ibtdetl[idx].prev_rec = pr_ibtrec.prev_rec 
					LET int_flag = false 
					LET quit_flag = false 
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
		CLOSE WINDOW i671 
		RETURN 
	END IF 
	LET msgresp = kandoomsg("W",8036,"") 
	#8036 Confirm TO UPDATE transfer
	IF msgresp = "Y" THEN 
		IF write_transfer(pr_trans_num) THEN 
			LET msgresp = kandoomsg("I",7009,"") 
			#7009 Transfer successfully receipted
		ELSE 
			LET msgresp = kandoomsg("I",7053,"") 
			#7053 Transfer receipt failed
		END IF 
	END IF 
	CLOSE WINDOW i671 
END FUNCTION 


FUNCTION write_transfer(pr_trans_num) 
	DEFINE 
	pr_trans_num LIKE ibthead.trans_num, 
	pr_prodledg RECORD LIKE prodledg.*, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pr_product RECORD LIKE product.*, 
	pr_src_prodstatus RECORD LIKE prodstatus.*, 
	pr_dst_prodstatus RECORD LIKE prodstatus.*, 
	pr_category RECORD LIKE category.*, 
	pr_dst_mask_code LIKE warehouse.acct_mask_code, 
	ps_prodledg RECORD LIKE prodledg.*, 
	pr_ibtdetl RECORD LIKE ibtdetl.*, 
	pr_ibtload RECORD LIKE ibtload.*, 
	pr_warehouse RECORD LIKE warehouse.*, 
	pr_inparms RECORD LIKE inparms.*, 
	pr_serialinfo RECORD LIKE serialinfo.*, 
	pr_period_num LIKE ibthead.period_num, 
	pr_year_num LIKE ibthead.year_num, 
	pr_rev_num, i, cnt, pr_ibtcnt, pr_rec_cnt SMALLINT, 
	err_message CHAR(40) 

	LET msgresp = kandoomsg("U",1005,"") 
	#1005 Updating Database
	SELECT unique * INTO pr_inparms.* FROM inparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	GOTO bypass 
	LABEL recovery: 
	IF error_recover(err_message, status) = "N" THEN 
		RETURN false 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		LET pr_period_num = pr_ibthead.period_num 
		LET pr_year_num = pr_ibthead.year_num 
		DECLARE c1_ibthead CURSOR FOR 
		SELECT * FROM ibthead 
		WHERE trans_num = pr_trans_num 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		FOR UPDATE 
		OPEN c1_ibthead 
		FETCH c1_ibthead INTO pr_ibthead.* 
		LET pr_ibthead.period_num = pr_period_num 
		LET pr_ibthead.year_num = pr_year_num 
		FOR cnt = 1 TO 500 
			IF pa_ibtdetl[cnt].line_num IS NULL 
			OR pa_ibtdetl[cnt].line_num = 0 THEN 
				LET cnt = cnt - 1 
				EXIT FOR 
			END IF 
		END FOR 
		## Create Prodledger Entries
		FOR i = 1 TO cnt 
			IF pa_ibtdetl[i].rec_qty = 0 THEN 
				CONTINUE FOR 
			END IF 
			SELECT * INTO pr_ibtdetl.* FROM ibtdetl 
			WHERE trans_num = pr_trans_num 
			AND line_num = pa_saveibt[i].line_num 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			INITIALIZE pr_ibtload.* TO NULL 
			SELECT * INTO pr_ibtload.* FROM ibtload 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND trans_num = pr_trans_num 
			AND line_num = pa_saveibt[i].line_num 
			INITIALIZE pr_prodledg.* TO NULL 
			LET pr_prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET pr_prodledg.part_code = pr_ibtdetl.part_code 
			LET pr_prodledg.ware_code = pr_inparms.ibt_ware_code 
			LET pr_prodledg.tran_date = pr_delivery_date 
			LET pr_prodledg.seq_num = pr_ibtdetl.line_num 
			LET pr_prodledg.trantype_ind = "T" 
			LET pr_prodledg.year_num = pr_ibthead.year_num 
			LET pr_prodledg.period_num = pr_ibthead.period_num 
			LET pr_prodledg.source_text = pr_ibthead.to_ware_code 
			LET pr_prodledg.source_num = pr_trans_num 
			LET pr_prodledg.tran_qty = pa_ibtdetl[i].rec_qty 
			LET pr_prodledg.bal_amt = 0 
			LET pr_prodledg.cost_amt = 0 
			LET pr_prodledg.sales_amt = 0 
			IF pr_inparms.hist_flag = "Y" THEN 
				LET pr_prodledg.hist_flag = "N" 
			ELSE 
				LET pr_prodledg.hist_flag = "Y" 
			END IF 
			LET pr_prodledg.post_flag = "N" 
			LET pr_prodledg.entry_code = glob_rec_kandoouser.sign_on_code 
			LET pr_prodledg.entry_date = today 
			SELECT * INTO pr_product.* FROM product 
			WHERE part_code = pr_ibtdetl.part_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			SELECT * INTO pr_category.* FROM category 
			WHERE cat_code = pr_product.cat_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			### Source Warehouse
			DECLARE c_prodstatus CURSOR FOR 
			SELECT * FROM prodstatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ware_code = pr_prodledg.ware_code 
			AND part_code = pr_prodledg.part_code 
			FOR UPDATE 
			OPEN c_prodstatus 
			FETCH c_prodstatus INTO pr_src_prodstatus.* 
			LET pr_src_prodstatus.seq_num = pr_src_prodstatus.seq_num + 1 
			IF pr_src_prodstatus.stocked_flag = "Y" THEN 
				LET pr_src_prodstatus.onhand_qty = 
				pr_src_prodstatus.onhand_qty 
				- pr_prodledg.tran_qty 
			ELSE 
				LET pr_src_prodstatus.onhand_qty = 0 
			END IF 
			LET err_message = "I59 - Product Ledger Entry" 
			INITIALIZE ps_prodledg.* TO NULL 
			LET ps_prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET ps_prodledg.part_code = pr_prodledg.part_code 
			LET ps_prodledg.ware_code = pr_prodledg.ware_code 
			LET ps_prodledg.tran_date = pr_prodledg.tran_date 
			LET ps_prodledg.seq_num = pr_src_prodstatus.seq_num 
			LET ps_prodledg.trantype_ind = "T" 
			LET ps_prodledg.year_num = pr_prodledg.year_num 
			LET ps_prodledg.period_num = pr_prodledg.period_num 
			LET ps_prodledg.source_text = pr_prodledg.source_text 
			LET ps_prodledg.source_num = pr_ibthead.trans_num 
			LET ps_prodledg.tran_qty = 0 - pr_prodledg.tran_qty 
			LET ps_prodledg.bal_amt = pr_src_prodstatus.onhand_qty 
			LET ps_prodledg.cost_amt = pr_ibtload.unit_cost_amt 
			LET ps_prodledg.sales_amt = 0 
			IF pr_inparms.hist_flag = "Y" THEN 
				LET ps_prodledg.hist_flag = "N" 
			ELSE 
				LET ps_prodledg.hist_flag = "Y" 
			END IF 
			LET ps_prodledg.post_flag = "N" 
			LET ps_prodledg.entry_code = glob_rec_kandoouser.sign_on_code 
			LET ps_prodledg.entry_date = today 
			# Both prodledg entries will contain the detination warehouse
			# adjustment account, causing the interim entries TO CLEAR
			# through the GL.  The net result IS a credit FROM the transfer
			# warehouse stock account AND a debit TO the detination warehouse
			# stock account.  Refer TO ISP FOR posting rules.
			LET ps_prodledg.acct_code = pr_category.adj_acct_code 
			SELECT acct_mask_code INTO pr_dst_mask_code FROM warehouse 
			WHERE ware_code = pr_ibthead.to_ware_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			CALL build_mask(glob_rec_kandoouser.cmpy_code, 
			pr_dst_mask_code, 
			ps_prodledg.acct_code) 
			RETURNING ps_prodledg.acct_code 
			LET err_message = "1st prodledg INSERT" 
			INSERT INTO prodledg VALUES (ps_prodledg.*) 
			LET err_message = "1st prodstat UPDATE" 
			UPDATE prodstatus 
			SET seq_num = pr_src_prodstatus.seq_num, 
			onhand_qty = pr_src_prodstatus.onhand_qty 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_prodledg.part_code 
			AND ware_code = pr_prodledg.ware_code 
			### Destination Warehouse
			DECLARE c2_prodstatus CURSOR FOR 
			SELECT * FROM prodstatus 
			WHERE prodstatus.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_prodledg.part_code 
			AND ware_code = pr_prodledg.source_text 
			FOR UPDATE 
			OPEN c2_prodstatus 
			FETCH c2_prodstatus INTO pr_dst_prodstatus.* 
			IF status = notfound THEN 
				LET pr_dst_prodstatus.* = pr_src_prodstatus.* 
				LET pr_dst_prodstatus.ware_code = pr_prodledg.source_text 
				LET pr_dst_prodstatus.onhand_qty = 0 
				LET pr_dst_prodstatus.onord_qty = 0 
				LET pr_dst_prodstatus.forward_qty = 0 
				LET pr_dst_prodstatus.reserved_qty = 0 
				LET pr_dst_prodstatus.back_qty = 0 
				LET pr_dst_prodstatus.transit_qty = 0 
				LET pr_dst_prodstatus.seq_num = 0 
				LET pr_dst_prodstatus.wgted_cost_amt = ps_prodledg.cost_amt 
				LET pr_dst_prodstatus.status_date = today 
				LET err_message = "1st prodstat INSERT" 
				INSERT INTO prodstatus VALUES (pr_dst_prodstatus.*) 
			END IF 
			CLOSE c2_prodstatus 
			IF pr_dst_prodstatus.wgted_cost_amt IS NULL THEN 
				LET pr_dst_prodstatus.wgted_cost_amt = 0 
			END IF 
			IF (pr_dst_prodstatus.onhand_qty + pr_prodledg.tran_qty) > 0 THEN 
				IF pr_dst_prodstatus.onhand_qty > 0 THEN 
					LET pr_dst_prodstatus.wgted_cost_amt = 
					( ( pr_dst_prodstatus.wgted_cost_amt 
					* pr_dst_prodstatus.onhand_qty) + 
					+ ( pr_prodledg.tran_qty * 
					pr_ibtload.unit_cost_amt)) 
					/(pr_prodledg.tran_qty+pr_dst_prodstatus.onhand_qty) 
				ELSE 
					LET pr_dst_prodstatus.wgted_cost_amt = 
					pr_ibtload.unit_cost_amt 
				END IF 
			END IF 
			LET pr_dst_prodstatus.onhand_qty = pr_dst_prodstatus.onhand_qty 
			+ pr_prodledg.tran_qty 
			LET pr_dst_prodstatus.seq_num = pr_dst_prodstatus.seq_num + 1 
			INITIALIZE ps_prodledg.* TO NULL 
			LET ps_prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET ps_prodledg.part_code = pr_prodledg.part_code 
			LET ps_prodledg.ware_code = pr_prodledg.source_text 
			LET ps_prodledg.tran_date = pr_delivery_date 
			LET ps_prodledg.seq_num = pr_dst_prodstatus.seq_num 
			LET ps_prodledg.trantype_ind = "T" 
			LET ps_prodledg.year_num = pr_prodledg.year_num 
			LET ps_prodledg.period_num = pr_prodledg.period_num 
			LET ps_prodledg.source_text = pr_prodledg.ware_code 
			LET ps_prodledg.source_num = pr_ibthead.trans_num 
			LET ps_prodledg.tran_qty = pr_prodledg.tran_qty 
			LET ps_prodledg.bal_amt = pr_dst_prodstatus.onhand_qty 
			LET ps_prodledg.cost_amt = pr_ibtload.unit_cost_amt 
			LET ps_prodledg.sales_amt = 0 
			IF pr_inparms.hist_flag = "Y" THEN 
				LET ps_prodledg.hist_flag = "N" 
			ELSE 
				LET ps_prodledg.hist_flag = "Y" 
			END IF 
			LET ps_prodledg.post_flag = "N" 
			LET ps_prodledg.entry_code = glob_rec_kandoouser.sign_on_code 
			LET ps_prodledg.entry_date = today 
			LET ps_prodledg.acct_code = pr_category.adj_acct_code 
			CALL build_mask(glob_rec_kandoouser.cmpy_code, 
			pr_dst_mask_code, 
			ps_prodledg.acct_code) 
			RETURNING ps_prodledg.acct_code 
			LET err_message = "2nd prodledg INSERT" 
			INSERT INTO prodledg VALUES (ps_prodledg.*) 
			LET err_message = "2nd prodstat UPDATE" 
			UPDATE prodstatus 
			SET seq_num = pr_dst_prodstatus.seq_num, 
			onhand_qty = pr_dst_prodstatus.onhand_qty, 
			wgted_cost_amt = pr_dst_prodstatus.wgted_cost_amt, 
			transit_qty = transit_qty - ps_prodledg.tran_qty 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_dst_prodstatus.part_code 
			AND ware_code = pr_dst_prodstatus.ware_code 
			## Update ibtdetls with rec_qty
			LET err_message = "ibtdetl UPDATE" 
			UPDATE ibtdetl 
			SET rec_qty = rec_qty + pr_prodledg.tran_qty, 
			conf_qty = conf_qty - pr_prodledg.tran_qty 
			WHERE trans_num = pr_ibthead.trans_num 
			AND line_num = pr_ibtdetl.line_num 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 

			IF pr_product.serial_flag = "Y" THEN 
				LET err_message = "I59 - serial_update " 
				LET pr_serialinfo.cmpy_code = ps_prodledg.cmpy_code 
				LET pr_serialinfo.part_code = ps_prodledg.part_code 
				LET pr_serialinfo.ware_code = ps_prodledg.ware_code 
				LET pr_serialinfo.trans_num = ps_prodledg.seq_num 
				LET pr_serialinfo.trantype_ind = "0" 
				LET status = serial_update(pr_serialinfo.*, 
				pa_ibtdetl[i].rec_qty, '') 
				IF status <> 0 THEN 
					GOTO recovery 
					EXIT program 
				END IF 
			END IF 
		END FOR 
		## Update ibthead STATUS
		SELECT count(*) INTO pr_ibtcnt FROM ibtdetl 
		WHERE (conf_qty + rec_qty) < trf_qty 
		AND status_ind <> "4" 
		AND trans_num = pr_ibthead.trans_num 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF pr_ibtcnt = 0 THEN 
			SELECT count(*) INTO pr_rec_cnt FROM ibtdetl 
			WHERE rec_qty < trf_qty 
			AND status_ind <> "4" 
			AND trans_num = pr_ibthead.trans_num 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF pr_rec_cnt = 0 THEN 
				LET pr_ibthead.status_ind = IBTHEAD_STATUS_IND_TRANSFER_COMPLETED_C 
			ELSE 
				LET pr_ibthead.status_ind = IBTHEAD_STATUS_IND_TRANSFER_PARTIALLY_COMPLETED_P 
			END IF 
		ELSE 
			SELECT count(*) INTO pr_ibtcnt FROM ibtdetl 
			WHERE (conf_qty + rec_qty) != 0 
			AND status_ind <> "4" 
			AND trans_num = pr_ibthead.trans_num 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF pr_ibtcnt = 0 THEN 
				LET pr_ibthead.status_ind = IBTHEAD_STATUS_IND_TRANSFER_UNDELIVERED_U 
			ELSE 
				LET pr_ibthead.status_ind = IBTHEAD_STATUS_IND_TRANSFER_PARTIALLY_COMPLETED_P 
			END IF 
		END IF 

		IF pr_ibthead.status_ind = IBTHEAD_STATUS_IND_TRANSFER_COMPLETED_C THEN 
			DECLARE c_ibtdetl_ser CURSOR FOR 
			SELECT * FROM ibtdetl 
			WHERE trans_num = pr_ibthead.trans_num 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			FOREACH c_ibtdetl_ser INTO pr_ibtdetl.* 
				CALL serial_delete(pr_ibtdetl.part_code, 
				pr_ibthead.from_ware_code) 
			END FOREACH 
			LET status = serial_return("","0") 
		END IF 

		SELECT rev_num INTO pr_rev_num FROM ibthead 
		WHERE trans_num = pr_trans_num 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF pr_orig_rev_num != pr_rev_num THEN 
			LET msgresp = kandoomsg("W",7026,"") 
			#7026 Another user has edited this ORDER - Changes NOT saved
			LET err_message = "I59 - Another user has modified transfer" 
			ROLLBACK WORK 
			RETURN false 
		END IF 
		UPDATE ibthead 
		SET status_ind = pr_ibthead.status_ind, 
		rev_num = rev_num + 1 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND trans_num = pr_ibthead.trans_num 
	COMMIT WORK 
	RETURN true 
END FUNCTION 
