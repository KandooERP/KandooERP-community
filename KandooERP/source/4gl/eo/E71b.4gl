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
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../eo/E_EO_GLOBALS.4gl"
GLOBALS "../eo/E7_GROUP_GLOBALS.4gl"
GLOBALS "../eo/E71_GLOBALS.4gl"
###########################################################################
# E71b - Maintainence program FOR Sales Conditions  Condition discounts Line Entry
###########################################################################
################################################################################
# FUNCTION lineitem_entry()
#
#
################################################################################
FUNCTION lineitem_entry() 
	DEFINE l_arr_rec_conddisc DYNAMIC ARRAY OF RECORD 
		scroll_flag char(1), 
		reqd_amt LIKE conddisc.reqd_amt, 
		bonus_check_per LIKE conddisc.bonus_check_per, 
		disc_check_per LIKE conddisc.disc_check_per, 
		disc_per LIKE conddisc.disc_per 
	END RECORD 
	DEFINE l_save_amt LIKE conddisc.reqd_amt 
	DEFINE l_idx SMALLINT 
	DEFINE i SMALLINT

	DECLARE c_conddisc cursor FOR 
	SELECT 
		"", 
		reqd_amt, 
		bonus_check_per, 
		disc_check_per, 
		disc_per 
	FROM t_conddisc 
	ORDER BY reqd_amt 

	LET l_idx = 1 
	FOREACH c_conddisc INTO l_arr_rec_conddisc[l_idx].* 
		LET l_idx = l_idx + 1 
	END FOREACH 
--	CALL l_arr_rec_conddisc.delete(l_idx-1)

	OPTIONS INSERT KEY f1, 
	DELETE KEY f2 
 
	MESSAGE kandoomsg2("E",1003,"") #" F1 TO Insert - F2 TO Delete - RETURN TO Edit"
	INPUT ARRAY l_arr_rec_conddisc WITHOUT DEFAULTS FROM sr_conddisc.* ATTRIBUTE(UNBUFFERED, auto append = false, insert row = false) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","E71b","inp-arr-l_arr_rec_conddisc") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			IF (l_arr_rec_conddisc[l_idx].reqd_amt = 0 OR l_arr_rec_conddisc[l_idx].reqd_amt IS NULL)
			OR 
			(
					(l_arr_rec_conddisc[l_idx].bonus_check_per IS NULL OR
					l_arr_rec_conddisc[l_idx].bonus_check_per = 0) 
					AND
					(l_arr_rec_conddisc[l_idx].disc_check_per IS NULL OR
					l_arr_rec_conddisc[l_idx].disc_check_per = 0) 
					AND
					(l_arr_rec_conddisc[l_idx].disc_per IS NULL OR 
					l_arr_rec_conddisc[l_idx].disc_per = 0) 
			) THEN
			
				CALL dialog.setActionHidden("APPEND",TRUE)
			ELSE
				CALL dialog.setActionHidden("APPEND",FALSE)
			END IF
			
--		AFTER FIELD scroll_flag 
--			LET l_arr_rec_conddisc[l_idx].scroll_flag = NULL 

		BEFORE FIELD reqd_amt 
			LET l_save_amt = l_arr_rec_conddisc[l_idx].reqd_amt 
			IF l_save_amt IS NULL THEN 
				LET l_save_amt = 0 
			END IF 

		AFTER FIELD reqd_amt 
			IF l_arr_rec_conddisc[l_idx].reqd_amt IS NULL THEN 
				IF fgl_lastkey() = fgl_keyval("down") 
				OR fgl_lastkey() = fgl_keyval("up") 
				OR fgl_lastkey() = fgl_keyval("left") THEN 
					CALL l_arr_rec_conddisc.delete(l_idx) --INITIALIZE l_arr_rec_conddisc[l_idx].* TO NULL 
					NEXT FIELD scroll_flag 
				ELSE 
					ERROR kandoomsg2("E",9019,"") 	#9019 Reqd Amt must be Entered
					NEXT FIELD reqd_amt 
				END IF 
			ELSE 
				IF l_arr_rec_conddisc[l_idx].reqd_amt < 0 THEN 
					ERROR kandoomsg2("E",9020,"") 		#9020 Reqd Amt must be Entered
					NEXT FIELD reqd_amt 
				ELSE 
					IF l_save_amt != l_arr_rec_conddisc[l_idx].reqd_amt THEN 
						FOR i = 1 TO arr_count() 
							IF l_arr_rec_conddisc[i].reqd_amt=l_arr_rec_conddisc[l_idx].reqd_amt 
							AND i != l_idx THEN 
								ERROR kandoomsg2("E",9038,"") 			#9038" This Amount has Previously been Entered"
								LET l_arr_rec_conddisc[l_idx].reqd_amt = l_save_amt 
								NEXT FIELD reqd_amt 
							END IF 
						END FOR 
					END IF 
				END IF 
			END IF 

		AFTER FIELD bonus_check_per 
			IF l_arr_rec_conddisc[l_idx].bonus_check_per IS NULL THEN 
				ERROR kandoomsg2("E",9039,"") 	#9039" Bonus Check Percentage must be Entered"
				LET l_arr_rec_conddisc[l_idx].bonus_check_per = 0 
				NEXT FIELD bonus_check_per 
			END IF 
			IF l_arr_rec_conddisc[l_idx].bonus_check_per < 0 
			OR l_arr_rec_conddisc[l_idx].bonus_check_per > 100 THEN 
				ERROR kandoomsg2("E",9040,"") 	#9040" Bonus check percentage must be between 0 AND 100
				LET l_arr_rec_conddisc[l_idx].bonus_check_per = 0 
				NEXT FIELD bonus_check_per 
			END IF 

		AFTER FIELD disc_check_per 
			IF l_arr_rec_conddisc[l_idx].disc_check_per IS NULL THEN 
				ERROR kandoomsg2("E",9041,"") 			#9041" Discount Check Percentage must be Entered"
				LET l_arr_rec_conddisc[l_idx].disc_check_per = 0 
				NEXT FIELD disc_check_per 
			END IF 
			IF l_arr_rec_conddisc[l_idx].disc_check_per < 0 
			OR l_arr_rec_conddisc[l_idx].disc_check_per > 100 THEN 
				ERROR kandoomsg2("E",9042,"") 		#9042" Discount check percentage must be between 0 AND 100
				LET l_arr_rec_conddisc[l_idx].disc_check_per = 0 
				NEXT FIELD disc_check_per 
			END IF 

		AFTER FIELD disc_per 
			IF l_arr_rec_conddisc[l_idx].disc_per IS NULL THEN 
				ERROR kandoomsg2("E",9023,"") 		#9023" Discount Percentage must be Entered"
				LET l_arr_rec_conddisc[l_idx].disc_per = 0 
				NEXT FIELD disc_per 
			END IF 
			IF l_arr_rec_conddisc[l_idx].disc_per < 0 
			OR l_arr_rec_conddisc[l_idx].disc_per > 100 THEN 
				ERROR kandoomsg2("E",9034,"") 		#9034 Discount percentage must be between 0 AND 100
				LET l_arr_rec_conddisc[l_idx].disc_per = 0 
				NEXT FIELD disc_per 
			END IF 

		BEFORE INSERT 
			IF arr_curr() <= arr_count() THEN 
				NEXT FIELD reqd_amt 
			END IF 

		BEFORE DELETE 
			INITIALIZE l_arr_rec_conddisc[l_idx].* TO NULL 

		AFTER ROW 
			IF l_arr_rec_conddisc[l_idx].reqd_amt IS NOT NULL THEN 
				IF l_arr_rec_conddisc[l_idx].bonus_check_per IS NULL 
				OR l_arr_rec_conddisc[l_idx].bonus_check_per < 0 
				OR l_arr_rec_conddisc[l_idx].bonus_check_per > 100 THEN 
					LET l_arr_rec_conddisc[l_idx].bonus_check_per = 0 
				END IF 
				IF l_arr_rec_conddisc[l_idx].disc_check_per IS NULL 
				OR l_arr_rec_conddisc[l_idx].disc_check_per < 0 
				OR l_arr_rec_conddisc[l_idx].disc_check_per > 100 THEN 
					LET l_arr_rec_conddisc[l_idx].disc_check_per = 0 
				END IF 
				IF l_arr_rec_conddisc[l_idx].disc_per IS NULL 
				OR l_arr_rec_conddisc[l_idx].disc_per < 0 
				OR l_arr_rec_conddisc[l_idx].disc_per > 100 THEN 
					LET l_arr_rec_conddisc[l_idx].disc_per = 0 
				END IF 
			ELSE 
				INITIALIZE l_arr_rec_conddisc[l_idx].* TO NULL 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET quit_flag = FALSE 
		LET int_flag = FALSE 
	ELSE 
		DELETE FROM t_conddisc 
		FOR l_idx = 1 TO arr_count() 
			IF l_arr_rec_conddisc[l_idx].reqd_amt IS NOT NULL THEN
			 
				SELECT unique 1 FROM t_conddisc 
				WHERE reqd_amt = l_arr_rec_conddisc[l_idx].reqd_amt 
				IF status = NOTFOUND THEN
				 
					INSERT INTO t_conddisc 
					VALUES (l_arr_rec_conddisc[l_idx].reqd_amt, 
					l_arr_rec_conddisc[l_idx].bonus_check_per, 
					l_arr_rec_conddisc[l_idx].disc_check_per, 
					l_arr_rec_conddisc[l_idx].disc_per)
					 
				END IF 
			END IF 
		END FOR 
	END IF 

END FUNCTION
################################################################################
# END FUNCTION lineitem_entry()
################################################################################