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
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../pu/R_PU_GLOBALS.4gl" 
GLOBALS "../pu/RA_GROUP_GLOBALS.4gl"
GLOBALS "../pu/RAF_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################   
DEFINE modu_rec_options RECORD 
	head_detl_flag, 
	head_deliv_flag, 
	head_notes_flag, 
	line_detl_flag, 
	line_notes_flag, 
	status_flag CHAR(1), 
	sort_flag SMALLINT 
END RECORD 
DEFINE modu_rec_purchhead RECORD LIKE purchhead.* 
DEFINE modu_order_lines INTEGER 
DEFINE modu_vendor_orders INTEGER 
DEFINE modu_report_orders INTEGER 
DEFINE modu_vendor_total FLOAT 
DEFINE modu_report_total FLOAT 
DEFINE modu_order_total FLOAT 

###########################################################################
# FUNCTION RAF_main() 
#
# RAF Purchase Order Detail 2 Report
###########################################################################
FUNCTION RAF_main() 
	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("RAF") -- albo 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode
			OPEN WINDOW R605 with FORM "R605" 
			CALL  windecoration_r("R605") 

			MENU " Purchase Order Detail 2" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","RAE","menu-purch_order_det-1") 
					CALL RAF_rpt_process(RAF_rpt_query())

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
					
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				COMMAND "Run" " Enter SELECT criteria AND generate REPORT" 
					CALL RAF_rpt_process(RAF_rpt_query())

				ON ACTION "Print Manager" 					#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				COMMAND KEY("E",interrupt)"Exit" " Exit TO menus" 
					EXIT MENU 
					
			END MENU 
			CLOSE WINDOW R605 


		WHEN "2" #Background Process with rmsreps.report_code
			CALL RAF_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW R605 with FORM "R605" 
			CALL  windecoration_r("R605") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(RAF_rpt_query()) #save where clause in env 
			CLOSE WINDOW R605 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL RAF_rpt_process(get_url_sel_text())
	END CASE
END FUNCTION 
###########################################################################
# END FUNCTION RAF_main() 
###########################################################################


###########################################################################
# FUNCTION rpt_options() 
#
# 
###########################################################################
FUNCTION rpt_options() 
	OPEN WINDOW R606 with FORM "R606" 
	CALL  windecoration_r("R606") 

	LET msgresp = kandoomsg("U",1009,"")	#1009 Enter Report Details;  OK TO Continue.

	LET modu_rec_options.head_detl_flag = "Y" 
	LET modu_rec_options.head_deliv_flag = "Y" 
	LET modu_rec_options.head_notes_flag = "Y" 
	LET modu_rec_options.line_detl_flag = "Y" 
	LET modu_rec_options.line_notes_flag = "Y" 
	LET modu_rec_options.status_flag = "Y" 
	LET modu_rec_options.sort_flag = 1 

	INPUT BY NAME modu_rec_options.head_detl_flag, 
	modu_rec_options.head_deliv_flag, 
	modu_rec_options.head_notes_flag, 
	modu_rec_options.line_detl_flag, 
	modu_rec_options.line_notes_flag, 
	modu_rec_options.status_flag, 
	modu_rec_options.sort_flag WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","R12","inp-ooptions-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		AFTER FIELD head_detl_flag 
			IF modu_rec_options.head_detl_flag IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered.
				LET modu_rec_options.head_detl_flag = "Y" 
				NEXT FIELD head_detl_flag 
			END IF 
		AFTER FIELD head_deliv_flag 
			IF modu_rec_options.head_deliv_flag IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered.
				LET modu_rec_options.head_deliv_flag = "Y" 
				NEXT FIELD head_deliv_flag 
			END IF 
		AFTER FIELD head_notes_flag 
			IF modu_rec_options.head_notes_flag IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered.
				LET modu_rec_options.head_notes_flag = "Y" 
				NEXT FIELD head_notes_flag 
			END IF 

		AFTER FIELD line_detl_flag 
			IF modu_rec_options.line_detl_flag IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered.
				LET modu_rec_options.line_detl_flag = "Y" 
				NEXT FIELD line_detl_flag 
			END IF 

		AFTER FIELD line_notes_flag 
			IF modu_rec_options.line_notes_flag IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered.
				LET modu_rec_options.line_notes_flag = "Y" 
				NEXT FIELD line_notes_flag 
			END IF 

		AFTER FIELD status_flag 
			IF modu_rec_options.status_flag IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered.
				LET modu_rec_options.status_flag = "Y" 
				NEXT FIELD status_flag 
			END IF 

		AFTER FIELD sort_flag 
			IF modu_rec_options.sort_flag IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered.
				LET modu_rec_options.sort_flag = 1 
				NEXT FIELD sort_flag 
			END IF 

	END INPUT 

	CLOSE WINDOW R606 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

	LET glob_rec_rpt_selector.ref1_code = modu_rec_options.head_detl_flag 
	LET glob_rec_rpt_selector.ref2_code = modu_rec_options.head_deliv_flag 
	LET glob_rec_rpt_selector.ref3_code = modu_rec_options.head_notes_flag 
	LET glob_rec_rpt_selector.ref4_code = modu_rec_options.line_detl_flag 
	LET glob_rec_rpt_selector.ref1_ind = modu_rec_options.line_notes_flag 
	LET glob_rec_rpt_selector.ref2_ind = modu_rec_options.status_flag 
	LET glob_rec_rpt_selector.ref1_num = modu_rec_options.sort_flag
	 
	RETURN true 
END FUNCTION 
###########################################################################
# END FUNCTION rpt_options() 
###########################################################################


###########################################################################
# FUNCTION RAF_rpt_query() 
#
# 
###########################################################################
FUNCTION RAF_rpt_query() 
	DEFINE l_where_text STRING 
	
	LET msgresp = kandoomsg("U",1001,"") #1001 Enter Selection Criteria;  OK TO Continue.
	CONSTRUCT BY NAME l_where_text ON purchhead.vend_code, 
	purchhead.order_num, 
	purchhead.var_num, 
	purchhead.curr_code, 
	purchhead.order_text, 
	purchhead.salesperson_text, 
	purchhead.ware_code, 
	status_ind, 
	printed_flag, 
	confirm_ind, 
	confirm_text, 
	authorise_code, 
	enter_code, 
	order_date, 
	due_date, 
	confirm_date, 
	cancel_date, 
	entry_date, 
	purchdetl.type_ind, 
	oem_text, 
	job_code, 
	acct_code, 
	list_cost_amt, 
	ref_text, 
	activity_code, 
	disc_per 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","RAF","construct-purchhead-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL 
	ELSE
		CALL rpt_options()
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			RETURN NULL
		END IF
	END IF 
	
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL
	ELSE
		RETURN l_where_text
	END IF
END FUNCTION 
###########################################################################
# END FUNCTION RAF_rpt_query() 
###########################################################################


###########################################################################
# FUNCTION RAF_rpt_process(p_where_text)
#
# 
###########################################################################
FUNCTION RAF_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  #report array index
	DEFINE pr_group1 CHAR(24) 
	DEFINE pr_group2 CHAR(24) 

	LET modu_order_lines = 0 
	LET modu_order_total = 0 
	LET modu_vendor_orders = 0 
	LET modu_vendor_total = 0 
	LET modu_report_orders = 0 
	LET modu_report_total = 0 
	
	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"RAF_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT RAF_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = 0, 
	BOTTOM MARGIN = 0, 
	LEFT MARGIN = 0, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------
	
	
	#------------------------------------------------------------
	LET modu_rec_options.head_detl_flag = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("RAF_rpt_list")].ref1_code 
	LET modu_rec_options.head_deliv_flag = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("RAF_rpt_list")].ref2_code 
	LET modu_rec_options.head_notes_flag = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("RAF_rpt_list")].ref3_code 
	LET modu_rec_options.line_detl_flag = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("RAF_rpt_list")].ref4_code 
	LET modu_rec_options.line_notes_flag = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("RAF_rpt_list")].ref1_ind 
	LET modu_rec_options.status_flag = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("RAF_rpt_list")].ref2_ind 
	LET modu_rec_options.sort_flag = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("RAF_rpt_list")].ref1_num 

	LET l_query_text = 
	"SELECT purchhead.order_num, purchhead.vend_code, purchhead.due_date ", 
	" FROM purchhead, purchdetl ", 
	"WHERE purchhead.cmpy_code ='",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND purchdetl.cmpy_code = purchhead.cmpy_code ", 
	" AND purchdetl.order_num = purchhead.order_num ", 
	"AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("RAF_rpt_list")].sel_text clipped," ", 
	" group by purchhead.order_num, purchhead.vend_code, purchhead.due_date " 

	CASE modu_rec_options.sort_flag 
		WHEN 1 
			LET l_query_text = l_query_text clipped, 
			" ORDER BY purchhead.vend_code, ", 
			"purchhead.order_num" 
		WHEN 2 
			LET l_query_text = l_query_text clipped, 
			" ORDER BY purchhead.vend_code, ", 
			"purchhead.due_date" 
		WHEN 3 
			LET l_query_text = l_query_text clipped, 
			" ORDER BY purchhead.order_num, ", 
			"purchhead.vend_code" 
		WHEN 4 
			LET l_query_text = l_query_text clipped, 
			" ORDER BY purchhead.due_date, ", 
			"purchhead.vend_code" 
	END CASE 

	PREPARE s_poorder FROM l_query_text 
	DECLARE c_poorder CURSOR FOR s_poorder 
	FOREACH c_poorder INTO modu_rec_purchhead.order_num, 
		modu_rec_purchhead.vend_code, 
		modu_rec_purchhead.due_date 
		CASE modu_rec_options.sort_flag 
			WHEN 1 
				LET pr_group1 = modu_rec_purchhead.vend_code 
				LET pr_group2 = modu_rec_purchhead.order_num 
			WHEN 2 
				LET pr_group1 = modu_rec_purchhead.vend_code 
				LET pr_group2 = modu_rec_purchhead.order_num 
			WHEN 3 
				LET pr_group1 = modu_rec_purchhead.order_num 
				LET pr_group2 = modu_rec_purchhead.vend_code 
			WHEN 4 
				LET pr_group1 = modu_rec_purchhead.order_num 
				LET pr_group2 = modu_rec_purchhead.vend_code 
		END CASE 

		#---------------------------------------------------------
		OUTPUT TO REPORT RAF_rpt_list(l_rpt_idx,
		modu_rec_purchhead.order_num, 
		pr_group1, 
		pr_group2) 
		--IF NOT rpt_int_flag_handler2("Vendor:",modu_rec_purchhead.vend_code,NULL,l_rpt_idx) THEN
		--	EXIT FOREACH 
		--END IF 
		#---------------------------------------------------------		


		CASE modu_rec_options.sort_flag 
			WHEN 1 
				IF NOT rpt_int_flag_handler2("Vendor",modu_rec_purchhead.vend_code, 
				modu_rec_purchhead.order_num,l_rpt_idx) THEN 
					EXIT FOREACH 
				END IF 
			WHEN 2 
				IF NOT rpt_int_flag_handler2("Vendor",modu_rec_purchhead.vend_code, 
				modu_rec_purchhead.due_date,l_rpt_idx) THEN 
					EXIT FOREACH 
				END IF 
			WHEN 3 
				IF NOT rpt_int_flag_handler2("Purchase ORDER",modu_rec_purchhead.order_num, 
				modu_rec_purchhead.vend_code,l_rpt_idx) THEN 
					EXIT FOREACH 
				END IF 
			WHEN 4 
				IF NOT rpt_int_flag_handler2("Due date",modu_rec_purchhead.due_date, 
				modu_rec_purchhead.vend_code,l_rpt_idx) THEN 
					EXIT FOREACH 
				END IF 
		END CASE 
		CONTINUE FOREACH 
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT RAF_rpt_list
	CALL rpt_finish("RAF_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION RAF_rpt_process(p_where_text)
###########################################################################


###########################################################################
# REPORT RAF_rpt_list(p_rpt_idx,pr_order_num, pr_group1, pr_group2)
#
# 
###########################################################################
REPORT RAF_rpt_list(p_rpt_idx,pr_order_num, pr_group1, pr_group2) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE pr_purchdetl RECORD LIKE purchdetl.* 
	DEFINE pr_poaudit RECORD LIKE poaudit.* 
	DEFINE pr_notes RECORD LIKE notes.* 
	DEFINE pr_order_num LIKE purchhead.order_num 
	DEFINE pr_vendor_text LIKE vendor.name_text 
	DEFINE pr_city_text LIKE vendor.city_text 
	DEFINE vendor_count SMALLINT 
	DEFINE order_count SMALLINT 
	DEFINE first_order SMALLINT
	DEFINE pr_group1 CHAR(24) 
	DEFINE pr_group2 CHAR(24) 
	DEFINE pr_desc_text LIKE jmresource.desc_text 

	OUTPUT 
	left margin 1 
	ORDER external BY pr_group1, 
	pr_group2 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  

		BEFORE GROUP OF pr_group1 
			SELECT * INTO modu_rec_purchhead.* FROM purchhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND order_num = pr_order_num 
			SELECT name_text, city_text INTO pr_vendor_text, pr_city_text 
			FROM vendor 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = modu_rec_purchhead.vend_code 

			IF modu_rec_options.sort_flag = 1 
			OR modu_rec_options.sort_flag = 2 THEN 
				PRINT COLUMN 01, "Vendor:", 
				COLUMN 10, modu_rec_purchhead.vend_code, 
				COLUMN 20, pr_vendor_text, 
				COLUMN 62, pr_city_text, 
				COLUMN 104, "Curr:", 
				COLUMN 111, modu_rec_purchhead.curr_code 
				PRINT COLUMN 01, "======" 
			ELSE 
				PRINT COLUMN 01, "Order:", 
				COLUMN 10, modu_rec_purchhead.order_num USING "<<<<<<<<", 
				COLUMN 21, "Variation:", 
				COLUMN 33, modu_rec_purchhead.var_num USING "####", 
				COLUMN 38, "Order Date:", 
				COLUMN 51, modu_rec_purchhead.order_date USING "dd/mm/yyyy", 
				COLUMN 63, "Due Date:", 
				COLUMN 74, modu_rec_purchhead.due_date USING "dd/mm/yyyy", 
				COLUMN 86, "Cancelled:", 
				COLUMN 97, modu_rec_purchhead.cancel_date USING "dd/mm/yyyy" 
				PRINT COLUMN 01, "======" 
			END IF 

		BEFORE GROUP OF pr_group2 
			SELECT * INTO modu_rec_purchhead.* FROM purchhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND order_num = pr_order_num 
			SELECT name_text, city_text INTO pr_vendor_text, pr_city_text 
			FROM vendor 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = modu_rec_purchhead.vend_code 

			IF modu_rec_options.sort_flag = 1 
			OR modu_rec_options.sort_flag = 2 THEN 
				LET modu_vendor_orders = modu_vendor_orders + 1 
				PRINT COLUMN 01, "Order:", 
				COLUMN 10, modu_rec_purchhead.order_num USING "<<<<<<<<", 
				COLUMN 21, "Variation:", 
				COLUMN 33, modu_rec_purchhead.var_num USING "####", 
				COLUMN 38, "Order Date:", 
				COLUMN 51, modu_rec_purchhead.order_date USING "dd/mm/yyyy", 
				COLUMN 63, "Due Date:", 
				COLUMN 74, modu_rec_purchhead.due_date USING "dd/mm/yyyy", 
				COLUMN 86, "Cancelled:", 
				COLUMN 97, modu_rec_purchhead.cancel_date USING "dd/mm/yyyy" 
				PRINT COLUMN 01, "======" 
			ELSE 
				PRINT COLUMN 01, "Vendor:", 
				COLUMN 10, modu_rec_purchhead.vend_code, 
				COLUMN 20, pr_vendor_text, 
				COLUMN 62, pr_city_text, 
				COLUMN 104, "Curr:", 
				COLUMN 111, modu_rec_purchhead.curr_code 
				PRINT COLUMN 01, "======" 
			END IF 

		ON EVERY ROW 
			IF modu_rec_options.head_detl_flag = "Y" THEN 
				PRINT COLUMN 04, "Vendor Ref:", 
				COLUMN 27, modu_rec_purchhead.order_text, 
				COLUMN 43, "Contact:", 
				COLUMN 52, modu_rec_purchhead.salesperson_text 
				PRINT COLUMN 04, "Entry Code:", 
				COLUMN 27, modu_rec_purchhead.enter_code, 
				COLUMN 38, "Date:", 
				COLUMN 45, modu_rec_purchhead.entry_date USING "dd/mm/yyyy", 
				COLUMN 57, "Status:", 
				COLUMN 66, modu_rec_purchhead.status_ind, 
				COLUMN 69, "Printed:", 
				COLUMN 79, modu_rec_purchhead.printed_flag, 
				COLUMN 82, "Revision:", 
				COLUMN 93, modu_rec_purchhead.rev_num USING "#####", 
				COLUMN 100, modu_rec_purchhead.rev_date USING "dd/mm/yyyy", 
				COLUMN 112, "Authorised:", 
				COLUMN 125, modu_rec_purchhead.authorise_code 
				PRINT COLUMN 04, "Confirmed:", 
				COLUMN 16, modu_rec_purchhead.confirm_ind, 
				COLUMN 29, modu_rec_purchhead.confirm_date USING "dd/mm/yyyy", 
				COLUMN 41, modu_rec_purchhead.confirm_text clipped 
			END IF 

			IF modu_rec_options.head_deliv_flag = "Y" THEN 
				PRINT COLUMN 01, "Delivery Details:", 
				COLUMN 31, modu_rec_purchhead.ware_code, 
				COLUMN 37, modu_rec_purchhead.del_name_text 
				PRINT COLUMN 37, modu_rec_purchhead.del_addr1_text 
				PRINT COLUMN 37, modu_rec_purchhead.del_addr2_text 
				PRINT COLUMN 37, modu_rec_purchhead.del_addr3_text 
				PRINT COLUMN 37, modu_rec_purchhead.del_addr4_text 
				PRINT COLUMN 37, modu_rec_purchhead.del_country_code --@db-patch_2020_10_04--
				PRINT COLUMN 01, "Contact:", 
				COLUMN 37, modu_rec_purchhead.contact_text, 
				COLUMN 79, modu_rec_purchhead.tele_text 
				PRINT " " 
			END IF 
			IF modu_rec_options.head_detl_flag = "Y" 
			AND modu_rec_purchhead.com1_text IS NOT NULL 
			AND modu_rec_purchhead.com1_text != " " 
			AND modu_rec_purchhead.com2_text IS NOT NULL 
			AND modu_rec_purchhead.com2_text != " " THEN 
				PRINT COLUMN 01, "Comments:", 
				COLUMN 22, modu_rec_purchhead.com1_text 
				PRINT COLUMN 22, modu_rec_purchhead.com2_text 
				PRINT " " 
			END IF 

			IF modu_rec_options.head_notes_flag = "Y" 
			AND modu_rec_purchhead.note_code IS NOT NULL 
			AND modu_rec_purchhead.note_code != " " THEN 
				DECLARE c_headnotes CURSOR FOR 
				SELECT * INTO pr_notes.* FROM notes 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND note_code = modu_rec_purchhead.note_code 
				PRINT COLUMN 13, "Notes:", 
				COLUMN 22, modu_rec_purchhead.note_code USING "############" 
				FOREACH c_headnotes INTO pr_notes.* 
					PRINT COLUMN 22, pr_notes.note_text 
				END FOREACH 
			END IF 

			PRINT COLUMN 05, "--------------------------------------------------------------------------------------------------------------------------" 
			PRINT COLUMN 05, "Line", 
			COLUMN 12, "Part/Activity", 
			COLUMN 40, "Ordered", 
			COLUMN 50, "UOM", 
			COLUMN 60, "List", 
			COLUMN 68, "Disc.", 
			COLUMN 80, "Unit", 
			COLUMN 93, "Tax", 
			COLUMN 104, "Total", 
			COLUMN 114, "Account" 
			PRINT COLUMN 05, "--------------------------------------------------------------------------------------------------------------------------" 

			DECLARE c_purchdetl CURSOR FOR 
			SELECT * INTO pr_purchdetl.* FROM purchdetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND order_num = modu_rec_purchhead.order_num 
			FOREACH c_purchdetl INTO pr_purchdetl.* 
				LET modu_order_lines = modu_order_lines + 1 
				CALL po_line_info(glob_rec_kandoouser.cmpy_code, 
				pr_purchdetl.order_num, 
				pr_purchdetl.line_num) 
				RETURNING pr_poaudit.order_qty, 
				pr_poaudit.received_qty, 
				pr_poaudit.voucher_qty, 
				pr_poaudit.unit_cost_amt, 
				pr_poaudit.ext_cost_amt, 
				pr_poaudit.unit_tax_amt, 
				pr_poaudit.ext_tax_amt, 
				pr_poaudit.line_total_amt 
				LET modu_order_total = modu_order_total + pr_poaudit.line_total_amt 
				PRINT COLUMN 05, pr_purchdetl.line_num USING "###", 
				COLUMN 10, pr_purchdetl.type_ind, 
				COLUMN 12, pr_purchdetl.ref_text clipped, 
				COLUMN 39, pr_poaudit.order_qty USING "######&.&&", 
				COLUMN 50, pr_purchdetl.uom_code, 
				COLUMN 55, pr_purchdetl.list_cost_amt USING "#####,##&.&&", 
				COLUMN 68, pr_purchdetl.disc_per USING "#&.&&&", 
				COLUMN 74, "%", 
				COLUMN 75, pr_poaudit.unit_cost_amt USING "#####,##&.&&", 
				COLUMN 88, pr_poaudit.unit_tax_amt USING "####,##&.&&", 
				COLUMN 100, pr_poaudit.line_total_amt USING "######,##&.&&", 
				COLUMN 114, pr_purchdetl.acct_code 

				IF modu_rec_options.status_flag = "Y" THEN 
					PRINT COLUMN 31, "Rec'd:", 
					COLUMN 39, pr_poaudit.received_qty USING "######&.&&" 
					PRINT COLUMN 31, "Inv'd:", 
					COLUMN 39, pr_poaudit.voucher_qty USING "######&.&&" 
				END IF 

				IF modu_rec_options.line_detl_flag = "Y" THEN 
					PRINT COLUMN 13, pr_purchdetl.desc_text, 
					COLUMN 54, pr_purchdetl.desc2_text 
					IF pr_purchdetl.type_ind = "J" OR pr_purchdetl.type_ind = "C" THEN 
						SELECT desc_text INTO pr_desc_text FROM jmresource 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND jmresource.res_code = pr_purchdetl.res_code 
						IF status = notfound THEN 
							LET pr_desc_text = " " 
						END IF 
						PRINT COLUMN 13, "Resource", 
						COLUMN 26, pr_purchdetl.ref_text[1,8], 
						COLUMN 36, pr_desc_text 
					END IF 
					PRINT COLUMN 13, "Vendor Ref.", 
					COLUMN 26, pr_purchdetl.oem_text 
				END IF 

				IF modu_rec_options.line_notes_flag = "Y" 
				AND pr_purchdetl.note_code IS NOT NULL 
				AND pr_purchdetl.note_code != " " THEN 
					DECLARE c_detlnotes CURSOR FOR 
					SELECT * INTO pr_notes.* FROM notes 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND note_code = pr_purchdetl.note_code 
					PRINT COLUMN 13, "Notes:", 
					COLUMN 21, modu_rec_purchhead.note_code USING "############" 
					FOREACH c_detlnotes INTO pr_notes.* 
						PRINT COLUMN 21, pr_notes.note_text 
					END FOREACH 
				END IF 
				PRINT " " 

			END FOREACH 

		AFTER GROUP OF pr_group2 
			IF modu_rec_options.sort_flag = 1 
			OR modu_rec_options.sort_flag = 2 THEN 
				PRINT COLUMN 99, "--------------" 
				PRINT COLUMN 05, "Order Total:", 
				COLUMN 22, modu_order_lines USING "###&", 
				COLUMN 27, "Lines", 
				COLUMN 99, modu_order_total USING "#######,##&.&&" 
				LET modu_vendor_total = modu_vendor_total + modu_order_total 
				LET modu_order_total = 0 
				LET modu_order_lines = 0 
			ELSE 
				LET modu_vendor_orders = 1 #can only be one vendor ORDER 
				PRINT COLUMN 99, "--------------" 
				PRINT COLUMN 05, "Vendor Total:", 
				COLUMN 21, modu_vendor_orders USING "####&", 
				COLUMN 27, "Orders", 
				COLUMN 36, "Average", 
				COLUMN 44, (modu_order_total / modu_vendor_orders) 
				USING "#######,##&.&&", 
				COLUMN 99, modu_order_total USING "#######,##&.&&" 
				LET modu_report_orders = modu_report_orders + modu_vendor_orders 
				LET modu_report_total = modu_report_total + modu_order_total 
				LET modu_vendor_orders = 0 
				LET modu_vendor_total = 0 
			END IF 
			PRINT " " 

		AFTER GROUP OF pr_group1 
			IF modu_rec_options.sort_flag = 1 
			OR modu_rec_options.sort_flag = 2 THEN 
				PRINT COLUMN 99, "--------------" 
				PRINT COLUMN 05, "Vendor Total:", 
				COLUMN 21, modu_vendor_orders USING "####&", 
				COLUMN 27, "Orders", 
				COLUMN 36, "Average", 
				COLUMN 44, (modu_vendor_total / modu_vendor_orders) 
				USING "#######,##&.&&", 
				COLUMN 99, modu_vendor_total USING "#######,##&.&&" 
				LET modu_report_total = modu_report_total + modu_vendor_total 
				LET modu_report_orders = modu_report_orders + modu_vendor_orders 
				LET modu_vendor_orders = 0 
				LET modu_vendor_total = 0 
			ELSE 
				PRINT COLUMN 99, "--------------" 
				PRINT COLUMN 05, "Order Total:", 
				COLUMN 22, modu_order_lines USING "###&", 
				COLUMN 27, "Lines", 
				COLUMN 99, modu_order_total USING "#######,##&.&&" 
				LET modu_order_total = 0 
				LET modu_order_lines = 0 
			END IF 
			PRINT " " 
			PRINT " " 
			PRINT " " 
			PRINT " " 
			
		ON LAST ROW 
			PRINT " " 
			PRINT COLUMN 99, "--------------" 
			PRINT COLUMN 05, "Report Total:", 
			COLUMN 20, modu_report_orders USING "#####&", 
			COLUMN 27, "Orders", 
			COLUMN 36, "Average", 
			COLUMN 44, (modu_report_total / modu_report_orders) 
			USING "#######,##&.&&", 
			COLUMN 99, modu_report_total USING "#######,##&.&&" 
			PRINT " " 
			PRINT " " 
			PRINT " " 
			PRINT " " 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	


			LET modu_report_orders = 0 
			LET modu_report_total = 0 
END REPORT
###########################################################################
# END REPORT RAF_rpt_list(p_rpt_idx,pr_order_num, pr_group1, pr_group2)
########################################################################### 