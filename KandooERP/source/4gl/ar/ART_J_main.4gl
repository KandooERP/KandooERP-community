###########################################################################
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
GLOBALS "../common/glob_GLOBALS_report.4gl" 

GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/AR_GROUP_GLOBALS.4gl"
GLOBALS "../ar/ART_J_GLOBALS.4gl"  
############################################################
# MAIN
#
# ART Summary Aging by JMJ Debt Type AND Customer Type
# Account Aging by Reference REPORT
# New faciltity TO REPORT outstanding IN/CR/CA amounts by
# customer reference (purchase_code), aged INTO current,
# over 30, over 60 AND over 90 days according TO selected date

############################################################
MAIN 
	DEFER quit 
	DEFER interrupt

	CALL setModuleId("ART_J")
	CALL ui_init(0) #Initial UI Init	
	CALL authenticate(getmoduleid()) 
	CALL init_a_ar() #init a/ar module
	 
	CALL ART_J_main()

END MAIN 