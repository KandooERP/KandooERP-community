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

	Source code beautified by beautify.pl on 2020-01-03 14:28:59	$Id: $
}



#  This module contains the functions allowing a user TO
#  query by example FOR rows of the rpthead table
#


{
FUNCTION            :   def_qry
Description         :   This FUNCTION constructs a query based on the
                        VALUES entered by the user, AND IF the QBE IS
                        NOT interrupted, calls a CURSOR handling
                        routine
Impact GLOBALS      :   glob_query_1
perform screens     :   rpt_maint
}
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS "../gl/GW5_GLOBALS.4gl" 


############################################################
# FUNCTION def_qry()
#
#
############################################################
FUNCTION def_qry() 
	DEFINE l_rowid INTEGER 
	DEFINE l_s1 STRING --har(600) 

	CLEAR FORM 

	#get the users query criteria
	CONSTRUCT BY NAME glob_query_1 
	ON rpthead.rpt_id, 
	rpthead.rpt_text 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","GW5e","construct-rpthead") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
	END CONSTRUCT 


	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 
		CALL def_curs() 
	END IF 


END FUNCTION #def_qry() 


