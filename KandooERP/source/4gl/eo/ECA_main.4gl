#
# You should have received a copy of the GNU General Public License along
# with this program; IF NOT, write TO the Free Software Foundation, Inc.,
# 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
###########################################################################
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../eo/E_EO_GLOBALS.4gl"
GLOBALS "../eo/EC_GROUP_GLOBALS.4gl"  
GLOBALS "../eo/ECA_GLOBALS.4gl"
###########################################################################
# MAIN
#
# ECA - allows users TO SELECT a salesperson TO which peruse
#       commission information FROM statistics tables.
###########################################################################
MAIN
	DEFER QUIT 
	DEFER INTERRUPT 

	CALL setModuleId("ECA") -- albo 
	CALL ui_init(0) 	#Initial UI Init 
	CALL authenticate(getmoduleid()) 
	CALL init_e_eo() #init e/eo module

	CALL ECA_main()
END MAIN 
###########################################################################
# END MAIN
###########################################################################