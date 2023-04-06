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
#  cishwind.4gl (cinq_ship)
#                FUNCTION displays shipping information on form A206
###########################################################################
###########################################################################
# MODULE Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
###########################################################################
# FUNCTION cinq_ship(p_cmpy,p_cust_code)
#
#
###########################################################################
FUNCTION cinq_ship(p_cmpy,p_cust_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_cust_code LIKE customer.cust_code 
  DEFINE l_msgresp LIKE language.yes_flag
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_name_text LIKE customer.name_text 
	DEFINE l_rec_customership RECORD LIKE customership.* 
	DEFINE l_arr_custship DYNAMIC ARRAY OF RECORD #array[150] OF RECORD 
		scroll_flag CHAR(1), 
		ship_code LIKE customership.ship_code, 
		name_text LIKE customership.name_text, 
		city_text LIKE customership.city_text, 
		post_code LIKE customership.post_code 
	END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_address_count SMALLINT # shipping_adress_count

	SELECT * 
	INTO l_rec_customer.* 
	FROM customer 
	WHERE cmpy_code = p_cmpy 
	AND cust_code = p_cust_code 
	IF STATUS = NOTFOUND THEN 
		ERROR kandoomsg2("A",9067,p_cust_code) 	#9067 Logic Error : customer ??? NOT found"
		RETURN 
	END IF 


	SELECT COUNT(*) 
	INTO l_address_count
	FROM customership 
	WHERE cmpy_code = p_cmpy 
	AND cust_code = p_cust_code 
		
	DECLARE c_shipment CURSOR FOR 
	SELECT * FROM customership 
	WHERE cmpy_code = p_cmpy 
	AND cust_code = p_cust_code 
	ORDER BY cmpy_code, 
	cust_code, 
	ship_code 
	LET l_idx = 0
	 
	FOREACH c_shipment INTO l_rec_customership.* 
		LET l_idx = l_idx + 1 
		LET l_arr_custship[l_idx].ship_code = l_rec_customership.ship_code 
		LET l_arr_custship[l_idx].name_text = l_rec_customership.name_text 
		LET l_arr_custship[l_idx].city_text = l_rec_customership.city_text 
		LET l_arr_custship[l_idx].post_code = l_rec_customership.post_code 
		IF l_rec_customership.city_text IS NULL THEN 
			LET l_arr_custship[l_idx].city_text = l_rec_customership.addr2_text 
		ELSE 
			LET l_arr_custship[l_idx].city_text = l_rec_customership.city_text 
		END IF 
--		IF l_idx = 150 THEN 
--			ERROR kandoomsg2("A",9068,"150") 		#9068 First 150 shipping addresses selected FOR this customer
--			EXIT FOREACH 
--		END IF 
	END FOREACH 
	IF l_idx = 150 THEN 
		ERROR kandoomsg2("A",9069,"") 	#9069 No shipping addresses exist FOR this customer
		RETURN 
	END IF 
--	CALL set_count(l_idx) 

	OPEN WINDOW A111 with FORM "A111" 
	CALL windecoration_a("A111") 

	LET l_name_text = l_rec_customer.name_text 
	DISPLAY l_rec_customership.cust_code TO cust_code 
	DISPLAY l_name_text TO customer.name_text  
	DISPLAY l_address_count TO shipping_adress_count

	MESSAGE  kandoomsg2("A",1007,"") #1007 F3/F4 - RETURN TO View
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	DISPLAY ARRAY l_arr_custship TO sr_custship.* ATTRIBUTE(UNBUFFERED) 
	#INPUT ARRAY l_arr_custship WITHOUT DEFAULTS FROM sr_custship.* ATTRIBUTE(UNBUFFERED)
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","cishwind","input-arr-custship") 

		BEFORE ROW 
			LET l_idx = arr_curr() 

		ON ACTION "ACCEPT" 
			IF l_idx > 0 THEN 
				CALL display_ship(p_cmpy,p_cust_code,l_arr_custship[l_idx].ship_code) 
			ELSE 
				CALL fgl_winmessage("Info","No shipping addresses found TO view","info") 
				EXIT DISPLAY 
			END IF 


		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
			#
			#      BEFORE ROW
			#         LET l_idx = arr_curr()
			#         #LET scrn = scr_line()
			#         #DISPLAY l_arr_custship[l_idx].*
			#         #     TO sr_custship[scrn].*

			#      AFTER FIELD scroll_flag
			#         IF fgl_lastkey() = fgl_keyval("accept")
			#         AND fgl_fglgui() THEN
			#            NEXT FIELD ship_code
			#         END IF
			#         LET l_arr_custship[l_idx].scroll_flag = NULL
			#         #DISPLAY l_arr_custship[l_idx].*
			#         #    TO sr_custship[scrn].*
			#
			#         IF  fgl_lastkey() = fgl_keyval("down")
			#         AND arr_curr() >= arr_count() THEN
			#            ERROR kandoomsg2("A",9001,"")
			#            NEXT FIELD scroll_flag
			#         END IF

			#      BEFORE FIELD ship_code
			#         CALL display_ship(p_cmpy,p_cust_code,l_arr_custship[l_idx].ship_code)
			#         NEXT FIELD scroll_flag

			#AFTER ROW
			#   DISPLAY l_arr_custship[l_idx].*
			#        TO sr_custship[scrn].*



	END DISPLAY 
	##################

	CLOSE WINDOW A111 
	LET int_flag = false 
	LET quit_flag = false 
END FUNCTION 


#######################################################################################
# FUNCTION display_ship(p_cmpy,p_cust_code,p_ship_code)
#
# Display Shipping Addresses
#######################################################################################
FUNCTION display_ship(p_cmpy,p_cust_code,p_ship_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_cust_code LIKE customer.cust_code 
	DEFINE p_ship_code LIKE customership.ship_code 
	DEFINE l_msgresp LIKE language.yes_flag
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_customership RECORD LIKE customership.* 
	DEFINE l_rec_country RECORD LIKE country.* 
	DEFINE l_rec_pr_warehouse RECORD LIKE warehouse.* 
	DEFINE l_rec_carrier RECORD LIKE carrier.* 
	DEFINE l_temp_prompt_text CHAR(40) 

	SELECT name_text 
	INTO l_rec_customer.name_text 
	FROM customer 
	WHERE cmpy_code = p_cmpy 
	AND cust_code = p_cust_code 

	IF STATUS = NOTFOUND THEN 
		ERROR kandoomsg2("A",9067,p_cust_code) 	#9067 Logic Error : customer ??? NOT found"
		RETURN 
	END IF 

	SELECT * 
	INTO l_rec_customership.* 
	FROM customership 
	WHERE cmpy_code = p_cmpy 
	AND cust_code = p_cust_code 
	AND ship_code = p_ship_code 

	IF STATUS = NOTFOUND THEN 
		RETURN 
	END IF 

	SELECT country.* INTO l_rec_country.* 
	FROM country, 
	company 
	WHERE company.cmpy_code = p_cmpy 
	AND country.country_code = company.country_code 

	IF STATUS = NOTFOUND THEN 
		LET l_rec_country.state_code_text = "State............." 
		LET l_rec_country.post_code_text = "Postal Code......." 
		LET l_rec_country.state_code_max_num = 6 
		LET l_rec_country.post_code_max_num = 10 
	ELSE 
		LET l_temp_prompt_text = l_rec_country.state_code_text clipped, 
		".................." 
		LET l_rec_country.state_code_text = l_temp_prompt_text 
		LET l_temp_prompt_text = l_rec_country.post_code_text clipped, 
		".................." 
		LET l_rec_country.post_code_text = l_temp_prompt_text 
	END IF 

	SELECT desc_text 
	INTO l_rec_pr_warehouse.desc_text 
	FROM warehouse 
	WHERE cmpy_code = p_cmpy 
	AND ware_code = l_rec_customership.ware_code 
	IF STATUS = NOTFOUND THEN 
		LET l_rec_pr_warehouse.desc_text = "**********" 
	END IF 
	IF l_rec_customership.carrier_code IS NOT NULL THEN 
		SELECT name_text 
		INTO l_rec_carrier.name_text 
		FROM carrier 
		WHERE cmpy_code = p_cmpy 
		AND carrier_code = l_rec_customership.carrier_code 
		IF STATUS = NOTFOUND THEN 
			LET l_rec_carrier.name_text = "**********" 
		END IF 
	END IF 

	OPEN WINDOW A206 with FORM "A206" 
	CALL windecoration_a("A206") 

	CALL db_country_localize(l_rec_customership.country_code) #Localize

	--DISPLAY l_rec_country.state_code_text TO state_code_text ATTRIBUTE(WHITE)  
	--DISPLAY l_rec_country.post_code_text TO post_code_text ATTRIBUTE(WHITE) 
	
	DISPLAY l_rec_customership.cust_code TO customership.cust_code 
	DISPLAY l_rec_customer.name_text TO cust_text
	DISPLAY l_rec_customership.name_text TO customership.name_text
	DISPLAY l_rec_carrier.name_text TO carrier_text	 

	DISPLAY l_rec_customership.ship_code TO ship_code
	DISPLAY l_rec_customership.addr_text TO addr_text 
	DISPLAY l_rec_customership.addr2_text TO addr2_text 
	DISPLAY l_rec_customership.city_text TO city_text 
	DISPLAY l_rec_customership.state_code TO state_code  --@db-patch_2020_10_04--
	DISPLAY l_rec_customership.post_code TO post_code 
	DISPLAY l_rec_customership.country_code TO country_code  --@db-patch_2020_10_04--
--@db-patch_2020_10_04--	DISPLAY l_rec_customership.country_text TO country_text
	DISPLAY l_rec_customership.contact_text TO contact_text 
	DISPLAY l_rec_customership.tele_text TO tele_text
	DISPLAY l_rec_customership.ware_code TO ware_code 
	DISPLAY l_rec_pr_warehouse.desc_text TO desc_text 
	DISPLAY l_rec_customership.carrier_code TO carrier_code 
	DISPLAY l_rec_customership.freight_ind TO freight_ind 
	DISPLAY l_rec_customership.ship1_text TO ship1_text 
	DISPLAY l_rec_customership.ship2_text TO ship2_text 

	CALL eventsuspend() 
	# ERROR kandoomsg2("U",1,"")

	CLOSE WINDOW A206 
END FUNCTION 


