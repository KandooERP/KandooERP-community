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

	Source code beautified by beautify.pl on 2020-01-02 19:48:19	$Id: $
}



# Purpose - Release tentative invoices INTO Billing.
#            1. This copies details FROM (tentinvhead, tentinvdetl)
#               INTO invoicehead, invoicedetl
#            2. Updates customer details
#            3. Updates product details
#            4. Update activity details
#            5. Creates ar audit details
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 
DEFINE 

pa_tentinvhead array[1000] OF RECORD 
	line_ind CHAR(1), 
	inv_num LIKE tentinvhead.inv_num, 
	contract_code LIKE tentinvhead.contract_code, 
	desc_text LIKE contracthead.desc_text, 
	total_amt LIKE tentinvhead.total_amt 
END RECORD, 
pa_dspinv array[1000] OF RECORD 
	contract_code LIKE tentinvhead.contract_code, 
	inv_num LIKE invoicehead.inv_num, 
	inv_date LIKE invoicehead.inv_date, 
	inv_type CHAR(08), 
	total_amt LIKE invoicehead.total_amt 
END RECORD, 
pr_rec_kandoouser RECORD LIKE kandoouser.*, 
pr_arparms RECORD LIKE arparms.*, 
pr_inparms RECORD LIKE inparms.*, 
pr_tentinvhead RECORD LIKE tentinvhead.*, 
pr_tentinvdetl RECORD LIKE tentinvdetl.*, 
pr_contracthead RECORD LIKE contracthead.*, 
pr_contractdetl RECORD LIKE contractdetl.*, 
pr_contractdate RECORD LIKE contractdate.*, 
pr_invoicehead RECORD LIKE invoicehead.*, 
pr_invoicedetl RECORD LIKE invoicedetl.*, 
pr_araudit RECORD LIKE araudit.*, 
pr_customer RECORD LIKE customer.*, 
pr_job RECORD LIKE job.*, 
pr_activity RECORD LIKE activity.*, 
pr_prodstatus RECORD LIKE prodstatus.*, 
pr_prodledg RECORD LIKE prodledg.*, 
pr_jobledger RECORD LIKE jobledger.*, 
pr_resbill RECORD LIKE resbill.*, 
pr_term RECORD LIKE term.*, 
run_total_amt LIKE invoicehead.total_amt, 
pv_found_one, idx, scrn, cnt SMALLINT, 
err_continue CHAR(1), 
err_message CHAR(40), 
formname CHAR(15), 
pv_cust_code LIKE saleshist.cust_code, 
pv_contract_date LIKE invoicehead.inv_date, 
sel_query_text CHAR(1500), 
query_text CHAR(1500), 
newyear SMALLINT 

MAIN 
	#Initial UI Init
	CALL setModuleId("JA9") -- albo 
	CALL ui_init(0) 

	CALL authenticate(getmoduleid()) 


	SELECT * INTO pr_inparms.* 
	FROM inparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
	parm_code = "1" 

	SELECT * INTO pr_arparms.* 
	FROM arparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
	parm_code = "1" 
	OPEN WINDOW wja11 with FORM "JA11" -- alch kd-747 
	CALL winDecoration_j("JA11") -- alch kd-747 
	LET msgresp = kandoomsg("A",1001,"") 
	# MESSAGE " Enter Selection Criteria - ESC TO Continue"
	CONSTRUCT BY NAME query_text ON 
	tentinvhead.inv_num, 
	tentinvhead.contract_code, 
	tentinvhead.desc_text, 
	tentinvhead.total_amt 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","JA9","const-inv_num-4") -- alch kd-506 
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
	END CONSTRUCT 

	LET query_text = "SELECT * ", 
	"FROM tentinvhead ", 
	"WHERE cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	"AND ", query_text clipped 

	PREPARE sel_query_text FROM query_text 
	DECLARE tent_head_cur CURSOR with HOLD FOR sel_query_text 

	INITIALIZE pa_tentinvhead TO NULL 
	LET idx = 0 
	LET run_total_amt = 0 

	FOREACH tent_head_cur INTO pr_tentinvhead.* 
		LET idx = idx + 1 

		IF idx > 1000 THEN 
			ERROR "Only first 1000 invoices displayed" 
			EXIT FOREACH 
		END IF 

		LET pa_tentinvhead[idx].line_ind = "*" 
		LET pa_tentinvhead[idx].inv_num = pr_tentinvhead.inv_num 
		LET pa_tentinvhead[idx].contract_code = pr_tentinvhead.contract_code 
		LET pa_tentinvhead[idx].desc_text = pr_contracthead.desc_text 
		LET pa_tentinvhead[idx].total_amt = pr_tentinvhead.total_amt 
		LET run_total_amt = run_total_amt + pa_tentinvhead[idx].total_amt 
	END FOREACH 

	CLOSE tent_head_cur 

	CALL set_count(idx) 

	MESSAGE " F3/F4 TO page fwd/bwd, F7 toggle invoice SELECT, ESC TO accept" 
	attribute (yellow) 

	DISPLAY BY NAME run_total_amt 

	INPUT ARRAY pa_tentinvhead WITHOUT DEFAULTS FROM sr_contracthead.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","JA9","input_arr-pa_tentinvhead-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (F7) 
			CASE 
				WHEN pa_tentinvhead[idx].line_ind = "*" 
					LET pa_tentinvhead[idx].line_ind = " " 
					DISPLAY pa_tentinvhead[idx].line_ind TO 
					sr_contracthead[scrn].line_ind 
					LET run_total_amt = run_total_amt - 
					pa_tentinvhead[idx].total_amt 
					DISPLAY BY NAME run_total_amt 

				WHEN pa_tentinvhead[idx].line_ind = " " 
					LET pa_tentinvhead[idx].line_ind = "*" 
					DISPLAY pa_tentinvhead[idx].line_ind TO 
					sr_contracthead[scrn].line_ind 
					LET run_total_amt = run_total_amt + 
					pa_tentinvhead[idx].total_amt 
					DISPLAY BY NAME run_total_amt 
			END CASE 

		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 

		AFTER FIELD line_ind 
			IF idx = arr_count() AND 
			fgl_lastkey() = fgl_keyval("down") THEN 
				ERROR "There are no more rows in the direction you are going" 
				NEXT FIELD line_ind 
			END IF 

		BEFORE FIELD inv_num 
			NEXT FIELD line_ind 

		BEFORE FIELD total_amt 
			NEXT FIELD line_ind 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 

	IF int_flag = true OR 
	quit_flag = true THEN 
		EXIT program 
	END IF 

	#   OPEN WINDOW win1 AT 18,3 with 1 rows, 74 columns
	#      attribute (border)      -- alch KD-747
	LET cnt = 0 

	FOR idx = 1 TO 1000 

		IF pa_tentinvhead[idx].line_ind = "*" THEN 

			SELECT * INTO pr_tentinvhead.* 
			FROM tentinvhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
			inv_num = pa_tentinvhead[idx].inv_num AND 
			contract_code = pa_tentinvhead[idx].contract_code 

			IF status = 0 THEN 
				CALL post_invoice() 
			END IF 

		END IF 

	END FOR 

	#   CLOSE WINDOW win1      -- alch KD-747

	CLOSE WINDOW wja11 

	CALL set_count(cnt) 
	OPEN WINDOW wja10 with FORM "JA10" -- alch kd-747 
	CALL winDecoration_j("JA10") -- alch kd-747 
	MESSAGE " F3/F4 TO page fwd/bwd, ESC TO continue" 
	attribute (yellow) 

	DISPLAY ARRAY pa_dspinv TO sr_contracthead.* 

		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","JA9","display-arr-dspinv") -- alch kd-506

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END DISPLAY 


	CLOSE WINDOW wja10 

END MAIN 


FUNCTION post_invoice() 


	DEFINE fr_services RECORD LIKE services.*, 
	fv_today DATE, 
	fv_ra_num int, 
	fv_seq_num SMALLINT, 
	fv_trans_amt LIKE jobledger.trans_amt, 
	fv_trans_qty LIKE jobledger.trans_qty, 
	fv_charge_amt LIKE jobledger.charge_amt, 
	fv_freq SMALLINT 


	#  ***********************************************************************
	#  Process tentative invoice header
	#

	GOTO bypass 
	LABEL recovery: 
	LET err_continue = error_recover(err_message, status) 
	IF err_continue != "Y" THEN 
		EXIT program 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 

		DISPLAY " Billing Invoice : ", pr_tentinvhead.contract_code at 1,1 

		LET pr_invoicehead.* = pr_tentinvhead.* 

		LET pr_invoicehead.inv_num = 

		next_trans_num(glob_rec_kandoouser.cmpy_code, TRAN_TYPE_INVOICE_IN, pr_invoicehead.acct_override_code) 
		IF pr_invoicehead.inv_num < 0 THEN 
			LET err_message = "JA9 - JM invoice number UPDATE" 
			LET status = pr_invoicehead.inv_num 
			GO TO recovery 
		END IF 

		LET cnt = cnt + 1 

		# USE TODAY'S DATE AS THE INVOICE DATE BUT STORE THE CONTRACT DATE
		# SO CONTRACTDATE CAN BE UPDATED WITH THE INVOICE NUMBER
		LET pv_contract_date = pr_invoicehead.inv_date 
		LET pr_invoicehead.inv_date = today 

		CALL get_conv_rate(glob_rec_kandoouser.cmpy_code, 
		pr_invoicehead.currency_code, 
		pr_invoicehead.inv_date, 
		"S") 
		RETURNING pr_invoicehead.conv_qty 

		SELECT term.* 
		INTO pr_term.* 
		FROM term, customer 
		WHERE customer.cmpy_code = pr_invoicehead.cmpy_code 
		AND customer.cust_code = pr_invoicehead.cust_code 
		AND customer.cmpy_code = term.cmpy_code 
		AND customer.term_code = term.term_code 

		CALL get_due_and_discount_date(pr_term.*, pr_invoicehead.inv_date) 
		RETURNING pr_invoicehead.due_date, pr_invoicehead.disc_date 
































		LET pa_dspinv[cnt].contract_code = pr_tentinvhead.contract_code 
		LET pa_dspinv[cnt].inv_num = pr_invoicehead.inv_num 
		LET pa_dspinv[cnt].inv_date = pr_invoicehead.inv_date 








		CASE 
			WHEN pr_tentinvhead.inv_ind = "D" 
				LET pa_dspinv[cnt].inv_type = "Consolid" 
			WHEN pr_tentinvhead.inv_ind = "3" 
				LET pa_dspinv[cnt].inv_type = TRAN_TYPE_JOB_JOB 
			OTHERWISE 
				LET pa_dspinv[cnt].inv_type = "Gen/Inv" 
		END CASE 


		LET pa_dspinv[cnt].total_amt = pr_invoicehead.total_amt 

		DECLARE tent_detl_cur CURSOR with HOLD FOR 
		SELECT * FROM tentinvdetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
		inv_num = pr_tentinvhead.inv_num 
		ORDER BY line_num 

		#      *******************************************************************
		#      Process each tentative invoice detail FOR above header
		#
		FOREACH tent_detl_cur INTO pr_tentinvdetl.* 

			LET pr_invoicedetl.cmpy_code = pr_tentinvdetl.cmpy_code 
			LET pr_invoicedetl.cust_code = pr_tentinvdetl.cust_code 
			LET pr_invoicedetl.inv_num = pr_invoicehead.inv_num 
			LET pr_invoicedetl.line_num = pr_tentinvdetl.line_num 
			LET pr_invoicedetl.line_num = pr_tentinvdetl.line_num 

			LET pr_invoicedetl.part_code = pr_tentinvdetl.part_code 
			LET pr_invoicedetl.ware_code = pr_tentinvdetl.ware_code 
			LET pr_invoicedetl.cat_code = pr_tentinvdetl.cat_code 
			LET pr_invoicedetl.ord_qty = pr_tentinvdetl.ord_qty 
			LET pr_invoicedetl.ship_qty = pr_tentinvdetl.ship_qty 
			LET pr_invoicedetl.prev_qty = pr_tentinvdetl.prev_qty 
			LET pr_invoicedetl.back_qty = pr_tentinvdetl.back_qty 
			LET pr_invoicedetl.ser_flag = pr_tentinvdetl.ser_flag 
			LET pr_invoicedetl.ser_qty = pr_tentinvdetl.ser_qty 
			LET pr_invoicedetl.line_text = pr_tentinvdetl.line_text 
			LET pr_invoicedetl.uom_code = pr_tentinvdetl.uom_code 
			LET pr_invoicedetl.unit_cost_amt = pr_tentinvdetl.unit_cost_amt 
			LET pr_invoicedetl.ext_cost_amt = pr_tentinvdetl.ext_cost_amt 
			LET pr_invoicedetl.disc_amt = pr_tentinvdetl.disc_amt 
			LET pr_invoicedetl.unit_sale_amt = pr_tentinvdetl.unit_sale_amt 
			LET pr_invoicedetl.ext_sale_amt = pr_tentinvdetl.ext_sale_amt 
			LET pr_invoicedetl.unit_tax_amt = pr_tentinvdetl.unit_tax_amt 
			LET pr_invoicedetl.ext_tax_amt = pr_tentinvdetl.ext_tax_amt 
			LET pr_invoicedetl.line_total_amt = pr_tentinvdetl.line_total_amt 
			LET pr_invoicedetl.seq_num = pr_tentinvdetl.seq_num 
			LET pr_invoicedetl.line_acct_code = pr_tentinvdetl.line_acct_code 
			LET pr_invoicedetl.level_code = pr_tentinvdetl.level_code 
			LET pr_invoicedetl.comm_amt = pr_tentinvdetl.comm_amt 
			LET pr_invoicedetl.comp_per = pr_tentinvdetl.comp_per 
			LET pr_invoicedetl.tax_code = pr_tentinvdetl.tax_code 
			LET pr_invoicedetl.order_line_num = pr_tentinvdetl.order_line_num 

			## This IS because the service line num IS carried across in the order_num
			## field. IF it's NOT a job, THEN LET it continue as norm.

			IF pr_tentinvhead.inv_ind <> "3" THEN 
				LET pr_invoicedetl.order_num = pr_tentinvdetl.order_num 
			END IF 


			LET pr_invoicedetl.disc_per = pr_tentinvdetl.disc_per 
			LET pr_invoicedetl.offer_code = pr_tentinvdetl.offer_code 
			LET pr_invoicedetl.sold_qty = pr_tentinvdetl.sold_qty 
			LET pr_invoicedetl.bonus_qty = pr_tentinvdetl.bonus_qty 
			LET pr_invoicedetl.ext_bonus_amt = pr_tentinvdetl.ext_bonus_amt 
			LET pr_invoicedetl.ext_stats_amt = pr_tentinvdetl.ext_stats_amt 
			LET pr_invoicedetl.prodgrp_code = pr_tentinvdetl.prodgrp_code 
			LET pr_invoicedetl.maingrp_code = pr_tentinvdetl.maingrp_code 
			LET pr_invoicedetl.list_price_amt = pr_tentinvdetl.list_price_amt 
			LET pr_invoicedetl.var_code = pr_tentinvdetl.var_code 
			LET pr_invoicedetl.activity_code = pr_tentinvdetl.activity_code 
			LET pr_invoicedetl.jobledger_seq_num =pr_tentinvdetl.jobledger_seq_num 
			LET pr_invoicedetl.contract_line_num = 
			pr_tentinvdetl.contract_line_num 

			#         *******************************************************************
			#         Update product STATUS
			#
			IF pr_invoicedetl.part_code IS NOT NULL 
			AND pr_invoicedetl.ship_qty != 0 THEN 

				LET pv_found_one = false 

				DECLARE ps1_curs CURSOR FOR 
				SELECT * 
				INTO pr_prodstatus.* 
				FROM prodstatus 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pr_invoicedetl.part_code 
				AND ware_code = pr_invoicedetl.ware_code 
				FOR UPDATE 

				FOREACH ps1_curs 

					LET pv_found_one = true 
					LET pr_prodstatus.seq_num = pr_prodstatus.seq_num + 1 
					LET pr_invoicedetl.seq_num = pr_prodstatus.seq_num 
					IF pr_prodstatus.onhand_qty IS NULL THEN 
						LET pr_prodstatus.onhand_qty = 0 
					END IF 
					# Dont adjust onhand VALUES FOR non-stocked Inventory
					IF pr_prodstatus.stocked_flag = "Y" THEN 
						LET pr_prodstatus.onhand_qty = pr_prodstatus.onhand_qty - 
						pr_invoicedetl.ship_qty 
						# It IS completely invalid TO alter the reserved qty on prodstatus
						# unless tentative invoicing adds TO it (which it doesnt !)
						#         LET pr_prodstatus.reserved_qty = pr_prodstatus.reserved_qty -
						#                                          pr_invoicedetl.ship_qty
					END IF 

					UPDATE prodstatus 
					SET onhand_qty = pr_prodstatus.onhand_qty, 
					reserved_qty = pr_prodstatus.reserved_qty, 
					last_sale_date = pr_invoicehead.inv_date, 
					seq_num = pr_prodstatus.seq_num 
					WHERE CURRENT OF ps1_curs 

				END FOREACH 

				#  UPDATE TO latest cost of sales
				LET pr_invoicedetl.unit_cost_amt = pr_prodstatus.wgted_cost_amt 
				* pr_invoicehead.conv_qty 
				LET pr_invoicedetl.ext_cost_amt = pr_invoicedetl.unit_cost_amt 
				* pr_invoicedetl.ship_qty 

				#            *******************************************************************
				#            Update product ledger
				#
				IF pv_found_one = true THEN 
					INITIALIZE pr_prodledg.* TO NULL 
					LET pr_prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET pr_prodledg.part_code = pr_invoicedetl.part_code 
					LET pr_prodledg.ware_code = pr_invoicedetl.ware_code 
					LET pr_prodledg.tran_date = pr_invoicehead.inv_date 
					LET pr_prodledg.seq_num = pr_prodstatus.seq_num 
					LET pr_prodledg.trantype_ind = "S" 
					LET pr_prodledg.year_num = pr_invoicehead.year_num 
					LET pr_prodledg.period_num = pr_invoicehead.period_num 
					LET pr_prodledg.source_text = pr_invoicedetl.cust_code 
					LET pr_prodledg.source_num = pr_invoicedetl.inv_num 
					LET pr_prodledg.tran_qty = 0 - pr_invoicedetl.ship_qty + 0 
					LET pr_prodledg.bal_amt = pr_prodstatus.onhand_qty 

					IF pr_invoicehead.conv_qty IS NOT NULL AND 
					pr_invoicehead.conv_qty != 0 THEN 
						LET pr_prodledg.cost_amt = pr_invoicedetl.unit_cost_amt / 
						pr_invoicehead.conv_qty 
						LET pr_prodledg.sales_amt = pr_invoicedetl.unit_sale_amt / 
						pr_invoicehead.conv_qty 
					ELSE 
						LET pr_prodledg.cost_amt = 0 
						LET pr_prodledg.sales_amt = 0 
					END IF 

					IF pr_inparms.hist_flag = "Y" THEN 
						LET pr_prodledg.hist_flag = "N" 
					ELSE 
						LET pr_prodledg.hist_flag = "Y" 
					END IF 

					LET pr_prodledg.post_flag = "N" 
					LET pr_prodledg.entry_code = glob_rec_kandoouser.sign_on_code 
					LET pr_prodledg.entry_date = today 

					INSERT INTO prodledg VALUES (pr_prodledg.*) 
				END IF 
			END IF 

			#         *******************************************************************
			#         Update job activity details
			#





			IF pr_tentinvhead.inv_ind = "3" 
			OR pr_tentinvhead.inv_ind = "D" 
			AND pr_tentinvdetl.contract_line_num IS NOT NULL THEN 

				IF pr_tentinvhead.inv_ind = "3" THEN 
					SELECT * 
					INTO pr_job.* 
					FROM job 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND job_code = pr_invoicehead.job_code 

					IF status != 0 THEN 
						LET err_message = "JA9 - Job code NOT found ", 
						pr_invoicehead.job_code 
						GOTO recovery 
					END IF 

				ELSE 
					# Invoice ind = 5 (Consolidated)

					SELECT * 
					INTO pr_contractdetl.* 
					FROM contractdetl 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND contract_code = pr_invoicehead.contract_code 
					AND line_num = pr_invoicedetl.contract_line_num 

					IF status != 0 THEN 
						LET err_message = "JA9 - Contract line NOT found FOR ", glob_rec_kandoouser.cmpy_code, 
						" ", pr_invoicehead.contract_code, " ", 
						pr_invoicedetl.contract_line_num 
						GOTO recovery 
					END IF 

					SELECT * 
					INTO pr_job.* 
					FROM job 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND job_code = pr_contractdetl.job_code 

					IF status != 0 THEN 
						LET err_message = "JA9 - Job code NOT found ", 
						pr_invoicehead.job_code 
						GOTO recovery 
					END IF 
				END IF 


				IF pr_invoicedetl.activity_code IS NOT NULL THEN 
					DECLARE upd_act CURSOR FOR 
					SELECT * 
					FROM activity 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

					AND job_code = pr_job.job_code 
					AND var_code = pr_invoicedetl.var_code 
					AND activity_code = pr_invoicedetl.activity_code 
					FOR UPDATE 

					OPEN upd_act 
					FETCH upd_act INTO pr_activity.* 

					LET err_message = "JA9 - Activity Actual Update" 

					# FOR recurring jobs we NEVER accumulate the bill qty
					# instead we SET TO the qty on jobledger cos they
					# can't amend this anyway

					IF pr_job.bill_way_ind = "R" THEN 
						UPDATE activity 
						SET act_bill_amt = pr_activity.act_bill_amt + 
						pr_invoicedetl.line_total_amt, 
						post_cost_amt = pr_activity.post_cost_amt + 
						pr_invoicedetl.ext_cost_amt, 
						act_bill_qty = pr_invoicedetl.ship_qty 
						WHERE CURRENT OF upd_act 
					ELSE 
						UPDATE activity 
						SET act_bill_amt = pr_activity.act_bill_amt + 
						pr_invoicedetl.line_total_amt, 
						post_cost_amt = pr_activity.post_cost_amt + 
						pr_invoicedetl.ext_cost_amt, 
						act_bill_qty = pr_activity.act_bill_qty + 
						pr_invoicedetl.ship_qty 
						WHERE CURRENT OF upd_act 
					END IF 
				END IF 


				#  Must INSERT INTO jobledger HERE!!! This IS because the jobledger rows
				#  don't exist, so we create them now off the services table - only occurs if
				#  invoice type IS = 2 (Detail), AND the invoice IS a job. I've put the
				#  service_line_num in the tentinvdetl.order_num field, but I've made sure it
				#  doesn't recognize it FOR an ORDER .












				IF (pr_invoicehead.inv_ind = "3" OR 
				pr_invoicehead.inv_ind = "D") 
				AND (pr_tentinvhead.bill_issue_ind = "2" OR 
				pr_tentinvhead.bill_issue_ind = "4") 
				AND pr_invoicedetl.activity_code IS NOT NULL THEN 


					SELECT services.* 
					INTO fr_services.* 
					FROM services 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND contract_code = pr_invoicehead.contract_code 
					AND contract_line_num = pr_invoicedetl.contract_line_num 
					AND service_line_num = pr_tentinvdetl.order_num 
					AND status_code = "A" 

					LET fv_today = today 

					## Get next resource allocation number
					SELECT ra_num 
					INTO fv_ra_num 
					FROM jmparms 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET fv_ra_num = fv_ra_num + 1 
					UPDATE jmparms 
					SET ra_num = fv_ra_num 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

					## Get contracthead since no-one ELSE did!!
					SELECT contracthead.* 
					INTO pr_contracthead.* 
					FROM contracthead 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND contract_code = pr_invoicehead.contract_code 

					## Get next sequence number FOR jobledger FROM activity
					LET fv_seq_num = pr_activity.seq_num + 1 
					UPDATE activity 
					SET seq_num = fv_seq_num 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND job_code = pr_job.job_code 
					AND var_code = pr_invoicedetl.var_code 
					AND activity_code = pr_invoicedetl.activity_code 

					## Calculations
					LET fv_trans_amt = 0 
					LET fv_trans_qty = 0 
					LET fv_charge_amt = 0 
					IF pr_contracthead.bill_type_code = "A" OR 
					pr_contracthead.bill_type_code = "D" THEN 
						LET fv_freq = 1 
					ELSE 
						LET fv_freq = (12/pr_contracthead.bill_int_ind) 
					END IF 
					CASE 
						WHEN fr_services.bill_type_ind = "R" 
							LET fv_trans_amt = fr_services.cost_amt 
							LET fv_trans_qty = fr_services.qty 
							LET fv_charge_amt = (fr_services.charge_amt/fv_freq) 

						WHEN fr_services.bill_type_ind = "C" 
							LET fv_trans_amt = (fr_services.cost_amt/fv_freq) 
							LET fv_trans_qty = fr_services.qty 
							LET fv_charge_amt = fr_services.charge_amt 

						WHEN fr_services.bill_type_ind = "Q" 
							LET fv_trans_amt = fr_services.cost_amt 
							LET fv_trans_qty = (fr_services.qty/fv_freq) 
							LET fv_charge_amt = fr_services.charge_amt 

						WHEN fr_services.bill_type_ind = "B" 
							LET fv_trans_amt = (fr_services.cost_amt/fv_freq) 
							LET fv_trans_qty = fr_services.qty 
							LET fv_charge_amt = (fr_services.charge_amt/fv_freq) 

						WHEN fr_services.bill_type_ind = "A" 
							LET fv_trans_amt = (fr_services.cost_amt/fv_freq) 
							LET fv_trans_qty = (fr_services.qty/fv_freq) 
							LET fv_charge_amt = (fr_services.charge_amt/fv_freq) 

						WHEN fr_services.bill_type_ind = "D" 
							LET fv_trans_amt = fr_services.cost_amt 
							LET fv_trans_qty = fr_services.qty 
							LET fv_charge_amt = fr_services.charge_amt 

							## This UPDATE IS part of the spec
							UPDATE services 
							SET status_code = "C" 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND contract_code = pr_invoicehead.contract_code 
							AND contract_line_num = 
							pr_invoicedetl.contract_line_num 
							AND service_line_num = pr_tentinvdetl.order_num 

					END CASE 
					LET pr_invoicehead.job_code = pr_job.job_code 
					INSERT INTO jobledger VALUES ( glob_rec_kandoouser.cmpy_code, 
					fv_today, 
					pr_invoicehead.year_num, 
					pr_invoicehead.period_num, 
					pr_invoicehead.job_code, 
					pr_invoicedetl.var_code, 
					pr_invoicedetl.activity_code, 
					fv_seq_num, 
					"RE", 
					fv_ra_num, 
					fr_services.service_code, 
					fv_trans_amt, 
					fv_trans_qty, 
					fv_charge_amt, 
					"N", 
					fr_services.desc_text, 
					"A" 
					) 
					LET pr_invoicedetl.jobledger_seq_num = fv_seq_num 

				END IF 


				#         *******************************************************************
				#         Update resbill
				#

				IF pr_invoicedetl.jobledger_seq_num <> 0 THEN 
					SELECT * 
					INTO pr_jobledger.* 
					FROM jobledger 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

					AND job_code = pr_job.job_code 
					AND var_code = pr_invoicedetl.var_code 
					AND activity_code = pr_invoicedetl.activity_code 
					AND seq_num = pr_invoicedetl.jobledger_seq_num 

					IF status != 0 THEN 
						LET err_message = "JA9 - Jobledger code NOT found ", 

						pr_job.job_code, " ", 
						pr_invoicedetl.var_code, " ", 
						pr_invoicedetl.activity_code, " ", 
						pr_invoicedetl.jobledger_seq_num 
						GOTO recovery 
					END IF 

					LET err_message = "JA9 - Insert Resbill Rows" 
					LET pr_resbill.cmpy_code = glob_rec_kandoouser.cmpy_code 

					LET pr_resbill.job_code = pr_job.job_code 
					LET pr_resbill.var_code = pr_invoicedetl.var_code 
					LET pr_resbill.activity_code = pr_invoicedetl.activity_code 
					LET pr_resbill.res_code = pr_jobledger.trans_source_text 
					LET pr_resbill.seq_num = pr_invoicedetl.jobledger_seq_num 
					LET pr_resbill.inv_num = pr_invoicehead.inv_num 
					LET pr_resbill.line_num = pr_invoicedetl.line_num 
					LET pr_resbill.apply_qty = pr_invoicedetl.ship_qty 
					LET pr_resbill.apply_amt = pr_invoicedetl.ext_sale_amt 
					LET pr_resbill.apply_cos_amt = pr_invoicedetl.ext_cost_amt 
					LET pr_resbill.desc_text = pr_invoicedetl.line_text 
					LET pr_resbill.tran_type_ind = "2" 
					LET pr_resbill.tran_date = pr_invoicehead.inv_date 
					LET pr_resbill.orig_inv_num = NULL 
					INSERT INTO resbill VALUES (pr_resbill.*) 
				END IF 
			END IF 

			#         *********************************************************************
			#         Update tentative invoice detail
			#

			# UPDATE SALES HISTORY TRANS TABLE
			IF pr_invoicehead.org_cust_code IS NULL THEN 
				LET pv_cust_code = pr_invoicehead.cust_code 
			ELSE 
				LET pv_cust_code = pr_invoicehead.org_cust_code 
			END IF 

			CALL upd_sales_trans(glob_rec_kandoouser.cmpy_code, 
			"I", 
			pv_cust_code, 
			pr_invoicedetl.cat_code, 
			pr_invoicedetl.part_code, 
			pr_invoicedetl.line_text, 
			pr_invoicedetl.ware_code, 
			pr_invoicehead.sale_code, 
			pr_invoicehead.acct_override_code, 
			pr_invoicehead.year_num, 
			pr_invoicehead.period_num, 
			pr_invoicedetl.ship_qty, 
			pr_invoicehead.conv_qty, 
			pr_invoicedetl.ext_cost_amt, 
			pr_invoicedetl.ext_sale_amt, 
			pr_invoicedetl.ext_tax_amt, 
			pr_invoicedetl.disc_amt) 


			INSERT INTO invoicedetl VALUES (pr_invoicedetl.*) 
		END FOREACH 

		CLOSE tent_detl_cur 

		#      **********************************************************************
		#      Update tentative invoice header
		#

		INSERT INTO invoicehead VALUES (pr_invoicehead.*) 

		#      **********************************************************************
		#      Update customer details
		#
		LET err_message = "JA9 - Customer Update SELECT" 

		DECLARE cm1_curs CURSOR FOR 
		SELECT * 
		INTO pr_customer.* 
		FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = pr_invoicehead.cust_code 
		FOR UPDATE 

		OPEN cm1_curs 
		FETCH cm1_curs 

		LET err_message = "JA9 - Customer Rows Updated " 
		LET pr_customer.next_seq_num = pr_customer.next_seq_num + 1 
		LET pr_customer.bal_amt = pr_customer.bal_amt + pr_invoicehead.total_amt 
		LET pr_customer.curr_amt = pr_customer.curr_amt +pr_invoicehead.total_amt 

		IF pr_customer.bal_amt > pr_customer.highest_bal_amt THEN 
			LET pr_customer.highest_bal_amt = pr_customer.bal_amt 
		END IF 

		LET pr_customer.cred_bal_amt = pr_customer.cred_limit_amt - 
		(pr_customer.bal_amt + pr_customer.onorder_amt) 

		IF year(pr_invoicehead.inv_date) > year(pr_customer.last_inv_date) THEN 
			LET pr_customer.ytds_amt = 0 
		END IF 

		LET pr_customer.ytds_amt = pr_customer.ytds_amt +pr_invoicehead.total_amt 

		IF (month(pr_invoicehead.inv_date) > month(pr_customer.last_inv_date) 
		OR year(pr_invoicehead.inv_date) > year(pr_customer.last_inv_date)) THEN 
			LET pr_customer.mtds_amt = 0 
		END IF 

		LET pr_customer.mtds_amt = pr_customer.mtds_amt +pr_invoicehead.total_amt 

		IF pr_invoicehead.inv_date > pr_customer.last_inv_date THEN 
			LET pr_customer.last_inv_date = pr_invoicehead.inv_date 
		END IF 

		LET err_message = "JA9 - Customer Table Actual Update " 

		UPDATE customer SET next_seq_num = pr_customer.next_seq_num, 
		bal_amt = pr_customer.bal_amt, 
		curr_amt = pr_customer.curr_amt, 
		highest_bal_amt = pr_customer.highest_bal_amt, 
		cred_bal_amt = pr_customer.cred_bal_amt, 
		last_inv_date = pr_customer.last_inv_date, 
		ytds_amt = pr_customer.ytds_amt, 
		mtds_amt = pr_customer.mtds_amt 
		WHERE CURRENT OF cm1_curs 
		CLOSE cm1_curs 

		#      ****************************************************************
		#      Update araudit details
		#

		LET err_message = "JA9 - Unable TO add TO AR log table " 
		LET pr_araudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pr_araudit.entry_code = glob_rec_kandoouser.sign_on_code 
		LET pr_araudit.tran_date = pr_invoicehead.inv_date 
		LET pr_araudit.cust_code = pr_invoicehead.cust_code 
		LET pr_araudit.seq_num = pr_customer.next_seq_num 
		LET pr_araudit.tran_type_ind = TRAN_TYPE_INVOICE_IN 
		LET pr_araudit.source_num = pr_invoicehead.inv_num 
		LET pr_araudit.tran_text = "Enter Invoice" 
		LET pr_araudit.tran_amt = pr_invoicehead.total_amt 
		LET pr_araudit.sales_code = pr_invoicehead.sale_code 
		LET pr_araudit.bal_amt = pr_customer.bal_amt 
		LET pr_araudit.year_num = pr_invoicehead.year_num 
		LET pr_araudit.period_num = pr_invoicehead.period_num 
		LET pr_araudit.currency_code = pr_customer.currency_code 
		LET pr_araudit.conv_qty = pr_invoicehead.conv_qty 
		LET pr_araudit.entry_date = today 

		INSERT INTO araudit VALUES (pr_araudit.*) 

		#      **********************************************************************
		#      Update contract date
		#
		LET err_message = "JA9 - Unable TO UPDATE contractdate table" 


		SELECT * 
		INTO pr_contractdate.* 
		FROM contractdate 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND contract_code = pr_invoicehead.contract_code 
		AND invoice_date = pv_contract_date 
		AND inv_num IS NULL 
		AND invoice_total_amt IS NULL 

		IF status = notfound THEN 
			LET pr_contractdate.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET pr_contractdate.contract_code = pr_invoicehead.contract_code 
			LET pr_contractdate.inv_num = pr_invoicehead.inv_num 
			LET pr_contractdate.invoice_date = pv_contract_date 
			LET pr_contractdate.invoice_total_amt = pr_invoicehead.total_amt 

			INSERT INTO contractdate VALUES (pr_contractdate.*) 
		ELSE 


			UPDATE contractdate 
			SET inv_num = pr_invoicehead.inv_num, 
			invoice_total_amt = pr_invoicehead.total_amt 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND contract_code = pr_invoicehead.contract_code 

			AND invoice_date = pv_contract_date 
		END IF 


		#      **********************************************************************
		#      Update contract header
		#
		LET err_message = "JA9 - Unable TO UPDATE contracthead table" 

		UPDATE contracthead 
		SET last_billed_date = pr_contractdate.invoice_date 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND contract_code = pr_invoicehead.contract_code 
		AND cust_code = pr_invoicehead.cust_code 

		#      *********************************************************************
		#      Clear out tentative invoice details
		#

		LET err_message = "JA9 - Unable TO delete tentative source details" 

		DELETE FROM tentinvdetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND inv_num = pr_tentinvhead.inv_num 

		DELETE FROM tentinvhead 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND inv_num = pr_tentinvhead.inv_num 

	COMMIT WORK 

END FUNCTION 
