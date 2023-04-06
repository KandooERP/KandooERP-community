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

	Source code beautified by beautify.pl on 2020-01-02 18:38:32	$Id: $
}




{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module L61  allows the user TO enter Accounts Receivable Credits
#              updating inventory via Shipments, AT confirmation the
#          credit IS created
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "L_LC_GLOBALS.4gl" 

GLOBALS "L61_GLOBALS.4gl" 

MAIN 
	#Initial UI Init
	CALL setModuleId("L61") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	#CREATE TEMP TABLE statab (cmpy CHAR(2),
	#ware CHAR(3),
	#part CHAR(15),
	#ship DECIMAL(12,3),
	#which CHAR(3)) with no log
	LET func_type = "Shipment Entry" 
	LET f_type = "C" 
	LET first_time = 1 
	LET noerror = 1 
	LET display_ship_code = "N" 
	LET ans = "Y" 
	WHILE ans = "Y" 
		#DELETE FROM statab WHERE 1=1
		INITIALIZE pr_shiphead.* TO NULL 
		LET pr_shiphead.fob_curr_cost_amt = 0 
		LET pr_shiphead.fob_inv_cost_amt = 0 
		LET pr_shiphead.fob_ent_cost_amt = 0 
		LET pr_shiphead.total_amt = 0 
		LET pr_shiphead.hand_amt = 0 
		LET pr_shiphead.hand_tax_amt = 0 
		LET pr_shiphead.freight_amt = 0 
		LET pr_shiphead.freight_tax_amt = 0 
		LET pr_shiphead.duty_ent_amt = 0 
		LET pr_shiphead.cost_amt = 0 
		LET pr_shiphead.disc_amt = 0 
		LET pr_shiphead.tax_per = 0 
		INITIALIZE pr_shipdetl.* TO NULL 
		FOR i = 1 TO 300 
			INITIALIZE pa_taxamt[i].tax_code TO NULL 
		END FOR 
		LET noerror = 1 
		LET goon = "Y" 
		LABEL headlab: 
		CALL L61_header() 
		IF ans = "N" THEN 
			# delete OR quit has been hit - need TO back out ps_prodstatus updates
			#CALL out_stat()
			EXIT WHILE 
		END IF 
		LABEL linelab: 
		IF (ans = "Y" AND goon = "Y") 
		OR (ans = "C" AND goon = "Y") THEN 
			CALL lineitem() 
		END IF 
		# on del key go back a SCREEN
		IF ans = "N" 
		OR ans = "C" THEN 
			LET int_flag = 0 
			LET quit_flag = 0 
			IF ans = "N" THEN 
				INITIALIZE pr_shiphead.* TO NULL 
				LET pr_shiphead.fob_curr_cost_amt = 0 
				LET pr_shiphead.fob_inv_cost_amt = 0 
				LET pr_shiphead.fob_ent_cost_amt = 0 
				LET pr_shiphead.total_amt = 0 
				LET pr_shiphead.hand_tax_amt = 0 
				LET pr_shiphead.hand_amt = 0 
				LET pr_shiphead.freight_tax_amt = 0 
				LET pr_shiphead.freight_amt = 0 
				LET pr_shiphead.duty_ent_amt = 0 
				LET pr_shiphead.cost_amt = 0 
				LET pr_shiphead.disc_amt = 0 
				LET pr_shiphead.tax_per = 0 
				LET first_time = 1 
				INITIALIZE pr_shipdetl.* TO NULL 
				#CALL out_stat()
				FOR idx = 1 TO arr_size 
					INITIALIZE st_shipdetl[idx].* TO NULL 
				END FOR 
				FOR i = 1 TO 300 
					INITIALIZE pa_taxamt[i].tax_code TO NULL 
				END FOR 
				LET ans = "Y" 
			END IF 
			GOTO headlab 
		END IF 

		IF ans = "Y" 
		AND goon = "Y" THEN 
			CALL summup() 
		END IF 

		IF ans = "N" THEN 
			LET int_flag = 0 
			LET quit_flag = 0 
			LET ans = "C" 
			GOTO linelab 
		END IF 

		IF ans = "Y" 
		AND goon = "Y" THEN 
			CALL write_credship() 
			IF noerror = 1 THEN 
				FOR i=1 TO arr_size 
					INITIALIZE st_shipdetl[i].* TO NULL 
				END FOR 
				#CALL cred_appl(pr_shiphead.ship_code, glob_rec_kandoouser.sign_on_code)
				LET temp_ship_code = pr_shiphead.ship_code 
				LET display_ship_code = "Y" 
				LET first_time = 1 
			ELSE 
				ROLLBACK WORK 
				{
				            OPEN WINDOW w71 AT 10,4 with 2 rows, 60 columns     -- albo  KD-761
				               ATTRIBUTE(border, reverse)
				}
				MESSAGE "Shipment NOT added, files NOT updated, CALL FOR assistance" 
				SLEEP 5 
				--            CLOSE WINDOW w71      -- albo  KD-763
			END IF 
		END IF 
	END WHILE 
END MAIN 
