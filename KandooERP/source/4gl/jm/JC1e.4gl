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

	Source code beautified by beautify.pl on 2020-01-02 19:48:20	$Id: $
}



{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module - JC1e.4gl - FUNCTION summup()
# Purpose - JM credit entry
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 
GLOBALS "JC1_GLOBALS.4gl" 


FUNCTION summup() 
	DEFINE 
	pr_term RECORD LIKE term.*, 
	pr_araudit RECORD LIKE araudit.*, 
	newyear SMALLINT, 
	dummy LIKE credithead.total_amt 
	OPEN WINDOW wa133 with FORM "A133" -- alch kd-747 
	CALL winDecoration_a("A133") -- alch kd-747 
	DISPLAY BY NAME pr_customer.currency_code 
	attribute (green) 
	DISPLAY BY NAME pr_customer.cust_code, 
	pr_customer.name_text, 
	pr_credithead.goods_amt, 
	pr_credithead.rev_num, 
	pr_credithead.rev_date, 
	pr_credithead.tax_amt, 
	pr_credithead.total_amt 

	LET ret_flag = 0 
	INPUT BY NAME pr_credithead.hand_amt, 
	pr_credithead.freight_amt, 
	pr_credithead.com1_text, 
	pr_credithead.com2_text WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","JC1e","input-pr_credithead-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE FIELD hand_amt 
			CALL find_taxcode(pr_credithead.hand_tax_code) 
			RETURNING idx 

		AFTER FIELD hand_amt 
			IF pr_credithead.hand_amt IS NULL THEN 
				LET pr_credithead.hand_amt = 0 
			END IF 
			CALL find_tax(pr_credithead.tax_code, " ", " ", 0, 0, 
			pr_credithead.hand_amt , 1, "H", "", "") 
			RETURNING dummy, 
			pr_credithead.hand_tax_amt, 
			dummy, 
			dummy, 
			pr_credithead.hand_tax_code 

			LET pr_credithead.total_amt = pr_credithead.goods_amt + 
			pr_credithead.tax_amt + 
			pr_credithead.hand_amt + 
			pr_credithead.hand_tax_amt + 
			pr_credithead.freight_amt + 
			pr_credithead.freight_tax_amt 
			DISPLAY BY NAME pr_credithead.total_amt, 
			pr_credithead.tax_amt 

		BEFORE FIELD freight_amt 
			CALL find_taxcode(pr_credithead.freight_tax_code) 
			RETURNING idx 

		AFTER FIELD freight_amt 
			IF pr_credithead.freight_amt IS NULL THEN 
				LET pr_credithead.freight_amt = 0 
			END IF 
			CALL find_tax(pr_credithead.tax_code, " ", " ", 0, 0, 

			pr_credithead.freight_amt , 1, "F", "", "") 
			RETURNING dummy, 
			pr_credithead.freight_tax_amt, 
			dummy, 
			dummy, 
			pr_credithead.freight_tax_code 

			LET pr_credithead.total_amt = pr_credithead.goods_amt + 
			pr_credithead.tax_amt + 
			pr_credithead.hand_amt + 
			pr_credithead.hand_tax_amt + 
			pr_credithead.freight_amt + 
			pr_credithead.freight_tax_amt 
			DISPLAY BY NAME pr_credithead.total_amt, 
			pr_credithead.tax_amt 

		AFTER INPUT 
			IF NOT (int_flag 
			OR quit_flag) THEN 
				IF pr_credithead.total_amt > pr_uncredited_amt THEN 
					LET msgresp = kandoomsg("J", 9611, pr_uncredited_amt) 
					#9611 Credit exceeds invoice unpaid amount
					NEXT FIELD hand_amt 
				END IF 
				LET pr_credithead.next_num = 0 
				LET pr_credithead.on_state_flag = "N" 
				LET pr_credithead.posted_flag = "N" 
				LET pr_credithead.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET pr_credithead.printed_num = 1 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 

	CLOSE WINDOW wa133 
	IF int_flag 
	OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 


FUNCTION total_tax() 
	DEFINE 
	i SMALLINT 

	LET i = 1 


	WHILE (i <= 300) 
		IF ps_creditdetl[i].ext_tax_amt IS NOT NULL THEN 
			LET pr_credithead.tax_amt = pr_credithead.tax_amt + 
			ps_creditdetl[i].ext_tax_amt 
		END IF 
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
			LET pa_taxamt[i].tax_amt = 0 
			EXIT WHILE 
		END IF 
		IF pa_taxamt[i].tax_code = tax_code THEN 
			EXIT WHILE 
		END IF 
		LET i = i + 1 
		IF i > 100 THEN 
			LET msgresp = kandoomsg("J",7022,"") 
			#ERROR " Internal error - Tax ARRAY overflow "
			SLEEP 5 
			EXIT program 
		END IF 
	END WHILE 
	RETURN i 
END FUNCTION 
