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

	Source code beautified by beautify.pl on 2020-01-02 18:38:28	$Id: $
}




{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module L11f Create Shipment Header & Detail entires in the tables

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "L_LC_GLOBALS.4gl" 

GLOBALS "L11_GLOBALS.4gl" 

DEFINE 
check_duty, check_fob money(10,2) 


FUNCTION write_ship() 
	DEFINE 
	blanks SMALLINT, 
	i SMALLINT, 
	vouch_code LIKE voucher.vouch_code, 
	vouch_amt, new_vouch_amt LIKE voucher.total_amt, 
	conv_rate LIKE voucher.conv_qty 

	LET check_duty = 0 
	LET check_fob = 0 
	GOTO bypass 
	LABEL recovery: 
	LET try_again = error_recover(err_message, status) 
	IF try_again != "Y" THEN 
		EXIT program 
	END IF 
	LABEL bypass: 
	WHENEVER any ERROR GOTO recovery 
	BEGIN WORK 
		WHENEVER any ERROR GOTO recovery 
		IF f_type != "E" THEN 
			LET pr_shiphead.eta_init_date = pr_shiphead.eta_curr_date 
		ELSE 
			#
			#  now delete the ship lines
			#
			LET err_message = "L11f - Shipdetl deletion" 
			DELETE FROM shipdetl 
			WHERE ship_code = ps_shiphead.ship_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			#
			# delete the shiphead
			#
			LET err_message = "L11f - Shiphead deletion" 
			DELETE FROM shiphead 
			WHERE ship_code = ps_shiphead.ship_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = ps_shiphead.vend_code 
			# copy across ship static details
			LET pr_shiphead.rev_date = today 
			IF ps_shiphead.rev_num IS NULL THEN 
				LET ps_shiphead.rev_num = 0 
			END IF 
			LET pr_shiphead.rev_num = ps_shiphead.rev_num + 1 
		END IF 
		#
		#now add in the ship lines
		#
		LET blanks = 0 
		FOR i = 1 TO arr_size 
			LET pr_shipdetl.* = st_shipdetl[i].* 
			IF pr_shipdetl.fob_unit_ent_amt IS NULL THEN 
				LET pr_shipdetl.fob_unit_ent_amt = 0 
			END IF 
			IF pr_shipdetl.fob_ext_ent_amt IS NULL THEN 
				LET pr_shipdetl.fob_ext_ent_amt = 0 
			END IF 
			IF pr_shipdetl.duty_unit_ent_amt IS NULL THEN 
				LET pr_shipdetl.duty_unit_ent_amt = 0 
			END IF 
			IF pr_shipdetl.duty_ext_ent_amt IS NULL THEN 
				LET pr_shipdetl.duty_ext_ent_amt = 0 
			END IF 
			IF pr_shipdetl.ship_rec_qty IS NULL THEN 
				LET pr_shipdetl.ship_rec_qty = 0 
			END IF 
			IF pr_shipdetl.landed_cost IS NULL THEN 
				LET pr_shipdetl.landed_cost = 0 
			END IF 
			LET pr_shipdetl.ship_code = pr_shiphead.ship_code 
			LET pr_shipdetl.line_num = i 
			#  now add the line IF its a real line
			#
			IF pr_shipdetl.part_code IS NULL 
			AND pr_shipdetl.cmpy_code IS NULL THEN 
				LET blanks = blanks + 1 
			ELSE 
				LET err_message = "L11 - shipdetl INSERT" 
				INSERT INTO shipdetl VALUES (pr_shipdetl.*) 
			END IF 
			LET check_duty = check_duty + pr_shipdetl.duty_ext_ent_amt 
			LET check_fob = check_fob + pr_shipdetl.fob_ext_ent_amt 
		END FOR 
		IF check_duty != pr_shiphead.duty_ent_amt 
		OR check_duty IS NULL 
		OR pr_shiphead.duty_ent_amt IS NULL THEN 
			ERROR "Audit on duty figures NOT correct" 
			CALL errorlog("L11 - Duty Total Amount Incorrect") 
			CALL display_error() 
			LET noerror = 0 
		END IF 
		IF check_fob != pr_shiphead.fob_ent_cost_amt 
		OR check_fob IS NULL 
		OR pr_shiphead.fob_ent_cost_amt IS NULL THEN 
			ERROR "Audit on FOB figures NOT correct" 
			CALL errorlog("L11 - FOB Total Amount Incorrect") 
			CALL display_error() 
			LET noerror = 0 
		END IF 
		#
		# write out the shiphead
		#
		LET pr_shiphead.line_num = arr_size - blanks 
		IF pr_shiphead.fob_ent_cost_amt IS NULL 
		OR pr_shiphead.duty_ent_amt IS NULL THEN 
			ERROR " Nulls in ship header" 
			GOTO recovery 
		END IF 
		LET err_message = "L11 - Shipment header INSERT" 
		INSERT INTO shiphead VALUES (pr_shiphead.*) 
		IF noerror = 1 THEN 
		COMMIT WORK 
	ELSE 
		ROLLBACK WORK 
	END IF 
	WHENEVER any ERROR stop 
END FUNCTION 


############################################################
# FUNCTION display_error()
#
#
############################################################
FUNCTION display_error() 
	DEFINE err_msg CHAR(60) 

	LET err_msg = "Error occurred" 
	CALL errorlog(err_msg) 
	LET err_msg = "FOB Total ",pr_shiphead.fob_ent_cost_amt 
	CALL errorlog(err_msg) 
	LET err_msg = "Check FOB", check_fob 
	CALL errorlog(err_msg) 
	LET err_msg = "Shipment Duty ",pr_shiphead.duty_ent_amt 
	CALL errorlog(err_msg) 
	LET err_msg = "Check Duty ", check_duty 
	CALL errorlog(err_msg) 
	LET err_msg = "Array size ",arr_size 
	CALL errorlog(err_msg) 
	FOR i=1 TO arr_size 
		LET err_msg = "Product ",st_shipdetl[i].part_code,"FOB ", 
		st_shipdetl[i].fob_ext_ent_amt, "Duty ", 
		st_shipdetl[i].duty_ext_ent_amt 
		CALL errorlog(err_msg) 
	END FOR 
END FUNCTION 
