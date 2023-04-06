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
# \brief module PRJ  -  Purchase Journal Report
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS 
	DEFINE glob_where1_text CHAR(2048) 
	DEFINE glob_where2_text CHAR(2048)
	DEFINE glob_pr_ledg_start SMALLINT 
	DEFINE glob_seg_start SMALLINT	
END GLOBALS 
DEFINE modu_seg_text STRING
############################################################
# MAIN
#
#
############################################################
MAIN 

	#Initial UI Init
	CALL setModuleId("PRJ") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	OPEN WINDOW P168 with FORM "P168" 
	CALL windecoration_p("P168") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	
			MENU " Purchase Journal Detail" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","PRJ","menu-purchase_journal-1") 
					CALL rpt_rmsreps_reset(NULL)
					CALL PRJ_rpt_process(PRJ_rpt_query())  
		
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report" 			#COMMAND "Report" " SELECT Criteria AND PRINT REPORT"
					CALL rpt_rmsreps_reset(NULL)
					CALL PRJ_rpt_process(PRJ_rpt_query())  
		
				ON ACTION "Print Manager"			#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "CANCEL"			#COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
					EXIT MENU 
		
			END MENU 
		
			CLOSE WINDOW P168

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL PRJ_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW P168 with FORM "P168" 
			CALL windecoration_p("P168") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(PRJ_rpt_query()) #save where clause in env 
			CLOSE WINDOW P168 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL PRJ_rpt_process(get_url_sel_text())
	END CASE 	 
END MAIN 


############################################################
# FUNCTION PRJ_rpt_query()
#
#
############################################################
FUNCTION PRJ_rpt_query() 
	DEFINE l_where_text STRING

	CLEAR FORM 
	MESSAGE kandoomsg2("P",1001,"")	#1001 Enter selection criteria - ESC TO Continue
	CONSTRUCT BY NAME l_where_text ON vendor.vend_code, 
	vendor.name_text, 
	vendor.currency_code, 
	voucherdist.vouch_code, 
	inv_text, 
	vouch_date, 
	entry_date, 
	year_num, 
	period_num, 
	total_amt, 
	paid_amt, 
	post_flag 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","PRJ","construct-vendor-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL
	ELSE
		LET glob_rec_rpt_selector.sel_option1 = segment_con(glob_rec_kandoouser.cmpy_code,"voucherdist")
		CALL fgl_winmessage("ERROR","Segment Data for voucherdist is empty","ERROR")		
		RETURN l_where_text 
	END IF 
END FUNCTION 


############################################################
# FUNCTION PRJ_rpt_process(p_where_text)
#
#
############################################################
FUNCTION PRJ_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_rpt_idx SMALLINT  #report array index

	DEFINE l_rec_voucherdist RECORD 
		acct_code LIKE voucherdist.acct_code, 
		vend_code LIKE voucher.vend_code, 
		name_text LIKE vendor.name_text, 
		vouch_code LIKE voucher.vouch_code, 
		vouch_date LIKE voucher.vouch_date, 
		com1_text LIKE voucher.com1_text, 
		com2_text LIKE voucher.com2_text, 
		conv_qty LIKE voucher.conv_qty, 
		dist_amt LIKE voucherdist.dist_amt, 
		order_num LIKE voucherdist.po_num, 
		ledg_code LIKE validflex.flex_code, 
		seg_code LIKE validflex.flex_code, 
		trans_ind CHAR(1) 
	END RECORD 
	DEFINE l_ledg_length SMALLINT
	DEFINE l_seg_length SMALLINT
	DEFINE l_temp_text CHAR(2048)
	DEFINE l_rpt_output CHAR(60) 
	DEFINE l_query1_text CHAR(2200) 
	DEFINE l_query2_text CHAR(2200)
	DEFINE l_finish_rep SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE i,j,p SMALLINT

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"PRJ_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT PRJ_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------
	#Case specific rems_reps works...
	LET modu_seg_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_option1
	#------------------------------------------------------------

	LET glob_where1_text = glob_where1_text clipped, modu_seg_text 
	LET glob_where2_text = glob_where1_text

	DECLARE structurecurs CURSOR FOR 
	SELECT start_num, length_num FROM structure 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND start_num > 0 
	AND (type_ind = "S" OR type_ind = "C" OR type_ind = "L") 
	ORDER BY start_num 
	OPEN structurecurs 

	FETCH structurecurs INTO glob_pr_ledg_start, l_ledg_length 
	LET l_ledg_length = l_ledg_length + glob_pr_ledg_start - 1 
	
	FETCH structurecurs INTO glob_seg_start, l_seg_length 
	LET l_seg_length = l_seg_length + glob_seg_start - 1 

	#glob_where2_text IS large enough TO store all CONSTRUCT INPUT. Do NOT alter....
	#There IS need TO allow FOR additional characters TO be inserted
	#WHEN substituting FOR debithead table entries.
	LET j = (length(glob_where2_text)) + 10 
	FOR i = 1 TO j 
		IF glob_where2_text[i,i+10] = "voucherdist" THEN 
			LET glob_where2_text[i,i+10] = " debitdist" 
		END IF 
		IF glob_where2_text[i,i+4] = "vouch" THEN 
			LET glob_where2_text[i,i+4] = "debit" 
		END IF 
		IF glob_where2_text[i,i+3] = "paid" THEN 
			LET l_temp_text = glob_where2_text[i+4,j] 
			LET glob_where2_text[i,j] = "apply",l_temp_text clipped 
		END IF 
		IF glob_where2_text[i,i+7] = "inv_text" THEN 
			LET l_temp_text = glob_where2_text[i+8,j] 
			LET glob_where2_text[i,j] = "debit_text",l_temp_text clipped 
		END IF 
	END FOR 

	LET l_query1_text = "SELECT voucherdist.acct_code,", 
	"voucher.vend_code,", 
	"vendor.name_text,", 
	"voucher.vouch_code,", 
	"voucher.vouch_date,", 
	"voucher.com1_text,", 
	"voucher.com2_text,", 
	"voucher.conv_qty, ", 
	"voucherdist.dist_amt, ", 
	"voucherdist.po_num ", 
	"FROM voucher,voucherdist,vendor ", 
	"WHERE voucherdist.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND vendor.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND voucher.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND vendor.vend_code = voucherdist.vend_code ", 
	"AND voucher.vend_code = vendor.vend_code ", 
	"AND voucher.vouch_code = voucherdist.vouch_code ", 
	" AND voucherdist.type_ind in ('G','W') ", 
	"AND ",glob_where1_text clipped 
	
	LET l_query2_text = "SELECT debitdist.acct_code,", 
	"debithead.vend_code,", 
	"vendor.name_text,", 
	"debithead.debit_num,", 
	"debithead.debit_date,", 
	"debithead.com1_text,", 
	"debithead.com2_text,", 
	"debithead.conv_qty, ", 
	"debitdist.dist_amt, ", 
	"debitdist.po_num ", 
	"FROM debithead,debitdist,vendor ", 
	"WHERE debitdist.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND vendor.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND debithead.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND vendor.vend_code = debitdist.vend_code ", 
	"AND debithead.vend_code = vendor.vend_code ", 
	"AND debithead.debit_num = debitdist.debit_code ", 
	" AND debitdist.type_ind in ('G','W') ", 
	"AND ",glob_where2_text clipped 
	PREPARE s_vchdst FROM l_query1_text 
	DECLARE c_vchdst CURSOR FOR s_vchdst 
	PREPARE s_dbdst FROM l_query2_text 
	DECLARE c_dbdst CURSOR FOR s_dbdst 

	LET l_finish_rep = false 
	
	FOREACH c_vchdst INTO l_rec_voucherdist.* 
		LET l_rec_voucherdist.trans_ind = "1" 
		LET l_rec_voucherdist.dist_amt = l_rec_voucherdist.dist_amt / l_rec_voucherdist.conv_qty 
		LET l_rec_voucherdist.ledg_code = l_rec_voucherdist.acct_code[glob_pr_ledg_start, l_ledg_length] 
		LET l_rec_voucherdist.seg_code = l_rec_voucherdist.acct_code[glob_seg_start, l_seg_length] 

			#---------------------------------------------------------
			OUTPUT TO REPORT PRJ_rpt_list(l_rpt_idx,
			l_rec_voucherdist.*)  
			IF NOT rpt_int_flag_handler2("Vendor Voucher...:",l_rec_voucherdist.vend_code, l_rec_voucherdist.vouch_code,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------
		 
	END FOREACH 
	
	IF NOT l_finish_rep THEN 

		FOREACH c_dbdst INTO l_rec_voucherdist.* 
			LET l_rec_voucherdist.trans_ind = "2" 
			LET l_rec_voucherdist.dist_amt = (l_rec_voucherdist.dist_amt			/ l_rec_voucherdist.conv_qty) * -1 
			LET l_rec_voucherdist.ledg_code = 	l_rec_voucherdist.acct_code[glob_pr_ledg_start, l_ledg_length] 
			LET l_rec_voucherdist.seg_code = 			l_rec_voucherdist.acct_code[glob_seg_start, l_seg_length] 

			#---------------------------------------------------------
			OUTPUT TO REPORT PRJ_rpt_list(l_rpt_idx,
			l_rec_voucherdist.*)  
			IF NOT rpt_int_flag_handler2("Debit...Vendor/Voucher:",l_rec_voucherdist.vend_code, l_rec_voucherdist.vouch_code,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------

		END FOREACH 
	END IF 

	#------------------------------------------------------------
	FINISH REPORT PRJ_rpt_list
	CALL rpt_finish("PRJ_rpt_list")
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
# REPORT PRJ_rpt_list(p_rpt_idx,p_rec_voucherdist)
#
#
############################################################
REPORT PRJ_rpt_list(p_rpt_idx,p_rec_voucherdist) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	 
	DEFINE p_rec_voucherdist RECORD 
		acct_code LIKE voucherdist.acct_code, 
		vend_code LIKE voucher.vend_code, 
		name_text LIKE vendor.name_text, 
		vouch_code LIKE voucher.vouch_code, 
		vouch_date LIKE voucher.vouch_date, 
		com1_text LIKE voucher.com1_text, 
		com2_text LIKE voucher.com2_text, 
		conv_qty LIKE voucher.conv_qty, 
		dist_amt LIKE voucherdist.dist_amt, 
		order_num LIKE voucherdist.po_num, 
		ledg_code LIKE validflex.flex_code, 
		seg_code LIKE validflex.flex_code, 
		trans_ind CHAR(1) 
	END RECORD
	DEFINE l_rec_coa RECORD LIKE coa.*
	DEFINE l_sum_vouch LIKE voucher.dist_amt
	DEFINE l_sum_deb LIKE voucher.dist_amt
	DEFINE l_ledger_desc CHAR(40) 
	DEFINE l_segment_desc CHAR(40)
	DEFINE l_cmpy_head CHAR(132) 
	DEFINE l_msg CHAR(25) 
	DEFINE l_trans_text CHAR(7) 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE i, col2, col, cnt SMALLINT

	OUTPUT 
 
	ORDER BY p_rec_voucherdist.ledg_code, 
	p_rec_voucherdist.seg_code, 
	p_rec_voucherdist.acct_code, 
	p_rec_voucherdist.vend_code, 
	p_rec_voucherdist.vouch_date, 
	p_rec_voucherdist.trans_ind 
	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
 
			LET l_ledger_desc = NULL 
			SELECT desc_text INTO l_ledger_desc FROM validflex 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND flex_code = p_rec_voucherdist.ledg_code 
			AND start_num = glob_pr_ledg_start 

			LET l_segment_desc = NULL 
			SELECT desc_text INTO l_segment_desc FROM validflex 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND flex_code = p_rec_voucherdist.seg_code 
			AND start_num = glob_seg_start 

			PRINT COLUMN 01, p_rec_voucherdist.ledg_code clipped, 
			p_rec_voucherdist.seg_code clipped, " ", 
			l_ledger_desc clipped, " ", 
			l_segment_desc 
			PRINT COLUMN 03, "Vendor", 
			COLUMN 43, "Type", 
			COLUMN 50, "Reference", 
			COLUMN 62, "Date", 
			COLUMN 71, "Order", 
			COLUMN 80, "Description", 
			COLUMN 127, "Amount" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
			
		BEFORE GROUP OF p_rec_voucherdist.ledg_code 
			SKIP TO top OF PAGE 
			
		BEFORE GROUP OF p_rec_voucherdist.seg_code 
			SKIP TO top OF PAGE 
			
		BEFORE GROUP OF p_rec_voucherdist.acct_code 
			NEED 3 LINES 
			INITIALIZE l_rec_coa.* TO NULL 
			SELECT * INTO l_rec_coa.* FROM coa 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND acct_code = p_rec_voucherdist.acct_code 
			PRINT COLUMN 01, p_rec_voucherdist.acct_code, 
			COLUMN 20, l_rec_coa.desc_text 
			
		ON EVERY ROW 
			IF p_rec_voucherdist.trans_ind = "1" THEN 
				LET l_trans_text = "Voucher" 
			ELSE 
				LET l_trans_text = "Debit" 
			END IF 
			PRINT COLUMN 03, p_rec_voucherdist.vend_code, 
			COLUMN 12, p_rec_voucherdist.name_text, 
			COLUMN 43, l_trans_text, 
			COLUMN 51, p_rec_voucherdist.vouch_code USING "#######&", 
			COLUMN 60, p_rec_voucherdist.vouch_date USING "dd/mm/yy"; 
			IF p_rec_voucherdist.order_num IS NULL 
			OR p_rec_voucherdist.order_num = 0 THEN 
				PRINT COLUMN 69, p_rec_voucherdist.com1_text[1,10]; 
			ELSE 
				PRINT COLUMN 69, p_rec_voucherdist.order_num USING "#########"; 
			END IF 
			PRINT COLUMN 80, p_rec_voucherdist.com2_text, 
			COLUMN 116,p_rec_voucherdist.dist_amt USING "--,---,---,--&.&&" 
			
		AFTER GROUP OF p_rec_voucherdist.acct_code 
			NEED 3 LINES 
			PRINT COLUMN 116, "-----------------" 
			PRINT COLUMN 101, "Account Total:", 
			COLUMN 116,group sum(p_rec_voucherdist.dist_amt) 
			USING "--,---,---,--&.&&" 
			SKIP 1 line 
			
		AFTER GROUP OF p_rec_voucherdist.seg_code 
			NEED 10 LINES 
			PRINT COLUMN 116, "=================" 
			PRINT COLUMN 101, "Segment Total:", 
			COLUMN 116,group sum(p_rec_voucherdist.dist_amt) 
			USING "--,---,---,--&.&&" 
			SKIP 1 line 
			PRINT COLUMN 05, "I HEREBY CERTIFY THAT THE PURCHASES DESCRIBED ABOVE" 
			PRINT COLUMN 05, "HAVE BEEN RECEIVED IN GOOD ORDER, AND THAT PRICES AND" 
			PRINT COLUMN 05, "QUALITY ARE SATISFACTORY." 
			SKIP 2 LINES 
			PRINT COLUMN 05, "................................ MANAGER / / " 
			SKIP 2 LINES 
			
		AFTER GROUP OF p_rec_voucherdist.ledg_code 
			SKIP TO top OF PAGE 
			PRINT COLUMN 116, "=================" 
			PRINT COLUMN 101, " Ledger Total:", 
			COLUMN 116,group sum(p_rec_voucherdist.dist_amt) 
			USING "--,---,---,--&.&&" 
			SKIP 2 LINES 

		ON LAST ROW 
			LET p_rec_voucherdist.ledg_code = NULL 
			LET p_rec_voucherdist.seg_code = NULL 
			SKIP TO top OF PAGE 
			PRINT COLUMN 116, "=================" 
			PRINT COLUMN 101, " Report Total:", 
			COLUMN 116,sum(p_rec_voucherdist.dist_amt) USING "--,---,---,--&.&&" 
			SELECT sum(total_amt - dist_amt) INTO l_sum_vouch FROM voucher 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			SELECT sum(total_amt - dist_amt) INTO l_sum_deb FROM debithead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			CASE 
				WHEN (l_sum_vouch != 0 AND l_sum_deb != 0) 
					LET l_msg = "Vouchers AND Debits exist" 
					LET l_msgresp = kandoomsg("P",7031,l_msg) 
				WHEN (l_sum_vouch !=0) 
					LET l_msg = "Vouchers exist" 
					LET l_msgresp = kandoomsg("P",7031,l_msg) 
				WHEN (l_sum_deb !=0) 
					LET l_msg = "Debits exist" 
					LET l_msgresp = kandoomsg("P",7031,l_msg) 
			END CASE 
			IF l_sum_vouch != 0 
			OR l_sum_deb != 0 THEN 
				PRINT COLUMN 01, " Warning: Undistributed ", l_msg 
			END IF 

			SKIP 3 line 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
		
END REPORT