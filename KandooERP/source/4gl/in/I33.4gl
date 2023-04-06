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


# allows the user TO scan serial items selecting on all columns as required.

GLOBALS 

	DEFINE 
	pr_serialinfo RECORD LIKE serialinfo.*, 
	where_part CHAR(500), 
	query_text CHAR(550), 
	answer, ans CHAR(1), 
	mrow, chosen, exist SMALLINT, 
	p1_overdue , p1_baddue LIKE customer.over1_amt, 
	pr_rec_kandoouser RECORD LIKE kandoouser.* 
END GLOBALS 

####################################################################
# MAIN
####################################################################
MAIN 
	DEFINE 
	pr_part_code LIKE prodstatus.part_code, 
	pr_ware_code LIKE prodstatus.ware_code, 
	pr_trans_num LIKE serialinfo.trans_num, 
	pr_trantype_ind LIKE serialinfo.trantype_ind 


	#Initial UI Init
	CALL setModuleId("I33") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 

	LET pr_part_code = NULL 
	LET pr_ware_code = NULL 
	LET pr_trans_num = NULL 
	LET pr_trantype_ind = NULL 

	IF num_args() = 0 THEN 
		CALL query() 
	ELSE 
		LET pr_part_code = arg_val(1) 
		IF arg_val(2) IS NOT NULL 
		AND arg_val(2) <> ' ' THEN 
			LET pr_ware_code = arg_val(2) 
		END IF 
		IF arg_val(3) IS NOT NULL 
		AND arg_val(3) <> ' ' THEN 
			LET pr_trans_num = arg_val(3) clipped 
		END IF 
		IF arg_val(4) IS NOT NULL 
		AND arg_val(4) <> ' ' THEN 
			LET pr_trantype_ind = arg_val(4) clipped 
		END IF 
		CALL select_serial(pr_part_code, pr_ware_code, pr_trans_num, 
		pr_trantype_ind) 
	END IF 
END MAIN 


FUNCTION select_serial(pr_part_code, pr_ware_code, pr_trans_num, 
	pr_trantype_ind) 
	DEFINE 
	pr_part_code LIKE prodstatus.part_code, 
	pr_ware_code LIKE prodstatus.ware_code, 
	pr_trans_num LIKE serialinfo.trans_num, 
	pr_trantype_ind LIKE serialinfo.trantype_ind, 
	pa_serialinfo array[500] OF RECORD 
		serial_code LIKE serialinfo.serial_code, 
		receipt_date LIKE serialinfo.receipt_date, 
		vend_code LIKE serialinfo.vend_code, 
		ware_code LIKE serialinfo.ware_code, 
		po_num LIKE serialinfo.po_num, 
		cust_code LIKE serialinfo.cust_code, 
		trans_num LIKE serialinfo.trans_num, 
		trantype_ind LIKE serialinfo.trantype_ind 
	END RECORD, 
	pr_product RECORD LIKE product.*, 
	pr_serial_code LIKE serialinfo.serial_code, 
	scrn INTEGER, 
	idx INTEGER 

	OPEN WINDOW wi126 with FORM "I126" 
	 CALL windecoration_i("I126") 


	CONSTRUCT BY NAME where_part ON serialinfo.part_code, 
	serialinfo.serial_code, 
	serialinfo.receipt_date, 
	serialinfo.vend_code, 
	serialinfo.ware_code, 
	serialinfo.po_num, 
	serialinfo.cust_code, 
	serialinfo.trans_num, 
	serialinfo.trantype_ind 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","I33","construct-serialinfo-1") -- albo kd-505 
			DISPLAY pr_part_code, 
			pr_ware_code, 
			pr_trans_num, 
			pr_trantype_ind 
			TO part_code, 
			ware_code, 
			trans_num, 
			trantype_ind 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END CONSTRUCT 
	LET query_text = 
	"SELECT serialinfo.* ", 
	"FROM serialinfo, product WHERE ", 
	where_part clipped, 
	" AND serialinfo.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND product.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND serialinfo.part_code = product.part_code ", 
	" ORDER BY 2, 3" 
	PREPARE s_serinfo FROM query_text 
	DECLARE c_serinfo SCROLL CURSOR FOR s_serinfo 
	LET idx = 0 
	OPTIONS SQL interrupt ON 
	WHENEVER ERROR CONTINUE 
	FOREACH c_serinfo INTO pr_serialinfo.* 
		LET idx = idx + 1 
		LET pa_serialinfo[idx].serial_code = pr_serialinfo.serial_code 
		LET pa_serialinfo[idx].receipt_date = pr_serialinfo.receipt_date 
		LET pa_serialinfo[idx].vend_code = pr_serialinfo.vend_code 
		LET pa_serialinfo[idx].ware_code = pr_serialinfo.ware_code 
		LET pa_serialinfo[idx].po_num = pr_serialinfo.po_num 
		LET pa_serialinfo[idx].cust_code = pr_serialinfo.cust_code 
		LET pa_serialinfo[idx].trans_num = pr_serialinfo.trans_num 
		LET pa_serialinfo[idx].trantype_ind = pr_serialinfo.trantype_ind 
		IF idx = 500 THEN 
			LET msgresp=kandoomsg("U",6100,idx) 
			EXIT FOREACH 
		END IF 
	END FOREACH 
	LET msgresp=kandoomsg("U",9113,idx) 
	#9113 "idx records selected"
	CALL set_count(idx) 
	SELECT * INTO pr_product.* FROM product 
	WHERE part_code = pr_part_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	DISPLAY BY NAME pr_product.part_code, 
	pr_product.desc_text, 
	pr_product.desc2_text 


	LET msgresp = kandoomsg("I",1300,"") 
	#1300 ENTER on line TO view detail.
	OPTIONS INSERT KEY f35, 
	DELETE KEY f36 
	INPUT ARRAY pa_serialinfo WITHOUT DEFAULTS FROM sr_serialinfo.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","I33","input-pa_serialinfo-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE FIELD serial_code 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			LET pr_serial_code = pa_serialinfo[idx].serial_code 
			DISPLAY pa_serialinfo[idx].* 
			TO sr_serialinfo[scrn].* 


		AFTER FIELD serial_code 
			LET pa_serialinfo[idx].serial_code = pr_serial_code 
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF arr_curr() = arr_count() THEN 
					LET msgresp=kandoomsg("I",9001,"") 
					#9001"There are no more rows in the direction you are go
					NEXT FIELD serial_code 
				END IF 
			END IF 

		BEFORE FIELD receipt_date 
			IF pa_serialinfo[idx].serial_code IS NOT NULL THEN 
				SELECT * INTO pr_serialinfo.* FROM serialinfo 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pr_part_code 
				AND serial_code = pa_serialinfo[idx].serial_code 
				OPEN WINDOW i127 with FORM "I127" 
				 CALL windecoration_i("I127") 
				WHILE true 
					CALL show_it() 
					CALL eventsuspend() 
					#LET msgresp = kandoomsg("I",7001,"")
					#7001 Press any key TO continue
					#               IF int_flag OR quit_flag THEN
					LET int_flag = false 
					LET quit_flag = false 
					EXIT WHILE 
					#               END IF
				END WHILE 
				CLOSE WINDOW i127 
			END IF 
			NEXT FIELD serial_code 

		AFTER ROW 
			DISPLAY pa_serialinfo[idx].* 
			TO sr_serialinfo[scrn].* 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	CLOSE WINDOW wi126 
END FUNCTION 


FUNCTION select_them() 
	LET msgresp = kandoomsg("U",1001,"") 
	#1001 Enter Selection Criteria;  OK TO Continue.

	DISPLAY '' TO pr_trantype_ind_desc 
	CONSTRUCT BY NAME where_part ON serialinfo.part_code, 
	product.desc_text, 
	product.desc2_text, 
	serialinfo.ware_code, 
	serial_code, 
	asset_num, 
	serialinfo.vend_code, 
	receipt_date, 
	receipt_num, 
	po_num, 
	cust_code, 
	ship_date, 
	trantype_ind, 
	trans_num, 
	credit_num, 
	ref_num 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","I33","construct-serialinfo-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 
	LET query_text = 
	"SELECT serialinfo.* ", 
	"FROM serialinfo, product WHERE ", 
	where_part clipped, 
	" AND serialinfo.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND product.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND serialinfo.part_code = product.part_code ", 
	" ORDER BY 2, 3" 

	LET exist = 0 
	IF ((int_flag != 0 
	OR quit_flag != 0) 
	AND exist = 0) THEN 
		EXIT program 
	END IF 

	PREPARE statement_1 FROM query_text 
	DECLARE serialinfo_set SCROLL CURSOR FOR statement_1 
	OPEN serialinfo_set 

	FETCH serialinfo_set INTO pr_serialinfo.* 
	IF status <> notfound THEN 
		LET exist = true 
	END IF 
END FUNCTION 


FUNCTION query() 
	OPEN WINDOW wi127 with FORM "I127" 
	 CALL windecoration_i("I127") 
	CLEAR FORM 
	LET exist = false 
	MENU " Serial Items" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","I33","menu-Serial-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE MENU 
			HIDE option "Next" 
			HIDE option "Previous" 
			HIDE option "First" 
			HIDE option "Last" 

		COMMAND "Query" " Search FOR serial items " 
			CALL select_them() 
			IF exist THEN 
				CALL show_it() 
				SHOW option "Next" 
				SHOW option "Previous" 
				SHOW option "First" 
				SHOW option "Last" 
				NEXT option "Next" 
			ELSE 
				LET msgresp = kandoomsg("U",1021,"") 
				#1021 No entries satisfied selection criteria.
				HIDE option "Next" 
				HIDE option "Previous" 
				HIDE option "First" 
				HIDE option "Last" 
			END IF 

		COMMAND KEY ("N",f21) "Next" " DISPLAY next selected serial item" 
			FETCH NEXT serialinfo_set INTO pr_serialinfo.* 
			IF status <> notfound THEN 
				CALL show_it() 
			ELSE 
				LET msgresp = kandoomsg("I",9079,"") 
				#9079 You have reached the END of the products selected"
				NEXT option "Previous" 
			END IF 

		COMMAND KEY ("P",f19) "Previous" " DISPLAY previous selected serial item" 
			FETCH previous serialinfo_set INTO pr_serialinfo.* 
			IF status <> notfound THEN 
				CALL show_it() 
			ELSE 
				LET msgresp = kandoomsg("I",9080,"") 
				#9080 You have reached the start of the products SELECT
				NEXT option "Next" 
			END IF 

		COMMAND KEY ("F",f18) "First" " DISPLAY first serial item in the selected list" 
			FETCH FIRST serialinfo_set INTO pr_serialinfo.* 
			IF status <> notfound THEN 
				CALL show_it() 
			ELSE 
				LET msgresp = kandoomsg("I",9080,"") 
				#9080 You have reached the start of the products SELECT
			END IF 

		COMMAND KEY ("L",f22) "Last" " DISPLAY last serial item in the selected list" 
			FETCH LAST serialinfo_set INTO pr_serialinfo.* 
			IF status <> notfound THEN 
				CALL show_it() 
			ELSE 
				LET msgresp = kandoomsg("I",9079,"") 
				#9079 You have reached the END of the products selected"
			END IF 

		COMMAND KEY(interrupt,"E") "Exit" " Exit FROM this program" 
			EXIT MENU 

		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
	END MENU 
	CLOSE WINDOW wi127 
END FUNCTION 


FUNCTION show_it() 
	DEFINE 
	pr_product RECORD LIKE product.*, 
	pr_trantype_ind_desc CHAR(18) 

	SELECT * INTO pr_product.* FROM product 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_serialinfo.part_code 

	CASE pr_serialinfo.trantype_ind 
		WHEN '0' LET pr_trantype_ind_desc = "Available " 
		WHEN '1' LET pr_trantype_ind_desc = "Reserved (Order) " 
		WHEN '2' LET pr_trantype_ind_desc = "Reserved (POS) " 
		WHEN '3' LET pr_trantype_ind_desc = "Reserved (CR) " 
		WHEN 'A' LET pr_trantype_ind_desc = "Deleted " 
		WHEN 'I' LET pr_trantype_ind_desc = "Issued " 
		WHEN 'S' LET pr_trantype_ind_desc = "Sold " 
		WHEN 'T' LET pr_trantype_ind_desc = "To Be Transferred " 
		WHEN 't' LET pr_trantype_ind_desc = "Transfer Confirmed" 
		WHEN 'K' LET pr_trantype_ind_desc = "Kitting Component " 
		OTHERWISE LET pr_trantype_ind_desc = " " 
	END CASE 

	DISPLAY BY NAME pr_serialinfo.part_code, 
	pr_product.desc_text, 
	pr_product.desc2_text, 
	pr_serialinfo.serial_code, 
	pr_serialinfo.asset_num, 
	pr_serialinfo.vend_code, 
	pr_serialinfo.po_num, 
	pr_serialinfo.receipt_date, 
	pr_serialinfo.receipt_num, 
	pr_serialinfo.cust_code, 
	pr_serialinfo.ship_date, 
	pr_serialinfo.ware_code, 
	pr_serialinfo.trantype_ind, 
	pr_trantype_ind_desc, 
	pr_serialinfo.credit_num, 
	pr_serialinfo.ref_num, 
	pr_serialinfo.trans_num 
END FUNCTION 
