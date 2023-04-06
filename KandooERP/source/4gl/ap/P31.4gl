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
	Source code beautified by beautify.pl on 2020-01-03 13:41:22	$Id: $
}
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_P3_GLOBALS.4gl" 
GLOBALS 
	DEFINE glob_rec_voucher RECORD LIKE voucher.* 
	DEFINE glob_temp_vend LIKE vendor.vend_code 
	DEFINE glob_next_chq_date DATE 
	DEFINE glob_where_text CHAR(800) 
	DEFINE glob_lower_limit DECIMAL(16,2) 
	DEFINE glob_upper_limit DECIMAL(16,2) 
	DEFINE glob_cycle_num LIKE tenthead.cycle_num 
	DEFINE glob_error_text CHAR(60) 
END GLOBALS 
############################################################
# Module Scope Variables
############################################################

############################################################
# MAIN
#
# \brief module P31  Payment Cycle Payment Calculator
#                 Calculates the payable invoices FOR creditors
############################################################
FUNCTION P31_main() 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_count_tenthead SMALLINT
	DEFINE l_operation_status SMALLINT
	DEFINE l_where_clause STRING
	#Initial UI Init

	DEFER quit 
	DEFER interrupt 
	CALL setModuleId("P31") 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	CALL db_glparms_get_rec("1") RETURNING glob_rec_glparms.* 
	#SELECT * INTO glob_rec_glparms.* FROM glparms
	#WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
	#AND key_code = "1"

	IF glob_rec_glparms IS NULL THEN #if sqlca.sqlcode = NOTFOUND THEN 
		LET l_msgresp=kandoomsg('P',5007,'') 
		#5007 General Ledger...
		EXIT PROGRAM 
	END IF 

	LET glob_cycle_num = 1 

	OPEN WINDOW p148 with FORM "P148" 
	CALL windecoration_p("P148") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	#Check if no payment request pending
	SELECT count(*)
	INTO l_count_tenthead
	FROM tenthead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cycle_num = glob_cycle_num 
	IF l_count_tenthead > 0 OR found_tentpays() > 0 THEN 
		--LET l_msgresp = kandoomsg('P',7051,'') 
		#7051 Tentative Payment Selection has already been performed.
		CALL fgl_winmessage("Tentative payment Pending","Press OK to quit","info") 
		CLOSE WINDOW p148 
		EXIT PROGRAM
	END IF 
	
	LET l_operation_status = TRUE
	WHILE l_operation_status
		CALL construct_dataset_payments()  RETURNING l_operation_status,l_where_clause
		IF l_operation_status THEN
			CALL process_vouchers(l_where_clause) RETURNING l_operation_status
			IF l_operation_status THEN  # we found payments to do
				CLOSE WINDOW p148 
				CALL run_prog("P33","","","","") 
				EXIT WHILE 
			END IF 
		END IF
	END WHILE 
END FUNCTION # P31_main 

############################################################
# FUNCTION construct_dataset_payments()
#
# Get the Vendor/Voucher criteria FOR retrieval of Payment Details
############################################################
FUNCTION construct_dataset_payments() 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_low_lim DECIMAL(16,2) 
	DEFINE l_upp_lim DECIMAL(16,2) 
	DEFINE l_where_clause STRING


	LET glob_rec_voucher.vouch_date = today 
	LET glob_next_chq_date = today 
	LET glob_lower_limit = NULL 
	LET glob_upper_limit = NULL 
	WHILE TRUE 
		IF glob_lower_limit = 0 THEN 
			LET glob_lower_limit = NULL 
		END IF 
		IF glob_upper_limit = 99999999 THEN 
			LET glob_upper_limit = NULL 
		END IF 
		LET l_msgresp = kandoomsg("P",1056,"") 
		#1056 Enter Payment Details;  OK TO Continue.
		LET glob_rec_vendor.currency_code = glob_rec_glparms.base_currency_code 
{
		# ericv: this input is making the input of criteria cumbersome, replaced by 1 CONSTRUCT BY NAME
		INPUT glob_rec_vendor.currency_code, 
		glob_next_chq_date, 
		glob_lower_limit, 
		glob_upper_limit WITHOUT DEFAULTS 
		FROM 
		vendor.currency_code, 
		next_chq_date, 
		lower_limit, 
		upper_limit 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","P31","inp-vendor-1") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON KEY (control-b) infield(currency_code) 
				LET glob_rec_vendor.currency_code = show_curr(glob_rec_kandoouser.cmpy_code) 
				DISPLAY BY NAME glob_rec_vendor.currency_code 

				NEXT FIELD currency_code 

			AFTER FIELD currency_code 
				SELECT unique 1 
				FROM currency 
				WHERE currency_code = glob_rec_vendor.currency_code 

				IF sqlca.sqlcode = NOTFOUND THEN 
					LET l_msgresp = kandoomsg("A",9057,"") 
					#9057 "Currency NOT found -Try Window"
					NEXT FIELD currency_code 
				END IF 

			AFTER FIELD lower_lim
				IF glob_lower_limit IS NULL THEN 
					LET l_low_lim = 0 
				ELSE 
					LET l_low_lim = glob_lower_limit 
				END IF 
				IF l_low_lim < 0 THEN 
					LET l_msgresp = kandoomsg("P",9180,"") 
					#9180 The lower limit cannot be less than zero
					IF glob_lower_limit IS NOT NULL THEN 
						LET glob_lower_limit = l_low_lim 
					END IF 
					NEXT FIELD lower_limit 
				ELSE 
					IF l_low_lim > glob_upper_limit THEN 
						LET l_msgresp = kandoomsg("P",9183,"") 
						#9183 The lower limit cannot be > the upper limit...
						NEXT FIELD lower_limit 
					END IF 
				END IF 

			AFTER FIELD upper_limit 
				IF glob_upper_limit IS NULL THEN 
					LET l_upp_lim = 99999999 
				ELSE 
					LET l_upp_lim = glob_upper_limit 
				END IF 
				IF l_upp_lim <= 0 THEN 
					LET l_msgresp = kandoomsg("P",9181,"") 
					#9181 The upper limit cannot be less than OR equal TO zero
					IF glob_upper_limit IS NOT NULL THEN 
						LET glob_upper_limit = l_upp_lim 
					END IF 
					NEXT FIELD upper_limit 
				END IF 
				IF l_upp_lim < l_low_lim THEN 
					LET l_msgresp = kandoomsg("P",9182,"") 
					#9182 The upper limit cannot be less than the lower limit
					IF glob_upper_limit IS NOT NULL THEN 
						LET glob_upper_limit = l_upp_lim 
					END IF 
					NEXT FIELD upper_limit 
				END IF 
			AFTER INPUT 
				IF NOT (int_flag OR quit_flag) THEN 
				END IF 

		END INPUT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			RETURN FALSE 
		END IF 
}
		LET l_msgresp = kandoomsg("U",1001,"") 
		#1001 Enter Selection Criteria;  OK TO Continue.
		CONSTRUCT BY NAME l_where_clause ON 
			vendor.currency_code, 
			voucher.due_date,
			voucher.total_amt,
			vendor.type_code, 
			vendor.vend_code, 
			voucher.vouch_code, 
--			voucher.total_amt, 
			voucher.term_code, 
			vendor.bank_code, 
			vendor.pay_meth_ind 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","P31","construct-vendor-1") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE
			RETURN FALSE,"" 
		ELSE 
			RETURN TRUE,l_where_clause 
		END IF 

	END WHILE 
END FUNCTION 

############################################################
# FUNCTION found_tentpays()
#
# Check TO see IF recently someone has started loading tentpays
############################################################
FUNCTION found_tentpays() 

	WHENEVER ERROR CONTINUE 
	SELECT unique 1 FROM tentpays 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cycle_num = glob_cycle_num 
	IF STATUS = 0 THEN 
		RETURN TRUE 
	ELSE 
		RETURN FALSE 
	END IF 
END FUNCTION 


############################################################
# FUNCTION process_vouchers()
#
# Process Vouchers FOR Payment
############################################################
FUNCTION process_vouchers(p_where_clause)
	DEFINE p_where_clause STRING
	DEFINE l_idx SMALLINT 
	DEFINE l_withhold_tax_ind LIKE vendortype.withhold_tax_ind 
	DEFINE l_tax_code LIKE tax.tax_code 
	DEFINE l_tax_per LIKE tax.tax_per 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_skip_vendor SMALLINT 
	DEFINE l_on_hold_cnt SMALLINT 
	DEFINE l_not_found_cnt SMALLINT 
	DEFINE l_counted INTEGER 
	DEFINE l_total_vouch_amt DECIMAL(16,2) 
	DEFINE l_source_text LIKE tentpays.source_text 
	DEFINE l_source_ind LIKE tentpays.source_ind 
	#DEFINE pr_disc_per         LIKE termdetl.disc_per #huho NOT used
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_rec_tentpays RECORD LIKE tentpays.* 
	DEFINE l_rec_tenthead RECORD LIKE tenthead.* 
	DEFINE l_pay_meth_ind LIKE vouchpayee.pay_meth_ind 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE prp_vouchers_tobe_paid PREPARED
	DEFINE prp_insert_tentpays PREPARED
	DEFINE prp_insert_tenthead PREPARED
	DEFINE crs_vouchers_tobe_paid CURSOR
	DEFINE crs_tentpays_count_sum CURSOR
	DEFINE regexp util.regex 
	DEFINE l_match_result util.match_results 


	LET l_query_text = "INSERT INTO tentpays VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)"
	CALL prp_insert_tentpays.Prepare(l_query_text)

	LET l_query_text = " INSERT INTO tenthead VALUES (?,?,?,?,?,?,?,?,?,?)"
	CALL prp_insert_tenthead.Prepare(l_query_text)
	 
	--"SELECT unique voucher.* ", 
	LET l_query_text = "SELECT voucher.* ", 
	"FROM voucher,", 
	"vendor ", 
	"WHERE voucher.cmpy_code = ? ",
	"AND (voucher.hold_code = 'NO' OR voucher.hold_code IS NULL) ", 
	"AND voucher.total_amt <> voucher.paid_amt ", 
	"AND voucher.approved_code = 'Y' ", 
	"AND voucher.vend_code = vendor.vend_code ", 
	"AND vendor.cmpy_code = voucher.cmpy_code ",
	"AND vendor.pay_meth_ind matches '[13]' AND ", # cheque OR eft 
	p_where_clause CLIPPED," ", 
--	"AND voucher.total_amt > 0 ", 
	"ORDER BY voucher.vend_code, voucher.vouch_code" 

	CALL crs_vouchers_tobe_paid.Declare(l_query_text)
	# catch glob_upper_limit and glob_lower_limit from regexp on l_query_text, same for due date

	LET l_match_result = util.regex.search(l_query_text,/voucher\.total_amt between\s*?(\d+)\s+and\s*?(\d+)/s)
	IF l_match_result THEN
		LET glob_lower_limit = l_match_result.str(1)
		LET glob_upper_limit = l_match_result.str(2)
	ELSE
		LET l_match_result = util.regex.search(l_query_text,/voucher\.total_amt\s*>\s*.*?(\d+)/s)
		IF l_match_result THEN
			LET glob_lower_limit = l_match_result.str(1)
		END IF
		LET l_match_result = util.regex.search(l_query_text,/voucher\.total_amt\s+<\s+.*?(\d+)/s)
		IF l_match_result THEN
			LET glob_upper_limit = l_match_result.str(1)
		END IF
	END IF

	LET l_query_text = "SELECT source_ind, source_text, count(*), sum(vouch_amt) ",
	" FROM tentpays ",
	" WHERE cmpy_code = ",
	" AND cycle_num = ? ",
	" GROUP BY 1,2 "
	CALL crs_tentpays_count_sum.Declare(l_query_text)

	LET l_msgresp = kandoomsg("U",1002,"") 
	#1002 Searching Database...
	LET glob_temp_vend = " " 
	LET l_idx = 0 
	LET l_on_hold_cnt = 0 
	LET l_not_found_cnt = 0 
--	LET l_msgresp = kandoomsg("U",1005,"") 
	#1005 Updating Database...

	--DISPLAY " Vendor: " at 1,2 
--	GOTO bypass 
--	LABEL recovery: 
--	IF error_recover(glob_error_text,STATUS) != "Y" THEN 

--		RETURN FALSE 
--	END IF 
--	LABEL bypass: 
--	WHENEVER ERROR GOTO recovery 
--	IF found_tentpays() THEN 
--		LET l_msgresp = kandoomsg('P',7051,'') 
--		#7051 Tentative Payment Selection has already been performed.
--
--		RETURN FALSE 
--	END IF 
	BEGIN WORK 

		### 1st Pass IS TO retrieve all the vendor+voucher information ###
	CALL crs_vouchers_tobe_paid.Open(glob_rec_kandoouser.cmpy_code)
	WHILE crs_vouchers_tobe_paid.FetchNext(l_rec_voucher.*) = 0

		IF glob_temp_vend <> l_rec_voucher.vend_code THEN 
			LET l_skip_vendor = FALSE 
			CALL get_whold_tax(glob_rec_kandoouser.cmpy_code,glob_rec_vendor.vend_code,glob_rec_vendor.type_code) 
			RETURNING l_withhold_tax_ind,l_tax_code,l_tax_per 
--		ELSE 
--			IF l_skip_vendor THEN 
--				CONTINUE WHILE 
--			END IF 
		END IF 
		INITIALIZE l_rec_tentpays.* TO NULL 
		LET l_rec_tentpays.cycle_num = glob_cycle_num 
		LET l_rec_tentpays.taken_disc_amt = 0 
		IF glob_next_chq_date <= l_rec_voucher.disc_date THEN 
			LET l_rec_tentpays.disc_date = l_rec_voucher.disc_date 
			LET l_rec_tentpays.taken_disc_amt = l_rec_voucher.poss_disc_amt 
		END IF 
		LET l_rec_tentpays.vouch_amt = l_rec_voucher.total_amt - l_rec_voucher.paid_amt - l_rec_tentpays.taken_disc_amt 
		LET glob_rec_vendor.bal_amt = glob_rec_vendor.bal_amt - l_rec_tentpays.vouch_amt - l_rec_tentpays.taken_disc_amt 
		IF glob_rec_vendor.bal_amt < 0 THEN 
			LET l_rec_tentpays.vouch_amt = l_rec_tentpays.vouch_amt + glob_rec_vendor.bal_amt 
			LET glob_rec_vendor.bal_amt = 0 
			#IF voucher IS NOT fully paid, zero out discount.
			LET l_rec_tentpays.taken_disc_amt = 0 
		END IF 
		IF l_rec_tentpays.vouch_amt > 0 THEN 
			LET l_pay_meth_ind = "" 
			IF l_rec_voucher.source_ind = "S" THEN # sundry voucher 
				SELECT pay_meth_ind INTO l_pay_meth_ind 
				FROM vouchpayee 
				WHERE vend_code = l_rec_voucher.vend_code 
					AND vouch_code = l_rec_voucher.vouch_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_rec_tentpays.pay_meth_ind = l_pay_meth_ind 
			ELSE 
				LET l_rec_tentpays.pay_meth_ind = glob_rec_vendor.pay_meth_ind 
			END IF 
			LET l_rec_tentpays.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET l_rec_tentpays.vend_code = l_rec_voucher.vend_code 
			LET l_rec_tentpays.vouch_code = l_rec_voucher.vouch_code 
			LET l_rec_tentpays.due_date = l_rec_voucher.due_date 
			LET l_rec_tentpays.disc_date = l_rec_voucher.disc_date 
			LET l_rec_tentpays.withhold_tax_ind = l_rec_voucher.withhold_tax_ind 
			LET l_rec_tentpays.tax_code = l_tax_code 
			LET l_rec_tentpays.tax_per = l_tax_per 
			IF l_rec_voucher.source_ind IS NOT NULL AND l_rec_voucher.source_ind = "8" THEN 
				LET l_rec_tentpays.source_ind = l_rec_voucher.source_ind 
				LET l_rec_tentpays.source_text = l_rec_voucher.source_text 
			ELSE 
				IF l_pay_meth_ind IS NOT NULL THEN 
					# Sundry voucher
					LET l_rec_tentpays.source_ind = l_rec_voucher.source_ind 
					LET l_rec_tentpays.source_text = l_rec_voucher.vouch_code 
					USING "&&&&&&&&" 
				ELSE 
					LET l_rec_tentpays.source_ind = "1" 
					LET l_rec_tentpays.source_text = glob_rec_vendor.vend_code 
				END IF 
			END IF 
			LET l_rec_tentpays.status_ind = 1 
			LET l_rec_tentpays.pay_doc_num = 0 
			LET l_rec_tentpays.page_num = 0 
			LET l_rec_tentpays.cheq_code = 0 
			LET l_rec_tentpays.vouch_date = l_rec_voucher.vouch_date 
			LET l_rec_tentpays.inv_text = l_rec_voucher.inv_text 
			LET l_rec_tentpays.total_amt = l_rec_voucher.total_amt 
			LET glob_error_text = "Problems Inserting Tentative Payments - P31" 
			CALL prp_insert_tentpays.Execute(l_rec_tentpays.*)
			LET l_idx = l_idx + 1 
		END IF 
	END WHILE # crs_vouchers_tobe_paid

	### 2nd Pass IS TO resort the tentpays AND process based upon source_text###
	IF glob_upper_limit = 99999999 THEN 
		LET glob_upper_limit = NULL 
	END IF 
	IF glob_lower_limit = 0.00 THEN 
		LET glob_lower_limit = NULL 
	END IF 
	IF (glob_upper_limit IS NOT NULL OR glob_lower_limit IS NOT null) THEN 
		# check if cumulated amount for vendor is not above min and max amounts
		CALL crs_tentpays_count_sum.Open(glob_rec_kandoouser.cmpy_code,glob_cycle_num) 
		WHILE crs_tentpays_count_sum.FetchNext(l_source_ind, l_source_text, l_counted, l_total_vouch_amt) = 0
			IF (l_total_vouch_amt IS NOT null) THEN 
				IF (glob_lower_limit IS NOT null) THEN 
					IF (glob_upper_limit IS NOT null) THEN 
						IF (l_total_vouch_amt <= glob_upper_limit) AND (l_total_vouch_amt >= glob_lower_limit) THEN 
							CONTINUE WHILE
						END IF 
					ELSE 
						IF (l_total_vouch_amt >= glob_lower_limit) THEN 
							CONTINUE WHILE 
						END IF 
					END IF 
				ELSE 
					IF (l_total_vouch_amt <= glob_upper_limit) THEN 
						CONTINUE WHILE 
					END IF 
				END IF 
				LET glob_error_text = "Problems Deleting Tentative Payments - P31" 
				DELETE FROM tentpays 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cycle_num = glob_cycle_num 
					AND source_text = l_source_text 
					AND source_ind = l_source_ind 
				LET l_idx = l_idx - l_counted 
			END IF 
		END WHILE   # crs_tentpays_count_sum
	END IF 
	IF l_idx > 0 THEN 
		INITIALIZE l_rec_tenthead.* TO NULL 
		LET l_rec_tenthead.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_rec_tenthead.cycle_num = glob_cycle_num 
		LET l_rec_tenthead.entry_code = glob_rec_kandoouser.sign_on_code 
		LET l_rec_tenthead.status_datetime = today 
		LET l_rec_tenthead.status_ind = 1 
		LET glob_error_text = "Problems Inserting INTO Tentative Master Table - P31" 
		CALL prp_insert_tenthead.Execute(l_rec_tenthead.*)
		--INSERT INTO tenthead VALUES (l_rec_tenthead.*) 
	END IF 
	COMMIT WORK 

	--WHENEVER ERROR CONTINUE 
	IF (l_on_hold_cnt) THEN 
		LET l_msgresp = kandoomsg('P',7057,l_on_hold_cnt) 
		#7057 There are VALUE Vendor/s On Hold.
	END IF 
	IF (l_not_found_cnt) THEN 
		LET l_msgresp = kandoomsg('P',7058,l_not_found_cnt) 
		#7058 There are VALUE Vendors NOT Found. Refer TO get_settings_logFile()
	END IF 
	IF l_idx = 0 THEN 
		LET l_msgresp = kandoomsg('P',7052,'') 
		#7052 There are NO Vouchers selected FOR Payment.
		RETURN FALSE 
	ELSE 
		LET l_msgresp = kandoomsg("P",7053,l_idx) 
		#7000 Payment Calculator Load Complete
		RETURN TRUE 
	END IF 
END FUNCTION 
