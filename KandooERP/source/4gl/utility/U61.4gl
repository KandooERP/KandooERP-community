{
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

	Source code beautified by beautify.pl on 2020-01-03 18:54:46	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../utility/U_UT_GLOBALS.4gl" 


###################################################################
# MAIN
#
# U61 maintains statistic interval type codes
###################################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("U61") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_u_ut() #init utility module 

	OPEN WINDOW u212 with FORM "U212" 
	CALL windecoration_u("U212") 

	#   WHILE select_type()
	CALL scan_type() 
	#   END WHILE
	CLOSE WINDOW u212 
END MAIN 


###################################################################
# FUNCTION select_type()
#
#
###################################################################
FUNCTION select_type(p_filter) 
	DEFINE p_filter boolean 
	DEFINE query_text STRING 
	DEFINE where_text STRING 
	DEFINE idx SMALLINT 
	DEFINE l_rec_stattype RECORD LIKE stattype.* 
	DEFINE l_arr_rec_stattype DYNAMIC ARRAY OF --array[100] OF 
	RECORD 
		scroll_flag CHAR(1), 
		type_code LIKE stattype.type_code, 
		type_text LIKE stattype.type_text, 
		type_ind LIKE stattype.type_ind 
	END RECORD 
	DEFINE l_msgresp LIKE language.yes_flag
	
	IF p_filter THEN 
		CLEAR FORM 
		LET l_msgresp = kandoomsg("E",1001,"") 
		#1001 Enter selection criteria - ESC TO continue
		CONSTRUCT BY NAME where_text ON type_code, 
		type_text, 
		type_ind 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","U61","construct-sattype") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 


		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET where_text = " 1=1 " 
		END IF 

	ELSE 
		LET where_text = " 1=1 " 
	END IF 

	LET l_msgresp = kandoomsg("E",1002,"") 
	#1002 Searching database - please wait
	LET query_text = "SELECT * FROM stattype ", 
	"WHERE cmpy_code ='",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND ",where_text clipped," ", 
	"ORDER BY cmpy_code, type_code" 
	PREPARE s_stattype FROM query_text 
	DECLARE c_stattype CURSOR FOR s_stattype 

	LET idx = 0 
	FOREACH c_stattype INTO l_rec_stattype.* 
		LET idx = idx + 1 
		LET l_arr_rec_stattype[idx].scroll_flag = NULL 
		LET l_arr_rec_stattype[idx].type_code = l_rec_stattype.type_code 
		LET l_arr_rec_stattype[idx].type_text = l_rec_stattype.type_text 
		LET l_arr_rec_stattype[idx].type_ind = l_rec_stattype.type_ind 
		#      IF idx = 100 THEN
		#         LET l_msgresp = kandoomsg("E",9195,"100")
		#         #9195 " First ??? stattypes selected only"
		#         EXIT FOREACH
		#      END IF
	END FOREACH 
	IF idx = 0 THEN 
		LET l_msgresp=kandoomsg("E",9196,"") 
		#9196 " No interval types satisfied the selection criteria"
		LET idx = 1 
	END IF 

	RETURN l_arr_rec_stattype 
END FUNCTION 


###################################################################
# FUNCTION scan_type()
#
#
###################################################################
FUNCTION scan_type() 
	DEFINE l_rec_stattype RECORD LIKE stattype.* 
	DEFINE l_scroll_flag CHAR(1) 
	DEFINE l_arr_rec_stattype DYNAMIC ARRAY OF --array[100] OF 
	RECORD 
		scroll_flag CHAR(1), 
		type_code LIKE stattype.type_code, 
		type_text LIKE stattype.type_text, 
		type_ind LIKE stattype.type_ind 
	END RECORD 
	DEFINE l_rowid INTEGER 
	DEFINE idx SMALLINT 
	DEFINE i SMALLINT
	DEFINE l_del_cnt SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag
	
	OPTIONS INSERT KEY f1 
	--DELETE KEY f36 


	CALL select_type(false) RETURNING l_arr_rec_stattype 

	#   CALL set_count(idx)
	LET l_msgresp = kandoomsg("E",1003,"") 
	# "F1 TO add, RETURN on line TO change, F2 TO delete"
	INPUT ARRAY l_arr_rec_stattype WITHOUT DEFAULTS FROM sr_stattype.* attributes(UNBUFFERED, append ROW = false, auto append = false, DELETE ROW = false, INSERT ROW = false) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","U61","input-arr-stattype") 
			CALL dialog.setActionHidden("EDIT", NOT l_arr_rec_stattype.getSize())

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER" 
			CALL select_type(true) RETURNING l_arr_rec_stattype 

		BEFORE ROW 
			LET idx = arr_curr() 

		BEFORE FIELD scroll_flag 
			LET idx = arr_curr() 
			#         LET scrn = scr_line()
			LET l_scroll_flag = l_arr_rec_stattype[idx].scroll_flag 
			#         DISPLAY l_arr_rec_stattype[idx].*
			#              TO sr_stattype[scrn].*

		AFTER FIELD scroll_flag 
			LET l_arr_rec_stattype[idx].scroll_flag = l_scroll_flag 
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF l_arr_rec_stattype[idx+1].type_code IS NULL 
				OR arr_curr() >= arr_count() THEN 
					LET l_msgresp = kandoomsg("E",9001,"") 
					# There are no more rows in the direction you are going.
					NEXT FIELD scroll_flag 
				END IF 
			END IF 

		ON ACTION ("EDIT","DOUBLECLICK") 
			#      	NEXT FIELD type_code
			#
			#      BEFORE FIELD type_code
			IF edit_type(l_arr_rec_stattype[idx].type_code) THEN 
				SELECT type_code, 
				type_text, 
				type_ind 
				INTO l_arr_rec_stattype[idx].type_code, 
				l_arr_rec_stattype[idx].type_text, 
				l_arr_rec_stattype[idx].type_ind 
				FROM stattype 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND type_code = l_arr_rec_stattype[idx].type_code 
			END IF 
			CALL select_type(false) RETURNING l_arr_rec_stattype 
			NEXT FIELD scroll_flag 

		ON ACTION "NEW" 
			#      BEFORE INSERT
			#         IF arr_curr() < arr_count() THEN
			LET l_rowid = edit_type("") 
			#            SELECT type_code,
			#                   type_text,
			#                   type_ind
			#              INTO l_arr_rec_stattype[idx].type_code,
			#                   l_arr_rec_stattype[idx].type_text,
			#                   l_arr_rec_stattype[idx].type_ind
			#              FROM stattype
			#             WHERE rowid = l_rowid
			#
			#            IF STATUS = NOTFOUND THEN
			#               FOR idx = arr_curr() TO arr_count()
			#                  LET l_arr_rec_stattype[idx].* = l_arr_rec_stattype[idx+1].*
			#                  IF scrn <= 14 THEN
			#                     DISPLAY l_arr_rec_stattype[idx].*
			#                          TO sr_stattype[scrn].*
			#
			#                     LET scrn = scrn + 1
			#                  END IF
			#               END FOR
			#               INITIALIZE l_arr_rec_stattype[idx].* TO NULL
			#            END IF
			#END IF
			CALL select_type(false) RETURNING l_arr_rec_stattype 
			NEXT FIELD scroll_flag 

		ON ACTION "DELETE" #ON KEY (F2) --delete marker
		#count how many are selected for delete 
		LET l_del_cnt = 0
		FOR i = 1 TO l_arr_rec_stattype.getLength()
			IF l_arr_rec_stattype[i].scroll_flag = "*" THEN
				LET l_del_cnt = l_del_cnt + 1
			END IF
		END FOR
		#if none is selected, select current row
		IF l_del_cnt = 0 THEN
			LET l_arr_rec_stattype[idx].scroll_flag = "*"
			LET l_del_cnt = 1
		END IF
		IF kandoomsg("E",8023,l_del_cnt) = "Y" THEN	#8023 Confirm TO Delete ",l_del_cnt," stattype(s)? (Y/N)"
			FOR i = 1 TO l_arr_rec_stattype.getLength()
				IF l_arr_rec_stattype[i].scroll_flag = "*" THEN
					IF delete_type(l_arr_rec_stattype[i].type_code) THEN 
						DELETE FROM stattype 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND type_code = l_arr_rec_stattype[i].type_code 
					END IF 
				END IF
			END FOR
			#Refresh input data array from DB
			CALL select_type(false) RETURNING l_arr_rec_stattype 			
		END IF

{		
		IF l_del_cnt > 0 THEN 
			IF kandoomsg("E",8023,l_del_cnt) = "Y" THEN	#8023 Confirm TO Delete ",l_del_cnt," stattype(s)? (Y/N)"
				LET l_msgresp = kandoomsg("E",1005,"") 

				FOR idx = 1 TO arr_count() 
					IF l_arr_rec_stattype[idx].scroll_flag = "*" THEN 
						IF delete_type(l_arr_rec_stattype[idx].type_code) THEN 
							DELETE FROM stattype 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND type_code = l_arr_rec_stattype[idx].type_code 
						END IF 
					END IF 
				END FOR 

			END IF 
		END IF 



			IF l_arr_rec_stattype[idx].type_code IS NOT NULL THEN 
				IF l_arr_rec_stattype[idx].scroll_flag IS NULL THEN 
					IF delete_type(l_arr_rec_stattype[idx].type_code) THEN 
						LET l_arr_rec_stattype[idx].scroll_flag = "*" 
						LET l_del_cnt = l_del_cnt + 1 
					END IF 
				ELSE 
					LET l_arr_rec_stattype[idx].scroll_flag = NULL 
					LET l_del_cnt = l_del_cnt - 1 
				END IF 
			END IF 
			NEXT FIELD scroll_flag 

			#     AFTER ROW
			#         DISPLAY l_arr_rec_stattype[idx].*
			#              TO sr_stattype[scrn].*

			#      ON KEY (control-w)  --help
			#         CALL kandoohelp("")

}

	END INPUT 
	###############################


	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
{
	ELSE 
		IF l_del_cnt > 0 THEN 
			IF kandoomsg("E",8023,l_del_cnt) = "Y" THEN 
				#8023 Confirm TO Delete ",l_del_cnt," stattype(s)? (Y/N)"
				LET l_msgresp = kandoomsg("E",1005,"") 

				FOR idx = 1 TO arr_count() 
					IF l_arr_rec_stattype[idx].scroll_flag = "*" THEN 
						IF delete_type(l_arr_rec_stattype[idx].type_code) THEN 
							DELETE FROM stattype 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND type_code = l_arr_rec_stattype[idx].type_code 
						END IF 
					END IF 
				END FOR 

			END IF 
		END IF 
}
	END IF 
END FUNCTION 


###################################################################
# FUNCTION edit_type(p_type_code)
#
# Note: IF p_type_code is NOT NULL = EDIT
# Type Code and Type_ind CAN NOT BE CHANGED in EDIT
###################################################################
FUNCTION edit_type(p_type_code) 
	DEFINE p_type_code LIKE stattype.type_code 
	DEFINE l_rec_stattype RECORD LIKE stattype.* 
	DEFINE l_msgresp LIKE language.yes_flag
	
	SELECT * INTO l_rec_stattype.* 
	FROM stattype 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND type_code = p_type_code 

	IF sqlca.sqlcode = notfound THEN 
		LET l_rec_stattype.type_code = p_type_code 
		LET l_rec_stattype.type_ind = "0" 
		LET l_rec_stattype.cust_upd_ind = "N" 
		LET l_rec_stattype.prod_upd_ind = "N" 
		LET l_rec_stattype.prod_upd1_ind = "N" 
		LET l_rec_stattype.prod_upd2_ind = "N" 
		LET l_rec_stattype.prod_upd3_ind = "N" 
		LET l_rec_stattype.prod_upd4_ind = "N" 
		LET l_rec_stattype.sale_upd_ind = "N" 
		LET l_rec_stattype.sale_upd1_ind = "N" 
		LET l_rec_stattype.sale_upd2_ind = "N" 
		LET l_rec_stattype.sale_upd3_ind = "N" 
		LET l_rec_stattype.sale_upd4_ind = "N" 
		LET l_rec_stattype.terr_upd_ind = "N" 
		LET l_rec_stattype.terr_upd1_ind = "N" 
		LET l_rec_stattype.sper_upd_ind = "N" 
		LET l_rec_stattype.sper_upd1_ind = "N" 
		LET l_rec_stattype.cond_upd_ind = "N" 
		LET l_rec_stattype.offer_upd_ind = "N" 
		LET l_rec_stattype.ware_upd_ind = "N" 
		LET l_rec_stattype.ware_upd1_ind = "N" 
		LET l_rec_stattype.ware_upd2_ind = "N" 
		LET l_rec_stattype.ware_upd3_ind = "N" 
		LET l_rec_stattype.ware_upd4_ind = "N" 
		LET p_type_code = NULL 
	END IF 

	OPEN WINDOW u213 with FORM "U213" 
	CALL windecoration_u("U213") 

	LET l_msgresp = kandoomsg("E",1057,"") 
	#1057 " Enter Interval Type Details - ESC TO Continue"
	INPUT BY NAME l_rec_stattype.type_code, 
	l_rec_stattype.type_text, 
	l_rec_stattype.type_ind, 
	l_rec_stattype.ware_upd_ind, 
	l_rec_stattype.ware_upd1_ind, 
	l_rec_stattype.ware_upd2_ind, 
	l_rec_stattype.ware_upd3_ind, 
	l_rec_stattype.ware_upd4_ind, 
	l_rec_stattype.prod_upd_ind, 
	l_rec_stattype.prod_upd1_ind, 
	l_rec_stattype.prod_upd2_ind, 
	l_rec_stattype.prod_upd3_ind, 
	l_rec_stattype.sale_upd_ind, 
	l_rec_stattype.sale_upd1_ind, 
	l_rec_stattype.sale_upd2_ind, 
	l_rec_stattype.sale_upd3_ind, 
	l_rec_stattype.terr_upd_ind, 
	l_rec_stattype.terr_upd1_ind, 
	l_rec_stattype.sper_upd_ind, 
	l_rec_stattype.sper_upd1_ind, 
	l_rec_stattype.cust_upd_ind, 
	l_rec_stattype.cond_upd_ind, 
	l_rec_stattype.offer_upd_ind WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","U61","input-stattype")
			IF p_type_code IS NOT NULL THEN 
				CALL Dialog.setFieldActive("stattype.type_code",FALSE)
				CALL Dialog.setFieldActive("stattype.type_ind",FALSE)
			END IF
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

--		BEFORE FIELD type_code 
--			IF p_type_code IS NOT NULL THEN 
--				
--			END IF 

		AFTER FIELD type_code 
			IF p_type_code IS NULL THEN		
				IF l_rec_stattype.type_code IS NOT NULL THEN 
					SELECT unique 1 FROM stattype 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND type_code = l_rec_stattype.type_code 
	
					IF status = 0 THEN 
						ERROR kandoomsg2("E",9198,"") 
						#9198" Statistic Interval Type code must be unique "
						NEXT FIELD type_code 
					END IF 
	
				END IF 
			END IF
--		BEFORE FIELD type_ind 
--			IF p_type_code IS NOT NULL THEN ## edit OF type IS NOT permitted 
--				#IF fgl_lastkey() = fgl_keyval("up") THEN 
--				#	NEXT FIELD previous 
--				#ELSE 
--				#	NEXT FIELD NEXT 
--				#END IF 
--			END IF 

		AFTER FIELD type_ind 
			IF l_rec_stattype.type_ind = "6" THEN 
				## based on AR payment term
				LET p_type_code = enter_term(l_rec_stattype.type_code) 

				OPTIONS INSERT KEY f1, 
				DELETE KEY f36 

				IF p_type_code IS NOT NULL THEN 
					SELECT unique 1 FROM stattype 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND type_code = p_type_code 

					IF status = 0 THEN 
						LET l_msgresp = kandoomsg("E",9238,"") 
						#9238" Payment Term Statistic Interval Type exists
						LET p_type_code = NULL 
						NEXT FIELD type_ind 
					ELSE 
						SELECT term_code, 
						desc_text 
						INTO l_rec_stattype.type_code, 
						l_rec_stattype.type_text 
						FROM term 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND term_code = p_type_code 

						DISPLAY BY NAME l_rec_stattype.type_code, 
						l_rec_stattype.type_text 

						LET p_type_code = NULL 
						NEXT FIELD cust_upd_ind 
					END IF 

				ELSE 

					NEXT FIELD type_ind 
				END IF 

			END IF 

		ON ACTION "sul_select_all_deselect"
			LET l_rec_stattype.ware_upd_ind = "N" 
			LET l_rec_stattype.ware_upd1_ind = "N" 
			LET l_rec_stattype.ware_upd2_ind = "N" 
			LET l_rec_stattype.ware_upd3_ind = "N" 
			LET l_rec_stattype.ware_upd4_ind = "N" 
			LET l_rec_stattype.prod_upd_ind = "N" 
			LET l_rec_stattype.prod_upd1_ind = "N" 
			LET l_rec_stattype.prod_upd2_ind = "N" 
			LET l_rec_stattype.prod_upd3_ind = "N" 
			LET l_rec_stattype.sale_upd_ind = "N" 
			LET l_rec_stattype.sale_upd1_ind = "N" 
			LET l_rec_stattype.sale_upd2_ind = "N" 
			LET l_rec_stattype.sale_upd3_ind = "N" 
			LET l_rec_stattype.terr_upd_ind = "N" 
			LET l_rec_stattype.terr_upd1_ind = "N" 
			LET l_rec_stattype.sper_upd_ind = "N" 
			LET l_rec_stattype.sper_upd1_ind = "N" 
			LET l_rec_stattype.cust_upd_ind = "N" 
			LET l_rec_stattype.cond_upd_ind = "N" 
			LET l_rec_stattype.offer_upd_ind = "N"
			
		ON ACTION "sul_select_all_select"
			LET l_rec_stattype.ware_upd_ind = "Y" 
			LET l_rec_stattype.ware_upd1_ind = "Y" 
			LET l_rec_stattype.ware_upd2_ind = "Y" 
			LET l_rec_stattype.ware_upd3_ind = "Y" 
			LET l_rec_stattype.ware_upd4_ind = "Y" 
			LET l_rec_stattype.prod_upd_ind = "Y" 
			LET l_rec_stattype.prod_upd1_ind = "Y" 
			LET l_rec_stattype.prod_upd2_ind = "Y" 
			LET l_rec_stattype.prod_upd3_ind = "Y" 
			LET l_rec_stattype.sale_upd_ind = "Y" 
			LET l_rec_stattype.sale_upd1_ind = "Y" 
			LET l_rec_stattype.sale_upd2_ind = "Y" 
			LET l_rec_stattype.sale_upd3_ind = "Y" 
			LET l_rec_stattype.terr_upd_ind = "Y" 
			LET l_rec_stattype.terr_upd1_ind = "Y" 
			LET l_rec_stattype.sper_upd_ind = "Y" 
			LET l_rec_stattype.sper_upd1_ind = "Y" 
			LET l_rec_stattype.cust_upd_ind = "Y" 
			LET l_rec_stattype.cond_upd_ind = "Y" 
			LET l_rec_stattype.offer_upd_ind = "Y"


		ON ACTION "sul_select_toggle"
			IF l_rec_stattype.ware_upd_ind = "N" THEN
				LET l_rec_stattype.ware_upd_ind = "Y" 
			ELSE
				LET l_rec_stattype.ware_upd_ind = "N"
			END IF
			IF l_rec_stattype.ware_upd1_ind = "N" THEN			
				LET l_rec_stattype.ware_upd1_ind = "Y"
			ELSE
				LET l_rec_stattype.ware_upd1_ind = "N"
			END IF
			IF l_rec_stattype.ware_upd2_ind = "N" THEN		 
				LET l_rec_stattype.ware_upd2_ind = "Y"
			ELSE
				LET l_rec_stattype.ware_upd2_ind = "N"
			END IF
			IF l_rec_stattype.ware_upd3_ind = "N" THEN  
				LET l_rec_stattype.ware_upd3_ind = "Y"
			ELSE
				LET l_rec_stattype.ware_upd3_ind = "N"
			END IF
			IF l_rec_stattype.ware_upd4_ind = "N" THEN  
				LET l_rec_stattype.ware_upd4_ind = "Y"
			ELSE
				LET l_rec_stattype.ware_upd4_ind = "N"
			END IF
			IF l_rec_stattype.prod_upd_ind = "N" THEN
				LET l_rec_stattype.prod_upd_ind = "Y"
			ELSE
				LET l_rec_stattype.prod_upd_ind = "N"
			END IF
			
			IF l_rec_stattype.prod_upd1_ind = "N" THEN
				LET l_rec_stattype.prod_upd1_ind = "Y"
			ELSE
				LET l_rec_stattype.prod_upd1_ind = "N"
			END IF 
			
			IF l_rec_stattype.prod_upd2_ind = "N" THEN
				LET l_rec_stattype.prod_upd2_ind = "Y"
			ELSE
				LET l_rec_stattype.prod_upd2_ind = "N"
			END IF 

			IF l_rec_stattype.prod_upd3_ind = "N" THEN
				LET l_rec_stattype.prod_upd3_ind = "Y"
			ELSE
				LET l_rec_stattype.prod_upd3_ind = "N"
			END IF 

			IF l_rec_stattype.sale_upd_ind = "N" THEN
				LET l_rec_stattype.sale_upd_ind = "Y"
			ELSE
				LET l_rec_stattype.sale_upd_ind = "N"
			END IF 

			IF l_rec_stattype.sale_upd1_ind = "N" THEN
				LET l_rec_stattype.sale_upd1_ind = "Y"
			ELSE
				LET l_rec_stattype.sale_upd1_ind = "N"
			END IF 

			IF l_rec_stattype.sale_upd2_ind = "N" THEN
				LET l_rec_stattype.sale_upd2_ind = "Y"
			ELSE
				LET l_rec_stattype.sale_upd2_ind = "N"
			END IF 

			IF l_rec_stattype.sale_upd3_ind = "N" THEN
				LET l_rec_stattype.sale_upd3_ind = "Y"
			ELSE
				LET l_rec_stattype.sale_upd3_ind = "N"
			END IF 

			IF l_rec_stattype.terr_upd_ind = "N" THEN
				LET l_rec_stattype.terr_upd_ind = "Y"
			ELSE
				LET l_rec_stattype.terr_upd_ind = "N"
			END IF 									

			IF l_rec_stattype.terr_upd1_ind = "N" THEN
				LET l_rec_stattype.terr_upd1_ind = "Y"
			ELSE
				LET l_rec_stattype.terr_upd1_ind = "N"
			END IF 									

			IF l_rec_stattype.sper_upd_ind = "N" THEN
				LET l_rec_stattype.sper_upd_ind = "Y"
			ELSE
				LET l_rec_stattype.sper_upd_ind = "N"
			END IF 									

			IF l_rec_stattype.sper_upd1_ind = "N" THEN
				LET l_rec_stattype.sper_upd1_ind = "Y"
			ELSE
				LET l_rec_stattype.sper_upd1_ind = "N"
			END IF 									

			IF l_rec_stattype.cust_upd_ind = "N" THEN
				LET l_rec_stattype.cust_upd_ind = "Y"
			ELSE
				LET l_rec_stattype.cust_upd_ind = "N"
			END IF 									

			IF l_rec_stattype.cond_upd_ind = "N" THEN
				LET l_rec_stattype.cond_upd_ind = "Y"
			ELSE
				LET l_rec_stattype.cond_upd_ind = "N"
			END IF 									

			IF l_rec_stattype.offer_upd_ind = "N" THEN
				LET l_rec_stattype.offer_upd_ind = "Y"
			ELSE
				LET l_rec_stattype.offer_upd_ind = "N"
			END IF 									



		
		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF l_rec_stattype.type_code IS NULL THEN 
					LET l_msgresp = kandoomsg("E",9197,"") 
					#9197" Statistic Interval Type code must be entered "
					NEXT FIELD type_code 
				END IF 

				IF l_rec_stattype.type_text IS NULL THEN 
					LET l_msgresp = kandoomsg("E",9199,"") 
					#9199 "Must enter a description"
					NEXT FIELD type_text 
				END IF 

			END IF 


	END INPUT 
	##########################

	CLOSE WINDOW U213 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		IF p_type_code IS NULL THEN 
			LET l_rec_stattype.cmpy_code = glob_rec_kandoouser.cmpy_code 
			INSERT INTO stattype VALUES (l_rec_stattype.*) 
			RETURN sqlca.sqlerrd[6] 
		ELSE 
			UPDATE stattype 
			SET stattype.* = l_rec_stattype.* 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND type_code = p_type_code 
			RETURN sqlca.sqlerrd[3] 
		END IF 
	END IF 

END FUNCTION 



###################################################################
# FUNCTION delete_type(p_type_code)
#
#
###################################################################
FUNCTION delete_type(p_type_code) 
	DEFINE p_type_code LIKE stattype.type_code 
	DEFINE l_msgresp LIKE language.yes_flag
	
	SELECT unique 1 FROM statint 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND type_code = p_type_code 

	IF sqlca.sqlcode = 0 THEN 
		LET l_msgresp=kandoomsg("E",7070,p_type_code) 
		#7070" Interval type IS in use - Deletion IS NOT permitted"
		RETURN false 
	END IF 

	SELECT unique 1 FROM statparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ( day_type_code = p_type_code 
	OR week_type_code = p_type_code 
	OR mth_type_code = p_type_code 
	OR qtr_type_code = p_type_code 
	OR year_type_code = p_type_code) 

	IF sqlca.sqlcode = 0 THEN 
		LET l_msgresp=kandoomsg("E",7070,p_type_code) 
		#7070" Interval type IS in use - Deletion IS NOT permitted"
		RETURN false 
	ELSE 
		RETURN true 
	END IF 

END FUNCTION 



###################################################################
# FUNCTION delete_type(p_type_code)
#
#
###################################################################
FUNCTION enter_term(p_type_code) 
	DEFINE p_type_code LIKE term.term_code 
	DEFINE l_rec_term RECORD LIKE term.* 
	DEFINE l_msgresp LIKE language.yes_flag
	
	LET l_rec_term.term_code = p_type_code 

	OPEN WINDOW u214 with FORM "U214" 
	CALL windecoration_u("U214") 

	LET l_msgresp=kandoomsg("E",1061,"") 
	#1061 Enter Payment Term TO base Interval Type

	INPUT BY NAME l_rec_term.term_code, 
	l_rec_term.desc_text WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","U61","input-term") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		ON KEY (control-b) 
			LET l_rec_term.term_code = show_term(glob_rec_kandoouser.cmpy_code) 
			NEXT FIELD term_code 

		BEFORE FIELD term_code 
			SELECT desc_text INTO l_rec_term.desc_text 
			FROM term 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND term_code = l_rec_term.term_code 
			DISPLAY BY NAME l_rec_term.desc_text 

		AFTER FIELD term_code 
			CLEAR desc_text 
			SELECT desc_text INTO l_rec_term.desc_text 
			FROM term 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND term_code = l_rec_term.term_code 

			CASE 
				WHEN l_rec_term.term_code IS NULL 
					LET l_msgresp=kandoomsg("E",9058,"") 
					#9058 term must be entered
					NEXT FIELD term_code 
				WHEN sqlca.sqlcode = notfound 
					LET l_msgresp=kandoomsg("E",9056,"") 
					#9056 term must be entered
					NEXT FIELD term_code 
				OTHERWISE 
					DISPLAY BY NAME l_rec_term.desc_text 

					SLEEP 1 
			END CASE 


	END INPUT 
	#######################

	CLOSE WINDOW u214 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN p_type_code 
	ELSE 
		RETURN l_rec_term.term_code 
	END IF 
END FUNCTION 
