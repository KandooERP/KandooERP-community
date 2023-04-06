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

	Source code beautified by beautify.pl on 2020-01-03 18:54:47	$Id: $
}



{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module URP.4gl
#
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../utility/U_UT_GLOBALS.4gl" 
#GLOBALS
#DEFINE pr_rec_kandoouser RECORD LIKE kandoouser.*


#DEFINE term_type CHAR(20)
#DEFINE runner CHAR(100)
#DEFINE ret_code INTEGER
#END GLOBALS
DEFINE modu_sys_type CHAR(20) 

###################################################################
# MAIN
#
#
###################################################################
MAIN 
	DEFINE runner CHAR(100) 
	CALL setModuleId("URP") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_u_ut() #init utility module 

	CREATE temp TABLE t_uname (uname CHAR(60)) 
	LET runner = "echo `uname` > /tmp/maxuname" 
	RUN runner 
	LOAD FROM "/tmp/maxuname" INSERT INTO t_uname 
	LET runner = "rm /tmp/maxuname" 
	RUN runner 
	SELECT uname INTO modu_sys_type FROM t_uname 
	#LET term_type = fgl_getenv("$TERM")

	CALL system_setup() 
END MAIN 


###################################################################
# FUNCTION system_setup()
#
#
###################################################################
FUNCTION system_setup() 
	DEFINE runner CHAR(100) 
	DEFINE ret_code INTEGER 
	#Note: Huho 27.03.2018 We will NOT support AIX & Co, only windows, Linux AND Apple OS
	CALL fgl_winmessage("Kandoo IS supported for Linux, Apple AND Windows","Kandoo IS supported for Linux, Apple AND Windows","info") 
	IF modu_sys_type matches "AIX*" THEN 
		# on AIX sites lsvg only exists on RISC boxes WHERE it will RETURN 0.
		# on AIX sites lsvg doesn't exist on RT boxes WHERE it will RETURN 1.
		# RISC boxes running AIX have normal lp commands
		# TO get rid of the sh: lsvg NOT found MESSAGE AT RT sites
		# echo "EXIT 1" > /usr/bin/lsvg; chmod +x /usr/bin/lsvg
		LET runner = "lsvg > /dev/NULL 2>&1" 
		RUN runner RETURNING ret_code 
		IF ret_code THEN 
			LET modu_sys_type = "AIX RT" 
		ELSE 
			LET modu_sys_type = "AIX RISC" 
		END IF 
	ELSE 
		LET modu_sys_type = "NON AIX" 
	END IF 

	WHENEVER ERROR CONTINUE 
	OPTIONS DELETE KEY f36 
	WHENEVER ERROR stop 

	OPEN WINDOW u103 with FORM "U103" 
	CALL windecoration_u("U103") 

	WHILE select_device() 
	END WHILE 

	CLOSE WINDOW u103 
END FUNCTION 


###################################################################
# FUNCTION select_device()
#
#
###################################################################
FUNCTION select_device() 
	DEFINE l_arr_rec_printcodes DYNAMIC ARRAY OF #array[100] 
	RECORD 
		print_code LIKE printcodes.print_code, 
		desc_text LIKE printcodes.desc_text, 
		width_num LIKE printcodes.width_num, 
		length_num LIKE printcodes.length_num 
	END RECORD 
	DEFINE pr_printcodes RECORD LIKE printcodes.* 
	DEFINE pr_deletion_text LIKE printcodes.desc_text 
	DEFINE pr_delete_print_code LIKE printcodes.print_code 
	DEFINE query_text STRING 
	DEFINE where_text STRING 
	DEFINE i SMALLINT 
	DEFINE idx SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag
	
	CLEAR FORM 
	OPTIONS DELETE KEY f2 
	LET l_msgresp = kandoomsg("U",1001,"") 
	CONSTRUCT BY NAME where_text ON printcodes.print_code, 
	printcodes.desc_text, 
	printcodes.width_num, 
	printcodes.length_num 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","URP","construct-printcodes") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	LET query_text = "SELECT * ", 
	"FROM printcodes ", 
	"WHERE ",where_text clipped," ", 
	"ORDER BY print_code" 
	PREPARE s_printcode FROM query_text 
	DECLARE c_printcode CURSOR FOR s_printcode 
	LET idx = 0 
	FOREACH c_printcode INTO pr_printcodes.* 
		LET idx = idx + 1 
		LET l_arr_rec_printcodes[idx].print_code = pr_printcodes.print_code 
		LET l_arr_rec_printcodes[idx].desc_text = pr_printcodes.desc_text 
		LET l_arr_rec_printcodes[idx].width_num = pr_printcodes.width_num 
		LET l_arr_rec_printcodes[idx].length_num = pr_printcodes.length_num 
		IF idx = 100 THEN 
			LET l_msgresp = kandoomsg("U",6100,idx) 
			EXIT FOREACH 
		END IF 
	END FOREACH 

	LET l_msgresp = kandoomsg("U",9113,idx) 
	CALL set_count(idx) 
	LET l_msgresp = kandoomsg("U",1003,"") 
	INPUT ARRAY l_arr_rec_printcodes WITHOUT DEFAULTS FROM sr_printcodes.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","URP","input-arr-printcodes") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		BEFORE ROW 
			LET idx = arr_curr() 
			#         LET scrn = scr_line()
			LET pr_printcodes.print_code = l_arr_rec_printcodes[idx].print_code 
			#BEFORE FIELD print_code
			#   DISPLAY l_arr_rec_printcodes[idx].*
			#        TO sr_printcodes[scrn].*

		AFTER FIELD print_code 
			LET l_arr_rec_printcodes[idx].print_code = pr_printcodes.print_code 
			# DISPLAY l_arr_rec_printcodes[idx].print_code
			#      TO sr_printcodes[scrn].print_code

		ON ACTION "EDIT" --edit/input 
			IF edit_device(l_arr_rec_printcodes[idx].print_code) THEN 
				SELECT print_code, 
				desc_text, 
				width_num, 
				length_num 
				INTO l_arr_rec_printcodes[idx].* 
				FROM printcodes 
				WHERE print_code = pr_printcodes.print_code 
			END IF 
			NEXT FIELD print_code 

		BEFORE FIELD desc_text 
			IF edit_device(l_arr_rec_printcodes[idx].print_code) THEN 
				SELECT print_code, 
				desc_text, 
				width_num, 
				length_num 
				INTO l_arr_rec_printcodes[idx].* 
				FROM printcodes 
				WHERE print_code = pr_printcodes.print_code 
			END IF 
			NEXT FIELD print_code 

		BEFORE DELETE 
			LET pr_delete_print_code = l_arr_rec_printcodes[idx].print_code 

		AFTER DELETE 
			DELETE FROM printcodes 
			WHERE print_code = pr_delete_print_code 

		BEFORE INSERT --new add new device 
			CALL add_device() 
			RETURNING pr_printcodes.* 
			IF pr_printcodes.print_code IS NOT NULL THEN 
				LET l_arr_rec_printcodes[idx].print_code = pr_printcodes.print_code 
				LET l_arr_rec_printcodes[idx].desc_text = pr_printcodes.desc_text 
				LET l_arr_rec_printcodes[idx].width_num = pr_printcodes.width_num 
				LET l_arr_rec_printcodes[idx].length_num = pr_printcodes.length_num 
				#            DISPLAY l_arr_rec_printcodes[idx].*
				#                 TO sr_printcodes[scrn].*

			END IF 
			NEXT FIELD print_code 

		ON KEY (control-w) --help 
			CALL kandoohelp("") 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 
	END IF 

	RETURN true 
	OPTIONS DELETE KEY f36 

END FUNCTION 


###################################################################
# FUNCTION add_device()
#
#
###################################################################
FUNCTION add_device() 
	DEFINE pr_printcodes RECORD LIKE printcodes.* 
	DEFINE pr_exists SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag
	
	OPEN WINDOW u102 with FORM "U102" 
	CALL windecoration_u("U102") 

	INPUT BY NAME pr_printcodes.print_code, 
	pr_printcodes.desc_text, 
	pr_printcodes.device_ind, 
	pr_printcodes.width_num, 
	pr_printcodes.length_num, 
	pr_printcodes.print_text, 
	pr_printcodes.compress_1, 
	pr_printcodes.compress_2, 
	pr_printcodes.compress_3, 
	pr_printcodes.compress_4, 
	pr_printcodes.compress_5, 
	pr_printcodes.compress_6, 
	pr_printcodes.compress_7, 
	pr_printcodes.compress_8, 
	pr_printcodes.compress_9, 
	pr_printcodes.compress_10, 
	pr_printcodes.compress_11, 
	pr_printcodes.compress_12, 
	pr_printcodes.compress_13, 
	pr_printcodes.compress_14, 
	pr_printcodes.compress_15, 
	pr_printcodes.compress_16, 
	pr_printcodes.compress_17, 
	pr_printcodes.compress_18, 
	pr_printcodes.compress_19, 
	pr_printcodes.compress_20, 
	pr_printcodes.normal_1, 
	pr_printcodes.normal_2, 
	pr_printcodes.normal_3, 
	pr_printcodes.normal_4, 
	pr_printcodes.normal_5, 
	pr_printcodes.normal_6, 
	pr_printcodes.normal_7, 
	pr_printcodes.normal_8, 
	pr_printcodes.normal_9, 
	pr_printcodes.normal_10 WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","URP","input-printcodes-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		AFTER FIELD print_code 
			IF pr_printcodes.print_code IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				NEXT FIELD print_code 
			END IF 
			LET pr_exists = false 
			SELECT 1 
			INTO pr_exists 
			FROM printcodes 
			WHERE printcodes.print_code = pr_printcodes.print_code 
			IF pr_exists THEN 
				LET l_msgresp = kandoomsg("U",9030,"") 
				NEXT FIELD print_code 
			END IF 

		AFTER FIELD device_ind 
			CASE 
				WHEN pr_printcodes.device_ind = "1" 
					CALL check_cmd(pr_printcodes.*) 
					IF modu_sys_type = "AIX RT" THEN 
						LET pr_printcodes.print_text = "cat $F | PRINT ", 
						pr_printcodes.print_code clipped," -nc=$C " 
					ELSE 
						LET pr_printcodes.print_text = "lp -c -s -d", 
						pr_printcodes.print_code clipped," -n$C $F" 
					END IF 
				WHEN pr_printcodes.device_ind = "2" 
					LET pr_printcodes.print_text = "pg -p \"Page ''%d:\" $F" 
			END CASE 
			DISPLAY BY NAME pr_printcodes.print_text 


			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				LET pr_exists = false 
				SELECT 1 
				INTO pr_exists 
				FROM printcodes 
				WHERE printcodes.print_code = pr_printcodes.print_code 
				IF pr_exists THEN 
					LET l_msgresp = kandoomsg("U",9030,"") 
					NEXT FIELD print_code 
				END IF 
			END IF 

		ON KEY (control-w) --help 
			CALL kandoohelp("") 

	END INPUT 


	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		INITIALIZE pr_printcodes.* TO NULL 
	ELSE 
		INSERT INTO printcodes VALUES (pr_printcodes.*) 
	END IF 
	CLOSE WINDOW u102 

	RETURN pr_printcodes.* 
END FUNCTION 


###################################################################
# FUNCTION edit_device(pr_printcode)
#
#
###################################################################
FUNCTION edit_device(pr_printcode) 
	DEFINE pr_save_dev_ind LIKE printcodes.device_ind 
	DEFINE pr_printcode LIKE printcodes.print_code 
	DEFINE pr_printcodes RECORD LIKE printcodes.* 
	DEFINE l_msgresp LIKE language.yes_flag
	
	OPEN WINDOW u102 with FORM "U102" 
	CALL windecoration_u("U102") 

	SELECT * 
	INTO pr_printcodes.* 
	FROM printcodes 
	WHERE printcodes.print_code = pr_printcode 
	LET pr_save_dev_ind = pr_printcodes.device_ind 
	DISPLAY BY NAME pr_printcodes.* 

	INPUT BY NAME pr_printcodes.desc_text, 
	pr_printcodes.device_ind, 
	pr_printcodes.width_num, 
	pr_printcodes.length_num, 
	pr_printcodes.print_text, 
	pr_printcodes.compress_1, 
	pr_printcodes.compress_2, 
	pr_printcodes.compress_3, 
	pr_printcodes.compress_4, 
	pr_printcodes.compress_5, 
	pr_printcodes.compress_6, 
	pr_printcodes.compress_7, 
	pr_printcodes.compress_8, 
	pr_printcodes.compress_9, 
	pr_printcodes.compress_10, 
	pr_printcodes.compress_11, 
	pr_printcodes.compress_12, 
	pr_printcodes.compress_13, 
	pr_printcodes.compress_14, 
	pr_printcodes.compress_15, 
	pr_printcodes.compress_16, 
	pr_printcodes.compress_17, 
	pr_printcodes.compress_18, 
	pr_printcodes.compress_19, 
	pr_printcodes.compress_20, 
	pr_printcodes.normal_1, 
	pr_printcodes.normal_2, 
	pr_printcodes.normal_3, 
	pr_printcodes.normal_4, 
	pr_printcodes.normal_5, 
	pr_printcodes.normal_6, 
	pr_printcodes.normal_7, 
	pr_printcodes.normal_8, 
	pr_printcodes.normal_9, 
	pr_printcodes.normal_10 WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","URP","input-printcodes-2") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		AFTER FIELD device_ind 
			IF pr_printcodes.device_ind != pr_save_dev_ind THEN 
				CASE 
					WHEN pr_printcodes.device_ind = "1" 
						CALL check_cmd(pr_printcodes.*) 
						IF modu_sys_type = "AIX RT" THEN 
							LET pr_printcodes.print_text = "cat $F | PRINT ", 
							pr_printcodes.print_code clipped," -nc=$C " 
						ELSE 
							LET pr_printcodes.print_text = "lp -c -s -d", 
							pr_printcodes.print_code clipped," -n$C $F" 
						END IF 
					WHEN pr_printcodes.device_ind = "2" 
						LET pr_printcodes.print_text = "pg -p \"Page ''%d:\" $F" 
				END CASE 
			END IF 
			DISPLAY BY NAME pr_printcodes.print_text 


			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 

	CLOSE WINDOW u102 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		UPDATE printcodes 
		SET * = pr_printcodes.* 
		WHERE print_code = pr_printcodes.print_code 
		RETURN true 
	END IF 

END FUNCTION 


###################################################################
# FUNCTION check_cmd(pr_printcodes)
#
#
###################################################################
FUNCTION check_cmd(pr_printcodes) 
	DEFINE pr_found SMALLINT 
	DEFINE pr_wrn CHAR(1) 
	DEFINE pr_printcodes RECORD LIKE printcodes.* 
	DEFINE x SMALLINT 
	DEFINE i SMALLINT 
	DEFINE ans CHAR(1) 
	DEFINE l_msgresp LIKE language.yes_flag
	
	LET pr_found = 0 
	LET pr_wrn = " " 
	FOR i = 1 TO (length(pr_printcodes.print_text)-2) 
		IF pr_printcodes.print_text[i,i + 2] = "lp " THEN 
			LET pr_found = i 
			EXIT FOR 
		END IF 
	END FOR 

	FOR x = pr_found TO (length(pr_printcodes.print_text)-2) 
		IF pr_printcodes.print_text[x,x + 2] = "-c " THEN 
			LET pr_wrn = "N" 
			EXIT FOR 
		END IF 
	END FOR 
	IF pr_wrn != "N" THEN 
		LET l_msgresp = kandoomsg("U",7006,"") 
	END IF 
END FUNCTION