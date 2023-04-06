
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
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/AC_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/ACB_GLOBALS.4gl"
GLOBALS "../common/glob_GLOBALS_report.4gl"

#####################################################################
# MAIN
#
# glob_from_batch = get_url_batch_number()
#
#  Description:   Debtors Cash Receipts Listing
#                 Provides the facility TO produce a Cash Receipts Listing
#                  FOR processing of Bank Lodgements.
#####################################################################
MAIN 
	DEFINE fv_error_log CHAR(30) 

	DEFER interrupt 
	DEFER quit 
	
	CALL setModuleId("ACB") 
	CALL ui_init(0) #Initial UI Init

	CALL authenticate(getmoduleid()) RETURNING glob_cmpy_code, glob_username 
	CALL init_a_ar() #init a/ar module 

	#original kandooo 1.0 comment
	### Set the interrupt handling - unfortunately the following statements
	### cannot be siphoned out TO an external FUNCTION as they must be called in
	### the MAIN FUNCTION.
	### Set the Lock mode TO wait 30 seconds before timing out with an
	### "Unable TO obtain Lock" MESSAGE

	SET LOCK MODE TO NOT wait 

	LET fv_error_log = trim(get_settings_logFile()) 
	CALL startlog(fv_error_log) 

--	IF get_url_batch_number() IS NULL THEN 
--		CALL get_batch_range() 
--	ELSE 
--		LET glob_from_batch = get_url_batch_number() 
--		LET glob_to_batch = glob_from_batch 
--	END IF 

	CALL ACB_main() 
END MAIN 
