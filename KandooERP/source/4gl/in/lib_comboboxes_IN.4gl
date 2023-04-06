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

	Source code beautified by beautify.pl on 2020-01-03 09:12:19	$Id: $
}

# This module contains functions that are re used in several modules of the IN BM
# They are more specialized in combobox handling and interaction

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 

# this combo on maingrp is dynamic, is filters on dept_code
FUNCTION dyn_combolist_maingrp (p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null,p_dept_code)
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 
	DEFINE p_dept_code LIKE product.dept_code
	LET l_wherestring = " WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' "
	IF p_dept_code IS NOT NULL THEN
		LET l_wherestring = l_wherestring," AND dept_code MATCHES '",p_dept_code,"' "
	END IF
	CALL comboList_Flex(p_cb_field_name,"maingrp", "maingrp_code", "desc_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 
END FUNCTION # dyn_combolist_maingrp

# this combo on prodgrp is dynamic, is filters on dept_code and maingrp
FUNCTION dyn_combolist_prodgrp (p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null,p_dept_code,p_maingrp_code)
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 
	DEFINE p_dept_code LIKE product.dept_code
	DEFINE p_maingrp_code LIKE prodgrp.maingrp_code
	LET l_wherestring = " WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' "
	IF p_dept_code IS NOT NULL THEN
		LET l_wherestring = l_wherestring," AND dept_code MATCHES '",p_dept_code,"' "
	END IF
    IF p_maingrp_code IS NOT NULL THEN
	    LET l_wherestring = l_wherestring," AND maingrp_code MATCHES '",p_maingrp_code,"' "
	END IF
	CALL comboList_Flex(p_cb_field_name,"prodgrp", "prodgrp_code", "desc_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 
END FUNCTION # dyn_combolist_prodgrp

# this combo on product is dynamic, is filters on dept_code and maingrp
FUNCTION dyn_combolist_product (p_cb_field_name,p_variable,p_sort,p_single,p_hint,p_condition_type,p_add_null,p_dept_code,p_maingrp_code,p_prodgrp_code)
	DEFINE p_cb_field_name VARCHAR(25) --form FIELD 
	DEFINE p_variable SMALLINT -- 0=first FIELD IS variable 1= 2nd FIELD IS variable 
	DEFINE p_sort SMALLINT --0=sort ON FIRST 1=sort ON 2nd 
	DEFINE p_single SMALLINT --0=variable AND LABEL 1= variable = LABEL 
	DEFINE p_hint SMALLINT --1 = SHOW both VALUES in LABEL 
	DEFINE l_wherestring STRING --where 
	DEFINE l_condition_group STRING 
	DEFINE p_condition_type STRING 
	DEFINE p_add_null SMALLINT 
	DEFINE p_dept_code LIKE product.dept_code
	DEFINE p_maingrp_code LIKE product.maingrp_code
	DEFINE p_prodgrp_code LIKE product.prodgrp_code
	LET l_wherestring = " WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' "
	IF p_dept_code IS NOT NULL THEN
		LET l_wherestring = l_wherestring," AND dept_code MATCHES '",p_dept_code,"' "
	END IF
    IF p_maingrp_code IS NOT NULL THEN
	    LET l_wherestring = l_wherestring," AND maingrp_code MATCHES '",p_maingrp_code,"' "
	END IF
    IF p_prodgrp_code IS NOT NULL THEN
	    LET l_wherestring = l_wherestring," AND prodgrp_code MATCHES '",p_prodgrp_code,"' "
	END IF
	CALL comboList_Flex(p_cb_field_name,"product", "part_code", "desc_text", l_wherestring,l_condition_group,p_condition_type,p_variable,p_sort,p_single,p_hint,p_add_null) 
END FUNCTION # dyn_combolist_product
