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
GLOBALS "../ss/KR2_GLOBALS.4gl"
GLOBALS 
	DEFINE pr_rec_kandoouser RECORD LIKE kandoouser.*, 
	pr_company RECORD LIKE company.*, 
	pr_output CHAR(60), 
	query_text, where_text CHAR(2000), 
	rpt_length LIKE rmsreps.page_length_num, 
	rpt_pageno INTEGER, 
	rpt_date DATE, 
	rpt_note CHAR(80), 
	i, rpt_wid SMALLINT 
END GLOBALS 

# \file
# \brief module KR2.4gl - Subscription Audit Report -
MAIN 
	DEFER quit 
	DEFER interrupt 

	#Initial UI Init
	CALL setModuleId("KR2") -- albo 
	CALL ui_init(0) 
	CALL authenticate(getmoduleid()) 


	LET rpt_wid = 100 
	LET rpt_note = NULL 
	LET rpt_date = today 
	SELECT * INTO pr_company.* FROM company 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

	OPEN WINDOW wk154 at 2,3 WITH FORM "K154" 
	attribute (border, MESSAGE line first) 
	MENU " Customer Subscriptions audit" 

		ON ACTION "WEB-HELP" -- albo kd-374 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "REPORT" #COMMAND "Run report" " SELECT Criteria AND Print report" 
			CALL kr2_query() 
			IF int_flag OR quit_flag THEN 
				LET int_flag = 0 
				LET quit_flag = 0 
				NEXT option "Exit" 
			END IF 

		ON ACTION "PRINT MANAGER"		#COMMAND KEY ("P",f11) "Print" "Print OR view using RMS"
			CALL run_prog("URS","","","","") 

		COMMAND "Exit" " Exit TO menus" 
			EXIT MENU 
	END MENU 

	CLOSE WINDOW wk154 
END MAIN 


FUNCTION kr2_query()
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	pr_subaudit RECORD 
		cust_code LIKE customer.cust_code, 
		ship_code LIKE customership.ship_code, 
		name_text LIKE customer.name_text, 
		part_code LIKE product.part_code, 
		sub_type_code LIKE subcustomer.sub_type_code, 
		comm_date LIKE subcustomer.comm_date, 
		end_date LIKE subcustomer.end_date, 
		issue_num LIKE subaudit.issue_num, 
		seq_num LIKE subaudit.seq_num, 
		tran_date LIKE subaudit.tran_date, 
		tran_type_ind LIKE subaudit.tran_type_ind, 
		tran_qty LIKE subaudit.tran_qty, 
		unit_amt LIKE subaudit.unit_amt, 
		comm_text LIKE subaudit.comm_text 
	END RECORD 

	MESSAGE 
	" Enter criteria FOR selection - ESC TO begin search " 

	CONSTRUCT where_text 
	ON subcustomer.cust_code, 
	customer.name_text, 
	subcustomer.ship_code, 
	subcustomer.part_code, 
	subcustomer.sub_type_code, 
	subcustomer.comm_date, 
	subcustomer.end_date, 
	subaudit.tran_date, 
	subaudit.tran_type_ind, 
	subaudit.tran_qty, 
	subaudit.unit_amt, 
	subaudit.seq_num, 
	subaudit.source_num, 
	subaudit.comm_text 
	FROM subcustomer.cust_code, 
	customer.name_text, 
	subcustomer.ship_code, 
	subcustomer.part_code, 
	subcustomer.sub_type_code, 
	subcustomer.comm_date, 
	subcustomer.end_date, 
	sr_subaudit[1].tran_date, 
	sr_subaudit[1].tran_type_ind, 
	sr_subaudit[1].tran_qty, 
	sr_subaudit[1].unit_amt, 
	sr_subaudit[1].seq_num, 
	sr_subaudit[1].source_num, 
	sr_subaudit[1].comm_text 

		ON ACTION "WEB-HELP" -- albo kd-374 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 
	END IF 

	LET query_text = "SELECT ", 
	"subcustomer.cust_code, ", 
	"subcustomer.ship_code, ", 
	"customer.name_text, ", 
	"subcustomer.part_code, ", 
	"subcustomer.sub_type_code, ", 
	"subcustomer.comm_date, ", 
	"subcustomer.end_date, ", 
	"subaudit.issue_num, ", 
	"subaudit.seq_num, ", 
	"subaudit.tran_date, ", 
	"subaudit.tran_type_ind, ", 
	"subaudit.tran_qty, ", 
	"subaudit.unit_amt, ", 
	"subaudit.comm_text ", 
	"FROM subcustomer, customer, subaudit ", 
	"WHERE subcustomer.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	" AND subcustomer.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	" AND subaudit.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	" AND subcustomer.cust_code = customer.cust_code ", 
	" AND subaudit.cust_code = subcustomer.cust_code ", 
	" AND subaudit.ship_code = subcustomer.ship_code ", 
	" AND subaudit.part_code = subcustomer.part_code ", 
	" AND subaudit.sub_type_code = subcustomer.sub_type_code ", 
	" AND subaudit.start_date = subcustomer.comm_date ", 
	" AND subaudit.end_date = subcustomer.end_date ", 
	"AND ",where_text clipped," ", 
	"ORDER BY subcustomer.sub_type_code, ", 
	" subcustomer.comm_date,", 
	" subcustomer.part_code,", 
	" customer.name_text, subcustomer.cust_code, ", 
	" subcustomer.ship_code, ", 
	" subaudit.seq_num, ", 
	" subaudit.tran_date " 
	PREPARE invoicer FROM query_text 
	DECLARE selcurs CURSOR FOR invoicer 

	OPEN WINDOW w1 at 12,10 WITH 3 rows,60 COLUMNS 
	attribute (border,prompt line last) 
	DISPLAY " Processing REPORT, please wait" at 1,2 
	DISPLAY " Customer: " at 2,3 

	LET l_rpt_idx = rpt_start(getmoduleid(),"KR2_rpt_list","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT KR2_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------	
	 
	FOREACH selcurs INTO pr_subaudit.* 
		DISPLAY pr_subaudit.cust_code at 2,15 

		#---------------------------------------------------------
		OUTPUT TO REPORT KR2_rpt_list (l_rpt_idx,pr_subaudit.*) 
		#---------------------------------------------------------

		IF int_flag OR quit_flag THEN 
			#8503 Continue Report (Y/N)
			IF kandoomsg("U","8503","") = "N" THEN 
				#9501 Report Terminated
				LET msgresp = kandoomsg("U","9501","") 
				EXIT FOREACH 
			END IF 
			LET int_flag = false 
			LET quit_flag = false 
		END IF 
	END FOREACH 
	CLOSE WINDOW w1 

	#------------------------------------------------------------
	FINISH REPORT KR2_rpt_list
	CALL rpt_finish("KR2_rpt_list")
	#------------------------------------------------------------	 
 
END FUNCTION 


REPORT KR2_rpt_list(p_rpt_idx,pr_subaudit) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE 
	pr_subaudit RECORD 
		cust_code LIKE customer.cust_code, 
		ship_code LIKE customership.ship_code, 
		name_text LIKE customer.name_text, 
		part_code LIKE product.part_code, 
		sub_type_code LIKE subcustomer.sub_type_code, 
		comm_date LIKE subcustomer.comm_date, 
		end_date LIKE subcustomer.end_date, 
		issue_num LIKE subaudit.issue_num, 
		seq_num LIKE subaudit.seq_num, 
		tran_date LIKE subaudit.tran_date, 
		tran_type_ind LIKE subaudit.tran_type_ind, 
		tran_qty LIKE subaudit.tran_qty, 
		unit_amt LIKE subaudit.unit_amt, 
		comm_text LIKE subaudit.comm_text 
	END RECORD, 
	pr_product RECORD LIKE product.*, 
	pr_substype RECORD LIKE substype.*, 
	pr_customership RECORD LIKE customership.*, 
	pr_subcustomer RECORD LIKE subcustomer.*, 
	tot_disc DECIMAL(16,2), 
	line1, line2 CHAR(80), 
	offset1, offset2 SMALLINT, 
	len, s INTEGER 

	OUTPUT 
	--left margin 0 
	ORDER external BY pr_subaudit.sub_type_code, 
	pr_subaudit.comm_date, pr_subaudit.part_code, 
	pr_subaudit.name_text, pr_subaudit.cust_code, 
	pr_subaudit.ship_code, pr_subaudit.seq_num, 
	pr_subaudit.tran_date 

	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 20, "Date", 
			COLUMN 29, "Type", 
			COLUMN 40, "Quantity", 
			COLUMN 50, "Issue", 
			COLUMN 60, "Comments" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		BEFORE GROUP OF pr_subaudit.sub_type_code 
			SKIP TO top OF PAGE 

		BEFORE GROUP OF pr_subaudit.comm_date 
			SKIP TO top OF PAGE 

		BEFORE GROUP OF pr_subaudit.part_code 
			SKIP TO top OF PAGE 
			SELECT * 
			INTO pr_product.* 
			FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_subaudit.part_code 
			SELECT * INTO pr_substype.* FROM substype 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND type_code = pr_subaudit.sub_type_code 
			PRINT COLUMN 1, "Subscription Type :", 
			COLUMN 21, pr_subcustomer.sub_type_code, 
			COLUMN 25, pr_substype.desc_text clipped 
			PRINT COLUMN 1, "Start date:" , pr_subaudit.comm_date USING "dd/mm/yy" 
			PRINT COLUMN 1, "Product:" , pr_subaudit.part_code, 
			COLUMN 25, pr_product.desc_text, 
			COLUMN 60, pr_product.desc2_text 
			SKIP 1 LINES 

		BEFORE GROUP OF pr_subaudit.cust_code 
			PRINT COLUMN 5, "Customer:", 
			COLUMN 15, pr_subaudit.cust_code, 
			COLUMN 25, pr_subaudit.name_text 
			SKIP 1 LINES 

		BEFORE GROUP OF pr_subaudit.ship_code 
			SELECT * 
			INTO pr_customership.* 
			FROM customership 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = pr_subaudit.cust_code 
			AND ship_code = pr_subaudit.ship_code 
			SELECT sum(tran_qty) INTO pr_subcustomer.sub_qty 
			FROM subaudit 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = pr_subaudit.cust_code 
			AND ship_code = pr_subaudit.ship_code 
			AND part_code = pr_subaudit.part_code 
			AND start_date = pr_subaudit.comm_date 
			AND tran_type_ind = "SUB" 
			IF pr_subcustomer.sub_qty IS NULL THEN 
				LET pr_subcustomer.sub_qty = 0 
			END IF 
			SELECT sum(tran_qty) INTO pr_subcustomer.issue_qty 
			FROM subaudit 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = pr_subaudit.cust_code 
			AND ship_code = pr_subaudit.ship_code 
			AND part_code = pr_subaudit.part_code 
			AND start_date = pr_subaudit.comm_date 
			AND tran_type_ind = "ISS" 
			IF pr_subcustomer.issue_qty IS NULL THEN 
				LET pr_subcustomer.issue_qty = 0 
			END IF 
			PRINT COLUMN 10, "Shipping address:", 
			COLUMN 28, pr_subaudit.ship_code, 
			COLUMN 38, pr_customership.name_text, 
			COLUMN 70, pr_customership.addr_text 
			PRINT COLUMN 10, "Subscription: ", pr_subcustomer.sub_qty USING "-----&", 
			COLUMN 33, "Issued: ", pr_subcustomer.issue_qty USING "-----&"; 
			IF pr_customership.addr2_text IS NOT NULL THEN 
				PRINT COLUMN 70, pr_customership.addr2_text 
			END IF 
			IF pr_customership.city_text IS NOT NULL THEN 
				PRINT COLUMN 70, pr_customership.city_text 
			END IF 
			IF pr_customership.city_text IS NOT NULL THEN 
				PRINT COLUMN 70, pr_customership.state_code, 
				COLUMN 75, pr_customership.post_code 
			END IF 
			IF pr_customership.country_code IS NOT NULL THEN --@db-patch_2020_10_04 report--
				PRINT COLUMN 70, pr_customership.country_code --@db-patch_2020_10_04 report--
			END IF 
			PRINT COLUMN 1, " " 
			#skip 1 lines


		ON EVERY ROW 
			PRINT COLUMN 18, pr_subaudit.tran_date USING "dd/mm/yy", 
			COLUMN 30, pr_subaudit.tran_type_ind, 
			COLUMN 38, pr_subaudit.tran_qty USING "------&", 
			COLUMN 51, pr_subaudit.issue_num USING "###", 
			COLUMN 60, pr_subaudit.comm_text 

		AFTER GROUP OF pr_subaudit.ship_code 
			SKIP 2 LINES 
		ON LAST ROW 
			NEED 5 LINES 
			SKIP 2 line 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
END REPORT 
