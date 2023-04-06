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

	Source code beautified by beautify.pl on 2020-01-02 10:35:11	$Id: $
}

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

############################################################
# Module Scope Variables
############################################################
#DEFINE l_msgresp LIKE language.yes_flag

############################################################
# FUNCTION disp_debit_dis(p_cmpy_code, p_debit_num)
#
#
############################################################
FUNCTION disp_debit_dis(p_cmpy_code,p_debit_num) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_debit_num LIKE debithead.debit_num 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_debithead RECORD LIKE debithead.* 
	DEFINE l_rec_debitdist RECORD LIKE debitdist.* 
	DEFINE l_arr_rec_debitdist DYNAMIC ARRAY OF #array[200] OF 
				RECORD 
					scroll_flag CHAR(1), 
					line_num LIKE debitdist.line_num, 
					type_ind LIKE debitdist.type_ind, 
					acct_code LIKE debitdist.acct_code, 
					dist_amt LIKE debitdist.dist_amt, 
					dist_qty LIKE debitdist.dist_qty, 
					uom_code LIKE coa.uom_code 
				END RECORD 
	DEFINE l_where_text CHAR(2048) 
	DEFINE l_query_text CHAR(2200) 
	DEFINE idx SMALLINT 
	DEFINE l_cnt SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	SELECT * INTO l_rec_debithead.* FROM debithead 
	WHERE cmpy_code = p_cmpy_code 
	AND debit_num = p_debit_num 
	IF status = notfound THEN 
		LET l_msgresp = kandoomsg("U",7001,"Debit") 
		#7001 Logic Error: Debit RECORD does NOT exist
		RETURN 
	END IF 
	SELECT * INTO l_rec_vendor.* FROM vendor 
	WHERE cmpy_code = p_cmpy_code 
	AND vend_code = l_rec_debithead.vend_code 
	IF status = notfound THEN 
		LET l_msgresp=kandoomsg("P",9014,"") 
		#9014" Logic Error: Vendor does NOT Exist"
		RETURN 
	END IF 

	OPEN WINDOW p170 with FORM "P170" 
	CALL windecoration_p("P170") 

	DISPLAY BY NAME l_rec_debithead.vend_code, 
	l_rec_vendor.name_text, 
	l_rec_debithead.debit_num, 
	l_rec_debithead.total_amt 

	DISPLAY BY NAME l_rec_debithead.currency_code 
	attribute(green) 
	DISPLAY l_rec_debithead.dist_amt, 
	l_rec_debithead.dist_qty 
	TO debithead.dist_amt, 
	debithead.dist_qty 

	SELECT count(*) INTO l_cnt FROM debitdist 
	WHERE cmpy_code = p_cmpy_code 
	AND vend_code = l_rec_debithead.vend_code 
	AND debit_code = l_rec_debithead.debit_num 
	IF l_cnt > 30 THEN 
		LET l_msgresp=kandoomsg("P",1001,"") 
		#1001" Enter Selection Criteria - ESC TO Continue
		CONSTRUCT BY NAME l_where_text ON debitdist.line_num, 
		debitdist.acct_code, 
		debitdist.dist_amt, 
		debitdist.dist_qty 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","dmdiwind","construct-debitdist") 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 


	ELSE 
		LET l_where_text = "1=1" 
	END IF 
	LET l_query_text = "SELECT * FROM debitdist ", 
	"WHERE cmpy_code = '",p_cmpy_code,"' ", 
	"AND vend_code = '",l_rec_debithead.vend_code,"' ", 
	"AND debit_code ='",l_rec_debithead.debit_num,"' ", 
	"ORDER BY 1,2,3,4" 
	IF not(int_flag OR quit_flag) THEN 
		LET l_msgresp=kandoomsg("P",1002,"") 
		#P1002 Searching database - Please Wait
		PREPARE s_debitdist FROM l_query_text 
		DECLARE c_debitdist CURSOR FOR s_debitdist 
		LET idx = 0 
		FOREACH c_debitdist INTO l_rec_debitdist.* 
			LET idx = idx + 1 
			LET l_arr_rec_debitdist[idx].line_num = l_rec_debitdist.line_num 
			LET l_arr_rec_debitdist[idx].type_ind = l_rec_debitdist.type_ind 
			LET l_arr_rec_debitdist[idx].acct_code = l_rec_debitdist.acct_code 
			LET l_arr_rec_debitdist[idx].dist_amt = l_rec_debitdist.dist_amt 
			LET l_arr_rec_debitdist[idx].dist_qty = l_rec_debitdist.dist_qty 
			SELECT uom_code INTO l_arr_rec_debitdist[idx].uom_code FROM coa 
			WHERE cmpy_code = p_cmpy_code 
			AND acct_code = l_rec_debitdist.acct_code 
			IF idx = 200 THEN 
				LET l_msgresp=kandoomsg("P",9042,idx) 
				#9042 " First 200 lines selected"
				EXIT FOREACH 
			END IF 
		END FOREACH 
		OPTIONS INSERT KEY f36, 
		DELETE KEY f36 

		CALL set_count(idx) 
		LET l_msgresp = kandoomsg("P",1008,"") 
		#1008 F3 page forward, F4 page back  ESC TO Continue"
		INPUT ARRAY l_arr_rec_debitdist WITHOUT DEFAULTS FROM sr_debitdist.* ATTRIBUTE(UNBUFFERED) 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","dmdiwind","input-arr-debitdist") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				LET idx = arr_curr() 
				#LET scrn = scr_line()
				DISPLAY l_arr_rec_debitdist[idx].line_num TO idx 

				#DISPLAY l_arr_rec_debitdist[idx].* TO sr_debitdist[scrn].*

				CALL disp_db_line(p_cmpy_code,p_debit_num,l_arr_rec_debitdist[idx].line_num) 
				NEXT FIELD scroll_flag 
			AFTER FIELD scroll_flag 
				IF fgl_lastkey() = fgl_keyval("down") THEN 
					IF arr_curr() = arr_count() THEN 
						LET l_msgresp=kandoomsg("P",9001,"") 
						#9001 There are no more rows in the direction ...
						NEXT FIELD scroll_flag 
					ELSE 
						IF l_arr_rec_debitdist[idx+1].acct_code IS NULL THEN 
							LET l_msgresp=kandoomsg("P",9001,"") 
							#9001 There are no more rows in the direction ...
							NEXT FIELD scroll_flag 
						END IF 
					END IF 
				END IF 
			BEFORE FIELD acct_code 
				NEXT FIELD scroll_flag 
				#AFTER ROW
				#   DISPLAY l_arr_rec_debitdist[idx].* TO sr_debitdist[scrn].*


		END INPUT 

	END IF 

	CLOSE WINDOW p170 
	LET int_flag = false 
	LET quit_flag = false 


END FUNCTION 


############################################################
# FUNCTION disp_db_line(p_cmpy_code,p_debit_num,p_line_num)
#
#
############################################################
FUNCTION disp_db_line(p_cmpy_code,p_debit_num,p_line_num) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_debit_num LIKE debithead.debit_num 
	DEFINE p_line_num LIKE debitdist.line_num 
	DEFINE l_rec_debitdist RECORD LIKE debitdist.* 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_rec_prompt 
	RECORD 
		line_1 CHAR(25), 
		line_2 CHAR(25) 
	END RECORD 
	DEFINE l_temp_text CHAR(30) 

	SELECT * INTO l_rec_debitdist.* 
	FROM debitdist 
	WHERE cmpy_code = p_cmpy_code 
	AND debit_code = p_debit_num 
	AND line_num = p_line_num 

	IF status = notfound THEN 
		CLEAR analy_prompt_text, 
		line_1, 
		line_2, 
		analysis_text, 
		desc_text, 
		job_code, 
		res_code 
	ELSE 
		SELECT * INTO l_rec_coa.* 
		FROM coa 
		WHERE cmpy_code = p_cmpy_code 
		AND acct_code = l_rec_debitdist.acct_code 
		IF l_rec_coa.analy_prompt_text IS NULL THEN 
			LET l_rec_coa.analy_prompt_text = "Analysis" 
		END IF 
		LET l_temp_text = l_rec_coa.analy_prompt_text clipped,"..............." 
		LET l_rec_coa.analy_prompt_text = l_temp_text 
		CASE l_rec_debitdist.type_ind 
			WHEN "J" 
				LET l_rec_prompt.line_1 = kandooword(TRAN_TYPE_JOB_JOB,1) 
				LET l_rec_prompt.line_1 = l_rec_prompt.line_1 clipped,"........." 
				LET l_rec_prompt.line_2 = kandooword("jmresource",1) 
				LET l_rec_prompt.line_2 = l_rec_prompt.line_2 clipped,"........." 
			WHEN "S" 
				LET l_rec_prompt.line_1 = kandooword("shipment",1) 
				LET l_rec_prompt.line_1 = l_rec_prompt.line_1 clipped,"........." 
				LET l_rec_prompt.line_2 = kandooword("costtype",1) 
				LET l_rec_prompt.line_2 = l_rec_prompt.line_2 clipped,"........." 
			OTHERWISE 
				LET l_rec_debitdist.job_code = NULL 
				LET l_rec_debitdist.res_code = NULL 
		END CASE 
		DISPLAY BY NAME l_rec_coa.analy_prompt_text, 
		l_rec_prompt.line_1, 
		l_rec_prompt.line_2 
		DISPLAY BY NAME l_rec_debitdist.analysis_text, 
		l_rec_debitdist.desc_text, 
		l_rec_debitdist.job_code, 
		l_rec_debitdist.res_code 

	END IF 

END FUNCTION 


