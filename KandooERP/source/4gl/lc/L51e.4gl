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

	Source code beautified by beautify.pl on 2020-01-02 18:38:31	$Id: $
}




# module L51e - Get shipment summation information

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "L_LC_GLOBALS.4gl" 

GLOBALS "L51_GLOBALS.4gl" 



FUNCTION summup() 
	DEFINE 
	rep CHAR(1), 
	#vouch_code LIKE voucher.vouch_code,
	#vouch_amt, new_vouch_amt LIKE voucher.total_amt,
	#conv_rate LIKE voucher.conv_qty,
	cont_flag CHAR(1) 

	OPEN WINDOW wl104 with FORM "L149" 
	CALL windecoration_l("L149") -- albo kd-761 

	DISPLAY BY NAME pr_shiphead.vend_code, 
	pr_vendor.name_text, 
	pr_shiphead.ship_code, 
	pr_shiphead.ship_type_code, 
	pr_shiphead.eta_curr_date, 
	pr_shiphead.fob_ent_cost_amt, 
	pr_shiphead.curr_code, 
	pr_shiphead.ant_fob_amt, 
	pr_shiphead.bl_awb_text, 
	pr_shiphead.lc_ref_text, 
	pr_shiphead.container_text, 
	pr_shiphead.case_num, 
	pr_shiphead.com1_text, 
	pr_shiphead.entry_code, 
	pr_shiphead.com2_text, 
	pr_shiphead.entry_date 

	LET ret_flag = 0 
	LET cont_flag = "N" 
	WHILE true 
		LET cont_flag = "N" 
		INPUT BY NAME 
		pr_shiphead.bl_awb_text, 
		pr_shiphead.lc_ref_text, 
		pr_shiphead.container_text, 
		pr_shiphead.case_num, 
		pr_shiphead.com1_text, 
		pr_shiphead.com2_text WITHOUT DEFAULTS 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","L51e","input-bl_awb_text-1") -- albo 

			ON ACTION "WEB-HELP" -- albo kd-375 
				CALL onlinehelp(getmoduleid(),null) 

			AFTER INPUT 
				IF int_flag OR quit_flag THEN ELSE 
					IF pr_shiphead.ant_fob_amt != pr_shiphead.fob_ent_cost_amt THEN 
						{  -- albo
						            WHILE TRUE
						               ERROR " "
						               prompt "Warning: FOB does NOT equal expected total. Continue?  "
						               FOR CHAR rep
						               LET rep = upshift(rep)
						               IF rep = "Y" OR rep = "N" THEN
						                  EXIT WHILE
						               ELSE
						                  ERROR "Continue? Y OR N"
						               END IF
						            END WHILE
						}
						LET rep = promptYN("","Warning: FOB does NOT equal expected total. Continue? ","Y") -- albo 
						LET rep = upshift(rep) 
						IF rep = "N" THEN 
							NEXT FIELD bl_awb_text 
						END IF 
						IF int_flag OR quit_flag 
						THEN # del hit 
							LET int_flag = 0 
							LET quit_flag = 0 
							LET cont_flag = "Y" 
						ELSE 
							LET cont_flag = "N" 
						END IF 
					END IF 
				END IF 
			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 
		IF cont_flag = "Y" THEN 
			CONTINUE WHILE 
		ELSE 
			EXIT WHILE 
		END IF 
		IF int_flag != 0 
		OR quit_flag != 0 THEN 
			EXIT WHILE 
		END IF 
	END WHILE 
	CLOSE WINDOW wl104 

	IF int_flag != 0 
	OR quit_flag != 0 THEN 
		LET int_flag = 0 
		LET quit_flag = 0 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 
