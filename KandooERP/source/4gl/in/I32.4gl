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

	Source code beautified by beautify.pl on 2020-01-03 09:12:26	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 

#allows the user TO scan a product FOR a serial number AND THEN TO look AT further details AND change details.


GLOBALS 

	DEFINE 
	pr_product RECORD LIKE product.*, 
	pa_serialinfo array[320] OF RECORD 
		serial_code LIKE serialinfo.serial_code, 
		receipt_date LIKE serialinfo.receipt_date, 
		vend_code LIKE serialinfo.vend_code, 
		ware_code LIKE serialinfo.ware_code, 
		po_num LIKE serialinfo.po_num, 
		cust_code LIKE serialinfo.cust_code, 
		trans_num LIKE serialinfo.trans_num, 
		trantype_ind LIKE serialinfo.trantype_ind 
	END RECORD, 
	try_again CHAR(1), 
	err_message CHAR(40), 
	query_text, sel_text CHAR(200), 
	idx, id_flag, scrn, cnt, err_flag SMALLINT 

END GLOBALS 

####################################################################
# MAIN
####################################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("I32") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 

	OPEN WINDOW i126 with FORM "I126" 
	 CALL windecoration_i("I126") 

	WHILE select_serial() 
		CALL scan_serial() 
	END WHILE 
	CLOSE WINDOW i126 
END MAIN 


FUNCTION select_serial() 
	DEFINE 
	pr_serialinfo RECORD LIKE serialinfo.*, 
	pr_serial_flag LIKE product.serial_flag, 
	idx SMALLINT, 
	query_text CHAR(300), 
	where_text CHAR(200) 

	CLEAR FORM 
	LET msgresp=kandoomsg("I",1001,"") 
	#1001 Enter selection criteria - ESC TO Continue

	LET pr_serialinfo.serial_code = 0 

	INPUT BY NAME pr_product.part_code 
	WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","I32","input-pr_product-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) 
			CASE 
				WHEN infield(part_code) 
					LET pr_product.part_code = show_item(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME pr_product.part_code 
					NEXT FIELD part_code 
			END CASE 

		AFTER FIELD part_code 
			SELECT * INTO pr_product.* FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_product.part_code 

			IF status = notfound THEN 
				LET msgresp = kandoomsg("A",9119,"") 
				#9119 Product NOT found;  Try Window.
				NEXT FIELD part_code 
			ELSE 
				DISPLAY BY NAME pr_product.desc_text, 
				pr_product.desc2_text 

				IF pr_product.serial_flag <> 'Y' THEN 
					LET msgresp = kandoomsg("I",9288,"") 
					#9288 This IS NOT a Serial Item.
					NEXT FIELD part_code 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag != 0 
	OR quit_flag != 0 THEN 
		RETURN false 
	END IF 

	CONSTRUCT BY NAME where_text ON serial_code, 
	receipt_date, 
	vend_code , 
	ware_code, 
	po_num , 
	cust_code , 
	trans_num , 
	trantype_ind 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","I32","construct-serial_code-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		LET msgresp=kandoomsg("I",1002,"") 
		LET query_text = "SELECT * FROM serialinfo ", 
		"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		" AND part_code = '",pr_product.part_code, 
		##                      "' AND trantype_ind = '0' ",
		"' AND ",where_text clipped," ", 
		"ORDER BY serial_code" 
		PREPARE s_serial FROM query_text 
		DECLARE c_serial CURSOR FOR s_serial 
		RETURN true 
	END IF 
END FUNCTION 



FUNCTION scan_serial() 
	DEFINE 
	pr_serialinfo RECORD LIKE serialinfo.*, 
	pr_sto_serial_code LIKE serialinfo.serial_code 

	LET idx = 0 
	FOREACH c_serial INTO pr_serialinfo.* 
		LET idx = idx + 1 
		LET pa_serialinfo[idx].serial_code = pr_serialinfo.serial_code 
		LET pa_serialinfo[idx].receipt_date = pr_serialinfo.receipt_date 
		LET pa_serialinfo[idx].vend_code = pr_serialinfo.vend_code 
		LET pa_serialinfo[idx].ware_code = pr_serialinfo.ware_code 
		LET pa_serialinfo[idx].po_num = pr_serialinfo.po_num 
		LET pa_serialinfo[idx].cust_code = pr_serialinfo.cust_code 
		LET pa_serialinfo[idx].trans_num = pr_serialinfo.trans_num 
		LET pa_serialinfo[idx].trantype_ind = pr_serialinfo.trantype_ind 
		IF idx > 300 THEN 
			LET msgresp = kandoomsg("U",6100,idx) 
			#6100 Only idx records selected
			EXIT FOREACH 
		END IF 
	END FOREACH 
	CALL set_count(idx) 

	LET msgresp = kandoomsg("W",1033,'') 
	#1033 ENTER on line TO edit
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	INPUT ARRAY pa_serialinfo WITHOUT DEFAULTS FROM sr_serialinfo.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","I32","input-arr-pa_serialinfo-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 

		BEFORE FIELD serial_code 
			LET pr_sto_serial_code = pa_serialinfo[idx].serial_code 

		AFTER FIELD serial_code 
			LET pa_serialinfo[idx].serial_code = pr_sto_serial_code 
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF arr_curr() = arr_count() THEN 
					LET msgresp=kandoomsg("I",9001,"") 
					#9001"There are no more rows in the direction you are go
					NEXT FIELD serial_code 
				END IF 
			END IF 

		BEFORE FIELD receipt_date 
			LET pa_serialinfo[idx].serial_code 
			= get_detail(pa_serialinfo[idx].serial_code) 
			DISPLAY pa_serialinfo[idx].* TO sr_serialinfo[scrn].* 

			NEXT FIELD serial_code 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	LET int_flag = 0 
	LET quit_flag = 0 
END FUNCTION 


FUNCTION get_detail(pr_serial_code) 
	DEFINE 
	pr_serial_code LIKE serialinfo.serial_code, 
	pr_warehouse RECORD LIKE warehouse.*, 
	pr_serialinfo RECORD LIKE serialinfo.* , 
	pr_sto_asset_num LIKE serialinfo.asset_num, 
	pr_sto_serial_code LIKE serialinfo.serial_code, 
	pr_order_date LIKE purchhead.order_date 

	SELECT * INTO pr_serialinfo.* FROM serialinfo 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_product.part_code 
	AND serial_code = pr_serial_code 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("U",9910,'') 
		#9910 RECORD NOT found
		RETURN pr_serial_code 
	END IF 

	SELECT warehouse.* INTO pr_warehouse.* FROM warehouse 
	WHERE warehouse.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND warehouse.ware_code = pr_serialinfo.ware_code 

	OPEN WINDOW i127 with FORM "I127" 
	 CALL windecoration_i("I127") 

	LET msgresp = kandoomsg("I",1131,'') 
	#9910 Enter code
	DISPLAY pr_serialinfo.ware_code, 
	pr_warehouse.desc_text 
	TO ware_code, 
	warehouse.desc_text 


	DISPLAY BY NAME pr_serialinfo.serial_code, 
	pr_serialinfo.part_code, 
	pr_serialinfo.vend_code, 
	pr_serialinfo.po_num, 
	pr_serialinfo.cust_code, 
	pr_serialinfo.trans_num, 
	pr_serialinfo.ref_num, 
	pr_serialinfo.credit_num, 
	pr_serialinfo.trantype_ind, 
	pr_serialinfo.asset_num, 
	pr_product.desc_text, 
	pr_product.desc2_text 


	INPUT BY NAME pr_serialinfo.serial_code, 
	pr_serialinfo.asset_num, 
	pr_serialinfo.receipt_date, 
	pr_serialinfo.receipt_num 
	WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","I32","input-pr_serialinfo-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE FIELD serial_code 
			LET pr_sto_serial_code = pr_serialinfo.serial_code 

		AFTER FIELD serial_code 
			IF pr_sto_serial_code <> pr_serialinfo.serial_code THEN 
				SELECT unique 1 FROM serialinfo 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pr_serialinfo.part_code 
				AND serial_code = pr_serialinfo.serial_code 
				IF status <> notfound THEN 
					LET msgresp = kandoomsg("I",9272,'') 
					#9272 Serial number already exists.
					NEXT FIELD serial_code 
				END IF 
			END IF 


		BEFORE FIELD asset_num 
			LET pr_sto_asset_num = pr_serialinfo.asset_num 

		AFTER FIELD asset_num 
			IF pr_sto_asset_num <> pr_serialinfo.asset_num THEN 
				SELECT unique 1 FROM serialinfo 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND asset_num = pr_serialinfo.asset_num 
				IF status <> notfound THEN 
					LET msgresp = kandoomsg("I",9573,'') 
					#9272 Asset number already exists.
					NEXT FIELD asset_num 
				END IF 
			END IF 


		AFTER FIELD receipt_date 
			SELECT order_date 
			INTO pr_order_date 
			FROM purchhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND order_num = pr_serialinfo.po_num 
			IF status = notfound THEN 
			ELSE 
				IF pr_serialinfo.receipt_date < pr_order_date 
				OR pr_serialinfo.receipt_date > today THEN 
					LET msgresp = kandoomsg("U",9110,"") 
					NEXT FIELD receipt_date 
				END IF 
			END IF 

		AFTER INPUT 
			IF int_flag != 0 
			OR quit_flag != 0 THEN 
				LET quit_flag = 0 
				LET int_flag = 0 
			ELSE 
				GOTO bypass 
				LABEL recovery: 
				LET try_again = error_recover(err_message, status) 
				IF try_again != "Y" THEN 
					EXIT program 
				END IF 
				LABEL bypass: 
				WHENEVER ERROR GOTO recovery 
				BEGIN WORK 
					LET err_message = "I32 - Serial UPDATE" 
					UPDATE serialinfo 
					SET serial_code = pr_serialinfo.serial_code, 
					asset_num = pr_serialinfo.asset_num, 
					receipt_num = pr_serialinfo.receipt_num, 
					receipt_date = pr_serialinfo.receipt_date 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND serial_code = pr_serial_code 
					AND part_code = pr_serialinfo.part_code 
					IF status = notfound THEN 
						LET msgresp = kandoomsg("I",7080,'') 
						#7080 Another User altered serial information during
						ROLLBACK WORK 
						RETURN pr_serial_code 
					END IF 
				COMMIT WORK 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	CLOSE WINDOW i127 
	RETURN pr_serialinfo.serial_code 
END FUNCTION 
