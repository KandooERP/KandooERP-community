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
DEFINE modu_frm_label CHAR(9) 

############################################################
# FUNCTION I5A_main()
# RETURN VOID
#
# Purpose - Stock Transfer Report
############################################################
FUNCTION I5A_main() 

	CALL setModuleId("I5A") 

	LET modu_frm_label = "Report"
	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode
			OPEN WINDOW I663 WITH FORM "I663" 
			 CALL windecoration_i("I663")
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
			DISPLAY modu_frm_label TO frm_label			

			MENU "Stock Transfer" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","I5A","menu-Stock_Transfer") -- albo kd-505 
					CALL rpt_rmsreps_reset(NULL)
					CALL I5A_rpt_process(I5A_rpt_query())

				ON ACTION "WEB-HELP" -- albo kd-372 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar()

				ON ACTION "Report" #COMMAND "Run Report" " SELECT Criteria AND Print Report"
					CALL rpt_rmsreps_reset(NULL)
					CALL I5A_rpt_process(I5A_rpt_query())

				ON ACTION "PRINT MANAGER" --COMMAND "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" --COMMAND KEY (interrupt, "E") "Exit" " Exit TO menus" 
					EXIT MENU

			END MENU
			CLOSE WINDOW I663

		WHEN "2" #Background Process with rmsreps.report_code
			CALL I5A_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW I663 with FORM "I663" 
			 CALL windecoration_i("I663") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			DISPLAY modu_frm_label TO frm_label
			CALL set_url_sel_text(I5A_rpt_query()) #save where clause in env 
			CLOSE WINDOW I663 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL I5A_rpt_process(get_url_sel_text())
	END CASE	

END FUNCTION 
############################################################
# END FUNCTION I5A_main() 
############################################################

############################################################
# FUNCTION I5A_rpt_query() 
# RETURN r_where_text (Query By Example)
# DataSource for the report driver with CONSTRUCT
############################################################
FUNCTION I5A_rpt_query() 
	DEFINE r_where_text LIKE rmsreps.sel_text

	MESSAGE " Enter criteria FOR selection - ESC TO begin search"
 
	CONSTRUCT BY NAME r_where_text ON 
	ibthead.trans_num, 
	ibthead.desc_text, 
	ibthead.from_ware_code, 
	ibthead.to_ware_code, 
	ibthead.trans_date, 
	ibthead.year_num, 
	ibthead.period_num, 
	ibthead.sched_ind, 
	ibthead.status_ind, 
	ibtdetl.line_num, 
	ibtdetl.part_code, 
	ibtdetl.trf_qty, 
	ibtdetl.sched_qty, 
	ibtdetl.picked_qty, 
	ibtdetl.conf_qty, 
	ibtdetl.rec_qty, 
	ibtdetl.back_qty 

		BEFORE CONSTRUCT 
			DISPLAY modu_frm_label TO frm_label
			CALL publish_toolbar("kandoo","I5A","construct-stocktransfer") -- albo kd-505

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
# END FUNCTION I5A_rpt_query() 
############################################################

############################################################
# FUNCTION I5A_rpt_process(p_where_text) 
# 
# The report driver
############################################################
FUNCTION I5A_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT
	DEFINE l_rec_ibthead RECORD LIKE ibthead.* 
	DEFINE l_rec_ibtdetl RECORD LIKE ibtdetl.*
	DEFINE l_sell_uom_code LIKE product.sell_uom_code 

	#------------------------------------------------------------
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"I5A_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	

	START REPORT I5A_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	LET l_query_text = 
	"SELECT ibthead.*,ibtdetl.*,product.sell_uom_code ", 
	"FROM ibthead,ibtdetl,product ", 
	"WHERE ibtdetl.trans_num = ibthead.trans_num ", 
	"AND ibtdetl.part_code = product.part_code ",
	"AND ibtdetl.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND ibthead.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND product.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND ", p_where_text CLIPPED," ",
	"ORDER BY ibthead.trans_num,product.sell_uom_code,ibtdetl.line_num" 

	PREPARE s_transfer FROM l_query_text 
	DECLARE c_transfer CURSOR FOR s_transfer 

	FOREACH c_transfer INTO l_rec_ibthead.*, l_rec_ibtdetl.*, l_sell_uom_code
		#---------------------------------------------------------
		OUTPUT TO REPORT I5A_rpt_list(l_rpt_idx,l_rec_ibthead.*,l_rec_ibtdetl.*,l_sell_uom_code) 
		IF NOT rpt_int_flag_handler2("Transfer: ",l_rec_ibthead.trans_num,l_rec_ibtdetl.part_code,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#--------------------------------------------------------- 
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT I5A_rpt_list
	RETURN rpt_finish("I5A_rpt_list")
	#------------------------------------------------------------

END FUNCTION 
############################################################
# END FUNCTION I5A_rpt_process() 
############################################################

############################################################
# REPORT I5A_rpt_list(p_rpt_idx,p_rec_ibthead,p_rec_ibtdetl,p_sell_uom_code)
#
# Report Definition/Layout
############################################################
REPORT I5A_rpt_list(p_rpt_idx,p_rec_ibthead,p_rec_ibtdetl,p_sell_uom_code) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_ibthead RECORD LIKE ibthead.*
	DEFINE p_rec_ibtdetl RECORD LIKE ibtdetl.* 
 	DEFINE p_sell_uom_code LIKE product.sell_uom_code
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_source_text LIKE warehouse.desc_text 
	DEFINE l_dest_text   LIKE warehouse.desc_text

	ORDER EXTERNAL BY p_rec_ibthead.trans_num,p_sell_uom_code,p_rec_ibtdetl.line_num 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 CLIPPED #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 CLIPPED #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]

	BEFORE GROUP OF p_rec_ibthead.trans_num 
		NEED 8 LINES 
		SELECT desc_text INTO l_source_text FROM warehouse 
		WHERE ware_code = p_rec_ibthead.from_ware_code AND 
				cmpy_code = glob_rec_kandoouser.cmpy_code 
		SELECT desc_text INTO l_dest_text FROM warehouse 
		WHERE ware_code = p_rec_ibthead.to_ware_code	AND 
				cmpy_code = glob_rec_kandoouser.cmpy_code 
		PRINT COLUMN 01,"Source...... ",p_rec_ibthead.from_ware_code CLIPPED," ",l_source_text CLIPPED 
		PRINT COLUMN 01,"Destination. ",p_rec_ibthead.to_ware_code CLIPPED," ",l_dest_text CLIPPED 
		PRINT COLUMN 01,"Transfer No. ",p_rec_ibthead.trans_num USING "<<<<<<<<", 
		COLUMN 28,p_rec_ibthead.trans_date USING "dd/mm/yyyy" 
		SKIP 1 LINE 

	AFTER GROUP OF p_rec_ibthead.trans_num 
		SKIP 3 LINES 

	AFTER GROUP OF p_sell_uom_code 
		NEED 3 LINES 
		PRINT COLUMN 54,"---------", 
		COLUMN 69,"---------", 
		COLUMN 82,"---------", 
		COLUMN 96,"---------", 
		COLUMN 110,"---------", 
		COLUMN 124,"---------" 
		PRINT COLUMN 54,GROUP SUM(p_rec_ibtdetl.trf_qty)USING "#,###,##&"," ",p_sell_uom_code CLIPPED, 
		COLUMN 69, GROUP SUM(p_rec_ibtdetl.sched_qty)   USING "#,###,##&", 
		COLUMN 82, GROUP SUM(p_rec_ibtdetl.picked_qty)  USING "#,###,##&", 
		COLUMN 96, GROUP SUM(p_rec_ibtdetl.conf_qty)    USING "#,###,##&", 
		COLUMN 110,GROUP SUM(p_rec_ibtdetl.rec_qty)     USING "#,###,##&", 
		COLUMN 124,GROUP SUM(p_rec_ibtdetl.back_qty)    USING "#,###,##&" 
		SKIP 2 LINES 
			
	ON EVERY ROW 
		SELECT * INTO l_rec_product.* FROM product 
		WHERE part_code = p_rec_ibtdetl.part_code	AND 
				cmpy_code = glob_rec_kandoouser.cmpy_code 
		PRINT COLUMN 01,p_rec_ibtdetl.part_code CLIPPED, 
		COLUMN 17, l_rec_product.desc_text CLIPPED, 
		COLUMN 54, p_rec_ibtdetl.trf_qty    USING "#,###,##&"," ",p_sell_uom_code CLIPPED, 
		COLUMN 69, p_rec_ibtdetl.sched_qty  USING "#,###,##&", 
		COLUMN 82, p_rec_ibtdetl.picked_qty USING "#,###,##&", 
		COLUMN 96, p_rec_ibtdetl.conf_qty   USING "#,###,##&", 
		COLUMN 110,p_rec_ibtdetl.rec_qty    USING "#,###,##&", 
		COLUMN 124,p_rec_ibtdetl.back_qty   USING "#,###,##&" 
			
	ON LAST ROW 
		SKIP 2 LINE 
		#End Of Report
		IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
			PRINT COLUMN 01,"Selection Criteria:" 
			PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text CLIPPED WORDWRAP RIGHT MARGIN 100 
		END IF 
		PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report 			
		LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = PAGENO
			
END REPORT
############################################################
# END REPORT I5A_rpt_list() 
############################################################ 