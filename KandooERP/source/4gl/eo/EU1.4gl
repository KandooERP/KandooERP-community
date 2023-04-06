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
GLOBALS "../eo/E_EO_GLOBALS.4gl"
GLOBALS "../eo/EU_GROUP_GLOBALS.4gl"  
GLOBALS "../eo/EU1_GLOBALS.4gl" 
###########################################################################
# MODULE Scope Variables
###########################################################################
DEFINE modu_first_time SMALLINT 
DEFINE modu_temp_text char(20) 
DEFINE modu_zero_stats_flag char(1)
DEFINE modu_order_ind char(1)	  
###########################################################################
# FUNCTION EU1_main()
#
# Inventory Yearly Turnover Report Ordered by Product Code OR
#     Product Group OR
#     Main Group
###########################################################################
FUNCTION EU1_main() 

	DEFER QUIT 
	DEFER INTERRUPT 

	CALL setModuleId("EU1") 
	 
	LET modu_first_time = 1
	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	 
			OPEN WINDOW E283 with FORM "E283" 
			 CALL windecoration_e("E283") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
			DISPLAY getmenuitemlabel(NULL) TO header_text 
			
			MENU " Customer Turnover report" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","EU1","menu-Customer-1") -- albo kd-502
					CALL rpt_rmsreps_reset(NULL)
					CALL EU1_rpt_process(EU1_rpt_query())
		 
				ON ACTION "WEB-HELP" -- albo kd-370 
					CALL onlinehelp(getmoduleid(),null)
					 
				ON ACTION "REPORT" #COMMAND "Report" " SELECT criteria AND PRINT report" 
					CALL rpt_rmsreps_reset(NULL)
					CALL EU1_rpt_process(EU1_rpt_query())
		
				ON ACTION "PRINT MANAGER"		#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "CANCEL" #COMMAND KEY(INTERRUPT,"E")"Exit" " RETURN TO menus" 
					EXIT MENU 
		
			END MENU 
			CLOSE WINDOW E283 
	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL EU1_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW E283 with FORM "E283" 
			 CALL windecoration_e("E283") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(EU1_rpt_query()) #save where clause in env 
			CLOSE WINDOW E283 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL EU1_rpt_process(get_url_sel_text())
	END CASE 

END FUNCTION 


###########################################################################
# FUNCTION EU1_rpt_query() 
#
# 
###########################################################################
FUNCTION EU1_rpt_query() 
	DEFINE l_where_text STRING

	IF NOT EU1_rpt_enter_year() THEN
		RETURN NULL
	END IF

	MESSAGE kandoomsg2("E",1001,"") #1001 Enter Selection Criteria - ESC TO Continue
	CONSTRUCT BY NAME l_where_text ON 
		part_code, 
		prodgrp_code, 
		maingrp_code, 
		cat_codve, 
		class_code, 
		desc_text, 
		desc2_text, 
		short_desc_text 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","EU1","construct-part_code-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN NULL
	ELSE
		
		LET glob_rec_rpt_selector.ref1_ind = modu_order_ind
		LET glob_rec_rpt_selector.ref1_num = glob_rec_statparms.year_num
		LET glob_rec_rpt_selector.ref2_ind = modu_zero_stats_flag
						
		RETURN l_where_text
	END IF 
END FUNCTION

############################################################
# FUNCTION EU1_rpt_process(p_where_text) 
#
#
############################################################
FUNCTION EU1_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  #report array index
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_order_text char(35) 
	
	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"EU1_rpt_list_product",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT EU1_rpt_list_product TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------
	#get additional rms_reps values for query
	LET modu_order_ind = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_ind
	LET glob_rec_statparms.year_num = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_num
	LET modu_zero_stats_flag = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref2_ind
	#------------------------------------------------------------
	
	CASE modu_order_ind 
		WHEN "1" 
			LET l_order_text = "part_code" 
		WHEN "2" 
			LET l_order_text = "prodgrp_code,part_code" 
		WHEN "3" 
			LET l_order_text = "maingrp_code,prodgrp_code,part_code" 
	END CASE 
	
	LET l_query_text = "SELECT * FROM product ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND status_ind != '3' ", 
	"AND ",p_where_text clipped," ", 
	"ORDER BY cmpy_code,",l_order_text clipped
	 
	PREPARE s_product FROM l_query_text 
	DECLARE c_product cursor FOR s_product
	 
	LET l_query_text = "SELECT * FROM statprod ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND year_num = ? ", 
	"AND type_code = '",glob_rec_statparms.year_type_code,"' ", 
	"AND int_num = 1 ", 
	"AND part_code = ? " 
	PREPARE s_statprod FROM l_query_text 
	DECLARE c_statprod cursor FOR s_statprod 

	MESSAGE kandoomsg2("E",1161,"") 	#1161 Reporting on Product...
	FOREACH c_product INTO l_rec_product.* 

		#---------------------------------------------------------
		OUTPUT TO REPORT EU1_rpt_list_product(l_rpt_idx,
		l_rec_product.*)  
		IF NOT rpt_int_flag_handler2("Product:",l_rec_product.desc_text, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------
	END FOREACH
	#------------------------------------------------------------
	FINISH REPORT EU1_rpt_list_product
	CALL rpt_finish("EU1_rpt_list_product")
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
# FUNCTION EU1_rpt_enter_year()  
#
# 
###########################################################################
FUNCTION EU1_rpt_enter_year() 

	LET modu_order_ind = "1" 
	LET modu_zero_stats_flag = xlate_to("Y") 
	LET glob_rec_statparms.year_num = year(today) 

	MESSAGE kandoomsg2("E",1157,"") #1157 Enter year FOR REPORT run - ESC TO Continue

	INPUT 
		glob_rec_statparms.year_num, 
		modu_zero_stats_flag, 
		modu_order_ind WITHOUT DEFAULTS 
	FROM
		year_num, 
		zero_stats_flag, 
		order_ind ATTRIBUTE(UNBUFFERED)

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","EU1","input-year_num-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "YEAR-1" --ON KEY (f9) 
			LET glob_rec_statparms.year_num = glob_rec_statparms.year_num - 1 
			NEXT FIELD year_num 

		ON ACTION "YEAR+1" --ON KEY (f10) 
			LET glob_rec_statparms.year_num = glob_rec_statparms.year_num + 1 
			NEXT FIELD year_num 

		AFTER FIELD year_num 
			IF glob_rec_statparms.year_num IS NULL THEN 
				ERROR kandoomsg2("E",9210,"")			#9210 Year number must be entered
				LET glob_rec_statparms.year_num = year(today) 
				NEXT FIELD year_num 
			END IF 
			
	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		LET glob_rec_statparms.year_num = year(today) 
		RETURN FALSE 
	ELSE 
		RETURN TRUE 
	END IF 
END FUNCTION 


###########################################################################
# REPORT EU1_rpt_list_product_product(p_rec_product)  
#
# 
###########################################################################
REPORT EU1_rpt_list_product_product(p_rpt_idx,p_rec_product) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_rec_product RECORD LIKE product.* 
	DEFINE l_rec_cur_statprod RECORD LIKE statprod.* 
	DEFINE l_rec_s_cur_statprod RECORD LIKE statprod.* 
	DEFINE l_rec_statprod RECORD LIKE statprod.* 
	DEFINE l_rec_s_prv_statprod RECORD LIKE statprod.* 
--	DEFINE pa_line array[4] OF char(85) 
	DEFINE l_cur_disc_per, l_prv_disc_per FLOAT 
	DEFINE l_cur_total_disc_per, l_prv_total_disc_per FLOAT 
	DEFINE l_cur_profit_per, l_prv_profit_per FLOAT 
	DEFINE l_cur_total_profit_per, l_prv_total_profit_per FLOAT 
	DEFINE l_sequence_text char(25) 
	DEFINE i SMALLINT 

	OUTPUT 
	left margin 0 
	ORDER external BY p_rec_product.cmpy_code 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			
			LET glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text[67,70] = glob_rec_statparms.year_num USING "####" 
			LET glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text[79,82] = glob_rec_statparms.year_num -1 USING "####" 
			
			PRINT COLUMN 01,glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			CASE modu_order_ind 
				WHEN "1" 
					LET l_sequence_text = "by Product code" 
				WHEN "2" 
					LET l_sequence_text = "by Product Group code" 
				WHEN "3" 
					LET l_sequence_text = "by Main Group code" 
			END CASE 
			PRINT COLUMN 04,l_sequence_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
 
		ON EVERY ROW 
			OPEN c_statprod USING glob_rec_statparms.year_num, 
			p_rec_product.part_code 
			FETCH c_statprod INTO l_rec_cur_statprod.* 
			IF status = NOTFOUND THEN 
				LET l_rec_cur_statprod.gross_amt = 0 
				LET l_rec_cur_statprod.net_amt = 0 
				LET l_rec_cur_statprod.cost_amt = 0 
			END IF 
			LET i = glob_rec_statparms.year_num - 1 
			OPEN c_statprod USING i, 
			p_rec_product.part_code 
			FETCH c_statprod INTO l_rec_statprod.* 
			IF status = NOTFOUND THEN 
				LET l_rec_statprod.gross_amt = 0 
				LET l_rec_statprod.net_amt = 0 
				LET l_rec_statprod.cost_amt = 0 
			END IF 
			IF modu_first_time = 1 THEN 
				LET l_rec_s_cur_statprod.gross_amt = l_rec_cur_statprod.gross_amt 
				LET l_rec_s_cur_statprod.net_amt = l_rec_cur_statprod.net_amt 
				LET l_rec_s_cur_statprod.cost_amt = l_rec_cur_statprod.cost_amt 
				LET l_rec_s_prv_statprod.gross_amt = l_rec_statprod.gross_amt 
				LET l_rec_s_prv_statprod.net_amt = l_rec_statprod.net_amt 
				LET l_rec_s_prv_statprod.cost_amt = l_rec_statprod.cost_amt 
				LET modu_first_time = 2 
			ELSE 
				LET l_rec_s_cur_statprod.gross_amt = l_rec_s_cur_statprod.gross_amt 
				+ l_rec_cur_statprod.gross_amt 
				LET l_rec_s_cur_statprod.net_amt = l_rec_s_cur_statprod.net_amt 
				+ l_rec_cur_statprod.net_amt 
				LET l_rec_s_cur_statprod.cost_amt = l_rec_s_cur_statprod.cost_amt 
				+ l_rec_cur_statprod.cost_amt 
				LET l_rec_s_prv_statprod.gross_amt = l_rec_s_prv_statprod.gross_amt 
				+ l_rec_statprod.gross_amt 
				LET l_rec_s_prv_statprod.net_amt = l_rec_s_prv_statprod.net_amt 
				+ l_rec_statprod.net_amt 
				LET l_rec_s_prv_statprod.cost_amt = l_rec_s_prv_statprod.cost_amt 
				+ l_rec_statprod.cost_amt 
				LET modu_first_time = modu_first_time + 1 
			END IF 
			IF l_rec_cur_statprod.gross_amt = 0 
			AND l_rec_cur_statprod.net_amt = 0 
			AND l_rec_cur_statprod.cost_amt = 0 
			AND l_rec_statprod.gross_amt = 0 
			AND l_rec_statprod.net_amt = 0 
			AND l_rec_statprod.cost_amt = 0 
			AND modu_zero_stats_flag = "N" THEN 
				# Do NOT PRINT zero statistics
			ELSE 
				NEED 6 LINES 
				IF l_rec_cur_statprod.gross_amt = 0 THEN 
					LET l_cur_disc_per = 0 
				ELSE 
					LET l_cur_disc_per = 100 * 
					(1-(l_rec_cur_statprod.net_amt/l_rec_cur_statprod.gross_amt)) 
				END IF 
				IF l_rec_statprod.gross_amt = 0 THEN 
					LET l_prv_disc_per = 0 
				ELSE 
					LET l_prv_disc_per = 100 * 
					(1-(l_rec_statprod.net_amt/l_rec_statprod.gross_amt)) 
				END IF 
				IF (l_rec_cur_statprod.net_amt - l_rec_cur_statprod.cost_amt) = 0 THEN 
					LET l_cur_profit_per = 0 
				ELSE 
					LET l_cur_profit_per = 100 * 
					((l_rec_cur_statprod.net_amt-l_rec_cur_statprod.cost_amt) 
					/(l_rec_cur_statprod.net_amt)) 
				END IF 
				IF (l_rec_statprod.net_amt - l_rec_statprod.cost_amt) = 0 THEN 
					LET l_prv_profit_per = 0 
				ELSE 
					LET l_prv_profit_per = 100 * 
					((l_rec_statprod.net_amt-l_rec_statprod.cost_amt) 
					/(l_rec_statprod.net_amt)) 
				END IF 
				PRINT COLUMN 01, p_rec_product.part_code, 
				COLUMN 17, p_rec_product.desc_text, 
				COLUMN 48, "Gross turnover", 
				COLUMN 63, l_rec_cur_statprod.gross_amt USING "---,---,--&", 
				COLUMN 75, l_rec_statprod.gross_amt USING "---,---,--&" 
				PRINT COLUMN 19, "Main Group: ", 
				COLUMN 34, p_rec_product.maingrp_code, 
				COLUMN 48, "Nett turnover", 
				COLUMN 63, l_rec_cur_statprod.net_amt USING "---,---,--&", 
				COLUMN 75, l_rec_statprod.net_amt USING "---,---,--&" 
				PRINT COLUMN 19, "Product Group: ", 
				COLUMN 34, p_rec_product.prodgrp_code, 
				COLUMN 48, "Cost", 
				COLUMN 63, l_rec_cur_statprod.cost_amt USING "---,---,--&", 
				COLUMN 75, l_rec_statprod.cost_amt USING "---,---,--&" 
				PRINT COLUMN 48, "Profit", 
				COLUMN 63, l_rec_cur_statprod.net_amt - 
				l_rec_cur_statprod.cost_amt USING "---,---,--&", 
				COLUMN 75, l_rec_statprod.net_amt - 
				l_rec_statprod.cost_amt USING "---,---,--&" 
				PRINT COLUMN 48, "Discount %", 
				COLUMN 68, l_cur_disc_per USING "---&.&", 
				COLUMN 80, l_prv_disc_per USING "---&.&" 
				PRINT COLUMN 48, "Profit %", 
				COLUMN 68, l_cur_profit_per USING "---&.&", 
				COLUMN 80, l_prv_profit_per USING "---&.&" 
				SKIP 1 line 
			END IF 
			
		ON LAST ROW 
			IF l_rec_s_cur_statprod.gross_amt = 0 THEN 
				LET l_cur_total_disc_per = 0 
			ELSE 
				LET l_cur_total_disc_per = 100 * 
				(1-(l_rec_s_cur_statprod.net_amt/l_rec_s_cur_statprod.gross_amt)) 
			END IF 
			IF l_rec_s_prv_statprod.gross_amt = 0 THEN 
				LET l_prv_total_disc_per = 0 
			ELSE 
				LET l_prv_total_disc_per = 100 * 
				(1-(l_rec_s_prv_statprod.net_amt / l_rec_s_prv_statprod.gross_amt)) 
			END IF 
			IF (l_rec_s_cur_statprod.net_amt - l_rec_s_cur_statprod.cost_amt) = 0 THEN 
				LET l_cur_total_profit_per = 0 
			ELSE 
				LET l_cur_total_profit_per = 100 * 
				((l_rec_s_cur_statprod.net_amt-l_rec_s_cur_statprod.cost_amt) 
				/ (l_rec_s_cur_statprod.net_amt)) 
			END IF 
			IF (l_rec_s_prv_statprod.net_amt - l_rec_s_prv_statprod.cost_amt) = 0 THEN 
				LET l_prv_total_profit_per = 0 
			ELSE 
				LET l_prv_total_profit_per = 100 * 
				((l_rec_s_prv_statprod.net_amt-l_rec_s_prv_statprod.cost_amt) 
				/ (l_rec_s_prv_statprod.net_amt)) 
			END IF 
			PRINT COLUMN 48, "--------------------------------------" 
			PRINT COLUMN 19, "Total: ", 
			COLUMN 48, "Gross turnover", 
			COLUMN 63, l_rec_s_cur_statprod.gross_amt USING "---,---,--&", 
			COLUMN 75, l_rec_s_prv_statprod.gross_amt USING "---,---,--&" 
			PRINT COLUMN 48, "Nett turnover", 
			COLUMN 63, l_rec_s_cur_statprod.net_amt USING "---,---,--&", 
			COLUMN 75, l_rec_s_prv_statprod.net_amt USING "---,---,--&" 
			PRINT COLUMN 48, "Cost", 
			COLUMN 63, l_rec_s_cur_statprod.cost_amt USING "---,---,--&", 
			COLUMN 75, l_rec_s_prv_statprod.cost_amt USING "---,---,--&" 
			PRINT COLUMN 48, "Profit", 
			COLUMN 63, l_rec_s_cur_statprod.net_amt - 
			l_rec_s_cur_statprod.cost_amt USING "---,---,--&", 
			COLUMN 75, l_rec_s_prv_statprod.net_amt - 
			l_rec_s_prv_statprod.cost_amt USING "---,---,--&" 
			PRINT COLUMN 48, "Discount %", 
			COLUMN 68, l_cur_total_disc_per USING "---&.&", 
			COLUMN 80, l_prv_total_disc_per USING "---&.&" 
			PRINT COLUMN 48, "Profit %", 
			COLUMN 68, l_cur_total_profit_per USING "---&.&", 
			COLUMN 80, l_prv_total_profit_per USING "---&.&" 
			SKIP 1 LINES 

			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
			LET modu_first_time = 1 
 
END REPORT 