############################################################,###############
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
############################################################
# SET up the segment constructs FOR searches
############################################################

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

################################################################
# FUNCTION segment_con(p_cmpy, p_tablename)
#
#
################################################################
FUNCTION segment_con(p_cmpy,p_tablename) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_tablename LIKE account.acct_code 
	DEFINE l_rec_structure RECORD LIKE structure.* 
	DEFINE l_arr_rec_structure ARRAY[10] OF #of RECORD #must stay fix size 10 
		RECORD 
			start_num LIKE structure.start_num, 
			length_num LIKE structure.length_num, 
			desc_text LIKE structure.desc_text 
		END RECORD 
	DEFINE l_query_text CHAR(2200) 
	DEFINE i SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

		OPTIONS DELETE KEY f36, 
		INSERT KEY f36 
		--   FOR l_idx = 1 TO 10
		--      INITIALIZE l_arr_rec_structure[l_idx].* TO NULL
		--   END FOR

		OPEN WINDOW structurewind with FORM "G168" 
		CALL windecoration_g("G168") 

		DECLARE structurecurs CURSOR FOR 
		SELECT * INTO l_rec_structure.* FROM structure 
		WHERE cmpy_code = p_cmpy 
		AND start_num > 0 
		AND (type_ind = "S" OR type_ind = "C" OR type_ind = "L") 
		ORDER BY start_num 
		LET l_idx = 0 

		FOREACH structurecurs 
			LET l_idx = l_idx + 1 
			LET l_arr_rec_structure[l_idx].start_num = l_rec_structure.start_num 
			LET l_arr_rec_structure[l_idx].length_num = l_rec_structure.length_num 
			LET l_arr_rec_structure[l_idx].desc_text = l_rec_structure.desc_text 

			DISPLAY l_arr_rec_structure[l_idx].* TO sr_structure[l_idx].* 
		END FOREACH 

		CALL set_count(l_idx) 
		LET l_msgresp = kandoomsg("G",1001,"")	#1001 " Enter Selection Criteria - Esc TO Continue"
		CASE 
			WHEN (l_idx = 1) 
				CONSTRUCT l_query_text ON flex1 
				FROM f1 

					BEFORE CONSTRUCT 
						CALL publish_toolbar("kandoo","seg_con","construct-flex-1") 

					ON ACTION "WEB-HELP" 
						CALL onlinehelp(getmoduleid(),null) 

					ON ACTION "actToolbarManager" 
						CALL setuptoolbar() 

				END CONSTRUCT 

			WHEN (l_idx = 2) 
				CONSTRUCT l_query_text ON flex1, 
				flex2 
				FROM f1, f2 

					BEFORE CONSTRUCT 
						CALL publish_toolbar("kandoo","seg_con","construct-flex-2") 

					ON ACTION "WEB-HELP" 
						CALL onlinehelp(getmoduleid(),null) 

					ON ACTION "actToolbarManager" 
						CALL setuptoolbar() 

				END CONSTRUCT 


			WHEN (l_idx = 3) #mask code has got 3 segments, division, department AND gl-account nominal code 
				CONSTRUCT l_query_text ON flex1, 
				flex2, 
				flex3 
				FROM f1, f2, f3 

					BEFORE CONSTRUCT 
						CALL publish_toolbar("kandoo","seg_con","construct-flex-3") 

					ON ACTION "WEB-HELP" 
						CALL onlinehelp(getmoduleid(),null) 

					ON ACTION "actToolbarManager" 
						CALL setuptoolbar() 

				END CONSTRUCT 


			WHEN (l_idx = 4) 
				CONSTRUCT l_query_text ON flex1, 
				flex2, 
				flex3, 
				flex4 
				FROM f1, f2, f3, f4 

					BEFORE CONSTRUCT 
						CALL publish_toolbar("kandoo","seg_con","construct-flex-4") 

					ON ACTION "WEB-HELP" 
						CALL onlinehelp(getmoduleid(),null) 

					ON ACTION "actToolbarManager" 
						CALL setuptoolbar() 

				END CONSTRUCT 


			WHEN (l_idx = 5) 
				CONSTRUCT l_query_text ON flex1, 
				flex2, 
				flex3, 
				flex4, 
				flex5 
				FROM f1, f2, f3, f4, f5 

					BEFORE CONSTRUCT 
						CALL publish_toolbar("kandoo","seg_con","construct-flex-5") 

					ON ACTION "WEB-HELP" 
						CALL onlinehelp(getmoduleid(),null) 

					ON ACTION "actToolbarManager" 
						CALL setuptoolbar() 
				END CONSTRUCT 


			WHEN (l_idx = 6) 
				CONSTRUCT l_query_text ON flex1, 
				flex2, 
				flex3, 
				flex4, 
				flex5, 
				flex6 
				FROM f1, f2, f3, f4, f5, f6 

					BEFORE CONSTRUCT 
						CALL publish_toolbar("kandoo","seg_con","construct-flex-6") 

					ON ACTION "WEB-HELP" 
						CALL onlinehelp(getmoduleid(),null) 

					ON ACTION "actToolbarManager" 
						CALL setuptoolbar() 

				END CONSTRUCT 


			WHEN (l_idx = 7) 
				CONSTRUCT l_query_text ON flex1, 
				flex2, 
				flex3, 
				flex4, 
				flex5, 
				flex6, 
				flex7 
				FROM f1, f2, f3, f4, f5, f6, f7 

					BEFORE CONSTRUCT 
						CALL publish_toolbar("kandoo","seg_con","construct-flex-7") 

					ON ACTION "WEB-HELP" 
						CALL onlinehelp(getmoduleid(),null) 

					ON ACTION "actToolbarManager" 
						CALL setuptoolbar() 

				END CONSTRUCT 


			WHEN (l_idx = 8) 
				CONSTRUCT l_query_text ON flex1, 
				flex2, 
				flex3, 
				flex4, 
				flex5, 
				flex6, 
				flex7, 
				flex8 
				FROM f1, f2, f3, f4, f5, f6, f7, f8 

					BEFORE CONSTRUCT 
						CALL publish_toolbar("kandoo","seg_con","construct-flex-8") 

					ON ACTION "WEB-HELP" 
						CALL onlinehelp(getmoduleid(),null) 

					ON ACTION "actToolbarManager" 
						CALL setuptoolbar() 

				END CONSTRUCT 


			WHEN (l_idx = 9) 
				CONSTRUCT l_query_text ON flex1, 
				flex2, 
				flex3, 
				flex4, 
				flex5, 
				flex6, 
				flex7, 
				flex8, 
				flex9 
				FROM f1, f2, f3, f4, f5, f6, f7, f8, f9 

					BEFORE CONSTRUCT 
						CALL publish_toolbar("kandoo","seg_con","construct-flex-9") 

					ON ACTION "WEB-HELP" 
						CALL onlinehelp(getmoduleid(),null) 

					ON ACTION "actToolbarManager" 
						CALL setuptoolbar() 

				END CONSTRUCT 


			WHEN (l_idx = 10) 
				CONSTRUCT l_query_text ON flex1, 
				flex2, 
				flex3, 
				flex4, 
				flex5, 
				flex6, 
				flex7, 
				flex8, 
				flex9, 
				flexa 
				FROM f1, f2, f3, f4, f5, f6, f7, f8, f9, f10 

					BEFORE CONSTRUCT 
						CALL publish_toolbar("kandoo","seg_con","construct-flex-10") 

					ON ACTION "WEB-HELP" 
						CALL onlinehelp(getmoduleid(),null) 

					ON ACTION "actToolbarManager" 
						CALL setuptoolbar() 

				END CONSTRUCT 


		END CASE 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			CLOSE WINDOW structurewind 
			LET l_query_text = NULL 
			RETURN l_query_text 
		END IF 

		CLOSE WINDOW structurewind 
		# OK now we have the info but we need TO massage the data.
		# replace the table TO table name, AND SET up the [1,2] etc
		# positioning within the l_query_text
		#FOR i = 1 TO 490
		#FOR i = 1 TO length(l_query_text-4) #original
		FOR i = 1 TO length(l_query_text)-4 --huho length(l_query_text-4) ???? 
			CASE 
				WHEN l_query_text[i,i+4] = "flex1" 
					CALL stuff_in ( p_cmpy, i, p_tablename, l_arr_rec_structure[1].start_num, 
					l_query_text, l_arr_rec_structure[1].length_num ) 
					RETURNING l_query_text 
				WHEN l_query_text[i,i+4] = "flex2" 
					CALL stuff_in ( p_cmpy, i, p_tablename, l_arr_rec_structure[2].start_num, 
					l_query_text, l_arr_rec_structure[2].length_num ) 
					RETURNING l_query_text 
				WHEN l_query_text[i,i+4] = "flex3" 
					CALL stuff_in ( p_cmpy, i, p_tablename, l_arr_rec_structure[3].start_num, 
					l_query_text, l_arr_rec_structure[3].length_num ) 
					RETURNING l_query_text 
				WHEN l_query_text[i,i+4] = "flex4" 
					CALL stuff_in ( p_cmpy, i, p_tablename, l_arr_rec_structure[4].start_num, 
					l_query_text, l_arr_rec_structure[4].length_num ) 
					RETURNING l_query_text 
				WHEN l_query_text[i,i+4] = "flex5" 
					CALL stuff_in ( p_cmpy, i, p_tablename, l_arr_rec_structure[5].start_num, 
					l_query_text, l_arr_rec_structure[5].length_num ) 
					RETURNING l_query_text 
				WHEN l_query_text[i,i+4] = "flex6" 
					CALL stuff_in ( p_cmpy, i, p_tablename, l_arr_rec_structure[6].start_num, 
					l_query_text, l_arr_rec_structure[6].length_num ) 
					RETURNING l_query_text 
				WHEN l_query_text[i,i+4] = "flex7" 
					CALL stuff_in ( p_cmpy, i, p_tablename, l_arr_rec_structure[7].start_num, 
					l_query_text, l_arr_rec_structure[7].length_num ) 
					RETURNING l_query_text 
				WHEN l_query_text[i,i+4] = "flex8" 
					CALL stuff_in ( p_cmpy, i, p_tablename, l_arr_rec_structure[8].start_num, 
					l_query_text, l_arr_rec_structure[8].length_num ) 
					RETURNING l_query_text 
				WHEN l_query_text[i,i+4] = "flex9" 
					CALL stuff_in ( p_cmpy, i, p_tablename, l_arr_rec_structure[9].start_num, 
					l_query_text, l_arr_rec_structure[9].length_num ) 
					RETURNING l_query_text 
				WHEN l_query_text[i,i+4] = "flexa" 
					CALL stuff_in ( p_cmpy, i, p_tablename, l_arr_rec_structure[10].start_num, 
					l_query_text, l_arr_rec_structure[10].length_num ) 
					RETURNING l_query_text 
			END CASE 

		END FOR 

		IF l_query_text[1,495] IS NOT NULL AND LENGTH(l_query_text[1,495]) <> 0 THEN
			LET l_query_text = " AND ", l_query_text[1,495]
		END IF 

		OPTIONS DELETE KEY f2, 
		INSERT KEY f1 

		LET int_flag = false 
		LET quit_flag = false 

		RETURN l_query_text 
END FUNCTION 
################################################################
# END FUNCTION segment_con(p_cmpy, p_tablename)
################################################################


################################################################
# FUNCTION stuff_in (p_cmpy, p_pos, p_tablename, p_starter, p_query_text, p_lengther)
#
# returns the corresponding segment  i.e. p_table_name="accountledger" ret = "accountledger.acct_code[1,3]"
# CALL stuff_in ( p_cmpy, i, p_tablename, l_arr_rec_structure[1].start_num, l_query_text, l_arr_rec_structure[1].length_num )
################################################################
FUNCTION stuff_in (p_cmpy,p_pos,p_tablename,p_starter,p_query_text,p_lengther) 
	DEFINE p_cmpy LIKE company.cmpy_code
	DEFINE p_pos SMALLINT
	DEFINE p_tablename CHAR(18) 
 	DEFINE p_starter SMALLINT 
	DEFINE p_query_text CHAR(2200) #huho - keep this static size
	DEFINE p_lengther SMALLINT 
	DEFINE l_blanks CHAR(18)
	DEFINE l_chart_pos SMALLINT 
	DEFINE l_shift_num SMALLINT 
	DEFINE l_tab_length SMALLINT 
	DEFINE l_ender SMALLINT 
	DEFINE l_dec_2_start DECIMAL(2) 
	DEFINE l_dec_2_end DECIMAL(2) 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE j SMALLINT

	DISPLAY "p_cmpy",p_cmpy 
	DISPLAY "p_pos",p_pos 
	DISPLAY "p_tablename",p_tablename 
	DISPLAY "p_starter", p_starter 
	DISPLAY "p_query_text", p_query_text 
	DISPLAY "p_lengther",p_lengther 

	# IF we are using the p_tablename of account THEN there IS a much faster
	# way of searching using chart_code rather THEN acct_code[x,y] which
	# will NOT index. So we are using l_chart_pos TO check this.
	SELECT start_num INTO l_chart_pos FROM structure 
	WHERE cmpy_code = p_cmpy 
	AND type_ind = "C" 

	LET l_blanks = " " #huho ohhh my .... do i NEED TO count this ? char(18) 
	LET l_ender = p_starter + p_lengther - 1 
	LET l_dec_2_start = p_starter 
	LET l_dec_2_end = l_ender 
	LET l_tab_length = length(p_tablename) 
	LET l_shift_num = l_tab_length + 12 

	IF p_tablename = "invoicedetl" THEN 
		LET l_shift_num = l_shift_num + 5 
	END IF 

	FOR j = 499 TO (p_pos + l_shift_num) step -1 
		LET p_query_text[j,j+1] = p_query_text[j - l_shift_num, j - l_shift_num + 1] 
	END FOR 

	LET p_query_text[p_pos, p_pos + l_shift_num + 4] = l_blanks #1,1+25+4 = 30 
	IF p_tablename = "account" 
	AND p_starter = l_chart_pos THEN 
		LET p_query_text[p_pos, p_pos + l_shift_num + 4] = " account.chart_code " 
	ELSE 
		IF p_tablename = "invoicedetl" THEN 
			LET p_query_text[p_pos, p_pos + l_shift_num + 4] = p_tablename clipped, 
			".line_acct_code[", 
			p_starter USING "<<<<", 
			",", 
			l_ender USING "<<<<", 
			"]" 
		ELSE 
			LET p_query_text[p_pos, p_pos + l_shift_num + 4] = #30 
			p_tablename clipped, ".acct_code[", p_starter USING "<<<<" , 
			"," ,l_ender USING "<<<<", "]" 
		END IF 
	END IF 

	RETURN (p_query_text) 
END FUNCTION 
################################################################
# END FUNCTION stuff_in (p_cmpy, p_pos, p_tablename, p_starter, p_query_text, p_lengther)
################################################################