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

	Source code beautified by beautify.pl on 2020-01-03 13:41:34	$Id: $
}
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_P7_GLOBALS.4gl"
GLOBALS "../ap/P71_GLOBALS.4gl"

############################################################
# MODULE Scope Variables
############################################################


############################################################
# FUNCTION update_db() 
#
#
############################################################
FUNCTION update_db() 
	DEFINE l_rec_recurdetl RECORD LIKE recurdetl.* 
	DEFINE l_rec_term RECORD LIKE term.* 
	DEFINE l_rev_num LIKE recurhead.rev_num 
	DEFINE l_run_num LIKE recurhead.run_num 
	DEFINE l_disc_date DATE 
	DEFINE l_err_message CHAR(60) 
	DEFINE l_msgresp LIKE language.yes_flag
	DEFINE r_rowid INTEGER
	
	LET l_msgresp = kandoomsg("P",1005,"") 
	#1005 Updating Database - pls wait
	SELECT sum(dist_amt),sum(dist_qty) 
	INTO glob_rec_recurhead.dist_amt, 
	glob_rec_recurhead.dist_qty 
	FROM t_recurdetl 
	IF glob_rec_recurhead.dist_amt IS NULL THEN 
		LET glob_rec_recurhead.dist_amt = 0 
	END IF 
	IF glob_rec_recurhead.dist_qty IS NULL THEN 
		LET glob_rec_recurhead.dist_qty = 0 
	END IF 
	IF glob_rec_recurhead.tax_code IS NOT NULL THEN 
		SELECT ((tax_per/100)*glob_rec_recurhead.total_amt) 
		INTO glob_rec_recurhead.tax_amt 
		FROM tax 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND tax_code = glob_rec_recurhead.tax_code 
	ELSE 
		LET glob_rec_recurhead.tax_amt = 0 
	END IF 
	LET glob_rec_recurhead.goods_amt = glob_rec_recurhead.total_amt 
	IF glob_rec_recurhead.term_code IS NULL THEN 
		SELECT term_code INTO l_rec_term.term_code 
		FROM vendor 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND vend_code = glob_rec_recurhead.vend_code 
	ELSE 
		LET l_rec_term.term_code = glob_rec_recurhead.term_code 
	END IF 
	SELECT * INTO l_rec_term.* 
	FROM term 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND term_code = l_rec_term.term_code 
	CALL get_due_and_discount_date(l_rec_term.*, glob_rec_recurhead.next_vouch_date) 
	RETURNING glob_rec_recurhead.next_due_date, 
	l_disc_date 
	GOTO bypass 
	LABEL recovery: 
	IF error_recover(l_err_message, status) != "Y" THEN 
		RETURN false 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		SELECT rev_num,run_num 
		INTO l_rev_num, l_run_num 
		FROM recurhead 
		WHERE cmpy_code = glob_rec_recurhead.cmpy_code 
		AND recur_code = glob_rec_recurhead.recur_code 
		IF sqlca.sqlcode = NOTFOUND THEN 
			LET glob_rec_recurhead.rev_num = 0 
		ELSE 
			IF l_rev_num != glob_rec_recurhead.rev_num THEN 
				LET l_err_message="P71 - Recurring Payment updated by another user" 
				GOTO recovery 
			END IF 
			LET glob_rec_recurhead.rev_num = glob_rec_recurhead.rev_num + 1 
			LET glob_rec_recurhead.rev_code = glob_rec_kandoouser.sign_on_code 
			LET glob_rec_recurhead.rev_date = today 
			IF l_run_num != glob_rec_recurhead.run_num THEN 
				LET l_err_message="P71 - Recurring Payment processed by another user" 
				GOTO recovery 
			END IF 
		END IF 
		LET l_err_message = "P71 - Deleting distributions " 
		DELETE FROM recurdetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND recur_code = glob_rec_recurhead.recur_code 
		DECLARE c_recurdetl CURSOR FOR 
		SELECT * FROM t_recurdetl 
		ORDER BY line_num 
		LET l_err_message = "P71 - Inserting distributions " 
		LET glob_rec_recurhead.line_num = 0 
		FOREACH c_recurdetl INTO l_rec_recurdetl.* 
			LET glob_rec_recurhead.line_num = glob_rec_recurhead.line_num + 1 
			LET l_rec_recurdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET l_rec_recurdetl.recur_code = glob_rec_recurhead.recur_code 
			LET l_rec_recurdetl.line_num = glob_rec_recurhead.line_num 
			INSERT INTO recurdetl VALUES (l_rec_recurdetl.*) 
		END FOREACH 
		LET l_err_message = "P71 - Updating Recurring Payment" 
		UPDATE recurhead 
		SET recurhead.* = glob_rec_recurhead.* 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND recur_code = glob_rec_recurhead.recur_code 
		LET r_rowid = sqlca.sqlerrd[3] 
		IF r_rowid = 0 THEN 
			LET l_err_message = "P71 - Inserting Recurring Payment " 
			INSERT INTO recurhead VALUES (glob_rec_recurhead.*) 
			LET r_rowid = sqlca.sqlerrd[6] 
		END IF 
	COMMIT WORK 
	RETURN r_rowid 
	WHENEVER ERROR stop 
END FUNCTION 


