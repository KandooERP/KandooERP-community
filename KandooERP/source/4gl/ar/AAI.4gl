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
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/AA_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/AAI_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
--DEFINE modu_cmd CHAR(3) 
DEFINE modu_itis DATE 
--DEFINE modu_print_sel CHAR(1) 

#####################################################################
# FUNCTION AAI_main()
#
# Corporate Debtors Customer Listing
#####################################################################
FUNCTION AAI_main()
	CALL setModuleId("AAI")

	IF NOT fgl_find_table("cdlisting") THEN	
		CREATE temp TABLE cdlisting (cust_code CHAR(8), 
		name_text CHAR(30), 
		addr1_text CHAR(30), 
		addr2_text CHAR(30), 
		city_text CHAR(20), 
		state_code CHAR(20), 
		post_code CHAR(10), 
		country_code CHAR(3), 
		country_text CHAR(20), 
		currency_code CHAR(3), 
		type_code CHAR(3), 
		sale_code CHAR(8), 
		term_code CHAR(3), 
		tax_code CHAR(3), 
		inv_level_ind CHAR(1), 
		cred_limit_amt DECIMAL(16,2), 
		fax_text CHAR(20), 
		tele_text CHAR(20), 
		mobile_phone CHAR(20),
		email CHAR(20),
		contact_text CHAR(30), 
		inv_addr_flag CHAR(1), 
		sales_anly_flag CHAR(1), 
		credit_chk_flag CHAR(1), 
		corp_cust_code CHAR(8), 
		corp_name_text CHAR(30), 
		corp_addr1_text CHAR(30), 
		corp_addr2_text CHAR(30), 
		corp_city_text CHAR(20), 
		corp_tele_text CHAR(20)) with no LOG 
	END IF
	
	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 
			OPEN WINDOW A218 with FORM "A218" 
			CALL windecoration_a("A218")
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
		
			MENU " Corporate Debtors Listing" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","AAI","menu-corporate-debtors-listing") 
					CALL rpt_rmsreps_reset(NULL)
					CALL AAI_rpt_process(AAI_rpt_query())
					 
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 		
		
				ON ACTION "Report" 	#COMMAND "Run" " Enter selection criteria AND generate REPORT"
					CALL rpt_rmsreps_reset(NULL)
					IF fgl_find_table("cdlisting") THEN
						DELETE FROM cdlisting WHERE "1=1"
					END IF
					CALL AAI_rpt_process(AAI_rpt_query()) 
		
				ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "CANCEL" #COMMAND KEY(interrupt,"E")"Exit" " RETURN TO menus"
					EXIT MENU 
			END MENU 
		
			CLOSE WINDOW A218 

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL AAI_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A218 with FORM "A218" 
			CALL windecoration_a("A218") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(AAI_rpt_query()) #save where clause in env 
			CLOSE WINDOW A218 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL AAI_rpt_process(get_url_sel_text())
	END CASE			

	IF fgl_find_table("tcdlisting") THEN
		DROP TABLE cdlisting
	END IF
		
END FUNCTION
#####################################################################
# END FUNCTION AAI_main()
#####################################################################

#####################################################################
# FUNCTION AAI_rpt_query()
#
#
#####################################################################
FUNCTION AAI_rpt_query() 
	DEFINE l_where_text STRING 
	DEFINE l_exist SMALLINT
	DEFINE l_chk_cust_code LIKE customer.cust_code
	DEFINE l_rec_rp_customer RECORD 
		cust_code LIKE customer.cust_code, 
		name_text LIKE customer.name_text, 
		addr1_text LIKE customer.addr1_text, 
		addr2_text LIKE customer.addr2_text, 
		city_text LIKE customer.city_text, 
		state_code LIKE customer.state_code, 
		post_code LIKE customer.post_code, 
		country_code LIKE customer.country_code, 
--@db-patch_2020_10_04--		country_text LIKE customer.country_text, 
		currency_code LIKE customer.currency_code, 
		type_code LIKE customer.type_code, 
		sale_code LIKE customer.sale_code, 
		term_code LIKE customer.term_code, 
		tax_code LIKE customer.tax_code, 
		inv_level_ind LIKE customer.inv_level_ind, 
		cred_limit_amt LIKE customer.cred_limit_amt, 
		fax_text LIKE customer.fax_text, 
		tele_text LIKE customer.tele_text, 
		mobile_phone LIKE customer.mobile_phone,
		email LIKE customer.email,
		contact_text LIKE customer.contact_text, 
		inv_addr_flag LIKE customer.inv_addr_flag, 
		sales_anly_flag LIKE customer.sales_anly_flag, 
		credit_chk_flag LIKE customer.credit_chk_flag, 
		corp_cust_code LIKE customer.corp_cust_code, 
		corp_name_text LIKE customer.name_text, 
		corp_addr1_text LIKE customer.addr1_text, 
		corp_addr2_text LIKE customer.addr2_text, 
		corp_city_text LIKE customer.city_text, 
		corp_tele_text LIKE customer.tele_text 
	END RECORD
	DEFINE l_rec_customer RECORD 
		cust_code LIKE customer.cust_code, 
		name_text LIKE customer.name_text, 
		addr1_text LIKE customer.addr1_text, 
		addr2_text LIKE customer.addr2_text, 
		city_text LIKE customer.city_text, 
		state_code LIKE customer.state_code, 
		post_code LIKE customer.post_code, 
		country_code LIKE customer.country_code, 
--@db-patch_2020_10_04--		country_text LIKE customer.country_text, 
		currency_code LIKE customer.currency_code, 
		type_code LIKE customer.type_code, 
		sale_code LIKE customer.sale_code, 
		term_code LIKE customer.term_code, 
		tax_code LIKE customer.tax_code, 
		inv_level_ind LIKE customer.inv_level_ind, 
		cred_limit_amt LIKE customer.cred_limit_amt, 
		fax_text LIKE customer.fax_text, 
		tele_text LIKE customer.tele_text, 
		mobile_phone LIKE customer.mobile_phone,
		email LIKE customer.email,				
		contact_text LIKE customer.contact_text, 
		inv_addr_flag LIKE customer.inv_addr_flag, 
		sales_anly_flag LIKE customer.sales_anly_flag, 
		credit_chk_flag LIKE customer.credit_chk_flag, 
		corp_cust_code LIKE customer.corp_cust_code, 
		corp_name_text LIKE customer.name_text, 
		corp_addr1_text LIKE customer.addr1_text, 
		corp_addr2_text LIKE customer.addr2_text, 
		corp_city_text LIKE customer.city_text, 
		corp_tele_text LIKE customer.tele_text 
	END RECORD
	DEFINE l_rec_v_customer RECORD 
		cust_code LIKE customer.cust_code, 
		name_text LIKE customer.name_text, 
		addr1_text LIKE customer.addr1_text, 
		addr2_text LIKE customer.addr2_text, 
		city_text LIKE customer.city_text, 
		state_code LIKE customer.state_code, 
		post_code LIKE customer.post_code, 
		country_code LIKE customer.country_code, 
--@db-patch_2020_10_04--		country_text LIKE customer.country_text, 
		currency_code LIKE customer.currency_code, 
		type_code LIKE customer.type_code, 
		sale_code LIKE customer.sale_code, 
		term_code LIKE customer.term_code, 
		tax_code LIKE customer.tax_code, 
		inv_level_ind LIKE customer.inv_level_ind, 
		cred_limit_amt LIKE customer.cred_limit_amt, 
		fax_text LIKE customer.fax_text, 
		tele_text LIKE customer.tele_text, 
		mobile_phone LIKE customer.mobile_phone,
		email LIKE customer.email,				
		contact_text LIKE customer.contact_text, 
		inv_addr_flag LIKE customer.inv_addr_flag, 
		sales_anly_flag LIKE customer.sales_anly_flag, 
		credit_chk_flag LIKE customer.credit_chk_flag, 
		corp_cust_code LIKE customer.corp_cust_code, 
		corp_name_text LIKE customer.name_text, 
		corp_addr1_text LIKE customer.addr1_text, 
		corp_addr2_text LIKE customer.addr2_text, 
		corp_city_text LIKE customer.city_text, 
		corp_tele_text LIKE customer.tele_text 
	END RECORD 

	DELETE FROM cdlisting 
	WHERE 1=1 

	INITIALIZE l_rec_customer.* TO NULL 
	INITIALIZE l_rec_rp_customer.* TO NULL 
	INITIALIZE l_rec_v_customer.* TO NULL 

	MESSAGE kandoomsg2("U",1020,"Report Type") 
	#1001 Enter Report Type;  OK TO Continue.
	INPUT glob_rec_rpt_selector.sel_option1 FROM print_sel  

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","AA1","inp-print_sel") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL 
	END IF 
	MESSAGE kandoomsg2("U",1001,"") #1001 Enter Selection Criteria;  OK TO Continue.
	CONSTRUCT BY NAME l_where_text ON cust_code, 
	name_text, 
	addr1_text, 
	addr2_text, 
	city_text, 
	state_code, 
	post_code, 
	country_code, 
	country_text, 
	currency_code, 
	type_code, 
	sale_code, 
	term_code, 
	tax_code, 
	inv_level_ind, 
	cred_limit_amt, 
	fax_text, 
	tele_text, 
	mobile_phone,
	email,		
	contact_text, 
	inv_addr_flag, 
	sales_anly_flag, 
	credit_chk_flag 


		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","AAI","construct-customer") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false
		RETURN NULL
	ELSE
		RETURN l_where_text 
	END IF

END FUNCTION
#####################################################################
# END FUNCTION AAI_rpt_query()
#####################################################################


#####################################################################
# FUNCTION AAI_rpt_process(p_where_text) 
#
#
#####################################################################
FUNCTION AAI_rpt_process(p_where_text) 
	DEFINE p_where_text STRING
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE l_query_text STRING
	DEFINE l_exist SMALLINT
	DEFINE l_chk_cust_code LIKE customer.cust_code
	DEFINE l_rec_rp_customer RECORD 
		cust_code LIKE customer.cust_code, 
		name_text LIKE customer.name_text, 
		addr1_text LIKE customer.addr1_text, 
		addr2_text LIKE customer.addr2_text, 
		city_text LIKE customer.city_text, 
		state_code LIKE customer.state_code, 
		post_code LIKE customer.post_code, 
		country_code LIKE customer.country_code, 
--@db-patch_2020_10_04--		country_text LIKE customer.country_text, 
		currency_code LIKE customer.currency_code, 
		type_code LIKE customer.type_code, 
		sale_code LIKE customer.sale_code, 
		term_code LIKE customer.term_code, 
		tax_code LIKE customer.tax_code, 
		inv_level_ind LIKE customer.inv_level_ind, 
		cred_limit_amt LIKE customer.cred_limit_amt, 
		fax_text LIKE customer.fax_text, 
		tele_text LIKE customer.tele_text, 
		mobile_phone LIKE customer.mobile_phone,
		email LIKE customer.email,				
		contact_text LIKE customer.contact_text, 
		inv_addr_flag LIKE customer.inv_addr_flag, 
		sales_anly_flag LIKE customer.sales_anly_flag, 
		credit_chk_flag LIKE customer.credit_chk_flag, 
		corp_cust_code LIKE customer.corp_cust_code, 
		corp_name_text LIKE customer.name_text, 
		corp_addr1_text LIKE customer.addr1_text, 
		corp_addr2_text LIKE customer.addr2_text, 
		corp_city_text LIKE customer.city_text, 
		corp_tele_text LIKE customer.tele_text 
	END RECORD
	DEFINE l_rec_customer RECORD 
		cust_code LIKE customer.cust_code, 
		name_text LIKE customer.name_text, 
		addr1_text LIKE customer.addr1_text, 
		addr2_text LIKE customer.addr2_text, 
		city_text LIKE customer.city_text, 
		state_code LIKE customer.state_code, 
		post_code LIKE customer.post_code, 
		country_code LIKE customer.country_code, 
--@db-patch_2020_10_04--		country_text LIKE customer.country_text, 
		currency_code LIKE customer.currency_code, 
		type_code LIKE customer.type_code, 
		sale_code LIKE customer.sale_code, 
		term_code LIKE customer.term_code, 
		tax_code LIKE customer.tax_code, 
		inv_level_ind LIKE customer.inv_level_ind, 
		cred_limit_amt LIKE customer.cred_limit_amt, 
		tele_text LIKE customer.tele_text, 
		mobile_phone LIKE customer.mobile_phone,
		fax_text LIKE customer.fax_text,
		email LIKE customer.email,				
		contact_text LIKE customer.contact_text, 
		inv_addr_flag LIKE customer.inv_addr_flag, 
		sales_anly_flag LIKE customer.sales_anly_flag, 
		credit_chk_flag LIKE customer.credit_chk_flag, 
		corp_cust_code LIKE customer.corp_cust_code, 
		corp_name_text LIKE customer.name_text, 
		corp_addr1_text LIKE customer.addr1_text, 
		corp_addr2_text LIKE customer.addr2_text, 
		corp_city_text LIKE customer.city_text, 
		corp_tele_text LIKE customer.tele_text 
	END RECORD
	DEFINE l_rec_v_customer RECORD 
		cust_code LIKE customer.cust_code, 
		name_text LIKE customer.name_text, 
		addr1_text LIKE customer.addr1_text, 
		addr2_text LIKE customer.addr2_text, 
		city_text LIKE customer.city_text, 
		state_code LIKE customer.state_code, 
		post_code LIKE customer.post_code, 
		country_code LIKE customer.country_code, 
--@db-patch_2020_10_04--		country_text LIKE customer.country_text, 
		currency_code LIKE customer.currency_code, 
		type_code LIKE customer.type_code, 
		sale_code LIKE customer.sale_code, 
		term_code LIKE customer.term_code, 
		tax_code LIKE customer.tax_code, 
		inv_level_ind LIKE customer.inv_level_ind, 
		cred_limit_amt LIKE customer.cred_limit_amt, 
		fax_text LIKE customer.fax_text, 
		tele_text LIKE customer.tele_text, 
		mobile_phone LIKE customer.mobile_phone,
		email LIKE customer.email,				
		contact_text LIKE customer.contact_text, 
		inv_addr_flag LIKE customer.inv_addr_flag, 
		sales_anly_flag LIKE customer.sales_anly_flag, 
		credit_chk_flag LIKE customer.credit_chk_flag, 
		corp_cust_code LIKE customer.corp_cust_code, 
		corp_name_text LIKE customer.name_text, 
		corp_addr1_text LIKE customer.addr1_text, 
		corp_addr2_text LIKE customer.addr2_text, 
		corp_city_text LIKE customer.city_text, 
		corp_tele_text LIKE customer.tele_text 
	END RECORD 

	DELETE FROM cdlisting 
	WHERE 1=1 

	INITIALIZE l_rec_customer.* TO NULL 
	INITIALIZE l_rec_rp_customer.* TO NULL 
	INITIALIZE l_rec_v_customer.* TO NULL 

	 
	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF
	
	LET l_rpt_idx = rpt_start(getmoduleid(),"AAI_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT AAI_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	#ORDER BY Customer Code
	IF glob_rec_arparms.report_ord_flag = "C" THEN 

		# Selection FOR corporate AND originating
		CASE glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AAI_rpt_list")].sel_option1 
			WHEN "1" 
				LET l_query_text = "SELECT cust_code, name_text, addr1_text, ", 
				" addr2_text, city_text, state_code, ", 
				" post_code, country_code, country_text, ", 
				" currency_code, type_code, sale_code, ", 
				" term_code, tax_code, inv_level_ind, ", 
				" cred_limit_amt, fax_text, tele_text, mobile_phone, email, ", 
				" contact_text, inv_addr_flag, sales_anly_flag, ", 
				" credit_chk_flag, corp_cust_code ", 
				"FROM customer WHERE ", 
				glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AAI_rpt_list")].sel_text clipped, 
				" AND cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
				" ORDER BY corp_cust_code, cust_code, name_text " 

			WHEN "2" 
				LET l_query_text = "SELECT cust_code, name_text, addr1_text, ", 
				" addr2_text, city_text, state_code, ", 
				" post_code, country_code, country_text, ", 
				" currency_code, type_code, sale_code, ", 
				" term_code, tax_code, inv_level_ind, ", 
				" cred_limit_amt, fax_text, tele_text, mobile_phone, email, ", 
				" contact_text, inv_addr_flag, sales_anly_flag, ", 
				" credit_chk_flag, corp_cust_code ", 
				"FROM customer WHERE ", 
				glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AAI_rpt_list")].sel_text CLIPPED,
				" AND cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
				" AND corp_cust_code IS NULL ", 
				" ORDER BY corp_cust_code, cust_code, name_text " 

			WHEN "3" 
				LET l_query_text = "SELECT cust_code, name_text, addr1_text, ", 
				" addr2_text, city_text, state_code, ", 
				" post_code, country_code, country_text, ", 
				" currency_code, type_code, sale_code, ", 
				" term_code, tax_code, inv_level_ind, ", 
				" cred_limit_amt, fax_text, tele_text, mobile_phone, email, ", 
				" contact_text, inv_addr_flag, sales_anly_flag, ", 
				" credit_chk_flag, corp_cust_code ", 
				"FROM customer WHERE ", 
				glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AAI_rpt_list")].sel_text CLIPPED, 
				" AND cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
				" AND corp_cust_code IS NOT NULL ", 
				" ORDER BY corp_cust_code, cust_code, name_text " 

		END CASE 

	ELSE 
		CASE glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AAI_rpt_list")].sel_option1 
			WHEN "1" 
				LET l_query_text = "SELECT cust_code, name_text, addr1_text, ", 
				" addr2_text, city_text, state_code, ", 
				" post_code, country_code, country_text, ", 
				" currency_code, type_code, sale_code, ", 
				" term_code, tax_code, inv_level_ind, ", 
				" cred_limit_amt, fax_text, tele_text, mobile_phone, email, ", 
				" contact_text, inv_addr_flag, sales_anly_flag, ", 
				" credit_chk_flag, corp_cust_code ", 
				"FROM customer WHERE ", 
				glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AAI_rpt_list")].sel_text CLIPPED, 
				" AND cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
				" ORDER BY corp_cust_code, name_text, cust_code" 

			WHEN "2" 
				LET l_query_text = "SELECT cust_code, name_text, addr1_text, ", 
				" addr2_text, city_text, state_code, ", 
				" post_code, country_code, country_text, ", 
				" currency_code, type_code, sale_code, ", 
				" term_code, tax_code, inv_level_ind, ", 
				" cred_limit_amt, fax_text, tele_text, mobile_phone, email, ", 
				" contact_text, inv_addr_flag, sales_anly_flag, ", 
				" credit_chk_flag, corp_cust_code ", 
				"FROM customer WHERE ", 
				glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AAI_rpt_list")].sel_text CLIPPED, 
				" AND cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
				" AND corp_cust_code IS NULL ", 
				" ORDER BY corp_cust_code, name_text, cust_code" 


			WHEN "3" 
				LET l_query_text = "SELECT cust_code, name_text, addr1_text, ", 
				" addr2_text, city_text, state_code, ", 
				" post_code, country_code, country_text, ", 
				" currency_code, type_code, sale_code, ", 
				" term_code, tax_code, inv_level_ind, ", 
				" cred_limit_amt, fax_text, tele_text, mobile_phone, email, ", 
				" contact_text, inv_addr_flag, sales_anly_flag, ", 
				" credit_chk_flag, corp_cust_code ", 
				"FROM customer WHERE ", 
				glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AAI_rpt_list")].sel_text CLIPPED, 
				" AND cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
				" AND corp_cust_code IS NOT NULL ", 
				" ORDER BY corp_cust_code, name_text, cust_code" 
		END CASE 

	END IF 

	# Get inital selection records AND
	# OUTPUT TO a temporary file (cdlisting)

	PREPARE choice FROM l_query_text 
	DECLARE selcurs CURSOR FOR choice 

	CASE glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AAI_rpt_list")].sel_option1 
		WHEN "1" # both corporate AND originating 
			FOREACH selcurs 
				INTO l_rec_customer.* 

				# SELECT corporate debtor FOR originating
				IF l_rec_customer.corp_cust_code IS NOT NULL THEN 
					SELECT cust_code, 
					name_text, 
					addr1_text, 
					addr2_text, 
					city_text, 
					state_code, 
					post_code, 
					country_code, 
					country_text, 
					currency_code, 
					type_code, 
					sale_code, 
					term_code, 
					tax_code, 
					inv_level_ind, 
					cred_limit_amt, 
					fax_text, 
					tele_text,
					mobile_phone, #check out.. was added
					email,  #check out.. was added
					contact_text, 
					inv_addr_flag, 
					sales_anly_flag, 
					credit_chk_flag, 
					corp_cust_code, 
					name_text, 
					addr1_text, 
					addr2_text, 
					city_text, 
					tele_text 
					INTO l_rec_v_customer.* 
					FROM customer 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cust_code = l_rec_customer.corp_cust_code 

					# Check that RECORD does NOT already l_exist
					SELECT cust_code 
					INTO l_chk_cust_code 
					FROM cdlisting 
					WHERE cust_code = l_rec_v_customer.cust_code 

					IF status = NOTFOUND THEN 
						LET l_rec_v_customer.corp_cust_code = l_rec_v_customer.cust_code 
						LET l_rec_v_customer.corp_name_text = l_rec_v_customer.name_text 
						LET l_rec_v_customer.corp_addr1_text = l_rec_v_customer.addr1_text 
						LET l_rec_v_customer.corp_addr2_text = l_rec_v_customer.addr2_text 
						LET l_rec_v_customer.corp_city_text = l_rec_v_customer.city_text 
						LET l_rec_v_customer.corp_tele_text = l_rec_v_customer.tele_text
						#Possible extension 
						#LET l_rec_v_customer.corp_mobile_phone = l_rec_v_customer.mobile_phone
						#LET l_rec_v_customer.corp_email = l_rec_v_customer.email

						INSERT INTO cdlisting VALUES (l_rec_v_customer.cust_code , 
						l_rec_v_customer.name_text , 
						l_rec_v_customer.addr1_text , 
						l_rec_v_customer.addr2_text , 
						l_rec_v_customer.city_text , 
						l_rec_v_customer.state_code , 
						l_rec_v_customer.post_code , 
						l_rec_v_customer.country_code , 
--@db-patch_2020_10_04--						l_rec_v_customer.country_text , 
						l_rec_v_customer.currency_code , 
						l_rec_v_customer.type_code , 
						l_rec_v_customer.sale_code , 
						l_rec_v_customer.term_code , 
						l_rec_v_customer.tax_code , 
						l_rec_v_customer.inv_level_ind , 
						l_rec_v_customer.cred_limit_amt , 
						l_rec_v_customer.fax_text , 
						l_rec_v_customer.tele_text , 
						l_rec_v_customer.mobile_phone ,
						l_rec_v_customer.email ,												
						l_rec_v_customer.contact_text , 
						l_rec_v_customer.inv_addr_flag , 
						l_rec_v_customer.sales_anly_flag , 
						l_rec_v_customer.credit_chk_flag , 
						l_rec_v_customer.corp_cust_code, 
						l_rec_v_customer.corp_name_text, 
						l_rec_v_customer.corp_addr1_text, 
						l_rec_v_customer.corp_addr2_text, 
						l_rec_v_customer.corp_city_text, 
						l_rec_v_customer.corp_tele_text ) 

					END IF 

					SELECT name_text, 
					addr1_text, 
					addr2_text, 
					city_text, 
					tele_text 
					INTO l_rec_customer.corp_name_text, 
					l_rec_customer.corp_addr1_text, 
					l_rec_customer.corp_addr2_text, 
					l_rec_customer.corp_city_text, 
					l_rec_customer.corp_tele_text 
					FROM customer 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cust_code = l_rec_customer.corp_cust_code 

				END IF 

				# SELECT all originating debtors FOR corporate
				IF l_rec_customer.corp_cust_code IS NULL THEN 

					DECLARE org_curs CURSOR FOR 

					SELECT cust_code, 
					name_text, 
					addr1_text, 
					addr2_text, 
					city_text, 
					state_code, 
					post_code, 
					country_code, 
					country_text, 
					currency_code, 
					type_code, 
					sale_code, 
					term_code, 
					tax_code, 
					inv_level_ind, 
					cred_limit_amt, 
					fax_text, 
					tele_text,
					mobile_phone, 
					email,
					contact_text, 
					inv_addr_flag, 
					sales_anly_flag, 
					credit_chk_flag, 
					corp_cust_code, 
					name_text, 
					addr1_text, 
					addr2_text, 
					city_text, 
					tele_text 
					INTO l_rec_v_customer.* 
					FROM customer 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND corp_cust_code = l_rec_customer.cust_code 

					FOREACH org_curs 
						LET l_rec_v_customer.corp_name_text = l_rec_customer.name_text 
						LET l_rec_v_customer.corp_addr1_text = l_rec_customer.addr1_text 
						LET l_rec_v_customer.corp_addr2_text = l_rec_customer.addr2_text 
						LET l_rec_v_customer.corp_city_text = l_rec_customer.city_text 
						LET l_rec_v_customer.tele_text = l_rec_customer.tele_text 
						#Were addded
						LET l_rec_v_customer.mobile_phone = l_rec_customer.mobile_phone #Were addded
						LET l_rec_v_customer.email = l_rec_customer.email	#Were addded						 					

						# Check that RECORD does NOT already l_exist
						SELECT cust_code 
						INTO l_chk_cust_code 
						FROM cdlisting 
						WHERE cust_code = l_rec_v_customer.cust_code 

						IF status = NOTFOUND THEN 
							INSERT INTO cdlisting VALUES (l_rec_v_customer.cust_code , 
							l_rec_v_customer.name_text , 
							l_rec_v_customer.addr1_text , 
							l_rec_v_customer.addr2_text , 
							l_rec_v_customer.city_text , 
							l_rec_v_customer.state_code , 
							l_rec_v_customer.post_code , 
							l_rec_v_customer.country_code , 
--@db-patch_2020_10_04--							l_rec_v_customer.country_text , 
							l_rec_v_customer.currency_code , 
							l_rec_v_customer.type_code , 
							l_rec_v_customer.sale_code , 
							l_rec_v_customer.term_code , 
							l_rec_v_customer.tax_code , 
							l_rec_v_customer.inv_level_ind , 
							l_rec_v_customer.cred_limit_amt , 
							l_rec_v_customer.fax_text , 
							l_rec_v_customer.tele_text , 
							l_rec_v_customer.mobile_phone ,
							l_rec_v_customer.email ,														
							l_rec_v_customer.contact_text , 
							l_rec_v_customer.inv_addr_flag , 
							l_rec_v_customer.sales_anly_flag , 
							l_rec_v_customer.credit_chk_flag , 
							l_rec_v_customer.corp_cust_code, 
							l_rec_v_customer.corp_name_text, 
							l_rec_v_customer.corp_addr1_text, 
							l_rec_v_customer.corp_addr2_text, 
							l_rec_v_customer.corp_city_text, 
							l_rec_v_customer.corp_tele_text ) 
						END IF 

					END FOREACH 

					LET l_rec_customer.corp_cust_code = l_rec_customer.cust_code 
					LET l_rec_customer.corp_name_text = l_rec_customer.name_text 
					LET l_rec_customer.corp_addr1_text = l_rec_customer.addr1_text 
					LET l_rec_customer.corp_addr2_text = l_rec_customer.addr2_text 
					LET l_rec_customer.corp_city_text = l_rec_customer.city_text 
					LET l_rec_customer.corp_tele_text = l_rec_customer.tele_text 
					#Possible extension
					#LET l_rec_customer.corp_mobile_phone = l_rec_customer.mobile_phone #Possible extension
					#LET l_rec_customer.corp_tele_email = l_rec_customer.email	#Possible extension				

				END IF 

				# Check that RECORD does NOT already l_exist
				SELECT cust_code 
				INTO l_chk_cust_code 
				FROM cdlisting 
				WHERE cust_code = l_rec_customer.cust_code 

				IF status = NOTFOUND THEN 
					INSERT INTO cdlisting 
					VALUES (l_rec_customer.*) 
				END IF 

			END FOREACH 


		WHEN "2" # corporate only 
			FOREACH selcurs 
				INTO l_rec_customer.* 

				DECLARE org_cur CURSOR FOR 

				SELECT cust_code, 
				name_text, 
				addr1_text, 
				addr2_text, 
				city_text, 
				state_code, 
				post_code, 
				country_code, 
				country_text, 
				currency_code, 
				type_code, 
				sale_code, 
				term_code, 
				tax_code, 
				inv_level_ind, 
				cred_limit_amt, 
				fax_text, 
				tele_text, 
				mobile_phone,
				email,
				contact_text, 
				inv_addr_flag, 
				sales_anly_flag, 
				credit_chk_flag, 
				corp_cust_code, 
				name_text, 
				addr1_text, 
				addr2_text, 
				city_text, 
				tele_text 
				INTO l_rec_v_customer.* 
				FROM customer 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND corp_cust_code = l_rec_customer.cust_code 

				FOREACH org_cur 
					LET l_rec_v_customer.corp_name_text = l_rec_customer.name_text 
					LET l_rec_v_customer.corp_addr1_text = l_rec_customer.addr1_text 
					LET l_rec_v_customer.corp_addr2_text = l_rec_customer.addr2_text 
					LET l_rec_v_customer.corp_city_text = l_rec_customer.city_text 
					LET l_rec_v_customer.tele_text = l_rec_customer.tele_text
					#Was added 
					LET l_rec_v_customer.mobile_phone = l_rec_customer.mobile_phone #Was added
					LET l_rec_v_customer.email = l_rec_customer.email	#Was added			 	
					# Check that RECORD does NOT alread l_exist
					SELECT cust_code 
					INTO l_chk_cust_code 
					FROM cdlisting 
					WHERE cust_code = l_rec_v_customer.cust_code 

					IF status = NOTFOUND THEN 

						INSERT INTO cdlisting VALUES (l_rec_v_customer.cust_code , 
						l_rec_v_customer.name_text , 
						l_rec_v_customer.addr1_text , 
						l_rec_v_customer.addr2_text , 
						l_rec_v_customer.city_text , 
						l_rec_v_customer.state_code , 
						l_rec_v_customer.post_code , 
						l_rec_v_customer.country_code , 
--@db-patch_2020_10_04--						l_rec_v_customer.country_text , 
						l_rec_v_customer.currency_code , 
						l_rec_v_customer.type_code , 
						l_rec_v_customer.sale_code , 
						l_rec_v_customer.term_code , 
						l_rec_v_customer.tax_code , 
						l_rec_v_customer.inv_level_ind , 
						l_rec_v_customer.cred_limit_amt , 
						l_rec_v_customer.fax_text , 
						l_rec_v_customer.tele_text , 
						l_rec_v_customer.mobile_phone ,
						l_rec_v_customer.email ,												
						l_rec_v_customer.contact_text , 
						l_rec_v_customer.inv_addr_flag , 
						l_rec_v_customer.sales_anly_flag , 
						l_rec_v_customer.credit_chk_flag , 
						l_rec_v_customer.corp_cust_code, 
						l_rec_v_customer.corp_name_text, 
						l_rec_v_customer.corp_addr1_text, 
						l_rec_v_customer.corp_addr2_text, 
						l_rec_v_customer.corp_city_text, 
						l_rec_v_customer.corp_tele_text ) 

					END IF 

				END FOREACH 

				LET l_rec_customer.corp_cust_code = l_rec_customer.cust_code 

				SELECT name_text, 
				addr1_text, 
				addr2_text, 
				city_text, 
				tele_text 
				#,
				#mobile_phone,
				#email
				INTO l_rec_customer.corp_name_text, 
				l_rec_customer.corp_addr1_text, 
				l_rec_customer.corp_addr2_text, 
				l_rec_customer.corp_city_text, 
				l_rec_customer.corp_tele_text
				#,
				#l_rec_customer.corp_mobile_phone, 
				#l_rec_customer.corp_email							 
				FROM customer 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = l_rec_customer.corp_cust_code 

				# Check that RECORD does NOT already l_exist
				SELECT cust_code 
				INTO l_chk_cust_code 
				FROM cdlisting 
				WHERE cust_code = l_rec_customer.cust_code 

				IF status = NOTFOUND THEN 
					INSERT INTO cdlisting 
					VALUES (l_rec_customer.*) 
				END IF 
			END FOREACH 

		WHEN "3" # originating only 
			FOREACH selcurs 
				INTO l_rec_customer.* 

				SELECT cust_code, 
				name_text, 
				addr1_text, 
				addr2_text, 
				city_text, 
				state_code, 
				post_code, 
				country_code, 
				country_text, 
				currency_code, 
				type_code, 
				sale_code, 
				term_code, 
				tax_code, 
				inv_level_ind, 
				cred_limit_amt, 
				fax_text, 
				tele_text, 
				mobile_phone, #added
				email,				#added	
				contact_text, 
				inv_addr_flag, 
				sales_anly_flag, 
				credit_chk_flag, 
				corp_cust_code, 
				name_text, 
				addr1_text, 
				addr2_text, 
				city_text, 
				tele_text 
				#,
				# mobile_phone,
				# email
				INTO l_rec_v_customer.* 
				FROM customer 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = l_rec_customer.corp_cust_code 

				# Check that RECORD does NOT already l_exist
				SELECT cust_code 
				INTO l_chk_cust_code 
				FROM cdlisting 
				WHERE cust_code = l_rec_v_customer.cust_code 

				IF status = NOTFOUND THEN 
					LET l_rec_v_customer.corp_cust_code = l_rec_v_customer.cust_code 
					INSERT INTO cdlisting VALUES (l_rec_v_customer.cust_code , 
					l_rec_v_customer.name_text , 
					l_rec_v_customer.addr1_text , 
					l_rec_v_customer.addr2_text , 
					l_rec_v_customer.city_text , 
					l_rec_v_customer.state_code , 
					l_rec_v_customer.post_code , 
					l_rec_v_customer.country_code , 
--@db-patch_2020_10_04--					l_rec_v_customer.country_text , 
					l_rec_v_customer.currency_code , 
					l_rec_v_customer.type_code , 
					l_rec_v_customer.sale_code , 
					l_rec_v_customer.term_code , 
					l_rec_v_customer.tax_code , 
					l_rec_v_customer.inv_level_ind , 
					l_rec_v_customer.cred_limit_amt , 
					l_rec_v_customer.fax_text , 
					l_rec_v_customer.tele_text , 
					l_rec_v_customer.mobile_phone , #added
					l_rec_v_customer.email ,			  #added							
					l_rec_v_customer.contact_text , 
					l_rec_v_customer.inv_addr_flag , 
					l_rec_v_customer.sales_anly_flag , 
					l_rec_v_customer.credit_chk_flag , 
					l_rec_v_customer.corp_cust_code, 
					l_rec_v_customer.corp_name_text, 
					l_rec_v_customer.corp_addr1_text, 
					l_rec_v_customer.corp_addr2_text, 
					l_rec_v_customer.corp_city_text, 
					l_rec_v_customer.corp_tele_text ) 
				END IF 

				SELECT name_text, 
				addr1_text, 
				addr2_text, 
				city_text, 
				tele_text 
				#,
				#mobile_phone, #added
				#email,				#added					
				INTO l_rec_customer.corp_name_text, 
				l_rec_customer.corp_addr1_text, 
				l_rec_customer.corp_addr2_text, 
				l_rec_customer.corp_city_text, 
				l_rec_customer.corp_tele_text 
				#,
				#l_rec_customer.corp_mobile_phonet,
				#l_rec_customer.corp_email				
				FROM customer 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = l_rec_customer.corp_cust_code 

				# Check that RECORD does NOT already l_exist
				SELECT cust_code 
				INTO l_chk_cust_code 
				FROM cdlisting 
				WHERE cust_code = l_rec_customer.cust_code 

				IF status = NOTFOUND THEN 
					INSERT INTO cdlisting 
					VALUES (l_rec_customer.*) 
				END IF 
			END FOREACH 

	END CASE 


	IF glob_rec_arparms.report_ord_flag = "C" THEN 
		DECLARE list_cur CURSOR FOR 
		SELECT * 
		FROM cdlisting 
		ORDER BY corp_cust_code, cust_code 

		FOREACH list_cur INTO l_rec_rp_customer.*
			#------------------------------------------------------------
			OUTPUT TO REPORT AAI_rpt_list(l_rpt_idx,l_rec_rp_customer.*) 
			IF NOT rpt_int_flag_handler2("Customer:",l_rec_rp_customer.cust_code, l_rec_rp_customer.name_text,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#------------------------------------------------------------
		END FOREACH 
	ELSE 
		DECLARE list_curs CURSOR FOR 
		SELECT * 
		FROM cdlisting 
		ORDER BY corp_name_text, name_text 

		FOREACH list_curs INTO l_rec_rp_customer.* 
			#------------------------------------------------------------
			OUTPUT TO REPORT AAI_rpt_list(l_rpt_idx,l_rec_rp_customer.*) 
			IF NOT rpt_int_flag_handler2("Customer:",l_rec_rp_customer.cust_code, l_rec_rp_customer.name_text,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#------------------------------------------------------------
			 
		END FOREACH 
	END IF 

	#------------------------------------------------------------
	FINISH REPORT AAI_rpt_list
	CALL rpt_finish("AAI_rpt_list")
	#------------------------------------------------------------

	IF int_flag THEN
		RETURN FALSE
	ELSE
		RETURN TRUE
	END IF
END FUNCTION 
#####################################################################
# END FUNCTION AAI_rpt_process(p_where_text) 
#####################################################################


#####################################################################
# REPORT AAI_rpt_list(p_rec_customer)
#
#
#####################################################################
REPORT aai_rpt_list(p_rpt_idx,p_rec_customer) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_customer RECORD 
		cust_code LIKE customer.cust_code, 
		name_text LIKE customer.name_text, 
		addr1_text LIKE customer.addr1_text, 
		addr2_text LIKE customer.addr2_text, 
		city_text LIKE customer.city_text, 
		state_code LIKE customer.state_code, 
		post_code LIKE customer.post_code, 
		country_code LIKE customer.country_code, 
--@db-patch_2020_10_04--		country_text LIKE customer.country_text, 
		currency_code LIKE customer.currency_code, 
		type_code LIKE customer.type_code, 
		sale_code LIKE customer.sale_code, 
		term_code LIKE customer.term_code, 
		tax_code LIKE customer.tax_code, 
		inv_level_ind LIKE customer.inv_level_ind, 
		cred_limit_amt LIKE customer.cred_limit_amt, 
		fax_text LIKE customer.fax_text, 
		tele_text LIKE customer.tele_text, 
		mobile_phone LIKE customer.mobile_phone,
		email LIKE customer.email,				
		contact_text LIKE customer.contact_text, 
		inv_addr_flag LIKE customer.inv_addr_flag, 
		sales_anly_flag LIKE customer.sales_anly_flag, 
		credit_chk_flag LIKE customer.credit_chk_flag, 
		corp_cust_code LIKE customer.corp_cust_code, 
		corp_name_text LIKE customer.name_text, 
		corp_addr1_text LIKE customer.addr1_text, 
		corp_addr2_text LIKE customer.addr2_text, 
		corp_city_text LIKE customer.city_text, 
		corp_tele_text LIKE customer.tele_text 
		#,
		#corp_mobile_phone LIKE customer.mobile_phone
		#corp_email LIKE customer.email
	END RECORD
	DEFINE l_len INTEGER 
	DEFINE l_s INTEGER 

	OUTPUT 

	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 2, "Corporate", 
			COLUMN 15, "Orig.", 
			COLUMN 25, "Name", 
			COLUMN 57, "Address", 
			COLUMN 91, "Phone", 
			COLUMN 113,"IN SA CR" 

			PRINT COLUMN 3, "Debtor", 
			COLUMN 15, "Debtor" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		ON EVERY ROW 

			IF p_rec_customer.cust_code != p_rec_customer.corp_cust_code THEN 

				SKIP 1 line 

				PRINT COLUMN 13, p_rec_customer.cust_code, 
				COLUMN 25, p_rec_customer.name_text , 
				COLUMN 57, p_rec_customer.addr1_text, 
				COLUMN 91, p_rec_customer.tele_text , 
				#COLUMN 91, p_rec_customer.mobile_phone ,  #possible addition
				#COLUMN 91, p_rec_customer.email , #possible addition
				COLUMN 114, p_rec_customer.inv_addr_flag, 
				COLUMN 117, p_rec_customer.sales_anly_flag, 
				COLUMN 120, p_rec_customer.credit_chk_flag 

				PRINT COLUMN 57, p_rec_customer.addr2_text, 
				COLUMN 91, p_rec_customer.city_text 

			END IF 

		ON LAST ROW 

			SKIP 1 line 
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			
			PRINT COLUMN 1, "Print Selection = ", 
			COLUMN 20, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_option1 CLIPPED, 
			COLUMN 30, "1 = Both, 2 = Corporate Only, 3 = Originating Only." 

			SKIP 1 line 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = pageno


		BEFORE GROUP OF p_rec_customer.corp_cust_code 
			SKIP 1 line 

			IF p_rec_customer.cust_code = p_rec_customer.corp_cust_code THEN 

				PRINT COLUMN 2, p_rec_customer.cust_code, 
				COLUMN 25, p_rec_customer.name_text , 
				COLUMN 57, p_rec_customer.addr1_text, 
				COLUMN 91, p_rec_customer.tele_text 
				#COLUMN 91, p_rec_customer.mobile_phone #possible extension
				#COLUMN 91, p_rec_customer.email  #possible extension
				PRINT COLUMN 57, p_rec_customer.addr2_text, 
				COLUMN 91, p_rec_customer.city_text 

			ELSE 

				PRINT COLUMN 2, p_rec_customer.corp_cust_code, 
				COLUMN 25, p_rec_customer.corp_name_text , 
				COLUMN 57, p_rec_customer.corp_addr1_text, 
				COLUMN 91, p_rec_customer.corp_tele_text 
				#COLUMN 91, p_rec_customer.mobile_phone  #possible extension
				#COLUMN 91, p_rec_customer.email  #possible extension
				PRINT COLUMN 57, p_rec_customer.corp_addr2_text, 
				COLUMN 91, p_rec_customer.corp_city_text 

			END IF 

END REPORT
#####################################################################
# END REPORT AAI_rpt_list(p_rec_customer)
##################################################################### 