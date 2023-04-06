GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION lib_windecoration_i_whenever_sqlerror ()
    # this code instanciates the default sql errors handling for all the code lines below this function
    # it is a compiler preprocessor instruction. It is not necessary to execute that function
    WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
END FUNCTION

FUNCTION windecoration_i(pwinname) 
	DEFINE pwinname STRING 
	DEFINE errmsg STRING 

	CASE pwinname 
	# Prog: U11
	# User Parameters
		WHEN "I100" -- GROUP codes (List) 
		WHEN "I101" -- product information 
			CALL setTitleGroupBox("cntGbProductInformation","lb_productInformation") 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_category("cat_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_classCode("class_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

			CALL setTitleGroupBox("cntGbRelationships","lb_productInformation") 
			CALL comboList_productCode("alter_part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_productCode("super_part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_productCode("compn_part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

			CALL setTitleGroupBox("cntGbUnitsOfMeasureConversions","lb_unitsOfMeasureConversions") 
			CALL comboList_uomCode("pur_uom_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 
			CALL comboList_uomCode("stock_uom_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 
			CALL comboList_uomCode("sell_uom_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 

			CALL setTitleGroupBox("cntGbOther","lb_other") 

		WHEN "I102" -- units OF measure codes (List) 


		WHEN "I104" -- product scan (list) 

		WHEN "I105" -- purchasing info (Vendor credit??) 
			CALL comboList_vendorCode("vend_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_uomCode("pur_uom_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 
			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_warrantyDays("days_warr_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_TAB_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I105a" -- purchasing 
			CALL comboList_vendorCode("vend_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_warrantyDays("days_warr_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_TAB_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I106" -- similiar TO which product.? (List) 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I108" -- product notes (List) 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I109" -- product stocking status (List) 
			CALL comboList_uomCode("sell_uom_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 


		WHEN "I110" -- product history (List) 
			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I111" -- product history (again) 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_maingrp("maingrp_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_productGroup("prodgrp_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL combolist_year_from_period("year_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 
			CALL comboList_period("period_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 

		WHEN "I112" -- product ledger 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL combolist_prodadjtype_code_text("source_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT)

		WHEN "I114" -- product movement 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL combolist_prodadjtype_code_text("source_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT)
		WHEN "I116" -- product ledger - fifo cost 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I119" -- direct product receipt no flexcode
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL combolist_year_from_period("year_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 
			CALL comboList_period("period_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint)
			CALL combolist_prodadjtype_code_text("source_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT)

		WHEN "I119a" -- direct product receipt with flexcode
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL combolist_year_from_period("year_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 
			CALL comboList_period("period_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 

		WHEN "I120" -- product issue 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL combolist_year_from_period("year_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 
			CALL comboList_period("period_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 

		WHEN "I122" -- product cost adjustment 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL combolist_year_from_period("year_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 
			CALL comboList_period("period_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 
			CALL comboList_coa_account("acct_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) --pvariable,psort,psingle,phint) 
			CALL comboList_uomCode("stock_uom_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_uomCode("sell_uom_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL combolist_prodadjtype_code_text("source_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT)


		WHEN "I123" -- product cost adjustment 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL combolist_year_from_period("year_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 
			CALL comboList_period("period_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 
			CALL comboList_coa_account("acct_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) --pvariable,psort,psingle,phint) 
			CALL comboList_uomCode("stock_uom_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_uomCode("sell_uom_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL combolist_prodadjtype_code_text("source_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT)

		WHEN "I125" -- stock valuation 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I126" -- serialized products 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 


		WHEN "I127" -- serialized products 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_vendorCode("vend_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_customer("cust_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) 


		WHEN "I129" -- selected SERIAL no. 
			CALL comboList_productCode("d_part",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I130" -- available SERIAL no. (list) 

		WHEN "I131" -- inventory posting selection (List) 

		WHEN "I132" -- warehouse detail 
			CALL combolist_warehouse ("ware_code", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_country ("country_code", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_waregrp ("waregrp_code", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) --price type --psort,psingle,phint) 
			CALL combolist_cartarea ("cart_area_code", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) --price type --psort,psingle,phint) 
			CALL comboList_suburb_code_text("city_text", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 

		WHEN "I133" -- warehouse scan (List) 

		WHEN "I134" -- warehouse scan (List) 

		WHEN "I135" -- product category 
			--CALL comboList_category      ("cat_code",          COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT)
			CALL combolist_coa_account ("sale_acct_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) --pvariable,psort,psingle,phint) 
			CALL combolist_coa_account ("cogs_acct_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) --pvariable,psort,psingle,phint) 
			CALL combolist_coa_account ("stock_acct_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) --pvariable,psort,psingle,phint) 
			CALL combolist_coa_account ("adj_acct_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) --pvariable,psort,psingle,phint) 
			CALL combolist_coa_account ("int_rev_acct_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) --pvariable,psort,psingle,phint) 
			CALL combolist_coa_account ("int_cogs_acct_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) --pvariable,psort,psingle,phint) 


		WHEN "I136" -- product category information (list) 

		WHEN "I137" -- product category scan (list) 

		WHEN "I138" -- company price UPDATE 
			CALL combolist_warehouse ("pr_mast_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 

		WHEN "I139" -- product category 
			CALL combolist_category ("cat_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_costtype ("cost_list_ind",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			CALL combolist_pricetype ("price1_ind", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_pricetype ("price2_ind", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_pricetype ("price3_ind", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_pricetype ("price4_ind", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_pricetype ("price5_ind", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_pricetype ("price6_ind", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_pricetype ("price7_ind", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_pricetype ("price8_ind", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_pricetype ("price9_ind", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL comboList_defaultCostType("def_cost_ind", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_roundingrule ("rounding_ind", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 

		WHEN "I140" -- inventory classes (List) 

		WHEN "I141" -- inventory classes (List) 

		WHEN "I142" -- cost ledger inquiry (List) 
			CALL combolist_productcode ("part_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_warehouse ("ware_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 

		WHEN "I143" -- product selection 
			CALL combolist_warehouse ("ware_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_productcode ("part_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_maingrp ("maingrp_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_productgroup ("prodgrp_code", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_category ("cat_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_classcode ("class_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_productcode ("alter_part_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_productcode ("super_part_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_productcode ("compn_part_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_uomcode ("pur_uom_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_uomcode ("stock_uom_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_uomcode ("sell_uom_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 

		WHEN "I145" -- izp - inventory parameters 
			CALL combolist_warehouse ("mast_ware_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_warehouse ("ibt_ware_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_cogs ("cost_ind", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) --pvariable,psort,psingle,phint) 
			CALL combolist_journalcode ("inv_journal_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) --pvariable,psort,psingle,phint) 

			#CALL comboList_price_type("type_ind",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT)	--price type  --pSort,pSingle,pHint)
			#CALL comboList_maingrp("maingrp_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT)
			#CALL comboList_glrepsubgrp("maingrp_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT)
			#CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT)
			#CALL comboList_productGroup("prodgrp_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT)
			#CALL comboList_classCode("class_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT)
			#CALL comboList_uomCode("uom_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT)
			#CALL comboList_priceLevel2("list_level_ind",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) --pVariable,pSort,pSingle,pHint)


		WHEN "I146" -- product (list) 
			CALL combolist_productcode ("part_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 

		WHEN "I147" -- inventory setup routine 
			CALL combolist_warehouse ("ware_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_productcode ("start_part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I148" -- opening balance setup 
			CALL combolist_warehouse ("ware_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_productcode ("part_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 

		WHEN "I150" -- product information 
			CALL combolist_productcode   ("part_code", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT)
			CALL combolist_productgroup ("prodgrp_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_category ("cat_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_classcode ("class_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 

			CALL combolist_productcode ("alter_part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			CALL combolist_productcode ("super_part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			CALL combolist_productcode ("compn_part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 

			CALL combolist_uomcode ("pur_uom_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_uomcode ("stock_uom_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_uomcode ("sell_uom_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 


		WHEN "I152" -- automatic price UPDATE 
			CALL combolist_warehouse ("ware_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_productcode ("part_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_productgroup ("prodgrp_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_maingrp ("maingrp_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_category ("cat_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_classcode ("class_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_vendorcode ("vend_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 

		WHEN "I155" -- warehouse image 
			CALL combolist_warehouse ("ware_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 

		WHEN "I158" -- selected SERIAL no. 
			CALL combolist_productcode ("d_part", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 

		WHEN "I159" -- product blends (Kits) (list) 

		WHEN "I160" -- product selection 
			CALL combolist_productcode ("part_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_maingrp ("maingrp_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_productgroup ("prodgrp_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_category ("cat_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_classcode ("class_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 

			CALL combolist_productcode ("alter_part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			CALL combolist_productcode ("super_part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			CALL combolist_productcode ("compn_part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 

			CALL combolist_uomcode ("pur_uom_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_uomcode ("stock_uom_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_uomcode ("sell_uom_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 

			CALL combolist_trantype_ind ("trantype_ind", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 

		WHEN "I161" -- product ledger 
			CALL combolist_productcode ("part_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_maingrp ("maingrp_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_productgroup ("prodgrp_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_warehouse ("ware_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_year_from_period ("year_num", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 
			CALL combolist_period ("period_num", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 
			CALL combolist_trantype_ind ("trantype_ind", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_prodadjtype_code_text("source_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT)


		WHEN "I162" -- warehouse stock status 
			CALL combolist_productcode ("part_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_maingrp ("maingrp_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_productgroup ("prodgrp_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL comboList_warehousePartStatus("status_ind", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_warehouse ("ware_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 

		WHEN "I162a" -- product pricing REPORT 
			CALL combolist_productcode ("part_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_category ("cat_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_classcode ("class_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_maingrp ("maingrp_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_productgroup ("prodgrp_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_warehouse ("ware_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 

		WHEN "I163" -- product selection 
			CALL combolist_productcode ("part_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_maingrp ("maingrp_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_productgroup ("prodgrp_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_category ("cat_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_classcode ("class_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_productcode ("alter_part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			CALL combolist_productcode ("super_part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			CALL combolist_productcode ("compn_part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			CALL combolist_warehouse ("ware_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_trantype_ind ("trantype_ind", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_year_from_period ("year_num", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 
			CALL combolist_period ("period_num", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 


		WHEN "I164" -- product quotations (list - nothing TO do) 

		WHEN "I165" -- product quotation 
			CALL combolist_vendorcode ("vend_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_productcode ("part_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_currency ("curr_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_currency ("frgt_curr_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 

		WHEN "I167" -- tariff code (list) 

		WHEN "I168" -- product pricing REPORT 
			CALL combolist_category ("cat_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_productcode ("part_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_warehouse ("ware_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 

		WHEN "I169a" -- inventory history REPORT 
			CALL combolist_productcode ("part_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_productgroup ("prodgrp_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_maingrp ("maingrp_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_category ("cat_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_classcode ("class_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_warehouse ("ware_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 

		WHEN "I170" -- product reorder REPORT 
			CALL comboList_category("cat_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I170a" -- reporting criteria 
			CALL combolist_year_from_period("year_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 
			CALL comboList_period("period_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 

		WHEN "I171" -- warehouse image 
			CALL comboList_warehouse("pr_ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_country("pr_country_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_country("country_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I172" -- product image selection 
			CALL comboList_productCode("part_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,combo_label_is_value_dash_label,null,COMBO_NULL_NOT) 
			CALL comboList_category("cat_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,combo_label_is_value_dash_label,null,COMBO_NULL_NOT) 
			CALL comboList_classCode("class_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,combo_label_is_value_dash_label,null,COMBO_NULL_NOT) 

			#			DISPLAY getLangStr("lb_state") TO lb_state
			#			DISPLAY getLangStr("lb_state") TO lb_state2

		WHEN "I173" -- user defined reference definitions 
			CALL comboList_validation("ref1_ind",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_validation("ref2_ind",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_validation("ref3_ind",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_validation("ref4_ind",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_validation("ref5_ind",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_validation("ref6_ind",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_validation("ref7_ind",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_validation("ref8_ind",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I174" -- statistical minimum turnover 

		WHEN "I175" -- stock re-order REPORT 
			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_maingrp("maingrp_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_productGroup("prodgrp_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_classCode("class_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_productCode("alter_part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I177" -- in post REPORT (list) 
			CALL combolist_year_from_period("year_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 
			CALL comboList_period("period_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint)

		WHEN "I178" -- in snapshot REPORT 
			CALL combolist_year_from_period("year_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 
			CALL comboList_period("period_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 

		WHEN "I179" -- automatic price UPDATE 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_productGroup("prodgrp_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_maingrp("maingrp_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_vendorCode("vend_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_category("cat_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I180" -- inventory replenishment 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_maingrp("maingrp_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_productGroup("prodgrp_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I181" -- recommended re-order REPORT 
			CALL comboList_vendorCode("vend_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_category("cat_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I182" -- product issues 
			CALL combolist_year_from_period("year_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 
			CALL comboList_period("period_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 
			CALL comboList_coa_account("acct_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) --pvariable,psort,psingle,phint) 
			CALL combolist_prodadjtype_code_text("source_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT)
		WHEN "I183" -- stock valuation 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I184" -- cost ledger inquiry 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I185" -- product margin 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I186" -- SERIAL numbers 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I187" -- stock reorder REPORT 
			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_category("cat_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_maingrp("maingrp_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_productGroup("prodgrp_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_classCode("class_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I188" -- GROUP details maintenance 
			#CALL comboList_ingroup("ingroup_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT)
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I189" -- product selection 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I200" -- adjust product cost (list) 

		WHEN "I201" -- product / DATE selection (list) 
			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I202" -- product cost adjustment 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL combolist_year_from_period("year_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 
			CALL comboList_period("period_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 
			CALL comboList_coa_account("acct_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) --pvariable,psort,psingle,phint) 


		WHEN "I203" -- adjust product quantity (list) 

		WHEN "I204" -- product / DATE selection 
			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I205" -- product adjustment 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL combolist_year_from_period("year_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 
			CALL comboList_period("period_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 
			CALL comboList_coa_account("acct_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) --pvariable,psort,psingle,phint) 

		WHEN "I206" -- stock valuation 
			CALL comboList_category("cat_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_classCode("class_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I207" -- stock revaluation 
			CALL comboList_category("cat_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_classCode("class_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 


		WHEN "I208" -- stock turn calculator 
			#nothing TO do

		WHEN "I209" -- stockturn information 
			#nothing TO do

		WHEN "I211" -- inventory purchase ORDER LINES 
			CALL comboList_productCode("ref_text",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_coa_account("acct_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) --pvariable,psort,psingle,phint) 
			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_uomCode("sell_uom_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_uomCode("pur_uom_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL combolist_year_from_period("year_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 
			CALL comboList_period("period_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 


		WHEN "I213" -- product history (list) 


		WHEN "I214" -- pricing exception REPORT 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL combolist_year_from_period("year_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 
			CALL comboList_period("period_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 
			CALL comboList_salesPerson("sale_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) 
			CALL comboList_customerType("type_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) 
			CALL comboList_customer("cust_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) 
			CALL comboList_classCode("class_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_maingrp("maingrp_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_productGroup("prodgrp_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_category("cat_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I215" -- costledger validation 
			CALL comboList_category("cat_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_classCode("class_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I216" -- aged stock valuation 
			CALL comboList_category("cat_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_classCode("class_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I217" -- product lead time UPDATE 
			CALL comboList_vendorCode("vend_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I220" -- stock take details 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_productGroup("prodgrp_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_maingrp("maingrp_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 


		WHEN "I222" -- stock take adjustments listing 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_productGroup("prodgrp_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_maingrp("maingrp_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I223" -- stocktake count sheets 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_productGroup("prodgrp_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_maingrp("maingrp_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I224" -- stock take count / file creation 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_productGroup("prodgrp_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_maingrp("maingrp_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 


		WHEN "I225" -- valuation method 
			#nothing TO do

		WHEN "I226" -- unit dimensions & packing 
			#nothing TO do

		WHEN "I254" -- product amendment LOG 
			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_maingrp("maingrp_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_productGroup("prodgrp_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_category("cat_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_classCode("class_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_user("user_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I256" -- product amendment LOG 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_uomCode("stock_uom_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_uomCode("sell_uom_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_user("user_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 


		WHEN "I257" -- product amendment LOG (list) 
			#nothing TO do

		WHEN "I258" -- product blend/kit compilation 
			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_warehouse("pr_kit_warehouse",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_kit("kit_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint)
			CALL combolist_prodadjtype_code_text("source_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL combolist_year_from_period("pr_year_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 
			CALL comboList_period("pr_period_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 

		WHEN "I259" -- product blend/kit maintenance 
			CALL comboList_kit("kit_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 

		WHEN "I260" -- kit SERIAL numbering 
			#nothing TO do

		WHEN "I261" -- serialized products 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I500" -- product information 
			CALL combolist_productcode ("part_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_prodinfo_info_ind ("info_ind", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 

		WHEN "I600" -- product detail scan 
			CALL comboList_productGroup("prodgrp_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_maingrp("maingrp_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 

			CALL comboList_prodSubDept("subdept_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 


			#nothing TO do

		WHEN "I601" -- product GROUP scan (List) 
			#nothing TO do

		WHEN "I602" -- MAIN product GROUP scan (List) 
			#nothing TO do

		WHEN "I603" -- MAIN product GROUP maintenance (List) 
			CALL comboList_maingrp("maingrp_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 

		WHEN "I603_query" -- MAIN product GROUP maintenance (List) 
			CALL comboList_maingrp("maingrp_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 


		WHEN "I604" -- MAIN product GROUP maintenance 
			#CALL comboList_maingrp("maingrp_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT)
			CALL comboList_proddept("dept_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I605" -- product GROUP maintenance (list) 
			#nothing TO do

		WHEN "I606" -- product GROUP maintenance 
			CALL comboList_proddept("dept_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			--CALL comboList_productGroup("prodgrp_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			--CALL comboList_maingrp("maingrp_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 

		WHEN "I607" -- department maintenance (list) 
			#nothing TO do
		WHEN "I608" -- department maintenance 
			CALL comboList_proddept("dept_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I609" -- department scan (list) 
			#nothing TO do

		WHEN "I610" -- product details 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_productGroup("prodgrp_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_category("cat_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_classCode("class_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

			CALL comboList_productCode("alter_part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_productCode("super_part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_productCode("compn_part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

			CALL comboList_uomCode("pur_uom_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 
			CALL comboList_uomCode("stock_uom_code",0,9,0,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_uomCode("sell_uom_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_uomCode("price_uom_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I611" -- product reporting codes (list) 
			#nothing TO do

		WHEN "I612" -- product details (list) 
			#nothing TO do

		WHEN "I613" -- product stock status (list) 
			CALL comboList_product_status("status_ind",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_category("cat_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_classCode("class_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL combolist_proddept("dept_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I614" 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_product_analysis_abc("abc_ind",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

			#Note, there are currently 3 stock_uom_code fields in the form
			CALL comboList_uomCode("stock_uom_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I615" -- warehouse pricing 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_uomCode("price_uom_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 
			CALL comboList_uomCode("sell_uom_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 

			CALL comboList_tax_code("sale_tax_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_tax_code("purch_tax_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

			CALL comboList_currency("for_curr_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I616" -- product trends REPORT 
			CALL combolist_year_from_period("year_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 
			CALL comboList_period("period_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 

			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

			CALL comboList_maingrp("maingrp_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_productGroup("prodgrp_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_classCode("class_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_productCode("alter_part_code ",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I617" -- REPORT warehouse 

			CALL combolist_year_from_period("year_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 
			CALL comboList_period("period_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 
			CALL comboList_reportingLevel("report_ind",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 
			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_proddept("dept_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_maingrp("maingrp_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_productGroup("prodgrp_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_classCode("class_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_productCode("alter_part_code ",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I618" -- product quotation processing 
			#nothing TO do ?  --file import load config

		WHEN "I619" -- UPDATE inventory prices AND costs 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_productGroup("prodgrp_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_category("cat_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_classCode("class_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			#Note: 2 fields with vend_code !!! sugar
			CALL comboList_vendorCode("vend_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			#CALL comboList_vendorCode("vend_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT)
			CALL comboList_currency("curr_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I620" -- product notes selection (list) 
			#nothing TO do

		WHEN "I621" -- product class details
			#we need to populate these combos here because we need the class_code (in the query) which is not available at this time 
			#CALL comboList_classCode            ("class_code",     COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			#CALL comboList_class_price_level_ind("price_level_ind",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT)	--price type  --fieldName,pVariable,pSort,pSingle,pHint)
			#CALL comboList_class_ord_level_ind  ("ord_level_ind",  COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT)
			#stock_level_ind
			#desc_level_ind
			#CALL comboList_prodStructure_seq_num("class_code",     COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT)

		WHEN "I622" -- product flexible structure (list) 
			#nothing TO do

		WHEN "I623" -- product flex codes 
			CALL comboList_classCode("class_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_prodStructure_seq_num("start_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I624" -- product segments (list) 
			#nothing TO do
		WHEN "I625" -- product segment verifier 
			CALL comboList_classCode("class_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I626" -- product details 
			CALL combolist_category ("cat_code", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT)
			CALL combolist_classcode ("class_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
 			CALL combolist_proddept ("dept_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_productgroup ("prodgrp_code", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			# ericv 20201122: productgrp, maingrp and product are replaced by dynamic combo functions (consider values previously input)
			CALL combolist_productcode ("alter_part_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NONE) 
			CALL combolist_productcode ("super_part_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NONE) 
			CALL combolist_productcode ("compn_part_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NONE) 

			CALL combolist_uomcode ("pur_uom_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 
			CALL combolist_uomcode ("stock_uom_code", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_uomcode ("sell_uom_code", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_uomcode ("price_uom_code", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_proddanger_dg_code ("dg_code", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NONE) 

			{
					WHEN "I626_refresh"		-- Product Details
						CALL ui.ComboBox.ForName("class_code").CLEAR()
						CALL comboList_classCode           ("class_code",      COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT)
						CALL ui.ComboBox.ForName("prodgrp_code").CLEAR()
						CALL comboList_productGroup        ("prodgrp_code",    COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT)
						CALL ui.ComboBox.ForName("cat_code").CLEAR()
						CALL comboList_category            ("cat_code",        COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT)
						CALL ui.ComboBox.ForName("lter_part_code").CLEAR()
						CALL comboList_productCode         ("alter_part_code", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT)
						CALL ui.ComboBox.ForName("super_part_code").CLEAR()
						CALL comboList_productCode         ("super_part_code", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT)
						CALL ui.ComboBox.ForName("compn_part_code").CLEAR()
						CALL comboList_productCode         ("compn_part_code", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT)
						CALL ui.ComboBox.ForName("pur_uom_code").CLEAR()
						CALL comboList_uomCode             ("pur_uom_code",    COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT)	--price type  --fieldName,pVariable,pSort,pSingle,pHint)
						CALL ui.ComboBox.ForName("stock_uom_code").CLEAR()
						CALL comboList_uomCode             ("stock_uom_code",  COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT)
						CALL ui.ComboBox.ForName("sell_uom_code").CLEAR()
						CALL comboList_uomCode             ("sell_uom_code",   COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT)
						CALL ui.ComboBox.ForName("price_uom_code").CLEAR()
						CALL comboList_uomCode             ("price_uom_code",  COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT)
						CALL ui.ComboBox.ForName("dg_code").CLEAR()
						CALL comboList_proddanger_dg_code  ("dg_code",         COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT)

			}

		WHEN "I627" -- product LABEL formats (list) 
			#nothing TO do
		WHEN "I628" -- product LABEL formats (list) 
			# label_code  ??
			CALL comboList_printcodes("print_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I629" -- product adjustment types (list) 
			CALL comboList_coa_account_current("adj_acct_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,COMBO_NULL_NOT)  
			#CALL comboList_coa_account ("cash_acct_code", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT)

			#FUNCTION comboList_coa_account(cb_field_name,pVariable,pSort,pSingle,pHint,p_account_type_required)


		WHEN "I630" -- product LABEL generation 
			CALL comboList_labelHeadCode("label_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_category("cat_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_productGroup("prodgrp_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_maingrp("maingrp_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_vendorCode("vend_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I631" -- product labels (list) 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT)

		WHEN "I632" -- product labels (list) 
			#nothing TO do

		WHEN "I633" -- product schedule parameters 
			#nothing TO do

		WHEN "I634" -- inventory production schedule 
			CALL comboList_productCode("part_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL comboList_warehouse("ware_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 

		WHEN "I635" -- inventory production schedule 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I636" -- inventory production schedule (list) 

		WHEN "I637" -- product reclassification 
			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_uomCode("stock_uom_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_uomCode("stock3_uom_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

			CALL combolist_year_from_period("year_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 
			CALL comboList_period("period_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 

			CALL comboList_uomCode("sell_uom_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_uomCode("sell3_uom_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_uomCode("sell_uom",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_uomCode("sell2_uom",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I638" -- product reclassification 
			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL combolist_year_from_period("year_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 
			CALL comboList_period("period_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 
			CALL comboList_uomCode("stock_uom_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_uomCode("sell_uom_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I639" -- product surcharge (list) 
			#nothing TO do

		WHEN "I640" -- product surcharge 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_uomCode("sell_uom_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			#double identifier
			#CALL comboList_uomCode("sell_uom_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT)
			CALL comboList_uomCode("base_uom_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I643" -- ??? DYNAMIC title 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_proddept("dept_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_maingrp("maingrp_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_productGroup("prodgrp_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_classCode("class_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_vendorCode("vend_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_category("cat_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I644" -- stock-take scan (list) 

		WHEN "I645" -- posting details 
			CALL combolist_year_from_period("year_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 
			CALL comboList_period("period_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 
			CALL comboList_customerType("source_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) 
			CALL comboList_coa_account("adj_acct_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) --pvariable,psort,psingle,phint) 

		WHEN "I646" -- product information 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_category("cat_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_productGroup("prodgrp_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_classCode("class_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_maingrp("maingrp_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			#CALL rev_code ????? needs checking in 4gl what table IS queried
			CALL comboList_productCode("alter_part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_productCode("super_part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_productCode("compn_part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_uomCode("pur_uom_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_uomCode("stock_uom_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_uomCode("sell_uom_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_vendorCode("vend_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I647" --warehouse GROUP maintenance (LIST) 

		WHEN "I648" --bar code validation 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_productGroup("prodgrp_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_category("cat_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_classCode("class_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_vendorCode("vend_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I649" --bar code maintenance 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I650" --warehouse GROUP maintenance (LIST) 
			CALL comboList_waregrp("waregrp_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) --price type --psort,psingle,phint) 


		WHEN "I651" --dangerous goods classes (LIST) (list) 
			#nothing TO do
		WHEN "I652" --dangerous goods segregation (LIST) 
			CALL comboList_classCode("class_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I653" -- dangerous goods codes (LIST) 
			#nothing TO do

		WHEN "I654" -- dangerous goods detail 
			CALL comboList_proddanger_dg_code("class_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I655" -- dangerous goods class (LIST) 
			#nothing TO do
		WHEN "I656" -- dangerous goods codes (LIST) 
			#nothing TO do
		WHEN "I657" -- stock take details (list) 
			#cycle_num ?
			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 


		WHEN "I658" -- stock take reversal selection (LIST) 
			#nothing TO do

		WHEN "I661" -- product transaction purge 
			CALL combolist_year_from_period("pr_ret_year",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 
			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_maingrp("maingrp_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) 
			CALL comboList_productGroup("prodgrp_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) 
			CALL comboList_category("cat_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I662" -- product transaction purge confirmation 
			#nothing TO do

		WHEN "I663" -- transfer 
			CALL comboList_warehouse("from_ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_warehouse("to_ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

			CALL combolist_year_from_period("year_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 
			CALL comboList_period("period_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 

			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 


		WHEN "I664" -- lables / PRINT dispatch labels 
			CALL comboList_warehouse("from_ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_warehouse("to_ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL combolist_year_from_period("year_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 
			CALL comboList_period("period_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 



		WHEN "I668" -- stock transfers (LIST) 
			#nothing TO do

		WHEN "I669" -- stock transfers 
			CALL comboList_warehouse("from_ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_warehouse("to_ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL combolist_year_from_period("year_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 
			CALL comboList_period("period_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 


		WHEN "I670" -- transfer confirmation 
			CALL combolist_year_from_period("year_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 
			CALL comboList_period("period_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 

		WHEN "I671" -- transfer receipt 
			CALL combolist_year_from_period("year_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 
			CALL comboList_period("period_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 

		WHEN "I672" -- product LOAD 
			#load_ind
			CALL comboList_write_file_path_default("path_text",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_tax_code("sale_tax_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_tax_code("purch_tax_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I673" -- in LOAD parameters (list) 
			#nothing TO do

		WHEN "I674" -- in import parameters 
			#load_ind
			CALL comboList_write_file_path_default("path_text",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I675" -- from_ware_code 
			CALL comboList_warehouse("from_ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_warehouse("to_ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I676" -- transfer deliveries 
			CALL comboList_warehouse("from_ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_warehouse("to_ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I677" -- details 
			CALL comboList_warehouse("from_ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_warehouse("to_ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_transptype("transp_type_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I678" -- transfer receipts 
			CALL comboList_warehouse("from_ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_warehouse("to_ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I679" -- product selection 
			CALL comboList_write_file_path_default("pr_path_name",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_productGroup("prodgrp_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_maingrp("maingrp_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_category("cat_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_classCode("class_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_vendorCode("vend_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I680" --promotion maintenance (list) 
			#nothing TO do

		WHEN "I681" -- promotion detail maintenance 
			#offer_code ?
			CALL comboList_price_type("type_ind",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) --price type --psort,psingle,phint) 
			CALL comboList_maingrp("maingrp_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			#CALL comboList_glrepsubgrp("maingrp_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT)
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_productGroup("prodgrp_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_classCode("class_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_uomCode("uom_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_priceLevel2("list_level_ind",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) --pvariable,psort,psingle,phint) 

		WHEN "I682" -- shipment in transit status 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			#Note: stock_uom_code IS a duplicated identifier
			CALL comboList_uomCode("stock_uom_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) #note: there are 2 combo with the same identifier 

		WHEN "I683" -- bin location maintenance 
			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			#			CALL comboList_location("locn_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT)
		WHEN "I684" -- customer product codes 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I687" -- tariff LOAD 
			CALL comboList_write_file_path_default("path_text",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I688" -- UPDATE inventory foreign costs 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_productGroup("prodgrp_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_category("cat_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_classCode("class_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_vendorCode("product.vend_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_currency("for_curr_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_vendorCode("prodquote.vend_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) #note: identifier exists twice.. how do we deal with this 

		WHEN "I689" -- product selection 
			CALL comboList_write_file_path_default("pr_path_name",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_maingrp("maingrp_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_productGroup("prodgrp_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_vendorCode("vend_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I693" -- stock-take LOAD 
			CALL comboList_write_file_path_default("path_text",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I701" -- product supersession (list) 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I702" -- alternative products 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I703" -- companion products 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I704" -- sequence number UPDATE confirmation 
			#nothing TO do

		WHEN "I705" -- price list comparison 
			CALL comboList_vendorCode("vend_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_category("cat_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_maingrp("maingrp_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_productGroup("prodgrp_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_classCode("class_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I706" -- stock transfer 
			CALL combolist_year_from_period("year_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 
			CALL comboList_period("period_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 
			CALL comboList_uomCode("uom_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_warehouse("from_ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_warehouse("to_ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I707" -- aged stock valuation 
			CALL comboList_category("cat_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_classCode("class_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "I50_" -- Stock Transfer Reports 
			#nothing TO do

		WHEN "IA00" -- Product Reports 
			#nothing TO do

		WHEN "IB00" -- Warehouse Reports 
			#nothing TO do

		WHEN "IC00" -- Pricing Reports 
			#nothing TO do

		WHEN "ID00" -- Stock Re-order Reports 
			#nothing TO do

		WHEN "IR00" -- Inventory Reports 
			#nothing TO do

		OTHERWISE 
			LET errmsg = "Invalid Window name passed TO winDecoration_I(", trim(pwinname), ")" 
			CALL fgl_winmessage("Internal 4GL Error",errMsg, "error") 
	END CASE 

END FUNCTION 
