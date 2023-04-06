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

	Source code beautified by beautify.pl on 2020-01-03 09:12:50	$Id: $
}





#	Main Product Group Maintenance
#
#	IZM.4gl - Maintainence Program FOR main product groups.
#
#	Important Note:
#	maingrp.min_month_amt = "Minimum Statistics Amount"
# maingrp.min_quart_amt = "Minimum Distribution Amount"
# maingrp.min_year_amt = This Column Is Not Used. SP 5/4/94
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
--GLOBALS "I_IN_GLOBALS.4gl" 

####################################################################
# MAIN
#
#
####################################################################
MAIN 
	DEFINE l_filter boolean 
	#Initial UI Init
	CALL setModuleId("IZM") 
	CALL ui_init(0) 


	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
    CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 

    CALL IZM_main()
END MAIN
