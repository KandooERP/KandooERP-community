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
# Purpose - Global definitions FOR all modules in contract enquiry

GLOBALS 

	DEFINE 
	pr_contracthead RECORD LIKE contracthead.*, 
	pr_contractdetl RECORD LIKE contractdetl.*, 
	pr_customership RECORD LIKE customership.*, 
	pr_activity RECORD LIKE activity.*, 
	pr_jobvars RECORD LIKE jobvars.*, 
	pr_job RECORD LIKE job.*, 
	pr_product RECORD LIKE product.*, 
	pr_invoicehead RECORD LIKE invoicehead.*, 
	pa_contracthead array[500] OF RECORD 
		contract_code LIKE contracthead.contract_code, 
		cust_code LIKE contracthead.cust_code, 
		status_code LIKE contracthead.status_code, 
		desc_text LIKE contracthead.desc_text 
	END RECORD, 
	idx SMALLINT, 
	scrn SMALLINT, 
	formname CHAR(15), 
	func_type CHAR(15), 
	query_text CHAR(500), 
	where_part CHAR(500) 

END GLOBALS 
