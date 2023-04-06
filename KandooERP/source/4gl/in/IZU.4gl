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

	Source code beautified by beautify.pl on 2020-01-03 09:12:51	$Id: $
}




{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module - IZU Maintain Inventroy triggers
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 
DEFINE 
pa_trigger array[10] OF RECORD 
	scroll_flag CHAR(1), 
	trig_name_text CHAR(30), ### NAME OF trigger 
	trig_status_text CHAR(10) ### status "ENABLED" OR "DISABLED" 
END RECORD, 
pr_trig_cnt SMALLINT ### number OF triggers setup FOR TRAN_TYPE_INVOICE_IN 

{
FUNCTION IZU_whenever_sqlerror ()
    # this code instanciates the default sql errors handling for all the code lines below this function
    # it is a compiler preprocessor instruction. It is not necessary to execute that function
    WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
END FUNCTION
}
####################################################################
# MAIN
####################################################################
MAIN 
	#DEFINE l_msgresp LIKE language.yes_flag
	DEFINE l_msgresp CHAR(1)
	#Initial UI Init
	CALL setModuleId("IZU") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 

	OPEN WINDOW u509 with FORM "U509" 
	CALL winDecoration_u("U509") -- albo kd-758 

	IF UPSHIFT(glob_rec_kandoouser.sign_on_code) = "ADMIN" THEN -- albo kd-2020   
      # Only a database administrator can run this program
		CALL initialize_array() 
		CALL scan_triggers() 
	ELSE 
      CALL msgerror("","You must be a database administrator to run this program, exiting")
	END IF 
	CLOSE WINDOW u509 
END MAIN 


FUNCTION scan_triggers() 
	DEFINE 
	idx,scrn SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag

	CALL set_count(pr_trig_cnt) 
	LET l_msgresp=kandoomsg("U",1018,"") 
	#1018 "Enter RETURN TO toggle STATUS
	DISPLAY ARRAY pa_trigger TO sr_trigger.* 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","IZU","display-arr-trigger") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		ON KEY (tab) 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			IF pa_trigger[idx].trig_status_text = "DISABLED" THEN 
				LET pa_trigger[idx].trig_status_text = "ENABLED" 
			ELSE 
				LET pa_trigger[idx].trig_status_text = "DISABLED" 
			END IF 
			DISPLAY pa_trigger[idx].trig_status_text 
			TO sr_trigger[scrn].trig_status_text 

		ON KEY (RETURN) 
			--#IF fgl_fglgui() THEN
			--#   EXIT display
			--#END IF
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			IF pa_trigger[idx].trig_status_text = "DISABLED" THEN 
				LET pa_trigger[idx].trig_status_text = "ENABLED" 
			ELSE 
				LET pa_trigger[idx].trig_status_text = "DISABLED" 
			END IF 
			DISPLAY pa_trigger[idx].trig_status_text 
			TO sr_trigger[scrn].trig_status_text 
		ON KEY (F8) 
			LET idx = arr_curr() 
			CALL purge_trigger(idx) 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END DISPLAY 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 
		LET l_msgresp=kandoomsg("U",1010,"") 
		#1010 "Enter RETURN TO toggle STATUS
		FOR idx = 1 TO arr_count() 
			IF pa_trigger[idx].trig_status_text = "DISABLED" THEN 
				IF trigger_status(idx) THEN 
					CALL trigger_drop(idx) 
				END IF 
			ELSE 
				IF NOT trigger_status(idx) THEN 
					CALL trigger_create(idx) 
				END IF 
			END IF 
		END FOR 
	END IF 
END FUNCTION 


FUNCTION initialize_array() 
	LET pr_trig_cnt = 1 
	LET pa_trigger[1].trig_name_text = "Product Pricing" 
	IF trigger_status(pr_trig_cnt) THEN 
		LET pa_trigger[1].trig_status_text = "ENABLED" 
	ELSE 
		LET pa_trigger[1].trig_status_text = "DISABLED" 
	END IF 
END FUNCTION 


FUNCTION trigger_status(pr_trig_num) 
	DEFINE 
	pr_trig_num SMALLINT, 
	cnt SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag

	CASE pr_trig_num 
		WHEN 1 
			SELECT count(*) INTO cnt 
			FROM systriggers 
			WHERE trigname matches "prodstattrig[123]" 
			CASE 
				WHEN cnt = 0 
					RETURN false 
				WHEN cnt = 3 
					RETURN true 
				OTHERWISE 
					CALL trigger_drop(pr_trig_num) 
					LET l_msgresp = kandoomsg("U",7017,"Pricing") 
					RETURN false 
			END CASE 
	END CASE 
END FUNCTION 


FUNCTION trigger_create(pr_trig_num) 
	DEFINE 
	pr_trig_num SMALLINT, 
	pr_trig_text CHAR(10000) 
	DEFINE l_msgresp LIKE language.yes_flag

	CASE pr_trig_num 
		WHEN 1 
			LET pr_trig_text = 
			"create trigger prodstattrig1 ", 
			"INSERT on prodstatus referencing new as post FOR each row ", 
			" (INSERT INTO prodstatlog VALUES(post.cmpy_code,", 
			"post.part_code,", 
			"post.ware_code,", 
			"post.list_amt,", 
			"post.price1_amt,", 
			"post.price2_amt,", 
			"post.price3_amt,", 
			"post.price4_amt,", 
			"post.price5_amt,", 
			"post.price6_amt,", 
			"post.price7_amt,", 
			"post.price8_amt,", 
			"post.price9_amt,", 
			"post.est_cost_amt,", 
			"post.act_cost_amt,", 
			"post.for_cost_amt,", 
			"user,current,'1','',current))" 
			WHENEVER ERROR CONTINUE 
			PREPARE s6_ins_trig FROM pr_trig_text 
			EXECUTE s6_ins_trig 
			WHENEVER ERROR stop 
			LET pr_trig_text = 
			"create trigger prodstattrig2 ", 
			"UPDATE of cmpy_code,", 
			"part_code,", 
			"ware_code,", 
			"list_amt,", 
			"price1_amt,", 
			"price2_amt,", 
			"price3_amt,", 
			"price4_amt,", 
			"price5_amt,", 
			"price6_amt,", 
			"price7_amt,", 
			"price8_amt, ", 
			"price9_amt,", 
			"est_cost_amt,", 
			"act_cost_amt,", 
			"for_cost_amt ON prodstatus ", 
			"referencing old as pre new as post ", 
			"FOR each row WHEN (", 
			"((pre.list_amt IS NULL AND post.list_amt IS NOT null) OR", 
			"(post.list_amt IS NULL AND pre.list_amt IS NOT null) OR", 
			"(post.list_amt != pre.list_amt)) OR ", 
			"((pre.price1_amt IS NULL AND post.price1_amt IS NOT null) OR", 
			"(post.price1_amt IS NULL AND pre.price1_amt IS NOT null) OR", 
			"(post.price1_amt != pre.price1_amt)) OR ", 
			"((pre.price2_amt IS NULL AND post.price2_amt IS NOT null) OR", 
			"(post.price2_amt IS NULL AND pre.price2_amt IS NOT null) OR", 
			"(post.price2_amt != pre.price2_amt)) OR ", 
			"((pre.price3_amt IS NULL AND post.price3_amt IS NOT null) OR", 
			"(post.price3_amt IS NULL AND pre.price3_amt IS NOT null) OR", 
			"(post.price3_amt != pre.price3_amt)) OR ", 
			"((pre.price4_amt IS NULL AND post.price4_amt IS NOT null) OR", 
			"(post.price4_amt IS NULL AND pre.price4_amt IS NOT null) OR", 
			"(post.price4_amt != pre.price4_amt)) OR ", 
			"((pre.price5_amt IS NULL AND post.price5_amt IS NOT null) OR", 
			"(post.price5_amt IS NULL AND pre.price5_amt IS NOT null) OR", 
			"(post.price5_amt != pre.price5_amt)) OR ", 
			"((pre.price6_amt IS NULL AND post.price6_amt IS NOT null) OR", 
			"(post.price6_amt IS NULL AND pre.price6_amt IS NOT null) OR", 
			"(post.price6_amt != pre.price6_amt)) OR ", 
			"((pre.price7_amt IS NULL AND post.price7_amt IS NOT null) OR", 
			"(post.price7_amt IS NULL AND pre.price7_amt IS NOT null) OR", 
			"(post.price7_amt != pre.price7_amt)) OR ", 
			"((pre.price8_amt IS NULL AND post.price8_amt IS NOT null) OR", 
			"(post.price8_amt IS NULL AND pre.price8_amt IS NOT null) OR", 
			"(post.price8_amt != pre.price8_amt)) OR ", 
			"((pre.price9_amt IS NULL AND post.price9_amt IS NOT null) OR", 
			"(post.price9_amt IS NULL AND pre.price9_amt IS NOT null) OR", 
			"(post.price9_amt != pre.price9_amt)) OR ", 
			"((pre.est_cost_amt IS NULL AND post.est_cost_amt IS NOT NULL)OR", 
			"(post.est_cost_amt IS NULL AND pre.est_cost_amt IS NOT NULL)OR", 
			"(post.est_cost_amt != pre.est_cost_amt)) OR ", 
			"((pre.act_cost_amt IS NULL AND post.act_cost_amt IS NOT NULL)OR", 
			"(post.act_cost_amt IS NULL AND pre.act_cost_amt IS NOT NULL)OR", 
			"(post.act_cost_amt != pre.act_cost_amt)) OR ", 
			"((pre.for_cost_amt IS NULL AND post.for_cost_amt IS NOT NULL)OR", 
			"(post.for_cost_amt IS NULL AND pre.for_cost_amt IS NOT NULL)OR", 
			"(post.for_cost_amt != pre.for_cost_amt)) ) ", 
			" (INSERT INTO prodstatlog VALUES(post.cmpy_code,", 
			"post.part_code,", 
			"post.ware_code,", 
			"post.list_amt,", 
			"post.price1_amt,", 
			"post.price2_amt,", 
			"post.price3_amt,", 
			"post.price4_amt,", 
			"post.price5_amt,", 
			"post.price6_amt,", 
			"post.price7_amt,", 
			"post.price8_amt,", 
			"post.price9_amt,", 
			"post.est_cost_amt,", 
			"post.act_cost_amt,", 
			"post.for_cost_amt,", 
			"user,current,", 
			"'1','',current)) " 
			PREPARE s6_upd_trig FROM pr_trig_text 
			EXECUTE s6_upd_trig 
			LET pr_trig_text = 
			"create trigger prodstattrig3 ", 
			"delete on prodstatus referencing old as pre FOR each row ", 
			" (INSERT INTO prodstatlog VALUES(pre.cmpy_code,", 
			"pre.part_code,", 
			"pre.ware_code,", 
			"pre.list_amt,", 
			"pre.price1_amt,", 
			"pre.price2_amt,", 
			"pre.price3_amt,", 
			"pre.price4_amt,", 
			"pre.price5_amt,", 
			"pre.price6_amt,", 
			"pre.price7_amt,", 
			"pre.price8_amt,", 
			"pre.price9_amt,", 
			"pre.est_cost_amt,", 
			"pre.act_cost_amt,", 
			"pre.for_cost_amt,", 
			"user,current,'1','',current))" 
			PREPARE s6_del_trig FROM pr_trig_text 
			EXECUTE s6_del_trig 
			LET l_msgresp=kandoomsg("U",7014,"Pricing") 
			#7014 "Pricing Triggers Enabled"
	END CASE 
END FUNCTION 


FUNCTION trigger_drop(pr_trig_num) 
	DEFINE 
	pr_trig_num SMALLINT, 
	pr_drop_text CHAR(200) 
	DEFINE l_msgresp LIKE language.yes_flag

	CASE pr_trig_num 
		WHEN 1 
			LET pr_drop_text = "drop trigger prodstattrig1;", 
			"drop trigger prodstattrig2;", 
			"drop trigger prodstattrig3;" 
			WHENEVER ERROR CONTINUE 
			PREPARE s3_prodstattrig FROM pr_drop_text 
			EXECUTE s3_prodstattrig 
			WHENEVER ERROR stop 
			LET l_msgresp=kandoomsg("U",7015,"Pricing") 
			#7015 "Pricing Triggers Disabled"
	END CASE 
END FUNCTION 


FUNCTION purge_trigger(pr_trig_num) 
	DEFINE 
	pr_trig_num SMALLINT 

	error" Amendment log purging disabled" 
	#
	#  INPUT BY NAME pr_purge_date
	#  DELETE FROM prodstatlog WHERE audit_date <= pr_purge_date
	#
END FUNCTION 
