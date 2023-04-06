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
GLOBALS "../eo/E_EO_GLOBALS.4gl"
GLOBALS "../eo/E6_GROUP_GLOBALS.4gl"
GLOBALS "../eo/E61_GLOBALS.4gl"
###########################################################################
# FUNCTION E61_main()
#
# E61 - Maintainence program FOR Sales Order Special Offers
###########################################################################
FUNCTION E61_main() 
	DEFER QUIT 
	DEFER INTERRUPT 
	
	CALL setModuleId("E61") -- albo 

	LET yes_flag = xlate_from("Y") 
	LET no_flag = xlate_from("N") 

	CREATE temp TABLE t_offerprod( type_ind char(1), 
	maingrp_code char(3), 
	prodgrp_code char(3), 
	part_code char(15), 
	reqd_amt decimal(10,2), 
	reqd_qty decimal(8,2)) with no LOG
	 
	CREATE temp TABLE t_offerauto( part_code char(15), 
	bonus_qty decimal(8,2), 
	sold_qty decimal(8,2), 
	price_amt decimal(10,2), 
	disc_per decimal(5,2), 
	disc_allow_flag char(1), 
	status_ind char(1)) with no LOG
	 
	CREATE temp TABLE t_proddisc( maingrp_code char(3), 
	prodgrp_code char(3), 
	part_code char(15), 
	reqd_amt decimal(10,2), 
	reqd_qty decimal(8,2), 
	disc_per decimal(5,2), 
	unit_sale_amt decimal(16,2), 
	per_amt_ind char(1)) with no LOG 

	OPEN WINDOW E121 with FORM "E121" 
	 CALL windecoration_e("E121") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

--	WHILE db_offersale_get_datasource() 
	CALL scan_offersale() 
--	END WHILE 

	CLOSE WINDOW E121 
END FUNCTION


################################################################################
# FUNCTION db_offersale_get_datasource()
#
#
################################################################################
FUNCTION db_offersale_get_datasource(p_filter)
	DEFINE p_filter BOOLEAN 
	DEFINE l_where_text STRING 
	DEFINE l_query_text STRING 
	DEFINE l_arr_rec_offersale DYNAMIC ARRAY OF RECORD 
		offer_code LIKE offersale.offer_code, 
		desc_text LIKE offersale.desc_text, 
		start_date LIKE offersale.start_date, 
		end_date LIKE offersale.end_date, 
		prodline_disc_flag LIKE offersale.prodline_disc_flag 
	END RECORD
	DEFINE l_idx SMALLINT

	IF p_filter THEN
		CLEAR FORM 
	
		MESSAGE kandoomsg2("E",1001,"")	#MESSAGE " Enter Selection Criteria - ESC TO Continue "
		CONSTRUCT BY NAME l_where_text ON 
			offer_code, 
			desc_text, 
			start_date, 
			end_date, 
			prodline_disc_flag 
	
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","E61","construct-offersale") 
	
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
	
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
	
		END CONSTRUCT 
	
		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE
			LET l_where_text = " 1=1 " 
		END IF		 
	ELSE 
		LET l_where_text = " 1=1 "
	END IF
		
	MESSAGE kandoomsg2("E",1002,"") 	#MESSAGE " Searching database - please wait "
	LET l_query_text = 
		"SELECT * ", 
		"FROM offersale ", 
		"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY cmpy_code,", 
		"offer_code" 
	PREPARE s_offersale FROM l_query_text 
	DECLARE c_offersale cursor FOR s_offersale 

	LET l_idx = 0 
	FOREACH c_offersale INTO glob_rec_offersale.* 
		LET l_idx = l_idx + 1 
		#LET l_arr_rec_offersale[l_idx].scroll_flag = NULL
		LET l_arr_rec_offersale[l_idx].offer_code = glob_rec_offersale.offer_code 
		LET l_arr_rec_offersale[l_idx].desc_text = glob_rec_offersale.desc_text 
		LET l_arr_rec_offersale[l_idx].start_date = glob_rec_offersale.start_date 
		LET l_arr_rec_offersale[l_idx].end_date = glob_rec_offersale.end_date 
		LET l_arr_rec_offersale[l_idx].prodline_disc_flag = xlate_from(glob_rec_offersale.prodline_disc_flag) 

    IF l_idx = glob_rec_settings.maxListArraySize THEN
            MESSAGE kandoomsg2("U",6100,l_idx)
            EXIT FOREACH
    END IF
                
	END FOREACH 

	MESSAGE kandoomsg2("U",9113,l_idx) 	#9113 l_idx records selected

	RETURN l_arr_rec_offersale 
END FUNCTION 
################################################################################
# END FUNCTION db_offersale_get_datasource()
################################################################################


################################################################################
# FUNCTION scan_offersale()
#
#
################################################################################
FUNCTION scan_offersale() 
	DEFINE l_offer_code LIKE offersale.offer_code 
	DEFINE l_scroll_flag char(1) 
	DEFINE l_arr_rec_offersale DYNAMIC ARRAY OF RECORD 
		offer_code LIKE offersale.offer_code, 
		desc_text LIKE offersale.desc_text, 
		start_date LIKE offersale.start_date, 
		end_date LIKE offersale.end_date, 
		prodline_disc_flag LIKE offersale.prodline_disc_flag 
	END RECORD
	DEFINE l_err_continue char(1)
	DEFINE l_err_message char(60)
	DEFINE i SMALLINT 
	DEFINE j SMALLINT
	DEFINE l_del_cnt SMALLINT
	DEFINE l_idx SMALLINT

--	IF l_idx = 0 THEN 
--		LET l_idx = 1 
--		INITIALIZE l_arr_rec_offersale[l_idx].start_date TO NULL 
--		INITIALIZE l_arr_rec_offersale[l_idx].end_date TO NULL 
--	END IF 
--
--	OPTIONS DELETE KEY f36 

	CALL db_offersale_get_datasource(FALSE) RETURNING l_arr_rec_offersale

	MESSAGE kandoomsg2("E",1003,"") #MESSAGE" F1 TO Add - F2 TO Delete - RETURN TO Edit "

	DISPLAY ARRAY l_arr_rec_offersale TO sr_offersale.* ATTRIBUTE(UNBUFFERED) 
	#INPUT ARRAY l_arr_rec_offersale WITHOUT DEFAULTS FROM sr_offersale.* ATTRIBUTE(UNBUFFERED)
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","E61","inp-arr-l_arr_rec_offersale")
			CALL dialog.setActionHidden("ACCEPT",TRUE) 
			CALL dialog.setActionHidden("EDIT",NOT l_arr_rec_offersale.getSize())
			CALL dialog.setActionHidden("DELETE",NOT l_arr_rec_offersale.getSize())

		BEFORE ROW 
			LET l_idx = arr_curr() 
			
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
			
		ON ACTION "FILTER"
			CALL l_arr_rec_offersale.clear()
			CALL db_offersale_get_datasource(TRUE) RETURNING l_arr_rec_offersale
			CALL dialog.setActionHidden("ACCEPT",TRUE) 
			CALL dialog.setActionHidden("EDIT",NOT l_arr_rec_offersale.getSize())
			CALL dialog.setActionHidden("DELETE",NOT l_arr_rec_offersale.getSize())

		ON ACTION "REFRESH"
			 CALL windecoration_e("E121")
			CALL l_arr_rec_offersale.clear()
			CALL db_offersale_get_datasource(TRUE) RETURNING l_arr_rec_offersale
			CALL dialog.setActionHidden("ACCEPT",TRUE) 
			CALL dialog.setActionHidden("EDIT",NOT l_arr_rec_offersale.getSize())
			CALL dialog.setActionHidden("DELETE",NOT l_arr_rec_offersale.getSize())


			#ON ACTION ("Edit","DoubleClick")
			#	NEXT FIELD offer_code

			#BEFORE FIELD scroll_flag
			#   LET l_idx = arr_curr()
			#   #LET scrn = scr_line()
			#   LET l_scroll_flag = l_arr_rec_offersale[l_idx].scroll_flag
			#   #DISPLAY l_arr_rec_offersale[l_idx].*
			#   #     TO sr_offersale[scrn].*

			#AFTER FIELD scroll_flag
			#   LET l_arr_rec_offersale[l_idx].scroll_flag = l_scroll_flag
			#  # DISPLAY l_arr_rec_offersale[l_idx].scroll_flag
			#   #     TO sr_offersale[scrn].scroll_flag
			#
			#   IF fgl_lastkey() = fgl_keyval("down") THEN
			#      IF arr_curr() = arr_count() THEN
			#         ERROR kandoomsg2("E",9001,"")
			#         #9001 There are no more rows in the direction ...
			#         NEXT FIELD scroll_flag
			#      ELSE
			#         IF l_arr_rec_offersale[l_idx+1].offer_code IS NULL THEN
			#            ERROR kandoomsg2("E",9001,"")
			#            #9001 There are no more rows in the direction ...
			#            NEXT FIELD scroll_flag
			#         END IF
			#      END IF
			#   END IF

		ON ACTION ("EDIT","DoubleClick")
			IF (l_idx > 0) AND (l_idx <= l_arr_rec_offersale.getSize()) THEN
				#BEFORE FIELD offer_code  --EDIT ??? next field offer_code
				IF l_arr_rec_offersale[l_idx].offer_code IS NOT NULL THEN 
				
					CALL process_offer("EDIT",l_arr_rec_offersale[l_idx].offer_code)	
					RETURNING l_offer_code
					 
					SELECT 
						desc_text, 
						start_date, 
						end_date, 
						prodline_disc_flag 
					INTO 
						l_arr_rec_offersale[l_idx].desc_text, 
						l_arr_rec_offersale[l_idx].start_date, 
						l_arr_rec_offersale[l_idx].end_date, 
						l_arr_rec_offersale[l_idx].prodline_disc_flag 
					FROM offersale 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND offer_code = l_arr_rec_offersale[l_idx].offer_code 
				END IF 
				#  NEXT FIELD scroll_flag
			END IF
			
		ON ACTION "ADD" 
			#BEFORE INSERT
			#IF arr_curr() < arr_count() THEN
			# CALL process_offer("ADD",l_arr_rec_offersale[l_arr_rec_offersale.getlength() + 1].offer_code)
			CALL process_offer("ADD",NULL)	RETURNING l_offer_code
			
			IF l_offer_code IS NOT NULL THEN
				SELECT 
					"", 
					offer_code, 
					desc_text, 
					start_date, 
					end_date, 
					prodline_disc_flag 
				INTO l_arr_rec_offersale[l_idx+1].* #?kept crashing with "0" index
				FROM offersale 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND offer_code = l_offer_code 
				#IF STATUS = NOTFOUND THEN
				#   FOR l_idx = arr_curr() TO arr_count()
				#      LET l_arr_rec_offersale[l_idx].* = l_arr_rec_offersale[l_idx+1].*
				#  IF scrn <= 13 THEN
				#     IF l_arr_rec_offersale[l_idx].offer_code IS NULL THEN
				#        LET l_arr_rec_offersale[l_idx].start_date = ""
				#        LET l_arr_rec_offersale[l_idx].end_date = ""
				#     END IF
				#     DISPLAY l_arr_rec_offersale[l_idx].* TO sr_offersale[scrn].*
				#
				#     LET scrn = scrn + 1
				#  END IF
				#   END FOR
				#   INITIALIZE l_arr_rec_offersale[l_idx].* TO NULL
				#END IF
				#ELSE
				#   IF l_idx > 1 THEN
				#      ERROR kandoomsg2("E",9001,"")    # There are no more rows in the direction you are going "
				#   END IF
				#END IF
				#NEXT FIELD scroll_flag

				CALL dialog.setActionHidden("EDIT",NOT l_arr_rec_offersale.getSize())
				CALL dialog.setActionHidden("DELETE",NOT l_arr_rec_offersale.getSize())

			END IF
			
		ON ACTION "DELETE" 
			IF (l_idx > 0) AND (l_idx <= l_arr_rec_offersale.getSize()) THEN
				LET l_del_cnt = 1 
				IF kandoomsg("E",8000,l_del_cnt) = "Y" THEN ### Confirm TO Delete ",l_del_cnt," Sales Offers(s)? (Y/N)" 
					GOTO bypass 
					LABEL recovery: 
					LET l_err_continue = error_recover(l_err_message, status) 
	
					IF l_err_continue != "Y" THEN 
						EXIT PROGRAM 
					END IF 
	
					LABEL bypass: 
					WHENEVER ERROR GOTO recovery 
	
					BEGIN WORK 
						LET l_err_message = "E61 - Deleting Special Offers " 
						#FOR l_idx = 1 TO arr_count()
						#   IF l_arr_rec_offersale[l_idx].scroll_flag = "*" THEN
						DELETE FROM offerprod 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND offer_code = l_arr_rec_offersale[l_idx].offer_code 
	
						DELETE FROM offerauto 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND offer_code = l_arr_rec_offersale[l_idx].offer_code 
	
						DELETE FROM proddisc 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND key_num = l_arr_rec_offersale[l_idx].offer_code 
						AND type_ind = "2" 
	
						DELETE FROM offersale 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND offer_code = l_arr_rec_offersale[l_idx].offer_code 
						#      END IF
						#   END FOR
	
					COMMIT WORK 
					WHENEVER ERROR stop 
				END IF 
	
				CALL dialog.setActionHidden("EDIT",NOT l_arr_rec_offersale.getSize())
				CALL dialog.setActionHidden("DELETE",NOT l_arr_rec_offersale.getSize())
			END IF

			#ON KEY(F2)	--DELETE / SET delete marker
			#   IF l_arr_rec_offersale[l_idx].offer_code IS NOT NULL THEN
			#      IF l_arr_rec_offersale[l_idx].scroll_flag IS NULL THEN
			#         IF offer_delete(l_arr_rec_offersale[l_idx].offer_code) THEN
			#            LET l_arr_rec_offersale[l_idx].scroll_flag = "*"
			#            LET l_del_cnt = l_del_cnt + 1
			#         END IF
			#      ELSE
			#         LET l_arr_rec_offersale[l_idx].scroll_flag = NULL
			#         LET l_del_cnt = l_del_cnt - 1
			#      END IF
			#   END IF
			#   NEXT FIELD scroll_flag

			#AFTER ROW
			#   DISPLAY l_arr_rec_offersale[l_idx].*
			#        TO sr_offersale[scrn].*

	END DISPLAY 
	---------------------------------------------------------

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
	ELSE 
		  {    IF l_del_cnt != 0 THEN
		         IF kandoomsg("E",8000,l_del_cnt) = "Y" THEN # Confirm TO Delete ",l_del_cnt," Sales Offers(s)? (Y/N)"
		            GOTO bypass
		            label recovery:
		            LET l_err_continue = error_recover(l_err_message, STATUS)
		            IF l_err_continue != "Y" THEN
		               EXIT PROGRAM
		            END IF
		            label bypass:
		            WHENEVER ERROR GOTO recovery

		            BEGIN WORK
		               LET l_err_message = "E61 - Deleting Special Offers "
		               FOR l_idx = 1 TO arr_count()
		                  IF l_arr_rec_offersale[l_idx].scroll_flag = "*" THEN
		                     DELETE FROM offerprod
		                        WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
		                          AND offer_code = l_arr_rec_offersale[l_idx].offer_code
		                     DELETE FROM offerauto
		                        WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
		                          AND offer_code = l_arr_rec_offersale[l_idx].offer_code
		                     DELETE FROM proddisc
		                        WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
		                          AND key_num = l_arr_rec_offersale[l_idx].offer_code
		                          AND type_ind = "2"
		                     DELETE FROM offersale
		                        WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
		                          AND offer_code = l_arr_rec_offersale[l_idx].offer_code
		                  END IF
		               END FOR

		            COMMIT WORK
		            WHENEVER ERROR STOP
		         END IF
		      END IF

		}
	END IF 

END FUNCTION 


################################################################################
# FUNCTION init_offer(p_mode,p_offer_code)
#
#
################################################################################
FUNCTION init_offer(p_mode,p_offer_code) 
	DEFINE p_mode char(4) 
	DEFINE p_offer_code LIKE offersale.offer_code
	DEFINE l_rec_offerprod RECORD LIKE offerprod.* 
	DEFINE l_rec_offerauto RECORD LIKE offerauto.* 
	DEFINE l_rec_proddisc RECORD LIKE proddisc.* 

	INITIALIZE glob_rec_offersale.* TO NULL 
	DELETE FROM t_offerprod 
	DELETE FROM t_proddisc 
	DELETE FROM t_offerauto 

	IF p_mode = "EDIT" THEN 
		SELECT * INTO glob_rec_offersale.* 
		FROM offersale 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND offer_code = p_offer_code 
	ELSE 
		IF p_offer_code IS NULL THEN 
			RETURN 
		END IF 
		IF kandoomsg("E",8002,p_offer_code) = "N" THEN 
			## Image new offer FROM existing
			RETURN 
		END IF 
		SELECT * INTO glob_rec_offersale.* 
		FROM offersale 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND offer_code = p_offer_code 
		LET glob_rec_offersale.offer_code = NULL 
	END IF 

	DECLARE c1_offerprod cursor FOR 
	SELECT * FROM offerprod 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND offer_code = p_offer_code 
	FOREACH c1_offerprod INTO l_rec_offerprod.* 
		INSERT INTO t_offerprod VALUES (
			l_rec_offerprod.type_ind, 
			l_rec_offerprod.maingrp_code, 
			l_rec_offerprod.prodgrp_code, 
			l_rec_offerprod.part_code, 
			l_rec_offerprod.reqd_amt, 
			l_rec_offerprod.reqd_qty) 
	END FOREACH 

	DECLARE c1_proddisc cursor FOR 
	SELECT * FROM proddisc 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_num = p_offer_code 
	AND type_ind = "2" 
	FOREACH c1_proddisc INTO l_rec_proddisc.* 
		INSERT INTO t_proddisc VALUES (
			l_rec_proddisc.maingrp_code, 
			l_rec_proddisc.prodgrp_code, 
			l_rec_proddisc.part_code, 
			l_rec_proddisc.reqd_amt, 
			l_rec_proddisc.reqd_qty, 
			l_rec_proddisc.disc_per, 
			l_rec_proddisc.unit_sale_amt, 
			l_rec_proddisc.per_amt_ind) 
	END FOREACH 

	DECLARE c1_offerauto cursor FOR 
	SELECT * FROM offerauto 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND offer_code = p_offer_code 
	FOREACH c1_offerauto INTO l_rec_offerauto.* 
		INSERT INTO t_offerauto VALUES (
			l_rec_offerauto.part_code, 
			l_rec_offerauto.bonus_qty, 
			l_rec_offerauto.sold_qty, 
			l_rec_offerauto.price_amt, 
			l_rec_offerauto.disc_per, 
			l_rec_offerauto.disc_allow_flag, 
			l_rec_offerauto.status_ind) 
	END FOREACH 
END FUNCTION 


################################################################################
# FUNCTION process_offer(p_mode,p_offer_code)
#
#
################################################################################
FUNCTION process_offer(p_mode,p_offer_code) 
	DEFINE p_mode char(4) 
	DEFINE p_offer_code LIKE offersale.offer_code 
	DEFINE l_disc_type char(3) 

	OPEN WINDOW E122 with FORM "E122" 
	 CALL windecoration_e("E122") 

	CALL init_offer(p_mode,p_offer_code) 

	LET p_offer_code = NULL 

	WHILE edit_header(glob_rec_offersale.offer_code) 

		MENU " Special offers" 
			BEFORE MENU 
				CALL publish_toolbar("kandoo","E61","menu-special_offers") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON ACTION "Save" 		#COMMAND KEY(escape,"S")"Save" " Save special offer "
				CALL update_database() RETURNING p_offer_code 
				EXIT MENU 

			ON ACTION "Products" 	#COMMAND "Products" " Include product line discount in offer"
				OPEN WINDOW E123 with FORM "E123" 
				 CALL windecoration_e("E123") 

				CALL lineitem_entry("1") 
				CLOSE WINDOW E123 

			ON ACTION "Bonus" 			#COMMAND "Bonus"         " Include bonus product items in the special offer"
				OPEN WINDOW E124 with FORM "E124" 
				 CALL windecoration_e("E124") 

				CALL lineitem_entry("2") 
				CLOSE WINDOW E124 


			ON ACTION "Lines" 		#COMMAND "Lines"          " Include automatic product insertion in the special offer"
				OPEN WINDOW E125 with FORM "E125" 
				 CALL windecoration_e("E125") 

				IF glob_rec_offersale.checktype_ind = "1" THEN 
					LET l_disc_type = "Qty" 
				ELSE 
					LET l_disc_type = "Amt" 
				END IF 

				DISPLAY l_disc_type TO disc_type 

				-------------------------------------------------

				MENU "Line insertion" 
					BEFORE MENU 
						CALL publish_toolbar("kandoo","E61","menu-line_insertion") 

					ON ACTION "WEB-HELP" 
						CALL onlinehelp(getmoduleid(),null) 

					ON ACTION "actToolbarManager" 
						CALL setuptoolbar() 


					ON ACTION "Auto" 				#COMMAND "Auto "                  " Automatically Add Lines AND Edit"
						IF auto_proddisc() THEN 
							CALL proddisc_entry() 
						END IF 

					ON ACTION "Manual" 				#COMMAND "Manual "                  " Manually Add Lines AND Edit"
						CALL proddisc_entry() 

					ON ACTION "Exit" 				#COMMAND KEY(INTERRUPT,"E")"Exit" " RETURN TO Menu"
						LET int_flag = FALSE 
						LET quit_flag = FALSE 
						EXIT MENU 

				END MENU 
				------------------------------------------
				CLOSE WINDOW E125 

			ON ACTION "Auto" 
				#COMMAND "Auto"            " Include automatic product insertion in offer"

				OPEN WINDOW e126 with FORM "E126" 
				 CALL windecoration_e("E126") 
				CALL disp_autoprod() 

				-----------------------------------------
				MENU "Auto product line insertion" 
					BEFORE MENU 
						CALL publish_toolbar("kandoo","E61","menu-auto_prod_line") 

					ON ACTION "WEB-HELP" 
						CALL onlinehelp(getmoduleid(),null) 

					ON ACTION "actToolbarManager" 
						CALL setuptoolbar() 


					ON ACTION "Product selection" 
						#COMMAND "Product Selection"               " SELECT products FROM main & product groups"
						CALL scan_groups() 
						CALL disp_autoprod() 

					ON ACTION "Line edit" 
						#COMMAND "Line Edit"                  " Scan through auto inserted products"
						CALL scan_prods() 
						CALL disp_autoprod() 

					ON ACTION "Exit" 
						#COMMAND KEY(INTERRUPT,"E")"Exit" " RETURN TO Menu"
						LET int_flag = FALSE 
						LET quit_flag = FALSE 
						EXIT MENU 


					COMMAND KEY (control-w) 
						CALL kandoohelp("") 

				END MENU 

				-----------------------------------------

				CLOSE WINDOW e126 


			ON ACTION "Exit"		#COMMAND KEY("E",INTERRUPT)"Exit" " RETURN TO editting offer"
				LET quit_flag = TRUE 
				EXIT MENU 

		END MENU 

		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
		ELSE 
			EXIT WHILE 
		END IF 

	END WHILE 

	OPTIONS DELETE KEY f36, 
	INSERT KEY f1 

	CLOSE WINDOW E122 

	RETURN p_offer_code 
END FUNCTION 


################################################################################
# FUNCTION offer_delete(p_offer_code)
#
#
################################################################################
FUNCTION offer_delete(p_offer_code) 
	DEFINE p_offer_code LIKE offersale.offer_code 

	SELECT unique 1 FROM orderhead, 
	orderdetl 
	WHERE orderhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND orderdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND orderhead.order_num = orderdetl.order_num 
	AND orderhead.status_ind != "C" 
	AND orderdetl.offer_code = p_offer_code 

	IF status = NOTFOUND THEN 
		RETURN TRUE 
	ELSE 
		ERROR kandoomsg2("E",7069,p_offer_code) #7069 Special offer in use , no deletion
		RETURN FALSE 
	END IF 

END FUNCTION 
