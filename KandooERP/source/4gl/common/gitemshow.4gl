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

	Source code beautified by beautify.pl on 2020-01-02 10:35:12	$Id: $
}

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

############################################################
# FUNCTION show_mrwitem(p_item_id)
#
#   gitemshow - show_mrwitem
#               window FUNCTION FOR finding mrwitem records
#               returns item_id
############################################################
FUNCTION show_mrwitem(p_item_id) 
	DEFINE p_item_id LIKE mrwitem.item_id 
	DEFINE l_rec_mrwitem RECORD LIKE mrwitem.* 
	DEFINE l_arr_rec_mrwitem DYNAMIC ARRAY OF RECORD --array[100] OF RECORD 
		scroll_flag CHAR(1), 
		item_id LIKE mrwitem.item_id, 
		item_desc LIKE mrwitem.item_desc 
	END RECORD 
	DEFINE l_idx SMALLINT 
	--	DEFINE scrn SMALLINT
	DEFINE l_query_text CHAR(800) 
	DEFINE l_where_text CHAR(400) 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	OPEN WINDOW g502 with FORM "G502" 
	CALL windecoration_g("G502") 

	WHILE true 
		CLEAR FORM 
		LET l_msgresp = kandoomsg("U",1001,"") 
		#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON item_id, 
		item_desc 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","gitemshow","construct-item") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 


		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_mrwitem.item_id = NULL 
			EXIT WHILE 
		END IF 
		LET l_msgresp = kandoomsg("U",1002,"") 
		#1002 " Searching database - please wait"
		LET l_query_text = "SELECT * FROM mrwitem ", 
		"WHERE ",l_where_text clipped," ", 
		"ORDER BY item_id" 
		WHENEVER ERROR CONTINUE 
		OPTIONS SQL interrupt ON 
		PREPARE s_mrwitem FROM l_query_text 
		DECLARE c_mrwitem CURSOR FOR s_mrwitem 

		LET l_idx = 0 
		FOREACH c_mrwitem INTO l_rec_mrwitem.* 
			LET l_idx = l_idx + 1 
			LET l_arr_rec_mrwitem[l_idx].item_id = l_rec_mrwitem.item_id 
			LET l_arr_rec_mrwitem[l_idx].item_desc = l_rec_mrwitem.item_desc 
			--         IF l_idx = 100 THEN
			--            LET l_msgresp = kandoomsg("U",6100,l_idx)
			--            EXIT FOREACH
			--         END IF
		END FOREACH 
		LET l_msgresp=kandoomsg("U",9113,l_idx) 

		#U9113 l_idx records selected
		IF l_idx = 0 THEN 
			LET l_idx = 1 
			INITIALIZE l_arr_rec_mrwitem[1].* TO NULL 
		END IF 
		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

		LET l_msgresp = kandoomsg("U",1019,"") 
		#1006 " Press ESC on line TO SELECT"
		--      CALL set_count(l_idx)
		INPUT ARRAY l_arr_rec_mrwitem WITHOUT DEFAULTS FROM sr_mrwitem.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","gitemshow","input-arr-mrwitem") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				--            LET scrn = scr_line()
				--            IF l_arr_rec_mrwitem[l_idx].item_id IS NOT NULL THEN
				--               DISPLAY l_arr_rec_mrwitem[l_idx].* TO sr_mrwitem[scrn].*
				--
				--            END IF
				NEXT FIELD scroll_flag 

			AFTER FIELD scroll_flag 
				LET l_arr_rec_mrwitem[l_idx].scroll_flag = NULL 
				IF fgl_lastkey() = fgl_keyval("down") 
				AND arr_curr() >= arr_count() THEN 
					LET l_msgresp = kandoomsg("U",9001,"") 
					NEXT FIELD scroll_flag 
				END IF 

			BEFORE FIELD item_id 
				LET l_rec_mrwitem.item_id = l_arr_rec_mrwitem[l_idx].item_id 
				EXIT INPUT 
				--         AFTER ROW
				--            DISPLAY l_arr_rec_mrwitem[l_idx].* TO sr_mrwitem[scrn].*

			AFTER INPUT 
				LET l_rec_mrwitem.item_id = l_arr_rec_mrwitem[l_idx].item_id 

		END INPUT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 

	CLOSE WINDOW g502 

	RETURN l_rec_mrwitem.item_id 
END FUNCTION 
