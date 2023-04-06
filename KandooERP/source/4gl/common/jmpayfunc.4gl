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

	Source code beautified by beautify.pl on 2020-01-02 10:35:16	$Id: $
}



#
# get_paycodes(p_cmpy, p_person_code, p_env_code, p_pay_code, p_rate_code)
#     ask FOR paycodes with defaults FROM person OR FROM jmparms
#
# get_jmpaycodes(p_env_code, p_pay_code, p_rate_code)
#     ask FOR paycodes FOR jmparms
#
# disp_paycodes(p_env_code, p_pay_code, p_rate_code)
#     DISPLAY paycodes
#

GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION get_paycodes(p_cmpy,p_person_code,p_env_code,p_pay_code,p_rate_code) 
	DEFINE p_cmpy LIKE company.cmpy_code
	DEFINE p_person_code LIKE person.person_code 
	DEFINE p_env_code LIKE person.env_code 
	DEFINE p_pay_code LIKE person.pay_code 
	DEFINE p_rate_code LIKE person.rate_code 
	DEFINE l_msgresp LIKE language.yes_flag
	DEFINE l_rec_person RECORD LIKE person.* 
	DEFINE l_rec_jmparms RECORD LIKE jmparms.* 

	OPEN WINDOW j137 with FORM "J137" 
	CALL windecoration_j("J137") 
	IF p_env_code IS NULL OR 
	p_pay_code IS NULL OR 
	p_rate_code IS NULL THEN 
		IF p_person_code IS NOT NULL THEN 
			SELECT * INTO l_rec_person.* 
			FROM person 
			WHERE person.cmpy_code = p_cmpy 
			AND person.person_code = p_person_code 
			IF status = notfound THEN 
				LET l_msgresp = kandoomsg("J", 9532, "") 
				#ERROR " Person NOT found - check using J86"
				EXIT program 
			END IF 
		ELSE 
			INITIALIZE l_rec_person.* TO NULL 
		END IF 
		SELECT jmparms.* INTO l_rec_jmparms.* 
		FROM jmparms 
		WHERE jmparms.cmpy_code = p_cmpy 
		AND jmparms.key_code = "1" 
		IF status = notfound THEN 
			LET l_msgresp = kandoomsg("J", 1501, "") 
			#ERROR " Must SET up JM Parameters first in JZP"
			EXIT program 
		END IF 
		IF p_env_code IS NULL THEN 
			IF l_rec_person.env_code IS NULL THEN 
				LET p_env_code = l_rec_jmparms.env_code 
			ELSE 
				LET p_env_code = l_rec_person.env_code 
			END IF 
		END IF 
		IF p_pay_code IS NULL THEN 
			IF l_rec_person.pay_code IS NULL THEN 
				LET p_pay_code = l_rec_jmparms.pay_code 
			ELSE 
				LET p_pay_code = l_rec_person.pay_code 
			END IF 
		END IF 
		IF p_rate_code IS NULL THEN 
			IF l_rec_person.rate_code IS NULL THEN 
				LET p_rate_code = l_rec_jmparms.rate_code 
			ELSE 
				LET p_rate_code = l_rec_person.rate_code 
			END IF 
		END IF 
	END IF 

	DISPLAY p_env_code, p_pay_code, p_rate_code 
	TO env_code, pay_code, rate_code 


	INPUT p_env_code, p_pay_code, p_rate_code WITHOUT DEFAULTS 
	FROM env_code, pay_code, rate_code 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","jmpayfunc","input-pay-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD env_code 
			IF p_env_code IS NULL THEN 
				LET l_msgresp = kandoomsg("J", 9517, "") 
				#error" Envelope Code must be entered"
				NEXT FIELD env_code 
			END IF 
		AFTER FIELD pay_code 
			IF p_pay_code IS NULL THEN 
				LET l_msgresp = kandoomsg("J", 9518, "") 
				#error" Pay Code must be entered"
				NEXT FIELD pay_code 
			END IF 

	END INPUT 
	CLOSE WINDOW j137 
	RETURN p_env_code, 
	p_pay_code, 
	p_rate_code 
END FUNCTION # get_paycodes 


FUNCTION get_jmpaycodes(p_env_code,p_pay_code,p_rate_code) 
	DEFINE p_env_code LIKE person.env_code 
	DEFINE p_pay_code LIKE person.pay_code 
	DEFINE p_rate_code LIKE person.rate_code
	DEFINE msgresp LIKE language.yes_flag	 

	OPEN WINDOW j137 with FORM "J137" 
	CALL windecoration_j("J137") 
	DISPLAY p_env_code, p_pay_code, p_rate_code 
	TO env_code, pay_code, rate_code 


	INPUT p_env_code, p_pay_code, p_rate_code WITHOUT DEFAULTS 
	FROM env_code, pay_code, rate_code 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","jmpayfunc","input-pay-2") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD env_code 
			IF p_env_code IS NULL THEN 
				LET msgresp = kandoomsg("J", 9517, "") 
				#error" Envelope Code must be entered"
				NEXT FIELD env_code 
			END IF 
		AFTER FIELD pay_code 
			IF p_pay_code IS NULL THEN 
				LET msgresp = kandoomsg("J", 9518, "") 
				#error" Pay Code must be entered"
				NEXT FIELD pay_code 
			END IF 

	END INPUT 
	CLOSE WINDOW j137 
	RETURN p_env_code, 
	p_pay_code, 
	p_rate_code 
END FUNCTION 


FUNCTION disp_paycodes(p_env_code,p_pay_code,p_rate_code) 
	DEFINE p_env_code LIKE person.env_code 
	DEFINE p_pay_code LIKE person.pay_code 
	DEFINE p_rate_code LIKE person.rate_code 

	OPEN WINDOW j137 with FORM "J137" 
	CALL windecoration_j("J137") 
	DISPLAY p_env_code, p_pay_code, p_rate_code 
	TO env_code, pay_code, rate_code 

	#LET msgresp = kandoomsg("U",1,"")
	CALL eventsuspend() 

	#Any Key TO Continue
	CLOSE WINDOW j137 
END FUNCTION # disp_paycodes 


