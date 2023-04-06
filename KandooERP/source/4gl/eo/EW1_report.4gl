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
GLOBALS "../eo/EW_GROUP_GLOBALS.4gl"
GLOBALS "../eo/EW1_GLOBALS.4gl"  

###########################################################################
# REPORT EW1_rpt_list(p_rpt_idx,p_rec_cur_distterr, 
#	p_rec_prv_distterr, 
#	p_rec_cy_distterr, 
#	p_rec_py_distterr) 
#
# 
###########################################################################
REPORT EW1_rpt_list(p_rpt_idx,
	p_rec_cur_distterr, 
	p_rec_prv_distterr, 
	p_rec_cy_distterr, 
	p_rec_py_distterr,
	p_rec_statint,
	p_rec_criteria)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	  
	DEFINE p_rec_cur_distterr RECORD LIKE distterr.* 
	DEFINE p_rec_prv_distterr RECORD LIKE distterr.* 
	DEFINE p_rec_cy_distterr RECORD LIKE distterr.* 
	DEFINE p_rec_py_distterr RECORD LIKE distterr.* 
	DEFINE p_rec_statint RECORD LIKE statint.*
	DEFINE p_rec_criteria RECORD 
		part_ind char(1), 
		pgrp_ind char(1), 
		mgrp_ind char(1) 
	END RECORD 
	DEFINE l_rec_statterr RECORD LIKE statterr.* 
	DEFINE l_desc_text LIKE product.desc_text 
	DEFINE l_ytd_net_amt LIKE statterr.net_amt 
	DEFINE l_ytd_sales_qty LIKE statterr.sales_qty
	DEFINE l_ytd_orders_num LIKE statterr.new_cust_num 
	DEFINE l_ytd_offers_num LIKE statterr.new_cust_num 
	DEFINE l_ytd_credits_num LIKE statterr.new_cust_num 
	DEFINE l_ytd_poss_cust_num LIKE statterr.new_cust_num
	DEFINE l_ytd_buy_cust_num LIKE statterr.new_cust_num
	DEFINE l_ytd_new_cust_num LIKE statterr.new_cust_num
	DEFINE l_ytd_lost_cust_num LIKE statterr.new_cust_num 
	DEFINE l_avg_ord LIKE statterr.orders_num
	DEFINE l_avg_ord_ytd LIKE statterr.orders_num
	DEFINE l_poss_cust_per FLOAT 
	DEFINE l_int_num LIKE statint.int_num 
	DEFINE l_year_num SMALLINT 
	DEFINE x SMALLINT 
	DEFINE i SMALLINT 
	DEFINE j SMALLINT 

	OUTPUT 

	ORDER BY p_rec_cur_distterr.cmpy_code, 
	p_rec_cur_distterr.area_code, 
	p_rec_cur_distterr.maingrp_code, 
	p_rec_cur_distterr.prodgrp_code, 
	p_rec_cur_distterr.part_code 
	
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			SELECT desc_text INTO l_desc_text FROM salearea 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND area_code = p_rec_cur_distterr.area_code 

			SELECT sum(net_amt),sum(sales_qty),sum(orders_num),sum(offers_num), 
			sum(credits_num),sum(poss_cust_num),sum(buy_cust_num), 
			sum(new_cust_num), sum(lost_cust_num) 
			INTO l_ytd_net_amt,l_ytd_sales_qty,l_ytd_orders_num, 
			l_ytd_offers_num,l_ytd_credits_num,l_ytd_poss_cust_num, 
			l_ytd_buy_cust_num, l_ytd_new_cust_num,l_ytd_lost_cust_num 
			FROM statterr 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND area_code = p_rec_cur_distterr.area_code 
			AND terr_code IS NULL 
			AND year_num = p_rec_statint.year_num 
			AND type_code = glob_rec_statparms.mth_type_code 
			AND int_num between 1 AND p_rec_statint.int_num 

			IF l_ytd_net_amt IS NULL THEN 
				LET l_ytd_net_amt = 0 
			END IF 
			IF l_ytd_sales_qty IS NULL THEN 
				LET l_ytd_sales_qty = 0 
			END IF 
			IF l_ytd_orders_num IS NULL THEN 
				LET l_ytd_orders_num = 0 
			END IF 
			IF l_ytd_offers_num IS NULL THEN 
				LET l_ytd_offers_num = 0 
			END IF 
			IF l_ytd_credits_num IS NULL THEN 
				LET l_ytd_credits_num = 0 
			END IF 
			IF l_ytd_poss_cust_num IS NULL THEN 
				LET l_ytd_poss_cust_num = 0 
			END IF 
			IF l_ytd_buy_cust_num IS NULL THEN 
				LET l_ytd_buy_cust_num = 0 
			END IF 
			IF l_ytd_new_cust_num IS NULL THEN 
				LET l_ytd_new_cust_num = 0 
			END IF 
			IF l_ytd_lost_cust_num IS NULL THEN 
				LET l_ytd_lost_cust_num = 0 
			END IF 

			SELECT * INTO l_rec_statterr.* FROM statterr 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND area_code = p_rec_cur_distterr.area_code 
			AND terr_code IS NULL 
			AND year_num = p_rec_statint.year_num 
			AND type_code = glob_rec_statparms.mth_type_code 
			AND int_num = p_rec_statint.int_num 
			IF status = NOTFOUND THEN 
				LET l_rec_statterr.net_amt = 0 
				LET l_rec_statterr.sales_qty = 0 
				LET l_rec_statterr.orders_num = 0 
				LET l_rec_statterr.credits_num = 0 
				LET l_rec_statterr.poss_cust_num = 0 
				LET l_rec_statterr.buy_cust_num = 0 
				LET l_rec_statterr.new_cust_num = 0 
				LET l_rec_statterr.lost_cust_num = 0 
			END IF 

			IF (l_rec_statterr.orders_num - l_rec_statterr.credits_num) = 0 THEN 
				LET l_avg_ord = 0 
			ELSE 
				LET l_avg_ord = l_rec_statterr.net_amt / 	(l_rec_statterr.orders_num - l_rec_statterr.credits_num) 
			END IF 
			IF (l_ytd_orders_num - l_ytd_credits_num) = 0 THEN 
				LET l_avg_ord_ytd = 0 
			ELSE 
				LET l_avg_ord_ytd = l_ytd_net_amt/ 	(l_ytd_orders_num - l_ytd_credits_num) 
			END IF 
			PRINT COLUMN 01,"Sales Area: ", 
			COLUMN 13,p_rec_cur_distterr.area_code, 
			COLUMN 19,l_desc_text, 
			COLUMN 52,"Customers Curr YTD ", 
			COLUMN 88,"Orders Curr ytd" 
			
			PRINT COLUMN 52,"-----------------------------", 
			COLUMN 88,"----------------------------" 
			
			PRINT COLUMN 52,"Customer count", 
			COLUMN 69,l_rec_statterr.poss_cust_num USING "####&", 
			COLUMN 76,l_rec_statterr.poss_cust_num USING "####&", 
			COLUMN 88,"Orders count", 
			COLUMN 104,l_rec_statterr.orders_num USING "####&", 
			COLUMN 111,l_ytd_orders_num USING "####&" 
			
			PRINT COLUMN 52,"Buying customers", 
			COLUMN 69,l_rec_statterr.buy_cust_num USING "####&", 
			COLUMN 76,l_ytd_buy_cust_num USING "####&", 
			COLUMN 88,"Credits count", 
			COLUMN 104,l_rec_statterr.credits_num USING "####&", 
			COLUMN 111,l_ytd_credits_num USING "####&" 
			
			PRINT COLUMN 01,"Start Date: ", p_rec_statint.start_date USING "dd/mm/yy",
			COLUMN 52,"New customers", 
			COLUMN 69,l_rec_statterr.new_cust_num USING "####&", 
			COLUMN 76,l_ytd_new_cust_num USING "####&", 
			COLUMN 88,"Avg ord value", 
			COLUMN 103,l_avg_ord USING "-----&", 
			COLUMN 110,l_avg_ord_ytd USING "-----&" 

			PRINT COLUMN 01," END Date: ", p_rec_statint.end_date USING "dd/mm/yy",
			COLUMN 52,"Lost customers", 
			COLUMN 69,l_rec_statterr.lost_cust_num USING "####&", 
			COLUMN 76,l_ytd_lost_cust_num USING "####&" 
 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text #wasl_arr_line[1]
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line3_text #wasl_arr_line[3] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			
		BEFORE GROUP OF p_rec_cur_distterr.area_code 
			SKIP TO top OF PAGE 
			
		AFTER GROUP OF p_rec_cur_distterr.part_code 
			NEED 3 LINES 
			IF p_rec_criteria.part_ind = "Y" THEN 
				SELECT desc_text INTO l_desc_text FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = p_rec_cur_distterr.part_code 
				IF l_rec_statterr.poss_cust_num = 0 THEN 
					LET l_poss_cust_per = 0 
				ELSE 
					LET l_poss_cust_per = 100 * 
					(group sum(p_rec_cy_distterr.mth_cust_num)/l_rec_statterr.poss_cust_num) 
				END IF 
				PRINT COLUMN 10,p_rec_cur_distterr.part_code, 
				COLUMN 26,l_desc_text, 
				COLUMN 58,p_rec_statint.year_num USING "####", 
				COLUMN 64,l_poss_cust_per USING "---&.&", 
				COLUMN 75,group sum(p_rec_cur_distterr.mth_sales_qty) USING "-----&", 
				COLUMN 82,group sum(p_rec_cur_distterr.mth_net_amt) USING "---,---,--&", 
				COLUMN 94,group sum(p_rec_cur_distterr.mth_cust_num) USING "-----&", 
				COLUMN 105,group sum(p_rec_cy_distterr.mth_sales_qty)	USING "-----&", 
				COLUMN 112,group sum(p_rec_cy_distterr.mth_net_amt) USING "---,---,--&", 
				COLUMN 124,group sum(p_rec_cy_distterr.mth_cust_num)USING "-----&" 
				
				PRINT COLUMN 58,(p_rec_statint.year_num-1) USING "####", 
				COLUMN 75,group sum(p_rec_prv_distterr.mth_sales_qty)	USING "-----&", 
				COLUMN 82,group sum(p_rec_prv_distterr.mth_net_amt) USING "----------&", 
				COLUMN 94,group sum(p_rec_prv_distterr.mth_cust_num) USING "-----&", 
				COLUMN 105,group sum(p_rec_py_distterr.mth_sales_qty) USING "-----&", 
				COLUMN 112,group sum(p_rec_py_distterr.mth_net_amt) USING "----------&", 
				COLUMN 124,group sum(p_rec_py_distterr.mth_cust_num) USING "-----&" 
			END IF 
			
		AFTER GROUP OF p_rec_cur_distterr.prodgrp_code 
			NEED 4 LINES 
			IF p_rec_criteria.pgrp_ind = "Y" THEN 
				SELECT desc_text INTO l_desc_text FROM prodgrp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND prodgrp_code = p_rec_cur_distterr.prodgrp_code 
				IF l_rec_statterr.poss_cust_num = 0 THEN 
					LET l_poss_cust_per = 0 
				ELSE 
					LET l_poss_cust_per = 100 * 
					(group sum(p_rec_cy_distterr.mth_cust_num)/l_rec_statterr.poss_cust_num) 
				END IF 
				PRINT COLUMN 05,"Product group:", 
				COLUMN 20,p_rec_cur_distterr.prodgrp_code, 
				COLUMN 26,l_desc_text, 
				COLUMN 58,p_rec_statint.year_num USING "####", 
				COLUMN 64,l_poss_cust_per USING "---&.&", 
				COLUMN 75,group sum(p_rec_cur_distterr.mth_sales_qty) USING "-----&", 
				COLUMN 82,group sum(p_rec_cur_distterr.mth_net_amt) USING "---,---,--&", 
				COLUMN 94,group sum(p_rec_cur_distterr.mth_cust_num) USING "-----&", 
				COLUMN 105,group sum(p_rec_cy_distterr.mth_sales_qty) USING "-----&", 
				COLUMN 112,group sum(p_rec_cy_distterr.mth_net_amt) USING "---,---,--&", 
				COLUMN 124,group sum(p_rec_cy_distterr.mth_cust_num) USING "-----&"
				 
				PRINT COLUMN 58,(p_rec_statint.year_num-1) USING "####", 
				COLUMN 75,group sum(p_rec_prv_distterr.mth_sales_qty)	USING "-----&", 
				COLUMN 82,group sum(p_rec_prv_distterr.mth_net_amt) USING "----------&", 
				COLUMN 94,group sum(p_rec_prv_distterr.mth_cust_num)	USING "-----&", 
				COLUMN 105,group sum(p_rec_py_distterr.mth_sales_qty) USING "-----&", 
				COLUMN 112,group sum(p_rec_py_distterr.mth_net_amt) USING "----------&", 
				COLUMN 124,group sum(p_rec_py_distterr.mth_cust_num) USING "-----&" 
				SKIP 1 line 
			END IF 
			
		AFTER GROUP OF p_rec_cur_distterr.maingrp_code 
			NEED 4 LINES 
			IF p_rec_criteria.mgrp_ind = "Y" THEN 
				SELECT desc_text INTO l_desc_text FROM maingrp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND maingrp_code = p_rec_cur_distterr.maingrp_code 
				IF l_rec_statterr.poss_cust_num = 0 THEN 
					LET l_poss_cust_per = 0 
				ELSE 
					LET l_poss_cust_per = 100 * 
					(group sum(p_rec_cy_distterr.mth_cust_num)/l_rec_statterr.poss_cust_num) 
				END IF 
				PRINT COLUMN 03,"Main group:", 
				COLUMN 20,p_rec_cur_distterr.maingrp_code, 
				COLUMN 26,l_desc_text, 
				COLUMN 58,p_rec_statint.year_num USING "####", 
				COLUMN 64,l_poss_cust_per USING "---&.&", 
				COLUMN 75,group sum(p_rec_cur_distterr.mth_sales_qty) USING "-----&", 
				COLUMN 82,group sum(p_rec_cur_distterr.mth_net_amt) 	USING "---,---,--&", 
				COLUMN 94,group sum(p_rec_cur_distterr.mth_cust_num) 	USING "-----&", 
				COLUMN 105,group sum(p_rec_cy_distterr.mth_sales_qty) USING "-----&", 
				COLUMN 112,group sum(p_rec_cy_distterr.mth_net_amt) 	USING "---,---,--&", 
				COLUMN 124,group sum(p_rec_cy_distterr.mth_cust_num) 	USING "-----&" 
				
				PRINT COLUMN 58,(p_rec_statint.year_num-1) 				USING "####", 
				COLUMN 75,group sum(p_rec_prv_distterr.mth_sales_qty) USING "-----&", 
				COLUMN 82,group sum(p_rec_prv_distterr.mth_net_amt) 	USING "----------&", 
				COLUMN 94,group sum(p_rec_prv_distterr.mth_cust_num) 	USING "-----&", 
				COLUMN 105,group sum(p_rec_py_distterr.mth_sales_qty) USING "-----&", 
				COLUMN 112,group sum(p_rec_py_distterr.mth_net_amt) 	USING "----------&", 
				COLUMN 124,group sum(p_rec_py_distterr.mth_cust_num) 	USING "-----&" 
				SKIP 1 line 
			END IF 
			
		AFTER GROUP OF p_rec_cur_distterr.area_code 
			NEED 4 LINES 
			IF l_rec_statterr.poss_cust_num = 0 THEN 
				LET l_poss_cust_per = 0 
			ELSE 
				LET l_poss_cust_per = 100 * (group sum(p_rec_cy_distterr.mth_cust_num)/l_rec_statterr.poss_cust_num) 
			END IF 
			PRINT COLUMN 01,"Area summary:", 
			COLUMN 58,p_rec_statint.year_num USING "####", 
			COLUMN 64,l_poss_cust_per USING "---&.&", 
			COLUMN 75,group sum(p_rec_cur_distterr.mth_sales_qty)	USING "-----&", 
			COLUMN 82,group sum(p_rec_cur_distterr.mth_net_amt) USING "---,---,--&", 
			COLUMN 94,group sum(p_rec_cur_distterr.mth_cust_num) USING "-----&", 
			COLUMN 105,group sum(p_rec_cy_distterr.mth_sales_qty) USING "-----&", 
			COLUMN 112,group sum(p_rec_cy_distterr.mth_net_amt) USING "---,---,--&", 
			COLUMN 124,group sum(p_rec_cy_distterr.mth_cust_num) USING "-----&"
			 
			PRINT COLUMN 58,(p_rec_statint.year_num-1) USING "####", 
			COLUMN 75,group sum(p_rec_prv_distterr.mth_sales_qty) USING "-----&", 
			COLUMN 82,group sum(p_rec_prv_distterr.mth_net_amt) USING "----------&", 
			COLUMN 94,group sum(p_rec_prv_distterr.mth_cust_num) USING "-----&", 
			COLUMN 105,group sum(p_rec_py_distterr.mth_sales_qty) USING "-----&", 
			COLUMN 112,group sum(p_rec_py_distterr.mth_net_amt) USING "----------&", 
			COLUMN 124,group sum(p_rec_py_distterr.mth_cust_num) USING "-----&" 
			SKIP 1 line 
			
		ON LAST ROW 
			SKIP 1 LINES 

			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
END REPORT
###########################################################################
# END REPORT EW1_rpt_list(p_rec_cur_distterr,	p_rec_prv_distterr,	p_rec_cy_distterr,	p_rec_py_distterr) 
###########################################################################