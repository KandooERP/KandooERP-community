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
# DISPLAY customer reporting codes
GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION cinq_rep_code(p_cmpy,p_cust_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_cust_code LIKE customer.cust_code 
   DEFINE l_msgresp LIKE language.yes_flag
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_arparms RECORD LIKE arparms.* 
	DEFINE l_userref RECORD LIKE userref.* 

	SELECT * 
	INTO l_rec_arparms.* 
	FROM arparms 
	WHERE cmpy_code = p_cmpy 
	AND parm_code = "1" 
	IF STATUS = NOTFOUND THEN 
		ERROR kandoomsg2("A",9002,"") 
		RETURN 
	END IF 
	SELECT * 
	INTO l_rec_customer.* 
	FROM customer 
	WHERE cmpy_code = p_cmpy 
	AND cust_code = p_cust_code 
	IF STATUS = NOTFOUND THEN 
		ERROR kandoomsg2("A",9067,p_cust_code) 	#9067 Customer ??? doesnt exist
		RETURN 
	END IF 
	IF l_rec_arparms.ref1_text IS NULL AND l_rec_arparms.ref2_text IS NULL 
	AND l_rec_arparms.ref3_text IS NULL AND l_rec_arparms.ref4_text IS NULL 
	AND l_rec_arparms.ref5_text IS NULL AND l_rec_arparms.ref6_text IS NULL 
	AND l_rec_arparms.ref7_text IS NULL AND l_rec_arparms.ref8_text IS NULL THEN 
		ERROR kandoomsg2("A",9072,"") 	#9072 Customer reporting codes are NOT configured - Refer Menu AZP
		RETURN 
	END IF 
	OPEN WINDOW A602 with FORM "A602" 
	CALL windecoration_a("A602") -- albo kd-752 

	LET l_rec_arparms.ref1_text = mk_ar_prompt(l_rec_arparms.ref1_text) 
	LET l_rec_arparms.ref2_text = mk_ar_prompt(l_rec_arparms.ref2_text) 
	LET l_rec_arparms.ref3_text = mk_ar_prompt(l_rec_arparms.ref3_text) 
	LET l_rec_arparms.ref4_text = mk_ar_prompt(l_rec_arparms.ref4_text) 
	LET l_rec_arparms.ref5_text = mk_ar_prompt(l_rec_arparms.ref5_text) 
	LET l_rec_arparms.ref6_text = mk_ar_prompt(l_rec_arparms.ref6_text) 
	LET l_rec_arparms.ref7_text = mk_ar_prompt(l_rec_arparms.ref7_text) 
	LET l_rec_arparms.ref8_text = mk_ar_prompt(l_rec_arparms.ref8_text) 
	DISPLAY BY NAME l_rec_arparms.ref1_text, 
	l_rec_arparms.ref2_text, 
	l_rec_arparms.ref3_text, 
	l_rec_arparms.ref4_text, 
	l_rec_arparms.ref5_text, 
	l_rec_arparms.ref6_text, 
	l_rec_arparms.ref7_text, 
	l_rec_arparms.ref8_text 
	ATTRIBUTE(white) 
	DISPLAY BY NAME l_rec_customer.ref1_code, 
	l_rec_customer.ref2_code, 
	l_rec_customer.ref3_code, 
	l_rec_customer.ref4_code, 
	l_rec_customer.ref5_code, 
	l_rec_customer.ref6_code, 
	l_rec_customer.ref7_code, 
	l_rec_customer.ref8_code 

	SELECT ref_desc_text INTO l_userref.ref_desc_text FROM userref 
	WHERE cmpy_code = p_cmpy AND source_ind = "A" 
	AND ref_ind = "1" AND ref_code = l_rec_customer.ref1_code 
	IF STATUS = 0 THEN 
		DISPLAY l_userref.ref_desc_text 
		TO ref1_desc_text 

	END IF 
	SELECT ref_desc_text INTO l_userref.ref_desc_text FROM userref 
	WHERE cmpy_code = p_cmpy AND source_ind = "A" 
	AND ref_ind = "2" AND ref_code = l_rec_customer.ref2_code 
	IF STATUS = 0 THEN 
		DISPLAY l_userref.ref_desc_text 
		TO ref2_desc_text 

	END IF 
	SELECT ref_desc_text INTO l_userref.ref_desc_text FROM userref 
	WHERE cmpy_code = p_cmpy AND source_ind = "A" 
	AND ref_ind = "3" AND ref_code = l_rec_customer.ref3_code 
	IF STATUS = 0 THEN 
		DISPLAY l_userref.ref_desc_text 
		TO ref3_desc_text 

	END IF 
	SELECT ref_desc_text INTO l_userref.ref_desc_text FROM userref 
	WHERE cmpy_code = p_cmpy AND source_ind = "A" 
	AND ref_ind = "4" AND ref_code = l_rec_customer.ref4_code 
	IF STATUS = 0 THEN 
		DISPLAY l_userref.ref_desc_text 
		TO ref4_desc_text 

	END IF 
	SELECT ref_desc_text INTO l_userref.ref_desc_text FROM userref 
	WHERE cmpy_code = p_cmpy AND source_ind = "A" 
	AND ref_ind = "5" AND ref_code = l_rec_customer.ref5_code 
	IF STATUS = 0 THEN 
		DISPLAY l_userref.ref_desc_text 
		TO ref5_desc_text 

	END IF 
	SELECT ref_desc_text INTO l_userref.ref_desc_text FROM userref 
	WHERE cmpy_code = p_cmpy AND source_ind = "A" 
	AND ref_ind = "6" AND ref_code = l_rec_customer.ref6_code 
	IF STATUS = 0 THEN 
		DISPLAY l_userref.ref_desc_text 
		TO ref6_desc_text 

	END IF 
	SELECT ref_desc_text INTO l_userref.ref_desc_text FROM userref 
	WHERE cmpy_code = p_cmpy AND source_ind = "A" 
	AND ref_ind = "7" AND ref_code = l_rec_customer.ref7_code 
	IF STATUS = 0 THEN 
		DISPLAY l_userref.ref_desc_text 
		TO ref7_desc_text 

	END IF 
	SELECT ref_desc_text INTO l_userref.ref_desc_text FROM userref 
	WHERE cmpy_code = p_cmpy AND source_ind = "A" 
	AND ref_ind = "8" AND ref_code = l_rec_customer.ref8_code 
	IF STATUS = 0 THEN 
		DISPLAY l_userref.ref_desc_text 
		TO ref8_desc_text 

	END IF 

	CALL eventsuspend() 
	#ERROR kandoomsg2("U",1,"")

	CLOSE WINDOW A602 
END FUNCTION 


FUNCTION mk_ar_prompt(pr_ref_text) 
	DEFINE 
	pr_temp_text CHAR(40), 
	pr_ref_text LIKE arparms.ref1_text 

	IF pr_ref_text IS NULL THEN 
		LET pr_temp_text = NULL 
	ELSE 
		LET pr_temp_text = pr_ref_text clipped,"...................." 
	END IF 
	RETURN pr_temp_text 
END FUNCTION 


