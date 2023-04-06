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
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../eo/E_EO_GLOBALS.4gl"
GLOBALS "../eo/E5_GROUP_GLOBALS.4gl"
GLOBALS "../eo/E52_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################
# E54a - Prepare AND PRINT consignment note(s) FOR required FORMAT
###########################################################################
# FUNCTION generate_connote(
#	p_cmpy,
#	p_kandoouser_sign_on_code,
#	p_where_text, 
#	p_rec_despatchhead, 
#	p_next_consign, 
#	p_upd_car_ind, 
#	p_verbose_ind) 
###########################################################################
FUNCTION generate_connote(
	p_cmpy,
	p_kandoouser_sign_on_code,
	p_where_text, 
	p_rec_despatchhead, 
	p_next_consign, 
	p_upd_car_ind, 
	p_verbose_ind) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE p_where_text STRING #char(200) 
	DEFINE p_rec_despatchhead RECORD LIKE despatchhead.* 
	DEFINE p_next_consign LIKE carrier.next_consign
	DEFINE p_upd_car_ind SMALLINT 
	DEFINE p_verbose_ind SMALLINT 

	DEFINE l_query_text STRING #char(500) 
--	DEFINE glob_rec_opparms RECORD LIKE opparms.* 
	DEFINE l_rec_carrier RECORD LIKE carrier.* 
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_rec_pickhead RECORD LIKE pickhead.* 
	DEFINE l_rec_despatchdetl RECORD LIKE despatchdetl.* 
	DEFINE l_rec_despatchline RECORD 
		invoice_num LIKE despatchdetl.invoice_num, 
		nett_wgt_qty LIKE despatchdetl.nett_wgt_qty, 
		nett_cubic_qty LIKE despatchdetl.nett_cubic_qty, 
		despatch_qty LIKE despatchdetl.despatch_qty 
	END RECORD 

	DEFINE l_detail_ind SMALLINT 
 
	DEFINE l_despatch_qty INTEGER 
--	DEFINE l_msg_time LIKE delivmsg.msg_time 
--	DEFINE l_msg_event_text LIKE delivmsg.event_text 
	DEFINE l_msg_num LIKE delivmsg.msg_num 
	DEFINE l_msg_text LIKE delivmsg.msg_text 
	
	###-Dangerous goods variables
	DEFINE l_rec_tmp_carry RECORD 
		main_dg_code LIKE proddanger.dg_code, 
		carry_dg_code LIKE proddanger.dg_code 
	END RECORD 
	DEFINE l_counter SMALLINT 
	DEFINE i SMALLINT 
	DEFINE j SMALLINT 
	DEFINE k SMALLINT 
	DEFINE l SMALLINT 
	DEFINE m SMALLINT 	
	DEFINE l_arr_rec_carry DYNAMIC ARRAY OF RECORD 
		main_dg_code LIKE proddanger.dg_code, 
		carry_dg_code LIKE proddanger.dg_code, 
		delete_flag char(1) 
	END RECORD 
	DEFINE l_dg_code LIKE proddanger.dg_code 
	DEFINE l_dg_code2 LIKE proddanger.dg_code 
	DEFINE l_next_dg_code LIKE proddanger.dg_code 
	DEFINE l_main_dg_code LIKE proddanger.dg_code 
	DEFINE l_nett_wgt_qty LIKE despatchdetl.nett_wgt_qty 
	DEFINE l_nett_cubic_qty LIKE despatchdetl.nett_cubic_qty 
	DEFINE l_rec_dangerline RECORD LIKE dangerline.* 
	DEFINE l_rec_proddanger RECORD LIKE proddanger.* 

	IF p_where_text IS NULL THEN 
		RETURN FALSE 
	END IF 
	
	GOTO bypass 
	LABEL recovery: 
	ROLLBACK WORK 
	CALL error_mess(p_cmpy,p_rec_despatchhead.ware_code,l_msg_num,l_msg_text, p_verbose_ind) 
	RETURN FALSE 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	BEGIN WORK 
		DECLARE c_carrier cursor FOR 
		SELECT * FROM carrier 
		WHERE cmpy_code = p_cmpy 
		AND carrier_code = p_rec_despatchhead.carrier_code 
		FOR UPDATE 
		OPEN c_carrier 
		FETCH c_carrier INTO l_rec_carrier.* 
		IF p_next_consign IS NOT NULL THEN 
			LET l_rec_carrier.next_consign = p_next_consign 
		END IF 
		LET p_rec_despatchhead.manifest_num = l_rec_carrier.next_manifest 
		LET l_query_text = 
		"SELECT * FROM pickhead ", 
		"WHERE cmpy_code = '",p_cmpy,"' ", 
		"AND con_status_ind = '0' ", 
		"AND status_ind <> '9' ", 
		"AND carrier_code = '",p_rec_despatchhead.carrier_code,"' ", 
		"AND ",p_where_text clipped," ", 
		"ORDER BY pick_date,", 
		"ware_code,", 
		"pick_num" 
		PREPARE s_pickhead FROM l_query_text 
		DECLARE c_pickhead cursor FOR s_pickhead 

		LET l_query_text = " SELECT * FROM pickhead ", 
		" WHERE cmpy_code = '",p_cmpy,"' ", 
		" AND pick_num = ? ", 
		" AND carrier_code = '", 
		p_rec_despatchhead.carrier_code,"' ", 
		" AND con_status_ind <> '9' ", 
		" FOR update" 
		PREPARE s2_pickhead FROM l_query_text 
		DECLARE c2_pickhead cursor FOR s2_pickhead 

		LET l_detail_ind = FALSE 
		FOREACH c_pickhead INTO l_rec_pickhead.* 
			#############################################################
			###- Procedure TO process dangerous goods onto connotes  -###
			###- Aims TO: Optimise the number of dangerous goods     -###
			###-   travelling together, that do NOT have carrying    -###
			###-   restrictions, AND minimise the number of connotes -###
			###-   being used TO transport the dangerous goods.      -###
			#############################################################
			###- * IF the current invoice has products with danger-  -###
			###-   ous goods THEN perform steps below:               -###
			###- 1 Insert INTO tmp_danger the dg_codes AND there sums-###
			###-   FOR processing later;                             -###
			###- 2 Fill the tmp_carry table with all possible        -###
			###-   combinations of carrying relationships that are   -###
			###-   feasible; verify through carry_dangercode FUNCTION-###
			###- 3 Copy tmp_carry TO ARRAY FOR elimination of        -###
			###-   redundant carry relationships;                    -###
			###- 4 Copy ARRAY TO tmp_carry FOR final processing;     -###
			###-   the tmp_carry will represent the valid carrying   -###
			###-   relationships TO be used in connote processing    -###
			###- 5 FOREACH tmp_carry RECORD add a dangerline RECORD  -###
			###-   AND FOREACH change in tmp_carry main dg code add  -###
			###-   a despatchdetl(connote)                           -###
			###- 6 Complete processing by inserting the despatchhead -###
			###-   AND updating the invoicehead WHERE appropriate    -###
			#############################################################
			###- 1 Insert INTO tmp_danger the dg_codes AND there sums-###
			###-   FOR processing later;                             -###
			SELECT unique 1 FROM product 
			WHERE cmpy_code = p_cmpy 
			AND dg_code IS NOT NULL 
			AND part_code in 
				(select part_code FROM pickdetl 
				WHERE cmpy_code = p_cmpy 
				AND pick_num = l_rec_pickhead.pick_num) 
			
			IF status <> NOTFOUND THEN 
				###-Process all dangerous goods
				###-Clear the temporary tables before processing
				DELETE FROM tmp_danger WHERE 1=1 
				DELETE FROM tmp_carry WHERE 1=1 
				
				###-INITIALIZE the carry_dg_code array
				FOR i=1 TO 100 
					INITIALIZE l_arr_rec_carry[i].* TO NULL 
				END FOR 
				
				###-Collect the summed quantity FOR each danger code
				INSERT INTO tmp_danger 
				SELECT pr.dg_code, 
				sum(pr.weight_qty*pd.picked_qty), 
				sum(pr.cubic_qty*pd.picked_qty), 
				sum(pd.picked_qty) 
				FROM pickdetl pd, product pr 
				WHERE pd.cmpy_code = p_cmpy 
				AND pr.cmpy_code = p_cmpy 
				AND pd.pick_num = l_rec_pickhead.pick_num 
				AND pd.part_code = pr.part_code 
				AND pd.ware_code = p_rec_despatchhead.ware_code 
				GROUP BY pr.dg_code 
				
				###- 2 Fill the tmp_carry table with all possible        -###
				###-   combinations of carrying relationships that are   -###
				DECLARE c_tmpdanger cursor FOR 
				SELECT dg_code FROM tmp_danger 
				ORDER BY dg_code 
				DECLARE c_tmpdanger2 cursor FOR 
				SELECT dg_code FROM tmp_danger 
				ORDER BY dg_code 
				
				FOREACH c_tmpdanger INTO l_dg_code 
					FOREACH c_tmpdanger2 INTO l_dg_code2 
						IF ((l_dg_code IS null) AND (l_dg_code2 IS null)) OR 
						(l_dg_code = l_dg_code2) 
						THEN 
							INSERT INTO tmp_carry VALUES (l_dg_code,l_dg_code2) 
						ELSE 
							###-INSERT the carrying relationship IF ok
							IF carry_dangercodes(l_dg_code,l_dg_code2,p_cmpy) THEN 
								INSERT INTO tmp_carry VALUES (l_dg_code,l_dg_code2) 
							END IF 
						END IF 
					END FOREACH 
				END FOREACH
				 
				###- 3 Copy tmp_carry TO ARRAY FOR elimination of        -###
				###-   redundant carry relationships;                    -###
				###-eliminate WHERE the main dg code IS NULL
				DELETE FROM tmp_carry WHERE main_dg_code IS NULL 
				###- SELECT the danger code with the most combinations
				###-  ie: the danger code that can be carried with the
				###-      most alternate danger codes
				###- Use this main_dg_code TO eliminate the other carry
				###- rows that are already accounted FOR
				DECLARE c_carry cursor FOR 
				SELECT main_dg_code, count(*) 
				FROM tmp_carry 
				WHERE main_dg_code IS NOT NULL 
				GROUP BY main_dg_code 
				ORDER BY 2 desc,1 
				OPEN c_carry 
				FETCH c_carry INTO l_main_dg_code, l_counter 
				CLOSE c_carry 
				DECLARE c_carry2 cursor FOR 
				SELECT * FROM tmp_carry 
				LET i=0 

				INITIALIZE l_dg_code,l_dg_code2 TO NULL 

				FOREACH c_carry2 INTO l_dg_code, l_dg_code2 
					LET i=i+1 
					LET l_arr_rec_carry[i].main_dg_code = l_dg_code 
					LET l_arr_rec_carry[i].carry_dg_code= l_dg_code2 
					LET l_arr_rec_carry[i].delete_flag = "N" 
				END FOREACH 

				###- Eliminate the ARRAY rows WHERE the carry
				###- relationship IS already SET AND feasible
				###- Using ARRAY because cannot dynamically DELETE FROM
				###- the temporary table AND have a CURSOR only see the
				###- undeleted rows
				FOR j = 1 TO i 
					IF l_arr_rec_carry[j].delete_flag = "N" THEN 
						IF (l_arr_rec_carry[j].main_dg_code = l_main_dg_code) THEN 
							IF (l_arr_rec_carry[j].carry_dg_code<>l_main_dg_code) AND 
							(l_arr_rec_carry[j].carry_dg_code IS NOT null) 
							THEN 

								FOR k=1 TO i 
									IF l_arr_rec_carry[k].delete_flag = "N" THEN 
										IF (l_arr_rec_carry[k].main_dg_code = 
										l_arr_rec_carry[j].carry_dg_code) 
										THEN 
											LET l_arr_rec_carry[k].delete_flag = "Y" 
										END IF 
									END IF 
								END FOR 

							END IF 
						ELSE 
							IF l_arr_rec_carry[j].carry_dg_code IS NULL THEN 
								LET l_arr_rec_carry[j].delete_flag = "Y" 
							ELSE 
								IF l_arr_rec_carry[j].main_dg_code<> 
								l_arr_rec_carry[j].carry_dg_code THEN 

									FOR l=1 TO i 
										IF l_arr_rec_carry[l].delete_flag = "N" THEN 
											IF (l_arr_rec_carry[l].main_dg_code=l_main_dg_code) AND 
											(l_arr_rec_carry[l].carry_dg_code= 
											l_arr_rec_carry[j].carry_dg_code) 
											THEN 
												LET l_arr_rec_carry[j].delete_flag = "Y" 
												EXIT FOR 
											END IF 
										END IF 
									END FOR 

								END IF 
							END IF 
						END IF 
					END IF 
				END FOR 

				###- 4 Copy ARRAY TO tmp_carry FOR final processing;     -###
				###-   the tmp_carry will represent the valid carrying   -###
				###-   relationships TO be used in connote processing    -###
				DELETE FROM tmp_carry WHERE 1=1 
				FOR m=1 TO i 
					IF l_arr_rec_carry[m].delete_flag="N" THEN 
						INSERT INTO tmp_carry VALUES (l_arr_rec_carry[m].main_dg_code, 
						l_arr_rec_carry[m].carry_dg_code) 
					END IF 
				END FOR 

				###- 5 FOREACH tmp_carry RECORD add a dangerline RECORD  -###
				###-   AND FOREACH change in tmp_carry main dg code add  -###
				###-   a despatchdetl(connote)                           -###
				DECLARE c_carry4 cursor FOR 
				SELECT * FROM tmp_carry 
				ORDER BY main_dg_code 
				LET l_next_dg_code = "ZZZ" ###-because there can be NULL dg_code 

				FOREACH c_carry4 INTO l_rec_tmp_carry.* 

					###-Sum the travelling danger codes together FOR the despatchdetl
					IF l_next_dg_code != l_rec_tmp_carry.main_dg_code THEN 
						LET l_next_dg_code = l_rec_tmp_carry.main_dg_code 

						###-After the first despatchdetl INSERT allow the option TO
						###-get the next consignment number FROM the carrier
						IF p_upd_car_ind THEN 
							CALL add_consign_note(l_rec_carrier.next_consign)	RETURNING l_rec_carrier.next_consign 
							LET l_msg_num = 7066 
							LET l_msg_text = l_rec_carrier.carrier_code 

							UPDATE carrier 
							SET next_consign = l_rec_carrier.next_consign 
							WHERE cmpy_code = p_cmpy 
							AND carrier_code = l_rec_carrier.carrier_code 
						END IF 

						LET l_msg_num = 7067 
						LET l_msg_text = l_rec_pickhead.pick_num 
	
						UPDATE pickdetl 
						SET despatch_code = l_rec_carrier.next_consign 
						WHERE cmpy_code = p_cmpy 
						AND pick_num = l_rec_pickhead.pick_num 
	
						LET l_rec_despatchdetl.invoice_num = NULL 
						LET l_rec_despatchdetl.pick_num = l_rec_pickhead.pick_num 
						IF l_rec_pickhead.status_ind = 1 THEN 
							UPDATE invoicehead 
							SET manifest_num = l_rec_carrier.next_manifest 
							WHERE cmpy_code = p_cmpy 
							AND inv_num = l_rec_pickhead.inv_num 
							LET l_rec_despatchdetl.invoice_num = l_rec_pickhead.inv_num 
						END IF 
						LET l_nett_wgt_qty = 0 
						LET l_nett_cubic_qty = 0 
						LET l_despatch_qty = 0 
	
						SELECT sum(nett_wgt_qty), 
						sum(nett_cubic_qty), 
						sum(despatch_qty) 
						INTO l_nett_wgt_qty, 
						l_nett_cubic_qty, 
						l_despatch_qty 
						FROM tmp_danger 
						WHERE dg_code in 
						(select carry_dg_code 
						FROM tmp_carry 
						WHERE main_dg_code = l_rec_tmp_carry.main_dg_code) 

						###-Insert INTO despatchdetl the grouped dangerous goods codes
						CASE glob_rec_opparms.ship_label_ind 
							WHEN "1" 
								LET l_despatch_qty = (l_nett_wgt_qty / 
								glob_rec_opparms.ship_label_qty) + 1 
							WHEN "2" 
								LET l_despatch_qty = (l_nett_cubic_qty / 
								glob_rec_opparms.ship_label_qty) + 1 
							WHEN "3" 
								LET l_despatch_qty = (l_despatch_qty / 
								glob_rec_opparms.ship_label_qty) + 1 
							WHEN "4" 
								LET l_despatch_qty = glob_rec_opparms.ship_label_qty 
						END CASE 
						LET l_msg_num = 7065 
						LET l_msg_text = l_rec_carrier.next_consign 
						
						INSERT INTO despatchdetl VALUES (p_cmpy, 
						p_rec_despatchhead.carrier_code, 
						l_rec_carrier.next_consign, 
						l_rec_carrier.next_manifest, 
						l_rec_pickhead.inv_num, 
						l_nett_wgt_qty, 
						l_nett_wgt_qty, 
						l_nett_cubic_qty, 
						l_nett_cubic_qty, 
						l_despatch_qty, 
						l_rec_pickhead.pick_num) 
						LET l_detail_ind = TRUE ###-allow UPDATE ON completion 
					END IF 

					###-Now INSERT the danger lines related TO the despatchdetl
					INITIALIZE l_rec_dangerline.* TO NULL 

					SELECT dg_code, nett_wgt_qty, despatch_qty 
					INTO l_rec_dangerline.dg_code, 
					l_rec_dangerline.nett_wgt_qty, 
					l_rec_dangerline.despatch_qty 
					FROM tmp_danger 
					WHERE dg_code = l_rec_tmp_carry.carry_dg_code 
					AND dg_code IS NOT NULL 
					IF status <> NOTFOUND THEN 
						CASE glob_rec_opparms.ship_label_ind 
							WHEN "1" 
								LET l_rec_dangerline.despatch_qty = 
								(l_rec_dangerline.nett_wgt_qty / 
								glob_rec_opparms.ship_label_qty) + 1 
							WHEN "2" 
								LET l_rec_dangerline.despatch_qty = 
								(l_rec_dangerline.nett_wgt_qty / 
								glob_rec_opparms.ship_label_qty) + 1 
							WHEN "3" 
								LET l_rec_dangerline.despatch_qty = 
								(l_rec_dangerline.despatch_qty / 
								glob_rec_opparms.ship_label_qty) + 1 
							WHEN "4" 
								LET l_rec_dangerline.despatch_qty = 
								glob_rec_opparms.ship_label_qty 
						END CASE 
						
						###-Collect the Danger Product details
						SELECT * INTO l_rec_proddanger.* 
						FROM proddanger 
						WHERE cmpy_code = p_cmpy 
						AND dg_code = l_rec_dangerline.dg_code 
						###-Insert INTO dangerline
						INSERT INTO dangerline VALUES (p_cmpy, 
						p_rec_despatchhead.carrier_code, 
						l_rec_carrier.next_consign, 
						l_rec_carrier.next_manifest, 
						l_rec_dangerline.dg_code, 
						l_rec_dangerline.nett_wgt_qty, 
						l_rec_dangerline.despatch_qty, 
						l_rec_proddanger.pkg_code) 
					END IF 
				END FOREACH
				 
			ELSE ###-no dangerous goods-###
 
				SELECT pd.pick_num, sum(pr.weight_qty*pd.picked_qty), 
				sum(pr.cubic_qty*pd.picked_qty), 
				sum(pd.picked_qty) 
				INTO l_rec_despatchline.* 
				FROM pickdetl pd, product pr 
				WHERE pd.cmpy_code = p_cmpy 
				AND pr.cmpy_code = p_cmpy 
				AND pd.pick_num = l_rec_pickhead.pick_num 
				AND pd.part_code = pr.part_code 
				AND pd.ware_code = p_rec_despatchhead.ware_code 
				GROUP BY pd.pick_num 
				IF sqlca.sqlcode = 0 THEN 
					LET l_detail_ind = TRUE 
					CASE glob_rec_opparms.ship_label_ind 
						WHEN "1" 
							LET l_despatch_qty = (l_rec_despatchline.nett_wgt_qty / glob_rec_opparms.ship_label_qty) + 1 
							LET l_rec_despatchline.despatch_qty = l_despatch_qty 
						WHEN "2" 
							LET l_despatch_qty = (l_rec_despatchline.nett_cubic_qty / glob_rec_opparms.ship_label_qty) + 1 
							LET l_rec_despatchline.despatch_qty = l_despatch_qty 
						WHEN "3" 
							LET l_despatch_qty = (l_rec_despatchline.despatch_qty / glob_rec_opparms.ship_label_qty) + 1 
							LET l_rec_despatchline.despatch_qty = l_despatch_qty 
						WHEN "4" 
							LET l_rec_despatchline.despatch_qty = glob_rec_opparms.ship_label_qty 
					END CASE 
					
					LET l_msg_num = 7065 
					LET l_msg_text = l_rec_carrier.next_consign 
					INSERT INTO despatchdetl VALUES (p_cmpy, 
					p_rec_despatchhead.carrier_code, 
					l_rec_carrier.next_consign, 
					l_rec_carrier.next_manifest, 
					l_rec_pickhead.inv_num, 
					l_rec_despatchline.nett_wgt_qty, 
					l_rec_despatchline.nett_wgt_qty, 
					l_rec_despatchline.nett_cubic_qty, 
					l_rec_despatchline.nett_cubic_qty, 
					l_rec_despatchline.despatch_qty, 
					l_rec_pickhead.pick_num) 
					IF p_upd_car_ind THEN 
						CALL add_consign_note(l_rec_carrier.next_consign) 
						RETURNING l_rec_carrier.next_consign 
						LET l_msg_num = 7066 
						LET l_msg_text = l_rec_carrier.carrier_code 
						UPDATE carrier 
						SET next_consign = l_rec_carrier.next_consign 
						WHERE cmpy_code = p_cmpy 
						AND carrier_code = l_rec_carrier.carrier_code 
					END IF 
					LET l_msg_num = 7067 
					LET l_msg_text = l_rec_despatchline.invoice_num 
					IF l_rec_pickhead.status_ind = "1" THEN 
						UPDATE invoicehead 
						SET manifest_num = l_rec_carrier.next_manifest 
						WHERE cmpy_code = p_cmpy 
						AND inv_num = l_rec_pickhead.inv_num 
					END IF 
				END IF 
			END IF 
			OPEN c2_pickhead USING l_rec_pickhead.pick_num 
			FETCH c2_pickhead 
			IF status = NOTFOUND THEN 
				LET l_msg_num = 7094 
				LET l_msg_text = l_rec_carrier.next_consign 
				GOTO recovery 
			END IF 
			UPDATE pickhead SET con_status_ind = "1" 
			WHERE cmpy_code = p_cmpy 
			AND pick_num = l_rec_pickhead.pick_num 
			AND carrier_code = l_rec_pickhead.carrier_code 
			CLOSE c2_pickhead 
		END FOREACH 
		###- 6 Complete processing by inserting the despatchhead -###
		###-   AND updating the invoicehead WHERE appropriate    -###
		IF l_detail_ind THEN 
			LET l_msg_num = 7068 
			LET l_msg_text = p_rec_despatchhead.manifest_num
			 
			INSERT INTO despatchhead VALUES (p_rec_despatchhead.*) 
			LET l_msg_num = 7066 
			LET l_msg_text = l_rec_carrier.carrier_code 
			UPDATE carrier 
			SET next_manifest = next_manifest + 1 
			WHERE cmpy_code = p_cmpy 
			AND carrier_code = l_rec_carrier.carrier_code 
		END IF
		 
	COMMIT WORK 
	WHENEVER ERROR stop
	 
	RETURN TRUE 
END FUNCTION 
###########################################################################
# END FUNCTION generate_connote(
###########################################################################


###########################################################################
# FUNCTION carry_dangercodes(p_dg_code,p_dg_code2,p_cmpy)
# 
# Carry Danger Code - verify the travelling relationship between danger codes 
###########################################################################
FUNCTION carry_dangercodes(p_dg_code,p_dg_code2,p_cmpy) 
	DEFINE p_dg_code LIKE product.dg_code 
	DEFINE p_dg_code2 LIKE product.dg_code 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE l_counter SMALLINT 
	DEFINE l_rec_proddanger RECORD LIKE proddanger.*  
	DEFINE l_rec_proddanger2 RECORD LIKE proddanger.*  
	DEFINE l_rec_proddanger3 RECORD LIKE proddanger.* 
	DEFINE l_rec_tmp_carry RECORD 
		main_dg_code LIKE proddanger.dg_code, 
		carry_dg_code LIKE proddanger.dg_code 
	END RECORD 

	###-collect the danger code class AND carry details
	IF p_dg_code IS NOT NULL THEN 
		SELECT * INTO l_rec_proddanger.* 
		FROM proddanger 
		WHERE cmpy_code = p_cmpy 
		AND dg_code = p_dg_code 
	ELSE 
		INITIALIZE l_rec_proddanger.* TO NULL 
	END IF 
	IF p_dg_code2 IS NOT NULL THEN 
		SELECT * INTO l_rec_proddanger2.* 
		FROM proddanger 
		WHERE cmpy_code = p_cmpy 
		AND dg_code = p_dg_code2 
	ELSE 
		INITIALIZE l_rec_proddanger2.* TO NULL 
	END IF 

	###-verify the carrying relationship IF class codes are different
	###-IF a NULL class code exists THEN RETURN TRUE
	IF (l_rec_proddanger.class_code IS null) AND 
	(l_rec_proddanger2.class_code IS null) 
	THEN 
		RETURN TRUE ###-can be carried together 
	ELSE 
		IF (l_rec_proddanger.class_code IS null) AND 
		(l_rec_proddanger2.class_code IS NOT null) 
		THEN 
			RETURN TRUE ###-a NULL class code can travel with anything 
		ELSE 
			IF (l_rec_proddanger.class_code IS NOT null) AND 
			(l_rec_proddanger2.class_code IS null) 
			THEN 
				RETURN TRUE ###-a NULL class code can travel with anything 
			END IF 
		END IF 
	END IF 

	###- Class codes are both NOT NULL AND require processing
	IF l_rec_proddanger.class_code != l_rec_proddanger2.class_code THEN 
		SELECT unique 1 
		FROM dangercarry 
		WHERE class1_code = l_rec_proddanger.class_code 
		AND class2_code = l_rec_proddanger2.class_code 
		AND carry_ind IS NOT NULL 
		IF status = NOTFOUND THEN 

			###-Ensure there are no clashes within the current main_dg_code list
			###-by verifying the relationship between each dg_code in the list
			###-AND the second dg_code
			DECLARE c_carry5 cursor FOR 
			SELECT * FROM tmp_carry 
			WHERE main_dg_code = p_dg_code 
			AND (carry_dg_code != p_dg_code AND 
			carry_dg_code IS NOT null)
			 
			FOREACH c_carry5 INTO l_rec_tmp_carry.* 
				###-Collect the proddanger details of the carry_dg_code
				SELECT * INTO l_rec_proddanger3.* 
				FROM proddanger 
				WHERE cmpy_code = p_cmpy 
				AND dg_code = l_rec_tmp_carry.carry_dg_code 
				
				###-IF the same class code THEN no checking needed
				IF l_rec_proddanger2.class_code != l_rec_proddanger3.class_code THEN 
					SELECT unique 1 
					FROM dangercarry 
					WHERE class1_code = l_rec_proddanger2.class_code 
					AND class2_code = l_rec_proddanger3.class_code 
					AND carry_ind IS NOT NULL 
					IF status = NOTFOUND THEN 
						CONTINUE FOREACH 
					ELSE 
						RETURN FALSE ###-second dg_code can't be carried in the list 
					END IF 
				END IF
				 
			END FOREACH
			 
			RETURN TRUE ###-can be carried together 
		END IF 
	END IF 
	RETURN FALSE ###-cannot be carried together 
END FUNCTION 
###########################################################################
# END FUNCTION carry_dangercodes(p_dg_code,p_dg_code2,p_cmpy)
###########################################################################


###########################################################################
# FUNCTION error_mess(p_cmpy,p_ware_code,p_msg_num,p_msg_text,p_verbose_ind)
# 
# 
###########################################################################
FUNCTION error_mess(p_cmpy,p_ware_code,p_msg_num,p_msg_text,p_verbose_ind) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_ware_code LIKE warehouse.ware_code 
	DEFINE p_msg_num LIKE delivmsg.msg_num 
	DEFINE p_msg_text LIKE delivmsg.msg_text 
	DEFINE p_verbose_ind SMALLINT 
	DEFINE l_time LIKE delivmsg.msg_time 
	DEFINE l_event_text LIKE delivmsg.event_text 

	IF p_verbose_ind THEN 
		MESSAGE kandoomsg2("E",p_msg_num,p_msg_text) 
	ELSE 
		LET l_event_text = "Error during generating consignment note" 
		LET l_time = time 
		INSERT INTO delivmsg VALUES (p_cmpy, 
		0, 
		p_ware_code, 
		today, 
		l_time, 
		l_event_text, 
		p_msg_num, 
		p_msg_text) 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION error_mess(p_cmpy,p_ware_code,p_msg_num,p_msg_text,p_verbose_ind)
###########################################################################


###########################################################################
# FUNCTION prepare_connote(
#	p_cmpy,
#	p_kandoouser_sign_on_code,
#	p_carrier_code,
#	p_ware_code, 
#	p_manifest_num,
#	p_invoice_num, 
#	p_despatch_code,
#	p_verbose_ind) 
#
# 
# 
###########################################################################
FUNCTION prepare_connote(
	p_cmpy,
	p_kandoouser_sign_on_code,
	p_carrier_code,
	p_ware_code, 
	p_manifest_num,
	p_invoice_num, 
	p_despatch_code,
	p_verbose_ind) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE p_carrier_code LIKE despatchdetl.carrier_code 
	DEFINE p_ware_code LIKE warehouse.ware_code 
	DEFINE p_manifest_num LIKE despatchdetl.manifest_num 
	DEFINE p_invoice_num LIKE despatchdetl.invoice_num 
	DEFINE p_despatch_code LIKE despatchdetl.despatch_code 
	DEFINE p_verbose_ind SMALLINT 
	DEFINE l_rec_carrier RECORD LIKE carrier.* 
	DEFINE l_rec_despatchdetl RECORD LIKE despatchdetl.* 
	DEFINE l_where_text char(50) 
	DEFINE l_query_text char(200) 
--	DEFINE l_output char(80) 
	DEFINE l_rpt_idx SMALLINT  #report array index
	DEFINE l_tmp_str STRING
	
	IF p_verbose_ind THEN 
		--      OPEN WINDOW w1_E54 AT 15,12 with 1 rows,50 columns  -- albo  KD-755
		--        ATTRIBUTE(border,white,MESSAGE line first)
		MESSAGE " Reporting on Invoice number..." 
	END IF 
	SELECT * 
	INTO l_rec_carrier.* 
	FROM carrier 
	WHERE cmpy_code = p_cmpy 
	AND carrier_code = p_carrier_code 
	IF p_invoice_num IS NULL AND p_despatch_code IS NULL THEN 
		LET l_where_text = "1=1" 
	ELSE 
		IF p_invoice_num IS NULL THEN 
			LET l_where_text = "despatch_code = '",p_despatch_code,"' " 
		ELSE 
			LET l_where_text = "invoice_num = \"",p_invoice_num,"\" " 
		END IF 
	END IF 
	
	LET l_query_text = 
	"SELECT * ", 
	"FROM despatchdetl ", 
	"WHERE cmpy_code = \"",p_cmpy,"\" ", 
	"AND carrier_code = \"",p_carrier_code,"\" ", 
	"AND manifest_num = \"",p_manifest_num,"\" ", 
	"AND ",l_where_text clipped," " 
--	IF p_ware_code IS NOT NULL THEN 
--		LET rpt_note = "EO - Consignment Notes - Warehouse: ", 
--		p_ware_code, 
--		" - Carrier: ",p_carrier_code 
--	ELSE 
--		LET rpt_note = "EO - Consignment Note FOR invoice: ", 
--		p_invoice_num USING "########", 
--		" - Carrier: ",p_carrier_code 
--	END IF 
	
	PREPARE s_despatchdetl FROM l_query_text 
	DECLARE c_despatchdetl cursor with hold FOR s_despatchdetl 
	
	CASE l_rec_carrier.format_ind 
		WHEN "1" 
			#------------------------------------------------------------		
			LET l_rpt_idx = rpt_start("E54-f1","E54_rpt_list_consignment_note_f1","N/A", RPT_SHOW_RMS_DIALOG)
			IF l_rpt_idx = 0 THEN #User pressed CANCEL
				RETURN FALSE
			END IF

			IF p_ware_code IS NOT NULL THEN
				LET l_tmp_str = p_ware_code,	" - Carrier: ",p_carrier_code 
				CALL rpt_set_header_footer_line_2_append(l_rpt_idx,NULL,l_tmp_str) 
			ELSE 
				LET l_tmp_str = p_invoice_num USING "########"," - Carrier: ",p_carrier_code
				CALL rpt_set_header_footer_line_2_append(l_rpt_idx,NULL,l_tmp_str)
			END IF 
				
			START REPORT E54_rpt_list_consignment_note_f1 TO rpt_get_report_file_with_path2(l_rpt_idx)
			WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
			TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
			BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
			LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
			RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
			#------------------------------------------------------------		

			FOREACH c_despatchdetl INTO l_rec_despatchdetl.*
				#---------------------------------------------------------
				OUTPUT TO REPORT E54_rpt_list_consignment_note_f1(l_rpt_idx,
				l_rec_despatchdetl.*)   
				
				IF NOT rpt_int_flag_handler2("Invoice:",l_rec_despatchdetl.invoice_num,NULL,l_rpt_idx) THEN
					EXIT FOREACH 
				END IF 
				#---------------------------------------------------------
			END FOREACH 


			#------------------------------------------------------------
			FINISH REPORT E54_rpt_list_consignment_note_f1
			CALL rpt_finish("E54_rpt_list_consignment_note_f1")
			#------------------------------------------------------------

		WHEN "2" 
			#------------------------------------------------------------		
			LET l_rpt_idx = rpt_start("E54-f2","E54_rpt_list_consignment_note_f2","N/A", RPT_SHOW_RMS_DIALOG)
			IF l_rpt_idx = 0 THEN #User pressed CANCEL
				RETURN FALSE
			END IF	

			IF p_ware_code IS NOT NULL THEN
				LET l_tmp_str = p_ware_code,	" - Carrier: ",p_carrier_code 
				CALL rpt_set_header_footer_line_2_append(l_rpt_idx,NULL,l_tmp_str) 
			ELSE 
				LET l_tmp_str = p_invoice_num USING "########"," - Carrier: ",p_carrier_code
				CALL rpt_set_header_footer_line_2_append(l_rpt_idx,NULL,l_tmp_str)
			END IF 


			START REPORT E54_rpt_list_consignment_note_f2 TO rpt_get_report_file_with_path2(l_rpt_idx)
			WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
			TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
			BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
			LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
			RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
			#------------------------------------------------------------		
			

			IF p_verbose_ind THEN 
				DISPLAY l_rec_despatchdetl.invoice_num at 1,40 

			END IF 
			
			FOREACH c_despatchdetl INTO l_rec_despatchdetl.*
				#---------------------------------------------------------
				OUTPUT TO REPORT E54_rpt_list_consignment_note_f2(l_rpt_idx,
				l_rec_despatchdetl.*)    
				
				IF NOT rpt_int_flag_handler2("Invoice:",l_rec_despatchdetl.invoice_num,NULL,l_rpt_idx) THEN
					EXIT FOREACH 
				END IF 
				#---------------------------------------------------------
			END FOREACH 
			
			#------------------------------------------------------------
			FINISH REPORT E54_rpt_list_consignment_note_f2
			CALL rpt_finish("E54_rpt_list_consignment_note_f2")			
			#------------------------------------------------------------


			#  WHEN "3"
			#     START REPORT connote_f3 TO l_output
			#     IF p_verbose_ind THEN
			#        DISPLAY l_rec_despatchdetl.invoice_num AT 1,40
			#
			#     END IF
			#     FOREACH c_despatchdetl INTO l_rec_despatchdetl.*
			#        IF p_verbose_ind THEN
			#           DISPLAY l_rec_despatchdetl.invoice_num AT 1,40
			#
			#        END IF
			#        OUTPUT TO REPORT connote_f3(l_rec_despatchdetl.*)
			#     END FOREACH
			#     LET rpt_length = ??
			#     LET rpt_wid = ??
			#     CALL upd_reports(l_output,rpt_pageno,rpt_wid,rpt_length)
			#     FINISH REPORT connote_f3
			#  WHEN "4"
			#     LET l_output = init_report(p_cmpy,p_kandoouser_sign_on_code,rpt_note)
			#     START REPORT connote_f4 TO l_output
			#     IF p_verbose_ind THEN
			#        DISPLAY l_rec_despatchdetl.invoice_num AT 1,40
			#
			#     END IF
			#     FOREACH c_despatchdetl INTO l_rec_despatchdetl.*
			#        IF p_verbose_ind THEN
			#           DISPLAY l_rec_despatchdetl.invoice_num AT 1,40
			#
			#        END IF
			#        OUTPUT TO REPORT connote_f4(l_rec_despatchdetl.*)
			#     END FOREACH
			#     LET rpt_length = ??
			#     LET rpt_wid = ??
			#     CALL upd_reports(l_output,rpt_pageno,rpt_wid,rpt_length)
			#     FINISH REPORT connote_f4
			#  WHEN "5"
			#     LET l_output = init_report(p_cmpy,p_kandoouser_sign_on_code,rpt_note)
			#     START REPORT connote_f5 TO l_output
			#     IF p_verbose_ind THEN
			#        DISPLAY l_rec_despatchdetl.invoice_num AT 1,40
			#
			#     END IF
			#     FOREACH c_despatchdetl INTO l_rec_despatchdetl.*
			#        IF p_verbose_ind THEN
			#           DISPLAY l_rec_despatchdetl.invoice_num AT 1,40
			#
			#        END IF
			#        OUTPUT TO REPORT connote_f5(l_rec_despatchdetl.*)
			#     END FOREACH
			#     LET rpt_length = ??
			#     LET rpt_wid = ??
			#     CALL upd_reports(l_output,rpt_pageno,rpt_wid,rpt_length)
			#     FINISH REPORT connote_f5
			#  WHEN "6"
			#     LET l_output = init_report(p_cmpy,p_kandoouser_sign_on_code,rpt_note)
			#     START REPORT connote_f6 TO l_output
			#     IF p_verbose_ind THEN
			#        DISPLAY l_rec_despatchdetl.invoice_num AT 1,40
			#
			#     END IF
			#     FOREACH c_despatchdetl INTO l_rec_despatchdetl.*
			#        IF p_verbose_ind THEN
			#           DISPLAY l_rec_despatchdetl.invoice_num AT 1,40
			#
			#        END IF
			#        OUTPUT TO REPORT connote_f6(l_rec_despatchdetl.*)
			#     END FOREACH
			#     LET rpt_length = ??
			#     LET rpt_wid = ??
			#     CALL upd_reports(l_output,rpt_pageno,rpt_wid,rpt_length)
			#     FINISH REPORT connote_f6
			#  WHEN "7"
			#     LET l_output = init_report(p_cmpy,p_kandoouser_sign_on_code,rpt_note)
			#     START REPORT connote_f7 TO l_output
			#     IF p_verbose_ind THEN
			#        DISPLAY l_rec_despatchdetl.invoice_num AT 1,40
			#
			#     END IF
			#     FOREACH c_despatchdetl INTO l_rec_despatchdetl.*
			#        IF p_verbose_ind THEN
			#           DISPLAY l_rec_despatchdetl.invoice_num AT 1,40
			#
			#        END IF
			#        OUTPUT TO REPORT connote_f7(l_rec_despatchdetl.*)
			#     END FOREACH
			#     LET rpt_length = ??
			#     LET rpt_wid = ??
			#     CALL upd_reports(l_output,rpt_pageno,rpt_wid,rpt_length)
			#     FINISH REPORT connote_f7
			#  WHEN "8"
			#     LET l_output = init_report(p_cmpy,p_kandoouser_sign_on_code,rpt_note)
			#     START REPORT connote_f8 TO l_output
			#     IF p_verbose_ind THEN
			#        DISPLAY l_rec_despatchdetl.invoice_num AT 1,40
			#
			#     END IF
			#     FOREACH c_despatchdetl INTO l_rec_despatchdetl.*
			#        IF p_verbose_ind THEN
			#           DISPLAY l_rec_despatchdetl.invoice_num AT 1,40
			#
			#        END IF
			#        OUTPUT TO REPORT connote_f8(l_rec_despatchdetl.*)
			#     END FOREACH
			#     LET rpt_length = ??
			#     LET rpt_wid = ??
			#     CALL upd_reports(l_output,rpt_pageno,rpt_wid,rpt_length)
			#     FINISH REPORT connote_f8
			#  WHEN "9"
			#     LET l_output = init_report(p_cmpy,p_kandoouser_sign_on_code,rpt_note)
			#     START REPORT connote_f9 TO l_output
			#     IF p_verbose_ind THEN
			#        DISPLAY l_rec_despatchdetl.invoice_num AT 1,40
			#
			#     END IF
			#     FOREACH c_despatchdetl INTO l_rec_despatchdetl.*
			#        IF p_verbose_ind THEN
			#           DISPLAY l_rec_despatchdetl.invoice_num AT 1,40
			#
			#        END IF
			#        OUTPUT TO REPORT connote_f9(l_rec_despatchdetl.*)
			#     END FOREACH
			#     LET rpt_length = ??
			#     LET rpt_wid = ??
			#     CALL upd_reports(l_output,rpt_pageno,rpt_wid,rpt_length)
			#     FINISH REPORT connote_f9
		OTHERWISE 

			#------------------------------------------------------------		
			LET l_rpt_idx = rpt_start("E54-f1","E54_rpt_list_consignment_note_f1","N/A", RPT_SHOW_RMS_DIALOG)
			IF l_rpt_idx = 0 THEN #User pressed CANCEL
				RETURN FALSE
			END IF	

			IF p_ware_code IS NOT NULL THEN
				LET l_tmp_str = p_ware_code,	" - Carrier: ",p_carrier_code 
				CALL rpt_set_header_footer_line_2_append(l_rpt_idx,NULL,l_tmp_str) 
			ELSE 
				LET l_tmp_str = p_invoice_num USING "########"," - Carrier: ",p_carrier_code
				CALL rpt_set_header_footer_line_2_append(l_rpt_idx,NULL,l_tmp_str)
			END IF 

			START REPORT E54_rpt_list_consignment_note_f1 TO rpt_get_report_file_with_path2(l_rpt_idx)
			WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
			TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
			BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
			LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
			RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
			#------------------------------------------------------------		
			
			FOREACH c_despatchdetl INTO l_rec_despatchdetl.* 
				#---------------------------------------------------------
				OUTPUT TO REPORT E54_rpt_list_consignment_note_f1(l_rpt_idx,
				l_rec_despatchdetl.*)   
				
				IF NOT rpt_int_flag_handler2("Invoice:",l_rec_despatchdetl.invoice_num,NULL,l_rpt_idx) THEN
					EXIT FOREACH 
				END IF 
				#---------------------------------------------------------
			END FOREACH 

			#------------------------------------------------------------
			FINISH REPORT E54_rpt_list_consignment_note_f1
			CALL rpt_finish("E54_rpt_list_consignment_note_f1")
			#------------------------------------------------------------
	END CASE 
	
	# Explicit close of c_despatchdetl, was declared with hold!
	CLOSE c_despatchdetl 
	IF p_verbose_ind THEN 
		--      CLOSE WINDOW w1_E54  -- albo  KD-755
	END IF 

	IF int_flag THEN 
		LET int_flag = FALSE 
		ERROR " Printing was aborted" 
		RETURN FALSE 
	ELSE 
		RETURN TRUE 
	END IF 	
END FUNCTION 
###########################################################################
# END FUNCTION prepare_connote(p_cmpy,p_kandoouser_sign_on_code,p_carrier_code,p_ware_code,	p_manifest_num,p_invoice_num,	p_despatch_code,p_verbose_ind) 
###########################################################################


###########################################################################
# FUNCTION add_consign_note(p_next_consign)
# 
# 
###########################################################################
FUNCTION add_consign_note(p_next_consign) 
	DEFINE p_next_consign LIKE carrier.next_consign 
	DEFINE l_part_old_char LIKE carrier.next_consign 
	DEFINE l_part_char LIKE carrier.next_consign 
	DEFINE l_part_num INTEGER 
	DEFINE i SMALLINT 
	DEFINE x SMALLINT 
	DEFINE y SMALLINT 
	DEFINE z SMALLINT 

	LET l_part_char = NULL 
	FOR x = length(p_next_consign) TO 1 step -1 
		IF p_next_consign[x,x] < "0" 
		OR p_next_consign[x,x] > "9" THEN 
			EXIT FOR 
		ELSE 
			LET l_part_char[x,x] = p_next_consign[x,x] 
		END IF 
	END FOR 
	# Length numeric part original number
	LET y = length(l_part_char) - x 
	LET l_part_num = l_part_char + 1 
	LET l_part_char = l_part_num 
	# Length numeric part new number
	LET z = length(l_part_char) 
	# Check IF addition leads TO outnumbering
	LET x = length(p_next_consign) + z - y 
	# IF length new number < length old number fill with leading zeroes
	IF z < y THEN 
		LET l_part_old_char = l_part_char 
		FOR i = y TO 1 step -1 
			LET l_part_char[i,i] = "0" 
		END FOR 
		LET i = y - z + 1 
		LET l_part_char[i,y] = l_part_old_char[1,z] 
		# Length numeric part new number
		LET z = length(l_part_char) 
	END IF 
	#  Determine startposition new number
	LET x = length(p_next_consign) - y + 1 
	# Determine endposition new number
	LET y = x + z - 1 
	# Place new number AT correct position in last consigment note number
	LET p_next_consign[x,y] = l_part_char[1,z] 
	RETURN p_next_consign 
END FUNCTION 
###########################################################################
# END FUNCTION add_consign_note(p_next_consign)
###########################################################################


###########################################################################
# REPORT E54_rpt_list_consignment_note_f1(p_rpt_idx,p_rec_despatchdetl)
# 
# customer specific Consignment note 
###########################################################################
REPORT E54_rpt_list_consignment_note_f1(p_rpt_idx,p_rec_despatchdetl) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_rec_despatchdetl RECORD LIKE despatchdetl.* 
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_rec_orderhead RECORD LIKE orderhead.* 
	DEFINE l_rec_dangerline RECORD LIKE dangerline.* 
	DEFINE l_rec_proddanger RECORD LIKE proddanger.* 
	DEFINE i SMALLINT 

	OUTPUT 
--	top margin 5 
--	PAGE length 33 

	FORMAT
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
	 
		ON EVERY ROW 
			INITIALIZE l_rec_invoicehead.* TO NULL 
			IF p_rec_despatchdetl.invoice_num IS NOT NULL THEN 
				SELECT * 
				INTO l_rec_invoicehead.* 
				FROM invoicehead 
				WHERE cmpy_code = p_rec_despatchdetl.cmpy_code 
				AND inv_num = p_rec_despatchdetl.invoice_num 
			ELSE 
				DECLARE c1_orders cursor FOR 
				SELECT * INTO l_rec_orderhead.* 
				FROM orderhead 
				WHERE cmpy_code = p_rec_despatchdetl.cmpy_code 
				AND order_num in 
				(select pd.order_num 
				FROM pickdetl pd,pickhead ph 
				WHERE pd.cmpy_code = p_rec_despatchdetl.cmpy_code 
				AND ph.cmpy_code = p_rec_despatchdetl.cmpy_code 
				AND ph.pick_num = p_rec_despatchdetl.pick_num 
				AND pd.pick_num = ph.pick_num 
				AND ph.carrier_code = p_rec_despatchdetl.carrier_code 
				AND ph.ware_code = pd.ware_code) 
				OPEN c1_orders 
				FETCH c1_orders 
				CLOSE c1_orders 
				LET l_rec_invoicehead.name_text = l_rec_orderhead.ship_name_text 
				LET l_rec_invoicehead.addr1_text = l_rec_orderhead.ship_addr1_text 
				LET l_rec_invoicehead.addr2_text = l_rec_orderhead.ship_addr2_text 
				LET l_rec_invoicehead.city_text = l_rec_orderhead.ship_city_text 
				LET l_rec_invoicehead.state_code = l_rec_orderhead.state_code 
				LET l_rec_invoicehead.post_code = l_rec_orderhead.post_code 
				LET l_rec_invoicehead.country_code = l_rec_orderhead.country_code --@db-patch_2020_10_04--
				LET l_rec_invoicehead.ord_num = l_rec_orderhead.order_num 
			END IF 
			PRINT COLUMN 34, "X", 
			COLUMN 36, l_rec_invoicehead.name_text 
			PRINT COLUMN 36, l_rec_invoicehead.addr1_text 
			SKIP 1 line 
			PRINT COLUMN 36, l_rec_invoicehead.city_text, 
			COLUMN 56, l_rec_invoicehead.state_code, 
			COLUMN 63, l_rec_invoicehead.post_code[1,5] 
			SKIP 2 LINES 
			PRINT COLUMN 32, "NO GOODS TO BE LEFT WITHOUT signature" 
			SKIP 3 LINES 
			PRINT COLUMN 11, "HAIR cosmetics", 
			COLUMN 36, p_rec_despatchdetl.gross_wgt_qty USING "###.##" 
			PRINT COLUMN 11, "GW", 
			COLUMN 13, l_rec_invoicehead.ord_num USING "########" 
			SKIP TO top OF PAGE 
			--LET rpt_pageno = pageno 
END REPORT 
###########################################################################
# END REPORT E54_rpt_list_consignment_note_f1(p_rpt_idx,p_rec_despatchdetl)
###########################################################################


###########################################################################
# REPORT E54_rpt_list_consignment_note_f1(p_rec_despatchdetl)
# 
# Customer specific General consignment note 
###########################################################################
REPORT E54_rpt_list_consignment_note_f2(p_rpt_idx,p_rec_despatchdetl) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_rec_despatchdetl RECORD LIKE despatchdetl.* 
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_rec_orderhead RECORD LIKE orderhead.* 
	DEFINE l_rec_dangerline RECORD LIKE dangerline.* 
	DEFINE l_rec_proddanger RECORD LIKE proddanger.* 
	DEFINE l_next_line SMALLINT 

	OUTPUT 

	FORMAT
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
	 
		ON EVERY ROW 
			INITIALIZE l_rec_invoicehead.* TO NULL 
			IF p_rec_despatchdetl.invoice_num IS NOT NULL THEN 
				SELECT * 
				INTO l_rec_invoicehead.* 
				FROM invoicehead 
				WHERE cmpy_code = p_rec_despatchdetl.cmpy_code 
				AND inv_num = p_rec_despatchdetl.invoice_num 
			ELSE 
				DECLARE c2_orders cursor FOR 
				SELECT * INTO l_rec_orderhead.* 
				FROM orderhead 
				WHERE cmpy_code = p_rec_despatchdetl.cmpy_code 
				AND order_num in 
				(select pd.order_num 
				FROM pickdetl pd,pickhead ph 
				WHERE pd.cmpy_code = p_rec_despatchdetl.cmpy_code 
				AND ph.cmpy_code = p_rec_despatchdetl.cmpy_code 
				AND ph.pick_num = p_rec_despatchdetl.pick_num 
				AND pd.pick_num = ph.pick_num 
				AND ph.carrier_code = p_rec_despatchdetl.carrier_code 
				AND ph.ware_code = pd.ware_code) 
				OPEN c2_orders 
				FETCH c2_orders 
				CLOSE c2_orders 
				
				LET l_rec_invoicehead.name_text = l_rec_orderhead.ship_name_text 
				LET l_rec_invoicehead.addr1_text = l_rec_orderhead.ship_addr1_text 
				LET l_rec_invoicehead.addr2_text = l_rec_orderhead.ship_addr2_text 
				LET l_rec_invoicehead.city_text = l_rec_orderhead.ship_city_text 
				LET l_rec_invoicehead.state_code = l_rec_orderhead.state_code 
				LET l_rec_invoicehead.post_code = l_rec_orderhead.post_code 
				LET l_rec_invoicehead.country_code = l_rec_orderhead.country_code --@db-patch_2020_10_04--
				LET l_rec_invoicehead.ord_num = l_rec_orderhead.order_num 
			END IF 
			
			PRINT COLUMN 36, l_rec_invoicehead.addr1_text 
			SKIP 1 line 
			PRINT COLUMN 36, l_rec_invoicehead.addr2_text 
			SKIP 1 line 
			PRINT COLUMN 36, l_rec_invoicehead.city_text, 
			COLUMN 56, l_rec_invoicehead.state_code, 
			COLUMN 63, l_rec_invoicehead.post_code[1,5] 
			SKIP 1 line 
			PRINT COLUMN 15, "NO GOODS TO BE LEFT WITHOUT signature" 
			SKIP 9 LINES 
			PRINT COLUMN 2, "HAIR cosmetics", 
			COLUMN 30, p_rec_despatchdetl.gross_wgt_qty USING "##&.&&" 
			PRINT COLUMN 2, "GW", 
			COLUMN 4, l_rec_invoicehead.ord_num USING "########" 
			PRINT COLUMN 2, "INVOICE:", 
			COLUMN 11, l_rec_invoicehead.inv_num USING "########" 
			
			###-Include any Dangerlines setup FOR this connote-###
			###-move TO the dangerline section;must start on the 33rd line-###
			SKIP 10 line 
			
			###-collect the dangerlines AND PRINT-###
			DECLARE c_danger3 cursor FOR 
			SELECT dl.*,pd.* 
			FROM dangerline dl, proddanger pd 
			WHERE dl.cmpy_code = pd.cmpy_code 
			AND dl.dg_code = pd.dg_code 
			AND dl.cmpy_code = p_rec_despatchdetl.cmpy_code 
			AND dl.despatch_code = p_rec_despatchdetl.despatch_code 
			AND dl.manifest_num = p_rec_despatchdetl.manifest_num 
			ORDER BY dl.dg_code 
			LET l_next_line=0 
			FOREACH c_danger3 INTO l_rec_dangerline.*, 
				l_rec_proddanger.* 
				PRINT COLUMN 002, l_rec_proddanger.tech_text[1,15], 
				COLUMN 019, l_rec_proddanger.class_code, 
				COLUMN 025, l_rec_proddanger.un_num_text, 
				COLUMN 035, l_rec_proddanger.pkg_code, 
				COLUMN 042, l_rec_dangerline.nett_wgt_qty USING "#####&.&&", 
				COLUMN 053, l_rec_dangerline.despatch_qty USING "#####&.&&" 
				LET l_next_line=l_next_line+1 
				
				###-connote only allows three dangerous goods references-###
				IF l_next_line=3 THEN 
					EXIT FOREACH 
				END IF 
				SKIP 1 line 
			END FOREACH 
			SKIP TO top OF PAGE 
			#LET rpt_pageno = pageno 
			#  page trailer
			#     PRINT COLUMN 41,"Received by",
			#           COLUMN 60,"Date"
			#     skip 1 lines
			#     PRINT COLUMN 60,"/  /"
			#     PRINT COLUMN 41,".........................."
			#     skip 1 lines
END REPORT
###########################################################################
# END REPORT E54_rpt_list_consignment_note_f1(p_rec_despatchdetl)
###########################################################################