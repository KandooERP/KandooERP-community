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

	Source code beautified by beautify.pl on 2020-01-02 10:35:13	$Id: $
}

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

############################################################
# FUNCTION show_operator(p_operator)
#
#     goptshow.4gl - show_operator
#                    window FUNCTION FOR finding mrwparms records
#                    returns operator
############################################################
FUNCTION show_operator(p_operator) 
	DEFINE p_operator CHAR(1) 
	DEFINE l_arr_rec_operator array[5] OF RECORD 
		scroll_flag CHAR(1), 
		operator CHAR(1), 
		op_desc CHAR(32) 
	END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	OPEN WINDOW g503 with FORM "G503" 
	CALL windecoration_g("G503") 

	WHILE true 
		CLEAR FORM 
		SELECT add_op, "Addition", 
		sub_op, "Substraction", 
		mult_op, "Multiplication", 
		div_op, "Division", 
		thru_op, "Through" 
		INTO l_arr_rec_operator[1].operator, l_arr_rec_operator[1].op_desc, 
		l_arr_rec_operator[2].operator, l_arr_rec_operator[2].op_desc, 
		l_arr_rec_operator[3].operator, l_arr_rec_operator[3].op_desc, 
		l_arr_rec_operator[4].operator, l_arr_rec_operator[4].op_desc, 
		l_arr_rec_operator[5].operator, l_arr_rec_operator[5].op_desc 
		FROM mrwparms 
		LET l_idx = 5 
		LET l_msgresp=kandoomsg("U",9113,l_idx) 
		#U9113 l_idx records selected
		LET l_msgresp = kandoomsg("U",1019,"") 

		#1006 " Press ESC on line TO SELECT"
		CALL set_count(l_idx) #max 5 
		INPUT ARRAY l_arr_rec_operator WITHOUT DEFAULTS FROM sr_operator.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","goptshow","input-arr-operator") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 


			BEFORE ROW 
				LET l_idx = arr_curr() 
				--            LET scrn = scr_line()
				--            IF l_arr_rec_operator[l_idx].operator IS NOT NULL THEN
				--               DISPLAY l_arr_rec_operator[l_idx].* TO sr_operator[scrn].*
				--
				--            END IF
				NEXT FIELD scroll_flag 

			AFTER FIELD scroll_flag 
				LET l_arr_rec_operator[l_idx].scroll_flag = NULL 
				IF fgl_lastkey() = fgl_keyval("down") 
				AND arr_curr() >= arr_count() THEN 
					LET l_msgresp = kandoomsg("U",9001,"") 
					NEXT FIELD scroll_flag 
				END IF 

			BEFORE FIELD operator 
				LET p_operator = l_arr_rec_operator[l_idx].operator 
				EXIT INPUT 

				--         AFTER ROW
				--            DISPLAY l_arr_rec_operator[l_idx].* TO sr_operator[scrn].*

			AFTER INPUT 
				LET p_operator = l_arr_rec_operator[l_idx].operator 

		END INPUT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET p_operator = NULL 
			EXIT WHILE 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 

	CLOSE WINDOW g503 

	RETURN p_operator 
END FUNCTION 
