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

	Source code beautified by beautify.pl on 2020-01-03 10:10:06	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "T_GW_GLOBALS.4gl" 


# This program does "housekeeping" on REPORT writer tables which are
# permanent, although used in a "temporary" manner.  They should be
# cleared AFTER each run, although this doesn't always happen.

#######################################################################
# MAIN
#
#
#######################################################################
MAIN 
	DEFINE fv_ans CHAR(1) 

	CALL setModuleId("GWA") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_t_gw() #init batch module 

	LET fv_ans = upshift(kandoomsg ("G", 1624, "")) 

	IF fv_ans = "Y" THEN 
		MESSAGE "Housekeeping in progress" 

		DELETE FROM rptslect 
		DELETE FROM colaccum 
		DELETE FROM rptargs 
		MESSAGE "Housekeeping complete" 

	ELSE 
		MESSAGE "Housekeeping cancelled" 

	END IF 

	CALL donePrompt("Housekeeping","Housekeeping","ACCEPT") 

END MAIN 
