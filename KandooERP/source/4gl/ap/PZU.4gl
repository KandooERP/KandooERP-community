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

	Source code beautified by beautify.pl on 2020-01-03 13:41:52	$Id: $
}
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 

############################################################
# Module Scope Variables
############################################################
DEFINE modu_arr_rec_trigger ARRAY[10] OF 
RECORD 
	scroll_flag CHAR(1), 
	trig_name_text CHAR(30), ### NAME OF trigger 
	trig_status_text CHAR(10) ### status "ENABLED" OR "DISABLED" 
END RECORD 
DEFINE modu_trig_cnt SMALLINT 

############################################################
# MAIN
#
# \brief module - PZU Create Audit Tables AND associated Triggers.
############################################################
MAIN 
	DEFINE l_msgresp LIKE language.yes_flag 

	CALL setModuleId("PZU") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	OPEN WINDOW u509 with FORM "U509" 
	CALL windecoration_p("P509") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	#Do OR don'T - We are NOT working with database users security
	#original code
	#SELECT * FROM sysusers
	# WHERE username = glob_rec_kandoouser.sign_on_code
	#   AND usertype = "D"
	#IF STATUS = 0 THEN
	IF glob_rec_kandoouser.sign_on_code = "Admin" THEN #we only allow the admin user TO do db changes 
		CALL initialize_array() 
		CALL scan_triggers() 
	ELSE 
		LET l_msgresp=kandoomsg("U",5004,"") 
		#5004 "You must be logged on as root TO maintain audit tables"
	END IF 
	CLOSE WINDOW u509 
END MAIN 


############################################################
# FUNCTION scan_triggers()
#
#
############################################################
FUNCTION scan_triggers() 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE idx SMALLINT

	CALL set_count(modu_trig_cnt) 
	LET l_msgresp=kandoomsg("U",1018,"") 
	#1018 "Enter RETURN TO toggle STATUS

	DISPLAY ARRAY modu_arr_rec_trigger TO sr_trigger.* 

		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","PZU","display-arr-trigger") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "EDIT" 
			LET idx = arr_curr() 
			#LET scrn = scr_line()
			IF modu_arr_rec_trigger[idx].trig_status_text = "DISABLED" THEN 
				LET modu_arr_rec_trigger[idx].trig_status_text = "ENABLED" 
			ELSE 
				LET modu_arr_rec_trigger[idx].trig_status_text = "DISABLED" 
			END IF 
			#DISPLAY modu_arr_rec_trigger[idx].trig_status_text
			#     TO sr_trigger[scrn].trig_status_text

		ON KEY (tab) 
			LET idx = arr_curr() 
			#LET scrn = scr_line()
			IF modu_arr_rec_trigger[idx].trig_status_text = "DISABLED" THEN 
				LET modu_arr_rec_trigger[idx].trig_status_text = "ENABLED" 
			ELSE 
				LET modu_arr_rec_trigger[idx].trig_status_text = "DISABLED" 
			END IF 
			#DISPLAY modu_arr_rec_trigger[idx].trig_status_text
			#    TO sr_trigger[scrn].trig_status_text

		ON ACTION "ACCEPT" #was KEY(RETURN) 
			#--#IF fgl_fglgui() THEN
			#--#   EXIT display
			#--#END IF
			LET idx = arr_curr() 
			#LET scrn = scr_line()
			IF modu_arr_rec_trigger[idx].trig_status_text = "DISABLED" THEN 
				LET modu_arr_rec_trigger[idx].trig_status_text = "ENABLED" 
			ELSE 
				LET modu_arr_rec_trigger[idx].trig_status_text = "DISABLED" 
			END IF 
			#DISPLAY modu_arr_rec_trigger[idx].trig_status_text
			#     TO sr_trigger[scrn].trig_status_text


	END DISPLAY 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 
		LET l_msgresp=kandoomsg("U",1010,"") 
		#1010 "Enter RETURN TO toggle STATUS
		FOR idx = 1 TO arr_count() 
			IF modu_arr_rec_trigger[idx].trig_status_text = "DISABLED" THEN 
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


############################################################
# FUNCTION INITIALIZE_array()
#
#
############################################################
FUNCTION initialize_array() 
	LET modu_trig_cnt = 1 
	LET modu_arr_rec_trigger[1].trig_name_text = "Vendor" 
	IF trigger_status(modu_trig_cnt) THEN 
		LET modu_arr_rec_trigger[1].trig_status_text = "ENABLED" 
	ELSE 
		LET modu_arr_rec_trigger[1].trig_status_text = "DISABLED" 
	END IF 
END FUNCTION 



############################################################
# FUNCTION INITIALIZE_array()
#
#
############################################################
FUNCTION trigger_status(p_trig_num) 
	DEFINE p_trig_num SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE cnt SMALLINT

	CASE p_trig_num 
		WHEN 1 
			SELECT count(*) INTO cnt FROM systriggers 
			WHERE trigname matches "vendortrig[123]" 
			CASE 
				WHEN cnt = 0 
					RETURN false 
				WHEN cnt = 3 
					RETURN true 
				OTHERWISE 
					CALL trigger_drop(p_trig_num) 
					LET l_msgresp = kandoomsg("U",7017,"Vendor") 
					RETURN false 
			END CASE 
	END CASE 
END FUNCTION 



############################################################
# FUNCTION trigger_create(p_trig_num)
#
#
############################################################
FUNCTION trigger_create(p_trig_num) 
	DEFINE p_trig_num SMALLINT 
	DEFINE l_trig_text CHAR(10000) 
	DEFINE l_msgresp LIKE language.yes_flag 

	CASE p_trig_num 
		WHEN 1 
			############################################################################
			#                           Vendor Triggers                                #
			############################################################################
			LET l_trig_text = 
			"create trigger vendortrig1 ", 
			"INSERT on vendor ", 
			"referencing new as post ", 
			"FOR each row(INSERT INTO vendoraudit ", 
			"VALUES (post.cmpy_code,post.vend_code,post.name_text,", 
			"post.addr1_text,post.addr2_text,post.addr3_text,", 
			"post.city_text,post.state_code,post.post_code,", 
			"post.country_code,post.language_code,",--@db-patch_2020_10_04-- post.country_text, 
			"post.type_code,post.term_code,post.tax_code,", 
			"post.tax_text,post.our_acct_code,post.contact_text,", 
			"post.tele_text,post.extension_text,post.limit_amt,", 
			"post.hold_code,post.usual_acct_code,post.drop_flag,", 
			"post.finance_per,post.fax_text,post.currency_code,", 
			"post.bank_acct_code,post.pay_meth_ind,user,current,'1',' ',", 
			"post.vat_code)) " 
			WHENEVER ERROR CONTINUE 
			PREPARE s1_ins_trig FROM l_trig_text 
			EXECUTE s1_ins_trig 
			WHENEVER ERROR stop 
			LET l_trig_text = 
			"create trigger vendortrig2 ", 
			"UPDATE of cmpy_code,vend_code,name_text,addr1_text,addr2_text,", 
			"addr3_text,city_text,state_code,post_code,country_text,", 
			"country_code,language_code,type_code,term_code,", 
			"tax_code,tax_text,our_acct_code,contact_text,tele_text,", 
			"extension_text,limit_amt,hold_code,usual_acct_code,", 
			"drop_flag,finance_per,fax_text,currency_code,", 
			"bank_acct_code,pay_meth_ind,vat_code ON vendor ", 
			"referencing old as pre new as post ", 
			"FOR each row WHEN (", 
			"((pre.name_text IS NULL AND post.name_text IS NOT null) OR", 
			"(post.name_text IS NULL AND pre.name_text IS NOT null) OR", 
			"(post.name_text != pre.name_text)) OR ", 
			"((pre.addr1_text IS NULL AND post.addr1_text IS NOT null) OR", 
			"(post.addr1_text IS NULL AND pre.addr1_text IS NOT null) OR", 
			"(post.addr1_text != pre.addr1_text)) OR ", 
			"((pre.addr2_text IS NULL AND post.addr2_text IS NOT null) OR", 
			"(post.addr2_text IS NULL AND pre.addr2_text IS NOT null) OR", 
			"(post.addr2_text != pre.addr2_text)) OR ", 
			"((pre.addr3_text IS NULL AND post.addr3_text IS NOT null) OR", 
			"(post.addr3_text IS NULL AND pre.addr3_text IS NOT null) OR", 
			"(post.addr3_text != pre.addr3_text)) OR ", 
			"((pre.city_text IS NULL AND post.city_text IS NOT null) OR", 
			"(post.city_text IS NULL AND pre.city_text IS NOT null) OR", 
			"(post.city_text != pre.city_text)) OR ", 
			"((pre.state_code IS NULL AND post.state_code IS NOT null) OR", 
			"(post.state_code IS NULL AND pre.state_code IS NOT null) OR", 
			"(post.state_code != pre.state_code)) OR ", 
			"((pre.post_code IS NULL AND post.post_code IS NOT null) OR", 
			"(post.post_code IS NULL AND pre.post_code IS NOT null) OR", 
			"(post.post_code != pre.post_code)) OR ", 
--@db-patch_2020_10_04--			"((pre.country_text IS NULL AND post.country_text IS NOT null) OR", 
--@db-patch_2020_10_04--			"(post.country_text IS NULL AND pre.country_text IS NOT null) OR", 
--@db-patch_2020_10_04--			"(post.country_text != pre.country_text)) OR ", 
			"((pre.country_code IS NULL AND post.country_code IS NOT null) OR", 
			"(post.country_code IS NULL AND pre.country_code IS NOT null) OR", 
			"(post.country_code != pre.country_code)) OR ", 
			"((pre.language_code IS NULL AND post.language_code IS NOT null) OR", 
			"(post.language_code IS NULL AND pre.language_code IS NOT null) OR", 
			"(post.language_code != pre.language_code)) OR ", 
			"((pre.type_code IS NULL AND post.type_code IS NOT null) OR", 
			"(post.type_code IS NULL AND pre.type_code IS NOT null) OR", 
			"(post.type_code != pre.type_code)) OR ", 
			"((pre.term_code IS NULL AND post.term_code IS NOT null) OR", 
			"(post.term_code IS NULL AND pre.term_code IS NOT null) OR", 
			"(post.term_code != pre.term_code)) OR ", 
			"((pre.tax_code IS NULL AND post.tax_code IS NOT null) OR", 
			"(post.tax_code IS NULL AND pre.tax_code IS NOT null) OR", 
			"(post.tax_code != pre.tax_code)) OR ", 
			"((pre.tax_text IS NULL AND post.tax_text IS NOT null) OR", 
			"(post.tax_text IS NULL AND pre.tax_text IS NOT null) OR", 
			"(post.tax_text != pre.tax_text)) OR ", 
			"((pre.our_acct_code IS NULL AND post.our_acct_code IS NOT null) OR", 
			"(post.our_acct_code IS NULL AND pre.our_acct_code IS NOT null) OR", 
			"(post.our_acct_code != pre.our_acct_code)) OR ", 
			"((pre.contact_text IS NULL AND post.contact_text IS NOT null) OR", 
			"(post.contact_text IS NULL AND pre.contact_text IS NOT null) OR", 
			"(post.contact_text != pre.contact_text)) OR ", 
			"((pre.tele_text IS NULL AND post.tele_text IS NOT null) OR", 
			"(post.tele_text IS NULL AND pre.tele_text IS NOT null) OR", 
			"(post.tele_text != pre.tele_text)) OR ", 
			"((pre.extension_text IS NULL AND post.extension_text IS NOT null) OR", 
			"(post.extension_text IS NULL AND pre.extension_text IS NOT null) OR", 
			"(post.extension_text != pre.extension_text)) OR ", 
			"((pre.limit_amt IS NULL AND post.limit_amt IS NOT null) OR", 
			"(post.limit_amt IS NULL AND pre.limit_amt IS NOT null) OR", 
			"(post.limit_amt != pre.limit_amt)) OR ", 
			"((pre.hold_code IS NULL AND post.hold_code IS NOT null) OR", 
			"(post.hold_code IS NULL AND pre.hold_code IS NOT null) OR", 
			"(post.hold_code != pre.hold_code)) OR ", 
			"((pre.usual_acct_code IS NULL AND post.usual_acct_code IS NOT null) OR", 
			"(post.usual_acct_code IS NULL AND pre.usual_acct_code IS NOT null) OR", 
			"(post.usual_acct_code != pre.usual_acct_code)) OR ", 
			"((pre.drop_flag IS NULL AND post.drop_flag IS NOT null) OR", 
			"(post.drop_flag IS NULL AND pre.drop_flag IS NOT null) OR", 
			"(post.drop_flag != pre.drop_flag)) OR ", 
			"((pre.finance_per IS NULL AND post.finance_per IS NOT null) OR", 
			"(post.finance_per IS NULL AND pre.finance_per IS NOT null) OR", 
			"(post.finance_per != pre.finance_per)) OR ", 
			"((pre.fax_text IS NULL AND post.fax_text IS NOT null) OR", 
			"(post.fax_text IS NULL AND pre.fax_text IS NOT null) OR", 
			"(post.fax_text != pre.fax_text)) OR ", 
			"((pre.currency_code IS NULL AND post.currency_code IS NOT null) OR", 
			"(post.currency_code IS NULL AND pre.currency_code IS NOT null) OR", 
			"(post.currency_code != pre.currency_code)) OR ", 
			"((pre.bank_acct_code IS NULL AND post.bank_acct_code IS NOT null) OR", 
			"(post.bank_acct_code IS NULL AND pre.bank_acct_code IS NOT null) OR", 
			"(post.bank_acct_code != pre.bank_acct_code)) OR ", 
			"((pre.vat_code IS NULL AND post.vat_code IS NOT null) OR", 
			"(post.vat_code IS NULL AND pre.vat_code IS NOT null) OR", 
			"(post.vat_code != pre.vat_code)) OR ", 
			"((pre.pay_meth_ind IS NULL AND post.pay_meth_ind IS NOT null) OR", 
			"(post.pay_meth_ind IS NULL AND pre.pay_meth_ind IS NOT null) OR", 
			"(post.pay_meth_ind != pre.pay_meth_ind)) ", 
			") (INSERT INTO vendoraudit ", 
			"VALUES (pre.cmpy_code,pre.vend_code,pre.name_text,", 
			"pre.addr1_text,pre.addr2_text,pre.addr3_text,", 
			"pre.city_text,pre.state_code,pre.post_code,", 
			"pre.country_code,pre.language_code,", --@db-patch_2020_10_04-- pre.country_text,
			"pre.type_code,pre.term_code,pre.tax_code,", 
			"pre.tax_text,pre.our_acct_code,pre.contact_text,", 
			"pre.tele_text,pre.extension_text,pre.limit_amt,", 
			"pre.hold_code,pre.usual_acct_code,pre.drop_flag,", 
			"pre.finance_per,pre.fax_text,pre.currency_code,", 
			"pre.bank_acct_code,pre.pay_meth_ind,user,current,'2',' ',", 
			"pre.vat_code)) " 
			PREPARE s1_upd_trig FROM l_trig_text 
			EXECUTE s1_upd_trig 
			LET l_trig_text = 
			"create trigger vendortrig3 ", 
			"delete on vendor ", 
			"referencing old as pre ", 
			"FOR each row(INSERT INTO vendoraudit ", 
			"VALUES (pre.cmpy_code,pre.vend_code,pre.name_text,", 
			"pre.addr1_text,pre.addr2_text,pre.addr3_text,", 
			"pre.city_text,pre.state_code,pre.post_code,", 
			"pre.country_code,pre.language_code,", --@db-patch_2020_10_04-- pre.country_codetext, 
			"pre.type_code,pre.term_code,pre.tax_code,", 
			"pre.tax_text,pre.our_acct_code,pre.contact_text,", 
			"pre.tele_text,pre.extension_text,pre.limit_amt,", 
			"pre.hold_code,pre.usual_acct_code,pre.drop_flag,", 
			"pre.finance_per,pre.fax_text,pre.currency_code,", 
			"pre.bank_acct_code,pre.pay_meth_ind,user,current,'3',' ',", 
			"pre.vat_code)) " 
			PREPARE s1_del_trig FROM l_trig_text 
			EXECUTE s1_del_trig 
			LET l_msgresp=kandoomsg("U",7014,"Vendor") 
			#7014 "Vendor Triggers Enabled"
	END CASE 
END FUNCTION 


############################################################
# FUNCTION trigger_drop(p_trig_num)
#
#
############################################################
FUNCTION trigger_drop(p_trig_num) 
	DEFINE p_trig_num SMALLINT 
	DEFINE l_drop_text CHAR(200) 
	DEFINE l_msgresp LIKE language.yes_flag 

	CASE p_trig_num 
		WHEN 1 
			LET l_drop_text = "drop trigger vendortrig1;", 
			"drop trigger vendortrig2;", 
			"drop trigger vendortrig3;" 
			WHENEVER ERROR CONTINUE 
			PREPARE s3_vendortrig FROM l_drop_text 
			EXECUTE s3_vendortrig 
			WHENEVER ERROR stop 
			LET l_msgresp=kandoomsg("U",7015,"Vendor") 
	END CASE 
END FUNCTION 


