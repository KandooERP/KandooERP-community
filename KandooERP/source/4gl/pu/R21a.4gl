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

	Source code beautified by beautify.pl on 2020-01-02 17:06:15	Source code beautified by beautify.pl on 2020-01-02 17:03:24	$Id: $
}

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "R_PU_GLOBALS.4gl" 
GLOBALS "R21_GLOBALS.4gl" 

{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module R21  allows the user TO receipt Purchase Orders



FUNCTION R21_header() 
	DEFINE 
	err_flag, 
	cnt, 
	chosen, 
	exist, 
	idx, 
	pr_return_status, 
	id_flag SMALLINT, 
	pr_period RECORD LIKE period.* 

	SELECT * INTO pr_puparms.* FROM puparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_code = "1" 
	IF status = notfound THEN 
		ERROR " Purchasing Parameters need TO be SET up in RZP " 
		SLEEP 4 
		EXIT program 
	END IF 
	INITIALIZE pr_poaudit.* TO NULL 
	OPEN WINDOW r112 with FORM "R112" 
	CALL  windecoration_r("R112") 

	LET passover = false 
	LET pr_poaudit.entry_date = today 
	LET pr_poaudit.entry_code = glob_rec_kandoouser.sign_on_code 
	LET pr_poaudit.tran_date = today 
	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, today) RETURNING pr_poaudit.year_num, 
	pr_poaudit.period_num 
	SELECT * INTO pr_vendor.* FROM vendor 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND vend_code = pr_purchhead.vend_code 
	IF status = notfound THEN 
		ERROR "Vendor NOT found, try again" 
	END IF 
	DISPLAY pr_vendor.name_text TO vendor.name_text 

	CALL display_vend() 
	LET pr_purchhead.printed_flag = "N" 
	LET msgresp = kandoomsg("R",1019,"") 
	#1019  Enter Receipt Details; OK TO Continue
	INPUT BY NAME pr_poaudit.tran_date, 
	pr_poaudit.year_num, 
	pr_poaudit.period_num, 
	pr_purchhead.com1_text, 
	pr_purchhead.com2_text WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","R12","inp-purchhead-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		AFTER FIELD tran_date 
			IF pr_poaudit.tran_date IS NULL THEN 
				LET pr_poaudit.tran_date = today 
			END IF 
			CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, pr_poaudit.tran_date) 
			RETURNING pr_poaudit.year_num, pr_poaudit.period_num 
			DISPLAY BY NAME pr_poaudit.tran_date, 
			pr_poaudit.year_num, 
			pr_poaudit.period_num 

		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				CALL valid_period( glob_rec_kandoouser.cmpy_code, 
				pr_poaudit.year_num, 
				pr_poaudit.period_num, 
				"PU") 
				RETURNING pr_poaudit.year_num, 
				pr_poaudit.period_num, 
				pr_return_status 
				IF pr_return_status THEN 
					ERROR " Accounting period IS closed OR NOT SET up " 
					NEXT FIELD poaudit.year_num 
				END IF 
				CALL valid_period( glob_rec_kandoouser.cmpy_code, 
				pr_poaudit.year_num, 
				pr_poaudit.period_num, 
				TRAN_TYPE_INVOICE_IN) 
				RETURNING pr_poaudit.year_num, 
				pr_poaudit.period_num, 
				pr_return_status 
				IF pr_return_status THEN 
					ERROR " Accounting period IS closed OR NOT SET up " 
					NEXT FIELD poaudit.year_num 
				END IF 
				LET pr_poaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET save_year = pr_poaudit.year_num 
				LET save_period = pr_poaudit.period_num 
				LET save_date = pr_poaudit.tran_date 
				IF NOT select_mode() THEN 
					LET pr_poaudit.year_num = save_year 
					LET pr_poaudit.period_num = save_period 
					LET pr_poaudit.tran_date = save_date 
					NEXT FIELD tran_date 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 
	CLOSE WINDOW r112 
END FUNCTION 


FUNCTION display_vend() 
	SELECT * INTO pr_tax.* FROM tax 
	WHERE tax_code = pr_purchhead.tax_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	SELECT * INTO pr_term.* FROM term 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND term_code = pr_purchhead.term_code 
	SELECT * INTO pr_warehouse.* FROM warehouse 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ware_code = pr_purchhead.ware_code 
	DISPLAY pr_purchhead.curr_code TO purchhead.curr_code 
	attribute(green) 
	DISPLAY pr_purchhead.vend_code, 
	pr_purchhead.order_num, 
	pr_purchhead.salesperson_text, 
	pr_purchhead.term_code, 
	pr_term.desc_text, 
	pr_purchhead.tax_code, 
	pr_tax.desc_text, 
	pr_purchhead.ware_code, 
	pr_warehouse.desc_text, 
	pr_purchhead.type_ind, 
	pr_purchhead.conv_qty, 
	pr_purchhead.due_date, 
	pr_purchhead.cancel_date, 
	pr_purchhead.status_ind, 
	pr_purchhead.printed_flag 
	TO purchhead.vend_code, 
	purchhead.order_num, 
	purchhead.salesperson_text, 
	purchhead.term_code, 
	term.desc_text, 
	purchhead.tax_code, 
	tax.desc_text, 
	purchhead.ware_code, 
	warehouse.desc_text, 
	purchhead.type_ind, 
	purchhead.conv_qty, 
	purchhead.due_date, 
	purchhead.cancel_date, 
	purchhead.status_ind, 
	purchhead.printed_flag 

END FUNCTION 
