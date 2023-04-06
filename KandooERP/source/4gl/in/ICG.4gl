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

#	Source code beautified by beautify.pl on 2020-01-03 09:12:31	$Id: $

#KandooERP runs on Querix Lycia www.querix.com
#Adapted by eric@begooden.it,hoelzl@querix.com,a.bondar@querix.com

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "I_IN_GLOBALS.4gl"
############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_mast_ware_code LIKE inparms.mast_ware_code 

############################################################
# FUNCTION ICG_main()
#
# Purpose - Price Gross Profit List by Group Report
############################################################
FUNCTION ICG_main() 

	CALL setModuleId("ICG") 

	#TODO replace with global_rec_inparms when FUNCTION init_i_in will be finished
	SELECT mast_ware_code INTO modu_mast_ware_code	FROM inparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	AND
			parm_code = "1" 
	IF STATUS = NOTFOUND THEN 
		CALL msgerror("","Inventory Parameters are not set up.\n                 Refer Menu IZP.")
		#LET msgresp = kandoomsg("I",5002,"") 
		#5002 In Parameters NOT SET up - Refer Menu IZP
		EXIT PROGRAM 
	END IF 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode
			OPEN WINDOW I643 WITH FORM "I643" 
			 CALL windecoration_i("I643")
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
			
			MENU "Price Gross Profit" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","ICG","menu-Price_Gross-1") -- albo kd-505
					CALL rpt_rmsreps_reset(NULL)
					CALL ICG_rpt_process(ICG_rpt_query())

				ON ACTION "WEB-HELP" -- albo kd-372 
					CALL onlinehelp(getmoduleid(),NULL) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar()

				ON ACTION "Report" #COMMAND "Run Report" " SELECT Criteria AND Print Report"
					CALL rpt_rmsreps_reset(NULL)
					CALL ICG_rpt_process(ICG_rpt_query())

				ON ACTION "PRINT MANAGER" --COMMAND "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" --COMMAND KEY (interrupt, "E") "Exit" " Exit TO menus" 
					EXIT MENU

			END MENU
			CLOSE WINDOW I643

		WHEN "2" #Background Process with rmsreps.report_code
			CALL ICG_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW I643 with FORM "I643" 
			 CALL windecoration_i("I643") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(ICG_rpt_query()) #save where clause in env 
			CLOSE WINDOW I643 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL ICG_rpt_process(get_url_sel_text())
	END CASE	

END FUNCTION 
############################################################
# END FUNCTION ICG_main()
############################################################

############################################################
# FUNCTION ICG_rpt_query() 
# RETURN r_where_text (Query By Example)
# DataSource for the report driver with CONSTRUCT
############################################################
FUNCTION ICG_rpt_query() 
	DEFINE r_where_text LIKE rmsreps.sel_text

	MESSAGE " Enter criteria FOR selection - ESC TO begin search"

	CONSTRUCT BY NAME r_where_text ON 
	product.part_code, 
	product.desc_text, 
	product.desc2_text, 
	maingrp.dept_code, 
	product.maingrp_code, 
	product.prodgrp_code, 
	product.class_code, 
	product.vend_code, 
	product.cat_code, 
	product.oem_text 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","ICG","construct-product-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN NULL 
	ELSE 
		RETURN r_where_text
	END IF

END FUNCTION 
############################################################
# END FUNCTION ICG_rpt_query() 
############################################################

############################################################
# FUNCTION ICG_rpt_process(p_where_text) 
# 
# The report driver
############################################################
FUNCTION ICG_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.*

	#------------------------------------------------------------
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"ICG_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	

	START REPORT ICG_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	LET l_query_text = 
	"SELECT product.*,prodstatus.* ", 
	"FROM product,prodstatus,maingrp ", 
	"WHERE product.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND prodstatus.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND maingrp.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND product.part_code = prodstatus.part_code ", 
	"AND prodstatus.ware_code = \"",modu_mast_ware_code,"\" ", 
	"AND maingrp.maingrp_code = product.maingrp_code ", 
	"AND ", p_where_text CLIPPED," ",
	"ORDER BY product.part_code" 

	PREPARE s_product FROM l_query_text 
	DECLARE c_product CURSOR FOR s_product 

	FOREACH c_product INTO l_rec_product.*,l_rec_prodstatus.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT ICG_rpt_list(l_rpt_idx,l_rec_product.*,l_rec_prodstatus.*) 
		IF NOT rpt_int_flag_handler2("Product: ",l_rec_prodstatus.part_code,"",l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT ICG_rpt_list
	RETURN rpt_finish("ICG_rpt_list")
	#------------------------------------------------------------

END FUNCTION 
############################################################
# END FUNCTION ICG_rpt_process() 
############################################################

############################################################
# FUNCTION gross_profit_per_ICG(p_price_amt,p_cost_amt)
# 
# Calculate gross profit percent
############################################################
FUNCTION gross_profit_per_ICG(p_price_amt,p_cost_amt) 
	DEFINE p_price_amt LIKE prodstatus.list_amt 
	DEFINE p_cost_amt LIKE prodstatus.est_cost_amt 
	DEFINE l_temp_per FLOAT 
	DEFINE r_gross_profit_per DECIMAL(4,1) 

	IF p_cost_amt IS NULL THEN 
		LET p_cost_amt = 0 
	END IF 
	IF p_price_amt IS NULL THEN 
		LET p_price_amt = 0 
	END IF 
	IF p_price_amt = 0 THEN 
		LET l_temp_per = 0 
	ELSE 
		LET l_temp_per = (p_price_amt - p_cost_amt) / p_price_amt * 100 
	END IF 
	CASE 
		WHEN (l_temp_per > 999.9) 
			LET r_gross_profit_per = 999.9 
		WHEN (l_temp_per < -99.9) 
			LET r_gross_profit_per = -99.9 
		OTHERWISE 
			LET r_gross_profit_per = l_temp_per 
	END CASE 
	RETURN r_gross_profit_per 

END FUNCTION 
############################################################
# END FUNCTION gross_profit_per_ICG 
############################################################

############################################################
# REPORT ICG_rpt_list(p_rpt_idx,p_rec_product,p_rec_prodstatus)
#
# Report Definition/Layout
############################################################
REPORT ICG_rpt_list(p_rpt_idx,p_rec_product,p_rec_prodstatus) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_product RECORD LIKE product.* 
	DEFINE p_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_prodgrp_text LIKE prodgrp.desc_text 
	DEFINE l_prodgrp_cont_text CHAR(40) 
	DEFINE l_list_gp_per DECIMAL(4,1) 
	DEFINE l_price1_gp_per DECIMAL(4,1) 
	DEFINE l_price2_gp_per DECIMAL(4,1) 
	DEFINE l_price3_gp_per DECIMAL(4,1) 
	DEFINE l_price4_gp_per DECIMAL(4,1) 
	DEFINE l_price5_gp_per DECIMAL(4,1) 
	DEFINE l_price6_gp_per DECIMAL(4,1) 
	DEFINE l_price7_gp_per DECIMAL(4,1) 
	DEFINE l_price8_gp_per DECIMAL(4,1) 
	DEFINE l_price9_gp_per DECIMAL(4,1) 
	DEFINE l_temp_text LIKE kandooword.response_text 

	ORDER EXTERNAL BY p_rec_product.prodgrp_code,p_rec_product.desc_text 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 CLIPPED #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 CLIPPED #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]
			IF PAGENO > 1 AND l_prodgrp_cont_text IS NOT NULL THEN 
				PRINT COLUMN 1, "Product Group: ",l_prodgrp_cont_text CLIPPED, 
				COLUMN 88, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line3_text CLIPPED 
			ELSE 
				PRINT COLUMN 88, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line3_text CLIPPED 
			END IF
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]

	BEFORE GROUP OF p_rec_product.prodgrp_code 
		SELECT desc_text INTO l_prodgrp_text FROM prodgrp 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	AND
				prodgrp_code = p_rec_product.prodgrp_code 
		IF STATUS = NOTFOUND THEN 
			LET l_prodgrp_text = "*Unknown*" 
		END IF 

		LET l_prodgrp_cont_text = NULL 
		NEED 4 LINES 
		SKIP 1 LINE 
		PRINT COLUMN 1, "Product Group: ",p_rec_product.prodgrp_code CLIPPED,1 SPACE,l_prodgrp_text CLIPPED 
		SKIP 1 LINE 
		LET l_prodgrp_cont_text = p_rec_product.prodgrp_code, " ",l_prodgrp_text CLIPPED," (cont.)"

	ON EVERY ROW 
		LET l_list_gp_per = gross_profit_per_ICG(p_rec_prodstatus.list_amt,p_rec_prodstatus.est_cost_amt) 
		LET l_price1_gp_per = gross_profit_per_ICG(p_rec_prodstatus.price1_amt,p_rec_prodstatus.est_cost_amt) 
		LET l_price2_gp_per = gross_profit_per_ICG(p_rec_prodstatus.price2_amt,p_rec_prodstatus.est_cost_amt) 
		LET l_price3_gp_per = gross_profit_per_ICG(p_rec_prodstatus.price3_amt,p_rec_prodstatus.est_cost_amt) 
		LET l_price4_gp_per = gross_profit_per_ICG(p_rec_prodstatus.price4_amt,p_rec_prodstatus.est_cost_amt) 
		LET l_price5_gp_per = gross_profit_per_ICG(p_rec_prodstatus.price5_amt,p_rec_prodstatus.est_cost_amt) 
		LET l_price6_gp_per = gross_profit_per_ICG(p_rec_prodstatus.price6_amt,p_rec_prodstatus.est_cost_amt) 
		LET l_price7_gp_per = gross_profit_per_ICG(p_rec_prodstatus.price7_amt,p_rec_prodstatus.est_cost_amt) 
		LET l_price8_gp_per = gross_profit_per_ICG(p_rec_prodstatus.price8_amt,p_rec_prodstatus.est_cost_amt) 
		LET l_price9_gp_per = gross_profit_per_ICG(p_rec_prodstatus.price9_amt,p_rec_prodstatus.est_cost_amt) 

		PRINT COLUMN 1, p_rec_product.part_code CLIPPED, 
		COLUMN 17, p_rec_product.desc_text CLIPPED 
      PRINT	COLUMN 26, p_rec_product.vend_code CLIPPED, 
		COLUMN 35, p_rec_product.price_uom_code CLIPPED, 
		COLUMN 40, p_rec_prodstatus.list_amt      USING "-------&.&&", 
		COLUMN 52, p_rec_prodstatus.est_cost_amt  USING "-------&.&&", 
		COLUMN 64, l_list_gp_per   USING "---&.&", 
		COLUMN 71, l_price1_gp_per USING "---&.&", 
		COLUMN 78, l_price2_gp_per USING "---&.&", 
		COLUMN 85, l_price3_gp_per USING "---&.&", 
		COLUMN 92, l_price4_gp_per USING "---&.&", 
		COLUMN 99, l_price5_gp_per USING "---&.&", 
		COLUMN 106,l_price6_gp_per USING "---&.&", 
		COLUMN 113,l_price7_gp_per USING "---&.&", 
		COLUMN 120,l_price8_gp_per USING "---&.&", 
		COLUMN 127,l_price9_gp_per USING "---&.&" 

	ON LAST ROW 
		SKIP 1 LINE
		#End Of Report
		IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
			PRINT COLUMN 01,"Selection Criteria:" 
			PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text CLIPPED WORDWRAP RIGHT MARGIN 100 
		END IF 
		PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report 			
		LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = PAGENO

END REPORT
