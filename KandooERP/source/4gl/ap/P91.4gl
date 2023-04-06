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
# This Program allows the user TO enter AND maintain contractor
# information, especially withholding tax details
# It may be run FROM another program (eg. P11) with an argument of
# vendor code TO add a contractor entry FOR that vendor
#
# Rewritten based on AZ3 TO bring ARRAY handling INTO line with current
# standards
#

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P9_GROUP_GLOBALS.4gl" 
GLOBALS "../ap/P91_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################
GLOBALS 
	DEFINE pr_vend_code_arg LIKE vendor.vend_code 
END GLOBALS 

############################################################
# MAIN
#
#
############################################################
MAIN 
	DEFINE l_row SMALLINT 

	#Initial UI Init
	CALL setModuleId("P91") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	IF get_url_vendor_code() IS NOT NULL THEN
	--IF num_args() > 0 THEN 
		LET pr_vend_code_arg = get_url_vendor_code() --arg_val(1) 
		LET l_row = edit_contractor("") 
	ELSE 
		LET pr_vend_code_arg = NULL 

		OPEN WINDOW p158 with FORM "P158" 
		CALL windecoration_p("P158") 

		CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

		WHILE select_contractor() 
			CALL scan_contractor() 
		END WHILE 
		CLOSE WINDOW p158 
	END IF 
END MAIN 


############################################################
# FUNCTION select_contractor()
#
#
############################################################
FUNCTION select_contractor() 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_where_text CHAR(2048) 
	DEFINE l_msgresp LIKE language.yes_flag 

	CLEAR FORM 
	LET l_msgresp=kandoomsg("P",1001,"") 
	#1001 Enter Selection Criteria - ESC TO Continue"

	CONSTRUCT l_where_text ON contractor.vend_code, 
	vendor.name_text, 
	contractor.variation_text 
	FROM contractor.vend_code, 
	vendor.name_text, 
	contractor.variation_text 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","P91","construct-contractor-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		LET l_msgresp=kandoomsg("P",1002,"") 
		#1002 Searching database - please wait
		LET l_query_text = "SELECT * FROM contractor, vendor ", 
		"WHERE contractor.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		" AND contractor.cmpy_code = vendor.cmpy_code ", 
		" AND contractor.vend_code = vendor.vend_code ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY 1,2" 
		PREPARE s_contractor FROM l_query_text 
		DECLARE c_contractor CURSOR FOR s_contractor 
		RETURN true 
	END IF 
END FUNCTION 


############################################################
# FUNCTION scan_contractor()
#
#
############################################################
FUNCTION scan_contractor() 
	DEFINE l_rec_contractor RECORD LIKE contractor.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_arr_contractor ARRAY[250] OF RECORD 
		scroll_flag CHAR(1), 
		vend_code LIKE contractor.vend_code, 
		name_text LIKE vendor.name_text, 
		variation_text LIKE contractor.variation_text 
	END RECORD 
	DEFINE l_scroll_flag CHAR(1) 
	DEFINE l_rowid INTEGER 
	DEFINE l_del_qty SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE idx SMALLINT

	LET idx = 0 

	FOREACH c_contractor INTO l_rec_contractor.*, l_rec_vendor.* 
		LET idx = idx + 1 
		LET l_arr_contractor[idx].vend_code = l_rec_contractor.vend_code 
		LET l_arr_contractor[idx].name_text = l_rec_vendor.name_text 
		LET l_arr_contractor[idx].variation_text = l_rec_contractor.variation_text 
		IF idx = 250 THEN 
			LET l_msgresp=kandoomsg("P",9005,250) 
			#9005 " First 250 Contractors Selected"
			EXIT FOREACH 
		END IF 
	END FOREACH 

	IF idx = 0 THEN 
		LET l_msgresp=kandoomsg("P",9129,"") 
		#P9129 "No contractors satisfied selection criteria"
		LET idx = 1 
	END IF 
	LET l_msgresp=kandoomsg("P",1003,"") 
	#1003 F1 TO add, RETURN on line TO change, F2 TO delete"
	CALL set_count(idx) 

	OPTIONS DELETE KEY f36, 
	INSERT KEY f1 

	INPUT ARRAY l_arr_contractor WITHOUT DEFAULTS FROM sr_contractor.* ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P91","inp-arr-contractor-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE FIELD scroll_flag 
			LET idx = arr_curr() 
			#LET scrn = scr_line()
			LET l_scroll_flag = l_arr_contractor[idx].scroll_flag 
			# DISPLAY l_arr_contractor[idx].*
			#      TO sr_contractor[scrn].*

		AFTER FIELD scroll_flag 
			LET l_arr_contractor[idx].scroll_flag = l_scroll_flag 
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF arr_curr() = arr_count() THEN 
					LET l_msgresp=kandoomsg("P",9001,"") 
					#9001 There are no more rows in the direction ...
					NEXT FIELD scroll_flag 
				ELSE 
					IF l_arr_contractor[idx+1].vend_code IS NULL THEN 
						LET l_msgresp=kandoomsg("P",9001,"") 
						#9001 There are no more rows in the direction ...
						NEXT FIELD scroll_flag 
					END IF 
				END IF 
			END IF 

		BEFORE FIELD vend_code 
			IF l_arr_contractor[idx].vend_code IS NOT NULL THEN 
				IF edit_contractor(l_arr_contractor[idx].vend_code) THEN 
					SELECT variation_text 
					INTO l_arr_contractor[idx].variation_text 
					FROM contractor 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND vend_code = l_arr_contractor[idx].vend_code 
				END IF 
			END IF 
			NEXT FIELD scroll_flag 

		BEFORE INSERT 
			IF arr_curr() < arr_count() THEN 
				LET l_rowid = edit_contractor("") 
				SELECT vend_code, 
				variation_text 
				INTO l_arr_contractor[idx].vend_code, 
				l_arr_contractor[idx].variation_text 
				FROM contractor 
				WHERE rowid = l_rowid 
				IF status = NOTFOUND THEN 
					#FOR idx = arr_curr() TO arr_count()
					#   LET l_arr_contractor[idx].* = l_arr_contractor[idx+1].*
					#   IF scrn <= 14 THEN
					#      DISPLAY l_arr_contractor[idx].*
					#           TO sr_contractor[scrn].*
					#
					#      LET scrn = scrn + 1
					#   END IF
					#END FOR
					#INITIALIZE l_arr_contractor[idx].* TO NULL
				ELSE 
					SELECT name_text 
					INTO l_arr_contractor[idx].name_text 
					FROM vendor 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND vend_code = l_arr_contractor[idx].vend_code 
				END IF 
			ELSE 
				IF idx > 1 THEN 
					LET l_msgresp = kandoomsg("P",9001,"") 
					#9001There are no more rows in the direction you are going
				END IF 
			END IF 

		ON KEY (F2) --delete 
			IF l_arr_contractor[idx].vend_code IS NOT NULL THEN 
				IF l_arr_contractor[idx].scroll_flag IS NULL THEN 
					LET l_arr_contractor[idx].scroll_flag = "*" 
					LET l_del_qty = l_del_qty + 1 
				ELSE 
					LET l_arr_contractor[idx].scroll_flag = NULL 
					LET l_del_qty = l_del_qty - 1 
				END IF 
			END IF 
			NEXT FIELD scroll_flag 

			#AFTER ROW
			#DISPLAY l_arr_contractor[idx].*
			#     TO sr_contractor[scrn].*



	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 
		IF l_del_qty != 0 THEN 
			LET l_msgresp = kandoomsg("P",8008,l_del_qty) 
			#8008 Confirm TO Delete ",l_del_qty,"Contractors ? (Y/N)"
			IF l_msgresp = "Y" THEN 
				FOR idx = 1 TO arr_count() 
					IF l_arr_contractor[idx].scroll_flag = "*" THEN 
						DELETE FROM contractor 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND vend_code = l_arr_contractor[idx].vend_code 
					END IF 
				END FOR 
			END IF 
		END IF 
	END IF 
END FUNCTION 




############################################################
# FUNCTION edit_contractor(p_vend_code)
#
#
############################################################
FUNCTION edit_contractor(p_vend_code) 
	DEFINE p_vend_code LIKE contractor.vend_code 
	DEFINE l_vendor_name LIKE vendor.name_text 
	DEFINE l_vendor_tax_no LIKE vendor.tax_text 
	DEFINE l_vendor_tax_text LIKE vendor.tax_text 
	DEFINE l_rec_contractor RECORD LIKE contractor.* 
	DEFINE l_rec_tax RECORD LIKE tax.*
	DEFINE l_temp_text CHAR(20)
	DEFINE l_msgresp LIKE language.yes_flag 

	IF pr_vend_code_arg IS NULL THEN 
		SELECT * INTO l_rec_contractor.* 
		FROM contractor 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND vend_code = p_vend_code 
	ELSE 
		SELECT * INTO l_rec_contractor.* 
		FROM contractor 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND vend_code = pr_vend_code_arg 
		IF status = NOTFOUND THEN 
			LET l_rec_contractor.vend_code = pr_vend_code_arg 
		ELSE 
			LET p_vend_code = pr_vend_code_arg 
		END IF 
	END IF 

	SELECT name_text, 
	tax_text 
	INTO l_vendor_name, 
	l_vendor_tax_no 
	FROM vendor 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND vend_code = l_rec_contractor.vend_code 

	OPEN WINDOW p157 with FORM "P157" 
	CALL windecoration_p("P157") 

	DISPLAY l_vendor_name TO vendor.name_text 

	IF p_vend_code IS NULL THEN 
		LET l_rec_contractor.start_date = today 
		DISPLAY BY NAME l_rec_contractor.start_date 
		LET l_rec_contractor.expiry_date = NULL 
		LET l_rec_contractor.var_start_date = NULL 
		LET l_rec_contractor.var_exp_date = NULL 
		LET l_rec_contractor.union_exp_date = NULL 
		LET l_rec_contractor.ins_exp_date = NULL 
	END IF 

	IF l_rec_contractor.tax_no_text IS NULL THEN 
		DISPLAY l_vendor_tax_no TO contractor.tax_no_text 

	END IF 
	LET l_msgresp=kandoomsg("P",1009,"") 
	#1009 Enter contractor details - ESC TO Continue

	DISPLAY BY NAME l_rec_contractor.tax_rate_qty 


	INPUT BY NAME l_rec_contractor.vend_code, 
	l_rec_contractor.start_date, 
	l_rec_contractor.home_phone_text, 
	l_rec_contractor.pager_comp_text, 
	l_rec_contractor.pager_num_text, 
	l_rec_contractor.licence_text, 
	l_rec_contractor.expiry_date, 
	l_rec_contractor.tax_no_text, 
	l_rec_contractor.regist_num_text, 
	l_rec_contractor.tax_code, 
	l_rec_contractor.variation_text, 
	l_rec_contractor.var_start_date, 
	l_rec_contractor.var_exp_date, 
	l_rec_contractor.union_text, 
	l_rec_contractor.union_num_text, 
	l_rec_contractor.union_exp_date, 
	l_rec_contractor.insurance_text, 
	l_rec_contractor.comp_num_text, 
	l_rec_contractor.ins_exp_date WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P91","inp-contractor-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON KEY (control-b) infield (vend_code) 

			LET l_temp_text = show_vend(glob_rec_kandoouser.cmpy_code,l_rec_contractor.vend_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_contractor.vend_code = l_temp_text 
				NEXT FIELD vend_code 
			END IF 

		ON KEY (control-b) infield (tax_code) 
			LET l_temp_text = show_tax(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_contractor.tax_code = l_temp_text 
				NEXT FIELD tax_code 
			END IF 

		BEFORE FIELD vend_code 
			IF p_vend_code IS NOT NULL OR 
			pr_vend_code_arg IS NOT NULL THEN 
				NEXT FIELD start_date 
			END IF 

		AFTER FIELD vend_code 
			IF l_rec_contractor.vend_code IS NULL THEN 
				LET l_msgresp = kandoomsg("P",9103,"") 
				#9103" Contractor must be entered
				NEXT FIELD vend_code 
			ELSE 
				SELECT unique 1 FROM contractor 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND vend_code = l_rec_contractor.vend_code 
				IF status = 0 THEN 
					LET l_msgresp = kandoomsg("P",9104,"") 
					#9104" Contractor already exists - Please Re Enter "
					NEXT FIELD vend_code 
				END IF 

				SELECT name_text, 
				tax_text 
				INTO l_vendor_name, 
				l_vendor_tax_text 
				FROM vendor 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND vend_code = l_rec_contractor.vend_code 
				IF status = NOTFOUND THEN 
					LET l_msgresp = kandoomsg("P",9105,"") 
					#9105" Vendor does NOT exist - Try Window "
					NEXT FIELD vend_code 
				ELSE 
					DISPLAY l_vendor_name TO vendor.name_text 

					LET l_rec_contractor.tax_no_text = l_vendor_tax_text 
					DISPLAY BY NAME l_rec_contractor.tax_no_text 

				END IF 
			END IF 

		AFTER FIELD tax_code 
			CLEAR contractor.tax_rate_qty 
			IF l_rec_contractor.tax_code IS NULL THEN 
				LET l_rec_contractor.tax_rate_qty = 0 
			ELSE 
				SELECT * INTO l_rec_tax.* 
				FROM tax 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND tax_code = l_rec_contractor.tax_code 
				IF status = NOTFOUND THEN 
					LET l_msgresp=kandoomsg("P",9106,"") 
					#9106 Tax Code NOT found - try window
					NEXT FIELD tax_code 
				ELSE 
					LET l_rec_contractor.tax_rate_qty = l_rec_tax.tax_per 
					DISPLAY BY NAME l_rec_contractor.tax_rate_qty 

				END IF 
			END IF 

		AFTER FIELD tax_no_text 
			IF l_rec_contractor.tax_no_text IS NULL THEN 
				LET l_msgresp = kandoomsg("P",9107,"") 
				#9107" Tax Text cannot be blank "
				LET l_rec_contractor.tax_no_text = l_vendor_tax_text 
				DISPLAY BY NAME l_rec_contractor.tax_no_text 

				NEXT FIELD tax_no_text 
			END IF 

		AFTER FIELD variation_text 
			IF l_rec_contractor.variation_text IS NULL AND 
			(l_rec_contractor.tax_code IS NULL OR 
			l_rec_contractor.tax_rate_qty = 0) THEN 
				LET l_msgresp=kandoomsg("P",9110,"") 
				#9110 Must have Variation No. TO be tax exempt
				NEXT FIELD tax_code 
			END IF 

		AFTER FIELD var_start_date 
			IF l_rec_contractor.variation_text IS NOT NULL AND 
			l_rec_contractor.var_start_date IS NULL THEN 
				LET l_msgresp = kandoomsg("P",9108,"") 
				#9108" Variation Start date cannot be blank "
				NEXT FIELD var_start_date 
			END IF 

		AFTER FIELD var_exp_date 
			IF l_rec_contractor.variation_text IS NOT NULL AND 
			l_rec_contractor.var_exp_date IS NULL THEN 
				LET l_msgresp = kandoomsg("P",9109,"") 
				#9109" Variation Expiry date cannot be blank "
				NEXT FIELD var_exp_date 
			END IF 
			IF l_rec_contractor.var_start_date > l_rec_contractor.var_exp_date THEN 
				LET l_msgresp = kandoomsg("P",9111,"") 
				#9111" Variation Start date AFTER Expiry date"
				NEXT FIELD var_start_date 
			END IF 


		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF l_rec_contractor.tax_code IS NULL THEN 
					LET l_rec_contractor.tax_rate_qty = 0 
				ELSE 
					SELECT * INTO l_rec_tax.* 
					FROM tax 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND tax_code = l_rec_contractor.tax_code 
					IF status = NOTFOUND THEN 
						LET l_msgresp=kandoomsg("P",9106,"") 
						#9106 Tax Code NOT found - try window
						NEXT FIELD tax_code 
					END IF 
					LET l_rec_contractor.tax_rate_qty = l_rec_tax.tax_per 
					DISPLAY BY NAME l_rec_contractor.tax_rate_qty 

				END IF 

				IF l_rec_contractor.tax_no_text IS NULL THEN 
					LET l_msgresp = kandoomsg("P",9107,"") 
					#9107" Tax Text cannot be blank "
					NEXT FIELD tax_no_text 
				END IF 

				IF l_rec_contractor.variation_text IS NULL AND 
				(l_rec_contractor.tax_code IS NULL OR 
				l_rec_contractor.tax_rate_qty = 0) THEN 
					LET l_msgresp=kandoomsg("P",9110,"") 
					#9110 Must have Variation No. TO be tax exempt
					NEXT FIELD tax_code 
				END IF 

				IF l_rec_contractor.variation_text IS NOT NULL AND 
				l_rec_contractor.var_start_date IS NULL THEN 
					LET l_msgresp = kandoomsg("P",9108,"") 
					#9108" Variation Start date cannot be blank "
					NEXT FIELD var_start_date 
				END IF 

				IF l_rec_contractor.variation_text IS NOT NULL AND 
				l_rec_contractor.var_exp_date IS NULL THEN 
					LET l_msgresp = kandoomsg("P",9109,"") 
					#9109" Variation Expiry date cannot be blank "
					NEXT FIELD var_exp_date 
				END IF 

				IF l_rec_contractor.var_start_date > l_rec_contractor.var_exp_date THEN 
					LET l_msgresp = kandoomsg("P",9111,"") 
					#9111" Variation Start date AFTER Expiry date"
					NEXT FIELD var_start_date 
				END IF 
			END IF 

	END INPUT 


	CLOSE WINDOW p157 

	OPTIONS INSERT KEY f1, 
	DELETE KEY f36 

	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
		RETURN false 
	ELSE 
		IF p_vend_code IS NULL THEN 
			LET l_rec_contractor.cmpy_code = glob_rec_kandoouser.cmpy_code 
			INSERT INTO contractor VALUES (l_rec_contractor.*) 
			RETURN sqlca.sqlerrd[6] 
		ELSE 
			UPDATE contractor 
			SET contractor.* = l_rec_contractor.* 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = p_vend_code 
			RETURN sqlca.sqlerrd[3] 
		END IF 
	END IF 

END FUNCTION 


