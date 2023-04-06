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
GLOBALS "../ar/AW2_GLOBALS.4gl" 
############################################################
# Module Scope Variables
############################################################
######################################################################################
# FUNCTION AW2_main()
#
# AW2 Edit Proposed Adjustments
# Allows proposed adjustments TO be edited
######################################################################################
FUNCTION AW2_main() 
	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("AW2") 

	OPEN WINDOW A659 with FORM "A659" 
	CALL windecoration_a("A659") 

	WHILE select_tentarbal() 
		CALL scan_tentarbal() 
	END WHILE 

	CLOSE WINDOW A659 
END FUNCTION 


######################################################################################
# FUNCTION select_tentarbal()
#
#
######################################################################################
FUNCTION select_tentarbal() 
	DEFINE l_query_text CHAR(1000) 
	DEFINE l_where_text CHAR(1000) 
	DEFINE l_msgresp LIKE language.yes_flag 
	
	CLEAR FORM 
	LET l_msgresp = kandoomsg("A",1001,"") 
	#1001 Enter Selection Criteria - ESC TO Continue"
	CONSTRUCT BY NAME l_where_text ON tentarbal.cust_code, 
	customer.name_text, 
	customer.currency_code, 
	tentarbal.credit_amt, 
	tentarbal.debit_amt, 
	tentarbal.days_old 


		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","AW2","construct-tentarbal") 

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
	#1002 Searching database - please wait
	LET l_query_text = "SELECT tentarbal.cust_code,customer.name_text,", 
	"customer.currency_code,tentarbal.credit_amt,", 
	"tentarbal.debit_amt,tentarbal.days_old ", 
	" FROM tentarbal,customer ", 
	"WHERE tentarbal.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND customer.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND tentarbal.cust_code = customer.cust_code ", 
	"AND ",l_where_text clipped 
	IF glob_rec_arparms.report_ord_flag = "C" THEN 
		LET l_query_text = l_query_text clipped," ORDER BY currency_code,", 
		" tentarbal.cust_code" 
	ELSE 
		LET l_query_text = l_query_text clipped," ORDER BY currency_code,", 
		" name_text,", 
		" tentarbal.cust_code" 
	END IF 

	PREPARE s_tentarbal FROM l_query_text 
	DECLARE c_tentarbal CURSOR FOR s_tentarbal 

	RETURN true 
END FUNCTION 



######################################################################################
# FUNCTION scan_tentarbal()
#
#
######################################################################################
FUNCTION scan_tentarbal() 
	DEFINE l_del_cnt SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_tentarbal 
	RECORD 
		cust_code LIKE tentarbal.cust_code, 
		name_text LIKE customer.name_text, 
		currency_code LIKE customer.currency_code, 
		credit_amt LIKE tentarbal.credit_amt, 
		debit_amt LIKE tentarbal.debit_amt, 
		days_old LIKE tentarbal.days_old 
	END RECORD 
	DEFINE l_arr_rec_tentarbal array[1500] OF 
	RECORD 
		scroll_flag CHAR(1), 
		cust_code LIKE tentarbal.cust_code, 
		name_text LIKE customer.name_text, 
		currency_code LIKE customer.currency_code, 
		credit_amt LIKE tentarbal.credit_amt, 
		debit_amt LIKE tentarbal.debit_amt, 
		days_old LIKE tentarbal.days_old 
	END RECORD 

	#DEFINE glob_rec_customer RECORD LIKE customer.*
	DEFINE l_scroll_flag CHAR(1) 
	DEFINE l_tot_credit_amt DECIMAL(16,2) 
	DEFINE l_tot_debit_amt DECIMAL(16,2) 

	DEFINE idx SMALLINT 

	LET idx = 0 
	LET l_tot_credit_amt = 0 
	LET l_tot_debit_amt = 0 

	FOREACH c_tentarbal INTO l_rec_tentarbal.* 
		LET idx = idx + 1 
		LET l_arr_rec_tentarbal[idx].cust_code = l_rec_tentarbal.cust_code 
		LET l_arr_rec_tentarbal[idx].name_text = l_rec_tentarbal.name_text 
		LET l_arr_rec_tentarbal[idx].currency_code = l_rec_tentarbal.currency_code 
		LET l_arr_rec_tentarbal[idx].debit_amt = l_rec_tentarbal.debit_amt 
		LET l_arr_rec_tentarbal[idx].credit_amt = l_rec_tentarbal.credit_amt 
		LET l_arr_rec_tentarbal[idx].days_old = l_rec_tentarbal.days_old 
		LET l_tot_debit_amt = l_tot_debit_amt + l_arr_rec_tentarbal[idx].debit_amt 
		LET l_tot_credit_amt = l_tot_credit_amt + l_arr_rec_tentarbal[idx].credit_amt 
		IF idx = 500 THEN 
			LET l_msgresp = kandoomsg("A",9043,idx) 
			#9043 First 500 customers selected only
			EXIT FOREACH 
		END IF 
	END FOREACH 

	IF idx = 0 THEN 
		LET l_msgresp = kandoomsg("A",9308,"") 
		#9308 No tentative balance write offs selected
	END IF 

	DISPLAY l_tot_debit_amt TO tot_debit_amt  attribute(magenta)
	DISPLAY l_tot_credit_amt TO tot_credit_amt attribute(magenta)
	 
	OPTIONS INSERT KEY f38, 
	DELETE KEY f36 
	CALL set_count(idx) 
	LET l_msgresp = kandoomsg("A",1081,"") 

	#1081 F2 TO Delete - RETURN TO edit"
	INPUT ARRAY l_arr_rec_tentarbal WITHOUT DEFAULTS FROM sr_tentarbal.* ATTRIBUTE(UNBUFFERED) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","AW2","inp-arr-tentarbal") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET idx = arr_curr() 
			#LET scrn = scr_line()
			LET l_rec_tentarbal.cust_code = l_arr_rec_tentarbal[idx].cust_code 
			LET l_rec_tentarbal.debit_amt = l_arr_rec_tentarbal[idx].debit_amt 
			LET l_rec_tentarbal.credit_amt = l_arr_rec_tentarbal[idx].credit_amt 
			LET l_rec_tentarbal.days_old = l_arr_rec_tentarbal[idx].days_old 
			NEXT FIELD scroll_flag 

		BEFORE FIELD scroll_flag 
			LET l_scroll_flag = l_arr_rec_tentarbal[idx].scroll_flag 
			#DISPLAY l_arr_rec_tentarbal[idx].* TO sr_tentarbal[scrn].*

		AFTER FIELD scroll_flag 
			LET l_arr_rec_tentarbal[idx].scroll_flag = l_scroll_flag 
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF l_arr_rec_tentarbal[idx+1].cust_code IS NULL 
				OR arr_curr() >= (arr_count() + 1) THEN 
					LET l_msgresp=kandoomsg("W",9001,"") 
					#9001 There no more rows...
					NEXT FIELD scroll_flag 
				END IF 
			END IF 

		ON KEY (F8) --customer details 
			CALL cinq_clnt(glob_rec_kandoouser.cmpy_code,l_arr_rec_tentarbal[idx].cust_code) --customer details 

		ON KEY (F2) infield(scroll_flag)  --delete 
					IF l_arr_rec_tentarbal[idx].scroll_flag IS NULL THEN 
						LET l_arr_rec_tentarbal[idx].scroll_flag = "*" 
						LET l_del_cnt = l_del_cnt + 1 
					ELSE 
						LET l_arr_rec_tentarbal[idx].scroll_flag = NULL 
						LET l_del_cnt = l_del_cnt - 1 
					END IF 
					NEXT FIELD scroll_flag 


		BEFORE FIELD cust_code 
			IF l_arr_rec_tentarbal[idx].scroll_flag IS NULL THEN 
				NEXT FIELD credit_amt 
			ELSE 
				NEXT FIELD scroll_flag 
			END IF 
			#BEFORE FIELD credit_amt
			#   DISPLAY l_arr_rec_tentarbal[idx].* TO sr_tentarbal[scrn].*

		AFTER FIELD credit_amt 
			IF l_arr_rec_tentarbal[idx].credit_amt IS NULL THEN 
				NEXT FIELD credit_amt 
			END IF 
			IF l_arr_rec_tentarbal[idx].credit_amt < 0 THEN 
				LET l_msgresp = kandoomsg("A",9309,"") 
				#9309 "Value must be greater than 0
				NEXT FIELD credit_amt 
			END IF 
			
			CASE 
				WHEN fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("down") 
					LET l_tot_credit_amt = l_tot_credit_amt 
					- l_rec_tentarbal.credit_amt 
					+ l_arr_rec_tentarbal[idx].credit_amt 
					LET l_rec_tentarbal.credit_amt = l_arr_rec_tentarbal[idx].credit_amt
					 
					DISPLAY l_tot_credit_amt  TO tot_credit_amt attribute(magenta)
					 
					UPDATE tentarbal 
					SET credit_amt = l_arr_rec_tentarbal[idx].credit_amt, 
					debit_amt = l_arr_rec_tentarbal[idx].debit_amt 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cust_code = l_arr_rec_tentarbal[idx].cust_code 
					NEXT FIELD debit_amt 
					
				WHEN fgl_lastkey() = fgl_keyval("left") 
					OR fgl_lastkey() = fgl_keyval("up") 
					OR fgl_lastkey() = fgl_keyval("accept") 
					LET l_tot_credit_amt = l_tot_credit_amt 
					- l_rec_tentarbal.credit_amt 
					+ l_arr_rec_tentarbal[idx].credit_amt 
					LET l_rec_tentarbal.credit_amt = l_arr_rec_tentarbal[idx].credit_amt 
					
					DISPLAY l_tot_credit_amt TO tot_credit_amt attribute(magenta)
					 
					UPDATE tentarbal 
					SET credit_amt = l_arr_rec_tentarbal[idx].credit_amt, 
					debit_amt = l_arr_rec_tentarbal[idx].debit_amt 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cust_code = l_arr_rec_tentarbal[idx].cust_code 
					NEXT FIELD scroll_flag 
					
				OTHERWISE 
					NEXT FIELD credit_amt 
			END CASE 

		AFTER FIELD debit_amt 
			IF l_arr_rec_tentarbal[idx].debit_amt IS NULL THEN 
				NEXT FIELD debit_amt 
			END IF 
			IF l_arr_rec_tentarbal[idx].debit_amt < 0 THEN 
				LET l_msgresp = kandoomsg("A",9309,"") 
				#9309 "Value must be greater than 0
				NEXT FIELD debit_amt 
			END IF 
			CASE 
				WHEN fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("accept") 
					OR fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("down") 
					LET l_tot_debit_amt = l_tot_debit_amt 
					- l_rec_tentarbal.debit_amt 
					+ l_arr_rec_tentarbal[idx].debit_amt 
					LET l_rec_tentarbal.debit_amt = l_arr_rec_tentarbal[idx].debit_amt
					 
					DISPLAY l_tot_debit_amt TO tot_debit_amt attribute(magenta)
					 
					UPDATE tentarbal 
					SET credit_amt = l_arr_rec_tentarbal[idx].credit_amt, 
					debit_amt = l_arr_rec_tentarbal[idx].debit_amt 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cust_code = l_arr_rec_tentarbal[idx].cust_code 
					NEXT FIELD scroll_flag 
				WHEN fgl_lastkey() = fgl_keyval("left") 
					OR fgl_lastkey() = fgl_keyval("up") 
					LET l_tot_debit_amt = l_tot_debit_amt 
					- l_rec_tentarbal.debit_amt 
					+ l_arr_rec_tentarbal[idx].debit_amt 
					LET l_rec_tentarbal.debit_amt = l_arr_rec_tentarbal[idx].debit_amt
					 
					DISPLAY l_tot_debit_amt TO tot_debit_amt attribute(magenta)
					 
					UPDATE tentarbal 
					SET credit_amt = l_arr_rec_tentarbal[idx].credit_amt, 
					debit_amt = l_arr_rec_tentarbal[idx].debit_amt 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cust_code = l_arr_rec_tentarbal[idx].cust_code 
					NEXT FIELD credit_amt 
				OTHERWISE 
					NEXT FIELD debit_amt 
			END CASE 
			#AFTER ROW
			#   DISPLAY l_arr_rec_tentarbal[idx].* TO sr_tentarbal[scrn].*

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				IF infield(credit_amt) OR infield(debit_amt) THEN 
					LET l_arr_rec_tentarbal[idx].credit_amt = l_rec_tentarbal.credit_amt 
					LET l_arr_rec_tentarbal[idx].debit_amt = l_rec_tentarbal.debit_amt 
					#DISPLAY l_arr_rec_tentarbal[idx].* TO sr_tentarbal[scrn].*

					LET int_flag = false 
					LET quit_flag = false 
					NEXT FIELD scroll_flag 
				END IF 
			END IF 



	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 
		IF l_del_cnt > 0 THEN 
			LET l_msgresp = kandoomsg("A",8029,l_del_cnt) 
			#8029 Confirm TO Delete ",l_del_cnt," Tentative Balance(s)? (Y/N)"
			IF l_msgresp = "Y" THEN 
				FOR idx = 1 TO arr_count() 
					IF l_arr_rec_tentarbal[idx].scroll_flag = "*" THEN 
						DELETE FROM tentarbal 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cust_code = l_arr_rec_tentarbal[idx].cust_code 
					END IF 
				END FOR 
			END IF 
		END IF 
	END IF 
END FUNCTION 


