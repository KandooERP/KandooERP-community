#Ledger/Segment Translation G549

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

	Source code beautified by beautify.pl on 2020-01-03 14:29:04	$Id: $
}




# maintenance program TO translate general ledger accounts
# FROM other financial software TO the KandooERP general ledger


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS "GZM_GLOBALS.4gl" 


############################################################
# MAIN
#
#
############################################################
MAIN 

	CALL setModuleId("GZM") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 

	LET glob_account_arg = 'L' 
	LET glob_header_text = "Ledger/Segment Translation" clipped 

	OPEN WINDOW g549 with FORM "G549" 
	CALL windecoration_g("G549") 

	DISPLAY glob_header_text TO glob_header_text 
	--ATTRIBUTE(white)
	WHILE select_accounts() 
		CALL scan_accounts() 
	END WHILE 
	CLOSE WINDOW g549 
END MAIN 


