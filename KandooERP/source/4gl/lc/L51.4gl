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
}
#as GLOBALS FROM L51a

{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module L51 allows the user TO enter PO RETURN Shipments

# these GLOBALS should be duplicated in L54.4gl
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "L_LC_GLOBALS.4gl" 

GLOBALS "L51_GLOBALS.4gl" 

MAIN 
	DEFINE i SMALLINT 

	#Initial UI Init
	CALL setModuleId("L51") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 


	#
	#  need TO defer interrupt AND quit because of UPDATE situation
	#  of ps_prodstatus in L11b.4gl
	LET func_type = "Shipment Entry" 
	LET f_type = "O" 
	LET first_time = 1 
	LET noerror = 1 
	LET display_ship_code = "N" 
	LET ans = "Y" 
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
	acct_code CHAR(18), 
	duty_rate_per DECIMAL(6,3), 
	full_recpt_flag CHAR(1), 
	stock_wo_flag CHAR(1) 
	) with no LOG 
	WHILE ans = "Y" 
		FOR i = 1 TO 100 
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
		IF select_vendor() THEN 
			LET restart = false 
			WHILE L51_header() 
				IF delivery_address() THEN 
					WHILE lineitem() 
						IF summup() THEN 
							CALL write_ship() 
							IF noerror = 1 THEN 
								FOR i = 1 TO arr_size 
									INITIALIZE st_shipdetl[i].* TO NULL 
								END FOR 
								# MESSAGE out shipment number
								LET first_time = 1 
								LET temp_ship_code = pr_shiphead.ship_code 
								LET display_ship_code = "Y" 
								LET restart = true 
								EXIT WHILE {exit WHILE lineitem} 
							END IF 
						END IF {summup} 
						CLOSE WINDOW wl102 
					END WHILE {lineitem} 
				END IF { delivery_address} 
				CLOSE WINDOW wl102 
				IF restart THEN 
					EXIT WHILE {header} 
				END IF 
				CLOSE WINDOW wl101 
			END WHILE {L51_header()} 
			CLOSE WINDOW wl101 
			IF restart THEN 
				LET restart = false 
			END IF 
		ELSE 
			LET ans = "N" 
		END IF {select_vendor} 
		CLOSE WINDOW wl100 
	END WHILE {ans = "Y"} 
END MAIN 
