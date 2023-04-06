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
#  get_print(x,y) - This FUNCTION will RETURN the default printer
#                   WHEN int_flag OR quit_flag IS pressed.
#  get_print2(x,y) - This FUNCTION will RETURN NULL
#                    WHEN int_flag OR quit_flag IS pressed.
###########################################################################

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl"  

GLOBALS 
	DEFINE glob_rec_temp 
		RECORD 
		   dest LIKE printcodes.print_code 
		END RECORD 
	DEFINE global_rec_printcodes RECORD LIKE printcodes.* 
	DEFINE global_destination LIKE printcodes.print_code 
END GLOBALS 


###################################################################################
# FUNCTION get_print(p_cmpy, p_default)
#
#
###################################################################################
FUNCTION get_print(p_cmpy,p_default) 
	DEFINE p_cmpy LIKE company.cmpy_code
	DEFINE p_default LIKE printcodes.print_code 
	DEFINE l_msgresp LIKE language.yes_flag 
 
	LET int_flag = false 
	LET quit_flag = false 
	LET glob_rec_temp.dest = p_default 

	OPEN WINDOW U500 with FORM "U500" 
	CALL windecoration_u("U500") 

	INPUT BY NAME glob_rec_temp.* WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","prinwind","input-temp-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (dest) 
			LET glob_rec_temp.dest = show_print(p_cmpy) 
			NEXT FIELD dest 

		AFTER FIELD dest 
			SELECT * INTO global_rec_printcodes.* FROM printcodes 
			WHERE print_code = glob_rec_temp.dest 
			IF status = (notfound) THEN 
				LET glob_rec_temp.dest = NULL 
				LET l_msgresp = kandoomsg("U",9105,"") 
				NEXT FIELD dest 
			END IF 



	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET glob_rec_temp.dest = p_default 
	END IF 
	LET global_destination = glob_rec_temp.dest 

	CLOSE WINDOW U500 

	RETURN global_destination 
END FUNCTION 
###################################################################################
# END FUNCTION get_print(p_cmpy, p_default)
###################################################################################


###################################################################################
# FUNCTION get_print2(p_cmpy, p_default)
#
#
###################################################################################
FUNCTION get_print2(p_cmpy,p_default) 
	DEFINE p_cmpy LIKE company.cmpy_code
	DEFINE p_default LIKE printcodes.print_code 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET int_flag = false 
	LET quit_flag = false 
	LET glob_rec_temp.dest = p_default 

	OPEN WINDOW u500 with FORM "U500" 
	CALL windecoration_u("U500") 

	INPUT BY NAME glob_rec_temp.* WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","prinwind","input-temp-2") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (dest) 
			LET glob_rec_temp.dest = show_print(p_cmpy) 
			NEXT FIELD dest 

		AFTER FIELD dest 
			SELECT * INTO global_rec_printcodes.* FROM printcodes 
			WHERE print_code = glob_rec_temp.dest 
			IF status = (notfound) THEN 
				LET glob_rec_temp.dest = NULL 
				LET l_msgresp = kandoomsg("U",9105,"") 
				NEXT FIELD dest 
			END IF 


	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET glob_rec_temp.dest = NULL 
	END IF 
	LET global_destination = glob_rec_temp.dest 

	CLOSE WINDOW U500 

	RETURN global_destination 
END FUNCTION 
###################################################################################
# END FUNCTION get_print2(p_cmpy, p_default)
###################################################################################