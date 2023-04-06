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

	Source code beautified by beautify.pl on 2020-01-03 18:40:35	$Id: $
}



#USE channel

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../cm/sr2_contact_GLOBALS.4gl" 
####
MAIN 
	####

	# default IS (25 ,80)
	# gui.SCREEN.size.x
	# SET the following variables in your fglprofile
	# gui.SCREEN.size.x AND gui.SCREEN.size.y

	# CALL fgl_setsize(30,100)
	# CALL fgl_setsize(30,98)

	# CALL fgl_initSUSE()

	#Initial UI Init
	CALL setModuleId("contact") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	CALL contact_main_menu("") 

END MAIN 

