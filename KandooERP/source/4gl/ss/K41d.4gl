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

	Source code beautified by beautify.pl on 2019-12-31 14:28:29	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "K_SS_GLOBALS.4gl" 
GLOBALS "K41_GLOBALS.4gl" 


FUNCTION summup() 
	DEFINE 
	pr_save_hnd LIKE credithead.hand_amt, 
	pr_save_frt LIKE credithead.freight_amt 

	OPEN WINDOW wa133 at 2,3 WITH FORM "A133" 
	attribute(border,white,MESSAGE line first) 
	DISPLAY BY NAME pr_customer.currency_code attribute(green) 
	DISPLAY BY NAME pr_credithead.cust_code, 
	pr_customer.name_text, 
	pr_credithead.goods_amt, 
	pr_credithead.rev_num, 
	pr_credithead.rev_date, 
	pr_credithead.total_amt, 
	pr_credithead.tax_amt 

	LET ret_flag = 0 
	INPUT BY NAME pr_credithead.hand_amt, 
	pr_credithead.freight_amt, 
	pr_credithead.com1_text, 
	pr_credithead.com2_text 
	WITHOUT DEFAULTS 

		ON ACTION "WEB-HELP" -- albo kd-374 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE FIELD hand_amt 
			LET pr_save_hnd = pr_credithead.hand_amt 
			LET pr_credithead.hand_tax_code = pr_credithead.tax_code 
			LET pr_credithead.freight_tax_code = pr_credithead.tax_code 
		AFTER FIELD hand_amt 
			LET pr_credithead.total_amt = pr_credithead.goods_amt 
			+ pr_credithead.hand_amt 
			+ pr_credithead.freight_amt 
			+ pr_credithead.tax_amt 
			DISPLAY BY NAME pr_credithead.total_amt, 
			pr_credithead.tax_amt 

		AFTER FIELD freight_amt 
			LET pr_credithead.total_amt = pr_credithead.goods_amt 
			+ pr_credithead.hand_amt 
			+ pr_credithead.freight_amt 
			+ pr_credithead.tax_amt 
			DISPLAY BY NAME pr_credithead.total_amt, 
			pr_credithead.tax_amt 

		AFTER INPUT 
			IF pr_tax.hand_per IS NULL THEN 
				LET pr_credithead.hand_amt = 0 
			ELSE 
			IF pr_credithead.hand_amt IS NULL THEN 
				LET pr_credithead.hand_amt = 0 
			END IF 
			LET pr_credithead.hand_tax_amt = pr_credithead.hand_amt 
			* pr_tax.hand_per /100 
		END IF 
		IF pr_tax.freight_per IS NULL THEN 
			LET pr_credithead.freight_amt = 0 
		ELSE 
		IF pr_credithead.freight_amt IS NULL THEN 
			LET pr_credithead.freight_amt = 0 
		END IF 
		LET pr_credithead.freight_tax_amt = pr_credithead.freight_amt 
		* pr_tax.freight_per /100 
	END IF 
	LET pr_credithead.tax_amt = pr_credithead.tax_amt 
	+ pr_credithead.hand_tax_amt 
	+ pr_credithead.freight_tax_amt 
	LET pr_credithead.total_amt = pr_credithead.goods_amt 
	+ pr_credithead.hand_amt 
	+ pr_credithead.freight_amt 
	+ pr_credithead.tax_amt 
	DISPLAY BY NAME pr_credithead.total_amt, 
	pr_credithead.tax_amt 

	LET pr_credithead.tax_per = pr_tax.tax_per 
	LET pr_credithead.next_num = 0 
	LET pr_credithead.on_state_flag = "N" 
	LET pr_credithead.posted_flag = "N" 
	LET pr_credithead.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET pr_credithead.printed_num = 1 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	CLOSE WINDOW wa133 
	IF int_flag OR quit_flag THEN 
		LET ans = "N" 
	ELSE 
	CLOSE WINDOW wk155 
	CLOSE WINDOW wa127 
END IF 
END FUNCTION 
