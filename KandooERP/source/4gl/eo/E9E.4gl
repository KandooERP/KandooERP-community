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
GLOBALS "../eo/E9_GLOBALS.4gl" 
GLOBALS "../eo/E9E_GLOBALS.4gl"
###########################################################################
# MODULAR Scope Variables
###########################################################################
###########################################################################
# FUNCTION E9E_main()
#
# E9E - Summary Report of Picking Slips
###########################################################################
FUNCTION E9E_main() 
	DEFER QUIT 
	DEFER INTERRUPT 

	CALL setModuleId("E9E") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 
			OPEN WINDOW E458 with FORM "E458" 
			 CALL windecoration_e("E458") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
		
			MENU " Picking Slip summary" 
		
				BEFORE MENU 
					CALL publish_toolbar("kandoo","E9E","menu-Picking_Slip-1") -- albo kd-502 
					CALL rpt_rmsreps_reset(NULL)
					CALL E9E_rpt_process(E9E_rpt_query())
					
				ON ACTION "WEB-HELP" -- albo kd-370 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "REPORT" #COMMAND "Run" " SELECT criteria AND PRINT report" 
					CALL rpt_rmsreps_reset(NULL)
					CALL E9E_rpt_process(E9E_rpt_query())
		
				ON ACTION "PRINT MANAGER" #COMMAND KEY ("P",f11) "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 
					NEXT option "Exit" 
		
				ON ACTION "CANCEL" #COMMAND KEY(INTERRUPT,"E")"Exit" " Exit TO menus" 
					EXIT MENU 
			END MENU 
		
			CLOSE WINDOW E458 

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL E9E_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW E458 with FORM "E458" 
			 CALL windecoration_e("E458") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(E9E_rpt_query()) #save where clause in env 
			CLOSE WINDOW E458 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL E9E_rpt_process(get_url_sel_text())
	END CASE 	
				
END FUNCTION 
###########################################################################
# END FUNCTION E9E_main()
###########################################################################

 
###########################################################################
# FUNCTION E9E_rpt_query() 
#
# #Construct where clause
###########################################################################
FUNCTION E9E_rpt_query() 
	DEFINE l_where_text STRING
	
	MESSAGE kandoomsg2("U",1001,"") #1001 " Enter Selection Criteria - OK TO continue;"
	CONSTRUCT l_where_text ON pickhead.cust_code, 
	pickhead.pick_num, 
	pickhead.pick_date, 
	pickdetl.order_num, 
	pickhead.ware_code, 
	pickdetl.part_code 
	FROM pickhead.cust_code, 
	pickhead.pick_num, 
	pickhead.pick_date, 
	pickdetl.order_num, 
	pickhead.ware_code, 
	pickdetl.part_code 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","E9E","construct-pickhead-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
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
###########################################################################
# END FUNCTION E9E_rpt_query() 
###########################################################################

	
############################################################
# FUNCTION E9E_rpt_process(p_where_text) 
#
#
############################################################
FUNCTION E9E_rpt_process(p_where_text) 
	DEFINE p_where_text STRING
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE l_rec_pickdetl RECORD LIKE pickdetl.* 
	DEFINE l_rec_pickhead RECORD LIKE pickhead.* 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"E9E_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT E9E_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------

	LET l_query_text = "SELECT pickhead.*,", 
	"pickdetl.* ", 
	"FROM pickhead,", 
	"pickdetl ", 
	"WHERE pickhead.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND pickdetl.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND pickdetl.pick_num = pickhead.pick_num ", 
	"AND pickdetl.ware_code = pickhead.ware_code ", 
	"AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("E9E_rpt_list")].sel_text clipped," ",	 
	"ORDER BY pickdetl.ware_code,", 
	"pickdetl.pick_num,", 
	"pickdetl.order_num,", 
	"pickdetl.order_line_num" 
	
	PREPARE s_pickhead FROM l_query_text
	 
	DISPLAY " Picking Slip: " at 1,5 
	DECLARE c_pickhead cursor FOR s_pickhead 

	FOREACH c_pickhead INTO l_rec_pickhead.*, l_rec_pickdetl.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT E9E_rpt_list(l_rpt_idx, l_rec_pickhead.*, l_rec_pickdetl.*) 
		IF NOT rpt_int_flag_handler2("Picking Slip:",l_rec_pickdetl.pick_num, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------		
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT E9E_rpt_list
	CALL rpt_finish("E9E_rpt_list")
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
# END FUNCTION E9E_rpt_process(p_where_text) 
############################################################


###########################################################################
# REPORT E9E_rpt_list(p_rpt_idx,p_rec_pickhead,p_rec_pickdetl) 
#
#
###########################################################################
REPORT E9E_rpt_list(p_rpt_idx,p_rec_pickhead,p_rec_pickdetl) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_pickhead RECORD LIKE pickhead.*
	DEFINE p_rec_pickdetl RECORD LIKE pickdetl.*
	DEFINE l_cust_name_text LIKE customer.name_text
	DEFINE l_rec_warehouse RECORD LIKE warehouse.*
	DEFINE l_cmpy_head char(132)
	DEFINE l_col2 SMALLINT 

	OUTPUT 

	ORDER external BY p_rec_pickdetl.ware_code, 
	p_rec_pickdetl.pick_num, 
	p_rec_pickdetl.order_num, 
	p_rec_pickdetl.order_line_num 

	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 7, "Pick", 
			COLUMN 16, "Pick", 
			COLUMN 24, "Customer", 
			COLUMN 33, "Shipping", 
			COLUMN 45, "Order", 
			COLUMN 54, "Order", 
			COLUMN 62, "Print", 
			COLUMN 68, "Print", 
			COLUMN 75, "Status" 

			PRINT COLUMN 6, "Number", 
			COLUMN 16, "Date", 
			COLUMN 24, " code", 
			COLUMN 33, " Code ", 
			COLUMN 45, "Number", 
			COLUMN 55, "Date", 
			COLUMN 62, "Number ", 
			COLUMN 67, "Date " 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		BEFORE GROUP OF p_rec_pickdetl.ware_code 
			SKIP TO top OF PAGE 
			SELECT * 
			INTO l_rec_warehouse.* 
			FROM warehouse 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ware_code = p_rec_pickdetl.ware_code 
			PRINT COLUMN 2, "Warehouse: ", p_rec_pickdetl.ware_code, 
			COLUMN 20, l_rec_warehouse.desc_text 

		AFTER GROUP OF p_rec_pickdetl.pick_num 
			PRINT COLUMN 4, p_rec_pickdetl.pick_num USING "#######&", 
			COLUMN 14, p_rec_pickhead.pick_date USING "dd/mm/yy", 
			COLUMN 24, p_rec_pickhead.cust_code, 
			COLUMN 33, p_rec_pickhead.ship_code, 
			COLUMN 43, p_rec_pickdetl.order_num USING "#######&", 
			COLUMN 53, p_rec_pickdetl.order_date USING "dd/mm/yy", 
			COLUMN 62, p_rec_pickhead.printed_num USING "##&", 
			COLUMN 67, p_rec_pickhead.printed_date USING "dd/mm/yy"; 
			CASE 
				WHEN (p_rec_pickhead.status_ind = 0) 
					PRINT COLUMN 76, "PICK" 
				WHEN (p_rec_pickhead.status_ind = 1) 
					PRINT COLUMN 76, "CONF" 
				WHEN (p_rec_pickhead.status_ind = 9) 
					PRINT COLUMN 76, "CANC" 
				OTHERWISE 
					PRINT COLUMN 76, "ERROR" 
			END CASE 

		ON LAST ROW 
			NEED 9 LINES 
			SKIP 3 line 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			 
END REPORT 
###########################################################################
# END REPORT E9E_rpt_list(p_rpt_idx,p_rec_pickhead,p_rec_pickdetl) 
###########################################################################