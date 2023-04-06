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
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../eo/E_EO_GLOBALS.4gl"
GLOBALS "../eo/EU_GROUP_GLOBALS.4gl"  
GLOBALS "../eo/EU6_GLOBALS.4gl" 
###########################################################################
# MODULE Scope Variables
###########################################################################
DEFINE modu_rec_mth_statint RECORD LIKE statint.*
DEFINE modu_order_ind char(1) 	 
DEFINE modu_temp_text STRING 
DEFINE modu_year_num_minus_1 SMALLINT
###########################################################################
# FUNCTION EU6_main()
#
# EU6 Product Monthly Turnover Comparison
###########################################################################
FUNCTION EU6_main() 
	DEFER QUIT 
	DEFER INTERRUPT 

	CALL setModuleId("EU6") -- albo 
--	CALL ui_init(0) 	#Initial UI Init 
--	CALL authenticate(getmoduleid()) 
--	CALL init_e_eo() #init e/eo module

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	
			OPEN WINDOW e130 with FORM "E130" 
			 CALL windecoration_e("E130") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
			DISPLAY getmenuitemlabel(NULL) TO header_text
			  
			MENU " Product Turnover report" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","EU6","menu-Product-1") -- albo kd-502 
					CALL rpt_rmsreps_reset(NULL)					 
					CALL EU6_rpt_process(EU6_rpt_query())
					
				ON ACTION "WEB-HELP" -- albo kd-370 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
					
				ON ACTION "REPORT" #COMMAND "Run" " Enter selection criteria AND generate report" 
					CALL rpt_rmsreps_reset(NULL)					 
					CALL EU6_rpt_process(EU6_rpt_query())

				ON ACTION "PRINT MANAGER" 				#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
					
				ON ACTION "CANCEL" #COMMAND KEY("E",INTERRUPT)"Exit" " Exit TO menus" 
					EXIT MENU 

			END MENU 

			CLOSE WINDOW E130 
	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL EU6_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW E130 with FORM "E130" 
			 CALL windecoration_e("E130") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(EU6_rpt_query()) #save where clause in env 
			CLOSE WINDOW E130 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL EU6_rpt_process(get_url_sel_text())
	END CASE 
	
END FUNCTION 


###########################################################################
# FUNCTION EU6_rpt_query()
#
#
###########################################################################
FUNCTION EU6_rpt_query() 
	DEFINE l_where_text STRING 

	LET modu_rec_mth_statint.year_num = glob_rec_statparms.year_num 
	LET modu_rec_mth_statint.int_num = glob_rec_statparms.mth_num 
	LET modu_order_ind = "1" 
	
	MESSAGE kandoomsg2("E",1157,"") #1157 Enter year FOR REPORT run - ESC TO Continue

	INPUT 
		modu_rec_mth_statint.year_num, 
		modu_rec_mth_statint.int_text, 
		modu_order_ind WITHOUT DEFAULTS 
	FROM
		year_num, 
		int_text, 
		order_ind ATTRIBUTE(UNBUFFERED) 
	
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","EU6","input-year_num-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 
			
		ON ACTION "LOOKUP" infield(int_text)  
				LET modu_temp_text = "year_num = '",modu_rec_mth_statint.year_num,"' ", 
				"AND type_code = '",glob_rec_statparms.mth_type_code,"'" 
				LET modu_temp_text = show_interval(glob_rec_kandoouser.cmpy_code,modu_temp_text) 
				IF modu_temp_text IS NOT NULL THEN 
					LET modu_rec_mth_statint.int_num = modu_temp_text 
					NEXT FIELD int_text 
				END IF 

		ON ACTION "YEAR-1" --ON KEY (f9) 
			LET modu_rec_mth_statint.year_num = modu_rec_mth_statint.year_num - 1 
			NEXT FIELD year_num 

		ON ACTION "YEAR+1" --ON KEY (f10) 
			LET modu_rec_mth_statint.year_num = modu_rec_mth_statint.year_num + 1 
			NEXT FIELD year_num 

		BEFORE FIELD year_num 
			SELECT * INTO modu_rec_mth_statint.* FROM statint 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND year_num = modu_rec_mth_statint.year_num 
			AND type_code = glob_rec_statparms.mth_type_code 
			AND int_num = modu_rec_mth_statint.int_num 
			
			DISPLAY BY NAME 
				modu_rec_mth_statint.int_text, 
				modu_rec_mth_statint.start_date, 
				modu_rec_mth_statint.end_date 

		AFTER FIELD year_num 
			IF modu_rec_mth_statint.year_num IS NULL THEN 
				ERROR kandoomsg2("E",9210,"") 			#9210 Year number must be entered
				LET modu_rec_mth_statint.year_num = glob_rec_statparms.year_num 
				NEXT FIELD year_num 
			END IF 

		BEFORE FIELD int_text 
			SELECT int_text INTO modu_rec_mth_statint.int_text FROM statint 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND year_num = modu_rec_mth_statint.year_num 
			AND type_code = glob_rec_statparms.mth_type_code 
			AND int_num = modu_rec_mth_statint.int_num 

		AFTER FIELD int_text 
			IF modu_rec_mth_statint.int_text IS NULL THEN 
				ERROR kandoomsg2("E",9222,"") 				#9222 Interval must be entered"
				NEXT FIELD int_text 
			ELSE 
				DECLARE c_interval cursor FOR 
				SELECT * FROM statint 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND year_num = modu_rec_mth_statint.year_num 
				AND type_code = glob_rec_statparms.mth_type_code 
				AND int_text = modu_rec_mth_statint.int_text 
				OPEN c_interval 
				FETCH c_interval INTO modu_rec_mth_statint.* 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("E",9223,"") 					#9223 Interval does NOT exist - Try Window"
					LET modu_rec_mth_statint.int_num = glob_rec_statparms.mth_num 
					NEXT FIELD int_text 
				END IF 
			END IF 
			
			DISPLAY BY NAME 
				modu_rec_mth_statint.start_date, 
				modu_rec_mth_statint.end_date 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN FALSE 
	ELSE 
		MESSAGE kandoomsg2("E",1001,"") #1001 Enter Selection Criteria - ESC TO Continue

		CONSTRUCT BY NAME l_where_text ON 
			part_code, 
			prodgrp_code, 
			maingrp_code 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","EU6","construct-part_code-1") -- albo kd-502 

			ON ACTION "WEB-HELP" -- albo kd-370 
				CALL onlinehelp(getmoduleid(),null) 

			BEFORE FIELD part_code 
				IF modu_order_ind > 1 THEN 
					NEXT FIELD prodgrp_code 
				END IF 

			BEFORE FIELD prodgrp_code 
				IF modu_order_ind > 2 THEN 
					NEXT FIELD maingrp_code 
				END IF 
		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			RETURN FALSE 
		END IF 
	END IF 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN NULL
	ELSE
	
 
		LET glob_rec_rpt_selector.ref1_code = modu_rec_mth_statint.year_num 
		LET glob_rec_rpt_selector.ref2_code = modu_rec_mth_statint.type_code 
		LET glob_rec_rpt_selector.ref4_code = modu_rec_mth_statint.int_num 
		--LET modu_rec_mth_statint.year_num = modu_rec_mth_statint.year_num - 1 
		LET glob_rec_rpt_selector.ref3_code = modu_year_num_minus_1
		LET glob_rec_rpt_selector.ref1_ind = modu_order_ind 
		RETURN l_where_text
	END IF 
END FUNCTION 


###########################################################################
# FUNCTION EU6_rpt_process()
#
#
###########################################################################
FUNCTION EU6_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  #report array index
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_mth_statprod RECORD LIKE statprod.* 
	DEFINE l_rec_pmth_statprod RECORD LIKE statprod.* 
	DEFINE l_rec_yr_statprod RECORD 
		net_amt LIKE statprod.net_amt 
	END RECORD 
	DEFINE l_rec_prev_statprod RECORD 
		net_amt LIKE statprod.net_amt 
	END RECORD 


	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"EU6_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT EU6_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------
	#get additional rms_reps values for query
	LET modu_order_ind = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("EU6_rpt_list")].ref3_ind

	LET modu_rec_mth_statint.year_num =  glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("EU6_rpt_list")].ref1_num 
	LET modu_rec_mth_statint.type_code = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("EU6_rpt_list")].ref1_code
	LET modu_rec_mth_statint.start_date = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("EU6_rpt_list")].ref1_date			
	LET modu_rec_mth_statint.dist_flag = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("EU6_rpt_list")].ref1_ind	
		
	LET modu_rec_mth_statint.int_num = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("EU6_rpt_list")].ref2_num			
	LET modu_rec_mth_statint.end_date = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("EU6_rpt_list")].ref2_date
	LET modu_rec_mth_statint.int_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("EU6_rpt_list")].ref2_code
	LET modu_rec_mth_statint.updreq_flag = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("EU6_rpt_list")].ref2_ind


	LET modu_rec_mth_statint.year_num  = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("EU6_rpt_list")].ref1_code
	LET modu_rec_mth_statint.type_code = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("EU6_rpt_list")].ref2_code
	LET modu_rec_mth_statint.int_num = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("EU6_rpt_list")].ref4_code

	LET modu_year_num_minus_1 = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("EU6_rpt_list")].ref3_code
	LET modu_order_ind = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("EU6_rpt_list")].ref1_ind

		
	#------------------------------------------------------------	


	#
	# Current Period Sales calculation
	#
	LET l_query_text = "SELECT * FROM statprod ", 
	"WHERE type_code = ? ", 
	"AND year_num = ? ", 
	"AND int_num = ? ", 
	"AND part_code IS NOT NULL ", 
	"AND maingrp_code = ? ", 
	"AND prodgrp_code = ? ", 
	"AND part_code = ? " 
	PREPARE s_statprod FROM l_query_text 
	DECLARE c_statprod cursor FOR s_statprod 
	#
	# YTD calculation
	#
	LET l_query_text = "SELECT sum(net_amt) FROM statprod ", 
	"WHERE int_num <= ? ", 
	"AND year_num = ? ", 
	"AND type_code = ? ", 
	"AND part_code IS NOT NULL ", 
	"AND maingrp_code = ? ", 
	"AND prodgrp_code = ? ", 
	"AND part_code = ? " 
	PREPARE s1_statprod FROM l_query_text 
	DECLARE c1_statprod cursor FOR s1_statprod 
	LET l_query_text = "SELECT * FROM product ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND ",p_where_text clipped," "

	CASE modu_order_ind
		WHEN '1' 
			LET l_query_text = l_query_text clipped, " ORDER BY part_code" 
		WHEN '2' 
			LET l_query_text = l_query_text clipped, " ORDER BY prodgrp_code,part_code" 
		WHEN '3' 
			LET l_query_text = l_query_text clipped, 
			" ORDER BY maingrp_code,prodgrp_code,part_code" 
	END CASE 
	
	PREPARE s_product FROM l_query_text 
	DECLARE c_product cursor FOR s_product
	 
	FOREACH c_product INTO l_rec_product.* 

		OPEN c_statprod USING 
		modu_rec_mth_statint.type_code, 
		modu_rec_mth_statint.year_num, 
		modu_rec_mth_statint.int_num, 
		l_rec_product.maingrp_code, 
		l_rec_product.prodgrp_code, 
		l_rec_product.part_code 
		FETCH c_statprod INTO l_rec_mth_statprod.* 
		IF status = NOTFOUND THEN 
			LET l_rec_mth_statprod.net_amt = 0 
		END IF 
		CLOSE c_statprod 
		
		OPEN c_statprod USING 
		modu_rec_mth_statint.type_code, 
		modu_year_num_minus_1, 
		modu_rec_mth_statint.int_num, 
		l_rec_product.maingrp_code, 
		l_rec_product.prodgrp_code, 
		l_rec_product.part_code 
		FETCH c_statprod INTO l_rec_pmth_statprod.* 
		IF status = NOTFOUND THEN 
			LET l_rec_pmth_statprod.net_amt = 0 
		END IF 
		CLOSE c_statprod 
		
		OPEN c1_statprod USING 
		modu_rec_mth_statint.int_num, 
		modu_rec_mth_statint.year_num, 
		modu_rec_mth_statint.type_code, 
		l_rec_product.maingrp_code, 
		l_rec_product.prodgrp_code, 
		l_rec_product.part_code 
		FETCH c1_statprod INTO l_rec_yr_statprod.* 
		IF l_rec_yr_statprod.net_amt IS NULL THEN 
			LET l_rec_yr_statprod.net_amt = 0 
		END IF 
		CLOSE c1_statprod 
		
		#
		# PTD calculation
		#
		OPEN c1_statprod USING 
		modu_rec_mth_statint.int_num, 
		modu_year_num_minus_1, 
		modu_rec_mth_statint.type_code, 
		l_rec_product.maingrp_code, 
		l_rec_product.prodgrp_code, 
		l_rec_product.part_code 
		FETCH c1_statprod INTO l_rec_prev_statprod.* 
		IF l_rec_prev_statprod.net_amt IS NULL THEN 
			LET l_rec_prev_statprod.net_amt = 0 
		END IF 
		CLOSE c1_statprod 

		#---------------------------------------------------------
		OUTPUT TO REPORT EU6_rpt_list(l_rpt_idx,
		l_rec_product.*, 
		l_rec_mth_statprod.*, 
		l_rec_pmth_statprod.*, 
		l_rec_yr_statprod.*, 
		l_rec_prev_statprod.*)  
		#---------------------------------------------------------	

		CASE modu_order_ind
			WHEN '1' 
				IF NOT rpt_int_flag_handler2("Product", l_rec_product.part_code,NULL,l_rpt_idx) THEN 
					EXIT FOREACH 
				END IF 
			WHEN '2' 
				IF NOT rpt_int_flag_handler2("Product group", l_rec_product.prodgrp_code,NULL,l_rpt_idx) THEN 
					EXIT FOREACH 
				END IF 
			WHEN '3' 
				IF NOT rpt_int_flag_handler2("Main group", l_rec_product.maingrp_code,NULL,l_rpt_idx) THEN 
					EXIT FOREACH 
				END IF 
		END CASE 
	END FOREACH 
	
	#------------------------------------------------------------
	FINISH REPORT EU6_rpt_list
	CALL rpt_finish("EU6_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = FALSE 
		ERROR " Printing was aborted" 
		RETURN FALSE 
	ELSE 
		RETURN TRUE 
	END IF
END FUNCTION 


###########################################################################
# REPORT EU6_rpt_list(p_rec_product, 
#	p_rec_mth_statprod, 
#	p_rec_pmth_statprod, 
#	p_rec_yr_statprod, 
#	p_rec_prev_statprod)
#
#
###########################################################################
REPORT EU6_rpt_list(p_rpt_idx,
	p_rec_product, 
	p_rec_mth_statprod, 
	p_rec_pmth_statprod, 
	p_rec_yr_statprod, 
	p_rec_prev_statprod)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	 	 
	DEFINE p_rec_product RECORD LIKE product.* 
	DEFINE p_rec_mth_statprod RECORD LIKE statprod.* 
	DEFINE p_rec_pmth_statprod RECORD LIKE statprod.* 
	DEFINE p_rec_yr_statprod RECORD 
		net_amt LIKE statprod.net_amt 
	END RECORD 
	DEFINE p_rec_prev_statprod RECORD 
		net_amt LIKE statprod.net_amt 
	END RECORD 
	DEFINE l_ytd_statprod LIKE statprod.net_amt
	DEFINE l_ptd_statprod LIKE statprod.net_amt
	 
	DEFINE l_cp_statprod LIKE statprod.net_amt
	DEFINE l_pp_statprod LIKE statprod.net_amt
	 
	DEFINE l_mth_variance FLOAT
	DEFINE l_ytd_variance FLOAT
	 
	DEFINE l_desc_text char(30) 

	OUTPUT 
 
	ORDER external BY p_rec_product.maingrp_code, 
	p_rec_product.prodgrp_code, 
	p_rec_product.part_code
	 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text #wasl_arr_line[2]

			CASE modu_order_ind
				WHEN '1' 
					PRINT COLUMN 01, "Product"; 
				WHEN '2' 
					PRINT COLUMN 01, "Product group"; 
				WHEN '3' 
					PRINT COLUMN 01, "Main group"; 
			END CASE 
			PRINT COLUMN 18, "Description", 
			COLUMN 53, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text
			
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			
			PRINT COLUMN 01, "Year: ", modu_rec_mth_statint.year_num USING "####", 
			COLUMN 15, "Interval: ", modu_rec_mth_statint.int_num USING "###" 
			
			SKIP 1 line 
			
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			
		BEFORE GROUP OF p_rec_product.maingrp_code 
			IF modu_order_ind = "3" THEN 
				LET l_ytd_variance = 0 
				LET l_ytd_statprod = 0 
				LET l_ptd_statprod = 0 
				LET l_cp_statprod = 0 
				LET l_pp_statprod = 0 
				LET l_mth_variance = 0 
			END IF 
			
		AFTER GROUP OF p_rec_product.maingrp_code 
			IF modu_order_ind = "3" THEN 
				SELECT desc_text INTO l_desc_text FROM maingrp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND maingrp_code = p_rec_product.maingrp_code 
				IF status = NOTFOUND THEN 
					LET l_desc_text = NULL 
				END IF 
				LET l_cp_statprod = GROUP sum(p_rec_mth_statprod.net_amt) 
				LET l_pp_statprod = GROUP sum(p_rec_pmth_statprod.net_amt) 
				IF l_pp_statprod = 0 THEN 
					LET l_mth_variance = 0 
				ELSE 
					LET l_mth_variance = ((l_cp_statprod - l_pp_statprod) / 
					l_pp_statprod) * 100 
				END IF 
				LET l_ytd_statprod = GROUP sum(p_rec_yr_statprod.net_amt) 
				LET l_ptd_statprod = GROUP sum(p_rec_prev_statprod.net_amt) 
				LET l_ytd_variance = ((l_ytd_statprod - l_ptd_statprod) / 
				l_ptd_statprod) * 100 
				PRINT COLUMN 01, p_rec_product.maingrp_code, 
				COLUMN 18, l_desc_text, 
				COLUMN 59,group sum(p_rec_mth_statprod.net_amt) 
				USING "-------&.&&", 
				COLUMN 71,group sum(p_rec_pmth_statprod.net_amt) 
				USING "-------&.&&", 
				COLUMN 84,l_mth_variance USING "------&.&& %", 
				COLUMN 97,group sum(p_rec_yr_statprod.net_amt) USING "------&.&&", 
				COLUMN 109,group sum(p_rec_prev_statprod.net_amt) 
				USING "------&.&&", 
				COLUMN 121,l_ytd_variance USING "------&.&& %" 
			END IF 
			
		BEFORE GROUP OF p_rec_product.prodgrp_code 
			IF modu_order_ind = "2" THEN 
				LET l_ytd_variance = 0 
				LET l_ytd_statprod = 0 
				LET l_ptd_statprod = 0 
				LET l_mth_variance = 0 
				LET l_cp_statprod = 0 
				LET l_pp_statprod = 0 
			END IF 
			
		AFTER GROUP OF p_rec_product.prodgrp_code 
			IF modu_order_ind = "2" THEN 
				SELECT desc_text INTO l_desc_text FROM prodgrp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND prodgrp_code = p_rec_product.prodgrp_code 
				IF status = NOTFOUND THEN 
					LET l_desc_text = NULL 
				END IF 
				LET l_cp_statprod = GROUP sum(p_rec_mth_statprod.net_amt) 
				LET l_pp_statprod = GROUP sum(p_rec_pmth_statprod.net_amt) 
				IF l_pp_statprod = 0 THEN 
					LET l_mth_variance = 0 
				ELSE 
					LET l_mth_variance = ((l_cp_statprod - l_pp_statprod) / 
					l_pp_statprod) * 100 
				END IF 
				LET l_ytd_statprod = GROUP sum(p_rec_yr_statprod.net_amt) 
				LET l_ptd_statprod = GROUP sum(p_rec_prev_statprod.net_amt) 
				IF l_ptd_statprod = 0 THEN 
					LET l_ytd_variance = 0 
				ELSE 
					LET l_ytd_variance = ((l_ytd_statprod - l_ptd_statprod) / 
					l_ptd_statprod) * 100 
				END IF 
				PRINT COLUMN 01, p_rec_product.prodgrp_code, 
				COLUMN 18, l_desc_text, 
				COLUMN 59, GROUP sum(p_rec_mth_statprod.net_amt) 
				USING "-------&.&&", 
				COLUMN 71, GROUP sum(p_rec_pmth_statprod.net_amt) 
				USING "-------&.&&", 
				COLUMN 84, l_mth_variance USING "------&.&& %", 
				COLUMN 97,group sum(p_rec_yr_statprod.net_amt) 
				USING "------&.&&", 
				COLUMN 109,group sum(p_rec_prev_statprod.net_amt) 
				USING "------&.&&", 
				COLUMN 121,l_ytd_variance USING "------&.&& %" 
			END IF 

		ON EVERY ROW 
			IF modu_order_ind = "1" THEN 
				IF p_rec_prev_statprod.net_amt = 0 THEN 
					LET l_ytd_variance = 0 
				ELSE 
					LET l_ytd_variance = ((p_rec_yr_statprod.net_amt - 
					p_rec_prev_statprod.net_amt) / 
					p_rec_prev_statprod.net_amt) * 100 
				END IF 
				IF p_rec_pmth_statprod.net_amt = 0 THEN 
					LET l_mth_variance = 0 
				ELSE 
					LET l_mth_variance = ((p_rec_mth_statprod.net_amt - 
					p_rec_pmth_statprod.net_amt) / 
					p_rec_pmth_statprod.net_amt) * 100 
				END IF 
				PRINT COLUMN 01, p_rec_product.part_code, 
				COLUMN 18, p_rec_product.desc_text, 
				COLUMN 59, p_rec_mth_statprod.net_amt USING "-------&.&&", 
				COLUMN 71, p_rec_pmth_statprod.net_amt USING "-------&.&&", 
				COLUMN 84, l_mth_variance USING "------&.&& %", 
				COLUMN 97, p_rec_yr_statprod.net_amt USING "------&.&&", 
				COLUMN 109,p_rec_prev_statprod.net_amt USING "------&.&&", 
				COLUMN 121,l_ytd_variance USING "------&.&& %" 
			END IF 
			
		ON LAST ROW 
			SKIP 1 line 
			LET l_ytd_statprod = sum(p_rec_yr_statprod.net_amt) 
			LET l_ptd_statprod = sum(p_rec_prev_statprod.net_amt) 
			IF l_ptd_statprod = 0 THEN 
				LET l_ytd_variance = 0 
			ELSE 
				LET l_ytd_variance = ((l_ytd_statprod - l_ptd_statprod) / 
				l_ptd_statprod) * 100 
			END IF 
			LET l_cp_statprod = sum(p_rec_mth_statprod.net_amt) 
			LET l_pp_statprod = sum(p_rec_pmth_statprod.net_amt) 
			IF l_pp_statprod = 0 THEN 
				LET l_mth_variance = 0 
			ELSE 
				LET l_mth_variance = ((l_cp_statprod - l_pp_statprod) / 
				l_pp_statprod) * 100 
			END IF 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			PRINT COLUMN 01, "Totals", 
			COLUMN 59, sum(p_rec_mth_statprod.net_amt) USING "-------&.&&", 
			COLUMN 71, sum(p_rec_pmth_statprod.net_amt) USING "-------&.&&", 
			COLUMN 84, l_mth_variance USING "------&.&& %", 
			COLUMN 97,sum(p_rec_yr_statprod.net_amt) USING "------&.&&", 
			COLUMN 109,sum(p_rec_prev_statprod.net_amt) USING "------&.&&", 
			COLUMN 121,l_ytd_variance USING "------&.&& %"
			 
			SKIP 1 LINES 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
			LET l_ytd_variance = 0 
			LET l_ytd_statprod = 0 
			LET l_ptd_statprod = 0 
			LET l_cp_statprod = 0 
			LET l_pp_statprod = 0 
			LET l_mth_variance = 0 
END REPORT