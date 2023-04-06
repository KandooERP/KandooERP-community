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
# A20,A21,A22,A27
# Shipping Address INPUT
############################################################
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/A2_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/A20_GLOBALS.4gl"


########################################################################
# FUNCTION enter_invoice_shipping_addr(p_mode)
###
### This FUNCTION opens the shipping address box in top right hand corner.
### A default ship address IS displayed AND may be changed by the user.
###
########################################################################
FUNCTION enter_invoice_shipping_addr(p_mode) 
	DEFINE p_mode STRING 
	DEFINE l_rec_customership RECORD LIKE customership.* 
	DEFINE l_save_ship_code LIKE customership.ship_code 
	DEFINE i SMALLINT 
	DEFINE l_run_arg STRING 
	DEFINE l_run_arg1 STRING 
	DEFINE l_run_arg2 STRING 
	DEFINE l_ret_nav SMALLINT 	#Wizard Style Navigation NAV_BACKWARD=0 NAV_FORWARD SMALLINT=1 NAV_CANCEL SMALLINT=-1 NAV_DONE SMALLINT = 2	
	
	LET l_ret_nav = NAV_FORWARD

	IF p_mode = MODE_CLASSIC_ADD THEN 
		#---------------------------------------
		# obtain default shipping address
		#
		SELECT count(*) INTO i 
		FROM customership 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = glob_rec_invoicehead.cust_code 
		DISPLAY i TO formonly.addr_cnt 

		CASE 
			WHEN i = 0 ## no ship adresses SET up - use billing address 
			WHEN i = 1 
				#'---------------------------------------------------
				# One shipping address SET up. This becomes default
				SELECT ship_code INTO glob_rec_invoicehead.ship_code 
				FROM customership 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = glob_rec_invoicehead.cust_code 
			OTHERWISE 
				
				#---------------------------------------------------------------
				# IF multiple addresses SET up THEN try FOR one with same code
				# as customer.  IF NOT SET up THEN SELECT any as default.
				SELECT unique 1 FROM customership 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = glob_rec_invoicehead.cust_code 
				AND ship_code = glob_rec_invoicehead.cust_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					DECLARE c_custship CURSOR FOR 
					SELECT ship_code FROM customership 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cust_code = glob_rec_invoicehead.cust_code 
					OPEN c_custship 
					FETCH c_custship INTO glob_rec_invoicehead.ship_code 
				ELSE 
					LET glob_rec_invoicehead.ship_code = glob_rec_invoicehead.cust_code 
				END IF 
		END CASE 

		CALL db_customership_get_rec(UI_OFF,glob_rec_invoicehead.cust_code,glob_rec_invoicehead.ship_code) RETURNING l_rec_customership.*

		LET glob_rec_invoicehead.ship_code = l_rec_customership.ship_code 
		LET glob_rec_invoicehead.name_text = l_rec_customership.name_text 
		LET glob_rec_invoicehead.addr1_text = l_rec_customership.addr_text 
		LET glob_rec_invoicehead.addr2_text = l_rec_customership.addr2_text 
		LET glob_rec_invoicehead.city_text = l_rec_customership.city_text 
		LET glob_rec_invoicehead.state_code = l_rec_customership.state_code 
		LET glob_rec_invoicehead.post_code = l_rec_customership.post_code 
		LET glob_rec_invoicehead.country_code = l_rec_customership.country_code --@db-patch_2020_10_04--
		LET glob_rec_invoicehead.contact_text = l_rec_customership.contact_text 
		LET glob_rec_invoicehead.tele_text = l_rec_customership.tele_text 
		LET glob_rec_invoicehead.mobile_phone = l_rec_customership.mobile_phone		
		LET glob_rec_invoicehead.email = l_rec_customership.email		
	ELSE 
		LET l_rec_customership.ship_code = glob_rec_invoicehead.ship_code 
	END IF 

	LET glob_rec_invoicehead.invoice_to_ind = glob_rec_customer.invoice_to_ind 

	MESSAGE kandoomsg2("A",1063,"") #A1063 Enter Shipping Address 
	INPUT 
		glob_rec_invoicehead.ship_code, 
		glob_rec_invoicehead.name_text, 
		glob_rec_invoicehead.addr1_text, 
		glob_rec_invoicehead.addr2_text, 
		glob_rec_invoicehead.city_text, 
		glob_rec_invoicehead.state_code, 
		glob_rec_invoicehead.post_code, 
		glob_rec_invoicehead.country_code, --@db-patch_2020_10_04--
		glob_rec_invoicehead.contact_text, 
		glob_rec_invoicehead.tele_text,
		glob_rec_invoicehead.mobile_phone,
		glob_rec_invoicehead.email WITHOUT DEFAULTS 
	FROM
		ship_code, 
		invoicehead.name_text, 
		addr1_text, 
		addr2_text, 
		city_text, 
		state_code, 
		post_code, 
		country_code, 
		contact_text, 
		tele_text, 
		mobile_phone, 
		email	ATTRIBUTE(UNBUFFERED) 


		BEFORE INPUT
			CALL fgl_dialog_setkeylabel("ACCEPT","Next","{CONTEXT}/public/querix/icon/svg/24/ic_navigate_next_24px.svg",7) 
			CALL publish_toolbar("kandoo","A21a","inp-invoicehead-2") 
			CALL db_country_localize(glob_rec_invoicehead.country_code) --@db-patch_2020_10_04-- #Localize
 			CALL dialog.setActionHidden("ACCEPT",TRUE)
			DISPLAY db_customership_get_name_text(UI_OFF,glob_rec_invoicehead.cust_code ,l_rec_customership.ship_code) TO customership.name_text
			DISPLAY l_rec_customership.ware_code TO customership.ware_code
			DISPLAY db_warehouse_get_desc_text(UI_OFF,l_rec_customership.ware_code) TO warehouse.desc_text
			
		ON CHANGE country_code --@db-patch_2020_10_04--
			CALL db_country_localize(glob_rec_invoicehead.country_code) --@db-patch_2020_10_04-- #Localize
	
		ON CHANGE ship_code
			DISPLAY db_customership_get_name_text(UI_OFF,glob_rec_invoicehead.cust_code ,l_rec_customership.ship_code) TO customership.name_text
	
		ON ACTION "REFRESH"
			CALL windecoration_a("A138") 
	
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "NAV_BACKWARD"
			LET l_ret_nav = NAV_BACKWARD
			EXIT INPUT

		ON ACTION (ACCEPT,"NAV_FORWARD")
			LET l_ret_nav = NAV_FORWARD
			ACCEPT INPUT

		ON ACTION "actNewShippingAddress" 
			CALL clear_user_clipboard() --clear db clipboard 

			LET l_run_arg1 = "CUSTOMER_CODE=", trim(glob_rec_invoicehead.cust_code) 
			LET l_run_arg2 = "MODE=ADD"
			CALL run_prog("A17",l_run_arg1,l_run_arg2,"","") --manage shipping addresses OF CURRENT customer 

			CALL ui.ComboBox.ForName("ship_code").CLEAR() 
			CALL comboList_customership_DOUBLE("ship_code",glob_rec_customer.cust_code,COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT)

			LET glob_rec_invoicehead.ship_code = get_db_clipboard_string_val() --store new customer id in db clipboard 
			CALL clear_user_clipboard() --clear db clipboard 
			CALL windecoration_a("A138")
			 
		ON ACTION "LOOKUP" infield (ship_code) 
			LET glob_rec_invoicehead.ship_code = show_ship(glob_rec_kandoouser.cmpy_code,glob_rec_customer.cust_code) 
			NEXT FIELD ship_code 


		ON ACTION "CUSTOMER" --KEY (F8) #customer info 
			CALL cinq_clnt(glob_rec_kandoouser.cmpy_code,glob_rec_customer.cust_code) --customer details 
			NEXT FIELD ship_code 

		BEFORE FIELD ship_code 
			LET l_save_ship_code = l_rec_customership.ship_code 

		AFTER FIELD ship_code 
			IF l_save_ship_code IS NULL OR l_save_ship_code != glob_rec_invoicehead.ship_code THEN 
			 
				IF glob_rec_invoicehead.ship_code IS NULL THEN 
					IF kandooDialog("A",8018,"",TRUE,"Billing Address","QUESTION") THEN 
						## use billing address
						LET glob_rec_invoicehead.name_text = glob_rec_customer.name_text 
						LET glob_rec_invoicehead.addr1_text = glob_rec_customer.addr1_text 
						LET glob_rec_invoicehead.addr2_text = glob_rec_customer.addr2_text 
						LET glob_rec_invoicehead.city_text = glob_rec_customer.city_text 
						LET glob_rec_invoicehead.state_code = glob_rec_customer.state_code 
						LET glob_rec_invoicehead.post_code = glob_rec_customer.post_code 
						LET glob_rec_invoicehead.country_code = glob_rec_customer.country_code --@db-patch_2020_10_04--
						LET glob_rec_invoicehead.contact_text = glob_rec_customer.contact_text 
						LET glob_rec_invoicehead.tele_text = glob_rec_customer.tele_text 
						LET glob_rec_invoicehead.mobile_phone = glob_rec_customer.mobile_phone
						LET glob_rec_invoicehead.email = glob_rec_customer.email						
					END IF 

				ELSE 

					SELECT * INTO l_rec_customership.* 
					FROM customership 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cust_code = glob_rec_invoicehead.cust_code 
					AND ship_code = glob_rec_invoicehead.ship_code 

					IF status = NOTFOUND THEN 
						ERROR kandoomsg2("U",9105,"")	#9105 "Record Not Found; Try Window"
						NEXT FIELD ship_code 
					END IF 

					LET glob_rec_invoicehead.ship_code = l_rec_customership.ship_code 
					LET glob_rec_invoicehead.name_text = l_rec_customership.name_text 
					LET glob_rec_invoicehead.addr1_text = l_rec_customership.addr_text 
					LET glob_rec_invoicehead.addr2_text = l_rec_customership.addr2_text 
					LET glob_rec_invoicehead.city_text = l_rec_customership.city_text 
					LET glob_rec_invoicehead.state_code = l_rec_customership.state_code 
					LET glob_rec_invoicehead.post_code = l_rec_customership.post_code 
					LET glob_rec_invoicehead.country_code = l_rec_customership.country_code --@db-patch_2020_10_04--
					LET glob_rec_invoicehead.contact_text = l_rec_customership.contact_text 
					LET glob_rec_invoicehead.tele_text = l_rec_customership.tele_text 
					LET glob_rec_invoicehead.mobile_phone = l_rec_customership.mobile_phone 
					LET glob_rec_invoicehead.email = l_rec_customership.email					
				END IF 

				DISPLAY BY NAME 
					glob_rec_invoicehead.name_text, 
					glob_rec_invoicehead.addr1_text, 
					glob_rec_invoicehead.addr2_text, 
					glob_rec_invoicehead.city_text, 
					glob_rec_invoicehead.state_code, 
					glob_rec_invoicehead.post_code, 
					glob_rec_invoicehead.country_code, --@db-patch_2020_10_04--
					glob_rec_invoicehead.contact_text, 
					glob_rec_invoicehead.tele_text,
					glob_rec_invoicehead.mobile_phone,
					glob_rec_invoicehead.email				
				
				IF glob_rec_invoicehead.ship_code IS NULL THEN
				 SLEEP 2 #don't like sleep.. question is, do we really need to do this...
				END IF
			END IF 

			#-----------------------------------------------------------
			# Set up other invoicehead defaults that may be determined
			# FROM the customership record.
			#
			IF glob_rec_warehouse.ware_code IS NULL THEN 
				LET glob_rec_warehouse.ware_code = l_rec_customership.ware_code 
			END IF 

			IF glob_rec_invoicehead.ship1_text IS NULL THEN 
				LET glob_rec_invoicehead.ship1_text = l_rec_customership.ship1_text 
				LET glob_rec_invoicehead.ship2_text = l_rec_customership.ship2_text 
			END IF 

	END INPUT #-----------------------------------------------------------

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET l_ret_nav = NAV_CANCEL
	ELSE 
		#nothing 
	END IF 

	RETURN l_ret_nav	
END FUNCTION 
########################################################################
# END FUNCTION enter_invoice_shipping_addr(p_mode)
########################################################################
