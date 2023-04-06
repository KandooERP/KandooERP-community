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
#  A11a.4gl contains attribute the GLOBALS variables AND two
#           maintanence functions FOR customer add AND edit.
#  Functions are:  1. corp_cust()    Maintains corp_cust fields
#                  2. report_codes() Maintains reporting code fields
#  Both functions UPDATE a global custromer RECORD 'glob_rec_customer' AND
#  RETURN TRUE OR FALSE depending IF user backed out of SCREEN OR NOT.
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/A1_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/A11_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_show_corp_ind SMALLINT -- true/false Corporate customer turned on.
DEFINE modu_prev_hold_code LIKE customer.hold_code
DEFINE modu_auto_cust_ind SMALLINT -- true/false auto customer turned on.
DEFINE modu_rec_custstmnt RECORD LIKE custstmnt.* 	   

############################################################
# FUNCTION process_customer(p_mode)
#
#
############################################################
FUNCTION process_customer(p_mode) 
	DEFINE p_mode CHAR(4) 
	DEFINE l_tempstr STRING 
	DEFINE l_ret_entry_state boolean 
	DEFINE l_run_arg STRING 
	DEFINE l_temp_text STRING

	LET glob_update_order_hold = false 
	LET modu_prev_hold_code = NULL 
	LET glob_grp_cust_inv = get_kandoooption_feature_state("AR","GI") 

	LET l_ret_entry_state = true #true = CONTINUE customer entry/addition false=exit 

	MENU " Customer" 
		BEFORE MENU 
			SHOW OPTION ALL 
			
			IF NOT modu_show_corp_ind THEN 
				HIDE option "Corporate" 
			END IF 
			
			IF NOT glob_show_rep_ind THEN 
				HIDE option "Report" 
			END IF 
			
			IF p_mode = MODE_CLASSIC_ADD THEN 
				HIDE option "Product" 
				HIDE option "Notes" 
			END IF 
			
			IF glob_grp_cust_inv != "Y" THEN 
				HIDE option "Group" 
			END IF 

			CALL publish_toolbar("kandoo","A11","menu-customer") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "Group"		#COMMAND "Group" "Add the customer group details"
			CALL add_cust_grps(glob_rec_kandoouser.cmpy_code, glob_rec_customer.cust_code) 

		ON ACTION "Save" 		#COMMAND "Save" " Save customer details TO the database"
			IF update_customer(p_mode) THEN 
				#7014 "Customer ?? added successfully
				LET l_temp_text = glob_rec_customer.cust_code clipped,":",	glob_rec_customer.name_text clipped 
				MESSAGE kandoomsg2("A",7014,l_temp_text) 

				CALL set_db_clipboard_string_val(glob_rec_customer.cust_code) 

				IF p_mode = MODE_CLASSIC_ADD THEN 

					MENU " Customer Info" 
						BEFORE MENU 
							CALL publish_toolbar("kandoo","A11","menu-customer-info") 

						ON ACTION "WEB-HELP" 
							CALL onlinehelp(getmoduleid(),null) 

						ON ACTION "actToolbarManager" 
							CALL setuptoolbar() 

						ON ACTION "Notes"					#COMMAND "Notes"  " Enter Customer Notes "
							CALL edit_notes(glob_rec_kandoouser.cmpy_code,glob_rec_customer.cust_code) 

						ON ACTION "Products"						#COMMAND "Product"  " Enter Customer Products "
							LET l_run_arg = "CUSTOMER_CODE=", trim(glob_rec_customer.cust_code) 
							CALL run_prog("A1F",l_run_arg,"","","") #a1f customer product codes 

						ON ACTION "ADD" 
							EXIT MENU 

						ON ACTION "Exit" 
							#COMMAND KEY(interrupt,"E")"Exit"
							LET int_flag = true 
							EXIT MENU 

					END MENU 

				END IF 

			END IF 

			EXIT MENU 

		ON ACTION "Parameters"		#COMMAND KEY ("D",f20) "Detail" " Enter customer SET up parameters"
			IF customer_edit_2() THEN 
			END IF 

		ON ACTION "Credit" 		#COMMAND "Credit"     " Enter credit details "
			IF customer_edit_3(p_mode) THEN 
			END IF 

		ON ACTION "Corporate"		#COMMAND "Corporate"  " Enter corporate customer details "
			CALL customer_edit_5() 

		ON ACTION "Report" 	#COMMAND "Report"  " Enter reporting code details "
			IF customer_edit_6() THEN 
			END IF 

		ON ACTION "Shipping"	#COMMAND "Shipping"   " Enter shipping addresses "
			IF p_mode = MODE_CLASSIC_ADD THEN 
				CALL customer_edit_4() 
			ELSE 
				LET l_run_arg = "CUSTOMER_CODE=", trim(glob_rec_customer.cust_code) 
				CALL run_prog("A17","MODE=ADD",l_run_arg,NULL,NULL) --manage shipping addresses OF CURRENT customer 
			END IF 

		ON ACTION "Billing"		#COMMAND "Billing"  " Enter customers billing details"
			IF edit7_cust() THEN 
			END IF 

		ON ACTION "Notes"	#COMMAND "Notes" " Enter Customer Notes "
			CALL edit_notes(glob_rec_kandoouser.cmpy_code,glob_rec_customer.cust_code) 

		ON ACTION "Product"	#COMMAND "Product"  " Enter Customer Products "
			LET l_run_arg = "CUSTOMER_CODE=", trim(glob_rec_customer.cust_code) 
			CALL run_prog("A1F",l_run_arg,"","","") #a1f customer product codes 

		ON ACTION "Exit" 	#COMMAND KEY(interrupt,"E")"Exit" "Discard Customer"
			EXIT MENU 

	END MENU 

	IF get_url_child_run_once_only() THEN 
		RETURN false 
	END IF 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 

END FUNCTION 
############################################################
# FUNCTION process_customer(p_mode)
############################################################


############################################################
# FUNCTION INITIALIZE_globals(p_mode,p_cust_code)
#
#.
############################################################
FUNCTION initialize_globals(p_mode,p_cust_code) 
	DEFINE p_cust_code LIKE customer.cust_code 
	DEFINE p_mode CHAR(4) 
	DEFINE l_msg STRING 

	CALL arparms_init() # AR/Account Receivable Parameters (arparms)

	IF get_debug() = true THEN 
		DISPLAY "########### A-Modules - INITIALIZE_globals(p_mode,p_cust_code) 1 ################" 
		DISPLAY "p_mode=", p_mode 
		DISPLAY "p_cust_code=", p_cust_code 
		DISPLAY "glob_rec_kandoouser.cmpy_code = ", glob_rec_kandoouser.cmpy_code 
	END IF 

	#--------------------------------------------------------------------
	# This FUNCTION sets up the following GLOBALS variables...
	#   country, company,  glparms,  arparms,  customer
	#--------------------------------------------------------------------
	IF get_kandoooption_feature_state("AR","CN") = "Y" THEN 
		LET modu_auto_cust_ind = true 
	ELSE 
		LET modu_auto_cust_ind = false 
	END IF 

	IF get_debug() = true THEN 
		DISPLAY "########### A-Modules - INITIALIZE_globals(p_mode,p_cust_code) 2 ################" 
		DISPLAY "p_mode=", p_mode 
		DISPLAY "p_cust_code=", p_cust_code 
		DISPLAY "glob_rec_kandoouser.cmpy_code = ", glob_rec_kandoouser.cmpy_code 
	END IF 

	IF glob_rec_arparms.corp_drs_flag != "Y" THEN 
		LET modu_show_corp_ind = false 
	ELSE 
		LET modu_show_corp_ind = true 
	END IF 

	IF glob_rec_arparms.ref1_text IS NOT NULL 
	OR glob_rec_arparms.ref2_text IS NOT NULL 
	OR glob_rec_arparms.ref3_text IS NOT NULL 
	OR glob_rec_arparms.ref4_text IS NOT NULL 
	OR glob_rec_arparms.ref5_text IS NOT NULL 
	OR glob_rec_arparms.ref6_text IS NOT NULL 
	OR glob_rec_arparms.ref7_text IS NOT NULL 
	OR glob_rec_arparms.ref8_text IS NOT NULL THEN 
		LET glob_show_rep_ind = true 
	ELSE 
		LET glob_show_rep_ind = false 
	END IF 

	--SELECT * INTO glob_rec_country.* 
	--FROM country 
	--WHERE country_code = glob_rec_company.country_code 

	--IF status = NOTFOUND THEN 
	--	ERROR kandoomsg2("U",5127,"") 
	--	#5127 " Country Code NOT SET up.
	--	LET l_msg = "Problem in INITIALIZE_globals(A-Modules - p_mode=", trim(p_mode), ",p_cust_code=", trim(p_cust_code) , ")\ncmpy=", trim(glob_rec_kandoouser.cmpy_code), "\nEXIT PROGRAM) #5127" 
	--	EXIT PROGRAM 
	--ELSE #I think, we no longer need this text for state and post code labels 
	--	LET l_temp_text = glob_rec_country.state_code_text clipped, 
	--	".................." 
	--	LET glob_rec_country.state_code_text = l_temp_text 
	--	LET l_temp_text = glob_rec_country.post_code_text clipped, 
	--	".................." 
	--	LET glob_rec_country.post_code_text = l_temp_text 
	--END IF 
	##
	## Code below sets up the customer global record
	##

	INITIALIZE glob_rec_customer.* TO NULL 

	IF p_mode = MODE_CLASSIC_ADD THEN 
		LET glob_rec_customer.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET glob_rec_customer.next_seq_num = 0 
		LET glob_rec_customer.currency_code = glob_rec_arparms.currency_code 
		LET glob_rec_customer.cred_limit_amt = glob_rec_arparms.cred_amt 
		LET glob_rec_customer.country_code = glob_rec_company.country_code 
		LET glob_rec_customer.language_code = glob_rec_company.language_code 
		LET glob_rec_customer.setup_date = today 
		LET glob_rec_customer.country_code = get_default_country_code() --glob_rec_country.country_text 
--@db-patch_2020_10_04--		LET glob_rec_customer.country_text = db_country_get_country_text(UI_OFF,get_default_country_code()) --glob_rec_country.country_text 
		LET glob_rec_customer.dun_code = "1" 
		LET glob_rec_customer.show_disc_flag = "N" 
		LET glob_rec_customer.partial_ship_flag = "Y" 

		IF glob_rec_arparms.consolidate_flag IS NULL THEN 
			LET glob_rec_arparms.consolidate_flag = "N" 
		END IF 

		LET glob_rec_customer.consolidate_flag = glob_rec_arparms.consolidate_flag 
		LET glob_rec_customer.share_flag = "N" 
		LET glob_rec_customer.int_chge_flag = "N" 
		LET glob_rec_customer.back_order_flag = "Y" 
		LET glob_rec_customer.ord_text_ind = "N" 
		LET glob_rec_customer.delete_flag = "N" 
		LET glob_rec_customer.delete_date = "" 
		LET glob_rec_customer.pay_ind = "1" 
		LET glob_rec_customer.inv_level_ind = "L" 
		LET glob_rec_customer.invoice_to_ind = "1" 
		LET glob_rec_customer.stmnt_ind = glob_rec_arparms.stmnt_ind 
		LET glob_rec_customer.inv_reqd_flag = "Y" 
		LET glob_rec_customer.cred_reqd_flag = "Y" 
		LET glob_rec_customer.inv_format_ind = "1" 
		LET glob_rec_customer.cred_format_ind = "1" 
		LET glob_rec_customer.mail_reqd_flag = "Y" 
		LET glob_rec_customer.curr_amt = 0 
		LET glob_rec_customer.highest_bal_amt = 0 
		LET glob_rec_customer.over1_amt = 0 
		LET glob_rec_customer.bal_amt = 0 
		LET glob_rec_customer.over30_amt = 0 
		LET glob_rec_customer.onorder_amt = 0 
		LET glob_rec_customer.over60_amt = 0 
		LET glob_rec_customer.over90_amt = 0 
		LET glob_rec_customer.avg_cred_day_num = 0 
		LET glob_rec_customer.hold_code = "" 
		LET glob_rec_customer.ytds_amt = 0 
		LET glob_rec_customer.mtds_amt = 0 
		LET glob_rec_customer.ytdp_amt = 0 
		LET glob_rec_customer.mtdp_amt = 0 
		LET glob_rec_customer.late_pay_num = 0 
		LET glob_rec_customer.cred_bal_amt = glob_rec_customer.cred_limit_amt 
		LET glob_rec_customer.last_mail_date = "" 
		LET glob_rec_customer.cred_override_ind = 0 
		LET modu_rec_custstmnt.stat_date = "" 
		LET modu_rec_custstmnt.bal_amt = "" 

		DELETE FROM t_customership WHERE 1=1 

	ELSE 

		CALL db_customer_get_rec(UI_OFF,p_cust_code) RETURNING glob_rec_customer.* 
		--SELECT * INTO glob_rec_customer.* 
		--FROM customer 
		--WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		--AND cust_code = p_cust_code 
		IF glob_rec_customer.cust_code IS NULL THEN
			ERROR kandoomsg2("U",7001,"Customer") #7001 Logic Error Cust RECORD Not Found
		END IF 
		##
		## In edit mode, initialise the country text AND prompts TO
		## match the customer country code, NOT the company.
		##

		--SELECT * INTO glob_rec_country.* 
		--FROM country 
		--WHERE country_code = glob_rec_customer.country_code 

		--IF status = NOTFOUND THEN 
		--	ERROR kandoomsg2("U",5127,"") 
		--	#5127 " Country Code NOT SET up.
		--ELSE 
		--	LET l_temp_text = glob_rec_country.state_code_text clipped, 
		--	".................." 
		--	LET glob_rec_country.state_code_text = l_temp_text 
		--	LET l_temp_text = glob_rec_country.post_code_text clipped, 
		--	".................." 
		--	LET glob_rec_country.post_code_text = l_temp_text 
		--END IF 

		IF glob_rec_customer.next_seq_num = 0 THEN 
			LET modu_rec_custstmnt.stat_date = "" 
			LET modu_rec_custstmnt.bal_amt = "" 
		ELSE 
			DECLARE c_custstmnt CURSOR FOR 
			SELECT * FROM custstmnt 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = glob_rec_customer.cust_code 
			ORDER BY cust_code,	stat_date desc 

			OPEN c_custstmnt 
			FETCH c_custstmnt INTO modu_rec_custstmnt.* 

			IF status = NOTFOUND THEN 
				LET modu_rec_custstmnt.stat_date = "" 
				LET modu_rec_custstmnt.bal_amt = "" 
			END IF 
		END IF 

	END IF 

	IF get_debug() = true THEN 
		DISPLAY "########### A-Modules - INITIALIZE_globals(p_mode,p_cust_code) 2 ################" 
		DISPLAY "p_mode=", p_mode 
		DISPLAY "p_cust_code=", p_cust_code 
		DISPLAY "END OF FUNCTION" 
		DISPLAY "----------------------------------------------------------------------" 
	END IF 

END FUNCTION 
############################################################
# END FUNCTION INITIALIZE_globals(p_mode,p_cust_code)
############################################################


############################################################
# FUNCTION customer_edit_1(p_mode)
#
# Edit customer address and contact info
############################################################
FUNCTION customer_edit_1(p_mode) 
	DEFINE p_mode CHAR(4) 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_customertype RECORD LIKE customertype.* 
	DEFINE l_rec_territory RECORD LIKE territory.* 
	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 
	DEFINE l_rec_suburb RECORD LIKE suburb.* 
	DEFINE l_rec_suburbarea RECORD LIKE suburbarea.* 
	DEFINE l_rec_street RECORD LIKE street.* 
	DEFINE l_rowid INTEGER 
	DEFINE l_locn_code LIKE location.locn_code 
	DEFINE l_ware_code LIKE warehouse.ware_code 
	DEFINE l_waregrp_code LIKE warehouse.waregrp_code 
	DEFINE l_temp_text STRING
	DEFINE l_temp_sales_person_terri_code LIKE salesperson.terri_code #for validation with territory purpose 
	
	SELECT locn_code INTO l_locn_code FROM userlocn 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND sign_on_code = glob_rec_kandoouser.sign_on_code 

	SELECT ware_code INTO l_ware_code FROM location 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND locn_code = l_locn_code 

	SELECT waregrp_code INTO l_waregrp_code FROM warehouse 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ware_code = l_ware_code 

	CLEAR FORM 

	IF trim(p_mode) = MODE_CLASSIC_ADD THEN  #HuHo 16.1.2020 - when creating new customers , it should not take existing data  .. move it over to the global init function
		--INITIALIZE glob_rec_customer.* TO NULL
		LET glob_rec_customer.country_code = get_default_country_code()
		LET glob_rec_customer.currency_code = get_default_currency_code()
		LET glob_rec_customer.cmpy_code = get_ku_cmpy_code() 
		LET glob_rec_customer.delete_flag = 'N'		
	END IF

	LET l_rec_customer.* = glob_rec_customer.* 
	
	MESSAGE kandoomsg2("U",1020,"Customer") #U1020 Enter Customer Details - ESC TO Continue
--@db-patch_2020_10_04-- 
{
	IF glob_rec_customer.country_code IS NOT NULL THEN 
		SELECT country_text INTO glob_rec_customer.country_text 
		FROM country 
		WHERE country_code = glob_rec_customer.country_code 

		IF status = NOTFOUND THEN 
			LET glob_rec_customer.country_text = "**********" 
		END IF 

		DISPLAY glob_rec_customer.country_text TO country_text

	END IF 
}
	IF glob_rec_customer.type_code IS NOT NULL THEN 
		SELECT * INTO l_rec_customertype.* 
		FROM customertype 
		WHERE type_code = glob_rec_customer.type_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 

		IF status = NOTFOUND THEN 
			LET l_rec_customertype.type_text = "**********" 
		END IF 

		DISPLAY l_rec_customertype.type_text TO type_text  

	END IF 

	IF glob_rec_customer.territory_code IS NOT NULL THEN 
		SELECT * INTO l_rec_territory.* 
		FROM territory 
		WHERE terr_code = glob_rec_customer.territory_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 

		IF status = NOTFOUND THEN 
			LET l_rec_territory.desc_text = "**********" 
		END IF 

		DISPLAY l_rec_territory.desc_text TO territory.desc_text 

	END IF 

	#get sales person record	 
	CALL db_salesperson_get_rec(UI_OFF,glob_rec_customer.sale_code) RETURNING l_rec_salesperson.*
	IF l_rec_salesperson.sale_code IS NULL THEN
		LET l_rec_salesperson.name_text = "**********"
	END IF

	DISPLAY l_rec_salesperson.name_text TO salesperson.name_text 

	--CALL db_country_localize(glob_rec_customer.country_code) #Localize
	INPUT BY NAME 
		glob_rec_customer.cust_code, 
		glob_rec_customer.name_text, 
		glob_rec_customer.addr1_text, 
		glob_rec_customer.addr2_text, 
		glob_rec_customer.city_text, 
		glob_rec_customer.state_code, 
		glob_rec_customer.post_code, 
		glob_rec_customer.country_code, 
		glob_rec_customer.contact_text, 
		glob_rec_customer.tele_text, 
		glob_rec_customer.fax_text,
		glob_rec_customer.mobile_phone,
		glob_rec_customer.email, 
		glob_rec_customer.comment_text, 
		glob_rec_customer.vat_code, 
		glob_rec_customer.registration_num, 
		glob_rec_customer.type_code, 
		glob_rec_customer.currency_code, 
		glob_rec_customer.territory_code, 
		glob_rec_customer.sale_code WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED) 


		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A11","input-customer-1")
			CALL db_country_localize(glob_rec_customer.country_code) #Localize			 
			DISPLAY db_currency_get_desc_text(UI_OFF,glob_rec_customer.currency_code) TO currency.desc_text

		ON CHANGE country_code 
			CALL db_country_localize(glob_rec_customer.country_code) #Localize

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (addr2_text) 
			LET l_rowid = show_wstreet(glob_rec_kandoouser.cmpy_code) 

			IF l_rowid != 0 THEN 
				SELECT * INTO l_rec_street.* FROM street 
				WHERE rowid = l_rowid 

				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("W",9005,"") #9005 Logic error: Street name NOT found"
					NEXT FIELD addr2_text 
				END IF 

				SELECT * INTO l_rec_suburb.* FROM suburb 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND suburb_code = l_rec_street.suburb_code 

				LET glob_rec_customer.addr2_text = l_rec_street.street_text clipped, 
				" ", l_rec_street.st_type_text 
				LET glob_rec_customer.city_text = l_rec_suburb.suburb_text 
				LET glob_rec_customer.state_code = l_rec_suburb.state_code 
				LET glob_rec_customer.post_code = l_rec_suburb.post_code 
				#Default the salesperson code IF NOT already entered.

				SELECT * INTO l_rec_suburbarea.* FROM suburbarea 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND suburb_code = l_rec_street.suburb_code 
				AND waregrp_code = l_waregrp_code 

				LET glob_rec_customer.territory_code = l_rec_suburbarea.terr_code 

				SELECT sale_code INTO l_rec_territory.sale_code 
				FROM territory 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND terr_code = l_rec_suburbarea.terr_code 

				LET glob_rec_customer.sale_code = l_rec_territory.sale_code 

				IF glob_rec_customer.sale_code IS NULL THEN 
					LET glob_rec_customer.sale_code = l_rec_suburbarea.sale_code 
				END IF 

				CALL db_salesperson_get_name_text(UI_OFF,glob_rec_customer.sale_code) RETURNING l_rec_salesperson.name_text 

				DISPLAY BY NAME 
					glob_rec_customer.city_text, 
					glob_rec_customer.state_code, 
					glob_rec_customer.post_code, 
					glob_rec_customer.sale_code, 
					glob_rec_customer.name_text 

			END IF 

			NEXT FIELD addr2_text 


		ON ACTION "LOOKUP" infield (city_text) 
			LET l_rec_suburb.suburb_code = show_wsub(glob_rec_kandoouser.cmpy_code) 

			IF l_rec_suburb.suburb_code != 0 THEN 

				SELECT * INTO l_rec_suburb.* FROM suburb 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND suburb_code = l_rec_suburb.suburb_code 

				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("W",9006,"") 	#9006 Logic error: Suburb NOT found"
					NEXT FIELD city_text 
				END IF 

				SELECT * INTO l_rec_suburbarea.* FROM suburbarea 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND suburb_code = l_rec_suburb.suburb_code 
				AND waregrp_code = l_waregrp_code 

				LET glob_rec_customer.city_text = l_rec_suburb.suburb_text 
				LET glob_rec_customer.state_code = l_rec_suburb.state_code 
				LET glob_rec_customer.post_code = l_rec_suburb.post_code 
				LET glob_rec_customer.territory_code = l_rec_suburbarea.terr_code 

				INITIALIZE l_rec_territory.* TO NULL 

				SELECT * INTO l_rec_territory.* FROM territory 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND terr_code = glob_rec_customer.territory_code 

				LET glob_rec_customer.sale_code = l_rec_territory.sale_code 

				IF glob_rec_customer.sale_code IS NULL THEN 
					LET glob_rec_customer.sale_code = l_rec_suburbarea.sale_code 
				END IF 

				IF glob_rec_customer.sale_code IS NOT NULL THEN 
					INITIALIZE l_rec_salesperson.* TO NULL
					CALL db_salesperson_get_name_text(UI_OFF,glob_rec_customer.sale_code) RETURNING l_rec_salesperson.name_text  
				END IF 

				DISPLAY BY NAME 
					glob_rec_customer.city_text, 
					glob_rec_customer.state_code, 
					glob_rec_customer.post_code, 
					glob_rec_customer.territory_code, 
					glob_rec_customer.sale_code, 
					glob_rec_customer.name_text 

				DISPLAY l_rec_territory.desc_text TO territory.desc_text 
				DISPLAY glob_rec_customer.sale_code TO customer.sale_code 
				DISPLAY l_rec_salesperson.name_text TO salesperson.name_text 
		
			END IF 


		ON ACTION "LOOKUP" infield (country_code) 
			LET l_temp_text = show_country() 
			IF l_temp_text IS NOT NULL THEN 
				LET glob_rec_customer.country_code = l_temp_text 
				NEXT FIELD country_code 
			END IF 

		ON ACTION "LOOKUP" infield (type_code) 
			LET l_temp_text = show_ctyp(glob_rec_kandoouser.cmpy_code) 

			IF l_temp_text IS NOT NULL THEN 
				LET glob_rec_customer.type_code = l_temp_text 
				NEXT FIELD type_code 
			END IF 

		ON ACTION "LOOKUP" infield (currency_code) 
			LET l_temp_text = show_curr(glob_rec_kandoouser.cmpy_code) 

			IF l_temp_text IS NOT NULL THEN 
				LET glob_rec_customer.currency_code = l_temp_text 
				NEXT FIELD currency_code 
			END IF 

		ON ACTION "LOOKUP" infield (territory_code) 
			LET l_temp_text = show_territory(glob_rec_kandoouser.cmpy_code,"") 

			IF l_temp_text IS NOT NULL THEN 
				LET glob_rec_customer.territory_code = l_temp_text 
				NEXT FIELD territory_code 
			END IF 

		ON ACTION "LOOKUP" infield (sale_code) 
			LET l_temp_text = show_sale(glob_rec_kandoouser.cmpy_code) 

			IF l_temp_text IS NOT NULL THEN 
				LET glob_rec_customer.sale_code = l_temp_text 
				NEXT FIELD sale_code 
			END IF 


		BEFORE FIELD cust_code 
			IF p_mode = MODE_CLASSIC_EDIT OR modu_auto_cust_ind THEN 
				NEXT FIELD NEXT 
			END IF 

		AFTER FIELD cust_code 
			IF glob_rec_customer.cust_code IS NOT NULL THEN 
				SELECT unique 1 FROM customer 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = glob_rec_customer.cust_code 
				IF status = 0 THEN
					ERROR kandoomsg2("A",9025,"") #9025" The Customer Code already exists - Try Again"
--					ERROR kandoomsg2("A",9025,"") 
--					#9025" The Customer Code already exists - Try Again"
					NEXT FIELD cust_code 
				END IF 
			ELSE
			
			END IF 



		AFTER FIELD country_code 
			#CLEAR country_text

			IF glob_rec_customer.country_code IS NOT NULL THEN 
				IF NOT db_country_pk_exists(UI_FK,NULL,glob_rec_customer.country_code) THEN
					NEXT FIELD country_code
				END IF
				--SELECT * INTO glob_rec_country.* 
				--FROM country 
				--WHERE country_code = glob_rec_customer.country_code 

				--IF status = NOTFOUND THEN 
				--	ERROR kandoomsg2("A",9047,"") 
				--	#9047 " Country code NOT found -  try window "
				--	NEXT FIELD country_code 
				--END IF 

			END IF 

		ON CHANGE type_code
			DISPLAY db_customertype_get_type_text(UI_OFF,glob_rec_customer.type_code) TO customer.type_text
					
		AFTER FIELD type_code 
			CLEAR customertype.type_text 

			IF glob_rec_customer.type_code IS NOT NULL THEN 
				SELECT * INTO l_rec_customertype.* 
				FROM customertype 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND type_code = glob_rec_customer.type_code 

				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("A",9030,"") 
					#9030 " Customer Type NOT found - try window"
					NEXT FIELD type_code 
				ELSE 
					DISPLAY l_rec_customertype.type_text TO type_text 
				END IF 

			END IF 
			
		ON CHANGE currency_code
			DISPLAY db_currency_get_desc_text(UI_OFF,glob_rec_customer.currency_code) TO currency.desc_text
			 
		BEFORE FIELD currency_code 
			## Cannot change currency IF any transactions exist
			IF glob_rec_customer.next_seq_num > 0 THEN 
				IF NOT get_is_screen_navigation_forward() THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 

		AFTER FIELD currency_code 
			IF glob_rec_customer.currency_code IS NOT NULL THEN 
				SELECT unique 1 FROM currency 
				WHERE currency_code = glob_rec_customer.currency_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("A",9057,"") #9057" Currency NOT found, try window"
					NEXT FIELD currency_code 
				END IF 
			END IF 

		ON CHANGE territory_code
			DISPLAY l_rec_territory.desc_text TO territory.desc_text
				
		AFTER FIELD territory_code 
			--CLEAR territory.desc_text 

			IF glob_rec_customer.territory_code IS NOT NULL THEN 
				SELECT * INTO l_rec_territory.* 
				FROM territory 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND terr_code = glob_rec_customer.territory_code 

				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("A",9084,"")	#9084 " territory NOT found - try window"
					NEXT FIELD territory_code 
				END IF 

				IF l_rec_territory.sale_code IS NOT NULL THEN 
					LET glob_rec_customer.sale_code = l_rec_territory.sale_code 
				END IF 

				DISPLAY l_rec_territory.desc_text TO territory.desc_text 
				DISPLAY glob_rec_customer.sale_code TO customer.sale_code 
			END IF 

		ON CHANGE sale_code
			LET l_rec_salesperson.name_text = db_salesperson_get_name_text(UI_OFF,glob_rec_customer.sale_code)
			DISPLAY l_rec_salesperson.name_text TO salesperson.name_text
			
		AFTER FIELD sale_code 
			--CLEAR salesperson.name_text 

			IF glob_rec_customer.sale_code IS NOT NULL THEN
				IF db_salesperson_pk_exists(UI_FK,MODE_UPDATE,glob_rec_customer.sale_code) THEN
					LET l_temp_sales_person_terri_code = db_salesperson_get_terri_code(UI_OFF,glob_rec_customer.sale_code)
					IF ((l_temp_sales_person_terri_code != glob_rec_customer.territory_code)
						AND (l_temp_sales_person_terri_code IS NOT NULL)) THEN
						ERROR "Sales Person is not allowed to sell in this territory"
						LET glob_rec_customer.sale_code = NULL  #Reset value
						NEXT FIELD sale_code
					ELSE
						--LET glob_rec_customer.territory_code = db_salesperson_get_terri_code(UI_OFF,glob_rec_customer.sale_code) 
						--DISPLAY glob_rec_customer.territory_code TO customer.territory_code
						DISPLAY db_salesperson_get_name_text(UI_OFF,glob_rec_customer.sale_code) TO salesperson.name_text
					END IF
				--ELSE #Is a customer dedicated sales person really a must have requirement ???
				--	NEXT FIELD sale_code					
				END IF 
			END IF 
--				SELECT * INTO l_rec_salesperson.* 
--				FROM salesperson 
--				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
--				AND sale_code = glob_rec_customer.sale_code 

--				IF status = NOTFOUND THEN 
--					ERROR kandoomsg2("A",9032,"") 
--					#9032 " Salesperson NOT found - try window"
--					NEXT FIELD sale_code 
--				END IF 

--				IF l_rec_salesperson.terri_code IS NOT NULL THEN 
--					LET glob_rec_customer.territory_code = l_rec_salesperson.terri_code 
--				END IF 

		AFTER FIELD vat_code --vat registration number - needs TO be localized 
			IF glob_rec_customer.vat_code IS NOT NULL THEN
				IF NOT validate_vat_registration_code(glob_rec_customer.vat_code,glob_rec_customer.country_code) THEN 
					ERROR kandoomsg2("G",9538,"") #Invalid ABN. Enter valid ABN OR leave blank
					NEXT FIELD vat_code 
				END IF 

				IF p_mode = MODE_CLASSIC_ADD THEN 
					DECLARE c_abn CURSOR FOR 
					SELECT * FROM customer 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND vat_code = glob_rec_customer.vat_code 
					OPEN c_abn 
					FETCH c_abn 
				ELSE 
					DECLARE c_abn2 CURSOR FOR 
					SELECT * FROM customer 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cust_code != glob_rec_customer.cust_code 
					AND vat_code = glob_rec_customer.vat_code 
					OPEN c_abn2 
					FETCH c_abn2 
				END IF 

				IF status != NOTFOUND THEN 
					ERROR kandoomsg2("G",9609,"")					#9609 ABN already exists.
					NEXT FIELD vat_code 
				END IF 

			END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF not(p_mode = MODE_CLASSIC_EDIT OR modu_auto_cust_ind) THEN 
					IF glob_rec_customer.cust_code IS NULL THEN 
						ERROR kandoomsg2("A",9024,"")						#9024 " Customer Code must be entered "
						NEXT FIELD cust_code 
					END IF 
				END IF 

				IF glob_rec_customer.country_code IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") 					#9024 " Value must be entered "
					NEXT FIELD country_code 
				END IF 

				IF glob_rec_customer.type_code IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") 			#9024 " Value must be entered "
					NEXT FIELD type_code 
				END IF 

				IF glob_rec_customer.currency_code IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") 				#9024 " Value must be entered "
					NEXT FIELD currency_code 
				END IF 

--#{ #alch 05.05.2020 - KD-1784: Sales Territory and Salesperson should be optional
				IF glob_rec_customer.territory_code IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") 
					#9024 " Value must be entered "
					NEXT FIELD territory_code 
				END IF 

				IF glob_rec_customer.sale_code IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") 
					#9024 " Value must be entered "
					NEXT FIELD sale_code 
				END IF 
--#}
				IF (l_rec_territory.sale_code IS NOT NULL AND 
				l_rec_territory.sale_code != l_rec_salesperson.sale_code) 
				OR (l_rec_salesperson.terri_code IS NOT NULL AND 
				l_rec_territory.terr_code != l_rec_salesperson.terri_code) THEN 
					ERROR kandoomsg2("A",7043,"") 				#7043 " Salesperson Terri SET up IS invalid
					NEXT FIELD territory_code 
				END IF 

			ELSE 

				IF p_mode = MODE_CLASSIC_ADD THEN 
					IF glob_rec_customer.cust_code IS NOT NULL THEN 						
						IF kandooDialog2("A",8004,"") = "N" THEN #8004 Do you wish TO quit(Y/N)
							CONTINUE INPUT 
						END IF
					END IF 
				END IF 
				LET quit_flag = true 
			END IF 

	END INPUT 
	###############################

	IF int_flag OR quit_flag THEN 
		LET glob_rec_customer.* = l_rec_customer.* 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 
############################################################
# END FUNCTION customer_edit_1(p_mode)
############################################################


############################################################
# FUNCTION customer_edit_2()
#
#
############################################################
FUNCTION customer_edit_2() 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_term RECORD LIKE term.* 
	DEFINE l_rec_tax RECORD LIKE tax.* 
	DEFINE l_rec_condsale RECORD LIKE condsale.* 
	#DEFINE l_rec_stateinfo RECORD LIKE stateinfo.* #not used
	DEFINE l_temp_text STRING

	LET l_rec_customer.* = glob_rec_customer.* 

	OPEN WINDOW A607 with FORM "A607" 
	CALL windecoration_a("A607") 

	MESSAGE kandoomsg2("U",1020,"Customer Parameters")	#U1020 Enter Customer Details - ESC TO Continue

	IF glob_rec_customer.cond_code IS NOT NULL THEN 
		SELECT * INTO l_rec_condsale.* 
		FROM condsale 
		WHERE cond_code = glob_rec_customer.cond_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF status = NOTFOUND THEN 
			LET l_rec_condsale.desc_text = "**********" 
		END IF 

		DISPLAY l_rec_condsale.desc_text TO condsale.desc_text 

	END IF 

	IF glob_rec_customer.tax_code IS NOT NULL THEN 
		SELECT * INTO l_rec_tax.* 
		FROM tax 
		WHERE tax_code = glob_rec_customer.tax_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 

		IF status = NOTFOUND THEN 
			LET l_rec_tax.desc_text = "**********" 
		END IF 

		DISPLAY l_rec_tax.desc_text TO tax.desc_text 

	END IF 

	IF glob_rec_customer.term_code IS NOT NULL THEN 
		SELECT * INTO l_rec_term.* 
		FROM term 
		WHERE term_code = glob_rec_customer.term_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 

		IF status = NOTFOUND THEN 
			LET l_rec_term.desc_text = "**********" 
		END IF 

		DISPLAY l_rec_term.desc_text TO term.desc_text 

	END IF 

	############################################
	INPUT BY NAME glob_rec_customer.inv_level_ind, 
	glob_rec_customer.cond_code, 
	glob_rec_customer.tax_code, 
	glob_rec_customer.tax_num_text, 
	glob_rec_customer.last_mail_date, 
	glob_rec_customer.pay_ind, 
	glob_rec_customer.term_code, 
	glob_rec_customer.bank_acct_code, 
	--glob_rec_customer.stmnt_ind,
	--modu_rec_custstmnt.stat_date,
	--modu_rec_custstmnt.bal_amt,
	--glob_rec_customer.dun_code,
	glob_rec_customer.invoice_to_ind, 
	glob_rec_customer.ord_text_ind, 
	glob_rec_customer.consolidate_flag, 
	glob_rec_customer.back_order_flag, 
	glob_rec_customer.partial_ship_flag, 
	glob_rec_customer.share_flag WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED) 


		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A11","input-customer-2") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (cond_code) 
			LET l_temp_text = show_cond(glob_rec_kandoouser.cmpy_code,"") 
			
			IF l_temp_text IS NOT NULL THEN 
				LET glob_rec_customer.cond_code = l_temp_text 
				NEXT FIELD cond_code 
			END IF 
			
			CALL combolist_salescondition ("cond_code", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 



		ON ACTION "LOOKUP" infield (tax_code) 
			LET l_temp_text = show_tax(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET glob_rec_customer.tax_code = l_temp_text 
				NEXT FIELD tax_code 
			END IF 
			CALL combolist_tax_code ("tax_code", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 


		ON ACTION "LOOKUP" infield (term_code) 
			LET l_temp_text = show_term(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET glob_rec_customer.term_code = l_temp_text 
				NEXT FIELD term_code 
			END IF 
			CALL combolist_termcode ("term_code", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 



		AFTER FIELD cond_code 
			CLEAR condsale.desc_text 

			IF glob_rec_customer.cond_code IS NOT NULL THEN 
				#- D. Seguin / 2019-11-17 / Bud issue #kandooERP-108 - in order to prevent sub query error added a distinct key word on the sql statement
				SELECT distinct desc_text INTO l_rec_condsale.desc_text 
				FROM condsale 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cond_code = glob_rec_customer.cond_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("A",9078,"") #9078" Sales condition code does NOT exist - Try Window"
					NEXT FIELD cond_code 
				ELSE 
					DISPLAY l_rec_condsale.desc_text TO desc_text 

				END IF 
			END IF 

		AFTER FIELD tax_code 
			CLEAR tax.desc_text 

			IF glob_rec_customer.tax_code IS NOT NULL THEN 
				SELECT desc_text INTO l_rec_tax.desc_text 
				FROM tax 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND tax_code = glob_rec_customer.tax_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("A",9036,"") #9036 " Tax Code NOT found, try window"
					NEXT FIELD tax_code 
				ELSE 
					DISPLAY l_rec_tax.desc_text TO tax.desc_text 

				END IF 
			END IF 

		AFTER FIELD term_code 
			CLEAR term.desc_text 

			IF glob_rec_customer.term_code IS NOT NULL THEN 
				SELECT desc_text INTO l_rec_term.desc_text 
				FROM term 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND term_code = glob_rec_customer.term_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("A",9034,"") #9034 " Term Code NOT found - use window"
					NEXT FIELD term_code 
				ELSE 
					DISPLAY l_rec_term.desc_text TO term.desc_text 

				END IF 
			END IF 


		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF glob_rec_customer.tax_code IS NULL THEN 
					ERROR kandoomsg2("A",9035,"") #9035 " Must enter tax code, try window"
					NEXT FIELD tax_code 
				END IF 
				IF glob_rec_customer.term_code IS NULL THEN 
					ERROR kandoomsg2("A",9033,"") #9033 " Customer payment terms must be entered "
					NEXT FIELD term_code 
				END IF 
			END IF 

	END INPUT 

	CLOSE WINDOW A607 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET glob_rec_customer.* = l_rec_customer.* 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 

END FUNCTION 
############################################################
# END FUNCTION customer_edit_2()
############################################################


############################################################
# FUNCTION customer_edit_3(p_mode)
#
#
############################################################
FUNCTION customer_edit_3(p_mode) 
	DEFINE p_mode CHAR(4) 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_holdreas RECORD LIKE holdreas.* 
	DEFINE l_prev_hold_code2 LIKE customer.hold_code 
	DEFINE l_update_order_hold2 SMALLINT 
	DEFINE l_used_window SMALLINT 
	DEFINE l_temp_text STRING

	LET l_prev_hold_code2 = modu_prev_hold_code 
	LET l_update_order_hold2 = glob_update_order_hold 
	LET l_rec_customer.* = glob_rec_customer.* 

	#init some decimal values in case there are NULL
	IF glob_rec_customer.curr_amt IS NULL THEN
		LET glob_rec_customer.curr_amt = 0
	END IF

	IF glob_rec_customer.cred_bal_amt IS NULL THEN
		LET glob_rec_customer.curr_amt = 0
	END IF

	IF glob_rec_customer.bal_amt IS NULL THEN
		LET glob_rec_customer.cred_bal_amt = 0
	END IF

	IF glob_rec_customer.onorder_amt IS NULL THEN
		LET glob_rec_customer.onorder_amt = 0
	END IF

	OPEN WINDOW A108 with FORM "A108" 
	CALL windecoration_a("A108") 

	MESSAGE kandoomsg2("A",1012,"")	#1012 Enter Customer credit details - ESC TO Continue

	LET glob_rec_customer.cred_bal_amt = glob_rec_customer.cred_limit_amt 
	- glob_rec_customer.bal_amt 
	- glob_rec_customer.onorder_amt 

	IF glob_rec_customer.hold_code IS NOT NULL THEN 
		SELECT * INTO l_rec_holdreas.* 
		FROM holdreas 
		WHERE hold_code = glob_rec_customer.hold_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF status = NOTFOUND THEN 
			LET l_rec_holdreas.reason_text = "**********" 
		END IF 
	END IF 

	DISPLAY BY NAME 
		glob_rec_customer.cust_code, 
		glob_rec_customer.name_text, 
		glob_rec_customer.curr_amt, 
		glob_rec_customer.over1_amt, 
		glob_rec_customer.over30_amt, 
		glob_rec_customer.over60_amt, 
		glob_rec_customer.over90_amt, 
		glob_rec_customer.bal_amt, 
		glob_rec_customer.cred_limit_amt, 
		glob_rec_customer.onorder_amt, 
		glob_rec_customer.cred_bal_amt, 
		glob_rec_customer.avg_cred_day_num, 
		glob_rec_customer.highest_bal_amt, 
		glob_rec_customer.ytds_amt, 
		glob_rec_customer.ytdp_amt, 
		glob_rec_customer.late_pay_num, 
		glob_rec_customer.setup_date, 
		modu_rec_custstmnt.stat_date 
	
	DISPLAY l_rec_holdreas.reason_text TO reason_text
	DISPLAY glob_rec_customer.bal_amt TO balance_amt 

	DISPLAY BY NAME glob_rec_customer.currency_code #HuHo: attribute(GREEN) #why with color / green ? I'll remove it
	LET l_used_window = false 

	INPUT BY NAME 
		glob_rec_customer.hold_code, 
		glob_rec_customer.int_chge_flag, 
		glob_rec_customer.cred_override_ind, 
		glob_rec_customer.cred_limit_amt WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED) 


		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A11","input-customer-3") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (hold_code) 
			LET l_temp_text = show_hold(glob_rec_kandoouser.cmpy_code,"") 
			IF l_temp_text IS NOT NULL THEN 
				LET glob_rec_customer.hold_code = l_temp_text 
				LET l_used_window = true 
				NEXT FIELD hold_code 
			END IF 

		BEFORE FIELD hold_code 
			IF NOT l_used_window THEN 
				LET modu_prev_hold_code = glob_rec_customer.hold_code 
			END IF 

			LET l_used_window = false 

		AFTER FIELD hold_code 
			INITIALIZE l_rec_holdreas.* TO NULL 

			IF glob_rec_customer.hold_code IS NOT NULL THEN 
				SELECT reason_text INTO l_rec_holdreas.reason_text 
				FROM holdreas 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND hold_code = glob_rec_customer.hold_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("A",9040,"")					#9040 Hold code NOT found try window
					NEXT FIELD hold_code 
				END IF 

			END IF 

			DISPLAY l_rec_holdreas.reason_text TO reason_text

			IF p_mode = MODE_CLASSIC_EDIT THEN 
				IF modu_prev_hold_code IS NULL THEN 
					IF glob_rec_customer.hold_code IS NOT NULL THEN 
						IF promptTF("Confirm", kandoomsg2("A",8040,""),1) THEN  		#8040 Confirm TO place all non-held orders on hold
							LET glob_update_order_hold = true 
						ELSE 
							LET glob_update_order_hold = false 
						END IF 
					END IF 
				ELSE 
					IF glob_rec_customer.hold_code IS NULL THEN 
						IF promptTF("Confirm", kandoomsg2("A",8041,""),1) THEN  	#8041 Confirm TO release all orders FROM hold
							LET glob_update_order_hold = true 
						ELSE 
							LET glob_update_order_hold = false 
						END IF 
					END IF 
				END IF 

				MESSAGE kandoomsg2("A",1012,"")		#1012 Enter Customer credit details - ESC TO Continue
			END IF 

		AFTER FIELD cred_override_ind 
			IF glob_rec_customer.cred_override_ind IS NULL THEN 
				ERROR kandoomsg2("U",9102,"")			#9102 value must be entered
				NEXT FIELD cred_override_ind 
			END IF 

		AFTER FIELD cred_limit_amt 
			IF glob_rec_customer.cred_limit_amt IS NULL THEN 
				LET glob_rec_customer.cred_limit_amt = 0 
				NEXT FIELD cred_limit_amt 
			END IF 

			IF glob_rec_customer.cred_limit_amt < 0 THEN 				
				ERROR kandoomsg2("A",9039,"") #9039 credit limit cant be negative
				NEXT FIELD cred_limit_amt 
			END IF 

			LET glob_rec_customer.cred_bal_amt = glob_rec_customer.cred_limit_amt 
			- glob_rec_customer.bal_amt 
			- glob_rec_customer.onorder_amt 
			DISPLAY BY NAME glob_rec_customer.cred_bal_amt 


	END INPUT 

	CLOSE WINDOW A108 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET glob_rec_customer.* = l_rec_customer.* 
		LET modu_prev_hold_code = l_prev_hold_code2 
		LET glob_update_order_hold = l_update_order_hold2 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 
############################################################
# END FUNCTION customer_edit_3(p_mode)
############################################################


############################################################
# FUNCTION customer_edit_4()
#
#
############################################################
FUNCTION customer_edit_4() 
	DEFINE l_rec_customership RECORD LIKE customership.* 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_rec_carrier RECORD LIKE carrier.* 
	DEFINE l_temp_text STRING

	OPEN WINDOW A206 with FORM "A206" 
	CALL windecoration_a("A206") 

	SELECT unique 1 FROM t_customership 

	IF status = NOTFOUND THEN 
		LET l_rec_customership.cust_code = glob_rec_customer.cust_code
		LET l_rec_customership.ship_code = glob_rec_customer.cust_code 
		LET l_rec_customership.addr_text = glob_rec_customer.addr1_text 
		LET l_rec_customership.addr2_text= glob_rec_customer.addr2_text 
		LET l_rec_customership.city_text = glob_rec_customer.city_text 
		LET l_rec_customership.state_code= glob_rec_customer.state_code 
		LET l_rec_customership.post_code = glob_rec_customer.post_code 
		LET l_rec_customership.country_code = glob_rec_customer.country_code --@db-patch_2020_10_04-- 
		LET l_rec_customership.contact_text = glob_rec_customer.contact_text 
		LET l_rec_customership.tele_text = glob_rec_customer.tele_text 
		LET l_rec_customership.mobile_phone = glob_rec_customer.mobile_phone 
		LET l_rec_customership.email = glob_rec_customer.email
		
		DISPLAY glob_rec_customer.cust_code TO cust_code
		DISPLAY l_rec_customership.ship_code TO ship_code
		DISPLAY l_rec_customership.addr_text TO addr_text
		DISPLAY l_rec_customership.addr2_text TO addr2_text
		DISPLAY l_rec_customership.city_text TO city_text
		DISPLAY l_rec_customership.state_code TO state_code
		DISPLAY l_rec_customership.post_code TO post_code
		DISPLAY l_rec_customership.country_code TO country_code --@db-patch_2020_10_04-- 
		DISPLAY l_rec_customership.contact_text TO contact_text
		DISPLAY l_rec_customership.tele_text TO tele_text
		DISPLAY l_rec_customership.mobile_phone TO mobile_phone
		DISPLAY l_rec_customership.email TO email
		DISPLAY l_rec_customership.ware_code TO ware_code
		DISPLAY l_rec_customership.ship1_text TO ship1_text
		DISPLAY l_rec_customership.ship2_text TO ship2_text 

	END IF 

	LET l_rec_customership.cust_code = glob_rec_customer.cust_code 
	LET l_rec_customership.name_text = glob_rec_customer.name_text

--	DISPLAY l_rec_customership.cust_code TO customership.cust_code  
--	DISPLAY glob_rec_customer.name_text TO cust_text  
--	DISPLAY l_rec_customership.ship_code TO customership.ship_code 

	#Display localized names for state/county/oblast and ZIP/post code, Postleitzahl
	CALL db_country_localize(glob_rec_customer.country_code) #Localize
	--DISPLAY db_country_get_state_code_text(l_rec_customership.country_text) TO lb_state_code_text
	--DISPLAY db_country_get_post_code_text(l_rec_customership.country_text) TO lb_post_code_text

	INPUT BY NAME l_rec_customership.ship_code, 
	l_rec_customership.name_text, 
	l_rec_customership.addr_text, 
	l_rec_customership.addr2_text, 
	l_rec_customership.city_text, 
	l_rec_customership.state_code, 
	l_rec_customership.post_code, 
	l_rec_customership.country_code, --@db-patch_2020_10_04--
	l_rec_customership.contact_text, 
	l_rec_customership.tele_text, 
	l_rec_customership.mobile_phone, 
	l_rec_customership.email, 
	l_rec_customership.ware_code, 
	l_rec_customership.carrier_code, 
	l_rec_customership.freight_ind, 
	l_rec_customership.ship1_text, 
	l_rec_customership.ship2_text WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED) 


		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A11","input-customership") 
			CALL db_country_localize(l_rec_customership.country_code) --@db-patch_2020_10_04-- #Localize
			DISPLAY l_rec_customership.cust_code TO customership.cust_code  
			DISPLAY glob_rec_customer.name_text TO cust_text  
			DISPLAY l_rec_customership.ship_code TO customership.ship_code 

		ON CHANGE country_text 
			CALL db_country_localize(l_rec_customership.country_code) --@db-patch_2020_10_04-- #Localize
	
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
	
		ON ACTION "LOOKUP" infield (ware_code) 
			LET l_temp_text = show_ware(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_customership.ware_code = l_temp_text 
				NEXT FIELD ware_code 
			END IF 
			CALL combolist_warehouse ("ware_code", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 

		ON ACTION "LOOKUP" infield (carrier_code) 
			LET l_temp_text = show_carrier(glob_rec_kandoouser.cmpy_code,"") 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_customership.carrier_code = l_temp_text 
				NEXT FIELD carrier_code 
			END IF 


		AFTER FIELD ship_code 
			IF l_rec_customership.ship_code IS NULL THEN 
				ERROR kandoomsg2("A",9028,"") 
				#9028 " Must enter a Shipping code "
				NEXT FIELD ship_code 
			ELSE 
				SELECT unique 1 FROM t_customership 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = glob_rec_customer.cust_code 
				AND ship_code = l_rec_customership.ship_code 

				IF status = 0 THEN 
					ERROR kandoomsg2("A",9026,"") 
					#9026 " This Shipping ID has already been used"
					NEXT FIELD ship_code 
				END IF 

			END IF 

		AFTER FIELD ware_code 
			IF l_rec_customership.ware_code IS NOT NULL THEN #huho doc states, warehouse is optional
				SELECT desc_text INTO l_rec_warehouse.desc_text 
				FROM warehouse 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = l_rec_customership.ware_code 
	
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("A",9041,"") 
					#9041" Warehouse code NOT found - Try Window"
					CLEAR warehouse.desc_text 
					NEXT FIELD ware_code 
				ELSE 
					DISPLAY l_rec_warehouse.desc_text TO warehouse.desc_text 
	
				END IF 
			END IF
		AFTER FIELD carrier_code 
			IF l_rec_customership.carrier_code IS NOT NULL THEN 
				SELECT name_text INTO l_rec_carrier.name_text FROM carrier 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND carrier_code = l_rec_customership.carrier_code 

				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("A",9042,"") 
					#9042" Carrier code NOT found - Try Window"
					CLEAR carrier_text 
					NEXT FIELD carrier_code 
				ELSE 
					DISPLAY l_rec_carrier.name_text TO carrier_text 

				END IF 

			END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				SELECT desc_text INTO l_rec_warehouse.desc_text FROM warehouse 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = l_rec_customership.ware_code 

				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("A",9041,"") 
					#9041" Warehouse code NOT found - Try Window"
					NEXT FIELD ware_code 
				END IF 

				IF l_rec_customership.carrier_code IS NOT NULL 
				AND l_rec_customership.freight_ind IS NULL THEN 
					ERROR kandoomsg2("A",9059,"") 
					#9059" Freight rate level must be entered FOR Carrier"
					NEXT FIELD freight_ind 
				END IF 
			END IF 


	END INPUT 
	###############################

	CLOSE WINDOW Aa206 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 
		LET l_rec_customership.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_rec_customership.cust_code = glob_rec_customer.cust_code 
		INSERT INTO t_customership VALUES (l_rec_customership.*) 
	END IF 
END FUNCTION 
############################################################
# END FUNCTION customer_edit_4()
############################################################


############################################################
# FUNCTION customer_edit_5()
#
#
############################################################
FUNCTION customer_edit_5() 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_corpcust RECORD LIKE customer.* 
	DEFINE l_temp_text STRING

	LET l_rec_customer.* = glob_rec_customer.* 

	OPEN WINDOW A205a with FORM "A205a" 
	CALL windecoration_a("A205a") 

	MESSAGE kandoomsg2("U",1020,"Customer") #U1020 Enter Customer Details - ESC TO Continue
	INPUT BY NAME 
		glob_rec_customer.corp_cust_code, 
		glob_rec_customer.corp_cust_ind, 
		glob_rec_customer.sales_anly_flag, 
		glob_rec_customer.inv_addr_flag, 
		glob_rec_customer.credit_chk_flag WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A11","input-customer-4") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (corp_cust_code) 
			LET l_temp_text = show_clnt(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET glob_rec_customer.corp_cust_code = l_temp_text 
				NEXT FIELD corp_cust_code 
			END IF 

		AFTER FIELD corp_cust_code 
			IF glob_rec_customer.corp_cust_code IS NULL THEN 
				LET glob_rec_customer.inv_addr_flag = NULL 
				LET glob_rec_customer.sales_anly_flag = NULL 
				LET glob_rec_customer.credit_chk_flag = NULL 
				CLEAR FORM 
			ELSE 
				IF glob_rec_customer.cust_code = glob_rec_customer.corp_cust_code THEN 
					ERROR kandoomsg2("A",9501,"") 
					NEXT FIELD corp_cust_code 
				END IF 

				SELECT * INTO l_rec_corpcust.* 
				FROM customer 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = glob_rec_customer.corp_cust_code 

				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("A",9009,"") 					#9009 "Customer does NOT exist - try window"
					NEXT FIELD corp_cust_code 
				END IF 

				IF l_rec_corpcust.corp_cust_code IS NOT NULL THEN 
					ERROR kandoomsg2("A",9502,"") 
					NEXT FIELD corp_cust_code 
				END IF 

				IF l_rec_corpcust.currency_code = glob_rec_customer.currency_code THEN 
					DISPLAY BY NAME l_rec_corpcust.name_text 

				ELSE 
					ERROR kandoomsg2("A",9060,"") 					#9060 "Corporate & Branch customers must have same currency"
					NEXT FIELD corp_cust_code 
				END IF 

				IF glob_rec_customer.inv_addr_flag IS NULL THEN 
					LET glob_rec_customer.inv_addr_flag = "O" 
				END IF 

				IF glob_rec_customer.sales_anly_flag IS NULL THEN 
					LET glob_rec_customer.sales_anly_flag = "O" 
				END IF 

				IF glob_rec_customer.credit_chk_flag IS NULL THEN 
					LET glob_rec_customer.credit_chk_flag = "O" 
				END IF 

				DISPLAY BY NAME glob_rec_customer.inv_addr_flag, 
				glob_rec_customer.sales_anly_flag, 
				glob_rec_customer.credit_chk_flag 

			END IF 

		AFTER FIELD inv_addr_flag 
			IF glob_rec_customer.corp_cust_code IS NOT NULL 
			AND glob_rec_customer.inv_addr_flag IS NULL THEN 
				ERROR kandoomsg2("A",9061,"") 				#9061 "You must enter invoice address flag"
				NEXT FIELD inv_addr_flag 
			END IF 

		AFTER FIELD sales_anly_flag 
			IF glob_rec_customer.corp_cust_code IS NOT NULL 
			AND glob_rec_customer.sales_anly_flag IS NULL THEN 
				ERROR kandoomsg2("A",9062,"") 				#9062 "You must enter sales_anly_flag price flag"
				NEXT FIELD sales_anly_flag 
			END IF 

		AFTER FIELD credit_chk_flag 
			IF glob_rec_customer.corp_cust_code IS NOT NULL 
			AND glob_rec_customer.credit_chk_flag IS NULL THEN 
				ERROR kandoomsg2("A",9063,"") 				#9063 "You must enter credit_chk_flag price flag"
				NEXT FIELD credit_chk_flag 
			END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF glob_rec_customer.corp_cust_code IS NULL THEN 
					LET glob_rec_customer.inv_addr_flag = NULL 
					LET glob_rec_customer.sales_anly_flag = NULL 
					LET glob_rec_customer.credit_chk_flag = NULL 
					CLEAR FORM 
				ELSE 
					IF glob_rec_customer.inv_addr_flag IS NULL THEN 
						LET glob_rec_customer.inv_addr_flag = "O" 
					END IF 
					IF glob_rec_customer.sales_anly_flag IS NULL THEN 
						LET glob_rec_customer.sales_anly_flag = "O" 
					END IF 
					IF glob_rec_customer.credit_chk_flag IS NULL THEN 
						LET glob_rec_customer.credit_chk_flag = "O" 
					END IF 
				END IF 
			END IF 


	END INPUT 
	################################

	CLOSE WINDOW A205a 

	IF int_flag OR quit_flag THEN 
		LET glob_rec_customer.* = l_rec_customer.* 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 
END FUNCTION 
############################################################
# FUNCTION customer_edit_5()
############################################################


############################################################
# FUNCTION customer_edit_6()
#
#
############################################################
FUNCTION customer_edit_6() 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_userref RECORD LIKE userref.* 
	DEFINE l_valid_flag SMALLINT 
	DEFINE l_seq_num SMALLINT 
	DEFINE l_temp_text STRING

	LET l_rec_customer.* = glob_rec_customer.* 
	LET glob_rec_arparms.ref1_text = A11_make_prompt(glob_rec_arparms.ref1_text) 
	LET glob_rec_arparms.ref2_text = A11_make_prompt(glob_rec_arparms.ref2_text) 
	LET glob_rec_arparms.ref3_text = A11_make_prompt(glob_rec_arparms.ref3_text) 
	LET glob_rec_arparms.ref4_text = A11_make_prompt(glob_rec_arparms.ref4_text) 
	LET glob_rec_arparms.ref5_text = A11_make_prompt(glob_rec_arparms.ref5_text) 
	LET glob_rec_arparms.ref6_text = A11_make_prompt(glob_rec_arparms.ref6_text) 
	LET glob_rec_arparms.ref7_text = A11_make_prompt(glob_rec_arparms.ref7_text) 
	LET glob_rec_arparms.ref8_text = A11_make_prompt(glob_rec_arparms.ref8_text) 

	OPEN WINDOW A602 with FORM "A602" 
	CALL windecoration_a("A602") 

	MESSAGE kandoomsg2("U",1020,"Customer Report Codes") 	#U1020 Enter Customer Details - ESC TO Continue
	DISPLAY BY NAME 
		glob_rec_arparms.ref1_text, 
		glob_rec_arparms.ref2_text, 
		glob_rec_arparms.ref3_text, 
		glob_rec_arparms.ref4_text, 
		glob_rec_arparms.ref5_text, 
		glob_rec_arparms.ref6_text, 
		glob_rec_arparms.ref7_text, 
		glob_rec_arparms.ref8_text attribute(white) 

	INPUT BY NAME 
		glob_rec_customer.ref1_code, 
		glob_rec_customer.ref2_code, 
		glob_rec_customer.ref3_code, 
		glob_rec_customer.ref4_code, 
		glob_rec_customer.ref5_code, 
		glob_rec_customer.ref6_code, 
		glob_rec_customer.ref7_code, 
		glob_rec_customer.ref8_code WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED) 


		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A11","input-customer-5") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

			############################################################
			# X
			############################################################

		ON ACTION "LOOKUP" infield (ref1_code) 
			LET l_temp_text = show_ref(glob_rec_kandoouser.cmpy_code,"A","1") 
			IF l_temp_text IS NOT NULL THEN 
				LET glob_rec_customer.ref1_code = l_temp_text 
				NEXT FIELD ref1_code 
			END IF 

		ON ACTION "LOOKUP" infield (ref2_code) 
			LET l_temp_text = show_ref(glob_rec_kandoouser.cmpy_code,"A","2") 
			IF l_temp_text IS NOT NULL THEN 
				LET glob_rec_customer.ref2_code = l_temp_text 
				NEXT FIELD ref2_code 
			END IF 

		ON ACTION "LOOKUP" infield (ref3_code) 
			LET l_temp_text = show_ref(glob_rec_kandoouser.cmpy_code,"A","3") 
			IF l_temp_text IS NOT NULL THEN 
				LET glob_rec_customer.ref3_code = l_temp_text 
				NEXT FIELD ref3_code 
			END IF 

		ON ACTION "LOOKUP" infield (ref4_code) 
			LET l_temp_text = show_ref(glob_rec_kandoouser.cmpy_code,"A","4") 
			IF l_temp_text IS NOT NULL THEN 
				LET glob_rec_customer.ref4_code = l_temp_text 
				NEXT FIELD ref4_code 
			END IF 

		ON ACTION "LOOKUP" infield (ref5_code) 
			LET l_temp_text = show_ref(glob_rec_kandoouser.cmpy_code,"A","5") 
			IF l_temp_text IS NOT NULL THEN 
				LET glob_rec_customer.ref5_code = l_temp_text 
				NEXT FIELD ref5_code 
			END IF 

		ON ACTION "LOOKUP" infield (ref6_code) 
			LET l_temp_text = show_ref(glob_rec_kandoouser.cmpy_code,"A","6") 
			IF l_temp_text IS NOT NULL THEN 
				LET glob_rec_customer.ref6_code = l_temp_text 
				NEXT FIELD ref6_code 
			END IF 

		ON ACTION "LOOKUP" infield (ref7_code) 
			LET l_temp_text = show_ref(glob_rec_kandoouser.cmpy_code,"A","7") 
			IF l_temp_text IS NOT NULL THEN 
				LET glob_rec_customer.ref7_code = l_temp_text 
				NEXT FIELD ref7_code 
			END IF 

		ON ACTION "LOOKUP" infield (ref8_code) 
			LET l_temp_text = show_ref(glob_rec_kandoouser.cmpy_code,"A","8") 
			IF l_temp_text IS NOT NULL THEN 
				LET glob_rec_customer.ref8_code = l_temp_text 
				NEXT FIELD ref8_code 
			END IF 


		BEFORE FIELD ref1_code 
			IF glob_rec_arparms.ref1_text IS NULL THEN 
				LET l_seq_num = 1 
				NEXT FIELD ref2_code 
			END IF 

		AFTER FIELD ref1_code 
			LET l_seq_num = 1 

			CALL valid_ref("1",glob_rec_arparms.ref1_ind,glob_rec_customer.ref1_code) 
			RETURNING l_valid_flag,l_rec_userref.ref_desc_text 

			IF l_valid_flag THEN 
				DISPLAY l_rec_userref.ref_desc_text TO ref1_desc_text 

			ELSE 
				CLEAR ref1_desc_text 
				NEXT FIELD ref1_code 
			END IF 

		BEFORE FIELD ref2_code 
			IF glob_rec_arparms.ref2_text IS NULL THEN 
				IF l_seq_num > 2 THEN 
					LET l_seq_num = 2 
					NEXT FIELD ref1_code 
				ELSE 
					LET l_seq_num = 2 
					NEXT FIELD ref3_code 
				END IF 
			END IF 

		AFTER FIELD ref2_code 
			LET l_seq_num = 2 

			CALL valid_ref("2",glob_rec_arparms.ref2_ind,glob_rec_customer.ref2_code) 
			RETURNING l_valid_flag,l_rec_userref.ref_desc_text 

			IF l_valid_flag THEN 
				DISPLAY l_rec_userref.ref_desc_text TO ref2_desc_text 

			ELSE 
				CLEAR ref2_desc_text 
				NEXT FIELD ref2_code 
			END IF 

		BEFORE FIELD ref3_code 
			IF glob_rec_arparms.ref3_text IS NULL THEN 
				IF l_seq_num > 3 THEN 
					LET l_seq_num = 3 
					NEXT FIELD ref2_code 
				ELSE 
					LET l_seq_num = 3 
					NEXT FIELD ref4_code 
				END IF 
			END IF 

		AFTER FIELD ref3_code 
			LET l_seq_num = 3 

			CALL valid_ref("3",glob_rec_arparms.ref3_ind,glob_rec_customer.ref3_code) 
			RETURNING l_valid_flag,l_rec_userref.ref_desc_text 

			IF l_valid_flag THEN 
				DISPLAY l_rec_userref.ref_desc_text TO ref3_desc_text 

			ELSE 
				CLEAR ref3_desc_text 
				NEXT FIELD ref3_code 
			END IF 

		BEFORE FIELD ref4_code 
			IF glob_rec_arparms.ref4_text IS NULL THEN 
				IF l_seq_num > 4 THEN 
					LET l_seq_num = 4 
					NEXT FIELD ref3_code 
				ELSE 
					LET l_seq_num = 4 
					NEXT FIELD ref5_code 
				END IF 
			END IF 

		AFTER FIELD ref4_code 
			LET l_seq_num = 4 

			CALL valid_ref("4",glob_rec_arparms.ref4_ind,glob_rec_customer.ref4_code) 
			RETURNING l_valid_flag,l_rec_userref.ref_desc_text 

			IF l_valid_flag THEN 
				DISPLAY l_rec_userref.ref_desc_text TO ref4_desc_text 

			ELSE 
				CLEAR ref4_desc_text 
				NEXT FIELD ref4_code 
			END IF 

		BEFORE FIELD ref5_code 
			IF glob_rec_arparms.ref5_text IS NULL THEN 
				IF l_seq_num > 5 THEN 
					LET l_seq_num = 5 
					NEXT FIELD ref4_code 
				ELSE 
					LET l_seq_num = 5 
					NEXT FIELD ref6_code 
				END IF 
			END IF 

		AFTER FIELD ref5_code 
			LET l_seq_num = 5 
			CALL valid_ref("5",glob_rec_arparms.ref5_ind,glob_rec_customer.ref5_code) 
			RETURNING l_valid_flag,l_rec_userref.ref_desc_text 

			IF l_valid_flag THEN 
				DISPLAY l_rec_userref.ref_desc_text TO ref5_desc_text 

			ELSE 
				CLEAR ref5_desc_text 
				NEXT FIELD ref5_code 
			END IF 

		BEFORE FIELD ref6_code 
			IF glob_rec_arparms.ref6_text IS NULL THEN 
				IF l_seq_num > 6 THEN 
					LET l_seq_num = 6 
					NEXT FIELD ref5_code 
				ELSE 
					LET l_seq_num = 6 
					NEXT FIELD ref7_code 
				END IF 
			END IF 

		AFTER FIELD ref6_code 
			LET l_seq_num = 6 
			CALL valid_ref("6",glob_rec_arparms.ref6_ind,glob_rec_customer.ref6_code) 
			RETURNING l_valid_flag,l_rec_userref.ref_desc_text 

			IF l_valid_flag THEN 
				DISPLAY l_rec_userref.ref_desc_text TO ref6_desc_text 

			ELSE 
				CLEAR ref6_desc_text 
				NEXT FIELD ref6_code 
			END IF 

		BEFORE FIELD ref7_code 
			IF glob_rec_arparms.ref7_text IS NULL THEN 
				IF l_seq_num > 7 THEN 
					LET l_seq_num = 7 
					NEXT FIELD ref6_code 
				ELSE 
					LET l_seq_num = 7 
					NEXT FIELD ref8_code 
				END IF 
			END IF 

		AFTER FIELD ref7_code 
			LET l_seq_num = 7 
			CALL valid_ref("7",glob_rec_arparms.ref7_ind,glob_rec_customer.ref7_code) 
			RETURNING l_valid_flag,l_rec_userref.ref_desc_text 

			IF l_valid_flag THEN 
				DISPLAY l_rec_userref.ref_desc_text TO ref7_desc_text 

			ELSE 
				CLEAR ref7_desc_text 
				NEXT FIELD ref7_code 
			END IF 

		BEFORE FIELD ref8_code 
			IF glob_rec_arparms.ref8_text IS NULL THEN 
				LET l_seq_num = 8 
				EXIT INPUT 
			END IF 

		AFTER FIELD ref8_code 
			LET l_seq_num = 8 
			CALL valid_ref("8",glob_rec_arparms.ref8_ind,glob_rec_customer.ref8_code) 
			RETURNING l_valid_flag,l_rec_userref.ref_desc_text 

			IF l_valid_flag THEN 
				DISPLAY l_rec_userref.ref_desc_text TO ref8_desc_text 

			ELSE 
				CLEAR ref8_desc_text 
				NEXT FIELD ref8_code 
			END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				CALL valid_ref("1",glob_rec_arparms.ref1_ind,glob_rec_customer.ref1_code) 
				RETURNING l_valid_flag,l_rec_userref.ref_desc_text 
				IF l_valid_flag = 0 THEN 
					NEXT FIELD ref1_code 
				END IF 

				CALL valid_ref("2",glob_rec_arparms.ref2_ind,glob_rec_customer.ref2_code) 
				RETURNING l_valid_flag,l_rec_userref.ref_desc_text 

				IF l_valid_flag = 0 THEN 
					NEXT FIELD ref2_code 
				END IF 

				CALL valid_ref("3",glob_rec_arparms.ref3_ind,glob_rec_customer.ref3_code) 
				RETURNING l_valid_flag,l_rec_userref.ref_desc_text 
				IF l_valid_flag = 0 THEN 
					NEXT FIELD ref3_code 
				END IF 

				CALL valid_ref("4",glob_rec_arparms.ref4_ind,glob_rec_customer.ref4_code) 
				RETURNING l_valid_flag,l_rec_userref.ref_desc_text 

				IF l_valid_flag = 0 THEN 
					NEXT FIELD ref4_code 
				END IF 

				CALL valid_ref("5",glob_rec_arparms.ref5_ind,glob_rec_customer.ref5_code) 
				RETURNING l_valid_flag,l_rec_userref.ref_desc_text 

				IF l_valid_flag = 0 THEN 
					NEXT FIELD ref5_code 
				END IF 

				CALL valid_ref("6",glob_rec_arparms.ref6_ind,glob_rec_customer.ref6_code) 
				RETURNING l_valid_flag,l_rec_userref.ref_desc_text 

				IF l_valid_flag = 0 THEN 
					NEXT FIELD ref6_code 
				END IF 

				CALL valid_ref("7",glob_rec_arparms.ref7_ind,glob_rec_customer.ref7_code) 
				RETURNING l_valid_flag,l_rec_userref.ref_desc_text 

				IF l_valid_flag = 0 THEN 
					NEXT FIELD ref7_code 
				END IF 

				CALL valid_ref("8",glob_rec_arparms.ref8_ind,glob_rec_customer.ref8_code) 
				RETURNING l_valid_flag,l_rec_userref.ref_desc_text 

				IF l_valid_flag = 0 THEN 
					NEXT FIELD ref8_code 
				END IF 

			END IF 



	END INPUT 
	####################

	CLOSE WINDOW A602 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET glob_rec_customer.* = l_rec_customer.* 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 
############################################################
# FUNCTION customer_edit_6()
############################################################


############################################################
# FUNCTION edit7_cust()
#
#
############################################################
FUNCTION edit7_cust() 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_stateinfo RECORD LIKE stateinfo.* 

	LET l_rec_customer.* = glob_rec_customer.* 

	OPEN WINDOW A234 with FORM "A234" 
	CALL windecoration_a("A234") 

	MESSAGE kandoomsg2("U",1020,"Customer Billing") 	#U1020 Enter Customer Correspondence - ESC TO Continue

	INPUT BY NAME 
		glob_rec_customer.stmnt_ind, 
		glob_rec_customer.dun_code, 
		modu_rec_custstmnt.stat_date, 
		modu_rec_custstmnt.bal_amt, 
		glob_rec_customer.inv_reqd_flag, 
		glob_rec_customer.inv_format_ind, 
		glob_rec_customer.cred_reqd_flag, 
		glob_rec_customer.cred_format_ind, 
		glob_rec_customer.mail_reqd_flag WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED) 


		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A11","input-customer-6") 

			#stmnt_ind
			CASE glob_rec_customer.stmnt_ind	
				WHEN "O"
					DISPLAY "Open Item" TO stmnt_text
				WHEN "B"
					DISPLAY "Balance Forward" TO stmnt_text
				WHEN "N"
					DISPLAY "None" TO stmnt_text
				WHEN "W"
					DISPLAY "Weekly" TO stmnt_text
			END CASE

			#dun_code
			IF glob_rec_customer.dun_code IS NOT NULL THEN 
				SELECT all1_text INTO l_rec_stateinfo.all1_text 
				FROM stateinfo 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND dun_code = glob_rec_customer.dun_code 
				IF status = 0 THEN 
					DISPLAY l_rec_stateinfo.all1_text TO all1_text
				END IF 
			END IF 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null)
			 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "REFRESH"
			CALL windecoration_a("A234")
					
		ON CHANGE stmnt_ind
			CASE glob_rec_customer.stmnt_ind	
				WHEN "O"
					DISPLAY "Open Item" TO stmnt_text
				WHEN "B"
					DISPLAY "Balance Forward" TO stmnt_text
				WHEN "N"
					DISPLAY "None" TO stmnt_text
				WHEN "W"
					DISPLAY "Weekly" TO stmnt_text
			END CASE
			 
		ON CHANGE dun_code #copy paste after field
			IF glob_rec_customer.dun_code IS NOT NULL THEN 
				SELECT all1_text INTO l_rec_stateinfo.all1_text 
				FROM stateinfo 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND dun_code = glob_rec_customer.dun_code 
				IF status = 0 THEN 
					DISPLAY l_rec_stateinfo.all1_text TO all1_text
				END IF 
			END IF 


		AFTER FIELD dun_code 
			CLEAR all1_text 
			IF glob_rec_customer.dun_code IS NOT NULL THEN 
				SELECT all1_text INTO l_rec_stateinfo.all1_text 
				FROM stateinfo 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND dun_code = glob_rec_customer.dun_code 
				IF status = 0 THEN 
					DISPLAY l_rec_stateinfo.all1_text TO all1_text

				END IF 
			END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
			END IF 



	END INPUT 
	######################

	CLOSE WINDOW A234 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET glob_rec_customer.* = l_rec_customer.* 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 
############################################################
# FUNCTION edit7_cust()
############################################################


############################################################
# FUNCTION update_customer(p_mode)
#
#
############################################################
FUNCTION update_customer(p_mode) 
	DEFINE p_mode CHAR(4) 
	DEFINE l_err_message CHAR(80) 
	DEFINE l_trans_num INTEGER 
	DEFINE l_rec_customership RECORD LIKE customership.* 
	DEFINE l_err_continue CHAR(1) 
	DEFINE l_country_code LIKE country.country_code --@db-patch_2020_10_04--
	
	#Final validation for NULL values
	IF glob_rec_customer.cred_limit_amt IS NULL THEN
		LET glob_rec_customer.cred_limit_amt = 0
	END IF
	IF glob_rec_customer.cred_bal_amt IS NULL THEN
		LET glob_rec_customer.cred_bal_amt = 0
	END IF
	IF glob_rec_customer.scheme_amt IS NULL THEN
		LET glob_rec_customer.scheme_amt = 0	
	END IF
	IF glob_rec_customer.cred_given_num IS NULL THEN
		LET glob_rec_customer.cred_given_num = 0
	END IF
	IF glob_rec_customer.cred_taken_num IS NULL THEN
		LET glob_rec_customer.cred_taken_num = 0
	END IF

	IF glob_rec_customer.interest_per IS NULL THEN
		LET glob_rec_customer.interest_per = 0
	END IF		
			
	IF glob_update_order_hold THEN 
		CALL hold_orders(modu_prev_hold_code) 
	END IF 

	IF glob_rec_customer.bal_amt IS NULL THEN
		LET glob_rec_customer.bal_amt = 0
	END IF
	IF glob_rec_customer.curr_amt IS NULL THEN
		LET glob_rec_customer.curr_amt = 0
	END IF

	IF glob_rec_customer.ytdp_amt IS NULL THEN
		LET glob_rec_customer.ytdp_amt = 0
	END IF
	
	IF glob_rec_customer.mtdp_amt IS NULL THEN
		LET glob_rec_customer.mtdp_amt = 0
	END IF

	GOTO bypass 

	LABEL recovery: 
	IF error_recover(l_err_message,status) != "Y" THEN 
		RETURN false 
	END IF 

	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	BEGIN WORK 
		IF p_mode = MODE_CLASSIC_ADD THEN 
			IF modu_auto_cust_ind THEN 
				LET l_trans_num = next_trans_num(glob_rec_kandoouser.cmpy_code,TRAN_TYPE_CUSTOMER_CUS,"") 
				IF l_trans_num < 0 THEN 
					LET l_err_message = "Next customer number UPDATE" 
					LET status = l_trans_num 
					GOTO recovery 
				END IF 
				LET glob_rec_customer.cust_code = l_trans_num 
			END IF 

			SELECT unique 1 FROM customer 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = glob_rec_customer.cust_code 

			IF status = 0 THEN 
				LET l_err_message = "Customer already exists" 
				ERROR kandoomsg2("A",9025,"") 
				GOTO recovery 
			END IF 

			LET l_err_message = "A11 - Inserting New Customer Row" 
			IF glob_rec_customer.cmpy_code IS NULL THEN
				LET glob_rec_customer.cmpy_code = get_ku_cmpy_code()  #for some reason, company was not set
			END IF
			INSERT INTO customer VALUES (glob_rec_customer.*) 

			LET l_err_message = "A11 - Inserting Customer Group Codes" 
			INSERT INTO stnd_custgrp SELECT * FROM t1_stnd_custgrp 

		ELSE 
--			LET l_country_text = db_country_get_country_text(UI_OFF,glob_rec_customer.country_code) --@db-patch_2020_10_04--

			UPDATE customer 
			SET corp_cust_code = glob_rec_customer.corp_cust_code, 
			name_text = glob_rec_customer.name_text, 
			addr1_text = glob_rec_customer.addr1_text, 
			addr2_text = glob_rec_customer.addr2_text, 
			city_text = glob_rec_customer.city_text, 
			state_code = glob_rec_customer.state_code, 
			post_code = glob_rec_customer.post_code, 
--			country_text = l_country_text, --@db-patch_2020_10_04-- 
			country_code = glob_rec_customer.country_code, 
			language_code = glob_rec_customer.language_code, 
			type_code = glob_rec_customer.type_code, 
			sale_code = glob_rec_customer.sale_code, 
			term_code = glob_rec_customer.term_code, 
			tax_code = glob_rec_customer.tax_code, 
			inv_addr_flag = glob_rec_customer.inv_addr_flag, 
			sales_anly_flag = glob_rec_customer.sales_anly_flag, 
			credit_chk_flag = glob_rec_customer.credit_chk_flag, 
			tax_num_text = glob_rec_customer.tax_num_text, 
			last_mail_date = glob_rec_customer.last_mail_date, 
			registration_num = glob_rec_customer.registration_num, 
			vat_code = glob_rec_customer.vat_code, 
			contact_text = glob_rec_customer.contact_text, 
			tele_text = glob_rec_customer.tele_text, 
			mobile_phone = glob_rec_customer.mobile_phone,			
			email = glob_rec_customer.email,			
			cred_limit_amt = glob_rec_customer.cred_limit_amt, 
			cred_bal_amt = glob_rec_customer.cred_bal_amt, 
			inv_level_ind = glob_rec_customer.inv_level_ind, 
			dun_code = glob_rec_customer.dun_code, 
			partial_ship_flag = glob_rec_customer.partial_ship_flag, 
			back_order_flag = glob_rec_customer.back_order_flag, 
			currency_code = glob_rec_customer.currency_code, 
			int_chge_flag = glob_rec_customer.int_chge_flag, 
			stmnt_ind = glob_rec_customer.stmnt_ind, 
			fax_text = glob_rec_customer.fax_text, 
			territory_code = glob_rec_customer.territory_code, 
			bank_acct_code = glob_rec_customer.bank_acct_code, 
			consolidate_flag = glob_rec_customer.consolidate_flag, 
			cond_code = glob_rec_customer.cond_code, 
			pay_ind = glob_rec_customer.pay_ind, 
			hold_code = glob_rec_customer.hold_code, 
			share_flag = glob_rec_customer.share_flag, 
			invoice_to_ind = glob_rec_customer.invoice_to_ind, 
			ref1_code = glob_rec_customer.ref1_code, 
			ref2_code = glob_rec_customer.ref2_code, 
			ref3_code = glob_rec_customer.ref3_code, 
			ref4_code = glob_rec_customer.ref4_code, 
			ref5_code = glob_rec_customer.ref5_code, 
			ref6_code = glob_rec_customer.ref6_code, 
			ref7_code = glob_rec_customer.ref7_code, 
			ref8_code = glob_rec_customer.ref8_code, 
			mobile_phone = glob_rec_customer.mobile_phone, 
			comment_text = glob_rec_customer.comment_text, 
			ord_text_ind = glob_rec_customer.ord_text_ind, 
			corp_cust_ind = glob_rec_customer.corp_cust_ind, 
			cred_override_ind = glob_rec_customer.cred_override_ind, 
			inv_reqd_flag = glob_rec_customer.inv_reqd_flag, 
			inv_format_ind = glob_rec_customer.inv_format_ind, 
			cred_reqd_flag = glob_rec_customer.cred_reqd_flag, 
			cred_format_ind = glob_rec_customer.cred_format_ind, 
			mail_reqd_flag = glob_rec_customer.mail_reqd_flag,
			ytdp_amt = glob_rec_customer.ytdp_amt,
			mtdp_amt = glob_rec_customer.mtdp_amt,
			scheme_amt = glob_rec_customer.scheme_amt,
			cred_given_num = glob_rec_customer.cred_given_num,
			cred_taken_num = glob_rec_customer.cred_taken_num,
			interest_per = glob_rec_customer.interest_per,
			bal_amt = glob_rec_customer.bal_amt,
			curr_amt = glob_rec_customer.curr_amt						  
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = glob_rec_customer.cust_code
			
			LET l_err_message = "A11 - Deleting Customer Group Codes" 

			DELETE FROM stnd_custgrp 

			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = glob_rec_customer.cust_code 

			LET l_err_message = "A11 - Inserting Customer Group Codes" 

			INSERT INTO stnd_custgrp SELECT * FROM t1_stnd_custgrp 

		END IF 

		IF p_mode = MODE_CLASSIC_ADD THEN 
			LET l_err_message="A11 - Inserting Customer Shipping Address" 

			DECLARE c_ship CURSOR FOR 
			SELECT * FROM t_customership 

			FOREACH c_ship INTO l_rec_customership.* 
				LET l_rec_customership.cust_code = glob_rec_customer.cust_code 
				INSERT INTO customership VALUES (l_rec_customership.*) 
			END FOREACH 

		END IF 

	COMMIT WORK 

	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 

	RETURN true 
END FUNCTION 
############################################################
# END FUNCTION update_customer(p_mode)
############################################################


############################################################
# FUNCTION valid_ref(p_ref_num,p_ref_ind,p_ref_code)
#
#
############################################################
FUNCTION valid_ref(p_ref_num,p_ref_ind,p_ref_code) 
	DEFINE p_ref_num LIKE userref.ref_ind 
	DEFINE p_ref_ind LIKE arparms.ref1_ind 
	DEFINE p_ref_code LIKE customer.ref1_code 
	DEFINE l_desc_text LIKE userref.ref_desc_text 
	DEFINE l_query_text CHAR(100) 
	DEFINE l_text CHAR(20) 
	DEFINE l_status INTEGER 

	LET l_query_text = "SELECT ref",p_ref_num,"_text FROM arparms ", 
	"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND parm_code = \"1\"" 

	PREPARE s_arparms FROM l_query_text 
	DECLARE c_arparms CURSOR FOR s_arparms 

	OPEN c_arparms 
	FETCH c_arparms INTO l_text 

	SELECT ref_desc_text 
	INTO l_desc_text 
	FROM userref 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND source_ind = "A" 
	AND ref_ind = p_ref_num 
	AND ref_code = p_ref_code 

	CASE p_ref_ind 

		WHEN "1" 
			LET l_status = true 

		WHEN "2" 
			IF p_ref_code IS NULL THEN 
				ERROR kandoomsg2("A",9065,l_text)				#9065" Reference Code #,X,"must be Entered"
				LET l_status = false 
			ELSE 
				LET l_status = true 
			END IF 

		WHEN "3" 
			IF p_ref_code IS NOT NULL 
			AND sqlca.sqlcode = NOTFOUND THEN 
				ERROR kandoomsg2("A",9066,l_text)			#9066" Reference Code #,X," NOT found - Try Window"
				LET l_status = false 
			ELSE 
				LET l_status = true 
			END IF 

		WHEN "4" 
			IF p_ref_code IS NULL THEN 
				ERROR kandoomsg2("A",9065,l_text)			#9065" Reference Code #,X,"must be Entered"
				LET l_status = false 
			ELSE 
				IF sqlca.sqlcode = NOTFOUND THEN 
					ERROR kandoomsg2("A",9066,l_text)				#9066" Reference Code #,X," NOT found - Try Window"
					LET l_status = false 
				ELSE 
					LET l_status = true 
				END IF 

			END IF 

		OTHERWISE 
			LET l_status = 2 

	END CASE 

	RETURN l_status,l_desc_text 
END FUNCTION 
############################################################
# END FUNCTION valid_ref(p_ref_num,p_ref_ind,p_ref_code)
############################################################


############################################################
# FUNCTION add_cust_grps(p_cmpy_code,p_cust_code)
#
#
############################################################
FUNCTION add_cust_grps(p_cmpy_code,p_cust_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code #huho may NOT used 
	DEFINE p_cust_code LIKE customer.cust_code 
	DEFINE l_dup_cnt SMALLINT #, scrn 
	DEFINE l_cnt SMALLINT 
	DEFINE i SMALLINT 
	DEFINE l_idx SMALLINT 
	#	DEFINE scr SMALLINT

	DEFINE l_rec_stnd_custgrp RECORD LIKE stnd_custgrp.* 
	DEFINE l_arr_rec_stnd_custgrp DYNAMIC ARRAY OF #array[20] OF RECORD 
		RECORD 
			group_code LIKE stnd_custgrp.group_code, 
			attn_text LIKE stnd_custgrp.attn_text 
		END RECORD 
		DEFINE fv_new_group LIKE stnd_custgrp.group_code 

		LET l_idx = 0 

		OPEN WINDOW A920 with FORM "A920" 
		CALL windecoration_a("A920") #huho CHECK this later 

		SELECT count(*) 
		INTO l_cnt 
		FROM t1_stnd_custgrp 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = p_cust_code 

		IF l_cnt > 0 THEN 
			DECLARE stnd_grp CURSOR FOR 
			SELECT * 
			FROM t1_stnd_custgrp 
			WHERE cust_code = p_cust_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 

			FOREACH stnd_grp INTO l_rec_stnd_custgrp.* 
				LET l_idx = l_idx + 1 
				LET l_arr_rec_stnd_custgrp[l_idx].group_code = l_rec_stnd_custgrp.group_code 
				LET l_arr_rec_stnd_custgrp[l_idx].attn_text = l_rec_stnd_custgrp.attn_text 
				IF l_idx > 21 THEN 
					ERROR " Only the first 20 customer groups have been selected " 
					EXIT FOREACH 
				END IF 
			END FOREACH 
		END IF 

		CALL set_count(l_idx) 
		DISPLAY p_cust_code TO cust_code 

		MESSAGE l_cnt, " Groups FOR Customer - F1 add, F2 Del" 
		#ATTRIBUTE(YELLOW)

		INPUT ARRAY l_arr_rec_stnd_custgrp WITHOUT DEFAULTS FROM sr_group.* ATTRIBUTE(UNBUFFERED) 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","A11","inp-arr-custgrp") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON ACTION "LOOKUP" infield (group_code) 
				MESSAGE "rp 1" 
				#DISPLAY "rp 1" AT 1,1
				LET fv_new_group = show_group(glob_rec_kandoouser.cmpy_code) 
				IF fv_new_group IS NOT NULL THEN 
					LET l_arr_rec_stnd_custgrp[l_idx].group_code = fv_new_group 
				END IF 
				#DISPLAY l_arr_rec_stnd_custgrp[l_idx].group_code TO sr_group[scrn].group_code
				NEXT FIELD group_code 

--			ON ACTION "ADD" 
--				#ON KEY(F1)
--				LET l_idx = arr_curr() 
--				#LET scrn = scr_line()
--
--				FOR i = arr_count() TO l_idx step -1 
--					LET l_arr_rec_stnd_custgrp[i+1].* = l_arr_rec_stnd_custgrp[i].* 
--				END FOR 
--
--				INITIALIZE l_arr_rec_stnd_custgrp[l_idx].* TO NULL 
--				#LET scr = scrn
--
--				#FOR i = l_idx TO l_idx + (10 - scrn)
--				#   DISPLAY l_arr_rec_stnd_custgrp[i].* TO sr_group[scr].*
--				#   LET scr = scr + 1
--				#END FOR
--
--				NEXT FIELD group_code 

			ON ACTION "DELETE" 
				#ON KEY(F2)
				LET l_idx = arr_curr() 
				#LET scrn = scr_line()

				FOR i = l_idx TO arr_count() 
					LET l_arr_rec_stnd_custgrp[i].* = l_arr_rec_stnd_custgrp[i+1].* 
				END FOR 

				LET l_cnt = arr_count() 
				INITIALIZE l_arr_rec_stnd_custgrp[l_cnt].* TO NULL 
				#LET scr = scrn

				#FOR i = l_idx TO l_idx + (10 - scrn)
				# DISPLAY l_arr_rec_stnd_custgrp[i].* TO sr_group[scr].*
				# LET scr = scr + 1
				#END FOR

				NEXT FIELD group_code 


			BEFORE ROW 
				LET l_idx = arr_curr() 
				#LET scrn = scr_line()


			AFTER FIELD group_code 
				IF l_arr_rec_stnd_custgrp[l_idx].group_code IS NOT NULL THEN 
					SELECT * 
					FROM stnd_grp 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND group_code = l_arr_rec_stnd_custgrp[l_idx].group_code 


					IF status = NOTFOUND THEN 
						ERROR " Group Code does NOT exist. Try window " 
						NEXT FIELD group_code 
					END IF 

					FOR i = 1 TO arr_count() 
						IF i = l_idx THEN 
							CONTINUE FOR 
						END IF 

						IF l_arr_rec_stnd_custgrp[l_idx].group_code = l_arr_rec_stnd_custgrp[i].group_code THEN 
							ERROR "This Customer already belongs TO this group " 
							NEXT FIELD group_code 
						END IF 

					END FOR 

				END IF 

			AFTER FIELD attn_text 
				SELECT count(*) INTO l_dup_cnt 
				FROM stnd_custgrp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND group_code = l_arr_rec_stnd_custgrp[l_idx].group_code 
				AND cust_code = p_cust_code 

				IF l_dup_cnt > 0 THEN 
					ERROR kandoomsg2("A",9563, l_arr_rec_stnd_custgrp[l_idx].group_code) 
					NEXT FIELD group_code 
				END IF 


			AFTER INPUT 
				IF l_arr_rec_stnd_custgrp[l_idx].group_code IS NOT NULL THEN 
					SELECT * 
					FROM stnd_grp 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND group_code = l_arr_rec_stnd_custgrp[l_idx].group_code 

					IF status = NOTFOUND THEN 
						ERROR " Group Code does NOT exist. Try window " 
						NEXT FIELD group_code 
					END IF 

				END IF 

		END INPUT 
		#######################

		CLOSE WINDOW A920 

		LET l_idx = arr_count() 
		CALL set_count(l_idx) 

		DELETE 
		FROM t1_stnd_custgrp 

		FOR l_idx = 1 TO arr_count() 
			IF l_arr_rec_stnd_custgrp[l_idx].group_code IS NULL THEN 
				CONTINUE FOR 
			END IF 
			LET l_rec_stnd_custgrp.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET l_rec_stnd_custgrp.cust_code = p_cust_code 
			LET l_rec_stnd_custgrp.group_code = l_arr_rec_stnd_custgrp[l_idx].group_code 
			LET l_rec_stnd_custgrp.attn_text = l_arr_rec_stnd_custgrp[l_idx].attn_text 

			INSERT INTO t1_stnd_custgrp 
			VALUES (l_rec_stnd_custgrp.*) 
		END FOR 

END FUNCTION #add_cust_grps 
############################################################
# FUNCTION add_cust_grps(p_cmpy_code,p_cust_code)
############################################################


############################################################
# FUNCTION A11_make_prompt(p_ref_text)
#
#
############################################################
FUNCTION A11_make_prompt(p_ref_text) 
	DEFINE l_temp_text CHAR(40) 
	DEFINE p_ref_text LIKE arparms.ref1_text 

	IF p_ref_text IS NULL THEN 
		LET l_temp_text = NULL 
	ELSE 
		LET l_temp_text = p_ref_text clipped,"...................." 
	END IF 

	RETURN l_temp_text 

END FUNCTION 
############################################################
# END FUNCTION A11_make_prompt(p_ref_text)
############################################################


############################################################
# FUNCTION hold_orders(p_prev_hold_code)
#
#
############################################################
FUNCTION hold_orders(p_prev_hold_code) 
	DEFINE p_prev_hold_code LIKE customer.hold_code 
	DEFINE l_rec_orderhead RECORD LIKE orderhead.* 
	DEFINE l_rec_orderhead2 RECORD LIKE orderhead.* 
	DEFINE l_err_message CHAR(60) 

	MESSAGE kandoomsg2("U",1005,"") 	#1005 Updating Database; Please Wait..

	GOTO bypass2 

	LABEL recovery2: 
	IF error_recover(l_err_message,status) != "Y" THEN 
		RETURN false 
	END IF 

	LABEL bypass2: 
	WHENEVER ERROR GOTO recovery2 

	IF p_prev_hold_code IS NULL THEN 
		#Place Orders On Hold
		DECLARE c_holdorder CURSOR with HOLD FOR 
		SELECT * FROM orderhead 
		WHERE cust_code = glob_rec_customer.cust_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND hold_code IS NULL 
		AND status_ind in ("U","P","X") 

		FOREACH c_holdorder INTO l_rec_orderhead.* 
			BEGIN WORK 
				INITIALIZE l_rec_orderhead2.* TO NULL 
				LET l_err_message = "A11a - Getting Orderhead FOR Update" 

				DECLARE c2_holdorder CURSOR FOR 
				SELECT * FROM orderhead 
				WHERE order_num = l_rec_orderhead.order_num 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				FOR UPDATE 

				OPEN c2_holdorder 
				FETCH c2_holdorder INTO l_rec_orderhead2.* 

				IF l_rec_orderhead2.status_ind = "X" THEN 
					ERROR kandoomsg2("A",7095,"")					#7095 Order being editted; No adjustment made.
					ROLLBACK WORK 
					CONTINUE FOREACH 
				END IF 

				LET l_err_message = "A11a - Updating Hold Code On Orders" 
				UPDATE orderhead 
				SET hold_code = glob_rec_customer.hold_code 
				WHERE CURRENT OF c2_holdorder 
			COMMIT WORK 

		END FOREACH 

	ELSE 

		#Remove Customer Hold Code FROM Order
		DECLARE c3_holdorder CURSOR with HOLD FOR 
		SELECT * FROM orderhead 
		WHERE cust_code = glob_rec_customer.cust_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND hold_code = p_prev_hold_code 
		AND status_ind in ("U","P","X") 

		FOREACH c3_holdorder INTO l_rec_orderhead.* 
			BEGIN WORK 
				INITIALIZE l_rec_orderhead2.* TO NULL 
				LET l_err_message = "A11a - Getting Orderhead FOR Update2" 

				DECLARE c4_holdorder CURSOR FOR 
				SELECT * FROM orderhead 
				WHERE order_num = l_rec_orderhead.order_num 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				FOR UPDATE 

				OPEN c4_holdorder 
				FETCH c4_holdorder INTO l_rec_orderhead2.* 

				IF l_rec_orderhead2.status_ind = "X" THEN 
					ERROR kandoomsg2("A",7095,"")			#7095 Order being editted; No adjustment made.
					ROLLBACK WORK 
					CONTINUE FOREACH 
				END IF 

				LET l_err_message = "A11a - Updating Hold Code On Orders2" 

				UPDATE orderhead 
				SET hold_code = NULL 
				WHERE current of c4_holdorder
			COMMIT WORK 

		END FOREACH 
	END IF 

END FUNCTION 
############################################################
# END FUNCTION hold_orders(p_prev_hold_code)
############################################################