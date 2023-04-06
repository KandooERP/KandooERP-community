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
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/A5_GROUP_GLOBALS.4gl"
GLOBALS "../ar/A53_GLOBALS.4gl" 
############################################################
# MAIN
#
# Cash Flow Analysis
############################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("A53") 
	CALL ui_init(0) 

	DEFER interrupt 
	DEFER quit 
	CALL authenticate(getmoduleid()) 
	CALL init_a_ar() #init a/ar module 

	OPEN WINDOW A685 with FORM "A685" 
	CALL windecoration_a("A685") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	WHILE get_priority() 
		CALL calculate_cash_flow() 
	END WHILE 
	CLOSE WINDOW A685 
END MAIN 


############################################################
# FUNCTION get_priority() 
#
#
############################################################
FUNCTION get_priority() 
	DEFINE l_pro_date SMALLINT 
	DEFINE l_analysis  SMALLINT 
	DEFINE l_due_date SMALLINT 

	MESSAGE kandoomsg2("U",1020,"Priority") #1020 Enter Priority Details; OK TO Continue
	LET l_pro_date = 1 
	LET l_analysis = 2 
	LET l_due_date = 3 
	LET glob_priority1 = 1 
	LET glob_priority2 = 2 
	LET glob_priority3 = 3 

	INPUT 
		l_pro_date, 
		l_analysis, 
		l_due_date WITHOUT DEFAULTS 
	FROM
		pro_date, 
		analysis, 
		due_date
	
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A53","inp-analysis") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
			
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD pro_date 
			CASE l_pro_date 
				WHEN 1 
					LET glob_priority1 = 1 
				WHEN 2 
					LET glob_priority2 = 1 
				WHEN 3 
					LET glob_priority3 = 1 
			END CASE 
			
		AFTER FIELD analysis 
			CASE l_analysis 
				WHEN 1 
					LET glob_priority1 = 2 
				WHEN 2 
					LET glob_priority2 = 2 
				WHEN 3 
					LET glob_priority3 = 2 
			END CASE 
			
		AFTER FIELD due_date 
			CASE l_due_date 
				WHEN 1 
					LET glob_priority1 = 3 
				WHEN 2 
					LET glob_priority2 = 3 
				WHEN 3 
					LET glob_priority3 = 3 
			END CASE
			 
		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF l_pro_date = l_analysis THEN 
					ERROR kandoomsg2("A",9522,"") 					#9522 Each option must have a different priority (1,2,3)
					NEXT FIELD pro_date 
				END IF 
				IF l_pro_date = l_due_date THEN 
					ERROR kandoomsg2("A",9522,"") 					#9522 Each option must have a different priority (1,2,3)
					NEXT FIELD pro_date 
				END IF 
				IF l_analysis = l_due_date THEN 
					ERROR kandoomsg2("A",9522,"") 					#9522 Each option must have a different priority (1,2,3)
					NEXT FIELD analysis 
				END IF 
			END IF 

	END INPUT 
	
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	
	RETURN true 
END FUNCTION 

############################################################
# FUNCTION calculate_cash_flow()
#
#
############################################################
FUNCTION calculate_cash_flow() 
	DEFINE l_rec_temp RECORD 
		tm_amount DECIMAL(14,2), 
		tm_dis DECIMAL(14,2), 
		tm_unpaid DECIMAL(14,2), 
		tm_past DECIMAL(14,2), 
		tm_ipast INTEGER, 
		tm_1t7 DECIMAL(14,2), 
		tm_i1t7 INTEGER, 
		tm_8t14 DECIMAL(14,2), 
		tm_i8t14 INTEGER, 
		tm_15t21 DECIMAL(14,2), 
		tm_i15t21 INTEGER, 
		tm_22t28 DECIMAL(14,2), 
		tm_i22t28 INTEGER, 
		tm_29t35 DECIMAL(14,2), 
		tm_i29t35 INTEGER, 
		tm_36t42 DECIMAL(14,2), 
		tm_i36t42 INTEGER, 
		tm_43t49 DECIMAL(14,2), 
		tm_i43t49 INTEGER, 
		tm_50t56 DECIMAL(14,2), 
		tm_i50t56 INTEGER, 
		tm_plus DECIMAL(14,2), 
		tm_iplus INTEGER 
	END RECORD
	DEFINE l_setup_date1 DATE
	DEFINE l_setup_date2 DATE
	DEFINE l_setup_date3 DATE
	DEFINE l_setup_date4 DATE
	DEFINE l_setup_date5 DATE
	DEFINE l_setup_date6 DATE
	DEFINE l_setup_date7 DATE
	DEFINE l_setup_date8 DATE
	DEFINE l_setup_date9 DATE
	DEFINE l_setup_date10 DATE
	DEFINE l_setup_date11 DATE
	DEFINE l_setup_date12 DATE
	DEFINE l_setup_date13 DATE
	DEFINE l_setup_date14 DATE
	DEFINE l_setup_date15 DATE
	DEFINE l_setup_date16 DATE
	DEFINE l_setup_date17 DATE
	DEFINE l_setup_date18 DATE
	DEFINE l_invoice_total DECIMAL(14,2) 
	DEFINE l_credit_total DECIMAL(14,2) 
	DEFINE l_cash_total DECIMAL(14,2) 
	 
	DEFINE l_outstanding_total DECIMAL(14,2)
	DEFINE l_unpaid_amt DECIMAL(14,2)
	 
	--DEFINE globm_invoicehead RECORD LIKE invoicehead.*
	DEFINE l_rec_customer RECORD LIKE customer.*
	DEFINE l_rec_credithead RECORD LIKE credithead.*
	DEFINE l_rec_cashreceipt RECORD LIKE cashreceipt.*
	DEFINE l_currency_code LIKE currency.currency_code 
	DEFINE l_t_priority1 SMALLINT
	DEFINE l_t_priority2 SMALLINT	 
	DEFINE l_t_priority3 SMALLINT	
	DEFINE l_adjusted_days INTEGER 

	MESSAGE kandoomsg2("U",1002,"") 	#1002 Searching Database; Please Wait.
	LET l_invoice_total = 0 
	LET l_credit_total = 0 
	LET l_cash_total = 0 
	# initialise totals
	LET l_rec_temp.tm_amount = 0 
	LET l_rec_temp.tm_dis = 0 
	LET l_rec_temp.tm_unpaid = 0 
	LET l_rec_temp.tm_past = 0 
	LET l_rec_temp.tm_ipast = 0 
	LET l_rec_temp.tm_1t7 = 0 
	LET l_rec_temp.tm_i1t7 = 0 
	LET l_rec_temp.tm_8t14 = 0 
	LET l_rec_temp.tm_i8t14 = 0 
	LET l_rec_temp.tm_15t21 = 0 
	LET l_rec_temp.tm_i15t21 = 0 
	LET l_rec_temp.tm_22t28 = 0 
	LET l_rec_temp.tm_i22t28 = 0 
	LET l_rec_temp.tm_29t35 = 0 
	LET l_rec_temp.tm_i29t35 = 0 
	LET l_rec_temp.tm_36t42 = 0 
	LET l_rec_temp.tm_i36t42 = 0 
	LET l_rec_temp.tm_43t49 = 0 
	LET l_rec_temp.tm_i43t49 = 0 
	LET l_rec_temp.tm_50t56 = 0 
	LET l_rec_temp.tm_i50t56 = 0 
	LET l_rec_temp.tm_plus = 0 
	LET l_rec_temp.tm_iplus = 0 
	
--	OPEN WINDOW w1 with FORM "U999" 
--	CALL windecoration_u("U999") 
	
	DECLARE c_cashreceipt CURSOR FOR 
	SELECT * FROM cashreceipt 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cash_amt != applied_amt 
	
	FOREACH c_cashreceipt INTO l_rec_cashreceipt.* 
		--DISPLAY " " at 1,14 
		--DISPLAY "Cash Receipt: ", l_rec_cashreceipt.cash_num at 1,3 
		MESSAGE "Cash Receipt: ", l_rec_cashreceipt.cash_num 
		LET l_unpaid_amt = l_rec_cashreceipt.cash_amt - l_rec_cashreceipt.applied_amt 
		
		SELECT currency_code INTO l_currency_code FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = l_rec_cashreceipt.cust_code 
		
		CALL conv_currency(l_unpaid_amt, glob_rec_kandoouser.cmpy_code, 
		l_currency_code, "F", today, "S") 
		RETURNING l_unpaid_amt 
		
		LET l_cash_total = l_cash_total + l_unpaid_amt 
		LET l_adjusted_days = l_rec_cashreceipt.cash_date - today 
		IF l_adjusted_days > 56 THEN 
			LET l_rec_temp.tm_plus = l_rec_temp.tm_plus - l_unpaid_amt 
		ELSE 
			IF l_adjusted_days > 49 THEN 
				LET l_rec_temp.tm_50t56 = l_rec_temp.tm_50t56 - l_unpaid_amt 
			ELSE 
				IF l_adjusted_days > 42 THEN 
					LET l_rec_temp.tm_43t49 = l_rec_temp.tm_43t49 - l_unpaid_amt 
				ELSE 
					IF l_adjusted_days > 35 THEN 
						LET l_rec_temp.tm_36t42 = l_rec_temp.tm_36t42 - l_unpaid_amt 
					ELSE 
						IF l_adjusted_days > 28 THEN 
							LET l_rec_temp.tm_29t35 = l_rec_temp.tm_29t35 - l_unpaid_amt 
						ELSE 
							IF l_adjusted_days > 21 THEN 
								LET l_rec_temp.tm_22t28 = l_rec_temp.tm_22t28 - l_unpaid_amt 
							ELSE 
								IF l_adjusted_days > 14 THEN 
									LET l_rec_temp.tm_15t21 = l_rec_temp.tm_15t21 - l_unpaid_amt 
								ELSE 
									IF l_adjusted_days > 7 THEN 
										LET l_rec_temp.tm_8t14 = l_rec_temp.tm_8t14 - l_unpaid_amt 
									ELSE 
										IF l_adjusted_days > 0 THEN 
											LET l_rec_temp.tm_1t7 = l_rec_temp.tm_1t7 - l_unpaid_amt 
										ELSE 
											LET l_rec_temp.tm_past = l_rec_temp.tm_past - l_unpaid_amt 
										END IF 
									END IF 
								END IF 
							END IF 
						END IF 
					END IF 
				END IF 
			END IF 
		END IF 
		IF int_flag OR quit_flag THEN 
			IF kandoomsg("U",8023,"") = "N" THEN 
				#8023 Continue Processing
				LET int_flag = false 
				LET quit_flag = false 
--				CLOSE WINDOW w1 
				RETURN 
			END IF 
		END IF 
	END FOREACH 
	
	DECLARE c_credithead CURSOR FOR 
	SELECT * FROM credithead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND total_amt != appl_amt 
	
	FOREACH c_credithead INTO l_rec_credithead.* 
		--DISPLAY " " at 1,9 
		MESSAGE "Credit: ", l_rec_credithead.cred_num  
		--DISPLAY "Credit: ", l_rec_credithead.cred_num at 1,3
		LET l_unpaid_amt = l_rec_credithead.total_amt - l_rec_credithead.appl_amt 
		SELECT currency_code INTO l_currency_code FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = l_rec_credithead.cust_code 
		
		CALL conv_currency(l_unpaid_amt, glob_rec_kandoouser.cmpy_code, 
		l_currency_code, "F", today, "S") 
		RETURNING l_unpaid_amt 
		
		LET l_credit_total = l_credit_total + l_unpaid_amt 
		LET l_adjusted_days = l_rec_credithead.cred_date - today 
		IF l_adjusted_days > 56 THEN 
			LET l_rec_temp.tm_plus = l_rec_temp.tm_plus - l_unpaid_amt 
		ELSE 
			IF l_adjusted_days > 49 THEN 
				LET l_rec_temp.tm_50t56 = l_rec_temp.tm_50t56 - l_unpaid_amt 
			ELSE 
				IF l_adjusted_days > 42 THEN 
					LET l_rec_temp.tm_43t49 = l_rec_temp.tm_43t49 - l_unpaid_amt 
				ELSE 
					IF l_adjusted_days > 35 THEN 
						LET l_rec_temp.tm_36t42 = l_rec_temp.tm_36t42 - l_unpaid_amt 
					ELSE 
						IF l_adjusted_days > 28 THEN 
							LET l_rec_temp.tm_29t35 = l_rec_temp.tm_29t35 - l_unpaid_amt 
						ELSE 
							IF l_adjusted_days > 21 THEN 
								LET l_rec_temp.tm_22t28 = l_rec_temp.tm_22t28 - l_unpaid_amt 
							ELSE 
								IF l_adjusted_days > 14 THEN 
									LET l_rec_temp.tm_15t21 = l_rec_temp.tm_15t21 - l_unpaid_amt 
								ELSE 
									IF l_adjusted_days > 7 THEN 
										LET l_rec_temp.tm_8t14 = l_rec_temp.tm_8t14 - l_unpaid_amt 
									ELSE 
										IF l_adjusted_days > 0 THEN 
											LET l_rec_temp.tm_1t7 = l_rec_temp.tm_1t7 - l_unpaid_amt 
										ELSE 
											LET l_rec_temp.tm_past = l_rec_temp.tm_past - l_unpaid_amt 
										END IF 
									END IF 
								END IF 
							END IF 
						END IF 
					END IF 
				END IF 
			END IF 
		END IF 
		
		IF int_flag OR quit_flag THEN 
			IF kandoomsg("U",8023,"") = "N" THEN 
				#8023 Continue Processing
				LET int_flag = false 
				LET quit_flag = false 
--				CLOSE WINDOW w1 
				RETURN 
			END IF 
		END IF 
	END FOREACH 
	
	DECLARE c_invoicehead CURSOR FOR 
	SELECT * FROM invoicehead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND total_amt != paid_amt 
	FOREACH c_invoicehead INTO glob_rec_invoicehead.* 
		CALL db_customer_get_rec(UI_OFF,glob_rec_invoicehead.cust_code) RETURNING l_rec_customer.*	
--		SELECT * INTO l_rec_customer.* FROM customer 
--		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
--		AND cust_code = glob_rec_invoicehead.cust_code
 
--		DISPLAY " " at 1,9 
		MESSAGE "Invoice: ", glob_rec_invoicehead.inv_num
--		DISPLAY "Invoice: ", glob_rec_invoicehead.inv_num at 1,3 

		LET l_t_priority1 = glob_priority1 
		LET l_t_priority2 = glob_priority2 
		LET l_t_priority3 = glob_priority3 
		
		LET l_unpaid_amt = glob_rec_invoicehead.total_amt - glob_rec_invoicehead.paid_amt 
		SELECT currency_code INTO l_currency_code FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = glob_rec_invoicehead.cust_code 
		CALL conv_currency(l_unpaid_amt, glob_rec_kandoouser.cmpy_code, 
		l_currency_code, "F", today, "S") 
		RETURNING l_unpaid_amt 
		LET l_invoice_total = l_invoice_total + l_unpaid_amt 
		LABEL again: 
		IF l_t_priority1 = 1 
		AND glob_rec_invoicehead.expected_date IS NULL THEN 
			LET l_t_priority1 = l_t_priority2 
			LET l_t_priority2 = l_t_priority3 
		ELSE 
			LET l_adjusted_days = glob_rec_invoicehead.expected_date - today 
		END IF 
		IF (l_t_priority1 = 2 
		AND (l_rec_customer.cred_given_num = 0 
		OR l_rec_customer.cred_given_num IS null)) THEN 
			LET l_t_priority1 = l_t_priority2 
			LET l_t_priority2 = l_t_priority3 
			GOTO again 
		END IF 
		IF l_t_priority1 = 2 THEN 
			LET l_adjusted_days = ((glob_rec_invoicehead.inv_date 
			+ ((l_rec_customer.cred_taken_num 
			/ l_rec_customer.cred_given_num) 
			* (glob_rec_invoicehead.due_date 
			- glob_rec_invoicehead.inv_date)))-today) 
		END IF 
		IF l_t_priority1 = 3 THEN 
			LET l_adjusted_days = glob_rec_invoicehead.due_date - today 
		END IF 
		IF l_adjusted_days > 56 THEN 
			LET l_rec_temp.tm_plus = l_rec_temp.tm_plus + l_unpaid_amt 
			LET l_rec_temp.tm_iplus = l_rec_temp.tm_iplus + 1 
		ELSE 
			IF l_adjusted_days > 49 THEN 
				LET l_rec_temp.tm_50t56 = l_rec_temp.tm_50t56 + l_unpaid_amt 
				LET l_rec_temp.tm_i50t56 = l_rec_temp.tm_i50t56 + 1 
			ELSE 
				IF l_adjusted_days > 42 THEN 
					LET l_rec_temp.tm_43t49 = l_rec_temp.tm_43t49 + l_unpaid_amt 
					LET l_rec_temp.tm_i43t49 = l_rec_temp.tm_i43t49 + 1 
				ELSE 
					IF l_adjusted_days > 35 THEN 
						LET l_rec_temp.tm_36t42 = l_rec_temp.tm_36t42 + l_unpaid_amt 
						LET l_rec_temp.tm_i36t42 = l_rec_temp.tm_i36t42 + 1 
					ELSE 
						IF l_adjusted_days > 28 THEN 
							LET l_rec_temp.tm_29t35 = l_rec_temp.tm_29t35 + l_unpaid_amt 
							LET l_rec_temp.tm_i29t35 = l_rec_temp.tm_i29t35 + 1 
						ELSE 
							IF l_adjusted_days > 21 THEN 
								LET l_rec_temp.tm_22t28 = l_rec_temp.tm_22t28 + l_unpaid_amt 
								LET l_rec_temp.tm_i22t28 = l_rec_temp.tm_i22t28 + 1 
							ELSE 
								IF l_adjusted_days > 14 THEN 
									LET l_rec_temp.tm_15t21 = l_rec_temp.tm_15t21	+ l_unpaid_amt 
									LET l_rec_temp.tm_i15t21 = l_rec_temp.tm_i15t21 + 1 
								ELSE 
									IF l_adjusted_days > 7 THEN 
										LET l_rec_temp.tm_8t14 = l_rec_temp.tm_8t14	+ l_unpaid_amt 
										LET l_rec_temp.tm_i8t14 = l_rec_temp.tm_i8t14 + 1 
									ELSE 
										IF l_adjusted_days > 0 THEN 
											LET l_rec_temp.tm_1t7 = l_rec_temp.tm_1t7 + l_unpaid_amt 
											LET l_rec_temp.tm_i1t7 = l_rec_temp.tm_i1t7 + 1 
										ELSE 
											LET l_rec_temp.tm_past = l_rec_temp.tm_past + l_unpaid_amt 
											LET l_rec_temp.tm_ipast = l_rec_temp.tm_ipast + 1 
										END IF 
									END IF 
								END IF 
							END IF 
						END IF 
					END IF 
				END IF 
			END IF 
		END IF 
		IF int_flag OR quit_flag THEN 
			IF kandoomsg("U",8023,"") = "N" THEN 
				#8023 Continue Processing
				LET int_flag = false 
				LET quit_flag = false 
--				CLOSE WINDOW w1 
				RETURN 
			END IF 
		END IF 
	END FOREACH 
	
--	CLOSE WINDOW w1
	 
	OPEN WINDOW A686 with FORM "A686" 
	CALL windecoration_a("A686") 

	LET l_setup_date1 = today 
	LET l_setup_date2 = today + 1 
	LET l_setup_date3 = today + 7 
	LET l_setup_date4 = today + 8 
	LET l_setup_date5 = today + 14 
	LET l_setup_date6 = today + 15 
	LET l_setup_date7 = today + 21 
	LET l_setup_date8 = today + 22 
	LET l_setup_date9 = today + 28 
	LET l_setup_date10 = today + 29 
	LET l_setup_date11 = today + 35 
	LET l_setup_date12 = today + 36 
	LET l_setup_date13 = today + 42 
	LET l_setup_date14 = today + 43 
	LET l_setup_date15 = today + 49 
	LET l_setup_date16 = today + 50 
	LET l_setup_date17 = today + 56 
	LET l_setup_date18 = today + 57
	 
	DISPLAY l_setup_date1, 
	l_setup_date2, 
	l_setup_date3, 
	l_setup_date4, 
	l_setup_date5, 
	l_setup_date6, 
	l_setup_date7, 
	l_setup_date8, 
	l_setup_date9, 
	l_setup_date10, 
	l_setup_date11, 
	l_setup_date12, 
	l_setup_date13, 
	l_setup_date14, 
	l_setup_date15, 
	l_setup_date16, 
	l_setup_date17, 
	l_setup_date18 
	TO
	setup_date1, 
	setup_date2, 
	setup_date3, 
	setup_date4, 
	setup_date5, 
	setup_date6, 
	setup_date7, 
	setup_date8, 
	setup_date9, 
	setup_date10, 
	setup_date11, 
	setup_date12, 
	setup_date13, 
	setup_date14, 
	setup_date15, 
	setup_date16, 
	setup_date17, 
	setup_date18 
	
	LET l_outstanding_total = l_invoice_total - (l_credit_total + l_cash_total) 
	DISPLAY BY NAME l_rec_temp.tm_past, 
	l_rec_temp.tm_1t7, 
	l_rec_temp.tm_8t14, 
	l_rec_temp.tm_15t21, 
	l_rec_temp.tm_22t28, 
	l_rec_temp.tm_29t35, 
	l_rec_temp.tm_36t42, 
	l_rec_temp.tm_43t49, 
	l_rec_temp.tm_50t56, 
	l_rec_temp.tm_plus 
	
	DISPLAY l_outstanding_total TO outstanding_total
	DISPLAY l_invoice_total TO invoice_total 
	DISPLAY l_credit_total TO credit_total
	DISPLAY l_cash_total TO cash_total

	CALL eventsuspend() 
	#ERROR kandoomsg2("U",1,"")
	CLOSE WINDOW A686 
	
END FUNCTION