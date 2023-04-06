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
GLOBALS "../utility/U_UT_GLOBALS.4gl" 
GLOBALS "../utility/U11_GLOBALS.4gl"  

#To test p4gl FOR ignoring of MAIN FUNCTION REPORT blocks in included file:
#GLOBALS '../utility/U12.4gl'


 
############################################################
# MODULE Scope Variables
############################################################
#FOR Doc4GL testing: - works, but does NOT RECORD variable type?
--DEFINE test_module_var SMALLINT 

#######################################################################
# MAIN
#
#
#######################################################################
MAIN 
	DEFER QUIT 
	DEFER INTERRUPT 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 

	CALL setModuleId("U11") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_u_ut() #init utility module 

	CALL U11_main()
END MAIN	