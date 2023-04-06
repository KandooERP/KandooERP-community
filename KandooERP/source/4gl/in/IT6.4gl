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

	Source code beautified by beautify.pl on 2020-01-03 09:12:45	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 

# Purpose    : Update Stocktake stock entry data TO PRODSTATUS, PRODLEDG
#              AND produce STOCK ADJUSTMENT REPORT

GLOBALS 
	DEFINE 
	winds_text CHAR(40), 
	where_text CHAR(1200), 
	query_text CHAR(1300), 
	rpt_width LIKE rmsreps.report_width_num, 
	rpt_length LIKE rmsreps.page_length_num, 
	rpt_pageno LIKE rmsreps.page_num, 
	pr_count_over INTEGER, 
	pr_cycle_num LIKE stktake.cycle_num, 
	pr_stktake RECORD LIKE stktake.*, 
	pr_tran_rec RECORD 
		tran_date LIKE prodledg.tran_date, 
		desc_text LIKE prodledg.desc_text, 
		year_num LIKE prodledg.year_num, 
		period_num LIKE prodledg.period_num, 
		source_type LIKE prodledg.source_type,
		source_code LIKE prodadjtype.adj_type_code 
	END RECORD, 
	pr_verbose_ind SMALLINT, 
	pr_fifo_lifo_ind LIKE inparms.cost_ind 
END GLOBALS 

####################################################################
# MAIN
####################################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("IT6") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 


	LET rpt_width = 132 
	CALL fgl_winmessage("arg needs fixing","arg needs fixing","info") 
	IF num_args() > 1 THEN 
		LET glob_rec_kandoouser.cmpy_code = arg_val(2) 
	END IF 
	LET pr_verbose_ind = true 
	SELECT cost_ind INTO pr_fifo_lifo_ind 
	FROM inparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = '1' 
 
	SELECT unique 1 FROM stktake 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND status_ind = "1" 
	IF status = notfound THEN 
		LET msgresp=kandoomsg("I",7057,"") 
		#7057 No current Stock Take exist - Refer IT1
		EXIT program 
	END IF 
	IF num_args() > 0 THEN 
		LET pr_verbose_ind = 0 
		LET pr_cycle_num = arg_val(1) 
		LET query_text = "SELECT * FROM stktake ", 
		"WHERE cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
		"AND status_ind = '1' ", 
		"AND cycle_num = ",pr_cycle_num," ", 
		"ORDER BY cycle_num,start_date" 
		PREPARE s2_stktake FROM query_text 
		DECLARE c2_stktake CURSOR FOR s2_stktake 
		OPEN c2_stktake 
		FETCH c2_stktake INTO pr_stktake.* 
		CLOSE c2_stktake 
		LET pr_tran_rec.tran_date = today 
		LET pr_tran_rec.desc_text = "Stocktake Posting" 
		CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,pr_tran_rec.tran_date) 
		RETURNING pr_tran_rec.year_num, 
		pr_tran_rec.period_num 
		LET pr_tran_rec.source_code = NULL 
		CALL adjust() 
	ELSE 
		OPEN WINDOW i644 with FORM "I644" 
		 CALL windecoration_i("I644") -- albo kd-758 
		WHILE select_cycle() 
			CALL scan_cycle() 
		END WHILE 
		CLOSE WINDOW i644 
	END IF 
END MAIN 


FUNCTION select_cycle() 

	CLEAR FORM 
	LET msgresp = kandoomsg("I",1001,"") 
	#1001 Enter Selection Criteria - ESC TO Continue
	CONSTRUCT BY NAME where_text ON cycle_num, 
	desc_text, 
	start_date 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","IT6","construct-cycle_num-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	LET msgresp = kandoomsg("I",1002,"") 
	#1002 Searching database - please wait
	LET query_text = "SELECT * FROM stktake ", 
	"WHERE cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	"AND status_ind = '1' ", 
	"AND ", where_text clipped," ", 
	"ORDER BY cycle_num,start_date" 
	PREPARE s_stktake FROM query_text 
	DECLARE c_stktake CURSOR FOR s_stktake 
	RETURN true 
END FUNCTION 


FUNCTION scan_cycle() 
	DEFINE 
	pa_stktake array[400] OF RECORD 
		scroll_flag CHAR(1), 
		cycle_num LIKE stktake.cycle_num, 
		desc_text LIKE stktake.desc_text, 
		start_date LIKE stktake.start_date 
	END RECORD, 
	idx ,del_cnt SMALLINT, 
	init SMALLINT 

	LET idx = 0 
	FOREACH c_stktake INTO pr_stktake.* 
		LET idx = idx + 1 
		LET pa_stktake[idx].cycle_num = pr_stktake.cycle_num 
		LET pa_stktake[idx].desc_text = pr_stktake.desc_text 
		LET pa_stktake[idx].start_date = pr_stktake.start_date 
		IF idx = 100 THEN 
			LET msgresp = kandoomsg("U",6100,idx) 
			EXIT FOREACH 
		END IF 
	END FOREACH 
	LET msgresp = kandoomsg("U",9113,idx) 
	IF idx = 0 THEN 
	END IF 
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	CALL set_count (idx) 
	LET msgresp = kandoomsg("I",1311,"") 
	#I1311 F2 TO Delete - Enter TO Post - ESC TO continue
	INPUT ARRAY pa_stktake WITHOUT DEFAULTS FROM sr_stktake.* 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IT6","input-arr-pa_stktake-1") -- albo kd-505 
		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 
		BEFORE ROW 
			LET idx = arr_curr() 
			IF arr_curr() > arr_count() THEN 
				LET msgresp = kandoomsg("I",9001,"") 
				#I9001 No more rows in the direction you are going
			END IF 
		BEFORE FIELD desc_text 
			IF pa_stktake[idx].scroll_flag = "*" THEN 
				LET msgresp=kandoomsg("I",7055,"") 
				#7055 This file has been marked FOR deleteion - No Posting!
			ELSE 
				IF pa_stktake[idx].cycle_num IS NULL THEN 
					LET msgresp=kandoomsg("I",7058,"") 
					#7058 No current entry exist
				ELSE 
					LET pr_cycle_num = pa_stktake[idx].cycle_num 
					CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,pa_stktake[idx].start_date) 
					RETURNING pr_tran_rec.year_num, 
					pr_tran_rec.period_num 
					IF get_tran_date() THEN 
						CALL adjust() 
					END IF 
				END IF 
			END IF 
			EXIT INPUT 
		ON KEY (F2) 
			IF pa_stktake[idx].cycle_num IS NULL THEN 
				LET msgresp=kandoomsg("I",7058,"") 
				#7058 No current entry exist
			ELSE 
				IF pa_stktake[idx].scroll_flag IS NULL THEN 
					LET pa_stktake[idx].scroll_flag = "*" 
					LET del_cnt = del_cnt + 1 
				ELSE 
					LET pa_stktake[idx].scroll_flag = NULL 
					LET del_cnt = del_cnt - 1 
				END IF 
				NEXT FIELD scroll_flag 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 
		IF del_cnt > 0 THEN 
			LET msgresp = kandoomsg("I",8015,del_cnt) 
			#8009 Confirm TO Delete ",del_cnt," Cycle(s)? (Y/N)"
			IF msgresp = "Y" THEN 
				FOR idx = 1 TO arr_count() 
					IF pa_stktake[idx].scroll_flag = "*" THEN 
						BEGIN WORK 
							DELETE FROM stktakedetl 
							WHERE cycle_num = pa_stktake[idx].cycle_num 
							AND cmpy_code = glob_rec_kandoouser.cmpy_code 
							UPDATE stktake 
							SET status_ind = "2", 
							completion_date = today 
							WHERE cycle_num = pa_stktake[idx].cycle_num 
							AND cmpy_code = glob_rec_kandoouser.cmpy_code 
						COMMIT WORK 
					END IF 
				END FOR 
			END IF 
		END IF 
	END IF 
END FUNCTION 


FUNCTION get_tran_date() 
	DEFINE 
	pr_prodadjtype RECORD LIKE prodadjtype.* 

	OPEN WINDOW i645 with FORM "I645" 
	 CALL windecoration_i("I645") -- albo kd-758 
	LET msgresp=kandoomsg("I",1044,"") 
	#1044 Enter posting date details
	LET pr_tran_rec.tran_date = today 
	LET pr_tran_rec.desc_text = "Stocktake Posting" 
	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,pr_tran_rec.tran_date) 
	RETURNING pr_tran_rec.year_num, 
	pr_tran_rec.period_num 
	INPUT BY NAME pr_tran_rec.tran_date, 
	pr_tran_rec.desc_text, 
	pr_tran_rec.year_num, 
	pr_tran_rec.period_num, 
	pr_tran_rec.source_code WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IT6","input-pr_tran_rec-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD tran_date 
			IF pr_tran_rec.tran_date IS NULL THEN 
				LET pr_tran_rec.tran_date = today 
				NEXT FIELD tran_date 
			ELSE 
				CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,pr_tran_rec.tran_date) 
				RETURNING pr_tran_rec.year_num, 
				pr_tran_rec.period_num 
				DISPLAY BY NAME pr_tran_rec.period_num, 
				pr_tran_rec.year_num 

			END IF 
		AFTER FIELD year_num 
			IF pr_tran_rec.year_num IS NULL THEN 
				CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,pr_tran_rec.tran_date) 
				RETURNING pr_tran_rec.year_num, 
				pr_tran_rec.period_num 
				DISPLAY BY NAME pr_tran_rec.period_num 

				NEXT FIELD year_num 
			END IF 
		AFTER FIELD period_num 
			IF pr_tran_rec.period_num IS NULL THEN 
				CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,pr_tran_rec.tran_date) 
				RETURNING pr_tran_rec.year_num, 
				pr_tran_rec.period_num 
				DISPLAY BY NAME pr_tran_rec.period_num 

				NEXT FIELD year_num 
			END IF 
		AFTER FIELD source_code 
			IF pr_tran_rec.source_code IS NOT NULL THEN 
				SELECT * INTO pr_prodadjtype.* FROM prodadjtype 
				WHERE source_code = pr_tran_rec.source_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = notfound THEN 
					LET msgresp = kandoomsg("I",9166,"") 
					#9166 Adjustment Type Not Found - Try Window
					NEXT FIELD source_code 
				ELSE 
					LET pr_tran_rec.source_type = "PADJ" 
					DISPLAY pr_prodadjtype.desc_text, 
					pr_prodadjtype.adj_acct_code 
					TO prodadjtype.desc_text, 
					prodadjtype.adj_acct_code 

				END IF 
			ELSE 
				INITIALIZE pr_prodadjtype.* TO NULL 
				DISPLAY pr_prodadjtype.desc_text, 
				pr_prodadjtype.adj_acct_code 
				TO prodadjtype.desc_text, 
				prodadjtype.adj_acct_code 

			END IF 
		ON KEY (control-b) 
			LET winds_text = show_adj_type_code(glob_rec_kandoouser.cmpy_code) 
			IF winds_text IS NOT NULL THEN 
				LET pr_tran_rec.source_code = winds_text clipped 
				SELECT * INTO pr_prodadjtype.* FROM prodadjtype 
				WHERE source_code = pr_tran_rec.source_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				DISPLAY BY NAME pr_tran_rec.source_code 

			END IF 
			DISPLAY pr_prodadjtype.desc_text, 
			pr_prodadjtype.adj_acct_code 
			TO prodadjtype.desc_text, 
			prodadjtype.adj_acct_code 

			NEXT FIELD source_code 
		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF NOT valid_period2(glob_rec_kandoouser.cmpy_code,pr_tran_rec.year_num, 
				pr_tran_rec.period_num,TRAN_TYPE_INVOICE_IN) THEN 
					LET msgresp=kandoomsg("P",9024,"") 
					#P9024 " Accounting period IS closed OR NOT SET up "
					NEXT FIELD year_num 
				END IF 
				IF pr_tran_rec.source_code IS NOT NULL THEN 
					SELECT * INTO pr_prodadjtype.* FROM prodadjtype 
					WHERE source_code = pr_tran_rec.source_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF status = notfound THEN 
						LET msgresp = kandoomsg("I",9166,"") 
						#9166 Adjustment Type Not Found - Try Window
						NEXT FIELD source_code 
					END IF 
				END IF 
				LET pr_tran_rec.source_type = "PADJ" 
				LET msgresp=kandoomsg("I",8038,pr_cycle_num) 
				#8038 Confirm TO commence posting stocktake cycle 999 (Y/N)
				IF not(msgresp = "Y") THEN 
					NEXT FIELD tran_date 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	CLOSE WINDOW i645 
	IF int_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 


FUNCTION adjust() 
	DEFINE 
	err_message CHAR(40), 
	pr_output CHAR(60), 
	pr_mask_code LIKE warehouse.acct_mask_code, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pr_prodadjtype RECORD LIKE prodadjtype.*, 
	pr_prodledg RECORD LIKE prodledg.*, 
	pr_category RECORD LIKE category.*, 
	pr_error_cnt, 
	pr_total_count, 
	pr_count_cnt INTEGER, 
	pr_stktakedetl RECORD LIKE stktakedetl.*, 
	pr_calc_status SMALLINT, 
	pr_db_status INTEGER, 
	pr_fifo_lifo_cost LIKE prodledg.cost_amt, 
	pr_new_onhand_qty LIKE prodstatus.onhand_qty 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"IT6_rpt_list_adjust","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT IT6_rpt_list_adjust TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = 0, 
	BOTTOM MARGIN = 0, 
	LEFT MARGIN = 0, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------
	
	LET pr_total_count = 0 
	LET pr_error_cnt = 0 
	LET pr_count_cnt = 0 
	IF pr_verbose_ind THEN 
		LET msgresp=kandoomsg("I",1005,"") 
		#1005 " Updating Database Please wait
	END IF 
	SELECT total_parts_num INTO pr_total_count FROM stktake 
	WHERE cycle_num = pr_cycle_num 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code ## ar 747 

	### Preset some default/INITIALIZEd VALUES
	LET pr_prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET pr_prodledg.tran_qty =0 
	LET pr_prodledg.year_num =pr_tran_rec.year_num 
	LET pr_prodledg.period_num=pr_tran_rec.period_num 
	LET pr_prodledg.tran_date =pr_tran_rec.tran_date 
	LET pr_prodledg.desc_text =pr_tran_rec.desc_text 
	LET pr_prodledg.trantype_ind="A" 
	LET pr_prodledg.source_text="Stck.Take" 
	LET pr_prodledg.sales_amt =0 
	LET pr_prodledg.hist_flag ="N" 
	LET pr_prodledg.post_flag ="N" 
	LET pr_prodledg.jour_num =0 
	LET pr_prodledg.entry_code=glob_rec_kandoouser.sign_on_code 
	LET pr_prodledg.entry_date=today 
	LET pr_prodledg.source_num=pr_cycle_num 
	### IF an adjustment code was entered collect its details
	### AND use this TO flag the use of its account code
	INITIALIZE pr_prodadjtype.* TO NULL 
	IF pr_tran_rec.source_code IS NOT NULL THEN 
		SELECT * INTO pr_prodadjtype.* FROM prodadjtype 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND source_code = pr_tran_rec.source_code 
		IF status = notfound THEN 
			INITIALIZE pr_prodadjtype.* TO NULL 
		ELSE 
			IF pr_prodadjtype.adj_acct_code IS NULL OR 
			pr_prodadjtype.adj_acct_code = " " THEN 
				INITIALIZE pr_prodadjtype.* TO NULL 
				#        ELSE
				### Change the source text TO represent the adjustment code
				#           LET pr_prodledg.source_text = pr_prodadjtype.adj_type_code
			END IF 
		END IF 
	END IF 

	DECLARE c_stktakedetl CURSOR with HOLD FOR 
	SELECT cycle_num,part_code, ware_code, 
	sum(onhand_qty), sum(count_qty) 
	FROM stktakedetl 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cycle_num = pr_cycle_num 
	GROUP BY cycle_num,ware_code, part_code 
	ORDER BY cycle_num, ware_code, part_code 
	IF pr_verbose_ind THEN 
		--      OPEN WINDOW w1 AT 21,25 with 1 rows, 40 columns  -- albo  KD-758
		--        ATTRIBUTE(border)
		LET pr_count_cnt = 0 
		DISPLAY "of " at 1,6 
		DISPLAY pr_total_count at 1,10 
	END IF 
	FOREACH c_stktakedetl INTO pr_stktakedetl.cycle_num, 
		pr_stktakedetl.part_code, 
		pr_stktakedetl.ware_code, 
		pr_stktakedetl.onhand_qty, 
		pr_stktakedetl.count_qty 
		LET pr_count_cnt = pr_count_cnt + 1 
		IF pr_verbose_ind THEN 
			DISPLAY pr_count_cnt at 1,1 
		END IF 
		IF pr_stktakedetl.onhand_qty = pr_stktakedetl.count_qty THEN 
			DELETE FROM stktakedetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cycle_num = pr_stktakedetl.cycle_num 
			AND ware_code = pr_stktakedetl.ware_code 
			AND part_code = pr_stktakedetl.part_code 
		ELSE 
			GOTO bypass 
			LABEL recovery: 
			IF pr_verbose_ind THEN 
				IF error_recover(err_message,status) != "Y" THEN 
					EXIT FOREACH 
				END IF 
			ELSE 
				EXIT FOREACH 
			END IF 
			LABEL bypass: 
			WHENEVER ERROR GOTO recovery 
			BEGIN WORK 
				DECLARE c_prodstatus CURSOR FOR 
				SELECT * FROM prodstatus 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = pr_stktakedetl.ware_code 
				AND part_code = pr_stktakedetl.part_code 
				AND stocked_flag = "Y" 
				FOR UPDATE 
				OPEN c_prodstatus 
				FETCH c_prodstatus INTO pr_prodstatus.* 
				IF status = notfound THEN 
					LET pr_error_cnt = pr_error_cnt + 1 
					ROLLBACK WORK 
					CONTINUE FOREACH 
				END IF 
				IF pr_prodstatus.wgted_cost_amt IS NULL THEN 
					LET pr_prodstatus.wgted_cost_amt = 0 
				END IF 
				LET pr_new_onhand_qty = pr_prodstatus.onhand_qty + 
				(pr_stktakedetl.count_qty - 
				pr_stktakedetl.onhand_qty) 
				UPDATE prodstatus 
				SET seq_num = seq_num + 1, 
				onhand_qty = onhand_qty + (pr_stktakedetl.count_qty 
				- pr_stktakedetl.onhand_qty), 
				last_stcktake_date = pr_tran_rec.tran_date 
				WHERE cmpy_code = pr_prodstatus.cmpy_code 
				AND ware_code = pr_prodstatus.ware_code 
				AND part_code = pr_prodstatus.part_code 
				### Prepare the variable prodledg VALUES
				LET pr_prodledg.part_code = pr_stktakedetl.part_code 
				LET pr_prodledg.ware_code = pr_stktakedetl.ware_code 
				LET pr_prodledg.seq_num = pr_prodstatus.seq_num+1 
				LET pr_prodledg.cost_amt = pr_prodstatus.wgted_cost_amt 
				LET pr_prodledg.tran_qty = pr_stktakedetl.count_qty 
				- pr_stktakedetl.onhand_qty 
				LET pr_prodledg.bal_amt = pr_prodstatus.onhand_qty 
				+ pr_prodledg.tran_qty 
				#
				# IF FIFO/LIFO costing IS implemented, CALL the fifo/lifo cost
				# calculation using UPDATE mode TO retrieve the cost AT which
				# this adjustment will be valued WHEN the adjustment IS posted AND TO
				# adjust the cost ledger entries.  IF the adjustment IS -ve, it will be
				# treated as an issue, IF +ve it will be treated as a receipt AND
				# valued AT last actual cost.
				#
				IF pr_fifo_lifo_ind matches "[FL]" THEN 
					IF pr_prodledg.tran_qty <= 0 THEN 
						CALL fifo_lifo_issue(glob_rec_kandoouser.cmpy_code, 
						pr_prodledg.part_code, 
						pr_prodledg.ware_code, 
						pr_prodledg.tran_date, 
						pr_prodledg.seq_num, 
						pr_prodledg.trantype_ind, 
						(0 - pr_prodledg.tran_qty), 
						pr_fifo_lifo_ind, 
						true) 
						RETURNING pr_calc_status, 
						pr_db_status, 
						pr_fifo_lifo_cost 
						IF pr_calc_status = false THEN 
							LET status = pr_db_status 
							GO TO recovery 
						END IF 
						LET pr_prodledg.cost_amt = pr_fifo_lifo_cost 
					ELSE 
						LET pr_prodledg.cost_amt = pr_prodstatus.act_cost_amt 
						CALL fifo_lifo_receipt(glob_rec_kandoouser.cmpy_code, 
						pr_prodledg.part_code, 
						pr_prodledg.ware_code, 
						pr_prodledg.tran_date, 
						pr_prodledg.seq_num, 
						pr_prodledg.trantype_ind, 
						pr_prodledg.tran_qty, 
						pr_fifo_lifo_ind, 
						pr_prodledg.cost_amt) 
						RETURNING pr_calc_status, 
						pr_db_status 
						IF pr_calc_status = false THEN 
							LET status = pr_db_status 
							GO TO recovery 
						END IF 
					END IF 
				END IF 
				### Collect the account code mask FOR the current warehouse
				SELECT acct_mask_code INTO pr_mask_code 
				FROM warehouse 
				WHERE cmpy_code = pr_prodledg.cmpy_code 
				AND ware_code = pr_prodledg.ware_code 
				### IF the adjustment code was entered THEN use the adjustment
				### account code OTHERWISE use the product category account code
				IF pr_prodadjtype.adj_type_code IS NULL THEN 
					SELECT category.* INTO pr_category.* FROM product,category 
					WHERE product.cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND product.part_code = pr_stktakedetl.part_code 
					AND category.cmpy_code = product.cmpy_code 
					AND category.cat_code = product.cat_code 
					IF status = notfound THEN 
						ROLLBACK WORK 
						CONTINUE FOREACH 
					END IF 
					LET pr_prodledg.acct_code = build_mask(pr_prodledg.cmpy_code, 
					pr_mask_code, 
					pr_category.adj_acct_code) 
				ELSE 
					LET pr_prodledg.acct_code = build_mask(pr_prodledg.cmpy_code, 
					pr_mask_code, 
					pr_prodadjtype.adj_acct_code) 
				END IF 
				INSERT INTO prodledg VALUES (pr_prodledg.*)
				 
				#---------------------------------------------------------
				OUTPUT TO REPORT IT6_rpt_list_adjust(l_rpt_idx,pr_stktakedetl.ware_code, 
						pr_stktakedetl.part_code, 
						pr_stktakedetl.onhand_qty, 
						pr_stktakedetl.count_qty, 
						pr_prodledg.tran_qty, 
						pr_prodledg.cost_amt * pr_prodledg.tran_qty, 
						pr_new_onhand_qty)  
				#---------------------------------------------------------

				DELETE FROM stktakedetl 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cycle_num = pr_cycle_num 
				AND ware_code = pr_stktakedetl.ware_code 
				AND part_code = pr_stktakedetl.part_code 
			COMMIT WORK 
		END IF 
	END FOREACH 
	WHENEVER ERROR stop 
	IF pr_verbose_ind THEN 
		--      CLOSE WINDOW w1  -- albo  KD-758
	END IF 
	###-IF there are no stktakedetls FOR this cycle THEN
	###-stocktake IS completly posted
	LET pr_count_over = 0 
	SELECT count(*) INTO pr_count_over 
	FROM stktakedetl 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cycle_num = pr_cycle_num 
	IF pr_count_over = 0 THEN 
		UPDATE stktake 
		SET status_ind = "3", 
		completion_date = today 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cycle_num = pr_cycle_num 
	END IF 

	#------------------------------------------------------------
	FINISH REPORT IT6_rpt_list_adjust
	CALL rpt_finish("IT6_rpt_list_adjust")
	#------------------------------------------------------------

	IF pr_verbose_ind THEN 
		CALL run_prog("URS","","","","") -- ON ACTION "Print Manager" 
		IF pr_error_cnt > 0 THEN 
			LET msgresp=kandoomsg("I",7056,pr_error_cnt) 
			#7056 Products that did NOT UPDATE:
		END IF 
	END IF 
	LET int_flag = false 
	LET quit_flag = false 
END FUNCTION 


REPORT IT6_rpt_list_adjust(pr_ware_code, 
	pr_part_code, 
	pr_onhand,pr_count, 
	pr_adjustment,pr_cost, 
	pr_new_onhand) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	
	DEFINE 
	pr_ware_code LIKE prodstatus.ware_code, 
	pr_part_code LIKE prodstatus.part_code, 
	pr_desc_text LIKE product.desc_text, 
	pr_onhand,pr_count,pr_adjustment,pr_cost FLOAT, 
	pa_line array[4] OF CHAR(132), 
	pr_new_onhand, pr_fifo_lifo_qty LIKE prodstatus.onhand_qty, 
	pr_qty_flag CHAR(1) 

	OUTPUT 
--	top margin 0 
--	left margin 0 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			PRINT COLUMN 01, "Cycle: ",	pr_cycle_num USING "<<<<<" 
			PRINT COLUMN 01,"Period: ",pr_tran_rec.period_num USING "<<<",	COLUMN 12,"Year: ",pr_tran_rec.year_num USING "<<<<" 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		ON EVERY ROW 
			INITIALIZE pr_desc_text TO NULL 
			SELECT desc_text INTO pr_desc_text FROM product 
			WHERE part_code = pr_part_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET pr_qty_flag = NULL 
			IF pr_fifo_lifo_ind matches "[FL]" THEN 
				SELECT sum(onhand_qty) 
				INTO pr_fifo_lifo_qty 
				FROM costledg 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = pr_ware_code 
				AND part_code = pr_part_code 
				IF pr_fifo_lifo_qty IS NULL THEN 
					LET pr_fifo_lifo_qty = 0 
				END IF 
				IF pr_fifo_lifo_qty <> pr_new_onhand THEN 
					LET pr_qty_flag = '*' 
				END IF 
			END IF 
			PRINT COLUMN 1,pr_ware_code clipped, 
			COLUMN 12,pr_part_code clipped, 
			COLUMN 28,pr_desc_text, 
			COLUMN 65,pr_onhand USING "---------&.&&&&", 
			COLUMN 81,pr_count USING "---------&.&&&&", 
			COLUMN 97,pr_adjustment USING "---------&.&&&&", 
			COLUMN 113,pr_cost USING "-,---,---,--&.&&&&", 
			COLUMN 132,pr_qty_flag 
		ON LAST ROW 
			PRINT COLUMN 65, "---------------", 
			COLUMN 81, "---------------", 
			COLUMN 97, "---------------", 
			COLUMN 113,"------------------" 
			PRINT COLUMN 03,"Report Totals:", 
			COLUMN 65, sum(pr_onhand) USING "---------&.&&&&", 
			COLUMN 81, sum(pr_count) USING "---------&.&&&&", 
			COLUMN 97, sum(pr_adjustment) USING "---------&.&&&&", 
			COLUMN 113,sum(pr_cost) USING "-,---,---,--&.&&&&" 
			PRINT COLUMN 65, "---------------", 
			COLUMN 81, "---------------", 
			COLUMN 97, "---------------", 
			COLUMN 113,"------------------" 
			IF pr_count_over > 0 THEN 
				PRINT COLUMN 001, "((Stocktake cycle ", pr_cycle_num using "####", 
				" IS NOT completely posted.))" 
			END IF 
			SKIP 2 line 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	

END REPORT 

