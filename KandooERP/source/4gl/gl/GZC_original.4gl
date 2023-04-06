###########################################################################
# This program IS free software; you can redistribute it AND/OR modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2 of the License, OR (at your
# option) any later version.
#
# This program IS distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if NOT, write TO the Free Software Foundation, Inc.,
# 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
###########################################################################


{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module - GZC
# Purpose - adds new companies AND sets up the rms parameters record
#
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS 
	DEFINE glob_rec_rmsparm RECORD LIKE rmsparm.*
END GLOBALS 
############################################################
# MODULE Scope Variables
############################################################
	DEFINE modu_rec_currency RECORD LIKE currency.*
	DEFINE modu_rec_country RECORD LIKE country.*
	DEFINE modu_rec_language RECORD LIKE language.*
	DEFINE modu_rec_kandoooption RECORD LIKE kandoooption.* 
	DEFINE modu_arr_rec_company array[200] OF RECORD 
		cmpy_code LIKE company.cmpy_code, 
		name_text LIKE company.name_text, 
		city_text LIKE company.city_text, 
		tele_text LIKE company.tele_text 
	END RECORD 
	DEFINE modu_where_part CHAR(500) 
	DEFINE modu_query_text CHAR(900) 
	DEFINE modu_idx SMALLINT
	DEFINE modu_counter SMALLINT
	DEFINE modu_ans CHAR(1) 

############################################################
# MAIN
#
#
############################################################
MAIN 
	DEFER interrupt 
	DEFER quit 
	CALL authenticate("GZC") 

	OPEN WINDOW g130 at 2,3 with FORM "G130" 
	attribute (border) 
	WHILE select_cmpy() 
		CALL maintain_cmpy() 
	END WHILE 
	CLOSE WINDOW g130 
END MAIN 


############################################################
# FUNCTION select_cmpy()
#
#
############################################################
FUNCTION select_cmpy()
 
	CLEAR FORM 
	LET msgresp = kandoomsg("U",1001,"") 
	#1001 Enter Selection Criteria;  OK TO Continue.
	CONSTRUCT BY NAME modu_where_part ON company.cmpy_code, 
	company.name_text, 
	company.city_text, 
	company.tele_text 
	attribute(cyan) 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	LET msgresp = kandoomsg("U",1002,"") 
	#1001 Enter Selection Criteria;  OK TO Continue.
	LET modu_query_text = 
	" select * ", 
	" FROM company ", 
	" where cmpy_code >= \" \" AND ", 
	modu_where_part clipped, 
	" ORDER BY cmpy_code " 
	PREPARE choice FROM modu_query_text 
	DECLARE c_ware CURSOR FOR choice 
	LET modu_idx = 0 
	FOREACH c_ware INTO glob_rec_company.* 
		LET modu_idx = modu_idx + 1 
		LET modu_arr_rec_company[modu_idx].cmpy_code = glob_rec_company.cmpy_code 
		LET modu_arr_rec_company[modu_idx].name_text = glob_rec_company.name_text 
		LET modu_arr_rec_company[modu_idx].city_text = glob_rec_company.city_text 
		LET modu_arr_rec_company[modu_idx].tele_text = glob_rec_company.tele_text 
		IF modu_idx = 180 THEN 
			LET msgresp = kandoomsg("U",6100,modu_idx) 
			#First modu_idx records selected
			EXIT FOREACH 
		END IF 
	END FOREACH 
	LET msgresp = kandoomsg("U",9113,modu_idx) 
	#9113 modu_idx records selected
	RETURN true 
END FUNCTION 


############################################################
# FUNCTION maintain_cmpy()
#
#
############################################################
FUNCTION maintain_cmpy() 

	IF modu_idx = 0 THEN 
		LET modu_idx = 1 
		INITIALIZE modu_arr_rec_company[modu_idx].* TO NULL 
	END IF 
	CALL set_count (modu_idx) 
	LET msgresp = kandoomsg("U",1003,"") 
	#1003 F1 TO Add; F2 TO Delete; ENTER on line TO edit.
	INPUT ARRAY modu_arr_rec_company WITHOUT DEFAULTS FROM sr_company.* attributes(UNBUFFERED) 
	#attribute(cyan)
		BEFORE ROW 
			LET modu_idx = arr_curr() 
			#let scrn = scr_line()
			LET glob_rec_company.cmpy_code = modu_arr_rec_company[modu_idx].cmpy_code 
			LET glob_rec_company.name_text = modu_arr_rec_company[modu_idx].name_text 
			LET glob_rec_company.city_text = modu_arr_rec_company[modu_idx].city_text 
			LET glob_rec_company.tele_text = modu_arr_rec_company[modu_idx].tele_text 
		BEFORE FIELD name_text 
			IF glob_rec_company.cmpy_code IS NOT NULL THEN 
				CALL changor() 
				LET modu_arr_rec_company[modu_idx].cmpy_code = glob_rec_company.cmpy_code 
				LET modu_arr_rec_company[modu_idx].name_text = glob_rec_company.name_text 
				LET modu_arr_rec_company[modu_idx].city_text = glob_rec_company.city_text 
				LET modu_arr_rec_company[modu_idx].tele_text = glob_rec_company.tele_text 
				#display modu_arr_rec_company[modu_idx].* TO sr_company[scrn].*
				#   attribute(cyan)
			END IF 
			NEXT FIELD cmpy_code 
		BEFORE DELETE 
			IF glob_rec_company.cmpy_code IS NOT NULL THEN 
				CALL deletor() 
				EXIT INPUT 
			END IF 
		BEFORE INSERT 
			CALL addor() 
			LET modu_arr_rec_company[modu_idx].cmpy_code = glob_rec_company.cmpy_code 
			LET modu_arr_rec_company[modu_idx].name_text = glob_rec_company.name_text 
			LET modu_arr_rec_company[modu_idx].city_text = glob_rec_company.city_text 
			LET modu_arr_rec_company[modu_idx].tele_text = glob_rec_company.tele_text 
			#display modu_arr_rec_company[modu_idx].* TO sr_company[scrn].*
			#   attribute(cyan)
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 
END FUNCTION 


############################################################
# FUNCTION addor()
#
#
############################################################
FUNCTION addor() 

	OPEN WINDOW g131 at 3,5 with FORM "G131" 
	attribute (border) 
	LET msgresp = kandoomsg("G",1069,"") 
	#1069 Enter Company Details; OK TO Continue
	INPUT BY NAME glob_rec_company.cmpy_code, 
	glob_rec_company.name_text, 
	glob_rec_company.addr1_text, 
	glob_rec_company.addr2_text, 
	glob_rec_company.city_text, 
	glob_rec_company.state_code, 
	glob_rec_company.post_code, 
	glob_rec_company.country_code, 
	glob_rec_company.curr_code, 
	glob_rec_company.language_code, 
	glob_rec_company.tele_text, 
	glob_rec_company.fax_text, 
	glob_rec_company.telex_text, 
	glob_rec_company.vat_code, 
	glob_rec_company.tax_text, 
	glob_rec_company.com1_text, 
	glob_rec_company.com2_text 
	attribute(cyan)
	 
		ON ACTION "LOOKUP" infield(country_code) 
					LET glob_rec_company.country_code = show_country() 
					DISPLAY BY NAME glob_rec_company.country_code 
					attribute (cyan) 
					NEXT FIELD country_code 

		ON ACTION "LOOKUP" infield(curr_code) 
					LET glob_rec_company.curr_code = show_curr(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME glob_rec_company.curr_code 
					attribute (cyan) 
					NEXT FIELD curr_code 

		ON ACTION "LOOKUP" infield(language_code) 
					LET glob_rec_company.language_code = show_language() 
					DISPLAY BY NAME glob_rec_company.language_code 
					attribute (cyan) 
					NEXT FIELD language_code 
			
		AFTER FIELD cmpy_code 
			IF glob_rec_company.cmpy_code IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD cmpy_code 
			END IF 
			SELECT count(*) INTO modu_counter FROM company 
			WHERE cmpy_code = glob_rec_company.cmpy_code 
			IF modu_counter > 0 THEN 
				LET msgresp = kandoomsg("U",9104,"") 
				#9104 This record already exists
				NEXT FIELD cmpy_code 
			END IF 
		AFTER FIELD country_code 
			IF glob_rec_company.country_code IS NOT NULL THEN 
				SELECT * INTO modu_rec_country.* FROM country 
				WHERE country_code = glob_rec_company.country_code 
				IF status = NOTFOUND THEN 
					LET msgresp = kandoomsg("U",9105,"") 			#9105 Record NOT found; Try Window.
					NEXT FIELD country_code 
				END IF 
				DISPLAY modu_rec_country.country_text TO country.country_text attribute (cyan) 
			END IF
			 
		AFTER FIELD curr_code 
			IF glob_rec_company.curr_code IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 			#9102 Value must be entered
				NEXT FIELD curr_code 
			END IF 
			SELECT * INTO modu_rec_currency.* FROM currency 
			WHERE currency_code = glob_rec_company.curr_code 
			IF status = NOTFOUND THEN 
				LET msgresp = kandoomsg("U",9105,"") 		#9105 Record NOT found; Try Window.
				NEXT FIELD curr_code 
			END IF 
			
			DISPLAY modu_rec_currency.desc_text TO currency.desc_text 
			attribute (cyan) 
		AFTER FIELD language_code 
			IF glob_rec_company.language_code IS NOT NULL THEN 
				SELECT * INTO modu_rec_language.* FROM language 
				WHERE language_code = glob_rec_company.language_code 
				IF status = NOTFOUND THEN 
					LET msgresp = kandoomsg("U",9105,"") 
					#9105 Record NOT found; Try Window.
					NEXT FIELD language_code 
				END IF 
				DISPLAY modu_rec_language.language_text TO language.language_text 
				attribute (cyan) 
			END IF 
		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				INITIALIZE glob_rec_company.* TO NULL 
				EXIT INPUT 
			END IF 
			IF glob_rec_company.cmpy_code IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD cmpy_code 
			END IF 
			IF glob_rec_company.country_code IS NOT NULL THEN 
				SELECT * INTO modu_rec_country.* FROM country 
				WHERE country_code = glob_rec_company.country_code 
				IF status = NOTFOUND THEN 
					LET msgresp = kandoomsg("U",9105,"") 
					#9105 Record NOT found; Try Window.
					NEXT FIELD country_code 
				END IF 
				DISPLAY modu_rec_country.country_text TO country.country_text 
				attribute (cyan) 
			END IF 
			IF glob_rec_company.curr_code IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD curr_code 
			END IF 
			SELECT * INTO modu_rec_currency.* FROM currency 
			WHERE currency_code = glob_rec_company.curr_code 
			IF status = NOTFOUND THEN 
				LET msgresp = kandoomsg("U",9105,"") 
				#9105 Record NOT found; Try Window.
				NEXT FIELD curr_code 
			END IF 
			IF glob_rec_company.language_code IS NOT NULL THEN 
				SELECT * INTO modu_rec_language.* FROM language 
				WHERE language_code = glob_rec_company.language_code 
				IF status = NOTFOUND THEN 
					LET msgresp = kandoomsg("U",9105,"") 
					#9105 Record NOT found; Try Window.
					NEXT FIELD language_code 
				END IF 
				DISPLAY modu_rec_language.language_text TO language.language_text 
				attribute (cyan) 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		CLOSE WINDOW g131 
		RETURN 
	END IF 
	BEGIN WORK 
		LET glob_rec_company.country_text = modu_rec_country.country_text 
		INSERT INTO company VALUES (glob_rec_company.*) 
		IF status THEN 
			ROLLBACK WORK 
			LET msgresp = kandoomsg("G", 9508, "") 
			#9508 Unable TO add company - Try again
			SLEEP 3 
			CLOSE WINDOW g131 
			RETURN 
		END IF 
		SELECT * INTO glob_rec_rmsparm.* FROM rmsparm 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

		IF status = NOTFOUND THEN 
			INITIALIZE glob_rec_rmsparm.* TO NULL 
		END IF 
		LET glob_rec_rmsparm.cmpy_code = glob_rec_company.cmpy_code 
		LET glob_rec_rmsparm.next_report_num = 1 
		INSERT INTO rmsparm VALUES (glob_rec_rmsparm.*) 
		IF status THEN 
			ROLLBACK WORK 
			#9508 Unable TO add company - Try again
			LET msgresp = kandoomsg("G", 9508, "") 
			SLEEP 3 
			CLOSE WINDOW g131 
			RETURN 
		END IF 
		## Add kandoooption entry
		IF glob_rec_company.cmpy_code != '99' THEN 
			DELETE FROM kandoooption WHERE cmpy_code = glob_rec_company.cmpy_code 
			DECLARE c_kandoooption CURSOR FOR 
			SELECT * FROM kandoooption 
			WHERE cmpy_code = '99' 
			FOREACH c_kandoooption INTO modu_rec_kandoooption.* 
				LET modu_rec_kandoooption.cmpy_code = glob_rec_company.cmpy_code 
				INSERT INTO kandoooption VALUES (modu_rec_kandoooption.*) 
			END FOREACH 
		END IF 
		IF NOT add_poststatus() THEN 
			ROLLBACK WORK 
			#9508 Unable TO add company - Try again
			LET msgresp = kandoomsg("G", 9508, "") 
			SLEEP 3 
			CLOSE WINDOW g131 
			RETURN 
		END IF 
	COMMIT WORK 
	CALL upd_module() 
	CLOSE WINDOW g131 
END FUNCTION 



############################################################
# FUNCTION changor()
#
#
############################################################
FUNCTION changor() 

	OPEN WINDOW g131 at 3,5 with FORM "G131" 
	attributes (border) 
	LET msgresp = kandoomsg("G",1069,"") 
	#1069 Enter Company Details; OK TO Continue
	SELECT company.* INTO glob_rec_company.* FROM company 
	WHERE cmpy_code = modu_arr_rec_company[modu_idx].cmpy_code 
	SELECT * INTO modu_rec_country.* FROM country 
	WHERE country_code = glob_rec_company.country_code 
	IF status = NOTFOUND THEN 
		LET modu_rec_country.country_text = NULL 
	END IF 
	SELECT * INTO modu_rec_currency.* FROM currency 
	WHERE currency_code = glob_rec_company.curr_code 
	IF status = NOTFOUND THEN 
		LET modu_rec_currency.desc_text = NULL 
	END IF 
	SELECT * INTO modu_rec_language.* FROM language 
	WHERE language_code = glob_rec_company.language_code 
	IF status = NOTFOUND THEN 
		LET modu_rec_language.language_text = NULL 
	END IF 
	DISPLAY BY NAME glob_rec_company.name_text, 
	glob_rec_company.addr1_text, 
	glob_rec_company.addr2_text, 
	glob_rec_company.city_text, 
	glob_rec_company.state_code, 
	glob_rec_company.cmpy_code, 
	glob_rec_company.post_code, 
	glob_rec_company.country_code, 
	modu_rec_country.country_text, 
	glob_rec_company.curr_code, 
	modu_rec_currency.desc_text, 
	glob_rec_company.language_code, 
	modu_rec_language.language_text, 
	glob_rec_company.tele_text, 
	glob_rec_company.fax_text, 
	glob_rec_company.telex_text, 
	glob_rec_company.vat_code, 
	glob_rec_company.tax_text, 
	glob_rec_company.com1_text, 
	glob_rec_company.com2_text 
	attribute (cyan) 
	INPUT BY NAME glob_rec_company.name_text, 
	glob_rec_company.addr1_text, 
	glob_rec_company.addr2_text, 
	glob_rec_company.city_text, 
	glob_rec_company.state_code, 
	glob_rec_company.post_code, 
	glob_rec_company.country_code, 
	glob_rec_company.curr_code, 
	glob_rec_company.language_code, 
	glob_rec_company.tele_text, 
	glob_rec_company.fax_text, 
	glob_rec_company.telex_text, 
	glob_rec_company.vat_code, 
	glob_rec_company.tax_text, 
	glob_rec_company.com1_text, 
	glob_rec_company.com2_text WITHOUT DEFAULTS 
	attribute(cyan) 
		ON ACTION "LOOKUP" infield(country_code) 
					LET glob_rec_company.country_code = show_country() 
					DISPLAY BY NAME glob_rec_company.country_code 
					attribute (cyan) 
					NEXT FIELD country_code 

		ON ACTION "LOOKUP" infield(curr_code) 
					LET glob_rec_company.curr_code = show_curr(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME glob_rec_company.curr_code 
					attribute (cyan) 
					NEXT FIELD curr_code 

		ON ACTION "LOOKUP" infield(language_code) 
					LET glob_rec_company.language_code = show_language() 
					DISPLAY BY NAME glob_rec_company.language_code 
					attribute (cyan) 
					NEXT FIELD language_code 

		AFTER FIELD country_code 
			IF glob_rec_company.country_code IS NOT NULL THEN 
				SELECT * INTO modu_rec_country.* FROM country 
				WHERE country_code = glob_rec_company.country_code 
				IF status = NOTFOUND THEN 
					LET msgresp = kandoomsg("U",9105,"") 
					#9105 Record NOT found; Try Window.
					NEXT FIELD country_code 
				END IF 
				DISPLAY modu_rec_country.country_text TO country.country_text 
				attribute (cyan) 
			END IF 
		AFTER FIELD curr_code 
			IF glob_rec_company.curr_code IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD curr_code 
			END IF 
			SELECT * INTO modu_rec_currency.* FROM currency 
			WHERE currency_code = glob_rec_company.curr_code 
			IF status = NOTFOUND THEN 
				LET msgresp = kandoomsg("U",9105,"") 
				#9105 Record NOT found; Try Window.
				NEXT FIELD curr_code 
			END IF 
			DISPLAY modu_rec_currency.desc_text TO currency.desc_text 
			attribute (cyan) 
		AFTER FIELD language_code 
			IF glob_rec_company.language_code IS NOT NULL THEN 
				SELECT * INTO modu_rec_language.* FROM language 
				WHERE language_code = glob_rec_company.language_code 
				IF status = NOTFOUND THEN 
					LET msgresp = kandoomsg("U",9105,"") 
					#9105 Record NOT found; Try Window.
					NEXT FIELD language_code 
				END IF 
				DISPLAY modu_rec_language.language_text TO language.language_text 
				attribute (cyan) 
			END IF 
		AFTER FIELD vat_code 
			IF glob_rec_company.vat_code IS NOT NULL THEN 
				IF NOT validate_vat_registration_code(glob_rec_company.vat_code) THEN 
					LET msgresp = kandoomsg("G",9538,"") 
					#Invalid ABN. Enter valid ABN OR leave blank
					NEXT FIELD vat_code 
				END IF 
			END IF 
		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 
			IF glob_rec_company.country_code IS NOT NULL THEN 
				SELECT * INTO modu_rec_country.* FROM country 
				WHERE country_code = glob_rec_company.country_code 
				IF status = NOTFOUND THEN 
					LET msgresp = kandoomsg("U",9105,"") 
					#9105 Record NOT found; Try Window.
					NEXT FIELD country_code 
				END IF 
				DISPLAY modu_rec_country.country_text TO country.country_text 
				attribute (cyan) 
			END IF 
			IF glob_rec_company.curr_code IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD curr_code 
			END IF 
			SELECT * INTO modu_rec_currency.* FROM currency 
			WHERE currency_code = glob_rec_company.curr_code 
			IF status = NOTFOUND THEN 
				LET msgresp = kandoomsg("U",9105,"") 
				#9105 Record NOT found; Try Window.
				NEXT FIELD curr_code 
			END IF 
			IF glob_rec_company.language_code IS NOT NULL THEN 
				SELECT * INTO modu_rec_language.* FROM language 
				WHERE language_code = glob_rec_company.language_code 
				IF status = NOTFOUND THEN 
					LET msgresp = kandoomsg("U",9105,"") 
					#9105 Record NOT found; Try Window.
					NEXT FIELD language_code 
				END IF 
				DISPLAY modu_rec_language.language_text TO language.language_text 
				attribute (cyan) 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		CLOSE WINDOW g131 
		RETURN 
	END IF 
	LET glob_rec_company.country_text = modu_rec_country.country_text 
	UPDATE company 
	SET * = glob_rec_company.* 
	WHERE cmpy_code = glob_rec_company.cmpy_code 
	LET modu_arr_rec_company[modu_idx].name_text = glob_rec_company.name_text 
	LET modu_arr_rec_company[modu_idx].city_text = glob_rec_company.city_text 
	LET modu_arr_rec_company[modu_idx].tele_text = glob_rec_company.tele_text 
	CALL upd_module() 
	CLOSE WINDOW g131 
END FUNCTION 



############################################################
# FUNCTION deletor()
#
#
############################################################
FUNCTION deletor() 

	LET msgresp = kandoomsg("G",8029,"") 
	#8029 Confirm TO delete company?
	IF msgresp = "Y" THEN 
		BEGIN WORK 
			DELETE FROM company 
			WHERE cmpy_code = glob_rec_company.cmpy_code 
			DELETE FROM kandoooption 
			WHERE cmpy_code = glob_rec_company.cmpy_code 
			DELETE FROM poststatus 
			WHERE cmpy_code = glob_rec_company.cmpy_code 
		COMMIT WORK 
	END IF 
END FUNCTION 


############################################################
# FUNCTION upd_module()
#
#
############################################################
FUNCTION upd_module() 

	OPEN WINDOW g214 at 5,7 with FORM "G214" 
	attribute (border) 
	LET msgresp = kandoomsg("G",1069,"") 
	#1069 Enter Company Details; OK TO Continue
	DISPLAY BY NAME glob_rec_company.cmpy_code, 
	glob_rec_company.name_text, 
	glob_rec_company.module_text 
	attribute(cyan) 
	INPUT BY NAME glob_rec_company.module_text WITHOUT DEFAULTS 
	attribute(cyan) 
		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	UPDATE company 
	SET module_text = glob_rec_company.module_text 
	WHERE cmpy_code = glob_rec_company.cmpy_code 
	CLOSE WINDOW g214 
END FUNCTION 


############################################################
# FUNCTION add_poststatus()
#
#
############################################################
FUNCTION add_poststatus() 
	DEFINE l_rec_poststatus RECORD LIKE poststatus.* 

	LET l_rec_poststatus.cmpy_code = glob_rec_company.cmpy_code 
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