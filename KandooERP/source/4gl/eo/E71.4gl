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
GLOBALS "../eo/E7_GROUP_GLOBALS.4gl"
GLOBALS "../eo/E71_GLOBALS.4gl"
################################################################################
# FUNCTION E71_main()
#
# E71 - Maintanence program FOR Sales Conditions
################################################################################
FUNCTION E71_main() 

	CALL setModuleId("E71") -- albo 

	LET glob_yes_flag = xlate_from("Y") 
	LET glob_no_flag = xlate_from("N") 

	CREATE temp TABLE t_conddisc(reqd_amt decimal(10,2), 
	bonus_check_per decimal(5,2), 
	disc_check_per decimal(5,2), 
	disc_per decimal(5,2)) with no LOG 
	
	CREATE temp TABLE t_proddisc( maingrp_code char(3), 
	prodgrp_code char(3), 
	part_code char(15), 
	reqd_amt decimal(10,2), 
	reqd_qty decimal(8,2), 
	disc_per decimal(5,2), 
	unit_sale_amt decimal(16,2), 
	per_amt_ind char(1)) with no LOG 

	CREATE temp TABLE t_condcust(cust_code char(8), 
	name_text char(30), 
	cond_code char(3), 
	old_cond_code char(3)) with no LOG 

	OPEN WINDOW E131 with FORM "E131" 
	 CALL windecoration_e("E131") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 


	CALL scan_condsale() 

	CLOSE WINDOW E131 

END FUNCTION
################################################################################
# END FUNCTION E71_main()
################################################################################


################################################################################
# FUNCTION condsale_get_datasource()
#
#
################################################################################
FUNCTION condsale_get_datasource(p_filter)
	DEFINE p_filter BOOLEAN 
	DEFINE l_where_text STRING
	DEFINE l_query_text STRING 
	DEFINE l_idx SMALLINT
	DEFINE l_arr_rec_condsale DYNAMIC ARRAY OF RECORD --array[400] OF RECORD 
		scroll_flag char(1),
		cond_code LIKE condsale.cond_code, 
		desc_text LIKE condsale.desc_text, 
		prodline_disc_flag LIKE condsale.prodline_disc_flag, 
		tier_disc_flag LIKE condsale.tier_disc_flag 
	END RECORD
	
	IF p_filter THEN	
		CLEAR FORM 
		MESSAGE kandoomsg2("E",1001,"") 	#" Enter Selection Criteria - ESC TO Continue "
		CONSTRUCT BY NAME l_where_text ON 
			cond_code, 
			desc_text, 
			prodline_disc_flag, 
			tier_disc_flag 
	
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","E71","construct-condsale") 
	
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
	
		MESSAGE kandoomsg2("E",1002,"")	#MESSAGE " Searching database - please wait "
		LET l_query_text = 
			"SELECT * FROM condsale ", 
			"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code),"' ", 
			"AND ",l_where_text clipped," ", 
			"ORDER BY cond_code" 

		PREPARE s_condsale FROM l_query_text 
		DECLARE c_condsale cursor FOR s_condsale 

	LET l_idx = 0 
	FOREACH c_condsale INTO glob_rec_condsale.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_condsale[l_idx].scroll_flag = NULL 
		LET l_arr_rec_condsale[l_idx].cond_code = glob_rec_condsale.cond_code 
		LET l_arr_rec_condsale[l_idx].desc_text = glob_rec_condsale.desc_text 
		LET l_arr_rec_condsale[l_idx].tier_disc_flag = glob_rec_condsale.tier_disc_flag 
		LET l_arr_rec_condsale[l_idx].prodline_disc_flag = glob_rec_condsale.prodline_disc_flag 
		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF
	END FOREACH 

	MESSAGE kandoomsg2("U",9113,l_idx) #9113 l_idx records selected
	
	RETURN l_arr_rec_condsale	
END FUNCTION 
################################################################################
# END FUNCTION condsale_get_datasource()
################################################################################


################################################################################
# FUNCTION scan_condsale()
#
#
################################################################################
FUNCTION scan_condsale() 
	DEFINE l_cond_code LIKE condsale.cond_code
	DEFINE l_scroll_flag char(1)
	DEFINE l_arr_rec_condsale DYNAMIC ARRAY OF RECORD --array[400] OF RECORD 
		scroll_flag char(1),
		cond_code LIKE condsale.cond_code, 
		desc_text LIKE condsale.desc_text, 
		prodline_disc_flag LIKE condsale.prodline_disc_flag, 
		tier_disc_flag LIKE condsale.tier_disc_flag 
	END RECORD
--	DEFINE l_err_continue char(1)
	DEFINE l_err_message char(60)
	DEFINE i SMALLINT 
	DEFINE j SMALLINT
	DEFINE l_del_cnt SMALLINT
	DEFINE l_idx SMALLINT
	DEFINE l_arr_delete_id DYNAMIC ARRAY OF LIKE condsale.cond_code
	
	CALL condsale_get_datasource(FALSE) RETURNING l_arr_rec_condsale
	 
	MESSAGE kandoomsg2("E",1003,"") #" F1 TO Add - F2 TO Delete - RETURN TO Edit "
	DISPLAY ARRAY l_arr_rec_condsale TO sr_condsale.* ATTRIBUTE(UNBUFFERED)
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","E71","inp-arr-l_arr_rec_condsale") 
			CALL dialog.setActionHidden("ACCEPT",TRUE) #Hide Apply button
			CALL fgl_dialog_setkeylabel("CANCEL","Exit") #Hide Apply button
 			CALL dialog.setActionHidden("EDIT",NOT l_arr_rec_condsale.getSize())
 			CALL dialog.setActionHidden("DELETE",NOT l_arr_rec_condsale.getSize())
 			
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER"
			CALL l_arr_rec_condsale.clear()
			CALL condsale_get_datasource(TRUE) RETURNING l_arr_rec_condsale
			
		ON ACTION "REFRESH"
			CALL l_arr_rec_condsale.clear()
			 CALL windecoration_e("E131")		
			CALL condsale_get_datasource(FALSE) RETURNING l_arr_rec_condsale

		BEFORE ROW
			LET l_idx = arr_curr() 
				
--		ON ACTION ("EDIT","DOUBLECLICK") 
--			#AFTER FIELD scroll_flag
--			LET l_arr_rec_condsale[l_idx].scroll_flag = l_scroll_flag 
--			# DISPLAY l_arr_rec_condsale[l_idx].scroll_flag
--			#      TO sr_condsale[scrn].scroll_flag

	ON ACTION ("EDIT", "DOUBLECLICK")
--		BEFORE FIELD cond_code 
			IF l_arr_rec_condsale[l_idx].cond_code IS NOT NULL THEN 

				CALL process_condition("EDIT",l_arr_rec_condsale[l_idx].cond_code)	RETURNING l_arr_rec_condsale[l_idx].cond_code 
				CALL l_arr_rec_condsale.clear()
				CALL condsale_get_datasource(FALSE) RETURNING l_arr_rec_condsale

				--CALL condsale_get_datasource(FALSE) RETURNING l_arr_rec_condsale
				--SELECT desc_text, 
				--tier_disc_flag, 
				--prodline_disc_flag 
				--INTO l_arr_rec_condsale[l_idx].desc_text, 
				--l_arr_rec_condsale[l_idx].tier_disc_flag , 
				--l_arr_rec_condsale[l_idx].prodline_disc_flag 
				--FROM condsale 
				--WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				--AND cond_code = l_arr_rec_condsale[l_idx].cond_code 

			END IF 

			--NEXT FIELD scroll_flag 

		ON ACTION "ADD" 
--			IF arr_curr() < arr_count() THEN 
			CALL process_condition("ADD",l_arr_rec_condsale[l_idx+1].cond_code)	RETURNING l_cond_code 
			CALL l_arr_rec_condsale.clear()
			CALL condsale_get_datasource(FALSE) RETURNING l_arr_rec_condsale

--				SELECT "", 
--				cond_code, 
--				desc_text, 
--				tier_disc_flag, 
--				prodline_disc_flag 
--				INTO l_arr_rec_condsale[l_idx].* 
--				FROM condsale 
--				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
--				AND cond_code = l_cond_code 
--
--				IF status = NOTFOUND THEN 
--					#   FOR l_idx = arr_curr() TO arr_count()
--					#      LET l_arr_rec_condsale[l_idx].* = l_arr_rec_condsale[l_idx+1].*
--					#      IF scrn <= 13 THEN
--					#         DISPLAY l_arr_rec_condsale[l_idx].* TO sr_condsale[scrn].*
--					#
--					#         LET scrn = scrn + 1
--					#      END IF
--					#   END FOR
--					INITIALIZE l_arr_rec_condsale[l_idx].* TO NULL 
--				END IF 
--			ELSE 
--				IF l_idx > 1 THEN 
--					ERROR kandoomsg2("E",9001,"") 
--					# There are no more rows in the direction you are going "
--				END IF 
--			END IF

			 
--			NEXT FIELD scroll_flag 

		ON ACTION "DELETE" --f2 delete / SET DELETE marker
			IF (l_idx > 0) AND (l_idx <= l_arr_rec_condsale.getSize()) THEN  #data array must not be empty
				LET l_del_cnt = 0 
				FOR l_idx = 1 TO l_arr_rec_condsale.getsize() #check, what rows are selected AND if they can be deleted 
					IF dialog.isRowSelected("sr_condsale",l_idx) THEN
						IF cond_delete(l_arr_rec_condsale[l_idx].cond_code) THEN 
							LET l_del_cnt = l_del_cnt + 1
							CALL l_arr_delete_id.append(l_arr_rec_condsale[l_idx].cond_code) #if valid, add cond_Code to array
						END IF 
					END IF 
				END FOR 
			END IF

			IF l_del_cnt != 0 THEN #at least one row must be selected valid for deletion 
				IF kandoomsg("E",8001,l_del_cnt) = "Y" THEN 	#8001 Confirm TO Delete ",l_del_cnt,"Sales Condition(s)? (Y/N)"
					  
					LET l_err_message ="E71 - Deleting Sales Conditions " 
					GOTO bypass 
					LABEL recovery: 
					IF error_recover(l_err_message,status) = "N" THEN 
						EXIT PROGRAM 
					END IF 
					LABEL bypass: 
					WHENEVER ERROR GOTO recovery 
	
					BEGIN WORK 
	
					FOR l_idx = 1 TO l_arr_delete_id.getSize()
					
						DELETE FROM conddisc 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cond_code = l_arr_delete_id[l_idx]  #l_arr_rec_condsale[l_idx].cond_code 
	
						DELETE FROM proddisc 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND key_num = l_arr_delete_id[l_idx]  #l_arr_rec_condsale[l_idx].cond_code 
						AND type_ind = "1" 
	
						DELETE FROM condsale 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cond_code = l_arr_delete_id[l_idx]  #l_arr_rec_condsale[l_idx].cond_code 
	
					END FOR
					
					COMMIT WORK 
	
					WHENEVER ERROR stop 
				END IF 
			END IF 
		
 			#refresh data from DB
			CALL l_arr_rec_condsale.clear()
			CALL condsale_get_datasource(FALSE) RETURNING l_arr_rec_condsale

	END DISPLAY  
	#-----------------------------------------------------------------------------------------------------

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
	END IF 
END FUNCTION 
################################################################################
# END FUNCTION scan_condsale()
################################################################################


################################################################################
# FUNCTION init_cond(p_mode,p_cond_code)
#
#
################################################################################
FUNCTION init_cond(p_mode,p_cond_code) 
	DEFINE p_mode char(4) 
	DEFINE p_cond_code LIKE condsale.cond_code 
	DEFINE l_rec_conddisc RECORD LIKE conddisc.* 
	DEFINE l_rec_proddisc RECORD LIKE proddisc.* 

	INITIALIZE glob_rec_condsale.* TO NULL 
	DELETE FROM t_conddisc 
	DELETE FROM t_proddisc 
	DELETE FROM t_condcust 

	IF p_mode = "EDIT" THEN 
		SELECT * INTO glob_rec_condsale.* 
		FROM condsale 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cond_code = p_cond_code 
	ELSE 
		IF p_cond_code IS NULL THEN 
			RETURN 
		END IF 
		IF kandoomsg("E",8002,p_cond_code) = "N" THEN ## IMage new condition FROM ABC
			
			RETURN 
		END IF 
	END IF 

	DECLARE c1_conddisc cursor FOR 
	SELECT * FROM conddisc 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cond_code = p_cond_code 
	
	FOREACH c1_conddisc INTO l_rec_conddisc.* 
		INSERT INTO t_conddisc 
		VALUES (l_rec_conddisc.reqd_amt, 
		l_rec_conddisc.bonus_check_per, 
		l_rec_conddisc.disc_check_per, 
		l_rec_conddisc.disc_per) 
	END FOREACH
	 
	DECLARE c1_proddisc cursor FOR 
	SELECT * FROM proddisc 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_num = p_cond_code 
	AND type_ind = "1" 

	FOREACH c1_proddisc INTO l_rec_proddisc.* 
		INSERT INTO t_proddisc 
		VALUES (l_rec_proddisc.maingrp_code, 
		l_rec_proddisc.prodgrp_code, 
		l_rec_proddisc.part_code, 
		l_rec_proddisc.reqd_amt, 
		l_rec_proddisc.reqd_qty, 
		l_rec_proddisc.disc_per, 
		l_rec_proddisc.unit_sale_amt, 
		l_rec_proddisc.per_amt_ind) 
	END FOREACH
	 
END FUNCTION 
################################################################################
# END FUNCTION init_cond(p_mode,p_cond_code)
################################################################################


################################################################################
# FUNCTION process_condition(p_mode,p_cond_code)
#
#
################################################################################
FUNCTION process_condition(p_mode,p_cond_code) 
	DEFINE p_mode char(4) 
	DEFINE p_cond_code LIKE condsale.cond_code 

	OPEN WINDOW E132 with FORM "E132" 
	 CALL windecoration_e("E132") 

	CALL init_cond(p_mode,p_cond_code) 

	WHILE edit_header(p_mode) 

		MENU "Sales conditions" 
			BEFORE MENU 
				CALL publish_toolbar("kandoo","E71","menu-sales_condition") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON ACTION "SAVE" #COMMAND KEY("S",escape)"Save" " Save sales condition details "
				CALL update_database() 
				RETURNING p_cond_code 
				EXIT MENU 

			ON ACTION "TIERED DISCOUNT" 	#COMMAND "Tiered" " Include tiered discount in sales condition"
				OPEN WINDOW E136 with FORM "E136" 
				 CALL windecoration_e("E136") 

				CALL lineitem_entry() 

				CLOSE WINDOW E136 

			ON ACTION "PRODUCT DISCOUNT" 	#COMMAND "Line" " Include product line discount in sales condition"
				OPEN WINDOW E125 with FORM "E125" 
				 CALL windecoration_e("E125") 

				CALL proddisc_entry() #product line discount entry

				CLOSE WINDOW E125 

			ON ACTION "CUSTOMERS DISCOUNT"	#COMMAND "Customers"    " Add OR remove customers using this sales condition"
				OPTIONS INSERT KEY f36, 
				DELETE KEY f36 

				OPEN WINDOW E134 with FORM "E134" 
				 CALL windecoration_e("E134") 

				CALL scan_customer()

				CLOSE WINDOW E134 

			ON ACTION "Exit" #COMMAND KEY("E",INTERRUPT)"Exit" " RETURN TO edit condition"
				LET quit_flag = TRUE --huho: should i really understand this ? 
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

	CLOSE WINDOW E132 

	RETURN p_cond_code 
END FUNCTION 
################################################################################
# END FUNCTION process_condition(p_mode,p_cond_code)
################################################################################


################################################################################
# FUNCTION cond_delete(p_cond_code)
#
#
################################################################################
FUNCTION cond_delete(p_cond_code) 
	DEFINE p_cond_code LIKE condsale.cond_code 

	SELECT unique 1 FROM customer 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cond_code = p_cond_code 

	IF status = 0 THEN 
		ERROR kandoomsg2("E",7010,p_cond_code) #7010 Sales Condition assigned TO Customer, No Deletion
		RETURN FALSE 
	END IF 

	SELECT unique 1 FROM orderhead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cond_code = p_cond_code 
	AND status_ind != "C" 

	IF status = 0 THEN 
		ERROR kandoomsg2("E",7064,p_cond_code) #7064 Sales Condition exists on current sales orders
		RETURN FALSE 
	END IF 
	RETURN TRUE 

END FUNCTION
################################################################################
# END FUNCTION cond_delete(p_cond_code)
################################################################################