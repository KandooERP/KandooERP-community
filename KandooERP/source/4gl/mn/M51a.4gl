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
GLOBALS "../mn/M51_GLOBALS.4gl"

GLOBALS 

	DEFINE 
--	formname CHAR(15), 
--	rpt_pageno SMALLINT, 
--	rpt_length SMALLINT, 
--	rpt_note CHAR(80), 
--	rpt_wid SMALLINT, 
	pv_mps_plan LIKE mps.plan_code, 
	pv_mrp_plan LIKE mrp.plan_code, 
	pv_mps_desc LIKE mps.desc_text, 
	pv_factor_ind LIKE shopordhead.probability_per, 
	pv_fence_ind CHAR(1), 
	pv_scrap_ind CHAR(1), 
	pv_prodgrp_code LIKE product.prodgrp_code, 
	pv_cat_code LIKE product.cat_code, 
	pv_class_code LIKE product.class_code, 
	pv_end_date DATE, 
	pv_demand_fence DATE, 
	pv_background SMALLINT, 
	pv_found_error SMALLINT, 
	pv_errormsg CHAR(100) 

END GLOBALS 
###########################################################################
# MODULE Scope Variables
###########################################################################
DEFINE 
pr_menunames RECORD LIKE menunames.*, 
pr_shopordhead RECORD LIKE shopordhead.*, 
pr_shoporddetl RECORD LIKE shoporddetl.*, 
pr_product RECORD LIKE product.*, 
pr_prodmfg RECORD LIKE prodmfg.*, 
pr_mps RECORD LIKE mps.*, 
pr_bor RECORD LIKE bor.*, 
pr_configuration RECORD LIKE configuration.*, 
pv_rowid INTEGER, 
pr_cust_ord RECORD 
	due_date LIKE orderhead.order_date, 
	order_num LIKE orderhead.order_num, 
	cust_code LIKE orderhead.cust_code, 
	part_code LIKE orderdetl.part_code, 
	uom_code LIKE orderdetl.uom_code, 
	order_qty LIKE orderdetl.order_qty, 
	inv_qty LIKE orderdetl.inv_qty, 
	lead_time LIKE product.days_lead_num 
END RECORD 

###########################################################################
# MAIN
#
#
###########################################################################
MAIN 

	#Initial UI Init
	CALL setModuleId("M51") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 


	IF num_args() > 0 THEN 
		LET pv_background = true 
	END IF 

	CALL mps_main() 

END MAIN 
###########################################################################
# END MAIN
###########################################################################


###########################################################################
# FUNCTION mps_main()
#
#
###########################################################################
FUNCTION mps_main() 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	 
	DEFINE 
	fv_month SMALLINT, 
	fv_date SMALLINT, 
	fv_hour SMALLINT, 
	fv_minute SMALLINT, 
	fv_input_ok SMALLINT, 
	fv_data_exists SMALLINT, 
	fv_ok SMALLINT, 
	fv_char_month CHAR(3), 
	fv_new_date DATE, 
	fv_runner CHAR(300), 
	fv_output CHAR(80) 


	IF pv_background THEN 
		LET pv_mps_plan = arg_val(1) 
		LET pv_mps_desc = arg_val(2) 
		LET pv_end_date = arg_val(3) 
		LET pv_fence_ind = arg_val(4) 
		LET pv_scrap_ind = arg_val(5) 

		LET pv_found_error = false 

		#------------------------------------------------------------
		LET l_rpt_idx = rpt_start("M51-BGR","M51_rpt_list_mps_background","N/A", RPT_SHOW_RMS_DIALOG)
		IF l_rpt_idx = 0 THEN #User pressed CANCEL
			RETURN FALSE
		END IF	
		START REPORT M51_rpt_list_mps_background TO rpt_get_report_file_with_path2(l_rpt_idx)
		WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
		TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
		BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
		LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
		RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
		#------------------------------------------------------------


		LET fv_ok = true 
		BEGIN WORK 

			WHENEVER ERROR CONTINUE 

			LOCK TABLE mps in exclusive MODE 

			IF status <> 0 THEN 
				LET pv_errormsg = "Someone ELSE IS running MPS AT the moment, ", 
				"wait until they have finished" 
				#---------------------------------------------------------
				OUTPUT TO REPORT M51_rpt_list_mps_background(l_rpt_idx,
				pv_errormsg) 
				#---------------------------------------------------------				
				LET pv_found_error = true 
				LET fv_ok = false 
				UNLOCK TABLE mps 
			END IF 

			IF NOT fv_ok THEN
				#------------------------------------------------------------
				FINISH REPORT M51_rpt_list_mps_background
				CALL rpt_finish("M51_rpt_list_mps_background")
				#------------------------------------------------------------			 
				RETURN 
			END IF 

			WHENEVER ERROR stop 

			CALL drop_table() 
			CALL create_table() 
			CALL generate_mps(pv_scrap_ind) RETURNING fv_data_exists 

			IF fv_data_exists THEN 
				CALL calc_ros(pv_scrap_ind) 
				CALL generate_ros(pv_scrap_ind) 
				CALL work_out_ros(pv_scrap_ind) 
			COMMIT WORK 
			CALL print_report(pv_fence_ind,pv_scrap_ind) 
		ELSE 
			LET pv_found_error = true 
			ROLLBACK WORK 
		END IF 

		#------------------------------------------------------------
		FINISH REPORT M51_rpt_list_mps_background
		CALL rpt_finish("M51_rpt_list_mps_background")
		#------------------------------------------------------------	

		CALL drop_table() 
		RETURN 
	END IF 

	OPEN WINDOW M134 with FORM "M134"
	CALL  windecoration_m("M134") -- albo kd-762 

	LET fv_ok = true 

	CALL kandoomenu("M", 141) RETURNING pr_menunames.* 
	MENU pr_menunames.menu_text 
		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 
		COMMAND pr_menunames.cmd1_code pr_menunames.cmd1_text 
			WHENEVER ERROR CONTINUE 
			BEGIN WORK 
				LOCK TABLE mps in exclusive MODE 

				IF status <> 0 THEN 
					LET msgresp = kandoomsg("M",9645,"") 				# ERROR "Someone ELSE running MPS wait until they have finished"
					SLEEP 3 
					LET fv_ok = false 
					EXIT program 
				END IF 

				DELETE FROM mpstable 

				WHENEVER ERROR stop 
				LET msgresp = kandoomsg("M",1518,"") 			# MESSAGE "Press ESC TO generate" attribute (yellow)

				DISPLAY "" at 2,1 
				CALL input_mps() RETURNING fv_input_ok 

				IF fv_input_ok THEN 
					{
					               OPEN WINDOW w0_working AT 16,8 with 3 rows,56 columns    -- albo  KD-762
					                   attributes (white,border)
					}
					LET fv_ok = true 
					CALL drop_table() 
					CALL create_table() 
					CALL generate_mps(pv_scrap_ind) RETURNING fv_data_exists 

					IF fv_data_exists THEN 
						CALL calc_ros(pv_scrap_ind) 
						CALL generate_ros(pv_scrap_ind) 
						CALL work_out_ros(pv_scrap_ind) 
					COMMIT WORK 
					CALL print_report(pv_fence_ind,pv_scrap_ind) 
					NEXT option pr_menunames.cmd4_code # "Print" 
				ELSE 
					ROLLBACK WORK 
				END IF 

				CALL drop_table() 
				--               CLOSE WINDOW w0_working      -- albo  KD-762
			END IF 

		COMMAND pr_menunames.cmd2_code pr_menunames.cmd2_text 
			WHENEVER ERROR CONTINUE 

			DELETE FROM mpstable 

			WHENEVER ERROR stop 
			LET msgresp = kandoomsg("M",1518,"") 
			# MESSAGE "Press ESC TO generate"
			DISPLAY "" at 2,1 
			CALL input_mps() RETURNING fv_input_ok 

			IF fv_input_ok THEN 
				LET fv_runner="fglrun M51.42r ", 
				"\"",pv_mps_plan CLIPPED,"\" ", 
				"\"",pv_mps_desc CLIPPED,"\" ", 
				"\"",pv_end_date using "dd/mm/yyyy","\" ", 
				"\"",pv_fence_ind CLIPPED,"\" ", 
				"\"",pv_scrap_ind CLIPPED,"\" ", 
				"\"",pv_prodgrp_code CLIPPED,"\" ", 
				"\"",pv_cat_code CLIPPED,"\" ", 
				"\"",pv_class_code CLIPPED,"\" & 2>&1" 
				RUN fv_runner 
			END IF 

			NEXT option pr_menunames.cmd5_code # "Exit" 

		COMMAND pr_menunames.cmd3_code pr_menunames.cmd3_text 
			LET msgresp = kandoomsg("M",1518,"") 
			# MESSAGE "Press ESC TO generate"
			DISPLAY "" at 2,1 
			CALL get_params() 
			RETURNING fv_input_ok, pv_mps_plan, pv_mrp_plan, pv_end_date, 
			pv_fence_ind, pv_scrap_ind, fv_month, fv_date, 
			fv_hour,fv_minute, fv_new_date 

			IF fv_input_ok THEN 
				LET fv_char_month = fv_new_date USING "MMM" 
				LET fv_runner= "at ",fv_hour USING "&&", 
				":",fv_minute USING "&&", 
				" ",fv_char_month , 
				" ",fv_date USING "&&", 
				"< ", 
				"fglrun M51.42R ", 
				"\"",pv_mps_plan CLIPPED,"\" ", 
				"\"",pv_mps_desc CLIPPED,"\" ", 
				"\"",pv_end_date using "dd/mm/yyyy","\" ", 
				"\"",pv_fence_ind CLIPPED,"\" ", 
				"\"",pv_scrap_ind CLIPPED,"\" ", 
				"\"",pv_prodgrp_code CLIPPED,"\" ", 
				"\"",pv_cat_code CLIPPED,"\" ", 
				"\"",pv_class_code CLIPPED,"\" & 2>&1" 
				RUN fv_runner 
			END IF 

			NEXT option pr_menunames.cmd5_code # "Exit" 

		ON ACTION "Print Manager" 
			#command pr_menunames.cmd4_code pr_menunames.cmd4_text
			CALL run_prog("URS", "", "", "", "") 
			NEXT option pr_menunames.cmd5_code # "Exit" 

		COMMAND pr_menunames.cmd5_code pr_menunames.cmd5_text 
			EXIT MENU 

		COMMAND KEY (interrupt) 
			EXIT MENU 
	END MENU 

	CLOSE WINDOW M134 

END FUNCTION 
###########################################################################
# END FUNCTION mps_main()
###########################################################################


###########################################################################
# FUNCTION input_mps()
#
#
###########################################################################
FUNCTION input_mps() 
	DEFINE fv_input_ok SMALLINT, 
	fv_count INTEGER 

	INITIALIZE pv_mps_plan, 
	pv_mps_desc, 
	pv_end_date, 
	pv_fence_ind, 
	pv_scrap_ind, 
	pv_factor_ind TO NULL 

	LET fv_input_ok = true 

	LET msgresp = kandoomsg("M",1519,"")	# MESSAGE "Enter MPS data AND press ESC TO continue"
	DISPLAY "" at 2,1 

	INPUT pv_mps_plan, 
	pv_mps_desc, 
	pv_end_date, 
	pv_fence_ind, 
	pv_scrap_ind, 
	pv_prodgrp_code, 
	pv_cat_code, 
	pv_class_code WITHOUT DEFAULTS 
	FROM plan_code, 
	desc_text, 
	end_date, 
	fence_ind, 
	scrap_ind, 
	prodgrp_code, 
	cat_code, 
	class_code 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD plan_code 
			SELECT unique count(*) 
			INTO fv_count 
			FROM mps 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND plan_code = pv_mps_plan 

			IF fv_count > 0 THEN 
				ERROR "" 
				--- modif ericv init # attributes (normal,white)
				LET msgresp = kandoomsg("M",4505,"") 
				# prompt "This schedule already exists, Do you want TO
				#         regenerate it (Y/N)?"

				IF msgresp = "N" THEN 
					NEXT FIELD plan_code 
				ELSE 
					DELETE FROM mps 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND plan_code = pv_mps_plan 

					DELETE FROM mpsdemand 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND plan_code = pv_mps_plan 
					AND type_text = "RO" 
				END IF 
			END IF 

		AFTER FIELD end_date 
			IF pv_end_date < today THEN 
				LET msgresp = kandoomsg("M",9646,"") 			# ERROR "The END date must be AFTER OR equal TO todays date"
				NEXT FIELD end_date 
			END IF 

		AFTER FIELD fence_ind 
			IF pv_fence_ind NOT matches "[OF]" THEN 
				LET msgresp = kandoomsg("M",9647,"") 			# ERROR "wrong code entered  "
				NEXT FIELD fence_ind 
			END IF 

		AFTER FIELD scrap_ind 
			IF pv_scrap_ind NOT matches "[SYBN]" THEN 
				LET msgresp = kandoomsg("M",9647,"") 			# ERROR "wrong code entered  "
				NEXT FIELD scrap_ind 
			END IF 

		AFTER FIELD prodgrp_code 
			IF pv_prodgrp_code IS NULL THEN 
				LET pv_prodgrp_code = "*" 
			ELSE 
				SELECT prodgrp_code 
				INTO pv_prodgrp_code 
				FROM prodgrp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND prodgrp_code = pv_prodgrp_code 

				IF status = notfound THEN 
					LET msgresp = kandoomsg("I",9011,"") 		# ERROR "Product Group NOT found - Try Window"
					NEXT FIELD prodgrp_code 
				END IF 
			END IF 

		AFTER FIELD cat_code 
			IF pv_cat_code IS NULL THEN 
				LET pv_cat_code = "*" 
			ELSE 
				SELECT cat_code 
				INTO pv_cat_code 
				FROM category 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cat_code = pv_cat_code 

				IF status = notfound THEN 
					LET msgresp = kandoomsg("I",9039,"") 			# ERROR "Product Category NOT found - Try Window"
					NEXT FIELD cat_code 
				END IF 
			END IF 

		AFTER FIELD class_code 
			IF pv_class_code IS NULL THEN 
				LET pv_class_code = "*" 
			ELSE 
				SELECT class_code 
				INTO pv_class_code 
				FROM class 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND class_code = pv_class_code 

				IF status = notfound THEN 
					LET msgresp = kandoomsg("I",9041,"") 		# ERROR "Inventory Class NOT found - Try Window"
					NEXT FIELD class_code 
				END IF 
			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 

			IF pv_mps_plan IS NULL THEN 
				LET msgresp = kandoomsg("M",9648,"") 		# ERROR "A plan code must be entered"
				NEXT FIELD plan_code 
			ELSE 
				SELECT unique count(*) 
				INTO fv_count 
				FROM mps 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND plan_code = pv_mps_plan 

				IF fv_count > 0 THEN 
					LET msgresp = kandoomsg("M",9649,"") 			# ERROR "plan code entered already exists in the DATABASE"
					NEXT FIELD plan_code 
				END IF 
			END IF 

			IF pv_end_date IS NULL THEN 
				LET msgresp = kandoomsg("M",9650,"") 	# ERROR "A date must be entered"
				NEXT FIELD end_date 
			ELSE 
				IF pv_end_date < today THEN 
					LET msgresp = kandoomsg("M",9646,"") 		# ERROR "The END date must be AFTER OR equal TO todays date"
					NEXT FIELD end_date 
				END IF 
			END IF 
	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET fv_input_ok = false 
		LET msgresp = kandoomsg("M",9651,"") # ERROR "Generation Aborted"
	END IF 

	RETURN fv_input_ok 

END FUNCTION 
###########################################################################
# END FUNCTION input_mps()
###########################################################################


###########################################################################
# FUNCTION get_params()
#
#
###########################################################################
FUNCTION get_params() 

	DEFINE 
	fv_month SMALLINT, 
	fv_date SMALLINT, 
	fv_hour SMALLINT, 
	fv_minute SMALLINT, 
	fv_curr_month SMALLINT, 
	fv_year SMALLINT, 
	fv_new_date INTEGER, 
	fv_input_ok SMALLINT, 
	fv_count INTEGER 


	LET fv_input_ok = true 

	OPEN WINDOW M144 with FORM "M144" 
	CALL  windecoration_m("M144") -- albo kd-762 

	LET msgresp = kandoomsg("M",1505,"") 
	# MESSAGE "ESC TO accept DEL TO EXIT"

	INITIALIZE 
	pv_mps_plan, 
	pv_mrp_plan, 
	pv_end_date, 
	pv_fence_ind, 
	pv_scrap_ind, 
	fv_month, 
	fv_date, 
	fv_hour, 
	fv_minute 
	TO NULL 

	INPUT 
	pv_mps_plan, pv_mrp_plan, 
	pv_end_date, pv_fence_ind, 
	pv_scrap_ind, fv_month, 
	fv_date, fv_hour, 
	fv_minute 
	WITHOUT DEFAULTS 
	FROM 
	schedule_code, plan_code, 
	end_date, fence_ind, 
	scrap_ind, date_month, 
	date_date, time_hour, 
	time_minute 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD schedule_code 
			SELECT unique count(*) 
			INTO fv_count 
			FROM mps 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND plan_code = pv_mps_plan 

			IF fv_count > 0 THEN 
				ERROR "" 
				--- modif ericv init # ATTRIBUTE(normal,white)
				LET msgresp = kandoomsg("M",4505,"") 
				# prompt "This schedule already exists, Do you want TO
				#         regenerate it (Y/N)?"

				IF msgresp = "N" THEN 
					NEXT FIELD schedule_code 
				ELSE 
					DELETE FROM mps 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND plan_code = pv_mps_plan 
				END IF 
			END IF 

		AFTER FIELD plan_code 
			SELECT unique count(*) 
			INTO fv_count 
			FROM mrp 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND plan_code = pv_mrp_plan 

			IF fv_count > 0 THEN 
				ERROR "" 
				--- modif ericv init # ATTRIBUTE(normal,white)
				LET msgresp = kandoomsg("M",4506,"") 
				# prompt "This plan already exists, Do you want TO regenerate
				#         it (Y/N)?"

				IF msgresp = "Y" THEN 
					DELETE FROM mrp 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND plan_code = pv_mrp_plan 
				ELSE 
					NEXT FIELD plan_code 
				END IF 
			END IF 

		AFTER FIELD end_date 
			IF pv_end_date < today THEN 
				LET msgresp = kandoomsg("M",9646,"") 
				# ERROR "The END date must be AFTER OR equal TO todays date"
				NEXT FIELD end_date 
			END IF 

		AFTER FIELD date_month 
			IF fv_month IS NULL THEN 
				LET msgresp = kandoomsg("M",9652,"") 
				# ERROR "A value must be entered in this field"
				NEXT FIELD date_month 
			ELSE 
				IF fv_month < 1 
				OR fv_month > 12 THEN 
					LET msgresp = kandoomsg("M",9653,"") 
					# ERROR "An invalid month value was entered"
					NEXT FIELD date_month 
				END IF 
			END IF 

		AFTER FIELD date_date 
			IF fv_date IS NULL THEN 
				LET msgresp = kandoomsg("M",9652,"") 
				# ERROR "A value must be entered in this field"
				NEXT FIELD date_date 
			ELSE 
				LET fv_curr_month = month(today) 
				LET fv_year = year(today) 

				IF fv_month < fv_curr_month THEN 
					LET fv_year = fv_year + 1 
				END IF 

				WHENEVER ERROR CONTINUE 
				LET fv_new_date = mdy(fv_month,fv_date,fv_year) 

				IF status <> 0 THEN 
					LET msgresp = kandoomsg("M",9654,"") 
					# ERROR "This date IS invalid"
					NEXT FIELD date_month 
				END IF 

				WHENEVER ERROR stop 
			END IF 

		AFTER FIELD time_hour 
			IF fv_hour IS NULL THEN 
				LET msgresp = kandoomsg("M",9652,"") 
				# ERROR "A value must be entered in this field"
				NEXT FIELD time_hour 
			ELSE 
				IF fv_hour < 0 
				OR fv_hour > 23 THEN 
					LET msgresp = kandoomsg("M",9655,"") 
					# ERROR "An invalid value was entered FOR the hours"
					NEXT FIELD time_hour 
				END IF 
			END IF 

		AFTER FIELD time_minute 
			IF fv_minute IS NULL THEN 
				LET msgresp = kandoomsg("M",9652,"") 
				# ERROR "A value must be entered in this field"
				NEXT FIELD time_minute 
			ELSE 
				IF fv_minute < 0 
				OR fv_minute > 59 THEN 
					LET msgresp = kandoomsg("M",9656,"") 
					# ERROR "An invalid value was entered FOR the minutes"
					NEXT FIELD time_minute 
				END IF 
			END IF 
	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET fv_month = NULL 
		LET fv_date = NULL 
		LET fv_hour = NULL 
		LET fv_minute = NULL 
		LET fv_input_ok = false 
		LET msgresp = kandoomsg("M",9657,"") 	# ERROR "Data Entery Aborted"
	END IF 

	CLOSE WINDOW M144 

	RETURN fv_input_ok, pv_mps_plan, pv_mrp_plan, pv_end_date, pv_fence_ind, 
	pv_scrap_ind, fv_month, fv_date, fv_hour,fv_minute, fv_new_date 

END FUNCTION 
###########################################################################
# END UNCTION get_params()
###########################################################################


###########################################################################
# FUNCTION generate_mps(fv_scrap_ind)
#
#
###########################################################################
FUNCTION generate_mps(fv_scrap_ind) 

	DEFINE 
	fv_start_date DATE, 
	fv_type CHAR(2), 
	fv_scrap_ind CHAR(1), 
	fv_lead_time INTEGER, 
	fv_parent_cnt SMALLINT, 
	fv_cnt SMALLINT, 
	fv_calc_qty LIKE shoporddetl.required_qty, 
	fv_type_code LIKE prodmfg.part_type_ind, 
	fv_mps_ind LIKE prodmfg.mps_ind, 
	fv_req_qty LIKE shoporddetl.required_qty, 
	fv_order_type_ind LIKE shopordhead.order_type_ind, 
	fv_prodgrp_code LIKE product.prodgrp_code, 
	fv_cat_code LIKE product.cat_code, 
	fv_class_code LIKE product.class_code, 
	fv_count SMALLINT, 
	unexploded_subs SMALLINT, 
	no_phantoms SMALLINT, 
	fv_man_lead LIKE product.days_lead_num 


	DELETE FROM mps 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND plan_code = pv_mps_plan 

	### First run through AND get all shop orders AND forecast orders

	DECLARE rough_orders CURSOR FOR 
	SELECT * 
	FROM shopordhead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND order_type_ind matches "[FOS]" 
	AND status_ind <> "C" 
	AND (start_date >= today 
	OR (start_date < today 
	AND receipted_qty < order_qty)) 
	AND end_date <= pv_end_date 
	ORDER BY part_code, end_date 

	FOREACH rough_orders INTO pr_shopordhead.* 
		IF NOT pv_background THEN 
			CALL working("Shop Orders ",pr_shopordhead.shop_order_num) 
		END IF 

		SELECT * 
		INTO pr_prodmfg.* 
		FROM prodmfg 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = pr_shopordhead.part_code 
		AND part_type_ind matches "[MG]" 

		IF status != 0 THEN 
			CONTINUE FOREACH 
		END IF 

		IF pr_prodmfg.mps_ind != "Y" THEN 
			CONTINUE FOREACH 
		END IF 

		SELECT * 
		INTO pr_product.* 
		FROM product 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = pr_shopordhead.part_code 

		IF status != 0 THEN 
			CONTINUE FOREACH 
		END IF 

		IF pv_prodgrp_code != "*" 
		AND pr_product.prodgrp_code != pv_prodgrp_code THEN 
			CONTINUE FOREACH 
		END IF 

		IF pv_cat_code != "*" 
		AND pr_product.cat_code != pv_cat_code THEN 
			CONTINUE FOREACH 
		END IF 

		IF pv_class_code != "*" 
		AND pr_product.class_code != pv_class_code THEN 
			CONTINUE FOREACH 
		END IF 

		LET pv_demand_fence = today + pr_prodmfg.demand_fence_num 

		IF (pv_fence_ind = "O" 
		AND pr_shopordhead.order_type_ind = "F" 
		AND pr_shopordhead.start_date > pv_demand_fence) 
		OR (pr_shopordhead.order_type_ind matches "[SO]") 
		OR (pv_fence_ind = "F") 
		AND pr_shopordhead.order_qty IS NOT NULL THEN 

			LET fv_start_date = pr_shopordhead.start_date 

			IF pr_shopordhead.order_type_ind matches "[SO]" THEN 
				LET fv_type = "AO" 
			ELSE 
				LET fv_type = "FO" 
			END IF 

			IF pr_shopordhead.receipted_qty IS NULL THEN 
				LET pr_shopordhead.receipted_qty = 0 
			END IF 

			IF pr_shopordhead.rejected_qty IS NULL THEN 
				LET pr_shopordhead.rejected_qty = 0 
			END IF 

			LET fv_calc_qty = pr_shopordhead.order_qty - 
			(pr_shopordhead.receipted_qty + 
			pr_shopordhead.rejected_qty) 

			CASE 
				WHEN pr_prodmfg.man_stk_con_qty IS NULL 
					LET pr_prodmfg.man_stk_con_qty = 1 
				WHEN pr_product.pur_stk_con_qty IS NULL 
					LET pr_product.pur_stk_con_qty = 1 
				WHEN pr_product.stk_sel_con_qty IS NULL 
					LET pr_product.stk_sel_con_qty = 1 
			END CASE 

			CASE 
				WHEN pr_shopordhead.uom_code = pr_product.stock_uom_code 
					LET fv_calc_qty = fv_calc_qty / pr_prodmfg.man_stk_con_qty 
				WHEN pr_shopordhead.uom_code = pr_product.pur_uom_code 
					LET fv_calc_qty = fv_calc_qty * pr_product.pur_stk_con_qty 
					LET fv_calc_qty = fv_calc_qty / pr_prodmfg.man_stk_con_qty 
				WHEN pr_shopordhead.uom_code = pr_product.sell_uom_code 
					LET fv_calc_qty = fv_calc_qty / pr_product.stk_sel_con_qty 
					LET fv_calc_qty = fv_calc_qty / pr_prodmfg.man_stk_con_qty 
			END CASE 

			INSERT INTO mps 
			VALUES (glob_rec_kandoouser.cmpy_code, 
			pv_mps_plan, 
			pr_shopordhead.part_code, 
			pr_shopordhead.part_code, 
			pr_shopordhead.start_date, 
			pr_shopordhead.end_date, 
			pv_mps_desc, 
			fv_type, 
			pr_shopordhead.order_type_ind, 
			fv_calc_qty, 
			pr_shopordhead.shop_order_num, 
			today, 
			glob_rec_kandoouser.sign_on_code, 
			"M51") 

			IF pr_shopordhead.order_type_ind matches "[SO]" THEN 
				LET fv_lead_time = pr_product.days_lead_num 

				IF fv_lead_time IS NULL THEN 
					LET fv_lead_time = 0 
				END IF 

				IF pr_prodmfg.part_type_ind = "M" THEN 
					CALL get_next_level_so(pr_shopordhead.shop_order_num, 
					pr_shopordhead.part_code, 
					fv_lead_time, 
					pr_shopordhead.start_date, 
					pr_shopordhead.order_type_ind, 
					fv_scrap_ind) 
				ELSE 
					CALL get_next_level_gen(pr_mps.reference_num, 
					pr_shopordhead.part_code, 
					fv_lead_time, 
					pr_shopordhead.start_date, 
					pr_shopordhead.order_qty, 
					fv_type) 
				END IF 
			END IF 
		END IF 
	END FOREACH 

	### First get all sales orders FOR given period irrespective
	### of whether part IS a manufacturing one OR NOT

	DECLARE cust_orders CURSOR FOR 
	SELECT orderhead.order_date, orderhead.order_num, orderhead.cust_code, 
	orderdetl.part_code, orderdetl.uom_code, orderdetl.order_qty, 
	orderdetl.inv_qty, product.days_lead_num 
	FROM orderhead, orderdetl, product 
	WHERE orderhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND orderdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND product.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND orderdetl.order_num = orderhead.order_num 
	AND orderdetl.cust_code = orderhead.cust_code 
	AND orderhead.order_date <= pv_end_date 
	AND orderhead.status_ind != "C" 
	AND orderdetl.order_qty > orderdetl.inv_qty 
	AND product.part_code = orderdetl.part_code 

	LET fv_count = 0 

	FOREACH cust_orders INTO pr_cust_ord.* 
		IF NOT pv_background THEN 
			CALL working("Customer Orders ",pr_cust_ord.part_code) 
		END IF 

		SELECT prodgrp_code, cat_code, class_code 
		INTO fv_prodgrp_code, fv_cat_code, fv_class_code 
		FROM product 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = pr_cust_ord.part_code 

		IF pv_prodgrp_code != "*" 
		AND fv_prodgrp_code != pv_prodgrp_code THEN 
			CONTINUE FOREACH 
		END IF 

		IF pv_cat_code != "*" 
		AND fv_cat_code != pv_cat_code THEN 
			CONTINUE FOREACH 
		END IF 

		IF pv_class_code != "*" 
		AND fv_class_code != pv_class_code THEN 
			CONTINUE FOREACH 
		END IF 

		IF pr_cust_ord.lead_time IS NULL THEN 
			LET pr_cust_ord.lead_time = 1 
		END IF 

		LET fv_req_qty = pr_cust_ord.order_qty - pr_cust_ord.inv_qty 

		SELECT * 
		INTO pr_prodmfg.* 
		FROM prodmfg 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = pr_cust_ord.part_code 

		SELECT part_type_ind, mps_ind 
		INTO fv_type_code, fv_mps_ind 
		FROM prodmfg 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = pr_cust_ord.part_code 

		IF status = notfound THEN 
			LET fv_type_code = "X" 
		END IF 

		IF fv_mps_ind != "Y" THEN 
			CONTINUE FOREACH 
		END IF 

		SELECT days_lead_num 
		INTO fv_man_lead 
		FROM product 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = pr_cust_ord.part_code 

		IF fv_man_lead IS NULL THEN 
			LET fv_man_lead = 0 
		END IF 

		LET pv_demand_fence = today + pr_prodmfg.demand_fence_num 

		IF fv_type_code matches "[GMP]" THEN 
			LET fv_type = "CO" 
			LET fv_start_date = get_cal_date(pr_cust_ord.due_date, 
			fv_man_lead, 
			"B") 
		ELSE 
			LET fv_start_date = get_cal_date(pr_cust_ord.due_date, 
			pr_cust_ord.lead_time, 
			"B") 
			LET fv_type = "CX" 
		END IF 

		IF (pv_fence_ind = "O" 
		AND fv_start_date <= pv_demand_fence) 
		OR (pv_fence_ind = "F" 
		AND fv_start_date < today) THEN 

			CASE 
				WHEN pr_prodmfg.man_stk_con_qty IS NULL 
					LET pr_prodmfg.man_stk_con_qty = 1 
				WHEN pr_product.pur_stk_con_qty IS NULL 
					LET pr_product.pur_stk_con_qty = 1 
				WHEN pr_product.stk_sel_con_qty IS NULL 
					LET pr_product.stk_sel_con_qty = 1 
			END CASE 

			CASE 
				WHEN pr_cust_ord.uom_code = pr_product.stock_uom_code 
					LET fv_req_qty = fv_req_qty / pr_prodmfg.man_stk_con_qty 
				WHEN pr_cust_ord.uom_code = pr_product.pur_uom_code 
					LET fv_req_qty = fv_req_qty * pr_product.pur_stk_con_qty 
					LET fv_req_qty = fv_req_qty / pr_prodmfg.man_stk_con_qty 
				WHEN pr_cust_ord.uom_code = pr_product.sell_uom_code 
					LET fv_req_qty = fv_req_qty / pr_product.stk_sel_con_qty 
					LET fv_req_qty = fv_req_qty / pr_prodmfg.man_stk_con_qty 
			END CASE 

			INSERT INTO mps 
			VALUES (glob_rec_kandoouser.cmpy_code, 
			pv_mps_plan, 
			pr_cust_ord.part_code, 
			pr_cust_ord.part_code, 
			fv_start_date, 
			pr_cust_ord.due_date, 
			pv_mps_desc, 
			fv_type, 
			"C", 
			fv_req_qty, 
			pr_cust_ord.order_num, 
			today, 
			glob_rec_kandoouser.sign_on_code, 
			"M51") 
		END IF 

		LET fv_count = fv_count + 1 
	END FOREACH 

	LET unexploded_subs = false 
	LET no_phantoms = false 

	WHILE NOT (no_phantoms AND unexploded_subs) 
		DECLARE phan_curs CURSOR FOR 
		SELECT rowid, * 
		FROM mps 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND plan_code = pv_mps_plan 
		AND (type_text = "GE" 
		OR type_text = "US" 
		OR type_text = "UP") 

		LET fv_count = 0 

		FOREACH phan_curs INTO pv_rowid, pr_mps.* 
			IF NOT pv_background THEN 
				CASE 
					WHEN pr_mps.type_text = "UP" 
						CALL working("Replacing Phantoms ",pr_mps.part_code) 
					WHEN pr_mps.type_text = "GE" 
						CALL working("Replacing Generics ",pr_mps.part_code) 
					OTHERWISE 
						CALL working("Exploding Sub Assemblies ", 
						pr_mps.part_code) 
				END CASE 
			END IF 

			LET fv_count = fv_count + 1 

			SELECT days_lead_num 
			INTO fv_lead_time 
			FROM product 
			WHERE cmpy_code = pr_mps.cmpy_code 
			AND part_code = pr_mps.part_code 

			IF fv_lead_time IS NULL THEN 
				LET fv_lead_time = 0 
			END IF 

			CASE 
				WHEN pr_mps.type_text = "UP" 
					LET fv_cnt = 0 
					LET fv_parent_cnt = 0 

					CALL get_next_level_bor(pr_mps.reference_num, 
					pr_mps.part_code, 
					fv_lead_time, 
					pr_mps.start_date, 
					pr_mps.required_qty, 
					fv_order_type_ind, 
					fv_scrap_ind) 

				WHEN pr_mps.type_text = "GE" 
					CALL get_next_level_gen(pr_mps.reference_num, 
					pr_mps.part_code, 
					fv_lead_time, 
					pr_mps.start_date, 
					pr_mps.required_qty, 
					#                                            pr_mps.order_type_ind)
					pr_mps.order_type_code) 
			END CASE 

			#do NOT delete phantom records
			IF pr_mps.type_text != "UP" THEN 
				DELETE FROM mps 
				WHERE rowid = pv_rowid 
				LET fv_count = fv_count - 1 
			ELSE 
				LET fv_count = fv_count - 1 
			END IF 

		END FOREACH 

		IF fv_count = 0 THEN 
			LET no_phantoms = true 
			LET unexploded_subs = true 
		END IF 
	END WHILE 

	RETURN true 

END FUNCTION 
###########################################################################
# END FUNCTION generate_mps(fv_scrap_ind)
###########################################################################


###########################################################################
# FUNCTION get_next_level_so(fv_shop_order_num, fv_part_code, fv_par_lead_time,
#
#
###########################################################################
FUNCTION get_next_level_so(fv_shop_order_num, fv_part_code, fv_par_lead_time, 
	fv_par_start_date, fv_order_type_ind, fv_scrap_ind) 

	DEFINE 
	fv_shop_order_num LIKE shopordhead.shop_order_num, 
	fv_part_code LIKE shopordhead.part_code, 
	fv_order_type_ind LIKE shopordhead.order_type_ind, 
	fv_par_lead_time INTEGER, 
	fv_type CHAR(2), 
	fv_scrap_ind CHAR(1), 
	fv_par_start_date DATE, 
	fv_start_date DATE, 
	fv_due_date DATE, 
	fv_scrap_qty LIKE shoporddetl.required_qty, 
	fv_yield_qty LIKE shoporddetl.required_qty, 
	fv_calc_qty LIKE shoporddetl.required_qty 


	DECLARE rough_assemblies CURSOR FOR 
	SELECT * 
	FROM shoporddetl 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND shop_order_num = fv_shop_order_num 
	AND required_qty > 0 

	FOREACH rough_assemblies INTO pr_shoporddetl.* 

		SELECT * 
		INTO pr_prodmfg.* 
		FROM prodmfg 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = pr_shoporddetl.part_code 
		AND part_type_ind matches "[MGP]" 

		IF status != 0 THEN 
			CONTINUE FOREACH 
		END IF 

		SELECT * 
		INTO pr_product.* 
		FROM product 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = pr_prodmfg.part_code 

		IF status != 0 THEN 
			CONTINUE FOREACH 
		END IF 

		IF NOT pv_background THEN 
			CALL working("Sub Assemblies ",pr_shoporddetl.part_code) 
		END IF 

		CASE 
			WHEN pr_prodmfg.part_type_ind = "P" 
				LET fv_type = "UP" 
			WHEN pr_prodmfg.part_type_ind = "G" 
				LET fv_type = "GE" 
			WHEN pr_prodmfg.part_type_ind = "M" 
				LET fv_type = "SS" 
		END CASE 

		IF pr_product.days_lead_num IS NULL THEN 
			LET pr_product.days_lead_num = 0 
		END IF 

		LET fv_due_date = get_cal_date(fv_par_start_date, 
		0, 
		"F") 

		IF pr_prodmfg.part_type_ind = "P" THEN 
			LET fv_start_date = fv_due_date 
		ELSE 
			LET fv_start_date = get_cal_date(fv_due_date, 
			pr_product.days_lead_num, 
			"B") 
		END IF 

		IF pr_shoporddetl.required_qty IS NULL THEN 
			LET pr_shoporddetl.required_qty = 0 
		END IF 

		IF pr_shoporddetl.issued_qty IS NULL THEN 
			LET pr_shoporddetl.issued_qty = 0 
		END IF 

		LET fv_calc_qty = pr_shoporddetl.required_qty -pr_shoporddetl.issued_qty 

		IF pr_prodmfg.scrap_per IS NOT NULL 
		AND pr_prodmfg.scrap_per > 0 THEN 
			LET fv_scrap_qty = (fv_calc_qty * pr_prodmfg.scrap_per) / 100 
		END IF 

		IF pr_prodmfg.yield_per IS NOT NULL 
		AND pr_prodmfg.yield_per > 0 THEN 
			LET fv_yield_qty = 100 / pr_prodmfg.yield_per 
			LET fv_yield_qty = (fv_calc_qty * fv_yield_qty) - fv_calc_qty 
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

		IF fv_order_type_ind = "F" THEN 
			LET fv_calc_qty = fv_calc_qty + fv_scrap_qty + fv_yield_qty 
		END IF 

		IF fv_order_type_ind = "F" 
		AND fv_type = "SS" THEN 
			LET fv_type = "FS" 
		END IF 

		CASE 
			WHEN pr_prodmfg.man_stk_con_qty IS NULL 
				LET pr_prodmfg.man_stk_con_qty = 1 
			WHEN pr_product.pur_stk_con_qty IS NULL 
				LET pr_product.pur_stk_con_qty = 1 
			WHEN pr_product.stk_sel_con_qty IS NULL 
				LET pr_product.stk_sel_con_qty = 1 
		END CASE 

		CASE 
			WHEN pr_shoporddetl.uom_code = pr_product.stock_uom_code 
				LET fv_calc_qty = fv_calc_qty / pr_prodmfg.man_stk_con_qty 
			WHEN pr_shoporddetl.uom_code = pr_product.pur_uom_code 
				LET fv_calc_qty = fv_calc_qty * pr_product.pur_stk_con_qty 
				LET fv_calc_qty = fv_calc_qty / pr_prodmfg.man_stk_con_qty 
			WHEN pr_shoporddetl.uom_code = pr_product.sell_uom_code 
				LET fv_calc_qty = fv_calc_qty / pr_product.stk_sel_con_qty 
				LET fv_calc_qty = fv_calc_qty / pr_prodmfg.man_stk_con_qty 
		END CASE 

		IF fv_calc_qty <> 0 THEN 
			SELECT * 
			INTO pr_mps.* 
			FROM mps 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND plan_code = pv_mps_plan 
			AND parent_part_code = pr_shopordhead.part_code 
			AND part_code = pr_shoporddetl.part_code 
			AND start_date = fv_start_date 
			AND due_date = fv_due_date 
			AND type_text = fv_type 
			AND order_type_ind = fv_order_type_ind 
			AND reference_num = fv_shop_order_num 

			IF status != 0 THEN 
				INSERT INTO mps VALUES (glob_rec_kandoouser.cmpy_code, 
				pv_mps_plan, 
				pr_shopordhead.part_code, 
				pr_shoporddetl.part_code, 
				fv_start_date, 
				fv_due_date, 
				pv_mps_desc, 
				fv_type, 
				fv_order_type_ind, 
				fv_calc_qty, 
				fv_shop_order_num, 
				today, 
				glob_rec_kandoouser.sign_on_code, 
				"M51") 
			ELSE 
				UPDATE mps 
				SET required_qty = required_qty + fv_calc_qty 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND plan_code = pv_mps_plan 
				AND parent_part_code = pr_shopordhead.part_code 
				AND part_code = pr_shoporddetl.part_code 
				AND start_date = fv_start_date 
				AND due_date = fv_due_date 
				AND type_text = fv_type 
				AND order_type_ind = fv_order_type_ind 
				AND reference_num = fv_shop_order_num 
			END IF 
		END IF 
	END FOREACH 

END FUNCTION 
###########################################################################
# END FUNCTION get_next_level_so(fv_shop_order_num, fv_part_code, fv_par_lead_time,
###########################################################################


###########################################################################
# FUNCTION get_next_level_bor(fv_shop_order_num,
#
#
###########################################################################
FUNCTION get_next_level_bor(fv_shop_order_num, 
	fv_part_code, 
	fv_par_lead_time, 
	fv_par_start_date, 
	fv_par_qty, 
	fv_order_type, 
	fv_scrap_ind) 

	DEFINE 
	fv_shop_order_num LIKE shopordhead.shop_order_num, 
	fv_part_code LIKE shopordhead.part_code, 
	fv_par_lead_time INTEGER, 
	fv_lead_time INTEGER, 
	fv_type CHAR(2), 
	fv_par_start_date DATE, 
	fv_start_date DATE, 
	fv_due_date DATE, 
	fv_scrap_ind CHAR(1), 
	fv_par_qty LIKE shoporddetl.required_qty, 
	fv_scrap_qty LIKE shoporddetl.required_qty, 
	fv_yield_qty LIKE shoporddetl.required_qty, 
	fv_calc_qty LIKE shoporddetl.required_qty, 
	fv_order_type CHAR(1) 


	DECLARE rough_bor_ass CURSOR FOR 
	SELECT * 
	FROM bor 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parent_part_code = fv_part_code 

	FOREACH rough_bor_ass INTO pr_bor.* 
		IF pr_bor.start_date > fv_par_start_date 
		OR pr_bor.end_date < fv_par_start_date THEN 
			CONTINUE FOREACH 
		END IF 

		SELECT * 
		INTO pr_prodmfg.* 
		FROM prodmfg 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = pr_bor.part_code 
		AND part_type_ind matches "[GMP]" 

		IF status != 0 THEN 
			CONTINUE FOREACH 
		END IF 

		IF pr_prodmfg.mps_ind != "Y" THEN 
			CONTINUE FOREACH 
		END IF 

		SELECT * 
		INTO pr_product.* 
		FROM product 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = pr_prodmfg.part_code 

		IF status != 0 THEN 
			CONTINUE FOREACH 
		END IF 

		IF NOT pv_background THEN 
			CALL working("Sub Assemblies ",pr_bor.part_code) 
		END IF 

		IF pr_prodmfg.part_type_ind = "P" THEN 
			LET fv_type = "UP" 
		ELSE 
			LET fv_type = "SS" 
		END IF 

		IF fv_order_type = "F" 
		AND fv_type = "SS" THEN 
			LET fv_type = "FS" 
		END IF 

		IF pr_product.days_lead_num IS NULL THEN 
			LET fv_lead_time = 0 
		ELSE 
			LET fv_lead_time = pr_product.days_lead_num 
		END IF 

		LET fv_due_date = get_cal_date(fv_par_start_date, 
		0, 
		"F") 

		IF pr_prodmfg.part_type_ind = "P" THEN 
			LET fv_start_date = fv_due_date 
		ELSE 
			LET fv_start_date = get_cal_date(fv_due_date, 
			fv_lead_time, 
			"B") 
		END IF 

		LET fv_calc_qty = pr_bor.required_qty * fv_par_qty 
		LET fv_yield_qty = 0 
		LET fv_scrap_qty = 0 

		IF pr_prodmfg.scrap_per IS NOT NULL 
		AND pr_prodmfg.scrap_per > 0 THEN 
			LET fv_scrap_qty = (fv_calc_qty * pr_prodmfg.scrap_per) / 100 
		END IF 

		IF pr_prodmfg.yield_per IS NOT NULL 
		AND pr_prodmfg.yield_per > 0 THEN 
			LET fv_yield_qty = 100 / pr_prodmfg.yield_per 
			LET fv_yield_qty = (fv_calc_qty * fv_yield_qty) - fv_calc_qty 
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

		IF fv_order_type = "C" 
		AND fv_type != "UP" THEN 
			LET fv_type = "CS" 
		END IF 

		IF fv_order_type = "F" 
		AND fv_type != "UP" THEN 
			LET fv_type = "FS" 
		END IF 

		CASE 
			WHEN pr_prodmfg.man_stk_con_qty IS NULL 
				LET pr_prodmfg.man_stk_con_qty = 1 
			WHEN pr_product.pur_stk_con_qty IS NULL 
				LET pr_product.pur_stk_con_qty = 1 
			WHEN pr_product.stk_sel_con_qty IS NULL 
				LET pr_product.stk_sel_con_qty = 1 
		END CASE 

		CASE 
			WHEN pr_bor.uom_code = pr_product.stock_uom_code 
				LET fv_calc_qty = fv_calc_qty / pr_prodmfg.man_stk_con_qty 
			WHEN pr_bor.uom_code = pr_product.pur_uom_code 
				LET fv_calc_qty = fv_calc_qty * pr_product.pur_stk_con_qty 
				LET fv_calc_qty = fv_calc_qty / pr_prodmfg.man_stk_con_qty 
			WHEN pr_bor.uom_code = pr_product.sell_uom_code 
				LET fv_calc_qty = fv_calc_qty / pr_product.stk_sel_con_qty 
				LET fv_calc_qty = fv_calc_qty / pr_prodmfg.man_stk_con_qty 
		END CASE 

		SELECT * 
		INTO pr_mps.* 
		FROM mps 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND plan_code = pv_mps_plan 
		AND parent_part_code = pr_bor.parent_part_code 
		AND part_code = pr_bor.part_code 
		AND start_date = fv_start_date 
		AND due_date = fv_due_date 
		AND type_text = fv_type 
		AND order_type_ind = fv_order_type 
		AND reference_num = fv_shop_order_num 

		IF status != 0 THEN 
			INSERT INTO mps VALUES (glob_rec_kandoouser.cmpy_code, 
			pv_mps_plan, 
			pr_bor.parent_part_code, 
			pr_bor.part_code, 
			fv_start_date, 
			fv_due_date, 
			pv_mps_desc, 
			fv_type, 
			fv_order_type, 
			fv_calc_qty, 
			fv_shop_order_num, 
			today, 
			glob_rec_kandoouser.sign_on_code, 
			"M51") 
		ELSE 
			UPDATE mps 
			SET required_qty = required_qty + fv_calc_qty 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND plan_code = pv_mps_plan 
			AND parent_part_code = pr_bor.parent_part_code 
			AND part_code = pr_bor.part_code 
			AND start_date = fv_start_date 
			AND due_date = fv_due_date 
			AND type_text = fv_type 
			AND order_type_ind = fv_order_type 
			AND reference_num = fv_shop_order_num 
		END IF 

		IF fv_type = "SS" 
		OR fv_type = "FS" 
		OR fv_type = "CS" THEN 
			SELECT * 
			INTO pr_mps.* 
			FROM mps 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND plan_code = pv_mps_plan 
			AND parent_part_code = pr_bor.parent_part_code 
			AND part_code = pr_bor.part_code 
			AND start_date = fv_start_date 
			AND due_date = fv_due_date 
			AND type_text = "US" 
			AND order_type_ind = fv_order_type 
			AND reference_num = fv_shop_order_num 

			IF status != 0 THEN 
				INSERT INTO mps VALUES (glob_rec_kandoouser.cmpy_code, 
				pv_mps_plan, 
				pr_bor.parent_part_code, 
				pr_bor.part_code, 
				fv_start_date, 
				fv_due_date, 
				pv_mps_desc, 
				"US", 
				fv_order_type, 
				fv_calc_qty, 
				fv_shop_order_num, 
				today, 
				glob_rec_kandoouser.sign_on_code, 
				"M51") 
			ELSE 
				UPDATE mps 
				SET required_qty = required_qty + fv_calc_qty 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND plan_code = pv_mps_plan 
				AND parent_part_code = pr_bor.parent_part_code 
				AND part_code = pr_bor.part_code 
				AND start_date = fv_start_date 
				AND due_date = fv_due_date 
				AND type_text = "US" 
				AND order_type_ind = fv_order_type 
				AND reference_num = fv_shop_order_num 
			END IF 
		END IF 
	END FOREACH 

END FUNCTION 
###########################################################################
# END FUNCTION get_next_level_bor(fv_shop_order_num,
###########################################################################


###########################################################################
# FUNCTION get_next_level_ros(fv_shop_order_num, 
#	fv_part_code, 
#	fv_par_lead_time, 
#	fv_par_start_date, 
#	fv_par_qty, 
#	fv_order_type, 
#	fv_scrap_ind) 
#
#
#
###########################################################################
FUNCTION get_next_level_ros(fv_shop_order_num, 
	fv_part_code, 
	fv_par_lead_time, 
	fv_par_start_date, 
	fv_par_qty, 
	fv_order_type, 
	fv_scrap_ind) 

	DEFINE 
	pr_mps RECORD LIKE mps.*, 
	fv_shop_order_num LIKE shopordhead.shop_order_num, 
	fv_part_code LIKE shopordhead.part_code, 
	fv_par_lead_time INTEGER, 
	fv_lead_time INTEGER, 
	fv_type CHAR(2), 
	fv_par_start_date DATE, 
	fv_start_date DATE, 
	fv_due_date DATE, 
	fv_scrap_ind CHAR(1), 
	fv_par_qty LIKE shoporddetl.required_qty, 
	fv_scrap_qty LIKE shoporddetl.required_qty, 
	fv_yield_qty LIKE shoporddetl.required_qty, 
	fv_calc_qty LIKE shoporddetl.required_qty, 
	fv_order_type CHAR(1) 


	DECLARE ros_bor_ass CURSOR FOR 
	SELECT * 
	FROM bor 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parent_part_code = fv_part_code 

	FOREACH ros_bor_ass INTO pr_bor.* 
		IF pr_bor.start_date > fv_par_start_date 
		OR pr_bor.end_date < fv_par_start_date THEN 
			CONTINUE FOREACH 
		END IF 

		SELECT * 
		INTO pr_prodmfg.* 
		FROM prodmfg 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = pr_bor.part_code 
		AND part_type_ind matches "[GMP]" 

		IF status != 0 THEN 
			CONTINUE FOREACH 
		END IF 

		SELECT * 
		INTO pr_product.* 
		FROM product 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = pr_prodmfg.part_code 

		IF status != 0 THEN 
			CONTINUE FOREACH 
		END IF 

		IF NOT pv_background THEN 
			CALL working("Sub Assemblies ",pr_bor.part_code) 
		END IF 

		IF pr_prodmfg.part_type_ind = "P" THEN 
			LET fv_type = "UP" 
		ELSE 
			LET fv_type = "SS" 
		END IF 

		IF fv_order_type = "F" 
		AND fv_type = "SS" THEN 
			LET fv_type = "FS" 
		END IF 

		IF fv_order_type = "C" 
		AND fv_type = "SS" THEN 
			LET fv_type = "CS" 
		END IF 

		IF pr_product.days_lead_num IS NULL THEN 
			LET fv_lead_time = 0 
		ELSE 
			LET fv_lead_time = pr_product.days_lead_num 
		END IF 

		LET fv_due_date = get_cal_date(fv_par_start_date, 
		0, 
		"F") 

		IF pr_prodmfg.part_type_ind = "P" THEN 
			LET fv_start_date = fv_due_date 
		ELSE 
			LET fv_start_date = get_cal_date(fv_due_date, 
			fv_lead_time, 
			"B") 
		END IF 

		LET fv_par_start_date = fv_start_date 
		LET fv_calc_qty = pr_bor.required_qty * fv_par_qty 
		LET fv_yield_qty = 0 
		LET fv_scrap_qty = 0 

		IF pr_prodmfg.scrap_per IS NOT NULL 
		AND pr_prodmfg.scrap_per > 0 THEN 
			LET fv_scrap_qty = (fv_calc_qty * pr_prodmfg.scrap_per) / 100 
		END IF 

		IF pr_prodmfg.yield_per IS NOT NULL 
		AND pr_prodmfg.yield_per > 0 THEN 
			LET fv_yield_qty = 100 / pr_prodmfg.yield_per 
			LET fv_yield_qty = (fv_calc_qty * fv_yield_qty) - fv_calc_qty 
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

		IF fv_order_type = "C" 
		AND fv_type != "UP" THEN 
			LET fv_type = "CS" 
		END IF 

		CASE 
			WHEN pr_prodmfg.man_stk_con_qty IS NULL 
				LET pr_prodmfg.man_stk_con_qty = 1 
			WHEN pr_product.pur_stk_con_qty IS NULL 
				LET pr_product.pur_stk_con_qty = 1 
			WHEN pr_product.stk_sel_con_qty IS NULL 
				LET pr_product.stk_sel_con_qty = 1 
		END CASE 

		CASE 
			WHEN pr_bor.uom_code = pr_product.stock_uom_code 
				LET fv_calc_qty = fv_calc_qty / pr_prodmfg.man_stk_con_qty 
			WHEN pr_bor.uom_code = pr_product.pur_uom_code 
				LET fv_calc_qty = fv_calc_qty * pr_product.pur_stk_con_qty 
				LET fv_calc_qty = fv_calc_qty / pr_prodmfg.man_stk_con_qty 
			WHEN pr_bor.uom_code = pr_product.sell_uom_code 
				LET fv_calc_qty = fv_calc_qty / pr_product.stk_sel_con_qty 
				LET fv_calc_qty = fv_calc_qty / pr_prodmfg.man_stk_con_qty 
		END CASE 

		SELECT * 
		INTO pr_mps.* 
		FROM mps 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND plan_code = pv_mps_plan 
		AND parent_part_code = pr_bor.parent_part_code 
		AND part_code = pr_bor.part_code 
		AND start_date = fv_start_date 
		AND due_date = fv_due_date 
		AND type_text = fv_type 
		AND order_type_ind = fv_order_type 
		AND reference_num = fv_shop_order_num 

		IF status != 0 THEN 
			INSERT INTO mps VALUES (glob_rec_kandoouser.cmpy_code, 
			pv_mps_plan, 
			pr_bor.parent_part_code, 
			pr_bor.part_code, 
			fv_start_date, 
			fv_due_date, 
			pv_mps_desc, 
			fv_type, 
			fv_order_type, 
			fv_calc_qty, 
			fv_shop_order_num, 
			today, 
			glob_rec_kandoouser.sign_on_code, 
			"M51") 
		ELSE 
			UPDATE mps 
			SET required_qty = required_qty + fv_calc_qty 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND plan_code = pv_mps_plan 
			AND parent_part_code = pr_bor.parent_part_code 
			AND part_code = pr_bor.part_code 
			AND start_date = fv_start_date 
			AND due_date = fv_due_date 
			AND type_text = fv_type 
			AND order_type_ind = fv_order_type 
			AND reference_num = fv_shop_order_num 
		END IF 

		IF fv_type = "SS" 
		OR fv_type = "FS" 
		OR fv_type = "CS" THEN 
			SELECT * 
			INTO pr_mps.* 
			FROM mps 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND plan_code = pv_mps_plan 
			AND parent_part_code = pr_bor.parent_part_code 
			AND part_code = pr_bor.part_code 
			AND start_date = fv_start_date 
			AND due_date = fv_due_date 
			AND type_text = "US" 
			AND order_type_ind = fv_order_type 
			AND reference_num = fv_shop_order_num 

			IF status != 0 THEN 
				INSERT INTO mps VALUES (glob_rec_kandoouser.cmpy_code, 
				pv_mps_plan, 
				pr_bor.parent_part_code, 
				pr_bor.part_code, 
				fv_start_date, 
				fv_due_date, 
				pv_mps_desc, 
				"US", 
				fv_order_type, 
				fv_calc_qty, 
				fv_shop_order_num, 
				today, 
				glob_rec_kandoouser.sign_on_code, 
				"M51") 
			ELSE 
				UPDATE mps 
				SET required_qty = required_qty + fv_calc_qty 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND plan_code = pv_mps_plan 
				AND parent_part_code = pr_bor.parent_part_code 
				AND part_code = pr_bor.part_code 
				AND start_date = fv_start_date 
				AND due_date = fv_due_date 
				AND type_text = "US" 
				AND order_type_ind = fv_order_type 
				AND reference_num = fv_shop_order_num 
			END IF 
		END IF 
	END FOREACH 

END FUNCTION 
###########################################################################
# END FUNCTION get_next_level_ros(fv_shop_order_num, 
#	fv_part_code, 
#	fv_par_lead_time, 
#	fv_par_start_date, 
#	fv_par_qty, 
#	fv_order_type, 
#	fv_scrap_ind) 
###########################################################################


###########################################################################
# FUNCTION get_next_level_gen(fv_shop_order_num, 
#	fv_part_code, 
#	fv_par_lead_time, 
#	fv_par_start_date, 
#	fv_par_qty, 
#	fv_order_type) 
# 
#
#
#
###########################################################################
FUNCTION get_next_level_gen(fv_shop_order_num, 
	fv_part_code, 
	fv_par_lead_time, 
	fv_par_start_date, 
	fv_par_qty, 
	fv_order_type) 

	DEFINE 
	fv_shop_order_num LIKE shopordhead.shop_order_num, 
	fv_part_code LIKE shopordhead.part_code, 
	fv_par_lead_time INTEGER, 
	fv_type CHAR(2), 
	fv_par_start_date DATE, 
	fv_start_date DATE, 
	fv_due_date DATE, 
	fv_par_qty LIKE shoporddetl.required_qty, 
	fv_calc_qty LIKE shoporddetl.required_qty, 
	fv_order_type CHAR(1) 


	DECLARE rough_gen_ass CURSOR FOR 
	SELECT * 
	FROM configuration 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND generic_part_code = fv_part_code 

	FOREACH rough_gen_ass INTO pr_configuration.* 
		SELECT * 
		INTO pr_prodmfg.* 
		FROM prodmfg 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = pr_configuration.specific_part_code 
		AND part_type_ind matches "[GMP]" 

		IF status != 0 THEN 
			CONTINUE FOREACH 
		END IF 

		SELECT * 
		INTO pr_product.* 
		FROM product 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = pr_configuration.specific_part_code 

		IF status != 0 THEN 
			CONTINUE FOREACH 
		END IF 

		IF NOT pv_background THEN 
			CALL working("Generic Configurations ",pr_bor.part_code) 
		END IF 

		IF pr_prodmfg.part_type_ind = "P" THEN 
			LET fv_type = "UP" 
		ELSE 
			LET fv_type = "SS" 
		END IF 

		IF fv_order_type = "F" 
		AND fv_type = "SS" THEN 
			LET fv_type = "FS" 
		END IF 

		IF pr_product.days_lead_num IS NULL THEN 
			LET pr_product.days_lead_num = 0 
		END IF 

		LET fv_due_date = get_cal_date(fv_par_start_date, 
		0, 
		"F") 

		IF pr_prodmfg.part_type_ind = "P" THEN 
			LET fv_start_date = fv_due_date 
		ELSE 
			LET fv_start_date = get_cal_date(fv_due_date, 
			pr_product.days_lead_num, 
			"B") 
		END IF 

		LET fv_calc_qty = pr_configuration.factor_amt * fv_par_qty 

		IF fv_order_type = "C" 
		AND fv_type != "UP" THEN 
			LET fv_type = "CS" 
		END IF 

		SELECT * 
		INTO pr_mps.* 
		FROM mps 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND plan_code = pv_mps_plan 
		AND parent_part_code = pr_configuration.generic_part_code 
		AND part_code = pr_configuration.specific_part_code 
		AND start_date = fv_start_date 
		AND due_date = fv_due_date 
		AND type_text = fv_type 
		AND order_type_ind = fv_order_type 
		AND reference_num = fv_shop_order_num 

		IF status != 0 THEN 
			INSERT INTO mps VALUES (glob_rec_kandoouser.cmpy_code, 
			pv_mps_plan, 
			pr_configuration.generic_part_code, 
			pr_configuration.specific_part_code, 
			fv_start_date, 
			fv_due_date, 
			pv_mps_desc, 
			fv_type, 
			fv_order_type, 
			fv_calc_qty, 
			fv_shop_order_num, 
			today, 
			glob_rec_kandoouser.sign_on_code, 
			"M51") 
		ELSE 
			UPDATE mps 
			SET required_qty = required_qty + fv_calc_qty 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND plan_code = pv_mps_plan 
			AND parent_part_code = pr_configuration.generic_part_code 
			AND part_code = pr_configuration.specific_part_code 
			AND start_date = fv_start_date 
			AND due_date = fv_due_date 
			AND type_text = fv_type 
			AND order_type_ind = fv_order_type 
			AND reference_num = fv_shop_order_num 
		END IF 

		IF fv_type = "SS" 
		OR fv_type = "FS" 
		OR fv_type = "CS" THEN 
			SELECT * 
			INTO pr_mps.* 
			FROM mps 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND plan_code = pv_mps_plan 
			AND parent_part_code = pr_configuration.generic_part_code 
			AND part_code = pr_configuration.specific_part_code 
			AND start_date = fv_start_date 
			AND due_date = fv_due_date 
			AND type_text = "US" 
			AND order_type_ind = fv_order_type 
			AND reference_num = fv_shop_order_num 

			IF status != 0 THEN 
				INSERT INTO mps VALUES (glob_rec_kandoouser.cmpy_code, 
				pv_mps_plan, 
				pr_configuration.generic_part_code, 
				pr_configuration.specific_part_code, 
				fv_start_date, 
				fv_due_date, 
				pv_mps_desc, 
				"US", 
				fv_order_type, 
				fv_calc_qty, 
				fv_shop_order_num, 
				today, 
				glob_rec_kandoouser.sign_on_code, 
				"M51") 
			ELSE 
				UPDATE mps 
				SET required_qty = required_qty + fv_calc_qty 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND plan_code = pv_mps_plan 
				AND parent_part_code = pr_configuration.generic_part_code 
				AND part_code = pr_configuration.specific_part_code 
				AND start_date = fv_start_date 
				AND due_date = fv_due_date 
				AND type_text = "US" 
				AND order_type_ind = fv_order_type 
				AND reference_num = fv_shop_order_num 
			END IF 
		END IF 
	END FOREACH 

END FUNCTION 
###########################################################################
# END FUNCTION get_next_level_gen(fv_shop_order_num, 
#	fv_part_code, 
#	fv_par_lead_time, 
#	fv_par_start_date, 
#	fv_par_qty, 
#	fv_order_type) 
###########################################################################


###########################################################################
# FUNCTION get_next_level_gen1(fv_shop_order_num, 
#	fv_part_code, 
#	fv_par_lead_time, 
#	fv_par_start_date, 
#	fv_par_qty, 
#	fv_order_type) 
#
#
###########################################################################
FUNCTION get_next_level_gen1(fv_shop_order_num, 
	fv_part_code, 
	fv_par_lead_time, 
	fv_par_start_date, 
	fv_par_qty, 
	fv_order_type) 

	DEFINE 
	fv_shop_order_num LIKE shopordhead.shop_order_num, 
	fv_part_code LIKE shopordhead.part_code, 
	fv_par_lead_time INTEGER, 
	fv_type CHAR(2), 
	fv_par_start_date DATE, 
	fv_start_date DATE, 
	fv_due_date DATE, 
	fv_par_qty LIKE shoporddetl.required_qty, 
	fv_calc_qty LIKE shoporddetl.required_qty, 
	fv_order_type CHAR(1) 


	DECLARE rrough_gen_ass CURSOR FOR 
	SELECT * 
	FROM configuration 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND generic_part_code = fv_part_code 

	FOREACH rrough_gen_ass INTO pr_configuration.* 
		SELECT * 
		INTO pr_prodmfg.* 
		FROM prodmfg 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = pr_configuration.specific_part_code 
		AND part_type_ind matches "[GMP]" 

		IF status != 0 THEN 
			CONTINUE FOREACH 
		END IF 

		SELECT * 
		INTO pr_product.* 
		FROM product 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = pr_configuration.specific_part_code 

		IF status != 0 THEN 
			CONTINUE FOREACH 
		END IF 

		IF NOT pv_background THEN 
			CALL working("Generic Configurations ",pr_bor.part_code) 
		END IF 

		IF pr_prodmfg.part_type_ind = "P" THEN 
			LET fv_type = "UP" 
		ELSE 
			LET fv_type = "SS" 
		END IF 

		IF fv_order_type = "F" 
		AND fv_type = "SS" THEN 
			LET fv_type = "FS" 
		END IF 

		IF pr_product.days_lead_num IS NULL THEN 
			LET pr_product.days_lead_num = 0 
		END IF 

		LET fv_due_date = get_cal_date(fv_par_start_date, 
		0, 
		"F") 

		IF pr_prodmfg.part_type_ind = "P" THEN 
			LET fv_start_date = fv_due_date 
		ELSE 
			LET fv_start_date = get_cal_date(fv_due_date, 
			pr_product.days_lead_num, 
			"B") 
		END IF 

		LET fv_calc_qty = pr_configuration.factor_amt * fv_par_qty 

		IF fv_order_type = "C" 
		AND fv_type != "UP" THEN 
			LET fv_type = "CS" 
		END IF 

		SELECT * 
		INTO pr_mps.* 
		FROM mps 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND plan_code = pv_mps_plan 
		AND parent_part_code = pr_configuration.generic_part_code 
		AND part_code = pr_configuration.specific_part_code 
		AND start_date = fv_start_date 
		AND due_date = fv_due_date 
		AND type_text = fv_type 
		AND order_type_ind = fv_order_type 
		AND reference_num = fv_shop_order_num 

		IF status != 0 THEN 
			INSERT INTO mps VALUES (glob_rec_kandoouser.cmpy_code, 
			pv_mps_plan, 
			pr_configuration.generic_part_code, 
			pr_configuration.specific_part_code, 
			fv_start_date, 
			fv_due_date, 
			pv_mps_desc, 
			fv_type, 
			fv_order_type, 
			fv_calc_qty, 
			fv_shop_order_num, 
			today, 
			glob_rec_kandoouser.sign_on_code, 
			"M51") 
		ELSE 
			UPDATE mps 
			SET required_qty = required_qty + fv_calc_qty 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND plan_code = pv_mps_plan 
			AND parent_part_code = pr_configuration.generic_part_code 
			AND part_code = pr_configuration.specific_part_code 
			AND start_date = fv_start_date 
			AND due_date = fv_due_date 
			AND type_text = fv_type 
			AND order_type_ind = fv_order_type 
			AND reference_num = fv_shop_order_num 
		END IF 

		IF fv_type = "SS" 
		OR fv_type = "FS" 
		OR fv_type = "CS" THEN 
			SELECT * 
			INTO pr_mps.* 
			FROM mps 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND plan_code = pv_mps_plan 
			AND parent_part_code = pr_configuration.generic_part_code 
			AND part_code = pr_configuration.specific_part_code 
			AND start_date = fv_start_date 
			AND due_date = fv_due_date 
			AND type_text = "US" 
			AND order_type_ind = fv_order_type 
			AND reference_num = fv_shop_order_num 

			IF status != 0 THEN 
				INSERT INTO mps VALUES (glob_rec_kandoouser.cmpy_code, 
				pv_mps_plan, 
				pr_configuration.generic_part_code, 
				pr_configuration.specific_part_code, 
				fv_start_date, 
				fv_due_date, 
				pv_mps_desc, 
				"US", 
				fv_order_type, 
				fv_calc_qty, 
				fv_shop_order_num, 
				today, 
				glob_rec_kandoouser.sign_on_code, 
				"M51") 
			ELSE 
				UPDATE mps 
				SET required_qty = required_qty + fv_calc_qty 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND plan_code = pv_mps_plan 
				AND parent_part_code = pr_configuration.generic_part_code 
				AND part_code = pr_configuration.specific_part_code 
				AND start_date = fv_start_date 
				AND due_date = fv_due_date 
				AND type_text = "US" 
				AND order_type_ind = fv_order_type 
				AND reference_num = fv_shop_order_num 
			END IF 
		END IF 
	END FOREACH 

END FUNCTION 
###########################################################################
# END FUNCTION get_next_level_gen1(fv_shop_order_num, 
#	fv_part_code, 
#	fv_par_lead_time, 
#	fv_par_start_date, 
#	fv_par_qty, 
#	fv_order_type) 
###########################################################################


###########################################################################
# FUNCTION get_next_level_bor1(fv_shop_order_num, 
#	fv_part_code, 
#	fv_par_lead_time, 
#	fv_par_start_date, 
#	fv_par_qty, 
#	fv_order_type, 
#	fv_scrap_ind) 
#
#
###########################################################################
FUNCTION get_next_level_bor1(fv_shop_order_num, 
	fv_part_code, 
	fv_par_lead_time, 
	fv_par_start_date, 
	fv_par_qty, 
	fv_order_type, 
	fv_scrap_ind) 

	DEFINE 
	fv_shop_order_num LIKE shopordhead.shop_order_num, 
	fv_part_code LIKE shopordhead.part_code, 
	fv_par_lead_time INTEGER, 
	fv_lead_time INTEGER, 
	fv_type CHAR(2), 
	fv_par_start_date DATE, 
	fv_start_date DATE, 
	fv_due_date DATE, 
	fv_scrap_ind CHAR(1), 
	fv_par_qty LIKE shoporddetl.required_qty, 
	fv_scrap_qty LIKE shoporddetl.required_qty, 
	fv_yield_qty LIKE shoporddetl.required_qty, 
	fv_calc_qty LIKE shoporddetl.required_qty, 
	fv_order_type CHAR(1) 


	DECLARE rrough_bor_ass CURSOR FOR 
	SELECT * 
	FROM bor 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parent_part_code = fv_part_code 

	FOREACH rrough_bor_ass INTO pr_bor.* 
		IF pr_bor.start_date > fv_par_start_date 
		OR pr_bor.end_date < fv_par_start_date THEN 
			CONTINUE FOREACH 
		END IF 

		SELECT * 
		INTO pr_prodmfg.* 
		FROM prodmfg 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = pr_bor.part_code 
		AND part_type_ind matches "[GMP]" 

		IF status != 0 THEN 
			CONTINUE FOREACH 
		END IF 

		IF pr_prodmfg.mps_ind != "Y" THEN 
			CONTINUE FOREACH 
		END IF 

		SELECT * 
		INTO pr_product.* 
		FROM product 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = pr_prodmfg.part_code 

		IF status != 0 THEN 
			CONTINUE FOREACH 
		END IF 

		IF NOT pv_background THEN 
			CALL working("Sub Assemblies ",pr_bor.part_code) 
		END IF 

		IF pr_prodmfg.part_type_ind = "P" THEN 
			LET fv_type = "UP" 
		ELSE 
			LET fv_type = "SS" 
		END IF 

		IF pr_product.days_lead_num IS NULL THEN 
			LET fv_lead_time = 0 
		ELSE 
			LET fv_lead_time = pr_product.days_lead_num 
		END IF 

		LET fv_due_date = get_cal_date(fv_par_start_date, 
		0, 
		"F") 

		IF pr_prodmfg.part_type_ind = "P" THEN 
			LET fv_start_date = fv_due_date 
		ELSE 
			LET fv_start_date = get_cal_date(fv_due_date, 
			fv_lead_time, 
			"B") 
		END IF 

		LET fv_calc_qty = pr_bor.required_qty * fv_par_qty 
		LET fv_yield_qty = 0 
		LET fv_scrap_qty = 0 

		IF pr_prodmfg.scrap_per IS NOT NULL 
		AND pr_prodmfg.scrap_per > 0 THEN 
			LET fv_scrap_qty = (fv_calc_qty * pr_prodmfg.scrap_per) / 100 
		END IF 

		IF pr_prodmfg.yield_per IS NOT NULL 
		AND pr_prodmfg.yield_per > 0 THEN 
			LET fv_yield_qty = 100 / pr_prodmfg.yield_per 
			LET fv_yield_qty = (fv_calc_qty * fv_yield_qty) - fv_calc_qty 
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

		IF fv_order_type = "C" 
		AND fv_type != "UP" THEN 
			LET fv_type = "CS" 
		END IF 

		IF fv_order_type = "F" 
		AND fv_type != "UP" THEN 
			LET fv_type = "FS" 
		END IF 

		CASE 
			WHEN pr_prodmfg.man_stk_con_qty IS NULL 
				LET pr_prodmfg.man_stk_con_qty = 1 
			WHEN pr_product.pur_stk_con_qty IS NULL 
				LET pr_product.pur_stk_con_qty = 1 
			WHEN pr_product.stk_sel_con_qty IS NULL 
				LET pr_product.stk_sel_con_qty = 1 
		END CASE 

		CASE 
			WHEN pr_bor.uom_code = pr_product.stock_uom_code 
				LET fv_calc_qty = fv_calc_qty / pr_prodmfg.man_stk_con_qty 
			WHEN pr_bor.uom_code = pr_product.pur_uom_code 
				LET fv_calc_qty = fv_calc_qty * pr_product.pur_stk_con_qty 
				LET fv_calc_qty = fv_calc_qty / pr_prodmfg.man_stk_con_qty 
			WHEN pr_bor.uom_code = pr_product.sell_uom_code 
				LET fv_calc_qty = fv_calc_qty / pr_product.stk_sel_con_qty 
				LET fv_calc_qty = fv_calc_qty / pr_prodmfg.man_stk_con_qty 
		END CASE 

		SELECT * 
		INTO pr_mps.* 
		FROM mps 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND plan_code = pv_mps_plan 
		AND parent_part_code = pr_bor.parent_part_code 
		AND part_code = pr_bor.part_code 
		AND start_date = fv_start_date 
		AND due_date = fv_due_date 
		AND type_text = fv_type 
		AND order_type_ind = fv_order_type 
		AND reference_num = fv_shop_order_num 

		IF status != 0 THEN 
			INSERT INTO mps VALUES (glob_rec_kandoouser.cmpy_code, 
			pv_mps_plan, 
			pr_bor.parent_part_code, 
			pr_bor.part_code, 
			fv_start_date, 
			fv_due_date, 
			pv_mps_desc, 
			fv_type, 
			fv_order_type, 
			fv_calc_qty, 
			fv_shop_order_num, 
			today, 
			glob_rec_kandoouser.sign_on_code, 
			"M51") 
		ELSE 
			UPDATE mps 
			SET required_qty = required_qty + fv_calc_qty 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND plan_code = pv_mps_plan 
			AND parent_part_code = pr_bor.parent_part_code 
			AND part_code = pr_bor.part_code 
			AND start_date = fv_start_date 
			AND due_date = fv_due_date 
			AND type_text = fv_type 
			AND order_type_ind = fv_order_type 
			AND reference_num = fv_shop_order_num 
		END IF 

		IF fv_type = "SS" 
		OR fv_type = "FS" 
		OR fv_type = "CS" THEN 
			SELECT * 
			INTO pr_mps.* 
			FROM mps 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND plan_code = pv_mps_plan 
			AND parent_part_code = pr_bor.parent_part_code 
			AND part_code = pr_bor.part_code 
			AND start_date = fv_start_date 
			AND due_date = fv_due_date 
			AND type_text = "US" 
			AND order_type_ind = fv_order_type 
			AND reference_num = fv_shop_order_num 

			IF status != 0 THEN 
				INSERT INTO mps VALUES (glob_rec_kandoouser.cmpy_code, 
				pv_mps_plan, 
				pr_bor.parent_part_code, 
				pr_bor.part_code, 
				fv_start_date, 
				fv_due_date, 
				pv_mps_desc, 
				"US", 
				fv_order_type, 
				fv_calc_qty, 
				fv_shop_order_num, 
				today, 
				glob_rec_kandoouser.sign_on_code, 
				"M51") 
			ELSE 
				UPDATE mps 
				SET required_qty = required_qty + fv_calc_qty 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND plan_code = pv_mps_plan 
				AND parent_part_code = pr_bor.parent_part_code 
				AND part_code = pr_bor.part_code 
				AND start_date = fv_start_date 
				AND due_date = fv_due_date 
				AND type_text = "US" 
				AND order_type_ind = fv_order_type 
				AND reference_num = fv_shop_order_num 
			END IF 
		END IF 
	END FOREACH 

END FUNCTION 
###########################################################################
# END FUNCTION get_next_level_bor1(fv_shop_order_num, 
#	fv_part_code, 
#	fv_par_lead_time, 
#	fv_par_start_date, 
#	fv_par_qty, 
#	fv_order_type, 
#	fv_scrap_ind) 
###########################################################################


###########################################################################
# FUNCTION calc_ros(fv_scrap_ind)
#
#
###########################################################################
FUNCTION calc_ros(fv_scrap_ind) 

	DEFINE 
	fv_old_part LIKE prodmfg.part_code, 
	fv_to_order LIKE mps.start_date, 
	fv_start_date LIKE mps.start_date, 
	fv_due_date LIKE mps.due_date, 
	fv_onhand_qty LIKE prodstatus.onhand_qty, 
	fv_critical_qty LIKE prodstatus.critical_qty, 
	fv_scrap_ind CHAR(1) 


	DECLARE ros_curs CURSOR FOR 
	SELECT * 
	FROM mps 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND plan_code = pv_mps_plan 
	AND type_text != "CX" 
	ORDER BY part_code, due_date, type_text, reference_num 

	LET fv_old_part = "XXXXXXXXXX" 
	LET fv_due_date = NULL 

	FOREACH ros_curs INTO pr_mps.* 
		IF NOT pv_background THEN 
			CALL working("Calculating Recommended Orders ","") 
		END IF 

		IF fv_start_date IS NULL THEN 
			LET fv_start_date = pr_mps.start_date 
		END IF 

		IF fv_due_date IS NULL THEN 
			LET fv_due_date = pr_mps.due_date 
		END IF 

		IF pr_mps.part_code != fv_old_part THEN 
			SELECT sum(onhand_qty), sum(critical_qty) 
			INTO fv_onhand_qty, fv_critical_qty 
			FROM prodstatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_mps.part_code 

			IF status = notfound THEN 
				LET fv_onhand_qty = 0 
				LET fv_critical_qty = 0 
			END IF 

			IF fv_onhand_qty IS NULL THEN 
				LET fv_onhand_qty = 0 
			END IF 

			IF fv_critical_qty IS NULL THEN 
				LET fv_critical_qty = 0 
			END IF 

			SELECT * 
			INTO pr_product.* 
			FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_mps.part_code 

			IF status = notfound THEN 
				LET pr_product.min_ord_qty = 0 
			END IF 

			LET fv_onhand_qty = fv_onhand_qty * pr_prodmfg.man_stk_con_qty 
			LET fv_critical_qty = fv_critical_qty * pr_prodmfg.man_stk_con_qty 
			LET fv_old_part = pr_mps.part_code 
			LET fv_due_date = pr_mps.due_date 
		END IF 

		IF pr_mps.type_text = "AO" THEN 
			LET fv_onhand_qty = fv_onhand_qty + pr_mps.required_qty 
			CONTINUE FOREACH 
		END IF 

		LET fv_onhand_qty = fv_onhand_qty - pr_mps.required_qty 

		IF fv_onhand_qty < 0 
		OR fv_onhand_qty < fv_critical_qty THEN 
			LET fv_due_date = pr_mps.due_date 
			LET pr_mps.required_qty = fv_onhand_qty * -1 
			LET fv_to_order = pr_mps.required_qty 

			IF pr_product.min_ord_qty > pr_mps.required_qty THEN 
				LET fv_to_order = pr_product.min_ord_qty 
			END IF 

			IF fv_critical_qty > (fv_onhand_qty + fv_to_order) THEN 
				LET fv_to_order = fv_to_order + (fv_critical_qty - 
				(fv_onhand_qty + fv_to_order)) 
			END IF 

			LET fv_onhand_qty = fv_onhand_qty + fv_to_order 

			CALL get_next_level_ros(pr_mps.reference_num, 
			pr_mps.part_code, 
			pr_product.days_lead_num, 
			pr_mps.start_date, 
			fv_to_order, 
			#                                    pr_mps.order_type_ind,
			pr_mps.order_type_code, 
			fv_scrap_ind) 

			IF NOT pv_background THEN 
				CALL working ("Creating Recommended Order ", pr_mps.part_code) 
			END IF 
		END IF 
	END FOREACH 

END FUNCTION 
###########################################################################
# END FUNCTION calc_ros(fv_scrap_ind)
###########################################################################


###########################################################################
# FUNCTION work_out_ros(fv_scrap_ind)
#
#
###########################################################################
FUNCTION work_out_ros(fv_scrap_ind) 
	DEFINE 
	fv_old_part LIKE prodmfg.part_code, 
	fv_start_date LIKE mps.start_date, 
	fv_due_date LIKE mps.due_date, 
	fv_to_order LIKE prodstatus.onhand_qty, 
	fv_onhand_qty LIKE prodstatus.onhand_qty, 
	fv_critical_qty LIKE prodstatus.critical_qty, 
	fv_scrap_ind CHAR(1), 
	fv_seq SMALLINT 


	DECLARE mps_curs CURSOR FOR 
	SELECT * 
	FROM mps 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND plan_code = pv_mps_plan 
	AND type_text != "CX" 
	ORDER BY part_code, due_date, type_text, reference_num 

	LET fv_old_part = "XXXXXXXXXX" 
	LET fv_due_date = NULL 

	FOREACH mps_curs INTO pr_mps.* 
		IF NOT pv_background THEN 
			CALL working("Calculating Recommended Orders ","") 
		END IF 

		IF pr_mps.type_text = "US" 
		OR pr_mps.type_text = "UP" THEN 
			CONTINUE FOREACH 
		END IF 

		IF fv_start_date IS NULL THEN 
			LET fv_start_date = pr_mps.start_date 
		END IF 

		IF fv_due_date IS NULL THEN 
			LET fv_due_date = pr_mps.due_date 
		END IF 

		IF pr_mps.part_code != fv_old_part THEN 
			SELECT sum(onhand_qty), sum(critical_qty) 
			INTO fv_onhand_qty, fv_critical_qty 
			FROM prodstatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_mps.part_code 

			IF status = notfound THEN 
				LET fv_onhand_qty = 0 
				LET fv_critical_qty = 0 
			END IF 

			IF fv_onhand_qty IS NULL THEN 
				LET fv_onhand_qty = 0 
			END IF 

			IF fv_critical_qty IS NULL THEN 
				LET fv_critical_qty = 0 
			END IF 

			SELECT * 
			INTO pr_product.* 
			FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_mps.part_code 

			IF status = notfound THEN 
				LET pr_product.min_ord_qty = 0 
			END IF 

			IF pr_product.days_lead_num IS NULL THEN 
				LET pr_product.days_lead_num = 0 
			END IF 

			SELECT * 
			INTO pr_prodmfg.* 
			FROM prodmfg 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_mps.part_code 

			IF status = notfound THEN 
				LET pr_prodmfg.man_stk_con_qty = 0 
			END IF 

			LET fv_old_part = pr_mps.part_code 
			LET fv_seq = 0 
			LET fv_due_date = pr_mps.due_date 
		END IF 

		LET fv_onhand_qty = fv_onhand_qty * pr_prodmfg.man_stk_con_qty 
		LET fv_critical_qty = fv_critical_qty * pr_prodmfg.man_stk_con_qty 

		IF pr_mps.type_text = "AO" THEN 
			LET fv_onhand_qty = fv_onhand_qty + pr_mps.required_qty 
			LET fv_seq = fv_seq + 1 
			CALL insert_into_report(pr_mps.*,fv_seq,fv_onhand_qty,0,fv_scrap_ind) 
			CONTINUE FOREACH 
		END IF 

		LET fv_onhand_qty = fv_onhand_qty - pr_mps.required_qty 
		LET fv_seq = fv_seq + 1 

		CALL insert_into_report(pr_mps.*, fv_seq, fv_onhand_qty,0,fv_scrap_ind) 

		IF fv_onhand_qty < 0 
		OR fv_onhand_qty < fv_critical_qty THEN 
			LET fv_due_date = pr_mps.due_date 
			LET pr_mps.type_text = "RO" 
			LET pr_mps.required_qty = fv_onhand_qty * -1 
			LET fv_to_order = pr_mps.required_qty 

			IF pr_product.min_ord_qty > pr_mps.required_qty THEN 
				LET fv_to_order = pr_product.min_ord_qty 
			END IF 

			IF fv_critical_qty > (fv_onhand_qty + fv_to_order) THEN 
				LET fv_to_order = fv_to_order + (fv_critical_qty - 
				(fv_onhand_qty + fv_to_order)) 
			END IF 

			LET fv_onhand_qty = fv_onhand_qty + fv_to_order 
			LET pr_mps.start_date = get_cal_date(pr_mps.due_date, 
			pr_product.days_lead_num, 
			"B") 

			### ****** M U S T   D O   O R D E R   I N C R E M E N T S *******

			LET fv_seq = fv_seq + 1 

			CALL insert_into_report1(pr_mps.*, 
			fv_seq, 
			fv_onhand_qty, 
			fv_to_order, 
			fv_scrap_ind) 

			IF NOT pv_background THEN 
				CALL working("Creating Recommended Order ", pr_mps.part_code) 
			END IF 
		END IF 
	END FOREACH 

END FUNCTION 
###########################################################################
# END FUNCTION work_out_ros(fv_scrap_ind)
###########################################################################


###########################################################################
# FUNCTION insert_into_report(fr_mps,fv_seq,fv_onhand_qty,fv_to_order,fv_scrap_ind)
#
#
###########################################################################
FUNCTION insert_into_report(fr_mps,fv_seq,fv_onhand_qty,fv_to_order,fv_scrap_ind) 
	DEFINE 
	fr_mps RECORD LIKE mps.*, 
	fv_scrap_ind CHAR(1), 
	fv_seq SMALLINT, 
	fv_part_desc LIKE product.desc_text, 
	fv_to_order LIKE prodstatus.onhand_qty, 
	fv_ordered LIKE prodstatus.onhand_qty, 
	fv_onhand_qty LIKE prodstatus.onhand_qty, 
	fv_lead_time LIKE product.days_lead_num 


	IF fr_mps.type_text != "RO" THEN 
		LET fv_ordered = fv_to_order 

		SELECT desc_text 
		INTO fv_part_desc 
		FROM product 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = fr_mps.part_code 

		SELECT days_lead_num 
		INTO fv_lead_time 
		FROM product 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = fr_mps.part_code 

		IF fv_lead_time IS NULL THEN 
			LET fv_lead_time = 0 
		END IF 

		INSERT INTO mpstable VALUES ("", 
		"", 
		fr_mps.part_code, 
		fv_part_desc, 
		fr_mps.reference_num, 
		fr_mps.type_text, 
		fr_mps.required_qty, 
		fr_mps.due_date, 
		fr_mps.start_date, 
		fv_onhand_qty, 
		fv_ordered, 
		fv_seq, 
		fv_lead_time) 
	END IF 

END FUNCTION 
###########################################################################
# END FUNCTION insert_into_report(fr_mps,fv_seq,fv_onhand_qty,fv_to_order,fv_scrap_ind)
###########################################################################


###########################################################################
# FUNCTION insert_into_report1(fr_mps,fv_seq,fv_onhand_qty,fv_to_order, fv_scrap_ind)
#
#
###########################################################################
FUNCTION insert_into_report1(fr_mps,fv_seq,fv_onhand_qty,fv_to_order, fv_scrap_ind) 
	DEFINE 
	fr_mps RECORD LIKE mps.*, 
	fv_scrap_ind CHAR(1), 
	fv_seq SMALLINT, 
	fv_part_desc LIKE product.desc_text, 
	fv_to_order LIKE prodstatus.onhand_qty, 
	fv_ordered LIKE prodstatus.onhand_qty, 
	fv_onhand_qty LIKE prodstatus.onhand_qty, 
	fv_lead_time LIKE product.days_lead_num 


	IF fr_mps.type_text = "RO" THEN 
		LET fv_ordered = fv_to_order 
	ELSE 
		LET fv_ordered = 0 
	END IF 

	SELECT desc_text 
	INTO fv_part_desc 
	FROM product 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = fr_mps.part_code 

	SELECT days_lead_num 
	INTO fv_lead_time 
	FROM product 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = fr_mps.part_code 

	IF fv_lead_time IS NULL THEN 
		LET fv_lead_time = 0 
	END IF 

	IF fr_mps.type_text = "RO" 
	AND fv_ordered > 0 THEN 
		INSERT INTO mpstable VALUES ("", 
		"", 
		fr_mps.part_code, 
		fv_part_desc, 
		fr_mps.reference_num, 
		fr_mps.type_text, 
		fr_mps.required_qty, 
		fr_mps.due_date, 
		fr_mps.start_date, 
		fv_onhand_qty, 
		fv_ordered, 
		fv_seq, 
		fv_lead_time) 

		SELECT * 
		FROM mpsdemand 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND plan_code = pv_mps_plan 
		AND part_code = fr_mps.part_code 
		AND due_date = fr_mps.due_date 
		AND start_date = fr_mps.start_date 
		AND reference_num = fr_mps.reference_num 
		AND type_text = "RO" 

		IF status != 0 THEN 
			INSERT INTO mpsdemand VALUES (glob_rec_kandoouser.cmpy_code, 
			pv_mps_plan, 
			fr_mps.parent_part_code, 
			fr_mps.part_code, 
			fr_mps.start_date, 
			fr_mps.due_date, 
			"RO", 
			fv_ordered, 
			fr_mps.reference_num, 
			today, 
			glob_rec_kandoouser.sign_on_code, 
			"M51") 
		ELSE 
			UPDATE mpsdemand 
			SET required_qty = required_qty + fv_ordered 
			WHERE part_code = fr_mps.part_code 
			AND plan_code = pv_mps_plan 
			AND due_date = fr_mps.due_date 
			AND start_date = fr_mps.start_date 
			AND reference_num = fr_mps.reference_num 
			AND type_text = "RO" 
		END IF 
	END IF 

END FUNCTION 
###########################################################################
# END FUNCTION insert_into_report1(fr_mps,fv_seq,fv_onhand_qty,fv_to_order, fv_scrap_ind)
###########################################################################


###########################################################################
# FUNCTION generate_ros(fv_scrap_ind)
#
#
###########################################################################
FUNCTION generate_ros(fv_scrap_ind) 
	DEFINE 
	fv_scrap_ind CHAR(1), 
	fv_lead_time INTEGER, 
	fv_parent_cnt SMALLINT, 
	fv_cnt SMALLINT, 
	fv_order_type_ind LIKE shopordhead.order_type_ind, 
	fv_count SMALLINT, 
	unexploded_subs SMALLINT, 
	no_phantoms SMALLINT 


	LET unexploded_subs = false 
	LET no_phantoms = false 

	WHILE not(no_phantoms AND unexploded_subs) 
		DECLARE phan1_curs CURSOR with HOLD FOR 
		SELECT rowid, * 
		FROM mps 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND plan_code = pv_mps_plan 
		AND (type_text = "US" 
		OR type_text = "UP") 

		LET fv_count = 0 

		FOREACH phan1_curs INTO pv_rowid, pr_mps.* 
			IF NOT pv_background THEN 
				CASE 
					WHEN pr_mps.type_text = "UP" 
						CALL working("Replacing Phantoms ",pr_mps.part_code) 
					WHEN pr_mps.type_text = "GE" 
						CALL working("Replacing Generics ",pr_mps.part_code) 
					OTHERWISE 
						CALL working("Exploding Sub Assemblies ", 
						pr_mps.part_code) 
				END CASE 
			END IF 

			LET fv_count = fv_count + 1 

			SELECT days_lead_num 
			INTO fv_lead_time 
			FROM product 
			WHERE cmpy_code = pr_mps.cmpy_code 
			AND part_code = pr_mps.part_code 

			IF fv_lead_time IS NULL THEN 
				LET fv_lead_time = 0 
			END IF 

			CASE 
				WHEN pr_mps.type_text = "US" OR "UP" 
					LET fv_cnt = 0 
					LET fv_parent_cnt = 0 

					CALL get_next_level_bor1(pr_mps.reference_num, 
					pr_mps.part_code, 
					fv_lead_time, 
					pr_mps.start_date, 
					pr_mps.required_qty, 
					fv_order_type_ind, 
					fv_scrap_ind) 

				WHEN pr_mps.type_text = "GE" 
					CALL get_next_level_gen1(pr_mps.reference_num, 
					pr_mps.part_code, 
					fv_lead_time, 
					pr_mps.start_date, 
					pr_mps.required_qty, 
					#                                             pr_mps.order_type_ind)
					pr_mps.order_type_code) 
			END CASE 

			# do NOT delete phantom records
			IF pr_mps.type_text != "UP" THEN 
				DELETE FROM mps 
				WHERE rowid = pv_rowid 
				LET fv_count = fv_count - 1 
			ELSE 
				LET fv_count = fv_count - 1 
			END IF 

		END FOREACH 

		IF fv_count = 0 THEN 
			LET no_phantoms = true 
			LET unexploded_subs = true 
		END IF 
	END WHILE 

END FUNCTION 
###########################################################################
# END FUNCTION generate_ros(fv_scrap_ind)
###########################################################################


###########################################################################
# FUNCTION working(fp_text,fp_value)
#
#
###########################################################################
FUNCTION working(fp_text,fp_value) 
	DEFINE 
	fp_text CHAR(30), 
	fp_value CHAR(30) 


	DISPLAY fp_text clipped, ": ", fp_value clipped, "" at 2,2 
	--- modif ericv init # attributes (normal,white)

END FUNCTION 
###########################################################################
# END FUNCTION working(fp_text,fp_value)
###########################################################################


###########################################################################
# REPORT M51_rpt_list_mps_background(p_rpt_idx,rp_errormsg)
#
#
###########################################################################
REPORT M51_rpt_list_mps_background(p_rpt_idx,rp_errormsg) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE rp_errormsg CHAR(100) 

	OUTPUT 
 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		ON EVERY ROW 
			PRINT COLUMN 1, rp_errormsg 
			PRINT 

		ON LAST ROW 
			PRINT 

			IF pv_found_error THEN 
				PRINT " Errors have occured during the MPS - MPS has NOT run" 
			ELSE 
				PRINT " MPS Successful - " 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4]
END REPORT 
###########################################################################
# REPORT M51_rpt_list_mps_background(p_rpt_idx,rp_errormsg)
###########################################################################