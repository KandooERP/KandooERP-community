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
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"

###########################################################################
# FUNCTION db_bank_filter_datasource(p_filter)
#
#
###########################################################################
FUNCTION db_bank_filter_datasource(p_filter) 
	DEFINE p_filter boolean 
	DEFINE l_rec_bank RECORD LIKE bank.* 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE l_idx SMALLINT 
	DEFINE r_arr_rec_bank DYNAMIC ARRAY OF t_rec_bank_bc_na_ac 

	IF p_filter THEN 
		CLEAR FORM 
		MESSAGE kandoomsg2("U",1001,"")		#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON 
			bank_code, 
			name_acct_text, 
			acct_code 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","bankwind","construct-bank") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_bank.bank_code = NULL 
			LET l_where_text = " 1=1" 
		END IF 

	ELSE 
		LET l_where_text = " 1=1" 
	END IF 

	MESSAGE kandoomsg2("U",1002,"") #1002 " Searching database - please wait"
	LET l_query_text = 
		"SELECT * FROM bank ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY bank_code" 

--	WHENEVER ERROR CONTINUE 
--	OPTIONS SQL interrupt ON 

	PREPARE s_bank FROM l_query_text 
	DECLARE c_bank CURSOR FOR s_bank 

	LET l_idx = 0 
	FOREACH c_bank INTO l_rec_bank.* 
		LET l_idx = l_idx + 1 
		LET r_arr_rec_bank[l_idx].bank_code = l_rec_bank.bank_code 
		LET r_arr_rec_bank[l_idx].name_acct_text = l_rec_bank.name_acct_text 
		LET r_arr_rec_bank[l_idx].acct_code = l_rec_bank.acct_code 

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF			

	END FOREACH 
	
	MESSAGE kandoomsg2("U",9113,l_idx)#U9113 l_idx records selected

	RETURN r_arr_rec_bank 
END FUNCTION 
############################################################
# END FUNCTION db_bank_filter_datasource(p_filter)
############################################################


#######################################################################
# FUNCTION show_bank(p_cmpy)
#
#       bankwind.4gl - show_bank
#                      window FUNCTION FOR finding bank records
#                      returns bank_code
#######################################################################
FUNCTION show_bank(p_cmpy) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE l_arr_rec_bank DYNAMIC ARRAY OF t_rec_bank_bc_na_ac 
	#	#array[100] OF
	#		RECORD
	#			bank_code LIKE bank.bank_code,
	#			name_acct_text LIKE bank.name_acct_text,
	#			acct_code LIKE bank.acct_code
	#		END RECORD
	DEFINE l_idx SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE r_rec_bank RECORD LIKE bank.* 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	OPEN WINDOW g135 with FORM "G135" 
	CALL winDecoration_g("G135") 

	#   WHILE TRUE

	---------------------------------
	IF db_bank_get_count() > 1000 THEN 
		CALL db_bank_filter_datasource(true) RETURNING l_arr_rec_bank 
	ELSE 
		CALL db_bank_filter_datasource(false) RETURNING l_arr_rec_bank 
	END IF 

	------------------------------------

	IF l_arr_rec_bank.getlength() = 0 THEN 
		LET l_idx = 1 
		INITIALIZE l_arr_rec_bank[1].* TO NULL 
	END IF 
	
--	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
--	OPTIONS SQL interrupt off 

	MESSAGE kandoomsg2("U",1006,"") #1006 " ESC on line TO SELECT - F10 TO Add"
	DISPLAY ARRAY l_arr_rec_bank TO sr_bank.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","bankwind","input-arr-bank") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			LET r_rec_bank.bank_code = l_arr_rec_bank[l_idx].bank_code 
			#LET scrn = scr_line()
			#IF l_arr_rec_bank[l_idx].bank_code IS NOT NULL THEN
			#   DISPLAY l_arr_rec_bank[l_idx].* TO sr_bank[scrn].*
			#
			#END IF
			#            NEXT FIELD bank_code

		ON KEY (F10) #datamanagers (external programs) 
			CALL run_prog("GZ6","","","","") 
			#refresh my program data array with a possibly newly created bank acccount
			CALL db_bank_filter_datasource(false) RETURNING l_arr_rec_bank 
			#refresh my comboBoxList with the new bank account
			CALL comboList_bank("bank_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			#            NEXT FIELD bank_code

			#         AFTER FIELD bank_code
			#            IF  fgl_lastkey() = fgl_keyval("down")
			#            AND arr_curr() >= arr_count() THEN
			#               LET l_msgresp = kandoomsg("U",9001,"")
			#               NEXT FIELD bank_code
			#            END IF

			#         BEFORE FIELD name_acct_text
			#            LET r_rec_bank.bank_code = l_arr_rec_bank[l_idx].bank_code
			#            EXIT INPUT
			#AFTER ROW
			#   DISPLAY l_arr_rec_bank[l_idx].* TO sr_bank[scrn].*

			#AFTER INPUT
			#   LET r_rec_bank.bank_code = l_arr_rec_bank[l_idx].bank_code

	END DISPLAY 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 

	CLOSE WINDOW G135 

	RETURN r_rec_bank.bank_code, r_rec_bank.acct_code 
END FUNCTION 
#######################################################################
# END FUNCTION show_bank(p_cmpy)
#######################################################################