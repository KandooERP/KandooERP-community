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
# MODULE Scope Variables
############################################################
DEFINE modu_group_desc LIKE prodgrp.desc_text 
DEFINE modu_ware_desc_text LIKE warehouse.desc_text 

############################################################
# FUNCTION IAE_main()
# RETURN VOID
#
# Purpose - Product Master List Report
############################################################
FUNCTION IAE_main()

	CALL setModuleId("IAE") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode
			OPEN WINDOW I143 WITH FORM "I143" 
			 CALL windecoration_i("I143")
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title

			MENU "Product Master List" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","IAE","menu-Product_Master-1") -- albo kd-505 
					CALL rpt_rmsreps_reset(NULL)
					CALL IAE_rpt_process(IAE_rpt_query())

				ON ACTION "WEB-HELP" -- albo kd-372 
					CALL onlinehelp(getmoduleid(),NULL) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar()

				ON ACTION "Report" #COMMAND "Run Report" " SELECT Criteria AND Print Report"
					CALL rpt_rmsreps_reset(NULL)
					CALL IAE_rpt_process(IAE_rpt_query())

				ON ACTION "PRINT MANAGER" --COMMAND "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" --COMMAND KEY (interrupt, "E") "Exit" " Exit TO menus" 
					EXIT MENU

			END MENU
			CLOSE WINDOW I143

		WHEN "2" #Background Process with rmsreps.report_code
			CALL IAE_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW I143 with FORM "I143" 
			 CALL windecoration_i("I143") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(IAE_rpt_query()) #save where clause in env 
			CLOSE WINDOW I143 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL IAE_rpt_process(get_url_sel_text())
	END CASE	

END FUNCTION 
############################################################
# END FUNCTION IAE_main() 
############################################################

############################################################
# FUNCTION IAE_rpt_query() 
# RETURN r_where_text (Query By Example)
# DataSource for the report driver with CONSTRUCT
############################################################
FUNCTION IAE_rpt_query() 
	DEFINE r_where_text LIKE rmsreps.sel_text

	MESSAGE " Enter criteria FOR selection - ESC TO begin search"

	CONSTRUCT BY NAME r_where_text ON 
	prodstatus.ware_code, 
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
			CALL publish_toolbar("kandoo","IAE","construct-prodstatus-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),NULL) 

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
# END FUNCTION IAE_rpt_query() 
############################################################ 

############################################################
# FUNCTION IAE_rpt_process(p_where_text) 
# 
# The report driver
############################################################
FUNCTION IAE_rpt_process(p_where_text)
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

	LET l_rpt_idx = rpt_start(getmoduleid(),"IAE_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	

	START REPORT IAE_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	LET l_query_text = 
	"SELECT product.*,prodstatus.* ", 
	"FROM product, prodstatus ", 
	"WHERE product.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND prodstatus.cmpy_code = product.cmpy_code ", 
	"AND prodstatus.part_code = product.part_code ", 
	"AND ",p_where_text CLIPPED," ", 
	"ORDER BY prodstatus.ware_code,product.prodgrp_code,product.part_code" 

	PREPARE p_product FROM l_query_text 
	DECLARE c_product CURSOR FOR p_product 

	FOREACH c_product INTO l_rec_product.*,l_rec_prodstatus.* 
		SELECT warehouse.desc_text INTO modu_ware_desc_text FROM warehouse 
		WHERE warehouse.cmpy_code = glob_rec_kandoouser.cmpy_code	AND 
				warehouse.ware_code = l_rec_prodstatus.ware_code 
		SELECT prodgrp.desc_text INTO modu_group_desc FROM prodgrp 
		WHERE prodgrp.cmpy_code = glob_rec_kandoouser.cmpy_code	AND 
				prodgrp.prodgrp_code = l_rec_product.prodgrp_code 
		#---------------------------------------------------------
		OUTPUT TO REPORT IAE_rpt_list(l_rpt_idx,l_rec_product.*,l_rec_prodstatus.*) 
		IF NOT rpt_int_flag_handler2("Product: ",l_rec_product.part_code,"",l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT IAE_rpt_list
	RETURN rpt_finish("IAE_rpt_list")
	#------------------------------------------------------------

END FUNCTION
############################################################
# END FUNCTION IAE_rpt_process() 
############################################################

############################################################
# REPORT IAE_rpt_list(p_rpt_idx,p_rec_product,p_rec_prodstatus)
#
# Report Definition/Layout
############################################################
REPORT IAE_rpt_list(p_rpt_idx,p_rec_product,p_rec_prodstatus)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_product RECORD LIKE product.* 
	DEFINE p_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_arr_bin ARRAY[3] OF RECORD 
		bin_text CHAR(12) 
	END RECORD 
	DEFINE l_part_supercedes LIKE product.super_part_code 
	DEFINE l_duty_per LIKE tariff.duty_per 
	DEFINE l_bin_count SMALLINT 
	DEFINE l_part_found SMALLINT

	ORDER EXTERNAL BY p_rec_prodstatus.ware_code,p_rec_product.prodgrp_code,p_rec_product.part_code 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 CLIPPED #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 CLIPPED #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]
			PRINT COLUMN 01, p_rec_prodstatus.ware_code,COLUMN 05, modu_ware_desc_text CLIPPED
			PRINT COLUMN 01, p_rec_product.prodgrp_code,COLUMN 05, modu_group_desc CLIPPED
			SKIP 1 LINE 

	BEFORE GROUP OF p_rec_prodstatus.ware_code 
		SKIP TO TOP OF PAGE 

	BEFORE GROUP OF p_rec_product.prodgrp_code 
		SKIP TO TOP OF PAGE 

	ON EVERY ROW 
		LET l_part_found = FALSE 
		DECLARE c1_product CURSOR FOR 
		SELECT product.part_code FROM product 
		WHERE product.cmpy_code = glob_rec_kandoouser.cmpy_code AND 
				product.super_part_code = p_rec_product.part_code 
		OPEN c1_product 
		FETCH c1_product INTO l_part_supercedes 
		IF STATUS = 0 THEN 
			LET l_part_found = TRUE 
		END IF 
		CLOSE c1_product 
		IF NOT l_part_found THEN 
			DECLARE c_ingroup CURSOR FOR 
			SELECT ingroup.ingroup_code FROM ingroup 
			WHERE ingroup.cmpy_code = glob_rec_kandoouser.cmpy_code AND 
					ingroup.ingroup_code = p_rec_product.part_code AND 
					ingroup.type_ind = "S" 
			FOREACH c_ingroup INTO l_part_supercedes 
				LET l_part_found = TRUE 
				EXIT FOREACH 
			END FOREACH 
			IF NOT l_part_found THEN 
				LET l_part_supercedes = "" 
			END IF 
		END IF 
		SELECT tariff.duty_per INTO l_duty_per FROM tariff 
		WHERE tariff.cmpy_code = glob_rec_kandoouser.cmpy_code AND 
				tariff.tariff_code = p_rec_product.tariff_code 
		IF STATUS = NOTFOUND THEN 
			LET l_duty_per = NULL 
		END IF 
		FOR l_bin_count = 1 TO 3 
			LET l_arr_bin[l_bin_count].bin_text = NULL 
		END FOR 
		LET l_bin_count = 0 
		IF p_rec_prodstatus.bin1_text != " " 
		AND p_rec_prodstatus.bin1_text IS NOT NULL THEN 
			LET l_bin_count = l_bin_count + 1 
			LET l_arr_bin[l_bin_count].bin_text = p_rec_prodstatus.bin1_text 
		END IF 
		IF p_rec_prodstatus.bin2_text != " " 
		AND p_rec_prodstatus.bin2_text IS NOT NULL THEN 
			LET l_bin_count = l_bin_count + 1 
			LET l_arr_bin[l_bin_count].bin_text = p_rec_prodstatus.bin2_text 
		END IF 
		IF p_rec_prodstatus.bin3_text != " " 
		AND p_rec_prodstatus.bin3_text IS NOT NULL THEN 
			LET l_bin_count = l_bin_count + 1 
			LET l_arr_bin[l_bin_count].bin_text = p_rec_prodstatus.bin3_text 
		END IF 
		IF l_bin_count = 3 THEN 
			NEED 3 LINES 
		ELSE 
			IF l_bin_count = 2 OR (p_rec_product.desc2_text != " " AND p_rec_product.desc2_text IS NOT NULL) THEN 
				NEED 2 LINES 
			END IF 
		END IF 
		PRINT COLUMN 001, p_rec_product.part_code CLIPPED, 
		COLUMN 017, p_rec_product.desc_text CLIPPED, 
		COLUMN 056, p_rec_prodstatus.list_amt USING "-------&.&&", 
		COLUMN 068, p_rec_product.super_part_code CLIPPED, 
		COLUMN 084, l_part_supercedes CLIPPED, 
		COLUMN 100, p_rec_product.tariff_code CLIPPED, 
		COLUMN 113, l_duty_per USING "---&.&&", -- USING "#&.&&",  
		COLUMN 121, l_arr_bin[1].bin_text CLIPPED 
		IF l_bin_count = 2 OR (p_rec_product.desc2_text != " " AND p_rec_product.desc2_text IS NOT NULL) THEN 
			PRINT COLUMN 017, p_rec_product.desc2_text CLIPPED, 
			COLUMN 121, l_arr_bin[2].bin_text CLIPPED 
		END IF 
		IF l_bin_count = 3 THEN 
			PRINT COLUMN 121, l_arr_bin[3].bin_text CLIPPED
		END IF 
		SKIP 1 LINE 
			
	ON LAST ROW 
		#End Of Report
		IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
			PRINT COLUMN 01,"Selection Criteria:" 
			PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text CLIPPED WORDWRAP RIGHT MARGIN 100 
		END IF 
		PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report 			
		LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = PAGENO

END REPORT 