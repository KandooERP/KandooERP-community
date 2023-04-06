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
# wcustwin.4gl - show_wcust
#                window FUNCTION FOR finding customer record
#                returns customer code
#              - newcust IS an integrated Customer Addition FUNCTION
GLOBALS "../common/glob_GLOBALS.4gl" 
DEFINE 
glob_rec_customer RECORD LIKE customer.*, 
--winds_text CHAR(20), 
--pr_country RECORD LIKE country.*, 
--pr_company RECORD LIKE company.*, 
glob_rec_arparms RECORD LIKE arparms.* 

FUNCTION show_wcust(p_cmpy,p_waregrp_code,p_type_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_waregrp_code LIKE waregrp.waregrp_code 
	DEFINE p_type_code LIKE customer.type_code 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_ordquotext RECORD LIKE ordquotext.* 
	DEFINE l_arr_customer array[100] OF RECORD 
		scroll_flag CHAR(1), 
		cust_code LIKE customer.cust_code, 
		addr1_text LIKE customer.addr1_text, 
		territory_code LIKE customer.territory_code, 
		type_code LIKE customer.type_code, 
		sale_code LIKE customer.sale_code 
	END RECORD 
	DEFINE l_idx,l_scrn SMALLINT 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_where_text CHAR(2048) 
	DEFINE l_msgresp LIKE language.yes_flag

	INITIALIZE glob_rec_arparms.* TO NULL 
	INITIALIZE l_rec_ordquotext.* TO NULL 
	SELECT * INTO glob_rec_arparms.* FROM arparms 
	WHERE cmpy_code = p_cmpy 
	AND parm_code = "1" 
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	OPEN WINDOW w102 with FORM "W102" 
	CALL windecoration_w("W102") -- albo kd-767 
	WHILE TRUE 
		CLEAR FORM 
		LET l_msgresp = kandoomsg("U",1001,"") 
		#1001 Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON name_text, 
		state_code, 
		post_code, 
		addr2_text, 
		city_text, 
		cust_code, 
		addr1_text, 
		territory_code, 
		type_code, 
		sale_code 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","wcustwin","construct-customer") 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 


		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			LET l_rec_customer.cust_code = NULL 
			EXIT WHILE 
		END IF 
		IF p_type_code IS NOT NULL THEN 
			LET l_where_text = l_where_text CLIPPED," AND type_code = '",p_type_code,"'" 
		END IF 
		LET l_query_text = "SELECT * FROM customer ", 
		"WHERE cmpy_code = '",p_cmpy,"' ", 
		"AND ", l_where_text CLIPPED 
		IF glob_rec_arparms.report_ord_flag = "C" THEN 
			LET l_query_text = l_query_text CLIPPED," ORDER BY cust_code" 
		ELSE 
			LET l_query_text = l_query_text CLIPPED," ORDER BY name_text" 
		END IF 
		WHENEVER ERROR CONTINUE 
		OPTIONS SQL interrupt ON 
		PREPARE s_customer FROM l_query_text 
		DECLARE c_customer CURSOR FOR s_customer 
		LET l_idx = 0 
		FOREACH c_customer INTO l_rec_customer.* 
			LET l_idx = l_idx + 1 
			LET l_arr_customer[l_idx].cust_code = l_rec_customer.cust_code 
			LET l_arr_customer[l_idx].addr1_text = l_rec_customer.addr1_text 
			LET l_arr_customer[l_idx].territory_code = l_rec_customer.territory_code 
			LET l_arr_customer[l_idx].type_code = l_rec_customer.type_code 
			LET l_arr_customer[l_idx].sale_code = l_rec_customer.sale_code 
			IF l_idx = 100 THEN 
				LET l_msgresp = kandoomsg("U",6100,l_idx) 
				EXIT FOREACH 
			END IF 
		END FOREACH 
		LET l_msgresp = kandoomsg("U",9113,l_idx) 
		#9113 l_idx records selected
		IF l_idx = 0 THEN 
			LET l_idx = 1 
			INITIALIZE l_arr_customer[1].* TO NULL 
		END IF 
		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 

		LET l_msgresp = kandoomsg("U",1006,"") 
		#1006 " ESC on line TO SELECT - F10 TO Add
		CALL set_count(l_idx) 
		INPUT ARRAY l_arr_customer WITHOUT DEFAULTS FROM sr_customer.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","wcustwin","input-arr-customer") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				LET l_scrn = scr_line() 
				IF l_arr_customer[l_idx].cust_code IS NOT NULL THEN 
					DISPLAY l_arr_customer[l_idx].* TO sr_customer[l_scrn].* 

					SELECT * INTO l_rec_customer.* FROM customer 
					WHERE cmpy_code = p_cmpy 
					AND cust_code = l_arr_customer[l_idx].cust_code 
					DISPLAY BY NAME l_rec_customer.name_text, 
					l_rec_customer.addr2_text, 
					l_rec_customer.city_text, 
					l_rec_customer.state_code, 
					l_rec_customer.post_code 

				END IF 
				NEXT FIELD scroll_flag 
			AFTER FIELD scroll_flag 
				LET l_arr_customer[l_idx].scroll_flag = NULL 
				IF fgl_lastkey() = fgl_keyval("down") 
				AND arr_curr() >= arr_count() THEN 
					LET l_msgresp = kandoomsg("U",9001,"") 
					NEXT FIELD scroll_flag 
				END IF 
			BEFORE FIELD cust_code 
				LET l_rec_customer.cust_code = l_arr_customer[l_idx].cust_code 
				EXIT INPUT 
			ON KEY (F10) 
				LET l_rec_customer.cust_code = newcust(p_cmpy,p_waregrp_code, 
				l_rec_ordquotext.*) 
				IF l_rec_customer.cust_code IS NOT NULL THEN 
					EXIT INPUT 
				ELSE 
					NEXT FIELD scroll_flag 
				END IF 
			AFTER ROW 
				DISPLAY l_arr_customer[l_idx].* TO sr_customer[l_scrn].* 

			AFTER INPUT 
				LET l_rec_customer.cust_code = l_arr_customer[l_idx].cust_code 

		END INPUT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 
	CLOSE WINDOW w102 
	RETURN l_rec_customer.cust_code 
END FUNCTION 


FUNCTION newcust(p_cmpy,p_waregrp_code,p_ordquotext) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_waregrp_code LIKE waregrp.waregrp_code 
	DEFINE p_ordquotext RECORD LIKE ordquotext.* 
	DEFINE l_rec_mbparms RECORD LIKE mbparms.*
	DEFINE l_rec_ordquote RECORD LIKE ordquote.* 
	DEFINE l_rec_customertype RECORD LIKE customertype.* 
	DEFINE l_rec_territory RECORD LIKE territory.* 
	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 
	DEFINE l_rec_suburb RECORD LIKE suburb.* 
	DEFINE l_rec_tax RECORD LIKE tax.* 
	DEFINE l_tax_desc_text LIKE tax.desc_text 
	DEFINE l_rec_street RECORD LIKE street.* 
	DEFINE l_rec_suburbarea RECORD LIKE suburbarea.* 
	DEFINE l_trans_num LIKE nextnumber.next_num 
	DEFINE l_rowid INTEGER 
	DEFINE l_suburb_code INTEGER
	DEFINE l_err_message CHAR(40) 
	DEFINE l_auto_cust_ind CHAR(1) 
	DEFINE l_msgresp LIKE language.yes_flag
	DEFINE l_winds_text CHAR(20)	
	DEFINE l_rec_country RECORD LIKE country.*
	DEFINE l_rec_company RECORD LIKE company.*

	OPEN WINDOW w101 with FORM "W101" 
	CALL windecoration_w("W101") -- albo kd-767 
	SELECT * INTO glob_rec_arparms.* FROM arparms 
	WHERE cmpy_code = p_cmpy 
	AND parm_code = "1" 
	IF status = notfound THEN 
		LET l_msgresp = kandoomsg("U",5101,"") 
		#5005 Accounts Receivable Parameters NOT SET up - Refer Menu AZP
		CLOSE WINDOW w101 
		LET glob_rec_customer.cust_code = NULL 
		RETURN glob_rec_customer.cust_code 
	END IF 
	SELECT * INTO l_rec_mbparms.* FROM mbparms 
	WHERE cmpy_code = p_cmpy 
	IF status = notfound THEN 
		LET l_msgresp = kandoomsg("W",5006,"") 
		#5006 Max Brick Parameters NOT SET up - Refer Menu AZP
		CLOSE WINDOW w101 
		LET glob_rec_customer.cust_code = NULL 
		RETURN glob_rec_customer.cust_code 
	END IF 
	SELECT * INTO l_rec_tax.* 
	FROM tax 
	WHERE cmpy_code = p_cmpy 
	AND tax_code = l_rec_mbparms.tax_code 
	LET l_tax_desc_text = l_rec_tax.desc_text 
	SELECT * INTO l_rec_company.* FROM company 
	WHERE cmpy_code = p_cmpy 
	IF status = notfound THEN 
		LET l_msgresp = kandoomsg("U",5100,"") 
		#9003 Company NOT SET up - Refer System Administrator"
		CLOSE WINDOW w101 
		LET glob_rec_customer.cust_code = NULL 
		RETURN glob_rec_customer.cust_code 
	END IF 
	IF get_kandoooption_feature_state("AR","CN") = "Y" THEN 
		LET l_auto_cust_ind = TRUE 
	ELSE 
		LET l_auto_cust_ind = FALSE 
	END IF 
	SELECT * INTO l_rec_country.* FROM country 
	WHERE country_code = l_rec_company.country_code 
	LET l_msgresp = kandoomsg("W",1011,"") 
	#1011  Enter Customer Details
	INITIALIZE glob_rec_customer.* TO NULL 
	LET glob_rec_customer.country_code = l_rec_company.country_code 
	LET glob_rec_customer.language_code = l_rec_company.language_code 
	LET glob_rec_customer.country_code = l_rec_country.country_code --@db-patch_2020_10_04--
	LET glob_rec_customer.inv_level_ind = l_rec_mbparms.inv_level_ind 
	LET glob_rec_customer.name_text = p_ordquotext.name_text 
	LET glob_rec_customer.addr1_text = p_ordquotext.addr1_text 
	LET glob_rec_customer.addr2_text = p_ordquotext.addr2_text 
	LET glob_rec_customer.city_text = p_ordquotext.city_text 
	LET glob_rec_customer.state_code = p_ordquotext.state_code 
	LET glob_rec_customer.post_code = p_ordquotext.post_code 
	LET glob_rec_customer.tax_code = l_rec_mbparms.tax_code 
	SELECT * INTO l_rec_ordquote.* FROM ordquote 
	WHERE cmpy_code = p_cmpy 
	AND order_num = p_ordquotext.order_num 
	IF status = 0 THEN 
		LET glob_rec_customer.territory_code = l_rec_ordquote.territory_code 
		LET glob_rec_customer.sale_code = l_rec_ordquote.sale_code 
	END IF 
	DISPLAY glob_rec_customer.country_code TO country_code 
	DISPLAY glob_rec_customer.tax_code TO tax_code
	DISPLAY l_tax_desc_text TO tax_desc_text 

	IF l_rec_mbparms.cust_type IS NOT NULL THEN 
		LET glob_rec_customer.type_code = l_rec_mbparms.cust_type 
		SELECT * INTO l_rec_customertype.* FROM customertype 
		WHERE cmpy_code = p_cmpy 
		AND type_code = glob_rec_customer.type_code 
		DISPLAY glob_rec_customer.type_code, 
		l_rec_customertype.type_text 
		TO customer.type_code, 
		customertype.type_text 

	END IF 

	INPUT BY NAME glob_rec_customer.cust_code, 
	glob_rec_customer.name_text, 
	glob_rec_customer.addr1_text, 
	glob_rec_customer.addr2_text, 
	glob_rec_customer.city_text, 
	glob_rec_customer.state_code, 
	glob_rec_customer.post_code, 
	glob_rec_customer.country_code, 
	glob_rec_customer.language_code, 
	glob_rec_customer.territory_code, 
	glob_rec_customer.sale_code, 
	glob_rec_customer.type_code, 
	glob_rec_customer.tax_code, 
	glob_rec_customer.bank_acct_code, 
	glob_rec_customer.inv_level_ind, 
	glob_rec_customer.vat_code, 
	glob_rec_customer.registration_num, 
	glob_rec_customer.contact_text, 
	glob_rec_customer.tele_text, 
	glob_rec_customer.fax_text, 
	glob_rec_customer.mobile_phone WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","wcustwin","input-customer") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield(addr2_text) 
					LET l_rowid = show_wstreet(p_cmpy) 
					IF l_rowid != 0 THEN 
						SELECT * INTO l_rec_street.* FROM street 
						WHERE rowid = l_rowid 
						IF status = notfound THEN 
							LET l_msgresp = kandoomsg("W",9005,"") 
							#9005 Logic error: Street name NOT found"
							NEXT FIELD addr2_text 
						END IF 
						SELECT * INTO l_rec_suburb.* FROM suburb 
						WHERE cmpy_code = p_cmpy 
						AND suburb_code = l_rec_street.suburb_code 
						SELECT * INTO l_rec_suburbarea.* FROM suburbarea 
						WHERE cmpy_code = p_cmpy 
						AND suburb_code = l_rec_suburb.suburb_code 
						AND waregrp_code = p_waregrp_code 
						LET glob_rec_customer.addr2_text = l_rec_street.street_text CLIPPED, 
						" ", l_rec_street.st_type_text 
						LET glob_rec_customer.city_text = l_rec_suburb.suburb_text 
						LET glob_rec_customer.state_code = l_rec_suburb.state_code 
						LET glob_rec_customer.post_code = l_rec_suburb.post_code 
						LET glob_rec_customer.territory_code = l_rec_suburbarea.terr_code 
						INITIALIZE l_rec_territory.* TO NULL 
						SELECT * INTO l_rec_territory.* FROM territory 
						WHERE cmpy_code = p_cmpy 
						AND terr_code = glob_rec_customer.territory_code 

						LET glob_rec_customer.sale_code = l_rec_territory.sale_code 

						IF glob_rec_customer.sale_code IS NULL THEN 
							LET glob_rec_customer.sale_code = l_rec_suburbarea.sale_code 
						END IF 

						IF glob_rec_customer.sale_code IS NOT NULL THEN 
							INITIALIZE l_rec_salesperson.* TO NULL
							#get sales person record	 
							CALL db_salesperson_get_rec(UI_OFF,glob_rec_customer.sale_code) RETURNING l_rec_salesperson.* 
						END IF 

						DISPLAY BY NAME 
							glob_rec_customer.addr2_text, 
							glob_rec_customer.city_text, 
							glob_rec_customer.state_code, 
							glob_rec_customer.post_code, 
							glob_rec_customer.territory_code 

						DISPLAY 
							l_rec_territory.desc_text, 
							glob_rec_customer.sale_code, 
							l_rec_salesperson.name_text 
						TO 
							territory.desc_text, 
							customer.sale_code, 
							salesperson.name_text 

					END IF 

		ON ACTION "LOOKUP" infield(city_text) 
					LET l_suburb_code = show_wsub(p_cmpy) 
					IF l_suburb_code != 0 THEN 
						SELECT * INTO l_rec_suburb.* FROM suburb 
						WHERE cmpy_code = p_cmpy 
						AND suburb_code = l_suburb_code 
						IF status = notfound THEN 
							LET l_msgresp = kandoomsg("W",9006,"")					#9006 Logic error: Suburb NOT found"
							NEXT FIELD city_text 
						END IF 

						SELECT * INTO l_rec_suburbarea.* FROM suburbarea 
						WHERE cmpy_code = p_cmpy 
						AND suburb_code = l_suburb_code 
						AND waregrp_code = p_waregrp_code 

						LET glob_rec_customer.city_text = l_rec_suburb.suburb_text 
						LET glob_rec_customer.state_code = l_rec_suburb.state_code 
						LET glob_rec_customer.post_code = l_rec_suburb.post_code 
						LET glob_rec_customer.territory_code = l_rec_suburbarea.terr_code 

						INITIALIZE l_rec_territory.* TO NULL 

						SELECT * INTO l_rec_territory.* FROM territory 
						WHERE cmpy_code = p_cmpy 
						AND terr_code = glob_rec_customer.territory_code 

						LET glob_rec_customer.sale_code = l_rec_territory.sale_code 

						IF glob_rec_customer.sale_code IS NULL THEN 
							LET glob_rec_customer.sale_code = l_rec_suburbarea.sale_code 
						END IF 

						IF glob_rec_customer.sale_code IS NOT NULL THEN 
							INITIALIZE l_rec_salesperson.* TO NULL 
							#get sales person record	 
							CALL db_salesperson_get_rec(UI_OFF,glob_rec_customer.sale_code) RETURNING l_rec_salesperson.*

						END IF 

						DISPLAY BY NAME 
							glob_rec_customer.city_text, 
							glob_rec_customer.state_code, 
							glob_rec_customer.post_code, 
							glob_rec_customer.territory_code, 
							glob_rec_customer.sale_code, 
							glob_rec_customer.name_text 

						DISPLAY 
							l_rec_territory.desc_text, 
							glob_rec_customer.sale_code, 
							l_rec_salesperson.name_text 
						TO 
							territory.desc_text, 
							customer.sale_code, 
							salesperson.name_text 
					END IF 
					
		ON ACTION "LOOKUP" infield(tax_code) 
					LET l_winds_text = show_tax(p_cmpy) 
					IF l_winds_text IS NOT NULL THEN 
						LET glob_rec_customer.tax_code = l_winds_text 
						NEXT FIELD tax_code 
					END IF 
					
		ON ACTION "LOOKUP" infield(country_code) 
					LET l_winds_text = show_country() 
					IF l_winds_text IS NOT NULL THEN 
						LET glob_rec_customer.country_code = l_winds_text 
						NEXT FIELD country_code 
					END IF 
					
		ON ACTION "LOOKUP" infield(language_code) 
					LET l_winds_text = show_language() 
					IF l_winds_text IS NOT NULL THEN 
						LET glob_rec_customer.language_code = l_winds_text 
						NEXT FIELD language_code 
					END IF 
					
		ON ACTION "LOOKUP" infield(territory_code) 
					LET l_winds_text = show_territory(p_cmpy,"") 
					IF l_winds_text IS NOT NULL THEN 
						LET glob_rec_customer.territory_code = l_winds_text 
						NEXT FIELD territory_code 
					END IF 
					
		ON ACTION "LOOKUP" infield(sale_code) 
					LET l_winds_text = show_sale(p_cmpy) 
					IF l_winds_text IS NOT NULL THEN 
						LET glob_rec_customer.sale_code = l_winds_text 
						NEXT FIELD sale_code 
					END IF 
					
		ON ACTION "LOOKUP" infield(type_code) 
					LET l_winds_text = show_ctyp(p_cmpy) 
					IF l_winds_text IS NOT NULL THEN 
						LET glob_rec_customer.type_code = l_winds_text 
						NEXT FIELD type_code 
					END IF 

		BEFORE FIELD cust_code 
			IF l_auto_cust_ind THEN 
				NEXT FIELD NEXT 
			END IF 

		AFTER FIELD cust_code 
			IF glob_rec_customer.cust_code IS NOT NULL THEN 
				SELECT unique 1 FROM customer 
				WHERE cmpy_code = p_cmpy 
				AND cust_code = glob_rec_customer.cust_code 
				IF status = 0 THEN 
					LET l_msgresp = kandoomsg("A",9025,"") 
					#9025" The Customer Code already exists - Try Again"
					NEXT FIELD cust_code 
				END IF 
			END IF 

		AFTER FIELD name_text 
			IF glob_rec_customer.name_text IS NULL THEN 
				LET l_msgresp = kandoomsg("W",9171,"") #9171 Customer's name must be entered"
				NEXT FIELD name_text 
			END IF 

		AFTER FIELD country_code 
			IF glob_rec_customer.country_code IS NULL THEN 
				LET l_msgresp = kandoomsg("A",9047,"") #9047 Country code NOT found - Try window "
				NEXT FIELD country_code 
			ELSE 
				SELECT * INTO l_rec_country.* FROM country 
				WHERE country_code = glob_rec_customer.country_code 
				IF status = notfound THEN 
					LET l_msgresp = kandoomsg("A",9047,"") 		#9047 Country code NOT found - Try window "
					NEXT FIELD country_code 
				ELSE 
					LET glob_rec_customer.country_code = l_rec_country.country_code --@db-patch_2020_10_04--
					LET glob_rec_customer.language_code = l_rec_country.language_code 
					
					DISPLAY glob_rec_customer.country_code TO country_code --@db-patch_2020_10_04--
					DISPLAY glob_rec_customer.language_code TO language_code

				END IF 
			END IF 

		AFTER FIELD vat_code 
			IF glob_rec_customer.vat_code IS NOT NULL THEN 
				IF NOT validate_vat_registration_code(glob_rec_customer.vat_code,glob_rec_customer.country_code) THEN			
					ERROR kandoomsg2("G",9538,"") #Invalid ABN. Enter valid ABN OR leave blank
					NEXT FIELD vat_code 
				END IF 
			END IF 
			
		AFTER FIELD tax_code 
			CLEAR tax_desc_text 
			IF glob_rec_customer.tax_code IS NOT NULL THEN 
				SELECT desc_text INTO l_tax_desc_text 
				FROM tax 
				WHERE cmpy_code = p_cmpy 
				AND tax_code = glob_rec_customer.tax_code 
				IF status = notfound THEN 
					LET l_msgresp = kandoomsg("A",9036,"")				#9036 " Tax Code NOT found, try window"
					NEXT FIELD tax_code 
				ELSE 
					DISPLAY l_tax_desc_text TO tax_desc_text 

				END IF 
			END IF 

		AFTER FIELD inv_level_ind 
			IF glob_rec_customer.inv_level_ind IS NULL 
			OR glob_rec_customer.inv_level_ind NOT matches "[1-9,LC]" THEN 
				LET l_msgresp = kandoomsg("W",9160,"")			#9160 " Level Indicator must be 1-9, L OR C"
				NEXT FIELD inv_level_ind 
			END IF 

		AFTER FIELD territory_code 
			IF glob_rec_customer.territory_code IS NULL THEN 
				LET l_msgresp = kandoomsg("A",9084,"")	#9084 Territory NOT found - try window"
				NEXT FIELD territory_code 
			ELSE 
				SELECT * INTO l_rec_territory.* FROM territory 
				WHERE cmpy_code = p_cmpy 
				AND terr_code = glob_rec_customer.territory_code 
				IF status = notfound THEN 
					LET l_msgresp = kandoomsg("A",9084,"") 				#9084 Territory NOT found - try window"
					NEXT FIELD territory_code 
				END IF 
				
				IF l_rec_territory.sale_code IS NOT NULL THEN
					#get sales person record	 
					CALL db_salesperson_get_rec(UI_OFF,l_rec_territory.sale_code) RETURNING l_rec_salesperson.*
					IF status = notfound THEN 
						LET l_msgresp = kandoomsg("A",7042,"")				#7042 Territory Salesman NOT found - Refer AZT
						LET l_rec_territory.sale_code = NULL 
						NEXT FIELD territory_code 
					END IF 
					
					IF l_rec_salesperson.terri_code != glob_rec_customer.territory_code 
					AND l_rec_salesperson.terri_code IS NOT NULL THEN 
						LET l_msgresp = kandoomsg("A",7043,"") 				#7043 Salesperson Territory SET up IS invalid
						NEXT FIELD territory_code 
					END IF
					 
					LET glob_rec_customer.sale_code = l_rec_territory.sale_code 
				END IF 
				
				DISPLAY 
					l_rec_territory.desc_text, 
					glob_rec_customer.sale_code, 
					l_rec_salesperson.name_text 
				TO 
					territory.desc_text, 
					customer.sale_code, 
					salesperson.name_text 

			END IF
			 
		BEFORE FIELD sale_code 
			IF l_rec_territory.sale_code IS NOT NULL THEN 
				IF fgl_lastkey() = fgl_keyval("up") 
				OR fgl_lastkey() = fgl_keyval("left") THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 
		AFTER FIELD sale_code 
			IF glob_rec_customer.sale_code IS NULL THEN 
				LET l_msgresp = kandoomsg("A",9032,"")			#9032 " Salesperson NOT found - try window"
				NEXT FIELD sale_code 
			ELSE 
				#get sales person record	 
				CALL db_salesperson_get_rec(UI_OFF,glob_rec_customer.sale_code ) RETURNING l_rec_salesperson.*

				IF l_rec_salesperson.sale_code is NULL THEN 
					LET l_msgresp = kandoomsg("A",9032,"")					#9032 " Salesperson NOT found - try window"
					NEXT FIELD sale_code 
				END IF 
				
				IF l_rec_salesperson.terri_code IS NOT NULL THEN 
					IF l_rec_salesperson.terri_code != glob_rec_customer.territory_code					AND glob_rec_customer.territory_code IS NOT NULL THEN 
						LET l_msgresp = kandoomsg("A",9152,glob_rec_customer.territory_code)						#9152" Salesperson IS NOT assigned TO territory:"
						NEXT FIELD sale_code 
					END IF 
					
					SELECT * INTO l_rec_territory.* FROM territory 
					WHERE cmpy_code = p_cmpy 
					AND terr_code = l_rec_salesperson.terri_code 
					IF status = notfound THEN 
						LET l_msgresp = kandoomsg("A",9153,"")				#9153 " territory FOR salesperson NOT found
						LET l_rec_salesperson.terri_code = NULL 
					END IF 
					
					LET glob_rec_customer.territory_code = l_rec_salesperson.terri_code 
				END IF
				 
				DISPLAY 
					glob_rec_customer.territory_code, 
					l_rec_territory.desc_text, 
					glob_rec_customer.sale_code, 
					l_rec_salesperson.name_text 
				TO 
					customer.territory_code, 
					territory.desc_text, 
					customer.sale_code, 
					salesperson.name_text 

			END IF 
		AFTER FIELD language_code 
			IF glob_rec_customer.language_code IS NOT NULL THEN 
				SELECT unique 1 FROM language 
				WHERE language_code = glob_rec_customer.language_code 
				IF status = notfound THEN 
					LET l_msgresp = kandoomsg("A",9037,"")		#9037 Language code NOT found -  try window "
					NEXT FIELD language_code 
				END IF 
			END IF 

		BEFORE FIELD type_code 
			IF l_rec_mbparms.cust_type IS NOT NULL THEN 
				LET glob_rec_customer.type_code = l_rec_mbparms.cust_type 
				SELECT * INTO l_rec_customertype.* FROM customertype 
				WHERE cmpy_code = p_cmpy 
				AND type_code = glob_rec_customer.type_code 
				
				DISPLAY 
					glob_rec_customer.type_code, 
					l_rec_customertype.type_text 
				TO 
					customer.type_code, 
					customertype.type_text 
	
				IF fgl_lastkey() = fgl_keyval("up") 
				OR fgl_lastkey() = fgl_keyval("left") THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 
		AFTER FIELD type_code 
			CLEAR customertype.type_text 
			IF glob_rec_customer.type_code IS NULL THEN 
				LET l_msgresp = kandoomsg("A",9029,"") 
				#9029 " customer type must be entered"
				NEXT FIELD type_code 
			ELSE 
				SELECT * INTO l_rec_customertype.* FROM customertype 
				WHERE cmpy_code = p_cmpy 
				AND type_code = glob_rec_customer.type_code 
				IF status = notfound THEN 
					LET l_msgresp = kandoomsg("A",9030,"") 
					#9030 " Customer Type NOT found - try window"
					NEXT FIELD type_code 
				ELSE 
					DISPLAY l_rec_customertype.type_text 
					TO customertype.type_text 

				END IF 
			END IF 
		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF not(l_auto_cust_ind) THEN 
					IF glob_rec_customer.cust_code IS NULL THEN 
						LET l_msgresp = kandoomsg("A",9024,"") 
						#9024 " Customer Code must be entered "
						NEXT FIELD cust_code 
					END IF 
				END IF 
				IF glob_rec_customer.name_text IS NULL THEN 
					LET l_msgresp = kandoomsg("W",9171,"") 
					#9171 Customer's name must be entered"
					NEXT FIELD name_text 
				END IF 
				IF glob_rec_customer.country_code IS NULL THEN 
					LET l_msgresp = kandoomsg("A",9047,"") 
					#9047 Country code NOT found - Try window "
					NEXT FIELD country_code 
				ELSE 
					SELECT * INTO l_rec_country.* FROM country 
					WHERE country_code = glob_rec_customer.country_code 
					IF status = notfound THEN 
						LET l_msgresp = kandoomsg("A",9047,"") 
						#9047 Country code NOT found - Try window "
						NEXT FIELD country_code 
					ELSE 
						LET glob_rec_customer.country_code = l_rec_country.country_code --@db-patch_2020_10_04--
						LET glob_rec_customer.language_code = l_rec_country.language_code 
						
						DISPLAY glob_rec_customer.country_code TO country_code --@db-patch_2020_10_04--
						DISPLAY glob_rec_customer.language_code TO language_code 

					END IF 
				END IF 
				IF glob_rec_customer.inv_level_ind IS NULL 
				OR glob_rec_customer.inv_level_ind NOT matches "[1-9,LC]" THEN 
					LET l_msgresp = kandoomsg("W",9160,"") 			#9160 " Level Indicator must be 1-9, L OR C"
					NEXT FIELD inv_level_ind 
				END IF 

				#get sales person record	 
				CALL db_salesperson_get_rec(UI_OFF,glob_rec_customer.sale_code ) RETURNING l_rec_salesperson.*
								
 				IF l_rec_salesperson.sale_code is NULL THEN 
					LET l_msgresp = kandoomsg("A",9032,"") 				#9032 Salesperson NOT found - use window"
					NEXT FIELD sale_code 
				END IF 
				
				SELECT * INTO l_rec_territory.* FROM territory 
				WHERE cmpy_code = p_cmpy 
				AND terr_code = glob_rec_customer.territory_code 
				IF status = notfound THEN 
					LET l_msgresp = kandoomsg("A",9084,"") 				#9084 " Territory NOT found - use window"
					NEXT FIELD territory_code 
				END IF 
				
				IF (l_rec_territory.sale_code IS NOT NULL AND 
				l_rec_territory.sale_code != l_rec_salesperson.sale_code) 
				OR (l_rec_salesperson.terri_code IS NOT NULL AND 
				l_rec_territory.terr_code != l_rec_salesperson.terri_code) THEN 
					LET l_msgresp = kandoomsg("A",7043,"") 				#7043 " Salesperson Terri SET up IS invalid
					NEXT FIELD territory_code 
				END IF 
				
				DISPLAY 
					l_rec_territory.desc_text, 
					l_rec_salesperson.name_text 
				TO 
					territory.desc_text, 
					salesperson.name_text 

				IF glob_rec_customer.language_code IS NOT NULL THEN 
					SELECT unique 1 FROM language 
					WHERE language_code = glob_rec_customer.language_code 
					IF status = notfound THEN 
						LET l_msgresp = kandoomsg("A",9037,"") 
						#9037 " Language code NOT found - try window "
						NEXT FIELD language_code 
					END IF 
				END IF 
				IF glob_rec_customer.type_code IS NULL THEN 
					LET l_msgresp = kandoomsg("A",9029,"") 
					#9029 " customer type must be entered"
					NEXT FIELD type_code 
				ELSE 
					SELECT * INTO l_rec_customertype.* FROM customertype 
					WHERE cmpy_code = p_cmpy 
					AND type_code = glob_rec_customer.type_code 
					IF status = notfound THEN 
						LET l_msgresp = kandoomsg("A",9030,"") 
						#9030 " Customer Type NOT found - try window"
						NEXT FIELD type_code 
					END IF 
				END IF 
				IF glob_rec_arparms.ref1_ind = "2" OR glob_rec_arparms.ref1_ind = "4" 
				OR glob_rec_arparms.ref2_ind = "2" OR glob_rec_arparms.ref2_ind = "4" 
				OR glob_rec_arparms.ref3_ind = "2" OR glob_rec_arparms.ref3_ind = "4" 
				OR glob_rec_arparms.ref4_ind = "2" OR glob_rec_arparms.ref4_ind = "4" 
				OR glob_rec_arparms.ref5_ind = "2" OR glob_rec_arparms.ref5_ind = "4" 
				OR glob_rec_arparms.ref6_ind = "2" OR glob_rec_arparms.ref6_ind = "4" 
				OR glob_rec_arparms.ref7_ind = "2" OR glob_rec_arparms.ref7_ind = "4" 
				OR glob_rec_arparms.ref8_ind = "2" OR glob_rec_arparms.ref8_ind = "4" THEN 
					IF NOT report_codes(p_cmpy) THEN 
						NEXT FIELD name_text 
					END IF 
				END IF 
			END IF 

	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		LET glob_rec_customer.cust_code = NULL 
		CLOSE WINDOW w101 
		RETURN glob_rec_customer.cust_code 
	END IF 
	LET glob_rec_customer.cmpy_code = p_cmpy 
	LET glob_rec_customer.setup_date = today 
	LET glob_rec_customer.last_mail_date = today 
	LET glob_rec_customer.cred_limit_amt = l_rec_mbparms.cred_limit_amt 
	LET glob_rec_customer.cred_bal_amt = l_rec_mbparms.cred_limit_amt 
	LET glob_rec_customer.bal_amt = 0 
	LET glob_rec_customer.highest_bal_amt = 0 
	LET glob_rec_customer.curr_amt = 0 
	LET glob_rec_customer.over1_amt = 0 
	LET glob_rec_customer.over30_amt = 0 
	LET glob_rec_customer.onorder_amt = 0 
	LET glob_rec_customer.over60_amt = 0 
	LET glob_rec_customer.over90_amt = 0 
	LET glob_rec_customer.onorder_amt = 0 
	LET glob_rec_customer.cred_override_ind = "0" 
	LET glob_rec_customer.dun_code = l_rec_mbparms.dun_code 
	LET glob_rec_customer.avg_cred_day_num = 0 
	LET glob_rec_customer.next_seq_num = 0 
	LET glob_rec_customer.partial_ship_flag = "Y" 
	LET glob_rec_customer.back_order_flag = "Y" 
	IF glob_rec_arparms.consolidate_flag IS NULL THEN 
		LET glob_rec_arparms.consolidate_flag = "N" 
	END IF 
	LET glob_rec_customer.consolidate_flag = glob_rec_arparms.consolidate_flag 
	LET glob_rec_customer.currency_code = l_rec_mbparms.currency_code 
	LET glob_rec_customer.stmnt_ind = l_rec_mbparms.stmnt_ind 
	LET glob_rec_customer.inv_reqd_flag = l_rec_mbparms.inv_reqd_flag 
	LET glob_rec_customer.cred_reqd_flag = l_rec_mbparms.cred_reqd_flag 
	LET glob_rec_customer.mail_reqd_flag = l_rec_mbparms.mail_reqd_flag 
	LET glob_rec_customer.inv_format_ind = l_rec_mbparms.inv_format_ind 
	LET glob_rec_customer.cred_format_ind = l_rec_mbparms.cred_format_ind 
	LET glob_rec_customer.ord_text_ind = "N" 
	LET glob_rec_customer.term_code = l_rec_mbparms.term_code 
	LET glob_rec_customer.int_chge_flag = "N" 
	LET glob_rec_customer.ytds_amt = 0 
	LET glob_rec_customer.mtds_amt = 0 
	LET glob_rec_customer.ytdp_amt = 0 
	LET glob_rec_customer.mtdp_amt = 0 
	LET glob_rec_customer.late_pay_num = 0 
	LET glob_rec_customer.cred_given_num = 0 
	LET glob_rec_customer.cred_taken_num = 0 
	LET glob_rec_customer.interest_per = 0 
	LET glob_rec_customer.delete_flag = "N" 
	LET glob_rec_customer.delete_date = "" 
	LET glob_rec_customer.show_disc_flag = "N" 
	LET glob_rec_customer.pay_ind = l_rec_mbparms.pay_ind 
	LET glob_rec_customer.hold_code = "" 
	LET glob_rec_customer.share_flag = "N" 
	LET glob_rec_customer.scheme_amt = 0 
	LET glob_rec_customer.invoice_to_ind = l_rec_mbparms.invoice_to_ind 
	GOTO bypass 
	LABEL recovery: 
	IF error_recover(l_err_message,status) != "Y" THEN 
		CLOSE WINDOW w101 
		LET glob_rec_customer.cust_code = NULL 
		RETURN glob_rec_customer.cust_code 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		IF l_auto_cust_ind THEN 
			LET l_trans_num = next_trans_num(p_cmpy,TRAN_TYPE_CUSTOMER_CUS,"") 
			IF l_trans_num < 0 THEN 
				LET l_err_message = "W11 - Next customer number UPDATE" 
				LET status = l_trans_num 
				GOTO recovery 
			END IF 
			LET glob_rec_customer.cust_code = l_trans_num 
		END IF 
		SELECT unique 1 FROM customer 
		WHERE cmpy_code = p_cmpy 
		AND cust_code = glob_rec_customer.cust_code 
		IF status = 0 THEN 
			LET l_err_message = "Customer already exists" 
			LET l_msgresp = kandoomsg("A",9025,"") 
			GOTO recovery 
		END IF 
		INSERT INTO customer VALUES (glob_rec_customer.*) 
	COMMIT WORK 
	DISPLAY BY NAME glob_rec_customer.cust_code 

	CLOSE WINDOW w101 
	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	RETURN glob_rec_customer.cust_code 
END FUNCTION 


FUNCTION report_codes(p_cmpy) 
	DEFINE p_cmpy LIKE company.cmpy_code
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_userref RECORD LIKE userref.* 
	DEFINE l_valid_flag SMALLINT
	DEFINE l_seq_num SMALLINT
	DEFINE l_msgresp LIKE language.yes_flag	
	DEFINE l_winds_text CHAR(20)

	OPEN WINDOW A602 with FORM "A602" 
	CALL windecoration_a("A602") -- albo kd-767 
	LET l_msgresp = kandoomsg("W",1014,"") 
	#1014  Enter Reporting Codes - ESC TO Continue
	LET l_rec_customer.* = glob_rec_customer.* 
	LET glob_rec_arparms.ref1_text = make_prompt(glob_rec_arparms.ref1_text) 
	LET glob_rec_arparms.ref2_text = make_prompt(glob_rec_arparms.ref2_text) 
	LET glob_rec_arparms.ref3_text = make_prompt(glob_rec_arparms.ref3_text) 
	LET glob_rec_arparms.ref4_text = make_prompt(glob_rec_arparms.ref4_text) 
	LET glob_rec_arparms.ref5_text = make_prompt(glob_rec_arparms.ref5_text) 
	LET glob_rec_arparms.ref6_text = make_prompt(glob_rec_arparms.ref6_text) 
	LET glob_rec_arparms.ref7_text = make_prompt(glob_rec_arparms.ref7_text) 
	LET glob_rec_arparms.ref8_text = make_prompt(glob_rec_arparms.ref8_text) 
	DISPLAY BY NAME glob_rec_arparms.ref1_text, 
	glob_rec_arparms.ref2_text, 
	glob_rec_arparms.ref3_text, 
	glob_rec_arparms.ref4_text, 
	glob_rec_arparms.ref5_text, 
	glob_rec_arparms.ref6_text, 
	glob_rec_arparms.ref7_text, 
	glob_rec_arparms.ref8_text 
	attribute(white) 

	INPUT BY NAME glob_rec_customer.ref1_code, 
	glob_rec_customer.ref2_code, 
	glob_rec_customer.ref3_code, 
	glob_rec_customer.ref4_code, 
	glob_rec_customer.ref5_code, 
	glob_rec_customer.ref6_code, 
	glob_rec_customer.ref7_code, 
	glob_rec_customer.ref8_code WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","wcustwin","input-customer-ref") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

					
		ON ACTION "LOOKUP" infield(ref1_code) 
					LET l_winds_text = show_ref(p_cmpy,"A","1") 
					IF l_winds_text IS NOT NULL THEN 
						LET glob_rec_customer.ref1_code = l_winds_text 
						NEXT FIELD ref1_code 
					END IF 
					
		ON ACTION "LOOKUP" infield(ref2_code) 
					LET l_winds_text = show_ref(p_cmpy,"A","2") 
					IF l_winds_text IS NOT NULL THEN 
						LET glob_rec_customer.ref2_code = l_winds_text 
						NEXT FIELD ref2_code 
					END IF 
					
		ON ACTION "LOOKUP" infield(ref3_code) 
					LET l_winds_text = show_ref(p_cmpy,"A","3") 
					IF l_winds_text IS NOT NULL THEN 
						LET glob_rec_customer.ref3_code = l_winds_text 
						NEXT FIELD ref3_code 
					END IF 
					
		ON ACTION "LOOKUP" infield(ref4_code) 
					LET l_winds_text = show_ref(p_cmpy,"A","4") 
					IF l_winds_text IS NOT NULL THEN 
						LET glob_rec_customer.ref4_code = l_winds_text 
						NEXT FIELD ref4_code 
					END IF 
					
		ON ACTION "LOOKUP" infield(ref5_code) 
					LET l_winds_text = show_ref(p_cmpy,"A","5") 
					IF l_winds_text IS NOT NULL THEN 
						LET glob_rec_customer.ref5_code = l_winds_text 
						NEXT FIELD ref5_code 
					END IF 
					
		ON ACTION "LOOKUP" infield(ref6_code) 
					LET l_winds_text = show_ref(p_cmpy,"A","6") 
					IF l_winds_text IS NOT NULL THEN 
						LET glob_rec_customer.ref6_code = l_winds_text 
						NEXT FIELD ref6_code 
					END IF 
					
		ON ACTION "LOOKUP" infield(ref7_code) 
					LET l_winds_text = show_ref(p_cmpy,"A","7") 
					IF l_winds_text IS NOT NULL THEN 
						LET glob_rec_customer.ref7_code = l_winds_text 
						NEXT FIELD ref7_code 
					END IF 
					
		ON ACTION "LOOKUP" infield(ref8_code) 
			LET l_winds_text = show_ref(p_cmpy,"A","8") 
			IF l_winds_text IS NOT NULL THEN 
				LET glob_rec_customer.ref8_code = l_winds_text 
				NEXT FIELD ref8_code 
			END IF

		BEFORE FIELD ref1_code 
			IF glob_rec_arparms.ref1_text IS NULL THEN 
				LET l_seq_num = 1 
				NEXT FIELD ref2_code 
			END IF 

		AFTER FIELD ref1_code 
			LET l_seq_num = 1 
			CALL valid_ref(p_cmpy,"A","1",glob_rec_arparms.ref1_ind,glob_rec_customer.ref1_code) 
			RETURNING l_valid_flag,l_rec_userref.ref_desc_text 
			IF l_valid_flag THEN 
				DISPLAY l_rec_userref.ref_desc_text 
				TO ref1_desc_text 
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
			CALL valid_ref(p_cmpy,"A","2",glob_rec_arparms.ref2_ind,glob_rec_customer.ref2_code) 
			RETURNING l_valid_flag,l_rec_userref.ref_desc_text 
			IF l_valid_flag THEN 
				DISPLAY l_rec_userref.ref_desc_text 
				TO ref2_desc_text 

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
			CALL valid_ref(p_cmpy,"A","3",glob_rec_arparms.ref3_ind,glob_rec_customer.ref3_code) 
			RETURNING l_valid_flag,l_rec_userref.ref_desc_text 
			IF l_valid_flag THEN 
				DISPLAY l_rec_userref.ref_desc_text 
				TO ref3_desc_text 

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
			CALL valid_ref(p_cmpy,"A","4",glob_rec_arparms.ref4_ind,glob_rec_customer.ref4_code) 
			RETURNING l_valid_flag,l_rec_userref.ref_desc_text 
			IF l_valid_flag THEN 
				DISPLAY l_rec_userref.ref_desc_text 
				TO ref4_desc_text 

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
			CALL valid_ref(p_cmpy,"A","5",glob_rec_arparms.ref5_ind,glob_rec_customer.ref5_code) 
			RETURNING l_valid_flag,l_rec_userref.ref_desc_text 
			IF l_valid_flag THEN 
				DISPLAY l_rec_userref.ref_desc_text 
				TO ref5_desc_text 

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
			CALL valid_ref(p_cmpy,"A","6",glob_rec_arparms.ref6_ind,glob_rec_customer.ref6_code) 
			RETURNING l_valid_flag,l_rec_userref.ref_desc_text 
			IF l_valid_flag THEN 
				DISPLAY l_rec_userref.ref_desc_text 
				TO ref6_desc_text 

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
			CALL valid_ref(p_cmpy,"A","7",glob_rec_arparms.ref7_ind,glob_rec_customer.ref7_code) 
			RETURNING l_valid_flag,l_rec_userref.ref_desc_text 
			IF l_valid_flag THEN 
				DISPLAY l_rec_userref.ref_desc_text 
				TO ref7_desc_text 

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
			CALL valid_ref(p_cmpy,"A","8",glob_rec_arparms.ref8_ind,glob_rec_customer.ref8_code) 
			RETURNING l_valid_flag,l_rec_userref.ref_desc_text 
			IF l_valid_flag THEN 
				DISPLAY l_rec_userref.ref_desc_text 
				TO ref8_desc_text 

			ELSE 
				CLEAR ref8_desc_text 
				NEXT FIELD ref8_code 
			END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				CALL valid_ref(p_cmpy,"A","1",glob_rec_arparms.ref1_ind, 
				glob_rec_customer.ref1_code) 
				RETURNING l_valid_flag,l_rec_userref.ref_desc_text 
				IF NOT l_valid_flag THEN 
					NEXT FIELD ref1_code 
				END IF 
				CALL valid_ref(p_cmpy,"A","2",glob_rec_arparms.ref2_ind, 
				glob_rec_customer.ref2_code) 
				RETURNING l_valid_flag,l_rec_userref.ref_desc_text 
				IF NOT l_valid_flag THEN 
					NEXT FIELD ref2_code 
				END IF 
				CALL valid_ref(p_cmpy,"A","3",glob_rec_arparms.ref3_ind, 
				glob_rec_customer.ref3_code) 
				RETURNING l_valid_flag,l_rec_userref.ref_desc_text 
				IF NOT l_valid_flag THEN 
					NEXT FIELD ref3_code 
				END IF 
				CALL valid_ref(p_cmpy,"A","4",glob_rec_arparms.ref4_ind, 
				glob_rec_customer.ref4_code) 
				RETURNING l_valid_flag,l_rec_userref.ref_desc_text 
				IF NOT l_valid_flag THEN 
					NEXT FIELD ref4_code 
				END IF 
				CALL valid_ref(p_cmpy,"A","5",glob_rec_arparms.ref5_ind, 
				glob_rec_customer.ref5_code) 
				RETURNING l_valid_flag,l_rec_userref.ref_desc_text 
				IF NOT l_valid_flag THEN 
					NEXT FIELD ref5_code 
				END IF 
				CALL valid_ref(p_cmpy,"A","6",glob_rec_arparms.ref6_ind, 
				glob_rec_customer.ref6_code) 
				RETURNING l_valid_flag,l_rec_userref.ref_desc_text 
				IF NOT l_valid_flag THEN 
					NEXT FIELD ref6_code 
				END IF 
				CALL valid_ref(p_cmpy,"A","7",glob_rec_arparms.ref7_ind, 
				glob_rec_customer.ref7_code) 
				RETURNING l_valid_flag,l_rec_userref.ref_desc_text 
				IF NOT l_valid_flag THEN 
					NEXT FIELD ref7_code 
				END IF 
				CALL valid_ref(p_cmpy,"A","8",glob_rec_arparms.ref8_ind, 
				glob_rec_customer.ref8_code) 
				RETURNING l_valid_flag,l_rec_userref.ref_desc_text 
				IF NOT l_valid_flag THEN 
					NEXT FIELD ref8_code 
				END IF 
			END IF 

	END INPUT 
	CLOSE WINDOW A602 
	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		LET glob_rec_customer.* = l_rec_customer.* 
		RETURN FALSE 
	ELSE 
		RETURN TRUE 
	END IF 
END FUNCTION 


FUNCTION valid_ref(p_cmpy,p_source_ind,p_ref_num,p_ref_ind,p_ref_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_source_ind LIKE userref.source_ind 
	DEFINE p_ref_num LIKE userref.ref_ind 
	DEFINE p_ref_ind LIKE arparms.ref1_ind 
	DEFINE p_ref_code LIKE customer.ref1_code 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_text CHAR(20) 
	DEFINE l_msgresp LIKE language.yes_flag
	DEFINE r_status INTEGER
	DEFINE r_desc_text LIKE userref.ref_desc_text

	CASE p_source_ind 
		WHEN "A" 
			LET l_query_text = "SELECT ref",p_ref_num,"_text FROM arparms ", 
			"WHERE cmpy_code = \"",p_cmpy,"\" ", 
			"AND parm_code = \"1\" " 
		WHEN "W" 
			LET l_query_text = "SELECT ref",p_ref_num,"_text FROM mbparms ", 
			"WHERE cmpy_code = \"",p_cmpy,"\" " 
	END CASE 
	PREPARE s1_userref FROM l_query_text 
	DECLARE c1_userref CURSOR FOR s1_userref 
	OPEN c1_userref 
	FETCH c1_userref INTO l_text 
	SELECT ref_desc_text INTO r_desc_text FROM userref 
	WHERE cmpy_code = p_cmpy 
	AND source_ind = p_source_ind 
	AND ref_ind = p_ref_num 
	AND ref_code = p_ref_code 
	CASE p_ref_ind 
		WHEN "1" 
			LET r_status = TRUE 
		WHEN "2" 
			IF p_ref_code IS NULL THEN 
				LET l_msgresp = kandoomsg("A",9065,l_text) 
				#9065" Reference Code #,X,"must be Entered"
				LET r_status = FALSE 
			ELSE 
				LET r_status = TRUE 
			END IF 
		WHEN "3" 
			IF p_ref_code IS NOT NULL 
			AND sqlca.sqlcode = notfound THEN 
				LET l_msgresp = kandoomsg("A",9066,l_text) 
				#9066" Reference Code #,X," NOT found - Try Window"
				LET r_status = FALSE 
			ELSE 
				LET r_status = TRUE 
			END IF 
		WHEN "4" 
			IF p_ref_code IS NULL THEN 
				LET l_msgresp = kandoomsg("A",9065,l_text) 
				#9065" Reference Code #,X,"must be Entered"
				LET r_status = FALSE 
			ELSE 
				IF sqlca.sqlcode = notfound THEN 
					LET l_msgresp = kandoomsg("A",9066,l_text) 
					#9066" Reference Code #,X," NOT found - Try Window"
					LET r_status = FALSE 
				ELSE 
					LET r_status = TRUE 
				END IF 
			END IF 
		OTHERWISE 
			LET r_status = TRUE 
	END CASE 
	RETURN r_status,r_desc_text 
END FUNCTION 


FUNCTION make_prompt(p_ref_text) 
	DEFINE p_ref_text LIKE arparms.ref1_text 
	DEFINE r_temp_text CHAR(40)
	
	IF p_ref_text IS NULL THEN 
		LET r_temp_text = NULL 
	ELSE 
		LET r_temp_text = p_ref_text CLIPPED,"...................." 
	END IF 
	RETURN r_temp_text 
END FUNCTION 


