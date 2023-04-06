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
GLOBALS "../pu/RA_GROUP_GLOBALS.4gl"
GLOBALS "../pu/RAE_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################   
DEFINE modu_vendor_count SMALLINT 
DEFINE modu_order_count SMALLINT
#######################################################################
# FUNCTION RAE_main() 
#
# RAE Purchase Order Expedite Report
#######################################################################
FUNCTION RAE_main() 
	DEFER quit 
	DEFER interrupt
	CALL setModuleId("RAE") -- albo 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode
			OPEN WINDOW R124 with FORM "R124" 
			CALL  windecoration_r("R124") 

			MENU " Purchase Order Expedite" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","RAE","menu-purch_order_exp-1") 
					CALL RAE_rpt_process(RAE_rpt_query())
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
					
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				COMMAND "Run" " Enter selection criteria AND generate REPORT" 
					CALL RAE_rpt_process(RAE_rpt_query())

				ON ACTION "Print Manager" 	#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				COMMAND KEY("E",interrupt)"Exit" " Exit TO menus" 
					EXIT MENU 

			END MENU 
			CLOSE WINDOW R124 
			
		WHEN "2" #Background Process with rmsreps.report_code
			CALL RAE_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW R124 with FORM "R124" 
			CALL  windecoration_r("R124") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(RAE_rpt_query()) #save where clause in env 
			CLOSE WINDOW R124 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL RAE_rpt_process(get_url_sel_text())
	END CASE
END FUNCTION 
#######################################################################
# END FUNCTION RAE_main() 
#######################################################################


#######################################################################
# FUNCTION RAE_rpt_query() 
#
# 
#######################################################################
FUNCTION RAE_rpt_query() 
	DEFINE l_where_text STRING 
	
	LET msgresp = kandoomsg("U",1001,"")	#1001 Enter Selection Criteria;  OK TO Continue.
	CONSTRUCT BY NAME l_where_text ON purchdetl.vend_code, 
	purchdetl.order_num, 
	purchhead.curr_code, 
	purchdetl.type_ind, 
	purchdetl.ref_text, 
	purchdetl.job_code, 
	purchhead.status_ind, 
	purchdetl.activity_code, 
	purchdetl.acct_code 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","RAE","construct-purchdetl-1") 

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
		RETURN l_where_text
	END IF 
END FUNCTION 
#######################################################################
# END FUNCTION RAE_rpt_query() 
#######################################################################


#######################################################################
# FUNCTION RAE_rpt_process(p_where_text)
#
# 
#######################################################################
FUNCTION RAE_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  #report array index 
	DEFINE pr_purchhead RECORD LIKE purchhead.* 
	DEFINE pr_purchdetl RECORD LIKE purchdetl.* 
	DEFINE pr_poaudit RECORD LIKE poaudit.* 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"RAE_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT RAE_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = 0, 
	BOTTOM MARGIN = 0, 
	LEFT MARGIN = 0, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------

	LET modu_order_count = 0 
	LET modu_vendor_count = 0 
	LET l_query_text = "SELECT * FROM purchhead, purchdetl ", 
	"WHERE purchhead.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND purchdetl.cmpy_code = purchhead.cmpy_code ", 
	" AND purchdetl.order_num = purchhead.order_num ", 
	" AND purchhead.cancel_date IS NULL ", 
	"AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("RAE_rpt_list")].sel_text clipped," ", 
	" ORDER BY purchdetl.vend_code, ", 
	"purchhead.due_date, ", 
	"purchdetl.order_num, ", 
	"purchdetl.line_num" 

	PREPARE s_poorder FROM l_query_text 
	DECLARE c_poorder CURSOR FOR s_poorder 
	
	FOREACH c_poorder INTO pr_purchhead.*, 
		pr_purchdetl.* 
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
		IF pr_poaudit.order_qty != 0 
		AND pr_poaudit.order_qty IS NOT NULL 
		AND pr_poaudit.order_qty > pr_poaudit.received_qty THEN 

		#---------------------------------------------------------
		OUTPUT TO REPORT AB1_rpt_list(l_rpt_idx,
		pr_purchhead.*, 
			pr_purchdetl.*, 
			pr_poaudit.*) 
		IF NOT rpt_int_flag_handler2("Vendor:",pr_purchhead.vend_code, pr_purchhead.order_num,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------
		ELSE 
			CONTINUE FOREACH 
		END IF 
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT AB1_rpt_list
	CALL rpt_finish("AB1_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
	
END FUNCTION 
#######################################################################
# END FUNCTION RAE_rpt_process(p_where_text)
#######################################################################


#######################################################################
# REPORT RAE_rpt_list(p_rpt_idx,pr_purchhead, pr_purchdetl, pr_poaudit)
#
# 
#######################################################################
REPORT RAE_rpt_list(p_rpt_idx,pr_purchhead, pr_purchdetl, pr_poaudit) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE pr_purchhead RECORD LIKE purchhead.* 
	DEFINE pr_purchdetl RECORD LIKE purchdetl.* 
	DEFINE pr_poaudit RECORD LIKE poaudit.* 
	DEFINE pr_vendor_name LIKE vendor.name_text 
	DEFINE pr_vendor_fax LIKE vendor.fax_text 
	DEFINE pr_qty_os LIKE poaudit.order_qty 
	DEFINE pr_oem_text LIKE purchdetl.oem_text 
	DEFINE pr_lead_time LIKE product.days_lead_num 
	DEFINE pr_desc_line CHAR(75) 
	DEFINE first_order SMALLINT
	
	OUTPUT 
--	left margin 1 
	ORDER external BY pr_purchdetl.vend_code, 
	pr_purchhead.due_date, 
	pr_purchdetl.order_num, 
	pr_purchdetl.line_num 
	FORMAT 
		PAGE HEADER
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
					
		BEFORE GROUP OF pr_purchdetl.vend_code 
			SKIP TO top OF PAGE 
			SELECT name_text, fax_text INTO pr_vendor_name, pr_vendor_fax 
			FROM vendor 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = pr_purchdetl.vend_code 
			PRINT COLUMN 01, "VENDOR: ", 
			pr_vendor_name, 
			" ", 
			pr_vendor_fax 
			LET modu_vendor_count = modu_vendor_count + 1 
			LET first_order = true 
			
		BEFORE GROUP OF pr_purchdetl.order_num NEED 8 LINES 
			LET modu_order_count = modu_order_count + 1 
			PRINT " " 
			PRINT COLUMN 06, "ORDER NO:", 
			COLUMN 22, pr_purchdetl.order_num USING "<<<<<<<<", 
			COLUMN 28, "ORDER DATE: ", 
			pr_purchhead.order_date USING "dd/mmm/yyyy", 
			" DUE DATE : ", 
			pr_purchhead.due_date USING "dd/mmm/yyyy" 
			PRINT COLUMN 06, "---------------------------" 
			PRINT COLUMN 11, "FOR ATTENTION OF: ", 
			COLUMN 29, pr_purchhead.salesperson_text 
			PRINT COLUMN 11, "YOUR REF: ",	pr_purchhead.order_text 
			PRINT " " PRINT COLUMN 11, "OUR CONTACT: ",	pr_purchhead.contact_text 
			PRINT COLUMN 11, "PHONE: ", pr_purchhead.tele_text	PRINT " "
			 
		ON EVERY ROW 
			NEED 2 LINES 
			LET pr_lead_time = 0 

			IF pr_purchdetl.type_ind = "J" OR pr_purchdetl.type_ind = "C" THEN 
				LET pr_oem_text = pr_purchdetl.job_code clipped, 
				" ", 
				pr_purchdetl.activity_code 
			ELSE 

				IF pr_purchdetl.type_ind = "I" OR pr_purchdetl.type_ind = "C" THEN 
					LET pr_oem_text = pr_purchdetl.oem_text 
					SELECT days_lead_num INTO pr_lead_time 
					FROM product 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = pr_purchdetl.ref_text 
					AND vend_code = pr_purchdetl.vend_code 
					IF status = notfound THEN 
						LET pr_lead_time = 0 
					END IF 
				ELSE 
					LET pr_oem_text = pr_purchdetl.ref_text 
				END IF 
			END IF 
			LET pr_qty_os = pr_poaudit.order_qty - pr_poaudit.received_qty 
			LET pr_desc_line = pr_purchdetl.desc_text clipped, 
			" ", 
			pr_purchdetl.desc2_text 
			PRINT COLUMN 01, pr_purchdetl.line_num USING "###", 
			COLUMN 07, pr_oem_text[1,25], 
			COLUMN 33, pr_poaudit.order_qty USING "-----&.&&", 
			COLUMN 44, pr_poaudit.received_qty USING "-----&.&&", 
			COLUMN 55, pr_qty_os USING "----&.&&", 
			COLUMN 65, pr_poaudit.unit_cost_amt USING "-------&.&&", 
			COLUMN 77, pr_lead_time USING "####" 
			PRINT COLUMN 05, pr_desc_line 
			
		ON LAST ROW 
			SKIP TO top OF PAGE 
			PRINT " " 
			PRINT " " 
			PRINT COLUMN 01, "Total Vendors Selected: ", 
			modu_vendor_count USING "#######&" 
			PRINT " " 
			PRINT COLUMN 01, "Total Orders Selected: ", 
			modu_order_count USING "#######&" 
			PRINT " " 
			PRINT " " 
			PRINT " " 
			PRINT " " 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	

END REPORT
#######################################################################
# END REPORT RAE_rpt_list(p_rpt_idx,pr_purchhead, pr_purchdetl, pr_poaudit)
####################################################################### 