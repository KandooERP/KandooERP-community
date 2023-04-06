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
# \brief module A18 - allows the user TO enter AND maintain Customer Promotions
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/A1_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/A18_GLOBALS.4gl"

############################################################
# FUNCTION A18_main()
#
#
############################################################
FUNCTION A18_main()
	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("A18") 

	OPEN WINDOW A690 with FORM "A690" 
	CALL windecoration_a("A690") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	CALL customer_manage()
	
	CLOSE WINDOW A690 
	
	
END FUNCTION 
############################################################
# END FUNCTION A18_main()
#
#
############################################################


############################################################
# FUNCTION db_customer_get_datasource(p_filter)
#
#
############################################################
FUNCTION db_customer_get_datasource(p_filter)
	DEFINE p_filter BOOLEAN 
	DEFINE l_where_text STRING
	DEFINE l_query_text STRING 
	DEFINE l_outer_text CHAR(5)
	DEFINE x SMALLINT 
	DEFINE l_rec_customer RECORD LIKE customer.*
	DEFINE l_arr_rec_customer DYNAMIC ARRAY OF RECORD --array[100] OF RECORD 
		scroll_flag CHAR(1), 
		cust_code LIKE customer.cust_code, 
		name_text LIKE customer.name_text, 
		type_code LIKE customer.type_code 
	END RECORD
	DEFINE l_idx SMALLINT 

	IF p_filter THEN
		CLEAR FORM 
		MESSAGE kandoomsg2("W",1001,"") 		#1001 Enter Selection Criteria
		CONSTRUCT BY NAME l_where_text ON 
			customer.cust_code, 
			customer.name_text, 
			customer.type_code 
	
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","A18","construct-customer") 
	
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null)
				 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
	
		END CONSTRUCT 
	
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_where_text = " 1=1 "
		END IF 
	ELSE
		LET l_where_text = " 1=1 "
	END IF

	MESSAGE kandoomsg2("W",1002,"") 	#1002 Searching Database
	LET l_query_text = 
		"SELECT customer.* ", 
		"FROM customer ", 
		"WHERE customer.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY customer.cust_code" 
	PREPARE s_customer FROM l_query_text 
	DECLARE c_customer CURSOR FOR s_customer 

	LET l_idx = 0 
	FOREACH c_customer INTO l_rec_customer.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_customer[l_idx].cust_code = l_rec_customer.cust_code 
		LET l_arr_rec_customer[l_idx].name_text = l_rec_customer.name_text 
		LET l_arr_rec_customer[l_idx].type_code = l_rec_customer.type_code 

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF	
	END FOREACH 
	MESSAGE kandoomsg2("U",9113,l_idx) 	#9113 l_idx records selected

 RETURN l_arr_rec_customer
END FUNCTION 
############################################################
# END FUNCTION db_customer_get_datasource(p_filter)
############################################################


############################################################
# FUNCTION scan_customer() 
#
#
############################################################
FUNCTION customer_manage() 
	DEFINE l_rec_customer RECORD LIKE customer.*
	DEFINE l_arr_rec_customer DYNAMIC ARRAY OF RECORD --array[100] OF RECORD 
		scroll_flag CHAR(1), 
		cust_code LIKE customer.cust_code, 
		name_text LIKE customer.name_text, 
		type_code LIKE customer.type_code 
	END RECORD
	DEFINE l_idx SMALLINT 

	CALL db_customer_get_datasource(FALSE) RETURNING l_arr_rec_customer

	MESSAGE kandoomsg2("W",1036,"") 	#1036 Customer Promotions; ENTER on line TO Edit
	--INPUT ARRAY l_arr_rec_customer WITHOUT DEFAULTS FROM sr_customer.* ATTRIBUTE(UNBUFFERED)
	#--------------------------------------------------- 
	DISPLAY ARRAY l_arr_rec_customer TO sr_customer.* ATTRIBUTE(UNBUFFERED)	
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","A18","inp-arr-customer") 
			CALL db_country_localize(NULL) #Localize				
			CALL combolist_state ("state_code", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,combo_null_space) 
			CALL dialog.setActionHidden("ACCEPT",TRUE)
			
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER"
			CALL l_arr_rec_customer.clear()
			CALL db_customer_get_datasource(TRUE) RETURNING l_arr_rec_customer

		ON ACTION "REFRESH"
			CALL windecoration_a("A690") 
			CALL l_arr_rec_customer.clear()
			CALL db_customer_get_datasource(FALSE) RETURNING l_arr_rec_customer
		
		BEFORE ROW 
			LET l_idx = arr_curr() 

		ON ACTION ("EDIT","doubleClick") 
			CALL customer_offer(l_arr_rec_customer[l_idx].cust_code)
			CALL l_arr_rec_customer.clear()
			CALL db_customer_get_datasource(FALSE) RETURNING l_arr_rec_customer
			 
			OPTIONS INSERT KEY f36, 
			DELETE KEY f36 
			NEXT FIELD scroll_flag 


		--BEFORE FIELD cust_code 
		--	CALL customer_offer(l_arr_rec_customer[l_idx].cust_code) 
		--	OPTIONS INSERT KEY f36, 
		--	DELETE KEY f36 
		--	NEXT FIELD scroll_flag 

	END DISPLAY 
	#---------------------------------------------------

	LET int_flag = false 
	LET quit_flag = false 
END FUNCTION 
############################################################
# END FUNCTION scan_customer() 
############################################################


############################################################
# FUNCTION customer_offer(p_cust_code)
#
#
############################################################
FUNCTION customer_offer(p_cust_code) 
	DEFINE p_cust_code LIKE customer.cust_code
	DEFINE l_rec_customer RECORD LIKE customer.*
	DEFINE l_rec_custoffer RECORD LIKE custoffer.*
	DEFINE l_rec_customertype RECORD LIKE customertype.* 
	DEFINE l_rec_pricing RECORD LIKE pricing.*
	DEFINE l_rec_s_pricing RECORD LIKE pricing.* 
	DEFINE l_arr_rec_custoffer DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		offer_code LIKE custoffer.offer_code, 
		desc_text LIKE pricing.desc_text, 
		start_date LIKE custoffer.offer_start_date, 
		effective_date LIKE custoffer.effective_date 
	END RECORD
	DEFINE l_offer_code LIKE custoffer.offer_code
	DEFINE l_scroll_flag CHAR(1)
	DEFINE l_filter_text CHAR(100)
	DEFINE l_mode CHAR(4) 
	DEFINE l_cnt SMALLINT --,scrn
	DEFINE i SMALLINT --,scrn
	DEFINE l_idx SMALLINT --,scrn
	DEFINE l_s2 SMALLINT --,scrn
	DEFINE l_del_cnt SMALLINT --,scrn
	DEFINE l_country_text LIKE country.country_text

	IF p_cust_code IS NULL THEN 
		RETURN 
	END IF 

	OPEN WINDOW A691 with FORM "A691" 
	CALL windecoration_a("A691") 

	CALL db_customer_get_rec(UI_OFF,p_cust_code) RETURNING l_rec_customer.* 
--	SELECT * INTO l_rec_customer.* FROM customer 
--	WHERE cust_code = p_cust_code 
--	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	--SELECT * INTO glob_rec_country.* FROM country 
	--WHERE country_code = l_rec_customer.country_code 
	SELECT * INTO l_rec_customertype.* FROM customertype 
	WHERE type_code = l_rec_customer.type_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 

	SELECT country.country_text INTO l_country_text
	FROM country
	WHERE country.country_code = l_rec_customer.country_code

	DISPLAY BY NAME 
		l_rec_customer.cust_code, 
		l_rec_customer.name_text, 
		l_rec_customer.addr1_text, 
		l_rec_customer.addr2_text, 
		l_rec_customer.city_text, 
		l_rec_customer.state_code, 
		l_rec_customer.post_code, 
		l_rec_customer.country_code, 
		l_rec_customer.type_code, 
		l_rec_customertype.type_text 

	DISPLAY l_country_text TO country_text

	CALL db_country_localize(l_rec_customer.country_code) #Localize

	DECLARE custcur CURSOR FOR 
	SELECT * FROM custoffer,pricing 
	WHERE custoffer.cust_code = l_rec_customer.cust_code 
	AND custoffer.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND pricing.offer_code = custoffer.offer_code 
	AND pricing.start_date = custoffer.offer_start_date 
	AND pricing.cmpy_code = custoffer.cmpy_code 
	ORDER BY custoffer.offer_code,custoffer.offer_start_date 
	MESSAGE kandoomsg2("W",1002,"") 	#1002 " Searching database - please wait"

	DECLARE pricecur SCROLL CURSOR FOR 
	SELECT * INTO l_rec_pricing.* FROM pricing 
	WHERE offer_code = l_offer_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND type_ind = 1 
	ORDER BY start_date 
	LET l_idx = 0 

	FOREACH custcur INTO l_rec_custoffer.*,l_rec_pricing.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_custoffer[l_idx].offer_code = l_rec_custoffer.offer_code 
		LET l_arr_rec_custoffer[l_idx].desc_text = l_rec_pricing.desc_text 
		LET l_arr_rec_custoffer[l_idx].start_date = l_rec_custoffer.offer_start_date 
		LET l_arr_rec_custoffer[l_idx].effective_date = l_rec_custoffer.effective_date 

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF	
	END FOREACH 

	MESSAGE kandoomsg2("U",9113,l_idx) #U9113 l_idx records selected
	IF l_idx = 0 THEN 
		LET l_idx = 1 
		INITIALIZE l_arr_rec_custoffer[l_idx].* TO NULL 
	END IF 

	OPTIONS INSERT KEY f1, 
	DELETE KEY f36 

	MESSAGE kandoomsg2("W",1003,"") #" F1 TO Add - F2 TO Delete - RETURN on line TO Edit "
	INPUT ARRAY l_arr_rec_custoffer WITHOUT DEFAULTS FROM sr_custoffer.* ATTRIBUTE(UNBUFFERED, delete row = false) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A18","inp-arr-custoffer") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null)
			 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			INITIALIZE l_rec_pricing.* TO NULL 
			LET l_idx = arr_curr() 
			LET l_mode = MODE_CLASSIC_EDIT 
			NEXT FIELD scroll_flag 

		BEFORE INSERT 
			INITIALIZE l_rec_custoffer.* TO NULL 
			LET l_mode = MODE_CLASSIC_ADD 
			NEXT FIELD offer_code 

		BEFORE FIELD scroll_flag 
			LET l_scroll_flag = l_arr_rec_custoffer[l_idx].scroll_flag 
			#DISPLAY l_arr_rec_custoffer[l_idx].* TO sr_custoffer[scrn].*

		AFTER FIELD scroll_flag 
			LET l_arr_rec_custoffer[l_idx].scroll_flag = l_scroll_flag 
			LET l_rec_custoffer.offer_code = l_arr_rec_custoffer[l_idx].offer_code 
			LET l_rec_custoffer.offer_start_date = l_arr_rec_custoffer[l_idx].start_date 
			LET l_rec_custoffer.effective_date = l_arr_rec_custoffer[l_idx].effective_date 

		BEFORE FIELD offer_code 
			IF l_mode != MODE_CLASSIC_ADD THEN 
				NEXT FIELD effective_date 
			END IF 

		AFTER FIELD offer_code 
			CASE 
				WHEN fgl_lastkey() = fgl_keyval("accept") 
					OR fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("down") 
					IF l_arr_rec_custoffer[l_idx].offer_code IS NULL THEN 
						ERROR kandoomsg2("W",9124,"") 					#9124 Offer Code Must Be Entered - Use Window TO SELECT
						NEXT FIELD offer_code 
					ELSE 
						LET l_offer_code = l_arr_rec_custoffer[l_idx].offer_code 
						SELECT count(*) INTO l_cnt FROM pricing 
						WHERE offer_code = l_offer_code 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND ((end_date IS null) OR (end_date >= today)) 

						IF l_cnt = 0 THEN 
							ERROR kandoomsg2("W",9125,"") 						#9125 Offer Code Does Not Exist - Try Window
							NEXT FIELD offer_code 
						ELSE 
							IF l_cnt > 1 THEN 
								LET l_filter_text = "pricing.offer_code = '",	l_arr_rec_custoffer[l_idx].offer_code,"' " 

								CALL show_pricing(glob_rec_kandoouser.cmpy_code,l_filter_text) 
								RETURNING l_rec_pricing.offer_code, 
								l_rec_pricing.start_date 

								SELECT * INTO l_rec_pricing.* FROM pricing 
								WHERE offer_code = l_rec_pricing.offer_code 
								AND cmpy_code = glob_rec_kandoouser.cmpy_code 
								LET l_arr_rec_custoffer[l_idx].offer_code = l_rec_pricing.offer_code 
								LET l_arr_rec_custoffer[l_idx].desc_text = l_rec_pricing.desc_text 
								LET l_arr_rec_custoffer[l_idx].start_date = l_rec_pricing.start_date 
								LET l_arr_rec_custoffer[l_idx].effective_date =	l_rec_pricing.start_date 
								#DISPLAY l_arr_rec_custoffer[l_idx].* TO sr_custoffer[scrn].*

								OPTIONS INSERT KEY f1, 
								DELETE KEY f36 
								
								IF l_rec_pricing.offer_code IS NOT NULL THEN 
									NEXT FIELD effective_date 
								END IF 

							ELSE 

								SELECT * INTO l_rec_pricing.* FROM pricing 
								WHERE offer_code = l_arr_rec_custoffer[l_idx].offer_code 
								AND cmpy_code = glob_rec_kandoouser.cmpy_code 
								LET l_arr_rec_custoffer[l_idx].offer_code = l_rec_pricing.offer_code 
								LET l_arr_rec_custoffer[l_idx].desc_text = l_rec_pricing.desc_text 
								LET l_arr_rec_custoffer[l_idx].start_date = l_rec_pricing.start_date 
								LET l_arr_rec_custoffer[l_idx].effective_date = 
								l_rec_pricing.start_date 
								#DISPLAY l_arr_rec_custoffer[l_idx].* TO sr_custoffer[scrn].*

							END IF 

						END IF 

						IF l_rec_pricing.end_date IS NULL THEN 
							LET l_rec_pricing.end_date = "01/12/1999" 
						END IF 

						FOR i = 1 TO arr_count() 
							IF i <> l_idx THEN 
								IF l_arr_rec_custoffer[i].offer_code = l_rec_pricing.offer_code 
								THEN 
									ERROR kandoomsg2("W",9184,"") 	#9184 Offer Code already applied TO this customer
									NEXT FIELD offer_code 
								END IF 

								SELECT * INTO l_rec_s_pricing.* FROM pricing 
								WHERE offer_code = l_arr_rec_custoffer[i].offer_code 
								AND cmpy_code = glob_rec_kandoouser.cmpy_code 

								IF l_rec_s_pricing.end_date IS NULL THEN 
									LET l_rec_s_pricing.end_date = "01/12/1999" 
								END IF 

								IF l_rec_pricing.part_code IS NOT NULL 
								AND l_rec_pricing.part_code = l_rec_s_pricing.part_code 
								AND l_rec_pricing.class_code = l_rec_s_pricing.class_code 
								AND ( l_rec_pricing.ware_code = l_rec_s_pricing.ware_code 
								OR ( l_rec_pricing.ware_code IS NULL 
								AND l_rec_s_pricing.ware_code IS NULL )) THEN 
									IF (l_rec_pricing.start_date >= l_rec_s_pricing.start_date 
									AND l_rec_pricing.start_date <= l_rec_s_pricing.end_date) 
									OR (l_rec_s_pricing.start_date >= l_rec_pricing.start_date 
									AND l_rec_s_pricing.start_date <= l_rec_pricing.end_date) 
									THEN 

										ERROR kandoomsg2("W",9246,"") #9246 This offer overlaps an existing offer FOR the same product
										NEXT FIELD offer_code 
									END IF 

								END IF 

								IF l_rec_pricing.prodgrp_code IS NOT NULL 
								AND l_rec_pricing.prodgrp_code = l_rec_s_pricing.prodgrp_code 
								AND ( l_rec_pricing.ware_code = l_rec_s_pricing.ware_code 
								OR ( l_rec_pricing.ware_code IS NULL 
								AND l_rec_s_pricing.ware_code IS NULL )) THEN 
									IF (l_rec_pricing.start_date >= l_rec_s_pricing.start_date 
									AND l_rec_pricing.start_date <= l_rec_s_pricing.end_date) 
									OR (l_rec_s_pricing.start_date >= l_rec_pricing.start_date 
									AND l_rec_s_pricing.start_date <= l_rec_pricing.end_date) THEN 
										ERROR kandoomsg2("W",9247,"") 	#9247 This offer overlaps an existing offer FOR the same product
										NEXT FIELD offer_code 
									END IF 

								END IF 

								IF l_rec_pricing.maingrp_code IS NOT NULL 
								AND l_rec_pricing.maingrp_code = l_rec_s_pricing.maingrp_code 
								AND ( l_rec_pricing.ware_code = l_rec_s_pricing.ware_code 
								OR ( l_rec_pricing.ware_code IS NULL 
								AND l_rec_s_pricing.ware_code IS NULL )) THEN 
									IF (l_rec_pricing.start_date >= l_rec_s_pricing.start_date 
									AND l_rec_pricing.start_date <= l_rec_s_pricing.end_date) 
									OR (l_rec_s_pricing.start_date >= l_rec_pricing.start_date 
									AND l_rec_s_pricing.start_date <= l_rec_pricing.end_date) THEN 
										ERROR kandoomsg2("W",9248,"") #9248 This offer overlaps an existing offer FOR the ,same product
										NEXT FIELD offer_code 
									END IF 

								END IF 

								IF l_rec_pricing.part_code IS NULL 
								AND l_rec_s_pricing.part_code IS NULL 
								AND l_rec_pricing.prodgrp_code IS NULL 
								AND l_rec_s_pricing.prodgrp_code IS NULL 
								AND l_rec_pricing.maingrp_code IS NULL 
								AND l_rec_s_pricing.maingrp_code IS NULL 
								AND l_rec_pricing.class_code IS NULL 
								AND l_rec_s_pricing.class_code IS NULL 
								AND l_rec_pricing.ware_code IS NOT NULL 
								AND l_rec_pricing.ware_code = l_rec_s_pricing.ware_code THEN 
									IF (l_rec_pricing.start_date >= l_rec_s_pricing.start_date 
									AND l_rec_pricing.start_date <= l_rec_s_pricing.end_date) 
									OR (l_rec_s_pricing.start_date >= l_rec_pricing.start_date 
									AND l_rec_s_pricing.start_date <= l_rec_pricing.end_date) THEN 
										ERROR kandoomsg2("A",9234,"") #9248 This offer overlaps an existing offer	#FOR the same location
										NEXT FIELD offer_code 
									END IF 
								END IF 
							END IF 
						END FOR 

						IF fgl_lastkey() = fgl_keyval("accept") THEN 
							IF l_arr_rec_custoffer[l_idx].effective_date IS NULL THEN 
								ERROR kandoomsg2("W",9126,"") 		#9126 An Effective Date Must Be Entered
								NEXT FIELD effective_date 
							ELSE 
								SELECT * INTO l_rec_pricing.* FROM pricing 
								WHERE offer_code = l_arr_rec_custoffer[l_idx].offer_code 
								AND cmpy_code = glob_rec_kandoouser.cmpy_code 
								IF (l_arr_rec_custoffer[l_idx].effective_date < 
								l_arr_rec_custoffer[l_idx].start_date) 
								OR (l_arr_rec_custoffer[l_idx].effective_date > 
								l_rec_pricing.end_date) THEN 
									ERROR kandoomsg2("W",9127,"") 		#9127 The Effective Date IS outside Start & END Date Range
									NEXT FIELD effective_date 
								END IF 
							END IF 
							NEXT FIELD scroll_flag 

						END IF 
						NEXT FIELD NEXT 

					END IF 

				OTHERWISE 
					NEXT FIELD offer_code 

			END CASE 

		AFTER FIELD effective_date 

			CASE 
				WHEN fgl_lastkey() = fgl_keyval("accept") 
					OR fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("down") 
					IF l_arr_rec_custoffer[l_idx].effective_date IS NULL THEN 
						ERROR kandoomsg2("W",9126,"") 		#9126 Effective Date Must Be Entered
						NEXT FIELD effective_date 
					ELSE 
						IF l_mode = MODE_CLASSIC_ADD THEN 
							FOR i = 1 TO arr_count() 
								IF i <> l_idx THEN 
									IF l_arr_rec_custoffer[i].offer_code = 
									l_arr_rec_custoffer[l_idx].offer_code THEN 
										ERROR kandoomsg2("W",9184,"") 					#9184 Offer Code already applied TO this customer
										NEXT FIELD offer_code 
									END IF 
								END IF 
							END FOR 
						END IF 

						SELECT * INTO l_rec_pricing.* FROM pricing 
						WHERE offer_code = l_arr_rec_custoffer[l_idx].offer_code 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code 
						IF (l_arr_rec_custoffer[l_idx].effective_date < 
						l_arr_rec_custoffer[l_idx].start_date) 
						OR (l_arr_rec_custoffer[l_idx].effective_date > 
						l_rec_pricing.end_date) THEN 
							ERROR kandoomsg2("W",9127,"") 				#9127 The Effective Date IS outside Start & END Date Range
							NEXT FIELD effective_date 
						END IF 
						NEXT FIELD scroll_flag 
					END IF 

				WHEN fgl_lastkey() = fgl_keyval("left") 
					OR fgl_lastkey() = fgl_keyval("up") 
					IF l_mode = MODE_CLASSIC_ADD THEN 
						NEXT FIELD previous 
					ELSE 
						NEXT FIELD effective_date 
					END IF 
				OTHERWISE 
					NEXT FIELD effective_date 

			END CASE 

		ON ACTION "DELETE_MARKER" --ON KEY (F2)  infield(scroll_flag) --delete
					IF l_arr_rec_custoffer[l_idx].scroll_flag IS NULL THEN 
						LET l_arr_rec_custoffer[l_idx].scroll_flag = "*" 
						LET l_del_cnt = l_del_cnt + 1 
					ELSE 
						LET l_arr_rec_custoffer[l_idx].scroll_flag = NULL 
						LET l_del_cnt = l_del_cnt - 1 
					END IF 
					NEXT FIELD scroll_flag 


			#AFTER ROW
			#DISPLAY l_arr_rec_custoffer[l_idx].* TO sr_custoffer[scrn].*

		ON ACTION "LOOKUP" infield (offer_code) 
			LET l_filter_text = " ((end_date IS NULL) OR (end_date >= today))" 

			CALL show_pricing(glob_rec_kandoouser.cmpy_code,l_filter_text) 
			RETURNING l_rec_pricing.offer_code, l_rec_pricing.start_date 

			SELECT * INTO l_rec_pricing.* FROM pricing 
			WHERE offer_code = l_rec_pricing.offer_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 

			LET l_arr_rec_custoffer[l_idx].offer_code = l_rec_pricing.offer_code 
			LET l_arr_rec_custoffer[l_idx].desc_text = l_rec_pricing.desc_text 
			LET l_arr_rec_custoffer[l_idx].start_date = l_rec_pricing.start_date 
			LET l_arr_rec_custoffer[l_idx].effective_date = l_rec_pricing.start_date 

			#DISPLAY l_arr_rec_custoffer[l_idx].* TO sr_custoffer[scrn].*

			OPTIONS INSERT KEY f1, 
			DELETE KEY f36 
			NEXT FIELD offer_code 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				IF NOT (infield(scroll_flag)) THEN 
					IF l_rec_custoffer.offer_code IS NULL THEN 

						FOR l_idx = arr_curr() TO arr_count() 
							LET l_arr_rec_custoffer[l_idx].* = l_arr_rec_custoffer[l_idx+1].* 

							#IF scrn <= 5 THEN
							#   IF l_arr_rec_custoffer[l_idx].offer_code IS NULL THEN
							#      INITIALIZE l_arr_rec_custoffer[l_idx].* TO NULL
							#   END IF
							#   DISPLAY l_arr_rec_custoffer[l_idx].* TO sr_custoffer[scrn].*
							#
							#   LET scrn = scrn + 1
							#END IF

						END FOR 
						#LET scrn = scr_line()
						INITIALIZE l_arr_rec_custoffer[l_idx].* TO NULL 
						LET int_flag = false 
						LET quit_flag = false 
						NEXT FIELD scroll_flag 

					ELSE 

						LET l_arr_rec_custoffer[l_idx].offer_code = l_rec_custoffer.offer_code 
						LET l_arr_rec_custoffer[l_idx].start_date = 
						l_rec_custoffer.offer_start_date 
						LET l_arr_rec_custoffer[l_idx].effective_date = 
						l_rec_custoffer.effective_date 
						LET int_flag = false 
						LET quit_flag = false 
						NEXT FIELD scroll_flag 
					END IF 

				END IF 
			END IF 

	END INPUT 
	#-------------------------------------------------

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 

		FOR l_idx = 1 TO arr_count() 
			IF l_arr_rec_custoffer[l_idx].offer_code IS NOT NULL THEN 
				LET l_rec_custoffer.cmpy_code = glob_rec_kandoouser.cmpy_code 

				LET l_rec_custoffer.cust_code = l_rec_customer.cust_code 
				LET l_rec_custoffer.offer_code = l_arr_rec_custoffer[l_idx].offer_code 
				LET l_rec_custoffer.offer_start_date = l_arr_rec_custoffer[l_idx].start_date 
				LET l_rec_custoffer.effective_date = l_arr_rec_custoffer[l_idx].effective_date 

				UPDATE custoffer 
				SET * = l_rec_custoffer.* 
				WHERE cust_code = l_rec_customer.cust_code 
				AND offer_code = l_arr_rec_custoffer[l_idx].offer_code 
				AND offer_start_date = l_arr_rec_custoffer[l_idx].start_date 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 

				IF sqlca.sqlerrd[3] = 0 THEN 
					INSERT INTO custoffer VALUES (l_rec_custoffer.*) 
				END IF 

			END IF 

		END FOR 

		IF l_del_cnt > 0 THEN 

			IF kandoomsg("W",8022,l_del_cnt) = "Y" THEN #8023 Confirm TO Delete ",l_del_cnt," Customer Pricing Offer(s)? (Y/N)"
				FOR l_idx = 1 TO arr_count() 
					IF l_arr_rec_custoffer[l_idx].scroll_flag = "*" THEN 
						DELETE FROM custoffer 
						WHERE cust_code = l_rec_customer.cust_code 
						AND offer_code = l_arr_rec_custoffer[l_idx].offer_code 
						AND offer_start_date = l_arr_rec_custoffer[l_idx].start_date 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					END IF 
				END FOR 
			END IF 
		END IF 
	END IF 

	CLOSE WINDOW A691 
END FUNCTION 
############################################################
# END FUNCTION customer_offer(p_cust_code)
############################################################