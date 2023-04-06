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

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"
GLOBALS "../gl/G_GL_GLOBALS.4gl" 

############################################################
# MAIN
#
# BIC (was BSB) Bank Code Management
#   GZU - Bank bics
############################################################
MAIN 
	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("GZU") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 

	OPEN WINDOW G534 with FORM "G534" 
	CALL windecoration_g("G534") 

	CALL scan_bic() 

	CLOSE WINDOW G534 

END MAIN 
############################################################
# END MAIN
############################################################


############################################################
# FUNCTION select_bic()
#
#
############################################################
FUNCTION select_bic() 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 

	CLEAR FORM #clear FORM ? 
	MESSAGE kandoomsg2("G",1001,"")	#1001 " Enter Selection Criteria - ESC TO Continue"
	CONSTRUCT BY NAME l_where_text ON 
		bic_code, 
		desc_text, 
		post_code, 
		bank_ref 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","GZU","bankDescriptionQuery") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL 
	ELSE 
		LET l_query_text = 
			"SELECT * FROM bic ", 
			"WHERE ", l_where_text clipped," ", 
			"ORDER BY bic.bic_code" 
		RETURN l_query_text 
	END IF 
END FUNCTION 
############################################################
# END FUNCTION select_bic()
############################################################


############################################################
# FUNCTION scan_bic()
#
#
############################################################
FUNCTION scan_bic() 
	DEFINE l_rec_bic RECORD LIKE bic.* 
	DEFINE l_mode SMALLINT 
	DEFINE hack_l_rec_bic RECORD LIKE bic.* 
	DEFINE l_arr_rec_bic DYNAMIC ARRAY OF t_rec_vic_bc_dt_pc_br 
	DEFINE l_arr_rec_bic_backup DYNAMIC ARRAY OF t_rec_vic_bc_dt_pc_br 
	DEFINE l_arr_rec_bic_pk_changed DYNAMIC ARRAY OF t_rec_vic_bc_dt_pc_br 

	#	DEFINE l_arr_rec_bic, l_arr_rec_bic_backup, l_arr_rec_bic_pk_changed DYNAMIC ARRAY OF
	#		RECORD
	#			bic_code LIKE bic.bic_code,
	#			desc_text LIKE bic.desc_text,
	#			post_code LIKE bic.post_code,
	#			bank_ref LIKE bic.bank_ref
	#		END RECORD
	DEFINE l_data_modified boolean 
	DEFINE sql_where_query VARCHAR(500) 
	DEFINE l_idx SMALLINT #removed scrn huho 
	DEFINE l_del_cnt SMALLINT 
	DEFINE l_i SMALLINT 
	DEFINE msgstr STRING 
	DEFINE l_msgresp LIKE language.yes_flag 


	CALL db_bic_get_arr_rec(filter_query_off,null) RETURNING l_arr_rec_bic 
	LET l_arr_rec_bic_backup = l_arr_rec_bic 
	IF l_arr_rec_bic.getlength() = 0 THEN 
		LET l_msgresp = kandoomsg("G",9167,"") 
		#9167" No Bank/State/Branchs satisfied selection criteria "
	END IF 



	#LET l_msgresp = kandoomsg("G",1003,"")
	#" F1 TO Add - F2 TO Delete - RETURN on line TO Edit "

	INPUT ARRAY l_arr_rec_bic WITHOUT DEFAULTS FROM sr_bic.* attribute(UNBUFFERED, append ROW = false, auto append = false, INSERT ROW = true, DELETE ROW = false) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GZU","bankDescriptionList") 
			LET l_mode = MODE_UPDATE 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "Filter" 
			LET sql_where_query = select_bic() 
			IF sql_where_query IS NULL THEN 
				CALL db_bic_get_arr_rec(filter_query_off,null) RETURNING l_arr_rec_bic 
			ELSE 
				CALL db_bic_get_arr_rec(filter_query_select,sql_where_query) RETURNING l_arr_rec_bic 
			END IF 


		ON ACTION "DELETE" 
			IF db_bic_delete(UI_ON,UI_CONFIRM_ON,l_arr_rec_bic[l_idx].bic_code) < 0 THEN #error 
				#ERROR "Could not remove row "
			ELSE 
				CALL db_bic_get_arr_rec(filter_query_off,null) RETURNING l_arr_rec_bic 
				LET l_arr_rec_bic_backup[l_idx].* = l_arr_rec_bic[l_idx].* 
			END IF 



		BEFORE ROW 
			LET l_idx = arr_curr() 
			#hack huho
			IF l_idx < 1 THEN 
				LET l_idx = 1 
			END IF 

			LET l_rec_bic.* = l_arr_rec_bic[l_idx].* 

		AFTER ROW ##check, IF user has changed data OR added a ROW 
			IF (l_rec_bic.bic_code <> l_arr_rec_bic[l_idx].bic_code) 
			OR (l_rec_bic.desc_text <> l_arr_rec_bic[l_idx].desc_text) 
			OR (l_rec_bic.post_code <> l_arr_rec_bic[l_idx].post_code) 
			OR (l_rec_bic.bank_ref <> l_arr_rec_bic[l_idx].bank_ref) 
			OR (l_rec_bic.bic_code IS null) THEN #user has changed data OR added a ROW 
				IF db_bic_update(ui_on,l_rec_bic.bic_code,l_arr_rec_bic[l_idx].*) = 0 THEN 
					LET l_data_modified = true 
					#LET l_arr_rec_bic[l_idx].* = l_rec_bic.*

					IF (l_rec_bic.bic_code <> l_arr_rec_bic[l_idx].bic_code) THEN --keep LOG ON changed pk fields FOR possible backup 
						CALL l_arr_rec_bic_pk_changed.append(l_rec_bic.*) 
					END IF 
					LET l_rec_bic.* = l_arr_rec_bic[l_idx].* 
					NEXT FIELD bic_code 
				END IF 
			END IF 
			IF NOT int_flag THEN 
				LET l_arr_rec_bic_backup[l_idx].* = l_arr_rec_bic[l_idx].* 
			END IF 

		BEFORE INSERT 
			LET l_mode = MODE_INSERT 
			INITIALIZE l_rec_bic.* TO NULL 

		AFTER INSERT 
			IF int_flag THEN 
				LET int_flag = false 
			ELSE 
				IF db_bic_insert(ui_on,l_arr_rec_bic[l_idx].*) = 0 THEN 
					LET l_data_modified = true 
				END IF 
			END IF 

			CALL db_bic_get_arr_rec(filter_query_off,null) RETURNING l_arr_rec_bic 
			LET l_mode = MODE_UPDATE 

		AFTER FIELD bic_code 
			IF l_arr_rec_bic[l_idx].bic_code IS NULL THEN #bic_code IS pk AND can never be NULL 
				LET l_msgresp = kandoomsg("G",9178,"") 
				#9178 Bank/State/Branchs must NOT be NULL
				NEXT FIELD bic_code 
			END IF 

			IF (l_rec_bic.bic_code <> l_arr_rec_bic[l_idx].bic_code) OR (l_rec_bic.bic_code IS null) THEN #user chas changed bic_code 
				IF db_bic_pk_exists(ui_pk,l_mode,l_arr_rec_bic[l_idx].bic_code) THEN #pk already exists 
					ERROR "This BIC Code already exists!" 
					NEXT FIELD bic_code 
				END IF 
			END IF 

		AFTER FIELD desc_text 
			IF l_arr_rec_bic[l_idx].desc_text IS NULL THEN 
				LET l_msgresp = kandoomsg("G",9177,"") 
				#9177 Bank/State/Branchs Description must NOT be NULL
				NEXT FIELD desc_text 
			END IF 

		AFTER INPUT 
			IF int_flag THEN 
				LET int_flag = false 
			END IF 

			#				LET HACK_l_rec_bic.*  = l_arr_rec_bic[l_idx].*
			#				IF HACK_l_rec_bic.* <> l_rec_bic.* THEN #if different, reinstate the row with the original data
			#
			#				#IF NOT l_arr_rec_bic[l_idx].* = l_rec_bic.* THEN
			#					LET l_arr_rec_bic[l_idx].* = l_rec_bic.*
			#					LET int_flag = FALSE
			#					NEXT FIELD bic_code
			#
			#				ELSE
			#
			#					IF l_data_modified THEN #some data were modified
			#
			#						LET msgStr = "You selected Cancel\nAre you sure you want to drop all your changes and recover the original data ?"
			#						IF promptTF("Drop All changes and loose work",msgStr) THEN
			#
			#							FOR l_idx = 1 TO l_arr_rec_bic_pk_changed.getLength()	#delete any rows with changed primary keys
			#								CALL db_bic_delete(UI_OFF,l_arr_rec_bic_pk_changed[l_idx].bic_code)
			#							END FOR
			#
			#							FOR l_idx = 1 TO l_arr_rec_bic_backup.getLength() #restore original data
			#								IF db_bic_pk_exists(UI_OFF,l_arr_rec_bic_backup[l_idx].bic_code) THEN
			#									IF NOT db_bic_rec_exists(UI_OFF,l_arr_rec_bic_backup[l_idx].*) THEN
			#										IF db_bic_update(UI_OFF,l_arr_rec_bic_backup[l_idx].bic_code,l_arr_rec_bic_backup[l_idx].*) < 0 THEN
			#											ERROR "Could not recover BIC ", trim(l_arr_rec_bic_backup[l_idx].bic_code)
			#										END IF
			#									END IF
			#								ELSE
			#									IF db_bic_insert(UI_OFF,l_arr_rec_bic_backup[l_idx].*) < 0 THEN
			#										ERROR "Could not recover BIC ", trim(l_arr_rec_bic_backup[l_idx].bic_code)
			#									END IF
			#								END IF
			#							END FOR
			#						END IF
			#						LET msgStr = "EXIT PROGRAM ?"
			#
			#						IF NOT promptTF("Exit",msgStr) THEN #Program closes normally with ACCEPT/Apply
			#							NEXT FIELD bic_code
			#						END IF
			#					END IF
			#				END IF
			#      END IF
	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 

END FUNCTION 
############################################################
# END FUNCTION scan_bic()
############################################################