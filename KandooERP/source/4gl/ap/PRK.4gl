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
# \brief module PRK  -  Purchase Order Voucher Report
#                 A REPORT that shows Voucher distributions TO  PO
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS 
--	DEFINE glob_where1_text CHAR(2048)
END GLOBALS 

############################################################
# MODULE SCOPE VARIABLES
############################################################


############################################################
# MAIN
#
#
############################################################
MAIN 

	#Initial UI Init
	CALL setModuleId("PRK") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	OPEN WINDOW P505 with FORM "P505" 
	CALL windecoration_p("P505") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	MENU " PO Voucher Report" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","PRK","menu-po_voucher_rep-1") 
			CALL rpt_rmsreps_reset(NULL)
			CALL PRK_rpt_process(PRK_rpt_query()) 
			
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "Report" 		#COMMAND "Report" " SELECT Criteria AND PRINT REPORT"
			CALL rpt_rmsreps_reset(NULL)
			CALL PRK_rpt_process(PRK_rpt_query()) 

		ON ACTION "Print Manager"			#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
			CALL run_prog("URS","","","","") 

		ON ACTION "CANCEL"			#COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
			EXIT MENU 

	END MENU 

	CLOSE WINDOW P505 
END MAIN 


############################################################
# FUNCTION PRK_rpt_query()
#
#
############################################################
FUNCTION PRK_rpt_query() 

	DEFINE l_where_text STRING
	DEFINE l_where2_text STRING
	DEFINE l_temp_text STRING
--	DEFINE l_glob_rpt_output CHAR(60) 
	DEFINE l_query1_text STRING

	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE i,j SMALLINT

	CLEAR FORM 
	
	LET l_msgresp = kandoomsg("P",1001,"") #1001 Enter selection criteria - ESC TO Continue
	CONSTRUCT BY NAME l_where_text ON purchhead.ware_code, 
	voucher.vend_code, 
	voucherdist.vouch_code, 
	voucher.inv_text, 
	voucher.vouch_date, 
	voucher.entry_date, 
	voucher.year_num, 
	voucher.period_num, 
	voucher.total_amt, 
	voucher.paid_amt, 
	voucher.post_flag 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","PRK","construct-voucher-1") 

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

	CALL segment_con(glob_rec_kandoouser.cmpy_code, "purchdetl") 
	RETURNING l_temp_text 

	IF l_temp_text IS NULL THEN 
		RETURN NULL 
	END IF 
	
	LET l_where_text = l_where_text clipped, l_temp_text 
	LET l_where2_text = l_where_text 
	#l_where2_text IS large enough TO store all CONSTRUCT INPUT. Do NOT alter....
	#There IS need TO allow FOR additional characters TO be inserted
	#WHEN substituting FOR debithead table entries.


	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL
	ELSE
		LET glob_rec_rpt_selector.ref1_text = l_where_text
		LET glob_rec_rpt_selector.ref2_text = l_where2_text		
		RETURN l_where_text 
	END IF 
END FUNCTION 


############################################################
# FUNCTION PRK_rpt_process(p_where_text)
#
#
############################################################
FUNCTION PRK_rpt_process(p_where_text)
	DEFINE p_where_text STRING
	DEFINE l_where2_text STRING
	DEFINE l_query_text STRING 
	DEFINE l_rpt_idx SMALLINT  #report array index
	DEFINE l_pr_finish_rep SMALLINT 
	DEFINE l_rec_voucherdist RECORD 
		ware_code LIKE purchhead.ware_code, 
		acct_code LIKE purchdetl.acct_code, 
		vend_code LIKE voucher.vend_code, 
		name_text LIKE vendor.name_text, 
		vouch_code LIKE voucher.vouch_code, 
		vouch_date LIKE voucher.vouch_date, 
		order_num LIKE purchhead.order_num, 
		line_num LIKE purchdetl.line_num, 
		ref_text LIKE purchdetl.ref_text, 
		oem_text LIKE purchdetl.oem_text, 
		desc_text LIKE purchdetl.desc_text, 
		conv_qty LIKE voucher.conv_qty, 
		dist_amt LIKE voucherdist.dist_amt, 
		trans_ind CHAR(1) 
	END RECORD 
		
	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"PRK_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT PRK_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------
	#Case specific rems_reps works...
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_text
	LET l_where2_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref2_text	
	#------------------------------------------------------------


	LET l_query_text = "SELECT purchhead.ware_code,", 
	"purchdetl.acct_code,", 
	"voucher.vend_code,", 
	"' ',", 
	"voucher.vouch_code,", 
	"voucher.vouch_date,", 
	"purchhead.order_num,", 
	"purchdetl.line_num,", 
	"purchdetl.ref_text,", 
	"purchdetl.oem_text,", 
	"purchdetl.desc_text,", 
	"voucher.conv_qty, ", 
	"voucherdist.dist_amt ", 
	"FROM voucher,voucherdist,purchhead,purchdetl ", 
	"WHERE voucherdist.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND voucher.vouch_code = voucherdist.vouch_code ", 
	"AND voucher.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND purchhead.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND purchhead.order_num = voucherdist.po_num ", 
	"AND purchdetl.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND purchdetl.order_num = voucherdist.po_num ", 
	"AND purchdetl.line_num = voucherdist.po_line_num ", 
	"AND ",p_where_text clipped 
	PREPARE s_vchdst FROM l_query_text 
	DECLARE c_vchdst CURSOR FOR s_vchdst 

	LET l_pr_finish_rep = false 

	FOREACH c_vchdst INTO l_rec_voucherdist.* 
		LET l_rec_voucherdist.trans_ind = "1" 
		LET l_rec_voucherdist.dist_amt = l_rec_voucherdist.dist_amt	/ l_rec_voucherdist.conv_qty
		 
		SELECT name_text INTO l_rec_voucherdist.name_text 
		FROM vendor 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND vend_code = l_rec_voucherdist.vend_code

			#---------------------------------------------------------
			OUTPUT TO REPORT PRK_rpt_list(l_rpt_idx,
			l_rec_voucherdist.*) 
			IF NOT rpt_int_flag_handler2("Vendor/Voucher:",l_rec_voucherdist.vend_code, l_rec_voucherdist.vouch_code,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------
		 
		OUTPUT TO REPORT PRK_rpt_list(l_rec_voucherdist.*)
		 
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT PRK_rpt_list
	CALL rpt_finish("PRK_rpt_list")
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
# REPORT PRK_rpt_list(p_rec_voucherdist)
#
#
############################################################
REPORT PRK_rpt_list(p_rpt_idx,p_rec_voucherdist) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	 
	DEFINE p_rec_voucherdist RECORD 
		ware_code LIKE purchhead.ware_code, 
		acct_code LIKE purchdetl.acct_code, 
		vend_code LIKE voucher.vend_code, 
		name_text LIKE vendor.name_text, 
		vouch_code LIKE voucher.vouch_code, 
		vouch_date LIKE voucher.vouch_date, 
		order_num LIKE purchhead.order_num, 
		line_num LIKE purchdetl.line_num, 
		ref_text LIKE purchdetl.ref_text, 
		oem_text LIKE purchdetl.oem_text, 
		desc_text LIKE purchdetl.desc_text, 
		conv_qty LIKE voucher.conv_qty, 
		dist_amt LIKE voucherdist.dist_amt, 
		trans_ind CHAR(1) 
	END RECORD
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_sum_vouch LIKE voucher.dist_amt
	DEFINE l_sum_deb LIKE voucher.dist_amt
	DEFINE l_cmpy_head CHAR(132)
	DEFINE l_msg CHAR(25) 
	DEFINE l_trans_text CHAR(7) 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE i, col2, col, cnt SMALLINT

	OUTPUT 
	left margin 0 
	ORDER BY p_rec_voucherdist.ware_code, 
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

--			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
--			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text
--			 			
--			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
		
			LET l_rec_warehouse.desc_text = NULL 
			SELECT desc_text INTO l_rec_warehouse.desc_text 
			FROM warehouse 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ware_code = p_rec_voucherdist.ware_code 
			PRINT COLUMN 01, p_rec_voucherdist.ware_code clipped," ", 
			l_rec_warehouse.desc_text 
			PRINT COLUMN 03, "Vendor", 
			COLUMN 45, "Voucher", 
			COLUMN 55, "Date", 
			COLUMN 65, "Order", 
			COLUMN 71, "Line", 
			COLUMN 76, "Reference", 
			COLUMN 101, "Vendor Reference", 
			COLUMN 127, "Amount" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		BEFORE GROUP OF p_rec_voucherdist.ware_code 
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
			COLUMN 43, p_rec_voucherdist.vouch_code USING "#######&", 
			COLUMN 53, p_rec_voucherdist.vouch_date USING "dd/mm/yy", 
			COLUMN 62, p_rec_voucherdist.order_num USING "#######&", 
			COLUMN 71, p_rec_voucherdist.line_num USING "##&", 
			COLUMN 75, p_rec_voucherdist.ref_text, 
			COLUMN 101, p_rec_voucherdist.oem_text, 
			COLUMN 116,p_rec_voucherdist.dist_amt USING "--,---,---,--&.&&" 
			PRINT COLUMN 75, p_rec_voucherdist.desc_text 
		AFTER GROUP OF p_rec_voucherdist.acct_code 
			NEED 3 LINES 
			PRINT COLUMN 116, "-----------------" 
			PRINT COLUMN 101, "Account Total:", 
			COLUMN 116,group sum(p_rec_voucherdist.dist_amt) 
			USING "--,---,---,--&.&&" 
			SKIP 1 line 
		AFTER GROUP OF p_rec_voucherdist.ware_code 
			NEED 10 LINES 
			PRINT COLUMN 116, "=================" 
			PRINT COLUMN 98, "Warehouse Total:", 
			COLUMN 116,group sum(p_rec_voucherdist.dist_amt) 
			USING "--,---,---,--&.&&" 
			SKIP 1 line 
			PRINT COLUMN 05, "I HEREBY CERTIFY THAT THE PURCHASES DESCRIBED ABOVE" 
			PRINT COLUMN 05, "HAVE BEEN RECEIVED IN GOOD ORDER, AND THAT PRICES AND" 
			PRINT COLUMN 05, "QUALITY ARE SATISFACTORY." 
			SKIP 2 LINES 
			PRINT COLUMN 05, "................................ MANAGER / / " 
			SKIP 2 LINES 
		ON LAST ROW 
			LET p_rec_voucherdist.ware_code = NULL 
			SKIP TO top OF PAGE 
			PRINT COLUMN 116, "=================" 
			PRINT COLUMN 101, " Report Total:", 
			COLUMN 116,sum(p_rec_voucherdist.dist_amt) USING "--,---,---,--&.&&" 
			SELECT sum(total_amt - dist_amt) INTO l_sum_vouch FROM voucher 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			SELECT sum(total_amt - dist_amt) INTO l_sum_deb FROM debithead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF l_sum_vouch != 0 
			AND l_sum_deb != 0 THEN 
				LET l_msg = "Vouchers AND Debits exist" 
				LET l_msgresp = kandoomsg("P",7031,l_msg) 
			ELSE 
				IF l_sum_vouch != 0 THEN 
					LET l_msg = "Vouchers exist" 
					LET l_msgresp = kandoomsg("P",7031,l_msg) 
				ELSE 
					LET l_msg = "Debits exist" 
					LET l_msgresp = kandoomsg("P",7031,l_msg) 
				END IF 
			END IF 
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