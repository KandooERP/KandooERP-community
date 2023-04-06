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

	Source code beautified by beautify.pl on 2020-01-02 10:35:05	$Id: $
}
#


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 


############################################################
# FUNCTION fundsapproved_get_count(p_cmpy_code,p_acct_code )
#
#
############################################################
FUNCTION fundsapproved_get_count(p_cmpy_code,p_acct_code ) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_acct_code LIKE fundsapproved.acct_code 
	DEFINE r_count SMALLINT 

	SELECT count(*) INTO r_count 
	FROM fundsapproved 
	WHERE cmpy_code = p_cmpy_code 
	AND acct_code = p_acct_code 

	SELECT unique(1) FROM fundsapproved 
	WHERE cmpy_code = p_cmpy_code 
	AND acct_code = p_acct_code 
	IF status = notfound THEN 
		LET r_count = 0 
	ELSE 
		LET r_count = 1 
	END IF 


	RETURN r_count 
END FUNCTION 



############################################################
# FUNCTION disp_cab(p_cmpy_code, p_acct_code)
#
#
############################################################
FUNCTION disp_cab(p_cmpy_code, p_acct_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_acct_code LIKE fundsapproved.acct_code 
	DEFINE l_rec_fundsapproved RECORD LIKE fundsapproved.* 
	DEFINE l_rec_poaudit RECORD LIKE poaudit.* 
	DEFINE l_coa_desc_text LIKE coa.desc_text 
	DEFINE l_fund_type_desc LIKE kandooword.response_text 
	DEFINE l_valid_tran LIKE language.yes_flag 
	DEFINE l_line_amt LIKE fundsapproved.limit_amt 
	DEFINE l_available_amt LIKE fundsapproved.limit_amt 
	DEFINE l_arr_rec_cabdetl DYNAMIC ARRAY OF 
	RECORD --array[1000] OF RECORD 
		scroll_flag CHAR(1), 
		type_ind LIKE purchdetl.type_ind, 
		ref_num LIKE purchdetl.order_num, 
		line_num LIKE purchdetl.line_num, 
		desc_text LIKE purchdetl.desc_text, 
		line_amt LIKE fundsapproved.limit_amt 
	END RECORD 
	DEFINE l_ref_num LIKE purchdetl.order_num 
	DEFINE l_desc_text LIKE purchdetl.desc_text 
	DEFINE l_line_num LIKE purchdetl.line_num 
	DEFINE l_idx SMALLINT 
	DEFINE l_counter SMALLINT 
	DEFINE l_counter2 SMALLINT 
	DEFINE l_scroll_flag CHAR(1) 
	DEFINE l_year_num LIKE purchhead.year_num 
	DEFINE l_msgresp LIKE language.yes_flag 

	SELECT * INTO l_rec_fundsapproved.* FROM fundsapproved 
	WHERE cmpy_code = p_cmpy_code 
	AND acct_code = p_acct_code 
	IF status = notfound THEN 
		RETURN false 
	END IF 
	LET l_counter = 0 

	OPEN WINDOW g553 with FORM "G553" 
	CALL windecoration_g("G553") 

	SELECT desc_text INTO l_coa_desc_text FROM coa 
	WHERE cmpy_code = p_cmpy_code 
	AND acct_code = p_acct_code 
	IF status = notfound THEN 
		LET l_coa_desc_text = NULL 
	END IF 
	DISPLAY p_acct_code, 
	l_rec_fundsapproved.fund_type_ind, 
	l_coa_desc_text 
	TO coa.acct_code, 
	fundsapproved.fund_type_ind, 
	coa.desc_text 

	LET l_msgresp = kandoomsg("U",1002,"") 
	#1002 Searching database;  Please wait.
	IF l_rec_fundsapproved.fund_type_ind = "CAP" THEN 
		CALL check_funds(p_cmpy_code, 
		p_acct_code, 
		"", 
		"", 
		"", 
		"", 
		"", 
		"", 
		"N") 
		RETURNING l_valid_tran, l_available_amt 
	ELSE 
	END IF 

	DISPLAY l_rec_fundsapproved.limit_amt, 
	l_available_amt, 
	l_rec_fundsapproved.locn_text, 
	l_rec_fundsapproved.active_flag, 
	l_rec_fundsapproved.approval_date, 
	l_rec_fundsapproved.amend_code, 
	l_rec_fundsapproved.capital_ref, 
	l_rec_fundsapproved.amend_date 
	TO fundsapproved.limit_amt, 
	available_amt, 
	fundsapproved.locn_text, 
	fundsapproved.active_flag, 
	fundsapproved.approval_date, 
	fundsapproved.amend_code, 
	fundsapproved.capital_ref, 
	fundsapproved.amend_date 


	# Get Purchase Order Details
	DECLARE c_purchdetl CURSOR FOR 
	SELECT order_num, line_num, desc_text 
	FROM purchdetl 
	WHERE cmpy_code = p_cmpy_code 
	AND acct_code = p_acct_code 
	ORDER BY order_num, line_num 
	FOREACH c_purchdetl INTO l_ref_num, l_line_num, l_desc_text 
		LET l_counter = l_counter + 1 
		LET l_arr_rec_cabdetl[l_counter].type_ind = "R" 
		LET l_arr_rec_cabdetl[l_counter].ref_num = l_ref_num 
		LET l_arr_rec_cabdetl[l_counter].line_num = l_line_num 
		LET l_arr_rec_cabdetl[l_counter].desc_text = l_desc_text 
		CALL po_line_info(p_cmpy_code, 
		l_ref_num, 
		l_line_num) 
		RETURNING l_rec_poaudit.order_qty, 
		l_rec_poaudit.received_qty, 
		l_rec_poaudit.voucher_qty, 
		l_rec_poaudit.unit_cost_amt, 
		l_rec_poaudit.ext_cost_amt, 
		l_rec_poaudit.unit_tax_amt, 
		l_rec_poaudit.ext_tax_amt, 
		l_rec_poaudit.line_total_amt 
		LET l_arr_rec_cabdetl[l_counter].line_amt = l_rec_poaudit.line_total_amt 
		IF l_counter = 1000 THEN 
			EXIT FOREACH 
		END IF 
	END FOREACH 

	IF l_counter < 1000 THEN 
		# Get Voucher Distribution Information
		DECLARE c_voucherdist CURSOR FOR 
		SELECT vouch_code, line_num, desc_text, dist_amt 
		FROM voucherdist 
		WHERE cmpy_code = p_cmpy_code 
		AND acct_code = p_acct_code 
		ORDER BY vouch_code, line_num 
		FOREACH c_voucherdist INTO l_ref_num, l_line_num, 
			l_desc_text, l_line_amt 
			LET l_counter = l_counter + 1 
			LET l_arr_rec_cabdetl[l_counter].type_ind = "P" 
			LET l_arr_rec_cabdetl[l_counter].ref_num = l_ref_num 
			LET l_arr_rec_cabdetl[l_counter].line_num = l_line_num 
			LET l_arr_rec_cabdetl[l_counter].desc_text = l_desc_text 
			LET l_arr_rec_cabdetl[l_counter].line_amt = l_line_amt 
			IF l_counter = 1000 THEN 
				EXIT FOREACH 
			END IF 
		END FOREACH 
	END IF 

	--   IF l_counter < 1000 THEN
	# Get Debit Transactions Information
	DECLARE c_debitdist CURSOR FOR 
	SELECT debit_code, line_num, desc_text, dist_amt 
	FROM debitdist 
	WHERE debitdist.cmpy_code = p_cmpy_code 
	AND debitdist.acct_code = p_acct_code 
	ORDER BY debit_code, line_num 
	FOREACH c_debitdist INTO l_ref_num, l_line_num, 
		l_desc_text, l_line_amt 
		LET l_counter = l_counter + 1 
		LET l_arr_rec_cabdetl[l_counter].type_ind = "P" 
		LET l_arr_rec_cabdetl[l_counter].ref_num = l_ref_num 
		LET l_arr_rec_cabdetl[l_counter].line_num = l_line_num 
		LET l_arr_rec_cabdetl[l_counter].desc_text = l_desc_text 
		LET l_arr_rec_cabdetl[l_counter].line_amt = l_line_amt * -1 
		IF l_counter = 1000 THEN 
			EXIT FOREACH 
		END IF 
	END FOREACH 
	--   END IF

	--   IF l_counter < 1000 THEN
	# Get Batch Transactions Information
	DECLARE c_batchdetl CURSOR FOR 
	SELECT batchdetl.jour_num, batchdetl.seq_num, desc_text, 
	batchdetl.for_debit_amt - batchdetl.for_credit_amt 
	FROM batchhead, batchdetl 
	WHERE batchhead.cmpy_code = p_cmpy_code 
	AND batchdetl.cmpy_code = p_cmpy_code 
	AND batchhead.jour_num = batchdetl.jour_num 
	AND batchdetl.acct_code = p_acct_code 
	AND (batchhead.source_ind != 'R' 
	AND batchhead.source_ind != 'P') 
	ORDER BY batchdetl.jour_num, batchdetl.seq_num 

	FOREACH c_batchdetl INTO l_ref_num, l_line_num, 
		l_desc_text, l_line_amt 
		LET l_counter = l_counter + 1 
		LET l_arr_rec_cabdetl[l_counter].type_ind = "G" 
		LET l_arr_rec_cabdetl[l_counter].line_num = l_line_num 
		LET l_arr_rec_cabdetl[l_counter].desc_text = l_desc_text 
		LET l_arr_rec_cabdetl[l_counter].ref_num = l_ref_num 
		LET l_arr_rec_cabdetl[l_counter].line_amt = l_line_amt 
		--         IF l_counter = 1000 THEN
		--            EXIT FOREACH
		--         END IF
	END FOREACH 

	--   END IF

	--   IF l_counter = 0 THEN
	--      LET l_counter = 1
	--      INITIALIZE l_arr_rec_cabdetl[1].* TO NULL
	--   END IF

	#   CALL set_COUNT(l_counter)
	--   OPTIONS INSERT KEY F36,
	--           DELETE KEY F36
	LET l_msgresp = kandoomsg("U",1534,"") 

	#1534 F3/F4 TO Page Fwd/Bwd;  Enter on line TO View;  OK TO Continue.
	--	INPUT ARRAY l_arr_rec_cabdetl WITHOUT DEFAULTS FROM sr_cabdetl.*
	DISPLAY ARRAY l_arr_rec_cabdetl TO sr_cabdetl.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","cabdetlwind","input-arr-cabdetl") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW --field scroll_flag 
			LET l_idx = arr_curr() 
			--         LET scrn = scr_line()
			IF l_idx > 0 THEN 
				LET l_scroll_flag = l_arr_rec_cabdetl[l_idx].scroll_flag 
				--         DISPLAY l_arr_rec_cabdetl[l_idx].* TO sr_cabdetl[scrn].*
			END IF 

		ON ACTION ("ACCEPT","DOUBLECLICK") -- AFTER FIELD scroll_flag 
			IF l_idx > 0 THEN 
				LET l_arr_rec_cabdetl[l_idx].scroll_flag = l_scroll_flag 
				--         IF fgl_lastkey() = fgl_keyval("down")
				--         AND arr_curr() >= arr_count() THEN
				--            LET l_msgresp=kandoomsg("U",9001,"")
				--            #9001 There no more rows...
				--            NEXT FIELD scroll_flag
				--         END IF
				--        IF (fgl_lastkey() = fgl_keyval("right")
				--         OR  fgl_lastkey() = fgl_keyval("RETURN")
				--         OR  fgl_lastkey() = fgl_keyval("tab")) THEN
				CASE l_arr_rec_cabdetl[l_idx].type_ind 
					WHEN "G" 
						CALL jo_det_scan(p_cmpy_code, l_arr_rec_cabdetl[l_idx].ref_num) 
					WHEN "P" 
						IF l_arr_rec_cabdetl[l_idx].line_amt >= 0 THEN 
							CALL display_voucher_header(p_cmpy_code,l_arr_rec_cabdetl[l_idx].ref_num) 
						ELSE 
							CALL disp_dm_head(p_cmpy_code,l_arr_rec_cabdetl[l_idx].ref_num) 
						END IF 
					WHEN "R" 
						CALL pohdwind(p_cmpy_code, l_arr_rec_cabdetl[l_idx].ref_num) 
				END CASE 

				LET int_flag = false 
				LET quit_flag = false 
				--NEXT FIELD scroll_flag
			END IF 
			--      AFTER ROW
			--         DISPLAY l_arr_rec_cabdetl[l_idx].* TO sr_cabdetl[scrn].*


	END DISPLAY 

	LET int_flag = false 
	LET quit_flag = false 

	CLOSE WINDOW g553 

	RETURN true 
END FUNCTION 
