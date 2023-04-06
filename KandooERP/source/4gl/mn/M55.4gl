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
# Purpose - Production Schedule Report
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../mn/M_MN_GLOBALS.4gl"
GLOBALS "../mn/M5_GROUP_GLOBALS.4gl" 
GLOBALS "../mn/M55_GLOBALS.4gl"

GLOBALS 

	DEFINE 
	formname CHAR(15), 
	pv_where_text CHAR(1000), 
	pv_pageno SMALLINT, 
	pr_menunames RECORD LIKE menunames.*, 
	pr_mnparms RECORD LIKE mnparms.* 

END GLOBALS 

###########################################################################
# MAIN
#
# Purpose - Production Schedule Report
###########################################################################
MAIN 

	#Initial UI Init
	CALL setModuleId("M55") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 


	SELECT * 
	INTO pr_mnparms.* 
	FROM mnparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	--    AND    parm_code = 1  -- albo
	AND param_code = 1 -- albo 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("M", 7500, "") # prompt "Manufacturing parameters are NOT SET up - Any key TO continue"
		EXIT program 
	END IF 

	CALL report_main() 

END MAIN 
###########################################################################
# END MAIN
###########################################################################


###########################################################################
# FUNCTION report_main() 
#
# FUNCTION TO DISPLAY the SCREEN AND control program flow via a ring menu
###########################################################################
FUNCTION report_main() 

	OPEN WINDOW w1_m152 with FORM "M152" 
	CALL  windecoration_m("M152") -- albo kd-762 

	CALL kandoomenu("M", 149) RETURNING pr_menunames.* 
	MENU pr_menunames.menu_text # production schedule 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND pr_menunames.cmd1_code pr_menunames.cmd1_text # REPORT 
			IF report_query() THEN 
				NEXT option pr_menunames.cmd3_code # PRINT 
			END IF 

		ON ACTION "Print Manager"	#command pr_menunames.cmd3_code pr_menunames.cmd3_text # Print
			CALL run_prog("URS", "", "", "", "") 

		COMMAND pr_menunames.cmd4_code pr_menunames.cmd4_text # EXIT 
			EXIT MENU 

		COMMAND KEY (interrupt) 
			EXIT MENU 
	END MENU 

	CLOSE WINDOW w1_m152 

END FUNCTION 
###########################################################################
# END UNCTION report_main() 
#
# FUNCTION TO DISPLAY the SCREEN AND control program flow via a ring menu
###########################################################################


###########################################################################
# FUNCTION report_query() 
#
# FUNCTION TO query the SCREEN AND produce a CURSOR TO REPORT FROM 
###########################################################################
FUNCTION report_query() 
	DEFINE 
	fv_query_text CHAR(1000), 
	fv_output CHAR(60), 
	fv_prod_desc LIKE product.desc_text, 
	fr_shopordhead RECORD LIKE shopordhead.* 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]

	LET msgresp = kandoomsg("M", 1500, "") # MESSAGE "Enter selection criteria - ESC TO Accept, DEL TO Exit"

	CONSTRUCT BY NAME pv_where_text 
	ON shop_order_num, suffix_num, shopordhead.part_code, order_qty, 
	uom_code, start_date, end_date 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET msgresp = kandoomsg("M",9555,"") 	# ERROR "Query Aborted"
		RETURN false 
	END IF 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (pv_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"M55_rpt_list_schedule",pv_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT M55_rpt_list_schedule TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET pv_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------

	LET fv_query_text = "SELECT shopordhead.*, desc_text ", 
	"FROM shopordhead, product ", 
	"WHERE shopordhead.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	"AND product.cmpy_code = shopordhead.cmpy_code ", 
	"AND product.part_code = shopordhead.part_code ", 
	"AND shopordhead.status_ind <> 'C' ", 
	"AND order_type_ind <> 'F' ", 
	"AND ", pv_where_text clipped, " ", 
	"ORDER BY end_date, shop_order_num, suffix_num" 

	PREPARE statement1 FROM fv_query_text 
	DECLARE c_schedule CURSOR FOR statement1 


	FOREACH c_schedule INTO fr_shopordhead.*, fv_prod_desc 
		
		#---------------------------------------------------------
		OUTPUT TO REPORT M55_rpt_list_schedule(l_rpt_idx,
		fr_shopordhead.*, fv_prod_desc) 
		#---------------------------------------------------------
 
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT M55_rpt_list_schedule
	CALL rpt_finish("M55_rpt_list_schedule")
	#------------------------------------------------------------

	RETURN true
END FUNCTION 
###########################################################################
# END FUNCTION report_query() 
###########################################################################


###########################################################################
# REPORT M55_rpt_list_schedule(p_rpt_idx,rr_shopordhead, rv_prod_desc)
#
# REPORT TO produce a production schedule 
###########################################################################
REPORT M55_rpt_list_schedule(p_rpt_idx, rr_shopordhead, rv_prod_desc) 
	DEFINE p_rpt_idx SMALLINT  #report array index
	DEFINE 
	rr_shopordhead RECORD LIKE shopordhead.*, 
	rv_prod_desc LIKE product.desc_text, 
	rv_name_text LIKE customer.name_text, 
	rv_eof_text CHAR(50), 
	rv_selection_text CHAR(25)

	OUTPUT 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
		

			PRINT COLUMN 4, "Sales", 
			COLUMN 48, "Shop", 
			COLUMN 107, "Quantity", 
			COLUMN 116, "Start" 
			PRINT COLUMN 4, "Order", 
			COLUMN 10, "Customer", 
			COLUMN 47, "Order", 
			COLUMN 54, "Product", 
			COLUMN 70, "Description", 
			COLUMN 108, "Ordered", 
			COLUMN 116, "Date", 
			COLUMN 125, "Due Date" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		ON EVERY ROW 
			LET rv_name_text = NULL 

			IF rr_shopordhead.cust_code IS NOT NULL THEN 
				SELECT name_text 
				INTO rv_name_text 
				FROM customer 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = rr_shopordhead.cust_code 
			END IF 

			PRINT COLUMN 1, rr_shopordhead.sales_order_num USING "########", 
			COLUMN 10, rv_name_text, 
			COLUMN 41, rr_shopordhead.shop_order_num USING "########", 
			COLUMN 50, rr_shopordhead.suffix_num USING "#&", 
			COLUMN 54, rr_shopordhead.part_code, 
			COLUMN 70, rv_prod_desc, 
			COLUMN 101, rr_shopordhead.order_qty, 
			COLUMN 116, rr_shopordhead.start_date USING "dd/mm/yy", 
			COLUMN 125, rr_shopordhead.end_date USING "dd/mm/yy" 

			IF pr_mnparms.ref4_ind matches "[1234]" 
			AND rr_shopordhead.user4_text IS NOT NULL THEN 
				PRINT COLUMN 10, pr_mnparms.ref4_text clipped, ": ", 
				rr_shopordhead.user4_text 
			END IF 

			PRINT 

		ON LAST ROW 

			SKIP 1 line 

			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN
				NEED 4 LINES  
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100
			ELSE
				NEED 2 LINES  
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4]


END REPORT 
###########################################################################
# END REPORT M55_rpt_list_schedule(p_rpt_idx,rr_shopordhead, rv_prod_desc)
###########################################################################