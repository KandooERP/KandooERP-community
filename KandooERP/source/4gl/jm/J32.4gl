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

	Source code beautified by beautify.pl on 2020-01-02 19:48:04	$Id: $
}




#Program J32 allows the user TO view Job Management Invoice Information

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 
GLOBALS "J32_GLOBALS.4gl" 

MAIN 
	#Initial UI Init
	CALL setModuleId("J32") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	SELECT inv_ref1_text INTO ref_text 
	FROM arparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 
	LET temp_text = ref_text clipped, 
	"................" 
	LET ref_text = temp_text 
	LET func_type = "View Invoice" 
	OPEN WINDOW wa192 with FORM "A192" -- alch kd-747 
	CALL winDecoration_a("A192") -- alch kd-747 
	CALL query() 
	CLOSE WINDOW wa192 
END MAIN 
FUNCTION select_them() 
	DISPLAY ref_text TO inv_ref1_text 
	LET msgresp = kandoomsg("U", 1001, "") 
	#1001 Enter criteria FOR selection - ESC TO begin search"
	CONSTRUCT where_part ON 
	invoicehead.cust_code, 
	invoicehead.org_cust_code, 
	customer.name_text, 
	o_cust.name_text, 
	invoicehead.inv_num, 
	invoicehead.ord_num, 
	invoicehead.job_code, 
	customer.currency_code, 
	invoicehead.goods_amt, 
	invoicehead.tax_amt, 
	invoicehead.hand_amt, 
	invoicehead.freight_amt, 
	invoicehead.total_amt, 
	invoicehead.paid_amt, 
	invoicehead.inv_date, 
	invoicehead.due_date, 
	invoicehead.disc_date, 
	invoicehead.paid_date, 
	invoicehead.disc_amt, 
	invoicehead.disc_taken_amt, 
	invoicehead.year_num, 
	invoicehead.period_num, 
	invoicehead.posted_flag, 
	invoicehead.entry_code, 
	invoicehead.entry_date, 
	invoicehead.purchase_code, 
	invoicehead.com1_text, 
	invoicehead.com2_text, 
	invoicehead.on_state_flag, 
	invoicehead.rev_date, 
	invoicehead.rev_num 
	FROM 
	invoicehead.cust_code, 
	invoicehead.org_cust_code, 
	customer.name_text, 
	formonly.org_name_text, 
	invoicehead.inv_num, 
	invoicehead.ord_num, 
	invoicehead.job_code, 
	customer.currency_code, 
	invoicehead.goods_amt, 
	invoicehead.tax_amt, 
	invoicehead.hand_amt, 
	invoicehead.freight_amt, 
	invoicehead.total_amt, 
	invoicehead.paid_amt, 
	invoicehead.inv_date, 
	invoicehead.due_date, 
	invoicehead.disc_date, 
	invoicehead.paid_date, 
	invoicehead.disc_amt, 
	invoicehead.disc_taken_amt, 
	invoicehead.year_num, 
	invoicehead.period_num, 
	invoicehead.posted_flag, 
	invoicehead.entry_code, 
	invoicehead.entry_date, 
	invoicehead.purchase_code, 
	invoicehead.com1_text, 
	invoicehead.com2_text, 
	invoicehead.on_state_flag, 
	invoicehead.rev_date, 
	invoicehead.rev_num 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","J32","const-invoicehead_cust_code-1") -- alch kd-506 
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
	END CONSTRUCT 

	LET y = length(where_part) 
	LET word = "" 
	LET use_outer = true 
	FOR x = 1 TO y 
		LET letter = where_part[x, (x + 1)] 
		IF letter = " " 
		OR letter = "=" 
		OR letter = "(" 
		OR letter = ")" 
		OR letter = "[" 
		OR letter = "]" 
		OR letter = "." 
		OR letter = "," THEN 
			LET word = "" 
		END IF 
		LET word = word clipped, 
		letter 
		IF word = "o_cust" THEN 
			LET use_outer = false 
			EXIT FOR 
		END IF 
	END FOR 
	IF use_outer THEN 
		LET query_text = "SELECT invoicehead.cust_code, ", 
		" invoicehead.org_cust_code, customer.name_text, ", 
		" o_cust.name_text, ", 
		" customer.currency_code, invoicehead.inv_num, ", 
		" invoicehead.paid_date, invoicehead.due_date, ", 
		" invoicehead.disc_date, invoicehead.goods_amt, ", 
		" invoicehead.hand_amt, invoicehead.freight_amt, ", 
		" invoicehead.tax_amt, invoicehead.total_amt, ", 
		" invoicehead.disc_amt, invoicehead.paid_amt, ", 
		" invoicehead.disc_taken_amt, invoicehead.entry_code, ", 
		" invoicehead.entry_date, invoicehead.purchase_code, ", 

		" invoicehead.job_code, ", 
		" invoicehead.inv_date, invoicehead.year_num, ", 
		" invoicehead.period_num, invoicehead.posted_flag, ", 
		" invoicehead.ord_num, invoicehead.on_state_flag, ", 
		" invoicehead.com1_text, invoicehead.rev_date, ", 
		" invoicehead.com2_text, invoicehead.rev_num ", 
		"FROM invoicehead , customer, outer customer o_cust", 
		" WHERE invoicehead.cmpy_code = \"", 
		glob_rec_kandoouser.cmpy_code, 
		"\" AND ", 
		" customer.cust_code = invoicehead.cust_code AND ", 
		" customer.cmpy_code = invoicehead.cmpy_code AND ", 
		" o_cust.cust_code = invoicehead.org_cust_code AND ", 
		" o_cust.cmpy_code = invoicehead.cmpy_code AND ", 
		" invoicehead.inv_ind = \"3\" AND ", 
		where_part clipped, 
		" ORDER BY invoicehead.cust_code, invoicehead.inv_num " 
	ELSE 
		LET query_text = "SELECT invoicehead.cust_code, ", 
		" invoicehead.org_cust_code, customer.name_text, ", 
		" o_cust.name_text, ", 
		" customer.currency_code, invoicehead.inv_num, ", 
		" invoicehead.paid_date, invoicehead.due_date, ", 
		" invoicehead.disc_date, invoicehead.goods_amt, ", 
		" invoicehead.hand_amt, invoicehead.freight_amt, ", 
		" invoicehead.tax_amt, invoicehead.total_amt, ", 
		" invoicehead.disc_amt, invoicehead.paid_amt, ", 
		" invoicehead.disc_taken_amt, invoicehead.entry_code, ", 
		" invoicehead.entry_date, invoicehead.purchase_code, ", 

		" invoicehead.job_code, ", 
		" invoicehead.inv_date, invoicehead.year_num, ", 
		" invoicehead.period_num, invoicehead.posted_flag, ", 
		" invoicehead.ord_num, invoicehead.on_state_flag, ", 
		" invoicehead.com1_text, invoicehead.rev_date, ", 
		" invoicehead.com2_text, invoicehead.rev_num ", 
		"FROM invoicehead , customer, customer o_cust", 
		" WHERE invoicehead.cmpy_code = \"", 
		glob_rec_kandoouser.cmpy_code, 
		"\" AND ", 
		" customer.cust_code = invoicehead.cust_code AND ", 
		" customer.cmpy_code = invoicehead.cmpy_code AND ", 
		" o_cust.cust_code = invoicehead.org_cust_code AND ", 
		" o_cust.cmpy_code = invoicehead.cmpy_code AND ", 
		" invoicehead.inv_ind = \"3\" AND ", 
		where_part clipped, 
		" ORDER BY invoicehead.cust_code, invoicehead.inv_num " 
	END IF 
	LET exist = 0 
	IF ((int_flag != 0 
	OR quit_flag != 0) 
	AND exist = 0) THEN 
		EXIT program 
	END IF 
	PREPARE statement_1 
	FROM query_text 
	DECLARE invoicehead_set SCROLL CURSOR FOR statement_1 
	OPEN invoicehead_set 
	FETCH invoicehead_set INTO pr_invoicehead.* 
	IF status <> notfound THEN 
		LET exist = true 
	END IF 
END FUNCTION 


FUNCTION query() 
	CLEAR FORM 

	DISPLAY ref_text TO inv_ref1_text 
	LET exist = false 
	MENU "Invoice" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","J32","menu-invoice-1") -- alch kd-506 
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
		COMMAND KEY("Q", f17) "Query" "Search FOR invoices " 
			CALL select_them() 
			IF exist THEN 
				CALL show_it() 
			ELSE 
				LET msgresp = kandoomsg("U",9101,"") 
				#9101 "No job management invoice satisfied the query criteria"
			END IF 
		COMMAND KEY("N", f21) "Next" "DISPLAY next selected invoice" 
			IF exist THEN 
				FETCH NEXT invoicehead_set INTO pr_invoicehead.* 
				IF status <> notfound THEN 
					CALL show_it() 
				ELSE 
					LET msgresp = kandoomsg("U",9001,"") 
					#9001 "You have reached the END of the invoices selected"
				END IF 
			ELSE 
				ERROR "You have TO make a selection first" 
			END IF 
		COMMAND KEY("P", f19) "Previous" "DISPLAY previous selected invoice" 
			IF exist THEN 
				FETCH previous invoicehead_set INTO pr_invoicehead.* 
				IF status <> notfound THEN 
					CALL show_it() 
				ELSE 
					LET msgresp = kandoomsg("U",9001,"") 
					#9001 "You have reached the start of the invoices selected"
				END IF 
			ELSE 
				LET msgresp = kandoomsg("U",9131,"") 
				#9131 "You have TO make a selection first"
			END IF 
		COMMAND KEY("D", f20) "Detail" "View invoice details" 
			IF exist THEN 
				CALL lineshow(glob_rec_kandoouser.cmpy_code, pr_invoicehead.cust_code, pr_invoicehead.inv_num 
				, func_type) 
			ELSE 
				LET msgresp = kandoomsg("U",9131,"") 
				#9131 "You have TO make a selection first"
			END IF 

			IF int_flag 
			OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
			END IF 
		COMMAND KEY("F", f18) "First" "DISPLAY first invoice in the selected list" 
			IF exist THEN 
				FETCH FIRST invoicehead_set INTO pr_invoicehead.* 
				IF status <> notfound THEN 
					CALL show_it() 
				ELSE 
					LET msgresp = kandoomsg("U",9001,"") 
					#9001 "You have reached the start of the invoices selected"
				END IF 
			ELSE 
				LET msgresp = kandoomsg("U",9131,"") 
				#9131 "You have TO make a selection first"
			END IF 
		COMMAND KEY("L", f22) "Last" "DISPLAY last invoice in the selected list" 
			IF exist THEN 
				FETCH LAST invoicehead_set INTO pr_invoicehead.* 
				IF status <> notfound THEN 
					CALL show_it() 
				ELSE 
					LET msgresp = kandoomsg("U",9001,"") 
					#9001 "You have reached the start of the invoices selected"
				END IF 
			ELSE 
				LET msgresp = kandoomsg("U",9131,"") 
				#9131 "You have TO make a selection first"
			END IF 
		COMMAND KEY(interrupt, "E") "Exit" "Exit TO menus" 
			EXIT MENU 
		COMMAND KEY(control-w) 
			CALL kandoohelp("") 
	END MENU 
END FUNCTION 


FUNCTION show_it() 
	IF pr_invoicehead.paid_date != "31/12/1899" THEN 
		DISPLAY BY NAME pr_invoicehead.paid_date 

	END IF 
	DISPLAY BY NAME pr_invoicehead.cust_code, 

	pr_invoicehead.org_cust_code, 
	pr_invoicehead.name_text, 

	pr_invoicehead.org_name_text, 
	pr_invoicehead.inv_num, 
	pr_invoicehead.ord_num, 
	pr_invoicehead.job_code, 
	pr_invoicehead.currency_code, 
	pr_invoicehead.goods_amt, 
	pr_invoicehead.tax_amt, 
	pr_invoicehead.hand_amt, 
	pr_invoicehead.freight_amt, 
	pr_invoicehead.total_amt, 
	pr_invoicehead.paid_amt, 
	pr_invoicehead.inv_date, 
	pr_invoicehead.due_date, 
	pr_invoicehead.disc_date, 
	pr_invoicehead.paid_date, 
	pr_invoicehead.disc_amt, 
	pr_invoicehead.disc_taken_amt, 
	pr_invoicehead.year_num, 
	pr_invoicehead.period_num, 
	pr_invoicehead.posted_flag, 
	pr_invoicehead.entry_code, 
	pr_invoicehead.entry_date, 
	pr_invoicehead.purchase_code, 
	pr_invoicehead.com1_text, 
	pr_invoicehead.com2_text, 
	pr_invoicehead.on_state_flag, 
	pr_invoicehead.rev_date, 
	pr_invoicehead.rev_num 

END FUNCTION 
