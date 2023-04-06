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

	Source code beautified by beautify.pl on 2020-01-02 10:35:36	$Id: $
}



#  subqwind.4gl:FUNCTION sub_disp_head()
#               DISPLAY subscription header information
#  subqwind.4gl:FUNCTION sub_disp_detl()
#               DISPLAY subscription detail line information
#  subqwind.4gl:FUNCTION sub_detl_line()
#               DISPLAY subscription detail line information
#  subqwind.4gl:FUNCTION disp_sched_issue()
#               DISPLAY subscription issue information

GLOBALS "../common/glob_GLOBALS.4gl" 

#
# DISPLAY Subscription Header Information
#
FUNCTION sub_disp_head(p_cmpy,p_cust_code,p_sub_num) 
	DEFINE p_cmpy LIKE company.cmpy_code
	DEFINE p_cust_code LIKE customer.cust_code 
	DEFINE p_sub_num LIKE subhead.sub_num 
	DEFINE l_msgresp LIKE language.yes_flag
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_subhead RECORD LIKE subhead.* 
	DEFINE l_rec_holdreas RECORD LIKE holdreas.* 
	DEFINE l_rec_arparms RECORD LIKE arparms.* 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_rec_substype RECORD LIKE substype.* 
	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 

	###-Collect AR parameter information
	SELECT * INTO l_rec_arparms.* 
	FROM arparms 
	WHERE cmpy_code = p_cmpy 
	AND parm_code = "1" 
	IF status = notfound THEN 
		LET l_msgresp = kandoomsg("A",9107,"") 
		# 9107 AR Parameters do NOT exist - Refer Menu AZP
		RETURN 
	END IF 
	###-Collect the Subscription Header details
	SELECT * INTO l_rec_subhead.* 
	FROM subhead 
	WHERE cmpy_code = p_cmpy 
	AND cust_code = p_cust_code 
	AND sub_num = p_sub_num 
	###-Collect the Customer details
	SELECT * INTO l_rec_customer.* 
	FROM customer 
	WHERE customer.cust_code = p_cust_code 
	AND customer.cmpy_code = p_cmpy 
	###-Collect the Hold Reason Details
	SELECT * INTO l_rec_holdreas.* FROM holdreas 
	WHERE holdreas.hold_code = l_rec_subhead.hold_code 
	AND cmpy_code = p_cmpy 
	###-Collect the Warehouse details
	SELECT * INTO l_rec_warehouse.* 
	FROM warehouse 
	WHERE cmpy_code = p_cmpy 
	AND ware_code = l_rec_subhead.ware_code 
	###-Collect the Subscription Type details
	SELECT * INTO l_rec_substype.* 
	FROM substype 
	WHERE cmpy_code = p_cmpy 
	AND type_code = l_rec_subhead.sub_type_code 

	#--------------------------------------------------
	# Collect the Salesperson details
	#get sales person record	 
	CALL db_salesperson_get_rec(UI_OFF,l_rec_subhead.sales_code ) RETURNING l_rec_salesperson.*

	OPEN WINDOW subhwind with FORM "K129" 
	CALL windecoration_k("K129") -- albo kd-767 

	DISPLAY BY NAME 
		l_rec_subhead.sub_num, 
		l_rec_subhead.cust_code, 
		l_rec_customer.name_text, 
		l_rec_subhead.last_inv_date, 
		l_rec_subhead.sub_date, 
		l_rec_subhead.ship_code, 
		l_rec_subhead.ship_name_text, 
		l_rec_subhead.ship_addr1_text, 
		l_rec_subhead.ship_addr2_text, 
		l_rec_subhead.ship_city_text, 
		l_rec_subhead.state_code, 
		l_rec_subhead.post_code, 
		l_rec_subhead.country_code, --@db-patch_2020_10_04--
		l_rec_subhead.invoice_to_ind, 
		l_rec_subhead.sub_type_code, 
		l_rec_substype.desc_text, 
		l_rec_subhead.start_date, 
		l_rec_subhead.end_date, 
		l_rec_subhead.ord_text, 
		l_rec_subhead.hold_code, 
		l_rec_holdreas.reason_text, 
		l_rec_subhead.ware_code, 
		l_rec_subhead.sales_code 

	DISPLAY BY NAME l_rec_arparms.inv_ref1_text 
	DISPLAY l_rec_warehouse.desc_text TO ware_text 

	DISPLAY l_rec_salesperson.name_text TO sale_text 

	DISPLAY 
		l_rec_customer.name_text, 
		l_rec_customer.addr1_text, 
		l_rec_customer.addr2_text, 
		l_rec_customer.city_text, 
		l_rec_customer.state_code, 
		l_rec_customer.post_code, 
		l_rec_customer.country_code --@db-patch_2020_10_04--
	TO sr_cust_addr.* 


	IF promptTF("",kandoomsg2("A",8010,""),1) THEN
		CALL sub_disp_detl(p_cmpy,l_rec_subhead.sub_num,l_rec_subhead.cust_code) 
	END IF 

	CLOSE WINDOW subhwind 

	LET int_flag = 0 
	LET quit_flag = 0 

	RETURN 
END FUNCTION 
#
# Subscription DISPLAY Detail Lines
#
FUNCTION sub_disp_detl(p_cmpy,p_sub_num,p_cust_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_sub_num LIKE subhead.sub_num 
	DEFINE p_cust_code LIKE customer.cust_code 
	DEFINE l_msgresp LIKE language.yes_flag
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_rec_subhead RECORD LIKE subhead.* 
	DEFINE l_rec_arparms RECORD LIKE arparms.* 
	DEFINE l_rec_subdetl RECORD LIKE subdetl.*
	DEFINE l_arr_subdetl ARRAY[300] OF RECORD 
		scroll_flag CHAR(1), 
		sub_line_num LIKE subdetl.sub_line_num, 
		part_code LIKE subdetl.part_code, 
		line_text LIKE subdetl.line_text, 
		sub_qty LIKE subdetl.sub_qty, 
		unit_amt LIKE subdetl.unit_amt, 
		line_total_amt LIKE subdetl.line_total_amt 
	END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_desc_text CHAR(30) 
	DEFINE l_tot_freight_amt LIKE subhead.freight_amt 
	DEFINE l_tot_hand_amt LIKE subhead.hand_amt 
	DEFINE i,j SMALLINT

	###-Collect AR parameter information
	SELECT * INTO l_rec_arparms.* 
	FROM arparms 
	WHERE cmpy_code = p_cmpy 
	AND parm_code = "1" 
	IF status = notfound THEN 
		LET l_msgresp = kandoomsg("A",9107,"") 
		# 9107 AR Parameters do NOT exist - Refer Menu AZP
	END IF 
	###-Collect the Subscription Header details
	SELECT * INTO l_rec_subhead.* 
	FROM subhead 
	WHERE cmpy_code = p_cmpy 
	AND cust_code = p_cust_code 
	AND sub_num = p_sub_num 
	###-Collect the Customer details
	SELECT * INTO l_rec_customer.* 
	FROM customer 
	WHERE customer.cust_code = p_cust_code 
	AND customer.cmpy_code = p_cmpy 
	###-Collect the Warehouse details
	SELECT * INTO l_rec_warehouse.* 
	FROM warehouse 
	WHERE cmpy_code = p_cmpy 
	AND ware_code = l_rec_subhead.ware_code 
	###-Collect the Tax details
	SELECT desc_text INTO l_desc_text 
	FROM tax 
	WHERE cmpy_code = p_cmpy 
	AND tax_code = l_rec_subhead.tax_code 
	OPEN WINDOW subdwind with FORM "K140" 
	CALL windecoration_k("K140") -- albo kd-767 
	LET l_tot_freight_amt = l_rec_subhead.freight_amt + l_rec_subhead.freight_tax_amt 
	LET l_tot_hand_amt = l_rec_subhead.hand_amt + l_rec_subhead.hand_tax_amt 
	###-DISPLAY TO SCREEN
	DISPLAY BY NAME l_rec_subhead.goods_amt, 
	l_rec_subhead.tax_amt, 
	l_rec_subhead.total_amt 
	attribute(yellow) 
	DISPLAY l_tot_freight_amt, 
	l_tot_hand_amt 
	TO freight_amt, 
	hand_amt 
	attribute(yellow) 
	DISPLAY BY NAME l_rec_customer.cred_bal_amt, 
	l_rec_subhead.tax_code, 
	l_rec_warehouse.ware_code 

	DISPLAY l_desc_text TO tax.desc_text 

	DISPLAY BY NAME l_rec_subhead.cust_code, 
	l_rec_customer.name_text, 
	l_rec_subhead.tax_code, 
	l_rec_subhead.goods_amt, 
	l_rec_subhead.tax_amt, 
	l_rec_subhead.total_amt 

	DISPLAY BY NAME l_rec_warehouse.desc_text 

	DISPLAY BY NAME l_rec_subhead.currency_code 
	attribute(green) 
	DECLARE c1_subdetl CURSOR FOR 
	SELECT * FROM subdetl 
	WHERE cmpy_code = p_cmpy 
	AND cust_code = p_cust_code 
	AND sub_num = p_sub_num 
	ORDER BY sub_line_num 
	LET l_idx = 0 
	FOREACH c1_subdetl INTO l_rec_subdetl.* 
		LET l_idx = l_idx + 1 
		LET l_rec_subdetl.ware_code = l_rec_warehouse.ware_code 
		LET l_arr_subdetl[l_idx].sub_line_num = l_rec_subdetl.sub_line_num 
		LET l_arr_subdetl[l_idx].part_code = l_rec_subdetl.part_code 
		LET l_arr_subdetl[l_idx].line_text = l_rec_subdetl.line_text 
		LET l_arr_subdetl[l_idx].sub_qty = l_rec_subdetl.sub_qty 
		LET l_arr_subdetl[l_idx].unit_amt = l_rec_subdetl.unit_amt 
		IF l_rec_arparms.show_tax_flag = "Y" THEN 
			LET l_arr_subdetl[l_idx].line_total_amt = l_rec_subdetl.line_total_amt 
		ELSE 
			LET l_arr_subdetl[l_idx].line_total_amt =l_rec_subdetl.unit_amt * 
			l_rec_subdetl.sub_qty 
		END IF 
	END FOREACH 
	CALL set_count(l_idx) 
	LET l_msgresp = kandoomsg("K","1008","") 

	#1008 F3/F4 TO ...
	DISPLAY ARRAY l_arr_subdetl TO sr_subdetl.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","subqwind","display-arr-subdetl") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON KEY (tab) 
			LET l_idx = arr_curr() 
			CALL sub_detl_line(p_cmpy,p_sub_num, 
			l_arr_subdetl[l_idx].part_code, 
			l_arr_subdetl[l_idx].sub_line_num) 
		ON KEY (RETURN) 
			LET l_idx = arr_curr() 
			CALL sub_detl_line(p_cmpy,p_sub_num, 
			l_arr_subdetl[l_idx].part_code, 
			l_arr_subdetl[l_idx].sub_line_num) 

	END DISPLAY 
	CLOSE WINDOW subdwind 
	LET int_flag = 0 
	LET quit_flag = 0 
	RETURN 
END FUNCTION 
#
# Subscription Detail Lines Display
#
FUNCTION sub_detl_line(p_cmpy,p_sub_num,p_part_code,p_sub_line) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_sub_num LIKE subhead.sub_num 
	DEFINE p_part_code LIKE subdetl.part_code 
	DEFINE p_sub_line LIKE subdetl.sub_line_num 
	DEFINE l_msgresp LIKE language.yes_flag
	DEFINE l_ware_text LIKE warehouse.desc_text 
	DEFINE l_rec_subhead RECORD LIKE subhead.* 
	DEFINE l_rec_subdetl RECORD LIKE subdetl.* 
	DEFINE l_sched LIKE subproduct.linetype_ind 

	OPEN WINDOW k135 with FORM "K135" 
	CALL windecoration_k("K135") -- albo kd-767 
	###- Collect the Sub Header Details
	SELECT * INTO l_rec_subhead.* 
	FROM subhead 
	WHERE sub_num = p_sub_num 
	AND cmpy_code = p_cmpy 
	###-Collect the Sub Detail Line details
	SELECT * INTO l_rec_subdetl.* 
	FROM subdetl 
	WHERE sub_num = p_sub_num 
	AND sub_line_num = p_sub_line 
	AND cmpy_code = p_cmpy 
	###- Collect the Sub Product details
	SELECT linetype_ind INTO l_sched 
	FROM subproduct 
	WHERE part_code = p_part_code 
	AND type_code = l_rec_subhead.sub_type_code 
	AND cmpy_code = p_cmpy 
	###- Collect the warehouse details
	SELECT desc_text INTO l_ware_text 
	FROM warehouse 
	WHERE ware_code = l_rec_subdetl.ware_code 
	AND cmpy_code = p_cmpy 
	DISPLAY BY NAME l_rec_subdetl.line_text, 
	l_rec_subdetl.ware_code, 
	l_rec_subdetl.sub_qty, 
	l_rec_subdetl.issue_qty, 
	l_rec_subdetl.inv_qty, 
	l_rec_subdetl.level_code, 
	l_rec_subdetl.unit_amt, 
	l_rec_subdetl.unit_tax_amt, 
	l_rec_subdetl.line_total_amt, 
	l_rec_subdetl.part_code 

	###- IF the sub product IS scheduled THEN make available schedule details
	###- ELSE prompt any key TO continue
	IF l_sched = 1 THEN 
		###- scheduled product - PREPARE MESSAGE TO DISPLAY the schedule issues
		IF promptTF("",kandoomsg2("K",8021,""),1) THEN
			CALL disp_sched_issue(p_cmpy,p_sub_num, 
			l_rec_subdetl.part_code,p_sub_line) 
		END IF 
	ELSE 
		LET l_msgresp = kandoomsg("K",8020,"") 
	END IF 
	CLOSE WINDOW k135 
	LET int_flag = 0 
	LET quit_flag = 0 
	RETURN 
END FUNCTION 
#
# Subscription Detail Lines Display
#
FUNCTION disp_sched_issue(p_cmpy,p_sub_num,p_part_code,p_sub_line) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_sub_num LIKE subhead.sub_num 
	DEFINE p_part_code LIKE subdetl.part_code 
	DEFINE p_sub_line LIKE subdetl.sub_line_num 
	DEFINE l_msgresp LIKE language.yes_flag
	DEFINE l_rec_subhead RECORD LIKE subhead.* 
	DEFINE l_rec_subschedule RECORD LIKE subschedule.* 
	DEFINE l_arr_subschedule ARRAY[300] OF RECORD
		scroll_flag CHAR(1), 
		issue_num SMALLINT, 
		desc_text CHAR(40), 
		sched_qty FLOAT, 
		issue_qty FLOAT, 
		inv_qty FLOAT, 
		sched_date DATE 
	END RECORD 
	DEFINE l_part_desc LIKE product.desc_text 
	DEFINE l_idx SMALLINT 

	OPEN WINDOW k131 with FORM "K131" 
	CALL windecoration_k("K131") -- albo kd-767 
	LET l_msgresp = kandoomsg("U",1002,"") 
	#1002 Searching database please wait
	###- Collect Sub Head details
	SELECT * INTO l_rec_subhead.* 
	FROM subhead 
	WHERE subhead.sub_num = p_sub_num 
	AND cmpy_code = p_cmpy 
	###- Collect Part Description
	SELECT desc_text INTO l_part_desc 
	FROM subproduct 
	WHERE cmpy_code = p_cmpy 
	AND part_code = p_part_code 
	AND type_code = l_rec_subhead.sub_type_code 
	DECLARE c_subschedule CURSOR FOR 
	SELECT * 
	FROM subschedule 
	WHERE sub_line_num = p_sub_line 
	AND sub_num = l_rec_subhead.sub_num 
	AND part_code = p_part_code 
	ORDER BY issue_num 
	LET l_idx = 0 
	FOREACH c_subschedule INTO l_rec_subschedule.* 
		SELECT * FROM subissues 
		WHERE cmpy_code = p_cmpy 
		AND part_code = p_part_code 
		AND issue_num = l_rec_subschedule.issue_num 
		AND plan_iss_date between l_rec_subhead.start_date 
		AND l_rec_subhead.end_date 
		LET l_idx = l_idx + 1 
		LET l_arr_subschedule[l_idx].issue_num = l_rec_subschedule.issue_num 
		LET l_arr_subschedule[l_idx].sched_qty = l_rec_subschedule.sched_qty 
		LET l_arr_subschedule[l_idx].issue_qty = l_rec_subschedule.issue_qty 
		LET l_arr_subschedule[l_idx].inv_qty = l_rec_subschedule.inv_qty 
		LET l_arr_subschedule[l_idx].sched_date = l_rec_subschedule.sched_date 
		LET l_arr_subschedule[l_idx].desc_text = l_rec_subschedule.desc_text 
		IF l_idx = 300 THEN 
			EXIT FOREACH 
		END IF 
	END FOREACH 
	LET l_msgresp = kandoomsg("U",1008,"") 
	# 1008 F3/F4 TO ...ESC TO Continue
	CALL set_count(l_idx) 
	DISPLAY p_part_code , 
	l_part_desc, 
	l_rec_subhead.start_date, 
	l_rec_subhead.end_date 
	TO part_code, 
	part_text, 
	start_date, 
	end_date 

	DISPLAY ARRAY l_arr_subschedule TO sr_subschedule.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","subqwind","display-arr-subschedule") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


	END DISPLAY 
	CLOSE WINDOW k131 
	RETURN 
END FUNCTION 


