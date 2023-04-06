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
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/A4_GROUP_GLOBALS.4gl"
GLOBALS "../ar/A43_J_GLOBALS.4gl" 

###########################################################################
# FUNCTION A43_J_main()
#
# Quick Credit Entry
###########################################################################
FUNCTION A43_J_main() 

	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("A43_J") 

	CALL create_table("creditdetl","t_creditdetl","","N") 

	OPEN WINDOW A226 with FORM "A226" 
	CALL windecoration_a("A226") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	MENU " Credit" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","A43_J","menu-credit-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "ADD" 		#COMMAND "Add" " Enter new credit"
			CALL enter_credit(MODE_CLASSIC_ADD) 

		ON ACTION "EDIT"		#COMMAND "EDIT" " Edit existing credit"
			CALL enter_credit(MODE_CLASSIC_EDIT) 

		ON ACTION "EXIT" 		#COMMAND KEY(interrupt,"E")"Exit" " RETURN TO menus"
			EXIT MENU 

	END MENU 

	CLOSE WINDOW A226 
END FUNCTION 
###########################################################################
# END FUNCTION A43_J_main()
###########################################################################


################################################################
# FUNCTION enter_credit( l_mode_flag )
#
#
################################################################
FUNCTION enter_credit( l_mode_flag ) 
	DEFINE l_mode_flag CHAR(4) 
	DEFINE l_cust_code LIKE credithead.cust_code 
	DEFINE l_save_date LIKE credithead.cred_date
	DEFINE l_invalid_period SMALLINT
	DEFINE l_idx SMALLINT
	DEFINE l_rec_screditdetl RECORD 
		scroll_flag CHAR(1), 
		line_num LIKE creditdetl.line_num, 
		cat_code LIKE creditdetl.cat_code, 
		line_text LIKE creditdetl.line_text, 
		line_acct_code LIKE creditdetl.line_acct_code, 
		line_total_amt LIKE creditdetl.line_total_amt 
	END RECORD 
	DEFINE l_dummy_field CHAR(1) 

	# DELETE FROM t_creditdetl ------------------
	DELETE FROM t_creditdetl WHERE 1=1 
	
	INITIALIZE glob_rec_customer.* TO NULL 
	INITIALIZE glob_rec_credithead.* TO NULL
	 
	LET glob_total_amt = 0 
	LET glob_control_amt = 0 
	
	CLEAR FORM 
	DISPLAY glob_total_amt TO total_amt 

	MESSAGE kandoomsg2("A",1072,"") 	#1072 Enter Credit Details - ESC TO Continue
	
	INPUT 
		glob_rec_customer.cust_code, 
		glob_rec_credithead.cred_date, 
		glob_rec_credithead.year_num, 
		glob_rec_credithead.period_num, 
		glob_rec_credithead.com1_text, 
		glob_rec_credithead.com2_text, 
		glob_rec_credithead.cred_text, 
		glob_control_amt, 
		l_dummy_field WITHOUT DEFAULTS 
	FROM
		glob_rec_customer.cust_code, 
		glob_rec_credithead.cred_date, 
		glob_rec_credithead.year_num, 
		glob_rec_credithead.period_num, 
		glob_rec_credithead.com1_text, 
		glob_rec_credithead.com2_text, 
		glob_rec_credithead.cred_text, 
		glob_control_amt, 
		l_dummy_field	

		BEFORE INPUT 
			IF l_mode_flag = 'EDIT' THEN 
				#
				# Pop-up window TO ask FOR Credit No. ( allow Control-B lookup )
				#      ( Clone of next_manual() FROM trans_num.4gl )
				#
				LET glob_rec_credithead.cred_num = enter_trans_num() 
				IF glob_rec_credithead.cred_num IS NULL THEN 
					#
					# User has DEL'd out
					#
					LET quit_flag = true 
					EXIT INPUT 
				END IF 
				SELECT * INTO glob_rec_credithead.* FROM credithead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cred_num = glob_rec_credithead.cred_num 
				IF sqlca.sqlcode = NOTFOUND THEN 
					#----------------------------------
					# Logic Error b/c enter_trans_num() would have validated above
					ERROR kandoomsg2("A",7076,glob_rec_credithead.cred_num) 		#7076 Logic Error: Credit <VALUE> does NOT exist
					LET quit_flag = true 
					EXIT INPUT 
				END IF 

				CALL db_customer_get_rec(UI_OFF,glob_rec_credithead.cust_code) RETURNING glob_rec_customer.* 
--				SELECT * INTO glob_rec_customer.* FROM customer 
--				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
--				AND cust_code = glob_rec_credithead.cust_code 
				IF glob_rec_customer.cust_code IS NULL THEN
					ERROR kandoomsg2("A",9047,glob_rec_credithead.cust_code)	#9047 Logic Error: Customer <VALUE> does NOT exist
					LET quit_flag = true 
					EXIT INPUT 
				END IF 

				# INSERT INTO t_creditdetl ------------------------------
				INSERT INTO t_creditdetl SELECT * FROM creditdetl 
				WHERE cred_num = glob_rec_credithead.cred_num 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 

				SELECT 1 FROM t_creditdetl WHERE part_code IS NOT NULL 
				IF sqlca.sqlcode = 0 THEN 
					ERROR kandoomsg2("A",9156,"credit") 	#9156 "Product Lines exists in this credit"
					NEXT FIELD cred_num 
				END IF 

				LET glob_control_amt = glob_rec_credithead.goods_amt 

				SELECT sum(line_total_amt) INTO glob_total_amt 
				FROM t_creditdetl 
				IF glob_total_amt IS NULL THEN 
					LET glob_total_amt = 0 
				END IF 

				DISPLAY glob_rec_customer.cust_code TO cust_code attribute( cyan ) 
				DISPLAY glob_rec_customer.name_text TO name_text attribute( cyan ) 
				DISPLAY glob_rec_credithead.cred_date TO cred_date attribute( cyan ) 
				DISPLAY glob_rec_credithead.year_num TO year_num attribute( cyan ) 
				DISPLAY glob_rec_credithead.period_num TO period_num attribute( cyan ) 
				DISPLAY glob_rec_credithead.com1_text TO com1_text attribute( cyan ) 
				DISPLAY glob_rec_credithead.com2_text TO com2_text attribute( cyan ) 
				DISPLAY glob_rec_credithead.cred_text TO cred_text attribute( cyan ) 
				DISPLAY glob_control_amt TO control_amt attribute( cyan ) 
				DISPLAY glob_total_amt TO total_amt attribute( cyan ) 
				
				DISPLAY glob_rec_credithead.currency_code TO currency_code #HuHo: attribute(GREEN) #why with color / green ? I'll remove it 
				#
				# Set up line details
				#
				DECLARE c2_creditdetl CURSOR FOR 
				SELECT 
					"", 
					line_num, 
					cat_code, 
					line_text, 
					line_acct_code, 
					line_total_amt 
				FROM t_creditdetl 
				ORDER BY line_num 
				LET l_idx = 0 

				FOREACH c2_creditdetl INTO l_rec_screditdetl.* 
					LET l_idx = l_idx + 1 
					
					IF l_rec_screditdetl.line_num != l_idx THEN
						#UPDATE t_creditdetl -------------------------------- 
						UPDATE t_creditdetl 
						SET line_num = l_idx 
						WHERE line_num = l_rec_screditdetl.line_num 
						LET l_rec_screditdetl.line_num = l_idx 
					END IF 

					IF l_idx <= 6 THEN 
						DISPLAY l_rec_screditdetl.* 
						TO sr_creditdetl[l_idx].* 
						attribute( cyan ) 
					END IF 
				END FOREACH 

				IF glob_rec_credithead.posted_flag = 'Y' THEN 
					ERROR kandoomsg2("A",7075,"") 				#7075 Warning: Credit posted. Limited editting OPTIONS
					NEXT FIELD com1_text 
				ELSE 
					NEXT FIELD cred_date 
				END IF 
			END IF 

			CALL publish_toolbar("kandoo","A43_J","inp-credithead-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield ( cust_code ) 
			LET glob_temp_text = show_clnt(glob_rec_kandoouser.cmpy_code) 
			IF glob_temp_text IS NOT NULL THEN 
				LET glob_rec_customer.cust_code = glob_temp_text 
			END IF 
			#
			# NEXT FIELD next removed b/c it does a 'BEFORE FIELD cust_code'
			#
			DISPLAY glob_rec_customer.cust_code TO cust_code

		ON ACTION "LOOKUP" infield ( cred_text ) 
			LET glob_temp_text = show_debt() 
			IF glob_temp_text IS NOT NULL THEN 
				LET glob_rec_credithead.cred_text = glob_temp_text 
			END IF 
			NEXT FIELD cred_text 


		BEFORE FIELD cust_code 
			LET l_cust_code = glob_rec_customer.cust_code 

		AFTER FIELD cust_code 
			IF glob_rec_customer.cust_code IS NULL THEN 
				ERROR kandoomsg2("A",9024,"") 			#9024 Customer code must be entered
				NEXT FIELD cust_code 
			END IF 
			
			CALL db_customer_get_rec(UI_OFF,glob_rec_customer.cust_code) RETURNING glob_rec_customer.* 
--			SELECT * INTO glob_rec_customer.* 
--			FROM customer 
--			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
--			AND cust_code = glob_rec_customer.cust_code 
			IF glob_rec_customer.cust_code IS NULL THEN
				ERROR kandoomsg2("A",9009,"")			#9009 Customer code NOT found - Try Window
				NEXT FIELD cust_code 
			END IF 

			IF glob_rec_customer.delete_flag = 'Y' THEN 
				ERROR kandoomsg2("A",9144,"") 	#9144 Customer has been marked FOR deletion
				NEXT FIELD cust_code 
			END IF 
			
			IF glob_rec_customer.hold_code IS NOT NULL THEN 
				ERROR kandoomsg2("A",9143,"") 	#9143 Customer IS on hold - Release before proceeding
				NEXT FIELD cust_code 
			END IF 

			IF glob_rec_customer.corp_cust_code IS NOT NULL	AND glob_rec_customer.corp_cust_ind = '1' THEN 
				SELECT * INTO glob_rec_corpcust.* 
				FROM customer 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = glob_rec_customer.corp_cust_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("A",9115,"") 	#9115 Corporate customer NOT found, setup using A15
					NEXT FIELD cust_code 
				END IF 
				
				IF glob_rec_corpcust.delete_flag = 'Y' THEN 
					ERROR kandoomsg2("A",9144,"") #9144 Customer has been marked FOR deletetion
					NEXT FIELD cust_code 
				END IF 
				
				IF glob_rec_customer.currency_code != glob_rec_corpcust.currency_code THEN 
					ERROR kandoomsg2("A",9060,"") #9060 "Corporate AND Originating Cust currency must be same."
					NEXT FIELD cust_code 
				END IF 
				
				IF glob_rec_corpcust.hold_code IS NOT NULL THEN 
					ERROR kandoomsg2("A",9145,"") #9145 Corporate customer IS on hold - Release before proceeding
					NEXT FIELD cust_code 
				END IF 
				
				IF glob_rec_corpcust.bal_amt > glob_rec_corpcust.cred_limit_amt THEN 
					ERROR kandoomsg2("A",9301,"") #9301 Corporate customer IS over credit limit - adjust credit
					NEXT FIELD cust_code 
				END IF 
				
				LET glob_rec_credithead.cust_code = glob_rec_customer.corp_cust_code 
				LET glob_rec_credithead.org_cust_code = glob_rec_customer.cust_code 
			ELSE 
				IF glob_rec_customer.bal_amt > glob_rec_customer.cred_limit_amt THEN 
					ERROR kandoomsg2("A",9300,"") 		#9300 Customer IS over credit limit - adjust credit
					NEXT FIELD cust_code 
				END IF 
				LET glob_rec_credithead.cust_code = glob_rec_customer.cust_code 
				LET glob_rec_credithead.org_cust_code = NULL 
			END IF 
			#------------------------------
			# INITIALIZE Credit
			IF l_cust_code IS NULL OR l_cust_code != glob_rec_customer.cust_code THEN 
				CALL setup_credit() 
			END IF 

			DISPLAY glob_rec_customer.cust_code TO cust_code ATTRIBUTE(CYAN)
			DISPLAY glob_rec_customer.name_text TO name_text ATTRIBUTE(CYAN)
			DISPLAY glob_rec_credithead.cred_date TO cred_date ATTRIBUTE(CYAN)
			DISPLAY glob_rec_credithead.year_num TO year_num ATTRIBUTE(CYAN)
			DISPLAY glob_rec_credithead.period_num TO period_num ATTRIBUTE(CYAN)
			DISPLAY glob_rec_credithead.com1_text TO com1_text ATTRIBUTE(CYAN)
			DISPLAY glob_rec_credithead.com2_text TO com2_text ATTRIBUTE(CYAN)
			DISPLAY glob_rec_credithead.cred_text TO cred_text ATTRIBUTE(CYAN)
			DISPLAY glob_control_amt TO control_amt ATTRIBUTE(CYAN)
			 
			DISPLAY glob_rec_credithead.currency_code TO currency_code #HuHo: attribute(GREEN) #why with color / green ? I'll remove it 

		BEFORE FIELD cred_date 
			LET l_save_date = glob_rec_credithead.cred_date 

		AFTER FIELD cred_date 
			IF glob_rec_credithead.cred_date IS NULL THEN 
				LET glob_rec_credithead.cred_date = l_save_date 
				NEXT FIELD cred_date 
			END IF 
			IF glob_rec_credithead.cred_date != l_save_date THEN 
				CALL db_period_what_period( glob_rec_kandoouser.cmpy_code, glob_rec_credithead.cred_date ) 
				RETURNING 
					glob_rec_credithead.year_num, 
					glob_rec_credithead.period_num
					 
				IF l_mode_flag = MODE_CLASSIC_ADD AND glob_rec_credithead.currency_code!=glob_rec_glparms.base_currency_code THEN 
					LET glob_rec_credithead.conv_qty = get_conv_rate( 
						glob_rec_kandoouser.cmpy_code, 
						glob_rec_credithead.currency_code , 
						glob_rec_credithead.cred_date,
						CASH_EXCHANGE_SELL ) 
				END IF 
			END IF 
			
			DISPLAY glob_rec_credithead.year_num TO year_num
			DISPLAY glob_rec_credithead.period_num TO period_num

			IF l_mode_flag = MODE_CLASSIC_EDIT THEN 
				IF NOT get_is_screen_navigation_forward() THEN 
					NEXT FIELD cred_date 
				END IF 
			END IF 

		AFTER FIELD com1_text 
			IF l_mode_flag = MODE_CLASSIC_EDIT THEN 
				IF glob_rec_credithead.posted_flag = 'y' THEN 

					IF NOT get_is_screen_navigation_forward() THEN 
						NEXT FIELD com1_text 
					END IF 
				END IF 
			END IF 

		AFTER FIELD cred_text 
			IF glob_rec_credithead.cred_text IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 			#9102 Value must be entered
				NEXT FIELD cred_text 
			ELSE 
				SELECT unique 1 FROM jmj_debttype 
				WHERE debt_type_code = glob_rec_credithead.cred_text 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					ERROR kandoomsg2("U",9105,"") 				#9105 RECORD NOT found; Try window.
					NEXT FIELD cred_text 
				END IF 
			END IF 

		BEFORE FIELD control_amt 
			IF l_mode_flag = MODE_CLASSIC_EDIT THEN 
				IF glob_rec_credithead.posted_flag = 'Y' THEN 
					NEXT FIELD dummy_field 
				END IF 
			END IF 

		AFTER FIELD control_amt 
			IF glob_control_amt < 0 THEN 
				ERROR kandoomsg2("A",9309,"") #9309 "Value must NOT be less than zero"
				NEXT FIELD control_amt 
			END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				#--------------------------------
				# Fiscal Year / Period validation
				#
				CALL valid_period( 
					glob_rec_kandoouser.cmpy_code, 
					glob_rec_credithead.year_num, 
					glob_rec_credithead.period_num, LEDGER_TYPE_AR ) 
				RETURNING 
					glob_rec_credithead.year_num, 
					glob_rec_credithead.period_num, 
					l_invalid_period
					 
				IF l_invalid_period THEN 
					NEXT FIELD year_num 
				END IF 
				#------------------------------
				# Acct Mask
				#
				IF NOT setup_acct_mask( l_mode_flag ) THEN 
					CONTINUE INPUT 
				END IF 
				#---------------------------------
				# Debt. Code
				SELECT unique 1 FROM jmj_debttype 
				WHERE debt_type_code = glob_rec_credithead.cred_text 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					ERROR kandoomsg2("U",9105,"") 	#9105 RECORD NOT found; Try window.
					NEXT FIELD cred_text 
				END IF 
				
				IF NOT lineitem2( l_mode_flag ) THEN 
					IF l_mode_flag = MODE_CLASSIC_ADD THEN 
						NEXT FIELD cust_code 
					ELSE 
						IF glob_rec_credithead.posted_flag = 'Y' THEN 
							NEXT FIELD com1_text 
						ELSE 
							NEXT FIELD cred_date 
						END IF 
					END IF 
				END IF 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 

END FUNCTION 
################################################################
# END FUNCTION enter_credit( l_mode_flag )
################################################################


################################################################
# FUNCTION setup_credit()
#
#
################################################################
FUNCTION setup_credit() 
	DEFINE i SMALLINT
	DEFINE l_s_cust_code LIKE credithead.cust_code
	DEFINE l_s_org_cust_code LIKE credithead.org_cust_code 

	LET l_s_cust_code = glob_rec_credithead.cust_code 
	LET l_s_org_cust_code = glob_rec_credithead.org_cust_code 

	INITIALIZE glob_rec_credithead.* TO NULL 

	LET glob_rec_credithead.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET glob_rec_credithead.cust_code = l_s_cust_code 
	LET glob_rec_credithead.org_cust_code = l_s_org_cust_code 
	LET glob_rec_credithead.cred_date = today 
	LET glob_rec_credithead.acct_override_code = NULL 
	LET glob_rec_credithead.rma_num = 0 
	LET glob_rec_credithead.job_code = NULL 
	LET glob_rec_credithead.entry_code = glob_rec_kandoouser.sign_on_code 
	LET glob_rec_credithead.entry_date = today 
	LET glob_rec_credithead.cred_ind = 'X' 
	LET glob_rec_credithead.sale_code = glob_rec_customer.sale_code 
	LET glob_rec_credithead.tax_code = glob_rec_customer.tax_code 
	LET glob_rec_credithead.tax_per = 0 
	LET glob_rec_credithead.cost_amt = 0 
	LET glob_rec_credithead.goods_amt = 0 
	LET glob_rec_credithead.tax_amt = 0 
	LET glob_rec_credithead.hand_amt = 0 
	LET glob_rec_credithead.hand_tax_code = glob_rec_customer.tax_code 
	LET glob_rec_credithead.hand_tax_amt = 0 
	LET glob_rec_credithead.freight_amt = 0 
	LET glob_rec_credithead.freight_tax_code = glob_rec_customer.tax_code 
	LET glob_rec_credithead.freight_tax_amt = 0 
	LET glob_rec_credithead.appl_amt = 0 
	LET glob_rec_credithead.disc_amt = 0 
	LET glob_rec_credithead.posted_flag = 'N' 
	LET glob_rec_credithead.on_state_flag = 'N' 
	LET glob_rec_credithead.next_num = 0 
	LET glob_rec_credithead.line_num = 0 
	LET glob_rec_credithead.com1_text = NULL 
	LET glob_rec_credithead.com2_text = NULL 
	LET glob_rec_credithead.rev_date = today 
	LET glob_rec_credithead.rev_num = 0 
	LET glob_rec_credithead.cost_ind = NULL 
	LET glob_rec_credithead.conv_qty = 1 
	LET glob_rec_credithead.price_tax_flag = NULL 
	LET glob_rec_credithead.printed_num = 0 
	LET glob_rec_credithead.reason_code = NULL 
	LET glob_rec_credithead.jour_num = NULL 
	LET glob_rec_credithead.post_date = NULL 
	LET glob_rec_credithead.stat_date = NULL 
	LET glob_rec_credithead.address_to_ind = NULL 
	LET glob_rec_credithead.cond_code = NULL 

	#----------------------------
	# Customer Defaults
	#
	CALL get_fiscal_year_period_for_date( glob_rec_credithead.cmpy_code,glob_rec_credithead.cred_date ) 
	RETURNING 
		glob_rec_credithead.year_num, 
		glob_rec_credithead.period_num
	 
	SELECT mgr_code INTO glob_rec_credithead.mgr_code 
	FROM salesperson 
	WHERE cmpy_code = glob_rec_credithead.cmpy_code 
	AND sale_code = glob_rec_customer.sale_code 
	
	SELECT area_code INTO glob_rec_credithead.area_code 
	FROM territory 
	WHERE cmpy_code = glob_rec_credithead.cmpy_code AND terr_code = glob_rec_customer.territory_code 

	LET glob_rec_credithead.currency_code = glob_rec_customer.currency_code 

	IF glob_rec_credithead.currency_code = glob_rec_glparms.base_currency_code THEN 
		LET glob_rec_credithead.conv_qty = 1 
	ELSE 
		IF glob_rec_credithead.conv_qty IS NULL OR glob_rec_credithead.conv_qty = 0 THEN 
			LET glob_rec_credithead.conv_qty = get_conv_rate( 
				glob_rec_kandoouser.cmpy_code, 
				glob_rec_credithead.currency_code, 
				glob_rec_credithead.cred_date, 
				CASH_EXCHANGE_SELL ) 
		END IF 
	END IF 
END FUNCTION 
################################################################
# END FUNCTION setup_credit()
################################################################


################################################################
# FUNCTION save_credit( p_mode_flag )
#
#
################################################################
FUNCTION save_credit(p_mode_flag) 
	DEFINE p_mode_flag CHAR(4)
	DEFINE l_s_cred_text LIKE credithead.cred_text 
	DEFINE l_s_cred_date LIKE credithead.cred_date 

	OPEN WINDOW w1 with FORM "U999" 
	CALL windecoration_u("U999") 

	MENU " Credit" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","A43_J","menu-credit-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "Save" 
			#COMMAND "Save" " Commit credit details TO database"
			IF p_mode_flag = MODE_CLASSIC_ADD THEN 
				LET glob_rec_credithead.cred_num = write_credit(MODE_CLASSIC_ADD) 
			ELSE 
				LET glob_rec_credithead.cred_num = write_credit(MODE_CLASSIC_EDIT) 
			END IF 
			EXIT MENU 

		ON ACTION "Exit" 
			#COMMAND KEY(interrupt,"E")"Exit" " RETURN TO credit entry"
			LET quit_flag = true 
			EXIT MENU 


	END MENU 

	CLOSE WINDOW w1 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		IF glob_rec_credithead.cred_num IS NOT NULL THEN 
			IF glob_rec_credithead.cred_num > 0 THEN 
				MESSAGE kandoomsg2("A",7029,glob_rec_credithead.cred_num)	#7029 Credit <VALUE> added successfully
			END IF 
		END IF 
		RETURN true 
	END IF 
END FUNCTION 
################################################################
# END FUNCTION save_credit( p_mode_flag )
################################################################


################################################################
# FUNCTION enter_trans_num()
#
#
################################################################
FUNCTION enter_trans_num() 
	DEFINE l_next_number LIKE arparms.nextcredit_num
	DEFINE l_prompt_text CHAR(40)
	DEFINE l_trans_text CHAR(20) 

	LET l_trans_text = kandooword("nextnumber.tran_type_ind",TRAN_TYPE_CREDIT_CR) 
	IF l_trans_text IS NULL THEN 
		ERROR kandoomsg2("U",9007,"") 
		LET l_trans_text = "Next Credit Number" 
	END IF 

	LET l_prompt_text = l_trans_text clipped,"............." 
	OPTIONS comment line FIRST 

	OPEN WINDOW A203 with FORM "A203" 
	CALL windecoration_a("A203") 

	#DISPLAY "" AT 9,1
	#DISPLAY " Enter unique Quick Credit number (W)" AT 9,1
	MESSAGE " Enter unique Quick Credit number (W)" 
	DISPLAY l_prompt_text TO prompt_text 

	INPUT l_next_number FROM next_number
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A43_J","inp-l_next_number") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" #ON KEY (control-b) 
			OPTIONS comment line LAST 
			LET glob_temp_text = show_qcred() 
			IF glob_temp_text IS NOT NULL THEN 
				LET l_next_number = glob_temp_text 
			END IF 
			
			OPTIONS comment line FIRST 
		--	DISPLAY "" at 9,1 
			CALL fgl_winmessage("Credit number","Enter unique Quick Credit number (W)","INFO") 

			NEXT FIELD next_number 

		AFTER INPUT 
			IF NOT ( int_flag OR quit_flag ) THEN 
				IF l_next_number IS NULL THEN 
					ERROR kandoomsg2("G",9025,l_trans_text) 				#9025 l_trans_text clipped, " must be entered "
					NEXT FIELD next_number 
				END IF 				IF l_next_number < 0 THEN 
					ERROR kandoomsg2("G",9026,l_trans_text)					#9026 l_trans_text clipped, " Must be Greater than Zero"
					NEXT FIELD next_number 
				END IF 
				
				SELECT unique 1 FROM credithead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cred_num = l_next_number 
				AND cred_ind = 'X' 

				IF sqlca.sqlcode = NOTFOUND THEN 
					ERROR kandoomsg2("U",9105,"") 				#9105 RECORD NOT found; Try window.
					NEXT FIELD next_number 
				END IF 
			END IF 


	END INPUT 

	CLOSE WINDOW A203 

	OPTIONS comment line LAST 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN "" 
	ELSE 
		RETURN l_next_number 
	END IF 

END FUNCTION 
################################################################
# END FUNCTION enter_trans_num()
################################################################


################################################################
# FUNCTION lineitem2( l_mode_flag )
#
#
################################################################
FUNCTION lineitem2( l_mode_flag ) 
	DEFINE l_mode_flag CHAR(4)
	DEFINE l_rec_creditdetl RECORD LIKE creditdetl.*
	DEFINE l_rec_screditdetl RECORD LIKE creditdetl.*
	DEFINE l_rec_coa RECORD LIKE coa.*
	DEFINE l_arr_rec_creditdetl DYNAMIC ARRAY OF RECORD --array[300] OF RECORD 
		scroll_flag CHAR(1), 
		line_num LIKE creditdetl.line_num, 
		cat_code LIKE creditdetl.cat_code, 
		line_text LIKE creditdetl.line_text, 
		line_acct_code LIKE creditdetl.line_acct_code, 
		line_total_amt LIKE creditdetl.line_total_amt 
	END RECORD 
	DEFINE l_cat_code LIKE product.cat_code
	DEFINE l_trans_code LIKE jmj_trantype.trans_code
	DEFINE l_lastkey INTEGER
	DEFINE l_idx SMALLINT
	DEFINE l_valid_ind SMALLINT
	DEFINE l_kandoo_len SMALLINT
	DEFINE i SMALLINT
	DEFINE j SMALLINT
	DEFINE l_ans CHAR(1) 


	IF l_mode_flag = MODE_CLASSIC_EDIT THEN 
		IF glob_rec_credithead.posted_flag = 'Y' THEN 
			IF save_credit( l_mode_flag ) THEN 
				RETURN true 
			ELSE 
				RETURN false 
			END IF 
		END IF 
	END IF 

	DECLARE c1_creditdetl CURSOR FOR 
	SELECT * FROM t_creditdetl 
	ORDER BY line_num 
	LET l_idx = 0 

	FOREACH c1_creditdetl INTO l_rec_creditdetl.* 
		LET l_idx = l_idx + 1 

		IF l_rec_creditdetl.line_num != l_idx THEN 
			#UPDATE --------------------------------
			UPDATE t_creditdetl 
			SET line_num = l_idx 
			WHERE line_num = l_rec_creditdetl.line_num 
			LET l_rec_creditdetl.line_num = l_idx 
		END IF 

		LET l_arr_rec_creditdetl[l_idx].line_num = l_rec_creditdetl.line_num 
		LET l_arr_rec_creditdetl[l_idx].cat_code = l_rec_creditdetl.cat_code 
		LET l_arr_rec_creditdetl[l_idx].line_text = l_rec_creditdetl.line_text 
		LET l_arr_rec_creditdetl[l_idx].line_acct_code = l_rec_creditdetl.line_acct_code 
		LET l_arr_rec_creditdetl[l_idx].line_total_amt = l_rec_creditdetl.line_total_amt 
	END FOREACH 

	CALL set_count(l_idx) 
	OPTIONS INSERT KEY f1, 
	DELETE KEY f36 

	##
	#1024 F1 TO Add etc...
	INPUT ARRAY l_arr_rec_creditdetl WITHOUT DEFAULTS FROM sr_creditdetl.* ATTRIBUTE(UNBUFFERED) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A43_J","inp-arr-creditdetl-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (cat_code) 
			LET glob_temp_text = show_tran() 
			IF glob_temp_text IS NOT NULL THEN 
				LET l_arr_rec_creditdetl[l_idx].cat_code = glob_temp_text 
			END IF 
			OPTIONS INSERT KEY f1, 
			DELETE KEY f36 
			NEXT FIELD cat_code 

		ON ACTION "LOOKUP" infield (line_acct_code) 
			LET glob_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF glob_temp_text IS NOT NULL 
			AND glob_temp_text != " " THEN 
				LET l_arr_rec_creditdetl[l_idx].line_acct_code = glob_temp_text 
			END IF 
			OPTIONS INSERT KEY f1, 
			DELETE KEY f36 
			NEXT FIELD line_acct_code 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			#LET scrn = scr_line()
			LET l_lastkey = NULL 
			
			SELECT * INTO l_rec_creditdetl.* 
			FROM t_creditdetl 
			WHERE line_num = l_arr_rec_creditdetl[l_idx].line_num 
			IF sqlca.sqlcode = NOTFOUND THEN 
				LET l_rec_creditdetl.line_num = NULL 
				NEXT FIELD line_num 
			ELSE 
				#CALL disp_line(scrn,l_rec_creditdetl.*)
				NEXT FIELD scroll_flag 
			END IF 

		AFTER FIELD scroll_flag 
			LET l_lastkey = fgl_lastkey() 

		BEFORE FIELD line_num 
			LET l_lastkey = fgl_lastkey() 
			IF l_rec_creditdetl.line_num IS NULL THEN 
				CALL insert_detlline() 
				RETURNING l_rec_creditdetl.* 
				INITIALIZE l_rec_screditdetl.* TO NULL 
				LET l_cat_code = NULL 
				LET l_arr_rec_creditdetl[l_idx].line_num = l_rec_creditdetl.line_num 
				LET l_arr_rec_creditdetl[l_idx].cat_code = l_rec_creditdetl.cat_code 
				LET l_arr_rec_creditdetl[l_idx].line_text = l_rec_creditdetl.line_text 
				LET l_arr_rec_creditdetl[l_idx].line_acct_code = 
				l_rec_creditdetl.line_acct_code 
				LET l_arr_rec_creditdetl[l_idx].line_total_amt = 
				l_rec_creditdetl.line_total_amt 
			ELSE 
				LET l_rec_screditdetl.* = l_rec_creditdetl.* 
				LET l_cat_code = l_rec_screditdetl.cat_code 
			END IF 

			CALL disp_line(l_idx,l_rec_creditdetl.*) #huho: CALL disp_line(scrn,l_rec_creditdetl.*)
 
			IF l_lastkey = fgl_keyval("left") OR l_lastkey = fgl_keyval("up") THEN 
				NEXT FIELD scroll_flag 
			ELSE 
				NEXT FIELD cat_code 
			END IF 

		BEFORE FIELD cat_code 
			LET l_cat_code = l_rec_creditdetl.cat_code 

		AFTER FIELD cat_code 
			LET l_lastkey = fgl_lastkey() 
			LET l_rec_creditdetl.cat_code = l_arr_rec_creditdetl[l_idx].cat_code 
			IF l_cat_code IS NULL	OR l_rec_creditdetl.cat_code != l_cat_code THEN 
				#----------------------------------------------
				# WHEN trans. code changed (OR first entered)
				#      THEN description & account must be reset.
				#
				LET l_cat_code = l_rec_creditdetl.cat_code 
				LET l_rec_creditdetl.line_text = NULL 
				LET l_rec_creditdetl.line_acct_code = NULL 
				LET l_rec_creditdetl.unit_sales_amt = 0 
				LET l_rec_creditdetl.line_total_amt = 0 
			END IF 
			IF l_rec_creditdetl.cat_code IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 			#9102 Value must be entered
				NEXT FIELD cat_code 
			END IF 
			
			WHENEVER any ERROR CONTINUE 
			LET l_trans_code = l_rec_creditdetl.cat_code 
			WHENEVER any ERROR stop 
			
			IF status < 0 THEN 
				ERROR kandoomsg2("I",9096,"") 			#9096 "A number must be entered"
				NEXT FIELD cat_code 
			END IF 
			
			SELECT * INTO glob_rec_jmjtrantype.* 
			FROM jmj_trantype 
			WHERE trans_code = l_rec_creditdetl.cat_code 
			AND record_ind = 'A' 
			AND imprest_ind = 'N' 

			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF sqlca.sqlcode = NOTFOUND THEN 
				ERROR kandoomsg2("U",9105,"") 			#9105 RECORD NOT found; Try window.
				NEXT FIELD cat_code 
			END IF 
			
			IF glob_rec_jmjtrantype.debt_type_code != glob_rec_credithead.cred_text THEN 
				ERROR kandoomsg2("A",6004,"") 			#6004 "Warning: Conflicting Debt. Types between header AND detail"
			END IF
			 
			SELECT * INTO l_rec_screditdetl.* 
			FROM t_creditdetl 
			WHERE line_num = l_rec_creditdetl.line_num 
			
			IF l_rec_screditdetl.cat_code IS NULL	OR l_rec_screditdetl.cat_code != l_rec_creditdetl.cat_code THEN 
				LET l_rec_creditdetl.line_acct_code = glob_rec_jmjtrantype.cr_acct_code 
			END IF 
			
			IF l_rec_creditdetl.line_text IS NULL THEN 
				LET l_kandoo_len = 30 - length(glob_rec_customer.cust_code) - 1 
				IF glob_rec_credithead.com1_text IS NULL THEN 
					LET l_rec_creditdetl.line_text = 
					glob_rec_customer.name_text[1, l_kandoo_len] clipped," ", 
					glob_rec_customer.cust_code clipped 
				ELSE 
					LET l_rec_creditdetl.line_text = 
					glob_rec_credithead.com1_text[1, l_kandoo_len] clipped, 
					" ", glob_rec_customer.cust_code clipped 
				END IF 
			END IF 

			CALL A43_creditdetl_update_line( l_rec_creditdetl.* ) 
			SELECT * INTO l_rec_creditdetl.* 
			FROM t_creditdetl 
			WHERE line_num = l_rec_creditdetl.line_num 
			
			CALL disp_line(l_idx, l_rec_creditdetl.* ) #call disp_line(scrn, l_rec_creditdetl.* ) 
			
			LET l_arr_rec_creditdetl[l_idx].cat_code = l_rec_creditdetl.cat_code 
			LET l_arr_rec_creditdetl[l_idx].line_text = l_rec_creditdetl.line_text 
			LET l_arr_rec_creditdetl[l_idx].line_acct_code = l_rec_creditdetl.line_acct_code 
			LET l_arr_rec_creditdetl[l_idx].line_total_amt = l_rec_creditdetl.line_total_amt 

			CASE 
				WHEN l_lastkey=fgl_keyval("accept") 
					NEXT FIELD line_total_amt 
				WHEN l_lastkey=fgl_keyval("RETURN") 
					OR l_lastkey=fgl_keyval("right") 
					OR l_lastkey=fgl_keyval("tab") 
					OR l_lastkey=fgl_keyval("down") 
					NEXT FIELD NEXT 
				WHEN l_lastkey=fgl_keyval("left") 
					OR l_lastkey=fgl_keyval("up") 
					NEXT FIELD previous 
				OTHERWISE 
					NEXT FIELD cat_code 
			END CASE 

		AFTER FIELD line_text 
			LET l_lastkey = fgl_lastkey() 
			LET l_rec_creditdetl.line_text = l_arr_rec_creditdetl[l_idx].line_text 
			CALL A43_creditdetl_update_line( l_rec_creditdetl.* ) 
			CALL disp_line(l_idx, l_rec_creditdetl.* ) #call disp_line(scrn, l_rec_creditdetl.* ) 

			CASE 
				WHEN l_lastkey=fgl_keyval("accept") 
					NEXT FIELD line_total_amt 
				WHEN l_lastkey=fgl_keyval("RETURN") 
					OR l_lastkey=fgl_keyval("right") 
					OR l_lastkey=fgl_keyval("tab") 
					OR l_lastkey=fgl_keyval("down") 
					NEXT FIELD NEXT 
				WHEN l_lastkey=fgl_keyval("left") 
					OR l_lastkey=fgl_keyval("up") 
					NEXT FIELD previous 
				OTHERWISE 
					NEXT FIELD line_text 
			END CASE 

		AFTER FIELD line_acct_code 
			LET l_lastkey = fgl_lastkey() 
			LET l_rec_creditdetl.line_acct_code = l_arr_rec_creditdetl[l_idx].line_acct_code
			 
			CALL verify_acct_code( 
				glob_rec_kandoouser.cmpy_code, 
				l_rec_creditdetl.line_acct_code , 
				glob_rec_credithead.year_num , 
				glob_rec_credithead.period_num ) 
			RETURNING l_rec_coa.* 
			
			IF l_rec_coa.acct_code IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 				#9102 Value must be entered
				NEXT FIELD line_acct_code 
			END IF 
			
			LET l_rec_creditdetl.line_acct_code = l_rec_coa.acct_code 
			LET l_arr_rec_creditdetl[l_idx].line_acct_code = l_rec_creditdetl.line_acct_code 
			
			CALL A43_creditdetl_update_line( l_rec_creditdetl.* ) 
			CALL disp_line(l_idx, l_rec_creditdetl.* ) --call disp_line(scrn, l_rec_creditdetl.* ) 

			CASE 
				WHEN l_lastkey=fgl_keyval("accept") 
					NEXT FIELD line_total_amt 
				WHEN l_lastkey=fgl_keyval("RETURN") 
					OR l_lastkey=fgl_keyval("right") 
					OR l_lastkey=fgl_keyval("tab") 
					OR l_lastkey=fgl_keyval("down") 
					NEXT FIELD NEXT 
				WHEN l_lastkey=fgl_keyval("left") 
					OR l_lastkey=fgl_keyval("up") 
					NEXT FIELD previous 
				OTHERWISE 
					NEXT FIELD line_acct_code 
			END CASE 

		BEFORE FIELD line_total_amt 
			IF l_lastkey = fgl_keyval("interrupt") 
			OR l_lastkey = fgl_keyval("accept") THEN 
				#
				# IF line entry NOT complete THEN RETURN TO scroll flag
				#
				NEXT FIELD scroll_flag 
			END IF 

		AFTER FIELD line_total_amt 
			LET l_lastkey = fgl_lastkey() 
			IF l_arr_rec_creditdetl[l_idx].line_total_amt < 0 THEN 
				ERROR kandoomsg2("A",9309,"") 		#9309 "Value must NOT be less than zero"
				NEXT FIELD line_total_amt 
			END IF 
			LET l_rec_creditdetl.unit_sales_amt = l_arr_rec_creditdetl[l_idx].line_total_amt 
			LET l_rec_creditdetl.line_total_amt = l_arr_rec_creditdetl[l_idx].line_total_amt 
			CALL A43_creditdetl_update_line( l_rec_creditdetl.* ) 
			CALL disp_line(l_idx, l_rec_creditdetl.* ) --call disp_line(scrn, l_rec_creditdetl.* ) 

		ON KEY (F2)
			# DELETE FROM t_creditdetl ------------------ 
			DELETE FROM t_creditdetl 
			WHERE line_num = l_arr_rec_creditdetl[l_idx].line_num 
			#LET j = scrn
			FOR i = l_idx TO arr_count() 
				IF i = 300 THEN 
					INITIALIZE l_arr_rec_creditdetl[300].* TO NULL 
				ELSE 
					LET l_arr_rec_creditdetl[i].* = l_arr_rec_creditdetl[i+1].* 
				END IF 
				
				IF l_arr_rec_creditdetl[i].line_num = 0 THEN 
					INITIALIZE l_arr_rec_creditdetl[i].* TO NULL 
				END IF 
				IF j <= 6 THEN 
					DISPLAY l_arr_rec_creditdetl[i].* TO sr_creditdetl[j].* 

					LET j = j + 1 
				END IF 
			END FOR 

			SELECT * INTO l_rec_creditdetl.* 
			FROM t_creditdetl 
			WHERE line_num = l_arr_rec_creditdetl[l_idx].line_num 
			IF sqlca.sqlcode = NOTFOUND THEN 
				INITIALIZE l_rec_creditdetl.* TO NULL 
			END IF 
			
			CALL disp_line(l_idx,l_rec_creditdetl.*) --call disp_line(scrn,l_rec_creditdetl.*) 
			NEXT FIELD scroll_flag 

		BEFORE INSERT 
			INITIALIZE l_arr_rec_creditdetl[l_idx].* TO NULL 
			INITIALIZE l_rec_creditdetl.* TO NULL 
			NEXT FIELD line_num 

		AFTER ROW 
			LET l_arr_rec_creditdetl[l_idx].scroll_flag = NULL 
			#DISPLAY l_arr_rec_creditdetl[l_idx].* TO sr_creditdetl[scrn].*

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				IF NOT infield(scroll_flag) THEN 
					LET int_flag = false 
					LET quit_flag = false 
					
					IF l_rec_screditdetl.line_num IS NULL THEN 
						# DELETE FROM t_creditdetl ------------------
						DELETE FROM t_creditdetl 
						WHERE line_num = l_arr_rec_creditdetl[l_idx].line_num 
						#LET j = scrn
						FOR i = arr_curr() TO arr_count() 
							IF l_arr_rec_creditdetl[i+1].line_num IS NOT NULL THEN 
								LET l_arr_rec_creditdetl[i].* = l_arr_rec_creditdetl[i+1].* 
							ELSE 
								INITIALIZE l_arr_rec_creditdetl[i].* TO NULL 
							END IF 
							IF j <= 5 THEN 
								DISPLAY l_arr_rec_creditdetl[i].* TO sr_creditdetl[j].* 

								LET j = j + 1 
							END IF 
						END FOR 

					ELSE 

						CALL A43_creditdetl_update_line(l_rec_screditdetl.*) 
						LET l_arr_rec_creditdetl[l_idx].cat_code = l_rec_screditdetl.cat_code 
						LET l_arr_rec_creditdetl[l_idx].line_text = l_rec_screditdetl.line_text 
						LET l_arr_rec_creditdetl[l_idx].line_acct_code = l_rec_screditdetl.line_acct_code 
						LET l_arr_rec_creditdetl[l_idx].line_total_amt = l_rec_screditdetl.line_total_amt 
					END IF 
					#CALL disp_line(scrn,l_rec_screditdetl.*)
					NEXT FIELD scroll_flag 
				END IF 
			ELSE 
				IF glob_total_amt != glob_control_amt THEN 
					ERROR kandoomsg2("A",9515,"Credit") 				#9515 "Credit total does NOT equal Control amount"
					CONTINUE INPUT 
				END IF 
				
				IF l_mode_flag = MODE_CLASSIC_EDIT 
				AND glob_total_amt < glob_rec_credithead.appl_amt THEN 
					ERROR kandoomsg2("A",9518,"") 				#9518 "Credit total less than amount applied"
					CONTINUE INPUT 
				END IF 
			END IF 

	END INPUT 

	# DELETE FROM t_creditdetl ------------------
	DELETE FROM t_creditdetl 
	WHERE part_code IS NULL 
	AND line_text IS NULL 
	AND ( line_total_amt IS NULL OR line_total_amt = 0 ) 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 

		IF kandoomsg("A",8011,"") = "N" THEN 		#8011 Do you wish TO hold line info ?
			# DELETE FROM t_creditdetl ------------------
			DELETE FROM t_creditdetl WHERE 1=1 
			LET glob_rec_credithead.line_num = 0 
		END IF 
		RETURN false 
	ELSE 
		IF save_credit( l_mode_flag ) THEN 
			RETURN true 
		ELSE 
			RETURN false 
		END IF 
	END IF 
END FUNCTION 
################################################################
# END FUNCTION lineitem2( l_mode_flag )
################################################################


################################################################
# FUNCTION insert_detlline()
#
# This FUNCTION inserts a line in the t_creditdetl with the appropriate
# defaults.
################################################################
FUNCTION insert_detlline() 
	DEFINE l_rec_creditdetl RECORD LIKE creditdetl.* 

	SELECT max(line_num) INTO l_rec_creditdetl.line_num 
	FROM t_creditdetl 
	IF l_rec_creditdetl.line_num IS NULL THEN 
		LET l_rec_creditdetl.line_num = 1 
	ELSE 
		LET l_rec_creditdetl.line_num = l_rec_creditdetl.line_num + 1 
	END IF 
	LET l_rec_creditdetl.ware_code = NULL 
	LET l_rec_creditdetl.part_code = NULL 
	LET l_rec_creditdetl.ship_qty = 1 
	LET l_rec_creditdetl.received_qty = 1 
	LET l_rec_creditdetl.unit_cost_amt = 0 
	LET l_rec_creditdetl.ext_cost_amt = 0 
	LET l_rec_creditdetl.disc_amt = 0 
	LET l_rec_creditdetl.unit_sales_amt = 0 
	LET l_rec_creditdetl.ext_sales_amt = 0 
	LET l_rec_creditdetl.unit_tax_amt = 0 
	LET l_rec_creditdetl.ext_tax_amt = 0 
	LET l_rec_creditdetl.line_total_amt = 0 
	LET l_rec_creditdetl.seq_num = 0 
	LET l_rec_creditdetl.level_code = glob_rec_customer.inv_level_ind 
	LET l_rec_creditdetl.comm_amt = 0 
	LET l_rec_creditdetl.tax_code = glob_rec_credithead.tax_code 
	LET l_rec_creditdetl.km_qty = 0 

	# INSERT INTO t_creditdetl ------------------------------
	INSERT INTO t_creditdetl VALUES (l_rec_creditdetl.*) 

	RETURN l_rec_creditdetl.* 
END FUNCTION 
################################################################
# END FUNCTION insert_detlline()
################################################################


################################################################
# FUNCTION disp_line( p_scrn, p_rec_creditdetl )
#
#
################################################################
FUNCTION disp_line( p_scrn, p_rec_creditdetl )
	DEFINE p_scrn SMALLINT  
	DEFINE p_rec_creditdetl RECORD LIKE creditdetl.*
	DEFINE l_desc_text CHAR(30)
	--p_scrn SMALLINT 

	### DISPLAY Current Line Info
	#DISPLAY "",p_rec_creditdetl.line_num,
	#           p_rec_creditdetl.cat_code,
	#           p_rec_creditdetl.line_text,
	#           p_rec_creditdetl.line_acct_code,
	#           p_rec_creditdetl.line_total_amt
	#        TO sr_creditdetl[p_scrn].*

	SELECT sum( line_total_amt ) INTO glob_total_amt 
	FROM t_creditdetl 
	IF glob_total_amt IS NULL THEN 
		LET glob_total_amt = 0 
	END IF 

	SELECT * INTO glob_rec_jmjtrantype.* 
	FROM jmj_trantype 

	WHERE trans_code = p_rec_creditdetl.cat_code 
	AND record_ind = 'A' 
	AND imprest_ind = 'N' 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = NOTFOUND THEN 
		INITIALIZE glob_rec_jmjtrantype.* TO NULL 
	END IF 

	DISPLAY 
		glob_rec_jmjtrantype.desc_text, 
		glob_rec_jmjtrantype.debt_type_code, 
		glob_total_amt 
	TO 
		jmj_trantype.desc_text, 
		jmj_trantype.debt_type_code, 
		glob_total_amt 

END FUNCTION 
################################################################
# END FUNCTION disp_line( p_scrn, p_rec_creditdetl )
################################################################


################################################################
# FUNCTION show_debt()
#
#
################################################################
FUNCTION show_debt() 
	DEFINE l_rec_jmjdebttype RECORD LIKE jmj_debttype.*
	DEFINE l_arr_rec_jmjdebttype array[100] OF RECORD 
		scroll_flag CHAR(1), 
		debt_type_code LIKE jmj_debttype.debt_type_code, 
		desc_text LIKE jmj_debttype.desc_text 
	END RECORD
	DEFINE l_idx SMALLINT
	#scrn smallin,
	DEFINE l_query_text CHAR(700)
	DEFINE l_where_text CHAR(300) 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	OPEN WINDOW A223 with FORM "A223" 
	CALL windecoration_a("A223") 

	CLEAR FORM 
	MESSAGE kandoomsg2("A",1001,"")	#1001 " Enter Selection Criteria - ESC TO Continue"
	CONSTRUCT BY NAME l_where_text ON debt_type_code, desc_text 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","A43_J","construct-debt") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		CLOSE WINDOW A223 
		RETURN "" 
	END IF 

	MESSAGE kandoomsg2("A",1002,"") #1002 " Searching database - please wait"

	LET l_query_text = 
		"SELECT * ", 
		"FROM jmj_debttype ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY debt_type_code" 

	PREPARE s_debttype FROM l_query_text 
	DECLARE c_debttype CURSOR FOR s_debttype 
	LET l_idx = 0 

	FOREACH c_debttype INTO l_rec_jmjdebttype.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_jmjdebttype[l_idx].debt_type_code = l_rec_jmjdebttype.debt_type_code 
		LET l_arr_rec_jmjdebttype[l_idx].desc_text = l_rec_jmjdebttype.desc_text 
		IF l_idx = 100 THEN 
			ERROR kandoomsg2("U",6100,l_idx) 			#6100 "First l_idx records selected "
			EXIT FOREACH 
		END IF 
	END FOREACH 

	MESSAGE kandoomsg2("U",9113,l_idx)	#9113 l_idx records selected
--	IF l_idx = 0 THEN 
--		LET l_idx = 1 
--		INITIALIZE l_arr_rec_jmjdebttype[1].* TO NULL 
--	END IF 
	MESSAGE kandoomsg2("A",1008,"") 	#1008 F3/F4 TO page Fwd/Bwd - ESC TO Continue
	CALL set_count(l_idx) 

	INPUT ARRAY l_arr_rec_jmjdebttype WITHOUT DEFAULTS FROM sr_jmjdebttype.* ATTRIBUTE(UNBUFFERED) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A43_J","inp-arr-jmjdebttype-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON KEY (F10) 
			CALL run_prog("AZ6_J","","","","") 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			#LET scrn = scr_line()
			IF l_arr_rec_jmjdebttype[l_idx].debt_type_code IS NOT NULL THEN 
				#DISPLAY l_arr_rec_jmjdebttype[l_idx].*
				#     TO sr_jmjdebttype[scrn].*

			END IF 
			NEXT FIELD scroll_flag 

		AFTER FIELD scroll_flag 
			LET l_arr_rec_jmjdebttype[l_idx].scroll_flag = NULL 
			IF fgl_lastkey() = fgl_keyval("down") AND arr_curr() >= arr_count() THEN 
				ERROR kandoomsg2("A",9001,"") 
				NEXT FIELD scroll_flag 
			END IF 

		BEFORE FIELD debt_type_code 
			LET l_rec_jmjdebttype.debt_type_code = l_arr_rec_jmjdebttype[l_idx].debt_type_code 
			EXIT INPUT 
			#AFTER ROW
			#   DISPLAY l_arr_rec_jmjdebttype[l_idx].*
			#        TO sr_jmjdebttype[scrn].*

		AFTER INPUT 
			LET l_rec_jmjdebttype.debt_type_code = l_arr_rec_jmjdebttype[l_idx].debt_type_code 

	END INPUT 

	CLOSE WINDOW A223 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN "" 
	ELSE 
		RETURN l_rec_jmjdebttype.debt_type_code 
	END IF 
END FUNCTION 
################################################################
# END FUNCTION show_debt()
################################################################


################################################################
# FUNCTION show_tran()
#
#
################################################################
FUNCTION show_tran() 
	DEFINE l_rec_jmjtrantype RECORD LIKE jmj_trantype.* 
	DEFINE l_arr_rec_jmjtrantype array[100] OF RECORD 
		scroll_flag CHAR(1), 
		trans_code LIKE jmj_trantype.trans_code, 
		desc_text LIKE jmj_trantype.desc_text, 
		cr_acct_code LIKE jmj_trantype.cr_acct_code, 
		debt_type_code LIKE jmj_trantype.debt_type_code 
	END RECORD 
	DEFINE l_idx SMALLINT
	DEFINE l_query_text CHAR(700) 
	DEFINE l_where_text CHAR(300) 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	OPEN WINDOW A224 with FORM "A224" 
	CALL windecoration_a("A224") 

	CLEAR FORM 
	MESSAGE kandoomsg2("A",1001,"") #1001 " Enter Selection Criteria - ESC TO Continue"
	CONSTRUCT BY NAME l_where_text ON 
		trans_code, 
		desc_text, 
		cr_acct_code, 
		debt_type_code 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","A43_J","construct-tran") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		CLOSE WINDOW A224 
		RETURN "" 
	END IF 

	MESSAGE kandoomsg2("A",1002,"") #1002 " Searching database - please wait"

	LET l_query_text = 
		"SELECT * ", 
		"FROM jmj_trantype ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND record_ind = 'A' ", 
		"AND imprest_ind = 'N' ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY trans_code" 

	PREPARE s_trantype FROM l_query_text 
	DECLARE c_trantype CURSOR FOR s_trantype 
	LET l_idx = 0 

	FOREACH c_trantype INTO l_rec_jmjtrantype.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_jmjtrantype[l_idx].trans_code = l_rec_jmjtrantype.trans_code 
		LET l_arr_rec_jmjtrantype[l_idx].desc_text = l_rec_jmjtrantype.desc_text 
		LET l_arr_rec_jmjtrantype[l_idx].cr_acct_code = l_rec_jmjtrantype.cr_acct_code 
		LET l_arr_rec_jmjtrantype[l_idx].debt_type_code = l_rec_jmjtrantype.debt_type_code 

		IF l_idx = 100 THEN 
			ERROR kandoomsg2("U",6100,l_idx)	#6100 "First l_idx records selected "
			EXIT FOREACH 
		END IF 
	END FOREACH 

	MESSAGE kandoomsg2("U",9113,l_idx) #9113 l_idx records selected
--	IF l_idx = 0 THEN 
--		LET l_idx = 1 
--		INITIALIZE l_arr_rec_jmjtrantype[1].* TO NULL 
--	END IF 
	MESSAGE kandoomsg2("A",1008,"")	#1008 F3/F4 TO page Fwd/Bwd - ESC TO Continue
	CALL set_count(l_idx) 

	INPUT ARRAY l_arr_rec_jmjtrantype WITHOUT DEFAULTS FROM sr_jmjtrantype.* ATTRIBUTE(UNBUFFERED) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A43_J","inp-arr-jmjdebttype-2") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON KEY (F10) 
			CALL run_prog("AZ7_J","","","","") 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			#LET scrn = scr_line()
			IF l_arr_rec_jmjtrantype[l_idx].trans_code IS NOT NULL THEN 
				#DISPLAY l_arr_rec_jmjtrantype[l_idx].*
				#     TO sr_jmjtrantype[scrn].*

			END IF 
			NEXT FIELD scroll_flag 

		AFTER FIELD scroll_flag 
			LET l_arr_rec_jmjtrantype[l_idx].scroll_flag = NULL 
			IF fgl_lastkey() = fgl_keyval("down") AND arr_curr() >= arr_count() THEN 
				ERROR kandoomsg2("A",9001,"") 
				NEXT FIELD scroll_flag 
			END IF 

		BEFORE FIELD trans_code 
			LET l_rec_jmjtrantype.trans_code = l_arr_rec_jmjtrantype[l_idx].trans_code 
			EXIT INPUT 
			#AFTER ROW
			#   DISPLAY l_arr_rec_jmjtrantype[l_idx].*
			#        TO sr_jmjtrantype[scrn].*

		AFTER INPUT 
			LET l_rec_jmjtrantype.trans_code = l_arr_rec_jmjtrantype[l_idx].trans_code 


	END INPUT 

	CLOSE WINDOW A224 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN "" 
	ELSE 
		RETURN l_rec_jmjtrantype.trans_code 
	END IF 
END FUNCTION 
################################################################
# END FUNCTION show_tran()
################################################################


################################################################
# FUNCTION show_qcred()
#
#
################################################################
FUNCTION show_qcred() 
	DEFINE l_rec_credithead RECORD LIKE credithead.*
	DEFINE l_rec_creditdetl RECORD LIKE creditdetl.*
	DEFINE l_arr_rec_credithead array[100] OF RECORD 
		scroll_flag CHAR(1), 
		cred_num LIKE credithead.cred_num, 
		cust_code LIKE credithead.cust_code, 
		cred_date LIKE credithead.cred_date, 
		cred_text LIKE credithead.cred_text, 
		total_amt LIKE credithead.total_amt, 
		posted_flag LIKE credithead.posted_flag 
	END RECORD 
	DEFINE l_idx SMALLINT 
	#scrn SMALLINT,
	DEFINE l_query_text CHAR(700) 
	DEFINE l_where_text CHAR(300) 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	OPEN WINDOW A227 with FORM "A227" 
	CALL windecoration_a("A227") 

	CLEAR FORM 
	MESSAGE kandoomsg2("A",1001,"") #1001 " Enter Selection Criteria - ESC TO Continue"
	CONSTRUCT BY NAME l_where_text ON 
		cred_num, 
		cust_code, 
		cred_date, 
		cred_text, 
		total_amt, 
		posted_flag 


		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","A43_J","construct-qcred") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		CLOSE WINDOW A227 
		RETURN "" 
	END IF 
	MESSAGE kandoomsg2("A",1002,"") #1002 " Searching database - please wait"

	#-----------------------------
	# SELECT JMJ Quick Credits which have a cred_ind of 'X'
	#
	LET l_query_text = 
		"SELECT * FROM credithead ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND cred_ind = 'X' ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY credithead.cred_num, ", 
		" credithead.cust_code,", 
		" credithead.cred_date" 

	PREPARE s_credithead FROM l_query_text 
	DECLARE c_credithead CURSOR FOR s_credithead 
	LET l_idx = 0 

	FOREACH c_credithead INTO l_rec_credithead.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_credithead[l_idx].cred_num = l_rec_credithead.cred_num 
		LET l_arr_rec_credithead[l_idx].cust_code = l_rec_credithead.cust_code 
		LET l_arr_rec_credithead[l_idx].cred_date = l_rec_credithead.cred_date 
		LET l_arr_rec_credithead[l_idx].cred_text = l_rec_credithead.cred_text 
		LET l_arr_rec_credithead[l_idx].total_amt = l_rec_credithead.total_amt 
		LET l_arr_rec_credithead[l_idx].posted_flag = l_rec_credithead.posted_flag 
		IF l_idx = 100 THEN 
			ERROR kandoomsg2("A",9174,l_idx) 		#9174 First <VALUE> Credits selected only
			EXIT FOREACH 
		END IF 
	END FOREACH 

	IF l_idx = 0 THEN 
		ERROR kandoomsg2("E",9213,"")		#9213 No Credits satisfied criteria
--		LET l_idx = 1 
--		INITIALIZE l_arr_rec_credithead[1].* TO NULL 
	END IF 
	
	MESSAGE kandoomsg2("A",1008,"") #1008 F3/F4 TO page Fwd/Bwd - ESC TO Continue
	CALL set_count(l_idx) 

	INPUT ARRAY l_arr_rec_credithead WITHOUT DEFAULTS FROM sr_credithead.* ATTRIBUTE(UNBUFFERED) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A43_J","inp-arr-credithead-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			#LET scrn = scr_line()
			IF l_arr_rec_credithead[l_idx].cred_num IS NOT NULL THEN 
				#DISPLAY l_arr_rec_credithead[l_idx].*
				#     TO sr_credithead[scrn].*

			END IF 
			NEXT FIELD scroll_flag 

		AFTER FIELD scroll_flag 
			LET l_arr_rec_credithead[l_idx].scroll_flag = NULL 
			IF fgl_lastkey() = fgl_keyval("down") AND arr_curr() >= arr_count() THEN 
				ERROR kandoomsg2("A",9001,"") 
				NEXT FIELD scroll_flag 
			END IF 

		BEFORE FIELD cred_num 
			LET l_rec_credithead.cred_num = l_arr_rec_credithead[l_idx].cred_num 
			EXIT INPUT 
			#AFTER ROW
			#   DISPLAY l_arr_rec_credithead[l_idx].*
			#        TO sr_credithead[scrn].*

		AFTER INPUT 
			LET l_rec_credithead.cred_num = l_arr_rec_credithead[l_idx].cred_num 

	END INPUT 

	CLOSE WINDOW A227 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN "" 
	ELSE 
		RETURN l_rec_credithead.cred_num 
	END IF 
END FUNCTION 
################################################################
# END FUNCTION show_qcred()
################################################################


################################################################
# FUNCTION A43_creditdetl_update_line(l_rec_creditdetl)
#
# This FUNCTION updates a credit line item.
################################################################
FUNCTION A43_creditdetl_update_line(l_rec_creditdetl) 
	DEFINE l_rec_creditdetl RECORD LIKE creditdetl.* 

	LET l_rec_creditdetl.disc_amt = 0 
	LET l_rec_creditdetl.ser_ind = 'N' 
	LET l_rec_creditdetl.unit_tax_amt = 0 

	#UPDATE --------------------------------
	UPDATE t_creditdetl SET 
		line_num = l_rec_creditdetl.line_num, 
		part_code = l_rec_creditdetl.part_code, 
		ware_code = l_rec_creditdetl.ware_code, 
		cat_code = l_rec_creditdetl.cat_code, 
		prodgrp_code = l_rec_creditdetl.prodgrp_code, 
		maingrp_code = l_rec_creditdetl.maingrp_code, 
		uom_code = l_rec_creditdetl.uom_code, 
		unit_sales_amt = l_rec_creditdetl.unit_sales_amt, 
		received_qty = l_rec_creditdetl.received_qty, 
		tax_code = l_rec_creditdetl.tax_code, 
		level_code = l_rec_creditdetl.level_code, 
		unit_tax_amt = l_rec_creditdetl.unit_tax_amt, 
		ext_tax_amt = l_rec_creditdetl.unit_tax_amt	* l_rec_creditdetl.ship_qty, 
		unit_cost_amt = l_rec_creditdetl.unit_cost_amt, 
		ship_qty = l_rec_creditdetl.ship_qty, 
		line_text = l_rec_creditdetl.line_text, 
		ext_cost_amt = l_rec_creditdetl.unit_cost_amt	* l_rec_creditdetl.ship_qty, 
		ext_sales_amt = l_rec_creditdetl.unit_sales_amt	* l_rec_creditdetl.ship_qty, 
		line_total_amt = l_rec_creditdetl.ship_qty * ( l_rec_creditdetl.unit_tax_amt	+ l_rec_creditdetl.unit_sales_amt ), 
		line_acct_code = l_rec_creditdetl.line_acct_code 
		WHERE line_num = l_rec_creditdetl.line_num 
END FUNCTION 
################################################################
# END FUNCTION A43_creditdetl_update_line(l_rec_creditdetl)
################################################################


################################################################
# FUNCTION setup_acct_mask( l_mode_flag )
#
#
# This FUNCTION sets up the corrct acct mask in the
# credithead.acct_mask_code COLUMN.  This mask IS created by
#
#   1. Create a dummy mask made up of "?"'s
#   2. Overlay customer type mask TO replace any "?"'s
#   3. Overlay kandoouser type mask TO replace any "?"'s
#   IF arparms.show_seg = "Y" THEN OPEN WINDOW TO allow user
#   TO edit mask.
#
# The mask IS used TO overlay the creditdetl.line_acct_code so sales
# may be directed TO the other cost centres.
#
################################################################
FUNCTION setup_acct_mask( l_mode_flag ) 
	DEFINE l_rec_customertype RECORD LIKE customertype.* 
	--DEFINE glob_rec_kandoouser RECORD LIKE kandoouser.*  
	DEFINE l_mode_flag CHAR(4) 

	#
	# IF credit IS posted, account masking cannot be changed
	#
	IF l_mode_flag = MODE_CLASSIC_EDIT AND glob_rec_credithead.posted_flag = "Y" THEN 
		RETURN true 
	END IF 
	#
	# SELECT & setup customertype mask
	#
	IF glob_rec_credithead.org_cust_code IS NOT NULL THEN 
		LET l_rec_customertype.type_code = glob_rec_corpcust.type_code 
	ELSE 
		LET l_rec_customertype.type_code = glob_rec_customer.type_code 
	END IF 

	SELECT * INTO l_rec_customertype.* 
	FROM customertype 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND type_code = l_rec_customertype.type_code 

	IF length(l_rec_customertype.acct_mask_code) = 0 THEN 
		LET l_rec_customertype.acct_mask_code = build_mask(glob_rec_kandoouser.cmpy_code,"??????????????????"," ") 
	ELSE 
		## CALL build mask TO ensure customertype structure IS correct
		LET l_rec_customertype.acct_mask_code =	build_mask(glob_rec_kandoouser.cmpy_code,"??????????????????",l_rec_customertype.acct_mask_code) 
	END IF 
	#-----------
	## SELECT & setup user mask
	##

--	SELECT * INTO glob_rec_kandoouser.* 
--	FROM kandoouser 
--	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
--	AND sign_on_code = glob_rec_kandoouser.sign_on_code 
	IF length(glob_rec_kandoouser.acct_mask_code) = 0 THEN 
		LET glob_rec_kandoouser.acct_mask_code = 
		build_mask(glob_rec_kandoouser.cmpy_code,"??????????????????"," ") 
	ELSE 
		## CALL build mask TO ensure kandoouser structure IS correct
		LET glob_rec_kandoouser.acct_mask_code = 
		build_mask(glob_rec_kandoouser.cmpy_code,"??????????????????",	glob_rec_kandoouser.acct_mask_code) 
	END IF 

	#---------------------
	## Mask IS built by the following FUNCTION
	##
	LET glob_rec_credithead.acct_override_code = 
	build_mask(glob_rec_kandoouser.cmpy_code,glob_rec_credithead.acct_override_code, 	glob_rec_kandoouser.acct_mask_code) 

	#----------------------
	## IF configured TO do so - popup window TO allow edit of mask.
	##
	IF glob_rec_arparms.show_seg_flag = "Y" THEN 
		LET glob_rec_credithead.acct_override_code = 
		segment_fill(glob_rec_kandoouser.cmpy_code,glob_rec_credithead.acct_override_code, 	glob_rec_credithead.acct_override_code) 
	END IF 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

	#----------------
	# IF credit IS being edited, credit number cannot be changed
	#
	IF l_mode_flag = MODE_CLASSIC_EDIT THEN 
		RETURN true 
	END IF 
	IF NOT valid_trans_num(glob_rec_kandoouser.cmpy_code,TRAN_TYPE_CREDIT_CR,glob_rec_credithead.acct_override_code) THEN 
		ERROR kandoomsg2("A",9516,"") #9516 "Invalid numbering - Review Menu GZD"
		RETURN false 
	END IF 
	RETURN true 
END FUNCTION 
################################################################
# FUNCTION setup_acct_mask( l_mode_flag )
################################################################


################################################################
# FUNCTION write_credit( p_mode )
#
#
#  0.  Lock customer
#  1.  IF edit THEN
#  2.     - delete line items
#  3.     - UPDATE customer
#  4.     - INSERT audit
#  5.  END IF
#  6.  IF add THEN
#  7.    - get next credit number
#  8. END IF
#  9. INSERT line items
#  10. IF add THEN
#  11.    - INSERT header
#  12. ELSE
#  13.    - UPDATE header
#  14. END IF
#  15. UPDATE customer
#  16. INSERT audit
#
################################################################
FUNCTION write_credit(p_mode) 
	DEFINE p_mode CHAR(4) 
	DEFINE l_err_message CHAR(40)
	DEFINE l_rec_araudit RECORD LIKE araudit.*
	DEFINE l_rec_t_credithead RECORD LIKE credithead.*
	DEFINE l_rec_creditdetl RECORD LIKE creditdetl.*
	DEFINE l_rec_customer RECORD LIKE customer.* 

	#
	# Declare dynamic cursors
	#
	DECLARE c_t_creditdetl CURSOR FOR 
	SELECT * FROM t_creditdetl ORDER BY line_num 
	GOTO bypass 
	LABEL recovery: 
	IF error_recover(l_err_message, status) != "Y" THEN 
		EXIT PROGRAM 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 

		DECLARE c3_creditdetl CURSOR FOR 
		INSERT INTO creditdetl VALUES (l_rec_creditdetl.*) 
		OPEN c3_creditdetl 
		DECLARE c_customer CURSOR FOR 
		SELECT * FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = glob_rec_credithead.cust_code 
		FOR UPDATE 
		OPEN c_customer 
		FETCH c_customer INTO l_rec_customer.* 

		IF p_mode = MODE_CLASSIC_ADD THEN 
			LET l_err_message = "A43_J - Next credit number UPDATE" 
			LET glob_rec_credithead.cred_num = next_trans_num(glob_rec_kandoouser.cmpy_code,TRAN_TYPE_CREDIT_CR,glob_rec_credithead.acct_override_code) 
			IF glob_rec_credithead.cred_num < 0 THEN 
				LET status = glob_rec_credithead.cred_num 
				GOTO recovery 
			END IF 
		ELSE 
			#
			# Obtain existing credithead TO ensure no second edit OR
			# posting has occurred.
			#
			DECLARE c3_credithead CURSOR FOR 
			SELECT * FROM credithead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cred_num = glob_rec_credithead.cred_num 
			FOR UPDATE 
			OPEN c3_credithead 
			FETCH c3_credithead INTO l_rec_t_credithead.* 

			IF l_rec_t_credithead.rev_num != glob_rec_credithead.rev_num OR l_rec_t_credithead.posted_flag != glob_rec_credithead.posted_flag THEN 
				LET l_err_message = "A43_J - Attempt TO concurrently edit Credit" 
				GOTO recovery 
			END IF 

			LET glob_rec_credithead.posted_flag = l_rec_t_credithead.posted_flag 
			LET glob_rec_credithead.appl_amt = l_rec_t_credithead.appl_amt 
			LET glob_rec_credithead.rev_date = today 

			IF l_rec_t_credithead.rev_num IS NULL THEN 
				LET glob_rec_credithead.rev_num = 0 
			END IF 

			LET glob_rec_credithead.rev_num = glob_rec_credithead.rev_num + 1 
			LET l_err_message = "A43_J - Customer backout " 

			#----------------------------------
			# Delete the credit lines
			#
			LET l_err_message = "A43_J - Credit line deletion failed" 
			
			DELETE FROM creditdetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cred_num = glob_rec_credithead.cred_num 

			LET l_rec_customer.bal_amt = l_rec_customer.bal_amt	+ l_rec_t_credithead.total_amt 
			LET l_rec_customer.next_seq_num = l_rec_customer.next_seq_num + 1 
			INITIALIZE l_rec_araudit.* TO NULL 
			LET l_rec_araudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET l_rec_araudit.tran_date = today 
			LET l_rec_araudit.cust_code = glob_rec_credithead.cust_code 
			LET l_rec_araudit.seq_num = l_rec_customer.next_seq_num 
			LET l_rec_araudit.tran_type_ind = TRAN_TYPE_CREDIT_CR 
			LET l_rec_araudit.source_num = l_rec_t_credithead.cred_num 
			LET l_rec_araudit.tran_text = "Backout Credit" 
			LET l_rec_araudit.tran_amt = l_rec_t_credithead.total_amt 
			LET l_rec_araudit.entry_code = glob_rec_kandoouser.sign_on_code 
			LET l_rec_araudit.sales_code = l_rec_t_credithead.sale_code 
			LET l_rec_araudit.year_num = l_rec_t_credithead.year_num 
			LET l_rec_araudit.period_num = l_rec_t_credithead.period_num 
			LET l_rec_araudit.bal_amt = l_rec_customer.bal_amt 
			LET l_rec_araudit.currency_code = l_rec_customer.currency_code 
			LET l_rec_araudit.conv_qty = l_rec_t_credithead.conv_qty 
			LET l_rec_araudit.entry_date = today 
			LET l_err_message = "A43_J - Unable TO add TO AR log table " 

			INSERT INTO araudit VALUES (l_rec_araudit.*) 

			LET l_rec_customer.curr_amt = l_rec_customer.curr_amt + l_rec_t_credithead.total_amt 
			LET l_rec_customer.cred_bal_amt = l_rec_customer.cred_limit_amt - l_rec_customer.bal_amt 
			LET l_rec_customer.ytds_amt = l_rec_customer.ytds_amt + l_rec_t_credithead.total_amt 
			LET l_rec_customer.mtds_amt = l_rec_customer.mtds_amt + l_rec_t_credithead.total_amt 
		END IF 

		#-----------------------
		# INITIALIZE the sum-of-lines header fields
		#
		LET glob_rec_credithead.cost_amt = 0 
		LET glob_rec_credithead.tax_amt = 0 
		LET glob_rec_credithead.goods_amt = 0 
		LET glob_rec_credithead.line_num = 0 
		LET l_err_message = "A43_J - Credit line addition failed" 
		
		OPEN c_t_creditdetl 
		FOREACH c_t_creditdetl INTO l_rec_creditdetl.* 
			LET glob_rec_credithead.line_num = glob_rec_credithead.line_num + 1 
			LET l_rec_creditdetl.cmpy_code = glob_rec_credithead.cmpy_code 
			LET l_rec_creditdetl.cust_code = glob_rec_credithead.cust_code 
			LET l_rec_creditdetl.cred_num = glob_rec_credithead.cred_num 
			LET l_rec_creditdetl.line_num = glob_rec_credithead.line_num 

			IF l_rec_creditdetl.ext_tax_amt IS NULL THEN 
				LET l_rec_creditdetl.ext_tax_amt = 0 
			END IF 

			IF l_rec_creditdetl.ext_sales_amt IS NULL THEN 
				LET l_rec_creditdetl.ext_sales_amt = 0 
			END IF 

			IF l_rec_creditdetl.line_total_amt IS NULL THEN 
				LET l_rec_creditdetl.line_total_amt = 0 
			END IF 

			IF l_rec_creditdetl.ext_cost_amt IS NULL THEN 
				LET l_rec_creditdetl.ext_cost_amt = 0 
			END IF 

			LET l_rec_creditdetl.line_acct_code = account_patch(
				glob_rec_kandoouser.cmpy_code,l_rec_creditdetl.line_acct_code, glob_rec_credithead.acct_override_code) 
			PUT c3_creditdetl 

			LET glob_rec_credithead.cost_amt = glob_rec_credithead.cost_amt + l_rec_creditdetl.ext_cost_amt 
			LET glob_rec_credithead.tax_amt = glob_rec_credithead.tax_amt + l_rec_creditdetl.ext_tax_amt 
			LET glob_rec_credithead.goods_amt = glob_rec_credithead.goods_amt + l_rec_creditdetl.ext_sales_amt 
		END FOREACH 
		
		LET glob_rec_credithead.cost_ind = glob_rec_arparms.costings_ind 
		LET glob_rec_credithead.total_amt = glob_rec_credithead.tax_amt	+ glob_rec_credithead.goods_amt 

		#
		# Check that cerdit has NOT been edited TO less than amount
		# applied TO invoices
		#
		IF glob_rec_credithead.appl_amt > glob_rec_credithead.total_amt THEN 
			LET l_err_message = "A43 - Credit total less than amount applied" 
			GOTO recovery 
		END IF 

		IF p_mode = MODE_CLASSIC_EDIT THEN 
			UPDATE credithead SET * = glob_rec_credithead.* 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cred_num = glob_rec_credithead.cred_num 
		ELSE 
			LET l_err_message = "A43_J - Unable TO add TO credit header table" 
			INSERT INTO credithead VALUES (glob_rec_credithead.*) 
		END IF 

		#--------------------
		# Now TO UPDATE customer
		#
		LET l_rec_customer.next_seq_num = l_rec_customer.next_seq_num + 1 
		LET l_rec_customer.bal_amt = l_rec_customer.bal_amt - glob_rec_credithead.total_amt 
		LET l_rec_customer.curr_amt = l_rec_customer.curr_amt - glob_rec_credithead.total_amt 
		LET l_err_message = "A43_J - Unable TO add TO AR log table " 

		INITIALIZE l_rec_araudit.* TO NULL 
		
		LET l_rec_araudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_rec_araudit.tran_date = glob_rec_credithead.cred_date 
		LET l_rec_araudit.cust_code = glob_rec_credithead.cust_code 
		LET l_rec_araudit.seq_num = l_rec_customer.next_seq_num 
		LET l_rec_araudit.tran_type_ind = TRAN_TYPE_CREDIT_CR 
		LET l_rec_araudit.source_num = glob_rec_credithead.cred_num 
		LET l_rec_araudit.tran_text = "Enter Credit" 
		LET l_rec_araudit.tran_amt = 0 - glob_rec_credithead.total_amt 
		LET l_rec_araudit.entry_code = glob_rec_kandoouser.sign_on_code 
		LET l_rec_araudit.sales_code = glob_rec_credithead.sale_code 
		LET l_rec_araudit.year_num = glob_rec_credithead.year_num 
		LET l_rec_araudit.period_num = glob_rec_credithead.period_num 
		LET l_rec_araudit.bal_amt = l_rec_customer.bal_amt 
		LET l_rec_araudit.currency_code = l_rec_customer.currency_code 
		LET l_rec_araudit.conv_qty = glob_rec_credithead.conv_qty 
		LET l_rec_araudit.entry_date = today 
		
		INSERT INTO araudit VALUES (l_rec_araudit.*) 
		LET l_rec_customer.cred_bal_amt = 
			l_rec_customer.cred_limit_amt 
			- l_rec_customer.bal_amt 
			- l_rec_customer.onorder_amt 
		
		LET l_rec_customer.ytds_amt = l_rec_customer.ytds_amt	- glob_rec_credithead.total_amt 
		LET l_rec_customer.mtds_amt = l_rec_customer.mtds_amt	- glob_rec_credithead.total_amt 
		LET l_err_message = "A43_J - Customer actual UPDATE "
		 
		UPDATE customer 
		SET next_seq_num = 
			l_rec_customer.next_seq_num, 
			bal_amt = l_rec_customer.bal_amt, 
			curr_amt = l_rec_customer.curr_amt, 
			highest_bal_amt = l_rec_customer.highest_bal_amt, 
			cred_bal_amt = l_rec_customer.cred_bal_amt, 
			ytds_amt = l_rec_customer.ytds_amt, 
			mtds_amt = l_rec_customer.mtds_amt 
		WHERE current of c_customer

	COMMIT WORK 
	
	RETURN glob_rec_credithead.cred_num 
END FUNCTION 
################################################################
# END FUNCTION write_credit( p_mode )
################################################################