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
GLOBALS "../ar/AS_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/ASB_GLOBALS.4gl"
############################################################
# Module Scope Variables
############################################################

#########################################################################
# FUNCTION ASB_main()
#
# Purpose  Allows the user TO extract debtors information TO tape.
#########################################################################
FUNCTION ASB_main() 
	DEFER QUIT 
	DEFER INTERRUPT 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 
	
	CALL setModuleId("ASB") 

	CALL create_table("customer","t_customer","","Y") 

	OPEN WINDOW A112 with FORM "A112" 
	CALL windecoration_a("A112") 

	MENU " Customer Extract " 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","ASB","menu-customer-extract") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
			#huho
		ON ACTION "Unload" #" Export Customer Information (UNL)" 
			IF export_cust() THEN 
				NEXT option "Exit" 
			END IF 
			CALL rpt_rmsreps_reset(NULL)
			#huho
			#COMMAND "Unload" " Export Customer Information"
			#   IF export_cust() THEN
			#      NEXT OPTION "Exit"
			#   END IF
		COMMAND KEY(interrupt,"E")"Exit" " RETURN TO menus" 
			EXIT MENU 

	END MENU 

	CLOSE WINDOW A112 

END FUNCTION 


#########################################################################
# FUNCTION export_cust()
#
#
#########################################################################
FUNCTION export_cust() 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_cust_code LIKE customer.cust_code 
	DEFINE l_rec_customer RECORD LIKE customer.*
	DEFINE l_where_text CHAR(800) 
	DEFINE l_query_text CHAR(900) 
	DEFINE l_error_code INTEGER 

	CLEAR FORM 
	LET l_msgresp=kandoomsg("A",1011,"") 
	#1011 " Enter Customer Information - ESC TO Continue"
	CONSTRUCT BY NAME l_where_text ON cust_code, 
	name_text, 
	currency_code, 
	addr1_text, 
	addr2_text, 
	city_text, 
	state_code, 
	post_code, 
	country_code, 
	tele_text, 
	mobile_phone,
	email, 
	comment_text, 
	curr_amt, 
	over1_amt, 
	over30_amt, 
	over60_amt, 
	over90_amt, 
	bal_amt, 
	vat_code, 
	inv_level_ind, 
	cond_code, 
	avg_cred_day_num, 
	cred_limit_amt, 
	onorder_amt, 
	hold_code, 
	type_code, 
	sale_code, 
	territory_code, 
	last_inv_date, 
	last_pay_date, 
	setup_date, 
	delete_date 


		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","ASB","construct-customer") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	LET l_msgresp = kandoomsg("A",1002,"") 
	DELETE FROM t_customer WHERE 1=1 
	LET l_query_text = "SELECT * FROM customer ", 
	"WHERE cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	"AND ", l_where_text 
	PREPARE s_customer FROM l_query_text 
	DECLARE c_customer CURSOR FOR s_customer 

	FOREACH c_customer INTO l_rec_customer.* 
		INSERT INTO t_customer VALUES (l_rec_customer.*) 
	END FOREACH 

	UNLOAD TO "NUBRIK" delimiter "|" 
	SELECT cust_code, name_text, addr1_text, addr2_text, 
	city_text, state_code, post_code, term_code, 
	bal_amt, curr_amt, over1_amt, over30_amt, 
	over60_amt, over90_amt FROM t_customer 
	LET l_error_code = 1 

	WHILE l_error_code != 0 
		LET l_error_code = 0 
		RUN "/bin/mt -t /dev/rmt/1qic rew" RETURNING l_error_code 
		IF l_error_code != 0 THEN 
			LET l_msgresp = kandoomsg("A",8023,"") 
			IF l_msgresp = 'N' THEN 
				RETURN false 
			END IF 
		END IF 
	END WHILE 

	RUN "/bin/tar cvf /dev/rmt/1qic NUBRIK" 

	RETURN true 
END FUNCTION 