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

	Source code beautified by beautify.pl on 2020-01-03 09:12:27	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 
GLOBALS "I51_GLOBALS.4gl" 
# I57.4gl - Edit Stock Transfers

#### Module scope variables
DEFINE 	pr_mode CHAR(10) 
DEFINE	pr_sched_ind CHAR(1)
DEFINE	pr_inparms RECORD LIKE inparms.*
DEFINE pr_ibthead RECORD LIKE ibthead.*
DEFINE pr_ibtdetl RECORD LIKE ibtdetl.*
DEFINE pr_prodledg RECORD LIKE prodledg.* 

# Module scope cursors
DEFINE crs_check_ibtdetl CURSOR


####################################################################
# MAIN
####################################################################
MAIN 
	DEFINE pr_req_num INTEGER
	DEFINE records_number INTEGER
	DEFINE query_statement STRING
	DEFINE l_status INTEGER
	DEFINE lt_ibthead RECORD LIKE ibthead.*
	#Initial UI Init
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	CALL setModuleId("I57") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 

	LET pr_mode = "EDIT" 
	LET pr_sched_ind = NULL 
	CALL create_table("ibtdetl","t_ibtdetl","","N") 
	IF num_args() > 0 THEN 
		LET pr_req_num = arg_val(1)
		
		# First fill the temp table with curring transfers
		LET records_number = fill_t_ibtdetl(pr_req_num)
 
		OPEN WINDOW i669 with FORM "I669" 
		 CALL windecoration_i("I669") -- albo kd-758 
		CALL stock_transfer_header_entry ("EDIT",pr_ibthead.*) RETURNING l_status
		IF l_status THEN
			CALL product_lines_entry ("EDIT",pr_ibthead.trans_num) RETURNING l_status
			IF l_status THEN
				LET lt_ibthead.* = pr_ibthead.*  
			END IF 
		END IF 

		# ericv 20210308 enter_ware() replaced by stock_transfer_header_entry
		# line_entry replaced by product_lines_entry
		CALL stock_transfer_header_entry("EDIT",pr_ibthead.*) RETURNING l_status
		CLOSE WINDOW i669 
		EXIT program 
	END IF 
	OPEN WINDOW i668 with FORM "I668" 
	 CALL windecoration_i("I668") -- albo kd-758 
	WHILE true
		LET query_statement = select_orders() 
		CALL scan_orders(query_statement) 
	END WHILE 
	CLOSE WINDOW i668 
END MAIN 

FUNCTION fill_t_ibtdetl(lr_req_num)
DEFINE lr_req_num INTEGER
DEFINE l_stk_sel_con_qty INTEGER
DEFINE l_records_number SMALLINT
	INITIALIZE pr_ibthead.* TO NULL 
		 
	SELECT * INTO pr_ibthead.* FROM ibthead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND trans_num = pr_req_num 
	IF sqlca.sqlcode = notfound THEN 
		EXIT program 
	END IF 

	DECLARE c_ibtdetl CURSOR FOR 
	SELECT * FROM ibtdetl 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND trans_num = pr_ibthead.trans_num
	 
	FOREACH c_ibtdetl INTO pr_ibtdetl.* 
		SELECT stk_sel_con_qty INTO l_stk_sel_con_qty FROM product 
		WHERE part_code = pr_ibtdetl.part_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pr_ibtdetl.trf_qty = pr_ibtdetl.trf_qty / l_stk_sel_con_qty 
		LET pr_ibtdetl.back_qty = pr_ibtdetl.back_qty 
		/ l_stk_sel_con_qty 
		LET pr_ibtdetl.conf_qty = pr_ibtdetl.conf_qty 
		/ l_stk_sel_con_qty 
		LET pr_ibtdetl.rec_qty = pr_ibtdetl.rec_qty / l_stk_sel_con_qty 
		LET pr_ibtdetl.sched_qty = pr_ibtdetl.sched_qty 
		/ l_stk_sel_con_qty 
		LET pr_ibtdetl.picked_qty = pr_ibtdetl.picked_qty 
		/ l_stk_sel_con_qty 
		
		WHENEVER SQLERROR CONTINUE
		INSERT INTO t_ibtdetl VALUES (pr_ibtdetl.*)
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 
		IF sqlca.sqlcode = 0 THEN
			LET l_records_number =  l_records_number + 1
		ELSE
			ERROR "Could not insert row into t_ibtdetl"
		END IF
	END FOREACH
	RETURN l_records_number
END FUNCTION 		# fill_t_ibtdetl

FUNCTION select_orders() 
	DEFINE query_text STRING
	DEFINE 	where_text STRING 

	CLEAR FORM 
	LET msgresp = kandoomsg("U",1001,"") 
	#1054 Enter Selection Criteria - ESC TO Continue
	CONSTRUCT BY NAME where_text ON trans_num, 
	from_ware_code, 
	to_ware_code, 
	desc_text, 
	trans_date, 
	status_ind 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","I57","construct-trans_num-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	LET query_text = "SELECT ibthead.* FROM ibthead ", 
	"WHERE ibthead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND ibthead.status_ind != '", IBTHEAD_STATUS_IND_TRANSFER_CANCELLED_R, "' ", #IBTHEAD_STATUS_IND_TRANSFER_CANCELLED_R
	"AND ibthead.status_ind != '", IBTHEAD_STATUS_IND_TRANSFER_COMPLETED_C, "' ", #IBTHEAD_STATUS_IND_TRANSFER_COMPLETED_C
	"AND ",where_text clipped," ", 
	"ORDER BY from_ware_code,to_ware_code,trans_num desc" 
	--RETURN true
	RETURN query_text 
END FUNCTION 	# select_orders


FUNCTION scan_orders(query_text) 
##- this function lists the transfer headers that match the query received as inbound parameter
	DEFINE query_text STRING
	DEFINE
	l_scroll_flag CHAR(1), 
	la_ibthead DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		trans_num LIKE ibthead.trans_num, 
		from_ware_code LIKE ibthead.from_ware_code, 
		to_ware_code LIKE ibthead.to_ware_code, 
		desc_text LIKE ibthead.desc_text, 
		trans_date LIKE ibthead.trans_date, 
		status_ind LIKE ibthead.status_ind 
	END RECORD, 
	lt_ibthead RECORD LIKE ibthead.*, 
	lr_ibtdetl RECORD LIKE ibtdetl.*, 
	del_cnt,i,j,idx,scrn SMALLINT 
	DEFINE l_stk_sel_con_qty INTEGER
	DEFINE l_status INTEGER

	LET msgresp = kandoomsg("U",1002,"") 
	#1002  Searching database - please wait
 
	OPTIONS SQL interrupt ON 
	PREPARE s_ibthead FROM query_text 
	DECLARE crs_scan_ibthead CURSOR FOR s_ibthead 
	LET idx = 0 
	CALL la_ibthead.Clear()
	FOREACH crs_scan_ibthead INTO pr_ibthead.* 
		LET idx = idx + 1 
		LET la_ibthead[idx].scroll_flag = NULL 
		LET la_ibthead[idx].trans_num = pr_ibthead.trans_num 
		LET la_ibthead[idx].from_ware_code = pr_ibthead.from_ware_code 
		LET la_ibthead[idx].to_ware_code = pr_ibthead.to_ware_code 
		LET la_ibthead[idx].desc_text = pr_ibthead.desc_text 
		LET la_ibthead[idx].trans_date = pr_ibthead.trans_date 
		LET la_ibthead[idx].status_ind = pr_ibthead.status_ind  
	END FOREACH 
	OPTIONS SQL interrupt off 
	##- Cursor must be closed because this function is in a loop
	CLOSE crs_scan_ibthead
	FREE crs_scan_ibthead
	 
	LET msgresp = kandoomsg("U",9113,idx) 
	#9113 idx records selected
	
	IF idx = 0 THEN 
		CALL la_ibthead.Clear() 
	END IF 
	--OPTIONS DELETE KEY f36, 
	--INSERT KEY f36 
	--CALL set_count(idx) 
	LET msgresp = kandoomsg("W",1154,"") 
	#1154 F1 TO Add - F2 TO cancel - RETURN on line TO Edit
	INPUT ARRAY la_ibthead WITHOUT DEFAULTS FROM sr_ibthead.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","I57","input-la_ibthead-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION ("Add Transfer") 
			CALL run_prog ("I51","","","","") 

		ON ACTION ("Edit Transfer")
			INITIALIZE pr_ibthead.* TO NULL 
			SELECT * INTO pr_ibthead.* 
			FROM ibthead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND trans_num = la_ibthead[idx].trans_num 
			
			DECLARE c2_ibtdetl CURSOR FOR 
			SELECT * FROM ibtdetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND trans_num = pr_ibthead.trans_num 
			
			FOREACH c2_ibtdetl INTO lr_ibtdetl.* 
				SELECT stk_sel_con_qty INTO l_stk_sel_con_qty 
				FROM product 
				WHERE part_code = lr_ibtdetl.part_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET lr_ibtdetl.trf_qty = lr_ibtdetl.trf_qty / l_stk_sel_con_qty 
				LET lr_ibtdetl.back_qty = lr_ibtdetl.back_qty 
				/ l_stk_sel_con_qty 
				LET lr_ibtdetl.conf_qty = lr_ibtdetl.conf_qty 
				/ l_stk_sel_con_qty 
				LET lr_ibtdetl.rec_qty = lr_ibtdetl.rec_qty / l_stk_sel_con_qty 
				LET lr_ibtdetl.sched_qty = lr_ibtdetl.sched_qty 
				/ l_stk_sel_con_qty 
				LET lr_ibtdetl.picked_qty = lr_ibtdetl.picked_qty 
				/ l_stk_sel_con_qty 
				INSERT INTO t_ibtdetl VALUES (lr_ibtdetl.*) 
			END FOREACH 
			LET lt_ibthead.* = pr_ibthead.* 
			OPEN WINDOW i669 with FORM "I669" 
			 CALL windecoration_i("I669") -- albo kd-758 
			--WHILE enter_ware()
			CALL stock_transfer_header_entry ("EDIT",pr_ibthead.*) RETURNING l_status
			IF l_status THEN
				CALL product_lines_entry ("EDIT",pr_ibthead.trans_num) RETURNING l_status
				IF l_status THEN
					LET lt_ibthead.* = pr_ibthead.*  
				END IF 
			END IF 
			CLOSE WINDOW i669 
			DELETE FROM t_ibtdetl 
			LET pr_ibthead.* = lt_ibthead.* 
			LET la_ibthead[idx].status_ind = pr_ibthead.status_ind 
			--OPTIONS DELETE KEY f36, 
			--INSERT KEY f36 
			NEXT FIELD scroll_flag
					
		ON ACTION ("Cancel Transfer") 
			IF la_ibthead[idx].trans_num IS NULL 
			OR la_ibthead[idx].status_ind = "C" 
			OR la_ibthead[idx].status_ind = "R" THEN 
			ELSE 
				IF la_ibthead[idx].scroll_flag IS NULL THEN
					# maybe could be transformed to 1 select sum(sched_qty),picked_qty,conf_qty
					# instead of 3 selects
					# ericv 2020-07-16
					SELECT unique 1 
					FROM ibtdetl 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND trans_num = la_ibthead[idx].trans_num 
						AND sched_qty > 0 
					IF sqlca.sqlcode!= notfound THEN 
						LET msgresp = kandoomsg("W",9462,"") 
						#9462 Loads exist FOR this tranfer - Cannot Cancel"
						NEXT FIELD scroll_flag 
					END IF 
					
					SELECT unique 1 
					FROM ibtdetl 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND trans_num = la_ibthead[idx].trans_num 
					AND picked_qty > 0 
					IF sqlca.sqlcode!= notfound THEN 
						LET msgresp = kandoomsg("W",9463,"") 
						#9463 Docket Printed FOR this transfer - Cannot Cancel"
						NEXT FIELD scroll_flag 
					END IF 
					
					SELECT unique 1 
					FROM ibtdetl 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND trans_num = la_ibthead[idx].trans_num 
					AND conf_qty > 0 
					IF sqlca.sqlcode!= notfound THEN 
						LET msgresp = kandoomsg("I",8050,"") 
						#8050 This Product has confirmed lines against it
						IF msgresp = 'N' THEN 
							NEXT FIELD scroll_flag 
						END IF 
					END IF 
					LET la_ibthead[idx].scroll_flag = "*" 
					LET del_cnt = del_cnt + 1 
				ELSE 
					LET la_ibthead[idx].scroll_flag = NULL 
					LET del_cnt = del_cnt - 1 
				END IF 
			END IF 
			NEXT FIELD scroll_flag 
					
		BEFORE ROW
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			LET l_scroll_flag = la_ibthead[idx].scroll_flag 
			DISPLAY la_ibthead[idx].* TO sr_ibthead[scrn].*
			
			IF la_ibthead[idx].trans_num IS NULL THEN 
				NEXT FIELD scroll_flag 
			END IF 
			
			IF la_ibthead[idx].status_ind = "C" 
			OR la_ibthead[idx].status_ind = "R" 
			OR la_ibthead[idx].scroll_flag = "*" THEN
				CALL DIALOG.SetActionActive("Edit Transfer", False)
				LET msgresp = kandoomsg("W",9458,"") 
				#9458 Transfer has been cancelled OR IS marked FOR cancellation
				NEXT FIELD scroll_flag 
			ELSE 
				CALL DIALOG.SetActionActive("Edit Transfer", True)
			{
				INITIALIZE pr_ibthead.* TO NULL 
				SELECT * INTO pr_ibthead.* 
				FROM ibthead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND trans_num = la_ibthead[idx].trans_num 
				
				DECLARE c2_ibtdetl CURSOR FOR 
				SELECT * FROM ibtdetl 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND trans_num = pr_ibthead.trans_num 
				
				FOREACH c2_ibtdetl INTO lr_ibtdetl.* 
					SELECT stk_sel_con_qty INTO l_stk_sel_con_qty 
					FROM product 
					WHERE part_code = lr_ibtdetl.part_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET lr_ibtdetl.trf_qty = lr_ibtdetl.trf_qty / l_stk_sel_con_qty 
					LET lr_ibtdetl.back_qty = lr_ibtdetl.back_qty 
					/ l_stk_sel_con_qty 
					LET lr_ibtdetl.conf_qty = lr_ibtdetl.conf_qty 
					/ l_stk_sel_con_qty 
					LET lr_ibtdetl.rec_qty = lr_ibtdetl.rec_qty / l_stk_sel_con_qty 
					LET lr_ibtdetl.sched_qty = lr_ibtdetl.sched_qty 
					/ l_stk_sel_con_qty 
					LET lr_ibtdetl.picked_qty = lr_ibtdetl.picked_qty 
					/ l_stk_sel_con_qty 
					INSERT INTO t_ibtdetl VALUES (lr_ibtdetl.*) 
				END FOREACH 
				LET lt_ibthead.* = pr_ibthead.* 
				OPEN WINDOW i669 with FORM "I669" 
				 CALL windecoration_i("I669") -- albo kd-758 
				--WHILE enter_ware()
				IF stock_transfer_header_entry ("EDIT",pr_ibthead.*) THEN
					IF product_line_entry () THEN 
						LET lt_ibthead.* = pr_ibthead.*  
					END IF 
				END IF 
				CLOSE WINDOW i669 
				DELETE FROM t_ibtdetl 
				LET pr_ibthead.* = lt_ibthead.* 
				LET la_ibthead[idx].status_ind = pr_ibthead.status_ind 
				--OPTIONS DELETE KEY f36, 
				--INSERT KEY f36 
				NEXT FIELD scroll_flag
			} 
			END IF 
			

		BEFORE FIELD scroll_flag 
--			LET idx = arr_curr() 
--			LET scrn = scr_line() 
			LET l_scroll_flag = la_ibthead[idx].scroll_flag 
			DISPLAY la_ibthead[idx].* TO sr_ibthead[scrn].* 

		AFTER FIELD scroll_flag 
			LET la_ibthead[idx].scroll_flag = l_scroll_flag 
			DISPLAY la_ibthead[idx].scroll_flag TO sr_ibthead[scrn].scroll_flag 

			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF idx >= arr_count() THEN 
					LET msgresp = kandoomsg("U",9001,"") 
					#9001 There no more rows...
					NEXT FIELD scroll_flag 
				ELSE 
					IF la_ibthead[idx+1].trans_num IS NULL 
					OR arr_curr() >= arr_count() THEN 
						LET msgresp = kandoomsg("U",9001,"") 
						#9001 There no more rows...
						NEXT FIELD scroll_flag 
					END IF 
				END IF 
			END IF 
{
		BEFORE FIELD trans_num 
			IF la_ibthead[idx].trans_num IS NULL THEN 
				NEXT FIELD scroll_flag 
			END IF 
			IF la_ibthead[idx].status_ind = "C" 
			OR la_ibthead[idx].status_ind = "R" 
			OR la_ibthead[idx].scroll_flag = "*" THEN 
				LET msgresp = kandoomsg("W",9458,"") 
				#9458 Transfer has been cancelled OR IS marked FOR cancellation
				NEXT FIELD scroll_flag 
			ELSE 
				INITIALIZE pr_ibthead.* TO NULL 
				SELECT * INTO pr_ibthead.* 
				FROM ibthead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND trans_num = la_ibthead[idx].trans_num 
				
				DECLARE c2_ibtdetl CURSOR FOR 
				SELECT * FROM ibtdetl 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND trans_num = pr_ibthead.trans_num 
				
				FOREACH c2_ibtdetl INTO lr_ibtdetl.* 
					SELECT stk_sel_con_qty INTO l_stk_sel_con_qty FROM product 
					WHERE part_code = lr_ibtdetl.part_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET lr_ibtdetl.trf_qty = lr_ibtdetl.trf_qty / l_stk_sel_con_qty 
					LET lr_ibtdetl.back_qty = lr_ibtdetl.back_qty 
					/ l_stk_sel_con_qty 
					LET lr_ibtdetl.conf_qty = lr_ibtdetl.conf_qty 
					/ l_stk_sel_con_qty 
					LET lr_ibtdetl.rec_qty = lr_ibtdetl.rec_qty / l_stk_sel_con_qty 
					LET lr_ibtdetl.sched_qty = lr_ibtdetl.sched_qty 
					/ l_stk_sel_con_qty 
					LET lr_ibtdetl.picked_qty = lr_ibtdetl.picked_qty 
					/ l_stk_sel_con_qty 
					INSERT INTO t_ibtdetl VALUES (lr_ibtdetl.*) 
				END FOREACH 
				LET lt_ibthead.* = pr_ibthead.* 
				OPEN WINDOW i669 with FORM "I669" 
				 CALL windecoration_i("I669") -- albo kd-758 
				WHILE enter_ware() 
					IF line_entry() THEN 
						LET lt_ibthead.* = pr_ibthead.* 
						EXIT WHILE 
					END IF 
				END WHILE 
				CLOSE WINDOW i669 
				DELETE FROM t_ibtdetl 
				LET pr_ibthead.* = lt_ibthead.* 
				LET la_ibthead[idx].status_ind = pr_ibthead.status_ind 
				--OPTIONS DELETE KEY f36, 
				--INSERT KEY f36 
				NEXT FIELD scroll_flag 
			END IF 
}

		AFTER ROW 
			DISPLAY la_ibthead[idx].* TO sr_ibthead[scrn].* 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 
		IF del_cnt > 0 THEN 
			LET msgresp = kandoomsg("W",8067,del_cnt) 
			#8059 Confirm TO Cancel ",del_cnt," Transfer(s)? (Y/N)"
			IF msgresp = "Y" THEN 
				FOR idx = 1 TO arr_count() 
					IF la_ibthead[idx].scroll_flag = "*" THEN 
						CALL cancel_transfer(la_ibthead[idx].trans_num) 
					END IF 
				END FOR 
			END IF 
		END IF 
	END IF 
END FUNCTION     # scan_orders


FUNCTION cancel_transfer(l_trans_num) 
	DEFINE
	l_trans_num LIKE ibthead.trans_num, 
	lr_product RECORD LIKE product.*, 
	lr_prodstatus RECORD LIKE prodstatus.*, 
	ls_prodledg RECORD LIKE prodledg.*, 
	l_serial_flag LIKE product.serial_flag, 
	err_message CHAR(200) 
	DEFINE query_statement STRING
 
	BEGIN WORK
	SET ISOLATION TO REPEATABLE READ
	# Any row accessed receives a shared lock that can prevent concurrent session to update it
		
	SELECT * INTO pr_inparms.* 
	FROM inparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 
	LET err_message = "I57 - Locking Order Header Record"
	 
	--DECLARE c1_ibthead CURSOR FOR 
	SELECT * INTO pr_ibthead.*
	FROM ibthead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND trans_num = l_trans_num 
	--FOR UPDATE 
	--OPEN c1_ibthead 
	--FETCH c1_ibthead INTO pr_ibthead.* 

	LET err_message = "I57 - Serial Initializing " 
	CALL serial_init(glob_rec_kandoouser.cmpy_code, "T", "", l_trans_num ) 

	LET err_message = "I57 - Locking all ibtdetl Records" 
--	DECLARE crs_check_ibtdetl CURSOR FOR 
--	SELECT * FROM ibtdetl 
--	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
--	AND trans_num = pr_ibthead.trans_num 
--	FOR UPDATE

WHENEVER SQLERROR STOP	
	LET query_statement = crs_check_ibtdetl.GetStatement()
	IF query_statement IS NULL THEN
		LET query_statement = "SELECT * FROM ibtdetl WHERE cmpy_code = ? AND AND trans_num = ?"
		CALL crs_check_ibtdetl.declare(query_statement)
		LET query_statement = crs_check_ibtdetl.GetStatement()
	END IF

	CALL crs_check_ibtdetl.SetParameters(glob_rec_kandoouser.cmpy_code,pr_ibthead.trans_num)
	CALL crs_check_ibtdetl.open()
	
	--FOREACH crs_check_ibtdetl INTO pr_ibtdetl.*
	WHILE crs_check_ibtdetl.FetchNext() = 0
		CALL crs_check_ibtdetl.SetResults(pr_ibtdetl.*)
		IF pr_ibtdetl.part_code IS NOT NULL THEN 
			IF pr_ibtdetl.sched_qty > 0 
			OR pr_ibtdetl.picked_qty > 0 THEN 
				LET err_message = "Docket OR Invoice raised during Cancel" 
				ROLLBACK WORK
				EXIT WHILE
				--GOTO recovery 
			END IF 
			SELECT * INTO lr_product.* 
			FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_ibtdetl.part_code 
			IF sqlca.sqlcode= notfound THEN 
				LET err_message = "Product NOT found ", pr_ibtdetl.part_code
				ROLLBACK WORK
				EXIT WHILE 
				--GOTO recovery 
			END IF 

			IF pr_ibtdetl.status_ind != IBTDETL_STATUS_IND_CANCELED_4 
			AND pr_ibtdetl.conf_qty > 0 THEN 
				LET pr_prodledg.ware_code = pr_ibthead.from_ware_code 
				LET pr_prodledg.source_text = pr_inparms.ibt_ware_code 
				LET pr_prodledg.tran_date = pr_ibthead.trans_date 
				LET pr_prodledg.year_num = pr_ibthead.year_num 
				LET pr_prodledg.period_num = pr_ibthead.period_num 
				LET pr_prodledg.desc_text = pr_ibthead.desc_text 
				CALL update_prodstatus(pr_ibtdetl.part_code,( -1 * pr_ibtdetl.conf_qty) ) 
				RETURNING ls_prodledg.*, l_serial_flag 
				UPDATE ibtload SET load_qty = rec_qty 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND trans_num = pr_ibtdetl.trans_num 
				AND line_num = pr_ibtdetl.line_num 
				LET pr_ibtdetl.conf_qty = 0 
			END IF 

			LET err_message = "Serial Delete -", pr_ibtdetl.part_code 
			CALL serial_delete(pr_ibtdetl.part_code, pr_ibthead.from_ware_code) 
			DECLARE c1_prodstatus CURSOR FOR 
			SELECT * FROM prodstatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ware_code = pr_ibthead.from_ware_code 
			AND part_code = pr_ibtdetl.part_code 
			FOR UPDATE 
			OPEN c1_prodstatus 
			FETCH c1_prodstatus 
			IF sqlca.sqlcode = 0 THEN 
				LET err_message = "I57 - Backorder setup - remove back_qty" 
				UPDATE prodstatus 
				SET back_qty = back_qty - pr_ibtdetl.back_qty 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = pr_ibthead.from_ware_code 
				AND part_code = pr_ibtdetl.part_code 
			END IF 
		END IF 
		LET pr_ibtdetl.back_qty = 0 
		LET pr_ibtdetl.status_ind = IBTDETL_STATUS_IND_CANCELED_4 
		LET pr_ibtdetl.amend_code = glob_rec_kandoouser.sign_on_code 
		LET pr_ibtdetl.amend_date = today 
		UPDATE ibtdetl 
		SET back_qty = pr_ibtdetl.back_qty, 
		amend_code = pr_ibtdetl.amend_code, 
		amend_date = pr_ibtdetl.amend_date, 
		status_ind = pr_ibtdetl.status_ind, 
		conf_qty = pr_ibtdetl.conf_qty 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND trans_num = pr_ibthead.trans_num 
		AND line_num = pr_ibtdetl.line_num 
	--END FOREACH 
	END WHILE    # fetchNExt crs_check_ibtdetl

	LET err_message = "I57 - serial RETURN " 
	LET status = serial_return("", "0") 

	LET pr_ibthead.rev_num = pr_ibthead.rev_num + 1 
	LET pr_ibthead.amend_date = today 
	LET pr_ibthead.amend_code = glob_rec_kandoouser.sign_on_code 
	LET pr_ibthead.status_ind = IBTHEAD_STATUS_IND_TRANSFER_CANCELLED_R 
	#
	LET err_message = "I57 - Update Transfer Header Record" 
	UPDATE ibthead SET * = pr_ibthead.* 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND trans_num = pr_ibthead.trans_num 

	CALL serial_init(glob_rec_kandoouser.cmpy_code, "t", "0", pr_ibthead.trans_num) 
	DECLARE c_ibtdetl_ser3 CURSOR FOR 
	SELECT part_code FROM ibtdetl 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND trans_num = pr_ibthead.trans_num 
	FOREACH c_ibtdetl_ser3 INTO pr_ibtdetl.part_code 
		CALL serial_delete(pr_ibtdetl.part_code, 
		pr_ibthead.from_ware_code) 
	END FOREACH 
	LET status = serial_return("","0") 

	COMMIT WORK  
END FUNCTION # cancel_transfer
