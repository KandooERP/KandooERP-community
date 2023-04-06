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

	Source code beautified by beautify.pl on 2020-01-03 09:12:48	$Id: $
}



{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module IZ7   Stock items reception (only non serial)
#
# Inventory setup program. Prompts FOR warehouse, date AND period AND
# starting product code. Prompts FOR weighted avg price AND unit price
# bypasses normal calculation of weighted avg cost.

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 

# define module scope variables
 
	DEFINE 
	pr_product RECORD LIKE product.*, 
--	pr_prodstatus RECORD LIKE prodstatus.*, 
--	pr_prodledg RECORD LIKE prodledg.*, 
	pr_inparms RECORD LIKE inparms.*
--	pr_warehouse RECORD LIKE warehouse.*, 
--	start_part_code LIKE product.part_code, 
--	cnt SMALLINT 
 

####################################################################
# MAIN
#
#
####################################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("IZ7") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 

	CALL main_receipt_product()

END MAIN


FUNCTION main_receipt_product()
DEFINE l_rec_prodstatus RECORD LIKE prodstatus.*
DEFINE l_rec_prodledg RECORD LIKE prodledg.*
DEFINE start_part_code LIKE product.part_code
DEFINE l_cnt SMALLINT

	SELECT * 
	INTO pr_inparms.* 
	FROM inparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 
	IF status = notfound THEN 
		ERROR "Inventory Parameters NOT Set Up - Refer Menu IZP" 
		CALL fgl_winmessage("Incorrect Warehouse Setup","Inventory Parameters NOT Set Up - Refer Menu IZP","error") 
		SLEEP 4 
		EXIT program 
	END IF 


	OPEN WINDOW i147 with FORM "I147" 
	 CALL windecoration_i("I147") -- albo kd-758 

	SELECT min(part_code) 
	INTO start_part_code 
	FROM product 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET l_rec_prodstatus.ware_code = NULL 
	LET l_rec_prodledg.tran_date = today 
	INPUT BY NAME l_rec_prodstatus.ware_code, 
	l_rec_prodledg.tran_date, 
	start_part_code WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IZ7","input-l_rec_prodstatus-1") -- albo kd-505 
		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 
		
		AFTER FIELD ware_code 
			SELECT count(*) 
			INTO l_cnt 
			FROM warehouse 
			WHERE warehouse.ware_code = l_rec_prodstatus.ware_code 
			IF l_cnt = 0 THEN 
				ERROR " Invalid Warehouse Code - Re-Try" 
				NEXT FIELD ware_code 
			END IF 
			--      ON KEY (control-w)
			--         CALL kandoohelp("")
	END INPUT 

	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, today) 
	RETURNING l_rec_prodledg.year_num, 
	l_rec_prodledg.period_num 

	OPEN WINDOW i148 with FORM "I148" 
	 CALL windecoration_i("I148") -- albo kd-758 

	MESSAGE "Processing...Please Wait" attribute(reverse, blink) 
	DECLARE crs_prodstatus CURSOR with HOLD FOR 
	SELECT prodstatus.* 
	FROM prodstatus 
	WHERE prodstatus.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND prodstatus.part_code >= start_part_code 
	AND prodstatus.ware_code = l_rec_prodstatus.ware_code 
	AND prodstatus.onhand_qty = 0 
	ORDER BY part_code 
	
	FOREACH crs_prodstatus INTO l_rec_prodstatus.* 
		SELECT product.* 
		INTO pr_product.* 
		FROM product 
		WHERE product.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND product.part_code = l_rec_prodstatus.part_code 
		DISPLAY l_rec_prodstatus.ware_code, 
		l_rec_prodstatus.part_code, 
		pr_product.desc_text 
		TO prodstatus.ware_code, 
		prodstatus.part_code, 
		product.desc_text 

		IF int_flag OR quit_flag THEN 
			ERROR 
			" Initial Load Program Aborted - Note Product Successfully Loaded" 
			SLEEP 4 
			EXIT FOREACH 
		END IF 
		CALL receipt_product(l_rec_prodstatus.*) 
	END FOREACH 

	CLOSE WINDOW i148 
	CLOSE WINDOW i147 
END FUNCTION 	# main_receipt_product 


####################################################################
# FUNCTION receipt_product()
#
#
####################################################################
FUNCTION receipt_product(l_rec_prodstatus) 
	DEFINE 
	err_continue CHAR(1), 
	err_message CHAR(40) 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.*
	DEFINE l_rec_prodledg RECORD LIKE prodledg.*

	INITIALIZE l_rec_prodledg.* TO NULL
	LET l_rec_prodledg.source_text = "Open Stk" 
	LET l_rec_prodledg.cost_amt = l_rec_prodstatus.act_cost_amt 
	
	INPUT BY NAME l_rec_prodstatus.wgted_cost_amt, 
	l_rec_prodledg.cost_amt, 
	l_rec_prodstatus.onhand_qty WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IZ7","input-l_rec_prodstatus-2") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

	END INPUT 
	IF int_flag OR quit_flag THEN 
		EXIT program 
	END IF 

	BEGIN WORK 
		LET l_rec_prodledg.tran_qty = l_rec_prodstatus.onhand_qty 
		IF l_rec_prodledg.cost_amt IS NULL THEN 
			LET l_rec_prodledg.cost_amt = 0 
		END IF 
		IF l_rec_prodstatus.wgted_cost_amt IS NULL THEN 
			LET l_rec_prodstatus.wgted_cost_amt = 0 
		END IF 
		IF l_rec_prodstatus.act_cost_amt IS NULL THEN 
			LET l_rec_prodstatus.act_cost_amt = 0 
		END IF 
		LET l_rec_prodstatus.act_cost_amt = l_rec_prodledg.cost_amt 
		LET err_message = "I21 - Prodstatus UPDATE" 
		LET l_rec_prodstatus.seq_num = l_rec_prodstatus.seq_num + 1 
		LET l_rec_prodstatus.last_receipt_date = l_rec_prodledg.tran_date 
		
		UPDATE prodstatus 
		SET * = l_rec_prodstatus.* 
		WHERE prodstatus.part_code = l_rec_prodstatus.part_code 
		AND prodstatus.ware_code = l_rec_prodstatus.ware_code 
		AND prodstatus.cmpy_code = glob_rec_kandoouser.cmpy_code 
		
		LET l_rec_prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_rec_prodledg.part_code = l_rec_prodstatus.part_code 
		LET l_rec_prodledg.ware_code = l_rec_prodstatus.ware_code 
		LET l_rec_prodledg.seq_num = l_rec_prodstatus.seq_num 
		LET l_rec_prodledg.trantype_ind = "O" 
		LET l_rec_prodledg.sales_amt = 0 
		IF pr_inparms.hist_flag = "Y" THEN 
			LET l_rec_prodledg.hist_flag = "N" 
		ELSE 
			LET l_rec_prodledg.hist_flag = "Y" 
		END IF 
		LET l_rec_prodledg.post_flag = "N" 
		LET l_rec_prodledg.bal_amt = l_rec_prodstatus.onhand_qty 
		LET l_rec_prodledg.entry_code = glob_rec_kandoouser.sign_on_code 
		LET l_rec_prodledg.entry_date = today 
		LET err_message = "I21 - prodstatus INSERT" 

		INSERT INTO prodledg VALUES (l_rec_prodledg.*) 

	COMMIT WORK 

	WHENEVER ERROR stop 

END FUNCTION 		# receipt_product
