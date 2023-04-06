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
############################################################
# MODULE Scope Variables
############################################################
	DEFINE modu_rec_accountledger RECORD LIKE accountledger.*
	--DEFINE l_rec_coa RECORD LIKE coa.*
	DEFINE modu_rec_hist_rec RECORD 
		acct_code LIKE accounthist.acct_code, 
		year_num LIKE accounthist.year_num, 
		period_num LIKE accounthist.period_num, 
		open_amt LIKE accounthist.open_amt, 
		close_amt LIKE accounthist.close_amt 
	END RECORD 
	DEFINE modu_open_amt CHAR(20)
	DEFINE modu_close_amt CHAR(20)
	DEFINE modu_first_time SMALLINT
	DEFINE modu_query_text CHAR(1500)
	DEFINE modu_where_part CHAR(1500)
	DEFINE modu_q1_text CHAR(500)
	DEFINE glob_msg_ans CHAR(1) 

############################################################
# MAIN 
#
# GAJ - Account History Journal Report ( based on GAJ )
#         Ordered by Acct. Code, Year / Period, Journal Code, Seq. No.
#         Includes Summary AT END of REPORT showing total DB / CR 's,
#         AND Net Movement by journal code.  Also includes accounts
#         with no movement AND non-zero opening balance.
#
############################################################
MAIN 
	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("GAJ") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 
	CALL GAJ_main()
END MAIN