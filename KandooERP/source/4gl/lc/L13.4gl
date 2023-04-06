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




{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module L13 allows the user TO Scan CVendor Shipments

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "L_LC_GLOBALS.4gl" 

GLOBALS "L13_GLOBALS.4gl" 

MAIN 
	#Initial UI Init
	CALL setModuleId("L13") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 


	OPEN WINDOW l107 with FORM "L107" 
	CALL windecoration_l("L107") -- albo kd-761 

	WHILE doit() 
	END WHILE 
	CLOSE WINDOW l107 
	LET int_flag = false 
	LET quit_flag = false 
END MAIN 

FUNCTION doit() 
	CLEAR FORM 
	LET msgresp = kandoomsg("U",1001,"") 
	#1001 Enter Selection Criteria;  OK TO Continue.
	CONSTRUCT where_part ON 
	shiphead.ship_code, 
	shiphead.ship_type_code, 
	shiphead.vend_code, 
	shipdetl.part_code, 
	shipdetl.source_doc_num, 
	shiphead.discharge_text, 
	shiphead.ship_status_code 
	FROM sr_shiphead[1].ship_code, 
	sr_shiphead[1].ship_type_code, 
	sr_shiphead[1].vend_code, 
	sr_shiphead[1].part_code, 
	sr_shiphead[1].source_doc_num, 
	sr_shiphead[1].discharge_text, 
	sr_shiphead[1].ship_status_code 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","L13","construct-shiphead-1") -- albo 

		ON ACTION "WEB-HELP" -- albo kd-375 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		RETURN false 
	END IF 

	LET sel_text = 
	"SELECT * ", 
	"FROM shiphead, shipdetl ", 
	" WHERE shiphead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	" AND shipdetl.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	" AND shiphead.ship_code = shipdetl.ship_code AND ", 
	where_part clipped, 
	" ORDER BY shiphead.cmpy_code, shiphead.ship_code " 

	PREPARE getord FROM sel_text 
	DECLARE c_ord CURSOR FOR getord 
	#OPEN c_ord
	LET idx = 0 
	FOREACH c_ord INTO pr_shiphead.*, pr_shipdetl.* 
		LET idx = idx + 1 
		LET pa_shiphead[idx].ship_code = pr_shiphead.ship_code 
		LET pa_shiphead[idx].vend_code = pr_shiphead.vend_code 
		LET pa_shiphead[idx].ship_type_code = pr_shiphead.ship_type_code 
		IF pr_shipdetl.part_code IS NULL THEN 
			LET pa_shiphead[idx].part_code = 
			pr_shipdetl.desc_text[1,15] 
		ELSE 
			LET pa_shiphead[idx].part_code = pr_shipdetl.part_code 
		END IF 
		LET pa_shiphead[idx].source_doc_num = pr_shipdetl.source_doc_num 
		LET pa_shiphead[idx].discharge_text = pr_shiphead.discharge_text 
		LET pa_shiphead[idx].ship_status_code = pr_shiphead.ship_status_code 
		IF idx > 240 THEN 
			EXIT FOREACH 
		END IF 
	END FOREACH 
	IF idx > 0 THEN 
		LET msgresp = kandoomsg("U",9113,idx) 
		# idx records selected.
		CALL set_count (idx) 
		LET msgresp = kandoomsg("A",1551,"") 
		#1551 Enter on line TO View;  OK TO Continue.
		INPUT ARRAY pa_shiphead WITHOUT DEFAULTS FROM sr_shiphead.* 

			ON ACTION "WEB-HELP" -- albo kd-375 
				CALL onlinehelp(getmoduleid(),null) 

			BEFORE ROW 
				LET idx = arr_curr() 
				LET scrn = scr_line() 
				LET pr_shiphead.ship_code = pa_shiphead[idx].ship_code 
				LET pr_shiphead.vend_code = pa_shiphead[idx].vend_code 
				LET pr_shiphead.ship_type_code = pa_shiphead[idx].ship_type_code 
				#LET pr_shiphead.part_code = pa_shiphead[idx].part_code
				#LET pr_shiphead.source_doc_num = pa_shiphead[idx].source_doc_num
				LET pr_shiphead.discharge_text = pa_shiphead[idx].discharge_text 
				LET pr_shiphead.ship_status_code = pa_shiphead[idx].ship_status_code 
				LET id_flag = 0 
				DISPLAY pa_shiphead[idx].* TO sr_shiphead[scrn].* 

			AFTER ROW 
				DISPLAY pa_shiphead[idx].* TO sr_shiphead[scrn].* 

			AFTER FIELD ship_code 
				IF arr_curr() = arr_count() 
				AND fgl_lastkey() = fgl_keyval("down") THEN 
					LET msgresp = kandoomsg("U",9001,"") 
					#9001 There are no more rows in the direction you are ...
					NEXT FIELD ship_code 
				END IF 
			BEFORE FIELD ship_type_code 
				IF pr_shiphead.ship_code IS NULL THEN 
					ERROR " Not a valid shipment" 
				ELSE 
					CALL scanner() 
					NEXT FIELD ship_code 
				END IF 
				NEXT FIELD ship_code 
			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 
	ELSE 
		LET msgresp = kandoomsg("L",9028,"") 
		#9028 There are no Shipments matching the selection criteria.
	END IF 
	RETURN true 
END FUNCTION 


FUNCTION scanner() 
	OPEN WINDOW scanwind with FORM "L105" 
	CALL windecoration_l("L105") -- albo kd-761 
	MESSAGE "" 
	SELECT o.*, c.* 
	INTO pr_shiphead.*, pr_vendor.* 
	FROM shiphead o, vendor c 
	WHERE o.ship_code = pa_shiphead[idx].ship_code 
	AND c.vend_code = pr_shiphead.vend_code 
	AND o.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND c.cmpy_code = glob_rec_kandoouser.cmpy_code 
	DISPLAY BY NAME 
	pr_shiphead.vend_code, 
	pr_vendor.name_text, 
	pr_shiphead.ship_code, 
	pr_shiphead.agent_code, 
	pr_shiphead.vessel_text, 
	pr_shiphead.eta_curr_date, 
	pr_shiphead.origin_port_text, 
	pr_shiphead.vessel_text, 
	pr_shiphead.discharge_text, 
	pr_shiphead.curr_code, 
	pr_shiphead.bl_awb_text, 
	pr_shiphead.ship_status_code, 
	pr_shiphead.container_text, 
	pr_shiphead.ware_code, 
	pr_shiphead.fob_ent_cost_amt, 
	pr_shiphead.duty_ent_amt, 
	pr_shiphead.entry_code, 
	pr_shiphead.entry_date, 
	pr_shiphead.com1_text, 
	pr_shiphead.rev_num, 
	pr_shiphead.com2_text, 
	pr_shiphead.rev_date 


	MENU "Detailed Inquiry" 
		ON ACTION "WEB-HELP" -- albo kd-375 
			CALL onlinehelp(getmoduleid(),null) 
		COMMAND "Lines" "DISPLAY shipment line details" 
			LET func_type = "View Shipment" 
			CALL shipshow(glob_rec_kandoouser.cmpy_code, pr_shiphead.vend_code, 
			pr_shiphead.ship_code, func_type) 
			NEXT option "Exit" 
		COMMAND "Status" "DISPLAY shipment lines STATUS" 
			CALL ship_stat(glob_rec_kandoouser.cmpy_code, pr_shiphead.vend_code, pr_shiphead.ship_code) 
			NEXT option "Exit" 
		COMMAND "Other Costs" "DISPLAY breakdown of other costs" 
			CALL show_shipcost(glob_rec_kandoouser.cmpy_code, pr_shiphead.ship_code) 
			NEXT option "Exit" 
		COMMAND KEY (interrupt, escape, "E") "Exit" "RETURN TO main SCREEN" 
			LET int_flag = 0 
			LET quit_flag = 0 
			EXIT MENU 
		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
	END MENU 
	CLOSE WINDOW scanwind 
	RETURN 
END FUNCTION 
