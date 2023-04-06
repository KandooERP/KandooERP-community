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
# \brief module P68 allows the user TO distribute debits NOT completely distributed
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P6_GROUP_GLOBALS.4gl"
GLOBALS "../ap/P68_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################
DEFINE pr_vendor RECORD LIKE vendor.* 

############################################################
# MAIN
#
#
############################################################
MAIN 

	#Initial UI Init
	CALL setModuleId("P68") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	OPEN WINDOW wp114 with FORM "P114" 
	CALL windecoration_p("P114") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	CALL create_table("debitdist","t_debitdist","","Y") 
	WHILE scan_debits() 
	END WHILE 
	CLOSE WINDOW wp114 
END MAIN 


FUNCTION scan_debits() 
	DEFINE l_rec_debithead RECORD LIKE debithead.*
	DEFINE l_arr_debithead ARRAY[200] OF RECORD 
	scroll_flag CHAR(1), 
	debit_num LIKE debithead.debit_num, 
	vend_code LIKE debithead.vend_code, 
	debit_date LIKE debithead.debit_date, 
	year_num LIKE debithead.year_num, 
	period_num LIKE debithead.period_num, 
	total_amt LIKE debithead.total_amt, 
	dist_amt LIKE debithead.dist_amt, 
	post_flag LIKE debithead.post_flag 
	END RECORD
	DEFINE l_scroll_flag CHAR(1)
	DEFINE l_where_text CHAR(2048) 
	DEFINE l_sel_text CHAR(2200)
	DEFINE l_dist_amt LIKE debithead.dist_amt 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE idx, scrn SMALLINT

	CLEAR FORM 
	LET l_msgresp=kandoomsg("P",1001,"") 
	#1001 Enter Selection criteria - ESC TO continue"
	CONSTRUCT BY NAME l_where_text ON debit_num, 
	vend_code, 
	debit_date, 
	year_num, 
	period_num, 
	total_amt, 
	dist_amt, 
	post_flag 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","P68","construct-debit-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN FALSE 
	END IF 
	LET l_sel_text = "SELECT * FROM debithead ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND total_amt != dist_amt ", 
	"AND ", l_where_text clipped, " ", 
	" ORDER BY debit_num " 
	LET idx = 0 
	PREPARE s_debithead FROM l_sel_text 
	DECLARE c_debithead CURSOR FOR s_debithead 
	FOREACH c_debithead INTO l_rec_debithead.* 
		LET idx = idx + 1 
		LET l_arr_debithead[idx].scroll_flag = NULL 
		LET l_arr_debithead[idx].debit_num = l_rec_debithead.debit_num 
		LET l_arr_debithead[idx].vend_code = l_rec_debithead.vend_code 
		LET l_arr_debithead[idx].debit_date = l_rec_debithead.debit_date 
		LET l_arr_debithead[idx].year_num = l_rec_debithead.year_num 
		LET l_arr_debithead[idx].period_num = l_rec_debithead.period_num 
		LET l_arr_debithead[idx].total_amt = l_rec_debithead.total_amt 
		LET l_arr_debithead[idx].dist_amt = l_rec_debithead.dist_amt 
		LET l_arr_debithead[idx].post_flag = l_rec_debithead.post_flag 
		IF idx = 200 THEN 
			LET l_msgresp=kandoomsg("P",9042,idx) 
			#9042 First idx entries selected
			EXIT FOREACH 
		END IF 
	END FOREACH 
	IF idx = 0 THEN 
		LET l_msgresp=kandoomsg("P",9044,"")	#9044 No entries satisfied selection criteria
		#Infx bug workaround
--		INITIALIZE l_arr_debithead[1].* TO NULL 
	END IF 
	CALL set_count (idx) 
	LET l_msgresp=kandoomsg("P",1044,idx)	#1044 F3/F4 - RETURN on line TO Edit
	INPUT ARRAY l_arr_debithead WITHOUT DEFAULTS FROM sr_debithead.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P68","inp-arr-debithead-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE FIELD scroll_flag 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			LET l_scroll_flag = l_arr_debithead[idx].scroll_flag 
			DISPLAY l_arr_debithead[idx].* 
			TO sr_debithead[scrn].* 

		AFTER FIELD scroll_flag 
			LET l_arr_debithead[idx].scroll_flag = l_scroll_flag 
			DISPLAY l_arr_debithead[idx].scroll_flag 
			TO sr_debithead[scrn].scroll_flag 

			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF arr_curr() = arr_count() THEN 
					LET l_msgresp=kandoomsg("I",9001,"") 
					#9001 There are no more rows in the direction ...
					NEXT FIELD scroll_flag 
				ELSE 
					IF l_arr_debithead[idx+1].debit_num IS NULL THEN 
						LET l_msgresp=kandoomsg("I",9001,"") 
						#9001 There are no more rows in the direction ...
						NEXT FIELD scroll_flag 
					END IF 
				END IF 
			END IF 
		BEFORE FIELD debit_num 
			IF l_arr_debithead[idx].vend_code IS NOT NULL THEN 
				OPEN WINDOW wp170 with FORM "P170" 
				CALL windecoration_p("P170") 

				SELECT * INTO l_rec_debithead.* FROM debithead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND vend_code = l_arr_debithead[idx].vend_code 
				AND debit_num = l_arr_debithead[idx].debit_num 
				INSERT INTO t_debitdist 
				SELECT * FROM debitdist 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND debit_code = l_rec_debithead.debit_num 
				AND vend_code = l_rec_debithead.vend_code 
				IF dist_debit(glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code, l_rec_debithead.*) THEN 
					LET l_rec_debithead.debit_num = 
					update_debit(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,"3",l_rec_debithead.*) 
					IF l_rec_debithead.debit_num = 0 THEN 
						LET l_msgresp=kandoomsg("P",7022,"") 
						#7022 Errors occurred during debit UPDATE"
					ELSE 
						LET l_msgresp=kandoomsg("P",7025,l_rec_debithead.debit_num) 
						#7025 Debit successfully updated"
					END IF 
					###-Need TO collect the dist_amt FROM the debithead
					###-TO DISPLAY the dist_amt on the ARRAY row
					SELECT dist_amt INTO l_dist_amt 
					FROM debithead 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND vend_code = l_arr_debithead[idx].vend_code 
					AND debit_num = l_arr_debithead[idx].debit_num 
					LET l_arr_debithead[idx].dist_amt = l_dist_amt 
				END IF 
				DELETE FROM t_debitdist 
				CLOSE WINDOW wp170 
			END IF 
			NEXT FIELD scroll_flag 
		AFTER ROW 
			DISPLAY l_arr_debithead[idx].* TO sr_debithead[scrn].* 

	END INPUT 
	LET int_flag = 0 
	LET quit_flag = 0 
	RETURN TRUE 
END FUNCTION 


