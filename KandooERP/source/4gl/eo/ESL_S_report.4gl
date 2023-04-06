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
GLOBALS "../eo/E_EO_GLOBALS.4gl"
GLOBALS "../eo/ES_GROUP_GLOBALS.4gl"  
GLOBALS "../eo/ESL_GLOBALS.4gl"

###########################################################################
# REPORT ESL_rpt_list_exception(p_rpt_idx,p_cust_code,p_part_code,p_order_ref,p_status) 
#
# 
###########################################################################
REPORT ESL_rpt_list_exception(p_rpt_idx,p_cust_code,p_part_code,p_order_ref,p_status)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	 
--	DEFINE pa_line array[4] OF char(132) 
	DEFINE p_cust_code char(3) 
	DEFINE p_part_code LIKE product.part_code 
	DEFINE p_order_ref char(10) 
	DEFINE p_status char(132) 

	OUTPUT 
 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text clipped 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  

		ON EVERY ROW 
			PRINT COLUMN 01, p_cust_code, 
			COLUMN 11, p_part_code, 
			COLUMN 28, p_order_ref, 
			COLUMN 40, p_status[1,90] 
			
		ON LAST ROW 
			NEED 3 LINES 
			SKIP 2 LINES 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			--LET rpt1_pageno = pageno 
END REPORT 
###########################################################################
# END REPORT ESL_rpt_list_exception(p_rpt_idx,p_cust_code,p_part_code,p_order_ref,p_status) 
###########################################################################


###########################################################################
# REPORT ESL_rpt_list_inserted(p_line_inserted)  
#
# 
###########################################################################
REPORT ESL_rpt_list_inserted(p_rpt_idx,p_line_inserted) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_line_inserted INTEGER
	DEFINE l_rec_company RECORD LIKE company.* 

	OUTPUT 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			#next 2 lines need checking... first seems duplicated
			PRINT COLUMN 01, "Store Allocation report" 
			PRINT COLUMN 01, today using "dd/mm/yyyy", 11 spaces, "Profit Order Import Summary (Load No: ",glob_rec_loadparms.seq_num using "<<<<<",")",11 spaces, "Page: 1"
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			PRINT COLUMN 01, " " 
			PRINT COLUMN 01, " " 

		ON EVERY ROW 
			PRINT COLUMN 01, " Order Lines Successfully Inserted: ", p_line_inserted USING "#######&" 
			PRINT COLUMN 01, " Order Lines With Errors: ", glob_err_cnt USING "#######&" 
			PRINT COLUMN 01, " --------" 
			PRINT COLUMN 01, " Total Order Lines Processed: ", (p_line_inserted + glob_err_cnt) USING "#######&" 


		ON LAST ROW 
			SKIP 4 LINES 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
		

END REPORT 
###########################################################################
# END REPORT ESL_rpt_list_inserted(p_line_inserted)  
###########################################################################


###########################################################################
# REPORT ESL_rpt_list_detailed(p_rec_orderdetl, l_prod_desc)   
#
# 
###########################################################################
REPORT ESL_rpt_list_detailed(p_rpt_idx,p_rec_orderdetl, l_prod_desc) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_rec_orderdetl RECORD LIKE orderdetl.* 
	DEFINE l_prod_desc char(61) 

	OUTPUT 

	ORDER BY p_rec_orderdetl.maingrp_code, 
	p_rec_orderdetl.part_code, 
	p_rec_orderdetl.cust_code 
	
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			 
#			PRINT COLUMN 01, time, 
#			COLUMN offset2, "Store Allocation report" 

			#      PRINT COLUMN 01, today using "dd/mm/yyyy", 22 spaces, "Profit Order Import List (Load No: ",glob_rec_loadparms.seq_num using "<<<<<",")",22 spaces, "Page: 1"
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			PRINT COLUMN 01, "Main Grp Part Code description", 
			COLUMN 87, "Customer Quantity " 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		BEFORE GROUP OF p_rec_orderdetl.part_code 
			PRINT COLUMN 04, p_rec_orderdetl.maingrp_code, 
			COLUMN 10, p_rec_orderdetl.part_code, 
			COLUMN 26, l_prod_desc; 

		AFTER GROUP OF p_rec_orderdetl.part_code 
			SKIP 1 line 

		AFTER GROUP OF p_rec_orderdetl.maingrp_code 
			SKIP TO top OF PAGE 

		ON EVERY ROW 
			PRINT COLUMN 88, p_rec_orderdetl.cust_code, 
			COLUMN 97, p_rec_orderdetl.order_qty USING "#######&" 

		ON LAST ROW 
			SKIP 4 LINES 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
END REPORT
###########################################################################
# END REPORT ESL_rpt_list_detailed(p_rec_orderdetl, l_prod_desc)   
###########################################################################