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
# FUNCTION IR4_main()
#
# Purpose - Serialised Products by Serial Number Report
############################################################
FUNCTION IR4_main()

	CALL setModuleId("IR4") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode
			OPEN WINDOW I126 WITH FORM "I126" 
			 CALL windecoration_i("I126")
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
			
			MENU "Serialized Products" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","IR4","menu-Serial_Stock-1") -- albo kd-505
					CALL rpt_rmsreps_reset(NULL)
					CALL IR4_rpt_process(IR4_rpt_query())

				ON ACTION "WEB-HELP" -- albo kd-372 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar()

				ON ACTION "Report" #COMMAND "Run Report" " SELECT Criteria AND Print Report"
					CALL rpt_rmsreps_reset(NULL)
					CALL IR4_rpt_process(IR4_rpt_query())

				ON ACTION "PRINT MANAGER" --COMMAND "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" --COMMAND KEY (interrupt, "E") "Exit" " Exit TO menus" 
					EXIT MENU

			END MENU
			CLOSE WINDOW I126

		WHEN "2" #Background Process with rmsreps.report_code
			CALL IR4_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW I126 with FORM "I126" 
			 CALL windecoration_i("I126") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(IR4_rpt_query()) #save where clause in env 
			CLOSE WINDOW I126 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL IR4_rpt_process(get_url_sel_text())
	END CASE	

END FUNCTION 
############################################################
# END FUNCTION IR4_main()
############################################################ 

############################################################
# FUNCTION IR4_rpt_query() 
# RETURN r_where_text (Query By Example)
# DataSource for the report driver with CONSTRUCT
############################################################
FUNCTION IR4_rpt_query() 
	DEFINE r_where_text LIKE rmsreps.sel_text

	MESSAGE " Enter criteria FOR selection - ESC TO begin search"

	CONSTRUCT BY NAME r_where_text ON 
	serialinfo.part_code, 
	product.desc_text, 
	product.desc2_text, 
	serialinfo.serial_code, 
	serialinfo.receipt_date, 
	serialinfo.vend_code, 
	serialinfo.ware_code,
	serialinfo.po_num, 
	serialinfo.cust_code, 
	serialinfo.trans_num, 
	serialinfo.trantype_ind 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","IR4","construct-serialinfo-1") -- albo kd-505 

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
# END FUNCTION IR4_rpt_query() 
############################################################	 

############################################################
# FUNCTION IR4_rpt_process(p_where_text) 
# 
# The report driver
############################################################
FUNCTION IR4_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT
	DEFINE l_rec_serial_flagitem RECORD 
		part_code LIKE serialinfo.part_code, 
		desc_text LIKE product.desc_text, 
		serial_code LIKE serialinfo.serial_code, 
		vend_code LIKE serialinfo.vend_code, 
		po_num LIKE serialinfo.po_num, 
		receipt_date LIKE serialinfo.receipt_date, 
		cust_code LIKE serialinfo.cust_code, 
		trans_num LIKE serialinfo.trans_num, 
		ship_date LIKE serialinfo.ship_date, 
		trantype_ind LIKE serialinfo.trantype_ind 
	END RECORD 

	#------------------------------------------------------------
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE
		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"IR4_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	

	START REPORT IR4_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	LET l_query_text = 
	"SELECT serialinfo.part_code,", 
	"product.desc_text,", 
	"serialinfo.serial_code,", 
	"serialinfo.vend_code,", 
	"serialinfo.po_num,", 
	"serialinfo.receipt_date,", 
	"serialinfo.cust_code,", 
	"serialinfo.trans_num,", 
	"serialinfo.ship_date,", 
	"serialinfo.trantype_ind ", 
	"FROM serialinfo,product ", 
	"WHERE serialinfo.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND product.cmpy_code = serialinfo.cmpy_code ", 
	"AND product.part_code = serialinfo.part_code ", 
	"AND ", p_where_text CLIPPED," ", 
	"ORDER BY serialinfo.serial_code" 

	PREPARE choice FROM l_query_text 
	DECLARE selcurs CURSOR FOR choice 

	FOREACH selcurs INTO l_rec_serial_flagitem.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT IR4_rpt_list(l_rpt_idx,l_rec_serial_flagitem.*) 
		IF NOT rpt_int_flag_handler2("Product: ",l_rec_serial_flagitem.part_code,"",l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT IR4_rpt_list
	RETURN rpt_finish("IR4_rpt_list")
	#------------------------------------------------------------

END FUNCTION 
############################################################
# END FUNCTION IR4_rpt_process() 
############################################################

############################################################
# REPORT IR4_rpt_list(p_rpt_idx,p_rec_serial_flagitem)
#
# Report Definition/Layout
############################################################
REPORT IR4_rpt_list(p_rpt_idx,p_rec_serial_flagitem) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_serial_flagitem RECORD 
		part_code LIKE serialinfo.part_code, 
		desc_text LIKE product.desc_text, 
		serial_code LIKE serialinfo.serial_code, 
		vend_code LIKE serialinfo.vend_code, 
		po_num LIKE serialinfo.po_num, 
		receipt_date LIKE serialinfo.receipt_date, 
		cust_code LIKE serialinfo.cust_code, 
		trans_num LIKE serialinfo.trans_num, 
		ship_date LIKE serialinfo.ship_date, 
		trantype_ind LIKE serialinfo.trantype_ind 
	END RECORD 

	ORDER EXTERNAL BY p_rec_serial_flagitem.serial_code 

	FORMAT 
		FIRST PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 CLIPPED #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 CLIPPED #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			SKIP 1 LINE
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 CLIPPED #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 CLIPPED #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]

	ON EVERY ROW 
		PRINT COLUMN 1, p_rec_serial_flagitem.serial_code CLIPPED, 
		COLUMN 22, p_rec_serial_flagitem.part_code CLIPPED, 
		COLUMN 38, p_rec_serial_flagitem.desc_text CLIPPED, 
		COLUMN 75, p_rec_serial_flagitem.vend_code CLIPPED, 
		COLUMN 84, p_rec_serial_flagitem.po_num       USING "########", 
		COLUMN 93, p_rec_serial_flagitem.receipt_date USING "dd/mm/yy", 
		COLUMN 102,p_rec_serial_flagitem.cust_code CLIPPED, 
		COLUMN 111,p_rec_serial_flagitem.trans_num    USING "########", 
		COLUMN 120,p_rec_serial_flagitem.ship_date    USING "dd/mm/yy", 
		COLUMN 130,p_rec_serial_flagitem.trantype_ind CLIPPED 

	ON LAST ROW 
		NEED 4 LINES 
		SKIP 2 LINES 
		#End Of Report
		IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
			PRINT COLUMN 01,"Selection Criteria:" 
			PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text CLIPPED WORDWRAP RIGHT MARGIN 100 
		END IF 
		PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report 			
		LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = PAGENO

END REPORT
