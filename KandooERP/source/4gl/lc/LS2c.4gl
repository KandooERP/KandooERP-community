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
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../lc/L_LC_GLOBALS.4gl"
GLOBALS "../lc/LS_GROUP_GLOBALS.4gl" 
GLOBALS "../lc/LS2_GLOBALS.4gl" 

# \brief module LS2c - Posts entries TO GL via jourintf AND updates prodstatus & product, AND creates the credit

DEFINE bal_rec RECORD 
	tran_type_ind LIKE batchdetl.tran_type_ind, 
	acct_code LIKE batchdetl.acct_code, 
	desc_text LIKE batchdetl.desc_text, 
	ref_num LIKE batchdetl.ref_num 
END RECORD 
DEFINE pr_shipdetl RECORD LIKE shipdetl.*
DEFINE pr_prodhist RECORD LIKE prodhist.*
DEFINE pr_prodledg RECORD LIKE prodledg.*
DEFINE pr_prodstatus RECORD LIKE prodstatus.*
DEFINE verif CHAR(1)
DEFINE do_update CHAR(1)
DEFINE doit CHAR(1)
DEFINE print_option CHAR(1)
DEFINE passed_desc LIKE batchdetl.desc_text 
DEFINE pos_qty DECIMAL(10,3)
DEFINE tran_qty DECIMAL(10,3)
DEFINE curr_code LIKE currency.currency_code
DEFINE tran_ind CHAR(3)
DEFINE save_1 money(12,2) 
DEFINE disc_totaller money(12,2)
DEFINE where_part STRING 
DEFINE sel_text STRING
DEFINE its_ok INTEGER
DEFINE cnt INTEGER
DEFINE mess CHAR(80) 
DEFINE total_tax MONEY 
DEFINE count2 SMALLINT 


FUNCTION write_cred() 
	DEFINE i SMALLINT
	DEFINE tax_idx SMALLINT	
	DEFINE ans CHAR(1)
	DEFINE chkagn CHAR(1)
	DEFINE err_flag CHAR(1)
	DEFINE mess_prompt string
	DEFINE pr_araudit RECORD LIKE araudit.*
	DEFINE pr_inparms RECORD LIKE inparms.*
	DEFINE pr_prodledg RECORD LIKE prodledg.* 

	INITIALIZE pr_araudit.* TO NULL 
	INITIALIZE pr_credithead.* TO NULL 
	LET check_tax = 0 
	LET check_mat = 0 
	LET err_flag = "N" 
	SELECT * INTO pr_inparms.* 
	FROM inparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 
	LET noerror = 1 

	LET pr_credithead.cred_num = 
	next_trans_num(glob_rec_kandoouser.cmpy_code, TRAN_TYPE_CREDIT_CR, pr_credithead.acct_override_code) 
	IF not(pr_credithead.cred_num > 0) THEN 
		LET err_message = "A41f - Next Credit Number Update" 
		LET status = pr_credithead.cred_num 
		LET msgresp = error_recover(err_message, status) 
		EXIT program 
	END IF 
	{Check that credit does NOT already exist}
	LET chkagn = "Y" 
	WHILE chkagn = "Y" 
		DECLARE c1 CURSOR FOR 
		SELECT 1 INTO counter 
		FROM credithead 
		WHERE cred_num = pr_credithead.cred_num 
		AND cmpy_code = pr_credithead.cmpy_code 
		OPEN c1 
		FETCH c1 
		IF status = notfound THEN 
			LET chkagn = "N" 
			EXIT WHILE 
		END IF 
		{     -- albo
		      OPEN WINDOW wrn AT 5,5 with 7 rows, 50 columns
		         attribute (border, reverse, prompt line last)

		      DISPLAY " WARNING : ", pr_credithead.cred_num, " credit number ",
		                    " has already     " AT 1,1
		      DISPLAY "           been used, do you wish TO allocate" AT 2,1
		      DISPLAY "           another number.                 " AT 3,1
		      prompt " (Y)es OR (N)o  " FOR CHAR ans
		      CLOSE WINDOW wrn
		}
		-- albo --
		LET mess_prompt = " WARNING : ", trim(pr_credithead.cred_num), " credit number "," has already", 
		"\n been used, do you wish TO allocate", 
		"\n another number?","\n ", 
		"\n (Y)es OR (N)o" 

		LET ans = promptYN("",mess_prompt,"Y") -- albo 
		----------
		IF ans matches "[Yy]" THEN 
			LET pr_credithead.cred_num = 
			next_trans_num(glob_rec_kandoouser.cmpy_code, TRAN_TYPE_CREDIT_CR, 
			pr_credithead.acct_override_code) 
		ELSE 
			EXIT program 
		END IF 
	END WHILE 
	CLOSE c1 
	LET pr_credithead.cmpy_code = pr_shiphead.cmpy_code 
	LET pr_credithead.cust_code = pr_shiphead.vend_code 
	LET pr_credithead.rma_num = NULL 
	LET pr_credithead.entry_code = glob_rec_kandoouser.sign_on_code 
	LET pr_credithead.entry_date = today 
	LET pr_credithead.cred_date = pr_shiphead.eta_curr_date 
	LET pr_credithead.sale_code = pr_shiphead.sale_code 
	LET pr_credithead.tax_code = pr_shiphead.tax_code 
	LET pr_credithead.tax_per = pr_shiphead.tax_per 
	LET pr_credithead.hand_amt = pr_shiphead.hand_amt 
	LET pr_credithead.hand_tax_code = pr_shiphead.hand_tax_code 
	LET pr_credithead.hand_tax_amt = pr_shiphead.hand_tax_amt 
	LET pr_credithead.freight_amt = pr_shiphead.freight_amt 
	LET pr_credithead.freight_tax_code = pr_shiphead.freight_tax_code 
	LET pr_credithead.freight_tax_amt = pr_shiphead.freight_tax_amt 
	LET pr_credithead.appl_amt = 0 
	LET pr_credithead.disc_amt = 0 
	LET pr_credithead.year_num = pr_shiphead.year_num 
	LET pr_credithead.period_num = pr_shiphead.period_num 
	LET pr_credithead.on_state_flag = "N" 
	LET pr_credithead.posted_flag = "N" 
	LET pr_credithead.next_num = 0 
	LET pr_credithead.line_num = 0 
	LET pr_credithead.printed_num = 1 
	LET pr_credithead.com1_text = pr_shiphead.com1_text 
	LET pr_credithead.com2_text = pr_shiphead.com2_text 
	LET pr_credithead.cost_ind = pr_arparms.costings_ind 
	LET pr_credithead.currency_code = pr_shiphead.curr_code 
	LET pr_credithead.conv_qty = pr_shiphead.conversion_qty 
	LET pr_credithead.cred_ind = "1" 
	LET pr_credithead.acct_override_code = pr_shiphead.acct_override_code 
	LET pr_credithead.goods_amt = 0 
	LET pr_credithead.tax_amt = pr_credithead.freight_tax_amt + 
	pr_credithead.hand_tax_amt 
	LET pr_credithead.total_amt = pr_credithead.freight_amt + 
	pr_credithead.freight_tax_amt + 
	pr_credithead.hand_amt + 
	pr_credithead.hand_tax_amt 
	LET pr_credithead.cost_amt = 0 
	# process lines
	DECLARE detlcurs CURSOR FOR 
	SELECT * INTO pr_shipdetl.* 
	FROM shipdetl 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ship_code = pr_shiphead.ship_code 
	#  now add in the credit lines
	LET i = 0 
	FOREACH detlcurs 
		LET i = i + 1 
		INITIALIZE pr_creditdetl.* TO NULL 
		LET pr_creditdetl.cmpy_code = pr_shipdetl.cmpy_code 
		LET pr_creditdetl.cred_num = pr_credithead.cred_num 
		LET pr_creditdetl.cust_code = pr_shiphead.vend_code 
		LET pr_creditdetl.line_num = i 
		LET pr_creditdetl.part_code =pr_shipdetl.part_code 
		LET pr_creditdetl.ware_code = pr_shiphead.ware_code 
		IF pr_shipdetl.part_code IS NOT NULL THEN 
			SELECT * INTO pr_product.* 
			FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_shipdetl.part_code 
			LET pr_creditdetl.cat_code = pr_product.cat_code 
			LET pr_creditdetl.ser_ind = pr_product.serial_flag 
			LET pr_creditdetl.uom_code = pr_product.sell_uom_code 
		ELSE 
			LET pr_creditdetl.cat_code = NULL 
			LET pr_creditdetl.ser_ind = NULL 
			LET pr_creditdetl.uom_code =null 
		END IF 
		LET pr_creditdetl.ship_qty = pr_shipdetl.ship_rec_qty 
		LET pr_creditdetl.line_text = pr_shipdetl.desc_text 
		LET pr_creditdetl.unit_cost_amt = pr_shipdetl.fob_unit_ent_amt 
		LET pr_creditdetl.ext_cost_amt = pr_creditdetl.unit_cost_amt * 
		pr_creditdetl.ship_qty 
		LET pr_creditdetl.unit_sales_amt = pr_shipdetl.landed_cost 
		LET pr_creditdetl.ext_sales_amt = pr_creditdetl.unit_sales_amt * 
		pr_creditdetl.ship_qty 
		LET pr_creditdetl.unit_tax_amt = pr_shipdetl.duty_unit_ent_amt 
		LET pr_creditdetl.ext_tax_amt = pr_creditdetl.unit_tax_amt * 
		pr_creditdetl.ship_qty 
		IF pr_creditdetl.ext_tax_amt IS NULL THEN 
			LET pr_creditdetl.ext_tax_amt = 0 
		END IF 
		IF pr_creditdetl.ext_sales_amt IS NULL THEN 
			LET pr_creditdetl.ext_sales_amt = 0 
		END IF 
		IF pr_creditdetl.line_total_amt IS NULL THEN 
			LET pr_creditdetl.line_total_amt = 0 
		END IF 
		LET pr_creditdetl.line_total_amt = pr_creditdetl.ext_sales_amt 
		+ pr_creditdetl.ext_tax_amt 
		LET pr_credithead.goods_amt = pr_credithead.goods_amt + 
		pr_creditdetl.ext_sales_amt 
		LET pr_credithead.tax_amt = pr_credithead.tax_amt + 
		pr_creditdetl.ext_tax_amt 
		LET pr_credithead.cost_amt = pr_credithead.cost_amt + 
		pr_creditdetl.ext_cost_amt 
		LET pr_credithead.total_amt = pr_credithead.total_amt 
		+ pr_creditdetl.line_total_amt 
		LET pr_creditdetl.cred_num = pr_credithead.cred_num 
		LET pr_creditdetl.line_num = i 
		LET pr_creditdetl.level_code = pr_shipdetl.level_code 
		LET pr_creditdetl.comm_amt = 0 
		LET pr_creditdetl.disc_amt = 0 
		LET pr_creditdetl.tax_code = pr_shipdetl.tax_code 
		LET pr_creditdetl.received_qty = 0 
		IF pr_creditdetl.part_code IS NULL 
		OR pr_creditdetl.ship_qty = 0 THEN 
		ELSE 
			DECLARE ps1_curs CURSOR FOR 
			SELECT * FROM prodstatus 
			WHERE part_code = pr_creditdetl.part_code 
			AND ware_code = pr_creditdetl.ware_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			FOR UPDATE 
			FOREACH ps1_curs INTO pr_prodstatus.* 
				LET pr_prodstatus.seq_num = pr_prodstatus.seq_num + 1 
				LET pr_creditdetl.seq_num = pr_prodstatus.seq_num 
				IF pr_prodstatus.onhand_qty IS NULL THEN 
					LET pr_prodstatus.onhand_qty = 0 
				END IF 
				# do NOT adjust onhnd VALUES FOR non-stocked inventory items
				IF pr_prodstatus.stocked_flag = "Y" THEN 
					LET pr_prodstatus.wgted_cost_amt = 
					((pr_prodstatus.wgted_cost_amt * pr_prodstatus.onhand_qty) + 
					(pr_creditdetl.unit_cost_amt * pr_creditdetl.ship_qty)) / 
					(pr_prodstatus.onhand_qty + pr_creditdetl.ship_qty) 
					LET pr_prodstatus.onhand_qty = pr_prodstatus.onhand_qty + 
					pr_creditdetl.ship_qty 
				END IF 
				UPDATE prodstatus 
				SET onhand_qty = pr_prodstatus.onhand_qty, 
				reserved_qty = pr_prodstatus.reserved_qty, 
				last_sale_date = pr_credithead.cred_date, 
				seq_num = pr_prodstatus.seq_num 
				WHERE CURRENT OF ps1_curs 
			END FOREACH 
			# patch up the line_acct_code
			CALL account_patch(glob_rec_kandoouser.cmpy_code, pr_shipdetl.acct_code, 
			pr_shiphead.acct_override_code) 
			RETURNING pr_creditdetl.line_acct_code 
		END IF 
		#  now add the line
		LET err_message = "A41f - Credline INSERT" 
		IF (pr_creditdetl.part_code IS NULL 
		AND pr_creditdetl.line_text IS NULL 
		AND pr_creditdetl.line_text IS NULL 
		AND (pr_creditdetl.line_total_amt = 0 OR 
		pr_creditdetl.line_total_amt IS null)) THEN 
		ELSE 
			INSERT INTO creditdetl VALUES (pr_creditdetl.*) 
		END IF 
		# now add ledger records
		IF pr_creditdetl.part_code IS NULL 
		OR pr_creditdetl.part_code = " " 
		OR pr_creditdetl.ship_qty = 0 THEN 
		ELSE 
			INITIALIZE pr_prodledg.* TO NULL 
			LET pr_prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET pr_prodledg.part_code = pr_creditdetl.part_code 
			LET pr_prodledg.ware_code = pr_creditdetl.ware_code 
			LET pr_prodledg.tran_date = pr_credithead.cred_date 
			LET pr_prodledg.seq_num = pr_creditdetl.seq_num 
			LET pr_prodledg.trantype_ind = "C" 
			LET pr_prodledg.year_num = pr_credithead.year_num 
			LET pr_prodledg.period_num = pr_credithead.period_num 
			LET pr_prodledg.source_text = pr_creditdetl.cust_code 
			LET pr_prodledg.source_num = pr_creditdetl.cred_num 
			LET pr_prodledg.tran_qty = pr_creditdetl.ship_qty 
			LET pr_prodledg.bal_amt = pr_prodstatus.onhand_qty 
			LET pr_prodledg.desc_text = "Shipment Finalise" 
			IF pr_credithead.conv_qty IS NOT NULL 
			AND pr_credithead.conv_qty != 0 THEN 
				LET pr_prodledg.cost_amt = pr_creditdetl.unit_cost_amt / 
				pr_credithead.conv_qty 
				LET pr_prodledg.sales_amt = pr_creditdetl.unit_sales_amt / 
				pr_credithead.conv_qty 
			END IF 
			IF pr_inparms.hist_flag = "Y" THEN 
				LET pr_prodledg.hist_flag = "N" 
			ELSE 
				LET pr_prodledg.hist_flag = "Y" 
			END IF 
			LET pr_prodledg.post_flag = "N" 
			LET err_message = "A41f - Itemledg INSERT" 
			INSERT INTO prodledg VALUES (pr_prodledg.*) 
		END IF 
	END FOREACH 
	LET err_message = "A41f - Customer UPDATE" 
	DECLARE curr_amts CURSOR FOR 
	SELECT * INTO pr_customer.* FROM customer 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cust_code = pr_credithead.cust_code 
	FOR UPDATE 
	FOREACH curr_amts 
		LET pr_customer.next_seq_num = pr_customer.next_seq_num + 1 
		LET pr_customer.bal_amt = pr_customer.bal_amt 
		- pr_credithead.total_amt 
		LET pr_customer.curr_amt = pr_customer.curr_amt 
		- pr_credithead.total_amt 
		LET pr_araudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pr_araudit.tran_date = pr_credithead.cred_date 
		LET pr_araudit.cust_code = pr_credithead.cust_code 
		LET pr_araudit.seq_num = pr_customer.next_seq_num 
		LET pr_araudit.tran_type_ind = TRAN_TYPE_CREDIT_CR 
		LET pr_araudit.source_num = pr_credithead.cred_num 
		LET pr_araudit.tran_text = "Shipment Credit" 
		LET pr_araudit.tran_amt = (-1*(pr_credithead.total_amt)) 
		LET pr_araudit.entry_code = glob_rec_kandoouser.sign_on_code 
		LET pr_araudit.year_num = pr_credithead.year_num 
		LET pr_araudit.period_num = pr_credithead.period_num 
		LET pr_araudit.bal_amt = pr_customer.bal_amt 
		LET pr_araudit.conv_qty = pr_credithead.conv_qty 
		LET pr_araudit.currency_code = pr_credithead.currency_code 
		LET pr_araudit.entry_date = today 
		LET err_message = "A41f - Araudit INSERT" 
		INSERT INTO araudit VALUES (pr_araudit.*) 
		LET pr_customer.cred_bal_amt = pr_customer.cred_limit_amt - 
		(pr_customer.bal_amt + pr_customer.onorder_amt) 
		LET pr_customer.ytds_amt = pr_customer.ytds_amt - pr_credithead.total_amt 
		LET pr_customer.mtds_amt = pr_customer.mtds_amt - pr_credithead.total_amt 
		LET err_message = "A41f - Customer UPDATE" 
		UPDATE customer SET next_seq_num = pr_customer.next_seq_num, 
		bal_amt = pr_customer.bal_amt, 
		curr_amt = pr_customer.curr_amt, 
		cred_bal_amt = pr_customer.cred_bal_amt, 
		ytds_amt = pr_customer.ytds_amt, 
		mtds_amt = pr_customer.mtds_amt 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = pr_customer.cust_code 
	END FOREACH 
	LET pr_credithead.line_num = i 
	LET err_message = "A41f - Credhead INSERT" 
	INSERT INTO credithead VALUES (pr_credithead.*) 

	IF err_flag = "N" THEN 
		#COMMIT WORK
	ELSE 
		ROLLBACK WORK 
		EXIT program 
	END IF 
	WHENEVER ERROR stop 
END FUNCTION 


FUNCTION summary() 

	LET err_message = " Summary Posting information " 
	# get the sum, add back in as ref_num = -1 AND ref_text = zzzcczzzc
	# THEN delete out the original

	DECLARE ps_curs CURSOR FOR 
	SELECT acct_code, tran_type_ind, sum(debit_amt - credit_amt) 
	INTO pr_data.acct_code, pr_data.tran_type_ind, pr_data.debit_amt 
	FROM posttemp 
	GROUP BY acct_code, tran_type_ind 

	FOREACH ps_curs 
		LET pr_data.ref_num = -1 
		LET pr_data.ref_text = "zzzcczzc" 
		LET pr_data.desc_text = passed_desc 
		LET pr_data.credit_amt = 0 
		IF pr_data.debit_amt < 0 THEN 
			LET pr_data.credit_amt = 0 - pr_data.debit_amt 
			LET pr_data.debit_amt = 0 
		END IF 
		INSERT INTO posttemp VALUES (pr_data.*) 
	END FOREACH 
	# now delete off detail
	DELETE FROM posttemp 
	WHERE (ref_num != -1 OR ref_num IS null) 
	AND ref_text != "zzzcczzc" 
	#now UPDATE ref_num AND ref_text on those summary left
	UPDATE posttemp 
	SET ref_num = 0, 
	ref_text = "Summary" 
END FUNCTION 


FUNCTION post_journal(p_cmpy, pr_ship_code, other_amt, final_date, period_num, year_num)
	DEFINE p_cmpy LIKE shiphead.cmpy_code
	DEFINE pr_ship_code LIKE shiphead.ship_code
	DEFINE other_amt LIKE shiphead.other_inv_amt 
	DEFINE final_date DATE
	DEFINE period_num LIKE prodledg.period_num
	DEFINE year_num LIKE prodledg.year_num 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]

	# SET glob_rec_kandoouser.sign_on_code TO LC so GL knows WHERE it came FROM
	LET glob_rec_kandoouser.sign_on_code = "LC" 
	LET its_ok = 0 
	LET all_ok = 1 
	LET rpt_wid = "132" 
	GOTO bypass 
	LABEL recovery: 
	LET try_again = error_recover(err_message,status) 
	IF try_again != "Y" THEN 
		EXIT program 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start("LCJRINTF-2","LCJRINTF_rpt_list_bdt","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT LCJRINTF_rpt_list_bdt TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	 
	LOCK TABLE prodstatus in share MODE 
	LOCK TABLE product in share MODE 
	LOCK TABLE prodledg in share MODE 
	
	LET err_message = "LS1c - Shipdetl SELECT" 
	IF pr_inparms.gl_del_flag = "N" THEN 
		LET passed_desc = "Summary Landed Cost", pr_shiphead.ship_code 
		CALL summary() 
	END IF 
	# OK now we have the temp table SET up we CALL jourintf TO
	# do its good work
	LET bal_rec.tran_type_ind = "CL" 
	# SET up balancing entry as the GL goods in transit account
	# as everything should balance......
	LET pr_data.acct_code = pr_smparms.ret_git_acct_code 
	LET bal_rec.acct_code = pr_smparms.ret_git_acct_code 
	LET bal_rec.desc_text = "Balancing entry FROM shipment finalise" 
	LET bal_rec.ref_num = pr_ship_code USING "&&&&&&&&" 
	LET sel_text = " SELECT *", 
	" FROM posttemp ", 
	" WHERE 1 =1 " 

	LET its_ok = lcjourintf(l_rpt_idx,
	sel_text, 
	p_cmpy, 
	glob_rec_kandoouser.sign_on_code, 
	bal_rec.*, 
	period_num, 
	year_num, 
	"GJ", 
	"LC", 
	pr_glparms.base_currency_code) 

	# see IF there IS a problem, IF so save
	# jourintf now returns (+/-) jour_num
	IF its_ok < 0 THEN 
		LET all_ok = 0 
	END IF 
	# now delete all FROM the table
	DELETE FROM posttemp WHERE 1=1 
	
	#------------------------------------------------------------
	FINISH REPORT LCJRINTF_rpt_list_bdt
	CALL rpt_finish("LCJRINTF_rpt_list_bdt")
	#------------------------------------------------------------

	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION