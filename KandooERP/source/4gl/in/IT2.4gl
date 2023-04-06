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

	Source code beautified by beautify.pl on 2020-01-03 09:12:44	$Id: $
}




{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module TO run STOCKTAKE COUNT SHEETS
#
#   IT2: This program generates stock take REPORT on users query
#        with number of blank pages required AT the END of the REPORT.
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "I_IN_GLOBALS.4gl" 
GLOBALS 
	DEFINE 
	pr_company RECORD LIKE company.*, 
	pr_location RECORD LIKE location.*, 
	rpt_width LIKE rmsreps.report_width_num, 
	rpt_length LIKE rmsreps.page_length_num, 
	rpt_pageno LIKE rmsreps.page_num, 
	rpt_note LIKE rmsreps.report_text, 
	pr_cmpy_name LIKE company.name_text, 
	pr_lines_num INTEGER, 
	pr_pages_num INTEGER, 
	where_text CHAR(1300), 
	pr_order1, pr_order2 CHAR(15), 
	pr_output CHAR(60) 
END GLOBALS 

############################################################
# GLOBAL Scope Variables
############################################################
DEFINE modu_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]

####################################################################
# MAIN
####################################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("IT2") 
	CALL ui_init(0) 


	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 

	SELECT * INTO pr_company.* FROM company 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	SELECT name_text INTO pr_cmpy_name FROM company 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

	OPEN WINDOW I223 with FORM "I223" 
	 CALL windecoration_i("I223") -- albo kd-758 

	MENU " Stocktake Count Sheets" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","IT2","menu-Stocktake_Count-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Run" " SELECT criteria AND generate REPORT" 
			LET rpt_pageno = 0 
			LET pr_pages_num = 0 
			IF get_blankpage() THEN 
				CALL print_report() 
				NEXT option "Print Manager" 
			END IF 
			LET int_flag=false 
			LET quit_flag=false 

		COMMAND "Blanks" " Print out some blank pages" 
			LET rpt_pageno = 0 
			LET pr_pages_num=0 
			IF get_blankpage() THEN 
				CALL print_blanks() 
				NEXT option "Print Manager" 
			END IF 
			LET int_flag=false 
			LET quit_flag=false 

		ON ACTION "Print Manager"			#COMMAND KEY ("P",f11) "Print" " Print the REPORT"
			CALL run_prog("URS","","","","") 

		COMMAND KEY(interrupt,"E") "Exit" " Exit FROM this REPORT" 
			EXIT MENU 
	END MENU 
	CLOSE WINDOW i223 
END MAIN 


FUNCTION get_blankpage() 
	DEFINE 
	pr_userlocn RECORD LIKE userlocn.*, 
	pr_stktakedetl RECORD LIKE stktakedetl.*, 
	query_text CHAR(1500), 
	order_text CHAR(100) 

	CLEAR FORM 
	LET pr_pages_num = 0 
	LET pr_lines_num = 1 
	INPUT BY NAME pr_pages_num, 
	pr_lines_num WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IT2","input-pr_pages_num-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD pr_pages_num 
			IF pr_pages_num IS NULL THEN 
				LET pr_pages_num = 0 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag=false 
		LET quit_flag=false 
		RETURN false 
	END IF 
	LET msgresp=kandoomsg("I",1001,"") 
	#I1001 Enter selection criteria
	CONSTRUCT BY NAME where_text ON stktake.cycle_num, 
	stktake.desc_text, 
	stktakedetl.ware_code, 
	stktakedetl.maingrp_code, 
	stktakedetl.prodgrp_code, 
	stktakedetl.part_code, 
	stktakedetl.bin_text 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","IT2","construct-stktake-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 
	IF int_flag OR quit_flag THEN 
		LET int_flag=false 
		LET quit_flag=false 
		RETURN false 
	ELSE 
		LET msgresp=kandoomsg("I",1002,"") 
		#1002 Searching Database Please wait"
		SELECT * INTO pr_userlocn.* FROM userlocn 
		WHERE sign_on_code = glob_rec_kandoouser.sign_on_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		SELECT * INTO pr_location.* FROM location 
		WHERE locn_code = pr_userlocn.locn_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF status = notfound OR pr_location.stocktake_ind = 'B' THEN 
			LET order_text = "stktakedetl.bin_text,stktakedetl.part_code" 
		ELSE 
			LET order_text = "stktakedetl.part_code,stktakedetl.bin_text" 
		END IF 
		LET query_text= "SELECT stktakedetl.* ", 
		"FROM stktake,", 
		"stktakedetl ", 
		"WHERE stktakedetl.cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND stktake.cmpy_code='",glob_rec_kandoouser.cmpy_code, "' ", 
		"AND stktake.status_ind='1' ", 
		"AND stktake.cycle_num=stktakedetl.cycle_num ", 
		"AND ",where_text clipped," ", 
		"ORDER BY stktakedetl.cycle_num, stktakedetl.ware_code,", 
		order_text clipped 
		PREPARE s_stktakedetl FROM query_text 
		DECLARE c_stktakedetl CURSOR FOR s_stktakedetl 
		RETURN true 
	END IF 
END FUNCTION 


FUNCTION print_report() 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE 
	pr_stktakedetl RECORD LIKE stktakedetl.* 

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"IT2_rpt_list_stock_taket","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT IT2_rpt_list_stock_take TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = 0, 
	BOTTOM MARGIN = 0, 
	LEFT MARGIN = 0, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------
	LET modu_rpt_idx = l_rpt_idx
	
	DISPLAY " Reporting on Bin : " at 1,2 

	DISPLAY " Product: " at 2,2 

	FOREACH c_stktakedetl INTO pr_stktakedetl.* 
		IF pr_location.stocktake_ind = "P" THEN 
			LET pr_order1 = pr_stktakedetl.part_code 
			LET pr_order2 = pr_stktakedetl.bin_text 
		ELSE 
			LET pr_order1 = pr_stktakedetl.bin_text 
			LET pr_order2 = pr_stktakedetl.part_code 
		END IF 
		#---------------------------------------------------------
		OUTPUT TO REPORT IT2_rpt_list_stock_take(modu_rpt_idx,pr_stktakedetl.*,pr_order1,pr_order2) 
		#---------------------------------------------------------
		
		DISPLAY pr_stktakedetl.bin_text at 1,22 

		DISPLAY pr_stktakedetl.part_code at 2,22 

		IF int_flag OR quit_flag THEN 
			#8503 Continue Report(Y/N)
			IF kandoomsg("U",8503,"") = "N" THEN 
				#9501 Report Terminated
				LET msgresp=kandoomsg("U",9501,"") 
				EXIT FOREACH 
			END IF 
		END IF 
	END FOREACH 
	#------------------------------------------------------------
	FINISH REPORT IT2_rpt_list_stock_take
	CALL rpt_finish("IT2_rpt_list_stock_take")
	#------------------------------------------------------------

END FUNCTION 


FUNCTION print_blanks()
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE 
	pr_stktakedetl RECORD LIKE stktakedetl.*, 
	pr_count_cnt SMALLINT 

	INITIALIZE pr_stktakedetl.* TO NULL 

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"IT2_rpt_list_stock_taket","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT IT2_rpt_list_stock_take TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = 0, 
	BOTTOM MARGIN = 0, 
	LEFT MARGIN = 0, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------
	LET modu_rpt_idx = l_rpt_idx

	FOR pr_count_cnt=1 TO (26*pr_pages_num) 
		LET pr_stktakedetl.cycle_num = NULL 
		LET pr_stktakedetl.ware_code = NULL 
		LET pr_stktakedetl.bin_text = "_______________" 
		LET pr_stktakedetl.part_code = "_______________" 
		
		#---------------------------------------------------------
		OUTPUT TO REPORT IT2_rpt_list_stock_take(modu_rpt_idx,pr_stktakedetl.*,pr_order1,pr_order2) 
		#---------------------------------------------------------

	END FOR 
	#------------------------------------------------------------
	FINISH REPORT IT2_rpt_list_stock_take
	CALL rpt_finish("IT2_rpt_list_stock_take")
	#------------------------------------------------------------


END FUNCTION 


REPORT IT2_rpt_list_stock_take(p_rpt_idx,pr_stktakedetl,pr_order1,pr_order2) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE 
	pr_stktakedetl RECORD LIKE stktakedetl.*, 
	pr_desc_text LIKE product.desc_text, 
	pr_temp_text CHAR(30), 
	pr_order1, pr_order2 CHAR(15), 
	pa_line array[4] OF CHAR(132), 
	x SMALLINT 

	OUTPUT 
--	left margin 0 
	ORDER external BY pr_stktakedetl.cycle_num, 
	pr_stktakedetl.ware_code, 
	pr_order1, 
	pr_order2 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text 
			PRINT COLUMN 01, "FOR Cycle: ", 	pr_stktakedetl.cycle_num USING "<<<<<" clipped 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
 

		BEFORE GROUP OF pr_stktakedetl.cycle_num 
			SKIP TO top OF PAGE 
		BEFORE GROUP OF pr_stktakedetl.ware_code 
			SKIP TO top OF PAGE 
			IF pr_stktakedetl.ware_code IS NULL THEN 
				PRINT COLUMN 1,"Warehouse - " 
			ELSE 
				SELECT desc_text INTO pr_desc_text 
				FROM warehouse 
				WHERE ware_code = pr_stktakedetl.ware_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				PRINT COLUMN 1,"Warehouse - ",pr_stktakedetl.ware_code," ", 
				pr_desc_text; 
			END IF 
			SKIP 1 line 
		ON EVERY ROW 
			#IF pr_stktakedetl.part_code = "---------------" THEN
			IF pr_stktakedetl.cycle_num IS NULL THEN 
				LET pr_desc_text = "______________________________" 
			ELSE 
				SELECT desc_text INTO pr_desc_text 
				FROM product 
				WHERE part_code = pr_stktakedetl.part_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			END IF 
			IF pr_stktakedetl.bin_text IS NOT NULL THEN 
				LET pr_temp_text = pr_stktakedetl.bin_text clipped,"..............." 
				LET pr_stktakedetl.bin_text = pr_temp_text 
			END IF 
			IF pr_stktakedetl.part_code IS NOT NULL THEN 
				LET pr_temp_text = pr_stktakedetl.part_code clipped,"..............." 
				LET pr_stktakedetl.part_code = pr_temp_text 
			END IF 
			IF pr_desc_text IS NOT NULL THEN 
				LET pr_temp_text = pr_desc_text clipped,"........................." 
				LET pr_desc_text = pr_temp_text 
			END IF 
			PRINT COLUMN 03,pr_stktakedetl.bin_text clipped, 
			COLUMN 19,pr_stktakedetl.part_code clipped, 
			COLUMN 35,pr_desc_text, 
			COLUMN 66,"___________", 
			COLUMN 80,"_____________________________________________________" 
			FOR x = 1 TO pr_lines_num 
				SKIP 1 line 
			END FOR 
		ON LAST ROW 
			SKIP TO top OF PAGE 
			FOR x = 1 TO (26*pr_pages_num) 
				PRINT COLUMN 3,"_______________", 
				COLUMN 19,"_______________", 
				COLUMN 35,"_____________________________", 
				COLUMN 66,"______________", 
				COLUMN 83,"_________________________________________________" 
				LET x = x + 1 
			END FOR 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	

END REPORT 


