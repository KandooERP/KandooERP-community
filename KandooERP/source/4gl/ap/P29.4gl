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
	Source code beautified by beautify.pl on 2020-01-03 13:41:20	$Id: $
}
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_P2_GLOBALS.4gl" 
GLOBALS "P29_GLOBALS.4gl" 
GLOBALS 
	DEFINE glob_distr_amt_option CHAR(1) 
END GLOBALS 
############################################################
# Module Scope Variables
############################################################

############################################################
# MAIN
#
# \brief module P29 - Voucher Distribution
#                   Provides scan of vouchers NOT fully distributed.
#                   On selection of voucher distribute_voucher_to_accounts (P29a) IS called
############################################################
MAIN 
	DEFINE l_withquery SMALLINT 

	#Initial UI Init
	CALL setModuleId("P29") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	LET glob_distr_amt_option = get_kandoooption_feature_state("AP", "DA") 
	CALL create_table("voucherdist","t_voucherdist","","N") 
	CALL create_table("purchdetl","t_purchdetl","","Y") 
	CALL create_table("poaudit","t_poaudit","","Y") 

	OPEN WINDOW P200 with FORM "P200" 
	CALL windecoration_p("P200") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	#if the the table has more than 1000 rows, force a query TO filter data
	IF db_voucher_get_count() > 1000 THEN 
		LET l_withquery = true 
	END IF 

	WHILE select_vouch(l_withquery) 
		LET l_withquery = scan_vouch() 
		IF l_withquery = 2 OR int_flag THEN 
			EXIT WHILE 
		END IF 
	END WHILE 

	CLOSE WINDOW p200 
END MAIN 


############################################################
# FUNCTION select_vouch()
#
#
############################################################
FUNCTION select_vouch(p_withquery) 
	DEFINE p_withquery SMALLINT 
	DEFINE l_where_text CHAR(2048) 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_msgresp LIKE language.yes_flag 

	IF p_withquery = 1 THEN 

		CLEAR FORM 
		#1001 " Enter selection criteria
		LET l_msgresp=kandoomsg("U",1001,"") 
		CONSTRUCT BY NAME l_where_text ON vouch_code, 
		vend_code, 
		vouch_date, 
		year_num, 
		period_num, 
		total_amt, 
		dist_amt 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","P29","construct-voucher-1") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_where_text = "1=1" 
		END IF 

	ELSE 
		LET l_where_text = "1=1" 
	END IF 

	# IF passed a "E" FOR edit get all vouchers  
	#Mode E=Edit changed to URL method
	IF (get_url_mode() = MODE_CLASSIC_EDIT) OR (get_url_mode() = MODE_CLASSIC_UPDATE) THEN 
	--IF arg_val(1) != "E" THEN 
		LET l_where_text = l_where_text clipped," AND total_amt != dist_amt" 
	END IF 
	
	LET l_query_text = "SELECT * FROM voucher ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND post_flag='N' ", 
	"AND ",l_where_text clipped," ", 
	"ORDER BY vouch_code" 
	
	PREPARE s_voucher FROM l_query_text 
	DECLARE c_voucher CURSOR FOR s_voucher 

	RETURN 1 

END FUNCTION 



############################################################
# FUNCTION scan_vouch()
#
#
############################################################
FUNCTION scan_vouch() 
	DEFINE l_arr_rec_voucher array[200] OF 
	RECORD 
		#scroll_flag CHAR(1),
		vouch_code LIKE voucher.vouch_code, 
		vend_code LIKE voucher.vend_code, 
		vouch_date LIKE voucher.vouch_date, 
		year_num LIKE voucher.year_num, 
		period_num LIKE voucher.period_num, 
		total_amt LIKE voucher.total_amt, 
		dist_amt LIKE voucher.dist_amt 
	END RECORD 
	DEFINE l_rec_vouchpayee RECORD LIKE vouchpayee.*
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE idx SMALLINT

	LET idx = 0 
	LET l_msgresp = kandoomsg("U",1002,"") 
	#1002 Searching Database;  Please wait.
	FOREACH c_voucher INTO glob_rec_voucher.* 
		LET idx = idx + 1 
		LET l_arr_rec_voucher[idx].vouch_code = glob_rec_voucher.vouch_code 
		LET l_arr_rec_voucher[idx].vend_code = glob_rec_voucher.vend_code 
		LET l_arr_rec_voucher[idx].vouch_date = glob_rec_voucher.vouch_date 
		LET l_arr_rec_voucher[idx].year_num = glob_rec_voucher.year_num 
		LET l_arr_rec_voucher[idx].period_num = glob_rec_voucher.period_num 
		LET l_arr_rec_voucher[idx].total_amt = glob_rec_voucher.total_amt 
		LET l_arr_rec_voucher[idx].dist_amt = glob_rec_voucher.dist_amt 
		IF idx = 200 THEN 
			LET l_msgresp=kandoomsg("P",9006,idx) 
			#9006 First 200 Vouchers selected.
			EXIT FOREACH 
		END IF 
	END FOREACH 
	CALL set_count(idx) 
	IF idx = 0 THEN 
		LET l_msgresp=kandoomsg("P",9007,"") 
		#9007 No Vouchers selected.
		RETURN 1 
	ELSE 
		LET l_msgresp=kandoomsg("P",1010,"") 
		#1010 Press RETURN on line TO distribute voucher.
		OPTIONS INSERT KEY f36, 
		DELETE KEY f36 
		#INPUT ARRAY l_arr_rec_voucher WITHOUT DEFAULTS FROM sr_voucher.*
		DISPLAY ARRAY l_arr_rec_voucher TO sr_voucher.* 

			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","P29","inp-arr-voucher-1") 

			ON ACTION "FILTER" 
				RETURN 1 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				LET idx = arr_curr() 
				#LET scrn = scr_line()
				#DISPLAY l_arr_rec_voucher[idx].* TO sr_voucher[scrn].*

			ON ACTION ("DOUBLECLICK","Distribute") 
				#AFTER FIELD scroll_flag
				#			IF fgl_lastkey() = fgl_keyval("down") THEN
				#		    IF arr_curr() = arr_count() THEN
				#		       LET l_msgresp=kandoomsg("U",9001,"")
				#		       #9001 There are no more rows in the direction ...
				#		       NEXT FIELD scroll_flag
				#		    ELSE
				#		       IF l_arr_rec_voucher[idx+1].vend_code IS NULL THEN
				#		          LET l_msgresp=kandoomsg("U",9001,"")
				#		          #9001 There are no more rows in the direction ...
				#		          NEXT FIELD scroll_flag
				#		       END IF
				#		    END IF
				#			END IF
				#         BEFORE FIELD vouch_code
				SELECT * INTO glob_rec_voucher.* 
				FROM voucher 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND vend_code = l_arr_rec_voucher[idx].vend_code 
				AND vouch_code = l_arr_rec_voucher[idx].vouch_code 
				IF status = 0 THEN 
					OPEN WINDOW P169 with FORM "P169" 
					CALL windecoration_p("P169") 
					LET l_msgresp=kandoomsg("U",1002,"") 
					#1002 Searching database - please wait
					DELETE FROM t_voucherdist 
					INSERT INTO t_voucherdist SELECT * FROM voucherdist 
					WHERE cmpy_code =glob_rec_kandoouser.cmpy_code 
					AND vouch_code=glob_rec_voucher.vouch_code 
					WHILE distribute_voucher_to_accounts(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,glob_rec_voucher.*) 

						IF glob_distr_amt_option = "Y" 
						AND glob_rec_voucher.dist_amt <> glob_rec_voucher.total_amt THEN 
							LET l_msgresp = kandoomsg("P", 1054, "") 
							#Distribution amount <> Total amount?
							IF l_msgresp = "N" THEN 
								LET quit_flag = true 
							END IF 
						END IF 

						IF glob_distr_amt_option = "N" 
						OR glob_rec_voucher.dist_amt = glob_rec_voucher.total_amt 
						OR l_msgresp = "Y" THEN 

							MENU" Distributions" 

								BEFORE MENU 
									CALL publish_toolbar("kandoo","P29","menu-distributions-1") 

								ON ACTION "WEB-HELP" 
									CALL onlinehelp(getmoduleid(),null) 

								ON ACTION "actToolbarManager" 
									CALL setuptoolbar() 

								ON ACTION "SAVE" #COMMAND "Save" " Commit distributions TO database" 
									IF update_voucher_related_tables(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,"3",glob_rec_voucher.*, 
									l_rec_vouchpayee.*) <= 0 THEN 
										IF promptTF("Save Error",kandoomsg2("P",8010,""),1) THEN  #8010" Error detected during Save - Re-Edit (Y/N)
 											LET quit_flag = true 
										END IF 
									END IF 
									EXIT MENU 
									
								ON ACTION "CANCEL" #COMMAND "Discard" " EXIT PROGRAMs without saving changes" 
									EXIT MENU
									 
								COMMAND KEY(interrupt)"Review" " Review Changes" 
									LET quit_flag = true 
									EXIT MENU 

							END MENU 

						END IF 

						IF int_flag OR quit_flag THEN 
							LET int_flag = false 
							LET quit_flag = false 
						ELSE 
							EXIT WHILE 
						END IF 

					END WHILE
					 
					CLOSE WINDOW P169
					 
					SELECT dist_amt INTO l_arr_rec_voucher[idx].dist_amt 
					FROM voucher 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND vend_code = l_arr_rec_voucher[idx].vend_code 
					AND vouch_code = l_arr_rec_voucher[idx].vouch_code
					 
					OPTIONS INSERT KEY f36, 
					DELETE KEY f36
					 
				END IF 
				#            NEXT FIELD scroll_flag
				#         AFTER ROW
				#            DISPLAY l_arr_rec_voucher[idx].*
				#                 TO sr_voucher[scrn].*


		END DISPLAY
		 
	END IF 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 2 
	END IF 

END FUNCTION