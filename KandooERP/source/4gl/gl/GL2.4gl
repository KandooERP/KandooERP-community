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

	Source code beautified by beautify.pl on 2020-01-03 14:28:46	$Id: $
}



# GL2 Report Data extraction process
#     Loads glrepdata table with data FOR selected reports
#
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 

############################################################
# MODULE Scope Variables
############################################################
--DEFINE modu_err_message CHAR(40)
--DEFINE modu_winds_text CHAR(40)
DEFINE modu_where1_text CHAR(100) 
DEFINE modu_where2_text CHAR(100) 
DEFINE modu_where3_text CHAR(100) 
DEFINE modu_file_name CHAR(150) 
DEFINE modu_path_name CHAR(150) 
--DEFINE modu_data_flag SMALLINT 
 

##############################################################
# MAIN
#
#
##############################################################
MAIN 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_data_flag SMALLINT
	
	CALL setModuleId("GL2") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 


	OPTIONS INPUT wrap 


	CALL create_table("glrepdata","t_accthist","","Y") 
	LET l_data_flag = false 

	OPEN WINDOW g545 with FORM "G545" 
	CALL windecoration_g("G545") 

	WHILE select_data() 
		IF (create_temp(l_data_flag) = true) THEN 
			CALL load_data()
		END IF 
	END WHILE 

	CLOSE WINDOW g545 

END MAIN 


##############################################################
# FUNCTION create_temp()
#
#
##############################################################
FUNCTION create_temp(p_data_flag) 
	DEFINE p_data_flag SMALLINT
	DEFINE l_rec_structure RECORD LIKE structure.* 
	DEFINE l_query_text CHAR(250)
	DEFINE i SMALLINT 

	DEFINE cur_v CURSOR 
	DEFINE ret_rec RECORD 
		acct_code LIKE coa.acct_code, 
		chart_code LIKE account.chart_code 
	END RECORD 

	IF p_data_flag = true THEN 
		# skip FUNCTION
		RETURN true 
	ELSE 
		LET p_data_flag = true 
	END IF 

	SELECT * INTO l_rec_structure.* FROM structure 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND type_ind = "C" 

	IF status = 0 THEN 
		LET i = l_rec_structure.start_num 
	ELSE 
		LET i = 1 
	END IF 

	LET l_query_text = " SELECT acct_code, acct_code[",i,",18] chart_code FROM coa ", 
	" WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"'", 
	" INTO temp t_chart " 


	PREPARE s_tempbuild FROM l_query_text 
	EXECUTE s_tempbuild 

	CREATE INDEX t_ckey ON t_chart (chart_code) 

	RETURN true 

END FUNCTION 


##############################################################
# FUNCTION select_data()
#
#
##############################################################
FUNCTION select_data() 
	DEFINE l_runner CHAR(100) 
	DEFINE l_ret_code INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE modu_where1_text STRING
	DEFINE modu_where2_text STRING
	DEFINE modu_where3_text STRING
	DEFINE modu_file_name STRING
	DEFINE modu_path_name STRING	
	
	LET l_msgresp=kandoomsg("U",1020,"File") 

	#1020 " Enter VALUE details - OK TO continue"
	INPUT modu_path_name,modu_file_name FROM path_name,file_name ATTRIBUTE(UNBUFFERED) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GL2","inp-file") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null)
			 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD path_name 
			IF modu_path_name IS NOT NULL THEN 
				LET l_ret_code = os.path.exists(modu_path_name) --huho changed TO os.path() method 
				#LET l_runner = " [ -d ",modu_path_name clipped," ] 2>>", trim(get_settings_logFile())
				#run l_runner returning l_ret_code
				IF l_ret_code = 0 THEN --if l_ret_code THEN 
					LET l_msgresp=kandoomsg("U",9124,"") 
					#9124 "Path does NOT exist"
					NEXT FIELD path_name 
				END IF 
			END IF 

		AFTER INPUT 

			# Exclusive OR
			# Lycia: Lycia SET's quit_flag = TRUE
			# whenever int_flag IS SET automatically.
			# IF NOT int_flag OR quit_flag THEN
			# huho - changed TO
			IF NOT (int_flag OR quit_flag) THEN 
				IF modu_path_name IS NULL THEN 
					LET l_msgresp=kandoomsg("U",9102,"") 
					#9102 "Value must be entered"
					NEXT FIELD path_name 
				END IF 

				IF modu_file_name IS NULL THEN 
					LET l_msgresp=kandoomsg("U",9102,"") 
					#9102 "Value must be entered"
					NEXT FIELD file_name 
				END IF 

			END IF 
	END INPUT 


	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

	LET l_msgresp=kandoomsg("U",1001,"") 
	#1001 " Enter criteria FOR selection - ESC TO begin search"
	CONSTRUCT BY NAME modu_where1_text ON glrepdetl.rept_code, 
	glrephead.desc_text 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","GL2","construct-glrep") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF fgl_lastkey() = fgl_keyval("accept") THEN 
		LET modu_where2_text = "1=1" 
		RETURN true 
	END IF 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

	CONSTRUCT BY NAME modu_where2_text ON year_num, 
	period_num 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","GL2","construct-year") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF fgl_lastkey() = fgl_keyval("accept") THEN 
		LET modu_where3_text = "1=1" 
		RETURN true 
	END IF 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

	CONSTRUCT BY NAME modu_where3_text ON group_code 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","GL2","construct-group") 

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

	RETURN true 

END FUNCTION 


##############################################################
# FUNCTION load_data()
#
#
##############################################################
FUNCTION load_data()
	DEFINE modu_where1_text STRING 
	DEFINE modu_where2_text STRING 
	DEFINE modu_where3_text STRING	
	DEFINE modu_file_name STRING
	DEFINE modu_path_name STRING
	
	DEFINE l_query1_text CHAR(500)
	DEFINE l_query2_text CHAR(500)
	DEFINE l_rec_glrepdetl RECORD LIKE glrepdetl.*
	DEFINE l_rec_accounthist RECORD LIKE accounthist.*
	DEFINE l_rec_account RECORD LIKE account.*
	DEFINE l_rec_s_accounthist RECORD LIKE accounthist.*
	DEFINE l_rec_glrepdata RECORD LIKE glrepdata.*
	DEFINE l_rec_coa RECORD LIKE coa.*
	DEFINE l_rec_glrepgroup RECORD LIKE glrepgroup.*
	DEFINE l_rec_glrepsubgrp RECORD LIKE glrepsubgrp.*
	--DEFINE l_chart CHAR(18) 
	DEFINE l_query3_text CHAR(300) 
	DEFINE i SMALLINT
	DEFINE j SMALLINT
	DEFINE l_msgresp LIKE language.yes_flag 

	##DEBUG
	#DEFINE cur_v CURSOR
	#DEFINE ret_rec RECORD
	#	acct_code LIKE coa.acct_code,
	#	chart_code LIKE account.chart_code
	#	END RECORD

	IF modu_where1_text IS NULL THEN 
		LET modu_where1_text = "1=1" 
	END IF 
	IF modu_where2_text IS NULL THEN 
		LET modu_where2_text = "1=1" 
	END IF 
	IF modu_where3_text IS NULL THEN 
		LET modu_where3_text = "1=1" 
	END IF 

	LET l_query1_text = "SELECT glrepdetl.* FROM glrepdetl, glrephead ", 
	" WHERE glrepdetl.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND glrephead.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND glrephead.rept_code = glrepdetl.rept_code", 
	" AND ",modu_where1_text clipped 
	LET l_query2_text = "SELECT * FROM accounthist ", 
	" WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND acct_code = ? ", 
	" AND ",modu_where2_text clipped 
	LET l_msgresp=kandoomsg("U",1506,"") --returns empty STRING ??? 


	#1506 Searching Database Please Stand By"
	PREPARE s_glrepdetl FROM l_query1_text 
	DECLARE c_glrepdetl CURSOR FOR s_glrepdetl 

	PREPARE s_accounthist FROM l_query2_text 
	DECLARE c_accounthist CURSOR FOR s_accounthist 

	DELETE FROM t_accthist WHERE 1=1 

	#   OPEN WINDOW w1 WITH FORM "U999" ATTRIBUTES(BORDER)
	#		CALL windecoration_u("U999")

	#DISPLAY "Processing:" TO lbLabel1
	MESSAGE "Processing..." 

	LET l_query3_text = " SELECT acct_code FROM t_chart ", 
	" WHERE chart_code = ? ", 
	" AND ",modu_where3_text clipped 

	PREPARE s_coa FROM l_query3_text 
	DECLARE c_coa CURSOR FOR s_coa 

	FOREACH c_glrepdetl INTO l_rec_glrepdetl.* 
		IF int_flag OR quit_flag THEN 
			#8503 Continue Report(Y/N)
			IF kandoomsg("U",8503,"") = "N" THEN 
				#9501 Report Terminated
				LET l_msgresp=kandoomsg("U",9501,"") 
				EXIT FOREACH 
			END IF 

			LET int_flag = false 
			LET quit_flag = false 
		END IF 


		SELECT * INTO l_rec_glrepsubgrp.* FROM glrepsubgrp 
		WHERE group_code = l_rec_glrepdetl.group_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 


		SELECT * INTO l_rec_glrepgroup.* FROM glrepgroup 
		WHERE maingrp_code = l_rec_glrepsubgrp.maingrp_code 
		AND rept_code = l_rec_glrepdetl.rept_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 

		OPEN c_coa USING l_rec_glrepdetl.chart_code 

		FOREACH c_coa INTO l_rec_coa.acct_code 
			SELECT * INTO l_rec_coa.* 
			FROM coa 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND acct_code = l_rec_coa.acct_code 

			OPEN c_accounthist USING l_rec_coa.acct_code 

			FOREACH c_accounthist INTO l_rec_accounthist.* 
				#DISPLAY l_rec_accounthist.acct_code  TO lbLabel1b
				MESSAGE l_rec_accounthist.acct_code 

				IF int_flag OR quit_flag THEN 
					EXIT FOREACH 
				END IF 

				LET l_rec_glrepdata.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_rec_glrepdata.rept_code = l_rec_glrepdetl.rept_code 
				LET l_rec_glrepdata.maingroup_code = l_rec_glrepsubgrp.maingrp_code 
				LET l_rec_glrepdata.subgroup_code = l_rec_glrepdetl.group_code 
				LET l_rec_glrepdata.subgroup_text = l_rec_glrepsubgrp.desc_text 
				LET l_rec_glrepdata.ref_ind = l_rec_glrepdetl.ref_ind 
				LET l_rec_glrepdata.sort1_order = l_rec_glrepgroup.rept_order 
				LET l_rec_glrepdata.sort2_order = l_rec_glrepsubgrp.maingrp_order 
				LET l_rec_glrepdata.ledg_code = l_rec_accounthist.acct_code[1,2] 
				LET l_rec_glrepdata.locn_code = l_rec_accounthist.acct_code[3,4] 
				LET l_rec_glrepdata.group_code = l_rec_coa.group_code 
				LET l_rec_glrepdata.year_num = l_rec_accounthist.year_num 
				LET l_rec_glrepdata.period_num = l_rec_accounthist.period_num 
				LET l_rec_glrepdata.stats_qty = l_rec_accounthist.stats_qty 
				LET l_rec_glrepdata.pre_close_amt = l_rec_accounthist.pre_close_amt 
				LET l_rec_glrepdata.budg1_amt = l_rec_accounthist.budg1_amt 
				LET l_rec_glrepdata.budg2_amt = l_rec_accounthist.budg2_amt 
				LET l_rec_glrepdata.budg3_amt = l_rec_accounthist.budg3_amt 
				LET l_rec_glrepdata.budg4_amt = l_rec_accounthist.budg4_amt 
				LET l_rec_glrepdata.budg5_amt = l_rec_accounthist.budg5_amt 
				LET l_rec_glrepdata.budg6_amt = l_rec_accounthist.budg6_amt 
				LET l_rec_glrepdata.ytd_pre_close_amt = 
				l_rec_accounthist.ytd_pre_close_amt 
				LET l_rec_glrepdata.ytd_budg1_amt = l_rec_accounthist.ytd_budg1_amt 
				LET l_rec_glrepdata.ytd_budg2_amt = l_rec_accounthist.ytd_budg2_amt 
				LET l_rec_glrepdata.ytd_budg3_amt = l_rec_accounthist.ytd_budg3_amt 
				LET l_rec_glrepdata.ytd_budg4_amt = l_rec_accounthist.ytd_budg4_amt 
				LET l_rec_glrepdata.ytd_budg5_amt = l_rec_accounthist.ytd_budg5_amt 
				LET l_rec_glrepdata.ytd_budg6_amt = l_rec_accounthist.ytd_budg6_amt 

				SELECT sum(stats_qty) INTO l_rec_glrepdata.ytd_stats_qty 
				FROM accounthist 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = l_rec_accounthist.acct_code 
				AND period_num between 1 AND l_rec_accounthist.period_num 
				AND year_num = l_rec_accounthist.year_num 

				IF l_rec_glrepdata.lytd_stats_qty IS NULL THEN 
					LET l_rec_glrepdata.lytd_stats_qty = 0 
				END IF 

				SELECT * INTO l_rec_s_accounthist.* FROM accounthist 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = l_rec_accounthist.acct_code 
				AND period_num = l_rec_accounthist.period_num 
				AND year_num = l_rec_accounthist.year_num - 1 

				IF status = 0 THEN 
					LET l_rec_glrepdata.lytd_pre_close_amt = 
					l_rec_s_accounthist.ytd_pre_close_amt 
					LET l_rec_glrepdata.lytd_budg1_amt = l_rec_s_accounthist.ytd_budg1_amt 
					LET l_rec_glrepdata.lytd_budg2_amt = l_rec_s_accounthist.ytd_budg2_amt 
					LET l_rec_glrepdata.lytd_budg3_amt = l_rec_s_accounthist.ytd_budg3_amt 
					LET l_rec_glrepdata.lytd_budg4_amt = l_rec_s_accounthist.ytd_budg4_amt 
					LET l_rec_glrepdata.lytd_budg5_amt = l_rec_s_accounthist.ytd_budg5_amt 
					LET l_rec_glrepdata.lytd_budg6_amt = l_rec_s_accounthist.ytd_budg6_amt 
				ELSE 
					LET l_rec_glrepdata.lytd_pre_close_amt =0 
					LET l_rec_glrepdata.lytd_budg1_amt = 0 
					LET l_rec_glrepdata.lytd_budg2_amt = 0 
					LET l_rec_glrepdata.lytd_budg3_amt = 0 
					LET l_rec_glrepdata.lytd_budg4_amt = 0 
					LET l_rec_glrepdata.lytd_budg5_amt = 0 
					LET l_rec_glrepdata.lytd_budg6_amt = 0 
				END IF 

				SELECT sum(stats_qty) INTO l_rec_glrepdata.lytd_stats_qty 
				FROM accounthist 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = l_rec_accounthist.acct_code 
				AND period_num between 1 AND l_rec_accounthist.period_num 
				AND year_num = l_rec_accounthist.year_num - 1 

				IF l_rec_glrepdata.lytd_stats_qty IS NULL THEN 
					LET l_rec_glrepdata.lytd_stats_qty = 0 
				END IF 

				INSERT INTO t_accthist VALUES (l_rec_glrepdata.*) 

				IF int_flag OR quit_flag THEN 
					EXIT FOREACH 
				END IF 

			END FOREACH 

		END FOREACH 

	END FOREACH 

	#DISPLAY "" AT 1,2
	#DISPLAY "Sorting...:" TO lbLabel1 -- 1,2
	MESSAGE "Sorting..." 

	#INSERT INTO glrepdata
	LET modu_file_name = modu_path_name clipped,"\/", modu_file_name 
	UNLOAD TO modu_file_name 

	SELECT cmpy_code, 
	rept_code, 
	maingroup_code, 
	subgroup_code, 
	subgroup_text, 
	ref_ind, 
	sort1_order, 
	sort2_order, 
	ledg_code, 
	locn_code, 
	group_code, 
	year_num, 
	period_num, 
	sum(stats_qty), 
	sum(pre_close_amt), 
	sum(budg1_amt), 
	sum(budg2_amt), 
	sum(budg3_amt), 
	sum(budg4_amt), 
	sum(budg5_amt), 
	sum(budg6_amt), 
	sum(ytd_stats_qty), 
	sum(ytd_pre_close_amt), 
	sum(ytd_budg1_amt), 
	sum(ytd_budg2_amt), 
	sum(ytd_budg3_amt), 
	sum(ytd_budg4_amt), 
	sum(ytd_budg5_amt), 
	sum(ytd_budg6_amt), 
	sum(lytd_stats_qty), 
	sum(lytd_pre_close_amt), 
	sum(lytd_budg1_amt), 
	sum(lytd_budg2_amt), 
	sum(lytd_budg3_amt), 
	sum(lytd_budg4_amt), 
	sum(lytd_budg5_amt), 
	sum(lytd_budg6_amt) 
	FROM t_accthist 
	GROUP BY cmpy_code, 
	rept_code, 
	maingroup_code, 
	subgroup_code, 
	subgroup_text, 
	ref_ind, 
	sort1_order, 
	sort2_order, 
	ledg_code, 
	locn_code, 
	group_code, 
	year_num, 
	period_num 

	# CLOSE WINDOW w1

END FUNCTION 