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
	Source code beautified by beautify.pl on 2020-01-03 13:41:22	$Id: $
}
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_P2_GLOBALS.4gl" 
############################################################
# Module Scope Variables
############################################################

############################################################
# MAIN
#
# \file
# \brief module P2E  Outstatnding Voucher Scan  & Inquiry
############################################################
MAIN 

	#Initial UI Init
	CALL setModuleId("P2E") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	OPEN WINDOW p213 with FORM "P213" 
	CALL winDecoration_p("P213") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	WHILE get_vendor() 
		CALL vinq_vouc(glob_rec_kandoouser.cmpy_code,glob_rec_vendor.vend_code) 
	END WHILE 

	CLOSE WINDOW p213 

END MAIN 


############################################################
# FUNCTION get_vendor()
#
#
############################################################
FUNCTION get_vendor() 
	DEFINE l_msgresp LIKE language.yes_flag 

	CLEAR FORM 
	LET l_msgresp=kandoomsg("P",1016,"") 

	#1016 Enter Vendor Code FOR Voucher Selection
	INPUT BY NAME glob_rec_vendor.vend_code WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P2E","inp-vend_code-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (vend_code) 
			LET glob_rec_vendor.vend_code = show_vend(glob_rec_kandoouser.cmpy_code,glob_rec_vendor.vend_code) 
			NEXT FIELD vend_code 

		AFTER FIELD vend_code 
			SELECT * INTO glob_rec_vendor.* FROM vendor 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = glob_rec_vendor.vend_code 
			IF status = NOTFOUND THEN 
				LET l_msgresp=kandoomsg("P",9105,"") 
				#9105 Vendor NOT found - Try Window"
				NEXT FIELD vend_code 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN FALSE 
	ELSE 
		RETURN TRUE 
	END IF 

END FUNCTION 


