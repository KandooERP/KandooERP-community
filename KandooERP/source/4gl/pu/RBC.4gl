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
GLOBALS "../pu/RBC_GLOBALS.4gl" 

--DEFINE modu_start_flg INTEGER 
DEFINE modu_sale_code LIKE salesperson.sale_code 
DEFINE modu_email_text LIKE salesperson.addr1_text 
 
###########################################################################
# FUNCTION RBC_main()
#
# RBC Emailing Outstanding Purchase Orders TO Sales Person
###########################################################################
FUNCTION RBC_main() 
	DEFER quit 
	DEFER interrupt
	
	CALL setModuleId("RBC")

	DECLARE c_salesperson CURSOR with HOLD FOR 
	SELECT salesperson.sale_code, salesperson.addr1_text 
	FROM salesperson 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

	FOREACH c_salesperson INTO modu_sale_code, modu_email_text 
		IF sel_salespsn(modu_sale_code) THEN 
			CALL RBC_rpt_process(modu_sale_code, modu_email_text) 
		END IF 
	END FOREACH 
END FUNCTION 

FUNCTION sel_salespsn(modu_sale_code) 
	DEFINE 
	modu_sale_code LIKE salesperson.sale_code, 
	match_text CHAR(10), 
	pr_cnt SMALLINT 

	LET match_text = modu_sale_code clipped, "*" 
	SELECT count(*) INTO pr_cnt 
	FROM activity 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND activity_code matches match_text 
	IF pr_cnt > 0 THEN 
		RETURN true 
	ELSE 
		RETURN false 
	END IF 
END FUNCTION 


FUNCTION RBC_rpt_process(modu_sale_code, modu_email_text) 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  #report array index
	DEFINE 
	modu_sale_code LIKE salesperson.sale_code, 
	modu_email_text LIKE salesperson.addr1_text, 
	pr_poaudit RECORD LIKE poaudit.*, 
	pr_order_num LIKE purchdetl.order_num, 
	pr_job_code LIKE purchdetl.job_code, 
	pr_var_num LIKE purchdetl.var_num, 
	pr_activity_code LIKE purchdetl.activity_code, 
	pr_cust_code LIKE customer.cust_code, 
	pr_due_date LIKE purchdetl.due_date, 
	run_string CHAR(150), 
	pr_name_text CHAR(30), 
	pr_sub_text CHAR(60), 
	pr_script_text CHAR(60) 

	#------------------------------------------------------------

	LET l_rpt_idx = rpt_start(getmoduleid(),"RBC_rpt_list","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT RBC_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	LET l_query_text = 
	"SELECT unique poaudit.*, purchdetl.job_code, purchdetl.var_num, ", 
	"purchdetl.activity_code, customer.cust_code ", 
	"FROM activity, job, customer, poaudit, purchdetl, purchhead ", 
	"WHERE purchdetl.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	" purchdetl.job_code IS NOT NULL AND ", 
	" purchdetl.var_num IS NOT NULL AND ", 
	" purchdetl.activity_code matches \"", modu_sale_code clipped, "*", "\" AND ", 
	" purchhead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	" purchhead.order_num = purchdetl.order_num AND ", 
	" purchhead.order_num = poaudit.po_num AND ", 
	" purchhead.vend_code = purchdetl.vend_code AND ", 
	" purchhead.cancel_date IS NULL AND ", 
	" poaudit.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	" poaudit.po_num = purchdetl.order_num AND ", 
	" poaudit.line_num = purchdetl.line_num AND ", 
	" poaudit.seq_num = purchdetl.seq_num AND ", 
	" poaudit.order_qty != poaudit.received_qty AND ", 
	" job.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	" job.job_code = purchdetl.job_code AND ", 
	" job.job_code = activity.job_code AND ", 
	" customer.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	" customer.cust_code = job.cust_code ", 
	" ORDER BY customer.cust_code, purchdetl.job_code, ", 
	"purchdetl.activity_code, poaudit.po_num" 
	
	PREPARE choice FROM l_query_text 
	DECLARE selcurs CURSOR FOR choice 

	OPEN selcurs 


	WHILE true 
		FETCH selcurs INTO pr_poaudit.*, pr_job_code, pr_var_num, 
		pr_activity_code, pr_cust_code 
		IF status = notfound THEN 
			EXIT WHILE 
		END IF 

		#---------------------------------------------------------
		OUTPUT TO REPORT RBC_rpt_list(l_rpt_idx,
		pr_poaudit.*, pr_job_code, pr_var_num, 
		pr_activity_code, pr_cust_code) 
		IF NOT rpt_int_flag_handler2("",NULL, NULL,l_rpt_idx) THEN
			EXIT WHILE 
		END IF 
		#---------------------------------------------------------

	END WHILE 

	#------------------------------------------------------------
	FINISH REPORT RBC_rpt_list
	CALL rpt_finish("RBC_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF

	CLOSE selcurs 
{
	SELECT salesperson.name_text INTO pr_name_text 
	FROM salesperson 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND sale_code = modu_sale_code 
	LET pr_sub_text = "Outstanding POs FOR ", pr_name_text clipped, " ", today 
	LET pr_script_text = "/apps/misc/bin/send_attach" 

	LET run_string = "perl ", pr_script_text clipped," ", 
	modu_email_text clipped," ", pr_output clipped, ' \"', 
	pr_sub_text clipped,'\"' 
	#   LET run_string = "mailx -s '", pr_sub_text clipped,"' ", modu_email_text clipped, " < ", pr_output clipped
	DISPLAY run_string 
	RUN run_string 
}
END FUNCTION 


REPORT RBC_rpt_list(p_rpt_idx,pr_poaudit, pr_job_code, pr_var_num, pr_activity_code, pr_cust_code)
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
	pr_charge_amt LIKE purchdetl.charge_amt, 
	pr_due_date LIKE purchdetl.due_date, 
	pr_note_code LIKE purchdetl.note_code, 
	pr_note_text LIKE notes.note_text, 
	pr_name_text CHAR(10) 

	OUTPUT 
--	left margin 0 
--	bottom margin 0 
	ORDER external BY pr_cust_code, pr_job_code, pr_activity_code, 
	pr_poaudit.po_num 

	FORMAT 

	#  first PAGE HEADER
	#     PRINT 'Content-Type: html;charset=\"iso-8859-1\"'
	#     PRINT 'Content-Type: html; charset=\"iso-8859-1\"'
	#     PRINT "Content-Transfer-Encoding: Quoted-printable"
	#    PRINT "<HTML>"
	#    PRINT "<BODY>"
	#    PRINT "<PRE>"
	#    PRINT '<FONT SIZE =\"3\" FACE=\"', 'Courier New, Courier', '\">'

	  PAGE HEADER
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1

	#  PRINT COLUMN 1, "Outstanding POs (Menu - RB7)", 5 spaces, today using "dd/mm/yyyy", 5 spaces, pr_company.cmpy_code,
	#                 2 spaces, pr_company.name_text clipped, 5 spaces,
	#                 "Page:", pageno using "####"
	#  skip 2 lines
	#  BEFORE GROUP OF pr_cust_code
	#     skip TO top of page
		BEFORE GROUP OF pr_job_code 
			#     skip TO top of page
			#  BEFORE GROUP OF pr_activity_code
			#     skip TO top of page
			SKIP 5 LINES 
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

			PRINT COLUMN 01, "Customer", 
			COLUMN 20, pr_cust_code, 
			COLUMN 40, pr_customer.name_text 
			SKIP 1 line 
			PRINT COLUMN 01, "Job code", 
			COLUMN 20, pr_job_code, 
			COLUMN 40, pr_job.title_text 
			SKIP 1 line 
			#      PRINT COLUMN 1, "Activity code", COLUMN 20, pr_activity_code, COLUMN 40, "Customer Order Number", 5 spaces, pr_activity.title_text
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
			SKIP 1 line 
			PRINT COLUMN 01, "PO No", 
			COLUMN 8, "Vendor", 
			COLUMN 15, "Ord QTY", 
			COLUMN 23, "Received", 
			COLUMN 33, "ETA", 
			COLUMN 42, "Description text", 
			COLUMN 83,"Unit Cost", 
			COLUMN 99,"Unit Sell" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
			SKIP 1 LINES 

		BEFORE GROUP OF pr_activity_code 
			SELECT * INTO pr_activity.* 
			FROM activity 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND job_code = pr_job_code 
			AND (var_code = pr_var_num OR var_code IS null) 
			AND activity_code = pr_activity_code 
			SKIP 2 line 
			PRINT COLUMN 01, "Activity code", 
			COLUMN 20, pr_activity_code, 
			COLUMN 40, "Customer Order Number", 5 spaces, pr_activity.title_text 
			
		ON EVERY ROW 
			SELECT vendor.name_text 
			INTO pr_name_text 
			FROM vendor 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = pr_poaudit.vend_code 

			SELECT purchdetl.due_date, purchdetl.charge_amt 
			INTO pr_due_date, pr_charge_amt 
			FROM purchdetl 
			WHERE cmpy_code = pr_poaudit.cmpy_code 
			AND order_num = pr_poaudit.po_num 
			AND line_num = pr_poaudit.line_num 
			SKIP 1 line 
			PRINT COLUMN 1, pr_poaudit.po_num USING "<<<<<<", 
			COLUMN 8, pr_name_text; 
			PRINT COLUMN 20, pr_poaudit.order_qty USING "<<&", 
			COLUMN 26, pr_poaudit.received_qty USING "<<&"; 
			PRINT COLUMN 32, pr_due_date USING "dd/mm/yy", 
			COLUMN 42, pr_poaudit.desc_text clipped; 
			PRINT COLUMN 80, pr_poaudit.unit_cost_amt clipped USING "------,--&.&&", 
			COLUMN 96, pr_charge_amt USING "------,--&.&&" 

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

			SKIP 5 line 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			

			#     PRINT "</FONT>"
			#     PRINT "</PRE>"
			#     PRINT "</BODY>"
			#     PRINT "</HTML>"

END REPORT 
