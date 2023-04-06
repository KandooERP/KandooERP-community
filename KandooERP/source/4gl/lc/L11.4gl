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

	Source code beautified by beautify.pl on 2020-01-02 18:38:27	$Id: $
}
#as GLOBALS FROM L11a
{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module L11 allows the user TO enter Shipments FOR Landed Costing

# these GLOBALS should be duplicated in L14.4gl

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../lc/L_LC_GLOBALS.4gl" 
GLOBALS "../lc/L11_GLOBALS.4gl" 

MAIN 
	DEFINE pr_retry CHAR(1) 
	DEFINE i SMALLINT 

	#Initial UI Init
	CALL setModuleId("L11") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	#
	#  need TO defer interrupt AND quit because of UPDATE situation
	#  of ps_prodstatus in L11b.4gl ??? WhAT ?
	LET func_type = "Shipment Entry" 
	LET f_type = "O" 
	LET noerror = 1 
	LET ans = "Y" 
	LET max_shipdetls = 300 
	CREATE temp TABLE tempdetl 
	( 
	cmpy_code CHAR(2), 
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
		WHENEVER any ERROR stop 
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

		ELSE 
			LET ans = "N" 
		END IF {select_vendor} 
		CLOSE WINDOW wl100 
	END WHILE {ans = "Y"} 
END MAIN 

