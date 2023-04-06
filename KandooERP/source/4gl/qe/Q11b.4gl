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
GLOBALS "../qe/Q_QE_GLOBALS.4gl"
GLOBALS "../qe/Q1_GROUP_GLOBALS.4gl" 
GLOBALS "../qe/Q11_GLOBALS.4gl" 
# \brief module Q11b



FUNCTION pay_detail() 
	DEFINE 
	pr_condsale RECORD LIKE condsale.*, 
	pr_term RECORD LIKE term.*, 
	pr_tax RECORD LIKE tax.* 

	IF pr_quotehead.cond_code IS NOT NULL THEN 
		SELECT desc_text 
		INTO pr_condsale.desc_text 
		FROM condsale 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cond_code = pr_quotehead.cond_code 
		IF sqlca.sqlcode = notfound THEN 
			LET msgresp = kandoomsg("E",9055,"") 
			#9055 Sales Condition does NOT exist - Try Window"
			LET pr_globals.paydetl_flag = "Y" 
			LET pr_condsale.desc_text = "**********" 
		END IF 
	END IF 
	SELECT desc_text 
	INTO pr_term.desc_text 
	FROM term 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND term_code = pr_quotehead.term_code 
	IF sqlca.sqlcode = notfound THEN 
		LET msgresp=kandoomsg("E",9056,"") 
		#9056" Payment Terms do NOT exist - try window"
		LET pr_globals.paydetl_flag = "Y" 
		LET pr_term.desc_text = "**********" 
	END IF 
	SELECT * INTO pr_tax.* 
	FROM tax 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tax_code = pr_quotehead.tax_code 
	IF sqlca.sqlcode = notfound THEN 
		LET msgresp=kandoomsg("E",9057,"") 
		#9057" Taxation Code do NOT exist "
		LET pr_globals.paydetl_flag = "Y" 
		LET pr_tax.desc_text = "**********" 
	END IF 
	IF pr_quotehead.conv_qty IS NULL OR pr_quotehead.conv_qty = 0 THEN 
		LET pr_quotehead.conv_qty =	get_conv_rate(
			glob_rec_kandoouser.cmpy_code,
			pr_quotehead.currency_code, 
			pr_quotehead.quote_date,
			CASH_EXCHANGE_SELL) 
	END IF 
	
	IF pr_globals.paydetl_flag = "Y" THEN 
		OPEN WINDOW q212 with FORM "Q212" -- alch kd-747 
		CALL windecoration_q("Q212") -- alch kd-747 
		LET msgresp=kandoomsg("E",1016,"") 	#1016 Enter Payment Details - F8 Customer Inquiry - F9 Credit Details
		
		DISPLAY pr_condsale.desc_text, 
		pr_term.desc_text, 
		pr_tax.desc_text 
		TO condsale.desc_text, 
		term.desc_text, 
		tax.desc_text 

		DISPLAY BY NAME pr_quotehead.currency_code	attribute(green) 
		INPUT BY NAME 
			pr_quotehead.cond_code, 
			pr_quotehead.term_code, 
			pr_quotehead.tax_code, 
			pr_quotehead.conv_qty 
		WITHOUT DEFAULTS 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","Q11b","inp-cond_code-1") -- alch kd-501 
			ON ACTION "WEB-HELP" -- albo kd-369 
				CALL onlinehelp(getmoduleid(),null) 
			ON KEY (control-b) 
				CASE 
					WHEN infield(cond_code) 
						LET pr_temp_text = show_cond(glob_rec_kandoouser.cmpy_code,"") 
						IF pr_temp_text IS NOT NULL THEN 
							LET pr_quotehead.cond_code = pr_temp_text 
						END IF 
						NEXT FIELD cond_code 
					WHEN infield(term_code) 
						LET pr_temp_text = show_term(glob_rec_kandoouser.cmpy_code) 
						IF pr_temp_text IS NOT NULL THEN 
							LET pr_quotehead.term_code = pr_temp_text 
						END IF 
						NEXT FIELD term_code 
					WHEN infield(tax_code) 
						LET pr_temp_text = show_tax(glob_rec_kandoouser.cmpy_code) 
						IF pr_temp_text IS NOT NULL THEN 
							LET pr_quotehead.tax_code = pr_temp_text 
						END IF 
						NEXT FIELD tax_code 
				END CASE 

			ON KEY (F8) --customer details / customer invoice submenu 
				CALL cinq_clnt(glob_rec_kandoouser.cmpy_code,pr_quotehead.cust_code) --customer details / customer invoice submenu 

			ON KEY (F9) 
				CALL view_cust(pr_quotehead.cust_code) 

			AFTER FIELD cond_code 
				CLEAR condsale.desc_text 
				IF pr_quotehead.cond_code IS NULL THEN 
					IF pr_customer.cond_code IS NOT NULL THEN 
						LET msgresp=kandoomsg("E",8011,"") 
						#8011 Condition NOT Entered. Use Cust's Condition.Y/N
						IF msgresp = "Y" THEN 
							LET pr_quotehead.cond_code = pr_customer.cond_code 
							NEXT FIELD cond_code 
						END IF 
					END IF 
				ELSE 
					SELECT desc_text 
					INTO pr_condsale.desc_text 
					FROM condsale 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cond_code = pr_quotehead.cond_code 
					IF sqlca.sqlcode = notfound THEN 
						LET msgresp=kandoomsg("E",9055,"") 
						#9055" Sales cond do NOT exist "
						NEXT FIELD cond_code 
					ELSE 
						DISPLAY pr_condsale.desc_text 
						TO condsale.desc_text 

						IF pr_customer.inv_level_ind != "L" THEN 
							LET msgresp=kandoomsg("E",7031,"") 
							#7031 Warning: In Nominating a sales condition customer
							#              prices will NOT be AT normal pricing level
						END IF 
					END IF 
				END IF 
			AFTER FIELD term_code 
				CLEAR term.desc_text 
				IF pr_quotehead.term_code IS NULL THEN 
					LET msgresp=kandoomsg("E",9058,"") 
					#9058" Payment Term must be Entered"
					LET pr_quotehead.term_code = pr_customer.term_code 
					NEXT FIELD term_code 
				ELSE 
					SELECT * INTO pr_term.* 
					FROM term 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND term_code = pr_quotehead.term_code 
					IF sqlca.sqlcode = notfound THEN 
						LET msgresp=kandoomsg("E",9056,"") 
						#9056" Sales Conditions does NOT exist "
						NEXT FIELD term_code 
					ELSE 
						DISPLAY pr_term.desc_text 
						TO term.desc_text 

					END IF 
				END IF 
			AFTER FIELD tax_code 
				CLEAR tax.desc_text 
				IF pr_quotehead.tax_code IS NULL THEN 
					LET msgresp=kandoomsg("E",9059,"") 
					#9059" Taxation Code must be Entered"
					LET pr_quotehead.tax_code = pr_customer.tax_code 
					NEXT FIELD tax_code 
				ELSE 
					SELECT * INTO pr_tax.* 
					FROM tax 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND tax_code = pr_quotehead.tax_code 
					IF sqlca.sqlcode = notfound THEN 
						LET msgresp=kandoomsg("E",9057,"") 
						#9057" Taxation Code do NOT exist "
						NEXT FIELD tax_code 
					ELSE 
						DISPLAY pr_tax.desc_text 
						TO tax.desc_text 

					END IF 
				END IF 
			BEFORE FIELD conv_qty 
				IF pr_globals.base_curr_code = pr_quotehead.currency_code THEN 
					LET pr_quotehead.conv_qty = 1.0 
					DISPLAY BY NAME pr_quotehead.conv_qty 

				END IF 
			AFTER FIELD conv_qty 
				IF pr_quotehead.conv_qty IS NULL OR pr_quotehead.conv_qty = 0 THEN 
					LET msgresp=kandoomsg("E",9060,"") 
					#9060" Currency Exchange Rate must have a value "
					LET pr_quotehead.conv_qty = 
					get_conv_rate(glob_rec_kandoouser.cmpy_code,pr_quotehead.currency_code, 
					pr_quotehead.quote_date,CASH_EXCHANGE_SELL) 
					NEXT FIELD conv_qty 
				END IF 
				IF pr_quotehead.conv_qty < 0 THEN 
					LET msgresp=kandoomsg("E",9061,"") 
					#9061 " Exchange Rate must be greater than zero "
					NEXT FIELD conv_qty 
				END IF 
				IF pr_quotehead.conv_qty != 
				get_conv_rate(glob_rec_kandoouser.cmpy_code,pr_quotehead.currency_code, 
				pr_quotehead.quote_date,CASH_EXCHANGE_SELL) THEN 
					LET msgresp = kandoomsg("E",8012,"") 
					#8012 Exchange Rate IS NOT current. Do you wish TO Update.Y/N
					IF msgresp = "Y" THEN 
						LET pr_quotehead.conv_qty = 
						get_conv_rate(glob_rec_kandoouser.cmpy_code,pr_quotehead.currency_code, 
						pr_quotehead.quote_date,CASH_EXCHANGE_SELL) 
						NEXT FIELD conv_qty 
					END IF 
				END IF 
				
			AFTER INPUT 
				IF not(int_flag OR quit_flag) THEN 
					SELECT unique 1 FROM term 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND term_code = pr_quotehead.term_code 
					IF sqlca.sqlcode = notfound THEN 
						LET msgresp=kandoomsg("E",9056,"") 
						#9056 Payment Terms do NOT exist try window
						NEXT FIELD term_code 
					END IF 
					SELECT * INTO pr_tax.* FROM tax 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND tax_code = pr_quotehead.tax_code 
					IF sqlca.sqlcode = notfound THEN 
						LET msgresp=kandoomsg("E",9057,"") 
						#9057" Taxation Code do NOT exist "
						NEXT FIELD tax_code 
					ELSE 
						IF pr_tax.calc_method_flag = "X" THEN 
							IF (pr_customer.last_mail_date < pr_quotehead.quote_date) 
							OR (pr_customer.last_mail_date IS null) 
							OR (pr_customer.tax_num_text IS null) THEN 
								IF pr_quotehead.tax_cert_text IS NULL THEN 
									LET pr_quotehead.tax_cert_text = enter_exempt_num(glob_rec_kandoouser.cmpy_code, 
									pr_quotehead.tax_code, 
									pr_customer.tax_num_text) 
								ELSE 
									LET pr_quotehead.tax_cert_text = enter_exempt_num(glob_rec_kandoouser.cmpy_code, 
									pr_quotehead.tax_code, 
									pr_quotehead.tax_cert_text) 
								END IF 
							END IF 
						END IF 
					END IF 
				END IF 
			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 
		CLOSE WINDOW q212 
	END IF 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 
