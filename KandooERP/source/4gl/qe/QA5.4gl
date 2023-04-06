{
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
}
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../qe/Q_QE_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
DEFINE pr_total_hand_amt LIKE quotehead.hand_amt 
DEFINE pr_total_freight_amt LIKE quotehead.freight_amt 

#######################################################################
# MAIN
#
# Purpose - Program QA5 Quotation Detail Report
#######################################################################
MAIN 
	DEFER quit 
	DEFER interrupt

	CALL setModuleId("QA5") -- albo 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) 
	CALL init_q_qe() 

	SELECT * INTO pr_arparms.* FROM arparms 
	WHERE parm_code = "1" 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode 
			OPEN WINDOW Q124 with FORM "Q124" 

			LET pr_arparms.inv_ref1_text = pr_arparms.inv_ref1_text clipped, 
			"................" 
			DISPLAY BY NAME pr_arparms.inv_ref1_text 
			MENU " Quotation By Detail Report" 
				BEFORE MENU
					CALL QA5_rpt_process(QA5_rpt_query())
					CALL rpt_rmsreps_reset(NULL)
									
				ON ACTION "WEB-HELP" -- albo kd-369 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "REPORT" #COMMAND "Run" " Enter selection criteria AND generate REPORT" 
					CALL QA5_rpt_process(QA5_rpt_query())
					CALL rpt_rmsreps_reset(NULL)

				ON ACTION "Print Manager"	#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				COMMAND KEY("E",interrupt)"Exit" " Exit TO menus" 
					EXIT MENU 
			END MENU 

			CLOSE WINDOW Q124 
	 
		WHEN "2" #Background Process with rmsreps.report_code
			CALL QA5_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW A190 with FORM "A190" 
			CALL winDecoration_a("A190") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(QA5_rpt_query()) #save where clause in env 
			CLOSE WINDOW A190 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL QA5_rpt_process(get_url_sel_text())
	END CASE 
END MAIN 


FUNCTION QA5_rpt_query() 
	DEFINE l_where_text STRING
	
	MESSAGE kandoomsg2("U",1001,"") 
	#1001 Enter Selection Criteria; OK TO Continue
	CONSTRUCT BY NAME l_where_text ON quotehead.cust_code, 
	customer.name_text, 
	quotehead.order_num, 
	quotehead.quote_date, 
	quotehead.valid_date, 
	quotehead.ord_text, 
	quotehead.currency_code, 
	quotehead.ware_code, 
	quotehead.status_ind, 
	quotedetl.part_code, 
	quotedetl.desc_text, 
	quotedetl.offer_code, 
	quotedetl.sold_qty, 
	quotedetl.bonus_qty, 
	quotedetl.disc_per, 
	quotedetl.unit_price_amt, 
	quotedetl.margin_ind, 
	quotehead.entry_code, 
	quotehead.entry_date, 
	quotehead.approved_by, 
	quotehead.approved_date 

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


FUNCTION QA5_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT   
	DEFINE pr_quotedetl RECORD LIKE quotedetl.* 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"QA5_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT QA5_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------

	LET pr_total_freight_amt = 0 
	LET pr_total_hand_amt = 0 
	LET l_query_text = "SELECT quotedetl.* FROM quotedetl,customer,quotehead ", 
	" WHERE quotedetl.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND customer.cmpy_code = quotedetl.cmpy_code ", 
	" AND quotehead.cmpy_code = customer.cmpy_code ", 
	" AND quotehead.cust_code = customer.cust_code ", 
	" AND quotehead.order_num = quotedetl.order_num ", 
			"AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("QA5_rpt_list")].sel_text clipped," ",  
	" ORDER BY quotedetl.cust_code, quotedetl.order_num, ", 
	" quotedetl.line_num" 
	
	PREPARE s_quotedetl FROM l_query_text 
	DECLARE c_quotedetl CURSOR FOR s_quotedetl
	 
	FOREACH c_quotedetl INTO pr_quotedetl.* 

		#---------------------------------------------------------
		OUTPUT TO REPORT QA5_rpt_list(l_rpt_idx,pr_quotedetl.*) 
		IF NOT rpt_int_flag_handler2("Quotation:",pr_quotedetl.order_num, pr_quotedetl.cust_code,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------

	END FOREACH 
	#------------------------------------------------------------

	#------------------------------------------------------------
	FINISH REPORT QA5_rpt_list
	CALL rpt_finish("QA5_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 


REPORT QA5_rpt_list(p_rpt_idx,pr_quotedetl) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE 
	pr_quotedetl RECORD LIKE quotedetl.*, 
	pr_quotehead RECORD LIKE quotehead.*, 
	pr_customer RECORD LIKE customer.*, 
	pr_total_amt LIKE quotehead.total_amt, 
	pr_cust_freight_amt LIKE quotehead.freight_amt, 
	pr_cust_hand_amt LIKE quotehead.hand_amt, 
	pa_line array[4] OF CHAR(132), 
	pr_desc_clipped_text CHAR(35) 

	OUTPUT 
	left margin 01 
	ORDER external BY pr_quotedetl.cust_code, 
	pr_quotedetl.order_num, 
	pr_quotedetl.line_num 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			 
		BEFORE GROUP OF pr_quotedetl.cust_code 
			SELECT * INTO pr_customer.* FROM customer 
			WHERE cust_code = pr_quotedetl.cust_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			SKIP TO top OF PAGE 
			PRINT COLUMN 001, "Customer: ",pr_quotedetl.cust_code, 
			COLUMN 020, pr_customer.name_text clipped, 
			COLUMN 104, pr_quotehead.currency_code 
			SKIP 1 line 
			LET pr_cust_freight_amt = 0 
			LET pr_cust_hand_amt = 0
			 
		BEFORE GROUP OF pr_quotedetl.order_num 
			SELECT * INTO pr_quotehead.* FROM quotehead 
			WHERE order_num = pr_quotedetl.order_num 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			PRINT COLUMN 001, "Quotation #: ", 
			COLUMN 014, pr_quotedetl.order_num USING "#######", 
			COLUMN 024, "Valid Until: ", 
			COLUMN 037, pr_quotehead.valid_date USING "dd/mm/yyyy" 
		
		ON EVERY ROW 
			PRINT COLUMN 001, pr_quotedetl.line_num USING "###", 
			COLUMN 005, pr_quotedetl.part_code, 
			COLUMN 022, pr_quotedetl.desc_text, 
			COLUMN 065, pr_quotedetl.order_qty USING "------&.&&", 
			COLUMN 076, pr_quotedetl.reserved_qty USING "------&.&&", 
			COLUMN 088, pr_quotedetl.uom_code, 
			COLUMN 095, pr_quotedetl.unit_price_amt USING "---,--&.&&", 
			COLUMN 109, pr_quotedetl.ext_price_amt USING "--,---,--&.&&" 
			IF pr_quotedetl.quote_lead_text IS NOT NULL THEN 
				PRINT COLUMN 020, "Availability: ", 
				COLUMN 035, pr_quotedetl.quote_lead_text clipped, 
				pr_quotedetl.quote_lead_text2 
			END IF 
			
		AFTER GROUP OF pr_quotedetl.order_num 
			IF (pr_quotehead.hand_amt + pr_quotehead.hand_tax_amt) != 0 THEN 
				PRINT COLUMN 085, "Insurance/Handling:", 
				COLUMN 109, pr_quotehead.hand_amt + 
				pr_quotehead.hand_tax_amt USING "--,---,--&.&&" 
			END IF 
			IF (pr_quotehead.freight_amt + pr_quotehead.freight_tax_amt) != 0 THEN 
				PRINT COLUMN 085, "Freight:", 
				COLUMN 109, pr_quotehead.freight_amt + 
				pr_quotehead.freight_tax_amt USING "--,---,--&.&&" 
			END IF 
			IF GROUP sum(pr_quotedetl.ext_tax_amt) != 0 THEN 
				PRINT COLUMN 085, "Sales Tax:", 
				COLUMN 109, GROUP sum(pr_quotedetl.ext_tax_amt) 
				USING "--,---,--&.&&" 
			END IF 
			LET pr_total_amt = GROUP sum (pr_quotedetl.ext_price_amt) 
			+ GROUP sum(pr_quotedetl.ext_tax_amt) 
			+ pr_quotehead.freight_tax_amt 
			+ pr_quotehead.freight_amt 
			+ pr_quotehead.hand_amt 
			+ pr_quotehead.hand_tax_amt 
			PRINT COLUMN 107, "---------------" 
			PRINT COLUMN 085, "Quotation Total:", 
			COLUMN 109, pr_total_amt USING "--,---,--&.&&" 
			LET pr_cust_hand_amt = pr_cust_hand_amt 
			+ pr_quotehead.hand_amt 
			+ pr_quotehead.hand_tax_amt 
			LET pr_cust_freight_amt = pr_cust_freight_amt 
			+ pr_quotehead.freight_amt 
			+ pr_quotehead.freight_tax_amt 
			
		AFTER GROUP OF pr_quotedetl.cust_code 
			PRINT COLUMN 107, "---------------" 
			PRINT COLUMN 085, "Client Total:", 
			COLUMN 109, GROUP sum(pr_quotedetl.ext_price_amt) 
			+ GROUP sum(pr_quotedetl.ext_tax_amt) 
			+ pr_cust_hand_amt 
			+ pr_cust_freight_amt USING "--,---,--&.&&" 
			LET pr_total_hand_amt = pr_total_hand_amt + pr_cust_hand_amt 
			LET pr_total_freight_amt = pr_total_freight_amt + pr_cust_freight_amt 
			
		ON LAST ROW 
			SKIP 2 line 
			PRINT COLUMN 107, "===============" 
			PRINT COLUMN 070, "Report Totals: Lines: ", count(*) USING "#####", 
			COLUMN 109, sum(pr_quotedetl.ext_price_amt) 
			+ sum(pr_quotedetl.ext_tax_amt) 
			+ pr_total_freight_amt 
			+ pr_total_hand_amt USING "--,---,--&.&&" 
			SKIP 1 line 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
END REPORT 