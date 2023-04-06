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

#	Source code beautified by beautify.pl on 2020-01-03 09:12:31	$Id: $

#KandooERP runs on Querix Lycia www.querix.com
#Adapted by eric@begooden.it,hoelzl@querix.com,a.bondar@querix.com

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/AA_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/AA3_GLOBALS.4gl" 
############################################################
# MODU Scope Variables
############################################################
DEFINE modu_skip_page_flag CHAR(1)
DEFINE modu_where_text CHAR(200)
DEFINE modu_temp_text VARCHAR(200)	
	
#####################################################################
# FUNCTION AA3_main()
#
# AA3 - Customer notes listing
#####################################################################
FUNCTION AA3_main() 

	CALL setModuleId("AA3")

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 
			OPEN WINDOW wa621 with FORM "A621" 
			CALL windecoration_a("A621") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
	
			MENU " Customer Notes Report" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","AA3","menu-customer-notes-rep") 
					CALL rpt_rmsreps_reset(NULL)
					CALL AA3_rpt_process(AA3_rpt_query())
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report"#COMMAND "Run Report" " SELECT criteria AND PRINT REPORT"
					CALL rpt_rmsreps_reset(NULL)
					CALL AA3_rpt_process(AA3_rpt_query())  
		
				ON ACTION "Print Manager"	#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","")
					 
				ON ACTION "CANCEL" # COMMAND KEY("E",interrupt)"Exit" " Exit TO menus"
					EXIT MENU 
		
			END MENU 
		
			CLOSE WINDOW wa621 

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL AA3_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW p120 with FORM "P120" 
			CALL windecoration_p("P120") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(AA3_rpt_query()) #save where clause in env 
			CLOSE WINDOW p120 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL AA3_rpt_process(get_url_sel_text())
	END CASE 


END FUNCTION 
#####################################################################
# END FUNCTION AA3_main()
#####################################################################


#####################################################################
# FUNCTION AA3_rpt_query()
# RETURN l_query_text
#
#####################################################################
FUNCTION AA3_rpt_query() 
	DEFINE l_where_text STRING
	MESSAGE kandoomsg2("A",1001,"") 

	CONSTRUCT BY NAME l_where_text ON customernote.cust_code, 
	customer.name_text, 
	customer.contact_text, 
	customer.tele_text, 
	customernote.note_date, 
	customernote.note_text 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","AA3","construct-customer") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL 
	END IF
	 
	LET modu_skip_page_flag = kandoomsg("A",8032,"") 	#A8043 Include Customer Page Break

	RETURN l_where_text
END FUNCTION
#####################################################################
# END FUNCTION AA3_rpt_query()
#####################################################################


#####################################################################
# FUNCTION AA3_rpt_process(p_where_text)
#
#
#####################################################################
FUNCTION AA3_rpt_process(p_where_text)
	DEFINE p_where_text STRING
	DEFINE l_rpt_idx SMALLINT  
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_query_text STRING
	DEFINE l_rec_customer RECORD LIKE customer.*
	DEFINE l_rec_customernote RECORD LIKE customernote.* 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF
	
		LET modu_skip_page_flag = kandoomsg("A",8032,"") 	#A8043 Include Customer Page Break


	LET l_rpt_idx = rpt_start(getmoduleid(),"AA3_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT AA3_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	LET l_query_text = "SELECT * FROM customer,", 
	"customernote ", 
	"WHERE customer.cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND customernote.cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND customer.cust_code=customernote.cust_code ", 
	"AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AA3_rpt_list")].sel_text clipped," ", 
	"ORDER BY" 
	
	IF glob_rec_arparms.report_ord_flag = "C" THEN 
		LET l_query_text = l_query_text clipped, 
		" customer.cust_code,note_date,note_num" 
	ELSE 
		LET l_query_text = l_query_text clipped, 
		" name_text,customer.cust_code,note_date,note_num" 
	END IF 
	
	PREPARE s_customer FROM l_query_text 
	DECLARE c_customer CURSOR FOR s_customer 
	FOREACH c_customer INTO l_rec_customer.*, l_rec_customernote.* 

		#---------------------------------------------------------
		OUTPUT TO REPORT AA3_rpt_list(l_rpt_idx,l_rec_customer.*,l_rec_customernote.*) 
		IF NOT rpt_int_flag_handler2("Customer:",l_rec_customer.cust_code, l_rec_customer.name_text,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------

	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT AA3_rpt_list
	CALL rpt_finish("AA3_rpt_list")
	#------------------------------------------------------------

	IF int_flag THEN
		RETURN FALSE
	ELSE
		RETURN TRUE
	END IF 	 
END FUNCTION 
#####################################################################
# END FUNCTION AA3_rpt_process(p_where_text)
#####################################################################


#####################################################################
# REPORT AA3_rpt_list(p_rec_customer,p_rec_customernote)
#
#
#####################################################################
REPORT AA3_rpt_list(p_rpt_idx,p_rec_customer,p_rec_customernote) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_customer RECORD LIKE customer.*
	DEFINE p_rec_customernote RECORD LIKE customernote.*
	DEFINE l_arr_line array[4] OF CHAR(132) 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 CLIPPED #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 CLIPPED  #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED  #wasl_arr_line[3] 

	BEFORE GROUP OF p_rec_customernote.cust_code 
		IF modu_skip_page_flag = "Y" THEN 
			SKIP TO top OF PAGE 
		ELSE 
			SKIP 2 LINES 
		END IF 
		PRINT 
		COLUMN 01, "Customer :",
		COLUMN 12, p_rec_customer.cust_code CLIPPED, 
		COLUMN 21, p_rec_customer.name_text CLIPPED 

	BEFORE GROUP OF p_rec_customernote.note_date 
		PRINT
		COLUMN 01, "Date :",
		COLUMN 08, p_rec_customernote.note_date USING "ddd dd/mm/yy" 

	ON EVERY ROW 
		PRINT COLUMN 08, p_rec_customernote.note_text CLIPPED WORDWRAP RIGHT MARGIN 80  

	AFTER GROUP OF p_rec_customernote.note_date 
		SKIP 2 LINES 

	ON LAST ROW 
		SKIP 1 line 
		#End Of Report
		IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
			PRINT COLUMN 01,"Selection Criteria:" 
			PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text CLIPPED WORDWRAP RIGHT MARGIN 100 
		END IF 
		PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report 			
		LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = PAGENO
			
END REPORT
#####################################################################
# END REPORT AA3_rpt_list(p_rec_customer,p_rec_customernote)
##################################################################### 