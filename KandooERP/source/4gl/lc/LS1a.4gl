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

# \brief module LS1a allows the user TO finalise a shipment

GLOBALS "LS1.4gl" 

DEFINE jm_count, pu_count, in_count, gen_count SMALLINT 


FUNCTION ship_final(p_cmpy,pr_ship_code,pr_vend_code) 
	 
	DEFINE pr_ship_code LIKE shiphead.ship_code 
	DEFINE p_cmpy LIKE shiphead.cmpy_code 
	DEFINE pr_vend_code LIKE vendor.vend_code 
	DEFINE pr_shipdetl RECORD LIKE shipdetl.* 
	DEFINE pr_product RECORD LIKE product.* 
	DEFINE pr_warehouse RECORD LIKE warehouse.* 
	DEFINE pr_shipstatus RECORD LIKE shipstatus.* 
	DEFINE pr_smparms RECORD LIKE smparms.* 
	DEFINE inv_curr_amt LIKE shiphead.fob_curr_cost_amt
	DEFINE net_fob_amt LIKE shiphead.fob_curr_cost_amt 
	DEFINE duty_amt LIKE shiphead.duty_inv_amt 
	DEFINE other_amt LIKE shiphead.other_inv_amt 
	DEFINE pr_landed_cost LIKE shipdetl.landed_cost 
	DEFINE pr_period_num LIKE prodledg.period_num 
	DEFINE pr_year_num LIKE prodledg.year_num 
	DEFINE final_date DATE 
	DEFINE doit,other_dist_ind,resp,cont CHAR(1) 
	DEFINE failed_it SMALLINT 

	IF pr_shiphead.finalised_flag = "Y" THEN 
		LET msgresp = kandoomsg("L", "9015", "") 
		#9015 "Shipment already finalised"
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
	CALL db_period_what_period(p_cmpy, final_date) 
	RETURNING pr_year_num, pr_period_num 
	OPEN WINDOW l123 with FORM "L123" 
	CALL windecoration_l("L123") -- albo kd-763 
	DISPLAY BY NAME 
	pr_vendor.vend_code, 
	pr_vendor.name_text, 
	pr_shiphead.ship_code, 
	pr_shiphead.ship_type_code, 
	pr_shiphead.eta_curr_date, 
	pr_shiphead.vessel_text, 
	pr_shiphead.discharge_text, 
	pr_shiphead.conversion_qty, 
	pr_shiphead.curr_code, 
	pr_shiphead.ware_code, 
	pr_warehouse.desc_text, 
	pr_shiphead.ship_status_code, 
	pr_shiphead.fob_ent_cost_amt, 
	pr_shiphead.fob_curr_cost_amt, 
	pr_shiphead.fob_inv_cost_amt, 
	pr_shiphead.duty_ent_amt, 
	pr_shiphead.duty_inv_amt, 
	pr_shiphead.other_cost_amt 

	DISPLAY pr_shiphead.curr_code, 
	pr_shipstatus.desc_text, 
	final_date, 
	pr_year_num, 
	pr_period_num 
	TO ship_curr, 
	shipstatus.desc_text, 
	final_date, 
	pr_year_num, 
	pr_period_num 

	LET inv_curr_amt = pr_shiphead.fob_ent_cost_amt / pr_shiphead.conversion_qty 
	DISPLAY BY NAME inv_curr_amt 
	IF pr_shiphead.fob_ent_cost_amt != pr_shiphead.fob_curr_cost_amt THEN 
		OPEN WINDOW l124 with FORM "L124" 
		CALL windecoration_l("L124") -- albo kd-763 
		MENU " Shipment Finalise" 
			ON ACTION "WEB-HELP" -- albo kd-375 
				CALL onlinehelp(getmoduleid(),null) 
			COMMAND "Continue" " Continue process bypassing warning" 
				LET resp = "N" 
				EXIT MENU 
			COMMAND KEY (interrupt, "E") "Exit" " Exit Finalise " 
				LET resp = "Y" 
				EXIT MENU 
			COMMAND KEY (control-w) 
				CALL kandoohelp("") 
		END MENU 
		CLOSE WINDOW l124 
		IF resp = "Y" THEN 
			CLOSE WINDOW l123 
			RETURN "Z" 
		END IF 
	END IF 
	IF pr_shiphead.duty_ent_amt != pr_shiphead.duty_inv_amt THEN 
		OPEN WINDOW l125 with FORM "L125" 
		CALL windecoration_l("L125") -- albo kd-763 
		MENU " Shipment Finalise" 
			ON ACTION "WEB-HELP" -- albo kd-375 
				CALL onlinehelp(getmoduleid(),null) 
			COMMAND "Continue" " Continue process bypassing warning" 
				LET resp = "N" 
				EXIT MENU 
			COMMAND KEY (interrupt, "E") "Exit" " Exit Finalise " 
				LET resp = "Y" 
				EXIT MENU 
			COMMAND KEY (control-w) 
				CALL kandoohelp("") 
		END MENU 
		CLOSE WINDOW l125 
		IF resp = "Y" THEN 
			CLOSE WINDOW l123 
			RETURN "Z" 
		END IF 
	END IF 
	INPUT BY NAME 
	pr_shiphead.ship_status_code, 
	final_date, 
	pr_year_num, 
	pr_period_num, 
	other_dist_ind WITHOUT DEFAULTS 

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
				LET msgresp = kandoomsg("L", "9012", "") 
				#9012 Shipment Status NOT found; Try Window.
				NEXT FIELD ship_status_code 
			ELSE 
				DISPLAY pr_shipstatus.desc_text 
				TO shipstatus.desc_text 

			END IF 
		AFTER FIELD final_date 
			CALL db_period_what_period(p_cmpy, final_date) 
			RETURNING pr_year_num, pr_period_num 
			IF check_period(p_cmpy, pr_year_num, pr_period_num) THEN ELSE 
				NEXT FIELD final_date 
			END IF 
			DISPLAY pr_year_num, pr_period_num 
			TO pr_year_num, pr_period_num 

		AFTER FIELD pr_year_num 
			IF check_period(p_cmpy, pr_year_num, pr_period_num) THEN ELSE 
				NEXT FIELD pr_year_num 
			END IF 
			DISPLAY pr_year_num, pr_period_num 
			TO pr_year_num, pr_period_num 

		AFTER FIELD pr_period_num 
			IF check_period(p_cmpy, pr_year_num, pr_period_num) THEN ELSE 
				NEXT FIELD pr_period_num 
			END IF 
			DISPLAY pr_year_num, pr_period_num 
			TO pr_year_num, pr_period_num 

		AFTER FIELD other_dist_ind 
			IF pr_shiphead.other_cost_amt != 0 THEN 
				IF ( jm_count > 0 
				OR pu_count > 0 
				OR gen_count > 0) 
				AND ( other_dist_ind = "W" 
				OR other_dist_ind = "D" 
				OR other_dist_ind = "C") THEN 
					LET msgresp = kandoomsg("P",9546,"") 
					#9546 This distribution only allowed FOR Inventory.
					NEXT FIELD other_dist_ind 
				END IF 
			END IF 
		AFTER INPUT 
			IF NOT (quit_flag OR int_flag) THEN 
				SELECT * INTO pr_shipstatus.* FROM shipstatus 
				WHERE cmpy_code = p_cmpy 
				AND ship_status_code = pr_shiphead.ship_status_code 
				IF (status = notfound) THEN 
					LET msgresp = kandoomsg("L", "9012", "") 
					#9012 Shipment Status NOT found; Try Window.
					NEXT FIELD ship_status_code 
				END IF 
				DISPLAY pr_shipstatus.desc_text 
				TO shipstatus.desc_text 

			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 

	IF int_flag OR quit_flag THEN 
		CLOSE WINDOW l123 
		RETURN "Z" 
	END IF 
	LET resp = "Y" 
	SELECT * INTO pr_smparms.* FROM smparms 
	WHERE key_num = "1" 
	AND cmpy_code = p_cmpy 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("U","5112","") 
		#5112 Landed Costing Parameters Not Set Up; Refer Menu LZP.
		EXIT program 
	END IF 
	SELECT * INTO pr_puparms.* FROM puparms 
	WHERE key_code = "1" 
	AND cmpy_code = p_cmpy 
	IF pr_smparms.git_acct_code IS NULL THEN 
		LET msgresp = kandoomsg("L", "9014", "") 
		#9014 Goods in transit account required in LC Parameters, see menu LZP.
		EXIT program 
	END IF 
	LET patch_code = pr_smparms.git_acct_code 
	MENU " Finalise Options" 
		ON ACTION "WEB-HELP" -- albo kd-375 
			CALL onlinehelp(getmoduleid(),null) 
		COMMAND "Final" " Finalise Shipment. No changes can be made AFTER this option." 
			LET pr_mode = "FINAL" 
			CALL calc_landed_cost(p_cmpy, 
			pr_ship_code, 
			pr_vend_code, 
			final_date, 
			other_dist_ind) 
			RETURNING net_fob_amt, 
			duty_amt, 
			other_amt, 
			pr_landed_cost, 
			cont 

			IF cont = "Y" THEN 

				LET resp = "N" 

				BEGIN WORK 
					CALL post_journal(p_cmpy, 
					pr_ship_code, 
					net_fob_amt, 
					duty_amt, 
					other_amt, 
					final_date, 
					pr_period_num, 
					pr_year_num) 

					IF all_ok = 0 THEN 
						LET msgresp = kandoomsg("L",8003,"")		#8003 Error(s) found during posting; Do you wish TO UPDATE ...
						IF msgresp = "N" THEN 
							ROLLBACK WORK 
						ELSE 
							CALL upd_shiphead(p_cmpy, 
							pr_ship_code, 
							pr_shiphead.ship_status_code) 
						COMMIT WORK 
					END IF 
				ELSE 
					LET msgresp = kandoomsg("L",8004,"") 		#8004 Posting done; Do you wish TO UPDATE database?
					IF msgresp = "N" THEN 
						ROLLBACK WORK 
					ELSE 
						CALL upd_shiphead(p_cmpy, 
						pr_ship_code, 
						pr_shiphead.ship_status_code) 
					COMMIT WORK 
				END IF 
			END IF 
			#CLOSE WINDOW wprompt
		END IF 
		NEXT option "Print Manager" 
		COMMAND "Calc" " Calculate Landed cost only." 
			LET pr_mode = "CALC" 
			CALL calc_landed_cost(p_cmpy, 
			pr_ship_code, 
			pr_vend_code, 
			final_date, 
			other_dist_ind) 
			RETURNING net_fob_amt, 
			duty_amt, 
			other_amt, 
			pr_landed_cost, 
			resp 
			LET msgresp = kandoomsg("L","7001", pr_ship_code) 
			#7001 Landed Cost Calculated FOR Shipment Number: ...
			NEXT option "Exit" 

		ON ACTION "Print" 
			#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
			CALL run_prog('URS','','','','') 
			NEXT option "Exit" 
		COMMAND KEY (interrupt, "E") "Exit" " Exit Shipment Finalise." 
			LET resp = "Z" 
			EXIT MENU 
		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
	END MENU 
	CLOSE WINDOW l123 
	RETURN resp 
END FUNCTION 


FUNCTION check_period(p_cmpy, pr_year_num, pr_period_num) 
	DEFINE p_cmpy LIKE shiphead.cmpy_code 
	DEFINE pr_period_num LIKE prodledg.period_num 
	DEFINE pr_year_num LIKE prodledg.year_num 
	DEFINE failed_it SMALLINT 

	IF jm_count > 0 THEN 
		CALL valid_period(
			p_cmpy, 
			pr_year_num, 
			pr_period_num, 
			LEDGER_TYPE_JM) 
		RETURNING 
			pr_year_num, 
			pr_period_num, 
			failed_it 
		IF failed_it = 1 THEN 
			RETURN false 
		END IF 
	END IF 
	
	IF pu_count > 0 THEN 
		CALL valid_period(
			p_cmpy, 
			pr_year_num, 
			pr_period_num, 
			LEDGER_TYPE_PU) 
		RETURNING 
			pr_year_num, 
			pr_period_num, 
			failed_it 
		
		IF failed_it = 1 THEN 
			RETURN false 
		END IF 
	END IF 
	
	IF in_count > 0 THEN 
		CALL valid_period(
			p_cmpy, 
			pr_year_num, 
			pr_period_num, 
			LEDGER_TYPE_IN) 
		RETURNING 
			pr_year_num,
			pr_period_num, 
			failed_it 
		IF failed_it = 1THEN 
			RETURN false 
		END IF 
		
	END IF 
	CALL valid_period(
		p_cmpy, 
		pr_year_num, 
		pr_period_num, 
		LEDGER_TYPE_GL) 
	RETURNING 
		pr_year_num, 
		pr_period_num, 
		failed_it 
	IF failed_it = 1 
	THEN 
		RETURN false 
	END IF 
	RETURN true 
END FUNCTION 

FUNCTION count_lines() 
	SELECT count(*) 
	INTO jm_count 
	FROM shipdetl 
	WHERE cmpy_code = p_cmpy 
	AND ship_code = pr_shiphead.ship_code 
	AND job_code IS NOT NULL 
	SELECT count(*) 
	INTO pu_count 
	FROM shipdetl 
	WHERE cmpy_code = p_cmpy 
	AND ship_code = pr_shiphead.ship_code 
	AND source_doc_num IS NOT NULL 
	OR source_doc_num != 0 
	SELECT count(*) 
	INTO in_count 
	FROM shipdetl 
	WHERE cmpy_code = p_cmpy 
	AND ship_code = pr_shiphead.ship_code 
	AND part_code IS NOT NULL 
	SELECT count(*) 
	INTO gen_count 
	FROM shipdetl 
	WHERE cmpy_code = p_cmpy 
	AND ship_code = pr_shiphead.ship_code 
	AND job_code IS NULL 
	AND part_code IS NULL 
END FUNCTION 

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

	LET err_message = "LS1a - Update Shipment Header" 
	UPDATE shiphead 
	SET ship_status_code = pr_ship_status_code, 
	finalised_flag = "Y" 
	WHERE shiphead.cmpy_code = p_cmpy 
	AND shiphead.ship_code = pr_ship_code 
END FUNCTION 
