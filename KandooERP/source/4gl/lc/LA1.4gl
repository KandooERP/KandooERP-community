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
GLOBALS "../lc/LA1_GLOBALS.4gl"
GLOBALS 
--	DEFINE pr_company RECORD LIKE company.* 
--	DEFINE rpt_note LIKE rmsreps.report_text 
--	DEFINE rpt_wid LIKE rmsreps.report_width_num 
--	DEFINE rpt_length LIKE rmsreps.page_length_num 
--	DEFINE rpt_pageno LIKE rmsreps.page_num 
	DEFINE query_text STRING 
	DEFINE where_text STRING 
END GLOBALS 
###########################################################################
# MAIN
#
# LA1 Shipment Monitoring Detail Report
###########################################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("LA1") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	OPEN WINDOW l102 with FORM "L102" 
	CALL windecoration_l("L102") -- albo kd-763 

	CREATE temp TABLE t_costs ( 
	res_code CHAR(8), 
	dist_amt DECIMAL(16,2) 
	) with no LOG 

	MENU " Shipment Detail Report" 

		ON ACTION "WEB-HELP" -- albo kd-375 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Run" " SELECT criteria AND PRINT REPORT" 
			IF la1_query() THEN 
				NEXT option "Print Manager" 
			END IF 

		ON ACTION "Print Manager"			#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
			CALL run_prog("URS","","","","") 


		COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus" 
			EXIT MENU 
	END MENU 

	CLOSE WINDOW l102 
END MAIN 
###########################################################################
# END MAIN
###########################################################################


###########################################################################
# FUNCTION la1_query()
#
# 
###########################################################################
FUNCTION la1_query()
	DEFINE l_rpt_idx SMALLINT  #report array index 
	DEFINE 
	pr_shipdetl RECORD LIKE shipdetl.*, 
	pr_shiphead RECORD LIKE shiphead.*, 
	pr_output CHAR(20) 

	LET msgresp =kandoomsg("U","1001","") #U1001 " Enter Selection Criteria - ESC TO Continue"
	CONSTRUCT BY NAME where_text ON shiphead.vend_code, 
	shiphead.ship_code, 
	shiphead.ship_type_code, 
	vendor.name_text, 
	shiphead.eta_curr_date, 
	shiphead.vessel_text, 
	shiphead.discharge_text, 
	shiphead.ship_status_code, 
	shiphead.conversion_qty, 
	shiphead.ware_code, 
	shipdetl.part_code, 
	shipdetl.source_doc_num, 
	shipdetl.ship_inv_qty, 
	shipdetl.fob_unit_ent_amt, 
	shipdetl.tariff_code, 
	shipdetl.duty_unit_ent_amt 

		ON ACTION "WEB-HELP" -- albo kd-375 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"LA1_rpt_list",where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT LA1_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------


	LET query_text = "SELECT shiphead.*,", 
	"shipdetl.* ", 
	"FROM shiphead,", 
	"vendor,", 
	"shipdetl ", 
	"WHERE shiphead.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND shipdetl.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND vendor.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND vendor.vend_code = shiphead.vend_code ", 
	"AND shipdetl.ship_code = shiphead.ship_code ", 
	"AND shiphead.ship_type_ind in (1,2) ", 
	"AND ",where_text clipped," ", 
	"ORDER BY shiphead.vend_code,", 
	"shiphead.ship_code,", 
	"shipdetl.line_num" 
	PREPARE s_shiphead FROM query_text 
	 
	DECLARE c_shiphead CURSOR FOR s_shiphead 
	FOREACH c_shiphead INTO pr_shiphead.*, pr_shipdetl.* 

		#---------------------------------------------------------
		OUTPUT TO REPORT M18_rpt_list_replace(l_rpt_idx,
		pr_shiphead.*, pr_shipdetl.*)
		#---------------------------------------------------------
		#DISPLAY pr_shipdetl.ship_code at 1,16 attribute (yellow) 
	END FOREACH 
	--   CLOSE WINDOW w1_LA2    -- albo  KD-763
	
	#------------------------------------------------------------
	FINISH REPORT LA1_rpt_list
	CALL rpt_finish("LA1_rpt_list")
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
# END FUNCTION la1_query()
###########################################################################


###########################################################################
# REPORT LA1_rpt_list(p_rpt_idx,pr_shiphead,pr_shipdetl)
#
# 
###########################################################################
REPORT LA1_rpt_list(p_rpt_idx,pr_shiphead,pr_shipdetl) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE 
	pr_shiphead RECORD LIKE shiphead.*, 
	pr_shipdetl RECORD LIKE shipdetl.*, 
	pr_voucherdist RECORD LIKE voucherdist.*, 
	pr_debitdist RECORD LIKE debitdist.*, 
	pr_shiprec RECORD LIKE shiprec.*, 
	pr_shipcosttype RECORD LIKE shipcosttype.*, 
	pr_costs RECORD 
		dist_amt LIKE voucherdist.dist_amt, 
		res_code LIKE voucherdist.res_code 
	END RECORD, 
	pr_status_desc_text LIKE shipstatus.desc_text, 
	pr_vend_name_text LIKE vendor.name_text, 
	pr_ware_desc_text LIKE warehouse.desc_text, 
	pr_part_code LIKE shipdetl.part_code, 
	pr_currency LIKE voucher.currency_code, 
	pr_date LIKE voucher.vouch_date, 
	pr_rec_qty LIKE shiprec.trans_qty, 
	pr_rec_amt LIKE shiprec.trans_amt, 
	pr_cost_amt LIKE voucherdist.dist_amt, 
	pr_dist_amt LIKE voucherdist.dist_amt, 
	pr_conv_qty LIKE voucher.conv_qty, 
	final_text CHAR(13), 
	cmpy_head CHAR(132), 
	col2, col SMALLINT 


	OUTPUT 

	ORDER external BY pr_shiphead.vend_code, 
	pr_shiphead.ship_code, 
	pr_shipdetl.line_num 
	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
		
			PRINT COLUMN 1, "Line", 
			COLUMN 9, "Purchase", 
			COLUMN 20, "Line Details", 
			COLUMN 39, "------- Qty -------", 
			COLUMN 59, "------- FOB Cost --------", 
			COLUMN 85, "------ Duty/Tax ------", 
			COLUMN 108, "Tariff ", 
			COLUMN 120, "Landed Cost" 
			IF pr_shiphead.finalised_flag = "Y" THEN 
				LET final_text = " Final" 
			ELSE 
				LET final_text = "Not Finalised" 
			END IF 
			PRINT COLUMN 1, " # ", 
			COLUMN 9, " # Line", 
			COLUMN 39, "Entered", 
			COLUMN 50, "Received", 
			COLUMN 63, "Unit", 
			COLUMN 76, "Total", 
			COLUMN 88, "Unit", 
			COLUMN 98, "Total", 
			COLUMN 109, "Code", 
			COLUMN 119, final_text 
			PRINT COLUMN 1, "----------------------------------------", 
			"-----------------------", 
			pr_shiphead.curr_code, "----------", 
			pr_shiphead.curr_code, "-", 
			"----------------------------------------", 
			"-----------" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

		BEFORE GROUP OF pr_shiphead.ship_code 
			SKIP TO top OF PAGE 
			SELECT desc_text INTO pr_status_desc_text FROM shipstatus 
			WHERE cmpy_code = pr_shiphead.cmpy_code 
			AND ship_status_code = pr_shiphead.ship_status_code 
			SELECT name_text INTO pr_vend_name_text FROM vendor 
			WHERE cmpy_code = pr_shiphead.cmpy_code 
			AND vend_code = pr_shiphead.vend_code 
			SELECT desc_text INTO pr_ware_desc_text FROM warehouse 
			WHERE cmpy_code = pr_shiphead.cmpy_code 
			AND ware_code = pr_shiphead.ware_code 
			PRINT COLUMN 1, "Vendor: ",pr_shiphead.vend_code, 
			COLUMN 15, pr_vend_name_text clipped 
			PRINT COLUMN 4, "Shipment ID: ", pr_shipdetl.ship_code, 
			COLUMN 26, pr_shiphead.ship_type_code, 
			COLUMN 32, "Status: ", pr_status_desc_text 
			PRINT COLUMN 32, "Ship: ", pr_shiphead.vessel_text, 
			COLUMN 63, "E.T.A: ",pr_shiphead.eta_curr_date USING "dd/mm/yy", 
			COLUMN 86, "Port of Discharge: ", pr_shiphead.discharge_text 
			PRINT COLUMN 32, "BL/AWB: ", pr_shiphead.bl_awb_text, 
			COLUMN 59, "L/C: ", pr_shiphead.lc_ref_text, 
			COLUMN 86, "Cases: ", pr_shiphead.case_num USING "#####", 
			COLUMN 100, "Container: ", pr_shiphead.container_text 
			PRINT COLUMN 32, "Warehouse: ", pr_ware_desc_text, 
			COLUMN 76, "Conversion Rate: ", 
			pr_shiphead.conversion_qty USING "####&.&&&&", 
			COLUMN 105, "Sales Tax Paid: ", pr_shiphead.tax_paid_flag 
			SKIP 1 line 

		ON EVERY ROW 
			SELECT sum(trans_qty), sum(trans_amt) 
			INTO pr_rec_qty, pr_rec_amt 
			FROM shiprec 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND line_num = pr_shipdetl.line_num 
			AND ship_code = pr_shiphead.ship_code 
			IF status = notfound THEN 
				LET pr_rec_qty = 0 
				LET pr_rec_amt = 0 
			END IF 
			IF pr_rec_qty IS NULL THEN 
				LET pr_rec_qty = 0 
			END IF 
			IF pr_rec_amt IS NULL THEN 
				LET pr_rec_amt = 0 
			END IF 
			IF pr_shipdetl.fob_unit_ent_amt = 0 THEN 
				LET pr_shipdetl.ship_rec_qty = pr_rec_qty 
			ELSE 
				LET pr_shipdetl.ship_rec_qty = pr_rec_qty + 
				(pr_rec_amt / pr_shipdetl.fob_unit_ent_amt) 
			END IF 
			PRINT COLUMN 1, pr_shipdetl.line_num USING "###", 
			COLUMN 5, pr_shipdetl.source_doc_num USING "########", 
			COLUMN 14, pr_shipdetl.doc_line_num USING "###", 
			COLUMN 39, pr_shipdetl.ship_inv_qty USING "######.##", 
			COLUMN 49, pr_shipdetl.ship_rec_qty USING "######.##", 
			COLUMN 59, pr_shipdetl.fob_unit_ent_amt USING "--------.&&", 
			COLUMN 71, pr_shipdetl.fob_ext_ent_amt USING "----------.&&", 
			COLUMN 85, pr_shipdetl.duty_unit_ent_amt USING "-------.&&", 
			COLUMN 96, pr_shipdetl.duty_ext_ent_amt USING "-------.&&", 
			COLUMN 107, pr_shipdetl.tariff_code, 
			COLUMN 120, pr_shipdetl.landed_cost USING "--------.&&" 
			CASE 
				WHEN pr_shipdetl.part_code IS NOT NULL 
					PRINT COLUMN 18, pr_shipdetl.part_code 
				WHEN pr_shipdetl.job_code IS NOT NULL 
					PRINT COLUMN 18, pr_shipdetl.job_code, 
					COLUMN 28, pr_shipdetl.var_code USING "####", 
					COLUMN 33, pr_shipdetl.activity_code 
				OTHERWISE 
					PRINT COLUMN 18, pr_shipdetl.desc_text 
			END CASE 

		AFTER GROUP OF pr_shiphead.ship_code 
			NEED 4 LINES 
			PRINT COLUMN 71, "-------------", 
			COLUMN 96, "----------" 
			PRINT COLUMN 71, GROUP sum (pr_shipdetl.fob_ext_ent_amt) 
			USING "----------.&&", 
			COLUMN 96, GROUP sum (pr_shipdetl.duty_ext_ent_amt) 
			USING "-------.&&" 
			SKIP 1 line 

			NEED 4 LINES 
			PRINT COLUMN 5, "Unit FOB Cost & Duty Invoiced:", 
			COLUMN 71, pr_shiphead.fob_inv_cost_amt USING "----------.&&", 
			COLUMN 96, pr_shiphead.duty_inv_amt USING "-------.&&" 
			PRINT COLUMN 7, "Base Currency" 
			SKIP 1 line 


			SELECT unique 1 FROM shiprec 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ship_code = pr_shiphead.ship_code 
			IF status != notfound THEN 
				NEED 5 LINES 
				PRINT COLUMN 5, "Receipt No", 
				COLUMN 17, "Line", 
				COLUMN 23, "Details", 
				COLUMN 59, "Quantity", 
				COLUMN 75, "Amount" 
				PRINT COLUMN 5, "---------------------------------------", 
				"----------------------------------------" 
				DECLARE c_shiprec CURSOR FOR 
				SELECT * FROM shiprec 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ship_code = pr_shiphead.ship_code 
				FOREACH c_shiprec INTO pr_shiprec.* 
					LET pr_part_code = NULL 
					SELECT part_code INTO pr_part_code FROM shipdetl 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND ship_code = pr_shiprec.ship_code 
					AND line_num = pr_shiprec.line_num 
					PRINT COLUMN 5, pr_shiprec.goods_receipt_text, 
					COLUMN 17, pr_shiprec.line_num USING "###", 
					COLUMN 23, pr_part_code, 
					COLUMN 40, pr_shiprec.recpt_date USING "dd/mm/yy", 
					COLUMN 59, pr_shiprec.trans_qty USING "-------&.&&", 
					COLUMN 71, pr_shiprec.trans_amt USING "---------&.&&" 
				END FOREACH 
				SKIP 1 line 
			END IF 

			SELECT unique 1 FROM voucherdist 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND job_code = pr_shiphead.ship_code 
			AND type_ind = 'S' 
			IF status != notfound THEN 
				NEED 5 LINES 
				PRINT COLUMN 5, "Voucher No", 
				COLUMN 17, "Line", 
				COLUMN 23, "Cost Type", 
				COLUMN 34, "Account Code", 
				COLUMN 48, "Vendor", 
				COLUMN 59, "Voucher Date", 
				COLUMN 75, "Amount" 
				PRINT COLUMN 5, "----------------------------------------", 
				"---------------------------------------" 
				DECLARE c_voucherdist CURSOR FOR 
				SELECT * FROM voucherdist 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND job_code = pr_shiphead.ship_code 
				AND type_ind = 'S' 
				FOREACH c_voucherdist INTO pr_voucherdist.* 

					LET pr_currency = NULL 
					LET pr_date = NULL 

					SELECT vouch_date, currency_code, conv_qty 
					INTO pr_date, pr_currency, pr_conv_qty 
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

					PRINT COLUMN 5, pr_voucherdist.vouch_code USING "#######&", 
					COLUMN 17, pr_voucherdist.line_num USING "###", 
					COLUMN 23, pr_voucherdist.res_code, 
					COLUMN 34, pr_voucherdist.acct_code, 
					COLUMN 48, pr_voucherdist.vend_code, 
					COLUMN 62, pr_date USING "dd/mm/yy", 
					COLUMN 71, pr_voucherdist.dist_amt USING "---------&.&&", 
					COLUMN 85, pr_currency 
				END FOREACH 
				SKIP 1 line 
			END IF 

			SELECT unique 1 FROM debitdist 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND job_code = pr_shiphead.ship_code 
			AND type_ind = 'S' 
			IF status != notfound THEN 
				NEED 5 LINES 
				PRINT COLUMN 5, "Debit Code", 
				COLUMN 17, "Line", 
				COLUMN 23, "Cost Type", 
				COLUMN 34, "Account Code", 
				COLUMN 75, "Amount" 
				PRINT COLUMN 5, "----------------------------------------", 
				"---------------------------------------" 
				DECLARE c_debitdist CURSOR FOR 
				SELECT * FROM debitdist 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND job_code = pr_shiphead.ship_code 
				AND type_ind = 'S' 
				FOREACH c_debitdist INTO pr_debitdist.* 

					LET pr_currency = NULL 
					LET pr_date = NULL 
					SELECT debit_date, currency_code, conv_qty 
					INTO pr_date, pr_currency, pr_conv_qty 
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
					PRINT COLUMN 5, pr_debitdist.debit_code USING "#######&", 
					COLUMN 17, pr_debitdist.line_num USING "###", 
					COLUMN 23, pr_debitdist.res_code, 
					COLUMN 34, pr_debitdist.acct_code, 
					COLUMN 48, pr_debitdist.vend_code, 
					COLUMN 62, pr_date USING "dd/mm/yy", 
					COLUMN 71, pr_debitdist.dist_amt USING "---------&.&&", 
					COLUMN 85, pr_currency 
				END FOREACH 
				SKIP 1 line 
			END IF 

			SELECT unique 1 FROM t_costs 
			WHERE 1 = 1 
			IF status != notfound THEN 
				DECLARE c_t_costs CURSOR FOR 
				SELECT shipcosttype.desc_text, dist_amt 
				FROM t_costs, shipcosttype 
				WHERE shipcosttype.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND t_costs.res_code = shipcosttype.cost_type_code 

				FOREACH c_t_costs INTO pr_shipcosttype.desc_text, 
					pr_cost_amt 
					NEED 2 LINES 
					PRINT COLUMN 5, pr_shipcosttype.desc_text, 
					COLUMN 71, pr_cost_amt USING "----------.&&" 
				END FOREACH 
				DELETE FROM t_costs 
				WHERE 1 = 1 
				SKIP 1 line 
			END IF 


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
# END REPORT LA1_rpt_list(p_rpt_idx,pr_shiphead,pr_shipdetl)
###########################################################################