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

############################################################
# FUNCTION db_shiphead_get_datasource(p_filter,p_cmpy_code)
#
# Datasource
# RETURNING l_arr_rec_shiphead
############################################################
FUNCTION db_shiphead_get_datasource(p_filter,p_cmpy_code)
	DEFINE p_filter BOOLEAN
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_shiphead RECORD LIKE shiphead.* 
	DEFINE l_rec_shipdetl RECORD LIKE shipdetl.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_arr_rec_shiphead DYNAMIC ARRAY OF #array[250] OF RECORD 
		RECORD 
			ship_code LIKE shiphead.ship_code, 
			ship_type_code LIKE shiphead.ship_type_code, 
			vend_code LIKE shiphead.vend_code, 
			part_code LIKE shipdetl.part_code, 
			source_doc_num LIKE shipdetl.source_doc_num, 
			discharge_text LIKE shiphead.discharge_text, 
			ship_status_code LIKE shiphead.ship_status_code 
		END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 

	IF p_filter THEN
		LET l_msgresp = kandoomsg("U",1001,"") 	#1001 Enter Selection Criteria - OK TO Continue.

		CONSTRUCT BY NAME l_where_text ON 
			shiphead.ship_code, 
			ship_type_code, 
			vend_code, 
			part_code, 
			source_doc_num, 
			discharge_text, 
			ship_status_code 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","showship","construct-shiphead")
				 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_where_text = " 1=1 "
		END IF 

	ELSE
		LET l_where_text = " 1=1 "
	END IF

	LET l_msgresp = kandoomsg("U",1002,"")	#1002 Searching Database - Please Wait
	LET l_query_text = 
		"SELECT * FROM shiphead, shipdetl ", 
		" WHERE shiphead.cmpy_code = \"",p_cmpy_code,"\" ", 
		" AND shipdetl.cmpy_code = \"",p_cmpy_code,"\" ", 
		" AND shipdetl.ship_code = shiphead.ship_code AND ", 
		l_where_text clipped, 
		" ORDER BY shiphead.cmpy_code, shiphead.ship_code " 

	PREPARE s_shiphead FROM l_query_text 
	DECLARE c_shiphead CURSOR FOR s_shiphead 

	LET l_idx = 0 
	FOREACH c_shiphead INTO l_rec_shiphead.*, l_rec_shipdetl.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_shiphead[l_idx].ship_code = l_rec_shiphead.ship_code 
		LET l_arr_rec_shiphead[l_idx].vend_code = l_rec_shiphead.vend_code 
		LET l_arr_rec_shiphead[l_idx].ship_type_code = l_rec_shiphead.ship_type_code 
		LET l_arr_rec_shiphead[l_idx].part_code = l_rec_shipdetl.part_code 
		LET l_arr_rec_shiphead[l_idx].source_doc_num = l_rec_shipdetl.source_doc_num 
		LET l_arr_rec_shiphead[l_idx].discharge_text = l_rec_shiphead.discharge_text 
		LET l_arr_rec_shiphead[l_idx].ship_status_code = l_rec_shiphead.ship_status_code

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF			 
	END FOREACH 
	
	MESSAGE kandoomsg2("U",9113,l_idx)	#9113 l_idx records selected
	RETURN l_arr_rec_shiphead
END FUNCTION	
############################################################
# END FUNCTION db_shiphead_get_datasource(p_filter,p_cmpy_code)
############################################################


############################################################
# FUNCTION showship(p_cmpy_code)
#
# showship - Window FUNCTION FOR Shipments Selection
############################################################
FUNCTION showship(p_cmpy_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_shiphead RECORD LIKE shiphead.* 
	DEFINE l_rec_shipdetl RECORD LIKE shipdetl.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_arr_rec_shiphead DYNAMIC ARRAY OF #array[250] OF RECORD 
		RECORD 
			ship_code LIKE shiphead.ship_code, 
			ship_type_code LIKE shiphead.ship_type_code, 
			vend_code LIKE shiphead.vend_code, 
			part_code LIKE shipdetl.part_code, 
			source_doc_num LIKE shipdetl.source_doc_num, 
			discharge_text LIKE shiphead.discharge_text, 
			ship_status_code LIKE shiphead.ship_status_code 
		END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 

		OPEN WINDOW l107 with FORM "L107" 
		CALL winDecoration_l("L107") -- albo kd-752 

	CALL db_shiphead_get_datasource(FALSE,p_cmpy_code) RETURNING l_arr_rec_shiphead

		IF l_arr_rec_shiphead.getSize() > 0 THEN
			MESSAGE "No Data found"
		END IF 

--			CALL set_count (l_idx) 
			LET l_msgresp = kandoomsg("U",1519,"") 
			#1519 OK TO SELECT; ENTER TO View; F10 TO Add.
			DISPLAY ARRAY l_arr_rec_shiphead TO  sr_shiphead.* ATTRIBUTE(UNBUFFERED) 
				BEFORE DISPLAY
					CALL publish_toolbar("kandoo","showship","input-arr-shiphead") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON ACTION "FILTER"
					CALL l_arr_rec_shiphead.clear()
					CALL db_shiphead_get_datasource(TRUE,p_cmpy_code) RETURNING l_arr_rec_shiphead
					IF l_arr_rec_shiphead.getSize() > 0 THEN
						MESSAGE "No Data found"
					END IF 

				ON ACTION "SETTINGS"  --ON KEY (F10) 
					CALL run_prog("L11","","","","") 

				ON ACTION "SCANNER"  --BEFORE FIELD ship_type_code 
					IF l_rec_shiphead.ship_code IS NOT NULL THEN 
						CALL scanner(p_cmpy_code, l_rec_shiphead.ship_code, l_rec_shiphead.vend_code) 
					END IF 

				BEFORE ROW 
					LET l_idx = arr_curr() 
					IF l_idx > 0 THEN 
						LET l_rec_shiphead.ship_code = l_arr_rec_shiphead[l_idx].ship_code 
						LET l_rec_shiphead.vend_code = l_arr_rec_shiphead[l_idx].vend_code 
						LET l_rec_shiphead.ship_type_code = l_arr_rec_shiphead[l_idx].ship_type_code 
						LET l_rec_shipdetl.part_code = l_arr_rec_shiphead[l_idx].part_code 
						LET l_rec_shipdetl.source_doc_num = l_arr_rec_shiphead[l_idx].source_doc_num 
						LET l_rec_shiphead.discharge_text = l_arr_rec_shiphead[l_idx].discharge_text 
						LET l_rec_shiphead.ship_status_code = l_arr_rec_shiphead[l_idx].ship_status_code 
					END IF 

		END DISPLAY 
 
		CLOSE WINDOW l107 

		IF int_flag OR quit_flag THEN 
			LET l_arr_rec_shiphead[l_idx].ship_code = NULL 
		END IF 
		LET int_flag = false 
		LET quit_flag = false 

		RETURN l_arr_rec_shiphead[l_idx].ship_code  #?why are we dealing firstly with a  full record.. and only returning one column ? 
END FUNCTION 
############################################################
# END FUNCTION showship(p_cmpy_code)
############################################################


############################################################
# FUNCTION scanner(p_cmpy_code, p_ship_code, p_vend_code)
#
#
############################################################
FUNCTION scanner(p_cmpy_code,p_ship_code,p_vend_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_ship_code LIKE shiphead.ship_code 
	DEFINE p_vend_code LIKE vendor.vend_code 
	DEFINE l_rec_shiphead RECORD LIKE shiphead.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_func_type CHAR(14) 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW l105 with FORM "L105" 
	CALL winDecoration_l("L105") -- albo kd-752 

	SELECT o.*, c.* INTO l_rec_shiphead.*, l_rec_vendor.* FROM shiphead o, vendor c 
	WHERE o.ship_code = p_ship_code 
	AND c.vend_code = p_vend_code 
	AND o.cmpy_code = p_cmpy_code 
	AND c.cmpy_code = p_cmpy_code 

	DISPLAY BY NAME 
		l_rec_shiphead.vend_code, 
		l_rec_vendor.name_text, 
		l_rec_shiphead.ship_code, 
		l_rec_shiphead.agent_code, 
		l_rec_shiphead.vessel_text, 
		l_rec_shiphead.ship_type_code, 
		l_rec_shiphead.origin_port_text, 
		l_rec_shiphead.eta_curr_date, 
		l_rec_shiphead.discharge_text, 
		l_rec_shiphead.curr_code, 
		l_rec_shiphead.bl_awb_text, 
		l_rec_shiphead.ship_status_code, 
		l_rec_shiphead.container_text, 
		l_rec_shiphead.ware_code, 
		l_rec_shiphead.fob_ent_cost_amt, 
		l_rec_shiphead.duty_ent_amt, 
		l_rec_shiphead.entry_code, 
		l_rec_shiphead.entry_date, 
		l_rec_shiphead.com1_text, 
		l_rec_shiphead.rev_num, 
		l_rec_shiphead.com2_text, 
		l_rec_shiphead.rev_date 

	LET l_msgresp = kandoomsg("A",8010,"") 
	LET l_msgresp = upshift(l_msgresp) 

	IF l_msgresp = "Y" THEN 
		LET l_func_type = "View Order" 
		CALL shipshow(
			p_cmpy_code, 
			l_rec_shiphead.vend_code, 
			l_rec_shiphead.ship_code, 
			l_func_type) 
	END IF 

	CLOSE WINDOW l105 

	RETURN 
END FUNCTION 
############################################################
# END FUNCTION scanner(p_cmpy_code, p_ship_code, p_vend_code)
############################################################