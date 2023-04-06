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

	Source code beautified by beautify.pl on 2020-01-02 17:06:14	Source code beautified by beautify.pl on 2020-01-02 17:03:23	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "R_PU_GLOBALS.4gl" 

{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module R17 allows the user TO search FOR orders that require
#             completion AND complete those purchase orders

--DEFINE msgresp LIKE language.yes_flag
DEFINE pr_purchhead RECORD LIKE purchhead.* 
DEFINE comp_flag CHAR(1) 

#######################################################################
# MAIN
#
#
#######################################################################
MAIN 

	CALL setModuleId("R17") -- albo 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_r_pu() #init r/pu purchase ORDER module 

	CALL create_table("purchdetl","t_purchdetl","","N") 
	CALL create_table("poaudit","t_poaudit","","N") 
	OPEN WINDOW r147 with FORM "R147" 
	CALL  windecoration_r("R147") 

	WHILE enter_selection() 
		CALL cancel_order() 
	END WHILE 

	CLOSE WINDOW r147 

END MAIN 


FUNCTION enter_selection() 
	DEFINE 
	tmp_cnt SMALLINT, 
	sel_text, where_part CHAR(500), 
	pr_vend_code LIKE vendor.vend_code, 
	pr_order_num LIKE purchhead.order_num 

	CLEAR FORM 
	LET pr_order_num = NULL 
	LET comp_flag = NULL 
	LET msgresp = kandoomsg("U",1001,"") 
	#1001 Enter Selection Criteria;  OK TO Continue.
	INPUT pr_vend_code, 
	pr_order_num, 
	comp_flag WITHOUT DEFAULTS 
	FROM purchhead.vend_code, 
	purchhead.order_num, 
	complete_flag 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","R17","inp-purchhead-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

			--- modif ericv # AFTER INPUT
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	LET msgresp = kandoomsg("W",1002,"") 
	#1002 Searching database;  Please wait.
	LET sel_text = "SELECT * ", 
	"FROM purchhead WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"'" 
	IF pr_vend_code IS NOT NULL THEN 
		LET sel_text = sel_text clipped, " ", 
		"AND vend_code = '",pr_vend_code,"'" 
	END IF 
	IF pr_order_num IS NOT NULL THEN 
		LET sel_text = sel_text clipped, " ", 
		"AND order_num = '",pr_order_num,"'" 
	END IF 
	LET sel_text = sel_text clipped, " ","AND status_ind != 'C' ", 
	" ORDER BY vend_code " 
	PREPARE getpord FROM sel_text 
	DECLARE c_pord CURSOR FOR getpord 
	RETURN true 
END FUNCTION 


FUNCTION cancel_order() 
	DEFINE 
	pr_purchhead RECORD LIKE purchhead.*, 
	pt_purchhead RECORD LIKE purchhead.*, 
	pa_purchhead array[2000] OF RECORD 
		scroll_flag CHAR(1), 
		vend_code LIKE purchhead.vend_code, 
		order_num LIKE purchhead.order_num, 
		status_ind LIKE purchhead.status_ind, 
		order_total LIKE poaudit.line_total_amt, 
		receipt_total LIKE poaudit.line_total_amt, 
		voucher_total LIKE poaudit.line_total_amt, 
		complete_flag CHAR(1) 
	END RECORD, 
	pr_tmp RECORD 
		order_total LIKE poaudit.line_total_amt, 
		receipt_total LIKE poaudit.line_total_amt, 
		voucher_total LIKE poaudit.line_total_amt, 
		tax_tot money(12,2) 
	END RECORD, 
	idx, id_flag, scrn, cnt, err_flag SMALLINT, 
	tax_tot, received_tot, voucher_tot money(12,2), 
	pr_cancel_cnt SMALLINT, 
	pr_scroll_flag CHAR(1) 

	LET idx = 0 
	FOREACH c_pord INTO pr_purchhead.* 
		CALL po_head_info( glob_rec_kandoouser.cmpy_code, pr_purchhead.order_num) 
		RETURNING pr_tmp.order_total, 
		pr_tmp.receipt_total, 
		pr_tmp.voucher_total, 
		pr_tmp.tax_tot 
		IF comp_flag = "Y" THEN 
			IF pr_tmp.order_total != pr_tmp.receipt_total 
			OR pr_tmp.order_total != pr_tmp.voucher_total THEN 
				CONTINUE FOREACH 
			END IF 
		END IF 
		IF comp_flag = "N" THEN 
			IF pr_tmp.order_total = pr_tmp.receipt_total 
			AND pr_tmp.order_total = pr_tmp.voucher_total THEN 
				CONTINUE FOREACH 
			END IF 
		END IF 
		LET idx = idx + 1 
		LET pa_purchhead[idx].scroll_flag = NULL 
		LET pa_purchhead[idx].vend_code = pr_purchhead.vend_code 
		LET pa_purchhead[idx].order_num = pr_purchhead.order_num 
		LET pa_purchhead[idx].order_total = pr_tmp.order_total 
		LET pa_purchhead[idx].receipt_total = pr_tmp.receipt_total 
		LET pa_purchhead[idx].voucher_total = pr_tmp.voucher_total 
		LET tax_tot = pr_tmp.tax_tot 
		IF pa_purchhead[idx].order_total = pa_purchhead[idx].voucher_total 
		AND pa_purchhead[idx].order_total = pa_purchhead[idx].receipt_total THEN 
			LET pa_purchhead[idx].complete_flag = "Y" 
		ELSE 
			LET pa_purchhead[idx].complete_flag = "N" 
		END IF 
		LET pa_purchhead[idx].status_ind = pr_purchhead.status_ind 
		IF idx = 1500 THEN 
			LET msgresp=kandoomsg("U",9010,idx) 
			#9100 First 1500
			EXIT FOREACH 
		END IF 
	END FOREACH 
	IF idx = 0 THEN 
		LET msgresp=kandoomsg("U",1021,"") 
		#9101 No rows satisfied the selection criteria
		RETURN 
	END IF 
	CALL set_count (idx) 
	LET msgresp = kandoomsg("U",9113,idx) 
	#9113 idx records selected.
	LET msgresp = kandoomsg("R",1018,"") 
	#1018 F3/F4 Page Fwd/Bwd; F6 Backorder Cancel; F7 Close Order;
	#     ENTER on line TO Edit.
	OPTIONS DELETE KEY f36, 
	INSERT KEY f38 

	INPUT ARRAY pa_purchhead WITHOUT DEFAULTS FROM sr_purchhead.* ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","R12","inp-arr-purchhead-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
		BEFORE FIELD scroll_flag 
			LET pr_scroll_flag = pa_purchhead[idx].scroll_flag 
			DISPLAY pa_purchhead[idx].* TO sr_purchhead[scrn].* 

		AFTER FIELD scroll_flag 
			LET pa_purchhead[idx].scroll_flag = pr_scroll_flag 
			IF fgl_lastkey() = fgl_keyval("nextpage") THEN 
				IF pa_purchhead[idx+13].vend_code IS NULL THEN 
					LET msgresp = kandoomsg("U",9001,"") 
					#9001 There are no more rows in the direction you are going.
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
			IF fgl_lastkey() = fgl_keyval("down") 
			AND arr_curr() = arr_count() THEN 
				LET msgresp = kandoomsg("U",9001,"") 
				#9001 There are no more rows in the direction you are going.
				NEXT FIELD scroll_flag 
			END IF 
		ON KEY (F7) 
			IF pa_purchhead[idx].status_ind = "C" THEN 
				LET msgresp = kandoomsg("P",9552,"") 
				#9552 The purchase ORDER has already been closed.
				NEXT FIELD scroll_flag 
			END IF 
			IF pa_purchhead[idx].order_num > 0 THEN 
				IF pa_purchhead[idx].order_total = pa_purchhead[idx].voucher_total 
				AND pa_purchhead[idx].order_total = pa_purchhead[idx].receipt_total 
				THEN 
					LET pa_purchhead[idx].complete_flag = "Y" 
				ELSE 
					IF close_order(glob_rec_kandoouser.cmpy_code, 
					pa_purchhead[idx].order_num, 
					pa_purchhead[idx].order_total, 
					pa_purchhead[idx].voucher_total) THEN 
						LET pa_purchhead[idx].status_ind = "C" 
						LET pa_purchhead[idx].complete_flag = "Y" 
					ELSE 
						NEXT FIELD scroll_flag 
					END IF 
					CALL po_head_info(glob_rec_kandoouser.cmpy_code, pa_purchhead[idx].order_num) 
					RETURNING pa_purchhead[idx].order_total, 
					pa_purchhead[idx].receipt_total, 
					pa_purchhead[idx].voucher_total, 
					tax_tot 
					LET msgresp = kandoomsg("R",1018,"") 
					#1018 F3/F4 Page Fwd/Bwd; F6 Backorder Cancel; F7 Close Order ...
					DELETE FROM t_poaudit WHERE 1=1 
				END IF 
				IF (pa_purchhead[idx].order_total = pa_purchhead[idx].voucher_total 
				AND pa_purchhead[idx].order_total = pa_purchhead[idx].receipt_total) 
				THEN 
					LET pa_purchhead[idx].complete_flag = "Y" 
					IF pa_purchhead[idx].scroll_flag IS NULL AND 
					pa_purchhead[idx].status_ind <> "C" THEN 
						LET pa_purchhead[idx].scroll_flag = "*" 
					END IF 
				ELSE 
					IF pa_purchhead[idx].status_ind != "C" THEN 
						LET pa_purchhead[idx].complete_flag = "N" 
					END IF 
					LET pa_purchhead[idx].scroll_flag = NULL 
				END IF 
				DISPLAY pa_purchhead[idx].scroll_flag, 
				pa_purchhead[idx].status_ind 
				TO sr_purchhead[scrn].scroll_flag, 
				sr_purchhead[scrn].status_ind 

				NEXT FIELD scroll_flag 
			END IF 
		ON KEY (F6) 
			IF pa_purchhead[idx].order_num > 0 THEN 
				IF pa_purchhead[idx].order_total = pa_purchhead[idx].voucher_total 
				AND pa_purchhead[idx].order_total = pa_purchhead[idx].receipt_total 
				THEN 
					LET pa_purchhead[idx].complete_flag = "Y" 
				ELSE 
					CALL backorder_cancel(glob_rec_kandoouser.cmpy_code, pa_purchhead[idx].order_num) 
					CALL po_head_info( glob_rec_kandoouser.cmpy_code, pa_purchhead[idx].order_num) 
					RETURNING pa_purchhead[idx].order_total, 
					pa_purchhead[idx].receipt_total, 
					pa_purchhead[idx].voucher_total, 
					tax_tot 
					LET msgresp = kandoomsg("R",1018,"") 
					#1018 F3/F4 Page Fwd/Bwd; F6 Backorder Cancel; F7 Close Order ...
				END IF 
				IF pa_purchhead[idx].order_total = pa_purchhead[idx].voucher_total 
				AND pa_purchhead[idx].order_total = pa_purchhead[idx].receipt_total 
				THEN 
					LET pa_purchhead[idx].complete_flag = "Y" 
					IF pa_purchhead[idx].scroll_flag IS NULL THEN 
						LET pa_purchhead[idx].scroll_flag = "*" 
					END IF 
				ELSE 
					LET pa_purchhead[idx].complete_flag = "N" 
					LET pa_purchhead[idx].scroll_flag = NULL 
				END IF 
				DISPLAY pa_purchhead[idx].* TO sr_purchhead[scrn].* 

				DELETE FROM t_purchdetl WHERE 1=1 
				NEXT FIELD scroll_flag 
			END IF 
		BEFORE FIELD vend_code 
			IF pa_purchhead[idx].order_num > 0 THEN 
				IF pa_purchhead[idx].status_ind = "C" THEN 
					LET msgresp = kandoomsg("R",9520,"") 
					#9520 The purchase ORDER cannot be edited as it IS completed.
					NEXT FIELD scroll_flag 
				END IF 
				IF po_mod(glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code,pa_purchhead[idx].order_num, "EDIT") THEN 
				END IF 
				OPTIONS DELETE KEY f36, 
				INSERT KEY f38 
				CALL po_head_info( glob_rec_kandoouser.cmpy_code, pa_purchhead[idx].order_num) 
				RETURNING pa_purchhead[idx].order_total, 
				pa_purchhead[idx].receipt_total, 
				pa_purchhead[idx].voucher_total, 
				tax_tot 
				IF pa_purchhead[idx].order_total = pa_purchhead[idx].voucher_total 
				AND pa_purchhead[idx].order_total = pa_purchhead[idx].receipt_total 
				THEN 
					LET pa_purchhead[idx].complete_flag = "Y" 
				ELSE 
					LET pa_purchhead[idx].complete_flag = "N" 
				END IF 
				DISPLAY pa_purchhead[idx].* TO sr_purchhead[scrn].* 

			END IF 
			NEXT FIELD scroll_flag 
		AFTER ROW 
			DISPLAY pa_purchhead[idx].* TO sr_purchhead[scrn].* 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				LET pr_cancel_cnt = 0 
				FOR idx = 1 TO arr_count() 
					IF pa_purchhead[idx].scroll_flag = "*" THEN 
						LET pr_cancel_cnt = pr_cancel_cnt + 1 
					END IF 
				END FOR 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
	ELSE 
		IF pr_cancel_cnt > 0 THEN 
			IF kandoomsg("R",8006,pr_cancel_cnt) = 'Y' THEN 
				#8006 Confirm TO complete pr_cancel_cnt purchase orders? (Y/N):
				FOR idx = 1 TO arr_count() 
					IF pa_purchhead[idx].scroll_flag = "*" THEN 
						IF pa_purchhead[idx].order_total = 
						pa_purchhead[idx].voucher_total 
						AND pa_purchhead[idx].order_total = 
						pa_purchhead[idx].receipt_total 
						AND pa_purchhead[idx].complete_flag = "Y" THEN 
							UPDATE purchhead 
							SET status_ind = "C", 
							rev_num = pr_purchhead.rev_num + 1, 
							rev_date = today 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND order_num = pa_purchhead[idx].order_num 
							AND vend_code = pa_purchhead[idx].vend_code 
						END IF 
					END IF 
				END FOR 
			END IF 
		END IF 
	END IF 
END FUNCTION 


FUNCTION backorder_cancel(p_cmpy, pr_po_num) 
	DEFINE 
	p_cmpy LIKE company.cmpy_code, 
	pr_po_num LIKE purchhead.order_num, 
	pr_purchhead RECORD LIKE purchhead.*, 
	pr_vendor RECORD LIKE vendor.*, 
	pf_purchdetl RECORD LIKE purchdetl.*, 
	cu_poaudit RECORD LIKE poaudit.*, 
	pr_old_onorder_amt LIKE vendor.onorder_amt, 
	pr_new_onorder_amt LIKE vendor.onorder_amt, 
	err_message CHAR(40), 
	pr_err_stat INTEGER 

	SELECT * INTO pr_purchhead.* FROM purchhead 
	WHERE cmpy_code = p_cmpy 
	AND order_num = pr_po_num 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("U",7001,"Order") 
		#7001 "Logic Error
		RETURN 
	END IF 
	GOTO bypass1 
	LABEL recovery1: 
	IF status != 0 THEN 
		LET pr_err_stat = status 
	END IF 
	IF error_recover(err_message,pr_err_stat) != "Y" THEN 
		RETURN 
	END IF 
	LABEL bypass1: 
	WHENEVER ERROR GOTO recovery1 
	BEGIN WORK 
		LET msgresp = kandoomsg("U",1005,"") 
		#1005 Updating database...
		DECLARE c1_vendor CURSOR FOR 
		SELECT * FROM vendor 
		WHERE cmpy_code = p_cmpy 
		AND vend_code = pr_purchhead.vend_code 
		FOR UPDATE 
		DECLARE c6_purchdetl CURSOR FOR 
		SELECT * FROM purchdetl 
		WHERE cmpy_code = p_cmpy 
		AND order_num = pr_purchhead.order_num 
		ORDER BY line_num 
		OPEN c1_vendor 
		FETCH c1_vendor INTO pr_vendor.* 
		LET pr_new_onorder_amt = 0 
		LET pr_old_onorder_amt = 0 
		FOREACH c6_purchdetl INTO pf_purchdetl.* 
			INSERT INTO t_purchdetl VALUES (pf_purchdetl.*) 
			LET err_message = "R21 - receipt line addition failed" 
			CALL po_line_info(p_cmpy, 
			pf_purchdetl.order_num, 
			pf_purchdetl.line_num) 
			RETURNING cu_poaudit.order_qty, 
			cu_poaudit.received_qty, 
			cu_poaudit.voucher_qty, 
			cu_poaudit.unit_cost_amt, 
			cu_poaudit.ext_cost_amt, 
			cu_poaudit.unit_tax_amt, 
			cu_poaudit.ext_tax_amt, 
			cu_poaudit.line_total_amt 
			LET pr_old_onorder_amt = pr_old_onorder_amt 
			+ ((cu_poaudit.order_qty - cu_poaudit.received_qty) 
			* (cu_poaudit.unit_cost_amt + cu_poaudit.unit_tax_amt)) 
			IF cu_poaudit.received_qty < cu_poaudit.order_qty THEN 
				LET cu_poaudit.tran_date = today 
				CALL db_period_what_period(p_cmpy, cu_poaudit.tran_date) 
				RETURNING cu_poaudit.year_num, cu_poaudit.period_num 
				LET cu_poaudit.order_qty = cu_poaudit.received_qty 
				CALL mod_po_line(p_cmpy, glob_rec_kandoouser.sign_on_code, pr_purchhead.*, 
				pf_purchdetl.*, 
				cu_poaudit.*) 
				RETURNING pr_err_stat 
				IF pr_err_stat < 0 THEN 
					GO TO recovery1 
				END IF 
			END IF 
			CALL po_line_info(p_cmpy, 
			pf_purchdetl.order_num, 
			pf_purchdetl.line_num) 
			RETURNING cu_poaudit.order_qty, 
			cu_poaudit.received_qty, 
			cu_poaudit.voucher_qty, 
			cu_poaudit.unit_cost_amt, 
			cu_poaudit.ext_cost_amt, 
			cu_poaudit.unit_tax_amt, 
			cu_poaudit.ext_tax_amt, 
			cu_poaudit.line_total_amt 
			LET pr_new_onorder_amt = pr_new_onorder_amt 
			+ ((cu_poaudit.order_qty - cu_poaudit.received_qty) 
			* (cu_poaudit.unit_cost_amt + cu_poaudit.unit_tax_amt)) 
		END FOREACH 
		LET pr_new_onorder_amt = pr_new_onorder_amt - pr_old_onorder_amt 
		UPDATE vendor 
		SET onorder_amt = onorder_amt + pr_new_onorder_amt 
		WHERE cmpy_code = p_cmpy 
		AND vend_code = pr_purchhead.vend_code 
	COMMIT WORK 
	WHENEVER ERROR stop 
END FUNCTION 

FUNCTION close_order(p_cmpy, pr_po_num, pr_order_total, pr_vouch_amt) 
	DEFINE 
	p_cmpy LIKE company.cmpy_code, 
	pr_po_num LIKE purchhead.order_num, 
	pr_purchhead RECORD LIKE purchhead.*, 
	pr_vendor RECORD LIKE vendor.*, 
	pr_purchdetl RECORD LIKE purchdetl.*, 
	pr_poaudit RECORD LIKE poaudit.*, 
	pr_reconcile_amt, 
	pr_reconcile_total, 
	pr_lower_limit, 
	pr_upper_limit, 
	pr_new_voucher_total LIKE poaudit.line_total_amt, 
	pr_amt_text CHAR(11), 
	pr_err_message CHAR(40), 
	pr_err_status INTEGER, 
	pr_received_qty LIKE poaudit.received_qty, 
	pr_voucher_qty LIKE poaudit.voucher_qty, 
	pr_received_total LIKE poaudit.received_qty, 
	pr_voucher_total LIKE poaudit.voucher_qty, 
	pr_order_total, pr_vouch_amt LIKE poaudit.line_total_amt 

	SELECT * INTO pr_purchhead.* FROM purchhead 
	WHERE cmpy_code = p_cmpy 
	AND order_num = pr_po_num 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("U",7001,"Order") 
		#7001 "Logic Error
		RETURN false 
	END IF 
	SELECT * INTO pr_vendor.* FROM vendor, purchhead 
	WHERE vendor.cmpy_code = p_cmpy 
	AND purchhead.cmpy_code = vendor.cmpy_code 
	AND purchhead.order_num = pr_po_num 
	AND vendor.vend_code = purchhead.vend_code 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("P",9060,pr_purchdetl.vend_code) 
		#9060 Logic Error: Vendor <Value> does NOT exist.
		RETURN false 
	END IF 
	LET pr_lower_limit = 
	pr_order_total * (1 -(pr_vendor.po_var_per/100)) 
	LET pr_upper_limit = 
	pr_order_total * (1 +(pr_vendor.po_var_per/100)) 
	IF pr_lower_limit < 
	(pr_order_total - pr_vendor.po_var_amt) THEN 
		LET pr_lower_limit = 
		pr_order_total - pr_vendor.po_var_amt 
	END IF 
	IF pr_upper_limit > 
	(pr_order_total + pr_vendor.po_var_amt) THEN 
		LET pr_upper_limit = 
		pr_order_total + pr_vendor.po_var_amt 
	END IF 
	IF (pr_vouch_amt < pr_lower_limit) OR 
	(pr_vouch_amt > pr_upper_limit) THEN 
		LET pr_amt_text = pr_vouch_amt USING "<<<<<<<&.&&" 
		LET msgresp = kandoomsg("P",9081,pr_amt_text) 
		#9081 Amount outside allowable price variance FOR this Vendor
		RETURN false 
	END IF 
	LET pr_reconcile_amt = 0 
	LET pr_reconcile_total = 0 
	DECLARE c7_purchdetl CURSOR FOR 
	SELECT * FROM purchdetl 
	WHERE cmpy_code = p_cmpy 
	AND order_num = pr_po_num 
	ORDER BY line_num 
	FOREACH c7_purchdetl INTO pr_purchdetl.* 
		CALL po_line_info(p_cmpy, 
		pr_purchdetl.order_num, 
		pr_purchdetl.line_num) 
		RETURNING pr_poaudit.order_qty, 
		pr_poaudit.received_qty, 
		pr_poaudit.voucher_qty, 
		pr_poaudit.unit_cost_amt, 
		pr_poaudit.ext_cost_amt, 
		pr_poaudit.unit_tax_amt, 
		pr_poaudit.ext_tax_amt, 
		pr_poaudit.line_total_amt 
		IF pr_poaudit.order_qty != pr_poaudit.received_qty 
		OR pr_poaudit.order_qty != pr_poaudit.voucher_qty THEN 
			LET msgresp = kandoomsg("R",9521,"") 
			#9521 The purchase ORDER has NOT been fully supplied.
			RETURN false 
		END IF 
		SELECT sum(line_total_amt) INTO pr_received_total FROM poaudit 
		WHERE cmpy_code = p_cmpy 
		AND po_num = pr_purchdetl.order_num 
		AND line_num = pr_purchdetl.line_num 
		AND received_qty != 0 
		IF pr_received_total IS NULL 
		OR pr_received_total = " " THEN 
			LET pr_received_total = 0 
		END IF 
		SELECT sum(line_total_amt) INTO pr_voucher_total FROM poaudit 
		WHERE cmpy_code = p_cmpy 
		AND po_num = pr_purchdetl.order_num 
		AND line_num = pr_purchdetl.line_num 
		AND voucher_qty != 0 
		IF pr_voucher_total IS NULL 
		OR pr_voucher_total = " " THEN 
			LET pr_voucher_total = 0 
		END IF 
		IF (pr_received_total - pr_voucher_total) = 0 THEN 
			CONTINUE FOREACH 
		END IF 
		LET pr_reconcile_amt = (pr_received_total - pr_voucher_total) 
		LET pr_reconcile_total = pr_reconcile_total 
		+ pr_reconcile_amt 
		INITIALIZE pr_poaudit.* TO NULL 
		LET pr_poaudit.cmpy_code = p_cmpy 
		LET pr_poaudit.po_num = pr_purchdetl.order_num 
		LET pr_poaudit.line_num = pr_purchdetl.line_num 
		LET pr_poaudit.seq_num = pr_purchdetl.seq_num 
		LET pr_poaudit.vend_code = pr_vendor.vend_code 
		LET pr_poaudit.tran_code = "CE" 
		LET pr_poaudit.tran_num = 0 
		LET pr_poaudit.tran_date = today 
		LET pr_poaudit.entry_date = today 
		LET pr_poaudit.entry_code = glob_rec_kandoouser.sign_on_code 
		LET pr_poaudit.orig_auth_flag = "N" 
		LET pr_poaudit.now_auth_flag = "N" 
		LET pr_poaudit.order_qty = 0 
		LET pr_poaudit.received_qty = 0 
		LET pr_poaudit.voucher_qty = 1 
		LET pr_poaudit.desc_text = "Reconciliation Closing Entry" 
		LET pr_poaudit.unit_cost_amt = 0 
		LET pr_poaudit.ext_cost_amt = 0 
		LET pr_poaudit.unit_tax_amt = 0 
		LET pr_poaudit.ext_tax_amt = 0 
		LET pr_poaudit.line_total_amt = pr_reconcile_amt 
		IF pr_purchhead.type_ind = "3" THEN 
			# Expense Accounting
			LET pr_poaudit.posted_flag = "Y" 
		ELSE 
			LET pr_poaudit.posted_flag = "N" 
		END IF 
		LET pr_poaudit.jour_num = 0 
		CALL db_period_what_period(p_cmpy,today) 
		RETURNING pr_poaudit.year_num, 
		pr_poaudit.period_num 
		INSERT INTO t_poaudit VALUES (pr_poaudit.*) 
	END FOREACH 
	LET msgresp = kandoomsg("R",8502,pr_reconcile_total) 
	#8502 The total amount TO reconcile IS pr_reconcile_total
	#     Do you wish TO continue? (Y/N):
	IF msgresp = "N" THEN 
		RETURN false 
	END IF 
	GOTO bypass 
	LABEL recovery: 
	LET msgresp = error_recover(pr_err_message, pr_err_status) 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	BEGIN WORK 
		LET pr_err_message = "Purchase Order Detail Update" 
		LET pr_err_message = "Purchase Order Audit Insert" 
		DECLARE c9_poaudit CURSOR FOR 
		SELECT * FROM t_poaudit 
		WHERE 1 = 1 
		FOREACH c9_poaudit INTO pr_poaudit.* 
			DECLARE c8_purchdetl CURSOR FOR 
			SELECT * FROM purchdetl 
			WHERE cmpy_code = p_cmpy 
			AND order_num = pr_po_num 
			AND line_num = pr_poaudit.line_num 
			FOR UPDATE 
			OPEN c8_purchdetl 
			FETCH c8_purchdetl INTO pr_purchdetl.* 
			LET pr_purchdetl.seq_num = pr_purchdetl.seq_num + 1 
			LET pr_poaudit.seq_num = pr_purchdetl.seq_num 
			INSERT INTO poaudit VALUES (pr_poaudit.*) 
			UPDATE purchdetl 
			SET seq_num = seq_num + 1 
			WHERE cmpy_code = p_cmpy 
			AND order_num = pr_po_num 
			AND line_num = pr_poaudit.line_num 
			CLOSE c8_purchdetl 
		END FOREACH 
		LET pr_err_message = "Purchase Order Header does NOT exist" 
		SELECT * INTO pr_purchhead.* FROM purchhead 
		WHERE order_num = pr_po_num 
		AND cmpy_code = p_cmpy 
		DECLARE c8_purchhead CURSOR FOR 
		SELECT * FROM purchhead 
		WHERE order_num = pr_po_num 
		AND cmpy_code = p_cmpy 
		FOR UPDATE 
		OPEN c8_purchhead 
		FETCH c8_purchhead INTO pr_purchhead.* 
		LET pr_err_message = "Purchase Order Header Update" 
		UPDATE purchhead 
		SET status_ind = "C", 
		rev_num = pr_purchhead.rev_num + 1, 
		rev_date = today 
		WHERE order_num = pr_po_num 
		AND cmpy_code = p_cmpy 
	COMMIT WORK 
	WHENEVER ERROR stop 
	RETURN true 
END FUNCTION 
