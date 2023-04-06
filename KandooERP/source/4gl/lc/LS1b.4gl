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
GLOBALS "../lc/LS_GROUP_GLOBALS.4gl" 
GLOBALS "../lc/LS1_GLOBALS.4gl" 
# \brief module LS1b.4gl calculates the landed cost FOR items in a shipment

#GLOBALS "LS1.4gl" 

FUNCTION calc_landed_cost(p_cmpy,pr_ship_code,pr_vend_code,final_date,other_dist_ind) 
	DEFINE pr_shipdetl RECORD LIKE shipdetl.* 
	DEFINE pr_ship_code LIKE shiphead.ship_code 
	DEFINE p_cmpy LIKE shiphead.cmpy_code 
	DEFINE pr_vend_code LIKE vendor.vend_code 
	DEFINE net_fob_amt LIKE shiphead.fob_curr_cost_amt 
	DEFINE duty_amt LIKE shiphead.duty_inv_amt 
	DEFINE other_amt LIKE shiphead.other_inv_amt 
	DEFINE total_net_fob_amt LIKE shiphead.fob_curr_cost_amt 
	DEFINE total_duty_amt LIKE shiphead.duty_inv_amt 
	DEFINE total_other_amt LIKE shiphead.other_inv_amt 
	DEFINE total_weight_qty LIKE product.weight_qty 
	DEFINE total_cubic_qty LIKE product.cubic_qty 
	DEFINE total_ship_rec_qty LIKE shipdetl.ship_rec_qty 
	DEFINE total_landed_cost LIKE shipdetl.landed_cost 
	DEFINE other_cost_amt LIKE shiphead.other_inv_amt 
	DEFINE pr_weight_qty LIKE product.weight_qty 
	DEFINE pr_cubic_qty LIKE product.cubic_qty 
	DEFINE pr_landed_cost LIKE shipdetl.landed_cost 
	DEFINE check_landed_cost LIKE shipdetl.landed_cost 
	DEFINE landed_cost_diff LIKE shipdetl.landed_cost 
	DEFINE pr_cost_type_code LIKE shipcosttype.cost_type_code 
	DEFINE pr_acct_code LIKE shipcosttype.acct_code 
	DEFINE pr_total_amt LIKE voucherdist.dist_amt 
	DEFINE total_density_qty DECIMAL(12,7) 
	DEFINE other_dist_ind, ok_to_goon, okay CHAR(1) 
	DEFINE final_date DATE 
	DEFINE max_idx, idx SMALLINT 

	LET other_cost_amt = pr_shiphead.other_cost_amt 
	LET total_net_fob_amt = 0 
	LET total_duty_amt = 0 
	LET total_other_amt = 0 
	LET total_weight_qty = 0 
	LET total_cubic_qty = 0 
	LET total_density_qty = 0 
	LET total_ship_rec_qty = 0 
	LET check_landed_cost = 0 
	LET total_landed_cost = pr_shiphead.fob_inv_cost_amt + 
	pr_shiphead.duty_inv_amt + other_cost_amt 
	FOR idx = 1 TO 50 
		LET pa_ship_costs[idx].cost_type_code = NULL 
		LET pa_ship_costs[idx].cost_amt = 0 
		LET pa_ship_costs[idx].total_amt = 0 
		LET pa_ship_costs[idx].assigned_amt = 0 
		LET pa_ship_costs[idx].acct_code = NULL 
	END FOR 
	DECLARE item_curs1 CURSOR FOR 
	SELECT * INTO pr_shipdetl.* FROM shipdetl 
	WHERE shipdetl.ship_code = pr_ship_code 
	AND shipdetl.cmpy_code = p_cmpy 
	ORDER BY cmpy_code, ship_code, line_num 
	LET ok_to_goon = "N" 
	FOREACH item_curs1 
		IF pr_shipdetl.ship_rec_qty = 0 
		OR pr_shipdetl.ship_rec_qty != pr_shipdetl.ship_inv_qty THEN 
			IF ok_to_goon != "Y" THEN 
				CALL check_qty() RETURNING ok_to_goon 
			END IF 
			IF ok_to_goon != "Y" THEN 
				EXIT program 
			END IF 
		END IF 
		IF pr_shipdetl.part_code IS NOT NULL 
		AND pr_shipdetl.ship_rec_qty > 0 THEN 
			CALL get_product(p_cmpy, pr_shipdetl.part_code) 
			RETURNING pr_weight_qty, pr_cubic_qty, okay 
			IF okay != "Y" THEN 
				RETURN 0, 0, 0, 0, "Z" 
			END IF 
			LET total_weight_qty = total_weight_qty + (pr_weight_qty * 
			pr_shipdetl.ship_rec_qty) 
			LET total_cubic_qty = total_cubic_qty + (pr_cubic_qty * 
			pr_shipdetl.ship_rec_qty) 
			IF pr_cubic_qty <> 0 THEN 
				LET total_density_qty = total_density_qty + 
				((pr_weight_qty / pr_cubic_qty) 
				* pr_shipdetl.ship_rec_qty) 
			END IF 
		END IF 
		LET total_ship_rec_qty = total_ship_rec_qty + 
		pr_shipdetl.ship_rec_qty 
	END FOREACH 
	IF total_ship_rec_qty = 0 THEN 
		CALL unable_to_goon() 
		RETURN 0, 0, 0, 0, "Z" 
	END IF 
	# SET up other costs array

	DECLARE o_curs CURSOR FOR 
	SELECT res_code, shipcosttype.acct_code, 
	sum(voucherdist.dist_amt / conv_qty) 
	FROM voucherdist, voucher, shipcosttype 
	WHERE voucher.cmpy_code = p_cmpy 
	AND voucherdist.cmpy_code = p_cmpy 
	AND shipcosttype.cmpy_code = p_cmpy 
	AND shipcosttype.cost_type_code = voucherdist.res_code 
	AND shipcosttype.class_ind = '3' 
	AND voucherdist.vouch_code = voucher.vouch_code 
	AND voucherdist.vend_code = voucher.vend_code 
	AND voucherdist.job_code = pr_shiphead.ship_code 
	AND voucherdist.type_ind = 'S' 
	GROUP BY 1, 2 
	union 
	SELECT res_code, shipcosttype.acct_code, 
	sum((0 - debitdist.dist_amt) / conv_qty) 
	FROM debitdist, debithead, shipcosttype 
	WHERE debithead.cmpy_code = p_cmpy 
	AND debitdist.cmpy_code = p_cmpy 
	AND shipcosttype.cmpy_code = p_cmpy 
	AND shipcosttype.cost_type_code = debitdist.res_code 
	AND shipcosttype.class_ind = '3' 
	AND debitdist.debit_code = debithead.debit_num 
	AND debitdist.vend_code = debithead.vend_code 
	AND debitdist.job_code = pr_ship_code 
	AND debitdist.type_ind = 'S' 
	GROUP BY 1, 2 
	ORDER BY 1, 2 

	LET pa_idx = 0 
	FOREACH o_curs INTO pr_cost_type_code, 
		pr_acct_code, 
		pr_total_amt 
		IF pa_idx > 0 THEN 
			IF pa_ship_costs[pa_idx].cost_type_code = pr_cost_type_code THEN 
				LET pa_ship_costs[pa_idx].total_amt 
				= pa_ship_costs[pa_idx].total_amt 
				+ pr_total_amt 
				CONTINUE FOREACH 
			END IF 
		END IF 
		LET pa_idx = pa_idx + 1 
		LET pa_ship_costs[pa_idx].cost_type_code = pr_cost_type_code 
		LET pa_ship_costs[pa_idx].acct_code = pr_acct_code 
		LET pa_ship_costs[pa_idx].total_amt 
		= pa_ship_costs[pa_idx].total_amt 
		+ pr_total_amt 
		IF pa_idx > 49 THEN 
			LET msgresp = kandoomsg("L","9013","") 
			#L9013 "Array NOT large enough TO handle all cost types
			RETURN 0, 0, 0, 0, "Z" 
		END IF 
	END FOREACH 
	LET net_fob_amt = 0 
	LET duty_amt = 0 
	LET other_amt = 0 
	LET idx = 0 
	DECLARE item_curs2 CURSOR FOR 
	SELECT * INTO pr_shipdetl.* FROM shipdetl 
	WHERE shipdetl.ship_code = pr_ship_code 
	AND shipdetl.cmpy_code = p_cmpy 
	AND shipdetl.ship_rec_qty > 0 
	ORDER BY cmpy_code, ship_code, line_num 
	FOREACH item_curs2 
		LET max_idx = sqlca.sqlerrd[3] 
		LET idx = idx + 1 
		IF pr_shiphead.fob_ent_cost_amt <> 0 
		AND pr_shiphead.fob_inv_cost_amt <> 0 THEN 
			LET net_fob_amt = pr_shipdetl.fob_ext_ent_amt 
			* pr_shiphead.fob_inv_cost_amt 
			/ pr_shiphead.fob_ent_cost_amt 
		ELSE 
			LET net_fob_amt = 0 
		END IF 
		LET total_net_fob_amt = total_net_fob_amt + net_fob_amt 
		IF pr_shipdetl.part_code IS NOT NULL THEN 
			CALL get_product(p_cmpy, pr_shipdetl.part_code) 
			RETURNING pr_weight_qty, pr_cubic_qty, okay 
			IF okay != "Y" THEN 
				RETURN 0, 0, 0, 0, "Z" 
			END IF 
		END IF 
		# do duty now
		IF pr_shiphead.duty_flag = "Y" THEN 
			IF pr_shiphead.duty_ent_amt <> 0 THEN 
				LET duty_amt = (pr_shiphead.duty_inv_amt / 
				pr_shiphead.duty_ent_amt) * pr_shipdetl.duty_ext_ent_amt 
			ELSE 
				LET duty_amt = 0 
			END IF 
			LET total_duty_amt = total_duty_amt + duty_amt 
		ELSE 
			IF pr_shiphead.duty_inv_amt != 0 THEN 
				CASE 
					WHEN other_dist_ind = "C" #cubic volume 
						LET duty_amt = ((pr_cubic_qty * pr_shipdetl.ship_rec_qty) 
						/ total_cubic_qty) * pr_shiphead.duty_inv_amt 
						LET total_duty_amt = total_duty_amt + duty_amt 
					WHEN other_dist_ind = "D" #density kg/m3 
						IF pr_cubic_qty <> 0 THEN 
							LET duty_amt = (((pr_weight_qty / pr_cubic_qty) * 
							pr_shipdetl.ship_rec_qty) / total_density_qty) * 
							pr_shiphead.duty_inv_amt 
						ELSE 
							LET duty_amt = 0 
						END IF 
						LET total_duty_amt = total_duty_amt + duty_amt 
					WHEN other_dist_ind = "L" #per line 
						IF pr_shiphead.line_num <> 0 THEN 
							LET duty_amt = (1 / pr_shiphead.line_num) * pr_shiphead.duty_inv_amt 
						ELSE 
							LET duty_amt = 0 
						END IF 
						LET total_duty_amt = total_duty_amt + duty_amt 
					WHEN other_dist_ind = "Q" #quantity 
						IF total_ship_rec_qty <> 0 THEN 
							LET duty_amt = (pr_shipdetl.ship_rec_qty / 
							total_ship_rec_qty) * pr_shiphead.duty_inv_amt 
						ELSE 
							LET duty_amt = 0 
						END IF 
						LET total_duty_amt = total_duty_amt + duty_amt 
					WHEN other_dist_ind = "V" #value 
						IF pr_shiphead.fob_ent_cost_amt <> 0 THEN 
							LET duty_amt = (pr_shipdetl.fob_ext_ent_amt / 
							pr_shiphead.fob_ent_cost_amt) * pr_shiphead.duty_inv_amt 
						ELSE 
							LET duty_amt = 0 
						END IF 
						LET total_duty_amt = total_duty_amt + duty_amt 
					WHEN other_dist_ind = "W" #weight 
						IF total_weight_qty <> 0 THEN 
							LET duty_amt = ((pr_shipdetl.ship_rec_qty * 
							pr_weight_qty) / total_weight_qty) * pr_shiphead.duty_inv_amt 
						ELSE 
							LET duty_amt = 0 
						END IF 
						LET total_duty_amt = total_duty_amt + duty_amt 
				END CASE 
			END IF 
		END IF 
		IF other_cost_amt != 0 THEN 
			IF pa_idx > 0 THEN 
				# distribute various other costs
				LET other_amt = 0 
				FOR i = 1 TO pa_idx 
					CASE 
						WHEN other_dist_ind = "C" #cubic volume 
							IF total_cubic_qty <> 0 THEN 
								LET pa_ship_costs[i].cost_amt = ((pr_cubic_qty * pr_shipdetl.ship_rec_qty) / 
								total_cubic_qty) * pa_ship_costs[i].total_amt 
							ELSE 
								LET pa_ship_costs[i].cost_amt = 0 
							END IF 
							LET total_other_amt = total_other_amt + pa_ship_costs[i].cost_amt 
							LET pa_ship_costs[i].assigned_amt = pa_ship_costs[i].assigned_amt 
							+ pa_ship_costs[i].cost_amt 
							LET other_amt = other_amt + pa_ship_costs[i].cost_amt 
						WHEN other_dist_ind = "D" #density kg/m3 
							IF total_density_qty <> 0 THEN 
								LET pa_ship_costs[i].cost_amt = (((pr_weight_qty / pr_cubic_qty) * 
								pr_shipdetl.ship_rec_qty) / total_density_qty) * 
								pa_ship_costs[i].total_amt 
							ELSE 
								LET pa_ship_costs[i].cost_amt = 0 
							END IF 
							LET total_other_amt = total_other_amt + pa_ship_costs[i].cost_amt 
							LET pa_ship_costs[i].assigned_amt = pa_ship_costs[i].assigned_amt 
							+ pa_ship_costs[i].cost_amt 
							LET other_amt = other_amt + pa_ship_costs[i].cost_amt 
						WHEN other_dist_ind = "L" #per line 
							IF pr_shiphead.line_num <> 0 THEN 
								LET pa_ship_costs[i].cost_amt = (1 / pr_shiphead.line_num) * pa_ship_costs[i].total_amt 
							ELSE 
								LET pa_ship_costs[i].cost_amt = 0 
							END IF 
							LET total_other_amt = total_other_amt + pa_ship_costs[i].cost_amt 
							LET pa_ship_costs[i].assigned_amt = pa_ship_costs[i].assigned_amt 
							+ pa_ship_costs[i].cost_amt 
							LET other_amt = other_amt + pa_ship_costs[i].cost_amt 
						WHEN other_dist_ind = "Q" #quantity 
							IF total_ship_rec_qty <> 0 THEN 
								LET pa_ship_costs[i].cost_amt = (pr_shipdetl.ship_rec_qty / 
								total_ship_rec_qty) * pa_ship_costs[i].total_amt 
							ELSE 
								LET pa_ship_costs[i].cost_amt = 0 
							END IF 
							LET total_other_amt = total_other_amt + pa_ship_costs[i].cost_amt 
							LET pa_ship_costs[i].assigned_amt = pa_ship_costs[i].assigned_amt 
							+ pa_ship_costs[i].cost_amt 
							LET other_amt = other_amt + pa_ship_costs[i].cost_amt 
						WHEN other_dist_ind = "V" #value 
							IF pr_shiphead.fob_ent_cost_amt <> 0 THEN 
								LET pa_ship_costs[i].cost_amt = (pr_shipdetl.fob_ext_ent_amt / 
								pr_shiphead.fob_ent_cost_amt) * pa_ship_costs[i].total_amt 
							ELSE 
								LET pa_ship_costs[i].cost_amt = 0 
							END IF 
							LET total_other_amt = total_other_amt + pa_ship_costs[i].cost_amt 
							LET pa_ship_costs[i].assigned_amt = pa_ship_costs[i].assigned_amt 
							+ pa_ship_costs[i].cost_amt 
							LET other_amt = other_amt + pa_ship_costs[i].cost_amt 
						WHEN other_dist_ind = "W" #weight 
							IF total_weight_qty <> 0 THEN 
								LET pa_ship_costs[i].cost_amt = ((pr_shipdetl.ship_rec_qty * pr_weight_qty) / 
								total_weight_qty) * pa_ship_costs[i].total_amt 
							ELSE 
								LET pa_ship_costs[i].cost_amt = 0 
							END IF 
							LET total_other_amt = total_other_amt + pa_ship_costs[i].cost_amt 
							LET pa_ship_costs[i].assigned_amt = pa_ship_costs[i].assigned_amt 
							+ pa_ship_costs[i].cost_amt 
							LET other_amt = other_amt + pa_ship_costs[i].cost_amt 
					END CASE 
				END FOR 
			END IF 
		END IF 
		LET pr_landed_cost = net_fob_amt + duty_amt + other_amt 
		IF pr_shipdetl.ship_rec_qty <> 0 THEN 
			LET pr_shipdetl.landed_cost = pr_landed_cost / pr_shipdetl.ship_rec_qty 
		ELSE 
			LET pr_shipdetl.landed_cost = pr_landed_cost 
		END IF 
		LET check_landed_cost = check_landed_cost 
		+ (pr_shipdetl.landed_cost * pr_shipdetl.ship_rec_qty) 
		IF idx = max_idx 
		AND check_landed_cost != total_landed_cost THEN 
			IF pr_shipdetl.ship_rec_qty <> 0 THEN 
				LET landed_cost_diff = (total_landed_cost - check_landed_cost) / 
				pr_shipdetl.ship_rec_qty 
			ELSE 
				LET landed_cost_diff = total_landed_cost - check_landed_cost 
			END IF 
			LET check_landed_cost = check_landed_cost - (pr_shipdetl.landed_cost 
			* pr_shipdetl.ship_rec_qty) 
			LET pr_shipdetl.landed_cost = pr_shipdetl.landed_cost + 
			landed_cost_diff 
			LET check_landed_cost = check_landed_cost + (pr_shipdetl.landed_cost 
			* pr_shipdetl.ship_rec_qty) 
			LET net_fob_amt = net_fob_amt + (landed_cost_diff * pr_shipdetl.ship_rec_qty) 
		END IF 
		UPDATE shipdetl 
		SET landed_cost = pr_shipdetl.landed_cost, 
		ext_landed_cost = pr_shipdetl.landed_cost * 
		pr_shipdetl.ship_rec_qty 
		WHERE shipdetl.cmpy_code = p_cmpy 
		AND shipdetl.ship_code = pr_shiphead.ship_code 
		AND shipdetl.line_num = pr_shipdetl.line_num 
		CALL insert_temp(pr_shiphead.ship_code, net_fob_amt, duty_amt, 
		other_amt, final_date, pr_shipdetl.*) 
	END FOREACH 
	RETURN total_net_fob_amt, total_duty_amt, total_other_amt, 
	total_landed_cost, "Y" 
END FUNCTION 


FUNCTION get_product(p_cmpy, pr_part_code) 
	DEFINE 
	p_cmpy CHAR(2), 
	pr_part_code LIKE product.part_code, 
	okay CHAR(1) 

	LET okay = "Y" 
	SELECT * INTO pr_product.* FROM product 
	WHERE product.cmpy_code = p_cmpy 
	AND product.part_code = pr_part_code 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("I","7032","") 
		#I 7032 "Product does NOT exist "
		CALL errorlog ("LS1b - Product missing FROM active shipment") 
		LET okay = "N" 
		LET pr_product.weight_qty = 1 
		LET pr_product.cubic_qty = 1 
	END IF 
	IF pr_product.weight_qty IS NULL THEN 
		LET pr_product.weight_qty = 1 
	END IF 
	IF pr_product.cubic_qty IS NULL THEN 
		LET pr_product.cubic_qty = 1 
	END IF 
	RETURN pr_product.weight_qty, pr_product.cubic_qty , okay 
END FUNCTION 


FUNCTION check_qty() 
	DEFINE 
	reply CHAR(1) 

	OPEN WINDOW wl126 with FORM "L126" 
	CALL windecoration_l("L126") -- albo kd-763 
	MENU " Shipment Finalise" 
		ON ACTION "WEB-HELP" -- albo kd-375 
			CALL onlinehelp(getmoduleid(),null) 
		COMMAND "Continue" " Continue process bypassing warning" 
			LET reply = "Y" 
			EXIT MENU 
		COMMAND KEY (interrupt, escape) "Exit" " Exit Finalise " 
			LET reply = "N" 
			EXIT MENU 
		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
	END MENU 
	CLOSE WINDOW wl126 
	RETURN reply 
END FUNCTION 


FUNCTION unable_to_goon() 
	DEFINE 
	reply CHAR(1) 

	OPEN WINDOW wl127 with FORM "L127" 
	CALL windecoration_l("L127") -- albo kd-763 
	--   prompt " Enter TO EXIT " FOR reply -- albo
	CALL eventsuspend() --LET reply = AnyKey(" Enter TO EXIT ",12,20) -- albo 

	CLOSE WINDOW wl127 
END FUNCTION 


FUNCTION insert_temp(pr_ship_code, net_fob_amt, duty_amt, other_amt, final_date,pr_shipdetl) 
	DEFINE 
	pr_ship_code LIKE shiphead.ship_code, 
	net_fob_amt LIKE shiphead.fob_curr_cost_amt, 
	duty_amt LIKE shiphead.duty_inv_amt, 
	other_amt LIKE shiphead.other_inv_amt, 
	final_date DATE, 
	pr_shipdetl RECORD LIKE shipdetl.*, 
	duty_acct_code LIKE coa.acct_code 

	GOTO bypass 
	LABEL recovery: 
	LET try_again = error_recover(err_message,status) 
	IF try_again != "Y" THEN 
		EXIT program 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	# SET up common data fields

	LET pr_data.tran_type_ind = "REC" 
	LET pr_data.ref_num = pr_ship_code 
	LET pr_data.ref_text = "Shipment Finalise" 
	LET pr_data.tran_date = final_date 
	LET pr_data.currency_code = pr_glparms.base_currency_code 
	LET pr_data.acct_code = pr_shipdetl.acct_code 
	LET pr_data.desc_text = "Shipment Final - Net FOB Cost" 
	LET pr_data.debit_amt = net_fob_amt 
	LET pr_data.credit_amt = 0 
	LET pr_data.base_credit_amt = 0 
	LET pr_data.base_debit_amt = net_fob_amt 
	LET pr_data.conv_qty = 1.0 
	LET pr_data.stats_qty = 0 
	IF pr_mode = "FINAL" THEN 
		LET err_message = "LS1b - Posttemp INSERT" 
		INSERT INTO posttemp VALUES (pr_data.*) 
	END IF 

	# INSERT duty INTO posttemp
	IF duty_amt IS NOT NULL 
	AND duty_amt > 0 THEN 
		LET duty_acct_code = NULL 
		SELECT acct_code 
		INTO duty_acct_code 
		FROM shipcosttype 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cost_type_code = "DUTY" 
		IF status = notfound 
		OR duty_acct_code IS NULL THEN 
			LET pr_data.acct_code = pr_shipdetl.acct_code 
		ELSE 
			CALL account_patch(glob_rec_kandoouser.cmpy_code,duty_acct_code, pr_shipdetl.acct_code) 
			RETURNING pr_data.acct_code 
		END IF 
		LET pr_data.desc_text = "Shipment Final - Duty" 
		LET pr_data.debit_amt = duty_amt 
		LET pr_data.credit_amt = 0 
		LET pr_data.base_debit_amt = duty_amt 
		LET pr_data.base_credit_amt = 0 
		LET pr_data.conv_qty = 1.0 
		LET pr_data.stats_qty = 0 
		IF pr_mode = "FINAL" THEN 
			LET err_message = "LS1b - Posttemp INSERT duty" 
			INSERT INTO posttemp VALUES (pr_data.*) 
		END IF 
	END IF 
	# INSERT other charges INTO posttemp
	IF other_amt IS NOT NULL 
	AND other_amt > 0 THEN 
		FOR i = 1 TO pa_idx 
			IF pa_ship_costs[i].cost_amt > 0 THEN 
				IF pa_ship_costs[i].acct_code IS NOT NULL THEN 
					CALL account_patch(glob_rec_kandoouser.cmpy_code, 
					pa_ship_costs[i].acct_code,pr_shipdetl.acct_code) 
					RETURNING pr_data.acct_code 
				ELSE 
					LET pr_data.acct_code = pr_shipdetl.acct_code 
				END IF 
				LET pr_data.desc_text = "Shipment Final - ", pa_ship_costs[i].cost_type_code 
				LET pr_data.debit_amt = pa_ship_costs[i].cost_amt 
				LET pr_data.credit_amt = 0 
				LET pr_data.base_debit_amt = pa_ship_costs[i].cost_amt 
				LET pr_data.base_credit_amt = 0 
				LET pr_data.conv_qty = 1.0 
				LET pr_data.stats_qty = 0 
				IF pr_mode = "FINAL" THEN 
					LET err_message = "LS1b - Posttemp INSERT ", pa_ship_costs[i].cost_type_code 
					INSERT INTO posttemp VALUES (pr_data.*) 
				END IF 
			END IF 
		END FOR 
	END IF 
	WHENEVER ERROR CONTINUE 
END FUNCTION 
