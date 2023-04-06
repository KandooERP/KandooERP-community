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

	Source code beautified by beautify.pl on 2020-01-03 09:12:31	$Id: $
}


#GLOBALS "../common/glob_GLOBALS.4gl"
#used as GLOBALS FROM IA1.4gl
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

# Purpose - GLobal Sourcefile FOR IA Reports

GLOBALS 
	DEFINE 
	pr_inparms RECORD LIKE inparms.*, 
	pr_rec_kandoouser RECORD LIKE kandoouser.*, 
	pr_company RECORD LIKE company.*, 
	query_text, 
	where_part CHAR(1500), 
	s, 
	len, 
	col, 
	rpt_width SMALLINT, 
	rpt_pageno SMALLINT, 
	rpt_length SMALLINT, 
	rpt_date DATE, 
	rpt_time CHAR(10), 
	rpt_note CHAR(132), 
	line1 , 
	line2, 
	line3 CHAR(132), 
	offset1, 
	offset2, 
	offset3 SMALLINT, 
	pr_output CHAR(60) 
END GLOBALS 

