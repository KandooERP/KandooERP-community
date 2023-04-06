##########################################################################
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
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/A4_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/A41_GLOBALS.4gl" 

################################################################
# MAIN
#
# \brief module E5C - Maintainence program FOR EO Customer credit Notes
#                This program allows the addition AND editting of
#                credit notes based on invoices that originated
#                FROM EO confirmed sales orders.
################################################################
MAIN 

	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("A41") 
	CALL ui_init(0) 	#Initial UI Init 

	CALL authenticate(getmoduleid()) 
	CALL init_a_ar() #init a/ar module 

	CALL A41_main()

END MAIN 
################################################################
# END MAIN
################################################################
