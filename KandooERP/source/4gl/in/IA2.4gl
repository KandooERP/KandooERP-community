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

#KandooERP runs on Querix Lycia www.querix.com
#Adapted by eric@begooden.it,hoelzl@querix.com,a.bondar@querix.com

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 

############################################################
# FUNCTION IA2_main()
# RETURN VOID
#
# Purpose - Product List by Inventory Category Report
############################################################
FUNCTION IA2_main()

	CALL setModuleId("IA2") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode
			OPEN WINDOW I160 WITH FORM "I160" 
			 CALL windecoration_i("I160")
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
			
			MENU "Product List by Inventory Category" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","IA2","menu-Product_Report-1") -- albo kd-505
					CALL rpt_rmsreps_reset(NULL)
					CALL IA2_rpt_process(IA2_rpt_query())

				ON ACTION "WEB-HELP" -- albo kd-372 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar()

				ON ACTION "Report" #COMMAND "Run Report" " SELECT Criteria AND Print Report"
					CALL rpt_rmsreps_reset(NULL)
					CALL IA2_rpt_process(IA2_rpt_query())

				ON ACTION "PRINT MANAGER" --COMMAND "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" --COMMAND KEY (interrupt, "E") "Exit" " Exit TO menus" 
					EXIT MENU

			END MENU
			CLOSE WINDOW I160

		WHEN "2" #Background Process with rmsreps.report_code
			CALL IA2_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW I160 with FORM "I160" 
			 CALL windecoration_i("I160") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(IA2_rpt_query()) #save where clause in env 
			CLOSE WINDOW I160 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL IA2_rpt_process(get_url_sel_text())
	END CASE

END FUNCTION 
############################################################
# END FUNCTION IA2_main() 
############################################################

############################################################
# FUNCTION IA2_rpt_query() 
# RETURN r_where_text (Query By Example)
# DataSource for the report driver with CONSTRUCT
############################################################
FUNCTION IA2_rpt_query() 
	DEFINE r_where_text LIKE rmsreps.sel_text

	MESSAGE " Enter criteria FOR selection - ESC TO begin search"

	CONSTRUCT BY NAME r_where_text ON 
	product.part_code, 
	product.desc_text, 
	product.desc2_text, 
	product.maingrp_code, 
	product.prodgrp_code, 
	product.cat_code, 
	product.class_code, 
	product.alter_part_code, 
	product.super_part_code, 
	product.compn_part_code, 
	product.pur_uom_code, 
	product.pur_stk_con_qty, 
	product.stock_uom_code, 
	product.stk_sel_con_qty, 
	product.sell_uom_code 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","IA2","construct-product-1") -- albo kd-505 

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
# END FUNCTION IA2_rpt_query() 
############################################################

############################################################
# FUNCTION IA2_rpt_process(p_where_text) 
# 
# The report driver
############################################################
FUNCTION IA2_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT
	DEFINE l_rec_product RECORD LIKE product.* 

	#------------------------------------------------------------
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE
		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"IA2_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	

	START REPORT IA2_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	LET l_query_text = 
	"SELECT * ", 
	"FROM product ", 
	"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND ", p_where_text CLIPPED," ", 
	"ORDER BY cat_code,part_code"

	PREPARE choice FROM l_query_text 
	DECLARE selcurs CURSOR FOR choice 

	FOREACH selcurs INTO l_rec_product.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT IA2_rpt_list(l_rpt_idx,l_rec_product.*) 
		IF NOT rpt_int_flag_handler2("Product: ",l_rec_product.part_code,"",l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT IA2_rpt_list
	RETURN rpt_finish("IA2_rpt_list")
	#------------------------------------------------------------

END FUNCTION 
############################################################
# END FUNCTION IA2_rpt_process() 
############################################################

############################################################
# REPORT IA2_rpt_list(p_rpt_idx,p_rec_product)
#
# Report Definition/Layout
############################################################
REPORT IA2_rpt_list(p_rpt_idx,p_rec_product)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_product RECORD LIKE product.* 
	DEFINE l_class_text LIKE class.desc_text 
	DEFINE l_category_text LIKE category.desc_text 

	ORDER EXTERNAL BY p_rec_product.cat_code,p_rec_product.part_code 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 CLIPPED #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 CLIPPED #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]

	BEFORE GROUP OF p_rec_product.cat_code 
		SELECT category.desc_text INTO l_category_text	FROM category 
		WHERE category.cmpy_code = glob_rec_kandoouser.cmpy_code	AND 
				category.cat_code = p_rec_product.cat_code 

		NEED 4 LINES 
		SKIP 1 LINE 
		PRINT COLUMN 1, "Category: ", 
		COLUMN 11, p_rec_product.cat_code CLIPPED, 
		COLUMN 15, l_category_text  CLIPPED
		SKIP 1 LINE

	ON EVERY ROW 
		SELECT class.desc_text INTO l_class_text	FROM class 
		WHERE class.cmpy_code = glob_rec_kandoouser.cmpy_code	AND 
				class.class_code = p_rec_product.class_code 

		PRINT COLUMN 1, p_rec_product.part_code CLIPPED, 
		COLUMN 17, p_rec_product.desc_text CLIPPED, 
		COLUMN 56, p_rec_product.class_code CLIPPED, 
		COLUMN 65, l_class_text CLIPPED, 
		COLUMN 96, p_rec_product.pur_uom_code CLIPPED, 
		COLUMN 103,p_rec_product.pur_stk_con_qty USING "####&.&&", 
		COLUMN 112,p_rec_product.stock_uom_code CLIPPED, 
		COLUMN 119,p_rec_product.stk_sel_con_qty USING "####&.&&", 
		COLUMN 128,p_rec_product.sell_uom_code  CLIPPED

	ON LAST ROW 
		NEED 4 LINES 
		SKIP 1 LINES 
		#End Of Report
		IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
			PRINT COLUMN 01,"Selection Criteria:" 
			PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text CLIPPED WORDWRAP RIGHT MARGIN 100 
		END IF 
		PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report 			
		LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = PAGENO

END REPORT 
