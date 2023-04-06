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
# Purpose - Writes details TO UPDATE tables FOR invoices.
############################################################
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/A2_GROUP_GLOBALS.4gl"
GLOBALS "../ar/A2S_GLOBALS.4gl" 
############################################################
# GLOBAL Scope Variables
############################################################
DEFINE modu_check_cost MONEY
DEFINE modu_check_tax MONEY 
DEFINE modu_check_mat MONEY 
DEFINE modu_found_one SMALLINT 
DEFINE modu_idx1 SMALLINT
DEFINE modu_det_cnt SMALLINT 
DEFINE modu_first_time SMALLINT 
DEFINE modu_l_which CHAR(3) 
DEFINE modu_arr_ma_invdetl array[300] OF RECORD LIKE invoicedetl.* 
DEFINE modu_arr_invhead RECORD LIKE invoicehead.* 
DEFINE modu_attn_text CHAR(40) 


############################################################
# FUNCTION cust_head(p_group_code) 
#
#
############################################################
FUNCTION cust_head(p_group_code) 
	DEFINE p_group_code LIKE stnd_custgrp.group_code 
	DEFINE l_rpt_idx SMALLINT 	
	DEFINE l_tmpmsg STRING 

	LET modu_arr_invhead.* = glob_rec_invoicehead.* 
	LET modu_idx1 = 1 
	LET modu_first_time = 1 

--	CALL upd_rms(glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code, glob_rec_kandoouser.security_ind, glob_rec_rmsreps.report_width_num, glob_menu_path, "Customer Invoice Report") 
--	RETURNING glob_rec_rmsreps.file_text 


	WHILE true 
		IF glob_arr_rec_st_invoicedetl[modu_idx1].cmpy_code IS NULL THEN 
			EXIT WHILE 
		END IF 
		LET modu_arr_ma_invdetl[modu_idx1].* = glob_arr_rec_st_invoicedetl[modu_idx1].* 
		LET modu_idx1 = modu_idx1 + 1 
	END WHILE 
	LET modu_det_cnt = modu_idx1 - 1 
	BEGIN WORK 

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"AS2F_rpt_list_invoice",NULL, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT AS2F_rpt_list_invoice TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------
--		START REPORT AS2F_rpt_list_invoice TO glob_rec_rmsreps.file_text 
		FOR glob_idx = 1 TO arr_count() 
			INITIALIZE glob_rec_term.* TO NULL 
			INITIALIZE glob_rec_customership.* TO NULL 
			IF glob_arr_rec_customer[glob_idx].incld_flg = 'Y' THEN 
				LET glob_rec_invoicehead.cust_code = glob_arr_rec_customer[glob_idx].cust_code 

				FOR modu_idx1 = 1 TO modu_det_cnt 
					LET glob_arr_rec_st_invoicedetl[modu_idx1].cust_code = glob_arr_rec_customer[glob_idx].cust_code 
				END FOR 

				SELECT * 
				INTO glob_rec_customer.* 
				FROM customer 
				WHERE cust_code = glob_arr_rec_customer[glob_idx].cust_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 

				LET glob_rec_invoicehead.name_text = glob_rec_customer.name_text 
				LET glob_rec_invoicehead.org_cust_code = glob_rec_customer.corp_cust_code 
				LET glob_rec_invoicehead.sale_code = glob_rec_customer.sale_code 
				LET glob_rec_invoicehead.term_code = glob_rec_customer.term_code 

				SELECT * 
				INTO glob_rec_term.* 
				FROM term 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND term_code = glob_rec_invoicehead.term_code 

				IF status = NOTFOUND THEN 
					ERROR "Term code FOR customer NOT found, must add TO continue" 
					SLEEP 10 
					EXIT PROGRAM 
				END IF 

				LET glob_rec_invoicehead.disc_amt = (glob_rec_invoicehead.goods_amt + 
				glob_rec_invoicehead.hand_amt) * 
				glob_rec_term.disc_per / 100 
				LET glob_rec_invoicehead.disc_per = glob_rec_term.disc_per 
	
				SELECT * 
				INTO glob_rec_customership.* 
				FROM customership 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = glob_rec_invoicehead.cust_code 

				LET glob_rec_invoicehead.ship_code = glob_rec_customership.ship_code 
				LET glob_rec_invoicehead.addr1_text = glob_rec_customership.addr_text 
				LET glob_rec_invoicehead.addr2_text = glob_rec_customership.addr2_text 
				LET glob_rec_invoicehead.city_text = glob_rec_customership.city_text 
				LET glob_rec_invoicehead.state_code = glob_rec_customership.state_code 
				LET glob_rec_invoicehead.post_code = glob_rec_customership.post_code 
				LET glob_rec_invoicehead.country_code = glob_rec_customership.country_code --@db-patch_2020_10_04--
				LET glob_rec_invoicehead.ship1_text = glob_rec_customership.ship1_text 
				LET glob_rec_invoicehead.ship2_text = glob_rec_customership.ship2_text 


				CALL write_inv() 
				OUTPUT TO REPORT AS2F_rpt_list_invoice(l_rpt_idx,
				glob_rec_invoicehead.cust_code, 
				glob_rec_invoicehead.name_text, 
				glob_rec_invoicehead.inv_num) 

				LET glob_arr_rec_customer[glob_idx].inv_num = glob_rec_invoicehead.inv_num 
				
				SELECT attn_text 
				INTO modu_attn_text 
				FROM stnd_custgrp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = glob_arr_rec_customer[glob_idx].cust_code 
				AND group_code = p_group_code 

				IF status = NOTFOUND THEN 

					LET l_tmpmsg = " Enter Attention name FOR - ",glob_arr_rec_customer[glob_idx].cust_code, " / ",p_group_code 
					LET modu_attn_text = fgl_winprompt(5,5, l_tmpmsg, "", 25, 0) 


				END IF 

				IF int_flag OR quit_flag THEN 
					EXIT FOR 
				END IF 

				INSERT INTO stnd_inv VALUES (
					glob_rec_kandoouser.cmpy_code, 
					glob_arr_rec_customer[glob_idx].cust_code, 
					p_group_code, 
					glob_arr_rec_customer[glob_idx].inv_num, 
					modu_attn_text) 

			ELSE 
				CONTINUE FOR 
			END IF 
		END FOR 

	#------------------------------------------------------------
	FINISH REPORT AS2F_rpt_list_invoice 
	CALL rpt_finish("AS2F_rpt_list_invoice")
	#------------------------------------------------------------

		MESSAGE " " 
		MESSAGE " ESCape TO continue, DEL TO EXIT without saving " 
		attribute (yellow) 

		DISPLAY ARRAY glob_arr_rec_customer TO sr_stand_inv.* ATTRIBUTE(UNBUFFERED) 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","A2Sf","display-arr-customer") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

--			ON KEY (ESC) 
--				EXIT DISPLAY 
		END DISPLAY 

		CLOSE WINDOW wa2sa 

		IF int_flag OR quit_flag THEN 
			ROLLBACK WORK 
			EXIT PROGRAM 
		ELSE 
		COMMIT WORK 
	END IF 
END FUNCTION 
############################################################
# END FUNCTION cust_head(p_group_code) 
############################################################


############################################################
# FUNCTION write_inv()
#
# 
############################################################
FUNCTION write_inv() 
	DEFINE l_tax_idx SMALLINT
	DEFINE i SMALLINT
	DEFINE l_counter SMALLINT
	DEFINE l_err_continue CHAR(1)
	DEFINE l_err_message CHAR(40)
	DEFINE l_ans CHAR(1)
	DEFINE l_chkagn CHAR(1)
	DEFINE l_err_flag CHAR(1)
	DEFINE l_rec_araudit RECORD LIKE araudit.*
	DEFINE l_rec_inparms RECORD LIKE inparms.*
	DEFINE l_rec_prodledg RECORD LIKE prodledg.* 
	DEFINE l_tmpmsg STRING 

	INITIALIZE l_rec_araudit.* TO NULL 
	LET modu_check_tax = 0 
	LET modu_check_mat = 0 
	LET modu_check_cost = 0 
	LET l_err_flag = "N" 
	FOR l_tax_idx = 1 TO 300 
		INITIALIZE glob_arr_rec_taxamt[l_tax_idx].tax_code TO NULL 
	END FOR 
	GOTO bypass 

	LABEL recovery: 
	LET l_err_continue = error_recover(l_err_message, status) 
	IF l_err_continue != "Y" THEN 
		IF glob_f_type = "I" THEN 
			CALL out_stat() 
		END IF 
		EXIT PROGRAM 
	END IF 

	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	CALL db_inparms_get_rec(UI_OFF,"1") RETURNING l_rec_inparms.*

	###  UPDATE AR paramaters RECORD AND get invoice number...
	IF glob_f_type = "I" THEN 
		LET l_err_message = "A2S - Next invoice number UPDATE" 
		CALL arparms_init() # AR/Account Receivable Parameters (arparms)

		IF glob_rec_arparms.nextinv_num = 0 THEN 
			IF modu_first_time = 1 THEN 
				LET glob_rec_invoicehead.inv_num = next_trans_num(
					glob_rec_kandoouser.cmpy_code,
					TRAN_TYPE_INVOICE_IN, 
					glob_rec_invoicehead.acct_override_code) 
				WHENEVER ERROR CONTINUE 
				IF glob_rec_invoicehead.inv_num = -9999 THEN 
					ERROR "Invalid numbering - Reveiw menu GZD" 
					SLEEP 5 
					EXIT PROGRAM 
				END IF 
				LET modu_first_time = 0 
			ELSE 
				LET glob_rec_invoicehead.inv_num = glob_rec_invoicehead.inv_num + 1 
			END IF 
		ELSE 
			LET glob_rec_invoicehead.inv_num = next_trans_num(
				glob_rec_kandoouser.cmpy_code,
				TRAN_TYPE_INVOICE_IN, 
				glob_rec_invoicehead.acct_override_code) 
			
			WHENEVER ERROR CONTINUE 
			IF glob_rec_invoicehead.inv_num = -9999 THEN 
				ERROR "Invalid numbering - Reveiw menu GZD" 
				SLEEP 5 
				EXIT PROGRAM 
			END IF 
		END IF 


		WHENEVER ERROR GOTO recovery 
		IF glob_rec_invoicehead.inv_num < 0 THEN 
			LET status = glob_rec_invoicehead.inv_num 
			GOTO recovery 
		END IF 
		# check that the invoice does NOT already exist
		LET l_chkagn = "Y" 
		WHILE l_chkagn = "Y" 

			DECLARE c1 CURSOR FOR 
			SELECT 1 
			INTO l_counter 
			FROM invoicehead 
			WHERE inv_num = glob_rec_invoicehead.inv_num 
			AND cmpy_code = glob_rec_invoicehead.cmpy_code 
			OPEN c1 
			FETCH c1 
			IF status = NOTFOUND THEN 
				LET l_chkagn = "N" 
				EXIT WHILE 
			END IF 

			LET l_tmpmsg = "WARNING : ", glob_rec_invoicehead.inv_num, " invoice number has already\n",	"been used, do you wish TO allocate another number" 
			LET l_ans = promptYN("Line Information","Do you wish TO hold line information?","Y") 

			IF l_ans matches "[Yy]" THEN 
				LET glob_rec_invoicehead.inv_num = next_trans_num(
					glob_rec_kandoouser.cmpy_code, 
					TRAN_TYPE_INVOICE_IN, 
					glob_rec_invoicehead.acct_override_code) 
			ELSE 
				EXIT PROGRAM 
			END IF 
		END WHILE 

		CLOSE c1 
		IF glob_rec_arparms.job_flag = "R" THEN 
			LET glob_goon = "R" 
		END IF 
	ELSE 
		# an invoice edit
		# get the latest paid_amt in CASE changed, FOR UPDATE TO lock

		DECLARE paid_curs CURSOR FOR 
		SELECT paid_amt, 
		rev_num 
		INTO glob_rec_save_inv_head.paid_amt, 
		glob_rec_save_inv_head.rev_num 
		FROM invoicehead 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND inv_num = glob_rec_invoicehead.inv_num 
		FOR UPDATE 

		OPEN paid_curs 
		FETCH paid_curs 

		# transfer across invoice static details
		LET glob_rec_invoicehead.paid_amt = glob_rec_save_inv_head.paid_amt 
		LET glob_rec_invoicehead.posted_flag = glob_rec_save_inv_head.posted_flag 
		LET glob_rec_invoicehead.story_flag = glob_rec_save_inv_head.story_flag 
		LET glob_rec_invoicehead.rev_date = today 
		IF glob_rec_save_inv_head.rev_num IS NULL THEN 
			LET glob_rec_save_inv_head.rev_num = 0 
		END IF 
		LET glob_rec_invoicehead.rev_num = glob_rec_save_inv_head.rev_num + 1 
		LET glob_rec_invoicehead.currency_code = glob_rec_save_inv_head.currency_code 
		LET glob_rec_invoicehead.inv_ind = glob_rec_save_inv_head.inv_ind 
		#   in the CASE of edit invoice delete out all the current invoice

		INITIALIZE l_rec_araudit.* TO NULL 
		LET l_err_message = "A2S - Customer backout " 

		DECLARE curr_amts CURSOR FOR 
		SELECT * 
		INTO glob_rec_customer.* 
		FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = glob_rec_save_inv_head.cust_code 
		FOR UPDATE 
		OPEN curr_amts 
		FETCH curr_amts 

		LET glob_rec_customer.bal_amt = glob_rec_customer.bal_amt - glob_rec_save_inv_head.total_amt 
		LET glob_rec_customer.next_seq_num = glob_rec_customer.next_seq_num + 1 
		LET l_rec_araudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_rec_araudit.tran_date = today 
		LET l_rec_araudit.cust_code = glob_rec_save_inv_head.cust_code 
		LET l_rec_araudit.seq_num = glob_rec_customer.next_seq_num 
		LET l_rec_araudit.tran_type_ind = TRAN_TYPE_INVOICE_IN 
		LET l_rec_araudit.source_num = glob_rec_save_inv_head.inv_num 
		LET l_rec_araudit.tran_text = "Backout Invoice" 
		LET l_rec_araudit.tran_amt = (0 - glob_rec_save_inv_head.total_amt) 
		LET l_rec_araudit.entry_code = glob_rec_kandoouser.sign_on_code 
		LET l_rec_araudit.sales_code = glob_rec_save_inv_head.sale_code 
		LET l_rec_araudit.year_num = glob_rec_save_inv_head.year_num 
		LET l_rec_araudit.period_num = glob_rec_save_inv_head.period_num 
		LET l_rec_araudit.bal_amt = glob_rec_customer.bal_amt 
		LET l_rec_araudit.currency_code = glob_rec_customer.currency_code 
		LET l_rec_araudit.conv_qty = glob_rec_save_inv_head.conv_qty 
		LET l_rec_araudit.entry_date = today 
		LET l_err_message = "A2S - Unable TO add TO AR log table " 

		INSERT INTO araudit VALUES (l_rec_araudit.*)
		 
		LET glob_rec_customer.curr_amt = glob_rec_customer.curr_amt - glob_rec_save_inv_head.total_amt 
		LET glob_rec_customer.cred_bal_amt = glob_rec_customer.cred_limit_amt - glob_rec_customer.bal_amt 
		LET glob_rec_customer.ytds_amt = glob_rec_customer.ytds_amt - glob_rec_save_inv_head.total_amt 
		LET glob_rec_customer.mtds_amt = glob_rec_customer.mtds_amt - glob_rec_save_inv_head.total_amt 
		LET l_err_message = "A2S - Customer backout " 

		UPDATE customer 
		SET next_seq_num = glob_rec_customer.next_seq_num, 
		bal_amt = glob_rec_customer.bal_amt, 
		curr_amt = glob_rec_customer.curr_amt, 
		highest_bal_amt = glob_rec_customer.highest_bal_amt, 
		cred_bal_amt = glob_rec_customer.cred_bal_amt, 
		last_inv_date = today, 
		ytds_amt = glob_rec_customer.ytds_amt, 
		mtds_amt = glob_rec_customer.mtds_amt 
		WHERE CURRENT OF curr_amts 

		CLOSE curr_amts 
		#  Delete the original invoice lines IF in edit
		LET modu_l_which = TRAN_TYPE_INVOICE_IN 

		DECLARE il_curs CURSOR FOR 
		SELECT * 
		INTO glob_rec_invoicedetl.* 
		FROM invoicedetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = glob_rec_save_inv_head.cust_code 
		AND inv_num = glob_rec_save_inv_head.inv_num 

		FOREACH il_curs 
			IF glob_rec_invoicedetl.part_code IS NULL 
			OR glob_rec_invoicedetl.part_code = " " 
			OR glob_rec_invoicedetl.ship_qty = 0 THEN 
			ELSE 
				LET modu_found_one = 0 
				DECLARE ps_curs CURSOR FOR 
				SELECT * 
				INTO glob_rec_prodstatus.* 
				FROM prodstatus 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
				part_code = glob_rec_invoicedetl.part_code 
				AND ware_code = glob_rec_invoicedetl.ware_code 
				FOR UPDATE 
				FOREACH ps_curs 
					LET modu_found_one = 1 
					LET glob_rec_prodstatus.seq_num = glob_rec_prodstatus.seq_num + 1 
					IF glob_rec_prodstatus.onhand_qty IS NULL THEN 
						LET glob_rec_prodstatus.onhand_qty = 0 
					END IF 
					## Do NOT adjust onhnd VALUES FOR non-stocked inventory items
					IF glob_rec_prodstatus.stocked_flag = "Y" THEN 
						LET glob_rec_prodstatus.onhand_qty 
						= glob_rec_prodstatus.onhand_qty 
						+ glob_rec_invoicedetl.ship_qty 
						LET glob_rec_prodstatus.reserved_qty 
						= glob_rec_prodstatus.reserved_qty 
						+ glob_rec_invoicedetl.ship_qty 
					END IF 
					UPDATE prodstatus 
					SET onhand_qty = glob_rec_prodstatus.onhand_qty, 
					reserved_qty = glob_rec_prodstatus.reserved_qty, 
					last_sale_date = today, 
					seq_num = glob_rec_prodstatus.seq_num 
					WHERE CURRENT OF ps_curs 
				END FOREACH 

				# modu_found_one needed TO overcome CPP problem
				# of selling no product AT whouse
				IF modu_found_one = 1 THEN 
					LET l_rec_prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET l_rec_prodledg.part_code = glob_rec_invoicedetl.part_code 
					LET l_rec_prodledg.ware_code = glob_rec_invoicedetl.ware_code 
					LET l_rec_prodledg.tran_date = today 
					LET l_rec_prodledg.seq_num = glob_rec_prodstatus.seq_num 
					LET l_rec_prodledg.trantype_ind = "S" 
					LET l_rec_prodledg.year_num = glob_rec_invoicehead.year_num 
					LET l_rec_prodledg.period_num = glob_rec_invoicehead.period_num 
					LET l_rec_prodledg.source_text = glob_rec_invoicedetl.cust_code 
					LET l_rec_prodledg.source_num = glob_rec_invoicedetl.inv_num 
					LET l_rec_prodledg.tran_qty = glob_rec_invoicedetl.ship_qty 
					LET l_rec_prodledg.bal_amt = glob_rec_prodstatus.onhand_qty 
					IF glob_rec_invoicehead.conv_qty IS NOT NULL THEN 
						IF glob_rec_invoicehead.conv_qty != 0 THEN 
							LET l_rec_prodledg.cost_amt = glob_rec_invoicedetl.unit_cost_amt / 
							glob_rec_invoicehead.conv_qty 
							LET l_rec_prodledg.sales_amt = glob_rec_invoicedetl.unit_sale_amt / 
							glob_rec_invoicehead.conv_qty 
						END IF 
					END IF 
					
					IF l_rec_inparms.hist_flag = "Y" THEN 
						LET l_rec_prodledg.hist_flag = "N" 
					ELSE 
						LET l_rec_prodledg.hist_flag = "Y" 
					END IF 
					
					LET l_rec_prodledg.post_flag = "N" 
					LET l_rec_prodledg.entry_code = glob_rec_kandoouser.sign_on_code 
					LET l_rec_prodledg.entry_date = today 
					LET l_err_message = "A2S - Product ledger INSERT failed" 
					
					INSERT INTO prodledg VALUES (l_rec_prodledg.*) 
				END IF 
			END IF 
		END FOREACH 

		LET l_err_message = "A2S - invoice line deletion failed" 

		DELETE FROM invoicedetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = glob_rec_save_inv_head.cust_code 
		AND inv_num = glob_rec_save_inv_head.inv_num 
		# delete out the invoicehead
		LET l_err_message = "A2S - invoice head deletion failed" 

		DELETE FROM invoicehead 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = glob_rec_save_inv_head.cust_code 
		AND inv_num = glob_rec_save_inv_head.inv_num 
	END IF 

	# the next piece of code allows the user TO renumber invoices
	# IF required the old invoice would now be deleted off,
	# AND we need TO renumber the invoice number..
	# This code could be commented out IF required.
	IF glob_goon = "R" THEN 
		LET glob_rec_invoicehead.inv_num = fgl_winprompt(5,5, "New Invoice Number", "", 25, 0) 

		IF glob_rec_invoicehead.inv_num IS NULL THEN 
			WHILE glob_rec_invoicehead.inv_num IS NULL 
				ERROR "You must enter an invoice number" 
				LET glob_rec_invoicehead.inv_num = fgl_winprompt(5,5, "You must enter an invoice number\n\nNew Invoice Number", "", 25, 0) 
			END WHILE 
		END IF 
	END IF 

	IF glob_goon != "C" THEN 
		LET l_err_message = "A2S - Customer UPDATE " 
		DECLARE cm1_curs CURSOR FOR 
		SELECT * 
		INTO glob_rec_customer.* 
		FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = glob_rec_invoicehead.cust_code 
		FOR UPDATE 
		OPEN cm1_curs 
		FETCH cm1_curs 

		LET glob_rec_customer.next_seq_num = glob_rec_customer.next_seq_num + 1 
		IF glob_rec_customer.bal_amt = 0 THEN 
			LET glob_rec_customer.bal_amt = glob_rec_invoicehead.total_amt 
		ELSE 
			LET glob_rec_customer.bal_amt = glob_rec_customer.bal_amt 
			+ glob_rec_invoicehead.total_amt 
		END IF 
		LET l_err_message = "A2S - Unable TO add TO AR log table " 
		LET l_rec_araudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_rec_araudit.tran_date = glob_rec_invoicehead.inv_date 
		LET l_rec_araudit.cust_code = glob_rec_invoicehead.cust_code 
		LET l_rec_araudit.seq_num = glob_rec_customer.next_seq_num 
		LET l_rec_araudit.tran_type_ind = TRAN_TYPE_INVOICE_IN 
		LET l_rec_araudit.source_num = glob_rec_invoicehead.inv_num 
		LET l_rec_araudit.tran_text = "Enter Invoice" 
		LET l_rec_araudit.tran_amt = glob_rec_invoicehead.total_amt 
		LET l_rec_araudit.entry_code = glob_rec_kandoouser.sign_on_code 
		LET l_rec_araudit.sales_code = glob_rec_invoicehead.sale_code 
		LET l_rec_araudit.year_num = glob_rec_invoicehead.year_num 
		LET l_rec_araudit.period_num = glob_rec_invoicehead.period_num 
		LET l_rec_araudit.bal_amt = glob_rec_customer.bal_amt 
		LET l_rec_araudit.currency_code = glob_rec_customer.currency_code 
		LET l_rec_araudit.conv_qty = glob_rec_invoicehead.conv_qty 
		LET l_rec_araudit.entry_date = today 

		INSERT INTO araudit VALUES (l_rec_araudit.*) 
		
		LET glob_rec_customer.curr_amt = glob_rec_customer.curr_amt	+ glob_rec_invoicehead.total_amt 
		IF glob_rec_customer.bal_amt > glob_rec_customer.highest_bal_amt THEN 
			LET glob_rec_customer.highest_bal_amt = glob_rec_customer.bal_amt 
		END IF 
		
		LET glob_rec_customer.cred_bal_amt = 
			glob_rec_customer.cred_limit_amt - glob_rec_customer.bal_amt - glob_rec_customer.onorder_amt 
		IF year(glob_rec_invoicehead.inv_date)> year(glob_rec_customer.last_inv_date) THEN 
			LET glob_rec_customer.ytds_amt = 0 
		END IF 
		
		LET glob_rec_customer.ytds_amt = glob_rec_customer.ytds_amt	+ glob_rec_invoicehead.total_amt 
		
		IF (month(glob_rec_invoicehead.inv_date) > month(glob_rec_customer.last_inv_date) 
		OR year(glob_rec_invoicehead.inv_date) > year(glob_rec_customer.last_inv_date)) THEN 
			LET glob_rec_customer.mtds_amt = 0 
		END IF 
		
		LET glob_rec_customer.mtds_amt = glob_rec_customer.mtds_amt	+ glob_rec_invoicehead.total_amt 
		LET glob_rec_customer.last_inv_date = glob_rec_invoicehead.inv_date 
		LET l_err_message = "A2S - Customer actual UPDATE " 
		
		UPDATE customer 
		SET next_seq_num = glob_rec_customer.next_seq_num, 
		bal_amt = glob_rec_customer.bal_amt, 
		curr_amt = glob_rec_customer.curr_amt, 
		highest_bal_amt = glob_rec_customer.highest_bal_amt, 
		cred_bal_amt = glob_rec_customer.cred_bal_amt, 
		last_inv_date = glob_rec_customer.last_inv_date, 
		ytds_amt = glob_rec_customer.ytds_amt, 
		mtds_amt = glob_rec_customer.mtds_amt 
		WHERE CURRENT OF cm1_curs 
		CLOSE cm1_curs 
		#  now add in the invoice lines
		LET l_err_message = "A2S - invoice line addition failed" 

		FOR i = 1 TO glob_arr_size 
			LET glob_rec_invoicedetl.* = glob_arr_rec_st_invoicedetl[i].* 
			IF glob_rec_invoicedetl.ext_tax_amt IS NULL THEN 
				LET glob_rec_invoicedetl.ext_tax_amt = 0 
			END IF 
			IF glob_rec_invoicedetl.ext_sale_amt IS NULL THEN 
				LET glob_rec_invoicedetl.ext_sale_amt = 0 
			END IF 
			IF glob_rec_invoicedetl.line_total_amt IS NULL THEN 
				LET glob_rec_invoicedetl.line_total_amt = 0 
			END IF 
			IF glob_rec_invoicedetl.ext_cost_amt IS NULL THEN 
				LET glob_rec_invoicedetl.ext_cost_amt = 0 
			END IF 
			LET glob_rec_invoicedetl.inv_num = glob_rec_invoicehead.inv_num 
			LET glob_rec_invoicedetl.line_num = i 

			IF glob_rec_invoicedetl.part_code IS NOT NULL 
			AND glob_rec_invoicedetl.ship_qty != 0 THEN 
				DECLARE ps1_curs CURSOR FOR 
				SELECT * 
				INTO glob_rec_prodstatus.* 
				FROM prodstatus 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = glob_rec_invoicedetl.part_code 
				AND ware_code = glob_rec_invoicedetl.ware_code 
				FOR UPDATE 

				FOREACH ps1_curs 
					LET glob_rec_prodstatus.seq_num = glob_rec_prodstatus.seq_num + 1 
					LET glob_rec_invoicedetl.seq_num = glob_rec_prodstatus.seq_num 
					IF glob_rec_prodstatus.onhand_qty IS NULL THEN 
						LET glob_rec_prodstatus.onhand_qty = 0 
					END IF 
					# Dont adjust onhand VALUES FOR non-stocked Inventory
					IF glob_rec_prodstatus.stocked_flag = "Y" THEN 
						LET glob_rec_prodstatus.onhand_qty = glob_rec_prodstatus.onhand_qty - glob_rec_invoicedetl.ship_qty 
						LET glob_rec_prodstatus.reserved_qty = glob_rec_prodstatus.reserved_qty - glob_rec_invoicedetl.ship_qty 
					END IF 
					
					UPDATE prodstatus 
					SET onhand_qty = glob_rec_prodstatus.onhand_qty, 
					reserved_qty = glob_rec_prodstatus.reserved_qty, 
					last_sale_date = glob_rec_invoicehead.inv_date, 
					seq_num = glob_rec_prodstatus.seq_num 
					WHERE CURRENT OF ps1_curs 
				END FOREACH
				 
				# patch up the line_acct_code
				CALL account_patch(
					glob_rec_kandoouser.cmpy_code, 
					glob_rec_invoicedetl.line_acct_code, 
					glob_patch_code) 
				RETURNING glob_rec_invoicedetl.line_acct_code 
			END IF
			 
			#  now add the line
			IF glob_rec_invoicedetl.part_code IS NULL 
			AND glob_rec_invoicedetl.line_text IS NULL 
			AND ( glob_rec_invoicedetl.line_total_amt = 0 
			OR glob_rec_invoicedetl.line_total_amt IS null
			OR glob_rec_invoicedetl.inv_num < 1
			OR glob_rec_invoicedetl.line_num < 1) THEN
				#ERROR 
				CALL fgl_winmessage("ERROR Invoice Details","Incomplete invoice details","ERROR") 
			ELSE 
	
			#INSERT invoiceDetl Record
			IF db_invoicedetl_rec_validation(UI_ON,MODE_INSERT,glob_rec_invoicedetl.*) THEN
				INSERT INTO invoicedetl VALUES (glob_rec_invoicedetl.*)		
			ELSE
				DISPLAY glob_rec_invoicedetl.*
				CALL fgl_winmessage("Error","Could not insert new invoiceDetl record","ERROR")
			END IF 

			END IF 
			# UPDATE prodledg IF a real line
			IF glob_rec_invoicedetl.part_code IS NULL 
			OR glob_rec_invoicedetl.part_code = " " 
			OR glob_rec_invoicedetl.ship_qty = 0 THEN 
			ELSE 
				
				INITIALIZE l_rec_prodledg.* TO NULL 
				
				LET l_rec_prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_rec_prodledg.part_code = glob_rec_invoicedetl.part_code 
				LET l_rec_prodledg.ware_code = glob_rec_invoicedetl.ware_code 
				LET l_rec_prodledg.tran_date = glob_rec_invoicehead.inv_date 
				LET l_rec_prodledg.seq_num = glob_rec_invoicedetl.seq_num 
				LET l_rec_prodledg.trantype_ind = "S" 
				LET l_rec_prodledg.year_num = glob_rec_invoicehead.year_num 
				LET l_rec_prodledg.period_num = glob_rec_invoicehead.period_num 
				LET l_rec_prodledg.source_text = glob_rec_invoicedetl.cust_code 
				LET l_rec_prodledg.source_num = glob_rec_invoicedetl.inv_num 
				LET l_rec_prodledg.tran_qty = 0 - glob_rec_invoicedetl.ship_qty + 0 
				LET l_rec_prodledg.bal_amt = glob_rec_prodstatus.onhand_qty 

				IF glob_rec_invoicehead.conv_qty IS NOT NULL THEN 
					IF glob_rec_invoicehead.conv_qty != 0 THEN 
						LET l_rec_prodledg.cost_amt = glob_rec_invoicedetl.unit_cost_amt / 
						glob_rec_invoicehead.conv_qty 
						LET l_rec_prodledg.sales_amt = glob_rec_invoicedetl.unit_sale_amt / 
						glob_rec_invoicehead.conv_qty 
					END IF 
				END IF 

				IF l_rec_inparms.hist_flag = "Y" THEN 
					LET l_rec_prodledg.hist_flag = "N" 
				ELSE 
					LET l_rec_prodledg.hist_flag = "Y" 
				END IF 
				
				LET l_rec_prodledg.post_flag = "N" 
				LET l_rec_prodledg.entry_code = glob_rec_kandoouser.sign_on_code 
				LET l_rec_prodledg.entry_date = today 
				
				INSERT INTO prodledg VALUES (l_rec_prodledg.*)
				 
			END IF 

			CALL find_taxcode(glob_rec_invoicedetl.tax_code) RETURNING l_tax_idx 
			LET glob_arr_rec_taxamt[l_tax_idx].tax_amt = glob_arr_rec_taxamt[l_tax_idx].tax_amt + 
			glob_rec_invoicedetl.ext_tax_amt 
			LET modu_check_mat = modu_check_mat + glob_rec_invoicedetl.ext_sale_amt 
			LET modu_check_cost = modu_check_cost + glob_rec_invoicedetl.ext_cost_amt 
		END FOR 

		CALL find_taxcode(glob_rec_invoicehead.freight_tax_code) RETURNING l_tax_idx 
		LET glob_arr_rec_taxamt[l_tax_idx].tax_amt = 
			glob_arr_rec_taxamt[l_tax_idx].tax_amt +	glob_rec_invoicehead.freight_tax_amt 
		CALL find_taxcode(glob_rec_invoicehead.hand_tax_code) RETURNING l_tax_idx 
		LET glob_arr_rec_taxamt[l_tax_idx].tax_amt = 
			glob_arr_rec_taxamt[l_tax_idx].tax_amt + glob_rec_invoicehead.hand_tax_amt 
		LET l_tax_idx = 1 

		WHILE (l_tax_idx <= 300) AND (glob_arr_rec_taxamt[l_tax_idx].tax_code IS NOT null) 
			LET modu_check_tax = modu_check_tax + glob_arr_rec_taxamt[l_tax_idx].tax_amt 
			LET l_tax_idx = l_tax_idx + 1 
		END WHILE 
		
		IF modu_check_tax != glob_rec_invoicehead.tax_amt OR modu_check_tax IS NULL OR 
		glob_rec_invoicehead.tax_amt IS NULL THEN 
			ERROR " Audit on tax figures NOT correct " 
			CALL errorlog(" A2S - tax total amount incorrect ") 
			CALL display_error() 
			LET l_err_flag = "Y" 

			LET glob_rec_invoicehead.tax_amt = modu_check_tax 
		END IF 
		IF modu_check_mat != glob_rec_invoicehead.goods_amt 
		OR modu_check_mat IS NULL 
		OR glob_rec_invoicehead.goods_amt IS NULL THEN 
			ERROR "Audit on material figures NOT correct" 
			CALL errorlog(" A2S - Material Total Amount Incorrect ") 
			CALL display_error() 
			LET l_err_flag = "Y" 

			LET glob_rec_invoicehead.goods_amt = modu_check_mat 
		END IF 
		IF modu_check_cost != glob_rec_invoicehead.cost_amt 
		OR modu_check_cost IS NULL 
		OR glob_rec_invoicehead.cost_amt IS NULL THEN 
			ERROR " Audit on cost figures NOT correct" 
			CALL errorlog(" A2S - Material Total Cost Incorrect ") 
			CALL display_error() 
			LET l_err_flag = "Y" 

			LET glob_rec_invoicehead.cost_amt = modu_check_cost 
		END IF 

		# write out the invoicehead
		LET glob_rec_invoicehead.line_num = glob_arr_size 
		LET glob_rec_invoicehead.cost_ind = glob_rec_arparms.costings_ind 
		LET l_err_message = "A2S - Unable TO add TO invoice header table" 

		#INSERT invoicehead Record
		IF db_invoicehead_rec_validation(UI_ON,MODE_INSERT,glob_rec_invoicehead.*) THEN
			INSERT INTO invoicehead VALUES (glob_rec_invoicehead.*)			
		ELSE
			DISPLAY glob_rec_invoicehead.*
			CALL fgl_winmessage("Error","Could not insert new invoicehead record","ERROR")
		END IF 

	END IF 

	IF l_err_flag = "Y" THEN 
		ROLLBACK WORK 
		CALL out_stat()
		CALL fgl_winmessage("Fatal Error","Exit Program","ERROR") 
		EXIT PROGRAM 

	END IF 

	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

END FUNCTION 
############################################################
# FUNCTION write_inv()
############################################################


############################################################
# FUNCTION out_stat() 
#
# 
############################################################
FUNCTION out_stat() 
	DEFINE l_ro_num INTEGER 
	DEFINE l_which CHAR(3) 

	LET glob_back_out = 1 
	LET l_ro_num = 0 

	DECLARE statab_curs CURSOR FOR 
	SELECT rowid, statab.* 
	INTO l_ro_num, glob_arr_rec_statab.* 
	FROM statab 
	WHERE rowid > l_ro_num 

	FOREACH statab_curs 
		IF glob_arr_rec_statab.which = TRAN_TYPE_INVOICE_IN THEN 
			LET l_which = "OUT" 
		ELSE 
			LET l_which = TRAN_TYPE_INVOICE_IN 
		END IF 

		DELETE FROM statab 
		WHERE rowid = l_ro_num 
		LET glob_rec_invoicedetl.seq_num = stat_res(glob_arr_rec_statab.company_cmpy_code, glob_arr_rec_statab.ware, 
		glob_arr_rec_statab.part, glob_arr_rec_statab.ship, 
		l_which) 
		OPEN statab_curs 
	END FOREACH 
END FUNCTION 
############################################################
# END FUNCTION out_stat() 
############################################################


############################################################
# FUNCTION display_error()
#
#
############################################################
FUNCTION display_error() 
	DEFINE l_ans CHAR(1)
	DEFINE l_runner CHAR(120) 

	CALL fgl_winmessage("need TO check this","need TO check this\n huho ref 001","info") 
	LET l_runner = "echo ' Error Occurred in Invoice Number :", 
	glob_rec_invoicehead.inv_num,"'>> ", trim(get_settings_logFile()) 
	RUN l_runner 

	LET l_runner = "echo ' Invoice Tax :", 
	glob_rec_invoicehead.tax_amt,"'>> ", trim(get_settings_logFile()) 
	RUN l_runner 

	LET l_runner = "echo ' Audit Check Tax :",modu_check_tax,"'>> ", trim(get_settings_logFile()) 
	RUN l_runner 

	LET l_runner = "echo ' Invoice Materials :", 
	glob_rec_invoicehead.goods_amt,"'>> ", trim(get_settings_logFile()) 
	RUN l_runner 

	LET l_runner = "echo ' Audit Check Materials :",modu_check_mat,"'>> ", trim(get_settings_logFile()) 
	RUN l_runner 

	LET l_runner = "echo ' Invoice Costs :", 
	glob_rec_invoicehead.cost_amt,"'>> ", trim(get_settings_logFile()) 
	RUN l_runner 

	LET l_runner = "echo ' Audit Check Costs :",modu_check_cost,"'>> ", trim(get_settings_logFile()) 
	RUN l_runner 

	ERROR " An Audit Check Error has Occurred - Check ", trim(get_settings_logFile()) 
	CALL eventsuspend() 

	LET int_flag = false 
	LET quit_flag = false 
END FUNCTION 
############################################################
# END FUNCTION display_error()
############################################################


############################################################
# FUNCTION stat_res(p_cmpy_code,p_warehouse_code,p_prod_id,p_value,p_which)
#
### a FUNCTION TO handle all warehouse STATUS changes TO be used
### WHERE ever AND WHEN ever required TO reserve stock
############################################################
FUNCTION stat_res(p_cmpy_code,p_warehouse_code,p_prod_id,p_value,p_which) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_warehouse_code CHAR(3) 
	DEFINE p_prod_id CHAR(15) 
	DEFINE p_value FLOAT 
	DEFINE p_which CHAR(3) 
	DEFINE l_sequence INTEGER 
	DEFINE l_err_continue CHAR(1) 
	DEFINE l_err_message CHAR(30) 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 

	IF p_prod_id IS NULL OR p_value = 0 THEN 
	ELSE 
		GOTO bypass 

		LABEL recovery: 
		LET l_err_message = "A2S Itemstat Update" 
		LET l_err_continue = error_recover(l_err_message, status) 
		IF l_err_continue != "Y" THEN 
			CALL errorlog("A2S Itemstat Adjustment NOT done") 
			EXIT PROGRAM 
		END IF 

		LABEL bypass: 
		BEGIN WORK 
			WHENEVER ERROR GOTO recovery 

			DECLARE psr_curs CURSOR FOR 
			SELECT * 
			INTO l_rec_prodstatus.* 
			FROM prodstatus 
			WHERE part_code = p_prod_id 
			AND ware_code = p_warehouse_code 
			AND cmpy_code = p_cmpy_code 
			FOR UPDATE 

			FOREACH psr_curs 
				LET l_rec_prodstatus.seq_num = l_rec_prodstatus.seq_num + 1 
				LET l_sequence = l_rec_prodstatus.seq_num 
				IF l_rec_prodstatus.reserved_qty IS NULL THEN 
					LET l_rec_prodstatus.reserved_qty = 0 
				END IF 

				#-------------------------------------------
				# do NOT adjust onhnd VALUES FOR non-stocked inventory items
				IF l_rec_prodstatus.stocked_flag = "Y" THEN 
					IF p_which = TRAN_TYPE_INVOICE_IN THEN 
						LET l_rec_prodstatus.reserved_qty = l_rec_prodstatus.reserved_qty - 
						p_value 
					ELSE 
						LET l_rec_prodstatus.reserved_qty = l_rec_prodstatus.reserved_qty + 
						p_value 
					END IF 
				END IF 

				UPDATE prodstatus 
				SET reserved_qty = l_rec_prodstatus.reserved_qty, 
				seq_num = l_rec_prodstatus.seq_num 
				WHERE CURRENT OF psr_curs 
			END FOREACH 
			#-----------------------------------
			# INSERT INTO statab FOR backout purposes
			IF glob_back_out = 0 THEN 
				INSERT INTO statab VALUES (p_cmpy_code, p_warehouse_code, 
				p_prod_id, p_value, 
				p_which ) 
			END IF 
		COMMIT WORK 
		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	END IF 

	RETURN(l_sequence) 
END FUNCTION 
############################################################
# END FUNCTION stat_res(p_cmpy_code,p_warehouse_code,p_prod_id,p_value,p_which)
############################################################


############################################################
# REPORT AS2F_rpt_list_invoice(p_cust_code, p_name_text, p_inv_num) 
#
#
############################################################
REPORT AS2F_rpt_list_invoice(p_rpt_idx,p_cust_code, p_name_text, p_inv_num) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_cust_code LIKE invoicehead.cust_code
	DEFINE p_name_text LIKE invoicehead.name_text
	DEFINE p_inv_num LIKE invoicehead.inv_num 

	OUTPUT 

	FORMAT 
		PAGE HEADER
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			SKIP 4 LINES 
	
			PRINT COLUMN 50, "CUSTOMERS INVOICE LIST" 
			SKIP 2 LINES 
	
			PRINT COLUMN 7, "Customer Code", 
			COLUMN 33, "Name", 
			COLUMN 52, "Invoice Number" 
			SKIP 1 line 
	
			PRINT COLUMN 5, "----------------------------------------------------------------------------------------------------" 

		ON EVERY ROW 
			PRINT COLUMN 10, p_cust_code, 
			COLUMN 20, p_name_text, 
			COLUMN 50, p_inv_num 

		ON LAST ROW 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = pageno		
			--PRINT COLUMN 38, "--=== END OF REPORT ===--" 
END REPORT 
############################################################
# END REPORT AS2F_rpt_list_invoice(p_cust_code, p_name_text, p_inv_num) 
############################################################