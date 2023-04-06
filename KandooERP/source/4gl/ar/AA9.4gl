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
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/AA_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/AA9_GLOBALS.4gl" 
############################################################
# MODU Scope Variables
############################################################
DEFINE modu_first_time SMALLINT
#####################################################################
# FUNCTION AA9_main()
#
# Customer Promotion Report
#####################################################################
FUNCTION AA9_main() 

	CALL setModuleId("AA9") 
	
	IF NOT fgl_find_table("t_priceoffer") THEN
		CREATE temp TABLE t_priceoffer (order_ind SMALLINT, 
		status_ind CHAR(1), 
		offer_code CHAR(6), 
		start_date DATE, 
		end_date DATE, 
		maingrp_code CHAR(3), 
		prodgrp_code CHAR(3), 
		part_code CHAR(15), 
		class_code CHAR(8), 
		ware_code CHAR(3), 
		disc_price_amt DECIMAL(16,4), 
		uom_code CHAR(4), 
		disc_per DECIMAL(6,3), 
		list_level_ind CHAR(1), 
		prom1_text CHAR(60), 
		prom2_text CHAR(60), 
		cust_code CHAR(8), 
		name_text CHAR(30), 
		type_ind CHAR(1)) with no LOG 
	END IF
	
	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 
			OPEN WINDOW A698 with FORM "A698" 
			CALL windecoration_a("A698")
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

			MENU " Customer Promotions Report" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","AA9","menu-promotion-rep") 				
					CALL rpt_rmsreps_reset(NULL)				
					CALL AA9_rpt_process(AA9_rpt_query())
								
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON ACTION "Report" #COMMAND "Run" " Enter selection criteria AND generate REPORT"
					CALL rpt_rmsreps_reset(NULL)					
					IF fgl_find_table("t_priceoffer") THEN
						DELETE FROM t_priceoffer WHERE "1=1"
					END IF

					CALL AA9_rpt_process(AA9_rpt_query())

				ON ACTION "Print Manager"	#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL"	#COMMAND KEY("E",interrupt)"Exit" " Exit TO menus"
					EXIT MENU 

			END MENU 

			CLOSE WINDOW A698 

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL AA9_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A698 with FORM "A698" 
			CALL windecoration_a("A698") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(AA9_rpt_query()) #save where clause in env 
			CLOSE WINDOW A698 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL AA9_rpt_process(get_url_sel_text())

	END CASE 	

	IF fgl_find_table("t_priceoffer") THEN
		DROP TABLE t_priceoffer
	END IF
	
END FUNCTION 
#####################################################################
# END FUNCTION AA9_main()
#####################################################################


#####################################################################
# FUNCTION AA9_rpt_query()
#
#
#####################################################################
FUNCTION AA9_rpt_query() 
	DEFINE l_where_text1 STRING #Return 1
	DEFINE l_where_text2 STRING #Return 2
	DEFINE l_where_text3 STRING #Return 3


	LET glob_rec_rpt_selector.sel_option1 = "4" 
	MESSAGE kandoomsg2("U",1020,"Promotion")	#1020 Enter Promotion Details; OK TO Continue.
	INPUT glob_rec_rpt_selector.sel_option1 WITHOUT DEFAULTS FROM promotion_status 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","AA9","inp-promotion_status") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL 
	END IF 

	MESSAGE kandoomsg2("U",1001,"") 

	CONSTRUCT BY NAME l_where_text1 ON customer.cust_code, 
	customer.name_text, 
	customer.sale_code, 
	customer.territory_code, 
	pricing.offer_code, 
	pricing.type_ind, 
	pricing.start_date, 
	pricing.end_date, 
	pricing.maingrp_code, 
	pricing.prodgrp_code, 
	pricing.part_code, 
	pricing.class_code, 
	pricing.ware_code, 
	pricing.disc_price_amt, 
	pricing.uom_code, 
	pricing.disc_per, 
	pricing.list_level_ind 


		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","AA9","construct-promotion") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL,NULL, NULL
	ELSE 
		LET l_where_text1 = " ", l_where_text1 CLIPPED, " "
	END IF 


{
	IF l_where_text2 IS NOT NULL THEN
		LET l_where_text1 = l_where_text1, " AND ", l_where_text2
	END IF

	IF l_where_text3 IS NOT NULL THEN
		LET l_where_text1 = l_where_text1, " AND ", l_where_text3
	END IF

}
	RETURN l_where_text1
	
END FUNCTION 
#####################################################################
# END FUNCTION AA9_rpt_query()
#####################################################################


#####################################################################
# FUNCTION AA9_rpt_process(p_where_text)
#
#
#####################################################################
FUNCTION AA9_rpt_process(p_where_text)
	DEFINE p_where_text STRING
	DEFINE l_where_text2 STRING	
	DEFINE l_where_text3 STRING	
	--DEFINE l_promotion_status CHAR(1) replaced by glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AA9_rpt_list")].sel_option1_text 
	DEFINE l_rpt_idx SMALLINT #rpt array index
	DEFINE l_rec_priceoffer RECORD 
		order_ind SMALLINT, 
		status_ind CHAR(1), 
		offer_code CHAR(6), 
		start_date DATE, 
		end_date DATE, 
		maingrp_code CHAR(3), 
		prodgrp_code CHAR(3), 
		part_code CHAR(15), 
		class_code CHAR(8), 
		ware_code CHAR(3), 
		disc_price_amt DECIMAL(16,4), 
		uom_code CHAR(4), 
		disc_per DECIMAL(6,3), 
		list_level_ind CHAR(1), 
		prom1_text CHAR(60), 
		prom2_text CHAR(60), 
		cust_code CHAR(8), 
		name_text CHAR(30), 
		type_ind CHAR(1) 
	END RECORD
	DEFINE l_query_text STRING
	DEFINE l_rec_pricing RECORD LIKE pricing.*
	DEFINE l_rec_customer RECORD LIKE customer.*
	DEFINE l_rec_custoffer RECORD LIKE custoffer.*
	DEFINE l_continue SMALLINT 
	DEFINE l_i SMALLINT
	DEFINE l_j SMALLINT
	DEFINE l_pricing_selection SMALLINT
	DEFINE l_length SMALLINT 
	DEFINE l_customer_selection SMALLINT

	#------------------------------------------------------------	
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false
		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"AA9_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT AA9_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------
	

--	LET glob_rec_rmsreps.ref1_ind = p_promotion_status		
--	LET l_length = length(glob_rec_rmsreps.sel_text) 
	LET l_length = length(p_where_text) 

	CASE glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AA9_rpt_list")].sel_option1  
		WHEN "1" 
			LET l_where_text3 = " ((start_date <= today AND end_date >= today) ", 
			" OR (start_date <= today AND end_date IS NULL)) " 
		WHEN "2" 
			LET l_where_text3 = " end_date < today " 
		WHEN "3" 
			LET l_where_text3 = " start_date > today " 
		WHEN "4" 
			LET l_where_text3 = " 1=1 " 
		WHEN "5" 
			LET l_where_text3 = " ((start_date <= today AND end_date >= today) ", 
			" OR (start_date <= today AND end_date IS NULL) ", 
			" OR (end_date < today)) " 
		WHEN "6" 
			LET l_where_text3 = " ((start_date <= today AND end_date >= today) ", 
			" OR (start_date <= today AND end_date IS NULL) ", 
			" OR (start_date > today)) " 
		WHEN "7" 
			LET l_where_text3 = " ((end_date < today) OR (start_date > today)) " 

	END CASE 

	LET l_customer_selection = false 
	LET l_pricing_selection = false 

	IF l_length > 5 THEN #Otherwise it's only a " 1=1 "
		FOR l_i = 1 TO (l_length - 1) 
			IF p_where_text[l_i,l_i+7] = "customer" THEN 
				LET l_customer_selection = true 
				EXIT FOR 
			END IF 
		END FOR 
	
		FOR l_j = 1 TO (l_length - 1) 
			IF p_where_text[l_j,l_j+6] = "pricing" THEN 
				LET l_pricing_selection = true 
				EXIT FOR 
			END IF 
		END FOR 

		#Customer Selection
		IF NOT l_customer_selection THEN 
			LET p_where_text = " 1=1 " 
		ELSE 
			IF l_pricing_selection THEN 
				LET p_where_text = p_where_text[1,l_j-5] 
			ELSE 
				LET p_where_text = p_where_text[1,l_j] 
			END IF 
		END IF 
	
		#Price Selection
		IF NOT l_pricing_selection THEN 
			LET l_where_text2 = "1=1" 
		ELSE 
			LET l_where_text2 = l_where_text2[l_j,l_length] 
		END IF 
	END IF

	IF l_where_text2 IS NULL THEN
		LET l_where_text2 = " 1=1 "
	END IF

	LET l_query_text = "SELECT pricing.*, custoffer.* ", 
	" FROM pricing, outer custoffer ", 
	" WHERE pricing.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND pricing.offer_code = custoffer.offer_code ", 
	" AND custoffer.cust_code ", 
	" in (SELECT cust_code FROM customer ", 
	" WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND ",p_where_text clipped, ") ", 
	" AND custoffer.cmpy_code = pricing.cmpy_code ", 
	" AND ",l_where_text2 clipped, " ", 
	" AND ",l_where_text3 clipped, " ", 
	" ORDER BY pricing.type_ind " 

	PREPARE s_pricing FROM l_query_text 
	DECLARE c_pricing CURSOR FOR s_pricing 

	INITIALIZE l_rec_custoffer.* TO NULL 
	INITIALIZE l_rec_customer.* TO NULL 

	LET l_continue = true

	 
	FOREACH c_pricing INTO l_rec_pricing.*, l_rec_custoffer.* 
		INITIALIZE l_rec_priceoffer.* TO NULL
		 
		IF NOT (l_rec_pricing.type_ind = "2" 
		OR l_rec_pricing.type_ind = "4" 
		OR l_rec_pricing.type_ind = "6") THEN 
			IF l_rec_custoffer.cust_code IS NULL THEN 
				CONTINUE FOREACH 
			ELSE 
				CALL db_customer_get_rec(UI_OFF,l_rec_custoffer.cust_code) RETURNING l_rec_customer.*
--				SELECT * INTO l_rec_customer.* FROM customer 
--				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
--				AND cust_code = l_rec_custoffer.cust_code 
				IF l_rec_customer.cust_code IS NULL THEN			
--				IF status = NOTFOUND THEN 
					CONTINUE FOREACH 
				END IF 
			END IF 
		END IF
		 
		LET l_rec_priceoffer.offer_code = l_rec_pricing.offer_code 
		LET l_rec_priceoffer.start_date = l_rec_pricing.start_date 
		LET l_rec_priceoffer.end_date = l_rec_pricing.end_date 
		LET l_rec_priceoffer.maingrp_code = l_rec_pricing.maingrp_code 
		LET l_rec_priceoffer.prodgrp_code = l_rec_pricing.prodgrp_code 
		LET l_rec_priceoffer.part_code = l_rec_pricing.part_code 
		LET l_rec_priceoffer.class_code = l_rec_pricing.class_code 
		LET l_rec_priceoffer.ware_code = l_rec_pricing.ware_code 
		LET l_rec_priceoffer.disc_price_amt = l_rec_pricing.disc_price_amt 
		LET l_rec_priceoffer.uom_code = l_rec_pricing.uom_code 
		LET l_rec_priceoffer.disc_per = l_rec_pricing.disc_per 
		LET l_rec_priceoffer.list_level_ind = l_rec_pricing.list_level_ind 

		IF l_rec_pricing.start_date > today THEN 
			LET l_rec_priceoffer.status_ind = "F" 
		ELSE 
			IF l_rec_pricing.end_date < today THEN 
				LET l_rec_priceoffer.status_ind = "E" 
			ELSE 
				LET l_rec_priceoffer.status_ind = "C" 
			END IF 
		END IF 
		LET l_rec_priceoffer.type_ind = l_rec_pricing.type_ind 

		CASE l_rec_pricing.type_ind 
			WHEN "1" 
				LET l_rec_priceoffer.order_ind = 4 
				LET l_rec_priceoffer.cust_code = l_rec_custoffer.cust_code 
				LET l_rec_priceoffer.name_text = l_rec_customer.name_text 
			WHEN "2" 
				LET l_rec_priceoffer.cust_code = " " 
				LET l_rec_priceoffer.order_ind = 1 
			WHEN "3" 
				LET l_rec_priceoffer.order_ind = 5 
				LET l_rec_priceoffer.cust_code = l_rec_custoffer.cust_code 
				LET l_rec_priceoffer.name_text = l_rec_customer.name_text 
				LET l_rec_priceoffer.prom1_text = l_rec_pricing.prom1_text 
				LET l_rec_priceoffer.prom2_text = l_rec_pricing.prom2_text 
			WHEN "4" 
				LET l_rec_priceoffer.order_ind = 2 
				LET l_rec_priceoffer.cust_code = " " 
				LET l_rec_priceoffer.prom1_text = l_rec_pricing.prom1_text 
				LET l_rec_priceoffer.prom2_text = l_rec_pricing.prom2_text 
			WHEN "5" 
				LET l_rec_priceoffer.order_ind = 6 
				LET l_rec_priceoffer.cust_code = l_rec_custoffer.cust_code 
				LET l_rec_priceoffer.name_text = l_rec_customer.name_text 
			WHEN "6" 
				LET l_rec_priceoffer.cust_code = " " 
				LET l_rec_priceoffer.order_ind = 3 
		END CASE 

		INSERT INTO t_priceoffer VALUES (l_rec_priceoffer.*) 

		INITIALIZE l_rec_custoffer.* TO NULL 
		INITIALIZE l_rec_customer.* TO NULL 
		IF NOT rpt_int_flag_handler2("Promotion:",l_rec_pricing.offer_code,l_rec_pricing.desc_text,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 

	END FOREACH 

	LET modu_first_time = 1 
	IF l_continue THEN 
		DECLARE c_priceoffer CURSOR FOR 
		SELECT * FROM t_priceoffer 
		ORDER BY cust_code, order_ind 
		
		FOREACH c_priceoffer INTO l_rec_priceoffer.* 

			OUTPUT TO REPORT AA9_rpt_list(l_rpt_idx,l_rec_priceoffer.*) 
			IF NOT rpt_int_flag_handler2("Promotion:",l_rec_priceoffer.offer_code, l_rec_pricing.desc_text,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF
		END FOREACH
		 
	END IF 
	 
	#------------------------------------------------------------
	FINISH REPORT AA9_rpt_list
	CALL rpt_finish("AA9_rpt_list")
	#------------------------------------------------------------

	DELETE FROM t_priceoffer WHERE 1=1 

	IF int_flag THEN
		RETURN FALSE
	ELSE
		RETURN TRUE
	END IF 	 
END FUNCTION 
#####################################################################
# END FUNCTION AA9_rpt_process(p_where_text)
#####################################################################


#####################################################################
# REPORT AA9_rpt_list(p_rpt_idx,p_rec_priceoffer) 
#
#
#####################################################################
REPORT AA9_rpt_list(p_rpt_idx,p_rec_priceoffer) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_priceoffer RECORD 
		order_ind SMALLINT, 
		status_ind CHAR(1), 
		offer_code CHAR(6), 
		start_date DATE, 
		end_date DATE, 
		maingrp_code CHAR(3), 
		prodgrp_code CHAR(3), 
		part_code CHAR(15), 
		class_code CHAR(8), 
		ware_code CHAR(3), 
		disc_price_amt DECIMAL(16,4), 
		uom_code CHAR(4), 
		disc_per DECIMAL(6,3), 
		list_level_ind CHAR(1), 
		prom1_text CHAR(60), 
		prom2_text CHAR(60), 
		cust_code CHAR(8), 
		name_text CHAR(30), 
		type_ind CHAR(1) 
	END RECORD
	DEFINE l_first_promo SMALLINT
	DEFINE l_arr_line array[4] OF CHAR(132) 

	OUTPUT 
--	left margin 0 
	ORDER external BY p_rec_priceoffer.cust_code,	p_rec_priceoffer.order_ind 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text			
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		BEFORE GROUP OF p_rec_priceoffer.order_ind 
			IF (p_rec_priceoffer.order_ind = "1" 
			OR p_rec_priceoffer.order_ind = "2" 
			OR p_rec_priceoffer.order_ind = "3") 
			AND modu_first_time = 1 THEN 
				SKIP TO top OF PAGE 
				PRINT COLUMN 001, "ALL CUSTOMERS" 
				LET modu_first_time = 2 
			END IF 
			IF NOT l_first_promo THEN 
			ELSE 
				LET l_first_promo = false 
			END IF 
			IF (p_rec_priceoffer.order_ind = "4" 
			OR p_rec_priceoffer.order_ind = "5" 
			OR p_rec_priceoffer.order_ind = "6") 
			AND modu_first_time = 2 THEN 
				LET modu_first_time = 3 
			END IF 

		BEFORE GROUP OF p_rec_priceoffer.cust_code 
			LET l_first_promo = true 
			IF p_rec_priceoffer.cust_code IS NOT NULL 
			AND p_rec_priceoffer.cust_code != " " THEN 
				IF modu_first_time = 2 THEN 
					SKIP TO top OF PAGE 
				ELSE 
					SKIP 1 line 
				END IF 
				PRINT COLUMN 001, p_rec_priceoffer.cust_code, 
				COLUMN 010, p_rec_priceoffer.name_text 
			END IF 

		ON EVERY ROW 
			IF p_rec_priceoffer.order_ind = "1" 
			OR p_rec_priceoffer.order_ind = "3" 
			OR p_rec_priceoffer.order_ind = "4" 
			OR p_rec_priceoffer.order_ind = "6" THEN 
				PRINT COLUMN 009, p_rec_priceoffer.type_ind, 
				COLUMN 013, p_rec_priceoffer.offer_code, 
				COLUMN 021, p_rec_priceoffer.start_date, 
				COLUMN 033, p_rec_priceoffer.end_date, 
				COLUMN 056, p_rec_priceoffer.maingrp_code, 
				COLUMN 062, p_rec_priceoffer.prodgrp_code, 
				COLUMN 068, p_rec_priceoffer.part_code, 
				COLUMN 084, p_rec_priceoffer.class_code, 
				COLUMN 093, p_rec_priceoffer.ware_code, 
				COLUMN 098, p_rec_priceoffer.disc_price_amt USING "------&.&&", 
				COLUMN 109, p_rec_priceoffer.uom_code, 
				COLUMN 113, p_rec_priceoffer.disc_per USING "---&.&&", 
				COLUMN 123, p_rec_priceoffer.list_level_ind, 
				COLUMN 130, p_rec_priceoffer.status_ind 
			ELSE 
				PRINT COLUMN 009, p_rec_priceoffer.type_ind, 
				COLUMN 013, p_rec_priceoffer.offer_code, 
				COLUMN 021, p_rec_priceoffer.start_date, 
				COLUMN 033, p_rec_priceoffer.end_date, 
				COLUMN 044, p_rec_priceoffer.prom1_text, 
				COLUMN 130, p_rec_priceoffer.status_ind 
				IF p_rec_priceoffer.prom2_text IS NOT NULL 
				AND p_rec_priceoffer.prom2_text != " " THEN 
					PRINT COLUMN 044, p_rec_priceoffer.prom2_text 
				END IF 
			END IF 

		ON LAST ROW 
			SKIP 1 line 

			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = pageno

			PRINT COLUMN 01, "Report Type: ", glob_arr_rec_rpt_rmsreps[p_rpt_idx].ref1_ind 
			--PRINT COLUMN 01, l_arr_line[4] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 			

END REPORT
#####################################################################
# END REPORT AA9_rpt_list(p_rpt_idx,p_rec_priceoffer) 
#####################################################################