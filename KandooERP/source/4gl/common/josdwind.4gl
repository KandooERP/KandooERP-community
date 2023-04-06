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

	Source code beautified by beautify.pl on 2020-01-02 10:35:17	$Id: $
}

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"


############################################################
# FUNCTION jo_det_scan(p_cmpy, p_jour_num)
# displays the journal batch details in scan form
# jo_detl_disp displays detailed batch line item information
# disp_journal displays batch header information only
############################################################
FUNCTION jo_det_scan(p_cmpy,p_jour_num) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_jour_num LIKE batchhead.jour_num 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_glparms RECORD LIKE glparms.* 
	DEFINE l_rec_batchhead RECORD LIKE batchhead.* 
	DEFINE l_rec_batchdetl RECORD LIKE batchdetl.* 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_arr_rec_batchdetl DYNAMIC ARRAY OF t_rec_batchdetl --array[3000] OF 
--	RECORD 
--		scroll_flag CHAR(1), 
--		seq_num LIKE batchdetl.seq_num, 
--		acct_code LIKE batchdetl.acct_code, 
--		for_debit_amt LIKE batchdetl.for_debit_amt, 
--		for_credit_amt LIKE batchdetl.for_credit_amt, 
--		stats_qty LIKE batchdetl.stats_qty, 
--		uom_code LIKE coa.uom_code 
--	END RECORD 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_where_text CHAR(2048) 
	DEFINE l_msg_text CHAR(20) 
	DEFINE l_temp_text CHAR(30) 
	DEFINE l_idx SMALLINT 
	DEFINE l_for_balance_amt LIKE batchdetl.for_credit_amt 
	DEFINE l_for_balance_control_amt LIKE batchhead.control_amt 
	DEFINE l_for_balance_quantity LIKE batchhead.control_qty 

	OPEN WINDOW G114 with FORM "G114" 
	CALL windecoration_g("G114") 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	SELECT * INTO l_rec_batchhead.* 
	FROM batchhead 
	WHERE cmpy_code = p_cmpy 
	AND jour_num = p_jour_num 

	SELECT * INTO l_rec_glparms.* 
	FROM glparms 
	WHERE cmpy_code = p_cmpy 
	AND key_code = "1" 
	DISPLAY l_rec_batchhead.jour_code TO jour_code 
	DISPLAY l_rec_batchhead.jour_num TO jour_code 
	DISPLAY l_rec_batchhead.jour_date TO jour_date 
	DISPLAY l_rec_batchhead.currency_code TO sr_currency[1].* attribute(green) 
	DISPLAY l_rec_batchhead.currency_code TO sr_currency[2].* attribute(green) 

	IF l_rec_glparms.control_tot_flag = "N" THEN 
		IF l_rec_batchhead.for_debit_amt = l_rec_batchhead.for_credit_amt 
		AND l_rec_batchhead.for_debit_amt > 0 THEN 
			LET l_msg_text = kandooword(" Batch in Balance",1) 
		END IF 
	ELSE 
		IF l_rec_batchhead.for_debit_amt = l_rec_batchhead.for_credit_amt 
		AND l_rec_batchhead.for_debit_amt = l_rec_batchhead.control_amt 
		AND l_rec_batchhead.stats_qty = l_rec_batchhead.control_qty 
		AND l_rec_batchhead.for_debit_amt > 0 THEN 
			LET l_msg_text = kandooword(" Batch in Balance",1) 
		END IF 
	END IF 
	IF l_msg_text IS NOT NULL THEN 
		MESSAGE l_msg_text --at 17,24 
		#	ELSE
		#		MESSAGE "" --AT 17,24
	END IF 
	#QXDEBUG
	#DISPLAY "l_rec_batchhead.for_debit_amt=", l_rec_batchhead.for_debit_amt
	#DISPLAY "l_rec_batchhead.for_credit_amt=", l_rec_batchhead.for_credit_amt
	#DISPLAY "l_rec_batchhead.stats_qty=", l_rec_batchhead.stats_qty
	#DISPLAY "l_rec_batchhead.control_amt=", l_rec_batchhead.control_amt
	#DISPLAY "l_rec_batchhead.control_qty=", l_rec_batchhead.control_qty

	DISPLAY l_rec_batchhead.for_debit_amt TO batchhead.for_debit_amt 
	DISPLAY l_rec_batchhead.for_credit_amt TO batchhead.for_credit_amt 
	DISPLAY l_rec_batchhead.stats_qty TO batchhead.stats_qty 
	DISPLAY l_rec_batchhead.control_amt TO batchhead.control_amt 
	DISPLAY l_rec_batchhead.control_qty TO batchhead.control_qty 

	LET l_for_balance_amt = l_rec_batchhead.for_credit_amt - l_rec_batchhead.for_debit_amt 
	LET l_for_balance_control_amt = l_rec_batchhead.for_debit_amt - l_rec_batchhead.control_amt 
	LET l_for_balance_quantity = l_rec_batchhead.stats_qty - l_rec_batchhead.control_qty 

	IF l_for_balance_amt = 0 THEN 
		DISPLAY l_for_balance_amt TO for_balance_amt attribute(GREEN) 
	ELSE 
		DISPLAY l_for_balance_amt TO for_balance_amt attribute(RED) 
	END IF 

	IF l_for_balance_control_amt = 0 THEN 
		DISPLAY l_for_balance_control_amt TO for_balance_control_amt attribute(GREEN) 
	ELSE 
		DISPLAY l_for_balance_control_amt TO for_balance_control_amt attribute(RED) 
	END IF 

	IF l_for_balance_quantity = 0 THEN 
		DISPLAY l_for_balance_quantity TO for_balance_quantity attribute(GREEN) 
	ELSE 
		DISPLAY l_for_balance_quantity TO for_balance_quantity attribute(RED) 
	END IF 


	LET l_msgresp=kandoomsg("G",1001,"") 
	#G1001 Enter Selection Criteria - Please Wait
	CONSTRUCT l_where_text 
	ON seq_num, 
	acct_code, 
	for_debit_amt, 
	for_credit_amt, 
	stats_qty, 
	ref_text, 
	desc_text 
	FROM batchdetl.seq_num, 
	batchdetl.acct_code, 
	batchdetl.for_debit_amt, 
	batchdetl.for_credit_amt, 
	batchdetl.stats_qty, 
	batchdetl.ref_text, 
	batchdetl.desc_text 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","josdwind","construct-batchdetl") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
	END CONSTRUCT 
	IF NOT (int_flag OR quit_flag) THEN 
		LET l_query_text = "SELECT * FROM batchdetl ", 
		"WHERE cmpy_code = '",p_cmpy,"' ", 
		"AND jour_code = '",l_rec_batchhead.jour_code,"' ", 
		"AND jour_num = '",l_rec_batchhead.jour_num,"' ", 
		"AND ",l_where_text clipped, " ", 
		"ORDER BY 1,2,3,4" 
		PREPARE s1_batchdetl FROM l_query_text 
		DECLARE c1_batchdetl CURSOR FOR s1_batchdetl 
		LET l_msgresp=kandoomsg("G",1002,"") 
		#G1001 Searching database - Please Wait
		LET l_idx = 0 
		FOREACH c1_batchdetl INTO l_rec_batchdetl.* 
			LET l_idx = l_idx + 1 
			LET l_arr_rec_batchdetl[l_idx].seq_num = l_rec_batchdetl.seq_num 
			LET l_arr_rec_batchdetl[l_idx].acct_code = l_rec_batchdetl.acct_code 
			LET l_arr_rec_batchdetl[l_idx].for_debit_amt = l_rec_batchdetl.for_debit_amt 
			LET l_arr_rec_batchdetl[l_idx].for_credit_amt = l_rec_batchdetl.for_credit_amt 
			LET l_arr_rec_batchdetl[l_idx].stats_qty = l_rec_batchdetl.stats_qty 
			SELECT uom_code 
			INTO l_arr_rec_batchdetl[l_idx].uom_code 
			FROM coa 
			WHERE cmpy_code = p_cmpy 
			AND acct_code = l_rec_batchdetl.acct_code 
			IF l_idx = 3000 THEN 
				LET l_msgresp=kandoomsg("G",9049,l_idx) 
				#G9049 " Max. No. of lines exceeded - First 3000 lines selected"
				EXIT FOREACH 
			END IF
			
			LET l_arr_rec_batchdetl[l_idx].analysis_text = l_rec_batchdetl.analysis_text	
			--LET l_arr_rec_batchdetl[l_idx].analy_prompt_text = l_rec_batchdetl.analy_prompt_text	
					
			LET l_arr_rec_batchdetl[l_idx].ref_text = l_rec_batchdetl.ref_text			
			LET l_arr_rec_batchdetl[l_idx].desc_text = l_rec_batchdetl.desc_text			
			LET l_arr_rec_batchdetl[l_idx].analysis_text = l_rec_batchdetl.analysis_text			
			
#				DISPLAY l_rec_coa.analy_prompt_text TO analy_prompt_text 
#				DISPLAY l_rec_batchdetl.ref_text TO ref_text 
#				DISPLAY l_rec_batchdetl.desc_text TO desc_text 
#				DISPLAY l_rec_batchdetl.analysis_text TO analysis_text 			
			
			
			
			 
		END FOREACH 
#		CALL set_count(l_idx) 
		LET l_msgresp=kandoomsg("G",1007,"") 
		#1007 F3/F4 - RETURN TO View
		#INPUT ARRAY l_arr_rec_batchdetl WITHOUT DEFAULTS FROM sr_batchdetl.* ATTRIBUTE(UNBUFFERED, insert row = false, auto append = false, delete row = false)
		DISPLAY ARRAY l_arr_rec_batchdetl TO sr_batchdetl_v2.* ATTRIBUTE(UNBUFFERED) 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","josdwind","input-arr-batchdetl") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				#				LET scrn = scr_line()
				DISPLAY l_arr_rec_batchdetl[l_idx].seq_num TO batchdetl.seq_num #was TO idx ??? 
				SELECT * INTO l_rec_batchdetl.* 
				FROM batchdetl 
				WHERE cmpy_code = p_cmpy 
				AND jour_code = l_rec_batchhead.jour_code 
				AND jour_num = l_rec_batchhead.jour_num 
				AND seq_num = l_arr_rec_batchdetl[l_idx].seq_num 

				SELECT * INTO l_rec_coa.* 
				FROM coa 
				WHERE cmpy_code = p_cmpy 
				AND acct_code = l_rec_batchdetl.acct_code 

				IF l_rec_coa.analy_prompt_text IS NULL THEN 
					LET l_rec_coa.analy_prompt_text = kandooword("Analysis",1) 
				END IF 

				LET l_temp_text = l_rec_coa.analy_prompt_text clipped,"........." 
				LET l_rec_coa.analy_prompt_text = l_temp_text 

#				DISPLAY l_rec_coa.analy_prompt_text TO analy_prompt_text 
#				DISPLAY l_rec_batchdetl.ref_text TO ref_text 
#				DISPLAY l_rec_batchdetl.desc_text TO desc_text 
#				DISPLAY l_rec_batchdetl.analysis_text TO analysis_text 
				#				NEXT FIELD scroll_flag

				#			AFTER FIELD scroll_flag
				#				IF fgl_lastkey() = fgl_keyval("down") THEN
				#					IF arr_curr() = arr_count() THEN
				#						LET l_msgresp=kandoomsg("I",9001,"")
				##9001 There are no more rows in the direction ...
				#						NEXT FIELD scroll_flag
				#					ELSE
				#						IF l_arr_rec_batchdetl[l_idx+1].acct_code IS NULL THEN
				#							LET l_msgresp=kandoomsg("I",9001,"")
				##9001 There are no more rows in the direction ...
				#							NEXT FIELD scroll_flag
				#						END IF
				#					END IF
				#				END IF

			ON ACTION ("Detail","DOUBLECLICK") 
				#BEFORE FIELD acct_code
				IF l_arr_rec_batchdetl[l_idx].acct_code IS NOT NULL THEN 
					OPEN WINDOW wg112 with FORM "G112" 
					CALL windecoration_g("G112") 
					CALL jo_detl_disp(p_cmpy, p_jour_num, l_arr_rec_batchdetl[l_idx].seq_num) 
					#LET l_msgresp = kandoomsg("U",1,"")
					CALL eventsuspend() 
					#1 " Any Key TO Continue "
					CLOSE WINDOW wg112 
				END IF 
				#NEXT FIELD scroll_flag

				#			AFTER ROW
				#				DISPLAY l_arr_rec_batchdetl[l_idx].* TO sr_batchdetl[scrn].*

		END DISPLAY 

	END IF 

	LET int_flag = false 
	LET quit_flag = false 

	CLOSE WINDOW G114 

END FUNCTION 


############################################################
# FUNCTION jo_det_scan(p_cmpy, p_jour_num)
#  This FUNCTION used TO be in joddwind.4gl
#  currently called FROM G2A AND jo_set_scan() above....
############################################################
FUNCTION jo_detl_disp(p_cmpy, p_jour_num, p_seq_num) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_jour_num LIKE batchdetl.jour_num 
	DEFINE p_seq_num LIKE batchdetl.seq_num 
	#DEFINE l_msgresp LIKE language.yes_flag
	DEFINE l_rec_glparms RECORD LIKE glparms.* 
	DEFINE l_rec_batchhead RECORD LIKE batchhead.* 
	DEFINE l_rec_batchdetl RECORD LIKE batchdetl.* 
	DEFINE l_rec_journal RECORD LIKE journal.* 
	DEFINE l_rec_coa RECORD LIKE coa.* 

	SELECT * INTO l_rec_glparms.* 
	FROM glparms 
	WHERE cmpy_code = p_cmpy 
	AND key_code = "1" 
	SELECT * INTO l_rec_batchhead.* 
	FROM batchhead 
	WHERE cmpy_code = p_cmpy 
	AND jour_num = p_jour_num 
	SELECT * INTO l_rec_batchdetl.* 
	FROM batchdetl 
	WHERE cmpy_code = p_cmpy 
	AND jour_code = l_rec_batchhead.jour_code 
	AND jour_num = p_jour_num 
	AND seq_num = p_seq_num 
	SELECT * INTO l_rec_journal.* 
	FROM journal 
	WHERE cmpy_code = p_cmpy 
	AND jour_code = l_rec_batchdetl.jour_code 
	SELECT * INTO l_rec_coa.* 
	FROM coa 
	WHERE cmpy_code = p_cmpy 
	AND acct_code = l_rec_batchdetl.acct_code 
	DISPLAY l_rec_batchhead.jour_code, 
	l_rec_journal.desc_text, 
	l_rec_batchhead.jour_num, 
	l_rec_batchhead.control_qty, 
	l_rec_batchhead.control_amt, 
	l_rec_batchhead.stats_qty, 
	l_rec_batchhead.for_debit_amt, 
	l_rec_batchhead.for_credit_amt, 
	l_rec_batchhead.year_num, 
	l_rec_batchhead.period_num, 
	l_rec_batchhead.entry_code, 
	l_rec_batchhead.post_flag, 
	l_rec_batchhead.jour_date, 
	l_rec_batchdetl.tran_type_ind, 
	l_rec_batchdetl.tran_date, 
	l_rec_batchdetl.acct_code, 
	l_rec_batchdetl.desc_text, 
	l_rec_batchdetl.ref_num, 
	l_rec_batchdetl.ref_text, 
	l_rec_batchdetl.seq_num, 
	l_rec_batchdetl.for_debit_amt, 
	l_rec_batchdetl.for_credit_amt, 
	l_rec_coa.uom_code, 
	l_rec_batchdetl.stats_qty, 
	l_rec_batchdetl.debit_amt, 
	l_rec_batchdetl.credit_amt 
	TO batchhead.jour_code, 
	journal.desc_text, 
	batchhead.jour_num, 
	batchhead.control_qty, 
	batchhead.control_amt, 
	batchhead.stats_qty, 
	batchhead.for_debit_amt, 
	batchhead.for_credit_amt, 
	batchhead.year_num, 
	batchhead.period_num, 
	batchhead.entry_code, 
	batchhead.post_flag, 
	batchhead.jour_date, 
	batchdetl.tran_type_ind, 
	batchdetl.tran_date, 
	batchdetl.acct_code, 
	batchdetl.desc_text, 
	batchdetl.ref_num, 
	batchdetl.ref_text, 
	batchdetl.seq_num, 
	batchdetl.for_debit_amt, 
	batchdetl.for_credit_amt, 
	coa.uom_code, 
	batchdetl.stats_qty, 
	batchdetl.debit_amt, 
	batchdetl.credit_amt 
	DISPLAY l_rec_batchhead.currency_code, 
	l_rec_batchdetl.currency_code, 
	l_rec_glparms.base_currency_code 
	TO batchhead.currency_code, 
	batchdetl.currency_code, 
	glparms.base_currency_code 
	attribute (GREEN) 
	LET int_flag = 0 
	LET quit_flag = 0 
END FUNCTION 


############################################################
# FUNCTION getbatch()
# Caller functions will have form G109 opened
# Currently called FROM G24, G25 AND G26
############################################################
FUNCTION disp_journal(p_cmpy,p_jour_num) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_jour_num LIKE batchhead.jour_num 

	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_batchhead RECORD LIKE batchhead.* 
	DEFINE l_rec_journal RECORD LIKE journal.* 
	DEFINE l_rec_currency RECORD LIKE currency.* 
	DEFINE l_temp_text CHAR(20) 
	DEFINE l_invalid_period SMALLINT 
	DEFINE l_temp_balance LIKE batchhead.for_credit_amt 

	SELECT * INTO l_rec_batchhead.* 
	FROM batchhead 
	WHERE cmpy_code = p_cmpy 
	AND jour_num = p_jour_num 
	SELECT desc_text INTO l_rec_journal.desc_text 
	FROM journal 
	WHERE cmpy_code = p_cmpy 
	AND jour_code = l_rec_batchhead.jour_code 
	SELECT * INTO l_rec_currency.* 
	FROM currency 
	WHERE currency_code = l_rec_batchhead.currency_code 

	DISPLAY BY NAME l_rec_batchhead.entry_code, 
	l_rec_batchhead.jour_date, 
	l_rec_batchhead.jour_code, 
	l_rec_journal.desc_text, 
	l_rec_batchhead.jour_num, 
	l_rec_batchhead.year_num, 
	l_rec_batchhead.period_num, 
	l_rec_batchhead.post_flag, 
	l_rec_batchhead.rate_type_ind, 
	l_rec_batchhead.conv_qty, 
	l_rec_batchhead.stats_qty, 
	l_rec_batchhead.control_qty, 
	l_rec_batchhead.control_amt, 
	l_rec_batchhead.for_debit_amt, 
	l_rec_batchhead.for_credit_amt, 
	l_rec_batchhead.com1_text, 
	l_rec_batchhead.com2_text 

	DISPLAY l_rec_batchhead.currency_code TO batchhead.currency_code attribute (GREEN) 
	DISPLAY l_rec_currency.desc_text TO currency.desc_text attribute (GREEN) 
	LET l_temp_balance = l_rec_batchhead.for_credit_amt - l_rec_batchhead.for_debit_amt 

	IF l_temp_balance = 0 THEN 
		DISPLAY l_temp_balance TO for_debit_credit_amt_balance attribute(GREEN) 
	ELSE 
		DISPLAY l_temp_balance TO for_debit_credit_amt_balance attribute(RED) 
	END IF 

	LET int_flag = 0 
	LET quit_flag = 0 

END FUNCTION 
