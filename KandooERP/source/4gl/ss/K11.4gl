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

	Source code beautified by beautify.pl on 2019-12-31 14:28:26	$Id: $
}




#  K11 Add AND edit customer subscription records. Transactions created
#      depend on subscription inv_ind
#      1 invoice now: creates subscription RECORD AND invoice
#      2 invoice AT nominated date &
#      3 invoice on issue : creates subscription RECORD only
#      4 pre-paid : creates subscription , cashreceipt AND invoice
#      F2 TO cancel will create a credit FOR any unshipped quantity on
#      type 1 OR 4 subscriptions
#  ### Globals are defined in K11a as K11? functions are also called
#  ### FROM K15, K1A
#
#  K11.4gl :FUNCTION select_subs(where_text)
#           CONSTRUCT AND CURSOR preparation of subs.
#           IF WHERE text IS NOT NULL THEN CONSTRUCT IS bypassed
#  K11.4gl :FUNCTION scan_subs()
#           INPUT ARRAY of subs
#  K11.4gl :FUNCTION process_sub(pr_mode,pr_sub_num)
#           pr_mode = "ADD" OR "EDIT"
#           pr_sub_num = 0 IF ADD, valid subscription number IF EDIT
#           Calls create & edit functions INITIALIZE_sub,
#                                         header_entry, lineitem_scan,
#                                         sub_summary,K11_enter_receipt,
#                                         write_sub
#  K11.4gl :FUNCTION INITIALIZE_sub(pr_sub_num)
#           sets up subhead RECORD defaults
#  K11.4gl :FUNCTION enter_hold()
#           allows add/edit of subhead hold_code
#  K11a.4gl:FUNCTION header_entry(pr_mode)
#           add/edit of subhead details
#  K11b.4gl:FUNCTION lineitem_scan()
#           ARRAY add/edit of subdetl records
#  K11b.4gl:FUNCTION insert_line()
#           INITIALIZE defaults AND INSERT new t_subdetl
#  K11b.4gl:FUNCTION update_line()
#           Update t_subdetl record
#  K11b.4gl:FUNCTION disp_total()
#           displays subhead totals WHILE in lineitem_scan
#  K11b.4gl:FUNCTION validate_field(pr_field_num)
#           Called FROM lineitem scan AND sub_detail TO validate data entry
#  K11b.4gl:FUNCTION sched_issue(pr_verbose_num)
#           Creates subschedule records AND Calculates
#           subscription quantity FOR scheduled type products
#           pr_verbose_num = TRUE - Allows editing of issue dates & qty
#           pr_verbose_num = FALSE - no DISPLAY OR INPUT - returns qty
#  K11c.4gl:FUNCTION sub_detail()
#           called by F8 key FROM lineitem_scan
#           form add/edit of subdetl records
#  K11c.4gl:FUNCTION unit_price(pr_ware_code,pr_part_code,pr_level_ind)
#           gets unit_amt (price) details FROM prodstatus according TO
#           customer price level
#  K11c.4gl:FUNCTION unit_tax(pr_ware_code,pr_part_code,pr_unit_amt)
#           calculates unit_tax_amt
#  K11d.4gl:FUNCTION sub_summary(pr_mode)
#           INPUT of freight AND carrier details
#  K11d.4gl:FUNCTION K11_subhead_disp_summ() 
#           called FROM sub_summary
#           recalculates AND displays subhead totals
#  K11d.4gl:FUNCTION pay_detail()
#           called FROM header_entry() allows user TO change default term
#           AND tax codes
#  K11d.4gl:FUNCTION view_cust()
#           Opens a window showing customer balance details
#  K11e.4gl:FUNCTION insert_sub()
#           creates new subhead RECORD with appropriate defaults
#  K11e.4gl:FUNCTION K11_write_sub()
#           updates subhead, subdetl records
#           creates other transactions according TO subhead.inv_ind
#  K11f.4gl:FUNCTION auto_apply(pr_cash_num,pr_inv_num)
#           checks receipt AND invoice TO see IF application IS possible
#           IF application can be made THEN calls
#           FUNCTION receipt_apply (A31c.4gl)
#  K11f.4gl:FUNCTION cancel_sub(pr_sub_num)
#           reduces subs TO already issued qty so no further processing will
#           take place. IF sub IS invoiced THEN credit will be created FOR
#           non issued quantity
#  K11g.4gl:FUNCTION K11_enter_receipt(pr_mode)
#           enter cashreceipt details FOR prepaid subs.
#           Amount defaults TO unpaid amount of sub

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "K_SS_GLOBALS.4gl" 
GLOBALS "K1_GROUP_GLOBALS.4gl" 
GLOBALS "K11_GLOBALS.4gl" 

MAIN 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE pr_sub_num LIKE subhead.sub_num 
	DEFINE pr_prompt_text CHAR(60) 

	#Initial UI Init
	CALL setModuleId("K11") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 


	LET yes_flag = "Y" 
	LET no_flag = "N" 
	CALL create_table("subhead","t_subhead","","Y") 
	CALL create_table("subdetl","t_subdetl","","Y") 
	CALL create_table("subschedule","t_subschedule","","Y") 
	CALL create_table("cashreceipt","t_cashreceipt","","N") 
	CALL create_table("invoicehead","t_invoicehead","","N") 
	CALL create_table("invoicedetl","t_invoicedetl","","N") 
	SELECT * INTO pr_rec_kandoouser.* 
	FROM kandoouser 
	WHERE sign_on_code = glob_rec_kandoouser.sign_on_code 
	SELECT * INTO pr_glparms.* 
	FROM glparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_code = "1" 
	IF sqlca.sqlcode = notfound THEN 
		LET msgresp = kandoomsg("A",5001,"") 
		#A5001 GL Parameters are NOT found"
		EXIT program 
	END IF 
	SELECT * INTO pr_ssparms.* 
	FROM ssparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF sqlca.sqlcode = notfound THEN 
		LET msgresp = kandoomsg("K",5001,"") 
		#5001 " SS Parameters are NOT found"
		EXIT program 
	END IF 
	SELECT * INTO pr_arparms.* 
	FROM arparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 
	IF sqlca.sqlcode = notfound THEN 
		LET msgresp = kandoomsg("A",5002,"") 
		#5002 " AR Parameters are NOT found"
		EXIT program 
	ELSE 
	LET pr_prompt_text = pr_arparms.inv_ref1_text clipped, 
	"......................" 
	LET pr_inv_prompt = pr_prompt_text clipped 
END IF 
SELECT country.* INTO pr_country.* 
FROM country, 
company 
WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
AND country.country_code = company.country_code 
LET pr_prompt_text = pr_country.state_code_text clipped, 
".................." 
LET pr_country.state_code_text = pr_prompt_text 
LET pr_prompt_text = pr_country.post_code_text clipped, 
".................." 
LET pr_country.post_code_text = pr_prompt_text 
OPEN WINDOW k128 WITH FORM "K128" 
#ATTRIBUTE(border,white,MESSAGE line first)
OPEN WINDOW k127 WITH FORM "K127" 
attribute(border) 
LET pr_sub_num = process_sub("ADD","") 
CLOSE WINDOW k127 
IF pr_sub_num > 0 THEN 
	LET pr_prompt_text = "sub_num ='",pr_sub_num,"'" 
ELSE 
LET pr_prompt_text = NULL 
END IF 
WHILE select_subs(pr_prompt_text) 
CALL scan_subs() 
LET pr_prompt_text = NULL 
END WHILE 
CLOSE WINDOW k128 
END MAIN 


FUNCTION select_subs(where_text) 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	where_text CHAR(300), 
	query_text CHAR(400) 

	CLEAR FORM 
	IF where_text IS NULL THEN 
		LET msgresp = kandoomsg("U",1001,"") 
		#1001 Enter Selection - ESC TO Continue
		CONSTRUCT BY NAME where_text ON sub_num, 
		cust_code, 
		sub_type_code, 
		start_date, 
		end_date, 
		status_ind 

			ON ACTION "WEB-HELP" -- albo kd-374 
				CALL onlinehelp(getmoduleid(),null) 

		END CONSTRUCT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			RETURN false 
		ELSE 
		IF where_text IS NULL THEN 
			LET where_text = "1=1" 
		END IF 
		LET msgresp = kandoomsg("U",1002,"") 
		#1002 " Searching database - please wait "
	END IF 
END IF 
LET query_text = "SELECT * FROM subhead ", 
"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
"AND status_ind <> 'C' ", 
"AND ",where_text clipped," ", 
"ORDER BY sub_num" 
PREPARE s_subhead FROM query_text 
DECLARE c_subhead CURSOR FOR s_subhead 
RETURN true 
END FUNCTION 


FUNCTION scan_subs() 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	pr_sub_num LIKE subhead.sub_num, 
	pr_scroll_flag CHAR(1), 
	pa_subhead array[200] OF RECORD 
		scroll_flag CHAR(1), 
		sub_num LIKE subhead.sub_num, 
		cust_code LIKE subhead.cust_code, 
		sub_type_code LIKE subhead.sub_type_code, 
		start_date LIKE subhead.start_date, 
		end_date LIKE subhead.end_date, 
		status_ind LIKE subhead.status_ind 
	END RECORD, 
	pa_subhead2 array[200] OF RECORD 
		name_text LIKE customer.name_text 
	END RECORD, 
	pr_value SMALLINT, 
	i,j,del_cnt,idx,scrn SMALLINT 

	LET idx = 0 
	FOREACH c_subhead INTO pr_subhead.* 
		LET idx = idx + 1 
		LET pa_subhead[idx].scroll_flag = NULL 
		LET pa_subhead[idx].sub_num = pr_subhead.sub_num 
		LET pa_subhead[idx].cust_code = pr_subhead.cust_code 
		SELECT name_text 
		INTO pa_subhead2[idx].name_text 
		FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = pr_subhead.cust_code 
		IF sqlca.sqlcode = notfound THEN 
			LET pa_subhead2[idx].name_text = "**********" 
		END IF 
		LET pa_subhead[idx].start_date = pr_subhead.start_date 
		LET pa_subhead[idx].end_date = pr_subhead.end_date 
		LET pa_subhead[idx].sub_type_code = pr_subhead.sub_type_code 
		LET pa_subhead[idx].status_ind = pr_subhead.status_ind 
		IF idx = 200 THEN 
			LET msgresp = kandoomsg("U",9100,"200") 
			##First 200 orders selected only
			EXIT FOREACH 
		END IF 
	END FOREACH 
	IF idx = 0 THEN 
		LET msgresp = kandoomsg("U",9101,"") 
		#9101" No Orders Satisfied Selection Criteria "
		LET idx = 1 
		INITIALIZE pa_subhead[1].* TO NULL 
	END IF 
	OPTIONS DELETE KEY f36, 
	INSERT KEY f1 
	CALL set_count(idx) 
	LET msgresp = kandoomsg("U",1100,"") 

	#1100" F1 TO Add - F2 TO Cancel - RETURN TO Edit
	INPUT ARRAY pa_subhead WITHOUT DEFAULTS FROM sr_subhead.* 

		ON ACTION "WEB-HELP" -- albo kd-374 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE FIELD scroll_flag 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			LET pr_scroll_flag = pa_subhead[idx].scroll_flag 
			DISPLAY pa_subhead[idx].* 
			TO sr_subhead[scrn].* 

			DISPLAY BY NAME pa_subhead2[idx].name_text 

		AFTER FIELD scroll_flag 
			LET pa_subhead[idx].scroll_flag = pr_scroll_flag 
			DISPLAY pa_subhead[idx].scroll_flag 
			TO sr_subhead[scrn].scroll_flag 

			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF arr_curr() >= arr_count() 
				OR pa_subhead[idx+1].cust_code IS NULL THEN 
					LET msgresp=kandoomsg("U",9001,"") 
					NEXT FIELD scroll_flag 
				END IF 
			END IF 

		BEFORE FIELD sub_num 
			IF pa_subhead[idx].sub_num IS NOT NULL THEN 
				OPEN WINDOW k129 at 2,3 WITH FORM "K129" 
				attribute(border) 
				CALL process_sub("EDIT",pa_subhead[idx].sub_num) 
				RETURNING pr_sub_num 
				CLOSE WINDOW k129 
				SELECT sub_num, 
				cust_code, 
				sub_type_code, 
				start_date, 
				end_date, 
				status_ind 
				INTO pa_subhead[idx].sub_num, 
				pa_subhead[idx].cust_code, 
				pa_subhead[idx].sub_type_code, 
				pa_subhead[idx].start_date, 
				pa_subhead[idx].end_date, 
				pa_subhead[idx].status_ind 
				FROM subhead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND sub_num = pa_subhead[idx].sub_num 
			END IF 

			OPTIONS DELETE KEY f36, 
			INSERT KEY f1 
			NEXT FIELD scroll_flag 

		BEFORE INSERT 
			IF fgl_lastkey() = fgl_keyval("NEXTPAGE") THEN 
				CLEAR sr_subhead[scrn].* 
				NEXT FIELD scroll_flag #informix bug 
			END IF 
			OPEN WINDOW k127 at 2,3 WITH FORM "K127" 
			attribute(border) 
			LET pr_sub_num = process_sub("ADD","") 
			CLOSE WINDOW k127 
			OPTIONS DELETE KEY f36, 
			INSERT KEY f1 
			SELECT sub_num, 
			cust_code, 
			sub_type_code, 
			start_date, 
			end_date, 
			status_ind 
			INTO pa_subhead[idx].sub_num, 
			pa_subhead[idx].cust_code, 
			pa_subhead[idx].sub_type_code, 
			pa_subhead[idx].start_date, 
			pa_subhead[idx].end_date, 
			pa_subhead[idx].status_ind 
			FROM subhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND sub_num = pr_sub_num 
			IF status = notfound THEN 
				FOR i = idx TO 199 
					LET pa_subhead[i].* = pa_subhead[i+1].* 
					IF pa_subhead[i].cust_code IS NULL THEN 
						LET pa_subhead[i].sub_num = "" 
						LET pa_subhead[i].start_date = "" 
						LET pa_subhead[i].end_date = "" 
					END IF 
					IF scrn <= 14 THEN 
						DISPLAY pa_subhead[i].* 
						TO sr_subhead[scrn].* 

						LET scrn = scrn + 1 
					END IF 
					IF pa_subhead[i].cust_code IS NULL THEN 
						CALL set_count(i-1) 
						EXIT FOR 
					END IF 
				END FOR 
			ELSE 
			SELECT name_text INTO pa_subhead2[idx].name_text 
			FROM customer 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = pa_subhead[idx].cust_code 
		END IF 
		NEXT FIELD scroll_flag 

		ON KEY (F2) 
			LET pr_credit = false 
			IF pa_subhead[idx].sub_num IS NOT NULL THEN 
				IF pa_subhead[idx].status_ind = "P" 
				OR pa_subhead[idx].status_ind = "C" THEN 
					SELECT sum((inv_qty - issue_qty) * unit_amt) 
					INTO pr_value 
					FROM subdetl 
					WHERE sub_num = pa_subhead[idx].sub_num 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND inv_qty > issue_qty 
					IF status = 0 THEN 
						LET msgresp = kandoomsg("K",8015,pr_value) 
						IF msgresp <> "Y" THEN 
							NEXT FIELD scroll_flag 
						END IF 
						LET pr_credit = true 
					ELSE 
					LET msgresp = kandoomsg("K",8016,"") 
					#8016 this will cancel non issued qty only
					#  -  TO RETURN goods use K41
					IF msgresp <> "Y" THEN 
						NEXT FIELD scroll_flag 
					END IF 
				END IF 
			ELSE 
			LET msgresp = kandoomsg("K",8012,pa_subhead[idx].sub_num) 
		END IF 
		IF msgresp = "Y" THEN 
			LET msgresp = kandoomsg("U",1005,"") 
			#1005 Updating Database - pls. wait
			CALL initialize_sub(pa_subhead[idx].sub_num) 
			IF cancel_sub(pa_subhead[idx].sub_num) THEN 
				SELECT sub_num, 
				cust_code, 
				sub_type_code, 
				start_date, 
				end_date, 
				status_ind 
				INTO pa_subhead[idx].sub_num, 
				pa_subhead[idx].cust_code, 
				pa_subhead[idx].sub_type_code, 
				pa_subhead[idx].start_date, 
				pa_subhead[idx].end_date, 
				pa_subhead[idx].status_ind 
				FROM subhead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND sub_num = pa_subhead[idx].sub_num 
			END IF 
			LET msgresp = kandoomsg("U",1100,"") 
			#1100 F1 Add - F2 Cancel - RETURN Edit - F8 Session Defaults"
		END IF 
	END IF 
	NEXT FIELD scroll_flag 

		AFTER ROW 
			DISPLAY pa_subhead[idx].* 
			TO sr_subhead[scrn].* 

		ON KEY (control-w) 
			CALL kandoohelp("") 

	END INPUT 

	LET int_flag = false 
	LET quit_flag = false 
END FUNCTION 

#########################################################################
# FUNCTION process_sub(pr_mode,pr_sub_num)
#
#
#########################################################################
FUNCTION process_sub(pr_mode,pr_sub_num) 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	pr_mode CHAR(4), 
	pr_hold_sub CHAR(1), 
	pr_mask_code LIKE customertype.acct_mask_code, 
	pr_substype RECORD LIKE substype.*, 
	pr_sub_num LIKE subhead.sub_num 

	CALL initialize_sub(pr_sub_num) 
	LET pr_sub_num = NULL 
	DISPLAY pr_country.state_code_text, 
	pr_country.post_code_text, 
	pr_country.state_code_text, 
	pr_country.post_code_text, 
	pr_inv_prompt 
	TO sr_prompts[1].*, 
	sr_prompts[2].*, 
	inv_ref1_text 
	attribute(white) 
	WHILE header_entry(pr_mode) 
		IF pr_customer.corp_cust_code IS NOT NULL AND 
		pr_customer.corp_cust_ind = "1" THEN 
			SELECT type_code INTO pr_customer.type_code 
			FROM customer 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = pr_customer.corp_cust_code 
		END IF 
		SELECT acct_mask_code INTO pr_mask_code 
		FROM customertype 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND type_code = pr_customer.type_code 
		AND acct_mask_code IS NOT NULL 
		IF status = notfound THEN 
			LET pr_subhead.acct_override_code = 
			build_mask(glob_rec_kandoouser.cmpy_code,pr_subhead.acct_override_code, 
			pr_rec_kandoouser.acct_mask_code) 
		ELSE 
		LET pr_subhead.acct_override_code = 
		build_mask(glob_rec_kandoouser.cmpy_code,pr_subhead.acct_override_code,pr_mask_code) 
	END IF 
	IF NOT valid_trans_num(glob_rec_kandoouser.cmpy_code,TRAN_TYPE_INVOICE_IN, pr_subhead.acct_override_code) THEN 
		#7031Warning: Automatic Invoice Numbering NOT Set up"
		LET msgresp=kandoomsg("A",7031,"") 
	END IF 
	DELETE FROM t_subhead 
	WHERE rowid = pr_growid 
	INSERT INTO t_subhead VALUES (pr_subhead.*) 
	LET pr_growid = sqlca.sqlerrd[6] 
	SELECT unique 1 FROM t_subdetl 
	WHERE sub_num = pr_subhead.sub_num OR sub_num IS NULL 
	IF status = notfound THEN 
		DELETE FROM t_subdetl WHERE 1=1 
		INSERT INTO t_subdetl 
		SELECT * FROM subdetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND sub_num = pr_subhead.sub_num 
		DELETE FROM t_subschedule WHERE 1=1 
		INSERT INTO t_subschedule 
		SELECT * FROM subschedule 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND sub_num = pr_subhead.sub_num 
	END IF 
	OPEN WINDOW k130 WITH FORM "K130" 
	#   ATTRIBUTE(border,white)
	WHILE lineitem_scan() 
		OPEN WINDOW k132 WITH FORM "K132" 
		#   ATTRIBUTE(border)
		WHILE sub_summary(pr_mode) 
			LET pr_paid_amt = 0 
			IF pr_mode = "ADD" THEN 
				SELECT * INTO pr_substype.* 
				FROM substype 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND type_code = pr_subhead.sub_type_code 
				IF status = 0 THEN 
					IF pr_substype.inv_ind = "4" THEN ## prepaid 
						LET pr_subhead.hold_code = NULL 
						LET pr_paid_amt = K11_enter_receipt(pr_mode) 
						IF pr_paid_amt <> pr_subhead.total_amt THEN 
							LET pr_subhead.hold_code = pr_ssparms.pp_hold_code 
							UPDATE t_subhead SET hold_code = pr_subhead.hold_code 
							LET msgresp = kandoomsg("K",7001,"") 
							#7001 Subscription placed on hold until fully paid
						END IF 
					END IF 
				END IF 
			END IF 
			#OPEN WINDOW w1_K11 AT 8,6 with 2 rows,64 columns  --huho
			#   ATTRIBUTE(border)
			MENU " subscriptions" 
				BEFORE MENU 
					IF pr_mode = "ADD" THEN 
						SELECT * INTO pr_substype.* 
						FROM substype 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND type_code = pr_subhead.sub_type_code 
						IF pr_substype.inv_ind = "4" THEN 
							HIDE option "Receipt" 
						END IF 
					END IF 
				ON ACTION "WEB-HELP" -- albo kd-374 
					CALL onlinehelp(getmoduleid(),null) 
				COMMAND "Save" " Save subscription TO database" 
					LET msgresp = kandoomsg("E",1005,"") 
					#1005 Updating Database - pls. wait
					IF pr_mode = "ADD" THEN 
						IF insert_sub() THEN 
							LET pr_sub_num = K11_write_sub(pr_mode) 
						ELSE 
						LET quit_flag = true 
					END IF 
				ELSE 
				LET pr_sub_num = K11_write_sub(pr_mode) 
			END IF 
			EXIT MENU 
				COMMAND "Receipt" " Enter cash receipt FOR subscription" 
					LET pr_paid_amt = K11_enter_receipt(pr_mode) 
				COMMAND "Hold" " Hold subscription TO prevent further processing" 
					IF enter_hold() THEN 
					END IF 
				COMMAND "Discard" " Discard (new sub/changed sub) changes" 
					DELETE FROM t_subhead WHERE 1=1 
					DELETE FROM t_subdetl WHERE 1=1 
					DELETE FROM t_subschedule WHERE 1=1 
					DELETE FROM t_cashreceipt WHERE 1=1 
					LET pr_sub_num = 0 
					EXIT MENU 
				COMMAND KEY("E",interrupt)"Exit" 
					" RETURN TO editting subscription" 
					LET quit_flag = true 
					EXIT MENU 
				COMMAND KEY (control-w) 
					CALL kandoohelp("") 
			END MENU 
			#CLOSE WINDOW w1_K11
			DELETE FROM t_cashreceipt WHERE 1=1 
			DELETE FROM t_invoicedetl WHERE 1=1 
			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
			ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 
	CLOSE WINDOW k132 
	IF pr_sub_num IS NOT NULL THEN 
		EXIT WHILE 
	END IF 
END WHILE 
CLOSE WINDOW k130 
IF pr_sub_num IS NOT NULL THEN 
	EXIT WHILE 
END IF 
END WHILE 
RETURN pr_sub_num 
END FUNCTION 


FUNCTION initialize_sub(pr_sub_num) 
	DEFINE 
	pr_sub_num LIKE subhead.sub_num 

	DELETE FROM t_subhead 
	DELETE FROM t_subdetl 
	DELETE FROM t_subschedule 
	INITIALIZE pr_customer.* TO NULL 
	SELECT * INTO pr_subhead.* 
	FROM subhead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND sub_num = pr_sub_num 
	IF status = notfound THEN 
		INITIALIZE pr_subhead.* TO NULL 
		LET pr_subhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pr_subhead.ware_code = "" 
		LET pr_subhead.entry_code = glob_rec_kandoouser.sign_on_code 
		LET pr_subhead.entry_date = today 
		LET pr_subhead.rev_date = today 
		LET pr_subhead.sub_date = today 
		LET pr_subhead.goods_amt = 0 
		LET pr_subhead.freight_amt = 0 
		LET pr_subhead.hand_amt = 0 
		LET pr_subhead.freight_tax_amt = 0 
		LET pr_subhead.hand_tax_amt = 0 
		LET pr_subhead.tax_amt = 0 
		LET pr_subhead.disc_amt = 0 
		LET pr_subhead.total_amt = 0 
		LET pr_subhead.cost_amt = 0 
		LET pr_subhead.status_ind = "U" 
		LET pr_subhead.line_num = 0 
		LET pr_subhead.rev_num = 0 
		LET pr_subhead.prepaid_flag = no_flag 
		LET pr_subhead.freight_inv_amt = 0 
		LET pr_subhead.hand_inv_amt = 0 
		LET pr_subhead.frttax_inv_amt = 0 
		LET pr_subhead.hndtax_inv_amt = 0 
		LET pr_currsub_amt = 0 
		LET pr_subhead.corp_flag = "N" 
	END IF 
	INSERT INTO t_subhead VALUES (pr_subhead.*) 
	LET pr_growid = sqlca.sqlerrd[6] 
END FUNCTION 

FUNCTION enter_hold() 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE pr_holdreas RECORD LIKE holdreas.* 
	DEFINE l_temp_text CHAR(500) #huho moved FROM GLOBALS 

	OPEN WINDOW k133 WITH FORM "K133" 

	LET msgresp=kandoomsg("U",1020,"Hold Code") 
	#1020 Subscription Hold Code
	LET pr_holdreas.hold_code = pr_subhead.hold_code 

	INPUT BY NAME pr_holdreas.hold_code WITHOUT DEFAULTS 

		ON ACTION "WEB-HELP" -- albo kd-374 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) 
			LET l_temp_text = show_hold(glob_rec_kandoouser.cmpy_code,"") 
			IF l_temp_text IS NOT NULL THEN 
				LET pr_holdreas.hold_code = l_temp_text 
			END IF 
			NEXT FIELD hold_code 

		BEFORE FIELD hold_code 
			SELECT reason_text 
			INTO pr_holdreas.reason_text 
			FROM holdreas 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND hold_code = pr_holdreas.hold_code 
			DISPLAY BY NAME pr_holdreas.reason_text 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF pr_holdreas.hold_code IS NOT NULL THEN 
					SELECT unique 1 FROM holdreas 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND hold_code = pr_holdreas.hold_code 
					IF status = notfound THEN 
						LET msgresp=kandoomsg("E",9045,"") 
						#9045" Sales ORDER hold code NOT found"
						NEXT FIELD hold_code 
					END IF 
				END IF 
			END IF 

		ON KEY (control-w) 
			CALL kandoohelp("") 

	END INPUT 

	CLOSE WINDOW k133 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
	LET pr_subhead.hold_code = pr_holdreas.hold_code 
	UPDATE t_subhead 
	SET hold_code = pr_subhead.hold_code 
	WHERE rowid = pr_growid 
	RETURN true 
END IF 
END FUNCTION 
