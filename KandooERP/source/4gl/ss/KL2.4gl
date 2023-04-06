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

	Source code beautified by beautify.pl on 2019-12-31 14:28:31	$Id: $
}


{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module KL2 : Generates tentative Invoices FOR
#                  Invoice AT nominated date type subscriptions
#                  substype.inv_ind = "2"

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "K_SS_GLOBALS.4gl" 

GLOBALS "KL2_GLOBALS.4gl" 

MAIN 
	DEFINE l_rpt_idx SMALLINT  

	DEFER quit 
	DEFER interrupt 
	
	#Initial UI Init
	CALL setModuleId("KL2") -- albo 
	CALL ui_init(0) 
	CALL authenticate(getmoduleid()) 

	SELECT * INTO pr_company.* 
	FROM company 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	OPEN WINDOW k139 WITH FORM "K139" 

	MENU " Invoice generation" 
		BEFORE MENU 
			SELECT unique 1 FROM tentinvhead 
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
		COMMAND "Generate" " Generate Tentative invoices" 
			IF select_invsubs() THEN 
				CALL scan_invsubs() 
			END IF 
			SELECT unique 1 FROM tentinvhead 
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
		COMMAND "Edit" " Edit Proposed invoices" 
			OPEN WINDOW k141 at 3,4 WITH FORM "K141" 
			attribute(border) 
			WHILE select_tentinvs() 
				CALL scan_tentinvs() 
			END WHILE 
			CLOSE WINDOW k141 
			NEXT option "Report" 
		COMMAND "Report" " Report on Proposed invoices" 
			LET rpt_date = today 
			LET rpt_time = time 
			OPEN WINDOW k141 at 3,4 WITH FORM "K141" 
			attribute(border) 
			WHILE select_tentinvs() 
				CALL rep_tentinvs() 
				EXIT WHILE 
			END WHILE 
			CLOSE WINDOW k141 
			NEXT option "PRINT MANAGER" 
			
		COMMAND "UPDATE" " Create Proposed invoices" 

--			LET rpt_date = today 
--			LET rpt_time = time 
			IF kandoomsg("K",8019,"") = "Y" THEN 

				#------------------------------------------------------------
				LET l_rpt_idx = rpt_start("KL2-INV_ERROR","KL2_rpt_list_EXCEP","N/A", RPT_SHOW_RMS_DIALOG)
				IF l_rpt_idx = 0 THEN #User pressed CANCEL
					RETURN FALSE
				END IF	
				START REPORT KL2_rpt_list_EXCEP TO rpt_get_report_file_with_path2(l_rpt_idx)
				WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
				TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
				BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
				LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
				RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num

				#------------------------------------------------------------

				#------------------------------------------------------------
				LET l_rpt_idx = rpt_start("KL2-INV_SUCCESS","KL2_rpt_list_SUCCESS","N/A", RPT_SHOW_RMS_DIALOG)
				IF l_rpt_idx = 0 THEN #User pressed CANCEL
					RETURN FALSE
				END IF	
				START REPORT KL2_rpt_list_SUCCESS TO rpt_get_report_file_with_path2(l_rpt_idx)
				WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
				TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
				BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
				LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
				RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num

				#------------------------------------------------------------

				CALL write_invs() 

				#------------------------------------------------------------
				FINISH REPORT KL2_rpt_list_EXCEP
				CALL rpt_finish("KL2_rpt_list_EXCEP")
				#------------------------------------------------------------

				#------------------------------------------------------------
				FINISH REPORT KL2_rpt_list_SUCCESS
				CALL rpt_finish("KL2_rpt_list_SUCCESS")
				#------------------------------------------------------------

			END IF 

		ON ACTION "PRINT MANAGER"		#COMMAND KEY ("P",f11) "Print" " Print OR View Generation Reports using RMS "
			CALL run_prog("URS","","","","") 

		COMMAND KEY("E",interrupt)"Exit" " RETURN TO menus" 
			EXIT MENU 

	END MENU 
	CLOSE WINDOW k139 
END MAIN 


FUNCTION select_invsubs() 
	DEFINE msgresp LIKE language.yes_flag 

	SELECT unique 1 FROM tentinvhead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = 0 THEN 
		LET msgresp = kandoomsg("K",8017,"") 
		IF msgresp = "Y" THEN 
			LET msgresp = kandoomsg("K",1016,"") 
			DELETE FROM tentinvhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			DELETE FROM tentinvdetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		ELSE 
		RETURN false 
	END IF 
END IF 
LET msgresp = kandoomsg("U",1020,"Invoice Generation") 
#1020 Enter Invoice Generation Details
LET pr_tentinvhead.inv_date = today 
CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,pr_tentinvhead.inv_date) 
RETURNING pr_tentinvhead.year_num, 
pr_tentinvhead.period_num 
INPUT BY NAME pr_subhead.sub_type_code, 
pr_tentinvhead.inv_date, 
pr_tentinvhead.year_num, 
pr_tentinvhead.period_num, 
pr_tentinvhead.com1_text, 
pr_tentinvhead.com2_text 
WITHOUT DEFAULTS 

	ON ACTION "WEB-HELP" -- albo kd-374 
		CALL onlinehelp(getmoduleid(),null) 

	ON KEY (control-b) 
		CASE 
			WHEN infield(sub_type_code) 
				LET pr_temp_text = show_substype(glob_rec_kandoouser.cmpy_code,"inv_ind = '2'") 
				IF pr_temp_text IS NOT NULL THEN 
					LET pr_subhead.sub_type_code = pr_temp_text 
				END IF 
				NEXT FIELD sub_type_code 
		END CASE 
	AFTER FIELD sub_type_code 
		IF pr_subhead.sub_type_code IS NULL THEN 
			LET msgresp = kandoomsg("U",9102,"") 
			#9102 Value must be entered
			NEXT FIELD sub_type_code 
		END IF 
		SELECT * INTO pr_substype.* 
		FROM substype 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND type_code = pr_subhead.sub_type_code 
		AND inv_ind = "2" 
		IF status = notfound THEN 
			LET msgresp = kandoomsg("U",9105,"") 
			#9105 RECORD NOT found - try window
			NEXT FIELD sub_type_code 
		ELSE 
		DISPLAY BY NAME pr_substype.desc_text 

	END IF 
	AFTER FIELD inv_date 
		IF pr_tentinvhead.inv_date IS NULL THEN 
			LET pr_tentinvhead.inv_date = today 
			NEXT FIELD inv_date 
		ELSE 
		IF NOT field_touched(year_num) THEN 
			CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,pr_tentinvhead.inv_date) 
			RETURNING pr_tentinvhead.year_num, 
			pr_tentinvhead.period_num 
			DISPLAY BY NAME pr_tentinvhead.period_num, 
			pr_tentinvhead.year_num 

		END IF 
	END IF 
	AFTER FIELD year_num 
		IF pr_tentinvhead.year_num IS NULL THEN 
			CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,pr_tentinvhead.inv_date) 
			RETURNING pr_tentinvhead.year_num, 
			pr_tentinvhead.period_num 
			DISPLAY BY NAME pr_tentinvhead.period_num 

			NEXT FIELD year_num 
		END IF 
	AFTER FIELD period_num 
		IF pr_tentinvhead.period_num IS NULL THEN 
			CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,pr_tentinvhead.inv_date) 
			RETURNING pr_tentinvhead.year_num, 
			pr_tentinvhead.period_num 
			DISPLAY BY NAME pr_tentinvhead.period_num 

			NEXT FIELD year_num 
		END IF 
	AFTER INPUT 
		IF not(int_flag OR quit_flag) THEN 
			IF pr_subhead.sub_type_code IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD sub_type_code 
			END IF 
			IF pr_tentinvhead.inv_date IS NULL THEN 
				LET pr_tentinvhead.inv_date = today 
			END IF 
			IF pr_tentinvhead.year_num IS NULL THEN 
				CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,pr_tentinvhead.inv_date) 
				RETURNING pr_tentinvhead.year_num, 
				pr_tentinvhead.period_num 
			END IF 
			IF pr_tentinvhead.period_num IS NULL THEN 
				CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,pr_tentinvhead.inv_date) 
				RETURNING pr_tentinvhead.year_num, 
				pr_tentinvhead.period_num 
			END IF 
			CALL valid_period(glob_rec_kandoouser.cmpy_code,pr_tentinvhead.year_num, 
			pr_tentinvhead.period_num,"AR") 
			RETURNING pr_tentinvhead.year_num, 
			pr_tentinvhead.period_num, 
			invalid_period 
			IF invalid_period THEN 
				NEXT FIELD year_num 
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


FUNCTION scan_invsubs() 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE idx SMALLINT 

	LET msgresp = kandoomsg("U",1001,"") 
	#Enter selection criteria
	CONSTRUCT BY NAME where_text ON subhead.cust_code, 
	customer.name_text, 
	subhead.ship_code, 
	subhead.ship_name_text, 
	customer.type_code, 
	subhead.state_code 

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
	LET query_text = "SELECT subhead.* ", 
	" FROM subhead,customer ", 
	" WHERE subhead.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND subhead.sub_type_code = '", 
	pr_subhead.sub_type_code,"' ", 
	" AND customer.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND subhead.cust_code = customer.cust_code ", 
	" AND subhead.status_ind <> 'C' ", 
	" AND ",where_text clipped 
	PREPARE s_subhead FROM query_text 
	DECLARE c_subhead CURSOR FOR s_subhead 

	DECLARE c_subdetl CURSOR FOR 
	SELECT * FROM subdetl 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND sub_num = pr_subhead.sub_num 
	AND inv_qty < sub_qty 

	OPEN WINDOW wkl2 at 10,15 WITH 2 ROWS, 50 COLUMNS 
	attribute(border) 
	DISPLAY "Customer : " at 1,2 
	DISPLAY "Subscrip : " at 2,2 
	FOREACH c_subhead INTO pr_subhead.* 
		LET idx = 0 
		LET total_cost = 0 
		LET total_sale = 0 
		LET total_tax = 0 
		DISPLAY pr_subhead.ship_name_text at 1,12 
		DISPLAY pr_subhead.sub_num at 2,12 
		FOREACH c_subdetl INTO pr_subdetl.* 
			LET idx = idx + 1 
			CALL insert_tentdetl() 
		END FOREACH 
		IF idx > 0 THEN 
			CALL insert_tenthead() 
		END IF 
	END FOREACH 
	CLOSE WINDOW wkl2 
END FUNCTION 

FUNCTION insert_tentdetl() 
	DEFINE pr_tentinvdetl RECORD LIKE tentinvdetl.*, 
	pr_product RECORD LIKE product.*, 
	pr_prodstatus RECORD LIKE prodstatus.* 

	LET pr_tentinvdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET pr_tentinvdetl.inv_num = pr_subdetl.sub_num 
	LET pr_tentinvdetl.part_code = pr_subdetl.part_code 
	LET pr_tentinvdetl.cust_code =pr_subdetl.cust_code 
	LET pr_tentinvdetl.line_num =pr_subdetl.sub_line_num 
	LET pr_tentinvdetl.ware_code =pr_subdetl.ware_code 
	LET pr_tentinvdetl.ord_qty =pr_subdetl.sub_qty 
	LET pr_tentinvdetl.ship_qty =pr_subdetl.sub_qty - pr_subdetl.inv_qty 
	LET pr_tentinvdetl.line_text =pr_subdetl.line_text 
	LET pr_tentinvdetl.unit_sale_amt = pr_subdetl.unit_amt 
	LET pr_tentinvdetl.unit_tax_amt = pr_subdetl.unit_tax_amt 
	LET pr_tentinvdetl.ext_sale_amt = pr_subdetl.unit_amt * 
	pr_tentinvdetl.ship_qty 
	LET pr_tentinvdetl.ext_tax_amt = pr_subdetl.unit_tax_amt * 
	pr_tentinvdetl.ship_qty 
	LET pr_tentinvdetl.line_total_amt= 
	pr_tentinvdetl.ext_sale_amt + 
	pr_tentinvdetl.ext_tax_amt 
	SELECT * INTO pr_product.* 
	FROM product 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_tentinvdetl.part_code 
	LET pr_tentinvdetl.cat_code = pr_product.cat_code 
	IF pr_tentinvdetl.line_text IS NULL THEN 
		LET pr_tentinvdetl.line_text = pr_product.desc_text 
	END IF 
	LET pr_tentinvdetl.uom_code = pr_product.sell_uom_code 
	LET pr_tentinvdetl.prodgrp_code = pr_product.prodgrp_code 
	LET pr_tentinvdetl.maingrp_code = pr_product.maingrp_code 
	SELECT subacct_code INTO pr_tentinvdetl.line_acct_code 
	FROM substype 
	WHERE cmpy_code = cmpy_code 
	AND type_code = pr_subhead.sub_type_code 
	AND subacct_code IS NOT NULL 
	IF status = notfound THEN 
		SELECT sub_acct_code INTO pr_tentinvdetl.line_acct_code 
		FROM ssparms 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	END IF 
	SELECT * INTO pr_prodstatus.* 
	FROM prodstatus 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ware_code = pr_tentinvdetl.ware_code 
	AND part_code = pr_tentinvdetl.part_code 
	LET pr_tentinvdetl.unit_cost_amt = pr_prodstatus.wgted_cost_amt 
	* pr_subhead.conv_qty 
	LET pr_tentinvdetl.ext_cost_amt = 
	pr_tentinvdetl.unit_cost_amt * 
	pr_tentinvdetl.ship_qty 
	LET pr_tentinvdetl.list_price_amt = pr_prodstatus.list_amt 
	* pr_subhead.conv_qty 
	IF pr_tentinvdetl.list_price_amt = 0 THEN 
		LET pr_tentinvdetl.list_price_amt = 
		pr_tentinvdetl.unit_sale_amt 
	END IF 
	LET pr_tentinvdetl.disc_amt = pr_tentinvdetl.list_price_amt 
	- pr_tentinvdetl.unit_sale_amt 
	LET total_cost = total_cost + pr_tentinvdetl.ext_cost_amt 
	LET total_sale = total_sale + pr_tentinvdetl.ext_sale_amt 
	LET total_tax = total_tax + pr_tentinvdetl.ext_tax_amt 
	INSERT INTO tentinvdetl VALUES (pr_tentinvdetl.*) 

END FUNCTION 


FUNCTION insert_tenthead() 
	DEFINE pr_term RECORD LIKE term.* 

	LET pr_tentinvhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET pr_tentinvhead.inv_num = pr_subhead.sub_num 
	LET pr_tentinvhead.cust_code = pr_subhead.cust_code 
	LET pr_tentinvhead.ord_num = pr_subhead.sub_num 
	LET pr_tentinvhead.purchase_code = pr_subhead.ord_text 
	LET pr_tentinvhead.ref_num = pr_subhead.sub_num 
	LET pr_tentinvhead.sale_code = pr_subhead.sales_code 
	LET pr_tentinvhead.term_code = pr_subhead.term_code 
	LET pr_tentinvhead.tax_code = pr_subhead.tax_code 
	SELECT tax_per INTO pr_tentinvhead.tax_per FROM tax 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tax_code = pr_tentinvhead.tax_code 
	LET pr_tentinvhead.goods_amt = total_sale 
	LET pr_tentinvhead.hand_amt = pr_subhead.hand_amt - 
	pr_subhead.hand_inv_amt 
	LET pr_tentinvhead.hand_tax_code = pr_subhead.hand_tax_code 
	LET pr_tentinvhead.hand_tax_amt = pr_subhead.hand_tax_amt - 
	pr_subhead.hndtax_inv_amt 
	LET pr_tentinvhead.freight_amt = pr_subhead.freight_amt - 
	pr_subhead.freight_inv_amt 
	LET pr_tentinvhead.freight_tax_code = pr_subhead.freight_tax_code 
	LET pr_tentinvhead.freight_tax_amt = pr_subhead.freight_tax_amt - 
	pr_subhead.frttax_inv_amt 
	LET pr_tentinvhead.hand_tax_code = pr_subhead.hand_tax_code 
	LET pr_tentinvhead.tax_amt = total_tax 
	LET pr_tentinvhead.disc_amt= pr_subhead.disc_amt 
	LET pr_tentinvhead.total_amt = pr_tentinvhead.goods_amt 
	+ pr_tentinvhead.tax_amt 
	+ pr_tentinvhead.hand_amt 
	+ pr_tentinvhead.hand_tax_amt 
	+ pr_tentinvhead.freight_amt 
	+ pr_tentinvhead.freight_tax_amt 
	LET pr_tentinvhead.cost_amt = total_cost 
	SELECT * INTO pr_term.* 
	FROM term 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND term_code = pr_tentinvhead.term_code 
	CALL get_due_and_discount_date(pr_term.*,pr_tentinvhead.inv_date) 
	RETURNING pr_tentinvhead.due_date, 
	pr_tentinvhead.disc_date 
	LET pr_tentinvhead.disc_amt= 
	(pr_tentinvhead.total_amt*pr_term.disc_per/100) 
	LET pr_tentinvhead.ship_code = pr_subhead.ship_code 
	LET pr_tentinvhead.name_text = pr_subhead.ship_name_text 
	LET pr_tentinvhead.addr1_text = pr_subhead.ship_addr1_text 
	LET pr_tentinvhead.addr2_text = pr_subhead.ship_addr2_text 
	LET pr_tentinvhead.city_text = pr_subhead.ship_city_text 
	LET pr_tentinvhead.state_code = pr_subhead.state_code 
	LET pr_tentinvhead.post_code = pr_subhead.post_code 
	LET pr_tentinvhead.country_code = pr_subhead.country_code --@db-patch_2020_10_04--
	LET pr_tentinvhead.ship1_text = pr_subhead.ship1_text 
	LET pr_tentinvhead.ship2_text = pr_subhead.ship2_text 
	LET pr_tentinvhead.fob_text = pr_subhead.fob_text 
	LET pr_tentinvhead.prepaid_flag = pr_subhead.prepaid_flag 
	LET pr_tentinvhead.currency_code = pr_subhead.currency_code 
	LET pr_tentinvhead.conv_qty = pr_subhead.conv_qty 
	LET pr_tentinvhead.acct_override_code =pr_subhead.acct_override_code 
	LET pr_tentinvhead.invoice_to_ind = pr_subhead.invoice_to_ind 
	LET pr_tentinvhead.territory_code = pr_subhead.territory_code 
	LET pr_tentinvhead.mgr_code = pr_subhead.mgr_code 
	LET pr_tentinvhead.area_code = pr_subhead.area_code 
	LET pr_tentinvhead.rev_num = pr_subhead.rev_num 
	LET pr_tentinvhead.carrier_code = pr_subhead.carrier_code 


	INSERT INTO tentinvhead VALUES (pr_tentinvhead.*) 

END FUNCTION 


FUNCTION select_tentinvs() 
	DEFINE msgresp LIKE language.yes_flag 
	CLEAR FORM 
	LET msgresp = kandoomsg("U",1001,"") 
	#Enter selection criteria
	CONSTRUCT BY NAME where_text ON tentinvhead.cust_code, 
	tentinvhead.name_text, 
	tentinvhead.inv_num, 
	tentinvhead.total_amt 

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
	LET query_text = "SELECT tentinvhead.* ", 
	" FROM tentinvhead", 
	" WHERE tentinvhead.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND ",where_text clipped, 
	" ORDER BY cust_code" 

	PREPARE s_tentinvhead FROM query_text 
	DECLARE c_tentinvhead CURSOR FOR s_tentinvhead 
	RETURN true 
END FUNCTION 


FUNCTION scan_tentinvs() 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE pa_tentinvhead array[300] OF RECORD 
		scroll_flag CHAR(1), 
		cust_code LIKE tentinvhead.cust_code, 
		name_text LIKE tentinvhead.name_text, 
		inv_num LIKE tentinvhead.inv_num, 
		total_amt LIKE tentinvhead.total_amt 
	END RECORD, 
	pr_scroll_flag CHAR(1), 
	i,idx,scrn SMALLINT 

	LET idx = 0 
	FOREACH c_tentinvhead INTO pr_tentinvhead.* 
		LET idx = idx + 1 
		LET pa_tentinvhead[idx].cust_code = pr_tentinvhead.cust_code 
		LET pa_tentinvhead[idx].inv_num = pr_tentinvhead.inv_num 
		LET pa_tentinvhead[idx].total_amt = pr_tentinvhead.total_amt 
		LET pa_tentinvhead[idx].name_text = pr_tentinvhead.name_text 
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
	INPUT ARRAY pa_tentinvhead WITHOUT DEFAULTS FROM sr_tentinvhead.* 

		ON ACTION "WEB-HELP" -- albo kd-374 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE FIELD scroll_flag 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			LET pr_scroll_flag = pa_tentinvhead[idx].scroll_flag 
			DISPLAY pa_tentinvhead[idx].* 
			TO sr_tentinvhead[scrn].* 

		AFTER FIELD scroll_flag 
			LET pa_tentinvhead[idx].scroll_flag = pr_scroll_flag 
			DISPLAY pa_tentinvhead[idx].scroll_flag 
			TO sr_tentinvhead[scrn].scroll_flag 

			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF arr_curr() >= arr_count() 
				OR pa_tentinvhead[idx+1].cust_code IS NULL THEN 
					LET msgresp=kandoomsg("U",9001,"") 
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
		BEFORE FIELD cust_code 
			IF pa_tentinvhead[idx].cust_code IS NOT NULL THEN 
				OPEN WINDOW k142 at 2,3 WITH FORM "K142" 
				attribute(border) 
				CALL modify_inv(pa_tentinvhead[idx].inv_num) 
				CLOSE WINDOW k142 
				SELECT cust_code, 
				name_text, 
				inv_num, 
				total_amt 
				INTO pa_tentinvhead[idx].cust_code, 
				pa_tentinvhead[idx].name_text, 
				pa_tentinvhead[idx].inv_num, 
				pa_tentinvhead[idx].total_amt 
				FROM tentinvhead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND inv_num = pa_tentinvhead[idx].inv_num 
			END IF 
			OPTIONS DELETE KEY f36, 
			INSERT KEY f36 
			NEXT FIELD scroll_flag 
		ON KEY (F2) 
			IF kandoomsg("K",8018,"") = "Y" THEN 
				DELETE FROM tentinvhead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND inv_num = pa_tentinvhead[idx].inv_num 
				FOR i = idx TO 299 
					LET pa_tentinvhead[i].* = pa_tentinvhead[i+1].* 
					IF pa_tentinvhead[i].cust_code IS NULL THEN 
						LET pa_tentinvhead[i].inv_num = NULL 
					END IF 
					IF scrn <= 12 THEN 
						DISPLAY pa_tentinvhead[i].* TO sr_tentinvhead[scrn].* 

						LET scrn = scrn + 1 
					END IF 
					IF pa_tentinvhead[i].cust_code IS NULL THEN 
						EXIT FOR 
					END IF 
				END FOR 
			END IF 
			NEXT FIELD scroll_flag 
		AFTER ROW 
			DISPLAY pa_tentinvhead[idx].* 
			TO sr_tentinvhead[scrn].* 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 

END FUNCTION 

FUNCTION modify_inv(pr_inv_num) 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE pr_inv_num INTEGER, 
	pr_carrier RECORD LIKE carrier.*, 
	pr_term RECORD LIKE term.*, 
	pr_customership RECORD LIKE customership.*, 
	pr_save_carr_code LIKE invoicehead.carrier_code, 
	pr_freight_amt LIKE invoicehead.freight_amt, 
	pr_weight_qty LIKE product.weight_qty, 
	pr_save_freight_ind LIKE customership.freight_ind 

	SELECT * INTO pr_tentinvhead.* 
	FROM tentinvhead 
	WHERE inv_num = pr_inv_num 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = notfound THEN 
		RETURN 
	END IF 

	LET msgresp=kandoomsg("A",1067,"") 
	#A1067" Order Shipping & Summary Details - ESC TO Continue"
	DISPLAY BY NAME pr_tentinvhead.cust_code, 
	pr_tentinvhead.name_text 

	CALL KL2_tentinvhead_disp_summ() 
	INPUT BY NAME pr_tentinvhead.carrier_code, 
	pr_customership.freight_ind, 
	pr_tentinvhead.ship1_text, 
	pr_tentinvhead.ship2_text, 
	pr_tentinvhead.fob_text, 
	pr_tentinvhead.com1_text, 
	pr_tentinvhead.com2_text, 
	pr_tentinvhead.hand_amt, 
	pr_tentinvhead.freight_amt, 
	pr_tentinvhead.due_date, 
	pr_tentinvhead.disc_date WITHOUT DEFAULTS 

		ON ACTION "WEB-HELP" -- albo kd-374 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) 
			IF infield(carrier_code) THEN 
				LET pr_temp_text = show_carrier(glob_rec_kandoouser.cmpy_code,"") 
				IF pr_temp_text IS NOT NULL THEN 
					LET pr_tentinvhead.carrier_code = pr_temp_text clipped 
					NEXT FIELD carrier_code 
				END IF 
			END IF 
		BEFORE FIELD carrier_code 
			LET pr_save_carr_code = pr_tentinvhead.carrier_code 
		AFTER FIELD carrier_code 
			IF pr_tentinvhead.carrier_code IS NOT NULL THEN 
				SELECT * INTO pr_carrier.* 
				FROM carrier 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND carrier_code = pr_tentinvhead.carrier_code 
				IF sqlca.sqlcode = notfound THEN 
					LET msgresp=kandoomsg("A",9042,"") 
					#9042" Carrier does NOT exist - Try Window"
					NEXT FIELD carrier_code 
				END IF 
				IF pr_save_carr_code != pr_tentinvhead.carrier_code 
				OR pr_save_carr_code IS NULL THEN 
					IF pr_carrier.charge_ind = 2 THEN 
						IF pr_weight_qty = 0 THEN 
							SELECT sum(p.weight_qty * o.ship_qty ) 
							INTO pr_weight_qty 
							FROM tentinvdetl o, product p 
							WHERE o.cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND o.inv_num = pr_tentinvhead.inv_num 
							AND p.cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND o.part_code = p.part_code 
							AND p.weight_qty IS NOT NULL 
						END IF 
					END IF 
					LET pr_tentinvhead.freight_amt = 
					calc_freight_charges(glob_rec_kandoouser.cmpy_code,pr_tentinvhead.carrier_code, 
					pr_customership.freight_ind, 
					pr_tentinvhead.state_code, 
					pr_tentinvhead.country_code, 
					pr_weight_qty) * pr_tentinvhead.conv_qty 
				END IF 
				DISPLAY pr_carrier.name_text TO carrier.name_text 

				CALL KL2_tentinvhead_disp_summ() 
			END IF 
		BEFORE FIELD freight_ind 
			LET pr_save_freight_ind = pr_customership.freight_ind 
		AFTER FIELD freight_ind 
			IF pr_save_freight_ind != pr_customership.freight_ind 
			OR pr_save_freight_ind IS NULL THEN 
				IF pr_carrier.charge_ind = 2 THEN 
					IF pr_weight_qty = 0 THEN 
						SELECT sum(p.weight_qty * o.ship_qty ) 
						INTO pr_weight_qty 
						FROM tentinvdetl o, product p 
						WHERE o.cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND o.inv_num = pr_tentinvhead.inv_num 
						AND p.cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND o.part_code = p.part_code 
						AND p.weight_qty IS NOT NULL 
					END IF 
				END IF 
				LET pr_tentinvhead.freight_amt = 
				calc_freight_charges(glob_rec_kandoouser.cmpy_code,pr_tentinvhead.carrier_code, 
				pr_customership.freight_ind, 
				pr_tentinvhead.state_code, 
				pr_tentinvhead.country_code, 
				pr_weight_qty) * pr_tentinvhead.conv_qty 
				CALL KL2_tentinvhead_disp_summ() 
			END IF 
		AFTER FIELD freight_amt 
			CALL KL2_tentinvhead_disp_summ() 
		AFTER FIELD hand_amt 
			CALL KL2_tentinvhead_disp_summ() 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 
	END IF 
	UPDATE tentinvhead SET * = pr_tentinvhead.* 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND inv_num = pr_tentinvhead.inv_num 

END FUNCTION 


FUNCTION KL2_tentinvhead_disp_summ() 
	DEFINE 
	pr_tax RECORD LIKE tax.* 

	SELECT * INTO pr_tax.* 
	FROM tax 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tax_code = pr_tentinvhead.tax_code 
	IF pr_tax.freight_per IS NULL THEN 
		LET pr_tax.freight_per = 0 
	END IF 
	IF pr_tax.hand_per IS NULL THEN 
		LET pr_tax.hand_per = 0 
	END IF 
	SELECT sum(ext_sale_amt), 
	sum(ext_tax_amt), 
	sum(line_total_amt) 
	INTO pr_tentinvhead.goods_amt, 
	pr_tentinvhead.tax_amt, 
	pr_tentinvhead.total_amt 
	FROM tentinvdetl 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND inv_num = pr_tentinvhead.inv_num 
	IF pr_tentinvhead.goods_amt IS NULL THEN 
		LET pr_tentinvhead.goods_amt = 0 
	END IF 
	IF pr_tentinvhead.tax_amt IS NULL THEN 
		LET pr_tentinvhead.tax_amt = 0 
	END IF 
	IF pr_tentinvhead.hand_amt IS NULL THEN 
		LET pr_tentinvhead.hand_amt = 0 
	ELSE 
	LET pr_tentinvhead.hand_tax_amt = 
	pr_tax.hand_per*pr_tentinvhead.hand_amt/100 
END IF 
IF pr_tentinvhead.freight_amt IS NULL THEN 
	LET pr_tentinvhead.freight_amt = 0 
ELSE 
LET pr_tentinvhead.freight_tax_amt = 
(pr_tax.freight_per*pr_tentinvhead.freight_amt)/100 
END IF 
LET pr_tentinvhead.total_amt = pr_tentinvhead.goods_amt 
+ pr_tentinvhead.tax_amt 
+ pr_tentinvhead.hand_amt 
+ pr_tentinvhead.hand_tax_amt 
+ pr_tentinvhead.freight_amt 
+ pr_tentinvhead.freight_tax_amt 
DISPLAY BY NAME pr_tentinvhead.freight_amt, 
pr_tentinvhead.hand_amt, 
pr_tentinvhead.tax_amt, 
pr_tentinvhead.goods_amt, 
pr_tentinvhead.total_amt 
attribute(yellow) 
DISPLAY BY NAME pr_tentinvhead.currency_code 
attribute(green) 
END FUNCTION 

FUNCTION rep_tentinvs() 
	DEFINE l_rpt_idx SMALLINT  
	DEFINE msgresp LIKE language.yes_flag 


	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start("KL2-INV_PROPOSAL","KL2_rpt_list_PROPOSAL","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT KL2_rpt_list_PROPOSAL TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------


	OPEN WINDOW wkl2 at 10,15 WITH 2 ROWS, 50 COLUMNS 
	attribute(border) 
	DISPLAY "Customer : " at 1,2 
	DISPLAY "Subscrip : " at 2,2 
	LET pr_tot_amt = 0 
	FOREACH c_tentinvhead INTO pr_tentinvhead.* 
		DISPLAY pr_tentinvhead.name_text at 1,12 
		DISPLAY pr_tentinvhead.inv_num at 2,12

		#---------------------------------------------------------		 
		OUTPUT TO REPORT KL2_rpt_list_PROPOSAL(l_rpt_idx,pr_tentinvhead.*) 
		#---------------------------------------------------------

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
	CLOSE WINDOW wkl2 

	#------------------------------------------------------------
	FINISH REPORT KL2_rpt_list_PROPOSAL
	CALL rpt_finish("KL2_rpt_list_PROPOSAL")
	#------------------------------------------------------------

END FUNCTION 

REPORT KL2_rpt_list_PROPOSAL(p_rpt_idx,pr_tentinvhead) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE pr_tentinvhead RECORD LIKE tentinvhead.*, 
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
			COLUMN 87, "Invoice", 
			COLUMN 101, "Possible" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		ON EVERY ROW 
			PRINT COLUMN 1, pr_tentinvhead.inv_num USING "########", 
			COLUMN 10, pr_tentinvhead.cust_code, 
			COLUMN 20, pr_tentinvhead.name_text, 
			COLUMN 52, pr_tentinvhead.inv_date USING "dd/mm/yy", 
			COLUMN 61, pr_tentinvhead.year_num USING "####", 
			COLUMN 67, pr_tentinvhead.period_num USING "###", 
			COLUMN 76, pr_tentinvhead.currency_code, 
			COLUMN 80, pr_tentinvhead.total_amt USING "---,---,---.&&", 
			COLUMN 95, pr_tentinvhead.disc_amt USING "---,---,---.&&" 
			LET pr_tot_amt = 
			pr_tot_amt + conv_currency(pr_tentinvhead.total_amt, glob_rec_kandoouser.cmpy_code, 
			pr_tentinvhead.currency_code, "F", pr_tentinvhead.inv_date, "S") 
		ON LAST ROW 
			PRINT COLUMN 1, "----------------------------------------", 
			"----------------------------------------", 
			"----------------------------------------", 
			"----------" 
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
