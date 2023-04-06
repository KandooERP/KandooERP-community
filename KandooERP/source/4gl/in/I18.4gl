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

	Source code beautified by beautify.pl on 2020-01-03 09:12:22	$Id: $
}

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 

#    - product bar codes TO be scanned OR entered
#    - product bar codes may also be updated


MAIN 
	#Initial UI Init
	CALL setModuleId("I18") 
	CALL ui_init(0) 


	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 

	OPEN WINDOW i648 with FORM "I648" 
	 CALL windecoration_i("I648") -- albo kd-758 
	CALL select_product() 
	CLOSE WINDOW i648 
END MAIN 


FUNCTION select_product() 
	DEFINE 
	pr_product RECORD LIKE product.*, 
	pr_bar_code_text LIKE product.bar_code_text, 
	winds_text LIKE product.part_code, 
	runner CHAR(200) 

	CLEAR FORM 
	LET msgresp=kandoomsg("I",1124,"") 
	#1124" Enter Bar Code - F8 Prod Info - F9 Purchase Info - F10 Upd Bar Code"
	INPUT BY NAME pr_product.bar_code_text, 
	pr_product.part_code WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","I18","input-pr_product-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) 
			LET winds_text = show_item(glob_rec_kandoouser.cmpy_code) 
			IF winds_text IS NOT NULL THEN 
				LET pr_product.part_code = winds_text 
				SELECT * INTO pr_product.* FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pr_product.part_code 
				CALL disp_product(pr_product.part_code) 
				NEXT FIELD bar_code_text 
			END IF 
		ON KEY (F10) 
			IF pr_product.part_code IS NOT NULL THEN 
				CALL update_barcode(pr_product.part_code) 
				RETURNING pr_product.bar_code_text 
				NEXT FIELD bar_code_text 
			END IF 
		ON KEY (F8) 
			IF pr_product.part_code IS NOT NULL THEN 
				CALL pinqwind(glob_rec_kandoouser.cmpy_code,pr_product.part_code,0) 
			END IF 
		ON KEY (F9) 
			CALL run_prog("R16","","","","") 
		AFTER FIELD bar_code_text 
			IF pr_product.bar_code_text IS NULL THEN 
				NEXT FIELD part_code 
			ELSE 
				LET pr_bar_code_text = get_barcode(pr_product.bar_code_text) 
				SELECT * INTO pr_product.* FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND bar_code_text = pr_bar_code_text 
				IF status = notfound THEN 
					LET msgresp=kandoomsg("I",9234,"") 
					#9234 " Bar Code NOT found"
					CLEAR FORM 
					LET pr_product.bar_code_text = NULL 
					LET pr_product.part_code = NULL 
					NEXT FIELD bar_code_text 
				ELSE 
					CALL disp_product(pr_product.part_code) 
					NEXT FIELD bar_code_text 
				END IF 
			END IF 
		BEFORE FIELD part_code 
			LET pr_product.part_code = NULL 
		AFTER FIELD part_code 
			IF fgl_lastkey() = fgl_keyval("up") 
			OR fgl_lastkey() = fgl_keyval("left") THEN 
				NEXT FIELD bar_code_text 
			END IF 
			IF pr_product.part_code IS NULL THEN 
				LET msgresp=kandoomsg("I",9013,"") 
				#9013 "Product code must be entered"
				NEXT FIELD part_code 
			ELSE 
				SELECT * INTO pr_product.* FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pr_product.part_code 
				IF status = notfound THEN 
					LET msgresp=kandoomsg("I",9010,"") 
					#9010 "Product code does noty exist - Try Window"
					NEXT FIELD part_code 
				ELSE 
					CALL disp_product(pr_product.part_code) 
					NEXT FIELD bar_code_text 
				END IF 
			END IF 
		ON KEY (F7) 
			IF pr_product.bar_code_text IS NOT NULL THEN 
				LET runner = "rsh \'echo $FGLSERVER | sed \'s/:.*//\'\'","winexec java Label ", 
				pr_product.part_code," ",pr_product.bar_code_text 
				RUN runner 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
END FUNCTION 


FUNCTION disp_product(pr_part_code) 
	DEFINE 
	pr_part_code LIKE product.part_code, 
	pr_product RECORD LIKE product.*, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pr_vendor RECORD LIKE vendor.*, 
	pr_inparms RECORD LIKE inparms.*, 
	pr_prodgrp_text LIKE prodgrp.desc_text, 
	pr_class_text LIKE class.desc_text, 
	pr_category_text LIKE category.desc_text 

	SELECT * INTO pr_inparms.* FROM inparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	SELECT * INTO pr_product.* FROM product 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_part_code 
	DISPLAY BY NAME pr_product.bar_code_text, 
	pr_product.part_code, 
	pr_product.desc_text, 
	pr_product.desc2_text, 
	pr_product.prodgrp_code, 
	pr_product.cat_code, 
	pr_product.class_code, 
	pr_product.vend_code, 
	pr_product.oem_text, 
	pr_product.status_ind, 
	pr_product.status_date, 
	pr_product.setup_date 

	SELECT list_amt INTO pr_prodstatus.list_amt FROM prodstatus 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_part_code 
	AND ware_code = pr_inparms.mast_ware_code 
	IF status = notfound THEN 
		LET pr_prodstatus.list_amt = 0 
	END IF 
	SELECT desc_text INTO pr_prodgrp_text FROM prodgrp 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND prodgrp_code = pr_product.prodgrp_code 
	IF status = notfound THEN 
		LET pr_prodgrp_text = "**********" 
	END IF 
	SELECT desc_text INTO pr_category_text FROM category 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cat_code = pr_product.cat_code 
	IF status = notfound THEN 
		LET pr_category_text = "**********" 
	END IF 
	SELECT desc_text INTO pr_class_text FROM class 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND class_code = pr_product.class_code 
	IF status = notfound THEN 
		LET pr_class_text = "**********" 
	END IF 
	IF pr_product.vend_code IS NOT NULL THEN 
		SELECT name_text INTO pr_vendor.name_text FROM vendor 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND vend_code = pr_product.vend_code 
		IF status = notfound THEN 
			LET pr_vendor.name_text = "**********" 
		END IF 
	END IF 
	DISPLAY BY NAME pr_prodstatus.list_amt, 
	pr_prodgrp_text, 
	pr_category_text, 
	pr_class_text, 
	pr_vendor.name_text 

END FUNCTION 


FUNCTION update_barcode(pr_part_code) 
	DEFINE 
	pr_part_code LIKE product.part_code, 
	pr_product RECORD LIKE product.* 

	OPEN WINDOW i649 with FORM "I649" 
	 CALL windecoration_i("I649") -- albo kd-758 
	LET msgresp=kandoomsg("I",1125,"") 
	#1125 " Enter Bar Code - ESC TO Continue"
	SELECT * INTO pr_product.* FROM product 
	WHERE part_code = pr_part_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	INPUT BY NAME pr_product.bar_code_text, 
	pr_product.part_code WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","I18","input-pr_product-2") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD bar_code_text 
			IF pr_product.bar_code_text IS NOT NULL THEN 
				LET pr_product.bar_code_text = get_barcode(pr_product.bar_code_text) 
				SELECT * FROM product 
				WHERE bar_code_text = pr_product.bar_code_text 
				AND part_code != pr_product.part_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = 0 THEN 
					LET msgresp=kandoomsg("I",9235,"") 
					#9235 "Bar Code already exists"
					NEXT FIELD bar_code_text 
				END IF 
			END IF 
		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF pr_product.bar_code_text IS NOT NULL THEN 
					SELECT * FROM product 
					WHERE bar_code_text = pr_product.bar_code_text 
					AND part_code != pr_product.part_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF status = 0 THEN 
						LET msgresp=kandoomsg("I",9235,"") 
						#9235 "Bar Code already exists"
						NEXT FIELD bar_code_text 
					END IF 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF NOT (int_flag OR quit_flag) THEN 
		UPDATE product 
		SET bar_code_text = pr_product.bar_code_text 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = pr_product.part_code 
	ELSE 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 
	CLOSE WINDOW i649 
	RETURN pr_product.bar_code_text 
END FUNCTION 


FUNCTION get_barcode(pr_bar_code) 
	DEFINE 
	pr_bar_code LIKE product.bar_code_text, 
	pr_length SMALLINT 

	IF pr_bar_code[1,1] = "#" THEN 
		LET pr_length = length(pr_bar_code) 
		LET pr_bar_code = pr_bar_code[2,pr_length] 
	END IF 
	RETURN pr_bar_code 
END FUNCTION 
