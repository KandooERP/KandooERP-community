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

	Source code beautified by beautify.pl on 2020-01-03 14:28:57	$Id: $
}



#   This module contains the functions allowing a user TO
#   query by example FOR rows of the rpthead & rptcol table
#
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS "../gl/GW3_GLOBALS.4gl" 

############################################################
# FUNCTION col_qry()
#
# Description         :   This FUNCTION constructs a query based on the
#                         VALUES entered by the user, AND IF the QBE IS
#                         NOT interrupted, calls a CURSOR handling
#                         routine
# Impact GLOBALS      :   glob_query_1
# perform screens     :   rpt_maint
############################################################
FUNCTION col_qry() 
	DEFINE l_rowid INTEGER 
	DEFINE l_s1 CHAR(600) 

	CLEAR FORM 
	CONSTRUCT glob_query_1 
	ON rpthead.rpt_id, 
	rpthead.rpt_text, 
	rptcol.col_id, 
	rptcoldesc.col_desc, 
	rptcol.width, 
	rptcol.amt_picture, 
	colitem.col_item 
	FROM rpthead.rpt_id, 
	rpthead.rpt_text, 
	rptcol.col_id, 
	rptcoldesc[1].col_desc, 
	rptcol.width, 
	rptcol.amt_picture, 
	colitem[1].col_item 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 
		CALL col_curs() 
	END IF #int_flag OR quit_flag THEN 

END FUNCTION #col_qry() 
