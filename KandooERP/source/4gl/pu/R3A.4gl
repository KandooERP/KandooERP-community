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
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../pu/R_PU_GLOBALS.4gl"
GLOBALS 
	DEFINE 
	msg, prog CHAR(40), 
	cmd CHAR(3), 
	prg_name CHAR(7), 
	pr_rec_kandoouser RECORD LIKE kandoouser.*, 
	pr_company RECORD LIKE company.*, 
	query_text, where_part CHAR(900), 
--	print_option CHAR(1), 
	pr_output CHAR(60), 
	q1_text CHAR(500), 
	rpt_wid SMALLINT, 
	rpt_date DATE, 
	rpt_time CHAR(10), 
	rpt_note CHAR(80), 
	line1, line2 CHAR(80), 
	offset1, offset2 SMALLINT, 
	idx INTEGER, 
	income, expense CHAR(1), 
	pr_purchdetl RECORD LIKE purchdetl.* 
END GLOBALS 
############################################################
# MODULE Scope Variables
############################################################

#######################################################################
# MAIN
#
# R3A - Outstanding Commitments Report
#######################################################################
MAIN 
	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("R3A") -- albo 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) 
	CALL init_r_pu() #init r/pu purchase ORDER module 

	CLEAR screen 

	MENU "Outstanding Commitments Report" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","R3A","menu-outstanding_commitments_rep-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		COMMAND "Run Report" " SELECT criteria AND PRINT REPORT" 
			CALL R3A_rpt_query() 
			CLEAR screen 

		ON ACTION "Print Manager" 	#COMMAND "Print" "Print OR view using RMS"
			CALL run_prog("URS","","","","") 

		COMMAND "Exit" " Exit TO menus" 
			EXIT MENU 

	END MENU 

	CLEAR screen 
END MAIN 

FUNCTION R3A_rpt_query() 
	DEFINE l_rpt_idx SMALLINT  
	DEFINE exist SMALLINT, 
	pr_account RECORD LIKE account.* 

	CLEAR screen 
	OPEN WINDOW R130 with FORM "R130" 
	CALL  windecoration_r("R130") 



	MESSAGE " Enter selection criteria - ESC TO START REPORT" 

	CONSTRUCT BY NAME where_part ON purchdetl.cmpy_code, 
	purchdetl.acct_code, 
	purchhead.year_num, 
	purchhead.period_num 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","R3A","construct-purchhead-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	# add on the search dimension of segments.......

	   CALL segment_con(glob_rec_kandoouser.cmpy_code, "account")
	         returning q1_text
	   LET where_part = where_part clipped, q1_text


	#------------------------------------------------------------
	IF (where_part IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"R3A_rpt_list",where_part, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT R3A_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = 0, 
	BOTTOM MARGIN = 0, 
	LEFT MARGIN = 0, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET where_part = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------

	LET query_text = 
	"SELECT purchdetl.* ", 
	"FROM purchdetl,purchhead ", 
	" WHERE purchdetl.cmpy_code = purchhead.cmpy_code ", 
	"AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("R3A_rpt_list")].sel_text clipped," ", 
	" AND purchdetl.order_num = purchhead.order_num ", 
	" ORDER BY purchdetl.acct_code, purchdetl.order_num " 


	PREPARE choice FROM query_text 
	DECLARE selcurs CURSOR FOR choice 

	OPEN selcurs 

	CLOSE WINDOW R130 
	CLEAR screen 
	WHILE true 
		FETCH selcurs INTO pr_purchdetl.* 
		IF status = notfound THEN 
			EXIT WHILE 
		END IF 
		#---------------------------------------------------------
		OUTPUT TO REPORT R3A_rpt_list(l_rpt_idx,pr_purchdetl.*)
		IF NOT rpt_int_flag_handler2("Purchase Order:",pr_purchdetl.order_num, NULL,l_rpt_idx) THEN
			EXIT WHILE 
		END IF 
		#---------------------------------------------------------		

	END WHILE 

	#------------------------------------------------------------
	FINISH REPORT R3A_rpt_list
	CALL rpt_finish("R3A_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 

REPORT R3A_rpt_list(p_rpt_idx,pr_purchdetl) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE pr_purchdetl RECORD LIKE purchdetl.*, 
	pr_purchhead RECORD LIKE purchhead.*, 
	pr_poaudit RECORD LIKE poaudit.*, 
	pr_vendor RECORD LIKE vendor.*, 
	tot_amt, out_amt money(10,2), 
	g_tot_amt, g_out_amt money(10,2), 
	grand_tot, grand_out money(10,2), 
	first_on_acct_flag INTEGER, 
	acct_desc CHAR(40) 

	OUTPUT 
	left margin 0 
	ORDER external BY pr_purchdetl.acct_code, pr_purchdetl.order_num 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
					
			IF pageno = 1 THEN 
				LET out_amt = 0 
				LET tot_amt = 0 
				LET g_out_amt = 0 
				LET g_tot_amt = 0 
				LET grand_tot = 0 
				LET grand_out = 0 
				LET first_on_acct_flag = 0 
			END IF 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 

			PRINT COLUMN 1, "**** All monetary VALUES are in local currency ****" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 1, "P.O.", 
			COLUMN 14, "Auth", 
			COLUMN 29, "Entry", 
			COLUMN 44, "Vendor Name", 
			COLUMN 85, "Curr", 
			COLUMN 94, "Order", 
			COLUMN 106, "Outstanding" 

			PRINT COLUMN 1, "Number", 
			COLUMN 14, "Code", 
			COLUMN 29, "Date", 
			COLUMN 85, "Code", 
			COLUMN 94, "Amount", 
			COLUMN 109, "Amount" 

			PRINT COLUMN 1, "------------------------------------------", 
			"------------------------------------------", 
			"------------------------------------------" 

		ON EVERY ROW 
			CALL po_line_info(glob_rec_kandoouser.cmpy_code, 
			pr_purchdetl.order_num, 
			pr_purchdetl.line_num) 
			RETURNING pr_poaudit.order_qty, 
			pr_poaudit.received_qty, 
			pr_poaudit.voucher_qty, 
			pr_poaudit.unit_cost_amt, 
			pr_poaudit.ext_cost_amt, 
			pr_poaudit.unit_tax_amt, 
			pr_poaudit.ext_tax_amt, 
			pr_poaudit.line_total_amt 

			LET tot_amt = tot_amt + (pr_poaudit.order_qty * 
			(pr_poaudit.unit_cost_amt + pr_poaudit.unit_tax_amt)) 
			IF pr_poaudit.order_qty > pr_poaudit.received_qty THEN 
				LET out_amt = out_amt + 
				((pr_poaudit.order_qty - pr_poaudit.received_qty) * 
				(pr_poaudit.unit_cost_amt + pr_poaudit.unit_tax_amt)) 
			END IF 


		AFTER GROUP OF pr_purchdetl.order_num 
			IF out_amt > 0 THEN 
				IF first_on_acct_flag = 0 THEN 
					SELECT desc_text 
					INTO acct_desc 
					FROM coa 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
					acct_code = pr_purchdetl.acct_code 
					PRINT COLUMN 1, "GL Account: ", pr_purchdetl.acct_code, 
					" ",acct_desc clipped 
					LET first_on_acct_flag = 1 
				END IF 
				INITIALIZE pr_purchhead.* TO NULL 
				SELECT * 
				INTO pr_purchhead.* 
				FROM purchhead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
				order_num = pr_purchdetl.order_num 
				SELECT * 
				INTO pr_vendor.* 
				FROM vendor 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
				vend_code = pr_purchhead.vend_code 
				LET tot_amt = conv_currency(tot_amt, glob_rec_kandoouser.cmpy_code, pr_purchhead.curr_code, 
				"F", pr_purchhead.order_date, "B") 
				LET out_amt = conv_currency(out_amt, glob_rec_kandoouser.cmpy_code, pr_purchhead.curr_code, 
				"F", pr_purchhead.order_date, "B") 
				PRINT COLUMN 1, pr_purchhead.order_num USING "######", 
				COLUMN 14, pr_purchhead.authorise_code, 
				COLUMN 29, pr_purchhead.entry_date USING "dd/mm/yyyy", 
				COLUMN 44, pr_vendor.name_text, 
				COLUMN 84, pr_purchhead.curr_code, 
				COLUMN 89, tot_amt USING "---,---,--$.&&", 
				COLUMN 105, out_amt USING "---,---,--$.&&" 
				LET g_tot_amt = g_tot_amt + tot_amt 
				LET g_out_amt = g_out_amt + out_amt 
			END IF 
			LET tot_amt = 0 
			LET out_amt = 0 

		AFTER GROUP OF pr_purchdetl.acct_code 
			IF first_on_acct_flag = 1 THEN 
				PRINT COLUMN 1, "Account Totals: ", 
				COLUMN 89, g_tot_amt USING "---,---,--$.&&", 
				COLUMN 105, g_out_amt USING "---,---,--$.&&" 
				LET first_on_acct_flag = 0 
				SKIP 1 LINES 
				LET grand_tot = grand_tot + g_tot_amt 
				LET grand_out = grand_out + g_out_amt 
			END IF 
			LET g_tot_amt = 0 
			LET g_out_amt = 0 

		ON LAST ROW 
			PRINT COLUMN 1, "Report Totals: ", 
			COLUMN 89, grand_tot USING "---,---,--$.&&", 
			COLUMN 105, grand_out USING "---,---,--$.&&" 
			SKIP 1 LINES 
			#PRINT COLUMN 40, "******** END OF REPORT R3A ********" 

			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			

			LET grand_tot = 0 
			LET grand_out = 0 



END REPORT 