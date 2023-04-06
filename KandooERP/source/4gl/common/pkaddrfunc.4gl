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

	Source code beautified by beautify.pl on 2020-01-02 10:35:23	$Id: $
}



#
# Packs addresses INTO non-NULL lines.  Called by PRINT progs.
#
# FUNCTION "pack_address" packs CUSTOMER, INVOICE, CREDIT AND ORDER addresses
#
# FUNCTION "pack_vend_address" packs VENDOR addresses
#
# FUNCTION "pack_4lines" packs PURCHASE ORDER addresses

FUNCTION pack_address(p_name_text,p_addr1_text,p_addr2_text,p_city_text,p_state_code,p_post_code,p_country_text) 
	DEFINE p_name_text CHAR(40) 
	DEFINE p_addr1_text CHAR(40) 
	DEFINE p_addr2_text CHAR(40) 
	DEFINE p_city_text CHAR(40) 
	DEFINE p_state_code CHAR(10) 
	DEFINE p_post_code CHAR(10) 
	DEFINE p_country_text CHAR(40) 
	DEFINE l_arr_address ARRAY[5] OF CHAR(40) 
	DEFINE x,y SMALLINT 

	LET l_arr_address[1] = p_name_text 
	LET l_arr_address[2] = p_addr1_text 
	LET l_arr_address[3] = p_addr2_text 
	IF p_city_text IS NULL THEN 
		LET l_arr_address[4] = p_state_code CLIPPED," ", 
		p_post_code CLIPPED 
	ELSE 
		LET l_arr_address[4] = p_city_text CLIPPED," ", 
		p_state_code CLIPPED," ", 
		p_post_code CLIPPED 
	END IF 
	LET l_arr_address[5] = p_country_text 
	FOR x = 1 TO 4 
		LET y = 1 
		WHILE length(l_arr_address[x]) = 0 
			LET l_arr_address[x] = l_arr_address[x+y] 
			INITIALIZE l_arr_address[x+y] TO NULL 
			LET y = y+1 
			IF x + y = 6 THEN 
				EXIT WHILE 
			END IF 
		END WHILE 
	END FOR 
	RETURN l_arr_address[1], 
	l_arr_address[2], 
	l_arr_address[3], 
	l_arr_address[4], 
	l_arr_address[5] 
END FUNCTION 


FUNCTION pack_vend_address(p_name_text,p_addr1_text,p_addr2_text,pr_addr3_text,p_city_text,p_state_code,p_post_code,p_country_text) 
	DEFINE 
	p_name_text CHAR(40), 
	p_addr1_text CHAR(40), 
	p_addr2_text CHAR(40), 
	pr_addr3_text CHAR(40), 
	p_city_text CHAR(40), 
	p_state_code CHAR(10), 
	p_post_code CHAR(10), 
	p_country_text CHAR(40), 
	l_arr_address ARRAY[6] OF CHAR(40), 
	x,y SMALLINT 

	LET l_arr_address[1] = p_name_text 
	LET l_arr_address[2] = p_addr1_text 
	LET l_arr_address[3] = p_addr2_text 
	LET l_arr_address[4] = pr_addr3_text 
	IF p_city_text IS NULL THEN 
		LET l_arr_address[5] = p_state_code CLIPPED," ", 
		p_post_code CLIPPED 
	ELSE 
		LET l_arr_address[5] = p_city_text CLIPPED," ", 
		p_state_code CLIPPED," ", 
		p_post_code CLIPPED 
	END IF 
	LET l_arr_address[6] = p_country_text 
	FOR x = 1 TO 5 
		LET y = 1 
		WHILE length(l_arr_address[x]) = 0 
			LET l_arr_address[x] = l_arr_address[x+y] 
			INITIALIZE l_arr_address[x+y] TO NULL 
			LET y = y+1 
			IF x + y = 7 THEN 
				EXIT WHILE 
			END IF 
		END WHILE 
	END FOR 
	RETURN l_arr_address[1], 
	l_arr_address[2], 
	l_arr_address[3], 
	l_arr_address[4], 
	l_arr_address[5], 
	l_arr_address[6] 
END FUNCTION 


FUNCTION pack_4lines(p_name_text,p_addr1_text,p_addr2_text,pr_addr3_text,pr_addr4_text,p_country_text) 
	DEFINE 
	p_name_text CHAR(40), 
	p_addr1_text CHAR(40), 
	p_addr2_text CHAR(40), 
	pr_addr3_text CHAR(40), 
	pr_addr4_text CHAR(40), 
	p_country_text CHAR(40), 
	l_arr_address ARRAY[6] OF CHAR(40), 
	x,y SMALLINT 

	LET l_arr_address[1] = p_name_text 
	LET l_arr_address[2] = p_addr1_text 
	LET l_arr_address[3] = p_addr2_text 
	LET l_arr_address[4] = pr_addr3_text 
	LET l_arr_address[5] = pr_addr4_text 
	LET l_arr_address[6] = p_country_text 
	FOR x = 1 TO 5 
		LET y = 1 
		WHILE length(l_arr_address[x]) = 0 
			LET l_arr_address[x] = l_arr_address[x+y] 
			INITIALIZE l_arr_address[x+y] TO NULL 
			LET y = y + 1 
			IF x + y = 7 THEN 
				EXIT WHILE 
			END IF 
		END WHILE 
	END FOR 
	RETURN l_arr_address[1], 
	l_arr_address[2], 
	l_arr_address[3], 
	l_arr_address[4], 
	l_arr_address[5], 
	l_arr_address[6] 
END FUNCTION 


