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
# MAIN
#
# module GC1  allows the user TO create Journal Batches in cash booh
###########################################################################
MAIN 

	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("GC1") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 

	CALL GC1_main()
END MAIN 
###########################################################################
# END MAIN
###########################################################################