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

	Source code beautified by beautify.pl on 2020-01-03 13:41:34	$Id: $
}



#       P71a.4gl consists of two functions with the following functionality
#
#       - History  : DISPLAY all vouchers (under this Recurring Voucher)
#                    that have been paid
#
#       - Schedule : DISPLAY all vouchers (under this Recurring Voucher)
#                    that are due TO be raised in the future
#
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_P7_GLOBALS.4gl"
GLOBALS "../ap/P71_GLOBALS.4gl"

############################################################
# MODULE Scope Variables
############################################################

############################################################
# FUNCTION P71_history(p_cmpy,p_rec_recurhead)
############################################################
FUNCTION P71_history(p_cmpy,p_rec_recurhead) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_rec_recurhead RECORD LIKE recurhead.* 
	DEFINE l_rec_voucher RECORD LIKE voucher.*
	DEFINE l_total_amt LIKE recurhead.total_amt 
	DEFINE l_todate_amt LIKE recurhead.total_amt
	DEFINE l_remain_amt LIKE recurhead.total_amt 
	DEFINE l_arr_history ARRAY[100] OF RECORD 
		scroll_flag CHAR(1), 
		run_num LIKE recurhead.run_num, 
		vouch_code LIKE voucher.vouch_code, 
		vouch_date LIKE voucher.vouch_date, 
		due_date LIKE voucher.due_date, 
		paid_amt LIKE voucher.paid_amt, 
		total_amt LIKE voucher.total_amt 
	END RECORD 
	DEFINE l_msgresp LIKE language.yes_flag
	DEFINE idx SMALLINT 

	OPEN WINDOW p192 with FORM "P192" 
	CALL windecoration_p("P192") 
	SELECT sum(total_amt) INTO l_todate_amt 
	FROM voucher 
	WHERE cmpy_code = p_cmpy 
	AND source_ind = "2" 
	AND source_text = p_rec_recurhead.recur_code 
	IF l_todate_amt IS NULL THEN 
		LET l_todate_amt = 0 
	END IF 
	IF p_rec_recurhead.max_run_num < 999 THEN 
		LET l_remain_amt = p_rec_recurhead.total_amt * 
		(p_rec_recurhead.max_run_num - p_rec_recurhead.run_num) 
		LET l_total_amt = l_todate_amt + l_remain_amt 
	END IF 
	DISPLAY BY NAME p_rec_recurhead.recur_code, 
	p_rec_recurhead.run_date, 
	p_rec_recurhead.next_vouch_date 
   DISPLAY l_total_amt, 
	l_todate_amt, 
	l_remain_amt
	TO total_amt, 
	todate_amt, 
	remain_amt

	DISPLAY BY NAME p_rec_recurhead.curr_code 
	attribute(green) 
	DECLARE c_history CURSOR FOR 
	SELECT * FROM voucher 
	WHERE cmpy_code = p_cmpy 
	AND source_ind = "2" 
	AND source_text = p_rec_recurhead.recur_code 
	AND vend_code = p_rec_recurhead.vend_code 
	ORDER BY cmpy_code, entry_date, vouch_code 
	LET idx = 0 
	FOREACH c_history INTO l_rec_voucher.* 
		LET idx = idx + 1 
		LET l_arr_history[idx].scroll_flag = NULL 
		LET l_arr_history[idx].run_num = idx 
		LET l_arr_history[idx].vouch_code = l_rec_voucher.vouch_code 
		LET l_arr_history[idx].vouch_date = l_rec_voucher.vouch_date 
		LET l_arr_history[idx].due_date = l_rec_voucher.due_date 
		LET l_arr_history[idx].paid_amt = l_rec_voucher.paid_amt 
		LET l_arr_history[idx].total_amt = l_rec_voucher.total_amt 
		IF idx = 100 THEN 
			LET l_msgresp = kandoomsg("P",1030,100) 
			#1030  First ??? Recurring Vouchers selected
			EXIT FOREACH 
		END IF 
	END FOREACH 

	LET l_msgresp = kandoomsg("P",1007,"") 
	#1007 F3/F4 Fwd/Bwd.. RETURN on line TO View
	CALL set_count(idx) 
	DISPLAY ARRAY l_arr_history TO sr_history.* 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","P71a","display-arr-history") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
		ON KEY (tab) 
			LET idx = arr_curr() 
			CALL display_voucher_header(p_cmpy,l_arr_history[idx].vouch_code) 
		ON KEY (RETURN) 
			LET idx = arr_curr() 
			CALL display_voucher_header(p_cmpy,l_arr_history[idx].vouch_code) 

	END DISPLAY 

	CLOSE WINDOW p192 
	LET int_flag = FALSE 
	LET quit_flag = FALSE 
END FUNCTION 


FUNCTION schedule(p_cmpy,p_rec_recurhead) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_rec_recurhead RECORD LIKE recurhead.*
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_term RECORD LIKE term.* 
	DEFINE l_disc_date DATE 
	DEFINE l_total_amt LIKE recurhead.total_amt
	DEFINE l_todate_amt LIKE recurhead.total_amt
	DEFINE l_remain_amt LIKE recurhead.total_amt 
	DEFINE l_arr_schedule ARRAY[50] OF RECORD 
		scroll_flag CHAR(1), 
		run_num LIKE recurhead.run_num, 
		inv_text LIKE recurhead.inv_text, 
		next_vouch_date LIKE recurhead.next_vouch_date, 
		next_due_date LIKE recurhead.next_due_date, 
		total_amt LIKE voucher.total_amt 
	END RECORD 
	DEFINE l_msgresp LIKE language.yes_flag
	DEFINE idx, x SMALLINT 

	OPEN WINDOW p193 with FORM "P193" 
	CALL windecoration_p("P193") 
	SELECT sum(total_amt) INTO l_todate_amt 
	FROM voucher 
	WHERE cmpy_code = p_cmpy 
	AND source_ind = "2" 
	AND source_text = p_rec_recurhead.recur_code 
	IF l_todate_amt IS NULL THEN 
		LET l_todate_amt = 0.0 
	END IF 
	IF p_rec_recurhead.max_run_num < 999 THEN 
		LET l_remain_amt = p_rec_recurhead.total_amt * 
		(p_rec_recurhead.max_run_num - p_rec_recurhead.run_num) 
		LET l_total_amt = l_todate_amt + l_remain_amt 
	END IF 
	DISPLAY BY NAME p_rec_recurhead.recur_code, 
	p_rec_recurhead.run_date, 
	p_rec_recurhead.next_vouch_date 
   DISPLAY l_total_amt, 
	l_todate_amt, 
	l_remain_amt
	TO pr_total_amt, 
	pr_todate_amt, 
	pr_remain_amt

	DISPLAY BY NAME p_rec_recurhead.curr_code 
	attribute(green) 
	IF p_rec_recurhead.term_code IS NULL THEN 
		SELECT * INTO l_rec_vendor.* 
		FROM vendor 
		WHERE cmpy_code = p_cmpy 
		AND vend_code = p_rec_recurhead.vend_code 
		SELECT * INTO l_rec_term.* 
		FROM term 
		WHERE cmpy_code = p_cmpy 
		AND term_code = l_rec_vendor.term_code 
	ELSE 
		SELECT * INTO l_rec_term.* 
		FROM term 
		WHERE cmpy_code = p_cmpy 
		AND term_code = p_rec_recurhead.term_code 
	END IF 
	LET idx = 0 
	FOR x = (p_rec_recurhead.run_num + 1) TO p_rec_recurhead.max_run_num 
		LET idx = idx + 1 
		LET l_arr_schedule[idx].run_num = x 
		LET l_arr_schedule[idx].next_vouch_date = generate_int(p_rec_recurhead.*, idx) 
		CALL get_due_and_discount_date(l_rec_term.*, l_arr_schedule[idx].next_vouch_date) 
		RETURNING l_arr_schedule[idx].next_due_date, 
		l_disc_date 
		LET l_arr_schedule[idx].total_amt = p_rec_recurhead.total_amt 
		IF p_rec_recurhead.inv_text IS NOT NULL THEN 
			LET l_arr_schedule[idx].inv_text = p_rec_recurhead.inv_text clipped, ".", 
			x USING "&&&" 
		END IF 
		IF idx = 50 THEN 
			LET l_msgresp = kandoomsg("P",1036,"50") 
			#1036 First ??? Payment Schedules selected
			EXIT FOR 
		END IF 
	END FOR 
	LET l_msgresp = kandoomsg("P",1008,"") 
	#1008 F3/F4 TO Page Fwd/Bwd - ESC TO Continue
	CALL set_count(idx) 

	DISPLAY ARRAY l_arr_schedule TO sr_schedule.* 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","P71a","display-arr-schedule") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END DISPLAY 

	CLOSE WINDOW p193 
	LET int_flag = FALSE 
	LET quit_flag = FALSE 
END FUNCTION 


