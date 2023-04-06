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
# \file
# \brief module - P61b - New Accounts Payable Debit Distribution
#                - distributes the debit TO gl code
#                - single line entry with GL batch LIKE line descripts.
#                - provides distributions AND online deletion of lines.
#  NB: This program requires temp table t_debitdist TO be created
#
############################################################

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P6_GROUP_GLOBALS.4gl"
GLOBALS "../ap/P61_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################

GLOBALS 
	#DEFINE pr_vendor RECORD LIKE vendor.*
	DEFINE glob_rec_debithead RECORD LIKE debithead.* 
	DEFINE glob_default_text CHAR(40) 
	DEFINE glob_desc_ind CHAR(1) 
	DEFINE glob_base_currency LIKE glparms.base_currency_code 
END GLOBALS 


############################################################
# FUNCTION dist_debit(p_cmpy_code,p_kandoouser_sign_on_code,p_rec_debithead)
#
#
############################################################
FUNCTION dist_debit(p_cmpy_code,p_kandoouser_sign_on_code,p_rec_debithead) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE p_rec_debithead RECORD LIKE debithead.* 
	DEFINE l_rec_company RECORD LIKE company.* 
	DEFINE l_rec_debitdist RECORD LIKE debitdist.* 
	DEFINE l_rec_s_debitdist RECORD LIKE debitdist.* 
	DEFINE l_rec_s_debitdist_uom_code LIKE coa.uom_code 
	DEFINE l_arr_rec_debitdist DYNAMIC ARRAY OF #array[200] OF RECORD 
		RECORD 
			scroll_flag CHAR(1), 
			line_num LIKE debitdist.line_num, 
			type_ind LIKE debitdist.type_ind, 
			acct_code LIKE debitdist.acct_code, 
			dist_amt LIKE debitdist.dist_amt, 
			dist_qty LIKE debitdist.dist_qty, 
			uom_code LIKE coa.uom_code 
		END RECORD 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_idx SMALLINT 
	DEFINE l_repeat_ind SMALLINT 
	DEFINE l_temp_text CHAR(20) 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE i SMALLINT

		LET glob_rec_debithead.* = p_rec_debithead.* ## move debit TO global 
		SELECT * INTO l_rec_company.* FROM company 
		WHERE cmpy_code = p_cmpy_code 
		IF status = NOTFOUND THEN 
			LET l_msgresp=kandoomsg("P",5000,"") 
			#5000" Company does NOT Exist"
			EXIT PROGRAM 
		END IF 
		SELECT * INTO glob_rec_vendor.* FROM vendor 
		WHERE cmpy_code = p_cmpy_code 
		AND vend_code = glob_rec_debithead.vend_code 
		IF status = NOTFOUND THEN 
			LET l_msgresp=kandoomsg("P",9014,"") 
			#9014" Logic Error: Vendor does NOT Exist"
			RETURN FALSE 
		END IF 
		SELECT base_currency_code INTO glob_base_currency 
		FROM glparms 
		WHERE cmpy_code = glob_rec_debithead.cmpy_code 
		AND key_code = "1" 
		IF status = NOTFOUND THEN 
			#P5007 GL Parameters Not Set up
			LET l_msgresp=kandoomsg("P",5007,"") 
			RETURN 
		END IF 
		DISPLAY BY NAME glob_rec_debithead.vend_code, 
		glob_rec_vendor.name_text, 
		glob_rec_debithead.debit_num 


		DISPLAY BY NAME glob_rec_debithead.currency_code 
		attribute(green) 

		CASE get_kandoooption_feature_state('AP','MS') 
			WHEN 'V' 
				LET glob_desc_ind = "3" 
			WHEN 'D' 
				LET glob_desc_ind = "2" 
			OTHERWISE 
				LET glob_desc_ind = "1" 
		END CASE 

		SELECT unique 1 FROM t_debitdist 
		IF status = 0 THEN 
			IF l_rec_company.module_text[10] = "J" THEN 
				SELECT unique 1 
				FROM activity, 
				t_debitdist 
				WHERE activity.cmpy_code = p_cmpy_code 
				AND activity.job_code = t_debitdist.job_code 
				AND activity.var_code = t_debitdist.var_code 
				AND activity.activity_code = t_debitdist.act_code 
				AND activity.finish_flag = "Y" 
				IF status = 0 THEN 
					LET l_msgresp=kandoomsg("P",7026,"") 
					#P7026" debit IS distributed TO close JM activities"
					RETURN FALSE 
				END IF 
			END IF 
		ELSE 
			##
			## No previous distributions:
			## Set up default lines
			## 1. Tax line
			## 2. General Disbursement
			IF glob_rec_vendor.def_exp_ind = "G" THEN 
				SELECT salestax_acct_code INTO l_rec_debitdist.acct_code 
				FROM vendortype 
				WHERE cmpy_code = p_cmpy_code 
				AND type_code = glob_rec_vendor.type_code 
				IF l_rec_debitdist.acct_code IS NOT NULL THEN 
					SELECT ((tax_per/100)*glob_rec_debithead.total_amt) 
					INTO l_rec_debitdist.dist_amt 
					FROM tax 
					WHERE cmpy_code = p_cmpy_code 
					AND tax_code = glob_rec_debithead.tax_code 
					IF l_rec_debitdist.dist_amt > 0 THEN 
						SELECT * INTO l_rec_coa.* FROM coa 
						WHERE cmpy_code = p_cmpy_code 
						AND acct_code = l_rec_debitdist.acct_code 
						LET l_rec_debitdist.desc_text = 
						line_desc(l_rec_debitdist.acct_code,glob_desc_ind) 
						LET l_rec_debitdist.line_num = 1 
						LET l_rec_debitdist.type_ind = "G" 
						IF l_rec_coa.uom_code IS NULL THEN 
							LET l_rec_debitdist.dist_qty = NULL 
						ELSE 
							LET l_rec_debitdist.dist_qty = 0 
						END IF 
						INSERT INTO t_debitdist VALUES (l_rec_debitdist.*) 
					END IF 
				END IF 
				IF glob_rec_vendor.usual_acct_code IS NOT NULL THEN 
					IF l_rec_debitdist.line_num = 1 THEN 
						LET l_rec_debitdist.line_num = 2 
					ELSE 
						LET l_rec_debitdist.line_num = 1 
					END IF 
					LET l_rec_debitdist.type_ind = "G" 
					LET l_rec_debitdist.acct_code = glob_rec_vendor.usual_acct_code 
					SELECT * INTO l_rec_coa.* FROM coa 
					WHERE cmpy_code = p_cmpy_code 
					AND acct_code = l_rec_debitdist.acct_code 
					LET l_rec_debitdist.desc_text = 
					line_desc(l_rec_debitdist.acct_code,glob_desc_ind) 
					LET l_rec_debitdist.dist_amt = 0 
					IF l_rec_coa.uom_code IS NULL THEN 
						LET l_rec_debitdist.dist_qty = NULL 
					ELSE 
						LET l_rec_debitdist.dist_qty = 0 
					END IF 
					INSERT INTO t_debitdist VALUES (l_rec_debitdist.*) 
				END IF 
			END IF 
		END IF 

		DECLARE c_t_debitdist CURSOR FOR 
		SELECT * FROM t_debitdist 
		WHERE acct_code IS NOT NULL 
		AND dist_amt IS NOT NULL 
		ORDER BY line_num 

		WHILE TRUE 
			LET l_msgresp=kandoomsg("P",1002,"") 
			#P1002 Searching database - Please Wait
			OPTIONS INSERT KEY f1, 
			DELETE KEY f2 
			LET l_idx = 0 
			OPEN c_t_debitdist 

			FOREACH c_t_debitdist INTO l_rec_debitdist.* 
				LET l_idx = l_idx + 1 
				UPDATE t_debitdist 
				SET line_num = l_idx 
				WHERE line_num = l_rec_debitdist.line_num 
				LET l_arr_rec_debitdist[l_idx].line_num = l_idx 
				LET l_arr_rec_debitdist[l_idx].type_ind = l_rec_debitdist.type_ind 
				LET l_arr_rec_debitdist[l_idx].acct_code = l_rec_debitdist.acct_code 
				LET l_arr_rec_debitdist[l_idx].dist_amt = l_rec_debitdist.dist_amt 
				LET l_arr_rec_debitdist[l_idx].dist_qty = l_rec_debitdist.dist_qty 
				SELECT uom_code INTO l_arr_rec_debitdist[l_idx].uom_code FROM coa 
				WHERE cmpy_code = p_cmpy_code 
				AND acct_code = l_rec_debitdist.acct_code 
				IF l_arr_rec_debitdist[l_idx].uom_code IS NULL 
				AND l_arr_rec_debitdist[l_idx].dist_qty = 0 THEN 
					LET l_arr_rec_debitdist[l_idx].dist_qty = NULL 
				END IF 
				IF l_idx = 200 THEN 
					LET l_msgresp=kandoomsg("P",9017,l_idx) 
					#P9017 " First 200 lines selected"
					EXIT FOREACH 
				END IF 
			END FOREACH 

			LET l_repeat_ind = FALSE 

			CALL set_count(l_idx) 

			LET l_msgresp=kandoomsg("P",1013,"") 
			#1013 F1 Add F2 Delete F8 Save Desc F9 Toggle Desc. F10 Disburse

			INPUT ARRAY l_arr_rec_debitdist WITHOUT DEFAULTS FROM sr_debitdist.* attribute(UNBUFFERED,append ROW = FALSE, auto append = FALSE) 

				BEFORE INPUT 
					CALL publish_toolbar("kandoo","P61B","inp-arr-debitdist-1") 
					CALL disp_total() 
					LET l_temp_text = kandooword("debithead.desc_ind",glob_desc_ind) 
					DISPLAY l_temp_text TO desc_mode
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON KEY (F10) 
					IF disburse_dist() THEN 
						LET l_repeat_ind = TRUE 
						EXIT INPUT 
					END IF 

				ON KEY (control-b) infield (acct_code) 
					LET l_temp_text = show_acct(p_cmpy_code) 
					OPTIONS INSERT KEY f1, 
					DELETE KEY f2 
					IF l_temp_text IS NOT NULL THEN 
						LET l_arr_rec_debitdist[l_idx].acct_code = l_temp_text 
						NEXT FIELD acct_code 
					END IF 

				ON KEY (F9) 
					CASE glob_desc_ind 
						WHEN "1" 
							LET glob_desc_ind = "2" 
						WHEN "2" 
							LET glob_desc_ind = "3" 
						OTHERWISE 
							LET glob_desc_ind = "1" 
					END CASE 
					LET l_temp_text = kandooword("debithead.desc_ind",glob_desc_ind) 
					DISPLAY l_temp_text TO desc_mode 

				BEFORE ROW 
					LET l_idx = arr_curr() 
					#            LET scrn = scr_line()
					IF l_idx > 0 THEN 
						IF l_arr_rec_debitdist[l_idx].line_num IS NOT NULL 
						AND l_arr_rec_debitdist[l_idx].line_num != 0 THEN 
							DISPLAY l_arr_rec_debitdist[l_idx].line_num TO idx 
						END IF 
						NEXT FIELD scroll_flag 
					END IF 

				BEFORE INSERT 
					INITIALIZE l_rec_debitdist.* TO NULL 
					INITIALIZE l_rec_s_debitdist.* TO NULL 
					LET l_rec_s_debitdist_uom_code = NULL 
					INITIALIZE l_arr_rec_debitdist[l_idx].* TO NULL 
					##
					## A minor Informix problem exists WHERE WHEN pressing delete
					## on last line actually performs a delete AND an INSERT. To
					## avoid this the following check IS included.
					##
					IF fgl_lastkey() = fgl_keyval("delete") 
					OR fgl_lastkey() = fgl_keyval("interrupt") THEN 
						NEXT FIELD scroll_flag 
					ELSE 
						NEXT FIELD type_ind 
					END IF 

 

				BEFORE FIELD scroll_flag 
					SELECT * INTO l_rec_debitdist.* FROM t_debitdist 
					WHERE line_num = l_arr_rec_debitdist[l_idx].line_num 
					IF status = NOTFOUND THEN 
						INITIALIZE l_rec_debitdist.* TO NULL 
					END IF 
					LET l_rec_s_debitdist.* = l_rec_debitdist.* 
					LET l_rec_s_debitdist_uom_code = l_arr_rec_debitdist[l_idx].uom_code 
					IF line_detail(FALSE,l_rec_debitdist.*) THEN 
					END IF 

				BEFORE FIELD type_ind 
					IF l_arr_rec_debitdist[l_idx].line_num IS NULL 
					OR l_arr_rec_debitdist[l_idx].line_num = 0 THEN 
						LET l_arr_rec_debitdist[l_idx].acct_code = glob_rec_vendor.usual_acct_code 
					END IF 
					INITIALIZE l_rec_coa.* TO NULL 
					SELECT * INTO l_rec_coa.* FROM coa 
					WHERE cmpy_code = p_cmpy_code 
					AND acct_code = l_arr_rec_debitdist[l_idx].acct_code 
					IF l_arr_rec_debitdist[l_idx].line_num IS NULL 
					OR l_arr_rec_debitdist[l_idx].line_num = 0 THEN 
						SELECT max(line_num) INTO l_arr_rec_debitdist[l_idx].line_num 
						FROM t_debitdist 
						IF l_arr_rec_debitdist[l_idx].line_num IS NULL THEN 
							LET l_arr_rec_debitdist[l_idx].line_num = 1 
						ELSE 
							LET l_arr_rec_debitdist[l_idx].line_num = 
							l_arr_rec_debitdist[l_idx].line_num + 1 
						END IF 
						LET l_arr_rec_debitdist[l_idx].type_ind = glob_rec_vendor.def_exp_ind 
						LET l_arr_rec_debitdist[l_idx].dist_amt = 0 
						IF l_rec_coa.uom_code IS NULL THEN 
							LET l_arr_rec_debitdist[l_idx].dist_qty = NULL 
							LET l_arr_rec_debitdist[l_idx].uom_code = NULL 
						END IF 
						DISPLAY l_arr_rec_debitdist[l_idx].line_num TO idx 

						#               DISPLAY l_arr_rec_debitdist[l_idx].* TO sr_debitdist[scrn].*

						LET l_rec_debitdist.type_ind = l_arr_rec_debitdist[l_idx].type_ind 
						LET l_rec_debitdist.line_num = l_arr_rec_debitdist[l_idx].line_num 
						LET l_rec_debitdist.acct_code = glob_rec_vendor.usual_acct_code 
						LET l_rec_debitdist.desc_text = 
						line_desc(l_rec_debitdist.acct_code,glob_desc_ind) 
						IF line_detail(FALSE,l_rec_debitdist.*) THEN 
						END IF 
					ELSE 
						IF l_arr_rec_debitdist[l_idx].type_ind IS NOT NULL THEN 
							NEXT FIELD acct_code 
						END IF 
					END IF 

				AFTER FIELD type_ind 
					IF l_arr_rec_debitdist[l_idx].type_ind IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered
						NEXT FIELD type_ind 
					END IF 
					UPDATE t_debitdist 
					SET type_ind = l_arr_rec_debitdist[l_idx].type_ind, 
					acct_code = l_arr_rec_debitdist[l_idx].acct_code, 
					desc_text = l_rec_debitdist.desc_text, 
					dist_amt = l_arr_rec_debitdist[l_idx].dist_amt, 
					dist_qty = l_arr_rec_debitdist[l_idx].dist_qty 
					WHERE line_num = l_arr_rec_debitdist[l_idx].line_num 
					IF sqlca.sqlerrd[3] = 0 THEN 
						IF l_arr_rec_debitdist[l_idx].type_ind <> "J" 
						AND l_arr_rec_debitdist[l_idx].type_ind <> "W" THEN 
							LET l_rec_debitdist.type_ind = l_arr_rec_debitdist[l_idx].type_ind 
							INSERT INTO t_debitdist VALUES (l_rec_debitdist.*) 
						END IF 
					END IF 
					CASE 
						WHEN fgl_lastkey() = fgl_keyval("accept") 
							IF l_rec_debitdist.analysis_text IS NULL 
							AND l_rec_coa.analy_req_flag = "Y" THEN 
								LET l_msgresp=kandoomsg("P",9016,"") 
								#9016 " Analysis IS required "
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
							DELETE FROM t_debitdist 
							WHERE line_num = l_arr_rec_debitdist[l_idx].line_num 
							LET l_arr_rec_debitdist[l_idx].line_num = 0 
							NEXT FIELD type_ind 
					END CASE 

				BEFORE FIELD acct_code 
					CASE l_arr_rec_debitdist[l_idx].type_ind 
						WHEN "J" 
							IF l_rec_company.module_text[10] = "J" THEN 
								CALL cr_jm_dist(p_cmpy_code,p_kandoouser_sign_on_code) 
								LET l_repeat_ind = TRUE 
								EXIT INPUT 
							ELSE 
								LET l_arr_rec_debitdist[l_idx].type_ind = "G" 
								NEXT FIELD type_ind 
							END IF 
						WHEN "S" 
							IF l_rec_company.module_text[12] = "L" THEN 
								CALL cr_lc_dist(p_cmpy_code,p_kandoouser_sign_on_code,l_arr_rec_debitdist[l_idx].line_num) 
								LET l_repeat_ind = TRUE 
								EXIT INPUT 
							ELSE 
								LET l_arr_rec_debitdist[l_idx].type_ind = "G" 
								NEXT FIELD type_ind 
							END IF 
						WHEN "W" 
							IF l_rec_company.module_text[23] = "W" THEN 
								CALL cr_wo_dist(p_cmpy_code,p_kandoouser_sign_on_code,l_arr_rec_debitdist[l_idx].line_num) 
								LET l_repeat_ind = TRUE 
								EXIT INPUT 
							ELSE 
								LET l_arr_rec_debitdist[l_idx].type_ind = "G" 
								NEXT FIELD type_ind 
							END IF 
						OTHERWISE 
					END CASE 

				AFTER FIELD acct_code 
					IF l_arr_rec_debitdist[l_idx].acct_code IS NULL THEN 
						LET l_msgresp=kandoomsg("P",9018,"") 
						#P9018" Account must be entered - Try Window"
						NEXT FIELD acct_code 
					END IF 
					CALL verify_acct_code(p_cmpy_code,l_arr_rec_debitdist[l_idx].acct_code, 
					glob_rec_debithead.year_num, 
					glob_rec_debithead.period_num) 
					RETURNING l_rec_coa.* 
					IF l_rec_coa.acct_code IS NULL THEN 
						NEXT FIELD acct_code 
					END IF 
					IF l_arr_rec_debitdist[l_idx].acct_code != l_rec_coa.acct_code THEN 
						LET l_arr_rec_debitdist[l_idx].acct_code = l_rec_coa.acct_code 
						NEXT FIELD acct_code 
					END IF 
					IF NOT acct_type(p_cmpy_code,l_rec_coa.acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
						NEXT FIELD acct_code 
					END IF 
					IF l_rec_debitdist.acct_code IS NULL 
					OR l_rec_debitdist.acct_code != l_rec_coa.acct_code THEN 
						LET l_rec_debitdist.desc_text = 
						line_desc(l_rec_coa.acct_code,glob_desc_ind) 
						LET l_rec_debitdist.acct_code = l_rec_coa.acct_code 
						IF line_detail(FALSE,l_rec_debitdist.*) THEN 
						END IF 
					END IF 
					IF l_rec_coa.uom_code IS NULL THEN 
						LET l_arr_rec_debitdist[l_idx].uom_code = NULL 
						LET l_arr_rec_debitdist[l_idx].dist_qty = NULL 
					ELSE 
						LET l_arr_rec_debitdist[l_idx].uom_code = l_rec_coa.uom_code 
					END IF 
					IF l_rec_coa.uom_code IS NOT NULL 
					AND l_arr_rec_debitdist[l_idx].dist_qty IS NULL THEN 
						LET l_arr_rec_debitdist[l_idx].dist_qty = 0 
					END IF 
					#            DISPLAY l_arr_rec_debitdist[l_idx].dist_qty,
					#                    l_arr_rec_debitdist[l_idx].uom_code
					#                 TO sr_debitdist[scrn].dist_qty,
					#                    sr_debitdist[scrn].uom_code

					UPDATE t_debitdist 
					SET acct_code = l_arr_rec_debitdist[l_idx].acct_code, 
					dist_qty = l_arr_rec_debitdist[l_idx].dist_qty 
					WHERE line_num = l_arr_rec_debitdist[l_idx].line_num 

					CALL disp_total() 

					CASE 
						WHEN fgl_lastkey() = fgl_keyval("accept") 
							IF l_rec_debitdist.analysis_text IS NULL 
							AND l_rec_coa.analy_req_flag = "Y" THEN 
								LET l_msgresp=kandoomsg("P",9016,"") 
								#9016 " Analysis IS required "
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
							NEXT FIELD scroll_flag 
						OTHERWISE 
							NEXT FIELD acct_code 
					END CASE 

				BEFORE FIELD dist_amt 
					IF (glob_rec_debithead.total_amt - glob_rec_debithead.dist_amt) > 0 
					AND l_arr_rec_debitdist[l_idx].dist_amt = 0 THEN 
						LET l_arr_rec_debitdist[l_idx].dist_amt = glob_rec_debithead.total_amt 
						- glob_rec_debithead.dist_amt 
					END IF 

				AFTER FIELD dist_amt 
					CASE 
						WHEN l_arr_rec_debitdist[l_idx].dist_amt IS NULL 
							LET l_arr_rec_debitdist[l_idx].dist_amt = 0 
							NEXT FIELD dist_amt 
						WHEN l_arr_rec_debitdist[l_idx].dist_amt < 0 
							LET l_msgresp=kandoomsg("P",9019,"") 
							#9019 " Amount must be positive "
							LET l_arr_rec_debitdist[l_idx].dist_amt = 0 
							NEXT FIELD dist_amt 
					END CASE 
					UPDATE t_debitdist 
					SET dist_amt = l_arr_rec_debitdist[l_idx].dist_amt 
					WHERE line_num = l_arr_rec_debitdist[l_idx].line_num 
					CALL disp_total() 
					IF glob_rec_debithead.total_amt < glob_rec_debithead.dist_amt THEN 
						LET l_msgresp=kandoomsg("P",9015,"") 
						#9015" This will over distribute the debit"
					END IF 
					CASE 
						WHEN fgl_lastkey() = fgl_keyval("accept") 
							IF l_rec_debitdist.analysis_text IS NULL 
							AND l_rec_coa.analy_req_flag = "Y" THEN 
								LET l_msgresp=kandoomsg("P",9016,"") 
								#9016 " Analysis IS required "
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
					IF l_arr_rec_debitdist[l_idx].uom_code IS NULL THEN 
						NEXT FIELD NEXT 
					END IF 

				AFTER FIELD dist_qty 
					UPDATE t_debitdist 
					SET dist_qty = l_arr_rec_debitdist[l_idx].dist_qty 
					WHERE line_num = l_arr_rec_debitdist[l_idx].line_num 
					CALL disp_total() 
					CASE 
						WHEN fgl_lastkey() = fgl_keyval("accept") 
							IF l_rec_debitdist.analysis_text IS NULL 
							AND l_rec_coa.analy_req_flag = "Y" THEN 
								LET l_msgresp=kandoomsg("P",9016,"") 
								#9016 " Analysis IS required "
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
							NEXT FIELD dist_qty 
					END CASE 

				BEFORE FIELD uom_code 
					IF NOT line_detail(TRUE,l_rec_debitdist.*) THEN 
						DELETE FROM t_debitdist 
						WHERE line_num = l_arr_rec_debitdist[l_idx].line_num 
						IF l_rec_s_debitdist.acct_code IS NOT NULL THEN 
							LET l_arr_rec_debitdist[l_idx].line_num = l_rec_s_debitdist.line_num 
							LET l_arr_rec_debitdist[l_idx].type_ind = l_rec_s_debitdist.type_ind 
							LET l_arr_rec_debitdist[l_idx].acct_code = l_rec_s_debitdist.acct_code 
							LET l_arr_rec_debitdist[l_idx].dist_amt = l_rec_s_debitdist.dist_amt 
							LET l_arr_rec_debitdist[l_idx].dist_qty = l_rec_s_debitdist.dist_qty 
							LET l_arr_rec_debitdist[l_idx].uom_code = l_rec_s_debitdist_uom_code 
							#                  DISPLAY l_arr_rec_debitdist[l_idx].* TO sr_debitdist[scrn].*

							INSERT INTO t_debitdist VALUES (l_rec_s_debitdist.*) 
						ELSE 
							FOR i = arr_curr() TO arr_count() 
								IF l_arr_rec_debitdist[i+1].acct_code IS NOT NULL THEN 
									LET l_arr_rec_debitdist[i].* = l_arr_rec_debitdist[i+1].* 
								ELSE 
									INITIALIZE l_arr_rec_debitdist[i].* TO NULL 
								END IF 
								#                     IF scrn <= 7 THEN
								#                        DISPLAY l_arr_rec_debitdist[i].* TO sr_debitdist[scrn].*
								#
								#                        LET scrn = scrn + 1
								#                     END IF
							END FOR 
							#                  LET scrn = scr_line()
						END IF 
						CALL disp_total() 
						NEXT FIELD scroll_flag 
					END IF 

				BEFORE DELETE 
					DELETE FROM t_debitdist 
					WHERE line_num = l_arr_rec_debitdist[l_idx].line_num 
					CALL disp_total() 
					INITIALIZE l_arr_rec_debitdist[l_idx].* TO NULL 
					NEXT FIELD scroll_flag 

				AFTER ROW 
					SELECT unique 1 FROM t_debitdist 
					WHERE line_num = l_arr_rec_debitdist[l_idx].line_num 
					IF status = NOTFOUND THEN 
						INITIALIZE l_arr_rec_debitdist[l_idx].* TO NULL 
					END IF 
					#            DISPLAY l_arr_rec_debitdist[l_idx].* TO sr_debitdist[scrn].*

				AFTER INPUT 
					#DEL & ESC go back TO scroll_flag IF CURSOR NOT on scroll_flag
					IF int_flag OR quit_flag THEN 
						IF NOT infield(scroll_flag) THEN 
							LET int_flag = FALSE 
							LET quit_flag = FALSE 
							DELETE FROM t_debitdist 
							WHERE line_num = l_arr_rec_debitdist[l_idx].line_num 
							IF l_rec_s_debitdist.acct_code IS NOT NULL THEN 
								LET l_arr_rec_debitdist[l_idx].line_num = l_rec_s_debitdist.line_num 
								LET l_arr_rec_debitdist[l_idx].type_ind = l_rec_s_debitdist.type_ind 
								LET l_arr_rec_debitdist[l_idx].acct_code=l_rec_s_debitdist.acct_code 
								LET l_arr_rec_debitdist[l_idx].dist_amt = l_rec_s_debitdist.dist_amt 
								LET l_arr_rec_debitdist[l_idx].dist_qty = l_rec_s_debitdist.dist_qty 
								LET l_arr_rec_debitdist[l_idx].uom_code = l_rec_s_debitdist_uom_code 
								#                     DISPLAY l_arr_rec_debitdist[l_idx].* TO sr_debitdist[scrn].*

								INSERT INTO t_debitdist VALUES (l_rec_s_debitdist.*) 
							ELSE 
								FOR i = arr_curr() TO arr_count() 
									IF l_arr_rec_debitdist[i+1].acct_code IS NOT NULL THEN 
										LET l_arr_rec_debitdist[i].* = l_arr_rec_debitdist[i+1].* 
									ELSE 
										INITIALIZE l_arr_rec_debitdist[i].* TO NULL 
									END IF 
									#                        IF scrn <= 7 THEN
									#                           DISPLAY l_arr_rec_debitdist[i].* TO sr_debitdist[scrn].*
									#
									#                           LET scrn = scrn + 1
									#                        END IF
								END FOR 
								#                     LET scrn = scr_line()
							END IF 
							CALL disp_total() 
							NEXT FIELD scroll_flag 
						END IF 
					ELSE 
						IF glob_rec_debithead.dist_amt > glob_rec_debithead.total_amt THEN 
							LET l_msgresp=kandoomsg("P",7010,"") 
							#P7010" debit Distributions Exceed Total"
							CONTINUE INPUT 
						END IF 
					END IF 

			END INPUT 

			IF NOT l_repeat_ind THEN 
				EXIT WHILE 
			END IF 

		END WHILE 

		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			RETURN FALSE 
		ELSE 
			RETURN TRUE 
		END IF 
END FUNCTION 




############################################################
# FUNCTION line_detail(p_update_ind,p_rec_debitdist)
#
#
############################################################
FUNCTION line_detail(p_update_ind,p_rec_debitdist) 
	DEFINE p_update_ind SMALLINT ## TRUE=update FALSE=display 
	DEFINE p_rec_debitdist RECORD LIKE debitdist.* 
	DEFINE l_rec_s_debitdist RECORD LIKE debitdist.* 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_rec_prompt 
	RECORD 
		line_1 CHAR(15), 
		line_2 CHAR(15) 
	END RECORD 
	DEFINE l_temp_text CHAR(30) 
	DEFINE l_msgresp LIKE language.yes_flag 

	SELECT * INTO l_rec_coa.* FROM coa 
	WHERE cmpy_code = glob_rec_debithead.cmpy_code 
	AND acct_code = p_rec_debitdist.acct_code 
	IF l_rec_coa.analy_prompt_text IS NULL THEN 
		LET l_rec_coa.analy_prompt_text = "Analysis" 
	END IF 
	LET l_temp_text = l_rec_coa.analy_prompt_text clipped,".................." 
	LET l_rec_coa.analy_prompt_text = l_temp_text 
	CASE p_rec_debitdist.type_ind 
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
		OTHERWISE 
			LET p_rec_debitdist.job_code = NULL 
			LET p_rec_debitdist.res_code = NULL 
	END CASE 

	DISPLAY BY NAME l_rec_coa.analy_prompt_text, 
	l_rec_prompt.line_1, 
	l_rec_prompt.line_2 

	INPUT BY NAME p_rec_debitdist.analysis_text, 
	p_rec_debitdist.desc_text, 
	p_rec_debitdist.job_code, 
	p_rec_debitdist.res_code WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P61B","inp-debitdist-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "NOTES" infield (desc_text)
		--ON KEY (control-n) infield (desc_text) 
			LET p_rec_debitdist.desc_text = 
			sys_noter(glob_rec_debithead.cmpy_code,p_rec_debitdist.desc_text) 
			NEXT FIELD desc_text 


		BEFORE FIELD analysis_text 
			IF p_update_ind THEN 
				LET l_rec_s_debitdist.* = p_rec_debitdist.* 
			ELSE 
				EXIT INPUT 
			END IF 
		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF glob_desc_ind = "2" THEN 
					LET glob_default_text = p_rec_debitdist.desc_text 
				END IF 
				IF p_rec_debitdist.analysis_text IS NULL 
				AND l_rec_coa.analy_req_flag = "Y" THEN 
					LET l_msgresp=kandoomsg("P",9016,"") 
					#9016 " Analysis IS required "
					NEXT FIELD analysis_text 
				END IF 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN FALSE 
	ELSE 
		UPDATE t_debitdist 
		SET analysis_text = p_rec_debitdist.analysis_text, 
		desc_text = p_rec_debitdist.desc_text 
		WHERE line_num = p_rec_debitdist.line_num 
		RETURN TRUE 
	END IF 
END FUNCTION 




############################################################
# FUNCTION line_desc(p_acct_code,p_mode_ind)
#
#
############################################################
FUNCTION line_desc(p_acct_code,p_mode_ind) 
	DEFINE p_acct_code LIKE debitdist.acct_code 
	DEFINE p_mode_ind CHAR(1) 
	DEFINE l_desc_text LIKE debitdist.desc_text 
	DEFINE l_msgresp LIKE language.yes_flag 

	CASE p_mode_ind 
		WHEN "1" ### account description 
			SELECT desc_text INTO l_desc_text FROM coa 
			WHERE cmpy_code = glob_rec_debithead.cmpy_code 
			AND acct_code = p_acct_code 
		WHEN "2" ### default description 
			LET l_desc_text = glob_default_text 
		WHEN "3" ### vendor's NAME 
			LET l_desc_text = glob_rec_vendor.name_text 
	END CASE 
	RETURN l_desc_text 
END FUNCTION 



############################################################
# FUNCTION disp_total()
#
#
############################################################
FUNCTION disp_total() 
	SELECT sum(dist_amt), 
	sum(dist_qty) 
	INTO glob_rec_debithead.dist_amt, 
	glob_rec_debithead.dist_qty 
	FROM t_debitdist 
	IF glob_rec_debithead.dist_amt IS NULL THEN 
		LET glob_rec_debithead.dist_amt = 0 
	END IF 
	IF glob_rec_debithead.dist_qty IS NULL THEN 
		LET glob_rec_debithead.dist_qty = 0 
	END IF 
	DISPLAY glob_rec_debithead.total_amt, 
	glob_rec_debithead.dist_amt, 
	glob_rec_debithead.dist_qty 
	TO debithead.total_amt, 
	debithead.dist_amt, 
	debithead.dist_qty 

END FUNCTION 



############################################################
# FUNCTION cr_jm_dist(p_cmpy,p_kandoouser_sign_on_code)
#
#
############################################################
FUNCTION cr_jm_dist(p_cmpy,p_kandoouser_sign_on_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE l_rec_debitdist RECORD LIKE debitdist.* 
	DEFINE l_rec_jmparms RECORD LIKE jmparms.* 
	DEFINE l_arr_rowid DYNAMIC ARRAY OF INTEGER #array[200] OF INTEGER 
	DEFINE l_arr_rec_debitdist DYNAMIC ARRAY OF #array[200] OF RECORD 
		RECORD 
			scroll_flag CHAR(1), 
			res_code LIKE debitdist.res_code, 
			desc_text LIKE debitdist.desc_text, 
			job_code LIKE debitdist.job_code, 
			var_code LIKE debitdist.var_code, 
			act_code LIKE debitdist.act_code, 
			dist_amt LIKE debitdist.dist_amt 
		END RECORD 
	DEFINE l_rec_job RECORD LIKE job.* 
	DEFINE l_rec_activity RECORD LIKE activity.* 
	DEFINE l_rec_jmresource RECORD LIKE jmresource.* 
	DEFINE l_rec_jobledger RECORD LIKE jobledger.* 
	DEFINE l_rowid INTEGER 
	DEFINE l_idx SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE i SMALLINT

		SELECT * INTO l_rec_jmparms.* 
		FROM jmparms 
		WHERE cmpy_code = glob_rec_debithead.cmpy_code 
		AND key_code = "1" 
		IF status = NOTFOUND THEN 
			#P5010 Job Management Patameters Not Set up
			LET l_msgresp=kandoomsg("P",5010,"") 
			RETURN 
		END IF 

		OPEN WINDOW j147 with FORM "J147" 
		CALL winDecoration_j("J147") 

		LET l_msgresp=kandoomsg("P",1002,"") 
		#1002 Searching database pls wait
		DISPLAY glob_rec_debithead.vend_code, 
		glob_rec_vendor.name_text, 
		glob_rec_debithead.debit_num, 
		glob_rec_debithead.total_amt, 
		glob_rec_debithead.dist_amt 
		TO vend_code, 
		name_text, 
		vouch_code, 
		total_amt, 
		dist_amt 

		DISPLAY BY NAME glob_rec_debithead.currency_code 
		attribute(green) 

		### Informix bug workaround
		WHENEVER ERROR CONTINUE 
		SELECT * FROM t_debitdist WHERE rowid = 0 INTO temp t_jmdist with no LOG 
		IF sqlca.sqlcode < 0 THEN 
			DELETE FROM t_jmdist 
		END IF 
		INSERT INTO t_jmdist SELECT * FROM t_debitdist 
		WHENEVER ERROR stop 

		DECLARE c_debitdist CURSOR FOR 
		SELECT rowid, * FROM t_jmdist 
		WHERE type_ind = "J" 
		ORDER BY line_num 

		LET l_idx = 0 
		FOREACH c_debitdist INTO l_rowid, 
			l_rec_debitdist.* 
			LET l_idx = l_idx + 1 
			LET l_arr_rowid[l_idx] = l_rowid 
			LET l_arr_rec_debitdist[l_idx].res_code = l_rec_debitdist.res_code 
			LET l_arr_rec_debitdist[l_idx].job_code = l_rec_debitdist.job_code 
			LET l_arr_rec_debitdist[l_idx].var_code = l_rec_debitdist.var_code 
			LET l_arr_rec_debitdist[l_idx].act_code = l_rec_debitdist.act_code 
			LET l_arr_rec_debitdist[l_idx].desc_text = l_rec_debitdist.desc_text 
			LET l_arr_rec_debitdist[l_idx].dist_amt = l_rec_debitdist.dist_amt 
			IF l_idx = 200 THEN 
				LET l_msgresp=kandoomsg("P",9028,l_idx) 
				#P9028 Only first Job Management Vouchers Selected"
				EXIT FOREACH 
			END IF 
		END FOREACH 
		IF l_idx = 0 THEN 
			LET l_idx = 1 
			LET l_arr_rec_debitdist[1].var_code = NULL 
		END IF 
		OPTIONS DELETE KEY f2, 
		INSERT KEY f1 
		LET l_msgresp=kandoomsg("P",1038,"") 
		#1038 Enter Job Management Voucher Line - F1 Add F2 Delete
		CALL set_count(l_idx) 

		INPUT ARRAY l_arr_rec_debitdist WITHOUT DEFAULTS FROM sr_voucherdist.* 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","P61B","inp-arr-voucherdist-1") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE FIELD scroll_flag 
				LET l_idx = arr_curr() 
				#         LET scrn = scr_line()
				IF l_arr_rec_debitdist[l_idx].res_code IS NOT NULL THEN 
					#            DISPLAY l_arr_rec_debitdist[l_idx].*
					#                 TO sr_voucherdist[scrn].*

					SELECT * INTO l_rec_debitdist.* 
					FROM t_jmdist 
					WHERE rowid = l_arr_rowid[l_idx] 
					SELECT * INTO l_rec_jmresource.* 
					FROM jmresource 
					WHERE cmpy_code = p_cmpy 
					AND res_code = l_arr_rec_debitdist[l_idx].res_code 
					IF status = NOTFOUND THEN 
						LET l_rec_jmresource.desc_text = "********" 
					END IF 
					DISPLAY l_rec_jmresource.desc_text TO jmresource.desc_text 

					SELECT title_text INTO l_rec_job.title_text 
					FROM job 
					WHERE cmpy_code = p_cmpy 
					AND job_code = l_arr_rec_debitdist[l_idx].job_code 
					IF status = NOTFOUND THEN 
						LET l_rec_job.title_text = "********" 
					END IF 
					DISPLAY l_rec_job.title_text TO job.title_text 

					SELECT title_text INTO l_rec_activity.title_text 
					FROM activity 
					WHERE cmpy_code = p_cmpy 
					AND job_code = l_arr_rec_debitdist[l_idx].job_code 
					AND var_code = l_arr_rec_debitdist[l_idx].var_code 
					AND activity_code = l_arr_rec_debitdist[l_idx].act_code 
					IF status = NOTFOUND THEN 
						LET l_rec_activity.title_text = "********" 
					END IF 
					DISPLAY l_rec_activity.title_text TO activity.title_text 

					DISPLAY BY NAME l_rec_jmresource.unit_code, 
					l_rec_debitdist.trans_qty, 
					l_rec_debitdist.cost_amt, 
					l_rec_debitdist.charge_amt 

					LET l_rec_jobledger.trans_amt = l_rec_debitdist.dist_amt 
					LET l_rec_jobledger.charge_amt = l_rec_debitdist.charge_amt 
					* l_rec_debitdist.trans_qty 
					DISPLAY l_rec_jobledger.trans_amt, 
					l_rec_jobledger.charge_amt 
					TO jobledger.trans_amt, 
					jobledger.charge_amt 

				END IF 

			AFTER FIELD scroll_flag 
				IF fgl_lastkey() = fgl_keyval("down") THEN 
					IF arr_curr() = arr_count() THEN 
						LET l_msgresp=kandoomsg("P",9001,"") 
						#9001 There are no more rows in the direction ...
						NEXT FIELD scroll_flag 
					ELSE 
						IF l_arr_rec_debitdist[l_idx+1].res_code IS NULL THEN 
							LET l_msgresp=kandoomsg("P",9001,"") 
							#9001 There are no more rows in the direction ...
							NEXT FIELD scroll_flag 
						END IF 
					END IF 
				END IF 

			BEFORE FIELD res_code 
				LET l_arr_rowid[l_idx] = dist_jm_line(p_cmpy,l_arr_rowid[l_idx]) 
				SELECT * INTO l_rec_debitdist.* 
				FROM t_jmdist 
				WHERE rowid = l_arr_rowid[l_idx] 
				IF status = NOTFOUND THEN 
					FOR i = l_idx TO arr_count() 
						LET l_arr_rowid[i] = l_arr_rowid[i+1] 
						LET l_arr_rec_debitdist[i].* = l_arr_rec_debitdist[i+1].* 
						#               IF scrn <= 5 THEN
						#                  DISPLAY l_arr_rec_debitdist[i].*
						#                       TO sr_voucherdist[scrn].*
						#
						#                  LET scrn = scrn + 1
						#               END IF
					END FOR 
					LET l_arr_rowid[i] = 0 
					INITIALIZE l_arr_rec_debitdist[i].* TO NULL 
				ELSE 
					LET l_arr_rec_debitdist[l_idx].res_code = l_rec_debitdist.res_code 
					LET l_arr_rec_debitdist[l_idx].job_code = l_rec_debitdist.job_code 
					LET l_arr_rec_debitdist[l_idx].var_code = l_rec_debitdist.var_code 
					LET l_arr_rec_debitdist[l_idx].act_code = l_rec_debitdist.act_code 
					LET l_arr_rec_debitdist[l_idx].desc_text = l_rec_debitdist.desc_text 
					LET l_arr_rec_debitdist[l_idx].dist_amt = l_rec_debitdist.dist_amt 
				END IF 
				SELECT sum(dist_amt) INTO glob_rec_debithead.dist_amt FROM t_jmdist 
				DISPLAY BY NAME glob_rec_debithead.dist_amt 

				NEXT FIELD scroll_flag 

			BEFORE INSERT 
				FOR i = arr_count() TO l_idx step -1 
					LET l_arr_rowid[i+1] = l_arr_rowid[i] 
				END FOR 
				INITIALIZE l_arr_rec_debitdist[l_idx].* TO NULL 
				#         CLEAR sr_voucherdist[scrn].*
				LET l_arr_rowid[l_idx] = 0 
				NEXT FIELD res_code 

			BEFORE DELETE 
				DELETE FROM t_jmdist 
				WHERE rowid = l_arr_rowid[l_idx] 
				FOR i = l_idx TO arr_count() 
					LET l_arr_rowid[i] = l_arr_rowid[i+1] 
				END FOR 
				#      AFTER ROW
				#         DISPLAY l_arr_rec_debitdist[l_idx].*
				#              TO sr_voucherdist[scrn].*


		END INPUT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
		ELSE 
			LET l_msgresp=kandoomsg("P",1005,"") 
			#1005 Searching database pls wait
			DELETE FROM t_debitdist 
			INSERT INTO t_debitdist SELECT * FROM t_jmdist 
		END IF 

		CLOSE WINDOW j147 

END FUNCTION 




############################################################
# FUNCTION cr_lc_dist(p_cmpy,p_kandoouser_sign_on_code,p_line_num)
#
#
############################################################
FUNCTION cr_lc_dist(p_cmpy,p_kandoouser_sign_on_code,p_line_num) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE p_line_num SMALLINT 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_rec_debitdist RECORD LIKE debitdist.* 
	DEFINE l_rec_shipcosttype RECORD LIKE shipcosttype.* 
	DEFINE l_rec_shiphead RECORD LIKE shiphead.* 
	DEFINE l_rec_smparms RECORD LIKE smparms.* 
	DEFINE l_old_res_code LIKE debitdist.res_code 
	DEFINE l_old_job_code LIKE debitdist.job_code 
	DEFINE l_pr_flag INTEGER 
	DEFINE l_temp_text CHAR(60) 
	DEFINE l_winds_text CHAR(80) 
	DEFINE l_msgresp LIKE language.yes_flag 

	INITIALIZE l_rec_debitdist.* TO NULL 
	INITIALIZE l_rec_coa.* TO NULL 
	SELECT * INTO l_rec_debitdist.* FROM t_debitdist 
	WHERE line_num = p_line_num 
	IF status = 0 THEN 
		SELECT * INTO l_rec_coa.* FROM coa 
		WHERE acct_code = l_rec_debitdist.acct_code 
		AND cmpy_code = p_cmpy 

		SELECT * INTO l_rec_shipcosttype.* FROM shipcosttype 
		WHERE cost_type_code = l_rec_debitdist.res_code 
		AND cmpy_code = p_cmpy 

		SELECT * INTO l_rec_shiphead.* FROM shiphead 
		WHERE ship_code = l_rec_debitdist.job_code 
		AND cmpy_code = p_cmpy 
	END IF 
	IF l_rec_coa.analy_prompt_text IS NULL THEN 
		LET l_rec_coa.analy_prompt_text = "Analysis" 
	END IF 
	LET l_temp_text = l_rec_coa.analy_prompt_text clipped,".................." 
	LET l_rec_coa.analy_prompt_text = l_temp_text 

	OPEN WINDOW p231 with FORM "P231" 
	CALL windecoration_p("P231") 

	DISPLAY BY NAME l_rec_coa.analy_prompt_text 
	attribute(white) 
	DISPLAY BY NAME l_rec_debitdist.job_code, 
	l_rec_debitdist.res_code, 
	l_rec_debitdist.desc_text, 
	l_rec_debitdist.acct_code, 
	l_rec_debitdist.dist_amt, 
	l_rec_debitdist.analysis_text, 
	l_rec_debitdist.dist_qty 

	DISPLAY l_rec_shipcosttype.desc_text TO ship_desc_text 


	IF l_rec_shiphead.finalised_flag = 'Y' 
	AND l_rec_shipcosttype.class_ind <> '4' THEN 
		LET l_msgresp = kandoomsg("P",7061,"") 
		#7061 Only "Late" cost types can be editted once a shipment IS fin
		CLOSE WINDOW p231 
		RETURN 
	END IF 

	LET l_old_res_code = l_rec_debitdist.res_code 
	LET l_old_job_code = l_rec_debitdist.job_code 

	INPUT BY NAME l_rec_debitdist.job_code, 
	l_rec_debitdist.res_code, 
	l_rec_debitdist.desc_text, 
	l_rec_debitdist.acct_code, 
	l_rec_debitdist.dist_amt, 
	l_rec_debitdist.analysis_text, 
	l_rec_debitdist.dist_qty 
	WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P61B","inp-debitdist-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		ON KEY (control-b) 
			CASE 
				WHEN infield(job_code) 
					LET l_winds_text = showship(p_cmpy) 
					OPTIONS INSERT KEY f1, 
					DELETE KEY f2 
					IF l_winds_text IS NOT NULL THEN 
						LET l_rec_debitdist.job_code = l_winds_text 
						NEXT FIELD job_code 
					END IF 
				WHEN infield(res_code) 
					CALL show_costtype(p_cmpy) RETURNING l_pr_flag, l_winds_text 
					OPTIONS INSERT KEY f1, 
					DELETE KEY f2 
					IF l_pr_flag THEN 
						LET l_rec_debitdist.res_code = l_winds_text 
						NEXT FIELD res_code 
					END IF 
				WHEN infield(acct_code) 
					LET l_winds_text = show_acct(p_cmpy) 
					OPTIONS INSERT KEY f1, 
					DELETE KEY f2 
					IF l_winds_text IS NOT NULL THEN 
						LET l_rec_debitdist.acct_code = l_winds_text 
						NEXT FIELD acct_code 
					END IF 
			END CASE 

			ON ACTION "NOTES" infield (desc_text)
			--ON KEY (control-n)			
				LET l_rec_debitdist.desc_text = 
				sys_noter(p_cmpy,l_rec_debitdist.desc_text) 
				NEXT FIELD desc_text 

		AFTER FIELD job_code 
			IF l_rec_debitdist.job_code IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD job_code 
			ELSE 
				SELECT * INTO l_rec_shiphead.* FROM shiphead 
				WHERE ship_code = l_rec_debitdist.job_code 
				AND cmpy_code = p_cmpy 
				IF status = NOTFOUND THEN 
					LET l_msgresp = kandoomsg("L",9005,"") 
					#9005 Shipment was NOT found
					NEXT FIELD job_code 
				END IF 
			END IF 

		AFTER FIELD res_code 
			IF fgl_lastkey() = fgl_keyval("left") 
			OR fgl_lastkey() = fgl_keyval("up") THEN 
				NEXT FIELD previous 
			END IF 
			IF l_rec_debitdist.res_code IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD res_code 
			END IF 
			SELECT * INTO l_rec_shipcosttype.* FROM shipcosttype 
			WHERE cost_type_code = l_rec_debitdist.res_code 
			AND cmpy_code = p_cmpy 
			IF status = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("L",9006,"") 
				#9006 Shipment Cost Type NOT found
				NEXT FIELD res_code 
			END IF 
			IF l_rec_shipcosttype.class_ind = '1' THEN 
				IF l_rec_shiphead.vend_code <> glob_rec_debithead.vend_code THEN 
					LET l_msgresp = kandoomsg("P",7060,"") 
					#7060 "Free on Board" cost types can .. vendor codes
					NEXT FIELD res_code 
				END IF 
				IF glob_rec_debithead.conv_qty <> l_rec_shiphead.conversion_qty THEN 
					LET l_msgresp = kandoomsg("P",7062,"") 
					#7062 "Free on Board" cost types can .. exchange rate
					NEXT FIELD res_code 
				END IF 
			END IF 
			IF l_rec_shiphead.finalised_flag <> 'Y' 
			AND l_rec_shipcosttype.class_ind = '4' THEN 
				LET l_msgresp = kandoomsg("P",9185,"") 
				#9185 "Late" cost types can only be used FOR finalised sh
				NEXT FIELD res_code 
			END IF 
			IF l_rec_shiphead.finalised_flag = 'Y' 
			AND l_rec_shipcosttype.class_ind <> '4' THEN 
				LET l_msgresp = kandoomsg("P",9186,"") 
				#9186 Only "Late" cost types can be used FOR finalised sh
				NEXT FIELD res_code 
			END IF 
			DISPLAY l_rec_shipcosttype.desc_text TO ship_desc_text 


			IF l_old_res_code <> l_rec_debitdist.res_code 
			OR l_old_job_code <> l_rec_debitdist.job_code 
			OR l_old_res_code IS NULL 
			OR l_old_job_code IS NULL THEN 
				LET l_old_res_code = l_rec_debitdist.res_code 
				IF l_rec_shipcosttype.class_ind <> '4' THEN 
					SELECT * INTO l_rec_smparms.* FROM smparms 
					WHERE key_num = '1' 
					AND cmpy_code = p_cmpy 
					IF l_rec_shiphead.ship_type_ind = 3 THEN 
						IF l_rec_shipcosttype.ret_acct_code IS NULL THEN 
							LET l_rec_debitdist.acct_code = l_rec_smparms.ret_git_acct_code 
						ELSE 
							LET l_rec_debitdist.acct_code = l_rec_shipcosttype.ret_acct_code 
						END IF 
					ELSE 
						IF l_rec_shipcosttype.acct_code IS NULL THEN 
							LET l_rec_debitdist.acct_code = l_rec_smparms.git_acct_code 
						ELSE 
							LET l_rec_debitdist.acct_code = l_rec_shipcosttype.acct_code 
						END IF 
					END IF 
					DISPLAY BY NAME l_rec_debitdist.acct_code 

				ELSE 
					IF l_rec_shiphead.ship_type_ind = 3 THEN 
						LET l_rec_debitdist.acct_code = l_rec_shipcosttype.ret_acct_code 
					ELSE 
						LET l_rec_debitdist.acct_code = l_rec_shipcosttype.acct_code 
					END IF 
					DISPLAY BY NAME l_rec_debitdist.acct_code 

				END IF 
			END IF 

		BEFORE FIELD desc_text 
			IF l_rec_debitdist.desc_text IS NULL THEN 
				LET l_rec_debitdist.desc_text = l_rec_debitdist.job_code clipped, 
				' ', l_rec_shipcosttype.desc_text 
			END IF 

		BEFORE FIELD acct_code 
			IF fgl_lastkey() = fgl_keyval("left") 
			OR fgl_lastkey() = fgl_keyval("up") THEN 
				NEXT FIELD previous 
			END IF 
			SELECT * INTO l_rec_coa.* FROM coa 
			WHERE acct_code = l_rec_debitdist.acct_code 
			AND cmpy_code = p_cmpy 
			IF l_rec_coa.analy_prompt_text IS NULL THEN 
				LET l_rec_coa.analy_prompt_text = "Analysis" 
			END IF 
			LET l_temp_text = l_rec_coa.analy_prompt_text clipped,"....................." 
			LET l_rec_coa.analy_prompt_text = l_temp_text 
			DISPLAY BY NAME l_rec_coa.analy_prompt_text 
			attribute(white) 
			IF l_rec_shipcosttype.class_ind <> '4' THEN 
				NEXT FIELD dist_amt 
			END IF 

		AFTER FIELD acct_code 
			IF fgl_lastkey() = fgl_keyval("left") 
			OR fgl_lastkey() = fgl_keyval("up") THEN 
				NEXT FIELD previous 
			END IF 
			IF l_rec_debitdist.acct_code IS NULL THEN 
				LET l_msgresp = kandoomsg("W",9232,"") 
				#9232 An account code must be entered
				NEXT FIELD acct_code 
			ELSE 
				SELECT * INTO l_rec_coa.* FROM coa 
				WHERE acct_code = l_rec_debitdist.acct_code 
				AND cmpy_code = p_cmpy 
				IF status = NOTFOUND THEN 
					LET l_msgresp = kandoomsg("W",9234,"") 
					#9234 Account code NOT found - Try window
					NEXT FIELD acct_code 
				ELSE 
					IF NOT acct_type(p_cmpy,l_rec_debitdist.acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"") THEN 
						NEXT FIELD acct_code 
					END IF 
					SELECT unique 1 FROM bank 
					WHERE cmpy_code = p_cmpy 
					AND acct_code = l_rec_debitdist.acct_code 
					IF status = NOTFOUND THEN 
					ELSE 
						LET l_msgresp = kandoomsg("G",9111," ") 
						NEXT FIELD acct_code 
					END IF 
					IF l_rec_coa.analy_prompt_text IS NULL THEN 
						LET l_rec_coa.analy_prompt_text = "Analysis" 
					END IF 
					LET l_temp_text = l_rec_coa.analy_prompt_text clipped,".................." 
					LET l_rec_coa.analy_prompt_text = l_temp_text 
					DISPLAY BY NAME l_rec_coa.analy_prompt_text 
					attribute(white) 
				END IF 
			END IF 

		AFTER FIELD dist_amt 
			IF l_rec_debitdist.dist_amt IS NULL OR 
			l_rec_debitdist.dist_amt <= 0 THEN 
				LET l_msgresp=kandoomsg("I",9085,"") 
				#9085 Must enter a value greater than zero
				NEXT FIELD dist_amt 
			END IF 

		AFTER FIELD analysis_text 
			IF l_rec_debitdist.analysis_text IS NULL 
			AND l_rec_coa.analy_req_flag = 'Y' THEN 
				LET l_msgresp=kandoomsg("P",9016,"") 
				#9016 Analysis IS required
				NEXT FIELD analysis_text 
			END IF 

		AFTER FIELD dist_qty 
			IF l_rec_coa.uom_code IS NULL 
			AND l_rec_debitdist.dist_qty IS NOT NULL 
			AND l_rec_debitdist.dist_qty <> 0 THEN 
				LET l_msgresp=kandoomsg("P",9184,"") 
				#9184 Quantities are NOT collected FOR this Account Code
				LET l_rec_debitdist.dist_qty = NULL 
				NEXT FIELD dist_qty 
			END IF 
			IF l_rec_coa.uom_code IS NOT NULL 
			AND l_rec_debitdist.dist_qty IS NULL THEN 
				LET l_rec_debitdist.dist_qty = 0 
			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			ELSE 
				IF l_rec_debitdist.job_code IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD job_code 
				ELSE 
					SELECT * INTO l_rec_shiphead.* FROM shiphead 
					WHERE ship_code = l_rec_debitdist.job_code 
					AND cmpy_code = p_cmpy 
					IF status = NOTFOUND THEN 
						LET l_msgresp = kandoomsg("L",9005,"") 
						#9005 Shipment was NOT found
						NEXT FIELD job_code 
					END IF 
				END IF 
				IF l_rec_debitdist.res_code IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD res_code 
				ELSE 
					SELECT * INTO l_rec_shipcosttype.* FROM shipcosttype 
					WHERE cost_type_code = l_rec_debitdist.res_code 
					AND cmpy_code = p_cmpy 
					IF status = NOTFOUND THEN 
						LET l_msgresp = kandoomsg("L",9006,"") 
						#9006 Shipment Cost Type NOT found
						NEXT FIELD res_code 
					END IF 
					IF l_rec_shipcosttype.class_ind = '1' THEN 
						IF l_rec_shiphead.vend_code <> glob_rec_debithead.vend_code THEN 
							LET l_msgresp = kandoomsg("P",7060,"") 
							#7060 "Free on Board" cost types can .. vendor code
							NEXT FIELD res_code 
						END IF 
						IF glob_rec_debithead.conv_qty <> l_rec_shiphead.conversion_qty THEN 
							LET l_msgresp = kandoomsg("P",7062,"") 
							#7062 "Free on Board" cost types can .. exchange
							NEXT FIELD res_code 
						END IF 
					END IF 
					IF l_rec_shiphead.finalised_flag <> 'Y' 
					AND l_rec_shipcosttype.class_ind = '4' THEN 
						LET l_msgresp = kandoomsg("P",9185,"") 
						#9185 "Late" cost types can only be used FOR finalised
						NEXT FIELD res_code 
					END IF 
					IF l_rec_shiphead.finalised_flag = 'Y' 
					AND l_rec_shipcosttype.class_ind <> '4' THEN 
						LET l_msgresp = kandoomsg("P",9186,"") 
						#9186 Only "Late" cost types can be used FOR finalised
						NEXT FIELD res_code 
					END IF 
					DISPLAY l_rec_shipcosttype.desc_text TO ship_desc_text 

				END IF 
				IF l_rec_shipcosttype.class_ind = '4' THEN 
					IF l_rec_debitdist.acct_code IS NULL THEN 
						LET l_msgresp = kandoomsg("W",9232,"") 
						#9232 An account code must be entered
						NEXT FIELD acct_code 
					END IF 
					IF NOT acct_type(p_cmpy,l_rec_debitdist.acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"") THEN 
						NEXT FIELD acct_code 
					END IF 
				END IF 
				IF l_rec_debitdist.dist_amt IS NULL OR 
				l_rec_debitdist.dist_amt <= 0 THEN 
					LET l_msgresp=kandoomsg("I",9085,"") 
					#9085 Must enter a value greater than zero
					NEXT FIELD dist_amt 
				END IF 
				IF l_rec_debitdist.analysis_text IS NULL 
				AND l_rec_coa.analy_req_flag = "Y" THEN 
					LET l_msgresp=kandoomsg("P",9016,"") 
					#9016 " Analysis IS required "
					NEXT FIELD analysis_text 
				END IF 
				IF l_rec_coa.uom_code IS NOT NULL 
				AND l_rec_debitdist.dist_qty IS NULL THEN 
					LET l_rec_debitdist.dist_qty = 0 
				END IF 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		CLOSE WINDOW p231 
		RETURN 
	END IF 
	LET l_rec_debitdist.type_ind = "S" 
	IF l_rec_debitdist.dist_qty IS NULL THEN 
		LET l_rec_debitdist.dist_qty = 0 
	END IF 

	LET l_rec_debitdist.po_num = '' 
	LET l_rec_debitdist.po_line_num = '' 
	LET l_rec_debitdist.trans_qty = 0 
	LET l_rec_debitdist.charge_amt = 0 

	UPDATE t_debitdist 
	SET job_code = l_rec_debitdist.job_code, 
	dist_qty = l_rec_debitdist.dist_qty, 
	dist_amt = l_rec_debitdist.dist_amt, 
	analysis_text = l_rec_debitdist.analysis_text, 
	po_num = l_rec_debitdist.po_num, 
	po_line_num = l_rec_debitdist.po_line_num, 
	type_ind = l_rec_debitdist.type_ind , 
	desc_text = l_rec_debitdist.desc_text, 
	trans_qty = l_rec_debitdist.trans_qty, 
	charge_amt = l_rec_debitdist.charge_amt, 
	res_code = l_rec_debitdist.res_code, 
	acct_code = l_rec_debitdist.acct_code 
	WHERE line_num = p_line_num 

	IF sqlca.sqlerrd[3] = 0 THEN 
		SELECT max(line_num) INTO l_rec_debitdist.line_num 
		FROM t_debitdist 
		IF l_rec_debitdist.line_num IS NULL THEN 
			LET l_rec_debitdist.line_num = 1 
		ELSE 
			LET l_rec_debitdist.line_num = l_rec_debitdist.line_num + 1 
		END IF 
		LET l_rec_debitdist.debit_code = glob_rec_debithead.debit_num 
		INSERT INTO t_debitdist VALUES (l_rec_debitdist.*) 
	END IF 

	CLOSE WINDOW p231 

END FUNCTION 



############################################################
# FUNCTION cr_wo_dist(p_cmpy,p_kandoouser_sign_on_code,p_line_num)
#
#
############################################################
FUNCTION cr_wo_dist(p_cmpy,p_kandoouser_sign_on_code,p_line_num) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE p_line_num SMALLINT 
	DEFINE l_rec_ordhead RECORD LIKE ordhead.* 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_rec_addcharge RECORD LIKE addcharge.* 
	DEFINE l_rec_debitdist RECORD LIKE debitdist.* 
	DEFINE l_name_text LIKE customer.name_text 
	DEFINE l_mask_code LIKE warehouse.acct_mask_code 
	DEFINE l_cost_amt DECIMAL(16,2) 
	DEFINE l_temp_text CHAR(60) 
	DEFINE l_winds_text CHAR(80) 
	DEFINE l_filter_text CHAR(80) 
	DEFINE l_outstdg_amt LIKE orderline.ext_price_amt 
	DEFINE l_status_ind LIKE orderline.status_ind 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_cost_amt = NULL 
	INITIALIZE l_rec_ordhead.* TO NULL 
	INITIALIZE l_rec_debitdist.* TO NULL 
	INITIALIZE l_name_text TO NULL 
	INITIALIZE l_rec_coa.* TO NULL 

	SELECT * INTO l_rec_debitdist.* FROM t_debitdist 
	WHERE line_num = p_line_num 
	IF status != NOTFOUND THEN 
		LET l_cost_amt = l_rec_debitdist.dist_amt 
		SELECT * INTO l_rec_coa.* FROM coa 
		WHERE acct_code = l_rec_debitdist.acct_code 
		AND cmpy_code = p_cmpy 
		SELECT * INTO l_rec_ordhead.* FROM ordhead 
		WHERE order_num = l_rec_debitdist.po_num 
		AND cmpy_code = p_cmpy 
		IF status = 0 THEN 
			SELECT name_text INTO l_name_text 
			FROM customer 
			WHERE cust_code = l_rec_ordhead.cust_code 
			AND cmpy_code = p_cmpy 
		END IF 
		# This next step IS an interim measure as we are changing what IS
		# stored in the desbitdist.desc_text FROM customer.name_text TO
		# addcharge.desc_code WR0326
		IF (l_rec_debitdist.desc_text = l_name_text 
		OR l_rec_debitdist.desc_text = l_rec_coa.desc_text) 
		AND l_rec_debitdist.desc_text IS NOT NULL THEN 
			LET l_rec_debitdist.desc_text = NULL 
		END IF 
	END IF 

	IF l_rec_coa.analy_prompt_text IS NULL THEN 
		LET l_rec_coa.analy_prompt_text = "Analysis" 
	END IF 

	LET l_rec_addcharge.desc_code = l_rec_debitdist.desc_text 
	LET l_temp_text = l_rec_coa.analy_prompt_text clipped,".................." 
	LET l_rec_coa.analy_prompt_text = l_temp_text 
	IF l_cost_amt IS NULL THEN 
		LET l_cost_amt = 0 
	END IF 

	OPEN WINDOW p506 with FORM "P506" 
	CALL windecoration_p("P506") 

	LET l_msgresp = kandoomsg("P",1070,"") 
	#1070 Enter Distribution Details - ESC TO Continue
	DISPLAY glob_rec_debithead.vend_code, 
	glob_rec_vendor.name_text, 
	glob_rec_debithead.debit_num, 
	glob_rec_debithead.total_amt, 
	glob_rec_debithead.dist_amt 
	TO voucher.vend_code, 
	glob_rec_vendor.name_text, 
	voucher.vouch_code, 
	voucher.total_amt, 
	voucher.dist_amt 

	DISPLAY BY NAME l_rec_coa.analy_prompt_text 
	attribute(white) 
	DISPLAY l_rec_ordhead.cust_code, 
	l_name_text, 
	l_rec_ordhead.ship_addr1_text, 
	l_rec_ordhead.ship_addr2_text, 
	l_rec_ordhead.ship_city_text, 
	l_rec_ordhead.ord_text, 
	l_rec_ordhead.order_num, 
	l_rec_addcharge.desc_code, 
	l_rec_debitdist.allocation_ind, 
	l_rec_debitdist.acct_code, 
	l_rec_coa.desc_text , 
	l_rec_debitdist.dist_amt, 
	l_rec_debitdist.analysis_text, 
	l_rec_debitdist.dist_qty, 
	l_rec_coa.uom_code 
	TO ordhead.cust_code, 
	customer.name_text, 
	ordhead.ship_addr1_text, 
	ordhead.ship_addr2_text, 
	ordhead.ship_city_text, 
	ordhead.ord_text, 
	ordhead.order_num, 
	addcharge.desc_code, 
	complete_flag, 
	voucherdist.acct_code, 
	coa.desc_text , 
	voucherdist.dist_amt, 
	voucherdist.analysis_text, 
	voucherdist.dist_qty, 
	coa.uom_code 

	INPUT l_rec_ordhead.order_num, 
	l_rec_addcharge.desc_code, 
	l_rec_debitdist.allocation_ind, 
	l_rec_debitdist.acct_code, 
	l_rec_debitdist.dist_amt, 
	l_rec_debitdist.analysis_text, 
	l_rec_debitdist.dist_qty 
	WITHOUT DEFAULTS 
	FROM ordhead.order_num, 
	addcharge.desc_code, 
	complete_flag, 
	voucherdist.acct_code, 
	voucherdist.dist_amt, 
	voucherdist.analysis_text, 
	voucherdist.dist_qty 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P61B","inp-debitdist-2") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON KEY (control-b) 
			CASE 
				WHEN infield(order_num) 
					LET l_filter_text = "ordhead.ord_ind in ('8','9') " 
					LET l_winds_text = show_mborders(p_cmpy,l_filter_text) 
					OPTIONS INSERT KEY f1, 
					DELETE KEY f2 
					IF l_winds_text IS NOT NULL THEN 
						LET l_rec_ordhead.order_num = l_winds_text 
						NEXT FIELD order_num 
					END IF 
				WHEN infield(acct_code) 
					LET l_winds_text = show_acct(p_cmpy) 
					OPTIONS INSERT KEY f1, 
					DELETE KEY f2 
					IF l_winds_text IS NOT NULL THEN 
						LET l_rec_debitdist.acct_code = l_winds_text 
						NEXT FIELD acct_code 
					END IF 
				WHEN infield(desc_code) 
					LET l_winds_text = show_addcharge(p_cmpy,"0") 
					OPTIONS INSERT KEY f1, 
					DELETE KEY f2 
					IF l_winds_text IS NOT NULL THEN 
						LET l_rec_addcharge.desc_code = l_winds_text 
						#DISPLAY l_rec_addcharge.desc_code
						#TO addcharge.desc_code
						NEXT FIELD addcharge.desc_code 
					END IF 
			END CASE 

		AFTER FIELD order_num 
			IF l_rec_ordhead.order_num IS NULL THEN 
				LET l_msgresp = kandoomsg("W",9264,"") 
				#9264 Order Number must be entered
				NEXT FIELD order_num 
			ELSE 
				SELECT * INTO l_rec_ordhead.* FROM ordhead 
				WHERE order_num = l_rec_ordhead.order_num 
				AND ord_ind in ("8","9") 
				AND cmpy_code = p_cmpy 
				IF status = NOTFOUND THEN 
					LET l_msgresp = kandoomsg("W",9333,"") 
					#9333 No deliveries exist FOR this customer/ Order combination
					NEXT FIELD order_num 
				END IF 
				SELECT name_text INTO l_name_text FROM customer 
				WHERE cust_code = l_rec_ordhead.cust_code 
				AND cmpy_code = p_cmpy 
				DISPLAY l_rec_ordhead.cust_code, 
				l_name_text, 
				l_rec_ordhead.ship_addr1_text, 
				l_rec_ordhead.ship_addr2_text, 
				l_rec_ordhead.ship_city_text, 
				l_rec_ordhead.ord_text 
				TO ordhead.cust_code, 
				customer.name_text, 
				ordhead.ship_addr1_text, 
				ordhead.ship_addr2_text, 
				ordhead.ship_city_text, 
				ordhead.ord_text 

			END IF 

		AFTER FIELD acct_code 
			IF fgl_lastkey() = fgl_keyval("left") 
			OR fgl_lastkey() = fgl_keyval("up") THEN 
				NEXT FIELD previous 
			END IF 
			IF l_rec_debitdist.acct_code IS NULL THEN 
				LET l_msgresp = kandoomsg("W",9232,"") 
				#9232 An account code must be entered
				NEXT FIELD acct_code 
			ELSE 
				CALL verify_acct_code(p_cmpy,l_rec_debitdist.acct_code, 
				glob_rec_debithead.year_num, 
				glob_rec_debithead.period_num) 
				RETURNING l_rec_coa.* 
				IF l_rec_coa.acct_code IS NULL THEN 
					NEXT FIELD acct_code 
				END IF 
				IF l_rec_debitdist.acct_code != l_rec_coa.acct_code THEN 
					LET l_rec_debitdist.acct_code = l_rec_coa.acct_code 
					NEXT FIELD acct_code 
				END IF 
				IF NOT acct_type(p_cmpy,l_rec_coa.acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
					NEXT FIELD acct_code 
				END IF 
				IF l_rec_coa.analy_prompt_text IS NULL THEN 
					LET l_rec_coa.analy_prompt_text = "Analysis" 
				END IF 
				LET l_temp_text = l_rec_coa.analy_prompt_text clipped,".................." 
				LET l_rec_coa.analy_prompt_text = l_temp_text 
				DISPLAY BY NAME l_rec_coa.analy_prompt_text 
				attribute(white) 
				DISPLAY BY NAME l_rec_coa.uom_code, 
				l_rec_coa.desc_text 

			END IF 

		AFTER FIELD desc_code 
			IF fgl_lastkey() = fgl_keyval("left") 
			OR fgl_lastkey() = fgl_keyval("up") THEN 
				NEXT FIELD previous 
			END IF 
			IF l_rec_addcharge.desc_code IS NOT NULL THEN 
				SELECT * INTO l_rec_addcharge.* 
				FROM addcharge 
				WHERE desc_code = l_rec_addcharge.desc_code 
				AND cmpy_code = p_cmpy 
				IF status = NOTFOUND THEN 
					LET l_msgresp = kandoomsg("W",9263,"") 
					#9263 Additional charge does NOT exist;  Try Window.
					NEXT FIELD desc_code 
				END IF 
				IF l_rec_addcharge.process_ind = 1 THEN 
					LET l_msgresp = kandoomsg("W",9955,"") 
					#9955 Cannot enter additional charge that IS automatically
					#     calculated.
					NEXT FIELD desc_code 
				END IF 
				DECLARE o_curs CURSOR FOR 
				SELECT line_num, ext_price_amt - ext_cost_amt, status_ind 
				INTO l_rec_debitdist.po_line_num,l_outstdg_amt, l_status_ind 
				FROM orderline 
				WHERE order_num = l_rec_ordhead.order_num 
				AND part_code IS NULL 
				AND desc_text = l_rec_addcharge.desc_code 
				OPEN o_curs 
				FETCH o_curs 
				IF status = NOTFOUND 
				OR l_outstdg_amt IS NULL THEN 
					LET l_outstdg_amt = 0 
				END IF 
				CLOSE o_curs 
				IF (l_outstdg_amt <= 0 
				OR l_status_ind = "C" 
				OR l_status_ind IS null) 
				AND (l_rec_debitdist.allocation_ind != "N" 
				OR l_rec_debitdist.allocation_ind IS null) THEN 
					LET l_rec_debitdist.allocation_ind = "Y" 
				ELSE 
					LET l_rec_debitdist.allocation_ind = "N" 
				END IF 
				DISPLAY l_rec_debitdist.allocation_ind 
				TO complete_flag 

				IF l_rec_debitdist.acct_code IS NULL THEN 
					SELECT acct_mask_code INTO l_mask_code 
					FROM warehouse 
					WHERE ware_code = l_rec_ordhead.ware_code 
					AND cmpy_code = p_cmpy 
					LET l_rec_addcharge.sl_exp_code = build_mask(p_cmpy, l_mask_code, 
					l_rec_addcharge.sl_exp_code) 
					LET l_rec_debitdist.acct_code = l_rec_addcharge.sl_exp_code 
					DISPLAY BY NAME l_rec_debitdist.acct_code 

				END IF 
			END IF 

		BEFORE FIELD complete_flag 
			IF l_rec_addcharge.desc_code IS NULL THEN 
				IF fgl_lastkey() = fgl_keyval("left") 
				OR fgl_lastkey() = fgl_keyval("up") THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 

		AFTER FIELD complete_flag 
			IF l_rec_debitdist.allocation_ind IS NULL 
			OR (l_rec_debitdist.allocation_ind != "Y" 
			AND l_rec_debitdist.allocation_ind != "N") THEN 
				LET l_msgresp = kandoomsg("G",9209,"") 
				#9209 Must be Y OR N
				NEXT FIELD complete_flag 
			END IF 

		AFTER FIELD analysis_text 
			IF l_rec_debitdist.analysis_text IS NULL 
			AND l_rec_coa.analy_req_flag = "Y" THEN 
				LET l_msgresp=kandoomsg("P",9016,"") 
				#9016 " Analysis IS required "
				NEXT FIELD analysis_text 
			END IF 

		AFTER FIELD dist_amt 
			IF l_rec_debitdist.dist_amt IS NULL 
			OR l_rec_debitdist.dist_amt <= 0 THEN 
				LET l_msgresp=kandoomsg("P",9019,"") 
				#9019 Payment amount must NOT be less than zero"
				NEXT FIELD voucherdist.dist_amt 
			END IF 

		AFTER FIELD dist_qty 
			IF l_rec_coa.uom_code IS NOT NULL 
			AND l_rec_debitdist.dist_qty IS NULL THEN 
				LET l_rec_debitdist.dist_qty = 0 
			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			ELSE 
				IF l_rec_ordhead.order_num IS NULL THEN 
					LET l_msgresp = kandoomsg("W",9264,"") 
					#9264 Order Number must be entered
					NEXT FIELD order_num 
				END IF 
				SELECT * INTO l_rec_ordhead.* FROM ordhead 
				WHERE order_num = l_rec_ordhead.order_num 
				AND ord_ind in ("8","9") 
				AND cmpy_code = p_cmpy 
				IF status = NOTFOUND THEN 
					LET l_msgresp = kandoomsg("W",9333,"") 
					#9333 No deliveries exist FOR this customer/ Order combination
					NEXT FIELD order_num 
				END IF 
				IF l_rec_debitdist.acct_code IS NULL THEN 
					LET l_msgresp = kandoomsg("W",9232,"") 
					#9232 An account code must be entered
					NEXT FIELD acct_code 
				END IF 
				CALL verify_acct_code(p_cmpy,l_rec_debitdist.acct_code, 
				glob_rec_debithead.year_num, 
				glob_rec_debithead.period_num) 
				RETURNING l_rec_coa.* 
				IF l_rec_coa.acct_code IS NULL THEN 
					NEXT FIELD acct_code 
				END IF 
				IF l_rec_debitdist.acct_code != l_rec_coa.acct_code THEN 
					LET l_rec_debitdist.acct_code = l_rec_coa.acct_code 
					NEXT FIELD acct_code 
				END IF 
				IF l_rec_addcharge.desc_code IS NOT NULL THEN 
					SELECT * INTO l_rec_addcharge.* 
					FROM addcharge 
					WHERE desc_code = l_rec_addcharge.desc_code 
					AND cmpy_code = p_cmpy 
					IF status = NOTFOUND THEN 
						LET l_msgresp = kandoomsg("W",9263,"") 
						#9263 Additional charge does NOT exist;  Try Window.
						NEXT FIELD addcharge.desc_code 
					END IF 
				END IF 
				IF l_rec_debitdist.dist_amt IS NULL 
				OR l_rec_debitdist.dist_amt <= 0 THEN 
					LET l_msgresp=kandoomsg("P",9019,"") 
					#9019 Payment amount must NOT be less than zero"
					NEXT FIELD voucherdist.dist_amt 
				END IF 
				IF l_rec_debitdist.analysis_text IS NULL 
				AND l_rec_coa.analy_req_flag = "Y" THEN 
					LET l_msgresp=kandoomsg("P",9016,"") 
					#9016 " Analysis IS required "
					NEXT FIELD analysis_text 
				END IF 
				IF l_rec_coa.uom_code IS NOT NULL 
				AND l_rec_debitdist.dist_qty IS NULL THEN 
					LET l_rec_debitdist.dist_qty = 0 
				END IF 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		CLOSE WINDOW p506 
		RETURN 
	END IF 

	LET l_rec_debitdist.type_ind = "W" 
	LET l_rec_debitdist.desc_text = l_rec_addcharge.desc_code 
	IF l_rec_debitdist.dist_qty IS NULL THEN 
		LET l_rec_debitdist.dist_qty = 0 
	END IF 

	LET l_rec_debitdist.po_num = l_rec_ordhead.order_num 
	LET l_rec_debitdist.res_code = l_rec_ordhead.cust_code 
	LET l_rec_debitdist.po_line_num = '' 
	LET l_rec_debitdist.trans_qty = 0 
	LET l_rec_debitdist.charge_amt = 0 

	UPDATE t_debitdist 
	SET dist_qty = l_rec_debitdist.dist_qty, 
	dist_amt = l_rec_debitdist.dist_amt, 
	analysis_text = l_rec_debitdist.analysis_text, 
	po_num = l_rec_ordhead.order_num, 
	type_ind = "W", 
	desc_text = l_rec_addcharge.desc_code, 
	trans_qty = 0, 
	charge_amt = 0, 
	res_code = l_rec_ordhead.cust_code, 
	acct_code = l_rec_debitdist.acct_code, 
	allocation_ind = l_rec_debitdist.allocation_ind 
	WHERE line_num = pr_line_num 

	IF sqlca.sqlerrd[3] = 0 THEN 
		SELECT max(line_num) INTO l_rec_debitdist.line_num 
		FROM t_debitdist 
		IF l_rec_debitdist.line_num IS NULL THEN 
			LET l_rec_debitdist.line_num = 1 
		ELSE 
			LET l_rec_debitdist.line_num = l_rec_debitdist.line_num + 1 
		END IF 
		LET l_rec_debitdist.debit_code = glob_rec_debithead.debit_num 
		LET l_rec_debitdist.type_ind = "W" 
		LET l_rec_debitdist.desc_text = l_rec_addcharge.desc_code 
		LET l_rec_debitdist.res_code = l_rec_ordhead.cust_code 
		IF l_rec_debitdist.dist_qty IS NULL THEN 
			LET l_rec_debitdist.dist_qty = 0 
		END IF 
		LET l_rec_debitdist.po_num = l_rec_ordhead.order_num 
		LET l_rec_debitdist.trans_qty = 0 
		LET l_rec_debitdist.charge_amt = 0 
		INSERT INTO t_debitdist VALUES (l_rec_debitdist.*) 
	END IF 

	CLOSE WINDOW p506 
END FUNCTION 




############################################################
# FUNCTION dist_jm_line(p_cmpy,p_rowid)
#
#
############################################################
FUNCTION dist_jm_line(p_cmpy,p_rowid) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_rowid INTEGER 
	DEFINE l_rec_debitdist RECORD LIKE debitdist.* 
	DEFINE l_rec_jmresource RECORD LIKE jmresource.* 
	DEFINE l_rec_job RECORD LIKE job.* 
	DEFINE l_rec_jobvars RECORD LIKE jobvars.* 
	DEFINE l_rec_activity RECORD LIKE activity.* 
	DEFINE l_rec_jobledger RECORD LIKE jobledger.* 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_save_amt LIKE debitdist.dist_amt 
	DEFINE l_temp1_text CHAR(8) 
	DEFINE l_temp2_text CHAR(8) 
	DEFINE l_msgresp LIKE language.yes_flag 

	IF p_rowid > 0 THEN 
		SELECT * INTO l_rec_debitdist.* 
		FROM t_jmdist 
		WHERE rowid = p_rowid 
		SELECT jmresource.* 
		INTO l_rec_jmresource.* 
		FROM jmresource 
		WHERE cmpy_code = p_cmpy 
		AND res_code = l_rec_debitdist.res_code 
		SELECT job.* 
		INTO l_rec_job.* 
		FROM job 
		WHERE cmpy_code = p_cmpy 
		AND job_code = l_rec_debitdist.job_code 
		SELECT jobvars.* 
		INTO l_rec_jobvars.* 
		FROM jobvars 
		WHERE cmpy_code = p_cmpy 
		AND job_code = l_rec_debitdist.job_code 
		AND var_code = l_rec_debitdist.var_code 
		SELECT activity.* 
		INTO l_rec_activity.* 
		FROM activity 
		WHERE cmpy_code = p_cmpy 
		AND job_code = l_rec_debitdist.job_code 
		AND var_code = l_rec_debitdist.var_code 
		AND activity_code = l_rec_debitdist.act_code 
	ELSE 
		LET l_rec_debitdist.var_code = NULL 
		LET l_rec_debitdist.cost_amt = 0 
		LET l_rec_debitdist.charge_amt = 0 
		LET l_rec_debitdist.trans_qty = 0 
	END IF 
	OPEN WINDOW j148 with FORM "J148" 
	CALL winDecoration_j("J148") 

	#1039 Enter Job Management Line - ESC TO Continue
	LET l_msgresp=kandoomsg("P",1039,"") 
	LET l_temp1_text = NULL 
	INPUT BY NAME glob_rec_vendor.vend_code, 
	glob_rec_vendor.name_text, 
	l_rec_debitdist.res_code, 
	l_rec_debitdist.acct_code, 
	l_rec_debitdist.job_code, 
	l_rec_debitdist.var_code, 
	l_rec_debitdist.act_code, 
	l_rec_debitdist.desc_text, 
	l_rec_debitdist.trans_qty, 
	l_rec_debitdist.allocation_ind, 
	l_rec_debitdist.cost_amt, 
	l_rec_debitdist.dist_amt, 
	l_rec_debitdist.charge_amt WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P61B","inp-debitdist-3") 

			LET l_rec_jobledger.charge_amt = l_rec_debitdist.trans_qty 
			* l_rec_debitdist.charge_amt 
			DISPLAY l_rec_jmresource.desc_text, 
			l_rec_job.title_text, 
			l_rec_jobvars.title_text, 
			l_rec_activity.title_text, 
			l_rec_jmresource.unit_code, 
			l_rec_jobledger.charge_amt, 
			glob_rec_debithead.total_amt, 
			glob_rec_debithead.dist_amt 
			TO jmresource.desc_text, 
			job.title_text, 
			jobvars.title_text, 
			activity.title_text, 
			jmresource.unit_code, 
			jobledger.charge_amt, 
			voucher.total_amt, 
			voucher.dist_amt 

			DISPLAY glob_rec_debithead.currency_code, 
			glob_rec_debithead.currency_code, 
			glob_rec_debithead.currency_code, 
			glob_base_currency 
			TO sr_currency[1].*, 
			sr_currency[2].*, 
			sr_currency[3].*, 
			glparms.base_currency_code 
			attribute(green) 



		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON KEY (control-b) 
			CASE 
				WHEN infield(res_code) 
					LET l_temp1_text = NULL 
					LET l_temp1_text = show_res(p_cmpy) 
					OPTIONS INSERT KEY f1, 
					DELETE KEY f2 
					IF l_temp1_text IS NOT NULL THEN 
						LET l_rec_debitdist.res_code = l_temp1_text 
					END IF 
					NEXT FIELD res_code 
				WHEN infield(job_code) 
					LET l_temp1_text = show_job(p_cmpy) 
					OPTIONS INSERT KEY f1, 
					DELETE KEY f2 
					IF l_temp1_text IS NOT NULL THEN 
						LET l_rec_debitdist.job_code = l_temp1_text 
					END IF 
					NEXT FIELD job_code 
				WHEN infield(var_code) 
					LET l_temp1_text = show_jobvars(p_cmpy,l_rec_debitdist.job_code) 
					OPTIONS INSERT KEY f1, 
					DELETE KEY f2 
					IF l_temp1_text IS NOT NULL THEN 
						LET l_rec_debitdist.var_code = l_temp1_text 
					END IF 
					NEXT FIELD var_code 
				WHEN infield(act_code) 
					LET l_temp1_text = show_activity(p_cmpy,l_rec_debitdist.job_code, 
					l_rec_debitdist.var_code) 
					OPTIONS INSERT KEY f1, 
					DELETE KEY f2 
					IF l_temp1_text IS NOT NULL THEN 
						LET l_rec_debitdist.act_code = l_temp1_text 
					END IF 
					NEXT FIELD act_code 
			END CASE 

			ON ACTION "NOTES" infield (desc_text) --ON KEY (control-n) 
				LET l_rec_debitdist.desc_text = 
				sys_noter(p_cmpy,l_rec_debitdist.desc_text) 
				NEXT FIELD desc_text 

		ON KEY (F8) 
			IF l_rec_jmresource.res_code IS NOT NULL AND 
			l_rec_jmresource.allocation_flag <> "1" THEN 
				LET l_msgresp = kandoomsg("J",9555,"") 
			ELSE 
				CALL adjust_allocflag(p_cmpy, l_rec_jmresource.res_code, 
				l_rec_debitdist.allocation_ind) 
				RETURNING l_rec_debitdist.allocation_ind 
			END IF 

		BEFORE FIELD res_code 
			IF l_temp1_text IS NULL THEN 
				LET l_temp2_text = l_rec_debitdist.res_code 
			END IF 

		AFTER FIELD res_code 
			IF l_rec_debitdist.res_code IS NULL THEN 
				LET l_msgresp=kandoomsg("P",9034,"") 
				#P9034 " Resource code must be entered
				NEXT FIELD res_code 
			ELSE 
				SELECT * INTO l_rec_jmresource.* 
				FROM jmresource 
				WHERE cmpy_code = p_cmpy 
				AND res_code = l_rec_debitdist.res_code 
				IF status = NOTFOUND THEN 
					LET l_msgresp=kandoomsg("P",9029,"") 
					#P9029 " Resource code does NOT exist - Try Window"
					NEXT FIELD res_code 
				ELSE 
					DISPLAY l_rec_jmresource.desc_text TO jmresource.desc_text 

					LET l_rec_debitdist.allocation_ind = l_rec_jmresource.allocation_ind 
					IF l_rec_debitdist.allocation_ind IS NULL THEN 
						LET l_rec_debitdist.allocation_ind = "A" 
					END IF 
					DISPLAY BY NAME l_rec_debitdist.allocation_ind 

					IF l_temp2_text IS NULL 
					OR l_temp2_text != l_rec_debitdist.res_code THEN 
						IF l_rec_jmresource.unit_cost_amt IS NULL THEN 
							LET l_rec_jmresource.unit_cost_amt = 1 
						END IF 
						IF l_rec_jmresource.unit_bill_amt IS NULL THEN 
							LET l_rec_jmresource.unit_bill_amt = 1 
						END IF 
						LET l_rec_debitdist.desc_text = l_rec_jmresource.desc_text 
						LET l_rec_debitdist.acct_code = l_rec_jmresource.exp_acct_code 
						IF glob_rec_debithead.conv_qty != 1 
						AND glob_rec_debithead.conv_qty != 0 THEN 
							LET l_rec_debitdist.cost_amt = l_rec_jmresource.unit_cost_amt * 
							glob_rec_debithead.conv_qty 
						ELSE 
							LET l_rec_debitdist.cost_amt = l_rec_jmresource.unit_cost_amt 
						END IF 
						LET l_rec_debitdist.charge_amt = l_rec_jmresource.unit_bill_amt 
						DISPLAY BY NAME l_rec_debitdist.desc_text, 
						l_rec_debitdist.acct_code, 
						l_rec_jmresource.unit_code, 
						l_rec_debitdist.cost_amt, 
						l_rec_debitdist.charge_amt 

						LET l_rec_debitdist.dist_amt = l_rec_debitdist.trans_qty 
						* l_rec_debitdist.cost_amt 
						LET l_rec_jobledger.charge_amt = l_rec_debitdist.trans_qty 
						* l_rec_debitdist.charge_amt 
						DISPLAY l_rec_debitdist.dist_amt, 
						l_rec_jobledger.charge_amt 
						TO voucherdist.dist_amt, 
						jobledger.charge_amt 

					END IF 
				END IF 
			END IF 

		BEFORE FIELD job_code 
			LET l_temp2_text = l_rec_debitdist.job_code 

		BEFORE FIELD var_code 
			IF l_rec_debitdist.job_code IS NULL THEN 
				LET l_msgresp=kandoomsg("P",9035,"") 
				#P9035 " Job code must be entered
				NEXT FIELD job_code 
			ELSE 
				SELECT * INTO l_rec_job.* 
				FROM job 
				WHERE cmpy_code = p_cmpy 
				AND job_code = l_rec_debitdist.job_code 
				IF status = NOTFOUND THEN 
					LET l_msgresp=kandoomsg("P",9030,"") 
					#P9030 " Job NOT found - try window"
					NEXT FIELD job_code 
				ELSE 
					DISPLAY l_rec_job.title_text TO job.title_text 

					LET l_rec_debitdist.acct_code = 
					build_mask(p_cmpy,l_rec_debitdist.acct_code, 
					l_rec_job.wip_acct_code) 
					DISPLAY BY NAME l_rec_debitdist.acct_code 

					IF l_temp2_text != l_rec_debitdist.job_code 
					OR l_temp2_text IS NULL THEN 
						CALL verify_acct_code(p_cmpy,l_rec_debitdist.acct_code, 
						glob_rec_debithead.year_num, 
						glob_rec_debithead.period_num) 
						RETURNING l_rec_coa.* 
						IF l_rec_coa.acct_code IS NULL THEN 
							NEXT FIELD job_code 
						ELSE 
							LET l_rec_debitdist.acct_code = l_rec_coa.acct_code 
						END IF 
					END IF 
				END IF 
			END IF 

		AFTER FIELD var_code 
			CLEAR jobvars.title_text 
			IF l_rec_debitdist.var_code IS NULL THEN 
				LET l_rec_debitdist.var_code = 0 
			END IF 
			IF l_rec_debitdist.var_code > 0 THEN 
				SELECT title_text INTO l_rec_jobvars.title_text 
				FROM jobvars 
				WHERE cmpy_code = p_cmpy 
				AND job_code = l_rec_debitdist.job_code 
				AND var_code = l_rec_debitdist.var_code 
				IF status = NOTFOUND THEN 
					LET l_msgresp=kandoomsg("P",9032,"") 
					#P9032 "Invalid Variation Code"
					LET l_rec_debitdist.var_code = NULL 
					CLEAR var_code 
					NEXT FIELD job_code 
				ELSE 
					DISPLAY l_rec_jobvars.title_text TO jobvars.title_text 

				END IF 
			END IF 

		BEFORE FIELD desc_text 
			IF l_rec_debitdist.act_code IS NULL THEN 
				LET l_msgresp=kandoomsg("P",9036,"") 
				#P9035 Activity Code must be entered"
				NEXT FIELD act_code 
			ELSE 
				SELECT * INTO l_rec_activity.* 
				FROM activity 
				WHERE cmpy_code = p_cmpy 
				AND job_code = l_rec_debitdist.job_code 
				AND var_code = l_rec_debitdist.var_code 
				AND activity_code = l_rec_debitdist.act_code 
				CASE 
					WHEN status = NOTFOUND 
						LET l_msgresp=kandoomsg("P",9031,"") 
						#P9031 Activity Code NOT found - try window
						NEXT FIELD job_code 
					WHEN l_rec_activity.finish_flag = "Y" 
						LET l_msgresp=kandoomsg("P",9033,"") 
						#P9033 Activity IS complete no transaction entry
						LET l_rec_debitdist.act_code = NULL 
						NEXT FIELD job_code 
					WHEN l_rec_activity.acct_code IS NULL 
						LET l_msgresp=kandoomsg("P",9037,"") 
						#P9037 Invalid activity FOR transaction entry
						NEXT FIELD job_code 
				END CASE 
				DISPLAY l_rec_activity.title_text TO activity.title_text 

			END IF 

		BEFORE FIELD trans_qty 
			LET l_save_amt = l_rec_debitdist.dist_amt 

		AFTER FIELD trans_qty 
			IF l_rec_debitdist.trans_qty IS NULL THEN 
				LET l_rec_debitdist.trans_qty = 0 
				NEXT FIELD trans_qty 
			END IF 
			IF l_rec_debitdist.trans_qty < 0 THEN 
				LET l_msgresp = kandoomsg("U",9927,"0") 
				# Must Enter value greater than zero
				NEXT FIELD trans_qty 
			END IF 
			LET l_rec_debitdist.dist_amt = l_rec_debitdist.trans_qty 
			* l_rec_debitdist.cost_amt 
			LET l_rec_jobledger.charge_amt = l_rec_debitdist.trans_qty 
			* l_rec_debitdist.charge_amt 
			LET glob_rec_debithead.dist_amt = glob_rec_debithead.dist_amt 
			- l_save_amt 
			+ l_rec_debitdist.dist_amt 
			DISPLAY l_rec_debitdist.trans_qty, 
			l_rec_debitdist.dist_amt, 
			l_rec_jobledger.charge_amt, 
			glob_rec_debithead.dist_amt 
			TO voucherdist.trans_qty, 
			voucherdist.dist_amt, 
			jobledger.charge_amt, 
			voucher.dist_amt 

		BEFORE FIELD cost_amt 
			IF l_rec_jmresource.cost_ind = "2" THEN 
				IF fgl_lastkey() = fgl_keyval("up") THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			ELSE 
				IF glob_rec_debithead.dist_amt > glob_rec_debithead.total_amt THEN 
					LET l_msgresp=kandoomsg("P",9015,"") 
					#P9015 Warning: This entry will over distribute the debithead"
				END IF 
				LET l_save_amt = l_rec_debitdist.dist_amt 
			END IF 

		AFTER FIELD cost_amt 
			IF l_rec_debitdist.cost_amt IS NULL THEN 
				LET l_rec_debitdist.cost_amt = 0 
				NEXT FIELD cost_amt 
			ELSE 
				IF l_rec_debitdist.cost_amt < 0 THEN 
					LET l_msgresp = kandoomsg("U",9927,"0") 
					# Must Enter value greater than zero
					NEXT FIELD cost_amt 
				END IF 
				LET l_rec_debitdist.dist_amt = l_rec_debitdist.trans_qty 
				* l_rec_debitdist.cost_amt 
				LET glob_rec_debithead.dist_amt = glob_rec_debithead.dist_amt 
				- l_save_amt 
				+ l_rec_debitdist.dist_amt 
			END IF 
			DISPLAY l_rec_debitdist.dist_amt, 
			glob_rec_debithead.dist_amt 
			TO voucherdist.dist_amt, 
			voucher.dist_amt 

		BEFORE FIELD dist_amt 
			LET l_save_amt = l_rec_debitdist.dist_amt 
			IF glob_rec_debithead.dist_amt > glob_rec_debithead.total_amt THEN 
				LET l_msgresp=kandoomsg("P",9015,"") 
				#P9015 Warning: This entry will over distribute the debithead"
			END IF 

		AFTER FIELD dist_amt 
			IF l_rec_debitdist.cost_amt IS NULL THEN 
				LET l_rec_debitdist.cost_amt = 0 
			ELSE 
				IF l_rec_debitdist.dist_amt < 0 THEN 
					LET l_msgresp = kandoomsg("U",9927,"0") 
					# Must Enter value greater than zero
					NEXT FIELD dist_amt 
				END IF 
				IF l_rec_jmresource.cost_ind = "1" THEN 
					IF l_rec_debitdist.trans_qty > 0 THEN 
						LET l_rec_debitdist.cost_amt = l_rec_debitdist.dist_amt 
						/ l_rec_debitdist.trans_qty 
					ELSE 
						LET l_rec_debitdist.trans_qty = 1 
						LET l_rec_debitdist.cost_amt = l_rec_debitdist.dist_amt 
					END IF 
				ELSE 
					IF l_rec_debitdist.cost_amt > 0 THEN 
						LET l_rec_debitdist.trans_qty = l_rec_debitdist.dist_amt 
						/ l_rec_debitdist.cost_amt 
					END IF 
				END IF 
			END IF 
			LET glob_rec_debithead.dist_amt = glob_rec_debithead.dist_amt 
			- l_save_amt 
			+ l_rec_debitdist.dist_amt 
			DISPLAY l_rec_debitdist.trans_qty, 
			l_rec_debitdist.cost_amt, 
			l_rec_debitdist.dist_amt, 
			l_rec_jobledger.charge_amt, 
			glob_rec_debithead.dist_amt 
			TO voucherdist.trans_qty, 
			voucherdist.cost_amt, 
			voucherdist.dist_amt, 
			jobledger.charge_amt, 
			voucher.dist_amt 

		BEFORE FIELD charge_amt 
			IF l_rec_jmresource.bill_ind = "2" THEN 
				IF fgl_lastkey() = fgl_keyval("up") THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 

		AFTER FIELD charge_amt 
			IF l_rec_debitdist.charge_amt IS NULL THEN 
				LET l_rec_debitdist.charge_amt = 0 
				NEXT FIELD charge_amt 
			ELSE 
				IF l_rec_debitdist.charge_amt < 0 THEN 
					LET l_msgresp = kandoomsg("U",9927,"0") 
					# Must Enter value greater than zero
					NEXT FIELD charge_amt 
				END IF 
				LET l_rec_jobledger.charge_amt = l_rec_debitdist.trans_qty 
				* l_rec_debitdist.charge_amt 
			END IF 
			DISPLAY l_rec_jobledger.charge_amt TO jobledger.charge_amt 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				SELECT * FROM jmresource 
				WHERE cmpy_code = p_cmpy 
				AND res_code = l_rec_debitdist.res_code 
				IF status = NOTFOUND THEN 
					LET l_msgresp=kandoomsg("P",9029,"") 
					#P9029 " Resource code does NOT exist - Try Window"
					NEXT FIELD res_code 
				END IF 
				SELECT * FROM job 
				WHERE cmpy_code = p_cmpy 
				AND job_code = l_rec_debitdist.job_code 
				IF status = NOTFOUND THEN 
					LET l_msgresp=kandoomsg("P",9030,"") 
					#P9030 " Job code does NOT exist - Try Window"
					NEXT FIELD job_code 
				END IF 
				IF l_rec_debitdist.var_code > 0 THEN 
					SELECT * FROM jobvars 
					WHERE cmpy_code = p_cmpy 
					AND job_code = l_rec_debitdist.job_code 
					AND var_code = l_rec_debitdist.var_code 
					IF status = NOTFOUND THEN 
						LET l_msgresp=kandoomsg("P",9032,"") 
						#P9032 " Job code does NOT exist - Try Window"
						NEXT FIELD var_code 
					END IF 
				END IF 
				SELECT * FROM activity 
				WHERE cmpy_code = p_cmpy 
				AND job_code = l_rec_debitdist.job_code 
				AND var_code = l_rec_debitdist.var_code 
				AND activity_code = l_rec_debitdist.act_code 
				IF status = NOTFOUND THEN 
					LET l_msgresp=kandoomsg("P",9031,"") 
					#P9031 " Job code does NOT exist - Try Window"
					NEXT FIELD act_code 
				END IF 
				IF glob_rec_debithead.dist_amt > glob_rec_debithead.total_amt THEN 
					LET l_msgresp=kandoomsg("P",9015,"") 
					#P9015 Warning: This entry will over distribute the debithead"
				END IF 
				CALL verify_acct_code(p_cmpy, 
				l_rec_debitdist.acct_code, 
				glob_rec_debithead.year_num, 
				glob_rec_debithead.period_num) 
				RETURNING l_rec_coa.* 
				IF l_rec_coa.acct_code IS NULL THEN 
					NEXT FIELD res_code 
				ELSE 
					LET l_rec_debitdist.acct_code = l_rec_coa.acct_code 
					DISPLAY BY NAME l_rec_debitdist.acct_code 

				END IF 
			END IF 

	END INPUT 

	CLOSE WINDOW j148 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN p_rowid 
	ELSE 
		IF p_rowid = 0 THEN 
			SELECT max(line_num) INTO l_rec_debitdist.line_num 
			FROM t_jmdist 
			IF l_rec_debitdist.line_num IS NULL THEN 
				LET l_rec_debitdist.line_num = 1 
			ELSE 
				LET l_rec_debitdist.line_num = l_rec_debitdist.line_num + 1 
			END IF 
			LET l_rec_debitdist.cmpy_code = glob_rec_debithead.cmpy_code 
			LET l_rec_debitdist.vend_code = glob_rec_debithead.vend_code 
			LET l_rec_debitdist.debit_code = glob_rec_debithead.debit_num 
			LET l_rec_debitdist.type_ind = "J" 
			INSERT INTO t_jmdist VALUES (l_rec_debitdist.*) 
			RETURN sqlca.sqlerrd[6] 
		ELSE 
			UPDATE t_jmdist 
			SET res_code = l_rec_debitdist.res_code, 
			job_code = l_rec_debitdist.job_code, 
			var_code = l_rec_debitdist.var_code, 
			act_code = l_rec_debitdist.act_code, 
			acct_code = l_rec_debitdist.acct_code, 
			trans_qty = l_rec_debitdist.trans_qty, 
			cost_amt = l_rec_debitdist.cost_amt, 
			dist_amt = l_rec_debitdist.dist_amt, 
			charge_amt = l_rec_debitdist.charge_amt, 
			desc_text = l_rec_debitdist.desc_text 
			WHERE rowid = p_rowid 
			RETURN p_rowid 
		END IF 
	END IF 
END FUNCTION 


############################################################
# FUNCTION disburse_dist()
#
#
############################################################
FUNCTION disburse_dist() 
	DEFINE l_rec_disbdetl RECORD LIKE disbdetl.* 
	DEFINE l_rec_debitdist RECORD LIKE debitdist.* 
	DEFINE l_total_qty LIKE disbhead.total_qty 
	DEFINE l_dist_amt LIKE debitdist.dist_amt 
	DEFINE l_line_num SMALLINT 

	LET l_dist_amt = glob_rec_debithead.total_amt - glob_rec_debithead.dist_amt 
	CALL enter_disb(glob_rec_debithead.cmpy_code,glob_rec_vendor.usual_acct_code,l_dist_amt) 
	RETURNING l_rec_disbdetl.disb_code,l_dist_amt 
	IF l_rec_disbdetl.disb_code IS NOT NULL AND l_dist_amt > 0 THEN 
		SELECT total_qty INTO l_total_qty 
		FROM disbhead 
		WHERE cmpy_code = glob_rec_debithead.cmpy_code 
		AND disb_code = l_rec_disbdetl.disb_code 
		DECLARE c_disbdetl CURSOR FOR 
		SELECT * FROM disbdetl 
		WHERE cmpy_code = glob_rec_debithead.cmpy_code 
		AND disb_code = l_rec_disbdetl.disb_code 
		SELECT max(line_num) INTO l_line_num 
		FROM t_debitdist 
		IF l_line_num IS NULL THEN 
			LET l_line_num = 0 
		END IF 

		FOREACH c_disbdetl INTO l_rec_disbdetl.* 
			INITIALIZE l_rec_debitdist.* TO NULL 
			LET l_line_num = l_line_num + 1 
			LET l_rec_debitdist.line_num = l_line_num 
			LET l_rec_debitdist.type_ind = "G" 
			LET l_rec_debitdist.acct_code = l_rec_disbdetl.acct_code 
			LET l_rec_debitdist.desc_text = l_rec_disbdetl.desc_text 
			LET l_rec_debitdist.analysis_text = l_rec_disbdetl.analysis_text 
			LET l_rec_debitdist.dist_amt = l_dist_amt 
			* (l_rec_disbdetl.disb_qty/l_total_qty) 
			IF l_rec_debitdist.dist_amt IS NULL THEN 
				LET l_rec_debitdist.dist_amt = 0 
			END IF 
			LET l_rec_debitdist.dist_qty = 0 
			INSERT INTO t_debitdist VALUES (l_rec_debitdist.*) 
		END FOREACH 
		RETURN TRUE 
	ELSE 
		RETURN FALSE 
	END IF 

END FUNCTION 
