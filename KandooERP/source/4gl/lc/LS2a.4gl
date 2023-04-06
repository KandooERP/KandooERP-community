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

# \brief module LS2a allows the user TO finalise a credit shipment

DEFINE in_count, gen_count SMALLINT 

###########################################################################
# FUNCTION ship_final(p_cmpy,pr_ship_code,pr_vend_code) 
#
#
###########################################################################
FUNCTION ship_final(p_cmpy,pr_ship_code,pr_vend_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE 
	pr_ship_code LIKE shiphead.ship_code, 
	pr_vend_code LIKE vendor.vend_code, 
	pt_shipdetl RECORD LIKE shipdetl.*, 
	pr_warehouse RECORD LIKE warehouse.*, 
	pr_shipstatus RECORD LIKE shipstatus.*, 
	other_amt LIKE shiphead.other_inv_amt, 
	period_num LIKE prodledg.period_num, 
	year_num LIKE prodledg.year_num, 
	final_date DATE, 
	doit, cont, resp CHAR(1), 
	a CHAR(1) 

	IF pr_shiphead.finalised_flag = "Y" THEN 
		ERROR "Shipment already finalised" 
		RETURN "Z" 
	END IF 
	SELECT * INTO pr_warehouse.* FROM warehouse 
	WHERE warehouse.cmpy_code = p_cmpy 
	AND warehouse.ware_code = pr_shiphead.ware_code 
	IF status = notfound THEN 
		LET pr_warehouse.desc_text = NULL 
	END IF 
	SELECT * INTO pr_shipstatus.* FROM shipstatus 
	WHERE shipstatus.cmpy_code = p_cmpy 
	AND ship_status_code = pr_shiphead.ship_status_code 
	IF status = notfound THEN 
		LET pr_shipstatus.desc_text = NULL 
	END IF 
	# check that all the relevant periods are OPEN
	LET final_date = today 
	CALL db_period_what_period(p_cmpy, final_date) RETURNING year_num, period_num 
	IF check_period(p_cmpy, year_num, period_num) THEN ELSE 
		RETURN "Z" 
	END IF 

	OPEN WINDOW wl167 with FORM "L167" 
	CALL windecoration_l("L167") -- albo kd-763 

	DISPLAY BY NAME 
	pr_shiphead.vend_code, 
	pr_customer.name_text, 
	pr_shiphead.ship_code, 
	pr_shiphead.ship_type_code, 
	pr_shiphead.eta_curr_date, 
	pr_shiphead.conversion_qty, 
	pr_shiphead.curr_code, 
	pr_shiphead.ware_code, 
	pr_warehouse.desc_text, 
	pr_shiphead.ship_status_code, 
	pr_shiphead.fob_ent_cost_amt, 
	pr_shiphead.duty_ent_amt, 
	pr_shiphead.other_cost_amt, 
	pr_shiphead.total_amt 

	# calculate value of RETURN
	LET pr_goods_ret_amt = 0 
	LET pr_tax_ret_amt = 0 
	DECLARE c_shipdetl CURSOR FOR 
	SELECT * FROM shipdetl 
	WHERE shipdetl.cmpy_code = p_cmpy 
	AND shipdetl.ship_code = pr_ship_code 
	FOREACH c_shipdetl INTO pt_shipdetl.* 
		LET pr_goods_ret_amt = pr_goods_ret_amt + 
		(pt_shipdetl.ship_rec_qty * pt_shipdetl.landed_cost) 
		LET pr_tax_ret_amt = pr_tax_ret_amt + 
		(pt_shipdetl.ship_rec_qty * pt_shipdetl.duty_unit_ent_amt) 
	END FOREACH 
	LET pr_tax_ret_amt = pr_tax_ret_amt + 
	pr_shiphead.freight_tax_amt + 
	pr_shiphead.hand_tax_amt 
	LET pr_total_ret_amt = 
	pr_shiphead.freight_amt + pr_shiphead.freight_tax_amt + 
	pr_shiphead.hand_amt + pr_shiphead.hand_tax_amt + 
	pr_goods_ret_amt + pr_tax_ret_amt 
	DISPLAY pr_goods_ret_amt, 
	pr_tax_ret_amt, 
	pr_total_ret_amt 
	TO cred_goods_amt, 
	cred_tax_amt, 
	cred_val_amt 

	DISPLAY pr_shiphead.curr_code, 
	pr_shipstatus.desc_text, 
	final_date, 
	year_num, 
	period_num 
	TO ship_curr, 
	shipstatus.desc_text, 
	final_date, 
	year_num, 
	period_num 

	INPUT BY NAME 
	pr_shiphead.ship_status_code, 
	final_date, 
	year_num, 
	period_num WITHOUT DEFAULTS 

		ON ACTION "WEB-HELP" -- albo kd-375 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) 
			CASE 
				WHEN infield (ship_status_code) 
					LET pr_shiphead.ship_status_code = show_shipst(p_cmpy) 
					DISPLAY BY NAME pr_shiphead.ship_status_code 
					NEXT FIELD ship_status_code 
			END CASE 

		AFTER FIELD ship_status_code 
			SELECT * INTO pr_shipstatus.* FROM shipstatus 
			WHERE cmpy_code = p_cmpy 
			AND ship_status_code = pr_shiphead.ship_status_code 
			IF (status = notfound) THEN 
				ERROR "Shipment Status NOT found. Try window" 
				NEXT FIELD ship_status_code 
			ELSE 
				DISPLAY pr_shipstatus.desc_text 
				TO shipstatus.desc_text 

			END IF 

		AFTER FIELD final_date 
			CALL db_period_what_period(p_cmpy, final_date) 
			RETURNING year_num, period_num 
			IF check_period(p_cmpy, year_num, period_num) THEN ELSE 
				NEXT FIELD final_date 
			END IF 
			DISPLAY year_num, period_num 
			TO year_num, period_num 

		AFTER FIELD year_num 
			IF check_period(p_cmpy, year_num, period_num) THEN ELSE 
				NEXT FIELD year_num 
			END IF 
			DISPLAY year_num, period_num 
			TO year_num, period_num 

		AFTER FIELD period_num 
			IF check_period(p_cmpy, year_num, period_num) THEN ELSE 
				NEXT FIELD period_num 
			END IF 
			DISPLAY year_num, period_num 
			TO year_num, period_num 

		AFTER INPUT 
			IF quit_flag != 0 
			OR int_flag != 0 THEN ELSE 
				SELECT * INTO pr_shipstatus.* FROM shipstatus 
				WHERE cmpy_code = p_cmpy 
				AND ship_status_code = pr_shiphead.ship_status_code 
				IF (status = notfound) THEN 
					ERROR "Shipment Status NOT found. Try window" 
					NEXT FIELD ship_status_code 
				ELSE 
					DISPLAY pr_shipstatus.desc_text 
					TO shipstatus.desc_text 
				END IF 
			END IF 

	END INPUT 
	IF int_flag != 0 
	OR quit_flag != 0 THEN 
		CLOSE WINDOW wl167 
		RETURN "Z" 
	END IF 
	LET resp = "Y" 
	SELECT * INTO pr_smparms.* FROM smparms 
	WHERE key_num = "1" 
	AND cmpy_code = p_cmpy 
	IF status = notfound THEN 
		ERROR " LC Parameters NOT found, see menu LZP" 
		RETURN "Z" 
	END IF 
	SELECT * INTO pr_arparms.* FROM arparms 
	WHERE cmpy_code = p_cmpy 
	AND parm_code = "1" 
	IF pr_smparms.ret_git_acct_code IS NULL THEN 
		ERROR "Goods in transit account required in LC Parameters, see menu LZP" 
		RETURN "Z" 
	END IF 
	LET patch_code = pr_smparms.ret_git_acct_code 

	MENU " Finalise Options" 
		ON ACTION "WEB-HELP" -- albo kd-375 
			CALL onlinehelp(getmoduleid(),null)
			 
		COMMAND "Final" 
			"Finalise shipment. No changes can be made AFTER this option." 
			CALL calc_landed_cost(p_cmpy,pr_ship_code,pr_vend_code,final_date) 
			RETURNING other_amt, cont 

			IF cont = "Y" THEN 
				--            OPEN WINDOW wprompt AT 10,5 with 1 rows, 64 columns -- albo
				--               attribute (border, reverse)
				LET resp = "N" 
				--LET rpt_note = "LC Shipment Final Posting Report" 
				--CALL init_report(p_cmpy, glob_rec_kandoouser.sign_on_code, rpt_note) RETURNING pr_output
				 
				BEGIN WORK 
					CALL post_journal(p_cmpy, pr_ship_code, other_amt, 
					final_date, period_num, year_num) 
					CALL write_cred() 
					IF all_ok = 0 THEN 
						--                     prompt " Postings done PROBLEMS FOUND RETURN TO accept, DEL TO cancel." -- albo
						--                       FOR CHAR doit
						CALL eventsuspend() --LET doit = AnyKey(" Postings done PROBLEMS FOUND RETURN TO accept, BREAK TO cancel.",10,6) -- albo 
						IF int_flag != 0 
						OR quit_flag != 0 THEN 
							ROLLBACK WORK 
						ELSE 
							CALL upd_shiphead(p_cmpy, pr_ship_code, 
							pr_shiphead.ship_status_code) 
						COMMIT WORK 
					END IF 
				ELSE 
					--                  prompt " Postings done RETURN TO accept, DEL TO cancel." -- albo
					--                        FOR CHAR doit
					CALL eventsuspend() --LET doit = AnyKey(" Postings done RETURN TO accept, BREAK TO cancel.",10,6) -- albo 
					IF int_flag != 0 
					OR quit_flag != 0 THEN 
						ROLLBACK WORK 
					ELSE 
						CALL upd_shiphead(p_cmpy, pr_ship_code, 
						pr_shiphead.ship_status_code) 
					COMMIT WORK 
				END IF 
			END IF 
			--               CLOSE WINDOW wprompt
		END IF 
		EXIT MENU 


		COMMAND KEY (interrupt, escape) "DEL TO EXIT" "Exit shipment finalise." 
			LET resp = "Z" 
			EXIT MENU 

	END MENU
	 
	CLOSE WINDOW wl167
	 
	RETURN resp 
END FUNCTION 
###########################################################################
# END FUNCTION ship_final(p_cmpy,pr_ship_code,pr_vend_code) 
###########################################################################


###########################################################################
# FUNCTION check_period(p_cmpy, year_num, period_num) 
#
#
###########################################################################
FUNCTION check_period(p_cmpy, year_num, period_num) 
	DEFINE p_cmpy LIKE shiphead.cmpy_code 
	DEFINE period_num LIKE prodledg.period_num 
	DEFINE year_num LIKE prodledg.year_num 
	DEFINE failed_it SMALLINT 

	CALL valid_period(
		p_cmpy, 
		year_num, 
		period_num, 
		LEDGER_TYPE_AR) 
	RETURNING 
		year_num, 
		period_num, 
		failed_it 
	
	IF failed_it = 1 THEN 
		RETURN false 
	END IF 
	IF in_count > 0 THEN 
		CALL valid_period(
			p_cmpy, 
			year_num, 
			period_num, 
			TRAN_TYPE_INVOICE_IN) 
		RETURNING 
			year_num, 
			period_num, 
			failed_it 
		IF failed_it = 1 THEN 
			RETURN false 
		END IF 
	END IF 
	
	CALL valid_period(
		p_cmpy, 
		year_num, 
		period_num, 
		LEDGER_TYPE_GL) 
	RETURNING 
		year_num, 
		period_num, 
		failed_it 
	IF failed_it = 1 THEN 
		RETURN false 
	END IF
	 
	RETURN true 
END FUNCTION 
###########################################################################
# END FUNCTION check_period(p_cmpy, year_num, period_num) 
###########################################################################


###########################################################################
# FUNCTION count_lines() 
#
#
###########################################################################
FUNCTION count_lines() 
	SELECT count(*) INTO in_count 
	FROM shipdetl 
	WHERE cmpy_code = p_cmpy 
	AND ship_code = pr_shiphead.ship_code 
	AND part_code IS NOT NULL 
	SELECT count(*) INTO gen_count 
	FROM shipdetl 
	WHERE cmpy_code = p_cmpy 
	AND ship_code = pr_shiphead.ship_code 
	AND job_code IS NULL 
	AND part_code IS NULL 
END FUNCTION 
###########################################################################
# END FUNCTION count_lines() 
###########################################################################


###########################################################################
# FUNCTION upd_shiphead(p_cmpy, pr_ship_code, pr_ship_status_code) 
#
#
###########################################################################
FUNCTION upd_shiphead(p_cmpy, pr_ship_code, pr_ship_status_code) 
	DEFINE 
	p_cmpy LIKE shiphead.cmpy_code, 
	pr_ship_code LIKE shiphead.ship_code, 
	pr_ship_status_code LIKE shipstatus.ship_status_code, 
	failed_it SMALLINT 

	GOTO bypass 
	LABEL recovery: 
	LET try_again = error_recover(err_message,status) 
	IF try_again != "Y" THEN 
		EXIT program 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	LET err_message = "LS2a - Update Shipment Header" 
	UPDATE shiphead 
	SET ship_status_code = pr_ship_status_code, 
	finalised_flag = "Y" 
	WHERE shiphead.cmpy_code = p_cmpy 
	AND shiphead.ship_code = pr_ship_code 
END FUNCTION 
###########################################################################
# END FUNCTION upd_shiphead(p_cmpy, pr_ship_code, pr_ship_status_code) 
###########################################################################