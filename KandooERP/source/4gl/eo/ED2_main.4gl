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
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../eo/E_EO_GLOBALS.4gl"
GLOBALS "../eo/ED_GROUP_GLOBALS.4gl"  
GLOBALS "../eo/ED2_GLOBALS.4gl"
###########################################################################
# MAIN
#
# ED2 - allows users TO SELECT a sales manager TO peruse
#               turnover information FROM statistics tables.
###########################################################################
MAIN 
	DEFER QUIT 
	DEFER INTERRUPT 
	
	CALL setModuleId("ED2") 
	CALL ui_init(0) #Initial UI Init 

	CALL authenticate(getmoduleid()) 
	CALL init_e_eo() #init e/eo module/program

	CALL ED2_main() 

END MAIN 
###########################################################################
#END  MAIN
###########################################################################