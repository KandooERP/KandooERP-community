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

	Source code beautified by beautify.pl on 2020-01-02 17:06:23	Source code beautified by beautify.pl on 2020-01-02 17:03:33	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "R_PU_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################


#######################################################################
# MAIN
#
# reset FOB cost
#######################################################################
MAIN 

	DEFINE 
	pr_purchhead RECORD LIKE purchhead.*, 
	pr_purchdetl RECORD LIKE purchdetl.*, 
	pr_poaudit RECORD LIKE poaudit.*, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	try_again CHAR(1), 
	warehouse_code CHAR(3), 
	err_message CHAR(40), 
	error_msg CHAR(100), 
	unit_cost LIKE poaudit.unit_cost_amt, 
	pur_curr_code LIKE purchhead.curr_code, 
	base_curr_code LIKE arparms.currency_code 


	CALL setModuleId("RS3") -- albo 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_r_pu() #init r/pu purchase ORDER module 

	GOTO bypass 
	LABEL recovery: 
	LET try_again = error_recover(err_message, status) 
	IF try_again != "Y" 
	THEN 
		EXIT program 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	BEGIN WORK 

		LOCK TABLE prodstatus in share MODE 

		DECLARE purchdetl_curs CURSOR FOR 
		SELECT * 
		INTO pr_purchdetl.* 
		FROM purchdetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND type_ind = "I" 

		FOREACH purchdetl_curs 

			CALL po_line_info(glob_rec_kandoouser.cmpy_code, 
			pr_purchdetl.order_num, 
			pr_purchdetl.line_num) 
			RETURNING pr_poaudit.order_qty, 
			pr_poaudit.received_qty, 
			pr_poaudit.voucher_qty, 
			pr_poaudit.unit_cost_amt, 
			pr_poaudit.ext_cost_amt, 
			pr_poaudit.unit_tax_amt, 
			pr_poaudit.ext_tax_amt, 
			pr_poaudit.line_total_amt 

			SELECT curr_code, ware_code INTO pur_curr_code, warehouse_code 
			FROM purchhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = pr_purchdetl.vend_code 
			AND order_num = pr_purchdetl.order_num 

			LET err_message = "RS3 prodstatus UPDATE" 

			UPDATE prodstatus SET 
			for_cost_amt = pr_poaudit.unit_cost_amt, 
			for_curr_code = pur_curr_code 
			WHERE 
			cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_purchdetl.ref_text 
			AND ware_code = warehouse_code 

		END FOREACH 

		SELECT currency_code INTO base_curr_code FROM arparms 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND parm_code = "1" 

		IF (status = notfound) THEN 
			LET error_msg = "base currency NOT found ", glob_rec_kandoouser.cmpy_code 
			CALL errorlog(error_msg) 
			EXIT program 
		END IF 


		DECLARE prod_curs CURSOR FOR 
		SELECT * 
		INTO pr_prodstatus.* 
		FROM prodstatus 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND (for_cost_amt IS NULL OR for_cost_amt = 0) 
		FOR UPDATE 

		LET err_message = "RS3 prodstatus UPDATE" 

		FOREACH prod_curs 

			UPDATE prodstatus SET 
			for_cost_amt = prodstatus.act_cost_amt, 
			for_curr_code = base_curr_code 
			WHERE CURRENT OF prod_curs 

		END FOREACH 

	COMMIT WORK 

END MAIN 
