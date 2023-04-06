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
GLOBALS "Q_QE_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
DEFINE pr_row_flag CHAR(1) 
#######################################################################
# MAIN
#
# \brief module QA1 - Quotation Listing By Customer
#######################################################################
MAIN 
	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("QA1") -- albo 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) 
	CALL init_q_qe() 

	SELECT * INTO pr_arparms.* FROM arparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 
	IF status = notfound THEN 
		EXIT program 
	END IF 
	DELETE FROM kandooreport 
	WHERE report_code = "QA1"
	 
	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode 	
			OPEN WINDOW Q100 with FORM "Q100" 

			LET pr_arparms.inv_ref1_text = pr_arparms.inv_ref1_text clipped, 
			"................" 
			DISPLAY BY NAME pr_arparms.inv_ref1_text
			 
			MENU " Quotation By Customer" 
				ON ACTION "WEB-HELP" -- albo kd-369 
					CALL onlinehelp(getmoduleid(),null) 
					
				ON ACTION "REPORT" #COMMAND "Run" " SELECT Criteria AND PRINT REPORT" 
					CALL QA1_rpt_process(QA1_rpt_query())
					CALL rpt_rmsreps_reset(NULL)

				ON ACTION "Print Manager" 	#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" #COMMAND KEY("E",interrupt)"Exit" " Exit TO menus" 
					EXIT MENU 

			END MENU 
			CLOSE WINDOW Q100
			 
		WHEN "2" #Background Process with rmsreps.report_code
			CALL QA1_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW Q100 with FORM "Q100" 
			CALL windecoration_q("Q100") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(QA1_rpt_query()) #save where clause in env 
			CLOSE WINDOW Q100 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL QA1_rpt_process(get_url_sel_text())
	END CASE 
	 
END MAIN 


FUNCTION QA1_rpt_query() 
	DEFINE l_where_text STRING
	
	MESSAGE kandoomsg2("U",1001,"") 
	CONSTRUCT BY NAME l_where_text ON quotehead.cust_code, 
	customer.name_text, 
	quotehead.order_num, 
	quotehead.currency_code, 
	quotehead.goods_amt, 
	quotehead.hand_amt, 
	quotehead.freight_amt, 
	quotehead.tax_amt, 
	quotehead.total_amt, 
	quotehead.cost_amt, 
	quotehead.disc_amt, 
	quotehead.approved_by, 
	quotehead.approved_date, 
	quotehead.ord_text, 
	quotehead.quote_date, 
	quotehead.valid_date, 
	quotehead.ship_date, 
	quotehead.status_ind, 
	quotehead.entry_code, 
	quotehead.entry_date, 
	quotehead.rev_date, 
	quotehead.rev_num, 
	quotehead.com1_text, 
	quotehead.com2_text, 
	quotehead.com3_text, 
	quotehead.com4_text 

		ON ACTION "WEB-HELP" -- albo kd-369 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 
	
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL
	ELSE
		RETURN l_where_text
	END IF 
END FUNCTION


FUNCTION QA1_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  
	DEFINE pr_quotehead RECORD LIKE quotehead.* 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"QA1_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT QA1_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------

	LET l_query_text = "SELECT quotehead.* FROM quotehead, customer ", 
	" WHERE quotehead.cmpy_code = '", glob_rec_kandoouser.cmpy_code,"' ", 
	" AND quotehead.cmpy_code = customer.cmpy_code ", 
	" AND quotehead.cust_code = customer.cust_code ", 
			"AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("QA1_rpt_list")].sel_text clipped," ",
	" ORDER BY quotehead.cust_code, order_num" 
	
	PREPARE s_quotehead FROM l_query_text 
	DECLARE c_quotehead CURSOR FOR s_quotehead 
	LET pr_row_flag = false 
	FOREACH c_quotehead INTO pr_quotehead.*

		#---------------------------------------------------------
		OUTPUT TO REPORT QA1_rpt_list(l_rpt_idx,
		pr_quotehead.*) 
		IF NOT rpt_int_flag_handler2("Quotation:",pr_quotehead.order_num, pr_quotehead.cust_code,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------
	 
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT QA1_rpt_list
	CALL rpt_finish("QA1_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 


REPORT QA1_rpt_list(p_rpt_idx,pr_quotehead) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE 
	pr_quotehead RECORD LIKE quotehead.*, 
	pr_customer RECORD LIKE customer.*, 
	pa_line array[4] OF CHAR(80) 

	OUTPUT 
	--left margin 1 
	ORDER external BY pr_quotehead.cust_code, 
	pr_quotehead.order_num 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			
		BEFORE GROUP OF pr_quotehead.cust_code 
			NEED 3 LINES 
			SELECT * INTO pr_customer.* FROM customer 
			WHERE cust_code = pr_quotehead.cust_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF pr_row_flag THEN 
				PRINT "----------------------------------------", 
				"----------------------------------------" 
			ELSE 
				LET pr_row_flag = true 
			END IF 
			PRINT COLUMN 01, "Customer: ", pr_quotehead.cust_code, 
			COLUMN 20, pr_customer.name_text, 
			COLUMN 57, pr_quotehead.currency_code 
			SKIP 1 line 
			
		ON EVERY ROW 
			PRINT COLUMN 01, pr_quotehead.order_num USING "#######", 
			COLUMN 10, pr_quotehead.ord_text, 
			COLUMN 32, pr_quotehead.quote_date USING "dd/mm/yy", 
			COLUMN 42, pr_quotehead.valid_date USING "dd/mm/yy", 
			COLUMN 60, pr_quotehead.total_amt USING "--,---,--&.&&", 
			COLUMN 78, pr_quotehead.status_ind 
			
		AFTER GROUP OF pr_quotehead.cust_code 
			NEED 3 LINES 
			PRINT " ----------", 
			"-- ------------ " 
			PRINT COLUMN 01, "Quotes:", GROUP count(*) USING "#####", 
			COLUMN 25, "Avg: ", COLUMN 22, GROUP avg(pr_quotehead.total_amt) 
			USING "--,---,--&.&&", 
			COLUMN 60, GROUP sum(pr_quotehead.total_amt) USING "--,---,--&.&&" 
			SKIP 1 line 
			
		ON LAST ROW 
			SKIP 1 line 
			PRINT COLUMN 01, "Quotes:", count(*) USING "#####", 
			COLUMN 25, "Avg: ", COLUMN 22, avg(pr_quotehead.total_amt) 
			USING "--,---,--&.&&", 
			COLUMN 60, sum(pr_quotehead.total_amt) USING "--,---,--&.&&" 
			SKIP 1 line 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
END REPORT