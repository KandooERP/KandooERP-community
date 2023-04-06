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
	Source code beautified by beautify.pl on 2020-01-02 10:35:04	$Id: $
}
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 


############################################################
# FUNCTION adjust_allocflag(p_cmpy, p_res_code, p_alloc_ind)
#
# \brief module Allocfunc - Allocation Flag adjustment program
############################################################
FUNCTION adjust_allocflag(p_cmpy, p_res_code, p_alloc_ind) 
	DEFINE p_cmpy LIKE company.cmpy_code #huho - this IS NOT used 
	DEFINE p_res_code LIKE jmresource.res_code 
	DEFINE p_alloc_ind LIKE jmresource.allocation_ind 
	DEFINE l_rec_jmresource RECORD LIKE jmresource.* 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW j196 with FORM "J196" 
	CALL winDecoration_j("J196") -- albo kd-756 

	LET l_rec_jmresource.res_code = p_res_code 
	LET l_rec_jmresource.allocation_ind = p_alloc_ind 
	DISPLAY l_rec_jmresource.res_code, 
	l_rec_jmresource.allocation_ind 
	TO res_code, 
	allocation_ind 

	LET l_msgresp = kandoomsg("U",1020,"Resource Allocation") 

	#1020 Enter Resource Allocation Details; OK TO Continue.
	INPUT BY NAME l_rec_jmresource.allocation_ind WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","allocfunc","input-allocation_resource") 


		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD allocation_ind 
			IF l_rec_jmresource.allocation_ind IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD allocation_ind 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 

	CLOSE WINDOW j196 

	RETURN l_rec_jmresource.allocation_ind 
END FUNCTION 


