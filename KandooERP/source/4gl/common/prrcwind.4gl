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

	Source code beautified by beautify.pl on 2020-01-02 10:35:29	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 


############################################################
# FUNCTION prrcwind(p_cmpy,p_part_code)
#
# DISPLAY product reporting codes
############################################################
FUNCTION prrcwind(p_cmpy,p_part_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_part_code LIKE product.part_code 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_inparms RECORD LIKE inparms.* 
	DEFINE l_rec_userref RECORD LIKE userref.* 
	DEFINE l_msgresp LIKE language.yes_flag 

	CALL db_inparms_get_rec(UI_OFF,"1") RETURNING l_rec_inparms.*
	IF l_rec_inparms.parm_code IS NULL THEN 
		LET l_msgresp = kandoomsg("I",9002,"") 
		RETURN 
	END IF 
	SELECT * 
	INTO l_rec_product.* 
	FROM product 
	WHERE cmpy_code = p_cmpy 
	AND part_code = p_part_code 
	IF status = notfound THEN 
		RETURN 
	END IF 
	IF l_rec_inparms.ref1_text IS NULL AND l_rec_inparms.ref2_text IS NULL 
	AND l_rec_inparms.ref3_text IS NULL AND l_rec_inparms.ref4_text IS NULL 
	AND l_rec_inparms.ref5_text IS NULL AND l_rec_inparms.ref6_text IS NULL 
	AND l_rec_inparms.ref7_text IS NULL AND l_rec_inparms.ref8_text IS NULL THEN 
		LET l_msgresp = kandoomsg("I",9072,"") 
		#9072 Product reporting codes are NOT configured - Refer Menu IZP
		RETURN 
	END IF 

	OPEN WINDOW i611 with FORM "I611" 
	CALL windecoration_i("I611") 

	LET l_rec_inparms.ref1_text = mk_in_prompt(l_rec_inparms.ref1_text) 
	LET l_rec_inparms.ref2_text = mk_in_prompt(l_rec_inparms.ref2_text) 
	LET l_rec_inparms.ref3_text = mk_in_prompt(l_rec_inparms.ref3_text) 
	LET l_rec_inparms.ref4_text = mk_in_prompt(l_rec_inparms.ref4_text) 
	LET l_rec_inparms.ref5_text = mk_in_prompt(l_rec_inparms.ref5_text) 
	LET l_rec_inparms.ref6_text = mk_in_prompt(l_rec_inparms.ref6_text) 
	LET l_rec_inparms.ref7_text = mk_in_prompt(l_rec_inparms.ref7_text) 
	LET l_rec_inparms.ref8_text = mk_in_prompt(l_rec_inparms.ref8_text) 
	DISPLAY BY NAME l_rec_inparms.ref1_text, 
	l_rec_inparms.ref2_text, 
	l_rec_inparms.ref3_text, 
	l_rec_inparms.ref4_text, 
	l_rec_inparms.ref5_text, 
	l_rec_inparms.ref6_text, 
	l_rec_inparms.ref7_text, 
	l_rec_inparms.ref8_text 
	attribute(white) 
	DISPLAY BY NAME l_rec_product.ref1_code, 
	l_rec_product.ref2_code, 
	l_rec_product.ref3_code, 
	l_rec_product.ref4_code, 
	l_rec_product.ref5_code, 
	l_rec_product.ref6_code, 
	l_rec_product.ref7_code, 
	l_rec_product.ref8_code 

	SELECT ref_desc_text INTO l_rec_userref.ref_desc_text FROM userref 
	WHERE cmpy_code = p_cmpy AND source_ind = "I" 
	AND ref_ind = "1" AND ref_code = l_rec_product.ref1_code 
	IF status = 0 THEN 
		DISPLAY l_rec_userref.ref_desc_text 
		TO ref1_desc_text 

	END IF 
	SELECT ref_desc_text INTO l_rec_userref.ref_desc_text FROM userref 
	WHERE cmpy_code = p_cmpy AND source_ind = "I" 
	AND ref_ind = "2" AND ref_code = l_rec_product.ref2_code 
	IF status = 0 THEN 
		DISPLAY l_rec_userref.ref_desc_text 
		TO ref2_desc_text 

	END IF 
	SELECT ref_desc_text INTO l_rec_userref.ref_desc_text FROM userref 
	WHERE cmpy_code = p_cmpy AND source_ind = "I" 
	AND ref_ind = "3" AND ref_code = l_rec_product.ref3_code 
	IF status = 0 THEN 
		DISPLAY l_rec_userref.ref_desc_text 
		TO ref3_desc_text 

	END IF 
	SELECT ref_desc_text INTO l_rec_userref.ref_desc_text FROM userref 
	WHERE cmpy_code = p_cmpy AND source_ind = "I" 
	AND ref_ind = "4" AND ref_code = l_rec_product.ref4_code 
	IF status = 0 THEN 
		DISPLAY l_rec_userref.ref_desc_text 
		TO ref4_desc_text 

	END IF 
	SELECT ref_desc_text INTO l_rec_userref.ref_desc_text FROM userref 
	WHERE cmpy_code = p_cmpy AND source_ind = "I" 
	AND ref_ind = "5" AND ref_code = l_rec_product.ref5_code 
	IF status = 0 THEN 
		DISPLAY l_rec_userref.ref_desc_text 
		TO ref5_desc_text 

	END IF 
	SELECT ref_desc_text INTO l_rec_userref.ref_desc_text FROM userref 
	WHERE cmpy_code = p_cmpy AND source_ind = "I" 
	AND ref_ind = "6" AND ref_code = l_rec_product.ref6_code 
	IF status = 0 THEN 
		DISPLAY l_rec_userref.ref_desc_text 
		TO ref6_desc_text 

	END IF 
	SELECT ref_desc_text INTO l_rec_userref.ref_desc_text FROM userref 
	WHERE cmpy_code = p_cmpy AND source_ind = "I" 
	AND ref_ind = "7" AND ref_code = l_rec_product.ref7_code 
	IF status = 0 THEN 
		DISPLAY l_rec_userref.ref_desc_text 
		TO ref7_desc_text 

	END IF 
	SELECT ref_desc_text INTO l_rec_userref.ref_desc_text FROM userref 
	WHERE cmpy_code = p_cmpy AND source_ind = "I" 
	AND ref_ind = "8" AND ref_code = l_rec_product.ref8_code 
	IF status = 0 THEN 
		DISPLAY l_rec_userref.ref_desc_text 
		TO ref8_desc_text 

	END IF 

	CALL eventsuspend() 
	#LET l_msgresp = kandoomsg("U",1,"")

	CLOSE WINDOW i611 
END FUNCTION 


############################################################
# FUNCTION mk_in_prompt(p_ref_text)
#
#
############################################################
FUNCTION mk_in_prompt(p_ref_text) 
	DEFINE p_ref_text LIKE inparms.ref1_text 
	DEFINE r_temp_text CHAR(40) 

	IF p_ref_text IS NULL THEN 
		LET r_temp_text = NULL 
	ELSE 
		LET r_temp_text = p_ref_text clipped,"...................." 
	END IF 

	RETURN r_temp_text 
END FUNCTION 
