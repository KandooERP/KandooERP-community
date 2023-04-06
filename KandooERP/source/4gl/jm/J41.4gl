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

	Source code beautified by beautify.pl on 2020-01-02 19:48:08	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 
GLOBALS 

	DEFINE pr_rec_kandoouser RECORD LIKE kandoouser.* 
	# pr_job RECORD LIKE job.*,
	DEFINE pr_user_scan_code LIKE kandoouser.acct_mask_code 
END GLOBALS 
{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module J41 - Update Activity Completion State



MAIN 
	#Initial UI Init
	CALL setModuleId("J41") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	CALL user_security(glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code) 
	RETURNING pr_rec_kandoouser.acct_mask_code, 
	pr_user_scan_code 
	OPEN WINDOW j317 with FORM "J317" -- alch kd-747 
	CALL winDecoration_j("J317") -- alch kd-747 
	WHILE select_job() 
		CALL edit_status(0) 
	END WHILE 
	CLOSE WINDOW j317 
END MAIN 
