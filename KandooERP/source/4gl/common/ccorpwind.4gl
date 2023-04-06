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

###########################################################################
# Requires
# common/cicdwind.4gl
###########################################################################

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

###########################################################################
# FUNCTION disp_corp_acc(p_cmpy,p_cust)
#
#
###########################################################################
FUNCTION disp_corp_acc(p_cmpy,p_cust) 
	DEFINE p_cmpy         LIKE company.cmpy_code 
	DEFINE p_cust         LIKE customer.cust_code
	DEFINE l_corp_code    LIKE customer.cust_code 
	DEFINE l_pr_customer  RECORD LIKE customer.* 
	DEFINE l_total_cred   DECIMAL(16,2) 
	DEFINE l_total_bal    DECIMAL(16,2)
	DEFINE l_ps_customer  RECORD LIKE customer.* 
	DEFINE l_arr_customer DYNAMIC ARRAY OF RECORD --ARRAY[200] OF RECORD 
		scroll_flag CHAR(1), 
		cust_code LIKE customer.cust_code, 
		name_text LIKE customer.name_text, 
		cred_limit_amt LIKE customer.cred_limit_amt, 
		curr_amt LIKE customer.curr_amt, 
		over1_amt LIKE customer.over1_amt, 
		over30_amt LIKE customer.over30_amt, 
		over60_amt LIKE customer.over60_amt, 
		over90_amt LIKE customer.over90_amt, 
		bal_amt LIKE customer.bal_amt 
	END RECORD 
	DEFINE l_idx SMALLINT

	OPEN WINDOW A233 with FORM "A233" 
	CALL windecoration_a("A233") 


	SELECT * INTO l_pr_customer.* FROM customer 
	WHERE cust_code = p_cust 
	AND cmpy_code = p_cmpy 

	IF l_pr_customer.corp_cust_code IS NOT NULL THEN 
		LET l_corp_code = l_pr_customer.corp_cust_code 
		SELECT * INTO l_ps_customer.* FROM customer 
		WHERE cust_code = l_corp_code 
		AND cmpy_code = p_cmpy 
	ELSE 
		LET l_corp_code = l_pr_customer.cust_code 
		LET l_ps_customer.* = l_pr_customer.* 
	END IF 

	DECLARE c_corp CURSOR FOR 
	SELECT * FROM customer 
	WHERE corp_cust_code = l_corp_code 
	AND cmpy_code = p_cmpy 

	DISPLAY l_ps_customer.cust_code, l_ps_customer.name_text 
	TO corp_cust_code,corp_name 

	LET l_idx = 1 
	LET l_arr_customer[l_idx].cust_code = l_ps_customer.cust_code 
	LET l_arr_customer[l_idx].name_text = l_ps_customer.name_text 
	LET l_arr_customer[l_idx].cred_limit_amt = l_ps_customer.cred_limit_amt 
	LET l_arr_customer[l_idx].curr_amt = l_ps_customer.curr_amt 
	LET l_arr_customer[l_idx].over1_amt = l_ps_customer.over1_amt 
	LET l_arr_customer[l_idx].over30_amt = l_ps_customer.over30_amt 
	LET l_arr_customer[l_idx].over60_amt = l_ps_customer.over60_amt 
	LET l_arr_customer[l_idx].over90_amt = l_ps_customer.over90_amt 
	LET l_arr_customer[l_idx].bal_amt = l_ps_customer.bal_amt 
	LET l_total_bal = l_ps_customer.bal_amt 
	LET l_total_cred = l_ps_customer.cred_limit_amt 

	FOREACH c_corp INTO l_pr_customer.* 
		LET l_idx = l_idx + 1 
		LET l_arr_customer[l_idx].cust_code = l_pr_customer.cust_code 
		LET l_arr_customer[l_idx].name_text = l_pr_customer.name_text 
		LET l_arr_customer[l_idx].cred_limit_amt = l_pr_customer.cred_limit_amt 
		LET l_arr_customer[l_idx].curr_amt = l_pr_customer.curr_amt 
		LET l_arr_customer[l_idx].over1_amt = l_pr_customer.over1_amt 
		LET l_arr_customer[l_idx].over30_amt = l_pr_customer.over30_amt 
		LET l_arr_customer[l_idx].over60_amt = l_pr_customer.over60_amt 
		LET l_arr_customer[l_idx].over90_amt = l_pr_customer.over90_amt 
		LET l_arr_customer[l_idx].bal_amt = l_pr_customer.bal_amt 
		LET l_total_bal = l_total_bal + l_pr_customer.bal_amt 
		LET l_total_cred = l_total_cred + l_pr_customer.cred_limit_amt 
--		IF l_idx = 200 THEN 
--			ERROR kandoomsg2("U",6100,l_idx) 
--			EXIT FOREACH 
--		END IF 
	END FOREACH 

	ERROR kandoomsg2("U",9113,l_idx) 
	OPTIONS INSERT KEY f1, 
	DELETE KEY f36 

	CALL set_count(l_idx) 
	MESSAGE kandoomsg2("A",1007,"")	#1008" F3 Page Down - F4 Page Up - ESC TO Exit

	DISPLAY l_total_bal,l_total_cred TO total_bal,total_cred  

	INPUT ARRAY l_arr_customer WITHOUT DEFAULTS FROM sr_customer.* 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","ccorpwind","input-arr-customer") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		BEFORE ROW 
			LET l_idx = arr_curr() 
			#LET scrn = scr_line()
			#IF l_arr_customer[l_idx].cust_code IS NOT NULL THEN
			#   DISPLAY l_arr_customer[l_idx].* TO sr_customer[scrn].*
			#
			#END IF
			NEXT FIELD scroll_flag 

		AFTER FIELD scroll_flag 
			#         --#IF fgl_lastkey() = fgl_keyval("accept")
			#         --#AND fgl_fglgui() THEN
			#         --#   NEXT FIELD cust_code
			#         --#END IF
			LET l_arr_customer[l_idx].scroll_flag = NULL 
			IF fgl_lastkey() = fgl_keyval("down") 
			AND arr_curr() >= arr_count() THEN 
				ERROR kandoomsg2("U",9001,"") 
				NEXT FIELD scroll_flag 
			END IF 

		BEFORE FIELD cust_code 
			INITIALIZE l_ps_customer.* TO NULL 
			SELECT * INTO l_ps_customer.* FROM customer 
			WHERE cust_code = l_arr_customer[l_idx].cust_code 
			AND cmpy_code = p_cmpy 
			IF l_ps_customer.corp_cust_code IS NOT NULL THEN 
				CALL cinq_cd(p_cmpy,l_ps_customer.cust_code) 
			END IF 
			NEXT FIELD scroll_flag 

			#AFTER ROW
			#   DISPLAY l_arr_customer[l_idx].* TO sr_customer[scrn].*



	END INPUT 


	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 

	CLOSE WINDOW A233 
END FUNCTION 


###########################################################################
# FUNCTION disp_corp_inv(p_cmpy,p_cust)
#
#
###########################################################################
FUNCTION disp_corp_inv(p_cmpy,p_cust) 
	DEFINE p_cmpy LIKE customer.cmpy_code 
	DEFINE p_cust LIKE customer.cust_code 
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_pr_arparms RECORD LIKE arparms.* 
	DEFINE l_arr_invoicehead DYNAMIC ARRAY OF RECORD --ARRAY [800] OF RECORD 
		inv_num LIKE invoicehead.inv_num, 
		expected_date LIKE invoicehead.expected_date, 
		purchase_code LIKE invoicehead.purchase_code, 
		due_date LIKE invoicehead.due_date, 
		in_over DECIMAL(4,0), 
		paid_amt LIKE invoicehead.paid_amt, 
		in_out LIKE invoicehead.total_amt, 
		story_flag CHAR(1) 
	END RECORD 
	DEFINE l_save_date DATE 
	DEFINE l_date_prompt CHAR(7) 
	DEFINE l_type CHAR(14) 
	DEFINE l_idx SMALLINT 
	DEFINE l_run_arg STRING #for forming the RUN url argument 

	LET l_type = "View Invoice" 
	SELECT * INTO l_rec_customer.* FROM customer 
	WHERE cmpy_code = p_cmpy 
	AND cust_code = p_cust 

	IF status = notfound THEN 
		ERROR kandoomsg2("A",9067,p_cust) 	#9067 Logic Error: Customer XXXX NOT found
		RETURN 
	END IF 

	SELECT * INTO l_rec_pr_arparms.* FROM arparms 
	WHERE cmpy_code = p_cmpy 
	AND parm_code = "1" 
	IF get_kandoooption_feature_state("AR","DT") = "2" THEN 
		LET l_date_prompt = "Invoice" 
	ELSE 
		LET l_date_prompt = " Due" 
	END IF 

	OPEN WINDOW A233 with FORM "A233" 
	CALL windecoration_a("A233") 

	IF status < 0 THEN 
		ERROR kandoomsg2("U",9917,"") 	#9917 "Window IS already OPEN"
		RETURN 
	END IF 
	DISPLAY BY NAME l_rec_pr_arparms.inv_ref2a_text, l_rec_pr_arparms.inv_ref2b_text attribute(white) 
	DISPLAY l_date_prompt TO  date_prompt	attribute(white)

	DISPLAY BY NAME l_rec_customer.currency_code attribute(green) 
	DECLARE curser_item CURSOR FOR 
	SELECT * INTO l_rec_invoicehead.* FROM invoicehead 
	WHERE cust_code = l_rec_customer.corp_cust_code 
	AND cmpy_code = p_cmpy 
	AND org_cust_code = l_rec_customer.cust_code 
	AND total_amt != invoicehead.paid_amt 
	AND posted_flag != "V" 
	AND posted_flag != "H" 
	LET l_idx = 0 

	FOREACH curser_item 
		LET l_idx = l_idx + 1 
		LET l_arr_invoicehead[l_idx].inv_num = l_rec_invoicehead.inv_num 
		LET l_arr_invoicehead[l_idx].expected_date = l_rec_invoicehead.expected_date 
		LET l_arr_invoicehead[l_idx].purchase_code = l_rec_invoicehead.purchase_code 
		IF l_date_prompt = "Invoice" THEN 
			LET l_arr_invoicehead[l_idx].due_date = l_rec_invoicehead.inv_date 
		ELSE 
			LET l_arr_invoicehead[l_idx].due_date = l_rec_invoicehead.due_date 
		END IF 
		IF l_rec_invoicehead.due_date IS NULL THEN 
			LET l_rec_invoicehead.due_date = today 
		END IF 
		IF today - l_rec_invoicehead.due_date > 9999 THEN 
			LET l_arr_invoicehead[l_idx].in_over = 9999 
		ELSE 
			LET l_arr_invoicehead[l_idx].in_over = today - l_rec_invoicehead.due_date 
		END IF 

		LET l_arr_invoicehead[l_idx].paid_amt = l_rec_invoicehead.paid_amt 
		LET l_arr_invoicehead[l_idx].in_out = l_rec_invoicehead.total_amt 
		- l_rec_invoicehead.paid_amt 
		SELECT unique 1 FROM invstory 
		WHERE cmpy_code = p_cmpy 
		AND cust_code = l_rec_customer.corp_cust_code 
		AND inv_num = l_rec_invoicehead.inv_num 
		IF status = notfound THEN 
			LET l_arr_invoicehead[l_idx].story_flag = "N" 
		ELSE 
			LET l_arr_invoicehead[l_idx].story_flag = "Y" 
		END IF 
--		IF l_idx = 800 THEN 
--			A233("A",9177,"") 		# 9177 Only the first 800 invoices have been selected"
--			EXIT FOREACH 
--		END IF 
	END FOREACH 

	DISPLAY BY NAME l_rec_customer.cust_code, 
	l_rec_customer.name_text, 
	l_rec_customer.corp_cust_code 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	CALL set_count(l_idx) 
	MESSAGE kandoomsg2("A",1089,"")	#1089"CTRL V View Invoice - CTRL C Customer Inquiry..."

	INPUT ARRAY l_arr_invoicehead WITHOUT DEFAULTS FROM sr_invoicehead.* 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","ccorpwind","input-arr-invoicehead") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
			
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		ON KEY (control-c) --customer details 
			CALL cinq_clnt( p_cmpy, l_rec_customer.cust_code) --customer details 

			NEXT FIELD inv_num 


		ON ACTION "NOTES" --ON KEY (control-n) 
			LET l_run_arg = "CUSTOMER_CODE=", trim(l_rec_customer.cust_code) 
			CALL run_prog("A13",l_run_arg,"","","") #customer notes filter 
			NEXT FIELD inv_num 

		ON KEY (control-t) 
			CALL inv_story(p_cmpy, 
			l_rec_customer.corp_cust_code, 
			l_arr_invoicehead[l_idx].inv_num) 
			SELECT unique 1 FROM invstory 
			WHERE cmpy_code = p_cmpy 
			AND cust_code = l_rec_customer.corp_cust_code 
			AND inv_num = l_arr_invoicehead[l_idx].inv_num 
			IF status = notfound THEN 
				LET l_arr_invoicehead[l_idx].story_flag = "N" 
			ELSE 
				LET l_arr_invoicehead[l_idx].story_flag = "Y" 
			END IF 
			#DISPLAY l_arr_invoicehead[l_idx].story_flag TO sr_invoicehead[scrn].story
			NEXT FIELD inv_num 

			#F5 the same as control-v because IBM Informix bug under AIX
		ON KEY (F5) 
			CALL lineshow(p_cmpy, 
			l_rec_customer.corp_cust_code, 
			l_arr_invoicehead[l_idx].inv_num, 
			l_type) 
			NEXT FIELD inv_num 

		ON KEY (control-v) 
			CALL lineshow(p_cmpy, 
			l_rec_customer.corp_cust_code, 
			l_arr_invoicehead[l_idx].inv_num, 
			l_type) 
			NEXT FIELD inv_num 

		BEFORE ROW 
			# SET up ARRAY variables
			LET l_idx = arr_curr() 
			#LET scrn = scr_line()
			LET l_save_date = l_arr_invoicehead[l_idx].expected_date 

		AFTER FIELD expected_date 
			IF (l_arr_invoicehead[l_idx].expected_date != l_save_date 
			OR (l_save_date IS NULL 
			AND l_arr_invoicehead[l_idx].expected_date IS NOT null)) THEN 
				UPDATE invoicehead 
				SET expected_date = l_arr_invoicehead[l_idx].expected_date 
				WHERE cmpy_code = p_cmpy 
				AND cust_code = l_rec_customer.corp_cust_code 
				AND inv_num = l_arr_invoicehead[l_idx].inv_num 
			END IF 


	END INPUT 
	CLOSE WINDOW A233 

	LET int_flag = false 
	LET quit_flag = false 
	RETURN 
END FUNCTION 


