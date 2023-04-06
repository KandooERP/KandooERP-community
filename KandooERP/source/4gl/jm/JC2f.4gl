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

	Source code beautified by beautify.pl on 2020-01-02 19:48:21	$Id: $
}




# Purpose - JM credit note edit

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 
GLOBALS "JC2_GLOBALS.4gl" 

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
	pr_line_total_amt LIKE creditdetl.line_total_amt, 
	pr_ext_cost_amt LIKE creditdetl.ext_cost_amt, 
	pr_ship_qty LIKE creditdetl.ship_qty, 
	fv_cust_code LIKE customer.cust_code, 
	pr_total_cost LIKE credithead.cost_amt , 
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
		LET err_message = "JC2f - Customer UPDATE SELECT" 
		DECLARE curr_amts CURSOR FOR 
		SELECT * INTO pr_customer.* 
		FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = pr_credithead.cust_code 
		FOR UPDATE 
		FOREACH curr_amts 
			LET pr_customer.next_seq_num = pr_customer.next_seq_num + 1 
			LET pr_customer.bal_amt = pr_customer.bal_amt 
			+ pr_prev_head.total_amt 
			- pr_credithead.total_amt 
			LET pr_customer.curr_amt = pr_customer.curr_amt 
			+ pr_prev_head.total_amt 
			- pr_credithead.total_amt 
			# Revers audit tran
			LET pr_araudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET pr_araudit.tran_date = pr_credithead.cred_date 
			LET pr_araudit.cust_code = pr_credithead.cust_code 
			LET pr_araudit.seq_num = pr_customer.next_seq_num 
			LET pr_araudit.tran_type_ind = TRAN_TYPE_CREDIT_CR 
			LET pr_araudit.source_num = pr_credithead.cred_num 
			LET pr_araudit.tran_text = "Edit Credit" 
			LET pr_araudit.tran_amt = pr_prev_head.total_amt 
			LET pr_araudit.entry_code = glob_rec_kandoouser.sign_on_code 
			LET pr_araudit.year_num = pr_credithead.year_num 
			LET pr_araudit.period_num = pr_credithead.period_num 
			LET pr_araudit.bal_amt = pr_customer.bal_amt 
			LET pr_araudit.currency_code = pr_customer.currency_code 
			LET pr_araudit.conv_qty = pr_credithead.conv_qty 
			LET pr_araudit.entry_date = today 
			LET err_message = "JC2f - Araudit INSERT" 
			INSERT INTO araudit VALUES (pr_araudit.*) 
			LET pr_customer.next_seq_num = pr_customer.next_seq_num + 1 
			# new audittran
			LET pr_araudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET pr_araudit.tran_date = pr_credithead.cred_date 
			LET pr_araudit.cust_code = pr_credithead.cust_code 
			LET pr_araudit.seq_num = pr_customer.next_seq_num 
			LET pr_araudit.tran_type_ind = TRAN_TYPE_CREDIT_CR 
			LET pr_araudit.source_num = pr_credithead.cred_num 
			LET pr_araudit.tran_text = "Edit Credit" 
			LET pr_araudit.tran_amt = (-1 * (pr_credithead.total_amt)) 
			LET pr_araudit.entry_code = glob_rec_kandoouser.sign_on_code 
			LET pr_araudit.year_num = pr_credithead.year_num 
			LET pr_araudit.period_num = pr_credithead.period_num 
			LET pr_araudit.bal_amt = pr_customer.bal_amt 
			LET pr_araudit.currency_code = pr_customer.currency_code 
			LET pr_araudit.conv_qty = pr_credithead.conv_qty 
			LET pr_araudit.entry_date = today 
			LET err_message = "JC2f - Araudit INSERT" 
			INSERT INTO araudit VALUES (pr_araudit.*) 
			LET pr_customer.cred_bal_amt = pr_customer.cred_bal_amt 
			+ pr_prev_head.total_amt 
			- pr_credithead.total_amt 
			LET pr_customer.ytds_amt = pr_customer.ytds_amt 
			+ pr_prev_head.total_amt 
			- pr_credithead.total_amt 
			LET pr_customer.mtds_amt = pr_customer.mtds_amt 
			+ pr_prev_head.total_amt 
			- pr_credithead.total_amt 
			LET err_message = "JC2f - Customer actual UPDATE" 
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

		LET err_message = "JC2f - Past customer UPDATE" 
		LET pr_total_cost = 0 
		# now add in the credit lines
		FOR i = 1 TO arr_size 
			LET pr_creditdetl.* = ps_creditdetl[i].* 
			SELECT line_total_amt, 
			ext_cost_amt, 
			ship_qty 
			INTO pr_line_total_amt, 
			pr_ext_cost_amt, 
			pr_ship_qty 
			FROM creditdetl 
			WHERE cmpy_code = pr_creditdetl.cmpy_code 
			AND cred_num = pr_creditdetl.cred_num 
			AND line_num = pr_creditdetl.line_num 

			LET err_message = "JC2f - Update Credit Detail" 
			UPDATE creditdetl 
			SET creditdetl.* = pr_creditdetl.* 
			WHERE creditdetl.cmpy_code = pr_creditdetl.cmpy_code 
			AND creditdetl.cred_num = pr_creditdetl.cred_num 
			AND creditdetl.line_num = pr_creditdetl.line_num 

			LET check_mat = check_mat + pr_creditdetl.ext_sales_amt 

			# resbill

			LET err_message = "JC2f - Update Resbill" 
			UPDATE resbill 
			SET apply_amt = 0 - px_creditdetl[i].ext_price, 
			apply_qty = 0 - pr_creditdetl.ship_qty, 
			apply_cos_amt = 0 - pr_creditdetl.ext_cost_amt 
			WHERE cmpy_code = pr_creditdetl.cmpy_code 
			AND inv_num = pr_creditdetl.cred_num 
			AND line_num = pr_creditdetl.line_num 

			LET err_message = "JC2f - Update Activity" 

			SELECT * INTO pr_activity.* 
			FROM activity 
			WHERE cmpy_code = pr_creditdetl.cmpy_code 
			AND job_code = pr_creditdetl.job_code 
			AND var_code = pr_creditdetl.var_code 
			AND activity_code = pr_creditdetl.activity_code 

			UPDATE activity 
			SET act_bill_amt = pr_activity.act_bill_amt 
			+ pr_line_total_amt 
			- pr_creditdetl.line_total_amt, 
			post_cost_amt = pr_activity.post_cost_amt 
			+ pr_ext_cost_amt 
			- pr_creditdetl.ext_cost_amt , 
			act_bill_qty = pr_activity.act_bill_qty 
			+ pr_ship_qty 
			- pr_creditdetl.ship_qty 
			WHERE cmpy_code = pr_creditdetl.cmpy_code 
			AND job_code = pr_creditdetl.job_code 
			AND var_code = pr_creditdetl.var_code 
			AND activity_code = pr_creditdetl.activity_code 

		END FOR 

		LET err_message = "JC2f - Update Credithead" 
		SELECT sum(ext_cost_amt) 
		INTO pr_credithead.cost_amt 
		FROM creditdetl 
		WHERE creditdetl.cmpy_code = pr_credithead.cmpy_code 
		AND creditdetl.cred_num = pr_credithead.cred_num 
		AND creditdetl.cust_code = pr_credithead.cust_code 

		UPDATE credithead 
		SET credithead.* = pr_credithead.* 
		WHERE credithead.cmpy_code = pr_credithead.cmpy_code 
		AND credithead.cred_num = pr_credithead.cred_num 
		AND credithead.cust_code = pr_credithead.cust_code 
		#------------------------------
		#  Removes credit details FOR this number FROM serialinfo
		#  AND THEN rewites the information on the correct lines
		#------------------------------
		LET err_message = "JC2f - Update Serialinfo" 
		IF pr_kandoooption_sn = "Y" THEN 
			UPDATE serialinfo 
			SET credit_num = 0 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND credit_num = pr_credithead.cred_num 
			DECLARE c_serialinfo CURSOR FOR 
			SELECT * 
			FROM t_serialinfo 
			FOREACH c_serialinfo INTO pr_serialinfo.* 
				UPDATE serialinfo 
				SET credit_num = pr_credithead.cred_num, 
				cust_code = pr_customer.cust_code 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pr_serialinfo.part_code 
				AND serial_code = pr_serialinfo.serial_code 
			END FOREACH 
		END IF 

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
	"'>> ",trim(get_settings_logFile()) 
	RUN runner 
	LET runner = "echo ' Audit Check Tax :", check_tax, 
	"'>> ",trim(get_settings_logFile()) 
	RUN runner 
	LET runner = "echo ' Credit Materials :", pr_credithead.goods_amt, 
	"'>> ",trim(get_settings_logFile()) 
	RUN runner 
	LET runner = "echo ' Audit Check Materials :", check_mat, 
	"'>> ",trim(get_settings_logFile()) 
	RUN runner 
	LET msgresp = kandoomsg("J",7023,"") 
	# An Audit Check Error has Occurred - Check ", trim(get_settings_logFile())
	LET int_flag = false 
	LET quit_flag = false 

END FUNCTION 
