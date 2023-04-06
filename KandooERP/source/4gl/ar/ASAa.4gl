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
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/AS_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/ASAa_GLOBALS.4gl" 
############################################################
# Module Scope Variables
############################################################
--DEFINE modu_where_part CHAR(700) 
--DEFINE modu_query_text CHAR(700) 
--DEFINE modu_answer CHAR(1)
--DEFINE modu_ans CHAR(1)
--DEFINE modu_id_flag SMALLINT 
--DEFINE modu_idx SMALLINT 
--DEFINE modu_cnt SMALLINT 
--DEFINE modu_err_flag SMALLINT 
--DEFINE modu_mrow SMALLINT 
DEFINE modu_exist SMALLINT 
DEFINE modu_chosen SMALLINT 
DEFINE modu_number_labels SMALLINT 
#########################################################################
# FUNCTION ASAa_main()
#
#
#########################################################################
FUNCTION ASAa_main() 
	DEFER QUIT 
	DEFER INTERRUPT 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 
	
	CALL setModuleId("ASAa") 

	LET modu_number_labels = 0 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query

		WHEN RPT_OP_MENU #UI/MENU Mode 

			OPEN WINDOW A105 with FORM "A105" 
			CALL windecoration_a("A105") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
		
			MENU " Mailing Labels" 
		
				BEFORE MENU 
					CALL publish_toolbar("kandoo","ASAa","menu-mailing-labels") 
					CALL ASAa_rpt_process(ASAa_rpt_query())
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report"			#      COMMAND "Report" " SELECT criteria AND PRINT REPORT"
					CALL ASAa_rpt_process(ASAa_rpt_query())
		
				ON ACTION "Count" 			#      COMMAND "Count" " DISPLAY number of labels selected"
					MESSAGE kandoomsg2("A",7505,modu_number_labels) 
					#7505 9 mailing labels have been selected.
		
				ON ACTION "Print Manager" 			#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "Exit" 				#COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
					EXIT MENU 
			
			END MENU 
		
			CLOSE WINDOW A105 
	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL ASAa_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A105 with FORM "A6A10552" 
			CALL windecoration_a("A105") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(ASAa_rpt_query()) #save where clause in env 
			CLOSE WINDOW A105 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL ASAa_rpt_process(get_url_sel_text())
	END CASE			
END FUNCTION 

#########################################################################
# FUNCTION ASAa_rpt_query()
#
#
#########################################################################
FUNCTION ASAa_rpt_query()
	DEFINE l_where_text STRING
	 
	MESSAGE kandoomsg2("U",1001,"") 
	#1001 Enter selection criteria; OK TO Continue.
	CONSTRUCT BY NAME l_where_text ON cust_code, 
	name_text, 
	addr1_text, 
	addr2_text, 
	city_text, 
	state_code, 
	post_code, 
	country_text, 
	currency_code, 
	type_code, 
	sale_code, 
	term_code, 
	tax_code, 
	setup_date, 
	contact_text, 
	tax_num_text, 
	int_chge_flag, 
	registration_num, 
	vat_code, 
	tele_text, 
	mobile_phone, 
	fax_text,
	email
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","ASAa","construct-customer") 


		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 



	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL
	ELSE
		RETURN l_where_text
	END IF 	
END FUNCTION


#########################################################################
# FUNCTION ASAa_rpt_process(p_where_text)
#
#
#########################################################################
FUNCTION ASAa_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT 
	DEFINE l_rec_customer RECORD LIKE customer.*
	
	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"ASAa_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT ASAa_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ASAa_rpt_list")].sel_text
	#------------------------------------------------------------

	LET modu_exist = 0 
	LET modu_chosen = false 
	LET modu_exist = false 
	LET int_flag = false 

	LET modu_number_labels = 0 

	LET l_query_text = "SELECT * ", 
	"FROM customer ", 
	"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ASAa_rpt_list")].sel_text clipped, 
	" ORDER BY cust_code " 
	PREPARE statement_1 FROM l_query_text 
	DECLARE contact CURSOR FOR statement_1 


	OPEN contact 
	FOREACH contact INTO l_rec_customer.* 
		IF l_rec_customer.tele_text[1,1] <> "!" THEN
			#---------------------------------------------------------
			OUTPUT TO REPORT ASAa_rpt_list(l_rpt_idx,l_rec_customer.*)  
			LET modu_number_labels = (modu_number_labels + 1) 
			IF NOT rpt_int_flag_handler2("Customer:",l_rec_customer.name_text, NULL,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------
		END IF 
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT ASAa_rpt_list
	CALL rpt_finish("ASAa_rpt_list")
	#------------------------------------------------------------

	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF  
END FUNCTION 


#########################################################################
# REPORT ASAa_rpt_list(p_rec_customer)
# LABEL printing
#
#########################################################################
REPORT ASAa_rpt_list(p_rpt_idx,p_rec_customer) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE p_rec_customer RECORD LIKE customer.* 
	DEFINE l_arr_rec_customer array[3] OF RECORD 
		cust_code LIKE customer.cust_code, 
		contact_text LIKE customer.contact_text, 
		name_text LIKE customer.name_text, 
		addr1_text LIKE customer.addr1_text, 
		addr2_text LIKE customer.addr2_text, 
		city_text LIKE customer.city_text, 
		state_code LIKE customer.state_code, 
		post_code LIKE customer.post_code 
	END RECORD 
	DEFINE l_idx INTEGER 

	OUTPUT 
--	top margin 0 
--	bottom margin 0 
--	PAGE length 9 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
	
		ON EVERY ROW 
			IF l_idx < 3 THEN 
				LET l_idx = l_idx + 1 
				LET l_arr_rec_customer[l_idx].cust_code = p_rec_customer.cust_code 
				LET l_arr_rec_customer[l_idx].contact_text = p_rec_customer.contact_text 
				LET l_arr_rec_customer[l_idx].name_text = p_rec_customer.name_text 
				LET l_arr_rec_customer[l_idx].addr1_text = p_rec_customer.addr1_text 
				LET l_arr_rec_customer[l_idx].addr2_text = p_rec_customer.addr2_text 
				LET l_arr_rec_customer[l_idx].city_text = p_rec_customer.city_text 
				LET l_arr_rec_customer[l_idx].state_code = p_rec_customer.state_code 
				LET l_arr_rec_customer[l_idx].post_code = p_rec_customer.post_code 
			END IF 

			IF l_idx = 3 THEN 
				PRINT COLUMN 25, l_arr_rec_customer[1].cust_code, 
				COLUMN 61, l_arr_rec_customer[2].cust_code, 
				COLUMN 97, l_arr_rec_customer[3].cust_code 
				PRINT COLUMN 2, l_arr_rec_customer[1].contact_text, 
				COLUMN 38, l_arr_rec_customer[2].contact_text, 
				COLUMN 75, l_arr_rec_customer[3].contact_text 
				PRINT COLUMN 2, l_arr_rec_customer[1].name_text, 
				COLUMN 38, l_arr_rec_customer[2].name_text, 
				COLUMN 75, l_arr_rec_customer[3].name_text 
				PRINT COLUMN 2, l_arr_rec_customer[1].addr1_text, 
				COLUMN 38, l_arr_rec_customer[2].addr1_text, 
				COLUMN 75, l_arr_rec_customer[3].addr1_text 
				PRINT COLUMN 2, l_arr_rec_customer[1].addr2_text, 
				COLUMN 38, l_arr_rec_customer[2].addr2_text, 
				COLUMN 75, l_arr_rec_customer[3].addr2_text 
				PRINT COLUMN 2, l_arr_rec_customer[1].city_text clipped, 
				COLUMN 38, l_arr_rec_customer[2].city_text clipped, 
				COLUMN 75, l_arr_rec_customer[3].city_text clipped 
				PRINT COLUMN 2, l_arr_rec_customer[1].state_code clipped, " ", 
				l_arr_rec_customer[1].post_code clipped, 
				COLUMN 38, l_arr_rec_customer[2].state_code clipped, " ", 
				l_arr_rec_customer[2].post_code clipped, 
				COLUMN 75, l_arr_rec_customer[3].state_code clipped, " ", 
				l_arr_rec_customer[3].post_code clipped 
				LET l_idx = 0 
				SKIP TO top OF PAGE 
			END IF 
		ON LAST ROW 
			CASE 
				WHEN l_idx = 1 
					PRINT COLUMN 25, l_arr_rec_customer[1].cust_code 
					PRINT COLUMN 2, l_arr_rec_customer[1].contact_text 
					PRINT COLUMN 2, l_arr_rec_customer[1].name_text 
					PRINT COLUMN 2, l_arr_rec_customer[1].addr1_text 
					PRINT COLUMN 2, l_arr_rec_customer[1].addr2_text 
					PRINT COLUMN 2, l_arr_rec_customer[1].city_text clipped 
					PRINT COLUMN 2, l_arr_rec_customer[1].state_code clipped, " ", 
					l_arr_rec_customer[1].post_code clipped 
					SKIP TO top OF PAGE 
				WHEN l_idx = 2 
					PRINT COLUMN 25, l_arr_rec_customer[1].cust_code, 
					COLUMN 71, l_arr_rec_customer[2].cust_code 
					PRINT COLUMN 2, l_arr_rec_customer[1].contact_text, 
					COLUMN 38, l_arr_rec_customer[2].contact_text 
					PRINT COLUMN 2, l_arr_rec_customer[1].name_text, 
					COLUMN 38, l_arr_rec_customer[2].name_text 
					PRINT COLUMN 2, l_arr_rec_customer[1].addr1_text, 
					COLUMN 38, l_arr_rec_customer[2].addr1_text 
					PRINT COLUMN 2, l_arr_rec_customer[1].addr2_text, 
					COLUMN 38, l_arr_rec_customer[2].addr2_text 
					PRINT COLUMN 2, l_arr_rec_customer[1].city_text clipped, 
					COLUMN 38, l_arr_rec_customer[2].city_text clipped 
					PRINT COLUMN 2, l_arr_rec_customer[1].state_code clipped, " ", 
					l_arr_rec_customer[1].post_code clipped, 
					COLUMN 38, l_arr_rec_customer[2].state_code clipped, " ", 
					l_arr_rec_customer[2].post_code clipped 
					SKIP TO top OF PAGE 
			END CASE 
END REPORT 
