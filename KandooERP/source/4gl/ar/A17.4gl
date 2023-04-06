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
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/A1_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/A17_GLOBALS.4gl" 

###########################################################################
# FUNCTION A17_main()
#
# Customer Shipping Maintanence
###########################################################################
FUNCTION A17_main() 
	DEFINE l_temp_prompt_text CHAR(40) 
	DEFINE i SMALLINT 
	DEFINE l_ship_code LIKE customership.ship_code 
	DEFINE l_msg STRING

	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("A17") --manage shipping addresses OF CURRENT customer 
	
	--SELECT * INTO glob_rec_country.* FROM country 
	--WHERE country_code = glob_rec_company.country_code 
--	#HuHo 27.08.2018 - this part was hidden/collapsed in the forms as it IS anything but good/pro
--	IF status = NOTFOUND THEN 
--		LET glob_rec_country.state_code_text = "State............." 
--		LET glob_rec_country.post_code_text = "Postal Code......." 
--		LET glob_rec_country.state_code_max_num = 6 
--		LET glob_rec_country.post_code_max_num = 10 
--	ELSE 
--		LET l_temp_prompt_text = glob_rec_country.state_code_text clipped, 
--		".................." 
--		LET glob_rec_country.state_code_text = l_temp_prompt_text 
--		LET l_temp_prompt_text = glob_rec_country.post_code_text clipped, 
--		".................." 
--		LET glob_rec_country.post_code_text = l_temp_prompt_text 
--	END IF 


	CALL fgl_winmessage("Welcome to A17","Adding a Customer Shipping Address","info")

	#####################################
	# Program can also be called with an argument TO only add a shipping address TO a customer
	IF get_url_mode() = MODE_CLASSIC_ADD THEN 
		OPEN WINDOW A206 with FORM "A206" 
		CALL windecoration_a("A206") 

		LET glob_rec_customer.cust_code = trim(get_url_cust_code()) 
		CALL db_customer_get_rec(UI_ON,glob_rec_customer.cust_code) RETURNING glob_rec_customer.*

		IF glob_rec_customer.cust_code IS NULL THEN
			LET l_msg =  "Invalid customer code", trim(glob_rec_customer.cust_code), "\nExit Application"
			CALL fgl_winmessage("Invalid customer code",l_msg,"error") 
			EXIT PROGRAM 
		END IF 

		CALL db_country_localize(glob_rec_customer.country_code) #Localize

		LET l_ship_code = add_ship(get_url_SHIP_CODE())
		 
		CLOSE WINDOW A206 
		RETURN l_ship_code 
	END IF 
	#####################################



	OPEN WINDOW A111 with FORM "A111" 
	CALL windecoration_a("A111") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

--	WHILE select_cust() 
		CALL scan_ship() 
--		INITIALIZE glob_rec_customer.* TO NULL 

--		IF get_url_cust_code() IS NOT NULL THEN 
--			EXIT WHILE 
--		END IF 
--	END WHILE 

	CLOSE WINDOW A111 
END FUNCTION
################################################################
# END FUNCTION A17_main()
################################################################


################################################################
# FUNCTION select_cust()
#
#
################################################################
FUNCTION select_cust()
	DEFINE l_name_text LIKE customer.name_text 
	DEFINE l_query_text STRING --CHAR(1000) 
	DEFINE l_where_text STRING --CHAR(300) 
	DEFINE l_cnt INTEGER 
	DEFINE l_msg STRING 
	DEFINE l_temp_text STRING
	CLEAR FORM 

	MESSAGE kandoomsg2("A",1014,"") #1014 Enter customer code FOR shipping address details

	INITIALIZE glob_rec_customer.* TO NULL
	IF get_url_cust_code() IS NOT NULL THEN 
		CALL db_customer_get_rec(UI_ON,get_url_cust_code()) RETURNING glob_rec_customer.* 

		IF glob_rec_customer.* IS NOT NULL THEN 
			RETURN glob_rec_customer.cust_code #NOT INPUT if cust_code was specified and is valid
		ELSE
			LET l_msg = "Invalid customer_code argument specified in URL!\nCUSTOMER_CODE=",trim(get_url_cust_code()),"\nCustomer not found!\nExit Application" 
			CALL fgl_winmessage("Invalid customer code",l_msg,"error") 
		END IF
	END IF
			
	INPUT glob_rec_customer.cust_code FROM cust_code ATTRIBUTE(UNBUFFERED)
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A17","inp-cust_code") 

		ON CHANGE cust_code
			DISPLAY db_customer_get_name_text(UI_OFF,glob_rec_customer.cust_code) TO customer.name_text

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		ON ACTION "LOOKUP" --ON KEY (control-b) 
			LET l_temp_text = show_clnt(glob_rec_kandoouser.cmpy_code) 

			IF l_temp_text IS NOT NULL THEN 
				LET glob_rec_customer.cust_code = trim(l_temp_text) 
				NEXT FIELD cust_code 
			END IF 


		AFTER FIELD cust_code 
			CALL db_customer_get_rec(UI_OFF,glob_rec_customer.cust_code) RETURNING glob_rec_customer.* 
--			SELECT * INTO glob_rec_customer.* 
--			FROM customer 
--			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
--			AND cust_code = glob_rec_customer.cust_code 
			IF glob_rec_customer.cust_code IS NULL THEN
				ERROR kandoomsg2("A",9009,"") 
				CLEAR name_text 
				NEXT FIELD cust_code 
			END IF 
			
			IF glob_rec_customer.delete_flag = "Y" THEN 
				ERROR kandoomsg2("A",9144,"") 			#9144 Customer IS marked FOR deletion - Unmark before proceeding
				CLEAR name_text 
				NEXT FIELD cust_code 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL  --false 
	ELSE 
		DISPLAY glob_rec_customer.cust_code TO cust_code 
		DISPLAY glob_rec_customer.name_text TO name_text

		SELECT count(*) INTO l_cnt FROM customership 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = glob_rec_customer.cust_code 
		DISPLAY l_cnt TO shipping_adress_count
		
		RETURN glob_rec_customer.cust_code
	END IF
		
		
--		IF l_cnt > 10 THEN 
--			ERROR kandoomsg2("U",1001,"") 
--
--			CONSTRUCT BY NAME l_where_text ON customership.ship_code, 
--			customership.name_text, 
--			customership.city_text, 
--			customership.post_code 
--
--
--				BEFORE CONSTRUCT 
--					CALL publish_toolbar("kandoo","A17","construct-customership") 
--
--				ON ACTION "WEB-HELP" 
--					CALL onlinehelp(getmoduleid(),null) 
--
--				ON ACTION "actToolbarManager" 
--					CALL setuptoolbar() 
--
--			END CONSTRUCT 
--
--		IF int_flag OR quit_flag THEN 
--				LET int_flag = false 
--				LET quit_flag = false 
--				RETURN NULL --false
--			ELSE 
--			 		RETURN glob_rec_customer.cust_code
--			 
--			END IF 
{
-------------		

		ELSE 
			LET l_where_text = "1=1" 
		END IF 

		ERROR kandoomsg2("U",1002,"") 
		LET l_query_text = "SELECT * FROM customership ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code CLIPPED,"' ", 
		"AND cust_code = '",glob_rec_customer.cust_code CLIPPED,"' ", 
		"AND ", l_where_text clipped, " ", 
		"ORDER BY cust_code,ship_code" 

		PREPARE s_customership FROM l_query_text 
		DECLARE c_custship CURSOR FOR s_customership 
		RETURN true 
	END IF 
-----------------
}
END FUNCTION 
################################################################
# END FUNCTION select_cust()
################################################################


################################################################
# FUNCTION shipping_address_datasource(p_ship_code)
#
#
################################################################
FUNCTION shipping_address_datasource(p_ship_code)
	DEFINE p_ship_code LIKE customership.ship_code
	DEFINE l_rec_customership RECORD LIKE customership.*	
	DEFINE l_arr_rec_custship DYNAMIC ARRAY OF RECORD --array[300] OF RECORD 
		scroll_flag CHAR(1), 
		ship_code LIKE customership.ship_code, 
		name_text LIKE customership.name_text, 
		city_text LIKE customership.city_text, 
		post_code LIKE customership.post_code 
	END RECORD
	DEFINE l_idx SMALLINT 
	DEFINE l_del_qty SMALLINT 
	DEFINE l_scroll_flag CHAR(1) 

	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 

	#Temp huho.. needs changing
	LET l_where_text = " 1 = 1 "

		ERROR kandoomsg2("U",1002,"") 
		LET l_query_text = "SELECT * FROM customership ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code CLIPPED,"' ", 
		"AND cust_code = '",glob_rec_customer.cust_code CLIPPED,"' ", 
		"AND ", l_where_text clipped, " ", 
		"ORDER BY cust_code,ship_code" 

		PREPARE s_customership FROM l_query_text 
		DECLARE c_custship CURSOR FOR s_customership 


	LET l_idx = 0 

	FOREACH c_custship INTO l_rec_customership.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_custship[l_idx].ship_code = l_rec_customership.ship_code 
		LET l_arr_rec_custship[l_idx].name_text = l_rec_customership.name_text 
		IF l_rec_customership.city_text IS NULL 
		OR l_rec_customership.city_text = " " THEN 
			LET l_arr_rec_custship[l_idx].city_text = l_rec_customership.addr2_text 
		ELSE 
			LET l_arr_rec_custship[l_idx].city_text = l_rec_customership.city_text 
		END IF 

		LET l_arr_rec_custship[l_idx].post_code = l_rec_customership.post_code 

	END FOREACH 

	RETURN l_arr_rec_custship
END FUNCTION
################################################################
# END FUNCTION shipping_address_datasource(p_ship_code)
################################################################


################################################################
# FUNCTION scan_ship()
#
#
################################################################
FUNCTION scan_ship() 
	DEFINE l_rec_customership RECORD LIKE customership.*
	DEFINE l_arr_rec_custship DYNAMIC ARRAY OF RECORD --array[300] OF RECORD 
		scroll_flag CHAR(1), 
		ship_code LIKE customership.ship_code, 
		name_text LIKE customership.name_text, 
		city_text LIKE customership.city_text, 
		post_code LIKE customership.post_code 
	END RECORD
	DEFINE l_idx SMALLINT
	DEFINE l_del_qty SMALLINT 
	DEFINE l_scroll_flag CHAR(1) 
	DEFINE i SMALLINT #just for a debug test.. remove this later

	CALL select_cust()
	CALL shipping_address_datasource(trim(glob_rec_customer.cust_code)) RETURNING l_arr_rec_custship

	LET l_del_qty = 0 
	LET l_idx = l_arr_rec_custship.getSize()


	IF l_idx = 0 THEN 
		ERROR kandoomsg2("A",9069,"") 	#9069 No shipping addresses exist FOR this customer
		LET l_idx = 1 
	END IF 

	OPTIONS INSERT KEY f1, 
	DELETE KEY f36 

	--CALL set_count(l_idx) 
	ERROR kandoomsg2("A",1003,"") #1003 F1 add - f2 delete - RETURN edit

	IF get_debug() THEN
		FOR i = 1 TO l_arr_rec_custship.getSize()  #just for debug to show array data
			DISPLAY l_arr_rec_custship[i].scroll_flag
			DISPLAY l_arr_rec_custship[i].ship_code
			DISPLAY l_arr_rec_custship[i].name_text
			DISPLAY l_arr_rec_custship[i].city_text
			DISPLAY l_arr_rec_custship[i].post_code
		END FOR
	END IF
	INPUT ARRAY l_arr_rec_custship WITHOUT DEFAULTS FROM sr_custship.* ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A17","inp-arr-custship") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER"
			CALL select_cust()
			CALL l_arr_rec_custship.clear()
			CALL shipping_address_datasource(trim(glob_rec_customer.cust_code)) RETURNING l_arr_rec_custship 

		BEFORE FIELD scroll_flag 
			LET l_idx = arr_curr() 
			#LET scrn = scr_line()
			LET l_scroll_flag = l_arr_rec_custship[l_idx].scroll_flag 
			#DISPLAY l_arr_rec_custship[l_idx].*
			#     TO sr_custship[scrn].*

		AFTER FIELD scroll_flag 
			LET l_arr_rec_custship[l_idx].scroll_flag = l_scroll_flag 
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF arr_curr() >= arr_count() THEN 
					ERROR kandoomsg2("A",9001,"") 
					NEXT FIELD scroll_flag 
				END IF 
				IF l_arr_rec_custship[l_idx+1].ship_code IS NULL THEN 
					ERROR kandoomsg2("A",9001,"") 
					NEXT FIELD scroll_flag 
				END IF 
			END IF 

		ON ACTION ("EDIT","doubleClick") 

			IF l_arr_rec_custship[l_idx].ship_code IS NOT NULL THEN 

				OPEN WINDOW A206 with FORM "A206" 
				CALL windecoration_a("A206") 

				IF edit_ship(l_arr_rec_custship[l_idx].ship_code) THEN 
					SELECT name_text, 
					city_text, 
					post_code 
					INTO l_arr_rec_custship[l_idx].name_text, 
					l_arr_rec_custship[l_idx].city_text, 
					l_arr_rec_custship[l_idx].post_code 
					FROM customership 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cust_code = glob_rec_customer.cust_code  
					AND ship_code = l_arr_rec_custship[l_idx].ship_code  

					IF l_arr_rec_custship[l_idx].city_text IS NULL THEN 
						SELECT addr2_text 
						INTO l_arr_rec_custship[l_idx].city_text 
						FROM customership 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cust_code = glob_rec_customer.cust_code 
						AND ship_code = l_arr_rec_custship[l_idx].ship_code 
					END IF 

				END IF 

				OPTIONS DELETE KEY f36, 
				INSERT KEY f1 
				CLOSE WINDOW A206 

			END IF 

			NEXT FIELD scroll_flag 


		BEFORE FIELD ship_code 
			IF l_arr_rec_custship[l_idx].ship_code IS NOT NULL THEN 

				OPEN WINDOW A206 with FORM "A206" 
				CALL windecoration_a("A206") 

				IF edit_ship(l_arr_rec_custship[l_idx].ship_code) THEN 
					SELECT name_text, 
					city_text, 
					post_code 
					INTO l_arr_rec_custship[l_idx].name_text, 
					l_arr_rec_custship[l_idx].city_text, 
					l_arr_rec_custship[l_idx].post_code 
					FROM customership 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cust_code = glob_rec_customer.cust_code 
					AND ship_code = l_arr_rec_custship[l_idx].ship_code 

					IF l_arr_rec_custship[l_idx].city_text IS NULL THEN 
						SELECT addr2_text 
						INTO l_arr_rec_custship[l_idx].city_text 
						FROM customership 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cust_code = glob_rec_customer.cust_code 
						AND ship_code = l_arr_rec_custship[l_idx].ship_code 
					END IF 

				END IF 

				OPTIONS DELETE KEY f36, 
				INSERT KEY f1 
				CLOSE WINDOW A206 
			END IF 

			NEXT FIELD scroll_flag 

		BEFORE INSERT 
			IF arr_curr() < arr_count() THEN 

				OPEN WINDOW A206 with FORM "A206" 
				CALL windecoration_a("A206") 

				LET l_arr_rec_custship[l_idx].ship_code = add_ship(NULL) 
				CLOSE WINDOW A206 

				SELECT name_text, 
				city_text, 
				post_code 
				INTO l_arr_rec_custship[l_idx].name_text, 
				l_arr_rec_custship[l_idx].city_text, 
				l_arr_rec_custship[l_idx].post_code 
				FROM customership 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = glob_rec_customer.cust_code 
				AND ship_code = l_arr_rec_custship[l_idx].ship_code 

				IF status = NOTFOUND THEN 

					FOR l_idx = arr_curr() TO arr_count() 
						LET l_arr_rec_custship[l_idx].* = l_arr_rec_custship[l_idx+1].* 
						#IF scrn <= 12 THEN
						#   DISPLAY l_arr_rec_custship[l_idx].*
						#        TO sr_custship[scrn].*
						#
						#   LET scrn = scrn + 1
						#END IF
					END FOR 

					INITIALIZE l_arr_rec_custship[l_idx].* TO NULL 

				ELSE 

					IF l_arr_rec_custship[l_idx].city_text IS NULL THEN 
						SELECT addr2_text 
						INTO l_arr_rec_custship[l_idx].city_text 
						FROM customership 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cust_code = glob_rec_customer.cust_code 
						AND ship_code = l_arr_rec_custship[l_idx].ship_code 
					END IF 
				END IF 

				OPTIONS DELETE KEY f36, 
				INSERT KEY f1 

			ELSE 

				IF l_idx > 1 THEN 
					ERROR kandoomsg2("A",9001,"") 					# There are no more rows in the direction you are going "
				END IF 
			END IF 
			NEXT FIELD scroll_flag 

		ON KEY (F2) --delete 
			IF l_arr_rec_custship[l_idx].ship_code IS NOT NULL THEN 

				IF l_arr_rec_custship[l_idx].scroll_flag IS NULL THEN 
					SELECT unique 1 FROM invoicehead 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cust_code = glob_rec_customer.cust_code 
					AND ship_code = l_arr_rec_custship[l_idx].ship_code 
					AND paid_amt != total_amt 

					IF status = 0 THEN 
						ERROR kandoomsg2("A",7015,l_arr_rec_custship[l_idx].ship_code) 						#7015 Shipping address IS in use Deleteion NOT permitted
					ELSE 
						LET l_arr_rec_custship[l_idx].scroll_flag = "*" 
						CALL ui.interface.refresh() #huho just temporary TO demonstrate TABLE refresh 
						LET l_del_qty = l_del_qty + 1 
					END IF 

				ELSE 
					LET l_arr_rec_custship[l_idx].scroll_flag = NULL 
					LET l_del_qty = l_del_qty - 1 
				END IF 

			END IF 

			NEXT FIELD scroll_flag 


			#AFTER ROW
			#   DISPLAY l_arr_rec_custship[l_idx].*
			#        TO sr_custship[scrn].*

	END INPUT 
	#######################


	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 

		IF l_del_qty != 0 THEN 

			IF kandoomsg("A",8006,l_del_qty) = "Y" THEN #8006 Confirm TO Delete ",l_del_qty,"Shipping address? (Y/N)"
				FOR l_idx = 1 TO arr_count() 

					IF l_arr_rec_custship[l_idx].scroll_flag = "*" THEN 
						SELECT unique 1 FROM invoicehead 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cust_code = glob_rec_customer.cust_code 
						AND ship_code = l_arr_rec_custship[l_idx].ship_code 
						AND paid_amt != total_amt 

						IF status = 0 THEN 
							ERROR kandoomsg2("A",7015,l_arr_rec_custship[l_idx].ship_code) 			#7010 Shipping address IS in use Deleteion NOT permitted
						ELSE 
							DELETE FROM customership 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND cust_code = glob_rec_customer.cust_code 
							AND ship_code = l_arr_rec_custship[l_idx].ship_code 
						END IF 
					END IF 
				END FOR 
			END IF 
		END IF 
	END IF 
END FUNCTION 
################################################################
# END FUNCTION scan_ship()
################################################################
 

################################################################
# FUNCTION add_ship()
#
#
################################################################
FUNCTION add_ship(p_cust_code) 
	DEFINE p_cust_code LIKE customer.cust_code
	DEFINE l_rec_customership RECORD LIKE customership.*
	DEFINE l_rec_warehouse RECORD LIKE warehouse.*
	DEFINE l_rec_carrier RECORD LIKE carrier.*
	DEFINE l_rec_suburb RECORD LIKE suburb.*
	DEFINE l_rec_street RECORD LIKE street.*
	DEFINE l_rec_suburb_code, l_rec_rowid INTEGER 
	DEFINE l_temp_text STRING
	DEFINE msgstr STRING 

	IF p_cust_code IS NULL THEN
		LET l_rec_customership.cust_code = trim(glob_rec_customer.cust_code) 
		LET l_rec_customership.name_text = trim(glob_rec_customer.name_text) 
	ELSE
		LET l_rec_customership.cust_code = trim(glob_rec_customer.cust_code)
		LET l_rec_customership.name_text = trim(db_customer_get_name_text(UI_OFF,l_rec_customership.cust_code)) 
	END IF
	
	DISPLAY l_rec_customership.cust_code TO customership.cust_code 
	DISPLAY glob_rec_customer.name_text TO cust_text
	DISPLAY l_rec_customership.name_text TO customership.name_text 

	CALL db_country_localize(l_rec_customership.country_code) --@db-patch_2020_10_04-- #Localize

	ERROR kandoomsg2("U",1020,"Customer Shipping")	#1020 Enter Customer Shipping Details
	
	#Default value for shipping code
	IF l_rec_customership.ship_code IS NULL THEN
		LET l_rec_customership.ship_code = trim(glob_rec_customer.cust_code)
	END IF

	INPUT BY NAME 
		l_rec_customership.ship_code, 
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
			CALL publish_toolbar("kandoo","A17","inp-customership-1") 
			
			IF l_rec_customership.country_code IS NULL THEN --@db-patch_2020_10_04--
				LET l_rec_customership.country_code = get_default_country_code() --@db-patch_2020_10_04--
			END IF
		
			CALL db_country_localize(l_rec_customership.country_code) --@db-patch_2020_10_04-- #Localize
			--CALL combolist_state ("state_code", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,l_rec_customership.state_code,combo_null_space) 

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

		ON ACTION "LOOKUP" infield (carrier_code) 
			LET l_temp_text = show_carrier(glob_rec_kandoouser.cmpy_code,"") 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_customership.carrier_code = l_temp_text 
				NEXT FIELD carrier_code 
			END IF 

		ON ACTION "LOOKUP" infield (addr2_text) 
			LET l_rec_rowid = show_wstreet(glob_rec_kandoouser.cmpy_code) 

			IF l_rec_rowid != 0 THEN 
				SELECT * INTO l_rec_street.* FROM street 
				WHERE rowid = l_rec_rowid 

				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("W",9005,"") 				#9005 Logic error: Street name NOT found"
					NEXT FIELD addr2_text 
				END IF 

				INITIALIZE l_rec_suburb.* TO NULL 

				SELECT * INTO l_rec_suburb.* FROM suburb 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND suburb_code = l_rec_street.suburb_code 

				LET l_rec_customership.addr2_text=l_rec_street.street_text clipped, 
				" ", l_rec_street.st_type_text 
				LET l_rec_customership.city_text = l_rec_suburb.suburb_text 
				LET l_rec_customership.state_code = l_rec_suburb.state_code 
				LET l_rec_customership.post_code = l_rec_suburb.post_code 
				LET l_rec_customership.contract_text = 
				l_rec_street.map_number clipped, 
				" ", l_rec_street.ref_text 
				
				DISPLAY BY NAME l_rec_customership.addr2_text, 
				l_rec_customership.city_text, 
				l_rec_customership.state_code, 
				l_rec_customership.post_code 

			END IF 
			NEXT FIELD addr2_text 

		ON ACTION "LOOKUP" infield (city_text) 
			LET l_rec_suburb_code = show_wsub(glob_rec_kandoouser.cmpy_code) 
			IF l_rec_suburb_code != 0 THEN 
				INITIALIZE l_rec_suburb.* TO NULL 
				SELECT * INTO l_rec_suburb.* FROM suburb 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND suburb_code = l_rec_suburb_code 

				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("W",9006,"") 					#9006 Logic error: Suburb NOT found"
					NEXT FIELD city_text 
				END IF 

				LET l_rec_customership.city_text = l_rec_suburb.suburb_text 
				LET l_rec_customership.state_code = l_rec_suburb.state_code 
				LET l_rec_customership.post_code = l_rec_suburb.post_code 

				DISPLAY BY NAME l_rec_customership.city_text, 
				l_rec_customership.state_code, 
				l_rec_customership.post_code 

			END IF 
			NEXT FIELD city_text 

		AFTER FIELD country_text
			CALL db_country_localize(l_rec_customership.country_code) --@db-patch_2020_10_04-- #Localize		 
			--CALL combolist_state ("state_code", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,l_rec_customership.state_code,combo_null_space) 

		AFTER FIELD ship_code 
			IF l_rec_customership.ship_code IS NULL THEN 
				ERROR kandoomsg2("A",9028,"") 		#9028 " Must enter a Shipping code "
				NEXT FIELD ship_code 
			ELSE 
				SELECT unique 1 FROM customership 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = glob_rec_customer.cust_code 
				AND ship_code = l_rec_customership.ship_code 

				IF status = 0 THEN 
					ERROR kandoomsg2("A",9026,"") 		#9026 " This Shipping ID has already been used"
					NEXT FIELD ship_code 
				END IF 
			END IF 

		AFTER FIELD ware_code 
			IF l_rec_customership.ware_code IS NOT NULL THEN 
				SELECT desc_text INTO l_rec_warehouse.desc_text FROM warehouse 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = l_rec_customership.ware_code 

				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("A",9041,"") 		#9041" Warehouse code NOT found - Try Window"
					CLEAR warehouse.desc_text 
					NEXT FIELD ware_code 
				ELSE 
					DISPLAY l_rec_warehouse.desc_text 
					TO warehouse.desc_text 

				END IF 
			END IF 

		AFTER FIELD carrier_code 
			IF l_rec_customership.carrier_code IS NOT NULL THEN 
				SELECT name_text INTO l_rec_carrier.name_text FROM carrier 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND carrier_code = l_rec_customership.carrier_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("A",9042,"") 				#9042" Carrier code NOT found - Try Window"
					CLEAR carrier_text 
					NEXT FIELD carrier_code 
				ELSE 
					DISPLAY l_rec_carrier.name_text 
					TO carrier_text 

				END IF 
			END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF l_rec_customership.ware_code IS NOT NULL THEN 
					IF NOT db_warehouse_pk_exists(UI_OFF,l_rec_customership.ware_code) THEN 
						ERROR kandoomsg2("A",9041,"") #9041" Warehouse code NOT found - Try Window"
						NEXT FIELD ware_code 
					END IF 
				END IF 

				IF l_rec_customership.carrier_code IS NOT NULL 
				AND l_rec_customership.freight_ind IS NULL THEN 
					ERROR kandoomsg2("A",9059,"") #9059" Freight rate level must be entered FOR Carrier"
					NEXT FIELD freight_ind 
				END IF 
			END IF 

	END INPUT 
	#-----------------------------------

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		CALL clear_user_clipboard() 
		RETURN NULL 
	ELSE 
		LET l_rec_customership.cmpy_code = glob_rec_kandoouser.cmpy_code 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
		INSERT INTO customership VALUES (l_rec_customership.*) 

		IF sqlca.sqlcode != 0 THEN --huho - added some ERROR handling AND clipboard copy 
			CALL clear_user_clipboard() 
			LET msgstr = "Could NOT store the Shipping Address ", trim(l_rec_customership.ship_code), " for customer ", trim(l_rec_customership.cust_code), " !\nERROR CODE: sqlca.sqlcode=", trim(sqlca.sqlcode) 
			CALL fgl_winmessage("Error on Shipping Address","Kandoo was NOT able TO create the shipping address","error") 
		ELSE 
			CALL set_db_clipboard_string_val(l_rec_customership.ship_code) 
			LET msgstr = "Shipping Address ", trim(l_rec_customership.ship_code), " for customer ", trim(l_rec_customership.cust_code), " created." 
			CALL fgl_winmessage("Success","Shipping Address stored","info") 
		END IF 

		RETURN l_rec_customership.ship_code 
	END IF 

END FUNCTION 
################################################################
# END FUNCTION add_ship()
################################################################


################################################################
# FUNCTION edit_ship(p_ship_code)
#
#
################################################################
FUNCTION edit_ship(p_ship_code) 
	DEFINE p_ship_code LIKE customership.ship_code 
	DEFINE l_rec_customership RECORD LIKE customership.* 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_rec_carrier RECORD LIKE carrier.* 
	DEFINE l_rec_suburb RECORD LIKE suburb.* 
	DEFINE l_rec_street RECORD LIKE street.* 
	DEFINE l_rec_suburb_code INTEGER
	DEFINE l_rec_rowid INTEGER 
	DEFINE l_temp_text STRING

	SELECT * 
	INTO l_rec_customership.* 
	FROM customership 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cust_code = glob_rec_customer.cust_code 
	AND ship_code = p_ship_code 
	IF status = NOTFOUND THEN 
		RETURN false 
	END IF 

	DISPLAY l_rec_customership.cust_code TO customership.cust_code
	DISPLAY glob_rec_customer.name_text TO cust_text
	DISPLAY l_rec_customership.ship_code TO customership.ship_code  

	CALL db_country_localize(l_rec_customership.country_code) --@db-patch_2020_10_04-- #Localize	

	MESSAGE kandoomsg2("U",1020,"Customer Shipping") #1020 Enter Customer Shipping Details
	INPUT BY NAME l_rec_customership.name_text, 
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
			CALL publish_toolbar("kandoo","A17","inp-customership-2") 

		ON CHANGE country_text 
			CALL db_country_localize(l_rec_customership.country_code) --@db-patch_2020_10_04-- #Localize	

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
			
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

			################################################################
			# X
			################################################################

		ON ACTION "LOOKUP" infield (ware_code) 
			LET l_temp_text = show_ware(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_customership.ware_code = l_temp_text 
				NEXT FIELD ware_code 
			END IF 

		ON ACTION "LOOKUP" infield (carrier_code) 
			LET l_temp_text = show_carrier(glob_rec_kandoouser.cmpy_code,"") 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_customership.carrier_code = l_temp_text 
				NEXT FIELD carrier_code 
			END IF 

		ON ACTION "LOOKUP" infield (addr2_text) 
			LET l_rec_rowid = show_wstreet(glob_rec_kandoouser.cmpy_code) 

			IF l_rec_rowid != 0 THEN 
				SELECT * INTO l_rec_street.* FROM street 
				WHERE rowid = l_rec_rowid 

				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("W",9005,"") 					#9005 Logic error: Street name NOT found"
					NEXT FIELD addr2_text 
				END IF 

				INITIALIZE l_rec_suburb.* TO NULL 
				SELECT * INTO l_rec_suburb.* FROM suburb 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND suburb_code = l_rec_street.suburb_code 

				LET l_rec_customership.addr2_text=l_rec_street.street_text clipped, 
				" ", l_rec_street.st_type_text 
				LET l_rec_customership.city_text = l_rec_suburb.suburb_text 
				LET l_rec_customership.state_code = l_rec_suburb.state_code 
				LET l_rec_customership.post_code = l_rec_suburb.post_code 
				LET l_rec_customership.contract_text = 
				l_rec_street.map_number clipped, 
				" ", l_rec_street.ref_text 

				DISPLAY BY NAME l_rec_customership.addr2_text, 
				l_rec_customership.city_text, 
				l_rec_customership.state_code, 
				l_rec_customership.post_code 

			END IF 

			NEXT FIELD addr2_text 

		ON ACTION "LOOKUP" infield (city_text) 
			LET l_rec_suburb_code = show_wsub(glob_rec_kandoouser.cmpy_code) 

			IF l_rec_suburb_code != 0 THEN 
				INITIALIZE l_rec_suburb.* TO NULL 
				SELECT * INTO l_rec_suburb.* FROM suburb 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND suburb_code = l_rec_suburb_code 

				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("W",9006,"") 					#9006 Logic error: Suburb NOT found"
					NEXT FIELD city_text 
				END IF 

				LET l_rec_customership.city_text = l_rec_suburb.suburb_text 
				LET l_rec_customership.state_code = l_rec_suburb.state_code 
				LET l_rec_customership.post_code = l_rec_suburb.post_code 
				
				DISPLAY BY NAME l_rec_customership.city_text, 
				l_rec_customership.state_code, 
				l_rec_customership.post_code 

			END IF 
			NEXT FIELD city_text 

		AFTER FIELD ware_code 
			IF l_rec_customership.ware_code IS NOT NULL THEN 
				SELECT desc_text INTO l_rec_warehouse.desc_text FROM warehouse 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = l_rec_customership.ware_code 

				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("A",9041,"") 					#9041" Warehouse code NOT found - Try Window"
					CLEAR warehouse.desc_text 
					NEXT FIELD ware_code 
				ELSE 
					DISPLAY l_rec_warehouse.desc_text 
					TO warehouse.desc_text 

				END IF 
			END IF 

		AFTER FIELD carrier_code 
			IF l_rec_customership.carrier_code IS NOT NULL THEN 
				SELECT name_text INTO l_rec_carrier.name_text FROM carrier 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND carrier_code = l_rec_customership.carrier_code 

				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("A",9042,"") 					#9042" Carrier code NOT found - Try Window"
					CLEAR carrier_text 
					NEXT FIELD carrier_code 
				ELSE 
					DISPLAY l_rec_carrier.name_text 
					TO carrier_text 

				END IF 
			END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 

				IF l_rec_customership.ware_code IS NOT NULL THEN 
					SELECT desc_text INTO l_rec_warehouse.desc_text FROM warehouse 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND ware_code = l_rec_customership.ware_code 
					IF status = NOTFOUND THEN 
						ERROR kandoomsg2("A",9041,"") 						#9041" Warehouse code NOT found - Try Window"
						NEXT FIELD ware_code 
					END IF 
				END IF 

				IF l_rec_customership.carrier_code IS NOT NULL 
				AND l_rec_customership.freight_ind IS NULL THEN 
					ERROR kandoomsg2("A",9059,"") 					#9059" Freight rate level must be entered FOR Carrier"
					NEXT FIELD freight_ind 
				END IF 
			END IF 

	END INPUT 
	#-----------------------------------

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		UPDATE customership 
		SET * = l_rec_customership.* 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = glob_rec_customer.cust_code 
		AND ship_code = p_ship_code 
		RETURN true 
	END IF 
END FUNCTION 
################################################################
# END FUNCTION edit_ship(p_ship_code)
################################################################