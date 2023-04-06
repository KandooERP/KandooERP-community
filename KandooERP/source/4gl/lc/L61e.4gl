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

	Source code beautified by beautify.pl on 2020-01-02 18:38:33	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "L_LC_GLOBALS.4gl" 

GLOBALS "L61_GLOBALS.4gl" 


FUNCTION summup() 
	DEFINE 
	pr_term RECORD LIKE term.*, 
	pr_araudit RECORD LIKE araudit.*, 
	newyear SMALLINT, 
	dummy money(10,2) 

	OPEN WINDOW wl156 with FORM "L156" 
	CALL windecoration_l("L156") -- albo kd-763 
	DISPLAY BY NAME pr_customer.currency_code attribute(green) 
	DISPLAY BY NAME pr_shiphead.vend_code, 
	pr_customer.name_text, 
	pr_shiphead.fob_ent_cost_amt, 
	pr_shiphead.rev_num, 
	pr_shiphead.rev_date, 
	pr_shiphead.duty_ent_amt, 
	pr_shiphead.total_amt 

	IF pv_corp_cust THEN 
		DISPLAY pr_customer.cust_code TO cust_code 
	END IF 

	LET ret_flag = 0 
	INPUT BY NAME pr_shiphead.hand_amt, 
	pr_shiphead.freight_amt, 
	pr_shiphead.com1_text, 
	pr_shiphead.com2_text WITHOUT DEFAULTS 

		ON ACTION "WEB-HELP" -- albo kd-375 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE FIELD hand_amt 
			CALL find_taxcode(pr_shiphead.hand_tax_code) RETURNING idx 
			LET pa_taxamt[idx].duty_ent_amt = pa_taxamt[idx].duty_ent_amt - 
			pr_shiphead.hand_tax_amt 
		AFTER FIELD hand_amt 
			IF pr_shiphead.hand_amt IS NULL THEN 
				LET pr_shiphead.hand_amt = 0 
			END IF 
			CALL find_tax(pr_shiphead.tax_code, 
			" ", 
			" ", 
			0, 
			0, 
			pr_shiphead.hand_amt, 
			1, 
			"H", 
			"", 
			"") RETURNING dummy, 
			pr_shiphead.hand_tax_amt, 
			dummy, 
			dummy, 
			pr_shiphead.hand_tax_code 

			LET pa_taxamt[idx].duty_ent_amt = pa_taxamt[idx].duty_ent_amt + 
			pr_shiphead.hand_tax_amt 
			CALL total_tax() 
			LET pr_shiphead.total_amt = pr_shiphead.fob_ent_cost_amt + 
			pr_shiphead.hand_amt + 
			pr_shiphead.freight_amt + 
			pr_shiphead.duty_ent_amt 
			DISPLAY BY NAME pr_shiphead.total_amt, 
			pr_shiphead.duty_ent_amt 
		BEFORE FIELD freight_amt 
			CALL find_taxcode(pr_shiphead.freight_tax_code) RETURNING idx 
			LET pa_taxamt[idx].duty_ent_amt = pa_taxamt[idx].duty_ent_amt - 
			pr_shiphead.freight_tax_amt 
		AFTER FIELD freight_amt 
			IF pr_shiphead.freight_amt IS NULL THEN 
				LET pr_shiphead.freight_amt = 0 
			END IF 
			CALL find_tax(pr_shiphead.tax_code, 
			" ", 
			" ", 
			0, 
			0, 
			pr_shiphead.freight_amt, 
			1, 
			"H", 
			"", 
			"") RETURNING dummy, 
			pr_shiphead.freight_tax_amt, 
			dummy, 
			dummy, 
			pr_shiphead.freight_tax_code 

			LET pa_taxamt[idx].duty_ent_amt = pa_taxamt[idx].duty_ent_amt + 
			pr_shiphead.freight_tax_amt 
			CALL total_tax() 
			LET pr_shiphead.total_amt = pr_shiphead.fob_ent_cost_amt + 
			pr_shiphead.hand_amt + 
			pr_shiphead.freight_amt + 
			pr_shiphead.duty_ent_amt 
			DISPLAY BY NAME pr_shiphead.total_amt, 
			pr_shiphead.duty_ent_amt 
		AFTER INPUT 
			#LET pr_shiphead.next_num = 0
			#   LET pr_shiphead.on_state_flag = "N"
			#   LET pr_shiphead.posted_flag = "N"
			LET pr_shiphead.cmpy_code = glob_rec_kandoouser.cmpy_code 
			#   LET pr_shiphead.printed_num = 1
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	CLOSE WINDOW wl156 
	IF int_flag != 0 
	OR quit_flag != 0 
	THEN 
		LET ans = "N" 
	ELSE 
		CLOSE WINDOW wl153 
		CLOSE WINDOW wl154 
	END IF 
END FUNCTION 

FUNCTION total_tax() 
	DEFINE 
	i SMALLINT 

	LET i = 1 
	LET pr_shiphead.duty_ent_amt = 0 
	WHILE (i <= 100) AND (pa_taxamt[i].tax_code IS NOT null) 
		LET pr_shiphead.duty_ent_amt = pr_shiphead.duty_ent_amt + pa_taxamt[i].duty_ent_amt 
		LET i = i + 1 
	END WHILE 
END FUNCTION 

FUNCTION find_taxcode(tax_code) 
	DEFINE 
	tax_code LIKE tax.tax_code, 
	i SMALLINT 

	LET i = 1 
	IF tax_code IS NULL THEN 
		LET tax_code = "###" 
	END IF 
	WHILE true 
		IF pa_taxamt[i].tax_code IS NULL THEN 
			LET pa_taxamt[i].tax_code = tax_code 
			LET pa_taxamt[i].duty_ent_amt = 0 
			EXIT WHILE 
		END IF 
		IF pa_taxamt[i].tax_code = tax_code THEN 
			EXIT WHILE 
		END IF 
		LET i = i + 1 
		IF i > 100 THEN 
			ERROR " Internal error - Tax ARRAY overflow " 
			SLEEP 5 
			EXIT program 
		END IF 
	END WHILE 
	RETURN i 
END FUNCTION 
