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

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/AS_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/AS6_GLOBALS.4gl" 

##############################################################
# REPORT AS6_rpt_list(p_rpt_idx,p_rec_doc,p_prntco,p_stdate,p_prntdun,p_cmpy_code)
#
#
##############################################################
REPORT AS6_rpt_list(p_rpt_idx,p_rec_doc,p_prntco,p_stdate,p_prntdun,p_cmpy_code) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_rec_doc RECORD 
		d_cust CHAR(8), 
		d_date DATE, 
		d_code CHAR(1), 
		d_ref INTEGER, 
		d_desc CHAR(17), 
		d_amt MONEY(12,2), 
		d_age INTEGER, 
		d_post CHAR(1), 
		d_bal MONEY(12,2) 
	END RECORD
	DEFINE p_prntco CHAR(1)
	DEFINE p_stdate DATE 
	DEFINE p_prntdun CHAR(1)
	DEFINE p_cmpy_code LIKE customer.cmpy_code 
	DEFINE l_rec_customer RECORD LIKE customer.*
 	DEFINE l_rec_stateinfo RECORD LIKE stateinfo.* 
	DEFINE l_save_cust LIKE customer.cust_code 
	DEFINE l_overdue MONEY(12,2)
	DEFINE l_bal_amt MONEY(12,2)
	DEFINE l_neg_amt MONEY(12,2)
	DEFINE l_over_60 MONEY(12,2) 
	DEFINE l_over30_60 MONEY(12,2) 
	DEFINE l_over1_30 MONEY(12,2) 
	DEFINE l_curr MONEY(12,2) 
	DEFINE l_bal MONEY(12,2) 
	DEFINE l_not_first SMALLINT 

	ORDER EXTERNAL BY p_rec_doc.d_cust, p_rec_doc.d_date 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1 --albo
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 CLIPPED #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 CLIPPED #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]
			SKIP 1 LINE 
			SELECT * 
			INTO glob_rec_company.* 
			FROM company 
			WHERE company.cmpy_code = p_cmpy_code 
			IF p_rec_doc.d_cust = l_save_cust 
			THEN 
			ELSE 
				SELECT * 
				INTO l_rec_customer.* 
				FROM customer 
				WHERE customer.cmpy_code = glob_rec_company.cmpy_code 
				AND customer.cust_code = p_rec_doc.d_cust 
				LET l_curr = 0 
				LET l_over_60 = 0 
				LET l_over30_60 = 0 
				LET l_over1_30 = 0 
				LET l_save_cust = p_rec_doc.d_cust 
			END IF 

			IF p_prntco = "Y" 
			THEN 
				PRINT COLUMN 11, glob_rec_company.name_text CLIPPED --, COLUMN 124, "PAGE ", 
				PRINT COLUMN 11, glob_rec_company.addr1_text CLIPPED
				PRINT COLUMN 11, glob_rec_company.addr2_text CLIPPED, 
				", ", glob_rec_company.state_code CLIPPED, 
				", ", glob_rec_company.post_code CLIPPED 

				PRINT COLUMN 52, glob_rec_company.name_text CLIPPED 
				PRINT COLUMN 11, "TELEPHONE ", glob_rec_company.tele_text, 
				COLUMN 52, glob_rec_company.addr1_text CLIPPED
				PRINT COLUMN 52, glob_rec_company.addr2_text CLIPPED, 
				", ", glob_rec_company.state_code CLIPPED, 
				", ", glob_rec_company.post_code CLIPPED 
			END IF 
			PRINT COLUMN 11, l_rec_customer.name_text CLIPPED, 
			COLUMN 96, l_rec_customer.name_text CLIPPED 
			PRINT COLUMN 11, l_rec_customer.addr1_text CLIPPED, 
			COLUMN 96, l_rec_customer.addr1_text CLIPPED
			IF l_rec_customer.addr2_text IS NOT NULL 
			THEN 
				PRINT COLUMN 11, l_rec_customer.addr2_text CLIPPED, 
				COLUMN 52, l_rec_customer.name_text CLIPPED, 
				COLUMN 96, l_rec_customer.addr2_text CLIPPED
				IF l_rec_customer.city_text IS NULL 
				THEN 
					PRINT COLUMN 11, 
					l_rec_customer.state_code CLIPPED, " ", l_rec_customer.post_code CLIPPED, 
					COLUMN 96, 
					l_rec_customer.state_code CLIPPED, " ", l_rec_customer.post_code CLIPPED 
				ELSE 
					PRINT COLUMN 11, l_rec_customer.city_text CLIPPED, 
					", ", l_rec_customer.state_code CLIPPED, " ", l_rec_customer.post_code CLIPPED, 
					COLUMN 96, l_rec_customer.city_text CLIPPED, 
					", ", l_rec_customer.state_code CLIPPED, " ", l_rec_customer.post_code CLIPPED 
				END IF 
			ELSE 
				IF l_rec_customer.city_text IS NULL 
				THEN 
					PRINT COLUMN 11, l_rec_customer.state_code CLIPPED, 
					" ", l_rec_customer.post_code CLIPPED, 
					COLUMN 96, l_rec_customer.state_code CLIPPED, 
					" ", l_rec_customer.post_code CLIPPED
					SKIP 1 LINE 
				ELSE 
					PRINT COLUMN 11, l_rec_customer.city_text CLIPPED, ", ", l_rec_customer.state_code CLIPPED, 
					" ", l_rec_customer.post_code CLIPPED, 
					COLUMN 96, l_rec_customer.city_text CLIPPED, ", ", l_rec_customer.state_code CLIPPED, 
					" ", l_rec_customer.post_code CLIPPED
					SKIP 1 LINE 
				END IF 
			END IF 
			SKIP 2 LINES 
			PRINT COLUMN 24, p_stdate USING "dd mmm yyyy", 
			COLUMN 55, l_rec_customer.cust_code CLIPPED, 
			COLUMN 65, p_stdate       USING "dd/mm/yy", 
			COLUMN 108,p_stdate       USING "dd mmm yyyy" 
			SKIP 2 LINES 

		PAGE TRAILER 
			SKIP 1 LINE 
			LET l_bal = l_over_60 + l_over30_60 + l_over1_30 + l_curr 
			LET l_overdue = l_over_60 + l_over30_60 + l_over1_30 
			PRINT 
			COLUMN 37, l_bal          USING "--------$.&&", 
			COLUMN 69, l_bal          USING "--------$.&&", 
			COLUMN 121,l_bal          USING "--------$.&&" 
			SKIP 1 LINE 
			PRINT 
			COLUMN 02,  "OVER 60 DAYS", 
			COLUMN 15,  "30-60 DAYS ", 
			COLUMN 26,  "1-30 DAYS ", 
			COLUMN 38,  "CURRENT", 
			COLUMN 87,  "OVER 60 DAYS", 
			COLUMN 100, "30-60 DAYS ", 
			COLUMN 111, "1-30 DAYS ", 
			COLUMN 123, "CURRENT" 
			SKIP 1 LINE 
			PRINT 
			COLUMN 01, l_over_60      USING "--------$.&&", 
			COLUMN 14, l_over30_60    USING "-------$.&&", 
			COLUMN 26, l_over1_30     USING "-------$.&&", 
			COLUMN 37, l_curr         USING "--------$.&&", 
			COLUMN 86, l_over_60      USING "--------$.&&", 
			COLUMN 99, l_over30_60    USING "-------$.&&", 
			COLUMN 110,l_over1_30     USING "-------$.&&", 
			COLUMN 121,l_curr         USING "--------$.&&" 

		BEFORE GROUP OF p_rec_doc.d_cust 
			LET l_bal = l_over_60 + l_over30_60 + l_over1_30 + l_curr 
			IF p_prntdun = "Y" 
			AND l_not_first = 1 
			THEN 
				SKIP 2 LINES 
				SELECT * 
				INTO l_rec_stateinfo.* 
				FROM stateinfo 
				WHERE stateinfo.cmpy_code = p_cmpy_code 
				AND stateinfo.dun_code = l_rec_customer.dun_code 
				PRINT COLUMN 23, l_rec_stateinfo.all1_text CLIPPED 
				PRINT COLUMN 23, l_rec_stateinfo.all2_text CLIPPED
				IF l_bal > 0 
				THEN 
					CASE 
						WHEN (l_over_60 > 0) 
							PRINT COLUMN 23, l_rec_stateinfo.over60_1_text CLIPPED 
							PRINT COLUMN 23, l_rec_stateinfo.over60_2_text CLIPPED 
						WHEN (l_over30_60 > 0) 
							PRINT COLUMN 23, l_rec_stateinfo.over30_1_text CLIPPED 
							PRINT COLUMN 23, l_rec_stateinfo.over30_2_text CLIPPED 
						WHEN (l_over1_30 > 0) 
							PRINT COLUMN 23, l_rec_stateinfo.over1_1_text CLIPPED 
							PRINT COLUMN 23, l_rec_stateinfo.over1_2_text CLIPPED 
						WHEN (l_curr > 0) 
							PRINT COLUMN 23, l_rec_stateinfo.cur1_text CLIPPED 
							PRINT COLUMN 23, l_rec_stateinfo.cur2_text CLIPPED 
						OTHERWISE 
							SKIP 2 LINES 
					END CASE 
				ELSE 
					SKIP 2 LINES 
				END IF 
			END IF 
			IF l_not_first = 0 
			THEN 
				LET l_not_first = 1 
			ELSE 
				SKIP TO TOP OF PAGE 
			END IF 
			NEED 7 LINES 

		ON EVERY ROW 
			IF p_rec_doc.d_cust != l_rec_customer.cust_code 
			THEN 
				PRINT COLUMN 1, " " 
				SKIP TO TOP OF PAGE 
			END IF 
			IF p_rec_doc.d_post = "C" THEN 
				LET p_rec_doc.d_desc = p_rec_doc.d_desc CLIPPED, " (Cancelled)" 
			END IF 
			LET l_neg_amt = 0 
			CASE 
				WHEN (p_rec_doc.d_age > 60) 
					LET l_over_60 = l_over_60 + p_rec_doc.d_bal 
				WHEN (p_rec_doc.d_age > 30 AND 
					p_rec_doc.d_age <= 60) 
					LET l_over30_60 = l_over30_60 + p_rec_doc.d_bal 
				WHEN (p_rec_doc.d_age > 1 AND 
					p_rec_doc.d_age <= 30) 
					LET l_over1_30 = l_over1_30 + p_rec_doc.d_bal 
				OTHERWISE 
					LET l_curr = l_curr + p_rec_doc.d_bal 
			END CASE 
			IF p_rec_doc.d_code = "I" 
			THEN 
				LET l_bal_amt = p_rec_doc.d_amt - p_rec_doc.d_bal 
				PRINT 
				COLUMN 02, p_rec_doc.d_date USING "dd/mm/yy", 
				COLUMN 11, p_rec_doc.d_desc CLIPPED, 
				COLUMN 19, p_rec_doc.d_ref  USING "######", 
				COLUMN 26, p_rec_doc.d_amt  USING "-------$.&&", 
				COLUMN 38, l_bal_amt        USING "-------$.&&", 
				COLUMN 55, p_rec_doc.d_desc CLIPPED, 
				COLUMN 63, p_rec_doc.d_ref  USING "######", 
				COLUMN 70, p_rec_doc.d_bal  USING "-------$.&&", 
				COLUMN 87, p_rec_doc.d_date USING "dd/mm/yy", 
				COLUMN 96, p_rec_doc.d_desc CLIPPED, 
				COLUMN 104,p_rec_doc.d_ref  USING "######", 
				COLUMN 110,p_rec_doc.d_amt  USING "-------$.&&", 
				COLUMN 122,l_bal_amt        USING "-------$.&&" 
			ELSE 
				LET l_neg_amt = p_rec_doc.d_bal * -1 
				LET l_bal_amt = p_rec_doc.d_amt + p_rec_doc.d_bal 
				PRINT 
				COLUMN 02, p_rec_doc.d_date USING "dd/mm/yy", 
				COLUMN 11, p_rec_doc.d_desc CLIPPED, 
				COLUMN 19, p_rec_doc.d_ref  USING "######", 
				COLUMN 26, l_bal_amt        USING "-------$.&&", 
				COLUMN 38, p_rec_doc.d_amt  USING "-------$.&&", 
				COLUMN 55, p_rec_doc.d_desc CLIPPED, 
				COLUMN 63, p_rec_doc.d_ref  USING "######", 
				COLUMN 70, l_neg_amt        USING "-------$.&&", 
				COLUMN 87, p_rec_doc.d_date USING "dd/mm/yy", 
				COLUMN 96, p_rec_doc.d_desc CLIPPED, 
				COLUMN 104,p_rec_doc.d_ref  USING "######", 
				COLUMN 110,l_bal_amt        USING "-------$.&&", 
				COLUMN 122,p_rec_doc.d_amt  USING "-------$.&&" 
			END IF 
{ -- (albo) If there is a block 'PAGE TRAILER' then the block 'ON LAST ROW' is not printed at the end of the report !!!??? - it's bug
		ON LAST ROW 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text CLIPPED WORDWRAP RIGHT MARGIN 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report 			
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = PAGENO
}
END REPORT
