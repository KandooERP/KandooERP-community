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

	Source code beautified by beautify.pl on 2020-01-02 10:35:32	$Id: $
}



# roundfunc.4gl - Price Rounding
#
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION rounding(p_round_ind,p_unit_price) 
	DEFINE p_round_ind LIKE location.price_round_ind 
	DEFINE p_unit_price LIKE orderline.unit_price_amt
	DEFINE l_qty DECIMAL(16,4) 
	DEFINE l_qty_dec DECIMAL(16,0) 
	DEFINE l_qty_int INTEGER 
	DEFINE r_return_amt DECIMAL(16,4) 

	CASE (p_round_ind) 
		WHEN "0" 
			#-------------------------------------
			# NEAREST DOLLAR
			#-------------------------------------
			LET l_qty_dec = p_unit_price 
			IF l_qty_dec = 0 THEN 
				LET r_return_amt = p_unit_price 
			ELSE 
				LET r_return_amt = l_qty_dec 
			END IF 
		WHEN "1" 
			#-------------------------------------
			# DOWN TO NEAREST DOLLAR
			#-------------------------------------
			LET l_qty_int = p_unit_price 
			IF l_qty_int = 0 THEN 
				LET r_return_amt = p_unit_price 
			ELSE 
				LET r_return_amt = l_qty_int 
			END IF 
		WHEN "2" 
			#-------------------------------------
			# UP TO NEAREST DOLLAR
			#-------------------------------------
			LET l_qty_int = p_unit_price 
			LET l_qty = p_unit_price - l_qty_int 
			IF l_qty = 0 THEN 
				LET r_return_amt = p_unit_price 
			ELSE 
				LET r_return_amt = l_qty_int + 1 
			END IF 
		WHEN "3" 
			#-------------------------------------
			# NEAREST 5 CENT
			#-------------------------------------
			LET l_qty_int = ((p_unit_price * 100)/5) 
			LET l_qty = ((l_qty_int * 5)/100) 
			IF l_qty = 0 THEN 
				LET r_return_amt = p_unit_price 
			ELSE 
				IF (p_unit_price - l_qty) > 0.025 THEN 
					LET l_qty = l_qty + 0.05 
				END IF 
				IF (p_unit_price - l_qty) = 0 THEN 
					LET r_return_amt = p_unit_price 
				ELSE 
					LET r_return_amt = l_qty 
				END IF 
			END IF 
		WHEN "4" 
			#-------------------------------------
			# DOWN TO 5 CENT
			#-------------------------------------
			LET l_qty_int = ((p_unit_price * 100)/5) 
			LET l_qty = ((l_qty_int * 5)/100) 
			IF l_qty = 0 THEN 
				LET r_return_amt = p_unit_price 
			ELSE 
				IF (p_unit_price - l_qty) = 0 THEN 
					LET r_return_amt = p_unit_price 
				ELSE 
					LET r_return_amt = l_qty 
				END IF 
			END IF 
		WHEN "5" 
			#-------------------------------------
			# UP TO 5 CENT
			#-------------------------------------
			LET l_qty_int = ((p_unit_price * 100)/5) 
			LET l_qty = ((l_qty_int * 5)/100) 
			IF (p_unit_price - l_qty) > 0 THEN 
				LET l_qty = l_qty + 0.05 
			END IF 
			IF (p_unit_price - l_qty) = 0 THEN 
				LET r_return_amt = p_unit_price 
			ELSE 
				LET r_return_amt = l_qty 
			END IF 
		WHEN "6" 
			#-------------------------------------
			# NEAREST CENT
			#-------------------------------------
			LET l_qty_int = p_unit_price * 100 
			LET l_qty = l_qty_int / 100 
			IF l_qty = 0 THEN 
				LET r_return_amt = p_unit_price 
			ELSE 
				IF (p_unit_price - l_qty) > 0.005 THEN 
					LET l_qty = l_qty + 0.01 
				END IF 
				IF (p_unit_price - l_qty) = 0 THEN 
					LET r_return_amt = p_unit_price 
				ELSE 
					LET r_return_amt = l_qty 
				END IF 
			END IF 
		WHEN "7" 
			#-------------------------------------
			# DOWN TO THE NEAREST CENT
			#-------------------------------------
			LET l_qty_int = p_unit_price * 100 
			LET l_qty = l_qty_int / 100 
			IF l_qty = 0 THEN 
				LET r_return_amt = p_unit_price 
			ELSE 
				IF (p_unit_price - l_qty) = 0 THEN 
					LET r_return_amt = p_unit_price 
				ELSE 
					LET r_return_amt = l_qty 
				END IF 
			END IF 
		WHEN "8" 
			#-------------------------------------
			# UP TO THE NEAREST CENT
			#-------------------------------------
			LET l_qty_int = p_unit_price * 100 
			LET l_qty = l_qty_int / 100 
			IF (p_unit_price - l_qty) > 0 THEN 
				LET l_qty = l_qty + 0.01 
			END IF 
			IF (p_unit_price - l_qty) = 0 THEN 
				LET r_return_amt = p_unit_price 
			ELSE 
				LET r_return_amt = l_qty 
			END IF 
		WHEN "9" 
			#-------------------------------------
			# NO ROUNDING
			#-------------------------------------
			LET r_return_amt = p_unit_price 
		OTHERWISE 
			#-------------------------------------
			# MBPARMS HAS BEEN CHANGED
			#-------------------------------------
			LET r_return_amt = p_unit_price 
	END CASE 
	RETURN r_return_amt 
END FUNCTION 

FUNCTION roundit(p_passed_number,p_round_value,p_rule) 
	DEFINE p_passed_number DECIMAL(16,4) 
	DEFINE p_round_value DECIMAL(6,4)
	DEFINE p_rule SMALLINT 
	DEFINE l_int2 INTEGER
	DEFINE l_rnd2 INTEGER
	DEFINE l_rem INTEGER
	DEFINE l_diff INTEGER
	DEFINE l_whole_dec DECIMAL(12) 
	DEFINE l_dec_str CHAR(17) 
	DEFINE r_result DECIMAL(16,4)

	LET l_dec_str = p_passed_number USING "###########&.&&&&" 
	LET l_whole_dec = l_dec_str[1,12] 
	LET l_int2 = l_dec_str[14,17] 
	LET l_rnd2 = p_round_value / .0001 
	LET l_rem = l_int2 mod l_rnd2 
	IF l_rem <> 0 THEN 
		### Find difference between remainder AND round value ###
		LET l_diff = l_rnd2 - l_rem 
		CASE 
			WHEN p_rule = 1 ##### round up 
				LET l_int2 = l_int2 + l_diff 
			WHEN p_rule = 2 ##### round down 
				LET l_int2 = l_int2 - l_rem 
			OTHERWISE ##### round TO nearest 
				IF l_diff > l_rem THEN #### round down 
					LET l_int2 = l_int2 - l_rem 
				ELSE #### round up 
					LET l_int2 = l_int2 + l_diff 
				END IF 
		END CASE 
	END IF 
	LET r_result = (l_int2 * 0.0001) + l_whole_dec 
	RETURN r_result 
END FUNCTION 


