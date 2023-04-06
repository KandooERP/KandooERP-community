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

	Source code beautified by beautify.pl on 2020-01-03 14:28:38	$Id: $
}



#Thsi file IS used as GLOBALS fiel FROM GB1.4gl
#GLOBALS "../common/glob_GLOBALS.4gl"
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl"
GLOBALS 
	DEFINE m1 CHAR(1)
	DEFINE m2 CHAR(1)
	DEFINE m3 CHAR(1)
	DEFINE m4 CHAR(1)
	DEFINE m5 CHAR(1)
	DEFINE m6 CHAR(1)
	DEFINE m7 CHAR(1)	 
	DEFINE m8 CHAR(1)
	DEFINE mb CHAR(1)		
	DEFINE mc CHAR(1)
	DEFINE mf CHAR(1)
	DEFINE ms CHAR(1)
	DEFINE mp CHAR(1)
	DEFINE mx CHAR(1)
	DEFINE glob_level CHAR(1)
	DEFINE msg CHAR(40)
	DEFINE prog CHAR(40)
	DEFINE cmd CHAR(3)
	DEFINE prg_name CHAR(7) 
	DEFINE itis DATE
	DEFINE query_text CHAR(900)
	DEFINE glob_where_part STRING -- CHAR(900)
	DEFINE q1_text CHAR(500) 
	DEFINE msg_ans CHAR(1) 
--	DEFINE print_option CHAR(1) 
	DEFINE comp_on CHAR(30) 
	DEFINE file_name CHAR(30) 
	DEFINE default_file CHAR(30) 
	DEFINE glob_rec_printcodes RECORD LIKE printcodes.* 
END GLOBALS 