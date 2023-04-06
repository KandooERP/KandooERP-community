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
# \brief module P72 - Recurring payment processing

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_P7_GLOBALS.4gl"
GLOBALS "../ap/P72_GLOBALS.4gl"
DEFINE glob_temp_text CHAR(20)
############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]

############################################################
# MAIN
############################################################
MAIN 
	DEFINE l_msgresp LIKE language.yes_flag 

	DEFER quit 
	DEFER interrupt 

	#Initial UI Init
	CALL setModuleId("P72") 
	CALL ui_init(0) 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	#LET glob_rec_kandooreport.report_code = "P721" 

	SELECT * INTO glob_glparms.* FROM glparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_code = "1" 
	IF status = NOTFOUND THEN 
		LET l_msgresp=kandoomsg("P",5007,"")	#5007 General Ledger Parameters Not Set Up
		EXIT PROGRAM 
	END IF 
	
	#now done it CALL init_p_ap() #init P/AP module
	#SELECT * INTO pr_apparms.* FROM apparms
	# WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
	#   AND parm_code = "1"
	#IF STATUS = NOTFOUND THEN
	#   LET l_msgresp=kandoomsg("P",5016,"")
	#   #5016 Accounts Payable Parameters Not Set Up
	#   EXIT PROGRAM
	#END IF
	CALL create_table("voucherdist","t_voucherdist","","N") 
	LET pr_globals.vouch_date = today 
	LET pr_globals.year_num = NULL 
	LET pr_globals.period_num = NULL 
	LET pr_globals.update_flag = "Y" 

	OPEN WINDOW P207 with FORM "P207" 
	CALL windecoration_p("P207") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	#DISPLAY BY NAME glob_rec_kandooreport.header_text 

	MENU " Recurring Vouchers" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","P72","menu-rec_voucher-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null)
			 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		COMMAND "Generate" " Enter selection criteria AND generate vouchers" 
			WHILE run_info() 
				IF select_recur() THEN 
					CALL generate_recur(true) 
					EXIT WHILE 
				END IF 
			END WHILE 
			 
		COMMAND "Report" " SELECT criteria AND PRINT REPORT" 
			WHILE run_info() 
				IF select_recur() THEN 
					CALL generate_recur(false) 
					EXIT WHILE 
				END IF 
			END WHILE 
			NEXT option "Print Manager" 

		ON ACTION "Print Manager"			#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
			CALL run_prog("URS","","","","") 

		COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus" 
			EXIT MENU 

	END MENU 
	CLOSE WINDOW P207 
END MAIN 


FUNCTION run_info() 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_msgresp=kandoomsg("P",1040,"")	#1040 Enter voucher run details
	LET pr_globals.vouch_date = today 
	
	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,today) 
	RETURNING pr_globals.year_num,	pr_globals.period_num
	 
	INPUT BY NAME 
		pr_globals.vouch_date, 
		pr_globals.update_flag, 
		pr_globals.year_num, 
		pr_globals.period_num WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P72","inp-GLOBALS-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null)
			 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD vouch_date 
			IF pr_globals.vouch_date IS NULL THEN 
				LET pr_globals.vouch_date = today 
				NEXT FIELD vouch_date 
			ELSE 
				IF pr_globals.vouch_date > (today + 30) THEN 
					LET glob_temp_text = pr_globals.vouch_date USING "dd/mm/yyyy" 
					LET l_msgresp = kandoomsg("U",9523,glob_temp_text) 
				END IF 
				IF NOT field_touched(year_num) THEN 
					CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,pr_globals.vouch_date) 
					RETURNING pr_globals.year_num, 
					pr_globals.period_num 
					DISPLAY BY NAME pr_globals.year_num, 
					pr_globals.period_num 

				END IF 
			END IF 
			
		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF glob_rec_apparms.vouch_approve_flag = "N" THEN 
					IF NOT valid_period2(glob_rec_kandoouser.cmpy_code,pr_globals.year_num, 
					pr_globals.period_num,"ap") THEN 
						LET l_msgresp=kandoomsg("P",9024,"") 
						#P9024 " Accounting period IS closed OR NOT SET up "
						NEXT FIELD year_num 
					END IF 
				ELSE 
					CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,pr_globals.vouch_date) 
					RETURNING pr_globals.year_num, 
					pr_globals.period_num 
				END IF 
			END IF 

	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 


FUNCTION select_recur() 
	DEFINE l_where_text CHAR(2048) 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_msgresp=kandoomsg("P",1001,"")	#1001 " Selection Criteria "
	CONSTRUCT BY NAME l_where_text ON 
		recurhead.group_text, 
		recurhead.recur_code, 
		recurhead.desc_text, 
		recurhead.vend_code, 
		vendor.name_text, 
		recurhead.int_ind, 
		recurhead.last_vouch_date, 
		recurhead.next_vouch_date, 
		recurhead.start_date, 
		recurhead.end_date, 
		recurhead.total_amt, 
		recurhead.curr_code, 
		recurhead.inv_text 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","P72","construct-recurhead-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		LET l_msgresp=kandoomsg("P",1002,"")	#1002 Searching database - pls wait
		LET l_query_text = 
		"SELECT recurhead.* ", 
		"FROM recurhead,", 
		"vendor ", 
		"WHERE recurhead.cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND vendor.cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND vendor.vend_code=recurhead.vend_code ", 
		"AND (vendor.hold_code ='NO' OR vendor.hold_code IS NULL) ", 
		"AND (recurhead.hold_code ='NO' OR recurhead.hold_code IS NULL) ", 
		"AND recurhead.next_vouch_date <='",pr_globals.vouch_date,"' ", 
		"AND recurhead.run_num <= recurhead.max_run_num ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY 1,4,2" 
		PREPARE s_recurhead FROM l_query_text 
		DECLARE c_recurhead CURSOR with HOLD FOR s_recurhead 
		RETURN true 
	END IF 
END FUNCTION 


FUNCTION generate_recur(p_update_ind) 
	DEFINE p_update_ind SMALLINT 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_rec_vouchpayee RECORD LIKE vouchpayee.* 
	DEFINE l_rec_voucherdist RECORD LIKE voucherdist.* 
	DEFINE l_rec_recurhead RECORD LIKE recurhead.* 
	DEFINE l_rec_recurdetl RECORD LIKE recurdetl.* 
	DEFINE l_rec_term RECORD LIKE term.* 
	DEFINE l_rpt_output CHAR(25) 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE cnt SMALLINT

	START REPORT P72_rpt_list TO l_rpt_output 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
--	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
--		LET int_flag = false 
--		LET quit_flag = false
--
--		RETURN FALSE
--	END IF

	LET modu_rpt_idx = rpt_start(getmoduleid(),"P72_rpt_list","N/A", RPT_SHOW_RMS_DIALOG)
	IF modu_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT P72_rpt_list TO rpt_get_report_file_with_path2(modu_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[modu_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[modu_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[modu_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[modu_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[modu_rpt_idx].report_width_num
	--LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("P72_rpt_list")].sel_text
	#------------------------------------------------------------


	LET cnt = 0 
	FOREACH c_recurhead INTO l_rec_recurhead.* 
		IF cnt = 0 THEN 

		END IF 
		LET cnt = cnt + 1 
		WHILE (l_rec_recurhead.next_vouch_date <= pr_globals.vouch_date) 
			AND(l_rec_recurhead.run_num < l_rec_recurhead.max_run_num) 
			INITIALIZE l_rec_voucher.* TO NULL 
			SELECT * INTO l_rec_vendor.* 
			FROM vendor 
			WHERE cmpy_code = l_rec_recurhead.cmpy_code 
			AND vend_code = l_rec_recurhead.vend_code 
			LET l_rec_voucher.cmpy_code = l_rec_recurhead.cmpy_code 
			LET l_rec_voucher.vend_code = l_rec_recurhead.vend_code 
			LET l_rec_voucher.vouch_code = NULL 
			IF l_rec_recurhead.inv_text IS NOT NULL THEN 
				LET glob_temp_text = (l_rec_recurhead.run_num + 1) USING "&&&" 
				LET l_rec_voucher.inv_text = l_rec_recurhead.inv_text clipped, 
				".",glob_temp_text clipped 
			END IF 
			LET l_rec_voucher.vouch_date = l_rec_recurhead.next_vouch_date 
			LET l_rec_voucher.entry_code = glob_rec_kandoouser.sign_on_code 
			LET l_rec_voucher.entry_date = today 
			LET l_rec_voucher.term_code = l_rec_recurhead.term_code 
			SELECT * INTO l_rec_term.* 
			FROM term 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND term_code = l_rec_voucher.term_code 
			IF status = NOTFOUND THEN 
				LET l_rec_voucher.term_code = l_rec_vendor.term_code 
				SELECT * INTO l_rec_term.* 
				FROM term 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND term_code = l_rec_voucher.term_code 
			END IF 
			IF l_rec_recurhead.tax_code IS NULL THEN 
				LET l_rec_voucher.tax_code = l_rec_vendor.tax_code 
			ELSE 
				LET l_rec_voucher.tax_code = l_rec_recurhead.tax_code 
			END IF 
			LET l_rec_voucher.goods_amt = l_rec_recurhead.total_amt 
			LET l_rec_voucher.tax_amt = 0 
			LET l_rec_voucher.total_amt = l_rec_recurhead.total_amt 
			LET l_rec_voucher.paid_amt = 0 
			LET l_rec_voucher.dist_qty = 0 
			LET l_rec_voucher.dist_amt = 0 
			CALL get_due_and_discount_date(l_rec_term.*,l_rec_recurhead.next_vouch_date) 
			RETURNING l_rec_voucher.due_date, 
			l_rec_voucher.disc_date 
			LET l_rec_voucher.poss_disc_amt = l_rec_voucher.total_amt 
			*(l_rec_term.disc_per/100) 
			LET l_rec_voucher.taken_disc_amt = 0 
			LET l_rec_voucher.paid_date = NULL 
			IF glob_rec_apparms.hist_flag = "Y" THEN 
				LET l_rec_voucher.hist_flag = "N" 
			ELSE 
				LET l_rec_voucher.hist_flag = "Y" 
			END IF 
			LET l_rec_voucher.split_from_num = 0 
			LET l_rec_voucher.pay_seq_num = 0 
			LET l_rec_voucher.jour_num = 0 
			LET l_rec_voucher.post_flag = "N" 
			LET l_rec_voucher.year_num = pr_globals.year_num 
			LET l_rec_voucher.period_num = pr_globals.period_num 
			LET l_rec_voucher.line_num = 0 
			LET l_rec_voucher.com1_text = l_rec_recurhead.com1_text[01,30] 
			LET l_rec_voucher.com2_text = l_rec_recurhead.com1_text[31,60] 
			LET l_rec_voucher.hold_code = l_rec_recurhead.hold_code 
			LET l_rec_voucher.jm_post_flag = "N" 
			IF glob_rec_apparms.vouch_approve_flag = 'Y' THEN 
				LET l_rec_voucher.approved_code = 'N' 
			ELSE 
				LET l_rec_voucher.approved_code = 'Y' 
			END IF 
			LET l_rec_voucher.approved_date = NULL 
			LET l_rec_voucher.approved_by_code = NULL 
			LET l_rec_voucher.currency_code = l_rec_recurhead.curr_code 
			IF l_rec_recurhead.conv_qty IS NULL THEN 
				LET l_rec_voucher.conv_qty = 
				get_conv_rate(glob_rec_kandoouser.cmpy_code,l_rec_voucher.currency_code, 
				l_rec_voucher.vouch_date,"B") 
			ELSE 
				LET l_rec_voucher.conv_qty = l_rec_recurhead.conv_qty 
			END IF 
			LET l_rec_voucher.post_date = NULL 
			LET l_rec_voucher.source_ind = "2" 
			LET l_rec_voucher.source_text = l_rec_recurhead.recur_code 
			DECLARE c_recurdetl CURSOR FOR 
			SELECT * FROM recurdetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND recur_code = l_rec_recurhead.recur_code 
			ORDER BY 1,2,3,4 
			FOREACH c_recurdetl INTO l_rec_recurdetl.* 
				INITIALIZE l_rec_voucherdist.* TO NULL 
				LET l_rec_voucherdist.cmpy_code = l_rec_recurdetl.cmpy_code 
				LET l_rec_voucherdist.vend_code = l_rec_recurhead.vend_code 
				LET l_rec_voucherdist.line_num = l_rec_recurdetl.line_num 
				LET l_rec_voucherdist.type_ind = l_rec_recurdetl.type_ind 
				LET l_rec_voucherdist.acct_code = l_rec_recurdetl.acct_code 
				LET l_rec_voucherdist.desc_text = l_rec_recurdetl.desc_text 
				LET l_rec_voucherdist.dist_qty = l_rec_recurdetl.dist_qty 
				LET l_rec_voucherdist.dist_amt = l_rec_recurdetl.dist_amt 
				LET l_rec_voucherdist.analysis_text=l_rec_recurdetl.analysis_text 
				LET l_rec_voucherdist.res_code = l_rec_recurdetl.res_code 
				LET l_rec_voucherdist.job_code = l_rec_recurdetl.job_code 
				LET l_rec_voucherdist.var_code = l_rec_recurdetl.var_code 
				LET l_rec_voucherdist.act_code = l_rec_recurdetl.act_code 
				LET l_rec_voucherdist.po_num = l_rec_recurdetl.po_num 
				LET l_rec_voucherdist.po_line_num = l_rec_recurdetl.po_line_num 
				LET l_rec_voucherdist.trans_qty = l_rec_recurdetl.trans_qty 
				LET l_rec_voucherdist.cost_amt = l_rec_recurdetl.cost_amt 
				LET l_rec_voucherdist.charge_amt = l_rec_recurdetl.charge_amt 
				INSERT INTO t_voucherdist VALUES (l_rec_voucherdist.*) 
				LET l_rec_voucher.line_num = l_rec_voucher.line_num + 1 
				LET l_rec_voucher.dist_amt = l_rec_voucher.dist_amt 
				+ l_rec_voucherdist.dist_amt 
				LET l_rec_voucher.dist_qty = l_rec_voucher.dist_qty 
				+ l_rec_voucherdist.dist_qty 
			END FOREACH 
			
			IF p_update_ind THEN 
				LET l_rec_voucher.vouch_code = 
				update_voucher_related_tables(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,"1",l_rec_voucher.*,l_rec_vouchpayee.*) 
				CASE 
					WHEN l_rec_voucher.vouch_code < 0 
						LET l_rec_recurhead.last_vouch_code = 0 - l_rec_voucher.vouch_code 
					WHEN l_rec_voucher.vouch_code > 0 
						LET l_rec_recurhead.last_vouch_code = l_rec_voucher.vouch_code 
					WHEN l_rec_voucher.vouch_code = 0 
						LET l_rec_voucher.total_amt = 0 
						LET l_rec_voucher.dist_amt = 0 
						DELETE FROM t_voucherdist 
				END CASE 
				LET l_msgresp=kandoomsg("P",1041,"") 		#1041 Processing Recurring Voucher Code:
				DISPLAY l_rec_recurhead.recur_code at 1,40 

				DISPLAY l_rec_recurhead.last_vouch_code USING "<<<<<<<<" at 2,40 

			ELSE 
				LET l_msgresp=kandoomsg("P",1042,"") 		#1042 Reporting on Recurring Voucher:
				DISPLAY l_rec_recurhead.recur_code at 1,40 

			END IF 
			LET l_rec_recurhead.run_num = l_rec_recurhead.run_num + 1 
			LET l_rec_recurhead.run_date = today 
			LET l_rec_recurhead.run_code = glob_rec_kandoouser.sign_on_code 
			LET l_rec_recurhead.last_vouch_date = l_rec_voucher.vouch_date 
			LET l_rec_recurhead.last_year_num = pr_globals.year_num 
			LET l_rec_recurhead.last_period_num = pr_globals.period_num 
			LET l_rec_recurhead.next_vouch_date = generate_int(l_rec_recurhead.*,2) 
			LET l_rec_recurhead.next_due_date = l_rec_voucher.due_date 
			IF l_rec_voucher.vouch_code IS NOT NULL 
			AND l_rec_voucher.vouch_code != 0 THEN 
				WHENEVER ERROR CONTINUE 
				UPDATE recurhead 
				SET * = l_rec_recurhead.* 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND recur_code = l_rec_recurhead.recur_code 
				AND rev_num = l_rec_recurhead.rev_num 
				IF sqlca.sqlerrd[3] = 0 OR sqlca.sqlcode < 0 THEN 
					LET l_msgresp=kandoomsg("P",7017,"")			#P7017 error occurred in UPDATE of recurring payment
				END IF 
				WHENEVER ERROR stop 
			END IF 
			OUTPUT TO REPORT P72_rpt_list(l_rec_recurhead.*,l_rec_voucher.*) 
			DELETE FROM t_voucherdist 
			IF pr_globals.update_flag= "N" THEN 
				EXIT WHILE 
			END IF 
		END WHILE 
	END FOREACH 
	IF cnt = 0 THEN 
		LET l_msgresp=kandoomsg("P",7018,"")	#7018 No recurhead selected FOR processing."
	ELSE 

	END IF 
	
	
	#------------------------------------------------------------
	FINISH REPORT P72_rpt_list
	CALL rpt_finish("P72_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 	
END FUNCTION 


REPORT P72_rpt_list(p_rpt_idx,p_rec_recurhead,p_rec_voucher) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_recurhead RECORD LIKE recurhead.* 
	DEFINE p_rec_voucher RECORD LIKE voucher.*
	DEFINE l_rec_voucherdist RECORD LIKE voucherdist.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.*
	DEFINE l_arr_tot_dist ARRAY[4] OF DECIMAL(16,2) 
--	DEFINE l_arr_line ARRAY[4] OF CHAR(132) 
	DEFINE l_message CHAR(45) 
	DEFINE l_base_dist_amt DECIMAL(16,2) 

	OUTPUT 
	PAGE length 66 
	left margin 0 
	
	ORDER external BY p_rec_recurhead.vend_code,	p_rec_recurhead.recur_code 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			
			PRINT COLUMN 01,"Processing Date :",pr_globals.vouch_date USING "dd/mm/yy" 
			SKIP 1 line 

		BEFORE GROUP OF p_rec_recurhead.vend_code 
			NEED 10 LINES 
			SELECT * INTO l_rec_vendor.* 
			FROM vendor 
			WHERE cmpy_code = p_rec_voucher.cmpy_code 
			AND vend_code = p_rec_voucher.vend_code 
			PRINT COLUMN 01, l_rec_vendor.vend_code, 
			COLUMN 10, l_rec_vendor.name_text 

		BEFORE GROUP OF p_rec_recurhead.recur_code 
			NEED 5 LINES 
			CASE 
				WHEN (p_rec_recurhead.next_vouch_date < pr_globals.vouch_date) 
					AND(pr_globals.update_flag = "N") 
					LET l_message = "** Voucher processing NOT up TO date" 
				WHEN (p_rec_voucher.dist_amt < p_rec_voucher.total_amt) 
					AND(p_rec_voucher.dist_amt > 0) 
					LET l_message = "** Voucher distribution incomplete" 
				OTHERWISE 
					LET l_message = "" 
			END CASE 
			PRINT COLUMN 10, p_rec_recurhead.recur_code, 
			COLUMN 19, p_rec_recurhead.desc_text, 
			COLUMN 50, l_message 

		ON EVERY ROW 
			CASE 
				WHEN p_rec_voucher.vouch_code = 0 
					LET l_message = "** Database error - voucher NOT generated" 
					LET p_rec_voucher.line_num = 0 
				WHEN p_rec_voucher.vouch_code < 0 
					LET p_rec_voucher.vouch_code = 0 - p_rec_voucher.vouch_code 
					LET l_message = "** Database error - dist.lines incomplete" 
				OTHERWISE 
					LET l_message = "" 
			END CASE 

			IF p_rec_voucher.vouch_code IS NOT NULL THEN 
				PRINT COLUMN 19,"Voucher No. :",p_rec_voucher.vouch_code USING "<<<<<<<<" 
			END IF 

			PRINT COLUMN 19,"Payment Seq.:",p_rec_recurhead.run_num USING "<<<", 
			COLUMN 36,"Date:",p_rec_voucher.vouch_date USING "dd/mm/yy", 
			COLUMN 50, l_message 
			LET l_arr_tot_dist[1] = 0 
			LET l_arr_tot_dist[2] = 0 
			DECLARE c_voucherdist CURSOR FOR 
			SELECT * FROM t_voucherdist 
			ORDER BY line_num 

			FOREACH c_voucherdist INTO l_rec_voucherdist.* 
				LET l_base_dist_amt = l_rec_voucherdist.dist_amt/p_rec_voucher.conv_qty 
				PRINT COLUMN 26, l_rec_voucherdist.line_num USING "####", 
				COLUMN 31, l_rec_voucherdist.acct_code , 
				COLUMN 50, l_rec_voucherdist.desc_text, 
				COLUMN 95, l_rec_voucherdist.dist_amt USING "-----------&.&&", 
				COLUMN 110,l_base_dist_amt USING "-----------&.&&" 
				LET l_arr_tot_dist[1] = l_arr_tot_dist[1] + l_rec_voucherdist.dist_amt 
				LET l_arr_tot_dist[2] = l_arr_tot_dist[2] + l_base_dist_amt 
			END FOREACH 

			IF p_rec_voucher.line_num > 0 THEN 
				PRINT COLUMN 95, "---------------", 
				COLUMN 111,"--------------" 
				IF p_rec_voucher.dist_amt < p_rec_voucher.total_amt THEN 
					PRINT COLUMN 75,"Distribution Total:", 
					COLUMN 95, l_arr_tot_dist[1] USING "-----------&.&&", 
					COLUMN 100,l_arr_tot_dist[2] USING "-----------&.&&" 
				END IF 
			END IF 
			PRINT COLUMN 80,"Voucher Total:", 
			COLUMN 95, p_rec_voucher.total_amt USING "-----------&.&&", 
			COLUMN 110,(p_rec_voucher.total_amt/p_rec_voucher.conv_qty) 
			USING "-----------&.&&", 
			COLUMN 126,p_rec_voucher.conv_qty USING "--&.&&&" 

		AFTER GROUP OF p_rec_recurhead.vend_code 
			IF GROUP count(*) > 1 THEN 
				PRINT COLUMN 95, "------",l_rec_vendor.currency_code,"------", 
				COLUMN 111,"-----",glob_glparms.base_currency_code,"------" 
				PRINT COLUMN 71,p_rec_recurhead.vend_code, 
				COLUMN 80,"Vendor Total :", 
				COLUMN 95, GROUP sum(p_rec_voucher.total_amt) 
				USING "-----------&.&&", 
				COLUMN 110,group sum(p_rec_voucher.total_amt/p_rec_voucher.conv_qty) 
				USING "-----------&.&&" 
			END IF 
			SKIP 2 LINES 

		ON LAST ROW 
			NEED 5 LINES 
			PRINT COLUMN 110,"======",glob_glparms.base_currency_code,"======" 
			PRINT COLUMN 80,"Report Total :", 
			COLUMN 110,sum(p_rec_voucher.total_amt/p_rec_voucher.conv_qty) 
			USING "-----------&.&&" 

			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			
			
END REPORT 

