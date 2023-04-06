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
# MODULE Description GC2.4gl
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
GLOBALS "../gl/GC2_GLOBALS.4gl"
GLOBALS "../gl/G21_GLOBALS.4gl" 
###########################################################################
# MODULE Scope Variables
###########################################################################

###########################################################################
# MAIN
#
#
###########################################################################
MAIN 
	DEFINE l_jour_num LIKE batchhead.jour_num 
	DEFINE l_prompt_text char(30) 
	DEFINE l_msgresp LIKE language.yes_flag 

	CALL setModuleId("GC2") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 

	SELECT * INTO glob_rec_glparms.* 
	FROM glparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_code = "1" 
	IF status = NOTFOUND THEN 
		LET l_msgresp=kandoomsg("G",5007,"") 
		#5008 " General Ledger Parameters Not Set Up - Refer Menu GZP"
		EXIT PROGRAM 
	END IF 
	-- commented as instructed by Eric
	--	CALL create_table("batchdetl","t_batchdetl","","Y") #changed to normal table
	CALL create_table("banking","t_banking","","Y") 

	OPEN WINDOW g138 with FORM "G138" 
	CALL windecoration_g("G138") 

	CALL init_journal("") 
	LET l_prompt_text = "Cash Book Bank charges" 

	#---------------------------------------------------------------------- BEGIN WHILE
	WHILE gc_header("DR",l_prompt_text) 
		LET l_jour_num = NULL 

		OPEN WINDOW G114 with FORM "G114" 
		CALL windecoration_g("G114") 

		#---------------------------------------------------------------------- BEGIN INNER WHILE
		WHILE batch_lines_entry() 

			MENU "Journal" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","GC2","menu-journal") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON ACTION "Save" 
					#command"Save"    " Save batch TO database "
					LET l_jour_num = g21a_write_gl_batch(MODE_CLASSIC_ADD) 
					IF l_jour_num < 0 THEN 
						# Error in capital account funds available
						NEXT option "Exit" 
					ELSE 
						EXIT MENU 
					END IF 

				ON ACTION "Discard" 
					#command"Discard" " Discard all changes"
					LET l_jour_num = 0 
					EXIT MENU 

				ON ACTION "Exit" 
					#COMMAND KEY(interrupt,"E")"Exit" " RETURN TO edit batch"
					LET quit_flag = true 
					EXIT MENU 

					#            COMMAND KEY (control-w)
					#               CALL kandoohelp("")

			END MENU 


			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
			ELSE 
				EXIT WHILE 
			END IF 
		END WHILE 
		#---------------------------------------------------------------------- END INNER WHILE

		CLOSE WINDOW G114 

		CASE 
			WHEN l_jour_num = 0 
				CALL init_journal("") 
			WHEN l_jour_num > 0 
				LET l_msgresp=kandoomsg("G",6010,l_jour_num) 
				## Successful addition of jour 1111
				CALL init_journal("") 
			OTHERWISE 
				EXIT CASE 
		END CASE 

	END WHILE 
	#---------------------------------------------------------------------- END WHILE

	CLOSE WINDOW g138 

END MAIN 
