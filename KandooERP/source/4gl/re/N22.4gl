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
GLOBALS "../re/N_RE_GLOBALS.4gl"
GLOBALS "../re/N2_GROUP_GLOBALS.4gl"
GLOBALS "../re/N22_GLOBALS.4gl"  
GLOBALS 
	DEFINE pr_delhead RECORD LIKE delhead.* 
	DEFINE pr_reqhead RECORD LIKE reqhead.* 
	DEFINE pa_deldetl array[100] OF 
	RECORD 
		line_num LIKE deldetl.line_num, 
		conf_qty LIKE deldetl.conf_qty, 
		desc_text LIKE reqdetl.desc_text, 
		req_qty LIKE reqdetl.req_qty, 
		remain_qty LIKE reqdetl.back_qty 
	END RECORD 
	DEFINE pr_period RECORD LIKE period.* 
	DEFINE arr_size SMALLINT 
END GLOBALS 
############################################################
# Module Scope Variables
############################################################
############################################################
# MAIN
#
# \brief module N22 - Delivery Confirmation
#                Confirms deliveries AND updates database accordingly
#                Note that because of large UPDATE it IS done in
#                two mutually exclusive transactions.
#
#       Transaction 1 Details - UPDATE deldetl    \
#                               UPDATE reqdetl     \  FOREACH
#                               #INSERT reqaudit     > delivery
#                               UPDATE prodstatus  /  line item
#                               INSERT prodledg   /
#
#       Transaction 2 Details - UPDATE reqhead  \
#                               UPDATE delhead  /     Once
############################################################
MAIN 
	DEFINE invalid_period SMALLINT 
	DEFINE ans CHAR(1) 

	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("N22") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_n_re() #init n/re module 

	OPEN WINDOW n129 with FORM "N129" 
	CALL windecoration_n("N129") -- albo kd-763 
	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,today) 
	RETURNING pr_period.year_num, 
	pr_period.period_num 
	CALL valid_period(glob_rec_kandoouser.cmpy_code,pr_period.year_num, 
	pr_period.period_num,TRAN_TYPE_INVOICE_IN) 
	RETURNING pr_period.year_num, 
	pr_period.period_num, 
	invalid_period 
	IF NOT invalid_period THEN 
		WHILE select_deliv() 
			IF confirm() THEN 
				CALL upd_details() 
				CALL upd_headers() 
				{
				           OPEN WINDOW w1_N22 AT 8,6 with 2 rows,50 columns    -- albo  KD-763
				              attributes(border, cyan, prompt line last)
				}
				display" Delivery Number: ",pr_delhead.del_num USING "<<<<<<<<", 
				" Confirmed Successfully " at 3,1 
				attribute(red) 
				--           prompt "             Any Key TO Continue" FOR CHAR ans  -- albo
				--              ATTRIBUTE(red)
				CALL eventsuspend() --LET ans = AnyKey(" Any key TO continue ",12,15) -- albo 
				--           CLOSE WINDOW w1_N22     -- albo  KD-763
			END IF 
			LET int_flag = false 
			LET quit_flag = false 
		END WHILE 
	END IF 
	CLOSE WINDOW n129 
END MAIN 


FUNCTION select_deliv() 
	DEFINE 
	pr_reqperson RECORD LIKE reqperson.* 

	CLEAR FORM 
	MESSAGE" Enter Requisition & Delivery Numbers FOR Confirmation " 
	attribute(yellow) 
	INPUT BY NAME pr_delhead.req_num, 
	pr_delhead.del_num WITHOUT DEFAULTS 

		ON ACTION "WEB-HELP" -- albo kd-377 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) 
			IF infield(req_num) THEN 
				LET pr_delhead.req_num = show_req(glob_rec_kandoouser.cmpy_code) 
				DISPLAY BY NAME pr_delhead.req_num 

				NEXT FIELD req_num 
			ELSE 
				#           LET pr_delhead.del_num = show_delv(glob_rec_kandoouser.cmpy_code,pr_delhead.req_num)
				DISPLAY BY NAME pr_delhead.del_num 

				NEXT FIELD del_num 
			END IF 
		AFTER FIELD req_num 
			SELECT reqhead.* 
			INTO pr_reqhead.* 
			FROM reqhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND req_num = pr_delhead.req_num 
			IF status = notfound THEN 
				error" Requisition Number NOT found - Try Window" 
				NEXT FIELD req_num 
			END IF 
			SELECT reqperson.* 
			INTO pr_reqperson.* 
			FROM reqperson 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND person_code = pr_reqhead.person_code 
			DISPLAY BY NAME pr_reqperson.person_code, 
			pr_reqperson.name_text 
			attribute(magenta) 
		AFTER FIELD del_num 
			SELECT * 
			INTO pr_delhead.* 
			FROM delhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND del_num = pr_delhead.del_num 
			IF status = notfound THEN 
				error" Delivery Number NOT found " 
				NEXT FIELD req_num 
			END IF 
			IF pr_delhead.req_num != pr_reqhead.req_num THEN 
				error" Delivery Number NOT found FOR this Requisition" 
				LET pr_delhead.req_num = pr_reqhead.req_num 
				NEXT FIELD req_num 
			END IF 
			IF pr_delhead.status_ind = 1 THEN 
				error" This Delivery has previously been Confirmed" 
				NEXT FIELD req_num 
			END IF 
			IF pr_delhead.status_ind = 2 THEN 
				error" This Delivery has been Cancelled " 
				NEXT FIELD req_num 
			END IF 
		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				SELECT delhead.* 
				INTO pr_delhead.* 
				FROM delhead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND del_num = pr_delhead.del_num 
				AND req_num = pr_delhead.req_num 
				IF status = notfound THEN 
					error" Delivery Number NOT found FOR this Requisition" 
					LET pr_delhead.req_num = pr_reqhead.req_num 
					NEXT FIELD req_num 
				ELSE 
					DISPLAY BY NAME pr_delhead.req_num, 
					pr_delhead.del_num, 
					pr_reqperson.person_code, 
					pr_reqperson.name_text 
					attribute(magenta) 
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


FUNCTION confirm() 
	DEFINE 
	pr_reqdetl RECORD LIKE reqdetl.*, 
	pr_deldetl RECORD LIKE deldetl.*, 
	idx, scrn SMALLINT, 
	pr_kandoo_conf_qty LIKE deldetl.conf_qty 

	DECLARE c0_deldetl CURSOR FOR 
	SELECT * 
	FROM deldetl 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND del_num = pr_delhead.del_num 
	ORDER BY cmpy_code, 
	del_num, 
	line_num 
	LET idx = 0 
	FOREACH c0_deldetl INTO pr_deldetl.* 
		LET idx = idx + 1 
		LET pa_deldetl[idx].line_num = pr_deldetl.line_num 
		LET pa_deldetl[idx].conf_qty = pr_deldetl.sched_qty 
		SELECT * INTO pr_reqdetl.* FROM reqdetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND req_num = pr_delhead.req_num 
		AND line_num = pr_deldetl.req_line_num 
		LET pa_deldetl[idx].desc_text = pr_reqdetl.desc_text 
		LET pa_deldetl[idx].req_qty = pr_reqdetl.req_qty 
		LET pa_deldetl[idx].remain_qty = pr_reqdetl.req_qty 
		- pr_reqdetl.confirmed_qty 
		- pr_deldetl.sched_qty 
	END FOREACH 
	MESSAGE" RETURN TO Alter Confirmed Qty - F9 FOR Line Detail", 
	" - ESC TO Continue" 
	attribute(yellow) 
	WHENEVER ERROR CONTINUE 
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	WHENEVER ERROR stop 
	CALL set_count(idx) 
	INPUT ARRAY pa_deldetl WITHOUT DEFAULTS FROM sr_deldetl.* 
		ON ACTION "WEB-HELP" -- albo kd-377 
			CALL onlinehelp(getmoduleid(),null) 
		ON KEY (F9) 
			SELECT req_line_num INTO pr_deldetl.req_line_num FROM deldetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND del_num = pr_delhead.del_num 
			AND line_num = pa_deldetl[idx].line_num 
			CALL display_line(glob_rec_kandoouser.cmpy_code,pr_reqdetl.*,1, 
			pr_reqhead.ware_code) 
			NEXT FIELD conf_qty 
		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			IF idx > arr_count() THEN 
				ERROR 
				" There are no more lines in the direction you are going" 
			END IF 
			SELECT * INTO pr_reqdetl.* FROM reqdetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND req_num = pr_delhead.req_num 
			AND line_num = pa_deldetl[idx].line_num 
			LET pr_deldetl.conf_qty = pa_deldetl[idx].conf_qty 
			NEXT FIELD conf_qty 
		BEFORE FIELD desc_text 
			SELECT sched_qty 
			INTO pr_kandoo_conf_qty 
			FROM deldetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND del_num = pr_delhead.del_num 
			AND line_num = pa_deldetl[idx].line_num 
			CASE 
				WHEN status = notfound 
					ERROR 
					" There are no more lines in the direction you are going" 
				WHEN pa_deldetl[idx].conf_qty IS NULL 
					LET pa_deldetl[idx].conf_qty = 0 
				WHEN pa_deldetl[idx].conf_qty < 0 
					error" Confirmed Quantity cannot be Less than Zero " 
					LET pa_deldetl[idx].conf_qty = pr_deldetl.conf_qty 
				WHEN pa_deldetl[idx].conf_qty > pr_kandoo_conf_qty 
					error" Confirmed Quantity cannot be Greater than ", 
					pr_kandoo_conf_qty USING "#######&.&&"," " 
					LET pa_deldetl[idx].conf_qty = pr_deldetl.conf_qty 
				OTHERWISE 
					LET pa_deldetl[idx].remain_qty= pa_deldetl[idx].remain_qty 
					+ pr_deldetl.conf_qty 
					- pa_deldetl[idx].conf_qty 
					LET pr_deldetl.conf_qty = pa_deldetl[idx].conf_qty 
					DISPLAY pa_deldetl[idx].remain_qty 
					TO sr_deldetl[scrn].remain_qty 

			END CASE 
			NEXT FIELD conf_qty 
		AFTER ROW 
			LET pa_deldetl[idx].conf_qty = pr_deldetl.conf_qty 
			DISPLAY pa_deldetl[idx].* 
			TO sr_deldetl[scrn].* 

		AFTER INPUT 
			LET arr_size = arr_count() 
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


FUNCTION upd_details() 
	DEFINE 
	pr_deldetl RECORD LIKE deldetl.*, 
	pr_reqdetl RECORD LIKE reqdetl.*, 
	pr_reqaudit RECORD LIKE reqaudit.*, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pr_prodledg RECORD LIKE prodledg.*, 
	pr_inparms RECORD LIKE inparms.*, 
	err_continue CHAR(1), 
	err_message CHAR(60), 
	i SMALLINT 

	SELECT inparms.* 
	INTO pr_inparms.* 
	FROM inparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 
	FOR i = 1 TO arr_size 
		IF pa_deldetl[i].line_num IS NULL 
		OR pa_deldetl[i].line_num = 0 THEN 
			CONTINUE FOR 
		END IF 
		GOTO bypass 
		LABEL recovery: 
		LET err_continue = error_recover(err_message, status) 
		IF err_continue != "Y" THEN 
			EXIT program 
		END IF 
		LABEL bypass: 
		WHENEVER ERROR GOTO recovery 
		BEGIN WORK 
			LET err_message = "N22 - Delivery Detail Update " 
			DECLARE c_deldetl CURSOR FOR 
			SELECT * 
			FROM deldetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND del_num = pr_delhead.del_num 
			AND line_num = pa_deldetl[i].line_num 
			FOR UPDATE 
			OPEN c_deldetl 
			FETCH c_deldetl INTO pr_deldetl.* 
			LET pr_deldetl.conf_qty = pa_deldetl[i].conf_qty 
			UPDATE deldetl 
			SET conf_qty = pr_deldetl.conf_qty 
			WHERE CURRENT OF c_deldetl 
			LET err_message = "N22 - Requisition Detail Update " 
			DECLARE c_reqdetl CURSOR FOR 
			SELECT * 
			FROM reqdetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND req_num = pr_delhead.req_num 
			AND line_num = pr_deldetl.req_line_num 
			FOR UPDATE 
			OPEN c_reqdetl 
			FETCH c_reqdetl INTO pr_reqdetl.* 
			LET pr_reqdetl.confirmed_qty = pr_reqdetl.confirmed_qty 
			+ pr_deldetl.conf_qty 
			LET pr_reqdetl.picked_qty = pr_reqdetl.picked_qty 
			- pr_deldetl.sched_qty 
			LET pr_reqdetl.back_qty = pr_reqdetl.back_qty 
			+ pr_deldetl.sched_qty 
			- pr_deldetl.conf_qty 
			LET pr_reqdetl.seq_num = pr_reqdetl.seq_num + 1 
			UPDATE reqdetl 
			SET confirmed_qty = pr_reqdetl.confirmed_qty, 
			picked_qty = pr_reqdetl.picked_qty, 
			back_qty = pr_reqdetl.back_qty, 
			seq_num = pr_reqdetl.seq_num 
			WHERE CURRENT OF c_reqdetl 
			#LET err_message = "N22 - Requisition Audit Insert "
			#LET pr_reqaudit.cmpy_code = pr_reqdetl.cmpy_code
			#LET pr_reqaudit.req_num = pr_reqdetl.req_num
			#LET pr_reqaudit.line_num = pr_reqdetl.line_num
			#LET pr_reqaudit.seq_num = pr_reqdetl.seq_num
			#LET pr_reqaudit.tran_type_ind = TRAN_TYPE_CREDIT_CR
			#LET pr_reqaudit.tran_date = today
			#LET pr_reqaudit.entry_code = glob_rec_kandoouser.sign_on_code
			#LET pr_reqaudit.unit_cost_amt = pr_reqdetl.unit_sales_amt
			#LET pr_reqaudit.unit_tax_amt = 0
			#LET pr_reqaudit.unit_sales_amt = pr_reqdetl.unit_sales_amt
			#LET pr_reqaudit.tran_qty = pr_deldetl.conf_qty
			#INSERT INTO reqaudit VALUES(pr_reqaudit.*)
			LET err_message = "N22 - Prodstatus Update " 
			DECLARE c_prodstatus CURSOR FOR 
			SELECT * 
			FROM prodstatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ware_code = pr_delhead.ware_code 
			AND part_code = pr_reqdetl.part_code 
			FOR UPDATE 
			OPEN c_prodstatus 
			FETCH c_prodstatus INTO pr_prodstatus.* 
			IF pr_prodstatus.stocked_flag = "Y" THEN 
				LET pr_prodstatus.onhand_qty = pr_prodstatus.onhand_qty 
				- pr_deldetl.conf_qty 
				LET pr_prodstatus.reserved_qty = pr_prodstatus.reserved_qty 
				- pr_deldetl.sched_qty 
				LET pr_prodstatus.back_qty = pr_prodstatus.back_qty 
				+ pr_deldetl.sched_qty 
				- pr_deldetl.conf_qty 
			END IF 
			LET pr_prodstatus.seq_num = pr_prodstatus.seq_num + 1 
			LET pr_prodstatus.last_sale_date = today 
			UPDATE prodstatus 
			SET onhand_qty = pr_prodstatus.onhand_qty, 
			reserved_qty = pr_prodstatus.reserved_qty, 
			back_qty = pr_prodstatus.back_qty, 
			last_sale_date = pr_prodstatus.last_sale_date, 
			seq_num = pr_prodstatus.seq_num 
			WHERE CURRENT OF c_prodstatus 
			LET err_message = "N22 - Prodledger Row Insert" 
			LET pr_prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET pr_prodledg.part_code = pr_prodstatus.part_code 
			LET pr_prodledg.ware_code = pr_prodstatus.ware_code 
			LET pr_prodledg.tran_date = today 
			LET pr_prodledg.seq_num = pr_prodstatus.seq_num 
			LET pr_prodledg.trantype_ind = "I" 
			LET pr_prodledg.year_num = pr_period.year_num 
			LET pr_prodledg.period_num = pr_period.period_num 
			LET pr_prodledg.source_text = pr_delhead.person_code 
			LET pr_prodledg.source_num = pr_reqdetl.req_num 
			LET pr_prodledg.tran_qty = 0 - pr_deldetl.conf_qty + 0 
			LET pr_prodledg.cost_amt = pr_deldetl.unit_cost_amt 
			* pr_deldetl.conf_qty 
			LET pr_prodledg.sales_amt = pr_deldetl.unit_sales_amt 
			* pr_deldetl.conf_qty 
			IF pr_inparms.hist_flag = "Y" THEN 
				LET pr_prodledg.hist_flag = "N" 
			ELSE 
				LET pr_prodledg.hist_flag = "Y" 
			END IF 
			LET pr_prodledg.post_flag = "N" 
			LET pr_prodledg.bal_amt = pr_prodstatus.onhand_qty 
			SELECT del_dept_text 
			INTO pr_prodledg.desc_text 
			FROM reqhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND req_num = pr_delhead.req_num 
			LET pr_prodledg.acct_code = pr_reqdetl.acct_code 
			INSERT INTO prodledg VALUES (pr_prodledg.*) 
		COMMIT WORK 
		WHENEVER ERROR stop 
	END FOR 
END FUNCTION 


FUNCTION upd_headers() 
	DEFINE 
	err_continue CHAR(1), 
	err_message CHAR(60) 

	GOTO bypass 
	LABEL recovery: 
	LET err_continue = error_recover(err_message, status) 
	IF err_continue != "Y" THEN 
		EXIT program 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		LET err_message = "N22 - Requisition Header Update " 
		SELECT unique cmpy_code 
		FROM reqdetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND req_num = pr_delhead.req_num 
		AND (confirmed_qty != req_qty) 
		IF status = notfound THEN 
			UPDATE reqhead 
			SET status_ind = 9 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND req_num = pr_delhead.req_num 
			AND status_ind != 0 
		ELSE 
			UPDATE reqhead 
			SET status_ind = 2 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND req_num = pr_delhead.req_num 
			AND status_ind != 0 
		END IF 
		LET err_message = "N22 - Delivery Header Update " 
		UPDATE delhead 
		SET status_ind = 1 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND del_num = pr_delhead.del_num 
	COMMIT WORK 
	WHENEVER ERROR stop 
END FUNCTION 
