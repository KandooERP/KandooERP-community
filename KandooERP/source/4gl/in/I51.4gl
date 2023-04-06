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

	Source code beautified by beautify.pl on 2020-01-03 09:12:26	$Id: $
}




# Inter Branch Stock Transfer
#               allows entry of items TO Transfer FROM one warehouse TO
#               another.  A product ledger RECORD IS created FOR both
#               stock movements. Transfer prodledg enties are NOT posted


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 
#GLOBALS "I51_GLOBALS.4gl" 

#      DEFINE
#         msgresp LIKE language.yes_flag,
#         pr_inparms RECORD LIKE inparms.*,

#         pr_ibtdetl RECORD LIKE ibtdetl.*,
#         rpt_pageno LIKE rmsreps.page_num,

#DEFINE pr_ibthead RECORD LIKE ibthead.*
#DEFINE pr_mode CHAR(10)
#DEFINE pr_sched_ind  CHAR(1)
# Module scope variables
DEFINE 
	pr_inparms RECORD LIKE inparms.*, 
{
	pr_ibthead RECORD LIKE ibthead.*, 
	pr_customer RECORD LIKE customer.*, 
	pr_ibtdetl RECORD LIKE ibtdetl.*, 
	pr_stk_sel_con_qty LIKE product.stk_sel_con_qty, 
	pr_req_num LIKE reqhead.req_num, 
	pr_sched_ind_sto LIKE ibthead.sched_ind,
} 
	pr_mode CHAR(10)
{ 
	pr_sched_ind CHAR(1), 
	rpt_pageno LIKE rmsreps.page_num, 
	query_text CHAR(500), 
	pa_ibtdetl DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		line_num LIKE ibtdetl.line_num, 
		part_code LIKE product.part_code, 
		desc_text LIKE product.desc_text, 
		trf_qty LIKE ibtdetl.trf_qty, 
		stock_uom_code LIKE product.stock_uom_code, 
		sell_tran_qty LIKE prodledg.tran_qty, 
		sell_uom_code LIKE product.stock_uom_code 
	END RECORD, 
	pa_prledger DYNAMIC ARRAY OF RECORD LIKE prodledg.*, 
	pa_prodledg DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		part_code LIKE product.part_code, 
		desc_text LIKE product.desc_text, 
		stock_tran_qty LIKE prodledg.tran_qty, 
		stock_uom_code LIKE product.stock_uom_code, 
		sell_tran_qty LIKE prodledg.tran_qty, 
		sell_uom_code LIKE product.stock_uom_code 
	END RECORD, 
	pr_printcodes RECORD LIKE printcodes.*, 
	pr_prodledg RECORD LIKE prodledg.*, 
	pr_temp_text CHAR(200), 
	pr_grandtot DECIMAL(16,2), 
	pr_arr_cnt SMALLINT
}

####################################################################
# MAIN
####################################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("I51") 
	CALL ui_init(0) 


	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 

	SELECT * INTO pr_inparms.* 
	FROM inparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 
	IF sqlca.sqlcode = notfound THEN 
		LET msgresp = kandoomsg("I",5002,"") 
		# I5002 Inventory parameters NOT SET up, run IZP
		EXIT program 
	END IF 
	--LET pr_sched_ind = NULL 
	LET pr_mode = "ADD" 
	CALL create_table("ibtdetl","t_ibtdetl","","N") 
	OPEN WINDOW i669 with FORM "I669" 
	 CALL windecoration_i("I669") -- albo kd-758 
--	INITIALIZE pr_ibthead.* TO NULL 
	WHILE stock_transfer_header_entry(pr_mode,"") 
		IF product_lines_entry("ADD","") THEN 
			-- DELETE FROM t_ibtdetl WHERE 1=1 
		END IF 
	END WHILE 
	CLOSE WINDOW i669 
END MAIN 
