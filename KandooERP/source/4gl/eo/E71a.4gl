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
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../eo/E_EO_GLOBALS.4gl"
GLOBALS "../eo/E7_GROUP_GLOBALS.4gl"
GLOBALS "../eo/E71_GLOBALS.4gl"
###########################################################################
# E71a - Maintainence program FOR Sales Conditions
###########################################################################
################################################################################
# FUNCTION edit_header(p_mode)
#
#
################################################################################
FUNCTION edit_header(p_mode) 
	DEFINE p_mode char(4) 

	MESSAGE kandoomsg2("E",1011,"") #1011 Edit Special Condition Details - ESC TO Continue"
	INPUT BY NAME 
		glob_rec_condsale.cond_code, 
		glob_rec_condsale.desc_text, 
		glob_rec_condsale.scheme_amt WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","E71a","inp-arr-glob_rec_condsale") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE FIELD cond_code 
			IF p_mode = "EDIT" THEN 
				NEXT FIELD desc_text 
			END IF 

		AFTER FIELD cond_code 
			IF glob_rec_condsale.cond_code IS NULL THEN 
				ERROR kandoomsg2("E",9000,"") 
				NEXT FIELD cond_code 
			ELSE 
				SELECT unique 1 FROM condsale 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cond_code = glob_rec_condsale.cond_code 
				IF sqlca.sqlcode = 0 THEN 
					ERROR kandoomsg2("E",6011,"") 				#6011 Warning: Sales Condition Number already exists "
				END IF 
			END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF p_mode = "ADD" THEN 
					SELECT unique 1 FROM condsale 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cond_code = glob_rec_condsale.cond_code 
					IF sqlca.sqlcode = 0 THEN 
						ERROR kandoomsg2("E",9037,"") 					#9037" Sales Condition Number already exists - Try Another"
						NEXT FIELD cond_code 
					END IF 
				END IF 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET quit_flag = FALSE 
		LET int_flag = FALSE 
		RETURN FALSE 
	ELSE 
		RETURN TRUE 
	END IF 

END FUNCTION
################################################################################
# END FUNCTION edit_header(p_mode)
################################################################################ 