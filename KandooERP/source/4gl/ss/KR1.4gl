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
GLOBALS "../ss/K_SS_GLOBALS.4gl"
GLOBALS "../ss/KR_GROUP_GLOBALS.4gl" 
GLOBALS "../ss/KR1_GLOBALS.4gl"

GLOBALS 
	DEFINE pr_company RECORD LIKE company.*, 
	pr_output CHAR(60), 
	where_text CHAR(600), 
	query_text CHAR(1100), 
	rpt_note CHAR(80), 
	rpt_pageno SMALLINT, 
	rpt_wid,rpt_length SMALLINT, 
	pr_print_addr_flag CHAR(1) #will be stored in rmsreps
END GLOBALS 
###########################################################################
# MAIN
#
# KR1.4gl - Subscription Summary Report - By Product
###########################################################################
MAIN 

	#Initial UI Init
	CALL setModuleId("KR1") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode 
			OPEN WINDOW K153 WITH FORM "K153"
		
			MENU " Customer Subscriptions " 
				BEFORE MENU
					CALL publish_toolbar("kandoo","KR1","menu-customer_subscriptions")		
					CALL rpt_rmsreps_reset(NULL)	 
					CALL KR1_rpt_process(KR1_rpt_query()) 
		
				ON ACTION "WEB-HELP" -- albo kd-374 
					CALL rpt_rmsreps_reset(NULL)	 
					CALL KR1_rpt_process(KR1_rpt_query()) 
		 
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar()
		
				ON ACTION "REPORT" --COMMAND "Run report" " SELECT criteria AND PRINT report"
					CALL rpt_rmsreps_reset(NULL)	 
					CALL KR1_rpt_process(KR1_rpt_query()) 
		
				ON ACTION "PRINT MANAGER"		#COMMAND KEY ("P",f11) "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "CANCEL" #COMMAND KEY(interrupt,"E")"Exit" " EXIT TO Menus" 
					EXIT MENU 
		
			END MENU
			 
			CLOSE WINDOW K153 
	 
		WHEN "2" #Background Process with rmsreps.report_code
			CALL KR1_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW K153 with FORM "K153" 
			CALL winDecoration_k("K153") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(KR1_rpt_query()) #save where clause in env 
			CLOSE WINDOW K153 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL KR1_rpt_process(get_url_sel_text())
	END CASE 	

END MAIN 
###########################################################################
# END MAIN
###########################################################################


###########################################################################
# FUNCTION KR1_rpt_query()
#
# 
###########################################################################
FUNCTION KR1_rpt_query()
	DEFINE l_where_text STRING 
 
	MESSAGE kandoomsg2("K",1001,"")	#K1001 Enter criteria FOR selection
	CONSTRUCT l_where_text ON subcustomer.cust_code, 
	customer.name_text, 
	subcustomer.ship_code, 
	customership.name_text, 
	customership.addr_text, 
	customership.addr2_text, 
	customership.city_text, 
	customership.state_code, 
	customership.post_code, 
	customership.country_code, --@db-patch_2020_10_04--
	subcustomer.part_code, 
	subcustomer.sub_type_code, 
	subcustomer.comm_date, 
	subcustomer.end_date, 
	subcustomer.sub_qty, 
	subcustomer.issue_qty 
	FROM subcustomer.cust_code, 
	customer.name_text, 
	subcustomer.ship_code, 
	customership.name_text, 
	customership.addr_text, 
	customership.addr2_text, 
	customership.city_text, 
	customership.state_code, 
	customership.post_code, 
	customership.country_code, --@db-patch_2020_10_04--
	subcustomer.part_code, 
	subcustomer.sub_type_code, 
	subcustomer.comm_date, 
	subcustomer.end_date, 
	subcustomer.sub_qty, 
	subcustomer.issue_qty 

		ON ACTION "WEB-HELP" -- albo kd-374 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL 
	ELSE		
		LET glob_rec_rpt_selector.ref1_ind = kandoomsg("K",8013,"") #pr_print_addr_flag
		RETURN l_where_text 
	END IF 
END FUNCTION

#####################################################################
# FUNCTION KR1_rpt_process(p_where_text) 
#
#
#####################################################################
FUNCTION KR1_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE pr_cssub RECORD 
		cmpy_code LIKE company.cmpy_code, 
		cust_code LIKE subcustomer.cust_code, 
		name_text LIKE customer.name_text, 
		ship_code LIKE subcustomer.ship_code, 
		part_code LIKE subcustomer.part_code, 
		sub_type_code LIKE subcustomer.sub_type_code, 
		comm_date LIKE subcustomer.comm_date, 
		end_date LIKE subcustomer.end_date, 
		sub_qty LIKE subcustomer.sub_qty, 
		issue_qty LIKE subcustomer.issue_qty, 
		issue_date LIKE subaudit.tran_date, 
		update_date LIKE subaudit.tran_date, 
		status_ind CHAR(1), 
		last_issue_num LIKE subcustomer.last_issue_num 
	END RECORD 
	
	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"KR1_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT KR1_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("KR1_rpt_list")].sel_text
	#------------------------------------------------------------
	# data from rmsreps db record
	LET pr_print_addr_flag = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_ind
	#------------------------------------------------------------
	 
	LET l_query_text = "SELECT subcustomer.cmpy_code, ", 
	"subcustomer.cust_code,", 
	"customership.name_text,", 
	"subcustomer.ship_code,", 
	"subcustomer.part_code,", 
	"subcustomer.sub_type_code , ", 
	"subcustomer.comm_date,", 
	"subcustomer.end_date, ", 
	"'','','','',", 
	"subcustomer.status_ind,", 
	"subcustomer.last_issue_num ", 
	"FROM customer,subcustomer,customership ", 
	"WHERE customer.cmpy_code='",glob_rec_kandoouser.cmpy_code,"'", 
	"AND customership.cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND subcustomer.cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND customer.cust_code=subcustomer.cust_code ", 
	"AND customer.cust_code=customership.cust_code ", 
	"AND subcustomer.ship_code = customership.ship_code ", 
	"AND ",p_where_text clipped," ", 
	"ORDER BY subcustomer.part_code,", 
	"customership.name_text,", 
	"subcustomer.cust_code,", 
	"subcustomer.ship_code,", 
	"subcustomer.comm_date " 
	PREPARE s_subcustomer FROM l_query_text 
	DECLARE c_subcustomer CURSOR FOR s_subcustomer 

	FOREACH c_subcustomer INTO pr_cssub.* 
		SELECT sum(tran_qty) INTO pr_cssub.sub_qty 
		FROM subaudit 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = pr_cssub.cust_code 
		AND ship_code = pr_cssub.ship_code 
		AND part_code = pr_cssub.part_code 
		AND sub_type_code = pr_cssub.sub_type_code 
		AND start_date = pr_cssub.comm_date 
		AND end_date = pr_cssub.end_date 
		AND tran_type_ind = "SUB" 

		SELECT sum(tran_qty) INTO pr_cssub.issue_qty 
		FROM subaudit 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = pr_cssub.cust_code 
		AND ship_code = pr_cssub.ship_code 
		AND part_code = pr_cssub.part_code 
		AND sub_type_code = pr_cssub.sub_type_code 
		AND start_date = pr_cssub.comm_date 
		AND end_date = pr_cssub.end_date 
		AND tran_type_ind = "ISS" 

		#---------------------------------------------------------
		OUTPUT TO REPORT KR1_rpt_list(l_rpt_idx,
		pr_cssub.*) 
		IF NOT rpt_int_flag_handler2("Customer:",pr_cssub.cust_code, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------	

	END FOREACH 
 
	#------------------------------------------------------------
	FINISH REPORT KR1_rpt_list
	CALL rpt_finish("KR1_rpt_list")
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
# END FUNCTION KR1_rpt_query()
###########################################################################


###########################################################################
# REPORT KR1_rpt_list(p_rpt_idx,p_rec_cssub)
#
# 
###########################################################################
REPORT KR1_rpt_list(p_rpt_idx,p_rec_cssub)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE 
	p_rec_cssub RECORD 
		cmpy_code LIKE company.cmpy_code, 
		cust_code LIKE subcustomer.cust_code, 
		name_text LIKE customer.name_text, 
		ship_code LIKE subcustomer.ship_code, 
		part_code LIKE subcustomer.part_code, 
		sub_type_code LIKE subcustomer.sub_type_code, 
		comm_date LIKE subcustomer.comm_date, 
		end_date LIKE subcustomer.end_date, 
		sub_qty LIKE subcustomer.sub_qty, 
		issue_qty LIKE subcustomer.issue_qty, 
		issue_date LIKE subaudit.tran_date, 
		update_date LIKE subaudit.tran_date, 
		status_ind CHAR(1), 
		last_issue_num LIKE subcustomer.last_issue_num 
	END RECORD, 
	pr_product RECORD LIKE product.*, 
	pr_customership RECORD LIKE customership.*, 
	pr_temp_text CHAR(40), 
	line1, line2 CHAR(80), 
	offset1, offset2 SMALLINT, 
	len, s INTEGER, 
	pr_substype RECORD LIKE substype.* 

	OUTPUT 

	ORDER external BY p_rec_cssub.part_code 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  


			PRINT COLUMN 2, "Customer", 
			COLUMN 15, "Name", 
			COLUMN 46, "Shipping", 
			COLUMN 59, "Sub.", 
			COLUMN 64, "Commence.", 
			COLUMN 075, "Finish", 
			COLUMN 82, "Issue", 
			COLUMN 89, "Issue", 
			COLUMN 98, "Update", 
			COLUMN 107, "Last", 
			COLUMN 115, "Status" 
			PRINT COLUMN 2, " Code ", 
			COLUMN 15, " ", 
			COLUMN 46, " Code ", 
			COLUMN 59, "Qty ", 
			COLUMN 66, "Date", 
			COLUMN 076, "Date", 
			COLUMN 82, " Qty ", 
			COLUMN 89, " date", 
			COLUMN 98, " Date ", 
			COLUMN 106,"Issue"
			 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

		BEFORE GROUP OF p_rec_cssub.part_code 
			SKIP TO top OF PAGE
			 
			SELECT * INTO pr_product.* 
			FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = p_rec_cssub.part_code
			 
			SELECT * INTO pr_substype.* 
			FROM substype 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND type_code = p_rec_cssub.sub_type_code
			 
			PRINT COLUMN 001, "Product: " , p_rec_cssub.part_code, 
			COLUMN 026, pr_product.desc_text, 
			COLUMN 056, "Subscription Type: ", 
			COLUMN 075, pr_substype.type_code, 
			COLUMN 079, pr_substype.desc_text clipped 
			PRINT COLUMN 026, pr_product.desc2_text clipped 
			SKIP 1 LINES 

		ON EVERY ROW 
			SELECT max(tran_date) INTO p_rec_cssub.issue_date 
			FROM subaudit 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = p_rec_cssub.cust_code 
			AND ship_code = p_rec_cssub.ship_code 
			AND part_code = p_rec_cssub.part_code 
			AND sub_type_code = p_rec_cssub.sub_type_code 
			AND start_date = p_rec_cssub.comm_date 
			AND end_date = p_rec_cssub.end_date 
			AND tran_type_ind = "CUM" 

			SELECT max(tran_date) INTO p_rec_cssub.update_date 
			FROM subaudit 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = p_rec_cssub.cust_code 
			AND ship_code = p_rec_cssub.ship_code 
			AND part_code = p_rec_cssub.part_code 
			AND sub_type_code = p_rec_cssub.sub_type_code 
			AND start_date = p_rec_cssub.comm_date 
			AND end_date = p_rec_cssub.end_date 
			AND tran_type_ind = "UPD" 

			PRINT COLUMN 3, p_rec_cssub.cust_code, 
			COLUMN 15, p_rec_cssub.name_text, 
			COLUMN 47, p_rec_cssub.ship_code, 
			COLUMN 57, p_rec_cssub.sub_qty USING "####&", 
			COLUMN 64, p_rec_cssub.comm_date USING "dd/mm/yy", 
			COLUMN 073,p_rec_cssub.end_date USING "dd/mm/yy", 
			COLUMN 81, p_rec_cssub.issue_qty USING "####&", 
			COLUMN 88, p_rec_cssub.issue_date USING "dd/mm/yy", 
			COLUMN 97, p_rec_cssub.update_date USING "dd/mm/yy", 
			COLUMN 108,p_rec_cssub.last_issue_num USING "###"; 
			CASE 
				WHEN p_rec_cssub.status_ind = 1 
					PRINT COLUMN 115, "ON hold" 
				WHEN p_rec_cssub.status_ind = 2 
					PRINT COLUMN 115, "CANCELLED" 
				WHEN p_rec_cssub.status_ind = 9 
					PRINT COLUMN 115, "COMPLETE" 
				OTHERWISE 
					PRINT COLUMN 106, " " 
			END CASE
			 
			IF pr_print_addr_flag = "Y" THEN 
				SELECT * INTO pr_customership.* 
				FROM customership 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = p_rec_cssub.cust_code 
				AND ship_code = p_rec_cssub.ship_code 
				IF status = 0 THEN 
					PRINT COLUMN 15, pr_customership.addr_text 
					IF pr_customership.addr2_text IS NOT NULL THEN 
						PRINT COLUMN 15, pr_customership.addr2_text 
					END IF 
					LET pr_temp_text = pr_customership.city_text clipped," ", 
					pr_customership.post_code clipped," ", 
					pr_customership.state_code clipped 
					IF pr_temp_text IS NOT NULL THEN 
						PRINT COLUMN 15,pr_temp_text 
					END IF 
				END IF 
			END IF 
			
		AFTER GROUP OF p_rec_cssub.part_code 
			SKIP 1 LINES 
			PRINT COLUMN 20, " Total ", p_rec_cssub.part_code clipped, " subscriptions:", 
			COLUMN 55, GROUP sum(p_rec_cssub.sub_qty) USING "######&", 
			COLUMN 79, GROUP sum(p_rec_cssub.issue_qty) USING "######&"
			 
		ON LAST ROW 
			NEED 5 LINES 
			SKIP 2 LINES 
			PRINT COLUMN 40, "-----------------------------------------------------", 
			"---------------------------------------" 
			PRINT COLUMN 20, " Total subscriptions:", 
			COLUMN 55, sum(p_rec_cssub.sub_qty) USING "######&", 
			COLUMN 79, sum(p_rec_cssub.issue_qty) USING "######&" 
			NEED 5 LINES 
			SKIP 2 line 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
END REPORT 
