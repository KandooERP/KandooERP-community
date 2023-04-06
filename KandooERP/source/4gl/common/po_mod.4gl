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

	Source code beautified by beautify.pl on 2020-01-02 10:35:25	$Id: $
}



{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module - po_mod
# Purpose - Used TO Add/Edit Purchase Order Line Details
#

#Thsi file IS used as GLOBALS file FROM po_add.4gl
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/po_common_globals.4gl" 
#GLOBALS "../common/po_mod.4gl"

#GLOBALS
#	DEFINE glob_rec_purchdetl RECORD LIKE purchdetl.*
#	DEFINE glob_rec_poaudit RECORD LIKE poaudit.*
#	DEFINE glob_rec_vendor RECORD LIKE vendor.*
#	DEFINE glob_rec_purchhead RECORD LIKE purchhead.*
#	#DEFINE glob_rec_jobledger RECORD LIKE jobledger.* #not used ?
#	#DEFINE glob_rec_jmresource RECORD LIKE jmresource.* #not used ?
#	DEFINE glob_onorder_total LIKE vendor.onorder_amt
#END GLOBALS


############################################################
# FUNCTION cred_disp()
#
#
############################################################
FUNCTION cred_disp() 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_credit_avail LIKE vendor.limit_amt 
	DEFINE l_order_total LIKE vendor.bal_amt 

	SELECT sum(line_total_amt) INTO l_order_total FROM t_poaudit 
	IF l_order_total IS NULL THEN 
		LET l_order_total = 0 
	END IF 
	LET l_credit_avail = glob_rec_vendor.limit_amt - (glob_rec_vendor.bal_amt 
	+ glob_onorder_total 
	+ l_order_total) 
	DISPLAY l_order_total, 
	l_credit_avail 
	TO order_total, 
	credit_avail 

END FUNCTION 



############################################################
# FUNCTION insert_line()
#
#
############################################################
FUNCTION insert_line() 
	DEFINE l_rec_pf_purchdetl RECORD LIKE purchdetl.* 
	DEFINE l_rec_pf_poaudit RECORD LIKE poaudit.* 

	INITIALIZE l_rec_pf_purchdetl.* TO NULL 
	INITIALIZE l_rec_pf_poaudit.* TO NULL 
	SELECT max(line_num) + 1 INTO l_rec_pf_purchdetl.line_num FROM t_purchdetl 
	IF l_rec_pf_purchdetl.line_num IS NULL THEN 
		LET l_rec_pf_purchdetl.line_num = 1 
	ELSE 
		SELECT type_ind INTO l_rec_pf_purchdetl.type_ind FROM t_purchdetl 
		WHERE line_num = l_rec_pf_purchdetl.line_num - 1 
	END IF 
	LET l_rec_pf_poaudit.line_num = l_rec_pf_purchdetl.line_num 
	LET l_rec_pf_poaudit.order_qty = 0 
	LET l_rec_pf_poaudit.received_qty = 0 
	LET l_rec_pf_poaudit.voucher_qty = 0 
	LET l_rec_pf_poaudit.unit_cost_amt = 0 
	LET l_rec_pf_poaudit.ext_cost_amt = 0 
	LET l_rec_pf_poaudit.unit_tax_amt = 0 
	LET l_rec_pf_poaudit.ext_tax_amt = 0 
	LET l_rec_pf_poaudit.line_total_amt = 0 
	LET l_rec_pf_purchdetl.order_num = glob_rec_purchhead.order_num 
	INSERT INTO t_purchdetl VALUES (l_rec_pf_purchdetl.*) 
	INSERT INTO t_poaudit VALUES (l_rec_pf_poaudit.*) 
	LET glob_rec_purchdetl.* = l_rec_pf_purchdetl.* 
	LET glob_rec_poaudit.* = l_rec_pf_poaudit.* 
END FUNCTION 


############################################################
# FUNCTION purchdetl_update_line()
#
#
############################################################
FUNCTION purchdetl_update_line() 
	DEFINE l_rec_pf_purchdetl RECORD LIKE purchdetl.* 
	DEFINE l_rec_pf_poaudit RECORD LIKE poaudit.* 

	LET l_rec_pf_purchdetl.* = glob_rec_purchdetl.* 
	LET l_rec_pf_poaudit.* = glob_rec_poaudit.* 
	UPDATE t_purchdetl 
	SET vend_code = l_rec_pf_purchdetl.vend_code, 
	seq_num = l_rec_pf_purchdetl.seq_num, 
	type_ind = l_rec_pf_purchdetl.type_ind, 
	ref_text = l_rec_pf_purchdetl.ref_text, 
	oem_text = l_rec_pf_purchdetl.oem_text, 
	res_code = l_rec_pf_purchdetl.res_code, 
	job_code = l_rec_pf_purchdetl.job_code, 
	var_num = l_rec_pf_purchdetl.var_num, 
	activity_code = l_rec_pf_purchdetl.activity_code, 
	desc_text = l_rec_pf_purchdetl.desc_text, 
	desc2_text = l_rec_pf_purchdetl.desc2_text, 
	uom_code = l_rec_pf_purchdetl.uom_code, 
	acct_code = l_rec_pf_purchdetl.acct_code, 
	req_num = l_rec_pf_purchdetl.req_num, 
	req_line_num = l_rec_pf_purchdetl.req_line_num, 
	note_code = l_rec_pf_purchdetl.note_code, 
	list_cost_amt = l_rec_pf_purchdetl.list_cost_amt, 
	disc_per = l_rec_pf_purchdetl.disc_per, 
	charge_amt = l_rec_pf_purchdetl.charge_amt, 
	due_date = l_rec_pf_purchdetl.due_date 
	WHERE line_num = l_rec_pf_purchdetl.line_num 
	UPDATE t_poaudit 
	SET seq_num = l_rec_pf_poaudit.seq_num, 
	vend_code = l_rec_pf_poaudit.vend_code, 
	tran_code = l_rec_pf_poaudit.tran_code, 
	tran_num = l_rec_pf_poaudit.tran_num, 
	tran_date = l_rec_pf_poaudit.tran_date, 
	entry_date = l_rec_pf_poaudit.entry_date, 
	entry_code = l_rec_pf_poaudit.entry_code, 
	orig_auth_flag = l_rec_pf_poaudit.orig_auth_flag, 
	now_auth_flag = l_rec_pf_poaudit.now_auth_flag, 
	order_qty = l_rec_pf_poaudit.order_qty, 
	received_qty = l_rec_pf_poaudit.received_qty, 
	voucher_qty = l_rec_pf_poaudit.voucher_qty, 
	desc_text = l_rec_pf_poaudit.desc_text, 
	unit_cost_amt = l_rec_pf_poaudit.unit_cost_amt, 
	ext_cost_amt = l_rec_pf_poaudit.ext_cost_amt, 
	unit_tax_amt = l_rec_pf_poaudit.unit_tax_amt, 
	ext_tax_amt = l_rec_pf_poaudit.ext_tax_amt, 
	line_total_amt = l_rec_pf_poaudit.line_total_amt, 
	posted_flag = l_rec_pf_poaudit.posted_flag, 
	jour_num = l_rec_pf_poaudit.jour_num, 
	year_num = l_rec_pf_poaudit.year_num, 
	period_num = l_rec_pf_poaudit.period_num 
	WHERE line_num = l_rec_pf_purchdetl.line_num 
END FUNCTION 


############################################################
# FUNCTION contin_menu()
#
# Used FOR mode = "ADD"
############################################################
FUNCTION contin_menu() 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_option SMALLINT 

	--   OPEN WINDOW w2 AT 10,13 with 4 rows, 53 columns  -- albo  KD-756
	--      ATTRIBUTE(border,menu line 3)
	LET l_msgresp=kandoomsg("R",1015,"") 
	#1015 Use the menu OPTIONS below TO review this transaction
	MENU " Order Entry" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","po_mod","menu-Order_Entry-1") -- albo kd-503 
		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 
		COMMAND "Save" " Add Purchase Order TO Database" 
			LET l_option = 4 
			EXIT MENU 
		COMMAND "Header" " RETURN TO edit Order Header Details" 
			LET l_option = 2 
			EXIT MENU 
		COMMAND KEY(interrupt,"E")"Exit" " RETURN TO edit Order Line Items" 
			LET l_option = 1 
			EXIT MENU 

	END MENU 
	--   CLOSE WINDOW w2  -- albo  KD-756
	RETURN l_option 
END FUNCTION 


############################################################
# FUNCTION po_mod(p_cmpy_code, p_kandoouser_sign_on_code, p_po_num, p_mode)
#
#
############################################################
FUNCTION po_mod(p_cmpy_code,p_kandoouser_sign_on_code,p_po_num, p_mode) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE p_po_num LIKE poaudit.po_num 
	DEFINE p_mode CHAR(4) 
	DEFINE l_arr_rec_purchdetl DYNAMIC ARRAY OF #array[2000] OF RECORD 
		RECORD 
			scroll_flag CHAR(1), 
			line_num LIKE purchdetl.line_num, 
			type_ind LIKE purchdetl.type_ind, 
			ref_text LIKE purchdetl.ref_text, 
			order_qty LIKE poaudit.order_qty, 
			uom_code LIKE purchdetl.uom_code, 
			line_total_amt LIKE poaudit.line_total_amt 
		END RECORD 
		DEFINE l_rec_purchhead RECORD LIKE purchhead.* 
		DEFINE l_rec_ps_purchdetl RECORD LIKE purchdetl.* 
		DEFINE l_rec_pf_purchdetl RECORD LIKE purchdetl.* 
		DEFINE l_rec_pf_poaudit RECORD LIKE poaudit.* 
		DEFINE l_rec_ps_poaudit RECORD LIKE poaudit.* 
		DEFINE l_rec_st_poaudit RECORD LIKE poaudit.* 
		DEFINE l_rec_cu_poaudit RECORD LIKE poaudit.* 
		DEFINE l_order_total LIKE poaudit.line_total_amt 
		DEFINE l_scroll_flag CHAR(1) 
		DEFINE l_pr_valid_tran CHAR(1) 
		DEFINE l_v_line_num SMALLINT 
		DEFINE l_err_cnt SMALLINT 
		DEFINE l_option SMALLINT 
		DEFINE l_order_total2 LIKE poaudit.line_total_amt 
		DEFINE idx SMALLINT 
		DEFINE i SMALLINT 
		#DEFINE j SMALLINT
		DEFINE l_lastkey2 SMALLINT 
		DEFINE l_lastkey SMALLINT 
		DEFINE l_available_amt LIKE fundsapproved.limit_amt 
		DEFINE l_seq_num LIKE poaudit.seq_num 
		DEFINE l_msgresp LIKE language.yes_flag 

		OPEN WINDOW r103 with FORM "R103" 
		CALL windecoration_r("R103") -- albo kd-756 
		LET idx = 0 
		LET l_order_total2 = 0 
		IF p_mode = "EDIT" THEN 
			SELECT * INTO glob_rec_purchhead.* FROM purchhead 
			WHERE cmpy_code = p_cmpy_code 
			AND order_num = p_po_num 
			SELECT * INTO glob_rec_vendor.* FROM vendor 
			WHERE cmpy_code = p_cmpy_code 
			AND vend_code = glob_rec_purchhead.vend_code 
			INSERT INTO t_purchdetl 
			SELECT * FROM purchdetl 
			WHERE cmpy_code = p_cmpy_code 
			AND order_num = glob_rec_purchhead.order_num 
			LET l_msgresp = kandoomsg("U",1002,"") 
			#1002 Searching Database;  Please wait.
			WHENEVER ERROR stop 
			WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
			DECLARE c_podetl CURSOR FOR 
			SELECT * FROM t_purchdetl 
			WHERE order_num = p_po_num 
			AND cmpy_code = p_cmpy_code 
			ORDER BY line_num 
			FOREACH c_podetl INTO l_rec_pf_purchdetl.* 
				LET idx = idx + 1 
				LET l_arr_rec_purchdetl[idx].line_num = l_rec_pf_purchdetl.line_num 
				LET l_arr_rec_purchdetl[idx].type_ind = l_rec_pf_purchdetl.type_ind 
				LET l_arr_rec_purchdetl[idx].ref_text = l_rec_pf_purchdetl.ref_text 
				INITIALIZE l_rec_pf_poaudit.* TO NULL 
				CALL po_line_info(p_cmpy_code, 
				p_po_num, 
				l_rec_pf_purchdetl.line_num) 
				RETURNING l_rec_pf_poaudit.order_qty, 
				l_rec_pf_poaudit.received_qty, 
				l_rec_pf_poaudit.voucher_qty, 
				l_rec_pf_poaudit.unit_cost_amt, 
				l_rec_pf_poaudit.ext_cost_amt, 
				l_rec_pf_poaudit.unit_tax_amt, 
				l_rec_pf_poaudit.ext_tax_amt, 
				l_rec_pf_poaudit.line_total_amt 
				LET l_rec_pf_poaudit.cmpy_code = p_cmpy_code 
				LET l_rec_pf_poaudit.line_num = l_rec_pf_purchdetl.line_num 
				LET l_rec_pf_poaudit.po_num = l_rec_pf_purchdetl.order_num 
				LET l_rec_pf_poaudit.tran_date = today 
				CALL db_period_what_period(p_cmpy_code,l_rec_pf_poaudit.tran_date) 
				RETURNING l_rec_pf_poaudit.year_num, 
				l_rec_pf_poaudit.period_num 
				INSERT INTO t_poaudit VALUES (l_rec_pf_poaudit.*) 
				LET l_arr_rec_purchdetl[idx].order_qty = l_rec_pf_poaudit.order_qty 
				LET l_arr_rec_purchdetl[idx].uom_code = l_rec_pf_purchdetl.uom_code 
				LET l_arr_rec_purchdetl[idx].line_total_amt = l_rec_pf_poaudit.line_total_amt 
				LET l_order_total2 = l_order_total2 + l_rec_pf_poaudit.line_total_amt 
				IF idx >= 2000 THEN 
					EXIT FOREACH 
				END IF 
			END FOREACH 
		ELSE 
			DECLARE c_purchdetl CURSOR FOR 
			SELECT * FROM t_purchdetl 
			ORDER BY line_num 
			FOREACH c_purchdetl INTO l_rec_pf_purchdetl.* 
				LET idx = idx + 1 
				SELECT * INTO l_rec_pf_poaudit.* FROM t_poaudit 
				WHERE line_num = l_rec_pf_purchdetl.line_num 
				LET l_arr_rec_purchdetl[idx].line_num = l_rec_pf_purchdetl.line_num 
				LET l_arr_rec_purchdetl[idx].type_ind = l_rec_pf_purchdetl.type_ind 
				LET l_arr_rec_purchdetl[idx].ref_text = l_rec_pf_purchdetl.ref_text 
				LET l_arr_rec_purchdetl[idx].uom_code = l_rec_pf_purchdetl.uom_code 
				LET l_arr_rec_purchdetl[idx].order_qty = l_rec_pf_poaudit.order_qty 
				LET l_arr_rec_purchdetl[idx].line_total_amt = l_rec_pf_poaudit.line_total_amt 
			END FOREACH 
		END IF 

		IF idx = 0 THEN 
			LET idx = 1 
			INITIALIZE l_arr_rec_purchdetl[idx].* TO NULL 
		END IF 

		CALL set_count(idx) 
		LET glob_onorder_total = glob_rec_vendor.onorder_amt - l_order_total2 

		LET l_msgresp = kandoomsg("R",1014,"") 
		#1014 F1 TO Add;  F2 TO Delete;  F8 Vendor Inquiry;  Enter on line TO Edit.
		OPTIONS INSERT KEY f36, 
		DELETE KEY f36 

		INPUT ARRAY l_arr_rec_purchdetl WITHOUT DEFAULTS FROM sr_purchdetl.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","po_mod","input-arr-purchedetl") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON KEY (F8) 
				CALL vinq_vend(p_cmpy_code,glob_rec_purchhead.vend_code) 
				OPTIONS INSERT KEY f36, 
				DELETE KEY f36 
			BEFORE ROW 
				LET idx = arr_curr() 
				NEXT FIELD scroll_flag 

			BEFORE FIELD scroll_flag 
				#         LET scrn = scr_line()
				LET l_scroll_flag = l_arr_rec_purchdetl[idx].scroll_flag 
				OPTIONS INSERT KEY f1, 
				DELETE KEY f36 
				SELECT * INTO l_rec_pf_purchdetl.* FROM t_purchdetl 
				WHERE line_num = l_arr_rec_purchdetl[idx].line_num 
				IF status = 0 THEN 
					SELECT * INTO l_rec_pf_poaudit.* FROM t_poaudit 
					WHERE line_num = l_arr_rec_purchdetl[idx].line_num 
					LET glob_rec_purchdetl.* = l_rec_pf_purchdetl.* 
					LET glob_rec_poaudit.* = l_rec_pf_poaudit.* 
					LET l_arr_rec_purchdetl[idx].line_num = l_rec_pf_purchdetl.line_num 
					LET l_arr_rec_purchdetl[idx].type_ind = l_rec_pf_purchdetl.type_ind 
					LET l_arr_rec_purchdetl[idx].ref_text = l_rec_pf_purchdetl.ref_text 
					LET l_arr_rec_purchdetl[idx].uom_code = l_rec_pf_purchdetl.uom_code 
					LET l_arr_rec_purchdetl[idx].order_qty = l_rec_pf_poaudit.order_qty 
					LET l_arr_rec_purchdetl[idx].line_total_amt = l_rec_pf_poaudit.line_total_amt 
					#            DISPLAY l_arr_rec_purchdetl[idx].* TO sr_purchdetl[scrn].*

					DISPLAY BY NAME l_rec_pf_purchdetl.desc_text 

					IF l_rec_pf_purchdetl.note_code IS NOT NULL 
					OR l_rec_pf_purchdetl.note_code != " " THEN 
						DISPLAY l_rec_pf_purchdetl.note_code 
						TO note_code 

					ELSE 
						DISPLAY "" 
						TO note_code 

					END IF 
				ELSE 
					INITIALIZE l_rec_pf_purchdetl.desc_text TO NULL 
					DISPLAY l_rec_pf_purchdetl.desc_text, 
					l_rec_pf_purchdetl.note_code 
					TO desc_text, 
					note_code 

					LET l_rec_pf_purchdetl.line_num = NULL 
					IF fgl_lastkey() = fgl_keyval("down") THEN 
						NEXT FIELD line_num 
					END IF 
				END IF 

				CALL cred_disp() 
				IF fgl_lastkey() = fgl_keyval("down") 
				OR fgl_lastkey() = fgl_keyval("RETURN") 
				OR fgl_lastkey() = fgl_keyval("tab") 
				OR fgl_lastkey() = fgl_keyval("right") 
				OR l_lastkey2 = fgl_keyval("accept") THEN 
					LET l_lastkey2 = 0 
					IF l_arr_rec_purchdetl[idx].type_ind IS NULL THEN 
						NEXT FIELD line_num 
					END IF 
				END IF 
				#         DISPLAY l_arr_rec_purchdetl[idx].* TO sr_purchdetl[scrn].*

			AFTER FIELD scroll_flag 
				LET l_arr_rec_purchdetl[idx].scroll_flag = l_scroll_flag 
				#         DISPLAY l_arr_rec_purchdetl[idx].scroll_flag
				#              TO sr_purchdetl[scrn].scroll_flag

				IF fgl_lastkey() = fgl_keyval("down") 
				OR fgl_lastkey() = fgl_keyval("RETURN") 
				OR fgl_lastkey() = fgl_keyval("tab") 
				OR fgl_lastkey() = fgl_keyval("right") 
				OR l_lastkey2 = fgl_keyval("accept") THEN 
					IF l_arr_rec_purchdetl[idx].type_ind IS NULL THEN 
						NEXT FIELD line_num 
					END IF 
				END IF 

			BEFORE FIELD line_num 
				#         LET scrn = scr_line()
				#         DISPLAY l_arr_rec_purchdetl[idx].* TO sr_purchdetl[scrn].*

				LET l_lastkey2 = 0 
				IF l_arr_rec_purchdetl[idx].type_ind IS NOT NULL THEN 
					IF l_arr_rec_purchdetl[idx].scroll_flag IS NOT NULL THEN 
						LET l_msgresp = kandoomsg("W",9016,"") 
						#9016 Order Line has been cancelled - Cannot Edit"
						NEXT FIELD scroll_flag 
					END IF 
				END IF 
				IF l_rec_pf_purchdetl.line_num IS NULL THEN 
					CALL insert_line() 
					LET l_rec_pf_purchdetl.* = glob_rec_purchdetl.* 
					LET l_rec_pf_poaudit.* = glob_rec_poaudit.* 
					INITIALIZE l_rec_ps_purchdetl.* TO NULL 
					INITIALIZE l_rec_ps_poaudit.* TO NULL 
					LET l_arr_rec_purchdetl[idx].line_num = l_rec_pf_purchdetl.line_num 
					LET l_arr_rec_purchdetl[idx].type_ind = l_rec_pf_purchdetl.type_ind 
					LET l_arr_rec_purchdetl[idx].ref_text = l_rec_pf_purchdetl.ref_text 
					LET l_arr_rec_purchdetl[idx].uom_code = l_rec_pf_purchdetl.uom_code 
					LET l_arr_rec_purchdetl[idx].order_qty = l_rec_pf_poaudit.order_qty 
					LET l_arr_rec_purchdetl[idx].line_total_amt = l_rec_pf_poaudit.line_total_amt 
					#            DISPLAY l_arr_rec_purchdetl[idx].* TO sr_purchdetl[scrn].*

					DISPLAY BY NAME glob_rec_purchdetl.desc_text, 
					glob_rec_purchdetl.note_code 

				ELSE 
					LET l_rec_ps_purchdetl.* = l_rec_pf_purchdetl.* 
					LET l_rec_ps_poaudit.* = l_rec_pf_poaudit.* 
				END IF 
				NEXT FIELD type_ind 

			ON KEY (F2) 
				SELECT unique 1 FROM purchdetl 
				WHERE cmpy_code = p_cmpy_code 
				AND line_num = l_arr_rec_purchdetl[idx].line_num 
				AND order_num = glob_rec_purchhead.order_num 
				IF status = 0 THEN 
					IF infield(scroll_flag) THEN 
						IF l_arr_rec_purchdetl[idx].scroll_flag IS NULL THEN 
							SELECT * FROM purchdetl 
							WHERE cmpy_code = p_cmpy_code 
							AND order_num = glob_rec_purchhead.order_num 
							AND line_num = l_arr_rec_purchdetl[idx].line_num 
							IF status = 0 THEN 
								CALL po_line_info(p_cmpy_code, glob_rec_purchhead.order_num, 
								glob_rec_purchdetl.line_num) 
								RETURNING l_rec_cu_poaudit.order_qty, 
								l_rec_cu_poaudit.received_qty, 
								l_rec_cu_poaudit.voucher_qty, 
								l_rec_cu_poaudit.unit_cost_amt, 
								l_rec_cu_poaudit.ext_cost_amt, 
								l_rec_cu_poaudit.unit_tax_amt, 
								l_rec_cu_poaudit.ext_tax_amt, 
								l_rec_cu_poaudit.line_total_amt 
								IF l_rec_cu_poaudit.received_qty != 0 THEN 
									LET l_msgresp = kandoomsg("P",9522,"Receipted") 
									#9522 Line Item has been Receipted-Delete NOT ...
									NEXT FIELD scroll_flag 
								END IF 
								IF l_rec_cu_poaudit.voucher_qty > 0 THEN 
									LET l_msgresp = kandoomsg("P",9522,"Invoiced") 
									#9522 Line Item has been Invoiced-Delete NOT ...
									NEXT FIELD scroll_flag 
								END IF 
							END IF 
							LET glob_rec_poaudit.order_qty = 0 
							LET glob_rec_poaudit.ext_cost_amt = 0 
							LET glob_rec_poaudit.ext_tax_amt = 0 
							LET glob_rec_poaudit.line_total_amt = 0 
							LET l_arr_rec_purchdetl[idx].scroll_flag = "*" 
							LET l_arr_rec_purchdetl[idx].order_qty = 0 
							LET l_arr_rec_purchdetl[idx].line_total_amt = 0 
							CALL purchdetl_update_line() 
						ELSE 
							LET l_arr_rec_purchdetl[idx].scroll_flag = NULL 
						END IF 
					END IF 
					#            DISPLAY l_arr_rec_purchdetl[idx].* TO sr_purchdetl[scrn].*

					NEXT FIELD scroll_flag 
				ELSE 
					DELETE FROM t_purchdetl 
					WHERE line_num = l_arr_rec_purchdetl[idx].line_num 
					DELETE FROM t_poaudit 
					WHERE line_num = l_arr_rec_purchdetl[idx].line_num 
					FOR i = arr_curr() TO arr_count() 
						LET l_arr_rec_purchdetl[i].* = l_arr_rec_purchdetl[i+1].* 
						#               IF scrn <= 12 THEN
						#                  IF l_arr_rec_purchdetl[i].type_ind IS NULL THEN
						#                     INITIALIZE l_arr_rec_purchdetl[i].* TO NULL
						#                  END IF
						#                  DISPLAY l_arr_rec_purchdetl[i].* TO sr_purchdetl[scrn].*
						#
						#                  LET scrn = scrn + 1
						#               END IF
						IF l_arr_rec_purchdetl[i].type_ind IS NULL THEN 
							EXIT FOR 
						END IF 
					END FOR 
					INITIALIZE l_arr_rec_purchdetl[i].* TO NULL 
					CALL credit_disp() 
					NEXT FIELD scroll_flag 
				END IF 

			BEFORE FIELD type_ind 
				SELECT unique 1 FROM purchdetl 
				WHERE cmpy_code = p_cmpy_code 
				AND order_num = glob_rec_purchhead.order_num 
				AND line_num = l_arr_rec_purchdetl[idx].line_num 
				IF status = 0 THEN 
					# modify existing line details
					IF glob_rec_purchhead.status_ind = "C" THEN 
						LET l_msgresp = kandoomsg("R",9520,"") 
						#9520 The purchase ORDER cannot be edited as it IS completed.
						NEXT FIELD scroll_flag 
					END IF 
					IF po_chng(p_cmpy_code, p_kandoouser_sign_on_code, glob_rec_purchhead.order_num, 
					glob_rec_purchdetl.line_num) THEN 
						CALL purchdetl_update_line() 
						LET l_rec_pf_purchdetl.* = glob_rec_purchdetl.* 
						LET l_rec_pf_poaudit.* = glob_rec_poaudit.* 
						CALL po_line_info(p_cmpy_code, 
						glob_rec_purchhead.order_num, 
						glob_rec_purchdetl.line_num) 
						RETURNING glob_rec_poaudit.order_qty, 
						glob_rec_poaudit.received_qty, 
						glob_rec_poaudit.voucher_qty, 
						glob_rec_poaudit.unit_cost_amt, 
						glob_rec_poaudit.ext_cost_amt, 
						glob_rec_poaudit.unit_tax_amt, 
						glob_rec_poaudit.ext_tax_amt, 
						glob_rec_poaudit.line_total_amt 
						LET l_arr_rec_purchdetl[idx].line_num = l_rec_pf_purchdetl.line_num 
						LET l_arr_rec_purchdetl[idx].type_ind = l_rec_pf_purchdetl.type_ind 
						LET l_arr_rec_purchdetl[idx].ref_text = l_rec_pf_purchdetl.ref_text 
						LET l_arr_rec_purchdetl[idx].uom_code = l_rec_pf_purchdetl.uom_code 
						LET l_arr_rec_purchdetl[idx].order_qty = l_rec_pf_poaudit.order_qty 
						LET l_arr_rec_purchdetl[idx].line_total_amt = l_rec_pf_poaudit.line_total_amt 
					END IF 
					CALL cred_disp() 
					OPTIONS INSERT KEY f1, 
					DELETE KEY f36 
					NEXT FIELD NEXT 
				ELSE 
					SELECT * INTO glob_rec_purchdetl.* FROM t_purchdetl 
					WHERE line_num = l_arr_rec_purchdetl[idx].line_num 
				END IF 

			AFTER FIELD type_ind 
				IF fgl_lastkey() = fgl_keyval("left") 
				OR fgl_lastkey() = fgl_keyval("up") THEN 
					SELECT * INTO glob_rec_purchdetl.* FROM t_purchdetl 
					WHERE line_num = l_arr_rec_purchdetl[idx].line_num 
					IF glob_rec_purchdetl.vend_code IS NULL 
					OR glob_rec_purchdetl.vend_code = " " THEN 
						DELETE FROM t_purchdetl 
						WHERE line_num = l_arr_rec_purchdetl[idx].line_num 
						DELETE FROM t_poaudit 
						WHERE line_num = l_arr_rec_purchdetl[idx].line_num 
						INITIALIZE l_arr_rec_purchdetl[idx].* TO NULL 
					END IF 
					NEXT FIELD scroll_flag 
				END IF 
				IF l_arr_rec_purchdetl[idx].type_ind IS NULL THEN 
					NEXT FIELD type_ind 
				END IF 

				IF l_arr_rec_purchdetl[idx].type_ind NOT matches "[GIJC]" THEN 
					LET l_msgresp=kandoomsg("R",9014,"") 
					#R9014 Valid line types are G,I,J
					NEXT FIELD type_ind 
				END IF 
				LET l_lastkey = fgl_lastkey() 
				IF glob_rec_purchhead.ware_code IS NULL 
				AND l_arr_rec_purchdetl[idx].type_ind matches "[IC]" THEN 
					LET l_msgresp = kandoomsg("R",9006,"") 
					#9006 Inventory ORDER lines are NOT permitted ...
					NEXT FIELD type_ind 
				END IF 
				IF po_add_line(p_cmpy_code, p_kandoouser_sign_on_code, glob_rec_purchhead.order_num, 
				l_arr_rec_purchdetl[idx].type_ind) THEN 

					IF l_arr_rec_purchdetl[idx].type_ind matches "[IC]" THEN 
						SELECT * 
						FROM product 
						WHERE cmpy_code = p_cmpy_code 
						AND part_code = glob_rec_purchdetl.ref_text 
						AND serial_flag = "Y" 
						IF status <> notfound THEN 
							SELECT line_num 
							INTO l_v_line_num 
							FROM t_purchdetl 
							WHERE order_num = glob_rec_purchdetl.order_num 
							AND cmpy_code = p_cmpy_code 
							AND type_ind = "I" OR type_ind = "C" 
							AND ref_text = glob_rec_purchdetl.ref_text 
							IF status <> notfound THEN 
								LET l_msgresp=kandoomsg("R",9538,l_v_line_num) 
								#R9538 This serialized Product already exists on line
								NEXT FIELD type_ind 
							END IF 
						END IF 
					END IF 

					CALL purchdetl_update_line() 
					LET l_rec_pf_purchdetl.* = glob_rec_purchdetl.* 
					LET l_rec_pf_poaudit.* = glob_rec_poaudit.* 
					LET l_arr_rec_purchdetl[idx].line_num = l_rec_pf_purchdetl.line_num 
					LET l_arr_rec_purchdetl[idx].type_ind = l_rec_pf_purchdetl.type_ind 
					LET l_arr_rec_purchdetl[idx].ref_text = l_rec_pf_purchdetl.ref_text 
					LET l_arr_rec_purchdetl[idx].uom_code = l_rec_pf_purchdetl.uom_code 
					LET l_arr_rec_purchdetl[idx].order_qty = l_rec_pf_poaudit.order_qty 
					LET l_arr_rec_purchdetl[idx].line_total_amt = l_rec_pf_poaudit.line_total_amt 
				ELSE 
					NEXT FIELD type_ind 
				END IF 
				#         DISPLAY l_arr_rec_purchdetl[idx].* TO sr_purchdetl[scrn].*

				CALL cred_disp() 
				OPTIONS INSERT KEY f1, 
				DELETE KEY f36 
				LET l_lastkey2 = fgl_lastkey() 
				IF l_lastkey = fgl_keyval("accept") THEN 
					NEXT FIELD scroll_flag 
				END IF 
				NEXT FIELD NEXT 
			BEFORE FIELD ref_text 
				NEXT FIELD NEXT 
			BEFORE INSERT 
				INITIALIZE l_arr_rec_purchdetl[idx].* TO NULL 
				INITIALIZE l_rec_pf_purchdetl.* TO NULL 
				INITIALIZE l_rec_pf_poaudit.* TO NULL 
				### Informix bug - ON LAST ROW, IF del IS pressed, BEFORE INSERT
				### IS re-executed
				IF fgl_lastkey() = fgl_keyval("delete") 
				OR fgl_lastkey() = fgl_keyval("interrupt") THEN 
					INITIALIZE l_arr_rec_purchdetl[idx].* TO NULL 
					NEXT FIELD scroll_flag 
				ELSE 
					NEXT FIELD line_num 
				END IF 
				#      AFTER ROW
				#         DISPLAY l_arr_rec_purchdetl[idx].* TO sr_purchdetl[scrn].*

			AFTER INPUT 
				IF int_flag OR quit_flag THEN 
					IF NOT infield(scroll_flag) THEN 
						LET int_flag = false 
						LET quit_flag = false 
						IF l_rec_ps_purchdetl.line_num IS NULL THEN 
							DELETE FROM t_purchdetl 
							WHERE line_num = l_arr_rec_purchdetl[idx].line_num 
							DELETE FROM t_poaudit 
							WHERE line_num = l_arr_rec_purchdetl[idx].line_num 
							#                  LET j = scrn
							FOR i = arr_curr() TO arr_count() 
								IF l_arr_rec_purchdetl[i+1].line_num IS NOT NULL THEN 
									LET l_arr_rec_purchdetl[i].* = l_arr_rec_purchdetl[i+1].* 
								ELSE 
									INITIALIZE l_arr_rec_purchdetl[i].* TO NULL 
								END IF 
								#                     IF j <= 12 THEN
								#                        IF l_arr_rec_purchdetl[i].line_num = 0 THEN
								#                           LET l_arr_rec_purchdetl[i].line_num = NULL
								#                        END IF
								#                        IF l_arr_rec_purchdetl[i].order_qty = 0 THEN
								#                           LET l_arr_rec_purchdetl[i].order_qty = NULL
								#                        END IF
								#                        DISPLAY l_arr_rec_purchdetl[i].* TO sr_purchdetl[j].*
								#
								#                        LET j = j + 1
								#                     END IF
							END FOR 
						ELSE 
							LET glob_rec_purchdetl.* = l_rec_ps_purchdetl.* 
							LET glob_rec_poaudit.* = l_rec_ps_poaudit.* 
							CALL purchdetl_update_line() 
							LET l_arr_rec_purchdetl[idx].line_num = l_rec_ps_purchdetl.line_num 
							LET l_arr_rec_purchdetl[idx].type_ind = l_rec_ps_purchdetl.type_ind 
							LET l_arr_rec_purchdetl[idx].ref_text = l_rec_ps_purchdetl.ref_text 
							LET l_arr_rec_purchdetl[idx].uom_code = l_rec_ps_purchdetl.uom_code 
							LET l_arr_rec_purchdetl[idx].order_qty = l_rec_ps_poaudit.order_qty 
							LET l_arr_rec_purchdetl[idx].line_total_amt = 
							l_rec_ps_poaudit.line_total_amt 
						END IF 
						NEXT FIELD scroll_flag 
					ELSE 
						IF p_mode = "ADD" THEN 
							LET int_flag = false 
							LET quit_flag = false 
							LET l_option = "2" 
						END IF 
					END IF 
				ELSE 
					SELECT unique 1 FROM t_purchdetl 
					IF status = notfound THEN 
						LET l_msgresp=kandoomsg("R",9007,"") 
						#9007 Purchase ORDER must have lines TO continue
						NEXT FIELD scroll_flag 
					END IF 
					IF p_mode = "ADD" THEN 
						CALL contin_menu() 
						RETURNING l_option 
					ELSE 
						SELECT sum(line_total_amt) INTO l_order_total FROM t_poaudit 
						IF l_order_total IS NULL THEN 
							LET l_order_total = 0 
						END IF 
						IF l_order_total < glob_rec_vendor.min_ord_amt 
						AND glob_rec_vendor.min_ord_amt IS NOT NULL 
						AND glob_rec_vendor.min_ord_amt != 0 THEN 
							LET l_msgresp = kandoomsg("R",8005,glob_rec_vendor.min_ord_amt) 
							#8005 ORDER total < vendor minimum ORDER amount
							IF l_msgresp = 'N' THEN 
								NEXT FIELD scroll_flag 
							END IF 
						END IF 
						IF NOT update_order(p_cmpy_code,p_kandoouser_sign_on_code) THEN 
							SELECT unique(1) FROM t_purchdetl 
							WHERE line_num = 1 
							IF status = notfound THEN 
								# Another user has changed purchase ORDER
								LET int_flag = true 
								EXIT INPUT 
							END IF 
							LET l_msgresp = kandoomsg("R",1014,"") 
							#1014 F1 TO Add;  F2 TO Delete;  F8 Vendor Inquiry; ...
							NEXT FIELD type_ind 
						END IF 
					END IF 
				END IF 
				IF p_mode = "ADD" THEN 
					CASE l_option ### OPTIONS are .. 
						WHEN 1 ## 1. CONTINUE line item edit 
							NEXT FIELD type_ind ## 2. back out saving line info 
						WHEN 2 ## 3. back out NOT saving line info 
							LET quit_flag = true ## 4. save purchase ORDER 
						WHEN 3 
							INITIALIZE glob_rec_purchhead.* TO NULL 
							INITIALIZE glob_rec_vendor.* TO NULL 
							LET quit_flag = true 
						WHEN 4 
							SELECT sum(line_total_amt) INTO l_order_total FROM t_poaudit 
							IF l_order_total IS NULL THEN 
								LET l_order_total = 0 
							END IF 
							IF l_order_total < glob_rec_vendor.min_ord_amt 
							AND glob_rec_vendor.min_ord_amt IS NOT NULL 
							AND glob_rec_vendor.min_ord_amt != 0 THEN 
								LET l_msgresp = kandoomsg("R",8005,glob_rec_vendor.min_ord_amt) 
								#8005 ORDER total < vendor minimum ORDER amount
								IF l_msgresp = 'N' THEN 
									NEXT FIELD type_ind 
								END IF 
							END IF 
							IF write_order(p_cmpy_code,p_kandoouser_sign_on_code) THEN 
								LET l_msgresp=kandoomsg("R",7010,glob_rec_purchhead.order_num) 
								#7010 Purchase Order VALUE added Successfully.
							ELSE 
								IF p_mode = "ADD" THEN 
									LET glob_rec_purchhead.order_num = NULL 
								END IF 
								LET l_msgresp = kandoomsg("R",1014,"") 
								#1014 F1 TO Add;  F2 TO Delete;  F8 Vendor Inquiry; ...
								NEXT FIELD type_ind 
							END IF 
							LET int_flag = false 
							LET quit_flag = false 
					END CASE 
				END IF 

		END INPUT 
		---------

		CLOSE WINDOW r103 

		IF int_flag OR quit_flag THEN 
			IF p_mode = "EDIT" THEN 
				DELETE FROM t_purchdetl WHERE 1 = 1 
				DELETE FROM t_poaudit WHERE 1 = 1 
			END IF 
			LET int_flag = false 
			LET quit_flag = false 
			RETURN false 
		END IF 
		RETURN true 
END FUNCTION 


############################################################
# FUNCTION update_order(p_cmpy_code,p_kandoouser_sign_on_code)
#
# Updates Purchase Order TO table FOR mode = "EDIT"
############################################################
FUNCTION update_order(p_cmpy_code,p_kandoouser_sign_on_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE l_rec_purchhead RECORD LIKE purchhead.* 
	DEFINE l_rec_pf_purchdetl RECORD LIKE purchdetl.* 
	DEFINE l_rec_cu_poaudit RECORD LIKE poaudit.* 
	DEFINE l_rec_st_poaudit RECORD LIKE poaudit.* 
	DEFINE l_err_continue, l_pr_valid_tran CHAR(1) 
	DEFINE l_err_message CHAR(40) 
	DEFINE l_new_onorder_amt LIKE vendor.onorder_amt 
	DEFINE l_old_onorder_amt LIKE vendor.onorder_amt 
	DEFINE l_err_cnt SMALLINT 
	DEFINE l_kandoo_log_msg CHAR(200) 
	DEFINE l_temp_order_qty LIKE poaudit.order_qty 
	DEFINE l_err_stat INTEGER 
	DEFINE l_save_line INTEGER 
	DEFINE l_saved_line INTEGER 
	DEFINE l_available_amt LIKE fundsapproved.limit_amt 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_msgresp = kandoomsg("U",1005,"") 
	#1005 Updating Database; Please wait.

	GOTO bypass 

	LABEL recovery: 
	LET l_err_continue = error_recover(l_err_message, status) 
	IF l_err_continue != "Y" THEN 
		EXIT program 
	END IF 

	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		DECLARE c_purchhead CURSOR FOR 
		SELECT * FROM purchhead 
		WHERE cmpy_code = p_cmpy_code 
		AND order_num = glob_rec_purchhead.order_num 
		FOR UPDATE 

		DECLARE c_vendor CURSOR FOR 
		SELECT * FROM vendor 
		WHERE cmpy_code = p_cmpy_code 
		AND vend_code = glob_rec_purchhead.vend_code 
		FOR UPDATE 
		OPEN c_purchhead 
		FETCH c_purchhead INTO l_rec_purchhead.* 
		OPEN c_vendor 
		FETCH c_vendor INTO glob_rec_vendor.* 

		IF l_rec_purchhead.rev_num != glob_rec_purchhead.rev_num THEN 
			LET l_msgresp = kandoomsg("W",7026,"") 
			#7026 Another user has edited this ORDER - Changes NOT saved
			ROLLBACK WORK 
			#Forced TO do this because user IS sent back TO OPTIONS window
			DELETE FROM t_purchdetl 
			DELETE FROM t_poaudit 
			RETURN false 
		END IF 

		LET glob_rec_purchhead.rev_date = today 
		DECLARE c2_purchdetl CURSOR with HOLD FOR 
		SELECT * FROM t_purchdetl 
		ORDER BY line_num 
		LET l_old_onorder_amt = 0 
		LET l_new_onorder_amt = 0 
		LET l_err_cnt = 0 

		FOREACH c2_purchdetl INTO glob_rec_purchdetl.* 
			SELECT * INTO glob_rec_poaudit.* FROM t_poaudit 
			WHERE line_num = glob_rec_purchdetl.line_num 
			CALL check_funds(p_cmpy_code, 
			glob_rec_purchdetl.acct_code, 
			glob_rec_poaudit.line_total_amt, 
			glob_rec_purchdetl.line_num, 
			glob_rec_poaudit.year_num, 
			glob_rec_poaudit.period_num, 
			"R", 
			glob_rec_purchhead.order_num, 
			"N") 
			RETURNING l_pr_valid_tran, l_available_amt 
			IF NOT l_pr_valid_tran THEN 
				LET l_msgresp = kandoomsg("U",9944,"") 
				#9944 The available Approved funds has been exceeded.
				ROLLBACK WORK 
				RETURN false 
			END IF 
			SELECT * INTO l_rec_pf_purchdetl.* FROM purchdetl 
			WHERE cmpy_code = p_cmpy_code 
			AND order_num = glob_rec_purchhead.order_num 
			AND line_num = glob_rec_purchdetl.line_num 
			IF status = 0 THEN 
				CALL po_line_info(p_cmpy_code, 
				glob_rec_purchdetl.order_num, 
				glob_rec_purchdetl.line_num) 
				RETURNING l_rec_st_poaudit.order_qty, 
				l_rec_st_poaudit.received_qty, 
				l_rec_st_poaudit.voucher_qty, 
				l_rec_st_poaudit.unit_cost_amt, 
				l_rec_st_poaudit.ext_cost_amt, 
				l_rec_st_poaudit.unit_tax_amt, 
				l_rec_st_poaudit.ext_tax_amt, 
				l_rec_st_poaudit.line_total_amt 
				## IF seq_num on database IS different AT this stage it means
				## purchdetl has been receipted OR vouchered.  During vouchering
				## unit cost of purchdetl may change.
				IF l_rec_pf_purchdetl.seq_num != glob_rec_purchdetl.seq_num 
				AND (l_rec_st_poaudit.order_qty != glob_rec_poaudit.order_qty 
				OR l_rec_st_poaudit.unit_cost_amt != glob_rec_poaudit.unit_cost_amt 
				OR l_rec_st_poaudit.unit_tax_amt != glob_rec_poaudit.unit_tax_amt) THEN 
					LET l_kandoo_log_msg = "Purchase line ", 
					glob_rec_purchdetl.line_num USING "<<<<" clipped, 
					" Puchase ORDER number ", 
					glob_rec_purchdetl.order_num USING "<<<<<<<<" clipped, 
					" Line Update failed." 
					CALL errorlog(l_kandoo_log_msg) 
					LET l_err_cnt = l_err_cnt + 1 
					CONTINUE FOREACH 
				END IF 
				LET l_old_onorder_amt = l_old_onorder_amt 
				+ ((l_rec_st_poaudit.order_qty - l_rec_st_poaudit.received_qty) 
				* (l_rec_st_poaudit.unit_cost_amt + l_rec_st_poaudit.unit_tax_amt)) 
				IF glob_rec_poaudit.order_qty != l_rec_st_poaudit.order_qty 
				AND ( glob_rec_poaudit.unit_tax_amt != l_rec_st_poaudit.unit_tax_amt 
				OR glob_rec_poaudit.unit_cost_amt != l_rec_st_poaudit.unit_cost_amt) THEN 
					LET l_temp_order_qty = glob_rec_poaudit.order_qty 
					LET glob_rec_poaudit.order_qty = l_rec_st_poaudit.order_qty 
					CALL mod_po_line(p_cmpy_code, p_kandoouser_sign_on_code, glob_rec_purchhead.*, 
					glob_rec_purchdetl.*, 
					glob_rec_poaudit.*) 
					RETURNING l_err_stat 
					IF l_err_stat < 0 THEN 
						GOTO recovery 
					END IF 
					LET glob_rec_poaudit.order_qty = l_temp_order_qty 
				END IF 
				CALL mod_po_line(p_cmpy_code, p_kandoouser_sign_on_code, glob_rec_purchhead.*, 
				glob_rec_purchdetl.*, 
				glob_rec_poaudit.*) 
				RETURNING l_err_stat 
				IF l_err_stat < 0 THEN 
					GOTO recovery 
				END IF 
				### Adjust stock IF only product has changed
				IF glob_rec_poaudit.order_qty = l_rec_st_poaudit.order_qty 
				AND l_rec_pf_purchdetl.ref_text != glob_rec_purchdetl.ref_text 
				AND glob_rec_purchdetl.type_ind matches "IC" THEN 
					LET l_temp_order_qty = glob_rec_poaudit.order_qty 
					LET glob_rec_poaudit.order_qty = l_rec_st_poaudit.order_qty * -1 
					### Adjust stock with old product
					CALL po_adjustments( p_cmpy_code, p_kandoouser_sign_on_code, glob_rec_purchhead.*, 
					l_rec_pf_purchdetl.*, 
					glob_rec_poaudit.*, 
					"") 
					RETURNING l_err_stat 
					IF l_err_stat < 0 THEN 
						LET l_err_message =" Error in UPDATE of product details " 
						GOTO recovery 
					END IF 
					LET glob_rec_poaudit.order_qty = l_temp_order_qty 
					### Adjust stock with old product
					CALL po_adjustments(p_cmpy_code, p_kandoouser_sign_on_code, glob_rec_purchhead.*, 
					glob_rec_purchdetl.*, 
					glob_rec_poaudit.*, "") 
					RETURNING l_err_stat 
					IF l_err_stat < 0 THEN 
						LET l_err_message =" Error in UPDATE of product details " 
						GOTO recovery 
					END IF 
				END IF 

				UPDATE purchdetl 
				SET oem_text = glob_rec_purchdetl.oem_text, 
				ref_text = glob_rec_purchdetl.ref_text, 
				res_code = glob_rec_purchdetl.res_code, 
				job_code = glob_rec_purchdetl.job_code, 
				var_num = glob_rec_purchdetl.var_num, 
				activity_code = glob_rec_purchdetl.activity_code, 
				acct_code = glob_rec_purchdetl.acct_code, 
				desc_text = glob_rec_purchdetl.desc_text, 
				desc2_text = glob_rec_purchdetl.desc2_text, 
				note_code = glob_rec_purchdetl.note_code, 
				list_cost_amt = glob_rec_purchdetl.list_cost_amt, 
				disc_per = glob_rec_purchdetl.disc_per, 
				charge_amt = glob_rec_purchdetl.charge_amt, 
				uom_code = glob_rec_purchdetl.uom_code, 
				due_date = glob_rec_purchdetl.due_date 
				WHERE cmpy_code = glob_rec_purchdetl.cmpy_code 
				AND order_num = glob_rec_purchdetl.order_num 
				AND line_num = glob_rec_purchdetl.line_num 
			ELSE 
				CALL add_po_line(p_cmpy_code, p_kandoouser_sign_on_code, glob_rec_purchhead.*, 
				glob_rec_purchdetl.*, glob_rec_poaudit.*) 
			END IF 
			CALL po_line_info(p_cmpy_code, 
			glob_rec_purchhead.order_num, 
			glob_rec_purchdetl.line_num) 
			RETURNING l_rec_cu_poaudit.order_qty, 
			l_rec_cu_poaudit.received_qty, 
			l_rec_cu_poaudit.voucher_qty, 
			l_rec_cu_poaudit.unit_cost_amt, 
			l_rec_cu_poaudit.ext_cost_amt, 
			l_rec_cu_poaudit.unit_tax_amt, 
			l_rec_cu_poaudit.ext_tax_amt, 
			l_rec_cu_poaudit.line_total_amt 
			LET l_new_onorder_amt = l_new_onorder_amt 
			+ ((l_rec_cu_poaudit.order_qty - l_rec_cu_poaudit.received_qty) 
			* (l_rec_cu_poaudit.unit_cost_amt + l_rec_cu_poaudit.unit_tax_amt)) 
		END FOREACH 

		UPDATE purchhead 
		SET rev_num = glob_rec_purchhead.rev_num + 1, 
		rev_date = glob_rec_purchhead.rev_date, 
		note_code = glob_rec_purchhead.note_code 
		WHERE cmpy_code = p_cmpy_code 
		AND order_num = glob_rec_purchhead.order_num 

		LET l_new_onorder_amt = l_new_onorder_amt - l_old_onorder_amt 

		UPDATE vendor 
		SET onorder_amt = onorder_amt + l_new_onorder_amt 
		WHERE cmpy_code = p_cmpy_code 
		AND vend_code = glob_rec_purchhead.vend_code 

	COMMIT WORK 

	DELETE FROM t_purchdetl WHERE 1 = 1 
	DELETE FROM t_poaudit WHERE 1 = 1 

	IF l_err_cnt > 0 THEN 
		LET l_msgresp = kandoomsg("R",7016,l_err_cnt) 
		#7016 Errors encountered during UPDATE - refer get_settings_logFile()
	END IF 

	RETURN true 
END FUNCTION 


############################################################
# FUNCTION write_order(p_cmpy_code,p_kandoouser_sign_on_code)
#
# # Writes Purchase Order TO table FOR mode = "ADD"
############################################################
FUNCTION write_order(p_cmpy_code,p_kandoouser_sign_on_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 

	DEFINE idx SMALLINT 
	DEFINE l_counter SMALLINT 
	DEFINE l_err_continue CHAR(1) 
	DEFINE l_pr_valid_tran CHAR(1) 
	DEFINE l_err_message CHAR(40) 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_puparms RECORD LIKE puparms.* 
	DEFINE l_onorder_amt LIKE vendor.onorder_amt 
	DEFINE l_available_amt LIKE fundsapproved.limit_amt 
	DEFINE l_msgresp LIKE language.yes_flag 

	GOTO bypass 
	LABEL recovery: 
	LET l_err_continue = error_recover(l_err_message, status) 
	IF l_err_continue != "Y" THEN 
		EXIT program 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		LET l_msgresp = kandoomsg("U",1005,"") 
		#1005 Updating Database; Please wait.
		# UPDATE AR paramaters RECORD AND get ORDER number...
		LET l_err_message = "R11 - RU Parameter Update Failed" 
		DECLARE c_puparms CURSOR FOR 
		SELECT * FROM puparms 
		WHERE cmpy_code = p_cmpy_code 
		AND key_code = "1" 
		FOR UPDATE 
		OPEN c_puparms 
		FETCH c_puparms INTO l_rec_puparms.* 

		LET glob_rec_purchhead.order_num = l_rec_puparms.next_po_num 
		LET glob_rec_purchhead.rev_num = 0 
		LET l_rec_puparms.next_po_num = l_rec_puparms.next_po_num + 1 

		UPDATE puparms 
		SET next_po_num = l_rec_puparms.next_po_num 
		WHERE cmpy_code = p_cmpy_code 
		AND key_code = "1" 
		LET l_err_message = " R11 - Order Line Addition Failed" 

		DECLARE c_purchdetl2 CURSOR FOR 
		SELECT * FROM t_purchdetl 
		WHERE 1 = 1 
		ORDER BY line_num 
		LET idx = 0 
		LET l_onorder_amt = 0 

		FOREACH c_purchdetl2 INTO glob_rec_purchdetl.* 
			LET idx = idx + 1 
			SELECT * INTO glob_rec_poaudit.* FROM t_poaudit 
			WHERE line_num = glob_rec_purchdetl.line_num 
			IF glob_rec_purchdetl.type_ind IS NULL 
			OR glob_rec_poaudit.order_qty IS NULL 
			OR glob_rec_poaudit.line_total_amt IS NULL THEN 
				CONTINUE FOREACH 
			END IF 
			CALL check_funds(p_cmpy_code, 
			glob_rec_purchdetl.acct_code, 
			glob_rec_poaudit.line_total_amt, 
			glob_rec_purchdetl.line_num, 
			glob_rec_poaudit.year_num, 
			glob_rec_poaudit.period_num, 
			"R", 
			glob_rec_purchhead.order_num, 
			"N") 
			RETURNING l_pr_valid_tran, l_available_amt 

			IF NOT l_pr_valid_tran THEN 
				LET l_msgresp = kandoomsg("U",9944,"") 
				#9944 The available Approved funds has been exceeded.
				ROLLBACK WORK 
				RETURN false 
			END IF 

			LET glob_rec_purchdetl.cmpy_code = p_cmpy_code 
			LET glob_rec_purchdetl.vend_code = glob_rec_purchhead.vend_code 
			LET glob_rec_purchdetl.order_num = glob_rec_purchhead.order_num 
			LET glob_rec_purchdetl.line_num = idx 
			LET glob_rec_purchdetl.seq_num = 1 
			IF glob_rec_poaudit.ext_tax_amt IS NULL THEN 
				LET glob_rec_poaudit.ext_tax_amt = 0 
			END IF 
			IF glob_rec_poaudit.received_qty IS NULL THEN 
				LET glob_rec_poaudit.received_qty = 0 
			END IF 
			IF glob_rec_poaudit.voucher_qty IS NULL THEN 
				LET glob_rec_poaudit.voucher_qty = 0 
			END IF 

			IF glob_rec_purchdetl.type_ind matches "IC" 
			AND glob_rec_poaudit.order_qty >= 0 THEN 
				SELECT * INTO l_rec_product.* FROM product 
				WHERE part_code = glob_rec_purchdetl.ref_text 
				AND cmpy_code = p_cmpy_code 
				DECLARE c_prodstatus CURSOR FOR 
				SELECT * INTO l_rec_prodstatus.* FROM prodstatus 
				WHERE part_code = glob_rec_purchdetl.ref_text 
				AND ware_code = glob_rec_purchhead.ware_code 
				AND cmpy_code = p_cmpy_code 
				FOR UPDATE 
				LET l_err_message = "R11 - Failure Adding TO Product Status" 

				FOREACH c_prodstatus 
					LET l_rec_prodstatus.seq_num = l_rec_prodstatus.seq_num + 1 
					IF l_rec_prodstatus.onord_qty IS NULL THEN 
						LET l_rec_prodstatus.onord_qty = 0 
					END IF 
					# On Hand VALUES FOR non-stocked inventory items
					# are NOT adjusted
					IF l_rec_prodstatus.stocked_flag = "Y" THEN 
						LET l_rec_prodstatus.onord_qty = l_rec_prodstatus.onord_qty 
						+ ((glob_rec_poaudit.order_qty 
						* l_rec_product.pur_stk_con_qty) 
						* l_rec_product.stk_sel_con_qty) 
					END IF 
					UPDATE prodstatus 
					SET onord_qty = l_rec_prodstatus.onord_qty, 
					seq_num = l_rec_prodstatus.seq_num 
					WHERE cmpy_code = p_cmpy_code 
					AND part_code = l_rec_prodstatus.part_code 
					AND ware_code = l_rec_prodstatus.ware_code 
				END FOREACH 

			END IF 

			INSERT INTO purchdetl VALUES (glob_rec_purchdetl.*) 
			LET glob_rec_poaudit.cmpy_code = glob_rec_purchdetl.cmpy_code 
			LET glob_rec_poaudit.vend_code = glob_rec_purchdetl.vend_code 
			LET glob_rec_poaudit.po_num = glob_rec_purchdetl.order_num 
			LET glob_rec_poaudit.line_num = idx 
			LET glob_rec_poaudit.tran_num = 0 
			LET glob_rec_poaudit.tran_code = "AA" 
			LET glob_rec_poaudit.received_qty = 0 
			LET glob_rec_poaudit.voucher_qty = 0 
			SELECT tran_date, year_num, period_num 
			INTO glob_rec_poaudit.tran_date, glob_rec_poaudit.year_num, glob_rec_poaudit.period_num 
			FROM t_poaudit 
			WHERE line_num = glob_rec_purchdetl.line_num 
			LET glob_rec_poaudit.jour_num = 0 
			LET glob_rec_poaudit.entry_date = today 
			LET glob_rec_poaudit.entry_code = p_kandoouser_sign_on_code 
			LET glob_rec_poaudit.posted_flag = "N" 
			LET glob_rec_poaudit.orig_auth_flag = "N" 
			LET glob_rec_poaudit.now_auth_flag = "N" 
			LET glob_rec_poaudit.seq_num = glob_rec_purchdetl.seq_num 
			LET glob_rec_poaudit.desc_text = glob_rec_purchdetl.desc_text 
			LET glob_rec_poaudit.ext_cost_amt = glob_rec_poaudit.unit_cost_amt 
			* glob_rec_poaudit.order_qty 
			LET glob_rec_poaudit.ext_tax_amt = glob_rec_poaudit.unit_tax_amt 
			* glob_rec_poaudit.order_qty 
			INSERT INTO poaudit VALUES (glob_rec_poaudit.*) 
			LET l_onorder_amt = l_onorder_amt + glob_rec_poaudit.line_total_amt 
		END FOREACH 

		#### Confirm Order does NOT already exist
		SELECT count(*) INTO l_counter FROM purchhead 
		WHERE order_num = glob_rec_purchhead.order_num 
		AND cmpy_code = glob_rec_purchhead.cmpy_code 
		IF l_counter != 0 THEN 
			LET l_err_message = "P.O. No. ", 
			glob_rec_purchhead.order_num USING "<<<<<", 
			" Already Exists, Ref.RZP" 
			GOTO recovery 
		END IF 

		LET l_err_message = "R11 - Failure Adding TO Order Header" 

		INSERT INTO purchhead VALUES (glob_rec_purchhead.*) 
		DECLARE c_vendor2 CURSOR FOR 
		SELECT * FROM vendor 
		WHERE cmpy_code = glob_rec_purchhead.cmpy_code 
		AND vend_code = glob_rec_purchhead.vend_code 
		FOR UPDATE 
		OPEN c_vendor2 
		FETCH c_vendor2 INTO l_rec_vendor.* 
		LET l_err_message = "R11 Updating Vendor -last ORDER date" 

		UPDATE vendor 
		SET last_po_date = glob_rec_purchhead.order_date, 
		onorder_amt = onorder_amt + l_onorder_amt 
		WHERE cmpy_code = glob_rec_purchhead.cmpy_code 
		AND vend_code = glob_rec_purchhead.vend_code 

	COMMIT WORK 

	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	RETURN true 
END FUNCTION 
