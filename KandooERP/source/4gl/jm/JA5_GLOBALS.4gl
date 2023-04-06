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

	Source code beautified by beautify.pl on 2020-01-02 19:48:17	$Id: $
}


#GLOBALS "../common/glob_GLOBALS.4gl"

{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module - JA1glob (Ja5g !!!) - Contract add
# Purpose - Global variables used in JA1 & JA2
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS 

	DEFINE 
	pr_company RECORD LIKE company.*, 
	pr_contracthead RECORD LIKE contracthead.*, 
	pr_contractdetl RECORD LIKE contractdetl.*, 
	pr_contractdate RECORD LIKE contractdate.*, 
	pr_product RECORD LIKE product.*, 
	pr_customership RECORD LIKE customership.*, 
	pr_customer RECORD LIKE customer.*, 
	pr_job RECORD LIKE job.*, 
	pr_jobvars RECORD LIKE jobvars.*, 
	pr_activity RECORD LIKE activity.*, 
	pr_rec_kandoouser RECORD LIKE kandoouser.*, 
	pr_lines RECORD 
		line1_text CHAR(132), 
		line2_text CHAR(132), 
		line3_text CHAR(132), 
		line4_text CHAR(132), 
		line5_text CHAR(132), 
		line6_text CHAR(132), 
		line7_text CHAR(132), 
		line8_text CHAR(132), 
		line9_text CHAR(132), 
		line10_text CHAR(132) 
	END RECORD, 

	query_text CHAR(1200), 
	where_part CHAR(1200), 
	formname CHAR(15), 
	rpt_pageno LIKE rmsreps.page_num, 
	pv_temp CHAR(1), 
	pr_output CHAR(60), 
	pv_date_flag SMALLINT, 
	pv_first_flag SMALLINT 

END GLOBALS 
