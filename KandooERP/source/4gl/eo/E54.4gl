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
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../eo/E_EO_GLOBALS.4gl"
GLOBALS "../eo/E5_GROUP_GLOBALS.4gl"
GLOBALS "../eo/E52_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################
--DEFINE modu_output char(30) 
###########################################################################
# FUNCTION E54_main()
#
# E54 - Generating AND/OR printing consignment notes program.
#       Provides front END TO generate_ AND prepare_ (E54a.4gl).
###########################################################################
FUNCTION E54_main()
	DEFINE l_where_text STRING --char(200) 
	DEFINE l_rec_despatchhead RECORD LIKE despatchhead.* 
	DEFINE l_next_consign LIKE carrier.next_consign 
	DEFINE l_last_consign LIKE carrier.last_consign 
	DEFINE l_temp_text char(30) 
	DEFINE i SMALLINT 

	CALL setModuleId("E54") -- albo 
	CALL init_E5_GROUP()
	
	OPEN WINDOW E156 with FORM "E156" 
	 CALL windecoration_e("E156") -- albo kd-755 

	DECLARE c_despatchhead cursor FOR 
	SELECT * FROM despatchhead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	ORDER BY despatch_date desc,	ware_code,	carrier_code,	manifest_num desc 
	OPEN c_despatchhead
	 
	FOR i = 1 TO 13 
		FETCH c_despatchhead INTO l_rec_despatchhead.* 
		IF sqlca.sqlcode = 0 THEN 
			SELECT name_text INTO l_temp_text 
			FROM carrier 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND carrier_code = l_rec_despatchhead.carrier_code 

			DISPLAY 
				"", 
				l_rec_despatchhead.despatch_date, 
				l_rec_despatchhead.ware_code, 
				l_rec_despatchhead.carrier_code, 
				l_temp_text, 
				l_rec_despatchhead.manifest_num 
			TO sr_despatchhead[i].*
		END IF 
	END FOR
	 
	MENU " Consignment notes" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","E54","menu-Consignment_Notes-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "LIST SHIPMENTS" " Scroll through selected shipments" 
			SELECT count(*) 
			INTO i FROM despatchhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

			IF i < glob_rec_settings.maxListArraySize THEN 
				CALL scan_shipments("1=1") 
			ELSE 
				CALL scan_shipments(select_shipments()) 
			END IF 

		COMMAND "SINGLE CONSIGNMENT NOTE" " Generate single consignment note" 
			CALL select_s_criteria() 

		COMMAND "MULTIPLE CONSIGNMENT NOTES" " SELECT criteria AND generate consignment notes" 
			CALL select_criteria() 


		ON ACTION "PRINT MANAGER" #COMMAND KEY ("P",f11) "Print"    " Print OR view using RMS"
			CALL run_prog("URS","","","","") 

		ON ACTION "CANCEL" #COMMAND KEY(INTERRUPT,"E")"Exit" " Exit TO menus" 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			EXIT MENU 

	END MENU 

	CLOSE WINDOW E156 
END FUNCTION 
###########################################################################
# END FUNCTION E54_main()
###########################################################################


###########################################################################
# FUNCTION select_shipments()
#
#
###########################################################################
FUNCTION select_shipments() 
	DEFINE l_where_text STRING --char(200) 

	CLEAR FORM 
	MESSAGE kandoomsg2("E",1001,"")	#1001 " Enter Selection Criteria - ESC TO Continue "

	CONSTRUCT BY NAME l_where_text ON 
		despatch_date, 
		ware_code, 
		carrier_code, 
		manifest_num 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","E54","construct-despatch_date-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN "" 
	ELSE 
		RETURN l_where_text 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION select_shipments()
###########################################################################


###########################################################################
# FUNCTION scan_shipments(p_where_text)
#
#
###########################################################################
FUNCTION scan_shipments(p_where_text) 
	DEFINE p_where_text STRING
	DEFINE l_rec_despatchhead RECORD LIKE despatchhead.* 
	DEFINE l_rec_despatchdetl RECORD LIKE despatchdetl.* 
	DEFINE l_arr_rec_despatchhead DYNAMIC ARRAY OF RECORD --array[200] OF RECORD 
		scroll_flag char(1), 
		despatch_date LIKE despatchhead.despatch_date, 
		ware_code LIKE despatchhead.ware_code, 
		carrier_code LIKE despatchhead.carrier_code, 
		name_text LIKE carrier.name_text, 
		manifest_num LIKE despatchhead.manifest_num 
	END RECORD 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_rec_carrier RECORD LIKE carrier.* 
	DEFINE l_scroll_flag char(1) 
	DEFINE l_query_text char(300) 
	DEFINE l_rpt_note char(60) 
	DEFINE i SMALLINT 
	DEFINE l_idx SMALLINT 

	IF p_where_text IS NULL THEN 
		RETURN 
	END IF 
	MESSAGE kandoomsg2("E",1002,"") #1002 " Searching database - please wait "
	LET 
		l_query_text = "SELECT * ", 
		"FROM despatchhead ", 
		"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND ",p_where_text clipped," ", 
		"ORDER BY despatch_date desc,", 
		"ware_code,", 
		"carrier_code,", 
		"manifest_num desc" 
	
	LET l_idx = 0 
	PREPARE s_despatchhead FROM l_query_text 
	DECLARE c1_despatchhead cursor FOR s_despatchhead 
	FOREACH c1_despatchhead INTO l_rec_despatchhead.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_despatchhead[l_idx].scroll_flag = NULL 
		LET l_arr_rec_despatchhead[l_idx].despatch_date = l_rec_despatchhead.despatch_date 
		LET l_arr_rec_despatchhead[l_idx].ware_code = l_rec_despatchhead.ware_code 
		LET l_arr_rec_despatchhead[l_idx].carrier_code = l_rec_despatchhead.carrier_code 

		SELECT name_text 
		INTO l_arr_rec_despatchhead[l_idx].name_text 
		FROM carrier 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND carrier_code = l_rec_despatchhead.carrier_code 

		LET l_arr_rec_despatchhead[l_idx].manifest_num = l_rec_despatchhead.manifest_num 

	END FOREACH 
	IF l_idx = 0 THEN 
		ERROR kandoomsg2("E",9128,"") 	#9128 No shipments satisfied selection criteria "
	ELSE 
		OPTIONS DELETE KEY f36, 
		INSERT KEY f36 

		MESSAGE kandoomsg2("E",1034,"") #1034 RETURN on line TO View - F9 TO Reprint
		INPUT ARRAY l_arr_rec_despatchhead WITHOUT DEFAULTS FROM sr_despatchhead.* 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","E54","input-arr-l_arr_rec_despatchhead-1") -- albo kd-502 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			BEFORE FIELD scroll_flag 
				LET l_idx = arr_curr() 

				LET l_scroll_flag = l_arr_rec_despatchhead[l_idx].scroll_flag 

			AFTER FIELD scroll_flag 
				LET l_arr_rec_despatchhead[l_idx].scroll_flag = l_scroll_flag 

				IF fgl_lastkey() = fgl_keyval("down")	AND arr_curr() >= arr_count() THEN 
					ERROR kandoomsg2("E",9001,"") 
					NEXT FIELD scroll_flag 
				END IF 
				
			BEFORE FIELD despatch_date 
				OPEN WINDOW e157 with FORM "E157" 
				 CALL windecoration_e("E157") -- albo kd-755 
				SELECT * INTO l_rec_despatchhead.* 
				FROM despatchhead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND carrier_code = l_arr_rec_despatchhead[l_idx].carrier_code 
				AND manifest_num = l_arr_rec_despatchhead[l_idx].manifest_num 
				SELECT * 
				INTO l_rec_warehouse.* 
				FROM warehouse 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = l_rec_despatchhead.ware_code 
				SELECT * 
				INTO l_rec_carrier.* 
				FROM carrier 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND carrier_code = l_rec_despatchhead.carrier_code 
				DISPLAY BY NAME l_rec_despatchhead.carrier_code, 
				l_rec_carrier.name_text, 
				l_rec_despatchhead.ware_code, 
				l_rec_warehouse.desc_text, 
				l_rec_despatchhead.manifest_num, 
				l_rec_despatchhead.com1_text, 
				l_rec_despatchhead.com2_text, 
				l_rec_despatchhead.despatch_date, 
				l_rec_despatchhead.despatch_time, 
				l_rec_despatchhead.amend_code 

				SELECT count(*) 
				INTO i FROM despatchdetl 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND carrier_code = l_arr_rec_despatchhead[l_idx].carrier_code 
				AND manifest_num = l_arr_rec_despatchhead[l_idx].manifest_num 
				IF i < 30 THEN 
					CALL scan_despdetls("1=1",l_rec_despatchhead.*) 
				ELSE 
					CALL scan_despdetls(select_despdetls(),l_rec_despatchhead.*) 
				END IF 
				CLOSE WINDOW e157 
				NEXT FIELD scroll_flag 
				

			ON KEY (f9) 
				CALL prepare_connote(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code, 
				l_arr_rec_despatchhead[l_idx].carrier_code, 
				l_arr_rec_despatchhead[l_idx].ware_code, 
				l_arr_rec_despatchhead[l_idx].manifest_num, 
				"","",TRUE) #returns TRUE/FALSE 

		END INPUT 
		
		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
		END IF 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION scan_shipments(p_where_text)
###########################################################################


###########################################################################
# FUNCTION select_despdetls() 
#
#
###########################################################################
FUNCTION select_despdetls() 
	DEFINE l_where_text char(300) 

	MESSAGE kandoomsg2("E",1001,"") #1001 " Enter Selection Criteria - ESC TO Continue "
	CONSTRUCT BY NAME l_where_text ON 
		invoice_num, 
		despatch_code, 
		nett_wgt_qty, 
		gross_wgt_qty, 
		nett_cubic_qty, 
		gross_cubic_qty, 
		despatch_qty 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","E54","construct-invoice_num-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN "" 
	ELSE 
		RETURN l_where_text 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION select_despdetls() 
###########################################################################


###########################################################################
# FUNCTION scan_despdetls(l_where_text,l_rec_despatchhead) 
#
#
###########################################################################
FUNCTION scan_despdetls(l_where_text,l_rec_despatchhead) 
	DEFINE l_where_text STRING 
	DEFINE l_query_text STRING 
	DEFINE l_rec_despatchhead RECORD LIKE despatchhead.* 
	DEFINE l_rec_despatchdetl RECORD LIKE despatchdetl.* 
	DEFINE l_arr_rec_despatchdetl DYNAMIC ARRAY OF RECORD --array[200] OF RECORD 
		scroll_flag char(1), 
		invoice_num LIKE despatchdetl.invoice_num, 
		despatch_code LIKE despatchdetl.despatch_code, 
		nett_wgt_qty LIKE despatchdetl.nett_wgt_qty, 
		gross_wgt_qty LIKE despatchdetl.gross_wgt_qty, 
		nett_cubic_qty LIKE despatchdetl.nett_cubic_qty, 
		gross_cubic_qty LIKE despatchdetl.gross_cubic_qty, 
		despatch_qty LIKE despatchdetl.despatch_qty 
	END RECORD 
	DEFINE l_scroll_flag char(1) 
	DEFINE i SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_del_qty SMALLINT 

	IF l_where_text IS NULL THEN 
		RETURN 
	END IF 
	ERROR kandoomsg2("E",1002,"") #1002 " Searching database - please wait "
	LET l_query_text = 
	"SELECT * ", 
	"FROM despatchdetl ", 
	"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND carrier_code = \"",l_rec_despatchhead.carrier_code,"\" ", 
	"AND manifest_num = \"",l_rec_despatchhead.manifest_num,"\" ", 
	"AND ",l_where_text clipped," ", 
	"ORDER BY invoice_num" 
	PREPARE s_despatchdetl FROM l_query_text 
	DECLARE c_despatchdetl cursor FOR s_despatchdetl 
	LET l_idx = 0 

	FOREACH c_despatchdetl INTO l_rec_despatchdetl.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_despatchdetl[l_idx].scroll_flag = NULL 
		LET l_arr_rec_despatchdetl[l_idx].invoice_num = l_rec_despatchdetl.invoice_num 
		LET l_arr_rec_despatchdetl[l_idx].nett_wgt_qty = l_rec_despatchdetl.nett_wgt_qty 
		LET l_arr_rec_despatchdetl[l_idx].gross_wgt_qty = l_rec_despatchdetl.gross_wgt_qty 
		LET l_arr_rec_despatchdetl[l_idx].nett_cubic_qty = l_rec_despatchdetl.nett_cubic_qty 
		LET l_arr_rec_despatchdetl[l_idx].gross_cubic_qty = l_rec_despatchdetl.gross_cubic_qty 
		LET l_arr_rec_despatchdetl[l_idx].despatch_qty = l_rec_despatchdetl.despatch_qty 
		LET l_arr_rec_despatchdetl[l_idx].despatch_code = l_rec_despatchdetl.despatch_code 
	END FOREACH 
	
 
	IF l_idx = 0 THEN 
		ERROR kandoomsg2("E",9142,"") 	#9142 No consignment notes satisfied selection criteria "
	ELSE 
		MESSAGE kandoomsg2("E",1036,"") 		#1036 F2 TO Delete - RETURN on line TO edit - F9 Reprint
	END IF 
	
	OPTIONS DELETE KEY f36, 
	INSERT KEY f36 

	INPUT ARRAY l_arr_rec_despatchdetl WITHOUT DEFAULTS FROM sr_despatchdetl.* ATTRIBUTE(UNBUFFERED,insert row = false, append row = false, delete row = false, auto append = false) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","E54","input-arr-l_arr_rec_despatchdetl-1") -- albo kd-502 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (f9) 
			--LET modu_output = 
			CALL prepare_connote(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code, 
			l_rec_despatchhead.carrier_code, 
			"", 
			l_rec_despatchhead.manifest_num, 
			l_arr_rec_despatchdetl[l_idx].invoice_num, 
			l_arr_rec_despatchdetl[l_idx].despatch_code, 
			FALSE) #returns TRUE/FALSE  

			MESSAGE kandoomsg2("E",2001,l_arr_rec_despatchdetl[l_idx].invoice_num) 		#2001 Consingment note FOR -invoice_num- reprinted
			SLEEP 2
			MESSAGE kandoomsg2("E",1036,"") #1036 F2 TO Delete - RETURN on line TO edit - F9 Reprint

		BEFORE FIELD scroll_flag 
			LET l_idx = arr_curr() 

			LET l_scroll_flag = l_arr_rec_despatchdetl[l_idx].scroll_flag 
			
		AFTER FIELD scroll_flag 
			LET l_arr_rec_despatchdetl[l_idx].scroll_flag = l_scroll_flag 

			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF (l_arr_rec_despatchdetl[l_idx+1].invoice_num IS NULL AND 
				l_arr_rec_despatchdetl[l_idx+1].despatch_code IS NULL ) 
				OR arr_curr() >= arr_count() THEN 
					ERROR kandoomsg2("E",9001,"") 			# 9001 There are no more rows in the direction you are going
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
			
		AFTER FIELD nett_wgt_qty 
			IF l_arr_rec_despatchdetl[l_idx].nett_wgt_qty IS NULL THEN 
				ERROR kandoomsg2("E",9129,"") 			#9129 Weight must be entered
				NEXT FIELD nett_wgt_qty 
			END IF 
			IF l_arr_rec_despatchdetl[l_idx].nett_wgt_qty < 0 THEN 
				ERROR kandoomsg2("E",9130,"") 			#9130 Weight may NOT be negative
				NEXT FIELD nett_wgt_qty 
			END IF 
			
		AFTER FIELD gross_wgt_qty 
			IF l_arr_rec_despatchdetl[l_idx].gross_wgt_qty IS NULL THEN 
				ERROR kandoomsg2("E",9129,"") 			#9129 Weight must be entered
				NEXT FIELD gross_wgt_qty 
			END IF 
			IF l_arr_rec_despatchdetl[l_idx].gross_wgt_qty < 0 THEN 
				ERROR kandoomsg2("E",9130,"") 			#9130 Weight may NOT be negative
				NEXT FIELD gross_wgt_qty 
			END IF 
			
		AFTER FIELD nett_cubic_qty 
			IF l_arr_rec_despatchdetl[l_idx].nett_cubic_qty IS NULL THEN 
				ERROR kandoomsg2("E",9131,"") 			#9131 Volume must be entered
				NEXT FIELD nett_cubic_qty 
			END IF 
			IF l_arr_rec_despatchdetl[l_idx].nett_cubic_qty < 0 THEN 
				ERROR kandoomsg2("E",9132,"") 			#9132 Volume may NOT be negative
				NEXT FIELD nett_cubic_qty 
			END IF 
			
		AFTER FIELD gross_cubic_qty 
			IF l_arr_rec_despatchdetl[l_idx].gross_cubic_qty IS NULL THEN 
				ERROR kandoomsg2("E",9131,"") 			#9131 Volume must be entered
				NEXT FIELD gross_cubic_qty 
			END IF 
			IF l_arr_rec_despatchdetl[l_idx].gross_cubic_qty < 0 THEN 
				ERROR kandoomsg2("E",9132,"") 			#9132 Volume may NOT be negative
				NEXT FIELD gross_cubic_qty 
			END IF 
			
		AFTER FIELD despatch_qty 
			IF l_arr_rec_despatchdetl[l_idx].despatch_qty IS NULL THEN 
				ERROR kandoomsg2("E",9133,"") 			#9133 Quantity must be entered
				NEXT FIELD despatch_qty 
			END IF 
			IF l_arr_rec_despatchdetl[l_idx].despatch_qty < 0 THEN 
				ERROR kandoomsg2("E",9134,"") 			#9134 Quantity may NOT be negative
				NEXT FIELD despatch_qty 
			END IF 
			IF l_arr_rec_despatchdetl[l_idx+1].invoice_num IS NULL 
			OR arr_curr() >= arr_count() THEN 
				NEXT FIELD scroll_flag 
			END IF 
			


		ON KEY (f2) 
			IF l_arr_rec_despatchdetl[l_idx].scroll_flag IS NULL THEN 
				LET l_arr_rec_despatchdetl[l_idx].scroll_flag = "*" 
				LET l_del_qty = l_del_qty + 1 
			ELSE 
				LET l_arr_rec_despatchdetl[l_idx].scroll_flag = NULL 
				LET l_del_qty = l_del_qty - 1 
			END IF 
			NEXT FIELD scroll_flag 

	END INPUT 
	
	IF not(int_flag OR quit_flag) THEN 
		FOR l_idx = 1 TO arr_count() 
			UPDATE despatchdetl 
			SET nett_wgt_qty = l_arr_rec_despatchdetl[l_idx].nett_wgt_qty, 
			gross_wgt_qty = l_arr_rec_despatchdetl[l_idx].gross_wgt_qty, 
			nett_cubic_qty = l_arr_rec_despatchdetl[l_idx].nett_cubic_qty, 
			gross_cubic_qty = l_arr_rec_despatchdetl[l_idx].gross_cubic_qty, 
			despatch_qty = l_arr_rec_despatchdetl[l_idx].despatch_qty 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND carrier_code = l_rec_despatchhead.carrier_code 
			AND manifest_num = l_rec_despatchhead.manifest_num 
			AND despatch_code = l_arr_rec_despatchdetl[l_idx].despatch_code 
			# AND invoice_num = l_arr_rec_despatchdetl[l_idx].invoice_num
		END FOR 
		IF l_del_qty != 0 THEN 
			IF promptTF("Delete",kandoomsg2("E",8004,""),1) THEN  	#8004 Confirmation TO Delete ",l_del_qty,"Consignment Note(s)? (Y/N)"
				FOR l_idx = 1 TO arr_count() 
					IF l_arr_rec_despatchdetl[l_idx].scroll_flag = "*" THEN 
						DELETE FROM despatchdetl 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND carrier_code = l_rec_despatchhead.carrier_code 
						AND manifest_num = l_rec_despatchhead.manifest_num 
						AND despatch_code = l_arr_rec_despatchdetl[l_idx].despatch_code 
						#  AND invoice_num = l_arr_rec_despatchdetl[l_idx].invoice_num
						UPDATE invoicehead 
						SET manifest_num = NULL 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND inv_num = l_arr_rec_despatchdetl[l_idx].invoice_num 
					END IF 
				END FOR 
			END IF 
		END IF 
	ELSE 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION scan_despdetls(l_where_text,l_rec_despatchhead) 
###########################################################################


###########################################################################
# FUNCTION select_criteria() 
#
#
###########################################################################
FUNCTION select_criteria() 
	DEFINE l_where_text char(100) 
	DEFINE l_rec_carrier RECORD LIKE carrier.* 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_rec_despatchhead RECORD LIKE despatchhead.* 
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_next_consign LIKE carrier.next_consign 
	DEFINE l_temp_text char(10) 

	OPEN WINDOW E158 with FORM "E158" 
	 CALL windecoration_e("E158") -- albo kd-755 

	INITIALIZE l_rec_despatchhead.* TO NULL 
	LET l_rec_despatchhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET l_rec_despatchhead.despatch_date = today 
	LET l_rec_despatchhead.despatch_time = time 
	LET l_rec_despatchhead.amend_code = glob_rec_kandoouser.sign_on_code 
	LET l_rec_despatchhead.amend_date = today 

	MESSAGE kandoomsg2("E",1040,"") #1040 " Enter shipment details - F9 Set consign. note - ESC TO Continue
	INPUT BY NAME 
		l_rec_despatchhead.ware_code, 
		l_rec_despatchhead.carrier_code, 
		l_rec_despatchhead.com1_text, 
		l_rec_despatchhead.com2_text, 
		l_rec_despatchhead.despatch_date, 
		l_rec_despatchhead.despatch_time WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","E54","input-arr-l_rec_despatchhead-1") -- albo kd-502 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (f9) 
			IF l_rec_carrier.carrier_code IS NOT NULL THEN 
				CALL set_connote_num(l_rec_carrier.*) 
				RETURNING l_rec_carrier.next_consign,	l_rec_carrier.last_consign 
				DISPLAY l_rec_carrier.next_consign TO next_consign
				DISPLAY l_rec_carrier.last_consign TO last_consign

			END IF 
			
		ON ACTION "LOOKUP" infield(ware_code) 
					LET l_temp_text = show_ware(glob_rec_kandoouser.cmpy_code) 
					IF l_temp_text IS NOT NULL THEN 
						LET l_rec_despatchhead.ware_code = l_temp_text 
						NEXT FIELD ware_code 
					END IF 
					
		ON ACTION "LOOKUP" infield(carrier_code) 
					LET l_temp_text = show_carrier(glob_rec_kandoouser.cmpy_code,"") 
					IF l_temp_text IS NOT NULL THEN 
						LET l_rec_despatchhead.carrier_code = l_temp_text 
						NEXT FIELD carrier_code 
					END IF 
 
		AFTER FIELD ware_code 
			SELECT * 
			INTO l_rec_warehouse.* 
			FROM warehouse 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ware_code = l_rec_despatchhead.ware_code 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("E",9047,"") 				#9047 Warehouse does NOT exist - Try Window
				NEXT FIELD ware_code 
			END IF 
			DISPLAY BY NAME l_rec_warehouse.desc_text 

		AFTER FIELD carrier_code 
			SELECT * 
			INTO l_rec_carrier.* 
			FROM carrier 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND carrier_code = l_rec_despatchhead.carrier_code 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("E",9140,"") 				#9140 Carrier does NOT exist - Try Window
				NEXT FIELD carrier_code 
			END IF 
			DISPLAY BY NAME l_rec_carrier.name_text, 
			l_rec_carrier.next_consign, 
			l_rec_carrier.last_consign 

		AFTER FIELD despatch_date 
			IF l_rec_despatchhead.despatch_date IS NULL THEN 
				ERROR kandoomsg2("E",9152,"") 				#9152 Shippping date must be entered
				NEXT FIELD despatch_date 
			END IF
			 
		AFTER FIELD despatch_time 
			IF l_rec_despatchhead.despatch_time IS NULL THEN 
				ERROR kandoomsg2("E",9153,"") 				#9153 Shippping time must be entered
				NEXT FIELD despatch_time 
			END IF 
			IF l_rec_despatchhead.despatch_time[1,2] < "00" 
			OR l_rec_despatchhead.despatch_time[1,2] > "24" THEN 
				ERROR kandoomsg2("E",9138,"") 				# 9138 An hour should have a value between 00 AND 24
				NEXT FIELD despatch_time 
			END IF 

			IF l_rec_despatchhead.despatch_time[4,5] < "00" 
			OR l_rec_despatchhead.despatch_time[4,5] > "60" THEN 
				ERROR kandoomsg2("E",9139,"") 			# 9139 A minute should have a value between 00 AND 60
				NEXT FIELD despatch_time 
			END IF 
			IF l_rec_despatchhead.despatch_time[3,3] != ":" THEN 
				LET l_rec_despatchhead.despatch_time[3,3] = ":" 
				DISPLAY BY NAME l_rec_despatchhead.despatch_time 

			END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				SELECT unique 1 
				FROM carrier 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND carrier_code = l_rec_carrier.carrier_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("E",9140,"") 					#9140 Carrier does NOT exist - Try Window
					NEXT FIELD carrier_code 
				END IF 
				IF l_rec_carrier.next_consign IS NULL THEN 
					ERROR kandoomsg2("E",9099,"") 				#9099 Consigment note must be entered
					LET l_rec_carrier.next_consign = 0 
					NEXT FIELD carrier_code 
				END IF 
				IF l_rec_despatchhead.despatch_date IS NULL THEN 
					ERROR kandoomsg2("E",9152,"") 				#9152 Shippping date must be entered
					NEXT FIELD despatch_date 
				END IF 
				IF l_rec_despatchhead.despatch_time IS NULL THEN 
					ERROR kandoomsg2("E",9153,"") 				#9153 Shippping time must be entered
					NEXT FIELD despatch_time 
				END IF 
				IF l_rec_despatchhead.despatch_time[1,2] < "00" 
				OR l_rec_despatchhead.despatch_time[1,2] > "24" THEN 
					ERROR kandoomsg2("E",9138,"") 				# 9138 An hour should have a vale between 00 AND 24
					NEXT FIELD despatch_time 
				END IF 
				IF l_rec_despatchhead.despatch_time[4,5] < "00" 
				OR l_rec_despatchhead.despatch_time[4,5] > "60" THEN 
					ERROR kandoomsg2("E",9139,"") 				# 9139 A minute should have a value between 00 AND 60
					NEXT FIELD despatch_time 
				END IF 

				MESSAGE kandoomsg2("E",1042,"") 			#1042 Enter selection criteria - F9 Set up cons.note - ESC Continue
				CONSTRUCT BY NAME l_where_text ON cust_code, 
				inv_num, 
				inv_date 

					BEFORE CONSTRUCT 
						CALL publish_toolbar("kandoo","E54","construct-cust_code-1")  

					ON ACTION "WEB-HELP" 
						CALL onlinehelp(getmoduleid(),null) 

					ON ACTION "actToolbarManager" 
						CALL setuptoolbar()
				
					ON ACTION "Consignment Number" --ON KEY (f9) 
						IF l_rec_carrier.carrier_code IS NOT NULL THEN 
							CALL set_connote_num(l_rec_carrier.*) 
							RETURNING 
								l_rec_carrier.next_consign, 
								l_rec_carrier.last_consign 
							DISPLAY BY NAME 
								l_rec_carrier.next_consign, 
								l_rec_carrier.last_consign 

						END IF 
				END CONSTRUCT 

				IF not(int_flag OR quit_flag) THEN
					IF NOT promptTF("Consigment Generator",kandoomsg2("E",8017,""),1) THEN 				#8017 Generate Consignment notes (Y/N)?
						MESSAGE kandoomsg2("E",1040,"") 
						CONTINUE INPUT
					END IF 
				END IF 
			END IF 

	END INPUT
	 
	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
	ELSE 
		MESSAGE kandoomsg2("E",1035,"") 	#1035 Generating consignment notes - Please wait
		CALL create_temp_tables() 
		IF generate_connote(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,l_where_text,l_rec_despatchhead.*, 
		"",TRUE,TRUE) THEN 
			--LET modu_output = 
			CALL prepare_connote(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code, 
			l_rec_despatchhead.carrier_code, 
			l_rec_despatchhead.ware_code, 
			l_rec_carrier.next_manifest,"","",TRUE) #returns TRUE/FALSE  
		END IF 
		CALL drop_temp_tables() 
	END IF
	 
	CLOSE WINDOW E158
	 
END FUNCTION 
###########################################################################
# END FUNCTION select_criteria() 
###########################################################################


###########################################################################
# FUNCTION select_criteria() 
#
# Create the temporary tables FOR the connote processing
###########################################################################
FUNCTION create_temp_tables() 

	CREATE temp TABLE tmp_danger 
	( dg_code char(8), 
	nett_wgt_qty FLOAT, 
	nett_cubic_qty FLOAT, 
	despatch_qty FLOAT 
	) 

	CREATE temp TABLE tmp_carry 
	( main_dg_code char(8), 
	carry_dg_code char(8) 
	) 
END FUNCTION 
###########################################################################
# END FUNCTION select_criteria() 
###########################################################################


###########################################################################
# FUNCTION drop_temp_tables() 
#
# Drop the temporary tables used in connote processing
###########################################################################
FUNCTION drop_temp_tables() 
	DROP TABLE tmp_danger 
	DROP TABLE tmp_carry 
END FUNCTION 
###########################################################################
# END FUNCTION drop_temp_tables() 
###########################################################################


###########################################################################
# FUNCTION select_s_criteria() 
#
# 
###########################################################################
FUNCTION select_s_criteria() 
	DEFINE l_where_text STRING --char(100) 
	DEFINE l_rec_carrier RECORD LIKE carrier.* 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_rec_despatchhead RECORD LIKE despatchhead.* 
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_next_consign LIKE carrier.next_consign 
	DEFINE l_temp_text char(10) 

	OPEN WINDOW E163 with FORM "E163" 
	 CALL windecoration_e("E163") -- albo kd-755 

	INITIALIZE l_rec_despatchhead.* TO NULL 
	LET l_rec_despatchhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET l_rec_despatchhead.despatch_date = today 
	LET l_rec_despatchhead.despatch_time = time 
	LET l_rec_despatchhead.amend_code = glob_rec_kandoouser.sign_on_code 
	LET l_rec_despatchhead.amend_date = today 

	MESSAGE kandoomsg2("E",1039,"") #1039 " Enter consingment note details - ESC TO Continue "
	INPUT BY NAME 
		l_rec_invoicehead.inv_num, 
		l_rec_despatchhead.com1_text, 
		l_rec_despatchhead.com2_text, 
		l_rec_despatchhead.despatch_date, 
		l_rec_despatchhead.despatch_time, 
		l_rec_carrier.next_consign WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","E54","input-l_rec_invoicehead-1") -- albo kd-502 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar()
				
		AFTER FIELD inv_num 
			SELECT * 
			INTO l_rec_invoicehead.* 
			FROM invoicehead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND manifest_num IS NULL 
			AND inv_ind = "6" 
			AND inv_num = l_rec_invoicehead.inv_num 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("E",9151,"") 			#9151 This invoice IS NOT valid
				NEXT FIELD inv_num 
			END IF 

			SELECT * 
			INTO l_rec_carrier.* 
			FROM carrier 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND carrier_code = l_rec_invoicehead.carrier_code 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("E",9140,"") 		#9140 Carrier does NOT exist - Try Window
				NEXT FIELD inv_num 
			END IF 

			DISPLAY BY NAME 
				l_rec_carrier.carrier_code, 
				l_rec_carrier.name_text 

			LET l_rec_carrier.next_consign = NULL 

			DISPLAY BY NAME l_rec_carrier.next_consign 

			SELECT distinct id.ware_code 
			INTO l_rec_despatchhead.ware_code 
			FROM invoicedetl id, product pr 
			WHERE id.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND pr.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND id.inv_num = l_rec_invoicehead.inv_num 
			AND id.part_code = pr.part_code 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("E",9154,"") 	#9154 This invoice does NOT have deliverable products
				NEXT FIELD inv_num 
			END IF 

			SELECT * 
			INTO l_rec_warehouse.* 
			FROM warehouse 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ware_code = l_rec_despatchhead.ware_code 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("E",9047,"") 	#9047 Warehouse does NOT exist - Try Window
				NEXT FIELD inv_num 
			END IF 

			DISPLAY BY NAME 
				l_rec_despatchhead.ware_code, 
				l_rec_warehouse.desc_text 

		AFTER FIELD next_consign 
			IF l_rec_carrier.next_consign IS NULL THEN 
				ERROR kandoomsg2("E",9099,"") 	#9099 Consigment note must be entered
				LET l_rec_carrier.next_consign = 0 
				NEXT FIELD next_consign 
			END IF 

			SELECT unique 1 
			FROM despatchdetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND carrier_code = l_rec_carrier.carrier_code 
			AND despatch_code = l_rec_carrier.next_consign 
			IF sqlca.sqlcode = 0 THEN 
				ERROR kandoomsg2("E",9146,"") 		#9146 Consignment note number has already been used - Try again
				NEXT FIELD next_consign 
			END IF 

		AFTER FIELD despatch_date 
			IF l_rec_despatchhead.despatch_date IS NULL THEN 
				ERROR kandoomsg2("E",9152,"") 		#9152 Shippping date must be entered
				NEXT FIELD despatch_date 
			END IF 

		AFTER FIELD despatch_time 
			IF l_rec_despatchhead.despatch_time IS NULL THEN 
				ERROR kandoomsg2("E",9153,"") 		#9153 Shippping time must be entered
				NEXT FIELD despatch_time 
			END IF
			 
			IF l_rec_despatchhead.despatch_time[1,2] < "00" OR l_rec_despatchhead.despatch_time[1,2] > "24" THEN 
				ERROR kandoomsg2("E",9138,"") 	# 9138 An hour should have a value between 00 AND 24
				NEXT FIELD despatch_time 
			END IF
			 
			IF l_rec_despatchhead.despatch_time[4,5] < "00" OR l_rec_despatchhead.despatch_time[4,5] > "60" THEN 
				ERROR kandoomsg2("E",9139,"") 	# 9139 A minute should have a value between 00 AND 60
				NEXT FIELD despatch_time 
			END IF 
			
			IF l_rec_despatchhead.despatch_time[3,3] != ":" THEN 
				LET l_rec_despatchhead.despatch_time[3,3] = ":" 
				DISPLAY BY NAME l_rec_despatchhead.despatch_time 

			END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 

				IF l_rec_carrier.next_consign IS NULL THEN 
					ERROR kandoomsg2("E",9099,"") 				#9099 Consigment note must be entered
					LET l_rec_carrier.next_consign = 0 
					NEXT FIELD next_consign 
				END IF 

				IF l_rec_despatchhead.despatch_date IS NULL THEN 
					ERROR kandoomsg2("E",9152,"") 			#9152 Shippping date must be entered
					NEXT FIELD despatch_date 
				END IF 

				IF l_rec_despatchhead.despatch_time IS NULL THEN 
					ERROR kandoomsg2("E",9153,"") 				#9153 Shippping time must be entered
					NEXT FIELD despatch_time 
				END IF 

				IF l_rec_despatchhead.despatch_time[1,2] < "00"	OR l_rec_despatchhead.despatch_time[1,2] > "24" THEN 
					ERROR kandoomsg2("E",9138,"") 				# 9138 An hour should have a vale between 00 AND 24
					NEXT FIELD despatch_time 
				END IF 
				
				IF l_rec_despatchhead.despatch_time[4,5] < "00"	OR l_rec_despatchhead.despatch_time[4,5] > "60" THEN 
					ERROR kandoomsg2("E",9139,"") 				# 9139 A minute should have a value between 00 AND 60
					NEXT FIELD despatch_time 
				END IF 
				
				IF kandoomsg("E",8017,"") = "N" THEN #8017 Generate Consignment notes (Y/N)? 
					CONTINUE INPUT 
				END IF 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
	ELSE 
		LET l_where_text = "inv_num = \"",l_rec_invoicehead.inv_num,"\" " clipped 
		LET l_rec_despatchhead.carrier_code = l_rec_invoicehead.carrier_code 
		IF generate_connote(
			glob_rec_kandoouser.cmpy_code,
			glob_rec_kandoouser.sign_on_code,
			l_where_text,
			l_rec_despatchhead.*, 
			l_rec_carrier.next_consign,
			FALSE,
			TRUE) THEN 

			--LET modu_output = 
			CALL prepare_connote(
				glob_rec_kandoouser.cmpy_code,
				glob_rec_kandoouser.sign_on_code, 
				l_rec_despatchhead.carrier_code, 
				l_rec_despatchhead.ware_code, 
				l_rec_carrier.next_manifest, 
				l_rec_invoicehead.inv_num,
				"",
				FALSE) #returns TRUE/FALSE 
		END IF 
	END IF 
	CLOSE WINDOW E163 
END FUNCTION 
###########################################################################
# END FUNCTION select_s_criteria() 
###########################################################################


###########################################################################
# FUNCTION set_connote_num(p_rec_carrier) 
#
# 
###########################################################################
FUNCTION set_connote_num(p_rec_carrier) 
	DEFINE p_rec_carrier RECORD LIKE carrier.* 
	DEFINE l_next_consign LIKE carrier.next_consign 
	DEFINE l_last_consign LIKE carrier.last_consign 
	DEFINE l_nrof_ship_num SMALLINT 
	DEFINE l_part_char LIKE carrier.next_consign 
	DEFINE l_part_old_char LIKE carrier.next_consign 
	DEFINE l_part_num INTEGER 
	DEFINE l_err_message char(30) 
	DEFINE i SMALLINT 
	DEFINE x SMALLINT 
	DEFINE y SMALLINT 
	DEFINE z SMALLINT 
	
	OPEN WINDOW E162 with FORM "E162" 
	 CALL windecoration_e("E162") -- albo kd-755
 
	LET l_next_consign = p_rec_carrier.next_consign 
	LET l_last_consign = p_rec_carrier.last_consign 
	LET l_nrof_ship_num = 1 
	DISPLAY p_rec_carrier.last_consign TO last_consign 

	INPUT 
		p_rec_carrier.next_consign, 
		l_nrof_ship_num WITHOUT DEFAULTS 
	FROM 
		next_consign, 
		nrof_ship_num ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","E54","input-p_rec_carrier-1") -- albo kd-502 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD next_consign 
			IF p_rec_carrier.next_consign IS NULL THEN 
				ERROR kandoomsg2("E",9099,"") 			#9099 Consigment note must be entered
				LET p_rec_carrier.next_consign = 0 
				NEXT FIELD next_consign 
			END IF 

		AFTER FIELD nrof_ship_num
		 
			IF l_nrof_ship_num IS NULL THEN 
				ERROR kandoomsg2("E",9135,"") 			#9135 Number of needed consignment notes must be entered
				LET l_nrof_ship_num= 0 
				NEXT FIELD nrof_ship_num 
			END IF
			 
			IF l_nrof_ship_num <= 0 THEN 
				ERROR kandoomsg2("E",9136,"") 			#9136 Number of needed consignment notes must be greater than 0
				LET l_nrof_ship_num = 0 
				NEXT FIELD nrof_ship_num 
			END IF
			 
			LET l_part_char = NULL 
			FOR x = length(p_rec_carrier.next_consign) TO 1 step -1 
				IF p_rec_carrier.next_consign[x,x] < "0" OR p_rec_carrier.next_consign[x,x] > "9" THEN 
					EXIT FOR 
				ELSE 
					LET l_part_char[x,x] = p_rec_carrier.next_consign[x,x] 
				END IF 
			END FOR 

			IF l_part_char IS NULL THEN 
				ERROR kandoomsg2("E",9143,"") 		#9143 Next consignment note consists of characters only no addition
				NEXT FIELD next_consign 
			END IF 
			
			# Length numeric part original number
			LET y = length(l_part_char) - x 
			IF y > 9 THEN 
				ERROR kandoomsg2("E",9148,"") 			#9148 Numeric part may NOT be more than 9 digits
				NEXT FIELD next_consign 
			END IF 
			LET l_part_num = l_part_char + l_nrof_ship_num - 1 
			LET l_part_char = l_part_num
			 
			# Length numeric part new number
			LET z = length(l_part_char) 
			
			# Check IF addition leads TO outnumbering
			LET x = length(p_rec_carrier.next_consign) + z - y 
			IF x > 15 THEN 
				ERROR kandoomsg2("E",9145,"") 			#9145 Ran out of consignment note numbers
				NEXT FIELD nrof_ship_num 
			END IF
			 
			# IF length new number < length old number fill with leading zeroes
			IF z < y THEN 
				LET l_part_old_char = l_part_char 
				
				FOR i = y TO 1 step -1 
					LET l_part_char[i,i] = "0" 
				END FOR 
				
				LET i = y - z + 1 
				LET l_part_char[i,y] = l_part_old_char[1,z] 
				
				# Length numeric part new number
				LET z = length(l_part_char) 
			END IF
			 
			#  Determine startposition new number
			LET x = length(p_rec_carrier.next_consign) - y + 1 
			
			# Determine endposition new number
			LET y = x + z - 1 
			LET p_rec_carrier.last_consign = p_rec_carrier.next_consign 
			
			# Place new number AT correct position in last consigment note number
			LET p_rec_carrier.last_consign[x,y] = l_part_char[1,z] 
			DISPLAY BY NAME p_rec_carrier.last_consign 

			SELECT unique 1 
			FROM despatchdetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND carrier_code = p_rec_carrier.carrier_code 
			AND despatch_code between p_rec_carrier.next_consign 
			AND p_rec_carrier.last_consign 
			IF status != NOTFOUND THEN 
				ERROR kandoomsg2("E",9147,"") 			#9147 This range contains an already consignment note number
				NEXT FIELD next_consign 
			END IF 

	END INPUT 

	CLOSE WINDOW E162 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN 
			l_next_consign, 
			l_last_consign 

	ELSE 
	
		GOTO bypass 
		LABEL recovery: 
		IF error_recover(l_err_message,status) != "Y" THEN
			CALL fgl_winmessage("ERROR","Exit Program","ERROR") 		 
			EXIT PROGRAM 
		END IF 
		
		LABEL bypass: 
		WHENEVER ERROR GOTO recovery 
		BEGIN WORK 
			LET l_err_message = "Update carrier table" 
			UPDATE carrier 
			SET 
				next_consign = p_rec_carrier.next_consign, 
				last_consign = p_rec_carrier.last_consign 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND carrier_code = p_rec_carrier.carrier_code 
		COMMIT WORK 
		WHENEVER ERROR stop 

		RETURN 
			p_rec_carrier.next_consign,
			p_rec_carrier.last_consign 
	END IF	 
END FUNCTION
###########################################################################
# END FUNCTION set_connote_num(p_rec_carrier) 
###########################################################################