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

	Source code beautified by beautify.pl on 2020-01-02 10:35:41	$Id: $
}



#      wadchwin.4gl - show_addcharge
#                     window FUNCTION FOR finding addcharge records
#                     returns desc_code
#
#       p_auto_ind - VALUES 0 = Don't Show Automatic Recalculated Charges
#                     VALUES 1 = Show Only Automatic Recalculcated Charges
#                     VALUES 2 = Show All Charges
#                     VALUES 3 = Show All Automatic Charges

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

############################################################
# FUNCTION show_addcharge(p_cmpy_code,p_auto_ind)
#
#
############################################################
FUNCTION show_addcharge(p_cmpy_code,p_auto_ind) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_auto_ind CHAR(1) 
	DEFINE l_rec_addcharge RECORD LIKE addcharge.* 
	DEFINE l_arr_rec_addcharge DYNAMIC ARRAY OF #array[100] OF RECORD 
		RECORD 
			scroll_flag CHAR(1), 
			desc_code LIKE addcharge.desc_code, 
			process_ind LIKE addcharge.process_ind, 
			rev_acct_code LIKE addcharge.rev_acct_code 
		END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE l_msgresp LIKE language.yes_flag 

		OPTIONS INSERT KEY f36, 
		DELETE KEY f36 

		OPEN WINDOW w207 with FORM "W207" 
		CALL winDecoration_w("W207") -- albo kd-752 



		WHILE TRUE 
			CLEAR FORM 
			LET l_msgresp = kandoomsg("U",1001,"") 
			#1001 " Enter Selection Criteria - ESC TO Continue"

			CONSTRUCT BY NAME l_where_text ON desc_code, 
			process_ind, 
			rev_acct_code 
				BEFORE CONSTRUCT 
					CALL publish_toolbar("kandoo","wadchwin","construct-addcharge") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

			END CONSTRUCT 


			IF int_flag OR quit_flag THEN 
				LET int_flag = FALSE 
				LET quit_flag = FALSE 
				LET l_rec_addcharge.desc_code = NULL 
				EXIT WHILE 
			END IF 

			LET l_msgresp = kandoomsg("U",1002,"") 
			#1002 " Searching database - please wait"
			LET l_query_text = "SELECT * FROM addcharge ", 
			"WHERE cmpy_code = '",p_cmpy_code,"' ", 
			"AND ",l_where_text clipped 
			CASE p_auto_ind 
				WHEN "0" 
					LET l_query_text = l_query_text clipped, 
					" AND process_ind != 1 " 
				WHEN "1" 
					LET l_query_text = l_query_text clipped, 
					" AND process_ind = 1 " 
				WHEN "3" 
					LET l_query_text = l_query_text clipped, 
					" AND process_ind in (1,2) " 
			END CASE 
			LET l_query_text = l_query_text clipped, 
			" ORDER BY desc_code" 

			WHENEVER ERROR CONTINUE 
			OPTIONS SQL interrupt ON 
			PREPARE s_addcharge FROM l_query_text 
			DECLARE c_addcharge CURSOR FOR s_addcharge 

			LET l_idx = 0 
			FOREACH c_addcharge INTO l_rec_addcharge.* 
				LET l_idx = l_idx + 1 
				LET l_arr_rec_addcharge[l_idx].desc_code = l_rec_addcharge.desc_code 
				LET l_arr_rec_addcharge[l_idx].process_ind = l_rec_addcharge.process_ind 
				LET l_arr_rec_addcharge[l_idx].rev_acct_code = l_rec_addcharge.rev_acct_code 
				IF l_idx = 100 THEN 
					LET l_msgresp = kandoomsg("U",6100,l_idx) 
					EXIT FOREACH 
				END IF 
			END FOREACH 
			LET l_msgresp=kandoomsg("U",9113,l_idx) 
			#U9113 l_idx records selected
			IF l_idx = 0 THEN 
				LET l_idx = 1 
				INITIALIZE l_arr_rec_addcharge[1].* TO NULL 
			END IF 

			WHENEVER ERROR stop 
			WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 

			LET l_msgresp = kandoomsg("U",1006,"") 
			#1006 " ESC on line TO SELECT - F10 TO Add"
			CALL set_count(l_idx) 

			INPUT ARRAY l_arr_rec_addcharge WITHOUT DEFAULTS FROM sr_addcharge.* 
				BEFORE INPUT 
					CALL publish_toolbar("kandoo","wadchwin","input-arr-addcharge") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				BEFORE ROW 
					LET l_idx = arr_curr() 
					IF l_idx > 0 THEN 
						LET l_rec_addcharge.desc_code = l_arr_rec_addcharge[l_idx].desc_code 
					END IF 
					#            LET scrn = scr_line()
					#            IF l_arr_rec_addcharge[l_idx].desc_code IS NOT NULL THEN
					#               DISPLAY l_arr_rec_addcharge[l_idx].* TO sr_addcharge[scrn].*
					#
					#            END IF
					NEXT FIELD scroll_flag 

				ON KEY (F10) 
					CALL run_prog("WZD","","","","") 
					NEXT FIELD scroll_flag 

				AFTER FIELD scroll_flag 
					LET l_arr_rec_addcharge[l_idx].scroll_flag = NULL 
					IF fgl_lastkey() = fgl_keyval("down") 
					AND arr_curr() >= arr_count() THEN 
						LET l_msgresp = kandoomsg("U",9001,"") 
						NEXT FIELD scroll_flag 
					END IF 

				BEFORE FIELD desc_code 
					LET l_rec_addcharge.desc_code = l_arr_rec_addcharge[l_idx].desc_code 
					EXIT INPUT 

					#			AFTER ROW
					#            DISPLAY l_arr_rec_addcharge[l_idx].* TO sr_addcharge[scrn].*
					#
					#			AFTER INPUT
					#            LET l_rec_addcharge.desc_code = l_arr_rec_addcharge[l_idx].desc_code

			END INPUT 

			IF int_flag OR quit_flag THEN 
				LET int_flag = FALSE 
				LET quit_flag = FALSE 
			ELSE 
				EXIT WHILE 
			END IF 
		END WHILE 

		OPTIONS INSERT KEY f1, 
		DELETE KEY f2 
		CLOSE WINDOW w207 

		RETURN l_rec_addcharge.desc_code 
END FUNCTION 
