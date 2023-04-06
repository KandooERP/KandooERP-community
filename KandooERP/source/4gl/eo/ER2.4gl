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
###########################################################################
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../eo/E_EO_GLOBALS.4gl"
GLOBALS "../eo/ER_GROUP_GLOBALS.4gl"  
GLOBALS "../eo/ER2_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################
DEFINE modu_prompt_text char(40) 

###########################################################################
# FUNCTION ER2_main()
#
# ER2 Detailed Held Order Report
###########################################################################
FUNCTION ER2_main() 
	DEFER QUIT 
	DEFER INTERRUPT 
	
	CALL setModuleId("ER2") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	
		OPEN WINDOW E160 with FORM "E160" 
			 CALL windecoration_e("E160") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title

			LET modu_prompt_text = glob_rec_arparms.inv_ref1_text clipped, 	".................."
			DISPLAY modu_prompt_text TO prompt_text attribute(white)
			 
			MENU " Detailed Held Order report" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","ER2","menu-Detailed_Held-1") -- albo kd-502 
					CALL rpt_rmsreps_reset(NULL)
					CALL ER2_rpt_process(ER2_rpt_query())
					
				ON ACTION "WEB-HELP" -- albo kd-370 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "REPORT"	#COMMAND "Report" " SELECT criteria AND PRINT report" 
					CALL rpt_rmsreps_reset(NULL)
					CALL ER2_rpt_process(ER2_rpt_query())

				ON ACTION "PRINT MANAGER" 	#COMMAND KEY ("P",f11) "Print" " Print OR view the REPORT using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" #COMMAND KEY(INTERRUPT,"E")"Exit" " RETURN TO menus" 
					EXIT MENU 
			END MENU 

			CLOSE WINDOW E160 

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL ER2_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW E160 with FORM "E160" 
			 CALL windecoration_e("E160") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(ER2_rpt_query()) #save where clause in env 
			CLOSE WINDOW E160 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL ER2_rpt_process(get_url_sel_text())
	END CASE 	
	
END FUNCTION 
###########################################################################
# END FUNCTION ER2_main()
###########################################################################


###########################################################################
# FUNCTION ER2_rpt_query()
#
#
###########################################################################
FUNCTION ER2_rpt_query() 
	DEFINE l_where_text STRING

	MESSAGE kandoomsg2("U",1001,"") #1001 Enter Selection Criteria - ESC TO Continue
	CONSTRUCT BY NAME l_where_text ON 
	cust_code, 
	hold_code, 
	order_num, 
	ord_text, 
	order_date, 
	total_amt, 
	currency_code, 
	sales_code, 
	cond_code, 
	ware_code 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","ER2","construct-cust_code-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN NULL	
	ELSE 
		RETURN l_where_text 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION ER2_rpt_query()
###########################################################################


###########################################################################
# FUNCTION ER2_rpt_process(p_where_text)
#
#
###########################################################################
FUNCTION ER2_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING	
	DEFINE l_rpt_idx SMALLINT  #report array index
	DEFINE l_rec_orderhead RECORD LIKE orderhead.*	 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"ER2_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT ER2_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text	
	#------------------------------------------------------------

	LET l_query_text = "SELECT * FROM orderhead ", 
	"WHERE orderhead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND hold_code IS NOT NULL ", 
	"AND status_ind in ('U','P') ", 
	" AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ER2_rpt_list")].sel_text clipped, " ", 
	"ORDER BY currency_code, ", 
	"cust_code, order_date" 
	PREPARE s_orderhead FROM l_query_text 
	DECLARE c_orderhead cursor FOR s_orderhead 
	
	FOREACH c_orderhead INTO l_rec_orderhead.*
 	 	#---------------------------------------------------------
		OUTPUT TO REPORT ER2_rpt_list(l_rpt_idx,
		l_rec_orderhead.*)   
		
		IF NOT rpt_int_flag_handler2("Order:",l_rec_orderhead.order_num,NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------		
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT ER2_rpt_list
	CALL rpt_finish("ER2_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = FALSE 
		ERROR " Printing was aborted" 
		RETURN FALSE 
	ELSE 
		RETURN TRUE 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION ER2_rpt_process(p_where_text)
###########################################################################


###########################################################################
# REPORT ER2_rpt_list(p_rpt_idx,p_rec_orderhead)
#
#
###########################################################################
REPORT ER2_rpt_list(p_rpt_idx,p_rec_orderhead) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_rec_orderhead RECORD LIKE orderhead.* 
	DEFINE l_rec_company RECORD LIKE company.* 
	DEFINE l_rec_orderdetl RECORD LIKE orderdetl.* 
	DEFINE l_rec_holdreas RECORD LIKE holdreas.* 

	OUTPUT 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 01, glob_rec_arparms.inv_ref1_text --glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text  
			PRINT COLUMN 31, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line4_text 
			PRINT COLUMN 52, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line5_text 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line3_text 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		BEFORE GROUP OF p_rec_orderhead.currency_code 
			SKIP TO top OF PAGE 
			
		ON EVERY ROW 
			SELECT * INTO l_rec_holdreas.* FROM holdreas 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND hold_code = p_rec_orderhead.hold_code 
			IF status = NOTFOUND THEN 
				LET l_rec_holdreas.reason_text = "**********" 
			END IF 
			PRINT COLUMN 1, p_rec_orderhead.cust_code, 
			COLUMN 11, p_rec_orderhead.order_date USING "dd/mm/yy", 
			COLUMN 21, p_rec_orderhead.order_num USING "########", 
			COLUMN 31, p_rec_orderhead.ord_text, 
			COLUMN 55, p_rec_orderhead.cond_code, 
			COLUMN 66, p_rec_orderhead.ware_code, 
			COLUMN 73, p_rec_orderhead.total_amt USING "---,---,--&.&&", 
			COLUMN 92, p_rec_orderhead.hold_code, 
			COLUMN 97, l_rec_holdreas.reason_text 
			
			DECLARE c_orderdetl cursor FOR 
			SELECT * FROM orderdetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND order_num = p_rec_orderhead.order_num 
			ORDER BY cmpy_code, cust_code, order_num, line_num 
			FOREACH c_orderdetl INTO l_rec_orderdetl.* 
				PRINT COLUMN 3, l_rec_orderdetl.offer_code, 
				COLUMN 16, l_rec_orderdetl.part_code, 
				COLUMN 31, l_rec_orderdetl.desc_text, 
				COLUMN 62, l_rec_orderdetl.sold_qty USING "--,--&.&&", 
				COLUMN 75, l_rec_orderdetl.bonus_qty USING "--,--&.&&", 
				COLUMN 90, l_rec_orderdetl.unit_price_amt USING "-,---,--&.&&", 
				COLUMN 108, l_rec_orderdetl.disc_per USING "--&.&&", 
				COLUMN 116, l_rec_orderdetl.tax_code 
			END FOREACH 
			
			SKIP 1 line 
			
		AFTER GROUP OF p_rec_orderhead.cust_code 
			SKIP 1 line 
			
		AFTER GROUP OF p_rec_orderhead.currency_code 
			PRINT COLUMN 56, "-----------------------------------" 
			PRINT COLUMN 56, "Currency total", 
			COLUMN 71, GROUP sum(p_rec_orderhead.total_amt) USING "-----,---,--&.&&", 
			COLUMN 88, p_rec_orderhead.currency_code, 
			COLUMN 95, "Held Orders: ", 
			COLUMN 108, GROUP count(*) USING "<<<" 
			
		ON LAST ROW 
			SKIP 4 LINES 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = pageno
END REPORT
###########################################################################
# END REPORT ER2_rpt_list(p_rpt_idx,p_rec_orderhead)
###########################################################################