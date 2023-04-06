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

	Source code beautified by beautify.pl on 2020-01-03 09:12:20	$Id: $
}

##- TODO: create I12_main.4gl
##- reuse form I626 instead of I150 for QBE and see what can be re-used


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
# \brief module I12 - Product Inquiry Program

#@huho USE chnnel IS legacy - NOT supported by any modern 4gl compiler
#<AF>
#--# USE channel
#</AF>

FUNCTION I12_whenever_sqlerror ()
    # this code instanciates the default sql errors handling for all the code lines below this function
    # it is a compiler preprocessor instruction. It is not necessary to execute that function
    WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
END FUNCTION


MAIN 
	#Initial UI Init
	CALL setModuleId("I12") 
	CALL ui_init(0) 
	CALL init_i_in() 


	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 

	OPEN WINDOW i150 with FORM "I150" 
	 CALL windecoration_i("I150") -- albo kd-758 
	CALL query() 
	CLOSE WINDOW i150 
END MAIN 


FUNCTION select_product() 
	DEFINE 
	pr_part_code LIKE product.part_code, 
	where_part CHAR(900), 
	query_text CHAR(990) 

	CLEAR FORM 
	LET msgresp=kandoomsg("I",1001,"") 
	#1001" Enter Selection Criteria - ESC TO Continue"
	CONSTRUCT BY NAME where_part ON part_code, 
	short_desc_text, 
	desc_text, 
	desc2_text, 
	prodgrp_code, 
	cat_code, 
	class_code, 
	alter_part_code, 
	super_part_code, 
	compn_part_code, 
	pur_uom_code, 
	stock_uom_code, 
	sell_uom_code, 
	pur_stk_con_qty, 
	stk_sel_con_qty, 
	status_ind, 
	status_date, 
	stock_turn_qty, 
	target_turn_qty 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","I12","construct-part_code-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	LET msgresp=kandoomsg("I",1002,"") 
	#1002" Searching database - please wait
	LET query_text = "SELECT part_code ", 
	"FROM product ", 
	"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND ",where_part clipped," ", 
	"ORDER BY part_code" 
	PREPARE s_product FROM query_text 
	DECLARE c_product SCROLL CURSOR FOR s_product 
	OPEN c_product 
	FETCH c_product INTO pr_part_code 
	IF status = notfound THEN 
		RETURN false 
	ELSE 
		CALL display_product(pr_part_code) 
		RETURN true 
	END IF 
END FUNCTION 


FUNCTION query() 
	DEFINE 
	pr_part_code LIKE product.part_code 

	MENU " Product" 
		BEFORE MENU 
			HIDE option "Next" 
			HIDE option "Previous" 
			HIDE option "First" 
			HIDE option "Last" 
			HIDE option "Detail" 
			CALL publish_toolbar("kandoo","I12","menu-Product-1") -- albo kd-505 
			#<AF>
			HIDE option "Enabler" 
			SHOW option "iEnabler" 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

			#</AF>
		COMMAND "Query" " Enter Selection Criteria FOR products " 
			IF select_product() THEN 
				FETCH FIRST c_product INTO pr_part_code 
				SHOW option "Next" 
				SHOW option "Previous" 
				SHOW option "First" 
				SHOW option "Last" 
				SHOW option "Detail" 

				#<AF>
				SHOW option "Enabler" 
				SHOW option "iEnabler" 
				#</AF>

			ELSE 
				LET msgresp = kandoomsg("I",9022,"") 
				HIDE option "Next" 
				HIDE option "Previous" 
				HIDE option "First" 
				HIDE option "Last" 
				HIDE option "Detail" 

				#<AF>
				HIDE option "Enabler" 
				SHOW option "iEnabler" 
				#</AF>

			END IF 
		COMMAND KEY ("N",f21) "Next" " DISPLAY next selected product" 
			FETCH NEXT c_product INTO pr_part_code 
			IF status = notfound THEN 
				LET msgresp=kandoomsg("I",9079,"") 
				#9079" "You have reached the END of the products selected"
			ELSE 
				CALL display_product(pr_part_code) 
			END IF 
		COMMAND KEY ("P",f19) "Previous" " DISPLAY previous selected product" 
			FETCH previous c_product INTO pr_part_code 
			IF status = notfound THEN 
				LET msgresp=kandoomsg("I",9080,"") 
				#9080 "You have reached the start of the products selected"
			ELSE 
				CALL display_product(pr_part_code) 
			END IF 
		COMMAND KEY ("D",f20) "Detail" " View product details" 
			CALL pinqwind(glob_rec_kandoouser.cmpy_code,pr_part_code,0) 
		COMMAND KEY ("F",f18) "First" " DISPLAY first product in the selected list" 
			FETCH FIRST c_product INTO pr_part_code 
			IF status = notfound THEN 
				LET msgresp=kandoomsg("I",9080,"") 
				#9080 "You have reached the start of the products selected"
			ELSE 
				CALL display_product(pr_part_code) 
			END IF 
		COMMAND KEY ("L",f22) "Last" " DISPLAY last product in the selected list" 
			FETCH LAST c_product INTO pr_part_code 
			IF status = notfound THEN 
				LET msgresp=kandoomsg("I",9079,"") 
				#9079" "You have reached the END of the products selected"
			ELSE 
				CALL display_product(pr_part_code) 
			END IF 

			#<AF>
		COMMAND "Enabler" "Export this product TO Enabler POS file" 
			CALL enabler_pos_export_product(pr_part_code) # pr_part_code LIKE product.part_code, 


		COMMAND "iEnabler" "Import Enabler log file" 
			CALL enabler_pos_import() 
			#</AF>

		COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus" 
			LET int_flag = false 
			LET quit_flag = false 
			EXIT MENU 
		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
	END MENU 
END FUNCTION 


FUNCTION display_product(pr_part_code) 
	DEFINE 
	pr_part_code LIKE product.part_code, 
	pr_product RECORD LIKE product.*, 
	pr_prodgrp RECORD LIKE prodgrp.*, 
	pr_category RECORD LIKE category.*, 
	pr_class RECORD LIKE class.*, 
	alter_text, compn_text, super_text LIKE product.desc_text 

	SELECT * 
	INTO pr_product.* 
	FROM product 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_part_code 
	DISPLAY BY NAME pr_product.part_code, 
	pr_product.short_desc_text, 
	pr_product.desc_text, 
	pr_product.desc2_text, 
	pr_product.prodgrp_code, 
	pr_product.cat_code, 
	pr_product.class_code, 
	pr_product.alter_part_code, 
	pr_product.super_part_code, 
	pr_product.compn_part_code, 
	pr_product.pur_uom_code, 
	pr_product.sell_uom_code, 
	pr_product.stock_uom_code, 
	pr_product.pur_stk_con_qty, 
	pr_product.stk_sel_con_qty, 
	pr_product.status_ind, 
	pr_product.status_date, 
	pr_product.target_turn_qty, 
	pr_product.stock_turn_qty 

	SELECT desc_text 
	INTO pr_prodgrp.desc_text 
	FROM prodgrp 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND prodgrp_code = pr_product.prodgrp_code 
	SELECT desc_text 
	INTO pr_category.desc_text 
	FROM category 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cat_code = pr_product.cat_code 
	IF status = notfound THEN 
		LET pr_category.desc_text = "**********" 
	END IF 
	SELECT desc_text 
	INTO pr_class.desc_text 
	FROM class 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND class_code = pr_product.class_code 
	IF status = notfound THEN 
		LET pr_class.desc_text = "**********" 
	END IF 
	SELECT desc_text 
	INTO alter_text 
	FROM product 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_product.alter_part_code 
	SELECT desc_text 
	INTO compn_text 
	FROM product 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_product.compn_part_code 
	SELECT desc_text 
	INTO super_text 
	FROM product 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_product.super_part_code 
	DISPLAY pr_prodgrp.desc_text, 
	pr_category.desc_text, 
	pr_class.desc_text, 
	alter_text, 
	compn_text, 
	super_text 
	TO prodgrp.desc_text, 
	category.desc_text, 
	class.desc_text, 
	alter_text, 
	compn_text, 
	super_text 

END FUNCTION 

#<AF>

####################################################
FUNCTION enabler_pos_export_product(pr_part_code) 
	####################################################
	DEFINE 
	pr_part_code LIKE product.part_code, 

	pr_product RECORD LIKE product.*, 
	pr_prodstatus RECORD LIKE prodstatus.*, 

	pr_prodgrp RECORD LIKE prodgrp.*, 
	pr_category RECORD LIKE category.*, 
	pr_class RECORD LIKE class.*, 
	alter_text, compn_text, super_text LIKE product.desc_text 

	SELECT * 
	INTO pr_product.* 
	FROM product 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_part_code 
	{
	 DISPLAY BY NAME pr_product.part_code,
	                 pr_product.short_desc_text,
	                 pr_product.desc_text,
	                 pr_product.desc2_text,
	                 pr_product.prodgrp_code,
	                 pr_product.cat_code,
	                 pr_product.class_code,
	                 pr_product.alter_part_code,
	                 pr_product.super_part_code,
	                 pr_product.compn_part_code,
	                 pr_product.pur_uom_code,
	                 pr_product.sell_uom_code,
	                 pr_product.stock_uom_code,
	                 pr_product.pur_stk_con_qty,
	                 pr_product.stk_sel_con_qty,
	                 pr_product.status_ind,
	                 pr_product.status_date,
	                 pr_product.target_turn_qty,
	                 pr_product.stock_turn_qty

	}
	SELECT desc_text 
	INTO pr_prodgrp.desc_text 
	FROM prodgrp 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND prodgrp_code = pr_product.prodgrp_code 
	SELECT desc_text 
	INTO pr_category.desc_text 
	FROM category 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cat_code = pr_product.cat_code 
	IF status = notfound THEN 
		LET pr_category.desc_text = "**********" 
	END IF 
	SELECT desc_text 
	INTO pr_class.desc_text 
	FROM class 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND class_code = pr_product.class_code 
	IF status = notfound THEN 
		LET pr_class.desc_text = "**********" 
	END IF 
	SELECT desc_text 
	INTO alter_text 
	FROM product 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_product.alter_part_code 
	SELECT desc_text 
	INTO compn_text 
	FROM product 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_product.compn_part_code 
	SELECT desc_text 
	INTO super_text 
	FROM product 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_product.super_part_code 
	{
	   DISPLAY pr_prodgrp.desc_text,
	           pr_category.desc_text,
	           pr_class.desc_text,
	           alter_text,
	           compn_text,
	           super_text
	        TO prodgrp.desc_text,
	           category.desc_text,
	           class.desc_text,
	           alter_text,
	           compn_text,
	           super_text

	}


	INITIALIZE pr_prodstatus.* TO NULL 

	LET pr_prodstatus.act_cost_amt = 888 
	LET pr_prodstatus.list_amt = 999 

	#    START REPORT enabler_POS_export_product_r TO "$KANDOODIR/isl-file.dat"
	START REPORT enabler_pos_export_product_r TO "isl-file.dat" 
	#    START REPORT enabler_POS_export_productr() TO pipe "sendmail"

	OUTPUT TO REPORT enabler_pos_export_product_r(pr_product.*,pr_prodstatus.*) 

	FINISH REPORT enabler_pos_export_product_r 

	#To SMS gateway
	#run "cat /tmp/sendmail.msg | sendmail -F$REPLY_TO $SMSMAIL"
	RUN "cat isl-file.dat | sendmail -Fafalout@falout.com afalout@ihug.co.nz" WITHOUT waiting 
	#afalout@falout.com  afalout@ihug.co.nz
	#cat /tmp/sendmail.msg | sendmail $SMSMAIL


	#CC TO my normal email
	#cat /tmp/sendmailCC.msg | sendmail -F$REPLY_TO $CC


END FUNCTION #enabler_pos_export_product 

#############################################################
REPORT enabler_pos_export_product_r(pr_product,pr_prodstatus) 
	#############################################################
	DEFINE 

	pr_product RECORD LIKE product.*, 
	pr_prodstatus RECORD LIKE prodstatus.* 

	#"PF","PD_PLU","PD_BARC","PD_DESC","PD_SDESC","PD_INACT","PD_UNIT","PD_DEPT","PD_CLASS","PD_TYPE","PD_SUPP1","PD_SUPPC1","PD_COST1","PD_TAXCODE","PD_SERIAL","PD_NONDIM","PD_PRICE","PD_STYLE","PD_PACKSZ

	{
	"PC","4321","","Quilt Cover - Sgle Navy","Navy Quilt Cover S","N","","1","1","","1","",9.85,"","N","N",29.95,"",1
	"PC","4322","20049614","Quilt Cover - Dbl Navy","Navy Quilt Cover D","N","","1","1","","1","",12.65,"","N","N",39.95,"",1
	"PC","4323","20043285","Quilt Cover - King Navy","Navy Quilt Cover K","N","","1","1","","1","",19.85,"","N","N",59.95,"",1
	"PC","4324","","Bath Towel 66x127cm - Mustard","Mustard B Towel","N","","2","2","","2","",3.75,"","N","N",8.99,"",1
	"PC","4325","","Bath Towel 66x127cm - Sea Blue","Sea Blue B Towel","N","","2","2","","2","",5.5,"","N","N",8.99,"",1
	"PC","4326","","Bath Towel 66x127cm - Indigo","Indigo B Towel","N","","2","2","","2","",3.75,"","N","N",8.99,"",1
	"PC","4327","","Bath Towel 66x127cm - Violet","Violet B Towel","N","","2","2","","2","",5,"","N","N",12,"",1
	"PC","4328","","Bath Towel 66x127cm - Plum","Plum B Towel","N","","2","2","","2","",3.75,"","N","N",8.99,"",1
	"PC","4329","20049393","Bath Towel 66x127cm White","White B Towel","N","","2","2","","2","",3.75,"","N","N",8.99,"",1
	"PC","4330","","Bath Towel 66x127cm - Cloud","Cloud B Towel","N","","2","2","","2","",5,"","N","N",8.99,"",1
	"PC","4331","10023457","Lunch Box - Silver","Silver L Box","N","","3","3","","3","",0.95,"","N","N",2.25,"",1
	"PC","4332","","Lunch Box - Orange","Orange L Box","N","","3","3","","3","",0.95,"","N","N",2.25,"",1
	"PC","4333","20049355","Cushion 43x43cm - Barley","Barley Cushion","N","","4","4","","4","",9.85,"","N","N",17.47,"",1
	"PC","GV","","Gift Voucher","Gift Voucher","N","","","","GV","","",0,"","N","Y",0,"",1
	"PC","4334","","Unbleached Calico 120cm","Unbl Calico 120cm","N","","5","","","","",0.5,"","N","N",2.18,"",1
	"PC","4335","","Unbleached Calico 240cm","Unbl Calico 240cm","N","","5","","","","",1.25,"","N","N",5.47,"",1
	"PC","4336","20048785","Bath Mat - Fed Green","Fed Green B Mat","N","","2","","","2","",6.85,"","N","N",19.95,"",1
	"PC","4337","","Bath Mat - Red","Red B Mat","N","","","","","","","5","","N","N",10,"",1
	"PC","4338","","Bath Mat - Blue","Blue B Mat","N","","5","","","","",0,"","N","N",48.13,"",1


	"PC",
	"4338",
	"",
	"Bath Mat - Blue",
	"Blue B Mat",
	"N",
	"",
	"5",
	"",
	"",
	"",
	"",
			0,
	"",
	"N",
	"N",
			48.13,
	"",
			1



	}

	######
	OUTPUT 
	######
	left margin 0 
	top margin 0 

	######
	FORMAT 
	######

	#################
		FIRST PAGE HEADER 
			#################


			#email headers:
			PRINT "FROM: ERP on Aptiva <afalout@falout.com>" 
			PRINT "Reply-TO: afalout@falout.com" 
			#PRINT "Subject: Max2Enabler"
			PRINT "Subject: isl-file.dat" 
			PRINT "RETURN-Path: <afalout@falout.com>" 
			#PRINT "To: Andrej Falout <afalout@ihug.co.nz>"
			PRINT "To: Andrej Falout <afalout@falout.com>" 

			#Enabler headers:
			PRINT 
			'"PF","PD_PLU","PD_BARC","PD_DESC","PD_SDESC","PD_INACT","PD_UNIT","PD_DEPT","PD_CLASS","PD_TYPE","PD_SUPP1","PD_SUPPC1","PD_COST1","PD_TAXCODE","PD_SERIAL","PD_NONDIM","PD_PRICE","PD_STYLE","PD_PACKSZ"' 

			###########
			#PAGE HEADER
			###########
			   {
				  LET pr_page_num = pageno
			      SELECT * INTO pr_company.* FROM company
			       WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
			      LET line1 = pr_company.cmpy_code, "  ", pr_company.name_text clipped
			      LET offset1 = (132 - length(line1))/2
			      PRINT COLUMN  1, today clipped,
			            COLUMN offset1, line1 clipped,
			            COLUMN (132 - 9), "Page: ", pageno using "####"
			      LET rpt_note = "Inventory Verification Report (Menu ISV)"
			      LET line2 = rpt_note clipped
			      LET offset2 = (132 - length(line2))/2
			      PRINT COLUMN 1, time,
			            COLUMN offset2, line2 clipped
			      PRINT COLUMN   1, "----------------------------------------",
			                        "----------------------------------------",
			                        "----------------------------------------",
			                        "------------"
			    }
			############
		ON EVERY ROW 
			############
			#PRINT COLUMN 1, line_info
			PRINT 

			'"', 
			'PC', #1: pf 
			'",', 

			'"', 
			pr_product.part_code clipped, #2: "PD_PLU", 
			'",', 

			'"', 
			pr_product.bar_code_text clipped, #3: "PD_BARC", 
			'",', 

			'"', 
			pr_product.desc_text clipped, #4: "PD_DESC", 
			" ", 
			pr_product.desc2_text clipped, 
			'",', 

			'"', 
			pr_product.short_desc_text clipped, #5: "PD_SDESC", 
			'",', 

			'"', 
			pr_product.status_ind clipped, #6: "PD_INACT", 
			'",', 

			'"', 
			pr_product.sell_uom_code clipped, #7: "PD_UNIT", 
			'",', 

			'"', 
			"", #8: "PD_DEPT", 
			'",', 

			#PC_DIV????

			'"', 
			pr_product.class_code clipped, #9: "PD_CLASS", 
			'",', 

			'"', 
			"", #10: "PD_TYPE", 
			'",', 

			'"', 
			pr_product.vend_code clipped, #11: "PD_SUPP1", 
			'",', 

			'"', 
			pr_product.oem_text clipped, #12: "PD_SUPPC1", 
			'",', 

			#PD_SUPP2, PD_SUPPC2, PD_SUPP3, PD_SUPPC3 ?????

			#'"',
			pr_prodstatus.act_cost_amt USING "<<<<<<<<<<<.<&", #13: "PD_COST1", dec(16,4)->n(11,2) 
			#'",',

			#PD_COST2, PD_COST3

			'"', 
			pr_prodstatus.sale_tax_code clipped, #14: "PD_TAXCODE", 
			'",', 

			#PD_TAXCOD2

			'"', 
			pr_product.serial_flag clipped, #15: "PD_SERIAL", 
			'",', 

			'"', 
			pr_prodstatus.stocked_flag clipped, #16: "PD_NONDIM", 
			'",', 

			#'"',
			pr_prodstatus.list_amt USING "<<<<<<<<<<<<<.<<<&", #17: "PD_PRICE", dec(16,4) -> n13,4) 
			#'",',

			'"', 
			"", #18: "PD_STYLE", 
			'",', 

			#'"',
			pr_product.pack_qty clipped #19: "PD_PACKSZ"' char8 -> n(11,2) 
			#'"'
			{
			1"PC",
			2"AA1004A",
			3"0564092959",
			4"GN Bible Child Rainbow H/C29.95                   RRP $27.95",
			5"1",
			6"1",
			7"EA",
			8"",
			9"1",
			10"",
			11"BFBS",
			12"GNB043PCD",
			13"                  ",
			14"",
			15"N",
			16"",
			17"                  ",
			18"",
			19"          0.00"
			}

			###########
		ON LAST ROW 
			###########

			SKIP 1 line 
			      {
				  PRINT COLUMN 20, "Total Problems: ", count(*) using "###"
			      skip 1 line
			      PRINT COLUMN 50," ***** END OF REPORT ISV ***** "
			      }

END REPORT #report enabler_pos_export_product_r 


##########################################
FUNCTION enabler_pos_import() 
	##########################################
	DEFINE 
	exportf_month, 
	exportf_day, 
	recordtype 
	CHAR (2), 
	exportf_time 
	CHAR (4), 
	exportf_ext 
	CHAR (3), 
	exportf_name 
	CHAR (60), 
	tmp_buffer, 
	tmp_buffer_resto 
	CHAR (500), 
	tmp_length, 
	success, 
	cnt2, 
	comma, 
	comma1pos, 
	a_load_tv_cnt, 
	a_load_sh_cnt, 
	a_load_sl_cnt, 
	a_load_tn_cnt, 
	a_load_ts_cnt, 
	a_load_es_cnt 

	SMALLINT, 
	counter 
	INTEGER, 
	a_load_tv ARRAY [200] OF #transaction void 
	CHAR(300), 

	a_load_sh ARRAY [200] OF #sale HEADER 
	CHAR(300), 
	a_load_sl ARRAY [200] OF #sale line 
	CHAR(300), 
	a_load_tn ARRAY [200] OF #tender RECORD (payment FOR sale) 
	CHAR(300), 
	a_load_ts ARRAY [200] OF #tender summary 
	CHAR(300), 
	a_load_es ARRAY [200] OF #end OF day summary 
	CHAR(300) 


	{
	00000001,"TV","99",01,"20010628","14:33:08","1","99990100000002",999
	00000002,"SH","99",01,"20010628","14:34:52","1","99990100000003","999901000001","","",888,0,0,0,0,111,0,1,999,0,0,0,0,"","T","","",0,"","","",111,"","","","","","","N"
	00000003,"SL",1,"99",01,"20010628","14:34:52","1","99990100000003","999901000001","",1,1,888,789.33,888,"AA1004A",0,0,"","",111,12.5,0,0,"T","T","T",999,999,0,"","","1","","","","","",""," ","","",""
	00000004,"TN","99990100000003","CASH",999,"","","99",01,"20010628","14:34:52","","","","99990120010628","1","","N"
	00000005,"TS","99",01,"20010628","14:42:31","","CASH",999,0,0,"99990120010628"
	00000006,"ES","99",01,"20010628","14:42:31",999,0,1,0,0,0,0,0,0,0,0,0,111,0,0,0,0,0,0,0,0,0,0,0,0,
	}



	#06281451.hos
	LET exportf_month = "06" 
	LET exportf_day = "28" 
	LET exportf_time = "1451" 
	LET exportf_ext = "hos" 
	LET exportf_name = "../",exportf_month,exportf_day,exportf_time,".",exportf_ext 

	#    error exportf_name sleep 1

	LET a_load_tv_cnt = 0 
	LET a_load_sh_cnt = 0 
	LET a_load_sl_cnt = 0 
	LET a_load_tn_cnt = 0 
	LET a_load_ts_cnt = 0 
	LET a_load_es_cnt = 0 



	MESSAGE "Loading...please wait..." 

	IF 
	openfile("h_import",exportf_name,"r") 
	THEN 

		LET counter = 1 

		###########################################
		#--# WHILE channel::read("h_import", tmp_buffer)
		#@huho changed TO fgl_channel FUNCTION
		--# WHILE fgl_channel_read("h_import", tmp_buffer)

		###########################################

		#on Windows, we need TO strip trailing ^M
		LET tmp_buffer = tmp_buffer clipped 
		LET tmp_length = length (tmp_buffer) 
		IF 
		tmp_length > 1 
		THEN 
			LET tmp_buffer = tmp_buffer [1,tmp_length-1] 
		ELSE 
			LET tmp_buffer = " " 
		END IF 

		#INSERT INTO TMP_IMPORT VALUES (0, tmp_buffer)

		MESSAGE tmp_buffer 
		#sleep 2

		INITIALIZE recordtype TO NULL 
		LET cnt2 = 1 
		LET comma = 0 

		########################
		WHILE recordtype IS NULL 
			########################

			IF tmp_buffer[cnt2] = "," THEN 
				LET comma = comma + 1 

				IF comma = 1 THEN 
					LET comma1pos=cnt2 
				END IF 

				IF comma = 2 THEN 
					LET recordtype = tmp_buffer[comma1pos+2,cnt2] 
					--# LET tmp_buffer_resto = tmp_buffer[cnt2+2,length (tmp_buffer)]
					#Works FOR <Suse>, but fails with Informix:
					#|
					#|      The symbol "length" does NOT represent a defined variable.
					#| See error number -4369.
				END IF 
			END IF 

			LET cnt2 = cnt2 + 1 

			#########
		END WHILE 
		#########

		#error RecordType sleep 2

		CASE recordtype 

			WHEN "TV" #transaction void 
				LET a_load_tv_cnt=a_load_tv_cnt+1 
				LET a_load_tv[a_load_tv_cnt] = tmp_buffer_resto clipped 

			WHEN "SH" #sale HEADER 
				LET a_load_sh_cnt=a_load_sh_cnt+1 
				LET a_load_sh[a_load_sh_cnt] = tmp_buffer_resto clipped 

			WHEN "SL" #sale line 
				LET a_load_sl_cnt=a_load_sl_cnt+1 
				LET a_load_sl[a_load_sl_cnt] = tmp_buffer_resto clipped 

			WHEN "TN" #tender RECORD (payment FOR sale) 
				LET a_load_tn_cnt=a_load_tn_cnt+1 
				LET a_load_tn[a_load_tn_cnt] = tmp_buffer_resto clipped 

			WHEN "TS" #tender summary 
				LET a_load_ts_cnt=a_load_ts_cnt+1 
				LET a_load_ts[a_load_ts_cnt] = tmp_buffer_resto clipped 

			WHEN "ES" #end OF day summary 
				LET a_load_es_cnt=a_load_es_cnt+1 
				LET a_load_es[a_load_es_cnt] = tmp_buffer_resto clipped 

			OTHERWISE 
				ERROR "Error: unknown RecordType, aborting..." 
				LET success = false 

		END CASE 


		LET counter = counter + 1 

		#if
		#	devidable_by(counter,100)
		#then
		#    LET g_msg = "Loading line ",counter ," please wait..."
		#	CALL msg(g_msg)
		#END IF

		#########
		--# END WHILE
		#########

		IF 
		NOT success 
		THEN 
			RETURN #success 
		ELSE 
			IF 
			counter > 1 
			THEN 
				LET success = true 
			ELSE 
				LET success = false 
				ERROR "Error: file was empty, aborting" 
			END IF 

			#@huho changed TO fgl_channel FUNCTION
			#--# CALL channel::close("h_import")
			--# CALL fgl_channel_close("h_import")

			IF NOT success THEN 
				RETURN #success 
			ELSE 

				#transaction void
				#IF a_load_TV_cnt > 0 THEN
				#	CALL insert_a_load_TV(a_load_TV,a_load_TV_cnt)
				#END IF

				#sale header
				IF a_load_sh_cnt > 0 THEN 
					#									--# CALL insert_a_load_SH(a_load_SH,a_load_SH_cnt)
					#Works with <Suse>, but fails with Informix:
					#|
					#|      The variable "a_load_sh" IS too complex a type TO be used in
					#| an expression.
					#| See error number -4340.
				END IF 

				#sale line
				IF a_load_sl_cnt > 0 THEN 
					#									--# CALL insert_a_load_SL(a_load_SL,a_load_SL_cnt)
				END IF 

				#tender RECORD (payment FOR sale)
				IF a_load_tn_cnt > 0 THEN 
					#									--#CALL insert_a_load_TN(a_load_TN,a_load_TN_cnt)
				END IF 

				#tender summary
				IF a_load_ts_cnt > 0 THEN 
					#									--# CALL insert_a_load_TS(a_load_TS,a_load_TS_cnt)
				END IF 

				#END of day summary
				#IF a_load_ES_cnt > 0 THEN
				#	CALL insert_a_load_ES(a_load_ES,a_load_ES_cnt)
				#END IF

			END IF 
		END IF 
	ELSE 
		LET success = false 
		ERROR "Open load file failed" 
		SLEEP 3 
		RETURN #success 
	END IF 


END FUNCTION #enabler_pos_inport() 

##########################################################################
#
#       D4GL - <Suse> specific functions
#
##########################################################################

#################### channel functions ###################################


####################################################
FUNCTION openfile(file_handle, file_name, open_mode) 
	####################################################
	{
	channel::open_file(handle, filename, oflag)
	--# CALL channel::set_delimiter("pipe",",")
	--# CALL channel::open_file("stream", "fglprofile", "r")

	handle 		CHAR(xx) Unique identifier FOR the specified filename
	filename 	CHAR(xx) Name of the file you want TO OPEN
	oflag 		CHAR(1)
					r Read mode (standard INPUT IF the filename IS empty)
					w Write mode (standard OUTPUT IF the filename IS empty)
					a Append mode: writes AT the END of the file (standard
						OUTPUT IF the filename IS empty)
					u Reads standard read/write on standard INPUT (filename
						must be empty)
	Returns 	None
	}

	DEFINE 
	file_handle, 
	file_name 
	CHAR(100), 
	open_mode 
	CHAR(1) 

	#@huho changed TO fgl_channel FUNCTION
	#--# CALL channel::set_delimiter(file_handle,"")    #no delimiter
	#--# CALL channel::open_file(file_handle, file_name, open_mode)
	--# CALL fgl_channel_set_delimiter(file_handle,"")    #no delimiter
	--# CALL fgl_channel_open_file(file_handle, file_name, open_mode)

	RETURN channelstatus(STATUS) 

END FUNCTION 


######################################################
FUNCTION openpipe(pipe_handle, exec_string, open_mode) 
	######################################################
	{
	channel::open_pipe(pipe_handle, command, oflag)
	CALL channel::open_pipe("pipe", "ls -l", "r")

	pipe_handle 	CHAR(xx) Unique identifier FOR the specified command
	command 		CHAR(xx) Name of the command you want TO execute
	oflag 			CHAR(1)
						r Read mode
						w Write mode
						a Append mode: writes AT the END of the file
						u Read AND write FROM command (only
							available FOR the UNIX system)
	Returns: 		None
	}

	DEFINE 
	pipe_handle, 
	exec_string 
	CHAR(100), 
	open_mode 
	CHAR(1) 

	#@huho changed TO fgl_channel FUNCTION
	#--# CALL channel::open_pipe(pipe_handle, exec_string, open_mode)
	--# CALL fgl_channel_open_pipe(pipe_handle, exec_string, open_mode)

	RETURN channelstatus(STATUS) 

END FUNCTION 




################################
FUNCTION readchanel(handle) 
	################################
	{
	channel::read(handle, buffer-list)

	handle 			CHAR(xx) Unique identifier FOR OPEN channel
	buffer-list 	List of variables, IF you use more than one
					variable, you must enclose the list in brackets
					([ ])
	Returns 		SMALLINT
					TRUE IF data has been read FROM handle;
					FALSE IF an error occurs


	To single var:
		DEFINE buffer CHAR(128)
		LET success = channel::read("pipe_handle", buffer)


	To array:
		DEFINE buffer ARRAY[1024] of CHAR(128)
		DEFINE I INTEGER
		LET I = 1
		WHILE channel::read("pipe_handle", buffer[I])
			LET I = I + 1
		END WHILE
	    IF I > 1 THEN LET success = TRUE ELSE LET success = FALSE END IF

	To record:
		DEFINE buffer RECORD
		Buff1 CHAR(128),
		Buff2 CHAR(128),
		Buff3 INTEGER
		END RECORD
		LET success = channel::read("handle", [buffer.Buff1, buffer.Buff2,
		buffer.Buff3])

	}

	DEFINE 
	handle 
	CHAR(100), 
	success 
	SMALLINT 

	RETURN success 

END FUNCTION 

###########################################
FUNCTION writechannel(handle, write_string) 
	###########################################
	{
	channel::write(handle, buffer_list)

	handle 			CHAR(xx) Unique identifier FOR OPEN channel
	buffer_list 	List of variables; IF you use more than one
					variable, you must enclose the list in brackets
					([ ])
	Returns 		None
	}

	DEFINE 
	handle, 
	write_string 
	CHAR (100) 

	#@huho changed TO fgl_channel FUNCTION
	#--# CALL channel::write(handle, write_string)
	--# CALL fgl_channel_write(handle, write_string)

	RETURN channelstatus(STATUS) 

END FUNCTION 

#############################
FUNCTION closechannel(handle) 
	#############################
	DEFINE 
	handle 
	CHAR (100) 
	#@huho changed TO fgl_channel FUNCTION
	#--# CALL channel::close(handle)
	--# CALL fgl_channel_close(handle)

	RETURN channelstatus(STATUS) 

END FUNCTION 

##################################
FUNCTION channelstatus(tmp_status) 
	##################################
	DEFINE 
	success, 
	tmp_status 
	SMALLINT 

	CASE tmp_status 
		WHEN (-2000) # cannot OPEN file. 
			LET success = false 
		WHEN (-2001) # unsupported MODE FOR 'open file'. 
			LET success = false 
		WHEN (-2002) # cannot OPEN pipe. 
			LET success = false 
		WHEN (-2003) # unsupported MODE FOR 'open pipe'. 
			LET success = false 
		WHEN (-2004) # cannot write TO unopened file OR pipe. 
			LET success = false 
		WHEN (-2005) # channel write error. 
			LET success = false 
		WHEN (-2006) # cannot read FROM unopened file OR pipe. 
			LET success = false 
		WHEN 0 # no ERROR 
			LET success = true 
		OTHERWISE # some other ERROR !! 
			LET success = false 
	END CASE 

	RETURN success 

END FUNCTION 


########################### END Channel ##################################


#</AF>



