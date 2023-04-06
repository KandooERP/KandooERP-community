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
# E71f - Maintainence program FOR Sales Condition  Database UPDATE module
###########################################################################

################################################################################
# FUNCTION update_database()
#
#
################################################################################
FUNCTION update_database() 
	DEFINE l_rec_conddisc RECORD LIKE conddisc.* 
	DEFINE l_rec_proddisc RECORD LIKE proddisc.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_err_message char(80) 
	DEFINE x char(1) 
	DEFINE l_err_continue char(1) 
 
	ERROR kandoomsg2("E",1005,"") 	#1005 " Updating Database - please wait
	GOTO bypass 
	LABEL recovery: 
	LET l_err_continue = error_recover(l_err_message, status) 
	IF l_err_continue != "Y" THEN 
		EXIT PROGRAM 
	END IF 

	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	BEGIN WORK 
		LET l_err_message = "E71 - Deleting Sales Conditions Discount lines" 
		DELETE FROM conddisc 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cond_code = glob_rec_condsale.cond_code 
		DECLARE c_conddisc cursor FOR 
		SELECT "", 
		"", 
		t_conddisc.* 
		FROM t_conddisc 
		LET l_err_message = "E71 - Inserting Sales Conditions Discount lines" 
		LET glob_rec_condsale.tier_disc_flag = "N" 

		FOREACH c_conddisc INTO l_rec_conddisc.* 
			IF l_rec_conddisc.reqd_amt IS NOT NULL THEN 
				LET l_rec_conddisc.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_rec_conddisc.cond_code = glob_rec_condsale.cond_code 
				IF l_rec_conddisc.bonus_check_per IS NULL THEN 
					LET l_rec_conddisc.bonus_check_per = 0 
				END IF 
				IF l_rec_conddisc.disc_check_per IS NULL THEN 
					LET l_rec_conddisc.disc_check_per = 0 
				END IF 
				IF l_rec_conddisc.disc_per IS NULL THEN 
					LET l_rec_conddisc.disc_per = 0 
				END IF 
				INSERT INTO conddisc VALUES (l_rec_conddisc.*) 
				LET glob_rec_condsale.tier_disc_flag = "Y" 
			END IF 
		END FOREACH 

		LET l_err_message = "E71 - Deleting Product Line Discount lines" 
		DELETE FROM proddisc 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND key_num = glob_rec_condsale.cond_code 
		AND type_ind = "1" 
		DECLARE c_proddisc cursor FOR 
		SELECT "", #cmpy_code 
		"", #key_num 
		"", #type_ind 
		t_proddisc.* 
		FROM t_proddisc 

		LET l_err_message = "E71 - Inserting Product Line Discount lines" 
		LET glob_rec_condsale.prodline_disc_flag = "N" 

		FOREACH c_proddisc INTO l_rec_proddisc.* 
			LET l_rec_proddisc.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET l_rec_proddisc.key_num = glob_rec_condsale.cond_code 
			LET l_rec_proddisc.type_ind = "1" 
			IF l_rec_proddisc.reqd_amt IS NULL THEN 
				LET l_rec_proddisc.reqd_amt = 0 
			END IF 
			IF l_rec_proddisc.disc_per IS NULL THEN 
				LET l_rec_proddisc.disc_per = 0 
			END IF 
			LET l_rec_proddisc.reqd_qty = NULL 
			INSERT INTO proddisc VALUES (l_rec_proddisc.*) 
			LET glob_rec_condsale.prodline_disc_flag = "Y" 
		END FOREACH 

		LET l_err_message = "E71 - Selecting Customers FOR update" 
		DECLARE c_condcust cursor FOR 
		SELECT t_condcust.cust_code, 
		t_condcust.cond_code 
		FROM t_condcust 
		WHERE cond_code != old_cond_code 
		OR (cond_code IS NULL AND old_cond_code IS NOT null) 
		OR (cond_code IS NOT NULL AND old_cond_code IS null) 
		LET l_err_message = "E71 - Updating customers" 

		FOREACH c_condcust INTO l_rec_customer.cust_code, 
			l_rec_customer.cond_code 
			UPDATE customer 
			SET cond_code = l_rec_customer.cond_code 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = l_rec_customer.cust_code 
		END FOREACH 

		LET l_err_message = "E71 - Updating Sales Condition header" 
		LET glob_rec_condsale.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET glob_rec_condsale.prodline_disc_flag = xlate_to(glob_rec_condsale.prodline_disc_flag) 
		UPDATE condsale 
		SET condsale.* = glob_rec_condsale.* 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cond_code = glob_rec_condsale.cond_code 
		IF sqlca.sqlerrd[3] = 0 THEN 
			LET l_err_message = "E71 - Inserting Sales Condition header" 
			INSERT INTO condsale VALUES (glob_rec_condsale.*) 
		END IF 

	COMMIT WORK 

	WHENEVER ERROR stop 

	RETURN glob_rec_condsale.cond_code 
END FUNCTION 
################################################################################
# END FUNCTION update_database()
################################################################################