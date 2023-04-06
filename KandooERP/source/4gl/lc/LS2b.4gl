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
GLOBALS "../lc/LS2_GLOBALS.4gl" 


#@ Program LS2b.4gl calculates the landed cost FOR items in a shipment


FUNCTION calc_landed_cost(p_cmpy,pr_ship_code,pr_vend_code,final_date) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE 
	pr_shipdetl RECORD LIKE shipdetl.*, 
	pr_ship_code LIKE shiphead.ship_code, 
	pr_vend_code LIKE vendor.vend_code, 
	total_other_amt LIKE shiphead.other_inv_amt, 
	total_ship_rec_qty LIKE shipdetl.ship_rec_qty, 
	pr_other_cost_amt LIKE shiphead.other_inv_amt, 
	pr_cost_type_code LIKE shipcosttype.cost_type_code, 
	pr_acct_code LIKE shipcosttype.acct_code, 
	pr_total_amt LIKE voucherdist.dist_amt, 
	ok_to_goon CHAR(1), 
	final_date DATE, 
	idx SMALLINT 

	LET pr_other_cost_amt = pr_shiphead.other_cost_amt 
	LET total_other_amt = 0 
	LET total_ship_rec_qty = 0 
	# sum distribution base
	DECLARE item_curs1 CURSOR FOR 
	SELECT * INTO pr_shipdetl.* FROM shipdetl 
	WHERE shipdetl.ship_code = pr_ship_code 
	AND shipdetl.cmpy_code = p_cmpy 
	ORDER BY line_num 
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
		LET total_ship_rec_qty = total_ship_rec_qty + 
		pr_shipdetl.ship_rec_qty 
	END FOREACH 
	IF total_ship_rec_qty = 0 THEN 
		CALL unable_to_goon() 
		RETURN 0, "Z" 
	END IF 
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
		IF idx > 0 THEN 
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
		LET pa_ship_costs[pa_idx].cost_amt = 0 
		LET pa_ship_costs[pa_idx].assigned_amt = 0 
		IF pa_idx > 49 THEN 
			LET msgresp = kandoomsg("L","9013","") 
			#L9013 "Array NOT large enough TO handle all cost types
			RETURN 0, 0, 0, 0, "Z" 
		END IF 
	END FOREACH 
	LET idx = 0 
	IF total_other_amt > 0 THEN 
		CALL insert_temp(p_cmpy,pr_ship_code,total_other_amt, 
		pr_shiphead.duty_inv_amt, final_date) 
	END IF 
	RETURN total_other_amt, "Y" 
END FUNCTION 


FUNCTION get_product(p_cmpy, part_code) 
	DEFINE 
	p_cmpy CHAR(2), 
	part_code LIKE product.part_code, 
	okay CHAR(1) 

	LET okay = "Y" 
	SELECT * INTO pr_product.* FROM product 
	WHERE product.cmpy_code = p_cmpy 
	AND product.part_code = part_code 
	IF status = notfound THEN 
		ERROR "Product must have been deleted" 
		SLEEP 3 
		CALL errorlog ("LS1b - Product missing FROM active shipment") 
		LET okay = "N" 
		LET pr_product.weight_qty = 0 
		LET pr_product.cubic_qty = 0 
	END IF 
	RETURN okay 
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
		COMMAND KEY (interrupt, escape) "DEL TO Exit" " Exit Finalise " 
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
	{ -- albo
	   OPEN WINDOW wL127 AT 8,10 WITH FORM "L127"
	      attribute (border, red, MESSAGE line first)
	   prompt " Enter TO EXIT " FOR reply

	   CLOSE WINDOW wL127
	}
	LET reply = promptInput(" Enter TO EXIT ","",1) -- albo 

END FUNCTION 


FUNCTION insert_temp(p_cmpy, pr_ship_code, other_amt, pr_duty_amt, 
	final_date) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE 
	pr_ship_code LIKE shiphead.ship_code, 
	net_fob_amt LIKE shiphead.fob_curr_cost_amt, 
	pr_duty_amt LIKE shiphead.duty_inv_amt, 
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
	LET pr_data.desc_text = "Shipment Final - Duty" 
	# INSERT duty INTO posttemp
	IF pr_duty_amt IS NOT NULL 
	AND pr_duty_amt > 0 THEN 
		LET duty_acct_code = NULL 
		SELECT acct_code 
		INTO duty_acct_code 
		FROM shipcosttype 
		WHERE cmpy_code = p_cmpy 
		AND cost_type_code = "DUTY" 
		CALL account_patch(p_cmpy,duty_acct_code, 
		pr_shiphead.acct_override_code) 
		RETURNING pr_data.acct_code 
		LET pr_data.desc_text = "Shipment Final - Duty" 
		LET pr_data.debit_amt = pr_duty_amt 
		LET pr_data.credit_amt = 0 
		LET pr_data.base_debit_amt = pr_duty_amt 
		LET pr_data.base_credit_amt = 0 
		LET pr_data.conv_qty = 1.0 
		LET pr_data.stats_qty = 0 
		LET err_message = "LS1b - Posttemp INSERT duty" 
		INSERT INTO posttemp VALUES (pr_data.*) 
	END IF 
	# INSERT other charges INTO posttemp
	IF other_amt IS NOT NULL 
	AND other_amt > 0 THEN 
		FOR i = 1 TO pa_idx 
			IF pa_ship_costs[i].total_amt > 0 THEN 
				CALL account_patch(p_cmpy, 
				pa_ship_costs[i].acct_code, 
				pr_shiphead.acct_override_code) 
				RETURNING pr_data.acct_code 
				LET pr_data.desc_text = "Shipment Final - ", 
				pa_ship_costs[i].cost_type_code 
				LET pr_data.debit_amt = pa_ship_costs[i].total_amt 
				LET pr_data.credit_amt = 0 
				LET pr_data.base_debit_amt = pa_ship_costs[i].total_amt 
				LET pr_data.base_credit_amt = 0 
				LET pr_data.conv_qty = 1.0 
				LET pr_data.stats_qty = 0 
				LET err_message = "LS1b - Posttemp INSERT ", 
				pa_ship_costs[i].cost_type_code 
				INSERT INTO posttemp VALUES (pr_data.*) 
			END IF 
		END FOR 
	END IF 
	WHENEVER ERROR CONTINUE 
END FUNCTION 
