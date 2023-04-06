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

###########################################################################
# FUNCTION pinvwind(p_cmpy,p_part_code)
#
# \brief module - pinvwind.4gl
#
# Purpose - Displays OPTIONS FOR user TO DISPLAY statistical details
#           WHEN doing a product inquiry.
###########################################################################
FUNCTION pinvwind(p_cmpy,p_part_code) 
	DEFINE p_cmpy LIKE product.cmpy_code
	DEFINE p_part_code LIKE product.part_code 

	CALL pinqwind(p_cmpy,p_part_code,TRUE) 
END FUNCTION 

###########################################################################
# FUNCTION pinqwind(p_cmpy,p_part_code,p_xfer_ind)
#
# Inquiry Window - called FROM pinvwind (above) displaying Stock Xfer on menu
#                - called FROM I12.4gl without displaying Stock Xfer on menu
###########################################################################
FUNCTION pinqwind(p_cmpy,p_part_code,p_xfer_ind) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_part_code LIKE product.part_code 
	DEFINE p_xfer_ind SMALLINT 
   DEFINE l_rec_company RECORD LIKE company.*
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_inparms RECORD LIKE inparms.* 
	DEFINE l_arr_rec_prodmenu DYNAMIC ARRAY OF RECORD 
			scroll_flag CHAR(1), 
			option_num CHAR(1), 
			option_text CHAR(30) 
		END RECORD 
	DEFINE l_cust_code LIKE customer.cust_code 
	DEFINE l_idx SMALLINT --huho scrn 
	DEFINE i SMALLINT --huho scrn		 
	DEFINE l_arg1 STRING #used for the first argument when running programs (RUN) CALL run_prog("I13",l_arg1,"","","")
	DEFINE l_menu_option CHAR
	
		SELECT * INTO l_rec_company.* FROM company 
		WHERE cmpy_code = p_cmpy 

		CALL db_inparms_get_rec(UI_OFF,"1") RETURNING l_rec_inparms.*

		SELECT * INTO l_rec_product.* 
		FROM product 
		WHERE cmpy_code = p_cmpy 
		AND part_code = p_part_code 

		IF status = 0 THEN 
			# SELECT all matching part_codes INTO temp table TO reduce the number
			# of prodstatus table searches in ORDER TO determine whether the option
			# IS TO be displayed.
--CALL fgl_winmessage("Create temp table t_prodstatus","Create temp table t_prodstatus","ERROR") 
			SELECT * FROM prodstatus 
			WHERE cmpy_code = p_cmpy 
			AND part_code = p_part_code 
			INTO temp t_prodstatus with no LOG 

			FOR i = 1 TO 25 
				CASE i 
					WHEN "1" ## general details 
						LET l_idx = l_idx + 1 
						LET l_arr_rec_prodmenu[l_idx].option_num = "1" 
						LET l_arr_rec_prodmenu[l_idx].option_text = kandooword("pinqwind","1") 

					WHEN "2" ## purchasing info 
						LET l_idx = l_idx + 1 
						LET l_arr_rec_prodmenu[l_idx].option_num = "2" 
						LET l_arr_rec_prodmenu[l_idx].option_text = kandooword("pinqwind","2") 

					WHEN "3" ## pricing info 
						SELECT unique 1 FROM t_prodstatus 
						IF status = 0 THEN 
							LET l_idx = l_idx + 1 
							LET l_arr_rec_prodmenu[l_idx].option_num = "3" 
							LET l_arr_rec_prodmenu[l_idx].option_text = kandooword("pinqwind","3") 
						END IF 

					WHEN "4" ## stock status 
						SELECT unique 1 FROM t_prodstatus 
						IF status = 0 THEN 
							LET l_idx = l_idx + 1 
							LET l_arr_rec_prodmenu[l_idx].option_num = "4" 
							LET l_arr_rec_prodmenu[l_idx].option_text = kandooword("pinqwind","4") 
						END IF 

					WHEN "5" ## product ledger 
						SELECT unique 1 FROM t_prodstatus 
						WHERE seq_num > 0 
						IF status = 0 THEN 
							LET l_idx = l_idx + 1 
							LET l_arr_rec_prodmenu[l_idx].option_num = "5" 
							LET l_arr_rec_prodmenu[l_idx].option_text = kandooword("pinqwind","5") 
						END IF 

					WHEN "6" ## product notes 
						SELECT unique 1 FROM prodnote 
						WHERE cmpy_code = p_cmpy 
						AND part_code = p_part_code 
						IF status = 0 THEN 
							LET l_idx = l_idx + 1 
							LET l_arr_rec_prodmenu[l_idx].option_num = "6" 
							LET l_arr_rec_prodmenu[l_idx].option_text = kandooword("pinqwind","6") 
						END IF 

					WHEN "7" ## stocking info 
						LET l_idx = l_idx + 1 
						LET l_arr_rec_prodmenu[l_idx].option_num = "7" 
						LET l_arr_rec_prodmenu[l_idx].option_text = kandooword("pinqwind","7") 

					WHEN "8" ## product STATISTICS 
						SELECT unique 1 FROM statprod 
						WHERE cmpy_code = p_cmpy 
						AND part_code = p_part_code 
						IF status = 0 THEN 
							LET l_idx = l_idx + 1 
							LET l_arr_rec_prodmenu[l_idx].option_num = "8" 
							LET l_arr_rec_prodmenu[l_idx].option_text = kandooword("pinqwind","8") 
						END IF 

					WHEN "9" ## reporting codes 
						IF l_rec_inparms.ref1_text IS NOT NULL 
						OR l_rec_inparms.ref2_text IS NOT NULL 
						OR l_rec_inparms.ref3_text IS NOT NULL 
						OR l_rec_inparms.ref4_text IS NOT NULL 
						OR l_rec_inparms.ref5_text IS NOT NULL 
						OR l_rec_inparms.ref6_text IS NOT NULL 
						OR l_rec_inparms.ref7_text IS NOT NULL 
						OR l_rec_inparms.ref8_text IS NOT NULL THEN 
							LET l_idx = l_idx + 1 
							LET l_arr_rec_prodmenu[l_idx].option_num = "9" 
							LET l_arr_rec_prodmenu[l_idx].option_text = kandooword("pinqwind","9") 
						END IF 

					WHEN "10" ## back orders 
						SELECT unique 1 FROM t_prodstatus 
						WHERE back_qty > 0 
						IF status = 0 THEN 
							LET l_idx = l_idx + 1 
							LET l_arr_rec_prodmenu[l_idx].option_num = "A" 
							LET l_arr_rec_prodmenu[l_idx].option_text = kandooword("pinqwind","A") 
						ELSE 
							SELECT unique 1 FROM t_prodstatus 
							WHERE reserved_qty > 0 
							IF status = 0 THEN 
								LET l_idx = l_idx + 1 
								LET l_arr_rec_prodmenu[l_idx].option_num = "A" 
								LET l_arr_rec_prodmenu[l_idx].option_text = kandooword("pinqwind","A") 
							END IF 
						END IF 

					WHEN "11" ## purchase orders 
						SELECT unique 1 FROM t_prodstatus 
						WHERE onord_qty > 0 
						IF status = 0 THEN 
							LET l_idx = l_idx + 1 
							LET l_arr_rec_prodmenu[l_idx].option_num = "B" 
							LET l_arr_rec_prodmenu[l_idx].option_text = kandooword("pinqwind","B") 
						END IF 

					WHEN "12" ## stock transfer 
						IF p_xfer_ind THEN 
							LET l_idx = l_idx + 1 
							LET l_arr_rec_prodmenu[l_idx].option_num = "C" 
							LET l_arr_rec_prodmenu[l_idx].option_text = kandooword("pinqwind","C") 
						END IF 

					WHEN "13" ## production schedules 
						SELECT unique 1 FROM inproduction 
						WHERE cmpy_code = p_cmpy 
						AND part_code = p_part_code 
						IF status = 0 THEN 
							LET l_idx = l_idx + 1 
							LET l_arr_rec_prodmenu[l_idx].option_num = "D" 
							LET l_arr_rec_prodmenu[l_idx].option_text = kandooword("pinqwind","D") 
						END IF 

					WHEN "14" ## supersession 
						LET l_idx = l_idx + 1 
						LET l_arr_rec_prodmenu[l_idx].option_num = "E" 
						LET l_arr_rec_prodmenu[l_idx].option_text = kandooword("pinqwind","E") 

					WHEN "15" ## alternates 
						LET l_idx = l_idx + 1 
						LET l_arr_rec_prodmenu[l_idx].option_num = "F" 
						LET l_arr_rec_prodmenu[l_idx].option_text = kandooword("pinqwind","F") 

					WHEN "16" ## companions 
						LET l_idx = l_idx + 1 
						LET l_arr_rec_prodmenu[l_idx].option_num = "G" 
						LET l_arr_rec_prodmenu[l_idx].option_text = kandooword("pinqwind","G") 

					WHEN "17" ## product history 
						SELECT unique 1 FROM prodhist 
						WHERE cmpy_code = p_cmpy 
						AND part_code = p_part_code 
						IF status = 0 THEN 
							LET l_idx = l_idx + 1 
							LET l_arr_rec_prodmenu[l_idx].option_num = "H" 
							LET l_arr_rec_prodmenu[l_idx].option_text = kandooword("pinqwind","H") 
						END IF 

					WHEN "18" ## product information 
						LET l_idx = l_idx + 1 
						LET l_arr_rec_prodmenu[l_idx].option_num = "I" 
						LET l_arr_rec_prodmenu[l_idx].option_text = kandooword("pinqwind","I") 

					WHEN "19" ## cost ledger inquiry 
						IF l_rec_inparms.cost_ind = "F" 
						OR l_rec_inparms.cost_ind = "L" THEN 
							SELECT unique 1 FROM t_prodstatus 
							IF status = 0 THEN 
								LET l_idx = l_idx + 1 
								LET l_arr_rec_prodmenu[l_idx].option_num = "J" 
								LET l_arr_rec_prodmenu[l_idx].option_text = kandooword("pinqwind","J") 
							END IF 
						END IF 

					WHEN "20" ## product margin 
						SELECT unique 1 FROM t_prodstatus 
						IF status = 0 THEN 
							LET l_idx = l_idx + 1 
							LET l_arr_rec_prodmenu[l_idx].option_num = "K" 
							LET l_arr_rec_prodmenu[l_idx].option_text = kandooword("pinqwind","K") 
						END IF 

					WHEN "21" ## customer product code 
						LET l_idx = l_idx + 1 
						LET l_arr_rec_prodmenu[l_idx].option_num = "P" 
						LET l_arr_rec_prodmenu[l_idx].option_text = kandooword("pinvwind","P") 

					WHEN "22" ## serialized product 
						IF l_rec_product.serial_flag = 'Y' THEN 
							LET l_idx = l_idx + 1 
							LET l_arr_rec_prodmenu[l_idx].option_num = "S" 
							LET l_arr_rec_prodmenu[l_idx].option_text = kandooword("pinqwind","S") 
						END IF 

					WHEN "23" ## stock valuation 
						SELECT unique 1 FROM t_prodstatus 
						IF status = 0 THEN 
							LET l_idx = l_idx + 1 
							LET l_arr_rec_prodmenu[l_idx].option_num = "V" 
							LET l_arr_rec_prodmenu[l_idx].option_text = kandooword("pinqwind","V") 
						END IF 

					OTHERWISE 
						EXIT FOR 

				END CASE 

			END FOR 

			OPEN WINDOW I146 with FORM "I146" 
			CALL windecoration_i("I146") 

			DISPLAY BY NAME 
				l_rec_product.part_code, 
				l_rec_product.desc_text 

			ERROR kandoomsg2("A",1030,"") 

			#      INPUT ARRAY l_arr_rec_prodmenu WITHOUT DEFAULTS FROM sr_prodmenu.* ATTRIBUTE(UNBUFFERED)
			DISPLAY ARRAY l_arr_rec_prodmenu TO sr_prodmenu.* ATTRIBUTE(UNBUFFERED) 
				BEFORE DISPLAY 
					CALL publish_toolbar("kandoo","pinvwind","input-arr-prodmenu") 
					CALL dialog.setActionHidden("ACCEPT",NOT l_arr_rec_prodmenu.getSize())
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				BEFORE ROW 
					LET l_idx = arr_curr()
					LET l_menu_option =  l_arr_rec_prodmenu[l_idx].option_num
					#LET scrn = scr_line()
					# DISPLAY l_arr_rec_prodmenu[l_idx].*
					#      TO sr_prodmenu[scrn].*
					############################
					# Added by HuHo
				ON ACTION ("ACCEPT","DOUBLECLICK")
					IF (l_idx > 0) AND (l_idx <= l_arr_rec_prodmenu.getSize()) THEN
					
						LET l_arg1 = "PART_CODE=", trim(l_rec_product.part_code)
						 
						CASE l_menu_option 
							WHEN "1" ## general details 
								CALL prgdwind(p_cmpy,l_rec_product.part_code)
								 
							WHEN "2" ## purchasing info 
								CALL purch_det(p_cmpy,l_rec_product.part_code)
								 
							WHEN "3" ## product pricing 
								CALL prpdwind(p_cmpy,l_rec_product.part_code)
								 
							WHEN "4" ## stock status 
								CALL prsswind(p_cmpy,l_rec_product.part_code)
								 
							WHEN "5" ## product ledger 
								CALL prldwind(p_cmpy,l_rec_product.part_code)
								 
							WHEN "6" ## product notes								
								CALL run_prog("I13",l_arg1,"","","")
								 
							WHEN "7" ## warehouse stock status 
								CALL display_ware_stock(p_cmpy,l_rec_product.part_code)
								 
							WHEN "8" ## product STATISTICS 
								CALL prod_stats(p_cmpy,l_rec_product.part_code)
								 
							WHEN "9" ## reporting codes 
								CALL prrcwind(p_cmpy,l_rec_product.part_code)
								 
							WHEN "A" ## purchase orders 
								IF l_rec_company.module_text[23] = "W" THEN
									CALL fgl_winmessage("W-MODULE is not implemented yet","W-MODULE is not implemented yet\nBuilding Products Distribution","INFO") 
									CALL run_prog("W14",l_arg1,"","","") --missing programs 
								ELSE 
									CALL run_prog("E1A",l_arg1,"","","") 
								END IF 
								
							WHEN "B" ## back orders 
								CALL run_prog("R33",l_arg1,"","","")
								 
							WHEN "C" ## stock transfer 
								CALL run_prog("I51","", "","","")
								 
							WHEN "D" ## production schedules 
								CALL show_sched(p_cmpy,l_rec_product.part_code,"")
								 
							WHEN "E" ## supersession 
								CALL show_supersessions(p_cmpy,l_rec_product.part_code)
								 
							WHEN "F" ## alternates 
								CALL show_alternates(p_cmpy,l_rec_product.part_code)
								 
							WHEN "G" ## companions 
								CALL show_companions(p_cmpy,l_rec_product.part_code)
								 
							WHEN "H" ## product history 
								CALL run_prog("I1A",l_arg1,"","","")
								 
							WHEN "I" ## product information 
								CALL view_prodinfo(p_cmpy,l_rec_product.part_code)
								 
							WHEN "J" ## cost ledger` 
								CALL cost_ledger_inquiry(p_cmpy,l_rec_product.part_code,"")
								 
							WHEN "K" ## product margin 
								CALL product_margin_inquiry(p_cmpy,l_rec_product.part_code)
								 
							WHEN "P" ## customer part code 
								CALL view_partcust_code(p_cmpy,l_rec_product.part_code)	RETURNING l_cust_code
								 
							WHEN "S" ## serialized product 
								CALL run_prog("I33",l_arg1,"","","")
								 
							WHEN "V" ## stock valuation 
								CALL stock_valuation_window(p_cmpy,l_rec_product.part_code) 
						END CASE 
--					OPTIONS INSERT KEY f36, 
--					DELETE KEY f36 
					END IF





					############################
					{
					         AFTER FIELD scroll_flag
					--#IF fgl_lastkey() = fgl_keyval("accept")
					--#AND fgl_fglgui() THEN
					--#   NEXT FIELD option_num
					--#END IF
					            IF l_arr_rec_prodmenu[l_idx].scroll_flag IS NULL THEN
					               IF fgl_lastkey() = fgl_keyval("down")
					               AND arr_curr() = arr_count() THEN
					                  ERROR kandoomsg2("A",9001,"")
					                  NEXT FIELD scroll_flag
					               END IF
					            END IF
					         BEFORE FIELD option_num
					            IF l_arr_rec_prodmenu[l_idx].scroll_flag IS NULL THEN
					               LET l_arr_rec_prodmenu[l_idx].scroll_flag = l_arr_rec_prodmenu[l_idx].option_num
					            ELSE
					               LET i = 1
					               WHILE (l_arr_rec_prodmenu[l_idx].scroll_flag IS NOT NULL)
					                  IF l_arr_rec_prodmenu[i].option_num IS NULL THEN
					                     LET l_arr_rec_prodmenu[l_idx].scroll_flag = NULL
					                  ELSE
					                     IF l_arr_rec_prodmenu[l_idx].scroll_flag=
					                        l_arr_rec_prodmenu[i].option_num THEN
					                        EXIT WHILE
					                     END IF
					                  END IF
					                  LET i = i + 1
					               END WHILE
					            END IF

					            CASE l_arr_rec_prodmenu[l_idx].scroll_flag
					               WHEN "1"  ## General Details
					                  CALL prgdwind(p_cmpy,l_rec_product.part_code)
					               WHEN "2"  ## Purchasing Info
					                  CALL purch_det(p_cmpy,l_rec_product.part_code)
					               WHEN "3"  ## Product Pricing
					                  CALL prpdwind(p_cmpy,l_rec_product.part_code)
					               WHEN "4"  ## Stock Status
					                  CALL prsswind(p_cmpy,l_rec_product.part_code)
					               WHEN "5" ## Product Ledger
					                  CALL prldwind(p_cmpy,l_rec_product.part_code)
					               WHEN "6"  ## Product Notes
					                  CALL run_prog("I13",l_rec_product.part_code,"","","")
					               WHEN "7"  ## Warehouse Stock Status
					                  CALL display_ware_stock(p_cmpy,l_rec_product.part_code)
					               WHEN "8"  ## Product Statistics
					                  CALL prod_stats(p_cmpy,l_rec_product.part_code)
					               WHEN "9"  ## Reporting Codes
					                  CALL prrcwind(p_cmpy,l_rec_product.part_code)
					               WHEN "A"  ## Purchase Orders
					                  IF l_rec_company.module_text[23] = "W" THEN
					                     CALL run_prog("W14",l_rec_product.part_code,"","","")
					                  ELSE
					                     CALL run_prog("E1A",l_rec_product.part_code,"","","")
					                  END IF
					               WHEN "B"  ## Back Orders
					                  CALL run_prog("R33",l_rec_product.part_code,"","","")
					               WHEN "C"  ## Stock Transfer
					                  CALL run_prog("I51","", "","","")
					               WHEN "D" ## Production Schedules
					                  CALL show_sched(p_cmpy,l_rec_product.part_code,"")
					               WHEN "E" ## Supersession
					                  CALL show_supersessions(p_cmpy,l_rec_product.part_code)
					               WHEN "F" ## Alternates
					                  CALL show_alternates(p_cmpy,l_rec_product.part_code)
					               WHEN "G" ## Companions
					                  CALL show_companions(p_cmpy,l_rec_product.part_code)
					               WHEN "H"  ## Product History
					                  CALL run_prog("I1A",l_rec_product.part_code,"","","")
					               WHEN "I"  ## Product Information
					                  CALL view_prodinfo(p_cmpy,l_rec_product.part_code)
					               WHEN "J"  ## Cost Ledger`
					                  CALL cost_ledger_inquiry(p_cmpy,l_rec_product.part_code,"")
					               WHEN "K"  ## Product Margin
					                  CALL product_margin_inquiry(p_cmpy,l_rec_product.part_code)
					               WHEN "P" ## Customer Part Code
					                  CALL view_partcust_code(p_cmpy,l_rec_product.part_code)
					                          returning l_cust_code
					               WHEN "S"  ## Serialized Product
					                  CALL run_prog("I33",l_rec_product.part_code,"","","")
					               WHEN "V"  ## Stock Valuation
					                  CALL stock_valuation_window(p_cmpy,l_rec_product.part_code)
					            END CASE
					            OPTIONS INSERT KEY F36,
					                    DELETE KEY F36
					            LET l_arr_rec_prodmenu[l_idx].scroll_flag = NULL
					            NEXT FIELD scroll_flag
					#AFTER ROW
					#   DISPLAY l_arr_rec_prodmenu[l_idx].*
					#        TO sr_prodmenu[scrn].*
					 }

			END DISPLAY 

			CLOSE WINDOW I146 

--			IF fgl_find_table("t_prodstatus") THEN
				DROP TABLE t_prodstatus
--			END IF
		END IF 

		LET int_flag = false 
		LET quit_flag = false 

END FUNCTION 
###########################################################################
# END FUNCTION pinqwind(p_cmpy,p_part_code,p_xfer_ind)
###########################################################################

###########################################################################
# FUNCTION display_ware_stock(p_cmpy,p_part_code)
#
#
###########################################################################
FUNCTION display_ware_stock(p_cmpy,p_part_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_part_code LIKE product.part_code 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_rec_opparms RECORD LIKE opparms.* 
	DEFINE l_rec_backreas RECORD LIKE backreas.* 
	DEFINE l_rec_globalrec 
		RECORD 
			avail_qty LIKE prodstatus.onhand_qty, 
			favail_qty LIKE prodstatus.onhand_qty 
		END RECORD 
	DEFINE l_temp_text CHAR(30) 

	OPEN WINDOW I614 with FORM "I614" 
	CALL windecoration_i("I614") 

	SELECT * INTO l_rec_product.* FROM product 
	WHERE cmpy_code = p_cmpy 
	AND part_code = p_part_code 

	DISPLAY BY NAME 
		l_rec_product.part_code,	
		l_rec_product.desc_text
		 
	MESSAGE kandoomsg2("I",1030,"")	#1030 Enter Warehouse Code;  OK TO Continue.
	INPUT BY NAME l_rec_warehouse.ware_code 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","pinvwind","input-warehouse") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null)
			 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" #ON KEY (control-b) 
			LET l_temp_text = show_ware(p_cmpy) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_warehouse.ware_code = l_temp_text 
				DISPLAY BY NAME l_rec_warehouse.ware_code 

			END IF 
			NEXT FIELD ware_code 

		AFTER FIELD ware_code 
			IF l_rec_warehouse.ware_code IS NULL 
			OR l_rec_warehouse.ware_code = " " THEN 
				ERROR kandoomsg2("U",9102,"")			#9102 Value must be entered.
				NEXT FIELD ware_code 
			END IF 

			SELECT * INTO l_rec_warehouse.* FROM warehouse 
			WHERE ware_code = l_rec_warehouse.ware_code 
			AND cmpy_code = p_cmpy 
			IF status = notfound THEN 
				ERROR kandoomsg2("I",9030,"")		#9030 Warehouse does NOT exist;  Try Window.
				NEXT FIELD ware_code 
			END IF 

			SELECT * INTO l_rec_prodstatus.* FROM prodstatus 
			WHERE part_code = l_rec_product.part_code 
			AND ware_code = l_rec_warehouse.ware_code 
			AND cmpy_code = p_cmpy 
			IF status = notfound THEN 
				ERROR kandoomsg2("A",9126,"") 		#9156 Product NOT stocked AT this location.
				NEXT FIELD ware_code 
			END IF 
			DISPLAY l_rec_warehouse.desc_text 
			TO warehouse.desc_text 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 
		CALL db_opparms_get_cal_available_flag(UI_OFF,"1") RETURNING l_rec_opparms.cal_available_flag 

		IF l_rec_opparms.cal_available_flag  IS NULL THEN 
			LET l_rec_opparms.cal_available_flag = "N" 
		END IF 
		
		IF l_rec_opparms.cal_available_flag = "N" THEN 
			LET l_rec_globalrec.avail_qty = l_rec_prodstatus.onhand_qty - l_rec_prodstatus.reserved_qty - l_rec_prodstatus.back_qty 
		ELSE 
			LET l_rec_globalrec.avail_qty = l_rec_prodstatus.onhand_qty - l_rec_prodstatus.reserved_qty 
		END IF
		 
		LET l_rec_globalrec.favail_qty = l_rec_globalrec.avail_qty + l_rec_prodstatus.onord_qty - l_rec_prodstatus.forward_qty 

		SELECT * INTO l_rec_backreas.* FROM backreas 
		WHERE cmpy_code = p_cmpy 
		AND part_code = l_rec_prodstatus.part_code 
		AND ware_code = l_rec_prodstatus.ware_code 
		IF status = notfound THEN 
			LET l_rec_backreas.exp_date = NULL 
			LET l_rec_backreas.reason_text = NULL 
		END IF 
		
		DISPLAY 
			l_rec_warehouse.desc_text, 
			l_rec_product.sell_uom_code, 
			l_rec_product.sell_uom_code, 
			l_rec_product.sell_uom_code, 
			l_rec_globalrec.avail_qty, 
			l_rec_globalrec.avail_qty, 
			l_rec_globalrec.favail_qty 
		TO 
			warehouse.desc_text, 
			sr_stock[1].stock_uom_code, 
			sr_stock[2].stock_uom_code, 
			sr_stock[3].stock_uom_code, 
			sr_avail[1].avail_qty, 
			sr_avail[2].avail_qty, 
			favail_qty 

		DISPLAY BY NAME 
			l_rec_prodstatus.onhand_qty, 
			l_rec_prodstatus.reserved_qty, 
			l_rec_prodstatus.back_qty, 
			l_rec_prodstatus.onord_qty, 
			l_rec_prodstatus.forward_qty, 
			l_rec_prodstatus.reorder_point_qty, 
			l_rec_prodstatus.bin1_text, 
			l_rec_prodstatus.stocked_flag, 
			l_rec_prodstatus.reorder_qty, 
			l_rec_prodstatus.bin2_text, 
			l_rec_prodstatus.nonstk_pick_flag, 
			l_rec_prodstatus.max_qty, 
			l_rec_prodstatus.bin3_text, 
			l_rec_prodstatus.abc_ind, 
			l_rec_prodstatus.critical_qty, 
			l_rec_prodstatus.replenish_ind, 
			l_rec_prodstatus.last_sale_date, 
			l_rec_prodstatus.stockturn_qty, 
			l_rec_prodstatus.last_receipt_date, 
			l_rec_prodstatus.avg_qty, 
			l_rec_prodstatus.last_stcktake_date, 
			l_rec_backreas.exp_date, 
			l_rec_backreas.reason_text 

		--MESSAGE kandoomsg2("U",0001,"")	#0001 Any Key TO Continue.
		CALL eventsuspend()
	END IF 

	CLOSE WINDOW I614 
END FUNCTION 
###########################################################################
# FUNCTION display_ware_stock(p_cmpy,p_part_code)
###########################################################################