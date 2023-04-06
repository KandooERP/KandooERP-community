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
GLOBALS "../eo/E5_GROUP_GLOBALS.4gl"
GLOBALS "../eo/E5B_GLOBALS.4gl" 
###########################################################################
# FUNCTION E5B_main()
#
# E5B Bulk Pick List
###########################################################################
FUNCTION E5B_main() 
	DEFER QUIT 
	DEFER INTERRUPT 

	CALL setModuleId("E5B") 
	
	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	 
			OPEN WINDOW E454 with FORM "E454" 
			 CALL windecoration_e("E454") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
 
			MENU " Bulk Pick list" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","E5B","menu-Bulk_Pick-1") -- albo kd-502 
					CALL rpt_rmsreps_reset(NULL)
					CALL E5B_rpt_process(E5B_rpt_query())
					
				ON ACTION "WEB-HELP" -- albo kd-370 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "REPORT" #COMMAND "Run" " Enter selection criteria AND generate report" 
					CALL rpt_rmsreps_reset(NULL)
					CALL E5B_rpt_process(E5B_rpt_query())

				ON ACTION "PRINT MANAGER" 	#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" #COMMAND KEY("E",INTERRUPT)"Exit" " Exit TO menus" 
					EXIT MENU 
			END MENU 

			CLOSE WINDOW E454 
	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL E5B_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW E454 with FORM "E454" 
			 CALL windecoration_e("E454") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(E5B_rpt_query()) #save where clause in env 
			CLOSE WINDOW E454 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL E5B_rpt_process(get_url_sel_text())
	END CASE 
	
END FUNCTION 
###########################################################################
# END FUNCTION E5B_main()
###########################################################################


###########################################################################
# FUNCTION E5B_rpt_query() 
#
# 
###########################################################################
FUNCTION E5B_rpt_query() 
	DEFINE l_where_text STRING
	
	MESSAGE kandoomsg2("U",1001,"") 
	CONSTRUCT BY NAME l_where_text ON 
		pickdetl.ware_code, 
		pickdetl.order_num, 
		pickdetl.order_date, 
		pickdetl.pick_num, 
		pickhead.cust_code, 
		pickhead.carrier_code, 
		pickdetl.part_code 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","E5B","construct-pickdetl-1") -- albo kd-502 

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
# END FUNCTION E5B_rpt_query() 
###########################################################################


###########################################################################
# FUNCTION E5B_rpt_process(p_where_text) 
#
# 
###########################################################################
FUNCTION E5B_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  #report array index
	DEFINE l_rec_pickdetl RECORD LIKE pickdetl.* 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"E5B_rpt_list_product",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT E5B_rpt_list_product TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------
	
	LET l_query_text = "SELECT pickdetl.*, prodstatus.* ", 
	" FROM pickdetl,prodstatus, pickhead ", 
	" WHERE prodstatus.cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND prodstatus.cmpy_code = pickdetl.cmpy_code ", 
	" AND pickhead.pick_num = pickdetl.pick_num ", 
	" AND prodstatus.cmpy_code = pickhead.cmpy_code ", 
	" AND prodstatus.ware_code = pickdetl.ware_code ", 
	" AND prodstatus.ware_code = pickhead.ware_code ", 
	" AND prodstatus.part_code = pickdetl.part_code ", 
	" AND pickhead.status_ind = 0 ", 
	" AND ",p_where_text clipped," ", 
	" ORDER BY pickdetl.ware_code,bin1_text,pickdetl.part_code" 
	PREPARE s_pickdetl FROM l_query_text 
	DECLARE c_pickdetl cursor FOR s_pickdetl 
	
	FOREACH c_pickdetl INTO l_rec_pickdetl.*, l_rec_prodstatus.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT E5B_rpt_list_product(l_rpt_idx,
		l_rec_pickdetl.*,
		l_rec_prodstatus.*)  
		IF NOT rpt_int_flag_handler2("Picking Slip:",l_rec_pickdetl.pick_num, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------
	END FOREACH 
	
	#------------------------------------------------------------
	FINISH REPORT E5B_rpt_list_product
	CALL rpt_finish("E5B_rpt_list_product")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = FALSE 
		ERROR " Printing was aborted" 
		RETURN FALSE 
	ELSE 
		RETURN TRUE 
	END IF 	
END FUNCTION 
###########################################################################
# END FUNCTION E5B_rpt_process(p_where_text) 
###########################################################################


###########################################################################
# REPORT E5B_rpt_list_product(p_rpt_idx,p_rec_pickdetl,p_rec_prodstatus)  
#
# 
###########################################################################
REPORT E5B_rpt_list_product(p_rpt_idx,p_rec_pickdetl,p_rec_prodstatus) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_rec_pickdetl RECORD LIKE pickdetl.* 
	DEFINE p_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_rec_product RECORD LIKE product.* 

	OUTPUT 

	ORDER external BY 
		p_rec_pickdetl.ware_code, 
		p_rec_prodstatus.bin1_text, 
		p_rec_pickdetl.part_code 
	
	FORMAT 
	
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			
		BEFORE GROUP OF p_rec_pickdetl.ware_code 
			SKIP TO top OF PAGE 
			SELECT * INTO l_rec_warehouse.* FROM warehouse 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ware_code = p_rec_pickdetl.ware_code 
			PRINT COLUMN 01, "Warehouse: ",p_rec_pickdetl.ware_code, 
			COLUMN 17, l_rec_warehouse.desc_text 
			SKIP 1 line 
			
		AFTER GROUP OF p_rec_pickdetl.part_code 
			SELECT * INTO l_rec_product.* FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = p_rec_pickdetl.part_code 
			PRINT COLUMN 03, p_rec_prodstatus.bin1_text, 
			COLUMN 20, p_rec_pickdetl.part_code, 
			COLUMN 36, GROUP sum(p_rec_pickdetl.picked_qty) USING "------&.&", 
			COLUMN 50, l_rec_product.desc_text 
			
		ON LAST ROW 
			SKIP 3 line 

			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
END REPORT
###########################################################################
# END REPORT E5B_rpt_list_product(p_rpt_idx,p_rec_pickdetl,p_rec_prodstatus)  
###########################################################################