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
# \file
# \brief module KA1 : Generates tentative renewals FOR
#                  automatic renewal type subscriptions
#                  substype.renew_flag = "Y"
#
#    K11 modules are linked in FOR modification AND UPDATE functions
#    IF renewals are FROM a corporate entry THEN this program will also
#    a single invoice FOR subs with a common corp_cust_code as per K15.

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "K_SS_GLOBALS.4gl" 
GLOBALS "K11_GLOBALS.4gl" 

DEFINE 
winds_text CHAR(40), 
pr_subcustomer RECORD LIKE subcustomer.*, 
pr_substype RECORD LIKE substype.*, 
pr_tentsubhead RECORD LIKE tentsubhead.*, 
pr_tentsubdetl RECORD LIKE tentsubdetl.*, 
pr_subdetl RECORD LIKE subdetl.*, 
idx SMALLINT, 
pr_start_year,pr_end_year SMALLINT, 
total_cost,total_sale,total_tax DECIMAL(16,2), 
where_text,query_text CHAR(800), 
pr_output1, pr_output2 CHAR(40), 
pr_tot_amt DECIMAL(16,2), 
pr_price_ind CHAR(1), 
pr_rowid INTEGER 

MAIN 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFER quit 
	DEFER interrupt
	
	CALL setModuleId("KA1") -- albo 
	CALL ui_init(0) #Initial UI Init 
	CALL authenticate(getmoduleid()) 


	SELECT * INTO pr_company.* 
	FROM company 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	CALL create_table("subhead","t_subhead","","N") 
	CALL create_table("subdetl","t_subdetl","","N") 
	CALL create_table("subschedule","t_subschedule","","N") 
	CALL create_table("invoicedetl","t_invoicedetl","","N") 
	CALL create_table("cashreceipt","t_cashreceipt","","N") 
	
	OPEN WINDOW K157  WITH FORM "K157" 
	attribute(border) 
	
	MENU " Subscription renewals" 
		BEFORE MENU 
			SELECT unique 1 FROM tentsubhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = notfound THEN 
				HIDE option "Modify" 
				HIDE option "Report" 
				HIDE option "UPDATE" 
			ELSE 
			SHOW option "Modify" 
			SHOW option "Report" 
			SHOW option "UPDATE" 
		END IF 
		
		ON ACTION "WEB-HELP" -- albo kd-374 
			CALL onlinehelp(getmoduleid(),null) 
			
		COMMAND "Generate" " Generate Tentative renewals" 
			IF select_newsubs() THEN 
				CALL scan_newsubs() 
			END IF 
			SELECT unique 1 FROM tentsubhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = notfound THEN 
				HIDE option "Modify" 
				HIDE option "Report" 
				HIDE option "UPDATE" 
			ELSE 
			SHOW option "Modify" 
			SHOW option "Report" 
			SHOW option "UPDATE" 
			NEXT option "Modify" 
		END IF 
		
		COMMAND "Edit" " Edit Proposed subscriptions" 
			OPEN WINDOW k158 at 3,4 WITH FORM "K158" 
			attribute(border) 
			WHILE select_tentsubs() 
				CALL scan_tentsubs() 
			END WHILE 
			CLOSE WINDOW k158 
			NEXT option "Report" 
			
		COMMAND "Report" " Report on Proposed subscriptions" 
			LET rpt_date = today 
			LET rpt_time = time 
			OPEN WINDOW k158 at 2,3 WITH FORM "K158" 
			attribute(border) 
			WHILE select_tentsubs() 
				CALL rep_tentsubs() 
				EXIT WHILE 
			END WHILE 
			CLOSE WINDOW k158 
			NEXT option "PRINT MANAGER" 
			
		COMMAND "UPDATE" " Create Proposed subscriptions" 
			LET rpt_date = today 
			LET rpt_time = time 
			IF kandoomsg("K",8019,"") = "Y" THEN 

	#------------------------------------------------------------
	#OK
	LET l_rpt_idx = rpt_start("KA1-OK","KA1_rpt_list_subscription","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT KA1_rpt_list_subscription TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num

	#------------------------------------------------------------

	#------------------------------------------------------------
	#ERROR
	LET l_rpt_idx = rpt_start("KA1-OK","KA1_rpt_list_error","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT KA1_rpt_list_error TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num

	#------------------------------------------------------------


				CALL write_subs() 

				#------------------------------------------------------------
				FINISH REPORT KA1_rpt_list_error
				CALL rpt_finish("KA1_rpt_list_error")
				#------------------------------------------------------------

				#------------------------------------------------------------
				FINISH REPORT KA1_rpt_list_subscription
				CALL rpt_finish("KA1_rpt_list_subscription")
				#------------------------------------------------------------
			END IF 

		ON ACTION "PRINT MANAGER"		#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS "
			CALL run_prog("URS","","","","") 

		COMMAND KEY("E",interrupt)"Exit" " EXIT TO menus" 
			EXIT MENU 
	END MENU 

	CLOSE WINDOW K157 
END MAIN 


FUNCTION select_newsubs() 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE tmp_text CHAR(500) 

	SELECT unique 1 FROM tentsubhead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = 0 THEN 
		LET msgresp = kandoomsg("K",8017,"") 
		IF msgresp = "Y" THEN 
			LET msgresp = kandoomsg("K",1016,"") 
			DELETE FROM tentsubhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			DELETE FROM tentsubdetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			DELETE FROM tentsubschd 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		ELSE 
		RETURN false 
	END IF 
END IF 
LET msgresp = kandoomsg("U",1020,"Subscription Generation") 
#1020 Enter Subscription Generation Details
INITIALIZE pr_tentsubhead.* TO NULL 
LET pr_tentsubhead.sub_date = today 
INPUT BY NAME pr_tentsubhead.sub_type_code, 
pr_tentsubhead.sub_date, 
pr_tentsubhead.start_date, 
pr_tentsubhead.end_date, 
pr_price_ind, 
pr_tentsubhead.com1_text, 
pr_tentsubhead.com2_text 
WITHOUT DEFAULTS 

	ON ACTION "WEB-HELP" -- albo kd-374 
		CALL onlinehelp(getmoduleid(),null) 

	ON KEY (control-b) 
		CASE 
			WHEN infield(sub_type_code) 
				LET tmp_text = show_substype(glob_rec_kandoouser.cmpy_code,"renew_flag = 'Y'") 
				IF tmp_text IS NOT NULL THEN 
					LET pr_tentsubhead.sub_type_code = tmp_text 
				END IF 
				NEXT FIELD sub_type_code 
		END CASE 
	AFTER FIELD sub_type_code 
		IF pr_tentsubhead.sub_type_code IS NULL THEN 
			LET msgresp = kandoomsg("U",9102,"") 
			#9102 Value must be entered
			NEXT FIELD sub_type_code 
		END IF 
		SELECT * INTO pr_substype.* 
		FROM substype 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND type_code = pr_tentsubhead.sub_type_code 
		AND renew_flag = "Y" 
		IF status = notfound THEN 
			LET msgresp = kandoomsg("U",9105,"") 
			#9105 RECORD NOT found - try window
			NEXT FIELD sub_type_code 
		ELSE 
		DISPLAY BY NAME pr_substype.desc_text 

	END IF 
	AFTER FIELD sub_date 
		IF pr_tentsubhead.sub_date IS NULL THEN 
			LET pr_tentsubhead.sub_date = today 
			NEXT FIELD sub_date 
		ELSE 
		LET pr_start_year = year(pr_tentsubhead.sub_date) 
		IF month(pr_tentsubhead.sub_date) < pr_substype.start_mth_num THEN 
			LET pr_start_year = pr_start_year - 1 
		END IF 
		LET pr_end_year = pr_start_year 
		IF pr_substype.start_mth_num > pr_substype.end_mth_num THEN 
			LET pr_end_year = pr_end_year + 1 
		END IF 
		LET pr_tentsubhead.start_date = mdy(pr_substype.start_mth_num, 
		pr_substype.start_day_num, 
		pr_start_year) 
		LET pr_tentsubhead.end_date = mdy(pr_substype.end_mth_num, 
		pr_substype.end_day_num, 
		pr_end_year) 
		DISPLAY BY NAME pr_tentsubhead.start_date, 
		pr_tentsubhead.end_date 

	END IF 
	AFTER FIELD start_date 
		IF pr_tentsubhead.start_date IS NULL THEN 
			LET msgresp = kandoomsg("U",9102,"") 
			#9102 Value must be entered
			NEXT FIELD start_date 
		END IF 
	AFTER FIELD end_date 
		IF pr_tentsubhead.end_date IS NULL THEN 
			LET msgresp = kandoomsg("U",9102,"") 
			#9102 Value must be entered
			NEXT FIELD end_date 
		END IF 
		IF pr_tentsubhead.end_date < pr_tentsubhead.start_date THEN 
			LET msgresp = kandoomsg("K",9105,"") 
			#9105 Value must be entered
			NEXT FIELD start_date 
		END IF 
	AFTER INPUT 
		IF not(int_flag OR quit_flag) THEN 
			IF pr_tentsubhead.sub_type_code IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD sub_type_code 
			END IF 
			IF pr_tentsubhead.sub_date IS NULL THEN 
				LET pr_tentsubhead.sub_date = today 
			END IF 
			IF pr_tentsubhead.start_date IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD start_date 
			END IF 
			IF pr_tentsubhead.end_date IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD end_date 
			END IF 
		END IF 
	ON KEY (control-w) 
		CALL kandoohelp("") 
END INPUT 
IF int_flag OR quit_flag THEN 
	LET int_flag = false 
	LET quit_flag = false 
	RETURN false 
END IF 
RETURN true 
END FUNCTION 


FUNCTION scan_newsubs() 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE pr_cust,pr_ship LIKE subhead.cust_code 

	LET msgresp = kandoomsg("U",1001,"") 
	#Enter selection criteria
	CONSTRUCT BY NAME where_text ON subcustomer.cust_code, 
	customer.name_text, 
	subcustomer.ship_code, 
	customer.type_code, 
	customer.state_code 

		ON ACTION "WEB-HELP" -- albo kd-374 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 
	END IF 
	LET msgresp = kandoomsg("U",1002,"") 
	#Searching database
	LET query_text = "SELECT subcustomer.* ", 
	" FROM subcustomer,customer ", 
	" WHERE subcustomer.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND subcustomer.sub_type_code = '", 
	pr_tentsubhead.sub_type_code,"' ", 
	" AND customer.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND subcustomer.cust_code = customer.cust_code ", 
	" AND year(subcustomer.comm_date) = ", 
	(year(pr_tentsubhead.start_date) -1), 
	" AND ",where_text clipped, 
	" ORDER BY subcustomer.cust_code,subcustomer.ship_code" 
	PREPARE s_subcustomer FROM query_text 
	DECLARE c_subcustomer CURSOR FOR s_subcustomer 

	OPEN WINDOW wka1 at 10,15 WITH 2 ROWS, 50 COLUMNS 
	attribute(border) 
	##############################################################
	# This CURSOR checks FOR a valid subhead FOR the previous year
	# IF nothing IS found THEN we wont create a new one
	##############################################################
	DECLARE c_subhead CURSOR FOR 
	SELECT * FROM subhead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND sub_type_code = pr_subcustomer.sub_type_code 
	AND cust_code = pr_subcustomer.cust_code 
	AND ship_code = pr_subcustomer.ship_code 
	AND start_date = pr_subcustomer.comm_date 
	##############################################################
	# This CURSOR checks TO see IF a new sub already exists
	# IF it does THEN we wont create another new one
	##############################################################
	DECLARE c2_subhead CURSOR FOR 
	SELECT * FROM subhead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND sub_type_code = pr_subcustomer.sub_type_code 
	AND cust_code = pr_subcustomer.cust_code 
	AND ship_code = pr_subcustomer.ship_code 
	AND start_date = pr_tentsubhead.start_date 
	DISPLAY "Customer : " at 1,2 
	DISPLAY "Subscrip : " at 2,2 
	LET pr_cust = NULL 
	LET pr_ship = NULL 
	LET idx = 0 
	LET pr_rowid = 0 
	FOREACH c_subcustomer INTO pr_subcustomer.* 
		DISPLAY pr_subcustomer.part_code at 2,12 
		IF pr_cust IS NULL OR 
		pr_ship IS NULL OR 
		pr_cust <> pr_subcustomer.cust_code OR 
		pr_ship <> pr_subcustomer.ship_code THEN 
			IF idx > 0 THEN 
				CALL update_tenthead(pr_rowid) 
			END IF 
			LET idx = 0 
			OPEN c2_subhead 
			FETCH c2_subhead INTO pr_subhead.* 
			IF status = 0 THEN 
				CLOSE c2_subhead 
				CONTINUE FOREACH 
			END IF 
			CLOSE c2_subhead 
			OPEN c_subhead 
			FETCH c_subhead INTO pr_subhead.* 
			IF status = notfound THEN 
				CLOSE c_subhead 
				CONTINUE FOREACH 
			END IF 
			CLOSE c_subhead 
			DISPLAY pr_subhead.ship_name_text at 1,12 
			CALL insert_tenthead() 
			IF pr_rowid = 0 THEN 
				CONTINUE FOREACH 
			END IF 
		END IF 
		CALL insert_tentdetl() 
		LET pr_cust = pr_subcustomer.cust_code 
		LET pr_ship = pr_subcustomer.ship_code 
	END FOREACH 
	IF idx > 0 THEN 
		CALL update_tenthead(pr_rowid) 
	END IF 
	CLOSE WINDOW wka1 
END FUNCTION 

FUNCTION insert_tentdetl() 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE pr_tentsubdetl RECORD LIKE tentsubdetl.*, 
	pr_tentsubschd RECORD LIKE tentsubschd.*, 
	pr_subissues RECORD LIKE subissues.*, 
	pr_product RECORD LIKE product.*, 
	pr_subproduct RECORD LIKE subproduct.*, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pr_unit_amt DECIMAL(16,4) 

	SELECT count(*) INTO pr_tentsubdetl.sub_qty 
	FROM subissues 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_subcustomer.part_code 
	AND plan_iss_date between pr_tentsubhead.start_date 
	AND pr_tentsubhead.end_date 
	AND issue_num >= last_issue_num 
	IF pr_tentsubdetl.sub_qty = 0 THEN 
		RETURN 
	END IF 
	SELECT * INTO pr_subproduct.* 
	FROM subproduct 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_subcustomer.part_code 
	AND type_code = pr_subcustomer.sub_type_code 
	LET idx = idx + 1 
	DECLARE c_subissue CURSOR FOR 
	SELECT * FROM subissues 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_subcustomer.part_code 
	AND plan_iss_date between pr_tentsubhead.start_date 
	AND pr_tentsubhead.end_date 
	AND issue_num >= last_issue_num 
	FOREACH c_subissue INTO pr_subissues.* 
		LET pr_tentsubschd.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pr_tentsubschd.sub_num = pr_rowid 
		LET pr_tentsubschd.sub_line_num = idx 
		LET pr_tentsubschd.issue_num = pr_subissues.issue_num 
		LET pr_tentsubschd.sched_qty = 1 
		LET pr_tentsubschd.issue_qty = 0 
		LET pr_tentsubschd.inv_qty = 0 
		LET pr_tentsubschd.sched_date = pr_subissues.plan_iss_date 
		LET pr_tentsubschd.desc_text = pr_subissues.desc_text 
		INSERT INTO tentsubschd VALUES (pr_tentsubschd.*) 
	END FOREACH 
	LET pr_tentsubdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET pr_tentsubdetl.sub_num = pr_rowid 
	LET pr_tentsubdetl.part_code = pr_subcustomer.part_code 
	LET pr_tentsubdetl.cust_code =pr_subcustomer.cust_code 
	LET pr_tentsubdetl.sub_line_num = idx 
	LET pr_tentsubdetl.level_code = pr_customer.inv_level_ind 
	LET pr_tentsubdetl.tax_code = pr_subhead.tax_code 
	LET pr_tentsubdetl.ware_code =pr_subhead.ware_code 
	LET pr_tentsubdetl.issue_qty = 0 
	LET pr_tentsubdetl.inv_qty = 0 
	LET pr_tentsubdetl.line_text =pr_subproduct.desc_text 
	LET pr_subhead.start_date = pr_tentsubhead.start_date 
	CASE 
		WHEN pr_price_ind = "0" 
			LET pr_unit_amt = unit_price(pr_tentsubdetl.ware_code, 
			pr_tentsubdetl.part_code, 
			"L") 
		WHEN pr_price_ind = "1" 
			LET pr_unit_amt = pr_subcustomer.unit_amt 
		OTHERWISE 
			LET pr_unit_amt = unit_price(pr_tentsubdetl.ware_code, 
			pr_tentsubdetl.part_code, 
			pr_customer.inv_level_ind) 
	END CASE 
	LET pr_tentsubdetl.unit_amt = pr_unit_amt 
	LET pr_tentsubdetl.unit_tax_amt = unit_tax(pr_tentsubdetl.ware_code, 
	pr_tentsubdetl.part_code, 
	pr_tentsubdetl.unit_amt) 
	LET pr_tentsubdetl.line_total_amt= (pr_tentsubdetl.sub_qty * 
	(pr_tentsubdetl.unit_amt + 
	pr_tentsubdetl.unit_tax_amt)) 
	INSERT INTO tentsubdetl VALUES (pr_tentsubdetl.*) 

END FUNCTION 


FUNCTION insert_tenthead() 

	INITIALIZE pr_customer.* TO NULL 
	IF pr_subhead.corp_flag = "Y" THEN 
		SELECT * INTO pr_customer.* 
		FROM customer 
		WHERE cust_code = pr_subhead.corp_cust_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	ELSE 
	SELECT * INTO pr_customer.* 
	FROM customer 
	WHERE cust_code = pr_subhead.cust_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
END IF 
IF pr_customer.cust_code IS NULL THEN 
	LET pr_rowid = 0 
	RETURN 
END IF 
LET pr_tentsubhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
LET pr_tentsubhead.sub_num = 0 
LET pr_tentsubhead.cust_code = pr_subhead.cust_code 
LET pr_tentsubhead.ord_text = pr_subhead.ord_text 
LET pr_tentsubhead.sales_code = pr_subhead.sales_code 
LET pr_tentsubhead.term_code = pr_subhead.term_code 
LET pr_tentsubhead.tax_code = pr_subhead.tax_code 
LET pr_tentsubhead.goods_amt = 0 
LET pr_tentsubhead.hand_amt = 0 
LET pr_tentsubhead.hand_tax_code = pr_subhead.hand_tax_code 
LET pr_tentsubhead.hand_tax_amt = 0 
LET pr_tentsubhead.freight_amt = 0 
LET pr_tentsubhead.freight_tax_code = pr_subhead.freight_tax_code 
LET pr_tentsubhead.freight_tax_amt = 0 
LET pr_tentsubhead.hand_tax_code = pr_subhead.hand_tax_code 
LET pr_tentsubhead.tax_amt = 0 
LET pr_tentsubhead.disc_amt= 0 
LET pr_tentsubhead.total_amt = 0 
LET pr_tentsubhead.last_inv_num = NULL 
LET pr_tentsubhead.last_inv_date = NULL 
LET pr_tentsubhead.ware_code = pr_subhead.ware_code 
LET pr_tentsubhead.ship_date = pr_tentsubhead.sub_date 
LET pr_tentsubhead.first_inv_num = NULL 
LET pr_tentsubhead.ship_code = pr_subhead.ship_code 
LET pr_tentsubhead.ship_name_text = pr_subhead.ship_name_text 
LET pr_tentsubhead.ship_addr1_text = pr_subhead.ship_addr1_text 
LET pr_tentsubhead.ship_addr2_text = pr_subhead.ship_addr2_text 
LET pr_tentsubhead.ship_city_text = pr_subhead.ship_city_text 
LET pr_tentsubhead.state_code = pr_subhead.state_code 
LET pr_tentsubhead.post_code = pr_subhead.post_code 
LET pr_tentsubhead.country_code = pr_subhead.country_code --@db-patch_2020_10_04--
LET pr_tentsubhead.ship1_text = pr_subhead.ship1_text 
LET pr_tentsubhead.ship2_text = pr_subhead.ship2_text 
LET pr_tentsubhead.fob_text = pr_subhead.fob_text 
LET pr_tentsubhead.prepaid_flag = pr_subhead.prepaid_flag 
LET pr_tentsubhead.currency_code = pr_subhead.currency_code 
LET pr_tentsubhead.conv_qty = pr_subhead.conv_qty 
LET pr_tentsubhead.acct_override_code =pr_subhead.acct_override_code 
LET pr_tentsubhead.invoice_to_ind = pr_subhead.invoice_to_ind 
LET pr_tentsubhead.territory_code = pr_subhead.territory_code 
LET pr_tentsubhead.mgr_code = pr_subhead.mgr_code 
LET pr_tentsubhead.area_code = pr_subhead.area_code 
LET pr_tentsubhead.rev_num = pr_subhead.rev_num 
LET pr_tentsubhead.carrier_code = pr_subhead.carrier_code 
LET pr_tentsubhead.corp_flag = pr_subhead.corp_flag 
LET pr_tentsubhead.corp_cust_code = pr_subhead.corp_cust_code 

INSERT INTO tentsubhead VALUES (pr_tentsubhead.*) 
LET pr_rowid = sqlca.sqlerrd[6] 
LET pr_tentsubhead.sub_num = pr_rowid 
UPDATE tentsubhead 
SET sub_num = pr_tentsubhead.sub_num 
WHERE rowid = pr_rowid 

END FUNCTION 


FUNCTION select_tentsubs() 
	DEFINE msgresp LIKE language.yes_flag 

	CLEAR FORM 
	LET msgresp = kandoomsg("U",1001,"") 
	#Enter selection criteria
	CONSTRUCT BY NAME where_text ON tentsubhead.cust_code, 
	tentsubhead.ship_code, 
	tentsubhead.ship_name_text, 
	tentsubhead.sub_num, 
	tentsubhead.total_amt 

		ON ACTION "WEB-HELP" -- albo kd-374 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	LET msgresp = kandoomsg("U",1002,"") 
	#Searching database
	LET query_text = "SELECT tentsubhead.* ", 
	" FROM tentsubhead", 
	" WHERE tentsubhead.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND ",where_text clipped, 
	" ORDER BY cust_code" 

	PREPARE s_tentsubhead FROM query_text 
	DECLARE c_tentsubhead CURSOR FOR s_tentsubhead 
	RETURN true 
END FUNCTION 


FUNCTION scan_tentsubs() 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE pa_tentsubhead array[300] OF RECORD 
		scroll_flag CHAR(1), 
		cust_code LIKE tentsubhead.cust_code, 
		ship_code LIKE tentsubhead.ship_code, 
		ship_name_text LIKE tentsubhead.ship_name_text, 
		sub_num LIKE tentsubhead.sub_num, 
		total_amt LIKE tentsubhead.total_amt 
	END RECORD, 
	pr_sub_num INTEGER, 
	pr_scroll_flag CHAR(1), 
	i,idx,scrn SMALLINT 

	LET idx = 0 
	FOREACH c_tentsubhead INTO pr_tentsubhead.* 
		LET idx = idx + 1 
		LET pa_tentsubhead[idx].cust_code = pr_tentsubhead.cust_code 
		LET pa_tentsubhead[idx].ship_code = pr_tentsubhead.ship_code 
		LET pa_tentsubhead[idx].sub_num = pr_tentsubhead.sub_num 
		LET pa_tentsubhead[idx].total_amt = pr_tentsubhead.total_amt 
		LET pa_tentsubhead[idx].ship_name_text = pr_tentsubhead.ship_name_text 
		IF idx = 300 THEN 
			LET msgresp = kandoomsg("U",9100,"300") 
			#first 300 rows selected only
			EXIT FOREACH 
		END IF 
	END FOREACH 
	IF idx = 0 THEN 
		LET msgresp = kandoomsg("U",9101,"") 
		#No  records satisfied criteria
		RETURN 
	END IF 
	CALL set_count(idx) 
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	LET msgresp = kandoomsg("U",1101,"") 
	#F2 delete RETURN edit
	INPUT ARRAY pa_tentsubhead WITHOUT DEFAULTS FROM sr_tentsubhead.* 

		ON ACTION "WEB-HELP" -- albo kd-374 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE FIELD scroll_flag 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			LET pr_scroll_flag = pa_tentsubhead[idx].scroll_flag 
			DISPLAY pa_tentsubhead[idx].* 
			TO sr_tentsubhead[scrn].* 

		AFTER FIELD scroll_flag 
			LET pa_tentsubhead[idx].scroll_flag = pr_scroll_flag 
			DISPLAY pa_tentsubhead[idx].scroll_flag 
			TO sr_tentsubhead[scrn].scroll_flag 

			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF arr_curr() >= arr_count() 
				OR pa_tentsubhead[idx+1].cust_code IS NULL THEN 
					LET msgresp=kandoomsg("U",9001,"") 
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
		BEFORE FIELD cust_code 
			IF pa_tentsubhead[idx].sub_num IS NOT NULL THEN 
				OPEN WINDOW k129 at 2,3 WITH FORM "K129" 
				attribute(border) 
				CALL process_sub("EDIT",pa_tentsubhead[idx].sub_num) 
				RETURNING pr_sub_num 
				CLOSE WINDOW k129 
				SELECT cust_code, 
				ship_name_text, 
				sub_num, 
				total_amt 
				INTO pa_tentsubhead[idx].cust_code, 
				pa_tentsubhead[idx].ship_name_text, 
				pa_tentsubhead[idx].sub_num, 
				pa_tentsubhead[idx].total_amt 
				FROM tentsubhead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND sub_num = pa_tentsubhead[idx].sub_num 
			END IF 
			OPTIONS DELETE KEY f36, 
			INSERT KEY f36 
			NEXT FIELD scroll_flag 
		ON KEY (F2) 
			IF kandoomsg("K",8022,"") = "Y" THEN 
				DELETE FROM tentsubhead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND sub_num = pa_tentsubhead[idx].sub_num 
				DELETE FROM tentsubdetl 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND sub_num = pa_tentsubhead[idx].sub_num 
				DELETE FROM tentsubschd 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND sub_num = pa_tentsubhead[idx].sub_num 
				FOR i = idx TO 299 
					LET pa_tentsubhead[i].* = pa_tentsubhead[i+1].* 
					IF pa_tentsubhead[i].cust_code IS NULL THEN 
						LET pa_tentsubhead[i].sub_num = NULL 
					END IF 
					IF scrn <= 12 THEN 
						DISPLAY pa_tentsubhead[i].* TO sr_tentsubhead[scrn].* 

						LET scrn = scrn + 1 
					END IF 
					IF pa_tentsubhead[i].cust_code IS NULL THEN 
						EXIT FOR 
					END IF 
				END FOR 
			END IF 
			NEXT FIELD scroll_flag 
		AFTER ROW 
			DISPLAY pa_tentsubhead[idx].* 
			TO sr_tentsubhead[scrn].* 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 

END FUNCTION 


FUNCTION process_sub(pr_mode,pr_sub_num) 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	pr_mode CHAR(4), 
	pr_hold_sub CHAR(1), 
	pr_mask_code LIKE customertype.acct_mask_code, 
	pr_substype RECORD LIKE substype.*, 
	pr_sub_num LIKE subhead.sub_num 

	CALL initialize_sub(pr_sub_num) 
	LET pr_sub_num = NULL 
	DISPLAY pr_country.state_code_text, 
	pr_country.post_code_text, 
	pr_country.state_code_text, 
	pr_country.post_code_text, 
	pr_inv_prompt 
	TO sr_prompts[1].*, 
	sr_prompts[2].*, 
	inv_ref1_text 
	attribute(white) 
	WHILE header_entry(pr_mode) 
		IF pr_customer.corp_cust_code IS NOT NULL AND 
		pr_customer.corp_cust_ind = "1" THEN 
			SELECT type_code INTO pr_customer.type_code 
			FROM customer 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = pr_customer.corp_cust_code 
		END IF 
		SELECT acct_mask_code INTO pr_mask_code 
		FROM customertype 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND type_code = pr_customer.type_code 
		AND acct_mask_code IS NOT NULL 
		IF status = notfound THEN 
			LET pr_subhead.acct_override_code = 
			build_mask(glob_rec_kandoouser.cmpy_code,pr_subhead.acct_override_code, 
			pr_rec_kandoouser.acct_mask_code) 
		ELSE 
		LET pr_subhead.acct_override_code = 
		build_mask(glob_rec_kandoouser.cmpy_code,pr_subhead.acct_override_code,pr_mask_code) 
	END IF 
	IF NOT valid_trans_num(glob_rec_kandoouser.cmpy_code,TRAN_TYPE_INVOICE_IN, pr_subhead.acct_override_code) THEN 
		#7031Warning: Automatic Invoice Numbering NOT Set up"
		LET msgresp=kandoomsg("A",7031,"") 
	END IF 
	DELETE FROM t_subhead 
	WHERE rowid = pr_growid 
	INSERT INTO t_subhead VALUES (pr_subhead.*) 
	LET pr_growid = sqlca.sqlerrd[6] 
	SELECT unique 1 FROM t_subdetl 
	WHERE sub_num = pr_subhead.sub_num OR sub_num IS NULL 
	IF status = notfound THEN 
		DELETE FROM t_subdetl WHERE 1=1 
		INSERT INTO t_subdetl 
		SELECT * FROM tentsubdetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND sub_num = pr_subhead.sub_num 
		DELETE FROM t_subschedule WHERE 1=1 
		INSERT INTO t_subschedule 
		SELECT * FROM tentsubschd 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND sub_num = pr_subhead.sub_num 
	END IF 
	OPEN WINDOW k130 at 2,3 WITH FORM "K130" 
	attribute(border,white) 
	WHILE lineitem_scan() 
		OPEN WINDOW k132 at 2,3 WITH FORM "K132" 
		attribute(border) 
		WHILE sub_summary(pr_mode) 
			LET pr_paid_amt = 0 
			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				LET pr_sub_num = NULL 
				EXIT WHILE 
			ELSE 
			LET pr_sub_num = pr_subhead.sub_num 
			CALL update_sub(pr_sub_num) 
			EXIT WHILE 
		END IF 
	END WHILE 
	CLOSE WINDOW k132 
	IF pr_sub_num IS NOT NULL THEN 
		EXIT WHILE 
	END IF 
END WHILE 
CLOSE WINDOW k130 
IF pr_sub_num IS NOT NULL THEN 
	EXIT WHILE 
END IF 
END WHILE 
RETURN pr_sub_num 
END FUNCTION 


FUNCTION initialize_sub(pr_sub_num) 
	DEFINE 
	pr_sub_num LIKE subhead.sub_num 

	DELETE FROM t_subhead 
	DELETE FROM t_subdetl 
	DELETE FROM t_subschedule 
	INITIALIZE pr_customer.* TO NULL 
	SELECT * INTO pr_subhead.* 
	FROM tentsubhead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND sub_num = pr_sub_num 
	IF status = notfound THEN 
		INITIALIZE pr_subhead.* TO NULL 
		LET pr_subhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pr_subhead.ware_code = "" 
		LET pr_subhead.entry_code = glob_rec_kandoouser.sign_on_code 
		LET pr_subhead.entry_date = today 
		LET pr_subhead.rev_date = today 
		LET pr_subhead.sub_date = today 
		LET pr_subhead.goods_amt = 0 
		LET pr_subhead.freight_amt = 0 
		LET pr_subhead.hand_amt = 0 
		LET pr_subhead.freight_tax_amt = 0 
		LET pr_subhead.hand_tax_amt = 0 
		LET pr_subhead.tax_amt = 0 
		LET pr_subhead.disc_amt = 0 
		LET pr_subhead.total_amt = 0 
		LET pr_subhead.cost_amt = 0 
		LET pr_subhead.status_ind = "U" 
		LET pr_subhead.line_num = 0 
		LET pr_subhead.rev_num = 0 
		LET pr_subhead.prepaid_flag = no_flag 
		LET pr_subhead.invoice_to_ind = "1" 
		LET pr_subhead.freight_inv_amt = 0 
		LET pr_subhead.hand_inv_amt = 0 
		LET pr_subhead.frttax_inv_amt = 0 
		LET pr_subhead.hndtax_inv_amt = 0 
		LET pr_currsub_amt = 0 
		LET pr_subhead.corp_flag = "N" 
	END IF 
	INSERT INTO t_subhead VALUES (pr_subhead.*) 
	LET pr_growid = sqlca.sqlerrd[6] 
END FUNCTION 


FUNCTION rep_tentsubs() 
	DEFINE l_rpt_idx SMALLINT  
	DEFINE msgresp LIKE language.yes_flag 

	#------------------------------------------------------------

	LET l_rpt_idx = rpt_start(getmoduleid(),"KA1_rpt_list","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT KA1_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------


	OPEN WINDOW wka1 at 10,15 WITH 2 ROWS, 50 COLUMNS	attribute(border) 
	DISPLAY "Customer : " at 1,2 
	DISPLAY "Subscrip : " at 2,2 
	LET pr_tot_amt = 0 
	FOREACH c_tentsubhead INTO pr_tentsubhead.* 
		DISPLAY pr_tentsubhead.ship_name_text at 1,12 
		DISPLAY pr_tentsubhead.sub_num at 2,12

		#------------------------------------------------------------		 
		OUTPUT TO REPORT KA1_rpt_list(l_rpt_idx,pr_tentsubhead.*)
		#------------------------------------------------------------
		 
		IF int_flag OR quit_flag THEN 
			#8503 Continue Report(Y/N)
			IF kandoomsg("U",8503,"") = "N" THEN 
				#9501 Report Terminated
				LET msgresp=kandoomsg("U",9501,"") 
				EXIT FOREACH 
			END IF 
			LET int_flag = false 
			LET quit_flag = false 
		END IF 
	END FOREACH 
	CLOSE WINDOW wka1

	#------------------------------------------------------------
	FINISH REPORT KA1_rpt_list
	CALL rpt_finish("KA1_rpt_list")
	#------------------------------------------------------------
END FUNCTION 

FUNCTION update_tenthead(pr_rowid) 
	DEFINE pr_rowid INTEGER, 
	pr_tax RECORD LIKE tax.* 

	SELECT * INTO pr_tax.* 
	FROM tax 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tax_code = pr_tentsubhead.tax_code 
	IF pr_tax.freight_per IS NULL THEN 
		LET pr_tax.freight_per = 0 
	END IF 
	IF pr_tax.hand_per IS NULL THEN 
		LET pr_tax.hand_per = 0 
	END IF 
	SELECT sum(unit_amt * sub_qty), 
	sum(unit_tax_amt * sub_qty), 
	sum(line_total_amt) 
	INTO pr_tentsubhead.goods_amt, 
	pr_tentsubhead.tax_amt, 
	pr_tentsubhead.total_amt 
	FROM tentsubdetl 
	WHERE sub_num = pr_tentsubhead.sub_num 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF pr_tentsubhead.goods_amt IS NULL THEN 
		LET pr_tentsubhead.goods_amt = 0 
	END IF 
	IF pr_tentsubhead.tax_amt IS NULL THEN 
		LET pr_tentsubhead.tax_amt = 0 
	END IF 
	IF pr_tentsubhead.hand_amt IS NULL THEN 
		LET pr_tentsubhead.hand_amt = 0 
	ELSE 
	LET pr_tentsubhead.hand_tax_amt = 
	pr_tax.hand_per*pr_tentsubhead.hand_amt/100 
END IF 
IF pr_tentsubhead.freight_amt IS NULL THEN 
	LET pr_tentsubhead.freight_amt = 0 
ELSE 
LET pr_tentsubhead.freight_tax_amt = 
(pr_tax.freight_per*pr_tentsubhead.freight_amt)/100 
END IF 
LET pr_tentsubhead.total_amt = pr_tentsubhead.goods_amt 
+ pr_tentsubhead.tax_amt 
+ pr_tentsubhead.hand_amt 
+ pr_tentsubhead.hand_tax_amt 
+ pr_tentsubhead.freight_amt 
+ pr_tentsubhead.freight_tax_amt 
UPDATE tentsubhead 
SET total_amt = pr_tentsubhead.total_amt, 
goods_amt = pr_tentsubhead.goods_amt, 
tax_amt = pr_tentsubhead.tax_amt, 
hand_amt = pr_tentsubhead.hand_amt, 
freight_amt = pr_tentsubhead.freight_amt, 
hand_tax_amt = pr_tentsubhead.hand_tax_amt, 
freight_tax_amt = pr_tentsubhead.freight_tax_amt 
WHERE rowid = pr_rowid 

END FUNCTION 


REPORT KA1_rpt_list(p_rpt_idx,pr_tentsubhead) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE pr_tentsubhead RECORD LIKE tentsubhead.*, 
	line1, line2 CHAR(132), 
	rpt_note CHAR(60), 
	offset1, offset2 SMALLINT, 
	len, s INTEGER 

	OUTPUT 
	--left margin 0 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			
			PRINT COLUMN 1, "Sub", 
			COLUMN 10, "Customer", 
			COLUMN 25, "Name", 
			COLUMN 55, "Date", 
			COLUMN 61, "Year", 
			COLUMN 66, "Period", 
			COLUMN 74, "Currency", 
			COLUMN 88, "Total", 
			COLUMN 101, "Discount" 
			PRINT COLUMN 1, "Number", 
			COLUMN 12, "Code", 
			COLUMN 87, "Subscription", 
			COLUMN 101, "Possible" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		ON EVERY ROW 
			PRINT COLUMN 1, pr_tentsubhead.sub_num USING "########", 
			COLUMN 10, pr_tentsubhead.cust_code, 
			COLUMN 20, pr_tentsubhead.ship_name_text, 
			COLUMN 52, pr_tentsubhead.sub_date USING "dd/mm/yy", 
			COLUMN 76, pr_tentsubhead.currency_code, 
			COLUMN 80, pr_tentsubhead.total_amt USING "---,---,---.&&", 
			COLUMN 95, pr_tentsubhead.disc_amt USING "---,---,---.&&" 
			LET pr_tot_amt = 
			pr_tot_amt + conv_currency(pr_tentsubhead.total_amt, glob_rec_kandoouser.cmpy_code, 
			pr_tentsubhead.currency_code, "F", pr_tentsubhead.sub_date, "S") 
		ON LAST ROW 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 1, "In Base currency" 
			PRINT COLUMN 1, "Report totals:" 
			PRINT COLUMN 1, "Invs: ", count(*) USING "<<<<<", 
			COLUMN 80, pr_tot_amt USING "---,---,---.&&" 
			SKIP 1 line 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
END REPORT 
