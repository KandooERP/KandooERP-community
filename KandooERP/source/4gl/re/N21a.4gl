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
GLOBALS "../re/N_RE_GLOBALS.4gl"
GLOBALS "../re/N2_GROUP_GLOBALS.4gl"
GLOBALS "../re/N21_GLOBALS.4gl"  

{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module N21a  Picking Slip Print FUNCTION


FUNCTION create_pickslip(p_cmpy,p_kandoouser_sign_on_code,where_text) 
	DEFINE l_rpt_idx SMALLINT  
	DEFINE 
	p_cmpy LIKE company.cmpy_code, 
	p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code, 
	where_text STRING, 
	pr_reqhead RECORD LIKE reqhead.*, 
	pr_reqdetl RECORD LIKE reqdetl.*, 
	pr_reqaudit RECORD LIKE reqaudit.*, 
	pr_delhead RECORD LIKE delhead.*, 
	pr_deldetl RECORD LIKE deldetl.*, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	err_message CHAR(60), 
	err_continue CHAR(1), 

	query_text STRING , 
	ans CHAR(1), 
	pr_line_cnt, 
	orders_found SMALLINT 


	#------------------------------------------------------------
	IF (where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"N21_rpt_list_pick",where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT N21_rpt_list_pick TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------


	LET query_text = 
	"SELECT reqhead.* ", 
	"FROM reqhead ", 
	"WHERE reqhead.cmpy_code = \"",p_cmpy,"\" ", 
	"AND reqhead.status_ind > 0 ", 
	"AND exists ( SELECT 1 FROM reqdetl ", 
	"WHERE reqdetl.cmpy_code = \"",p_cmpy,"\" ", 
	"AND reqdetl.req_num = reqhead.req_num ", 
	"AND reqdetl.reserved_qty > 0 ) ", 
	"AND ",where_text clipped," ", 
	"ORDER BY reqhead.cmpy_code,", 
	"reqhead.req_num" 

	PREPARE s_reqhead FROM query_text 
	DECLARE c_reqhead CURSOR with HOLD FOR s_reqhead 

	LET orders_found = false 
	FOREACH c_reqhead INTO pr_reqhead.* 
		GOTO bypass 
		LABEL recovery: 
		LET err_continue = error_recover(err_message, status) 
		IF err_continue != "Y" THEN 
			EXIT program 
		END IF 
		LABEL bypass: 
		WHENEVER ERROR GOTO recovery 
		BEGIN WORK 
			IF NOT orders_found THEN 
				MESSAGE"" 
				display" Generating Picking Slip FOR Delivery No.: " at 1,1 
				display" Requisition No.: " at 2,1 
				LET orders_found = true 
			END IF 
			LET err_message = "N21a - Locking Reqparms FOR Next Del No." 
			DECLARE c_reqparms CURSOR FOR 
			SELECT * 
			FROM reqparms 
			WHERE cmpy_code = p_cmpy 
			AND key_code = "1" 
			FOR UPDATE 
			OPEN c_reqparms 
			FETCH c_reqparms INTO glob_rec_reqparms.* 
			LET pr_delhead.del_num = glob_rec_reqparms.next_del_num 
			LET pr_reqhead.last_del_no = glob_rec_reqparms.next_del_num 

			#DISPLAY glob_rec_reqparms.next_del_num at 1,44 	attribute(yellow) 
			 
			#DISPLAY pr_reqhead.req_num at 2,44	attribute(yellow)
 
			DECLARE c_reqdetl CURSOR FOR 
			SELECT * 
			FROM reqdetl 
			WHERE cmpy_code = pr_reqhead.cmpy_code 
			AND req_num = pr_reqhead.req_num 
			AND reserved_qty > 0 

			FOR UPDATE 
			LET pr_line_cnt = 0 

			FOREACH c_reqdetl INTO pr_reqdetl.* 
				SELECT * 
				INTO pr_prodstatus.* 
				FROM prodstatus 
				WHERE cmpy_code = pr_reqhead.cmpy_code 
				AND ware_code = pr_reqhead.ware_code 
				AND part_code = pr_reqdetl.part_code 


				#---------------------------------------------------------
				OUTPUT TO REPORT N21_rpt_list_pick(l_rpt_idx,
				pr_reqhead.*, 
				pr_reqdetl.*, 
				pr_prodstatus.*) 
				#---------------------------------------------------------
				
				LET err_message = "N21a - Updating Requisition Details " 

				UPDATE reqdetl 
				SET seq_num = pr_reqdetl.seq_num + 1, 
				picked_qty = pr_reqdetl.picked_qty
				+ pr_reqdetl.reserved_qty, 
				reserved_qty = 0 
				WHERE cmpy_code = pr_reqdetl.cmpy_code 
				AND req_num = pr_reqdetl.req_num 
				AND line_num = pr_reqdetl.line_num 
				#LET err_message = "N21a - Inserting Requisition Audit "
				#LET pr_reqaudit.cmpy_code = p_cmpy
				#LET pr_reqaudit.req_num = pr_reqhead.req_num
				#LET pr_reqaudit.line_num = pr_reqdetl.line_num
				#LET pr_reqaudit.seq_num = pr_reqdetl.seq_num + 1
				#LET pr_reqaudit.tran_type_ind = "PR"
				#LET pr_reqaudit.tran_date = today
				#LET pr_reqaudit.entry_code = p_kandoouser_sign_on_code
				#LET pr_reqaudit.unit_cost_amt = pr_reqdetl.unit_sales_amt
				#LET pr_reqaudit.unit_tax_amt = 0
				#LET pr_reqaudit.unit_sales_amt = pr_reqdetl.unit_sales_amt
				#LET pr_reqaudit.tran_qty = pr_reqdetl.reserved_qty
				#INSERT INTO reqaudit VALUES(pr_reqaudit.*)
				LET err_message = "N21a - Inserting Delivery Detail Row " 
				INITIALIZE pr_deldetl.* TO NULL 
				LET pr_line_cnt = pr_line_cnt + 1 
				LET pr_deldetl.cmpy_code = p_cmpy 
				LET pr_deldetl.del_num = pr_delhead.del_num 
				LET pr_deldetl.line_num = pr_line_cnt 
				LET pr_deldetl.sched_qty = pr_reqdetl.reserved_qty 
				LET pr_deldetl.conf_qty = 0 
				LET pr_deldetl.unit_cost_amt = pr_reqdetl.unit_cost_amt 
				LET pr_deldetl.unit_tax_amt = pr_reqdetl.unit_tax_amt 
				LET pr_deldetl.unit_sales_amt = pr_reqdetl.unit_sales_amt 
				LET pr_deldetl.req_line_num = pr_reqdetl.line_num 
				INSERT INTO deldetl VALUES (pr_deldetl.*) 
			END FOREACH 
			
			LET err_message = "N21a - Inserting Delivery Header Details " 
			INITIALIZE pr_delhead.* TO NULL 

			LET pr_delhead.cmpy_code = p_cmpy 
			LET pr_delhead.del_num = glob_rec_reqparms.next_del_num 
			LET pr_delhead.req_num = pr_reqhead.req_num 
			LET pr_delhead.type_ind = 1 
			LET pr_delhead.person_code = pr_reqhead.person_code 
			LET pr_delhead.ware_code = pr_reqhead.ware_code 
			LET pr_delhead.del_name_text = pr_reqhead.del_name_text 
			LET pr_delhead.del_addr1_text = pr_reqhead.del_addr1_text 
			LET pr_delhead.del_addr2_text = pr_reqhead.del_addr2_text 
			LET pr_delhead.del_addr3_text = pr_reqhead.del_addr3_text 
			LET pr_delhead.del_city_text = pr_reqhead.del_city_text 
			LET pr_delhead.del_state_code = pr_reqhead.del_state_code 
			LET pr_delhead.del_post_code = pr_reqhead.del_post_code 
			LET pr_delhead.del_country_code = pr_reqhead.del_country_code 
			LET pr_delhead.status_ind = 0 

			INSERT INTO delhead VALUES (pr_delhead.*) 

			LET pr_reqhead.last_del_date = today 
			LET pr_reqhead.last_del_no = pr_delhead.del_num 

			UPDATE reqhead 
			SET status_ind = 2, 
			last_del_no = pr_reqhead.last_del_no, 
			last_del_date = pr_reqhead.last_del_date 
			WHERE cmpy_code = p_cmpy 
			AND req_num = pr_reqhead.req_num 
			LET glob_rec_reqparms.next_del_num = glob_rec_reqparms.next_del_num + 1
			 
			UPDATE reqparms 
			SET next_del_num = glob_rec_reqparms.next_del_num 
			WHERE CURRENT OF c_reqparms
			 
			CLOSE c_reqparms
			 
		COMMIT WORK 
		WHENEVER ERROR stop
		 
	END FOREACH
	 
	IF orders_found = false THEN 
		--MESSAGE "" 
		MESSAGE " No Orders Requiring Picking were Selected " 
		--      prompt  "                   Any key TO continue " FOR CHAR ans  -- albo
		CALL eventsuspend() --LET ans = AnyKey(" Any key TO continue ",14,25) -- albo 
	ELSE 

	#------------------------------------------------------------
	FINISH REPORT N21_rpt_list_pick
	CALL rpt_finish("N21_rpt_list_pick")
	#------------------------------------------------------------	

	END IF 
	#IF arg_val(0) matches "N11.*" THEN
	IF get_baseprogname() matches "N11" THEN 
		SLEEP 3 
	END IF 
	--   CLOSE WINDOW w1_N21    -- albo  KD-763
	LET int_flag = false 
	LET quit_flag = false 
	--RETURN pr_output 
END FUNCTION 


REPORT N21_rpt_list_pick(p_rpt_idx,pr_reqhead, 
	pr_reqdetl, 
	pr_prodstatus) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]		
	DEFINE 
	pr_reqhead RECORD LIKE reqhead.*, 
	pr_reqdetl RECORD LIKE reqdetl.*, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pr_reqperson RECORD LIKE reqperson.*, 
	pa_address array[5] OF CHAR(40), 
	pr_product RECORD LIKE product.*, 
	pr_ordpick_qty LIKE prodstatus.onhand_qty, 
	pr_reqpick_qty LIKE prodstatus.onhand_qty, 
	pr_product_bal_qty LIKE prodstatus.onhand_qty, 
	i, j SMALLINT 

	OUTPUT 
	ORDER external BY pr_reqdetl.cmpy_code, pr_reqdetl.req_num 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
				
		BEFORE GROUP OF pr_reqdetl.req_num 
			SKIP TO top OF PAGE 
			SELECT * 
			INTO pr_reqperson.* 
			FROM reqperson 
			WHERE cmpy_code = pr_reqhead.cmpy_code 
			AND person_code = pr_reqhead.person_code 
			LET pa_address[1] = pr_reqhead.del_name_text 
			LET pa_address[2] = pr_reqhead.del_addr1_text 
			LET pa_address[3] = pr_reqhead.del_addr2_text 
			LET pa_address[4] = pr_reqhead.del_addr3_text 
			LET pa_address[5] = pr_reqhead.del_city_text," ", 
			pr_reqhead.del_state_code," ", 
			pr_reqhead.del_post_code 
			FOR i = 1 TO 4 
				LET j = i 
				WHILE pa_address[i] IS NULL 
					LET j = j + 1 
					LET pa_address[i] = pa_address[j] 
					LET pa_address[j] = NULL 
					IF j = 5 THEN 
						EXIT FOR 
					END IF 
				END WHILE 
			END FOR 
			PRINT COLUMN 1, COLUMN 2, " P-I-C-K-I-N-G L-I-S-T" 
			SKIP 3 LINES 
			PRINT COLUMN 02, glob_rec_company.name_text clipped 
			
			PRINT COLUMN 02, glob_rec_company.addr1_text clipped, 
			COLUMN 30, "Requisition No. : ", 
			pr_reqhead.req_num USING "<<<<<<<<" 
			
			PRINT COLUMN 02, glob_rec_company.city_text clipped," ", 
			glob_rec_company.state_code," ", 
			glob_rec_company.post_code clipped, 
			COLUMN 30, "Requisition Date: ", 
			pr_reqhead.req_date USING "mmm dd yyyy" 
			
			PRINT COLUMN 05, glob_rec_company.tele_text clipped 
			SKIP 1 line 
			PRINT COLUMN 03, "Issued TO:", 
			COLUMN 47, "Delivery Location:" 
			PRINT COLUMN 06, pr_reqperson.name_text, 
			COLUMN 53, pa_address[1] 
			PRINT COLUMN 06, pr_reqperson.dept_text, 
			COLUMN 53, pa_address[2] 
			
			FOR i = 3 TO 5 
				IF pa_address[i] IS NOT NULL THEN 
					PRINT COLUMN 53,pa_address[i] 
				END IF 
			END FOR 
			
			SKIP 1 line 
			PRINT COLUMN 03, "Person Code: ",pr_reqhead.person_code, 
			COLUMN 40, "Department: ",pr_reqhead.del_dept_text 
			PRINT COLUMN 03, "Issue Date: ",today USING "dd mmm yyyy", 
			" ",time, 
			COLUMN 40, "Delivery No:",pr_reqhead.last_del_no 
			USING "<<<<<<<<" 
			SKIP 1 line 
			
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 02, "Product", 
			COLUMN 17, "Description", 
			COLUMN 48, "Requested", 
			COLUMN 59, "This Issue", 
			COLUMN 71, "Remaining", 
			COLUMN 82, "Warehouse", 
			COLUMN 93, "Bin Location", 
			COLUMN 109,"Delivered", 
			COLUMN 125,"Product" 
			PRINT COLUMN 03, "Code", 
			COLUMN 48, "Quantity", 
			COLUMN 60, "Quantity", 
			COLUMN 71, "Quantity", 
			COLUMN 109,"Quantity", 
			COLUMN 125,"Balance" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		ON EVERY ROW 
			SELECT * 
			INTO pr_product.* 
			FROM product 
			WHERE cmpy_code = pr_reqdetl.cmpy_code 
			AND part_code = pr_reqdetl.part_code 
			IF pr_reqdetl.desc_text IS NULL THEN 
				LET pr_reqdetl.desc_text = pr_product.desc_text 
			END IF 
			SELECT sum(orderdetl.picked_qty) 
			INTO pr_ordpick_qty 
			FROM orderdetl 
			WHERE orderdetl.cmpy_code = pr_reqdetl.cmpy_code 
			AND orderdetl.ware_code = pr_reqhead.ware_code 
			AND orderdetl.part_code = pr_reqdetl.part_code 
			SELECT sum(reqdetl.picked_qty) 
			INTO pr_reqpick_qty 
			FROM reqdetl, 
			reqhead 
			WHERE reqdetl.cmpy_code = pr_reqdetl.cmpy_code 
			AND reqhead.cmpy_code = pr_reqdetl.cmpy_code 
			AND reqhead.ware_code = pr_reqhead.ware_code 
			AND reqdetl.req_num = reqhead.req_num 
			AND reqdetl.part_code = pr_reqdetl.part_code 
			IF pr_reqpick_qty IS NULL THEN 
				LET pr_reqpick_qty = 0 
			END IF 

			IF pr_ordpick_qty IS NULL THEN 
				LET pr_ordpick_qty = 0 
			END IF 

			LET pr_product_bal_qty = pr_prodstatus.onhand_qty 
			- pr_reqpick_qty 
			- pr_ordpick_qty 
			- pr_reqdetl.reserved_qty 
			PRINT COLUMN 01, pr_reqdetl.part_code, 
			COLUMN 17, pr_reqdetl.desc_text[1,30], 
			COLUMN 47, pr_reqdetl.req_qty USING "######&.&&", 
			COLUMN 59, pr_reqdetl.reserved_qty USING "######&.&&", 
			COLUMN 71,(pr_reqdetl.req_qty - pr_reqdetl.confirmed_qty 
			- pr_reqdetl.reserved_qty) 
			USING "######&.&&", 
			COLUMN 84, pr_reqhead.ware_code, 
			COLUMN 93, pr_prodstatus.bin1_text, 
			COLUMN 107,pr_reqdetl.confirmed_qty USING "#######&.&&", 
			COLUMN 120,pr_product_bal_qty USING "##,###,##&.&&" 

			IF pr_product.serial_flag = "Y" THEN 
				FOR i = 1 TO pr_reqdetl.reserved_qty 
					PRINT COLUMN 40, "Serial Number: ",i USING "<<<<", 
					COLUMN 60, "______________________________________" 
				END FOR 
			END IF 

			PAGE TRAILER 
				SKIP 1 LINES 
				PRINT COLUMN 10, "Picked By : __________________", 
				COLUMN 41, "Issue By : ____________________", 
				COLUMN 72, "Receipt Acknowledged By : __________________" 
				SKIP 2 LINES 

		ON LAST ROW 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
END REPORT 
