#Vendor Inquiry - vendor searching AND viewing details (no edit)
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
	Source code beautified by beautify.pl on 2020-01-03 13:41:17	$Id: $
}
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
--GLOBALS "../ap/P_AP_P1_GLOBALS.4gl"
--GLOBALS "P12_GLOBALS.4gl"  
############################################################
# Module Scope Variables
############################################################
#DEFINE pr_apparms RECORD LIKE apparms.*
#DEFINE glob_rec_vendor RECORD LIKE vendor.*


############################################################
# MAIN
#
#   allows the user TO view Vendor Information including credit
#   information on a single vendor AT a time but selecting a number
#   of parameters
############################################################
MAIN 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_withquery SMALLINT 

	#Initial UI Init
	CALL setModuleId("P12") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_p_ap() #init p/ap module 

	#   SELECT * INTO pr_apparms.* FROM apparms
	#    WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
	#   IF STATUS = NOTFOUND THEN
	#      LET l_msgresp=kandoomsg("P",5016,"")
	#      EXIT PROGRAM
	#   END IF

	OPEN WINDOW p105 with FORM "P105" 
	CALL windecoration_p("P105") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	#if the the table has more than 1000 rows, force a query TO filter data
	IF db_vendor_get_count() < 1000 THEN #if there are less than 1000 records, select/show all records 
		CALL select_vendor(l_withquery) 
		LET l_withquery = 0 
	ELSE 
		LET l_withquery = 1 
	END IF 


	CALL query(l_withquery) 

	CLOSE WINDOW p105 

END MAIN 


############################################################
# FUNCTION select_vendor()
#
#
############################################################
FUNCTION select_vendor(p_withquery) 
	DEFINE p_withquery SMALLINT 
	DEFINE l_where_text CHAR(2048) 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_msgresp LIKE language.yes_flag 

	IF p_withquery = 1 THEN 

		CLEAR FORM 

		LET l_msgresp=kandoomsg("P",1001,"") 
		#1001 Enter Selection Criteria
		CONSTRUCT BY NAME l_where_text ON vend_code, 
		name_text, 
		currency_code, 
		addr1_text, 
		addr2_text, 
		addr3_text, 
		city_text, 
		state_code, 
		post_code, 
		country_code, 
		curr_amt, 
		over1_amt, 
		over30_amt, 
		over60_amt, 
		over90_amt, 
		bal_amt, 
		avg_day_paid_num, 
		type_code, 
		term_code, 
		tax_code, 
		hold_code, 
		pay_meth_ind, 
		usual_acct_code, 
		vat_code, 
		last_po_date, 
		last_vouc_date, 
		last_payment_date, 
		setup_date, 
		highest_bal_amt, 
		ytd_amt 


			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","P12","construct-vendor-1") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON ACTION "LookupVendor" 
				LET glob_rec_vendor.vend_code = vendorlookup(glob_rec_vendor.vend_code) 
				DISPLAY BY NAME glob_rec_vendor.vend_code 

				#ON ACTION "LookupCoa"
				#	LET glob_rec_vendor.our_acct_code = db_coa_get_lookup(glob_rec_vendor.our_acct_code)
				#	DISPLAY BY NAME glob_rec_vendor.our_acct_code

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 

			#if the the table has more than 1000 rows, force a query TO filter data
			IF db_vendor_get_count() < 1000 THEN #if there are less than 1000 records, select/show all records 
				RETURN true 
			ELSE 
				RETURN false 
			END IF 
		END IF 

	ELSE 
		LET l_where_text = "1=1" 
	END IF 

	LET l_msgresp=kandoomsg("P",1002,"") 
	#1001 Searching database - please wait
	LET l_query_text = "SELECT * FROM vendor ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND ",l_where_text clipped 

	IF glob_rec_apparms.report_ord_flag = "A" THEN 
		LET l_query_text = l_query_text clipped," ORDER BY name_text,vend_code" 
	ELSE 
		LET l_query_text = l_query_text clipped," ORDER BY vend_code" 
	END IF 

	PREPARE s_vendor FROM l_query_text 
	DECLARE c_vendor SCROLL CURSOR FOR s_vendor 
	OPEN c_vendor 
	FETCH c_vendor INTO glob_rec_vendor.* 

	IF status = 0 THEN 
		RETURN true 
	ELSE 
		RETURN false 
	END IF 

END FUNCTION 


############################################################
# FUNCTION query(p_WithQuery)
#
#
############################################################
FUNCTION query(p_withquery) 
	DEFINE p_withquery SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	MENU " Vendor" 
		BEFORE MENU 
			IF p_withquery THEN 

				HIDE option "Next" 
				HIDE option "Previous" 
				HIDE option "First" 
				HIDE option "Last" 
				HIDE option "Detail" 
			ELSE 
				CALL display_vendor() 
			END IF 

			CALL publish_toolbar("kandoo","P12","menu-vendor-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		COMMAND "Query" " Enter Vendor selection criteria" 
			IF select_vendor(1) THEN 
				CALL display_vendor() 
				SHOW option "Next" 
				SHOW option "Previous" 
				SHOW option "First" 
				SHOW option "Last" 
				SHOW option "Detail" 
			ELSE 
				HIDE option "Next" 
				HIDE option "Previous" 
				HIDE option "First" 
				HIDE option "Last" 
				HIDE option "Detail" 
				LET l_msgresp=kandoomsg("P",9044,"") 
				#9044 No vendor satisfied the query criteria"
			END IF 

		COMMAND "Next" " DISPLAY next selected vendor" 
			FETCH NEXT c_vendor INTO glob_rec_vendor.* 
			IF status = 0 THEN 
				CALL display_vendor() 
			ELSE 
				LET l_msgresp=kandoomsg("P",9001,"") 
				#P9001 "You have reached the END of the rows selected"
			END IF 

		COMMAND "Previous" " DISPLAY previous selected vendor" 
			FETCH previous c_vendor INTO glob_rec_vendor.* 
			IF status = 0 THEN 
				CALL display_vendor() 
			ELSE 
				LET l_msgresp=kandoomsg("P",9001,"") 
				#P9001 "You have reached the END of the rows selected"
			END IF 

		COMMAND "Detail" " View vendor details" 
			CALL vinq_vend(glob_rec_kandoouser.cmpy_code,glob_rec_vendor.vend_code) 

		COMMAND "First" " DISPLAY first vendor in the selected list" 
			FETCH FIRST c_vendor INTO glob_rec_vendor.* 
			IF status = 0 THEN 
				CALL display_vendor() 
			ELSE 
				LET l_msgresp=kandoomsg("P",9001,"") 
				#P9001 "You have reached the END of the rows selected"
			END IF 

		COMMAND "Last" " DISPLAY last vendor in the selected list" 
			FETCH LAST c_vendor INTO glob_rec_vendor.* 
			IF status <> NOTFOUND THEN 
				CALL display_vendor() 
			ELSE 
				LET l_msgresp=kandoomsg("P",9001,"") 
				#P9001 "You have reached the END of the rows selected"
			END IF 

		COMMAND "Exit" " Exit this program" 
			LET int_flag = false 
			LET quit_flag = false 
			EXIT MENU 


	END MENU 

END FUNCTION 



############################################################
# FUNCTION display_vendor()
#
#
############################################################
FUNCTION display_vendor() 
	DEFINE l_rec_pr_term RECORD LIKE term.* 
	DEFINE l_rec_pr_tax RECORD LIKE tax.* 
	DEFINE l_rec_pr_holdpay RECORD LIKE holdpay.* 
	DEFINE l_rec_pr_vendortype RECORD LIKE vendortype.* 
	DEFINE l_pr_method_text CHAR(30) 

	SELECT * INTO l_rec_pr_term.* FROM term 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND term_code = glob_rec_vendor.term_code 

	IF status = NOTFOUND THEN 
		LET l_rec_pr_term.desc_text = "**********" 
	END IF 

	SELECT * INTO l_rec_pr_vendortype.* FROM vendortype 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND type_code = glob_rec_vendor.type_code 

	IF status = NOTFOUND THEN 
		LET l_rec_pr_vendortype.type_text = "**********" 
	END IF 

	IF glob_rec_vendor.hold_code IS NOT NULL THEN 
		SELECT * INTO l_rec_pr_holdpay.* FROM holdpay 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND hold_code = glob_rec_vendor.hold_code 
		IF status = NOTFOUND THEN 
			LET l_rec_pr_holdpay.hold_text = "**********" 
		END IF 
	END IF 

	SELECT * INTO l_rec_pr_tax.* FROM tax 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tax_code = glob_rec_vendor.tax_code 

	IF status = NOTFOUND THEN 
		LET l_rec_pr_tax.desc_text = "**********" 
	END IF 

	DISPLAY BY NAME glob_rec_vendor.vend_code, 
	glob_rec_vendor.name_text, 
	glob_rec_vendor.addr1_text, 
	glob_rec_vendor.addr2_text, 
	glob_rec_vendor.addr3_text, 
	glob_rec_vendor.city_text, 
	glob_rec_vendor.state_code, 
	glob_rec_vendor.post_code, 
	glob_rec_vendor.country_code,
--@db-patch_2020_10_04--	--glob_rec_vendor.country_text, 
	glob_rec_vendor.curr_amt, 
	glob_rec_vendor.over1_amt, 
	glob_rec_vendor.over30_amt, 
	glob_rec_vendor.over60_amt, 
	glob_rec_vendor.over90_amt, 
	glob_rec_vendor.bal_amt, 
	glob_rec_vendor.type_code, 
	glob_rec_vendor.term_code, 
	glob_rec_vendor.tax_code, 
	glob_rec_vendor.pay_meth_ind, 
	glob_rec_vendor.usual_acct_code, 
	glob_rec_vendor.vat_code, 
	glob_rec_vendor.hold_code, 
	glob_rec_vendor.highest_bal_amt, 
	glob_rec_vendor.avg_day_paid_num, 
	glob_rec_vendor.ytd_amt, 
	glob_rec_vendor.setup_date, 
	glob_rec_vendor.last_po_date, 
	glob_rec_vendor.last_vouc_date, 
	glob_rec_vendor.last_payment_date,
	glob_rec_vendor.usual_acct_code
	 

	LET l_pr_method_text = kandooword("vendor.pay_meth_ind",glob_rec_vendor.pay_meth_ind) 
	DISPLAY l_rec_pr_vendortype.type_text TO  vendortype.type_text
	DISPLAY l_rec_pr_term.desc_text TO term.desc_text
	DISPLAY l_rec_pr_tax.desc_text TO tax.desc_text
	DISPLAY l_rec_pr_holdpay.hold_text TO holdpay.hold_text
	DISPLAY l_pr_method_text TO method_text  
	DISPLAY glob_rec_vendor.currency_code TO currency_code
	  
	DISPLAY db_currency_get_desc_text(UI_OFF,glob_rec_vendor.currency_code) TO currency.desc_text
	DISPLAY db_coa_get_desc_text(UI_OFF,glob_rec_vendor.usual_acct_code) TO coa.desc_text 
	
	

	
END FUNCTION 


