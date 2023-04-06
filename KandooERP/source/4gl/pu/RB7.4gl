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
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../pu/R_PU_GLOBALS.4gl" 
GLOBALS "../pu/RB_GROUP_GLOBALS.4gl"
GLOBALS "../pu/RB7_GLOBALS.4gl" 
# \brief module RB7 Outstanding Purchase Orders

DEFINE modu_start_flg INTEGER 
DEFINE modu_tot_ext_cost_amt LIKE purchdetl.charge_amt 
DEFINE modu_tot_ext_sell_amt LIKE purchdetl.charge_amt 


FUNCTION RB7_main() 
	DEFER quit 
	DEFER interrupt
	
	CALL setModuleId("RB7") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode 	

			OPEN WINDOW R124 with FORM "R124" 
			CALL  windecoration_r("R124") 
		
			MENU " ORDER BY Job ID" 
		
				BEFORE MENU 
					CALL publish_toolbar("kandoo","RB7","menu-order_by_job_id-1") 
		
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
					
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				COMMAND "Run Report" " SELECT criteria AND PRINT REPORT" 
					CALL RB7_rpt_query() 
					CLEAR screen 
					NEXT option "Print Manager" 
		
				ON ACTION "Print Manager" 			#COMMAND KEY ("P",f11) "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 
					NEXT option "Exit" 
		
				COMMAND "Exit" " Exit TO menus" 
					EXIT MENU 
		
			END MENU 
			CLOSE WINDOW R124 
		WHEN "2" #Background Process with rmsreps.report_code
			CALL RB7_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW R124 with FORM "R124" 
			CALL  windecoration_r("R124") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(RB7_rpt_query()) #save where clause in env 
			CLOSE WINDOW R124 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL RB7_rpt_process(get_url_sel_text())
	END CASE
END FUNCTION 


FUNCTION RB7_rpt_query() 
	DEFINE l_where_text STRING
	DEFINE l_where2_text STRING

	LET msgresp = kandoomsg("U",1001,"") 
	CONSTRUCT BY NAME l_where_text ON customer.cust_code, 
	purchdetl.vend_code, 
	purchdetl.order_num, 
	purchhead.curr_code, 
	purchdetl.type_ind, 
	purchdetl.ref_text, 
	purchdetl.job_code, 
	purchhead.status_ind, 
	purchdetl.activity_code, 
	purchdetl.acct_code 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","RB7","construct-purchdetl-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null)
			 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 



		BEFORE FIELD cust_code 
			OPEN WINDOW R157 with FORM "R157" 
			CALL  windecoration_r("R157") 

			CONSTRUCT BY NAME l_where2_text ON purchdetl.due_date 

				BEFORE CONSTRUCT 
					CALL publish_toolbar("kandoo","RBt","construct-due_date-1") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

			END CONSTRUCT 

			CLOSE WINDOW R157 

			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false
				ERROR " Printing was aborted" 
				RETURN NULL
			END IF

	END CONSTRUCT 
	
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false
		ERROR " Printing was aborted" 
		RETURN NULL
	ELSE
		IF l_where2_text IS NOT NULL THEN 
			LET l_where_text = l_where_text CLIPPED, " ", l_where2_text
		END IF
		RETURN l_where_text
	END IF 
	
END FUNCTION 


FUNCTION RB7_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  #report array index
	DEFINE 
	pr_poaudit RECORD LIKE poaudit.*, 
	pr_order_num LIKE purchdetl.order_num, 
	pr_job_code LIKE purchdetl.job_code, 
	pr_var_num LIKE purchdetl.var_num, 
	pr_activity_code LIKE purchdetl.activity_code, 
	pr_cust_code LIKE customer.cust_code, 
	pr_cust_name_text LIKE customer.name_text, 
	pr_due_date LIKE purchdetl.due_date 
	#where2_part CHAR(40)
	
	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"RB7_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT RB7_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------
	 
	LET l_query_text = 
	"SELECT unique poaudit.*, purchdetl.job_code, purchdetl.var_num, ", 
	"purchdetl.activity_code, customer.name_text, customer.cust_code ", 
	"FROM activity, job, customer, poaudit, purchdetl, purchhead ", 
	"WHERE purchdetl.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	" purchdetl.job_code IS NOT NULL AND ", 
	" purchdetl.var_num IS NOT NULL AND ", 
	" purchdetl.activity_code IS NOT NULL AND ", 
	" purchhead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	" purchhead.order_num = purchdetl.order_num AND ", 
	" purchhead.order_num = poaudit.po_num AND ", 
	" purchhead.vend_code = purchdetl.vend_code AND ", 
	" purchhead.cancel_date IS NULL AND ", 
	" poaudit.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	" poaudit.po_num = purchdetl.order_num AND ", 
	" poaudit.line_num = purchdetl.line_num AND ", 
	" poaudit.seq_num = purchdetl.seq_num AND ", 
	" poaudit.order_qty > poaudit.received_qty AND ", 
	" job.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	" job.job_code = purchdetl.job_code AND ", 
	" job.job_code = activity.job_code AND ", 
	" customer.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	" customer.cust_code = job.cust_code AND ", 
	glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("RB7_rpt_list")].sel_text clipped," ",   
	" ORDER BY customer.name_text, customer.cust_code, purchdetl.job_code, ", 
	"purchdetl.activity_code, poaudit.po_num" 

	PREPARE choice FROM l_query_text 
	DECLARE selcurs CURSOR FOR choice 

	LET modu_tot_ext_cost_amt = 0 
	LET modu_tot_ext_sell_amt = 0 

	OPEN selcurs 
	WHILE true 
		FETCH selcurs INTO pr_poaudit.*, 
		pr_job_code, 
		pr_var_num, 
		pr_activity_code, 
		pr_cust_code, 
		pr_cust_name_text 
		IF status = notfound THEN 
			EXIT WHILE 
		END IF 

		#---------------------------------------------------------
		OUTPUT TO REPORT RB7_rpt_list(l_rpt_idx,
		pr_poaudit.*, 
		pr_job_code, 
		pr_var_num, 
		pr_activity_code, 
		pr_cust_code, 
		pr_cust_name_text) 
		IF NOT rpt_int_flag_handler2("Purchase Order:",pr_poaudit.po_num, NULL,l_rpt_idx) THEN
			EXIT WHILE 
		END IF 
		#---------------------------------------------------------	

	END WHILE 
	#------------------------------------------------------------
	FINISH REPORT RB7_rpt_list
	CALL rpt_finish("RB7_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF
END FUNCTION 


REPORT RB7_rpt_list(p_rpt_idx,pr_poaudit, pr_job_code, pr_var_num, pr_activity_code, pr_cust_name_text, pr_cust_code) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE 
	pr_poaudit RECORD LIKE poaudit.*, 
	pr_customer RECORD LIKE customer.*, 
	pr_job RECORD LIKE job.*, 
	pr_activity RECORD LIKE activity.*, 
	pr_vendor RECORD LIKE vendor.*, 
	pr_job_code LIKE purchdetl.job_code, 
	pr_var_num LIKE purchdetl.var_num, 
	pr_activity_code LIKE purchdetl.activity_code, 
	pr_cust_code LIKE customer.cust_code, 
	pr_cust_name_text LIKE customer.name_text, 
	pr_charge_amt, 
	pr_ext_cost_amt, 
	pr_ext_sell_amt LIKE purchdetl.charge_amt, 
	pr_due_date LIKE purchdetl.due_date, 
	pr_note_code LIKE purchdetl.note_code, 
	pr_note_text LIKE notes.note_text 

	OUTPUT 
--	left margin 5 
	ORDER external BY pr_cust_name_text,pr_cust_code, 
	pr_job_code, pr_activity_code, pr_poaudit.po_num 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
 
			SKIP 2 LINES 
		AFTER GROUP OF pr_cust_code 
			SKIP 2 LINES 
		BEFORE GROUP OF pr_job_code 
			SKIP 1 line 
		BEFORE GROUP OF pr_activity_code 
			SKIP 1 line 
			SELECT customer.* 
			INTO pr_customer.* 
			FROM customer 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = pr_cust_code 

			SELECT job.* 
			INTO pr_job.* 
			FROM job 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND job_code = pr_job_code 

			SELECT activity.* 
			INTO pr_activity.* 
			FROM activity 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND job_code = pr_job_code 
			AND var_code = "0" 
			AND activity_code = pr_activity_code 

			PRINT COLUMN 1, "Customer", 
			COLUMN 20, pr_cust_code, 
			COLUMN 40, pr_customer.name_text 
			SKIP 1 line 
			PRINT COLUMN 1, "Job code", 
			COLUMN 20, pr_job_code, 
			COLUMN 40, pr_job.title_text 
			SKIP 1 line 
			PRINT COLUMN 1, "Activity code", 
			COLUMN 20, pr_activity_code, 
			COLUMN 40, "Customer Order Number", 5 spaces, pr_activity.title_text 
			PRINT COLUMN 1, "______________________________________________________", 
			"______________________________________________________", 
			"______________________________________________________" 
			SKIP 1 line 
			PRINT COLUMN 1, "PO No", 
			COLUMN 8, " Vendor" clipped, 
			COLUMN 33, " Order QTY ", 
			COLUMN 43, " Received", 
			COLUMN 57, "ETA", 
			COLUMN 67, " Description text" clipped, 
			COLUMN 113," Unit Cost " clipped, 
			COLUMN 127,"Unit Sell" clipped, 
			COLUMN 141,"Ext Cost" clipped, 
			COLUMN 154,"Ext Sell" 
			PRINT COLUMN 1, "______________________________________________________", 
			"______________________________________________________", 
			"______________________________________________________" 
			SKIP 1 LINES 
		ON EVERY ROW 
			SELECT vendor.* 
			INTO pr_vendor.* 
			FROM vendor 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = pr_poaudit.vend_code 

			SELECT purchdetl.due_date, purchdetl.charge_amt 
			INTO pr_due_date, pr_charge_amt 
			FROM purchdetl 
			WHERE cmpy_code = pr_poaudit.cmpy_code 
			AND order_num = pr_poaudit.po_num 
			AND line_num = pr_poaudit.line_num 
			LET pr_ext_cost_amt = 
			(pr_poaudit.order_qty - pr_poaudit.received_qty)*pr_poaudit.unit_cost_amt 
			LET pr_ext_sell_amt = 
			(pr_poaudit.order_qty - pr_poaudit.received_qty)*pr_charge_amt 
			SKIP 1 line 
			PRINT COLUMN 1, pr_poaudit.po_num USING "<<<<<<", 
			COLUMN 8, pr_vendor.name_text clipped; 
			PRINT COLUMN 40, pr_poaudit.order_qty USING "<<<&", 
			COLUMN 48, pr_poaudit.received_qty USING "<<<&"; 
			PRINT COLUMN 56, pr_due_date USING "dd/mm/yy", 
			COLUMN 68, pr_poaudit.desc_text clipped; 
			PRINT COLUMN 110, pr_poaudit.unit_cost_amt USING "------,--&.&&", 
			COLUMN 118, pr_charge_amt USING "------,--&.&&"; 
			PRINT COLUMN 132, pr_ext_cost_amt USING "------,--&.&&", 
			COLUMN 148, pr_ext_sell_amt USING "------,--&.&&" 
			LET modu_tot_ext_cost_amt = modu_tot_ext_cost_amt + pr_ext_cost_amt 
			LET modu_tot_ext_sell_amt = modu_tot_ext_sell_amt + pr_ext_sell_amt 
			SELECT purchdetl.note_code 
			INTO pr_note_code 
			FROM purchdetl 
			WHERE cmpy_code = pr_poaudit.cmpy_code 
			AND order_num = pr_poaudit.po_num 
			AND line_num = pr_poaudit.line_num 
			IF pr_note_code IS NOT NULL THEN 
				PRINT COLUMN 5, "Note Code :", 
				COLUMN 20, pr_note_code 
				DECLARE notecurs CURSOR FOR 
				SELECT notes.note_text 
				FROM notes 
				WHERE cmpy_code = pr_poaudit.cmpy_code 
				AND note_code = pr_note_code 
				OPEN notecurs 
				WHILE sqlca.sqlcode >=0 
					FETCH notecurs INTO pr_note_text 
					IF sqlca.sqlcode = notfound THEN 
						EXIT WHILE 
					END IF 
					PRINT COLUMN 10, pr_note_text 
				END WHILE 
				CLOSE notecurs 
			END IF 
		ON LAST ROW 
			SKIP 2 line 
			PRINT COLUMN 140, "----------", 
			COLUMN 153,"----------" 
			PRINT COLUMN 120, "REPORT TOTAL", 
			COLUMN 134, modu_tot_ext_cost_amt USING "---,---,--&.&&", 
			150, modu_tot_ext_sell_amt USING "---,---,--&.&&" 
			PRINT COLUMN 140, "==========", 
			COLUMN 153, "==========" 
			SKIP 3 line 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			

END REPORT 
