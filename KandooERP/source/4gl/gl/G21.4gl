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
# General Information
# Test with
# a) Control amount enabled/disabled (GZP)
# a1) Control amount = 0 AND enabled
# a2) Control amount > 0 AND enabled
###########################################################################
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS "../gl/G21_GLOBALS.4gl" 
GLOBALS 
	DEFINE glob_balanced_flag boolean 
END GLOBALS 


############################################################
# FUNCTION G21_main()
#
# module G21  allows the user TO create Journal Batches
############################################################
FUNCTION G21_main() 
	DEFINE l_jour_num LIKE batchhead.jour_num 
	# DEFINE l_fv_cash_book  CHAR(1) #not used ?
	DEFINE l_save boolean 
	DEFINE query_stmt STRING 

	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("G21") 

	--{ erve 2019-10-25 creating a temp table that will disappear if the sessions blows out is not the best idea, replace by creating a permanent table
	-- CALL create_table("batchdetl","t_batchdetl","","Y")
	--}
	# t_batchdetl is now a permanent table, common for all users, so we add the user login

	OPEN WINDOW G463 with FORM "G463" 
	CALL windecoration_g("G463") 

	#Query if static temp table data exists and if the user wants to use them
	IF db_t_batchdetl_get_count() > 0 THEN 
		IF NOT promptTF("Batch data found","Batch data session exist!\nDo you want to use them ?",FALSE) THEN 
			CALL db_t_batchdetl_delete_all() 
		END IF 
	END IF 

	CALL init_journal("") 

	WHILE G21_header() 
		LET l_jour_num = NULL 

		OPEN WINDOW G114 with FORM "G114" # FOR test ericv 
		CALL windecoration_g("G114") 

		WHILE batch_lines_entry() 
			MENU "Journal" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","G21","menu-journal") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON ACTION "EDIT" 
					LET quit_flag = false 
					LET int_flag = false 
					CONTINUE WHILE 
					EXIT MENU 

				ON ACTION "SAVE" #command"Save" " Save batch TO database " 
					LET l_save = true 

					IF NOT glob_balanced_flag THEN 
						LET l_save = promptTF("Journal Line items do not balance!","Are you sure you want TO save this unbalanced batch?",TRUE ) 
					END IF 

					IF l_save THEN #if user pressed save AND confirmed save FOR unbalanced batches.. save 
						LET l_jour_num = g21a_write_gl_batch(MODE_CLASSIC_ADD) 
						IF l_jour_num < 0 THEN 
							# Error in capital account funds available

							NEXT option "Exit" 

						ELSE 
							EXIT MENU 
						END IF 
					END IF 

				ON ACTION "Discard"	#command"Discard" " Discard all changes"
					LET l_jour_num = 0 
					EXIT MENU 

				ON ACTION "Exit" 	#COMMAND KEY(interrupt,"E")"Exit" " RETURN TO edit batch"
					LET quit_flag = true 
					LET int_flag = true 
					EXIT MENU 

			END MENU 

			IF int_flag OR quit_flag OR l_save THEN 
				LET int_flag = false 
				LET quit_flag = false 
				LET l_save = false 
				EXIT WHILE 
			END IF 

		END WHILE 

		CLOSE WINDOW G114 

		CASE 
			WHEN l_jour_num = 0 
				CALL init_journal("") 

			WHEN l_jour_num > 0 
				MESSAGE kandoomsg2("G",6010,l_jour_num) ## Successful addition of jour 1111
				CALL init_journal("") 
			OTHERWISE 
				EXIT CASE 
		END CASE 

	END WHILE 

	CLOSE WINDOW G463 
END FUNCTION 
############################################################
# END FUNCTION G21_main()
############################################################