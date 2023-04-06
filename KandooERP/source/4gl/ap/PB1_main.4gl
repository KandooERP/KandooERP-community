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
GLOBALS "../ap/P_AP_GLOBALS.4gl"
GLOBALS "../ap/PB_GROUP_GLOBALS.4gl" 

############################################################
# Module Scope Variables
############################################################
DEFINE glob_glparms RECORD LIKE glparms.* 
DEFINE modu_tot_amt DECIMAL(16,2)
DEFINE modu_tot_disc DECIMAL(16,2)
DEFINE modu_tot_paid DECIMAL(16,2)
############################################################
# MAIN
#
# PB1 Voucher Listing By Vendor
############################################################
MAIN 
	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("PB1") 	#Initial UI Init 
	CALL ui_init(0) 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 
	
	CALL PB1_main()
	
END MAIN