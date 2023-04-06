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

	Source code beautified by beautify.pl on 2020-01-02 19:48:20	$Id: $
}



# Purpose - JM credit entry

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 
GLOBALS "JC1_GLOBALS.4gl" 

DEFINE 
check_tax, 
check_mat, 
total_tax LIKE credithead.total_amt, 
count2 SMALLINT 


FUNCTION write_cred() 
	DEFINE 
	i, 
	tax_idx SMALLINT, 
	ans, 
	chkagn CHAR(1), 
	err_flag CHAR(1), 
	sel_text CHAR(200), 
	pr_araudit RECORD LIKE araudit.*, 
	pr_inparms RECORD LIKE inparms.*, 
	pr_prodledg RECORD LIKE prodledg.*, 
	fv_cust_code LIKE customer.cust_code, 
	pr_serialinfo RECORD LIKE serialinfo.* 

	INITIALIZE pr_araudit.* TO NULL 
	LET check_tax = 0 
	LET check_mat = 0 
	LET err_flag = "N" 



	SELECT * INTO pr_inparms.* 
	FROM inparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 
	GOTO bypass 

	LABEL recovery: 
	LET try_again = error_recover(err_message, status) 
	IF try_again != "Y" THEN 
		EXIT program 
	END IF 

	LABEL bypass: 
	LET noerror = 1 

	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		LET pr_credithead.cred_num = next_trans_num(glob_rec_kandoouser.cmpy_code, TRAN_TYPE_CREDIT_CR, 
		pr_credithead.acct_override_code ) 
		IF NOT (pr_credithead.cred_num > 0) THEN 
			LET err_message = "JC1f - Next Credit Number Update" 
			LET status = pr_credithead.cred_num 
			GOTO recovery 
		END IF 



























		LET err_message = "JC1f - Customer UPDATE SELECT" 
		DECLARE curr_amts CURSOR FOR 
		SELECT * INTO pr_customer.* 
		FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = pr_credithead.cust_code 
		FOR UPDATE 
		FOREACH curr_amts 
			LET pr_customer.next_seq_num = pr_customer.next_seq_num + 1 
			LET pr_customer.bal_amt = pr_customer.bal_amt - pr_credithead.total_amt 
			LET pr_customer.curr_amt = pr_customer.curr_amt - 
			pr_credithead.total_amt 
			LET pr_araudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET pr_araudit.tran_date = pr_credithead.cred_date 
			LET pr_araudit.cust_code = pr_credithead.cust_code 
			LET pr_araudit.seq_num = pr_customer.next_seq_num 
			LET pr_araudit.tran_type_ind = TRAN_TYPE_CREDIT_CR 
			LET pr_araudit.source_num = pr_credithead.cred_num 
			LET pr_araudit.tran_text = "Enter Credit" 
			LET pr_araudit.tran_amt = (-1 * (pr_credithead.total_amt)) 
			LET pr_araudit.entry_code = glob_rec_kandoouser.sign_on_code 
			LET pr_araudit.year_num = pr_credithead.year_num 
			LET pr_araudit.period_num = pr_credithead.period_num 
			LET pr_araudit.bal_amt = pr_customer.bal_amt 
			LET pr_araudit.currency_code = pr_customer.currency_code 
			LET pr_araudit.conv_qty = pr_credithead.conv_qty 
			LET pr_araudit.entry_date = today 
			LET err_message = "JC1f - Araudit INSERT" 
			INSERT INTO araudit VALUES (pr_araudit.*) 
			LET pr_customer.cred_bal_amt = pr_customer.cred_limit_amt - ( 
			pr_customer.bal_amt + 
			pr_customer.onorder_amt ) 
			LET pr_customer.ytds_amt = pr_customer.ytds_amt - pr_credithead.total_amt 
			LET pr_customer.mtds_amt = pr_customer.mtds_amt - pr_credithead.total_amt 
			LET err_message = "JC1f - Customer actual UPDATE" 
			UPDATE customer 
			SET next_seq_num = pr_customer.next_seq_num, 
			bal_amt = pr_customer.bal_amt, 
			curr_amt = pr_customer.curr_amt, 
			cred_bal_amt = pr_customer.cred_bal_amt , 
			ytds_amt = pr_customer.ytds_amt , 
			mtds_amt = pr_customer.mtds_amt 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = pr_customer.cust_code 
		END FOREACH 
		# now add in the credit lines
		FOR i = 1 TO arr_size 
			LET pr_creditdetl.* = ps_creditdetl[i].* 
			IF pr_creditdetl.cmpy_code IS NULL THEN 
				CONTINUE FOR 
			END IF 
			IF pr_creditdetl.ext_tax_amt IS NULL THEN 
				LET pr_creditdetl.ext_tax_amt = 0 
			END IF 
			IF pr_creditdetl.ext_sales_amt IS NULL THEN 
				LET pr_creditdetl.ext_sales_amt = 0 
			END IF 
			IF pr_creditdetl.job_code IS NULL THEN 
				LET pr_creditdetl.job_code = pr_invoicehead.job_code 
			END IF 
			IF pr_creditdetl.line_total_amt IS NULL 
			OR pr_creditdetl.line_total_amt = 0 THEN 
				CONTINUE FOR 
			END IF 
			LET pr_creditdetl.cred_num = pr_credithead.cred_num 
			LET pr_creditdetl.line_num = i 
			# now add the line
			LET err_message = "JC1f - Credline INSERT" 
			#UPDATE SALES HISTORY TRANS TABLE
			IF pr_credithead.org_cust_code IS NULL THEN 
				LET fv_cust_code = pr_credithead.cust_code 
			ELSE 
				LET fv_cust_code = pr_credithead.org_cust_code 
			END IF 
			CALL upd_sales_trans(glob_rec_kandoouser.cmpy_code, "C", fv_cust_code, pr_creditdetl.cat_code, 
			pr_creditdetl.part_code , pr_creditdetl.line_text, 
			pr_creditdetl.ware_code , pr_credithead.sale_code, 
			pr_credithead.acct_override_code , pr_credithead.year_num, 
			pr_credithead.period_num , pr_creditdetl.ship_qty, 
			pr_credithead.conv_qty , pr_creditdetl.ext_cost_amt, 
			pr_creditdetl.ext_sales_amt , pr_creditdetl.ext_tax_amt, 
			pr_creditdetl.disc_amt ) 

			INSERT INTO creditdetl VALUES (pr_creditdetl.*) 
			IF pr_credithead.bill_issue_ind = "1" OR 
			pr_credithead.bill_issue_ind = "3" THEN 
				LET select_text = "SELECT * FROM tempbill ", 
				"WHERE var_code = ", 
				ps_creditdetl[i].var_code, 
				" ", 
				"AND activity_code = \"", 
				pr_creditdetl.activity_code, 
				"\" " 
			ELSE 
				LET select_text = "SELECT * FROM tempbill ", 
				"WHERE var_code = ", 
				ps_creditdetl[i].var_code, 
				" ", 
				"AND activity_code = \"", 
				pr_creditdetl.activity_code, 
				"\" ", 
				"AND seq_num = ", 
				pr_creditdetl.jobledger_seq_num 
			END IF 
			PREPARE selecter 
			FROM select_text 
			DECLARE rb_curs CURSOR FOR selecter 
			FOREACH rb_curs INTO pr_tempbill.* 
				CALL write_resbill(pr_tempbill.*, pr_creditdetl.line_num) 
				#------------------
				#Update serialinfo with invoice number AND customer num
				#        Either every serialinfo RECORD FOR the goods receipt
				#        OR only those serial numbers selected IF qty differs
				#-------------------
				LET err_message = "JC1 - Update Serialinfo - Full" 
				IF pr_tempbill.trans_type_ind = "PU" 
				AND pr_tempbill.serial_flag = "Y" THEN 
					IF pr_tempbill.apply_qty = pr_tempbill.stored_qty THEN 
						UPDATE serialinfo 
						SET credit_num = pr_credithead.cred_num, 
						cust_code = pr_customer.cust_code 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND part_code = pr_tempbill.part_code 
						AND ref_num = invoice_num 
					ELSE 
						LET err_message = "JC1 - Update Serialinfo - Partial" 
						DECLARE c_temp_serial CURSOR FOR 
						SELECT * 
						FROM t_serialinfo 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND part_code = pr_tempbill.part_code 
						FOREACH c_temp_serial INTO pr_serialinfo.* 
							UPDATE serialinfo 
							SET credit_num = pr_credithead.cred_num, 
							cust_code = pr_customer.cust_code 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND part_code = pr_serialinfo.part_code 
							AND serial_code = pr_serialinfo.serial_code 
						END FOREACH 
					END IF 
				END IF 
			END FOREACH 
			LET check_mat = check_mat + pr_creditdetl.ext_sales_amt 
		END FOR 
		LET tax_idx = 1 


		WHILE (tax_idx <= 300) 
			IF ps_creditdetl[tax_idx].ext_tax_amt IS NOT NULL THEN 
				LET check_tax = check_tax + ps_creditdetl[tax_idx].ext_tax_amt 
			END IF 
			LET tax_idx = tax_idx + 1 
		END WHILE 
		IF check_tax != pr_credithead.tax_amt 
		OR check_tax IS NULL 
		OR pr_credithead.tax_amt IS NULL THEN 
			LET msgresp = kandoomsg("J",9635,"") 
			#ERROR "Audit on tax figures NOT correct"
			CALL errorlog("JC1 - tax total amount incorrect") 
			CALL display_error() 
			LET err_flag = "Y" 
			LET pr_credithead.tax_amt = check_tax 
		END IF 
		IF check_mat != pr_credithead.goods_amt 
		OR check_mat IS NULL 
		OR pr_credithead.goods_amt IS NULL THEN 
			LET msgresp = kandoomsg("J",9637,"") 
			#ERROR "Audit on material figures NOT correct"
			CALL errorlog("JC1 - material total amount incorrect") 
			CALL display_error() 
			LET err_flag = "Y" 
			LET pr_credithead.goods_amt = check_mat 
		END IF 
		LET pr_credithead.line_num = arr_size 
		LET pr_credithead.cost_ind = pr_arparms.costings_ind 
		LET pr_credithead.disc_amt = 0 
		LET pr_credithead.appl_amt = 0 


		SELECT sum(ext_cost_amt) 
		INTO pr_credithead.cost_amt 
		FROM creditdetl 
		WHERE creditdetl.cmpy_code = pr_credithead.cmpy_code 
		AND creditdetl.cred_num = pr_credithead.cred_num 


		LET err_message = "JC1f - Credhead INSERT" 
		IF NOT pv_corp_cust THEN 
			IF sav_corp_code IS NOT NULL THEN 
				LET pr_credithead.org_cust_code = sav_corp_code 
			END IF 
		END IF 
		IF pr_credithead.cust_code = pr_credithead.org_cust_code THEN 
			LET pr_credithead.org_cust_code = NULL 
		END IF 
		INSERT INTO credithead VALUES (pr_credithead.*) 
		IF err_flag = "N" THEN 
		COMMIT WORK 
	ELSE 
		ROLLBACK WORK 
		EXIT program 
	END IF 

	WHENEVER ERROR stop 
END FUNCTION 


############################################################
# FUNCTION display_error()
#
#
############################################################
FUNCTION display_error() 
	DEFINE 
	ans CHAR(1), 
	runner CHAR(120) 

	LET runner = "echo ' Error Occurred in Credit Number :", 
	pr_credithead.cred_num, "'>> ",trim(get_settings_logFile()) 
	RUN runner 
	LET runner = "echo ' Credit Tax :", pr_credithead.tax_amt, 
	"'>> ", trim(get_settings_logFile()) 
	RUN runner 
	LET runner = "echo ' Audit Check Tax :", check_tax, 
	"'>> ", trim(get_settings_logFile()) 
	RUN runner 
	LET runner = "echo ' Credit Materials :", pr_credithead.goods_amt, 
	"'>> ", trim(get_settings_logFile()) 
	RUN runner 
	LET runner = "echo ' Audit Check Materials :", check_mat, 
	"'>> ", trim(get_settings_logFile()) 
	RUN runner 
	LET msgresp = kandoomsg("J",7023,"") 
	# An Audit Check Error has Occurred - Check ", trim(get_settings_logFile())
	LET int_flag = false 
	LET quit_flag = false 
END FUNCTION 



FUNCTION write_resbill(pr_tempbill, pr_resbill_line_num) 
	DEFINE 
	pr_tempbill RECORD 
		trans_invoice_flag CHAR(1), 
		trans_date LIKE jobledger.trans_date, 
		var_code LIKE jobledger.var_code, 
		activity_code LIKE jobledger.activity_code, 
		seq_num LIKE jobledger.seq_num, 
		line_num LIKE resbill.line_num, 
		trans_type_ind LIKE jobledger.trans_type_ind, 
		trans_source_num LIKE jobledger.trans_source_num, 
		trans_source_text LIKE jobledger.trans_source_text, 
		trans_amt LIKE jobledger.trans_amt, 
		trans_qty LIKE jobledger.trans_qty, 
		charge_amt LIKE jobledger.charge_amt, 
		apply_qty LIKE resbill.apply_qty, 
		apply_amt LIKE resbill.apply_amt, 
		apply_cos_amt LIKE resbill.apply_cos_amt, 
		desc_text LIKE jobledger.desc_text, 
		prev_apply_qty LIKE resbill.apply_qty, 
		prev_apply_amt LIKE resbill.apply_amt, 
		prev_apply_cos_amt LIKE resbill.apply_cos_amt, 
		arr_line_num SMALLINT, 
		allocation_ind LIKE jobledger.allocation_ind, 
		goods_rec_num LIKE jobledger.ref_num, 
		part_code LIKE purchdetl.ref_text, 
		serial_flag LIKE product.serial_flag, 
		stored_qty LIKE resbill.apply_qty 
	END RECORD, 
	pr_resbill RECORD LIKE resbill.*, 
	pr_resbill_line_num SMALLINT 

	LET err_message = "JC1 - Insert Resbill Rows" 
	LET pr_resbill.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET pr_resbill.job_code = pr_job.job_code 
	LET pr_resbill.var_code = pr_tempbill.var_code 
	LET pr_resbill.activity_code = pr_tempbill.activity_code 
	LET pr_resbill.res_code = pr_tempbill.trans_source_text 
	LET pr_resbill.seq_num = pr_tempbill.seq_num 
	LET pr_resbill.inv_num = pr_credithead.cred_num 
	LET pr_resbill.line_num = pr_resbill_line_num 
	LET pr_resbill.apply_qty = 0 - pr_tempbill.apply_qty 
	LET pr_resbill.apply_amt = 0 - pr_tempbill.apply_amt 
	LET pr_resbill.apply_cos_amt = 0 - pr_tempbill.apply_cos_amt 
	LET pr_resbill.desc_text = pr_tempbill.desc_text 
	LET pr_resbill.tran_type_ind = "3" 

	LET pr_resbill.tran_date = pr_credithead.cred_date 
	LET pr_resbill.orig_inv_num = pr_invoicehead.inv_num 
	INSERT INTO resbill VALUES (pr_resbill.*) 
	LET err_message = "JC1 - Activity UPDATE" 
	DECLARE upd_act1 CURSOR FOR 
	SELECT activity.* 
	FROM activity 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND job_code = pr_job.job_code 
	AND var_code = pr_tempbill.var_code 
	AND activity_code = pr_tempbill.activity_code 
	FOR UPDATE 
	OPEN upd_act1 
	FETCH upd_act1 INTO pr_activity.* 
	IF pr_job.bill_way_ind = "R" THEN 
		UPDATE activity 
		SET act_bill_amt = pr_activity.act_bill_amt - pr_tempbill.apply_amt, 
		post_cost_amt = pr_activity.post_cost_amt 
		- pr_tempbill.apply_cos_amt 
		WHERE CURRENT OF upd_act1 
	ELSE 
		UPDATE activity 
		SET act_bill_amt = pr_activity.act_bill_amt - pr_tempbill.apply_amt, 
		post_cost_amt = pr_activity.post_cost_amt 
		- pr_tempbill.apply_cos_amt, 
		act_bill_qty = pr_activity.act_bill_qty - pr_tempbill.apply_qty 
		WHERE CURRENT OF upd_act1 
	END IF 
END FUNCTION 
