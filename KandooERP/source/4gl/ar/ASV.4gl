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
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/AS_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/ASV_GLOBALS.4gl" 
############################################################
# Module Scope Variables
############################################################
--DEFINE modu_rec_invoicedetl RECORD LIKE invoicedetl.* 
--DEFINE modu_rec_araudit RECORD LIKE araudit.* 
DEFINE modu_rec_credithead RECORD LIKE credithead.* 
DEFINE modu_rec_creditdetl RECORD LIKE creditdetl.* 
DEFINE modu_rec_cashreceipt RECORD LIKE cashreceipt.* 
DEFINE modu_sum_amt money(12,2) 
DEFINE modu_sum_cost money(12,2) 
DEFINE modu_sum_tax money(12,2) 
DEFINE modu_sum_paid money(12,2) 
DEFINE modu_sum_dist money(12,2) 
DEFINE modu_sum_app money(12,2) 
DEFINE modu_sum_cash money(12,2) 
DEFINE modu_sum_cred money(12,2) 
DEFINE modu_lab_percentage DECIMAL(5,2) 
DEFINE modu_frt_percentage DECIMAL(5,2) 
DEFINE modu_line_info CHAR(131) 
DEFINE modu_last_num INTEGER 
DEFINE modu_last_cust CHAR(8) 
DEFINE modu_cnt SMALLINT 
DEFINE modu_problem SMALLINT 
DEFINE modu_ans CHAR(1) 
##########################################################################
# FUNCTION ASV_main()
#
#
##########################################################################
FUNCTION ASV_main() 
	DEFER QUIT 
	DEFER INTERRUPT 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 
	
	CALL setModuleId("ASV") 

#	OPEN WINDOW A952 with FORM "A952" 
#	CALL windecoration_a("A952") 

	MENU " Verify A/R " 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","ASV","menu-verify-a-r") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "Verify" 			#COMMAND "Verify"   " Verify A/c Receivable"
			CALL verify() 
			CALL rpt_rmsreps_reset(NULL)

		ON ACTION "Print Manager" 			#COMMAND KEY ("P",f11) "Print"  " Print OR view using RMS"
			CALL run_prog("URS","","","","") 

		ON ACTION "Exit"			#COMMAND "Exit" " Exit TO Menu"
			EXIT MENU 

	END MENU 

#	CLOSE WINDOW A952 

END FUNCTION 


##########################################################################
# FUNCTION verify()
#
#
##########################################################################
FUNCTION verify() 
	DEFINE l_strmsg STRING 
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.*
	DEFINE l_rec_customer RECORD LIKE customer.*
	#CALL authenticate("ASV") 

	LET modu_problem = 0 

	#DISPLAY "VERIFY OF ACCOUNTS RECEIVABLE SYSTEM TAKING PLACE" AT 8,10
#	CALL displayStatus("VERIFY OF ACCOUNTS RECEIVABLE SYSTEM TAKING PLACE") 
	MESSAGE "VERIFY OF ACCOUNTS RECEIVABLE SYSTEM TAKING PLACE" 
	CALL displayStatus("Creating index on araudit") 
	MESSAGE "Creating index on araudit"
	SLEEP 2 
	CREATE INDEX xxzz249 ON araudit (cmpy_code,cust_code, 
	source_num, tran_type_ind) 


	#DISPLAY "Creating index on invoicepay" AT 10,10
	CALL displayStatus("Creating index on invoicepay") 
	MESSAGE "Creating index on invoicepay" 

	CREATE INDEX yyxx1984 ON invoicepay (cmpy_code, cust_code, 
	pay_type_ind, ref_num) 

	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	CALL displayStatus("") 

	LET modu_last_num = 0 

	########################################################################
	# check invoices
	########################################################################
	DECLARE inv_curs 
	CURSOR FOR 
	SELECT * 
	INTO l_rec_invoicehead.* 
	FROM invoicehead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND inv_num > modu_last_num 
	ORDER BY cmpy_code,inv_num 

	FOREACH inv_curs 
		#DISPLAY "" AT 10,10
		#DISPLAY "Invoice Number: " , l_rec_invoicehead.inv_num AT 10,10
		MESSAGE "Invoice Number: " , l_rec_invoicehead.inv_num 
		# check that no nulls are around

		IF l_rec_invoicehead.total_amt IS NULL 
		OR l_rec_invoicehead.tax_amt IS NULL 
		OR l_rec_invoicehead.freight_amt IS NULL 
		OR l_rec_invoicehead.cost_amt IS NULL 
		OR l_rec_invoicehead.hand_amt IS NULL 
		OR l_rec_invoicehead.disc_amt IS NULL 
		OR l_rec_invoicehead.goods_amt IS NULL 
		OR l_rec_invoicehead.paid_amt IS NULL 
		THEN 
			LET modu_line_info = "Invoice has nulls somewhere ", l_rec_invoicehead.inv_num, 
			" Invoice amt ", l_rec_invoicehead.total_amt, 
			" tax ", l_rec_invoicehead.tax_amt, 
			" frt ", l_rec_invoicehead.freight_amt, 
			" cost ", l_rec_invoicehead.cost_amt, 
			" labour ", l_rec_invoicehead.hand_amt 
			CALL prob(modu_line_info) 
			LET modu_line_info = " disc ", l_rec_invoicehead.disc_amt, 
			" goods amt ", l_rec_invoicehead.goods_amt, 
			" paid amt ", l_rec_invoicehead.paid_amt 
			CALL prob(modu_line_info) 
			OPEN inv_curs 
			IF l_rec_invoicehead.total_amt IS NULL THEN 
				LET l_rec_invoicehead.total_amt = 0 
			END IF 
			IF l_rec_invoicehead.tax_amt IS NULL THEN 
				LET l_rec_invoicehead.tax_amt = 0 
			END IF 
			IF l_rec_invoicehead.freight_amt IS NULL THEN 
				LET l_rec_invoicehead.freight_amt = 0 
			END IF 
			IF l_rec_invoicehead.cost_amt IS NULL THEN 
				LET l_rec_invoicehead.cost_amt = 0 
			END IF 
			IF l_rec_invoicehead.hand_amt IS NULL THEN 
				LET l_rec_invoicehead.hand_amt = 0 
			END IF 
			IF l_rec_invoicehead.disc_amt IS NULL THEN 
				LET l_rec_invoicehead.disc_amt = 0 
			END IF 
			IF l_rec_invoicehead.goods_amt IS NULL THEN 
				LET l_rec_invoicehead.goods_amt = 0 
			END IF 
			IF l_rec_invoicehead.paid_amt IS NULL THEN 
				LET l_rec_invoicehead.paid_amt = 0 
			END IF 
		END IF 

		# check that invoice amt = sum of all parts

		LET modu_last_num = l_rec_invoicehead.inv_num 

		IF l_rec_invoicehead.total_amt != (l_rec_invoicehead.goods_amt + 
		l_rec_invoicehead.tax_amt + 
		l_rec_invoicehead.freight_amt + 
		l_rec_invoicehead.hand_amt) 
		THEN 
			LET modu_line_info = "Invoice amount NOT equal TO bits ", 
			l_rec_invoicehead.inv_num, 
			" Header amt ", l_rec_invoicehead.total_amt 

			CALL prob(modu_line_info) 
			OPEN inv_curs 
		END IF 

		# check that line totals = invoice total

		LET modu_cnt = 0 
		SELECT sum(line_total_amt), sum(ext_tax_amt), sum(ext_cost_amt), 
		count(*) 
		INTO modu_sum_amt, modu_sum_tax, modu_sum_cost, modu_cnt 
		FROM invoicedetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = l_rec_invoicehead.cust_code 
		AND inv_num = l_rec_invoicehead.inv_num 

		IF modu_sum_amt IS NULL THEN 
			IF modu_cnt > 0 THEN 
				LET modu_line_info = "Invoice Number ", l_rec_invoicehead.inv_num, 
				" has a NULL line total amount" 
				CALL prob(modu_line_info) 
				OPEN inv_curs 
			END IF 
			LET modu_sum_amt = 0 
		END IF 

		IF modu_sum_tax IS NULL THEN 
			IF modu_cnt > 0 THEN 
				LET modu_line_info = "Invoice Number ", l_rec_invoicehead.inv_num, 
				" has a NULL line tax amount" 
				CALL prob(modu_line_info) 
				OPEN inv_curs 
			END IF 
			LET modu_sum_tax = 0 
		END IF 

		IF modu_sum_cost IS NULL THEN 
			IF modu_cnt > 0 THEN 
				LET modu_line_info = "Invoice Number ", l_rec_invoicehead.inv_num, 
				" has a NULL line cost amount" 
				CALL prob(modu_line_info) 
				OPEN inv_curs 
			END IF 
			LET modu_sum_cost = 0 
		END IF 

		IF modu_sum_amt != (l_rec_invoicehead.total_amt - l_rec_invoicehead.hand_amt - 
		l_rec_invoicehead.freight_amt - l_rec_invoicehead.hand_tax_amt - 
		l_rec_invoicehead.freight_tax_amt) 
		THEN 
			LET modu_line_info = "Invoice Line amount NOT equal TO header ", 
			l_rec_invoicehead.inv_num, 
			" Header amt ", l_rec_invoicehead.total_amt, 
			" Line amt " ,modu_sum_amt 
			CALL prob(modu_line_info) 
			OPEN inv_curs 
		END IF 

		# check that tax lines = invoice header tax

		# in CASE there IS tax on handling OR freight do calculations

		SELECT tax_per 
		INTO modu_frt_percentage 
		FROM tax 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND tax_code = l_rec_invoicehead.freight_tax_code 

		SELECT tax_per 
		INTO modu_lab_percentage 
		FROM tax 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND tax_code = l_rec_invoicehead.hand_tax_code 

		LET modu_sum_tax = modu_sum_tax + 
		(((l_rec_invoicehead.hand_amt * modu_lab_percentage) + 
		(l_rec_invoicehead.freight_amt * modu_frt_percentage)) / 100) 

		IF modu_sum_tax != l_rec_invoicehead.tax_amt 
		THEN 
			LET modu_line_info = "Invoice Line tax NOT equal TO header ", 
			l_rec_invoicehead.inv_num, 
			" Header amt ", l_rec_invoicehead.tax_amt, 
			" Line amt " ,modu_sum_tax 
			CALL prob(modu_line_info) 
			OPEN inv_curs 
		END IF 

		# check that invoice lines costs = invoice header cost

		IF modu_sum_cost != l_rec_invoicehead.cost_amt 
		THEN 
			LET modu_line_info = "Invoice Line cost NOT equal TO header ", 
			l_rec_invoicehead.inv_num, 
			" Header amt ", l_rec_invoicehead.cost_amt, 
			" Line amt " ,modu_sum_cost 
			CALL prob(modu_line_info) 
			OPEN inv_curs 
		END IF 

		# check that daily log file correct
		# note that sum takes care of edit situations

		LET modu_cnt = 0 
		SELECT sum(tran_amt), count(*) 
		INTO modu_sum_amt, modu_cnt 
		FROM araudit 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = l_rec_invoicehead.cust_code 
		AND tran_type_ind = TRAN_TYPE_INVOICE_IN 
		AND source_num = l_rec_invoicehead.inv_num 

		IF modu_sum_amt IS NULL THEN 
			IF modu_cnt > 0 THEN 
				LET modu_line_info = "Invoice Number ", l_rec_invoicehead.inv_num, 
				" has a NULL log amount" 
				CALL prob(modu_line_info) 
				OPEN inv_curs 
			END IF 
			LET modu_sum_amt = 0 
		END IF 

		IF modu_sum_amt != l_rec_invoicehead.total_amt 
		THEN 
			LET modu_line_info = "Invoice Amount NOT equal TO daily log ", 
			l_rec_invoicehead.inv_num, 
			" Header amt ", l_rec_invoicehead.total_amt, 
			" Log amt " ,modu_sum_amt 
			CALL prob(modu_line_info) 
			OPEN inv_curs 
		END IF 

		# check that applied amount IS correct

		LET modu_cnt = 0 
		SELECT sum(pay_amt), count(*) 
		INTO modu_sum_amt, modu_cnt 
		FROM invoicepay 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = l_rec_invoicehead.cust_code 
		AND inv_num = l_rec_invoicehead.inv_num 

		IF modu_sum_amt IS NULL THEN 
			IF modu_cnt > 0 THEN 
				LET modu_line_info = "Invoice Number ", l_rec_invoicehead.inv_num, 
				" has a NULL invoice payment" 
				CALL prob(modu_line_info) 
				OPEN inv_curs 
			END IF 
			LET modu_sum_amt = 0 
		END IF 

		IF modu_sum_amt != l_rec_invoicehead.paid_amt 
		THEN 
			LET modu_line_info = "Invoice Paid NOT equal TO inv payments ", 
			l_rec_invoicehead.inv_num, 
			" Invoice Paid amt ", l_rec_invoicehead.paid_amt, 
			" Inv Payments " ,modu_sum_amt 
			CALL prob(modu_line_info) 
			OPEN inv_curs 
		END IF 

	END FOREACH 

	########################################################################
	# Now check the credits
	########################################################################
	LET modu_last_num = 0 

	DECLARE cred_curs 
	CURSOR FOR 
	SELECT * 
	INTO modu_rec_credithead.* 
	FROM credithead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cred_num > modu_last_num 
	ORDER BY cmpy_code, cred_num 

	FOREACH cred_curs 
		DISPLAY "" at 10,10 
		DISPLAY "Credit Number: " , modu_rec_credithead.cred_num at 10,10 

		# check that no nulls are around

		IF modu_rec_credithead.total_amt IS NULL 
		OR modu_rec_credithead.tax_amt IS NULL 
		OR modu_rec_credithead.freight_amt IS NULL 
		OR modu_rec_credithead.cost_amt IS NULL 
		OR modu_rec_credithead.hand_amt IS NULL 
		OR modu_rec_credithead.goods_amt IS NULL 
		OR modu_rec_credithead.disc_amt IS NULL 
		OR modu_rec_credithead.appl_amt IS NULL 
		THEN 
			LET modu_line_info = "Credit has nulls somewhere ", 
			modu_rec_credithead.cred_num, 
			" Credit amt ", modu_rec_credithead.total_amt, 
			" tax ", modu_rec_credithead.tax_amt, 
			" frt ", modu_rec_credithead.freight_amt, 
			" cost ", modu_rec_credithead.cost_amt, 
			" labour ", modu_rec_credithead.hand_amt 
			CALL prob(modu_line_info) 
			LET modu_line_info = " goods amt ", modu_rec_credithead.goods_amt, 
			" disc ", modu_rec_credithead.disc_amt, 
			" applied amt ", modu_rec_credithead.appl_amt 
			CALL prob(modu_line_info) 
			OPEN cred_curs 
			IF modu_rec_credithead.total_amt IS NULL THEN 
				LET modu_rec_credithead.total_amt = 0 
			END IF 
			IF modu_rec_credithead.tax_amt IS NULL THEN 
				LET modu_rec_credithead.tax_amt = 0 
			END IF 
			IF modu_rec_credithead.freight_amt IS NULL THEN 
				LET modu_rec_credithead.freight_amt = 0 
			END IF 
			IF modu_rec_credithead.cost_amt IS NULL THEN 
				LET modu_rec_credithead.cost_amt = 0 
			END IF 
			IF modu_rec_credithead.hand_amt IS NULL THEN 
				LET modu_rec_credithead.hand_amt = 0 
			END IF 
			IF modu_rec_credithead.goods_amt IS NULL THEN 
				LET modu_rec_credithead.goods_amt = 0 
			END IF 
			IF modu_rec_credithead.disc_amt IS NULL THEN 
				LET modu_rec_credithead.disc_amt = 0 
			END IF 
			IF modu_rec_credithead.appl_amt IS NULL THEN 
				LET modu_rec_credithead.appl_amt = 0 
			END IF 
		END IF 

		LET modu_last_num = modu_rec_credithead.cred_num 
		# check that invoice amt = sum of all parts

		IF modu_rec_credithead.total_amt != (modu_rec_credithead.goods_amt + 
		modu_rec_credithead.tax_amt + 
		modu_rec_credithead.freight_amt + 
		modu_rec_credithead.hand_amt) 
		THEN 
			LET modu_line_info = "Credit amount NOT equal TO bits ", 
			modu_rec_credithead.cred_num, 
			" Header amt ", modu_rec_credithead.total_amt 
			CALL prob(modu_line_info) 
			OPEN cred_curs 
		END IF 

		# check that line totals = credits total

		LET modu_cnt = 0 
		SELECT sum(line_total_amt),sum(ext_tax_amt),sum(ext_cost_amt), 
		count(*) 
		INTO modu_sum_amt,modu_sum_tax,modu_sum_cost,modu_cnt 
		FROM creditdetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = modu_rec_credithead.cust_code 
		AND cred_num = modu_rec_credithead.cred_num 

		IF modu_sum_amt IS NULL THEN 
			IF modu_cnt > 0 THEN 
				LET modu_line_info = "Credit Number ", modu_rec_credithead.cred_num, 
				" has a NULL line total amount" 
				CALL prob(modu_line_info) 
				OPEN cred_curs 
			END IF 
			LET modu_sum_amt = 0 
		END IF 

		IF modu_sum_tax IS NULL THEN 
			IF modu_cnt > 0 THEN 
				LET modu_line_info = "Credit Number ", modu_rec_credithead.cred_num, 
				" has a NULL line tax amount" 
				CALL prob(modu_line_info) 
				OPEN cred_curs 
			END IF 
			LET modu_sum_tax = 0 
		END IF 

		IF modu_sum_cost IS NULL THEN 
			IF modu_cnt > 0 THEN 
				LET modu_line_info = "Credit Number ", modu_rec_credithead.cred_num, 
				" has a NULL line cost amount" 
				CALL prob(modu_line_info) 
				OPEN cred_curs 
			END IF 
			LET modu_sum_cost = 0 
		END IF 

		IF modu_sum_amt != (modu_rec_credithead.total_amt - modu_rec_credithead.freight_amt - 
		modu_rec_credithead.freight_tax_amt - modu_rec_credithead.hand_amt - 
		modu_rec_credithead.hand_tax_amt) 
		THEN 
			LET modu_line_info = "Credit Line amount NOT equal TO header ", 
			modu_rec_credithead.cred_num, 
			" Header amt ", modu_rec_credithead.total_amt, 
			" Line amt " ,modu_sum_amt 
			CALL prob(modu_line_info) 
			OPEN cred_curs 
		END IF 

		# check that tax lines = credit header tax

		IF modu_sum_tax != (modu_rec_credithead.tax_amt - modu_rec_credithead.freight_tax_amt - 
		modu_rec_credithead.hand_tax_amt) 
		THEN 
			LET modu_line_info = "Credit Line tax NOT equal TO header ", 
			modu_rec_credithead.cred_num, 
			" Header amt ", modu_rec_credithead.tax_amt, 
			" Line amt " ,modu_sum_tax 
			CALL prob(modu_line_info) 
			OPEN cred_curs 
		END IF 

		# check that credit lines costs = credit header cost


		IF modu_sum_cost != modu_rec_credithead.cost_amt 
		THEN 
			LET modu_line_info = "Credit Line cost NOT equal TO header ", 
			modu_rec_credithead.cred_num, 
			" Header amt ", modu_rec_credithead.cost_amt, 
			" Line amt " ,modu_sum_cost 
			CALL prob(modu_line_info) 
			OPEN cred_curs 
		END IF 

		# check that daily log file correct
		# note that sum takes care of edit situations

		LET modu_cnt = 0 
		SELECT sum(tran_amt), count(*) 
		INTO modu_sum_amt, modu_cnt 
		FROM araudit 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = modu_rec_credithead.cust_code 
		AND tran_type_ind = TRAN_TYPE_CREDIT_CR 
		AND source_num = modu_rec_credithead.cred_num 

		IF modu_sum_amt IS NULL THEN 
			IF modu_cnt > 0 THEN 
				LET modu_line_info = "Credit Number ", modu_rec_credithead.cred_num, 
				" has a NULL log amount" 
				CALL prob(modu_line_info) 
				OPEN cred_curs 
			END IF 
			LET modu_sum_amt = 0 
		END IF 

		IF modu_sum_amt != (0 - modu_rec_credithead.total_amt) 
		THEN 
			LET modu_line_info = "Credit Amount NOT equal TO daily log ", 
			modu_rec_credithead.cred_num, 
			" Header amt ", modu_rec_credithead.total_amt, 
			" Log amt " ,modu_sum_amt 
			CALL prob(modu_line_info) 
			OPEN cred_curs 
		END IF 

		# check that applied amount IS correct

		LET modu_cnt = 0 
		SELECT sum(pay_amt), count(*) 
		INTO modu_sum_amt, modu_cnt 
		FROM invoicepay 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = modu_rec_credithead.cust_code 
		AND pay_type_ind = TRAN_TYPE_CREDIT_CR 
		AND ref_num = modu_rec_credithead.cred_num 

		IF modu_sum_amt IS NULL THEN 
			IF modu_cnt > 0 THEN 
				LET modu_line_info = "Credit Number ", modu_rec_credithead.cred_num, 
				" has a NULL invoice payment" 
				CALL prob(modu_line_info) 
				OPEN cred_curs 
			END IF 
			LET modu_sum_amt = 0 
		END IF 

		IF modu_sum_amt != modu_rec_credithead.appl_amt 
		THEN 
			LET modu_line_info = "Credit Paid NOT equal TO inv payments ", 
			modu_rec_credithead.cred_num, 
			" Credit Paid amt ", modu_rec_credithead.appl_amt, 
			" Inv Payments " ,modu_sum_amt 
			CALL prob(modu_line_info) 
			OPEN cred_curs 
		END IF 

	END FOREACH 

	########################################################################
	# Now check the cashreceipts
	########################################################################
	LET modu_last_num = 0 

	DECLARE cash_curs 
	CURSOR FOR 
	SELECT * 
	INTO modu_rec_cashreceipt.* 
	FROM cashreceipt 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cash_num > modu_last_num 
	ORDER BY cmpy_code, cash_num 

	FOREACH cash_curs 
		DISPLAY "" at 10,10 
		DISPLAY "Cash Receipt Number: " , modu_rec_cashreceipt.cash_num at 10,10 

		IF modu_rec_cashreceipt.cash_amt IS NULL 
		OR modu_rec_cashreceipt.applied_amt IS NULL 
		OR modu_rec_cashreceipt.disc_amt IS NULL 
		THEN 
			LET modu_line_info = "Cashreceipt has nulls somewhere ", 
			modu_rec_cashreceipt.cash_num, 
			" Cash amt ", modu_rec_cashreceipt.cash_amt, 
			" applied amt ", modu_rec_cashreceipt.applied_amt, 
			" disc ", modu_rec_cashreceipt.disc_amt 
			CALL prob(modu_line_info) 
			OPEN cash_curs 
			IF modu_rec_cashreceipt.cash_amt IS NULL THEN 
				LET modu_rec_cashreceipt.cash_amt = 0 
			END IF 
			IF modu_rec_cashreceipt.applied_amt IS NULL THEN 
				LET modu_rec_cashreceipt.applied_amt = 0 
			END IF 
			IF modu_rec_cashreceipt.disc_amt IS NULL THEN 
				LET modu_rec_cashreceipt.disc_amt = 0 
			END IF 
		END IF 

		LET modu_last_num = modu_rec_cashreceipt.cash_num 

		# check that daily log file correct
		# note that sum takes care of edit situations

		LET modu_cnt = 0 
		SELECT sum(tran_amt), count(*) 
		INTO modu_sum_amt, modu_cnt 
		FROM araudit 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = modu_rec_cashreceipt.cust_code 
		AND tran_type_ind = TRAN_TYPE_RECEIPT_CA 
		AND source_num = modu_rec_cashreceipt.cash_num 

		IF modu_sum_amt IS NULL THEN 
			IF modu_cnt > 0 THEN 
				LET modu_line_info = "Cashreceipt Number ", modu_rec_cashreceipt.cash_num, 
				" has a NULL log amount" 
				CALL prob(modu_line_info) 
				OPEN cash_curs 
			END IF 
			LET modu_sum_amt = 0 
		END IF 

		IF modu_sum_amt != (0 - modu_rec_cashreceipt.cash_amt) 
		THEN 
			LET modu_line_info = "Cash Amount NOT equal TO daily log ", 
			modu_rec_cashreceipt.cash_num, 
			" Header amt ", modu_rec_cashreceipt.cash_amt, 
			" Log amt " ,modu_sum_amt 
			CALL prob(modu_line_info) 
			OPEN cash_curs 
		END IF 

		# check that applied amount IS correct

		LET modu_cnt = 0 
		SELECT sum(pay_amt), count(*) 
		INTO modu_sum_amt, modu_cnt 
		FROM invoicepay 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = modu_rec_cashreceipt.cust_code 
		AND pay_type_ind = TRAN_TYPE_RECEIPT_CA 
		AND ref_num = modu_rec_cashreceipt.cash_num 

		IF modu_sum_amt IS NULL THEN 
			IF modu_cnt > 0 THEN 
				LET modu_line_info = "Cashreceipt Number ", modu_rec_cashreceipt.cash_num, 
				" has a NULL invoice payment" 
				CALL prob(modu_line_info) 
				OPEN cash_curs 
			END IF 
			LET modu_sum_amt = 0 
		END IF 

		IF modu_sum_amt != modu_rec_cashreceipt.applied_amt 
		THEN 
			LET modu_line_info = "Cash Paid NOT equal TO inv payments ", 
			modu_rec_cashreceipt.cash_num, 
			" Cash Paid amt ", modu_rec_cashreceipt.applied_amt, 
			" Inv Payments " ,modu_sum_amt 
			CALL prob(modu_line_info) 
			OPEN cash_curs 
		END IF 

	END FOREACH 

	########################################################################
	# Now check the customer balance IS OK
	########################################################################

	LET modu_last_cust = " " 
	DECLARE cust_curs 
	CURSOR FOR 
	SELECT * 
	INTO l_rec_customer.* 
	FROM customer 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cust_code > modu_last_cust 
	ORDER BY cmpy_code, cust_code 

	FOREACH cust_curs 

		#DISPLAY "Customer: " , l_rec_customer.name_text at 10,10 

		IF l_rec_customer.bal_amt IS NULL 
		THEN 
			LET modu_line_info = "Customer ", l_rec_customer.cust_code, 
			" has a NULL balance amount" 
			CALL prob(modu_line_info) 
			OPEN cust_curs 
			LET l_rec_customer.bal_amt = 0 
		END IF 

		LET modu_last_cust = l_rec_customer.cust_code 

		# get the sum of the invoices outstanding

		SELECT sum(total_amt), sum(paid_amt) 
		INTO modu_sum_amt , modu_sum_paid, modu_cnt 
		FROM invoicehead 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = l_rec_customer.cust_code 
		AND total_amt != paid_amt 

		IF modu_sum_amt IS NULL THEN 
			LET modu_sum_amt = 0 
		END IF 
		IF modu_sum_paid IS NULL THEN 
			LET modu_sum_paid = 0 
		END IF 

		# now get the sum of the credits outstanding

		SELECT sum(total_amt), sum(appl_amt) 
		INTO modu_sum_cred, modu_sum_dist, modu_cnt 
		FROM credithead 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = l_rec_customer.cust_code 
		AND total_amt != appl_amt 

		IF modu_sum_cred IS NULL THEN 
			LET modu_sum_cred = 0 
		END IF 
		IF modu_sum_dist IS NULL THEN 
			LET modu_sum_dist = 0 
		END IF 

		# now get the sum of the cash outstanding

		SELECT sum(cash_amt), sum(applied_amt) 
		INTO modu_sum_cash, modu_sum_app, modu_cnt 
		FROM cashreceipt 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = l_rec_customer.cust_code 
		AND cash_amt != applied_amt 

		IF modu_sum_cash IS NULL THEN 
			LET modu_sum_cash = 0 
		END IF 
		IF modu_sum_app IS NULL THEN 
			LET modu_sum_app = 0 
		END IF 

		LET modu_sum_amt = (modu_sum_amt - modu_sum_paid) 
		- ((modu_sum_cred - modu_sum_dist) 
		+ (modu_sum_cash - modu_sum_app)) 
		IF l_rec_customer.bal_amt != modu_sum_amt 
		THEN 
			LET modu_line_info = "Client bal NOT equal TO parts- run aging ", 
			l_rec_customer.cust_code, 
			" Cust bal ", l_rec_customer.bal_amt, 
			" Parts amt " ,modu_sum_amt 
			CALL prob(modu_line_info) 
			OPEN cust_curs 
		END IF 

		# now get the sum of the cash outstanding

		SELECT bal_amt 
		INTO modu_sum_amt 
		FROM araudit 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = l_rec_customer.cust_code 
		AND seq_num = (SELECT max(seq_num) 
		FROM araudit 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = l_rec_customer.cust_code) 

		IF modu_sum_amt IS NULL THEN 
			LET modu_line_info = "Araudit has a NULL balance amount FOR ", 
			" customer ", l_rec_customer.cust_code 
			CALL prob(modu_line_info) 
			OPEN cust_curs 
			LET modu_sum_amt = 0 
		END IF 

		IF l_rec_customer.bal_amt != modu_sum_amt 
		THEN 
			LET modu_line_info = "Client bal NOT equal TO latest araudit ", 
			l_rec_customer.cust_code, 
			" Cust bal ", l_rec_customer.bal_amt, 
			" Ledger amt " ,modu_sum_amt 
			CALL prob(modu_line_info) 
			OPEN cust_curs 
		END IF 

	END FOREACH 

	CLEAR screen 

	IF modu_problem = 1 
	THEN 
		#------------------------------------------------------------
		FINISH REPORT ASV_rpt_list_ver
		CALL rpt_finish("ASV_rpt_list_ver")
		#------------------------------------------------------------
	
	  		
		#LET l_strmsg = glob_rec_rmsreps.file_text, "\nDatabase verified - Problems exist" 
		LET l_strmsg = "\nDatabase verified - Problems exist"
		CALL displaystatus(l_strmsg) 
		CALL fgl_winmessage("Database verified",l_strmsg,"warning") 
		#DISPLAY " DATABASE VERIFIED - PROBLEMS EXIST" AT 16,10
		#attribute (magenta)
		#sleep 15
	ELSE
		#LET l_strmsg = glob_rec_rmsreps.file_text, "\nDatabase verified - All Ok"  
		LET l_strmsg = "\nDatabase verified - All Ok" 
		CALL displaystatus(l_strmsg) 
		CALL fgl_winmessage("Database verified",l_strmsg,"info") 

		#DISPLAY " DATABASE VERIFIED - ALL OK" AT 16,10
		#attribute (magenta)
		#sleep 15
	END IF 

	DROP INDEX xxzz249 

	DROP INDEX yyxx1984 
	
END FUNCTION 



##########################################################################
# FUNCTION prob(p_line1)
#
#
##########################################################################
FUNCTION prob(p_line1) 
	DEFINE p_line1 CHAR(132) 
	DEFINE l_rpt_idx SMALLINT 	

	CALL displayStatus("Problems Found - Check Report") 
	#DISPLAY "Problems Found - Check Report " AT 15,10
	ERROR "Problems Found - Check Report" 
	IF modu_problem = 0 
	THEN 
		LET modu_problem = 1 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
--	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
--		LET int_flag = false 
--		LET quit_flag = false
--
--		RETURN FALSE
--	END IF
	
		LET l_rpt_idx = rpt_start(getmoduleid(),"ASV_rpt_list_ver","N/A", RPT_SHOW_RMS_DIALOG)
		IF l_rpt_idx = 0 THEN #User pressed CANCEL
			RETURN FALSE
		END IF	
		START REPORT ASV_rpt_list_ver TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
--	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
		#------------------------------------------------------------
			
			 
	END IF 
	
		#---------------------------------------------------------
		OUTPUT TO REPORT ASV_rpt_list_ver(l_rpt_idx,p_line1)  
		#---------------------------------------------------------
	
END FUNCTION 


##########################################################################
# REPORT ASV_rpt_list_ver(p_line_info)
#
#
##########################################################################
REPORT ASV_rpt_list_ver(p_rpt_idx,p_line_info)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	 
	DEFINE p_line_info CHAR(131) 

	DEFINE l_rpt_note CHAR(30)
	DEFINE l_offset1 SMALLINT
	DEFINE l_offset2 SMALLINT
	DEFINE l_line1 CHAR(80)
	DEFINE l_line2 CHAR(80) 

	OUTPUT 
	left margin 0 

	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			
		ON EVERY ROW 
			PRINT COLUMN 1, p_line_info 
		ON LAST ROW 
			SKIP 1 line 
			PRINT COLUMN 20, "Total Problems: ", count(*) USING "###" 
			SKIP 1 line 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
			
END REPORT 