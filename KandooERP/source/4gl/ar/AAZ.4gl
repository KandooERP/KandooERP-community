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
}
{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/AA_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/AAZ_GLOBALS.4gl" 

#####################################################################
# FUNCTION AAZ_main()
#
# Purpose - Invoice Story Report
#####################################################################
FUNCTION AAZ_main()

	CALL setModuleId("AAZ") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 
			OPEN WINDOW A118 with FORM "A118" 
			CALL windecoration_a("A118") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
		
			MENU " Invoice Story Report" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","AAZ","menu-invoice-story-rep") 
					CALL rpt_rmsreps_reset(NULL)
					CALL AAZ_rpt_process(AAZ_rpt_query())
		
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report"	#COMMAND "Run" " SELECT criteria AND PRINT REPORT"
					CALL rpt_rmsreps_reset(NULL)
					CALL AAZ_rpt_process(AAZ_rpt_query())  
		
				ON ACTION "Print Manager"	#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "CANCEL"	#COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
					EXIT MENU 
		
			END MENU 
		
			CLOSE WINDOW A118 
			
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL AAZ_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A118 with FORM "A118" 
			CALL windecoration_a("A118") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(AAZ_rpt_query()) #save where clause in env 
			CLOSE WINDOW A118 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL AAZ_rpt_process(get_url_sel_text())
	END CASE 
END FUNCTION

#####################################################################
# FUNCTION AAZ_rpt_query()
#
#
#####################################################################
FUNCTION AAZ_rpt_query() 
	DEFINE l_rec_invstory RECORD 
		cust_code LIKE invstory.cust_code, 
		name_text LIKE customer.name_text, 
		note_date LIKE invstory.note_date, 
		note_num LIKE invstory.note_num, 
		note_text LIKE invstory.note_text 
	END RECORD 
	DEFINE l_where_text STRING
	DEFINE l_query_text STRING
	
	MESSAGE kandoomsg("U",1001,"") 

	
	#1001 Enter Selection Criteria; OK TO Continue.
	CONSTRUCT BY NAME l_where_text ON invstory.cust_code, 
	customer.name_text, 
	invstory.note_date, 
	invstory.note_text 


		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","AAZ","construct-invstory") 

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


#####################################################################
# FUNCTION AAZ_rpt_process(p_where_text) 
#
#
#####################################################################
FUNCTION AAZ_rpt_process(p_where_text) 
	DEFINE p_where_text STRING	
	DEFINE l_rpt_idx SMALLINT 
	DEFINE l_query_text STRING
	DEFINE l_rec_invstory RECORD 
		cust_code LIKE invstory.cust_code, 
		name_text LIKE customer.name_text, 
		note_date LIKE invstory.note_date, 
		note_num LIKE invstory.note_num, 
		note_text LIKE invstory.note_text 
	END RECORD 


	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"AAZ_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT AAZ_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------


	LET l_query_text = "SELECT invstory.cust_code, customer.name_text, ", 
	" invstory.note_date, invstory.note_num, ", 
	" invstory.note_text ", 
	" FROM invstory, customer ", 
	" WHERE customer.cust_code = invstory.cust_code ", 
	" AND invstory.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	" AND customer.cmpy_code = invstory.cmpy_code ", 
	" AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AAZ_rpt_list")].sel_text clipped," ", 
	" ORDER BY invstory.cust_code, note_date, note_num"
	 
	PREPARE s_invstory FROM l_query_text 
	DECLARE c_invstory CURSOR FOR s_invstory 


	FOREACH c_invstory INTO l_rec_invstory.* 

		#---------------------------------------------------------
		OUTPUT TO REPORT AA1_rpt_list(l_rpt_idx,l_rec_invstory.*) 
		IF NOT rpt_int_flag_handler2("Customer:",l_rec_invstory.cust_code, l_rec_invstory.name_text,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------
	
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT AAZ_rpt_list
	CALL rpt_finish("AAZ_rpt_list")
	#------------------------------------------------------------

	IF int_flag THEN
		RETURN FALSE
	ELSE
		RETURN TRUE
	END IF 	  

END FUNCTION 



#####################################################################
# REPORT AAZ_rpt_list(p_rec_invstory)
#
#
#####################################################################
REPORT AAZ_rpt_list(p_rpt_idx,p_rec_invstory) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_invstory RECORD 
		cust_code LIKE invstory.cust_code, 
		name_text LIKE customer.name_text, 
		note_date LIKE invstory.note_date, 
		note_num LIKE invstory.note_num, 
		note_text LIKE invstory.note_text 
	END RECORD 
	DEFINE l_temp_str STRING 
	OUTPUT 
--	left margin 0 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		ON EVERY ROW 
			PRINT COLUMN 10, p_rec_invstory.note_text 

		ON LAST ROW 
			SKIP 1 line
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = pageno
			
			SKIP TO top OF PAGE 
			PRINT COLUMN 20, "Total Items: ", count(*) USING "###" 

		BEFORE GROUP OF p_rec_invstory.cust_code 
			SKIP TO top OF PAGE 
			PRINT COLUMN 5, "Customer : ", p_rec_invstory.cust_code clipped, 
			2 spaces, p_rec_invstory.name_text 
			SKIP 2 LINES 

		BEFORE GROUP OF p_rec_invstory.note_date 
			PRINT COLUMN 5, "Date : ", p_rec_invstory.note_date 
			SKIP 1 line 

		AFTER GROUP OF p_rec_invstory.note_date 
			SKIP 2 LINES 
END REPORT