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
GLOBALS "../ar/A2_GROUP_GLOBALS.4gl"
GLOBALS "../ar/A2S_GLOBALS.4gl" 
############################################################
# FUNCTION summup() 
#
#
############################################################
FUNCTION summup() 
	DEFINE l_rec_term RECORD LIKE term.*
	DEFINE l_newyear SMALLINT
	DEFINE l_dummy money(10,2) 

	OPEN WINDOW A147 with FORM "A147" 
	CALL windecoration_a("A147") 

	IF glob_f_type = "I" THEN 
		SELECT ship1_text, ship2_text 
		INTO glob_rec_invoicehead.ship1_text, glob_rec_invoicehead.ship2_text 
		FROM customership 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = glob_rec_invoicehead.cust_code 
		AND ship_code = glob_rec_invoicehead.ship_code 
	END IF 

	CALL get_due_and_discount_date(l_rec_term.*, glob_rec_invoicehead.inv_date) 
	RETURNING glob_rec_invoicehead.due_date, glob_rec_invoicehead.disc_date 

	LET glob_rec_invoicehead.ship_date = glob_rec_invoicehead.inv_date 
	LET glob_rec_invoicehead.prepaid_flag = "P" 
	
	IF glob_recalc = "Y" THEN 
		LET glob_rec_invoicehead.hand_tax_amt = glob_rec_temp.hand_tax_amt 
		LET glob_rec_invoicehead.freight_tax_amt = glob_rec_temp.freight_tax_amt 
		LET glob_inc_tax = "Y" 
	END IF 

	CALL total_tax() 

	LET glob_inc_tax = "N" 
	LET glob_rec_invoicehead.total_amt =	glob_rec_invoicehead.goods_amt 
		+	glob_rec_invoicehead.hand_amt 
		+	glob_rec_invoicehead.freight_amt 
		+	glob_rec_invoicehead.tax_amt 

	DISPLAY BY NAME 
		glob_rec_invoicehead.cust_code, 
		glob_rec_customer.name_text, 
		glob_rec_customer.currency_code, 
		glob_rec_invoicehead.goods_amt, 
		glob_rec_invoicehead.tax_amt, 
		glob_rec_invoicehead.hand_amt, 
		glob_rec_invoicehead.freight_amt, 
		glob_rec_invoicehead.total_amt, 
		glob_rec_invoicehead.due_date, 
		glob_rec_invoicehead.disc_date, 
		glob_rec_invoicehead.disc_amt, 
		glob_rec_invoicehead.ship1_text, 
		glob_rec_invoicehead.ship2_text, 
		glob_rec_invoicehead.fob_text, 
		glob_rec_invoicehead.prepaid_flag, 
		glob_rec_invoicehead.ship_date, 
		glob_rec_invoicehead.com1_text, 
		glob_rec_invoicehead.com2_text, 
		glob_rec_invoicehead.rev_date, 
		glob_rec_invoicehead.rev_num 

	LET glob_ret_flag = 0 

	INPUT BY NAME 
		glob_rec_invoicehead.hand_amt, 
		glob_rec_invoicehead.freight_amt, 
		glob_rec_invoicehead.due_date, 
		glob_rec_invoicehead.disc_date, 
		glob_rec_invoicehead.ship1_text, 
		glob_rec_invoicehead.ship2_text, 
		glob_rec_invoicehead.fob_text, 
		glob_rec_invoicehead.prepaid_flag, 
		glob_rec_invoicehead.ship_date, 
		glob_rec_invoicehead.com1_text, 
		glob_rec_invoicehead.com2_text WITHOUT DEFAULTS 


		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A2Se","inp-invoicehead") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE FIELD hand_amt 
			CALL find_taxcode(glob_rec_invoicehead.hand_tax_code) RETURNING glob_idx 

			LET glob_arr_rec_taxamt[glob_idx].tax_amt = glob_arr_rec_taxamt[glob_idx].tax_amt - glob_rec_invoicehead.hand_tax_amt 

		AFTER FIELD hand_amt 
			IF glob_rec_invoicehead.hand_amt IS NULL THEN 
				LET glob_rec_invoicehead.hand_amt = 0 
			END IF 
			
			CALL find_tax(
				glob_rec_invoicehead.tax_code, 
				" ", 
				" ", 
				0, 
				0, 
				glob_rec_invoicehead.hand_amt, 
				1, 
				"H", 
				"", 
				"") 
			RETURNING 
				l_dummy, 
				glob_rec_invoicehead.hand_tax_amt, 
				l_dummy, 
				l_dummy, 
				glob_rec_invoicehead.hand_tax_code 

			LET glob_arr_rec_taxamt[glob_idx].tax_amt = glob_arr_rec_taxamt[glob_idx].tax_amt + glob_rec_invoicehead.hand_tax_amt 

			CALL total_tax() 

			LET glob_rec_invoicehead.total_amt = glob_rec_invoicehead.goods_amt 
				+	glob_rec_invoicehead.hand_amt 
				+	glob_rec_invoicehead.freight_amt 
				+ glob_rec_invoicehead.tax_amt 

			LET glob_rec_invoicehead.disc_amt = (glob_rec_invoicehead.goods_amt +	glob_rec_invoicehead.hand_amt) 
				* l_rec_term.disc_per / 100 
			
			DISPLAY BY NAME 
				glob_rec_invoicehead.total_amt, 
				glob_rec_invoicehead.tax_amt, 
				glob_rec_invoicehead.disc_amt 

			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 

		BEFORE FIELD freight_amt 
			CALL find_taxcode(glob_rec_invoicehead.freight_tax_code) RETURNING glob_idx 
			
			LET glob_arr_rec_taxamt[glob_idx].tax_amt = glob_arr_rec_taxamt[glob_idx].tax_amt -	glob_rec_invoicehead.freight_tax_amt 

		AFTER FIELD freight_amt 
			IF glob_rec_invoicehead.freight_amt IS NULL THEN 
				LET glob_rec_invoicehead.freight_amt = 0 
			END IF 
			
			CALL find_tax(
				glob_rec_invoicehead.tax_code, 
				" ", 
				" ", 
				0, 
				0, 
				glob_rec_invoicehead.freight_amt, 
				1, 
				"H", 
				"", 
				"") 
			RETURNING 
				l_dummy, 
				glob_rec_invoicehead.freight_tax_amt, 
				l_dummy, 
				l_dummy, 
				glob_rec_invoicehead.freight_tax_code 

			LET glob_arr_rec_taxamt[glob_idx].tax_amt = glob_arr_rec_taxamt[glob_idx].tax_amt +	glob_rec_invoicehead.freight_tax_amt 
			CALL total_tax() 
			
			LET glob_rec_invoicehead.total_amt = glob_rec_invoicehead.goods_amt 
			+	glob_rec_invoicehead.hand_amt 
			+ glob_rec_invoicehead.freight_amt 
			+ glob_rec_invoicehead.tax_amt 
			
			DISPLAY BY NAME 
				glob_rec_invoicehead.total_amt, 
				glob_rec_invoicehead.tax_amt 

			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 

		AFTER INPUT 
			LET glob_rec_invoicehead.disc_per = l_rec_term.disc_per 
			LET glob_rec_invoicehead.seq_num = 0 
			LET glob_rec_invoicehead.disc_taken_amt = 0 
			LET glob_rec_invoicehead.paid_amt = 0 
			LET glob_rec_invoicehead.on_state_flag = "N" 
			LET glob_rec_invoicehead.posted_flag = "N" 
			LET glob_rec_invoicehead.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET glob_rec_invoicehead.printed_num = 1 
	END INPUT 
	
	CLOSE WINDOW A147 
	IF int_flag OR quit_flag THEN 
		LET glob_ans = "N" 
	END IF 
END FUNCTION 
############################################################
# END FUNCTION summup() 
############################################################
 

############################################################
# FUNCTION total_tax() 
#
#
############################################################
FUNCTION total_tax() 
	DEFINE i SMALLINT 
	DEFINE x SMALLINT 

	LET i = 1 
	LET glob_rec_invoicehead.tax_amt = 0 

	WHILE (i <= 300) AND (glob_arr_rec_taxamt[i].tax_code IS NOT NULL AND glob_arr_rec_taxamt[i].tax_code <> "###" ) 
		IF glob_inc_tax = "Y" THEN 
			LET glob_arr_rec_taxamt[i].tax_amt = glob_arr_rec_taxamt[i].tax_amt 
				+ glob_rec_invoicehead.hand_tax_amt 
				+	glob_rec_invoicehead.freight_tax_amt 
		END IF
		 
		LET glob_rec_invoicehead.tax_amt = glob_rec_invoicehead.tax_amt + glob_arr_rec_taxamt[i].tax_amt 
		LET i = i + 1 
	END WHILE 
END FUNCTION 
############################################################
# END FUNCTION total_tax() 
############################################################


############################################################
# FUNCTION find_taxcode(p_tax_code)
#
#
############################################################
FUNCTION find_taxcode(p_tax_code) 
	DEFINE p_tax_code LIKE tax.tax_code 
	DEFINE i SMALLINT 

	LET i = 1 
	IF p_tax_code IS NULL THEN 
		LET p_tax_code = "###" 
	END IF 

	WHILE true 
		IF glob_arr_rec_taxamt[i].tax_code IS NULL THEN 
			LET glob_arr_rec_taxamt[i].tax_code = p_tax_code 
			LET glob_arr_rec_taxamt[i].tax_amt = 0 
			EXIT WHILE 
		END IF 

		IF glob_arr_rec_taxamt[i].tax_code = p_tax_code THEN 
			EXIT WHILE 
		END IF 

		LET i = i + 1 

		IF i > 300 THEN 
			ERROR " Internal error - Tax ARRAY overflow " 
			SLEEP 5 
			EXIT PROGRAM 
		END IF 
	END WHILE 

	RETURN i 
END FUNCTION 
############################################################
# END FUNCTION find_taxcode(p_tax_code)
############################################################