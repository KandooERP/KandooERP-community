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
# Requires
# common/crhdwind.4gl
# common/cashwind.4gl
# common/invqwind.4gl
###########################################################################

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

###################################################################
# FUNCTION unapply_pay(p_cmpy, p_cust_code, p_invnum)
#
# FUNCTION unapp_pay allows the user TO scan the Invoice Payments
# review in more detail the various transactions
###################################################################
FUNCTION unapply_pay(p_cmpy,p_cust_code,p_invnum) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_cust_code LIKE invoicepay.cust_code 
	DEFINE p_invnum LIKE invoicepay.inv_num 
  DEFINE l_pr_wa136 SMALLINT
	DEFINE l_rec_invoicepay RECORD LIKE invoicepay.* 
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_arr_rec_invoicepay DYNAMIC ARRAY OF #array[500] OF RECORD 
		RECORD 
			appl_num LIKE invoicepay.appl_num, 
			pay_type_ind LIKE invoicepay.pay_type_ind, 
			ref_num LIKE invoicepay.ref_num, 
			apply_num LIKE invoicepay.apply_num, 
			pay_date LIKE invoicepay.pay_date, 
			pay_text LIKE invoicepay.pay_text, 
			pay_amt LIKE invoicepay.pay_amt, 
			disc_amt LIKE invoicepay.disc_amt 
		END RECORD 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_idx SMALLINT 
	DEFINE l_cnt SMALLINT 
	DEFINE l_ref_text CHAR(32) 
	DEFINE l_inv_ref1_text LIKE arparms.inv_ref1_text 
	DEFINE l_c_termdetl DATETIME year TO second 
	DEFINE l_doc_ind_text CHAR(3) 
	DEFINE l_where_text STRING 
	DEFINE l_query_text STRING 
	DEFINE l_count INTEGER 
	DEFINE l_days_num LIKE termdetl.days_num 
	DEFINE l_disc_per LIKE termdetl.disc_per 
	DEFINE l_due_date LIKE invoicehead.due_date 
	DEFINE l_disc_amt LIKE invoicehead.disc_amt 
	DEFINE l_total_amt LIKE invoicehead.total_amt 

		## Dynamic CURSOR name used b/c func.
		## does NOT assume anything about calling FUNCTION
		LET l_c_termdetl = CURRENT year TO second 

		IF l_pr_wa136 < 1 THEN # albo: it is not clear where variable l_pr_wa136 is initialized
			LET l_pr_wa136 = l_pr_wa136 + 1 
			CALL open_window( 'A136', l_pr_wa136 ) 
		ELSE 
			LET l_msgresp = kandoomsg("U",9917,"") 
			#9917 Window IS already OPEN
			RETURN FALSE 
		END IF 

		SELECT inv_ref1_text INTO l_inv_ref1_text 
		FROM arparms 
		WHERE cmpy_code = p_cmpy 
		AND parm_code = "1" 

		IF STATUS = NOTFOUND THEN 
			LET l_msgresp = kandoomsg("A",9107,"") 
			#A9107 AP Parameters NOT SET up - Refer menu AZP
			RETURN FALSE 
		END IF 

		LET l_ref_text = l_inv_ref1_text CLIPPED, "................" 

		SELECT * 
		INTO l_rec_customer.* 
		FROM customer 
		WHERE cmpy_code = p_cmpy 
		AND cust_code = p_cust_code 

		IF STATUS = NOTFOUND THEN 
			LET l_msgresp = kandoomsg("A",9067,"")	#A9067 Logic Error: Customer does NOT exist
			RETURN FALSE 
		END IF 

		SELECT * 
		INTO l_rec_invoicehead.* 
		FROM invoicehead 
		WHERE cmpy_code = p_cmpy 
		AND cust_code = p_cust_code 
		AND inv_num = p_invnum 

		IF STATUS = NOTFOUND THEN 
			LET l_msgresp = kandoomsg("A",7048,p_invnum)		#7048 Logic Error: Invoice does NOT exist
			RETURN FALSE 
		END IF 

		CASE l_rec_invoicehead.inv_ind 
			WHEN "1" 
				LET l_doc_ind_text = "A-R" 
			WHEN "2" 
				LET l_doc_ind_text = "NOR" 
			WHEN "3" 
				LET l_doc_ind_text = TRAN_TYPE_JOB_JOB 
			WHEN "4" 
				LET l_doc_ind_text = "ADJ" 
			WHEN "5" 
				LET l_doc_ind_text = "PRE" 
			OTHERWISE 
				LET l_doc_ind_text = "NOR" 
		END CASE 

		DISPLAY l_ref_text TO arparms.inv_ref1_text attribute(white) 

		DISPLAY l_doc_ind_text TO doc_ind_text 

		DISPLAY BY NAME l_rec_invoicehead.cust_code, 
			l_rec_customer.name_text, 
			l_rec_invoicehead.job_code, 
			l_rec_invoicehead.inv_num, 
			l_rec_invoicehead.inv_date, 
			l_rec_invoicehead.due_date, 
			l_rec_invoicehead.total_amt, 
			l_rec_invoicehead.paid_amt 

		DISPLAY BY NAME l_rec_customer.currency_code attribute(green) 

		DECLARE l_c_termdetl CURSOR FOR 
		SELECT days_num, disc_per 
		FROM termdetl 
		WHERE cmpy_code = p_cmpy 
		AND term_code = l_rec_invoicehead.term_code 

		LET l_idx = 0 
		FOREACH l_c_termdetl INTO l_days_num, l_disc_per 
			LET l_idx = l_idx + 1 
			LET l_due_date = l_rec_invoicehead.inv_date + l_days_num 
			LET l_disc_amt = l_rec_invoicehead.total_amt	* ( l_disc_per / 100 ) 
			LET l_total_amt = l_rec_invoicehead.total_amt - l_disc_amt 

			CASE l_idx 
				WHEN 1 
					DISPLAY 
						l_due_date USING "dd/mm/yy", 
						l_total_amt, 
						l_disc_amt 
					TO 
						due_date1, 
						total_amt1, 
						disc_amt1 

				WHEN 2 
					DISPLAY 
						l_due_date USING "dd/mm/yy", 
						l_total_amt, 
						l_disc_amt 
					TO 
						due_date2, 
						total_amt2, 
						disc_amt2 

				WHEN 3 
					DISPLAY 
						l_due_date USING "dd/mm/yy", 
						l_total_amt, 
						l_disc_amt 
					TO 
						due_date3, 
						total_amt3, 
						disc_amt3 

				OTHERWISE 
					EXIT FOREACH 
			END CASE 

		END FOREACH 

		LET l_where_text = NULL 
		SELECT count(*) INTO l_count 
		FROM invoicepay 
		WHERE cmpy_code = p_cmpy 
		AND inv_num = p_invnum 
		AND cust_code = p_cust_code 

		IF l_count > 100 THEN 
			LET l_msgresp = kandoomsg("U",1001,"")	#1001 Enter Selection Criteria; OK TO Continue.

			CONSTRUCT BY NAME l_where_text ON 
				appl_num , 
				pay_type_ind , 
				ref_num , 
				apply_num , 
				pay_date , 
				pay_text, 
				pay_amt, 
				disc_amt 

				BEFORE CONSTRUCT 
					CALL publish_toolbar("kandoo","unapp_pay","construct-invoicepay") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

			END CONSTRUCT 
			##################

			IF int_flag OR quit_flag THEN 
				LET int_flag = FALSE 
				LET quit_flag = FALSE 

				CALL close_win( 'a136', l_pr_wa136 )	RETURN FALSE 
			END IF 
		END IF 

		IF l_where_text IS NULL THEN 
			LET l_where_text = "1=1" 
		END IF 

		LET l_msgresp = kandoomsg("U",1002,"") #1002 Searching Database; Please Wait.

		LET l_query_text = 
			"SELECT invoicepay.* ", 
			" FROM invoicepay ", 
			" WHERE invoicepay.cmpy_code = '", p_cmpy, "'", 
			" AND invoicepay.inv_num = '", p_invnum, "'", 
			" AND invoicepay.cust_code = '", p_cust_code, "'", 
			" AND ", l_where_text CLIPPED, 
			" ORDER BY appl_num " 

		PREPARE ia_invoicepays FROM l_query_text 
		DECLARE ia_curs CURSOR FOR ia_invoicepays 

		LET l_idx = 0 
		FOREACH ia_curs INTO l_rec_invoicepay.* 
			LET l_idx = l_idx + 1 
			#   LET scrn = scr_line()
			LET l_arr_rec_invoicepay[l_idx].appl_num = l_rec_invoicepay.appl_num 
			LET l_arr_rec_invoicepay[l_idx].pay_type_ind = l_rec_invoicepay.pay_type_ind 
			LET l_arr_rec_invoicepay[l_idx].ref_num = l_rec_invoicepay.ref_num 
			LET l_arr_rec_invoicepay[l_idx].apply_num = l_rec_invoicepay.apply_num 
			LET l_arr_rec_invoicepay[l_idx].pay_date = l_rec_invoicepay.pay_date 
			LET l_arr_rec_invoicepay[l_idx].pay_text = l_rec_invoicepay.pay_text 
			LET l_arr_rec_invoicepay[l_idx].pay_amt = l_rec_invoicepay.pay_amt 
			LET l_arr_rec_invoicepay[l_idx].disc_amt = l_rec_invoicepay.disc_amt 

			IF l_idx = 500 THEN 
				LET l_msgresp=kandoomsg("U",1505,l_idx)	#1505 "Only first 500 rows selected.
				EXIT FOREACH 
			END IF 
		END FOREACH 

		CALL set_count(l_idx) 
		LET l_msgresp = kandoomsg("A",1054,"")	#A1054 RETURN TO View Details  - DEL TO Exit
		DISPLAY ARRAY l_arr_rec_invoicepay TO sr_invoicepay.* ATTRIBUTE(UNBUFFERED) 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","unapp_pay","display-arr-invoicepay") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON KEY (tab) 
				LET l_idx = arr_curr() 
				IF l_arr_rec_invoicepay[l_idx].pay_type_ind = TRAN_TYPE_RECEIPT_CA THEN 
					CALL cash_disp(
						p_cmpy, 
						p_cust_code, 
						l_arr_rec_invoicepay[l_idx].ref_num) 
				ELSE 
					IF l_arr_rec_invoicepay[l_idx].pay_type_ind = TRAN_TYPE_CREDIT_CR THEN 
						CALL cr_disp_head(
							p_cmpy, 
							p_cust_code, 
							l_arr_rec_invoicepay[l_idx].ref_num) 
					END IF 
				END IF 

			ON ACTION "PAYMENT" --on KEY (RETURN) 
				LET l_idx = arr_curr() 
				IF l_arr_rec_invoicepay[l_idx].pay_type_ind = TRAN_TYPE_RECEIPT_CA THEN 
					CALL cash_disp(
						p_cmpy, 
						p_cust_code, 
						l_arr_rec_invoicepay[l_idx].ref_num) 
				ELSE 
					IF l_arr_rec_invoicepay[l_idx].pay_type_ind = TRAN_TYPE_CREDIT_CR THEN 
						CALL cr_disp_head(
							p_cmpy, 
							p_cust_code, 
							l_arr_rec_invoicepay[l_idx].ref_num) 
					END IF 
				END IF 


		END DISPLAY 

		CALL close_win( 'A136', l_pr_wa136 ) 
		LET l_pr_wa136 = l_pr_wa136 - 1 
		LET int_flag = 0 
		LET quit_flag = 0 

		RETURN (l_rec_invoicehead.paid_amt) 
END FUNCTION 
###################################################################
# FUNCTION unapply_pay(p_cmpy, p_cust_code, p_invnum)
###################################################################