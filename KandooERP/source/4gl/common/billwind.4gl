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



#
# Billing Type Code lookup window FOR finding billing type codes
# WHEN adding Contracts.

GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION show_bill_type() 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_arr_pa_bill_type array[5] OF RECORD 
		bill_type_code LIKE contracthead.bill_type_code, 
		type_text CHAR(12) 
	END RECORD 
	DEFINE l_arr_pb_bill_type array[5] OF RECORD 
		bill_type_code LIKE contracthead.bill_type_code, 
		type_text CHAR(12) 
	END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_scrn SMALLINT 
	DEFINE l_arr_size SMALLINT 
	DEFINE l_formname CHAR(15) 

	OPEN WINDOW wa909 with FORM "A909" 
	CALL windecoration_a("A909") -- albo kd-767 

	LET l_msgresp = kandoomsg("A",1513,"") 
	# MESSAGE "ESC TO SELECT, DEL TO EXIT"

	LET l_arr_pa_bill_type[1].bill_type_code = "D" 
	LET l_arr_pa_bill_type[2].bill_type_code = "W" 
	LET l_arr_pa_bill_type[3].bill_type_code = "M" 
	LET l_arr_pa_bill_type[4].bill_type_code = "E" 
	LET l_arr_pa_bill_type[5].bill_type_code = "A" 
	LET l_arr_pa_bill_type[1].type_text = "Daily " 
	LET l_arr_pa_bill_type[2].type_text = "Weekly " 
	LET l_arr_pa_bill_type[3].type_text = "Monthly " 
	LET l_arr_pa_bill_type[4].type_text = "END Of Month" 
	LET l_arr_pa_bill_type[5].type_text = "Annually " 

	LET l_idx = 5 
	LET l_arr_size = 5 
	CALL set_count(l_arr_size) 

	INPUT ARRAY l_arr_pa_bill_type WITHOUT DEFAULTS FROM sr_bill_type.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","billwind","input-arr-bill-type") 


		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			LET l_scrn = scr_line() 
			LET l_arr_pb_bill_type[l_idx].* = l_arr_pa_bill_type[l_idx].* 

		AFTER ROW 
			DISPLAY l_arr_pb_bill_type[l_idx].* TO sr_bill_type[l_scrn].* 
			LET l_arr_pa_bill_type[l_idx].* = l_arr_pb_bill_type[l_idx].* 


	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		CLOSE WINDOW wa909 
		RETURN "" 
	END IF 

	CLOSE WINDOW wa909 
	LET l_idx = arr_curr() 

	RETURN l_arr_pa_bill_type[l_idx].bill_type_code 

END FUNCTION 


