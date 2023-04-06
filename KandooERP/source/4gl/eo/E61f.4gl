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
GLOBALS "../eo/E6_GROUP_GLOBALS.4gl"
GLOBALS "../eo/E61_GLOBALS.4gl"
################################################################################
# FUNCTION update_database()
#
# E61f - Maintainence program FOR Sales Order Special Offers
#        Database UPDATE module
################################################################################
FUNCTION update_database() 
	DEFINE l_rec_offerprod RECORD LIKE offerprod.* 
	DEFINE l_rec_offerauto RECORD LIKE offerauto.* 
--	DEFINE l_rec_s_offerauto RECORD LIKE offerauto.* 
	DEFINE l_rec_proddisc RECORD LIKE proddisc.* 
	DEFINE l_err_message char(80) 
	DEFINE l_err_continue char(1) 

	MESSAGE kandoomsg2("E",1005,"")	#1005 " Updating Database - please wait

	GOTO bypass 
	LABEL recovery: 
	LET l_err_continue = error_recover(l_err_message, status) 
	IF l_err_continue != "Y" THEN 
		EXIT PROGRAM 
	END IF 

	LABEL bypass: 

	WHENEVER ERROR GOTO recovery 

	BEGIN WORK 
		LET l_err_message = "E61 - Deleting Special Offer Product lines" 
		DELETE FROM offerprod 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND offer_code = glob_rec_offersale.offer_code 
		DECLARE c_offerprod cursor FOR 
		SELECT "", 
		"", 
		t_offerprod.* 
		FROM t_offerprod 
		LET l_err_message = "E61 - Inserting Special Offer Product lines" 

		FOREACH c_offerprod INTO l_rec_offerprod.* 
			LET l_rec_offerprod.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET l_rec_offerprod.offer_code = glob_rec_offersale.offer_code 
			IF glob_rec_offersale.checktype_ind = "1" THEN 
				IF l_rec_offerprod.reqd_qty IS NULL THEN 
					LET l_rec_offerprod.reqd_qty = 0 
				END IF 
				LET l_rec_offerprod.reqd_amt = NULL 
			ELSE 
				IF l_rec_offerprod.reqd_amt IS NULL THEN 
					LET l_rec_offerprod.reqd_amt = 0 
				END IF 
				LET l_rec_offerprod.reqd_qty = NULL 
			END IF 
			INSERT INTO offerprod VALUES (l_rec_offerprod.*) 
		END FOREACH 

		LET l_err_message = "E61 - Deleting Product Line Discount lines" 

		DELETE FROM proddisc 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND key_num = glob_rec_offersale.offer_code 
		AND type_ind = "2" 

		DECLARE c_proddisc cursor FOR 
		SELECT "", #cmpy_code 
		"", #key_num 
		"", #type_ind 
		t_proddisc.* 
		FROM t_proddisc 
		LET l_err_message = "E61 - Inserting Product Line Discount lines" 

		FOREACH c_proddisc INTO l_rec_proddisc.* 
			LET l_rec_proddisc.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET l_rec_proddisc.key_num = glob_rec_offersale.offer_code 
			LET l_rec_proddisc.type_ind = "2" 
			IF glob_rec_offersale.checktype_ind = "1" THEN 
				IF l_rec_proddisc.reqd_qty IS NULL THEN 
					LET l_rec_proddisc.reqd_qty = 0 
				END IF 
				LET l_rec_proddisc.reqd_amt = NULL 
			ELSE 
				IF l_rec_proddisc.reqd_amt IS NULL THEN 
					LET l_rec_proddisc.reqd_amt = 0 
				END IF 
				LET l_rec_proddisc.reqd_qty = NULL 
			END IF 
			INSERT INTO proddisc VALUES (l_rec_proddisc.*) 
		END FOREACH 

		LET l_err_message = "E61 - Deleting Auto Product lines" 
		DELETE FROM offerauto 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND offer_code = glob_rec_offersale.offer_code 
		DECLARE c_offerauto cursor FOR 
		SELECT t_offerauto.* 
		FROM t_offerauto 

		LET l_err_message = "E61 - Inserting Auto Product lines" 

		FOREACH c_offerauto INTO l_rec_offerauto.part_code, 
			l_rec_offerauto.bonus_qty, 
			l_rec_offerauto.sold_qty, 
			l_rec_offerauto.price_amt, 
			l_rec_offerauto.disc_per, 
			l_rec_offerauto.disc_allow_flag, 
			l_rec_offerauto.status_ind 
			LET l_rec_offerauto.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET l_rec_offerauto.offer_code = glob_rec_offersale.offer_code 
			LET l_rec_offerauto.disc_allow_flag = 
			xlate_to(l_rec_offerauto.disc_allow_flag) 
			LET l_rec_offerauto.status_ind = 
			xlate_to(l_rec_offerauto.status_ind) 
			INSERT INTO offerauto VALUES (l_rec_offerauto.*) 
		END FOREACH 

		LET l_err_message = "E61 - Updating Special Offer header" 
		LET glob_rec_offersale.auto_prod_flag = xlate_to(glob_rec_offersale.auto_prod_flag) 
		LET glob_rec_offersale.prodline_disc_flag = xlate_to(glob_rec_offersale.prodline_disc_flag) 
		LET glob_rec_offersale.grp_disc_flag = xlate_to(glob_rec_offersale.grp_disc_flag) 

		UPDATE offersale 
		SET offersale.* = glob_rec_offersale.* 
		WHERE cmpy_code = glob_rec_offersale.cmpy_code 
		AND offer_code = glob_rec_offersale.offer_code 

		IF sqlca.sqlerrd[3] = 0 THEN 
			LET l_err_message = "E61 - Inserting Special Offer header" 
			LET glob_rec_offersale.cmpy_code = glob_rec_kandoouser.cmpy_code 
			INSERT INTO offersale VALUES (glob_rec_offersale.*) 
		END IF 

	COMMIT WORK 

	WHENEVER ERROR stop 

	RETURN glob_rec_offersale.offer_code 
END FUNCTION 