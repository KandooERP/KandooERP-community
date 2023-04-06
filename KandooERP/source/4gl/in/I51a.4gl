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
##- the ibthead and ibtdetl 'status_ind' determine the status of the transfert. 
##- Values are:
##- ibthead
##- R => Transfer cancelled
##- C => completed
##- P => partially completed
##- U => Undelivered
##- ibtdetl: not clear yet ....
##- 0 => New
##- 4 => Cancelled

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../in/I_IN_GLOBALS.4gl" 
--GLOBALS "I51_GLOBALS.4gl" 

# I51a.4gl - Stock Transfers
# Module scope variables
	DEFINE 
	mr_inparms RECORD LIKE inparms.*, 
	mr_ibthead RECORD LIKE ibthead.*,
	mr_ibtdetl RECORD LIKE ibtdetl.*,
	mr_prodledg RECORD LIKE prodledg.*, 
	--pr_customer RECORD LIKE customer.*, 
	--pr_stk_sel_con_qty LIKE product.stk_sel_con_qty, 
	--pr_req_num LIKE reqhead.req_num, 
	m_sched_ind_sto LIKE ibthead.sched_ind, 
	m_mode CHAR(10), 
	m_sched_ind CHAR(1), 
	rpt_pageno LIKE rmsreps.page_num, 
	--query_text CHAR(500), 
	ma_ibtdetl_array DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		line_num LIKE ibtdetl.line_num, 
		part_code LIKE product.part_code, 
		desc_text LIKE product.desc_text, 
		trf_qty LIKE ibtdetl.trf_qty, 
		stock_uom_code LIKE product.stock_uom_code, 
		sell_tran_qty LIKE prodledg.tran_qty, 
		sell_uom_code LIKE product.stock_uom_code 
	END RECORD, 
	ma_ibtdetl_remainder DYNAMIC ARRAY OF RECORD
		picked_qty LIKE ibtdetl.picked_qty,
		sched_qty LIKE ibtdetl.sched_qty,
		conf_qty LIKE ibtdetl.conf_qty,
		rec_qty LIKE ibtdetl.rec_qty,
		back_qty LIKE ibtdetl.back_qty,
		amend_code LIKE ibtdetl.amend_code,
		amend_date LIKE ibtdetl.amend_date,
		status_ind LIKE ibtdetl.status_ind,
		req_num LIKE ibtdetl.req_num,
		req_line_num LIKE ibtdetl.req_line_num
	END RECORD
	DEFINE ma_ibtdetl_addl_data DYNAMIC ARRAY OF RECORD
		serial_flag LIKE product.serial_flag,
		stk_sel_con_qty LIKE product.stk_sel_con_qty
	END RECORD
	DEFINE ma_action_array DYNAMIC ARRAY OF RECORD
		# This array tracks the action to for each element:   I => insert, U => Update, D => Delete, NULL => do nothing			
		todo CHAR(1)
	END RECORD,
	ma_prledger DYNAMIC ARRAY OF RECORD LIKE prodledg.*, 
	ma_prodledg DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		part_code LIKE product.part_code, 
		desc_text LIKE product.desc_text, 
		stock_tran_qty LIKE prodledg.tran_qty, 
		stock_uom_code LIKE product.stock_uom_code, 
		sell_tran_qty LIKE prodledg.tran_qty, 
		sell_uom_code LIKE product.stock_uom_code 
	END RECORD, 
	mr_printcodes RECORD LIKE printcodes.*,
	m_arr_cnt SMALLINT
	--pr_temp_text CHAR(200), 
	--



--DEFINE crs_ibtdetl_1_trans CURSOR
DEFINE crs_all_t_ibtdetl CURSOR
DEFINE crs_suburb_city CURSOR
DEFINE c1_ibtdetl CURSOR
DEFINE c_ibtdetl_ser2 CURSOR

# this function prepares and declares cursors ONCE, for using many times
FUNCTION declare_cursors_and_prepare_detail()
	DEFINE query_stmt STRING
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	LET query_stmt = "SELECT d.line_num,d.part_code,p.desc_text,d.trf_qty,p.stock_uom_code,d.trf_qty,p.sell_uom_code,",
	"d.picked_qty,d.sched_qty,d.conf_qty,d.rec_qty,d.back_qty,d.amend_code,d.amend_date,d.status_ind,d.req_num,d.req_line_num,",
	"p.serial_flag,p.stk_sel_con_qty ",
	"FROM ibtdetl d,product p ",
	"WHERE d.part_code = p.part_code ",
	"AND p.cmpy_code = ? ",
	"AND d.trans_num = ? ",
	" ORDER BY d.line_num "	
	
	# Choose declare method between the following 2 lines cursorname.declare or PREPARE/DECLARE on next lines
	# then adapt the code in the product_lines_entry(trans_num) function accordingly ( i.e use the same method )
	--CALL crs_ibtdetl_1_trans.declare(query_stmt)					# version with cursor method that causes problems
	--LET query_stmt = crs_ibtdetl_1_trans.GetStatement()				# version with cursor method that causes problems
	
	PREPARE p_ibtdetl FROM query_stmt								# version with traditional cursor
	DECLARE crs_ibtdetl_1_trans CURSOR FOR p_ibtdetl				# version with traditional cursor
	
	LET query_stmt = "SELECT * FROM ibtdetl WHERE cmpy_code = ? AND trans_num = ? AND part_code IS NOT NULL"
	CALL c1_ibtdetl.declare(query_stmt)
	LET query_stmt = c1_ibtdetl.GetStatement()
 
 	# this cursor has a problem when declared as variable
	--LET query_stmt = "SELECT * FROM t_ibtdetl WHERE part_code IS NOT NULL ORDER BY line_num"
	--CALL crs_all_t_ibtdetl.declare(query_stmt)
	--LET query_stmt = crs_all_t_ibtdetl.GetStatement()
	DECLARE crs_all_t_ibtdetl CURSOR FOR 
	SELECT * FROM t_ibtdetl 
	WHERE part_code IS NOT NULL 
	ORDER BY line_num
	
	LET query_stmt = "SELECT part_code FROM t_ibtdetl WHERE status_ind = ?" 
	CALL c_ibtdetl_ser2.DECLARE (query_stmt) 
	LET query_stmt = c_ibtdetl_ser2.GetStatement()
	
	
	LET query_stmt = "SELECT * FROM suburb WHERE suburb_text = ? AND state_code = ? AND cmpy_code = ?"
	CALL crs_suburb_city.declare(query_stmt)
	LET query_stmt = crs_suburb_city.GetStatement()
	
END FUNCTION

FUNCTION stock_transfer_header_entry(lr_mode,lr_ibthead) 
	DEFINE 
	lr_mode CHAR(10),
	ls_ibthead RECORD LIKE ibthead.*, 			# clone of ls_ibthead, serves as backup record
	lr_ibthead RECORD LIKE ibthead.*, 			# full ibthead received as inbound parameter
	lr_inparms RECORD LIKE inparms.*, 
	ls_warehouse RECORD LIKE warehouse.*, 
	pa_desc_text array[2] OF LIKE warehouse.desc_text, 		# array of the 2 warehouses source and destination
	invalid_period,arr_cnt INTEGER, 
	pr_temp_text CHAR(200), 
	pr_module_text LIKE company.module_text, 
	pr_cnt SMALLINT 
	DEFINE l_cmpy_code LIKE ibthead.cmpy_code
	DEFINE l_trans_num LIKE ibthead.trans_num

	IF m_mode <> "EDIT" THEN
		INITIALIZE lr_ibthead.* TO NULL
		LET m_sched_ind = NULL
	ELSE
		DISPLAY BY NAME lr_ibthead.trans_num
		# get "from" warehouse description
		SELECT desc_text INTO pa_desc_text[1] 
		FROM warehouse 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND ware_code = lr_ibthead.from_ware_code 
		DISPLAY pa_desc_text[1] TO sr_desc_text[1].ware_text
		
		# get "to" warehouse description
		SELECT desc_text INTO pa_desc_text[2] FROM warehouse 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND ware_code = lr_ibthead.to_ware_code 
		DISPLAY pa_desc_text[2] TO sr_desc_text[2].ware_text
	END IF
	LET lr_ibthead.* = lr_ibthead.*
	LET m_mode = lr_mode
	
	SELECT * INTO lr_inparms.* 
	FROM inparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET m_sched_ind_sto = NULL 
 
	--IF lr_ibthead.from_ware_code IS NULL THEN 
	IF lr_ibthead.from_ware_code IS NULL THEN
		CLEAR FORM 
		LET arr_cnt = 0 
		LET lr_ibthead.trans_date = today 
		
		CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,lr_ibthead.trans_date) 
		RETURNING lr_ibthead.year_num, 
		lr_ibthead.period_num 
		LET lr_ibthead.from_ware_code = lr_inparms.mast_ware_code 
		
		SELECT module_text INTO pr_module_text 
		FROM company 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF pr_module_text[23] != "W" THEN 
			LET lr_ibthead.sched_ind = "1" 
		ELSE 
			LET lr_ibthead.sched_ind = "2" 
		END IF 
	ELSE 
		LET ls_ibthead.* = lr_ibthead.* 
	END IF 
	IF m_sched_ind IS NOT NULL THEN 
		LET lr_ibthead.sched_ind = m_sched_ind 
	END IF 
	LET msgresp = kandoomsg("I",1302,"") 

	# I1302 Enter transfer details - Accept TO Continue
	INPUT BY NAME lr_ibthead.from_ware_code, 
		lr_ibthead.to_ware_code, 
		lr_ibthead.trans_date, 
		lr_ibthead.year_num, 
		lr_ibthead.period_num, 
		lr_ibthead.sched_ind, 
		lr_ibthead.desc_text WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","I51a","input-lr_ibthead-1") -- albo kd-505
			IF m_mode = "EDIT" THEN
				# in EDIT mode, the following field cannot be input (replaces before field / next field)
				CALL DIALOG.SetFieldActive("from_ware_code,to_ware_code,sched_ind", false)
			ELSE
				CALL DIALOG.SetFieldActive("from_ware_code,to_ware_code,sched_ind", true)
			END IF

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 
			
		ON KEY ("HELP") 
			CALL kandoohelp("")

		ON ACTION "LOOKUP"  infield(from_ware_code) 
					LET lr_ibthead.from_ware_code = show_ware(glob_rec_kandoouser.cmpy_code) 
					NEXT FIELD from_ware_code 
		ON ACTION "LOOKUP"  infield(to_ware_code) 
					LET lr_ibthead.to_ware_code = show_ware(glob_rec_kandoouser.cmpy_code) 
					NEXT FIELD to_ware_code 
		 
		ON ACTION "NOTES" infield(desc_text)
			LET lr_ibthead.desc_text = sys_noter(glob_rec_kandoouser.cmpy_code, lr_ibthead.desc_text) 
			NEXT FIELD desc_text 
		
		BEFORE FIELD from_ware_code 
			LET pr_temp_text = lr_ibthead.from_ware_code 
			
		AFTER FIELD from_ware_code 
			IF lr_ibthead.from_ware_code IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD from_ware_code 
			ELSE 
				SELECT desc_text INTO pa_desc_text[1] 
				FROM warehouse 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = lr_ibthead.from_ware_code 
				IF sqlca.sqlcode = notfound THEN 
					LET msgresp = kandoomsg("U",9105,"") 
					#9105 RECORD IS NOT found, try window
					NEXT FIELD from_ware_code 
				ELSE 
					SELECT count(*) INTO pr_cnt 
					FROM t_ibtdetl 
					IF ls_ibthead.from_ware_code IS NOT NULL 
					AND ls_ibthead.from_ware_code != lr_ibthead.from_ware_code 
					AND pr_cnt > 0 THEN 
						LET msgresp = kandoomsg("I",8027,"") 
						#I8027 Delete Line Items (Y/N)?
						IF msgresp = "Y" THEN 
							LET arr_cnt = 0 
							CLEAR sr_ibtdetl[1].* 
							CLEAR sr_ibtdetl[2].* 
							CLEAR sr_ibtdetl[3].* 
							CLEAR sr_ibtdetl[4].* 
							CLEAR sr_ibtdetl[5].* 
							CLEAR sr_ibtdetl[6].* 
							CLEAR sr_status[1].* 
							CLEAR sr_status[2].* 
							DELETE FROM t_ibtdetl 
						ELSE 
							LET lr_ibthead.from_ware_code = ls_ibthead.from_ware_code 
							NEXT FIELD from_ware_code 
						END IF 
					END IF 
					DISPLAY pa_desc_text[1] TO sr_desc_text[1].ware_text 

				END IF 
			END IF 

		BEFORE FIELD to_ware_code 
			IF m_mode = "EDIT" THEN 
				NEXT FIELD trans_date 
			END IF 

		AFTER FIELD to_ware_code 
			IF lr_ibthead.to_ware_code IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD to_ware_code 
			ELSE 
				SELECT * INTO ls_warehouse.* 
				FROM warehouse 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND ware_code = lr_ibthead.to_ware_code 
				IF sqlca.sqlcode = notfound THEN 
					LET msgresp = kandoomsg("U",9105,"") 
					#9105 RECORD IS NOT found, try window
					NEXT FIELD to_ware_code 
				ELSE 
					LET pa_desc_text[2] = ls_warehouse.desc_text 
					DISPLAY pa_desc_text[2] TO sr_desc_text[2].ware_text 

				END IF 
			END IF 

		BEFORE FIELD trans_date 
			IF lr_ibthead.trans_date IS NULL THEN 
				LET lr_ibthead.trans_date = today 
			END IF 
			LET ls_ibthead.trans_date = lr_ibthead.trans_date 

		AFTER FIELD trans_date 
			IF lr_ibthead.trans_date IS NULL THEN 
				LET lr_ibthead.trans_date = today 
			END IF 
			IF lr_ibthead.trans_date != ls_ibthead.trans_date THEN 
				CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,lr_ibthead.trans_date) 
				RETURNING lr_ibthead.year_num,lr_ibthead.period_num 
				DISPLAY BY NAME lr_ibthead.period_num,lr_ibthead.year_num 
			END IF 

		AFTER FIELD period_num 
			CALL valid_period(glob_rec_kandoouser.cmpy_code,lr_ibthead.year_num,lr_ibthead.period_num,TRAN_TYPE_INVOICE_IN) 
			RETURNING lr_ibthead.year_num, 
				lr_ibthead.period_num, 
				invalid_period 
			IF invalid_period THEN 
				NEXT FIELD year_num 
			END IF 

		AFTER FIELD sched_ind 
			IF lr_ibthead.sched_ind IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered.
				NEXT FIELD sched_ind 
			END IF 
			SELECT module_text INTO pr_module_text 
			FROM company 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF pr_module_text[23] != "W" THEN 
				IF lr_ibthead.sched_ind = "2" THEN 
					LET msgresp = kandoomsg("I",9004,"") 
					#9004 Scheduling NOT available.
					NEXT FIELD sched_ind 
				END IF 
			END IF 
			
		AFTER FIELD desc_text
			MESSAGE "Header input completed, please click on ACCEPT"
			
		AFTER INPUT 
			IF NOT int_flag THEN 
				IF lr_ibthead.to_ware_code IS NULL THEN 
					LET msgresp = kandoomsg("U",9105,"") 
					#I9029 warehouse IS NOT found, try window
					NEXT FIELD to_ware_code 
				END IF 
				IF lr_ibthead.from_ware_code = lr_ibthead.to_ware_code THEN 
					LET msgresp = kandoomsg("I",9111,"") 
					#I9111 source & dest warehouse cannot be the same
					NEXT FIELD to_ware_code 
				END IF 
				CALL valid_period(glob_rec_kandoouser.cmpy_code,lr_ibthead.year_num,lr_ibthead.period_num,TRAN_TYPE_INVOICE_IN) 
				RETURNING lr_ibthead.year_num, 
					lr_ibthead.period_num, 
					invalid_period 
				IF invalid_period THEN 
					NEXT FIELD year_num 
				END IF 
				IF lr_ibthead.sched_ind IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered.
					NEXT FIELD sched_ind 
				END IF
				LET mr_ibthead.* = lr_ibthead.* 
			END IF 
	END INPUT 
	
	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION      # stock_transfer_header_entry
	 
FUNCTION product_lines_entry(l_input_mode,l_trans_num) 
	DEFINE 
	exit_flag SMALLINT, 
	lr_lastkey INTEGER, 
	lr_product RECORD LIKE product.*, 
	lr_prodstatus RECORD LIKE prodstatus.*, 
	ls_prodstatus RECORD LIKE prodstatus.*, 		# clone of lr_prodstatus, serves as record backup in case of cancel
	ls_ibtdetl RECORD LIKE ibtdetl.*, 				# 
	ln_ibtdetl RECORD LIKE ibtdetl.*, 
	lf_ibtdetl RECORD LIKE ibtdetl.*, 
	ls_array RECORD									# clone of the current array element 
		scroll_flag CHAR(1), 
		line_num LIKE ibtdetl.line_num, 
		part_code LIKE product.part_code, 
		desc_text LIKE product.desc_text, 
		trf_qty LIKE ibtdetl.trf_qty, 
		stock_uom_code LIKE product.stock_uom_code, 
		sell_tran_qty LIKE prodledg.tran_qty, 
		sell_uom_code LIKE product.stock_uom_code 
	END RECORD,
	l_prodstatus_avail_qty LIKE prodstatus.onhand_qty, 
	l_dest_mask_code LIKE warehouse.acct_mask_code,
	l_prodledg_acct_code LIKE prodledg.acct_code,
	la_prodstatus array[2] OF RECORD 
		onhand_qty LIKE prodstatus.onhand_qty, 
		reserved_qty LIKE prodstatus.reserved_qty, 
		back_qty LIKE prodstatus.back_qty, 
		avail_qty LIKE prodstatus.onhand_qty 
	END RECORD, 
	l_ibtdetl RECORD 
		scroll_flag CHAR(1), 
		line_num LIKE ibtdetl.line_num, 
		part_code LIKE product.part_code, 
		desc_text LIKE product.desc_text, 
		trf_qty LIKE ibtdetl.trf_qty, 
		stock_uom_code LIKE product.stock_uom_code, 
		sell_tran_qty LIKE prodledg.tran_qty, 
		sell_uom_code LIKE product.stock_uom_code 
	END RECORD,
	l_part_code LIKE ibtdetl.part_code, 
	l_delivered_qty FLOAT, 
	l_act_qty FLOAT, 
	l_new_line,pr_curr,l_cnt,elem_num,screen_line INTEGER, 
	l_scroll_flag CHAR(1), 
	query_stmt STRING, 
	l_temp_text STRING,
	l_winds_text STRING, -- CHAR(100),
	l_trans_num LIKE ibthead.trans_num, 
	l_prod_serial_cnt SMALLINT, 
	j,i SMALLINT 
	DEFINE l_input_mode CHAR(5)

	CALL ma_ibtdetl_array.clear()
	CALL ma_prledger.clear()
	CALL ma_prodledg.clear()
 
	LET msgresp = kandoomsg("U",1003,"") 
	# I1004 F1 - Add  F2 - Delete  ESC TO Continue
--	OPTIONS INSERT KEY f1, 
--	DELETE KEY f36 

	--IF crs_ibtdetl_1_trans.GetStatement() IS NULL THEN
		# check if this cursor has already been declared, if not, it is declared ONCE in the whole program
		# check the declare_cursors_and_prepare_detail to set the right cursor declare method
		CALL declare_cursors_and_prepare_detail()
	--END IF
	
	--CALL crs_ibtdetl_1_trans.SetParameters(glob_rec_kandoouser.cmpy_code,l_trans_num)	# version with cursor method that causes problems
	--CALL crs_ibtdetl_1_trans.open()							# version with cursor method that causes problems

	IF l_input_mode = "EDIT" THEN
		OPEN crs_ibtdetl_1_trans USING glob_rec_kandoouser.cmpy_code,l_trans_num   # version with traditional cursor
		 
		LET elem_num = 1
		# Scan the existing transfer lines
-- 	LET query_stmt = "SELECT d.line_num,d.part_code,p.desc_text,d.trf_qty,p.stock_uom_code,d.trf_qty,",
--	"d.picked_qty,d.sched_qty,d.conf_qty,d.rec_qty,d.back_qty,d.amend_code,d.amend_date,d.status_ind,d.req_num,d.req_line_num,",
--	"p.serial_flag,p.stk_sel_con_qty ",

		FOREACH crs_ibtdetl_1_trans INTO 
				ma_ibtdetl_array[elem_num].line_num, 	# version with traditional cursor
				ma_ibtdetl_array[elem_num].part_code,								# version with traditional cursor
				ma_ibtdetl_array[elem_num].desc_text,								# version with traditional cursor
				ma_ibtdetl_array[elem_num].trf_qty,								# version with traditional cursor
				ma_ibtdetl_array[elem_num].stock_uom_code,						# version with traditional cursor
				ma_ibtdetl_array[elem_num].sell_tran_qty,							# version with traditional cursor
				ma_ibtdetl_array[elem_num].sell_uom_code,							# version with traditional cursor
				ma_ibtdetl_remainder[elem_num].picked_qty,
				ma_ibtdetl_remainder[elem_num].sched_qty,
				ma_ibtdetl_remainder[elem_num].conf_qty,
				ma_ibtdetl_remainder[elem_num].rec_qty,
				ma_ibtdetl_remainder[elem_num].back_qty,
				ma_ibtdetl_remainder[elem_num].amend_code,
				ma_ibtdetl_remainder[elem_num].amend_date,
				ma_ibtdetl_remainder[elem_num].status_ind,
				ma_ibtdetl_remainder[elem_num].req_num,
				ma_ibtdetl_remainder[elem_num].req_line_num,
				--mr_ibtdetl.status_ind,									# version with traditional cursor
				ma_ibtdetl_addl_data[elem_num].serial_flag,										# version with traditional cursor
				ma_ibtdetl_addl_data[elem_num].stk_sel_con_qty								# version with traditional cursor

	 
		--WHILE  crs_ibtdetl_1_trans.fetchNext() = 0							# version with cursor method that causes problems
																			# The problem I have is that apparently crs_ibtdetl_1_trans.SetParameters and then
																			# crs_ibtdetl_1_trans.open retrieve 1 row as expected, 
																			# but SetResults does not assign values to the ma_ibtdetl array
			
			--CALL crs_ibtdetl_1_trans.SetResults(							# version with cursor method that causes problems
			--ma_ibtdetl_array[elem_num].line_num,									# version with cursor method that causes problems
			--ma_ibtdetl_array[elem_num].part_code,									# version with cursor method that causes problems
			--ma_ibtdetl_array[elem_num].desc_text,									# version with cursor method that causes problems
			--ma_ibtdetl_array[elem_num].trf_qty,									# version with cursor method that causes problems
			--ma_ibtdetl_array[elem_num].stock_uom_code,							# version with cursor method that causes problems
			--ma_ibtdetl_array[elem_num].sell_tran_qty,								# version with cursor method that causes problems
			--ma_ibtdetl_array[elem_num].sell_uom_code,								# version with cursor method that causes problems
			--mr_ibtdetl.status_ind,											# version with cursor method that causes problems
			--lr_product.serial_flag,											# version with cursor method that causes problems
			--lr_product.stk_sel_con_qty										# version with cursor method that causes problems
			--)  																# version with cursor method that causes problems
			 
			IF ma_ibtdetl_addl_data[elem_num].serial_flag = 'Y' 
			AND m_sched_ind_sto <> mr_ibthead.sched_ind THEN 
				LET ma_ibtdetl_array[elem_num].trf_qty = 0 
				LET ma_ibtdetl_array[elem_num].sell_tran_qty = 0 
			ELSE 
				-- ericv 20200722 LET ma_ibtdetl_array[elem_num].trf_qty = mr_ibtdetl.trf_qty 
				-- ericv 20200722 LET ma_ibtdetl_array[elem_num].sell_tran_qty = mr_ibtdetl.trf_qty * lr_product.stk_sel_con_qty 
			END IF 
			-- ericv 20200722 LET ma_ibtdetl_array[elem_num].sell_uom_code = lr_product.sell_uom_code 
			IF ma_ibtdetl_remainder[elem_num].status_ind = "4" THEN 
				LET ma_ibtdetl_array[elem_num].scroll_flag = "*" 
			END IF 
			LET ma_action_array[elem_num].todo = "N"			# element exists but do Nothing (yet)
			LET elem_num = elem_num + 1
		--END WHILE 															# version with cursor method that causes problems
		END FOREACH
		# elem_num is 1 behind last element, delete last empty element	
		CALL ma_ibtdetl_array.Delete(elem_num)
		LET elem_num = elem_num -1													# version with traditional cursor
	END IF 
	
	LET msgresp = kandoomsg("U",9113,elem_num) 
	#9113 elem_num records selected
		CALL set_count(elem_num) 
	IF m_sched_ind_sto <> mr_ibthead.sched_ind 
	OR m_sched_ind_sto IS NULL THEN 
		LET m_sched_ind_sto = mr_ibthead.sched_ind 
		CASE mr_ibthead.sched_ind 
			WHEN '0' 
				CALL serial_init(glob_rec_kandoouser.cmpy_code, "", "0", mr_ibthead.trans_num) 
			WHEN '1' 
				CALL serial_init(glob_rec_kandoouser.cmpy_code, "T", "0", mr_ibthead.trans_num) 
		END CASE 
	END IF 
	LET int_flag = false 
	LET quit_flag = false 
	LET exit_flag = false 

	INPUT ARRAY ma_ibtdetl_array WITHOUT DEFAULTS FROM sr_ibtdetl.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","I51a","input-arr_ma_ibtdetl-1") -- albo kd-505 
			CALL DIALOG.SetFieldActive("scroll_flag", false)

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "LOOKUP" infield(part_code)
			LET l_temp_text = "part_code in ", 
			"(SELECT part_code FROM prodstatus ", 
			"WHERE cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
			"AND ware_code='",mr_ibthead.from_ware_code,"')" 
			LET l_winds_text = show_part(glob_rec_kandoouser.cmpy_code,l_temp_text) 
			IF l_winds_text IS NOT NULL THEN 
				LET ma_ibtdetl_array[elem_num].part_code = l_winds_text 
			END IF 
			--DELETE KEY f36 
			NEXT FIELD part_code 
			--END IF 

		ON ACTION "DELETE" 
			IF elem_num <> 0 THEN
			IF ma_ibtdetl_array[elem_num].part_code IS NOT NULL 
			AND l_input_mode = "EDIT" THEN #cancel line 
				IF infield(scroll_flag) THEN 
					IF ma_ibtdetl_array[elem_num].scroll_flag IS NOT NULL THEN 
						SELECT * FROM ibtdetl 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND trans_num = mr_ibthead.trans_num 
						AND line_num = ma_ibtdetl_array[elem_num].line_num 
						AND status_ind = '4' 
						IF sqlca.sqlcode = 0 THEN 
							LET msgresp = kandoomsg("W",9465,"") 
							##9465 Transfer line has already been cancelled"
							NEXT FIELD scroll_flag 
						ELSE 
							SELECT * INTO ln_ibtdetl.* 
							FROM ibtdetl 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND trans_num = mr_ibthead.trans_num 
							AND line_num = ma_ibtdetl_array[elem_num].line_num 
							IF sqlca.sqlcode = notfound THEN 
								LET l_delivered_qty = 0 
							ELSE 
								LET l_delivered_qty = ln_ibtdetl.sched_qty 
								+ ln_ibtdetl.picked_qty 
								+ ln_ibtdetl.conf_qty 
								+ ln_ibtdetl.rec_qty 
							END IF 
							UPDATE t_ibtdetl 
							SET amend_date = today, 
							amend_code = glob_rec_kandoouser.sign_on_code, 
							status_ind = "0", 
							back_qty = ma_ibtdetl_array[elem_num].trf_qty 
							- l_delivered_qty 
							WHERE line_num = ma_ibtdetl_array[elem_num].line_num 
							LET ma_ibtdetl_array[elem_num].scroll_flag = NULL 
							NEXT FIELD scroll_flag 
						END IF 
					END IF 
					
					### ericv check this sequence  too ....
					SELECT * INTO mr_ibtdetl.* 
					FROM t_ibtdetl 
					WHERE line_num = ma_ibtdetl_array[elem_num].line_num 
					IF sqlca.sqlcode = notfound THEN 
						LET msgresp = kandoomsg("W",9466,"") 
						#9466 Logic error: Transfer Line does NOT exist"
						NEXT FIELD scroll_flag 
					END IF 
					IF mr_ibtdetl.sched_qty > 0 THEN 
						LET msgresp = kandoomsg("W",9467,"") 
						#9467 Loads exists FOR this transfer Line - Cannot Cancel"
						NEXT FIELD scroll_flag 
					END IF 
					IF mr_ibtdetl.picked_qty > 0 THEN 
						LET msgresp = kandoomsg("W",9468,"") 
						#9468 Docket printed FOR this Transfer Line - Cannot Cancel"
						NEXT FIELD scroll_flag 
					END IF 
					IF mr_ibtdetl.conf_qty > 0 THEN 
						LET msgresp = kandoomsg("I",8050,"") 
						#8050 This Product has confirmed lines against it
						IF msgresp = 'N' THEN 
							NEXT FIELD scroll_flag 
						END IF 
					END IF 
					{
					-- ericv 20200722 
					UPDATE t_ibtdetl 
					SET amend_date = today, 
					amend_code = glob_rec_kandoouser.sign_on_code, 
					status_ind = "4", 
					back_qty = 0 
					WHERE line_num = ma_ibtdetl_array[elem_num].line_num 
					LET ma_ibtdetl_array[elem_num].scroll_flag = "*" 
					NEXT FIELD scroll_flag
					} 
				END IF 
			END IF 
			
			IF l_input_mode = "ADD" THEN #delete line 
				IF ma_ibtdetl_array[elem_num].part_code IS NOT NULL 
				AND mr_ibthead.from_ware_code IS NOT NULL THEN 
					CALL serial_delete(ma_ibtdetl_array[elem_num].part_code, 
					mr_ibthead.from_ware_code) 
				END IF 
				{
				-- ericv 20200722 
				DELETE FROM t_ibtdetl 
				WHERE line_num = ma_ibtdetl_array[elem_num].line_num
				} 
				LET pr_curr = arr_curr() 
				LET l_cnt = arr_count() 
				FOR elem_num = pr_curr TO l_cnt 
					LET ma_ibtdetl_array[elem_num].* = ma_ibtdetl_array[elem_num+1].* 
					IF screen_line <= 6 THEN 
						IF ma_ibtdetl_array[elem_num].part_code IS NULL THEN 
							LET ma_ibtdetl_array[elem_num].line_num = NULL 
							LET ma_ibtdetl_array[elem_num].part_code = NULL 
							LET ma_ibtdetl_array[elem_num].desc_text = NULL 
							LET ma_ibtdetl_array[elem_num].trf_qty = NULL 
							LET ma_ibtdetl_array[elem_num].sell_tran_qty = NULL 
							LET ma_ibtdetl_array[elem_num].stock_uom_code = NULL 
							LET ma_ibtdetl_array[elem_num].sell_uom_code = NULL 
						END IF 
						DISPLAY ma_ibtdetl_array[elem_num].* TO sr_ibtdetl[screen_line].* 

						LET screen_line = screen_line + 1 
					END IF 
				END FOR 
				INITIALIZE ma_ibtdetl_array[elem_num].* TO NULL 
				NEXT FIELD scroll_flag 
			END IF 
			END IF
{
		BEFORE FIELD part_code 
			LET l_part_code = ma_ibtdetl_array[elem_num].part_code 
			IF l_input_mode = "EDIT" THEN 
				LET l_prodstatus_avail_qty = stock_status(ma_ibtdetl_array[elem_num].part_code)
				{ next comments block apparently not useful 
				SELECT * INTO ln_ibtdetl.* 
				FROM ibtdetl 
				WHERE line_num = ma_ibtdetl_array[elem_num].line_num 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND trans_num = mr_ibthead.trans_num 
				IF status != notfound THEN 
					IF ln_ibtdetl.back_qty != ln_ibtdetl.trf_qty THEN 
						NEXT FIELD trf_qty 
					END IF 
				END IF 

			END IF
} 

		BEFORE ROW 
			LET elem_num = arr_curr() 
			LET screen_line = scr_line() 
			# Save the line in clone record
			IF elem_num <> 0 THEN
			LET ls_array.* = ma_ibtdetl_array[elem_num].*
			--LET l_prodstatus_avail_qty = BOARD001stock_status(ma_ibtdetl_array[elem_num].part_code) 
--			IF fgl_lastkey() <> fgl_keyval("accept") AND fgl_lastkey() <> fgl_keyval("cancel") THEN
--				NEXT FIELD scroll_flag
--			END IF 
			CASE
				WHEN l_input_mode = "ADD"
					{ this block moved to before insert
					CALL insert_t_ibtdetl_line() 
					LET lf_ibtdetl.* = mr_ibtdetl.* 
					INITIALIZE ls_ibtdetl.* TO NULL 
					INITIALIZE lr_product.* TO NULL 
					INITIALIZE la_prodstatus[1].* TO NULL 
					INITIALIZE la_prodstatus[2].* TO NULL 
					LET ma_ibtdetl_array[elem_num].line_num = mr_ibtdetl.line_num 
					LET ma_ibtdetl_array[elem_num].part_code = mr_ibtdetl.part_code 
					LET ma_ibtdetl_array[elem_num].desc_text = lr_product.desc_text 
					LET ma_ibtdetl_array[elem_num].trf_qty = mr_ibtdetl.trf_qty 
					LET ma_ibtdetl_array[elem_num].stock_uom_code = lr_product.stock_uom_code 
					LET ma_ibtdetl_array[elem_num].sell_tran_qty = mr_ibtdetl.trf_qty * lr_product.stk_sel_con_qty 
					LET ma_ibtdetl_array[elem_num].sell_uom_code = lr_product.sell_uom_code 
					DISPLAY ma_ibtdetl_array[elem_num].* TO sr_ibtdetl[screen_line].* 
					DISPLAY la_prodstatus[1].* TO sr_status[1].* 
					DISPLAY la_prodstatus[2].* TO sr_status[2].* 
					--ELSE 
						--LET ls_ibtdetl.* = lf_ibtdetl.* 
					--END IF 
--			IF lr_lastkey = fgl_keyval("left") 
--			OR lr_lastkey = fgl_keyval("up") THEN 
--				NEXT FIELD scroll_flag 
--			ELSE 
						--NEXT FIELD part_code 
					--END IF 
					}
					WHEN l_input_mode = "EDIT" 
					{
					-- ericv 20200722 SELECT * INTO lf_ibtdetl.* 
					FROM t_ibtdetl 
					WHERE line_num = ma_ibtdetl_array[elem_num].line_num 
					IF status = 0 THEN 
						SELECT * INTO lr_product.* 
						FROM product 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND part_code = lf_ibtdetl.part_code 
						LET mr_ibtdetl.* = lf_ibtdetl.* 
						LET ma_ibtdetl_array[elem_num].line_num = mr_ibtdetl.line_num 
						LET ma_ibtdetl_array[elem_num].part_code = mr_ibtdetl.part_code 
						LET ma_ibtdetl_array[elem_num].desc_text = lr_product.desc_text 
						LET ma_ibtdetl_array[elem_num].trf_qty = mr_ibtdetl.trf_qty 
						LET ma_ibtdetl_array[elem_num].stock_uom_code = lr_product.stock_uom_code 
						IF ma_ibtdetl_array[elem_num].sell_tran_qty IS NULL THEN 
							LET ma_ibtdetl_array[elem_num].sell_tran_qty = mr_ibtdetl.trf_qty	* lr_product.stk_sel_con_qty 
						END IF 
						LET ma_ibtdetl_array[elem_num].sell_uom_code = lr_product.sell_uom_code 
						DISPLAY ma_ibtdetl_array[elem_num].* TO sr_ibtdetl[screen_line].* 
						LET ls_ibtdetl.* = lf_ibtdetl.*
					END IF
					}
			END CASE
			END IF

		BEFORE INSERT
			IF elem_num <> 0 THEN
			# when we create a new transfer line 
			LET elem_num = arr_curr() 
			LET screen_line = scr_line()
			INITIALIZE ma_ibtdetl_array[elem_num].* TO NULL
			LET ma_ibtdetl_array[elem_num].line_num = elem_num
			-- LET ma_action_array[elem_num].todo = "I" 
			INITIALIZE lf_ibtdetl.* TO NULL 
			-- ericv 20200722 CALL insert_t_ibtdetl_line() 
			LET lf_ibtdetl.* = mr_ibtdetl.* 
			INITIALIZE ls_ibtdetl.* TO NULL 
			INITIALIZE lr_product.* TO NULL 
			INITIALIZE la_prodstatus[1].* TO NULL 
			INITIALIZE la_prodstatus[2].* TO NULL
			# Initialize the remainder part with the right values
			LET ma_ibtdetl_remainder[elem_num].picked_qty = 0
			LET ma_ibtdetl_remainder[elem_num].sched_qty = 0
			LET ma_ibtdetl_remainder[elem_num].conf_qty = 0
			LET ma_ibtdetl_remainder[elem_num].rec_qty = 0
			LET ma_ibtdetl_remainder[elem_num].back_qty = 0
			LET ma_ibtdetl_remainder[elem_num].amend_code = 0
			LET ma_ibtdetl_remainder[elem_num].amend_date = NULL
			LET ma_ibtdetl_remainder[elem_num].status_ind = 0
			LET ma_ibtdetl_remainder[elem_num].req_num = NULL
			LET ma_ibtdetl_remainder[elem_num].req_line_num = NULL
			END IF
			{
			-- ericv 20200722
			LET ma_ibtdetl_array[elem_num].line_num = pr_ibtdetl.line_num 
			LET ma_ibtdetl_array[elem_num].part_code = mr_ibtdetl.part_code 
			LET ma_ibtdetl_array[elem_num].desc_text = lr_product.desc_text 
			LET ma_ibtdetl_array[elem_num].trf_qty = mr_ibtdetl.trf_qty 
			LET ma_ibtdetl_array[elem_num].stock_uom_code = lr_product.stock_uom_code 
			LET ma_ibtdetl_array[elem_num].sell_tran_qty = mr_ibtdetl.trf_qty * lr_product.stk_sel_con_qty 
			LET ma_ibtdetl_array[elem_num].sell_uom_code = lr_product.sell_uom_code 
			DISPLAY ma_ibtdetl_array[elem_num].* TO sr_ibtdetl[screen_line].* 
			DISPLAY la_prodstatus[1].* TO sr_status[1].* 
			DISPLAY la_prodstatus[2].* TO sr_status[2].*
			}
		
		BEFORE FIELD scroll_flag
			NEXT FIELD part_code
		{ 
			LET elem_num = arr_curr() 
			LET screen_line = scr_line() 
			LET l_scroll_flag = ma_ibtdetl_array[elem_num].scroll_flag 
			--OPTIONS INSERT KEY f1, 
			--DELETE KEY f36 
			IF l_input_mode = "EDIT" THEN
				SELECT * INTO lf_ibtdetl.* FROM t_ibtdetl 
				WHERE line_num = ma_ibtdetl_array[elem_num].line_num 
				IF status = 0 THEN 
					SELECT * INTO lr_product.* FROM product 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = lf_ibtdetl.part_code 
					LET mr_ibtdetl.* = lf_ibtdetl.* 
					LET ma_ibtdetl_array[elem_num].line_num = mr_ibtdetl.line_num 
					LET ma_ibtdetl_array[elem_num].part_code = mr_ibtdetl.part_code 
					LET ma_ibtdetl_array[elem_num].desc_text = lr_product.desc_text 
					LET ma_ibtdetl_array[elem_num].trf_qty = mr_ibtdetl.trf_qty 
					LET ma_ibtdetl_array[elem_num].stock_uom_code = lr_product.stock_uom_code 
					IF ma_ibtdetl_array[elem_num].sell_tran_qty IS NULL THEN 
						LET ma_ibtdetl_array[elem_num].sell_tran_qty = mr_ibtdetl.trf_qty 
						* lr_product.stk_sel_con_qty 
					END IF 
					LET ma_ibtdetl_array[elem_num].sell_uom_code = lr_product.sell_uom_code 
					DISPLAY ma_ibtdetl_array[elem_num].* TO sr_ibtdetl[screen_line].* 
	
				ELSE 
					LET lf_ibtdetl.line_num = NULL 
					IF fgl_lastkey() = fgl_keyval("down") 
					OR fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("right") THEN 
						NEXT FIELD line_num 
					END IF 
				END IF 
			END IF
		}
		AFTER FIELD scroll_flag 
			IF elem_num <> 0 THEN
			LET ma_ibtdetl_array[elem_num].scroll_flag = l_scroll_flag 
			LET lr_lastkey = fgl_lastkey() 
			DISPLAY ma_ibtdetl_array[elem_num].scroll_flag TO sr_ibtdetl[screen_line].scroll_flag 

			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF ma_ibtdetl_array[elem_num].line_num IS NULL THEN 
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
			END IF
{
		-- ericv 20200728 commented out all this block
		BEFORE FIELD line_num 
			LET lr_lastkey = fgl_lastkey() 
			DISPLAY ma_ibtdetl_array[elem_num].* TO sr_ibtdetl[screen_line].* 

			IF ma_ibtdetl_array[elem_num].part_code IS NOT NULL THEN 
				IF ma_ibtdetl_array[elem_num].scroll_flag IS NOT NULL THEN 
					LET msgresp = kandoomsg("W",9016,"") 
					##9016 Order Line has been cancelled - Cannot Edit"
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
			IF lf_ibtdetl.line_num IS NULL THEN 
				CALL insert_t_ibtdetl_line() 
				LET lf_ibtdetl.* = mr_ibtdetl.* 
				INITIALIZE ls_ibtdetl.* TO NULL 
				INITIALIZE lr_product.* TO NULL 
				INITIALIZE la_prodstatus[1].* TO NULL 
				INITIALIZE la_prodstatus[2].* TO NULL 
				LET ma_ibtdetl_array[elem_num].line_num = mr_ibtdetl.line_num 
				LET ma_ibtdetl_array[elem_num].part_code = mr_ibtdetl.part_code 
				LET ma_ibtdetl_array[elem_num].desc_text = lr_product.desc_text 
				LET ma_ibtdetl_array[elem_num].trf_qty = mr_ibtdetl.trf_qty 
				LET ma_ibtdetl_array[elem_num].stock_uom_code = lr_product.stock_uom_code 
				LET ma_ibtdetl_array[elem_num].sell_tran_qty = mr_ibtdetl.trf_qty * lr_product.stk_sel_con_qty 
				LET ma_ibtdetl_array[elem_num].sell_uom_code = lr_product.sell_uom_code 
				DISPLAY ma_ibtdetl_array[elem_num].* TO sr_ibtdetl[screen_line].* 
				DISPLAY la_prodstatus[1].* TO sr_status[1].* 
				DISPLAY la_prodstatus[2].* TO sr_status[2].* 
			ELSE 
				LET ls_ibtdetl.* = lf_ibtdetl.* 
			END IF 
--			IF lr_lastkey = fgl_keyval("left") 
--			OR lr_lastkey = fgl_keyval("up") THEN 
--				NEXT FIELD scroll_flag 
--			ELSE 
				NEXT FIELD part_code 
			--END IF 
}

		AFTER FIELD part_code 
			IF elem_num <> 0 THEN
			LET mr_ibtdetl.part_code = ma_ibtdetl_array[elem_num].part_code  
			# part_code is not mandatory if we accept or cancel on this line
--			IF fgl_lastkey() <> fgl_keyval("accept") AND fgl_lastkey() <> fgl_keyval("cancel") THEN 
--				IF ma_ibtdetl_array[elem_num].part_code IS NULL THEN 
--					LET msgresp = kandoomsg("U",9102,"") 
--					#9102 Value must be entered
--					NEXT FIELD part_code 
--				END IF
			IF ma_ibtdetl_array[elem_num].part_code IS NOT NULL THEN
				# check if not repeating the same part code
				FOR i = 1 TO arr_count() 
					IF ma_ibtdetl_array[i].part_code = ma_ibtdetl_array[elem_num].part_code 
					AND i <> elem_num THEN 
						LET msgresp = kandoomsg("I",9113,"") 
						# I9113 Product has already been used
						NEXT FIELD part_code 
					END IF 
				END FOR 
				
				# Check that the product exists
				SELECT product.* INTO lr_product.* 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = ma_ibtdetl_array[elem_num].part_code 
				IF sqlca.sqlcode = notfound THEN 
					LET msgresp = kandoomsg("U",9105,"") 
					#9105 RECORD NOT found, try window
					NEXT FIELD part_code 
				END IF
				LET ma_ibtdetl_addl_data[elem_num].stk_sel_con_qty = lr_product.stk_sel_con_qty
				LET ma_ibtdetl_addl_data[elem_num].serial_flag = lr_product.serial_flag
				
				IF mr_ibthead.sched_ind = '2' 
				AND ma_ibtdetl_addl_data[elem_num].serial_flag = 'Y' THEN 
					LET msgresp = kandoomsg("I",9286,"") 
					#9286 Serial Items cannot be used with Type 2 Transfer
					NEXT FIELD part_code 
				END IF 
				
				IF l_part_code <> ma_ibtdetl_array[elem_num].part_code THEN 
					CALL serial_delete(l_part_code,mr_ibthead.from_ware_code) 
					
					IF ma_ibtdetl_addl_data[elem_num].serial_flag = 'Y' THEN 
						LET ma_ibtdetl_array[elem_num].trf_qty = 0 
						LET ma_ibtdetl_array[elem_num].sell_tran_qty = 0 
						DISPLAY ma_ibtdetl_array[elem_num].trf_qty, 
						ma_ibtdetl_array[elem_num].sell_tran_qty 
						TO sr_ibtdetl[screen_line].trf_qty, 
						sr_ibtdetl[screen_line].sell_tran_qty 
	
					END IF 
				END IF 
	
				# check if this product belongs to a category and warehouse that has a budget created
				# mandatory to insert into prodledger 
				SELECT acct_mask_code INTO l_dest_mask_code 
				FROM warehouse 
				WHERE ware_code = mr_ibthead.to_ware_code  
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				
				SELECT adj_acct_code INTO mr_prodledg.acct_code 
				FROM category 
				WHERE cat_code = lr_product.cat_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 

				LET l_prodledg_acct_code = build_mask(glob_rec_kandoouser.cmpy_code,l_dest_mask_code,mr_prodledg.acct_code)

				SELECT * INTO lr_prodstatus.* 
				FROM prodstatus 
				WHERE part_code = ma_ibtdetl_array[elem_num].part_code 
				AND ware_code = mr_ibthead.from_ware_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF sqlca.sqlcode = notfound THEN 
					LET msgresp = kandoomsg("I",7035,"") 
					#7035 Product STATUS FOR warehouse NOT found,try again
					NEXT FIELD part_code 
				END IF
				IF lr_product.status_ind = "3" THEN 
					LET msgresp = kandoomsg("I",9511,"") 
					#9511 This product has been deleted
					NEXT FIELD part_code 
				END IF 
				IF lr_prodstatus.status_ind = "3" THEN 
					LET msgresp = kandoomsg("U",9915,mr_ibthead.from_ware_code) 
					#9915 Product has been deleted AT the MEL warehouse
					NEXT FIELD part_code 
				END IF 
				
				# Check that the product exists in the "to" warehouse
				SELECT * INTO ls_prodstatus.* 
				FROM prodstatus 
				WHERE part_code = ma_ibtdetl_array[elem_num].part_code 
				AND ware_code = mr_ibthead.to_ware_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF sqlca.sqlcode != notfound THEN 
					IF ls_prodstatus.status_ind = "3" THEN 
						LET msgresp = kandoomsg("U",9915,mr_ibthead.to_ware_code) 
						#9915 Product has been deleted AT the MEL warehouse
						NEXT FIELD part_code 
					END IF 
				END IF 
	
				IF get_kandoooption_feature_state(TRAN_TYPE_INVOICE_IN,"FS") = "Y" 
				AND mult_segs(glob_rec_kandoouser.cmpy_code, lr_product.class_code) THEN 
					CASE 
						WHEN mr_ibthead.sched_ind = 0 
							IF NOT validate_despatch_segment(glob_rec_kandoouser.cmpy_code, ma_ibtdetl_array[elem_num].part_code, false) THEN 
								LET msgresp = kandoomsg("W",9503,"") 
								#9503 "Must despatch AT lowest segment level"
								NEXT FIELD part_code 
							END IF 
						OTHERWISE 
							IF NOT validate_order_segment(
							glob_rec_kandoouser.cmpy_code, 
							ma_ibtdetl_array[elem_num].part_code, 
							lr_product.class_code, 
							false
							) THEN 
								LET msgresp = kandoomsg("W",9500,"") 
								#9500 "Must enter up TO Order segment"
								NEXT FIELD part_code 
							END IF 
					END CASE 
				END IF 
	
				# why update 300 times in the same row?
				-- CALL update_t_ibtdetl_line(elem_num) 
				LET ma_ibtdetl_array[elem_num].desc_text = lr_product.desc_text 
				LET ma_ibtdetl_array[elem_num].stock_uom_code = lr_product.stock_uom_code 
				LET ma_ibtdetl_array[elem_num].sell_uom_code = lr_product.sell_uom_code 
				DISPLAY ma_ibtdetl_array[elem_num].* TO sr_ibtdetl[screen_line].* 
	
				LET l_prodstatus_avail_qty = stock_status(ma_ibtdetl_array[elem_num].part_code) 
				IF l_prodstatus_avail_qty IS NULL THEN 
					LET msgresp = kandoomsg("U",9930,"Available quantity IS NULL") 
					#9930 Logic Error: Available quantity IS NULL
					NEXT FIELD part_code 
				END IF 
				IF fgl_lastkey() = fgl_keyval("accept") THEN 
					IF ma_ibtdetl_array[elem_num].trf_qty IS NULL 
					OR ma_ibtdetl_array[elem_num].trf_qty = 0 THEN 
						NEXT FIELD trf_qty 
					ELSE 
						LET ma_ibtdetl_array[elem_num].sell_tran_qty = ma_ibtdetl_array[elem_num].trf_qty 
						* lr_product.stk_sel_con_qty 
						NEXT FIELD scroll_flag 
					END IF 
				END IF 

			END IF 
			END IF		

		BEFORE FIELD trf_qty 
			IF elem_num <> 0 THEN
			SELECT * INTO ln_ibtdetl.* 
			FROM ibtdetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND trans_num = mr_ibthead.trans_num 
			AND line_num = ma_ibtdetl_array[elem_num].line_num 
			
			## check in array
			IF sqlca.sqlcode = notfound THEN 
				LET l_delivered_qty = 0 
			ELSE 
				LET l_delivered_qty = ln_ibtdetl.sched_qty 
				+ ln_ibtdetl.picked_qty 
				+ ln_ibtdetl.conf_qty 
				+ ln_ibtdetl.rec_qty 
			END IF 

			IF ma_ibtdetl_addl_data[elem_num].serial_flag = 'Y' THEN 
				LET lr_lastkey = fgl_lastkey() 
				IF ma_ibtdetl_array[elem_num].trf_qty IS NULL THEN 
					LET ma_ibtdetl_array[elem_num].trf_qty = 0 
				END IF 
				LET l_act_qty = ma_ibtdetl_array[elem_num].trf_qty 
				- ( l_delivered_qty / lr_product.stk_sel_con_qty) 
				IF l_act_qty IS NULL THEN 
					LET l_act_qty = 0 
				END IF 
				LET l_prod_serial_cnt = serial_input(ma_ibtdetl_array[elem_num].part_code,mr_ibthead.from_ware_code,l_act_qty ) 
				IF l_prod_serial_cnt < 0 THEN 
					IF l_prod_serial_cnt = -1 THEN 
						NEXT FIELD part_code 
					ELSE 
						CALL errorlog("I51a - Fatal error in serial_input ") 
						EXIT program 
					END IF 
				ELSE 
					LET ma_ibtdetl_array[elem_num].trf_qty = ma_ibtdetl_array[elem_num].trf_qty + l_prod_serial_cnt - l_act_qty 
					IF ma_ibtdetl_array[elem_num].trf_qty <= 0 THEN 
						LET msgresp = kandoomsg("I",9085,"") 
						#9085 Quantity must be greater than zero
						NEXT FIELD part_code 
					END IF 
					
					SELECT * INTO ln_ibtdetl.* 
					FROM ibtdetl 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND trans_num = mr_ibthead.trans_num 
					AND line_num = ma_ibtdetl_array[elem_num].line_num 
					IF sqlca.sqlcode = notfound THEN 
						LET l_delivered_qty = 0 
					ELSE 
						LET l_delivered_qty = ln_ibtdetl.sched_qty 
						+ ln_ibtdetl.picked_qty 
						+ ln_ibtdetl.conf_qty 
						+ ln_ibtdetl.rec_qty 
					END IF 
					LET mr_ibtdetl.trf_qty = ma_ibtdetl_array[elem_num].trf_qty 
					LET mr_ibtdetl.back_qty = mr_ibtdetl.trf_qty 
					- mr_ibtdetl.sched_qty 
					- mr_ibtdetl.picked_qty 
					- mr_ibtdetl.conf_qty 
					- mr_ibtdetl.rec_qty 
					# why update 300 times on the same line?
					-- CALL update_t_ibtdetl_line(elem_num) 
					LET lf_ibtdetl.* = mr_ibtdetl.* 
					DISPLAY ma_ibtdetl_array[elem_num].trf_qty 
					TO sr_ibtdetl[screen_line].trf_qty 

					LET ma_ibtdetl_array[elem_num].sell_tran_qty 
					= ma_ibtdetl_array[elem_num].trf_qty * lr_product.stk_sel_con_qty 
					DISPLAY ma_ibtdetl_array[elem_num].sell_tran_qty 
					TO sr_ibtdetl[screen_line].sell_tran_qty 

					--IF lr_lastkey = fgl_keyval("up") 
					--OR lr_lastkey = fgl_keyval("left") THEN 
						--NEXT FIELD previous 
					--ELSE 
						--NEXT FIELD NEXT 
					--END IF 
				END IF 
			END IF 
			END IF

		AFTER FIELD trf_qty 
			IF elem_num <> 0 THEN
			CASE 
				WHEN ma_ibtdetl_array[elem_num].trf_qty IS NULL 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD trf_qty 
				WHEN ma_ibtdetl_array[elem_num].trf_qty <= 0 
					LET msgresp = kandoomsg("I",9085,"") 
					#9085 Quantity must be greater than zero
					NEXT FIELD trf_qty 
				WHEN (ma_ibtdetl_array[elem_num].trf_qty * lr_product.stk_sel_con_qty)	< l_delivered_qty 
					LET msgresp = kandoomsg("W",9459,"") 
					#9459 Value must be greater than OR equal TO delivered quantity
					NEXT FIELD trf_qty 
			END CASE 
			IF (ma_ibtdetl_array[elem_num].trf_qty * lr_product.stk_sel_con_qty) > l_prodstatus_avail_qty THEN 
				LET msgresp = kandoomsg("I",9112,"") 
				NEXT FIELD trf_qty
				#9112 Insufficient stock available
			END IF 
			LET mr_ibtdetl.trf_qty = ma_ibtdetl_array[elem_num].trf_qty 
			
			IF field_touched(trf_qty) THEN
				# to be double checked here when we modify this value, the other cumulated values must be recalculate for the DIFFERENCE
				# totals on quantities should be equal to difference between former value and current value
				IF ls_array.trf_qty <> ma_ibtdetl_array[elem_num].trf_qty AND ma_action_array[elem_num] = "U" THEN
					# if trf_qty is modified, the prodstatus qty should be modified by differential
					LET ma_ibtdetl_array[elem_num].trf_qty = ma_ibtdetl_array[elem_num].trf_qty
				END IF 
			END IF 
			LET mr_ibtdetl.back_qty = mr_ibtdetl.trf_qty 
			- mr_ibtdetl.sched_qty 
			- mr_ibtdetl.picked_qty 
			- mr_ibtdetl.conf_qty 
			- mr_ibtdetl.rec_qty 
			
			# why update 300 times in the same line ?
			-- CALL update_t_ibtdetl_line(elem_num)  
			LET lf_ibtdetl.* = mr_ibtdetl.* 
			DISPLAY ma_ibtdetl_array[elem_num].trf_qty TO sr_ibtdetl[screen_line].trf_qty 

			LET ma_ibtdetl_array[elem_num].sell_tran_qty = ma_ibtdetl_array[elem_num].trf_qty 
			* lr_product.stk_sel_con_qty 
			DISPLAY ma_ibtdetl_array[elem_num].sell_tran_qty 
			TO sr_ibtdetl[screen_line].sell_tran_qty 
			END IF
			--CASE 
				--WHEN fgl_lastkey() = fgl_keyval("accept") 
					--NEXT FIELD scroll_flag 
				--WHEN fgl_lastkey() = fgl_keyval("RETURN") 
					--OR fgl_lastkey() = fgl_keyval("right") 
					--OR fgl_lastkey() = fgl_keyval("tab") 
					--OR fgl_lastkey() = fgl_keyval("down") 
					--NEXT FIELD NEXT 
				--WHEN fgl_lastkey() = fgl_keyval("left") 
					--OR fgl_lastkey() = fgl_keyval("up") 
					--NEXT FIELD part_code 
				--OTHERWISE 
					--NEXT FIELD trf_qty 
			--END CASE 

		BEFORE FIELD sell_tran_qty 
			NEXT FIELD NEXT 
			
		AFTER ROW
			--IF fgl_lastkey() <> fgl_keyval("accept") AND fgl_lastkey() <> fgl_keyval("cancel") THEN
				# check if the part code has not been forgotten if not simply exiting the input array
			IF elem_num <> 0 THEN
			CASE
				WHEN field_touched(sr_ibtdetl[elem_num].*) AND ma_action_array[elem_num].todo IS NULL
					# This is a new row to be Inserted
					LET ma_action_array[elem_num].todo = "I"	# This element must be updated. I is marked as I after insert and D on action delete
				WHEN field_touched(sr_ibtdetl[elem_num].*) AND ma_action_array[elem_num].todo = "N"
					# this is an existing element that has been modified
					LET ma_action_array[elem_num].todo = "U"	# This element must be updated. I is marked as I after insert and D on action delete
			END CASE
			
			CASE  
				WHEN ma_ibtdetl_array[elem_num].part_code IS NOT NULL AND ma_ibtdetl_array[elem_num].trf_qty IS NOT NULL
					# all the required data is OK, we can proceed
					--CALL update_t_ibtdetl_line(elem_num)
					--DISPLAY ma_ibtdetl_array[elem_num].* TO sr_ibtdetl[screen_line].*
				
				WHEN (ma_ibtdetl_array[elem_num].part_code IS NULL AND ma_ibtdetl_array[elem_num].trf_qty IS NOT NULL )
				OR (ma_ibtdetl_array[elem_num].part_code IS NOT NULL AND ma_ibtdetl_array[elem_num].trf_qty IS NULL )
					LET msgresp = kandoomsg("U",9102,"") 
--					#9102 Value must be entered
					NEXT FIELD part_code 			
				OTHERWISE
					DELETE FROM t_ibtdetl 
					WHERE line_num = elem_num
					CALL ma_ibtdetl_array.delete(elem_num)
			END CASE
			END IF		

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				{
				IF NOT infield(scroll_flag) THEN 
					LET int_flag = false 
					LET quit_flag = false 
					IF ls_ibtdetl.line_num IS NULL THEN 
						DELETE FROM t_ibtdetl 
						WHERE line_num = ma_ibtdetl_array[elem_num].line_num 
						LET j = screen_line 
						FOR i = arr_curr() TO arr_count() 
							IF ma_ibtdetl_array[i+1].line_num IS NOT NULL THEN 
								LET ma_ibtdetl_array[i].* = ma_ibtdetl_array[i+1].* 
							ELSE 
								INITIALIZE ma_ibtdetl_array[i].* TO NULL 
							END IF 
							IF j <= 6 THEN 
								IF ma_ibtdetl_array[i].line_num = 0 THEN 
									LET ma_ibtdetl_array[i].line_num = NULL 
								END IF 
								IF ma_ibtdetl_array[i].trf_qty = 0 THEN 
									LET ma_ibtdetl_array[i].trf_qty = NULL 
									LET ma_ibtdetl_array[i].sell_tran_qty = NULL 
								END IF 
								DISPLAY ma_ibtdetl_array[i].* TO sr_ibtdetl[j].* 

								LET j = j + 1 
							END IF 
						END FOR 
					ELSE 
						LET mr_ibtdetl.* = ls_ibtdetl.* 
						CALL update_t_ibtdetl_line(elem_num) 
						SELECT * INTO lr_product.* 
						FROM product 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND part_code = lf_ibtdetl.part_code 
						LET mr_ibtdetl.* = lf_ibtdetl.* 
						LET ma_ibtdetl_array[elem_num].line_num = ls_ibtdetl.line_num 
						LET ma_ibtdetl_array[elem_num].part_code = ls_ibtdetl.part_code 
						LET ma_ibtdetl_array[elem_num].desc_text = lr_product.desc_text 
						LET ma_ibtdetl_array[elem_num].trf_qty = ls_ibtdetl.trf_qty 
						LET ma_ibtdetl_array[elem_num].stock_uom_code = lr_product.stock_uom_code 
						LET ma_ibtdetl_array[elem_num].sell_tran_qty = ls_ibtdetl.trf_qty 
						* lr_product.stk_sel_con_qty 
						LET ma_ibtdetl_array[elem_num].sell_uom_code = lr_product.sell_uom_code 
					END IF 
					NEXT FIELD scroll_flag 
				END IF
				} 
			ELSE 
				IF ma_ibtdetl_array[1].part_code IS NULL THEN 
					LET msgresp = kandoomsg("W",9470,"") 
					#9470 Transfer must have lines TO continue
					--NEXT FIELD scroll_flag 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
		RETURN false 
	END IF 
	
	IF l_input_mode = "ADD" THEN 
		LET msgresp = kandoomsg("I",8044,"") 
		#8044 Confirm TO create stock transfer
		IF msgresp = "Y" THEN 
			LET m_sched_ind_sto = NULL 
			IF mr_ibthead.trans_date IS NULL THEN 
				LET mr_ibthead.trans_date = today 
			END IF 
			
			BEGIN WORK
			SET ISOLATION TO REPEATABLE READ
			IF insert_into_transfer_header() THEN 
				
				FOR elem_num = 1 TO  ma_ibtdetl_array.GetSize()
					LET ma_prodledg[elem_num].part_code = ma_ibtdetl_array[elem_num].part_code 
					LET ma_prodledg[elem_num].desc_text = ma_ibtdetl_array[elem_num].desc_text 
					LET ma_prodledg[elem_num].stock_tran_qty = ma_ibtdetl_array[elem_num].trf_qty 
					LET ma_prodledg[elem_num].stock_uom_code = ma_ibtdetl_array[elem_num].stock_uom_code 
					LET ma_prodledg[elem_num].sell_tran_qty = ma_ibtdetl_array[elem_num].sell_tran_qty 
					LET ma_prodledg[elem_num].sell_uom_code = ma_ibtdetl_array[elem_num].sell_uom_code 
				END FOR 
				LET mr_prodledg.ware_code = mr_ibthead.from_ware_code 
				LET mr_prodledg.source_text = mr_ibthead.to_ware_code 
				LET mr_prodledg.tran_date = mr_ibthead.trans_date 
				LET mr_prodledg.year_num = mr_ibthead.year_num 
				LET mr_prodledg.period_num = mr_ibthead.period_num 
				LET mr_prodledg.desc_text = mr_ibthead.desc_text 
				IF mr_ibthead.sched_ind != "0" THEN 
					IF NOT insert_into_transfer_lines() THEN
						ROLLBACK WORK 
						RETURN false 
					END IF 
				ELSE 
					--IF NOT immediate_transfer() THEN   
					LET l_trans_num = immediate_transfer() 
					IF l_trans_num IS NULL THEN
						ROLLBACK WORK 
						RETURN false 
					END IF 
				END IF 
			ELSE 
				ROLLBACK WORK
				RETURN false 
			END IF
			--DELETE FROM t_ibtdetl
			COMMIT WORK 
			DISPLAY BY NAME mr_ibthead.trans_num
			CALL print_transfer("ADD") 
			RETURN true 
		END IF 
		SET ISOLATION TO COMMITTED READ
		ROLLBACK WORK
		RETURN false 
	ELSE 
		LET m_sched_ind_sto = NULL 
		BEGIN WORK
		SET ISOLATION TO REPEATABLE READ
		IF NOT insert_into_transfer_lines() THEN
			ROLLBACK WORK 
			RETURN false 
		END IF 
		--DELETE FROM t_ibtdetl
		SET ISOLATION TO COMMITTED READ 
		COMMIT WORK
		DISPLAY BY NAME mr_ibthead.trans_num
		ERROR "This transfer has completed successfully"
		CALL print_transfer("EDIT") 
		RETURN true 
	END IF 
END FUNCTION 		# product_lines_entry


FUNCTION insert_into_transfer_header() 
	DEFINE 
	lr_ibthead RECORD LIKE ibthead.*, 
	lr_inparms RECORD LIKE inparms.*, 
	lr_supply RECORD LIKE supply.*, 
	lr_suburb RECORD LIKE suburb.*, 
	lr_warehouse RECORD LIKE warehouse.*, 
	err_message CHAR(40) 

	LET msgresp=kandoomsg("U",1005,"") 
	#1005 Updating database - please wait

		# First increment next_trans_num
		# Exceptionnally allow set lock mode to wait 2
		SET LOCK MODE TO WAIT 2
		UPDATE inparms 
		SET next_trans_num = next_trans_num + 1 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND parm_code = "1"
		
		# then take its value
		SELECT * INTO lr_inparms.*
		FROM inparms 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND parm_code = "1" 
		
		LET mr_ibthead.trans_num = lr_inparms.next_trans_num 
		LET lr_ibthead.* = mr_ibthead.* 
		LET lr_ibthead.cmpy_code = glob_rec_kandoouser.cmpy_code 
		INITIALIZE lr_warehouse.* TO NULL 
		INITIALIZE lr_suburb.* TO NULL 
		INITIALIZE lr_supply.* TO NULL 
		
		# locate the 'to' warehouse and calculate distance
		SELECT * INTO lr_warehouse.* 
		FROM warehouse 
		WHERE ware_code = mr_ibthead.to_ware_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		
		# Take the first row with that City in suburb, can have more than 1 row per city
		CALL crs_suburb_city.SetParameters(lr_warehouse.city_text,lr_warehouse.state_code,glob_rec_kandoouser.cmpy_code)
		CALL crs_suburb_city.open()							#  
		CALL crs_suburb_city.fetchNext()
		CALL crs_suburb_city.SetResults(lr_suburb.*)

		SELECT * INTO lr_supply.* 
		FROM supply 
		WHERE suburb_code = lr_suburb.suburb_code 
		AND ware_code = mr_ibthead.from_ware_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		
		LET lr_ibthead.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET lr_ibthead.km_qty = lr_supply.km_qty 
		LET lr_ibthead.cart_area_code = lr_warehouse.cart_area_code 
		LET lr_ibthead.entry_date = today 
		LET lr_ibthead.entry_code = glob_rec_kandoouser.sign_on_code 
		LET lr_ibthead.rev_num = 0 
		LET lr_ibthead.del_num = 0 
		LET lr_ibthead.amend_date = NULL 
		LET lr_ibthead.status_ind = IBTHEAD_STATUS_IND_TRANSFER_CANCELLED_R 
		
 		LET err_message = " I51a - Adding Order Header Row" 
		
		INSERT INTO ibthead VALUES (lr_ibthead.*) 
		LET mr_ibthead.* = lr_ibthead.* 
	--COMMIT WORK 
	--WHENEVER ERROR CONTINUE 
	RETURN true 
END FUNCTION 		# insert_into_transfer_header

FUNCTION insert_into_transfer_lines() 
	DEFINE 
	lr_product RECORD LIKE product.*, 
	lr_prodstatus RECORD LIKE prodstatus.*, 
	ls_ibtdetl RECORD LIKE ibtdetl.*, 			# clone of lr_ibtdetl, serves as a backup in case of cancel
	lr_ibtdetl RECORD LIKE ibtdetl.*, 
	lr_ibthead RECORD LIKE ibthead.*, 
	lr_src_prodstatus RECORD LIKE prodstatus.*, 
	lr_dst_prodstatus RECORD LIKE prodstatus.*, 
	lr_serialinfo RECORD LIKE serialinfo.*, 
	ls_prodledg RECORD LIKE prodledg.*, 
	l_stk_sel_con_qty LIKE product.stk_sel_con_qty, 
	l_serial_flag LIKE product.serial_flag, 
	total_lineitems SMALLINT, 
	err_message CHAR(200), 
	l_ibtcnt, pr_rec_cnt SMALLINT, 
	l_line_num, i SMALLINT
	DEFINE l_act_qty LIKE ibtdetl.sched_qty
	DEFINE serial_status SMALLINT 
	DEFINE elem_num SMALLINT
	DEFINE l_back_order_qty LIKE prodstatus.back_qty
	DEFINE l_sum_trf_qty LIKE ibtdetl.trf_qty
	DEFINE l_sum_sched_qty LIKE ibtdetl.sched_qty 
	DEFINE l_sum_picked_qty LIKE ibtdetl.picked_qty 
	DEFINE l_sum_rec_qty LIKE ibtdetl.rec_qty 
	DEFINE l_sum_conf_qty LIKE ibtdetl.conf_qty 
	DEFINE l_sum_back_qty LIKE ibtdetl.back_qty

	
	SELECT * INTO mr_inparms.* 
	FROM inparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 

	SELECT *  INTO lr_ibthead.*
	FROM ibthead 
	WHERE trans_num = mr_ibthead.trans_num 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code
	
	LET total_lineitems = 0
	IF m_mode = "EDIT" THEN 
		IF lr_ibthead.rev_num != mr_ibthead.rev_num THEN 
			LET msgresp = kandoomsg("W",7026,"") 
			#7026 Another user has edited this ORDER - Changes NOT saved
			LET err_message = "I51a - Another user has modified transfer" 
			ROLLBACK WORK 
			RETURN false 
		END IF 

		LET mr_ibthead.amend_code = glob_rec_kandoouser.sign_on_code 
		LET mr_ibthead.amend_date = today 

	END IF
	
		LET l_sum_trf_qty = 0 
		LET l_sum_sched_qty = 0 
		LET l_sum_picked_qty = 0 
		LET l_sum_rec_qty = 0  
		LET l_sum_conf_qty = 0 
		LET l_sum_back_qty = 0 
	
	FOR elem_num = 1 TO ma_ibtdetl_array.GetSize()
	# Scan the ma_ibtdetl array instead of the temp table
		LET total_lineitems = total_lineitems + 1
		--LET ls_ibtdetl.cmpy_code = glob_rec_kandoouser.cmpy_code
		--LET ls_ibtdetl.conf_qty = ls_ibtdetl.conf_qty * lr_product.stk_sel_con_qty 
		--LET ls_ibtdetl.picked_qty = ls_ibtdetl.picked_qty * lr_product.stk_sel_con_qty 
		--LET ls_ibtdetl.sched_qty = ls_ibtdetl.sched_qty 			* lr_product.stk_sel_con_qty	
		
		LET lr_ibtdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET lr_ibtdetl.trans_num = mr_ibthead.trans_num 
		LET lr_ibtdetl.line_num = elem_num 
		LET lr_ibtdetl.part_code = ma_ibtdetl_array[elem_num].part_code
		LET lr_ibtdetl.trf_qty = ma_ibtdetl_array[elem_num].trf_qty * ma_ibtdetl_addl_data[elem_num].stk_sel_con_qty
		LET lr_ibtdetl.sched_qty = ma_ibtdetl_remainder[elem_num].sched_qty * ma_ibtdetl_addl_data[elem_num].stk_sel_con_qty 
		LET lr_ibtdetl.picked_qty = ma_ibtdetl_remainder[elem_num].picked_qty * ma_ibtdetl_addl_data[elem_num].stk_sel_con_qty 
		LET lr_ibtdetl.rec_qty = ma_ibtdetl_remainder[elem_num].rec_qty * ma_ibtdetl_addl_data[elem_num].stk_sel_con_qty 
		LET lr_ibtdetl.conf_qty = ma_ibtdetl_remainder[elem_num].conf_qty * ma_ibtdetl_addl_data[elem_num].stk_sel_con_qty 
		LET lr_ibtdetl.back_qty = ma_ibtdetl_remainder[elem_num].back_qty * ma_ibtdetl_addl_data[elem_num].stk_sel_con_qty
		LET lr_ibtdetl.amend_code = ma_ibtdetl_remainder[elem_num].amend_code
		LET lr_ibtdetl.amend_date = ma_ibtdetl_remainder[elem_num].amend_date
		LET lr_ibtdetl.status_ind = ma_ibtdetl_remainder[elem_num].status_ind
		LET lr_ibtdetl.req_num = ma_ibtdetl_remainder[elem_num].req_num
		LET lr_ibtdetl.req_line_num = ma_ibtdetl_remainder[elem_num].req_line_num
		
		# Calculate sums of qties to give status to head
		LET l_sum_trf_qty = l_sum_trf_qty + lr_ibtdetl.trf_qty 
		LET l_sum_sched_qty = l_sum_sched_qty + lr_ibtdetl.sched_qty 
		LET l_sum_picked_qty = l_sum_picked_qty + lr_ibtdetl.picked_qty 
		LET l_sum_rec_qty = l_sum_rec_qty + lr_ibtdetl.rec_qty  
		LET l_sum_conf_qty = l_sum_conf_qty + lr_ibtdetl.conf_qty 
		LET l_sum_back_qty = l_sum_back_qty + lr_ibtdetl.back_qty 
		
		--IF lr_ibtdetl.line_num > total_lineitems THEN
		CASE
			WHEN ma_action_array[elem_num].todo = "I"
				# the row is set to be inserted  
				INSERT INTO ibtdetl VALUES (lr_ibtdetl.*) 
				# all this quantity is added to back order qty
				LET l_back_order_qty = lr_ibtdetl.back_qty
			WHEN ma_action_array[elem_num].todo = "U"
				# the row is set to be updated 
				LET lr_ibtdetl.amend_code = glob_rec_kandoouser.sign_on_code 
				LET lr_ibtdetl.amend_date = today 
				UPDATE ibtdetl 
				SET * = lr_ibtdetl.* 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND trans_num = mr_ibthead.trans_num 
				AND line_num = lr_ibtdetl.line_num 
				# this quantity should be based on difference with former value if modified
				LET l_back_order_qty = lr_ibtdetl.back_qty

			WHEN ma_action_array[elem_num].todo = "D"
				# the row is set to be deleted
			OTHERWISE
				# Do nothing 
				CONTINUE FOR
		END CASE 
		
		UPDATE prodstatus 
		--SET back_qty = back_qty + lr_ibtdetl.back_qty 
		SET back_qty = back_qty + l_back_order_qty
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND ware_code = mr_ibthead.from_ware_code 
		AND part_code = lr_ibtdetl.part_code 

		IF l_serial_flag = "Y" THEN 
			IF lr_ibtdetl.status_ind = IBTDETL_STATUS_IND_CANCELED_4 THEN 
				CALL serial_delete(lr_ibtdetl.part_code,mr_ibthead.from_ware_code) 
				LET status = serial_return(lr_ibtdetl.part_code,"0") 
			ELSE 
				LET l_act_qty = (lr_ibtdetl.trf_qty-lr_ibtdetl.sched_qty-lr_ibtdetl.picked_qty-lr_ibtdetl.conf_qty-lr_ibtdetl.rec_qty) / l_stk_sel_con_qty 
				IF l_act_qty IS NULL THEN 
					LET l_act_qty = 0 
				END IF 
				LET err_message = "I51a - Save serial_update " 
				LET lr_serialinfo.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET lr_serialinfo.part_code = lr_ibtdetl.part_code 
				LET lr_serialinfo.ware_code = mr_ibthead.from_ware_code 
				LET lr_serialinfo.ref_num = mr_ibthead.trans_num 
				LET lr_serialinfo.trans_num = mr_ibthead.trans_num 
				LET lr_serialinfo.trantype_ind = 'T' 
				LET serial_status = serial_update(lr_serialinfo.*, l_act_qty,'0') 
				IF serial_status <> 0 THEN
					ERROR "Houston we have a problem" 
					--GOTO recovery 
				END IF 
			END IF 
		END IF 
		 
	END FOR		# For of array scan
	
		
	# Calculate the flag of the header
	CASE
		WHEN l_sum_rec_qty = l_sum_trf_qty 
			# transfer complete
			LET mr_ibthead.status_ind = IBTHEAD_STATUS_IND_TRANSFER_COMPLETED_C
		
		WHEN l_sum_rec_qty > 0 AND l_sum_rec_qty + l_sum_conf_qty < l_sum_trf_qty
			# transfer Partially complete
			LET mr_ibthead.status_ind = IBTHEAD_STATUS_IND_TRANSFER_PARTIALLY_COMPLETED_P
			
		OTHERWISE
			# transfer Uncomplete
			LET mr_ibthead.status_ind = IBTHEAD_STATUS_IND_TRANSFER_UNDELIVERED_U
	END CASE
			
{		SELECT count(*) INTO pr_ibtcnt 
		FROM t_ibtdetl 
		WHERE (conf_qty + rec_qty) < trf_qty 
		AND status_ind <> "4" 
		IF pr_ibtcnt = 0 THEN 
			SELECT count(*) INTO pr_rec_cnt 
			FROM t_ibtdetl 
			WHERE rec_qty < trf_qty 
			AND status_ind <> "4" 
			IF pr_rec_cnt = 0 THEN 
				LET mr_ibthead.status_ind = IBTHEAD_STATUS_IND_TRANSFER_COMPLETED_C 
			ELSE 
				LET mr_ibthead.status_ind = IBTHEAD_STATUS_IND_TRANSFER_PARTIALLY_COMPLETED_P 
			END IF 
		ELSE 
			SELECT count(*) INTO pr_ibtcnt 
			FROM t_ibtdetl 
			WHERE (conf_qty + rec_qty) != 0 
			AND status_ind <> "4" 
			IF pr_ibtcnt = 0 THEN 
				LET mr_ibthead.status_ind = IBTHEAD_STATUS_IND_TRANSFER_UNDELIVERED_U 
			ELSE 
				LET mr_ibthead.status_ind = IBTHEAD_STATUS_IND_TRANSFER_PARTIALLY_COMPLETED_P 
			END IF 
		END IF 
	END IF 
	LET mr_ibthead.rev_num = mr_ibthead.rev_num + 1 
	IF mr_ibthead.sched_ind = "0" THEN 
		LET mr_ibthead.status_ind = IBTHEAD_STATUS_IND_TRANSFER_COMPLETED_C 
	END IF
} 
	UPDATE ibthead 
	SET * = mr_ibthead.* 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND trans_num = mr_ibthead.trans_num 
	
	RETURN true
	
END FUNCTION  # insert_into_transfer_lines()



FUNCTION immediate_transfer() 
# this function scrolls the t_ibtdetl lines and copies them to ibtdetl
# it updates ibthead accordingly, as well as prodstatus
	
	DEFINE 
	ls_prodledg RECORD LIKE prodledg.*, 
	lr_product RECORD LIKE product.*, 
	lr_ibtdetl RECORD LIKE ibtdetl.*, 
	lr_serialinfo RECORD LIKE serialinfo.*, 
	l_stk_sel_con_qty LIKE product.stk_sel_con_qty, 
	l_serial_flag LIKE product.serial_flag, 
	total_lineitems SMALLINT, 
	err_message CHAR(200), 
	l_ibtcnt,lr_rec_cnt SMALLINT, 
	l_line_num,i,elem_num SMALLINT 

	LET msgresp=kandoomsg("U",1005,"") 

	# ericv: should be done by reading the array		 
		LET l_line_num = 0
		CALL crs_all_t_ibtdetl.open()
		
	FOR elem_num = 1 TO ma_ibtdetl_array.GetSize()
	# Scan the ma_ibtdetl array instead of the temp table
		LET total_lineitems = total_lineitems + 1
		--LET ls_ibtdetl.cmpy_code = glob_rec_kandoouser.cmpy_code
		--LET ls_ibtdetl.conf_qty = ls_ibtdetl.conf_qty * lr_product.stk_sel_con_qty 
		--LET ls_ibtdetl.picked_qty = ls_ibtdetl.picked_qty * lr_product.stk_sel_con_qty 
		--LET ls_ibtdetl.sched_qty = ls_ibtdetl.sched_qty 			* lr_product.stk_sel_con_qty
		SELECT stk_sel_con_qty INTO l_stk_sel_con_qty 
		FROM product 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = ma_ibtdetl_array[elem_num].part_code
		
		LET lr_ibtdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET lr_ibtdetl.trans_num = mr_ibthead.trans_num 
		LET lr_ibtdetl.line_num = elem_num 
		LET lr_ibtdetl.part_code = ma_ibtdetl_array[elem_num].part_code
		LET lr_ibtdetl.trf_qty = ma_ibtdetl_array[elem_num].trf_qty * l_stk_sel_con_qty
		LET lr_ibtdetl.rec_qty = lr_ibtdetl.trf_qty
		LET lr_ibtdetl.sched_qty = 0 
		LET lr_ibtdetl.picked_qty = 0 
		LET lr_ibtdetl.conf_qty = 0
		LET lr_ibtdetl.back_qty = 0
	
		WHENEVER SQLERROR CONTINUE
		INSERT INTO ibtdetl VALUES (lr_ibtdetl.*)
		IF sqlca.sqlcode < 0 THEN
			ERROR "Problem at INSERT INTO ibtdetl"
			ROLLBACK WORK
			RETURN -1
		END IF
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	
		
	END FOR
		
{
		FOREACH crs_all_t_ibtdetl INTO lr_ibtdetl.* 
		-- WHILE crs_all_t_ibtdetl.FetchNext() = 0			# seems to be a problem with CURSOR as variable
			--CALL crs_all_t_ibtdetl.SetResults( lr_ibtdetl.* )
			SELECT stk_sel_con_qty INTO lr_stk_sel_con_qty 
			FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = lr_ibtdetl.part_code 
			LET lr_line_num = lr_line_num + 1 
			LET lr_ibtdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET lr_ibtdetl.trans_num = mr_ibthead.trans_num 
			LET lr_ibtdetl.line_num = lr_line_num 
			LET lr_ibtdetl.rec_qty = lr_ibtdetl.rec_qty * lr_stk_sel_con_qty 
			LET lr_ibtdetl.trf_qty = lr_ibtdetl.trf_qty * lr_stk_sel_con_qty 
			LET lr_ibtdetl.rec_qty = lr_ibtdetl.trf_qty 
			LET lr_ibtdetl.back_qty = 0 
			WHENEVER SQLERROR CONTINUE
			INSERT INTO ibtdetl VALUES (lr_ibtdetl.*)
			IF sqlca.sqlcode < 0 THEN
				ERROR "Problem at INSERT INTO ibtdetl"
				ROLLBACK WORK
				RETURN -1
			END IF
			WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
			 
		--END WHILE 		# crs_all_t_ibtdetl
		END FOREACH
		--CALL crs_all_t_ibtdetl.Close()
 }
		LET mr_ibthead.rev_num = mr_ibthead.rev_num + 1 
		LET mr_ibthead.status_ind = IBTHEAD_STATUS_IND_TRANSFER_COMPLETED_C 
		
		WHENEVER SQLERROR CONTINUE
		UPDATE ibthead 
		SET * = mr_ibthead.* 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND trans_num = mr_ibthead.trans_num
		IF sqlca.sqlcode < 0 THEN
			ERROR "Problem at UPDATE ibthead"
			ROLLBACK WORK
			RETURN -1
		END IF
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
		
		LET m_arr_cnt = l_line_num 
		### Modify Prodstatus ####

		--DECLARE c2_inparms CURSOR FOR 
		SELECT * INTO mr_inparms.* 
		FROM inparms 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND parm_code = "1" 
		--FOR UPDATE 
		--OPEN c2_inparms 
		--FETCH c2_inparms INTO mr_inparms.* 
		FOR i = 1 TO ma_prodledg.GetSize() 
			CALL update_prodstatus(ma_prodledg[i].part_code, ma_prodledg[i].sell_tran_qty) 
			RETURNING ls_prodledg.*, l_serial_flag 
			LET ma_prledger[i].* = ls_prodledg.* 
			IF l_serial_flag = "Y" THEN 
				LET err_message = "I51a - Imm serial_update " 
				LET lr_serialinfo.cmpy_code = ls_prodledg.cmpy_code 
				LET lr_serialinfo.part_code = ls_prodledg.part_code 
				LET lr_serialinfo.ware_code = ls_prodledg.ware_code 
				LET lr_serialinfo.ref_num = ls_prodledg.source_num 
				LET lr_serialinfo.trantype_ind = '0' 
				LET status = serial_update(lr_serialinfo.*, 
				ls_prodledg.tran_qty,'') 
				IF status <> 0 THEN 
					--GOTO recovery 
					EXIT program 
				END IF 
			END IF 
		END FOR 
	--COMMIT WORK 

	RETURN ls_prodledg.source_num 
END FUNCTION #immediate_transfer 


FUNCTION update_prodstatus(l_part_code,l_sell_tran_qty) 
	DEFINE 
	l_part_code LIKE prodledg.part_code, 
	l_sell_tran_qty LIKE prodledg.tran_qty, 
	ls_prodleg RECORD LIKE prodledg.*, 
	lr_src_prodstatus RECORD LIKE prodstatus.*, 
	lr_dst_prodstatus RECORD LIKE prodstatus.*, 
	lr_product RECORD LIKE product.*, 
	l_src_ware_code LIKE prodstatus.ware_code,
	lr_temp_text STRING,
	lr_dest_mask_code LIKE warehouse.acct_mask_code 

	### Source Warehouse
	--DECLARE c2_prodstatus CURSOR FOR 
	SELECT * INTO lr_src_prodstatus.*
	FROM prodstatus 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ware_code = l_src_ware_code 
	AND part_code = l_part_code 
	--FOR UPDATE 
	--OPEN c2_prodstatus 
	--FETCH c2_prodstatus INTO lr_src_prodstatus.* 
	
	LET lr_src_prodstatus.seq_num = lr_src_prodstatus.seq_num + 1 
	IF lr_src_prodstatus.stocked_flag = "Y" THEN 
		LET lr_src_prodstatus.onhand_qty = lr_src_prodstatus.onhand_qty 
		- l_sell_tran_qty 
	ELSE 
		LET lr_src_prodstatus.onhand_qty = 0 
	END IF 
	LET lr_temp_text = "I25 - Product Ledger Entry" 
	INITIALIZE ls_prodleg.* TO NULL 
	LET ls_prodleg.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET ls_prodleg.part_code = l_part_code 
	
	SELECT * INTO lr_product.* 
	FROM product 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = ls_prodleg.part_code 
	
	## The destination warehouse IS held in mr_prodledg.source_text.
	## ??? or is it in the prodstatus record ??????
	## Both prodledg entries will contain the destination warehouse
	## adjustment account, as OTHERWISE the two entries do NOT CLEAR
	## through the GL WHEN the transfer IS complete.  Any missing stock
	## IS deemed TO be an adjustment TO the destinaton warehouse only.
	## Refer TO ISP FOR posting rules.
	
	SELECT acct_mask_code INTO lr_dest_mask_code 
	FROM warehouse 
	WHERE ware_code = mr_prodledg.source_text  
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	
	SELECT adj_acct_code INTO mr_prodledg.acct_code 
	FROM category 
	WHERE cat_code = lr_product.cat_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	
	IF sqlca.sqlcode = notfound THEN
		ERROR "No budget created for that category, please check with your accountant"
		ROLLBACK WORK
	END IF
	
	LET ls_prodleg.acct_code = build_mask(glob_rec_kandoouser.cmpy_code,lr_dest_mask_code,mr_prodledg.acct_code) 
	LET ls_prodleg.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET ls_prodleg.part_code = l_part_code
	LET ls_prodleg.ware_code = mr_prodledg.ware_code 
	LET ls_prodleg.tran_date = mr_prodledg.tran_date 
	LET ls_prodleg.seq_num = lr_src_prodstatus.seq_num 
	LET ls_prodleg.trantype_ind = "T" 
	LET ls_prodleg.year_num = mr_prodledg.year_num 
	LET ls_prodleg.period_num = mr_prodledg.period_num 
	LET ls_prodleg.desc_text = mr_prodledg.desc_text 
	LET ls_prodleg.source_text = mr_prodledg.source_text 
	LET ls_prodleg.source_num = mr_ibthead.trans_num 
	LET ls_prodleg.tran_qty = 0 - l_sell_tran_qty 
	LET ls_prodleg.bal_amt = lr_src_prodstatus.onhand_qty 
	LET ls_prodleg.cost_amt = lr_src_prodstatus.wgted_cost_amt 
	LET ls_prodleg.sales_amt = 0 
	IF mr_inparms.hist_flag = "Y" THEN 
		LET ls_prodleg.hist_flag = "N" 
	ELSE 
		LET ls_prodleg.hist_flag = "Y" 
	END IF 
	LET ls_prodleg.post_flag = "N" 
	LET ls_prodleg.entry_code = glob_rec_kandoouser.sign_on_code 
	LET ls_prodleg.entry_date = today 
	
	INSERT INTO prodledg VALUES (ls_prodleg.*) 
	
	UPDATE prodstatus 
	SET seq_num = lr_src_prodstatus.seq_num, 
		onhand_qty = lr_src_prodstatus.onhand_qty
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = lr_src_prodstatus.part_code 
		AND ware_code = lr_src_prodstatus.ware_code 
	### Destination Warehouse
	
	-- DECLARE c3_prodstatus CURSOR FOR 
	SELECT * INTO lr_dst_prodstatus.*
	FROM prodstatus 
	WHERE prodstatus.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = l_part_code 
	AND ware_code = mr_prodledg.source_text 
	--FOR UPDATE 
	--OPEN c3_prodstatus 
	--FETCH c3_prodstatus INTO lr_dst_prodstatus.* 
	IF lr_dst_prodstatus.wgted_cost_amt IS NULL THEN 
		LET lr_dst_prodstatus.wgted_cost_amt = 0 
	END IF 
	IF lr_dst_prodstatus.act_cost_amt IS NULL THEN 
		LET lr_dst_prodstatus.act_cost_amt = 0 
	END IF 
	IF lr_dst_prodstatus.onhand_qty > 0 THEN 
		IF (l_sell_tran_qty + lr_dst_prodstatus.onhand_qty) = 0 THEN 
			LET lr_dst_prodstatus.wgted_cost_amt = 0 
		ELSE 
			LET lr_dst_prodstatus.wgted_cost_amt = 
			((lr_dst_prodstatus.wgted_cost_amt * lr_dst_prodstatus.onhand_qty) 
			+(l_sell_tran_qty * lr_src_prodstatus.wgted_cost_amt)) 
			/(l_sell_tran_qty + lr_dst_prodstatus.onhand_qty) 
		END IF 
	ELSE 
		LET lr_dst_prodstatus.wgted_cost_amt = lr_src_prodstatus.wgted_cost_amt 
	END IF 
	LET lr_dst_prodstatus.seq_num = lr_dst_prodstatus.seq_num + 1 
	INITIALIZE ls_prodleg.* TO NULL 
	LET ls_prodleg.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET ls_prodleg.part_code = l_part_code 
	LET ls_prodleg.ware_code = mr_prodledg.source_text 
	LET ls_prodleg.tran_date = mr_prodledg.tran_date 
	LET ls_prodleg.seq_num = lr_dst_prodstatus.seq_num 
	LET ls_prodleg.trantype_ind = "T" 
	LET ls_prodleg.acct_code = build_mask(glob_rec_kandoouser.cmpy_code,lr_dest_mask_code,	mr_prodledg.acct_code) 
	LET ls_prodleg.year_num = mr_prodledg.year_num 
	LET ls_prodleg.period_num = mr_prodledg.period_num 
	LET ls_prodleg.desc_text = mr_prodledg.desc_text 
	LET ls_prodleg.source_text = mr_prodledg.ware_code 
	LET ls_prodleg.source_num = mr_ibthead.trans_num ####
 	# we lost source_num in ls_prodleg
	LET ls_prodleg.tran_qty = l_sell_tran_qty 
	LET ls_prodleg.bal_amt = lr_dst_prodstatus.onhand_qty 
	+ l_sell_tran_qty 
	LET ls_prodleg.cost_amt = lr_src_prodstatus.wgted_cost_amt 
	LET ls_prodleg.sales_amt = 0 
	IF mr_inparms.hist_flag = "Y" THEN 
		LET ls_prodleg.hist_flag = "N" 
	ELSE 
		LET ls_prodleg.hist_flag = "Y" 
	END IF 
	LET ls_prodleg.post_flag = "N" 
	LET ls_prodleg.entry_code = glob_rec_kandoouser.sign_on_code 
	LET ls_prodleg.entry_date = today 
	
	INSERT INTO prodledg VALUES (ls_prodleg.*) 
	
	# Update destination prodstatus	
	UPDATE prodstatus 
	SET seq_num = lr_dst_prodstatus.seq_num, 
		onhand_qty = lr_dst_prodstatus.onhand_qty + l_sell_tran_qty, 
		wgted_cost_amt = lr_dst_prodstatus.wgted_cost_amt, 
		act_cost_amt = lr_dst_prodstatus.act_cost_amt,
		last_receipt_date = ls_prodleg.tran_date  
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = lr_dst_prodstatus.part_code 
		AND ware_code = lr_dst_prodstatus.ware_code 
	
	RETURN ls_prodleg.*, lr_product.serial_flag 
END FUNCTION 		# update_prodstatus

FUNCTION print_transfer(mode)
	DEFINE mode CHAR(60) #??? a bit over the top ???
	DEFINE l_rpt_idx SMALLINT  #report array index
	DEFINE l_tmp_str STRING 
	--DEFINE rpt_wid SAMLLINT
	DEFINE i  SMALLINT 
	--rpt_note LIKE rmsreps.report_text, 
	DEFINE pr_msg CHAR(80) 
	--pr_output CHAR(60),
	DEFINE REP char(1) 
	
	#----
	#  Usage of the 'MESSAGE' statement IS required because maxms
	#  OR the DISPLAY command do NOT work IF a ring menu IS prese
	#  under 4j's charater mode
	#----
	LET msgresp = kandoomsg("W",1,"") 
	IF MODE = "ADD" THEN 
		LET pr_msg = " Stock Transfer ", 	mr_ibthead.trans_num USING "<<<<<<<<", 	" Successfully Created." 
		MESSAGE pr_msg attribute(yellow) 

		#      LET msgresp = kandoomsg("I",1045,mr_ibthead.trans_num)
		#      #1045 Stock Transfer 1234 Successfully Created.
	ELSE 
		LET pr_msg = " Stock Transfer ", 
		mr_ibthead.trans_num USING "<<<<<<<<", 
		" Successfully Updated." 
		MESSAGE pr_msg attribute(yellow) #LET msgresp = kandoomsg("I",1048,mr_ibthead.trans_num)
		#      #7046 Transfer number has been successfully updated"
	END IF 
	MENU "Print Transfer" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","I51a","menu-Print_Transfer-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null)
		
		COMMAND KEY (control-w) 
			CALL kandoohelp("") 

		COMMAND "Yes" " Print a copy of the transfer" 
--			LET rpt_pageno = 0 
--			LET rpt_note = "IN Stock Transfer - ", 
--			" FROM: ",mr_ibthead.from_ware_code, 
--			" To: ",mr_ibthead.to_ware_code

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
			LET l_tmp_str = 	" FROM: ",mr_ibthead.from_ware_code CLIPPED, " To: ",mr_ibthead.to_ware_code CLIPPED
			CALL rpt_set_header_footer_line_2_append(l_rpt_idx,"", l_tmp_str)
			 
			FOR i = 1 TO m_arr_cnt 
				SELECT unique 1 FROM ibtdetl 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND trans_num = mr_ibthead.trans_num 
				AND line_num = ma_ibtdetl_array[i].line_num 
				AND status_ind = '4' 
				
				IF sqlca.sqlcode = notfound THEN
					#---------------------------------------------------------
					OUTPUT TO REPORT AB1_rpt_list(l_rpt_idx,				 
					ma_ibtdetl_array[i].*, 
					mr_ibthead.trans_num) 
					#---------------------------------------------------------
				END IF 
			END FOR 

			#------------------------------------------------------------
			FINISH REPORT I51_rpt_list
			CALL rpt_finish("I51_rpt_list")
			#------------------------------------------------------------

			LET rep = fgl_winprompt(5,5, "There is no program to run the report", "", 50, 0)
			-- CALL run_prog("URS","","","","") -- ON ACTION "Print Manager" 
			EXIT MENU 

		COMMAND "No" "Do NOT PRINT a copy of the transfer" 
			EXIT MENU 
		
	END MENU 
	INITIALIZE mr_prodledg.* TO NULL 
	CALL ma_prodledg.Clear()
	CALL ma_prledger.Clear()
	LET m_arr_cnt = 0 
	--   CLOSE WINDOW w1   -- albo  KD-758
END FUNCTION 		# print_transfer

REPORT I51_rpt_list(p_rpt_idx,ls_ibtdetl, lv_trans_num)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	 
	DEFINE 
	lr_ibtdetl RECORD LIKE ibtdetl.*, 
	ls_ibtdetl RECORD 
		scroll_flag CHAR(1), 
		line_num LIKE ibtdetl.line_num, 
		part_code LIKE product.part_code, 
		desc_text LIKE product.desc_text, 
		trf_qty LIKE ibtdetl.trf_qty, 
		stock_uom_code LIKE product.stock_uom_code, 
		sell_tran_qty LIKE prodledg.tran_qty, 
		sell_uom_code LIKE product.stock_uom_code 
	END RECORD, 
	lv_trans_num LIKE ibthead.trans_num, 
	mr_prodledg RECORD LIKE prodledg.*, 
	mr_src_prodstatus RECORD LIKE prodstatus.*, 
	pr_src_ware, 
	pr_dest_ware RECORD LIKE warehouse.*, 
	pr_desc_text LIKE product.desc_text, 
	pr_uom_code LIKE product.sell_uom_code, 
	pr_stk_sel_con_qty LIKE product.stk_sel_con_qty, 
	pr_ware1_ad1, 
	pr_ware2_ad1, 
	pr_ware1_ad2, 
	pr_ware2_ad2, 
	pr_ware1_ad3, 
	pr_ware2_ad3 CHAR(32), 
	pr_endpage SMALLINT,
	pr_grandtot DECIMAL(16,2)

	OUTPUT 
	PAGE length 66 
	top margin 0 
	bottom margin 13 
	left margin 0 

	ORDER BY lv_trans_num, ls_ibtdetl.line_num 
	#ORDER external by lv_trans_num

	FORMAT 
		FIRST PAGE HEADER
			LET pr_grandtot = 0
		PAGE HEADER 
			LET pr_endpage = false 
			# Printer defaulted TO that used in Requisitions
			SELECT printcodes.* INTO mr_printcodes.* FROM reqparms, printcodes 
			WHERE reqparms.key_code = '1' 
			AND reqparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND printcodes.print_code = reqparms.po_print_text 
			IF sqlca.sqlcode = notfound THEN 
				INITIALIZE mr_printcodes.* TO NULL 
			END IF 

			LET rpt_pageno = pageno 
			SELECT * INTO mr_ibthead.* FROM ibthead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND trans_num = lv_trans_num 
			SELECT * INTO pr_src_ware.* FROM warehouse 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ware_code = mr_ibthead.from_ware_code 
			IF sqlca.sqlcode = notfound THEN 
				INITIALIZE pr_src_ware.* TO NULL 
			END IF 
			SELECT * INTO pr_dest_ware.* FROM warehouse 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ware_code = mr_ibthead.to_ware_code 
			IF sqlca.sqlcode = notfound THEN 
				INITIALIZE pr_dest_ware.* TO NULL 
			END IF 
			PRINT ascii(mr_printcodes.normal_1), 
			ascii(mr_printcodes.normal_2), 
			ascii(mr_printcodes.normal_3), 
			ascii(mr_printcodes.normal_4), 
			ascii(mr_printcodes.normal_5), 
			ascii(mr_printcodes.normal_6), 
			ascii(mr_printcodes.normal_7), 
			ascii(mr_printcodes.normal_8), 
			ascii(mr_printcodes.normal_9), 
			ascii(mr_printcodes.normal_10) 
			PRINT COLUMN 49,'stock transfer'; 
			PRINT ascii(mr_printcodes.compress_1), 
			ascii(mr_printcodes.compress_2), 
			ascii(mr_printcodes.compress_3), 
			ascii(mr_printcodes.compress_4), 
			ascii(mr_printcodes.compress_5), 
			ascii(mr_printcodes.compress_6), 
			ascii(mr_printcodes.compress_7), 
			ascii(mr_printcodes.compress_8), 
			ascii(mr_printcodes.compress_9), 
			ascii(mr_printcodes.compress_10) 
			SKIP 2 LINES 
			LET pr_ware1_ad1 = pr_src_ware.addr1_text clipped 
			LET pr_ware1_ad2 = pr_src_ware.addr2_text clipped 
			LET pr_ware1_ad3 = pr_src_ware.city_text 
			IF pr_ware1_ad3 IS NULL THEN 
				LET pr_ware1_ad3 = pr_src_ware.state_code 
			ELSE 
				LET pr_ware1_ad3 = pr_ware1_ad3 clipped, " ", 
				pr_src_ware.state_code clipped 
			END IF 
			IF pr_ware1_ad3 IS NULL THEN 
				LET pr_ware1_ad3 = pr_src_ware.post_code 
			ELSE 
				LET pr_ware1_ad3 = pr_ware1_ad3 clipped, " ", 
				pr_src_ware.post_code clipped, " " 
			END IF 
			IF pr_ware1_ad2 IS NULL THEN 
				LET pr_ware1_ad2 = pr_ware1_ad3 
				INITIALIZE pr_ware1_ad3 TO NULL 
			END IF 
			IF pr_ware1_ad1 IS NULL THEN 
				LET pr_ware1_ad1 = pr_ware1_ad2 
				INITIALIZE pr_ware1_ad2 TO NULL 
			END IF 
			LET pr_ware2_ad1 = pr_dest_ware.addr1_text clipped 
			LET pr_ware2_ad2 = pr_dest_ware.addr2_text clipped 
			LET pr_ware2_ad3 = pr_dest_ware.city_text 
			IF pr_ware2_ad3 IS NULL THEN 
				LET pr_ware2_ad3 = pr_dest_ware.state_code 
			ELSE 
				LET pr_ware2_ad3 = pr_ware2_ad3 clipped, " ", 
				pr_dest_ware.state_code clipped 
			END IF 
			IF pr_ware2_ad3 IS NULL THEN 
				LET pr_ware2_ad3 = pr_dest_ware.post_code 
			ELSE 
				LET pr_ware2_ad3 = pr_ware2_ad3 clipped, " ", 
				pr_dest_ware.post_code clipped, " " 
			END IF 
			IF pr_ware2_ad2 IS NULL THEN 
				LET pr_ware2_ad2 = pr_ware2_ad3 
				INITIALIZE pr_ware2_ad3 TO NULL 
			END IF 
			IF pr_ware2_ad1 IS NULL THEN 
				LET pr_ware2_ad1 = pr_ware2_ad2 
				INITIALIZE pr_ware2_ad2 TO NULL 
			END IF 
			PRINT COLUMN 16, pr_src_ware.desc_text clipped, 
			COLUMN 54, pr_dest_ware.desc_text clipped, 
			COLUMN 87, 'Number', 
			COLUMN 97, lv_trans_num USING "<<<<<<<<" 
			PRINT COLUMN 16, pr_ware1_ad1 clipped, 
			COLUMN 54, pr_ware2_ad1 clipped, 
			COLUMN 87, 'Date', 
			COLUMN 97, mr_ibthead.trans_date USING "dd-mm-yy" 
			PRINT COLUMN 16, pr_ware1_ad2 clipped, 
			COLUMN 54, pr_ware2_ad2 clipped 
			PRINT COLUMN 16, pr_ware1_ad3 clipped, 
			COLUMN 54, pr_ware2_ad3 clipped, 
			COLUMN 87, 'Ref:', 
			COLUMN 91, mr_ibthead.desc_text[1,16] clipped 
			SKIP 1 LINES 
			PRINT COLUMN 6, 'Code', 
			COLUMN 22, 'Name', 
			COLUMN 57, 'Qty' , 
			COLUMN 80, 'Cost', 
			COLUMN 92, 'Total' 
			SKIP 1 LINES 

		BEFORE GROUP OF lv_trans_num 
			SKIP TO top OF PAGE 
			#      need 63 lines

		AFTER GROUP OF lv_trans_num 
			LET pr_endpage = true 

		ON EVERY ROW 
			SELECT * INTO mr_src_prodstatus.* FROM prodstatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ware_code = mr_ibthead.from_ware_code 
			AND part_code = ls_ibtdetl.part_code 
			SELECT desc_text, 
			sell_uom_code, 
			stk_sel_con_qty 
			INTO pr_desc_text, 
			pr_uom_code, 
			pr_stk_sel_con_qty 
			FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = ls_ibtdetl.part_code 
			IF sqlca.sqlcode = notfound THEN 
				LET pr_desc_text = NULL 
				LET pr_uom_code = NULL 
			END IF 
			LET pr_grandtot = pr_grandtot 
			+ (ls_ibtdetl.trf_qty * mr_src_prodstatus.wgted_cost_amt 
			* pr_stk_sel_con_qty) 
			PRINT COLUMN 6, ls_ibtdetl.part_code, 
			COLUMN 22, pr_desc_text, 
			COLUMN 53, ls_ibtdetl.trf_qty * pr_stk_sel_con_qty USING "------&", 
			COLUMN 61, pr_uom_code, 
			COLUMN 66, mr_src_prodstatus.wgted_cost_amt, 
			COLUMN 86, ls_ibtdetl.trf_qty * mr_src_prodstatus.wgted_cost_amt 
			* pr_stk_sel_con_qty USING "-------&.&&" 
			PAGE TRAILER 
				IF pr_endpage THEN 
					PRINT COLUMN 77, 'TOTAL', 
					COLUMN 86, pr_grandtot 
					USING "---------&.&&" 
					SKIP 7 LINES 
				ELSE 
					SKIP 8 LINES 
				END IF 
				PRINT COLUMN 60, 'PRINTED', ' ', 
				today USING "dd-mm-yy", ' ', 
				time 
				PRINT ascii(mr_printcodes.normal_1), 
				ascii(mr_printcodes.normal_2), 
				ascii(mr_printcodes.normal_3), 
				ascii(mr_printcodes.normal_4), 
				ascii(mr_printcodes.normal_5), 
				ascii(mr_printcodes.normal_6), 
				ascii(mr_printcodes.normal_7), 
				ascii(mr_printcodes.normal_8), 
				ascii(mr_printcodes.normal_9), 
				ascii(mr_printcodes.normal_10) 
		ON LAST ROW 
			LET pr_endpage = true 
END REPORT 

FUNCTION stock_status(l_part_code) 
	DEFINE 
	l_part_code LIKE product.part_code, 
	lr_product RECORD LIKE product.*, 
	lr_prodstatus RECORD LIKE product.*, 
	la_prodstat array[2] OF RECORD 
		onhand_qty LIKE prodstatus.onhand_qty, 
		reserved_qty LIKE prodstatus.reserved_qty, 
		back_qty LIKE prodstatus.back_qty, 
		avail_qty LIKE prodstatus.onhand_qty 
	END RECORD, 
	l_trf_qty LIKE ibtdetl.trf_qty, 
	l_temp_text STRING 

	CLEAR sr_status[1].* 
	CLEAR sr_status[2].* 
	IF l_part_code IS NULL THEN 
		RETURN false 
	END IF 
	SELECT onhand_qty,reserved_qty,back_qty,0 
	INTO la_prodstat[1].* 
	FROM prodstatus 
	WHERE part_code = l_part_code 
	AND ware_code = mr_ibthead.from_ware_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF sqlca.sqlcode = notfound THEN 
		LET msgresp = kandoomsg("I",7035,"") 
		#7035 Product does NOT exist AT this warehouse.
		RETURN false 
	END IF 
	SELECT sum(trf_qty) INTO l_trf_qty FROM ibtdetl 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND trans_num = mr_ibthead.trans_num 
	AND part_code = l_part_code 
	IF l_trf_qty IS NULL THEN 
		LET l_trf_qty = 0 
	END IF 
	SELECT * INTO lr_product.* FROM product 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = l_part_code 
	LET la_prodstat[1].avail_qty = la_prodstat[1].onhand_qty 
	- la_prodstat[1].reserved_qty 
	- la_prodstat[1].back_qty 
	+ (l_trf_qty * lr_product.stk_sel_con_qty) 
	DISPLAY la_prodstat[1].* TO sr_status[1].* 

	IF la_prodstat[1].avail_qty <= 0 THEN 
		LET msgresp = kandoomsg("I",9112,"") 
		# I9112 Insufficient stock available
	END IF 
	SELECT onhand_qty,reserved_qty,back_qty,0 
	INTO la_prodstat[2].* 
	FROM prodstatus 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = l_part_code 
	AND ware_code = mr_ibthead.to_ware_code 
	IF sqlca.sqlcode = notfound THEN 
		--      OPEN WINDOW w1 AT 10,5 with 3 rows,70 columns  -- albo  KD-758
		--         ATTRIBUTE(border)
		MENU " Product NOT stocked AT destination warehouse" 

			BEFORE MENU 
				CALL publish_toolbar("kandoo","I51a","menu-Product_not_stocked-1") -- albo kd-505 

			ON ACTION "WEB-HELP" -- albo kd-372 
				CALL onlinehelp(getmoduleid(),null) 

			COMMAND "Image" " Image existing product stocking STATUS" 
				SELECT * INTO lr_product.* 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = l_part_code 
				LET l_temp_text = image_product(glob_rec_kandoouser.cmpy_code, lr_product.*,mr_ibthead.to_ware_code) 
				#LET l_temp_text = sim_warehouse(glob_rec_kandoouser.cmpy_code,lr_product.*,
				#mr_ibthead.to_ware_code)
				SELECT onhand_qty,reserved_qty,back_qty,0 
				INTO la_prodstat[2].* 
				FROM prodstatus 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = l_part_code 
				AND ware_code = mr_ibthead.to_ware_code 
				IF sqlca.sqlcode = 0 THEN 
					EXIT MENU 
				END IF 
			COMMAND KEY("E",interrupt)"Exit" " Re-enter destination warehouse" 
				LET quit_flag = true 
				EXIT MENU 
			COMMAND KEY (control-w) 
				CALL kandoohelp("") 
		END MENU 
		--      CLOSE WINDOW w1  -- albo  KD-758
	END IF 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN "" 
	ELSE 
		LET la_prodstat[2].avail_qty = la_prodstat[2].onhand_qty 
		- la_prodstat[2].reserved_qty 
		- la_prodstat[2].back_qty 
		DISPLAY la_prodstat[2].* TO sr_status[2].* 

	END IF 
	RETURN la_prodstat[1].avail_qty 
END FUNCTION 		# stock_status


FUNCTION insert_t_ibtdetl_line() 
	DEFINE 
	lr_ibtdetl RECORD LIKE ibtdetl.* 

	INITIALIZE lr_ibtdetl.* TO NULL 
	SELECT max(line_num) + 1 INTO lr_ibtdetl.line_num 
	FROM t_ibtdetl 
	WHERE part_code IS NOT NULL 
	IF lr_ibtdetl.line_num IS NULL THEN 
		LET lr_ibtdetl.line_num = 1 
	END IF 
	LET lr_ibtdetl.picked_qty = 0 
	LET lr_ibtdetl.sched_qty = 0 
	LET lr_ibtdetl.conf_qty = 0 
	LET lr_ibtdetl.rec_qty = 0 
	LET lr_ibtdetl.back_qty = 0 
	LET lr_ibtdetl.amend_date = NULL 
	LET lr_ibtdetl.amend_code = NULL 
	LET lr_ibtdetl.status_ind = IBTDETL_STATUS_IND_NEW_0 
	INSERT INTO t_ibtdetl VALUES (lr_ibtdetl.*) 
	LET mr_ibtdetl.* = lr_ibtdetl.* 
END FUNCTION 	# insert_t_ibtdetl_line


FUNCTION update_t_ibtdetl_line(l_line_num) 
DEFINE l_line_num LIKE ibtdetl.line_num

	IF m_mode = 'EDIT' THEN 
		LET mr_ibtdetl.amend_date = today 
		LET mr_ibtdetl.amend_code = glob_rec_kandoouser.sign_on_code 
	END IF 
	UPDATE t_ibtdetl 
	SET part_code = mr_ibtdetl.part_code, 
	trf_qty = mr_ibtdetl.trf_qty, 
	back_qty = mr_ibtdetl.back_qty 
	WHERE line_num = l_line_num
	IF sqlca.sqlerrd[3] = 0 THEN
		ERROR "Could not find A row for that line",l_line_num
	END IF
	 
END FUNCTION 	# update_t_ibtdetl_line


# This function clones a product from one warehouse to another warehouse
FUNCTION image_product(p_cmpy, lr_product, lr_ware_code) 
	DEFINE 
	p_cmpy LIKE company.cmpy_code, 
	lr_product RECORD LIKE product.*, 
	lp_product RECORD LIKE product.*, 
	lr_ware_code LIKE warehouse.ware_code, 
	l_temp_text STRING, 
	l_parent_part, l_dashes, l_flex_part LIKE product.part_code, 
	parent_ind, pr_flex SMALLINT 


	IF mult_segs(p_cmpy, lr_product.class_code) THEN 
		CALL break_prod(p_cmpy,lr_product.part_code,lr_product.class_code,1) 
		RETURNING l_parent_part,l_dashes,l_flex_part,pr_flex 
		SELECT 1 
		INTO parent_ind 
		FROM prodstatus 
		WHERE cmpy_code = p_cmpy 
		AND part_code = l_parent_part 
		AND ware_code = lr_ware_code 
		IF sqlca.sqlcode = notfound THEN 
			# add parent
			SELECT * INTO lp_product.* 
			FROM product 
			WHERE cmpy_code = p_cmpy 
			AND part_code = l_parent_part 
			LET l_temp_text = sim_warehouse(p_cmpy,lp_product.*, 
			lr_ware_code) 
		END IF 
		IF l_parent_part <> lr_product.part_code THEN 
			LET l_temp_text = sim_warehouse(p_cmpy,lr_product.*, 
			lr_ware_code) 
		END IF 
	ELSE 
		LET l_temp_text = sim_warehouse(p_cmpy,lr_product.*, 
		lr_ware_code) 
	END IF 
	RETURN l_temp_text 
END FUNCTION 		# image_product


##- this function is deprecated / replaced by insert_into_transfer_lines
FUNCTION insert_into_transfer_lines_old() 
	DEFINE 
	lr_product RECORD LIKE product.*, 
	lr_prodstatus RECORD LIKE prodstatus.*, 
	ls_ibtdetl RECORD LIKE ibtdetl.*, 			# clone of , serves as a backup in case of cancel
	pr_ibtdetl RECORD LIKE ibtdetl.*, 
	pt_ibthead RECORD LIKE ibthead.*, 
	mr_src_prodstatus RECORD LIKE prodstatus.*, 
	pr_dst_prodstatus RECORD LIKE prodstatus.*, 
	pr_serialinfo RECORD LIKE serialinfo.*, 
	ps_prodledg RECORD LIKE prodledg.*, 
	pr_stk_sel_con_qty LIKE product.stk_sel_con_qty, 
	pr_serial_flag LIKE product.serial_flag, 
	pr_act_qty LIKE ibtdetl.trf_qty, 
	total_lineitems SMALLINT, 
	err_message CHAR(200), 
	pr_ibtcnt, pr_rec_cnt SMALLINT, 
	pr_line_num, i SMALLINT
	DEFINE serial_status SMALLINT 

	SELECT * INTO mr_inparms.* 
	FROM inparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 

	SELECT *  INTO pt_ibthead.*
	FROM ibthead 
	WHERE trans_num = mr_ibthead.trans_num 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
 
	IF m_mode = "EDIT" THEN 
		IF pt_ibthead.rev_num != mr_ibthead.rev_num THEN 
			LET msgresp = kandoomsg("W",7026,"") 
			#7026 Another user has edited this ORDER - Changes NOT saved
			LET err_message = "I51a - Another user has modified transfer" 
			ROLLBACK WORK 
			RETURN false 
		END IF 
	END IF 
	LET total_lineitems = 0 

	IF m_mode = "EDIT" THEN 
		LET mr_ibthead.amend_code = glob_rec_kandoouser.sign_on_code 
		LET mr_ibthead.amend_date = today 

		LET err_message = "I51a - Locking Transfer Records" 
		# Gosh!!!!! they are locked already   ericv 2020 06 25		

		CALL c1_ibtdetl.SetParameters(glob_rec_kandoouser.cmpy_code,mr_ibthead.trans_num)
		CALL c1_ibtdetl.open()							#  
		WHILE  c1_ibtdetl.fetchNext() = 0
			CALL c1_ibtdetl.SetResults(pr_ibtdetl.*) 
			LET total_lineitems = total_lineitems + 1 
			
			SELECT * INTO ls_ibtdetl.* 
			FROM t_ibtdetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND trans_num = pr_ibtdetl.trans_num 
			AND line_num = pr_ibtdetl.line_num 
			AND part_code IS NOT NULL 
			
			SELECT * INTO lr_product.* 
			FROM product 
			WHERE part_code = ls_ibtdetl.part_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			
			LET ls_ibtdetl.conf_qty = ls_ibtdetl.conf_qty 
			* lr_product.stk_sel_con_qty 
			LET ls_ibtdetl.picked_qty = ls_ibtdetl.picked_qty 
			* lr_product.stk_sel_con_qty 
			LET ls_ibtdetl.sched_qty = ls_ibtdetl.sched_qty 
			* lr_product.stk_sel_con_qty 
			IF sqlca.sqlcode = notfound THEN 
				LET err_message = "I51a - Lines have changed during Edit" 
				--GOTO recovery 
			END IF 
			IF pr_ibtdetl.conf_qty != ls_ibtdetl.conf_qty 
			OR pr_ibtdetl.picked_qty != ls_ibtdetl.picked_qty THEN 
				LET err_message = "Docket OR Invoice generated during Edit" 
				--GOTO recovery 
			END IF 
			IF pr_ibtdetl.sched_qty != ls_ibtdetl.sched_qty THEN 
				LET err_message = "Order has been scheduled during edit" 
				--GOTO recovery 
			END IF 

			LET err_message = "I51a - Backorder setup - remove back_qty" 
			UPDATE prodstatus 
			SET back_qty = back_qty - pr_ibtdetl.back_qty 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = mr_ibthead.from_ware_code 
				AND part_code = pr_ibtdetl.part_code 
				 
		END WHILE   # FetchNext c1_ibtdetl
		CALL c1_ibtdetl.Close()							# 
	END IF 
	
	LET pr_line_num = 0 
	--CALL crs_all_t_ibtdetl.open()
	
	--WHILE crs_all_t_ibtdetl.FetchNext() = 0
		--CALL crs_all_t_ibtdetl.SetResults( pr_ibtdetl.* )
	FOREACH crs_all_t_ibtdetl INTO pr_ibtdetl.*  
		SELECT stk_sel_con_qty, serial_flag 
		INTO pr_stk_sel_con_qty, pr_serial_flag 
		FROM product 
		WHERE part_code = pr_ibtdetl.part_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		
		SELECT * INTO lr_prodstatus.* 
		FROM prodstatus 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND ware_code = mr_ibthead.from_ware_code 
		AND part_code = pr_ibtdetl.part_code 

		IF pr_ibtdetl.status_ind = IBTDETL_STATUS_IND_CANCELED_4 THEN 
			LET err_message = "I51a - Cancel Transfer " 
			SELECT unique 1 
			FROM ibtdetl 
			WHERE trans_num = pr_ibtdetl.trans_num 
			AND line_num = pr_ibtdetl.line_num 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF sqlca.sqlcode = notfound THEN 
				--CONTINUE WHILE
				CONTINUE FOREACH 
			ELSE 
				IF pr_ibtdetl.conf_qty > 0 THEN 
					LET mr_prodledg.ware_code = mr_ibthead.from_ware_code 
					LET mr_prodledg.source_text = mr_inparms.ibt_ware_code 
					LET mr_prodledg.tran_date = mr_ibthead.trans_date 
					LET mr_prodledg.year_num = mr_ibthead.year_num 
					LET mr_prodledg.period_num = mr_ibthead.period_num 
					LET mr_prodledg.desc_text = mr_ibthead.desc_text 
					CALL update_prodstatus(pr_ibtdetl.part_code,( -1 * pr_ibtdetl.conf_qty) ) 
					RETURNING ps_prodledg.*, pr_serial_flag 
					
					UPDATE ibtload SET load_qty = rec_qty 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND trans_num = pr_ibtdetl.trans_num 
						AND line_num = pr_ibtdetl.line_num 
					LET pr_ibtdetl.conf_qty = 0 
				END IF 
			END IF 
		END IF 

		LET pr_line_num = pr_line_num + 1 
		LET pr_ibtdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pr_ibtdetl.trans_num = mr_ibthead.trans_num 
		LET pr_ibtdetl.line_num = pr_line_num 
		LET pr_ibtdetl.sched_qty = pr_ibtdetl.sched_qty * pr_stk_sel_con_qty 
		LET pr_ibtdetl.picked_qty = pr_ibtdetl.picked_qty * pr_stk_sel_con_qty 
		LET pr_ibtdetl.rec_qty = pr_ibtdetl.rec_qty * pr_stk_sel_con_qty 
		LET pr_ibtdetl.conf_qty = pr_ibtdetl.conf_qty * pr_stk_sel_con_qty 
		LET pr_ibtdetl.trf_qty = pr_ibtdetl.trf_qty * pr_stk_sel_con_qty 
		LET pr_ibtdetl.back_qty = pr_ibtdetl.back_qty * pr_stk_sel_con_qty 
		IF pr_ibtdetl.line_num > total_lineitems THEN 
			INSERT INTO ibtdetl VALUES (pr_ibtdetl.*) 
			--DELETE FROM t_ibtdetl
			--WHERE line_num = pr_ibtdetl.line_num
		ELSE 
			LET pr_ibtdetl.amend_code = glob_rec_kandoouser.sign_on_code 
			LET pr_ibtdetl.amend_date = today 
			UPDATE ibtdetl 
			SET * = pr_ibtdetl.* 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND trans_num = mr_ibthead.trans_num 
			AND line_num = pr_ibtdetl.line_num 
			DELETE FROM t_ibtdetl
			WHERE line_num = pr_ibtdetl.line_num
		END IF 
		
		UPDATE prodstatus 
		SET back_qty = back_qty + pr_ibtdetl.back_qty 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND ware_code = mr_ibthead.from_ware_code 
		AND part_code = pr_ibtdetl.part_code 

		IF pr_serial_flag = "Y" THEN 
			IF pr_ibtdetl.status_ind = IBTDETL_STATUS_IND_CANCELED_4 THEN 
				CALL serial_delete(pr_ibtdetl.part_code,mr_ibthead.from_ware_code) 
				LET status = serial_return(pr_ibtdetl.part_code,"0") 
			ELSE 
				LET pr_act_qty = ( pr_ibtdetl.trf_qty 
				- pr_ibtdetl.sched_qty 
				- pr_ibtdetl.picked_qty 
				- pr_ibtdetl.conf_qty 
				- pr_ibtdetl.rec_qty ) 
				/ pr_stk_sel_con_qty 
				IF pr_act_qty IS NULL THEN 
					LET pr_act_qty = 0 
				END IF 
				LET err_message = "I51a - Save serial_update " 
				LET pr_serialinfo.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET pr_serialinfo.part_code = pr_ibtdetl.part_code 
				LET pr_serialinfo.ware_code = mr_ibthead.from_ware_code 
				LET pr_serialinfo.ref_num = mr_ibthead.trans_num 
				LET pr_serialinfo.trans_num = mr_ibthead.trans_num 
				LET pr_serialinfo.trantype_ind = 'T' 
				LET serial_status = serial_update(pr_serialinfo.*, pr_act_qty,'0') 
				IF serial_status <> 0 THEN
					ERROR "Houston we have a problem" 
					--GOTO recovery 
				END IF 
			END IF 
		END IF 
	--END WHILE   # crs_all_t_ibtdetl
	--CALL crs_all_t_ibtdetl.Close()
	END FOREACH
	CLOSE crs_all_t_ibtdetl

	SELECT count(*) INTO pr_ibtcnt 
	FROM t_ibtdetl 
	WHERE status_ind = "4" 

	# Watch out: Status_ind goes "R" depending on t_ibtdetl ?
	
	SELECT count(*) INTO pr_rec_cnt 
	FROM t_ibtdetl 
	IF pr_ibtcnt = pr_rec_cnt THEN 
		DECLARE c_ibtdetl_ser CURSOR FOR 
		SELECT * FROM t_ibtdetl 
		FOREACH c_ibtdetl_ser INTO pr_ibtdetl.* 
			CALL serial_delete(pr_ibtdetl.part_code, 
			mr_ibthead.from_ware_code) 
		END FOREACH 
		LET status = serial_return("","0") 
		LET mr_ibthead.status_ind = IBTHEAD_STATUS_IND_TRANSFER_CANCELLED_R 
	ELSE 
		SELECT count(*) INTO pr_ibtcnt 
		FROM t_ibtdetl 
		WHERE (conf_qty + rec_qty) < trf_qty 
		AND status_ind <> "4" 
		IF pr_ibtcnt = 0 THEN 
			SELECT count(*) INTO pr_rec_cnt 
			FROM t_ibtdetl 
			WHERE rec_qty < trf_qty 
			AND status_ind <> "4" 
			IF pr_rec_cnt = 0 THEN 
				LET mr_ibthead.status_ind = IBTHEAD_STATUS_IND_TRANSFER_COMPLETED_C 
			ELSE 
				LET mr_ibthead.status_ind = IBTHEAD_STATUS_IND_TRANSFER_PARTIALLY_COMPLETED_P 
			END IF 
		ELSE 
			SELECT count(*) INTO pr_ibtcnt 
			FROM t_ibtdetl 
			WHERE (conf_qty + rec_qty) != 0 
			AND status_ind <> "4" 
			IF pr_ibtcnt = 0 THEN 
				LET mr_ibthead.status_ind = IBTHEAD_STATUS_IND_TRANSFER_UNDELIVERED_U 
			ELSE 
				LET mr_ibthead.status_ind = IBTHEAD_STATUS_IND_TRANSFER_PARTIALLY_COMPLETED_P 
			END IF 
		END IF 
	END IF 
	LET mr_ibthead.rev_num = mr_ibthead.rev_num + 1 
	IF mr_ibthead.sched_ind = "0" THEN 
		LET mr_ibthead.status_ind = IBTHEAD_STATUS_IND_TRANSFER_COMPLETED_C 
	END IF 
	UPDATE ibthead 
	SET * = mr_ibthead.* 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND trans_num = mr_ibthead.trans_num 

	IF pr_ibtcnt > 0 THEN 
		 # put a cursor variable here
		CALL serial_init(glob_rec_kandoouser.cmpy_code, "t", "0", mr_ibthead.trans_num) 
		DECLARE c_ibtdetl_ser2 CURSOR FOR 
		SELECT part_code FROM t_ibtdetl 
		WHERE status_ind = '4' 
		FOREACH c_ibtdetl_ser2 INTO pr_ibtdetl.part_code 
			CALL serial_delete(pr_ibtdetl.part_code, 
			mr_ibthead.from_ware_code) 
		END FOREACH 
		LET serial_status = serial_return("","0") 
	END IF 
	--COMMIT WORK 
	--WHENEVER ERROR stop 
	-- LET m_arr_cnt = pr_line_num
	LET m_arr_cnt = pr_ibtcnt 
	RETURN true 
END FUNCTION 		# insert_into_transfer_lines_old
