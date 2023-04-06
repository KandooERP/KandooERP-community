###########################################################################
#
# huho: moved this function TO lib_validation (which IS included in lib_tool) 
#
###########################################################################


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
##
## ABN Check Digit verification routine
##
############################################################
# GLOBAL Scope Variables
############################################################


#huho moved TO lib_validation (which IS included in lib_tool)
{
FUNCTION validate_vat_registration_code(p_vat_code)
	DEFINE p_vat_code CHAR(11)
	DEFINE l_arr_abn_num array[11] of INTEGER
	DEFINE l_weight_num array[11] of INTEGER
	DEFINE l_check_digit INTEGER
	DEFINE i INTEGER

   IF length(p_vat_code) <> 11 THEN
      RETURN FALSE
   END IF
   FOR i = 1 TO 11
      LET l_arr_abn_num[i] = p_vat_code[i]
      IF l_arr_abn_num[i] IS NULL THEN
         LET l_arr_abn_num[i] = 0
      END IF
   END FOR
   LET l_weight_num[1] = 10
   LET l_weight_num[2] = 1
   LET l_weight_num[3] = 3
   LET l_weight_num[4] = 5
   LET l_weight_num[5] = 7
   LET l_weight_num[6] = 9
   LET l_weight_num[7] = 11
   LET l_weight_num[8] = 13
   LET l_weight_num[9] = 15
   LET l_weight_num[10] = 17
   LET l_weight_num[11] = 19
   LET l_arr_abn_num[1] = l_arr_abn_num[1] - 1
   LET l_check_digit = 0
   FOR i = 1 TO 11
       LET l_check_digit = l_check_digit + (l_arr_abn_num[i] *
                                              l_weight_num[i])
   END FOR
   IF l_check_digit mod 89 <> 0 THEN
      RETURN FALSE
   ELSE
      RETURN TRUE
   END IF
END FUNCTION

}

