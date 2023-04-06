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
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS 
	DEFINE glob_rec_arparms RECORD LIKE arparms.* 
	DEFINE glob_rec_ssparms RECORD LIKE ssparms.* 
	DEFINE glob_rec_mbparms RECORD LIKE mbparms.* 
	DEFINE glob_rec_jmparms RECORD LIKE jmparms.* 
	DEFINE glob_temp_text VARCHAR(200) 
END GLOBALS 


#######################################################################
# MAIN
#
# Purpose - Automatic Transaction Numbering
#           Allows the user TO maintain the automatic
#           transaction numbering
#######################################################################
MAIN 
	DEFINE l_msgresp LIKE language.yes_flag 

	DEFER quit 
	DEFER interrupt 

	#Initial UI Init
	CALL setModuleId("GZD") 
	CALL ui_init(0) #initial ui init 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 


	#SELECT * INTO glob_rec_company.*
	#   FROM company
	#   WHERE cmpy_code = glob_rec_kandoouser.cmpy_code

	IF status = NOTFOUND THEN 
		ERROR kandoomsg2("U",5100,"")		#5100 Company Not Set Up;  Refer TO System Administrator.
		EXIT PROGRAM 
	END IF 

	SELECT * INTO glob_rec_arparms.* FROM arparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 

	IF status = NOTFOUND THEN 
		ERROR kandoomsg2("G",5001,"") 	#5001 AR Parameters Not Set Up;  Refer Menu AZP.
		CALL fgl_winmessage("AR Parameters Not Set Up - AZP","AR Parameters Not Set Up\nRefer TO Menu AZP\nExit Application","error") 
		EXIT PROGRAM 
	END IF 

	OPEN WINDOW G110 with FORM "G110" 
	CALL windecoration_g("G110") 

	CALL anumwind()

{
	MENU " Automatic Numbering" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","GZD","transactionMainMenu") 
			#CALL fgl_dialog_setkeylabel("D", "Detail","",0,0, "Enter transaction numbers")
			#CALL fgl_dialog_setkeylabel("E", "Exit","",0,0, "Exit")
			CALL anumwind() 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "Settings" #COMMAND KEY ("D",f20) "Detail" " Enter transaction numbers" 
			CALL anumwind() 

		ON ACTION "Exit" 
			EXIT MENU 

	END MENU
} 
END MAIN 
#######################################################################
# END MAIN
#######################################################################


#######################################################################
# FUNCTION anumwind_data_source() 
#
#
#######################################################################
FUNCTION anumwind_data_source() 
	DEFINE l_arr_rec_anummenu DYNAMIC ARRAY OF RECORD #array[25] OF RECORD 
		scroll_flag CHAR(1), 
		option_num CHAR(1), 
		option_text CHAR(30) 
	END RECORD 
	DEFINE l_counter SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	FOR l_counter = 1 TO 12 
		CASE l_counter 
			WHEN "1" # credits 
				LET l_idx = l_idx + 1 
				LET l_arr_rec_anummenu[l_idx].option_num = "1" 
				LET l_arr_rec_anummenu[l_idx].option_text = kandooword("anumwind","1") 
			WHEN "2" # invoices 
				LET l_idx = l_idx + 1 
				LET l_arr_rec_anummenu[l_idx].option_num = "2" 
				LET l_arr_rec_anummenu[l_idx].option_text = kandooword("anumwind","2") 
			WHEN "3" # receipts 
				LET l_idx = l_idx + 1 
				LET l_arr_rec_anummenu[l_idx].option_num = "3" 
				LET l_arr_rec_anummenu[l_idx].option_text = kandooword("anumwind","3") 
			WHEN "4" # contracts 
				LET l_idx = l_idx + 1 
				LET l_arr_rec_anummenu[l_idx].option_num = "4" 
				LET l_arr_rec_anummenu[l_idx].option_text = kandooword("anumwind","4") 
			WHEN "5" # batches 
				LET l_idx = l_idx + 1 
				LET l_arr_rec_anummenu[l_idx].option_num = "5" 
				LET l_arr_rec_anummenu[l_idx].option_text = kandooword("anumwind","5") 
			WHEN "6" # jobs 
				IF glob_rec_company.module_text[10] != "J" THEN 
					CONTINUE FOR 
				END IF 
				LET l_idx = l_idx + 1 
				LET l_arr_rec_anummenu[l_idx].option_num = "6" 
				LET l_arr_rec_anummenu[l_idx].option_text = kandooword("anumwind","6") 
			WHEN "7" # customers 
				IF get_kandoooption_feature_state("AR","CN") != "Y" THEN 
					CONTINUE FOR 
				END IF 
				LET l_idx = l_idx + 1 
				LET l_arr_rec_anummenu[l_idx].option_num = "7" 
				LET l_arr_rec_anummenu[l_idx].option_text = kandooword("anumwind","7") 
			WHEN "8" # subscriptions 
				IF glob_rec_company.module_text[11] != "K" THEN 
					CONTINUE FOR 
				END IF 
				LET l_idx = l_idx + 1 
				LET l_arr_rec_anummenu[l_idx].option_num = "8" 
				LET l_arr_rec_anummenu[l_idx].option_text = kandooword("anumwind","8") 
			WHEN "9" # orders 
				IF glob_rec_company.module_text[23] != "W" THEN 
					CONTINUE FOR 
				END IF 
				LET l_idx = l_idx + 1 
				LET l_arr_rec_anummenu[l_idx].option_num = "9" 
				LET l_arr_rec_anummenu[l_idx].option_text = kandooword("anumwind","9") 
			WHEN "10" # loads 
				IF glob_rec_company.module_text[23] != "W" THEN 
					CONTINUE FOR 
				END IF 
				LET l_idx = l_idx + 1 
				LET l_arr_rec_anummenu[l_idx].option_num = "A" 
				LET l_arr_rec_anummenu[l_idx].option_text = kandooword("anumwind","A") 
			WHEN "11" # deliveries 
				IF glob_rec_company.module_text[23] != "W" THEN 
					CONTINUE FOR 
				END IF 
				LET l_idx = l_idx + 1 
				LET l_arr_rec_anummenu[l_idx].option_num = "B" 
				LET l_arr_rec_anummenu[l_idx].option_text = kandooword("anumwind","B") 
			WHEN "12" # transport 
				IF glob_rec_company.module_text[23] != "W" THEN 
					CONTINUE FOR 
				END IF 
				LET l_idx = l_idx + 1 
				LET l_arr_rec_anummenu[l_idx].option_num = "C" 
				LET l_arr_rec_anummenu[l_idx].option_text = kandooword("anumwind","C") 
		END CASE 
	END FOR 
	
	RETURN l_arr_rec_anummenu
END FUNCTION
#######################################################################
# END FUNCTION anumwind_data_source() 
#######################################################################


#######################################################################
# FUNCTION anumwind()
#
#
#######################################################################
FUNCTION anumwind() 
	DEFINE l_arr_rec_anummenu DYNAMIC ARRAY OF RECORD #array[25] OF RECORD 
		scroll_flag CHAR(1), 
		option_num CHAR(1), 
		option_text CHAR(30) 
	END RECORD 
	DEFINE l_counter SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 
{
	FOR l_counter = 1 TO 12 
		CASE l_counter 
			WHEN "1" # credits 
				LET l_idx = l_idx + 1 
				LET l_arr_rec_anummenu[l_idx].option_num = "1" 
				LET l_arr_rec_anummenu[l_idx].option_text = kandooword("anumwind","1") 
			WHEN "2" # invoices 
				LET l_idx = l_idx + 1 
				LET l_arr_rec_anummenu[l_idx].option_num = "2" 
				LET l_arr_rec_anummenu[l_idx].option_text = kandooword("anumwind","2") 
			WHEN "3" # receipts 
				LET l_idx = l_idx + 1 
				LET l_arr_rec_anummenu[l_idx].option_num = "3" 
				LET l_arr_rec_anummenu[l_idx].option_text = kandooword("anumwind","3") 
			WHEN "4" # contracts 
				LET l_idx = l_idx + 1 
				LET l_arr_rec_anummenu[l_idx].option_num = "4" 
				LET l_arr_rec_anummenu[l_idx].option_text = kandooword("anumwind","4") 
			WHEN "5" # batches 
				LET l_idx = l_idx + 1 
				LET l_arr_rec_anummenu[l_idx].option_num = "5" 
				LET l_arr_rec_anummenu[l_idx].option_text = kandooword("anumwind","5") 
			WHEN "6" # jobs 
				IF glob_rec_company.module_text[10] != "J" THEN 
					CONTINUE FOR 
				END IF 
				LET l_idx = l_idx + 1 
				LET l_arr_rec_anummenu[l_idx].option_num = "6" 
				LET l_arr_rec_anummenu[l_idx].option_text = kandooword("anumwind","6") 
			WHEN "7" # customers 
				IF get_kandoooption_feature_state("AR","CN") != "Y" THEN 
					CONTINUE FOR 
				END IF 
				LET l_idx = l_idx + 1 
				LET l_arr_rec_anummenu[l_idx].option_num = "7" 
				LET l_arr_rec_anummenu[l_idx].option_text = kandooword("anumwind","7") 
			WHEN "8" # subscriptions 
				IF glob_rec_company.module_text[11] != "K" THEN 
					CONTINUE FOR 
				END IF 
				LET l_idx = l_idx + 1 
				LET l_arr_rec_anummenu[l_idx].option_num = "8" 
				LET l_arr_rec_anummenu[l_idx].option_text = kandooword("anumwind","8") 
			WHEN "9" # orders 
				IF glob_rec_company.module_text[23] != "W" THEN 
					CONTINUE FOR 
				END IF 
				LET l_idx = l_idx + 1 
				LET l_arr_rec_anummenu[l_idx].option_num = "9" 
				LET l_arr_rec_anummenu[l_idx].option_text = kandooword("anumwind","9") 
			WHEN "10" # loads 
				IF glob_rec_company.module_text[23] != "W" THEN 
					CONTINUE FOR 
				END IF 
				LET l_idx = l_idx + 1 
				LET l_arr_rec_anummenu[l_idx].option_num = "A" 
				LET l_arr_rec_anummenu[l_idx].option_text = kandooword("anumwind","A") 
			WHEN "11" # deliveries 
				IF glob_rec_company.module_text[23] != "W" THEN 
					CONTINUE FOR 
				END IF 
				LET l_idx = l_idx + 1 
				LET l_arr_rec_anummenu[l_idx].option_num = "B" 
				LET l_arr_rec_anummenu[l_idx].option_text = kandooword("anumwind","B") 
			WHEN "12" # transport 
				IF glob_rec_company.module_text[23] != "W" THEN 
					CONTINUE FOR 
				END IF 
				LET l_idx = l_idx + 1 
				LET l_arr_rec_anummenu[l_idx].option_num = "C" 
				LET l_arr_rec_anummenu[l_idx].option_text = kandooword("anumwind","C") 
		END CASE 
	END FOR 
}
	OPEN WINDOW g555 with FORM "G555" 
	CALL windecoration_g("G555") 

	CALL anumwind_data_source() RETURNING l_arr_rec_anummenu

	#   CALL set_count(l_idx)
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36
	 
	MESSAGE kandoomsg2("A",1030,"") #1030 Enter TO SELECT Option.
	#INPUT ARRAY l_arr_rec_anummenu WITHOUT DEFAULTS FROM sr_anummenu.* ATTRIBUTE(UNBUFFERED)
	DISPLAY ARRAY l_arr_rec_anummenu TO sr_anummenu.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","GZD","transactionNumMenu") 
			CALL dialog.setActionHidden("ACCEPT",TRUE)

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "REFRESH"
			CALL anumwind_data_source() RETURNING l_arr_rec_anummenu

		BEFORE ROW 
			LET l_idx = arr_curr()
			LET l_arr_rec_anummenu[l_idx].scroll_flag = "*"
			
		AFTER ROW			
			LET l_arr_rec_anummenu[l_idx].scroll_flag = NULL 
			 
			#LET scrn = scr_line()
			#DISPLAY l_arr_rec_anummenu[l_idx].*
			#     TO sr_anummenu[scrn].*

			#AFTER FIELD scroll_flag
			#        IF l_arr_rec_anummenu[l_idx].scroll_flag IS NULL THEN
			#           IF fgl_lastkey() = fgl_keyval("down")
			#           AND arr_curr() = arr_count() THEN
			#              ERROR kandoomsg2("A",9001,"")
			#              NEXT FIELD scroll_flag
			#           END IF
			#        END IF

			#BEFORE FIELD option_num
			#        IF l_arr_rec_anummenu[l_idx].scroll_flag IS NULL THEN
			#           LET l_arr_rec_anummenu[l_idx].scroll_flag = l_arr_rec_anummenu[l_idx].option_num
			#        ELSE
			#           LET l_counter = 1
			#           WHILE (l_arr_rec_anummenu[l_idx].scroll_flag IS NOT NULL)
			#              IF l_arr_rec_anummenu[l_counter].option_num IS NULL THEN
			#                 LET l_arr_rec_anummenu[l_idx].scroll_flag = NULL
			#              ELSE
			#                 IF l_arr_rec_anummenu[l_idx].scroll_flag=
			#                    l_arr_rec_anummenu[l_counter].option_num THEN
			#                    EXIT WHILE
			#                 END IF
			#              END IF
			#              LET l_counter = l_counter + 1
			#           END WHILE
			#        END IF
			#

		ON ACTION ("EDIT","ACCEPT","doubleClick") 
			CURRENT WINDOW IS G110 

			CASE l_arr_rec_anummenu[l_idx].option_num --scroll_flag 

				WHEN "1" ### credits 
					SELECT * INTO glob_rec_arparms.* FROM arparms 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND parm_code = "1" 
					CALL upd_number(TRAN_TYPE_CREDIT_CR,glob_rec_arparms.nextcredit_num) 

				WHEN "2" ### invoices 
					SELECT * INTO glob_rec_arparms.* FROM arparms 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND parm_code = "1" 
					CALL upd_number(TRAN_TYPE_INVOICE_IN,glob_rec_arparms.nextinv_num) 

				WHEN "3" ### receipts 
					SELECT * INTO glob_rec_arparms.* FROM arparms 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND parm_code = "1" 
					CALL upd_number(TRAN_TYPE_RECEIPT_CA,glob_rec_arparms.nextcash_num) 

				WHEN "4" ### contracts 
					SELECT * INTO glob_rec_jmparms.* FROM jmparms 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND key_code = "1" 
					IF status = NOTFOUND THEN 
						ERROR kandoomsg2("G",5010,"") 			#5010 JM Parameters Not Set Up;  Refer Menu JZP.
					ELSE 
						CALL upd_number(TRAN_TYPE_CONTRACT_CON, glob_rec_jmparms.nextcontract_num) 
					END IF 

				WHEN "5" ### batches 
					SELECT unique(1) FROM apparms 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND parm_code = "1" 
					IF status = NOTFOUND THEN 
						ERROR kandoomsg2("G",5116,"") 				#5116 AP Parameters Not Set Up;  Refer Menu PZP.
					ELSE 
						CALL upd_number(TRAN_TYPE_BATCH_BAT,1) 
					END IF 

				WHEN "6" ### jobs 
					SELECT * INTO glob_rec_jmparms.* FROM jmparms 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND key_code = "1" 
					IF status = NOTFOUND THEN 
						ERROR kandoomsg2("G",5010,"") 				#5010 JM Parameters Not Set Up;  Refer Menu JZP.
					ELSE 
						IF glob_rec_jmparms.nextjob_num = 0 THEN 
							CALL upd_number(TRAN_TYPE_JOB_JOB,0) 
						ELSE 
							SELECT unique(1) FROM nextnumber 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND tran_type_ind = TRAN_TYPE_JOB_JOB 
							AND flex_code = "POSITIONS" 
							AND next_num != 0 
							IF status = NOTFOUND THEN 
								CALL upd_number(TRAN_TYPE_JOB_JOB,1) 
							ELSE 
								CALL upd_number(TRAN_TYPE_JOB_JOB,2) 
							END IF 
						END IF 
					END IF 

				WHEN "7" ### Customers" 
					SELECT * INTO glob_rec_arparms.* FROM arparms 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND parm_code = "1" 
					CALL upd_number(TRAN_TYPE_CUSTOMER_CUS,1) 

				WHEN "8" ### Subscriptions" 
					SELECT * INTO glob_rec_ssparms.* FROM ssparms 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF status = NOTFOUND THEN 
						ERROR kandoomsg2("K",5001,"") 	#5001 SS Parameters Not Set Up;  Refer Menu KZP.
					ELSE 
						CALL upd_number("SS",glob_rec_ssparms.next_sub_num) 
					END IF 

				WHEN "9" ### orders 
					SELECT * INTO glob_rec_mbparms.* FROM mbparms 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF status = NOTFOUND THEN 
						ERROR kandoomsg2("W",5006,"") 		#5006 Max Brick Parameters NOT SET up;  Refer Menu WZP.
					ELSE 
						CALL upd_number(TRAN_TYPE_ORDER_ORD,1) 
					END IF 

				WHEN "A" ### loads 
					SELECT * INTO glob_rec_mbparms.* FROM mbparms 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF status = NOTFOUND THEN 
						ERROR kandoomsg2("W",5006,"") 		#5006 Max Brick Parameters NOT SET up;  Refer Menu WZP.
					ELSE 
						CALL upd_number(TRAN_TYPE_LOAD_LNO,1) 
					END IF 

				WHEN "B" ### deliveries 
					SELECT * INTO glob_rec_mbparms.* FROM mbparms 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF status = NOTFOUND THEN 
						ERROR kandoomsg2("W",5006,"") 		#5006 Max Brick Parameters NOT SET up;  Refer Menu WZP.
					ELSE 
						CALL upd_number(TRAN_TYPE_DELIVERY_DLV,1) 
					END IF 

				WHEN "C" ### transport 
					SELECT * INTO glob_rec_mbparms.* FROM mbparms 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF status = NOTFOUND THEN 
						ERROR kandoomsg2("W",5006,"") 	#5006 Max Brick Parameters NOT SET up;  Refer Menu WZP.
					ELSE 
						CALL upd_number(TRAN_TYPE_TRANSPORT_TRN,1) 
					END IF 

				OTHERWISE 
					ERROR kandoomsg2("U",9940,"") 	#9940 This option IS NOT available.
			END CASE 

			CURRENT WINDOW IS g555 

			OPTIONS INSERT KEY f36, 
			DELETE KEY f36 

			LET l_arr_rec_anummenu[l_idx].scroll_flag = NULL 
			#NEXT FIELD scroll_flag
			#AFTER ROW
			#   DISPLAY l_arr_rec_anummenu[l_idx].*
			#        TO sr_anummenu[scrn].*

	END DISPLAY 

	LET int_flag = false 
	LET quit_flag = false 

	CLOSE WINDOW G555 

END FUNCTION 
#######################################################################
# FUNCTION anumwind()
#######################################################################


#######################################################################
# FUNCTION upd_prefixs(p_tran_type)
#
#
#######################################################################
FUNCTION upd_prefixs(p_tran_type) 
	DEFINE p_tran_type LIKE nextnumber.tran_type_ind 
	DEFINE l_arr_rec_format array[3] OF 
	RECORD 
		start_num LIKE structure.start_num, 
		length_num LIKE structure.length_num, 
		desc_text LIKE structure.desc_text 
	END RECORD 
	DEFINE l_seg_length SMALLINT 
	DEFINE l_start_char CHAR(2) 
	DEFINE l_next_char CHAR(6) 
	DEFINE l_next_num INTEGER 
	DEFINE i INTEGER 
	DEFINE j INTEGER 
	DEFINE l_idx INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 

	SELECT next_num INTO l_next_num 
	FROM nextnumber 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tran_type_ind = p_tran_type 
	AND flex_code = "POSITIONS" 

	IF status = NOTFOUND THEN 
		LET l_next_num = 0 
	END IF 

	FOR i = 1 TO 3 
		LET l_arr_rec_format[i].start_num = 0 
	END FOR 

	LET l_idx = 1 
	LET j = 0-l_next_num 

	FOR i = 2 TO 0 step -1 
		LET l_arr_rec_format[l_idx].start_num = j / (100 ** i) 
		LET j = j mod (100 ** i) 

		IF l_arr_rec_format[l_idx].start_num > 0 THEN 
			SELECT 
				length_num, 
				desc_text 
			INTO 
				l_arr_rec_format[l_idx].length_num, 
				l_arr_rec_format[l_idx].desc_text 
			FROM structure 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND start_num = l_arr_rec_format[l_idx].start_num 
			AND type_ind = "S" 
			IF status = NOTFOUND THEN 
				INITIALIZE l_arr_rec_format[l_idx].* TO NULL 
			END IF 
			LET l_idx = l_idx + 1 
		END IF 

	END FOR 

	CALL set_count(l_idx-1) 
	INPUT ARRAY l_arr_rec_format WITHOUT DEFAULTS FROM sr_format.* attribute(UNBUFFERED, auto append = false, append ROW = false, DELETE ROW = false, INSERT ROW = false) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GZD","transation2") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			#LET scrn = scr_line()

		AFTER FIELD start_num 
			IF l_arr_rec_format[l_idx].start_num IS NULL THEN 
				INITIALIZE l_arr_rec_format[l_idx].* TO NULL 
			ELSE 
				SELECT 
					start_num, 
					length_num, 
					desc_text 
				INTO l_arr_rec_format[l_idx].* 
				FROM structure 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND start_num = l_arr_rec_format[l_idx].start_num 
				AND type_ind = "S" 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("G",9014,"") 			#9014" No segments Exist with this Starting Position "
					INITIALIZE l_arr_rec_format[l_idx].* TO NULL 
				END IF 
			END IF 
			#DISPLAY l_arr_rec_format[l_idx].*
			#     TO sr_format[scrn].*

		BEFORE FIELD length_num 
			NEXT FIELD start_num 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				LET l_next_char = "" 
				LET l_seg_length = 0 
				FOR i = 1 TO 3 
					IF l_arr_rec_format[i].length_num > 0 THEN 
						LET l_seg_length = l_seg_length 
						+ l_arr_rec_format[i].length_num 
						LET l_start_char = l_arr_rec_format[i].start_num USING "<<" 
						IF length(l_start_char) = 1 THEN 
							LET l_start_char = "0",l_start_char clipped 
						END IF 
						LET l_next_char = l_next_char clipped,l_start_char 
					END IF 
				END FOR 

				IF l_seg_length = 0 THEN 
					ERROR kandoomsg2("G",9015,"") 			#9015" No Segments Defined FOR Prefixing"
					NEXT FIELD start_num 
				END IF 
				IF l_seg_length >= 8 THEN 
					ERROR kandoomsg2("G",9016,"") 			#9016" A/C segment length > trans number length "
					NEXT FIELD start_num 
				END IF 
				
				IF enter_prefix(
					p_tran_type, 
					l_arr_rec_format[1].start_num, 
					l_arr_rec_format[2].start_num, 
					l_arr_rec_format[3].start_num) THEN 
					
					LET l_next_num = l_next_char clipped 
				ELSE 
					NEXT FIELD start_num 
				END IF 
			END IF 

			#      ON KEY (control-w)
			#         CALL kandoohelp("")

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 
		LET l_next_num = 0 - l_next_num 
		UPDATE nextnumber 
		SET next_num = l_next_num 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND tran_type_ind = p_tran_type 
		AND flex_code = "POSITIONS" 

		IF sqlca.sqlerrd[3] = 0 THEN 
			INSERT INTO nextnumber 
			VALUES (glob_rec_kandoouser.cmpy_code,p_tran_type,"POSITIONS",l_next_num,"N") 
		END IF 
	END IF 

END FUNCTION 
#######################################################################
# END FUNCTION upd_prefixs(p_tran_type)
#######################################################################


#######################################################################
# FUNCTION upd_prog(p_tran_type)
#
#
#######################################################################
FUNCTION upd_prog(p_tran_type) 
	DEFINE p_tran_type LIKE nextnumber.tran_type_ind 
	DEFINE l_arr_rec_program DYNAMIC ARRAY OF RECORD #array[30] OF RECORD 
		prog LIKE nextnumber.flex_code, 
		alloc_ind CHAR(1), 
		next_num LIKE nextnumber.next_num 
	END RECORD 
	DEFINE l_rec_program RECORD 
		prog LIKE nextnumber.flex_code, 
		alloc_ind LIKE nextnumber.alloc_ind, 
		next_num LIKE nextnumber.next_num 
	END RECORD 
	DEFINE l_rec_s_program RECORD 
		prog LIKE nextnumber.flex_code, 
		alloc_ind LIKE nextnumber.alloc_ind, 
		next_num LIKE nextnumber.next_num 
	END RECORD 
	DEFINE l_idx INTEGER 
	DEFINE i INTEGER 
	DEFINE j INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET glob_temp_text = 
	" INSERT INTO nextnumber VALUES (?,?,?,?,?)" 
	PREPARE s_insprog FROM glob_temp_text 
	DECLARE c2_nextnumber CURSOR FOR 

	SELECT flex_code,alloc_ind ,next_num 
	FROM nextnumber 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tran_type_ind = p_tran_type 
	AND flex_code != "PROGRAM" 
	AND flex_code != "NEXTNUMBER" 
	AND flex_code != "POSITIONS" 

	LET l_idx = 1 
	FOREACH c2_nextnumber INTO l_rec_program.* 
		LET l_arr_rec_program[l_idx].* = l_rec_program.* 
		IF l_idx > 29 THEN 
			ERROR kandoomsg2("G",9191,l_idx) 		#9191 "First 30 programs selected only
			EXIT FOREACH 
		END IF 
		LET l_idx = l_idx + 1 
	END FOREACH 

	CALL set_count(l_idx-1) 
	SELECT flex_code,alloc_ind,next_num INTO l_rec_program.* 
	FROM nextnumber 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tran_type_ind = p_tran_type 
	AND flex_code = "PROGRAM" 
	IF sqlca.sqlcode = NOTFOUND THEN 
		INSERT INTO nextnumber 
		VALUES (glob_rec_kandoouser.cmpy_code,p_tran_type,"PROGRAM",1,"N") 
		LET l_rec_program.next_num = 1 
	END IF 

	LET l_rec_program.prog = "Default Next Number" 

	OPEN WINDOW G538 with FORM "G538" 
	CALL windecoration_g("G538") 

	MESSAGE kandoomsg2("G",1503,"") #1503 " Enter Default next number - ESC TO Continue"

	INPUT l_rec_program.next_num WITHOUT DEFAULTS FROM def_nextnum 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GZD","transation3") 
			LET l_rec_s_program.next_num = l_rec_program.next_num 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD def_nextnum 
			IF l_rec_program.next_num IS NULL 
			OR l_rec_program.next_num < 0 THEN 
				LET l_rec_program.next_num = l_rec_s_program.next_num 
				DISPLAY l_rec_program.next_num TO def_nextnum 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 
		ERROR kandoomsg2("G",1004,"") #1004 " F1 TO Add - F2 TO Delete - ESC TO Continue"
		INPUT ARRAY l_arr_rec_program WITHOUT DEFAULTS FROM sr_nextnumber.* ATTRIBUTE(UNBUFFERED) 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","GZD","transation4") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				#LET scrn = scr_line()

			AFTER FIELD prog 
				IF l_arr_rec_program[l_idx].prog = "NEXTNUMBER" 
				OR l_arr_rec_program[l_idx].prog = "POSITIONS" 
				OR l_arr_rec_program[l_idx].prog = "PROGRAM" THEN 
					ERROR kandoomsg2("G",9189,"") 	#9189 "Invalid program entered"
					NEXT FIELD prog 
				END IF 
				FOR i = 1 TO arr_count() 
					IF i != l_idx 
					AND l_arr_rec_program[l_idx].prog = l_arr_rec_program[i].prog THEN 
						ERROR kandoomsg2("G",9192,"") 	#9192 "Program has already be entered "
						NEXT FIELD prog 
					END IF 
				END FOR 

			AFTER FIELD alloc_ind 
				IF l_arr_rec_program[l_idx].alloc_ind IS NULL THEN 
					LET l_arr_rec_program[l_idx].alloc_ind = "N" 
					#DISPLAY l_arr_rec_program[l_idx].alloc_ind TO
					#        sr_nextnumber[scrn].alloc_ind
				END IF 

			AFTER FIELD next_num 
				IF l_arr_rec_program[l_idx].alloc_ind = "N" THEN 
					IF l_arr_rec_program[l_idx].next_num < 0 
					OR l_arr_rec_program[l_idx].next_num IS NULL 
					AND l_arr_rec_program[l_idx].prog IS NOT NULL THEN 
						ERROR kandoomsg2("G",9190,"") 	#9190  "Invalid next number"
						NEXT FIELD next_num 
					END IF 
				ELSE 
					NEXT FIELD NEXT 
				END IF 

			AFTER INPUT 
				IF not(int_flag OR quit_flag) THEN 
				END IF 

		END INPUT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			DELETE FROM nextnumber 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND tran_type_ind = p_tran_type 
			AND ((flex_code IS null) OR (flex_code != "NEXTNUMBER" 
			AND flex_code != "POSITIONS")) 
			FOR l_idx = 1 TO arr_count() 
				IF l_arr_rec_program[l_idx].prog IS NOT NULL THEN 
					EXECUTE s_insprog USING 
					glob_rec_kandoouser.cmpy_code,p_tran_type,l_arr_rec_program[l_idx].prog, 
					l_arr_rec_program[l_idx].next_num,l_arr_rec_program[l_idx].alloc_ind 
				END IF 
			END FOR 
			EXECUTE s_insprog USING	glob_rec_kandoouser.cmpy_code,p_tran_type,"PROGRAM",l_rec_program.next_num,"N" 
		END IF 
	END IF 
	CLOSE WINDOW G538 
END FUNCTION 
#######################################################################
# END FUNCTION upd_prog(p_tran_type)
#######################################################################


#######################################################################
# FUNCTION enter_prefix(p_tran_type,p_seg1,p_seg2,p_seg3)
#
#
#######################################################################
FUNCTION enter_prefix(p_tran_type,p_seg1,p_seg2,p_seg3) 
	DEFINE p_tran_type LIKE nextnumber.tran_type_ind 
	DEFINE p_seg1 LIKE structure.start_num 
	DEFINE p_seg2 LIKE structure.start_num 
	DEFINE p_seg3 LIKE structure.start_num 

	DEFINE l_rec_nextnumber RECORD LIKE nextnumber.* 
	DEFINE l_arr_rec_nextnumber DYNAMIC ARRAY OF RECORD #array[400] OF RECORD 
		flex1 LIKE nextnumber.flex_code, 
		flex2 LIKE nextnumber.flex_code, 
		flex3 LIKE nextnumber.flex_code, 
		next_num LIKE nextnumber.next_num 
	END RECORD 
	DEFINE l_arr_rec_format array[3] OF #array[3] OF RECORD 
		RECORD 
			start_num LIKE structure.start_num, 
			length_num LIKE structure.length_num, 
			desc_text LIKE structure.desc_text 
		END RECORD 
		DEFINE l_kandoo_num INTEGER 
		DEFINE l_integer INTEGER 
		DEFINE l_flex_cnt SMALLINT 
		DEFINE l_idx SMALLINT 
		DEFINE x SMALLINT 
		DEFINE y SMALLINT 
		DEFINE i SMALLINT 
		DEFINE l_err_continue CHAR(1) 
		DEFINE l_err_message CHAR(40) 
		DEFINE l_msgresp LIKE language.yes_flag 

		OPEN WINDOW G190 with FORM "G190" 
		CALL windecoration_g("G190") 

		LET l_arr_rec_format[1].start_num = p_seg1 
		LET l_arr_rec_format[2].start_num = p_seg2 
		LET l_arr_rec_format[3].start_num = p_seg3 
		LET l_flex_cnt = 0 

		FOR i = 1 TO 3 
			SELECT 
				start_num, 
				length_num, 
				desc_text 
			INTO l_arr_rec_format[l_flex_cnt + 1].* 
			FROM structure 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND start_num > 0 
			AND start_num = l_arr_rec_format[i].start_num 
			IF sqlca.sqlcode = 0 THEN 
				LET l_flex_cnt = l_flex_cnt+1 
				DISPLAY l_arr_rec_format[l_flex_cnt].desc_text 
				TO sr_heading[l_flex_cnt].desc_text 
			END IF 
		END FOR 

		LET i = 8 
		- l_arr_rec_format[1].length_num 
		- l_arr_rec_format[2].length_num 
		- l_arr_rec_format[3].length_num 
		
		LET glob_temp_text = "99999999" 
		LET l_kandoo_num = glob_temp_text[1,i] 

		DISPLAY l_kandoo_num TO l_kandoo_num 
		DECLARE c_nextnumber CURSOR FOR 
		SELECT * FROM nextnumber 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND tran_type_ind = p_tran_type 
		AND flex_code != "POSITIONS" 
		AND flex_code != "NEXTNUMBER" 
		LET l_idx = 0 

		FOREACH c_nextnumber INTO l_rec_nextnumber.* 
			LET l_idx = l_idx + 1 
			FOR i = 1 TO l_flex_cnt 
				LET x = l_arr_rec_format[i].start_num 
				LET y = l_arr_rec_format[i].length_num 
				CASE i 
					WHEN 1 
						LET l_arr_rec_nextnumber[l_idx].flex1 = l_rec_nextnumber.flex_code[x,x+y-1] 
					WHEN 2 
						LET l_arr_rec_nextnumber[l_idx].flex2 = l_rec_nextnumber.flex_code[x,x+y-1] 
					WHEN 3 
						LET l_arr_rec_nextnumber[l_idx].flex3 = l_rec_nextnumber.flex_code[x,x+y-1] 
				END CASE 
			END FOR 

			LET l_arr_rec_nextnumber[l_idx].next_num = l_rec_nextnumber.next_num 
			IF l_idx = 400 THEN 
				ERROR kandoomsg2("G",9017,400) #9017 " Only 400 Account segments selected"
				EXIT FOREACH 
			END IF 
		END FOREACH 

		CALL set_count(l_idx) 
		ERROR kandoomsg2("G",1004,"") #1004 " F1 TO Add - F2 TO Delete - ESC TO Continue"

		OPTIONS INSERT KEY f1, 
		DELETE KEY f2 

		#INPUT ARRAY --------------------------------------------------
		INPUT ARRAY l_arr_rec_nextnumber WITHOUT DEFAULTS FROM sr_nextnumber.* attribute(UNBUFFERED, append ROW = false, auto append = false) 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","GZD","transation5") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				#LET scrn = scr_line()

			ON ACTION "LOOKUP" infield (flex1) 
				LET l_arr_rec_nextnumber[l_idx].flex1 = 
				show_flex(glob_rec_kandoouser.cmpy_code,l_arr_rec_format[1].start_num) 
				OPTIONS INSERT KEY f1, 
				DELETE KEY f2 
				NEXT FIELD flex1 

			ON ACTION "LOOKUP" infield (flex2) 
				LET l_arr_rec_nextnumber[l_idx].flex2 = 
				show_flex(glob_rec_kandoouser.cmpy_code, l_arr_rec_format[2].start_num) 
				OPTIONS INSERT KEY f1, 
				DELETE KEY f2 
				NEXT FIELD flex2 

			ON ACTION "LOOKUP" infield (flex3) 
				LET l_arr_rec_nextnumber[l_idx].flex3 = 
				show_flex(glob_rec_kandoouser.cmpy_code, l_arr_rec_format[3].start_num) 
				OPTIONS INSERT KEY f1, 
				DELETE KEY f2 
				NEXT FIELD flex3 

				#BEFORE FIELD flex1
				#   DISPLAY l_arr_rec_nextnumber[l_idx].*
				#        TO sr_nextnumber[scrn].*

			AFTER FIELD flex1 
				IF l_arr_rec_nextnumber[l_idx].flex1 IS NULL THEN 
					INITIALIZE l_arr_rec_nextnumber[l_idx].* TO NULL 
					LET l_arr_rec_nextnumber[l_idx].next_num = "" 
				ELSE 
					IF invalid_flex(l_arr_rec_format[1].start_num, 
					l_arr_rec_nextnumber[l_idx].flex1) THEN 
						ERROR kandoomsg2("G",9018,"") 	#9018" This segment IS NOT a valid flex code - Try Window"
						NEXT FIELD flex1 
					END IF 
					IF p_tran_type != TRAN_TYPE_JOB_JOB AND p_tran_type != TRAN_TYPE_CONTRACT_CON THEN 
						WHENEVER ERROR CONTINUE 
						LET l_integer = l_arr_rec_nextnumber[l_idx].flex1 
						IF status = -1213 THEN 
							ERROR kandoomsg2("G",9019,"") #9019 "Only Numeric segments allowed"
							NEXT FIELD flex1 
						END IF 
						WHENEVER ERROR stop 
					END IF 
				END IF 
				#DISPLAY l_arr_rec_nextnumber[l_idx].*
				#     TO sr_nextnumber[scrn].*

			BEFORE FIELD flex2 
				IF l_arr_rec_nextnumber[l_idx].flex1 IS NULL THEN 
					NEXT FIELD flex1 
				END IF 
				IF l_flex_cnt = 1 THEN 
					NEXT FIELD next_num 
				END IF 

			AFTER FIELD flex2 
				IF l_arr_rec_nextnumber[l_idx].flex2 IS NULL THEN 
					ERROR kandoomsg2("G",9020,"") #9020" Flex Code Must be Entered "
					NEXT FIELD flex2 
				ELSE 
					IF invalid_flex(l_arr_rec_format[2].start_num,l_arr_rec_nextnumber[l_idx].flex2) THEN 
						ERROR kandoomsg2("G",9018,"") #9018" This segment IS NOT a valid flex code
						NEXT FIELD flex2 
					END IF 
					IF p_tran_type != TRAN_TYPE_JOB_JOB AND p_tran_type != TRAN_TYPE_CONTRACT_CON THEN 
						WHENEVER ERROR CONTINUE 
						LET l_integer = l_arr_rec_nextnumber[l_idx].flex2 
						IF status = -1213 THEN 
							ERROR kandoomsg2("G",9019,"") 	#9019 "Only Numeric segments allowed"
							NEXT FIELD flex2 
						END IF 
						WHENEVER ERROR stop 
					END IF 
				END IF 

			BEFORE FIELD flex3 
				IF l_flex_cnt = 2 THEN 
					NEXT FIELD next_num 
				END IF 

			AFTER FIELD flex3 
				IF l_arr_rec_nextnumber[l_idx].flex3 IS NULL THEN 
					ERROR kandoomsg2("G",9020,"") 		#9020" Flex Code Must be Entered "
					NEXT FIELD flex3 
				ELSE 
					IF invalid_flex(l_arr_rec_format[3].start_num,l_arr_rec_nextnumber[l_idx].flex3) THEN 
						ERROR kandoomsg2("G",9018,"") 	#9018" This segment IS NOT a valid flex code
						NEXT FIELD flex3 
					END IF 
					IF p_tran_type != TRAN_TYPE_JOB_JOB AND p_tran_type != TRAN_TYPE_CONTRACT_CON THEN 
						WHENEVER ERROR CONTINUE 
						LET l_integer = l_arr_rec_nextnumber[l_idx].flex3 
						IF status = -1213 THEN 
							ERROR kandoomsg2("G",9019,"") 		#9019 "Only Numeric segments allowed"
							NEXT FIELD flex3 
						END IF 
						WHENEVER ERROR stop 
					END IF 
				END IF 

			BEFORE FIELD next_num 
				LET l_integer = l_arr_rec_nextnumber[l_idx].next_num 
				FOR x = 1 TO arr_count() 
					IF x != arr_curr() THEN 
						CASE l_flex_cnt 
							WHEN 1 
								IF l_arr_rec_nextnumber[x].flex1 = l_arr_rec_nextnumber[l_idx].flex1 THEN 
									ERROR kandoomsg2("G",9024,"") 	#9024 "Segment combination already exists
									NEXT FIELD flex1 
								END IF 
							WHEN 2 
								IF l_arr_rec_nextnumber[x].flex1 = l_arr_rec_nextnumber[l_idx].flex1 
								AND l_arr_rec_nextnumber[x].flex2 = l_arr_rec_nextnumber[l_idx].flex2 THEN 
									ERROR kandoomsg2("G",9024,"") 
									NEXT FIELD flex1 
								END IF 
							WHEN 3 
								IF l_arr_rec_nextnumber[x].flex1 = l_arr_rec_nextnumber[l_idx].flex1 
								AND l_arr_rec_nextnumber[x].flex2 = l_arr_rec_nextnumber[l_idx].flex2 
								AND l_arr_rec_nextnumber[x].flex3 = l_arr_rec_nextnumber[l_idx].flex3 THEN 
									ERROR kandoomsg2("G",9024,"") 
									NEXT FIELD flex1 
								END IF 
						END CASE 
					END IF 
				END FOR 

			AFTER FIELD next_num 
				CASE 
					WHEN l_arr_rec_nextnumber[l_idx].next_num IS NULL 
						ERROR kandoomsg2("G",9021,"") #9021" Next transaction number must be entered "
						LET l_arr_rec_nextnumber[l_idx].next_num = l_integer 
						NEXT FIELD next_num 

					WHEN l_arr_rec_nextnumber[l_idx].next_num <= 0 
						ERROR kandoomsg2("G",9022,"") #9022" Next number must be greater than Zero "
						LET l_arr_rec_nextnumber[l_idx].next_num = l_integer 
						NEXT FIELD next_num 

					WHEN l_arr_rec_nextnumber[l_idx].next_num > l_kandoo_num 
						ERROR kandoomsg2("G",9023,"") #9023" Next number must NOT exceed maximum permitted"
						LET l_arr_rec_nextnumber[l_idx].next_num = l_integer 
						NEXT FIELD next_num 
				END CASE 

			AFTER ROW 
				FOR x = 1 TO arr_count() 
					IF x != arr_curr() THEN 
						CASE l_flex_cnt 
							WHEN 1 
								IF l_arr_rec_nextnumber[x].flex1 = l_arr_rec_nextnumber[l_idx].flex1 THEN 
									ERROR kandoomsg2("G",9024,"") #9024 "Segment combination already exists
									INITIALIZE l_arr_rec_nextnumber[l_idx].* TO NULL 
									NEXT FIELD flex1 
								END IF 

							WHEN 2 
								IF l_arr_rec_nextnumber[x].flex1 = l_arr_rec_nextnumber[l_idx].flex1 
								AND l_arr_rec_nextnumber[x].flex2 = l_arr_rec_nextnumber[l_idx].flex2 THEN 
									INITIALIZE l_arr_rec_nextnumber[l_idx].* TO NULL 
									ERROR kandoomsg2("G",9024,"") #9024 Segment combination already exists; This entry ..
									NEXT FIELD flex1 
								END IF 

							WHEN 3 
								IF l_arr_rec_nextnumber[x].flex1 = l_arr_rec_nextnumber[l_idx].flex1 
								AND l_arr_rec_nextnumber[x].flex2 = l_arr_rec_nextnumber[l_idx].flex2 
								AND l_arr_rec_nextnumber[x].flex3 = l_arr_rec_nextnumber[l_idx].flex3 THEN 
									INITIALIZE l_arr_rec_nextnumber[l_idx].* TO NULL 
									ERROR kandoomsg2("G",9024,"") #9024 Segment combination already exists; This entry ..
									NEXT FIELD flex1 
								END IF 
						END CASE 
					END IF 
				END FOR 

			AFTER INPUT 
				IF not(int_flag OR quit_flag) THEN 
					IF l_arr_rec_nextnumber[l_idx].next_num IS NULL 
					AND (l_arr_rec_nextnumber[l_idx].flex1 IS NOT NULL 
					OR l_arr_rec_nextnumber[l_idx].flex2 IS NOT NULL 
					OR l_arr_rec_nextnumber[l_idx].flex3 IS NOT null) THEN 
						ERROR kandoomsg2("G",9021,"") 	#9021 Next transaction number must be entered.
						LET l_arr_rec_nextnumber[l_idx].next_num = l_integer 
						NEXT FIELD next_num 
					END IF 
				END IF 

		END INPUT 

		OPTIONS INSERT KEY f36, 
		DELETE KEY f36 

		CLOSE WINDOW G190 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			RETURN false 
		ELSE 
			WHENEVER ERROR GOTO recovery 
			GOTO bypass 
			LABEL recovery: 
			LET l_err_continue = error_recover(l_err_message, status) 
			IF l_err_continue != "Y" THEN 
				RETURN false 
			END IF 
			LABEL bypass: 
			BEGIN WORK 
				LET l_err_message = "Deleting Next Number (GZD)" 

				DELETE FROM nextnumber 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND tran_type_ind = p_tran_type 
				AND flex_code != "POSITIONS" 
				AND flex_code != "PROGRAM" 
				AND flex_code != "NEXTNUMBER" 

				FOR l_idx = 1 TO arr_count() 
					IF l_arr_rec_nextnumber[l_idx].flex1 IS NOT NULL THEN 
						LET l_rec_nextnumber.flex_code = "" 
						FOR i = 1 TO l_flex_cnt 
							LET x = l_arr_rec_format[i].start_num 
							LET y = l_arr_rec_format[i].length_num 
							CASE 
								WHEN i = 1 
									LET l_rec_nextnumber.flex_code[x,x+y-1] = 
									l_arr_rec_nextnumber[l_idx].flex1 
								WHEN i = 2 
									LET l_rec_nextnumber.flex_code[x,x+y-1] = 
									l_arr_rec_nextnumber[l_idx].flex2 
								WHEN i = 3 
									LET l_rec_nextnumber.flex_code[x,x+y-1] = 
									l_arr_rec_nextnumber[l_idx].flex3 
							END CASE 
						END FOR 

						SELECT unique 1 FROM nextnumber 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND tran_type_ind = p_tran_type 
						AND flex_code = l_rec_nextnumber.flex_code 

						IF status = NOTFOUND THEN 
							LET l_rec_nextnumber.cmpy_code = glob_rec_kandoouser.cmpy_code 
							LET l_rec_nextnumber.tran_type_ind = p_tran_type 
							LET l_rec_nextnumber.flex_code = l_rec_nextnumber.flex_code 
							LET l_rec_nextnumber.next_num = l_arr_rec_nextnumber[l_idx].next_num 
							LET l_rec_nextnumber.alloc_ind = "N" 
							LET l_err_message = "Inserting Next Number (GZD)" 
							INSERT INTO nextnumber VALUES (l_rec_nextnumber.*) 
						END IF 
					END IF 
				END FOR 

			COMMIT WORK 
			WHENEVER ERROR stop 

			RETURN true 
		END IF 

END FUNCTION 
#######################################################################
# END FUNCTION enter_prefix(p_tran_type,p_seg1,p_seg2,p_seg3)
#######################################################################


#######################################################################
# FUNCTION invalid_flex(p_start_num,p_flex_code)
#
#
#######################################################################
FUNCTION invalid_flex(p_start_num,p_flex_code) 
	DEFINE p_start_num LIKE structure.start_num 
	DEFINE p_flex_code LIKE validflex.flex_code 

	SELECT unique 1 FROM validflex 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND start_num = p_start_num 
	AND flex_code = p_flex_code 
	RETURN sqlca.sqlcode 
END FUNCTION 
#######################################################################
# END FUNCTION invalid_flex(p_start_num,p_flex_code)
#######################################################################


#######################################################################
# FUNCTION num_exists(p_cmpy,p_tran_type,p_doc_num)
#
#
#######################################################################
FUNCTION num_exists(p_cmpy,p_tran_type,p_doc_num) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_tran_type LIKE nextnumber.tran_type_ind 
	DEFINE p_doc_num LIKE arparms.nextinv_num 
	DEFINE l_doc_code LIKE customer.cust_code 
	DEFINE l_query_text CHAR(200) 

	CASE p_tran_type 
		WHEN TRAN_TYPE_INVOICE_IN 
			LET l_query_text = "SELECT unique 1 FROM invoicehead ", 
			"WHERE cmpy_code =\"",p_cmpy,"\" ", 
			"AND inv_num = ",p_doc_num,"" 
		WHEN TRAN_TYPE_CREDIT_CR 
			LET l_query_text = "SELECT unique 1 FROM credithead ", 
			"WHERE cmpy_code =\"",p_cmpy,"\" ", 
			"AND cred_num = ",p_doc_num,"" 
		WHEN TRAN_TYPE_RECEIPT_CA 
			LET l_query_text = "SELECT unique 1 FROM cashreceipt ", 
			"WHERE cmpy_code =\"",p_cmpy,"\" ", 
			"AND cash_num = ",p_doc_num,"" 
		WHEN TRAN_TYPE_CUSTOMER_CUS 
			LET l_doc_code = p_doc_num 
			LET l_query_text = "SELECT unique 1 FROM customer ", 
			"WHERE cmpy_code =\"",p_cmpy,"\" ", 
			"AND cust_code =\"",l_doc_code,"\" " 
		WHEN TRAN_TYPE_ORDER_ORD 
			LET l_query_text = "SELECT unique 1 FROM ordhead ", 
			"WHERE cmpy_code =\"",p_cmpy,"\" ", 
			"AND order_num = ",p_doc_num,"" 
		WHEN TRAN_TYPE_LOAD_LNO 
			LET l_query_text = "SELECT unique 1 FROM loadhead ", 
			"WHERE cmpy_code =\"",p_cmpy,"\" ", 
			"AND load_num =\"",p_doc_num,"\" " 
		WHEN TRAN_TYPE_BATCH_BAT 
			LET l_query_text = "SELECT unique 1 FROM voucher ", 
			"WHERE cmpy_code =\"",p_cmpy,"\" ", 
			"AND batch_num =\"",p_doc_num,"\" " 
		WHEN TRAN_TYPE_DELIVERY_DLV 
			LET l_query_text = "SELECT unique 1 FROM delivhead ", 
			"WHERE cmpy_code =\"",p_cmpy,"\" ", 
			"AND pick_num =\"",p_doc_num,"\" " 
		WHEN TRAN_TYPE_TRANSPORT_TRN 
			LET l_query_text = "SELECT unique 1 FROM driverledger ", 
			"WHERE cmpy_code =\"",p_cmpy,"\" ", 
			"AND ref_num =\"",p_doc_num,"\" ", 
			"AND trans_type_code = 'AD' " 
		WHEN TRAN_TYPE_JOB_JOB 
			LET l_query_text = "SELECT unique 1 FROM job ", 
			"WHERE cmpy_code =\"",p_cmpy,"\" ", 
			"AND job_code = \"",p_doc_num using "<<<<<<<<" ,"\"" 
		WHEN "SS" 
			LET l_query_text = "SELECT unique 1 FROM subhead ", 
			"WHERE cmpy_code =\"",p_cmpy,"\" ", 
			"AND sub_num = ",p_doc_num,"" 
		WHEN TRAN_TYPE_CONTRACT_CON 
			LET l_doc_code = p_doc_num 
			LET l_query_text = "SELECT unique 1 ", 
			"FROM contracthead ", 
			"WHERE cmpy_code = '", p_cmpy, "' ", 
			"AND contract_code = '", l_doc_code, "'" 
	END CASE 

	PREPARE s_number FROM l_query_text 
	DECLARE c_number CURSOR FOR s_number 
	OPEN c_number 
	FETCH c_number 

	IF status = NOTFOUND THEN 
		CLOSE c_number 

		IF p_tran_type = TRAN_TYPE_BATCH_BAT THEN 
			# Need TO check Debithead table as batch number also used here.
			DECLARE c_number2 CURSOR FOR 
			SELECT unique(1) FROM debithead 
			WHERE cmpy_code = p_cmpy 
			AND batch_num = p_doc_num 
			OPEN c_number2 
			FETCH c_number2 
			IF status = NOTFOUND THEN 
				CLOSE c_number2 
				RETURN false 
			ELSE 
				CLOSE c_number2 
				RETURN true 
			END IF 
		ELSE 
			RETURN false 
		END IF 
	ELSE 
		CLOSE c_number 
		RETURN true 
	END IF 
END FUNCTION 
#######################################################################
# END FUNCTION num_exists(p_cmpy,p_tran_type,p_doc_num)
#######################################################################


#######################################################################
# FUNCTION upd_number(p_tran_type,p_numtype_num)
#
#
#######################################################################
FUNCTION upd_number(p_tran_type,p_numtype_num) 
	DEFINE p_tran_type LIKE nextnumber.tran_type_ind 
	DEFINE p_numtype_num INTEGER 
	DEFINE l_err_continue CHAR(1) 
	DEFINE l_numtype_ind CHAR(1) 
	DEFINE l_next_num LIKE nextnumber.next_num 
	DEFINE l_save_option CHAR(1) 
	DEFINE l_trans_text CHAR(23) 
	DEFINE l_err_message CHAR(40) 
	DEFINE l_prompt_text CHAR(40) 
	DEFINE l_msgresp LIKE language.yes_flag 

	### code below handles first time run data conversion
	IF p_numtype_num < 0 OR p_numtype_num > 3 THEN 
		SELECT unique 1 FROM nextnumber 
		WHERE cmpy_code = glob_rec_company.cmpy_code 
		AND tran_type_ind = p_tran_type 
		AND flex_code = "NEXTNUMBER" 
		IF status = NOTFOUND THEN 
			INSERT INTO nextnumber 
			VALUES (glob_rec_company.cmpy_code,p_tran_type,"NEXTNUMBER",p_numtype_num,"N") 
		END IF 
		LET p_numtype_num = 1 
	END IF 
	### code above handles first time run data conversion

	LET l_numtype_ind = p_numtype_num + 1 
	CLEAR FORM 
	IF l_numtype_ind = 2 
	AND (
		p_tran_type = TRAN_TYPE_CUSTOMER_CUS OR 
		p_tran_type = TRAN_TYPE_ORDER_ORD OR 
		p_tran_type = TRAN_TYPE_DELIVERY_DLV OR 
		p_tran_type = TRAN_TYPE_TRANSPORT_TRN OR 
		p_tran_type = TRAN_TYPE_BATCH_BAT OR 
		p_tran_type = TRAN_TYPE_LOAD_LNO
		) THEN 
		DISPLAY l_numtype_ind TO numtype_ind 

	ELSE 
		# INPUT ---------------------------------------------------
		INPUT l_numtype_ind WITHOUT DEFAULTS FROM numtype_ind 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","GZD","transation6") 
				LET l_save_option = l_numtype_ind 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

--			ON CHANGE numtype_ind
			
			AFTER FIELD numtype_ind 
				IF l_numtype_ind = "E" THEN 
					LET l_numtype_ind = l_save_option 
					DISPLAY l_numtype_ind TO numtype_ind 
					LET quit_flag = true 
					EXIT INPUT 
				END IF 
				
				IF l_numtype_ind != "3" AND l_save_option = "3" THEN 

					#					OPEN WINDOW w1_GZD WITH FORM "U999" ATTRIBUTES(BORDER)
					#					CALL windecoration_u("U999")

					MENU "Delete Segment Prefixing Setup" 

						BEFORE MENU 
							CALL publish_toolbar("kandoo","GZD","menu-delete-segment-prefix-setup") 

						ON ACTION "WEB-HELP" 
							CALL onlinehelp(getmoduleid(),null) 

						ON ACTION "actToolbarManager" 
							CALL setuptoolbar() 

						ON ACTION "Yes" 
							#                COMMAND "Yes"
							WHENEVER ERROR GOTO recovery 
							GOTO bypass 
							LABEL recovery: 
							LET l_err_continue = error_recover(l_err_message, status) 
							IF l_err_continue != "Y" THEN 
								LET l_numtype_ind = l_save_option 
								LET quit_flag = true 
								EXIT MENU 
							END IF 

							LABEL bypass: 
							BEGIN WORK 

								LET l_err_message = "Deleting Next Number Entry (GZD)" 
								DELETE FROM nextnumber 
								WHERE cmpy_code = glob_rec_company.cmpy_code 
								AND tran_type_ind = p_tran_type 
								AND flex_code != "NEXTNUMBER" 
								AND flex_code != "POSITIONS" 
								AND flex_code != "PROGRAM" 

								LET l_err_message = "Updating Next Number Entry (GZD)" 
								UPDATE nextnumber 
								SET next_num = 0 
								WHERE cmpy_code = glob_rec_company.cmpy_code 
								AND tran_type_ind = p_tran_type 
								AND flex_code = "POSITIONS" 

							COMMIT WORK 
							WHENEVER ERROR stop 
							EXIT MENU 

						ON ACTION "No"			#COMMAND KEY(interrupt,"N")"No"
							LET l_numtype_ind = l_save_option 
							LET quit_flag = true 
							EXIT MENU 

					END MENU 

					IF int_flag OR quit_flag THEN 
						LET int_flag = false 
						LET quit_flag = false 
						NEXT FIELD numtype_ind 
					END IF 
				END IF 

			AFTER INPUT 
				IF l_numtype_ind = "E" THEN 
					LET quit_flag = true 
				END IF 

		END INPUT 

	END IF 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 

		CASE l_numtype_ind 
			WHEN "1"	### Manual entry

			WHEN "2"	### Sequential next numbering
				LET l_trans_text=kandooword("nextnumber.tran_type_ind",p_tran_type) 
				IF l_trans_text IS NULL THEN 
					ERROR kandoomsg2("U",9007,"") 
					LET l_trans_text = "Next ",p_tran_type," Number" 
				END IF
				 
				IF p_tran_type = TRAN_TYPE_JOB_JOB THEN 
					SELECT nextjob_num INTO l_next_num 
					FROM jmparms 
					WHERE cmpy_code = glob_rec_company.cmpy_code 
					AND key_code = "1" 
				ELSE 
					SELECT next_num INTO l_next_num 
					FROM nextnumber 
					WHERE cmpy_code = glob_rec_company.cmpy_code 
					AND tran_type_ind = p_tran_type 
					AND flex_code = "NEXTNUMBER" 
					IF status = NOTFOUND THEN 
						INSERT INTO nextnumber 
						VALUES (glob_rec_company.cmpy_code,p_tran_type,"NEXTNUMBER",1,"N") 
						LET l_next_num = 1 
					END IF 
				END IF 

				--LET l_prompt_text = l_trans_text clipped,"............."
				LET l_prompt_text = "Starting/Current Number" 
				DISPLAY l_prompt_text TO prompt_text 

				#INPUT -------------------------------------------------------------------
				INPUT l_next_num WITHOUT DEFAULTS FROM next_num ATTRIBUTE(UNBUFFERED) 
					BEFORE INPUT 
						CALL publish_toolbar("kandoo","GZD","transation7") 

					ON ACTION "WEB-HELP" 
						CALL onlinehelp(getmoduleid(),null) 

					ON ACTION "actToolbarManager" 
						CALL setuptoolbar() 

					AFTER FIELD next_num 
						CASE 
							WHEN l_next_num IS NULL 
								ERROR kandoomsg2("G",9026,l_trans_text) 	#9026 Next trans number must be entered
								LET l_next_num = 1 
								NEXT FIELD next_num 
							WHEN l_next_num <= 0 
								ERROR kandoomsg2("G",9025,l_trans_text) 	#9025 Next trans number must be > 0
								LET l_next_num = 1 
								NEXT FIELD next_num 
							WHEN l_next_num >= 99999999 
								ERROR kandoomsg2("G",9028,l_trans_text) 	#9025 Next trans number has exceeded max length
								LET l_next_num = 1 
								NEXT FIELD next_num 
							OTHERWISE 
								IF num_exists(glob_rec_kandoouser.cmpy_code,p_tran_type,l_next_num) THEN 
									ERROR kandoomsg2("G",9027,l_trans_text) 	#9027 Next trans number has exceeded max length
									LET l_next_num = 1 
									NEXT FIELD next_num 
								END IF 
								IF p_tran_type = TRAN_TYPE_JOB_JOB THEN 
									UPDATE jmparms 
									SET nextjob_num = l_next_num 
									WHERE cmpy_code = glob_rec_company.cmpy_code 
									AND key_code = "1" 
								ELSE 
									WHENEVER ERROR GOTO recovery2 
									GOTO bypass2 
									LABEL recovery2: 
									LET l_err_continue = error_recover(l_err_message, status) 
									IF l_err_continue != "Y" THEN 
										# Do this so no other updates take place down
										# further
										LET p_tran_type = NULL 
										EXIT INPUT 
									END IF 
									LABEL bypass2: 
									LET l_err_message = "Updating Next Number (GZD)"
									MESSAGE l_err_message
									
									--SLEEP 2 

									BEGIN WORK 
										UPDATE nextnumber 
										SET next_num = l_next_num 
										WHERE cmpy_code = glob_rec_company.cmpy_code 
										AND tran_type_ind = p_tran_type 
										AND flex_code = "NEXTNUMBER" 
									COMMIT WORK 
									WHENEVER ERROR stop 
								END IF 
						END CASE 

				END INPUT 

			WHEN "3" 
				CALL upd_prefixs(p_tran_type) 

			WHEN "4" 
				CALL upd_prog(p_tran_type) 

		END CASE 

		LET p_numtype_num = l_numtype_ind 

		CASE p_tran_type 
			WHEN TRAN_TYPE_JOB_JOB 
				IF p_numtype_num = 1 THEN 
					UPDATE jmparms 
					SET nextjob_num = 0 
					WHERE cmpy_code = glob_temp_text 
					AND key_code = "1" 
				END IF 
			WHEN TRAN_TYPE_CONTRACT_CON 
				UPDATE jmparms 
				SET nextcontract_num = p_numtype_num - 1 
				WHERE cmpy_code = glob_temp_text 
				AND key_code = "1" 
			WHEN TRAN_TYPE_RECEIPT_CA 
				UPDATE arparms 
				SET nextcash_num = p_numtype_num - 1 
				WHERE cmpy_code = glob_temp_text 
				AND parm_code = "1" 
			WHEN TRAN_TYPE_CREDIT_CR 
				UPDATE arparms 
				SET nextcredit_num = p_numtype_num - 1 
				WHERE cmpy_code = glob_temp_text 
				AND parm_code = "1" 
			WHEN TRAN_TYPE_INVOICE_IN 
				UPDATE arparms 
				SET nextinv_num = p_numtype_num -1 
				WHERE cmpy_code = glob_temp_text 
				AND parm_code = "1" 
			WHEN "SS" 
				UPDATE ssparms 
				SET next_sub_num = p_numtype_num -1 
				WHERE cmpy_code = glob_temp_text 
		END CASE 
	END IF 

	LET int_flag = false 
	LET quit_flag = false 
END FUNCTION 
#######################################################################
# END FUNCTION upd_number(p_tran_type,p_numtype_num)
#######################################################################