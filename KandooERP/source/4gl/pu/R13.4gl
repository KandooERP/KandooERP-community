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

	Source code beautified by beautify.pl on 2020-01-02 17:06:13	Source code beautified by beautify.pl on 2020-01-02 17:03:23	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "R_PU_GLOBALS.4gl" 

{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module R13 allows the user TO inquire on Purchase Orders

GLOBALS 
	DEFINE 
	pr_purchhead RECORD LIKE purchhead.*, 
	pr_vendor RECORD LIKE vendor.*, 
	po_set_open SMALLINT 
END GLOBALS 


##################################################################
# MAIN
#
#
##################################################################
MAIN 

	CALL setModuleId("R13") -- albo 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_r_pu() #init r/pu purchase ORDER module 

	OPEN WINDOW r152 with FORM "R152" 
	CALL  windecoration_r("R152") 

	CALL po_inquiry() 
	CLOSE WINDOW r152 

END MAIN 


FUNCTION po_selected() 
	DEFINE 
	query_text CHAR(1300), 
	where_text CHAR(1000), 
	where2_text CHAR(500) 

	CLEAR FORM 
	LET where2_text = NULL 
	LET msgresp = kandoomsg("P",1001,"") 
	#1001 Enter Selection Criteria;  OK TO Continue. F8 Extended Criteria...
	CONSTRUCT where_text ON purchhead.vend_code, 
	vendor.name_text, 
	purchhead.order_num, 
	purchhead.order_date, 
	purchhead.term_code, 
	purchhead.tax_code, 
	purchhead.ware_code, 
	purchhead.authorise_code, 
	purchhead.order_text, 
	purchhead.salesperson_text, 
	purchhead.var_num, 
	purchhead.year_num, 
	purchhead.period_num, 
	purchhead.status_ind, 
	purchhead.printed_flag, 
	purchhead.rev_num, 
	purchhead.type_ind, 
	purchhead.conv_qty, 
	purchhead.curr_code, 
	purchhead.due_date, 
	purchhead.cancel_date, 
	purchhead.com1_text, 
	purchhead.com2_text 
	FROM purchhead.vend_code, 
	vendor.name_text, 
	purchhead.order_num, 
	purchhead.order_date, 
	purchhead.term_code, 
	purchhead.tax_code, 
	purchhead.ware_code, 
	purchhead.authorise_code, 
	purchhead.order_text, 
	purchhead.salesperson_text, 
	purchhead.var_num, 
	purchhead.year_num, 
	purchhead.period_num, 
	purchhead.status_ind, 
	purchhead.printed_flag, 
	purchhead.rev_num, 
	purchhead.type_ind, 
	purchhead.conv_qty, 
	purchhead.curr_code, 
	purchhead.due_date, 
	purchhead.cancel_date, 
	purchhead.com1_text, 
	purchhead.com2_text 


		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","R13","construct-purchhead-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 



		ON KEY (F8) 
			LET where2_text = extend_criteria() 
			IF where2_text IS NULL THEN 
				CONTINUE CONSTRUCT 
			END IF 
		AFTER CONSTRUCT 
			IF not(int_flag OR quit_flag) THEN 
				IF where2_text IS NULL THEN 
					LET where2_text = "1=1" 
				END IF 
			END IF 
	END CONSTRUCT 


	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	LET msgresp = kandoomsg("A",1002,"") 
	#1002 Searching database;  Please wait.
	LET query_text = 
	"SELECT distinct purchhead.*, vendor.* ", 
	" FROM vendor, purchhead, purchdetl, outer job ", 
	" WHERE purchhead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	" purchdetl.cmpy_code = purchhead.cmpy_code AND ", 
	" purchdetl.vend_code = purchhead.vend_code AND ", 
	" purchdetl.order_num = purchhead.order_num AND ", 
	" vendor.cmpy_code = purchhead.cmpy_code AND ", 
	" vendor.vend_code = purchhead.vend_code AND ", 
	" job.cmpy_code = purchdetl.cmpy_code AND ", 
	" job.job_code = purchdetl.job_code AND ", 
	where_text clipped, " AND ", 
	where2_text clipped, 
	" ORDER BY purchhead.vend_code, purchhead.order_num " 


	PREPARE po_query FROM query_text 
	DECLARE po_set SCROLL CURSOR FOR po_query 
	OPEN po_set 
	FETCH po_set INTO pr_purchhead.*, pr_vendor.* 
	IF status = notfound THEN 
		LET po_set_open = false 
		RETURN false 
	ELSE 
		LET po_set_open = true 
		RETURN true 
	END IF 
END FUNCTION 


FUNCTION po_inquiry() 
	DEFINE 
	pr_note_code CHAR(15) 

	LET po_set_open = false 
	MENU " Purchase Orders" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","R13","menu-purchase_orders-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		COMMAND "Query" " Enter selection criteria FOR products" 
			IF po_selected() THEN 
				CALL display_order() 
			ELSE 
				IF po_set_open THEN 
					CALL display_order() # re-display previous valid selection 
				ELSE 
					ERROR "No orders satisfied the query criteria" 
				END IF 
			END IF 
		COMMAND KEY ("N",f21) "Next" " DISPLAY next selected ORDER" 
			IF po_set_open THEN 
				FETCH NEXT po_set 
				INTO pr_purchhead.*, 
				pr_vendor.* 
				IF status = notfound THEN 
					ERROR "You have reached the END of the orders selected" 
				ELSE 
					CALL display_order() 
				END IF 
			ELSE 
				ERROR "You have TO make a selection first" 
			END IF 
		COMMAND KEY ("P",f19) "Previous" " DISPLAY previous selected ORDER" 
			IF po_set_open THEN 
				FETCH previous po_set 
				INTO pr_purchhead.*, 
				pr_vendor.* 
				IF status = notfound THEN 
					ERROR "You have reached the start of the orders selected" 
				ELSE 
					CALL display_order() 
				END IF 
			ELSE 
				ERROR " You have TO make a selection first" 
			END IF 
		COMMAND KEY ("D",f20) "Detail" " View ORDER details" 
			IF po_set_open THEN 

				MENU " Detail" 

					BEFORE MENU 
						CALL publish_toolbar("kandoo","R13","menu-purchase_orders-1") 
						IF pr_purchhead.note_code IS NULL 
						OR pr_purchhead.note_code = " " THEN 
							HIDE option "Notes" 
						END IF 

					ON ACTION "WEB-HELP" 
						CALL onlinehelp(getmoduleid(),null) 
					ON ACTION "actToolbarManager" 
						CALL setuptoolbar() 


					COMMAND "Lines" " View purchase ORDER line information" 
						CALL podewind(glob_rec_kandoouser.cmpy_code, 
						pr_purchhead.order_num) 
					COMMAND "Delivery" " View delivery information FOR purchase ORDER" 
						CALL disp_del_addr() 
					COMMAND "Notes" " View purchase ORDER notes" 
						CALL disp_note(pr_purchhead.cmpy_code, 
						pr_purchhead.note_code) 
					COMMAND "PO Status" " View purchase ORDER STATUS" 
						CALL pooswind(glob_rec_kandoouser.cmpy_code, 
						pr_purchhead.order_num) 
					COMMAND KEY(interrupt,E) "Exit" " Exit FROM this query" 
						EXIT MENU 
					COMMAND KEY (control-w) 
						CALL kandoohelp("") 
				END MENU 
				LET int_flag = false 
				LET quit_flag = false 
			ELSE 
				ERROR " You have TO make a selection first" 
			END IF 
		COMMAND KEY ("F",f18) "First" " DISPLAY first ORDER in the selected list" 
			IF po_set_open THEN 
				FETCH FIRST po_set 
				INTO pr_purchhead.*, 
				pr_vendor.* 
				IF status = notfound THEN 
					ERROR "You have reached the start of the orders selected" 
				ELSE 
					CALL display_order() 
				END IF 
			ELSE 
				ERROR "You have TO make a selection first" 
			END IF 
		COMMAND KEY ("L",f22) "Last" " DISPLAY last ORDER in the selected list" 
			IF po_set_open THEN 
				FETCH LAST po_set 
				INTO pr_purchhead.*, 
				pr_vendor.* 
				IF status = notfound THEN 
					ERROR "You have reached the END of the orders selected" 
				ELSE 
					CALL display_order() 
				END IF 
			ELSE 
				ERROR " You have TO make a selection first" 
			END IF 
		COMMAND KEY(interrupt,"E") "Exit" " Exit TO menus" 
			EXIT MENU 
		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
	END MENU 
END FUNCTION 


FUNCTION display_order() 
	DEFINE 
	pr_term_desc LIKE term.desc_text, 
	pr_tax_desc LIKE tax.desc_text, 
	pr_ware_desc LIKE warehouse.desc_text, 
	order_total, 
	received_total, 
	voucher_total, 
	tax_total LIKE voucher.total_amt 

	CALL po_head_info(glob_rec_kandoouser.cmpy_code, 
	pr_purchhead.order_num) 
	RETURNING order_total, 
	received_total, 
	voucher_total, 
	tax_total 

	SELECT desc_text INTO pr_term_desc FROM term 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND term_code = pr_purchhead.term_code 
	IF status = notfound THEN 
		LET pr_term_desc = " " 
	END IF 

	SELECT desc_text INTO pr_tax_desc FROM tax 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tax_code = pr_purchhead.tax_code 
	IF status = notfound THEN 
		LET pr_tax_desc = " " 
	END IF 

	SELECT desc_text INTO pr_ware_desc FROM warehouse 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ware_code = pr_purchhead.ware_code 
	IF status = notfound THEN 
		LET pr_ware_desc = " " 
	END IF 

	SELECT note_code INTO pr_purchhead.note_code FROM purchhead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND order_num = pr_purchhead.order_num 

	DISPLAY pr_purchhead.vend_code, 
	pr_vendor.name_text, 
	pr_purchhead.order_num, 
	pr_purchhead.order_date, 
	pr_purchhead.term_code, 
	pr_term_desc, 
	pr_purchhead.tax_code, 
	pr_tax_desc, 
	pr_purchhead.ware_code, 
	pr_ware_desc, 
	pr_purchhead.conv_qty, 
	pr_purchhead.authorise_code, 
	pr_purchhead.note_code, 
	pr_purchhead.type_ind, 
	pr_purchhead.order_text, 
	pr_purchhead.salesperson_text, 
	pr_purchhead.com1_text, 
	pr_purchhead.com2_text, 
	pr_purchhead.due_date, 
	pr_purchhead.cancel_date, 
	pr_purchhead.var_num, 
	pr_purchhead.year_num, 
	pr_purchhead.period_num, 
	pr_purchhead.status_ind, 
	pr_purchhead.printed_flag, 
	pr_purchhead.rev_num, 
	order_total, 
	received_total, 
	voucher_total 
	TO purchhead.vend_code, 
	vendor.name_text, 
	purchhead.order_num, 
	purchhead.order_date, 
	purchhead.term_code, 
	term.desc_text, 
	purchhead.tax_code, 
	tax.desc_text, 
	purchhead.ware_code, 
	warehouse.desc_text, 
	purchhead.conv_qty, 
	purchhead.authorise_code, 
	purchhead.note_code, 
	purchhead.type_ind, 
	purchhead.order_text, 
	purchhead.salesperson_text, 
	purchhead.com1_text, 
	purchhead.com2_text, 
	purchhead.due_date, 
	purchhead.cancel_date, 
	purchhead.var_num, 
	purchhead.year_num, 
	purchhead.period_num, 
	purchhead.status_ind, 
	purchhead.printed_flag, 
	purchhead.rev_num, 
	order_total, 
	received_total, 
	voucher_total 

	DISPLAY pr_purchhead.curr_code TO purchhead.curr_code 
	attribute (green) 
END FUNCTION 


FUNCTION disp_del_addr() 
	OPEN WINDOW r106 with FORM "R106" 
	CALL  windecoration_r("R106") 

	DISPLAY BY NAME 
		pr_purchhead.del_name_text, 
		pr_purchhead.del_addr1_text, 
		pr_purchhead.del_addr2_text, 
		pr_purchhead.del_addr3_text, 
		pr_purchhead.del_addr4_text, 
		pr_purchhead.del_country_code, 
		pr_purchhead.contact_text, 
		pr_purchhead.tele_text 

	CALL eventsuspend() # LET msgresp = kandoomsg("U",1,"") 
	#1 Any Key TO Continue
	CLOSE WINDOW r106 
END FUNCTION 


FUNCTION extend_criteria() 
	DEFINE 
	where_text CHAR(500), 
	msgresp LIKE language.yes_flag 

	LET where_text = "1=1" 
	OPEN WINDOW r156 with FORM "R156" 
	CALL  windecoration_r("R156") 

	LET msgresp = kandoomsg("A",1001,"") 
	#1001 Enter Selection Criteria - ESC TO Continue
	CONSTRUCT BY NAME where_text ON job.cust_code, 
	purchdetl.job_code, 
	purchdetl.var_num, 
	purchdetl.activity_code 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","R13","construct-job-1") -- albo kd-503 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	CLOSE WINDOW r156 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET where_text = NULL 
	END IF 
	RETURN where_text 
END FUNCTION 


