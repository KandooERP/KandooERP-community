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

	Source code beautified by beautify.pl on 2020-01-02 19:48:06	$Id: $
}



# Modified version of A21e, FOR job management
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J36_GLOBALS.4gl" 

FUNCTION summup() 
	DEFINE msgresp LIKE language.yes_flag 

	DEFINE 
	dummy money(10,2) 
	OPEN WINDOW wa147 with FORM "A147" -- alch kd-747 
	CALL winDecoration_a("A147") -- alch kd-747 
	IF tmp_tax_total IS NULL THEN 
		LET tmp_tax_total = 0 
	END IF 
	LET pr_invoicehead.tax_amt = tmp_tax_total 
	LET pr_invoicehead.total_amt = pr_invoicehead.goods_amt + 
	pr_invoicehead.tax_amt + 
	pr_invoicehead.hand_amt + 
	pr_invoicehead.hand_tax_amt + 
	pr_invoicehead.freight_amt + 
	pr_invoicehead.freight_tax_amt 
	LET pr_invoicehead.disc_per = pr_term.disc_per 

	IF pv_corp_cust THEN 
		DISPLAY pr_invoicehead.org_cust_code TO invoicehead.cust_code 
	ELSE 
		DISPLAY BY NAME pr_invoicehead.cust_code 
	END IF 
	LET msgresp=kandoomsg("J",1425,"") 
	#F5 TO view foreign curency details
	DISPLAY BY NAME pr_customer.name_text, 
	pr_customer.currency_code, 
	pr_invoicehead.goods_amt, 
	pr_invoicehead.tax_amt, 
	pr_invoicehead.hand_amt, 
	pr_invoicehead.freight_amt, 
	pr_invoicehead.total_amt, 
	pr_invoicehead.due_date, 
	pr_invoicehead.disc_date, 
	pr_invoicehead.disc_amt, 
	pr_invoicehead.ship1_text, 
	pr_invoicehead.ship2_text, 
	pr_invoicehead.fob_text, 
	pr_invoicehead.prepaid_flag, 
	pr_invoicehead.ship_date, 
	pr_invoicehead.com1_text, 
	pr_invoicehead.com2_text, 
	pr_invoicehead.rev_date, 
	pr_invoicehead.rev_num 

	INPUT BY NAME pr_invoicehead.hand_amt, 
	pr_invoicehead.freight_amt, 
	pr_invoicehead.due_date, 
	pr_invoicehead.disc_date, 
	pr_invoicehead.ship1_text, 
	pr_invoicehead.ship2_text, 
	pr_invoicehead.fob_text, 
	pr_invoicehead.prepaid_flag, 
	pr_invoicehead.ship_date, 
	pr_invoicehead.com1_text, 
	pr_invoicehead.com2_text WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","J36e","input-pr_invoicehead-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (F5) 
			LET pr_invoicehead.total_amt = pr_invoicehead.goods_amt + 
			pr_invoicehead.tax_amt + 
			pr_invoicehead.hand_amt + 
			pr_invoicehead.hand_tax_amt + 
			pr_invoicehead.freight_amt + 
			pr_invoicehead.freight_tax_amt 
			CALL view_currency2( pr_customer.cust_code, 
			pr_invoicehead.conv_qty ) 
			# Handling Charges


		BEFORE FIELD hand_amt 
			LET pr_invoicehead.total_amt = pr_invoicehead.total_amt 
			- pr_invoicehead.hand_amt 

		AFTER FIELD hand_amt 
			IF pr_invoicehead.hand_amt IS NULL THEN 
				LET pr_invoicehead.hand_amt = 0 
				NEXT FIELD hand_amt 
			END IF 
			LET pr_invoicehead.total_amt = pr_invoicehead.total_amt 
			+ pr_invoicehead.hand_amt 

			CALL find_tax(pr_invoicehead.tax_code, 
			" ", 
			" ", 
			0, 
			0, 
			pr_invoicehead.hand_amt, 
			1, 
			"H", 
			"", 
			"") RETURNING dummy, 
			pr_invoicehead.hand_tax_amt, 
			dummy, 
			dummy, 
			pr_invoicehead.hand_tax_code 

			LET pr_invoicehead.total_amt = pr_invoicehead.goods_amt + 
			pr_invoicehead.tax_amt + 
			pr_invoicehead.hand_amt + 
			pr_invoicehead.hand_tax_amt + 
			pr_invoicehead.freight_amt + 
			pr_invoicehead.freight_tax_amt 


			DISPLAY BY NAME pr_invoicehead.total_amt, 
			pr_invoicehead.tax_amt 

			# Freight Charges

		BEFORE FIELD freight_amt 
			LET pr_invoicehead.total_amt = pr_invoicehead.total_amt 
			- pr_invoicehead.freight_amt 

		AFTER FIELD freight_amt 
			IF pr_invoicehead.freight_amt IS NULL THEN 
				LET pr_invoicehead.freight_amt = 0 
				NEXT FIELD freight_amt 
			END IF 

			LET pr_invoicehead.total_amt = pr_invoicehead.total_amt 
			+ pr_invoicehead.freight_amt 

			CALL find_tax(pr_invoicehead.tax_code, 
			" ", 
			" ", 
			0, 
			0, 
			pr_invoicehead.freight_amt, 
			1, 
			"F", 
			"", 
			"") RETURNING dummy, 
			pr_invoicehead.freight_tax_amt, 
			dummy, 
			dummy, 
			pr_invoicehead.freight_tax_code 

			LET pr_invoicehead.total_amt = pr_invoicehead.goods_amt + 
			pr_invoicehead.tax_amt + 
			pr_invoicehead.hand_amt + 
			pr_invoicehead.hand_tax_amt + 
			pr_invoicehead.freight_amt + 
			pr_invoicehead.freight_tax_amt 

			DISPLAY BY NAME pr_invoicehead.total_amt, 
			pr_invoicehead.tax_amt 



		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 

	CLOSE WINDOW wa147 
	IF int_flag OR quit_flag THEN 
		LET pr_invoicehead.total_amt = orig_inv_amt 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 

END FUNCTION 

FUNCTION view_currency2( fv_cust, fv_xchange ) 

	DEFINE fv_cust LIKE customer.cust_code, 
	fv_currency LIKE customer.currency_code, 
	fv_xchange LIKE rate_exchange.conv_buy_qty, 
	fv_goods_amt LIKE invoicehead.goods_amt, 
	fv_tax_amt LIKE invoicehead.tax_amt, 
	fv_hand_amt LIKE invoicehead.hand_amt, 
	fv_freight_amt LIKE invoicehead.freight_amt, 
	fv_total_amt LIKE invoicehead.total_amt, 
	fv_disc_amt LIKE invoicehead.disc_amt, 
	fv_ok CHAR(1), 
	mess_prompt STRING 

	SELECT customer.currency_code 
	INTO fv_currency 
	FROM customer 
	WHERE customer.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND customer.cust_code = fv_cust 

	LET fv_goods_amt = pr_invoicehead.goods_amt * fv_xchange 
	LET fv_tax_amt = pr_invoicehead.tax_amt * fv_xchange 
	LET fv_hand_amt = pr_invoicehead.hand_amt * fv_xchange 
	LET fv_freight_amt = pr_invoicehead.freight_amt * fv_xchange 

	LET fv_total_amt = pr_invoicehead.total_amt * fv_xchange 
	LET fv_disc_amt = pr_invoicehead.disc_amt * fv_xchange 

	DISPLAY fv_goods_amt, fv_tax_amt, fv_hand_amt, fv_freight_amt, 
	fv_total_amt, fv_disc_amt TO goods_amt, tax_amt, hand_amt, 
	freight_amt, total_amt, disc_amt 
	--    prompt 'Values shown in ', fv_currency clipped, '. RETURN TO continue:'  -- albo
	--        FOR fv_ok
	LET mess_prompt = 'values shown in ', fv_currency clipped, '. RETURN TO continue:' -- albo 
	LET fv_ok = promptInput(mess_prompt,"",1) 

	LET int_flag = false 
	LET quit_flag = false 

	DISPLAY BY NAME pr_invoicehead.goods_amt, pr_invoicehead.tax_amt, 
	pr_invoicehead.hand_amt, pr_invoicehead.freight_amt, 
	pr_invoicehead.total_amt, pr_invoicehead.disc_amt 

END FUNCTION 

