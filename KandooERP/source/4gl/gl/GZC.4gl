#Fiscal Year & Period G153
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
# Purpose - adds new companies AND sets up the rms parameters record
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS "../setup/lib_db_setup_GLOBALS.4gl" 
GLOBALS 
	DEFINE glob_rec_company_setup RECORD LIKE company.*
	#	DEFINE
	#glob_rec_company_setup
	#glob_rec_company_setup RECORD LIKE company.*
	#	DEFINE modu_rec_setup_currency RECORD LIKE currency.* #moved to module scope
	#	DEFINE modu_rec_setup_country RECORD LIKE country.* #moved to module scope
	#	DEFINE modu_rec_setup_language RECORD LIKE language.* #moved to module scope
	#	DEFINE modu_rec_setup_rmsparm RECORD LIKE rmsparm.* #moved to module scope
	#	DEFINE modu_rec_setup_kandoooption RECORD LIKE kandoooption.* #moved to module scope
	#	DEFINE modu_arr_rec_setup_company DYNAMIC ARRAY OF t_rec_company_c_n_c_t
	#array[200] of record
	#   cmpy_code LIKE company.cmpy_code,
	#   name_text LIKE company.name_text,
	#   city_text LIKE company.city_text,
	#   tele_text LIKE company.tele_text
	#END RECORD
	#DEFINE where_part CHAR(500)#moved to local scope
	#DEFINE query_text CHAR(900)#moved to local scope
	#	DEFINE glob_idx  SMALLINT #moved to local scope

	#	DEFINE glob_ans CHAR(1) not used
END GLOBALS 

############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_rec_setup_currency RECORD LIKE currency.* 
DEFINE modu_rec_setup_country RECORD LIKE country.* 
DEFINE modu_rec_setup_language RECORD LIKE language.* 
DEFINE modu_rec_setup_rmsparm RECORD LIKE rmsparm.* 
DEFINE modu_rec_setup_kandoooption RECORD LIKE kandoooption.* 
DEFINE modu_arr_rec_setup_company DYNAMIC ARRAY OF t_rec_company_c_n_c_c_t_t_a_c_m #t_rec_company_c_n_c_t 

FUNCTION GZC_whenever_sqlerror ()
	# this code instanciates the default sql errors handling for all the code lines below this function
	# it is a compiler preprocessor. It is not necessary to execute that function
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
END FUNCTION
 
###########################################################################
# MAIN
#
#
###########################################################################
MAIN 

	CALL setModuleId("GZC") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	-- CALL init_g_gl() #init g/gl general ledger module #KD-2128

	LET gl_setuprec.ui_mode = ui_on #no ui FOR sub-modules (silent mode) 

	OPEN WINDOW G130 with FORM "G130" 
	CALL windecoration_g("G130") --populate WINDOW FORM elements 

	#CALL authenticate(getModuleId())
	#   WHILE select_cmpy()
	CALL maintain_cmpy() 
	#   END WHILE
	CLOSE WINDOW G130 
END MAIN 
###########################################################################
# END MAIN
###########################################################################


###########################################################################
# FUNCTION select_cmpy()
#
#
###########################################################################
FUNCTION select_cmpy() 
	DEFINE l_query_text STRING #varchar(500) 
	DEFINE l_where_part STRING #varchar(500) 
	DEFINE l_msgresp LIKE language.yes_flag 

	CLEAR FORM 
	MESSAGE kandoomsg2("U",1001,"") #1001 Enter Selection Criteria;  OK TO Continue.
	CONSTRUCT BY NAME l_where_part ON 
		company.cmpy_code, 
		company.name_text, 
		company.city_text, 
		company.tele_text 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","GZC","companyQuery") 
			--ERROR kandoomsg2("U",1002,"")	#1001 Enter Selection Criteria;  OK TO Continue.

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET l_query_text = NULL 
	ELSE 
		LET l_query_text = 
			" SELECT * ", 
			" FROM company ", 
			" WHERE cmpy_code >= \" \" AND ", 
			l_where_part clipped, 
			" ORDER BY cmpy_code " 
	END IF 
	{
	   PREPARE choice FROM query_text
	   DECLARE c_ware CURSOR FOR choice
	   LET glob_idx = 0
	   FOREACH c_ware INTO glob_rec_company_setup.*
	      LET glob_idx = glob_idx + 1
	      LET modu_arr_rec_setup_company[glob_idx].cmpy_code = glob_rec_company_setup.cmpy_code
	      LET modu_arr_rec_setup_company[glob_idx].name_text = glob_rec_company_setup.name_text
	      LET modu_arr_rec_setup_company[glob_idx].city_text = glob_rec_company_setup.city_text
	      LET modu_arr_rec_setup_company[glob_idx].tele_text = glob_rec_company_setup.tele_text
	      IF glob_idx = 180 THEN
	         ERROR kandoomsg2("U",6100,glob_idx)
	#First glob_idx records selected
	         EXIT FOREACH
	      END IF
	   END FOREACH
	   ERROR kandoomsg2("U",9113,glob_idx)
	#9113 glob_idx records selected
	   RETURN TRUE
	}
	RETURN l_query_text 
END FUNCTION 


############################################################
# FUNCTION maintain_cmpy()
#
#
############################################################
FUNCTION maintain_cmpy() 
	DEFINE l_query_text STRING #varchar(500) 
	DEFINE l_idx SMALLINT 
--	DEFINE l_msgresp LIKE language.yes_flag 

	CALL db_company_get_arr_c_n_c_c_t_t_a_c_m(filter_query_off,null) RETURNING modu_arr_rec_setup_company 

--	IF modu_arr_rec_setup_company IS NULL THEN 
--		LET l_idx = 1 
--		INITIALIZE modu_arr_rec_setup_company[l_idx].* TO NULL 
--	END IF 
	
	MESSAGE kandoomsg2("U",1003,"") #1003 F1 TO Add; F2 TO Delete; ENTER on line TO edit.
	#INPUT ARRAY modu_arr_rec_setup_company WITHOUT DEFAULTS FROM sr_company.* ATTRIBUTE(UNBUFFERED)

	CALL display_current_user() #currently logged in user details 

	DISPLAY ARRAY modu_arr_rec_setup_company TO sr_company.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","GZC","companyList") 

		BEFORE ROW 
			LET l_idx = arr_curr() 

			LET glob_rec_company_setup.cmpy_code = modu_arr_rec_setup_company[l_idx].cmpy_code #do we really NEED these 4 LET statements ? 
			LET glob_rec_company_setup.name_text = modu_arr_rec_setup_company[l_idx].name_text 
			LET glob_rec_company_setup.city_text = modu_arr_rec_setup_company[l_idx].city_text 
			LET glob_rec_company_setup.tele_text = modu_arr_rec_setup_company[l_idx].tele_text 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER" 
			LET l_query_text = select_cmpy() 
			IF l_query_text IS NULL THEN 
				CALL db_company_get_arr_c_n_c_c_t_t_a_c_m(filter_query_off,null) RETURNING modu_arr_rec_setup_company 
			ELSE 
				CALL db_company_get_arr_c_n_c_c_t_t_a_c_m(filter_query_select,l_query_text) RETURNING modu_arr_rec_setup_company 
			END IF 

		ON ACTION ("EDIT","ACCEPT","DOUBLECLICK") 
			IF glob_rec_company_setup.cmpy_code IS NOT NULL THEN 
				CALL company_edit(l_idx) 
				LET modu_arr_rec_setup_company[l_idx].cmpy_code = glob_rec_company_setup.cmpy_code 
				LET modu_arr_rec_setup_company[l_idx].name_text = glob_rec_company_setup.name_text 
				LET modu_arr_rec_setup_company[l_idx].city_text = glob_rec_company_setup.city_text 
				LET modu_arr_rec_setup_company[l_idx].tele_text = glob_rec_company_setup.tele_text 
				#DISPLAY modu_arr_rec_setup_company[l_idx].* TO sr_company[scrn].*
			END IF 

			CALL db_company_get_arr_c_n_c_c_t_t_a_c_m(filter_query_off,null) RETURNING modu_arr_rec_setup_company 

		ON ACTION "NEW" 
			CALL company_new() 
			LET modu_arr_rec_setup_company[l_idx].cmpy_code = glob_rec_company_setup.cmpy_code 
			LET modu_arr_rec_setup_company[l_idx].name_text = glob_rec_company_setup.name_text 
			LET modu_arr_rec_setup_company[l_idx].city_text = glob_rec_company_setup.city_text 
			LET modu_arr_rec_setup_company[l_idx].tele_text = glob_rec_company_setup.tele_text 

			CALL db_company_get_arr_c_n_c_c_t_t_a_c_m(filter_query_off,null) RETURNING modu_arr_rec_setup_company 

		ON ACTION "RESET POSTSTATUS" #this option should only be available for the company kandoo-admin
			BEGIN WORK
				DELETE FROM poststatus WHERE cmpy_code = glob_rec_company_setup.cmpy_code
				IF add_poststatus() THEN
				COMMIT WORK 
			END IF 

		ON ACTION "DELETE" 
			IF glob_rec_company_setup.cmpy_code IS NOT NULL THEN 
				CALL company_delete() 
			END IF 

			CALL db_company_get_arr_c_n_c_c_t_t_a_c_m(filter_query_off,null) RETURNING modu_arr_rec_setup_company 


			#      BEFORE FIELD name_text
			#         IF glob_rec_company_setup.cmpy_code IS NOT NULL THEN
			#            CALL company_edit()
			#            LET modu_arr_rec_setup_company[l_idx].cmpy_code = glob_rec_company_setup.cmpy_code
			#            LET modu_arr_rec_setup_company[l_idx].name_text = glob_rec_company_setup.name_text
			#            LET modu_arr_rec_setup_company[l_idx].city_text  = glob_rec_company_setup.city_text
			#            LET modu_arr_rec_setup_company[l_idx].tele_text = glob_rec_company_setup.tele_text
			#            --huho DISPLAY modu_arr_rec_setup_company[l_idx].* TO sr_company[scrn].*
			#
			#         END IF
			#         NEXT FIELD cmpy_code

			#      BEFORE DELETE
			#         IF glob_rec_company_setup.cmpy_code IS NOT NULL THEN
			#            CALL company_delete()
			#            EXIT INPUT
			#         END IF



			#			BEFORE INSERT
			#         CALL company_new()
			#         LET modu_arr_rec_setup_company[l_idx].cmpy_code = glob_rec_company_setup.cmpy_code
			#         LET modu_arr_rec_setup_company[l_idx].name_text = glob_rec_company_setup.name_text
			#         LET modu_arr_rec_setup_company[l_idx].city_text  = glob_rec_company_setup.city_text
			#         LET modu_arr_rec_setup_company[l_idx].tele_text = glob_rec_company_setup.tele_text
			--huho DISPLAY modu_arr_rec_setup_company[l_idx].* TO sr_company[scrn].*


			#ON KEY (f9)
			#	CALL company_new()  --huho added TO also modify kandoooptions (contact module security VALUES)

			#on action "editkandoooption"
			#	CALL company_new()  --huho added TO also modify kandoooptions (contact module security VALUES)

			#      ON KEY (control-w)
			#         CALL kandoohelp("")
	END DISPLAY 
	##############################

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 
END FUNCTION 
############################################################
# END FUNCTION maintain_cmpy()
############################################################


############################################################
# FUNCTION display_current_user()
#
#
############################################################
FUNCTION display_current_user() 
	DISPLAY glob_rec_kandoouser.sign_on_code TO current_sign_on_code 
	DISPLAY glob_rec_kandoouser.name_text TO current_name_text 
	DISPLAY glob_rec_kandoouser.cmpy_code TO current_cmpy_code 
	DISPLAY db_company_get_name_text(ui_off,glob_rec_kandoouser.cmpy_code) TO current_cmpy_name 
	DISPLAY glob_rec_kandoouser.acct_mask_code TO current_account_mask_code 
END FUNCTION 
############################################################
# END FUNCTION display_current_user()
############################################################


############################################################
# FUNCTION company_new()
#
#
############################################################
# Create new company
FUNCTION company_new() 
	DEFINE l_load_file STRING 
	DEFINE l_counter SMALLINT 


	OPEN WINDOW G131 with FORM "G131" 
	CALL windecoration_g("G131") --populate WINDOW FORM elements 

	IF glob_rec_company_setup.country_code IS NOT NULL THEN 
		CALL comboList_state("state_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,glob_rec_company_setup.country_code,COMBO_NULL_SPACE) 
	ELSE 
		CALL comboList_state("state_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_SPACE) 
	END IF 

	MESSAGE kandoomsg2("G",1069,"")#1069 Enter Company Details; OK TO Continue
	INPUT BY NAME 
		glob_rec_company_setup.cmpy_code, 
		glob_rec_company_setup.name_text, 
		glob_rec_company_setup.addr1_text, 
		glob_rec_company_setup.addr2_text, 
		glob_rec_company_setup.city_text, 
		glob_rec_company_setup.state_code, 
		glob_rec_company_setup.post_code, 
		glob_rec_company_setup.country_code,

		glob_rec_company_setup.curr_code,
		glob_rec_company_setup.language_code,

		glob_rec_company_setup.tele_text,
		glob_rec_company_setup.telex_text, 
		glob_rec_company_setup.mobile_phone,
		glob_rec_company_setup.fax_text, 
		glob_rec_company_setup.email, 

		glob_rec_company_setup.vat_code, 
		glob_rec_company_setup.vat_div_code,
		glob_rec_company_setup.tax_text, 

		glob_rec_company_setup.com1_text, 
		glob_rec_company_setup.com2_text 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GZC","companyNew") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield(country_code) 
			LET glob_rec_company_setup.country_code = show_country() 
			DISPLAY BY NAME glob_rec_company_setup.country_code 
			NEXT FIELD country_code 

		ON ACTION "LOOKUP" infield(curr_code) 
			LET glob_rec_company_setup.curr_code = show_curr(glob_rec_kandoouser.cmpy_code) 
			DISPLAY BY NAME glob_rec_company_setup.curr_code 
			NEXT FIELD curr_code 

		ON ACTION "LOOKUP" infield(language_code) 
			LET glob_rec_company_setup.language_code = show_language() 
			DISPLAY BY NAME glob_rec_company_setup.language_code 
			NEXT FIELD language_code 

		AFTER FIELD cmpy_code 
			IF glob_rec_company_setup.cmpy_code IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 		#9102 Value must be entered
				NEXT FIELD cmpy_code 
			END IF 

			SELECT count(*) INTO l_counter FROM company 
			WHERE cmpy_code = glob_rec_company_setup.cmpy_code 
			IF l_counter > 0 THEN 
				ERROR kandoomsg2("U",9104,"") 			#9104 This RECORD already exists
				NEXT FIELD cmpy_code 
			END IF 

		AFTER FIELD country_code 
			IF glob_rec_company_setup.country_code IS NOT NULL THEN 
				SELECT * INTO modu_rec_setup_country.* FROM country 

				WHERE country_code = glob_rec_company_setup.country_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("U",9105,"")			#9105 RECORD NOT found; Try Window.
					NEXT FIELD country_code 
				END IF 

				DISPLAY modu_rec_setup_country.country_text TO country.country_text 

				IF glob_rec_company_setup.country_code IS NOT NULL THEN 
					CALL comboList_state("state_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,glob_rec_company_setup.country_code,COMBO_NULL_SPACE) 
				ELSE 
					CALL comboList_state("state_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_SPACE) 
				END IF 
			END IF 

		AFTER FIELD curr_code 
			IF glob_rec_company_setup.curr_code IS NULL THEN 
				ERROR kandoomsg2("U",9102,"")			#9102 Value must be entered
				NEXT FIELD curr_code 
			END IF 
			
			SELECT * INTO modu_rec_setup_currency.* FROM currency 
			WHERE currency_code = glob_rec_company_setup.curr_code 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("U",9105,"")		#9105 RECORD NOT found; Try Window.
				NEXT FIELD curr_code 
			END IF 
			DISPLAY modu_rec_setup_currency.desc_text TO currency.desc_text 

		AFTER FIELD language_code 
			IF glob_rec_company_setup.language_code IS NOT NULL THEN 
				SELECT * INTO modu_rec_setup_language.* FROM language 
				WHERE language_code = glob_rec_company_setup.language_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("U",9105,"") #9105 RECORD NOT found; Try Window.
					NEXT FIELD language_code 
				END IF 
				DISPLAY modu_rec_setup_language.language_text TO language.language_text 

			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				INITIALIZE glob_rec_company_setup.* TO NULL 
				EXIT INPUT 
			END IF 
			IF glob_rec_company_setup.cmpy_code IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 			#9102 Value must be entered
				NEXT FIELD cmpy_code 
			END IF 
			IF glob_rec_company_setup.country_code IS NOT NULL THEN 
				SELECT * INTO modu_rec_setup_country.* FROM country 
				WHERE country_code = glob_rec_company_setup.country_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("U",9105,"") 				#9105 RECORD NOT found; Try Window.
					NEXT FIELD country_code 
				END IF 
				DISPLAY modu_rec_setup_country.country_text TO country.country_text 

			END IF 
			IF glob_rec_company_setup.curr_code IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 			#9102 Value must be entered
				NEXT FIELD curr_code 
			END IF 

			SELECT * INTO modu_rec_setup_currency.* FROM currency 
			WHERE currency_code = glob_rec_company_setup.curr_code 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("U",9105,"") 			#9105 RECORD NOT found; Try Window.
				NEXT FIELD curr_code 
			END IF 

			IF glob_rec_company_setup.language_code IS NOT NULL THEN 
				SELECT * INTO modu_rec_setup_language.* FROM language 
				WHERE language_code = glob_rec_company_setup.language_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("U",9105,"") 				#9105 RECORD NOT found; Try Window.
					NEXT FIELD language_code 
				END IF 
				
				DISPLAY modu_rec_setup_language.language_text TO language.language_text 

			END IF 
	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		CLOSE WINDOW g131 
		RETURN 
	END IF 

	BEGIN WORK 
		LET glob_rec_company_setup.country_code = modu_rec_setup_country.country_code --@db-patch_2020_10_04--
		INSERT INTO company VALUES (glob_rec_company_setup.*) 
		IF status THEN 
			ROLLBACK WORK 
			ERROR kandoomsg2("G", 9508, "")	#9508 Unable TO add company - Try again
			SLEEP 3 
			CLOSE WINDOW g131 
			RETURN 
		END IF 

		IF get_debug() = true THEN 
			DISPLAY "########### GZC - Create new company record ################" 
				DISPLAY "Count new companies rows in rmsparm=", db_rmsparm_get_count_cmpy(glob_rec_company_setup.cmpy_code) 
				DISPLAY "Count current user rows in rmsparm=", db_rmsparm_get_count() 
				DISPLAY "Count ALL rows in rmsparm=", db_rmsparm_get_count_all() 
				DISPLAY "glob_rec_kandoouser.cmpy_code = ", glob_rec_kandoouser.cmpy_code 
			END IF 

			SELECT * INTO modu_rec_setup_rmsparm.* FROM rmsparm 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

			IF status = NOTFOUND THEN 
				INITIALIZE modu_rec_setup_rmsparm.* TO NULL 
			END IF 
			LET modu_rec_setup_rmsparm.cmpy_code = glob_rec_company_setup.cmpy_code 
			LET modu_rec_setup_rmsparm.next_report_num = 1 
			INSERT INTO rmsparm VALUES (modu_rec_setup_rmsparm.*) 
			IF status THEN 
				ROLLBACK WORK 
				
				ERROR kandoomsg2("G", 9508, "") #9508 Unable TO add company - Try again
				SLEEP 3 
				CLOSE WINDOW g131 
				RETURN 
			END IF 
			
			## Add kandoooption entry
			IF glob_rec_company_setup.cmpy_code != '99' THEN #'99'must be a reserved TABLE ROW - something LIKE a template ? 
				DELETE FROM kandoooption 
				WHERE cmpy_code = glob_rec_company_setup.cmpy_code 
			
				DECLARE c_kandoooption CURSOR FOR 
				SELECT * FROM kandoooption 
				WHERE cmpy_code = '99' 
			
				FOREACH c_kandoooption INTO modu_rec_setup_kandoooption.* 
					LET modu_rec_setup_kandoooption.cmpy_code = glob_rec_company_setup.cmpy_code 
					INSERT INTO kandoooption VALUES (modu_rec_setup_kandoooption.*) 
				END FOREACH 
			
			END IF 
			
			IF NOT add_poststatus() THEN 
				ROLLBACK WORK 				
				ERROR kandoomsg2("G", 9508, "") #9508 Unable TO add company - Try again
				SLEEP 3 
				CLOSE WINDOW G131 
				RETURN 
			END IF 
		COMMIT WORK 
		
		CALL upd_module() 
		
		CLOSE WINDOW G131 

		#huho 09.08.2017 Feature request by Ali
		#Add import lib_db_groupinfo -> FUNCTION import_groupinfo()
		#MFR #169617871: Import COA WHEN creating a new company

		LET glob_rec_company_setup.cmpy_code = glob_rec_company_setup.cmpy_code 

		LET l_load_file = "unl/groupinfo-",glob_rec_company_setup.country_code CLIPPED,".unl" 
		IF os.path.exists(l_load_file) THEN 
			IF fgl_winquestion("Import Chart of Accounts?", "Do you want TO import chart of accounts FOR this company ?", "Yes", "Yes|No", "question", 1) = "Yes" THEN 
				CALL import_groupinfo(ui_off,glob_rec_company_setup.cmpy_code) 
				#CALL db_coa_import(glob_rec_company_setup.cmpy_code)
				CALL db_coa_import_for_new_company(glob_rec_company_setup.cmpy_code) 
			END IF 
		END IF 

		LET l_load_file = "unl/tax-",glob_rec_company_setup.country_code CLIPPED,".unl" 
		IF os.path.exists(l_load_file) THEN 
			IF fgl_winquestion("Import local VAT rates?", "Do you want TO import VAT local rates FOR this company ?", "Yes", "Yes|No", "question", 1) = "Yes" THEN 
				CALL import_tax(UI_OFF,glob_rec_company_setup.cmpy_code) 
			END IF 
		END IF 

		LET l_load_file = "unl/journal-",glob_rec_company_setup.country_code CLIPPED,".unl" 
		IF os.path.exists(l_load_file) THEN 
			IF fgl_winquestion("Import Ledger Journals ?", "Do you want TO import Ledger Journals FOR this company ?", "Yes", "Yes|No", "question", 1) = "Yes" THEN 
				CALL import_journal(false, glob_rec_company_setup.cmpy_code) --false = silent MODE 
			END IF 
		END IF 

		LET l_load_file = "unl/holdpay-",glob_rec_company_setup.country_code CLIPPED,".unl" 
		IF os.path.exists(l_load_file) THEN 
			IF fgl_winquestion("Import Hold Payment Reasons ?", "Do you want TO import Hold Payment Reasons FOR this company ?", "Yes", "Yes|No", "question", 1) = "Yes" THEN 
				CALL import_holdpay(glob_rec_company_setup.cmpy_code) 
			END IF 
		END IF 
		
END FUNCTION 
############################################################
# END FUNCTION company_new()
############################################################


############################################################
# FUNCTION company_edit()
#
#
############################################################
FUNCTION company_edit(p_idx) 
	DEFINE p_idx SMALLINT 
	DEFINE l_country_code LIKE country.country_code 
	DEFINE l_curr_code LIKE currency.currency_code 
	DEFINE l_language_code LIKE language.language_code 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW G131 with FORM "G131" 
	CALL windecoration_g("G131") --populate WINDOW FORM elements 

	MESSAGE kandoomsg2("G",1069,"") 	#1069 Enter Company Details; OK TO Continue

	SELECT company.* INTO glob_rec_company_setup.* FROM company 
	WHERE cmpy_code = modu_arr_rec_setup_company[p_idx].cmpy_code 

	SELECT * INTO modu_rec_setup_country.* FROM country 
	WHERE country_code = glob_rec_company_setup.country_code 
	IF status = NOTFOUND THEN 
		LET modu_rec_setup_country.country_text = NULL 
	END IF 

	SELECT * INTO modu_rec_setup_currency.* FROM currency 
	WHERE currency_code = glob_rec_company_setup.curr_code 
	IF status = NOTFOUND THEN 
		LET modu_rec_setup_currency.desc_text = NULL 
	END IF 

	SELECT * INTO modu_rec_setup_language.* FROM language 
	WHERE language_code = glob_rec_company_setup.language_code 
	IF status = NOTFOUND THEN 
		LET modu_rec_setup_language.language_text = NULL 
	END IF 

	IF glob_rec_company_setup.country_code IS NOT NULL THEN 
		CALL comboList_state("state_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,glob_rec_company_setup.country_code,COMBO_NULL_SPACE) 
	ELSE 
		CALL comboList_state("state_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_SPACE) 
	END IF 

	DISPLAY BY NAME 
		glob_rec_company_setup.cmpy_code,
		glob_rec_company_setup.name_text, 
		glob_rec_company_setup.addr1_text, 
		glob_rec_company_setup.addr2_text, 
		glob_rec_company_setup.city_text, 
		glob_rec_company_setup.state_code, 
		glob_rec_company_setup.post_code, 
		
		glob_rec_company_setup.country_code, 
		modu_rec_setup_country.country_text,
		 
		glob_rec_company_setup.curr_code,		 
		modu_rec_setup_currency.desc_text,
		 
		glob_rec_company_setup.language_code, 
		modu_rec_setup_language.language_text, 
		
		glob_rec_company_setup.tele_text, 
		glob_rec_company_setup.fax_text, 
		glob_rec_company_setup.telex_text, 
		
		glob_rec_company_setup.vat_code, 
		glob_rec_company_setup.tax_text, 
		glob_rec_company_setup.com1_text, 
		glob_rec_company_setup.com2_text 
	
		INPUT BY NAME 
			glob_rec_company_setup.name_text, 
			glob_rec_company_setup.addr1_text, 
			glob_rec_company_setup.addr2_text, 
			glob_rec_company_setup.city_text, 
			glob_rec_company_setup.state_code, 
			glob_rec_company_setup.post_code, 
			glob_rec_company_setup.country_code, 
			glob_rec_company_setup.curr_code, 
			glob_rec_company_setup.language_code, 
			glob_rec_company_setup.tele_text, 
			glob_rec_company_setup.fax_text, 
			glob_rec_company_setup.telex_text, 
			glob_rec_company_setup.vat_code, 
			glob_rec_company_setup.tax_text, 
			glob_rec_company_setup.com1_text, 
			glob_rec_company_setup.com2_text WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GZC","companyEdit") 
			CALL comboList_state("state_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,glob_rec_company_setup.country_code,COMBO_NULL_SPACE) 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield(country_code) 

			LET l_country_code = show_country() 
			IF l_country_code IS NOT NULL THEN 
				LET glob_rec_company_setup.country_code = l_country_code 
			END IF 

			DISPLAY BY NAME glob_rec_company_setup.country_code 

			NEXT FIELD country_code 


		ON ACTION "LOOKUP" infield(curr_code) 
			#LET glob_rec_company_setup.curr_code = show_curr(glob_rec_kandoouser.cmpy_code)
			LET l_curr_code = show_curr(glob_rec_kandoouser.cmpy_code) 

			IF l_curr_code IS NOT NULL THEN 
				LET glob_rec_company_setup.curr_code = l_curr_code 
			END IF 

			DISPLAY BY NAME glob_rec_company_setup.curr_code 

			NEXT FIELD curr_code 

		ON ACTION "LOOKUP" infield(language_code) 
			#LET glob_rec_company_setup.language_code = show_language()
			LET l_language_code = show_language() 
			
			IF l_language_code IS NOT NULL THEN 
				LET glob_rec_company_setup.language_code = l_language_code 
			END IF 
			DISPLAY BY NAME glob_rec_company_setup.language_code 

			NEXT FIELD language_code 
			{
			         CASE
			            WHEN infield(country_code)
			#changed - OTHERWISE NULL RETURN will overwrite existing value
			#LET glob_rec_company_setup.country_code = show_country()
			               LET l_country_code = show_country()
			               IF l_country_code IS NOT NULL THEN
			               	LET glob_rec_company_setup.country_code = l_country_code
			               END IF

			               DISPLAY BY NAME glob_rec_company_setup.country_code
			--huho
			               NEXT FIELD country_code
			            WHEN infield(curr_code)
			#LET glob_rec_company_setup.curr_code = show_curr(glob_rec_kandoouser.cmpy_code)
			            	LET l_curr_code = show_curr(glob_rec_kandoouser.cmpy_code)

			               IF l_curr_code IS NOT NULL THEN
			               	LET glob_rec_company_setup.curr_code = l_curr_code
			               END IF
			               DISPLAY BY NAME glob_rec_company_setup.curr_code
			--huho
			               NEXT FIELD curr_code
			            WHEN infield(language_code)
			#LET glob_rec_company_setup.language_code = show_language()
											LET l_language_code = show_language()
											IF l_language_code IS NOT NULL THEN
			               		LET glob_rec_company_setup.language_code = l_language_code
			               	END IF
			               DISPLAY BY NAME glob_rec_company_setup.language_code
			--huho
			               NEXT FIELD language_code
			         END CASE
			}
		AFTER FIELD country_code 
			IF glob_rec_company_setup.country_code IS NOT NULL THEN 
				SELECT * INTO modu_rec_setup_country.* FROM country 
				WHERE country_code = glob_rec_company_setup.country_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("U",9105,"") 			#9105 RECORD NOT found; Try Window.
					NEXT FIELD country_code 
				END IF 
			
				DISPLAY modu_rec_setup_country.country_text TO country.country_text 
				CALL comboList_state("state_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,glob_rec_company_setup.country_code,COMBO_NULL_SPACE) 
			END IF 
			
		AFTER FIELD curr_code 
			IF glob_rec_company_setup.curr_code IS NULL THEN 
				ERROR kandoomsg2("U",9102,"")			#9102 Value must be entered
				NEXT FIELD curr_code 
			END IF 
			
			SELECT * INTO modu_rec_setup_currency.* FROM currency 
			WHERE currency_code = glob_rec_company_setup.curr_code 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("U",9105,"") 		#9105 RECORD NOT found; Try Window.
				NEXT FIELD curr_code 
			END IF 
			DISPLAY modu_rec_setup_currency.desc_text TO currency.desc_text 

		AFTER FIELD language_code 
			IF glob_rec_company_setup.language_code IS NOT NULL THEN 
				SELECT * INTO modu_rec_setup_language.* FROM language 
				WHERE language_code = glob_rec_company_setup.language_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("U",9105,"") 			#9105 RECORD NOT found; Try Window.
					NEXT FIELD language_code 
				END IF 
				DISPLAY modu_rec_setup_language.language_text TO language.language_text 

			END IF 

		AFTER FIELD vat_code 
			IF glob_rec_company_setup.vat_code IS NOT NULL THEN
				IF NOT validate_vat_registration_code(glob_rec_company_setup.vat_code,glob_rec_company_setup.country_code) THEN 
					ERROR kandoomsg2("G",9538,"") 				#Invalid ABN. Enter valid ABN OR leave blank
					NEXT FIELD vat_code 
				END IF 
			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 
			
			IF glob_rec_company_setup.country_code IS NOT NULL THEN 
				SELECT * INTO modu_rec_setup_country.* FROM country 
				WHERE country_code = glob_rec_company_setup.country_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("U",9105,"") 				#9105 RECORD NOT found; Try Window.
					NEXT FIELD country_code 
				END IF 
				DISPLAY modu_rec_setup_country.country_text TO country.country_text 

			END IF 
			
			IF glob_rec_company_setup.curr_code IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 			#9102 Value must be entered
				NEXT FIELD curr_code 
			END IF 
			
			SELECT * INTO modu_rec_setup_currency.* FROM currency 
			WHERE currency_code = glob_rec_company_setup.curr_code 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("U",9105,"") 			#9105 RECORD NOT found; Try Window.
				NEXT FIELD curr_code 
			END IF 
			
			IF glob_rec_company_setup.language_code IS NOT NULL THEN 
				SELECT * INTO modu_rec_setup_language.* FROM language 
				WHERE language_code = glob_rec_company_setup.language_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("U",9105,"") 				#9105 RECORD NOT found; Try Window.
					NEXT FIELD language_code 
				END IF 
				DISPLAY modu_rec_setup_language.language_text TO language.language_text 

			END IF 

			#      ## Add kandoooption entry  --copy/paste add by HuHo.. we have no docs on this AND no test data incl. the default 99 company RECORD data
			#			IF glob_rec_company_setup.cmpy_code != '99' THEN
			#				IF fgl_winquestion("Re-Initialise Default kandoooptions (temp hack until we know more)", "Re-Initialise Default kandoooptions (temp hack until we know more)\nCurrently held kandoooption table data will be deleted\nand the company 99 data will be used!\n this IS may be just a temp hack until we know more", "Yes", "Yes|No", "info", 1) = "Yes"  THEN
			#
			#         DELETE FROM kandoooption WHERE cmpy_code = glob_rec_company_setup.cmpy_code
			#         DECLARE c_kandoooption CURSOR FOR
			#         SELECT * FROM kandoooption
			#          WHERE cmpy_code = '99'
			#         FOREACH c_kandoooption INTO modu_rec_setup_kandoooption.*
			#            LET modu_rec_setup_kandoooption.cmpy_code = glob_rec_company_setup.cmpy_code
			#            INSERT INTO kandoooption VALUES (modu_rec_setup_kandoooption.*)
			#         END FOREACH
			#      	END IF
			#      END IF


	END INPUT 
	######################################

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		CLOSE WINDOW G131 
		RETURN 
	END IF 

	LET glob_rec_company_setup.country_code = modu_rec_setup_country.country_code --@db-patch_2020_10_04--
	UPDATE company 
	SET * = glob_rec_company_setup.* 
	WHERE cmpy_code = glob_rec_company_setup.cmpy_code 

	LET modu_arr_rec_setup_company[p_idx].name_text = glob_rec_company_setup.name_text 
	LET modu_arr_rec_setup_company[p_idx].city_text = glob_rec_company_setup.city_text 
	LET modu_arr_rec_setup_company[p_idx].tele_text = glob_rec_company_setup.tele_text 
	
	CALL upd_module() 
	
	CLOSE WINDOW G131 
	
END FUNCTION 
############################################################
# END FUNCTION company_edit()
############################################################


############################################################
# FUNCTION company_delete()
#
#
############################################################
FUNCTION company_delete() 
	DEFINE l_msgresp LIKE language.yes_flag 

	ERROR kandoomsg2("G",8029,"") #8029 Confirm TO delete company?
	IF l_msgresp = "Y" THEN 
		BEGIN WORK 
			DELETE FROM company 
			WHERE cmpy_code = glob_rec_company_setup.cmpy_code 
			
			DELETE FROM kandoooption 
			WHERE cmpy_code = glob_rec_company_setup.cmpy_code 
			
			DELETE FROM poststatus 
			WHERE cmpy_code = glob_rec_company_setup.cmpy_code 
		COMMIT WORK 
	END IF 
END FUNCTION 
############################################################
# END FUNCTION company_delete()
############################################################


############################################################
# FUNCTION upd_module() 
#
#
############################################################
FUNCTION upd_module() 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW G214 with FORM "G214" 
	CALL windecoration_g("G214") --populate WINDOW FORM elements 

	IF glob_rec_company_setup.module_text IS NULL THEN
		LET glob_rec_company_setup.module_text = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	END IF
	 
	ERROR kandoomsg2("G",1069,"") #1069 Enter Company Details; OK TO Continue

	DISPLAY BY NAME 
		glob_rec_company_setup.cmpy_code, 
		glob_rec_company_setup.name_text, 
		glob_rec_company_setup.module_text 

	INPUT BY NAME glob_rec_company_setup.module_text WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GZC","modulesInstalled") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null)
			 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 
	END INPUT 
	
	UPDATE company 
	SET module_text = glob_rec_company_setup.module_text 
	WHERE cmpy_code = glob_rec_company_setup.cmpy_code 
	
	CLOSE WINDOW G214 
	
END FUNCTION 
############################################################
# END FUNCTION upd_module() 
############################################################


############################################################
# FUNCTION add_poststatus()
#
#
############################################################
FUNCTION add_poststatus() 
	DEFINE l_rec_poststatus RECORD LIKE poststatus.* 

	LET l_rec_poststatus.cmpy_code = glob_rec_company_setup.cmpy_code 
	LET l_rec_poststatus.module_code = " " 
	LET l_rec_poststatus.user_code = " " 
	LET l_rec_poststatus.status_code = 99 
	LET l_rec_poststatus.status_text = "Initial Load - no post yet" 
	LET l_rec_poststatus.status_time = CURRENT year TO second 
	LET l_rec_poststatus.error_status = 0 
	LET l_rec_poststatus.error_text = " " 
	LET l_rec_poststatus.error_time = CURRENT year TO second 
	LET l_rec_poststatus.jour_num = 0 
	LET l_rec_poststatus.error1_text = " " 
	LET l_rec_poststatus.error2_text = " " 
	LET l_rec_poststatus.error3_text = " " 
	LET l_rec_poststatus.error4_text = " " 
	LET l_rec_poststatus.post_running_flag = "N" 
	LET l_rec_poststatus.post_year_num = 0 
	LET l_rec_poststatus.post_period_num = 0 
	LET l_rec_poststatus.online_ind = "N" 
	LET l_rec_poststatus.module_code = "AP" 

	INSERT INTO poststatus VALUES (l_rec_poststatus.*) 
	IF status THEN 
		RETURN false 
	END IF 

	LET l_rec_poststatus.module_code = "AR" 
	INSERT INTO poststatus VALUES (l_rec_poststatus.*) 
	IF status THEN 
		RETURN false 
	END IF 

	LET l_rec_poststatus.module_code = "FA" 
	INSERT INTO poststatus VALUES (l_rec_poststatus.*) 
	IF status THEN 
		RETURN false 
	END IF 

	LET l_rec_poststatus.module_code = TRAN_TYPE_INVOICE_IN 
	INSERT INTO poststatus VALUES (l_rec_poststatus.*) 
	IF status THEN 
		RETURN false 
	END IF 

	LET l_rec_poststatus.module_code = "JM" 
	INSERT INTO poststatus VALUES (l_rec_poststatus.*) 
	IF status THEN 
		RETURN false 
	END IF 

	LET l_rec_poststatus.module_code = "PU" 
	INSERT INTO poststatus VALUES (l_rec_poststatus.*) 
	IF status THEN 
		RETURN false 
	END IF 

	RETURN true 
END FUNCTION 
############################################################
# END FUNCTION add_poststatus()
############################################################