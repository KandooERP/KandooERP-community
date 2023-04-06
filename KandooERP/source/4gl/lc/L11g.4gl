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

	Source code beautified by beautify.pl on 2020-01-02 18:38:28	$Id: $
}




# L11g.4gl - This file contains the following functions
#   tariff_review - this FUNCTION provides a DISPLAY of
#         the duty totals by tariff code
#   tariff_details -this FUNCTION provides a DISPLAY of
#         the shipment lines against each tariff code
#

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "L_LC_GLOBALS.4gl" 

GLOBALS "L11_GLOBALS.4gl" 


FUNCTION tariff_review() 

	DEFINE 
	pa_tariff array[300] OF RECORD 
		tariff_code LIKE tariff.tariff_code, 
		ship_inv_qty LIKE shipdetl.ship_inv_qty, 
		fob_ent_amt LIKE shipdetl.fob_ext_ent_amt, 
		fob_base_amt LIKE shiphead.fob_inv_cost_amt, 
		duty_ent_amt LIKE shipdetl.duty_ext_ent_amt, 
		duty_rate_per LIKE shipdetl.duty_rate_per 
	END RECORD, 
	st_tariff array[300] OF RECORD 
		tariff_code LIKE shipdetl.tariff_code, 
		ship_inv_qty LIKE shipdetl.ship_inv_qty, 
		fob_ent_amt LIKE shipdetl.fob_ext_ent_amt, 
		fob_base_amt LIKE shiphead.fob_inv_cost_amt, 
		duty_ent_amt LIKE shiphead.duty_ent_amt, 
		duty_rate_per LIKE shipdetl.duty_rate_per 
	END RECORD, 
	pr_tariff RECORD 
		tariff_code LIKE shipdetl.tariff_code, 
		ship_inv_qty LIKE shipdetl.ship_inv_qty, 
		fob_ent_amt LIKE shipdetl.fob_ext_ent_amt, 
		fob_base_amt LIKE shiphead.fob_inv_cost_amt, 
		duty_ent_amt LIKE shiphead.duty_ent_amt, 
		duty_rate_per LIKE shipdetl.duty_rate_per 
	END RECORD, 
	pr_total_duty LIKE shiphead.duty_ent_amt, 
	pl_shipdetl RECORD LIKE shipdetl.*, 
	cnt, idx, i, scrn SMALLINT 

	OPEN WINDOW wl137 with FORM "L137" 
	CALL windecoration_l("L137") -- albo kd-761 

	DISPLAY pr_shiphead.curr_code TO 
	currency.currency_code 
	DELETE FROM tempdetl WHERE 1=1 
	FOR i = 1 TO max_shipdetls 
		IF st_shipdetl[i].part_code IS NULL 
		AND st_shipdetl[i].desc_text IS NULL 
		AND (st_shipdetl[i].ship_inv_qty = 0 
		OR st_shipdetl[i].ship_inv_qty IS null) THEN 
			# NOT a TRUE line
			EXIT FOR 
		END IF 
		INSERT INTO tempdetl VALUES (st_shipdetl[i].*) 
	END FOR 

	DECLARE tar_curs CURSOR FOR 
	SELECT 
	unique tariff_code, 
	sum (ship_inv_qty), 
	sum (fob_ext_ent_amt), 
	0, 
	sum (duty_ext_ent_amt), 
	duty_rate_per 
	INTO pr_tariff.* 
	FROM tempdetl 
	GROUP BY tariff_code, duty_rate_per 
	ORDER BY tariff_code 

	LET idx = 1 
	FOREACH tar_curs INTO pa_tariff[idx].* 
		LET pa_tariff[idx].fob_base_amt = conv_shipcurr( 
		pa_tariff[idx].fob_ent_amt, 
		pr_shiphead.curr_code, 
		"F", 
		pr_shiphead.conversion_qty) 
		LET idx = idx + 1 
		IF idx > max_shipdetls THEN 
			EXIT FOREACH 
		END IF 
	END FOREACH 
	LET idx = idx -1 

	IF idx > 0 THEN 
		MESSAGE 
		"Cursor TO code, F8 TO view breakdown" 
		attribute (yellow) 
	ELSE 
		ERROR "No shipment lines added yet" 
		attribute (yellow) 
		CLOSE WINDOW wl137 
		RETURN 
	END IF 

	LET cnt = idx 
	CALL set_count(cnt) 
	MESSAGE "F8 TO view breakdown" 

	DISPLAY ARRAY pa_tariff TO sr_tariff.* 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","L11g","display-arr-tariff") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON KEY (F8) 
			LET i = arr_curr() 
			SELECT 
			sum (duty_ext_ent_amt) 
			INTO pr_total_duty 
			FROM tempdetl 
			WHERE tariff_code = pa_tariff[i].tariff_code 
			CALL tariff_details(pa_tariff[i].tariff_code, 
			pr_total_duty) 
			CALL set_count(cnt) 
			CURRENT WINDOW IS wl137 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END DISPLAY 
	CLOSE WINDOW wl137 
	IF int_flag OR quit_flag THEN 
		LET int_flag = 0 
		LET quit_flag = 0 
	END IF 
END FUNCTION 


#---  tariff_details  ---------------------------------------#
FUNCTION tariff_details(pr_tariff_code, pr_duty_amt) 

	DEFINE 
	pr_tariff_code LIKE tariff.tariff_code, 
	pr_duty_amt LIKE shiphead.duty_ent_amt, 
	pa_detail array[300] OF RECORD 
		line_num LIKE shipdetl.line_num, 
		part_code LIKE shipdetl.part_code, 
		ship_inv_qty LIKE shipdetl.ship_inv_qty, 
		fob_ent_amt LIKE shipdetl.fob_unit_ent_amt, 
		fob_base_amt LIKE shiphead.fob_inv_cost_amt, 
		duty_unit_ent_amt LIKE shipdetl.duty_unit_ent_amt, 
		duty_rate_per LIKE shipdetl.line_num 
	END RECORD, 
	st_detail array[300] OF RECORD 
		line_num LIKE shipdetl.line_num, 
		part_code LIKE shipdetl.part_code, 
		ship_inv_qty LIKE shipdetl.ship_inv_qty, 
		fob_ent_amt LIKE shipdetl.fob_unit_ent_amt, 
		fob_base_amt LIKE shiphead.fob_inv_cost_amt, 
		duty_unit_ent_amt LIKE shipdetl.duty_unit_ent_amt, 
		duty_rate_per LIKE shipdetl.line_num 
	END RECORD, 
	pr_detail RECORD 
		line_num LIKE shipdetl.line_num, 
		part_code LIKE shipdetl.part_code, 
		ship_inv_qty LIKE shipdetl.ship_inv_qty, 
		fob_ent_amt LIKE shipdetl.fob_unit_ent_amt, 
		fob_base_amt LIKE shiphead.fob_inv_cost_amt, 
		duty_unit_ent_amt LIKE shipdetl.duty_unit_ent_amt, 
		duty_rate_per LIKE shipdetl.line_num 
	END RECORD, 
	pl_shipdetl RECORD LIKE shipdetl.*, 
	pr_tariff RECORD LIKE tariff.*, 
	cnt, idx, i, scrn SMALLINT 

	OPEN WINDOW wl138 with FORM "L138" 
	CALL windecoration_l("L138") -- albo kd-761 

	DISPLAY pr_shiphead.curr_code TO 
	currency.currency_code 
	SELECT * 
	INTO pr_tariff.* 
	FROM tariff 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tariff_code = pr_tariff_code 

	DISPLAY pr_tariff.tariff_code, 
	pr_tariff.desc_text, 
	pr_duty_amt, 
	pr_tariff.duty_per 
	TO 
	tariff_code, 
	duty_ent_amt, 
	desc_text, 
	duty_per 

	DECLARE det_curs CURSOR FOR 
	SELECT 
	0, 
	part_code, 
	ship_inv_qty, 
	fob_unit_ent_amt, 
	0, 
	duty_ext_ent_amt, 
	duty_rate_per 
	INTO pr_detail.* 
	FROM tempdetl 

	LET idx = 1 
	FOREACH det_curs INTO pa_detail[idx].* 
		LET pa_detail[idx].line_num = idx 
		LET pa_detail[idx].fob_base_amt = conv_shipcurr( 
		pa_detail[idx].fob_ent_amt, 
		pr_shiphead.curr_code, 
		"F", 
		pr_shiphead.conversion_qty) 
		LET idx = idx + 1 
		IF idx > max_shipdetls THEN 
			EXIT FOREACH 
		END IF 
	END FOREACH 
	LET idx = idx -1 

	IF idx > 0 THEN ELSE 
		ERROR "No shipment lines found" 
		attribute (yellow) 
		CLOSE WINDOW wl138 
		RETURN 
	END IF 
	LET cnt = idx 
	CALL set_count(cnt) 

	DISPLAY ARRAY pa_detail TO sr_detail.* 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","L11g","display-arr-detail") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END DISPLAY 

	CLOSE WINDOW wl138 
	IF int_flag OR quit_flag THEN 
		LET int_flag = 0 
		LET quit_flag = 0 
	END IF 
END FUNCTION 


