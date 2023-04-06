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




{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module L64  allows the user TO edit Credit RETURN Shipments



############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "L_LC_GLOBALS.4gl" 
GLOBALS "L64_GLOBALS.4gl" 

MAIN 

	#Initial UI Init
	CALL setModuleId("L64") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 


	SELECT credit_ref2a_text, 
	credit_ref2b_text 
	INTO pr_arparms.credit_ref2a_text, 
	pr_arparms.credit_ref2b_text 
	FROM arparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 
	LET func_type = "Edit Shipment " 
	LET f_type = "J" 
	LET noerror = 1 
	LET first_time = 1 
	LET display_ship_code = "N" 
	OPEN WINDOW l162 with FORM "L162" 
	CALL windecoration_l("L162") -- albo kd-763 

	LABEL reselect: 
	WHILE cred_ship_select() 
		LET ps_shiphead.* = pr_shiphead.* 
		INITIALIZE pr_shipdetl.* TO NULL 
		FOR i = 1 TO 300 
			INITIALIZE pa_taxamt[i].tax_code TO NULL 
		END FOR 
		LET noerror = 1 
		LET ans = "Y" 
		LET goon = "Y" 
		LABEL headlab: 
		CALL L61_header() 
		IF ans = "N" THEN 
			CONTINUE WHILE 
		END IF 
		LABEL linelab: 
		IF (ans = "Y" AND goon = "Y") 
		OR (ans = "C" AND goon = "Y") THEN 
			CALL lineitem() 
		END IF 
		# on del key go back a SCREEN
		IF ans = "N" 
		OR ans = "C" THEN 
			LET int_flag = false 
			LET quit_flag = false 
			FOR i = 1 TO 300 
				INITIALIZE pa_taxamt[i].tax_code TO NULL 
			END FOR 
			IF ans = "N" THEN 
				LET f_type = "J" 
				LET noerror = 1 
				LET first_time = 1 
				LET display_ship_code = "N" 
				GOTO reselect 
			END IF 
			IF ans = "C" THEN 
				GOTO headlab 
			END IF 
		END IF 
		IF ans = "Y" 
		AND goon = "Y" THEN 
			CALL summup() 
		END IF 
		IF ans = "N" THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET ans = "C" 
			GOTO linelab 
		END IF 
		IF ans = "Y" 
		AND goon = "Y" THEN 
			CALL write_credship() 
			IF noerror = 1 THEN 
				FOR i = 1 TO arr_size 
					INITIALIZE st_shipdetl[i].* TO NULL 
				END FOR 
				LET temp_ship_code = pr_shiphead.ship_code 
				LET display_ship_code = "Y" 
			ELSE ROLLBACK WORK 
				{
				                  OPEN WINDOW w77 AT 10,4 with 2 rows, 60 columns    -- albo  KD-763
				                        ATTRIBUTE(border, reverse)
				}
				MESSAGE "Credit NOT changed, files NOT updated, CALL FOR assistance" 
				SLEEP 5 
				--                  CLOSE WINDOW w77     -- albo  KD-763
			END IF 
		END IF 
		INITIALIZE pr_shipdetl.* TO NULL 
		FOR i = 1 TO 300 
			INITIALIZE pa_taxamt[i].tax_code TO NULL 
		END FOR 
	END WHILE 
	CLOSE WINDOW l162 
END MAIN 

