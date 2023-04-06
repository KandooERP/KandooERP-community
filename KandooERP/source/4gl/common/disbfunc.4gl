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
	Source code beautified by beautify.pl on 2020-01-02 10:35:10	$Id: $
}
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

############################################################
# MODULE Scope Variables
############################################################

############################################################
# FUNCTION enter_disb(p_cmpy,p_acct_code,p_undist_amt)
#
# FUNCTION disbfunc.4gl - Common routine FOR entering a disbursement.
# Used by distribution facilities,  (voucher,receipt...)
############################################################
FUNCTION enter_disb(p_cmpy,p_acct_code,p_undist_amt) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_acct_code LIKE disbhead.acct_code 
	DEFINE p_undist_amt LIKE recurdetl.dist_amt 
	DEFINE l_rec_disbhead RECORD LIKE disbhead.* 
	DEFINE l_dist_amt LIKE recurdetl.dist_amt 
	DEFINE l_pr_temp_text CHAR(40) 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW p194 with FORM "P194" 
	CALL winDecoration_p("P194") -- albo kd-752 
	IF p_acct_code IS NOT NULL THEN 
		DECLARE c_disbhead CURSOR FOR 
		SELECT * FROM disbhead 
		WHERE cmpy_code = p_cmpy 
		AND acct_code = p_acct_code 
		OPEN c_disbhead 
		FETCH c_disbhead INTO l_rec_disbhead.* 
		IF status = 0 THEN 
			DISPLAY BY NAME l_rec_disbhead.desc_text 

		END IF 
		CLOSE c_disbhead 
	END IF 

	LET l_dist_amt = p_undist_amt 

	INPUT l_rec_disbhead.disb_code, l_dist_amt WITHOUT DEFAULTS FROM disb_code, dist_amt attributes(UNBUFFERED) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","disbfunc","input-disbhead") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (disb_code) 
			LET l_pr_temp_text = show_disb(p_cmpy,"") 
			IF l_pr_temp_text IS NOT NULL THEN 
				LET l_rec_disbhead.disb_code = l_pr_temp_text 
				NEXT FIELD disb_code 
			END IF 

		ON CHANGE disb_code
			DISPLAY db_disbhead_get_desc_text(UI_OFF,l_rec_disbhead.disb_code) TO disbhead.desc_text

		AFTER FIELD disb_code 
			IF l_rec_disbhead.disb_code IS NULL THEN 
				LET l_msgresp=kandoomsg("P",9038,"") 
				#P9038 "Must enter a disbursement code"
				NEXT FIELD disb_code 
			ELSE 
				SELECT * INTO l_rec_disbhead.* 
				FROM disbhead 
				WHERE cmpy_code = p_cmpy 
				AND disb_code = l_rec_disbhead.disb_code 
				IF sqlca.sqlcode = notfound THEN 
					LET l_msgresp=kandoomsg("P",9039,"") 
					#P9039 "Disbursement Code does NOT exist"
					NEXT FIELD disb_code 
				ELSE 
					DISPLAY BY NAME l_rec_disbhead.desc_text 

				END IF 
			END IF 

		AFTER FIELD dist_amt 
			CASE 
				WHEN l_dist_amt IS NULL 
					LET l_dist_amt = p_undist_amt 
					NEXT FIELD dist_amt 
				WHEN (l_dist_amt <= 0 AND p_undist_amt > 0) 
					LET l_msgresp=kandoomsg("P",9019,"") 
					#P9019 Must enter a positive amount"
					NEXT FIELD dist_amt 
				WHEN (l_dist_amt > 0 AND p_undist_amt < 0) 
					LET l_msgresp=kandoomsg("P",9015,"") 
					#P9015 " Amount will exceed voucher total"
					NEXT FIELD dist_amt 
				WHEN (l_dist_amt > p_undist_amt AND p_undist_amt > 0) 
					OR (l_dist_amt < p_undist_amt AND p_undist_amt < 0) 
					LET l_msgresp=kandoomsg("P",9015,"") 
					#P9015 " Amount will exceed voucher total"
					NEXT FIELD dist_amt 
			END CASE 

	END INPUT 

	CLOSE WINDOW p194 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		INITIALIZE l_rec_disbhead.disb_code TO NULL 
	END IF 

	RETURN l_rec_disbhead.disb_code, l_dist_amt 
END FUNCTION 
