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
# FUNCTION IR3_main()
#
# Purpose - Serialized Products Report
############################################################
FUNCTION IR3_main()

	CALL setModuleId("IR3") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode
			OPEN WINDOW I127 WITH FORM "I127" 
			 CALL windecoration_i("I127")
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
			
			MENU "Serialized Products" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","IR3","menu-Serial Stock-1") -- albo kd-505
					CALL rpt_rmsreps_reset(NULL)
					CALL IR3_rpt_process(IR3_rpt_query())

				ON ACTION "WEB-HELP" -- albo kd-372 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar()

				ON ACTION "Report" #COMMAND "Run Report" " SELECT Criteria AND Print Report"
					CALL rpt_rmsreps_reset(NULL)
					CALL IR3_rpt_process(IR3_rpt_query())

				ON ACTION "PRINT MANAGER" --COMMAND "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" --COMMAND KEY (interrupt, "E") "Exit" " Exit TO menus" 
					EXIT MENU

			END MENU
			CLOSE WINDOW I127

		WHEN "2" #Background Process with rmsreps.report_code
			CALL IR3_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW I127 with FORM "I127" 
			 CALL windecoration_i("I127") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(IR3_rpt_query()) #save where clause in env 
			CLOSE WINDOW I127 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL IR3_rpt_process(get_url_sel_text())
	END CASE	

END FUNCTION 
############################################################
# END FUNCTION IR3_main()
############################################################ 

############################################################
# FUNCTION IR3_rpt_query() 
# RETURN r_where_text (Query By Example)
# DataSource for the report driver with CONSTRUCT
############################################################
FUNCTION IR3_rpt_query() 
	DEFINE r_where_text LIKE rmsreps.sel_text

	MESSAGE " Enter criteria FOR selection - ESC TO begin search"

	CONSTRUCT BY NAME r_where_text ON 
	serialinfo.part_code, 
	product.desc_text, 
	product.desc2_text, 
	serialinfo.ware_code, 
	serialinfo.serial_code, 
	serialinfo.asset_num, 
	serialinfo.vend_code, 
	serialinfo.po_num,
	serialinfo.receipt_date, 
	serialinfo.receipt_num, 
	serialinfo.cust_code, 
	serialinfo.trans_num, 
	serialinfo.ship_date,
	serialinfo.credit_num, 
	serialinfo.trantype_ind,
	serialinfo.ref_num 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","IR3","construct-serialinfo-1") -- albo kd-505 

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
# END FUNCTION IR3_rpt_query() 
############################################################	 

############################################################
# FUNCTION IR3_rpt_process(p_where_text) 
# 
# The report driver
############################################################
FUNCTION IR3_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT
	DEFINE l_rec_serialinfo RECORD LIKE serialinfo.* 
	DEFINE l_product_desc LIKE product.desc_text 

	#------------------------------------------------------------
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE
		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"IR3_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	

	START REPORT IR3_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	LET l_query_text = 
	"SELECT serialinfo.*,product.desc_text ", 
	"FROM serialinfo,product ", 
	"WHERE serialinfo.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND product.cmpy_code = serialinfo.cmpy_code ", 
	"AND product.part_code = serialinfo.part_code ", 
	"AND ", p_where_text CLIPPED," ", 
	"ORDER BY serialinfo.part_code,serialinfo.serial_code" 

	PREPARE choice FROM l_query_text 
	DECLARE selcurs CURSOR FOR choice 

	FOREACH selcurs INTO l_rec_serialinfo.*, l_product_desc 
		#---------------------------------------------------------
		OUTPUT TO REPORT IR3_rpt_list(l_rpt_idx,l_rec_serialinfo.*, l_product_desc) 
		IF NOT rpt_int_flag_handler2("Product: ",l_rec_serialinfo.part_code,"",l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT IR3_rpt_list
	RETURN rpt_finish("IR3_rpt_list")
	#------------------------------------------------------------

END FUNCTION 
############################################################
# END FUNCTION IR3_rpt_process() 
############################################################

############################################################
# REPORT IR3_rpt_list(p_rpt_idx,p_rec_serialinfo,p_product_desc)
#
# Report Definition/Layout
############################################################
REPORT IR3_rpt_list(p_rpt_idx,p_rec_serialinfo,p_product_desc) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_serialinfo RECORD LIKE serialinfo.* 
	DEFINE p_product_desc LIKE product.desc_text
	DEFINE l_r_cnt INTEGER 
	DEFINE l_r_cnt_tot INTEGER

	ORDER EXTERNAL BY p_rec_serialinfo.part_code,p_rec_serialinfo.serial_code 

	FORMAT 
		FIRST PAGE HEADER 
			LET l_r_cnt = 0 
			LET l_r_cnt_tot = 0 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 CLIPPED #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 CLIPPED #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 CLIPPED #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 CLIPPED #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]

	BEFORE GROUP OF p_rec_serialinfo.part_code 
		SKIP 1 LINE 
		PRINT COLUMN 1, "Item: ", p_rec_serialinfo.part_code CLIPPED,"  ",p_product_desc CLIPPED

	ON EVERY ROW 
		LET l_r_cnt = l_r_cnt + 1 
		LET l_r_cnt_tot = l_r_cnt_tot + 1 
		PRINT COLUMN 4, p_rec_serialinfo.serial_code CLIPPED, 
		COLUMN 26, p_rec_serialinfo.vend_code CLIPPED, 
		COLUMN 36, p_rec_serialinfo.po_num       USING "#######&", 
		COLUMN 46, p_rec_serialinfo.receipt_date USING "dd/mm/yy", 
		COLUMN 56, p_rec_serialinfo.receipt_num  USING "#######&", 
		COLUMN 66, p_rec_serialinfo.cust_code CLIPPED, 
		COLUMN 76, p_rec_serialinfo.trans_num    USING "#######&", 
		COLUMN 86, p_rec_serialinfo.ship_date    USING "dd/mm/yy", 
		COLUMN 96, p_rec_serialinfo.credit_num   USING "#######&", 
		COLUMN 106,p_rec_serialinfo.ref_num      USING "#######&", 
		COLUMN 117,p_rec_serialinfo.ware_code CLIPPED, 
		COLUMN 126,p_rec_serialinfo.trantype_ind CLIPPED 

	AFTER GROUP OF p_rec_serialinfo.part_code 
		PRINT COLUMN 122,"----------" 
		PRINT COLUMN 115,"Count: ",l_r_cnt            USING "#########&" 
		LET l_r_cnt = 0 

	ON LAST ROW 
		NEED 4 LINES 
		SKIP 1 LINE 
		PRINT COLUMN 122,"==========" 
		PRINT COLUMN 108,"Report Count: ",l_r_cnt_tot USING "#########&" 
		PRINT COLUMN 122,"----------" 
		SKIP 1 LINE 
		#End Of Report
		SKIP 1 LINE
		IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
			PRINT COLUMN 01,"Selection Criteria:" 
			PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text CLIPPED WORDWRAP RIGHT MARGIN 100 
		END IF 
		PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report 			
		LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = PAGENO

END REPORT 
