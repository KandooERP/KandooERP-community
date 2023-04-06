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
# DESCRIPTION module GC1.4gl
###########################################################################

###########################################################################
# allows the user TO INPUT Cashbook deposits AND credits
# The amount IS debited TO the gl bank a/c
# It generates cbaudit records, (NOT cashreceipts).
# It also 'posts period activity' by generating the GL batch FOR the batch.
# This program uses the same database UPDATE routines AND distribution
# entry routines as regular batch entry.
###########################################################################

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl"
GLOBALS "../gl/GC_GROUP_GLOBALS.4gl" 
GLOBALS "../gl/GC1_GLOBALS.4gl"
GLOBALS "../gl/G21_GLOBALS.4gl" 

GLOBALS 
	DEFINE glob_balanced_flag boolean 
END GLOBALS 
###########################################################################
# MODULE Scope Variables
###########################################################################

###########################################################################
# FUNCTION GC1_main()
#
# module GC1  allows the user TO create Journal Batches in cash booh
###########################################################################
FUNCTION GC1_main() 
	DEFINE l_jour_num LIKE batchhead.jour_num 
	DEFINE l_prompt_text char(30) 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_save boolean 

	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("GC1") 

	SELECT * INTO glob_rec_glparms.* 
	FROM glparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_code = "1" 
	IF status = NOTFOUND THEN 
		CALL fgl_winmessage("ERROR",kandoomsg2("G",5007,""),"ERROR") 	#5008 " General Ledger Parameters Not Set Up - Refer Menu GZP"
		EXIT PROGRAM 
	END IF 

	#Query if static temp table data exists and if the user wants to use them
	IF db_t_batchdetl_get_count() > 0 THEN 
		IF NOT promptTF("Batch data found","Batch data session exist!\nDo you want to use them ?",FALSE) THEN 
			CALL db_t_batchdetl_delete_all() 
		END IF 
	END IF 

	--	CALL create_table("batchdetl","t_batchdetl","","Y") #changed to normal table
	CALL create_table("banking","t_banking","","Y") 

	OPEN WINDOW G138 with FORM "G138" 
	CALL windecoration_g("G138") 

	CALL init_journal("") 
	LET l_prompt_text = "Cash Book Deposits / credits" 

	#-------------------------------------------------------------------- BEGIN OUTER WHILE
	WHILE gc_header(TRAN_TYPE_CREDIT_CR,l_prompt_text) 
		LET l_jour_num = NULL 

		OPEN WINDOW G114 with FORM "G114" 
		CALL windecoration_g("G114") 

		#-------------------------------------------------------------------- BEGIN NESTED/INNER WHILE
		WHILE batch_lines_entry() 

			MENU " journal" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","GC1","menu-journal") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON ACTION "EDIT" 
					LET quit_flag = false 
					LET int_flag = false 
					CONTINUE WHILE 
					EXIT MENU 

				ON ACTION "Save" #command"Save" " Save batch TO database " 
					LET l_save = true 

					IF NOT glob_balanced_flag THEN 
						LET l_save = promptTF("Journal Line items do not balance!","Are you sure you want TO save this unbalanced batch?" ,TRUE) 
					END IF 

					IF l_save THEN #if user pressed save AND confirmed save FOR unbalanced batches.. save 
						LET l_jour_num = g21a_write_gl_batch(MODE_CLASSIC_ADD) 
						IF l_jour_num < 0 THEN	# Error in capital account funds available
							NEXT option "Exit" 
						ELSE 
							EXIT MENU 
						END IF 
					END IF 

				ON ACTION "Discard" 		#command"Discard" " Discard all changes"
					LET l_jour_num = 0 
					EXIT MENU 

				ON ACTION "Exit" 				#COMMAND KEY(interrupt,"E")"Exit" " RETURN TO edit batch"
					LET quit_flag = true 
					LET int_flag = true 
					EXIT MENU 

			END MENU 


			IF int_flag OR quit_flag OR l_save THEN 
				LET int_flag = false 
				LET quit_flag = false 
				LET l_save = false 
				--			ELSE
				EXIT WHILE 
			END IF 

		END WHILE 
		#-------------------------------------------------------------------- END NESTED/INNER WHILE

		CLOSE WINDOW G114 

		CASE 
			WHEN l_jour_num = 0 
				CALL init_journal("") 

			WHEN l_jour_num > 0 
				MESSAGE kandoomsg2("G",6010,l_jour_num) 	## Successful addition of jour 1111
				CALL init_journal("") 

			OTHERWISE 
				EXIT CASE 
		END CASE 

	END WHILE 
	#-------------------------------------------------------------------- END OUTER WHILE
	CLOSE WINDOW G138 
END FUNCTION 
###########################################################################
# END FUNCTION GC1_main()
###########################################################################