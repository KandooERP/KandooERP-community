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

	Source code beautified by beautify.pl on 2020-01-03 09:12:23	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 

{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief This module is the main module of I21 of the Stock Entry operation. It can split to different function depending on use of flexcode or not

--GLOBALS 
	DEFINE 
	pr_rec_kandoouser RECORD LIKE kandoouser.*, 
	pr_product RECORD LIKE product.*, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pm_prodstatus RECORD LIKE prodstatus.*, 
	pr_prodadjtype RECORD LIKE prodadjtype.*, 
	pr_class RECORD LIKE class.*, 
	created SMALLINT, 
	pr_prodstructure RECORD LIKE prodstructure.*, 
	flex_part,orig_part LIKE product.part_code, 
	pr_flex,pr_length,pr_start SMALLINT, 
	pr_dashes CHAR(15), 
	dashlength SMALLINT, 
	pr_prodledg RECORD LIKE prodledg.*, 
	pr_inparms RECORD LIKE inparms.*, 
	pr_warehouse RECORD LIKE warehouse.*, 
	seku, puku, stku LIKE product.stock_uom_code, 
	winds_text,filter_text CHAR(200), 
	err_continue CHAR(1), 
	err_message CHAR(40), 
	chkqty DECIMAL(15,2), 
	stck_tran_qty, sell_tran_qty LIKE prodledg.tran_qty, 
	stck_cost_amt, sell_cost_amt LIKE prodledg.cost_amt, 
	avail_qty, availf_qty, avail1_qty LIKE prodstatus.onhand_qty, 
	invalid_per SMALLINT, 
	pr_opparms RECORD LIKE opparms.* 
--END GLOBALS 

MAIN

	DEFER quit 
	DEFER interrupt 
	
	CALL I21_main ()

END MAIN 

FUNCTION I21_main ()
	#Initial UI Init
	CALL setModuleId("I21") 
	CALL ui_init(0) 
	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 

	# Check for INVENTORY parameters
	SELECT * INTO pr_inparms.* 
	FROM inparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 
	IF sqlca.sqlcode = notfound THEN 
		LET msgresp = kandoomsg("I",9002,"") 
		#9002 Inventory Parameters NOT Set Up - Menu IZP
		EXIT program 
	END IF 
	SELECT * INTO pr_opparms.* 
	FROM opparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_num = "1" 
	IF sqlca.sqlcode = notfound THEN 
		LET pr_opparms.cal_available_flag = "N" 
	END IF 

	# IN , FS means flexible product structure
	# Flexcode may be replaced later by use of NoSQL
	IF get_kandoooption_feature_state(TRAN_TYPE_INVOICE_IN,"FS") = "Y" THEN 
		OPEN WINDOW i119a with FORM "I119a" 
		 CALL windecoration_i("I119a") -- albo kd-758 
		WHILE product_reception_flexcode() 
			LET msgresp = kandoomsg("I",7064,pr_product.part_code) 
			#7064 "Product Successfully Receipted"
		END WHILE 
		CLOSE WINDOW i119a 
	ELSE 
		OPEN WINDOW i119 with FORM "I119" 
		 CALL windecoration_i("I119") -- albo kd-758 
		WHILE product_reception_noflexcode() 
			LET msgresp = kandoomsg("I",7064,pr_product.part_code) 
			#7064 "Product Successfully Receipted"
		END WHILE 
		CLOSE WINDOW i119 
	END IF 
END FUNCTION # I21_main () 

FUNCTION create_new_product(master_part,new_segment) 
	DEFINE 
	master_part,new_segment LIKE product.part_code, 
	pr_product RECORD LIKE product.*, 
	ps_product RECORD LIKE product.*, 
	pr_prodstructure RECORD LIKE prodstructure.*, 
	pr_prodflex RECORD LIKE prodflex.*, 
	pr_flex_code LIKE prodflex.flex_code, 
	pr_class RECORD LIKE class.*, 
	pr_last_seq_num, pr_skip, y_pos, x_pos,seg_len,i SMALLINT, 
	remain_segment LIKE product.part_code, 
	char_string CHAR(30) 

	BEGIN WORK
	SET ISOLATION TO REPEATABLE READ  # we want to lock all read product in shared mode temporarily
	SELECT * 
	INTO pr_product.* 
	FROM product 
	WHERE part_code = master_part 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	
	LET ps_product.* = pr_product.* 
	SELECT * 
	INTO pr_class.* 
	FROM class 
	WHERE class_code = pr_product.class_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	
	SELECT max(seq_num) 
	INTO pr_last_seq_num 
	FROM prodstructure 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND class_code = pr_product.class_code 
	
	IF pr_last_seq_num = 0 OR pr_last_seq_num IS NULL THEN 
		LET pr_last_seq_num = 1 
	END IF 
	#LET pr_dashes = NULL
	LET x_pos = 1 
	LET pr_skip = true 
	LET seg_len = length(new_segment) 
	LET ps_product.part_code = master_part 
	
	DECLARE prods_curs CURSOR FOR 
	SELECT * 
	FROM prodstructure 
	WHERE class_code = pr_class.class_code 
		AND seq_num > pr_class.price_level_ind 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	
	FOREACH prods_curs INTO pr_prodstructure.* 
		IF pr_prodstructure.type_ind = "F" THEN 
			LET ps_product.part_code = ps_product.part_code clipped, 
			pr_prodstructure.desc_text 
			IF pr_skip = true THEN 
				LET pr_skip = false 
			ELSE 
				LET x_pos = x_pos + 1 
			END IF 
		ELSE 
			LET y_pos = x_pos + pr_prodstructure.length - 1 
			IF seg_len >= x_pos THEN 
				LET remain_segment = new_segment[x_pos, seg_len] clipped 
			ELSE 
				LET remain_segment = "" 
			END IF 
			IF (pr_prodstructure.seq_num > pr_class.stock_level_ind 
			AND length(remain_segment) > 0 ) 
			OR pr_prodstructure.seq_num <= pr_class.stock_level_ind THEN 
				LET char_string = new_segment[x_pos, y_pos] 
				IF pr_prodstructure.seq_num = pr_last_seq_num THEN 
					IF NOT validate_string(char_string, 1, pr_prodstructure.length, false) THEN 
						RETURN false, " " 
					END IF 
				ELSE 
					IF NOT validate_string(char_string, pr_prodstructure.length, pr_prodstructure.length,false) 
					THEN 
						RETURN false, " " 
					END IF 
				END IF 
				IF pr_prodstructure.valid_flag = "Y" THEN 
					LET pr_flex_code = new_segment[x_pos, y_pos] 
					SELECT * 
					INTO pr_prodflex.* 
					FROM prodflex 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND class_code = pr_prodstructure.class_code 
						AND start_num = pr_prodstructure.start_num 
						AND flex_code = pr_flex_code 
					IF sqlca.sqlcode = notfound THEN 
						RETURN FALSE," " 
					END IF 
				END IF 
			END IF 
			LET ps_product.part_code = ps_product.part_code clipped, new_segment[x_pos, y_pos] 
			LET x_pos = x_pos + pr_prodstructure.length 
		END IF 
	END FOREACH 
	#LET ps_product.part_code = ps_product.part_code clipped,
	#pr_dashes clipped,
	#new_segment clipped
	LET ps_product.oem_text = ps_product.part_code 
	LET ps_product.short_desc_text = ps_product.part_code 
	
	
	--GOTO bypass1 
	--LABEL recovery1: 
	--LET err_continue = error_recover(err_message, status) 
	--IF err_continue != "Y" THEN 
	--	EXIT program 
	--END IF 
	-- LABEL bypass1: 
	WHENEVER SQLERROR CONTINUE  
	--BEGIN WORK 
	LET err_message = "" 
	INSERT INTO product VALUES (ps_product.*)
	IF sqlca.sqlcode < 0 THEN
		ERROR "I21 - Product Create failed,exiting program"
		ROLLBACK WORK
	ELSE 
		COMMIT WORK
		MESSAGE "New product created successfully"
		SET ISOLATION TO COMMITTED READ
	END IF
	LET created = 1 
	RETURN true, ps_product.part_code 
END FUNCTION 