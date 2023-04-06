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
# \file
# \brief module G32 - % Based recurring journal disbursement processing
#
#  This program uses local version of journal-interface(jourintf) due TO
#  the dubious nature of winds/jourintf since variable locking installed.
#
#  Multi-Currency Note
#  -------------------
#  The source of all disbursement batches created are GL accounts
#  (closing balance OR period movement).  Since all accounthist are
#  in base currency THEN all disbursement journals are in base currency.
#  The only conversion done IS TO convert base TO REPORT currency if
#  required.  The posting interface handles currency conversion TO
#  minimise the scope of any future change TO disburse the movements
#  of accounthistcurr.
#
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS "../gl/G32_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 

############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_rec_period RECORD LIKE period.* 
DEFINE modu_query_text CHAR(600) 

############################################################
# MAIN
#
#
############################################################
MAIN 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFER quit 
	DEFER interrupt 
	CALL setModuleId("G32") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 
	CALL G32_main()
END MAIN