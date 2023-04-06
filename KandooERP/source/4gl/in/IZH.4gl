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

	Source code beautified by beautify.pl on 2020-01-03 09:12:49	$Id: $
}


#GLOBALS "../common/glob_GLOBALS.4gl"

{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module IZH Customer Address Listing

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 

#Module Scope Variables


####################################################################
# MAIN
####################################################################
MAIN 
	DEFINE l_msgresp LIKE language.yes_flag 
	#Initial UI Init
	CALL setModuleId("IZH") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 

	OPEN WINDOW i683 with FORM "I683" 
	 CALL windecoration_i("I683") -- albo kd-758 

	CALL fgl_winmessage("Eric Job","Eric is going to re-genertate this program using autoCodeGen","info") 
	LET l_msgresp = kandoomsg("I",7071,"") 
	#7071 Bin Location Validation Option Not Set
END MAIN 
