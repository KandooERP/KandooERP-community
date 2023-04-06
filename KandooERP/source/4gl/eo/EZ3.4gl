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
GLOBALS "../eo/EZ_GROUP_GLOBALS.4gl"  
GLOBALS "../eo/EZ3_GLOBALS.4gl"
############################################################
# FUNCTION EZ3_main() 
#
# EZ3 Allows the user TO enter AND maintain interval sales targets
############################################################
FUNCTION EZ3_main() 
	DEFER QUIT 
	DEFER INTERRUPT 
	
	CALL setModuleId("EZ3") 

	CALL db_statparms_get_rec(UI_ON,"1") RETURNING glob_rec_statparms.* 
	
	IF NOT db_statparms_get_rec_exists("1") THEN
		CALL fgl_winmessage("ERROR",kandoomsg("E",5004,""),"ERROR") 
		EXIT PROGRAM 
	END IF 
	
	LET glob_rec_year_type.year_num = glob_rec_statparms.year_num 
	LET glob_rec_year_type.type_code = glob_rec_statparms.mth_type_code 
	
	OPEN WINDOW E210 with FORM "E210" 
	 CALL windecoration_e("E210") 
	
	MENU " targets" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","EZ3","menu-Targets-1")

			DISPLAY BY NAME glob_rec_year_type.*	attribute(yellow) 

			SELECT unique 1 FROM stattype 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND type_code = glob_rec_year_type.type_code 
			IF status = NOTFOUND OR glob_rec_year_type.year_num IS NULL THEN 
				HIDE option 
					"SALES_TARGET_AREA", 
					"SALES_TARGET_TERRITORIES", 
					"SALES_TARGET_MANAGER", 
					"SALES_TARGET_PERSON", 
					"SALES_TARGET_CONDITION", 
					"SALES_TARGET_OFFER" 
			ELSE 
				SHOW option all 
			END IF 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
			
		COMMAND "SALES_TARGET_AREA" " Maintain sales targets FOR sales areas" 
			LET glob_temp_text = kandooword("stattarget.bdgt_type_ind","1") 
			DISPLAY glob_temp_text TO prompt_text 
			
			LET glob_temp_text = "SELECT desc_text FROM salearea ",	"WHERE cmpy_code = ? AND area_code = ?" 

			IF select_targ_cursor("1") THEN 
				CALL edit_targ("1",glob_temp_text) 
			END IF 

		COMMAND "SALES_TARGET_TERRITORIES" " Maintain sales targets FOR sales territories" 
			LET glob_temp_text = kandooword("stattarget.bdgt_type_ind","2") 
			DISPLAY glob_temp_text TO prompt_text 

			LET glob_temp_text = "SELECT desc_text FROM territory ", "WHERE cmpy_code = ? AND terr_code = ?" 
			IF select_targ_cursor("2") THEN 
				CALL edit_targ("2",glob_temp_text) 
			END IF 

		COMMAND "SALES_TARGET_MANAGER" " Maintain sales targets FOR sales managers" 
			LET glob_temp_text = kandooword("stattarget.bdgt_type_ind","3") 
			DISPLAY glob_temp_text TO prompt_text 

			LET glob_temp_text = "SELECT name_text FROM salesmgr ",	"WHERE cmpy_code = ? AND mgr_code = ?" 
			IF select_targ_cursor("3") THEN 
				CALL edit_targ("3",glob_temp_text) 
			END IF 

		COMMAND "SALES_TARGET_PERSON" " Maintain sales targets FOR sales person" 
			LET glob_temp_text = kandooword("stattarget.bdgt_type_ind","4") 
			DISPLAY glob_temp_text TO prompt_text 
			
			LET glob_temp_text = "SELECT name_text FROM salesperson ","WHERE cmpy_code = ? AND sale_code = ?" 
			IF select_targ_cursor("4") THEN 
				CALL edit_targ("4",glob_temp_text) 
			END IF 

		COMMAND "SALES_TARGET_CONDITION" " Maintain sales targets FOR sales conditions" 
			LET glob_temp_text = kandooword("stattarget.bdgt_type_ind","5") 
			DISPLAY glob_temp_text TO prompt_text 
			
			LET glob_temp_text = "SELECT desc_text FROM condsale ",	"WHERE cmpy_code = ? AND cond_code = ?" 
			IF select_targ_cursor("5") THEN 
				CALL edit_targ("5",glob_temp_text) 
			END IF 

		COMMAND "SALES_TARGET_OFFER" " Maintain sales targets FOR special offers" 
			LET glob_temp_text = kandooword("stattarget.bdgt_type_ind","6") 
			DISPLAY glob_temp_text TO prompt_text 
			
			LET glob_temp_text = "SELECT desc_text FROM offersale ", "WHERE cmpy_code = ? AND offer_code = ?" 
			IF select_targ_cursor("6") THEN 
				CALL edit_targ("6",glob_temp_text) 
			END IF 

		ON ACTION "PERIOD OPTIONS" --COMMAND "PERIOD OPTIONS" " Change current year AND/OR interval type" 
			IF int_options() THEN 
				SHOW option all 
			ELSE 
				HIDE option "SALES_TARGET_AREA" 
				HIDE option "SALES_TARGET_TERRITORIES" 
				HIDE option "SALES_TARGET_MANAGER" 
				HIDE option "SALES_TARGET_PERSON" 
				HIDE option "SALES_TARGET_CONDITION" 
				HIDE option "SALES_TARGET_OFFER" 
				HIDE option "Image"  #??? we have no menu option/item called "Image" !!! ??? !!! KEY F8 ??? 
			END IF 

			DISPLAY BY NAME glob_rec_year_type.*	attribute(yellow) 

		ON ACTION "CANCEL" --COMMAND KEY(INTERRUPT,"E")"Exit" " EXIT PROGRAM " 
			EXIT MENU 

	END MENU 

	LET int_flag = FALSE 
	LET quit_flag = FALSE 
END FUNCTION 
############################################################
# END FUNCTION EZ3_main() 
############################################################


############################################################
# FUNCTION int_options()
#
#
############################################################
FUNCTION int_options() 
	DEFINE l_rec_statint RECORD LIKE statint.* 
	DEFINE l_rec_stattype RECORD LIKE stattype.* 

	LET l_rec_statint.year_num = glob_rec_year_type.year_num 
	LET l_rec_statint.type_code = glob_rec_year_type.type_code 

	SELECT type_text INTO l_rec_stattype.type_text 
	FROM stattype 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND type_code = l_rec_statint.type_code
	 
	OPEN WINDOW E212 with FORM "E212" 
	 CALL windecoration_e("E212") -- albo kd-755
 
	MESSAGE kandoomsg2("E",1070,"") #1070 " Enter Year Number & Interval Type - ESC TO Continue" AT 1,1
	INPUT BY NAME 
		l_rec_statint.year_num, 
		l_rec_statint.type_code, 
		l_rec_stattype.type_text WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","EZ3","input-year_num-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "LOOKUP" infield (type_code) 
			LET glob_temp_text = show_inttype(glob_rec_kandoouser.cmpy_code,"") 
			IF glob_temp_text IS NOT NULL THEN 
				LET l_rec_statint.type_code = glob_temp_text 
			END IF 
			NEXT FIELD type_code 

		AFTER FIELD type_code 
			CLEAR type_text 
			IF l_rec_statint.type_code IS NULL THEN 
				ERROR kandoomsg2("E",9197,"") 			#9197" Type code must be entered"
				LET l_rec_statint.type_code = glob_rec_year_type.type_code 
				NEXT FIELD type_code 
			ELSE 
				SELECT type_text INTO l_rec_stattype.type_text 
				FROM stattype 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND type_code = l_rec_statint.type_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("E",9202,"")	#9202" Stat type dont exist"
					NEXT FIELD type_code 
				ELSE 
					DISPLAY BY NAME l_rec_stattype.type_text 
				END IF 
			END IF 

	END INPUT 

	CLOSE WINDOW E212 
	
	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
	ELSE 
		LET glob_rec_year_type.year_num = l_rec_statint.year_num 
		LET glob_rec_year_type.type_code = l_rec_statint.type_code 
	END IF 

	SELECT unique 1 FROM stattype 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND type_code = l_rec_statint.type_code 
	
	IF status = NOTFOUND 
	OR l_rec_statint.year_num IS NULL 
	OR l_rec_statint.year_num = 0 THEN 
		RETURN FALSE 
	ELSE 
		RETURN TRUE 
	END IF 

END FUNCTION 
############################################################
# END FUNCTION int_options()
############################################################


############################################################
# FUNCTION select_targ_cursor(p_type_ind)
#
#
############################################################
FUNCTION select_targ_cursor(p_type_ind) 
	DEFINE p_type_ind LIKE stattarget.bdgt_type_ind 
	DEFINE l_where_text STRING 
	DEFINE l_query_text STRING 
	DEFINE i SMALLINT 

--	FOR i = 1 TO 13 
--		CLEAR sr_stattarget[i].* 
--	END FOR 
	
	MESSAGE kandoomsg2("E",1001,"") #1001 " Enter Selection Criteria - ESC TO Continue "
	CONSTRUCT BY NAME l_where_text ON 
		stattarget.int_num, 
		statint.int_text, 
		stattarget.bdgt_type_code, 
		stattarget.bdgt_ind, 
		stattarget.bdgt_amt, 
		stattarget.bdgt_qty 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","EZ3","construct-int_num-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE
		LET l_where_text = " 1=1 " 
		RETURN FALSE 
	ELSE 
		MESSAGE kandoomsg2("E",1002,"") 	#1002 " Searching database - please wait "
		LET l_query_text = 
		"SELECT stattarget.* FROM stattarget,", 
		"statint ", 
		"WHERE stattarget.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND stattarget.year_num = '",glob_rec_year_type.year_num,"' ", 
		"AND stattarget.type_code = '",glob_rec_year_type.type_code,"' ", 
		"AND stattarget.bdgt_type_ind = '",p_type_ind,"' ", 
		"AND statint.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND statint.year_num = '",glob_rec_year_type.year_num,"' ", 
		"AND statint.type_code = '",glob_rec_year_type.type_code,"' ", 
		"AND statint.int_num = stattarget.int_num ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY 1,5,6,7,2,3,4" 
		PREPARE s_stattarget FROM l_query_text 
		DECLARE c_stattarget cursor FOR s_stattarget 
		RETURN TRUE 
	END IF 

END FUNCTION 
############################################################
# END FUNCTION select_targ_cursor_cursor(p_type_ind)
############################################################


############################################################
# FUNCTION edit_targ(p_type_ind,p_desc_text)
#
#
############################################################
FUNCTION edit_targ(p_type_ind,p_desc_text) 
	DEFINE p_type_ind LIKE stattarget.bdgt_type_ind 
	DEFINE p_desc_text STRING  
	DEFINE l_rec_stattarget RECORD LIKE stattarget.* 
	DEFINE l_arr_rec_stattarget DYNAMIC ARRAY OF 
	RECORD 
		scroll_flag char(1), 
		int_num LIKE stattarget.int_num, 
		int_text LIKE statint.int_text, 
		bdgt_type_code LIKE stattarget.bdgt_type_code, 
		type_text char(30), 
		bdgt_ind LIKE stattarget.bdgt_ind, 
		bdgt_amt LIKE stattarget.bdgt_amt, 
		bdgt_qty LIKE stattarget.bdgt_qty 
	END RECORD 
	DEFINE l_scroll_flag char(1) 
	DEFINE l_idx SMALLINT 

	PREPARE s_desc_text FROM p_desc_text 
	DECLARE c_desc_text cursor FOR s_desc_text
	 
	LET l_idx = 0 
	FOREACH c_stattarget INTO l_rec_stattarget.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_stattarget[l_idx].int_num = l_rec_stattarget.int_num 
		LET l_arr_rec_stattarget[l_idx].bdgt_type_code = l_rec_stattarget.bdgt_type_code 
		LET l_arr_rec_stattarget[l_idx].bdgt_ind = l_rec_stattarget.bdgt_ind 
		LET l_arr_rec_stattarget[l_idx].bdgt_amt = l_rec_stattarget.bdgt_amt 
		LET l_arr_rec_stattarget[l_idx].bdgt_qty = l_rec_stattarget.bdgt_qty 

		SELECT int_text INTO l_arr_rec_stattarget[l_idx].int_text 
		FROM statint 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND year_num = glob_rec_year_type.year_num 
		AND type_code = glob_rec_year_type.type_code 
		AND int_num = l_rec_stattarget.int_num 

		OPEN c_desc_text USING glob_rec_kandoouser.cmpy_code, l_rec_stattarget.bdgt_type_code 
		FETCH c_desc_text INTO glob_temp_text 

		IF status = 0 THEN 
			LET l_arr_rec_stattarget[l_idx].type_text = glob_temp_text 
		ELSE 
			LET l_arr_rec_stattarget[l_idx].type_text = "**********" 
		END IF 

	END FOREACH 

	IF l_idx = 0 THEN 
		ERROR kandoomsg2("E",9219,"") #9219"No sales targets satisfied selection criteria"
		SLEEP 2
	END IF 
	MESSAGE kandoomsg2("E",1071,"") #1071 " F1 TO Add - F2 TO Delete - RETURN TO Edit - F8 TO Image"

	OPTIONS INSERT KEY f1 

	INPUT ARRAY l_arr_rec_stattarget WITHOUT DEFAULTS FROM sr_stattarget.* ATTRIBUTES(UNBUFFERED,delete row = false, insert row = false, append row = false)
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","EZ3","input-arr-l_arr_rec_stattarget-1") 
			CALL dialog.setActionHidden("DELETE-ROW",NOT l_arr_rec_stattarget.getSize())
 			CALL dialog.setActionHidden("ACCEPT",NOT l_arr_rec_stattarget.getSize())

		BEFORE ROW 
			LET l_idx = arr_curr() 

			IF l_arr_rec_stattarget[l_idx].bdgt_type_code IS NOT NULL THEN 
				LET l_rec_stattarget.int_num = l_arr_rec_stattarget[l_idx].int_num 
				LET l_rec_stattarget.bdgt_type_code = l_arr_rec_stattarget[l_idx].bdgt_type_code 
			ELSE 
				INITIALIZE l_arr_rec_stattarget[l_idx].* TO NULL 
				LET l_rec_stattarget.int_num = NULL 
				LET l_rec_stattarget.bdgt_type_code = NULL 
			END IF 
			--NEXT FIELD scroll_flag 

		AFTER ROW 
			IF l_arr_rec_stattarget[l_idx].bdgt_ind IS NULL THEN 
				INITIALIZE l_arr_rec_stattarget[l_idx].* TO NULL 
			END IF 

		BEFORE INSERT 
			INITIALIZE l_arr_rec_stattarget[l_idx].* TO NULL 
			#         CLEAR sr_stattarget[scrn].*
			LET l_rec_stattarget.int_num = NULL 
			LET l_rec_stattarget.bdgt_type_code = NULL 

			IF arr_curr() < arr_count() OR l_idx = 1 THEN 
				LET l_arr_rec_stattarget[l_idx].bdgt_amt = 0 
				LET l_arr_rec_stattarget[l_idx].bdgt_qty = 0 
				NEXT FIELD int_num 
			ELSE 
				ERROR kandoomsg2("E",9001,"") 		#9001There are no more rows in the direction you are going
			END IF 


		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "LOOKUP" infield (int_num,int_text) 
			LET glob_temp_text = "year_num='",glob_rec_year_type.year_num,"' ", "AND type_code='",glob_rec_year_type.type_code,"'" 
			LET glob_temp_text = show_interval(glob_rec_kandoouser.cmpy_code,glob_temp_text) 

			OPTIONS INSERT KEY f1 

			IF glob_temp_text IS NOT NULL THEN 
				LET l_arr_rec_stattarget[l_idx].int_num = glob_temp_text 
				NEXT FIELD bdgt_type_code 
			END IF 
{
		#(control-b) infield(int_num) AND (control-b) infield(int_text) process the same code
		ON ACTION "LOOKUP" infield (int_text) 
			LET glob_temp_text = "year_num='",glob_rec_year_type.year_num,"' ", "AND type_code='",glob_rec_year_type.type_code,"'" 
			LET glob_temp_text = show_interval(glob_rec_kandoouser.cmpy_code,glob_temp_text)
			 
			OPTIONS INSERT KEY f1
			 
			IF glob_temp_text IS NOT NULL THEN 
				LET l_arr_rec_stattarget[l_idx].int_num = glob_temp_text 
				NEXT FIELD bdgt_type_code 
			END IF 
}
		ON ACTION "LOOKUP" infield (bdgt_type_code) 
			CASE p_type_ind 
				WHEN "1" 
					LET glob_temp_text = show_area(glob_rec_kandoouser.cmpy_code) 
				WHEN "2" 
					LET glob_temp_text = show_territory(glob_rec_kandoouser.cmpy_code,"") 
				WHEN "3" 
					LET glob_temp_text = show_salesmgr(glob_rec_kandoouser.cmpy_code,"") 
				WHEN "4" 
					LET glob_temp_text = show_sale(glob_rec_kandoouser.cmpy_code) 
				WHEN "5" 
					LET glob_temp_text = show_cond(glob_rec_kandoouser.cmpy_code,"") 
				WHEN "6" 
					LET glob_temp_text = show_offer(glob_rec_kandoouser.cmpy_code,"") 
			END CASE
			 
			OPTIONS INSERT KEY f1
			 
			IF glob_temp_text IS NOT NULL THEN 
				LET l_arr_rec_stattarget[l_idx].bdgt_type_code = glob_temp_text 
				NEXT FIELD bdgt_type_code 
			END IF 


		BEFORE FIELD scroll_flag 
			#         IF l_arr_rec_stattarget[l_idx].bdgt_type_code IS NOT NULL THEN
			#            DISPLAY l_arr_rec_stattarget[l_idx].*
			#                 TO sr_stattarget[scrn].*
			#
			#         ELSE
			#            CLEAR sr_stattarget[scrn].*
			#         END IF
			LET l_scroll_flag = l_arr_rec_stattarget[l_idx].scroll_flag 

		AFTER FIELD scroll_flag 
			LET l_arr_rec_stattarget[l_idx].scroll_flag = l_scroll_flag 
			#         DISPLAY l_arr_rec_stattarget[l_idx].*
			#              TO sr_stattarget[scrn].*

		BEFORE FIELD int_num 
			IF l_rec_stattarget.int_num IS NOT NULL THEN 
				NEXT FIELD bdgt_type_code 
			END IF 

		BEFORE FIELD int_text 
			IF l_arr_rec_stattarget[l_idx].int_num IS NOT NULL THEN 
				SELECT int_text INTO l_arr_rec_stattarget[l_idx].int_text 
				FROM statint 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND year_num = glob_rec_year_type.year_num 
				AND type_code = glob_rec_year_type.type_code 
				AND int_num = l_arr_rec_stattarget[l_idx].int_num 
			END IF 

		AFTER FIELD int_text 
			IF l_arr_rec_stattarget[l_idx].int_text IS NOT NULL THEN 
				DECLARE c_statint cursor FOR 
				SELECT int_num FROM statint 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND year_num = glob_rec_year_type.year_num 
				AND type_code = glob_rec_year_type.type_code 
				AND int_text = l_arr_rec_stattarget[l_idx].int_text 
				OPEN c_statint 
				FETCH c_statint INTO l_arr_rec_stattarget[l_idx].int_num 
			END IF 

			#      BEFORE FIELD bdgt_type_code
			#         DISPLAY l_arr_rec_stattarget[l_idx].*
			#              TO sr_stattarget[scrn].*

			IF l_rec_stattarget.bdgt_type_code IS NOT NULL THEN 
				NEXT FIELD bdgt_ind 
			END IF 

			IF l_arr_rec_stattarget[l_idx].int_num IS NULL THEN 
				MESSAGE kandoomsg2("E",9222,"") 			#9222" Interval must be entered"
				NEXT FIELD int_num 
			ELSE 
				SELECT unique 1 FROM statint 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND year_num = glob_rec_year_type.year_num 
				AND type_code = glob_rec_year_type.type_code 
				AND int_num = l_arr_rec_stattarget[l_idx].int_num 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("E",9223,"") 				#9223" Interval NOT found try window "
					NEXT FIELD int_num 
				END IF 
			END IF 

		BEFORE FIELD type_text 
			OPEN c_desc_text USING glob_rec_kandoouser.cmpy_code,l_arr_rec_stattarget[l_idx].bdgt_type_code 
			FETCH c_desc_text INTO l_arr_rec_stattarget[l_idx].type_text 
			IF status = NOTFOUND THEN 
				LET glob_temp_text = kandooword("stattarget.bdgt_type_ind",p_type_ind) 
				MESSAGE kandoomsg2("E",9220,glob_temp_text) 			#9220 Value does NOT exist - Try Window
				LET l_arr_rec_stattarget[l_idx].bdgt_type_code = NULL 
				NEXT FIELD bdgt_type_code 
			END IF 

			NEXT FIELD bdgt_ind 

		AFTER FIELD bdgt_ind 
			IF l_arr_rec_stattarget[l_idx].bdgt_ind IS NULL THEN 
				ERROR kandoomsg2("E",9221,"") 		#9221" Number of targets must be entered"
				NEXT FIELD bdgt_ind 
			END IF 

		AFTER FIELD bdgt_amt 
			IF l_arr_rec_stattarget[l_idx].bdgt_amt IS NULL THEN 
				LET l_arr_rec_stattarget[l_idx].bdgt_amt = 0 
				NEXT FIELD bdgt_amt 
			END IF 

		AFTER FIELD bdgt_qty 
			IF l_arr_rec_stattarget[l_idx].bdgt_qty IS NULL THEN 
				LET l_arr_rec_stattarget[l_idx].bdgt_qty = 0 
				NEXT FIELD bdgt_qty 
			END IF 
			NEXT FIELD scroll_flag 


		ON ACTION "DELETE-ROW" --ON KEY (f2) #delete 
			IF (l_idx > 0) AND (l_idx <= l_arr_rec_stattarget.getSize()) THEN
				IF l_arr_rec_stattarget[l_idx].int_num IS NOT NULL THEN 
					IF l_arr_rec_stattarget[l_idx].scroll_flag IS NULL THEN 
						LET l_arr_rec_stattarget[l_idx].scroll_flag = "*" 
					ELSE 
						LET l_arr_rec_stattarget[l_idx].scroll_flag = NULL 
					END IF 
				END IF 
--			NEXT FIELD scroll_flag 
			END IF
			
		ON ACTION "SALES_TARGET_IMAGING" --"Sales Targets Imaging" --ON KEY (f8) #Imaging
			CALL image_stattarget(p_type_ind) 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
	ELSE 
		MESSAGE kandoomsg2("E",1005,"") 
		FOR l_idx = 1 TO arr_count() 
			IF l_arr_rec_stattarget[l_idx].scroll_flag = "*" THEN 
				DELETE FROM stattarget 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND year_num = glob_rec_year_type.year_num 
				AND type_code = glob_rec_year_type.type_code 
				AND bdgt_type_ind = p_type_ind 
				AND int_num = l_arr_rec_stattarget[l_idx].int_num 
				AND bdgt_type_code = l_arr_rec_stattarget[l_idx].bdgt_type_code 
				AND bdgt_ind = l_arr_rec_stattarget[l_idx].bdgt_ind 
			END IF 
		END FOR 

		FOR l_idx = 1 TO arr_count() 
			WHENEVER ERROR GOTO recovery 
			IF l_arr_rec_stattarget[l_idx].scroll_flag IS NULL 
			AND l_arr_rec_stattarget[l_idx].bdgt_type_code IS NOT NULL 
			AND l_arr_rec_stattarget[l_idx].bdgt_ind IS NOT NULL THEN 
				UPDATE stattarget 
				SET 
					bdgt_amt = l_arr_rec_stattarget[l_idx].bdgt_amt, 
					bdgt_qty = l_arr_rec_stattarget[l_idx].bdgt_qty 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND year_num = glob_rec_year_type.year_num 
				AND type_code = glob_rec_year_type.type_code 
				AND bdgt_type_ind = p_type_ind 
				AND int_num = l_arr_rec_stattarget[l_idx].int_num 
				AND bdgt_type_code = l_arr_rec_stattarget[l_idx].bdgt_type_code 
				AND bdgt_ind = l_arr_rec_stattarget[l_idx].bdgt_ind 
				IF sqlca.sqlerrd[3] = 0 THEN 
					LET l_rec_stattarget.cmpy_code =glob_rec_kandoouser.cmpy_code 
					LET l_rec_stattarget.year_num = glob_rec_year_type.year_num 
					LET l_rec_stattarget.type_code = glob_rec_year_type.type_code 
					LET l_rec_stattarget.bdgt_type_ind = p_type_ind 
					LET l_rec_stattarget.int_num= l_arr_rec_stattarget[l_idx].int_num 
					LET l_rec_stattarget.bdgt_type_code = l_arr_rec_stattarget[l_idx].bdgt_type_code 
					LET l_rec_stattarget.bdgt_ind = l_arr_rec_stattarget[l_idx].bdgt_ind 
					LET l_rec_stattarget.bdgt_amt = l_arr_rec_stattarget[l_idx].bdgt_amt 
					LET l_rec_stattarget.bdgt_qty = l_arr_rec_stattarget[l_idx].bdgt_qty 
					INSERT INTO stattarget VALUES (l_rec_stattarget.*) 
				END IF 
			END IF 
			LABEL recovery: 
		END FOR 
		WHENEVER ERROR stop 
	END IF 

END FUNCTION 
############################################################
# END FUNCTION edit_targ(p_type_ind,p_desc_text)
############################################################

############################################################
# FUNCTION image_stattarget(p_type_ind)
#
# Imaging FUNCTION -allows bugets TO be imaged AT year,INT-type & interval
#                   level.  FOR one individual area,territory,offer...etc
#                   OR FOR all areas,territories,offers...etc
############################################################
FUNCTION image_stattarget(p_type_ind) 
	DEFINE p_type_ind char(1) 
	DEFINE l_rec_statint RECORD LIKE statint.* 
	DEFINE l_rec_stattarget RECORD LIKE stattarget.* 
	DEFINE l_rec_img_record 
		RECORD 
			src_year_num LIKE stattarget.year_num, 
			src_type_code LIKE stattarget.type_code, 
			src_int_num LIKE stattarget.int_num, 
			src_int_text LIKE statint.int_text, 
			src_bdgt_code LIKE stattarget.bdgt_type_code, 
			src_desc_text char(30), 
			tgt_year_num LIKE stattarget.year_num, 
			tgt_type_code LIKE stattarget.type_code, 
			tgt_int_num LIKE statint.int_num, 
			tgt_int_text LIKE statint.int_text, 
			tgt_bdgt_code LIKE stattarget.bdgt_type_code, 
			tgt_desc_text char(30), 
			budgt1_num char(1), 
			budgt2_num char(1), 
			budgt3_num char(1), 
			budgt4_num char(1), 
			budgt5_num char(1), 
			budgt6_num char(1), 
			budgt7_num char(1), 
			budgt8_num char(1), 
			budgt9_num char(1) 
		END RECORD 
		DEFINE l_arr_budgt_num array[9] OF char(1) 
		DEFINE l_where_text STRING 
		DEFINE l_query_text STRING 
		DEFINE i SMALLINT 

		LET glob_temp_text = kandooword("stattarget.bdgt_type_ind",p_type_ind) 
		LET glob_temp_text = glob_temp_text clipped,"........" 

		OPEN WINDOW E211 with FORM "E211" 
		 CALL windecoration_e("E211") -- albo kd-755 

		DISPLAY glob_temp_text TO src_prompt_text attribute(white)  
		DISPLAY glob_temp_text TO tgt_prompt_text attribute(white) 
		
		MESSAGE kandoomsg2("E",1072,"") 	#1072 Enter Image criteria - ESC TO Continue
		LET l_rec_img_record.src_year_num = glob_rec_year_type.year_num 
		LET l_rec_img_record.src_type_code = glob_rec_year_type.type_code 
		LET l_rec_img_record.src_int_num = NULL 
		LET l_rec_img_record.tgt_year_num = glob_rec_year_type.year_num 
		LET l_rec_img_record.tgt_type_code = glob_rec_year_type.type_code 
		LET l_rec_img_record.tgt_int_num = NULL 
		LET l_rec_img_record.budgt1_num = "Y" 
		LET l_rec_img_record.budgt2_num = "Y" 
		LET l_rec_img_record.budgt3_num = "Y" 
		LET l_rec_img_record.budgt4_num = "Y" 
		LET l_rec_img_record.budgt5_num = "Y" 
		LET l_rec_img_record.budgt6_num = "Y" 
		LET l_rec_img_record.budgt7_num = "Y" 
		LET l_rec_img_record.budgt8_num = "Y" 
		LET l_rec_img_record.budgt9_num = "Y" 


		INPUT BY NAME l_rec_img_record.* WITHOUT DEFAULTS 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","EZ3","input-l_rec_img_record-1") -- albo kd-502 

			ON ACTION "WEB-HELP" -- albo kd-370 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "LOOKUP" infield (src_type_code) 
				LET glob_temp_text = show_inttype(glob_rec_kandoouser.cmpy_code,"") 

				OPTIONS DELETE KEY f36, 
				INSERT KEY f1 

				IF glob_temp_text IS NOT NULL THEN 
					LET l_rec_img_record.src_type_code = glob_temp_text 
					NEXT FIELD src_type_code 
				END IF 

				#(control-b) infield(src_int_num) AND (control-b) infield(src_int_text) process the same code
			ON ACTION "LOOKUP" infield (src_int_num) 
				LET glob_temp_text = "1=1" 
				IF l_rec_img_record.src_year_num IS NOT NULL THEN 
					LET glob_temp_text = glob_temp_text clipped," ", "AND year_num='",l_rec_img_record.src_year_num,"'" 
				END IF 

				IF l_rec_img_record.src_type_code IS NOT NULL THEN 
					LET glob_temp_text = glob_temp_text clipped," ", "AND type_code='",l_rec_img_record.src_type_code,"'" 
				END IF 
				LET glob_temp_text = show_interval(glob_rec_kandoouser.cmpy_code,glob_temp_text) 

				OPTIONS DELETE KEY f36, 
				INSERT KEY f1 

				IF glob_temp_text IS NOT NULL THEN 
					LET l_rec_img_record.src_int_num = glob_temp_text 
					NEXT FIELD src_int_num 
				END IF 

			ON ACTION "LOOKUP" infield (src_int_text) 
				LET glob_temp_text = "1=1" 
				IF l_rec_img_record.src_year_num IS NOT NULL THEN 
					LET glob_temp_text = glob_temp_text clipped," ", "AND year_num='",l_rec_img_record.src_year_num,"'" 
				END IF 
				IF l_rec_img_record.src_type_code IS NOT NULL THEN 
					LET glob_temp_text = glob_temp_text clipped," ", "AND type_code='",l_rec_img_record.src_type_code,"'" 
				END IF 

				LET glob_temp_text = show_interval(glob_rec_kandoouser.cmpy_code,glob_temp_text) 

				OPTIONS INSERT KEY f1 

				IF glob_temp_text IS NOT NULL THEN 
					LET l_rec_img_record.src_int_num = glob_temp_text 
					NEXT FIELD src_int_num 
				END IF 


			ON ACTION "LOOKUP" infield (src_bdgt_code) 
				CASE p_type_ind 
					WHEN "1" 
						LET glob_temp_text = show_area(glob_rec_kandoouser.cmpy_code) 
					WHEN "2" 
						LET glob_temp_text = show_territory(glob_rec_kandoouser.cmpy_code,"") 
					WHEN "3" 
						LET glob_temp_text = show_salesmgr(glob_rec_kandoouser.cmpy_code,"") 
					WHEN "4" 
						LET glob_temp_text = show_sale(glob_rec_kandoouser.cmpy_code) 
					WHEN "5" 
						LET glob_temp_text = show_cond(glob_rec_kandoouser.cmpy_code,"") 
					WHEN "6" 
						LET glob_temp_text = show_offer(glob_rec_kandoouser.cmpy_code,"") 
				END CASE 

				OPTIONS INSERT KEY f1 

				IF glob_temp_text IS NOT NULL THEN 
					LET l_rec_img_record.src_bdgt_code = glob_temp_text 
					NEXT FIELD src_bdgt_code 
				END IF 

			ON ACTION "LOOKUP" infield (tgt_bdgt_code) 
				CASE p_type_ind 
					WHEN "1" 
						LET glob_temp_text = show_area(glob_rec_kandoouser.cmpy_code) 
					WHEN "2" 
						LET glob_temp_text = show_territory(glob_rec_kandoouser.cmpy_code,"") 
					WHEN "3" 
						LET glob_temp_text = show_salesmgr(glob_rec_kandoouser.cmpy_code,"") 
					WHEN "4" 
						LET glob_temp_text = show_sale(glob_rec_kandoouser.cmpy_code) 
					WHEN "5" 
						LET glob_temp_text = show_cond(glob_rec_kandoouser.cmpy_code,"") 
					WHEN "6" 
						LET glob_temp_text = show_offer(glob_rec_kandoouser.cmpy_code,"") 
				END CASE 

				OPTIONS INSERT KEY f1 

				IF glob_temp_text IS NOT NULL THEN 
					LET l_rec_img_record.tgt_bdgt_code = glob_temp_text 
					NEXT FIELD tgt_bdgt_code 
				END IF 

			ON ACTION "LOOKUP" infield (tgt_type_code) 
				LET glob_temp_text = show_inttype(glob_rec_kandoouser.cmpy_code,"") 

				OPTIONS INSERT KEY f1 

				IF glob_temp_text IS NOT NULL THEN 
					LET l_rec_img_record.tgt_type_code = glob_temp_text 
					NEXT FIELD tgt_type_code 
				END IF 

				#(control-b) infield(tgt_int_num) AND (control-b) infield(tgt_int_text) process the same code
			ON ACTION "LOOKUP" infield (tgt_int_num) 
				LET glob_temp_text = "1=1" 
				IF l_rec_img_record.tgt_year_num IS NOT NULL THEN 
					LET glob_temp_text = glob_temp_text clipped," ", 
					"AND year_num='",l_rec_img_record.tgt_year_num,"'" 
				END IF 
				IF l_rec_img_record.tgt_type_code IS NOT NULL THEN 
					LET glob_temp_text = glob_temp_text clipped," ", 
					"AND type_code='",l_rec_img_record.tgt_type_code,"'" 
				END IF 

				LET glob_temp_text = show_interval(glob_rec_kandoouser.cmpy_code,glob_temp_text) 

				OPTIONS INSERT KEY f1 

				IF glob_temp_text IS NOT NULL THEN 
					LET l_rec_img_record.tgt_int_num = glob_temp_text 
					NEXT FIELD tgt_int_num 
				END IF 

			ON ACTION "LOOKUP" infield (tgt_int_text) 
				LET glob_temp_text = "1=1" 

				IF l_rec_img_record.tgt_year_num IS NOT NULL THEN 
					LET glob_temp_text = glob_temp_text clipped," ", 
					"AND year_num='",l_rec_img_record.tgt_year_num,"'" 
				END IF 

				IF l_rec_img_record.tgt_type_code IS NOT NULL THEN 
					LET glob_temp_text = glob_temp_text clipped," ", 
					"AND type_code='",l_rec_img_record.tgt_type_code,"'" 
				END IF 

				LET glob_temp_text = show_interval(glob_rec_kandoouser.cmpy_code,glob_temp_text) 

				OPTIONS INSERT KEY f1 

				IF glob_temp_text IS NOT NULL THEN 
					LET l_rec_img_record.tgt_int_num = glob_temp_text 
					NEXT FIELD tgt_int_num 
				END IF 

			AFTER FIELD src_type_code 
				IF l_rec_img_record.src_type_code IS NOT NULL THEN 
					SELECT unique 1 FROM stattype 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND type_code = l_rec_img_record.src_type_code 
					IF status = NOTFOUND THEN 
						ERROR kandoomsg2("E",9202,"") 
						NEXT FIELD src_type_code 
					END IF 
					
					LET l_rec_img_record.tgt_type_code = l_rec_img_record.src_type_code 
					DISPLAY BY NAME l_rec_img_record.tgt_type_code 

				END IF 

			AFTER FIELD src_int_num 
				IF l_rec_img_record.src_int_num IS NOT NULL THEN 
					IF l_rec_img_record.src_year_num IS NULL 
					OR l_rec_img_record.src_type_code IS NULL THEN 
						
						#------------------------------------------------------
						#7078 Cannot enter an interval without year amd type"
						NEXT FIELD src_type_code 
					ELSE 
						SELECT int_text INTO l_rec_img_record.src_int_text 
						FROM statint 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND year_num = l_rec_img_record.src_year_num 
						AND type_code = l_rec_img_record.src_type_code 
						AND int_num = l_rec_img_record.src_int_num 
						IF status = NOTFOUND THEN 
							ERROR kandoomsg2("E",9223,"") 
							NEXT FIELD src_int_num 
						END IF 
						
						LET l_rec_img_record.tgt_year_num = l_rec_img_record.src_year_num 
						LET l_rec_img_record.tgt_type_code = l_rec_img_record.src_type_code 
						LET l_rec_img_record.tgt_int_num = l_rec_img_record.src_int_num 
						LET l_rec_img_record.tgt_int_text = l_rec_img_record.src_int_text 
						
						DISPLAY BY NAME l_rec_img_record.* 

					END IF 
				END IF 

			AFTER FIELD src_int_text 
				IF l_rec_img_record.src_int_text IS NOT NULL THEN 
					LET glob_temp_text = "1=1" 
					IF l_rec_img_record.src_year_num IS NOT NULL THEN 
						LET glob_temp_text = glob_temp_text clipped," ", "AND year_num='",l_rec_img_record.src_year_num,"'" 
					END IF 
					
					IF l_rec_img_record.src_type_code IS NOT NULL THEN 
						LET glob_temp_text = glob_temp_text clipped," ", "AND type_code='",l_rec_img_record.src_type_code,"'" 
					END IF 
					
					LET l_query_text =
						"SELECT * FROM statint ", 
						"WHERE cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
						"AND int_text='",l_rec_img_record.src_int_text,"' ", 
						"AND ",glob_temp_text clipped 
					
					PREPARE s1_statint FROM l_query_text 
					DECLARE c1_statint cursor FOR s1_statint 
					
					OPEN c1_statint 
					FETCH c1_statint INTO l_rec_statint.* 
					
					IF status = NOTFOUND THEN 
						ERROR kandoomsg2("E",9223,"") 
						NEXT FIELD src_int_num 
					ELSE 
						LET l_rec_img_record.src_year_num = l_rec_statint.year_num 
						LET l_rec_img_record.src_type_code = l_rec_statint.type_code 
						LET l_rec_img_record.src_int_num = l_rec_statint.int_num 
						LET l_rec_img_record.src_int_text = l_rec_statint.int_text 
						LET l_rec_img_record.tgt_year_num = l_rec_statint.year_num 
						LET l_rec_img_record.tgt_type_code = l_rec_statint.type_code 
						LET l_rec_img_record.tgt_int_num = l_rec_statint.int_num 
						LET l_rec_img_record.tgt_int_text = l_rec_statint.int_text 
						DISPLAY BY NAME l_rec_img_record.* 

					END IF 
				END IF 

			AFTER FIELD src_bdgt_code 
				CLEAR src_desc_text 
				IF l_rec_img_record.src_bdgt_code IS NOT NULL THEN 
					OPEN c_desc_text USING glob_rec_kandoouser.cmpy_code,l_rec_img_record.src_bdgt_code 
					FETCH c_desc_text INTO l_rec_img_record.src_desc_text 
					IF status = NOTFOUND THEN 
						LET glob_temp_text=kandooword("stattarget.bdgt_type_ind",p_type_ind) 
						
						ERROR kandoomsg2("E",9220,glob_temp_text) 					#9220 Value does NOT exist - Try Window
						NEXT FIELD src_bdgt_code 
					ELSE 
						LET l_rec_img_record.tgt_bdgt_code = l_rec_img_record.src_bdgt_code 
						DISPLAY BY NAME l_rec_img_record.src_desc_text, 
						l_rec_img_record.tgt_bdgt_code 

					END IF 
				END IF 

			AFTER FIELD tgt_type_code 
				IF l_rec_img_record.tgt_type_code IS NOT NULL THEN 
					SELECT unique 1 FROM stattype 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND type_code = l_rec_img_record.tgt_type_code 
					IF status = NOTFOUND THEN 
						ERROR kandoomsg2("E",9202,"") 
						NEXT FIELD tgt_type_code 
					END IF 
				END IF 

			AFTER FIELD tgt_int_num 
				IF l_rec_img_record.tgt_int_num IS NOT NULL THEN 
					IF l_rec_img_record.tgt_year_num IS NULL 
					OR l_rec_img_record.tgt_type_code IS NULL THEN 
						#7078 Cannot enter an interval without year amd type"
						NEXT FIELD tgt_type_code 
					ELSE 
						SELECT int_text INTO l_rec_img_record.tgt_int_text 
						FROM statint 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND year_num = l_rec_img_record.tgt_year_num 
						AND type_code = l_rec_img_record.tgt_type_code 
						AND int_num = l_rec_img_record.tgt_int_num 
						IF status = NOTFOUND THEN 
							ERROR kandoomsg2("E",9223,"") 
							NEXT FIELD tgt_int_num 
						ELSE 
							DISPLAY BY NAME l_rec_img_record.* 
						END IF 
					END IF 
				END IF 

			AFTER FIELD tgt_int_text 
				IF l_rec_img_record.tgt_int_text IS NOT NULL THEN 
					LET glob_temp_text = "1=1"
					 
					IF l_rec_img_record.tgt_year_num IS NOT NULL THEN 
						LET glob_temp_text = glob_temp_text clipped," ",	"AND year_num='",l_rec_img_record.tgt_year_num,"'" 
					END IF
					 
					IF l_rec_img_record.tgt_type_code IS NOT NULL THEN 
						LET glob_temp_text = glob_temp_text clipped," ", "AND type_code='",l_rec_img_record.tgt_type_code,"'" 
					END IF
					 
					LET l_query_text =
						"SELECT * FROM statint ", 
						"WHERE cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
						"AND int_text='",l_rec_img_record.tgt_int_text,"' ", 
						"AND ",glob_temp_text clipped 
					
					PREPARE s2_statint FROM l_query_text 
					DECLARE c2_statint cursor FOR s2_statint 
					OPEN c2_statint 
					FETCH c2_statint INTO l_rec_statint.* 
					IF status = NOTFOUND THEN 
						ERROR kandoomsg2("E",9223,"") 
						NEXT FIELD tgt_int_num 
					ELSE 
						LET l_rec_img_record.tgt_year_num = l_rec_statint.year_num 
						LET l_rec_img_record.tgt_type_code = l_rec_statint.type_code 
						LET l_rec_img_record.tgt_int_num = l_rec_statint.int_num 
						LET l_rec_img_record.tgt_int_text = l_rec_statint.int_text 
						DISPLAY BY NAME l_rec_img_record.* 

					END IF 
				END IF 

			AFTER FIELD tgt_bdgt_code 
				CLEAR tgt_desc_text 
				IF l_rec_img_record.tgt_bdgt_code IS NOT NULL THEN 
					OPEN c_desc_text USING glob_rec_kandoouser.cmpy_code,l_rec_img_record.tgt_bdgt_code 
					FETCH c_desc_text INTO l_rec_img_record.tgt_desc_text 
					IF status = NOTFOUND THEN 
						LET glob_temp_text=kandooword("stattarget.bdgt_type_ind",p_type_ind) 
						ERROR kandoomsg2("E",9220,glob_temp_text) 					#9220 Value does NOT exist - Try Window
						NEXT FIELD tgt_bdgt_code 
					ELSE 
						DISPLAY BY NAME l_rec_img_record.* 

					END IF 
				END IF 

			AFTER INPUT 
				IF l_rec_img_record.src_year_num IS NULL THEN 
					ERROR kandoomsg2("E",9224,"") 			#9224 Source Year must be entered "
					NEXT FIELD src_year_num 
				END IF 
				
				IF l_rec_img_record.tgt_year_num IS NULL THEN 
					ERROR kandoomsg2("E",9225,"")					#9225 target Year must be entered "
					LET l_rec_img_record.tgt_year_num = l_rec_img_record.src_year_num 
					NEXT FIELD tgt_year_num 
				END IF 

		END INPUT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
		ELSE 
			MESSAGE kandoomsg2("E",1002,"") 
			LET l_where_text = "bdgt_type_ind = '",p_type_ind,"' ", "AND year_num = '",l_rec_img_record.src_year_num,"'" 
			
			IF l_rec_img_record.src_type_code IS NOT NULL THEN 
				LET l_where_text = l_where_text clipped," ", 	"AND type_code = '",l_rec_img_record.src_type_code,"'" 
			END IF 
			
			IF l_rec_img_record.src_int_num IS NOT NULL THEN 
				LET l_where_text = l_where_text clipped," ", 	"AND int_num = '",l_rec_img_record.src_int_num,"'" 
			END IF 
			
			IF l_rec_img_record.src_bdgt_code IS NOT NULL THEN 
				LET l_where_text = l_where_text clipped," ", 	"AND bdgt_type_code = '",l_rec_img_record.src_bdgt_code,"'" 
			END IF 
			
			LET l_arr_budgt_num[1] = l_rec_img_record.budgt1_num 
			LET l_arr_budgt_num[2] = l_rec_img_record.budgt2_num 
			LET l_arr_budgt_num[3] = l_rec_img_record.budgt3_num 
			LET l_arr_budgt_num[4] = l_rec_img_record.budgt4_num 
			LET l_arr_budgt_num[5] = l_rec_img_record.budgt5_num 
			LET l_arr_budgt_num[6] = l_rec_img_record.budgt6_num 
			LET l_arr_budgt_num[7] = l_rec_img_record.budgt7_num 
			LET l_arr_budgt_num[8] = l_rec_img_record.budgt8_num 
			LET l_arr_budgt_num[9] = l_rec_img_record.budgt9_num 
			LET glob_temp_text = NULL 

			FOR i = 1 TO 9 
				IF l_arr_budgt_num[i] = "Y" THEN 
					LET glob_temp_text = glob_temp_text clipped,",",i USING "<<<<" 
				END IF 
			END FOR 

			LET glob_temp_text[1,1] = "(" 
			LET glob_temp_text = glob_temp_text clipped,")" 

			IF length(glob_temp_text) > 2 THEN 
				LET l_where_text = l_where_text clipped," AND bdgt_ind in ",glob_temp_text 
			END IF 

			LET l_query_text = 
				"SELECT count(*) FROM stattarget ", 
				"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
				"AND ",l_where_text clipped 
			PREPARE s_count FROM l_query_text 
			DECLARE c_count cursor FOR s_count 

			OPEN c_count 
			FETCH c_count INTO i 

			IF i = 0 THEN 
				ERROR kandoomsg2("E",7079,"") 			#7079" No sales targets satisfied imaging criteria

			ELSE 

				IF kandoomsg("E",8028,i) = "Y" THEN 			#8027 Image sales targets (Y/N)?
					MESSAGE kandoomsg2("E",1005,"") 				#1005 Updating database - so wait
					LET l_query_text = 
						"SELECT * FROM stattarget ", 
						"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
						"AND ",l_where_text clipped 

					PREPARE s2_stattarget FROM l_query_text 
					DECLARE c2_stattarget cursor FOR s2_stattarget 

					LET i = 0 

					FOREACH c2_stattarget INTO l_rec_stattarget.* 
						LET l_rec_stattarget.year_num = l_rec_img_record.tgt_year_num
						 
						IF l_rec_img_record.tgt_type_code IS NOT NULL THEN 
							LET l_rec_stattarget.type_code = l_rec_img_record.tgt_type_code 
						END IF
						 
						IF l_rec_img_record.tgt_int_num IS NOT NULL THEN 
							LET l_rec_stattarget.int_num = l_rec_img_record.tgt_int_num 
						END IF
						 
						IF l_rec_img_record.tgt_bdgt_code IS NOT NULL THEN 
							LET l_rec_stattarget.bdgt_type_code = l_rec_img_record.tgt_bdgt_code 
						END IF
						 
						SELECT unique 1 FROM statint 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND year_num = l_rec_stattarget.year_num 
						AND type_code = l_rec_stattarget.type_code 
						AND int_num = l_rec_stattarget.int_num 
						IF status = 0 THEN 
							SELECT unique 1 FROM stattarget 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND year_num = l_rec_stattarget.year_num 
							AND type_code = l_rec_stattarget.type_code 
							AND int_num = l_rec_stattarget.int_num 
							AND bdgt_type_ind = l_rec_stattarget.bdgt_type_ind 
							AND bdgt_type_code = l_rec_stattarget.bdgt_type_code 
							AND bdgt_ind = l_rec_stattarget.bdgt_ind 
							IF status = NOTFOUND THEN
							 
								INSERT INTO stattarget VALUES (l_rec_stattarget.*)
								 
								LET i = i + 1 
							END IF 
						ELSE 
							LET int_flag = TRUE 
						END IF 
					END FOREACH
					 
					IF int_flag OR quit_flag THEN 
						LET int_flag = FALSE 
						LET quit_flag = FALSE 
						ERROR kandoomsg2("E",7080,i) 					#7080" Not all ints SET up - Not all targets added "
					ELSE 
						MESSAGE kandoomsg2("E",7081,i) 					#7081 Successful addition of 555 targets
					END IF 
				END IF 
			END IF 
		END IF 

		CLOSE WINDOW E211 

END FUNCTION 
############################################################
# END FUNCTION image_stattarget(p_type_ind)
############################################################