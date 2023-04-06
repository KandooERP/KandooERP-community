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
{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module Q11 - Maintainence program FOR Sales Quotations
#                This program allows the addition AND editting of
#                sales quotations entered FOR advanced ORDER entry.
#
#          Q11.4gl
#              - main line structure
#              - process_order() FUNCTION that controls everything
#              - INITIALIZE_ord() FUNCTION which IS called between each
#                   ORDER add/edit TO reset GLOBALS & CLEAR temp tables.
#
#          Q11a.4gl
#              - header_entry()  retrieves first SCREEN INPUT FOR add/edit.
#              - INITIALIZE_ord() resets all GLOBALS AND temp tables
#
#          Q11b.4gl
#              - pay_detail() retrieves second SCREEN INPUT orders.
#                             Enter terms/tax/conditions etc...
#              - view_cust()  Allows user TO view customer account
#                             details. ie: balance, credit available
#              - commission() Allows user TO distribute sales commission
#                             TO salespersons (iff customer.share_flag = Y)
#          Q11c.4gl
#              - offer_scan() Allows user TO nominate offers AND quantities of
#
#          Q11d.4gl
#              - lineitem_scan()  displays a scan of ORDER line item AND allows
#                                 add/edit/delete of such.
#
#          Q11e.4gl
#              - lineitem_entry() Detailed line entry (window FOR 1 line).
#                                 Called FROM lineitems FOR detailed entry
#
#          Q11f.4gl
#              - checkoffer() displays a scan of special offers used
#                             AND performs checking calculations on each.
#
#          Q11g.4gl
#              - summary()    Allows user TO enter freight handling AND
#                             shipping instruction FOR this ORDER
#
#          Q11h.4gl
#              - insert_order() Inserts  a blank new ORDER INTO the database


###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../qe/Q_QE_GLOBALS.4gl"
GLOBALS "../qe/Q1_GROUP_GLOBALS.4gl" 
GLOBALS "../qe/Q11_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
#######################################################################
# MAIN
#
#
#######################################################################
MAIN 
	DEFINE pr_order_num LIKE quotehead.order_num 
	DEFINE pr_prompt_text CHAR(40) 

	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("Q11") -- albo 
	CALL ui_init(0) #initial ui init 

	CALL authenticate(getmoduleid()) 
	CALL init_q_qe() 

	LET yes_flag = "Y" 
	LET no_flag = "N" 
	LET pr_globals.quote_date = today 
	LET pr_globals.ship_date = today 
	LET pr_globals.def_paydetl_flag = no_flag 
	LET pr_globals.owner_text = glob_rec_kandoouser.sign_on_code 
	#CALL create_table("saleshare","t_saleshare","","N")
	#CALL create_table("orderlog","t_orderlog","","N")
	CALL create_table("quotedetl","t_quotedetl","","Y") 
	CALL create_table("quotedetl","t2_quotedetl","","Y") 
	CALL create_table("quotedetl","t3_quotedetl","","Y") 
	CALL cr_offer_tables() 


	CALL db_opparms_get_rec(UI_OFF,"1") RETURNING glob_rec_opparms.*
	IF glob_rec_opparms.key_num IS NULL AND glob_rec_opparms.cmpy_code IS NULL THEN 
		CALL fgl_winmessage("Configuration Error - Operational Parameters missing (Program eZP)",kandoomsg2("E",5002,""),"ERROR") #5002 " OE Parameters are NOT found" #HuHo 2.12.2020: Was "OZP" which we haven't got and I changed it to "EZP"
		EXIT program 
	END IF 

	 
	SELECT * INTO pr_arparms.* 
	FROM arparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("A",5002,"") 
		#5002 " AR Parameters are NOT found"
		EXIT program 
	ELSE 
		LET pr_prompt_text = pr_arparms.inv_ref1_text clipped, 
		".................." 
		LET pr_arparms.inv_ref1_text = pr_prompt_text clipped 
	END IF 
	SELECT country.* INTO pr_country.* 
	FROM country, company 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND country.country_code = company.country_code 
	LET pr_prompt_text = pr_country.state_code_text clipped, 
	".................." 
	LET pr_country.state_code_text = pr_prompt_text 
	LET pr_prompt_text = pr_country.post_code_text clipped, 
	".................." 
	LET pr_country.post_code_text = pr_prompt_text 
	OPEN WINDOW q210 with FORM "Q210" -- alch kd-747 
	CALL windecoration_q("Q210") -- alch kd-747 
	IF num_args() = 0 THEN 
		OPEN WINDOW q211 with FORM "Q211" -- alch kd-747 
		CALL windecoration_q("Q211") -- alch kd-747 
		LET pr_order_num = process_order("ADD","") 
		CLOSE WINDOW q211 
	ELSE 
		LET pr_order_num = arg_val(1) 
	END IF 
	IF pr_order_num > 0 THEN 
		LET pr_prompt_text = "order_num ='",pr_order_num,"'" 
	ELSE 
		LET pr_prompt_text = NULL 
	END IF 
	WHILE select_orders(pr_prompt_text) 
		CALL scan_orders() 
		LET pr_prompt_text = NULL 
	END WHILE 
	CLOSE WINDOW q210 
END MAIN 


FUNCTION select_orders(where_text) 
	DEFINE 
	where_text CHAR(300), 
	query_text CHAR(400) 

	CLEAR FORM 
	IF where_text IS NULL THEN 
		LET msgresp = kandoomsg("E",1054,"") 
		#1054 Enter Selection - ESC TO Continue F8 Session Defs
		CONSTRUCT BY NAME where_text ON order_num, 
		cust_code, 
		quote_date, 
		total_amt, 
		valid_date, 
		hold_code, 
		status_ind 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","Q11","const-order_num-1") -- alch kd-501 
			ON ACTION "WEB-HELP" -- albo kd-369 
				CALL onlinehelp(getmoduleid(),null) 
			ON KEY (F8) 
				CALL enter_defaults() 
			ON KEY (control-w) 
				CALL kandoohelp("") 
		END CONSTRUCT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			RETURN false 
		END IF 
		IF pr_globals.owner_text IS NOT NULL THEN 
			LET where_text = where_text clipped, 
			" AND entry_code = '",pr_globals.owner_text,"'" 
		END IF 
	END IF 
	LET msgresp = kandoomsg("E",1002,"") 
	#1002 " Searching database - please wait "
	LET query_text = "SELECT * FROM quotehead ", 
	" WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND ",where_text clipped," ", 
	" AND status_ind NOT in ('D','C') ", 
	" ORDER BY order_num" 
	PREPARE s_quotehead FROM query_text 
	DECLARE c_quotehead CURSOR FOR s_quotehead 
	RETURN true 
END FUNCTION 


FUNCTION scan_orders() 
	DEFINE 
	pr_order_num LIKE quotehead.order_num, 
	pr_scroll_flag CHAR(1), 
	pa_quotehead array[200] OF RECORD 
		scroll_flag CHAR(1), 
		order_num LIKE quotehead.order_num, 
		cust_code LIKE quotehead.cust_code, 
		quote_date LIKE quotehead.quote_date, 
		total_amt LIKE quotehead.total_amt, 
		valid_date LIKE quotehead.valid_date, 
		hold_code LIKE quotehead.hold_code, 
		status_ind LIKE quotehead.status_ind 
	END RECORD, 
	pa_quotehead2 array[200] OF RECORD 
		name_text LIKE customer.name_text, 
		cond_code LIKE quotehead.cond_code, 
		desc_text LIKE pricing.desc_text 
	END RECORD, 
	pr_orderlog RECORD LIKE orderlog.*, 
	pr_status_ind CHAR(1), 
	change_status,i,j,del_cnt,idx,scrn SMALLINT 

	LET idx = 0 
	FOREACH c_quotehead INTO pr_quotehead.* 
		LET idx = idx + 1 
		LET pa_quotehead[idx].scroll_flag = NULL 
		LET pa_quotehead[idx].order_num = pr_quotehead.order_num 
		LET pa_quotehead[idx].cust_code = pr_quotehead.cust_code 
		SELECT name_text INTO pa_quotehead2[idx].name_text FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = pr_quotehead.cust_code 
		IF status = notfound THEN 
			LET pa_quotehead2[idx].name_text = "**********" 
		END IF 
		LET pa_quotehead2[idx].cond_code = pr_quotehead.cond_code 
		SELECT desc_text INTO pa_quotehead2[idx].desc_text FROM condsale 
		WHERE cond_code = pa_quotehead2[idx].cond_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pa_quotehead[idx].quote_date = pr_quotehead.quote_date 
		LET pa_quotehead[idx].total_amt = pr_quotehead.total_amt 
		LET pa_quotehead[idx].hold_code = pr_quotehead.hold_code 
		LET pa_quotehead[idx].status_ind = pr_quotehead.status_ind 
		LET pa_quotehead[idx].valid_date = pr_quotehead.valid_date 
		IF idx = 200 THEN 
			LET msgresp = kandoomsg("E",9048,"200") 
			##First 200 orders selected only
			EXIT FOREACH 
		END IF 
	END FOREACH 
	IF idx = 0 THEN 
		LET msgresp = kandoomsg("E",9049,"") 
		#9049" No Orders Satisfied Selection Criteria "
		LET idx = 1 
		INITIALIZE pa_quotehead[idx].* TO NULL 
		INITIALIZE pa_quotehead2[idx].* TO NULL 
	END IF 
	OPTIONS DELETE KEY f36, 
	INSERT KEY f1 
	CALL set_count(idx) 
	LET msgresp = kandoomsg("Q",1014,"") 
	#1014" F1 TO Add - F2 TO Cancel - RETURN TO Edit - F8 Session Defaults"
	INPUT ARRAY pa_quotehead WITHOUT DEFAULTS FROM sr_quotehead.* 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","Q11","inp_arr-sr_quotehead-1") -- alch kd-501 
		ON ACTION "WEB-HELP" -- albo kd-369 
			CALL onlinehelp(getmoduleid(),null) 
		ON KEY (F8) 
			CALL enter_defaults() 
		ON KEY (F5) 
			IF infield(scroll_flag) THEN 
				IF pa_quotehead[idx].order_num IS NOT NULL THEN 
					DECLARE c_edithold CURSOR FOR 
					SELECT * INTO pr_quotehead.* FROM quotehead 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND order_num = pa_quotehead[idx].order_num 
					FOR UPDATE 
					SELECT * INTO pr_quotehead.* FROM quotehead 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND order_num = pa_quotehead[idx].order_num 
					IF pr_quotehead.status_ind = "X" THEN 
						LET msgresp = kandoomsg("E",9254,"") 
						#9254 "Order has been locked by another process"
						NEXT FIELD scroll_flag 
					END IF 
					BEGIN WORK 
						WHENEVER ERROR CONTINUE 
						OPEN c_edithold 
						IF status <> 0 THEN 
							LET msgresp = kandoomsg("E",9253,"") 
							#9253 "Unable TO lock ORDER FOR edit"
							ROLLBACK WORK 
							WHENEVER ERROR stop 
							NEXT FIELD scroll_flag 
						END IF 
						WHENEVER ERROR CONTINUE 
						FETCH c_edithold 
						IF status <> 0 THEN 
							LET msgresp = kandoomsg("E",9253,"") 
							#9253 "Unable TO lock ORDER FOR edit"
							ROLLBACK WORK 
							WHENEVER ERROR stop 
							NEXT FIELD scroll_flag 
						END IF 
						IF pr_quotehead.status_ind = "X" THEN 
							LET msgresp = kandoomsg("E",9254,"") 
							#9254 "Order has been locked by another process"
							ROLLBACK WORK 
							WHENEVER ERROR stop 
							NEXT FIELD scroll_flag 
						END IF 
						LET pr_status_ind = pr_quotehead.status_ind 
						UPDATE quotehead SET status_ind = "X" 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND order_num = pr_quotehead.order_num 
						IF status <> 0 THEN 
							LET msgresp = kandoomsg("E",9253,"") 
							#9253 "Unable TO lock ORDER FOR edit"
							ROLLBACK WORK 
							WHENEVER ERROR stop 
							NEXT FIELD scroll_flag 
						END IF 
					COMMIT WORK 
					WHENEVER ERROR stop 
					IF enter_hold() THEN 
						UPDATE quotehead 
						SET hold_code = pr_quotehead.hold_code, 
						status_ind = pr_status_ind 
						WHERE order_num = pa_quotehead[idx].order_num 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code 
						LET pa_quotehead[idx].hold_code = pr_quotehead.hold_code 
					ELSE 
						UPDATE quotehead 
						SET hold_code = pr_quotehead.hold_code, 
						status_ind = pr_status_ind 
						WHERE order_num = pa_quotehead[idx].order_num 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					END IF 
				END IF 
				OPTIONS DELETE KEY f36, 
				INSERT KEY f1 
				NEXT FIELD scroll_flag 
			END IF 
		BEFORE FIELD scroll_flag 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			LET pr_scroll_flag = pa_quotehead[idx].scroll_flag 
			INITIALIZE pr_quotehead.* TO NULL 
			SELECT * INTO pr_quotehead.* FROM quotehead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND order_num = pa_quotehead[idx].order_num 
			LET pa_quotehead[idx].scroll_flag = NULL 
			LET pa_quotehead[idx].order_num = pr_quotehead.order_num 
			LET pa_quotehead[idx].cust_code = pr_quotehead.cust_code 
			SELECT name_text INTO pa_quotehead2[idx].name_text FROM customer 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = pr_quotehead.cust_code 
			IF status = notfound THEN 
				LET pa_quotehead2[idx].name_text = "**********" 
			END IF 
			LET pa_quotehead2[idx].cond_code = pr_quotehead.cond_code 
			SELECT desc_text INTO pa_quotehead2[idx].desc_text FROM condsale 
			WHERE cond_code = pa_quotehead2[idx].cond_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET pa_quotehead[idx].quote_date = pr_quotehead.quote_date 
			LET pa_quotehead[idx].total_amt = pr_quotehead.total_amt 
			LET pa_quotehead[idx].hold_code = pr_quotehead.hold_code 
			LET pa_quotehead[idx].status_ind = pr_quotehead.status_ind 
			LET pa_quotehead[idx].valid_date = pr_quotehead.valid_date 
			DISPLAY pa_quotehead[idx].* TO sr_quotehead[scrn].* 

			DISPLAY BY NAME pa_quotehead2[idx].name_text, 
			pa_quotehead2[idx].cond_code, 
			pa_quotehead2[idx].desc_text 

		AFTER FIELD scroll_flag 
			LET pa_quotehead[idx].scroll_flag = pr_scroll_flag 
			DISPLAY pa_quotehead[idx].scroll_flag 
			TO sr_quotehead[scrn].scroll_flag 

			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF arr_curr() >= arr_count() 
				OR pa_quotehead[idx+1].cust_code IS NULL THEN 
					LET msgresp=kandoomsg("E",9001,"") 
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
		BEFORE FIELD order_num 
			IF pa_quotehead[idx].order_num IS NOT NULL THEN 
				DECLARE c_editorder CURSOR FOR 
				SELECT * INTO pr_quotehead.* 
				FROM quotehead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND order_num = pa_quotehead[idx].order_num 
				FOR UPDATE 
				SELECT * INTO pr_quotehead.* FROM quotehead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND order_num = pa_quotehead[idx].order_num 
				IF pr_quotehead.status_ind = "X" THEN 
					LET msgresp = kandoomsg("E",9254,"") 
					#9254 "Order has been locked by another process"
					NEXT FIELD scroll_flag 
				END IF 
				BEGIN WORK 
					WHENEVER ERROR CONTINUE 
					OPEN c_editorder 
					IF status <> 0 THEN 
						LET msgresp = kandoomsg("E",9253,"") 
						#9253 "Unable TO lock ORDER FOR edit"
						ROLLBACK WORK 
						WHENEVER ERROR stop 
						NEXT FIELD scroll_flag 
					END IF 
					WHENEVER ERROR CONTINUE 
					FETCH c_editorder 
					IF status <> 0 THEN 
						LET msgresp = kandoomsg("E",9253,"") 
						#9253 "Unable TO lock ORDER FOR edit"
						ROLLBACK WORK 
						WHENEVER ERROR stop 
						NEXT FIELD scroll_flag 
					END IF 
					IF pr_quotehead.status_ind = "X" THEN 
						LET msgresp = kandoomsg("E",9254,"") 
						#9254 "Order has been locked by another process"
						ROLLBACK WORK 
						WHENEVER ERROR stop 
						NEXT FIELD scroll_flag 
					END IF 
					LET pr_status_ind = pr_quotehead.status_ind 
					UPDATE quotehead SET status_ind = "X" 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND order_num = pr_quotehead.order_num 
					IF status <> 0 THEN 
						LET msgresp = kandoomsg("E",9253,"") 
						#9253 "Unable TO lock ORDER FOR edit"
						ROLLBACK WORK 
						WHENEVER ERROR stop 
						NEXT FIELD scroll_flag 
					END IF 
				COMMIT WORK 
				WHENEVER ERROR stop 
				OPEN WINDOW q220 with FORM "Q220" -- alch kd-747 
				CALL windecoration_q("Q220") -- alch kd-747 
				CALL process_order("EDIT",pa_quotehead[idx].order_num) 
				RETURNING pr_order_num 
				CLOSE WINDOW q220 
				SELECT total_amt, 
				status_ind, 
				valid_date 
				INTO pa_quotehead[idx].total_amt, 
				pa_quotehead[idx].status_ind, 
				pa_quotehead[idx].valid_date 
				FROM quotehead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND order_num = pa_quotehead[idx].order_num 
			END IF 
			OPTIONS DELETE KEY f36, 
			INSERT KEY f1 
			NEXT FIELD scroll_flag 
		BEFORE INSERT 
			IF fgl_lastkey() = fgl_keyval("NEXTPAGE") THEN 
				CLEAR sr_quotehead[scrn].* 
				NEXT FIELD scroll_flag #informix bug 
			END IF 
			OPEN WINDOW q211 with FORM "Q211" -- alch kd-747 
			CALL windecoration_q("Q211") -- alch kd-747 
			LET pr_order_num = process_order("ADD","") 
			CLOSE WINDOW q211 
			OPTIONS DELETE KEY f36, 
			INSERT KEY f1 
			SELECT order_num, 
			cust_code, 
			quote_date, 
			total_amt, 
			hold_code, 
			status_ind, 
			valid_date 
			INTO pa_quotehead[idx].order_num, 
			pa_quotehead[idx].cust_code, 
			pa_quotehead[idx].quote_date, 
			pa_quotehead[idx].total_amt, 
			pa_quotehead[idx].hold_code, 
			pa_quotehead[idx].status_ind, 
			pa_quotehead[idx].valid_date 
			FROM quotehead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND order_num = pr_order_num 
			IF status = notfound THEN 
				FOR i = idx TO 199 
					LET pa_quotehead[i].* = pa_quotehead[i+1].* 
					IF pa_quotehead[i].cust_code IS NULL THEN 
						LET pa_quotehead[i].order_num = "" 
						LET pa_quotehead[i].quote_date = "" 
						LET pa_quotehead[i].total_amt = "" 
					END IF 
					IF scrn <= 12 THEN 
						DISPLAY pa_quotehead[i].* 
						TO sr_quotehead[scrn].* 

						LET scrn = scrn + 1 
					END IF 
					IF pa_quotehead[i].cust_code IS NULL THEN 
						CALL set_count(i-1) 
						EXIT FOR 
					END IF 
				END FOR 
			ELSE 
				SELECT name_text INTO pa_quotehead2[idx].name_text 
				FROM customer 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = pa_quotehead[idx].cust_code 
				LET pa_quotehead2[idx].cond_code = pr_quotehead.cond_code 
				SELECT desc_text INTO pa_quotehead2[idx].desc_text FROM condsale 
				WHERE cond_code = pa_quotehead2[idx].cond_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			END IF 
			NEXT FIELD scroll_flag 
		ON KEY (F2) 
			IF pa_quotehead[idx].order_num IS NOT NULL 
			AND pa_quotehead[idx].status_ind = "U" THEN 
				IF kandoomsg("E",8010,pa_quotehead[idx].order_num) = "Y" THEN 
					LET msgresp = kandoomsg("E",1005,"") 
					#1005 Updating Database - pls. wait
					CALL initialize_ord(pa_quotehead[idx].order_num) 
					IF write_order(1) THEN 
						SELECT total_amt, 
						status_ind 
						INTO pa_quotehead[idx].total_amt, 
						pa_quotehead[idx].status_ind 
						FROM quotehead 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND order_num = pa_quotehead[idx].order_num 
					END IF 
					LET msgresp = kandoomsg("Q",1014,"") 
					#1014 F1 Add - F2 Cancel - RETURN Edit - F8 Session Defaults"
				END IF 
			END IF 
			NEXT FIELD scroll_flag 
		AFTER ROW 
			DISPLAY pa_quotehead[idx].* 
			TO sr_quotehead[scrn].* 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	LET int_flag = false 
	LET quit_flag = false 
END FUNCTION 


FUNCTION process_order(pr_mode,pr_order_num) 
	DEFINE 
	pr_mode CHAR(4), 
	pr_hold_order CHAR(1), 
	pr_mask_code LIKE customertype.acct_mask_code, 
	pr_order_num LIKE quotehead.order_num, 
	pr_cash_amt DECIMAL(16,2), 
	pr_retry SMALLINT 

	CALL initialize_ord(pr_order_num) 
	LET pr_order_num = NULL 
	DISPLAY pr_country.state_code_text, 
	pr_country.post_code_text, 
	pr_country.state_code_text, 
	pr_country.post_code_text, 
	pr_arparms.inv_ref1_text 
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
			LET pr_quotehead.acct_override_code = 
			build_mask(glob_rec_kandoouser.cmpy_code,pr_quotehead.acct_override_code, 
			glob_rec_kandoouser.acct_mask_code) 
		ELSE 
			LET pr_quotehead.acct_override_code = 
			build_mask(glob_rec_kandoouser.cmpy_code,pr_quotehead.acct_override_code,pr_mask_code) 
		END IF 
		IF glob_rec_opparms.show_seg_flag = "Y" THEN 
			LET pr_quotehead.acct_override_code = 
			segment_fill(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.acct_mask_code, 
			pr_quotehead.acct_override_code) 
			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				CONTINUE WHILE 
			END IF 
		END IF 
		IF NOT valid_trans_num(glob_rec_kandoouser.cmpy_code,TRAN_TYPE_INVOICE_IN, pr_quotehead.acct_override_code) THEN 
			#7031Warning: Automatic Invoice Numbering NOT Set up"
			LET msgresp=kandoomsg("A",7031,"") 
		END IF 
		DELETE FROM t_orderpart WHERE 1=1 
		IF pr_quotehead.cond_code IS NOT NULL THEN 
			## INSERT dummy entry in t_orderpart FOR condition
			INSERT INTO t_orderpart (offer_code,offer_qty) VALUES("###",1) 
		END IF 
		DELETE FROM t_quotedetl WHERE 1=1 
		INSERT INTO t_quotedetl 
		SELECT * FROM quotedetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND order_num = pr_quotehead.order_num 
		SELECT unique 1 FROM offersale 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND start_date <= pr_quotehead.quote_date 
		AND end_date >= pr_quotehead.quote_date 
		IF status = 0 THEN 
			IF NOT offer_entry() THEN 
				CONTINUE WHILE 
			END IF 
		END IF 
		OPEN WINDOW q214 with FORM "Q214" -- alch kd-747 
		CALL windecoration_q("Q214") -- alch kd-747 
		IF pr_quotehead.cond_code IS NOT NULL THEN 
			SELECT unique 1 FROM condsale 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cond_code = pr_quotehead.cond_code 
			IF status != notfound THEN 
				IF pr_customer.inv_level_ind != "L" THEN 
					LET msgresp=kandoomsg("E",7031,"") 
					#7031 Warning: In Nominating a sales condition customer
					#              prices will NOT be AT normal pricing level
				END IF 
			END IF 
		END IF 
		WHILE lineitem_scan() 
			SELECT unique 1 FROM t_orderpart 
			IF status = 0 THEN 
				DECLARE c1_orderpart CURSOR FOR 
				SELECT offer_code FROM t_orderpart 
				WHERE offer_qty > 0 
				AND offer_code != "###" 
				AND offer_code NOT in (SELECT offer_code FROM t_quotedetl 
				WHERE offer_code IS NOT null) 
				LET pr_retry = false 
				FOREACH c1_orderpart INTO pr_temp_text 
					LET msgresp=kandoomsg("E",7091,pr_temp_text) 
					#7091 Warning: Offer ABC NOT included in line items
					IF msgresp = "Y" THEN 
						LET pr_retry = true 
						EXIT FOREACH 
					END IF 
					DELETE FROM t_orderpart WHERE offer_code = pr_temp_text 
				END FOREACH 
				IF pr_retry THEN 
					CONTINUE WHILE 
				END IF 
				IF NOT check_offer() THEN 
					CONTINUE WHILE 
				END IF 
			END IF 
			OPEN WINDOW q216 with FORM "Q216" -- alch kd-747 
			CALL windecoration_q("Q216") -- alch kd-747 
			WHILE order_summary(pr_mode) 
				SELECT unique 1 FROM t_orderpart 
				WHERE disc_ind = "X" 
				IF status = 0 THEN 
					LET msgresp = kandoomsg("E",7015,"") 
					#7015 Order must be on Hold before Saving"
					LET pr_quotehead.hold_code = glob_rec_opparms.so_hold_code 
					LET pr_hold_order = true 
				END IF 
				#OPEN WINDOW w1_Q11 AT 10,4 with 3 rows,72 columns ATTRIBUTE(border, menu line 2) -- alch KD-747
				LET pr_retry = false 
				MENU " Sales Quotations" 
					BEFORE MENU 
						IF (pr_customer.bal_amt - pr_customer.curr_amt) > 0 THEN 
							LET msgresp = kandoomsg("E",1166,"") 
							#1166 This customer account IS overdue
							NEXT option "Hold" 
						END IF 
						CALL publish_toolbar("kandoo","Q11","menu-sales_quot-1") -- alch kd-501 
					ON ACTION "WEB-HELP" -- albo kd-369 
						CALL onlinehelp(getmoduleid(),null) 
					COMMAND "Save" " Save sales quotation TO Database" 
						LET msgresp = kandoomsg("E",1005,"") 
						#1005 Updating Database - pls. wait
						IF pr_mode = "ADD" THEN 
							IF insert_order() THEN 
								LET pr_order_num = write_order(0) 
							ELSE 
								LET pr_retry = true 
							END IF 
						ELSE 
							LET pr_order_num = write_order(0) 
						END IF 
						EXIT MENU 
					COMMAND "Hold" " Hold sales quotation TO prevent further processing" 
						IF enter_hold() THEN 
						END IF 
					COMMAND "Discard" " Discard (new quotation/changed quotation) changes" 
						IF pr_mode = "EDIT" THEN 
							SELECT * INTO pr_quotehead.* 
							FROM quotehead 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND order_num = pr_quotehead.order_num 
							IF pr_quotehead.status_ind = "X" THEN 
								SELECT unique 1 FROM quotedetl 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND order_num = pr_quotehead.order_num 
								IF status = notfound THEN 
									LET pr_quotehead.status_ind = "C" 
								ELSE 
									LET pr_quotehead.status_ind = "U" 
								END IF 
								UPDATE quotehead 
								SET status_ind = pr_quotehead.status_ind 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND order_num = pr_quotehead.order_num 
							END IF 
						END IF 
						LET pr_order_num = 0 
						EXIT MENU 
					COMMAND KEY("E",Interrupt)"Exit" 
						" RETURN TO editting Quotation" 
						LET pr_retry = true 
						EXIT MENU 
					COMMAND KEY (control-w) 
						CALL kandoohelp("") 
				END MENU 
				#CLOSE WINDOW w1_Q11	-- alch KD-747
				IF int_flag OR quit_flag THEN 
					LET int_flag = false 
					LET quit_flag = false 
				END IF 
				IF pr_retry = true THEN 
					LET pr_retry = false 
				ELSE 
					EXIT WHILE 
				END IF 
			END WHILE 
			CLOSE WINDOW q216 
			IF pr_order_num IS NOT NULL THEN 
				EXIT WHILE 
			END IF 
		END WHILE 
		CLOSE WINDOW q214 
		IF pr_order_num IS NOT NULL THEN 
			EXIT WHILE 
		END IF 
	END WHILE 
	RETURN pr_order_num 
END FUNCTION 


FUNCTION initialize_ord(pr_order_num) 
	DEFINE 
	pr_order_num LIKE quotehead.order_num 

	DELETE FROM t_quotedetl 
	#DELETE FROM t_saleshare
	DELETE FROM t_orderpart 
	DELETE FROM t_offerprod 
	DELETE FROM t_proddisc 
	INITIALIZE pr_customer.* TO NULL 
	SELECT * INTO pr_quotehead.* 
	FROM quotehead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND order_num = pr_order_num 
	IF status = notfound THEN 
		INITIALIZE pr_quotehead.* TO NULL 
		LET pr_quotehead.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pr_quotehead.ware_code = "" 
		LET pr_quotehead.entry_code = glob_rec_kandoouser.sign_on_code 
		LET pr_quotehead.entry_date = today 
		LET pr_quotehead.rev_date = today 
		LET pr_quotehead.valid_date = today		+ glob_rec_qpparms.days_validity_num 
		LET pr_quotehead.quote_date = pr_globals.quote_date 
		LET pr_quotehead.ship_date = pr_globals.ship_date 
		LET pr_quotehead.goods_amt = 0 
		LET pr_quotehead.freight_amt = 0 
		LET pr_quotehead.hand_amt = 0 
		LET pr_quotehead.freight_tax_amt = 0 
		LET pr_quotehead.hand_tax_amt = 0 
		LET pr_quotehead.tax_amt = 0 
		LET pr_quotehead.disc_amt = 0 
		LET pr_quotehead.total_amt = 0 
		LET pr_quotehead.cost_amt = 0 
		LET pr_quotehead.status_ind = "U" 
		LET pr_quotehead.line_num = 0 
		LET pr_quotehead.rev_num = 0 
		LET pr_quotehead.prepaid_flag = no_flag 
		LET pr_quotehead.invoice_to_ind = "1" 
		LET pr_currord_amt = 0 
	ELSE 
		LET pr_currord_amt = pr_quotehead.total_amt 
		SELECT unique 1 FROM quotedetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND order_num = pr_quotehead.order_num 
		AND line_num = 1 
		AND status_ind = "1" 
		IF status = 0 THEN 
			LET pr_globals.supp_ware_code = pr_quotehead.ware_code 
		ELSE 
			LET pr_globals.supp_ware_code = "" 
		END IF 
	END IF 
	LET pr_globals.paydetl_flag = pr_globals.def_paydetl_flag 
	SELECT base_currency_code 
	INTO pr_globals.base_curr_code 
	FROM glparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_code = "1" 
END FUNCTION 
