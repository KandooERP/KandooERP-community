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

	Source code beautified by beautify.pl on 2020-01-02 18:38:29	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "L_LC_GLOBALS.4gl" 

{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module L14  allows the user TO edit Shipments

# these have TO be the same as the GLOBALS in L11
GLOBALS 
	DEFINE 
	pr_shiphead RECORD LIKE shiphead.*, 
	ps_shiphead RECORD LIKE shiphead.*, 
	pr_vendor RECORD LIKE vendor.*, 
	pr_shipagent RECORD LIKE vendor.*, 
	pr_warehouse RECORD LIKE warehouse.*, 
	pr_shipdetl RECORD LIKE shipdetl.*, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pr_category RECORD LIKE category.*, 
	pr_product RECORD LIKE product.*, 
	pr_currency RECORD LIKE currency.*, 
	pr_tariff RECORD LIKE tariff.*, 
	pr_smparms RECORD LIKE smparms.*, 
	pr_glparms RECORD LIKE glparms.*, 
	pr_shipstatus RECORD LIKE shipstatus.*, 
	pr_voucher RECORD LIKE voucher.*, 
	pr_debithead RECORD LIKE debithead.*, 
	pr_part_code LIKE shipdetl.part_code, 
	scrn, idx, ret_flag, i, restart, noerror SMALLINT, 
	nxtfld, firstime SMALLINT, 
	arr_size, counter SMALLINT, 
	f_type, ans CHAR(1), 
	try_again CHAR(1), 
	save_conversion_qty FLOAT, 
	save_curr_code LIKE shiphead.curr_code, 
	func_type CHAR(14), 
	retain_flag SMALLINT, 
	err_message CHAR(40), 
	st_shipdetl array[300] OF RECORD LIKE shipdetl.*, 
	tran_date DATE, 
	temp_ship_code CHAR(8), 
	pr_po_num LIKE purchhead.order_num, 
	max_shipdetls SMALLINT, 
	pa_shipdetl ARRAY [300] OF RECORD 
		part_code LIKE shipdetl.part_code, 
		source_doc_num LIKE shipdetl.source_doc_num, 
		ship_inv_qty LIKE shipdetl.ship_inv_qty, 
		fob_unit_ent_amt LIKE shipdetl.fob_unit_ent_amt, 
		tariff_code LIKE shipdetl.tariff_code, 
		duty_unit_ent_amt LIKE shipdetl.duty_unit_ent_amt 
	END RECORD 

END GLOBALS 

MAIN 
	DEFINE 
	pr_retry CHAR(1) 

	#Initial UI Init
	CALL setModuleId("L14") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	#
	# need TO defer interrupt AND quit because of UPDATE situation
	# of ps_prodstatus in L11b.4gl
	#
	LET func_type = "Shipment Edit" 
	LET f_type = "E" 
	LET noerror = 1 
	LET ans = "Y" 
	LET max_shipdetls = 300 
	CREATE temp TABLE tempdetl 
	( cmpy_code CHAR(2), 
	ship_code CHAR(8), 
	line_num SMALLINT, 
	part_code CHAR(15), 
	desc_text CHAR(30), 
	source_doc_num INTEGER, 
	doc_line_num SMALLINT, 
	job_code CHAR(8), 
	var_code SMALLINT, 
	activity_code CHAR(8), 
	ship_inv_qty FLOAT, 
	ship_rec_qty FLOAT, 
	fob_unit_ent_amt DECIMAL(16,4), 
	fob_ext_ent_amt DECIMAL(16,2), 
	tariff_code CHAR(12), 
	duty_unit_ent_amt DECIMAL(16,4), 
	duty_ext_ent_amt DECIMAL(16,2), 
	landed_cost DECIMAL(16,4), 
	ext_landed_cost DECIMAL(16,2), 
	acct_code CHAR(18), 
	duty_rate_per DECIMAL(6,3), 
	full_recpt_flag CHAR(1), 
	stock_wo_flag CHAR(1), 
	tax_code CHAR(3), 
	level_code CHAR(1), 
	line_total_amt DECIMAL(16,2) 
	) with no LOG 

	CALL create_table("voucherdist","t_voucherdist","","N") 
	CALL create_table("debitdist", "t_debitdist", "","N") 

	WHILE ans = "Y" 
		FOR i = 1 TO max_shipdetls 
			INITIALIZE pa_shipdetl[i].* TO NULL 
		END FOR 
		WHENEVER ERROR stop 
		DELETE FROM tempdetl WHERE 1=1 
		INITIALIZE pr_shiphead.* TO NULL 
		LET pr_shiphead.fob_inv_cost_amt = 0 
		LET pr_shiphead.fob_curr_cost_amt = 0 
		LET pr_shiphead.fob_ent_cost_amt = 0 
		LET pr_shiphead.duty_ent_amt = 0 
		LET pr_shiphead.duty_inv_amt = 0 
		LET pr_shiphead.other_inv_amt = 0 
		LET pr_shiphead.ant_other_amt = 0 
		LET pr_shiphead.voucher_flag = "N" 
		LET pr_shiphead.finalised_flag = "N" 
		INITIALIZE pr_shipdetl.* TO NULL 
		LET noerror = 1 
		IF ship_select() THEN 
			LET ps_shiphead.* = pr_shiphead.* 
			IF select_vendor() THEN 
				LET restart = false 
				WHILE L11_header() 
					WHILE lineitem() 
						LET pr_retry = 'Y' 
						WHILE summup() 
							LET pr_retry = handle_updates() 
							IF pr_retry = 'N' THEN 
								EXIT WHILE 
							END IF 
						END WHILE {summup} 
						IF pr_retry = 'N' THEN 
							EXIT WHILE 
						END IF 
					END WHILE {lineitem} 
					IF restart THEN 
						EXIT WHILE {header} 
					END IF 
					CLOSE WINDOW wl101 
				END WHILE {L11_header()} 
				CLOSE WINDOW wl101 
			END IF {ship_select} 
			IF restart THEN 
				LET restart = false 
			END IF 
			CLOSE WINDOW wl100 
		ELSE 
			LET ans = "N" 
		END IF {select_vendor} 
	END WHILE {ans = "Y"} 
END MAIN 
