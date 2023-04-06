# Transaction Type Listing
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

	Source code beautified by beautify.pl on 2020-01-03 11:19:28	$Id: $
}
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/AZ_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/AZ7_J_GLOBALS.4gl" 

############################################################
# Module Scope Variables
############################################################
DEFINE modu_edit_trans_code LIKE jmj_trantype.trans_code 
DEFINE modu_edit_record_ind LIKE jmj_trantype.record_ind 
DEFINE modu_edit_imprest_ind LIKE jmj_trantype.imprest_ind 


##################################################################
# MAIN
#
#
##################################################################
MAIN 
	DEFINE l_withquery SMALLINT 

	CALL setModuleId("AZ7_J") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_a_ar() #init a/ar module 

	OPEN WINDOW wa230 with FORM "A230" 
	CALL windecoration_a("A230") 

	#if the the table has more than 1000 rows, force a query TO filter data
	IF db_jmj_trantype_get_count() > 1000 THEN 
		LET l_withquery = 1 
	END IF 

	WHILE select_jmj_trantype(l_withquery) 
		LET l_withquery = scan_jmj_trantype() 
		IF l_withquery = 2 OR int_flag THEN 
			EXIT WHILE 
		END IF 
	END WHILE 

	CLOSE WINDOW wa230 
END MAIN 


##################################################################
# FUNCTION select_jmj_trantype()
#
#
##################################################################
FUNCTION select_jmj_trantype(p_withquery) 
	DEFINE p_withquery SMALLINT 
	DEFINE l_query_text CHAR(500) 
	DEFINE l_where_text STRING 

	IF p_withquery = 1 THEN 

		CLEAR FORM 
		MESSAGE kandoomsg2("A",1001,"") 		#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON 
			trans_code, 
			desc_text, 
			cr_acct_code, 
			debt_type_code, 
			record_ind, 
			imprest_ind 


			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","AZ7_J","construct-trans") 

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

	MESSAGE kandoomsg2("A",1002,"") 	#1002 " Searching database - please wait"
	LET l_query_text = 
		"SELECT * FROM jmj_trantype ", 
		"WHERE cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
		"AND ", l_where_text clipped," ", 
		"ORDER BY jmj_trantype.trans_code, ", 
		"jmj_trantype.record_ind, ", 
		"jmj_trantype.imprest_ind" 

	PREPARE s_jmj_trantype FROM l_query_text 
	DECLARE c_jmj_trantype CURSOR FOR s_jmj_trantype 

	RETURN 1 
END FUNCTION 


##################################################################
# FUNCTION scan_jmj_trantype()
#
#
##################################################################
FUNCTION scan_jmj_trantype() 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_jmj_trantype RECORD LIKE jmj_trantype.* 
	DEFINE l_arr_rec_jmj_trantype DYNAMIC ARRAY OF RECORD # array[400] OF 
	 
		scroll_flag CHAR(1), 
		trans_code LIKE jmj_trantype.trans_code, 
		desc_text LIKE jmj_trantype.desc_text, 
		cr_acct_code LIKE jmj_trantype.cr_acct_code, 
		debt_type_code LIKE jmj_trantype.debt_type_code, 
		record_ind LIKE jmj_trantype.record_ind, 
		imprest_ind LIKE jmj_trantype.imprest_ind 
	END RECORD 
	DEFINE l_scroll_flag CHAR(1) 
	DEFINE l_curr SMALLINT --,scrn 
	DEFINE l_cnt SMALLINT --,scrn 
	DEFINE l_idx SMALLINT --,scrn 
	DEFINE l_del_cnt SMALLINT --,scrn 
	DEFINE l_rowid SMALLINT --,scrn 
	DEFINE l_x SMALLINT --,scrn 

	LET l_idx = 1 
	FOREACH c_jmj_trantype INTO l_rec_jmj_trantype.* 
		LET l_arr_rec_jmj_trantype[l_idx].trans_code = l_rec_jmj_trantype.trans_code 
		LET l_arr_rec_jmj_trantype[l_idx].desc_text = l_rec_jmj_trantype.desc_text 
		LET l_arr_rec_jmj_trantype[l_idx].cr_acct_code = l_rec_jmj_trantype.cr_acct_code 
		LET l_arr_rec_jmj_trantype[l_idx].debt_type_code = l_rec_jmj_trantype.debt_type_code 
		LET l_arr_rec_jmj_trantype[l_idx].record_ind = l_rec_jmj_trantype.record_ind 
		LET l_arr_rec_jmj_trantype[l_idx].imprest_ind = l_rec_jmj_trantype.imprest_ind 
		#      IF l_idx = 400 THEN
		#         ERROR kandoomsg2("A",6100,l_idx)
		#         EXIT FOREACH
		#      END IF
		LET l_idx = l_idx + 1 
	END FOREACH 

	ERROR kandoomsg2("U",9113,l_idx) 

	#   CALL set_count(l_idx)
	MESSAGE kandoomsg2("A",1003,"") 	#1003 "F1 TO Add - F2 TO Delete - RETURN TO Edit
	INPUT ARRAY l_arr_rec_jmj_trantype WITHOUT DEFAULTS FROM sr_jmj_trantype.* attribute(UNBUFFERED, auto append = false, APPEND ROW = false, INSERT ROW = false,delete ROW = false) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","AZ7_J","inp-arr-jmj_trantype-1") 

		BEFORE ROW 
			LET l_idx = arr_curr() 

		ON ACTION "FILTER" 
			RETURN 1 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE FIELD scroll_flag 
			LET l_idx = arr_curr() 
			#LET scrn = scr_line()
			LET l_scroll_flag = l_arr_rec_jmj_trantype[l_idx].scroll_flag 
			#DISPLAY l_arr_rec_jmj_trantype[l_idx].* TO sr_jmj_trantype[scrn].*

			#AFTER FIELD scroll_flag
			# LET l_arr_rec_jmj_trantype[l_idx].scroll_flag = l_scroll_flag
			# DISPLAY l_arr_rec_jmj_trantype[l_idx].scroll_flag
			#      TO sr_jmj_trantype[scrn].scroll_flag

			#IF fgl_lastkey() = fgl_keyval("down") THEN
			#   IF l_arr_rec_jmj_trantype[l_idx+1].trans_code IS NULL
			#   OR arr_curr() >= arr_count() THEN
			#      ERROR kandoomsg2("A",9001,"")			#      #9001 There no more rows...
			#      NEXT FIELD scroll_flag
			#   END IF
			#END IF

		ON ACTION ("EDIT","doubleClick","ACCEPT") --huho new - copy/paste BEFORE FIELD trans_code 
			IF l_arr_rec_jmj_trantype[l_idx].trans_code IS NOT NULL THEN 
				CALL edit_jmj_trantype(l_arr_rec_jmj_trantype[l_idx].trans_code, 
				l_arr_rec_jmj_trantype[l_idx].record_ind, 
				l_arr_rec_jmj_trantype[l_idx].imprest_ind) 
				SELECT * INTO l_rec_jmj_trantype.* FROM jmj_trantype 
				WHERE trans_code = modu_edit_trans_code 
				AND record_ind = modu_edit_record_ind 
				AND imprest_ind = modu_edit_imprest_ind 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_arr_rec_jmj_trantype[l_idx].trans_code=l_rec_jmj_trantype.trans_code 
				LET l_arr_rec_jmj_trantype[l_idx].desc_text=l_rec_jmj_trantype.desc_text 
				LET l_arr_rec_jmj_trantype[l_idx].cr_acct_code=l_rec_jmj_trantype.cr_acct_code 
				LET l_arr_rec_jmj_trantype[l_idx].debt_type_code=l_rec_jmj_trantype.debt_type_code 
				LET l_arr_rec_jmj_trantype[l_idx].record_ind=l_rec_jmj_trantype.record_ind 
				LET l_arr_rec_jmj_trantype[l_idx].imprest_ind=l_rec_jmj_trantype.imprest_ind 
				OPTIONS INSERT KEY f1, 
				DELETE KEY f36 
			END IF 
			#NEXT FIELD scroll_flag
			RETURN 0 --return TO refresh TABLE 

		BEFORE FIELD trans_code 
			IF l_arr_rec_jmj_trantype[l_idx].trans_code IS NOT NULL THEN 
				CALL edit_jmj_trantype(l_arr_rec_jmj_trantype[l_idx].trans_code, 
				l_arr_rec_jmj_trantype[l_idx].record_ind, 
				l_arr_rec_jmj_trantype[l_idx].imprest_ind) 
				SELECT * INTO l_rec_jmj_trantype.* FROM jmj_trantype 
				WHERE trans_code = modu_edit_trans_code 
				AND record_ind = modu_edit_record_ind 
				AND imprest_ind = modu_edit_imprest_ind 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_arr_rec_jmj_trantype[l_idx].trans_code=l_rec_jmj_trantype.trans_code 
				LET l_arr_rec_jmj_trantype[l_idx].desc_text=l_rec_jmj_trantype.desc_text 
				LET l_arr_rec_jmj_trantype[l_idx].cr_acct_code=l_rec_jmj_trantype.cr_acct_code 
				LET l_arr_rec_jmj_trantype[l_idx].debt_type_code=l_rec_jmj_trantype.debt_type_code 
				LET l_arr_rec_jmj_trantype[l_idx].record_ind=l_rec_jmj_trantype.record_ind 
				LET l_arr_rec_jmj_trantype[l_idx].imprest_ind=l_rec_jmj_trantype.imprest_ind 
				OPTIONS INSERT KEY f1, 
				DELETE KEY f36 
			END IF 
			NEXT FIELD scroll_flag 

		ON ACTION "ADD" --before INSERT 
			#IF arr_curr() < l_arr_rec_jmj_trantype.getLength() THEN #arr_count() THEN
			LET l_curr = arr_curr() 
			LET l_cnt = arr_count() 
			LET l_rowid = insert_jmj_trantype("","","") 
			IF l_rowid = 0 THEN 
				FOR l_idx = l_curr TO l_cnt 
					LET l_arr_rec_jmj_trantype[l_idx].* = l_arr_rec_jmj_trantype[l_idx+1].* 
					# IF scrn <= 10 THEN
					#    DISPLAY l_arr_rec_jmj_trantype[l_idx].* TO sr_jmj_trantype[scrn].*
					#
					#    LET scrn = scrn + 1
					# END IF
				END FOR 
				INITIALIZE l_arr_rec_jmj_trantype[l_idx].* TO NULL 
			ELSE 
				SELECT * INTO l_rec_jmj_trantype.* FROM jmj_trantype 
				WHERE rowid = l_rowid 
				LET l_arr_rec_jmj_trantype[l_idx].trans_code=l_rec_jmj_trantype.trans_code 
				LET l_arr_rec_jmj_trantype[l_idx].desc_text=l_rec_jmj_trantype.desc_text 
				LET l_arr_rec_jmj_trantype[l_idx].cr_acct_code=l_rec_jmj_trantype.cr_acct_code 
				LET l_arr_rec_jmj_trantype[l_idx].debt_type_code=l_rec_jmj_trantype.debt_type_code 
				LET l_arr_rec_jmj_trantype[l_idx].record_ind = l_rec_jmj_trantype.record_ind 
				LET l_arr_rec_jmj_trantype[l_idx].imprest_ind=l_rec_jmj_trantype.imprest_ind 
			END IF 
			#         ELSE
			#            IF l_idx > 1 THEN
			#               ERROR kandoomsg2("A",9001,"")			#               #9001 There are no more rows....
			#END IF

			RETURN 0 --return TO refresh TABLE 
			#END IF

		ON ACTION "DELETE" --on KEY (F2) --delete 
			IF l_arr_rec_jmj_trantype[l_idx].scroll_flag IS NULL THEN 
				LET l_arr_rec_jmj_trantype[l_idx].scroll_flag = "*" 
				LET l_del_cnt = l_del_cnt + 1 
			ELSE 
				LET l_arr_rec_jmj_trantype[l_idx].scroll_flag = NULL 
				LET l_del_cnt = l_del_cnt - 1 
			END IF 
			NEXT FIELD scroll_flag 
			#AFTER ROW
			#   DISPLAY l_arr_rec_jmj_trantype[l_idx].* TO sr_jmj_trantype[scrn].*


	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 2 --exit 
	ELSE 
		IF l_del_cnt > 0 THEN 
			
			IF kandoomsg("A",8022,l_del_cnt) = "Y" THEN #8022 Confirm TO Delete ",l_del_cnt," Transaction Type(s)? (Y/N)"
				FOR l_idx = 1 TO arr_count() 
					IF l_arr_rec_jmj_trantype[l_idx].scroll_flag = "*" THEN 
						DELETE FROM jmj_trantype 
						WHERE trans_code = l_arr_rec_jmj_trantype[l_idx].trans_code 
						AND record_ind = l_arr_rec_jmj_trantype[l_idx].record_ind 
						AND imprest_ind = l_arr_rec_jmj_trantype[l_idx].imprest_ind 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					END IF 
				END FOR 
			END IF 
		END IF 
		RETURN 0 --return TO refresh TABLE 
	END IF 
END FUNCTION 


##################################################################
# FUNCTION show_debt()
#
#
##################################################################
FUNCTION show_debt() 
	DEFINE l_rec_jmjdebttype RECORD LIKE jmj_debttype.* 
	DEFINE l_arr_rec_jmjdebttype array[100] OF RECORD 
		scroll_flag CHAR(1), 
		debt_type_code LIKE jmj_debttype.debt_type_code, 
		desc_text LIKE jmj_debttype.desc_text 
	END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_query_text CHAR(700) 
	DEFINE l_where_text CHAR(300) 

	OPEN WINDOW A223 with FORM "A223" 
	CALL windecoration_a("A223") 

	CLEAR FORM 
	MESSAGE kandoomsg2("A",1001,"") 	#1001 " Enter Selection Criteria - ESC TO Continue"
	CONSTRUCT BY NAME l_where_text ON debt_type_code, 
	desc_text 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		CLOSE WINDOW A223 
		RETURN "" 
	END IF 
	
	MESSAGE kandoomsg2("A",1002,"") 	#1002 " Searching database - please wait"
	LET l_query_text = 
		"SELECT * ", 
		"FROM jmj_debttype ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY debt_type_code" 

	PREPARE s_debttype FROM l_query_text 
	DECLARE c_debttype CURSOR FOR s_debttype 

	LET l_idx = 0 
	FOREACH c_debttype INTO l_rec_jmjdebttype.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_jmjdebttype[l_idx].debt_type_code = l_rec_jmjdebttype.debt_type_code 
		LET l_arr_rec_jmjdebttype[l_idx].desc_text = l_rec_jmjdebttype.desc_text 
		IF l_idx = 100 THEN 
			ERROR "First 100 Debt Types selected only" 
			EXIT FOREACH 
		END IF 
	END FOREACH 

--	IF l_idx = 0 THEN 
--		ERROR "No Debt Types satisfied criteria" 
--		LET l_idx = 1 
--		INITIALIZE l_arr_rec_jmjdebttype[1].* TO NULL 
--	END IF 
	MESSAGE kandoomsg2("A",1008,"")	#1008 F3/F4 TO page Fwd/Bwd - ESC TO Continue
	CALL set_count(l_idx) 

	INPUT ARRAY l_arr_rec_jmjdebttype WITHOUT DEFAULTS FROM sr_jmjdebttype.* ATTRIBUTE(UNBUFFERED) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","AZ7_J","inp-arr-jmjdebttype-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			#LET scrn = scr_line()
			IF l_arr_rec_jmjdebttype[l_idx].debt_type_code IS NOT NULL THEN 
				#DISPLAY l_arr_rec_jmjdebttype[l_idx].*
				#     TO sr_jmjdebttype[scrn].*

			END IF 
			NEXT FIELD scroll_flag 
			
		AFTER FIELD scroll_flag 
			LET l_arr_rec_jmjdebttype[l_idx].scroll_flag = NULL 
			IF fgl_lastkey() = fgl_keyval("down") 
			AND arr_curr() >= arr_count() THEN 
				ERROR kandoomsg2("A",9001,"") 
				NEXT FIELD scroll_flag 
			END IF 
			
		BEFORE FIELD debt_type_code 
			LET l_rec_jmjdebttype.debt_type_code = 		l_arr_rec_jmjdebttype[l_idx].debt_type_code 
			EXIT INPUT 
			#AFTER ROW
			#   DISPLAY l_arr_rec_jmjdebttype[l_idx].*
			#        TO sr_jmjdebttype[scrn].*

		AFTER INPUT 
			LET l_rec_jmjdebttype.debt_type_code = 
			l_arr_rec_jmjdebttype[l_idx].debt_type_code 

	END INPUT 

	CLOSE WINDOW A223 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN "" 
	ELSE 
		RETURN l_rec_jmjdebttype.debt_type_code 
	END IF 

END FUNCTION 



##################################################################
# FUNCTION edit_jmj_trantype(p_trans_code,p_record_ind,p_imprest_ind)
#
#
##################################################################
FUNCTION edit_jmj_trantype(p_trans_code,p_record_ind,p_imprest_ind) 
	DEFINE p_trans_code LIKE jmj_trantype.trans_code 
	DEFINE p_record_ind LIKE jmj_trantype.record_ind 
	DEFINE p_imprest_ind LIKE jmj_trantype.imprest_ind 

	DEFINE l_rec_s_jmj_trantype RECORD LIKE jmj_trantype.* 
	DEFINE l_rec_jmj_trantype RECORD LIKE jmj_trantype.* 
	DEFINE l_rec_jmj_debttype RECORD LIKE jmj_debttype.* 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_next_trans_code LIKE jmj_trantype.trans_code 
	DEFINE l_winds_text CHAR(40) 
	DEFINE l_db_type_text LIKE jmj_debttype.desc_text 
	DEFINE l_db_acct_text LIKE coa.desc_text 
	DEFINE l_cr_acct_text LIKE coa.desc_text 

	DEFINE l_sqlerrd INTEGER 

	INITIALIZE l_rec_jmj_trantype.* TO NULL 
	IF p_trans_code IS NOT NULL THEN 
		SELECT * INTO l_rec_jmj_trantype.* FROM jmj_trantype 
		WHERE trans_code = p_trans_code 
		AND record_ind = p_record_ind 
		AND imprest_ind = p_imprest_ind 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		SELECT * INTO l_rec_jmj_debttype.* FROM jmj_debttype 
		WHERE debt_type_code = l_rec_jmj_trantype.debt_type_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_db_type_text = l_rec_jmj_debttype.desc_text 
		SELECT desc_text INTO l_db_acct_text FROM coa 
		WHERE acct_code = l_rec_jmj_trantype.db_acct_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		SELECT desc_text INTO l_cr_acct_text FROM coa 
		WHERE acct_code = l_rec_jmj_trantype.cr_acct_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	ELSE 
		LET l_rec_jmj_trantype.cmpy_code = glob_rec_kandoouser.cmpy_code 
	END IF 

	OPEN WINDOW A231 with FORM "A231" 
	CALL windecoration_a("A231") 

	DISPLAY l_rec_jmj_trantype.trans_code TO trans_code 
	DISPLAY l_rec_jmj_trantype.desc_text TO desc_text 
	DISPLAY l_rec_jmj_trantype.debt_type_code TO debt_type_code 
	DISPLAY l_db_type_text TO db_type_text 
	DISPLAY l_rec_jmj_trantype.cr_acct_code TO cr_acct_code 
	DISPLAY l_cr_acct_text TO cr_acct_text 
	DISPLAY l_rec_jmj_trantype.db_acct_code TO db_acct_code 
	DISPLAY l_db_acct_text TO db_acct_text
	DISPLAY l_rec_jmj_trantype.record_ind TO record_ind
	DISPLAY l_rec_jmj_trantype.imprest_ind TO imprest_ind


	INPUT BY NAME l_rec_jmj_trantype.trans_code, 
	l_rec_jmj_trantype.desc_text, 
	l_rec_jmj_trantype.debt_type_code, 
	l_rec_jmj_trantype.cr_acct_code, 
	l_rec_jmj_trantype.db_acct_code, 
	l_rec_jmj_trantype.record_ind, 
	l_rec_jmj_trantype.imprest_ind WITHOUT DEFAULTS 


		BEFORE INPUT 
			CALL publish_toolbar("kandoo","AZ7_J","inp-jmj_trantype-2") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (debt_type_code) 


			LET l_winds_text = NULL 
			LET l_winds_text = show_debt() 
			IF l_winds_text IS NOT NULL THEN 
				LET l_rec_jmj_trantype.debt_type_code = l_winds_text 
				SELECT * INTO l_rec_jmj_debttype.* 
				FROM jmj_debttype 
				WHERE debt_type_code = l_rec_jmj_trantype.debt_type_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_db_type_text = l_rec_jmj_debttype.desc_text 
				DISPLAY l_rec_jmj_trantype.debt_type_code TO debt_type_code 
				DISPLAY l_db_type_text TO db_type_text 

			END IF 
			NEXT FIELD debt_type_code 

		ON ACTION "LOOKUP" infield (cr_acct_code) 

			LET l_winds_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF l_winds_text IS NOT NULL THEN 
				LET l_rec_jmj_trantype.cr_acct_code = l_winds_text clipped 
				DISPLAY l_rec_jmj_trantype.cr_acct_code TO cr_acct_code 

			END IF 

		ON ACTION "LOOKUP" infield (db_acct_code) 
			LET l_winds_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF l_winds_text IS NOT NULL THEN 
				LET l_rec_jmj_trantype.db_acct_code = l_winds_text clipped 
				DISPLAY l_rec_jmj_trantype.db_acct_code TO db_acct_code

			END IF 


		BEFORE FIELD trans_code 
			ERROR kandoomsg2("A",1075,"") 			#1075 " Enter Transaction Type Details
			IF p_trans_code IS NOT NULL THEN 
				NEXT FIELD desc_text 
			END IF 

		AFTER FIELD trans_code 
			IF l_rec_jmj_trantype.trans_code IS NULL THEN 
				ERROR kandoomsg2("A",9227,"") 				#9227 " Transaction Type Code must be entered
				NEXT FIELD trans_code 
			END IF 
		AFTER FIELD desc_text 
			IF l_rec_jmj_trantype.desc_text IS NULL THEN 
				ERROR kandoomsg2("A",9101,"") 				#9101 Transaction Type Description must be entered
				NEXT FIELD desc_text 
			END IF 

		AFTER FIELD debt_type_code 
			IF l_rec_jmj_trantype.debt_type_code IS NULL THEN 
				ERROR kandoomsg2("A",9225,"") 				#9225 Debt Type must be entered
				NEXT FIELD debt_type_code 
			ELSE 
				SELECT * INTO l_rec_jmj_debttype.* FROM jmj_debttype 
				WHERE debt_type_code = l_rec_jmj_trantype.debt_type_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("A",9228,"") 					#9228 Debt Type NOT found - Try window
					NEXT FIELD debt_type_code 
				ELSE 
					LET l_db_type_text = l_rec_jmj_debttype.desc_text 
					DISPLAY l_db_type_text TO db_type_text

				END IF 
			END IF 

		AFTER FIELD cr_acct_code 
			IF l_rec_jmj_trantype.cr_acct_code IS NULL THEN 
				ERROR kandoomsg2("A",9229,"") 				#9229 Credit Account must be entered
				NEXT FIELD cr_acct_code 
			ELSE 
				SELECT * INTO l_rec_coa.* FROM coa 
				WHERE acct_code = l_rec_jmj_trantype.cr_acct_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("A",9230,"") 					#9230 Credit Account does NOT exist - Try Window
					NEXT FIELD cr_acct_code 
				END IF 
				IF NOT acct_type(glob_rec_kandoouser.cmpy_code, l_rec_jmj_trantype.cr_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
					NEXT FIELD cr_acct_code 
				END IF 
				LET l_cr_acct_text = l_rec_coa.desc_text 
				DISPLAY l_cr_acct_text TO cr_acct_text

			END IF 

		AFTER FIELD db_acct_code 
			IF l_rec_jmj_trantype.db_acct_code IS NULL THEN 
				ERROR kandoomsg2("A",9231,"") 				#9231 Debit Account must be entered
				NEXT FIELD db_acct_code 
			ELSE 
				SELECT * INTO l_rec_coa.* FROM coa 
				WHERE acct_code = l_rec_jmj_trantype.db_acct_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("A",9232,"") 					#9232 Debit Account does NOT exist - Try Window
					NEXT FIELD db_acct_code 
				END IF 
				IF NOT acct_type(glob_rec_kandoouser.cmpy_code,l_rec_jmj_trantype.db_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
					NEXT FIELD db_acct_code 
				END IF 
				LET l_cr_acct_text = l_rec_coa.desc_text 
				DISPLAY l_db_acct_text TO db_acct_text

			END IF 
		AFTER FIELD record_ind 
			IF l_rec_jmj_trantype.record_ind IS NULL 
			OR l_rec_jmj_trantype.record_ind NOT matches "[ABC]" THEN 
				ERROR kandoomsg2("U",9102,"") 
				NEXT FIELD record_ind 
			END IF 

		AFTER FIELD imprest_ind 
			IF l_rec_jmj_trantype.imprest_ind IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 
				NEXT FIELD imprest_ind 
			END IF 

		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF p_trans_code IS NOT NULL THEN 
					IF l_rec_jmj_trantype.trans_code IS NULL THEN 
						ERROR kandoomsg2("A",9227,"") 						#9227 " Transaction Type Code must be entered
						NEXT FIELD trans_code 
					END IF 
				END IF 
				IF l_rec_jmj_trantype.desc_text IS NULL THEN 
					ERROR kandoomsg2("A",9101,"") 					#9101 Description must be entered
					NEXT FIELD desc_text 
				END IF 
				
				IF l_rec_jmj_trantype.debt_type_code IS NULL THEN 
					ERROR kandoomsg2("A",9225,"") 					#9225 " Debt Type must be entered
					NEXT FIELD debt_type_code 
				END IF 
				
				IF l_rec_jmj_trantype.cr_acct_code IS NULL THEN 
					ERROR kandoomsg2("A",9229,"") 					#9229 Credit Account must be entered
					NEXT FIELD cr_acct_code 
				END IF 
				
				IF NOT acct_type(glob_rec_kandoouser.cmpy_code, l_rec_jmj_trantype.cr_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
					NEXT FIELD cr_acct_code 
				END IF 
				
				IF l_rec_jmj_trantype.db_acct_code IS NULL THEN 
					ERROR kandoomsg2("A",9231,"") 					#9231 Debit Account must be entered
					NEXT FIELD db_acct_code 
				END IF 
				
				IF NOT acct_type(glob_rec_kandoouser.cmpy_code, l_rec_jmj_trantype.db_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
					NEXT FIELD db_acct_code 
				END IF 
				
				IF l_rec_jmj_trantype.record_ind NOT matches "[ABC]"	OR l_rec_jmj_trantype.record_ind IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") 
					NEXT FIELD record_ind 
				END IF 
				
				IF l_rec_jmj_trantype.imprest_ind IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") 
					NEXT FIELD imprest_ind 
				END IF 
				
				SELECT * INTO l_rec_s_jmj_trantype.* FROM jmj_trantype 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND trans_code = l_rec_jmj_trantype.trans_code 
				AND record_ind = l_rec_jmj_trantype.record_ind 
				AND imprest_ind = l_rec_jmj_trantype.imprest_ind 
				IF p_trans_code IS NULL THEN 
					IF status != NOTFOUND THEN 
						ERROR kandoomsg2("A",9233,"") 						#9233 Transaction Type Code already exists
						NEXT FIELD trans_code 
					END IF 
				ELSE 
					IF l_rec_jmj_trantype.trans_code != p_trans_code THEN 
						IF status != NOTFOUND THEN 
							ERROR kandoomsg2("A",9233,"") 				#9233 Transaction Type Code already exists
							NEXT FIELD trans_code 
						END IF 
					END IF 
				END IF 
				
				UPDATE jmj_trantype 
				SET * = l_rec_jmj_trantype.* 
				WHERE trans_code = p_trans_code 
				AND record_ind = p_record_ind 
				AND imprest_ind = p_imprest_ind 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
	END IF 


	CLOSE WINDOW A231 

	LET modu_edit_trans_code = l_rec_jmj_trantype.trans_code 
	LET modu_edit_record_ind = l_rec_jmj_trantype.record_ind 
	LET modu_edit_imprest_ind = l_rec_jmj_trantype.imprest_ind 

END FUNCTION 


##################################################################
# FUNCTION insert_jmj_trantype(p_trans_code,p_record_ind,p_imprest_ind)
#
#
##################################################################
FUNCTION insert_jmj_trantype(p_trans_code,p_record_ind,p_imprest_ind) 
	DEFINE p_trans_code LIKE jmj_trantype.trans_code 
	DEFINE p_record_ind LIKE jmj_trantype.record_ind 
	DEFINE p_imprest_ind LIKE jmj_trantype.imprest_ind 

	DEFINE l_rec_s_jmj_trantype RECORD LIKE jmj_trantype.* 
	DEFINE l_rec_jmj_trantype RECORD LIKE jmj_trantype.* 
	DEFINE l_rec_jmj_debttype RECORD LIKE jmj_debttype.* 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_next_trans_code LIKE jmj_trantype.trans_code 
	DEFINE l_winds_text CHAR(40) 
	DEFINE l_db_type_text LIKE jmj_debttype.desc_text 
	DEFINE l_db_acct_text LIKE coa.desc_text 
	DEFINE l_cr_acct_text LIKE coa.desc_text 
	DEFINE l_sqlerrd INTEGER 
	DEFINE l_err_message CHAR(40) 

	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	INITIALIZE l_rec_jmj_trantype.* TO NULL 
	IF p_trans_code IS NOT NULL THEN 
		SELECT * INTO l_rec_jmj_trantype.* FROM jmj_trantype 
		WHERE trans_code = p_trans_code 
		AND record_ind = p_record_ind 
		AND imprest_ind = p_imprest_ind 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 

		SELECT * INTO l_rec_jmj_debttype.* FROM jmj_debttype 
		WHERE debt_type_code = l_rec_jmj_trantype.debt_type_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_db_type_text = l_rec_jmj_debttype.desc_text 

		SELECT desc_text INTO l_db_acct_text FROM coa 
		WHERE acct_code = l_rec_jmj_trantype.db_acct_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 

		SELECT desc_text INTO l_cr_acct_text FROM coa 
		WHERE acct_code = l_rec_jmj_trantype.cr_acct_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	ELSE 
		LET l_rec_jmj_trantype.cmpy_code = glob_rec_kandoouser.cmpy_code 
	END IF 

	OPEN WINDOW A231 with FORM "A231" 
	CALL windecoration_a("A231") 

	DISPLAY 
	l_rec_jmj_trantype.trans_code, 
	l_rec_jmj_trantype.desc_text, 
	l_rec_jmj_trantype.debt_type_code, 
	l_db_type_text, 
	l_rec_jmj_trantype.cr_acct_code, 
	l_cr_acct_text, 
	l_rec_jmj_trantype.db_acct_code, 
	l_db_acct_text, 
	l_rec_jmj_trantype.record_ind, 
	l_rec_jmj_trantype.imprest_ind 
	TO 
	trans_code, 
	desc_text, 
	debt_type_code, 
	l_db_type_text, 
	cr_acct_code, 
	l_cr_acct_text, 
	db_acct_code, 
	l_db_acct_text, 
	record_ind, 
	imprest_ind 


	INPUT BY NAME l_rec_jmj_trantype.trans_code, 
	l_rec_jmj_trantype.desc_text, 
	l_rec_jmj_trantype.debt_type_code, 
	l_rec_jmj_trantype.cr_acct_code, 
	l_rec_jmj_trantype.db_acct_code, 
	l_rec_jmj_trantype.record_ind, 
	l_rec_jmj_trantype.imprest_ind WITHOUT DEFAULTS 


		BEFORE INPUT 
			CALL publish_toolbar("kandoo","AZ7_J","inp-jmj_trantype-3") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (debt_type_code) 
			LET l_winds_text = NULL 
			LET l_winds_text = show_debt() 
			IF l_winds_text IS NOT NULL THEN 
				LET l_rec_jmj_trantype.debt_type_code = l_winds_text 
				SELECT * INTO l_rec_jmj_debttype.* 
				FROM jmj_debttype 
				WHERE debt_type_code = l_rec_jmj_trantype.debt_type_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_db_type_text = l_rec_jmj_debttype.desc_text 
				DISPLAY l_rec_jmj_trantype.debt_type_code TO debt_type_code 
				DISPLAY l_db_type_text TO db_type_text

			END IF 
			NEXT FIELD debt_type_code 

		ON ACTION "LOOKUP" infield (cr_acct_code) 
			LET l_winds_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF l_winds_text IS NOT NULL THEN 
				LET l_rec_jmj_trantype.cr_acct_code = l_winds_text clipped 
				DISPLAY BY NAME l_rec_jmj_trantype.cr_acct_code 

			END IF 

		ON ACTION "LOOKUP" infield (db_acct_code) 
			LET l_winds_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF l_winds_text IS NOT NULL THEN 
				LET l_rec_jmj_trantype.db_acct_code = l_winds_text clipped 
				DISPLAY BY NAME l_rec_jmj_trantype.db_acct_code 

			END IF 


		BEFORE FIELD trans_code 
			ERROR kandoomsg2("A",1075,"") 			#1075 " Enter Transaction Type Details
			IF p_trans_code IS NOT NULL THEN 
				NEXT FIELD desc_text 
			END IF 

		AFTER FIELD trans_code 
			IF l_rec_jmj_trantype.trans_code IS NULL THEN 
				ERROR kandoomsg2("A",9227,"") 				#9227 " Transaction Type Code must be entered
				NEXT FIELD trans_code 
			END IF 

		AFTER FIELD desc_text 
			IF l_rec_jmj_trantype.desc_text IS NULL THEN 
				ERROR kandoomsg2("A",9101,"") 				#9101 Transaction Type Description must be entered
				NEXT FIELD desc_text 
			END IF 

		AFTER FIELD debt_type_code 
			IF l_rec_jmj_trantype.debt_type_code IS NULL THEN 
				ERROR kandoomsg2("A",9225,"") 				#9225 Debt Type must be entered
				NEXT FIELD debt_type_code 
			ELSE 
				SELECT * INTO l_rec_jmj_debttype.* FROM jmj_debttype 
				WHERE debt_type_code = l_rec_jmj_trantype.debt_type_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("A",9228,"") 					#9228 Debt Type NOT found - Try window
					NEXT FIELD debt_type_code 
				ELSE 
					LET l_db_type_text = l_rec_jmj_debttype.desc_text 
					DISPLAY l_db_type_text  TO db_type_text

				END IF 
			END IF 

		AFTER FIELD cr_acct_code 
			IF l_rec_jmj_trantype.cr_acct_code IS NULL THEN 
				ERROR kandoomsg2("A",9229,"") 				#9229 Credit Account must be entered
				NEXT FIELD cr_acct_code 
			ELSE 
				SELECT * INTO l_rec_coa.* FROM coa 
				WHERE acct_code = l_rec_jmj_trantype.cr_acct_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("A",9230,"") 					#9230 Credit Account does NOT exist - Try Window
					NEXT FIELD cr_acct_code 
				END IF 
				IF NOT acct_type(glob_rec_kandoouser.cmpy_code,l_rec_jmj_trantype.cr_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
					NEXT FIELD cr_acct_code 
				END IF 
				LET l_cr_acct_text = l_rec_coa.desc_text 
				DISPLAY l_cr_acct_text TO cr_acct_text

			END IF 

		AFTER FIELD db_acct_code 
			IF l_rec_jmj_trantype.db_acct_code IS NULL THEN 
				ERROR kandoomsg2("A",9231,"") 				#9231 Debit Account must be entered
				NEXT FIELD db_acct_code 
			ELSE 
				SELECT * INTO l_rec_coa.* FROM coa 
				WHERE acct_code = l_rec_jmj_trantype.db_acct_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("A",9232,"") 					#9232 Debit Account does NOT exist - Try Window
					NEXT FIELD db_acct_code 
				END IF 
				IF NOT acct_type(glob_rec_kandoouser.cmpy_code,l_rec_jmj_trantype.db_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
					NEXT FIELD db_acct_code 
				END IF 
				LET l_cr_acct_text = l_rec_coa.desc_text 
				DISPLAY l_db_acct_text TO db_acct_text

			END IF 

		AFTER FIELD record_ind 
			IF l_rec_jmj_trantype.record_ind IS NULL 
			OR l_rec_jmj_trantype.record_ind NOT matches "[ABC]" THEN 
				ERROR kandoomsg2("U",9102,"") 
				NEXT FIELD record_ind 
			END IF 

		AFTER FIELD imprest_ind 
			IF l_rec_jmj_trantype.imprest_ind IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 
				NEXT FIELD imprest_ind 
			END IF 

		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF p_trans_code IS NOT NULL THEN 
					IF l_rec_jmj_trantype.trans_code IS NULL THEN 
						ERROR kandoomsg2("A",9227,"") 						#9227 " Transaction Type Code must be entered
						NEXT FIELD trans_code 
					END IF 
				END IF 
				IF l_rec_jmj_trantype.desc_text IS NULL THEN 
					ERROR kandoomsg2("A",9101,"") 					#9101 Description must be entered
					NEXT FIELD desc_text 
				END IF 
				IF l_rec_jmj_trantype.debt_type_code IS NULL THEN 
					ERROR kandoomsg2("A",9225,"") 					#9225 " Debt Type must be entered
					NEXT FIELD debt_type_code 
				END IF 
				IF l_rec_jmj_trantype.cr_acct_code IS NULL THEN 
					ERROR kandoomsg2("A",9229,"") 					#9229 Credit Account must be entered
					NEXT FIELD cr_acct_code 
				END IF 
				IF NOT acct_type(glob_rec_kandoouser.cmpy_code,l_rec_jmj_trantype.cr_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
					NEXT FIELD cr_acct_code 
				END IF 
				IF l_rec_jmj_trantype.db_acct_code IS NULL THEN 
					ERROR kandoomsg2("A",9231,"") 					#9231 Debit Account must be entered
					NEXT FIELD db_acct_code 
				END IF 
				IF NOT acct_type(glob_rec_kandoouser.cmpy_code,l_rec_jmj_trantype.db_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
					NEXT FIELD db_acct_code 
				END IF 
				IF l_rec_jmj_trantype.record_ind NOT matches "[ABC]" 
				OR l_rec_jmj_trantype.record_ind IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") 
					NEXT FIELD record_ind 
				END IF 
				IF l_rec_jmj_trantype.imprest_ind IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") 
					NEXT FIELD imprest_ind 
				END IF 
				SELECT * INTO l_rec_s_jmj_trantype.* FROM jmj_trantype 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND trans_code = l_rec_jmj_trantype.trans_code 
				AND record_ind = l_rec_jmj_trantype.record_ind 
				AND imprest_ind = l_rec_jmj_trantype.imprest_ind 
				IF p_trans_code IS NULL THEN 
					IF status != NOTFOUND THEN 
						ERROR kandoomsg2("A",9233,"") 						#9233 Transaction Type Code already exists
						NEXT FIELD trans_code 
					END IF 
				ELSE 
					IF l_rec_jmj_trantype.trans_code != p_trans_code THEN 
						IF status != NOTFOUND THEN 
							ERROR kandoomsg2("A",9233,"") 							#9233 Transaction Type Code already exists
							NEXT FIELD trans_code 
						END IF 
					END IF 
				END IF 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
		CLOSE WINDOW A231 
		RETURN false 
	END IF 

	GOTO bypass 
	LABEL recovery: 
	IF error_recover(l_err_message, status) = "N" THEN 
		CLOSE WINDOW A231 
		RETURN false 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	BEGIN WORK 
		LET l_err_message = "AZ7 - Inserting jmj_trantype" 
		INSERT INTO jmj_trantype VALUES (l_rec_jmj_trantype.*) 
		LET l_sqlerrd = sqlca.sqlerrd[6] 
	COMMIT WORK 

	CLOSE WINDOW A231 

	RETURN l_sqlerrd 
END FUNCTION 


