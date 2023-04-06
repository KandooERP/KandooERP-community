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

	Source code beautified by beautify.pl on 2020-01-02 18:38:33	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "L_LC_GLOBALS.4gl" 

GLOBALS "L61_GLOBALS.4gl" 

DEFINE 
check_tax, 
check_mat, 
total_tax MONEY, 
count2 SMALLINT 

FUNCTION write_credship() 
	DEFINE 
	cnt, i, tax_idx SMALLINT, 
	ans, chkagn CHAR(1), 
	err_flag CHAR(1), 
	foundit CHAR(1), 
	char_ship_code CHAR(8), 
	dec_ship_code DECIMAL(8,0), 

	pr_smparms RECORD LIKE smparms.* 

	LET check_tax = 0 
	LET check_mat = 0 
	LET err_flag = "N" 
	FOR tax_idx = 1 TO 300 
		INITIALIZE pa_taxamt[tax_idx].tax_code TO NULL 
	END FOR 
	GOTO bypass 
	LABEL recovery: 
	LET try_again = error_recover(err_message, status) 
	IF try_again != "Y" THEN 
		#CALL out_stat()
		EXIT program 
	END IF 
	LABEL bypass: 
	LET noerror = 1 
	WHENEVER ERROR GOTO recovery 
	SELECT * 
	INTO pr_smparms.* 
	FROM smparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_num = "1" 
	BEGIN WORK 
		#   IF f_type = "J" AND
		#NOT pv_corp_cust AND
		#(pr_shiphead.org_cust_code =
		#pr_shiphead.vend_code) THEN
		#LET pr_shiphead.vend_code =
		#ps_shiphead.vend_code
		#END IF

		LET cnt = 0 
		IF f_type = "C" THEN 
			WHILE true 
				LET cnt = cnt + 1 
				LET char_ship_code = pr_smparms.next_ship_code 
				LET dec_ship_code = pr_smparms.next_ship_code 
				DECLARE c1 CURSOR FOR 
				SELECT 1 INTO cnt FROM shiphead 
				WHERE ship_code = char_ship_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				OPEN c1 
				FETCH c1 
				IF status = notfound THEN 
					LET pr_shiphead.ship_code = char_ship_code 
					UPDATE smparms 
					SET next_ship_code = dec_ship_code 
					EXIT WHILE 
				END IF 
				IF cnt > 50 THEN 
					EXIT WHILE 
				END IF 
				LET pr_smparms.next_ship_code = pr_smparms.next_ship_code + 1 
			END WHILE 
			IF cnt > 50 THEN 
				LET err_message = "L61 - Allocate shipment number error" 
				LET status = pr_smparms.next_ship_code 
				GO TO recovery 
			END IF 
			CLOSE c1 
			LET pr_shiphead.finalised_flag = "N" 
		ELSE 
			### Shipment Edit
			### Obtain latest appl_amt, disc_amt
			### Lock FOR Update
			DECLARE appl_curs CURSOR FOR 
			SELECT * 
			INTO ps_shiphead.* 
			FROM shiphead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ship_code = pr_shiphead.ship_code 
			FOR UPDATE 
			OPEN appl_curs 
			FETCH appl_curs 
			LET pr_shiphead.other_inv_amt = ps_shiphead.other_inv_amt 
			LET pr_shiphead.other_cost_amt = ps_shiphead.other_cost_amt 
			LET pr_shiphead.late_cost_amt = ps_shiphead.late_cost_amt 
			LET pr_shiphead.rev_date = today 
			IF pr_shiphead.rev_num IS NULL THEN 
				LET pr_shiphead.rev_num = 0 
			END IF 
			LET pr_shiphead.rev_num = pr_shiphead.rev_num + 1 
			#  Delete the ship lines
			LET err_message = "A47 - shipline deletion" 
			DELETE FROM shipdetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ship_code = ps_shiphead.ship_code 
			#
			# delete out the shiphead
			#
			LET err_message = "A47 - Credhead deletion" 
			DELETE FROM shiphead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = ps_shiphead.vend_code 
			AND ship_code = ps_shiphead.ship_code 
		END IF 
		#  now add in the ship lines
		FOR i = 1 TO arr_size 
			LET pr_shipdetl.* = st_shipdetl[i].* 
			IF pr_shipdetl.duty_ext_ent_amt IS NULL THEN 
				LET pr_shipdetl.duty_ext_ent_amt = 0 
			END IF 
			IF pr_shipdetl.ext_landed_cost IS NULL THEN 
				LET pr_shipdetl.ext_landed_cost = 0 
			END IF 
			IF pr_shipdetl.line_total_amt IS NULL THEN 
				LET pr_shipdetl.line_total_amt = 0 
			END IF 
			LET pr_shipdetl.ship_code = pr_shiphead.ship_code 
			LET pr_shipdetl.line_num = i 
			IF pr_shipdetl.part_code IS NULL 
			OR pr_shipdetl.ship_inv_qty = 0 THEN 
			ELSE 
				# patch up the line_acct_code
				CALL account_patch(glob_rec_kandoouser.cmpy_code, pr_shipdetl.acct_code, patch_code) 
				RETURNING pr_shipdetl.acct_code 
			END IF 
			#  now add the line
			LET err_message = "L61f - Credline INSERT" 
			IF (pr_shipdetl.part_code IS NULL 
			AND pr_shipdetl.desc_text IS NULL 
			AND (pr_shipdetl.line_total_amt = 0 OR 
			pr_shipdetl.line_total_amt IS null)) THEN 
			ELSE 
				INSERT INTO shipdetl VALUES (pr_shipdetl.*) 
			END IF 

			CALL find_taxcode(pr_shipdetl.tax_code) RETURNING tax_idx 
			LET pa_taxamt[tax_idx].duty_ent_amt = pa_taxamt[tax_idx].duty_ent_amt + 
			pr_shipdetl.duty_ext_ent_amt 
			LET check_mat = check_mat + pr_shipdetl.ext_landed_cost 
		END FOR 
		CALL find_taxcode(pr_shiphead.freight_tax_code) RETURNING tax_idx 
		LET pa_taxamt[tax_idx].duty_ent_amt = pa_taxamt[tax_idx].duty_ent_amt + 
		pr_shiphead.freight_tax_amt 
		CALL find_taxcode(pr_shiphead.hand_tax_code) RETURNING tax_idx 
		LET pa_taxamt[tax_idx].duty_ent_amt = pa_taxamt[tax_idx].duty_ent_amt + 
		pr_shiphead.hand_tax_amt 
		LET tax_idx = 1 
		WHILE (tax_idx <= 300) AND (pa_taxamt[tax_idx].tax_code IS NOT null) 
			LET check_tax = check_tax + pa_taxamt[tax_idx].duty_ent_amt 
			LET tax_idx = tax_idx + 1 
		END WHILE 
		IF check_tax != pr_shiphead.duty_ent_amt 
		OR check_tax IS NULL 
		OR pr_shiphead.duty_ent_amt IS NULL THEN 
			ERROR "Audit on tax figures NOT correct" 
			CALL errorlog("L61 - tax total amount incorrect") 
			CALL display_error() 
			LET err_flag = "Y" 
			LET pr_shiphead.duty_ent_amt = check_tax 
		END IF 
		IF check_mat != pr_shiphead.fob_ent_cost_amt 
		OR check_mat IS NULL 
		OR pr_shiphead.fob_ent_cost_amt IS NULL THEN 
			ERROR "Audit on material figures NOT correct" 
			CALL errorlog("L61 - material total amount incorrect") 
			CALL display_error() 
			LET err_flag = "Y" 
			LET pr_shiphead.fob_ent_cost_amt = check_mat 
		END IF 
		LET pr_shiphead.line_num = arr_size 
		# initialise other fields
		IF pr_shiphead.late_cost_amt IS NULL THEN 
			LET pr_shiphead.late_cost_amt = 0 
		END IF 
		IF pr_shiphead.ant_fob_amt IS NULL THEN 
			LET pr_shiphead.ant_fob_amt = 0 
		END IF 
		IF pr_shiphead.ant_duty_amt IS NULL THEN 
			LET pr_shiphead.ant_duty_amt = 0 
		END IF 
		IF pr_shiphead.other_cost_amt IS NULL THEN 
			LET pr_shiphead.other_cost_amt = 0 
		END IF 
		IF pr_shiphead.ant_other_amt IS NULL THEN 
			LET pr_shiphead.ant_other_amt = 0 
		END IF 
		IF pr_shiphead.other_inv_amt IS NULL THEN 
			LET pr_shiphead.other_inv_amt = 0 
		END IF 
		LET err_message = "L61f - Credhead INSERT" 

		INSERT INTO shiphead VALUES (pr_shiphead.*) 

		IF err_flag = "N" THEN 
		COMMIT WORK 
	ELSE 
		ROLLBACK WORK 
		#CALL out_stat()
		EXIT program 
	END IF 


	WHENEVER ERROR stop 
END FUNCTION 


############################################################
# FUNCTION display_error()
#
#
############################################################

FUNCTION display_error() 
	DEFINE 
	ans CHAR(1), 
	runner CHAR(120) 

	LET runner = "echo ' Error Occurred in Shipment Number :", 
	pr_shiphead.ship_code,"'>> ",trim(get_settings_logFile()) 
	RUN runner 
	LET runner = "echo ' Shipment Tax :", 
	pr_shiphead.duty_ent_amt,"'>> ",trim(get_settings_logFile()) 
	RUN runner 
	LET runner = "echo ' Audit Check Tax :",check_tax,"'>> ",trim(get_settings_logFile()) 
	RUN runner 
	LET runner = "echo ' Shipment Materials :", 
	pr_shiphead.fob_ent_cost_amt,"'>> ",trim(get_settings_logFile()) 
	RUN runner 
	LET runner = "echo ' Audit Check Materials :",check_mat,"'>> ",trim(get_settings_logFile()) 
	RUN runner 
	-- albo
	{
	   OPEN WINDOW A21w1 AT 10,10 with 1 rows,30 columns     -- albo  KD-763
	      ATTRIBUTE(border,prompt line last)
	}
	CALL fgl_winmessage(trim(get_settings_logFile()),"An Audit Check Error has Occurred","ERROR") 
	--    prompt  "               Any Key TO Continue" FOR CHAR ans
	CALL eventsuspend() --LET ans = AnyKey(" Any Key TO Continue",13,10) -- albo 
	--   CLOSE WINDOW A21w1    -- albo  KD-763
	----------
	LET int_flag = false 
	LET quit_flag = false 
END FUNCTION 
