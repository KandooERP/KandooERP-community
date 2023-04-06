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

	Source code beautified by beautify.pl on 2020-01-02 10:35:27	$Id: $
}




############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 


############################################################
# FUNCTION pooswind(p_cmpy_code, p_order_number)
#
#
############################################################
FUNCTION pooswind(p_cmpy_code,p_order_number) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_order_number INTEGER 
	DEFINE l_arr_rec_purchdetl DYNAMIC ARRAY OF #array [2020] OF RECORD 
		RECORD 
			type_ind LIKE purchdetl.type_ind, 
			desc_text LIKE purchdetl.desc_text, 
			order_qty LIKE poaudit.order_qty, 
			received_qty LIKE poaudit.received_qty, 
			voucher_qty LIKE poaudit.voucher_qty 
		END RECORD 
	DEFINE l_rec_poaudit RECORD LIKE poaudit.* 
	DEFINE l_rec_purchdetl RECORD LIKE purchdetl.* 
	DEFINE l_idx SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

		INITIALIZE l_rec_purchdetl.* TO NULL 
		OPTIONS DELETE KEY f36, 
		INSERT KEY f36 

		OPEN WINDOW r116 with FORM "R116" 
		CALL windecoration_r("R116") 

		LET l_msgresp = kandoomsg("U",1002,"") 
		DECLARE c_item CURSOR FOR 
		SELECT purchdetl.* INTO l_rec_purchdetl.* FROM purchdetl 
		WHERE order_num = p_order_number 
		AND cmpy_code = p_cmpy_code 
		ORDER BY line_num 
		LET l_idx = 0 

		FOREACH c_item 
			LET l_idx = l_idx + 1 
			LET l_arr_rec_purchdetl[l_idx].type_ind = l_rec_purchdetl.type_ind 
			LET l_arr_rec_purchdetl[l_idx].desc_text = l_rec_purchdetl.desc_text 
			CALL po_line_info(p_cmpy_code, l_rec_purchdetl.order_num, l_rec_purchdetl.line_num) 
			RETURNING l_rec_poaudit.order_qty, 
			l_rec_poaudit.received_qty, 
			l_rec_poaudit.voucher_qty, 
			l_rec_poaudit.unit_cost_amt, 
			l_rec_poaudit.ext_cost_amt, 
			l_rec_poaudit.unit_tax_amt, 
			l_rec_poaudit.ext_tax_amt, 
			l_rec_poaudit.line_total_amt 
			LET l_arr_rec_purchdetl[l_idx].order_qty = l_rec_poaudit.order_qty 
			LET l_arr_rec_purchdetl[l_idx].received_qty = l_rec_poaudit.received_qty 
			LET l_arr_rec_purchdetl[l_idx].voucher_qty = l_rec_poaudit.voucher_qty 
			#      IF l_idx = 2000 THEN
			#         LET l_msgresp = kandoomsg("U",6100,l_idx)
			#         #6100 First l_idx records selected
			#         EXIT FOREACH
			#      END IF
		END FOREACH 

		LET l_msgresp = kandoomsg("U",9113,l_idx) 
		#9113 l_idx records selected
		#   CALL set_count(l_idx)
		LET l_msgresp = kandoomsg("U",1008,"") 
		#1008 OK TO continue.

		DISPLAY ARRAY l_arr_rec_purchdetl TO sr_purchdetl.* ATTRIBUTE(UNBUFFERED) 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","pooswind","display-arr-purchdetl") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END DISPLAY 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		END IF 

		CLOSE WINDOW r116 

		RETURN 
END FUNCTION 


