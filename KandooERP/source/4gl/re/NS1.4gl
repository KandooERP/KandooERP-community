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
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../re/N_RE_GLOBALS.4gl"
GLOBALS "../re/NS_GROUP_GLOBALS.4gl"
GLOBALS "../re/NS1_GLOBALS.4gl" 
GLOBALS 
	DEFINE where_text CHAR(500) 
END GLOBALS 
############################################################
# Module Scope Variables
############################################################
############################################################
# MAIN
#
# \brief module NS1 - Purchase Order Print
#             selects which TO PRINT before calling the FUNCTION po_print
############################################################
MAIN 
	DEFINE pr_output CHAR(25) 

	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("NS1") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_n_re() #init n/re module 

	OPEN WINDOW n123 with FORM "N123" 
	CALL windecoration_n("N123") -- albo kd-763 

	WHILE select_po() 
		CALL print_po(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,where_text) 
		RETURNING pr_output 
		CALL run_prog("URS","","","","") -- ON ACTION "Print Manager" 
	END WHILE 
	CLOSE WINDOW n123 
END MAIN 


FUNCTION select_po() 
	MESSAGE " Enter Selection Criteria - ESC TO Continue " 
	attribute(yellow) 
	CONSTRUCT BY NAME where_text ON purchhead.order_num, 
	purchhead.vend_code, 
	purchhead.ware_code, 
	purchhead.order_date, 
	purchhead.order_text, 
	purchhead.enter_code, 
	purchhead.entry_date, 
	purchhead.due_date, 
	purchhead.year_num, 
	purchhead.period_num, 
	purchhead.curr_code, 
	purchhead.printed_flag 
		ON ACTION "WEB-HELP" -- albo kd-377 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		MESSAGE " Searching Database - please wait " 
		attribute(yellow) 
		RETURN true 
	END IF 
END FUNCTION 
