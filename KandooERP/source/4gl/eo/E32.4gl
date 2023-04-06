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
GLOBALS "../eo/E3_GROUP_GLOBALS.4gl"
GLOBALS "../eo/E32_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################
DEFINE modu_rec_backorder RECORD LIKE backorder.* 
DEFINE modu_bware char(3) 
DEFINE modu_eware char(3)
DEFINE modu_shorta char(1)
DEFINE modu_cat_codeuct LIKE backorder.part_code 
DEFINE modu_avail LIKE backorder.avail_qty 

############################################################
# FUNCTION E32_main()
#
# E32  Print back ORDER allocation
############################################################
FUNCTION E32_main() 
	DEFER QUIT 
	DEFER INTERRUPT 

	CALL setModuleId("E32") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	
			OPEN WINDOW E500 WITH FORM "E500_back_order_allocation"
			 CALL windecoration_e("E500")
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
			
			MENU " Back Order allocation" 
		
				BEFORE MENU 
					CALL publish_toolbar("kandoo","E32","menu-Back_Order-1") -- albo kd-502 
					CALL rpt_rmsreps_reset(NULL)  
					CALL E32_rpt_process_backorders(E32_rpt_query_backorders())
					
				ON ACTION "WEB-HELP" -- albo kd-370 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "REPORT" #COMMAND "Report" " SELECT Criteria AND PRINT report"
					CALL rpt_rmsreps_reset(NULL)  
					CALL E32_rpt_process_backorders(E32_rpt_query_backorders())
		
				ON ACTION "PRINT MANAGER" #COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
				
				ON ACTION "CANCEL" #COMMAND KEY(INTERRUPT,"E")"Exit" " Exit TO menus" 
					EXIT MENU 
		
			END MENU 
		
			CLOSE WINDOW E500
			 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL E32_rpt_process_backorders(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW E500 with FORM "E500" 
			 CALL windecoration_e("E500") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(E32_rpt_query_backorders()) #save where clause in env 
			CLOSE WINDOW E500 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL E32_rpt_process_backorders(get_url_sel_text())
	END CASE 	
	
END FUNCTION 
###########################################################################
# END FUNCTION E32_main()  
###########################################################################


############################################################
# FUNCTION E32_rpt_query_backorders() 
#
# 
############################################################
FUNCTION E32_rpt_query_backorders() 
	
	LET modu_shorta = "N"

	INPUT 
		modu_bware,
		modu_eware,
		modu_shorta  WITHOUT DEFAULTS
	FROM 
		bware,
		eware,
		shorta ATTRIBUTE(UNBUFFERED)
		
		AFTER INPUT
			IF modu_bware IS NULL THEN 
				LET modu_bware = " " 
			END IF 
			IF modu_eware IS NULL THEN 
				LET modu_eware = "zzz" 
			END IF 	
	END INPUT
	
	#MESSAGE "    Back Order Allocation Print "

	#prompt " Print short allocations only (y/n)?: "
	#FOR CHAR modu_shorta

	#LET modu_shorta = upshift(modu_shorta)
	#IF modu_shorta = "N"
	#then
	#ELSE
	#LET modu_shorta = "Y"
	#END IF

	--   prompt " Enter beginning warehouse FOR allocation: " -- albo
	--   FOR modu_bware
{
	LET modu_bware = promptInput(" Enter beginning warehouse FOR allocation: ","",3) -- albo 
	LET modu_bware = upshift(modu_bware)  
	IF int_flag OR quit_flag THEN 
		--      CLOSE WINDOW getinfo  -- albo  KD-755
		RETURN FALSE 
	END IF 
	IF modu_bware IS NULL THEN 
		LET modu_bware = " " 
	END IF 

	--   prompt " Enter ending warehouse FOR allocation: " -- albo
	--   FOR modu_eware
	LET modu_eware = promptInput(" Enter ending warehouse FOR allocation: ","",3) -- albo 
	LET modu_eware = upshift(modu_eware) 
	IF int_flag OR quit_flag THEN 
		--      CLOSE WINDOW getinfo  -- albo  KD-755
		RETURN FALSE 
	END IF 
	IF modu_eware IS NULL THEN 
		LET modu_eware = "zzz" 
	END IF 
}
	
	
	IF int_flag OR quit_flag THEN
		LET int_flag = FALSE 
		RETURN NULL
	ELSE
		LET glob_rec_rpt_selector.ref1_code = modu_bware
		LET glob_rec_rpt_selector.ref2_code = modu_eware
		LET glob_rec_rpt_selector.ref1_ind = modu_shorta
		RETURN "N/A"
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION E32_rpt_query_backorders()  
###########################################################################


############################################################
# FUNCTION E32_rpt_process_backorders()  
#
# 
############################################################
FUNCTION E32_rpt_process_backorders(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_rpt_idx SMALLINT  #report array index

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF
	
	LET l_rpt_idx = rpt_start(getmoduleid(),"E32_rpt_list_back","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT E32_rpt_list_back TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	LET modu_bware = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_code  
	LET modu_eware = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref2_code
	LET modu_shorta = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_ind

	DECLARE c_baccurs cursor FOR 
	SELECT * 
	INTO modu_rec_backorder.* 
	FROM backorder 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ware_code between modu_bware AND modu_eware 
	OPEN c_baccurs 



	FOREACH c_baccurs 

		#---------------------------------------------------------
		OUTPUT TO REPORT E32_rpt_list_back(l_rpt_idx,
		modu_rec_backorder.*) 
		IF NOT rpt_int_flag_handler2("CustoOrdermer:",modu_rec_backorder.order_num,NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------

	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT E32_rpt_list_back
	CALL rpt_finish("E32_rpt_list_back")
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
# END FUNCTION E32_rpt_process_backorders()
###########################################################################


############################################################
# REPORT E32_rpt_list_back(p_rpt_idx,	p_rec_backorder) 
#
#
############################################################
REPORT E32_rpt_list_back(p_rpt_idx,p_rec_backorder) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_rec_backorder RECORD LIKE backorder.*
	DEFINE l_short_sign char(3) 

	OUTPUT 

	ORDER external BY p_rec_backorder.part_code, p_rec_backorder.ware_code, 
	p_rec_backorder.avail_qty 

	FORMAT 

		PAGE HEADER 

			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 1, "Product", 
			COLUMN 25, "Available", 
			COLUMN 45, "Order number", 
			COLUMN 63, "Cust code", 
			COLUMN 82, "Quantity required", 
			COLUMN 102, "Quantity allocated" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		BEFORE GROUP OF p_rec_backorder.part_code 

			LET modu_cat_codeuct = p_rec_backorder.part_code 
			LET modu_avail = p_rec_backorder.avail_qty 

		ON EVERY ROW 

			IF p_rec_backorder.req_qty > p_rec_backorder.alloc_qty 
			THEN 
				LET l_short_sign = "***" 
			ELSE 
				LET l_short_sign = " " 
			END IF 

			PRINT COLUMN 1, modu_cat_codeuct, 
			COLUMN 25, modu_avail, 
			COLUMN 45, p_rec_backorder.order_num, 
			COLUMN 65, p_rec_backorder.cust_code, 
			COLUMN 85, p_rec_backorder.req_qty, 
			COLUMN 105, p_rec_backorder.alloc_qty, 
			COLUMN 118, l_short_sign 

			LET modu_cat_codeuct = "" 
			LET modu_avail = modu_avail - p_rec_backorder.req_qty 

		ON LAST ROW 
			SKIP 1 line 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			

END REPORT 
###########################################################################
# END REPORT E32_rpt_list_back(p_rpt_idx,	p_rec_backorder)
###########################################################################