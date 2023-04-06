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

	Source code beautified by beautify.pl on 2020-01-03 13:41:20	$Id: $
}


#
#Program P29a.4gl - Accounts Payable Voucher Distribution
#                 - distributes the voucher TO gl code AND calls
#                    appropriate functions FOR distributions TO PU&JM
#                 - single line entry with GL batch LIKE line descripts.
#                 - provides distributions AND online deletion of lines.
#  NB: This program requires temp table t_voucherdist TO be created
#


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_P2_GLOBALS.4gl" 
GLOBALS "P29_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################

############################################################
# FUNCTION distribute_voucher_to_accounts(p_cmpy,p_kandoouser_sign_on_code,p_rec_voucher)
#
#
############################################################
FUNCTION distribute_voucher_to_accounts(p_cmpy,p_kandoouser_sign_on_code,p_rec_voucher) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE p_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_rec_company RECORD LIKE company.* 
	DEFINE l_rec_voucherdist RECORD LIKE voucherdist.* 
	DEFINE l_rec_voucherdist2 RECORD LIKE voucherdist.* 
	DEFINE l_voucherdist_uom_code LIKE coa.uom_code 
	DEFINE l_arr_rec_voucherdist DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		line_num LIKE voucherdist.line_num, 
		type_ind LIKE voucherdist.type_ind, 
		acct_code LIKE voucherdist.acct_code, 
		dist_amt LIKE voucherdist.dist_amt, 
		dist_qty LIKE voucherdist.dist_qty, 
		uom_code LIKE coa.uom_code 
	END RECORD 
	DEFINE l_tax_amt LIKE voucherdist.dist_amt    # tax amount for this voucher
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_rec_tax RECORD LIKE tax.* 
	DEFINE l_finalised_flag LIKE shiphead.finalised_flag 
	DEFINE l_class_ind LIKE shipcosttype.class_ind 
	DEFINE idx SMALLINT 
	DEFINE l_repeat_ind SMALLINT 
	DEFINE l_temp_text CHAR(20) 
	DEFINE l_valid_tran LIKE language.yes_flag 
	DEFINE l_available_amt LIKE fundsapproved.limit_amt 
	DEFINE l_checked CHAR(1) 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE i SMALLINT
	DEFINE l_input_status SMALLINT

	LET glob_rec_voucher.* = p_rec_voucher.* ## move voucher TO global 
	SELECT * INTO l_rec_company.* 
	FROM company 
	WHERE cmpy_code = p_cmpy 
	IF sqlca.sqlcode = NOTFOUND THEN 
		ERROR kandoomsg2("P",5000,"") 	#5000 Company does NOT Exist.
		EXIT PROGRAM 
	END IF 
	
	SELECT * INTO glob_rec_vendor.* 
	FROM vendor 
	WHERE cmpy_code = p_cmpy 
	AND vend_code = glob_rec_voucher.vend_code 
	IF sqlca.sqlcode = NOTFOUND THEN 
		ERROR kandoomsg2("P",9014,"") 	#9014 Logic Error: Vendor does NOT Exist.
		RETURN false 
	END IF
	 
	DISPLAY BY NAME 
		glob_rec_voucher.vend_code, 
		glob_rec_vendor.name_text, 
		glob_rec_voucher.vouch_code 

	DISPLAY BY NAME glob_rec_voucher.currency_code attribute(green)
	 
	CASE get_kandoooption_feature_state('AP','MS') 
		WHEN 'V' 
			LET glob_desc_ind = "3" 
		WHEN 'D' 
			LET glob_desc_ind = "2" 
		OTHERWISE 
			LET glob_desc_ind = "1" 
	END CASE
	 
	LET l_rec_voucherdist.cmpy_code = glob_rec_kandoouser.cmpy_code
	LET l_rec_voucherdist.vend_code = glob_rec_voucher.vend_code
	LET l_rec_voucherdist.vouch_code = glob_rec_voucher.vouch_code 

	# Check if we have Job management stuff
	SELECT unique 1 
	FROM t_voucherdist 
	IF sqlca.sqlcode = 0 THEN 
		IF l_rec_company.module_text[10] = "J" THEN 
			SELECT unique 1 
			FROM activity,t_voucherdist 
			WHERE activity.cmpy_code = p_cmpy 
			AND activity.job_code = t_voucherdist.job_code 
			AND activity.var_code = t_voucherdist.var_code 
			AND activity.activity_code = t_voucherdist.act_code 
			AND activity.finish_flag = "Y" 
			IF sqlca.sqlcode = 0 THEN 
				ERROR kandoomsg2("P",7026,"") #P7026" Voucher IS distributed TO close JM activities"
				RETURN false 
			END IF 
		END IF 
	ELSE 
		##
		## No previous distributions:
		## Set up default lines
		## 1. Tax line
		## 2. General Disbursement

		# Tax amount
		IF glob_rec_vendor.def_exp_ind = "G" THEN 
			SELECT * INTO l_rec_tax.* 
			FROM tax 
			WHERE cmpy_code = p_cmpy 
			AND tax_code = glob_rec_voucher.tax_code 

			IF l_rec_tax.tax_per <> 0 THEN 
				IF l_rec_tax.buy_acct_code IS NOT NULL THEN 
					# assign nominal code generally used with this tax code
					LET l_rec_voucherdist.acct_code = l_rec_tax.buy_acct_code 
				ELSE
					# take tax code from vendor type 
					SELECT salestax_acct_code INTO l_rec_voucherdist.acct_code 
					FROM vendortype 
					WHERE cmpy_code = p_cmpy 
					AND type_code = glob_rec_vendor.type_code 

					IF l_rec_voucherdist.acct_code IS NULL THEN 
						SELECT salestax_acct_code 
						INTO l_rec_voucherdist.acct_code 
						FROM vendortype 
						WHERE cmpy_code = p_cmpy 
						AND parm_code = "1" 
					END IF 
				END IF 

				--LET l_rec_voucherdist.dist_amt = glob_rec_voucher.total_amt * l_rec_tax.tax_per / (l_rec_tax.tax_per + 100)
				LET l_tax_amt = glob_rec_voucher.total_amt * l_rec_tax.tax_per / (l_rec_tax.tax_per + 100)  # save this amount to calculate net
				LET l_rec_voucherdist.dist_amt = l_tax_amt
				IF l_rec_voucherdist.dist_amt > 0 AND l_rec_voucherdist.acct_code IS NOT NULL THEN 
					SELECT * INTO l_rec_coa.* 
					FROM coa 
					WHERE cmpy_code = p_cmpy 
					AND acct_code = l_rec_voucherdist.acct_code 
					LET l_rec_voucherdist.desc_text =	set_voucherdist_description(l_rec_voucherdist.acct_code,glob_desc_ind) 
					LET l_rec_voucherdist.line_num = 1 
					LET l_rec_voucherdist.type_ind = "G" 
					IF l_rec_coa.uom_code IS NULL THEN 
						LET l_rec_voucherdist.dist_qty = NULL 
					ELSE 
						LET l_rec_voucherdist.dist_qty = 0 
					END IF
					 
					INSERT INTO t_voucherdist VALUES (l_rec_voucherdist.*)
					 
				END IF 
			END IF 
			
			# Expense amount
			IF glob_rec_vendor.usual_acct_code IS NOT NULL THEN 
				IF l_rec_voucherdist.line_num = 1 THEN 
					LET l_rec_voucherdist.line_num = 2 
				ELSE 
					LET l_rec_voucherdist.line_num = 1 
				END IF 
				LET l_rec_voucherdist.type_ind = "G" 
				LET l_rec_voucherdist.acct_code = glob_rec_vendor.usual_acct_code
				 
				SELECT * INTO l_rec_coa.* 
				FROM coa 
				WHERE cmpy_code = p_cmpy 
				AND acct_code = l_rec_voucherdist.acct_code
				 
				LET l_rec_voucherdist.desc_text = set_voucherdist_description(l_rec_voucherdist.acct_code,glob_desc_ind) 
				-- LET l_rec_voucherdist.dist_amt = 0   # change by ericv 20210201
				LET l_rec_voucherdist.dist_amt = glob_rec_voucher.total_amt - l_tax_amt
				 
				IF l_rec_coa.uom_code IS NULL THEN 
					LET l_rec_voucherdist.dist_qty = NULL 
				ELSE 
					LET l_rec_voucherdist.dist_qty = 0 
				END IF
				 
				INSERT INTO t_voucherdist VALUES (l_rec_voucherdist.*)
				 
			END IF 
		END IF 
	END IF
	 
	# FIXME: # wow, no cmpy_code and no vouch_code: what if several agents input vouchers at the same time??
	DECLARE crs_voucherdist_scan_all CURSOR FOR  
	SELECT * FROM t_voucherdist 
	ORDER BY line_num
	 
	WHILE true 
		MESSAGE kandoomsg2("P",1002,"")	#P1002 Searching database - Please Wait

		OPTIONS INSERT KEY f1, 
		DELETE KEY f36 
		LET idx = 0 

		OPEN crs_voucherdist_scan_all 

		FOREACH crs_voucherdist_scan_all INTO l_rec_voucherdist.* 
			LET idx = idx + 1 

			# UPDATE -----------------------------
			UPDATE t_voucherdist 
			SET line_num = idx 
			WHERE line_num = l_rec_voucherdist.line_num 

			LET l_arr_rec_voucherdist[idx].line_num = idx 
			LET l_arr_rec_voucherdist[idx].type_ind = l_rec_voucherdist.type_ind 
			LET l_arr_rec_voucherdist[idx].acct_code = l_rec_voucherdist.acct_code 
			LET l_arr_rec_voucherdist[idx].dist_amt = l_rec_voucherdist.dist_amt 
			LET l_arr_rec_voucherdist[idx].dist_qty = l_rec_voucherdist.dist_qty 

			SELECT uom_code INTO l_arr_rec_voucherdist[idx].uom_code 
			FROM coa 
			WHERE cmpy_code = p_cmpy 
			AND acct_code = l_rec_voucherdist.acct_code 

			IF l_arr_rec_voucherdist[idx].uom_code IS NULL AND l_arr_rec_voucherdist[idx].dist_qty = 0 THEN 
				LET l_arr_rec_voucherdist[idx].dist_qty = NULL 
			END IF 

		END FOREACH 

		LET l_repeat_ind = false 

--		CALL set_count(idx) 

		ERROR kandoomsg2("P",1013,"") 
		LET l_checked = "N" 

		#1013 F1 Add F2 Delete F8 Save Desc F9 Toggle Desc. F10 Disburse
		INPUT ARRAY l_arr_rec_voucherdist WITHOUT DEFAULTS FROM sr_voucherdist.* attribute(UNBUFFERED, insert ROW = false, APPEND ROW = TRUE,auto append = TRUE, DELETE ROW = false) # albo kd-1541 
			BEFORE INPUT 
				CALL fgl_dialog_setkeylabel("F9","Toggle Description")
				CALL fgl_dialog_setkeylabel("F10","Disburse")
				CALL publish_toolbar("kandoo","P29a","inp-arr-voucherdist-1") 
				
				CALL display_voucher_total() 
				
				LET l_temp_text = kandooword("voucher.desc_ind",glob_desc_ind) 
				DISPLAY l_temp_text TO desc_mode 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON ACTION "LOOKUP" infield (acct_code) 
				LET l_temp_text = show_acct(p_cmpy) 
				OPTIONS INSERT KEY f1, 
				DELETE KEY f36 
				
				IF l_temp_text IS NOT NULL THEN 
					LET l_arr_rec_voucherdist[idx].acct_code = l_temp_text 
					NEXT FIELD acct_code 
				END IF 

			ON KEY (F9) --description toggle ? 1-3 ? 
				CASE glob_desc_ind 
					WHEN "1" 
						LET glob_desc_ind = "2" 
					WHEN "2" 
						LET glob_desc_ind = "3" 
					OTHERWISE 
						LET glob_desc_ind = "1" 
				END CASE 
				LET l_temp_text = kandooword("voucher.desc_ind",glob_desc_ind) 
				DISPLAY l_temp_text TO desc_mode 

			ON KEY (F10) 
				IF disburse_distribution() THEN 
					LET l_repeat_ind = true 
					EXIT INPUT 
				END IF 

			BEFORE ROW 
				LET idx = arr_curr() 
				IF (glob_rec_voucher.total_amt - glob_rec_voucher.dist_amt) != 0 THEN 
					LET l_checked = "N" 
				END IF 
				
				IF (glob_rec_voucher.total_amt - glob_rec_voucher.dist_amt) = 0	AND l_checked = "N" THEN 
					LET l_checked = "Y" 
				ELSE 
					IF l_arr_rec_voucherdist[idx].line_num IS NOT NULL 
					AND l_arr_rec_voucherdist[idx].line_num != 0 THEN 
						DISPLAY l_arr_rec_voucherdist[idx].line_num TO idx
					END IF 
				END IF 
				NEXT FIELD scroll_flag 

			BEFORE INSERT 
				INITIALIZE l_rec_voucherdist.* TO NULL 
				INITIALIZE l_rec_voucherdist2.* TO NULL 
				LET l_voucherdist_uom_code = NULL 
				--INITIALIZE l_arr_rec_voucherdist[idx].* TO NULL 

				NEXT FIELD type_ind 

				##
				## A minor Informix problem exists WHERE WHEN pressing delete
				## on last line actually performs a delete AND an INSERT. To
				## avoid this the following check IS included.
				##
				#            IF fgl_lastkey() = fgl_keyval("delete")
				#            OR fgl_lastkey() = fgl_keyval("interrupt") THEN
				#               NEXT FIELD scroll_flag
				#            ELSE
				#               NEXT FIELD type_ind
				#            END IF

				#         AFTER FIELD scroll_flag
				#            IF fgl_lastkey() = fgl_keyval("down")
				#            AND l_arr_rec_voucherdist[idx].line_num IS NULL THEN
				#               NEXT FIELD type_ind
				#            END IF

			BEFORE FIELD scroll_flag 
				LET idx = arr_curr() 
				SELECT * INTO l_rec_voucherdist.* 
				FROM t_voucherdist 
				WHERE line_num = l_arr_rec_voucherdist[idx].line_num 
				
				LET l_rec_voucherdist2.* = l_rec_voucherdist.* 
				LET l_voucherdist_uom_code = l_arr_rec_voucherdist[idx].uom_code 
				
				CALL input_voucherdist_detail(false,l_rec_voucherdist.*)
				RETURNING l_input_status 
				
				IF input_voucherdist_detail(false,l_rec_voucherdist.*) THEN 
				END IF 

			AFTER FIELD scroll_flag
				--DISPLAY "AFTER FIELD scroll_flag"				

			BEFORE FIELD line_num
				--DISPLAY "BEFORE FIELD line_num"

			AFTER FIELD line_num
				--DISPLAY "AFTER FIELD line_num"
			
			BEFORE FIELD type_ind 
				--DISPLAY "BEFORE FIELD type_ind"			
				IF l_checked = "N" THEN 
					IF l_arr_rec_voucherdist[idx].line_num IS NULL 
					OR l_arr_rec_voucherdist[idx].line_num = 0 THEN 

						SELECT max(line_num) INTO l_arr_rec_voucherdist[idx].line_num 
						FROM t_voucherdist 
						IF l_arr_rec_voucherdist[idx].line_num IS NULL THEN 
							LET l_arr_rec_voucherdist[idx].line_num = 1 
						ELSE 
							LET l_arr_rec_voucherdist[idx].line_num = 
							l_arr_rec_voucherdist[idx].line_num + 1 
						END IF 
						LET l_arr_rec_voucherdist[idx].type_ind = glob_rec_vendor.def_exp_ind 

						DISPLAY l_arr_rec_voucherdist[idx].line_num TO idx 

						LET l_rec_voucherdist.acct_code = '' 
						LET l_rec_voucherdist.desc_text = '' 
						LET l_rec_voucherdist.res_code = '' 
						LET l_rec_voucherdist.job_code = '' 

						IF input_voucherdist_detail(false,l_rec_voucherdist.*) THEN 
						END IF 
					ELSE 
						IF l_arr_rec_voucherdist[idx].type_ind IS NOT NULL THEN 
							NEXT FIELD acct_code 
						END IF 
					END IF 

				ELSE #l_checked = "Y" 

					IF l_arr_rec_voucherdist[idx].line_num IS NULL	OR l_arr_rec_voucherdist[idx].line_num = 0 THEN 
						NEXT FIELD scroll_flag 
					END IF 
				END IF 

			AFTER FIELD type_ind
				--DISPLAY "AFTER FIELD type_ind"			 
				IF l_arr_rec_voucherdist[idx].type_ind IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") 				#9102 Value must be entered
					NEXT FIELD type_ind 
				END IF 

				IF l_arr_rec_voucherdist[idx].type_ind <> 'S' 
				AND l_arr_rec_voucherdist[idx].type_ind <> 'J' 
				AND l_arr_rec_voucherdist[idx].type_ind <> 'W' THEN 
					IF l_arr_rec_voucherdist[idx].acct_code IS NULL THEN 
						LET l_arr_rec_voucherdist[idx].acct_code = glob_rec_vendor.usual_acct_code 
					END IF 
				END IF 

				# FROM here down IS creating a dummy dist line FOR some reason
				INITIALIZE l_rec_coa.* TO NULL 

				SELECT * INTO l_rec_coa.* FROM coa 
				WHERE cmpy_code = p_cmpy 
				AND acct_code = l_arr_rec_voucherdist[idx].acct_code 

				IF l_rec_voucherdist.line_num IS NULL 
				OR l_rec_voucherdist.line_num = 0 THEN 
					LET l_arr_rec_voucherdist[idx].dist_amt = 0 
					IF l_rec_coa.uom_code IS NULL THEN 
						LET l_arr_rec_voucherdist[idx].dist_qty = NULL 
						LET l_arr_rec_voucherdist[idx].uom_code = NULL 
					END IF 

					DISPLAY l_arr_rec_voucherdist[idx].line_num TO idx 

					LET l_rec_voucherdist.type_ind = l_arr_rec_voucherdist[idx].type_ind 
					LET l_rec_voucherdist.line_num = l_arr_rec_voucherdist[idx].line_num 
					LET l_rec_voucherdist.acct_code = l_arr_rec_voucherdist[idx].acct_code 
					
					IF l_arr_rec_voucherdist[idx].type_ind <> 'W' THEN 
						LET l_rec_voucherdist.desc_text = 
						set_voucherdist_description(l_rec_voucherdist.acct_code,glob_desc_ind) 
					END IF 
					
					IF input_voucherdist_detail(false,l_rec_voucherdist.*) THEN 
					END IF 
				END IF 

				UPDATE t_voucherdist SET 
					type_ind = l_arr_rec_voucherdist[idx].type_ind, 
					acct_code = l_arr_rec_voucherdist[idx].acct_code, 
					desc_text = l_rec_voucherdist.desc_text, 
					dist_amt = l_arr_rec_voucherdist[idx].dist_amt, 
					dist_qty = l_arr_rec_voucherdist[idx].dist_qty 
				WHERE line_num = l_arr_rec_voucherdist[idx].line_num 

				IF sqlca.sqlerrd[3] = 0 THEN 
					LET l_rec_voucherdist.type_ind = l_arr_rec_voucherdist[idx].type_ind 
					INSERT INTO t_voucherdist VALUES (l_rec_voucherdist.*) 
				END IF 

				CASE 
					WHEN fgl_lastkey() = fgl_keyval("accept") 
						IF l_rec_voucherdist.analysis_text IS NULL 
						AND l_rec_coa.analy_req_flag = "Y" THEN 
							ERROR kandoomsg2("P",9016,"")	#9016 Analysis IS required.
							NEXT FIELD uom_code 
						ELSE 
							NEXT FIELD scroll_flag 
						END IF 

--					WHEN fgl_lastkey() = fgl_keyval("RETURN") 
--						OR fgl_lastkey() = fgl_keyval("right") 
--						OR fgl_lastkey() = fgl_keyval("tab") 
--						OR fgl_lastkey() = fgl_keyval("down") 
--						NEXT FIELD NEXT 
--					WHEN fgl_lastkey() = fgl_keyval("left") 
--						OR fgl_lastkey() = fgl_keyval("up") 
--						NEXT FIELD previous 
					OTHERWISE 

						#DELETE
						DELETE FROM t_voucherdist 
						WHERE line_num = l_arr_rec_voucherdist[idx].line_num 
						LET l_arr_rec_voucherdist[idx].line_num = 0 
						NEXT FIELD type_ind 
				END CASE 

			BEFORE FIELD acct_code
				--DISPLAY "BEFORE FIELD acct_code"			 
				CASE l_arr_rec_voucherdist[idx].type_ind 
					WHEN "A" 
						IF l_rec_company.module_text[1] = "A" THEN 
							IF glob_rec_vendor.usual_acct_code IS NULL THEN 
								ERROR kandoomsg2("A",9218,"")	#9218 Usual GL code must be setup.
								NEXT FIELD scroll_flag 
							END IF 
							
							CALL cr_ar_dist(p_cmpy,p_kandoouser_sign_on_code) 
							LET l_repeat_ind = true 
							EXIT INPUT 
						ELSE 
							LET l_arr_rec_voucherdist[idx].type_ind = "G" 
							NEXT FIELD type_ind 
						END IF 

					WHEN "J" 
						IF l_rec_company.module_text[10] = "J" THEN 
							CALL cr_jm_dist(p_cmpy,p_kandoouser_sign_on_code) 
							LET l_repeat_ind = true 
							EXIT INPUT 
						ELSE 
							LET l_arr_rec_voucherdist[idx].type_ind = "G" 
							NEXT FIELD type_ind 
						END IF 

					WHEN "S" 
						IF l_rec_company.module_text[12] = "L" THEN 
							CALL cr_lc_dist(p_cmpy,p_kandoouser_sign_on_code,l_arr_rec_voucherdist[idx].line_num) 
							LET l_repeat_ind = true 
							EXIT INPUT 
						ELSE 
							LET l_arr_rec_voucherdist[idx].type_ind = "G" 
							NEXT FIELD type_ind 
						END IF 
						LET l_repeat_ind = true 
						EXIT INPUT 

					WHEN "P" 
						IF l_rec_company.module_text[18] = "R" THEN 
							CALL cr_po_dist(p_cmpy,p_kandoouser_sign_on_code) 
							LET l_repeat_ind = true 
							EXIT INPUT 
						ELSE 
							LET l_arr_rec_voucherdist[idx].type_ind = "G" 
							NEXT FIELD type_ind 
						END IF 
						LET l_repeat_ind = true 
						EXIT INPUT 

					WHEN "W" 
						IF l_rec_company.module_text[23] = "W" THEN 
							CALL cr_wo_dist(p_cmpy,p_kandoouser_sign_on_code,l_arr_rec_voucherdist[idx].line_num) 
							LET l_repeat_ind = true 
							EXIT INPUT 
						ELSE 
							LET l_arr_rec_voucherdist[idx].type_ind = "G" 
							NEXT FIELD type_ind 
						END IF 
						LET l_repeat_ind = true 
						EXIT INPUT 
					OTHERWISE 
				END CASE 

			AFTER FIELD acct_code 
				--DISPLAY "AFTER FIELD acct_code "		
				IF l_arr_rec_voucherdist[idx].acct_code IS NULL THEN 
					ERROR kandoomsg2("P",9018,"") 				#9018  Account must be entered; Try Window.
					NEXT FIELD acct_code 
				END IF 

				CALL verify_acct_code(
					p_cmpy,
					l_arr_rec_voucherdist[idx].acct_code, 
					glob_rec_voucher.year_num, 
					glob_rec_voucher.period_num) 
				RETURNING l_rec_coa.* 
				
				IF l_rec_coa.acct_code IS NULL THEN 
					NEXT FIELD acct_code 
				END IF 

				IF l_arr_rec_voucherdist[idx].acct_code != l_rec_coa.acct_code THEN 
					LET l_arr_rec_voucherdist[idx].acct_code = l_rec_coa.acct_code 
					NEXT FIELD acct_code 
				END IF 

				IF NOT acct_type(p_cmpy,l_rec_coa.acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"") THEN 
					NEXT FIELD acct_code 
				END IF 

				IF l_rec_voucherdist.acct_code IS NULL OR l_rec_voucherdist.acct_code != l_rec_coa.acct_code THEN 
					LET l_rec_voucherdist.desc_text = set_voucherdist_description(l_rec_coa.acct_code,glob_desc_ind) 
					LET l_rec_voucherdist.acct_code = l_rec_coa.acct_code 
					
					IF input_voucherdist_detail(false,l_rec_voucherdist.*) THEN 
					END IF 
				END IF 

				IF l_rec_coa.uom_code IS NULL THEN 
					LET l_arr_rec_voucherdist[idx].uom_code = NULL 
					LET l_arr_rec_voucherdist[idx].dist_qty = NULL 
				ELSE 
					LET l_arr_rec_voucherdist[idx].uom_code = l_rec_coa.uom_code 
				END IF 

				IF l_rec_coa.uom_code IS NOT NULL AND l_arr_rec_voucherdist[idx].dist_qty IS NULL THEN 
					LET l_arr_rec_voucherdist[idx].dist_qty = 0 
				END IF 

				#            DISPLAY l_arr_rec_voucherdist[idx].dist_qty,
				#                    l_arr_rec_voucherdist[idx].uom_code
				#                 TO sr_voucherdist[scrn].dist_qty,
				#                    sr_voucherdist[scrn].uom_code

				UPDATE t_voucherdist SET 
					acct_code = l_arr_rec_voucherdist[idx].acct_code, 
					dist_qty = l_arr_rec_voucherdist[idx].dist_qty 
				WHERE line_num = l_arr_rec_voucherdist[idx].line_num 

				CALL display_voucher_total() 
				--DISPLAY "fgl_lastkey()",fgl_lastkey()
				--DISPlAY "fgl_keyname()=", fgl_keyname(fgl_lastkey())
				--DISPLAY "fgl_keyval=", fgl_keyval(fgl_lastkey())
				--DISPLAY "fgl_lastaction()=",fgl_lastaction()
				CASE 
					WHEN ((fgl_lastkey() = fgl_keyval("accept")) OR fgl_lastaction() = "ACCEPT") 
						IF l_rec_voucherdist.analysis_text IS NULL AND l_rec_coa.analy_req_flag = "Y" THEN 
							ERROR kandoomsg2("P",9016,"") 	#9016 Analysis IS required.

							NEXT FIELD uom_code 
						ELSE 
							NEXT FIELD scroll_flag 
						END IF 
					WHEN get_is_screen_navigation_forward()
--					WHEN fgl_lastkey() = fgl_keyval("RETURN") 
--						OR fgl_lastkey() = fgl_keyval("right") 
--						OR fgl_lastkey() = fgl_keyval("tab") 
--						OR fgl_lastkey() = fgl_keyval("down") 
						NEXT FIELD NEXT 

					WHEN NOT get_is_screen_navigation_forward()
					--WHEN fgl_lastkey() = fgl_keyval("left") 
					--	OR fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD scroll_flag 

					OTHERWISE 
						NEXT FIELD acct_code 
				END CASE 

			BEFORE FIELD dist_amt 
				--DISPLAY "BEFORE FIELD dist_amt "			
				IF (glob_rec_voucher.total_amt - glob_rec_voucher.dist_amt) > 0 
				AND l_arr_rec_voucherdist[idx].dist_amt = 0 THEN 
					LET l_arr_rec_voucherdist[idx].dist_amt = glob_rec_voucher.total_amt 
					- glob_rec_voucher.dist_amt 
				END IF 

			AFTER FIELD dist_amt 
				--DISPLAY "AFTER FIELD dist_amt"			
				IF l_arr_rec_voucherdist[idx].dist_amt IS NULL THEN 
					LET l_arr_rec_voucherdist[idx].dist_amt = 0 
					NEXT FIELD dist_amt 
				END IF 

				CALL check_funds(
					p_cmpy, 
					l_arr_rec_voucherdist[idx].acct_code, 
					l_arr_rec_voucherdist[idx].dist_amt, 
					l_arr_rec_voucherdist[idx].line_num, 
					glob_rec_voucher.year_num, 
					glob_rec_voucher.period_num, 
					"P", 
					l_rec_voucherdist.vouch_code, 
					"Y") 
				RETURNING l_valid_tran, l_available_amt
				 
				MESSAGE kandoomsg2("P",1013,"") #1013 F1 Add F2 Delete F8 Save Desc F9 Toggle Desc. F10 Disburse

				IF NOT l_valid_tran THEN 
					NEXT FIELD acct_code 
				END IF 

				UPDATE t_voucherdist 
				SET dist_amt = l_arr_rec_voucherdist[idx].dist_amt 
				WHERE line_num = l_arr_rec_voucherdist[idx].line_num 

				CALL display_voucher_total() 

				IF glob_rec_voucher.total_amt < glob_rec_voucher.dist_amt THEN 
					ERROR kandoomsg2("P",9015,"")			#9015 This will over distribute the voucher.
				END IF 

				CASE 
					WHEN fgl_lastkey() = fgl_keyval("accept") 
						IF l_rec_voucherdist.analysis_text IS NULL 
						AND l_rec_coa.analy_req_flag = "Y" THEN 
							ERROR kandoomsg2("P",9016,"") 			#9016 " Analysis IS required "
							NEXT FIELD uom_code 
						ELSE 
							NEXT FIELD scroll_flag 
						END IF 

					WHEN fgl_lastkey() = fgl_keyval("RETURN") 
						OR fgl_lastkey() = fgl_keyval("right") 
						OR fgl_lastkey() = fgl_keyval("tab") 
						OR fgl_lastkey() = fgl_keyval("down") 
						NEXT FIELD NEXT 
					WHEN fgl_lastkey() = fgl_keyval("left") 
						OR fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD previous 
					OTHERWISE 
						NEXT FIELD dist_amt 
				END CASE 

			BEFORE FIELD dist_qty 
				IF l_arr_rec_voucherdist[idx].uom_code IS NULL THEN 
					NEXT FIELD NEXT 
				END IF 

			AFTER FIELD dist_qty 
				UPDATE t_voucherdist 
				SET dist_qty = l_arr_rec_voucherdist[idx].dist_qty 
				WHERE line_num = l_arr_rec_voucherdist[idx].line_num 
				CALL display_voucher_total() 

				CASE 
					WHEN fgl_lastkey() = fgl_keyval("accept") 
						IF l_rec_voucherdist.analysis_text IS NULL AND l_rec_coa.analy_req_flag = "Y" THEN 
							ERROR kandoomsg2("P",9016,"") 						#9016 Analysis IS required.
							NEXT FIELD uom_code 
						ELSE 
							NEXT FIELD scroll_flag 
						END IF 
{
					WHEN fgl_lastkey() = fgl_keyval("RETURN") 
						OR fgl_lastkey() = fgl_keyval("right") 
						OR fgl_lastkey() = fgl_keyval("tab") 
						OR fgl_lastkey() = fgl_keyval("down") 
						NEXT FIELD NEXT 

					WHEN fgl_lastkey() = fgl_keyval("left") 
						OR fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD previous 

					OTHERWISE 
						NEXT FIELD dist_qty 
}
				END CASE 

			BEFORE FIELD uom_code 
				IF NOT input_voucherdist_detail(true,l_rec_voucherdist.*) THEN 
					DELETE FROM t_voucherdist 
					WHERE line_num = l_arr_rec_voucherdist[idx].line_num 
					IF l_rec_voucherdist2.acct_code IS NOT NULL THEN 
						LET l_arr_rec_voucherdist[idx].line_num = l_rec_voucherdist2.line_num 
						LET l_arr_rec_voucherdist[idx].type_ind = l_rec_voucherdist2.type_ind 
						LET l_arr_rec_voucherdist[idx].acct_code = l_rec_voucherdist2.acct_code 
						LET l_arr_rec_voucherdist[idx].dist_amt = l_rec_voucherdist2.dist_amt 
						LET l_arr_rec_voucherdist[idx].dist_qty = l_rec_voucherdist2.dist_qty 
						LET l_arr_rec_voucherdist[idx].uom_code = l_voucherdist_uom_code 

						INSERT INTO t_voucherdist VALUES (l_rec_voucherdist2.*) 
						#               ELSE
						#                  FOR i = arr_curr() TO arr_count()
						#                     IF l_arr_rec_voucherdist[i+1].acct_code IS NOT NULL THEN
						#                        LET l_arr_rec_voucherdist[i].* = l_arr_rec_voucherdist[i+1].*
						#                     ELSE
						#                        INITIALIZE l_arr_rec_voucherdist[i].* TO NULL
						#                     END IF
						#                     IF scrn <= 7 THEN
						#                        DISPLAY l_arr_rec_voucherdist[i].* TO sr_voucherdist[scrn].*
						#
						#                        LET scrn = scrn + 1
						#                     END IF
						#                  END FOR
						#                  LET scrn = scr_line()
					END IF 
					CALL display_voucher_total() 
					NEXT FIELD scroll_flag 
				END IF 

			ON KEY (F2) 
				IF l_arr_rec_voucherdist[idx].type_ind = 'S' THEN 
					SELECT finalised_flag INTO l_finalised_flag 
					FROM shiphead 
					WHERE cmpy_code = p_cmpy 
					AND ship_code = l_rec_voucherdist.job_code 

					SELECT class_ind INTO l_class_ind 
					FROM shipcosttype 
					WHERE cmpy_code = p_cmpy 
					AND cost_type_code = l_rec_voucherdist.res_code 

					IF l_finalised_flag = 'Y' 
					AND l_class_ind <> '4' THEN 
						ERROR kandoomsg2("P",7061,"") 
						#7061 Only "Late" cost types can be editted once a...
						NEXT FIELD scroll_flag 
					END IF 
				END IF 

				DELETE FROM t_voucherdist 
				WHERE line_num = l_arr_rec_voucherdist[idx].line_num
				IF sqlca.sqlcode = 0 THEN
					CALL l_arr_rec_voucherdist.deleteElement(idx)
				END IF 
				CALL display_voucher_total() 

			AFTER ROW
				--DISPLAY "AFTER ROW" 
				SELECT unique 1 FROM t_voucherdist 
				WHERE line_num = l_arr_rec_voucherdist[idx].line_num 
				IF sqlca.sqlcode = NOTFOUND THEN 
					--INITIALIZE l_arr_rec_voucherdist[idx].* TO NULL 
				END IF 

			AFTER INPUT 
				#DEL & ESC go back TO scroll_flag IF CURSOR NOT on scroll_flag
				IF l_arr_rec_voucherdist.getlength() > 0 AND idx > 0 THEN 
					IF int_flag OR quit_flag THEN 
						IF NOT infield(scroll_flag) THEN 
							LET int_flag = false 
							LET quit_flag = false 
							DELETE FROM t_voucherdist 
							WHERE line_num = l_arr_rec_voucherdist[idx].line_num 
							IF l_rec_voucherdist2.acct_code IS NOT NULL THEN 
								LET l_arr_rec_voucherdist[idx].line_num = l_rec_voucherdist2.line_num 
								LET l_arr_rec_voucherdist[idx].type_ind = l_rec_voucherdist2.type_ind 
								LET l_arr_rec_voucherdist[idx].acct_code=l_rec_voucherdist2.acct_code 
								LET l_arr_rec_voucherdist[idx].dist_amt = l_rec_voucherdist2.dist_amt 
								LET l_arr_rec_voucherdist[idx].dist_qty = l_rec_voucherdist2.dist_qty 
								LET l_arr_rec_voucherdist[idx].uom_code = l_voucherdist_uom_code 
								#                     DISPLAY l_arr_rec_voucherdist[idx].* TO sr_voucherdist[scrn].*

								INSERT INTO t_voucherdist VALUES (l_rec_voucherdist2.*) 
							END IF 
							CALL display_voucher_total() 
							NEXT FIELD scroll_flag 
						END IF 
					ELSE 
						IF glob_rec_voucher.dist_amt > glob_rec_voucher.total_amt THEN 
							ERROR kandoomsg2("P",7010,"") #P7010" Voucher Distributions Exceed Total"
							CONTINUE INPUT 
						ELSE 
							LET l_repeat_ind = false 
							EXIT INPUT 
						END IF 
					END IF 
				END IF 
		END INPUT 

		IF NOT l_repeat_ind THEN 
			EXIT WHILE 
		END IF 
	END WHILE 


	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 
############################################################
# END FUNCTION distribute_voucher_to_accounts(p_cmpy,p_kandoouser_sign_on_code,p_rec_voucher)
############################################################


############################################################
# FUNCTION input_voucherdist_detail(p_update_ind,p_rec_voucherdist)
#
#
############################################################
FUNCTION input_voucherdist_detail(p_update_ind,p_rec_voucherdist) 
	DEFINE p_update_ind smallint## true=update false=display 
	DEFINE p_rec_voucherdist RECORD LIKE voucherdist.* 
	DEFINE l_msgresp LIKE language.yes_flag
	DEFINE l_rec_voucherdist2 RECORD LIKE voucherdist.* 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_rec_prompt 
	RECORD 
		line_1 CHAR(15), 
		line_2 CHAR(15) 
	END RECORD 
	DEFINE l_temp_text CHAR(30) 

	--DISPLAY "FUNCTION input_voucherdist_detail(", trim(p_update_ind), ",", trim(p_rec_voucherdist), ")"
 
	SELECT * INTO l_rec_coa.* FROM coa 
	WHERE cmpy_code = glob_rec_voucher.cmpy_code 
	AND acct_code = p_rec_voucherdist.acct_code
	 
	IF l_rec_coa.analy_prompt_text IS NULL THEN 
		LET l_rec_coa.analy_prompt_text = "Analysis" 
	END IF
	 
	LET l_temp_text = l_rec_coa.analy_prompt_text clipped,"..............." 
	LET l_rec_coa.analy_prompt_text = l_temp_text
	 
	CASE p_rec_voucherdist.type_ind 
		WHEN "J" 
			LET l_rec_prompt.line_1 = kandooword(TRAN_TYPE_JOB_JOB,1) 
			LET l_rec_prompt.line_1 = l_rec_prompt.line_1 clipped,"........." 
			LET l_rec_prompt.line_2 = kandooword("jmresource",1) 
			LET l_rec_prompt.line_2 = l_rec_prompt.line_2 clipped,"........." 
		WHEN "S" 
			LET l_rec_prompt.line_1 = kandooword("shipment",1) 
			LET l_rec_prompt.line_1 = l_rec_prompt.line_1 clipped,"........." 
			LET l_rec_prompt.line_2 = kandooword("costtype",1) 
			LET l_rec_prompt.line_2 = l_rec_prompt.line_2 clipped,"........." 
		WHEN "P" 
			LET l_rec_prompt.line_1 = kandooword("purchhead.order_num",1) 
			LET l_rec_prompt.line_1 = l_rec_prompt.line_1 clipped,"........." 
			LET l_rec_prompt.line_2 = kandooword("purchdetl.line_num",1) 
			LET l_rec_prompt.line_2 = l_rec_prompt.line_2 clipped,"........." 
			LET p_rec_voucherdist.job_code = p_rec_voucherdist.po_num 
			LET p_rec_voucherdist.res_code = p_rec_voucherdist.po_line_num 
		WHEN "A" 
			LET l_rec_prompt.line_1 = kandooword("customer.cust_code",1) 
			LET l_rec_prompt.line_1 = l_rec_prompt.line_1 clipped,"........." 
			LET l_rec_prompt.line_2 = kandooword("invoicehead.inv_num",1) 
			LET l_rec_prompt.line_2 = l_rec_prompt.line_2 clipped,"........." 
			LET p_rec_voucherdist.job_code = p_rec_voucherdist.res_code 
			LET p_rec_voucherdist.res_code = p_rec_voucherdist.po_num 
		WHEN "W" 
			LET l_rec_prompt.line_1 = kandooword("ordhead.order_num",1) 
			LET l_rec_prompt.line_1 = l_rec_prompt.line_1 clipped,"........." 
			LET l_rec_prompt.line_2 = kandooword("ordhead.cust_code",1) 
			LET l_rec_prompt.line_2 = l_rec_prompt.line_2 clipped,"........." 
			LET p_rec_voucherdist.job_code = p_rec_voucherdist.po_num 
		OTHERWISE 
			LET p_rec_voucherdist.job_code = NULL 
			LET p_rec_voucherdist.res_code = NULL 
	END CASE
	 
	DISPLAY BY NAME 
		l_rec_coa.analy_prompt_text, 
		l_rec_prompt.line_1, 
		l_rec_prompt.line_2
	 
	OPTIONS INPUT NO WRAP
	
	INPUT BY NAME 
		p_rec_voucherdist.analysis_text, 
		p_rec_voucherdist.desc_text, 
		p_rec_voucherdist.job_code, 
		p_rec_voucherdist.res_code WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P29a","inp-voucherdist-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "NOTES" infield(desc_text) --ON KEY (control-n) infield(desc_text)  
				LET p_rec_voucherdist.desc_text = sys_noter(glob_rec_voucher.cmpy_code,p_rec_voucherdist.desc_text) 
				NEXT FIELD desc_text 
			
		BEFORE FIELD analysis_text
			--DISPLAY "BEFORE FIELD analysis_text" 		 
			IF p_update_ind THEN 
				LET l_rec_voucherdist2.* = p_rec_voucherdist.* 	
			ELSE 
				EXIT INPUT 
			END IF


		--BEFORE FIELD desc_text
		--	DISPLAY "BEFORE FIELD desc_text"

		--BEFORE FIELD job_code
		--	DISPLAY "BEFORE FIELD job_code"

		--BEFORE FIELD res_code
		--	DISPLAY "BEFORE FIELD res_code"
			
		--AFTER FIELD desc_text
		--	DISPLAY "AFTER FIELD desc_text"

		--AFTER FIELD job_code
		--	DISPLAY "AFTER FIELD job_code"

		--AFTER FIELD res_code
		--	DISPLAY "AFTER FIELD res_code"
 		 
		AFTER INPUT 
		--	DISPLAY "AFTER INPUT"		
			IF not(int_flag OR quit_flag) THEN
			 
				IF glob_desc_ind = "2" THEN 
					LET glob_default_text = p_rec_voucherdist.desc_text 
				END IF
				 
				IF p_rec_voucherdist.analysis_text IS NULL AND l_rec_coa.analy_req_flag = "Y" THEN 
					ERROR kandoomsg2("P",9016,"") #9016 " Analysis IS required "
					NEXT FIELD analysis_text 
				END IF
				 
			END IF 

	END INPUT
	--DISPLAY "DONE INPUT"		
	
	OPTIONS INPUT WRAP
		 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		UPDATE t_voucherdist 
		SET analysis_text = p_rec_voucherdist.analysis_text, 
		desc_text = p_rec_voucherdist.desc_text 
		WHERE line_num = p_rec_voucherdist.line_num 
		RETURN true 
	END IF 
END FUNCTION 


############################################################
# FUNCTION set_voucherdist_description(p_acct_code,p_mode_ind)
#
#
############################################################
FUNCTION set_voucherdist_description(p_acct_code,p_mode_ind) 
	DEFINE p_acct_code LIKE voucherdist.acct_code 
	DEFINE p_mode_ind CHAR(1) 
	DEFINE r_desc_text LIKE voucherdist.desc_text 

	CASE p_mode_ind 
		WHEN "1" ### account description 
			SELECT desc_text INTO r_desc_text FROM coa 
			WHERE cmpy_code = glob_rec_voucher.cmpy_code 
			AND acct_code = p_acct_code 
		WHEN "2" ### default description 
			LET r_desc_text = glob_default_text 
		WHEN "3" ### vendor's NAME 
			LET r_desc_text = glob_rec_vendor.name_text 
	END CASE 
	RETURN r_desc_text 
END FUNCTION 

############################################################
# FUNCTION display_voucher_total()
#
#
############################################################
FUNCTION display_voucher_total() 
	SELECT sum(dist_amt), 
	sum(dist_qty) 
	INTO glob_rec_voucher.dist_amt, 
	glob_rec_voucher.dist_qty 
	FROM t_voucherdist 

	IF glob_rec_voucher.dist_amt IS NULL THEN 
		LET glob_rec_voucher.dist_amt = 0 
	END IF 
	IF glob_rec_voucher.dist_qty IS NULL THEN 
		LET glob_rec_voucher.dist_qty = 0 
	END IF 
	
	DISPLAY glob_rec_voucher.total_amt, 
	glob_rec_voucher.dist_amt, 
	glob_rec_voucher.dist_qty 
	TO voucher.total_amt, 
	voucher.dist_amt, 
	voucher.dist_qty 

END FUNCTION 

############################################################
# FUNCTION disburse_distribution()
#
#
############################################################
FUNCTION disburse_distribution() 
	DEFINE l_rec_disbdetl RECORD LIKE disbdetl.* 
	DEFINE l_rec_voucherdist RECORD LIKE voucherdist.* 
	DEFINE l_total_qty LIKE disbhead.total_qty 
	DEFINE l_dist_amt LIKE voucherdist.dist_amt 

	LET l_dist_amt = glob_rec_voucher.total_amt - glob_rec_voucher.dist_amt 
	CALL enter_disb(glob_rec_voucher.cmpy_code,glob_rec_vendor.usual_acct_code,l_dist_amt) 
	RETURNING l_rec_disbdetl.disb_code,l_dist_amt 

	IF l_rec_disbdetl.disb_code IS NOT NULL AND l_dist_amt > 0 THEN 
		SELECT total_qty INTO l_total_qty 
		FROM disbhead 
		WHERE cmpy_code = glob_rec_voucher.cmpy_code 
		AND disb_code = l_rec_disbdetl.disb_code 

		DECLARE c_disbdetl CURSOR FOR 
		SELECT * FROM disbdetl 
		WHERE cmpy_code = glob_rec_voucher.cmpy_code 
		AND disb_code = l_rec_disbdetl.disb_code 

		SELECT max(line_num) INTO glob_rec_voucher.line_num 
		FROM t_voucherdist 

		IF glob_rec_voucher.line_num IS NULL THEN 
			LET glob_rec_voucher.line_num = 0 
		END IF 

		FOREACH c_disbdetl INTO l_rec_disbdetl.* 
			INITIALIZE l_rec_voucherdist.* TO NULL 
			LET glob_rec_voucher.line_num = glob_rec_voucher.line_num + 1 
			LET l_rec_voucherdist.line_num = glob_rec_voucher.line_num 
			LET l_rec_voucherdist.type_ind = "G" 
			LET l_rec_voucherdist.acct_code = l_rec_disbdetl.acct_code 
			LET l_rec_voucherdist.desc_text = l_rec_disbdetl.desc_text 
			LET l_rec_voucherdist.analysis_text = l_rec_disbdetl.analysis_text 
			LET l_rec_voucherdist.dist_amt = l_dist_amt * (l_rec_disbdetl.disb_qty/l_total_qty) 
			IF l_rec_voucherdist.dist_amt IS NULL THEN 
				LET l_rec_voucherdist.dist_amt = 0 
			END IF 
			LET l_rec_voucherdist.dist_qty = 0 
			INSERT INTO t_voucherdist VALUES (l_rec_voucherdist.*) 
		END FOREACH 

		RETURN true 
	ELSE 
		RETURN false 
	END IF 
END FUNCTION