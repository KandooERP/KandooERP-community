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

# \brief module G26 allows the user TO view Journal Batch details FROM scan info
#         also taking arguments IF passed

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"
GLOBALS "../gl/G_GL_GLOBALS.4gl" 

###########################################################################
# MODULE Scope Variables
###########################################################################
--DEFINE modu_query_from_argument BOOLEAN
DEFINE modu_sel_text_used boolean #sql query argument will only be used once 

###########################################################################
# MAIN
#
# module G26 allows the user TO view Journal Batch details
# FROM scan info also taking arguments IF passed
#
# Feature Request by AnBl: add menu options to launch new and post
###########################################################################
MAIN 
	DEFINE i int 

	CALL setModuleId("G26") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 

	IF get_debug() THEN 
		FOR i = 0 TO num_args() #debug info 
			DISPLAY "arg_val(", trim(i), ")=", trim(arg_val(i)) 
		END FOR 
	END IF 

	OPEN WINDOW G154 with FORM "G154" 
	CALL windecoration_g("G154") 

	CALL getbatch() 

	#	WHILE TRUE
	#		IF NOT getbatch() THEN
	#			EXIT WHILE
	#		END IF
	#	END WHILE

	CLOSE WINDOW G154 
END MAIN 
###########################################################################
# END MAIN
###########################################################################


############################################################
# FUNCTION getBatchHead_DataSource(p_filter)
#
#
############################################################
FUNCTION getbatchhead_datasource(p_filter) 
	DEFINE p_filter boolean 
	DEFINE p_query_text STRING
	DEFINE l_query_text STRING
	DEFINE l_rec_batchhead RECORD LIKE batchhead.* 
	DEFINE l_arr_rec_batchhead DYNAMIC ARRAY OF t_rec_batchhead_jc_cn_cd_ec_si_yn_pn_da_ca_pf 
	--	DEFINE l_arr_rec_batchhead DYNAMIC ARRAY OF RECORD --ARRAY[205] OF
	--			jour_code LIKE batchhead.jour_code,
	--			jour_num LIKE batchhead.jour_num,
	--			entry_code LIKE batchhead.entry_code,
	--			source_ind LIKE batchhead.source_ind,
	--			year_num LIKE batchhead.year_num,
	--			period_num LIKE batchhead.period_num,
	--			for_debit_amt LIKE batchhead.for_debit_amt,
	--			for_credit_amt LIKE batchhead.for_credit_amt,
	--			post_flag LIKE batchhead.post_flag
	--		END RECORD
	DEFINE l_where_part VARCHAR(2000) 
--	DEFINE l_sel_text VARCHAR(2000) 
	DEFINE l_idx SMALLINT 
	DEFINE l_sel_text_set boolean 
	DEFINE l_msgresp LIKE language.yes_flag 

	#IF we get the string via the URL, we will use it
	#classic arg() is always a problem becaus we send many many arguments
	#	DISPLAY "get_url_str1()=", get_url_str1()


	--	IF (modu_sel_text_used = FALSE) AND (get_url_query_text() IS NOT NULL) THEN
	--		LET l_sel_text = get_url_query_text()
	--		LET modu_sel_text_used = TRUE
	--		IF get_debug() THEN
	--			MESSAGE "Argument get_url_query_text(): ", trim(l_sel_text)
	--		END IF

	IF get_url_query_text() IS NOT NULL THEN
		LET l_query_text = get_url_query_text()
		LET modu_sel_text_used = TRUE
		MESSAGE "Argument get_url_query_text(): ", trim(l_query_text)
	ELSE
		IF p_filter THEN 
			CLEAR FORM 
			MESSAGE kandoomsg2("G",1001,"")		#1001 Enter selection criteria - ESC TO continue"

			CONSTRUCT BY NAME l_where_part ON 
				jour_code, 
				jour_num, 
				entry_code, 
				source_ind, 
				year_num, 
				period_num, 
				for_debit_amt, 
				for_credit_amt, 
				post_flag 

				BEFORE CONSTRUCT 
					CALL publish_toolbar("kandoo","G26","construct-batch") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
			END CONSTRUCT 
		ELSE 
			LET l_where_part = " 1=1 " 
		END IF 

		IF modu_sel_text_used = FALSE THEN
			LET l_query_text = 
				"SELECT * FROM batchhead ", 
				"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
				"AND ", l_where_part clipped, 
				"ORDER BY jour_code,jour_num" 
		END IF
		
		IF int_flag OR quit_flag THEN 
			RETURN false 
		END IF 

	END IF 

	#MESSAGE "debug sql:", trim(l_sel_text)

	PREPARE getbatch_datasource FROM l_query_text 
	DECLARE c_batc_datasource CURSOR FOR getbatch_datasource 
	LET l_idx = 0 

	FOREACH c_batc_datasource INTO l_rec_batchhead.* 
		LET l_idx = l_idx + 1 
		#LET scrn = scr_line()
		LET l_arr_rec_batchhead[l_idx].jour_code = l_rec_batchhead.jour_code 
		LET l_arr_rec_batchhead[l_idx].jour_num = l_rec_batchhead.jour_num 
		LET l_arr_rec_batchhead[l_idx].entry_code = l_rec_batchhead.entry_code 
		LET l_arr_rec_batchhead[l_idx].source_ind = l_rec_batchhead.source_ind 
		LET l_arr_rec_batchhead[l_idx].year_num = l_rec_batchhead.year_num 
		LET l_arr_rec_batchhead[l_idx].period_num = l_rec_batchhead.period_num 
		LET l_arr_rec_batchhead[l_idx].for_debit_amt = l_rec_batchhead.for_debit_amt 
		LET l_arr_rec_batchhead[l_idx].for_credit_amt = l_rec_batchhead.for_credit_amt 
		LET l_arr_rec_batchhead[l_idx].post_flag = l_rec_batchhead.post_flag 
		--		IF l_idx > 199 THEN --alch I don't see reason to limit number of displayed rows
		--			LET l_msgresp = kandoomsg("G",9042,l_idx)
		--9042 First l_idx batches selected"
		--			EXIT FOREACH
		--		END IF
		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF	
	END FOREACH 

	IF l_arr_rec_batchhead.getlength() = 0 THEN 
		LET l_msgresp = kandoomsg("G",9043,"") 
		#9043 No Batches Selected
	END IF 


	RETURN l_arr_rec_batchhead 
END FUNCTION 
############################################################
# END FUNCTION getBatchHead_DataSource(p_filter)
############################################################


############################################################
# FUNCTION getbatch()
#
#
############################################################
FUNCTION getbatch() 
	DEFINE l_rec_batchhead RECORD LIKE batchhead.* 
	DEFINE l_arr_rec_batchhead DYNAMIC ARRAY OF t_rec_batchhead_jc_cn_cd_ec_si_yn_pn_da_ca_pf 
	--	DEFINE l_arr_rec_batchhead DYNAMIC ARRAY OF RECORD --ARRAY[205] OF
	--			jour_code LIKE batchhead.jour_code,
	--			jour_num LIKE batchhead.jour_num,
	--			entry_code LIKE batchhead.entry_code,
	--			year_num LIKE batchhead.year_num,
	--			period_num LIKE batchhead.period_num,
	--			for_debit_amt LIKE batchhead.for_debit_amt,
	--			for_credit_amt LIKE batchhead.for_credit_amt,
	--			post_flag LIKE batchhead.post_flag
	--		END RECORD
	DEFINE l_where_part VARCHAR(2000) 
	DEFINE l_sel_text VARCHAR(2000) 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_idx SMALLINT 

	{
	#Optional program argument for query BUT argument is only used ONCE in a program life cycle
		IF (modu_sel_text_used = FALSE) AND (get_url_query_text() IS NOT NULL) THEN
			LET l_sel_text = get_url_query_text()
			LET modu_sel_text_used = TRUE
			IF get_debug() THEN
				MESSAGE "Argument get_url_query_text(): ", trim(l_sel_text)
			END IF

		ELSE

			CLEAR FORM
			LET l_msgresp = kandoomsg("G",1001,"")
	#1001 Enter selection criteria - ESC TO continue"

			CONSTRUCT BY NAME l_where_part on
					jour_code,
					jour_num,
					entry_code,
					source_ind,
					year_num,
					period_num,
					for_debit_amt,
					for_credit_amt,
					post_flag

				BEFORE CONSTRUCT
					CALL publish_toolbar("kandoo","G26","construct-batch")

				ON ACTION "WEB-HELP"
					CALL onlineHelp(getModuleId(),NULL)

				ON ACTION "actToolbarManager"
					CALL setupToolbar()

			END CONSTRUCT

			LET l_sel_text = 	"SELECT * FROM batchhead ",
							"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ",
							"AND ", l_where_part clipped,
							"ORDER BY jour_code,jour_num"

			IF int_flag OR quit_flag THEN
				RETURN FALSE
			END IF

		END IF

		IF get_debug() THEN
			MESSAGE "debug sql:", trim(l_sel_text)
		END IF

		PREPARE getbatch FROM l_sel_text
			DECLARE c_batc CURSOR FOR getbatch
		LET l_idx = 0

		FOREACH c_batc INTO l_rec_batchhead.*
			LET l_idx = l_idx + 1
	#LET scrn = scr_line()
			LET l_arr_rec_batchhead[l_idx].jour_code = l_rec_batchhead.jour_code
			LET l_arr_rec_batchhead[l_idx].jour_num = l_rec_batchhead.jour_num
			LET l_arr_rec_batchhead[l_idx].entry_code = l_rec_batchhead.entry_code
			LET l_arr_rec_batchhead[l_idx].source_ind = l_rec_batchhead.source_ind
			LET l_arr_rec_batchhead[l_idx].year_num = l_rec_batchhead.year_num
			LET l_arr_rec_batchhead[l_idx].period_num = l_rec_batchhead.period_num
			LET l_arr_rec_batchhead[l_idx].for_debit_amt = l_rec_batchhead.for_debit_amt
			LET l_arr_rec_batchhead[l_idx].for_credit_amt = l_rec_batchhead.for_credit_amt
			LET l_arr_rec_batchhead[l_idx].post_flag = l_rec_batchhead.post_flag
	#		IF l_idx > 199 THEN --alch I don't see reason to limit number of displayed rows
	#			LET l_msgresp = kandoomsg("G",9042,l_idx)
	#9042 First l_idx batches selected"
	#			EXIT FOREACH
	#		END IF
		END FOREACH

	}

	CALL getbatchhead_datasource(false) RETURNING l_arr_rec_batchhead 

	--	CALL set_count(l_idx)
	--	IF l_idx = 0 THEN
	--		LET l_msgresp = kandoomsg("G",9043,"")
	--9043 No Batches Selected
	--	END IF
	MESSAGE kandoomsg2("G",1043,"")	#1043 F3/F4 - RETURN TO View
	#	INPUT ARRAY l_arr_rec_batchhead WITHOUT DEFAULTS FROM sr_batchhead.* ATTRIBUTES(UNBUFFERED)

	DISPLAY ARRAY l_arr_rec_batchhead TO sr_batchhead.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","G26","input-arr-batchhead") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER" 
			CLEAR FORM 
			CALL l_arr_rec_batchhead.clear() 
			CALL getbatchhead_datasource(true) RETURNING l_arr_rec_batchhead 

		ON ACTION "REFRESH" 
			CALL getbatchhead_datasource(false) RETURNING l_arr_rec_batchhead 

		ON ACTION "NEW" 
			CALL run_prog("G21","","","","") #new batch 
			CALL getbatchhead_datasource(false) RETURNING l_arr_rec_batchhead 

		ON ACTION "EDIT" 
			CALL run_prog("G22","","","","") #new batch 
			CALL getbatchhead_datasource(false) RETURNING l_arr_rec_batchhead 

		ON ACTION "Post Batch" #gp2 post journals 
			CALL run_prog("GP2","","","","") #post journals 
			CALL getbatchhead_datasource(false) RETURNING l_arr_rec_batchhead 

		ON ACTION "REPORT Trial Balance" #trial balance REPORT 
			CALL run_prog("GRA","","","","") #trial balance REPORT 
			CALL getbatchhead_datasource(false) RETURNING l_arr_rec_batchhead 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			#LET scrn = scr_line()
			#		BEFORE FIELD jour_num

		ON ACTION ("Details","ACCEPT","DOUBLECLICK") 
			IF l_idx > 0 THEN #for empty arrays 

				IF l_arr_rec_batchhead[l_idx].jour_code IS NOT NULL THEN 

					OPEN WINDOW g109 with FORM "G109" 
					CALL windecoration_g("G109") 
					CALL disp_journal(glob_rec_kandoouser.cmpy_code,l_arr_rec_batchhead[l_idx].jour_num) 
					#LET l_msgresp = kandoomsg("G",8015,"")

					MENU "Batch details" 
						BEFORE MENU 
							CALL publish_toolbar("kandoo","G26","menu-batchhead") 

						ON ACTION "View batch details" 
							CALL jo_det_scan(glob_rec_kandoouser.cmpy_code, l_arr_rec_batchhead[l_idx].jour_num) 

						ON ACTION "CANCEL" 
							EXIT MENU 

						ON ACTION "WEB-HELP" 
							CALL onlinehelp(getmoduleid(),null) 

						ON ACTION "actToolbarManager" 
							CALL setuptoolbar() 
					END MENU 
					#8015 " View batch details (y/n) ?"
					#				IF l_msgresp = "Y"
					#				OR l_msgresp = "y" THEN
					#					CALL jo_det_scan(glob_rec_kandoouser.cmpy_code, l_arr_rec_batchhead[l_idx].jour_num)
					#				END IF
					CLOSE WINDOW g109 

				END IF 
				#			NEXT FIELD jour_code
			END IF 

	END DISPLAY 
	------------------------------------------------------------------------------ END DISPLAY

	LET int_flag = false 
	LET quit_flag = false 
	#	IF num_args() > 0 THEN
	#		RETURN FALSE
	#	ELSE
	#		RETURN TRUE
	#	END IF

	IF get_url_query_text() THEN 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 

END FUNCTION 
############################################################
# END FUNCTION getbatch()
############################################################