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
# \brief module : PR8
# Purpose : Summary Account Aging

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS 
--	DEFINE where_part CHAR(2048) 
	DEFINE tot_unpaid , tot_curr, tot_o30, tot_o60, tot_o90, tot_plus DECIMAL(16,2) 
END GLOBALS 

############################################################
# MAIN
#
#
############################################################
MAIN 

	#Initial UI Init
	CALL setModuleId("PR8") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	OPEN WINDOW P100 with FORM "P100" 
	CALL windecoration_p("P100") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	MENU " Aging Report" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","PR8","menu-aging_rep-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "Report"		#COMMAND "Report" " SELECT criteria AND PRINT REPORT"
			CALL PR8_rpt_process(PR8_rpt_query())  

		ON ACTION "Print Manager"		#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
			CALL run_prog("URS","","","","") 

		ON ACTION "CANCEL"			#COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
			EXIT MENU 

	END MENU 

	CLOSE WINDOW P100 
END MAIN 


############################################################
# FUNCTION PR8_rpt_query()
#
#
############################################################
FUNCTION PR8_rpt_query()
	DEFINE l_where_text STRING  
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_agedate DATE 
	
	WHENEVER ERROR CONTINUE 
	DROP TABLE shuffle 
	WHENEVER ERROR stop 
	CREATE temp TABLE shuffle (tm_vend CHAR(8), 
	tm_name CHAR(30), 
	tm_cury CHAR(3), 
	tm_conv_qty FLOAT, 
	tm_tele CHAR(12), 
	tm_date DATE, 
	tm_type CHAR(2), 
	tm_doc INTEGER, 
	tm_refer CHAR(20), 
	tm_late INTEGER, 
	tm_amount DECIMAL(16,2), 
	tm_unpaid DECIMAL(16,2), 
	tm_cur DECIMAL(16,2), 
	tm_o30 DECIMAL(16,2), 
	tm_o60 DECIMAL(16,2), 
	tm_o90 DECIMAL(16,2), 
	tm_plus DECIMAL(16,2)) with no LOG 
	CLEAR FORM 

	LET l_msgresp = kandoomsg("U",1001,"")	#1001 Enter criteria FOR selection - press ESC TO begin REPORT"
	CONSTRUCT BY NAME l_where_text ON vendor.vend_code, 
	vendor.name_text, 
	vendor.addr1_text, 
	vendor.addr2_text, 
	vendor.addr3_text, 
	vendor.city_text, 
	vendor.state_code, 
	vendor.post_code, 
	vendor.country_code, 
--@db-patch_2020_10_04--	vendor.country_text, 
	vendor.our_acct_code, 
	vendor.contact_text, 
	vendor.tele_text, 
	vendor.extension_text, 
	vendor.fax_text, 
	vendor.type_code, 
	vendor.term_code, 
	vendor.tax_code, 
	vendor.currency_code, 
	vendor.tax_text, 
	vendor.bank_acct_code, 
	vendor.drop_flag, 
	vendor.language_code 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","PR8","construct-vendor-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL 
	END IF 

	OPEN WINDOW P508 with FORM "P508" 
	CALL windecoration_p("P508") 

	LET l_agedate = today 

	INPUT l_agedate WITHOUT DEFAULTS FROM agedate 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","PR8","inp-agedate-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF l_agedate IS NULL THEN 
					LET l_msgresp = kandoomsg("P",9513,"")			#9513 Aging Date must be entered
					LET l_agedate = today 
					NEXT FIELD agedate 
				END IF 
			END IF 

	END INPUT 

	CLOSE WINDOW p508
	
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL
	ELSE
		LET glob_rec_rpt_selector.ref1_date = l_agedate RETURN l_where_text 
	END IF  
END FUNCTION

############################################################
# FUNCTION PR8_rpt_process(p_where_text)
#
#
############################################################
FUNCTION PR8_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_rpt_idx SMALLINT  #report array index
	DEFINE l_tmp_str STRING	
	DEFINE l_agedate DATE 
	DEFINE l_rec_tempdoc RECORD 
		tm_vend LIKE vendor.vend_code, 
		tm_name LIKE vendor.name_text, 
		tm_cury LIKE vendor.currency_code, 
		tm_conv_qty FLOAT, 
		tm_tele LIKE vendor.tele_text, 
		tm_date LIKE vendor.setup_date, 
		tm_type CHAR(2), 
		tm_doc INTEGER, 
		tm_refer CHAR(20), 
		tm_late INTEGER, 
		tm_amount DECIMAL(16,2), 
		tm_unpaid DECIMAL(16,2), 
		tm_curr DECIMAL(16,2), 
		tm_o30 DECIMAL(16,2), 
		tm_o60 DECIMAL(16,2), 
		tm_o90 DECIMAL(16,2), 
		tm_plus DECIMAL(16,2) 
	END RECORD
	DEFINE l_rec_voucher RECORD 
		vend_code LIKE voucher.vend_code, 
		name_text LIKE vendor.name_text, 
		currency_code LIKE vendor.currency_code, 
		tele_text LIKE vendor.tele_text, 
		vouch_code LIKE voucher.vouch_code, 
		vouch_date LIKE voucher.vouch_date, 
		due_date LIKE voucher.due_date, 
		inv_text LIKE voucher.inv_text, 
		total_amt LIKE voucher.total_amt, 
		paid_amt LIKE voucher.paid_amt, 
		conv_qty LIKE voucher.conv_qty 
	END RECORD 
	DEFINE l_rec_debithead RECORD 
		vend_code LIKE debithead.vend_code, 
		name_text LIKE vendor.name_text, 
		currency_code LIKE vendor.currency_code, 
		tele_text LIKE vendor.tele_text, 
		debit_num LIKE debithead.debit_num, 
		debit_date LIKE debithead.debit_date, 
		debit_text LIKE debithead.debit_text, 
		total_amt LIKE debithead.total_amt, 
		apply_amt LIKE debithead.apply_amt, 
		conv_qty LIKE debithead.conv_qty 
	END RECORD
	DEFINE l_rec_cheque RECORD 
		vend_code LIKE cheque.vend_code, 
		name_text LIKE vendor.name_text, 
		currency_code LIKE vendor.currency_code, 
		tele_text LIKE vendor.tele_text, 
		cheq_code LIKE cheque.cheq_code, 
		cheq_date LIKE cheque.cheq_date, 
		com3_text LIKE cheque.com3_text, 
		pay_amt LIKE cheque.pay_amt, 
		apply_amt LIKE cheque.apply_amt, 
		conv_qty LIKE cheque.conv_qty 
	END RECORD 
	DEFINE l_query_text CHAR(2200)



	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"PR8_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT PR8_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------
	#Case specific rems_reps works...
	LET l_agedate  = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_date
	LET l_tmp_str = "Aging FROM: ", l_agedate USING "dd/mm/yy"
	CALL rpt_set_header_footer_line_2_append(l_rpt_idx,NULL, l_tmp_str)
	#------------------------------------------------------------



	LET l_query_text = "SELECT voucher.vend_code, vendor.name_text, ", 
	"vendor.currency_code, vendor.tele_text, ", 
	"voucher.vouch_code, voucher.vouch_date, ", 
	"voucher.due_date, voucher.inv_text, ", 

	"voucher.total_amt, voucher.paid_amt, ", 
	"voucher.conv_qty ", 
	"FROM voucher, vendor ", 
	"WHERE vendor.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND voucher.vend_code = vendor.vend_code ", 
	"AND voucher.cmpy_code = vendor.cmpy_code ", 
	"AND voucher.total_amt != voucher.paid_amt ", 
	"AND ", p_where_text clipped 



	PREPARE invoicer FROM l_query_text 
	DECLARE invcurs CURSOR FOR invoicer 

	WHILE true 
		FOREACH invcurs INTO l_rec_voucher.* 
			LET l_rec_tempdoc.tm_vend = l_rec_voucher.vend_code 
			LET l_rec_tempdoc.tm_name = l_rec_voucher.name_text 
			LET l_rec_tempdoc.tm_cury = l_rec_voucher.currency_code 
			LET l_rec_tempdoc.tm_conv_qty = l_rec_voucher.conv_qty 
			LET l_rec_tempdoc.tm_tele = l_rec_voucher.tele_text 
			LET l_rec_tempdoc.tm_date = l_rec_voucher.vouch_date 
			LET l_rec_tempdoc.tm_type = "VO" 
			LET l_rec_tempdoc.tm_doc = l_rec_voucher.vouch_code 
			LET l_rec_tempdoc.tm_refer = l_rec_voucher.inv_text 
			LET l_rec_tempdoc.tm_late = l_agedate - l_rec_voucher.due_date 
			LET l_rec_tempdoc.tm_amount = l_rec_voucher.total_amt 
			LET l_rec_tempdoc.tm_unpaid = l_rec_voucher.total_amt - l_rec_voucher.paid_amt 
			LET l_rec_tempdoc.tm_plus = 0 
			LET l_rec_tempdoc.tm_o90 = 0 
			LET l_rec_tempdoc.tm_o60 = 0 
			LET l_rec_tempdoc.tm_o30 = 0 
			LET l_rec_tempdoc.tm_curr = 0 
			IF l_rec_tempdoc.tm_late > 90 THEN 
				LET l_rec_tempdoc.tm_plus = l_rec_tempdoc.tm_unpaid 
			ELSE 
				IF l_rec_tempdoc.tm_late > 60 THEN 
					LET l_rec_tempdoc.tm_o90 = l_rec_tempdoc.tm_unpaid 
				ELSE 
					IF l_rec_tempdoc.tm_late > 30 THEN 
						LET l_rec_tempdoc.tm_o60 = l_rec_tempdoc.tm_unpaid 
					ELSE 
						IF l_rec_tempdoc.tm_late > 0 THEN 
							LET l_rec_tempdoc.tm_o30 = l_rec_tempdoc.tm_unpaid 
						ELSE 
							LET l_rec_tempdoc.tm_curr = l_rec_tempdoc.tm_unpaid 
						END IF 
					END IF 
				END IF 
			END IF 
			INSERT INTO shuffle VALUES (l_rec_tempdoc.*) 
			DISPLAY " Remittance: ", l_rec_voucher.vouch_code at 1,10 

			IF int_flag OR quit_flag THEN 
				EXIT WHILE 
			END IF 
		END FOREACH 

		LET l_query_text = "SELECT debithead.vend_code, vendor.name_text, ", 
		"vendor.currency_code,vendor.tele_text, ", 
		"debithead.debit_num, debithead.debit_date, ", 
		"debithead.debit_text, debithead.total_amt, ", 
		"debithead.apply_amt, ", 
		"debithead.conv_qty ", 
		"FROM debithead, vendor ", 
		"WHERE vendor.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
		"debithead.cmpy_code = vendor.cmpy_code AND ", 
		"debithead.vend_code = vendor.vend_code AND ", 
		"debithead.total_amt != debithead.apply_amt AND ", 
		p_where_text clipped 
		PREPARE creditor FROM l_query_text 
		DECLARE credcurs CURSOR FOR creditor 
		FOREACH credcurs INTO l_rec_debithead.* 
			LET l_rec_tempdoc.tm_vend = l_rec_debithead.vend_code 
			LET l_rec_tempdoc.tm_name = l_rec_debithead.name_text 
			LET l_rec_tempdoc.tm_cury = l_rec_debithead.currency_code 
			LET l_rec_tempdoc.tm_conv_qty = l_rec_debithead.conv_qty 
			LET l_rec_tempdoc.tm_tele = l_rec_debithead.tele_text 
			LET l_rec_tempdoc.tm_date = l_rec_debithead.debit_date 
			LET l_rec_tempdoc.tm_type = "DB" 
			LET l_rec_tempdoc.tm_doc = l_rec_debithead.debit_num 
			LET l_rec_tempdoc.tm_refer = l_rec_debithead.debit_text 
			LET l_rec_tempdoc.tm_late = 0 
			LET l_rec_tempdoc.tm_amount = 0 
			LET l_rec_tempdoc.tm_amount = l_rec_tempdoc.tm_amount 
			- l_rec_debithead.total_amt 
			LET l_rec_tempdoc.tm_unpaid = l_rec_debithead.apply_amt 
			- l_rec_debithead.total_amt 
			LET l_rec_tempdoc.tm_plus = 0 
			LET l_rec_tempdoc.tm_o90 = 0 
			LET l_rec_tempdoc.tm_o60 = 0 
			LET l_rec_tempdoc.tm_o30= 0 
			LET l_rec_tempdoc.tm_curr = 0 
			IF l_rec_tempdoc.tm_late > 90 THEN 
				LET l_rec_tempdoc.tm_plus = l_rec_tempdoc.tm_unpaid 
			ELSE 
				IF l_rec_tempdoc.tm_late > 60 THEN 
					LET l_rec_tempdoc.tm_o90 = l_rec_tempdoc.tm_unpaid 
				ELSE 
					IF l_rec_tempdoc.tm_late > 30 THEN 
						LET l_rec_tempdoc.tm_o60 = l_rec_tempdoc.tm_unpaid 
					ELSE 
						IF l_rec_tempdoc.tm_late > 0 THEN 
							LET l_rec_tempdoc.tm_o30 = l_rec_tempdoc.tm_unpaid 
						ELSE 
							LET l_rec_tempdoc.tm_curr = l_rec_tempdoc.tm_unpaid 
						END IF 
					END IF 
				END IF 
			END IF 
			DISPLAY " Debit: ", l_rec_debithead.debit_num at 1,10 

			INSERT INTO shuffle VALUES (l_rec_tempdoc.*) 
			IF int_flag OR quit_flag THEN 
				EXIT WHILE 
			END IF 
		END FOREACH 
		LET l_query_text = "SELECT cheque.vend_code, vendor.name_text, ", 
		"vendor.currency_code,vendor.tele_text, ", 
		"cheque.cheq_code, cheque.cheq_date, ", 
		"cheque.com3_text, cheque.pay_amt, ", 
		"cheque.apply_amt, ", 
		"cheque.conv_qty ", 
		"FROM cheque, vendor ", 
		"WHERE vendor.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
		"cheque.cmpy_code = vendor.cmpy_code AND ", 
		"cheque.vend_code = vendor.vend_code AND ", 
		"cheque.pay_amt != cheque.apply_amt AND ", 
		p_where_text clipped 
		PREPARE casher FROM l_query_text 
		DECLARE cashcurs CURSOR FOR casher 
		FOREACH cashcurs INTO l_rec_cheque.* 
			LET l_rec_tempdoc.tm_vend = l_rec_cheque.vend_code 
			LET l_rec_tempdoc.tm_name = l_rec_cheque.name_text 
			LET l_rec_tempdoc.tm_cury = l_rec_cheque.currency_code 
			LET l_rec_tempdoc.tm_conv_qty = l_rec_cheque.conv_qty 
			LET l_rec_tempdoc.tm_tele = l_rec_cheque.tele_text 
			LET l_rec_tempdoc.tm_date = l_rec_cheque.cheq_date 
			LET l_rec_tempdoc.tm_type = "CH" 
			LET l_rec_tempdoc.tm_doc = l_rec_cheque.cheq_code 
			LET l_rec_tempdoc.tm_refer = l_rec_cheque.com3_text 
			LET l_rec_tempdoc.tm_late = 0 
			LET l_rec_tempdoc.tm_amount = 0 
			LET l_rec_tempdoc.tm_amount = l_rec_tempdoc.tm_amount - l_rec_cheque.pay_amt 
			LET l_rec_tempdoc.tm_unpaid = l_rec_cheque.apply_amt - l_rec_cheque.pay_amt 
			LET l_rec_tempdoc.tm_plus = 0 
			LET l_rec_tempdoc.tm_o90 = 0 
			LET l_rec_tempdoc.tm_o60 = 0 
			LET l_rec_tempdoc.tm_o30= 0 
			LET l_rec_tempdoc.tm_curr = 0 
			IF l_rec_tempdoc.tm_late > 90 THEN 
				LET l_rec_tempdoc.tm_plus = l_rec_tempdoc.tm_unpaid 
			ELSE 
				IF l_rec_tempdoc.tm_late > 60 THEN 
					LET l_rec_tempdoc.tm_o90 = l_rec_tempdoc.tm_unpaid 
				ELSE 
					IF l_rec_tempdoc.tm_late > 30 THEN 
						LET l_rec_tempdoc.tm_o60 = l_rec_tempdoc.tm_unpaid 
					ELSE 
						IF l_rec_tempdoc.tm_late > 0 THEN 
							LET l_rec_tempdoc.tm_o30 = l_rec_tempdoc.tm_unpaid 
						ELSE 
							LET l_rec_tempdoc.tm_curr = l_rec_tempdoc.tm_unpaid 
						END IF 
					END IF 
				END IF 
			END IF 
			DISPLAY " Cheque: ", l_rec_cheque.cheq_code at 1,10 

			INSERT INTO shuffle VALUES (l_rec_tempdoc.*) 
			IF int_flag OR quit_flag THEN 
				EXIT WHILE 
			END IF 
		END FOREACH 
		EXIT WHILE 

	END WHILE 



	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"PR8_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT PR8_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------
	#Case specific rems_reps works...
	LET l_tmp_str = "Aging FROM: ", l_agedate USING "dd/mm/yy"
	CALL rpt_set_header_footer_line_2_append(l_rpt_idx,NULL, l_tmp_str)
	#------------------------------------------------------------

	DECLARE selcurs CURSOR FOR 
	SELECT * FROM shuffle 
	ORDER BY tm_cury, tm_date, tm_doc 

	FOREACH selcurs INTO l_rec_tempdoc.*

		#---------------------------------------------------------
		OUTPUT TO REPORT PR8_rpt_list(l_rpt_idx,
		l_rec_tempdoc.*, l_agedate)  
		IF NOT rpt_int_flag_handler2("Vendor:",l_rec_tempdoc.tm_vend, l_rec_tempdoc.tm_name,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------
 
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT PR8_rpt_list
	CALL rpt_finish("PR8_rpt_list")
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
# REPORT PR8_rpt_list(p_rpt_idx,p_rec_tempdoc,p_agedate)
#
#
############################################################
REPORT PR8_rpt_list(p_rpt_idx,p_rec_tempdoc,p_agedate)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	 
	DEFINE p_rec_tempdoc RECORD 
		tm_vend CHAR(8), 
		tm_name CHAR(30), 
		tm_cury CHAR(3), 
		tm_conv_qty FLOAT, 
		tm_tele CHAR(12), 
		tm_date DATE, 
		tm_type CHAR(2), 
		tm_doc INTEGER, 
		tm_refer CHAR(20), 
		tm_late INTEGER, 
		tm_amount DECIMAL(16,2), 
		tm_unpaid DECIMAL(16,2), 
		tm_curr DECIMAL(16,2), 
		tm_o30 DECIMAL(16,2), 
		tm_o60 DECIMAL(16,2), 
		tm_o90 DECIMAL(16,2), 
		tm_plus DECIMAL(16,2) 
	END RECORD
	DEFINE p_agedate DATE
	DEFINE l_print_flag CHAR(1) 
	DEFINE l_first_record CHAR(1)
	DEFINE l_vend_tm_unpaid DECIMAL(16,2) 
	DEFINE l_vend_tm_curr DECIMAL(16,2) 
	DEFINE l_vend_tm_o30 DECIMAL(16,2) 
	DEFINE l_vend_tm_o60 DECIMAL(16,2) 
	DEFINE l_vend_tm_o90 DECIMAL(16,2) 
	DEFINE l_vend_tm_plus DECIMAL(16,2) 
	DEFINE l_arr_line ARRAY[4] OF CHAR(132)
 
	OUTPUT 
 
	ORDER external BY p_rec_tempdoc.tm_cury 

	FORMAT 
		PAGE HEADER 

			IF pageno = 1 THEN 
				LET l_first_record = "Y" 
				LET l_print_flag = "N" 
				LET l_vend_tm_unpaid = 0 
				LET l_vend_tm_curr = 0 
				LET l_vend_tm_o30 = 0 
				LET l_vend_tm_o60 = 0 
				LET l_vend_tm_o90 = 0 
				LET l_vend_tm_plus = 0 
				LET tot_unpaid = 0 
				LET tot_curr = 0 
				LET tot_o30 = 0 
				LET tot_o60 = 0 
				LET tot_o90 = 0 
				LET tot_plus = 0 
			END IF 

			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text
			 			
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		ON EVERY ROW 
			LET l_vend_tm_unpaid = l_vend_tm_unpaid + p_rec_tempdoc.tm_unpaid 
			LET l_vend_tm_curr = l_vend_tm_curr + p_rec_tempdoc.tm_curr 
			LET l_vend_tm_o30 = l_vend_tm_o30 + p_rec_tempdoc.tm_o30 
			LET l_vend_tm_o60 = l_vend_tm_o60 + p_rec_tempdoc.tm_o60 
			LET l_vend_tm_o90 = l_vend_tm_o90 + p_rec_tempdoc.tm_o90 
			LET l_vend_tm_plus = l_vend_tm_plus + p_rec_tempdoc.tm_plus 
			LET tot_unpaid = tot_unpaid + (p_rec_tempdoc.tm_unpaid 
			/ p_rec_tempdoc.tm_conv_qty) 
			LET tot_curr = tot_curr + (p_rec_tempdoc.tm_curr / p_rec_tempdoc.tm_conv_qty) 
			LET tot_o30 = tot_o30 + (p_rec_tempdoc.tm_o30 / p_rec_tempdoc.tm_conv_qty) 
			LET tot_o60 = tot_o60 + (p_rec_tempdoc.tm_o60 / p_rec_tempdoc.tm_conv_qty) 
			LET tot_o90 = tot_o90 + (p_rec_tempdoc.tm_o90 / p_rec_tempdoc.tm_conv_qty) 
			LET tot_plus = tot_plus + (p_rec_tempdoc.tm_plus / p_rec_tempdoc.tm_conv_qty) 

		AFTER GROUP OF p_rec_tempdoc.tm_cury 
			PRINT COLUMN 1, "CURRENCY : ", p_rec_tempdoc.tm_cury , 
			COLUMN 38, l_vend_tm_unpaid USING "------------&.&&", 
			COLUMN 55, l_vend_tm_curr USING "-----------&.&&", 
			COLUMN 72, l_vend_tm_o30 USING "----------&.&&", 
			COLUMN 88, l_vend_tm_o60 USING "----------&.&&", 
			COLUMN 104, l_vend_tm_o90 USING "----------&.&&", 
			COLUMN 119, l_vend_tm_plus USING "----------&.&&" 
			LET l_vend_tm_unpaid = 0 
			LET l_vend_tm_curr = 0 
			LET l_vend_tm_o30 = 0 
			LET l_vend_tm_o60 = 0 
			LET l_vend_tm_o90 = 0 
			LET l_vend_tm_plus = 0 
			LET l_print_flag = "N" 

		ON LAST ROW 
			PRINT COLUMN 1, "----------------------------------------", 
			"----------------------------------------", 
			"----------------------------------------", 
			"------------" 
			PRINT COLUMN 1, "Totals in base currency", 
			COLUMN 38, tot_unpaid USING "------------&.&&", 
			COLUMN 55, tot_curr USING "-----------&.&&", 
			COLUMN 72, tot_o30 USING "----------&.&&", 
			COLUMN 86, tot_o60 USING "------------&.&&", 
			COLUMN 104, tot_o90 USING "----------&.&&", 
			COLUMN 119, tot_plus USING "----------&.&&" 
			SKIP 2 line 

			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
	
			
END REPORT