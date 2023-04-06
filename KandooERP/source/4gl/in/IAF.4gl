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

	Source code beautified by beautify.pl on 2020-01-03 09:12:30	$Id: $
}


#GLOBALS "../common/glob_GLOBALS.4gl"

{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module IAF Inventory Stock Write-off Report
#    - This program IS intended TO be OUTPUT FOR a spreadsheet program

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 
GLOBALS "IA_GLOBALS.4gl" #note: this IS FOR all ia<n> programs 
GLOBALS "../common/glob_GLOBALS_report.4gl" 

#Module Scope Variables
DEFINE pr_report_file CHAR(80)

DEFINE glob_rec_rmsreps RECORD LIKE rmsreps.*
 

####################################################################
# MAIN
####################################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("IAF") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 

	CASE rpt_kandooreport_init(glob_rec_kandoouser.cmpy_code,getmoduleid(),"IAF") 
		WHEN "1" 
			OPEN WINDOW i689 with FORM "I689" 
			 CALL windecoration_i("I689") -- albo kd-758 
			MENU " Inventory Stock Write-off" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","IAF","menu-Inventory_Stock-1") -- albo kd-505 
				ON ACTION "WEB-HELP" -- albo kd-372 
					CALL onlinehelp(getmoduleid(),null) 
				COMMAND "Run" " SELECT Criteria AND PRINT REPORT" 
					IF IAF_rpt_query() THEN 
						IF glob_rec_rmsreps.exec_ind = "1" THEN 
							## Interactive
							CALL IAF_rpt_process() 
						ELSE 
							## Background
							CALL exec_report() 
						END IF 
						NEXT option "Print Manager" 
					END IF 

				ON ACTION "Print Manager" 
					#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
					NEXT option "Exit" 
				COMMAND KEY("E",interrupt)"Exit" " Exit TO menus" 
					EXIT MENU 
				COMMAND KEY (control-w) 
					CALL kandoohelp("") 
			END MENU 
			CLOSE WINDOW i689 
		WHEN "2" 
			CALL IAF_rpt_process() 
		WHEN "3" 
			OPEN WINDOW i689 with FORM "I689" 
			 CALL windecoration_i("I689") -- albo kd-758 
			CALL IAF_rpt_query() 
			CLOSE WINDOW i689 
	END CASE 
END MAIN 


FUNCTION IAF_rpt_query() 
	DEFINE 
	pr_file_name CHAR(20), 
	pr_path_name CHAR(50) 

	LET msgresp = kandoomsg("U",1020,"File & Path") 
	#1020 Enter File & Path Details; OK TO Continue.
	INPUT BY NAME pr_file_name, 
	pr_path_name WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IAF","input-pr_file_name-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD pr_file_name 
			IF pr_file_name IS NULL 
			OR pr_file_name = " " THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD pr_file_name 
			END IF 
		AFTER FIELD pr_path_name 
			IF pr_path_name IS NULL 
			OR pr_path_name = " " THEN 
				LET msgresp = kandoomsg("A",8015,"") 
				#8015 Warning: Current Directory will be defaulted
			END IF 
		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF pr_path_name IS NULL 
				OR pr_path_name = " " 
				OR length(pr_path_name) = 0 THEN 
					LET pr_path_name = "." 
				END IF 
				LET pr_report_file = pr_path_name clipped, 
				"/",pr_file_name clipped 
				IF NOT is_path_valid(pr_path_name) THEN 
					LET msgresp = kandoomsg("U",9107,"") 
					#9107 Unix file OR directory does NOT exist.
					NEXT FIELD pr_path_name 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	LET msgresp = kandoomsg("U", 1001, "") 
	#1001 Enter Selection Criteria; OK TO Continue
	CONSTRUCT BY NAME glob_rec_rmsreps.sel_text ON product.maingrp_code, 
	product.prodgrp_code, 
	product.vend_code, 
	product.part_code, 
	product.desc_text 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","IAF","construct-product-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	IF report1(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,0) THEN 
		RETURN true 
	ELSE 
		RETURN false 
	END IF 
END FUNCTION 


FUNCTION IAF_rpt_process() 
	DEFINE 
	pr_super_code LIKE product.super_part_code, 
	pr_for_cost_amt LIKE prodstatus.for_cost_amt, 
	pr_act_cost_amt LIKE prodstatus.act_cost_amt, 
	pr_last_receipt_date LIKE prodstatus.last_receipt_date, 
	pr_tran_qty LIKE prodledg.tran_qty, 
	pr_ware_code LIKE prodstatus.ware_code, 
	pr_cmpy_code LIKE product.cmpy_code, 
	pr_vend_code LIKE product.vend_code, 
	pr_maingrp_code LIKE product.maingrp_code, 
	pr_prodgrp_code LIKE product.prodgrp_code, 
	pr_part_code LIKE product.part_code, 
	pr_part_desc LIKE product.desc_text, 
	pr_oem_text LIKE product.oem_text, 
	pr_tariff_code LIKE product.tariff_code, 
	pr_for_curr_code LIKE prodstatus.for_curr_code, 
	query_text CHAR(1500), 
	pr_output CHAR(20) 

	#------------------------------------------------------------
	CALL report2()
	MESSAGE "Process Report - ", trim(glob_rec_rmsreps.report_text), ": ", trim(glob_rec_rmsreps.file_text)	
	START REPORT IAF_rpt_list TO glob_rec_rmsreps.file_text
	#------------------------------------------------------------

	LET query_text = "SELECT product.cmpy_code, product.vend_code,", 
	" product.maingrp_code, product.prodgrp_code,", 
	" product.part_code, product.desc_text,", 
	" product.oem_text, product.tariff_code,", 
	" prodstatus.ware_code, sum(prodledg.tran_qty),", 
	" prodstatus.for_cost_amt, prodstatus.act_cost_amt,", 
	" prodstatus.last_receipt_date, prodstatus.for_curr_code,", 
	" product.super_part_code", 
	" FROM product, prodledg, prodstatus", 
	" WHERE (prodstatus.ware_code = '3' ", 
	" OR prodstatus.ware_code = '16')", 
	" AND prodledg.source_text = 'Stck.Tak'", 
	" AND prodledg.trantype_ind = 'A'", 
	" AND prodstatus.cmpy_code = '",glob_rec_kandoouser.cmpy_code, "' ", 
	" AND prodledg.cmpy_code = product.cmpy_code", 
	" AND prodstatus.cmpy_code = product.cmpy_code", 
	" AND prodledg.part_code = product.part_code", 
	" AND prodstatus.part_code = product.part_code", 
	" AND prodledg.tran_date = '03/03/1999'", 
	" AND prodledg.ware_code = prodstatus.ware_code", 
	" AND ", glob_rec_rmsreps.sel_text clipped, 
	" group by 1,2,3,4,5,6,7,8,9,11,12,13,14,15", 
	" having sum(prodledg.tran_qty) < 0 ", 
	" ORDER BY product.vend_code,", 
	" product.maingrp_code,", 
	" product.prodgrp_code" 
	PREPARE p_product FROM query_text 
	DECLARE c_product CURSOR FOR p_product 

#	START REPORT IAF_rpt_list TO pr_report_file 

	FOREACH c_product INTO pr_cmpy_code, pr_vend_code, 
		pr_maingrp_code, pr_prodgrp_code, 
		pr_part_code, pr_part_desc, 
		pr_oem_text, pr_tariff_code, 
		pr_ware_code, pr_tran_qty, 
		pr_for_cost_amt, pr_act_cost_amt, 
		pr_last_receipt_date, pr_for_curr_code 

		OUTPUT TO REPORT IAF_rpt_list(pr_cmpy_code, pr_vend_code, pr_maingrp_code, 
		pr_prodgrp_code, pr_part_code, pr_part_desc, 
		pr_oem_text, pr_tariff_code, pr_ware_code, 
		pr_tran_qty, pr_for_cost_amt, pr_act_cost_amt, 
		pr_last_receipt_date, pr_for_curr_code, 
		pr_super_code) 
		IF NOT report3("Product",pr_part_code, 
		pr_part_desc) THEN 
			EXIT FOREACH 
		END IF 
	END FOREACH 
	
	IF glob_rec_rmsreps.exec_ind = "1" 
	OR glob_rec_rmsreps.exec_ind = "4" THEN 
		## Interactive
		CLOSE WINDOW w1_rpt 
	END IF 
END FUNCTION 


REPORT IAF_rpt_list(pr_cmpy_code, pr_vend_code, pr_maingrp_code, pr_prodgrp_code, 
	pr_part_code, pr_part_desc, pr_oem_text, pr_tariff_code, 
	pr_ware_code, pr_tran_qty, pr_for_cost_amt, pr_act_cost_amt, 
	pr_last_receipt_date, pr_for_curr_code, pr_super_code) 
	DEFINE 
	pr_prodquote_flag CHAR(1), 
	pr_super_code LIKE product.super_part_code, 
	pr_for_cost_amt LIKE prodstatus.for_cost_amt, 
	pr_act_cost_amt LIKE prodstatus.act_cost_amt, 
	pr_last_receipt_date LIKE prodstatus.last_receipt_date, 
	pr_tran_qty LIKE prodledg.tran_qty, 
	pr_ware_code LIKE prodstatus.ware_code, 
	pr_cmpy_code LIKE product.cmpy_code, 
	pr_vend_code LIKE product.vend_code, 
	pr_maingrp_code LIKE product.maingrp_code, 
	pr_prodgrp_code LIKE product.prodgrp_code, 
	pr_part_code LIKE product.part_code, 
	pr_part_desc LIKE product.desc_text, 
	pr_oem_text LIKE product.oem_text, 
	pr_tariff_code LIKE product.tariff_code, 
	pr_name_text LIKE vendor.name_text, 
	pr_currency_code LIKE vendor.currency_code, 
	pr_maingrp_desc LIKE maingrp.desc_text, 
	pr_prodgrp_desc LIKE prodgrp.desc_text, 
	pr_duty_per LIKE tariff.duty_per, 
	pr_cost_amt LIKE prodquote.cost_amt, 
	pr_for_curr_code LIKE prodstatus.for_curr_code, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pa_line array[4] OF CHAR(132) 

	OUTPUT 
	top margin 0 
	bottom margin 0 
	ORDER external BY pr_vend_code, 
	pr_maingrp_code, 
	pr_prodgrp_code 
	FORMAT 
		FIRST PAGE HEADER 
			LET glob_rec_rmsreps.page_num = pageno 
			PRINT COLUMN 01, "Vendor|Name|Vendor Curr.|Main Group|Main Grp Desc.|Prod Group|Prod Grp Desc.|Part|Product Desc.|Superseded|OEM|Tariff|Rate|Write Off Qty|Unit FOR. Cost|Currency|Unit Latest Cost|Receipt Date|Warehouse|Prod. Quote" 
		BEFORE GROUP OF pr_vend_code 
			LET pr_name_text = "" 
			LET pr_currency_code = "" 
			SELECT name_text, currency_code INTO pr_name_text, pr_currency_code 
			FROM vendor 
			WHERE cmpy_code = pr_cmpy_code 
			AND vend_code = pr_vend_code 
		BEFORE GROUP OF pr_maingrp_code 
			LET pr_maingrp_desc = "" 
			SELECT desc_text INTO pr_maingrp_desc 
			FROM maingrp 
			WHERE cmpy_code = pr_cmpy_code 
			AND maingrp_code = pr_maingrp_code 
		BEFORE GROUP OF pr_prodgrp_code 
			LET pr_prodgrp_desc = "" 
			SELECT desc_text INTO pr_prodgrp_desc 
			FROM prodgrp 
			WHERE cmpy_code = pr_cmpy_code 
			AND prodgrp_code = pr_prodgrp_code 
			
		ON EVERY ROW 
			LET pr_cost_amt = NULL 
			LET pr_duty_per = 0 
			SELECT duty_per INTO pr_duty_per FROM tariff 
			WHERE cmpy_code = pr_cmpy_code 
			AND tariff_code = pr_tariff_code 
			DECLARE pcurs CURSOR FOR 
			SELECT cost_amt INTO pr_cost_amt FROM prodquote 
			WHERE cmpy_code = pr_cmpy_code 
			AND oem_text = pr_oem_text 
			AND vend_code = pr_vend_code 
			OPEN pcurs 
			FETCH pcurs 
			CLOSE pcurs 
			PRINT COLUMN 01, pr_vend_code clipped,"|", 
			pr_name_text clipped,"|", 
			pr_currency_code clipped,"|", 
			pr_maingrp_code clipped,"|", 
			pr_maingrp_desc clipped,"|", 
			pr_prodgrp_code clipped,"|", 
			pr_prodgrp_desc clipped,"|", 
			pr_part_code clipped,"|", 
			pr_part_desc clipped,"|", 
			pr_super_code clipped,"|", 
			pr_oem_text clipped,"|", 
			pr_tariff_code clipped,"|", 
			pr_duty_per,"|", 
			pr_tran_qty *-1,"|", 
			pr_for_cost_amt,"|", 
			pr_for_curr_code,"|", 
			pr_act_cost_amt,"|", 
			pr_last_receipt_date,"|", 
			pr_ware_code,"|", 
			pr_cost_amt 
END REPORT