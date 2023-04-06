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
# FUNCTION IR6_main()
#
# Purpose - Barcode label print
############################################################
FUNCTION IR6_main()

	CALL setModuleId("IR6") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode
			OPEN WINDOW I165 WITH FORM "I165" 
			 CALL windecoration_i("I165")
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
			
			MENU "Barcode label" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","IR6","menu-Purchasing_Quotes-1") -- albo kd-505
					CALL rpt_rmsreps_reset(NULL)
					CALL IR6_rpt_process(IR6_rpt_query())

				ON ACTION "WEB-HELP" -- albo kd-372 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar()

				ON ACTION "Report" #COMMAND "Run Report" " SELECT Criteria AND Print Report"
					CALL rpt_rmsreps_reset(NULL)
					CALL IR6_rpt_process(IR6_rpt_query())

				ON ACTION "PRINT MANAGER" --COMMAND "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" --COMMAND KEY (interrupt, "E") "Exit" " Exit TO menus" 
					EXIT MENU

			END MENU
			CLOSE WINDOW I165

		WHEN "2" #Background Process with rmsreps.report_code
			CALL IR6_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW I165 with FORM "I165" 
			 CALL windecoration_i("I165") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(IR6_rpt_query()) #save where clause in env 
			CLOSE WINDOW I165 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL IR6_rpt_process(get_url_sel_text())
	END CASE

END FUNCTION
############################################################
# END FUNCTION IR6_main()
############################################################

############################################################
# FUNCTION IR6_rpt_query() 
# RETURN r_where_text (Query By Example)
# DataSource for the report driver with CONSTRUCT
############################################################
FUNCTION IR6_rpt_query() 
	DEFINE r_where_text LIKE rmsreps.sel_text

	MESSAGE " Enter criteria FOR selection - ESC TO begin search"

	CONSTRUCT BY NAME r_where_text ON 
	prodquote.vend_code, 
	prodquote.part_code, 
	prodquote.oem_text, 
	prodquote.barcode_text, 
	prodquote.cost_amt, 
	prodquote.curr_code, 
	prodquote.freight_amt, 
	prodquote.frgt_curr_code, 
	prodquote.list_amt, 
	prodquote.break_qty, 
	prodquote.lead_time_qty, 
	prodquote.expiry_date, 
	prodquote.desc_text, 
	prodquote.status_ind, 
	prodquote.format_ind 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","IR6","construct-prodquote-2") -- albo kd-505 

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
# END FUNCTION IR6_rpt_query() 
############################################################

############################################################
# FUNCTION IR6_rpt_process(p_where_text) 
# 
# The report driver
############################################################
FUNCTION IR6_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT
	DEFINE l_rec_prodquote RECORD LIKE prodquote.* 

	#------------------------------------------------------------
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE
		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"IR6_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	

	START REPORT IR6_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	LET l_query_text = 
	"SELECT * FROM prodquote ", 
	"WHERE prodquote.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"'", 
	"AND ", p_where_text CLIPPED," ", 
	"ORDER BY prodquote.vend_code,prodquote.curr_code,prodquote.part_code" 
	
	PREPARE s_prodquote FROM l_query_text 
	DECLARE selcurs CURSOR FOR s_prodquote 

	FOREACH selcurs INTO l_rec_prodquote.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT IR6_rpt_list(l_rpt_idx,l_rec_prodquote.*) 
		IF NOT rpt_int_flag_handler2("Product: ",l_rec_prodquote.part_code,"",l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT IR6_rpt_list
	RETURN rpt_finish("IR6_rpt_list")
	#------------------------------------------------------------

END FUNCTION 
############################################################
# END FUNCTION IR6_rpt_process() 
############################################################

############################################################
# REPORT IR6_rpt_list(p_rpt_idx,p_rec_prodquote)
#
# Report Definition/Layout
############################################################
REPORT IR6_rpt_list(p_rpt_idx,p_rec_prodquote) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_prodquote RECORD LIKE prodquote.* 
	DEFINE l_esc CHAR(1)

	ORDER EXTERNAL BY p_rec_prodquote.vend_code,p_rec_prodquote.curr_code,p_rec_prodquote.part_code 

	FORMAT 
		FIRST PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1

	AFTER GROUP OF p_rec_prodquote.part_code 
		LET l_esc = ASCII(27) 
		PRINT l_esc, "A" 
		PRINT "REM Set Base Reference Point" 
		PRINT l_esc, "A3H0426V0001" 
		PRINT l_esc, "CP0" 
		PRINT l_esc, "CI2" 
		PRINT l_esc, TRAN_TYPE_RECEIPT_CA 
		PRINT l_esc, "H0050",l_esc,"V0100",l_esc,"L0101",l_esc,"U",p_rec_prodquote.part_code CLIPPED 
		PRINT l_esc, "H0050", l_esc,"V0200",l_esc,"BI031502",p_rec_prodquote.barcode_text CLIPPED
		PRINT l_esc, "Q1" 
		PRINT l_esc, "Z" 
		SKIP 1 LINE

END REPORT 
