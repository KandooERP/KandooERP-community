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

############################################################
# FUNCTION get_ordacct(p_cmpy,p_table_name,p_column_name,p_ref_code,p_ord_ind)
#
#     glordfunc.4gl - get_ordacct
#                   This FUNCTION returns the account code that has been
#                   setup FOR the various ORDER type indicators within
#                   "orderaccounts".  IF the account code cannot be found,
#                   the FUNCTION will RETURN "NULL" AND the calling program
#                   IS TO use the default account code.
#
#                   This FUNCTION can only be used IF the kandoooption "WOTA"
#                   has been activated in U1T.
############################################################
FUNCTION get_ordacct(p_cmpy,p_table_name,p_column_name,p_ref_code,p_ord_ind) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_ref_code LIKE orderaccounts.ref_code 
	DEFINE p_table_name LIKE orderaccounts.table_name 
	DEFINE p_column_name LIKE orderaccounts.column_name 
	DEFINE p_ord_ind LIKE ordhead.ord_ind 
	DEFINE l_acct_code LIKE coa.acct_code 
	DEFINE l_msgresp LIKE language.yes_flag 

	DEFER QUIT 
	DEFER INTERRUPT 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 
	
	IF get_kandoooption_feature_state("WO","TA") = "N" THEN 
		# Option has NOT been activated.
		RETURN NULL 
	END IF 

	IF p_table_name IS NULL THEN 
		ERROR kandoomsg2("U",9930,"Table name IS blank.") 
		RETURN NULL 
	END IF 
	IF p_column_name IS NULL THEN 
		ERROR kandoomsg2("U",9930,"Column name IS blank.") 
		RETURN NULL 
	END IF 
	IF p_ref_code IS NULL THEN 
		ERROR kandoomsg2("U",9930,"Reference code IS blank.") 
		RETURN NULL 
	END IF 
	IF p_ord_ind IS NULL THEN 
		ERROR kandoomsg2("U",9930,"Order type indicator IS blank.") 
		RETURN NULL 
	END IF
	 
	SELECT acct_code INTO l_acct_code FROM orderaccounts 
	WHERE cmpy_code = p_cmpy 
	AND table_name = p_table_name 
	AND column_name = p_column_name 
	AND ref_code = p_ref_code 
	AND ord_ind = p_ord_ind 
	IF status = notfound THEN 
		RETURN NULL 
	END IF 
	
	RETURN l_acct_code 
END FUNCTION 


