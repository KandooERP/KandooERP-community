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

	Source code beautified by beautify.pl on 2020-01-03 14:28:52	$Id: $
}



#Program GSC allows the user TO check subsidiary vs GL accounts


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 

GLOBALS 
END GLOBALS 

############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_conv_qty LIKE invoicehead.conv_qty 
DEFINE modu_ans CHAR(1) 
DEFINE modu_period_numb SMALLINT
DEFINE modu_year_numb SMALLINT
DEFINE modu_line_item_tot money(16,2)
DEFINE modu_posted_amt money(16,2)
DEFINE modu_totaller1 money(16,2) 
DEFINE modu_totaller2 money(16,2) 
DEFINE modu_totaller3 money(16,2) 
DEFINE modu_totaller4 money(16,2) 

############################################################
# MAIN
#
#
############################################################
MAIN 
	DEFINE l_msgresp LIKE language.yes_flag 

	CALL setModuleId("GSC") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 


	OPEN WINDOW wg165 with FORM "G165" 
	CALL windecoration_g("G165") 

	LET modu_ans = "Y" 
	WHILE modu_ans = "Y" 
		CALL query() 
	END WHILE 
END MAIN 



############################################################
# FUNCTION query()
#
#
############################################################
FUNCTION query() 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_msgresp = kandoomsg("G",1082,"") 

	# 1082 Enter Reconcilaition Details;  OK TO Continue.
	INPUT modu_year_numb, modu_period_numb WITHOUT DEFAULTS 
	FROM year_numb, period_numb 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GSC","inp-period") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		EXIT PROGRAM 
	END IF 

	# Accounts Receivable
	LET l_msgresp = kandoomsg("U",1002,"") 
	#1002 Searching Database;  Please Wait.
	SELECT sum(total_amt / conv_qty) 
	INTO modu_totaller1 
	FROM invoicehead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND period_num = modu_period_numb 
	AND year_num = modu_year_numb 
	AND posted_flag = "Y" 

	IF modu_totaller1 IS NULL THEN 
		LET modu_totaller1 = 0 
	END IF 
	LET modu_posted_amt = modu_totaller1 

	DISPLAY modu_totaller1 TO sc_sub[1].modu_totaller1 


	#now get all including NOT posted
	SELECT sum(total_amt / conv_qty) 
	INTO modu_totaller1 
	FROM invoicehead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND period_num = modu_period_numb 
	AND year_num = modu_year_numb 

	LET modu_totaller3 = 0 
	DECLARE inv_line_curs CURSOR FOR 
	SELECT conv_qty, sum(line_total_amt) 
	INTO modu_conv_qty, modu_line_item_tot 
	FROM invoicehead, invoicedetl 
	WHERE invoicedetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND invoicehead.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND period_num = modu_period_numb 
	AND year_num = modu_year_numb 
	AND line_total_amt < 0 
	AND invoicehead.inv_num = invoicedetl.inv_num 
	AND invoicehead.cust_code = invoicedetl.cust_code 
	GROUP BY conv_qty 

	FOREACH inv_line_curs 
		IF modu_line_item_tot IS NOT NULL THEN 
			LET modu_totaller3 = modu_totaller3 + (modu_line_item_tot / modu_conv_qty) 
		END IF 
	END FOREACH 

	DISPLAY modu_totaller3 TO sc_sub[1].modu_totaller3 


	LET modu_totaller2 = modu_totaller1 - modu_totaller3 

	DISPLAY modu_totaller2 TO sc_sub[1].modu_totaller2 


	LET modu_totaller4 = modu_totaller2 + modu_totaller3 

	DISPLAY modu_totaller4 TO sc_sub[1].modu_totaller4 


	SELECT sum(total_amt / conv_qty) 
	INTO modu_totaller1 
	FROM credithead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND period_num = modu_period_numb 
	AND year_num = modu_year_numb 
	AND posted_flag = "Y" 

	IF modu_totaller1 IS NULL THEN 
		LET modu_totaller1 = 0 
	END IF 

	LET modu_posted_amt = modu_totaller1 
	DISPLAY modu_totaller1 TO sc_sub[2].modu_totaller1 


	SELECT sum(total_amt / conv_qty) 
	INTO modu_totaller2 
	FROM credithead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND period_num = modu_period_numb 
	AND year_num = modu_year_numb 

	LET modu_totaller3 = 0 
	DECLARE cred_line_curs CURSOR FOR 
	SELECT conv_qty, sum(line_total_amt) 
	INTO modu_conv_qty, modu_line_item_tot 
	FROM credithead, creditdetl 
	WHERE creditdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND credithead.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND period_num = modu_period_numb 
	AND year_num = modu_year_numb 
	AND line_total_amt < 0 
	AND credithead.cred_num = creditdetl.cred_num 
	AND credithead.cust_code = creditdetl.cust_code 
	GROUP BY conv_qty 

	FOREACH cred_line_curs 
		IF modu_line_item_tot IS NOT NULL THEN 
			LET modu_totaller3 = modu_totaller3 + (modu_line_item_tot / modu_conv_qty) 
		END IF 
	END FOREACH 

	DISPLAY modu_totaller3 TO sc_sub[2].modu_totaller3 


	LET modu_totaller2 = modu_totaller1 - modu_totaller3 

	DISPLAY modu_totaller2 TO sc_sub[2].modu_totaller2 


	LET modu_totaller4 = modu_totaller2 + modu_totaller3 

	DISPLAY modu_totaller4 TO sc_sub[2].modu_totaller4 

	SELECT sum(cash_amt / conv_qty) 
	INTO modu_totaller1 
	FROM cashreceipt 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND period_num = modu_period_numb 
	AND year_num = modu_year_numb 
	AND posted_flag = "Y" 

	IF modu_totaller1 IS NULL THEN 
		LET modu_totaller1 = 0 
	END IF 

	LET modu_posted_amt = modu_totaller1 

	DISPLAY modu_totaller1 TO sc_sub[3].modu_totaller1 


	SELECT sum(cash_amt / conv_qty) 
	INTO modu_totaller3 
	FROM cashreceipt 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND period_num = modu_period_numb 
	AND year_num = modu_year_numb 
	AND cash_amt < 0 

	IF modu_totaller3 IS NULL THEN LET modu_totaller3 = 0 END IF 

		DISPLAY modu_totaller3 TO sc_sub[3].modu_totaller3 

		SELECT sum(cash_amt / conv_qty) 
		INTO modu_totaller2 
		FROM cashreceipt 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND period_num = modu_period_numb 
		AND year_num = modu_year_numb 
		AND cash_amt > 0 

		IF modu_totaller2 IS NULL THEN 
			LET modu_totaller2 = 0 
		END IF 

		DISPLAY modu_totaller2 TO sc_sub[3].modu_totaller2 


		LET modu_totaller4 = modu_totaller2 + modu_totaller3 

		DISPLAY modu_totaller4 TO sc_sub[3].modu_totaller4 


		# Accounts Payable

		SELECT sum(total_amt / conv_qty) 
		INTO modu_totaller1 
		FROM voucher 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND period_num = modu_period_numb 
		AND year_num = modu_year_numb 
		AND post_flag = "Y" 

		IF modu_totaller1 IS NULL THEN 
			LET modu_totaller1 = 0 
		END IF 

		LET modu_posted_amt = modu_totaller1 

		DISPLAY modu_totaller1 TO sc_sub[4].modu_totaller1 


		SELECT sum(total_amt / conv_qty) 
		INTO modu_totaller1 
		FROM voucher 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND period_num = modu_period_numb 
		AND year_num = modu_year_numb 

		LET modu_totaller3 = 0 
		DECLARE vdist_curs CURSOR FOR 
		SELECT conv_qty, sum(voucherdist.dist_amt) 
		INTO modu_conv_qty, modu_line_item_tot 
		FROM voucher, voucherdist 
		WHERE voucherdist.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND voucher.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND period_num = modu_period_numb 
		AND year_num = modu_year_numb 
		AND voucherdist.dist_amt < 0 
		AND voucher.vouch_code = voucherdist.vouch_code 
		AND voucher.vend_code = voucherdist.vend_code 
		GROUP BY conv_qty 

		FOREACH vdist_curs 
			IF modu_line_item_tot IS NOT NULL THEN 
				LET modu_totaller3 = modu_totaller3 + (modu_line_item_tot / modu_conv_qty) 
			END IF 
		END FOREACH 

		DISPLAY modu_totaller3 TO sc_sub[4].modu_totaller3 


		LET modu_totaller2 = modu_totaller1 - modu_totaller3 

		DISPLAY modu_totaller2 TO sc_sub[4].modu_totaller2 


		LET modu_totaller4 = modu_totaller2 + modu_totaller3 

		DISPLAY modu_totaller4 TO sc_sub[4].modu_totaller4 


		SELECT sum(total_amt / conv_qty) 
		INTO modu_totaller1 
		FROM debithead 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND period_num = modu_period_numb 
		AND year_num = modu_year_numb 
		AND post_flag = "Y" 

		IF modu_totaller1 IS NULL THEN 
			LET modu_totaller1 = 0 
		END IF 

		LET modu_posted_amt = modu_totaller1 

		DISPLAY modu_totaller1 TO sc_sub[5].modu_totaller1 

		SELECT sum(total_amt / conv_qty) 
		INTO modu_totaller2 
		FROM debithead 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND period_num = modu_period_numb 
		AND year_num = modu_year_numb 

		LET modu_totaller3 = 0 
		DECLARE ddist_curs CURSOR FOR 
		SELECT conv_qty, sum(debitdist.dist_amt) 
		INTO modu_conv_qty, modu_line_item_tot 
		FROM debithead, debitdist 
		WHERE debitdist.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND debithead.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND period_num = modu_period_numb 
		AND year_num = modu_year_numb 
		AND debitdist.dist_amt < 0 
		AND debithead.debit_num = debitdist.debit_code 
		AND debithead.vend_code = debitdist.vend_code 
		GROUP BY conv_qty 

		FOREACH ddist_curs 
			IF modu_line_item_tot IS NOT NULL THEN 
				LET modu_totaller3 = modu_totaller3 + (modu_line_item_tot / modu_conv_qty) 
			END IF 
		END FOREACH 

		DISPLAY modu_totaller3 TO sc_sub[5].modu_totaller3 


		LET modu_totaller2 = modu_totaller1 - modu_totaller3 

		DISPLAY modu_totaller2 TO sc_sub[5].modu_totaller2 


		LET modu_totaller4 = modu_totaller2 + modu_totaller3 

		DISPLAY modu_totaller4 TO sc_sub[5].modu_totaller4 


		SELECT sum(net_pay_amt / conv_qty) 
		INTO modu_totaller1 
		FROM cheque 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND period_num = modu_period_numb 
		AND year_num = modu_year_numb 
		AND post_flag = "Y" 

		IF modu_totaller1 IS NULL THEN 
			LET modu_totaller1 = 0 
		END IF 

		DISPLAY modu_totaller1 TO sc_sub[6].modu_totaller1 

		SELECT sum(net_pay_amt / conv_qty) 
		INTO modu_totaller3 
		FROM cheque 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND period_num = modu_period_numb 
		AND year_num = modu_year_numb 
		AND net_pay_amt < 0 

		IF modu_totaller3 IS NULL THEN 
			LET modu_totaller3 = 0 
		END IF 

		DISPLAY modu_totaller3 TO sc_sub[6].modu_totaller3 


		SELECT sum(net_pay_amt / conv_qty) 
		INTO modu_totaller2 
		FROM cheque 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND period_num = modu_period_numb 
		AND year_num = modu_year_numb 
		AND net_pay_amt > 0 

		IF modu_totaller2 IS NULL THEN 
			LET modu_totaller2 = 0 
		END IF 

		DISPLAY modu_totaller2 TO sc_sub[6].modu_totaller2 


		LET modu_totaller4 = modu_totaller2 + modu_totaller3 

		DISPLAY modu_totaller4 TO sc_sub[6].modu_totaller4 

		RETURN 
END FUNCTION