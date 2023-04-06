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
# Requires
# common/crhdwind.4gl
# common/cashwind.4gl
# common/inhdwind.4gl
###########################################################################

# \brief module GXX displays source document info FROM anywhere

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 

############################################################
# MAIN
#
#
############################################################
MAIN 
	DEFINE l_argval4 CHAR(150) 
	DEFINE l_argval5 CHAR(150) 

	DEFINE l_value1 CHAR(40) 
	DEFINE l_position SMALLINT 
	DEFINE l_string CHAR(150) 
	DEFINE l_end SMALLINT 
	DEFINE i SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	DEFINE l_arg_str1 STRING 
	DEFINE l_arg_str2 STRING 
	DEFINE l_arg_str3 STRING 
	DEFINE l_arg_str4 STRING 

	CALL setModuleId("GXX") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 

	LET l_value1 = get_url_menu_char2() #arg_val(1) 
	CASE 
		WHEN (l_value1 = TRAN_TYPE_INVOICE_IN) 
			# Invoice display
			CALL disc_per_head( glob_rec_kandoouser.cmpy_code, get_url_ref_text(), get_url_ref_num()) 

		WHEN (l_value1 = "VO") 
			# Voucher display
			CALL display_voucher_header( glob_rec_kandoouser.cmpy_code, get_url_ref_num()) 

		WHEN (l_value1 = TRAN_TYPE_RECEIPT_CA) 
			# Cash Receipt display
			CALL cash_disp( glob_rec_kandoouser.cmpy_code, get_url_ref_text(), get_url_ref_num()) 

		WHEN (l_value1 = TRAN_TYPE_CREDIT_CR) 
			# Credit display
			CALL cr_disp_head( glob_rec_kandoouser.cmpy_code, get_url_ref_text(), get_url_ref_num()) 

		WHEN (l_value1 = "GR") 
			# Goods Receipt display
			LET l_string = get_url_account_ledger() #arg_val(4) 

			LET l_end = length(l_string) 
			FOR i = 1 TO l_end 
				IF l_string[i,i] = '|' THEN 
					LET l_position = i 
					EXIT FOR 
				END IF 
			END FOR 

			LET l_argval4= l_string[1,l_position - 1] 
			LET l_argval5 = l_string[l_position+1,l_end] 

			LET l_arg_str1 = get_url_ref_text() 
			LET l_arg_str2 = get_url_ref_num() 
			#           LET l_arg_str3 = l_argval4
			#           LET l_arg_str4 = l_argval5

			CALL run_prog("R19",l_arg_str1,l_arg_str2,l_argval4,l_argval5) 

		OTHERWISE 
			LET l_msgresp = kandoomsg("G",9096,l_value1) 
			#9096 "No source information FOR ", l_value1
			SLEEP 6 
	END CASE 

END MAIN 
############################################################
# END MAIN
############################################################