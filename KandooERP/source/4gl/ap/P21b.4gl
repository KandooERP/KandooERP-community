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

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_P2_GLOBALS.4gl" 
GLOBALS 
	#DEFINE glob_ctl_linetotal SMALLINT #not used in this module
	#DEFINE glob_bat_linetotal SMALLINT #not used in this module
	#DEFINE glob_bat_amttotal LIKE voucher.total_amt #not used in this module
	#DEFINE glob_ctl_amttotal LIKE voucher.total_amt #not used in this module
	DEFINE glob_gv_distr_amt_option CHAR(1) 
END GLOBALS 
############################################################
# MODULE Scope Variables
############################################################

#another one! see P64a.4gl

############################################################
# FUNCTION voucher_distribution_menu(p_cmpy, p_kandoouser_sign_on_code, p_rec_voucher, p_rec_vouchpayee, p_update_ind)
#
#
############################################################
FUNCTION voucher_distribution_menu(p_cmpy,p_kandoouser_sign_on_code,p_rec_voucher,p_rec_vouchpayee,p_update_ind) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE p_rec_voucher RECORD LIKE voucher.* 
	DEFINE p_rec_vouchpayee RECORD LIKE vouchpayee.* 
	DEFINE p_update_ind CHAR(1) 
	DEFINE l_dist_amt LIKE voucher.dist_amt 
	#DEFINE l_exit_flag CHAR(1) #not used
	#DEFINE l_bal_flag CHAR(1) #not used
	DEFINE l_process_dist CHAR(1) 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_distribution_status SMALLINT
	DEFINE l_msg STRING

	LET glob_gv_distr_amt_option = get_kandoooption_feature_state("AP", "DA") 
	IF p_rec_voucher.vend_code IS NOT NULL THEN 

		MENU " Voucher" 
			BEFORE MENU 
				IF p_rec_voucher.post_flag = "Y" THEN 
					HIDE option "Distribution" 
				ELSE 
					DELETE FROM t_voucherdist 
					INSERT INTO t_voucherdist 
					SELECT * FROM voucherdist 
					WHERE cmpy_code = p_cmpy 
					AND vend_code = p_rec_voucher.vend_code 
					AND vouch_code= p_rec_voucher.vouch_code 
				END IF 
				
				IF get_kandoooption_feature_state("AP", "DA") = 'N' THEN #HuHo 11.03.2020 - Note, I did add this, but I'm not 100% sure about it. I just don't understand why DISTRIBUTION should be available if it is de/not selected in kandoooptions features
					CALL dialog.setActionHidden("DISTRIBUTION",TRUE)
					LET l_dist_amt = NULL 
					SELECT sum(dist_amt) INTO l_dist_amt FROM t_voucherdist 
					IF l_dist_amt IS NULL THEN 
						LET l_dist_amt = 0 
					END IF 
					
					IF p_rec_voucher.total_amt < l_dist_amt THEN 
						LET l_msgresp=kandoomsg("P",9047,"") 
						#9047 Total distributions exceed total of the voucher"
						NEXT option "Distribution" 
					ELSE 
						LET p_rec_voucher.vouch_code = update_voucher_related_tables(p_cmpy, p_kandoouser_sign_on_code, 
						p_update_ind, 
						p_rec_voucher.*, 
						p_rec_vouchpayee.*) 
						CASE 
							WHEN p_rec_voucher.vouch_code < 0 
								LET p_rec_voucher.vouch_code = 0 - p_rec_voucher.vouch_code 
								LET l_msgresp=kandoomsg("P",7016,p_rec_voucher.vouch_code) 
								#7016 Voucher added - error with dist lines
							WHEN p_rec_voucher.vouch_code = 0 
								LET l_msgresp=kandoomsg("P",7012,"") 
								#7012 Errors occurred during voucher add
						END CASE
						
						CASE p_update_ind 
							WHEN '1' 
								IF p_rec_voucher.vouch_code > 0 THEN 
									LET l_msgresp=kandoomsg("P",7011,p_rec_voucher.vouch_code) 
									#P7011" Voucher created successfully"
								END IF 
							WHEN '2' 
								SELECT * INTO p_rec_voucher.* 
								FROM voucher 
								WHERE cmpy_code = p_cmpy 
								AND vend_code = p_rec_voucher.vend_code 
								AND vouch_code= p_rec_voucher.vouch_code 
						END CASE 
						EXIT MENU 
					END IF 
					
					EXIT MENU #In this case, there is only one option.. to reason to show this menu
				END IF
				CALL publish_toolbar("kandoo","P21b","menu-voucher-1") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON ACTION "SAVE" --COMMAND "Save" " Save voucher TO database" 
				LET l_dist_amt = NULL 
				SELECT sum(dist_amt) INTO l_dist_amt FROM t_voucherdist 
				IF l_dist_amt IS NULL THEN 
					LET l_dist_amt = 0 
				END IF 
				
				IF p_rec_voucher.total_amt < l_dist_amt THEN 
					LET l_msgresp=kandoomsg("P",9047,"") 
					#9047 Total distributions exceed total of the voucher"
					NEXT option "Distribution" 
				ELSE 
					CALL update_voucher_related_tables(p_cmpy, p_kandoouser_sign_on_code,p_update_ind,p_rec_voucher.*,p_rec_vouchpayee.*) 
					RETURNING p_rec_voucher.vouch_code 
					CASE 
						WHEN p_rec_voucher.vouch_code < 0 
							LET p_rec_voucher.vouch_code = 0 - p_rec_voucher.vouch_code 
							LET l_msgresp=kandoomsg("P",7016,p_rec_voucher.vouch_code) 
							#7016 Voucher added - error with dist lines
						WHEN p_rec_voucher.vouch_code = 0 
							LET l_msgresp=kandoomsg("P",7012,"") 
							#7012 Errors occurred during voucher add
						OTHERWISE
							LET l_msg = "Internal voucher # ",p_rec_voucher.vouch_code USING "&&&&&&&"
							CALL fgl_winmessage("Voucher created successfully",l_msg, "info") 
					END CASE
					 
					CASE p_update_ind 
						WHEN '1' 
							IF p_rec_voucher.vouch_code > 0 THEN 
								LET l_msgresp=kandoomsg("P",7011,p_rec_voucher.vouch_code) 
								#P7011" Voucher created successfully"
							END IF 
						WHEN '2' 
							SELECT * INTO p_rec_voucher.* 
							FROM voucher 
							WHERE cmpy_code = p_cmpy 
							AND vend_code = p_rec_voucher.vend_code 
							AND vouch_code= p_rec_voucher.vouch_code 
					END CASE 
					EXIT MENU 
				END IF 

			ON ACTION "DISTRIBUTION"	--COMMAND "Distribution"	" Enter account distribution FOR this voucher" 
				OPEN WINDOW p169 with FORM "P169" 
				CALL windecoration_p("P169") 
				LET l_process_dist = "Y" 

				WHILE l_process_dist = "Y" 
					CALL distribute_voucher_to_accounts(p_cmpy,p_kandoouser_sign_on_code,p_rec_voucher.*)
					RETURNING l_distribution_status 
					IF NOT l_distribution_status THEN 
						DELETE FROM t_voucherdist 
						INSERT INTO t_voucherdist 
						SELECT * FROM voucherdist 
						WHERE cmpy_code = p_cmpy 
						AND vend_code = p_rec_voucher.vend_code 
						AND vouch_code = p_rec_voucher.vouch_code 
						EXIT WHILE 
					END IF 

					IF glob_gv_distr_amt_option = "Y" THEN 
						SELECT sum(dist_amt) 
						INTO p_rec_voucher.dist_amt 
						FROM t_voucherdist 
						IF p_rec_voucher.dist_amt <> p_rec_voucher.total_amt THEN 
							LET l_msgresp = kandoomsg("P", 1054, "") 
							#Distribution amount <> Total amount?
						END IF 
					END IF 

					IF (glob_gv_distr_amt_option = "N")
					OR (p_rec_voucher.dist_amt = p_rec_voucher.total_amt) 
					OR (l_msgresp = "Y") THEN 
						LET l_process_dist = "N" --Exit
					END IF 
				END WHILE 

				CLOSE WINDOW p169 

			ON ACTION "CANCEL" --COMMAND KEY(interrupt,"E")"Exit" " Discard changes" 
				LET quit_flag = TRUE 
				EXIT MENU 

		END MENU 

		DELETE FROM t_voucherdist 
		
		IF int_flag OR quit_flag THEN 
			LET p_rec_voucher.vouch_code = p_rec_voucher.vouch_code * -1 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
		END IF 
		RETURN p_rec_voucher.vouch_code 
	ELSE 
		RETURN FALSE 
	END IF 
END FUNCTION