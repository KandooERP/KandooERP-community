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

	Source code beautified by beautify.pl on 2020-01-03 14:28:31	$Id: $
}



#
{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module G29  allows the user TO UPDATE unposted Journal Batches
# created by other modules
#
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS "../gl/G21_GLOBALS.4gl" #g21a.4gl 


############################################################
# MAIN
#
#
############################################################
MAIN 
	DEFINE l_msgresp LIKE language.yes_flag 

	CALL setModuleId("G29") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 


	SELECT * INTO glob_rec_glparms.* 
	FROM glparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_code = "1" 
	IF status = NOTFOUND THEN 
		LET l_msgresp=kandoomsg("G",5007,"") 
		#5008 General Ledger Parameters Not Set Up;  Refer Menu GZP.
		EXIT PROGRAM 
	END IF 
	--   CALL create_table("batchdetl","t_batchdetl","","Y") #changed to normal table

	OPEN WINDOW g464 with FORM "G464" 
	CALL windecoration_g("G464") 

	LET l_msgresp=kandoomsg("G",7016,"") 
	#7016 WARNING: Subsidiary ledgers are product of non-gl documents.  ...
	WHILE select_jour() 
		CALL scan_jour() 
	END WHILE 
	CLOSE WINDOW g464 
END MAIN 


############################################################
# FUNCTION select_jour()
#
#
############################################################
FUNCTION select_jour() 
	DEFINE l_where_text CHAR(200) 
	DEFINE l_query_text CHAR(300) 
	DEFINE l_msgresp LIKE language.yes_flag 

	CLEAR FORM 
	LET l_msgresp=kandoomsg("U",1001,"") 
	#1001 Enter Selection Criteria;  OK TO Continue.
	CONSTRUCT BY NAME l_where_text ON jour_code, 
	jour_num, 
	jour_date, 
	year_num, 
	period_num, 
	for_debit_amt, 
	for_credit_amt, 
	currency_code 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","G29","construct-jour") 

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
		LET l_msgresp=kandoomsg("U",1002,"") 
		#1002 Searching database;  Please wait.
		IF glob_rec_glparms.use_clear_flag = "Y" THEN 
			LET l_where_text = l_where_text clipped," AND cleared_flag='N'" 
		END IF 
		LET l_query_text = "SELECT * FROM batchhead ", 
		"WHERE cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND post_flag='N' ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY jour_code,jour_num" 
		
		PREPARE s_batchhead FROM l_query_text 
		DECLARE c_batchhead CURSOR FOR s_batchhead 
		
		RETURN true 
	END IF 
END FUNCTION 


############################################################
# FUNCTION scan_jour()
#
#
############################################################
FUNCTION scan_jour() 
	DEFINE l_arr_rec_batchhead DYNAMIC ARRAY OF RECORD #array[200] OF 
		scroll_flag CHAR(1), 
		jour_code LIKE batchhead.jour_code, 
		jour_num LIKE batchhead.jour_num, 
		jour_date LIKE batchhead.jour_date, 
		year_num LIKE batchhead.year_num, 
		period_num LIKE batchhead.period_num, 
		for_debit_amt LIKE batchhead.for_debit_amt, 
		for_credit_amt LIKE batchhead.for_credit_amt, 
		currency_code LIKE batchhead.currency_code 
	END RECORD 
	DEFINE l_jour_num LIKE batchhead.jour_num 
	DEFINE l_idx SMALLINT  
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_idx = 0 
	FOREACH c_batchhead INTO glob_rec_batchhead.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_batchhead[l_idx].scroll_flag = NULL 
		LET l_arr_rec_batchhead[l_idx].jour_code = glob_rec_batchhead.jour_code 
		LET l_arr_rec_batchhead[l_idx].jour_num = glob_rec_batchhead.jour_num 
		LET l_arr_rec_batchhead[l_idx].jour_date = glob_rec_batchhead.jour_date 
		LET l_arr_rec_batchhead[l_idx].year_num = glob_rec_batchhead.year_num 
		LET l_arr_rec_batchhead[l_idx].period_num = glob_rec_batchhead.period_num 
		LET l_arr_rec_batchhead[l_idx].for_debit_amt = glob_rec_batchhead.for_debit_amt 
		LET l_arr_rec_batchhead[l_idx].for_credit_amt = glob_rec_batchhead.for_credit_amt 
		LET l_arr_rec_batchhead[l_idx].currency_code = glob_rec_batchhead.currency_code 

--		IF l_idx = 200 THEN 
--			LET l_msgresp=kandoomsg("G",9042,l_idx) 
--			#9035 First 200 Journal Selected Only.
--			EXIT FOREACH 
--		END IF 
	END FOREACH 

	IF l_idx = 0 THEN 
		LET l_msgresp=kandoomsg("G",9043,"") 
		#9036 No Journal Selected
	ELSE 
--		CALL set_count(l_idx) 
		OPTIONS INSERT KEY f36, 
		DELETE KEY f36 
		LET l_msgresp=kandoomsg("G",1039,l_idx) 

		#1021 Journal - RETURN TO Edit"
		INPUT ARRAY l_arr_rec_batchhead WITHOUT DEFAULTS FROM sr_batchhead.* attributes(UNBUFFERED) 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","G29","input-arr-batchhead") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				#LET scrn = scr_line()
	
			BEFORE FIELD scroll_flag 
				IF l_arr_rec_batchhead[l_idx].jour_code IS NOT NULL THEN 
					#DISPLAY l_arr_rec_batchhead[l_idx].*
					#     TO sr_batchhead[scrn].*

				END IF 
	
			AFTER FIELD scroll_flag 
				IF fgl_lastkey() = fgl_keyval("down") THEN 
					IF arr_curr() = arr_count() THEN 
						LET l_msgresp=kandoomsg("I",9001,"") 
						#9001 There are no more rows in the direction ...
						NEXT FIELD scroll_flag 
					ELSE 
						IF l_arr_rec_batchhead[l_idx+1].jour_code IS NULL THEN 
							LET l_msgresp=kandoomsg("I",9001,"") 
							#9001 There are no more rows in the direction ...
							NEXT FIELD scroll_flag 
						END IF 
					END IF 
				END IF 
	
			BEFORE FIELD jour_code 

				OPEN WINDOW g463 with FORM "G463" 
				CALL windecoration_g("G463") 

				CALL init_journal(l_arr_rec_batchhead[l_idx].jour_num) 
				LET l_jour_num = NULL 
				WHILE G21_header() 

					OPEN WINDOW G114 with FORM "G114" 
					CALL windecoration_g("G114") 

					WHILE batch_lines_entry() 


						menu" Journal" 
							BEFORE MENU 
								CALL publish_toolbar("kandoo","G29","menu-journal") 

							ON ACTION "WEB-HELP" 
								CALL onlinehelp(getmoduleid(),null) 

							ON ACTION "actToolbarManager" 
								CALL setuptoolbar() 

							ON ACTION "Save" 
								#command"Save" " Save changes TO database"
								LET l_jour_num = g21a_write_gl_batch(MODE_CLASSIC_EDIT) 
								IF l_jour_num < 0 THEN 
									# Error in capital account funds available
									NEXT option "Exit" 
								ELSE 
									EXIT MENU 
								END IF 

							ON ACTION "Discard" 
								#command"Discard" " Discard changes TO batch"
								LET l_jour_num = 0 
								EXIT MENU 

							ON ACTION "Exit" 
								#COMMAND KEY(interrupt,"E") "Exit" " RETURN TO edit batch"
								LET quit_flag = true 
								EXIT MENU 

							COMMAND KEY (control-w) 
								CALL kandoohelp("") 
						END MENU 


						IF int_flag OR quit_flag THEN 
							LET int_flag = false 
							LET quit_flag = false 
						ELSE 
							EXIT WHILE 
						END IF 
					END WHILE 
					CLOSE WINDOW G114 
					IF l_jour_num IS NOT NULL THEN 
						SELECT year_num, 
						period_num, 
						for_debit_amt, 
						for_credit_amt, 
						currency_code 
						INTO l_arr_rec_batchhead[l_idx].year_num, 
						l_arr_rec_batchhead[l_idx].period_num, 
						l_arr_rec_batchhead[l_idx].for_debit_amt, 
						l_arr_rec_batchhead[l_idx].for_credit_amt, 
						l_arr_rec_batchhead[l_idx].currency_code 
						FROM batchhead 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND jour_num = glob_rec_batchhead.jour_num 
						EXIT WHILE 
					END IF 
				END WHILE 
				CLOSE WINDOW g463 
				OPTIONS INSERT KEY f36, 
				DELETE KEY f36 
				NEXT FIELD scroll_flag 
				#AFTER ROW
				#   DISPLAY l_arr_rec_batchhead[l_idx].*
				#        TO sr_batchhead[scrn].*

--			ON KEY (control-w) 
--				CALL kandoohelp("") 
		END INPUT 

	END IF
	 
	LET int_flag = false 
	LET quit_flag = false 
END FUNCTION