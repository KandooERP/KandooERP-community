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
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/AA_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/AAT_J_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 

############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_rec_credithead RECORD LIKE credithead.* 
DEFINE modu_rec_cashreceipt RECORD LIKE cashreceipt.* 
DEFINE modu_rec_invoicepay RECORD LIKE invoicepay.* 
DEFINE modu_rec_doc RECORD 
	d_cust CHAR(8), 
	d_type_code CHAR(3), 
	d_date DATE, 
	d_ref INTEGER, 
	d_type CHAR(2), 
	d_age INTEGER, 
	d_bal money(12,2) 
END RECORD 
DEFINE modu_query_text CHAR(1000) 
DEFINE modu_where_text CHAR(1000) 
DEFINE modu_report_level CHAR(1) 
DEFINE modu_report_invoices CHAR(1)
DEFINE modu_tot_over1 DECIMAL(16,2) 
DEFINE modu_tot_over30 DECIMAL(16,2) 
DEFINE modu_tot_over60 DECIMAL(16,2) 
DEFINE modu_tot_over90 DECIMAL(16,2) 
DEFINE modu_tot_curr DECIMAL(16,2) 
DEFINE modu_tot_bal DECIMAL(16,2) 
DEFINE modu_tot_cust INTEGER 
DEFINE modu_age_date DATE 

#####################################################################
# MAIN
#
# Summary Aging Version that allows entry of aging Date AND
#           unpicks transactions closed AFTER cutoff date
# Only works with invoices that have either manifest_num NULL OR <> -1
# OR manifest_num = -1 depending on selection
#####################################################################
MAIN 
	DEFER interrupt 
	DEFER quit 
	
	CALL setModuleId("AAT") 
	CALL ui_init(0) #Initial UI Init 

	CALL authenticate(getmoduleid()) 
	CALL init_a_ar() #init a/ar module 

	SELECT * INTO glob_rec_company.* FROM company 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code

	CALL AAT_J_main()	
END MAIN