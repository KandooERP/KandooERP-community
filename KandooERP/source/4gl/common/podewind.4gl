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

	Source code beautified by beautify.pl on 2020-01-02 10:35:26	$Id: $
}



############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

GLOBALS 
	DEFINE glob_arr_rec_purchdetl DYNAMIC ARRAY OF #array [2000] OF RECORD 
		RECORD 
			scroll_flag CHAR(1), 
			line_num LIKE purchdetl.line_num, 
			type_ind LIKE purchdetl.type_ind, 
			ref_text LIKE purchdetl.ref_text, 
			order_qty LIKE poaudit.order_qty, 
			uom_code LIKE purchdetl.uom_code, 
			line_total_amt LIKE poaudit.line_total_amt 
		END RECORD 
		DEFINE glob_rec_poaudit RECORD LIKE poaudit.* 
		DEFINE glob_rec_purchdetl RECORD LIKE purchdetl.* 
		DEFINE glob_rec_purchhead RECORD LIKE purchhead.* 
		DEFINE glob_rec_vendor RECORD LIKE vendor.* 
		#l_msgresp,ans CHAR(1)
END GLOBALS 


############################################################
# FUNCTION podewind(p_cmpy_code, p_order_number)
#
#
############################################################
FUNCTION podewind(p_cmpy_code,p_order_number) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_order_number INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE idx SMALLINT 

	INITIALIZE glob_rec_purchdetl.* TO NULL 
	OPTIONS DELETE KEY f36, 
	INSERT KEY f36 
	SELECT * INTO glob_rec_purchhead.* FROM purchhead 
	WHERE cmpy_code = p_cmpy_code 
	AND order_num = p_order_number 
	SELECT * INTO glob_rec_vendor.* FROM vendor 
	WHERE cmpy_code = p_cmpy_code 
	AND vend_code = glob_rec_purchhead.vend_code 
	WHENEVER any ERROR CONTINUE 

	OPEN WINDOW r607 with FORM "R607" 
	CALL windecoration_r("R607") 

	WHENEVER any ERROR stop 
	IF status != 0 THEN 
		LET l_msgresp = kandoomsg("U",9917,"") 
		RETURN 
	END IF 
	LET l_msgresp = kandoomsg("U",1002,"") 
	#1002 Searching Database;  Please wait.
	DECLARE curser_item CURSOR FOR 
	SELECT purchdetl.* INTO glob_rec_purchdetl.* FROM purchdetl 
	WHERE order_num = p_order_number 
	AND cmpy_code = p_cmpy_code 
	ORDER BY line_num 
	LET idx = 0 

	FOREACH curser_item 
		LET idx = idx + 1 
		LET glob_arr_rec_purchdetl[idx].type_ind = glob_rec_purchdetl.type_ind 
		LET glob_arr_rec_purchdetl[idx].ref_text = glob_rec_purchdetl.ref_text 
		LET glob_arr_rec_purchdetl[idx].line_num = glob_rec_purchdetl.line_num 
		CALL po_line_info(p_cmpy_code, glob_rec_purchdetl.order_num, glob_rec_purchdetl.line_num) 
		RETURNING glob_rec_poaudit.order_qty, 
		glob_rec_poaudit.received_qty, 
		glob_rec_poaudit.voucher_qty, 
		glob_rec_poaudit.unit_cost_amt, 
		glob_rec_poaudit.ext_cost_amt, 
		glob_rec_poaudit.unit_tax_amt, 
		glob_rec_poaudit.ext_tax_amt, 
		glob_rec_poaudit.line_total_amt 
		LET glob_arr_rec_purchdetl[idx].order_qty = glob_rec_poaudit.order_qty 
		LET glob_arr_rec_purchdetl[idx].uom_code = glob_rec_purchdetl.uom_code 
		LET glob_arr_rec_purchdetl[idx].line_total_amt = glob_rec_poaudit.line_total_amt 
		IF idx = 2000 THEN 
			LET l_msgresp = kandoomsg("U",6100,idx) 
			#6100 First idx rows selected
			EXIT FOREACH 
		END IF 
	END FOREACH 

	LET l_msgresp = kandoomsg("U",9113,idx) 
	#9113 idx records selected
	CALL set_count(idx) 
	CALL credit_disp() 
	LET l_msgresp = kandoomsg("P",1512,"") 
	#1512 F5 PO Status;  ENTER on line TO View.

	INPUT ARRAY glob_arr_rec_purchdetl WITHOUT DEFAULTS FROM sr_purchdetl.* 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","podewind","input-arr-purchdetl") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 


		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON KEY (F5) 
			CALL pooswind(p_cmpy_code,p_order_number) 

		BEFORE ROW 
			LET idx = arr_curr() 
			#         LET scrn = scr_line()
			#         DISPLAY glob_arr_rec_purchdetl[idx].* TO sr_purchdetl[scrn].*

			SELECT * INTO glob_rec_purchdetl.* FROM purchdetl 
			WHERE cmpy_code = p_cmpy_code 
			AND line_num = glob_arr_rec_purchdetl[idx].line_num 
			AND order_num = p_order_number 
			DISPLAY BY NAME glob_rec_purchdetl.desc_text 

		BEFORE FIELD line_num 
			IF glob_arr_rec_purchdetl[idx].line_num IS NOT NULL THEN 
				CALL pord_window(p_cmpy_code) 
			END IF 
			NEXT FIELD scroll_flag 

		AFTER ROW 
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF glob_arr_rec_purchdetl[idx+1].type_ind IS NULL 
				OR arr_curr() >= arr_count() THEN 
					LET l_msgresp=kandoomsg("U",9001,"") 
					#9001 There no more rows...
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
			#         DISPLAY glob_arr_rec_purchdetl[idx].* TO sr_purchdetl[scrn].*

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
			END IF 

	END INPUT 

	CLOSE WINDOW r607 

	RETURN 
END FUNCTION 


############################################################
# FUNCTION credit_disp()
#
#
############################################################
FUNCTION credit_disp() 
	DEFINE l_order_total LIKE vendor.bal_amt 
	DEFINE l_credit_avail LIKE vendor.bal_amt 
	DEFINE i SMALLINT 

	LET l_order_total = 0 
	FOR i = 1 TO arr_count() 
		IF glob_arr_rec_purchdetl[i].line_total_amt IS NOT NULL THEN 
			LET l_order_total = l_order_total + glob_arr_rec_purchdetl[i].line_total_amt 
		END IF 
	END FOR 
	LET l_credit_avail = glob_rec_vendor.limit_amt 
	- glob_rec_vendor.bal_amt 
	DISPLAY l_order_total, l_credit_avail 
	TO l_order_total, l_credit_avail 

END FUNCTION 


############################################################
# FUNCTION pord_window(p_cmpy_code)
#
#
############################################################
FUNCTION pord_window(p_cmpy_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 

	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_rec_reqdetl RECORD LIKE reqdetl.* 
	DEFINE l_rec_job RECORD LIKE job.* 
	DEFINE l_rec_jobvars RECORD LIKE jobvars.* 
	DEFINE l_rec_jmresource RECORD LIKE jmresource.* 
	DEFINE l_rec_activity RECORD LIKE activity.* 
	DEFINE l_rec_jobledger RECORD LIKE jobledger.* 
	DEFINE l_tp_desc_text LIKE coa.desc_text 
	DEFINE l_unit_cost_amt LIKE poaudit.unit_cost_amt 

	SELECT * INTO l_rec_product.* FROM product 
	WHERE cmpy_code = p_cmpy_code 
	AND part_code = glob_rec_purchdetl.ref_text 

	SELECT * INTO l_rec_prodstatus.* FROM prodstatus 
	WHERE cmpy_code = p_cmpy_code 
	AND part_code = glob_rec_purchdetl.ref_text 
	AND ware_code = glob_rec_purchhead.ware_code 

	SELECT desc_text INTO l_tp_desc_text FROM coa 
	WHERE cmpy_code = p_cmpy_code 
	AND acct_code = glob_rec_purchdetl.acct_code 

	CALL po_line_info(p_cmpy_code, glob_rec_purchdetl.order_num, glob_rec_purchdetl.line_num) 
	RETURNING glob_rec_poaudit.order_qty, 
	glob_rec_poaudit.received_qty, 
	glob_rec_poaudit.voucher_qty, 
	glob_rec_poaudit.unit_cost_amt, 
	glob_rec_poaudit.ext_cost_amt, 
	glob_rec_poaudit.unit_tax_amt, 
	glob_rec_poaudit.ext_tax_amt, 
	glob_rec_poaudit.line_total_amt 

	CASE 
		WHEN glob_rec_purchdetl.type_ind = "G" 

			OPEN WINDOW r143 with FORM "R143" 
			CALL windecoration_r("R143") 

			DISPLAY BY NAME glob_rec_purchdetl.ref_text, 
			glob_rec_purchdetl.uom_code, 
			glob_rec_purchdetl.oem_text, 
			glob_rec_purchdetl.note_code 

		WHEN glob_rec_purchdetl.type_ind = "I" 

			OPEN WINDOW i211 with FORM "I211" 
			CALL windecoration_i("I211") 

			CALL display_stockstatus(p_cmpy_code,glob_rec_purchdetl.ref_text, 
			glob_rec_purchhead.ware_code) 
			DISPLAY BY NAME glob_rec_purchdetl.ref_text, 
			glob_rec_purchhead.ware_code, 
			l_rec_product.pur_uom_code, 
			l_rec_product.sell_uom_code, 
			glob_rec_purchdetl.oem_text, 
			glob_rec_purchdetl.note_code 

			CALL display_sell_uom(p_cmpy_code) 
		WHEN glob_rec_purchdetl.type_ind = "C" 

			OPEN WINDOW j177 with FORM "J177a" 
			CALL windecoration_j("J177a") 

			DISPLAY glob_rec_purchdetl.uom_code, 
			glob_rec_purchdetl.uom_code, 
			glob_rec_purchdetl.note_code 
			TO rec_uom_code, 
			vou_uom_code, 
			note_code 

			SELECT job.title_text INTO l_rec_job.title_text FROM job 
			WHERE cmpy_code = p_cmpy_code 
			AND job_code = glob_rec_purchdetl.job_code 
			SELECT jobvars.title_text INTO l_rec_jobvars.title_text FROM jobvars 
			WHERE cmpy_code = p_cmpy_code 
			AND job_code = glob_rec_purchdetl.job_code 
			AND var_code = glob_rec_purchdetl.var_num 
			SELECT activity.title_text INTO l_rec_activity.title_text FROM activity 
			WHERE cmpy_code = p_cmpy_code 
			AND job_code = glob_rec_purchdetl.job_code 
			AND var_code = glob_rec_purchdetl.var_num 
			AND activity_code = glob_rec_purchdetl.activity_code 
			SELECT jmresource.* INTO l_rec_jmresource.* FROM jmresource 
			WHERE cmpy_code = p_cmpy_code 
			AND res_code = glob_rec_purchdetl.res_code 

			LET l_rec_jmresource.unit_cost_amt = glob_rec_poaudit.unit_cost_amt 
			LET l_rec_jmresource.unit_bill_amt = glob_rec_purchdetl.charge_amt 
			LET l_rec_jobledger.trans_amt = glob_rec_poaudit.order_qty 
			* l_rec_jmresource.unit_cost_amt 
			LET l_rec_jobledger.charge_amt = glob_rec_poaudit.order_qty 
			* l_rec_jmresource.unit_bill_amt 
			LET l_unit_cost_amt = l_rec_jmresource.unit_cost_amt 
			CALL calc_jm_totals() 
			RETURNING l_rec_jmresource.unit_cost_amt, 
			l_rec_jobledger.trans_amt, 
			l_rec_jobledger.charge_amt 
			DISPLAY BY NAME l_rec_jmresource.res_code, 
			glob_rec_purchdetl.ref_text, 
			glob_rec_purchdetl.job_code, 
			glob_rec_purchdetl.var_num, 
			glob_rec_purchdetl.activity_code, 
			l_rec_jmresource.unit_code, 
			l_rec_jobledger.trans_amt, 
			l_rec_jmresource.unit_bill_amt, 
			l_rec_jobledger.charge_amt, 
			l_rec_jmresource.unit_cost_amt, 
			l_rec_jobledger.trans_amt, 
			l_rec_jobledger.charge_amt 

			DISPLAY l_rec_job.title_text, 
			l_rec_jobvars.title_text, 
			l_rec_activity.title_text 
			TO job.title_text, 
			jobvars.title_text, 
			activity.title_text 
		WHEN glob_rec_purchdetl.type_ind = "J" 

			OPEN WINDOW j177 with FORM "J177" 
			CALL windecoration_j("J177") 

			DISPLAY glob_rec_purchdetl.uom_code, 
			glob_rec_purchdetl.uom_code, 
			glob_rec_purchdetl.note_code 
			TO rec_uom_code, 
			vou_uom_code, 
			note_code 

			SELECT job.title_text INTO l_rec_job.title_text FROM job 
			WHERE cmpy_code = p_cmpy_code 
			AND job_code = glob_rec_purchdetl.job_code 
			SELECT jobvars.title_text INTO l_rec_jobvars.title_text FROM jobvars 
			WHERE cmpy_code = p_cmpy_code 
			AND job_code = glob_rec_purchdetl.job_code 
			AND var_code = glob_rec_purchdetl.var_num 
			SELECT activity.title_text INTO l_rec_activity.title_text FROM activity 
			WHERE cmpy_code = p_cmpy_code 
			AND job_code = glob_rec_purchdetl.job_code 
			AND var_code = glob_rec_purchdetl.var_num 
			AND activity_code = glob_rec_purchdetl.activity_code 
			SELECT jmresource.* INTO l_rec_jmresource.* FROM jmresource 
			WHERE cmpy_code = p_cmpy_code 
			AND res_code = glob_rec_purchdetl.res_code 
			LET l_rec_jmresource.unit_cost_amt = glob_rec_poaudit.unit_cost_amt 
			LET l_rec_jmresource.unit_bill_amt = glob_rec_purchdetl.charge_amt 
			LET l_rec_jobledger.trans_amt = glob_rec_poaudit.order_qty 
			* l_rec_jmresource.unit_cost_amt 
			LET l_rec_jobledger.charge_amt = glob_rec_poaudit.order_qty 
			* l_rec_jmresource.unit_bill_amt 
			LET l_unit_cost_amt = l_rec_jmresource.unit_cost_amt 
			CALL calc_jm_totals() 
			RETURNING l_rec_jmresource.unit_cost_amt, 
			l_rec_jobledger.trans_amt, 
			l_rec_jobledger.charge_amt 
			DISPLAY 
			l_rec_jmresource.res_code, 
			glob_rec_purchdetl.job_code, 
			glob_rec_purchdetl.var_num, 
			glob_rec_purchdetl.activity_code, 
			glob_rec_purchdetl.oem_text, 
			l_rec_jmresource.unit_code, 
			l_rec_jobledger.trans_amt, 
			l_rec_jmresource.unit_bill_amt, 
			l_rec_jobledger.charge_amt, 
			l_rec_jmresource.unit_cost_amt, 
			l_rec_jobledger.trans_amt, 
			l_rec_jobledger.charge_amt 
			TO 
			res_code, 
			job_code, 
			var_num, 
			activity_code, 
			oem_text, 
			unit_code, 
			trans_amt, 
			unit_bill_amt, 
			charge_amt, 
			unit_cost_amt, 
			trans_amt, 
			charge_amt 

			DISPLAY l_rec_job.title_text, 
			l_rec_jobvars.title_text, 
			l_rec_activity.title_text 
			TO job.title_text, 
			jobvars.title_text, 
			activity.title_text 

	END CASE 

	DISPLAY BY NAME glob_rec_purchhead.curr_code 
	attribute(green) 

	LET glob_rec_poaudit.tran_date = glob_rec_purchhead.order_date 
	LET glob_rec_poaudit.year_num = glob_rec_purchhead.year_num 
	LET glob_rec_poaudit.period_num = glob_rec_purchhead.period_num 

	DISPLAY 
	glob_rec_poaudit.tran_date, 
	glob_rec_poaudit.year_num, 
	glob_rec_poaudit.period_num, 
	glob_rec_purchdetl.desc_text, 
	glob_rec_purchdetl.desc2_text, 
	glob_rec_purchdetl.note_code, 
	glob_rec_purchdetl.acct_code, 
	l_tp_desc_text 
	TO 
	glob_rec_poaudit.tran_date, 
	glob_rec_poaudit.year_num, 
	glob_rec_poaudit.period_num, 
	glob_rec_purchdetl.desc_text, 
	glob_rec_purchdetl.desc2_text, 
	glob_rec_purchdetl.note_code, 
	glob_rec_purchdetl.acct_code, 
	tp_desc_text 

	CALL disp_po_totals() 

	MENU " Purchase Order" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","podewind","menu-Purchase_Order-1") -- albo kd-503 
			IF glob_rec_purchdetl.req_num IS NULL THEN 
				HIDE option "Requisition" 
			END IF 
			IF glob_rec_purchdetl.note_code IS NULL 
			OR glob_rec_purchdetl.note_code = " " THEN 
				HIDE option "Notes" 
			END IF 
		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 
		COMMAND "History" " View purchase ORDER line history" 
			CALL pohiwind(p_cmpy_code, 
			glob_rec_purchdetl.vend_code, 
			glob_rec_purchdetl.order_num, 
			glob_rec_purchdetl.line_num) 
		COMMAND "Notes" " View purchase ORDER line notes" 
			CALL disp_note(glob_rec_purchdetl.cmpy_code, 
			glob_rec_purchdetl.note_code) 
		COMMAND "Requisition" " View requisition information FOR purchase ORDER" 
			CALL requisition_inquiry(p_cmpy_code,glob_rec_purchdetl.req_num,1) 
		COMMAND "Status" " View purchase ORDER STATUS" 
			CALL pooswind(p_cmpy_code,glob_rec_purchdetl.order_num) 
		COMMAND KEY(interrupt,escape,"E") "Exit" " Exit FROM this query" 
			EXIT MENU 

	END MENU 

	CASE glob_rec_purchdetl.type_ind 
		WHEN "G" 
			CLOSE WINDOW r143 
		WHEN "I" 
			CLOSE WINDOW i211 
		WHEN "J" OR "C" 
			CLOSE WINDOW j177 
	END CASE 

END FUNCTION 
