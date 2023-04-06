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

	Source code beautified by beautify.pl on 2020-01-02 10:35:26	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/po_common_globals.4gl" 
#GLOBALS "../common/po_mod.4gl"

############################################################
# FUNCTION add_po_line(p_cmpy_code, p_kandoouser_sign_on_code, p_rec_purchhead,
#                                 p_rec_purchdetl,
#                                 p_rec_poaudit)
#
# po_add_line adds the line AFTER it has been entered
############################################################
FUNCTION add_po_line(p_cmpy_code,p_kandoouser_sign_on_code,p_rec_purchhead,p_rec_purchdetl,p_rec_poaudit) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE p_rec_purchhead RECORD LIKE purchhead.* 
	DEFINE p_rec_purchdetl RECORD LIKE purchdetl.* 
	DEFINE p_rec_poaudit RECORD LIKE poaudit.* 

	DEFINE l_rec_prodledg RECORD LIKE prodledg.* 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_rec_puparms RECORD LIKE puparms.* 
	DEFINE l_err_continue CHAR(1) 
	DEFINE l_err_message CHAR(40) 

	GOTO bypass 
	LABEL recovery: 
	LET l_err_continue = error_recover(l_err_message, status) 
	IF l_err_continue != "Y" THEN 
		EXIT program 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	LET l_err_message = "R11 - ORDER line addition failed" 
	IF p_rec_poaudit.ext_tax_amt IS NULL THEN 
		LET p_rec_poaudit.ext_tax_amt = 0 END IF 
		IF p_rec_poaudit.ext_cost_amt IS NULL THEN 
			LET p_rec_poaudit.ext_cost_amt = 0 END IF 
			IF p_rec_poaudit.received_qty IS NULL THEN 
				LET p_rec_poaudit.received_qty = 0 END IF 
				IF p_rec_poaudit.voucher_qty IS NULL THEN 
					LET p_rec_poaudit.voucher_qty = 0 END IF 
					IF p_rec_poaudit.line_total_amt IS NULL THEN 
						LET p_rec_poaudit.line_total_amt = 0 END IF 
						LET p_rec_purchdetl.order_num = p_rec_purchhead.order_num 
						LET p_rec_purchdetl.cmpy_code = p_rec_purchhead.cmpy_code 
						LET p_rec_purchdetl.vend_code = p_rec_purchhead.vend_code 
						LET p_rec_purchdetl.seq_num = 1 


						IF p_rec_purchdetl.type_ind matches "IC" 
						AND p_rec_poaudit.order_qty >= 0 THEN 

							SELECT * INTO l_rec_product.* FROM product 
							WHERE cmpy_code = p_rec_purchhead.cmpy_code 
							AND part_code = p_rec_purchdetl.ref_text 

							DECLARE ps1_curs CURSOR FOR 
							SELECT * INTO l_rec_prodstatus.* FROM prodstatus 
							WHERE part_code = p_rec_purchdetl.ref_text 
							AND ware_code = p_rec_purchhead.ware_code 
							AND cmpy_code = p_rec_purchhead.cmpy_code 
							FOR UPDATE 

							FOREACH ps1_curs 
								LET l_rec_prodstatus.seq_num = l_rec_prodstatus.seq_num + 1 
								IF l_rec_prodstatus.onord_qty IS NULL THEN 
									LET l_rec_prodstatus.onord_qty = 0 
								END IF 
								IF l_rec_prodstatus.stocked_flag = "Y" THEN 
									LET l_rec_prodstatus.onord_qty = l_rec_prodstatus.onord_qty 
									+ ((p_rec_poaudit.order_qty 
									* l_rec_product.pur_stk_con_qty) 
									* l_rec_product.stk_sel_con_qty) 
								END IF 
								UPDATE prodstatus 
								SET onord_qty = l_rec_prodstatus.onord_qty, 
								seq_num = l_rec_prodstatus.seq_num 
								WHERE cmpy_code = p_cmpy_code 
								AND part_code = l_rec_prodstatus.part_code 
								AND ware_code = l_rec_prodstatus.ware_code 
							END FOREACH 

						END IF 

						INSERT INTO purchdetl VALUES (p_rec_purchdetl.*) 

						LET p_rec_poaudit.cmpy_code = p_rec_purchdetl.cmpy_code 
						LET p_rec_poaudit.vend_code = p_rec_purchdetl.vend_code 
						LET p_rec_poaudit.po_num = p_rec_purchdetl.order_num 
						LET p_rec_poaudit.line_num = p_rec_purchdetl.line_num 
						LET p_rec_poaudit.tran_code = "AL" 
						LET p_rec_poaudit.tran_num = 0 
						LET p_rec_poaudit.received_qty = 0 
						LET p_rec_poaudit.voucher_qty = 0 
						LET p_rec_poaudit.jour_num = 0 
						LET p_rec_poaudit.entry_date = today 
						LET p_rec_poaudit.entry_code = p_kandoouser_sign_on_code 
						LET p_rec_poaudit.posted_flag = "N" 
						LET p_rec_poaudit.orig_auth_flag = "Y" 
						LET p_rec_poaudit.now_auth_flag = "Y" 
						LET p_rec_poaudit.seq_num = p_rec_purchdetl.seq_num 
						LET p_rec_poaudit.desc_text = p_rec_purchdetl.desc_text 
						INSERT INTO poaudit VALUES (p_rec_poaudit.*) 

END FUNCTION 
