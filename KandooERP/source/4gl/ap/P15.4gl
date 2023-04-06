# Vendor Address Maintenance P101
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
	Source code beautified by beautify.pl on 2020-01-03 13:41:18	$Id: $
}
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_P1_GLOBALS.4gl" 
#GLOBALS "P11a.4gl"


############################################################
# MAIN
#
# allows the user TO maintain vendor noncredit information
# AND delete a vendor IF no financial info exist
############################################################
MAIN 
	DEFINE l_withquery SMALLINT 
	#Initial UI Init
	CALL setModuleId("P15") 
	CALL ui_init(0) 


	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	OPEN WINDOW p101 with FORM "P101" 
	CALL windecoration_p("P101") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	#if the the table has more than 1000 rows, force a query TO filter data
	IF db_vendor_get_count() > 1000 THEN 
		LET l_withquery = true 
	END IF 

	WHILE construct_dataset_vendor(l_withquery) 
		LET l_withquery = scan_vendor() 
		IF l_withquery = 2 OR int_flag THEN 
			EXIT WHILE 
		END IF 
	END WHILE 

	CLOSE WINDOW p101 

END MAIN 


############################################################
# FUNCTION construct_dataset_vendor()
#
#
############################################################
FUNCTION construct_dataset_vendor(p_withquery) 
	DEFINE p_withquery SMALLINT 
	DEFINE l_where_text CHAR(200) 
	DEFINE l_query_text CHAR(300) 
	DEFINE l_msgresp LIKE language.yes_flag 

	IF p_withquery = 1 THEN 

		CLEAR FORM 
		LET l_msgresp = kandoomsg("U",1001,"") 
		#1001 Enter criteria FOR selection
		CONSTRUCT BY NAME l_where_text ON vend_code, 
		name_text, 
		contact_text, 
		tele_text 


			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","P15","construct-vendor-1") 

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

	LET l_msgresp = kandoomsg("U",1002,"") 
	#1002 Seraching database - please wait
	LET l_query_text = "SELECT * FROM vendor ", 
	"WHERE cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND ",l_where_text clipped, 
	"ORDER BY vend_code " 
	PREPARE s_vendor FROM l_query_text 
	DECLARE c_vendor CURSOR FOR s_vendor 
	RETURN true 

	RETURN 1 

END FUNCTION 


############################################################
# FUNCTION scan_vendor()
############################################################
FUNCTION scan_vendor() 
	DEFINE l_arr_rec_vendor DYNAMIC ARRAY OF 
	RECORD --huho changed TO DYNAMIC [250] 
		vend_code LIKE vendor.vend_code, 
		name_text LIKE vendor.name_text, 
		contact_text LIKE vendor.contact_text, 
		tele_text LIKE vendor.tele_text 
	END RECORD 
	DEFINE l_err_message CHAR(60) 
	DEFINE l_idx SMALLINT --program ARRAY INDEX 
	DEFINE l_del_cnt SMALLINT --number OF selected ROWS TO DELETE 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_process_status BOOLEAN

	LET l_idx = 1 

	#no idea why it uses the full record array....
	CALL l_arr_rec_vendor.clear() 
	FOREACH c_vendor INTO glob_rec_vendor.* 
		CALL l_arr_rec_vendor.append([glob_rec_vendor.vend_code, glob_rec_vendor.name_text, glob_rec_vendor.contact_text,glob_rec_vendor.tele_text]) 
	END FOREACH 

	IF l_arr_rec_vendor.getsize() = 0 THEN 
		LET l_msgresp = kandoomsg("U",9101,"") 
		#9101 No entries satisfied selection criteria"
		LET l_idx = 1 
	END IF 

	LET l_msgresp = kandoomsg("P",1055,"") 

	#1055  RETURN on line TO change, F2 TO delete"
	DISPLAY ARRAY l_arr_rec_vendor TO sr_vendor.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","P15","inp-arr-vendor-1") 

		BEFORE ROW 
			LET l_idx = arr_curr() 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER" 
			RETURN 1 

		ON ACTION "ACCEPT" --edit 
			IF l_arr_rec_vendor[l_idx].vend_code IS NOT NULL THEN 

				OPEN WINDOW p176 with FORM "P176" 
				CALL windecoration_p("P176") 

				CALL process_vendor("P15",MODE_CLASSIC_EDIT,l_arr_rec_vendor[l_idx].vend_code) 
				RETURNING l_process_status 
				IF l_process_status THEN 
					LET l_arr_rec_vendor[l_idx].name_text = glob_rec_vendor.name_text 
					LET l_arr_rec_vendor[l_idx].contact_text = glob_rec_vendor.contact_text 
					LET l_arr_rec_vendor[l_idx].tele_text = glob_rec_vendor.tele_text 
				END IF 

				CLOSE WINDOW p176 

			END IF 

		ON ACTION "ADD" 
			CALL fgl_winmessage("HuHo Beta feature test","just TO see, if we could allow TO add records here","info") 
			CALL run_prog("P11","","","","") 
			RETURN 0 

		ON ACTION "DELETE_ROWS" 
			LET l_del_cnt = 0 
			FOR l_idx = 1 TO arr_count() 
				IF dialog.isRowSelected("sr_vendor",l_idx) THEN 
					LET l_del_cnt = l_del_cnt + 1 
				END IF 
			END FOR 

			IF kandoomsg("U",8020,l_del_cnt) = "Y" THEN --user confirmation required 

				FOR l_idx = 1 TO l_arr_rec_vendor.getsize() --arr_count() 

					IF dialog.isRowSelected("sr_vendor",l_idx) THEN 

						IF NOT vendor_active(l_arr_rec_vendor[l_idx].vend_code) THEN 
							MESSAGE kandoomsg2("U",1005,"")		#1005 Updating database - please wait
							GOTO bypass 
							LABEL recovery: 
							IF error_recover(l_err_message,status) != "Y" THEN 
								RETURN false 
							END IF 
							LABEL bypass: 
							WHENEVER ERROR GOTO recovery 
							BEGIN WORK 
								LET l_err_message = "P15 - Deleting Vendor Record" 
								DELETE FROM vendornote 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND vend_code = l_arr_rec_vendor[l_idx].vend_code 
								DELETE FROM vendorhist 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND vend_code = l_arr_rec_vendor[l_idx].vend_code 
								DELETE FROM vendor 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND vend_code = l_arr_rec_vendor[l_idx].vend_code 
								IF sqlca.sqlerrd[3] != 1 THEN 
									LET l_err_message = "P15 - Error Deleting Vendor" 
									GOTO recovery 
								ELSE 
									CALL l_arr_rec_vendor.delete(l_idx) 
									LET l_idx = l_idx - 1 --this needs TO be done TO keep the screen TABLE in sync with the program ARRAY 
								END IF 
							COMMIT WORK 
							WHENEVER ERROR stop 
						END IF 
					END IF 

				END FOR 
				CALL ui.interface.refresh() 
			END IF 

	END DISPLAY 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 2 
	END IF 

END FUNCTION 


############################################################
# FUNCTION vendor_active(p_vend_code)
#
#
############################################################
FUNCTION vendor_active(p_vend_code) 
	DEFINE p_vend_code LIKE vendor.vend_code 

	SELECT unique 1 FROM apaudit 
	WHERE vend_code = p_vend_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 

	IF status != NOTFOUND THEN 
		RETURN true 
	END IF 

	SELECT unique 1 FROM purchhead 
	WHERE vend_code = p_vend_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 

	IF status = NOTFOUND THEN 
		RETURN false 
	END IF 

	RETURN true 
END FUNCTION 


