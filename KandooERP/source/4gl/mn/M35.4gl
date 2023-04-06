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
GLOBALS "../mn/M_MN_GLOBALS.4gl"
GLOBALS "../mn/M3_GROUP_GLOBALS.4gl" 
GLOBALS "../mn/M35_GLOBALS.4gl"

GLOBALS 

	DEFINE 
	formname CHAR(15), 
	pr_output CHAR(60), 
	pv_where_text CHAR(1000), 
	pv_pageno SMALLINT, 
	fr_shopordhead RECORD LIKE shopordhead.*, 
	fr_shoporddetl RECORD LIKE shoporddetl.*, 
	pr_menunames RECORD LIKE menunames.*, 
	pr_mnparms RECORD LIKE mnparms.*, 
	pr_inparms RECORD LIKE inparms.* 

END GLOBALS 
############################################################
# MAIN
#
# Shop Order Listing
############################################################
MAIN 

	#Initial UI Init
	CALL setModuleId("M35") -- albo 
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
		LET msgresp = kandoomsg("M", 7500, "") 
		# prompt "Manufacturing parameters are NOT SET up - Any key TO continue"
		EXIT program 
	END IF 

	SELECT * 
	INTO pr_inparms.* 
	FROM inparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = 1 

	IF status = notfound THEN 
		LET msgresp = kandoomsg("M", 7501, "") 
		# prompt "Inventory parameters are NOT SET up - Any key TO continue"
		EXIT program 
	END IF 

	OPEN WINDOW w1_m179 with FORM "M179" 
	CALL  windecoration_m("M179") -- albo kd-762 

	CALL kandoomenu("M", 159) RETURNING pr_menunames.* 
	MENU pr_menunames.menu_text # shop ORDER listing 

		COMMAND pr_menunames.cmd1_code pr_menunames.cmd1_text # REPORT 
			IF report_main() THEN 
				NEXT option pr_menunames.cmd3_code # PRINT 
			END IF 

		ON ACTION "Print Manager" 	#command pr_menunames.cmd3_code pr_menunames.cmd3_text # Print
			CALL run_prog("URS", "", "", "", "") 
			NEXT option pr_menunames.cmd4_code # EXIT 

		COMMAND pr_menunames.cmd4_code pr_menunames.cmd4_text #exit 
			EXIT MENU 

		COMMAND KEY(interrupt) 
			EXIT MENU 
	END MENU 

	CLOSE WINDOW w1_m179 

END MAIN 
############################################################
# END MAIN
############################################################


############################################################
# FUNCTION report_main() 
#
# 
############################################################
FUNCTION report_main() 
	DEFINE l_rpt_idx SMALLINT  #report array index
	DEFINE 
	fv_query_text CHAR (1000) 


	LET msgresp = kandoomsg("M", 1500, "") 
	# MESSAGE "Enter selection criteria - ESC TO Accept, DEL TO Exit"

	CONSTRUCT pv_where_text 
	ON shopordhead.shop_order_num, 
	shopordhead.suffix_num, 
	shopordhead.cust_code, 
	shopordhead.part_code, 
	shopordhead.order_type_ind, 
	shopordhead.status_ind, 
	shopordhead.start_date, 
	shopordhead.end_date 
	FROM shop_order_num, 
	suffix_num, 
	cust_code, 
	product, 
	order_type_ind, 
	status_ind, 
	start_date, 
	end_date 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET msgresp = kandoomsg("M", 9555, "") 
		# ERROR "Query aborted"
		RETURN false 
	END IF 

	LET fv_query_text = "SELECT * FROM shopordhead WHERE ", 
	pv_where_text clipped 

	PREPARE statement1 FROM fv_query_text 
	DECLARE ts_cur CURSOR FOR statement1 

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"M35_rpt_list_shopord","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT M35_rpt_list_shopord TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------
	#output is done in a function
	FOREACH ts_cur INTO fr_shopordhead.* 
		CALL child_process(l_rpt_idx) 
	END FOREACH 
	#------------------------------------------------------------

	#------------------------------------------------------------
	FINISH REPORT M35_rpt_list_shopord
	CALL rpt_finish("M35_rpt_list_shopord")
	#------------------------------------------------------------

	RETURN true 

END FUNCTION 
############################################################
# END FUNCTION report_main() 
#
# 
############################################################


############################################################
# FUNCTION child_process() 
#
# 
############################################################
FUNCTION child_process(p_rpt_idx) 
	DEFINE p_rpt_idx SMALLINT  #report array index
	DEFINE 
	fv_query_txt2 CHAR(2000) 


	LET fv_query_txt2 = "SELECT * ", 
	"FROM shoporddetl ", 
	"WHERE cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	"AND shop_order_num = ", 
	fr_shopordhead.shop_order_num, " ", 
	"AND suffix_num = ", fr_shopordhead.suffix_num 

	PREPARE statement2 FROM fv_query_txt2 
	DECLARE ts_curs CURSOR FOR statement2 

	FOREACH ts_curs INTO fr_shoporddetl.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT M35_rpt_list_shopord(p_rpt_idx,
		fr_shoporddetl.*) 
		#---------------------------------------------------------
	END FOREACH 

END FUNCTION 
############################################################
# END FUNCTION child_process() 
############################################################


############################################################
# REPORT M35_rpt_list_shopord(p_rpt_idx,rr_shoporddetl)
#
# 
############################################################
REPORT M35_rpt_list_shopord(p_rpt_idx,rr_shoporddetl) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE 
	rv_name_text LIKE customer.name_text, 
	rv_desc_text LIKE product.desc_text, 
	rv_hdesc_text LIKE product.desc_text, 
	rv_cost LIKE shoporddetl.std_wgted_cost_amt, 
	rv_price LIKE shoporddetl.std_wgted_cost_amt, 
	rv_act_cost LIKE wipreceipt.cost_amt, 
	rv_act_price LIKE wipreceipt.price_amt, 
	rv_required_time LIKE wipreceipt.receipt_qty, 
	rv_completed_time LIKE wipreceipt.receipt_qty, 
	rv_est LIKE shoporddetl.std_wgted_cost_amt, 
	rv_act LIKE shoporddetl.std_wgted_cost_amt, 
	rv_prev_shop_ord_num LIKE shoporddetl.shop_order_num, 
	rv_temp_note_code LIKE notes.note_code, 
	rv_shop_ord_est_tot_cst LIKE shoporddetl.std_wgted_cost_amt, 
	rv_shop_ord_act_tot_cst LIKE shoporddetl.std_wgted_cost_amt, 
	rv_shop_ord_est_tot_prc LIKE shoporddetl.std_wgted_cost_amt, 
	rv_shop_ord_act_tot_prc LIKE shoporddetl.std_wgted_cost_amt, 
	rv_material_est_tot_cst LIKE shoporddetl.std_wgted_cost_amt, 
	rv_material_act_tot_cst LIKE shoporddetl.std_wgted_cost_amt, 
	rv_material_est_tot_prc LIKE shoporddetl.std_wgted_cost_amt, 
	rv_material_act_tot_prc LIKE shoporddetl.std_wgted_cost_amt, 
	rv_other_mt_est_tot_cst LIKE shoporddetl.std_wgted_cost_amt, 
	rv_other_mt_act_tot_cst LIKE shoporddetl.std_wgted_cost_amt, 
	rv_other_mt_est_tot_prc LIKE shoporddetl.std_wgted_cost_amt, 
	rv_other_mt_act_tot_prc LIKE shoporddetl.std_wgted_cost_amt, 

	rr_notes RECORD LIKE notes.*, 
	rr_prodmfg RECORD LIKE prodmfg.*, 
	rr_workcentre RECORD LIKE workcentre.*, 
	rr_shopordhead2 RECORD LIKE shopordhead.*, 
	rr_shoporddetl RECORD LIKE shoporddetl.*, 

	rv_setup_qty SMALLINT, 
	rv_offset1 SMALLINT, 
	rv_cost_method_text CHAR(8), 
	rv_desc_txt CHAR(9), 
	rv_hdesc_txt CHAR(9), 
	rv_status_text CHAR(9), 
	rv_selection_text CHAR(25), 
	rv_eof_text CHAR(50), 
	rv_rpt_line1 CHAR(132), 
	rv_rpt_line2 CHAR(132), 
	rv_rpt_line3 CHAR(132), 
	rv_rpt_line4 CHAR(132) 


	OUTPUT 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
		

			PRINT COLUMN 1, "Shop Order Number: ", 
			COLUMN 19, rr_shoporddetl.shop_order_num, 
			COLUMN 36, "Suffix Number: ", 
			COLUMN 52, rr_shoporddetl.suffix_num, 
			COLUMN 75, "Customer : ", 
			COLUMN 93, fr_shopordhead.cust_code 

			LET rv_name_text = NULL 
			SELECT name_text 
			INTO rv_name_text 
			FROM customer 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = fr_shopordhead.cust_code 

			PRINT COLUMN 92, ":", 
			COLUMN 94, rv_name_text 

			SELECT desc_text 
			INTO rv_hdesc_text 
			FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = fr_shopordhead.part_code 

			PRINT COLUMN 1, "Product Code : ", 
			COLUMN 19, fr_shopordhead.part_code, 
			COLUMN 32, rv_hdesc_text, 
			COLUMN 75, "Order Type/No : ", 
			COLUMN 97, "" 

			IF pr_mnparms.ref4_ind matches "[1234]" 
			AND fr_shopordhead.user4_text IS NOT NULL THEN 
				LET rr_notes.note_text = NULL 

				IF fr_shopordhead.user4_text[1,3] = "###" THEN 
					LET rv_temp_note_code = fr_shopordhead.user4_text[4,15] 

					SELECT * 
					INTO rr_notes.* 
					FROM notes 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND note_code = rv_temp_note_code 
					AND note_num = 1 
				END IF 

				PRINT COLUMN 1, pr_mnparms.ref4_text, ": ", 
				fr_shopordhead.user4_text, " ", rr_notes.note_text 
			ELSE 
				PRINT 
			END IF 

			CASE 
				WHEN fr_shopordhead.status_ind = "C" 
					LET rv_status_text = "Completed" 
				WHEN fr_shopordhead.status_ind = "H" 
					LET rv_status_text = "Held" 
				WHEN fr_shopordhead.status_ind = "R" 
					LET rv_status_text = "Released" 
			END CASE 

			CASE 
				WHEN pr_inparms.cost_ind matches "[FW]" 
					LET rv_cost_method_text = "Weighted" 
				WHEN pr_inparms.cost_ind = "S" 
					LET rv_cost_method_text = "Standard" 
				WHEN pr_inparms.cost_ind = "L" 
					LET rv_cost_method_text = "Latest" 
			END CASE 

			PRINT COLUMN 1, "Quantity Required: ", 
			COLUMN 19, fr_shopordhead.order_qty, 
			COLUMN 36, "UOM :", 
			COLUMN 42, fr_shopordhead.uom_code, 
			COLUMN 47, "Qty Receipted :", 
			COLUMN 61, fr_shopordhead.receipted_qty USING "#######.##", 
			COLUMN 75, "Status : ", 
			COLUMN 93, rv_status_text, 
			COLUMN 106, "COGS Method : ", 
			COLUMN 117, rv_cost_method_text 

			PRINT COLUMN 1, "Start Date : ", 
			COLUMN 19, fr_shopordhead.start_date, 
			COLUMN 47, "Qty Rejected :", 
			COLUMN 61, fr_shopordhead.rejected_qty USING "#######.##", 
			COLUMN 75, "Release Date : ", 
			COLUMN 93, fr_shopordhead.release_date, 
			COLUMN 106, "Due Date : ", 
			COLUMN 119, fr_shopordhead.end_date 

			PRINT COLUMN 1, "Actual Start : ", 
			COLUMN 19, fr_shopordhead.actual_start_date, 
			COLUMN 106, "Actual END : ", 
			COLUMN 119, fr_shopordhead.actual_end_date 

			PRINT "--------------------------------------------------", 
			"-------------------------------------------------", 
			"--------------------------------" 
			#####
			# PRINT COLUMN HEADINGS
			#####

			PRINT COLUMN 3, "Product/Description", 
			COLUMN 27, "----------- Q U A N T I T Y -------------", 
			COLUMN 70, "------ T I M E -------", 
			COLUMN 101, "Est. Cost/", 
			COLUMN 122, "Act. Cost/" 

			PRINT COLUMN 5, "Work Centre", 
			COLUMN 32, "Required", 
			COLUMN 54, "Actual", 
			COLUMN 61, "W/Centre", 
			COLUMN 70, "Required", 
			COLUMN 86, "Actual", 
			COLUMN 101, "Price", 
			COLUMN 122, "Price" 

			PRINT "--------------------------------------------------", 
			"-------------------------------------------------", 
			"--------------------------------" 

		BEFORE GROUP OF rr_shoporddetl.shop_order_num 
			LET rv_shop_ord_est_tot_cst = 0 
			LET rv_shop_ord_act_tot_cst = 0 
			LET rv_shop_ord_est_tot_prc = 0 
			LET rv_shop_ord_act_tot_prc = 0 
			LET rv_material_est_tot_cst = 0 
			LET rv_material_act_tot_cst = 0 
			LET rv_material_est_tot_prc = 0 
			LET rv_material_act_tot_prc = 0 
			LET rv_other_mt_est_tot_cst = 0 
			LET rv_other_mt_act_tot_cst = 0 
			LET rv_other_mt_est_tot_prc = 0 
			LET rv_other_mt_act_tot_prc = 0 
			SKIP TO top OF PAGE 

		BEFORE GROUP OF rr_shoporddetl.suffix_num 
			IF rv_prev_shop_ord_num = rr_shoporddetl.shop_order_num THEN 
				LET rv_shop_ord_est_tot_cst = 0 
				LET rv_shop_ord_act_tot_cst = 0 
				LET rv_shop_ord_est_tot_prc = 0 
				LET rv_shop_ord_act_tot_prc = 0 
				LET rv_material_est_tot_cst = 0 
				LET rv_material_act_tot_cst = 0 
				LET rv_material_est_tot_prc = 0 
				LET rv_material_act_tot_prc = 0 
				LET rv_other_mt_est_tot_cst = 0 
				LET rv_other_mt_act_tot_cst = 0 
				LET rv_other_mt_est_tot_prc = 0 
				LET rv_other_mt_act_tot_prc = 0 
				SKIP TO top OF PAGE 
			END IF 

		ON EVERY ROW 
			CASE 
				WHEN rr_shoporddetl.type_ind matches "[CB]" 
					SELECT desc_text 
					INTO rv_desc_text 
					FROM product 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = rr_shoporddetl.part_code 

					CASE 
						WHEN pr_inparms.cost_ind matches "[FW]" 
							LET rv_est = rr_shoporddetl.std_wgted_cost_amt 
							LET rv_act = rr_shoporddetl.act_wgted_cost_amt 
						WHEN pr_inparms.cost_ind = "S" 
							LET rv_est = rr_shoporddetl.std_est_cost_amt 
							LET rv_act = rr_shoporddetl.act_est_cost_amt 
						WHEN pr_inparms.cost_ind = "L" 
							LET rv_est = rr_shoporddetl.std_act_cost_amt 
							LET rv_act = rr_shoporddetl.act_act_cost_amt 
					END CASE 

					SELECT * 
					INTO rr_prodmfg.* 
					FROM prodmfg 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = rr_shoporddetl.part_code 

					IF rr_prodmfg.part_type_ind = "P" THEN 
						PRINT COLUMN 1, rr_shoporddetl.type_ind, 
						COLUMN 3, rr_shoporddetl.part_code 

						PRINT COLUMN 7, rv_desc_text 
					ELSE 
						IF rv_est IS NULL THEN 
							LET rv_est = 0 
						END IF 
						IF rv_act IS NULL THEN 
							LET rv_act = 0 
						END IF 

						LET rv_est = rv_est * rr_shoporddetl.required_qty 
						LET rv_act = rv_act * rr_shoporddetl.issued_qty 

						IF rv_act IS NULL THEN 
							LET rv_act = 0 
						END IF 

						PRINT COLUMN 1, rr_shoporddetl.type_ind, 
						COLUMN 3, rr_shoporddetl.part_code, 
						COLUMN 26, rr_shoporddetl.required_qty, 
						COLUMN 41, rr_shoporddetl.uom_code, 
						COLUMN 46, rr_shoporddetl.issued_qty, 
						COLUMN 61, rr_shoporddetl.work_centre_code, 
						COLUMN 93, rv_est, 
						COLUMN 112, "C", 
						COLUMN 114, rv_act 

						IF rr_shoporddetl.std_price_amt IS NULL THEN 
							LET rr_shoporddetl.std_price_amt = 0 
						END IF 

						IF rr_shoporddetl.act_price_amt IS NULL THEN 
							LET rr_shoporddetl.act_price_amt = 0 
						END IF 

						LET rr_shoporddetl.std_price_amt 
						= rr_shoporddetl.std_price_amt 
						* rr_shoporddetl.required_qty 

						LET rr_shoporddetl.act_price_amt 
						= rr_shoporddetl.act_price_amt 
						* rr_shoporddetl.issued_qty 

						IF rr_shoporddetl.act_price_amt IS NULL THEN 
							LET rr_shoporddetl.act_price_amt = 0 
						END IF 

						PRINT COLUMN 7, rv_desc_text, 
						COLUMN 93, rr_shoporddetl.std_price_amt, 
						COLUMN 112, "P", 
						COLUMN 114, rr_shoporddetl.act_price_amt 

						LET rv_shop_ord_est_tot_cst = rv_shop_ord_est_tot_cst + rv_est 
						LET rv_shop_ord_act_tot_cst = rv_shop_ord_act_tot_cst + rv_act 
						LET rv_shop_ord_est_tot_prc = rv_shop_ord_est_tot_prc 
						+ rr_shoporddetl.std_price_amt 
						LET rv_shop_ord_act_tot_prc = rv_shop_ord_act_tot_prc 
						+ rr_shoporddetl.act_price_amt 
						LET rv_material_est_tot_cst = rv_material_est_tot_cst + rv_est 
						LET rv_material_act_tot_cst = rv_material_act_tot_cst + rv_act 
						LET rv_material_est_tot_prc = rv_material_est_tot_prc 
						+ rr_shoporddetl.std_price_amt 
						LET rv_material_act_tot_prc = rv_material_act_tot_prc 
						+ rr_shoporddetl.act_price_amt 
					END IF 

				WHEN rr_shoporddetl.type_ind = "W" 

					IF rr_shoporddetl.actual_end_date IS NOT NULL 
					AND rr_shoporddetl.actual_end_time IS NOT NULL THEN 
						LET rv_desc_txt = "Complete" 
					END IF 

					IF rr_shoporddetl.actual_start_date IS NOT NULL 
					AND rr_shoporddetl.actual_start_time IS NOT NULL 
					AND rr_shoporddetl.actual_end_date IS NULL 
					AND rr_shoporddetl.actual_end_time IS NULL THEN 
						LET rv_desc_txt = "Started" 
					END IF 

					IF rr_shoporddetl.actual_start_date IS NULL 
					AND rr_shoporddetl.actual_end_date IS NULL THEN 
						LET rv_desc_txt = "Planned" 
					END IF 

					SELECT * 
					INTO rr_workcentre.* 
					FROM workcentre 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND work_centre_code = rr_shoporddetl.work_centre_code 

					LET rv_cost = 0 
					LET rv_price = 0 

					SELECT sum(rate_amt) 
					INTO rv_cost 
					FROM workctrrate 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND work_centre_code = rr_shoporddetl.work_centre_code 
					AND rate_ind = "V" 

					SELECT sum(rate_amt) 
					INTO rv_price 
					FROM workctrrate 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND work_centre_code = rr_shoporddetl.work_centre_code 
					AND rate_ind = "F" 

					IF rv_price IS NULL THEN 
						LET rv_price = 0 
					END IF 
					IF rv_cost IS NULL THEN 
						LET rv_cost = 0 
					END IF 

					IF rr_workcentre.processing_ind = "Q" THEN 
						LET rv_cost = ((rv_cost / rr_workcentre.time_qty) 
						* rr_shoporddetl.oper_factor_amt * 
						fr_shopordhead.order_qty) + rv_price 
					ELSE 
						LET rv_cost = (rv_cost * rr_shoporddetl.oper_factor_amt * 
						fr_shopordhead.order_qty) + rv_price 
					END IF 
					LET rv_price = rv_cost + 
					((rv_cost * rr_workcentre.cost_markup_per) 
					/ 100) 

					IF rv_price IS NULL THEN 
						LET rv_price = 0 
					END IF 
					IF rv_cost IS NULL THEN 
						LET rv_cost = 0 
					END IF 

					SELECT sum(receipt_qty) 
					INTO rr_shoporddetl.receipted_qty 
					FROM wipreceipt 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND work_centre_code = rr_workcentre.work_centre_code 
					AND shop_order_num = rr_shoporddetl.shop_order_num 
					AND suffix_num = rr_shoporddetl.suffix_num 

					SELECT sum(cost_amt) 
					INTO rv_act_cost 
					FROM wipreceipt 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND work_centre_code = rr_workcentre.work_centre_code 
					AND shop_order_num = rr_shoporddetl.shop_order_num 
					AND suffix_num = rr_shoporddetl.suffix_num 

					SELECT sum(price_amt) 
					INTO rv_act_price 
					FROM wipreceipt 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND work_centre_code = rr_workcentre.work_centre_code 
					AND shop_order_num = rr_shoporddetl.shop_order_num 
					AND suffix_num = rr_shoporddetl.suffix_num 

					IF rv_act_cost IS NULL THEN 
						LET rv_act_cost = 0 
					END IF 

					IF rv_act_price IS NULL THEN 
						LET rv_act_price = 0 
					END IF 

					IF rr_workcentre.processing_ind = "Q" THEN 
						LET rv_required_time = rr_shoporddetl.required_qty / 
						rr_workcentre.time_qty 
					ELSE 
						LET rv_required_time = rr_shoporddetl.required_qty * 
						rr_workcentre.time_qty 
					END IF 

					LET rv_completed_time = NULL 

					SELECT sum(receipt_qty) 
					INTO rv_completed_time 
					FROM wipreceipt 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND work_centre_code = rr_shoporddetl.work_centre_code 
					AND shop_order_num = rr_shoporddetl.shop_order_num 
					AND suffix_num = rr_shoporddetl.suffix_num 
					AND sequence_num = rr_shoporddetl.sequence_num 
					AND type_ind = "T" 

					PRINT COLUMN 1, rr_shoporddetl.type_ind, 
					COLUMN 3, rr_shoporddetl.work_centre_code, 
					COLUMN 26, rr_shoporddetl.required_qty, 
					COLUMN 41, rr_workcentre.unit_uom_code, 
					COLUMN 46, rr_shoporddetl.receipted_qty USING "#####.##", 
					COLUMN 61, rv_desc_txt, 
					COLUMN 70, rv_required_time USING "#####.##", 
					COLUMN 80, rr_workcentre.time_unit_ind, 
					COLUMN 84, rv_completed_time USING "#####.##", 
					COLUMN 93, rv_cost, 
					COLUMN 112, "C", 
					COLUMN 114, rv_act_cost 

					PRINT COLUMN 7, rr_shoporddetl.desc_text, 
					COLUMN 93, rv_price, 
					COLUMN 112, "P", 
					COLUMN 114, rv_act_price 

					LET rv_shop_ord_est_tot_cst = rv_shop_ord_est_tot_cst + rv_cost 
					LET rv_shop_ord_act_tot_cst = rv_shop_ord_act_tot_cst 
					+ rv_act_cost 
					LET rv_shop_ord_est_tot_prc = rv_shop_ord_est_tot_prc + rv_price 
					LET rv_shop_ord_act_tot_prc = rv_shop_ord_act_tot_prc 
					+ rv_act_price 

					LET rv_other_mt_est_tot_cst = rv_other_mt_est_tot_cst + rv_cost 
					LET rv_other_mt_act_tot_cst = 
					rv_other_mt_act_tot_cst + rv_act_cost 
					LET rv_other_mt_est_tot_prc = rv_other_mt_est_tot_prc + rv_price 
					LET rv_other_mt_act_tot_prc = 
					rv_other_mt_act_tot_prc + rv_act_price 

				WHEN rr_shoporddetl.type_ind = "I" 
					PRINT COLUMN 1, rr_shoporddetl.type_ind, 
					COLUMN 3, "INSTRUCTION" 
					PRINT COLUMN 7, rr_shoporddetl.desc_text 

				WHEN rr_shoporddetl.type_ind matches "[SU]" 
					IF rr_shoporddetl.std_price_amt IS NULL THEN 
						LET rr_shoporddetl.std_price_amt = 0 
					END IF 

					IF rr_shoporddetl.act_price_amt IS NULL THEN 
						LET rr_shoporddetl.act_price_amt = 0 
					END IF 

					IF rr_shoporddetl.type_ind = "U" THEN 
						IF rr_shoporddetl.cost_type_ind = "Q" THEN 
							LET rv_setup_qty = fr_shopordhead.order_qty / 
							rr_shoporddetl.var_amt 

							IF fr_shopordhead.order_qty / rr_shoporddetl.var_amt > 
							rv_setup_qty THEN 
								LET rv_setup_qty = rv_setup_qty + 1 
							END IF 

							LET rr_shoporddetl.std_est_cost_amt = rv_setup_qty * 
							rr_shoporddetl.std_est_cost_amt 
							LET rr_shoporddetl.std_price_amt = rv_setup_qty * 
							rr_shoporddetl.std_price_amt 
						END IF 

						PRINT COLUMN 1, rr_shoporddetl.type_ind, 
						COLUMN 3, "SET UP", 
						COLUMN 70, rr_shoporddetl.required_qty 
						USING "#####.##", 
						COLUMN 80, rr_shoporddetl.uom_code, 
						COLUMN 93, rr_shoporddetl.std_est_cost_amt, 
						COLUMN 112, "C", 
						COLUMN 114, rr_shoporddetl.act_act_cost_amt 
					ELSE 
						IF rr_shoporddetl.cost_type_ind = "V" THEN 
							LET rr_shoporddetl.std_est_cost_amt = 
							rr_shoporddetl.std_est_cost_amt 
							* fr_shopordhead.order_qty 
							LET rr_shoporddetl.std_price_amt = 
							rr_shoporddetl.std_price_amt 
							* fr_shopordhead.order_qty 
						END IF 

						PRINT COLUMN 1, rr_shoporddetl.type_ind, 
						COLUMN 3, "COST", 
						COLUMN 93, rr_shoporddetl.std_est_cost_amt, 
						COLUMN 112, "C", 
						COLUMN 114, rr_shoporddetl.act_act_cost_amt 
					END IF 

					PRINT COLUMN 7, rr_shoporddetl.desc_text, 
					COLUMN 93, rr_shoporddetl.std_price_amt, 
					COLUMN 112, "P", 
					COLUMN 114, rr_shoporddetl.act_price_amt 

					LET rv_shop_ord_est_tot_cst = rv_shop_ord_est_tot_cst 
					+ rr_shoporddetl.std_est_cost_amt 
					LET rv_shop_ord_act_tot_cst = rv_shop_ord_act_tot_cst 
					+ rr_shoporddetl.act_act_cost_amt 
					LET rv_shop_ord_est_tot_prc = rv_shop_ord_est_tot_prc 
					+ rr_shoporddetl.std_price_amt 
					LET rv_shop_ord_act_tot_prc = rv_shop_ord_act_tot_prc 
					+ rr_shoporddetl.act_price_amt 
					LET rv_other_mt_est_tot_cst = rv_other_mt_est_tot_cst 
					+ rr_shoporddetl.std_est_cost_amt 
					LET rv_other_mt_act_tot_cst = rv_other_mt_act_tot_cst 
					+ rr_shoporddetl.act_act_cost_amt 
					LET rv_other_mt_est_tot_prc = rv_other_mt_est_tot_prc 
					+ rr_shoporddetl.std_price_amt 
					LET rv_other_mt_act_tot_prc = rv_other_mt_act_tot_prc 
					+ rr_shoporddetl.act_price_amt 
			END CASE 

			IF rr_shoporddetl.type_ind matches "[WSUI]" 
			AND rr_shoporddetl.desc_text[1,3] = "###" THEN 
				LET rv_temp_note_code = rr_shoporddetl.desc_text[4,15] 

				DECLARE rp_notes_cur CURSOR FOR 
				SELECT * 
				FROM notes 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND note_code = rv_temp_note_code 

				FOREACH rp_notes_cur INTO rr_notes.* 
					PRINT COLUMN 7, rr_notes.note_text 
				END FOREACH 
			END IF 

		AFTER GROUP OF rr_shoporddetl.suffix_num 
			LET rv_prev_shop_ord_num = rr_shoporddetl.shop_order_num 
			PRINT COLUMN 93, "------------------", 
			COLUMN 114, "------------------" 
			PRINT COLUMN 69, "Shop Order Total Cost : ", 
			COLUMN 93, rv_shop_ord_est_tot_cst, 
			COLUMN 114, rv_shop_ord_act_tot_cst 
			PRINT COLUMN 85, "Price : ", 
			COLUMN 93, rv_shop_ord_est_tot_prc, 
			COLUMN 114, rv_shop_ord_act_tot_prc 
			PRINT COLUMN 93, "==================", 
			COLUMN 114, "==================" 
			PRINT COLUMN 71, "Unit Material Cost : ", 
			COLUMN 93, rv_material_est_tot_cst, 
			COLUMN 114, rv_material_act_tot_cst 
			PRINT COLUMN 76, "Material Price : ", 
			COLUMN 93, rv_material_est_tot_prc, 
			COLUMN 114, rv_material_act_tot_prc 
			PRINT COLUMN 79, "Other Cost : ", 
			COLUMN 93, rv_other_mt_est_tot_cst, 
			COLUMN 114, rv_other_mt_act_tot_cst 
			PRINT COLUMN 79, "Other Price : ", 
			COLUMN 93, rv_other_mt_est_tot_prc, 
			COLUMN 114, rv_other_mt_act_tot_prc 
			PRINT COLUMN 93, "==================", 
			COLUMN 114, "==================" 

			LET rv_shop_ord_est_tot_cst = rv_shop_ord_est_tot_cst 
			/ fr_shopordhead.order_qty 
			LET rv_shop_ord_act_tot_cst = rv_shop_ord_act_tot_cst 
			/ fr_shopordhead.order_qty 
			LET rv_shop_ord_est_tot_prc = rv_shop_ord_est_tot_prc 
			/ fr_shopordhead.order_qty 
			LET rv_shop_ord_act_tot_prc = rv_shop_ord_act_tot_prc 
			/ fr_shopordhead.order_qty 

			PRINT COLUMN 81, "Unit Cost : ", 
			COLUMN 93, rv_shop_ord_est_tot_cst, 
			COLUMN 114, rv_shop_ord_act_tot_cst 
			PRINT COLUMN 85, "Price : ", 
			COLUMN 93, rv_shop_ord_est_tot_prc, 
			COLUMN 114, rv_shop_ord_act_tot_prc 
			PRINT COLUMN 93, "==================", 
			COLUMN 114, "==================" 


		AFTER GROUP OF rr_shoporddetl.shop_order_num 
			IF rv_prev_shop_ord_num != rr_shoporddetl.shop_order_num THEN 
				LET rv_prev_shop_ord_num = rr_shoporddetl.shop_order_num 
				PRINT COLUMN 93, "------------------", 
				COLUMN 114, "------------------" 
				PRINT COLUMN 69, "Shop Order Total Cost : ", 
				COLUMN 93, rv_shop_ord_est_tot_cst, 
				COLUMN 114, rv_shop_ord_act_tot_cst 
				PRINT COLUMN 85, "Price : ", 
				COLUMN 93, rv_shop_ord_est_tot_prc, 
				COLUMN 114, rv_shop_ord_act_tot_prc 
				PRINT COLUMN 93, "==================", 
				COLUMN 114, "==================" 
				PRINT COLUMN 71, "Unit Material Cost : ", 
				COLUMN 93, rv_material_est_tot_cst, 
				COLUMN 114, rv_material_act_tot_cst 
				PRINT COLUMN 76, "Material Price : ", 
				COLUMN 93, rv_material_est_tot_prc, 
				COLUMN 114, rv_material_act_tot_prc 
				PRINT COLUMN 79, "Other Cost : ", 
				COLUMN 93, rv_other_mt_est_tot_cst, 
				COLUMN 114, rv_other_mt_act_tot_cst 
				PRINT COLUMN 79, "Other Price : ", 
				COLUMN 93, rv_other_mt_est_tot_prc, 
				COLUMN 114, rv_other_mt_act_tot_prc 
				PRINT COLUMN 93, "==================", 
				COLUMN 114, "==================" 

				LET rv_shop_ord_est_tot_cst = rv_shop_ord_est_tot_cst 
				/ fr_shopordhead.order_qty 
				LET rv_shop_ord_act_tot_cst = rv_shop_ord_act_tot_cst 
				/ fr_shopordhead.order_qty 
				LET rv_shop_ord_est_tot_prc = rv_shop_ord_est_tot_prc 
				/ fr_shopordhead.order_qty 
				LET rv_shop_ord_act_tot_prc = rv_shop_ord_act_tot_prc 
				/ fr_shopordhead.order_qty 

				PRINT COLUMN 81, "Unit Cost : ", 
				COLUMN 93, rv_shop_ord_est_tot_cst, 
				COLUMN 114, rv_shop_ord_act_tot_cst 
				PRINT COLUMN 85, "Price : ", 
				COLUMN 93, rv_shop_ord_est_tot_prc, 
				COLUMN 114, rv_shop_ord_act_tot_prc 
				PRINT COLUMN 93, "==================", 
				COLUMN 114, "==================" 
			END IF 


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

			LET pv_pageno = pageno  #????? 

END REPORT 
############################################################
# END REPORT M35_rpt_list_shopord(p_rpt_idx,rr_shoporddetl)
############################################################