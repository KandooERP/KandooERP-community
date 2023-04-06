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

	Source code beautified by beautify.pl on 2020-01-02 17:06:24	Source code beautified by beautify.pl on 2020-01-02 17:03:33	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../pu/R_PU_GLOBALS.4gl" 

############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_rec_puparms RECORD LIKE puparms.* 
DEFINE modu_rec_journal RECORD LIKE journal.* 
DEFINE modu_rec_coa RECORD LIKE coa.* 

#######################################################################
# MAIN
#
# module RZP - Purchasing Parameters provides maintenance of Purchasing Set Up Parameters
# TABLE: puparms
#
# Generally outlines of the Purchasing system, including next purchase ORDER numbers AND the General Ledger account numbers used.
#
# Note:  Use extreme caution when altering any information in the parameters file once the system has been SET up AND IS in use.
#######################################################################
MAIN 

	CALL setModuleId("RZP") -- albo 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_r_pu() #init r/pu purchase ORDER module 

	OPEN WINDOW r104 with FORM "R104" 
	CALL  windecoration_r("R104") 

	MENU "Parameters" 
		BEFORE MENU 
			IF display_params() THEN 
				HIDE option "Add" 
			ELSE 
				HIDE option "Edit" 
			END IF 
			CALL publish_toolbar("kandoo","RZP","menu-parameters-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		COMMAND "Add" " Add Parameters" 
			IF input_params("ADD") THEN 
				HIDE option "Add" 
				SHOW option "Edit" 
			END IF 
			IF display_params() THEN 
			END IF 

		COMMAND "Edit" " Change Parameters" 
			IF input_params("EDIT") THEN 
			END IF 
			IF display_params() THEN 
			END IF 

		ON ACTION "CANCEL" # "Exit" " Exit TO menus" 
			EXIT MENU 

			#COMMAND KEY (control-w)
			#   CALL kandoohelp("")

	END MENU 

	CLOSE WINDOW r104 
END MAIN 


#######################################################################
# FUNCTION input_params(p_mode)
#
#
#######################################################################
FUNCTION input_params(p_mode) 
	DEFINE p_mode CHAR(4) 
	DEFINE l_rec_t_puparms RECORD LIKE puparms.* 
	DEFINE l_rec_s_puparms RECORD LIKE puparms.* 
	DEFINE l_temp_text CHAR(30) 
	DEFINE l_err_message CHAR(60) 
	DEFINE l_temp_po_num LIKE puparms.next_po_num 
	DEFINE l_temp_receipt_num LIKE puparms.next_receipt_num 

	IF p_mode = "ADD" THEN 
		INITIALIZE modu_rec_puparms.* TO NULL 
	ELSE 
		SELECT * INTO modu_rec_puparms.* FROM puparms 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND key_code = "1" 
		LET l_rec_s_puparms.* = modu_rec_puparms.* 
	END IF 
	LET msgresp = kandoomsg("U",1070,"") 
	#1070 Enter Parameter details; OK TO continue.
	INPUT BY NAME modu_rec_puparms.next_po_num, 
	modu_rec_puparms.next_ship_num, 
	modu_rec_puparms.next_receipt_num, 
	modu_rec_puparms.usual_ware_code, 
	modu_rec_puparms.usual_conf_flag, 
	modu_rec_puparms.post_method_ind, 
	modu_rec_puparms.over_meth_flag, 
	modu_rec_puparms.receipt_jour_code, 
	modu_rec_puparms.commit_jour_code, 
	modu_rec_puparms.purch_jour_code, 
	modu_rec_puparms.commit_acct_code, 
	modu_rec_puparms.goodsin_acct_code, 
	modu_rec_puparms.accrued_acct_code, 
	modu_rec_puparms.clear_acct_code WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","RZP","inp-puparms-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		ON KEY (control-b) infield (commit_jour_code) 
			LET l_temp_text = show_jour(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET modu_rec_puparms.commit_jour_code = l_temp_text 
				#DISPLAY BY NAME modu_rec_puparms.commit_jour_code
			END IF 
			#NEXT FIELD commit_jour_code

		ON KEY (control-b) infield (receipt_jour_code) 
			LET l_temp_text = show_jour(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET modu_rec_puparms.receipt_jour_code = l_temp_text 
				#   DISPLAY BY NAME modu_rec_puparms.receipt_jour_code

			END IF 
			#NEXT FIELD receipt_jour_code

		ON KEY (control-b) infield (purch_jour_code) 
			LET l_temp_text = show_jour(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET modu_rec_puparms.purch_jour_code = l_temp_text 
				#   DISPLAY BY NAME modu_rec_puparms.purch_jour_code

			END IF 
			#NEXT FIELD purch_jour_code

		ON KEY (control-b) infield (commit_acct_code) 
			LET modu_rec_puparms.commit_acct_code = show_acct(glob_rec_kandoouser.cmpy_code) 
			#DISPLAY BY NAME modu_rec_puparms.commit_acct_code

			#NEXT FIELD commit_acct_code

		ON KEY (control-b) infield (goodsin_acct_code) 
			LET l_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET modu_rec_puparms.goodsin_acct_code = l_temp_text 
				#   DISPLAY BY NAME modu_rec_puparms.goodsin_acct_code

			END IF 
			#NEXT FIELD goodsin_acct_code

		ON KEY (control-b) infield (accrued_acct_code) 
			LET l_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET modu_rec_puparms.accrued_acct_code = l_temp_text 
				#   DISPLAY BY NAME modu_rec_puparms.accrued_acct_code

			END IF 
			#NEXT FIELD accrued_acct_code

		ON KEY (control-b) infield (clear_acct_code) 
			LET l_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET modu_rec_puparms.clear_acct_code = l_temp_text 
				#   DISPLAY BY NAME modu_rec_puparms.clear_acct_code

			END IF 
			#NEXT FIELD clear_acct_code

		ON KEY (control-b) infield (usual_ware_code) 
			LET l_temp_text = show_ware(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET modu_rec_puparms.usual_ware_code = l_temp_text 
				#   DISPLAY BY NAME modu_rec_puparms.usual_ware_code

			END IF 
			#NEXT FIELD usual_ware_code

		BEFORE FIELD next_po_num 
			LET l_temp_po_num = modu_rec_puparms.next_po_num 

		AFTER FIELD next_po_num 
			IF l_temp_po_num != modu_rec_puparms.next_po_num 
			OR modu_rec_puparms.next_po_num IS NULL THEN 
				SELECT max(order_num) INTO l_temp_po_num 
				FROM purchhead 
				WHERE purchhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_temp_po_num = l_temp_po_num + 1 
			END IF 

			IF modu_rec_puparms.next_po_num < l_temp_po_num 
			OR modu_rec_puparms.next_po_num IS NULL THEN 
				LET msgresp = kandoomsg("R",9526,l_temp_po_num) 
				#9526 Next Purchase Order Number cannot be less than XXX.
				LET modu_rec_puparms.next_po_num = l_temp_po_num 
				NEXT FIELD next_po_num 
			END IF 

		AFTER FIELD next_ship_num 
			IF modu_rec_puparms.next_ship_num <= 0 
			OR modu_rec_puparms.next_ship_num IS NULL THEN 
				LET msgresp = kandoomsg("R",9536,"") 
				#9536 Next Shipment number must be greater than zero.
				NEXT FIELD next_ship_num 
			END IF 

		BEFORE FIELD next_receipt_num 
			LET l_temp_receipt_num = modu_rec_puparms.next_receipt_num 

		AFTER FIELD next_receipt_num 
			IF l_temp_receipt_num != modu_rec_puparms.next_receipt_num 
			OR modu_rec_puparms.next_receipt_num IS NULL THEN 
				SELECT max(tran_num) INTO l_temp_receipt_num 
				FROM poaudit 
				WHERE poaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND tran_code = "GR" 
				LET l_temp_receipt_num = l_temp_receipt_num + 1 
			END IF 

			IF modu_rec_puparms.next_receipt_num < l_temp_receipt_num 
			OR modu_rec_puparms.next_receipt_num IS NULL THEN 
				LET msgresp = kandoomsg("R",9527,l_temp_receipt_num) 
				#9527 Next Receipt Number cannot be less than XXX.
				LET modu_rec_puparms.next_receipt_num = l_temp_receipt_num 
				NEXT FIELD next_receipt_num 
			END IF 

		AFTER FIELD usual_ware_code 
			IF modu_rec_puparms.usual_ware_code IS NOT NULL THEN 
				SELECT unique 1 FROM warehouse 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = modu_rec_puparms.usual_ware_code 

				IF status = notfound THEN 
					LET msgresp = kandoomsg("U",9105,"") 
					#9105 RECORD NOT found; Try Window.
					NEXT FIELD usual_ware_code 
				END IF 
			END IF 

		AFTER FIELD receipt_jour_code 
			SELECT journal.* INTO modu_rec_journal.* FROM journal 
			WHERE journal.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND journal.jour_code = modu_rec_puparms.receipt_jour_code 

			IF status = notfound THEN 
				LET msgresp = kandoomsg("R",9528,"") 
				#9528 Goods Receipts Journal NOT found; Try Window.
				NEXT FIELD receipt_jour_code 
			END IF 

			DISPLAY modu_rec_journal.desc_text TO jour_desc1_text 

		AFTER FIELD commit_jour_code 
			SELECT journal.* INTO modu_rec_journal.* FROM journal 
			WHERE journal.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND journal.jour_code = modu_rec_puparms.commit_jour_code 

			IF status = notfound THEN 
				LET msgresp = kandoomsg("R",9529,"") 
				#9529 Commitments Journal NOT found; Try Window.
				NEXT FIELD commit_jour_code 
			END IF 

			DISPLAY modu_rec_journal.desc_text TO jour_desc2_text 

		AFTER FIELD purch_jour_code 
			SELECT journal.* INTO modu_rec_journal.* FROM journal 
			WHERE journal.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND journal.jour_code = modu_rec_puparms.purch_jour_code 

			IF status = notfound THEN 
				LET msgresp = kandoomsg("R",9530,"") 
				#9530 Purchase Orders Journal NOT found; Try Window.
				NEXT FIELD purch_jour_code 
			END IF 

			DISPLAY modu_rec_journal.desc_text TO jour_desc3_text 

		AFTER FIELD commit_acct_code 
			SELECT coa.* INTO modu_rec_coa.* FROM coa 
			WHERE coa.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND coa.acct_code = modu_rec_puparms.commit_acct_code 

			IF status = notfound THEN 
				LET msgresp = kandoomsg("R",9531,"") 
				#9531 Commitments Account NOT found; Try Window.
				NEXT FIELD commit_acct_code 
			END IF 

			DISPLAY modu_rec_coa.desc_text TO coa_desc1_text 

		AFTER FIELD goodsin_acct_code 
			SELECT coa.* INTO modu_rec_coa.* FROM coa 
			WHERE coa.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND coa.acct_code = modu_rec_puparms.goodsin_acct_code 

			IF status = notfound THEN 
				LET msgresp = kandoomsg("R",9532,"") 
				#9532 Goods On Order Account NOT found; Try Window.
				NEXT FIELD goodsin_acct_code 
			END IF 

			DISPLAY modu_rec_coa.desc_text TO coa_desc2_text 

		AFTER FIELD accrued_acct_code 
			SELECT coa.* INTO modu_rec_coa.* FROM coa 
			WHERE coa.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND coa.acct_code = modu_rec_puparms.accrued_acct_code 

			IF status = notfound THEN 
				LET msgresp = kandoomsg("R",9533,"") 
				#9533 Accrued Expenses Account NOT found; Try Window.
				NEXT FIELD accrued_acct_code 
			END IF 

			DISPLAY modu_rec_coa.desc_text TO coa_desc3_text 

		AFTER FIELD clear_acct_code 
			SELECT coa.* INTO modu_rec_coa.* FROM coa 
			WHERE coa.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND coa.acct_code = modu_rec_puparms.clear_acct_code 

			IF status = notfound THEN 
				LET msgresp = kandoomsg("R",9534,"") 
				#9534 Expense Clearing Account NOT found; Try Window.
				NEXT FIELD clear_acct_code 
			END IF 

			DISPLAY modu_rec_coa.desc_text TO coa_desc4_text 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 

			IF modu_rec_puparms.next_po_num <= 0 
			OR modu_rec_puparms.next_po_num IS NULL THEN 
				LET msgresp = kandoomsg("R",9535,"") 
				#9535 Next Purchase Order number must be greater than zero.
				NEXT FIELD next_po_num 
			END IF 

			IF modu_rec_puparms.next_ship_num <= 0 
			OR modu_rec_puparms.next_ship_num IS NULL THEN 
				LET msgresp = kandoomsg("R",9536,"") 
				#9536 Next Shipment number must be greater than zero.
				NEXT FIELD next_ship_num 
			END IF 

			SELECT journal.* INTO modu_rec_journal.* FROM journal 
			WHERE journal.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND journal.jour_code = modu_rec_puparms.receipt_jour_code 

			IF status = notfound THEN 
				LET msgresp = kandoomsg("R",9528,"") 
				#9528 Goods Receipts Journal NOT found; Try Window.
				NEXT FIELD receipt_jour_code 
			END IF 

			SELECT journal.* INTO modu_rec_journal.* FROM journal 
			WHERE journal.jour_code = modu_rec_puparms.commit_jour_code 
			AND journal.cmpy_code = glob_rec_kandoouser.cmpy_code 

			IF status = notfound THEN 
				LET msgresp = kandoomsg("R",9529,"") 
				#9529 Commitments Journal NOT found; Try Window.
				NEXT FIELD commit_jour_code 
			END IF 

			SELECT journal.* INTO modu_rec_journal.* FROM journal 
			WHERE journal.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND journal.jour_code = modu_rec_puparms.purch_jour_code 

			IF status = notfound THEN 
				LET msgresp = kandoomsg("R",9530,"") 
				#9530 Purchase Orders Journal NOT found; Try Window.
				NEXT FIELD purch_jour_code 
			END IF 

			SELECT coa.* INTO modu_rec_coa.* FROM coa 
			WHERE coa.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND coa.acct_code = modu_rec_puparms.commit_acct_code 
			IF status = notfound THEN 
				LET msgresp = kandoomsg("R",9531,"") 
				#9531 Commitments Account NOT found; Try Window.
				NEXT FIELD commit_acct_code 
			END IF 

			SELECT coa.* INTO modu_rec_coa.* FROM coa 
			WHERE coa.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND coa.acct_code = modu_rec_puparms.goodsin_acct_code 

			IF status = notfound THEN 
				LET msgresp = kandoomsg("R",9532,"") 
				#9532 Goods On Order Account NOT found; Try Window.
				NEXT FIELD goodsin_acct_code 
			END IF 

			SELECT coa.* INTO modu_rec_coa.* FROM coa 
			WHERE coa.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND coa.acct_code = modu_rec_puparms.accrued_acct_code 

			IF status = notfound THEN 
				LET msgresp = kandoomsg("R",9533,"") 
				#9533 Accrued Expenses Account NOT found; Try Window.
				NEXT FIELD accrued_acct_code 
			END IF 

			SELECT coa.* INTO modu_rec_coa.* FROM coa 
			WHERE coa.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND coa.acct_code = modu_rec_puparms.clear_acct_code 

			IF status = notfound THEN 
				LET msgresp = kandoomsg("R",9534,"") 
				#9534 Expense Clearing Account NOT found; Try Window.
				NEXT FIELD clear_acct_code 
			END IF 

		ON KEY (control-w) 
			CALL kandoohelp("") 

	END INPUT 
	###########################

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	IF p_mode = "ADD" THEN 
		LET modu_rec_puparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET modu_rec_puparms.key_code = "1" 
		INSERT INTO puparms VALUES (modu_rec_puparms.*) 
	ELSE 

		GOTO bypass 

		LABEL recovery: 
		IF error_recover(l_err_message, status) = "N" THEN 
			RETURN false 
		END IF 

		LABEL bypass: 
		WHENEVER ERROR GOTO recovery 

		BEGIN WORK 

			LET l_err_message = "RZP - Locking Parameters Record" 
			DECLARE c_puparms CURSOR FOR 
			SELECT * FROM puparms 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND key_code = "1" 
			FOR UPDATE 

			OPEN c_puparms 
			FETCH c_puparms INTO l_rec_t_puparms.* 
			IF l_rec_s_puparms.next_po_num != l_rec_t_puparms.next_po_num 
			OR l_rec_s_puparms.next_ship_num != l_rec_t_puparms.next_ship_num 
			OR l_rec_s_puparms.next_receipt_num != l_rec_t_puparms.next_receipt_num THEN 
				ROLLBACK WORK 
				LET msgresp = kandoomsg("U",7050,"") 
				#7050 Parameter VALUES have been updated since changes.
				RETURN false 
			END IF 

			UPDATE puparms 
			SET * = modu_rec_puparms.* 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND key_code = "1" 
		COMMIT WORK 

		WHENEVER ERROR stop 
	END IF 

	RETURN true 
END FUNCTION 


#######################################################################
# FUNCTION display_params()
#
#
#######################################################################
FUNCTION display_params() 

	CLEAR FORM 
	SELECT puparms.* INTO modu_rec_puparms.* FROM puparms 
	WHERE puparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND puparms.key_code = "1" 
	IF status = notfound THEN 
		RETURN false 
	END IF 

	DISPLAY BY NAME modu_rec_puparms.next_po_num, 
	modu_rec_puparms.next_ship_num, 
	modu_rec_puparms.next_receipt_num, 
	modu_rec_puparms.usual_ware_code, 
	modu_rec_puparms.usual_conf_flag, 
	modu_rec_puparms.post_method_ind, 
	modu_rec_puparms.over_meth_flag, 
	modu_rec_puparms.commit_acct_code, 
	modu_rec_puparms.goodsin_acct_code, 
	modu_rec_puparms.accrued_acct_code, 
	modu_rec_puparms.clear_acct_code, 
	modu_rec_puparms.receipt_jour_code, 
	modu_rec_puparms.commit_jour_code, 
	modu_rec_puparms.purch_jour_code 

	SELECT journal.desc_text INTO modu_rec_journal.desc_text 
	FROM journal 
	WHERE journal.jour_code = modu_rec_puparms.receipt_jour_code 
	AND journal.cmpy_code = glob_rec_kandoouser.cmpy_code 
	DISPLAY modu_rec_journal.desc_text TO jour_desc1_text 

	SELECT journal.desc_text INTO modu_rec_journal.desc_text 
	FROM journal 
	WHERE journal.jour_code = modu_rec_puparms.commit_jour_code 
	AND journal.cmpy_code = glob_rec_kandoouser.cmpy_code 
	DISPLAY modu_rec_journal.desc_text TO jour_desc2_text 

	SELECT journal.desc_text INTO modu_rec_journal.desc_text 
	FROM journal 
	WHERE journal.jour_code = modu_rec_puparms.purch_jour_code 
	AND journal.cmpy_code = glob_rec_kandoouser.cmpy_code 
	DISPLAY modu_rec_journal.desc_text TO jour_desc3_text 

	SELECT coa.desc_text INTO modu_rec_coa.desc_text 
	FROM coa 
	WHERE coa.acct_code = modu_rec_puparms.commit_acct_code 
	AND coa.cmpy_code = glob_rec_kandoouser.cmpy_code 
	DISPLAY modu_rec_coa.desc_text TO coa_desc1_text 

	SELECT coa.desc_text INTO modu_rec_coa.desc_text 
	FROM coa 
	WHERE coa.acct_code = modu_rec_puparms.goodsin_acct_code 
	AND coa.cmpy_code = glob_rec_kandoouser.cmpy_code 
	DISPLAY modu_rec_coa.desc_text TO coa_desc2_text 

	SELECT coa.desc_text INTO modu_rec_coa.desc_text 
	FROM coa 
	WHERE coa.acct_code = modu_rec_puparms.accrued_acct_code 
	AND coa.cmpy_code = glob_rec_kandoouser.cmpy_code 
	DISPLAY modu_rec_coa.desc_text TO coa_desc3_text 

	SELECT coa.desc_text INTO modu_rec_coa.desc_text 
	FROM coa 
	WHERE coa.acct_code = modu_rec_puparms.clear_acct_code 
	AND coa.cmpy_code = glob_rec_kandoouser.cmpy_code 
	DISPLAY modu_rec_coa.desc_text TO coa_desc4_text 

	RETURN true 
END FUNCTION 
