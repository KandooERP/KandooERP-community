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

	Source code beautified by beautify.pl on 2020-01-03 09:12:20	$Id: $
}


{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module I11a.4gl - Product Addition
#    This program allows the user TO enter new inventory products
#
#    Important Note: product.min_month_amt = "Minimum Statistics Amount"
#                    product.min_quart_amt = "Minimum Distribution Amount"
#                    product.min_year_amt = This Column Is Not Used. SP 5/4/94

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 
--GLOBALS "I11_GLOBALS.4gl" 

FUNCTION I11a_whenever_sqlerror ()
    # this code instanciates the default sql errors handling for all the code lines below this function
    # it is a compiler preprocessor instruction. It is not necessary to execute that function
    WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
END FUNCTION

FUNCTION valid_ref(p_ref_num,p_ref_ind,p_ref_code) 
	DEFINE 	p_ref_num LIKE userref.ref_ind
	DEFINE p_ref_ind LIKE arparms.ref1_ind
	DEFINE p_ref_code LIKE product.ref1_code
	DEFINE l_desc_text LIKE userref.ref_desc_text
	DEFINE query_text STRING
	DEFINE l_text CHAR(20)
	DEFINE l_status INTEGER 
	DEFINE msgresp LIKE language.yes_flag 

	# 20201124: why read 9 times a record that has been read at program start???
	# l_text is in fact ref1_text,ref2_text,ref3_text... ref9_text already present in glob_rec_inparms
	# disabled the construct because totally useless, just more useless code
	# very fuzzy logic that needs to be fixed when case is found...

	{
	LET query_text = "SELECT ref",p_ref_num,"_text FROM inparms ", 
	"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND parm_code = \"1\"" 
	PREPARE s_inparms FROM query_text 
	DECLARE c_inparms CURSOR FOR s_inparms 
	OPEN c_inparms 
	FETCH c_inparms INTO l_text 
	}

	SELECT ref_desc_text 
	INTO l_desc_text 
	FROM userref 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND source_ind = "I" 
	AND ref_ind = p_ref_num 
	AND ref_code = p_ref_code 
	
	CASE p_ref_ind 
		WHEN "1" 
			LET l_status = true 
		WHEN "2" 
			IF p_ref_code IS NULL THEN 
				LET msgresp = kandoomsg("I",9065,glob_rec_inparms.ref2_text) 
				#9065" Reference Code #,X,"must be Entered"
				LET l_status = false 
			ELSE 
				LET l_status = true 
			END IF 
		WHEN "3" 
			IF p_ref_code IS NOT NULL 
			AND sqlca.sqlcode = notfound THEN 
				LET msgresp = kandoomsg("I",9066,glob_rec_inparms.ref3_text) 
				#9066" Reference Code #,X," NOT found - Try Window"
				LET l_status = false 
			ELSE 
				LET l_status = true 
			END IF 
		WHEN "4" 
			IF p_ref_code IS NULL THEN 
				LET msgresp = kandoomsg("I",9065,glob_rec_inparms.ref4_text) 
				#9065" Reference Code #,X,"must be Entered"
				LET l_status = false 
			ELSE 
				IF sqlca.sqlcode = notfound THEN 
					LET msgresp = kandoomsg("I",9066,glob_rec_inparms.ref4_text) 
					#9066" Reference Code #,X," NOT found - Try Window"
					LET l_status = false 
				ELSE 
					LET l_status = true 
				END IF 
			END IF 
	END CASE 
	RETURN l_status,l_desc_text 
END FUNCTION 	# valid_ref


FUNCTION make_prompt(pr_ref_text) 
	DEFINE 	pr_temp_text CHAR(40), 
	pr_ref_text LIKE arparms.ref1_text 

	IF pr_ref_text IS NULL THEN 
		LET pr_temp_text = NULL 
	ELSE 
		LET pr_temp_text = pr_ref_text clipped,"...................." 
	END IF 
	RETURN pr_temp_text 
END FUNCTION 

