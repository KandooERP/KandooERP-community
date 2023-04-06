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
}
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

GLOBALS 

	DEFINE 
	formname CHAR(15), 
	rpt_pageno SMALLINT, 
	rpt_length SMALLINT, 
	rpt_note CHAR(80), 
	rpt_wid SMALLINT, 
	pv_mps_plan LIKE mps.plan_code, 
	pv_mrp_plan LIKE mrp.plan_code, 
	pv_mrp_desc LIKE mrp.desc_text, 
	pv_scrap_ind CHAR(1), 
	pv_background SMALLINT, 
	pv_found_error SMALLINT, 
	pv_errormsg CHAR(100), 
	pv_non_part_desc LIKE shoporddetl.desc_text, 
	pv_mps_desc LIKE mps.desc_text, 
	pv_end_date DATE, 
	pv_tot_sel SMALLINT, 
	pv_tot_left SMALLINT, 

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

	pr_lines1 RECORD 
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


	pr_kandooreport1 RECORD LIKE kandooreport.* 

END GLOBALS 

