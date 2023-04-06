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
#
#    FUNCTION - calc_freight_charges() - Calculates freight based on  carrier
#                                AND delivery attributes of a sale.
#
#    FUNCTION - calc_hand() - Calculates handling based on product
#                             AND quantities.
#
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

#################################################################################
# FUNCTION calc_freight_charges()
#
#
#################################################################################
FUNCTION calc_freight_charges(p_cmpy,p_carrier_code, ## carrier 
	p_type_ind, ## freight type 
	p_state_code, ## destination state 
	p_country_code, ## destination country 
	p_weight_qty) ## weight OF goods 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_carrier_code LIKE carrier.carrier_code 
	DEFINE p_type_ind LIKE quotehead.freight_ind 
	DEFINE p_state_code LIKE carriercost.state_code
	DEFINE p_country_code LIKE carriercost.country_code
	DEFINE p_weight_qty LIKE product.weight_qty
	DEFINE l_rec_carrier RECORD LIKE carrier.* 
	DEFINE r_freight_amt LIKE quotehead.freight_amt 

	LET r_freight_amt = 0 
	IF p_carrier_code IS NOT NULL THEN 
		SELECT * INTO l_rec_carrier.* 
		FROM carrier 
		WHERE cmpy_code = p_cmpy 
		AND carrier_code = p_carrier_code 

		IF sqlca.sqlcode = 0 THEN 
			SELECT freight_amt INTO r_freight_amt 
			FROM carriercost 
			WHERE cmpy_code = p_cmpy 
			AND carrier_code = l_rec_carrier.carrier_code 
			AND state_code = p_state_code 
			AND country_code = p_country_code 
			AND freight_ind = p_type_ind 

			IF sqlca.sqlcode = notfound THEN 
				SELECT freight_amt INTO r_freight_amt 
				FROM carriercost 
				WHERE cmpy_code = p_cmpy 
				AND carrier_code = l_rec_carrier.carrier_code 
				AND state_code IS NULL 
				AND country_code = p_country_code 
				AND freight_ind = p_type_ind 
			END IF 

			IF sqlca.sqlcode = 0 THEN 
				IF l_rec_carrier.charge_ind = 2 THEN 
					LET r_freight_amt = r_freight_amt * p_weight_qty 
				END IF 
			END IF 
		END IF 
	END IF 

	RETURN r_freight_amt 
END FUNCTION 
#################################################################################
# END FUNCTION calc_freight_charges()
#################################################################################


#################################################################################
# FUNCTION calc_handling_charges(p_cmpy,p_query_text)
#
#
#################################################################################
FUNCTION calc_handling_charges(p_cmpy,p_query_text) 
	DEFINE p_cmpy LIKE company.cmpy_code ## company 
	DEFINE p_query_text CHAR(2200) ## text contains SQL which retreives 
	## product & quantity.
	DEFINE l_part_code LIKE invoicedetl.part_code 
	DEFINE l_ship_qty LIKE invoicedetl.ship_qty 
	DEFINE l_rec_prodsurcharge RECORD LIKE prodsurcharge.* 
	DEFINE l_surchrge_amt LIKE invoicehead.hand_amt 
	DEFINE r_hand_amt LIKE invoicehead.hand_amt

	LET r_hand_amt = 0 

	WHENEVER ERROR GOTO recovery 
	PREPARE s_handling FROM p_query_text 
	DECLARE c_handling CURSOR FOR s_handling 

	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	FOREACH c_handling INTO l_part_code,l_ship_qty 
		IF l_ship_qty IS NOT NULL AND l_part_code IS NOT NULL THEN 
			SELECT * INTO l_rec_prodsurcharge.* FROM prodsurcharge 
			WHERE cmpy_code = p_cmpy 
			AND part_code = l_part_code 

			CASE 
				WHEN status = notfound 
					LET l_surchrge_amt = 0 
				WHEN l_ship_qty >= l_rec_prodsurcharge.low1_qty 
					AND l_ship_qty <= l_rec_prodsurcharge.up1_qty 
					LET l_surchrge_amt = l_rec_prodsurcharge.sur1_amt 
				WHEN l_ship_qty >= l_rec_prodsurcharge.low2_qty 
					AND l_ship_qty <= l_rec_prodsurcharge.up2_qty 
					LET l_surchrge_amt = l_rec_prodsurcharge.sur2_amt 
				WHEN l_ship_qty >= l_rec_prodsurcharge.low3_qty 
					AND l_ship_qty <= l_rec_prodsurcharge.up3_qty 
					LET l_surchrge_amt = l_rec_prodsurcharge.sur3_amt 
				WHEN l_ship_qty >= l_rec_prodsurcharge.low4_qty 
					AND l_ship_qty <= l_rec_prodsurcharge.up4_qty 
					LET l_surchrge_amt = l_rec_prodsurcharge.sur4_amt 
				WHEN l_ship_qty >= l_rec_prodsurcharge.low5_qty 
					AND l_ship_qty <= l_rec_prodsurcharge.up5_qty 
					LET l_surchrge_amt = l_rec_prodsurcharge.sur5_amt 
				WHEN l_ship_qty >= l_rec_prodsurcharge.low6_qty 
					AND l_ship_qty <= l_rec_prodsurcharge.up6_qty 
					LET l_surchrge_amt = l_rec_prodsurcharge.sur6_amt 
				WHEN l_ship_qty >= l_rec_prodsurcharge.low7_qty 
					AND l_ship_qty <= l_rec_prodsurcharge.up7_qty 
					LET l_surchrge_amt = l_rec_prodsurcharge.sur7_amt 
				WHEN l_ship_qty >= l_rec_prodsurcharge.low8_qty 
					AND l_ship_qty <= l_rec_prodsurcharge.up8_qty 
					LET l_surchrge_amt = l_rec_prodsurcharge.sur8_amt 
				OTHERWISE 
					LET l_surchrge_amt = 0 
			END CASE 

			LET r_hand_amt = r_hand_amt + l_surchrge_amt 
		END IF 
	END FOREACH 

	LABEL recovery: 

	RETURN r_hand_amt 
END FUNCTION 
#################################################################################
# END FUNCTION calc_handling_charges(p_cmpy,p_query_text)
#################################################################################