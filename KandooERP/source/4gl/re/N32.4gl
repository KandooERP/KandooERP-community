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
GLOBALS "../re/N_RE_GLOBALS.4gl"
GLOBALS "../re/N3_GROUP_GLOBALS.4gl"
GLOBALS "../re/N32_GLOBALS.4gl"  
GLOBALS 
	DEFINE glob_rec_country RECORD LIKE country.* 
	DEFINE where_text CHAR(500) 
--	pr_output CHAR(20) 
END GLOBALS 
###########################################################################
# Module Scope Variables
###########################################################################
###########################################################################
# MAIN
#
# N32 - Requisition Back Order Product Allocation Report
###########################################################################
MAIN 
	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("N32") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_n_re() #init n/re module 

	OPEN WINDOW N124 with FORM "N124" 
	CALL windecoration_n("N124") -- albo kd-763 

	MENU " Req. Allocations" 

		ON ACTION "WEB-HELP" -- albo kd-377 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Run Report" " SELECT Criteria AND Print Report" 
			CALL N32_rpt_query()  

		ON ACTION "Print Manager"			#COMMAND KEY ("P",f11) "Print" "Print OR view using RMS"
			CALL run_prog("URS","","","","") 

		COMMAND KEY(interrupt,"E")"Exit" " RETURN TO Menus" 
			EXIT MENU 

	END MENU 

	CLOSE WINDOW N124 
END MAIN 
###########################################################################
# END MAIN
###########################################################################


###########################################################################
# FUNCTION N32_rpt_query() 
#
# 
###########################################################################
FUNCTION N32_rpt_query() 
	DEFINE pr_reqbackord RECORD LIKE reqbackord.* 
	DEFINE l_where_text CHAR(400) 
	DEFINE l_query_text CHAR(700) 
	DEFINE l_rpt_idx SMALLINT  #report array index

	CLEAR FORM 

	MESSAGE " Enter Selection Criteria - ESC TO Continue "	attribute(yellow) 
	CONSTRUCT l_where_text ON reqbackord.ware_code, 
	reqbackord.part_code, 
	reqbackord.req_num, 
	reqbackord.require_qty, 
	reqbackord.person_code, 
	reqhead.req_date, 
	reqhead.year_num, 
	reqhead.period_num 
	FROM reqhead.ware_code, 
	reqdetl.part_code, 
	reqhead.req_num, 
	reqdetl.back_qty, 
	reqhead.person_code, 
	reqhead.req_date, 
	reqhead.year_num, 
	reqhead.period_num 

		ON ACTION "WEB-HELP" -- albo kd-377 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		MESSAGE " Searching database - please wait "		attribute(yellow) 
	END IF 


		#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (l_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"N32_rpt_list",l_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT N32_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET l_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------


	LET l_query_text = 
	"SELECT reqbackord.* ", 
	"FROM reqbackord,", 
	"reqhead ", 
	"WHERE reqbackord.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND reqbackord.cmpy_code = reqhead.cmpy_code ", 
	"AND reqbackord.req_num = reqhead.req_num ", 
	"AND ",l_where_text clipped," ", 
	"ORDER BY reqbackord.part_code,", 
	"reqbackord.ware_code" 

	PREPARE s1_reqbackord FROM l_query_text 
	DECLARE c_reqbackord CURSOR FOR s1_reqbackord 
 
	FOREACH c_reqbackord INTO pr_reqbackord.* 

		#---------------------------------------------------------
		OUTPUT TO REPORT AB1_rpt_list(l_rpt_idx,	
		pr_reqbackord.*) 

		IF NOT rpt_int_flag_handler2("Product:",pr_reqbackord.part_code, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------

	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT N32_rpt_list
	CALL rpt_finish("N32_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 


REPORT N32_rpt_list(p_rpt_idx, pr_reqbackord) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE pr_reqbackord RECORD LIKE reqbackord.* 
	DEFINE pr_available LIKE prodstatus.onhand_qty 
	--line1, line2 CHAR(100), 
	DEFINE col SMALLINT 
	DEFINE pr_short_ind CHAR(3) 

	OUTPUT 

	ORDER external BY pr_reqbackord.part_code, 
	pr_reqbackord.ware_code, 
	pr_reqbackord.avail_qty
	 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			
			PRINT COLUMN 1, "Product Code", 
			COLUMN 15, "Warehouse", 
			COLUMN 26, "Requisition", 
			COLUMN 39, "Person", 
			COLUMN 53, "Available", 
			COLUMN 69, "Required", 
			COLUMN 83, "Allocated" 
			PRINT COLUMN 17, "Code", 
			COLUMN 28, "Number", 
			COLUMN 40, "Code", 
			COLUMN 53, "Quantity", 
			COLUMN 69, "Quantity", 
			COLUMN 83, "Quantity" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		BEFORE GROUP OF pr_reqbackord.part_code 
			PRINT COLUMN 1, pr_reqbackord.part_code; 

		BEFORE GROUP OF pr_reqbackord.ware_code 
			PRINT COLUMN 17,pr_reqbackord.ware_code; 
			LET pr_available = pr_reqbackord.avail_qty 

		ON EVERY ROW 
			IF pr_reqbackord.require_qty > pr_reqbackord.alloc_qty THEN 
				LET pr_short_ind = "***" 
			ELSE 
				LET pr_short_ind = " " 
			END IF 
			PRINT COLUMN 26,pr_reqbackord.req_num USING "########", 
			COLUMN 39,pr_reqbackord.person_code, 
			COLUMN 48,pr_available USING "--,---,--&.&&&&", 
			COLUMN 63,pr_reqbackord.require_qty USING "--,---,--&.&&&&", 
			COLUMN 78,pr_reqbackord.alloc_qty USING "--,---,--&.&&&&", 
			COLUMN 97,pr_short_ind 
			LET pr_available = pr_available - pr_reqbackord.require_qty 

		AFTER GROUP OF pr_reqbackord.ware_code 
			SKIP 1 line 

		AFTER GROUP OF pr_reqbackord.part_code 
			SKIP 2 LINES 

		ON LAST ROW 
			SKIP 4 LINES
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4]
 				
END REPORT 
