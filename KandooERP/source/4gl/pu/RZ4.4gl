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

	Source code beautified by beautify.pl on 2020-01-02 17:06:23	Source code beautified by beautify.pl on 2020-01-02 17:03:33	$Id: $
}

############################################################
# Purchase Group -> mast_vend_code
# Table: vendorgrp   (populated by using the table vendor)
# PK: cmpy_code, mast_vend_code, vend_code
# The description label: desc_text
#
#A unique code representing the Purchasing Group TO which this vendor belongs. Purchase Orders FROM this vendor may then be matched against invoices (vouchers) FROM the nominated Purchasing Group.
#Use the CTRL+B look-up window TO select FROM Purchase Group codes entered on the system, OR add a new one by pressing F10. Entry TO this field IS NOT mandatory.
#Please refer TO the Voucher Entry program for further information on distributing vendor vouchers via Purchase Groups
############################################################

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"
GLOBALS "R_PU_GLOBALS.4gl" 

GLOBALS 
	DEFINE glob_sqlerrd1 INTEGER 
END GLOBALS 
############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_cur_distinctmastervendorcode CURSOR 

#######################################################################
# MAIN
#
#   RZ4 - Purchase Group Maintenance
#######################################################################
MAIN 
	DEFINE l_withquery SMALLINT 

	CALL setModuleId("RZ4") -- albo 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_r_pu() #init r/pu purchase ORDER module 

	#if the the table has more than 1000 rows, force a query TO filter data
	IF db_vendorgrp_get_count() > 1000 THEN 
		LET l_withquery = true 
	END IF 

	OPEN WINDOW p126 with FORM "P126" 
	CALL  windecoration_p("P126") 

	WHILE select_vendorgrp(l_withquery) 
		LET l_withquery = scan_vendorgrp() 
		IF l_withquery = 2 OR int_flag THEN 
			EXIT WHILE 
		END IF 
	END WHILE 

	CLOSE WINDOW p126 
END MAIN 


##################################################################
# FUNCTION select_vendorgrp(p_withQuery)
#
# DataSource Cursor with optional Query
##################################################################
FUNCTION select_vendorgrp(p_withquery) 
	DEFINE p_withquery SMALLINT 
	DEFINE l_query_text CHAR(300) 
	DEFINE l_where_text CHAR(200) 

	IF p_withquery = 1 THEN 

		CLEAR FORM 
		LET msgresp = kandoomsg("U",1001,"") 
		#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON mast_vend_code, 
		desc_text 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","RZ4","construct-vend_code-1") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_where_text = "1=1" 
		END IF 

	ELSE 
		LET l_where_text = "1=1" 
	END IF 

	LET msgresp = kandoomsg("A",1002,"") 
	#1002 " Searching database - please wait"

	LET l_query_text = 
	"SELECT distinct mast_vend_code FROM vendorgrp ", 
	"WHERE cmpy_code = ","'",glob_rec_kandoouser.cmpy_code,"'", 
	"AND ", l_where_text clipped," ", 
	"ORDER BY mast_vend_code" 

	PREPARE s_vendorgrp FROM l_query_text 
	DECLARE c_vendorgrp CURSOR FOR s_vendorgrp 

	RETURN 1 
END FUNCTION 


##################################################################
# FUNCTION scan_vendorgrp()
#
# Populates record data array used by DISPLAY ARRAY
# Options for New, Edit AND Delete record row
##################################################################
FUNCTION scan_vendorgrp() 
	DEFINE l_rec_vendorgrp RECORD LIKE vendorgrp.* 
	DEFINE l_arr_rec_vendorgrp DYNAMIC ARRAY OF 
	RECORD 
		mast_vend_code LIKE vendorgrp.mast_vend_code, 
		desc_text LIKE vendorgrp.desc_text 
	END RECORD 
	DEFINE l_current, pr_count SMALLINT 
	DEFINE l_cnt SMALLINT 
	DEFINE idx SMALLINT 
	DEFINE l_del_cnt SMALLINT 
	DEFINE l_rowid SMALLINT 
	DEFINE l_err SMALLINT 
	CALL l_arr_rec_vendorgrp.clear() 
	LET idx = 0 


	FOREACH c_vendorgrp INTO l_rec_vendorgrp.mast_vend_code 
		LET idx = idx + 1 
		SELECT distinct desc_text INTO l_rec_vendorgrp.desc_text FROM vendorgrp 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND mast_vend_code = l_rec_vendorgrp.mast_vend_code 

		CALL l_arr_rec_vendorgrp.append([l_rec_vendorgrp.mast_vend_code, l_rec_vendorgrp.desc_text ]) 
	END FOREACH 


	IF idx = 0 THEN #huho was 1 
		LET msgresp = kandoomsg("U",9101,"") 
		#9101 No Purchase ORDER Types satisfied selection criteria
	END IF 

	LET msgresp = kandoomsg("U",1003,"") 

	#1003 " F1 TO Add - F2 TO Delete - RETURN on line TO Edit "
	DISPLAY ARRAY l_arr_rec_vendorgrp TO sr_vendorgrp.* --huho WITHOUT DEFAULTS FROM sr_vendorgrp.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","RZ4","inp-arr-vendorgrp-1") 

		BEFORE ROW 
			LET idx = arr_curr() 

		ON ACTION "FILTER" 
			RETURN 1 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION ("EDIT","ACCEPT") 
			IF idx > 0 THEN 
				IF l_arr_rec_vendorgrp[idx].mast_vend_code IS NOT NULL THEN 
					CALL manage_vendorGroups(l_arr_rec_vendorgrp[idx].*,"E") --e=edit 
				END IF 
				RETURN 0 --refresh data source in CASE purchase GROUP has no members 
			END IF 

		ON ACTION "DELETE_ROW" 
			LET l_del_cnt = 0 

			LET l_del_cnt = getTableRowsSelected("sr_vendorgrp") 

			IF l_del_cnt < 1 THEN --at least one ROW must be selected 
				ERROR "You must select at least one row TO delete" 
			ELSE 
				IF kandoomsg("U",8020,l_del_cnt) = "Y" THEN 
					#8020 Confirm TO Delete l_del_cnt rows
					FOR idx = 1 TO l_arr_rec_vendorgrp.getsize() --arr_count() 

						IF dialog.isRowSelected("sr_vendorgrp",idx) THEN 
							WHENEVER ERROR CONTINUE 
							BEGIN WORK 

								DELETE FROM vendorgrp 
								WHERE mast_vend_code = l_arr_rec_vendorgrp[idx].mast_vend_code 
								AND cmpy_code = glob_rec_kandoouser.cmpy_code 

								IF sqlca.sqlerrd[3] != 1 THEN 
									ERROR "RZ4 - Error Deleting Vendor Groups" 
								ELSE 
									CALL l_arr_rec_vendorgrp.delete(idx) 
									LET idx = idx - 1 --this needs TO be done TO keep the screen TABLE in sync with the program ARRAY 
								END IF 

							COMMIT WORK 
							WHENEVER ERROR stop 

						END IF 
					END FOR 
				END IF 
			END IF 
			RETURN 0 --refresh data source in CASE purchase GROUP has no members 
			CALL ui.interface.refresh() 

		ON ACTION "NEW" 
			#CALL manage_vendorGroups(l_arr_rec_vendorgrp[idx].*,"N")  --N=New
			CALL manage_vendorGroups(NULL,NULL,"N") --n=new 

			RETURN 0 --refresh data source TO include new purchase GROUP 

		ON KEY (control-w) 
			CALL kandoohelp("") 

	END DISPLAY 


	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 2 --exit 
	END IF 

END FUNCTION 


##################################################################
# FUNCTION vendorTempTable(p_mast_vend_code)
# RETURN void
#
# Creates temp table with all available vendors which can be added TO the current vendor group
##################################################################
FUNCTION vendortemptable(p_mast_vend_code) 
	DEFINE p_mast_vend_code LIKE vendorgrp.mast_vend_code 
	DEFINE l_arr_rec_list_vendor DYNAMIC ARRAY OF 
	RECORD 
		vend_code LIKE vendorgrp.vend_code, 
		name_text LIKE vendor.name_text, 
		addr1_text LIKE vendor.addr1_text 
	END RECORD 
	DEFINE l_rec_vendor 
	RECORD 
		vend_code LIKE vendorgrp.vend_code, 
		name_text LIKE vendor.name_text, 
		addr1_text LIKE vendor.addr1_text 
	END RECORD 

	DEFINE l_sqlquery VARCHAR(500) 
	DEFINE l_mast_currency_code LIKE vendor.currency_code 
	DEFINE l_temptablecheck SMALLINT 
	DEFINE p_filter_sql VARCHAR(500) 


	SELECT currency_code INTO l_mast_currency_code FROM vendor 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND vend_code = p_mast_vend_code 

	WHENEVER ERROR CONTINUE 
	SELECT count(*) INTO l_temptablecheck FROM temp_table_vendor 
	WHENEVER ERROR stop 

	IF status = -206 THEN --table does NOT exist 
		CREATE temp TABLE temp_table_vendor 
		( 
		vend_code nchar(8), 
		name_text nvarchar(30), 
		addr1_text nvarchar(40) 
		) 
	ELSE 
		DELETE FROM temp_table_vendor 
	END IF 

	LET l_sqlquery = 
	"SELECT ", 
	"vendor.vend_code, ", 
	"vendor.name_text, ", 
	"vendor.addr1_text ", 
	"FROM vendor ", 
	"WHERE vendor.cmpy_code = '",glob_rec_kandoouser.cmpy_code CLIPPED,"' ", #only vendors belonging TO the same kandoo user company 
	"AND ", 
	"vendor.vend_code != '", p_mast_vend_code clipped, "' " 

	#only vendors using the same currency can belong TO the same vendorGroup
	IF l_mast_currency_code IS NOT NULL THEN 
		LET l_sqlquery = l_sqlquery, " ", 
		"AND ", 
		"vendor.currency_code = '", l_mast_currency_code clipped, "' " 
	END IF 

	LET l_sqlquery = l_sqlquery, " ", #vendors which already belong TO a vendor GROUP can NOT be added TO another vendor GROUP 
	"AND ", 
	"vendor.vend_code NOT IN (SELECT mast_vend_code FROM vendorgrp) ", 
	"AND ", 
	"vendor.vend_code NOT IN (SELECT vend_code FROM vendorgrp) " 


	LET l_sqlquery = l_sqlquery, " ", "ORDER BY vendor.vend_code" 


	CALL l_arr_rec_list_vendor.clear() 

	PREPARE v_s_t_vendorlist FROM l_sqlquery 
	DECLARE v_c_t_vendorlist CURSOR FOR v_s_t_vendorlist 

	FOREACH v_c_t_vendorlist INTO l_rec_vendor 
		INSERT INTO temp_table_vendor VALUES ( l_rec_vendor.vend_code, l_rec_vendor.name_text, l_rec_vendor.addr1_text) 
	END FOREACH 

END FUNCTION 



##################################################################
# FUNCTION dataSourceVendorList(p_filter,p_mast_vend_code) #return l_arr_rec_vendorgrp
# RETURN l_arr_rec_list_vendor
#
# Full DataSource for vendor list which can be added TO current vendor group
# with optional filter/construct p_filter
##################################################################
FUNCTION datasourcevendorlist(p_filter,p_mast_vend_code) #return l_arr_rec_vendorgrp 
	DEFINE p_filter boolean 
	DEFINE p_mast_vend_code LIKE vendorgrp.mast_vend_code 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_vendorgrp RECORD LIKE vendorgrp.* 
	DEFINE l_arr_rec_list_vendor DYNAMIC ARRAY OF 
	RECORD 
		#scroll_flag CHAR(1),
		vend_code LIKE vendorgrp.vend_code, 
		name_text LIKE vendor.name_text, 
		addr1_text LIKE vendor.addr1_text 
	END RECORD 

	DEFINE l_where_text1 VARCHAR(200) 
	DEFINE l_query_text1 CHAR(500) 


	IF p_filter THEN 
		CONSTRUCT BY NAME l_where_text1 ON temp_table_vendor.vend_code, 
		temp_table_vendor.name_text, 
		temp_table_vendor.addr1_text 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","RZ4","construct-temp_table_vendor-1") -- albo kd-503 

			ON ACTION ("ACCEPT","filterToggle") 
				EXIT CONSTRUCT 

		END CONSTRUCT 

		IF int_flag THEN 
			LET int_flag = false 
			LET l_where_text1 = "1=1" 
		END IF 
	ELSE 
		LET l_where_text1 = "1=1" 
	END IF 

	LET l_query_text1 = 
	"SELECT ", 
	"vend_code, ", 
	"name_text, ", 
	"addr1_text ", 
	"FROM temp_table_vendor ", 
	"WHERE ", l_where_text1 clipped, " ", 
	"ORDER BY vend_code" 


	IF trim(l_where_text1) = "1=1" THEN 
		LET p_filter = false 
	END IF 


	CALL l_arr_rec_list_vendor.clear() 
	PREPARE l_pre_sql_vendorgrp FROM l_query_text1 
	DECLARE modu_curs_vendorgrp CURSOR FOR l_pre_sql_vendorgrp 


	FOREACH modu_curs_vendorgrp 
		INTO l_rec_vendorgrp.vend_code, l_rec_vendor.name_text, l_rec_vendor.addr1_text 

		CALL l_arr_rec_list_vendor.append([l_rec_vendorgrp.vend_code,l_rec_vendor.name_text,l_rec_vendor.addr1_text]) 
	END FOREACH 

	RETURN l_arr_rec_list_vendor, p_filter 

END FUNCTION 


##################################################################
# FUNCTION dataSourceVendorGroupMembers(p_mast_vend_code) #return l_arr_rec_vendorgrp
# RETURN l_arr_rec_vendorgrp
#
# Full DataSource including all current vendor group members
##################################################################
FUNCTION datasourcevendorgroupmembers(p_mast_vend_code) #return l_arr_rec_vendorgrp 
	DEFINE p_mast_vend_code LIKE vendorgrp.mast_vend_code 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_vendorgrp RECORD LIKE vendorgrp.* 
	DEFINE l_arr_rec_list_vendor, l_arr_rec_vendorgrp DYNAMIC ARRAY OF 
	RECORD 
		vend_code LIKE vendorgrp.vend_code, 
		name_text LIKE vendor.name_text, 
		addr1_text LIKE vendor.addr1_text 
	END RECORD 

	DEFINE l_query_text1 CHAR(500) 

	LET l_query_text1 = 
	"SELECT ", 
	"vendorgrp.vend_code, ", 
	"vendor.name_text, ", 
	"vendor.addr1_text ", 
	"FROM vendorgrp, vendor ", 
	"WHERE ", 
	"vendor.cmpy_code = '",glob_rec_kandoouser.cmpy_code CLIPPED,"' ", 
	"AND vendor.vend_code = vendorgrp.vend_code ", 
	"AND vendorgrp.cmpy_code = '",glob_rec_kandoouser.cmpy_code CLIPPED,"' ", 
	"AND vendorgrp.mast_vend_code = '",p_mast_vend_code CLIPPED,"' ", 
	"ORDER BY vendorgrp.vend_code" 

	CALL l_arr_rec_vendorgrp.clear() 
	PREPARE vgm_s_t_vendorgrp FROM l_query_text1 
	DECLARE vgm_c_t_vendorgrp CURSOR FOR vgm_s_t_vendorgrp 


	FOREACH vgm_c_t_vendorgrp INTO l_rec_vendorgrp.vend_code, 
		l_rec_vendor.name_text, 
		l_rec_vendor.addr1_text 

		CALL l_arr_rec_vendorgrp.append([l_rec_vendorgrp.vend_code,l_rec_vendor.name_text,l_rec_vendor.addr1_text]) 
	END FOREACH 

	RETURN l_arr_rec_vendorgrp 

END FUNCTION 


##################################################################
#FUNCTION manage_vendorGroups(p_rec_mast_vendor,p_mode)
# RETURN void
#
# Options TO include/exclude vendors in the current vendor group / purchase group
##################################################################
FUNCTION manage_vendorgroups(p_rec_mast_vendor,p_mode) # CALL manage_vendorgroups(p_rec_mast_vendor.*,p_mode) 
	DEFINE p_rec_mast_vendor t_rec_vendorgrp_mv_dt 
	#		RECORD
	#         mast_vend_code LIKE vendorgrp.mast_vend_code,
	#         desc_text LIKE vendorgrp.desc_text
	#		END RECORD
	DEFINE p_mode CHAR 
	DEFINE l_mast_currency_code LIKE vendor.currency_code 
	DEFINE l_arr_rec_list_vendor DYNAMIC ARRAY OF t_rec_vendor_vc_nt_ad 
	DEFINE l_arr_rec_list_vendor_members DYNAMIC ARRAY OF t_rec_vendor_vc_nt_ad 
	#		RECORD
	#			vend_code LIKE vendorgrp.vend_code,
	#			name_text LIKE vendor.name_text,
	#			addr1_text LIKE vendor.addr1_text
	#		END RECORD
	DEFINE l_del_cnt SMALLINT 
	DEFINE l_rowid integer--, --seems TO be another idx FOR the programarray INDEX 
	DEFINE l_where_text1 CHAR(200) 
	DEFINE l_query_text1 CHAR(500) 
	DEFINE l_filter boolean 
	DEFINE l_rec_move_vend 
	RECORD 
		vend_code LIKE vendorgrp.vend_code, 
		name_text LIKE vendor.name_text, 
		addr1_text LIKE vendor.addr1_text 
	END RECORD 
	DEFINE l_tempdescription LIKE vendorgrp.desc_text 
	DEFINE l_move_cnt SMALLINT --count OF selected items 
	DEFINE l_arr_index DYNAMIC ARRAY OF SMALLINT --array OF indexes OF selected ROWS 
	DEFINE l_ret SMALLINT 
	DEFINE l_v_idx SMALLINT 
	DEFINE l_vgr_idx SMALLINT 
	DEFINE idx SMALLINT 
	DEFINE x SMALLINT 

	#	IF p_rec_mast_vendor.mast_vend_code IS NOT NULL THEN
	OPEN WINDOW p119 with FORM "P119" 
	CALL  windecoration_p("P119") 
	#	ELSE
	#		RETURN NULL
	#	END IF

	CASE upshift(p_mode) 

		WHEN "E" --edit 
			IF p_rec_mast_vendor.mast_vend_code IS NULL THEN 
				CLOSE WINDOW p119 
				RETURN NULL 
			END IF 

			DISPLAY p_rec_mast_vendor.mast_vend_code TO vendorgrp.mast_vend_code 
			DISPLAY p_rec_mast_vendor.desc_text TO vendorgrp.desc_text 

		WHEN "N" --new 
			LET msgresp = kandoomsg("R",1003,"") 
			#1003 " Enter Purchase Group Details - ESC TO continue"
			INPUT p_rec_mast_vendor.mast_vend_code, p_rec_mast_vendor.desc_text #without DEFAULTS 
			FROM vendorgrp.mast_vend_code, vendorgrp.desc_text ATTRIBUTE(UNBUFFERED) 

				BEFORE INPUT 
					CALL publish_toolbar("kandoo","RZ4","inp-vendorgrp-1") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON KEY (control-b) infield(mast_vend_code) 
					LET p_rec_mast_vendor.mast_vend_code = show_vend(glob_rec_kandoouser.cmpy_code,p_rec_mast_vendor.mast_vend_code) 
					IF p_rec_mast_vendor.mast_vend_code IS NOT NULL THEN 
						NEXT FIELD mast_vend_code 
					ELSE 
						NEXT FIELD vendorgrp.desc_text 
					END IF 

				AFTER FIELD mast_vend_code 
					IF p_rec_mast_vendor.mast_vend_code IS NULL THEN 
						ERROR "You need TO specify a primary vendor for the purchase/vendor group" 
						NEXT FIELD mast_vend_code 
					END IF 
					#check if vendor group already exists with this vendor as master
					IF db_vendorgrp_pk_exists(p_rec_mast_vendor.mast_vend_code) THEN 
						ERROR "Vendor Group already exists" 
						NEXT FIELD mast_vend_code 
					END IF 
					#check if vendor IS already assigned as a member TO any other vendor group
					IF db_vendorgrp_vendor_already_member(p_rec_mast_vendor.mast_vend_code) THEN 
						ERROR "Vendor IS already a member of another group" 
						NEXT FIELD mast_vend_code 
					END IF 

				AFTER FIELD vendorgrp.desc_text 
					IF p_rec_mast_vendor.desc_text IS NULL THEN 
						ERROR "You need TO specify a purchase/vendor group description" 
						NEXT FIELD vendorgrp.desc_text 
					END IF 

			END INPUT 

			IF int_flag THEN 
				LET int_flag = false 
				CLOSE WINDOW p119 
				RETURN NULL 
			END IF 

	END CASE 

	DISPLAY p_rec_mast_vendor.mast_vend_code TO vendorgrp.mast_vend_code 
	DISPLAY p_rec_mast_vendor.desc_text TO vendorgrp.desc_text 
	CALL ui.interface.refresh() 
	# create dataSource
	CALL vendortemptable(p_rec_mast_vendor.mast_vend_code) 
	CALL datasourcevendorlist(l_filter,p_rec_mast_vendor.mast_vend_code) RETURNING l_arr_rec_list_vendor, l_filter 
	CALL datasourcevendorgroupmembers(p_rec_mast_vendor.mast_vend_code) RETURNING l_arr_rec_list_vendor_members 

	LET l_v_idx = 1 
	LET l_vgr_idx = 1 

	dialog ATTRIBUTE(UNBUFFERED) 

	#-Vendors which can be added TO the Group LEFT  ----------------------------------------------------------------------------
	DISPLAY ARRAY l_arr_rec_list_vendor TO sr_vendorlist.* 

		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","RZ4","display_arr-l_arr_rec_list_vendor-1") -- albo kd-503 

		BEFORE ROW 
			LET l_v_idx = arr_curr() 

		ON ACTION ("ADD_MOVE_LEFT","doubleClick") #add vendor TO vendor GROUP 
			LET l_arr_index = getTableRowsSelected("sr_vendorList") --index OF all selected ROWS 
			LET l_move_cnt = l_arr_index.getsize() 

			IF l_move_cnt > 0 THEN --at least one ROW must be selected 

				FOR l_v_idx = 1 TO l_arr_index.getsize() 
					LET l_ret = db_vendorgrp_insert(glob_rec_kandoouser.cmpy_code, p_rec_mast_vendor.mast_vend_code, p_rec_mast_vendor.desc_text, l_arr_rec_list_vendor[l_arr_index[l_v_idx]].vend_code) 

					IF sqlca.sqlerrd[3] != 1 THEN 
						ERROR "RZ4 - Error Moving Vendor TO the current Vendor Group" 
					ELSE 
						CALL l_arr_rec_list_vendor.delete(l_v_idx) 
					END IF 

				END FOR 
			ELSE 
				ERROR "You must select at least one row TO be moved" 
			END IF 


			#					FOR l_v_idx = 1 TO l_arr_rec_list_vendor.getsize()  --arr_count()
			#
			#						IF dialog.isRowSelected("sr_vendorList",l_v_idx) THEN
			#							WHENEVER ERROR CONTINUE
			#							BEGIN WORK
			#
			#							LET l_ret = db_purchtype_insert(glob_rec_kandoouser.cmpy_code, p_rec_mast_vendor.mast_vend_code, p_rec_mast_vendor.desc_text,  l_arr_rec_list_vendor[l_v_idx].vend_code)
			#
			#							IF sqlca.sqlerrd[3] != 1 THEN
			#								ERROR "RZ4 - Error Moving Vendor TO the current Vendor Group"
			#							ELSE
			#								CALL l_arr_rec_list_vendor.delete(l_v_idx)
			#							END IF
			#
			#							COMMIT WORK
			#							WHENEVER ERROR STOP
			#
			#						END IF
			#					END FOR
			#				ELSE
			#					ERROR "You must select at least one row TO be moved"
			#				END IF

			LET l_filter = false --datasource has changed AND needs refreshing 
			CALL vendortemptable(p_rec_mast_vendor.mast_vend_code) 
			CALL datasourcevendorlist(l_filter,p_rec_mast_vendor.mast_vend_code) RETURNING l_arr_rec_list_vendor,l_filter 
			CALL datasourcevendorgroupmembers(p_rec_mast_vendor.mast_vend_code) RETURNING l_arr_rec_list_vendor_members 

	END DISPLAY 

	#-Vendor Group Members RIGHT ----------------------------------------------------------------------------

	DISPLAY ARRAY l_arr_rec_list_vendor_members TO sr_vendorgrp.* 

		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","RZ4","display_arr-l_arr_rec_list_vendor-2") -- albo kd-503 

		BEFORE ROW 
			LET l_vgr_idx = l_arr_rec_list_vendor_members.getsize() -- arr_count() 

		ON ACTION ("DELETE_MOVE_RIGHT","doubleClick") #remove vendor FROM vendor GROUP 
			LET l_arr_index = getTableRowsSelected("sr_vendorgrp") --index OF all selected ROWS 
			LET l_move_cnt = l_arr_index.getsize() 

			IF l_move_cnt > 0 THEN --at least one ROW must be selected 
				WHENEVER ERROR CONTINUE 
				BEGIN WORK 

					FOR l_v_idx = 1 TO l_arr_index.getsize() 
						LET l_ret = db_vendorgrp_delete(p_rec_mast_vendor.mast_vend_code,l_arr_rec_list_vendor_members[l_arr_index[l_v_idx]].vend_code) 

						IF sqlca.sqlerrd[3] != 1 THEN 
							ERROR "RZ4 - Error removing vendors FROM the current Purchasing Vendor Group" 
						ELSE 
							CALL l_arr_rec_list_vendor_members.delete(l_vgr_idx) 
						END IF 

					END FOR 

				COMMIT WORK 
				WHENEVER ERROR stop 

			ELSE 
				ERROR "You must select at least one row TO be removed FROM the group" 
			END IF 

			LET l_filter = false 
			CALL vendortemptable(p_rec_mast_vendor.mast_vend_code) 
			CALL datasourcevendorlist(l_filter,p_rec_mast_vendor.mast_vend_code) RETURNING l_arr_rec_list_vendor 
			CALL datasourcevendorgroupmembers(p_rec_mast_vendor.mast_vend_code) RETURNING l_arr_rec_list_vendor_members 

	END DISPLAY 

	INPUT p_rec_mast_vendor.desc_text WITHOUT DEFAULTS 
	FROM vendorgrp.desc_text 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","RZ4","inp-p_rec_mast_vendor-1") 
			LET msgresp = kandoomsg("R",1003,"") 
			#1003 " Enter Purchase Group Details - ESC TO continue"

		AFTER FIELD vendorgrp.desc_text 
			IF p_rec_mast_vendor.desc_text IS NULL THEN 
				ERROR "You need TO specify a purchase/vendor group description" 
				NEXT FIELD vendorgrp.desc_text 
			ELSE 
				IF field_touched(vendorgrp.desc_text) THEN 
					CALL db_vendorgrp_update_description(p_rec_mast_vendor.mast_vend_code,p_rec_mast_vendor.desc_text) 
					CALL datasourcevendorgroupmembers(p_rec_mast_vendor.mast_vend_code) RETURNING l_arr_rec_list_vendor_members 
				END IF 
			END IF 

	END INPUT 



	ON ACTION "filterToggle" 
		IF l_filter THEN 
			LET l_filter = false 
			CLEAR (temp_table_vendor.vend_code, temp_table_vendor.name_text, temp_table_vendor.addr1_text) 
		ELSE 
			LET l_filter = true 
		END IF 

		# create dataSource
		CALL datasourcevendorlist(l_filter,p_rec_mast_vendor.mast_vend_code) RETURNING l_arr_rec_list_vendor, l_filter 
		LET l_v_idx = 1 
		LET l_vgr_idx = 1 

	ON ACTION "DONE" 
		EXIT dialog 

	ON ACTION "WEB-HELP" 
		CALL onlinehelp(getmoduleid(),null) 

	ON ACTION "actToolbarManager" 
		CALL setuptoolbar() 

		BEFORE dialog 
			CALL publish_toolbar("kandoo","RZ4","inp-vendorgrp-1") 

			END dialog 

			IF l_arr_rec_list_vendor_members.getsize() = 0 THEN 
				MESSAGE "No Purchase Group was created" 
				CALL ui.interface.refresh() 
			END IF 

			CLOSE WINDOW p119 

END FUNCTION 

