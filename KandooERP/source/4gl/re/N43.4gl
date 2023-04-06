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
GLOBALS "../re/N_RE_GLOBALS.4gl"
GLOBALS "../re/N4_GROUP_GLOBALS.4gl"
GLOBALS "../re/N43_GLOBALS.4gl"  
############################################################
# Module Scope Variables
############################################################
############################################################
# MAIN
#
# \brief module N43 - Internal Requisition Purchase Order Generation
#                 SELECT purchase ORDER FOR current user only
############################################################
MAIN 
	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("N43") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_n_re() #init n/re module 

	CALL enter_approval(getmoduleid(),1) -- alch kd-494 
END MAIN 