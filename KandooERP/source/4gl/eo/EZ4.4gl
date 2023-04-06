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
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"
GLOBALS "../eo/E_EO_GLOBALS.4gl"
GLOBALS "../eo/EZ_GROUP_GLOBALS.4gl"  
GLOBALS "../eo/EZ4_GLOBALS.4gl"
#######################################################################
# FUNCTION EZ4_main()
#
#
#######################################################################
FUNCTION EZ4_main() 
	DEFINE i SMALLINT 

	#Initial UI Init
	CALL setModuleId("EZ4") -- albo 
	CALL ui_init(0) 

	DEFER QUIT 
	DEFER INTERRUPT 

	CALL authenticate(getmoduleid()) 
	#glob_rec_kandoouser.cmpy_code
	#db_company_get_country_code(p_cmpy_code)

	CALL db_country_get_rec(glob_rec_company.country_code) RETURNING glob_rec_country.* 
	#   SELECT country.*
	#      INTO glob_rec_country.*
	#      FROM company,
	#           country
	#     WHERE company.cmpy_code = glob_rec_kandoouser.cmpy_code
	#       AND country.country_code = company.country_code

	IF glob_rec_country.country_code IS NULL THEN 
		#IF STATUS = NOTFOUND THEN
		LET glob_rec_country.state_code_text ="State........" 
		LET glob_rec_country.post_code_text = "Post code.........." 
	ELSE 
		LET i = length(glob_rec_country.state_code_text) 
		LET glob_rec_country.state_code_text[i+1,20] = "................." 
		LET i = length(glob_rec_country.post_code_text) 
		LET glob_rec_country.post_code_text[i+1,20] = "................." 
	END IF 

	CREATE temp TABLE temp_carriercost(
		cmpy_code char(2), 
		carrier_code char(3), 
		state_code char(6), 
		country_code char(3), 
		freight_ind char(1), 
		freight_amt decimal(16,2)) with no LOG 

	OPEN WINDOW E142 with FORM "E142" 
	 CALL windecoration_e("E142") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	CALL scan_carrier() 

	CLOSE WINDOW E142 
END FUNCTION 
#######################################################################
# END MAIN
#######################################################################


#######################################################################
# FUNCTION db_carrier_get_query_where_part()
#
#
#######################################################################
FUNCTION db_carrier_get_query_where_part(p_filter)
	DEFINE p_filter BOOLEAN 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE l_arr_rec_carrier DYNAMIC ARRAY OF t_rec_carrier_cd_na_cy 
	DEFINE l_carrier_code LIKE carrier.carrier_code 
	
	IF p_filter THEN
		CLEAR FORM 
		MESSAGE kandoomsg2("E",1001,"")	#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON 
			carrier_code, 
			name_text, 
			city_text 
	
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","EZ4","construct-carrier") 
	
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
	
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
	
		END CONSTRUCT 
	
		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			LET l_where_text =  "1=1"
		END IF 
	ELSE 
		LET l_where_text =  "1=1"
	END IF
	
	MESSAGE kandoomsg2("E",1002,"") 	#1002 " Searching database - please wait"
	RETURN l_where_text 
	#      LET l_query_text = "SELECT * ",
	#                         "FROM carrier ",
	#                        "WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ",
	#                          "AND ",l_where_text clipped," ",
	#                        "ORDER BY cmpy_code,",
	#                                 "carrier_code"
	#      PREPARE s_carrier FROM l_query_text
	#      DECLARE c_carrier CURSOR FOR s_carrier
	#      RETURN TRUE
 
END FUNCTION 
#######################################################################
# END FUNCTION db_carrier_get_query_where_part()
#
#
#######################################################################


#######################################################################
# FUNCTION scan_carrier()
#
#
#######################################################################
FUNCTION scan_carrier() 
	DEFINE l_arr_rec_carrier DYNAMIC ARRAY OF t_rec_carrier_cd_na_cy 
	DEFINE l_carrier_code LIKE carrier.carrier_code 
	#		RECORD
	#			carrier_code LIKE carrier.carrier_code,
	#			name_text LIKE carrier.name_text,
	#			city_text LIKE carrier.city_text
	#		END RECORD
	DEFINE l_idx SMALLINT 
	DEFINE l_del_cnt SMALLINT 
	DEFINE l_where_text STRING 


	CALL db_carrier_get_arr_rec_vc_nt_ct(l_where_text) RETURNING l_arr_rec_carrier 
	#
	#   LET l_idx = 0
	#   FOREACH c_carrier INTO glob_rec_carrier.*
	#      LET l_idx = l_idx + 1
	#      LET l_arr_rec_carrier[l_idx].carrier_code = glob_rec_carrier.carrier_code
	#      LET l_arr_rec_carrier[l_idx].name_text = glob_rec_carrier.name_text
	#
	#      IF glob_rec_carrier.city_text IS NULL THEN
	#         LET l_arr_rec_carrier[l_idx].city_text = glob_rec_carrier.addr2_text
	#      ELSE
	#         LET l_arr_rec_carrier[l_idx].city_text = glob_rec_carrier.city_text
	#      END IF
	#
	#      IF l_idx = 100 THEN
	#         ERROR kandoomsg2("E",9094,"100")
	#         #9094 " First ??? Carriers Selected Only"
	#         EXIT FOREACH
	#      END IF
	#   END FOREACH
	IF NOT l_arr_rec_carrier.getsize() THEN #not found 
		#   #IF l_idx = 0 THEN
		ERROR kandoomsg2("E",9097,"") 	#9097" No Carriers Satisfied Selection Criteria "
		#      #LET l_idx = 1
	END IF 

	#   OPTIONS INSERT KEY F1,
	#           DELETE KEY F36

	#   CALL set_count(l_idx)
	MESSAGE kandoomsg2("E",1003,"") #" F1 TO Add - F2 TO Delete - RETURN TO Edit "

	DISPLAY ARRAY l_arr_rec_carrier TO sr_carrier.* ATTRIBUTE(UNBUFFERED)
	#INPUT ARRAY l_arr_rec_carrier WITHOUT DEFAULTS FROM sr_carrier.*
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","IZ4","inp-arr-carrier")
			CALL dialog.setActionHidden("ACCEPT",TRUE) 
			CALL dialog.setActionHidden("EDIT",NOT l_arr_rec_carrier.getSize())
			 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER" 
			CALL db_carrier_get_arr_rec_vc_nt_ct(db_carrier_get_query_where_part(TRUE)) RETURNING l_arr_rec_carrier 

		ON ACTION "REFRESH"
			 CALL windecoration_e("E142") 
			CALL db_carrier_get_arr_rec_vc_nt_ct(db_carrier_get_query_where_part(TRUE)) RETURNING l_arr_rec_carrier 


		BEFORE ROW 
			LET l_idx = arr_curr() 

			#      BEFORE FIELD scroll_flag
			#         LET l_idx = arr_curr()
			#         LET scrn = scr_line()
			#         LET l_scroll_flag = l_arr_rec_carrier[l_idx].scroll_flag
			#         DISPLAY l_arr_rec_carrier[l_idx].*
			#              TO sr_carrier[scrn].*

		ON ACTION ("ACCEPT","EDIT","DOUBLECLICK") 
			
			IF (l_arr_rec_carrier[l_idx].carrier_code IS NOT NULL) AND (l_idx > 0) THEN 
				CALL edit_carrier_carriercost(l_arr_rec_carrier[l_idx].carrier_code) 
				CALL db_carrier_get_arr_rec_vc_nt_ct(l_where_text) RETURNING l_arr_rec_carrier 
			END IF 
			##      IF edit_carrier(l_arr_rec_carrier[l_idx].carrier_code) THEN


			##				CALL db_carrier_get_arr_rec_vc_nt_ct(l_where_text) RETURNING l_arr_rec_carrier

			#               SELECT name_text,
			#                      city_text
			#                 INTO l_arr_rec_carrier[l_idx].name_text,
			#                      l_arr_rec_carrier[l_idx].city_text
			#                 FROM carrier
			#                WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
			#                  AND carrier_code = l_arr_rec_carrier[l_idx].carrier_code
			#               IF l_arr_rec_carrier[l_idx].city_text IS NULL THEN
			#                  SELECT addr2_text
			#                    INTO l_arr_rec_carrier[l_idx].city_text
			#                    FROM carrier
			#                   WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
			#                     AND carrier_code = l_arr_rec_carrier[l_idx].carrier_code
			#               END IF
			##       END IF
			##    END IF


			#      BEFORE FIELD carrier_code
			#         IF l_arr_rec_carrier[l_idx].carrier_code IS NOT NULL THEN
			#            IF edit_carrier(l_arr_rec_carrier[l_idx].carrier_code) THEN
			#               SELECT name_text,
			#                      city_text
			#                 INTO l_arr_rec_carrier[l_idx].name_text,
			#                      l_arr_rec_carrier[l_idx].city_text
			#                 FROM carrier
			#                WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
			#                  AND carrier_code = l_arr_rec_carrier[l_idx].carrier_code
			#               IF l_arr_rec_carrier[l_idx].city_text IS NULL THEN
			#                  SELECT addr2_text
			#                    INTO l_arr_rec_carrier[l_idx].city_text
			#                    FROM carrier
			#                   WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
			#                     AND carrier_code = l_arr_rec_carrier[l_idx].carrier_code
			#               END IF
			#            END IF
			#         END IF
			#         NEXT FIELD scroll_flag

		ON ACTION "Add" 
			LET l_carrier_code = add_carrier() #add new carrier 
			IF l_carrier_code IS NOT NULL THEN #returns new carrier code id ON success 
				CALL db_carrier_get_arr_rec_vc_nt_ct(l_where_text) RETURNING l_arr_rec_carrier 
				CALL edit_carrier_carriercost(l_carrier_code) 
				CALL db_carrier_get_arr_rec_vc_nt_ct(l_where_text) RETURNING l_arr_rec_carrier 
			END IF 
			CALL dialog.setActionHidden("EDIT",NOT l_arr_rec_carrier.getSize())
			#					IF add_carrier() THEN
			#            LET l_arr_rec_carrier[l_idx].carrier_code = add_carrier()
			#            SELECT name_text,
			#                   city_text
			#              INTO l_arr_rec_carrier[l_idx].name_text,
			#                   l_arr_rec_carrier[l_idx].city_text
			#              FROM carrier
			#             WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
			#               AND carrier_code = l_arr_rec_carrier[l_idx].carrier_code
			#
			#            IF STATUS = NOTFOUND THEN





			#            ELSE
			#               IF l_arr_rec_carrier[l_idx].city_text IS NULL THEN
			#                  SELECT addr2_text
			#                    INTO l_arr_rec_carrier[l_idx].city_text
			#                    FROM carrier
			#                   WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
			#                     AND carrier_code = l_arr_rec_carrier[l_idx].carrier_code
			#               END IF
			#            END IF



			#      BEFORE INSERT
			#         IF arr_curr() < arr_count() THEN
			#            LET l_arr_rec_carrier[l_idx].carrier_code = add_carrier()
			#            SELECT name_text,
			#                   city_text
			#              INTO l_arr_rec_carrier[l_idx].name_text,
			#                   l_arr_rec_carrier[l_idx].city_text
			#              FROM carrier
			#             WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
			#               AND carrier_code = l_arr_rec_carrier[l_idx].carrier_code
			#            IF STATUS = NOTFOUND THEN
			#               FOR l_idx = arr_curr() TO arr_count()
			#                  LET l_arr_rec_carrier[l_idx].* = l_arr_rec_carrier[l_idx+1].*
			#                  IF scrn <= 14 THEN
			#                     DISPLAY l_arr_rec_carrier[l_idx].*
			#                          TO sr_carrier[scrn].*
			#
			#                     LET scrn = scrn + 1
			#                  END IF
			#               END FOR
			#               INITIALIZE l_arr_rec_carrier[l_idx].* TO NULL
			#            ELSE
			#               IF l_arr_rec_carrier[l_idx].city_text IS NULL THEN
			#                  SELECT addr2_text
			#                    INTO l_arr_rec_carrier[l_idx].city_text
			#                    FROM carrier
			#                   WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
			#                     AND carrier_code = l_arr_rec_carrier[l_idx].carrier_code
			#               END IF
			#            END IF
			#         ELSE
			#            IF l_idx > 1 THEN
			#               ERROR kandoomsg2("E",9001,"")
			#               #9001There are no more rows in the direction you are going
			#            END IF
			#         END IF


		ON ACTION DELETE 
			IF l_arr_rec_carrier[l_idx].carrier_code IS NOT NULL THEN 

				SELECT unique 1 FROM orderhead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND carrier_code = l_arr_rec_carrier[l_idx].carrier_code 
				AND status_ind != "C" 

				IF status = 0 THEN 
					ERROR kandoomsg2("E",7045,l_arr_rec_carrier[l_idx].carrier_code) 
					#7045 sales orders exits FOR this ORDER - deletion no
				ELSE 
					LET l_del_cnt = 1 
					
					
					IF kandoomsg("E",8016,l_del_cnt) = "Y" THEN  #8016 Confirm TO Delete ",l_del_cnt," Carrier(s)? (Y/N)"

						SELECT unique 1 FROM orderhead 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND carrier_code = l_arr_rec_carrier[l_idx].carrier_code 
						AND status_ind != "C" 
						IF status = 0 THEN 
							ERROR kandoomsg2("E",7045,"") #7045 A sales ORDER exists FOR this carrier No Deletion
						ELSE 

							DELETE FROM carrier 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND carrier_code = l_arr_rec_carrier[l_idx].carrier_code 
							DELETE FROM carriercost 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND carrier_code = l_arr_rec_carrier[l_idx].carrier_code 

							CALL db_carrier_get_arr_rec_vc_nt_ct(l_where_text) RETURNING l_arr_rec_carrier 

						END IF 


					END IF 
				END IF 
			END IF 
			CALL dialog.setActionHidden("EDIT",NOT l_arr_rec_carrier.getSize())
			
			#      ON KEY(F2)  --delete marker
			#         IF l_arr_rec_carrier[l_idx].carrier_code IS NOT NULL THEN
			#            IF l_arr_rec_carrier[l_idx].scroll_flag IS NULL THEN
			#               SELECT unique 1 FROM orderhead
			#                  WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
			#                    AND carrier_code = l_arr_rec_carrier[l_idx].carrier_code
			#                    AND status_ind != "C"
			#               IF STATUS = 0 THEN
			#                  ERROR kandoomsg2("E",7045,l_arr_rec_carrier[l_idx].carrier_code)
			#                  #7045 sales orders exits FOR this ORDER - deletion no
			#               ELSE
			#                  LET l_arr_rec_carrier[l_idx].scroll_flag = "*"
			#                  LET l_del_cnt = l_del_cnt + 1
			#               END IF
			#            ELSE
			#               LET l_arr_rec_carrier[l_idx].scroll_flag = NULL
			#               LET l_del_cnt = l_del_cnt - 1
			#            END IF
			#         END IF
			#         NEXT FIELD scroll_flag

			# AFTER ROW
			#    DISPLAY l_arr_rec_carrier[l_idx].*
			#         TO sr_carrier[scrn].*

			#      ON KEY (control-w)
			#         CALL kandoohelp("")

	END DISPLAY 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		#   ELSE
		#      IF l_del_cnt > 0 THEN
		#         #8016 Confirm TO Delete ",l_del_cnt," Carrier(s)? (Y/N)"
		#         IF kandoomsg2("E",8016,l_del_cnt) = "Y" THEN
		#            FOR l_idx = 1 TO arr_count()
		#               IF l_arr_rec_carrier[l_idx].scroll_flag = "*" THEN
		#                  SELECT unique 1 FROM orderhead
		#                     WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
		#                       AND carrier_code = l_arr_rec_carrier[l_idx].carrier_code
		#                       AND status_ind != "C"
		#                  IF STATUS = 0 THEN
		#                     ERROR kandoomsg2("E",7045,"")
		#                     #7045 A sales ORDER exists FOR this carrier No Deletion
		#                  ELSE
		#                     DELETE FROM carrier
		#                        WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
		#                          AND carrier_code = l_arr_rec_carrier[l_idx].carrier_code
		#                     DELETE FROM carriercost
		#                        WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
		#                          AND carrier_code = l_arr_rec_carrier[l_idx].carrier_code
		#                  END IF
		#               END IF
		#            END FOR
		#         END IF
		#      END IF
	END IF 
END FUNCTION 
#######################################################################
# END FUNCTION scan_carrier()
#######################################################################


#######################################################################
# FUNCTION edit_carrier(p_carrier_code)
#
#
#######################################################################
FUNCTION edit_carrier(p_carrier_code) 
	DEFINE p_carrier_code LIKE carrier.carrier_code 
	DEFINE l_rec_carriercost RECORD LIKE carriercost.* 
	DEFINE l_nrof_cons_num SMALLINT 
	DEFINE l_part_char LIKE carrier.next_consign 
	DEFINE l_part_old_char LIKE carrier.next_consign 
	DEFINE l_part_num INTEGER 
	DEFINE i SMALLINT 
	DEFINE x SMALLINT 
	DEFINE y SMALLINT 
	DEFINE z SMALLINT 

	SELECT * 
	INTO glob_rec_carrier.* 
	FROM carrier 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND carrier_code = p_carrier_code 

	IF status = NOTFOUND THEN 
		RETURN FALSE 
	END IF 

	SELECT country_text 
	INTO glob_rec_country.country_text 
	FROM country 
	WHERE country_code = glob_rec_carrier.country_code 

	IF status = NOTFOUND THEN 
		LET glob_rec_country.country_text = "**********" 
	END IF 

	INSERT INTO temp_carriercost SELECT * 
	FROM carriercost 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND carrier_code = glob_rec_carrier.carrier_code 

	LET i = sqlca.sqlerrd[3] 

	OPEN WINDOW e141 with FORM "E141" 
	 CALL windecoration_e("E141") 

	DISPLAY BY NAME glob_rec_country.state_code_text, 
	glob_rec_country.post_code_text 
	attribute(white) 

	DECLARE c1_carriercost cursor FOR 
	SELECT * FROM temp_carriercost 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND carrier_code = p_carrier_code 
	ORDER BY cmpy_code, 
	carrier_code, 
	country_code, 
	state_code, 
	freight_ind 
	OPEN c1_carriercost 

	FOR i = 1 TO 4 
		FETCH c1_carriercost INTO l_rec_carriercost.* 
		IF sqlca.sqlcode = 0 THEN 
			DISPLAY l_rec_carriercost.country_code, 
			l_rec_carriercost.state_code, 
			l_rec_carriercost.freight_ind, 
			l_rec_carriercost.freight_amt 
			TO sr_carriercost[i].* 

		END IF 
	END FOR 

	DISPLAY BY NAME glob_rec_carrier.carrier_code, 
	glob_rec_carrier.last_consign, 
	glob_rec_country.country_text 

	LET l_nrof_cons_num = NULL 

	INPUT 
		glob_rec_carrier.name_text, 
		glob_rec_carrier.addr1_text, 
		glob_rec_carrier.addr2_text, 
		glob_rec_carrier.city_text, 
		glob_rec_carrier.state_code, 
		glob_rec_carrier.post_code, 
		glob_rec_carrier.country_code, 
		glob_rec_carrier.next_consign, 
		l_nrof_cons_num, 
		glob_rec_carrier.next_manifest, 
		glob_rec_carrier.charge_ind, 
		glob_rec_carrier.format_ind WITHOUT DEFAULTS 
	FROM 
		name_text, 
		addr1_text, 
		addr2_text, 
		city_text, 
		state_code, 
		post_code, 
		country_code, 
		next_consign, 
		nrof_cons_num, 
		next_manifest, 
		charge_ind, 
		format_ind ATTRIBUTE(UNBUFFERED)

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","EZ4","input-carrier") 
			CALL db_country_localize(glob_rec_carrier.country_code)
			
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

			#			ON ACTION "carrierCost_add"
			#				CALL carriercost_edit(p_carrier_code)


		ON ACTION "LOOKUP" infield (country_code) 
			LET glob_rec_carrier.country_code = show_country() 
			IF glob_rec_carrier.country_code IS NOT NULL THEN 
				DISPLAY BY NAME glob_rec_carrier.country_code 

			END IF 
			NEXT FIELD country_code 

		AFTER FIELD name_text 
			IF glob_rec_carrier.name_text IS NULL THEN 
				ERROR kandoomsg2("E",9098,"") 			#9098 Carrier name OR description must be Entered
				NEXT FIELD name_text 
			END IF 

		ON CHANGE country_code
			CALL db_country_localize(glob_rec_carrier.country_code) --@db-patch_2020_10_04-- #Localize

		AFTER FIELD country_code 
			IF glob_rec_carrier.country_code IS NULL THEN 
				ERROR kandoomsg2("E",9095,"")				#9095 country must be entered
				CLEAR country_text 
				NEXT FIELD country_code 
			ELSE 
				SELECT country_text 
				INTO glob_rec_country.country_text 
				FROM country 
				WHERE country_code = glob_rec_carrier.country_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("E",9096,"") 				#9096 country NOT found - try window
					CLEAR country_text 
					NEXT FIELD country_code 
				ELSE 
					DISPLAY BY NAME glob_rec_country.country_text 

				END IF 
			END IF 

		AFTER FIELD next_consign 
			IF glob_rec_carrier.next_consign IS NULL THEN 
				ERROR kandoomsg2("E",9099,"") 			#9099 Consigment note must be entered
				LET glob_rec_carrier.next_consign = 0 
				NEXT FIELD next_consign 
			END IF 

		AFTER FIELD nrof_cons_num 
			IF l_nrof_cons_num IS NULL THEN 
				IF fgl_lastkey() = fgl_keyval("up") 
				OR fgl_lastkey() = fgl_keyval("left") THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 

			IF l_nrof_cons_num <= 0 THEN 
				ERROR kandoomsg2("E",9136,"") 			#9136 Number of needed consignment notes must be greater than 0
				LET l_nrof_cons_num = 0 
				NEXT FIELD nrof_cons_num 
			END IF 

			LET l_part_char = NULL 
			FOR x = length(glob_rec_carrier.next_consign) TO 1 step -1 
				IF glob_rec_carrier.next_consign[x,x] < "0" 
				OR glob_rec_carrier.next_consign[x,x] > "9" THEN 
					EXIT FOR 
				ELSE 
					LET l_part_char[x,x] = glob_rec_carrier.next_consign[x,x] 
				END IF 
			END FOR 

			IF l_part_char IS NULL THEN 
				ERROR kandoomsg2("E",9143,"") 		#9143 Next consignment note consists of characters only no addition
				NEXT FIELD next_consign 
			END IF 

			# Length numeric part original number
			LET y = length(l_part_char) - x 
			IF y > 9 THEN 
				ERROR kandoomsg2("E",9148,"") 			#9148 Numeric part may NOT be more than 9 digits
				NEXT FIELD next_consign 
			END IF 

			LET l_part_num = l_part_char + l_nrof_cons_num - 1 
			LET l_part_char = l_part_num 
			# Length numeric part new number
			LET z = length(l_part_char) 
			# Check IF addition leads TO outnumbering

			LET x = length(glob_rec_carrier.next_consign) + z - y 
			IF x > 15 THEN 
				ERROR kandoomsg2("E",9145,"") 		#9145 Ran out of consignment note numbers
				NEXT FIELD nrof_cons_num 
			END IF 

			# IF length new number < length old number fill with leading zeroes
			IF z < y THEN 
				LET l_part_old_char = l_part_char 
				FOR i = y TO 1 step -1 
					LET l_part_char[i,i] = "0" 
				END FOR 
				LET i = y - z + 1 
				LET l_part_char[i,y] = l_part_old_char[1,z] 
				# Length numeric part new number
				LET z = length(l_part_char) 
			END IF 

			#  Determine startposition new number
			LET x = length(glob_rec_carrier.next_consign) - y + 1 
			# Determine endposition new number
			LET y = x + z - 1 
			LET glob_rec_carrier.last_consign = glob_rec_carrier.next_consign 

			# Place new number AT correct position in last consigment note number
			LET glob_rec_carrier.last_consign[x,y] = l_part_char[1,z] 
			DISPLAY BY NAME glob_rec_carrier.last_consign 

			SELECT unique 1 
			FROM despatchdetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND carrier_code = glob_rec_carrier.carrier_code 
			AND despatch_code between glob_rec_carrier.next_consign 
			AND glob_rec_carrier.last_consign 

			IF status != NOTFOUND THEN 
				ERROR kandoomsg2("E",9147,"") 		#9147 This range contains an already consignment note number
				NEXT FIELD next_consign 
			END IF 

		AFTER FIELD next_manifest 
			IF glob_rec_carrier.next_manifest IS NULL THEN 
				ERROR kandoomsg2("E",9113,"") 			#9113 Last manifest number must be entered
				LET glob_rec_carrier.next_manifest = 0 
				NEXT FIELD next_manifest 
			END IF 
			IF glob_rec_carrier.next_manifest < 0 THEN 
				ERROR kandoomsg2("E",9122,"") #9122 Last manifest number must NOT be negative
				LET glob_rec_carrier.next_manifest = 0 
				NEXT FIELD next_manifest 
			END IF 

		AFTER FIELD format_ind 
			IF glob_rec_carrier.format_ind IS NULL THEN 
				ERROR kandoomsg2("E",9114,"") 		#9114 Format must be entered (1 TO 99)
				LET glob_rec_carrier.format_ind = 1 
				NEXT FIELD format_ind 
			END IF 

		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF glob_rec_carrier.name_text IS NULL THEN 
					ERROR kandoomsg2("E",9098,"") 		#9098 Carrier name OR description must be Entered
					NEXT FIELD name_text 
				END IF 

				SELECT unique 1 FROM country 
				WHERE country_code = glob_rec_carrier.country_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("E",9096,"") 			#9096 country NOT found - try window
					NEXT FIELD country_code 
				END IF 
				#removed by request of user testing (Anna) - State Code is not used by all countries
				#IF glob_rec_carrier.state_code IS NULL THEN
				#   ERROR kandoomsg2("E",9103,"")   #9099 Last shipment/consigment note invalid
				#   NEXT FIELD state_code
				#END IF

				IF glob_rec_carrier.next_consign IS NULL THEN 
					ERROR kandoomsg2("E",9099,"") 				#9099 Consigment note must be entered
					LET glob_rec_carrier.next_consign = 0 
					NEXT FIELD next_consign 
				END IF 
				IF glob_rec_carrier.next_manifest IS NULL THEN 
					ERROR kandoomsg2("E",9113,"") 		#9113 Last manifest number must be entered
					LET glob_rec_carrier.next_manifest = 0 
					NEXT FIELD next_manifest 
				END IF 
				IF glob_rec_carrier.next_manifest < 0 THEN 
					ERROR kandoomsg2("E",9122,"") 		#9122 Last manifest number must NOT be negative
					LET glob_rec_carrier.next_manifest = 0 
					NEXT FIELD next_manifest 
				END IF 
				IF glob_rec_carrier.format_ind IS NULL THEN 
					ERROR kandoomsg2("E",9114,"") 
					#9114 Format must be entered
					LET glob_rec_carrier.format_ind = 1 
					NEXT FIELD format_ind 
				END IF 

				# Give the user the possibility TO maintain Carrier costs.
				SELECT count(*) 
				INTO i 
				FROM temp_carriercost 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND carrier_code = p_carrier_code 
				#Why is there a hard coded limit of 40 and the array was defind as 100 ? made it a dynamic array
				#IF i < 40 THEN
				IF NOT scan_carriercost("1=1") THEN 
					NEXT FIELD name_text 
				END IF 
				#ELSE
				#   IF NOT scan_carriercost(select_carriercost()) THEN
				#      NEXT FIELD name_text
				#   END IF
				#END IF
			END IF 

			#      ON KEY (control-w)
			#         CALL kandoohelp("")

	END INPUT 
	------------------------------------------------------------


	IF int_flag OR quit_flag THEN 
		LET quit_flag = FALSE 
		LET int_flag = FALSE 
		DELETE FROM temp_carriercost 
		CLOSE WINDOW E141 
		RETURN FALSE 
	ELSE 
		UPDATE carrier 
		SET carrier.* = glob_rec_carrier.* 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND carrier_code = p_carrier_code 
		# Delete all carriercost rows.
		DELETE FROM carriercost 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND carrier_code = p_carrier_code 
		# Insert carriercosts FROM temporary table.
		SELECT unique 1 
		FROM temp_carriercost 
		IF status = NOTFOUND THEN 
		ELSE 
			INSERT INTO carriercost 
			SELECT * FROM temp_carriercost 
			DELETE FROM temp_carriercost 
		END IF 
		CLOSE WINDOW E141 
		RETURN TRUE 
	END IF 
END FUNCTION 
#######################################################################
# END FUNCTION edit_carrier(p_carrier_code)
#######################################################################


#######################################################################
# FUNCTION edit_carrier_carriercost(p_carrier_code)
#
#
#######################################################################
FUNCTION edit_carrier_carriercost(p_carrier_code) 
	DEFINE p_carrier_code LIKE carrier.carrier_code 
	DEFINE l_arr_rec_carriercost DYNAMIC ARRAY OF t_rec_carriercost_co_st_fi_fa 
	DEFINE l_rec_carrier RECORD LIKE carrier.* 
	DEFINE l_rec_carriercost RECORD LIKE carriercost.* 
	DEFINE l_nrof_cons_num SMALLINT 
	DEFINE l_part_char LIKE carrier.next_consign 
	DEFINE l_part_old_char LIKE carrier.next_consign 
	DEFINE l_part_num INTEGER 
	DEFINE i SMALLINT 
	DEFINE x SMALLINT 
	DEFINE y SMALLINT 
	DEFINE z SMALLINT 
	DEFINE l_cost_idx SMALLINT 

	CALL db_carrier_get_rec(p_carrier_code) RETURNING l_rec_carrier.* 
	IF l_rec_carrier.carrier_code IS NULL THEN 
		ERROR "Carrier does not exist" 
		RETURN NULL 
	END IF 
	#   SELECT *
	#      INTO glob_rec_carrier.*
	#      FROM carrier
	#      WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
	#        AND carrier_code = p_carrier_code
	#
	#   IF STATUS = NOTFOUND THEN
	#      RETURN FALSE
	#   END IF
	#
	#   SELECT country_text
	#     INTO glob_rec_country.country_text
	#     FROM country
	#    WHERE country_code = glob_rec_carrier.country_code
	#
	#   IF STATUS = NOTFOUND THEN
	#      LET glob_rec_country.country_text = "**********"
	#   END IF
	#
	#   INSERT INTO temp_carriercost SELECT *
	#     FROM carriercost
	#    WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
	#      AND carrier_code = glob_rec_carrier.carrier_code
	#
	#   LET i = sqlca.sqlerrd[3]

	OPEN WINDOW e141 with FORM "E141" 
	 CALL windecoration_e("E141") 

	#   DISPLAY BY NAME glob_rec_country.state_code_text,
	#                   glob_rec_country.post_code_text
	#      ATTRIBUTE(white)

	#   DECLARE c5_carriercost CURSOR FOR
	#      SELECT * FROM temp_carriercost
	#       WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
	#         AND carrier_code = p_carrier_code
	#       ORDER BY cmpy_code,
	#                carrier_code,
	#                country_code,
	#                state_code,
	#                freight_ind
	#   OPEN c5_carriercost
	#
	#   FOR i = 1 TO 4
	#      FETCH c5_carriercost INTO l_rec_carriercost.*
	#      IF sqlca.sqlcode = 0 THEN
	#         DISPLAY l_rec_carriercost.country_code,
	#                 l_rec_carriercost.state_code,
	#                 l_rec_carriercost.freight_ind,
	#                 l_rec_carriercost.freight_amt
	#              TO sr_carriercost[i].*
	#
	#      END IF
	#   END FOR
	#
	#   DISPLAY BY NAME glob_rec_carrier.carrier_code,
	#                   glob_rec_carrier.last_consign,
	#                   glob_rec_country.country_text
	#
	#   LET l_nrof_cons_num = NULL


	CALL db_carriercost_get_arr_rec_by_carrier_short(p_carrier_code,null) RETURNING l_arr_rec_carriercost 

	# ---------------------------------------------------------------------------------------------
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT 
	l_rec_carrier.name_text, 
	l_rec_carrier.addr1_text, 
	l_rec_carrier.addr2_text, 
	l_rec_carrier.city_text, 
	l_rec_carrier.state_code, 
	l_rec_carrier.post_code, 
	l_rec_carrier.country_code, 
	l_rec_carrier.next_consign, 
	l_nrof_cons_num, 
	l_rec_carrier.next_manifest, 
	l_rec_carrier.charge_ind, 
	l_rec_carrier.format_ind WITHOUT DEFAULTS 
	FROM 
	name_text, 
	addr1_text, 
	addr2_text, 
	city_text, 
	state_code, 
	post_code, 
	country_code, 
	next_consign, 
	nrof_cons_num, 
	next_manifest, 
	charge_ind, 
	format_ind 

	BEFORE INPUT
		DISPLAY l_rec_carrier.carrier_code TO carrier_code 


		ON ACTION "LOOKUP" infield (country_code) 
			LET l_rec_carrier.country_code = show_country() 
			IF l_rec_carrier.country_code IS NOT NULL THEN 
				DISPLAY BY NAME l_rec_carrier.country_code 

			END IF 
			NEXT FIELD country_code 

		AFTER FIELD name_text 
			IF l_rec_carrier.name_text IS NULL THEN 
				ERROR kandoomsg2("E",9098,"") 			#9098 Carrier name OR description must be Entered
				NEXT FIELD name_text 
			END IF 

		AFTER FIELD country_code 
			IF l_rec_carrier.country_code IS NULL THEN 
				ERROR kandoomsg2("E",9095,"") 			#9095 country must be entered
				CLEAR country_text 
				NEXT FIELD country_code 
			ELSE 
				SELECT country_text 
				INTO glob_rec_country.country_text 
				FROM country 
				WHERE country_code = l_rec_carrier.country_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("E",9096,"") 				#9096 country NOT found - try window
					CLEAR country_text 
					NEXT FIELD country_code 
				ELSE 
					DISPLAY BY NAME glob_rec_country.country_text 

				END IF 
			END IF 

		AFTER FIELD next_consign 
			IF l_rec_carrier.next_consign IS NULL THEN 
				ERROR kandoomsg2("E",9099,"") 		#9099 Consigment note must be entered
				LET l_rec_carrier.next_consign = 0 
				NEXT FIELD next_consign 
			END IF 

		AFTER FIELD nrof_cons_num 
			IF l_nrof_cons_num IS NULL THEN 
				IF fgl_lastkey() = fgl_keyval("up") 
				OR fgl_lastkey() = fgl_keyval("left") THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 

			IF l_nrof_cons_num <= 0 THEN 
				ERROR kandoomsg2("E",9136,"") 			#9136 Number of needed consignment notes must be greater than 0
				LET l_nrof_cons_num = 0 
				NEXT FIELD nrof_cons_num 
			END IF 

			LET l_part_char = NULL 
			FOR x = length(l_rec_carrier.next_consign) TO 1 step -1 
				IF l_rec_carrier.next_consign[x,x] < "0" 
				OR l_rec_carrier.next_consign[x,x] > "9" THEN 
					EXIT FOR 
				ELSE 
					LET l_part_char[x,x] = l_rec_carrier.next_consign[x,x] 
				END IF 
			END FOR 

			IF l_part_char IS NULL THEN 
				ERROR kandoomsg2("E",9143,"") 			#9143 Next consignment note consists of characters only no addition
				NEXT FIELD next_consign 
			END IF 

			# Length numeric part original number
			LET y = length(l_part_char) - x 
			IF y > 9 THEN 
				ERROR kandoomsg2("E",9148,"") 		#9148 Numeric part may NOT be more than 9 digits
				NEXT FIELD next_consign 
			END IF 

			LET l_part_num = l_part_char + l_nrof_cons_num - 1 
			LET l_part_char = l_part_num 
			# Length numeric part new number
			LET z = length(l_part_char) 
			# Check IF addition leads TO outnumbering

			LET x = length(l_rec_carrier.next_consign) + z - y 
			IF x > 15 THEN 
				ERROR kandoomsg2("E",9145,"") 			#9145 Ran out of consignment note numbers
				NEXT FIELD nrof_cons_num 
			END IF 

			# IF length new number < length old number fill with leading zeroes
			IF z < y THEN 
				LET l_part_old_char = l_part_char 
				FOR i = y TO 1 step -1 
					LET l_part_char[i,i] = "0" 
				END FOR 
				LET i = y - z + 1 
				LET l_part_char[i,y] = l_part_old_char[1,z] 
				# Length numeric part new number
				LET z = length(l_part_char) 
			END IF 

			#  Determine startposition new number
			LET x = length(l_rec_carrier.next_consign) - y + 1 
			# Determine endposition new number
			LET y = x + z - 1 
			LET l_rec_carrier.last_consign = l_rec_carrier.next_consign 

			# Place new number AT correct position in last consigment note number
			LET l_rec_carrier.last_consign[x,y] = l_part_char[1,z] 
			DISPLAY BY NAME l_rec_carrier.last_consign 

			SELECT unique 1 
			FROM despatchdetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND carrier_code = l_rec_carrier.carrier_code 
			AND despatch_code between l_rec_carrier.next_consign 
			AND l_rec_carrier.last_consign 

			IF status != NOTFOUND THEN 
				ERROR kandoomsg2("E",9147,"") 			#9147 This range contains an already consignment note number
				NEXT FIELD next_consign 
			END IF 

		AFTER FIELD next_manifest 
			IF l_rec_carrier.next_manifest IS NULL THEN 
				ERROR kandoomsg2("E",9113,"") 			#9113 Last manifest number must be entered
				LET l_rec_carrier.next_manifest = 0 
				NEXT FIELD next_manifest 
			END IF 
			IF l_rec_carrier.next_manifest < 0 THEN 
				ERROR kandoomsg2("E",9122,"") #9122 Last manifest number must NOT be negative
				LET l_rec_carrier.next_manifest = 0 
				NEXT FIELD next_manifest 
			END IF 

		AFTER FIELD format_ind 
			IF l_rec_carrier.format_ind IS NULL THEN 
				ERROR kandoomsg2("E",9114,"") 	#9114 Format must be entered (1 TO 99)
				LET l_rec_carrier.format_ind = 1 
				NEXT FIELD format_ind 
			END IF 
			{
			      AFTER INPUT
			      IF NOT (int_flag OR quit_flag) THEN
			         IF l_rec_carrier.name_text IS NULL THEN
			            ERROR kandoomsg2("E",9098,"") #9098 Carrier name OR description must be Entered
			            NEXT FIELD name_text
			         END IF

			         SELECT unique 1 FROM country
			              WHERE country_code = l_rec_carrier.country_code
			         IF STATUS = NOTFOUND THEN
			            ERROR kandoomsg2("E",9096,"")	#9096 country NOT found - try window
			            NEXT FIELD country_code
			         END IF
			#removed by request of user testing (Anna) - State Code is not used by all countries
			#IF l_rec_carrier.state_code IS NULL THEN
			#   ERROR kandoomsg2("E",9103,"")   #9099 Last shipment/consigment note invalid
			#   NEXT FIELD state_code
			#END IF

			         IF l_rec_carrier.next_consign IS NULL THEN
			            ERROR kandoomsg2("E",9099,"")		#9099 Consigment note must be entered
			            LET l_rec_carrier.next_consign = 0
			            NEXT FIELD next_consign
			         END IF
			         IF l_rec_carrier.next_manifest IS NULL THEN
			            ERROR kandoomsg2("E",9113,"")		#9113 Last manifest number must be entered
			            LET l_rec_carrier.next_manifest = 0
			            NEXT FIELD next_manifest
			         END IF
			         IF l_rec_carrier.next_manifest < 0 THEN
			            ERROR kandoomsg2("E",9122,"")		#9122 Last manifest number must NOT be negative
			            LET l_rec_carrier.next_manifest = 0
			            NEXT FIELD next_manifest
			         END IF
			         IF l_rec_carrier.format_ind IS NULL THEN
			            ERROR kandoomsg2("E",9114,"")	#9114 Format must be entered
			            LET l_rec_carrier.format_ind = 1
			            NEXT FIELD format_ind
			         END IF

			# Give the user the possibility TO maintain Carrier costs.
			         SELECT count(*)
			           INTO i
			           FROM temp_carriercost
			          WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
			            AND carrier_code = p_carrier_code
			#Why is there a hard coded limit of 40 and the array was defind as 100 ? made it a dynamic array
			#IF i < 40 THEN
			            IF NOT scan_carriercost("1=1") THEN
			               NEXT FIELD name_text
			            END IF
			#ELSE
			#   IF NOT scan_carriercost(select_carriercost()) THEN
			#      NEXT FIELD name_text
			#   END IF
			#END IF
			      END IF
			}
			#      ON KEY (control-w)
			#         CALL kandoohelp("")

	END INPUT 

	# -----------------------------------------------------------------------

	DISPLAY ARRAY l_arr_rec_carriercost TO sr_carriercost.* 
		BEFORE ROW 
			LET l_cost_idx = dialog.getCurrentRow("sr_carriercost") 

		ON ACTION ("doubleClick","editCarrierCost") 
			CALL carriercost_edit(p_carrier_code,l_arr_rec_carriercost[l_cost_idx].country_code,l_arr_rec_carriercost[l_cost_idx].state_code,l_arr_rec_carriercost[l_cost_idx].freight_ind)
			CALL l_arr_rec_carriercost.clear() 
			CALL db_carriercost_get_arr_rec_by_carrier_short(p_carrier_code,null) RETURNING l_arr_rec_carriercost 

		ON ACTION "deleteCarrierCost" 
			IF db_carriercost_delete(p_carrier_code,l_arr_rec_carriercost[l_cost_idx].country_code,l_arr_rec_carriercost[l_cost_idx].state_code,l_arr_rec_carriercost[l_cost_idx].freight_ind) = 0 THEN 
				MESSAGE "Carrier Cost configuration deleted" 
				CALL l_arr_rec_carriercost.clear() 
				CALL db_carriercost_get_arr_rec_by_carrier_short(p_carrier_code,null) RETURNING l_arr_rec_carriercost 
			ELSE 
				ERROR "Could not delete Carrier Cost configuration" 
			END IF 


	END DISPLAY 
	# -----------------------------------------------------------------------

	BEFORE dialog 
		CALL publish_toolbar("kandoo","IZ4","input-carrier") 

		AFTER dialog 

			IF NOT (int_flag OR quit_flag) THEN 
				IF l_rec_carrier.name_text IS NULL THEN 
					ERROR kandoomsg2("E",9098,"") 				#9098 Carrier name OR description must be Entered
					NEXT FIELD name_text 
				END IF 

				SELECT unique 1 FROM country 
				WHERE country_code = l_rec_carrier.country_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("E",9096,"") 			#9096 country NOT found - try window
					NEXT FIELD country_code 
				END IF 
				#removed by request of user testing (Anna) - State Code is not used by all countries
				#IF l_rec_carrier.state_code IS NULL THEN
				#   ERROR kandoomsg2("E",9103,"")			#   #9099 Last shipment/consigment note invalid
				#   NEXT FIELD state_code
				#END IF

				IF l_rec_carrier.next_consign IS NULL THEN 
					ERROR kandoomsg2("E",9099,"") 			#9099 Consigment note must be entered
					LET l_rec_carrier.next_consign = 0 
					NEXT FIELD next_consign 
				END IF 
				IF l_rec_carrier.next_manifest IS NULL THEN 
					ERROR kandoomsg2("E",9113,"") 		#9113 Last manifest number must be entered
					LET l_rec_carrier.next_manifest = 0 
					NEXT FIELD next_manifest 
				END IF 
				IF l_rec_carrier.next_manifest < 0 THEN 
					ERROR kandoomsg2("E",9122,"") 	#9122 Last manifest number must NOT be negative
					LET l_rec_carrier.next_manifest = 0 
					NEXT FIELD next_manifest 
				END IF 
				IF l_rec_carrier.format_ind IS NULL THEN 
					ERROR kandoomsg2("E",9114,"") 		#9114 Format must be entered
					LET l_rec_carrier.format_ind = 1 
					NEXT FIELD format_ind 
				END IF 


				IF db_carriercost_get_count_by_carrier(l_rec_carrier.carrier_code) < 1 THEN 
					CASE promptYNC("Carrier without Cost Configuration","You can NOT have a carrier WITHOUT any cost configuaration!\do you want TO add a cost configuration ?\nno=delete carrrier details !","Yes") 
						WHEN "y" 
							CALL carriercost_edit(p_carrier_code,null,null,null) 
							CALL db_carriercost_get_arr_rec_by_carrier_short(p_carrier_code,null) RETURNING l_arr_rec_carriercost 
							CONTINUE dialog 
						WHEN "n" 
							IF promptTF("Delete carrier configuration","Are you sure you want TO DELETE this carrier ?",TRUE) THEN 
								IF db_carrier_is_used(p_carrier_code) THEN 
									ERROR "Can not delete carrier configuration as it is used" 
									CONTINUE dialog 
								END IF 
								IF db_carrier_delete(l_rec_carrier.carrier_code) THEN 
									ERROR "Could not delete carrier configuration!" 
								ELSE 
									MESSAGE "Carrier configuration deleted" 
									CALL db_carriercost_get_arr_rec_by_carrier_short(p_carrier_code,null) RETURNING l_arr_rec_carriercost 
								END IF 
							ELSE 
								CONTINUE dialog 
							END IF 
						OTHERWISE 
							LET int_flag = FALSE 
							CONTINUE dialog 
					END CASE 
				END IF 
			END IF 
			# Give the user the possibility TO maintain Carrier costs.
			#         SELECT count(*)
			#           INTO i
			#           FROM temp_carriercost
			#          WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
			#            AND carrier_code = p_carrier_code
			#         #Why is there a hard coded limit of 40 and the array was defind as 100 ? made it a dynamic array
			#         #IF i < 40 THEN
			#            IF NOT scan_carriercost("1=1") THEN
			#               NEXT FIELD name_text
			#            END IF
			#         #ELSE
			#   IF NOT scan_carriercost(select_carriercost()) THEN
			#      NEXT FIELD name_text
			#   END IF
			#END IF
			#      END IF


	ON ACTION "WEB-HELP" 
		CALL onlinehelp(getmoduleid(),null) 

	ON ACTION "actToolbarManager" 
		CALL setuptoolbar() 

	ON ACTION "addCarrierCost" 
		CALL carriercost_edit(p_carrier_code,null,null,null)
		CALL l_arr_rec_carriercost.clear() 
		CALL db_carriercost_get_arr_rec_by_carrier_short(p_carrier_code,null) RETURNING l_arr_rec_carriercost 

	ON ACTION "DONE" 
		EXIT dialog 

		END dialog 
		------------------------------------------------------------


		IF int_flag OR quit_flag THEN 
			LET quit_flag = FALSE 
			LET int_flag = FALSE 
			#DELETE FROM temp_carriercost
			CLOSE WINDOW E141 
			RETURN FALSE 
		ELSE 
			UPDATE carrier 
			SET carrier.* = l_rec_carrier.* 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND carrier_code = p_carrier_code 
			# Delete all carriercost rows.
			#DELETE FROM carriercost
			# WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
			#   AND carrier_code = p_carrier_code
			# Insert carriercosts FROM temporary table.
			#SELECT unique 1
			#  FROM temp_carriercost
			#IF STATUS = NOTFOUND THEN
			#ELSE
			#IF status = 0
			#   INSERT INTO carriercost
			#      SELECT * FROM temp_carriercost
			#   DELETE FROM temp_carriercost
			#END IF
			CLOSE WINDOW E141 
			RETURN TRUE 
		END IF 
END FUNCTION 
#######################################################################
# END FUNCTION edit_carrier_carriercost(p_carrier_code)
#######################################################################


#######################################################################
# FUNCTION add_carrier()
#
#
#######################################################################
FUNCTION add_carrier() 
	DEFINE l_rec_carrier RECORD LIKE carrier.* 
	DEFINE l_nrof_cons_num SMALLINT 
	DEFINE l_part_char LIKE carrier.next_consign 
	DEFINE l_part_old_char LIKE carrier.next_consign 
	DEFINE l_part_num INTEGER 
	DEFINE i SMALLINT 
	DEFINE x SMALLINT 
	DEFINE y SMALLINT 
	DEFINE z SMALLINT 

	OPEN WINDOW E144 with FORM "E144" 
	 CALL windecoration_e("E144") 

	#DISPLAY BY NAME glob_rec_country.state_code_text,
	#                glob_rec_country.post_code_text
	#   ATTRIBUTE(white)

	#INITIALIZE l_rec_carrier.* TO NULL
	LET l_rec_carrier.charge_ind = "1" 
	LET l_rec_carrier.format_ind = "1" 
	LET l_rec_carrier.country_code = glob_rec_country.country_code 
	LET l_rec_carrier.cmpy_code = glob_rec_kandoouser.cmpy_code 
	INPUT 
		l_rec_carrier.carrier_code, 
		l_rec_carrier.name_text, 
		l_rec_carrier.addr1_text, 
		l_rec_carrier.addr2_text, 
		l_rec_carrier.city_text, 
		l_rec_carrier.state_code, 
		l_rec_carrier.post_code, 
		l_rec_carrier.country_code, 
		l_rec_carrier.next_consign, 
		l_nrof_cons_num, 
		l_rec_carrier.next_manifest, 
		l_rec_carrier.charge_ind, 
		l_rec_carrier.format_ind WITHOUT DEFAULTS 
	FROM 
		carrier_code, 
		name_text, 
		addr1_text, 
		addr2_text, 
		city_text, 
		state_code, 
		post_code, 
		country_code, 
		next_consign, 
		nrof_cons_num, 
		next_manifest, 
		charge_ind, 
		format_ind 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","EZ4","input-carrier2") 
			CALL comboList_state("state_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,l_rec_carrier.country_code,COMBO_NULL_SPACE) 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
			
		ON ACTION "LOOKUP" infield (country_code) 
			LET l_rec_carrier.country_code = show_country() 
			IF l_rec_carrier.country_code IS NOT NULL THEN 
				DISPLAY BY NAME l_rec_carrier.country_code 
			END IF 
			NEXT FIELD country_code 


		AFTER FIELD carrier_code 
			IF l_rec_carrier.carrier_code IS NULL THEN 
				ERROR kandoomsg2("E",9092,"") 			#9092" Carrier must be entered
				NEXT FIELD carrier_code 
			ELSE 
				SELECT unique 1 FROM carrier 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND carrier_code = l_rec_carrier.carrier_code 
				IF status = 0 THEN 
					ERROR kandoomsg2("E",9093,"") 				#9093" Carrier already exists - Please Re Enter "
					NEXT FIELD carrier_code 
				END IF 
			END IF 

		AFTER FIELD name_text 
			IF l_rec_carrier.name_text IS NULL THEN 
				ERROR kandoomsg2("E",9098,"") 			#9098 Carrier name OR description must be Entered
				NEXT FIELD name_text 
			END IF 

		AFTER FIELD country_code 
			IF l_rec_carrier.country_code IS NULL THEN 
				ERROR kandoomsg2("E",9095,"") 			#9095 country must be entered
				CLEAR country_text 
				NEXT FIELD country_code 
			ELSE 
				SELECT country_text 
				INTO glob_rec_country.country_text 
				FROM country 
				WHERE country_code = l_rec_carrier.country_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("E",9096,"") 	#9096 country NOT found - try window
					CLEAR country_text 
					NEXT FIELD country_code 
				ELSE 
					DISPLAY BY NAME glob_rec_country.country_text 

				END IF 
			END IF 
			CALL comboList_state("state_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,l_rec_carrier.country_code,COMBO_NULL_SPACE) 
			#we are going to remove state codes and make it a full state description/name field
			#AFTER FIELD state_code
			#   IF l_rec_carrier.state_code IS NULL THEN
			#      ERROR kandoomsg2("E",9103,"")   #9103 State code must be entered
			#      NEXT FIELD state_code
			#   END IF

		AFTER FIELD next_consign 
			IF l_rec_carrier.next_consign IS NULL THEN 
				ERROR kandoomsg2("E",9099,"") #9099 Consigment note must be entered
				LET l_rec_carrier.next_consign = 0 
				NEXT FIELD next_consign 
			END IF 

		AFTER FIELD nrof_cons_num 
			IF l_nrof_cons_num IS NULL THEN
				IF NOT get_is_screen_navigation_forward() THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 

			IF l_nrof_cons_num <= 0 THEN 
				ERROR kandoomsg2("E",9136,"") #9136 Number of needed consignment notes must be greater than 0
				LET l_nrof_cons_num = 0 
				NEXT FIELD nrof_cons_num 
			END IF 

			LET l_part_char = NULL 
			FOR x = length(l_rec_carrier.next_consign) TO 1 step -1 
				IF l_rec_carrier.next_consign[x,x] < "0" 
				OR l_rec_carrier.next_consign[x,x] > "9" THEN 
					EXIT FOR 
				ELSE 
					LET l_part_char[x,x] = l_rec_carrier.next_consign[x,x] 
				END IF 
			END FOR 

			IF l_part_char IS NULL THEN 
				ERROR kandoomsg2("E",9143,"") 			#9143 Next consignment note consists of characters only no addition
				NEXT FIELD next_consign 
			END IF 
			
			# Length numeric part original number
			LET y = length(l_part_char) - x 
			IF y > 9 THEN 
				ERROR kandoomsg2("E",9148,"") 			#9148 Numeric part may NOT be more than 9 digits
				NEXT FIELD next_consign 
			END IF 
			LET l_part_num = l_part_char + l_nrof_cons_num - 1 
			LET l_part_char = l_part_num 
			
			# Length numeric part new number
			LET z = length(l_part_char) 
			
			# Check IF addition leads TO outnumbering
			LET x = length(l_rec_carrier.next_consign) + z - y 
			IF x > 15 THEN 
				ERROR kandoomsg2("E",9145,"") 			#9145 Ran out of consignment note numbers
				NEXT FIELD nrof_cons_num 
			END IF 

			# IF length new number < length old number fill with leading zeroes
			IF z < y THEN 
				LET l_part_old_char = l_part_char 
				FOR i = y TO 1 step -1 
					LET l_part_char[i,i] = "0" 
				END FOR 
				LET i = y - z + 1 
				LET l_part_char[i,y] = l_part_old_char[1,z] 
				# Length numeric part new number
				LET z = length(l_part_char) 
			END IF 
			
			#  Determine startposition new number
			LET x = length(l_rec_carrier.next_consign) - y + 1 
			
			# Determine endposition new number
			LET y = x + z - 1 
			LET l_rec_carrier.last_consign = l_rec_carrier.next_consign 
			
			# Place new number AT correct position in last consigment note number
			LET l_rec_carrier.last_consign[x,y] = l_part_char[1,z] 
			DISPLAY BY NAME l_rec_carrier.last_consign 

			SELECT unique 1 
			FROM despatchdetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND carrier_code = l_rec_carrier.carrier_code 
			AND despatch_code between l_rec_carrier.next_consign 
			AND l_rec_carrier.last_consign 
			IF status != NOTFOUND THEN 
				ERROR kandoomsg2("E",9147,"") 			#9147 This range contains an already consignment note number
				NEXT FIELD next_consign 
			END IF 

		AFTER FIELD next_manifest 
			IF l_rec_carrier.next_manifest IS NULL THEN 
				ERROR kandoomsg2("E",9113,"") 			#9113 Last manifest number must be entered
				LET l_rec_carrier.next_manifest = 0 
				NEXT FIELD next_manifest 
			END IF 
			
			IF l_rec_carrier.next_manifest < 0 THEN 
				ERROR kandoomsg2("E",9122,"") 			#9122 Last manifest number must NOT be negative
				LET l_rec_carrier.next_manifest = 0 
				NEXT FIELD next_manifest 
			END IF 

		AFTER FIELD format_ind 
			IF l_rec_carrier.format_ind IS NULL THEN 
				ERROR kandoomsg2("E",9114,"") 			#9114 Format must be entered (1 TO 99)
				LET l_rec_carrier.format_ind = 1 
				NEXT FIELD format_ind 
			END IF 

		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 


				IF db_carrier_pk_exists(l_rec_carrier.carrier_code) THEN 
					#            SELECT unique 1
					#              FROM carrier
					#             WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
					#               AND carrier_code = l_rec_carrier.carrier_code
					#            IF STATUS = 0 THEN
					ERROR kandoomsg2("E",9093,"") 				#9093" Cariier already exists - Please Re Enter "
					NEXT FIELD carrier_code 
				END IF 

				#validate country
				IF NOT db_country_pk_exists(ui_off,null,l_rec_carrier.country_code) THEN 


					#            SELECT unique 1 FROM country
					#              WHERE country_code = l_rec_carrier.country_code
					#            IF STATUS = NOTFOUND THEN
					ERROR kandoomsg2("E",9096,"") 				#9096 country NOT found - try window
					NEXT FIELD country_code 
				END IF 

				#carrier name must not be empty
				IF l_rec_carrier.name_text IS NULL THEN 
					ERROR kandoomsg2("E",9098,"") 				#9098 State name OR description must be Entered
					NEXT FIELD name_text 
				END IF 

				#IF l_rec_carrier.state_code IS NULL THEN
				#   ERROR kandoomsg2("E",9103,"")   #9103 State code must be entered
				#   NEXT FIELD state_code
				#END IF
				IF l_rec_carrier.next_consign IS NULL THEN 
					ERROR kandoomsg2("E",9099,"") 	#9099 Consigment note must be entered
					LET l_rec_carrier.next_consign = 0 
					NEXT FIELD next_consign 
				END IF 

				IF l_rec_carrier.next_manifest IS NULL THEN 
					ERROR kandoomsg2("E",9113,"") 	#9113 Last manifest number must be entered
					LET l_rec_carrier.next_manifest = 0 
					NEXT FIELD next_manifest 
				END IF 

				IF l_rec_carrier.next_manifest < 0 THEN 
					ERROR kandoomsg2("E",9122,"") 		#9122 Last manifest number must NOT be negative
					LET l_rec_carrier.next_manifest = 0 
					NEXT FIELD next_manifest 
				END IF 
				IF l_rec_carrier.format_ind IS NULL 
				OR l_rec_carrier.format_ind > 99 
				OR l_rec_carrier.format_ind < 1 THEN 
					ERROR kandoomsg2("E",9114,"") 		#9114 Format must be entered (1 TO 99)
					LET l_rec_carrier.format_ind = 1 
					NEXT FIELD format_ind 
				END IF 

				# Give the user the possibility TO maintain Carrier costs.
				#IF NOT scan_carriercost("1=1") THEN
				#   NEXT FIELD name_text
				#END IF
			END IF 

	END INPUT 
	--------------------------------------------------------

	IF int_flag OR quit_flag THEN 
		LET quit_flag = FALSE 
		LET int_flag = FALSE 
		#DELETE FROM temp_carriercost
		CLOSE WINDOW E144 
		RETURN "" 
	ELSE 
		LET l_rec_carrier.cmpy_code = glob_rec_kandoouser.cmpy_code 

		IF db_carrier_insert(l_rec_carrier.*) <> 0 THEN 
			ERROR "Could not create carrier configuration" 
			LET l_rec_carrier.carrier_code = NULL 
		ELSE 
			MESSAGE "Carrier Configuaration created" 
		END IF 
		#INSERT INTO carrier VALUES(l_rec_carrier.*)
		# Insert carriercosts FROM temporary table.
		#SELECT unique 1
		#  FROM temp_carriercost
		#IF STATUS = NOTFOUND THEN
		#ELSE
		#   INSERT INTO carriercost
		#      SELECT * FROM temp_carriercost
		#   DELETE FROM temp_carriercost
		#END IF
		CLOSE WINDOW E144 
		RETURN l_rec_carrier.carrier_code 
	END IF 
END FUNCTION 
#######################################################################
# END FUNCTION add_carrier()
#######################################################################


#######################################################################
# FUNCTION select_carriercost()
#
#
#######################################################################
FUNCTION select_carriercost() 
	DEFINE l_rec_carriercost RECORD LIKE carriercost.* 
	DEFINE l_where_text char(100) 
	DEFINE i SMALLINT 

	FOR i = 1 TO 4 
		INITIALIZE l_rec_carriercost.* TO NULL 
		DISPLAY "", 
		l_rec_carriercost.country_code, 
		l_rec_carriercost.state_code, 
		l_rec_carriercost.freight_ind, 
		l_rec_carriercost.freight_amt 
		TO sr_carriercost[i].* 

	END FOR 

	MESSAGE kandoomsg2("E",1001,"") #1001 " Enter Selection Criteria - ESC TO Continue"
	CONSTRUCT l_where_text ON country_code, 
	state_code, 
	freight_ind 
	FROM carriercost.country_code, 
	carriercost.state_code, 
	carriercost.freight_ind 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","EZ4","construct-carriercost") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN "" 
	ELSE 
		RETURN l_where_text 
	END IF 

END FUNCTION 
#######################################################################
# END FUNCTION select_carriercost()
#######################################################################


#######################################################################
# FUNCTION scan_carriercost(p_where_text)
#
#
#######################################################################
FUNCTION scan_carriercost(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING 

	DEFINE l_rec_carriercost RECORD LIKE carriercost.* 
	DEFINE l_arr_rec_carriercost DYNAMIC ARRAY OF t_rec_carriercost_co_st_fi_fa 
	#		RECORD
	#			#  scroll_flag CHAR(1),
	#			country_code LIKE carriercost.country_code,
	#			state_code LIKE carriercost.state_code,
	#			freight_ind LIKE carriercost.freight_ind,
	#			freight_amt LIKE carriercost.freight_amt
	#		END RECORD
	DEFINE l_arr_rowid DYNAMIC ARRAY OF INTEGER 
	DEFINE l_rowid INTEGER 
	DEFINE l_scroll_flag char(1) 
	DEFINE l_nrof_carriercosts SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_del_cnt SMALLINT 

	IF p_where_text IS NULL THEN 
		LET p_where_text = "1=1" 
	END IF 

	MESSAGE kandoomsg2("E",1002,"") #1002 " Searching database - please wait"

	CALL db_carriercost_get_arr_rec_by_carrier_short(glob_rec_carrier.carrier_code,p_where_text) RETURNING l_arr_rec_carriercost 
	{
	#LET l_query_text = "SELECT rowid,* ",
	   LET l_query_text = "SELECT * ",
	                      "FROM carriercost ",
	                     "WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ",
	                      " AND carrier_code = \"",glob_rec_carrier.carrier_code,"\" ",
	                       "AND ",p_where_text clipped," ",
	                     "ORDER BY cmpy_code,",
	                              "carrier_code,",
	                              "country_code,",
	                              "state_code,",
	                              "freight_ind"
	   PREPARE s_carriercost FROM l_query_text
	   DECLARE c_carriercost CURSOR FOR s_carriercost
	   LET l_idx = 0

	   FOREACH c_carriercost INTO l_rowid,
	                              l_rec_carriercost.*
	      LET l_idx = l_idx + 1
	      LET l_arr_rec_carriercost[l_idx].country_code = l_rec_carriercost.country_code
	      LET l_arr_rec_carriercost[l_idx].state_code = l_rec_carriercost.state_code
	      LET l_arr_rec_carriercost[l_idx].freight_ind = l_rec_carriercost.freight_ind
	      LET l_arr_rec_carriercost[l_idx].freight_amt = l_rec_carriercost.freight_amt
	      LET l_arr_rowid[l_idx] = l_rowid
	      IF l_idx = 100 THEN
	         ERROR kandoomsg2("E",9100,"100")
	#9100 " First ??? Carriercosts Selected Only"
	         EXIT FOREACH
	      END IF
	   END FOREACH
	}

	OPTIONS INSERT KEY f1, 
	DELETE KEY f2 
	#   IF l_idx = 0 THEN
	#      CALL set_count(1)
	#   ELSE
	#      CALL set_count(l_idx)
	#   END IF

	#LET l_nrof_carriercosts = arr_count()
	LET l_nrof_carriercosts = l_arr_rec_carriercost.getlength() 

	MESSAGE kandoomsg2("E",1003,"")	#" F1 TO Add - F2 TO Delete - RETURN TO Edit "

	INPUT ARRAY l_arr_rec_carriercost WITHOUT DEFAULTS FROM sr_carriercost.* attributes(unbuffered, append row=FALSE) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","EZ4","inp-arr-carriercost") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (country_code) 
			LET l_arr_rec_carriercost[l_idx].country_code = show_country() 
			IF l_arr_rec_carriercost[l_idx].country_code IS NULL THEN 
				NEXT FIELD carriercost.country_code 
			END IF 

		BEFORE ROW 
			LET l_idx = arr_curr() 

		AFTER ROW 
			IF NOT ((l_arr_rec_carriercost[l_idx].country_code IS null) AND 
			(l_arr_rec_carriercost[l_idx].country_code IS null) AND 
			(l_arr_rec_carriercost[l_idx].country_code IS null)) THEN 

				IF l_arr_rec_carriercost[l_idx].country_code IS NULL THEN 
					NEXT FIELD country_code 
				END IF 
				IF l_arr_rec_carriercost[l_idx].freight_ind IS NULL THEN 
					NEXT FIELD freight_ind 
				END IF 
				IF l_arr_rec_carriercost[l_idx].freight_amt IS NULL THEN 
					NEXT FIELD freight_amt 
				END IF 

			END IF 
			#LET scrn = scr_line()
			#DISPLAY l_arr_rec_carriercost[l_idx].*
			#     TO sr_carriercost[scrn].*

			#      AFTER FIELD scroll_flag
			#         DISPLAY l_arr_rec_carriercost[l_idx].scroll_flag
			#              TO sr_carriercost[scrn].scroll_flag
			#
			#         IF fgl_lastkey() = fgl_keyval("down") THEN
			#            IF l_arr_rec_carriercost[l_idx+1].country_code IS NULL
			#            OR arr_curr() >= arr_count() THEN
			#               ERROR kandoomsg2("E",9001,"")         #9001 There no more rows...
			#               NEXT FIELD scroll_flag
			#            END IF
			#         END IF

		AFTER FIELD country_code 
			IF l_arr_rec_carriercost[l_idx].country_code IS NULL THEN 
				ERROR kandoomsg2("E",9095,"") 	#9095 country must be entered
				NEXT FIELD country_code 
			ELSE 
				SELECT country_text 
				INTO glob_rec_country.country_text 
				FROM country 
				WHERE country_code = l_arr_rec_carriercost[l_idx].country_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("E",9096,"") 		#9096 country NOT found - try window
					NEXT FIELD country_code 
				END IF 
			END IF 

			#removed on user-tester request (Anna)
			#AFTER FIELD state_code
			#   IF l_arr_rec_carriercost[l_idx].state_code IS NULL THEN
			#      ERROR kandoomsg2("E",9103,"")     #9103 State must be entered
			#      NEXT FIELD state_code
			#   END IF

		AFTER FIELD freight_ind 
			IF l_arr_rec_carriercost[l_idx].freight_ind < "1" 
			OR l_arr_rec_carriercost[l_idx].freight_ind > "9" 
			OR l_arr_rec_carriercost[l_idx].freight_ind IS NULL THEN 
				ERROR kandoomsg2("E",9120,"") #9120 Freight indicator must be entered
				NEXT FIELD freight_ind 
			END IF 

		AFTER FIELD freight_amt 
			IF l_arr_rec_carriercost[l_idx].freight_amt < 0 
			OR l_arr_rec_carriercost[l_idx].freight_amt IS NULL THEN 
				ERROR kandoomsg2("E",9102,"") 	#9102 Freight Amount must NOT be negative
				NEXT FIELD freight_amt 
			END IF 

			#      BEFORE INSERT
			#         IF arr_curr() < arr_count() THEN
			#            NEXT FIELD country_code
			#         ELSE
			#            IF l_idx > 1 THEN
			#               ERROR kandoomsg2("E",9001,"")		#               #9001There are no more rows in the direction you are going
			#            END IF
			#            NEXT FIELD scroll_flag
			#         END IF

			#      ON KEY (control-w)
			#         CALL kandoohelp("")


	END INPUT 
	-------------------------------

	IF NOT (int_flag OR quit_flag) THEN 
		# First delete the rows that were selected during the scan.
		IF l_nrof_carriercosts > 0 THEN 
			FOR l_idx = 1 TO l_nrof_carriercosts 
				DELETE FROM temp_carriercost 
				WHERE rowid = l_arr_rowid[l_idx] 
			END FOR 
		END IF 
		# THEN INSERT the rows that were entered during the session.
		IF arr_count() > 0 THEN 
			FOR l_idx = 1 TO arr_count() 
				IF l_arr_rec_carriercost[l_idx].country_code IS NOT NULL THEN 
					IF l_arr_rec_carriercost[l_idx].state_code IS NULL THEN 
						SELECT * FROM temp_carriercost 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND carrier_code = glob_rec_carrier.carrier_code 
						AND country_code = l_arr_rec_carriercost[l_idx].country_code 
						AND state_code IS NULL 
						AND freight_ind = l_arr_rec_carriercost[l_idx].freight_ind 
					ELSE 
						SELECT * FROM temp_carriercost 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND carrier_code = glob_rec_carrier.carrier_code 
						AND country_code = l_arr_rec_carriercost[l_idx].country_code 
						AND state_code = l_arr_rec_carriercost[l_idx].state_code 
						AND freight_ind = l_arr_rec_carriercost[l_idx].freight_ind 
					END IF 
					IF status = NOTFOUND THEN 
						INSERT INTO temp_carriercost 
						VALUES (glob_rec_kandoouser.cmpy_code,glob_rec_carrier.carrier_code, 
						l_arr_rec_carriercost[l_idx].state_code, 
						l_arr_rec_carriercost[l_idx].country_code, 
						l_arr_rec_carriercost[l_idx].freight_ind, 
						l_arr_rec_carriercost[l_idx].freight_amt) 
					END IF 
				END IF 
			END FOR 
		END IF 
	END IF 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN FALSE 
	ELSE 
		RETURN TRUE 
	END IF 
END FUNCTION 
#######################################################################
# END FUNCTION select_carriercost()
#######################################################################


#######################################################################
# FUNCTION carriercost_edit(p_carrier_code,p_country_code,p_state_code,p_freight_ind)
#
# EDIT & NEW
#######################################################################
FUNCTION carriercost_edit(p_carrier_code,p_country_code,p_state_code,p_freight_ind) 
	DEFINE p_carrier_code LIKE carriercost.carrier_code 
	DEFINE p_country_code LIKE carriercost.country_code 
	DEFINE p_state_code LIKE carriercost.state_code 
	DEFINE p_freight_ind LIKE carriercost.freight_ind 

	DEFINE l_mode CHAR 
	DEFINE l_rec_carriercost_edit OF t_rec_carriercost_no_ccode_cmpy 
	DEFINE l_rec_carriercost RECORD LIKE carriercost.* 
	DEFINE l_retstatus SMALLINT 

	#IF p_carrier_code IS NULL OR p_country_code IS NULL OR p_freight_ind IS NULL THEN
	#	ERROR "ERROR, Carrier Code is empty"
	#	RETURN NULL
	#END IF
	#	DISPLAY db_carriercost_pk_exists(UI_OFF,NULL,p_carrier_code,p_country_code,p_state_code,p_freight_ind)
	IF db_carriercost_pk_exists(ui_off,null,p_carrier_code,p_country_code,p_state_code,p_freight_ind) > 0 THEN 
		#IF recird exists, EDIT Mode
		LET l_mode = MODE_CLASSIC1_UPDATE 
		CALL db_carriercost_get_rec(p_carrier_code,p_country_code,p_state_code,p_freight_ind) RETURNING l_rec_carriercost.* 
		LET l_rec_carriercost_edit.country_code = l_rec_carriercost.country_code 
		LET l_rec_carriercost_edit.state_code = l_rec_carriercost.state_code 
		LET l_rec_carriercost_edit.freight_ind = l_rec_carriercost.freight_ind 
		LET l_rec_carriercost_edit.freight_amt = l_rec_carriercost.freight_amt 

		ELSE # RECORD NOT found.. add new RECORD 
			#New Record
			LET l_mode = MODE_CLASSIC1_INSERT 
		END IF 

		OPEN WINDOW E143 with FORM ("E143") 
		 CALL windecoration_e("E143") 

		INPUT BY NAME l_rec_carriercost_edit.* WITHOUT DEFAULTS 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","EZ4","carriercost_add") 
				CALL comboList_state("state_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,l_rec_carriercost_edit.country_code,COMBO_NULL_SPACE) 
				CALL ui.interface.refresh() 
				
			ON ACTION "LOOKUP" infield (country_code) 
				LET l_rec_carriercost.country_code = show_country() 
				IF l_rec_carriercost.country_code IS NULL THEN 
					NEXT FIELD carriercost.country_code 
				END IF 
				CALL comboList_state("state_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,l_rec_carriercost_edit.country_code,COMBO_NULL_SPACE) 

			BEFORE FIELD country_code 
				CALL comboList_state("state_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,l_rec_carriercost_edit.country_code,COMBO_NULL_SPACE) 

			AFTER FIELD country_code 
				CALL comboList_state("state_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,l_rec_carriercost_edit.country_code,COMBO_NULL_SPACE) 

			BEFORE FIELD state_code 
				CALL comboList_state("state_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,l_rec_carriercost_edit.country_code,COMBO_NULL_SPACE) 

			AFTER INPUT 
				IF int_flag THEN 
					EXIT INPUT 
				END IF 

				IF l_rec_carriercost_edit.country_code IS NULL THEN 
					ERROR kandoomsg2("E",9095,"") 	#9095 country must be entered
					NEXT FIELD country_code 
				ELSE 
					IF db_country_pk_exists(ui_off,null,l_rec_carriercost_edit.country_code) < 1 THEN 
						ERROR "Country Does not exist" 
						NEXT FIELD country_code 
					END IF 
				END IF 

				#			IF l_rec_carriercost.state_code IS NOT NULL THEN
				#         IF pa_carriercost[l_idx].state_code IS NULL THEN
				#            ERROR kandoomsg2("E",9103,"")          #9103 State must be entered
				#            NEXT FIELD state_code
				#         END IF

				IF l_rec_carriercost_edit.freight_ind < "1" 
				OR l_rec_carriercost_edit.freight_ind > "9" 
				OR l_rec_carriercost_edit.freight_ind IS NULL THEN 
					ERROR kandoomsg2("E",9120,"") 		#9120 Freight indicator must be entered
					NEXT FIELD freight_ind 
				END IF 

				IF l_rec_carriercost_edit.freight_amt <= 0 THEN 
					ERROR "You need to specify the freight cost" 
					NEXT FIELD freight_amt 
				END IF 

				IF l_mode = MODE_CLASSIC1_INSERT THEN #only FOR new carriercost records - CHECK FOR pk existence 
					IF db_carriercost_pk_exists(ui_on,MODE_CLASSIC1_INSERT,p_carrier_code,l_rec_carriercost_edit.country_code,l_rec_carriercost_edit.state_code,l_rec_carriercost_edit.freight_ind) THEN 
						ERROR "This carrier cost record already exists" 
						CONTINUE INPUT 
					END IF 
				END IF 

				LET l_rec_carriercost.carrier_code = p_carrier_code 
				LET l_rec_carriercost.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_rec_carriercost.country_code = l_rec_carriercost_edit.country_code 
				LET l_rec_carriercost.state_code = l_rec_carriercost_edit.state_code 
				LET l_rec_carriercost.freight_ind = l_rec_carriercost_edit.freight_ind 
				LET l_rec_carriercost.freight_amt = l_rec_carriercost_edit.freight_amt 

		END INPUT 

		IF int_flag THEN 
			LET int_flag = FALSE 
			CLOSE WINDOW E143 
			RETURN NULL 
		END IF 

		CASE l_mode 
			WHEN MODE_CLASSIC1_UPDATE #edit 
				LET l_retstatus = db_carriercost_update(l_rec_carriercost.*) 

			WHEN MODE_CLASSIC1_INSERT #new 
				LET l_retstatus = db_carriercost_insert(l_rec_carriercost.*) 
			OTHERWISE 
				ERROR "Invalid usage mode" 
		END CASE 

		CLOSE WINDOW E143 

		RETURN l_retstatus 
END FUNCTION 
#######################################################################
# END FUNCTION carriercost_edit(p_carrier_code,p_country_code,p_state_code,p_freight_ind)
#######################################################################
