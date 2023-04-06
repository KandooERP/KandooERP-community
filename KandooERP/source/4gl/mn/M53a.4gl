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
GLOBALS "../mn/M5_GROUP_GLOBALS.4gl" 
GLOBALS "../mn/M53_GLOBALS.4gl"

DEFINE 
pr_menunames RECORD LIKE menunames.*, 
pr_shoporddetl RECORD LIKE shoporddetl.*, 
pr_prodmfg RECORD LIKE prodmfg.*, 
pr_product RECORD LIKE product.*, 
pr_mps RECORD LIKE mps.*, 
pr_mrp RECORD LIKE mrp.*, 
pr_bor RECORD LIKE bor.*

###########################################################################
# MAIN
#
# Purpose - MRP
########################################################################### 
MAIN 

	#Initial UI Init
	CALL setModuleId("M53") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	IF num_args() > 0 THEN 
		LET pv_background = true 
	END IF 

	CALL mrp_main() 

END MAIN 
###########################################################################
# END MAIN 
########################################################################### 

###########################################################################
# FUNCTION mrp_main() 
#
# Purpose - MRP
########################################################################### 
FUNCTION mrp_main() 
	DEFINE l_rpt_idx SMALLINT  #report array index
	DEFINE 
	fv_ok SMALLINT, 
	fv_runner CHAR(300), 
	fv_output CHAR(80) 


	IF pv_background THEN 
		LET pv_mrp_plan = arg_val(1) 
		LET pv_mrp_desc = arg_val(2) 
		LET pv_mps_plan = arg_val(3) 
		LET pv_scrap_ind = arg_val(4) 
		LET fv_ok = true 

		WHENEVER ERROR CONTINUE 

		LET pv_found_error = false 
		
		#------------------------------------------------------------
		LET l_rpt_idx = rpt_start("M53-MRP-BG","M53_rpt_list_mrp_background","N/A", RPT_SHOW_RMS_DIALOG)
		IF l_rpt_idx = 0 THEN #User pressed CANCEL
			RETURN FALSE
		END IF	
		START REPORT M53_rpt_list_mrp_background TO rpt_get_report_file_with_path2(l_rpt_idx)
		WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
		TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
		BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
		LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
		RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
		#------------------------------------------------------------

		BEGIN WORK 
			LOCK TABLE mrp in exclusive MODE 

			IF status <> 0 THEN 
				LET pv_errormsg = "Someone ELSE IS running MRP AT the moment, wait until they have finished"
				
				#---------------------------------------------------------
				OUTPUT TO REPORT M53_rpt_list_mrp_background(l_rpt_idx, 
				pv_errormsg) 
				#---------------------------------------------------------

				LET pv_found_error = true 
				LET fv_ok = false 
			END IF 

			IF NOT fv_ok THEN 

				#------------------------------------------------------------
				FINISH REPORT M53_rpt_list_mrp_background
				CALL rpt_finish("M53_rpt_list_mrp_background")
				#------------------------------------------------------------
			
				ROLLBACK WORK 
				RETURN 
			END IF 

		COMMIT WORK 
		WHENEVER ERROR stop 

		CALL drop_table() 
		CALL create_table() 

		IF fv_ok THEN 
			CALL generate_mrp(pv_scrap_ind) RETURNING fv_ok 

			IF fv_ok THEN 
				CALL add_in_pos() 
				CALL run_prog("M53c", pv_mrp_plan, pv_scrap_ind, "", "") 
			END IF 
		END IF 

		#------------------------------------------------------------
		FINISH REPORT M53_rpt_list_mrp_background
		CALL rpt_finish("M53_rpt_list_mrp_background")
		#------------------------------------------------------------
 
		CALL drop_table() 
		RETURN 
	END IF 

	OPEN WINDOW wm135 with FORM "M135" 
	CALL  windecoration_m("M135") -- albo kd-762 

	LET fv_ok = true 

	CALL kandoomenu("M",143) RETURNING pr_menunames.* 
	MENU pr_menunames.menu_text 
		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 
		COMMAND pr_menunames.cmd1_code pr_menunames.cmd1_text # REPORT 
			WHENEVER ERROR CONTINUE 
			BEGIN WORK 
				LOCK TABLE mrp in exclusive MODE 

				IF status <> 0 THEN 
					LET msgresp = kandoomsg("M",9645,"") 
					# ERROR "Someone ELSE IS running MRP AT the moment, ",
					#       "wait until they have finished"
					SLEEP 3 
					LET fv_ok = false 
					ROLLBACK WORK 
					EXIT program 
				END IF 

			COMMIT WORK 
			CALL drop_table() 
			CALL create_table() 
			CALL input_mrp() RETURNING fv_ok 

			IF fv_ok THEN 
				{
				                OPEN WINDOW w1_M35 AT 14,8 with 3 rows, 56 columns
				                    attributes (white,border)
				}
				CALL generate_mrp(pv_scrap_ind) RETURNING fv_ok 

				IF fv_ok THEN 
					CALL add_in_pos() 
					CALL run_prog("M53c", pv_mrp_plan, pv_scrap_ind, "", "") 
					NEXT option pr_menunames.cmd2_code # PRINT 
				END IF 

				--                CLOSE WINDOW w1_M35     -- albo  KD-762
			END IF 

			CALL drop_table() 

		ON ACTION "Print Manager" 
			#command pr_menunames.cmd2_code pr_menunames.cmd2_text # Print
			CALL run_prog("URS", "", "", "", "") 
			NEXT option pr_menunames.cmd5_code # EXIT 

		COMMAND pr_menunames.cmd3_code pr_menunames.cmd3_text # MESSAGE 
			OPTIONS 
			PROMPT line FIRST 
			--            prompt "Enter new Report Heading " FOR rpt_note -- agb
			LET rpt_note = promptInput("Enter new Report Heading ","",80) -- albo 
			NEXT option pr_menunames.cmd1_code # REPORT 

		COMMAND pr_menunames.cmd4_code pr_menunames.cmd4_text # background 
			CALL input_mrp() RETURNING fv_ok 
			CALL drop_table() 
			CALL create_table() 

			IF fv_ok THEN 
				CALL run_prog("M53",pv_mrp_plan, pv_mrp_desc, 
				pv_mps_plan, pv_scrap_ind) 
			END IF 

		COMMAND pr_menunames.cmd5_code pr_menunames.cmd5_text # EXIT 
			EXIT MENU 

		COMMAND KEY (interrupt) 
			EXIT MENU 
	END MENU 

	CLOSE WINDOW wm135 

END FUNCTION 
###########################################################################
# END FUNCTION mrp_main() 
########################################################################### 


###########################################################################
# FUNCTION input_mrp()
#
# 
########################################################################### 
FUNCTION input_mrp() 
	DEFINE 
	fv_ok SMALLINT, 
	fv_count INTEGER 


	LET fv_ok = true 

	LET msgresp = kandoomsg("M",1520,"") 
	# MESSAGE "Enter MRP data AND press ESC TO continue"

	INPUT pv_mrp_plan, pv_mps_plan, 
	pv_mrp_desc, pv_scrap_ind 
	FROM plan_code, schedule_code, 
	desc_text, scrap_ind 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD plan_code 
			SELECT unique count(*) 
			INTO fv_count 
			FROM mrp 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND plan_code = pv_mrp_plan 

			IF fv_count > 0 THEN 
				ERROR "" 
				--- modif ericv init # attributes (normal,white)
				LET msgresp = kandoomsg("M",4506,"") 

				IF msgresp = "Y" THEN 
					DELETE 
					FROM mrp 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND plan_code = pv_mrp_plan 

					DELETE FROM mpsdemand 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND plan_code = pv_mrp_plan 
					AND type_text = "RP" 
				ELSE 
					NEXT FIELD plan_code 
				END IF 
			END IF 

		AFTER FIELD schedule_code 
			SELECT unique count(*) 
			INTO fv_count 
			FROM mps 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND plan_code = pv_mps_plan 

			IF fv_count = 0 THEN 
				LET msgresp = kandoomsg("M",9661,"") 
				# ERROR "This schedule does NOT exist in the database"
				NEXT FIELD schedule_code 
			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 

			IF pv_mrp_plan IS NULL THEN 
				LET msgresp = kandoomsg("M",9648,"") 
				# ERROR "A plan code must be entered"
				NEXT FIELD plan_code 
			ELSE 
				SELECT unique count(*) 
				INTO fv_count 
				FROM mrp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND plan_code = pv_mrp_plan 

				IF fv_count > 0 THEN 
					LET msgresp = kandoomsg("M",9649,"")		#error"The plan code entered already exists in the database"
					NEXT FIELD plan_code 
				END IF 
			END IF 

			IF pv_mps_plan IS NULL THEN 
				LET msgresp = kandoomsg("M",9662,"")				# ERROR "A schedule code must be entered"
				NEXT FIELD schedule_code 
			ELSE 
				SELECT unique count(*) 
				INTO fv_count 
				FROM mps 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND plan_code = pv_mps_plan 

				IF fv_count = 0 THEN 
					LET msgresp = kandoomsg("M",9661,"") 	#ERROR "The schedule entered does NOT exist in the database"
					NEXT FIELD schedule_code 
				END IF 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET fv_ok = false 
		LET msgresp = kandoomsg("M",9663,"") # ERROR "MRP Generation Aborted"
	END IF 

	RETURN fv_ok 

END FUNCTION 
###########################################################################
# END FUNCTION input_mrp()
########################################################################### 


###########################################################################
# FUNCTION generate_mrp(fv_scrap_ind) 
#
# 
########################################################################### 
FUNCTION generate_mrp(fv_scrap_ind) 
	DEFINE 
	fv_due_date DATE, 
	fv_start_date DATE, 
	fv_type CHAR(2), 
	fv_scrap_ind CHAR(1), 
	fv_calc_qty LIKE shoporddetl.required_qty, 
	fv_scrap_qty LIKE shoporddetl.required_qty, 
	fv_yield_qty LIKE shoporddetl.required_qty, 
	fv_ro_qty LIKE mpsdemand.required_qty 


	DELETE FROM mrp 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND plan_code = pv_mrp_plan 

	### First run through AND get all shop orders AND forecast orders

	DECLARE mps_cursor CURSOR FOR 
	SELECT * 
	FROM mps 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND plan_code = pv_mps_plan 

	FOREACH mps_cursor INTO pr_mps.* 
		IF NOT pv_background THEN 
			CALL working("Processing mps ",pr_mps.part_code) 
		END IF 

		IF pr_mps.type_text = "CX" THEN 
			INSERT INTO mrp VALUES (glob_rec_kandoouser.cmpy_code, 
			pv_mrp_plan, 
			pr_mps.part_code, 
			pr_mps.start_date, 
			pr_mps.due_date, 
			pv_mrp_desc, 
			"CO", 
			pr_mps.required_qty, 
			pr_mps.reference_num, 
			today, 
			glob_rec_kandoouser.sign_on_code, 
			"M53.1") 
			CONTINUE FOREACH 
		END IF 

		IF pr_mps.type_text = "SS" 
		OR pr_mps.type_text = "UZ" 
		OR pr_mps.type_text = "FS" 
		OR pr_mps.type_text = "CS" 
		OR pr_mps.type_text = "FO" 
		OR pr_mps.type_text = "CO" THEN 

			SELECT required_qty 
			INTO fv_ro_qty 
			FROM mpsdemand 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND plan_code = pv_mps_plan 
			AND part_code = pr_mps.part_code 
			AND due_date = pr_mps.due_date 
			AND type_text = "RO" 
			AND reference_num = pr_mps.reference_num 

			IF status = notfound THEN 
				CONTINUE FOREACH 
			ELSE 
				LET pr_mps.required_qty = fv_ro_qty 
			END IF 

		END IF 

		IF pr_mps.type_text = "SS" 
		OR pr_mps.type_text = "UZ" 
		OR pr_mps.type_text = "FS" 
		OR pr_mps.type_text = "CS" 
		OR pr_mps.type_text = "FO" 
		OR pr_mps.type_text = "UP" 
		OR pr_mps.type_text = "CO" THEN 

			DECLARE bor_curs CURSOR FOR 
			SELECT * 
			FROM bor 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND parent_part_code = pr_mps.part_code 

			FOREACH bor_curs INTO pr_bor.* 
				SELECT * 
				INTO pr_prodmfg.* 
				FROM prodmfg 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pr_bor.part_code 
				AND part_type_ind = "R" 

				IF status != 0 THEN 
					CONTINUE FOREACH 
				END IF 

				SELECT * 
				INTO pr_product.* 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pr_bor.part_code 

				IF status != 0 THEN 
					CONTINUE FOREACH 
				END IF 

				IF pr_product.days_lead_num IS NULL THEN 
					LET pr_product.days_lead_num = 0 
				END IF 

				LET fv_due_date = get_cal_date(pr_mps.start_date, 
				0, 
				"F") 
				LET fv_start_date = get_cal_date(fv_due_date, 
				pr_product.days_lead_num, 
				"B") 
				LET fv_type = pr_mps.type_text 
				LET fv_calc_qty = pr_bor.required_qty * pr_mps.required_qty 
				LET fv_yield_qty = 0 
				LET fv_scrap_qty = 0 

				IF pr_prodmfg.scrap_per IS NOT NULL 
				AND pr_prodmfg.scrap_per > 0 THEN 
					LET fv_scrap_qty =(fv_calc_qty * pr_prodmfg.scrap_per) / 100 
				END IF 

				IF pr_prodmfg.yield_per IS NOT NULL 
				AND pr_prodmfg.yield_per > 0 THEN 
					LET fv_yield_qty = 100 / pr_prodmfg.yield_per 
					LET fv_yield_qty =(fv_calc_qty * fv_yield_qty) - fv_calc_qty 
				END IF 

				IF fv_scrap_ind = "N" THEN 
					LET fv_yield_qty = 0 
					LET fv_scrap_qty = 0 
				ELSE 
					IF fv_scrap_ind = "S" THEN 
						LET fv_yield_qty = 0 
					ELSE 
						IF fv_scrap_ind = "Y" THEN 
							LET fv_scrap_qty = 0 
						END IF 
					END IF 
				END IF 

				IF fv_calc_qty < 0 THEN 
					LET fv_scrap_qty = fv_scrap_qty * -1 
					LET fv_yield_qty = fv_yield_qty * -1 
				END IF 

				LET fv_calc_qty = fv_calc_qty + fv_scrap_qty + fv_yield_qty 

				CASE 
					WHEN pr_bor.uom_code = pr_prodmfg.man_uom_code 
						LET fv_calc_qty=fv_calc_qty / pr_prodmfg.man_stk_con_qty 
					WHEN pr_bor.uom_code = pr_product.pur_uom_code 
						LET fv_calc_qty=fv_calc_qty / pr_product.pur_stk_con_qty 
					WHEN pr_bor.uom_code = pr_product.sell_uom_code 
						LET fv_calc_qty=fv_calc_qty * pr_product.stk_sel_con_qty 
				END CASE 

				IF fv_type = "UZ" THEN 
					LET fv_type = "PS" 
				END IF 

				IF fv_type = "FO" THEN 
					LET fv_type = "FS" 
				END IF 

				SELECT plan_code 
				FROM mrp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND plan_code = pv_mrp_plan 
				AND part_code = pr_bor.part_code 
				AND start_date = fv_start_date 
				AND due_date = fv_due_date 
				AND type_text = fv_type 
				AND reference_num = pr_mps.reference_num 

				IF status = notfound THEN 

					INSERT INTO mrp VALUES (glob_rec_kandoouser.cmpy_code, 
					pv_mrp_plan, 
					pr_bor.part_code, 
					fv_start_date, 
					fv_due_date, 
					pv_mrp_desc, 
					fv_type, 
					fv_calc_qty, 
					pr_mps.reference_num, 
					today, 
					glob_rec_kandoouser.sign_on_code, 
					"M53.2") 

					IF fv_type = "UZ" THEN 
						LET fv_type = "PS" 
					END IF 
				ELSE 
					UPDATE mrp 
					SET required_qty = required_qty + fv_calc_qty, 
					last_program_text = "M53", 
					last_user_text = glob_rec_kandoouser.sign_on_code, 
					last_change_date = today 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND plan_code = pv_mrp_plan 
					AND part_code = pr_bor.part_code 
					AND start_date = fv_start_date 
					AND due_date = fv_due_date 
					AND type_text = fv_type 
					AND reference_num = pr_mps.reference_num 
				END IF 
			END FOREACH 
			FREE bor_curs 

			CONTINUE FOREACH 
		END IF 

		DECLARE shop_curs CURSOR FOR 
		SELECT * 
		FROM shoporddetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND shop_order_num = pr_mps.reference_num 
		AND type_ind = "C" 


		FOREACH shop_curs INTO pr_shoporddetl.* 
			SELECT * 
			INTO pr_prodmfg.* 
			FROM prodmfg 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_shoporddetl.part_code 
			AND part_type_ind = "R" 

			IF status != 0 THEN 
				CONTINUE FOREACH 
			END IF 

			SELECT * 
			INTO pr_product.* 
			FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_shoporddetl.part_code 

			IF status != 0 THEN 
				CONTINUE FOREACH 
			END IF 

			IF pr_product.days_lead_num IS NULL THEN 
				LET pr_product.days_lead_num = 0 
			END IF 

			LET fv_due_date = get_cal_date(pr_mps.start_date, 
			0, 
			"F") 
			LET fv_start_date = get_cal_date(fv_due_date, 
			pr_product.days_lead_num, 
			"B") 

			IF pr_mps.type_text = "SO" 
			OR pr_mps.type_text = "SS" THEN 
				LET fv_type = "SO" 
			END IF 

			IF pr_mps.type_text = "FO" 
			OR pr_mps.type_text = "FS" THEN 
				LET fv_type = "FO" 
			END IF 

			IF pr_mps.type_text = "AO" THEN 
				LET fv_type = "SS" 
			END IF 

			CASE 
				WHEN pr_shoporddetl.uom_code = pr_prodmfg.man_uom_code 
					LET pr_shoporddetl.required_qty = 
					pr_shoporddetl.required_qty / pr_prodmfg.man_stk_con_qty 
				WHEN pr_shoporddetl.uom_code = pr_product.pur_uom_code 
					LET pr_shoporddetl.required_qty = 
					pr_shoporddetl.required_qty / pr_product.pur_stk_con_qty 
				WHEN pr_shoporddetl.uom_code = pr_product.sell_uom_code 
					LET pr_shoporddetl.required_qty = 
					pr_shoporddetl.required_qty * pr_product.stk_sel_con_qty 
			END CASE 

			IF fv_type = "UZ" THEN 
				LET fv_type = "PS" 
			END IF 

			SELECT plan_code 
			FROM mrp 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND plan_code = pv_mrp_plan 
			AND part_code = pr_shoporddetl.part_code 
			AND start_date = fv_start_date 
			AND due_date = fv_due_date 
			AND type_text = fv_type 
			AND reference_num = pr_mps.reference_num 

			IF status = notfound THEN 

				INSERT INTO mrp VALUES (glob_rec_kandoouser.cmpy_code, 
				pv_mrp_plan, 
				pr_shoporddetl.part_code, 
				fv_start_date, 
				fv_due_date, 
				pv_mrp_desc, 
				fv_type, 
				pr_shoporddetl.required_qty, 
				pr_mps.reference_num, 
				today, 
				glob_rec_kandoouser.sign_on_code, 
				"M53.3") 
			ELSE 
				UPDATE mrp 
				SET required_qty = required_qty + 
				pr_shoporddetl.required_qty, 
				last_program_text = "M53", 
				last_user_text = glob_rec_kandoouser.sign_on_code, 
				last_change_date = today 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND plan_code = pv_mrp_plan 
				AND part_code = pr_shoporddetl.part_code 
				AND start_date = fv_start_date 
				AND due_date = fv_due_date 
				AND type_text = fv_type 
				AND reference_num = pr_mps.reference_num 
			END IF 
		END FOREACH 
		FREE shop_curs 
	END FOREACH 
	FREE mps_cursor 

	RETURN true 

END FUNCTION 
###########################################################################
# END FUNCTION generate_mrp(fv_scrap_ind) 
########################################################################### 


###########################################################################
# FUNCTION add_in_pos() 
#
# 
########################################################################### 
FUNCTION add_in_pos() 

	DEFINE 
	fr_poaudit RECORD LIKE poaudit.*, 
	fv_order_total LIKE poaudit.order_qty, 
	fv_received_total LIKE poaudit.received_qty, 
	fv_voucher_total LIKE poaudit.voucher_qty, 
	fv_order_num LIKE purchhead.order_num, 
	fv_line_num LIKE purchdetl.line_num, 
	fv_uom LIKE purchdetl.uom_code, 
	fv_pur_uom LIKE product.pur_uom_code, 
	fv_sell_uom LIKE product.sell_uom_code, 
	fv_pur_stk_con LIKE product.pur_stk_con_qty, 
	fv_stk_sel_con LIKE product.stk_sel_con_qty, 
	fv_part_code LIKE prodmfg.part_code, 
	fv_due_date LIKE purchhead.due_date, 
	fv_lead_time LIKE product.days_lead_num, 
	fv_start_date DATE, 
	fv_required_qty FLOAT 


	DECLARE rou_part CURSOR FOR 
	SELECT unique part_code 
	FROM mrp 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND plan_code = pv_mrp_plan 

	FOREACH rou_part INTO fv_part_code 
		IF NOT pv_background THEN 
			CALL working("Get POs ", fv_part_code) 
		END IF 

		DECLARE purc_curs CURSOR FOR 
		SELECT purchdetl.line_num, purchhead.order_num, purchhead.due_date, 
		purchdetl.uom_code 
		FROM purchhead, purchdetl 
		WHERE purchhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND purchdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND purchdetl.order_num = purchhead.order_num 
		AND purchdetl.vend_code = purchhead.vend_code 
		AND purchdetl.ref_text = fv_part_code 
		AND purchhead.status_ind != "C" 

		FOREACH purc_curs INTO fv_line_num, fv_order_num, fv_due_date, fv_uom 
			DECLARE po_curs CURSOR FOR 
			SELECT * 
			INTO fr_poaudit.* 
			FROM poaudit 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND po_num = fv_order_num 
			AND line_num = fv_line_num 

			LET fv_order_total = 0 
			LET fv_received_total = 0 
			LET fv_voucher_total = 0 

			FOREACH po_curs 
				LET fv_order_total = fv_order_total + fr_poaudit.order_qty 
				LET fv_received_total = fv_received_total + 
				fr_poaudit.received_qty 
				LET fv_voucher_total = fv_voucher_total + fr_poaudit.voucher_qty 
			END FOREACH 
			FREE po_curs 

			SELECT days_lead_num, pur_uom_code, sell_uom_code, pur_stk_con_qty, 
			stk_sel_con_qty 
			INTO fv_lead_time, fv_pur_uom, fv_sell_uom, fv_pur_stk_con, 
			fv_stk_sel_con 
			FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = fv_part_code 

			LET fv_start_date = get_cal_date(fv_due_date, 
			fv_lead_time, 
			"B") 
			LET fv_required_qty = fv_order_total - fv_received_total 

			CASE 
				WHEN fv_uom = fv_pur_uom 
					LET fv_required_qty = fv_required_qty * fv_pur_stk_con 
				WHEN fv_uom = fv_sell_uom 
					LET fv_required_qty = fv_required_qty / fv_stk_sel_con 
			END CASE 

			IF fv_required_qty <> 0 THEN 
				INSERT INTO mrp VALUES (glob_rec_kandoouser.cmpy_code, 
				pv_mrp_plan, 
				fv_part_code, 
				fv_start_date, 
				fv_due_date, 
				pv_mrp_desc, 
				"PO", 
				fv_required_qty, 
				fv_order_num, 
				today, 
				glob_rec_kandoouser.sign_on_code, 
				"M53.4") 

			END IF 
		END FOREACH 
		FREE purc_curs 
	END FOREACH 
	FREE rou_part 

END FUNCTION 
###########################################################################
# END FUNCTION add_in_pos() 
########################################################################### 


###########################################################################
# REPORT M53_rpt_list_mrp_background(rp_errormsg)
#
# 
########################################################################### 
REPORT M53_rpt_list_mrp_background(rp_errormsg) 

	DEFINE 
	rp_errormsg CHAR(100) 


	OUTPUT 
	left margin 1 

	FORMAT 
		FIRST PAGE HEADER 
			PRINT COLUMN 1, "Date: ", today, 
			COLUMN 100, "Page :", pageno USING "####" 
			PRINT 
			PRINT COLUMN 50, "MRP Background Report " 
			PRINT 
			PRINT COLUMN 1, "----------------------------------------", 
			"----------------------------------------", 
			"-----------------------------------------------" 
			PRINT 

		ON EVERY ROW 
			PRINT COLUMN 1, rp_errormsg 
			PRINT 

		ON LAST ROW 
			PRINT 

			IF pv_found_error THEN 
				PRINT " Errors have occured during the MRP - MRP has NOT run" 
			ELSE 
				PRINT " MRP Successful - " 
			END IF 

END REPORT 
###########################################################################
# END REPORT M53_rpt_list_mrp_background(rp_errormsg)
###########################################################################