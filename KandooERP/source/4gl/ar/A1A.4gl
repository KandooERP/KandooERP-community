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
GLOBALS "../ar/A1_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/A1A_GLOBALS.4gl"

###########################################################################
# MODULE Scope Variables
###########################################################################
	DEFINE modu_rec_customerhist RECORD LIKE customerhist.*
	DEFINE modu_rec_t_customerhist RECORD LIKE customerhist.*
	DEFINE modu_arr_rec_customerhist DYNAMIC ARRAY OF RECORD  
		year_num LIKE customerhist.year_num, 
		period_num LIKE customerhist.period_num, 
		sales_qty LIKE customerhist.sales_qty, 
		cash_amt LIKE customerhist.cash_amt, 
		cred_amt LIKE customerhist.cred_amt, 
		gross_per LIKE customerhist.gross_per 
	END RECORD 
	
###########################################################################
# FUNCTION A1A_main()
#
# allows the user TO view customer history information
###########################################################################
FUNCTION A1A_main() 
	DEFINE l_ans LIKE language.yes_flag 

	DEFER interrupt 
	DEFER quit 

	CALL setModuleId("A1A") 

	LET l_ans = "Y" 

	WHILE l_ans matches "[yY]" 
		CALL doit() 
		CLOSE WINDOW A114 
		LET l_ans = "Y" 
	END WHILE 

END FUNCTION 
###########################################################################
# END FUNCTION A1A_main() 
###########################################################################


###########################################################################
# FUNCTION doit()
#
#
###########################################################################
FUNCTION doit() 
	DEFINE l_idx SMALLINT
	OPEN WINDOW A114 with FORM "A114" 
	CALL windecoration_a("A114") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	MESSAGE kandoomsg2("A",1014,"") #1014 "Enter Customer Code; OK TO Continue"
	INITIALIZE modu_rec_t_customerhist.* TO NULL 
	
	DISPLAY BY NAME 
		modu_rec_t_customerhist.cust_code, 
		modu_rec_t_customerhist.year_num 

	INPUT BY NAME modu_rec_t_customerhist.cust_code, modu_rec_t_customerhist.year_num 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A1A","inp-customerhist") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (cust_code) 
			LET modu_rec_t_customerhist.cust_code = show_clnt(glob_rec_kandoouser.cmpy_code) 
			DISPLAY modu_rec_t_customerhist.cust_code TO cust_code
			NEXT FIELD cust_code 

		ON CHANGE cust_code
			DISPLAY db_customer_get_name_text(UI_OFF,modu_rec_t_customerhist.cust_code) TO customer.name_text		
			DISPLAY db_customer_get_currency_code(UI_OFF,modu_rec_t_customerhist.cust_code) TO customer.currency_code
			
		AFTER FIELD cust_code 
			SELECT * 
			INTO glob_rec_customer.* 
			FROM customer 
			WHERE cust_code = modu_rec_t_customerhist.cust_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("U",9105,"") 			#9105 " RECORD NOT found, try window"
				NEXT FIELD cust_code 
			END IF 

	END INPUT 

	IF int_flag != 0 OR quit_flag != 0 THEN 
		EXIT PROGRAM 
	END IF 

	DISPLAY BY NAME glob_rec_customer.name_text 
	DISPLAY BY NAME glob_rec_customer.currency_code #HuHo: attribute(GREEN) #why with color / green ? I'll remove it 

	IF modu_rec_t_customerhist.year_num IS NULL THEN 
		LET modu_rec_t_customerhist.year_num = 0 
	END IF 

	DECLARE c_hist CURSOR FOR 
	SELECT * 
	INTO modu_rec_customerhist.* 
	FROM customerhist 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cust_code = modu_rec_t_customerhist.cust_code 
	AND year_num >= modu_rec_t_customerhist.year_num 
	ORDER BY cust_code, year_num, period_num 

	LET l_idx = 0 
	FOREACH c_hist 
		LET l_idx = l_idx + 1 
		LET modu_arr_rec_customerhist[l_idx].year_num = modu_rec_customerhist.year_num 
		LET modu_arr_rec_customerhist[l_idx].period_num = modu_rec_customerhist.period_num 
		LET modu_arr_rec_customerhist[l_idx].sales_qty = modu_rec_customerhist.sales_qty 
		LET modu_arr_rec_customerhist[l_idx].cash_amt = modu_rec_customerhist.cash_amt 
		LET modu_arr_rec_customerhist[l_idx].cred_amt = modu_rec_customerhist.cred_amt 
		LET modu_arr_rec_customerhist[l_idx].gross_per = modu_rec_customerhist.gross_per 
	END FOREACH 

	MESSAGE kandoomsg2("A",1041,"") 	#1041 "ENTER on line TO view history detail"
	INPUT ARRAY modu_arr_rec_customerhist WITHOUT DEFAULTS FROM sr_customerhist.* ATTRIBUTE(UNBUFFERED) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A1A","inp-arr-customerhist") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			#LET scrn = scr_line()
			LET modu_rec_customerhist.year_num = modu_arr_rec_customerhist[l_idx].year_num 
			LET modu_rec_customerhist.period_num = modu_arr_rec_customerhist[l_idx].period_num 
			LET modu_rec_customerhist.sales_qty = modu_arr_rec_customerhist[l_idx].sales_qty 
			LET modu_rec_customerhist.cash_amt = modu_arr_rec_customerhist[l_idx].cash_amt 
			LET modu_rec_customerhist.cred_amt = modu_arr_rec_customerhist[l_idx].cred_amt 
			LET modu_rec_customerhist.gross_per = modu_arr_rec_customerhist[l_idx].gross_per 
			--LET modu_id_flag = 0 

		BEFORE FIELD period_num 
			IF modu_arr_rec_customerhist[l_idx].year_num IS NULL OR modu_arr_rec_customerhist[l_idx].period_num IS NULL THEN 
				ERROR kandoomsg2("A",9514,"") 				#9514 "No history available FOR this period"
				NEXT FIELD year_num 
			ELSE 
				CALL disp_cm_hist(
					glob_rec_kandoouser.cmpy_code, 
					modu_rec_t_customerhist.cust_code, 
					modu_arr_rec_customerhist[l_idx].year_num, 
					modu_arr_rec_customerhist[l_idx].period_num) 
				NEXT FIELD year_num 
			END IF 

	END INPUT 

	IF int_flag != 0 OR quit_flag != 0	THEN 
		LET int_flag = 0 
		LET quit_flag = 0 
	END IF 

END FUNCTION
###########################################################################
# END FUNCTION doit()
###########################################################################