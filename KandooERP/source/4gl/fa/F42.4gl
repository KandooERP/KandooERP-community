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

	Source code beautified by beautify.pl on 2020-01-03 10:36:56	$Id: $
}

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "F_FA_GLOBALS.4gl" 

# Purpose   :   Asset Scan

GLOBALS 
	DEFINE 

	p_famast, 
	famast_trn RECORD LIKE famast.*, 
	ans CHAR(1), 
	counter SMALLINT, 
	where_text CHAR(600), 
	query_text CHAR(700), 
	not_found SMALLINT, 
	exist SMALLINT, 
	auto_flag SMALLINT, 
	try_again CHAR(1), 
	err_message CHAR(60), 
	add_success_flag SMALLINT, 
	pr_vendor RECORD LIKE vendor.*, 
	display_asset LIKE famast.asset_code, 
	array_rec array[300] OF RECORD 
		asset_code LIKE famast.asset_code, 
		add_on_code LIKE famast.add_on_code, 
		desc_text LIKE famast.desc_text, 
		orig_setup_date LIKE famast.orig_setup_date 
	END RECORD, 
	runner CHAR(80) 
END GLOBALS 

MAIN 
	DEFINE 
	scrn SMALLINT, 
	re_display_flag CHAR(1), 
	pr_asset_code LIKE famast.asset_code 

	#Initial UI Init
	CALL setModuleId("F42") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	LET re_display_flag = "N" 
	OPEN WINDOW f128 with FORM "F128" -- alch kd-757 
	CALL  windecoration_f("F128") -- alch kd-757 
	WHILE true 
		CLEAR FORM 
		LET msgresp = kandoomsg("U",1001,"") 
		#1001 Enter selection criteria; OK TO continue.
		CONSTRUCT BY NAME query_text ON famast.asset_code, 
		famast.add_on_code, 
		famast.desc_text, 
		famast.orig_setup_date 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","F42","const-famast-2") -- alch kd-504 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
		END CONSTRUCT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			CLOSE WINDOW f128 
			EXIT program 
		END IF 

		LET where_text = "SELECT * ", 
		"FROM famast ", 
		"WHERE cmpy_code = \"", glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND ",query_text clipped," ", 
		"ORDER BY asset_code, add_on_code" 

		PREPARE sql1 FROM where_text 
		DECLARE curs_qry CURSOR FOR sql1 

		CALL load_array() 
		IF not_found THEN 
			LET msgresp = kandoomsg("U",9101,"") 
			#9101 No records satisfied selection criteria.
			CONTINUE WHILE 
		END IF 

		INITIALIZE p_famast.* TO NULL 
		OPTIONS INSERT KEY f36, 
		DELETE KEY f36 
		INPUT ARRAY array_rec WITHOUT DEFAULTS FROM s_famast.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","F42","inp_arr-s_famast-1") -- alch kd-504 
			AFTER ROW 
				DISPLAY array_rec[counter].* TO s_famast[scrn].* 
			BEFORE FIELD asset_code 
				LET counter = arr_curr() 
				LET scrn = scr_line() 
				LET pr_asset_code = array_rec[counter].asset_code 

			AFTER FIELD asset_code 
				LET array_rec[counter].asset_code = pr_asset_code 
				IF array_rec[counter+1].asset_code IS NULL 
				AND fgl_lastkey() = fgl_keyval("down") THEN 
					LET msgresp = kandoomsg("U",9001,"") 
					#9001 There are no more rows in the direction you are going.
					NEXT FIELD asset_code 
				END IF 
			BEFORE FIELD add_on_code 
				SELECT * INTO p_famast.* FROM famast 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND asset_code = array_rec[counter].asset_code 
				AND add_on_code = array_rec[counter].add_on_code 
				CALL show_it() 
				NEXT FIELD asset_code 
			ON KEY (control-w) 
				CALL kandoohelp("") 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
		END INPUT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			EXIT WHILE 
		END IF 

	END WHILE 

	CLOSE WINDOW f128 

END MAIN 

FUNCTION load_array() 
	DEFINE 
	look_rec RECORD LIKE famast.* 

	LET counter = 1 

	FOREACH curs_qry INTO look_rec.* 
		LET array_rec[counter].asset_code = look_rec.asset_code 
		LET array_rec[counter].add_on_code = look_rec.add_on_code 
		LET array_rec[counter].desc_text = look_rec.desc_text 
		LET array_rec[counter].orig_setup_date = look_rec.orig_setup_date 
		IF counter = 300 THEN 
			LET msgresp = kandoomsg("U",6100,counter) 
			#6100 First XXX records selected only. More may be available.
			EXIT FOREACH 
		END IF 
		LET counter = counter + 1 
		LET exist = true 
	END FOREACH 

	LET counter = counter - 1 

	LET not_found = false 
	IF NOT exist THEN 
		LET not_found = true 
	END IF 

	#9113 XXX records selected.
	LET msgresp = kandoomsg("U",1534,"") 
	CALL set_count(counter) 
	LET msgresp = kandoomsg("U",9113,counter) 
	#1534 TAB TO view line; OK TO continue.

END FUNCTION 


# culled FROM F41 FROM here down


FUNCTION show_it() 
	OPEN WINDOW f133 with FORM "F133" -- alch kd-757 
	CALL  windecoration_f("F133") -- alch kd-757 

	DISPLAY BY NAME p_famast.asset_code, 
	p_famast.add_on_code, 
	p_famast.faresp_code, 
	p_famast.desc_text, 
	p_famast.tag_text, 
	p_famast.orig_setup_date, 
	p_famast.asset_serial_text, 
	p_famast.acquist_code, 
	p_famast.acquist_date, 
	p_famast.orig_po_num, 
	p_famast.cgt_index_per, 
	p_famast.vend_code, 
	p_famast.currency_code, 
	p_famast.orig_fcost_amt, 
	p_famast.orig_cost_amt, 
	p_famast.operate_date, 
	p_famast.start_year_num, 
	p_famast.start_period_num, 
	p_famast.user1_code, 
	p_famast.user1_amt, 
	p_famast.user2_code, 
	p_famast.user2_amt, 
	p_famast.user3_code, 
	p_famast.user3_amt, 
	p_famast.user1_qty 

	LET msgresp = kandoomsg("F",8009,"") 
	#8009 Show more details?
	IF msgresp ="Y" THEN 
		CALL asset_detail() 
	END IF 
	CLOSE WINDOW f133 
END FUNCTION 


FUNCTION asset_detail() 
	DEFINE 
	sa, 
	endflag SMALLINT, 
	sel_value CHAR(1) 
	OPEN WINDOW f134 with FORM "F134" -- alch kd-757 
	CALL  windecoration_f("F134") -- alch kd-757 
	DISPLAY BY NAME p_famast.asset_code, 
	p_famast.desc_text 

	WHILE true 
		INPUT sel_value FROM what_do 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","F42","inp-sel_value-1") -- alch kd-504 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
		END INPUT 
		CASE (sel_value) 
			WHEN "1" 
				CALL gen_det() 
			WHEN "2" 
				CALL book_det() 
			WHEN "3" 
				CALL trans_det() 
			WHEN "C" 
				LET endflag = 1 
				EXIT CASE 
			WHEN "E" 
				LET endflag = 1 
				EXIT CASE 
		END CASE 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET endflag = 1 
		END IF 
		IF endflag = 1 THEN 
			EXIT WHILE 
		END IF 
	END WHILE 
	CLOSE WINDOW f134 
END FUNCTION 

FUNCTION gen_det() 
	OPEN WINDOW f137 with FORM "F137" -- alch kd-757 
	CALL  windecoration_f("F137") -- alch kd-757 

	DISPLAY BY NAME p_famast.asset_code, 
	p_famast.desc_text, 
	p_famast.faresp_code, 
	p_famast.tag_text, 
	p_famast.orig_setup_date, 
	p_famast.asset_serial_text, 
	p_famast.acquist_code, 
	p_famast.acquist_date, 
	p_famast.orig_po_num, 
	p_famast.cgt_index_per, 
	p_famast.vend_code, 
	p_famast.currency_code, 
	p_famast.orig_fcost_amt, 
	p_famast.orig_cost_amt, 
	p_famast.operate_date, 
	p_famast.start_year_num, 
	p_famast.start_period_num, 
	p_famast.user1_code, 
	p_famast.user1_amt, 
	p_famast.user2_code, 
	p_famast.user2_amt, 
	p_famast.user3_code, 
	p_famast.user3_amt, 
	p_famast.user1_qty 

	LET msgresp = kandoomsg("U",2,"") 
	#2 Any Key TO Continue.
	CLOSE WINDOW f137 
END FUNCTION 

FUNCTION book_det() 
	DEFINE 
	l_book LIKE fastatus.book_code, 
	where_text CHAR(500), 
	query_text CHAR(600), 
	scrn, 
	counter SMALLINT, 
	p_fastatus RECORD LIKE fastatus.*, 
	b_array array[300] OF RECORD 
		book_code LIKE fastatus.book_code, 
		book_text LIKE fabook.book_text 
	END RECORD, 
	pr_book_code LIKE fastatus.book_code, 
	asset_status CHAR(15) 
	OPEN WINDOW f139 with FORM "F139" -- alch kd-757 
	CALL  windecoration_f("F139") -- alch kd-757 
	LET msgresp = kandoomsg("U",1001,"") 
	#1001 Enter selection criteria; OK TO continue.
	CONSTRUCT BY NAME where_text ON fastatus.book_code 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","F42","const-fastatus-2") -- alch kd-504 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
	END CONSTRUCT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		CLOSE WINDOW f139 
		RETURN 
	END IF 
	LET msgresp = kandoomsg("U",1002,"") 
	#1002 Searching database; OK TO continue.

	LET query_text = "SELECT book_code FROM fastatus WHERE ", 
	"cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\" AND ", 
	"asset_code = \"", p_famast.asset_code, "\" AND ", 
	"add_on_code = \"", p_famast.add_on_code, "\" AND ", 
	where_text clipped 
	PREPARE state1 FROM query_text 

	DECLARE stat_curs CURSOR FOR state1 

	LET counter = 0 
	FOREACH stat_curs INTO l_book 
		LET counter = counter + 1 
		IF counter > 300 THEN 
			EXIT FOREACH 
		END IF 
		LET b_array[counter].book_code = l_book 

		SELECT book_text INTO b_array[counter].book_text 
		FROM fabook 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND book_code = b_array[counter].book_code 
		IF status = notfound THEN 
			LET b_array[counter].book_text = "" 
		END IF 
	END FOREACH 
	CALL set_count(counter) 
	LET msgresp = kandoomsg("U",1534,"") 
	#1534 TAB TO view line; OK TO continue.
	INPUT ARRAY b_array WITHOUT DEFAULTS FROM s_lookup.* 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","F42","inp_arr-b_array-1") -- alch kd-504 
		AFTER ROW 
			DISPLAY b_array[counter].* TO s_lookup[scrn].* 

		BEFORE FIELD book_code 
			LET counter = arr_curr() 
			LET scrn = scr_line() 
			LET pr_book_code = b_array[counter].book_code 
			DISPLAY b_array[counter].* TO s_lookup[scrn].* 

		AFTER FIELD book_code 
			LET b_array[counter].book_code = pr_book_code 
			IF b_array[counter+1].book_text IS NULL 
			AND fgl_lastkey() = fgl_keyval("down") THEN 
				LET msgresp = kandoomsg("U",9001,"") 
				#9001 There are no more rows in the direction you are going.
				NEXT FIELD book_code 
			END IF 
		BEFORE FIELD book_text 
			SELECT * INTO p_fastatus.* FROM fastatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND asset_code = p_famast.asset_code 
			AND add_on_code = p_famast.add_on_code 
			AND book_code = b_array[counter].book_code 
			IF status <> notfound THEN 
				OPEN WINDOW f140 with FORM "F140" -- alch kd-757 
				CALL  windecoration_f("F140") -- alch kd-757 

				CASE p_fastatus.bal_chge_appl_flag 
					WHEN "A" 
						LET asset_status = "Active" 
					WHEN "R" 
						LET asset_status = "Retired" 
					WHEN "S" 
						LET asset_status = "Sold" 
				END CASE 

				DISPLAY BY NAME p_famast.asset_code, 
				p_famast.desc_text, 
				p_fastatus.book_code, 
				p_fastatus.seq_num, 
				p_fastatus.depr_code, 
				p_fastatus.purchase_date, 
				p_fastatus.last_depr_year_num, 
				p_fastatus.last_depr_per_num, 
				p_fastatus.rem_life_num, 
				p_fastatus.cur_depr_cost_amt, 
				p_fastatus.depr_amt, 
				p_fastatus.net_book_val_amt, 
				p_fastatus.salvage_amt, 
				p_fastatus.bal_chge_appl_flag, 
				asset_status 

				LET msgresp = kandoomsg("U",2,"") 
				#2 Any Key TO Continue.
				CLOSE WINDOW f140 
			END IF 
			NEXT FIELD book_code 
		ON KEY (control-w) 
			CALL kandoohelp("") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 
	CLOSE WINDOW f139 
END FUNCTION 

FUNCTION trans_det() 
	DEFINE aud_array array[300] OF 
	RECORD 
		book_code LIKE faaudit.book_code, 
		batch_num LIKE faaudit.batch_num, 
		trans_ind LIKE faaudit.trans_ind, 
		asset_amt LIKE faaudit.asset_amt, 
		depr_amt LIKE faaudit.depr_amt, 
		net_book_val_amt LIKE faaudit.net_book_val_amt 
	END RECORD, 
	aud_array2 array[300] OF RECORD 
		batch_line_num LIKE faaudit.batch_line_num 
	END RECORD, 
	scrn, 
	counter SMALLINT, 
	where_text CHAR(500), 
	query_text CHAR(600), 
	p_faaudit RECORD LIKE faaudit.*, 
	pr_book_code LIKE faaudit.book_code, 
	line_stat CHAR(20) 

	OPEN WINDOW f141 with FORM "F141" -- alch kd-757 
	CALL  windecoration_f("F141") -- alch kd-757 
	WHILE true 
		LET msgresp = kandoomsg("U",1001,"") 
		#1001 Enter selection criteria; OK TO continue.
		CONSTRUCT BY NAME where_text ON faaudit.book_code, 
		faaudit.year_num, 
		faaudit.period_num, 
		faaudit.trans_ind, 
		faaudit.location_code, 
		faaudit.faresp_code, 
		faaudit.facat_code 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","F42","const-faaudit-2") -- alch kd-504 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
		END CONSTRUCT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			CLOSE WINDOW f141 
			EXIT WHILE 
		END IF 
		LET msgresp = kandoomsg("U",1002,"") 
		#1002 Searching database; OK TO continue.
		LET query_text = "SELECT * FROM faaudit WHERE ", 
		"cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\" AND ", 
		"asset_code = \"", p_famast.asset_code, "\" AND ", 
		"add_on_code = \"", p_famast.add_on_code, "\" AND ", 
		where_text clipped, 
		" ORDER BY book_code,status_seq_num" 

		PREPARE statementa FROM query_text 
		DECLARE audit_curs CURSOR FOR statementa 

		LET counter = 0 
		FOREACH audit_curs INTO p_faaudit.* 
			IF p_faaudit.trans_ind = "V" THEN {revaluation - mask the depr} 
				LET p_faaudit.depr_amt = 0 
			END IF 
			LET counter = counter + 1 
			IF counter > 300 THEN 
				EXIT FOREACH 
			END IF 
			LET aud_array[counter].book_code = p_faaudit.book_code 
			LET aud_array[counter].batch_num = p_faaudit.batch_num 
			LET aud_array[counter].trans_ind = p_faaudit.trans_ind 
			LET aud_array[counter].asset_amt = p_faaudit.asset_amt 
			LET aud_array[counter].depr_amt = p_faaudit.depr_amt 
			LET aud_array[counter].net_book_val_amt = p_faaudit.net_book_val_amt 
			LET aud_array2[counter].batch_line_num = p_faaudit.batch_line_num 
		END FOREACH 

		CALL set_count(counter) 

		OPEN WINDOW f142 with FORM "F142" -- alch kd-757 
		CALL  windecoration_f("F142") -- alch kd-757 

		LET msgresp = kandoomsg("U",1534,"") 
		#1534 TAB TO view line; OK TO continue.
		INPUT ARRAY aud_array WITHOUT DEFAULTS FROM s_lookup.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","F42","inp_arr-aud_array-1") -- alch kd-504 
			AFTER ROW 
				DISPLAY aud_array[counter].* TO s_lookup[scrn].* 

			BEFORE FIELD book_code 
				LET counter = arr_curr() 
				LET scrn = scr_line() 
				DISPLAY aud_array[counter].* TO s_lookup[scrn].* 

				LET pr_book_code = aud_array[counter].book_code 
			AFTER FIELD book_code 
				LET aud_array[counter].book_code = pr_book_code 
				IF aud_array[counter+1].trans_ind IS NULL 
				AND fgl_lastkey() = fgl_keyval("down") THEN 
					LET msgresp = kandoomsg("U",9001,"") 
					#9001 There are no more rows in the direction you are going.
					NEXT FIELD book_code 
				END IF 
			BEFORE FIELD status_seq_num 
				OPEN WINDOW f143 with FORM "F143" -- alch kd-757 
				CALL  windecoration_f("F143") -- alch kd-757 
				SELECT * INTO p_faaudit.* FROM faaudit 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND batch_num = aud_array[counter].batch_num 
				AND batch_line_num = aud_array2[counter].batch_line_num 
				IF p_faaudit.trans_ind = "V" THEN 
					LET p_faaudit.depr_amt = 0 
				END IF 
				IF status <> notfound THEN 
					CASE p_faaudit.trans_ind 
						WHEN "A" 
							LET line_stat = "Addition" 
						WHEN "J" 
							LET line_stat = "Adjustment" 
						WHEN "T" 
							IF p_faaudit.asset_amt < 0 THEN 
								LET line_stat = "Transfer - FROM" 
							ELSE 
								LET line_stat = "Transfer - TO" 
							END IF 
						WHEN "R" 
							LET line_stat = "Retirement" 
						WHEN "S" 
							LET line_stat = "Sale" 
						WHEN "L" 
							LET line_stat = "Life Adjustment" 
						WHEN "V" 
							LET line_stat = "Revaluation" 
						WHEN "D" 
							LET line_stat = "Depreciation" 
						WHEN "C" 
							LET line_stat = "Depn Code Change" 
					END CASE 
					DISPLAY BY NAME p_faaudit.asset_code, 
					p_faaudit.add_on_code, 
					p_faaudit.book_code, 
					p_faaudit.year_num, 
					p_faaudit.period_num, 
					p_faaudit.location_code, 
					p_faaudit.facat_code, 
					p_faaudit.faresp_code, 
					p_faaudit.batch_num, 
					p_faaudit.batch_line_num, 
					p_faaudit.trans_ind, 
					p_faaudit.asset_amt, 
					p_faaudit.depr_amt, 
					p_faaudit.entry_text, 
					p_faaudit.entry_date, 
					p_faaudit.net_book_val_amt, 
					line_stat, 
					p_faaudit.desc_text 

					LET msgresp = kandoomsg("U",2,"") 
					#2 Any Key TO Continue.
				END IF 
				CLOSE WINDOW f143 
				NEXT FIELD book_code 
			ON KEY (control-w) 
				CALL kandoohelp("") 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) -- alch kd-371 
		END INPUT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		END IF 
		CLOSE WINDOW f142 
	END WHILE 
END FUNCTION 
