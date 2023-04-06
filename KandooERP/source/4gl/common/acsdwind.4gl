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

	Source code beautified by beautify.pl on 2020-01-02 10:35:03	$Id: $
}

{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

#######################################################################
# FUNCTION ac_detl_scan(p_cmpy, p_acct, p_acc_year, p_per, p_seq)
#
# \brief module - acsdwind
# Purpose - FUNCTION ac_detl_scan displays scanned details allowing
#           further details TO be displayed by calling ac_detl_disp
#######################################################################
FUNCTION ac_detl_scan(p_cmpy, p_acct, p_acc_year, p_per, p_seq) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_acct LIKE accountledger.acct_code 
	DEFINE p_acc_year LIKE accountledger.year_num 
	DEFINE p_per LIKE accountledger.period_num 
	DEFINE p_seq LIKE accountledger.seq_num 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_accountledger RECORD LIKE accountledger.* 
	DEFINE l_rec_accounthist RECORD LIKE accounthist.* 
	DEFINE l_rec_company RECORD LIKE company.* 
	DEFINE l_rec_glparms RECORD LIKE glparms.* 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_arr_rec_seq DYNAMIC ARRAY OF #array[1000] OF RECORD 
		RECORD 
			seq_num LIKE accountledger.seq_num 
		END RECORD 
		DEFINE l_arr_rec_accountledger DYNAMIC ARRAY OF #array[1000] OF RECORD 
			RECORD 
				scroll_flag CHAR(1), 
				jour_code LIKE accountledger.jour_code, 
				seq_num LIKE accountledger.seq_num, 
				desc_text LIKE accountledger.desc_text, 
				debit_amt LIKE accountledger.debit_amt, 
				credit_amt LIKE accountledger.credit_amt, 
				stats_qty LIKE accountledger.stats_qty 
			END RECORD 
			DEFINE l_repeater SMALLINT 
			DEFINE l_idx SMALLINT 
			DEFINE l_debit_amt CHAR(20) 
			DEFINE l_credit_amt CHAR(20) 
			DEFINE l_open_amt CHAR(20) 
			DEFINE l_close_amt CHAR(20) 
			DEFINE l_scroll_flag CHAR(1) 

			SELECT * INTO l_rec_company.* FROM company 
			WHERE cmpy_code = p_cmpy 

			IF status = notfound THEN 
				ERROR kandoomsg2("G",5000,"") 	#5000 Company does NOT exist - Refer DBA
				RETURN 
			END IF 

			SELECT * INTO l_rec_coa.* FROM coa 
			WHERE coa.acct_code = p_acct 
			AND coa.cmpy_code = p_cmpy 
			IF status = notfound THEN 
				ERROR kandoomsg2("G",9031,"") #9031 Account code NOT found
				SLEEP 3 
				RETURN 
			END IF 

			SELECT * INTO l_rec_glparms.* FROM glparms 
			WHERE cmpy_code = p_cmpy 
			AND key_code = "1" 

			IF status = notfound THEN 
				ERROR kandoomsg2("G",5007,"") 	#5007 Gl Params NOT SET up - Refer GZP
				RETURN 
			END IF 

			OPEN WINDOW wg104 with FORM "G104" 
			CALL winDecoration_g("G104") 

			LET l_repeater = true 
			WHILE l_repeater 
				CALL l_arr_rec_accountledger.clear()
				DISPLAY p_acct TO accountledger.acct_code 
				DISPLAY p_cmpy TO accountledger.cmpy_code 
				DISPLAY p_acc_year TO accountledger.year_num 
				DISPLAY p_per TO accountledger.period_num 
				DISPLAY l_rec_coa.desc_text TO coa.desc_text 
				DISPLAY l_rec_company.name_text TO company.name_text 
				--          TO  accountledger.acct_code,
				--              accountledger.cmpy_code,
				--              accountledger.year_num,
				--              accountledger.period_num,
				--              coa.desc_text,
				--              company.name_text

				SELECT * INTO l_rec_accounthist.* FROM accounthist 
				WHERE cmpy_code = p_cmpy 
				AND acct_code = p_acct 
				AND year_num = p_acc_year 
				AND period_num = p_per 

				IF status = notfound THEN 
					LET l_open_amt = "" 
					LET l_close_amt = "" 
					LET l_debit_amt = "" 
					LET l_credit_amt = "" 
					LET l_idx = 0 
					--         CALL set_count(l_idx)

				ELSE 
					LET l_open_amt = ac_form(p_cmpy, 
					l_rec_accounthist.open_amt, 
					l_rec_coa.type_ind, 
					l_rec_glparms.style_ind) 
					LET l_close_amt = ac_form(p_cmpy, 
					l_rec_accounthist.close_amt, 
					l_rec_coa.type_ind, 
					l_rec_glparms.style_ind) 
					LET l_debit_amt = ac_form(p_cmpy, 
					l_rec_accounthist.debit_amt, 
					l_rec_coa.type_ind, 
					4) 
					LET l_credit_amt = ac_form(p_cmpy, 
					l_rec_accounthist.credit_amt, 
					l_rec_coa.type_ind, 
					4) 

					DECLARE dledg CURSOR FOR 
					SELECT * INTO l_rec_accountledger.* FROM accountledger 
					WHERE cmpy_code = p_cmpy 
					AND acct_code = p_acct 
					AND year_num = p_acc_year 
					AND period_num = p_per 
					AND seq_num >= p_seq 
					ORDER BY seq_num 
					LET l_idx = 0 

					FOREACH dledg 
						LET l_idx = l_idx + 1 
						#            LET scrn = scr_line()
						LET l_arr_rec_seq[l_idx].seq_num = l_rec_accountledger.seq_num 
						LET l_arr_rec_accountledger[l_idx].scroll_flag = NULL 
						LET l_arr_rec_accountledger[l_idx].jour_code = l_rec_accountledger.jour_code 
						LET l_arr_rec_accountledger[l_idx].seq_num = l_rec_accountledger.seq_num 
						LET l_arr_rec_accountledger[l_idx].desc_text = l_rec_accountledger.desc_text 
						LET l_arr_rec_accountledger[l_idx].credit_amt = l_rec_accountledger.credit_amt 
						LET l_arr_rec_accountledger[l_idx].debit_amt = l_rec_accountledger.debit_amt 
						LET l_arr_rec_accountledger[l_idx].stats_qty = l_rec_accountledger.stats_qty 
						#            IF l_idx = 1000 THEN
						#               ERROR kandoomsg2("G",9109,l_idx)         #9109 " First ??? Ledgers Selected Only"
						#               EXIT FOREACH
						#            END IF
					END FOREACH 
					#         CALL set_count(l_idx)
				END IF 

				--      IF l_idx = 0 THEN
				--         #Informix work around... currently DISPLAY previous line
				--         INITIALIZE l_arr_rec_accountledger[1].* TO NULL
				--      END IF

				DISPLAY l_open_amt TO open_amt 
				DISPLAY l_close_amt TO close_amt 
				DISPLAY l_debit_amt TO accounthist.debit_amt 
				DISPLAY l_credit_amt TO accounthist.credit_amt 
				--          TO  open_amt,
				--              close_amt,
				--              accounthist.debit_amt,
				--              accounthist.credit_amt

				LET l_repeater = false 
				--      OPTIONS INSERT KEY F36,
				--              DELETE KEY F36
				MESSAGE kandoomsg2("G",1044,"") #1044 RETURN TO View - F8 Committments - F9/F10 Prev/Next Period

				#huho INPUT ARRAY l_arr_rec_accountledger WITHOUT DEFAULTS FROM sr_accountledger.*

				DISPLAY ARRAY l_arr_rec_accountledger TO sr_accountledger.* ATTRIBUTE(UNBUFFERED) 
					BEFORE DISPLAY 
						CALL publish_toolbar("kandoo","acsdwind","input-arr-accountledger") 
						#Hide table first and last row navigation buttons
						CALL fgl_dialog_setkeylabel("First","") 
						CALL fgl_dialog_setkeylabel("FirstRow","") 
						CALL fgl_dialog_setkeylabel("Last","") 
						CALL fgl_dialog_setkeylabel("LastRow","") 


					ON ACTION "WEB-HELP" 
						CALL onlinehelp(getmoduleid(),null) 
					ON ACTION "actToolbarManager" 
						CALL setuptoolbar() 


					ON KEY (F8) --run r31 = commitments 
						CALL run_prog("R31",l_rec_accountledger.acct_code,"","","") --this IS zeromq business passing arguments TO child applications. 

					ON ACTION "Notes" #on KEY (control-n) --view/display notes 
						IF l_rec_accountledger.desc_text[1,3] = "###" 
						AND l_rec_accountledger.desc_text[16,18] = "###" THEN 
							CALL disp_note(p_cmpy, l_rec_accountledger.desc_text[4,15]) 
						END IF 



					ON ACTION "PREVIOUS YEAR" --ON KEY (control-o) -- previous fiscal year 
						CALL change_period(p_cmpy, p_acc_year, p_per, -1) 
						RETURNING p_acc_year, p_per 
						LET l_repeater = true 
						EXIT DISPLAY --huho INPUT 

					ON ACTION "PREVIOUS PERIOD" --ON KEY (F9) -- previous fiscal period 
						CALL change_period(p_cmpy, p_acc_year, p_per, -1) 
						RETURNING p_acc_year, p_per 
						LET l_repeater = true 
						EXIT DISPLAY --huho INPUT 

					ON ACTION "NEXT PERIOD" --ON KEY (control-p) --next fiscal period 
						CALL change_period(p_cmpy, p_acc_year, p_per, 1) 
						RETURNING p_acc_year, p_per 
						LET l_repeater = true 
						EXIT DISPLAY --huho INPUT 


					ON ACTION "NEXT YEAR" --ON KEY (F10) --next fiscal year 
						CALL change_period(p_cmpy, p_acc_year, p_per, 1) 
						RETURNING p_acc_year, p_per 
						LET l_repeater = true 
						EXIT DISPLAY --huho INPUT 


						# BEFORE FIELD scroll_flag
						#    LET l_idx = arr_curr()
						#    LET scrn = scr_line()
						#    LET l_scroll_flag = l_arr_rec_accountledger[l_idx].scroll_flag
						#    LET l_rec_accountledger.seq_num = l_arr_rec_seq[l_idx].seq_num

						# AFTER FIELD scroll_flag
						#    LET l_arr_rec_accountledger[l_idx].scroll_flag = l_scroll_flag
						#IF fgl_lastkey() = fgl_keyval("down") THEN
						#   IF arr_curr() >= arr_count() THEN
						#      LET l_msgresp=kandoomsg("W",9001,"")		#      #9001 There no more rows...
						#      NEXT FIELD scroll_flag
						#   END IF
						#
						#   IF l_arr_rec_accountledger[l_idx+1].jour_code IS NULL THEN
						#      LET l_msgresp=kandoomsg("W",9001,"")    #9001 There no more rows...
						#      NEXT FIELD scroll_flag
						#   END IF
						#END IF

					ON ACTION "View" 
						IF l_idx > 0 THEN 
							IF l_arr_rec_accountledger[l_idx].jour_code IS NOT NULL THEN 
								CALL ac_detl_disp(p_cmpy, 
								p_acct, 
								p_acc_year, 
								p_per, 
								l_rec_accountledger.seq_num) 
							END IF 
						END IF 


						#huho old BEFORE FIELD.. can remove this later
						#BEFORE FIELD jour_code  --(TAB Key) DISPLAY details of accountledger
						#  IF l_arr_rec_accountledger[l_idx].jour_code IS NOT NULL THEN
						#      CALL ac_detl_disp(p_cmpy,
						#                        p_acct,
						#                        p_acc_year,
						#                        p_per,
						#                        l_rec_accountledger.seq_num)
						#   END IF
						#   NEXT FIELD scroll_flag



				END DISPLAY 

				OPTIONS INSERT KEY f1, 
				DELETE KEY f2 
			END WHILE 

			CLOSE WINDOW wg104 

			LET int_flag = false 
			LET quit_flag = false 
END FUNCTION 


