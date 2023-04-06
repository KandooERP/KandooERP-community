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
# \brief module PRC - Period Activity Report
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS 
--	DEFINE p_where_text STRING -- CHAR(2048)
END GLOBALS 

############################################################
# MAIN
#
#
############################################################
MAIN 

	#Initial UI Init
	CALL setModuleId("PRC") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	

			OPEN WINDOW P154 with FORM "P154" 
			CALL windecoration_p("P154") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
		
			MENU " Period Activity" 
		
				BEFORE MENU 
					CALL publish_toolbar("kandoo","PRC","menu-period_activity-1") 
					CALL rpt_rmsreps_reset(NULL)
					CALL PRC_rpt_process(PRC_rpt_query()) 
		
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				COMMAND "Report" " SELECT criteria AND PRINT REPORT" 
					CALL rpt_rmsreps_reset(NULL)
					CALL PRC_rpt_process(PRC_rpt_query()) 
		
				ON ACTION "Print" 				#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "CANCEL" 				#COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
					EXIT MENU 
				
			END MENU 
		
			CLOSE WINDOW P154

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL PRC_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW P100 with FORM "P100" 
			CALL windecoration_p("P100") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(PRC_rpt_query()) #save where clause in env 
			CLOSE WINDOW P100 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL PRC_rpt_process(get_url_sel_text())
	END CASE 	 
END MAIN 


FUNCTION PRC_rpt_query() 
	DEFINE l_where_text STRING

	MESSAGE kandoomsg2("U",1001,"")	
	CONSTRUCT BY NAME l_where_text ON vendor.vend_code, 
	vendor.type_code, 
	vendor.name_text, 
	vendor.currency_code, 
	vendor.term_code, 
	vendor.tax_code, 
	voucher.year_num, 
	voucher.period_num 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","PRC","construct-vendor-1") 

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
		--LET glob_rec_rpt_selector.ref1_date = modu_agedate
		RETURN l_where_text 
	END IF 
END FUNCTION 


############################################################
# FUNCTION PRC_rpt_process(p_where_text)
#
#
############################################################
FUNCTION PRC_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	 
	DEFINE l_query_text CHAR(2200)
	DEFINE l_rec_tempdoc RECORD 
		tm_vend LIKE vendor.vend_code, 
		tm_type_code LIKE vendor.type_code, 
		tm_name LIKE vendor.name_text, 
		tm_date LIKE vendor.setup_date, 
		tm_type CHAR(2), 
		tm_doc INTEGER, 
		tm_refer CHAR(20), 
		tm_conv_qty FLOAT, 
		tm_amount DECIMAL(16,2), 
		tm_unpaid DECIMAL(16,2), 
		tm_dis DECIMAL(16,2), 
		tm_post CHAR(1) 
	END RECORD 
	DEFINE l_rec_voucher RECORD 
		vend_code LIKE voucher.vend_code, 
		type_code LIKE vendor.type_code, 
		name_text LIKE vendor.name_text, 
		vouch_code LIKE voucher.vouch_code, 
		vouch_date LIKE voucher.vouch_date, 
		inv_text LIKE voucher.inv_text, 
		total_amt LIKE voucher.total_amt, 
		paid_amt LIKE voucher.paid_amt, 
		poss_disc_amt LIKE voucher.poss_disc_amt, 
		taken_disc_amt LIKE voucher.taken_disc_amt, 
		post_flag LIKE voucher.post_flag, 
		conv_qty LIKE voucher.conv_qty 
	END RECORD
	DEFINE l_rec_debithead RECORD 
		vend_code LIKE debithead.vend_code, 
		type_code LIKE vendor.type_code, 
		name_text LIKE vendor.name_text, 
		debit_num LIKE debithead.debit_num, 
		debit_date LIKE debithead.debit_date, 
		debit_text LIKE debithead.debit_text, 
		total_amt LIKE debithead.total_amt, 
		apply_amt LIKE debithead.apply_amt, 
		post_flag LIKE debithead.post_flag, 
		conv_qty LIKE debithead.conv_qty 
	END RECORD
	DEFINE l_rec_cheque RECORD 
		vend_code LIKE cheque.vend_code, 
		type_code LIKE vendor.type_code, 
		name_text LIKE vendor.name_text, 
		cheq_code LIKE cheque.cheq_code, 
		cheq_date LIKE cheque.cheq_date, 
		com3_text LIKE cheque.com3_text, 
		pay_amt LIKE cheque.pay_amt, 
		apply_amt LIKE cheque.apply_amt, 
		post_flag LIKE cheque.post_flag, 
		conv_qty LIKE cheque.conv_qty 
	END RECORD
	DEFINE l_where_part_1 CHAR(2048)
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE i,j SMALLINT

	WHENEVER ERROR CONTINUE 
	DROP TABLE shuffle 
	WHENEVER ERROR stop 
	CREATE temp TABLE shuffle (tm_vend CHAR(8), 
	tm_type_code CHAR(3), 
	tm_name CHAR(30), 
	tm_date DATE, 
	tm_type CHAR(2), 
	tm_doc INTEGER, 
	tm_refer CHAR(20), 
	tm_conv_qty FLOAT, 
	tm_amount DECIMAL(16,2), 
	tm_unpaid DECIMAL(16,2), 
	tm_dis DECIMAL(16,2), 
	tm_post CHAR(1)) with no LOG 
	CLEAR FORM 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"PRC_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT PRC_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------
	#Case specific rems_reps works...
	#NONE
	#------------------------------------------------------------


	LET l_query_text = "SELECT voucher.vend_code, ", 
	"vendor.type_code, vendor.name_text, ", 
	"voucher.vouch_code,voucher.vouch_date, ", 
	"voucher.inv_text,voucher.total_amt, ", 
	"voucher.paid_amt,voucher.poss_disc_amt, ", 
	"voucher.taken_disc_amt, voucher.post_flag, ", 
	"voucher.conv_qty ", 
	"FROM voucher, vendor ", 
	"WHERE vendor.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	" AND voucher.vend_code = vendor.vend_code AND ", 
	"voucher.cmpy_code = vendor.cmpy_code AND ", 
	p_where_text clipped 

	MESSAGE kandoomsg2("U",1506,"")	#1506 Searching Database Please Stand By"

	LET l_where_part_1 = p_where_text 
	PREPARE invoicer FROM l_query_text 
	DECLARE invcurs CURSOR FOR invoicer 

	WHILE true 
		FOREACH invcurs INTO l_rec_voucher.* 
			LET l_rec_tempdoc.tm_vend = l_rec_voucher.vend_code 
			LET l_rec_tempdoc.tm_type_code = l_rec_voucher.type_code 
			LET l_rec_tempdoc.tm_name = l_rec_voucher.name_text 
			LET l_rec_tempdoc.tm_date = l_rec_voucher.vouch_date 
			LET l_rec_tempdoc.tm_type = "VO" 
			LET l_rec_tempdoc.tm_doc = l_rec_voucher.vouch_code 
			LET l_rec_tempdoc.tm_refer = l_rec_voucher.inv_text 
			LET l_rec_tempdoc.tm_conv_qty = l_rec_voucher.conv_qty 
			IF l_rec_voucher.conv_qty= 0 THEN 
				LET l_rec_voucher.conv_qty= 1 
			END IF 
			IF l_rec_voucher.post_flag = "V" THEN 
				LET l_rec_tempdoc.tm_amount = 0 
				LET l_rec_tempdoc.tm_unpaid = 0 
			ELSE 
				LET l_rec_tempdoc.tm_amount = l_rec_voucher.total_amt / 
				l_rec_voucher.conv_qty 
				LET l_rec_tempdoc.tm_unpaid = (l_rec_voucher.total_amt - 
				l_rec_voucher.paid_amt) / 
				l_rec_voucher.conv_qty 
			END IF 

			LET l_rec_tempdoc.tm_post = l_rec_voucher.post_flag 
			LET l_rec_tempdoc.tm_dis = (l_rec_voucher.poss_disc_amt - 
			l_rec_voucher.taken_disc_amt) / 
			l_rec_voucher.conv_qty 

			INSERT INTO shuffle VALUES (l_rec_tempdoc.*) 
		
			DISPLAY " Remitt.: ", l_rec_voucher.vouch_code at 1,10 

			IF int_flag OR quit_flag THEN 
				EXIT WHILE 
			END IF 

		END FOREACH 

		FOR i = 1 TO (length(p_where_text)-6) 
			IF p_where_text[i,i+6] = "voucher" THEN # move it all up BY 2 
				FOR j = (length(p_where_text)+2) TO (i+6) step -1 
					LET p_where_text[j] = p_where_text[j-2] 
				END FOR 
				LET p_where_text[i,i+8] = "debithead" 
			END IF 
		END FOR 
		LET l_query_text = "SELECT debithead.vend_code, vendor.type_code, ", 
		" vendor.name_text,", 
		" debithead.debit_num, debithead.debit_date,", 
		" debithead.debit_text, debithead.total_amt, ", 
		"debithead.apply_amt, debithead.post_flag, ", 
		"debithead.conv_qty ", 
		"FROM debithead, vendor ", 
		"WHERE vendor.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND debithead.cmpy_code = vendor.cmpy_code ", 
		"AND debithead.vend_code = vendor.vend_code AND ", 
		p_where_text clipped
		 
		PREPARE creditor FROM l_query_text 
		DECLARE credcurs CURSOR FOR creditor 
		FOREACH credcurs INTO l_rec_debithead.* 
			LET l_rec_tempdoc.tm_vend = l_rec_debithead.vend_code 
			LET l_rec_tempdoc.tm_type_code = l_rec_debithead.type_code 
			LET l_rec_tempdoc.tm_name = l_rec_debithead.name_text 
			LET l_rec_tempdoc.tm_date = l_rec_debithead.debit_date 
			LET l_rec_tempdoc.tm_type = "DB" 
			LET l_rec_tempdoc.tm_doc = l_rec_debithead.debit_num 
			LET l_rec_tempdoc.tm_conv_qty = l_rec_debithead.conv_qty 
			LET l_rec_tempdoc.tm_dis = 0 
			IF l_rec_debithead.post_flag = "V" THEN 
				LET l_rec_tempdoc.tm_amount = 0 
				LET l_rec_tempdoc.tm_unpaid = 0 
			ELSE 
				LET l_rec_tempdoc.tm_refer = l_rec_debithead.debit_text 
				LET l_rec_tempdoc.tm_amount = (0 - l_rec_debithead.total_amt) / 
				l_rec_debithead.conv_qty 
				LET l_rec_tempdoc.tm_unpaid = (l_rec_debithead.apply_amt - 
				l_rec_debithead.total_amt ) / 
				l_rec_debithead.conv_qty 
			END IF 
			LET l_rec_tempdoc.tm_post = l_rec_debithead.post_flag 
			DISPLAY " Credit: ", l_rec_debithead.debit_num at 1,10 

			INSERT INTO shuffle VALUES (l_rec_tempdoc.*) 
			IF int_flag OR quit_flag THEN 
				EXIT WHILE 
			END IF 
		END FOREACH 
		LET p_where_text = l_where_part_1 
		FOR i = 1 TO (length(p_where_text)-6) 
			IF p_where_text[i,i+6] = "voucher" THEN 
				LET p_where_text[i,i+6] = "cheque" 
			END IF 
		END FOR
		 
		LET l_query_text = "SELECT cheque.vend_code, vendor.type_code, ", 
		" vendor.name_text, ", 
		"cheque.cheq_code, cheque.cheq_date, ", 
		" cheque.com3_text, cheque.pay_amt, ", 
		"cheque.apply_amt,cheque.post_flag, ", 
		"cheque.conv_qty ", 
		"FROM cheque, vendor ", 
		"WHERE cheque.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
		" cheque.cmpy_code = vendor.cmpy_code AND ", 
		" cheque.vend_code = vendor.vend_code AND ", 
		p_where_text clipped 
		
		PREPARE casher FROM l_query_text 
		DECLARE cashcurs CURSOR FOR casher
		 
		FOREACH cashcurs INTO l_rec_cheque.* 
			LET l_rec_tempdoc.tm_vend = l_rec_cheque.vend_code 
			LET l_rec_tempdoc.tm_type_code = l_rec_cheque.type_code 
			LET l_rec_tempdoc.tm_name = l_rec_cheque.name_text 
			LET l_rec_tempdoc.tm_date = l_rec_cheque.cheq_date 
			LET l_rec_tempdoc.tm_type = "CH" 
			LET l_rec_tempdoc.tm_doc = l_rec_cheque.cheq_code 
			LET l_rec_tempdoc.tm_refer = l_rec_cheque.com3_text 
			LET l_rec_tempdoc.tm_conv_qty = l_rec_cheque.conv_qty 
			LET l_rec_tempdoc.tm_dis = 0 
			IF l_rec_cheque.post_flag = "V" THEN 
				LET l_rec_tempdoc.tm_amount = 0 
				LET l_rec_tempdoc.tm_unpaid = 0 
			ELSE 
				LET l_rec_tempdoc.tm_amount = (0 - l_rec_cheque.pay_amt) / 
				l_rec_cheque.conv_qty 
				LET l_rec_tempdoc.tm_unpaid = (l_rec_cheque.apply_amt - 
				l_rec_cheque.pay_amt) / l_rec_cheque.conv_qty 
			END IF 
			LET l_rec_tempdoc.tm_post = l_rec_cheque.post_flag 
			DISPLAY " Cheque: ", l_rec_cheque.cheq_code at 1,10 

			INSERT INTO shuffle VALUES (l_rec_tempdoc.*) 
			IF int_flag OR quit_flag THEN 
				EXIT WHILE 
			END IF 
		END FOREACH 
		EXIT WHILE 
	END WHILE 
	

	
	DECLARE selcurs CURSOR FOR 
	SELECT * FROM shuffle 
	ORDER BY tm_type_code, tm_vend, tm_date, tm_doc 
	
	FOREACH selcurs INTO l_rec_tempdoc.*

		#---------------------------------------------------------
		OUTPUT TO REPORT PRC_rpt_list(l_rpt_idx,
		l_rec_tempdoc.*)  
		IF NOT rpt_int_flag_handler2("Vendor:",l_rec_tempdoc.tm_vend, l_rec_tempdoc.tm_name,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------

	END FOREACH 
	
	#------------------------------------------------------------
	FINISH REPORT PRC_rpt_list
	CALL rpt_finish("PRC_rpt_list")
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
# REPORT PRC_rpt_list(p_rpt_idx,p_rec_tempdoc) 
#
#
############################################################
REPORT PRC_rpt_list(p_rpt_idx,p_rec_tempdoc) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_rec_tempdoc RECORD 
		tm_vend CHAR(8), 
		tm_type_code CHAR(3), 
		tm_name CHAR(30), 
		tm_date DATE, 
		tm_type CHAR(2), 
		tm_doc INTEGER, 
		tm_refer CHAR(20), 
		tm_conv_qty FLOAT, 
		tm_amount DECIMAL(16,2), 
		tm_unpaid DECIMAL(16,2), 
		tm_dis DECIMAL(16,2), 
		tm_post CHAR(1) 
	END RECORD
	DEFINE l_rev_vendortype RECORD LIKE vendortype.*
	
	OUTPUT 
 
	ORDER external BY p_rec_tempdoc.tm_type_code, 
	p_rec_tempdoc.tm_vend, 
	p_rec_tempdoc.tm_date, 
	p_rec_tempdoc.tm_doc 
	
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2]
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line3_text
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text
			 			
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
		 
		BEFORE GROUP OF p_rec_tempdoc.tm_type_code 
			SKIP 1 LINES 
			SELECT * INTO l_rev_vendortype.* FROM vendortype 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND type_code = p_rec_tempdoc.tm_type_code 
			PRINT COLUMN 1, "Vendor Type: ",p_rec_tempdoc.tm_type_code, 
			COLUMN 25, l_rev_vendortype.type_text 
			PRINT COLUMN 1, "Control Account: ", l_rev_vendortype.pay_acct_code 
		BEFORE GROUP OF p_rec_tempdoc.tm_vend 
			SKIP 2 LINES 
			PRINT COLUMN 1, "Vendor: ",p_rec_tempdoc.tm_vend, 
			COLUMN 25, p_rec_tempdoc.tm_name 
			SELECT * INTO glob_rec_vendor.* FROM vendor 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = p_rec_tempdoc.tm_vend 
			PRINT COLUMN 1, "Currency: ", glob_rec_vendor.currency_code 
		ON EVERY ROW 
			PRINT COLUMN 2, p_rec_tempdoc.tm_date USING "dd/mm/yy", 
			COLUMN 12, p_rec_tempdoc.tm_type, 
			COLUMN 18, p_rec_tempdoc.tm_doc USING "########", 
			COLUMN 28, p_rec_tempdoc.tm_refer, 
			COLUMN 49, p_rec_tempdoc.tm_amount USING "----,---,---.&&", 
			COLUMN 65, p_rec_tempdoc.tm_dis USING "----,---,---.&&", 
			COLUMN 81, p_rec_tempdoc.tm_unpaid USING "----,---,---.&&", 
			COLUMN 101,p_rec_tempdoc.tm_post 
		AFTER GROUP OF p_rec_tempdoc.tm_type_code 
			PRINT COLUMN 49, "------------------------------------------------" 
			PRINT COLUMN 49, GROUP sum(p_rec_tempdoc.tm_amount) 
			USING "----,---,---.&&", 
			COLUMN 65, GROUP sum(p_rec_tempdoc.tm_dis) 
			USING "----,---,---.&&", 
			COLUMN 81, GROUP sum(p_rec_tempdoc.tm_unpaid) 
			USING "----,---,---.&&" 
		AFTER GROUP OF p_rec_tempdoc.tm_vend 
			PRINT COLUMN 49, "------------------------------------------------" 
			PRINT COLUMN 49, GROUP sum(p_rec_tempdoc.tm_amount) 
			USING "----,---,---.&&", 
			COLUMN 65, GROUP sum(p_rec_tempdoc.tm_dis) 
			USING "----,---,---.&&", 
			COLUMN 81, GROUP sum(p_rec_tempdoc.tm_unpaid) 
			USING "----,---,---.&&" 
		ON LAST ROW 
			PRINT COLUMN 1, "Total", 
			COLUMN 49, "------------------------------------------------" 
			PRINT COLUMN 49, sum(p_rec_tempdoc.tm_amount) 
			USING "----,---,---.&&", 
			COLUMN 65, sum(p_rec_tempdoc.tm_dis) 
			USING "----,---,---.&&", 
			COLUMN 81, sum(p_rec_tempdoc.tm_unpaid) 
			USING "----,---,---.&&"
			 
			SKIP 2 line 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
		
END REPORT 