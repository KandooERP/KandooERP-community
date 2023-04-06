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
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../ss/K_SS_GLOBALS.4gl"
GLOBALS "../ss/KR_GROUP_GLOBALS.4gl" 
GLOBALS "../ss/KS2_GLOBALS.4gl"
GLOBALS 
	DEFINE  
	no_flag LIKE language.no_flag, 
	pr_ware_code LIKE subhead.ware_code, 
	pr_sub_date LIKE subhead.sub_date, 
	pr_company RECORD LIKE company.*, 
	pr_customership RECORD LIKE customership.*, 
	pr_rec_kandoouser RECORD LIKE kandoouser.*, 
	pr_ssparms RECORD LIKE ssparms.*, 
	pr_arparms RECORD LIKE arparms.*, 
	pr_glparms RECORD LIKE glparms.*, 
	pr_country RECORD LIKE country.*, 
	pr_subhead RECORD LIKE subhead.*, 
	pr_substype RECORD LIKE substype.*, 
	pr_subproduct RECORD LIKE subproduct.*, 
	pr_csubhead RECORD LIKE subhead.*, 
	pr_subdetl RECORD LIKE subdetl.*, 
	pr_customer RECORD LIKE customer.*, 
	pr_warehouse RECORD LIKE warehouse.*, 
	pr_paid_amt DECIMAL(16,2), 
	pr_start_year,pr_end_year SMALLINT, 
	err_message CHAR(60), 
	directory CHAR(60), 
	runner CHAR(100), 
	rpt_wid SMALLINT, 
	rpt_time CHAR(8), 
	rpt_date CHAR(10), 
	rpt_length INTEGER, 
	rpt_pageno INTEGER, 
	rpt2_pageno INTEGER, 
	rpt3_pageno INTEGER, 
	pr_output,pr_output2,pr_output3 CHAR(60), 
	pr_currsub_amt DECIMAL(16,2),## CURRENT ORDER total amount 
	pr_loadtable RECORD 
		cust_code CHAR(8), 
		ship_code CHAR(8), 
		sub_type CHAR(4), 
		part_code CHAR(18), 
		sub_qty FLOAT , 
		unit_amt DECIMAL(16,4) 
	END RECORD, 
	pr_temp_text CHAR(500) ## temp scratch pad variable 
END GLOBALS 
###########################################################################
# MODULE Scope Variables
###########################################################################
DEFINE modu_load_file STRING
###########################################################################
# MAIN
#
# Subs Load Program
###########################################################################
MAIN
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
 
 
	#Initial UI Init
	CALL setModuleId("KS2") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	SELECT * FROM subhead 
	WHERE rowid = 0 AND 1!=1 INTO temp t_subhead WITH no LOG 

	SELECT * FROM subdetl 
	WHERE rowid = 0 AND 1!=1 INTO temp t_subdetl WITH no LOG 
	SELECT * FROM subschedule 
	WHERE rowid = 0 AND 1!=1 INTO temp t_subschedule WITH no LOG 

	SELECT * FROM cashreceipt 
	WHERE rowid = 0 AND 1!=1 INTO temp t_cashreceipt WITH no LOG 
	SELECT * FROM invoicehead 
	WHERE rowid = 0 AND 1!=1 INTO temp t_invoicehead WITH no LOG 

	SELECT * FROM invoicedetl 
	WHERE rowid = 0 AND 1!=1 INTO temp t_invoicedetl WITH no LOG 
	
	CREATE temp TABLE t_loadtable(cust_code CHAR(8), 
	ship_code CHAR(8), 
	sub_type CHAR(4), 
	part_code CHAR(18), 
	sub_qty FLOAT, 
	unit_amt DECIMAL(16,4)) 
	LET rpt_wid = 80 
	LET rpt_date = today 
	
	SELECT * INTO pr_rec_kandoouser.* FROM kandoouser 
	WHERE sign_on_code = glob_rec_kandoouser.sign_on_code 

	SELECT * INTO pr_glparms.* FROM glparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_code = "1" 
	IF status = notfound THEN 
		CALL fgl_winmessage("GL Configuration Error! Exit Application...", kandoomsg2("A",5001,"")		,"ERROR") #5001 GL Parameters are NOT found"
		EXIT program 
	END IF 

	SELECT * INTO pr_ssparms.* FROM ssparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = notfound THEN 
		CALL fgl_winmessage("SS Configuration Error! Exit Application...", kandoomsg2("K",5001,"")	,"ERROR") #5001 " SS Parameters are NOT found"
		EXIT program 
	END IF 

	SELECT * INTO pr_arparms.* FROM arparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 
	IF status = notfound THEN
		CALL fgl_winmessage("AR Configuration Error! Exit Application...", kandoomsg2("A",5002,""),"ERROR") #5002 " AR Parameters are NOT found"
		EXIT program 
	END IF 
	
	SELECT country.* INTO pr_country.* 
	FROM country, 
	company 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND country.country_code = company.country_code
	 
	OPEN WINDOW K160 WITH FORM "K160" 
	MENU " Subscription load" 

		ON ACTION "WEB-HELP" -- albo kd-374 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "IMPORT SUBSCRIPTION" --COMMAND "Load" " INPUT details AND load subscription data" 
			IF input_details() THEN 

				#------------------------------------------------------------
				LET l_rpt_idx = rpt_start("KS2-ERROR","KS2_rpt_list_error","N/A", RPT_SHOW_RMS_DIALOG)
				IF l_rpt_idx = 0 THEN #User pressed CANCEL
					RETURN FALSE
				END IF	
				START REPORT KS2_rpt_list_error TO rpt_get_report_file_with_path2(l_rpt_idx)
				WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
				TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
				BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
				LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
				RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
				#------------------------------------------------------------

				#------------------------------------------------------------
				LET l_rpt_idx = rpt_start("KS2-SUBSCRIPTION","KS2_rpt_list_subscription","N/A", RPT_SHOW_RMS_DIALOG)
				IF l_rpt_idx = 0 THEN #User pressed CANCEL
					RETURN FALSE
				END IF	
				START REPORT KS2_rpt_list_subscription TO rpt_get_report_file_with_path2(l_rpt_idx)
				WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
				TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
				BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
				LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
				RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
				#------------------------------------------------------------


				#------------------------------------------------------------
				LET l_rpt_idx = rpt_start("KS2-INVOICE","KS2_rpt_list_invoice","N/A", RPT_SHOW_RMS_DIALOG)
				IF l_rpt_idx = 0 THEN #User pressed CANCEL
					RETURN FALSE
				END IF	
				START REPORT KS2_rpt_list_invoice TO rpt_get_report_file_with_path2(l_rpt_idx)
				WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
				TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
				BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
				LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
				RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
				#------------------------------------------------------------

				IF load_tables() THEN 
					IF insert_sub() THEN 
						CALL write_sub("ADD") 
					ELSE 
					ERROR kandoomsg2("K",9126,"")			#9126 Load was unsuccessful.
				END IF 

			END IF 
		 
			DELETE FROM t_subhead WHERE 1=1 
			DELETE FROM t_subdetl WHERE 1=1 
			DELETE FROM t_subschedule WHERE 1=1 
			DELETE FROM t_cashreceipt WHERE 1=1 
			DELETE FROM t_invoicehead WHERE 1=1 
			DELETE FROM t_invoicedetl WHERE 1=1 
			DELETE FROM t_loadtable WHERE 1=1
			
			#------------------------------------------------------------
			FINISH REPORT KS2_rpt_list_subscription
			CALL rpt_finish("AKS2_rpt_list_subscription")
			#------------------------------------------------------------			
			#------------------------------------------------------------
			FINISH REPORT KS2_rpt_list_invoice
			CALL rpt_finish("KS2_rpt_list_invoice")
			#------------------------------------------------------------	
			#------------------------------------------------------------
			FINISH REPORT KS2_rpt_list_error
			CALL rpt_finish("KS2_rpt_list_error")
			#------------------------------------------------------------	
			 
		END IF 

		ON ACTION "PRINT MANAGER"	#COMMAND KEY ("P",f11) "Print" " Print AND View Exception AND Load reports via RMS"
			CALL run_prog("URS","","","","") 

		COMMAND "Directory" " List entries in specified directory" 
			--         DISPLAY "" AT 2,1 -- albo
			--         prompt "Enter UNIX Pathname: " FOR directory  -- albo
			LET directory= promptInput("Enter UNIX Pathname: ","",80) -- albo 
			IF int_flag OR quit_flag 
			OR directory IS NULL THEN 
				LET int_flag = false 
				LET quit_flag = false 
				LET directory = NULL 
			ELSE 
			LET runner = "ls -f ",directory clipped,"|pg" 
			RUN runner 
		END IF 
		
 
		COMMAND KEY(interrupt,"E") "Exit" " Exit TO menus" 
			EXIT MENU 

	END MENU 
	CLOSE WINDOW k160 
END MAIN 
###########################################################################
# END MAIN
###########################################################################


###########################################################################
# FUNCTION input_details()
#
# 
###########################################################################
FUNCTION input_details() 

	LET pr_subhead.sub_date = today 
	INPUT 
		pr_subhead.sub_date, 
		pr_subhead.ware_code, 
		modu_load_file WITHOUT DEFAULTS
	FROM
		sub_date, 
		ware_code, 
		modu_load_file ATTRIBUTE(UNBUFFERED)
	 

		ON ACTION "WEB-HELP" -- albo kd-374 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD sub_date 
			IF pr_subhead.start_date IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 
				NEXT FIELD sub_date 
			END IF 

		AFTER FIELD ware_code 
			IF pr_subhead.ware_code IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 
				NEXT FIELD ware_code 
			END IF 

			SELECT unique 1 FROM warehouse 
			WHERE ware_code = pr_subhead.ware_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = notfound THEN 
				ERROR kandoomsg2("U",9102,"") 
				NEXT FIELD ware_code 
			END IF 

		AFTER FIELD modu_load_file 
			IF modu_load_file IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 
				NEXT FIELD modu_load_file 
			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 

			ELSE 
				IF pr_subhead.sub_date IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") 
					NEXT FIELD sub_date 
				END IF
				 
				IF pr_subhead.ware_code IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") 
					NEXT FIELD ware_code 
				END IF 
				
				SELECT unique 1 FROM warehouse 
				WHERE ware_code = pr_subhead.ware_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = notfound THEN 
					ERROR kandoomsg2("U",9102,"") 
					NEXT FIELD ware_code 
				END IF 
				IF modu_load_file IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") 
					NEXT FIELD modu_load_file 
				END IF 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

	LET pr_ware_code = pr_subhead.ware_code 
	LET pr_sub_date = pr_subhead.sub_date 

	RETURN TRUE 
END FUNCTION 
###########################################################################
# END FUNCTION input_details()
###########################################################################


###########################################################################
# FUNCTION load_tables()FUNCTION input_details()
#
# 
###########################################################################
FUNCTION load_tables() 
	DEFINE l_cust CHAR(8) 
	DEFINE l_ship CHAR(8)
	
	WHENEVER ERROR CONTINUE 
	DELETE FROM t_loadtable WHERE 1=1 
	LOAD FROM modu_load_file INSERT INTO t_loadtable; 
	IF status !=0 THEN 
		IF status = -846 THEN 
			ERROR kandoomsg2("U",9119,"") 
		ELSE 
			ERROR kandoomsg2("G",9144,"") 
		END IF 
		RETURN false 
	END IF 
	WHENEVER ERROR stop 

	DECLARE c_loadtable CURSOR FOR 
	SELECT * FROM t_loadtable 
	ORDER BY cust_code,ship_code,part_code 
	
	FOREACH c_loadtable INTO pr_loadtable.* 
		SELECT * INTO pr_customer.* FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = pr_loadtable.cust_code 
		IF status = notfound OR pr_loadtable.cust_code IS NULL THEN 
			LET err_message = "Customer does NOT exist" 
			LET pr_subhead.cust_code = pr_loadtable.cust_code 
			LET pr_subhead.ship_code = pr_loadtable.ship_code 
			OUTPUT TO REPORT KS2_rpt_list_error(pr_subhead.*,err_message) 
			ERROR err_message 
			RETURN false 
		END IF 

		SELECT * INTO pr_customership.* FROM customership 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = pr_loadtable.cust_code 
		AND ship_code = pr_loadtable.ship_code 
		IF status = notfound OR pr_loadtable.ship_code IS NULL THEN 
			LET err_message = "Ship Code does NOT exist" 
			LET pr_subhead.cust_code = pr_loadtable.cust_code 
			LET pr_subhead.ship_code = pr_loadtable.ship_code 
			OUTPUT TO REPORT KS2_rpt_list_error(pr_subhead.*,err_message) 
			ERROR err_message 
			RETURN false 
		END IF 

		SELECT * INTO pr_substype.* FROM substype 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND type_code = pr_loadtable.sub_type 
		IF status = notfound OR pr_loadtable.sub_type IS NULL THEN 
			LET pr_subhead.cust_code = pr_loadtable.cust_code 
			LET pr_subhead.ship_code = pr_loadtable.ship_code 
			LET err_message = "sub type ",pr_loadtable.sub_type," NOT SET up" 
			OUTPUT TO REPORT KS2_rpt_list_error(pr_subhead.*,err_message) 
			ERROR err_message 
			RETURN false 
		END IF 

		SELECT * INTO pr_subproduct.* FROM subproduct 
		WHERE part_code = pr_loadtable.part_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND type_code = pr_loadtable.sub_type 
		IF status = notfound OR pr_loadtable.part_code IS NULL THEN 
			LET pr_subhead.cust_code = pr_loadtable.cust_code 
			LET pr_subhead.ship_code = pr_loadtable.ship_code 
			LET err_message = "Subscription Product ", 
			pr_subdetl.part_code clipped," NOT setup" 
			OUTPUT TO REPORT KS2_rpt_list_error(pr_subhead.*,err_message) 
			ERROR err_message 
			RETURN false 
		END IF 

		IF l_cust IS NULL OR 
		l_ship IS NULL OR 
		l_cust <> pr_loadtable.cust_code OR 
		l_ship <> pr_loadtable.ship_code THEN 
			LET l_cust = pr_loadtable.cust_code 
			LET l_ship = pr_loadtable.ship_code 
			CALL build_subhead() 
		END IF 

		CALL build_lines() 
	END FOREACH 

	RETURN true 
END FUNCTION 
###########################################################################
# END FUNCTION load_tables()FUNCTION input_details()
###########################################################################


###########################################################################
# FUNCTION build_subhead() 
#
# 
###########################################################################
FUNCTION build_subhead() 

	INITIALIZE pr_subhead.* TO NULL 

	LET pr_subhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET pr_subhead.ware_code = pr_ware_code 
	LET pr_subhead.cust_code = pr_loadtable.cust_code 
	LET pr_subhead.ship_code = pr_loadtable.ship_code 
	LET pr_subhead.sub_type_code = pr_loadtable.sub_type 
	LET pr_subhead.entry_code = glob_rec_kandoouser.sign_on_code 
	LET pr_subhead.entry_date = today 
	LET pr_subhead.rev_date = today 
	LET pr_subhead.sub_date = pr_sub_date 
	LET pr_subhead.ship_date = pr_sub_date 
	SELECT * INTO pr_substype.* FROM substype 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND type_code = pr_loadtable.sub_type 
	IF status = notfound THEN 
		LET err_message = "sub type ",pr_loadtable.sub_type," NOT SET up" 
		OUTPUT TO REPORT KS2_rpt_list_error(pr_subhead.*,err_message) 
		ERROR err_message 
		RETURN 
	END IF 
	
	LET pr_start_year = year(pr_subhead.sub_date) 
	IF month(pr_subhead.sub_date) < pr_substype.start_mth_num THEN 
		LET pr_start_year = pr_start_year - 1 
	END IF 

	LET pr_end_year = pr_start_year 

	IF pr_substype.start_mth_num > pr_substype.end_mth_num THEN 
		LET pr_end_year = pr_end_year + 1 
	END IF 

	LET pr_subhead.start_date = mdy(pr_substype.start_mth_num, 
	pr_substype.start_day_num, 
	pr_start_year) 

	LET pr_subhead.end_date = mdy(pr_substype.end_mth_num, 
	pr_substype.end_day_num, 
	pr_end_year) 

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
	LET pr_subhead.freight_inv_amt = 0 
	LET pr_subhead.hand_inv_amt = 0 
	LET pr_subhead.frttax_inv_amt = 0 
	LET pr_subhead.hndtax_inv_amt = 0 
	LET pr_currsub_amt = 0 
	LET pr_subhead.corp_flag = "N" 

	SELECT * INTO pr_customer.* FROM customer 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cust_code = pr_subhead.cust_code 

	LET pr_subhead.term_code = pr_customer.term_code 
	LET pr_subhead.tax_code = pr_customer.tax_code 
	LET pr_subhead.hand_tax_code = pr_customer.tax_code 
	LET pr_subhead.freight_tax_code = pr_customer.tax_code 
	LET pr_subhead.sales_code = pr_customer.sale_code 
	LET pr_subhead.territory_code = pr_customer.territory_code 
	LET pr_subhead.cond_code = pr_customer.cond_code 
	LET pr_subhead.invoice_to_ind = pr_customer.invoice_to_ind 
	LET pr_subhead.currency_code = pr_customer.currency_code 
	LET pr_subhead.conv_qty = 1 

	SELECT * INTO pr_customership.* FROM customership 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cust_code = pr_subhead.cust_code 
	AND ship_code = pr_subhead.ship_code 
	IF status = 0 THEN 
		LET pr_subhead.ship_code = pr_customership.ship_code 
		LET pr_subhead.ware_code = pr_customership.ware_code 
		LET pr_subhead.ship_name_text = pr_customership.name_text 
		LET pr_subhead.ship_addr1_text = pr_customership.addr_text 
		LET pr_subhead.ship_addr2_text = pr_customership.addr2_text 
		LET pr_subhead.ship_city_text = pr_customership.city_text 
		LET pr_subhead.state_code = pr_customership.state_code 
		LET pr_subhead.post_code = pr_customership.post_code 
		LET pr_subhead.country_code = pr_customership.country_code --@db-patch_2020_10_04--
		LET pr_subhead.contact_text = pr_customership.contact_text 
		LET pr_subhead.tele_text = pr_customership.tele_text 
	ELSE 
		LET pr_subhead.ship_name_text = pr_customer.name_text 
		LET pr_subhead.ship_addr1_text = pr_customer.addr1_text 
		LET pr_subhead.ship_addr2_text = pr_customer.addr2_text 
		LET pr_subhead.ship_city_text = pr_customer.city_text 
		LET pr_subhead.state_code = pr_customer.state_code 
		LET pr_subhead.post_code = pr_customer.post_code 
		LET pr_subhead.country_code = pr_customer.country_code --@db-patch_2020_10_04--
	END IF 
	
	INSERT INTO t_subhead VALUES (pr_subhead.*) 
	
	LET pr_subhead.sub_num = sqlca.sqlerrd[6] 
	
	UPDATE t_subhead SET sub_num = rowid 
	WHERE sub_num IS NULL 

END FUNCTION 
###########################################################################
# END FUNCTION build_subhead() 
###########################################################################

###########################################################################
# FUNCTION build_lines()  
#
# 
###########################################################################
FUNCTION build_lines() 

	IF pr_subdetl.sub_line_num IS NULL THEN 
		LET pr_subdetl.sub_line_num = 1 
	ELSE 
		LET pr_subdetl.sub_line_num = pr_subdetl.sub_line_num + 1 
	END IF 

	LET pr_subdetl.sub_num = pr_subhead.sub_num 
	LET pr_subdetl.ware_code = pr_ware_code 
	LET pr_subdetl.part_code = pr_loadtable.part_code 

	SELECT * INTO pr_subproduct.* FROM subproduct 
	WHERE part_code = pr_subdetl.part_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND type_code = pr_subhead.sub_type_code 
	IF status = notfound THEN 
		LET err_message = "Subscription Product ", 
		pr_subdetl.part_code," NOT setup" 
		OUTPUT TO REPORT KS2_rpt_list_error(pr_subhead.*,err_message) 
		ERROR err_message 
		RETURN 
	END IF 

	SELECT desc_text INTO pr_subdetl.line_text 
	FROM product 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_subdetl.part_code 
	LET pr_subdetl.unit_amt = pr_loadtable.unit_amt 
	LET pr_subdetl.sub_qty = 0 
	LET pr_subdetl.cust_code = pr_subhead.cust_code 
	LET pr_subdetl.ship_code = pr_subhead.ship_code 
	LET pr_subdetl.issue_qty = 0 
	LET pr_subdetl.inv_qty = 0 
	LET pr_subdetl.return_qty = 0 
	LET pr_subdetl.unit_tax_amt = 0 
	LET pr_subdetl.level_code = pr_customer.inv_level_ind 
	LET pr_subdetl.tax_code = pr_subhead.tax_code 

	CALL build_sched() 
	IF pr_subdetl.unit_amt IS NULL THEN 
		LET pr_subdetl.unit_amt = 
		unit_price(pr_subdetl.ware_code, 
		pr_subdetl.part_code, 
		pr_subdetl.level_code) 
		LET pr_subdetl.unit_tax_amt = 
		unit_tax(pr_subdetl.ware_code, 
		pr_subdetl.part_code, 
		pr_subdetl.unit_amt) 
	END IF 
	LET pr_subdetl.line_total_amt = pr_subdetl.sub_qty 
	* (pr_subdetl.unit_tax_amt+pr_subdetl.unit_amt) 
	INSERT INTO t_subdetl VALUES (pr_subdetl.*) 
END FUNCTION 
###########################################################################
# END FUNCTION build_lines()  
#
# 
###########################################################################


###########################################################################
# FUNCTION build_sched()  
#
# 
###########################################################################
FUNCTION build_sched() 
	DEFINE pr_subissues RECORD LIKE subissues.*
	DEFINE pr_subschedule RECORD LIKE subschedule.* 

	DECLARE c_subissues CURSOR FOR 
	SELECT * FROM subissues 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_subdetl.part_code 
	AND plan_iss_date between pr_subhead.start_date 
	AND pr_subhead.end_date 
	AND issue_num >= last_issue_num 
	ORDER BY issue_num,plan_iss_date 
	FOREACH c_subissues INTO pr_subissues.* 
		INITIALIZE pr_subschedule.* TO NULL 
		LET pr_subschedule.sub_num = pr_subdetl.sub_num 
		LET pr_subschedule.sub_line_num = pr_subdetl.sub_line_num 
		LET pr_subschedule.part_code = pr_subdetl.part_code 
		LET pr_subschedule.issue_num = pr_subissues.issue_num 
		LET pr_subschedule.sched_qty = pr_loadtable.sub_qty 
		LET pr_subschedule.issue_qty = 0 
		LET pr_subschedule.inv_qty = 0 
		LET pr_subschedule.sched_date = pr_subissues.plan_iss_date 
		LET pr_subschedule.desc_text = pr_subissues.desc_text 
		INSERT INTO t_subschedule VALUES (pr_subschedule.*) 
		LET pr_subdetl.sub_qty = pr_subdetl.sub_qty + pr_loadtable.sub_qty 
	END FOREACH 

END FUNCTION 
###########################################################################
# END FUNCTION build_sched()  
###########################################################################


###########################################################################
# FUNCTION unit_price(p_ware_code,p_part_code,p_level_ind)
#
# 
###########################################################################
FUNCTION unit_price(p_ware_code,p_part_code,p_level_ind) 
	DEFINE p_ware_code LIKE prodstatus.ware_code 
	DEFINE p_part_code LIKE prodstatus.part_code 
	DEFINE p_level_ind LIKE customer.inv_level_ind 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_price_amt LIKE prodstatus.list_amt 

	SELECT unit_amt INTO l_price_amt 
	FROM subcustomer 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = p_part_code 
	AND cust_code = pr_subhead.cust_code 
	AND sub_type_code = pr_subhead.sub_type_code 
	AND ship_code = pr_subhead.ship_code 
	AND comm_date = pr_subhead.start_date 
	AND end_date = pr_subhead.end_date 
	AND unit_amt > 0 
	IF status = notfound THEN 

		SELECT * INTO l_rec_prodstatus.* FROM prodstatus 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND ware_code = p_ware_code 
		AND part_code = p_part_code 
		IF sqlca.sqlcode = notfound THEN 
			LET l_price_amt = 0 
		ELSE 
			CASE p_level_ind 
				WHEN "1" LET l_price_amt = l_rec_prodstatus.price1_amt 
				WHEN "2" LET l_price_amt = l_rec_prodstatus.price2_amt 
				WHEN "3" LET l_price_amt = l_rec_prodstatus.price3_amt 
				WHEN "4" LET l_price_amt = l_rec_prodstatus.price4_amt 
				WHEN "5" LET l_price_amt = l_rec_prodstatus.price5_amt 
				WHEN "6" LET l_price_amt = l_rec_prodstatus.price6_amt 
				WHEN "7" LET l_price_amt = l_rec_prodstatus.price7_amt 
				WHEN "8" LET l_price_amt = l_rec_prodstatus.price8_amt 
				WHEN "9" LET l_price_amt = l_rec_prodstatus.price9_amt 
				WHEN "L" LET l_price_amt = l_rec_prodstatus.list_amt 
				WHEN "C" LET l_price_amt = l_rec_prodstatus.wgted_cost_amt 
				OTHERWISE LET l_price_amt = l_rec_prodstatus.list_amt 
			END CASE 
			LET l_price_amt = l_price_amt * pr_subhead.conv_qty 
		END IF 
	END IF 

	RETURN l_price_amt 
END FUNCTION 
###########################################################################
# END FUNCTION unit_price(p_ware_code,p_part_code,p_level_ind)
###########################################################################


###########################################################################
# FUNCTION unit_tax(p_ware_code,p_part_code,p_unit_amt)
#
# 
###########################################################################
FUNCTION unit_tax(p_ware_code,p_part_code,p_unit_amt) 
	DEFINE p_ware_code LIKE subdetl.ware_code 
	DEFINE p_part_code LIKE subdetl.part_code 
	DEFINE pr_tax RECORD LIKE tax.* 
	DEFINE pr_prodstatus RECORD LIKE prodstatus.* 
	DEFINE p_unit_amt LIKE subdetl.unit_amt 
	DEFINE pr_unit_tax_amt LIKE subdetl.unit_tax_amt 

	IF p_unit_amt IS NULL THEN 
		LET p_unit_amt = 0 
	END IF 

	SELECT * INTO pr_tax.* FROM tax 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tax_code = pr_subhead.tax_code 

	CASE pr_tax.calc_method_flag 
		WHEN "P" 
			IF p_part_code IS NULL THEN 
				LET pr_unit_tax_amt = 0 
			ELSE 
				SELECT * INTO pr_prodstatus.* FROM prodstatus 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = p_part_code 
				AND ware_code = p_ware_code 
				SELECT * INTO pr_tax.* FROM tax 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND tax_code = pr_prodstatus.sale_tax_code 
				IF pr_tax.calc_method_flag = "D" THEN 
					LET pr_unit_tax_amt = pr_prodstatus.sale_tax_amt 
				ELSE { use product tax code percentage} 
				IF pr_tax.tax_per IS NULL THEN 
					LET pr_tax.tax_per = 0 
				END IF 
				LET pr_unit_tax_amt = pr_tax.tax_per * p_unit_amt / 100 
			END IF 
		END IF 

		WHEN "D" {product based tax - tax amount} 
			IF p_part_code IS NULL THEN 
				LET pr_unit_tax_amt = 0 
			ELSE 
			SELECT sale_tax_amt INTO pr_unit_tax_amt 
			FROM prodstatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = p_part_code 
			AND ware_code = p_ware_code 
		END IF 

		WHEN "N" ## % FROM tax TABLE - line based 
			LET pr_unit_tax_amt = pr_tax.tax_per * p_unit_amt / 100 

		WHEN "T" ## % FROM tax TABLE - inv based 
			SELECT unique 1 FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = p_part_code 
			AND total_tax_flag = "Y" 
			IF sqlca.sqlcode = 0 THEN 
				LET pr_unit_tax_amt = pr_tax.tax_per * p_unit_amt / 100 
			ELSE 
			LET pr_unit_tax_amt = 0 
		END IF 

		OTHERWISE 
			LET pr_unit_tax_amt = 0 
	END CASE 

	RETURN pr_unit_tax_amt 
END FUNCTION 
###########################################################################
# END FUNCTION unit_tax(p_ware_code,p_part_code,p_unit_amt)
###########################################################################


###########################################################################
# REPORT KS2_rpt_list_error(p_rec_subhead,p_err_message)
#
# 
###########################################################################
REPORT KS2_rpt_list_error(p_rpt_idx,p_rec_subhead,p_err_message)
 	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_subhead RECORD LIKE subhead.* 
	DEFINE p_err_message CHAR(40) 
	DEFINE line1,line2 CHAR(80) 
	DEFINE offset1,offset2 SMALLINT 

	OUTPUT 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  

			PRINT COLUMN 2,"Subscription", 
			COLUMN 15,"Customer", 
			COLUMN 25,"Ship code", 
			COLUMN 35,"Error message" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  

		ON EVERY ROW 
			PRINT COLUMN 2,p_rec_subhead.sub_num USING "#########", 
			COLUMN 15,p_rec_subhead.cust_code, 
			COLUMN 25,p_rec_subhead.ship_code, 
			COLUMN 35,p_err_message
			 
		ON LAST ROW 
			NEED 4 LINES 
		 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	

END REPORT 
###########################################################################
# END REPORT KS2_rpt_list_error(p_rec_subhead,p_err_message)
###########################################################################


###########################################################################
# REPORT KS2_rpt_list_subscription(p_rpt_idx,p_rec_subhead) 
#
# 
###########################################################################
REPORT KS2_rpt_list_subscription(p_rpt_idx,p_rec_subhead)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE p_rec_subhead RECORD LIKE subhead.* 

	OUTPUT 
	top margin 0 
	left margin 0 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 2,"Subscription", 
			COLUMN 15,"Customer", 
			COLUMN 25,"Ship code", 
			COLUMN 35,"Amount" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			 
		ON EVERY ROW 
			PRINT COLUMN 2,p_rec_subhead.sub_num USING "#########", 
			COLUMN 15,p_rec_subhead.cust_code, 
			COLUMN 25,p_rec_subhead.ship_code, 
			COLUMN 35,p_rec_subhead.total_amt 

		ON LAST ROW 
			PRINT COLUMN 1,"----------------------------------------", 
			"----------------------------------------" 
			PRINT COLUMN 2, count(*), 
			COLUMN 35,sum(p_rec_subhead.total_amt) 

			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	

END REPORT 
###########################################################################
# END REPORT KS2_rpt_list_subscription(p_rec_subhead) 
###########################################################################


###########################################################################
# REPORT KS2_rpt_list_invoice(p_rpt_idx,p_rec_invoicehead)  
#
# 
###########################################################################
REPORT KS2_rpt_list_invoice(p_rpt_idx,p_rec_invoicehead) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_invoicehead RECORD LIKE invoicehead.* 

	OUTPUT 
	top margin 0 
	left margin 0 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 2,"Invoice", 
			COLUMN 15,"Customer", 
			COLUMN 25,"Ship code", 
			COLUMN 35,"Amount" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		ON EVERY ROW 
			PRINT COLUMN 2,p_rec_invoicehead.inv_num USING "#########", 
			COLUMN 15,p_rec_invoicehead.cust_code, 
			COLUMN 25,p_rec_invoicehead.ship_code, 
			COLUMN 35,p_rec_invoicehead.total_amt 

		ON LAST ROW 
			PRINT COLUMN 1,"----------------------------------------", 
			"----------------------------------------" 
			PRINT COLUMN 2, count(*), 
			COLUMN 35,sum(p_rec_invoicehead.total_amt) 

END REPORT 
###########################################################################
# END REPORT KS2_rpt_list_invoice(p_rpt_idx,p_rec_invoicehead)  
###########################################################################

###########################################################################
# FUNCTION insert_sub()  
#
# 
###########################################################################
FUNCTION insert_sub() 
	DEFINE l_rec_subhead RECORD LIKE subhead.* 
	DEFINE l_save_num LIKE subhead.sub_num 

	IF retry_lock(glob_rec_kandoouser.cmpy_code,0) THEN END IF 
		GOTO bypass 
		LABEL recovery: 
		IF error_recover(err_message,status) != "Y" THEN 
			RETURN false 
		END IF 
		LABEL bypass: 
		WHENEVER ERROR GOTO recovery
		 
		BEGIN WORK 
			DECLARE c_tsubhead CURSOR FOR 
			SELECT * FROM t_subhead 

			FOREACH c_tsubhead INTO pr_subhead.* 
				SELECT sum(unit_amt * sub_qty), 
				sum(unit_tax_amt * sub_qty), 
				sum(line_total_amt) 
				INTO pr_subhead.goods_amt, 
				pr_subhead.tax_amt, 
				pr_subhead.total_amt 
				FROM t_subdetl 
				WHERE (sub_num IS NULL OR sub_num = pr_subhead.sub_num) 

				IF pr_subhead.goods_amt IS NULL THEN 
					LET pr_subhead.goods_amt = 0 
				END IF 
				IF pr_subhead.tax_amt IS NULL THEN 
					LET pr_subhead.tax_amt = 0 
				END IF 
				IF pr_subhead.hand_amt IS NULL THEN 
					LET pr_subhead.hand_amt = 0 
				END IF 
				IF pr_subhead.freight_amt IS NULL THEN 
					LET pr_subhead.freight_amt = 0 
				END IF 
				LET pr_subhead.total_amt = pr_subhead.goods_amt 
				+ pr_subhead.tax_amt 
				+ pr_subhead.hand_amt 
				+ pr_subhead.hand_tax_amt 
				+ pr_subhead.freight_amt 
				+ pr_subhead.freight_tax_amt 

				UPDATE t_subhead SET goods_amt = pr_subhead.goods_amt, 
				tax_amt = pr_subhead.tax_amt, 
				hand_amt = pr_subhead.hand_amt, 
				hand_tax_amt = pr_subhead.hand_tax_amt, 
				freight_amt = pr_subhead.freight_amt, 
				freight_tax_amt = pr_subhead.freight_tax_amt, 
				total_amt = pr_subhead.total_amt 
				WHERE sub_num = pr_subhead.sub_num 
				LET l_save_num = pr_subhead.sub_num 
				LET err_message = "KS2 - Next Subscription Number update" 
				LET pr_subhead.sub_num = next_trans_num(glob_rec_kandoouser.cmpy_code,"SS","") 
				IF pr_subhead.sub_num < 0 THEN 
					LET err_message = "KS2 - Error Obtaining Next Trans no." 
					LET status = pr_subhead.sub_num 
					RETURN status 
				END IF 

				SELECT area_code INTO pr_subhead.area_code 
				FROM territory 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND terr_code = pr_subhead.territory_code 

				LET pr_subhead.sub_ind = "2" 
				LET l_rec_subhead.* = pr_subhead.* 
				LET l_rec_subhead.goods_amt = 0 
				LET l_rec_subhead.hand_amt = 0 
				LET l_rec_subhead.paid_amt = 0 
				LET l_rec_subhead.hand_tax_amt = 0 
				LET l_rec_subhead.freight_amt = 0 
				LET l_rec_subhead.freight_tax_amt = 0 
				LET l_rec_subhead.tax_amt = 0 
				LET l_rec_subhead.disc_amt = 0 
				LET l_rec_subhead.total_amt = 0 
				LET l_rec_subhead.cost_amt = 0 
				LET l_rec_subhead.line_num = 0 
				LET l_rec_subhead.status_ind = "I" 
				LET err_message = " KS2 - Adding subscription Header row" 

				INSERT INTO subhead VALUES (l_rec_subhead.*) 
				IF l_save_num IS NULL THEN 
					UPDATE t_subhead SET sub_num = pr_subhead.sub_num 
					WHERE sub_num IS NULL 
					UPDATE t_subdetl SET sub_num = pr_subhead.sub_num 
					WHERE sub_num IS NULL 
					UPDATE t_subschedule SET sub_num = pr_subhead.sub_num 
					WHERE sub_num IS NULL 
				ELSE 
				UPDATE t_subhead SET sub_num = pr_subhead.sub_num 
				WHERE sub_num = l_save_num 
				UPDATE t_subdetl SET sub_num = pr_subhead.sub_num 
				WHERE sub_num = l_save_num 
				UPDATE t_subschedule SET sub_num = pr_subhead.sub_num 
				WHERE sub_num = l_save_num 
			END IF 
		END FOREACH 
		
	COMMIT WORK
	 
	WHENEVER ERROR CONTINUE
	 
	RETURN true 
END FUNCTION 
###########################################################################
# END FUNCTION insert_sub()  
###########################################################################


###########################################################################
# FUNCTION write_sub(p_mode)  
#
# 
###########################################################################
FUNCTION write_sub(p_mode) 
	DEFINE p_mode CHAR(4)
	DEFINE 
	ps_subhead RECORD LIKE subhead.*, 
	pt_subhead RECORD LIKE subhead.*, 
	pr_substype RECORD LIKE substype.*, 
	pr_subproduct RECORD LIKE subproduct.*, 
	pr_subdetl RECORD LIKE subdetl.*, 
	pr_invoicedetl RECORD LIKE invoicedetl.*, 
	pr_invoicehead RECORD LIKE invoicehead.*, 
	pr_customer RECORD LIKE customer.*, 
	pr_cashreceipt RECORD LIKE cashreceipt.*, 
	pr_customertype RECORD LIKE customertype.*, 
	pr_subcustomer RECORD LIKE subcustomer.*, 
	pr_subaudit RECORD LIKE subaudit.*, 
	pr_prodledg RECORD LIKE prodledg.*, 
	pr_product RECORD LIKE product.*, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pr_araudit RECORD LIKE araudit.*, 
	pr_term RECORD LIKE term.*, 
	pr_save_line_num LIKE subdetl.sub_line_num, 
	pr_inv_num CHAR(4), 
	pr2_paid_amt DECIMAL(16,2), 
	total_cost,total_sale,total_tax DECIMAL(16,2), 
	prg_name CHAR(8), 
	idx SMALLINT, 
	pr_float FLOAT, 
	pr_subschedule RECORD LIKE subschedule.* 

	IF retry_lock(glob_rec_kandoouser.cmpy_code,0) THEN END IF 
		GOTO bypass 
		LABEL recovery: 
		LET pr_subhead.* = ps_subhead.* 
		IF error_recover(err_message,status) != "Y" THEN 
			OUTPUT TO REPORT KS2_rpt_list_error(pr_subhead.*,err_message) 
			RETURN 
		END IF 
		LABEL bypass: 
		WHENEVER ERROR GOTO recovery 

		BEGIN WORK 
			DECLARE c_subhead CURSOR FOR 
			SELECT * FROM subhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND sub_num = pr_subhead.sub_num 
			FOR UPDATE 
			DECLARE c2_tsubhead CURSOR FOR 
			SELECT * FROM t_subhead 

			FOREACH c2_tsubhead INTO pr_subhead.* 
				LET idx = 0 
				LET total_cost = 0 
				LET total_sale = 0 
				LET total_tax = 0 
				IF pr_paid_amt IS NULL THEN 
					LET pr_paid_amt = 0 
				END IF 

				LET pr2_paid_amt = pr_paid_amt 
				SELECT * INTO pr_customer.* 
				FROM customer 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = pr_subhead.cust_code 

				## Declare Insert Cursor's
				## Subdetl
				DECLARE c_subdetl CURSOR FOR 
				INSERT INTO subdetl VALUES (pr_subdetl.*) 
				OPEN c_subdetl 

				## subschedule
				DECLARE c_subschedule CURSOR FOR 
				INSERT INTO subschedule VALUES (pr_subschedule.*) 
				OPEN c_subschedule 

				##
				LET ps_subhead.* = pr_subhead.* 
				LET err_message = "KS2 - Locking Subscription Header record" 
				OPEN c_subhead 
				FETCH c_subhead INTO pt_subhead.* 

				IF pt_subhead.rev_num != pr_subhead.rev_num THEN 
					LET err_message = "KS2 - Subscription has changed during edit" 
					GOTO recovery 
				END IF 

				IF pt_subhead.last_inv_num != pr_subhead.last_inv_num THEN 
					LET err_message = "KS2 - Subscription has been invoiced during edit" 
					GOTO recovery 
				END IF 

				SELECT * INTO pr_substype.* 
				FROM substype 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND type_code = pr_subhead.sub_type_code 
				LET err_message = "KS2 - Removing Existing Sub Line items" 

				DECLARE c1_subdetl CURSOR FOR 
				SELECT * FROM subdetl 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = pr_subhead.cust_code 
				AND sub_num = pr_subhead.sub_num 
				FOR UPDATE 

				FOREACH c1_subdetl INTO pr_subdetl.* 
					SELECT * INTO pr_subcustomer.* 
					FROM subcustomer 
					WHERE cmpy_code= glob_rec_kandoouser.cmpy_code 
					AND cust_code= pr_subhead.cust_code 
					AND ship_code= pr_subhead.ship_code 
					AND sub_type_code = pr_subhead.sub_type_code 
					AND part_code= pr_subdetl.part_code 
					AND comm_date= pr_subhead.start_date 
					AND end_date= pr_subhead.end_date 
					IF status = 0 THEN 
						LET pr_subcustomer.next_seq_num = pr_subcustomer.next_seq_num + 1 
						UPDATE subcustomer 
						SET next_seq_num = pr_subcustomer.next_seq_num, 
						unit_amt = pr_subdetl.unit_amt, 
						unit_tax_amt = pr_subdetl.unit_tax_amt 
						WHERE cmpy_code= glob_rec_kandoouser.cmpy_code 
						AND cust_code= pr_subhead.cust_code 
						AND ship_code= pr_subhead.ship_code 
						AND sub_type_code = pr_subhead.sub_type_code 
						AND part_code= pr_subdetl.part_code 
						AND comm_date= pr_subhead.start_date 
						AND end_date= pr_subhead.end_date 
					ELSE 
					LET pr_subcustomer.cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET pr_subcustomer.cust_code = pr_subhead.cust_code 
					LET pr_subcustomer.ship_code = pr_subhead.ship_code 
					LET pr_subcustomer.sub_type_code = pr_subhead.sub_type_code 
					LET pr_subcustomer.part_code = pr_subdetl.part_code 
					LET pr_subcustomer.comm_date = pr_subhead.start_date 
					LET pr_subcustomer.end_date = pr_subhead.end_date 
					LET pr_subcustomer.entry_date = today 
					LET pr_subcustomer.entry_code = glob_rec_kandoouser.sign_on_code 
					LET pr_subcustomer.unit_amt = pr_subdetl.unit_amt 
					LET pr_subcustomer.unit_tax_amt = pr_subdetl.unit_tax_amt 
					LET pr_subcustomer.currency_code =pr_subhead.currency_code 
					LET pr_subcustomer.conv_qty = pr_subhead.conv_qty 
					LET pr_subcustomer.bonus_ind = "N" 
					LET pr_subcustomer.status_ind = "0" 
					LET pr_subcustomer.next_seq_num = 1 
					LET pr_subcustomer.last_issue_num = 0 
					INSERT INTO subcustomer VALUES (pr_subcustomer.*) 
				END IF 

				LET pr_subaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET pr_subaudit.part_code = pr_subdetl.part_code 
				LET pr_subaudit.cust_code = pr_subhead.cust_code 
				LET pr_subaudit.ship_code = pr_subhead.ship_code 
				LET pr_subaudit.start_date = pr_subhead.start_date 
				LET pr_subaudit.end_date = pr_subhead.end_date 
				LET pr_subaudit.seq_num = pr_subcustomer.next_seq_num 
				LET pr_subaudit.tran_date = pr_subhead.sub_date 
				LET pr_subaudit.entry_date = today 
				LET pr_subaudit.entry_code = glob_rec_kandoouser.sign_on_code 
				LET pr_subaudit.tran_qty = 0 - pr_subdetl.sub_qty + 0 
				LET pr_subaudit.unit_amt = pr_subdetl.unit_amt 
				LET pr_subaudit.unit_tax_amt = pr_subdetl.unit_tax_amt 
				LET pr_subaudit.currency_code = pr_subhead.currency_code 
				LET pr_subaudit.conv_qty = pr_subhead.conv_qty 
				LET pr_subaudit.tran_type_ind = "SUB" 
				LET pr_subaudit.sub_num = pr_subhead.sub_num 
				LET pr_subaudit.source_num = pr_subhead.sub_num 
				LET pr_subaudit.sub_type_code = pr_subhead.sub_type_code 
				LET pr_subaudit.comm_text = "Subscription Edit " 
				INSERT INTO subaudit VALUES (pr_subaudit.*) 
				DELETE FROM subdetl 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = pr_subhead.cust_code 
				AND sub_num = pr_subhead.sub_num 
				AND sub_line_num = pr_subdetl.sub_line_num 
				DELETE FROM subschedule 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND sub_num = pr_subhead.sub_num 
				AND sub_line_num = pr_subdetl.sub_line_num 
			END FOREACH 

			LET pr_subhead.line_num = 0 
			DECLARE c_t_subdetl CURSOR FOR 

			SELECT * FROM t_subdetl 
			WHERE sub_num = pr_subhead.sub_num 
			ORDER BY sub_line_num 
			DECLARE c_t_subschedule CURSOR FOR 

			SELECT * FROM t_subschedule 
			WHERE sub_line_num = pr_save_line_num 
			AND sub_num = pr_subhead.sub_num 
			ORDER BY issue_num 

			FOREACH c_t_subdetl INTO pr_subdetl.* 
				LET pr_save_line_num = pr_subdetl.sub_line_num 
				LET pr_subhead.line_num = pr_subhead.line_num + 1 
				LET pr_subdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET pr_subdetl.cust_code = pr_subhead.cust_code 
				LET pr_subdetl.sub_num = pr_subhead.sub_num 
				LET pr_subdetl.sub_line_num = pr_subhead.line_num 
				IF pr_subdetl.status_ind IS NULL THEN 
					LET pr_subdetl.status_ind = "1" 
				END IF 
				SELECT * INTO pr_subcustomer.* 
				FROM subcustomer 
				WHERE cmpy_code= glob_rec_kandoouser.cmpy_code 
				AND cust_code= pr_subhead.cust_code 
				AND ship_code= pr_subhead.ship_code 
				AND sub_type_code = pr_subhead.sub_type_code 
				AND part_code= pr_subdetl.part_code 
				AND comm_date= pr_subhead.start_date 
				AND end_date= pr_subhead.end_date 
				IF status = 0 THEN 
					LET pr_subcustomer.next_seq_num = pr_subcustomer.next_seq_num + 1 
					UPDATE subcustomer 
					SET next_seq_num = pr_subcustomer.next_seq_num, 
					unit_amt = pr_subdetl.unit_amt, 
					unit_tax_amt = pr_subdetl.unit_tax_amt 
					WHERE cmpy_code= glob_rec_kandoouser.cmpy_code 
					AND cust_code= pr_subhead.cust_code 
					AND ship_code= pr_subhead.ship_code 
					AND sub_type_code = pr_subhead.sub_type_code 
					AND part_code= pr_subdetl.part_code 
					AND comm_date= pr_subhead.start_date 
					AND end_date= pr_subhead.end_date 
				ELSE 
				LET pr_subcustomer.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET pr_subcustomer.cust_code = pr_subhead.cust_code 
				LET pr_subcustomer.ship_code = pr_subhead.ship_code 
				LET pr_subcustomer.sub_type_code = pr_subhead.sub_type_code 
				LET pr_subcustomer.part_code = pr_subdetl.part_code 
				LET pr_subcustomer.comm_date = pr_subhead.start_date 
				LET pr_subcustomer.end_date = pr_subhead.end_date 
				LET pr_subcustomer.entry_date = today 
				LET pr_subcustomer.entry_code = glob_rec_kandoouser.sign_on_code 
				LET pr_subcustomer.unit_amt = pr_subdetl.unit_amt 
				LET pr_subcustomer.unit_tax_amt = pr_subdetl.unit_tax_amt 
				LET pr_subcustomer.currency_code =pr_subhead.currency_code 
				LET pr_subcustomer.conv_qty = pr_subhead.conv_qty 
				LET pr_subcustomer.bonus_ind = "N" 
				LET pr_subcustomer.status_ind = "0" 
				LET pr_subcustomer.next_seq_num = 1 
				LET pr_subcustomer.last_issue_num = 0 
				INSERT INTO subcustomer VALUES (pr_subcustomer.*) 
			END IF 

			LET pr_subaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET pr_subaudit.part_code = pr_subdetl.part_code 
			LET pr_subaudit.cust_code = pr_subhead.cust_code 
			LET pr_subaudit.ship_code = pr_subhead.ship_code 
			LET pr_subaudit.start_date = pr_subhead.start_date 
			LET pr_subaudit.end_date = pr_subhead.end_date 
			LET pr_subaudit.seq_num = pr_subcustomer.next_seq_num 
			LET pr_subaudit.tran_date = pr_subhead.sub_date 
			LET pr_subaudit.entry_date = today 
			LET pr_subaudit.entry_code = glob_rec_kandoouser.sign_on_code 
			LET pr_subaudit.tran_qty = pr_subdetl.sub_qty 
			LET pr_subaudit.unit_amt = pr_subdetl.unit_amt 
			LET pr_subaudit.unit_tax_amt = pr_subdetl.unit_tax_amt 
			LET pr_subaudit.currency_code = pr_subhead.currency_code 
			LET pr_subaudit.conv_qty = pr_subhead.conv_qty 
			LET pr_subaudit.tran_type_ind = "SUB" 
			LET pr_subaudit.sub_num = pr_subhead.sub_num 
			LET pr_subaudit.source_num = pr_subhead.sub_num 
			LET pr_subaudit.comm_text = "Subscription entry" 
			LET pr_subaudit.sub_type_code = pr_subhead.sub_type_code 
			INSERT INTO subaudit VALUES (pr_subaudit.*) 
			#################################################
			# are there any invoice lines
			#################################################
			IF pr_substype.inv_ind = "1" OR 
			pr_substype.inv_ind = "4" THEN 
				SELECT * INTO pr_subproduct.* 
				FROM subproduct 
				WHERE part_code = pr_subdetl.part_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND type_code = pr_subhead.sub_type_code 
				IF status = notfound THEN 
					LET err_message = "Subscription Product ", 
					pr_subdetl.part_code," NOT setup" 
					LET status = -1 
					GOTO recovery 
				END IF 
				INITIALIZE pr_invoicedetl.* TO NULL 
				LET idx = idx + 1 
				LET pr_invoicedetl.line_num = idx 
				LET pr_invoicedetl.cust_code = pr_subdetl.cust_code 
				LET pr_invoicedetl.part_code = pr_subdetl.part_code 
				LET pr_invoicedetl.ware_code = pr_subdetl.ware_code 
				LET pr_invoicedetl.line_text = pr_subdetl.line_text 
				LET pr_invoicedetl.ship_qty = pr_subdetl.sub_qty - 
				pr_subdetl.inv_qty 
				LET pr_invoicedetl.unit_sale_amt = pr_subdetl.unit_amt 
				LET pr_invoicedetl.unit_tax_amt = pr_subdetl.unit_tax_amt 
				LET pr_invoicedetl.ext_sale_amt = pr_subdetl.unit_amt * 
				pr_invoicedetl.ship_qty 
				LET pr_invoicedetl.ext_tax_amt = pr_subdetl.unit_tax_amt * 
				pr_invoicedetl.ship_qty 
				LET pr_invoicedetl.line_total_amt= 
				pr_invoicedetl.ext_sale_amt + 
				pr_invoicedetl.ext_tax_amt 
				SELECT * INTO pr_product.* 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pr_invoicedetl.part_code 
				LET pr_invoicedetl.cat_code = pr_product.cat_code 
				LET pr_invoicedetl.ser_flag = pr_product.serial_flag 
				IF pr_invoicedetl.line_text IS NULL THEN 
					LET pr_invoicedetl.line_text = pr_product.desc_text 
				END IF 
				LET pr_invoicedetl.uom_code = pr_product.sell_uom_code 
				LET pr_invoicedetl.order_num = pr_subhead.sub_num 
				LET pr_invoicedetl.order_line_num = pr_subdetl.sub_line_num 
				LET pr_invoicedetl.uom_code = pr_product.sell_uom_code 
				LET pr_invoicedetl.prodgrp_code = pr_product.prodgrp_code 
				LET pr_invoicedetl.maingrp_code = pr_product.maingrp_code 
				IF pr_subproduct.linetype_ind = "1" THEN 
					SELECT subacct_code INTO pr_invoicedetl.line_acct_code 
					FROM substype 
					WHERE cmpy_code = cmpy_code 
					AND type_code = pr_subhead.sub_type_code 
					AND subacct_code IS NOT NULL 
					IF status = notfound THEN 
						SELECT sub_acct_code INTO pr_invoicedetl.line_acct_code 
						FROM ssparms 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					END IF 
				ELSE 
				SELECT sale_acct_code INTO pr_invoicedetl.line_acct_code 
				FROM category 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cat_code = pr_invoicedetl.cat_code 
			END IF 
			SELECT * INTO pr_prodstatus.* 
			FROM prodstatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ware_code = pr_invoicedetl.ware_code 
			AND part_code = pr_invoicedetl.part_code 
			LET pr_invoicedetl.unit_cost_amt = pr_prodstatus.wgted_cost_amt 
			* pr_subhead.conv_qty 
			LET pr_invoicedetl.ext_cost_amt = 
			pr_invoicedetl.unit_cost_amt * 
			pr_invoicedetl.ship_qty 
			LET pr_invoicedetl.list_price_amt = pr_prodstatus.list_amt 
			* pr_subhead.conv_qty 
			IF pr_invoicedetl.list_price_amt = 0 THEN 
				LET pr_invoicedetl.list_price_amt = 
				pr_invoicedetl.unit_sale_amt 
				LET pr_invoicedetl.disc_per = 0 
			END IF 
			IF pr_invoicedetl.disc_per IS NULL THEN 
				## calc disc_per based on price
				LET pr_float = 100 * 
				(pr_invoicedetl.list_price_amt 
				-pr_invoicedetl.unit_sale_amt) 
				/pr_invoicedetl.list_price_amt 
				IF pr_float <= 0 THEN 
					LET pr_invoicedetl.disc_per = 0 
					LET pr_invoicedetl.list_price_amt = 
					pr_invoicedetl.unit_sale_amt 
				ELSE 
				LET pr_invoicedetl.disc_per = pr_float 
			END IF 
		END IF 
		LET pr_invoicedetl.disc_amt = 
		pr_invoicedetl.list_price_amt 
		- pr_invoicedetl.unit_sale_amt 
		LET total_cost = total_cost + pr_invoicedetl.ext_cost_amt 
		LET total_sale = total_sale + pr_invoicedetl.ext_sale_amt 
		LET total_tax = total_tax + pr_invoicedetl.ext_tax_amt 
		IF pr_invoicedetl.ship_qty > 0 THEN 
			INSERT INTO t_invoicedetl VALUES (pr_invoicedetl.*) 
		END IF 
		LET pr_subdetl.inv_qty = pr_subdetl.inv_qty+ pr_invoicedetl.ship_qty 
		IF pr_subproduct.linetype_ind = "1" THEN 
			UPDATE t_subschedule SET inv_qty = sched_qty 
			WHERE sub_line_num = pr_save_line_num 
		ELSE 
			LET pr_subdetl.issue_qty = pr_subdetl.inv_qty 
		END IF 
	END IF 
	LET err_message = "KS2 - Sub Line Item insert" 
	PUT c_subdetl
	 
	FOREACH c_t_subschedule INTO pr_subschedule.* 
		LET pr_subschedule.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pr_subschedule.sub_num = pr_subhead.sub_num 
		LET pr_subschedule.sub_line_num = pr_subdetl.sub_line_num 
		LET err_message = "KS2 - Sub Line Item insert" 
		PUT c_subschedule 
	END FOREACH 
	END FOREACH 
	FLUSH c_subschedule 
	CLOSE c_subschedule 
	FLUSH c_subdetl 
	CLOSE c_subdetl 

	LET pr_subhead.rev_num = pr_subhead.rev_num + 1 
	LET pr_subhead.rev_date = today 
	LET pr_subhead.cost_ind = pr_arparms.costings_ind 
	LET err_message = "KS2 - Update Subscription Header record" 

	IF pr_subhead.line_num = 0 THEN 

	## No lines exist THEN sub IS cancelled
	LET pr_subhead.status_ind = "C" 
	ELSE 
	SELECT unique 1 FROM subdetl 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND sub_num = pr_subhead.sub_num 
	AND (inv_qty != 0 
	OR issue_qty != 0) 

	IF sqlca.sqlcode = notfound THEN 
		## No lines shipped THEN sub IS unshipped
		LET pr_subhead.status_ind = "U" 
		ELSE 
		SELECT unique 1 FROM subdetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND sub_num = pr_subhead.sub_num 
		AND (inv_qty != sub_qty 
		OR inv_qty != issue_qty 
		OR issue_qty != sub_qty) 

		IF sqlca.sqlcode = 0 THEN 
			## Incomplete lines exists so sub IS partial shipped
			LET pr_subhead.status_ind = "P" 
			ELSE 
			LET pr_subhead.status_ind = "C" 
			END IF 
		END IF 
	END IF 

	IF pr_subhead.sales_code IS NULL THEN 
		LET pr_subhead.sales_code = pr_customer.sale_code 
	END IF 

	IF pr_subhead.territory_code IS NULL THEN 
		LET pr_subhead.territory_code = pr_customer.territory_code 
	END IF 

	IF pr_subhead.delivery_ind IS NULL THEN 
		LET pr_subhead.delivery_ind = "1" 
	END IF 

	IF pr_subhead.paid_amt IS NULL THEN 
		LET pr_subhead.paid_amt = 0 
	END IF 

	IF (pr_subhead.total_amt - pr_subhead.paid_amt) < pr2_paid_amt THEN 
		LET pr2_paid_amt = pr2_paid_amt - (pr_subhead.total_amt	- pr_subhead.paid_amt) 
		LET pr_subhead.paid_amt = pr_subhead.total_amt 
	ELSE 
		LET pr_subhead.paid_amt = pr_subhead.paid_amt + pr2_paid_amt 
		LET pr2_paid_amt = 0 
	END IF 

	UPDATE subhead SET * = pr_subhead.* 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND sub_num = pr_subhead.sub_num 
	OUTPUT TO REPORT KS2_rpt_list_subscription(pr_subhead.*) 

	###################################################
	## Does Invoice need TO be created
	###################################################
	IF pr_subhead.hand_inv_amt IS NULL THEN 
	LET pr_subhead.hand_inv_amt = 0 
	END IF 

	IF pr_subhead.hndtax_inv_amt IS NULL THEN 
	LET pr_subhead.hndtax_inv_amt = 0 
	END IF 

	IF pr_subhead.freight_inv_amt IS NULL THEN 
	LET pr_subhead.freight_inv_amt = 0 
	END IF 

	IF pr_subhead.frttax_inv_amt IS NULL THEN 
	LET pr_subhead.frttax_inv_amt = 0 
	END IF 
	LET pr_invoicehead.inv_num = 0 

	SELECT unique 1 FROM t_invoicedetl 
	WHERE ship_qty > 0 
	AND order_num = pr_subhead.sub_num 
	IF status = 0 THEN 
		IF pr_customer.corp_cust_code IS NOT NULL	AND pr_customer.corp_cust_ind = "1" THEN 
			LET pr_invoicehead.cust_code = pr_customer.corp_cust_code 
			LET pr_invoicehead.org_cust_code = pr_subhead.cust_code 
		ELSE 
			LET pr_invoicehead.cust_code = pr_subhead.cust_code 
			LET pr_invoicehead.org_cust_code = pr_subhead.cust_code 
		END IF 
	DECLARE c_customer CURSOR FOR 
	SELECT * FROM customer 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cust_code = pr_invoicehead.cust_code 

	FOR UPDATE 
	OPEN c_customer 
	FETCH c_customer INTO pr_customer.* 

	LET pr_invoicehead.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET pr_invoicehead.ord_num = pr_subhead.sub_num 
	LET pr_invoicehead.purchase_code = pr_subhead.ord_text 
	LET pr_invoicehead.job_code = NULL 
	LET pr_invoicehead.inv_date = pr_subhead.sub_date 
	LET pr_invoicehead.entry_code = pr_subhead.entry_code 
	LET pr_invoicehead.entry_date = pr_subhead.entry_date 
	LET pr_invoicehead.sale_code = pr_subhead.sales_code 
	LET pr_invoicehead.term_code = pr_subhead.term_code 
	LET pr_invoicehead.tax_code = pr_subhead.tax_code 

	SELECT tax_per INTO pr_invoicehead.tax_per FROM tax 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tax_code = pr_invoicehead.tax_code 

	LET pr_invoicehead.goods_amt = total_sale 
	LET pr_invoicehead.hand_amt = pr_subhead.hand_amt -	pr_subhead.hand_inv_amt 
	LET pr_invoicehead.hand_tax_code = pr_subhead.hand_tax_code 
	LET pr_invoicehead.hand_tax_amt = pr_subhead.hand_tax_amt -	pr_subhead.hndtax_inv_amt 
	LET pr_invoicehead.freight_amt = pr_subhead.freight_amt -	pr_subhead.freight_inv_amt 
	LET pr_invoicehead.freight_tax_code = pr_subhead.freight_tax_code 
	LET pr_invoicehead.freight_tax_amt = pr_subhead.freight_tax_amt -	pr_subhead.frttax_inv_amt 
	LET pr_invoicehead.tax_amt = total_tax 
	LET pr_invoicehead.total_amt = pr_invoicehead.goods_amt 
	+ pr_invoicehead.tax_amt 
	+ pr_invoicehead.hand_amt 
	+ pr_invoicehead.hand_tax_amt 
	+ pr_invoicehead.freight_amt 
	+ pr_invoicehead.freight_tax_amt 

	LET pr_invoicehead.cost_amt = total_cost 
	LET pr_invoicehead.paid_amt = 0 
	LET pr_invoicehead.paid_date = NULL 
	LET pr_invoicehead.disc_taken_amt = 0
	 
	SELECT * INTO pr_term.* 
	FROM term 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND term_code = pr_invoicehead.term_code 
	CALL get_due_and_discount_date(pr_term.*,pr_invoicehead.inv_date) 
	RETURNING pr_invoicehead.due_date,	pr_invoicehead.disc_date
	 
	LET pr_invoicehead.disc_amt=	(pr_invoicehead.total_amt*pr_term.disc_per/100) 
	LET pr_invoicehead.expected_date = NULL
	 
	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,pr_invoicehead.inv_date) 
	RETURNING pr_invoicehead.year_num,	pr_invoicehead.period_num 

	LET pr_invoicehead.on_state_flag = "N" 
	LET pr_invoicehead.posted_flag = "N" 
	LET pr_invoicehead.seq_num = 0 
	LET pr_invoicehead.line_num = idx 
	LET pr_invoicehead.printed_num = 0 
	LET pr_invoicehead.story_flag = NULL 
	LET pr_invoicehead.rev_date = today 
	LET pr_invoicehead.rev_num = 0 
	LET pr_invoicehead.ship_code = pr_subhead.ship_code 
	LET pr_invoicehead.name_text = pr_subhead.ship_name_text 
	LET pr_invoicehead.addr1_text = pr_subhead.ship_addr1_text 
	LET pr_invoicehead.addr2_text = pr_subhead.ship_addr2_text 
	LET pr_invoicehead.city_text = pr_subhead.ship_city_text 
	LET pr_invoicehead.state_code = pr_subhead.state_code 
	LET pr_invoicehead.post_code = pr_subhead.post_code 
	LET pr_invoicehead.country_code = pr_subhead.country_code --@db-patch_2020_10_04--
	LET pr_invoicehead.ship1_text = pr_subhead.ship1_text 
	LET pr_invoicehead.ship2_text = pr_subhead.ship2_text 
	LET pr_invoicehead.ship_date = pr_subhead.ship_date 
	LET pr_invoicehead.fob_text = pr_subhead.fob_text 
	LET pr_invoicehead.prepaid_flag = pr_subhead.prepaid_flag 
	LET pr_invoicehead.com1_text = pr_subhead.com1_text 
	LET pr_invoicehead.com2_text = pr_subhead.com2_text 
	LET pr_invoicehead.cost_ind = pr_subhead.cost_ind 
	LET pr_invoicehead.currency_code = pr_subhead.currency_code 
	LET pr_invoicehead.conv_qty = pr_subhead.conv_qty 
	LET pr_invoicehead.inv_ind = "7" 
	LET pr_invoicehead.prev_paid_amt = 0 
	LET pr_invoicehead.acct_override_code =pr_subhead.acct_override_code 
	LET pr_invoicehead.price_tax_flag = pr_subhead.price_tax_flag 
	LET pr_invoicehead.contact_text = pr_subhead.contact_text 
	LET pr_invoicehead.tele_text = pr_subhead.tele_text 
	LET pr_invoicehead.invoice_to_ind = pr_subhead.invoice_to_ind 
	LET pr_invoicehead.territory_code = pr_subhead.territory_code 
	LET pr_invoicehead.mgr_code = pr_subhead.mgr_code 
	LET pr_invoicehead.area_code = pr_subhead.area_code 
	LET pr_invoicehead.cond_code = pr_subhead.cond_code 
	LET pr_invoicehead.scheme_amt = pr_subhead.scheme_amt 
	LET pr_invoicehead.jour_num = NULL 
	LET pr_invoicehead.post_date = NULL 
	LET pr_invoicehead.carrier_code = pr_subhead.carrier_code 
	LET pr_invoicehead.manifest_num = NULL 
	LET pr_invoicehead.stat_date = NULL 
	LET pr_invoicehead.country_code = pr_customer.country_code 
	
	LET pr_temp_text = "SELECT * FROM prodstatus ", 
	" WHERE cmpy_code ='",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND part_code = ? AND ware_code = ? "
	 
	PREPARE s_prodstatus FROM pr_temp_text 
	DECLARE c_prodstatus CURSOR FOR s_prodstatus 
	LET pr_temp_text = "SELECT * FROM subcustomer ", 
	"WHERE cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND cust_code= ? ", 
	"AND ship_code= ? ", 
	"AND sub_type_code = ? ", 
	"AND part_code= ? ", 
	"AND comm_date= ? ", 
	"AND end_date= ? "
	 
	PREPARE s2_subcustomer FROM pr_temp_text 
	DECLARE c2_subcustomer CURSOR FOR s2_subcustomer 
	
	#INSERT invoiceDetl Record
	DECLARE c1_invoicedetl CURSOR FOR 
	INSERT INTO invoicedetl VALUES (pr_invoicedetl.*)		
 
	OPEN c1_invoicedetl 
	DECLARE c_prodledg CURSOR FOR 

	INSERT INTO prodledg VALUES (pr_prodledg.*) 
	OPEN c_prodledg 
	DECLARE c_subaudit CURSOR FOR 

	INSERT INTO subaudit VALUES (pr_subaudit.*) 
	OPEN c_subaudit 
	LET err_message = "KS2 - Next invoice number update" 
	LET pr_invoicehead.inv_num = next_trans_num(
		glob_rec_kandoouser.cmpy_code,
		TRAN_TYPE_INVOICE_IN,
		pr_invoicehead.acct_override_code) 

	IF pr_invoicehead.inv_num < 0 THEN 
		LET err_message = "KS2 - Error Obtaining Next Trans no." 
		LET status = pr_invoicehead.inv_num 
		GOTO recovery 
	END IF 

	DECLARE c_t_invoicedetl CURSOR FOR 
	SELECT * FROM t_invoicedetl 
	WHERE order_num = pr_subhead.sub_num 

	FOREACH c_t_invoicedetl INTO pr_invoicedetl.*
	 
		LET pr_invoicedetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pr_invoicedetl.inv_num = pr_invoicehead.inv_num 
		LET pr_invoicedetl.cust_code = pr_invoicehead.cust_code 
	
		##################################################
		## Adjust product AND create prodledger FOR On demand product
		##################################################
		SELECT * INTO pr_subproduct.* 
		FROM subproduct 
		WHERE part_code = pr_invoicedetl.part_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND type_code = pr_subhead.sub_type_code 
		IF pr_subproduct.linetype_ind = "2" THEN 
			IF pr_invoicedetl.part_code IS NOT NULL	AND pr_invoicedetl.ship_qty != 0 THEN 
				OPEN c_prodstatus USING pr_invoicedetl.part_code,	pr_invoicedetl.ware_code 
				FETCH c_prodstatus INTO pr_prodstatus.* 
	
				IF pr_prodstatus.stocked_flag = "Y" THEN 
					LET pr_prodstatus.seq_num = pr_prodstatus.seq_num + 1 
					LET pr_invoicedetl.seq_num = pr_prodstatus.seq_num 
	
					IF pr_prodstatus.onhand_qty IS NULL THEN 
						LET pr_prodstatus.onhand_qty = 0 
					END IF 
	
					LET pr_prodstatus.onhand_qty = pr_prodstatus.onhand_qty	- pr_invoicedetl.ship_qty 
		
					INITIALIZE pr_prodledg.* TO NULL 
		
					LET pr_prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET pr_prodledg.part_code = pr_invoicedetl.part_code 
					LET pr_prodledg.ware_code = pr_invoicedetl.ware_code 
					LET pr_prodledg.tran_date = pr_invoicehead.inv_date 
					LET pr_prodledg.seq_num = pr_invoicedetl.seq_num 
					LET pr_prodledg.trantype_ind = "S" 
					LET pr_prodledg.year_num = pr_invoicehead.year_num 
					LET pr_prodledg.period_num = pr_invoicehead.period_num 
					LET pr_prodledg.source_text = pr_invoicedetl.cust_code 
					LET pr_prodledg.source_num = pr_invoicedetl.inv_num 
					LET pr_prodledg.tran_qty =	0 - pr_invoicedetl.ship_qty + 0 
					LET pr_prodledg.bal_amt = pr_prodstatus.onhand_qty 
					LET pr_prodledg.cost_amt = pr_invoicedetl.unit_cost_amt	/ pr_invoicehead.conv_qty 
					LET pr_prodledg.sales_amt=pr_invoicedetl.unit_sale_amt / pr_invoicehead.conv_qty 
					LET pr_prodledg.hist_flag = "N" 
					LET pr_prodledg.post_flag = "N" 
					LET pr_prodledg.entry_code = glob_rec_kandoouser.sign_on_code 
					LET pr_prodledg.entry_date = today 
	
					PUT c_prodledg 
					END IF 
					UPDATE prodstatus 
	
					SET 
						onhand_qty = pr_prodstatus.onhand_qty, 
						reserved_qty = pr_prodstatus.reserved_qty, 
						last_sale_date = pr_invoicehead.inv_date, 
						seq_num = pr_prodstatus.seq_num 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = pr_invoicedetl.part_code 
					AND ware_code = pr_invoicedetl.ware_code 
					CLOSE c_prodstatus 
	
				END IF 
	
			END IF 
	
			LET pr_invoicedetl.line_acct_code = account_patch(
				glob_rec_kandoouser.cmpy_code,
				pr_invoicedetl.line_acct_code, 
				pr_invoicehead.acct_override_code) 
				PUT c1_invoicedetl 
	
			OPEN c2_subcustomer 
				USING pr_subhead.cust_code, 
				pr_subhead.ship_code, 
				pr_subhead.sub_type_code, 
				pr_invoicedetl.part_code, 
				pr_subhead.start_date, 
				pr_subhead.end_date 
	
			FETCH c2_subcustomer INTO pr_subcustomer.* 
		
			IF status = 0 THEN 
				LET pr_subcustomer.next_seq_num=pr_subcustomer.next_seq_num +1 
			
				UPDATE subcustomer 
				SET 
					inv_qty = inv_qty + pr_invoicedetl.ship_qty, 
					next_seq_num = pr_subcustomer.next_seq_num 
				WHERE cmpy_code = pr_invoicedetl.cmpy_code 
				AND cust_code = pr_subhead.cust_code 
				AND ship_code = pr_subhead.ship_code 
				AND sub_type_code = pr_subhead.sub_type_code 
				AND part_code = pr_invoicedetl.part_code 
				AND comm_date= pr_subhead.start_date 
				AND end_date= pr_subhead.end_date 
			END IF 
		
			CLOSE c2_subcustomer 
			LET pr_subaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET pr_subaudit.part_code = pr_invoicedetl.part_code 
			LET pr_subaudit.cust_code = pr_subhead.cust_code 
			LET pr_subaudit.ship_code = pr_subhead.ship_code 
			LET pr_subaudit.start_date = pr_subhead.start_date 
			LET pr_subaudit.end_date = pr_subhead.end_date 
			LET pr_subaudit.seq_num = pr_subcustomer.next_seq_num 
			LET pr_subaudit.tran_date = pr_invoicehead.inv_date 
			LET pr_subaudit.entry_date = today 
			LET pr_subaudit.entry_code = glob_rec_kandoouser.sign_on_code 
			LET pr_subaudit.tran_qty = pr_invoicedetl.ship_qty 
			LET pr_subaudit.unit_amt = pr_invoicedetl.unit_sale_amt 
			LET pr_subaudit.unit_tax_amt = pr_invoicedetl.unit_tax_amt 
			LET pr_subaudit.currency_code = pr_invoicehead.currency_code 
			LET pr_subaudit.conv_qty = pr_invoicehead.conv_qty 
			LET pr_subaudit.tran_type_ind = "INV" 
			LET pr_subaudit.sub_num = pr_subhead.sub_num 
			LET pr_subaudit.source_num = pr_invoicehead.inv_num 
			LET pr_subaudit.sub_type_code = pr_subhead.sub_type_code 
			LET pr_subaudit.comm_text = "Invoice Entry (sub)" 
		
			INSERT INTO subaudit VALUES (pr_subaudit.*) 
		
			END FOREACH 
		
			LET pr_invoicehead.cost_ind = pr_arparms.costings_ind 
			LET pr_invoicehead.total_amt = pr_invoicehead.tax_amt 
			+ pr_invoicehead.goods_amt 
			+ pr_invoicehead.freight_amt 
			+ pr_invoicehead.freight_tax_amt 
			+ pr_invoicehead.hand_amt 
			+ pr_invoicehead.hand_tax_amt 
	
	
			#INSERT invoicehead Record
			IF db_invoicehead_rec_validation(UI_ON,MODE_INSERT,pr_invoicehead.*) THEN
				INSERT INTO invoicehead VALUES (pr_invoicehead.*)			
			ELSE
				DISPLAY pr_invoicehead.*
				CALL fgl_winmessage("Error","Could not insert new invoicehead record","ERROR")
			END IF 
			 
			UPDATE subhead SET last_inv_num = pr_invoicehead.inv_num 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND sub_num = pr_subhead.sub_num 
			OUTPUT TO REPORT KS2_rpt_list_invoice(pr_invoicehead.*) 
		
			################################################
			## Now TO UPDATE customer
			################################################
			LET pr_customer.next_seq_num = pr_customer.next_seq_num + 1 
			LET pr_customer.bal_amt = pr_customer.bal_amt + pr_invoicehead.total_amt 
			LET err_message = "K21 - Unable TO add TO AR log table " 
		
			INITIALIZE pr_araudit.* TO NULL 
		
			LET pr_araudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET pr_araudit.tran_date = pr_invoicehead.inv_date 
			LET pr_araudit.cust_code = pr_invoicehead.cust_code 
			LET pr_araudit.seq_num = pr_customer.next_seq_num 
			LET pr_araudit.tran_type_ind = TRAN_TYPE_INVOICE_IN 
			LET pr_araudit.source_num = pr_invoicehead.inv_num 
			LET pr_araudit.tran_text = "Enter invoice" 
			LET pr_araudit.tran_amt = pr_invoicehead.total_amt 
			LET pr_araudit.entry_code = glob_rec_kandoouser.sign_on_code 
			LET pr_araudit.sales_code = pr_invoicehead.sale_code 
			LET pr_araudit.year_num = pr_invoicehead.year_num 
			LET pr_araudit.period_num = pr_invoicehead.period_num 
			LET pr_araudit.bal_amt = pr_customer.bal_amt 
			LET pr_araudit.currency_code = pr_customer.currency_code 
			LET pr_araudit.conv_qty = pr_invoicehead.conv_qty 
			LET pr_araudit.entry_date = today 
	
			INSERT INTO araudit VALUES (pr_araudit.*) 
			
			LET pr_customer.curr_amt = pr_customer.curr_amt + pr_invoicehead.total_amt 
	
			IF pr_customer.bal_amt > pr_customer.highest_bal_amt THEN 
				LET pr_customer.highest_bal_amt = pr_customer.bal_amt 
			END IF
			 
			LET pr_customer.cred_bal_amt = pr_customer.cred_limit_amt - pr_customer.bal_amt 
	
			IF year(pr_invoicehead.inv_date) > year(pr_customer.last_inv_date) THEN 
				LET pr_customer.ytds_amt = 0 
				LET pr_customer.mtds_amt = 0 
			END IF 
			
			LET pr_customer.ytds_amt = pr_customer.ytds_amt	+ pr_invoicehead.total_amt 
	
			IF month(pr_invoicehead.inv_date)>month(pr_customer.last_inv_date) THEN 
				LET pr_customer.mtds_amt = 0 
			END IF
			 
			LET pr_customer.mtds_amt = pr_customer.mtds_amt	+ pr_invoicehead.total_amt 
			LET pr_customer.last_inv_date = pr_invoicehead.inv_date 
			LET err_message = "K21 - Customer actual UPDATE "
			 
			UPDATE customer	 
			SET 
				next_seq_num = pr_customer.next_seq_num, 
				bal_amt = pr_customer.bal_amt, 
				curr_amt = pr_customer.curr_amt, 
				highest_bal_amt = pr_customer.highest_bal_amt, 
				cred_bal_amt = pr_customer.cred_bal_amt, 
				last_inv_date = pr_customer.last_inv_date, 
				ytds_amt = pr_customer.ytds_amt, 
				mtds_amt = pr_customer.mtds_amt 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = pr_customer.cust_code
			 
			CLOSE c_customer 
			CLOSE c1_invoicedetl 
			CLOSE c_prodledg 
			CLOSE c_subaudit 
		
		END IF 
	
		CLOSE c_subhead 
	END FOREACH
	 
	COMMIT WORK 
END FUNCTION
###########################################################################
# END FUNCTION write_sub(p_mode)  
########################################################################### 