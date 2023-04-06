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
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS 
--	DEFINE glob_rec_apparms RECORD LIKE apparms.*
END GLOBALS 
############################################################
# MODULE Scope Variables
############################################################
	DEFINE modu_rec_period RECORD LIKE period.*
	DEFINE modu_rec_accounthist RECORD LIKE accounthist.*
--	DEFINE modu_find1 CHAR(1) 
--	DEFINE modu_find2 CHAR(1) 
--	DEFINE modu_find3 CHAR(1) 
--	DEFINE modu_find4 CHAR(1) 
	DEFINE modu_no_data INTEGER 
	DEFINE modu_word CHAR(800) 
	DEFINE modu_x SMALLINT 
	DEFINE modu_y SMALLINT 
	DEFINE modu_msgresp CHAR(1)	 
	DEFINE modu_find_data CHAR(1) 
	DEFINE modu_year_num LIKE period.year_num 
	DEFINE modu_period_num LIKE period.period_num 
	DEFINE modu_acct_code LIKE coa.acct_code 
	DEFINE modu_start_date DATE 
	DEFINE modu_end_date DATE 
	DEFINE modu_report_total SMALLINT 
	DEFINE modu_do_period_total SMALLINT 
	DEFINE modu_totaller1 DECIMAL(16,2) 
	DEFINE modu_totaller2 DECIMAL(16,2) 
	DEFINE modu_totaller3 DECIMAL(16,2) 
--	DEFINE modu_totaller4 DECIMAL(16,2) 

--	DEFINE modu_totaller5 DECIMAL(16,2) 
--	DEFINE modu_totaller6 DECIMAL(16,2) 
--	DEFINE modu_totaller7 DECIMAL(16,2) 
--	DEFINE modu_totaller8 DECIMAL(16,2) 
	DEFINE modu_prob_mess CHAR(30)
#	DEFINE modu_where_part CHAR(800)
#	DEFINE modu_where_part1 CHAR(800)
#	DEFINE modu_where_part2 CHAR(800)
#	DEFINE modu_query_text CHAR(800)
#	DEFINE modu_subsid_query1 CHAR(800) #l_query_text
#	DEFINE modu_subsid_query2 CHAR(800)
#	DEFINE modu_subsid_query3 CHAR(800)
#	DEFINE modu_subsid_query4 CHAR(800)
#	DEFINE modu_query_text2 CHAR(1500)
#	DEFINE modu_query_text3 CHAR(800)
--	DEFINE modu_query_text4 CHAR(500)
	DEFINE modu_rec_hold RECORD 
		year_num LIKE period.year_num, 
		period_num LIKE period.period_num, 
		acct_code LIKE accounthist.acct_code, 
		level_type CHAR(3), 
		invoice_un DECIMAL(16,2), 
		invoice_post DECIMAL(16,2), 
		credit_un DECIMAL(16,2), 
		credit_post DECIMAL(16,2), 
		cash_un DECIMAL(16,2), 
		cash_post DECIMAL(16,2), 
		disc_un DECIMAL(16,2), 
		disc_post DECIMAL(16,2), 
		exp_un DECIMAL(16,2), 
		exp_post DECIMAL(16,2), 
		period_total DECIMAL(16,2) 
	END RECORD
############################################################
# MAIN
#
# GRC  AR Subsidiary TO GL reconciliation REPORT
############################################################
MAIN 
	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("GRC") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 
	CALL GRC_main()
END MAIN