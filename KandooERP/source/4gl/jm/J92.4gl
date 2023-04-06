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

	Source code beautified by beautify.pl on 2020-01-02 19:48:15	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 

{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module J92.4gl Inquire on a job issue FROM inventory

GLOBALS 

	DEFINE 
	pr_glparms RECORD LIKE glparms.*, 
	pr_jmparms RECORD LIKE jmparms.*, 
	pr_job RECORD LIKE job.*, 
	pr_jobvars RECORD LIKE jobvars.*, 
	pr_activity RECORD LIKE activity.*, 
	pr_customer RECORD LIKE customer.*, 
	pr_jobledger RECORD LIKE jobledger.*, 
	pr_prodledg RECORD LIKE prodledg.*, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pr_product RECORD LIKE product.*, 
	pr_warehouse RECORD LIKE warehouse.*, 
	pr_jmresource RECORD LIKE jmresource.*, 
	ans CHAR(1), 
	err_continue CHAR(1), 
	exist SMALLINT, 
	where_text, query_text CHAR(1200), 
	err_message CHAR(40), 
	cnt SMALLINT 
END GLOBALS 


MAIN 
	#Initial UI Init
	CALL setModuleId("J92") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	SELECT jmparms.* 
	INTO pr_jmparms.* 
	FROM jmparms 
	WHERE jmparms.cmpy_code = glob_rec_kandoouser.cmpy_code AND 
	jmparms.key_code = "1" 
	IF status = notfound THEN 
		ERROR " Must SET up JM Parameters first in JZP" 
		SLEEP 5 
		EXIT program 
	END IF 
	SELECT glparms.* 
	INTO pr_glparms.* 
	FROM glparms 
	WHERE glparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND glparms.key_code = "1" 
	IF status = notfound THEN 
		ERROR " Must SET up GL Parameters first in GZP" 
		SLEEP 5 
		EXIT program 
	END IF 
	OPEN WINDOW j152a with FORM "J152a" -- alch kd-747 
	CALL winDecoration_j("J152a") -- alch kd-747 
	IF num_args() > 0 THEN 
		IF select_issue() THEN 
			CALL display_issue() 
			CALL query() 
		END IF 
	ELSE 
		CALL query() 
	END IF 
	LET int_flag = false 
	LET quit_flag = false 
	CLOSE WINDOW j152a 
END MAIN 


FUNCTION select_issue() 
	WHILE true 
		CLEAR FORM 
		LET exist = false 
		IF num_args() > 0 THEN 
			LET where_text = arg_val(1) clipped," ",arg_val(2) 
		ELSE 
			LET msgresp = kandoomsg("J",1001,"") 
			# 1002 Searching database - please wait"
			CONSTRUCT BY NAME where_text ON 
			jobledger.job_code, 
			jobledger.var_code, 
			jobledger.activity_code, 
			jobledger.trans_date, 
			jobledger.year_num, 
			jobledger.period_num, 
			prodledg.part_code 
				BEFORE CONSTRUCT 
					CALL publish_toolbar("kandoo","J92","const-job_code-5") -- alch kd-506 
				ON ACTION "WEB-HELP" -- albo kd-373 
					CALL onlinehelp(getmoduleid(),null) 
			END CONSTRUCT 

			IF int_flag OR quit_flag THEN 
				RETURN false 
			END IF 
		END IF 
		IF num_args() = 0 THEN 
			LET msgresp = kandoomsg("J",1002,"") 
			# 1002 Searching database - please wait"
		END IF 
		LET query_text = 
		"SELECT * ", 
		" FROM jobledger, ", 
		" prodledg,", 
		" product ", 
		" WHERE jobledger.cmpy_code =\"", glob_rec_kandoouser.cmpy_code, "\"", 
		" AND prodledg.cmpy_code = jobledger.cmpy_code ", 
		" AND prodledg.part_code = jobledger.desc_text[1,15] ", 
		" AND prodledg.trantype_ind = \"J\" ", 
		" AND prodledg.source_num = jobledger.trans_source_num ", 
		" AND product.part_code = prodledg.part_code ", 
		" AND product.cmpy_code = prodledg.cmpy_code ", 
		" AND ", where_text clipped 
		PREPARE q_1 FROM query_text 
		DECLARE q_2 SCROLL CURSOR FOR q_1 
		OPEN q_2 
		FETCH q_2 
		INTO pr_jobledger.*, 
		pr_prodledg.*, 
		pr_product.* 
		IF status = notfound THEN 
			IF num_args() <= 0 THEN 
				ERROR "No Product Issues Selected - Please Re-SELECT." 
			END IF 
			IF num_args() > 0 THEN 
				ERROR "No Product Issues Selected." 
				SLEEP 5 
				EXIT program 
			END IF 
		ELSE 
			LET exist = true 
			EXIT WHILE 
		END IF 
	END WHILE 
	RETURN true 
END FUNCTION 


FUNCTION query() 
	IF num_args() = 0 THEN 
		MENU " Issues" 
			BEFORE MENU 
				CALL publish_toolbar("kandoo","J92","menu-issues-1") -- alch kd-506 
			ON ACTION "WEB-HELP" -- albo kd-373 
				CALL onlinehelp(getmoduleid(),null) 
			COMMAND "Query" " Search FOR Inventory Issues " 
				IF num_args() = 0 THEN 
					IF select_issue() THEN 
						CALL display_issue() 
					ELSE 
						LET int_flag = false 
						LET quit_flag = false 
					END IF 
				END IF 
			COMMAND KEY ("N",f21) "Next" " DISPLAY next selected issue" 
				IF exist THEN 
					FETCH NEXT q_2 
					INTO pr_jobledger.*, 
					pr_prodledg.*, 
					pr_product.* 
					IF status <> notfound THEN 
						CALL display_issue() 
					ELSE 
						ERROR "You have reached the END of the issues selected" 
					END IF 
				ELSE 
					ERROR "You have TO make a selection first" 
				END IF 
			COMMAND KEY ("P",f19) "Previous" " DISPLAY previous selected issue" 
				IF exist THEN 
					FETCH previous q_2 
					INTO pr_jobledger.*, 
					pr_prodledg.*, 
					pr_product.* 
					IF status <> notfound THEN 
						CALL display_issue() 
					ELSE 
						ERROR "You have reached the start of the issues selected" 
					END IF 
				ELSE 
					ERROR "You have TO make a selection first" 
				END IF 
			COMMAND KEY ("F",f18) "First" " DISPLAY first issue in the selected list" 
				IF exist THEN 
					FETCH FIRST q_2 
					INTO pr_jobledger.*, 
					pr_prodledg.*, 
					pr_product.* 
					IF status <> notfound THEN 
						CALL display_issue() 
					ELSE 
						ERROR "You have reached the start of the issues selected" 
					END IF 
				ELSE 
					ERROR "You have TO make a selection first" 
				END IF 
			COMMAND KEY ("L",f22) "Last" " DISPLAY last issue in the selected list" 
				IF exist THEN 
					FETCH LAST q_2 
					INTO pr_jobledger.*, 
					pr_prodledg.*, 
					pr_product.* 
					IF status <> notfound THEN 
						CALL display_issue() 
					ELSE 
						ERROR "You have reached the END of the issues selected" 
					END IF 
				ELSE 
					ERROR "You have TO make a selection first" 
				END IF 
			COMMAND KEY(interrupt,"E")"Exit" " RETURN TO the menus" 
				EXIT MENU 
			COMMAND KEY (control-w) 
				CALL kandoohelp("") 
		END MENU 
	ELSE 
		LET msgresp = kandoomsg("J",7001,"") 
		# 7001 Any Key TO Continue
	END IF 
END FUNCTION 


FUNCTION display_issue() 
	DEFINE 
	pr_pricex_amt DECIMAL(10,4), 
	pr_bill_way_text CHAR(11) 

	SELECT job.* 
	INTO pr_job.* 
	FROM job 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND job_code = pr_jobledger.job_code 
	SELECT customer.* 
	INTO pr_customer.* 
	FROM customer 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cust_code = pr_job.cust_code 
	SELECT jobvars.* 
	INTO pr_jobvars.* 
	FROM jobvars 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND job_code = pr_jobledger.job_code 
	AND var_code = pr_jobledger.var_code 
	SELECT activity.* 
	INTO pr_activity.* 
	FROM activity 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND job_code = pr_jobledger.job_code 
	AND var_code = pr_jobledger.var_code 
	AND activity_code = pr_jobledger.activity_code 
	SELECT warehouse.* 
	INTO pr_warehouse.* 
	FROM warehouse 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ware_code = pr_prodledg.ware_code 
	SELECT jmresource.* 
	INTO pr_jmresource.* 
	FROM jmresource 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND res_code = pr_jobledger.trans_source_text 
	SELECT prodstatus.* 
	INTO pr_prodstatus.* 
	FROM prodstatus 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_prodledg.part_code 
	AND ware_code = pr_prodledg.ware_code 
	CASE pr_activity.bill_way_ind 
		WHEN "F" 
			LET pr_bill_way_text = "Fixed Price" 
		WHEN "C" 
			LET pr_bill_way_text = "Cost Plus " 
		WHEN "T" 
			LET pr_bill_way_text = "Time & Mtls" 
		OTHERWISE 
			LET pr_bill_way_text = "Unknown" 
	END CASE 
	CASE 
		WHEN pr_customer.inv_level_ind = "L" 
			LET pr_pricex_amt = pr_prodstatus.list_amt 
		WHEN pr_customer.inv_level_ind = "1" 
			LET pr_pricex_amt = pr_prodstatus.price1_amt 
		WHEN pr_customer.inv_level_ind = "2" 
			LET pr_pricex_amt = pr_prodstatus.price2_amt 
		WHEN pr_customer.inv_level_ind = "3" 
			LET pr_pricex_amt = pr_prodstatus.price3_amt 
		WHEN pr_customer.inv_level_ind = "4" 
			LET pr_pricex_amt = pr_prodstatus.price4_amt 
		WHEN pr_customer.inv_level_ind = "5" 
			LET pr_pricex_amt = pr_prodstatus.price5_amt 
		WHEN pr_customer.inv_level_ind = "6" 
			LET pr_pricex_amt = pr_prodstatus.price6_amt 
		WHEN pr_customer.inv_level_ind = "7" 
			LET pr_pricex_amt = pr_prodstatus.price7_amt 
		WHEN pr_customer.inv_level_ind = "8" 
			LET pr_pricex_amt = pr_prodstatus.price8_amt 
		WHEN pr_customer.inv_level_ind = "9" 
			LET pr_pricex_amt = pr_prodstatus.price9_amt 
		OTHERWISE 
			LET pr_pricex_amt = 0 
	END CASE 
	DISPLAY BY NAME 
	pr_jobledger.job_code, 
	pr_customer.cust_code, 
	pr_customer.name_text, 
	pr_jobledger.var_code, 
	pr_jobledger.activity_code, 
	pr_jobledger.trans_date, 
	pr_jobledger.year_num, 
	pr_jobledger.period_num, 
	pr_jobledger.posted_flag, 
	pr_prodledg.part_code, 
	pr_prodledg.ware_code, 
	pr_jmresource.res_code, 
	pr_customer.inv_level_ind, 
	pr_product.sell_uom_code, 
	pr_activity.unit_code, 
	pr_jobledger.trans_qty, 
	pr_prodstatus.wgted_cost_amt, 
	pr_jobledger.trans_amt, 
	pr_jobledger.charge_amt 

	DISPLAY pr_job.title_text, 
	pr_jobvars.title_text, 
	pr_activity.title_text, 
	pr_product.desc_text, 
	pr_warehouse.desc_text, 
	pr_jmresource.desc_text, 
	pr_pricex_amt, 
	pr_bill_way_text 
	TO job_title_text, 
	jobvars_title_text, 
	activity_title_text, 
	product_desc_text, 
	warehouse_desc_text, 
	jmresource_desc_text, 
	pricex_amt, 
	bill_way_text 

END FUNCTION 
