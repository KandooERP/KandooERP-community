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
GLOBALS "../ar/AW_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/AW1_GLOBALS.4gl" 
############################################################
# Module Scope Variables
############################################################
DEFINE glob_rec_aging RECORD 
	current_from LIKE customer.bal_amt, 
	current_to LIKE customer.bal_amt, 
	over1_from LIKE customer.bal_amt, 
	over1_to LIKE customer.bal_amt, 
	over30_from LIKE customer.bal_amt, 
	over30_to LIKE customer.bal_amt, 
	over60_from LIKE customer.bal_amt, 
	over60_to LIKE customer.bal_amt, 
	over90_from LIKE customer.bal_amt, 
	over90_to LIKE customer.bal_amt 
END RECORD 
DEFINE glob_where2_text CHAR(1000) 


#################################################################################
# FUNCTION AW1_main()
#
#   - Program AW1  - Allows the user TO generate a list of customers
#                    FOR balance write offs
#################################################################################
FUNCTION AW1_main() 
	DEFER quit 
	DEFER interrupt  

	CALL setModuleId("AW1") 

	OPEN WINDOW A658 with FORM "A658" 
	CALL windecoration_a("A658") 

	INITIALIZE glob_rec_aging.* TO NULL 
	DISPLAY BY NAME glob_rec_aging.* 
	DISPLAY glob_rec_arparms.cust_age_date TO cust_age_date 


	MENU " Customer Balance Write Off" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","AW1","menu-customer-balance") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
			
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		COMMAND "Generate" " Generate List of Proposed Balance Write Offs" 
			SELECT unique 1 FROM tentarbal 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = NOTFOUND THEN 
				IF enter_params() THEN 
					CALL cust_writeoff() 
					NEXT option "Exit" 
				ELSE 
					NEXT option "Generate" 
				END IF 
			ELSE 
				#8026 Prior tentative write offs will be deleted. Continue(Y/N)?
				IF kandoomsg("A",8026,"") != "Y" THEN 
					NEXT option "Generate" 
				ELSE 
					IF enter_params() THEN 
						CALL cust_writeoff() 
						NEXT option "Exit" 
					ELSE 
						NEXT option "Generate" 
					END IF 
				END IF 
			END IF 

		ON ACTION "CANCEL" 
			EXIT MENU 
	END MENU 

	CLOSE WINDOW A658 

END FUNCTION 


#################################################################################
# FUNCTION enter_params()
#
#
#################################################################################
FUNCTION enter_params() 
	DEFINE l_failed_it SMALLINT 
	DEFINE l_where_text CHAR(1500) 
	DEFINE l_where3_text CHAR(1000) 
	DEFINE l_query_text CHAR(1000) 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_msgresp=kandoomsg("A",1080,"") 
	#1080 Enter Write Off Generation details - ESC TO continue
	INITIALIZE glob_rec_aging.* TO NULL 
	LET l_where_text = "1=1" 
	DISPLAY BY NAME glob_rec_aging.* 
	DISPLAY glob_rec_arparms.cust_age_date TO cust_age_date 

	INPUT BY NAME glob_rec_aging.* WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED) 


		BEFORE INPUT 
			CALL publish_toolbar("kandoo","AW1","inp-aging") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		INITIALIZE glob_rec_aging.* TO NULL 
		LET l_where_text = "1=1" 
		RETURN false 
	ELSE 
		LET glob_where2_text = "1=1" 
		IF glob_rec_aging.current_from IS NOT NULL THEN 
			LET glob_where2_text = glob_where2_text clipped," AND customer.curr_amt >=", 
			glob_rec_aging.current_from 
		END IF 
		IF glob_rec_aging.current_to IS NOT NULL THEN 
			LET glob_where2_text = glob_where2_text clipped," AND customer.curr_amt <=", 
			glob_rec_aging.current_to 
		END IF 
		IF glob_rec_aging.over1_from IS NOT NULL THEN 
			LET glob_where2_text = glob_where2_text clipped," AND customer.over1_amt >=", 
			glob_rec_aging.over1_from 
		END IF 
		IF glob_rec_aging.over1_to IS NOT NULL THEN 
			LET glob_where2_text = glob_where2_text clipped," AND customer.over1_amt <=", 
			glob_rec_aging.over1_to 
		END IF 
		IF glob_rec_aging.over30_from IS NOT NULL THEN 
			LET glob_where2_text = glob_where2_text clipped," AND customer.over30_amt >=", 
			glob_rec_aging.over30_from 
		END IF 
		IF glob_rec_aging.over30_to IS NOT NULL THEN 
			LET glob_where2_text = glob_where2_text clipped," AND customer.over30_amt <=", 
			glob_rec_aging.over30_to 
		END IF 
		IF glob_rec_aging.over60_from IS NOT NULL THEN 
			LET glob_where2_text = glob_where2_text clipped," AND customer.over60_amt >=", 
			glob_rec_aging.over30_from 
		END IF 
		IF glob_rec_aging.over60_to IS NOT NULL THEN 
			LET glob_where2_text = glob_where2_text clipped," AND customer.over60_amt <=", 
			glob_rec_aging.over60_to 
		END IF 
		IF glob_rec_aging.over90_from IS NOT NULL THEN 
			LET glob_where2_text = glob_where2_text clipped," AND customer.over90_amt >=", 
			glob_rec_aging.over90_from 
		END IF 
		IF glob_rec_aging.over90_to IS NOT NULL THEN 
			LET glob_where2_text = glob_where2_text clipped," AND customer.over90_amt <=", 
			glob_rec_aging.over90_to 
		END IF 
		LET l_msgresp=kandoomsg("A",1001,"") 
		#1001 Enter Selection criteria - ESC TO continue
		LET l_where3_text = "1=1" 
		CONSTRUCT BY NAME l_where3_text ON cust_code, 
		name_text, 
		type_code, 
		onorder_amt, 
		bal_amt, 
		last_inv_date, 
		last_pay_date, 
		setup_date, 
		currency_code, 
		sale_code, 
		territory_code, 
		tax_code, 
		term_code, 
		hold_code 


			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","AW1","construct-customer") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			RETURN false 
		ELSE 
			LET l_where_text = glob_where2_text clipped," AND ",l_where3_text clipped 
			LET glob_where2_text = glob_where2_text clipped," " 
			LET l_where3_text = l_where3_text clipped," " 
			IF glob_where2_text = "1=1" AND l_where3_text = " 1=1" THEN 
				#8030 SELECT All Customer Balances FOR Write Off. Continue(Y/N)?
				IF kandoomsg("A",8030,"") != "Y" THEN 
					RETURN false 
				END IF 
			END IF 
		END IF 
	END IF 
	LET l_query_text = "SELECT * FROM customer ", 
	"WHERE customer.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND ",l_where_text clipped," ", 
	"ORDER BY currency_code" 
	IF glob_rec_arparms.report_ord_flag = "C" THEN 
		LET l_query_text = l_query_text clipped,",cust_code" 
	ELSE 
		LET l_query_text = l_query_text clipped,",name_text,cust_code" 
	END IF 
	PREPARE s_customer FROM l_query_text 
	DECLARE c_customer CURSOR with HOLD FOR s_customer 
	RETURN true 
END FUNCTION 



#################################################################################
# FUNCTION cust_writeoff()
#
#
#################################################################################
FUNCTION cust_writeoff() 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_tentarbal RECORD LIKE tentarbal.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_err_message CHAR(240) 
	DEFINE l_cust_count INTEGER 
	DEFINE l_tot_amt DECIMAL(16,2) 

	GOTO bypass1 
	LABEL recovery: 
	IF error_recover(l_err_message,status) != "Y" THEN 
		RETURN 
	END IF 
	LABEL bypass1: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		LET l_err_message = "Records FROM tentarbal cannot be deleted" 
		DELETE FROM tentarbal 
		WHERE 1=1 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	COMMIT WORK 
	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	MESSAGE kandoomsg2("A",1002,"") #1002 Searching database - please wait
	MESSAGE kandoomsg2("A",1033,"") #Double message makes now sense.. 
	LET l_cust_count = 0
	 
	FOREACH c_customer INTO l_rec_customer.* 
		LET l_tot_amt = calc_writeoff(l_rec_customer.*) 
		IF l_tot_amt != 0 THEN 
			#DISPLAY l_rec_customer.cust_code," ",l_rec_customer.name_text at 2,2 	attribute(yellow) 
			LET l_cust_count = l_cust_count + 1 
			LET l_rec_tentarbal.cmpy_code = l_rec_customer.cmpy_code 
			LET l_rec_tentarbal.cust_code = l_rec_customer.cust_code 
			LET l_rec_tentarbal.next_seq_num = l_rec_customer.next_seq_num 
			LET l_rec_tentarbal.days_old = today - l_rec_customer.last_inv_date 
			IF l_tot_amt > 0 THEN 
				LET l_rec_tentarbal.debit_amt = l_tot_amt 
				LET l_rec_tentarbal.credit_amt = 0 
			ELSE 
				LET l_rec_tentarbal.credit_amt = l_tot_amt * -1 
				LET l_rec_tentarbal.debit_amt = 0 
			END IF 
			INSERT INTO tentarbal VALUES (l_rec_tentarbal.*) 
		END IF 
	END FOREACH
	 
 
	IF l_cust_count > 0 THEN 
		CALL run_prog("AW2","","","","") 
	ELSE 
		LET l_msgresp=kandoomsg("A",7082,"")	#7082 "No Customers Selected FOR Write Off"
	END IF 
END FUNCTION 



#################################################################################
# FUNCTION calc_writeoff(p_rec_customer)
#
#
#################################################################################
FUNCTION calc_writeoff(p_rec_customer) 
	DEFINE p_rec_customer RECORD LIKE customer.* 
	DEFINE l_total_amt DECIMAL(16,2) 

	LET l_total_amt = 0 
	IF glob_where2_text = "1=1" THEN 
		LET l_total_amt = l_total_amt + p_rec_customer.bal_amt 
	ELSE 
		IF (p_rec_customer.curr_amt >= glob_rec_aging.current_from 
		AND p_rec_customer.curr_amt <= glob_rec_aging.current_to) THEN 
			LET l_total_amt = l_total_amt + p_rec_customer.curr_amt 
		END IF 
		IF (p_rec_customer.over1_amt >= glob_rec_aging.over1_from 
		AND p_rec_customer.over1_amt <= glob_rec_aging.over1_to) THEN 
			LET l_total_amt = l_total_amt + p_rec_customer.over1_amt 
		END IF 
		IF (p_rec_customer.over30_amt >= glob_rec_aging.over30_from 
		AND p_rec_customer.over30_amt <= glob_rec_aging.over30_to) THEN 
			LET l_total_amt = l_total_amt + p_rec_customer.over30_amt 
		END IF 
		IF (p_rec_customer.over60_amt >= glob_rec_aging.over60_from 
		AND p_rec_customer.over60_amt <= glob_rec_aging.over60_to) THEN 
			LET l_total_amt = l_total_amt + p_rec_customer.over60_amt 
		END IF 
		IF (p_rec_customer.over90_amt >= glob_rec_aging.over90_from 
		AND p_rec_customer.over90_amt <= glob_rec_aging.over90_to) THEN 
			LET l_total_amt = l_total_amt + p_rec_customer.over90_amt 
		END IF 
	END IF 

	RETURN l_total_amt 
END FUNCTION 