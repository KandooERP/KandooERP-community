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

	Source code beautified by beautify.pl on 2020-01-02 18:38:37	$Id: $
}

{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "L_LC_GLOBALS.4gl" 
GLOBALS 
	DEFINE glob_rec_coa RECORD LIKE coa.* 
	#DEFINE glob_rec_printcodes RECORD LIKE printcodes.* #not used
	DEFINE glob_rec_vendor RECORD LIKE vendor.* 
	#DEFINE glob_err_flag SMALLINT	 #not used
	#DEFINE glob_cnt SMALLINT	 #not used
	#DEFINE glob_level CHAR(1) #not used
END GLOBALS 


############################################################
# MAIN
#
# \brief module LZP allows the user TO enter AND maintain Shipment Monitoring
#             Parameters
############################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("LZP") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 


	CALL smparm() 
END MAIN 


############################################################
# FUNCTION smparm()
#
#
############################################################
FUNCTION smparm() 

	OPEN WINDOW l116 with FORM "L116" 
	CALL windecoration_l("L116") -- albo kd-763 

	MENU " Parameters" 
		ON ACTION "WEB-HELP" -- albo kd-375 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE MENU 
			IF disp_smparm() THEN 
				HIDE option "Add" 
			ELSE 
				HIDE option "Change" 
			END IF 

		COMMAND "Add" " Add Parameters" 
			IF add_smparm() THEN 
				HIDE option "Add" 
				SHOW option "Change" 
			END IF 
			IF disp_smparm() THEN 
			END IF 

		COMMAND "Change" " Change Parameters" 
			CALL change_parm() 
			IF disp_smparm() THEN 
			END IF 

		COMMAND KEY (interrupt, "E") "Exit" " Exit TO menus" 
			EXIT program 
			#      COMMAND KEY (control-w)
			#         CALL kandoohelp("")
	END MENU 

END FUNCTION 



############################################################
# FUNCTION add_smparm()
#
#
############################################################
FUNCTION add_smparm() 
	DEFINE l_rec_smparms RECORD LIKE smparms.* 
	DEFINE l_temp_text CHAR(30) 

	LET msgresp = kandoomsg("U",1070,"") 
	#1070 Enter Parameter details; OK TO continue.
	INPUT BY NAME l_rec_smparms.next_ship_code, 
	l_rec_smparms.next_recpt_num, 
	l_rec_smparms.agent_vend_code, 
	l_rec_smparms.stax_uplift_per, 
	l_rec_smparms.direct_print_flag, 
	l_rec_smparms.print_text, 
	l_rec_smparms.git_acct_code, 
	l_rec_smparms.exp_git_acct_code, 
	l_rec_smparms.ord_git_acct_code, 
	l_rec_smparms.ret_git_acct_code WITHOUT DEFAULTS 

		ON ACTION "WEB-HELP" -- albo kd-375 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) infield (agent_vend_code) 
			LET l_temp_text = show_vend(glob_rec_kandoouser.cmpy_code,l_rec_smparms.agent_vend_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_smparms.agent_vend_code = l_temp_text 
				DISPLAY BY NAME l_rec_smparms.agent_vend_code 

			END IF 
			NEXT FIELD agent_vend_code 

		ON KEY (control-b) infield (git_acct_code) 
			LET l_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_smparms.git_acct_code = l_temp_text 
				DISPLAY BY NAME l_rec_smparms.git_acct_code 

			END IF 
			NEXT FIELD git_acct_code 

		ON KEY (control-b) infield (exp_git_acct_code) 
			LET l_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_smparms.exp_git_acct_code = l_temp_text 
				DISPLAY BY NAME l_rec_smparms.exp_git_acct_code 

			END IF 
			NEXT FIELD exp_git_acct_code 

		ON KEY (control-b) infield (ord_git_acct_code) 
			LET l_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_smparms.ord_git_acct_code = l_temp_text 
				DISPLAY BY NAME l_rec_smparms.ord_git_acct_code 

			END IF 
			NEXT FIELD ord_git_acct_code 

		ON KEY (control-b) infield (ret_git_acct_code) 
			LET l_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_smparms.ret_git_acct_code = l_temp_text 
				DISPLAY BY NAME l_rec_smparms.ret_git_acct_code 

			END IF 
			NEXT FIELD ret_git_acct_code 

		ON KEY (control-b) infield (print_text) 
			LET l_temp_text = show_print(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_smparms.print_text = l_temp_text 
				DISPLAY BY NAME l_rec_smparms.print_text 

			END IF 
			NEXT FIELD print_text 

		AFTER FIELD next_ship_code 
			IF l_rec_smparms.next_ship_code IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered.
				NEXT FIELD next_ship_code 
			END IF 
			IF l_rec_smparms.next_ship_code < 0 THEN 
				LET msgresp = kandoomsg("L",9035,"") 
				#9035 Shipment code must be greatet than OR equal TO zero.
				NEXT FIELD next_ship_code 
			END IF 

		AFTER FIELD next_recpt_num 
			IF l_rec_smparms.next_recpt_num IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered.
				NEXT FIELD next_recpt_num 
			END IF 
			IF l_rec_smparms.next_recpt_num < 0 THEN 
				LET msgresp = kandoomsg("L",9036,"") 
				#9036 Next receipt number must be equal TO OR greater than zero.
				NEXT FIELD next_recpt_num 
			END IF 

		AFTER FIELD agent_vend_code 
			SELECT name_text INTO glob_rec_vendor.name_text FROM vendor 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = l_rec_smparms.agent_vend_code 
			IF status = notfound THEN 
				LET msgresp = kandoomsg("P",9043,"") 
				#9043 Vendor NOT found; Try Window.
				NEXT FIELD agent_vend_code 
			END IF 
			DISPLAY BY NAME glob_rec_vendor.name_text 


		AFTER FIELD git_acct_code 
			SELECT unique 1 FROM coa 
			WHERE coa.acct_code = l_rec_smparms.git_acct_code 
			AND coa.cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = notfound THEN 
				LET msgresp = kandoomsg("L",9030,"") 
				#9030 Account NOT found; Try Window.
				NEXT FIELD git_acct_code 
			END IF 

		AFTER FIELD exp_git_acct_code 
			SELECT unique 1 FROM coa 
			WHERE coa.acct_code = l_rec_smparms.exp_git_acct_code 
			AND coa.cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = notfound THEN 
				LET msgresp = kandoomsg("L",9030,"") 
				#9030 Account NOT found; Try Window.
				NEXT FIELD exp_git_acct_code 
			END IF 

		AFTER FIELD ord_git_acct_code 
			SELECT unique 1 FROM coa 
			WHERE coa.acct_code = l_rec_smparms.ord_git_acct_code 
			AND coa.cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = notfound THEN 
				LET msgresp = kandoomsg("L",9030,"") 
				#9030 Account NOT found; Try Window.
				NEXT FIELD ord_git_acct_code 
			END IF 

		AFTER FIELD ret_git_acct_code 
			SELECT unique 1 FROM coa 
			WHERE coa.acct_code = l_rec_smparms.ret_git_acct_code 
			AND coa.cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = notfound THEN 
				LET msgresp = kandoomsg("L",9030,"") 
				#9030 Account NOT found; Try Window.
				NEXT FIELD ret_git_acct_code 
			END IF 

		AFTER FIELD stax_uplift_per 
			IF l_rec_smparms.stax_uplift_per IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered.
				NEXT FIELD stax_uplift_per 
			END IF 
			IF l_rec_smparms.stax_uplift_per < 0 THEN 
				LET msgresp = kandoomsg("L",9034,"") 
				#9034 Sales Tax Uplift must be greatet than OR equal TO zero.
				NEXT FIELD stax_uplift_per 
			END IF 

		AFTER FIELD direct_print_flag 
			IF (l_rec_smparms.direct_print_flag <> "Y" 
			AND l_rec_smparms.direct_print_flag <> "N" ) 
			OR l_rec_smparms.direct_print_flag IS NULL THEN 
				LET msgresp = kandoomsg("U",1026,"") 
				#1026 Valid VALUES are (Y)es OR (N)o.
				NEXT FIELD direct_print_flag 
			END IF 

		BEFORE FIELD print_text 
			IF l_rec_smparms.direct_print_flag <> "Y" THEN 
				IF fgl_lastkey() = fgl_keyval("up") 
				OR fgl_lastkey() = fgl_keyval("left") THEN 
					NEXT FIELD direct_print_flag 
				ELSE 
					NEXT FIELD git_acct_code 
				END IF 
			END IF 

		AFTER FIELD print_text 
			IF l_rec_smparms.direct_print_flag = "Y" 
			AND l_rec_smparms.print_text IS NULL THEN 
				LET msgresp = kandoomsg("U",9509,"") 
				#9509 Printer must be defined.
				NEXT FIELD print_text 
			END IF 
			SELECT unique 1 FROM printcodes 
			WHERE print_code = l_rec_smparms.print_text 
			IF status = notfound THEN 
				LET msgresp = kandoomsg("W",9301,"") 
				#9301 Printer NOT found; Try Window.
				NEXT FIELD print_text 
			END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				SELECT name_text INTO glob_rec_vendor.name_text FROM vendor 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND vend_code = l_rec_smparms.agent_vend_code 
				IF status = notfound THEN 
					LET msgresp = kandoomsg("P",9043,"") 
					#9043 Vendor NOT found; Try Window.
					NEXT FIELD agent_vend_code 
				END IF 
				DISPLAY BY NAME glob_rec_vendor.name_text 

				SELECT unique 1 FROM coa 
				WHERE coa.acct_code = l_rec_smparms.git_acct_code 
				AND coa.cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = notfound THEN 
					LET msgresp = kandoomsg("L",9030,"") 
					#9030 Account NOT found; Try Window.
					NEXT FIELD git_acct_code 
				END IF 
				SELECT unique 1 FROM coa 
				WHERE coa.acct_code = l_rec_smparms.exp_git_acct_code 
				AND coa.cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = notfound THEN 
					LET msgresp = kandoomsg("L",9030,"") 
					#9030 Account NOT found; Try Window.
					NEXT FIELD exp_git_acct_code 
				END IF 
				SELECT unique 1 FROM coa 
				WHERE coa.acct_code = l_rec_smparms.ord_git_acct_code 
				AND coa.cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = notfound THEN 
					LET msgresp = kandoomsg("L",9030,"") 
					#9030 Account NOT found; Try Window.
					NEXT FIELD ord_git_acct_code 
				END IF 
				SELECT unique 1 FROM coa 
				WHERE coa.acct_code = l_rec_smparms.ret_git_acct_code 
				AND coa.cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = notfound THEN 
					LET msgresp = kandoomsg("L",9030,"") 
					#9030 Account NOT found; Try Window.
					NEXT FIELD ret_git_acct_code 
				END IF 
				IF l_rec_smparms.stax_uplift_per IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered.
					NEXT FIELD stax_uplift_per 
				END IF 
				IF l_rec_smparms.stax_uplift_per < 0 THEN 
					LET msgresp = kandoomsg("L",9034,"") 
					#9034 Sales Tax Uplift must be greatet than OR equal TO zero.
					NEXT FIELD stax_uplift_per 
				END IF 
				IF l_rec_smparms.next_ship_code IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered.
					NEXT FIELD next_ship_code 
				END IF 
				IF l_rec_smparms.next_ship_code < 0 THEN 
					LET msgresp = kandoomsg("L",9035,"") 
					#9035 Shipment code must be greatet than OR equal TO zero.
					NEXT FIELD next_ship_code 
				END IF 
				IF l_rec_smparms.next_recpt_num IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered.
					NEXT FIELD next_recpt_num 
				END IF 
				IF l_rec_smparms.next_recpt_num < 0 THEN 
					LET msgresp = kandoomsg("L",9036,"") 
					#9036 Next receipt number must be equal TO OR greater than zero.
					NEXT FIELD next_recpt_num 
				END IF 
				IF (l_rec_smparms.direct_print_flag <> "Y" 
				AND l_rec_smparms.direct_print_flag <> "N") 
				OR l_rec_smparms.direct_print_flag IS NULL THEN 
					LET msgresp = kandoomsg("U",1026,"") 
					#1026 Valid VALUES are (Y)es OR (N)o.
					NEXT FIELD direct_print_flag 
				END IF 
				IF l_rec_smparms.direct_print_flag = "Y" 
				AND l_rec_smparms.print_text IS NULL THEN 
					LET msgresp = kandoomsg("U",9509,"") 
					#9509 Printer must be defined.
					NEXT FIELD print_text 
				END IF 
				IF l_rec_smparms.direct_print_flag = "Y" THEN 
					SELECT unique 1 FROM printcodes 
					WHERE print_code = l_rec_smparms.print_text 
					IF status = notfound THEN 
						LET msgresp = kandoomsg("W",9301,"") 
						#9301 Printer NOT found; Try Window.
						NEXT FIELD print_text 
					END IF 
				END IF 
				LET l_rec_smparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_rec_smparms.key_num = "1" 
			END IF 


			#      ON KEY (control-w)
			#         CALL kandoohelp("")
	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	INSERT INTO smparms VALUES (l_rec_smparms.*) 

	RETURN true 
END FUNCTION 


############################################################
# FUNCTION change_parm()
#
#
############################################################
FUNCTION change_parm() 
	DEFINE l_rec_t_smparms RECORD LIKE smparms.* 
	DEFINE l_rec_s_smparms RECORD LIKE smparms.* 
	DEFINE l_rec_smparms RECORD LIKE smparms.* 
	DEFINE l_next_ship_code LIKE smparms.next_ship_code 
	DEFINE l_next_recpt_num LIKE smparms.next_recpt_num 
	DEFINE l_temp_text CHAR(30) 
	DEFINE l_err_message CHAR(60) 

	SELECT smparms.* INTO l_rec_smparms.* FROM smparms 
	WHERE smparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND smparms.key_num = "1" 
	LET l_rec_s_smparms.* = l_rec_smparms.* 

	SELECT * INTO glob_rec_vendor.* FROM vendor 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND vend_code = l_rec_smparms.agent_vend_code 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("P",9043,"") 
		#9043 Vendor NOT found; Try Window.
	END IF 
	LET msgresp = kandoomsg("U",1070,"") 
	#1070 Enter Parameter details; OK TO continue.
	DISPLAY BY NAME l_rec_smparms.next_ship_code, 
	l_rec_smparms.next_recpt_num, 
	l_rec_smparms.stax_uplift_per, 
	l_rec_smparms.agent_vend_code, 
	glob_rec_vendor.name_text, 
	l_rec_smparms.direct_print_flag, 
	l_rec_smparms.print_text, 
	l_rec_smparms.git_acct_code, 
	l_rec_smparms.exp_git_acct_code, 
	l_rec_smparms.ord_git_acct_code, 
	l_rec_smparms.ret_git_acct_code 


	INPUT BY NAME l_rec_smparms.next_ship_code, 
	l_rec_smparms.next_recpt_num, 
	l_rec_smparms.agent_vend_code, 
	l_rec_smparms.stax_uplift_per, 
	l_rec_smparms.direct_print_flag, 
	l_rec_smparms.print_text, 
	l_rec_smparms.git_acct_code, 
	l_rec_smparms.exp_git_acct_code, 
	l_rec_smparms.ord_git_acct_code, 
	l_rec_smparms.ret_git_acct_code WITHOUT DEFAULTS 

		ON ACTION "WEB-HELP" -- albo kd-375 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) infield (agent_vend_code) 
			LET l_temp_text = show_vend(glob_rec_kandoouser.cmpy_code,l_rec_smparms.agent_vend_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_smparms.agent_vend_code = l_temp_text 
				DISPLAY BY NAME l_rec_smparms.agent_vend_code 

			END IF 
			NEXT FIELD agent_vend_code 

		ON KEY (control-b) infield (git_acct_code) 
			LET l_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_smparms.git_acct_code = l_temp_text 
				DISPLAY BY NAME l_rec_smparms.git_acct_code 

			END IF 
			NEXT FIELD git_acct_code 
		ON KEY (control-b) infield (exp_git_acct_code) 
			LET l_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_smparms.exp_git_acct_code = l_temp_text 
				DISPLAY BY NAME l_rec_smparms.exp_git_acct_code 

			END IF 
			NEXT FIELD exp_git_acct_code 

		ON KEY (control-b) infield (ord_git_acct_code) 
			LET l_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_smparms.ord_git_acct_code = l_temp_text 
				DISPLAY BY NAME l_rec_smparms.ord_git_acct_code 

			END IF 
			NEXT FIELD ord_git_acct_code 

		ON KEY (control-b) infield (ret_git_acct_code) 
			LET l_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_smparms.ret_git_acct_code = l_temp_text 
				DISPLAY BY NAME l_rec_smparms.ret_git_acct_code 

			END IF 
			NEXT FIELD ret_git_acct_code 

		ON KEY (control-b) infield (print_text) 
			LET l_temp_text = show_print(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_smparms.print_text = l_temp_text 
				DISPLAY BY NAME l_rec_smparms.print_text 

			END IF 
			NEXT FIELD print_text 

		AFTER FIELD next_ship_code 
			IF l_rec_smparms.next_ship_code != l_next_ship_code 
			OR l_rec_smparms.next_ship_code IS NULL THEN 
				SELECT max(ship_code) INTO l_next_ship_code 
				FROM shiphead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF l_rec_smparms.next_ship_code <= l_next_ship_code 
				OR l_rec_smparms.next_ship_code IS NULL THEN 
					LET msgresp = kandoomsg("L",9037,l_next_ship_code) 
					#9037 Next shipment number must be greater than XXX.
					LET l_rec_smparms.next_ship_code = l_next_ship_code + 1 
					NEXT FIELD next_ship_code 
				END IF 
			END IF 

		BEFORE FIELD next_recpt_num 
			LET l_next_recpt_num = l_rec_smparms.next_recpt_num 

		AFTER FIELD next_recpt_num 
			IF l_rec_smparms.next_recpt_num != l_next_recpt_num 
			OR l_rec_smparms.next_recpt_num IS NULL THEN 
				SELECT max(tran_num) INTO l_next_recpt_num 
				FROM poaudit 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND tran_code = "GR" 
				IF l_rec_smparms.next_recpt_num <= l_next_recpt_num 
				OR l_rec_smparms.next_recpt_num IS NULL THEN 
					LET msgresp = kandoomsg("L",9038,l_next_recpt_num) 
					#9038 Next shipment number must be greater than XXX.
					LET l_rec_smparms.next_recpt_num = l_next_recpt_num + 1 
					NEXT FIELD next_recpt_num 
				END IF 
			END IF 

		AFTER FIELD agent_vend_code 
			SELECT name_text INTO glob_rec_vendor.name_text FROM vendor 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = l_rec_smparms.agent_vend_code 
			IF status = notfound THEN 
				LET msgresp = kandoomsg("P",9043,"") 
				#9043 Vendor NOT found; Try Window.
				NEXT FIELD agent_vend_code 
			END IF 
			DISPLAY BY NAME glob_rec_vendor.name_text 

		AFTER FIELD git_acct_code 
			SELECT unique 1 FROM coa 
			WHERE coa.acct_code = l_rec_smparms.git_acct_code 
			AND coa.cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = notfound THEN 
				LET msgresp = kandoomsg("L",9030,"") 
				#9030 Account NOT found; Try Window.
				NEXT FIELD git_acct_code 
			END IF 

		AFTER FIELD exp_git_acct_code 
			SELECT unique 1 FROM coa 
			WHERE coa.acct_code = l_rec_smparms.exp_git_acct_code 
			AND coa.cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = notfound THEN 
				LET msgresp = kandoomsg("L",9030,"") 
				#9030 Account NOT found; Try Window.
				NEXT FIELD exp_git_acct_code 
			END IF 

		AFTER FIELD ord_git_acct_code 
			SELECT unique 1 FROM coa 
			WHERE coa.acct_code = l_rec_smparms.ord_git_acct_code 
			AND coa.cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = notfound THEN 
				LET msgresp = kandoomsg("L",9030,"") 
				#9030 Account NOT found; Try Window.
				NEXT FIELD ord_git_acct_code 
			END IF 
		AFTER FIELD ret_git_acct_code 
			SELECT unique 1 FROM coa 
			WHERE coa.acct_code = l_rec_smparms.ret_git_acct_code 
			AND coa.cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = notfound THEN 
				LET msgresp = kandoomsg("L",9030,"") 
				#9030 Account NOT found; Try Window.
				NEXT FIELD ret_git_acct_code 
			END IF 

		AFTER FIELD stax_uplift_per 
			IF l_rec_smparms.stax_uplift_per IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered.
				NEXT FIELD stax_uplift_per 
			END IF 
			IF l_rec_smparms.stax_uplift_per < 0 THEN 
				LET msgresp = kandoomsg("L",9034,"") 
				#9034 Sales Tax Uplift must be greater than OR equal TO zero.
				NEXT FIELD stax_uplift_per 
			END IF 

		AFTER FIELD direct_print_flag 
			IF (l_rec_smparms.direct_print_flag <> "Y" 
			AND l_rec_smparms.direct_print_flag <> "N" ) 
			OR l_rec_smparms.direct_print_flag IS NULL THEN 
				LET msgresp = kandoomsg("U",1026,"") 
				#1026 Valid VALUES are (Y)es OR (N)o.
				NEXT FIELD direct_print_flag 
			END IF 

		BEFORE FIELD print_text 
			IF l_rec_smparms.direct_print_flag <> "Y" THEN 
				IF fgl_lastkey() = fgl_keyval("up") 
				OR fgl_lastkey() = fgl_keyval("left") THEN 
					NEXT FIELD direct_print_flag 
				ELSE 
					NEXT FIELD git_acct_code 
				END IF 
			END IF 


		AFTER FIELD print_text 
			IF l_rec_smparms.direct_print_flag = "Y" 
			AND l_rec_smparms.print_text IS NULL THEN 
				LET msgresp = kandoomsg("U",9509,"") 
				#9509 Printer must be defined.
				NEXT FIELD print_text 
			END IF 
			SELECT unique 1 FROM printcodes 
			WHERE print_code = l_rec_smparms.print_text 
			IF status = notfound THEN 
				LET msgresp = kandoomsg("W",9301,"") 
				#9301 Printer NOT found; Try Window.
				NEXT FIELD print_text 
			END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				SELECT name_text INTO glob_rec_vendor.name_text FROM vendor 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND vend_code = l_rec_smparms.agent_vend_code 
				IF status = notfound THEN 
					LET msgresp = kandoomsg("P",9043,"") 
					#9043 Vendor NOT found; Try Window.
					NEXT FIELD agent_vend_code 
				END IF 
				DISPLAY BY NAME glob_rec_vendor.name_text 

				SELECT unique 1 FROM coa 
				WHERE coa.acct_code = l_rec_smparms.git_acct_code 
				AND coa.cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = notfound THEN 
					LET msgresp = kandoomsg("L",9030,"") 
					#9030 Account NOT found; Try Window.
					NEXT FIELD git_acct_code 
				END IF 
				SELECT unique 1 FROM coa 
				WHERE coa.acct_code = l_rec_smparms.exp_git_acct_code 
				AND coa.cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = notfound THEN 
					LET msgresp = kandoomsg("L",9030,"") 
					#9030 Account NOT found; Try Window.
					NEXT FIELD exp_git_acct_code 
				END IF 
				SELECT unique 1 FROM coa 
				WHERE coa.acct_code = l_rec_smparms.ord_git_acct_code 
				AND coa.cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = notfound THEN 
					LET msgresp = kandoomsg("L",9030,"") 
					#9030 Account NOT found; Try Window.
					NEXT FIELD ord_git_acct_code 
				END IF 
				SELECT unique 1 FROM coa 
				WHERE coa.acct_code = l_rec_smparms.ret_git_acct_code 
				AND coa.cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = notfound THEN 
					LET msgresp = kandoomsg("L",9030,"") 
					#9030 Account NOT found; Try Window.
					NEXT FIELD ret_git_acct_code 
				END IF 
				IF l_rec_smparms.stax_uplift_per IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered.
					NEXT FIELD stax_uplift_per 
				END IF 
				IF l_rec_smparms.stax_uplift_per < 0 THEN 
					LET msgresp = kandoomsg("L",9034,"") 
					#9034 Sales Tax Uplift must be greater than OR equal TO zero.
					NEXT FIELD stax_uplift_per 
				END IF 
				IF l_rec_smparms.next_ship_code IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered.
					NEXT FIELD next_ship_code 
				END IF 
				IF l_rec_smparms.next_ship_code < 0 THEN 
					LET msgresp = kandoomsg("L",9035,"") 
					#9035 Shipment code must be greatet than OR equal TO zero.
					NEXT FIELD next_ship_code 
				END IF 
				IF l_rec_smparms.next_recpt_num IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered.
					NEXT FIELD next_recpt_num 
				END IF 
				IF l_rec_smparms.next_recpt_num < 0 THEN 
					LET msgresp = kandoomsg("L",9036,"") 
					#9036 Next receipt number must be equal TO OR greater than zero.
					NEXT FIELD next_recpt_num 
				END IF 
				IF (l_rec_smparms.direct_print_flag <> "Y" 
				AND l_rec_smparms.direct_print_flag <> "N") 
				OR l_rec_smparms.direct_print_flag IS NULL THEN 
					LET msgresp = kandoomsg("U",1026,"") 
					#1026 Valid VALUES are (Y)es OR (N)o.
					NEXT FIELD direct_print_flag 
				END IF 
				IF l_rec_smparms.direct_print_flag = "Y" 
				AND l_rec_smparms.print_text IS NULL THEN 
					LET msgresp = kandoomsg("U",9509,"") 
					#9509 Printer must be defined.
					NEXT FIELD print_text 
				END IF 
				IF l_rec_smparms.direct_print_flag = "Y" THEN 
					SELECT unique 1 FROM printcodes 
					WHERE print_code = l_rec_smparms.print_text 
					IF status = notfound THEN 
						LET msgresp = kandoomsg("W",9301,"") 
						#9301 Printer NOT found; Try Window.
						NEXT FIELD print_text 
					END IF 
				END IF 
			END IF 

			#      ON KEY (control-w)
			#         CALL kandoohelp("")
	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 
	END IF 

	GOTO bypass 
	LABEL recovery: 
	IF error_recover(l_err_message, status) = "N" THEN 
		RETURN 
	END IF 

	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		LET l_err_message = "LZP - Locking Parameters Record" 
		DECLARE c_smparms CURSOR FOR 
		SELECT * FROM smparms 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND key_num = "1" 
		OPEN c_smparms 
		FETCH c_smparms INTO l_rec_t_smparms.* 
		IF l_rec_t_smparms.next_ship_code != l_rec_s_smparms.next_ship_code 
		OR l_rec_t_smparms.next_recpt_num != l_rec_s_smparms.next_recpt_num THEN 
			ROLLBACK WORK 
			LET msgresp = kandoomsg("U",7050,"") 
			#7050 Parameter VALUES have been updated since changes. ...
			RETURN 
		END IF 

		UPDATE smparms SET * = l_rec_smparms.* 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND key_num = "1" 
	COMMIT WORK 
	WHENEVER ERROR stop 
END FUNCTION 


############################################################
# FUNCTION disp_smparm()
#
#
############################################################
FUNCTION disp_smparm() 
	DEFINE l_rec_smparms RECORD LIKE smparms.* 

	CLEAR FORM 
	SELECT smparms.* INTO l_rec_smparms.* FROM smparms 
	WHERE smparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND smparms.key_num = "1" 
	IF status = notfound THEN 
		RETURN false 
	END IF 
	SELECT name_text INTO glob_rec_vendor.name_text FROM vendor 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND vend_code = l_rec_smparms.agent_vend_code 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("P",9043,"") 
		#9043 Vendor NOT found; Try Window.
	END IF 
	DISPLAY BY NAME l_rec_smparms.next_ship_code, 
	l_rec_smparms.next_recpt_num, 
	l_rec_smparms.agent_vend_code, 
	glob_rec_vendor.name_text, 
	l_rec_smparms.stax_uplift_per, 
	l_rec_smparms.direct_print_flag, 
	l_rec_smparms.print_text, 
	l_rec_smparms.git_acct_code, 
	l_rec_smparms.exp_git_acct_code, 
	l_rec_smparms.ord_git_acct_code, 
	l_rec_smparms.ret_git_acct_code 

	RETURN true 
END FUNCTION 
