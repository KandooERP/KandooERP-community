{
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

	Source code beautified by beautify.pl on 2020-01-02 17:31:33	$Id: $
}


# Purpose - Forecast Maintenance

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "M_MN_GLOBALS.4gl" 

GLOBALS 

	DEFINE 
	formname CHAR(15), 
	pr_prodmfg RECORD LIKE prodmfg.*, 
	pr_product RECORD LIKE product.*, 
	pr_shopordhead RECORD LIKE shopordhead.*, 
	pt_shopordhead RECORD LIKE shopordhead.*, 
	pr_company RECORD LIKE company.*, 
	pr_shoporddetl RECORD LIKE shoporddetl.*, 
	pa_shopordhead array[200] OF RECORD 
		start_date LIKE shopordhead.start_date, 
		end_date LIKE shopordhead.end_date, 
		uom_code LIKE shopordhead.uom_code, 
		order_qty LIKE shopordhead.order_qty, 
		forecast_num LIKE shopordhead.shop_order_num 
	END RECORD, 
	pa1_shopordhead array[200] OF RECORD 
		start_date LIKE shopordhead.start_date, 
		end_date LIKE shopordhead.end_date, 
		uom_code LIKE shopordhead.uom_code, 
		order_qty LIKE shopordhead.order_qty, 
		forecast_num LIKE shopordhead.shop_order_num 
	END RECORD, 
	idx SMALLINT, 
	r SMALLINT, 
	i SMALLINT, 
	scrn INTEGER, 
	cnt INTEGER, 
	forecast_count INTEGER, 
	no_of_forecast SMALLINT, 
	err_flag SMALLINT, 
	ok LIKE prodmfg.part_type_ind, 
	try_again LIKE prodmfg.part_type_ind, 
	fv_part_type LIKE prodmfg.part_type_ind, 
	tempamt LIKE shopordhead.order_qty, 
	ans, chgann CHAR(1), 
	err_message CHAR(40) 

END GLOBALS 


MAIN 

	#Initial UI Init
	CALL setModuleId("M61") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 


	LET ans = "Y" 
	WHILE ans = "Y" 
		IF getforecast() THEN 
			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
			END IF 
		END IF 

		CLOSE WINDOW wm131 
		LET ans = "Y" 
	END WHILE 

END MAIN 

#-------------------------------------------------------------------------#

#-------------------------------------------------------------------------#

FUNCTION getforecast() 

	OPEN WINDOW wm131 with FORM "M131" 
	CALL  windecoration_m("M131") -- albo kd-762 

	LET msgresp = kandoomsg("M",1505,"") 	# MESSAGE "esc TO eccept del TO EXIT"
	LET pt_shopordhead.shop_order_num = 0 

	INPUT BY NAME pt_shopordhead.part_code WITHOUT DEFAULTS 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) 
			CASE 
				WHEN infield (part_code) 
					LET fv_part_type = "M" 
					CALL show_mfgprods(glob_rec_kandoouser.cmpy_code,fv_part_type) 
					RETURNING pt_shopordhead.part_code 
					DISPLAY BY NAME pt_shopordhead.part_code 

					NEXT FIELD part_code 
			END CASE 

		AFTER FIELD part_code 
			IF pt_shopordhead.part_code IS NULL THEN 
				LET msgresp = kandoomsg("M",9532,"") 				# ERROR "product must be entered"
				NEXT FIELD part_code 
			ELSE 
				SELECT desc_text 
				INTO pr_product.desc_text 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pt_shopordhead.part_code 

				IF status = notfound THEN 
					LET msgresp = kandoomsg("M",9511,"") 
					# ERROR "product does NOT exist in the database"
					NEXT FIELD part_code 
				END IF 
			END IF 

			SELECT * 
			INTO pr_prodmfg.* 
			FROM prodmfg 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pt_shopordhead.part_code 
			AND mps_ind = "Y" 

			IF status = notfound THEN 
				LET msgresp = kandoomsg("M",9673,"") 
				# ERROR " Product NOT found, OR IS NOT an MPS part"
				NEXT FIELD part_code 
			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 

			DISPLAY BY NAME pr_prodmfg.part_code, 
			pr_product.desc_text 
	END INPUT 

	IF int_flag 
	OR quit_flag THEN 
		EXIT program 
	END IF 

	SELECT unique count(*) 
	INTO forecast_count 
	FROM shopordhead 
	WHERE shopordhead.cmpy_code = cmpy_code 
	AND shopordhead.part_code = pr_prodmfg.part_code 
	AND shopordhead.order_type_ind = "F" 

	IF status = notfound THEN 
		LET msgresp = kandoomsg("M",4507,"") 
		# prompt " No Forecasts FOR this product, add it (y/n)?"

		IF int_flag 
		OR quit_flag THEN 
			EXIT program 
		END IF 
		IF msgresp = 'Y' THEN 
			CALL scanner() 
		ELSE 
			RETURN false 
		END IF 
	ELSE 
		CALL scanner() 
	END IF 
	IF int_flag 
	OR quit_flag THEN 
		EXIT program 
	END IF 
	RETURN true 
END FUNCTION 

#-------------------------------------------------------------------------#

#-------------------------------------------------------------------------#

FUNCTION scanner() 

	LET msgresp = kandoomsg("U",1003,"") 

	DECLARE dforecast CURSOR FOR 
	SELECT shopordhead.* 
	INTO pr_shopordhead.* 
	FROM shopordhead 
	WHERE cmpy_code = cmpy_code 
	AND part_code = pr_prodmfg.part_code 
	AND order_type_ind = "F" 
	ORDER BY start_date 

	LET idx = 0 
	FOREACH dforecast 
		LET idx = idx + 1 
		LET pa_shopordhead[idx].start_date = pr_shopordhead.start_date 
		LET pa_shopordhead[idx].end_date = pr_shopordhead.end_date 
		LET pa_shopordhead[idx].uom_code = pr_shopordhead.uom_code 
		LET pa_shopordhead[idx].order_qty = pr_shopordhead.order_qty 
		LET pa_shopordhead[idx].forecast_num = pr_shopordhead.shop_order_num 
		LET pa1_shopordhead[idx].start_date = pr_shopordhead.start_date 
		LET pa1_shopordhead[idx].end_date = pr_shopordhead.end_date 
		LET pa1_shopordhead[idx].uom_code = pr_shopordhead.uom_code 
		LET pa1_shopordhead[idx].order_qty = pr_shopordhead.order_qty 
		LET pa1_shopordhead[idx].forecast_num = pr_shopordhead.shop_order_num 

		IF idx <= 10 
		AND idx > 1 THEN 
			DISPLAY pa_shopordhead [idx].* TO sr_forecast [idx].* 
		END IF 
	END FOREACH 
	LET no_of_forecast = idx 
	CALL set_count(idx) 

	INPUT ARRAY pa_shopordhead 
	WITHOUT DEFAULTS 
	FROM sr_forecast.* 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 

		BEFORE INSERT 
			LET no_of_forecast = 0 
			LET idx = arr_curr() 
			LET scrn = scr_line() 

		BEFORE DELETE 
			DELETE 
			FROM shopordhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND shop_order_num = pa_shopordhead[idx].forecast_num 

			DELETE 
			FROM shoporddetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND shop_order_num = pa_shopordhead[idx].forecast_num 

		AFTER FIELD start_date 
			IF pa_shopordhead[idx].start_date IS NULL THEN 
				LET pa_shopordhead[idx].start_date = today 
			END IF 
			DISPLAY pa_shopordhead[idx].start_date TO 
			sr_forecast[scrn].start_date 

		AFTER FIELD end_date 
			IF pa_shopordhead[idx].end_date IS NULL THEN 
				LET pa_shopordhead[idx].end_date 
				= pa_shopordhead[idx].start_date 
			ELSE 
				IF pa_shopordhead[idx].end_date 
				< pa_shopordhead[idx].start_date THEN 
					LET msgresp = kandoomsg("M",9646,"") 
					# ERROR "END Date IS less than the Start Date"
					NEXT FIELD end_date 
				END IF 
			END IF 
			DISPLAY pa_shopordhead[idx].end_date TO sr_forecast[scrn].end_date 

		AFTER FIELD order_qty 
			IF pa_shopordhead[idx].order_qty > 0 THEN 
				LET tempamt = pa_shopordhead[idx].order_qty 

				DISPLAY pa_shopordhead[idx].order_qty TO 
				sr_forecast[scrn].order_qty 

				IF status = -1213 THEN 
					LET msgresp = kandoomsg("M",9674,"") 
					#ERROR " Not a correct value "
					NEXT FIELD order_qty 
				END IF 

				IF status = -1226 THEN 
					LET msgresp = kandoomsg("M",9674,"") 
					#ERROR " Not a correct value "
					NEXT FIELD order_qty 
				END IF 
			ELSE 
				LET msgresp = kandoomsg("M",9674,"") 
				# ERROR " Not a correct value "
				NEXT FIELD order_qty 
			END IF 

			WHENEVER ERROR stop 

			IF idx > no_of_forecast THEN 
				INITIALIZE pa_shopordhead[idx].order_qty TO NULL 
			ELSE 
				IF pa_shopordhead[idx].order_qty IS NULL THEN 
					LET pa_shopordhead[scrn].order_qty = 0 
				END IF 
				IF tempamt IS NULL THEN 
					LET tempamt = 0 
				END IF 
			END IF 

			LET pa_shopordhead[idx].order_qty = tempamt 
			DISPLAY pa_shopordhead[idx].order_qty TO 
			sr_forecast[scrn].order_qty 

			IF idx > no_of_forecast THEN 
				SELECT next_order_num 
				INTO pa_shopordhead[idx].forecast_num 
				FROM mnparms 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND parm_code = "1" 

				DISPLAY pa_shopordhead[idx].forecast_num 
				TO sr_forecast[scrn].shop_order_num 

				LET pa_shopordhead[idx].uom_code = pr_prodmfg.man_uom_code 
				DISPLAY pa_shopordhead[idx].uom_code 
				TO sr_forecast[scrn].uom_code 

				BEGIN WORK 

					UPDATE mnparms 
					SET next_order_num = pa_shopordhead[idx].forecast_num + 1 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND parm_code = "1" 

					LET pr_shopordhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET pr_shopordhead.shop_order_num 
					= pa_shopordhead[idx].forecast_num 
					LET pr_shopordhead.suffix_num = 0 
					LET pr_shopordhead.order_type_ind = "F" 
					LET pr_shopordhead.status_ind = "H" 
					LET pr_shopordhead.sales_order_num = 0 
					LET pr_shopordhead.receipted_qty = 0 
					LET pr_shopordhead.rejected_qty = 0 
					LET pr_shopordhead.part_code = pr_prodmfg.part_code 
					LET pr_shopordhead.start_date = pa_shopordhead[idx].start_date 
					LET pr_shopordhead.end_date = pa_shopordhead[idx].end_date 
					LET pr_shopordhead.uom_code = pa_shopordhead[idx].uom_code 
					LET pr_shopordhead.order_qty = pa_shopordhead[idx].order_qty 
					LET pr_shopordhead.last_change_date = today 
					LET pr_shopordhead.last_user_text = glob_rec_kandoouser.sign_on_code 
					LET pr_shopordhead.last_program_text = "M61" 

					INSERT INTO shopordhead VALUES (pr_shopordhead.*) 
				COMMIT WORK 
				CALL ins_forecast(pr_prodmfg.part_code, 
				pa_shopordhead[idx].forecast_num, 
				pa_shopordhead[idx].order_qty, 
				pa_shopordhead[idx].start_date, 
				pa_shopordhead[idx].end_date) 
			ELSE 
				BEGIN WORK 

					UPDATE shopordhead 
					SET shopordhead.part_code = pr_prodmfg.part_code, 
					shopordhead.start_date = pa_shopordhead[idx].start_date, 
					shopordhead.end_date = pa_shopordhead[idx].end_date , 
					shopordhead.uom_code = pa_shopordhead[idx].uom_code , 
					shopordhead.order_qty = pa_shopordhead[idx].order_qty, 
					shopordhead.last_change_date = today, 
					shopordhead.last_user_text = glob_rec_kandoouser.sign_on_code , 
					shopordhead.last_program_text = "M61" 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND shop_order_num = pa_shopordhead[idx].forecast_num 

				COMMIT WORK 

				CALL ins_forecast(pr_prodmfg.part_code, 
				pa_shopordhead[idx].forecast_num, 
				pa_shopordhead[idx].order_qty, 
				pa_shopordhead[idx].start_date, 
				pa_shopordhead[idx].end_date) 

				SELECT shopordhead.end_date 
				INTO pr_shopordhead.end_date 
				FROM shopordhead 
				WHERE cmpy_code = cmpy_code 
				AND shop_order_num = pa_shopordhead[idx].forecast_num 

				LET pa_shopordhead[idx].end_date = pr_shopordhead.end_date 

				DISPLAY pa_shopordhead[idx].end_date 
				TO sr_forecast[scrn].end_date 
			END IF 
	END INPUT 
END FUNCTION 

#-------------------------------------------------------------------------#

#-------------------------------------------------------------------------#

FUNCTION ins_forecast(fv_parent_part_code, fv_order_num, fv_order_qty, 
	fv_start_date, fv_end_date) 

	DEFINE 
	fv_idx SMALLINT, 
	fv_scrn SMALLINT, 
	fv_cnt SMALLINT, 
	fv_cnt1 SMALLINT, 
	fv_setup_qty SMALLINT, 
	fv_cost_ind CHAR(1), 
	fv_runner CHAR(105), 
	fv_parent_part_code LIKE bor.parent_part_code, 
	fv_desc_text LIKE product.desc_text, 
	fv_cost1_tot LIKE bor.cost_amt, 
	fv_cost2_tot LIKE bor.cost_amt, 
	fv_cost3_tot LIKE bor.cost_amt, 
	fv_price_tot LIKE bor.price_amt, 
	fv_wc_tot LIKE bor.cost_amt, 
	fv_num_hrs INTEGER, 
	fv_op_hrs SMALLINT, 
	fv_time_fld CHAR(5), 
	fv_num_days SMALLINT, 
	fv_oper_time INTERVAL hour TO hour, 
	fv_order_num LIKE shopordhead.shop_order_num, 
	fv_order_qty LIKE shopordhead.order_qty, 
	fv_start_date LIKE shopordhead.start_date, 
	fv_end_date LIKE shopordhead.end_date, 
	fv_old_date LIKE shopordhead.end_date, 
	fr_bor RECORD LIKE bor.*, 
	fr_shoporddetl RECORD LIKE shoporddetl.*, 
	fr_workcentre RECORD LIKE workcentre.*, 
	fr_prodmfg RECORD LIKE prodmfg.*, 
	fr_product RECORD LIKE product.*, 
	fr_prodstatus RECORD LIKE prodstatus.*, 

	fa_cost1_amt array[200] OF LIKE bor.cost_amt, 
	fa_cost2_amt array[200] OF LIKE bor.cost_amt, 
	fa_cost3_amt array[200] OF LIKE bor.cost_amt 

	LET fv_cost1_tot = 0 
	LET fv_cost2_tot = 0 
	LET fv_cost3_tot = 0 
	LET fv_old_date = fv_end_date 

	DECLARE c_child CURSOR FOR 
	SELECT * 
	FROM bor 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parent_part_code = fv_parent_part_code 
	ORDER BY sequence_num 

	DELETE 
	FROM shoporddetl 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND shop_order_num = fv_order_num 

	LET fv_cnt = 0 

	BEGIN WORK 

		FOREACH c_child INTO fr_bor.* 
			LET fv_cnt = fv_cnt + 1 
			LET fr_shoporddetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET fr_shoporddetl.shop_order_num = fv_order_num 
			LET fr_shoporddetl.suffix_num = 0 
			LET fr_shoporddetl.parent_part_code = fv_parent_part_code 
			LET fr_shoporddetl.sequence_num = fr_bor.sequence_num 
			LET fr_shoporddetl.type_ind = fr_bor.type_ind 
			LET fr_shoporddetl.part_code = fr_bor.part_code 
			LET fr_shoporddetl.desc_text = fr_bor.desc_text 
			LET fr_shoporddetl.required_qty = fr_bor.required_qty 
			LET fr_shoporddetl.std_est_cost_amt = fr_bor.cost_amt 
			LET fr_shoporddetl.std_price_amt = fr_bor.price_amt 
			LET fr_shoporddetl.start_date = fv_start_date 
			LET fr_shoporddetl.end_date = fv_end_date 
			LET fr_shoporddetl.last_change_date = today 
			LET fr_shoporddetl.last_user_text = glob_rec_kandoouser.sign_on_code 
			LET fr_shoporddetl.last_program_text = "M61" 

			CASE fr_bor.type_ind 
				WHEN "I" 
					LET fr_shoporddetl.desc_text = fr_bor.desc_text 
				WHEN "S" 
					IF fr_bor.cost_type_ind = "F" THEN 
						LET fv_cost1_tot = fv_cost1_tot + fr_bor.cost_amt 
						LET fv_cost2_tot = fv_cost2_tot + fr_bor.cost_amt 
						LET fv_cost3_tot = fv_cost3_tot + fr_bor.cost_amt 
					ELSE 
						LET fr_shoporddetl.std_est_cost_amt = 
						fr_shoporddetl.std_est_cost_amt * fv_order_qty 
						LET fv_cost1_tot = fv_cost1_tot + (fr_bor.cost_amt * 
						fv_order_qty) 
						LET fv_cost2_tot = fv_cost2_tot + (fr_bor.cost_amt * 
						fv_order_qty) 
						LET fv_cost3_tot = fv_cost3_tot + (fr_bor.cost_amt * 
						fv_order_qty) 
					END IF 

				WHEN "W" 
					SELECT * 
					INTO fr_workcentre.* 
					FROM workcentre 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND work_centre_code = fr_bor.work_centre_code 

					SELECT sum(rate_amt) 
					INTO fr_shoporddetl.std_est_cost_amt 
					FROM workctrrate 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND work_centre_code = fr_bor.work_centre_code 
					AND rate_ind = "V" 

					IF fr_shoporddetl.std_est_cost_amt IS NULL THEN 
						LET fr_shoporddetl.std_est_cost_amt = 0 
					END IF 

					SELECT sum(rate_amt) 
					INTO fr_shoporddetl.std_price_amt 
					FROM workctrrate 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND work_centre_code = fr_bor.work_centre_code 
					AND rate_ind = "F" 

					IF fr_shoporddetl.std_price_amt IS NULL THEN 
						LET fr_shoporddetl.std_price_amt = 0 
					END IF 

					LET fr_shoporddetl.required_qty = 
					fr_bor.oper_factor_amt * fv_order_qty 

					IF fr_workcentre.processing_ind = "Q" THEN 
						LET fv_wc_tot = ((fr_shoporddetl.std_est_cost_amt 
						/ fr_workcentre.time_qty) 
						* fr_bor.oper_factor_amt 
						* fv_order_qty) 
						+ fr_shoporddetl.std_price_amt 
						LET fv_num_hrs = fr_shoporddetl.required_qty 
						/ fr_workcentre.time_qty 
						LET fv_cost1_tot = fv_cost1_tot + fv_wc_tot 
						LET fv_cost2_tot = fv_cost2_tot + fv_wc_tot 
						LET fv_cost3_tot = fv_cost3_tot + fv_wc_tot 
						LET fr_shoporddetl.std_price_amt = 0 
					ELSE 
						LET fv_wc_tot = (fr_shoporddetl.std_est_cost_amt * 
						fr_bor.oper_factor_amt * 
						fv_order_qty) + 
						fr_shoporddetl.std_price_amt 
						LET fv_num_hrs = fr_shoporddetl.required_qty 
						* fr_workcentre.time_qty 
						LET fr_shoporddetl.std_price_amt = 0 
						LET fv_cost1_tot = fv_cost1_tot + fv_wc_tot 
						LET fv_cost2_tot = fv_cost2_tot + fv_wc_tot 
						LET fv_cost3_tot = fv_cost3_tot + fv_wc_tot 
					END IF 
					LET fv_oper_time = fr_workcentre.oper_end_time 
					- fr_workcentre.oper_start_time 
					LET fv_time_fld = fv_oper_time 

					IF fr_workcentre.time_unit_ind = "D" THEN 
						LET fv_num_days = fv_num_hrs 
						LET fv_end_date = fv_start_date + fv_num_days units day 
						LET fr_shoporddetl.end_date = fv_end_date 
						LET fv_start_date = fr_shoporddetl.end_date 
					END IF 

					IF fr_workcentre.time_unit_ind = "H" THEN 
						LET fv_num_days = fv_num_hrs / (fv_time_fld[2,3]) 
						LET fv_end_date = fv_start_date + fv_num_days units day 
						LET fr_shoporddetl.end_date = fv_end_date 
						LET fv_start_date = fr_shoporddetl.end_date 
					END IF 

					IF fr_workcentre.time_unit_ind = "M" THEN 
						LET fv_num_days = (fv_num_hrs / 60) / (fv_time_fld[2,3]) 
						LET fv_end_date = fv_start_date + fv_num_days units day 
						LET fr_shoporddetl.end_date = fv_end_date 
						LET fv_start_date = fr_shoporddetl.end_date 
					END IF 

				WHEN "U" 
					IF fr_shoporddetl.cost_type_ind = "Q" THEN 
						LET fv_setup_qty = fv_order_qty / fr_bor.var_amt 
						IF fv_setup_qty < 1 THEN 
							LET fv_setup_qty = 1 
						END IF 
						LET fr_shoporddetl.required_qty = fv_setup_qty 
						LET fv_cost1_tot = fv_cost1_tot + 
						(fr_shoporddetl.std_est_cost_amt * 
						fv_setup_qty) 
						LET fv_cost2_tot = fv_cost2_tot + 
						(fr_shoporddetl.std_est_cost_amt * 
						fv_setup_qty) 
						LET fv_cost3_tot = fv_cost3_tot + 
						(fr_shoporddetl.std_est_cost_amt * 
						fv_setup_qty) 
					ELSE 
						LET fv_cost1_tot = fv_cost1_tot + 
						fr_shoporddetl.std_est_cost_amt 
						LET fv_cost2_tot = fv_cost2_tot + 
						fr_shoporddetl.std_est_cost_amt 
						LET fv_cost3_tot = fv_cost3_tot + 
						fr_shoporddetl.std_est_cost_amt 
					END IF 

				OTHERWISE 
					SELECT * 
					INTO fr_prodmfg.* 
					FROM prodmfg 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = fr_shoporddetl.part_code 

					SELECT * 
					INTO fr_prodstatus.* 
					FROM prodstatus 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = fr_shoporddetl.part_code 
					AND ware_code = fr_prodmfg.def_ware_code 

					SELECT * 
					INTO fr_product.* 
					FROM product 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = fr_shoporddetl.part_code 

					LET fr_shoporddetl.uom_code = fr_prodmfg.man_uom_code 
					LET fr_shoporddetl.issue_ware_code = fr_prodmfg.def_ware_code 
					LET fr_shoporddetl.required_qty = fr_shoporddetl.required_qty 
					* fv_order_qty 

					LET fr_shoporddetl.std_wgted_cost_amt = 
					fr_prodstatus.wgted_cost_amt * 
					fr_product.stk_sel_con_qty * 
					fr_prodmfg.man_stk_con_qty 
					LET fr_shoporddetl.std_est_cost_amt = 
					fr_prodstatus.est_cost_amt * 
					fr_product.stk_sel_con_qty * 
					fr_prodmfg.man_stk_con_qty 
					LET fr_shoporddetl.std_act_cost_amt = 
					fr_prodstatus.act_cost_amt * 
					fr_product.stk_sel_con_qty * 
					fr_prodmfg.man_stk_con_qty 
					LET fr_shoporddetl.std_price_amt = fr_prodstatus.list_amt * 
					fr_product.stk_sel_con_qty * 
					fr_prodmfg.man_stk_con_qty 
					CASE 
						WHEN fr_shoporddetl.uom_code = fr_product.pur_uom_code 
							LET fr_shoporddetl.std_est_cost_amt = 
							fr_shoporddetl.std_est_cost_amt / 
							(fr_prodmfg.man_stk_con_qty / 
							fr_product.pur_stk_con_qty) 
							LET fr_shoporddetl.std_wgted_cost_amt = 
							fr_shoporddetl.std_wgted_cost_amt / 
							(fr_prodmfg.man_stk_con_qty / 
							fr_product.pur_stk_con_qty) 
							LET fr_shoporddetl.std_act_cost_amt = 
							fr_shoporddetl.std_act_cost_amt / 
							(fr_prodmfg.man_stk_con_qty / 
							fr_product.pur_stk_con_qty) 
							LET fr_shoporddetl.std_price_amt = 
							fr_shoporddetl.std_price_amt / 
							(fr_prodmfg.man_stk_con_qty / 
							fr_product.pur_stk_con_qty) 

						WHEN fr_shoporddetl.uom_code = fr_product.stock_uom_code 
							LET fr_shoporddetl.std_est_cost_amt = 
							fr_shoporddetl.std_est_cost_amt / 
							fr_prodmfg.man_stk_con_qty 
							LET fr_shoporddetl.std_wgted_cost_amt = 
							fr_shoporddetl.std_wgted_cost_amt / 
							fr_prodmfg.man_stk_con_qty 
							LET fr_shoporddetl.std_act_cost_amt = 
							fr_shoporddetl.std_act_cost_amt / 
							fr_prodmfg.man_stk_con_qty 
							LET fr_shoporddetl.std_price_amt = 
							fr_shoporddetl.std_price_amt / 
							fr_prodmfg.man_stk_con_qty 

						WHEN fr_shoporddetl.uom_code = fr_product.sell_uom_code 
							LET fr_shoporddetl.std_est_cost_amt = 
							fr_shoporddetl.std_est_cost_amt / 
							(fr_prodmfg.man_stk_con_qty * 
							fr_product.stk_sel_con_qty) 
							LET fr_shoporddetl.std_wgted_cost_amt = 
							fr_shoporddetl.std_wgted_cost_amt / 
							(fr_prodmfg.man_stk_con_qty * 
							fr_product.stk_sel_con_qty) 
							LET fr_shoporddetl.std_act_cost_amt = 
							fr_shoporddetl.std_act_cost_amt / 
							(fr_prodmfg.man_stk_con_qty * 
							fr_product.stk_sel_con_qty) 
							LET fr_shoporddetl.std_price_amt = 
							fr_shoporddetl.std_price_amt / 
							(fr_prodmfg.man_stk_con_qty * 
							fr_product.stk_sel_con_qty) 
					END CASE 

					LET fv_cost1_tot = fv_cost1_tot + 
					(fr_shoporddetl.std_est_cost_amt * 
					fr_shoporddetl.required_qty) 
					LET fv_cost2_tot = fv_cost2_tot + 
					(fr_shoporddetl.std_wgted_cost_amt * 
					fr_shoporddetl.required_qty) 
					LET fv_cost3_tot = fv_cost3_tot + 
					(fr_shoporddetl.std_act_cost_amt * 
					fr_shoporddetl.required_qty) 
					LET fv_price_tot = fv_price_tot + 
					(fr_shoporddetl.std_price_amt * 
					fr_shoporddetl.required_qty) 

					IF fr_shoporddetl.type_ind = "B" THEN 
						LET fr_shoporddetl.required_qty = 
						- (fr_shoporddetl.required_qty) 
					END IF 
			END CASE 
			INSERT INTO shoporddetl VALUES (fr_shoporddetl.*) 
		END FOREACH 

		IF fv_old_date > fv_end_date THEN 
			LET fv_end_date = fv_old_date 
		END IF 

		UPDATE shopordhead 
		SET shopordhead.std_est_cost_amt = fv_cost1_tot, 
		shopordhead.std_wgted_cost_amt = fv_cost2_tot, 
		shopordhead.std_act_cost_amt = fv_cost3_tot, 
		shopordhead.std_price_amt = fv_price_tot, 
		shopordhead.end_date = fv_end_date 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND shop_order_num = fv_order_num 

	COMMIT WORK 
END FUNCTION 
