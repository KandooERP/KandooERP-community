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

	Source code beautified by beautify.pl on 2020-01-03 18:54:44	$Id: $
}



#
{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module U51 - Maintain Suburbs
#
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"
GLOBALS "../utility/U_UT_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"

GLOBALS 
	DEFINE glob_err_message CHAR(40) 
	DEFINE glob_arr_rec_suburbarea DYNAMIC ARRAY OF t_rec_suburbarea_wc_nt_ca_tc_sc_with_scrollflag 
	DEFINE glob_next_action SMALLINT 
--	DEFINE glob_rpt_pageno SMALLINT 
	DEFINE glob_l_del_cnt SMALLINT 
	DEFINE glob_arr_count SMALLINT 

END GLOBALS 


##############################################################
# MAIN
#
#
##############################################################
MAIN 
	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("U51") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_u_ut() #init utility module 

	OPTIONS INSERT KEY f1, 
	DELETE KEY f36 

	OPEN WINDOW U120 with FORM "U120" 
	CALL windecoration_u("U120") 

	LET glob_next_action = 0 

	CALL create_table("supply","t_supply","","Y") 
	CALL create_table("suburbarea","t_subarea","","Y") 

	#   WHILE U51_rpt_query()
	CALL scan_suburb() 
	#   END WHILE

	CLOSE WINDOW U120 

	IF glob_next_action > 0 THEN 
		#------------------------------------------------------------
		FINISH REPORT U51_rpt_list_suburb_log
		CALL rpt_finish("U51_rpt_list_suburb_log")
		#------------------------------------------------------------
	END IF 
END MAIN 


##############################################################
# FUNCTION U51_rpt_query()
##############################################################
FUNCTION U51_rpt_query(p_filter) 
	DEFINE p_filter boolean 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE l_rec_suburb RECORD LIKE suburb.* 
	DEFINE l_arr_rec_suburb DYNAMIC ARRAY OF t_rec_suburb_st_sc_pc_with_scrollflag 
	DEFINE l_arr_rec_sub_code DYNAMIC ARRAY OF #array[100] OF RECORD 
		RECORD 
			suburb_code LIKE suburb.suburb_code 
		END RECORD 

		DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
		DEFINE l_query_text STRING 
		DEFINE l_where_text STRING 
		DEFINE l_idx SMALLINT 
		DEFINE l_msgresp LIKE language.yes_flag 

		IF p_filter THEN 
			CLEAR FORM 
			LET l_msgresp = kandoomsg("U",1001,"") 
			#1001 " Enter Selection Criteria - ESC TO Continue"
			CONSTRUCT BY NAME l_where_text ON suburb_text, 
			state_code, 
			post_code 

				BEFORE CONSTRUCT 
					CALL publish_toolbar("kandoo","U51","construct-suburb") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

			END CONSTRUCT 

		ELSE 
			LET l_where_text = " 1=1 " 
		END IF 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_where_text = " 1=1 " 
		END IF 


		LET l_msgresp = kandoomsg("U",1002,"") 
		#1002 " Searching database - please wait"
		LET l_query_text = "SELECT * FROM suburb ", 
		"WHERE cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
		"AND ", l_where_text clipped," ", 
		"ORDER BY suburb.suburb_text" 
		PREPARE s_suburb FROM l_query_text 
		DECLARE c_suburb CURSOR FOR s_suburb 

		LET l_idx = 0 

		FOREACH c_suburb INTO l_rec_suburb.* 
			LET l_idx = l_idx + 1 
			LET l_arr_rec_sub_code[l_idx].suburb_code = l_rec_suburb.suburb_code 
			LET l_arr_rec_suburb[l_idx].suburb_text = l_rec_suburb.suburb_text 
			LET l_arr_rec_suburb[l_idx].state_code = l_rec_suburb.state_code 
			LET l_arr_rec_suburb[l_idx].post_code = l_rec_suburb.post_code 

			IF l_idx = 100 THEN 
				LET l_msgresp = kandoomsg("W",9021,l_idx) 
				#9021 " First ??? entries Selected Only"
				EXIT FOREACH 
			END IF 

		END FOREACH 

		RETURN l_arr_rec_suburb, l_arr_rec_sub_code 
END FUNCTION 

##############################################################
# FUNCTION edit_supply(p_suburb_code,p_suburb_text)
##############################################################
FUNCTION edit_supply(p_suburb_code,p_suburb_text) 
	DEFINE 
	p_suburb_code LIKE suburb.suburb_code, 
	p_suburb_text LIKE suburb.suburb_text 

	OPEN WINDOW u125 with FORM "U125" 
	CALL windecoration_u("U125") 

	IF select_supply(p_suburb_code,p_suburb_text) THEN 
		CALL scan_supply(p_suburb_code) 
	END IF 

	CLOSE WINDOW u125 
END FUNCTION 


##############################################################
# FUNCTION select_supply(p_suburb_code,p_suburb_text)
#
#
##############################################################
FUNCTION select_supply(p_suburb_code,p_suburb_text) 
	DEFINE p_suburb_code LIKE suburb.suburb_code 
	DEFINE p_suburb_text LIKE suburb.suburb_text 
	DEFINE l_rec_suburb RECORD LIKE suburb.* 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE l_msgresp LIKE language.yes_flag 
	CLEAR FORM 

	IF p_suburb_code IS NOT NULL THEN 
		SELECT * INTO l_rec_suburb.* FROM suburb 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND suburb_code = p_suburb_code 
	ELSE 
		LET l_rec_suburb.suburb_text = p_suburb_text 
	END IF 

	DISPLAY BY NAME l_rec_suburb.suburb_text 

	LET l_msgresp = kandoomsg("U",1002,"") 
	#1002 " Searching database - please wait"
	LET l_query_text = "SELECT * FROM t_supply, warehouse ", 
	"WHERE t_supply.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	"AND warehouse.cmpy_code = t_supply.cmpy_code ", 
	"AND warehouse.ware_code = t_supply.ware_code ", 
	"ORDER BY t_supply.ware_code" 
	PREPARE s_supply FROM l_query_text 
	DECLARE c_supply CURSOR FOR s_supply 

	RETURN true 
END FUNCTION 


##############################################################
# FUNCTION scan_supply(p_suburb_code)
#
#
##############################################################
FUNCTION scan_supply(p_suburb_code) 
	DEFINE p_suburb_code LIKE suburb.suburb_code 
	#DEFINE l_rec_suburb RECORD LIKE suburb.* #not used
	DEFINE l_rec_supply RECORD LIKE supply.* 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_arr_rec_supply DYNAMIC ARRAY OF t_rec_supply_wc_dt_kq_with_scrollflag 
	#	DEFINE l_arr_rec_supply array[100] of record
	#         scroll_flag CHAR(1),
	#         ware_code LIKE supply.ware_code,
	#         desc_text LIKE warehouse.desc_text,
	#         km_qty LIKE supply.km_qty
	#      END RECORD
	DEFINE pr_scroll_flag CHAR(1) 
	DEFINE winds_text CHAR(40) 
	DEFINE l_idx SMALLINT 
	DEFINE x SMALLINT 
	DEFINE i SMALLINT 
	DEFINE j SMALLINT 
	DEFINE c SMALLINT 
	DEFINE l_del_cnt SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	------------------------------

	OPTIONS INSERT KEY f1, 
	DELETE KEY f36 

	#   CALL set_count(l_idx)

	----------------------------------------

	LET l_msgresp = kandoomsg("U",1003,"") 
	#" F1 TO Add - F2 TO Delete - RETURN on line TO Edit "

	INPUT ARRAY l_arr_rec_supply WITHOUT DEFAULTS FROM sr_supply.* ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","U51","input-arr-supply") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (ware_code) 
			LET winds_text = NULL 
			LET winds_text = show_wlocn(glob_rec_kandoouser.cmpy_code) 
			IF winds_text IS NOT NULL THEN 
				LET l_arr_rec_supply[l_idx].ware_code = winds_text 
				#                  DISPLAY l_arr_rec_supply[l_idx].ware_code TO sr_supply[scrn].ware_code

			END IF 
			OPTIONS INSERT KEY f1, 
			DELETE KEY f36 
			NEXT FIELD ware_code 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			#         LET scrn = scr_line()
			NEXT FIELD scroll_flag 

		BEFORE INSERT 
			INITIALIZE l_rec_supply.* TO NULL 
			INITIALIZE l_arr_rec_supply[l_idx].* TO NULL 

			IF arr_count() = 1 THEN 
				NEXT FIELD scroll_flag 
			ELSE 
				NEXT FIELD ware_code 
			END IF 

		BEFORE FIELD scroll_flag 
			#         LET pr_scroll_flag = l_arr_rec_supply[l_idx].scroll_flag
			#         DISPLAY l_arr_rec_supply[l_idx].* TO sr_supply[scrn].*

			LET l_rec_supply.ware_code = l_arr_rec_supply[l_idx].ware_code 
			LET l_rec_warehouse.desc_text = l_arr_rec_supply[l_idx].desc_text 
			LET l_rec_supply.km_qty = l_arr_rec_supply[l_idx].km_qty 

			#      AFTER FIELD scroll_flag
			#         LET l_arr_rec_supply[l_idx].scroll_flag = pr_scroll_flag
			#         DISPLAY l_arr_rec_supply[l_idx].scroll_flag
			#              TO sr_supply[scrn].scroll_flag

			#         IF fgl_lastkey() = fgl_keyval("down") THEN
			#            IF l_arr_rec_supply[l_idx+1].ware_code IS NULL
			#            OR arr_curr() >= (arr_count() + 1) THEN
			#               LET l_msgresp=kandoomsg("W",9001,"")
			#               #9001 There no more rows...
			#               NEXT FIELD scroll_flag
			#            END IF
			#         END IF

		BEFORE FIELD ware_code 
			#         DISPLAY l_arr_rec_supply[l_idx].* TO sr_supply[scrn].*

			IF l_rec_supply.ware_code IS NOT NULL THEN 
				NEXT FIELD km_qty 
			END IF 

		AFTER FIELD ware_code 
			CASE 
				WHEN fgl_lastkey() = fgl_keyval("accept") 
					OR fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("down") 
					IF l_arr_rec_supply[l_idx].ware_code IS NULL 
					OR l_arr_rec_supply[l_idx].ware_code = 0 THEN 
						LET l_msgresp = kandoomsg("W",9041,"") 
						#9041 Warehouse Code must be entered
						NEXT FIELD ware_code 
					ELSE 
						LET l_arr_rec_supply[l_idx].scroll_flag = NULL 
						#                  DISPLAY l_arr_rec_supply[l_idx].scroll_flag
						#                       TO sr_supply[scrn].scroll_flag

						SELECT * INTO l_rec_warehouse.* FROM warehouse 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND ware_code = l_arr_rec_supply[l_idx].ware_code 

						IF status = notfound THEN 
							LET l_msgresp = kandoomsg("W",9200,"") 
							#9200 Warehouse NOT found - Try window
							NEXT FIELD ware_code 
						ELSE 
							IF l_rec_supply.ware_code IS NULL THEN 
								FOR c = 1 TO 99 
									IF l_idx != c THEN 
										IF l_arr_rec_supply[l_idx].ware_code 
										= l_arr_rec_supply[c].ware_code THEN 
											LET l_msgresp = kandoomsg("W",9093,"") 
											#9093 Suburb/Warehouse combo already exists
											NEXT FIELD ware_code 
											EXIT FOR 
										END IF 
									END IF 
								END FOR 
								SELECT * FROM t_supply 
								WHERE ware_code = l_arr_rec_supply[l_idx].ware_code 
								AND cmpy_code = glob_rec_kandoouser.cmpy_code 

								IF status != notfound THEN 
									LET l_msgresp = kandoomsg("W",9093,"") 
									#9093 Suburb/Warehouse combo already exists
									NEXT FIELD ware_code 
								END IF 
							END IF 
							LET l_arr_rec_supply[l_idx].desc_text = l_rec_warehouse.desc_text 
							#                     DISPLAY l_arr_rec_supply[l_idx].desc_text
							#                         TO sr_supply[scrn].desc_text

						END IF 

						IF fgl_lastkey() = fgl_keyval("accept") THEN 
							IF l_arr_rec_supply[l_idx].km_qty IS NULL 
							OR l_arr_rec_supply[l_idx].km_qty = 0 THEN 
								LET l_msgresp = kandoomsg("W",9042,"") 
								#9042 A distance must be entered
								NEXT FIELD km_qty 
							END IF 
						END IF 
						NEXT FIELD NEXT 
					END IF 

				WHEN fgl_lastkey() = fgl_keyval("left") 
					OR fgl_lastkey() = fgl_keyval("up") 
					NEXT FIELD previous 

				OTHERWISE 
					NEXT FIELD ware_code 

			END CASE 

		AFTER FIELD km_qty 
			CASE 
				WHEN fgl_lastkey() = fgl_keyval("accept") 
					OR fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("down") 
					IF l_arr_rec_supply[l_idx].km_qty IS NULL 
					OR l_arr_rec_supply[l_idx].km_qty = 0 THEN 
						LET l_msgresp = kandoomsg("W",9042,"") 
						#9042 A distance must be entered
						NEXT FIELD km_qty 
					ELSE 
						NEXT FIELD scroll_flag 
					END IF 
				WHEN fgl_lastkey() = fgl_keyval("left") 
					OR fgl_lastkey() = fgl_keyval("up") 
					NEXT FIELD previous 
				OTHERWISE 
					NEXT FIELD ware_code 
			END CASE 

		ON KEY (F2) --delete marker 
			IF l_arr_rec_supply[l_idx].scroll_flag IS NULL THEN 
				LET l_arr_rec_supply[l_idx].scroll_flag = "*" 
				LET l_del_cnt = l_del_cnt + 1 
			ELSE 
				LET l_arr_rec_supply[l_idx].scroll_flag = NULL 
				LET l_del_cnt = l_del_cnt - 1 
			END IF 
			NEXT FIELD scroll_flag 

			#      AFTER ROW
			#         DISPLAY l_arr_rec_supply[l_idx].* TO sr_supply[scrn].*

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				IF NOT (infield(scroll_flag)) THEN 
					LET int_flag = 0 
					LET quit_flag = 0 
					IF l_rec_supply.ware_code IS NULL THEN 
						#                  FOR l_idx = arr_curr() TO arr_count()
						#                     LET l_arr_rec_supply[l_idx].* = l_arr_rec_supply[l_idx+1].*
						#                     IF l_arr_rec_supply[l_idx].ware_code IS NULL THEN
						#                        INITIALIZE l_arr_rec_supply[l_idx].* TO NULL
						#                     END IF
						#                     IF scrn <= 10 THEN
						#                        DISPLAY l_arr_rec_supply[l_idx].*
						#                             TO sr_supply[scrn].*
						#
						#                        LET scrn = scrn + 1
						#                     END IF
						#                  END FOR
						#                 INITIALIZE l_arr_rec_supply[l_idx].* TO NULL
						#                 LET scrn = scr_line()
						#                 DISPLAY l_arr_rec_supply[l_idx].* TO sr_supply[scrn].*

						NEXT FIELD scroll_flag 
					ELSE 
						LET l_arr_rec_supply[l_idx].ware_code = l_rec_supply.ware_code 
						LET l_arr_rec_supply[l_idx].km_qty = l_rec_supply.km_qty 
						LET l_arr_rec_supply[l_idx].desc_text 
						= l_rec_warehouse.desc_text 
						#                  DISPLAY l_arr_rec_supply[l_idx].* TO sr_supply[scrn].*

						NEXT FIELD scroll_flag 
					END IF 
				END IF 
			END IF 

			#      ON KEY (control-w)
			#         CALL kandoohelp("")

	END INPUT 
	#######################

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 
		DELETE FROM t_supply 
		IF l_del_cnt > 0 THEN 
			LET l_msgresp = kandoomsg("W",8003,l_del_cnt) 
			#8003 Confirm TO Delete ",l_del_cnt," Supply Location(s)? (Y/N)"
		END IF 

		FOR l_idx = 1 TO arr_count() 
			IF l_arr_rec_supply[l_idx].ware_code IS NOT NULL THEN 
				LET l_rec_supply.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_rec_supply.suburb_code = p_suburb_code 
				LET l_rec_supply.ware_code = l_arr_rec_supply[l_idx].ware_code 
				LET l_rec_supply.km_qty = l_arr_rec_supply[l_idx].km_qty 
				IF l_arr_rec_supply[l_idx].scroll_flag != "*" 
				OR l_arr_rec_supply[l_idx].scroll_flag IS NULL THEN 
					INSERT INTO t_supply VALUES (l_rec_supply.*) 
				ELSE 
					IF l_msgresp != 'Y' THEN 
						INSERT INTO t_supply VALUES (l_rec_supply.*) 
					END IF 
				END IF 
			END IF 
		END FOR 
	END IF 

END FUNCTION 


##############################################################
# FUNCTION edit_suburbarea(p_suburb_code)
#
#
##############################################################
FUNCTION edit_suburbarea(p_suburb_code) 
	DEFINE p_suburb_code LIKE suburb.suburb_code 
	DEFINE l_rec_temp_suburbarea RECORD LIKE suburbarea.* 
	DEFINE l_rec_territory RECORD LIKE territory.* 
	DEFINE l_rec_suburbarea t_rec_suburbarea_wc_nt_ca_tc_sc_with_scrollflag 
	#	DEFINE l_rec_suburbarea record
	#         scroll_flag CHAR(1),
	#         waregrp_code LIKE suburbarea.waregrp_code,
	#         name_text LIKE waregrp.name_text,
	#         cart_area_code LIKE suburbarea.cart_area_code,
	#         terr_code LIKE suburbarea.terr_code,
	#         sale_code LIKE suburbarea.sale_code
	#      END RECORD
	DEFINE l_winds_text CHAR(40) 
	DEFINE l_idx SMALLINT 
	#	DEFINE scrn SMALLINT
	DEFINE i SMALLINT 
	DEFINE l_mode SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	IF p_suburb_code IS NULL THEN 
		LET l_mode = MODE_INSERT 
	ELSE 
		LET l_mode = MODE_UPDATE 
	END IF 
	#- INPUT the ARRAY suburbarea -#

	#DROP temp table t_subarea... wow... no error exception handling here

	IF fgl_find_table("t_subarea") THEN
		DROP TABLE t_subarea 
	END IF		   

	SELECT * FROM suburbarea 
	WHERE suburb_code = p_suburb_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	INTO temp t_subarea 
	#- IF the suburb code passed exists THEN collect the suburbarea -#
	#- rows AND also fill a temporary table with these VALUES.      -#

	DECLARE c_suburbarea CURSOR FOR 
	SELECT * 
	FROM suburbarea 
	WHERE suburb_code = p_suburb_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 

	LET l_idx = 0 

	FOREACH c_suburbarea INTO l_rec_temp_suburbarea.* 
		LET l_idx = l_idx + 1 
		SELECT name_text 
		INTO glob_arr_rec_suburbarea[l_idx].name_text 
		FROM waregrp 
		WHERE waregrp_code = l_rec_temp_suburbarea.waregrp_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 

		LET glob_arr_rec_suburbarea[l_idx].waregrp_code = l_rec_temp_suburbarea.waregrp_code 
		LET glob_arr_rec_suburbarea[l_idx].cart_area_code = l_rec_temp_suburbarea.cart_area_code 
		LET glob_arr_rec_suburbarea[l_idx].terr_code = l_rec_temp_suburbarea.terr_code 
		LET glob_arr_rec_suburbarea[l_idx].sale_code = l_rec_temp_suburbarea.sale_code 
		LET glob_arr_rec_suburbarea[l_idx].scroll_flag = NULL 

		#      IF l_idx = 100 THEN
		#         LET l_msgresp = kandoomsg("W",9021,l_idx)
		#         #9021 " First ??? entries Selected Only"
		#         EXIT FOREACH
		#      END IF
	END FOREACH 

	OPTIONS INSERT KEY f1, 
	DELETE KEY f36 
	#CALL set_count(l_idx)
	LET l_msgresp = kandoomsg("U",1003,"") 
	#" F1 TO Add - F2 TO Delete - RETURN on line TO Edit "

	INPUT ARRAY glob_arr_rec_suburbarea WITHOUT DEFAULTS FROM sr_suburbarea.* attribute(UNBUFFERED, append ROW = false,auto append = false, DELETE ROW = false) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","U51","input-arr-suburbarea") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		BEFORE ROW 
			LET l_idx = arr_curr() 
			IF l_idx > 0 THEN 
				LET l_rec_suburbarea.* = glob_arr_rec_suburbarea[l_idx].* 
			END IF 
			#         DISPLAY "arr_curr()=", arr_curr()
			#         DISPLAY "l_idx=",l_idx
			#         LET scrn = scr_line()
			NEXT FIELD scroll_flag 

		BEFORE INSERT 
			LET l_idx = arr_curr() 
			#         DISPLAY "arr_curr()=", arr_curr()
			#         DISPLAY "l_idx=",l_idx

			INITIALIZE l_rec_suburbarea.* TO NULL 
			#         INITIALIZE glob_arr_rec_suburbarea[l_idx].* TO NULL
			NEXT FIELD waregrp_code 

			#AFTER INSERT
			#	IF int_flag THEN
			#		CALL glob_arr_rec_suburbarea.deleteElement(l_idx)
			#		LET int_Flag = true
			#	END IF

		BEFORE FIELD scroll_flag 
			#         DISPLAY "arr_curr()=", arr_curr()
			#         DISPLAY "l_idx=",l_idx
			IF l_idx > 0 THEN 
				LET l_rec_suburbarea.scroll_flag = glob_arr_rec_suburbarea[l_idx].scroll_flag 
			END IF 
			#         DISPLAY glob_arr_rec_suburbarea[l_idx].* TO sr_suburbarea[scrn].*

		AFTER FIELD scroll_flag 
			#         DISPLAY "arr_curr()=", arr_curr()
			#         DISPLAY "l_idx=",l_idx
			IF l_idx > 0 THEN 
				LET glob_arr_rec_suburbarea[l_idx].scroll_flag = l_rec_suburbarea.scroll_flag 
				LET l_rec_suburbarea.* = glob_arr_rec_suburbarea[l_idx].* 
			END IF 
			#         DISPLAY glob_arr_rec_suburbarea[l_idx].scroll_flag
			#              TO sr_suburbarea[scrn].scroll_flag

			#         LET l_rec_suburbarea.* = glob_arr_rec_suburbarea[l_idx].*
			#         IF fgl_lastkey() = fgl_keyval("down") THEN
			#            IF glob_arr_rec_suburbarea[l_idx+1].waregrp_code IS NULL
			#            OR arr_curr() >= arr_count() THEN
			#               LET l_msgresp=kandoomsg("U",9001,"")
			#               #9001 There no more rows...
			#               NEXT FIELD scroll_flag
			#            END IF
			#         END IF

		BEFORE FIELD waregrp_code 
			LET l_idx = arr_curr() 
			#         DISPLAY "arr_curr()=", arr_curr()
			#         DISPLAY "l_idx=",l_idx

			#         DISPLAY glob_arr_rec_suburbarea[l_idx].* TO sr_suburbarea[scrn].*

			IF glob_arr_rec_suburbarea[l_idx].waregrp_code IS NOT NULL THEN 
				IF l_rec_suburbarea.waregrp_code IS NOT NULL THEN 
					NEXT FIELD cart_area_code 
				END IF 
			END IF 

		AFTER FIELD waregrp_code 
			#         DISPLAY "arr_curr()=", arr_curr()
			#         DISPLAY "l_idx=",l_idx

			CASE 
				WHEN fgl_lastkey() = fgl_keyval("accept") 
					OR fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("down") 
					IF glob_arr_rec_suburbarea[l_idx].waregrp_code IS NULL THEN 
						LET l_msgresp = kandoomsg("W",9365,"") 
						#9365 Warehouse Group code must be Entered
						NEXT FIELD waregrp_code 
					ELSE 
						IF l_rec_suburbarea.waregrp_code IS NULL THEN 
							SELECT unique 1 FROM suburbarea 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND suburb_code = p_suburb_code 
							AND waregrp_code = glob_arr_rec_suburbarea[l_idx].waregrp_code 
							IF status != notfound THEN 
								LET l_msgresp = kandoomsg("W",9376,"") 
								#9376 This Suburb IS already linked TO this
								#     Warehouse Group
								NEXT FIELD waregrp_code 
							ELSE 
								#- Verify the waregrp code has only been entered -#
								#- on one line.                                  -#
								FOR i = 1 TO arr_count() 
									IF i <> l_idx THEN 
										#-Check FOR duplicate waregrp code -#
										IF glob_arr_rec_suburbarea[l_idx].waregrp_code = 
										glob_arr_rec_suburbarea[i].waregrp_code THEN 
											LET l_msgresp = kandoomsg("W",9366,"") 
											# 9366 Warehouse Group code already exists
											NEXT FIELD waregrp_code 
										END IF 
									END IF 
								END FOR 
								SELECT unique 1 FROM waregrp 
								WHERE waregrp_code = glob_arr_rec_suburbarea[l_idx].waregrp_code 
								AND cmpy_code = glob_rec_kandoouser.cmpy_code 
								IF status = notfound THEN 
									LET l_msgresp = kandoomsg("W",9375,"") 
									# 9375 Warehouse Group does NOT exists - use window
									NEXT FIELD waregrp_code 
								ELSE 
									SELECT name_text INTO glob_arr_rec_suburbarea[l_idx].name_text 
									FROM waregrp 
									WHERE waregrp_code = glob_arr_rec_suburbarea[l_idx].waregrp_code 
									AND cmpy_code = glob_rec_kandoouser.cmpy_code 
									#                      DISPLAY glob_arr_rec_suburbarea[l_idx].name_text
									#                           TO sr_suburbarea[scrn].name_text

								END IF 
							END IF 

						ELSE 

							LET glob_arr_rec_suburbarea[l_idx].waregrp_code = l_rec_suburbarea.waregrp_code 
							#                DISPLAY glob_arr_rec_suburbarea[l_idx].waregrp_code
							#                     TO sr_suburbarea[scrn].waregrp_code

						END IF 

						IF fgl_lastkey() = fgl_keyval("accept") THEN 
							IF glob_arr_rec_suburbarea[l_idx].cart_area_code IS NULL THEN 
								LET l_msgresp = kandoomsg("W",9044,"") 
								#9044 A Cartage Area Code must be entered
								NEXT FIELD cart_area_code 
							ELSE 
								SELECT unique 1 FROM cartarea 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND cart_area_code = glob_arr_rec_suburbarea[l_idx].cart_area_code 
								IF status = notfound THEN 
									LET l_msgresp = kandoomsg("W",9202,"") 
									#9202 A Cartage Area Code IS NOT found
									NEXT FIELD cart_area_code 
								END IF 
							END IF 
							IF glob_arr_rec_suburbarea[l_idx].terr_code IS NULL THEN 
								LET l_msgresp = kandoomsg("W",9050,"") 
								#9050 A Territory Code must be entered
								NEXT FIELD terr_code 
							ELSE 
								SELECT unique 1 FROM territory 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND terr_code = glob_arr_rec_suburbarea[l_idx].terr_code 
								IF status = notfound THEN 
									LET l_msgresp = kandoomsg("W",9203,"") 
									#9203 This territory code IS NOT found - use window
									NEXT FIELD terr_code 
								END IF 
							END IF 
							NEXT FIELD scroll_flag 
						END IF 
						NEXT FIELD NEXT 
					END IF 

				OTHERWISE 
					NEXT FIELD waregrp_code 

			END CASE 

		AFTER FIELD cart_area_code 
			LET l_idx = arr_curr() 
			#         DISPLAY "arr_curr()=", arr_curr()
			#         DISPLAY "l_idx=",l_idx

			CASE 
				WHEN fgl_lastkey() = fgl_keyval("accept") 
					OR fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("down") 
					IF glob_arr_rec_suburbarea[l_idx].cart_area_code IS NULL THEN 
						LET l_msgresp = kandoomsg("W",9044,"") 
						#9044 A Cartage Area Code must be entered
						NEXT FIELD cart_area_code 
					END IF 
					SELECT unique(1) FROM cartarea 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cart_area_code = glob_arr_rec_suburbarea[l_idx].cart_area_code 
					IF status = notfound THEN 
						LET l_msgresp = kandoomsg("W",9202,"") 
						#9202 A Cartage Area Code IS NOT found
						NEXT FIELD cart_area_code 
					END IF 

					IF fgl_lastkey() = fgl_keyval("accept") THEN 
						IF glob_arr_rec_suburbarea[l_idx].terr_code IS NULL THEN 
							LET l_msgresp = kandoomsg("W",9050,"") 
							#9050 A Territory Code must be entered
							NEXT FIELD terr_code 
						ELSE 
							SELECT unique 1 
							FROM territory 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND terr_code = glob_arr_rec_suburbarea[l_idx].terr_code 
							IF status = notfound THEN 
								LET l_msgresp = kandoomsg("W",9203,"") 
								#9203 This territory code IS NOT found - use window
								NEXT FIELD terr_code 
							END IF 
						END IF 
						NEXT FIELD scroll_flag 
					END IF 

					NEXT FIELD NEXT 

				WHEN fgl_lastkey() = fgl_keyval("left") 
					OR fgl_lastkey() = fgl_keyval("up") 
					IF glob_arr_rec_suburbarea[l_idx].cart_area_code IS NULL THEN 
						LET l_msgresp = kandoomsg("W",9044,"") 
						#9044 A Cartage Area Code must be entered
						NEXT FIELD cart_area_code 
					END IF 

					SELECT unique(1) FROM cartarea 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cart_area_code = glob_arr_rec_suburbarea[l_idx].cart_area_code 

					IF status = notfound THEN 
						LET l_msgresp = kandoomsg("W",9202,"") 
						#9202 A Cartage Area Code IS NOT found
						NEXT FIELD cart_area_code 
					END IF 
					NEXT FIELD previous 

				OTHERWISE 
					NEXT FIELD cart_area_code 
			END CASE 

		AFTER FIELD terr_code 
			CASE 
				WHEN fgl_lastkey() = fgl_keyval("accept") 
					OR fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("down") 

					IF glob_arr_rec_suburbarea[l_idx].terr_code IS NULL THEN 
						LET l_msgresp = kandoomsg("W",9050,"") 
						#9050 A Territory Code must be entered
						NEXT FIELD terr_code 
					END IF 

					SELECT sale_code INTO l_rec_territory.sale_code FROM territory 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND terr_code = glob_arr_rec_suburbarea[l_idx].terr_code 

					IF status = notfound THEN 
						LET l_msgresp = kandoomsg("W",9203,"") 
						#9203 This territory code IS NOT found - use window
						NEXT FIELD terr_code 
					END IF 
					IF l_rec_territory.sale_code IS NOT NULL THEN 
						LET glob_arr_rec_suburbarea[l_idx].sale_code = l_rec_territory.sale_code 
					END IF 
					NEXT FIELD NEXT 

				WHEN fgl_lastkey() = fgl_keyval("left") 
					OR fgl_lastkey() = fgl_keyval("up") 
					IF glob_arr_rec_suburbarea[l_idx].terr_code IS NULL THEN 
						LET l_msgresp = kandoomsg("W",9050,"") 
						#9050 A Territory Code must be entered
						NEXT FIELD terr_code 
					END IF 
					SELECT sale_code INTO glob_arr_rec_suburbarea[l_idx].sale_code FROM territory 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND terr_code = glob_arr_rec_suburbarea[l_idx].terr_code 
					IF status = notfound THEN 
						LET l_msgresp = kandoomsg("W",9203,"") 
						#9203 This territory code IS NOT found - use window
						NEXT FIELD terr_code 
					END IF 
					NEXT FIELD previous 

				OTHERWISE 
					NEXT FIELD terr_code 
			END CASE 

		AFTER FIELD sale_code 
			IF glob_arr_rec_suburbarea[l_idx].sale_code IS NOT NULL THEN 
				SELECT unique(1) FROM salesperson 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND sale_code = glob_arr_rec_suburbarea[l_idx].sale_code 

				IF status = notfound THEN 
					LET l_msgresp = kandoomsg("A",9032,"") 
					#9032 Salesperson code NOT found; Try Window.
					NEXT FIELD sale_code 
				END IF 

				SELECT * INTO l_rec_territory.* 
				FROM territory 
				WHERE terr_code = glob_arr_rec_suburbarea[l_idx].terr_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 

				IF (l_rec_territory.sale_code IS NOT NULL AND 
				l_rec_territory.sale_code != glob_arr_rec_suburbarea[l_idx].sale_code) THEN 
					LET l_msgresp = kandoomsg("A",7043,"") 
					LET glob_arr_rec_suburbarea[l_idx].sale_code = l_rec_territory.sale_code 
					#7043 Error: Setup of salespersons AND territories IS incorrect.
					#        Refer Menus AZ3 AND AZT respectively.
					NEXT FIELD sale_code 
				END IF 
			END IF 

		ON KEY (F2) --delete marker 
			CASE 
				WHEN infield(scroll_flag) 
					IF glob_arr_rec_suburbarea[l_idx].scroll_flag IS NULL THEN 
						LET glob_arr_rec_suburbarea[l_idx].scroll_flag = "*" 
						LET glob_l_del_cnt = glob_l_del_cnt + 1 
					ELSE 
						LET glob_arr_rec_suburbarea[l_idx].scroll_flag = NULL 
						LET glob_l_del_cnt = glob_l_del_cnt - 1 
					END IF 
					NEXT FIELD scroll_flag 
			END CASE 

			#      AFTER ROW
			#         DISPLAY glob_arr_rec_suburbarea[l_idx].* TO sr_suburbarea[scrn].*


		ON ACTION "LOOKUP" infield (waregrp_code) 
			LET l_winds_text = NULL 
			LET l_winds_text = show_waregrp() 
			IF l_winds_text IS NOT NULL THEN 
				LET glob_arr_rec_suburbarea[l_idx].waregrp_code = l_winds_text 
				DISPLAY BY NAME glob_arr_rec_suburbarea[l_idx].waregrp_code 

			END IF 
			OPTIONS INSERT KEY f1, 
			DELETE KEY f36 
			NEXT FIELD waregrp_code 

		ON ACTION "LOOKUP" infield (cart_area_code) 
			LET l_winds_text = NULL 
			LET l_winds_text = show_cart_area(glob_rec_kandoouser.cmpy_code) 
			IF l_winds_text IS NOT NULL THEN 
				LET glob_arr_rec_suburbarea[l_idx].cart_area_code = l_winds_text 
				DISPLAY BY NAME glob_arr_rec_suburbarea[l_idx].cart_area_code 

			END IF 
			OPTIONS INSERT KEY f1, 
			DELETE KEY f36 
			NEXT FIELD cart_area_code 

		ON ACTION "LOOKUP" infield (terr_code) 
			LET l_winds_text = NULL 
			LET l_winds_text = show_territory(glob_rec_kandoouser.cmpy_code,"") 
			IF l_winds_text IS NOT NULL THEN 
				LET glob_arr_rec_suburbarea[l_idx].terr_code = l_winds_text 
				DISPLAY BY NAME glob_arr_rec_suburbarea[l_idx].terr_code 

			END IF 
			OPTIONS INSERT KEY f1, 
			DELETE KEY f36 
			NEXT FIELD terr_code 

		ON ACTION "LOOKUP" infield (sale_code) 
			LET l_winds_text = NULL 
			LET l_winds_text = show_sale(glob_rec_kandoouser.cmpy_code) 
			IF l_winds_text IS NOT NULL THEN 
				LET glob_arr_rec_suburbarea[l_idx].sale_code = l_winds_text 
				DISPLAY BY NAME glob_arr_rec_suburbarea[l_idx].sale_code 

			END IF 
			OPTIONS INSERT KEY f1, 
			DELETE KEY f36 
			NEXT FIELD sale_code 

		AFTER INPUT 
			LET l_idx = arr_curr() #??? 

			#	DISPLAY "AFTER INPUT arr_curr()=", arr_curr()
			#	DISPLAY "AFTER INPUT arr_count()=", arr_count()

			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 

				#            IF NOT (infield(scroll_flag)) THEN
				#               IF l_rec_suburbarea.waregrp_code IS NULL THEN
				#                  FOR l_idx = arr_curr() TO arr_count()
				#                     LET glob_arr_rec_suburbarea[l_idx].* = glob_arr_rec_suburbarea[l_idx+1].*
				#                     IF l_idx = arr_count() THEN
				#                        #INITIALIZE glob_arr_rec_suburbarea[l_idx].* TO NULL
				#                        CALL glob_arr_rec_suburbarea.deleteElement(l_idx)
				#                     END IF
				#                     IF scrn <= 8 THEN
				#                        DISPLAY glob_arr_rec_suburbarea[l_idx].* TO sr_suburbarea[scrn].*
				#
				#                        LET scrn = scrn + 1
				#                     END IF
				#                  END FOR
				#                  LET scrn = scr_line()
				#                  LET int_flag = FALSE
				#                  LET quit_flag = FALSE
				#                  NEXT FIELD scroll_flag
				#               ELSE
				#                  LET glob_arr_rec_suburbarea[l_idx].* = l_rec_suburbarea.*
				#                  LET int_flag = FALSE
				#                  LET quit_flag = FALSE
				#                  NEXT FIELD scroll_flag
				#               END IF
				#            END IF

			ELSE 

				IF glob_arr_rec_suburbarea[l_idx].terr_code IS NOT NULL THEN 
					SELECT sale_code INTO l_rec_territory.sale_code FROM territory 
					WHERE terr_code = glob_arr_rec_suburbarea[l_idx].terr_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 

					IF status = notfound THEN 
						LET l_msgresp = kandoomsg("W",9203,"") 
						#9203 Territory NOT found; Try window.
						NEXT FIELD terr_code 
					END IF 

					IF glob_arr_rec_suburbarea[l_idx].sale_code IS NOT NULL THEN 
						SELECT unique(1) FROM salesperson 
						WHERE sale_code = glob_arr_rec_suburbarea[l_idx].sale_code 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code 
						IF status = notfound THEN 
							LET l_msgresp = kandoomsg("A",9032,"") 
							#9032 Salesperson code NOT found; Try Window.
							NEXT FIELD sale_code 
						END IF 
					END IF 

					IF (l_rec_territory.sale_code IS NOT NULL AND 
					l_rec_territory.sale_code != glob_arr_rec_suburbarea[l_idx].sale_code) THEN 
						LET l_msgresp = kandoomsg("A",7043,"") 
						LET glob_arr_rec_suburbarea[l_idx].sale_code = l_rec_territory.sale_code 
						#7043 Error: Setup of salespersons AND territories IS incorrect.
						#        Refer Menus AZ3 AND AZT respectively.
						NEXT FIELD territory_code 
					END IF 

				END IF 
				LET glob_arr_count = arr_count() 

			END IF 

			#      ON KEY (control-w)
			#         CALL kandoohelp("")

	END INPUT 
END FUNCTION 


##############################################################
# FUNCTION edit_suburb(p_suburb_code)
#
#
##############################################################
FUNCTION edit_suburb(p_suburb_code) 
	DEFINE p_suburb_code LIKE suburb.suburb_code 
	DEFINE l_next_suburb_code LIKE suburb.suburb_code 

	DEFINE l_rec_s_suburb RECORD LIKE suburb.* 
	DEFINE l_rec_r_suburb RECORD LIKE suburb.* 
	DEFINE l_rec_supply RECORD LIKE supply.* 
	DEFINE l_rec_cartarea RECORD LIKE cartarea.* 
	DEFINE l_rec_territory RECORD LIKE territory.* 
	DEFINE l_winds_text CHAR(40) 
	DEFINE l_sqlerrd INTEGER 
	DEFINE l_rec_suburbarea RECORD LIKE suburbarea.* 
	DEFINE l_idx SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	INITIALIZE l_rec_r_suburb.* TO NULL 
	INITIALIZE l_rec_cartarea.* TO NULL 
	INITIALIZE l_rec_territory.* TO NULL 

	IF p_suburb_code IS NOT NULL THEN 
		SELECT * INTO l_rec_r_suburb.* FROM suburb 
		WHERE suburb_code = p_suburb_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		#-DECLARE CURSOR FOR suburbarea TO fill ARRAY variable -#
	ELSE 
		LET l_rec_r_suburb.cmpy_code = glob_rec_kandoouser.cmpy_code 
	END IF 

	DELETE FROM t_supply 

	DECLARE c_supply3 CURSOR FOR 
	SELECT * FROM supply 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND suburb_code = p_suburb_code 

	FOREACH c_supply3 INTO l_rec_supply.* 
		INSERT INTO t_supply VALUES (l_rec_supply.*) 
	END FOREACH 

	OPEN WINDOW u126 with FORM "U126" 
	CALL windecoration_u("U126") 

	DISPLAY BY NAME l_rec_r_suburb.suburb_text, 
	l_rec_r_suburb.state_code, 
	l_rec_r_suburb.post_code 

	LET l_msgresp = kandoomsg("W",1018,"") 
	#1018 " Enter Suburb Details - F10 FOR Supply Locations
	INPUT BY NAME l_rec_r_suburb.suburb_text, 
	l_rec_r_suburb.state_code, 
	l_rec_r_suburb.post_code WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","U51","input-suburb") 
			CALL comboList_state("state_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,glob_rec_company.country_code,COMBO_NULL_SPACE) 
			DISPLAY glob_rec_company.country_code TO country_code #note: suburb TABLE has currently no country COLUMN 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "REFRESH" 
			CALL windecoration_u("U126") 

		BEFORE FIELD suburb_text 
			IF p_suburb_code IS NOT NULL THEN 
				NEXT FIELD state_code 
			END IF 
			LET l_msgresp = kandoomsg("W",1019,"") 
			#1019 " Enter Suburb Details

		AFTER FIELD suburb_text 
			LET l_msgresp = kandoomsg("W",1018,"") 
			#1018 " Enter Suburb Details - F10 FOR Supply Locations
			IF l_rec_r_suburb.suburb_text IS NULL THEN 
				LET l_msgresp = kandoomsg("W",9035,"") 
				#9035 " Suburb must be entered
				NEXT FIELD suburb_text 
			END IF 

		AFTER FIELD state_code 
			IF l_rec_r_suburb.state_code IS NULL THEN 
				LET l_msgresp = kandoomsg("W",9043,"") 
				#9043 " State must be entered
				NEXT FIELD state_code 
			END IF 

		AFTER FIELD post_code 
			IF l_rec_r_suburb.post_code IS NULL THEN 
				LET l_msgresp = kandoomsg("W",9045,"") 
				#9045 Post Code must be entered
				NEXT FIELD post_code 
			END IF 

		ON KEY (F10) 
			IF infield(suburb_text) THEN 
			ELSE 
				CALL edit_supply(p_suburb_code,l_rec_r_suburb.suburb_text) 
			END IF 

		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF p_suburb_code IS NOT NULL THEN 
					IF l_rec_r_suburb.suburb_text IS NULL THEN 
						LET l_msgresp = kandoomsg("W",9035,"") 
						#9035 " Suburb must be entered
						NEXT FIELD suburb_text 
					END IF 
				END IF 

				IF l_rec_r_suburb.state_code IS NULL THEN 
					LET l_msgresp = kandoomsg("W",9043,"") 
					#9043 " State must be entered
					NEXT FIELD state_code 
				END IF 

				IF l_rec_r_suburb.post_code IS NULL THEN 
					LET l_msgresp = kandoomsg("W",9045,"") 
					#9045 Post Code must be entered
					NEXT FIELD post_code 
				END IF 

				SELECT * INTO l_rec_s_suburb.* FROM suburb 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND suburb_text = l_rec_r_suburb.suburb_text 
				AND state_code = l_rec_r_suburb.state_code 
				AND post_code = l_rec_r_suburb.post_code 

				IF p_suburb_code IS NULL THEN 
					IF status != notfound THEN 
						LET l_msgresp = kandoomsg("W",9047,"") 
						#9047 Suburb/State/Post Code combination already exists
						NEXT FIELD suburb_text 
					END IF 
				ELSE 
					IF l_rec_s_suburb.suburb_code != p_suburb_code THEN 
						IF status != notfound THEN 
							LET l_msgresp = kandoomsg("W",9047,"") 
							#9047 Suburb/State/Post Code combination already exists
							NEXT FIELD suburb_text 
						END IF 
					END IF 
				END IF 
				#- CALL SuburbArea (detail) FUNCTION -#
				#- RETURN TRUE IF OK OR FALSE IF delete pressed
				CALL edit_suburbarea(p_suburb_code) 
				IF int_flag OR quit_flag THEN 
					LET quit_flag = false 
					LET int_flag = false 
					LET l_msgresp = kandoomsg("W",1018,"") 
					#1018 " Enter Suburb Details - F10 FOR Supply Locations
					#NEXT FIELD suburb_text
				END IF 
			END IF 

			#      ON KEY (control-w)
			#         CALL kandoohelp("")
	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
		CLOSE WINDOW u126 
		RETURN false 
	END IF 

	GOTO bypass 

	LABEL recovery: 

	IF error_recover(glob_err_message, status) = "N" THEN 
		CLOSE WINDOW u126 
		RETURN false 
	END IF 

	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	BEGIN WORK 
		IF p_suburb_code IS NULL THEN 
			LET l_rec_r_suburb.suburb_code = 0 
		END IF 

		IF p_suburb_code IS NULL THEN 
			LET glob_err_message = "U51 - inserting suburb" 
			LET l_rec_r_suburb.suburb_code = l_next_suburb_code 
			INSERT INTO suburb VALUES (l_rec_r_suburb.*) 
			LET l_sqlerrd = sqlca.sqlerrd[6] 
			LET l_rec_r_suburb.suburb_code = sqlca.sqlerrd[2] 
		ELSE 
			LET glob_err_message = "U51 - updating suburb" 
			UPDATE suburb 
			SET * = l_rec_r_suburb.* 
			WHERE suburb_code = l_rec_r_suburb.suburb_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET l_sqlerrd = sqlca.sqlerrd[3] 
			#- DELETE FROM suburbarea THEN INSERT INTO suburbarea  -#
			DELETE FROM suburbarea 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND suburb_code = l_rec_r_suburb.suburb_code 
		END IF 

		#- INSERT INTO suburbarea the ARRAY captured -#
		LET glob_err_message = "U51 - inserting INTO suburbarea" 
		FOR l_idx = 1 TO glob_arr_count 
			IF glob_arr_rec_suburbarea[l_idx].waregrp_code IS NOT NULL THEN 
				LET l_rec_suburbarea.cmpy_code =glob_rec_kandoouser.cmpy_code 
				LET l_rec_suburbarea.suburb_code =l_rec_r_suburb.suburb_code 
				LET l_rec_suburbarea.waregrp_code =glob_arr_rec_suburbarea[l_idx].waregrp_code 
				LET l_rec_suburbarea.cart_area_code=glob_arr_rec_suburbarea[l_idx].cart_area_code 
				LET l_rec_suburbarea.terr_code =glob_arr_rec_suburbarea[l_idx].terr_code 
				LET l_rec_suburbarea.sale_code =glob_arr_rec_suburbarea[l_idx].sale_code 
				INSERT INTO suburbarea VALUES (l_rec_suburbarea.*) 
			END IF 
		END FOR 

		IF glob_l_del_cnt > 0 THEN 
			LET l_msgresp = kandoomsg("W",8062,glob_l_del_cnt) 
			#8062 "Confirmation TO Delete ",glob_l_del_cnt," Suburb Division(s)? (Y/N)"
			IF l_msgresp = "Y" THEN 
				FOR l_idx = 1 TO arr_count() 
					IF glob_arr_rec_suburbarea[l_idx].scroll_flag = "*" THEN 
						DELETE FROM suburbarea 
						WHERE waregrp_code = glob_arr_rec_suburbarea[l_idx].waregrp_code 
						AND suburb_code = l_rec_r_suburb.suburb_code 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					END IF 
				END FOR 
			END IF 
			LET glob_l_del_cnt = 0 
		END IF 
		LET glob_err_message = "U51 - Updating supply" 

		DELETE FROM supply 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND suburb_code = l_rec_r_suburb.suburb_code 
		DECLARE c_supply2 CURSOR FOR 
		SELECT * FROM t_supply 

		FOREACH c_supply2 INTO l_rec_supply.* 
			IF p_suburb_code IS NULL THEN 
				LET l_rec_supply.suburb_code = l_rec_r_suburb.suburb_code 
			END IF 
			INSERT INTO supply VALUES (l_rec_supply.*) 
		END FOREACH 

	COMMIT WORK 
	CLOSE WINDOW u126 

	RETURN l_sqlerrd 
END FUNCTION 


##############################################################
# FUNCTION scan_suburb()
#
#
##############################################################
FUNCTION scan_suburb() 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE l_rec_suburb RECORD LIKE suburb.* 
	DEFINE l_arr_rec_suburb DYNAMIC ARRAY OF t_rec_suburb_st_sc_pc_with_scrollflag 
	#	DEFINE l_arr_rec_suburb DYNAMIC ARRAY OF
	#		RECORD
	#         scroll_flag CHAR(1),
	#         suburb_text LIKE suburb.suburb_text,
	#         state_code LIKE suburb.state_code,
	#         post_code LIKE suburb.post_code
	#      END RECORD
	DEFINE l_arr_rec_sub_code DYNAMIC ARRAY OF #array[100] OF RECORD 
		RECORD 
			suburb_code LIKE suburb.suburb_code 
		END RECORD 
		DEFINE pr_scroll_flag CHAR(1) 
		DEFINE l_rec_street RECORD LIKE street.* 
		DEFINE l_rec_supply RECORD LIKE supply.* 
		DEFINE l_rec_suburbarea RECORD LIKE suburbarea.* 
		DEFINE l_street_count INTEGER 
		DEFINE l_curr SMALLINT 
		DEFINE l_cnt SMALLINT 
		DEFINE l_idx SMALLINT 
		DEFINE l_del_cnt SMALLINT 
		DEFINE l_x SMALLINT 
		DEFINE i SMALLINT 
		DEFINE l_rowid INTEGER 
		DEFINE l_msgresp LIKE language.yes_flag 

		IF db_suburb_get_count() > 1000 THEN 
			CALL U51_rpt_query(true) RETURNING l_arr_rec_suburb, l_arr_rec_sub_code 
		ELSE 
			CALL U51_rpt_query(false) RETURNING l_arr_rec_suburb, l_arr_rec_sub_code 
		END IF 


		-----------------------------------
		LET l_idx = 0 

		FOREACH c_suburb INTO l_rec_suburb.* 
			LET l_idx = l_idx + 1 
			LET l_arr_rec_sub_code[l_idx].suburb_code = l_rec_suburb.suburb_code 
			LET l_arr_rec_suburb[l_idx].suburb_text = l_rec_suburb.suburb_text 
			LET l_arr_rec_suburb[l_idx].state_code = l_rec_suburb.state_code 
			LET l_arr_rec_suburb[l_idx].post_code = l_rec_suburb.post_code 
			#
			#      IF l_idx = 100 THEN
			#         LET l_msgresp = kandoomsg("W",9021,l_idx)
			#         #9021 " First ??? entries Selected Only"
			#         EXIT FOREACH
			#      END IF

		END FOREACH 

		------------------------------

		IF l_arr_rec_suburb.getlength() = 0 THEN 
			LET l_msgresp = kandoomsg("W",9024,"") 
			#9024" No entries satisfied selection criteria "
		END IF 
		OPTIONS INSERT KEY f1, 
		DELETE KEY f36 
		#   CALL set_count(l_idx)
		LET l_msgresp = kandoomsg("U",1056,"") 

		#1056 F1 Add; F2 Delete; F6 Delete Street; F7 Copy Street; F8 Copy Suburb
		INPUT ARRAY l_arr_rec_suburb WITHOUT DEFAULTS FROM sr_suburb.* attribute(UNBUFFERED, append ROW = false,auto append = false, DELETE ROW = false, INSERT ROW = false) 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","U51","input-arr-suburb") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON ACTION "FILTER" 
				CALL U51_rpt_query(true) RETURNING l_arr_rec_suburb, l_arr_rec_sub_code 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				#			LET pr_scroll_flag = l_arr_rec_suburb[l_idx].scroll_flag
				#		AFTER ROW
				#			LET l_arr_rec_suburb[l_idx].scroll_flag = pr_scroll_flag

			BEFORE FIELD suburb_text 
				NEXT FIELD scroll_flag 

			BEFORE FIELD state_code 
				NEXT FIELD scroll_flag 

			BEFORE FIELD post_code 
				NEXT FIELD scroll_flag 


				#      BEFORE FIELD scroll_flag
				#         LET l_idx = arr_curr()
				#         LET scrn = scr_line()
				#         LET pr_scroll_flag = l_arr_rec_suburb[l_idx].scroll_flag
				#         DISPLAY l_arr_rec_suburb[l_idx].* TO sr_suburb[scrn].*

				#      AFTER FIELD scroll_flag
				#         LET l_arr_rec_suburb[l_idx].scroll_flag = pr_scroll_flag
				#         DISPLAY l_arr_rec_suburb[l_idx].scroll_flag TO sr_suburb[scrn].scroll_flag

				#         IF fgl_lastkey() = fgl_keyval("down") THEN
				#
				#            IF arr_curr() >= arr_count() THEN
				#               LET l_msgresp=kandoomsg("W",9001,"")
				#               #9001 There no more rows...
				#               NEXT FIELD scroll_flag
				#            END IF
				#
				#            IF l_arr_rec_suburb[l_idx+1].suburb_text IS NULL THEN
				#               LET l_msgresp=kandoomsg("W",9001,"")
				#               #9001 There no more rows...
				#               NEXT FIELD scroll_flag
				#            END IF
				#
				#         END IF

			ON ACTION ("DoubleClick","EDIT") 
				LET l_curr = arr_curr() 
				LET l_idx = arr_curr() 
				IF l_arr_rec_suburb[l_idx].suburb_text IS NOT NULL THEN 
					LET l_rec_suburb.suburb_code = l_arr_rec_sub_code[l_idx].suburb_code 
					LET l_curr = arr_curr() --again ?? 
					LET l_cnt = arr_count() 
					#LET l_cnt = l_arr_rec_suburb.getLength()
					IF edit_suburb(l_rec_suburb.suburb_code) THEN 
						SELECT * INTO l_rec_suburb.* FROM suburb 
						WHERE suburb_code = l_rec_suburb.suburb_code 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code 
						LET l_arr_rec_suburb[l_idx].suburb_text = l_rec_suburb.suburb_text 
						LET l_arr_rec_suburb[l_idx].state_code = l_rec_suburb.state_code 
						LET l_arr_rec_suburb[l_idx].post_code = l_rec_suburb.post_code 
					END IF 

				END IF 
				CALL U51_rpt_query(false) RETURNING l_arr_rec_suburb, l_arr_rec_sub_code 
				#         NEXT FIELD scroll_flag

				#      BEFORE FIELD suburb_text
				#      			LET l_curr = arr_curr()
				#         IF l_arr_rec_suburb[l_idx].suburb_text IS NOT NULL THEN
				#
				#            LET l_rec_suburb.suburb_code = l_arr_rec_sub_code[l_idx].suburb_code
				#            LET l_curr = arr_curr()
				#            LET l_cnt = arr_count()
				#            IF edit_suburb(l_rec_suburb.suburb_code) THEN
				#               SELECT * INTO l_rec_suburb.* FROM suburb
				#                WHERE suburb_code = l_rec_suburb.suburb_code
				#                  AND cmpy_code = glob_rec_kandoouser.cmpy_code
				#               LET l_arr_rec_suburb[l_idx].suburb_text = l_rec_suburb.suburb_text
				#               LET l_arr_rec_suburb[l_idx].state_code = l_rec_suburb.state_code
				#               LET l_arr_rec_suburb[l_idx].post_code = l_rec_suburb.post_code
				#            END IF
				#
				#         END IF
				#         NEXT FIELD scroll_flag

				#		ON ACTION "INSERT"
				#			LET l_curr = arr_curr()
				#            LET l_rowid = edit_suburb("")


			ON ACTION "NEW" 
				#BEFORE INSERT
				LET l_curr = arr_curr() 

				#DISPLAY "arr_curr()=", arr_curr()
				#DISPLAY "arr_count()=", arr_count()

				#         IF arr_curr() < arr_count() THEN
				#            LET l_curr = arr_curr()
				#            LET l_cnt = arr_count()
				#            LET l_rowid = edit_suburb("")
				CALL edit_suburb("") 
				#            IF l_rowid = 0 THEN
				#
				#               FOR l_idx = l_curr TO l_cnt
				#                  LET l_arr_rec_suburb[l_idx].* = l_arr_rec_suburb[l_idx+1].*
				#                  IF scrn <= 12 THEN
				#                     DISPLAY l_arr_rec_suburb[l_idx].* TO sr_suburb[scrn].*
				#
				#                     LET scrn = scrn + 1
				#                  END IF
				#               END FOR
				#
				#               INITIALIZE l_arr_rec_suburb[l_idx].* TO NULL
				#            ELSE
				#
				#               FOR l_x = arr_count() TO (l_idx + 1) step -1
				#                  LET l_arr_rec_sub_code[l_x].suburb_code = l_arr_rec_sub_code[l_x-1].suburb_code
				#               END FOR
				#
				#               SELECT * INTO l_rec_suburb.* FROM suburb
				#                WHERE rowid = l_rowid
				#               LET l_arr_rec_suburb[l_idx].suburb_text = l_rec_suburb.suburb_text
				#               LET l_arr_rec_suburb[l_idx].state_code = l_rec_suburb.state_code
				#               LET l_arr_rec_suburb[l_idx].post_code = l_rec_suburb.post_code
				#               LET l_arr_rec_sub_code[l_idx].suburb_code = l_rec_suburb.suburb_code
				#            END IF
				#         ELSE
				#            IF l_idx > 1 THEN
				#               LET l_msgresp = kandoomsg("W",9001,"")
				#               #9001 There are no more rows....
				#            END IF
				#         END IF
				CALL U51_rpt_query(false) RETURNING l_arr_rec_suburb, l_arr_rec_sub_code 



			ON ACTION "DELETE" 
				LET l_del_cnt = 0 
				FOR i = 1 TO l_arr_rec_suburb.getlength() 
					IF l_arr_rec_suburb[i].scroll_flag = "*" THEN 
						LET l_del_cnt = l_del_cnt + 1 
					END IF 
				END FOR 

				BEGIN WORK 

					IF l_del_cnt = 0 AND l_arr_rec_suburb.getlength() > 0 THEN 
						LET l_arr_rec_suburb[l_idx].scroll_flag = "*" 
						LET l_del_cnt = 1 
					END IF 

					IF l_del_cnt > 0 THEN 
						LET l_msgresp = kandoomsg("W",8005,l_del_cnt) 
						#8005 Confirm TO Delete ",l_del_cnt," Suburb(s)? (Y/N)"
						IF l_msgresp = "Y" THEN 

							IF glob_next_action = 0 THEN 
								#------------------------------------------------------------
								LET l_rpt_idx = rpt_start(getmoduleid(),"U51_rpt_list_suburb_log","N/A", RPT_SHOW_RMS_DIALOG)
								IF l_rpt_idx = 0 THEN #User pressed CANCEL
									RETURN FALSE
								END IF	
								START REPORT U51_rpt_list_suburb_log TO rpt_get_report_file_with_path2(l_rpt_idx)
								WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
								TOP MARGIN = 0, 
								BOTTOM MARGIN = 0, 
								LEFT MARGIN = 0, 
								RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
								#------------------------------------------------------------
							END IF 

							FOR l_idx = 1 TO arr_count() 
								IF l_arr_rec_suburb[l_idx].scroll_flag = "*" THEN 
									DECLARE c2_street CURSOR FOR 
									SELECT * FROM street 
									WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
									AND suburb_code = l_arr_rec_sub_code[l_idx].suburb_code 
									INITIALIZE l_rec_supply.* TO NULL 
									INITIALIZE l_rec_suburbarea.* TO NULL 
									LET glob_next_action = glob_next_action + 1 

									FOREACH c2_street INTO l_rec_street.* 
										#------------------------------------------------------------
										OUTPUT TO REPORT U51_rpt_list_suburb_log(l_rpt_idx,
										l_rec_street.*,l_arr_rec_sub_code[l_idx].suburb_code,"","1", 
										glob_next_action, 
										l_rec_supply.*,l_rec_suburbarea.*) 
										#------------------------------------------------------------
									

									END FOREACH 

									DELETE FROM street 
									WHERE suburb_code = l_arr_rec_sub_code[l_idx].suburb_code 
									AND cmpy_code = glob_rec_kandoouser.cmpy_code 
									DECLARE c2_supply CURSOR FOR 
									SELECT * FROM supply 
									WHERE suburb_code = l_arr_rec_sub_code[l_idx].suburb_code 
									AND cmpy_code = glob_rec_kandoouser.cmpy_code 
									INITIALIZE l_rec_street.* TO NULL 
									INITIALIZE l_rec_suburbarea.* TO NULL 
									LET glob_next_action = glob_next_action + 1 

									FOREACH c2_supply INTO l_rec_supply.* 
										#------------------------------------------------------------
										OUTPUT TO REPORT U51_rpt_list_suburb_log(l_rpt_idx,
										l_rec_street.*,l_arr_rec_sub_code[l_idx].suburb_code,"","7", 
										glob_next_action, 
										l_rec_supply.*,l_rec_suburbarea.*) 
										#------------------------------------------------------------ 
									END FOREACH 

									DELETE FROM supply 
									WHERE suburb_code = l_arr_rec_sub_code[l_idx].suburb_code 
									AND cmpy_code = glob_rec_kandoouser.cmpy_code 

									DECLARE c2_suburbarea CURSOR FOR 
									SELECT * FROM suburbarea 
									WHERE suburb_code = l_arr_rec_sub_code[l_idx].suburb_code 
									AND cmpy_code = glob_rec_kandoouser.cmpy_code 

									INITIALIZE l_rec_street.* TO NULL 
									INITIALIZE l_rec_supply.* TO NULL 
									LET glob_next_action = glob_next_action + 1 

									FOREACH c2_suburbarea INTO l_rec_suburbarea.* 
										#------------------------------------------------------------
										OUTPUT TO REPORT U51_rpt_list_suburb_log(l_rpt_idx,
										l_rec_street.*,l_arr_rec_sub_code[l_idx].suburb_code,"","8", 
										glob_next_action, 
										l_rec_supply.*,l_rec_suburbarea.*) 
										#------------------------------------------------------------
									END FOREACH 

									DELETE FROM suburbarea 
									WHERE suburb_code = l_arr_rec_sub_code[l_idx].suburb_code 
									AND cmpy_code = glob_rec_kandoouser.cmpy_code 
									INITIALIZE l_rec_street.* TO NULL 
									INITIALIZE l_rec_supply.* TO NULL 
									INITIALIZE l_rec_suburbarea.* TO NULL 
									LET glob_next_action = glob_next_action + 1 

										#------------------------------------------------------------
										OUTPUT TO REPORT U51_rpt_list_suburb_log(l_rpt_idx,
										l_rec_street.*,l_arr_rec_sub_code[l_idx].suburb_code,"","6", 
										glob_next_action, 
										l_rec_supply.*,l_rec_suburbarea.*) 
										#------------------------------------------------------------
									DELETE FROM suburb 
									WHERE suburb_code = l_arr_rec_sub_code[l_idx].suburb_code 
									AND cmpy_code = glob_rec_kandoouser.cmpy_code 
								END IF 
							END FOR 
						END IF 
					END IF 
				COMMIT WORK 





			ON KEY (F6) infield (scroll_flag) --delete street 
				CALL delete_streets(l_arr_rec_sub_code[l_idx].suburb_code) 
				LET l_msgresp = kandoomsg("U",1056,"") 
				#1056 F1 Add; F6 Delete Street; F7 Copy Street; F8 Copy Suburb
				CALL U51_rpt_query(false) RETURNING l_arr_rec_suburb, l_arr_rec_sub_code 

			ON KEY (F7) infield (scroll_flag) --copy street 
				CALL copy_streets(l_arr_rec_sub_code[l_idx].suburb_code) 
				LET l_msgresp = kandoomsg("U",1056,"") 
				#1056 F1 Add; F6 Delete Street; F7 Copy Street; F8 Copy Suburb
				CALL U51_rpt_query(false) RETURNING l_arr_rec_suburb, l_arr_rec_sub_code 

			ON KEY (F8) infield (scroll_flag) -- f8 copy suburb 
				CALL move_suburb(l_arr_rec_sub_code[l_idx].suburb_code) 
				LET l_msgresp = kandoomsg("U",1056,"") 
				#1056 F1 Add; F6 Delete Street; F7 Copy Street; F8 Copy Suburb
				CALL U51_rpt_query(false) RETURNING l_arr_rec_suburb, l_arr_rec_sub_code 

				#      ON KEY(F2) infield(scroll_flag) --delete
				#        SELECT count(*) INTO l_street_count FROM street
				#         WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
				#           AND suburb_code = l_arr_rec_sub_code[l_idx].suburb_code
				#
				#        IF l_street_count IS NULL THEN
				#           LET l_street_count = 0
				#        END IF
				#
				#        IF kandoomsg("U",8033," ") = "N" THEN
				#           NEXT FIELD scroll_flag
				#        END IF
				#
				#        IF l_arr_rec_suburb[l_idx].scroll_flag IS NULL THEN
				#           LET l_arr_rec_suburb[l_idx].scroll_flag = "*"
				#           LET l_del_cnt = l_del_cnt + 1
				#        ELSE
				#           LET l_arr_rec_suburb[l_idx].scroll_flag = NULL
				#           LET l_del_cnt = l_del_cnt - 1
				#        END IF
				#
				#        NEXT FIELD scroll_flag


				#      AFTER ROW
				#         DISPLAY l_arr_rec_suburb[l_idx].*
				#              TO sr_suburb[scrn].*
				#
				#      ON KEY (control-w)
				#         CALL kandoohelp("")

		END INPUT 
		##############################

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		END IF 
		#   ELSE
		#      IF l_del_cnt > 0 THEN
		#         IF glob_next_action = 0 THEN
		#            LET glob_rpt_output = init_report(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,"Suburb Audit Log")
		#            START REPORT U51_rpt_list_suburb_log TO glob_rpt_output
		#         END IF
		#      END IF
		#
		#      GOTO bypass
		#
		#      label recovery:
		#
		#      IF error_recover(glob_err_message, STATUS) = "N" THEN
		#         CLOSE WINDOW U120
		#         RETURN
		#      END IF
		#
		#      label bypass:
		#
		#      WHENEVER ERROR GOTO recovery
		{
		      BEGIN WORK

		      IF l_del_cnt > 0 THEN
		         LET l_msgresp = kandoomsg("W",8005,l_del_cnt)
		#8005 Confirm TO Delete ",l_del_cnt," Suburb(s)? (Y/N)"
		         IF l_msgresp = "Y" THEN

		            FOR l_idx = 1 TO arr_count()
		               IF l_arr_rec_suburb[l_idx].scroll_flag = "*" THEN
		                  DECLARE c2_street CURSOR FOR
		                     SELECT * FROM street
		                      WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
		                        AND suburb_code = l_arr_rec_sub_code[l_idx].suburb_code
		                  INITIALIZE l_rec_supply.* TO NULL
		                  INITIALIZE l_rec_suburbarea.* TO NULL
		                  LET glob_next_action = glob_next_action + 1

		                  FOREACH c2_street INTO l_rec_street.*
		                     OUTPUT TO REPORT U51_rpt_list_suburb_log(l_rec_street.*,
		                                                 l_arr_rec_sub_code[l_idx].suburb_code,
		                                                 "","1",glob_next_action,
		                                                 l_rec_supply.*,l_rec_suburbarea.*)
		                  END FOREACH

		                  DELETE FROM street
		                   WHERE suburb_code = l_arr_rec_sub_code[l_idx].suburb_code
		                     AND cmpy_code = glob_rec_kandoouser.cmpy_code
		                  DECLARE c2_supply CURSOR FOR
		                     SELECT * FROM supply
		                      WHERE suburb_code = l_arr_rec_sub_code[l_idx].suburb_code
		                        AND cmpy_code = glob_rec_kandoouser.cmpy_code
		                  INITIALIZE l_rec_street.* TO NULL
		                  INITIALIZE l_rec_suburbarea.* TO NULL
		                  LET glob_next_action = glob_next_action + 1

		                  FOREACH c2_supply INTO l_rec_supply.*
		                     OUTPUT TO REPORT U51_rpt_list_suburb_log(l_rec_street.*,
		                                                 l_arr_rec_sub_code[l_idx].suburb_code,
		                                                 "","7",glob_next_action,
		                                                 l_rec_supply.*,l_rec_suburbarea.*)
		                  END FOREACH

		                  DELETE FROM supply
		                   WHERE suburb_code = l_arr_rec_sub_code[l_idx].suburb_code
		                     AND cmpy_code = glob_rec_kandoouser.cmpy_code

		                  DECLARE c2_suburbarea CURSOR FOR
		                     SELECT * FROM suburbarea
		                      WHERE suburb_code = l_arr_rec_sub_code[l_idx].suburb_code
		                        AND cmpy_code = glob_rec_kandoouser.cmpy_code

		                  INITIALIZE l_rec_street.* TO NULL
		                  INITIALIZE l_rec_supply.* TO NULL
		                  LET glob_next_action = glob_next_action + 1

		                  FOREACH c2_suburbarea INTO l_rec_suburbarea.*
		                     OUTPUT TO REPORT U51_rpt_list_suburb_log(l_rec_street.*,
		                                                 l_arr_rec_sub_code[l_idx].suburb_code,
		                                                 "","8",glob_next_action,
		                                                 l_rec_supply.*,l_rec_suburbarea.*)
		                  END FOREACH

		                  DELETE FROM suburbarea
		                   WHERE suburb_code = l_arr_rec_sub_code[l_idx].suburb_code
		                     AND cmpy_code   = glob_rec_kandoouser.cmpy_code
		                  INITIALIZE l_rec_street.* TO NULL
		                  INITIALIZE l_rec_supply.* TO NULL
		                  INITIALIZE l_rec_suburbarea.* TO NULL
		                  LET glob_next_action = glob_next_action + 1

		                  OUTPUT TO REPORT U51_rpt_list_suburb_log(l_rec_street.*,
		                                              l_arr_rec_sub_code[l_idx].suburb_code,
		                                              "","6",glob_next_action,
		                                              l_rec_supply.*,l_rec_suburbarea.*)
		                  DELETE FROM suburb
		                   WHERE suburb_code = l_arr_rec_sub_code[l_idx].suburb_code
		                     AND cmpy_code = glob_rec_kandoouser.cmpy_code
		               END IF
		            END FOR
		         END IF
		      END IF
		      COMMIT WORK

		   END IF
		}
END FUNCTION 


##############################################################
# FUNCTION delete_streets(p_suburb_code)
##############################################################
FUNCTION delete_streets(p_suburb_code)
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE p_suburb_code LIKE suburb.suburb_code 
	DEFINE l_rec_street RECORD LIKE street.* 
	DEFINE l_rec_supply RECORD LIKE supply.* 
	DEFINE l_rec_suburbarea RECORD LIKE suburbarea.* 
	DEFINE l_street_count INTEGER 
	DEFINE l_err_message CHAR(60) 
	DEFINE l_msgresp LIKE language.yes_flag 

	SELECT count(*) INTO l_street_count FROM street 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND suburb_code = p_suburb_code 

	IF l_street_count IS NULL 
	OR l_street_count = 0 THEN 
		LET l_msgresp = kandoomsg("U",9931,"") 
		CALL fgl_winmessage("No streets found","This suburb has no streets TO delete","info") 
		#9931 This suburb has no streets TO delete
		RETURN 
	END IF 

	IF kandoomsg("U",8018,l_street_count) = "N" THEN 
		#8018 Confirm TO delete 20 streets
		RETURN 
	END IF 

	LET l_msgresp = kandoomsg("U",1005,"") 
	#1005 Updating Database; Please Wait.

	DECLARE c3_street CURSOR FOR 
	SELECT * FROM street 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND suburb_code = p_suburb_code 
	ORDER BY street_text 

	IF glob_next_action = 0 THEN 
	#------------------------------------------------------------
		LET l_rpt_idx = rpt_start(getmoduleid(),"U51_rpt_list_suburb_log","N/A", RPT_SHOW_RMS_DIALOG)
		IF l_rpt_idx = 0 THEN #User pressed CANCEL
			RETURN FALSE
		END IF	
		START REPORT U51_rpt_list_suburb_log TO rpt_get_report_file_with_path2(l_rpt_idx)
		WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
		TOP MARGIN = 0, 
		BOTTOM MARGIN = 0, 
		LEFT MARGIN = 0, 
		RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
		#------------------------------------------------------------
	END IF 

	LET glob_next_action = glob_next_action + 1 

	#	OPEN WINDOW w1 WITH FORM "U999"
	#	CALL windecoration_u("U999")

	MESSAGE "Deleting Street:" 
	INITIALIZE l_rec_supply.* TO NULL 
	INITIALIZE l_rec_suburbarea.* TO NULL 
	FOREACH c3_street INTO l_rec_street.* 
		MESSAGE l_rec_street.street_text 
		#DISPLAY l_rec_street.st_type_text TO lbLabel3
		#------------------------------------------------------------
		OUTPUT TO REPORT U51_rpt_list_suburb_log(l_rpt_idx,
		l_rec_street.*,p_suburb_code,"","1", 
		glob_next_action, 
		l_rec_supply.*,l_rec_suburbarea.*) 
		#------------------------------------------------------------

	END FOREACH 

	#   CLOSE WINDOW w1

	GOTO bypass 

	LABEL recovery: 

	IF error_recover(l_err_message, status) = "N" THEN 
		RETURN 
	END IF 

	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	-- BEGIN WORK    # ericv 2020-02-26: Useless begin work because it handles only one statement, but it might cause a further -535 error 
		LET l_err_message = "U51 - Deleting Street Records" 
		DELETE FROM street 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND suburb_code = p_suburb_code 
		LET l_street_count = sqlca.sqlerrd[3] 

	-- COMMIT WORK # goes with the previous BEGIN WORK 
	WHENEVER ERROR stop 
	LET l_msgresp = kandoomsg("U",7033,l_street_count) 
	#7033 20 Street have been successfully deleted
END FUNCTION 


##############################################################
# FUNCTION copy_streets(p_suburb_code)
##############################################################
FUNCTION copy_streets(p_suburb_code) 
	DEFINE p_suburb_code LIKE suburb.suburb_code
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	 
	DEFINE l_rec_suburb RECORD LIKE suburb.* 
	DEFINE l_rec_street RECORD LIKE street.* 
	DEFINE l_rec_supply RECORD LIKE supply.* 
	DEFINE l_rec_suburbarea RECORD LIKE suburbarea.* 
	DEFINE l_street_count INTEGER 
	DEFINE l_suburb_text LIKE suburb.suburb_text 
	DEFINE l_state_code LIKE suburb.state_code 
	DEFINE l_post_code LIKE suburb.post_code 
	DEFINE l_winds_text CHAR(60) 
	DEFINE l_err_message CHAR(60) 
	DEFINE l_msgresp LIKE language.yes_flag 

	SELECT * INTO l_rec_suburb.* FROM suburb 
	WHERE suburb_code = p_suburb_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 

	IF status = notfound THEN 
		LET l_msgresp = kandoomsg("U",7001,"Suburb") 
		#7001 Logic Error: Suburb RECORD does NOT exist
		RETURN 
	END IF 

	SELECT count(*) INTO l_street_count FROM street 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND suburb_code = p_suburb_code 

	IF l_street_count IS NULL 
	OR l_street_count = 0 THEN 
		LET l_msgresp = kandoomsg("U",9931,"") 
		CALL fgl_winmessage("Not streets found to copy","This suburb has no streets TO copy","info") 
		#9931 This suburb has no streets TO copy
		RETURN 
	END IF 

	OPEN WINDOW u208 with FORM "U208" 
	CALL windecoration_u("U208") 

	LET l_suburb_text = l_rec_suburb.suburb_text 
	LET l_state_code = l_rec_suburb.state_code 
	LET l_post_code = l_rec_suburb.post_code 

	DISPLAY l_suburb_text TO pr_suburb_text 
	DISPLAY l_state_code TO pr_state_code 
	DISPLAY l_post_code TO pr_post_code 

	INITIALIZE l_rec_suburb.* TO NULL 
	LET l_msgresp = kandoomsg("U",1020,"Suburb") 
	#1020 Enter Suburb Details; OK TO Continue.

	INPUT BY NAME l_rec_suburb.suburb_text, 
	l_rec_suburb.state_code, 
	l_rec_suburb.post_code WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","U51","input-suburb-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		ON ACTION "LOOKUP" infield (suburb_text) 
			LET l_winds_text = show_wsub(glob_rec_kandoouser.cmpy_code) 
			IF l_winds_text IS NOT NULL THEN 
				LET l_rec_suburb.suburb_code = l_winds_text 
				SELECT * INTO l_rec_suburb.* FROM suburb 
				WHERE suburb_code = l_rec_suburb.suburb_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			END IF 
			NEXT FIELD suburb_text 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				SELECT * INTO l_rec_suburb.* FROM suburb 
				WHERE suburb_text = l_rec_suburb.suburb_text 
				AND state_code = l_rec_suburb.state_code 
				AND post_code = l_rec_suburb.post_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 

				IF status = notfound THEN 
					LET l_msgresp = kandoomsg("U",9105,"") 
					#9105 RECORD NOT found; Try window.
					NEXT FIELD suburb_text 
				END IF 

				IF l_suburb_text = l_rec_suburb.suburb_text 
				AND l_state_code = l_rec_suburb.state_code 
				AND l_post_code = l_rec_suburb.post_code THEN 
					LET l_msgresp = kandoomsg("U",9932,"") 
					#9932 Cannot copy street(s) TO same suburb
					NEXT FIELD suburb_text 
				END IF 
			END IF 

		ON KEY (control-w) 
			CALL kandoohelp("") 

	END INPUT 
	######################

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		CLOSE WINDOW u208 
		RETURN 
	END IF 

	IF kandoomsg("U",8019,l_street_count) = "N" THEN 
		#8019 Confirm TO copy 20 streets TO new suburb
		CLOSE WINDOW u208 
		RETURN 
	END IF 

	LET l_msgresp = kandoomsg("U",1005,"") 
	#1005 Updating Database; Please Wait.

	IF glob_next_action = 0 THEN 
	#------------------------------------------------------------
		LET l_rpt_idx = rpt_start(getmoduleid(),"U51_rpt_list_suburb_log","N/A", RPT_SHOW_RMS_DIALOG)
		IF l_rpt_idx = 0 THEN #User pressed CANCEL
			RETURN FALSE
		END IF	
		START REPORT U51_rpt_list_suburb_log TO rpt_get_report_file_with_path2(l_rpt_idx)
		WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
		TOP MARGIN = 0, 
		BOTTOM MARGIN = 0, 
		LEFT MARGIN = 0, 
		RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
		#------------------------------------------------------------
	END IF 

	GOTO bypass 

	LABEL recovery: 

	IF error_recover(l_err_message, status) = "N" THEN 
		CLOSE WINDOW w1 
		CLOSE WINDOW u208 
		RETURN 
	END IF 

	CLOSE WINDOW w1 

	LABEL bypass: 

	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		DECLARE c_street CURSOR FOR 
		SELECT * FROM street 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND suburb_code = p_suburb_code 
		LET l_street_count = 0 
		LET glob_next_action = glob_next_action + 1 

		#   OPEN WINDOW w1 WITH FORM "U999"
		#	CALL windecoration_u("U999")

		MESSAGE "Copying Street:" 
		INITIALIZE l_rec_supply.* TO NULL 
		INITIALIZE l_rec_suburbarea.* TO NULL 

		FOREACH c_street INTO l_rec_street.* 
			MESSAGE l_rec_street.street_text 

			#DISPLAY l_rec_street.st_type_text TO lbLabel3

			LET l_rec_street.suburb_code = l_rec_suburb.suburb_code 
			LET l_err_message = "U51 - Insert Street Record" 
			SELECT unique 1 FROM street 
			WHERE street_text = l_rec_street.street_text 
			AND st_type_text = l_rec_street.st_type_text 
			AND suburb_code = l_rec_street.suburb_code 
			AND map_number = l_rec_street.map_number 
			AND ref_text = l_rec_street.ref_text 
			AND source_ind = l_rec_street.source_ind 
			AND cmpy_code = l_rec_street.cmpy_code 

			IF status = notfound THEN 
				INSERT INTO street VALUES (l_rec_street.*) 
				LET l_street_count = l_street_count + 1 
			ELSE 
				LET l_rec_street.street_text = l_rec_street.street_text clipped, 
				" ***** Already Exists *****" 
				LET l_rec_street.st_type_text = NULL 
				LET l_rec_street.map_number = NULL 
				LET l_rec_street.ref_text = NULL 
				LET l_rec_street.source_ind = NULL 
			END IF 

			#------------------------------------------------------------
			OUTPUT TO REPORT U51_rpt_list_suburb_log(l_rpt_idx,
			l_rec_street.*,p_suburb_code,"","2", 
			glob_next_action, 
			l_rec_supply.*,l_rec_suburbarea.*) 
			#------------------------------------------------------------

		END FOREACH 
	COMMIT WORK 

	WHENEVER ERROR stop 

	#   CLOSE WINDOW w1
	LET l_msgresp = kandoomsg("U",7034,l_street_count) 
	#7034 20 Street have been successfully inserted

	CLOSE WINDOW u208 
END FUNCTION 


##############################################################
# FUNCTION move_suburb(p_suburb_code)
##############################################################
FUNCTION move_suburb(p_suburb_code) 
	DEFINE p_suburb_code LIKE suburb.suburb_code 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE l_rec_suburb RECORD LIKE suburb.* 
	DEFINE l_rec_street RECORD LIKE street.* 
	DEFINE l_rec_supply RECORD LIKE supply.* 
	DEFINE l_rec_suburbarea RECORD LIKE suburbarea.* 
	DEFINE l_street_count INTEGER 
	DEFINE l_suburb_text LIKE suburb.suburb_text 
	DEFINE l_state_code LIKE suburb.state_code 
	DEFINE l_post_code LIKE suburb.post_code 
	DEFINE l_winds_text CHAR(60) 
	DEFINE l_err_message CHAR(60) 
	DEFINE l_msgresp LIKE language.yes_flag 

	SELECT * INTO l_rec_suburb.* FROM suburb 
	WHERE suburb_code = p_suburb_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 

	IF status = notfound THEN 
		LET l_msgresp = kandoomsg("U",7001,"Suburb") 
		#7001 Logic Error: Suburb RECORD does NOT exist
		RETURN 
	END IF 

	SELECT count(*) INTO l_street_count FROM street 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND suburb_code = p_suburb_code 

	IF l_street_count IS NULL 
	OR l_street_count = 0 THEN 
		#   LET l_msgresp = kandoomsg("U",9931,"")
		#   #9931 This suburb has no streets TO copy
		#   RETURN
	END IF 

	OPEN WINDOW u208 with FORM "U208" 
	CALL windecoration_u("U208") 

	LET l_suburb_text = l_rec_suburb.suburb_text 
	LET l_state_code = l_rec_suburb.state_code 
	LET l_post_code = l_rec_suburb.post_code 

	DISPLAY l_suburb_text TO pr_suburb_text 
	DISPLAY l_state_code TO pr_state_code 
	DISPLAY l_post_code TO pr_post_code 

	INITIALIZE l_rec_suburb.* TO NULL 
	LET l_msgresp = kandoomsg("U",1020,"Suburb") 
	#1020 Enter Suburb Details; OK TO Continue.

	INPUT BY NAME l_rec_suburb.suburb_text, 
	l_rec_suburb.state_code, 
	l_rec_suburb.post_code WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","U51","input-suburb-2") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		ON ACTION "LOOKUP" infield (suburb_text) 
			LET l_winds_text = show_wsub(glob_rec_kandoouser.cmpy_code) 
			IF l_winds_text IS NOT NULL THEN 
				LET l_rec_suburb.suburb_code = l_winds_text 
				SELECT * INTO l_rec_suburb.* FROM suburb 
				WHERE suburb_code = l_rec_suburb.suburb_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			END IF 
			CALL comboList_suburb_code_text("suburb_text",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_SPACE) 

			NEXT FIELD suburb_text 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				SELECT * INTO l_rec_suburb.* FROM suburb 
				WHERE suburb_text = l_rec_suburb.suburb_text 
				AND state_code = l_rec_suburb.state_code 
				AND post_code = l_rec_suburb.post_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 

				IF status = notfound THEN 
					LET l_msgresp = kandoomsg("U",9105,"") 
					#9105 RECORD NOT found; Try window.
					NEXT FIELD suburb_text 
				END IF 

				IF l_suburb_text = l_rec_suburb.suburb_text 
				AND l_state_code = l_rec_suburb.state_code 
				AND l_post_code = l_rec_suburb.post_code THEN 
					LET l_msgresp = kandoomsg("U",9932,"") 
					#9932 Cannot copy street(s) TO same suburb
					NEXT FIELD suburb_text 
				END IF 
			END IF 

		ON KEY (control-w) 
			CALL kandoohelp("") 

	END INPUT 
	##########################

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		CLOSE WINDOW u208 
		RETURN 
	END IF 

	IF kandoomsg("U",8032,l_street_count) = "N" THEN 
		#8032 Confirm TO move suburb details
		CLOSE WINDOW u208 
		RETURN 
	END IF 
	LET l_msgresp = kandoomsg("U",1005,"") 
	#1005 Updating Database; Please Wait.

	IF glob_next_action = 0 THEN 
	#------------------------------------------------------------
		LET l_rpt_idx = rpt_start(getmoduleid(),"U51_rpt_list_suburb_log","N/A", RPT_SHOW_RMS_DIALOG)
		IF l_rpt_idx = 0 THEN #User pressed CANCEL
			RETURN FALSE
		END IF	
		START REPORT U51_rpt_list_suburb_log TO rpt_get_report_file_with_path2(l_rpt_idx)
		WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
		TOP MARGIN = 0, 
		BOTTOM MARGIN = 0, 
		LEFT MARGIN = 0, 
		RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
		#------------------------------------------------------------
	END IF 

	GOTO bypass 
	LABEL recovery: 

	IF error_recover(l_err_message, status) = "N" THEN 
		CLOSE WINDOW w1 
		CLOSE WINDOW u208 
		RETURN 
	END IF 

	CLOSE WINDOW w1 

	LABEL bypass: 

	WHENEVER ERROR GOTO recovery 

	BEGIN WORK 
		DECLARE c4_street CURSOR FOR 
		SELECT * FROM street 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND suburb_code = p_suburb_code 
		LET l_street_count = 0 
		LET glob_next_action = glob_next_action + 1 

		#   OPEN WINDOW w1 WITH FORM "U999"
		#	CALL windecoration_u("U999")

		MESSAGE "Copying Street" --display "Copying Street:" TO lblabel1 

		INITIALIZE l_rec_supply.* TO NULL 
		INITIALIZE l_rec_suburbarea.* TO NULL 

		FOREACH c4_street INTO l_rec_street.* 
			MESSAGE l_rec_street.street_text 
			#DISPLAY l_rec_street.st_type_text TO lbLabel3

			LET l_err_message = "U51 - Deleting Street Record" 
			LET l_rec_street.suburb_code = l_rec_suburb.suburb_code 
			SELECT unique 1 FROM street 
			WHERE street_text = l_rec_street.street_text 
			AND st_type_text = l_rec_street.st_type_text 
			AND suburb_code = l_rec_street.suburb_code 
			AND map_number = l_rec_street.map_number 
			AND ref_text = l_rec_street.ref_text 
			AND source_ind = l_rec_street.source_ind 
			AND cmpy_code = l_rec_street.cmpy_code 
			IF status = notfound THEN 
				LET l_err_message = "U51 - Insert Street Record" 
				INSERT INTO street VALUES (l_rec_street.*) 
				LET l_street_count = l_street_count + 1 
			ELSE 
				LET l_rec_street.street_text = l_rec_street.street_text clipped, 
				" ***** Already Exists *****" 
				LET l_rec_street.st_type_text = NULL 
				LET l_rec_street.map_number = NULL 
				LET l_rec_street.ref_text = NULL 
				LET l_rec_street.source_ind = NULL 
			END IF 

			#------------------------------------------------------------
			OUTPUT TO REPORT U51_rpt_list_suburb_log(l_rpt_idx,
			l_rec_street.*,p_suburb_code,"","3", 
			glob_next_action, 
			l_rec_supply.*,l_rec_suburbarea.*) 
			#------------------------------------------------------------

		END FOREACH 

		LET glob_next_action = glob_next_action + 1 

		DECLARE c3_supply CURSOR FOR 
		SELECT * FROM supply 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND suburb_code = p_suburb_code 

		#   DISPLAY "" TO lbLabel1
		#   DISPLAY "" TO lbLabel2
		#   DISPLAY "" TO lbLabel3
		#   DISPLAY "" TO lbLabel1b
		#   DISPLAY "" TO lbLabel2b
		#   DISPLAY "" TO lbLabel3b

		MESSAGE "Copying Supply:" 
		INITIALIZE l_rec_street.* TO NULL 
		INITIALIZE l_rec_suburbarea.* TO NULL 

		FOREACH c3_supply INTO l_rec_supply.* 
			MESSAGE l_rec_suburb.suburb_text 

			#DISPLAY l_rec_supply.ware_code TO lbLabel3b

			LET l_rec_supply.suburb_code = l_rec_suburb.suburb_code 

			SELECT unique 1 FROM supply 
			WHERE suburb_code = l_rec_supply.suburb_code 
			AND cmpy_code = l_rec_supply.cmpy_code 
			AND ware_code = l_rec_supply.ware_code 
			IF status = notfound THEN 
				LET l_err_message = "U51 - Insert Supply Record" 
				INSERT INTO supply VALUES (l_rec_supply.*) 
			ELSE 
				LET l_rec_supply.km_qty = NULL 
			END IF 

			#------------------------------------------------------------
			OUTPUT TO REPORT U51_rpt_list_suburb_log(l_rpt_idx,
			l_rec_street.*,p_suburb_code,"","4", 
			glob_next_action, 
			l_rec_supply.*,l_rec_suburbarea.*) 
			#------------------------------------------------------------

		END FOREACH 

		LET glob_next_action = glob_next_action + 1 
		DECLARE c3_suburbarea CURSOR FOR 
		SELECT * FROM suburbarea 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND suburb_code = p_suburb_code 

		#   DISPLAY "" TO lbLabel1
		#   DISPLAY "" TO lbLabel2
		#   DISPLAY "" TO lbLabel3
		#   DISPLAY "" TO lbLabel1b
		#   DISPLAY "" TO lbLabel2b
		#   DISPLAY "" TO lbLabel3b

		MESSAGE "Copying Warehouse Group:" 

		INITIALIZE l_rec_street.* TO NULL 
		INITIALIZE l_rec_supply.* TO NULL 

		FOREACH c3_suburbarea INTO l_rec_suburbarea.* 
			MESSAGE l_rec_suburb.suburb_text 

			#DISPLAY l_rec_suburbarea.waregrp_code TO lbLabel3b

			LET l_rec_suburbarea.suburb_code = l_rec_suburb.suburb_code 
			SELECT unique 1 FROM suburbarea 
			WHERE suburb_code = l_rec_suburbarea.suburb_code 
			AND cmpy_code = l_rec_suburbarea.cmpy_code 
			AND waregrp_code = l_rec_suburbarea.waregrp_code 
			IF status = notfound THEN 
				LET l_err_message = "U51 - Insert Suburbarea Record" 
				INSERT INTO suburbarea VALUES (l_rec_suburbarea.*) 
			ELSE 
				LET l_rec_suburbarea.cart_area_code = NULL 
			END IF 
			#------------------------------------------------------------
			OUTPUT TO REPORT U51_rpt_list_suburb_log(l_rpt_idx,
			l_rec_street.*,p_suburb_code,"","5", 
			glob_next_action, 
			l_rec_supply.*,l_rec_suburbarea.*) 
			#------------------------------------------------------------

		END FOREACH 

	COMMIT WORK 

	WHENEVER ERROR stop 

	#   CLOSE WINDOW w1

	LET l_msgresp = kandoomsg("U",7035,l_street_count) 
	#7035 20 Street have been successfully moved

	CLOSE WINDOW u208 
END FUNCTION 


##############################################################
# REPORT U51_rpt_list_suburb_log(p_rec_street,p_from_suburb_code,
##############################################################
REPORT U51_rpt_list_suburb_log(p_rpt_idx,p_rec_street,p_from_suburb_code, 
	p_to_suburb_code,p_rpt_ind, 
	p_next_action,p_rec_supply,p_rec_suburbarea)
	 DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_street RECORD LIKE street.* 
	DEFINE p_from_suburb_code LIKE suburb.suburb_code 
	DEFINE p_to_suburb_code LIKE suburb.suburb_code 
	DEFINE p_rpt_ind CHAR(1) 
	DEFINE p_next_action SMALLINT 
	DEFINE p_rec_supply RECORD LIKE supply.* 
	DEFINE p_rec_suburbarea RECORD LIKE suburbarea.* 

	DEFINE l_rec_suburb RECORD LIKE suburb.* 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_rec_waregrp RECORD LIKE waregrp.* 
	DEFINE l_rec_to_suburb RECORD LIKE suburb.* 
	DEFINE l_supply_count INTEGER 
	DEFINE l_subarea_count INTEGER 
	DEFINE l_street_count INTEGER 

	DEFINE pr_line1, pr_line2, pr_line3 CHAR(132) 
	DEFINE l_line_text CHAR(115) 
	DEFINE l_temp_text CHAR(20) 
	DEFINE x SMALLINT 
	DEFINE y SMALLINT 

	OUTPUT 
--	left margin 1 
	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 		

			IF p_rpt_ind = "1" 
			OR p_rpt_ind = "2" 
			OR p_rpt_ind = "3" THEN 
				PRINT COLUMN 01, "Street", 
				COLUMN 52, "Type", 
				COLUMN 64, "Map Number", 
				COLUMN 76, "Map Reference", 
				COLUMN 90, "Map Source" 
			ELSE 

				IF p_rpt_ind = "4" 
				OR p_rpt_ind = "7" THEN 
					PRINT COLUMN 01, "Warehouse", 
					COLUMN 43, "Kilometres" 
				ELSE 
					IF p_rpt_ind = "5" 
					OR p_rpt_ind = "8" THEN 
						PRINT COLUMN 01, "Warehouse Group", 
						COLUMN 55, "Cartage Area", 
						COLUMN 70, "Territory" 
					ELSE 
						PRINT COLUMN 01, "Suburb Delete" 
					END IF 
				END IF 
			END IF 

			PRINT COLUMN 01, pr_line3 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 		

			SELECT * INTO l_rec_suburb.* FROM suburb 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND suburb_code = p_from_suburb_code 

			SELECT * INTO l_rec_to_suburb.* FROM suburb 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND suburb_code = p_to_suburb_code 
			IF p_rpt_ind = "1" 
			OR p_rpt_ind = "7" 
			OR p_rpt_ind = "8" THEN 
				PRINT COLUMN 01, "DELETED FROM Suburb..... ",l_rec_suburb.suburb_text 
				PRINT COLUMN 01, " State...... ",l_rec_suburb.state_code 
				PRINT COLUMN 01, " Post Code.. ",l_rec_suburb.post_code 
			ELSE 
				IF p_rpt_ind = "2" 
				OR p_rpt_ind = "3" 
				OR p_rpt_ind = "4" 
				OR p_rpt_ind = "5" THEN 
					PRINT COLUMN 01, "COPIED FROM Suburb....",l_rec_suburb.suburb_text, 
					COLUMN 74, "TO Suburb....",l_rec_to_suburb.suburb_text[1,46] 
					PRINT COLUMN 01, " State.....",l_rec_suburb.state_code, 
					COLUMN 74, " State.....",l_rec_to_suburb.state_code 
					PRINT COLUMN 01, " Post Code.",l_rec_suburb.post_code, 
					COLUMN 74, " Post Code.",l_rec_to_suburb.post_code 
				ELSE 
					PRINT COLUMN 01, "DELETED Suburb..... ",l_rec_suburb.suburb_text 
					PRINT COLUMN 01, " State...... ",l_rec_suburb.state_code 
					PRINT COLUMN 01, " Post Code.. ",l_rec_suburb.post_code 
				END IF 
			END IF 
			SKIP 1 line 

		BEFORE GROUP OF p_next_action 
			LET l_street_count = 0 
			LET l_supply_count = 0 
			LET l_subarea_count = 0 
			SKIP TO top OF PAGE 

		ON EVERY ROW 
			IF p_rec_street.street_text IS NOT NULL THEN 
				PRINT COLUMN 01, p_rec_street.street_text, 
				COLUMN 52, p_rec_street.st_type_text, 
				COLUMN 64, p_rec_street.map_number, 
				COLUMN 76, p_rec_street.ref_text, 
				COLUMN 95, p_rec_street.source_ind 
				IF p_rec_street.st_type_text IS NOT NULL THEN 
					LET l_street_count = l_street_count + 1 
				END IF 
			END IF 

			IF p_rec_supply.ware_code IS NOT NULL THEN 
				IF p_rec_supply.km_qty IS NULL THEN 
					LET l_rec_warehouse.desc_text = "***** Already Exists *****" 
				ELSE 
					INITIALIZE l_rec_warehouse.* TO NULL 
					SELECT * INTO l_rec_warehouse.* FROM warehouse 
					WHERE ware_code = p_rec_supply.ware_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET l_supply_count = l_supply_count + 1 
				END IF 
				PRINT COLUMN 01, p_rec_supply.ware_code, 
				COLUMN 05, l_rec_warehouse.desc_text, 
				COLUMN 40, p_rec_supply.km_qty USING "----,--&.&&&&" 
			END IF 
			IF p_rec_suburbarea.waregrp_code IS NOT NULL THEN 
				IF p_rec_suburbarea.cart_area_code IS NULL THEN 
					LET l_rec_waregrp.name_text = "***** Already Exists *****" 
					LET p_rec_suburbarea.terr_code = NULL 
				ELSE 
					INITIALIZE l_rec_waregrp.* TO NULL 
					SELECT * INTO l_rec_waregrp.* FROM waregrp 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND waregrp_code = p_rec_suburbarea.waregrp_code 
					LET l_subarea_count = l_subarea_count + 1 
				END IF 
				PRINT COLUMN 01, p_rec_suburbarea.waregrp_code, 
				COLUMN 10, l_rec_waregrp.name_text, 
				COLUMN 55, p_rec_suburbarea.cart_area_code, 
				COLUMN 70, p_rec_suburbarea.terr_code 
			END IF 

		AFTER GROUP OF p_next_action 
			SKIP 2 line 
			CASE p_rpt_ind 
				WHEN "1" 
					PRINT COLUMN 15, "Number of Streets Deleted: ",l_street_count 
				WHEN "2" 
					PRINT COLUMN 15, "Number of Streets Copied: ",l_street_count 
				WHEN "3" 
					PRINT COLUMN 15, "Number of Streets Copied: ",l_street_count 
				WHEN "4" 
					PRINT COLUMN 15, "Number of Supply Records Copied: ", 
					l_supply_count 
				WHEN "5" 
					PRINT COLUMN 15, "Number of Warehouse Groups Copied: ", 
					l_subarea_count 
				WHEN "7" 
					PRINT COLUMN 15, "Number of Supply Records Deleted: ", 
					l_supply_count 
				WHEN "8" 
					PRINT COLUMN 15, "Number of Warehouse Groups Deleted: ", 
					l_subarea_count 
			END CASE 

		ON LAST ROW 
			SKIP 1 LINES 
			PRINT COLUMN 50, "***** END OF REPORT U51 *****" 
END REPORT 
