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
# \file
# \brief module GCEb - European Cash Book Entry & Reconciliation
#                Look up windows FOR cheques,bank deposits
#                transfers...etc.  All functions are mutally exclusive
#                AND are only called FROM control-b main SCREEN array.
#                All functions RETURN the same number of variables except
#                show_type which lists the hardcoded transaction types.
#
#   FUNCTION show_type.
#
#   All FUNCTION below RETURN the following VALUES
#        doc_num INTEGER ## unique number identifying row selected
#        tran_date date  ## date of transaction on row selected
#        ref_code        ## Any reference information abount row selected
#        dr_tran_amt     ## Amount of debit transaction (zero FOR credit trans)
#        cr_tran_amt     ## Amount of credit transaction(zero FOR debit trans)
#
#   FUNCTION show_dischq() returns cashreceipt.cash_num,
#                                  cashreceipt.chq_date,
#                                  cashreceipt.banked_date,
#                                  cashreceipt.cheque_text,
#                                  zero
#                                  cashreceipt.cash_amt
#
#   FUNCTION show_cust()
#
#   FUNCTION show_cheq()
#
#   FUNCTION show_eft()
#
#   FUNCTION show_vend_voucher() ->  #note, this was show_vend() ??? duplicated function name
#
#   FUNCTION show_bdep()
#
#   FUNCTION split(doc_num, bk_cnt)
#
#   FUNCTION show_transfers() ## Tranfers OUT?IN
#
#   FUNCTION show_eft_for_rej()
#
###########################################################################

###########################################################################
# Requires
# common/cacdwind.4gl
###########################################################################

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl"
GLOBALS "../gl/GC_GROUP_GLOBALS.4gl" 
GLOBALS "../gl/GCE_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################

###########################################################################
# FUNCTION show_type()
#
#
###########################################################################
FUNCTION show_type() 
	DEFINE l_type LIKE bankstatement.entry_type_code 
	DEFINE l_arr_rec_type array[11] OF RECORD 
		entry_type_code LIKE bankstatement.entry_type_code, 
		desc_text char(21), 
		cr_dr char(2) 
	END RECORD 
	DEFINE l_i INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_arr_rec_type[1].entry_type_code = "BC" 
	LET l_arr_rec_type[1].desc_text = "Bank charges" 
	LET l_arr_rec_type[1].cr_dr = "DR" 
	LET l_arr_rec_type[2].entry_type_code = "BD" 
	LET l_arr_rec_type[2].desc_text = "Bank deposits" 
	LET l_arr_rec_type[2].cr_dr = TRAN_TYPE_CREDIT_CR 
	LET l_arr_rec_type[3].entry_type_code = "CH" 
	LET l_arr_rec_type[3].desc_text = "Cheque payments" 
	LET l_arr_rec_type[3].cr_dr = "DR" 
	LET l_arr_rec_type[4].entry_type_code = "PA" 
	LET l_arr_rec_type[4].desc_text = "Payments" 
	LET l_arr_rec_type[4].cr_dr = "DR" 
	LET l_arr_rec_type[5].entry_type_code = "RE" 
	LET l_arr_rec_type[5].desc_text = "Receipts" 
	LET l_arr_rec_type[5].cr_dr = TRAN_TYPE_CREDIT_CR 
	LET l_arr_rec_type[6].entry_type_code = "SC" 
	LET l_arr_rec_type[6].desc_text = "Sundry credits" 
	LET l_arr_rec_type[6].cr_dr = TRAN_TYPE_CREDIT_CR 
	LET l_arr_rec_type[7].entry_type_code = "TI" 
	LET l_arr_rec_type[7].desc_text = "Currency Transfer in" 
	LET l_arr_rec_type[7].cr_dr = TRAN_TYPE_CREDIT_CR 
	LET l_arr_rec_type[8].entry_type_code = "TO" 
	LET l_arr_rec_type[8].desc_text = "Currency Transfer out" 
	LET l_arr_rec_type[8].cr_dr = "DR" 
	LET l_arr_rec_type[9].entry_type_code = "DC" 
	LET l_arr_rec_type[9].desc_text = "Dishonoured cheques" 
	LET l_arr_rec_type[9].cr_dr = "DR" 
	LET l_arr_rec_type[10].entry_type_code = "EF" 
	LET l_arr_rec_type[10].desc_text = "Direct Entry (eft's)" 
	LET l_arr_rec_type[10].cr_dr = "DR" 
	LET l_arr_rec_type[11].entry_type_code = "ER" 
	LET l_arr_rec_type[11].desc_text = "Rejected Direct entry" 
	LET l_arr_rec_type[11].cr_dr = TRAN_TYPE_CREDIT_CR 

	OPEN WINDOW g417 with FORM "G417" 
	CALL windecoration_g("G417") 

	LET l_msgresp = kandoomsg("G",1080,"") 
	CALL set_count(11) 

	OPTIONS DELETE KEY f36, 
	INSERT KEY f36 

	INPUT ARRAY l_arr_rec_type WITHOUT DEFAULTS FROM sr_type.* attributes(unbuffered) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GCEb","inp-arr-type") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE FIELD entry_type_code 
			LET l_i = arr_curr() 
			LET l_type = l_arr_rec_type[l_i].entry_type_code 
			DISPLAY l_arr_rec_type[l_i].* TO sr_type[l_i].* 

		AFTER FIELD entry_type_code 
			LET l_arr_rec_type[l_i].entry_type_code = l_type 
			DISPLAY l_arr_rec_type[l_i].* TO sr_type[l_i].* 

		BEFORE FIELD desc_text 
			EXIT INPUT 
			#      ON KEY (control-w)
			#         CALL kandoohelp("")
	END INPUT 

	CLOSE WINDOW g417 
	LET int_flag = false 
	LET quit_flag = false 

	RETURN l_type 
END FUNCTION 


############################################################
# FUNCTION show_dischq()
#
#
############################################################
FUNCTION show_dischq() 
	DEFINE l_rec_cashreceipt RECORD LIKE cashreceipt.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_arr_rec_cashreceipt DYNAMIC ARRAY OF RECORD -- array[100] OF RECORD 
		cheque_text LIKE cashreceipt.cheque_text, 
		cash_amt LIKE cashreceipt.cash_amt, 
		cust_code LIKE cashreceipt.cust_code, 
		name_text LIKE customer.name_text, 
		cash_num LIKE cashreceipt.cash_num, 
		banked_date LIKE cashreceipt.banked_date 
	END RECORD 
	DEFINE l_where_text char(300) 
	DEFINE l_query_text char(900) 
	DEFINE l_idx SMALLINT #, scrn 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW g449 with FORM "G449" 
	CALL windecoration_g("G449") 

	WHILE true 
		CLEAR FORM 
		LET l_msgresp=kandoomsg("G",1001,"") 
		#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT l_where_text ON cashreceipt.cheque_text, 
		cashreceipt.cash_amt, 
		cashreceipt.cust_code, 
		customer.name_text, 
		cashreceipt.cash_num, 
		cashreceipt.banked_date 
		FROM cashreceipt.cheque_text, 
		cashreceipt.cash_amt, 
		cashreceipt.cust_code, 
		customer.name_text, 
		cashreceipt.cash_num, 
		cashreceipt.banked_date 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","GCEb","construct-cashreceipt") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET l_idx = 1 
			--INITIALIZE l_arr_rec_cashreceipt[1].* TO NULL 
			LET int_flag = false 
			LET quit_flag = false 
			EXIT WHILE 
		ELSE 
			LET l_msgresp=kandoomsg("G",1002,"") 		#1002 " Searching database - please wait "
		END IF 
		IF glob_rec_bank.currency_code != glob_rec_glparms.base_currency_code THEN 
			LET l_where_text = l_where_text clipped, 
			" AND cashreceipt.currency_code='",glob_rec_bank.currency_code,"'" 
		END IF 
		LET l_query_text = 
		"SELECT cashreceipt.*,", 
		"customer.name_text ", 
		"FROM cashreceipt,customer ", 
		"WHERE cashreceipt.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND customer.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND cashreceipt.cust_code = customer.cust_code ", 
		"AND cashreceipt.cash_acct_code = '",glob_rec_bank.acct_code,"' ", 
		"AND cashreceipt.banked_date IS NOT NULL ", 
		"AND cashreceipt.cash_amt > 0 ", 
		"AND job_code IS NULL ", 
		"AND cashreceipt.cash_num NOT in (SELECT doc_num FROM t_bkstate ", 
		" WHERE entry_type_code = 'DC' )", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY cashreceipt.banked_date desc ,", 
		"cashreceipt.cash_num" 
		PREPARE s_cashreceipt FROM l_query_text 
		DECLARE c_cashreceipt CURSOR FOR s_cashreceipt 
		LET l_idx = 0 
		FOREACH c_cashreceipt INTO l_rec_cashreceipt.*, 
			l_rec_customer.name_text 
			LET l_idx = l_idx + 1 
			LET l_arr_rec_cashreceipt[l_idx].cheque_text = l_rec_cashreceipt.cheque_text 
			LET l_arr_rec_cashreceipt[l_idx].cash_amt = l_rec_cashreceipt.cash_amt 
			LET l_arr_rec_cashreceipt[l_idx].cust_code = l_rec_cashreceipt.cust_code 
			LET l_arr_rec_cashreceipt[l_idx].name_text = l_rec_customer.name_text 
			LET l_arr_rec_cashreceipt[l_idx].cash_num = l_rec_cashreceipt.cash_num 
			LET l_arr_rec_cashreceipt[l_idx].banked_date = l_rec_cashreceipt.banked_date 
			IF l_idx = 100 THEN 
				LET l_msgresp = kandoomsg("G",9186,l_idx) 
				#9186 " First 100 entries selected only"
				EXIT FOREACH 
			END IF 
		END FOREACH 

		FREE s_cashreceipt 
		IF l_idx = 0 THEN 
			LET l_msgresp=kandoomsg("G",9516,l_idx) 
			#G9516 " No entries satisfied selection criteria
			CONTINUE WHILE 
		END IF 
		CALL set_count(l_idx) 
		LET l_msgresp=kandoomsg("G",1009,"") 

		#G1009 " ESC TO SELECT - RETURN FOR Line Information "
		INPUT ARRAY l_arr_rec_cashreceipt WITHOUT DEFAULTS FROM sr_cashreceipt.* attributes(unbuffered) 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","GCEb","inp-arr-cashreceipt") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 


			BEFORE ROW 
				LET l_idx = arr_curr() 
				#LET scrn = scr_line()
				LET l_rec_cashreceipt.cheque_text = l_arr_rec_cashreceipt[l_idx].cheque_text 
				IF l_idx <= arr_count() THEN 
					#DISPLAY l_arr_rec_cashreceipt[l_idx].* TO sr_cashreceipt[scrn].*

				ELSE 
					LET l_msgresp=kandoomsg("G",9001,"") 
				END IF 

			AFTER FIELD cheque_text 
				LET l_arr_rec_cashreceipt[l_idx].cheque_text = l_rec_cashreceipt.cheque_text 
				IF l_rec_cashreceipt.cheque_text IS NOT NULL THEN 
					#DISPLAY l_arr_rec_cashreceipt[l_idx].cheque_text
					#     TO sr_cashreceipt[scrn].cheque_text

				END IF 

			BEFORE FIELD cash_amt 
				IF l_arr_rec_cashreceipt[l_idx].cash_num > 0 THEN 
					CALL disp_cash_app(glob_rec_kandoouser.cmpy_code, l_arr_rec_cashreceipt[l_idx].cust_code, 
					l_arr_rec_cashreceipt[l_idx].cash_num) 
				END IF 
				NEXT FIELD cheque_text 

			AFTER ROW 
				#DISPLAY l_arr_rec_cashreceipt[l_idx].* TO sr_cashreceipt[scrn].*

			AFTER INPUT 
				LET l_idx = arr_curr() 
--			ON KEY (control-w) 
--				CALL kandoohelp("") 
		END INPUT
		 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			EXIT WHILE 
		END IF 
		CLEAR FORM
		 
	END WHILE
	 
	CLOSE WINDOW g449 
	OPTIONS INSERT KEY f1, 
	DELETE KEY f2 
	
	RETURN l_arr_rec_cashreceipt[l_idx].cash_num, 
	l_arr_rec_cashreceipt[l_idx].banked_date, 
	l_arr_rec_cashreceipt[l_idx].cheque_text, 
	l_arr_rec_cashreceipt[l_idx].cash_amt,"" 
END FUNCTION 


############################################################
# FUNCTION show_cust()
#
#
############################################################
FUNCTION show_cust() 
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_corpcust RECORD LIKE customer.* 
	DEFINE l_arr_rec_invoice DYNAMIC ARRAY OF RECORD --array[100] OF RECORD 
		invoice_num LIKE invoicehead.inv_num, 
		inv_date LIKE invoicehead.inv_date, 
		cust_code LIKE invoicehead.cust_code, 
		name_text LIKE customer.name_text, 
		paid_amt LIKE invoicehead.paid_amt, 
		currency_code LIKE invoicehead.currency_code, 
		paid_ind char(1) 
	END RECORD 
	DEFINE l_prev_app_amt LIKE bankdetails.tran_amt 
	DEFINE l_prev_app_disc LIKE bankdetails.disc_amt 
	DEFINE l_where_text char(300) 
	DEFINE l_query_text char(700) 
	DEFINE l_idx SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	WHENEVER ERROR CONTINUE 
	OPTIONS DELETE KEY f36, 
	INSERT KEY f36 
	WHENEVER ERROR stop 

	OPEN WINDOW g405 with FORM "G405" 
	CALL windecoration_g("G405") 

	WHILE true 
		CLEAR FORM 
		LET l_idx = 1 
		--INITIALIZE l_arr_rec_invoice[1].* TO NULL 
		LET l_msgresp=kandoomsg("G",1001,"")		#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT l_where_text ON 
			customer.cust_code, 
			customer.name_text, 
			customer.city_text, 
			customer.post_code, 
			invoicehead.inv_num, 
			invoicehead.total_amt 
		FROM customer.cust_code, 
			customer.name_text, 
			customer.city_text, 
			customer.post_code, 
			invoicehead.inv_num, 
			invoicehead.total_amt 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","GCEb","construct-customer") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
				
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			EXIT WHILE 
		ELSE 
			LET l_msgresp=kandoomsg("G",1002,"") 
			#1002 " Searching database - please wait "
		END IF 
		IF glob_rec_bank.currency_code != glob_rec_glparms.base_currency_code THEN 
			LET l_where_text = l_where_text clipped, 
			" AND customer.currency_code = \"", 
			glob_rec_bank.currency_code clipped,"\" " 
		END IF 
		
		LET l_query_text = 
		"SELECT customer.cust_code,", 
		"customer.corp_cust_code,", 
		"customer.name_text,", 
		"customer.currency_code,", 
		"invoicehead.* ", 
		"FROM invoicehead,", 
		"customer ", 
		"WHERE invoicehead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND invoicehead.cmpy_code = customer.cmpy_code ", 
		"AND invoicehead.cust_code = customer.cust_code ", 
		"AND invoicehead.paid_amt != invoicehead.total_amt ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY inv_num" 
		PREPARE s_head FROM l_query_text 
		DECLARE c_head CURSOR FOR s_head 
		LET l_idx = 0 
		
		FOREACH c_head INTO l_rec_customer.cust_code, 
			l_rec_customer.corp_cust_code, 
			l_rec_customer.name_text, 
			l_rec_customer.currency_code, 
			l_rec_invoicehead.* 
			LET l_idx = l_idx + 1 
			
			IF l_rec_customer.corp_cust_code IS NOT NULL THEN 
				SELECT * INTO l_rec_corpcust.* 
				FROM customer 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = l_rec_customer.corp_cust_code 
				AND delete_flag = "N" 
				IF sqlca.sqlcode = 0 THEN 
					LET l_rec_customer.* = l_rec_corpcust.* 
				END IF 
			END IF 
			
			LET l_arr_rec_invoice[l_idx].invoice_num = l_rec_invoicehead.inv_num 
			LET l_arr_rec_invoice[l_idx].inv_date = l_rec_invoicehead.inv_date 
			LET l_arr_rec_invoice[l_idx].cust_code = l_rec_invoicehead.cust_code 
			LET l_arr_rec_invoice[l_idx].name_text = l_rec_customer.name_text 
			
			SELECT sum(tran_amt),sum(disc_amt) 
			INTO l_prev_app_amt,l_prev_app_disc 
			FROM t_bkdetl 
			WHERE ref_num = l_rec_invoicehead.inv_num 
			AND ref_code = l_rec_invoicehead.cust_code 
			AND (select entry_type_code 
			FROM t_bkstate 
			WHERE seq_num = t_bkdetl.seq_num) = "RE" 
			
			IF l_prev_app_amt IS NULL THEN 
				LET l_prev_app_amt = 0 
				LET l_prev_app_disc = 0 
			END IF 
			
			LET l_arr_rec_invoice[l_idx].paid_amt = l_rec_invoicehead.total_amt 
			- l_rec_invoicehead.paid_amt 
			- l_prev_app_amt 
			- l_prev_app_disc 
			
			IF l_rec_invoicehead.currency_code IS NOT NULL THEN 
				LET l_arr_rec_invoice[l_idx].currency_code = l_rec_invoicehead.currency_code 
			ELSE 
				LET l_arr_rec_invoice[l_idx].currency_code = l_rec_customer.currency_code 
			END IF 
			IF l_rec_invoicehead.paid_amt != 0 THEN 
				LET l_arr_rec_invoice[l_idx].paid_ind = "Y" 
			ELSE 
				LET l_arr_rec_invoice[l_idx].paid_ind = NULL 
			END IF 
			
			IF l_idx = 100 THEN 
				LET l_msgresp = kandoomsg("U",6100,l_idx) 
				EXIT FOREACH 
			END IF 
		END FOREACH 
		
		LET l_msgresp = kandoomsg("U",9113,l_idx) 
		FREE s_head 
		IF l_idx = 0 THEN 
			LET l_idx = 1 
		END IF 
		
		CALL set_count(l_idx) 
		LET l_msgresp=kandoomsg("G",1009,"") 

		#G1009 " ESC TO SELECT - RETURN FOR Line Information "
		INPUT ARRAY l_arr_rec_invoice WITHOUT DEFAULTS FROM sr_invoice.* attributes(unbuffered) 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","GCEb","inp-arr-invoice") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
				
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 


			BEFORE ROW 
				LET l_idx = arr_curr() 
				#LET scrn = scr_line()
				LET l_rec_invoicehead.inv_num = l_arr_rec_invoice[l_idx].invoice_num 
				IF l_idx <= arr_count() THEN 
					#DISPLAY l_arr_rec_invoice[l_idx].*
					#     TO sr_invoice[scrn].*

				ELSE 
					LET l_msgresp=kandoomsg("G",9001,"") 
				END IF 
				
			AFTER FIELD invoice_num 
				LET l_arr_rec_invoice[l_idx].invoice_num = l_rec_invoicehead.inv_num 
				IF l_rec_invoicehead.inv_num IS NOT NULL THEN 
					#DISPLAY l_arr_rec_invoice[l_idx].invoice_num
					#     TO sr_invoice[scrn].invoice_num

				END IF 

			BEFORE FIELD inv_date --customer details / customer invoice submenu 
				CALL cinq_clnt(glob_rec_kandoouser.cmpy_code,l_arr_rec_invoice[l_idx].cust_code) --customer details / customer invoice submenu 
				NEXT FIELD invoice_num 

			AFTER ROW 
				#DISPLAY l_arr_rec_invoice[l_idx].* TO sr_invoice[scrn].*

			ON KEY (control-w) 
				CALL kandoohelp("") 

		END INPUT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			EXIT WHILE 
		END IF
		 
		CLEAR FORM
		 
	END WHILE
	 
	CLOSE WINDOW g405 
	OPTIONS INSERT KEY f1, 
	DELETE KEY f2
	 
	IF l_arr_rec_invoice[l_idx].currency_code != glob_rec_bank.currency_code THEN
	 
		SELECT conv_qty 
		INTO l_rec_invoicehead.conv_qty 
		FROM invoicehead 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND inv_num = l_arr_rec_invoice[l_idx].invoice_num
		 
		IF l_rec_invoicehead.conv_qty IS NULL 
		OR l_rec_invoicehead.conv_qty = 0 THEN 
			LET l_rec_invoicehead.conv_qty = get_conv_rate(
				glob_rec_kandoouser.cmpy_code, 
				l_arr_rec_invoice[l_idx].currency_code, 
				l_arr_rec_invoice[l_idx].inv_date, 
				CASH_EXCHANGE_BUY) 
		END IF 
		
		LET l_arr_rec_invoice[l_idx].paid_amt = l_arr_rec_invoice[l_idx].paid_amt	/ l_rec_invoicehead.conv_qty 
		LET l_msgresp = kandoomsg("G",9078,"") 
	END IF 

	RETURN 
		l_arr_rec_invoice[l_idx].invoice_num, 
		l_arr_rec_invoice[l_idx].inv_date, 
		l_arr_rec_invoice[l_idx].cust_code,"", 
		l_arr_rec_invoice[l_idx].paid_amt 
END FUNCTION 


############################################################
# FUNCTION db_cheque_get_datasource(p_filter)
#
#
############################################################
FUNCTION db_cheque_get_datasource(p_filter)
	DEFINE p_filter BOOLEAN
	DEFINE l_rec_s_cheque RECORD LIKE cheque.* 
	DEFINE l_rec_cheque RECORD LIKE cheque.* 
	DEFINE l_arr_doc_num DYNAMIC ARRAY OF INTEGER --array[100] OF INTEGER, 
	DEFINE l_arr_rec_cheque DYNAMIC ARRAY OF RECORD --array[100] OF RECORD 
		cheq_code LIKE cheque.cheq_code, 
		cheq_date LIKE cheque.cheq_date, 
		vend_code LIKE cheque.vend_code, 
		bank_amt LIKE cheque.net_pay_amt, 
		bank_curr LIKE cheque.currency_code, 
		net_pay_amt LIKE cheque.net_pay_amt, 
		currency_code LIKE cheque.currency_code 
	END RECORD 
	DEFINE l_where_text STRING -- char(300) 
	DEFINE l_query_text STRING --char(800) 
	DEFINE l_idx SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	IF p_filter THEN
		CLEAR FORM 
		LET l_msgresp=kandoomsg("G",1001,"") 
		#1001 " Enter Selection Criteria - ESC TO Continue"

		CONSTRUCT BY NAME l_where_text ON cheq_code, 
		cheq_date, 
		vend_code, 
		net_pay_amt, 
		currency_code 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","GCEb","construct-cheq") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			--INITIALIZE l_arr_rec_cheque[1].* TO NULL 
			LET l_idx = 1 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_where_text = " 1=1 " 
		END IF
	ELSE
		LET l_where_text = " 1=1 "
	END IF

	LET l_msgresp=kandoomsg("G",1002,"") 
	#1002 " Searching database - please wait "
	IF glob_rec_bank.currency_code != glob_rec_glparms.base_currency_code THEN 
		LET l_where_text = l_where_text clipped, 
		" AND currency_code='",glob_rec_bank.currency_code clipped,"'" 
	END IF 

	LET l_query_text = "SELECT * FROM cheque ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code CLIPPED,"' ", 
	"AND bank_code = '",glob_rec_bank.bank_code CLIPPED,"' ", 
	"AND recon_flag != 'Y' ", 
	"AND pay_meth_ind in ('1','2') ", 
	"AND cheq_code != 0 ", 
	"AND cheq_code IS NOT NULL ", 
	"AND ",l_where_text clipped," ", 
	"ORDER BY cheq_code" 

	PREPARE s_cheque FROM l_query_text 
	DECLARE c_cheque CURSOR FOR s_cheque 

	LET l_idx = 0 
	FOREACH c_cheque INTO l_rec_cheque.* 
		##
		## Dont DISPLAY unreconciled items in window IF they appear
		## elsewhere on this sheet.
		##
		SELECT unique 1 FROM t_bkstate 
		WHERE entry_type_code = "CH" 
		AND doc_num = l_rec_cheque.doc_num 
		IF status = NOTFOUND THEN 
			LET l_idx = l_idx + 1 
			LET l_arr_doc_num[l_idx] = l_rec_cheque.doc_num 
			LET l_arr_rec_cheque[l_idx].cheq_code = l_rec_cheque.cheq_code 
			LET l_arr_rec_cheque[l_idx].cheq_date = l_rec_cheque.cheq_date 
			IF l_rec_cheque.currency_code = glob_rec_bank.currency_code THEN 
				LET l_arr_rec_cheque[l_idx].bank_amt = l_rec_cheque.net_pay_amt 
			ELSE 
				LET l_arr_rec_cheque[l_idx].bank_amt = l_rec_cheque.net_pay_amt / l_rec_cheque.conv_qty 
			END IF 
			LET l_arr_rec_cheque[l_idx].bank_curr = glob_rec_bank.currency_code 
			LET l_arr_rec_cheque[l_idx].net_pay_amt = l_rec_cheque.net_pay_amt 
			LET l_arr_rec_cheque[l_idx].currency_code = l_rec_cheque.currency_code 
			LET l_arr_rec_cheque[l_idx].vend_code = l_rec_cheque.vend_code 
		END IF 

	END FOREACH 

	FREE s_cheque 
	
	IF l_arr_rec_cheque.getLength() = 0 THEN 
		LET l_msgresp=kandoomsg("G",9516,l_idx) 
		#G9516 " No entries satisfied selection criteria
	END IF 

	RETURN l_arr_rec_cheque, l_arr_doc_num
END FUNCTION


############################################################
# FUNCTION show_cheq()
#
#
############################################################
FUNCTION show_cheq() 
	DEFINE l_rec_s_cheque RECORD LIKE cheque.* 
	DEFINE l_rec_cheque RECORD LIKE cheque.* 
	DEFINE l_arr_doc_num DYNAMIC ARRAY OF INTEGER --array[100] OF INTEGER, 
	DEFINE l_arr_rec_cheque DYNAMIC ARRAY OF RECORD --array[100] OF RECORD 
		cheq_code LIKE cheque.cheq_code, 
		cheq_date LIKE cheque.cheq_date, 
		vend_code LIKE cheque.vend_code, 
		bank_amt LIKE cheque.net_pay_amt, 
		bank_curr LIKE cheque.currency_code, 
		net_pay_amt LIKE cheque.net_pay_amt, 
		currency_code LIKE cheque.currency_code 
	END RECORD 
	DEFINE l_where_text STRING -- char(300) 
	DEFINE l_query_text STRING --char(800) 
	DEFINE l_idx SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW g402 with FORM "G402" 
	CALL windecoration_g("G402") 

--	WHILE true 
	OPTIONS DELETE KEY f36, 
	INSERT KEY f36 

	CALL db_cheque_get_datasource(FALSE) RETURNING l_arr_rec_cheque, l_arr_doc_num

		LET l_msgresp=kandoomsg("G",1009,"") 

		#G1009 " ESC TO SELECT - RETURN FOR Line Information "
--		INPUT ARRAY l_arr_rec_cheque WITHOUT DEFAULTS FROM sr_cheque.* attributes(unbuffered) 
		DISPLAY ARRAY l_arr_rec_cheque TO sr_cheque.* ATTRIBUTES(unbuffered)
			BEFORE DISPLAY
				CALL publish_toolbar("kandoo","GCEb","inp-arr-cheque1") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null)
				 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON ACTION "FILTER"
				CALL l_arr_rec_cheque.clear()
				CALL db_cheque_get_datasource(TRUE) RETURNING l_arr_rec_cheque

			BEFORE ROW 
				LET l_idx = arr_curr() 
				IF l_idx <= l_arr_rec_cheque.getLength() THEN 
					LET l_rec_cheque.cheq_code = l_arr_rec_cheque[l_idx].cheq_code 
				END IF 


			AFTER DISPLAY --BEFORE FIELD cheq_date 
				IF l_idx <= l_arr_rec_cheque.getSize() THEN 
					IF l_arr_rec_cheque[l_idx].cheq_code IS NOT NULL THEN 
						SELECT * INTO l_rec_s_cheque.* FROM cheque 
						WHERE doc_num = l_arr_doc_num[l_idx] 
						CALL disp_ck_head(glob_rec_kandoouser.cmpy_code, 
						l_arr_rec_cheque[l_idx].vend_code, 
						l_arr_rec_cheque[l_idx].cheq_code, 
						"1", 
						l_rec_s_cheque.bank_code, 
						0) 
					END IF 
				END IF

		END DISPLAY 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
 
		END IF 

	CLOSE WINDOW g402 

	RETURN l_arr_doc_num[l_idx], 
	l_arr_rec_cheque[l_idx].cheq_date, 
	l_arr_rec_cheque[l_idx].cheq_code, 
	l_arr_rec_cheque[l_idx].bank_amt,"" 
END FUNCTION 


############################################################
# FUNCTION show_eft()
#
#
############################################################
FUNCTION show_eft() 
	DEFINE l_rec_cheque RECORD 
		eft_run_num LIKE cheque.eft_run_num, 
		cheq_date LIKE cheque.cheq_date, 
		eft_run_pay_amt LIKE cheque.pay_amt, 
		eft_run_net_amt LIKE cheque.net_pay_amt 
	END RECORD 
	DEFINE l_arr_rec_cheque DYNAMIC ARRAY OF RECORD --array[100] OF RECORD 
		scroll_flag char(1), 
		eft_run_num LIKE cheque.eft_run_num, 
		cheq_date LIKE cheque.cheq_date, 
		eft_run_pay_amt LIKE cheque.net_pay_amt, 
		eft_run_net_amt LIKE cheque.net_pay_amt 
	END RECORD 
	DEFINE l_where_text STRING --char(300) 
	DEFINE l_query_text STRING --char(700) 
	DEFINE l_idx SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW g537 with FORM "G537" 
	CALL windecoration_g("G537") 

	WHILE true 
		CLEAR FORM 
		DISPLAY BY NAME glob_rec_bank.currency_code 

		LET l_msgresp = kandoomsg("G",1001,"") 
		#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON eft_run_num, 
		cheq_date, 
		eft_run_pay_amt, 
		eft_run_net_amt 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","GCEb","construct-eft") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET l_idx = 1 
			--INITIALIZE l_arr_rec_cheque[1].* TO NULL 
			LET int_flag = false 
			LET quit_flag = false 
			EXIT WHILE 
		END IF 
		LET l_msgresp = kandoomsg("G",1002,"") 
		#1002" Searching database - please wait "
		LET l_query_text = "SELECT eft_run_num,", 
		"cheq_date,", 
		"sum(pay_amt), ", 
		"sum(net_pay_amt) ", 
		"FROM cheque ", 
		"WHERE cmpy_code='",glob_rec_kandoouser.cmpy_code, "' ", 
		"AND bank_code='",glob_rec_bank.bank_code, "' ", 
		"AND pay_meth_ind= '3' ", 
		"AND recon_flag != 'Y' ", 
		"AND ",l_where_text," ", 
		"group by eft_run_num,cheq_date ", 
		"ORDER BY eft_run_num" 
		PREPARE s2_cheque FROM l_query_text 
		DECLARE c2_cheque CURSOR FOR s2_cheque 

		LET l_idx = 0 
		FOREACH c2_cheque INTO l_rec_cheque.* 
			LET l_idx = l_idx + 1 
			LET l_arr_rec_cheque[l_idx].eft_run_num = l_rec_cheque.eft_run_num 
			LET l_arr_rec_cheque[l_idx].cheq_date = l_rec_cheque.cheq_date 
			LET l_arr_rec_cheque[l_idx].eft_run_pay_amt = l_rec_cheque.eft_run_pay_amt 
			LET l_arr_rec_cheque[l_idx].eft_run_net_amt = l_rec_cheque.eft_run_net_amt 
			IF l_idx = 100 THEN 
				LET l_msgresp = kandoomsg("G",9186,l_idx) 
				#9186 " First 100 entries selected only"
				EXIT FOREACH 
			END IF 
		END FOREACH 
		
		FREE s2_cheque 
		IF l_idx = 0 THEN 
			LET l_msgresp=kandoomsg("G",9516,l_idx) 
			#G9516 " No entries satisfied selection criteria
			LET l_idx = 1 
		END IF 
		CALL set_count(l_idx) 
		OPTIONS DELETE KEY f36, 
		INSERT KEY f36 
		LET l_msgresp = kandoomsg("G",1008,"") 

		#1008  ESC TO SELECT
		INPUT ARRAY l_arr_rec_cheque WITHOUT DEFAULTS FROM sr_cheque.* attributes(unbuffered) 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","GCEb","inp-arr-cheque2") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
				
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE FIELD scroll_flag 
				LET l_idx = arr_curr() 
				#LET scrn = scr_line()
				#DISPLAY l_arr_rec_cheque[l_idx].* TO sr_cheque[scrn].*

			AFTER FIELD scroll_flag 
				#CLEAR sr_cheque[scrn].scroll_flag
				IF fgl_lastkey() = fgl_keyval("down") THEN 
					IF l_arr_rec_cheque[l_idx+1].eft_run_num IS NULL 
					OR arr_curr() >= arr_count() THEN 
						LET l_msgresp=kandoomsg("G",9001,"") 
						#9001 There no more rows...
						NEXT FIELD scroll_flag 
					END IF 
				END IF 
			BEFORE FIELD eft_run_num 
				IF l_arr_rec_cheque[l_idx].eft_run_num IS NOT NULL THEN 
					EXIT INPUT 
				END IF 
				#AFTER ROW
				#   DISPLAY l_arr_rec_cheque[l_idx].* TO sr_cheque[scrn].*

--			ON KEY (control-w) 
--				CALL kandoohelp("") 
				
		END INPUT 
		
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			EXIT WHILE 
		END IF 
		
	END WHILE 
	
	CLOSE WINDOW g537 
	OPTIONS INSERT KEY f1, 
	DELETE KEY f2 
	
	RETURN l_arr_rec_cheque[l_idx].eft_run_num, 
	l_arr_rec_cheque[l_idx].cheq_date, 
	l_arr_rec_cheque[l_idx].eft_run_num, 
	l_arr_rec_cheque[l_idx].eft_run_net_amt,"" 
END FUNCTION 


############################################################
# FUNCTION show_eft_for_rej()
#
#
############################################################
FUNCTION show_eft_for_rej() 
	DEFINE l_rec_s_cheque RECORD LIKE cheque.* 
	DEFINE l_rec_cheque RECORD LIKE cheque.* 
	DEFINE l_vendor_name LIKE vendor.name_text 
	DEFINE l_arr_doc_num DYNAMIC ARRAY OF INTEGER --array[100] OF INTEGER, 
	DEFINE l_arr_rec_cheque DYNAMIC ARRAY OF RECORD --array[100] OF RECORD 
		cheq_code LIKE cheque.cheq_code, 
		net_pay_amt LIKE cheque.net_pay_amt, 
		vend_code LIKE cheque.vend_code, 
		name_text LIKE vendor.name_text, 
		eft_run_num LIKE cheque.eft_run_num, 
		cheq_date LIKE cheque.cheq_date 
	END RECORD 
	DEFINE l_where_text STRING --char(300), 
	DEFINE l_query_text STRING -- char(800), 
	DEFINE l_idx SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW g517 with FORM "G517" 
	CALL windecoration_g("G517") 

	WHILE true 
		CLEAR FORM 
		LET l_msgresp=kandoomsg("G",1001,"") 
		#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT l_where_text ON cheque.cheq_code, 
		cheque.net_pay_amt, 
		cheque.vend_code, 
		vendor.name_text, 
		cheque.eft_run_num, 
		cheque.cheq_date 
		FROM cheque.cheq_code, 
		cheque.net_pay_amt, 
		cheque.vend_code, 
		vendor.name_text, 
		cheque.eft_run_num, 
		cheque.cheq_date 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","GCEb","construct-cheque2") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null)
				 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar()
				 
		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			--INITIALIZE l_arr_rec_cheque[1].* TO NULL 
			LET l_idx = 1 
			LET int_flag = false 
			LET quit_flag = false 
			EXIT WHILE 
		ELSE 
			LET l_msgresp=kandoomsg("G",1002,"") 
			#1002 " Searching database - please wait "
			IF glob_rec_bank.currency_code != glob_rec_glparms.base_currency_code THEN 
				LET l_where_text = l_where_text clipped, 
				" AND cheque.currency_code='",glob_rec_bank.currency_code clipped,"'" 
			END IF 
		END IF 
		LET l_query_text = "SELECT cheque.* FROM cheque, vendor ", 
		"WHERE cheque.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND vendor.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND cheque.vend_code = vendor.vend_code ", 
		"AND cheque.bank_code = '",glob_rec_bank.bank_code,"' ", 
		"AND cheque.pay_meth_ind = '3' ", 
		"AND cheque.cheq_code != 0 ", 
		"AND cheque.cheq_code IS NOT NULL ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY cheque.cheq_code" 
		PREPARE s_eft FROM l_query_text 
		DECLARE c_eft CURSOR FOR s_eft 
		LET l_idx = 0 
		FOREACH c_eft INTO l_rec_cheque.* 
			##
			## Dont DISPLAY payment items in window IF they appear
			## elsewhere on this sheet.
			##
			SELECT unique 1 FROM t_bkstate 
			WHERE entry_type_code = "ER" 
			AND doc_num = l_rec_cheque.doc_num 
			IF status = NOTFOUND THEN 
				LET l_idx = l_idx + 1 
				SELECT name_text INTO l_vendor_name FROM vendor 
				WHERE vend_code = l_rec_cheque.vend_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = NOTFOUND THEN 
					LET l_vendor_name = "* Not found *" 
				END IF 
				LET l_arr_doc_num[l_idx] = l_rec_cheque.doc_num 
				LET l_arr_rec_cheque[l_idx].cheq_code = l_rec_cheque.cheq_code 
				IF l_rec_cheque.currency_code = glob_rec_bank.currency_code THEN 
					LET l_arr_rec_cheque[l_idx].net_pay_amt = l_rec_cheque.net_pay_amt 
				ELSE 
					LET l_arr_rec_cheque[l_idx].net_pay_amt = l_rec_cheque.net_pay_amt 
					/ l_rec_cheque.conv_qty 
				END IF 
				LET l_arr_rec_cheque[l_idx].vend_code = l_rec_cheque.vend_code 
				LET l_arr_rec_cheque[l_idx].name_text = l_vendor_name 
				LET l_arr_rec_cheque[l_idx].eft_run_num = l_rec_cheque.eft_run_num 
				LET l_arr_rec_cheque[l_idx].cheq_date = l_rec_cheque.cheq_date 
				IF l_idx = 100 THEN 
					LET l_msgresp = kandoomsg("G",9186,l_idx) 
					#9186 " First 100 entries selected only"
					EXIT FOREACH 
				END IF 
			END IF 
		END FOREACH 
		FREE s_eft 
		IF l_idx = 0 THEN 
			LET l_msgresp=kandoomsg("G",9516,l_idx) 
			#G9516 " No entries satisfied selection criteria
			LET l_idx = 1 
		END IF 
		OPTIONS DELETE KEY f36, 
		INSERT KEY f36 
		CALL set_count(l_idx) 
		LET l_msgresp=kandoomsg("G",1009,"") 

		#G1009 " ESC TO SELECT - RETURN FOR Line Information "
		INPUT ARRAY l_arr_rec_cheque WITHOUT DEFAULTS FROM sr_cheque.* attributes(unbuffered) 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","GCEb","inp-arr-cheque3") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				#LET scrn = scr_line()
				LET l_rec_cheque.cheq_code = l_arr_rec_cheque[l_idx].cheq_code 
				IF l_idx <= arr_count() THEN 
					#DISPLAY l_arr_rec_cheque[l_idx].* TO sr_cheque[scrn].*

				ELSE 
					LET l_msgresp=kandoomsg("G",9001,l_idx) 
				END IF 
			AFTER FIELD cheq_code 
				LET l_arr_rec_cheque[l_idx].cheq_code = l_rec_cheque.cheq_code 
				IF l_rec_cheque.cheq_code IS NOT NULL THEN 
					#DISPLAY l_arr_rec_cheque[l_idx].cheq_code TO sr_cheque[scrn].cheq_code

				END IF 
			BEFORE FIELD net_pay_amt 
				IF l_arr_rec_cheque[l_idx].cheq_code IS NOT NULL THEN 
					SELECT * INTO l_rec_s_cheque.* FROM cheque 
					WHERE doc_num = l_arr_doc_num[l_idx] 
					CALL disp_ck_head(glob_rec_kandoouser.cmpy_code, 
					l_arr_rec_cheque[l_idx].vend_code, 
					l_arr_rec_cheque[l_idx].cheq_code, 
					"3", 
					l_rec_s_cheque.bank_code, 
					0) 
				END IF 
				NEXT FIELD cheq_code 
				#AFTER ROW
				#   DISPLAY l_arr_rec_cheque[l_idx].* TO sr_cheque[scrn].*

			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			EXIT WHILE 
		END IF 
		CLEAR FORM 
	END WHILE 
	CLOSE WINDOW g517 
	RETURN l_arr_doc_num[l_idx], 
	l_arr_rec_cheque[l_idx].cheq_date, 
	l_arr_rec_cheque[l_idx].cheq_code, 
	"", 
	l_arr_rec_cheque[l_idx].net_pay_amt 
END FUNCTION 


############################################################
# FUNCTION show_vend_voucher()
#
#
############################################################
FUNCTION show_vend_voucher() 
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_arr_rec_voucher DYNAMIC ARRAY OF RECORD -- array[100] OF RECORD 
		voucher_code LIKE voucher.vouch_code, 
		vouch_date LIKE voucher.vouch_date, 
		vend_code LIKE voucher.vend_code, 
		name_text LIKE vendor.name_text, 
		unpaid_amt LIKE voucher.paid_amt, 
		currency_code LIKE voucher.currency_code, 
		paid_ind char(1) 
	END RECORD 
	DEFINE l_where_text STRING --char(300), 
	DEFINE l_query_text STRING --char(700), 
	DEFINE l_idx SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW g404 with FORM "G404" 
	CALL windecoration_g("G404") 

	WHILE true 
		CLEAR FORM 
		LET l_msgresp=kandoomsg("G",1001,"") 
		#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT l_where_text ON vendor.vend_code, 
		vendor.name_text, 
		voucher.vouch_code, 
		voucher.total_amt 
		FROM vendor.vend_code, 
		vendor.name_text, 
		voucher.vouch_code, 
		voucher.total_amt 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","GCEb","construct-voucher") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
				
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET l_idx = 1 
			--INITIALIZE l_arr_rec_voucher[1].* TO NULL 
			LET int_flag = false 
			LET quit_flag = false 
			EXIT WHILE 
		ELSE 
			LET l_msgresp=kandoomsg("G",1002,"") 
			#1002 " Searching database - please wait "
		END IF 
		IF glob_rec_bank.currency_code != glob_rec_glparms.base_currency_code THEN 
			LET l_where_text = l_where_text clipped, 
			" AND vendor.currency_code = \"", 
			glob_rec_bank.currency_code clipped,"\" " 
		END IF 
		LET l_query_text = 
		"SELECT vendor.name_text,", 
		"voucher.* ", 
		"FROM voucher,", 
		"vendor ", 
		"WHERE voucher.cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND voucher.cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND voucher.vend_code= vendor.vend_code ", 
		"AND vendor.hold_code= 'NO' ", 
		"AND voucher.hold_code= 'NO' ", 
		"AND voucher.year_num != 9999 ", 
		"AND voucher.paid_amt != voucher.total_amt ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY voucher.vouch_code" 
		PREPARE s_voucher FROM l_query_text 
		DECLARE c_voucher CURSOR FOR s_voucher 
		LET l_idx = 0 
		FOREACH c_voucher INTO l_rec_vendor.name_text,l_rec_voucher.* 
			LET l_idx = l_idx + 1 
			LET l_arr_rec_voucher[l_idx].voucher_code = l_rec_voucher.vouch_code 
			LET l_arr_rec_voucher[l_idx].vouch_date = l_rec_voucher.vouch_date 
			LET l_arr_rec_voucher[l_idx].vend_code = l_rec_voucher.vend_code 
			LET l_arr_rec_voucher[l_idx].name_text = l_rec_vendor.name_text 
			LET l_arr_rec_voucher[l_idx].currency_code = l_rec_voucher.currency_code 
			LET l_arr_rec_voucher[l_idx].unpaid_amt = l_rec_voucher.total_amt 
			- l_rec_voucher.paid_amt 
			IF l_rec_voucher.paid_amt != 0 THEN 
				LET l_arr_rec_voucher[l_idx].paid_ind = "Y" 
			ELSE 
				LET l_arr_rec_voucher[l_idx].paid_ind = NULL 
			END IF 
			IF l_idx = 100 THEN 
				LET l_msgresp=kandoomsg("G",9186,l_idx) 
				#G9186 " First 100 Unreconciled Transfers Selected Only"
				EXIT FOREACH 
			END IF 
		END FOREACH 
		FREE s_voucher 
		IF l_idx = 0 THEN 
			LET l_msgresp=kandoomsg("G",9516,l_idx) 
			#G9516 " No entries satisfied selection criteria
			LET l_idx = 1 
		END IF 
		CALL set_count(l_idx) 
		OPTIONS DELETE KEY f36, 
		INSERT KEY f36 
		LET l_msgresp=kandoomsg("G",1009,"") 

		#G1009 " ESC TO SELECT - RETURN FOR Line Information "
		INPUT ARRAY l_arr_rec_voucher WITHOUT DEFAULTS FROM sr_voucher.* attributes(unbuffered) 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","GCEb","inp-arr-voucher") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				#LET scrn = scr_line()
				IF l_idx <= arr_count() THEN 
					LET l_rec_voucher.vouch_code = l_arr_rec_voucher[l_idx].voucher_code 
					#DISPLAY l_arr_rec_voucher[l_idx].* TO sr_voucher[scrn].*

				ELSE 
					LET l_rec_voucher.vouch_code = NULL 
					LET l_msgresp=kandoomsg("G",9001,"") 
				END IF 
			AFTER FIELD voucher_code 
				LET l_arr_rec_voucher[l_idx].voucher_code = l_rec_voucher.vouch_code 
				IF l_rec_voucher.vouch_code IS NOT NULL THEN 
					#DISPLAY l_arr_rec_voucher[l_idx].voucher_code
					#     TO sr_voucher[scrn].voucher_code

				END IF 
			BEFORE FIELD vouch_date 
				IF l_arr_rec_voucher[l_idx].voucher_code IS NOT NULL THEN 
					CALL display_voucher_header(glob_rec_kandoouser.cmpy_code, l_arr_rec_voucher[l_idx].voucher_code) 
				END IF 
				NEXT FIELD voucher_code 

				--         AFTER ROW
				--            DISPLAY l_arr_rec_voucher[l_idx].* TO sr_voucher[scrn].*

				--         ON KEY (control-w)
				--            CALL kandoohelp("")
		END INPUT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			EXIT WHILE 
		END IF 
		CLEAR FORM 
	END WHILE 

	CLOSE WINDOW g404 

	IF l_arr_rec_voucher[l_idx].currency_code != glob_rec_bank.currency_code THEN 
		SELECT conv_qty INTO l_rec_voucher.conv_qty 
		FROM voucher 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND vouch_code = l_arr_rec_voucher[l_idx].voucher_code 
		IF l_rec_voucher.conv_qty IS NULL OR l_rec_voucher.conv_qty = 0 THEN 
			LET l_rec_voucher.conv_qty = get_conv_rate(
				glob_rec_kandoouser.cmpy_code, 
				l_arr_rec_voucher[l_idx].currency_code, 
				l_arr_rec_voucher[l_idx].vouch_date, 
				CASH_EXCHANGE_BUY) 
		END IF 
		
		LET l_arr_rec_voucher[l_idx].unpaid_amt = l_arr_rec_voucher[l_idx].unpaid_amt / l_rec_voucher.conv_qty 
		LET l_msgresp = kandoomsg("G",9078,"") 
	END IF 
	
	RETURN 
		l_arr_rec_voucher[l_idx].voucher_code, 
		l_arr_rec_voucher[l_idx].vouch_date, 
		l_arr_rec_voucher[l_idx].vend_code, 
		l_arr_rec_voucher[l_idx].unpaid_amt,"" 
END FUNCTION 


############################################################
# FUNCTION show_bdep(p_type_ind)
#
# BD Bank Deposit
# SC Sundry Credit
# BC Bank Charge
############################################################
FUNCTION show_bdep(p_type_ind) 
	DEFINE p_type_ind char(2) ## bd bank deposit 
	## SC Sundry Credit
	## BC Bank Charge
	DEFINE l_rec_banking RECORD LIKE banking.* 
	DEFINE l_arr_rec_banking DYNAMIC ARRAY OF RECORD --array[100] OF RECORD 
		scroll_flag char(1), 
		bk_bankdt LIKE banking.bk_bankdt, 
		bk_desc LIKE banking.bk_desc, 
		bk_cred LIKE banking.bk_cred 
	END RECORD 
	DEFINE l_arr_doc_num DYNAMIC ARRAY OF INTEGER --array[100] OF INTEGER, 
	DEFINE l_where_text STRING --char(100), 
	DEFINE l_query_text STRING --char(300), 
	DEFINE l_array_split SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW g403 with FORM "G403" 
	CALL windecoration_g("G403") 

	WHILE true 
		CLEAR FORM 
		IF p_type_ind = "BC" THEN 
			DISPLAY " Bank charge" TO prompt_text 
		ELSE 
			DISPLAY "Bank deposit" TO prompt_text 
		END IF 
		LET l_msgresp=kandoomsg("G",1001,"") 
		#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON bk_bankdt, 
		bk_desc, 
		bk_cred 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","GCEb","construct-bank") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET l_idx = 1 
			--INITIALIZE l_arr_rec_banking[1].* TO NULL 
			LET l_arr_doc_num[l_idx] = 0 
			LET int_flag = false 
			LET quit_flag = false 
			EXIT WHILE 
		END IF 
		LET l_msgresp=kandoomsg("G",1002,"") 
		#1002 " Searching database - please wait "
		CASE 
			WHEN p_type_ind = "BC" 
				LET l_where_text = l_where_text clipped, 
				"AND bk_type ='BC' AND bk_debit != 0" 
			WHEN p_type_ind = "SC" 
				LET l_where_text = l_where_text clipped, 
				"AND bk_type ='SC' AND bk_cred != 0" 
			OTHERWISE 
				LET l_where_text = l_where_text clipped, 
				"AND bk_type in ('CD','DP') AND bk_cred != 0" 
		END CASE 
		LET l_query_text = "SELECT * FROM banking ", 
		"WHERE bk_cmpy ='",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND bk_acct ='",glob_rec_bank.acct_code,"' ", 
		"AND bk_seq_no IS NULL ", 
		"AND bk_sh_no IS NULL ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY bk_bankdt" 
		WHILE true 
			PREPARE s1_banking FROM l_query_text 
			DECLARE c1_banking CURSOR FOR s1_banking 
			LET l_idx = 0 
			FOREACH c1_banking INTO l_rec_banking.* 
				##
				## Dont DISPLAY unreconciled items in window IF they appear
				## elsewhere on this sheet.
				## NB: "doc_num" IS unique on banking table so no need TO
				##     check BC, SC,  DP & CD separately
				SELECT unique 1 FROM t_bkstate 
				WHERE entry_type_code in ("BC","SC","DP","CD") 
				AND doc_num = l_rec_banking.doc_num 
				IF status = NOTFOUND THEN 
					LET l_idx = l_idx + 1 
					LET l_arr_doc_num[l_idx] = l_rec_banking.doc_num 
					LET l_arr_rec_banking[l_idx].bk_bankdt = l_rec_banking.bk_bankdt 
					LET l_arr_rec_banking[l_idx].bk_desc = l_rec_banking.bk_desc 
					IF p_type_ind = "BC" THEN 
						LET l_arr_rec_banking[l_idx].bk_cred = l_rec_banking.bk_debit 
					ELSE 
						LET l_arr_rec_banking[l_idx].bk_cred = l_rec_banking.bk_cred 
					END IF 
					IF l_idx = 100 THEN 
						LET l_msgresp=kandoomsg("G",9186,l_idx) 
						#G9186 " First 100 Unreconciled Transfers Selected Only"
						EXIT FOREACH 
					END IF 
				END IF 
			END FOREACH 
			FREE c1_banking 
			IF l_idx = 0 THEN 
				LET l_msgresp=kandoomsg("G",9516,l_idx) 
				#G9516 " No entries satisfied selection criteria
				LET l_arr_rec_banking[1].bk_bankdt = NULL ## TO avoid 31/12/99 DISPLAY 
				LET l_arr_rec_banking[1].bk_cred = NULL ## TO avoid 0 DISPLAY 
				LET l_idx = 1 
			END IF 
			OPTIONS DELETE KEY f36, 
			INSERT KEY f36 
			CALL set_count(l_idx) 
			LET l_msgresp=kandoomsg("G",1051,l_idx) 

			#G1051 " ESC TO SELECT - F8 TO Split"
			INPUT ARRAY l_arr_rec_banking WITHOUT DEFAULTS FROM sr_banking.* attributes(unbuffered) 

				BEFORE INPUT 
					CALL publish_toolbar("kandoo","GCEb","inp-arr-banking1") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				BEFORE FIELD scroll_flag 
					LET l_idx = arr_curr() 
					#LET scrn = scr_line()
					#DISPLAY l_arr_rec_banking[l_idx].* TO sr_banking[scrn].*

				ON KEY (f8) 
					IF p_type_ind = "BC" THEN 
						LET l_msgresp = kandoomsg("G",9079,"") 
					ELSE 
						IF split(l_arr_doc_num[l_idx]) THEN 
							LET l_array_split = true 
							EXIT INPUT 
						ELSE 
							SELECT bk_bankdt INTO l_arr_rec_banking[l_idx].bk_bankdt 
							FROM banking 
							WHERE doc_num = l_arr_doc_num[l_idx] 
							#DISPLAY l_arr_rec_banking[l_idx].bk_bankdt
							#     TO sr_banking[scrn].bk_bankdt

						END IF 
					END IF 
				ON KEY (f10) 
					IF p_type_ind = "BC" THEN 
						CALL run_prog("GC2","","","","") 
					ELSE 
						CALL run_prog("GC1","","","","") 
					END IF 
				BEFORE FIELD bk_bankdt 
					NEXT FIELD scroll_flag 
					#AFTER ROW
					#   DISPLAY l_arr_rec_banking[l_idx].* TO sr_banking[scrn].*

					--            ON KEY (control-w)
					--               CALL kandoohelp("")
			END INPUT 

			IF l_array_split THEN 
				LET l_array_split = false 
			ELSE 
				EXIT WHILE 
			END IF 
		END WHILE 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 
	CLOSE WINDOW g403 
	IF p_type_ind = "BC" THEN 
		RETURN l_arr_doc_num[l_idx], 
		l_arr_rec_banking[l_idx].bk_bankdt, 
		"", l_arr_rec_banking[l_idx].bk_cred,"" 
	ELSE 
		RETURN l_arr_doc_num[l_idx], 
		l_arr_rec_banking[l_idx].bk_bankdt, 
		"","",l_arr_rec_banking[l_idx].bk_cred 
	END IF 
END FUNCTION 


############################################################
# FUNCTION split(p_doc_num)
#
#
############################################################
FUNCTION split(p_doc_num) 
	DEFINE p_doc_num INTEGER 
	DEFINE l_arr_rec_split array[10] OF RECORD 
		bk_bankdt LIKE banking.bk_bankdt, 
		bk_desc LIKE banking.bk_desc, 
		bk_cred LIKE banking.bk_cred 
	END RECORD 
	DEFINE l_rec_banking RECORD LIKE banking.* 
	DEFINE l_tot_amt decimal(10,2) 
	DEFINE l_remain_amt decimal(10,2) 
	DEFINE l_err_message char(40) 
	DEFINE l_split_cnt SMALLINT 
	DEFINE l_i SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_orig_bank_dep_num LIKE banking.bank_dep_num 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPTIONS INSERT KEY f1, 
	DELETE KEY f2 
	SELECT * INTO l_rec_banking.* 
	FROM banking 
	WHERE doc_num = p_doc_num 

	OPEN WINDOW g144 with FORM "G144" 
	CALL windecoration_g("G144") 

	DISPLAY l_rec_banking.bk_bankdt, 
	l_rec_banking.bk_cred, 
	l_rec_banking.bk_cred 
	TO orig_date, 
	deposit_amt, 
	l_remain_amt 

	LET l_arr_rec_split[1].bk_bankdt = l_rec_banking.bk_bankdt 
	LET l_arr_rec_split[1].bk_desc = l_rec_banking.bk_desc 
	LET l_arr_rec_split[1].bk_cred = l_rec_banking.bk_cred 
	LET l_orig_bank_dep_num = l_rec_banking.bank_dep_num 
	CALL set_count(1) 

	INPUT ARRAY l_arr_rec_split WITHOUT DEFAULTS FROM sr_split.* attributes(unbuffered) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GCEb","inp-arr-split") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			#LET scrn = scr_line()
		BEFORE FIELD bk_desc 
			IF l_arr_rec_split[l_idx].bk_bankdt IS NULL THEN 
				NEXT FIELD bk_bankdt 
			END IF 
			IF l_arr_rec_split[l_idx].bk_desc IS NULL THEN 
				IF l_idx = 1 THEN 
					LET l_arr_rec_split[l_idx].bk_desc = l_rec_banking.bk_desc 
					NEXT FIELD bk_cred 
				ELSE 
					LET l_arr_rec_split[l_idx].bk_desc = "Manually split" 
				END IF 
			END IF 
			#DISPLAY l_arr_rec_split[l_idx].bk_desc TO sr_split[scrn].bk_desc

			IF l_arr_rec_split[l_idx].bk_cred IS NULL THEN 
				LET l_arr_rec_split[l_idx].bk_cred = l_remain_amt 
				#DISPLAY l_remain_amt
				#     TO sr_split[scrn].bk_cred

			END IF 

		AFTER FIELD bk_cred 
			IF l_arr_rec_split[l_idx].bk_cred IS NULL 
			AND l_arr_rec_split[l_idx].bk_bankdt IS NOT NULL THEN 
				LET l_arr_rec_split[l_idx].bk_cred = 0 
			END IF 

		AFTER ROW 
			LET l_tot_amt = 0 
			FOR l_i = 1 TO arr_count() 
				IF l_arr_rec_split[l_i].bk_bankdt IS NOT NULL 
				AND l_arr_rec_split[l_i].bk_cred IS NOT NULL THEN 
					LET l_tot_amt = l_tot_amt + l_arr_rec_split[l_i].bk_cred 
				END IF 
			END FOR 
			LET l_remain_amt = l_rec_banking.bk_cred - l_tot_amt 
			DISPLAY l_remain_amt TO remain_amt  

			IF l_arr_rec_split[l_idx].bk_bankdt IS NULL THEN 
				INITIALIZE l_arr_rec_split[l_idx].* TO NULL 
				#CLEAR sr_split[scrn].*
			ELSE 
				IF l_arr_rec_split[l_idx].bk_cred IS NULL THEN 
					LET l_arr_rec_split[l_idx].bk_cred = 0 
				END IF 
				#DISPLAY l_arr_rec_split[l_idx].*
				#     TO sr_split[scrn].*

			END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF l_remain_amt != 0 THEN 
					LET l_msgresp = kandoomsg("G",9077,"") 
					NEXT FIELD bk_bankdt 
				END IF 
				LET l_tot_amt = 0 
				FOR l_i = 1 TO arr_count() 
					IF l_arr_rec_split[l_i].bk_bankdt IS NOT NULL 
					AND l_arr_rec_split[l_i].bk_cred IS NOT NULL THEN 
						LET l_tot_amt = l_tot_amt + l_arr_rec_split[l_i].bk_cred 
					END IF 
				END FOR 
				IF l_tot_amt <> l_rec_banking.bk_cred THEN 
					LET l_msgresp = kandoomsg("G",9077,"") 
					NEXT FIELD bk_bankdt 
				END IF 
				IF NOT promptTF("",kandoomsg2("G",8022,""),1)	THEN #			#G8022 Confirm TO Split Deposits
					CONTINUE INPUT 
				END IF 
			END IF 
	END INPUT 

	CLOSE WINDOW G144 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

	GOTO bypass 
	LABEL recovery: 
	IF error_recover(l_err_message,status) != "Y" THEN 
		RETURN false 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	LET l_err_message="GCE - Split banking" 
	BEGIN WORK 
		LET l_split_cnt = 1 
		UPDATE banking 
		SET bk_cred = l_arr_rec_split[1].bk_cred, 
		bk_bankdt = l_arr_rec_split[1].bk_bankdt, 
		bk_desc = l_arr_rec_split[1].bk_desc 
		WHERE doc_num = p_doc_num 
		FOR l_i = 2 TO arr_count() 
			IF l_arr_rec_split[l_i].bk_bankdt IS NOT NULL THEN 
				LET l_split_cnt = l_split_cnt + 1 
				LET l_arr_rec_split[l_i].* = l_arr_rec_split[l_i].* 
				INITIALIZE l_rec_banking.* TO NULL 
				LET l_rec_banking.bk_cmpy = glob_rec_kandoouser.cmpy_code 
				LET l_rec_banking.bk_acct = glob_rec_bank.acct_code 
				LET l_rec_banking.bk_type = "CD" 
				LET l_rec_banking.bk_bankdt = l_arr_rec_split[l_i].bk_bankdt 
				LET l_rec_banking.bk_desc = l_arr_rec_split[l_i].bk_desc 
				LET l_rec_banking.bk_cred = l_arr_rec_split[l_i].bk_cred 
				LET l_rec_banking.bk_enter = glob_rec_kandoouser.sign_on_code 
				LET l_rec_banking.bank_dep_num = l_orig_bank_dep_num 
				LET l_rec_banking.doc_num = 0 
				INSERT INTO banking VALUES (l_rec_banking.*) 
			END IF 
		END FOR 

	COMMIT WORK 

	WHENEVER ERROR stop 
	OPTIONS DELETE KEY f36, 
	INSERT KEY f36 

	IF l_split_cnt > 1 THEN 
		RETURN true 
	ELSE 
		RETURN false 
	END IF 
END FUNCTION 


############################################################
# FUNCTION show_transfer(p_type_ind)
#
#
############################################################
FUNCTION show_transfer(p_type_ind) 
	DEFINE p_type_ind char(2) ## ti transfer in 
	## Transfer OUT
	DEFINE l_rec_banking RECORD LIKE banking.* 
	DEFINE l_arr_rec_banking DYNAMIC ARRAY OF RECORD --array[100] OF RECORD 
		bk_bankdt LIKE banking.bk_bankdt, 
		bk_type LIKE banking.bk_type, 
		bk_desc LIKE banking.bk_desc, 
		tran_amt LIKE banking.bk_cred, 
		currency_code LIKE bank.currency_code 
	END RECORD 
	DEFINE l_arr_doc_num array[100] OF INTEGER 
	DEFINE l_where_text char(100) 
	DEFINE l_query_text char(300) 
	DEFINE l_idx SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW g418 with FORM "G418" 
	CALL windecoration_g("G418") 

	WHILE true 
		CLEAR FORM 
		LET l_msgresp=kandoomsg("G",1001,"") 
		#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON bk_bankdt, 
		bk_desc 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","GCEb","construct-bank2") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET l_idx = 1 
			--INITIALIZE l_arr_rec_banking[1].* TO NULL 
			LET l_arr_doc_num[1] = 0 
			LET int_flag = false 
			LET quit_flag = false 
			EXIT WHILE 
		ELSE 
			LET l_msgresp=kandoomsg("G",1002,"") 
			#1002 " Searching database - please wait "
		END IF 

		LET l_query_text = "SELECT * FROM banking ", 
		"WHERE bk_cmpy='",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND bk_acct='",glob_rec_bank.acct_code,"' ", 
		"AND bk_type='",p_type_ind,"' ", 
		"AND bk_seq_no IS NULL ", 
		"AND bk_sh_no IS NULL ", 
		"AND (bk_rec_part IS NULL OR bk_rec_part = \"N\") ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY bk_bankdt" 
		PREPARE s2_banking FROM l_query_text 
		DECLARE c2_banking CURSOR FOR s2_banking 

		LET l_idx = 0 
		FOREACH c2_banking INTO l_rec_banking.* 
			LET l_idx = l_idx + 1 
			LET l_arr_doc_num[l_idx] = l_rec_banking.doc_num 
			LET l_arr_rec_banking[l_idx].bk_bankdt = l_rec_banking.bk_bankdt 
			LET l_arr_rec_banking[l_idx].bk_type = l_rec_banking.bk_type 
			LET l_arr_rec_banking[l_idx].bk_desc = l_rec_banking.bk_desc 
			IF p_type_ind = "TI" THEN 
				LET l_arr_rec_banking[l_idx].tran_amt = l_rec_banking.bk_cred 
			ELSE 
				LET l_arr_rec_banking[l_idx].tran_amt = l_rec_banking.bk_debit 
			END IF 
			LET l_arr_rec_banking[l_idx].currency_code = glob_rec_bank.currency_code 
			IF l_idx = 100 THEN 
				LET l_msgresp=kandoomsg("G",9186,l_idx) 
				#G9196 " First 100 Unreconciled Transfers Selected Only"
				EXIT FOREACH 
			END IF 
		END FOREACH 
		FREE c2_banking 
		IF l_idx = 0 THEN 
			LET l_msgresp=kandoomsg("G",9516,l_idx) 
			#G9516 " No entries satisfied selection criteria
			LET l_idx = 1 
		END IF 
		OPTIONS DELETE KEY f36, 
		INSERT KEY f36 
		CALL set_count(l_idx) 
		LET l_msgresp=kandoomsg("G",1006,"") 

		#G9186 " ESC TO SELECT - F10 add"
		INPUT ARRAY l_arr_rec_banking WITHOUT DEFAULTS FROM sr_banking.* attributes(unbuffered) 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","GCEb","inp-arr-banking2") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON KEY (f10) 
				CALL run_prog("GC8","","","","") 

			BEFORE FIELD bk_bankdt 
				LET l_idx = arr_curr() 
				#LET scrn = scr_line()
				IF l_arr_rec_banking[l_idx].bk_bankdt IS NULL THEN 
					#CLEAR sr_banking[scrn].bk_bankdt
				ELSE 
					LET l_rec_banking.bk_bankdt = l_arr_rec_banking[l_idx].bk_bankdt 
					#DISPLAY l_arr_rec_banking[l_idx].* TO sr_banking[scrn].*

				END IF 

			AFTER FIELD bk_bankdt 
				LET l_arr_rec_banking[l_idx].bk_bankdt = l_rec_banking.bk_bankdt 
				#DISPLAY l_arr_rec_banking[l_idx].bk_bankdt TO sr_banking[scrn].bk_bankdt

				IF fgl_lastkey() = fgl_keyval("down") 
				AND arr_curr() = arr_count() THEN 
					LET l_msgresp=kandoomsg("A",9001,"") 
					#9001 There are no more rows in the direction ...
					NEXT FIELD bk_bankdt 
				END IF 

			BEFORE FIELD bk_desc 
				NEXT FIELD bk_bankdt 
				--         AFTER ROW
				--            DISPLAY l_arr_rec_banking[l_idx].* TO sr_banking[scrn].*

				--         ON KEY (control-w)
				--            CALL kandoohelp("")
		END INPUT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 

	CLOSE WINDOW g418 

	IF p_type_ind = "TI" THEN 
		RETURN l_arr_doc_num[l_idx], 
		l_arr_rec_banking[l_idx].bk_bankdt, 
		l_arr_rec_banking[l_idx].bk_desc, 
		"", l_arr_rec_banking[l_idx].tran_amt 
	ELSE 
		RETURN l_arr_doc_num[l_idx], 
		l_arr_rec_banking[l_idx].bk_bankdt, 
		l_arr_rec_banking[l_idx].bk_desc, 
		l_arr_rec_banking[l_idx].tran_amt,"" 
	END IF 
END FUNCTION 
