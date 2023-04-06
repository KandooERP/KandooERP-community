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
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"  
GLOBALS "../re/N_RE_GLOBALS.4gl"
GLOBALS "../re/N4_GROUP_GLOBALS.4gl"
GLOBALS "../re/N41_GLOBALS.4gl"  
# \brief module N41a - Internal Requisition Purchase Order Generation



FUNCTION enter_approval(pr_prog_name,pr_select) 
	DEFINE pr_prog_name CHAR(3) 
	DEFINE pr_select INTEGER
	DEFINE pr_rec_kandoouser RECORD LIKE kandoouser.* 
	DEFINE invalid_period SMALLINT
	DEFINE l_kandoo_log_msg CHAR(20) 
	DEFINE pr_trf_cnt SMALLINT 
	DEFINE pr_err_cnt SMALLINT 

	#   CALL authenticate(pr_prog_name)
	#      returning cmpy,glob_kandoouser_sign_on_code	--alch KD-494

	SELECT * INTO pr_puparms.* FROM puparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_code = "1" 
	IF status = notfound THEN 
		LET msgresp=kandoomsg("N",5018,"") 
		#5018 Purchasing Parameters Not Set Up.
		EXIT program 
	END IF 
	SELECT reqperson.* INTO pr_reqperson.* FROM reqperson 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND person_code = glob_rec_kandoouser.sign_on_code 
	IF status = notfound THEN 
		LET msgresp=kandoomsg("N",7010,glob_rec_kandoouser.sign_on_code) 
		#7010 User does NOT have authority TO Internal Requisitions.
		EXIT program 
	END IF 
	IF pr_reqperson.po_low_limit_amt IS NULL 
	OR pr_reqperson.po_up_limit_amt IS NULL 
	OR pr_reqperson.po_up_limit_amt < 0 THEN 
		LET msgresp=kandoomsg("N",7010,glob_rec_kandoouser.sign_on_code) 
		#7010 User does NOT have authority TO Internal Requisitions.
		EXIT program 
	END IF 
	IF pr_reqperson.po_start_date > today 
	OR pr_reqperson.po_exp_date < today THEN 
		LET msgresp=kandoomsg("N",7010,glob_rec_kandoouser.sign_on_code) 
		#7010 User does NOT have authority TO Internal Requisitions.
		EXIT program 
	END IF 
	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, today) RETURNING pr_period.year_num, 
	pr_period.period_num 
	CALL valid_period(glob_rec_kandoouser.cmpy_code,pr_period.year_num, 
	pr_period.period_num,"PU") 
	RETURNING pr_period.year_num, 
	pr_period.period_num, 
	invalid_period 
	IF invalid_period THEN 
		LET msgresp=kandoomsg("U",7026,pr_period.year_num) 
		#7026 Current Purchasing Fiscal Year & Period Not Set Up.
		EXIT program 
	END IF 
	CREATE temp TABLE reqpurch (vend_code CHAR(8), 
	ware_code CHAR(3), 
	part_code CHAR(15), 
	req_num INTEGER, 
	line_num INTEGER, 
	replenish_ind CHAR(1), 
	unit_sales_amt DECIMAL(16,4), 
	po_qty FLOAT, 
	desc_text CHAR(40) ) with no LOG 
	CREATE unique INDEX reqpurch1_key ON reqpurch(req_num,line_num) 
	CREATE INDEX reqpurch2_key ON reqpurch(vend_code,ware_code) 
	CREATE temp TABLE t_approve (replenish_ind CHAR(1), 
	approve_amt DECIMAL(16,4)) with no LOG 
	#   create index t_app_1_key on t_approve(replenish_ind)
	CREATE temp TABLE t_reqdetl (req_num INTEGER, 
	line_num INTEGER, 
	approve_qty float) with no LOG 
	CREATE INDEX t_req_1_key ON t_reqdetl(line_num) 
	CREATE temp TABLE t_reqdetl2 (scroll_flag CHAR(1), 
	line_num SMALLINT, 
	part_code CHAR(15), 
	req_qty FLOAT, 
	uom_code CHAR(4), 
	outer_flag CHAR(1), 
	unit_sales_amt DECIMAL(16,4), 
	line_total DECIMAL(16,4), 
	replenish_ind CHAR(1), 
	vend_code CHAR(8), 
	desc_text CHAR(30)) with no LOG 
	CREATE INDEX t_req2_key ON t_reqdetl2(vend_code,desc_text) 
	OPEN WINDOW n115 with FORM "N115" 
	CALL windecoration_n("N115") -- albo kd-763 
	WHILE select_req(pr_select) 
		IF scan_req() THEN 
			SELECT unique 1 FROM reqpurch 
			IF status = 0 THEN 
				LET pr_err_cnt = 0 
				CALL write_purchord() RETURNING pr_po_cnt, 
				pr_pnd_cnt, 
				pr_trf_cnt, 
				pr_first_ponum, 
				pr_last_ponum, 
				pr_first_pnnum, 
				pr_last_pnnum, 
				pr_first_trfnum, 
				pr_last_trfnum, 
				pr_err_cnt 
				IF pr_err_cnt > 0 THEN 
					LET l_kandoo_log_msg = pr_err_cnt USING "<<<<" 
					LET msgresp = kandoomsg("N",7033,"") 
					#7033 Requisition has been approved by another user.
				END IF 
				CALL req_summary() 
			END IF 
		END IF 
		DELETE FROM reqpurch WHERE 1=1 
		DELETE FROM t_approve WHERE 1=1 
		DELETE FROM t_reqdetl WHERE 1=1 
	END WHILE 
	CLOSE WINDOW n115 
END FUNCTION 


FUNCTION select_req(pr_select) 
	DEFINE 
	pr_select INTEGER, 
	pr_reqhead RECORD LIKE reqhead.*, 
	pr_reqperson RECORD LIKE reqperson.*, 
	where_text CHAR(500), 
	where2_text CHAR(500), 
	query_text CHAR(800), 
	idx SMALLINT 

	OPTIONS DELETE KEY f36, 
	INSERT KEY f36 
	IF pr_select THEN 
		LET where2_text = "reqhead.person_code = ", "\'",glob_rec_kandoouser.sign_on_code,"\'" 
	ELSE 
		LET where2_text = "1=1" 
	END IF 
	WHILE true 
		CLEAR FORM 
		LET msgresp=kandoomsg("U",1001,"") 
		#1001 Enter Selection Criteria; OK TO Continue.
		CONSTRUCT BY NAME where_text ON reqhead.req_num, 
		reqhead.person_code, 
		reqperson.name_text, 
		reqhead.stock_ind, 
		reqhead.req_date, 
		reqhead.ware_code, 
		reqhead.total_sales_amt, 
		reqhead.status_ind 

			ON ACTION "WEB-HELP" -- albo kd-377 
				CALL onlinehelp(getmoduleid(),null) 

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			EXIT WHILE 
		END IF 
		LET msgresp=kandoomsg("U",1002,"") 
		#1002 Searching database;  Please wait.
		LET query_text = 
		"SELECT reqhead.*,", 
		"reqperson.name_text ", 
		"FROM reqhead,", 
		"reqperson ", 
		"WHERE reqhead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND reqperson.cmpy_code = reqhead.cmpy_code ", 
		"AND reqperson.person_code = reqhead.person_code ", 
		"AND status_ind < 9 ", 
		"AND status_ind != 0 ", 
		"AND ",where_text clipped," ", 
		"AND ",where2_text clipped," ", 
		"AND exists ( SELECT 1 FROM reqdetl ", 
		"WHERE reqdetl.cmpy_code = reqhead.cmpy_code ", 
		"AND reqdetl.req_num = reqhead.req_num ", 
		"AND reqdetl.po_qty = 0 ", 
		"AND ( reqdetl.req_qty > reqdetl.po_qty ", 
		"OR ( reqdetl.back_qty > 0 ", 
		"AND reqdetl.back_qty > reqdetl.po_qty ) ) )", 
		"ORDER BY reqhead.req_num,", 
		" reqhead.cmpy_code" 
		PREPARE s_reqhead FROM query_text 
		DECLARE c_reqhead CURSOR FOR s_reqhead 
		LET idx = 0 
		FOREACH c_reqhead INTO pr_reqhead.*, 
			pr_reqperson.name_text 
			### Above PREPARE will SELECT requisitions WHERE STATUS in != 0
			### AND back quantity equals zero.  These need TO be filtered out
			IF pr_reqhead.stock_ind != '0' THEN 
				SELECT unique 1 FROM reqdetl 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND req_num = pr_reqhead.req_num 
				AND (back_qty > 0 AND po_qty = 0) 
				IF status = notfound THEN 
					CONTINUE FOREACH 
				END IF 
			END IF 
			LET idx = idx + 1 
			LET pa_reqhead[idx].scroll_flag = NULL 
			LET pa_reqhead[idx].req_num = pr_reqhead.req_num 
			LET pa_reqhead[idx].person_code = pr_reqhead.person_code 
			LET pa_reqhead[idx].name_text = pr_reqperson.name_text 
			LET pa_reqhead[idx].stock_ind = pr_reqhead.stock_ind 
			LET pa_reqhead[idx].req_date = pr_reqhead.req_date 
			LET pa_reqhead[idx].ware_code = pr_reqhead.ware_code 
			LET pa_reqhead[idx].total_sales_amt = pr_reqhead.total_sales_amt 
			LET pa_reqhead[idx].status_ind = pr_reqhead.status_ind 
			IF idx = 200 THEN 
				LET msgresp=kandoomsg("U",9010,idx) 
				#9010 First 200 Requisitions Selected Only.
				EXIT FOREACH 
			END IF 
		END FOREACH 
		IF idx = 0 THEN 
			LET msgresp=kandoomsg("U",9113,idx) 
			#9113 0 records selected.
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		LET arr_size = idx 
		RETURN true 
	END IF 
END FUNCTION 


FUNCTION scan_req() 
	DEFINE 
	pr_reqhead RECORD LIKE reqhead.*, 
	pr_reqperson RECORD LIKE reqperson.*, 
	pr_scroll_flag, 
	pr_scroll_flag2, 
	err_continue CHAR(1), 
	idx, scrn, pr_error_count SMALLINT 

	LET msgresp = kandoomsg("N",1045,"") 
	#1045 ENTER on line FOR Details;  F8 Approve Req;  OK TO Complete Order.
	CALL set_count(arr_size) 
	INPUT ARRAY pa_reqhead WITHOUT DEFAULTS FROM sr_reqhead.* 

		ON ACTION "WEB-HELP" -- albo kd-377 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (F8) 
			IF allocate_all(pr_reqhead.stock_ind) THEN 
			END IF 
			LET int_flag = false 
			LET quit_flag = false 
			LET msgresp = kandoomsg("N",1045,"") 
			#1045 ENTER on line FOR Details;  F8 Toggle All;  OK TO ...
			NEXT FIELD scroll_flag 
		BEFORE FIELD scroll_flag 
			LET pr_scroll_flag = pa_reqhead[idx].scroll_flag 
			DISPLAY pa_reqhead[idx].* TO sr_reqhead[scrn].* 

		AFTER FIELD scroll_flag 
			LET pa_reqhead[idx].scroll_flag = pr_scroll_flag 
			IF fgl_lastkey() = fgl_keyval("nextpage") THEN 
				IF pa_reqhead[idx+14].req_num IS NULL THEN 
					LET msgresp = kandoomsg("U",9001,"") 
					#9001 No more rows in this direction
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
			IF fgl_lastkey() = fgl_keyval("down") 
			AND arr_curr() = arr_count() THEN 
				LET msgresp = kandoomsg("W",9001,"") 
				#9001 No more Rows in direction
				NEXT FIELD scroll_flag 
			END IF 
			DISPLAY pa_reqhead[idx].* TO sr_reqhead[scrn].* 

		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
		BEFORE FIELD req_num 
			IF pa_reqhead[idx].req_num IS NOT NULL THEN 
				LET msgresp = kandoomsg("U",1002, "") 
				#1002 "Searching Database , please wait
				CALL create_po(pa_reqhead[idx].req_num) 
				LET msgresp=kandoomsg("N",1045,"") 
				#1045 Req. Purchase Orders - RETURN FOR Line Detail; OK ...
				SELECT total_sales_amt INTO pa_reqhead[idx].total_sales_amt 
				FROM reqhead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND req_num = pa_reqhead[idx].req_num 
				DISPLAY pa_reqhead[idx].total_sales_amt 
				TO sr_reqhead[scrn].total_sales_amt 

				SELECT unique 1 FROM reqpurch 
				WHERE req_num = pa_reqhead[idx].req_num 
				IF status = notfound THEN 
					LET pa_reqhead[idx].scroll_flag = NULL 
				ELSE 
					LET pa_reqhead[idx].scroll_flag = "*" 
				END IF 
			END IF 
			NEXT FIELD scroll_flag 
		AFTER INPUT 
			SELECT unique 1 FROM reqpurch 
			IF status = 0 THEN 
				IF int_flag OR quit_flag THEN 
					LET msgresp=kandoomsg("N",8023,"") 
					#8023 Do you wish TO Save Purchase Order Information? (Y/N)
					IF msgresp = 'Y' THEN 
						NEXT FIELD scroll_flag 
					ELSE 
						LET quit_flag = true 
					END IF 
				ELSE 
					LET msgresp=kandoomsg("N",8024,"") 
					#8024 Do you wish TO Generate Purchase Orders? (Y/N)
					IF msgresp = 'N' THEN 
						NEXT FIELD scroll_flag 
					END IF 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 


FUNCTION req_summary() 
	DEFINE 
	pr_glparms RECORD LIKE glparms.*, 
	pr_vendor RECORD LIKE vendor.*, 
	pr_ibtdetl RECORD LIKE ibtdetl.*, 
	pr_warehouse RECORD LIKE warehouse.*, 
	pr_purchhead RECORD LIKE purchhead.*, 
	pr_reqsummary RECORD 
		trans_type CHAR(2), 
		vend_code CHAR(8), 
		ware_code CHAR(3), 
		trans_num LIKE purchhead.order_num, 
		due_date LIKE purchhead.due_date, 
		status_ind LIKE purchhead.status_ind 
	END RECORD, 
	pa_reqsummary array[200] OF RECORD 
		scroll_flag CHAR(2), 
		trans_type CHAR(2), 
		vend_code CHAR(8), 
		ware_code CHAR(3), 
		trans_num LIKE purchhead.order_num, 
		due_date LIKE purchhead.due_date, 
		curr_code LIKE purchhead.curr_code, 
		total_amt LIKE poaudit.line_total_amt, 
		status_ind LIKE purchhead.status_ind 
	END RECORD, 
	where_text CHAR(300), 
	pr_scroll_flag CHAR(1), 
	pr_tax_tot, pr_received_tot, pr_voucher_tot money(12,2), 
	pr_cost_amt DECIMAL(16,4), 
	pr_tmp CHAR(1), 
	idx,scrn SMALLINT 

	SELECT * INTO pr_glparms.* FROM glparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	CLEAR FORM 
	OPEN WINDOW n134 with FORM "N134" 
	CALL windecoration_n("N134") -- albo kd-763 
	LET msgresp=kandoomsg("U",1002,"") 
	#1002 "Searching Database - Please Wait .."
	DECLARE c_reqsummary CURSOR FOR 
	SELECT "PO",vend_code,ware_code,order_num,due_date,status_ind 
	FROM purchhead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND order_num between pr_first_ponum AND pr_last_ponum 
	union 
	SELECT "PN",vend_code,ware_code,pend_num,due_date," " 
	FROM pendhead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND pend_num between pr_first_pnnum AND pr_last_pnnum 
	union 
	SELECT "SX",from_ware_code,to_ware_code,trans_num,trans_date,status_ind 
	FROM ibthead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND trans_num between pr_first_trfnum AND pr_last_trfnum 
	ORDER BY 1,2 
	LET idx = 0 
	FOREACH c_reqsummary INTO pr_reqsummary.* 
		LET idx = idx + 1 
		LET pa_reqsummary[idx].scroll_flag = NULL 
		LET pa_reqsummary[idx].trans_type = pr_reqsummary.trans_type 
		LET pa_reqsummary[idx].vend_code = pr_reqsummary.vend_code 
		LET pa_reqsummary[idx].ware_code = pr_reqsummary.ware_code 
		LET pa_reqsummary[idx].trans_num = pr_reqsummary.trans_num 
		LET pa_reqsummary[idx].due_date = pr_reqsummary.due_date 
		LET pa_reqsummary[idx].status_ind = pr_reqsummary.status_ind 
		IF pa_reqsummary[idx].trans_type = 'PO' THEN 
			SELECT * INTO pr_purchhead.* FROM purchhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND order_num = pr_reqsummary.trans_num 
			LET pa_reqsummary[idx].curr_code = pr_purchhead.curr_code 
			CALL po_head_info(glob_rec_kandoouser.cmpy_code, pr_purchhead.order_num) 
			RETURNING pa_reqsummary[idx].total_amt, 
			pr_received_tot, 
			pr_voucher_tot, 
			pr_tax_tot 
			INITIALIZE pr_vendor.* TO NULL 
			SELECT * INTO pr_vendor.* FROM vendor 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = pa_reqsummary[idx].vend_code 
			IF pa_reqsummary[idx].total_amt < pr_vendor.min_ord_amt THEN 
				LET pa_reqsummary[idx].status_ind = "*" 
			END IF 
		ELSE 
			LET pa_reqsummary[idx].curr_code = pr_glparms.base_currency_code 
			LET pa_reqsummary[idx].total_amt = 0 
			DECLARE c_ibtdetl CURSOR FOR 
			SELECT * FROM ibtdetl 
			WHERE trans_num = pa_reqsummary[idx].trans_num 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			FOREACH c_ibtdetl INTO pr_ibtdetl.* 
				LET pr_cost_amt = 0 
				SELECT wgted_cost_amt INTO pr_cost_amt FROM prodstatus 
				WHERE part_code = pr_ibtdetl.part_code 
				AND ware_code = pa_reqsummary[idx].vend_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET pa_reqsummary[idx].total_amt = pa_reqsummary[idx].total_amt 
				+ (pr_ibtdetl.trf_qty * pr_cost_amt) 
			END FOREACH 
			IF pa_reqsummary[idx].total_amt IS NULL THEN 
				LET pa_reqsummary[idx].total_amt = 0 
			END IF 
		END IF 
		IF idx = 2000 THEN 
			EXIT FOREACH 
		END IF 
	END FOREACH 
	LET msgresp=kandoomsg("U",9010,idx) 
	#9010 First idx rows selected
	CALL set_count(idx) 
	LET msgresp=kandoomsg("N",1047,"") 
	#1047 ENTER on line TO Edit;  OK TO Continue
	INPUT ARRAY pa_reqsummary WITHOUT DEFAULTS FROM sr_reqsummary.* 

		ON ACTION "WEB-HELP" -- albo kd-377 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (F9) 
			LET msgresp=kandoomsg("N",8025,"") 
			#8025 " Confirm TO PRINT purchase ORDER information"
			IF msgresp = 'Y' THEN 
				IF pr_first_ponum <> 0 
				OR pr_last_ponum <> 0 THEN 
					LET where_text = "1=1 AND purchhead.order_num between ", 
					pr_first_ponum, "AND ",pr_last_ponum 
					CALL run_prog("RS1",where_text,"","","") 
				END IF 
				# PRINT stock transfers
				IF pr_first_trfnum <> 0 
				OR pr_last_trfnum <> 0 THEN 
					CALL print_transfers() 
				END IF 

				CALL run_prog("URS","","","","") -- ON ACTION "Print Manager" 
			END IF 
		BEFORE FIELD scroll_flag 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			LET pr_scroll_flag = pa_reqsummary[idx].scroll_flag 
			CASE pa_reqsummary[idx].trans_type 
				WHEN "SX" 
					SELECT * INTO pr_warehouse.* FROM warehouse 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND ware_code = pa_reqsummary[idx].vend_code 
					DISPLAY pr_warehouse.desc_text, 
					pr_warehouse.addr1_text, 
					pr_warehouse.addr2_text 
					TO name_text, 
					addr1_text, 
					addr2_text 

				OTHERWISE 
					SELECT * INTO pr_vendor.* FROM vendor 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND vend_code = pa_reqsummary[idx].vend_code 
					DISPLAY BY NAME pr_vendor.name_text, 
					pr_vendor.addr1_text, 
					pr_vendor.addr2_text 

			END CASE 
			IF pa_reqsummary[idx].status_ind = "*" THEN 
				LET msgresp = kandoomsg("N",9062,pr_vendor.min_ord_amt) 
				#9062 Order amount less than vendors minimum ORDER amount
			END IF 
			DISPLAY pa_reqsummary[idx].* TO sr_reqsummary[scrn].* 

		AFTER FIELD scroll_flag 
			LET pa_reqsummary[idx].scroll_flag = pr_scroll_flag 
			IF fgl_lastkey() = fgl_keyval("nextpage") THEN 
				IF pa_reqsummary[idx+9].trans_num IS NULL THEN 
					LET msgresp = kandoomsg("U",9001,"") 
					#9001 No more rows in this direction
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
			IF fgl_lastkey() = fgl_keyval("down") 
			AND arr_curr() = arr_count() THEN 
				LET msgresp = kandoomsg("W",9001,"") 
				#9001 No more Rows in direction
				NEXT FIELD scroll_flag 
			END IF 
			DISPLAY pa_reqsummary[idx].* TO sr_reqsummary[scrn].* 

		BEFORE FIELD trans_type 
			CASE pa_reqsummary[idx].trans_type 
				WHEN "PO" 
					CALL run_prog("R15",pa_reqsummary[idx].trans_num,"","","") 
					CALL po_head_info(glob_rec_kandoouser.cmpy_code, pa_reqsummary[idx].trans_num) 
					RETURNING pa_reqsummary[idx].total_amt, 
					pr_received_tot, 
					pr_voucher_tot, 
					pr_tax_tot 
					IF pa_reqsummary[idx].total_amt < pr_vendor.min_ord_amt THEN 
						LET pa_reqsummary[idx].status_ind = "*" 
					ELSE 
						SELECT status_ind INTO pa_reqsummary[idx].status_ind 
						FROM purchhead 
						WHERE order_num = pa_reqsummary[idx].trans_num 
						AND vend_code = pa_reqsummary[idx].vend_code 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					END IF 
				WHEN "SX" 
					CALL run_prog("I57",pa_reqsummary[idx].trans_num,"","","") 
				OTHERWISE 
			END CASE 
			NEXT FIELD scroll_flag 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	CLOSE WINDOW n134 
END FUNCTION 


FUNCTION print_transfers() 
	DEFINE l_rpt_idx SMALLINT  #report array index
	DEFINE	i SMALLINT, 
--	rpt_note LIKE rmsreps.report_text, 
	pr_product RECORD LIKE product.*, 
	ps_ibtdetl RECORD LIKE ibtdetl.*, 
	lv_ibtdetl RECORD 
		scroll_flag CHAR(1), 
		line_num LIKE ibtdetl.line_num, 
		part_code LIKE product.part_code, 
		desc_text LIKE product.desc_text, 
		trf_qty LIKE ibtdetl.trf_qty, 
		stock_uom_code LIKE product.stock_uom_code, 
		sell_tran_qty LIKE prodledg.tran_qty, 
		sell_uom_code LIKE product.stock_uom_code 
	END RECORD 
	DEFINE l_tmp_str STRING --pr_output CHAR(60) 

	LET pr_grandtot = 0 
	{
	   OPEN WINDOW w1 AT 10,14 with 3 rows, 50 columns     -- albo  KD-763
	      ATTRIBUTE(border, menu line 3)
	}
	DECLARE c_ibtdetls CURSOR FOR 
	SELECT * FROM ibthead, ibtdetl 
	WHERE ibthead.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ibtdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ibthead.trans_num between pr_first_trfnum AND pr_last_trfnum 
	AND ibtdetl.trans_num = ibthead.trans_num 

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start("I51","I51_rpt_list","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT I51_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------
	LET l_tmp_str =	" FROM: ",pr_first_trfnum USING "<<<<<<<<" ,	" To: ",pr_last_trfnum USING "<<<<<<<<" 
	CALL rpt_set_header_footer_line_2_append(l_rpt_idx,"", l_tmp_str)


	FOREACH c_ibtdetls INTO pr_ibthead.*, ps_ibtdetl.* 
		SELECT * INTO pr_product.* FROM product 
		WHERE part_code = ps_ibtdetl.part_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET lv_ibtdetl.line_num = ps_ibtdetl.line_num 
		LET lv_ibtdetl.part_code = ps_ibtdetl.part_code 
		LET lv_ibtdetl.desc_text = pr_product.desc_text 
		LET lv_ibtdetl.trf_qty = ps_ibtdetl.trf_qty	/ pr_product.stk_sel_con_qty 
		LET lv_ibtdetl.stock_uom_code = pr_product.stock_uom_code 
		LET lv_ibtdetl.sell_tran_qty = ps_ibtdetl.trf_qty 
		LET lv_ibtdetl.sell_uom_code = pr_product.sell_uom_code 
		DISPLAY " Processing: ",pr_ibthead.trans_num, " ",	ps_ibtdetl.line_num at 2,3

		#---------------------------------------------------------
		OUTPUT TO REPORT I51_rpt_list(l_rpt_idx,
		lv_ibtdetl.*, pr_ibthead.trans_num) 
		#---------------------------------------------------------
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT I51_rpt_list
	CALL rpt_finish("I51_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 

FUNCTION allocate_all(pr_stock_ind) 
	DEFINE 
	pr_reqdetl RECORD LIKE reqdetl.*, 
	pr_reqdetl2 RECORD LIKE reqdetl.*, 
	pr_stock_ind LIKE reqhead.stock_ind, 
	pr_vend_code LIKE vendor.vend_code, 
	pr_hold_code LIKE vendor.hold_code, 
	pr_scroll_flag CHAR(1), 
	pr_line_total LIKE reqhead.total_sales_amt, 
	pr_approve_qty LIKE reqdetl.po_qty, 
	pr_total_amount, 
	pr_total_sales_amt LIKE reqhead.total_sales_amt, 
	pr_temp_text CHAR(10), 
	pr_error_count, 
	idx SMALLINT, 
	err_continue CHAR(1) 

	OPEN WINDOW n136 with FORM "N136" 
	CALL windecoration_n("N136") -- albo kd-763 
	LET msgresp = kandoomsg("U",1512,"") 
	#1512 Press OK TO Continue OR CANCEL TO Exit.
	INPUT pr_vend_code 
	FROM vend_code 

		ON ACTION "WEB-HELP" -- albo kd-377 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) 
			LET pr_temp_text = show_vend(glob_rec_kandoouser.cmpy_code,pr_vend_code) 
			IF pr_temp_text IS NOT NULL 
			OR pr_temp_text != " " THEN 
				LET pr_vend_code = pr_temp_text 
				DISPLAY pr_vend_code 
				TO vend_code 

				NEXT FIELD vend_code 
			END IF 

		AFTER FIELD vend_code 
			IF pr_vend_code IS NULL 
			OR pr_vend_code = " " THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered.
				NEXT FIELD vend_code 
			END IF 
			SELECT hold_code INTO pr_hold_code FROM vendor 
			WHERE vend_code = pr_vend_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = notfound THEN 
				LET msgresp = kandoomsg("N",9043,"") 
				#9043 Vendor NOT found;  Try Window.
				NEXT FIELD vend_code 
			END IF 
			IF pr_hold_code = "ST" THEN 
				LET msgresp = kandoomsg("N",9046,"") 
				#9046 Vendor IS on hold.  Release before proceeding.
				NEXT FIELD vend_code 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	CLOSE WINDOW n136 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	LET pr_error_count = 0 
	LET msgresp = kandoomsg("U",1002,"") 
	FOR idx = 1 TO arr_count() 
		DECLARE c4_reqdetl CURSOR FOR 
		SELECT reqdetl.* FROM reqdetl 
		WHERE reqdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND reqdetl.req_num = pa_reqhead[idx].req_num 
		AND (reqdetl.req_qty > reqdetl.po_qty 
		OR (reqdetl.back_qty > 0 
		AND reqdetl.back_qty > reqdetl.po_qty)) 
		AND reqdetl.po_qty = 0 
		ORDER BY line_num 
		FOREACH c4_reqdetl INTO pr_reqdetl.* 
			IF pr_stock_ind != '0' THEN 
				IF pr_reqdetl.back_qty = 0 
				OR pr_reqdetl.po_qty > 0 THEN 
					CONTINUE FOREACH 
				END IF 
			END IF 
			SELECT approve_qty INTO pr_approve_qty FROM t_reqdetl 
			WHERE req_num = pr_reqdetl.req_num 
			AND line_num = pr_reqdetl.line_num 
			IF status = notfound THEN 
				IF pr_stock_ind = '0' THEN 
					LET pr_reqdetl.req_qty = pr_reqdetl.req_qty 
					- pr_reqdetl.po_qty 
				ELSE 
					LET pr_reqdetl.req_qty = pr_reqdetl.back_qty 
					- pr_reqdetl.po_qty 
				END IF 
			ELSE 
				LET pr_reqdetl.req_qty = pr_approve_qty 
			END IF 
			LET pr_line_total = pr_reqdetl.req_qty 
			* pr_reqdetl.unit_sales_amt 
			SELECT unique(1) FROM reqpurch 
			WHERE req_num = pr_reqdetl.req_num 
			AND line_num = pr_reqdetl.line_num 
			IF status = notfound THEN 
				LET pr_scroll_flag = NULL 
			ELSE 
				LET pr_scroll_flag = "*" 
			END IF 
			IF pr_scroll_flag IS NULL THEN 
				IF valid_vendor(pr_reqdetl.vend_code, 
				pr_reqdetl.line_num, 
				pr_reqdetl.replenish_ind, 
				true) THEN 
					IF pr_reqdetl.vend_code != pr_vend_code THEN 
						CONTINUE FOREACH 
					END IF 
					SELECT sum(approve_amt) INTO pr_total_amount FROM t_approve 
					IF pr_total_amount IS NULL THEN 
						LET pr_total_amount = 0 
					END IF 
					LET pr_total_amount = pr_total_amount 
					+ pr_line_total 
					IF pr_reqperson.po_up_limit_amt < pr_total_amount 
					AND glob_rec_reqparms.pend_purch_flag = "N" 
					AND pr_reqperson.po_up_limit_amt != 0 THEN 
						# Upper approval limit exceeded
						CONTINUE FOREACH 
					END IF 
					
					CALL update_approve(pr_reqdetl.replenish_ind, 
					pr_line_total,TRAN_TYPE_INVOICE_IN) 
					
					INSERT INTO reqpurch VALUES (pr_reqdetl.vend_code, 
					pa_reqhead[idx].ware_code, 
					pr_reqdetl.part_code, 
					pr_reqdetl.req_num, 
					pr_reqdetl.line_num, 
					pr_reqdetl.replenish_ind, 
					pr_reqdetl.unit_sales_amt, 
					pr_reqdetl.req_qty, 
					pr_reqdetl.desc_text) 
					LET pa_reqhead[idx].scroll_flag = "*" 
				ELSE 
					# Only want TO REPORT errors FOR Supply Type = "P"
					IF pr_reqdetl.replenish_ind = "P" THEN 
						LET pr_error_count = pr_error_count + 1 
					END IF 
				END IF 
			END IF 
		END FOREACH 
	END FOR 
	IF pr_error_count > 0 THEN 
		LET msgresp = kandoomsg("N",9514,pr_error_count) 
		# pr_error_count lines exist without vendor codes.
	END IF 
	RETURN true 
END FUNCTION 
