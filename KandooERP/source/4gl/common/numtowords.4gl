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

	Source code beautified by beautify.pl on 2020-01-02 10:35:19	$Id: $
}



# numtowords.4go:
#
#    Subroutine numto(x, line_width), converts a DECIMAL(11,2) number
#    TO words splits them INTO up TO three lines of line_width chars.
#
#    Returns three string variables, 80 chars, with text centralised
#    according TO line_width, with preceding AND following ***'s
#

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_arr_small_num array[20] OF CHAR(10) 
DEFINE modu_arr_big_num array[9] OF CHAR(10) 
DEFINE modu_amt_text CHAR(200) 
DEFINE modu_line_count SMALLINT 
DEFINE modu_arr_rec_line_text array[3] OF 
RECORD 
	offset SMALLINT, 
	ret_text CHAR(80) 
END RECORD 


############################################################
# FUNCTION numto(p_cheq_amt,p_line_width)
#
#
############################################################
FUNCTION numto(p_cheq_amt,p_line_width) 
	DEFINE p_cheq_amt DECIMAL(11,2) 
	DEFINE p_line_width SMALLINT 
	DEFINE l_cheq_text CHAR(13) 

	LET modu_line_count = 1 
	INITIALIZE modu_arr_rec_line_text[1].* TO NULL 
	INITIALIZE modu_arr_rec_line_text[2].* TO NULL 
	INITIALIZE modu_arr_rec_line_text[3].* TO NULL 
	CALL build_array() 
	LET l_cheq_text = p_cheq_amt USING "#########&.&&" 
	CALL numtowords(l_cheq_text) 
	CALL disp_ans(modu_amt_text,p_line_width) 
	RETURN modu_line_count, 
	modu_arr_rec_line_text[1].offset,modu_arr_rec_line_text[1].ret_text, 
	modu_arr_rec_line_text[2].offset,modu_arr_rec_line_text[2].ret_text, 
	modu_arr_rec_line_text[3].offset,modu_arr_rec_line_text[3].ret_text 
END FUNCTION 



############################################################
# FUNCTION numtowords(p_n_text)
#
#
############################################################
FUNCTION numtowords(p_n_text) 
	DEFINE p_n_text CHAR(13)
	DEFINE l_cents DECIMAL(12,2) 
	DEFINE l_dols DECIMAL(12,2)
 
	LET l_cents = p_n_text[12,13] 
	LET l_dols = p_n_text[1,10] 
	IF l_dols = 0 THEN 
		IF l_cents = 0 THEN 
			LET modu_amt_text = "Zero Dollars Exactly" 
		ELSE 
			LET modu_amt_text = "Zero Dollars AND ",l_cents USING "&&"," l_cents" 
		END IF 
	ELSE 
		IF l_cents = 0 THEN 
			LET modu_amt_text = intowords(l_dols) clipped , " Dollars Exactly" 
		ELSE 
			LET modu_amt_text = intowords(l_dols) clipped , " Dollars AND ", 
			l_cents USING "&&", " l_cents" 
		END IF 
	END IF 
END FUNCTION 


############################################################
# FUNCTION intowords(p_dols)
#
#
############################################################
FUNCTION intowords(p_dols) 
	DEFINE p_dols INTEGER 
	DEFINE l_left_amt INTEGER
	DEFINE r_text CHAR(200) 

	CASE 
		WHEN p_dols >= 1000000 
			# calc p_dols mod(1000000)
			LET l_left_amt = p_dols / 1000000 
			LET l_left_amt = p_dols - l_left_amt * 1000000 
			IF l_left_amt < 100 THEN 
				LET r_text = intowords (p_dols/1000000) clipped , " Million AND ", 
				intowords(l_left_amt) clipped 
			ELSE 
				LET r_text = intowords (p_dols/1000000) clipped , " Million ", 
				intowords(l_left_amt) clipped 
			END IF 
			RETURN r_text 
		WHEN p_dols >= 1000 
			# calc p_dols mod(1000)
			LET l_left_amt = p_dols / 1000 
			LET l_left_amt = p_dols - l_left_amt * 1000 
			IF l_left_amt > 0 AND l_left_amt < 100 THEN 
				LET r_text = intowords (p_dols/1000) clipped , " Thousand AND ", 
				intowords(l_left_amt) clipped 
			ELSE 
				LET r_text = intowords (p_dols/1000) clipped , " Thousand ", 
				intowords(l_left_amt) clipped 
			END IF 
			RETURN r_text 
		WHEN p_dols >= 100 
			# calc p_dols mod(100)
			LET l_left_amt = p_dols / 100 
			LET l_left_amt = p_dols - l_left_amt * 100 
			IF l_left_amt > 0 THEN 
				LET r_text = intowords(p_dols/100) clipped, " Hundred AND ", 
				intowords(l_left_amt) clipped 
			ELSE 
				LET r_text = intowords(p_dols/100) clipped, " Hundred " 
			END IF 
			RETURN r_text 
		WHEN p_dols >= 20 
			# calc p_dols mod(10)
			LET l_left_amt = p_dols / 10 
			LET l_left_amt = p_dols - l_left_amt * 10 
			LET r_text = modu_arr_big_num[p_dols/10] clipped, " ", 
			intowords(l_left_amt) clipped 
			RETURN r_text 
		OTHERWISE 
			LET r_text = modu_arr_small_num[p_dols + 1 ] 
			RETURN r_text 
	END CASE 
END FUNCTION 


############################################################
# FUNCTION build_array()
#
#
############################################################
FUNCTION build_array() 
	LET modu_arr_small_num[1] =" " 
	LET modu_arr_small_num[2] ="One" 
	LET modu_arr_small_num[3] ="Two" 
	LET modu_arr_small_num[4] ="Three" 
	LET modu_arr_small_num[5] ="Four" 
	LET modu_arr_small_num[6] ="Five" 
	LET modu_arr_small_num[7] ="Six" 
	LET modu_arr_small_num[8] ="Seven" 
	LET modu_arr_small_num[9] ="Eight" 
	LET modu_arr_small_num[10] ="Nine" 
	LET modu_arr_small_num[11] ="Ten" 
	LET modu_arr_small_num[12] ="Eleven" 
	LET modu_arr_small_num[13] ="Twelve" 
	LET modu_arr_small_num[14] ="Thirteen" 
	LET modu_arr_small_num[15] ="Fourteen" 
	LET modu_arr_small_num[16] ="Fifteen" 
	LET modu_arr_small_num[17] ="Sixteen" 
	LET modu_arr_small_num[18] ="Seventeen" 
	LET modu_arr_small_num[19] ="Eighteen" 
	LET modu_arr_small_num[20] ="Nineteen" 
	LET modu_arr_big_num[1] = "Ten" 
	LET modu_arr_big_num[2] = "Twenty" 
	LET modu_arr_big_num[3] = "Thirty" 
	LET modu_arr_big_num[4] = "Forty" 
	LET modu_arr_big_num[5] = "Fifty" 
	LET modu_arr_big_num[6] = "Sixty" 
	LET modu_arr_big_num[7] = "Seventy" 
	LET modu_arr_big_num[8] = "Eighty" 
	LET modu_arr_big_num[9] = "Ninety" 
END FUNCTION 



############################################################
# FUNCTION disp_ans(p_ret_text, p_line_width)
#
#
############################################################
FUNCTION disp_ans(p_ret_text,p_line_width) 
	DEFINE p_ret_text CHAR(200) 
	DEFINE p_line_width SMALLINT 
	DEFINE l_offset SMALLINT 
	DEFINE i SMALLINT 

	# split INTO two lines IF line IS longer than 50 chars
	# centre the text
	IF LENGTH(p_ret_text) < (p_line_width - 8) THEN 
		LET p_ret_text = "*** ", p_ret_text clipped, " ***" 
		LET l_offset = (p_line_width - LENGTH(p_ret_text)) /2 
		LET modu_arr_rec_line_text[modu_line_count].ret_text = p_ret_text clipped 
		LET modu_arr_rec_line_text[modu_line_count].offset = l_offset 
	ELSE 
		FOR i = (p_line_width - 8) TO (p_line_width -8 -10) step -1 
			IF p_ret_text[i] = " " THEN 
				EXIT FOR 
			END IF 
		END FOR 
		CALL disp_ans(p_ret_text[1, i - 1], p_line_width) 
		LET modu_line_count = modu_line_count + 1 
		CALL disp_ans(p_ret_text[ i + 1, 200], p_line_width) 
	END IF 
END FUNCTION 


