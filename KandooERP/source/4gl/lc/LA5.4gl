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
GLOBALS "../lc/L_LC_GLOBALS.4gl"
GLOBALS "../lc/LA_GROUP_GLOBALS.4gl" 
GLOBALS "../lc/LA5_GLOBALS.4gl"
 
GLOBALS 
	DEFINE level CHAR(1) 
	DEFINE  msg, prog CHAR(40) 
	DEFINE cmd CHAR(3) 
	DEFINE itis DATE 
	DEFINE prg_name CHAR(7) 
	--pr_rec_kandoouser RECORD LIKE kandoouser.*, 
	--pr_company RECORD LIKE company.*, 
	DEFINE query_text STRING 
	--print_option CHAR(1), 
	-- file_name CHAR(30), 
	-- default_file CHAR(30), 
	-- pr_printcodes RECORD LIKE printcodes.*, 
	--line1, line2 CHAR(80), 
	--offset1, offset2 SMALLINT, 
	--rpt_note LIKE rmsreps.report_text, 
	--rpt_wid LIKE rmsreps.report_width_num, 
	--rpt_length LIKE rmsreps.page_length_num, 
	--rpt_pageno LIKE rmsreps.page_num, 
	--rpt_time CHAR(8), 
	--rpt_date DATE, 
	DEFINE where_part STRING 
--	pr_output CHAR(20) 
END GLOBALS 
###########################################################################
# MAIN
#
# LA2 Shipment Monitoring Detail Report FOR Credits
###########################################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("LA5_main") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	CREATE temp TABLE t_costs ( 
	res_code CHAR(8), 
	dist_amt DECIMAL(16,2) 
	) with no LOG 

	CALL LA5_main() 

END MAIN 
###########################################################################
# END MAIN
###########################################################################


###########################################################################
# FUNCTION LA5_main() 
#
# 
###########################################################################
FUNCTION LA5_main() 
	CLEAR screen 

	OPEN WINDOW wl163 with FORM "L163" 
	CALL windecoration_l("L163") -- albo kd-763 

	MENU " Credit Shipment Detail Report" 

		ON ACTION "WEB-HELP" -- albo kd-375 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Run" " SELECT criteria AND PRINT REPORT" 
			CALL LA5_rpt_query() 

		ON ACTION "Print"			#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
			CALL run_prog('URS','','','','') 

		COMMAND "Exit" " Exit TO menus" 
			EXIT MENU 

	END MENU 

	CLOSE WINDOW wl163 
	CLEAR screen 
END FUNCTION 
###########################################################################
# END FUNCTION LA5_main() 
###########################################################################


###########################################################################
# FUNCTION LA5_rpt_query() 
#
# 
###########################################################################
FUNCTION LA5_rpt_query() 
	DEFINE l_rpt_idx SMALLINT  #report array index
	DEFINE 
	exist SMALLINT, 
	pr_shipdetl RECORD LIKE shipdetl.*, 
	pr_shiphead RECORD LIKE shiphead.* 

	LET msgresp = kandoomsg("U","1001","")	#U1001 " Enter criteria FOR selection - ESC TO begin search"

	CONSTRUCT BY NAME where_part ON 
	shiphead.vend_code, 
	customer.name_text, 
	shiphead.ship_code, 
	shiphead.ship_type_code, 
	shiphead.ship_status_code, 
	shiphead.ware_code, 
	shipdetl.part_code, 
	shipdetl.desc_text, 
	shiphead.eta_curr_date 

		ON ACTION "WEB-HELP" -- albo kd-375 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (where_part IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"LA5_rpt_list",where_part, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT LA5_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET where_part = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------


	LET query_text = 
	"SELECT shiphead.*, shipdetl.* ", 
	"FROM shiphead, customer, shipdetl, warehouse, shipstatus ", 
	"WHERE shiphead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	"shiphead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	"customer.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	"warehouse.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	"shipstatus.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	"customer.cust_code = shiphead.vend_code AND ", 
	"shipdetl.ship_code = shiphead.ship_code AND ", 
	"warehouse.ware_code = shiphead.ware_code AND ", 
	"shipstatus.ship_status_code = shiphead.ship_status_code AND ", 
	" shiphead.ship_type_ind in (3) AND ", 
	where_part clipped, 
	" ORDER BY shiphead.vend_code, shiphead.ship_code, shipdetl.line_num" 
	PREPARE choice FROM query_text 
	DECLARE selcurs CURSOR FOR choice 


	FOREACH selcurs INTO pr_shiphead.*, pr_shipdetl.*

		#---------------------------------------------------------
		OUTPUT TO REPORT LA5_rpt_list(l_rpt_idx,	 
		pr_shiphead.*, pr_shipdetl.*) 
		#---------------------------------------------------------
		#DISPLAY " Shipment: ", pr_shipdetl.ship_code at 1,5		attribute (yellow) 
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT LA5_rpt_list
	CALL rpt_finish("LA5_rpt_list")
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
# END FUNCTION LA5_rpt_query() 
###########################################################################


###########################################################################
# REPORT LA5_rpt_list(p_rpt_idx,pr_shiphead,pr_shipdetl)
#
# 
###########################################################################
REPORT LA5_rpt_list(p_rpt_idx,pr_shiphead,pr_shipdetl)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE 
	pr_shipdetl RECORD LIKE shipdetl.*, 
	pr_shiphead RECORD LIKE shiphead.*, 
	pr_voucherdist RECORD LIKE voucherdist.*, 
	pr_debitdist RECORD LIKE debitdist.*, 
	pr_shipcosttype RECORD LIKE shipcosttype.*, 
	fob_ent_base_amt LIKE shiphead.fob_inv_cost_amt, 
	cmpy_head CHAR(132), 
	status_desc_text LIKE shipstatus.desc_text, 
	vend_name_text LIKE vendor.name_text, 
	ware_desc_text LIKE warehouse.desc_text, 
	pr_cost_amt LIKE voucherdist.dist_amt, 
	pr_dist_amt LIKE voucherdist.dist_amt, 
	pr_conv_qty LIKE voucher.conv_qty, 
	s, len, col2, col SMALLINT 

	OUTPUT 

	ORDER external BY pr_shiphead.vend_code, pr_shiphead.ship_code, 
	pr_shipdetl.line_num 
	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			
			PRINT COLUMN 1, "Line", 
			COLUMN 9, "Line Details", 
			COLUMN 39, "Quantity", 
			COLUMN 49, "------- FOB Cost --------", 
			COLUMN 75, "------ Duty/Tax -----", 
			COLUMN 97, "----- Credit Value -----" 
			PRINT COLUMN 1, " # ", 
			COLUMN 54, "Unit", 
			COLUMN 67, "Total", 
			COLUMN 79, "Unit", 
			COLUMN 89, "Total", 
			COLUMN 101, "Unit", 
			COLUMN 115, "Total" 

			PRINT COLUMN 1, "----------------------------------------", 
			"-----------------------", 
			pr_shiphead.curr_code, "----------", 
			pr_shiphead.curr_code, "-", 
			"----------------------------------------", 
			"------------" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		ON EVERY ROW 
			CASE 
				WHEN pr_shipdetl.part_code IS NOT NULL 
					PRINT COLUMN 1, pr_shipdetl.line_num USING "###", 
					COLUMN 6, pr_shipdetl.part_code, 
					COLUMN 39, pr_shipdetl.ship_inv_qty USING "######.##", 
					COLUMN 49, pr_shipdetl.fob_unit_ent_amt USING "--------.&&", 
					COLUMN 61, pr_shipdetl.fob_ext_ent_amt USING "----------.&&", 
					COLUMN 75, pr_shipdetl.duty_unit_ent_amt USING "-------.&&", 
					COLUMN 86, pr_shipdetl.duty_unit_ent_amt USING "-------.&&", 
					COLUMN 97, pr_shipdetl.landed_cost USING "--------.&&", 
					COLUMN 109, pr_shipdetl.ext_landed_cost USING "----------.&&" 
				WHEN pr_shipdetl.job_code IS NOT NULL 
					PRINT COLUMN 1, pr_shipdetl.line_num USING "###", 
					COLUMN 6, pr_shipdetl.job_code, 
					COLUMN 18, pr_shipdetl.var_code USING "####", 
					COLUMN 23, pr_shipdetl.activity_code, 
					COLUMN 39, pr_shipdetl.ship_inv_qty USING "######.##", 
					COLUMN 49, pr_shipdetl.fob_unit_ent_amt USING "--------.&&", 
					COLUMN 61, pr_shipdetl.fob_ext_ent_amt USING "----------.&&", 
					COLUMN 75, pr_shipdetl.duty_unit_ent_amt USING "-------.&&", 
					COLUMN 86, pr_shipdetl.duty_unit_ent_amt USING "-------.&&", 
					COLUMN 97, pr_shipdetl.landed_cost USING "--------.&&", 
					COLUMN 109, pr_shipdetl.ext_landed_cost USING "----------.&&" 
				OTHERWISE 
					PRINT COLUMN 1, pr_shipdetl.line_num USING "###", 
					COLUMN 6, pr_shipdetl.desc_text, 
					COLUMN 39, pr_shipdetl.ship_inv_qty USING "######.##", 
					COLUMN 49, pr_shipdetl.fob_unit_ent_amt USING "--------.&&", 
					COLUMN 61, pr_shipdetl.fob_ext_ent_amt USING "----------.&&", 
					COLUMN 75, pr_shipdetl.duty_unit_ent_amt USING "-------.&&", 
					COLUMN 86, pr_shipdetl.duty_unit_ent_amt USING "-------.&&", 
					COLUMN 97, pr_shipdetl.landed_cost USING "--------.&&", 
					COLUMN 109, pr_shipdetl.ext_landed_cost USING "----------.&&" 
			END CASE 
			


		BEFORE GROUP OF pr_shiphead.ship_code 
			SKIP TO top OF PAGE 
			SELECT desc_text INTO status_desc_text 
			FROM shipstatus 
			WHERE cmpy_code = pr_shiphead.cmpy_code 
			AND ship_status_code = pr_shiphead.ship_status_code 

			SELECT name_text 
			INTO vend_name_text 
			FROM customer 
			WHERE cmpy_code = pr_shiphead.cmpy_code 
			AND cust_code = pr_shiphead.vend_code 
			SELECT desc_text 
			INTO ware_desc_text 
			FROM warehouse 
			WHERE cmpy_code = pr_shiphead.cmpy_code 
			AND ware_code = pr_shiphead.ware_code 

			PRINT COLUMN 1, "Customer: ",pr_shiphead.vend_code, 
			COLUMN 20, vend_name_text clipped 
			IF pr_shiphead.finalised_flag = "Y" THEN 
				PRINT COLUMN 4, "Shipment ID: ", pr_shipdetl.ship_code, 
				COLUMN 26, pr_shiphead.ship_type_code, 
				COLUMN 32, "Status: ", status_desc_text, 
				COLUMN 63, "E.T.A: ",pr_shiphead.eta_curr_date USING "dd/mm/yy", 
				COLUMN 120, "Finalised" 
			ELSE 
				PRINT COLUMN 4, "Shipment ID: ", pr_shipdetl.ship_code, 
				COLUMN 26, pr_shiphead.ship_type_code, 
				COLUMN 32, "Status: ", status_desc_text, 
				COLUMN 63, "E.T.A: ",pr_shiphead.eta_curr_date USING "dd/mm/yy", 
				COLUMN 120, "Not Final" 
			END IF 
			PRINT COLUMN 32, "Comments:: ", pr_shiphead.com1_text, 
			" ", pr_shiphead.com2_text 
			PRINT COLUMN 32, "Warehouse: ", ware_desc_text, 
			COLUMN 76, "Conversion Rate: ", 
			pr_shiphead.conversion_qty USING "####&.&&&&" 
			SKIP 1 line 


		AFTER GROUP OF pr_shiphead.ship_code 
			PRINT COLUMN 61, "-------------", 
			COLUMN 86, "----------", 
			COLUMN 109, "-------------" 
			PRINT COLUMN 61, GROUP sum (pr_shipdetl.fob_ext_ent_amt) 
			USING "----------.&&", 
			COLUMN 86, GROUP sum (pr_shipdetl.duty_ext_ent_amt) 
			USING "-------.&&", 
			COLUMN 109, GROUP sum (pr_shipdetl.ext_landed_cost) 
			USING "----------.&&" 

			DECLARE c_voucherdist CURSOR FOR 
			SELECT * FROM voucherdist 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND job_code = pr_shiphead.ship_code 
			AND type_ind = 'S' 
			FOREACH c_voucherdist INTO pr_voucherdist.* 
				SELECT conv_qty INTO pr_conv_qty 
				FROM voucher 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND vend_code = pr_voucherdist.vend_code 
				AND vouch_code = pr_voucherdist.vouch_code 
				UPDATE t_costs 
				SET dist_amt = dist_amt 
				+ ( pr_voucherdist.dist_amt / pr_conv_qty ) 
				WHERE res_code = pr_voucherdist.res_code 
				IF sqlca.sqlerrd[3] = 0 THEN 
					LET pr_dist_amt = pr_voucherdist.dist_amt / pr_conv_qty 
					INSERT INTO t_costs VALUES (pr_voucherdist.res_code, 
					pr_dist_amt ) 
				END IF 
			END FOREACH 

			DECLARE c_debitdist CURSOR FOR 
			SELECT * FROM debitdist 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND job_code = pr_shiphead.ship_code 
			AND type_ind = 'S' 
			FOREACH c_debitdist INTO pr_debitdist.* 
				SELECT conv_qty INTO pr_conv_qty 
				FROM debithead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND vend_code = pr_debitdist.vend_code 
				AND debit_num = pr_debitdist.debit_code 
				UPDATE t_costs 
				SET dist_amt = dist_amt 
				- ( pr_debitdist.dist_amt / pr_conv_qty ) 
				WHERE res_code = pr_debitdist.res_code 
				IF sqlca.sqlerrd[3] = 0 THEN 
					LET pr_dist_amt = 0 - (pr_debitdist.dist_amt / pr_conv_qty ) 
					INSERT INTO t_costs VALUES (pr_debitdist.res_code, 
					pr_dist_amt ) 
				END IF 
			END FOREACH 

			SELECT unique 1 FROM t_costs 
			WHERE 1 = 1 
			IF status != notfound THEN 
				SKIP 2 LINES 
				DECLARE c_t_costs CURSOR FOR 
				SELECT shipcosttype.desc_text, dist_amt 
				FROM t_costs, shipcosttype 
				WHERE shipcosttype.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND t_costs.res_code = shipcosttype.cost_type_code 

				FOREACH c_t_costs INTO pr_shipcosttype.desc_text, 
					pr_cost_amt 
					NEED 2 LINES 
					PRINT COLUMN 5, pr_shipcosttype.desc_text, 
					COLUMN 61, pr_cost_amt USING "----------.&&" 
				END FOREACH 
				DELETE FROM t_costs 
				WHERE 1=1 
			END IF 

		ON LAST ROW 
			SKIP 3 line 
			PRINT COLUMN 10, "Report Totals: Lines: ", count(*) USING "###" 
			SKIP 5 LINES 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4]
 				
			
END REPORT 
###########################################################################
# END REPORT LA5_rpt_list(p_rpt_idx,pr_shiphead,pr_shipdetl)
###########################################################################