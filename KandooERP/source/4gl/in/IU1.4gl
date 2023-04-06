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

	Source code beautified by beautify.pl on 2020-01-03 09:12:46	$Id: $
}




{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module IU1 - Product Amendment Inquiry
############################################################
# GLOBAL Scope Variables
############################################################
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 


####################################################################
# MAIN
####################################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("IU1") 
	CALL ui_init(0) 


	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 

	OPEN WINDOW i257 with FORM "I257" 
	 CALL windecoration_i("I257") -- albo kd-758 

	WHILE select_prodstatlog() 
		CALL scan_prodstatlog() 
	END WHILE 
	CLOSE WINDOW i257 
END MAIN 

FUNCTION select_prodstatlog() 
	DEFINE 
	query_text CHAR(800), 
	where_text CHAR(600) 

	CLEAR FORM 
	LET msgresp = kandoomsg("I",1001,"") 
	#1001 " Enter Selection Criteria - ESC TO Continue"
	CONSTRUCT BY NAME where_text ON product.part_code, 
	prodstatlog.ware_code, 
	prodstatlog.change_date, 
	prodstatlog.list_price_amt, 
	prodstatlog.est_cost_amt, 
	product.desc_text, 
	product.desc2_text 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","IU1","construct-product-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		LET msgresp = kandoomsg("I",1002,"") 
		#1002 " Searching database - please wait"
		LET query_text = "SELECT prodstatlog.rowid,", 
		"prodstatlog.* ", 
		"FROM prodstatlog,", 
		"product ", 
		"WHERE prodstatlog.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND product.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND prodstatlog.part_code = product.part_code ", 
		"AND ", where_text clipped, " ", 
		"ORDER BY prodstatlog.part_code,", 
		"prodstatlog.ware_code,", 
		"prodstatlog.audit_date" 
		PREPARE s_prodstatlog FROM query_text 
		DECLARE c_prodstatlog CURSOR FOR s_prodstatlog 
		RETURN true 
	END IF 
END FUNCTION 


FUNCTION scan_prodstatlog() 
	DEFINE 
	pr_prodstatlog RECORD LIKE prodstatlog.*, 
	pr_product RECORD LIKE product.*, 
	pa_prodstatlog array[300] OF RECORD 
		part_code LIKE prodstatlog.part_code, 
		ware_code LIKE prodstatlog.ware_code, 
		change_date LIKE prodstatlog.change_date, 
		time_text CHAR(5), 
		list_price_amt LIKE prodstatlog.list_price_amt, 
		est_cost_amt LIKE prodstatlog.est_cost_amt 
	END RECORD, 
	pr_rowid INTEGER, 
	pa_rowid array[300] OF INTEGER, 
	idx SMALLINT, 
	pr_temp_text CHAR(20) 

	LET idx = 0 
	FOREACH c_prodstatlog INTO pr_rowid, 
		pr_prodstatlog.* 
		LET idx = idx + 1 
		LET pa_rowid[idx] = pr_rowid 
		LET pa_prodstatlog[idx].part_code = pr_prodstatlog.part_code 
		LET pa_prodstatlog[idx].ware_code = pr_prodstatlog.ware_code 
		LET pa_prodstatlog[idx].change_date = pr_prodstatlog.change_date 
		LET pr_temp_text = pr_prodstatlog.audit_date 
		LET pa_prodstatlog[idx].time_text=pr_temp_text[12,16] 
		LET pa_prodstatlog[idx].list_price_amt = pr_prodstatlog.list_price_amt 
		LET pa_prodstatlog[idx].est_cost_amt = pr_prodstatlog.est_cost_amt 
		IF idx = 300 THEN 
			LET msgresp = kandoomsg("U",6100,idx) 
			EXIT FOREACH 
		END IF 
	END FOREACH 
	LET msgresp = kandoomsg("U",9113,idx) 
	IF idx = 0 THEN 
		LET msgresp = kandoomsg("I",9152,"") 
		#9024" No entries satisfied selection criteria "
	END IF 
	CALL set_count(idx) 
	LET msgresp = kandoomsg("I",1007,"") 
	#1003 "F3/F4 - RETURN TO view
	INPUT ARRAY pa_prodstatlog WITHOUT DEFAULTS FROM sr_prodstatlog.* 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IU1","input-arr-pa_prodstatlog-1") -- albo kd-505 
		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 
		BEFORE ROW 
			LET idx = arr_curr() 
			SELECT desc_text, desc2_text 
			INTO pr_product.desc_text, pr_product.desc2_text 
			FROM product 
			WHERE part_code = pa_prodstatlog[idx].part_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status != notfound THEN 
				DISPLAY BY NAME pr_product.desc_text, 
				pr_product.desc2_text 

			END IF 
			--- modif ericv init # AFTER FIELD part_code
			--#IF fgl_lastkey() = fgl_keyval("accept")
			--#AND fgl_fglgui() THEN
			--#   NEXT FIELD ware_code
			--#END IF
		BEFORE FIELD ware_code 
			LET idx = arr_curr() 
			CALL show_prodstatlog(pa_rowid[idx]) 
			NEXT FIELD part_code 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	LET int_flag = false 
	LET quit_flag = false 
END FUNCTION 


FUNCTION show_prodstatlog(pr_rowid) 
	DEFINE 
	pr_rowid INTEGER, 
	pr_prodstatlog RECORD LIKE prodstatlog.*, 
	pr_warehouse RECORD LIKE warehouse.*, 
	pr_product RECORD LIKE product.*, 
	pr_rec_kandoouser RECORD LIKE kandoouser.*, 
	pr_temp_text CHAR(20) 

	SELECT * INTO pr_prodstatlog.* 
	FROM prodstatlog 
	WHERE rowid = pr_rowid 
	IF status = notfound THEN 
		ERROR "Logic error" 
		RETURN 
	END IF 
	SELECT * INTO pr_product.* 
	FROM product 
	WHERE part_code = pr_prodstatlog.part_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = notfound THEN 
		LET pr_product.desc_text = "**********" 
	END IF 
	SELECT desc_text INTO pr_warehouse.desc_text 
	FROM warehouse 
	WHERE ware_code = pr_prodstatlog.ware_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = notfound THEN 
		LET pr_warehouse.desc_text = "**********" 
	END IF 
	SELECT name_text INTO pr_rec_kandoouser.name_text 
	FROM kandoouser 
	WHERE sign_on_code = pr_prodstatlog.user_code 
	IF status = notfound THEN 
		LET pr_rec_kandoouser.name_text = "**********" 
	END IF 
	OPEN WINDOW i256 with FORM "I256" 
	 CALL windecoration_i("I256") -- albo kd-758 
	DISPLAY BY NAME pr_prodstatlog.part_code, 
	pr_product.desc_text, 
	pr_product.desc2_text, 
	pr_prodstatlog.ware_code, 
	pr_prodstatlog.user_code, 
	pr_prodstatlog.change_date, 
	pr_prodstatlog.list_price_amt, 
	pr_prodstatlog.price_1_amt, 
	pr_prodstatlog.price_2_amt, 
	pr_prodstatlog.price_3_amt, 
	pr_prodstatlog.price_4_amt, 
	pr_prodstatlog.price_5_amt, 
	pr_prodstatlog.price_6_amt, 
	pr_prodstatlog.price_7_amt, 
	pr_prodstatlog.price_8_amt, 
	pr_prodstatlog.price_9_amt, 
	pr_prodstatlog.est_cost_amt, 
	pr_prodstatlog.act_cost_amt, 
	pr_prodstatlog.for_cost_amt, 
	pr_rec_kandoouser.name_text 

	LET pr_temp_text = pr_prodstatlog.audit_date 
	LET pr_temp_text = pr_temp_text[12,19] 
	DISPLAY pr_warehouse.desc_text, 
	pr_product.sell_uom_code, 
	pr_product.sell_uom_code, 
	pr_temp_text 
	TO warehouse.desc_text, 
	sr_uom[1].sell_uom_code, 
	sr_uom[2].sell_uom_code, 
	time_text 

	CALL eventsuspend()#let msgresp = kandoomsg("U",1,"") 
	CLOSE WINDOW i256 
END FUNCTION 
