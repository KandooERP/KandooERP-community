# Chart Translation G549


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

	Source code beautified by beautify.pl on 2020-01-03 14:29:05	$Id: $
}



# GL Chart Translation Maintenance

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS 
	DEFINE glob_header_text CHAR(26) 
	DEFINE glob_account_arg CHAR(1) 
END GLOBALS 


############################################################
# MAIN
#
#
############################################################
MAIN 
	CALL setModuleId("GZO") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 

	LET glob_account_arg = 'C' 
	LET glob_header_text = " Chart Translation" clipped 

	OPEN WINDOW g549 with FORM "G549" 
	CALL windecoration_g("G549") 

	DISPLAY glob_header_text TO header_text 

	WHILE select_accounts() 
		CALL scan_accounts() 
	END WHILE 
	CLOSE WINDOW g549 

END MAIN 
