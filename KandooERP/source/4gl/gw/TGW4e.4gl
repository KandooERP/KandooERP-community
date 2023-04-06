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

	Source code beautified by beautify.pl on 2020-01-03 10:10:05	$Id: $
}



############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "T_GW_GLOBALS.4gl" 
GLOBALS "TGW4_GLOBALS.4gl" 

#   This module contains the functions allowing a user TO
#   query by example FOR rows of the rptline table



{
FUNCTION            :   line_qry
Description         :   This FUNCTION constructs a query based on the
                        VALUES entered by the user, AND IF the QBE IS
                        NOT interrupted, calls a CURSOR handling
                        routine
Impact GLOBALS      :   gv_query_1
perform screens     :   rpt_maint
}

FUNCTION line_qry() 

	DEFINE 
	fv_rowid INTEGER, 
	fv_s1 CHAR(600) 

	CLEAR FORM 
	MESSAGE "" 

	CONSTRUCT gv_query_1 
	ON rptlinegrp.line_code, 
	rptlinegrp.linegrp_desc 
	FROM rptlinegrp.line_code, 
	rptlinegrp.linegrp_desc 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","TGW4e","construct-line_code-1") -- albo kd-515 

		ON ACTION "WEB-HELP" -- albo kd-378 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		ERROR "Query aborted" 
	ELSE 
		CALL line_curs() 
	END IF 

END FUNCTION 
