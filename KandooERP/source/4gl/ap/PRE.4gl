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
# \brief module : PRE - Creditor Funds Employed Report
# Purpose : Summary Account Aging of Vendors Aged Balances which encompasses
#           the value of goods received against purchase orders but NOT yet
#           vouchered.
#
#           Any undistributed vouchers of debits AND any unapplied cheques
#           will be listed AT the END of the REPORT.
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
############################################################
# GLOBAL SCOPE
############################################################
GLOBALS
	DEFINE glob_base_curr_code LIKE glparms.base_currency_code
	DEFINE glob_seg_text CHAR(500)
	DEFINE glob_age_date DATE 
	DEFINE glob_x1,glob_x2 SMALLINT
	DEFINE glob_y1,glob_y2 SMALLINT
END GLOBALS

############################################################
# MAIN
#
#
############################################################
MAIN 
	DEFINE l_msgresp LIKE language.yes_flag 

	#Initial UI Init
	CALL setModuleId("PRE") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	SELECT base_currency_code INTO glob_base_curr_code FROM glparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_code = "1" 
	IF status = NOTFOUND THEN 
		LET l_msgresp=kandoomsg("A",5001,"") 
		#5001 General Ledger Parameters NOT SET up; Refer menu GZP.
		EXIT PROGRAM 
	END IF 
	CREATE temp TABLE f_document (acct_code CHAR(18), 
	segment1 CHAR(18), 
	segment2 CHAR(18), 
	trans_type CHAR(2), 
	days_num INTEGER, 
	curr_code CHAR(3), 
	conv_qty FLOAT, 
	total_amt money(12,2), 
	unpaid_amt money(12,2), 
	curr_amt money(12,2), 
	over1_amt money(12,2), 
	over30_amt money(12,2), 
	over60_amt money(12,2), 
	over90_amt money(12,2), 
	received_amt money(12,2)) with no LOG 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	
			OPEN WINDOW P514 with FORM "P514" 
			CALL windecoration_p("P514") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

			LET glob_age_date = today 
			DISPLAY glob_age_date TO age_date 

			MENU " Creditor Funds Employed Report" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","PRE","menu-creditor_funds-1") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
					CALL rpt_rmsreps_reset(NULL)
					CALL PRE_rpt_process(PRE_rpt_query()) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON ACTION "Report"			#      COMMAND "Run" " SELECT criteria AND PRINT REPORT"
					CALL rpt_rmsreps_reset(NULL)
					CALL PRE_rpt_process(PRE_rpt_query()) 

				ON ACTION "Print"				#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog ("URS","","","","") 

				ON ACTION "CANCEL"					#COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
					EXIT MENU 

			END MENU 

			CLOSE WINDOW P514 

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL PRE_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW P514 with FORM "P514" 
			CALL windecoration_p("P514") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(PRE_rpt_query()) #save where clause in env 
			CLOSE WINDOW P514 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL PRE_rpt_process(get_url_sel_text())
	END CASE 
	
END MAIN 


############################################################
# FUNCTION PRE_rpt_query()
#
#
############################################################
FUNCTION PRE_rpt_query() 
	DEFINE l_where_text STRING

	CLEAR FORM 
	DISPLAY glob_age_date TO age_date 

	MESSAGE kandoomsg2("P",1522,"")	#1522 Enter Aging Date; OK TO continue.
	INPUT glob_age_date WITHOUT DEFAULTS FROM age_date 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","PRE","inp-age_date-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD age_date 
			IF not(int_flag OR quit_flag) 
			AND glob_age_date IS NULL THEN 
				ERROR kandoomsg2("P",9513,"")		#9513 Aging Date must be entered.
				LET glob_age_date = today 
				NEXT FIELD age_date 
			END IF 

	END INPUT 

	IF (int_flag OR quit_flag) THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	
	MESSAGE kandoomsg2("U",1001,"") #1001 Enter selection criteria;  OK TO continue.
	CONSTRUCT BY NAME l_where_text ON vendor.vend_code, 
	vendor.name_text, 
	vendor.addr1_text, 
	vendor.addr2_text, 
	vendor.addr3_text, 
	vendor.city_text, 
	vendor.state_code, 
	vendor.post_code, 
	vendor.country_code, 
	vendor.type_code, 
	vendor.currency_code, 
	vendor.term_code, 
	vendor.tax_code, 
	vendor.drop_flag, 
	vendor.tax_text, 
	vendor.our_acct_code, 
	vendor.contact_text, 
	vendor.tele_text, 
	vendor.extension_text, 
	vendor.fax_text 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","PRE","construct-vendor-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL 
	ELSE
		# get gl selection criterion
		LET glob_rec_rpt_selector.ref1_date = glob_age_date 
		LET glob_rec_rpt_selector.sel_option1 = segment_con(glob_rec_kandoouser.cmpy_code,"voucherdist")
		RETURN l_where_text
	END IF	
END FUNCTION 



############################################################
# FUNCTION PRE_rpt_process(p_where_text)
#
#
############################################################
FUNCTION PRE_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_rpt_idx SMALLINT  #report array index
	DEFINE l_tmp_str STRING
	DEFINE l_rec_document RECORD 
		acct_code LIKE voucherdist.acct_code, 
		segment1 LIKE coa.acct_code, 
		segment2 LIKE coa.acct_code, 
		trans_type LIKE araudit.tran_type_ind, 
		days_num INTEGER, 
		curr_code LIKE voucher.currency_code, 
		conv_qty LIKE voucher.conv_qty, 
		trans_amt LIKE voucher.total_amt, 
		unpaid_amt LIKE voucher.paid_amt, 
		curr_amt LIKE vendor.curr_amt, 
		over1_amt LIKE vendor.over1_amt, 
		over30_amt LIKE vendor.over30_amt, 
		over60_amt LIKE vendor.over60_amt, 
		over90_amt LIKE vendor.over90_amt, 
		received_amt LIKE vendor.over90_amt 
	END RECORD 
	DEFINE l_rec_voucher RECORD 
		currency_code LIKE vendor.currency_code, 
		vouch_code LIKE voucher.vouch_code, 
		vouch_date LIKE voucher.vouch_date, 
		due_date LIKE voucher.due_date, 
		total_amt LIKE voucher.total_amt, 
		paid_amt LIKE voucher.paid_amt, 
		dist_amt LIKE voucher.dist_amt, 
		conv_qty LIKE voucher.conv_qty 
	END RECORD 
	DEFINE l_rec_voucherdist RECORD LIKE voucherdist.*
	DEFINE l_rec_debithead RECORD LIKE debithead.*
	DEFINE l_rec_debitdist RECORD LIKE debitdist.*
	DEFINE l_rec_cheque RECORD LIKE cheque.* 
	DEFINE l_rec_purchdetl RECORD LIKE purchdetl.* 
	DEFINE l_rec_poaudit RECORD LIKE poaudit.*
	DEFINE l_rec_structure RECORD LIKE structure.*
	DEFINE l_query_text CHAR(2200)
	DEFINE l_unpaid_per FLOAT
	DEFINE l_unapply_flag SMALLINT
	DEFINE l_exist_flag SMALLINT
	DEFINE l_continue_flag SMALLINT
	DEFINE l_counter SMALLINT 
	DEFINE l_order_num LIKE purchhead.order_num
	DEFINE l_order_conv_qty LIKE purchhead.conv_qty
	DEFINE l_order_line_num LIKE purchdetl.line_num
	DEFINE l_order_acct_code LIKE purchdetl.acct_code 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"PRE_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT PRE_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------
	#Case specific rems_reps works...
	LET glob_age_date = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_date
	LET glob_seg_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_option1

	LET l_tmp_str = "Aging FROM: ", glob_age_date USING "dd/mm/yy"
	CALL rpt_set_header_footer_line_2_append(l_rpt_idx,NULL, l_tmp_str)
	#------------------------------------------------------------

	
	LET l_continue_flag = true 
	IF glob_seg_text = " AND 1=1" THEN 
		LET l_unapply_flag = true 
	ELSE 
		LET l_unapply_flag = false # undistribued AND unvouchered info TO be 
		# produced.
	END IF 
	LET l_query_text = "SELECT unique(1) FROM vendor ", 
	"WHERE vendor.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND ",p_where_text clipped 
	PREPARE s_vendor FROM l_query_text 
	DECLARE c_vendor CURSOR FOR s_vendor 
	OPEN c_vendor 
	FETCH c_vendor INTO l_exist_flag 

	# Need TO do something about GL segments
	DECLARE x_curs CURSOR FOR 
	SELECT * INTO l_rec_structure.* FROM structure 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND start_num > 0 
	AND (type_ind = "S" OR type_ind = "L") 
	ORDER BY start_num 
	OPEN x_curs 
	FETCH x_curs INTO l_rec_structure.* 
	LET glob_x1 = l_rec_structure.start_num 
	LET glob_y1 = l_rec_structure.start_num + l_rec_structure.length_num -1 
	FETCH NEXT x_curs INTO l_rec_structure.* 
	IF status = NOTFOUND THEN 
		LET glob_x2 = glob_x1 
		LET glob_y2 = glob_y1 
	ELSE 
		LET glob_x2 = l_rec_structure.start_num 
		LET glob_y2 = l_rec_structure.start_num + l_rec_structure.length_num -1 
	END IF 

	## Program requires 7 cursors
	## 1. Vouchers
	LET l_query_text = "SELECT voucher.currency_code,", 
	"vouch_code,", 
	"vouch_date,", 
	"due_date,", 
	"total_amt,", 
	"paid_amt,", 
	"dist_amt,", 
	"voucher.conv_qty ", 
	"FROM voucher,", 
	"vendor ", 
	"WHERE vendor.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND voucher.vend_code = vendor.vend_code ", 
	"AND voucher.cmpy_code = vendor.cmpy_code ", 
	"AND voucher.total_amt != voucher.paid_amt ", 
	"AND voucher.total_amt != 0 ", 
	"AND ",p_where_text clipped 
	PREPARE s_voucher FROM l_query_text 
	DECLARE c_voucher CURSOR FOR s_voucher 

	## 2. voucherdist
	LET l_query_text = "SELECT * FROM voucherdist ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND vouch_code = ? ",glob_seg_text 
	PREPARE s_voucherdist FROM l_query_text 
	DECLARE c_voucherdist CURSOR FOR s_voucherdist 

	## 3. Purchase orders
	LET l_query_text = "SELECT order_num,conv_qty ", 
	"FROM purchhead,", 
	"vendor ", 
	"WHERE vendor.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND purchhead.vend_code = vendor.vend_code ", 
	"AND purchhead.cmpy_code = vendor.cmpy_code ", 
	"AND purchhead.status_ind != 'C'", 
	"AND ",p_where_text clipped 
	PREPARE s_purchhead FROM l_query_text 
	DECLARE c_purchhead CURSOR FOR s_purchhead 

	## 4. Unvouchered purchase ORDER lines
	FOR l_counter = 1 TO length(glob_seg_text) 
		IF glob_seg_text[l_counter,l_counter+10] = "voucherdist" THEN 
			LET glob_seg_text[l_counter,l_counter+10] = " purchdetl" 
		END IF 
	END FOR 
	LET l_query_text = "SELECT line_num, acct_code FROM purchdetl ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND order_num = ? ",glob_seg_text 
	PREPARE s_purchdetl FROM l_query_text 
	DECLARE c_purchdetl CURSOR FOR s_purchdetl 

	## 5. Undistributed debits
	LET l_query_text = "SELECT debithead.currency_code,", 
	"debit_num,", 
	"total_amt,", 
	"apply_amt,", 
	"dist_amt,", 
	"conv_qty ", 
	"FROM debithead, vendor ", 
	"WHERE vendor.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND debithead.vend_code = vendor.vend_code ", 
	"AND debithead.cmpy_code = vendor.cmpy_code ", 
	"AND debithead.total_amt != debithead.apply_amt ", 
	"AND debithead.total_amt != 0 ", 
	"AND ",p_where_text clipped 
	PREPARE s_debithead FROM l_query_text 
	DECLARE c_debithead CURSOR FOR s_debithead 

	## 6. Distributed debit lines
	FOR l_counter = 1 TO length(glob_seg_text) 
		IF glob_seg_text[l_counter,l_counter+8] = "purchdetl" THEN 
			LET glob_seg_text[l_counter,l_counter+8] = "debitdist" 
		END IF 
	END FOR 
	LET l_query_text = "SELECT * FROM debitdist ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND debit_code = ? ",glob_seg_text 
	PREPARE s_debitdist FROM l_query_text 
	DECLARE c_debitdist CURSOR FOR s_debitdist 

	IF l_unapply_flag THEN 
		## 7. Unapplied cheques
		FOR l_counter = 1 TO length(glob_seg_text) 
			IF glob_seg_text[l_counter,l_counter+8] = "debitdist" THEN 
				LET glob_seg_text[l_counter,l_counter+8] = " cheque" 
			END IF 
		END FOR 
		LET l_query_text ="SELECT cheq_code,", 
		"cheq_date,", 
		"cheque.currency_code,", 
		"conv_qty,", 
		"pay_amt,", 
		"apply_amt ", 
		"FROM cheque, vendor ", 
		"WHERE cheque.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		" AND vendor.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND vendor.vend_code = cheque.vend_code ", 
		"AND (apply_amt != pay_amt OR apply_amt IS NULL) ", 
		"AND ", p_where_text clipped, " " 
		PREPARE s_cheque FROM l_query_text 
		DECLARE c_cheque CURSOR FOR s_cheque 
	END IF 

	DELETE FROM f_document WHERE 1=1 
	INITIALIZE l_rec_document.* TO NULL 
	LET l_counter = 0 
	
	OPEN c_voucher 
	FOREACH c_voucher INTO l_rec_voucher.* 
		#---------------------------------------------------------
		IF NOT rpt_int_flag_handler2("Voucher:",l_rec_voucher.vouch_code, NULL,l_rpt_idx) THEN
			LET l_continue_flag = false
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------
	
		LET l_counter = l_counter + 1 
		#common TO all voucher lines
		LET l_rec_document.trans_type = "VO" 
		LET l_rec_document.days_num = glob_age_date 
		- l_rec_voucher.due_date 
		LET l_rec_document.curr_code = l_rec_voucher.currency_code 
		LET l_rec_document.conv_qty = l_rec_voucher.conv_qty 
		LET l_rec_document.received_amt = 0 
		IF l_rec_voucher.paid_amt IS NULL THEN 
			LET l_rec_voucher.paid_amt = 0 
		END IF 
		LET l_unpaid_per = (l_rec_voucher.total_amt - l_rec_voucher.paid_amt) 
		/ l_rec_voucher.total_amt 
		OPEN c_voucherdist USING l_rec_voucher.vouch_code 
		FOREACH c_voucherdist INTO l_rec_voucherdist.* 
			IF l_rec_voucherdist.type_ind = "P" THEN 
				SELECT acct_code INTO l_order_acct_code 
				FROM purchdetl 
				WHERE order_num = l_rec_voucherdist.po_num 
				AND line_num = l_rec_voucherdist.po_line_num 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_rec_document.acct_code = l_order_acct_code 
			ELSE 
				LET l_rec_document.acct_code = l_rec_voucherdist.acct_code 
			END IF 
			LET l_rec_document.segment1 = l_rec_document.acct_code[glob_x1,glob_y1] 
			LET l_rec_document.segment2 = l_rec_document.acct_code[glob_x2,glob_y2] 
			IF l_rec_document.segment1 IS NULL THEN 
				LET l_rec_document.segment1 = "zz" # unknown 
				LET l_rec_document.segment2 = "za" # unknown 
			END IF 
			LET l_rec_document.trans_amt = l_rec_voucherdist.dist_amt 
			LET l_rec_document.unpaid_amt = l_rec_voucherdist.dist_amt * l_unpaid_per
			 
			INSERT INTO f_document VALUES (l_rec_document.*)
			 
		END FOREACH
		 
		IF l_unapply_flag THEN 
			LET l_rec_document.segment1 = "zz" # unknown 
			LET l_rec_document.segment2 = "zb" # unknown 
			LET l_rec_document.acct_code = "" 
			LET l_rec_document.trans_type = "UV" # undistributed voucher 
			LET l_rec_document.trans_amt = l_rec_voucher.total_amt - l_rec_voucher.dist_amt 
			LET l_rec_document.unpaid_amt = l_rec_document.trans_amt * l_unpaid_per 
			LET l_rec_document.received_amt = 0
			 
			INSERT INTO f_document VALUES (l_rec_document.*)
			 
		END IF 
	END FOREACH 
	
	IF l_counter = 0 
	AND l_unapply_flag 
	AND l_exist_flag THEN 
		LET l_rec_document.days_num = 0 
		LET l_rec_document.segment1 = "zz" # unknown 
		LET l_rec_document.segment2 = "zb" # unknown 
		LET l_rec_document.trans_type = "UV" 
		LET l_rec_document.trans_amt = 0 
		LET l_rec_document.unpaid_amt = 0 
		LET l_rec_document.received_amt = 0 
		LET l_rec_document.conv_qty = 1 
		INSERT INTO f_document VALUES (l_rec_document.*) 
	END IF 

	IF l_continue_flag THEN 
		INITIALIZE l_rec_document.* TO NULL 
		OPEN c_purchhead
		 
		FOREACH c_purchhead INTO l_order_num, l_order_conv_qty

			#---------------------------------------------------------
			IF NOT rpt_int_flag_handler2("Purchase Order:",l_order_num, NULL,l_rpt_idx) THEN
				LET l_continue_flag = false 
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------
		 
			#common TO all purchase ORDER lines
			LET l_rec_document.days_num = 0 
			LET l_rec_document.curr_code = "" 
			LET l_rec_document.conv_qty = l_order_conv_qty 
			OPEN c_purchdetl USING l_order_num
			 
			FOREACH c_purchdetl INTO l_order_line_num, l_order_acct_code 
				CALL po_line_info(glob_rec_kandoouser.cmpy_code, 
				l_order_num, 
				l_order_line_num) 
				RETURNING l_rec_poaudit.order_qty, 
				l_rec_poaudit.received_qty, 
				l_rec_poaudit.voucher_qty, 
				l_rec_poaudit.unit_cost_amt, 
				l_rec_poaudit.ext_cost_amt, 
				l_rec_poaudit.unit_tax_amt, 
				l_rec_poaudit.ext_tax_amt, 
				l_rec_poaudit.line_total_amt 
				IF (l_rec_poaudit.received_qty - l_rec_poaudit.voucher_qty) > 0 THEN 
					LET l_rec_document.trans_type = "VO" #to appear with vouchers 
					LET l_rec_document.acct_code = l_order_acct_code 
					LET l_rec_document.segment1 = l_order_acct_code[glob_x1,glob_y1] 
					LET l_rec_document.segment2 = l_order_acct_code[glob_x2,glob_y2] 
					IF l_rec_document.segment1 IS NULL THEN 
						LET l_rec_document.segment1 = "zz" # unknown 
						LET l_rec_document.segment2 = "za" # unknown 
					END IF 
					LET l_rec_document.trans_amt = (l_rec_poaudit.received_qty 
					- l_rec_poaudit.voucher_qty) 
					* l_rec_poaudit.unit_cost_amt 
					/ l_order_conv_qty 
					LET l_rec_document.received_amt = l_rec_document.trans_amt 
					LET l_rec_document.unpaid_amt = l_rec_document.trans_amt 
					INSERT INTO f_document VALUES (l_rec_document.*) 
				END IF 
				
			END FOREACH 
			
		END FOREACH 
		
	END IF 

	IF l_continue_flag THEN 
		INITIALIZE l_rec_document.* TO NULL 
		LET l_counter = 0 
		OPEN c_debithead 
		
		FOREACH c_debithead INTO l_rec_debithead.currency_code, 
			l_rec_debithead.debit_num, 
			l_rec_debithead.total_amt, 
			l_rec_debithead.apply_amt, 
			l_rec_debithead.dist_amt, 
			l_rec_debithead.conv_qty 

			#---------------------------------------------------------
			IF NOT rpt_int_flag_handler2("Debit:",l_rec_debithead.debit_num, NULL,l_rpt_idx) THEN
				LET l_continue_flag = false 
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------
			
			LET l_counter = l_counter + 1 
			LET l_rec_document.trans_type = "VO" 
			LET l_rec_document.days_num = 0 
			
			# Amount needs TO appear in current as per PR1!
			LET l_rec_document.curr_code = l_rec_debithead.currency_code 
			LET l_rec_document.conv_qty = l_rec_debithead.conv_qty 
			LET l_rec_document.received_amt = 0 
			IF l_rec_debithead.apply_amt IS NULL THEN 
				LET l_rec_debithead.apply_amt = 0 
			END IF 
			LET l_unpaid_per = (l_rec_debithead.total_amt - l_rec_debithead.apply_amt) 			/ l_rec_debithead.total_amt 
			OPEN c_debitdist USING l_rec_debithead.debit_num 
			FOREACH c_debitdist INTO l_rec_debitdist.* 
				IF l_rec_debitdist.type_ind = "P" THEN 
					SELECT acct_code INTO l_order_acct_code 
					FROM purchdetl 
					WHERE order_num = l_rec_debitdist.po_num 
					AND line_num = l_rec_debitdist.po_line_num 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET l_rec_document.acct_code = l_order_acct_code 
				ELSE 
					LET l_rec_document.acct_code = l_rec_debitdist.acct_code 
				END IF 
				LET l_rec_document.segment1 = l_rec_document.acct_code[glob_x1,glob_y1] 
				LET l_rec_document.segment2 = l_rec_document.acct_code[glob_x2,glob_y2] 
				IF l_rec_document.segment1 IS NULL THEN 
					LET l_rec_document.segment1 = "zz" # unknown 
					LET l_rec_document.segment2 = "za" # unknown 
				END IF 
				LET l_rec_document.trans_amt = 0 - l_rec_debitdist.dist_amt 
				LET l_rec_document.unpaid_amt = l_rec_document.trans_amt * l_unpaid_per 
				INSERT INTO f_document VALUES (l_rec_document.*) 
			END FOREACH 
			
			IF l_unapply_flag THEN 
				LET l_rec_document.segment1 = "zz" # unknown 
				LET l_rec_document.segment2 = "zb" # unknown 
				LET l_rec_document.acct_code = "" 
				LET l_rec_document.trans_type = "UD" # undistributed debit 
				LET l_rec_document.trans_amt = 0 - (l_rec_debithead.total_amt 
				- l_rec_debithead.dist_amt) 
				LET l_rec_document.unpaid_amt = l_rec_document.trans_amt * l_unpaid_per 
				LET l_rec_document.received_amt = 0 
				INSERT INTO f_document VALUES (l_rec_document.*) 
			END IF 
		END FOREACH 
		
		IF l_counter = 0 
		AND l_exist_flag THEN 
			LET l_rec_document.days_num = 0 
			LET l_rec_document.segment1 = "zz" # unknown 
			LET l_rec_document.segment2 = "zb" # unknown 
			LET l_rec_document.trans_type = "UD" 
			LET l_rec_document.trans_amt = 0 
			LET l_rec_document.unpaid_amt = 0 
			LET l_rec_document.received_amt = 0 
			LET l_rec_document.conv_qty = 0 
			INSERT INTO f_document VALUES (l_rec_document.*) 
		END IF 
	END IF 

	IF l_unapply_flag 
	AND l_continue_flag THEN 
		INITIALIZE l_rec_document.* TO NULL 
		LET l_counter = 0 
		OPEN c_cheque 
		FOREACH c_cheque INTO l_rec_cheque.cheq_code, 
			l_rec_cheque.cheq_date, 
			l_rec_cheque.currency_code, 
			l_rec_cheque.conv_qty, 
			l_rec_cheque.pay_amt, 
			l_rec_cheque.apply_amt

			#---------------------------------------------------------
			IF NOT rpt_int_flag_handler2("Cheque:",l_rec_cheque.cheq_code, NULL,l_rpt_idx) THEN
				LET l_continue_flag = false 
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------

			 
			LET l_counter = l_counter + 1 
			LET l_rec_document.acct_code = " " 
			LET l_rec_document.segment1 = "zz" # unknown 
			LET l_rec_document.segment2 = "zb" 
			LET l_rec_document.trans_type = "UC" 
			LET l_rec_document.days_num = 0 

			# Amount needs TO appear in current as per PR1!
			LET l_rec_document.curr_code = l_rec_cheque.currency_code 
			LET l_rec_document.conv_qty = l_rec_cheque.conv_qty 
			LET l_rec_document.trans_amt = 0 - l_rec_cheque.pay_amt 
			LET l_rec_document.unpaid_amt = l_rec_cheque.apply_amt - l_rec_cheque.pay_amt 
			LET l_rec_document.received_amt = 0 

			INSERT INTO f_document VALUES (l_rec_document.*) 

		END FOREACH 

		IF l_counter = 0 
		AND l_exist_flag THEN 
			LET l_rec_document.days_num = 0 
			LET l_rec_document.segment1 = "zz" # unknown 
			LET l_rec_document.segment2 = "zb" # unknown 
			LET l_rec_document.trans_type = "UC" 
			LET l_rec_document.trans_amt = 0 
			LET l_rec_document.unpaid_amt = 0 
			LET l_rec_document.received_amt = 0 
			LET l_rec_document.conv_qty = 1 

			INSERT INTO f_document VALUES (l_rec_document.*) 

		END IF 
	END IF 

	IF l_continue_flag THEN 
		IF l_unapply_flag THEN 
			FOR l_counter = 1 TO length(glob_seg_text) 
				IF glob_seg_text[l_counter,l_counter+9] = " cheque" THEN 
					LET glob_seg_text[l_counter,l_counter+9] = "f_document" 
				END IF 
			END FOR 
		ELSE 
			FOR l_counter = 1 TO length(glob_seg_text) 
				IF glob_seg_text[l_counter,l_counter+9] = " debitdist" THEN 
					LET glob_seg_text[l_counter,l_counter+9] = "f_document" 
				END IF 
			END FOR 
		END IF 

		LET l_query_text = "SELECT * FROM f_document ", 
		"WHERE 1=1 ", glob_seg_text, " ", 
		"ORDER BY trans_type desc, segment1, segment2 " 

		PREPARE s_fdocument FROM l_query_text 
		DECLARE c_fdocument CURSOR FOR s_fdocument 

		FOREACH c_fdocument INTO l_rec_document.* 

			#---------------------------------------------------------
			IF NOT rpt_int_flag_handler2("Segment:",l_rec_document.segment1, l_rec_document.segment2,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------
	
			LET l_rec_document.curr_amt = 0 
			LET l_rec_document.over1_amt = 0 
			LET l_rec_document.over30_amt = 0 
			LET l_rec_document.over60_amt = 0 
			LET l_rec_document.over90_amt = 0 

			CASE 
				WHEN l_rec_document.days_num > 90 
					LET l_rec_document.over90_amt = l_rec_document.unpaid_amt 
				WHEN l_rec_document.days_num > 60 
					LET l_rec_document.over60_amt = l_rec_document.unpaid_amt 
				WHEN l_rec_document.days_num > 30 
					LET l_rec_document.over30_amt = l_rec_document.unpaid_amt 
				WHEN l_rec_document.days_num > 0 
					LET l_rec_document.over1_amt = l_rec_document.unpaid_amt 
				OTHERWISE 
					IF l_rec_document.received_amt = 0 THEN 
						LET l_rec_document.curr_amt = l_rec_document.unpaid_amt 
					END IF 
			END CASE 

			#---------------------------------------------------------
			OUTPUT TO REPORT PR1_rpt_list(l_rpt_idx,
			l_rec_document.*)  
			IF NOT rpt_int_flag_handler2("Account/Transaction:",l_rec_document.acct_code, l_rec_document.trans_type,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------

		END FOREACH 
	END IF 

	#------------------------------------------------------------
	FINISH REPORT PRE_rpt_list
	CALL rpt_finish("PRE_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = FALSE 
		ERROR " Printing was aborted" 
		RETURN FALSE 
	ELSE 
		RETURN TRUE 
	END IF 	

END FUNCTION


############################################################
# REPORT PRE_rpt_list(p_rpt_idx,p_rec_document) 
#
#
############################################################
REPORT PRE_rpt_list(p_rpt_idx,p_rec_document) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	 
	DEFINE p_rec_document RECORD 
		acct_code LIKE voucherdist.acct_code, 
		segment1 LIKE coa.acct_code, 
		segment2 LIKE coa.acct_code, 
		trans_type LIKE araudit.tran_type_ind, 
		days_num INTEGER, 
		curr_code LIKE voucher.currency_code, 
		conv_qty LIKE voucher.conv_qty, 
		trans_amt LIKE voucher.total_amt, 
		unpaid_amt LIKE voucher.paid_amt, 
		curr_amt LIKE vendor.curr_amt, 
		over1_amt LIKE vendor.over1_amt, 
		over30_amt LIKE vendor.over30_amt, 
		over60_amt LIKE vendor.over60_amt, 
		over90_amt LIKE vendor.over90_amt, 
		received_amt LIKE vendor.over90_amt 
	END RECORD
	DEFINE l_rec_validflex RECORD LIKE validflex.*


	OUTPUT 

	ORDER external BY p_rec_document.trans_type desc, 
	p_rec_document.segment1, 
	p_rec_document.segment2 

	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text
			 			
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
		
			--PRINT COLUMN 2, "Aging Date:", 
			--COLUMN 14, glob_age_date USING "dd/mm/yyyy"; 
			--PRINT glob_rec_kandooreport.line2_text clipped 

		BEFORE GROUP OF p_rec_document.segment1 
			IF p_rec_document.trans_type = "VO" THEN 
				IF p_rec_document.segment1 = "zz" THEN 
					IF p_rec_document.segment2 = "za" THEN 
						PRINT COLUMN 06, "UNASSIGNED TRANSACTIONS" 
					END IF 
				ELSE 
					SELECT desc_text INTO l_rec_validflex.desc_text FROM validflex 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND start_num = glob_x1 
					AND flex_code = p_rec_document.segment1 
					IF status = NOTFOUND THEN 
						LET l_rec_validflex.desc_text = "** UNKNOWN ** " 
					END IF 
					PRINT COLUMN 01, p_rec_document.segment1 clipped, 
					COLUMN 04, "-", 
					COLUMN 06, l_rec_validflex.desc_text 
				END IF 
			END IF 

		BEFORE GROUP OF p_rec_document.segment2 
			IF p_rec_document.trans_type = "VO" THEN 
				NEED 2 LINES 
				IF p_rec_document.segment2 = "za" THEN 
					PRINT COLUMN 11, "VOUCHERS" 
				ELSE 
					SELECT desc_text INTO l_rec_validflex.desc_text FROM validflex 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND start_num = glob_x2 
					AND flex_code = p_rec_document.segment2 
					IF status = NOTFOUND THEN 
						LET l_rec_validflex.desc_text = "** UNKNOWN ** " 
					END IF 
					PRINT COLUMN 05, p_rec_document.segment2 clipped, 
					COLUMN 09, "-", 
					COLUMN 11, l_rec_validflex.desc_text 
				END IF 
			END IF 

		AFTER GROUP OF p_rec_document.trans_type 
			IF p_rec_document.trans_type = "VO" THEN 
			ELSE 
				NEED 2 LINES 
				PRINT 
				IF p_rec_document.trans_type = "UV" THEN 
					PRINT COLUMN 01, "Undistributed Vouchers"; 
				ELSE 
					IF p_rec_document.trans_type = "UD" THEN 
						PRINT COLUMN 01, "Undistributed Debits"; 
					ELSE 
						PRINT COLUMN 01, "Unapplied Cheques"; 
					END IF 
				END IF 
				PRINT COLUMN 25, GROUP sum(p_rec_document.unpaid_amt/ 
				p_rec_document.conv_qty) USING "-----,--&.&&", 
				COLUMN 41, GROUP sum(p_rec_document.curr_amt/ 
				p_rec_document.conv_qty) USING "-----,--&.&&", 
				COLUMN 57, GROUP sum(p_rec_document.over1_amt/ 
				p_rec_document.conv_qty) USING "-----,--&.&&", 
				COLUMN 73, GROUP sum(p_rec_document.over30_amt/ 
				p_rec_document.conv_qty) USING "-----,--&.&&", 
				COLUMN 89,group sum(p_rec_document.over60_amt/ 
				p_rec_document.conv_qty) USING "-----,--&.&&", 
				COLUMN 105,group sum(p_rec_document.over90_amt/ 
				p_rec_document.conv_qty) USING "-----,--&.&&" 
			END IF 

		AFTER GROUP OF p_rec_document.segment2 
			IF p_rec_document.trans_type = "VO" THEN 
				PRINT COLUMN 25, GROUP sum(p_rec_document.unpaid_amt/ 
				p_rec_document.conv_qty) USING "-----,--&.&&", 
				COLUMN 41, GROUP sum(p_rec_document.curr_amt/ 
				p_rec_document.conv_qty) USING "-----,--&.&&", 
				COLUMN 57, GROUP sum(p_rec_document.over1_amt/ 
				p_rec_document.conv_qty) USING "-----,--&.&&", 
				COLUMN 73, GROUP sum(p_rec_document.over30_amt/ 
				p_rec_document.conv_qty) USING "-----,--&.&&", 
				COLUMN 89,group sum(p_rec_document.over60_amt/ 
				p_rec_document.conv_qty) USING "-----,--&.&&", 
				COLUMN 105,group sum(p_rec_document.over90_amt/ 
				p_rec_document.conv_qty) USING "-----,--&.&&", 
				COLUMN 121,group sum(p_rec_document.received_amt) USING "-----,--&.&&" 
			END IF 

		AFTER GROUP OF p_rec_document.segment1 
			IF p_rec_document.trans_type = "VO" THEN 
				NEED 4 LINES 
				PRINT COLUMN 23, "----------------------------------------", 
				"----------------------------------------", 
				"------------------------------" 
				PRINT COLUMN 01, "Total", 
				COLUMN 07, p_rec_document.segment1 clipped 
				PRINT COLUMN 23, GROUP sum(p_rec_document.unpaid_amt /p_rec_document.conv_qty) USING "---,---,--&.&&", 
				COLUMN 39, GROUP sum(p_rec_document.curr_amt /p_rec_document.conv_qty) USING "---,---,--&.&&", 
				COLUMN 55, GROUP sum(p_rec_document.over1_amt /p_rec_document.conv_qty) USING "---,---,--&.&&", 
				COLUMN 71, GROUP sum(p_rec_document.over30_amt /p_rec_document.conv_qty) USING "---,---,--&.&&", 
				COLUMN 87,group sum(p_rec_document.over60_amt /p_rec_document.conv_qty) USING "---,---,--&.&&", 
				COLUMN 103,group sum(p_rec_document.over90_amt /p_rec_document.conv_qty) USING "---,---,--&.&&", 
				COLUMN 119,group sum(p_rec_document.received_amt) USING "---,---,--&.&&" 
				PRINT 
			END IF 
			
		ON LAST ROW 
			NEED 12 LINES 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			
			PRINT 
			PRINT COLUMN 01, "Report Totals: ",glob_base_curr_code, 
			COLUMN 23, sum(p_rec_document.unpaid_amt /p_rec_document.conv_qty) USING "---,---,--&.&&", 
			COLUMN 39, sum(p_rec_document.curr_amt	/p_rec_document.conv_qty) USING "---,---,--&.&&", 
			COLUMN 55, sum(p_rec_document.over1_amt /p_rec_document.conv_qty) USING "---,---,--&.&&", 
			COLUMN 71, sum(p_rec_document.over30_amt /p_rec_document.conv_qty) USING "---,---,--&.&&", 
			COLUMN 87, sum(p_rec_document.over60_amt /p_rec_document.conv_qty) USING "---,---,--&.&&", 
			COLUMN 103,sum(p_rec_document.over90_amt /p_rec_document.conv_qty) USING "---,---,--&.&&", 
			COLUMN 119,sum(p_rec_document.received_amt) USING "---,---,--&.&&" 
			PRINT COLUMN 23, "========================================", 
			"========================================", 
			"==============================" 
			PRINT 
			PRINT 

			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			 
END REPORT