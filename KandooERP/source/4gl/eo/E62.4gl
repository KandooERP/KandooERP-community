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
GLOBALS "../eo/E62_GLOBALS.4gl"
###########################################################################
# FUNCTION E62_main()
#
# E66 (E62 !!!) - Inquiry program FOR Sales Order Special Offers
###########################################################################
FUNCTION E62_main() 
	DEFER QUIT 
	DEFER INTERRUPT 
	
	CALL setModuleId("E62") 

	LET yes_flag = xlate_from("Y") 
	LET no_flag = xlate_from("N") 

	OPEN WINDOW E121 with FORM "E121" 
	 CALL windecoration_e("E121")
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
 
	CALL scan_offersale() 
	 
	CLOSE WINDOW E121
END FUNCTION 
###########################################################################
# END FUNCTION E62_main()
###########################################################################


###########################################################################
# FUNCTION db_offersale_get_datasource(p_filter)
#
#  
###########################################################################
FUNCTION db_offersale_get_datasource(p_filter) 
	DEFINE p_filter BOOLEAN
	DEFINE l_where_text STRING 
	DEFINE l_query_text STRING 
	DEFINE l_rec_offersale RECORD LIKE offersale.*
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
				CALL publish_toolbar("kandoo","E62","construct-offer_code-1")
	
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),NULL) 

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
	FOREACH c_offersale INTO l_rec_offersale.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_offersale[l_idx].offer_code = l_rec_offersale.offer_code 
		LET l_arr_rec_offersale[l_idx].desc_text = l_rec_offersale.desc_text 
		LET l_arr_rec_offersale[l_idx].start_date = l_rec_offersale.start_date 
		LET l_arr_rec_offersale[l_idx].end_date = l_rec_offersale.end_date 
		LET l_arr_rec_offersale[l_idx].prodline_disc_flag = 	xlate_from(l_rec_offersale.prodline_disc_flag)

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF
				 
	END FOREACH 
	MESSAGE kandoomsg2("U",9113,l_idx) #9113 l_idx records selected

	RETURN l_arr_rec_offersale 
END FUNCTION 
###########################################################################
# END FUNCTION db_offersale_get_datasource(p_filter)
###########################################################################


###########################################################################
# FUNCTION scan_offersale()
#
# 
###########################################################################
FUNCTION scan_offersale() 
	DEFINE l_rec_offersale RECORD LIKE offersale.*
	DEFINE l_arr_rec_offersale DYNAMIC ARRAY OF RECORD 
		offer_code LIKE offersale.offer_code, 
		desc_text LIKE offersale.desc_text, 
		start_date LIKE offersale.start_date, 
		end_date LIKE offersale.end_date, 
		prodline_disc_flag LIKE offersale.prodline_disc_flag 
	END RECORD 
	DEFINE l_idx SMALLINT 

	IF db_offersale_get_count() > get_settings_maxListArraySizeSwitch() THEN
		CALL db_offersale_get_datasource(TRUE) RETURNING l_arr_rec_offersale 	#for none-approved vouchers, we do not need to count prior
	ELSE
		CALL db_offersale_get_datasource(FALSE) RETURNING l_arr_rec_offersale 	#for none-approved vouchers, we do not need to count prior
	END IF 

--	IF l_idx = 0 THEN 
--		INITIALIZE l_arr_rec_offersale[l_idx+1].start_date TO NULL 
--		INITIALIZE l_arr_rec_offersale[l_idx+1].end_date TO NULL 
--	END IF 
	

	MESSAGE kandoomsg2("E",1007,"") 	#1007 F3/F4 TO Page Fwd/Bwd - RETURN TO View
	--INPUT ARRAY l_arr_rec_offersale WITHOUT DEFAULTS FROM sr_offersale.* ATTRIBUTE(UNBUFFERED, insert row = FALSE, append row = FALSE, auto append = FALSE, delete row = FALSE) 
	DISPLAY ARRAY l_arr_rec_offersale TO sr_offersale.* ATTRIBUTE(UNBUFFERED)
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","E62","input-arr-l_arr_rec_offersale-1") 
			CALL dialog.setActionHidden("ACCEPT",TRUE) 
			CALL dialog.setActionHidden("DETAIL",NOT l_arr_rec_offersale.getSize())

		BEFORE ROW 
			LET l_idx = arr_curr() 

		AFTER ROW
			#nothing

		AFTER DISPLAY
			#nothing
			
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),NULL) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar()
						
		ON ACTION "FILTER"
			CALL l_arr_rec_offersale.clear()
			CALL db_offersale_get_datasource(TRUE) RETURNING l_arr_rec_offersale 	#for none-approved vouchers, we do not need to count prior		

		ON ACTION "REFRESH"
			 CALL windecoration_e("E121")
			CALL l_arr_rec_offersale.clear()
			CALL db_offersale_get_datasource(FALSE) RETURNING l_arr_rec_offersale 	#for none-approved vouchers, we do not need to count prior		

		ON ACTION ("DETAIL","DOUBLECLICK") --BEFORE FIELD offer_code 
			IF (l_idx > 0) AND (l_idx <= l_arr_rec_offersale.getSize()) THEN
				SELECT * INTO l_rec_offersale.* FROM offersale 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND offer_code = l_arr_rec_offersale[l_idx].offer_code 
				IF status = NOTFOUND THEN 
					IF l_arr_rec_offersale[l_idx].offer_code IS NOT NULL THEN 
						ERROR kandoomsg2("E",7012,l_arr_rec_offersale[l_idx].offer_code) #7012 Special Offer has been deleted
					END IF 
				ELSE 
					OPEN WINDOW E129 with FORM "E129" 
					 CALL windecoration_e("E129") -- albo kd-755
	 
					LET l_rec_offersale.prodline_disc_flag = xlate_from(l_rec_offersale.prodline_disc_flag) 
					LET l_rec_offersale.grp_disc_flag = xlate_from(l_rec_offersale.grp_disc_flag) 
					LET l_rec_offersale.auto_prod_flag = xlate_from(l_rec_offersale.auto_prod_flag)
					 
					DISPLAY BY NAME 
						l_rec_offersale.offer_code, 
						l_rec_offersale.desc_text, 
						l_rec_offersale.start_date, 
						l_rec_offersale.end_date, 
						l_rec_offersale.bonus_check_per, 
						l_rec_offersale.bonus_check_amt, 
						l_rec_offersale.disc_check_per, 
						l_rec_offersale.disc_per, 
						l_rec_offersale.checkrule_ind, 
						l_rec_offersale.disc_rule_ind, 
						l_rec_offersale.checktype_ind, 
						l_rec_offersale.prodline_disc_flag, 
						l_rec_offersale.grp_disc_flag, 
						l_rec_offersale.auto_prod_flag, 
						l_rec_offersale.min_sold_amt, 
						l_rec_offersale.min_order_amt 
	
					MENU "INQUIRY" 
				
						BEFORE MENU 
							SHOW option all 
							SELECT unique 1 FROM offerprod 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND offer_code = l_rec_offersale.offer_code 
							AND type_ind = "1" 
							IF status = NOTFOUND THEN 
								HIDE option "Sold" 
							END IF 
	
							SELECT unique 1 FROM offerprod 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND offer_code = l_rec_offersale.offer_code 
							AND type_ind = "2" 
							IF status = NOTFOUND THEN 
								HIDE option "Bonus" 
							END IF 
	
							IF l_rec_offersale.prodline_disc_flag = no_flag THEN 
								HIDE option "Discounts" 
							ELSE 
								SELECT unique 1 FROM proddisc 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND key_num = l_rec_offersale.offer_code 
								AND type_ind = "2" 
								IF status = NOTFOUND THEN 
									HIDE option "Discounts" 
								END IF 
							END IF 
	
							IF l_rec_offersale.auto_prod_flag = no_flag THEN 
								HIDE option "Auto" 
							ELSE 
								SELECT unique 1 FROM offerauto 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND offer_code = l_rec_offersale.offer_code 
								IF status = NOTFOUND THEN 
									HIDE option "Auto" 
								END IF 
							END IF 
	
						ON ACTION "WEB-HELP" 
							CALL onlinehelp(getmoduleid(),NULL) 
	
						ON ACTION "actToolbarManager" 
							CALL setuptoolbar()
	
	
						COMMAND "Sold" " Inquire on sold product items " 
							OPEN WINDOW E123 with FORM "E123" 
							 CALL windecoration_e("E123") 
							CALL lineitem_scan(l_rec_offersale.*,"1") 
							CLOSE WINDOW E123 
	
						COMMAND "Bonus" " Inquire on bonus product items" 
							OPEN WINDOW E124 with FORM "E124" 
							 CALL windecoration_e("E124")  
							CALL lineitem_scan(l_rec_offersale.*,"2") 
							CLOSE WINDOW E124 
	
						COMMAND "Discounts" " Inquire on product line item discounts" 
							OPEN WINDOW E125 with FORM "E125" 
							 CALL windecoration_e("E125") 
							CALL proddisc_scan(l_rec_offersale.*) 
							CLOSE WINDOW E125 
	
						COMMAND "Auto" " Inquire on automatic insertion products" 
							OPEN WINDOW E291 with FORM "E291" 
							 CALL windecoration_e("E291") -- albo kd-755 
							CALL scan_prods(glob_rec_kandoouser.cmpy_code,l_rec_offersale.offer_code) 
							CLOSE WINDOW E291 
	
						COMMAND KEY("E",INTERRUPT)"Exit" " RETURN TO scan offers" 
							LET int_flag = FALSE 
							LET quit_flag = FALSE 
							EXIT MENU 
					END MENU 
	
					CLOSE WINDOW E129
				END IF
			END IF
	END DISPLAY 

	LET int_flag = FALSE 
	LET quit_flag = FALSE 
END FUNCTION 
###########################################################################
# END FUNCTION scan_offersale()
###########################################################################


###########################################################################
# FUNCTION scan_offersale()
#
# 
###########################################################################
FUNCTION lineitem_scan(p_rec_offersale,p_type_ind) 
	DEFINE p_rec_offersale RECORD LIKE offersale.* 
	DEFINE p_type_ind char(1) 
	DEFINE l_rec_offerprod RECORD LIKE offerprod.* 
	DEFINE l_arr_rec_offerprod DYNAMIC ARRAY OF RECORD --array[30] OF RECORD 
		part_code LIKE offerprod.part_code, 
		prodgrp_code LIKE offerprod.prodgrp_code, 
		maingrp_code LIKE offerprod.maingrp_code, 
		reqd_qty LIKE offerprod.reqd_qty, 
		reqd_amt LIKE offerprod.reqd_amt 
	END RECORD 
	DEFINE l_idx SMALLINT 

	DISPLAY BY NAME p_rec_offersale.offer_code, 
	p_rec_offersale.desc_text 

	DECLARE c_offerprod cursor FOR 
	SELECT * FROM offerprod 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND offer_code = p_rec_offersale.offer_code 
	AND type_ind = p_type_ind 
	LET l_idx = 0 
	
	FOREACH c_offerprod INTO l_rec_offerprod.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_offerprod[l_idx].part_code = l_rec_offerprod.part_code 
		LET l_arr_rec_offerprod[l_idx].prodgrp_code = l_rec_offerprod.prodgrp_code 
		LET l_arr_rec_offerprod[l_idx].maingrp_code = l_rec_offerprod.maingrp_code 
		LET l_arr_rec_offerprod[l_idx].reqd_qty = l_rec_offerprod.reqd_qty 
		LET l_arr_rec_offerprod[l_idx].reqd_amt = l_rec_offerprod.reqd_amt 
--		IF l_idx = 30 THEN 
--			## kandoomsg
--			EXIT FOREACH 
--		END IF 
	END FOREACH 

	MESSAGE kandoomsg2("E",1008,"") #1008 F3/f4 page fwd/bwd - ESC TO Continue
	CALL set_count(l_idx) 

	DISPLAY ARRAY l_arr_rec_offerprod TO sr_offerprod.* 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","E62","display-arr-offerprod") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),NULL) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END DISPLAY 

	LET quit_flag = FALSE 
	LET int_flag = FALSE 
END FUNCTION 
###########################################################################
# END FUNCTION scan_offersale()
###########################################################################


###########################################################################
# FUNCTION proddisc_scan(p_rec_offersale)
#
# 
###########################################################################
FUNCTION proddisc_scan(p_rec_offersale) 
	DEFINE p_rec_offersale RECORD LIKE offersale.* 
	DEFINE l_rec_proddisc RECORD LIKE proddisc.* 
	DEFINE l_arr_rec_proddisc DYNAMIC ARRAY OF RECORD --array[200] OF RECORD 
		scroll_flag char(1), 
		part_code LIKE proddisc.part_code, 
		prodgrp_code LIKE proddisc.prodgrp_code, 
		maingrp_code LIKE proddisc.maingrp_code, 
		reqd_amt LIKE proddisc.reqd_amt, 
		disc_per LIKE proddisc.disc_per, 
		unit_sale_amt LIKE proddisc.unit_sale_amt, 
		list_amt LIKE prodstatus.list_amt 
	END RECORD 
	DEFINE l_part_code LIKE proddisc.part_code 
	DEFINE l_idx SMALLINT 
	DEFINE l_disc_type char(3) 

	IF p_rec_offersale.checktype_ind = "1" THEN 
		LET l_disc_type = "Qty" 
	ELSE 
		LET l_disc_type = "Amt" 
	END IF 
	
	DISPLAY l_disc_type TO disc_type 
	DISPLAY BY NAME p_rec_offersale.offer_code 
	DISPLAY BY NAME p_rec_offersale.desc_text 

	CASE p_rec_offersale.checktype_ind 
		WHEN "1" 
			DECLARE c1_proddisc cursor FOR 
			SELECT * FROM proddisc 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND key_num = p_rec_offersale.offer_code 
			AND type_ind = "2" 
			ORDER BY maingrp_code, prodgrp_code, part_code, reqd_qty 
			LET l_idx = 0 

			FOREACH c1_proddisc INTO l_rec_proddisc.* 
				LET l_idx = l_idx + 1 
				LET l_arr_rec_proddisc[l_idx].part_code = l_rec_proddisc.part_code 
				LET l_arr_rec_proddisc[l_idx].prodgrp_code = l_rec_proddisc.prodgrp_code 
				LET l_arr_rec_proddisc[l_idx].maingrp_code = l_rec_proddisc.maingrp_code 
				LET l_arr_rec_proddisc[l_idx].reqd_amt = l_rec_proddisc.reqd_qty 
				IF l_rec_proddisc.per_amt_ind = 'P' THEN 
					LET l_arr_rec_proddisc[l_idx].unit_sale_amt = NULL 
					LET l_arr_rec_proddisc[l_idx].disc_per = l_rec_proddisc.disc_per 
				ELSE 
					LET l_arr_rec_proddisc[l_idx].unit_sale_amt = l_rec_proddisc.unit_sale_amt 
					LET l_arr_rec_proddisc[l_idx].disc_per = NULL 
				END IF 

				LET l_arr_rec_proddisc[l_idx].list_amt = get_listamount(l_rec_proddisc.part_code, l_rec_proddisc.prodgrp_code, l_rec_proddisc.maingrp_code) 

			END FOREACH 

		OTHERWISE 
			DECLARE c2_proddisc cursor FOR 
			SELECT * FROM proddisc 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND key_num = p_rec_offersale.offer_code 
			AND type_ind = "2" 
			ORDER BY maingrp_code, prodgrp_code, part_code, reqd_amt 

			LET l_idx = 0 
			FOREACH c2_proddisc INTO l_rec_proddisc.* 
				LET l_idx = l_idx + 1 
				LET l_arr_rec_proddisc[l_idx].part_code = l_rec_proddisc.part_code 
				LET l_arr_rec_proddisc[l_idx].prodgrp_code = l_rec_proddisc.prodgrp_code 
				LET l_arr_rec_proddisc[l_idx].maingrp_code = l_rec_proddisc.maingrp_code 
				LET l_arr_rec_proddisc[l_idx].reqd_amt = l_rec_proddisc.reqd_amt 

				IF l_rec_proddisc.per_amt_ind = 'P' THEN 
					LET l_arr_rec_proddisc[l_idx].unit_sale_amt = NULL 
					LET l_arr_rec_proddisc[l_idx].disc_per = l_rec_proddisc.disc_per 
				ELSE 
					LET l_arr_rec_proddisc[l_idx].unit_sale_amt = l_rec_proddisc.unit_sale_amt 
					LET l_arr_rec_proddisc[l_idx].disc_per = NULL 
				END IF 

				LET l_arr_rec_proddisc[l_idx].list_amt = get_listamount(
					l_rec_proddisc.part_code, 
					l_rec_proddisc.prodgrp_code, 
					l_rec_proddisc.maingrp_code) 
			END FOREACH 

	END CASE 

--	CALL set_count(l_idx) 
	MESSAGE kandoomsg2("E",1008,"")	#1008 " F3/F4 TO Page Fwd/Bwd - ESC TO Continue"

	DISPLAY ARRAY l_arr_rec_proddisc TO sr_proddisc.* 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","E62","display-arr-proddisc") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),NULL) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END DISPLAY 

	LET quit_flag = FALSE 
	LET int_flag = FALSE 
END FUNCTION 
###########################################################################
# END FUNCTION proddisc_scan(p_rec_offersale)
###########################################################################


###########################################################################
# FUNCTION get_listamount(p_part_code1,p_prodgrp_code,p_maingrp_code)
#
# 
###########################################################################
FUNCTION get_listamount(p_part_code1,p_prodgrp_code,p_maingrp_code) 
	DEFINE p_part_code1 LIKE proddisc.part_code 
	DEFINE p_prodgrp_code LIKE proddisc.prodgrp_code 
	DEFINE p_maingrp_code LIKE proddisc.maingrp_code 
	DEFINE l_rec_inparms RECORD LIKE inparms.* 
	DEFINE l_part_code LIKE product.part_code 
	DEFINE l_cnt SMALLINT 
	DEFINE l_list_amt LIKE prodstatus.list_amt 
	DEFINE l_min_list_amt LIKE prodstatus.list_amt 

	CALL db_inparms_get_rec(UI_OFF,"1") RETURNING l_rec_inparms.* 
	 
	IF p_part_code1 IS NOT NULL THEN 
		SELECT list_amt INTO l_list_amt FROM prodstatus 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = p_part_code1 
		AND ware_code = l_rec_inparms.mast_ware_code 
		IF status = NOTFOUND THEN 
			LET l_list_amt = 0 
		END IF 
	ELSE 
		IF p_prodgrp_code IS NOT NULL THEN 
			DECLARE c_product cursor FOR 
			SELECT part_code FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND prodgrp_code = p_prodgrp_code 
			LET l_cnt = 0 
			
			FOREACH c_product INTO l_part_code 
				SELECT list_amt INTO l_list_amt FROM prodstatus 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = l_part_code 
				AND ware_code = l_rec_inparms.mast_ware_code 
				IF status = NOTFOUND THEN 
					LET l_list_amt = 0 
				END IF 

				IF l_cnt = 0 THEN 
					LET l_min_list_amt = l_list_amt 
				END IF 

				IF l_list_amt < l_min_list_amt THEN 
					LET l_min_list_amt = l_list_amt 
				END IF 

				LET l_cnt = l_cnt + 1 
			END FOREACH 

			LET l_list_amt = l_min_list_amt 

		ELSE 

			IF p_maingrp_code IS NOT NULL THEN 
				DECLARE c2_product cursor FOR 
				SELECT part_code FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND maingrp_code = p_maingrp_code 
				LET l_cnt = 0 
				
				FOREACH c2_product INTO l_part_code 
					SELECT list_amt INTO l_list_amt FROM prodstatus 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = l_part_code 
					AND ware_code = l_rec_inparms.mast_ware_code 
					IF status = NOTFOUND THEN 
						LET l_list_amt = 0 
					END IF 

					IF l_cnt = 0 THEN 
						LET l_min_list_amt = l_list_amt 
					END IF 

					IF l_list_amt < l_min_list_amt THEN 
						LET l_min_list_amt = l_list_amt 
					END IF 
					LET l_cnt = l_cnt + 1 
				END FOREACH 

				LET l_list_amt = l_min_list_amt 
			END IF 
		END IF 
	END IF 
	
	RETURN l_list_amt 
END FUNCTION
###########################################################################
# END FUNCTION get_listamount(p_part_code1,p_prodgrp_code,p_maingrp_code)
###########################################################################