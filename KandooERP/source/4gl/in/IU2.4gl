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

	Source code beautified by beautify.pl on 2020-01-03 09:12:31	$Id: $
}
{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com,a.bondar@querix.com
}

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "I_IN_GLOBALS.4gl" 

############################################################
# FUNCTION IU2_main()
#
# Purpose - Product Status Report by product
############################################################
FUNCTION IU2_main()

	CALL setModuleId("IU2") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode
			OPEN WINDOW I254 WITH FORM "I254" 
			 CALL windecoration_i("I254")
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
			
			MENU "Price Amendment" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","IU2","menu-Product_Status-1") -- albo kd-505 

				ON ACTION "WEB-HELP" -- albo kd-372 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar()

				ON ACTION "Report" #COMMAND "Run Report" " SELECT Criteria AND Print Report"
					CALL IU2_rpt_process(IU2_rpt_query())
					CALL rpt_rmsreps_reset(NULL)

				ON ACTION "PRINT MANAGER" --COMMAND "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" --COMMAND KEY (interrupt, "E") "Exit" " Exit TO menus" 
					EXIT MENU

			END MENU
			CLOSE WINDOW I254

		WHEN "2" #Background Process with rmsreps.report_code
			CALL IU2_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW I254 with FORM "I254" 
			 CALL windecoration_i("I254") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(IU2_rpt_query()) #save where clause in env 
			CLOSE WINDOW I254 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL IU2_rpt_process(get_url_sel_text())
	END CASE	

END FUNCTION 

############################################################
# FUNCTION IU2_rpt_query() 
#
#
############################################################
FUNCTION IU2_rpt_query() 
	DEFINE l_where_text STRING

	MESSAGE " Enter criteria FOR selection - ESC TO begin search"

	CONSTRUCT BY NAME l_where_text ON 
	prodstatlog.ware_code, 
	product.part_code, 
	product.desc_text, 
	product.desc2_text, 
	product.maingrp_code, 
	product.prodgrp_code, 
	product.cat_code, 
	product.class_code, 
	prodstatlog.change_date, 
	prodstatlog.user_code 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","IU2","construct-prodstatlog-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
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

############################################################
# FUNCTION IU2_rpt_process() 
#
#
############################################################
FUNCTION IU2_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_prodstatlog RECORD LIKE prodstatlog.* 
	DEFINE l_rec_s_prodstatlog RECORD LIKE prodstatlog.* 

	#------------------------------------------------------------
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"IU2_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	

	START REPORT IU2_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	LET l_query_text = 
	"SELECT prodstatlog.*,product.* ", 
	"FROM prodstatlog,product ", 
	"WHERE prodstatlog.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	"AND product.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	"AND prodstatlog.part_code = product.part_code ", 
	"AND ", p_where_text CLIPPED," ",
	"ORDER BY prodstatlog.ware_code,prodstatlog.part_code,prodstatlog.audit_date" 

	PREPARE s_prodstatlog FROM l_query_text 
	DECLARE c_prodstatlog CURSOR FOR s_prodstatlog

	FOREACH c_prodstatlog INTO l_rec_prodstatlog.*,l_rec_product.* 
		IF l_rec_s_prodstatlog.part_code IS NULL 
		OR l_rec_s_prodstatlog.ware_code IS NULL 
		OR l_rec_s_prodstatlog.part_code != l_rec_prodstatlog.part_code 
		OR l_rec_s_prodstatlog.ware_code != l_rec_prodstatlog.ware_code 
		OR l_rec_s_prodstatlog.list_price_amt != l_rec_prodstatlog.list_price_amt 
		OR l_rec_s_prodstatlog.price_1_amt != l_rec_prodstatlog.price_1_amt 
		OR l_rec_s_prodstatlog.price_2_amt != l_rec_prodstatlog.price_2_amt 
		OR l_rec_s_prodstatlog.price_3_amt != l_rec_prodstatlog.price_3_amt 
		OR l_rec_s_prodstatlog.price_4_amt != l_rec_prodstatlog.price_4_amt 
		OR l_rec_s_prodstatlog.price_5_amt != l_rec_prodstatlog.price_5_amt 
		OR l_rec_s_prodstatlog.price_6_amt != l_rec_prodstatlog.price_6_amt 
		OR l_rec_s_prodstatlog.price_7_amt != l_rec_prodstatlog.price_7_amt 
		OR l_rec_s_prodstatlog.price_8_amt != l_rec_prodstatlog.price_8_amt 
		OR l_rec_s_prodstatlog.price_9_amt != l_rec_prodstatlog.price_9_amt THEN
			#---------------------------------------------------------
			OUTPUT TO REPORT IU2_rpt_list (l_rpt_idx,l_rec_prodstatlog.*,l_rec_product.*) 
			IF NOT rpt_int_flag_handler2("Product: ",l_rec_prodstatlog.part_code,"",l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------
			LET l_rec_s_prodstatlog.* = l_rec_prodstatlog.* 
		END IF 
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT IU2_rpt_list
	CALL rpt_finish("IU2_rpt_list")
	#------------------------------------------------------------

	IF int_flag THEN 
		LET int_flag = FALSE 
		ERROR " Printing was aborted" 
		RETURN FALSE 
	ELSE 
		RETURN TRUE 
	END IF

END FUNCTION 

############################################################
# REPORT IU2_rpt_list(p_rpt_idx,p_rec_prodstatlog,p_rec_product)
#
#
############################################################
REPORT IU2_rpt_list(p_rpt_idx,p_rec_prodstatlog,p_rec_product)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_prodstatlog RECORD LIKE prodstatlog.* 
	DEFINE p_rec_product RECORD LIKE product.* 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_name_text CHAR(30) 
	DEFINE l_time_text CHAR(30) 

	ORDER EXTERNAL BY p_rec_prodstatlog.ware_code,p_rec_prodstatlog.part_code,p_rec_prodstatlog.audit_date 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

	BEFORE GROUP OF p_rec_prodstatlog.ware_code 
		SELECT * INTO l_rec_warehouse.* 
		FROM warehouse 
		WHERE ware_code = p_rec_prodstatlog.ware_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		PRINT COLUMN 01, "Warehouse:", 
		COLUMN 12,l_rec_warehouse.ware_code CLIPPED, 
		COLUMN 17,l_rec_warehouse.desc_text CLIPPED
		SKIP 1 LINE 

	ON EVERY ROW 
		NEED 2 LINES 
		SELECT name_text INTO l_name_text 
		FROM kandoouser 
		WHERE sign_on_code = p_rec_prodstatlog.user_code 
		IF STATUS = NOTFOUND THEN 
			LET l_name_text = p_rec_prodstatlog.user_code 
		END IF 
		LET l_time_text = p_rec_prodstatlog.audit_date 
		PRINT COLUMN 01, p_rec_prodstatlog.part_code, 
		COLUMN 17, p_rec_product.desc_text[1,30], 
		COLUMN 48, p_rec_prodstatlog.change_date USING "dd/mm/yy", 
		COLUMN 57, l_time_text[12,16], 
		COLUMN 63, p_rec_product.sell_uom_code, 
		COLUMN 68, p_rec_prodstatlog.list_price_amt USING "-------&.&&&&", 
		COLUMN 81, p_rec_prodstatlog.price_1_amt USING "-------&.&&&&", 
		COLUMN 94, p_rec_prodstatlog.price_2_amt USING "-------&.&&&&", 
		COLUMN 107, p_rec_prodstatlog.price_3_amt USING "-------&.&&&&", 
		COLUMN 120, p_rec_prodstatlog.price_4_amt USING "-------&.&&&&" 
		PRINT COLUMN 17, p_rec_product.desc2_text, 
		COLUMN 48, l_name_text[1,20], 
		COLUMN 68, p_rec_prodstatlog.price_5_amt USING "-------&.&&&&", 
		COLUMN 81, p_rec_prodstatlog.price_6_amt USING "-------&.&&&&", 
		COLUMN 94, p_rec_prodstatlog.price_7_amt USING "-------&.&&&&", 
		COLUMN 107, p_rec_prodstatlog.price_8_amt USING "-------&.&&&&", 
		COLUMN 120, p_rec_prodstatlog.price_9_amt USING "-------&.&&&&" 

	AFTER GROUP OF p_rec_prodstatlog.ware_code 
		SKIP 3 LINES 

	ON LAST ROW 
		#End Of Report
		IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
			PRINT COLUMN 01,"Selection Criteria:" 
			PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text CLIPPED WORDWRAP RIGHT MARGIN 100 
		END IF 
		PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report 			
		LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = PAGENO

END REPORT 
