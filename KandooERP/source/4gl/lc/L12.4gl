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


#Program L12 allows the user TO view Shipment Information

GLOBALS 

	DEFINE pr_shiphead RECORD 
		vend_code LIKE shiphead.vend_code, 
		name_text LIKE vendor.name_text, 
		ship_code LIKE shiphead.ship_code, 
		agent_code LIKE shiphead.agent_code, 
		vessel_text LIKE shiphead.vessel_text, 
		ship_type_code LIKE shiphead.ship_type_code, 
		origin_port_text LIKE shiphead.origin_port_text, 
		eta_curr_date LIKE shiphead.eta_curr_date, 
		discharge_text LIKE shiphead.discharge_text, 
		curr_code LIKE shiphead.curr_code, 
		bl_awb_text LIKE shiphead.bl_awb_text, 
		ship_status_code LIKE shiphead.ship_status_code, 
		container_text LIKE shiphead.container_text, 
		ware_code LIKE shiphead.ware_code, 
		fob_ent_cost_amt LIKE shiphead.fob_ent_cost_amt, 
		duty_ent_amt LIKE shiphead.duty_ent_amt, 
		entry_code LIKE shiphead.entry_code, 
		entry_date LIKE shiphead.entry_date, 
		com1_text LIKE shiphead.com1_text, 
		rev_num LIKE shiphead.rev_num, 
		com2_text LIKE shiphead.com2_text, 
		rev_date LIKE shiphead.rev_date 
	END RECORD 
	DEFINE where_part CHAR(500) 
	DEFINE query_text CHAR(1500) 
--	DEFINE glob_level CHAR(1)
	DEFINE answer CHAR(1)
	DEFINE ans CHAR(1)
	DEFINE pr_rec_kandoouser RECORD LIKE kandoouser.* 
	DEFINE exist SMALLINT 
	DEFINE func_type CHAR(14) 
END GLOBALS 


MAIN 
	#Initial UI Init
	CALL setModuleId("L12") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 


	OPEN WINDOW l105 with FORM "L105" 
	CALL windecoration_l("L105") -- albo kd-761 
	CALL query() 
	CLOSE WINDOW l105 
END MAIN 


FUNCTION select_them() 
	LET exist = false 
	LET msgresp = kandoomsg("U",1001,"") 
	#1001 Enter Selection Criteria;  Oke TO Continue.
	CONSTRUCT where_part ON shiphead.vend_code, 
	vendor.name_text, 
	shiphead.ship_code, 
	shiphead.agent_code, 
	shiphead.vessel_text, 
	shiphead.ship_type_code, 
	shiphead.origin_port_text, 
	shiphead.eta_curr_date, 
	shiphead.discharge_text, 
	shiphead.curr_code, 
	shiphead.bl_awb_text, 
	shiphead.ship_status_code, 
	shiphead.container_text, 
	shiphead.ware_code, 
	shiphead.fob_ent_cost_amt, 
	shiphead.duty_ent_amt, 
	shiphead.entry_code, 
	shiphead.entry_date, 
	shiphead.com1_text, 
	shiphead.rev_num, 
	shiphead.com2_text, 
	shiphead.rev_date 
	FROM shiphead.vend_code, 
	vendor.name_text, 
	shiphead.ship_code, 
	shiphead.agent_code, 
	shiphead.vessel_text, 
	shiphead.ship_type_code, 
	shiphead.origin_port_text, 
	shiphead.eta_curr_date, 
	shiphead.discharge_text, 
	shiphead.curr_code, 
	shiphead.bl_awb_text, 
	shiphead.ship_status_code, 
	shiphead.container_text, 
	shiphead.ware_code, 
	shiphead.fob_ent_cost_amt, 
	shiphead.duty_ent_amt, 
	shiphead.entry_code, 
	shiphead.entry_date, 
	shiphead.com1_text, 
	shiphead.rev_num, 
	shiphead.com2_text, 
	shiphead.rev_date 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","L12","construct-shiphead-1") -- albo 

		ON ACTION "WEB-HELP" -- albo kd-375 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		RETURN false 
	END IF 

	LET query_text = 
	"SELECT shiphead.vend_code, vendor.name_text, ", 
	"shiphead.ship_code, shiphead.agent_code, ", 
	"shiphead.vessel_text, ", 
	"shiphead.ship_type_code, shiphead.origin_port_text, ", 
	"shiphead.eta_curr_date, shiphead.discharge_text,", 
	"shiphead.curr_code, shiphead.bl_awb_text,", 
	"shiphead.ship_status_code, shiphead.container_text,", 
	"shiphead.ware_code, shiphead.fob_ent_cost_amt,", 
	"shiphead.duty_ent_amt, shiphead.entry_code, ", 
	"shiphead.entry_date, shiphead.com1_text, ", 
	"shiphead.rev_num, shiphead.com2_text,", 
	"shiphead.rev_date ", 
	"FROM shiphead, vendor ", 
	"WHERE vendor.vend_code = shiphead.vend_code AND ", 
	" shiphead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	" vendor.cmpy_code = shiphead.cmpy_code AND ", 
	where_part clipped 

	PREPARE statement_1 FROM query_text 
	DECLARE shiphead_set SCROLL CURSOR FOR statement_1 
	OPEN shiphead_set 

	FETCH shiphead_set INTO pr_shiphead.* 
	IF status = notfound THEN 
		RETURN false 
	END IF 
	LET exist = true 
	RETURN true 
END FUNCTION 



FUNCTION query() 
	CLEAR FORM 
	LET exist = false 
	MENU " Shipment Information" 

		ON ACTION "WEB-HELP" -- albo kd-375 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Query" " Search FOR shipment" 
			IF select_them() THEN 
				CALL show_it() 
				NEXT option "Next" 
			ELSE 
				IF int_flag OR quit_flag THEN 
					LET int_flag = false 
					LET quit_flag = false 
				ELSE 
					LET msgresp = kandoomsg("L",9028,"") 
					#9028 No Shipment satisfied the selection criteria.
				END IF 
			END IF 

		COMMAND KEY ("N",f21) "Next" " DISPLAY next selected shipment" 
			IF exist THEN 
				FETCH NEXT shiphead_set INTO pr_shiphead.* 
				IF status <> notfound THEN 
					CALL show_it() 
				ELSE 
					ERROR "You have reached the END of the shipments selected" 
				END IF 
			ELSE 
				ERROR "You have TO make a selection first" 
			END IF 

		COMMAND KEY ("P",f19) "Prev" " DISPLAY previous selected shipment" 
			IF exist THEN 
				FETCH previous shiphead_set INTO pr_shiphead.* 
				IF status <> notfound THEN 
					CALL show_it() 
				ELSE 
					ERROR "You have reached the start of the shipments selected" 
				END IF 
			ELSE 
				ERROR "You have TO make a selection first" 
			END IF 

		COMMAND KEY ("D",f20) "Detail" " View shipment details" 
			IF exist THEN 
				CALL show_detail(glob_rec_kandoouser.cmpy_code, pr_shiphead.vend_code, pr_shiphead.ship_code, 
				func_type) 
			ELSE 
				ERROR "You have TO make a selection first" 
			END IF 

		COMMAND KEY ("F",f18) "First" " DISPLAY first shipment in the selected list" 
			IF exist THEN 
				FETCH FIRST shiphead_set INTO pr_shiphead.* 
				IF status <> notfound THEN 
					CALL show_it() 
				ELSE 
					ERROR "You have reached the start of the shipments selected" 
				END IF 
			ELSE 
				ERROR "You have TO make a selection first" 
			END IF 

		COMMAND KEY ("L",f22) "Last" " DISPLAY last shipments in the selected list" 
			IF exist THEN 
				FETCH LAST shiphead_set INTO pr_shiphead.* 
				IF status <> notfound THEN 
					CALL show_it() 
				ELSE 
					ERROR "You have reached the END of the shipments selected" 
				END IF 
			ELSE 
				ERROR "You have TO make a selection first" 
			END IF 

		COMMAND KEY (interrupt, "E") "Exit" " Exit TO menus" 
			EXIT MENU 
		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
	END MENU 
END FUNCTION 



FUNCTION show_it() 
	DISPLAY BY NAME pr_shiphead.vend_code, 
	pr_shiphead.name_text, 
	pr_shiphead.ship_code, 
	pr_shiphead.agent_code, 
	pr_shiphead.vessel_text, 
	pr_shiphead.ship_type_code, 
	pr_shiphead.origin_port_text, 
	pr_shiphead.eta_curr_date, 
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

END FUNCTION 



FUNCTION show_detail(p_cmpy, passed_vend_code, passed_ship_code, passed_func_type) 
	DEFINE 
	p_cmpy LIKE company.cmpy_code, 
	passed_vend_code LIKE vendor.vend_code, 
	passed_ship_code LIKE shiphead.ship_code, 
	passed_func_type CHAR(1) 

	MENU " Detailed Inquiry" 
		ON ACTION "WEB-HELP" -- albo kd-375 
			CALL onlinehelp(getmoduleid(),null) 
		COMMAND "Lines" " DISPLAY shipment line details" 
			CALL shipshow(p_cmpy, passed_vend_code, 
			passed_ship_code, passed_func_type) 
			NEXT option "Exit" 
		COMMAND "Status" " DISPLAY shipment lines STATUS" 
			CALL ship_stat(p_cmpy, passed_vend_code, passed_ship_code) 
			NEXT option "Exit" 
		COMMAND "Costs" " DISPLAY breakdown of other costs" 
			CALL show_shipcost(p_cmpy, passed_ship_code) 
			NEXT option "Exit" 
		COMMAND KEY (interrupt, "E") "Exit" " RETURN TO main SCREEN" 
			LET int_flag = 0 
			LET quit_flag = 0 
			EXIT MENU 
		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
	END MENU 
	RETURN 
END FUNCTION 
