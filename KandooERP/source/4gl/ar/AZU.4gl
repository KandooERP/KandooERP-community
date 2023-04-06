###########################################################################
# This program IS free software; you can redistribute it AND/OR modify itmodu_arr_rec_trigger
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
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/AZ_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/AZU_GLOBALS.4gl" 
############################################################
# Module Scope Variables
############################################################
--DEFINE modu_arr_rec_trigger array[10] OF
DEFINE modu_arr_rec_trigger DYNAMIC ARRAY OF 
RECORD 
	scroll_flag CHAR(1), 
	trig_name_text CHAR(30), 
	trig_status_text CHAR(10) 
END RECORD 
DEFINE modu_trig_cnt SMALLINT 


#############################################################################
# MAIN
#
# Customer trigger maintenance program
#############################################################################
MAIN 
	DEFINE database_owner LIKE sysmaster:sysdatabases.owner

	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("AZU") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
--	CALL init_a_ar() #init a/ar module #KD-2113

	OPEN WINDOW U509 with FORM "U509" 
	CALL windecoration_u("U509") 

	SELECT owner INTO database_owner  # alch KD-2113: Check User permissions in verify_user_role_and_security_level_for_module() function 
	FROM sysmaster:sysdatabases 
	WHERE name =  dbinfo('dbname')
	
	IF glob_rec_kandoouser.login_name != "informix" AND database_owner != glob_rec_kandoouser.login_name THEN   
		MESSAGE kandoomsg2("U",5004,"") 
	ELSE 
		CALL initialize_array() 
		CALL scan_triggers() 
	END IF 
	CLOSE WINDOW u509 
END MAIN 
#############################################################################
# END MAIN
#############################################################################


#############################################################################
# FUNCTION INITIALIZE_array()
#
#
#############################################################################
FUNCTION initialize_array() 

	LET modu_trig_cnt = 1 
	LET modu_arr_rec_trigger[1].trig_name_text = "Customer" 
	IF trigger_status(modu_trig_cnt) THEN 
		LET modu_arr_rec_trigger[1].trig_status_text = "ENABLED" 
	ELSE 
		LET modu_arr_rec_trigger[1].trig_status_text = "DISABLED" 
	END IF 
END FUNCTION 


#############################################################################
# FUNCTION scan_triggers()
#
#
#############################################################################
FUNCTION scan_triggers() 
	DEFINE idx SMALLINT #, scrn 

	CALL set_count(modu_trig_cnt) 
	MESSAGE kandoomsg2("U",1018,"") 

	DISPLAY ARRAY modu_arr_rec_trigger TO sr_trigger.* ATTRIBUTES(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","AZU","display-arr-trigger") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION ("EDIT","doubleClick") 
			LET idx = arr_curr() 
			#LET scrn = scr_line()
			IF modu_arr_rec_trigger[idx].trig_status_text = "DISABLED" THEN 
				LET modu_arr_rec_trigger[idx].trig_status_text = "ENABLED" 
			ELSE 
				LET modu_arr_rec_trigger[idx].trig_status_text = "DISABLED" 
			END IF 
			#   DISPLAY modu_arr_rec_trigger[idx].trig_status_text
			#        TO sr_trigger[scrn].trig_status_text



		ON KEY (tab) --change state 
			LET idx = arr_curr() 
			#LET scrn = scr_line()
			IF modu_arr_rec_trigger[idx].trig_status_text = "DISABLED" THEN 
				LET modu_arr_rec_trigger[idx].trig_status_text = "ENABLED" 
			ELSE 
				LET modu_arr_rec_trigger[idx].trig_status_text = "DISABLED" 
			END IF 
			#         DISPLAY modu_arr_rec_trigger[idx].trig_status_text
			#              TO sr_trigger[scrn].trig_status_text

		ON ACTION "ACCEPT" --huho ON KEY (RETURN) 
{
			--# IF fgl_fglgui() THEN
			--#   EXIT DISPLAY
			--# END IF
			LET idx = arr_curr() 
			#LET scrn = scr_line()
			IF modu_arr_rec_trigger[idx].trig_status_text = "DISABLED" THEN 
				LET modu_arr_rec_trigger[idx].trig_status_text = "ENABLED" 
			ELSE 
				LET modu_arr_rec_trigger[idx].trig_status_text = "DISABLED" 
			END IF 
			#DISPLAY modu_arr_rec_trigger[idx].trig_status_text
			#     TO sr_trigger[scrn].trig_status_text
}
			EXIT DISPLAY

	END DISPLAY 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 
		ERROR kandoomsg2("U",1010,"") 
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
#############################################################################
# END FUNCTION INITIALIZE_array()
#############################################################################


#############################################################################
# FUNCTION trigger_status(p_trig_num)
#
#
#############################################################################
FUNCTION trigger_status(p_trig_num) 
	DEFINE p_trig_num SMALLINT 
	DEFINE cnt SMALLINT 

	CASE p_trig_num 
		WHEN 1 
			SELECT count(*) INTO cnt FROM systriggers 
			WHERE trigname matches "customertrig[123]" 
			CASE 
				WHEN cnt = 0 
					RETURN false 
				WHEN cnt = 3 
					RETURN true 
				OTHERWISE 
					CALL trigger_drop(p_trig_num) 
					ERROR kandoomsg2("U",7017,"Customer") 
					RETURN false 
			END CASE 
	END CASE 
END FUNCTION 
#############################################################################
# END FUNCTION trigger_status(p_trig_num)
#############################################################################


#############################################################################
# FUNCTION trigger_create(p_trig_num)
#
#
#############################################################################
FUNCTION trigger_create(p_trig_num) 
	DEFINE p_trig_num SMALLINT 
	DEFINE l_trig_text CHAR(10000) 

	CASE p_trig_num 
		WHEN 1 
			LET l_trig_text = 
				"create trigger customertrig1 ", 
				"INSERT on customer referencing new as post FOR each row ", 
				" (INSERT INTO customeraudit VALUES(post.cmpy_code,", 
				"post.cust_code,", 
				"post.name_text,", 
				"post.addr1_text,", 
				"post.addr2_text,", 
				"post.city_text,", 
				"post.state_code,", 
				"post.post_code,", 
--@db-patch_2020_10_04--			"post.country_text,", 
				"post.country_code,", 
				"post.language_code,", 
				"post.type_code,", 
				"post.sale_code,", 
				"post.term_code,", 
				"post.tax_code,", 
				"post.tax_num_text,", 
				"post.contact_text,", 
				"post.tele_text,", 
				"post.mobile_phone,", #added
				"post.email,", #added						
				"post.cred_limit_amt,", 
				"post.inv_level_ind,", 
				"post.dun_code,", 
				"post.stmnt_ind,", 
				"post.territory_code,", 
				"post.bank_acct_code,", 
				"post.delete_flag,", 
				"post.delete_date,", 
				"post.hold_code,", 
				"post.ref1_code,", 
				"post.ref2_code,", 
				"post.ref3_code,", 
				"post.ref4_code,", 
				"post.ref5_code,", 
				"post.ref6_code,", 
				"post.ref7_code,", 
				"post.ref8_code,", 
				"post.mobile_phone,", 
				"post.ord_text_ind,", 
				"user,current,'1',' ',", 
				"post.vat_code))" 

			WHENEVER ERROR CONTINUE 
			PREPARE s1_ins_trig FROM l_trig_text 
			EXECUTE s1_ins_trig 
			WHENEVER ERROR stop 
			WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

			LET l_trig_text = 
			"create trigger customertrig2 ", 
			"UPDATE of cmpy_code,", 
			"cust_code,", 
			"name_text,", 
			"addr1_text,", 
			"addr2_text,", 
			"city_text,", 
			"state_code,", 
			"post_code,", 
			"country_text,", 
			"country_code,", 
			"language_code,", 
			"type_code,", 
			"sale_code,", 
			"term_code,", 
			"tax_code,", 
			"tax_num_text,", 
			"contact_text,", 
			"tele_text,", 
			"mobile_phone,",
			"email,",						
			"cred_limit_amt,", 
			"inv_level_ind,", 
			"dun_code,", 
			"stmnt_ind,", 
			"territory_code,", 
			"bank_acct_code,", 
			"delete_flag,", 
			"delete_date,", 
			"hold_code,", 
			"ref1_code,", 
			"ref2_code,", 
			"ref3_code,", 
			"ref4_code,", 
			"ref5_code,", 
			"ref6_code,", 
			"ref7_code,", 
			"ref8_code,", 
			"mobile_phone,", 
			"ord_text_ind,", 
			"vat_code ON customer ", 
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
			"((pre.sale_code IS NULL AND post.sale_code IS NOT null) OR", 
			"(post.sale_code IS NULL AND pre.sale_code IS NOT null) OR", 
			"(post.sale_code != pre.sale_code)) OR ", 
			"((pre.term_code IS NULL AND post.term_code IS NOT null) OR", 
			"(post.term_code IS NULL AND pre.term_code IS NOT null) OR", 
			"(post.term_code != pre.term_code)) OR ", 
			"((pre.tax_code IS NULL AND post.tax_code IS NOT null) OR", 
			"(post.tax_code IS NULL AND pre.tax_code IS NOT null) OR", 
			"(post.tax_code != pre.tax_code)) OR ", 
			"((pre.tax_num_text IS NULL AND post.tax_num_text IS NOT null) OR", 
			"(post.tax_num_text IS NULL AND pre.tax_num_text IS NOT null) OR", 
			"(post.tax_num_text != pre.tax_num_text)) OR ", 
			"((pre.contact_text IS NULL AND post.contact_text IS NOT null) OR", 
			"(post.contact_text IS NULL AND pre.contact_text IS NOT null) OR", 
			"(post.contact_text != pre.contact_text)) OR ", 
			"((pre.tele_text IS NULL AND post.tele_text IS NOT null) OR", 
			"(post.tele_text IS NULL AND pre.tele_text IS NOT null) OR", 
			"(post.tele_text != pre.tele_text)) OR ", 
			"((pre.cred_limit_amt IS NULL AND post.cred_limit_amt IS NOT null) OR", 
			"(post.cred_limit_amt IS NULL AND pre.cred_limit_amt IS NOT null) OR", 
			"(post.cred_limit_amt != pre.cred_limit_amt)) OR ", 
			"((pre.inv_level_ind IS NULL AND post.inv_level_ind IS NOT null) OR", 
			"(post.inv_level_ind IS NULL AND pre.inv_level_ind IS NOT null) OR", 
			"(post.inv_level_ind != pre.inv_level_ind)) OR ", 
			"((pre.dun_code IS NULL AND post.dun_code IS NOT null) OR", 
			"(post.dun_code IS NULL AND pre.dun_code IS NOT null) OR", 
			"(post.dun_code != pre.dun_code)) OR ", 
			"((pre.stmnt_ind IS NULL AND post.stmnt_ind IS NOT null) OR", 
			"(post.stmnt_ind IS NULL AND pre.stmnt_ind IS NOT null) OR", 
			"(post.stmnt_ind != pre.stmnt_ind)) OR ", 
			"((pre.territory_code IS NULL AND post.territory_code IS NOT null) OR", 
			"(post.territory_code IS NULL AND pre.territory_code IS NOT null) OR", 
			"(post.territory_code != pre.territory_code)) OR ", 
			"((pre.bank_acct_code IS NULL AND post.bank_acct_code IS NOT null) OR", 
			"(post.bank_acct_code IS NULL AND pre.bank_acct_code IS NOT null) OR", 
			"(post.bank_acct_code != pre.bank_acct_code)) OR ", 
			"((pre.delete_flag IS NULL AND post.delete_flag IS NOT null) OR", 
			"(post.delete_flag IS NULL AND pre.delete_flag IS NOT null) OR", 
			"(post.delete_flag != pre.delete_flag)) OR ", 
			"((pre.delete_date IS NULL AND post.delete_date IS NOT null) OR", 
			"(post.delete_date IS NULL AND pre.delete_date IS NOT null) OR", 
			"(post.delete_date != pre.delete_date)) OR ", 
			"((pre.hold_code IS NULL AND post.hold_code IS NOT null) OR", 
			"(post.hold_code IS NULL AND pre.hold_code IS NOT null) OR", 
			"(post.hold_code != pre.hold_code)) OR ", 
			"((pre.ref1_code IS NULL AND post.ref1_code IS NOT null) OR", 
			"(post.ref1_code IS NULL AND pre.ref1_code IS NOT null) OR", 
			"(post.ref1_code != pre.ref1_code)) OR ", 
			"((pre.ref2_code IS NULL AND post.ref2_code IS NOT null) OR", 
			"(post.ref2_code IS NULL AND pre.ref2_code IS NOT null) OR", 
			"(post.ref2_code != pre.ref2_code)) OR ", 
			"((pre.ref3_code IS NULL AND post.ref3_code IS NOT null) OR", 
			"(post.ref3_code IS NULL AND pre.ref3_code IS NOT null) OR", 
			"(post.ref3_code != pre.ref3_code)) OR ", 
			"((pre.ref4_code IS NULL AND post.ref4_code IS NOT null) OR", 
			"(post.ref4_code IS NULL AND pre.ref4_code IS NOT null) OR", 
			"(post.ref4_code != pre.ref4_code)) OR ", 
			"((pre.ref5_code IS NULL AND post.ref5_code IS NOT null) OR", 
			"(post.ref5_code IS NULL AND pre.ref5_code IS NOT null) OR", 
			"(post.ref5_code != pre.ref5_code)) OR ", 
			"((pre.ref6_code IS NULL AND post.ref6_code IS NOT null) OR", 
			"(post.ref6_code IS NULL AND pre.ref6_code IS NOT null) OR", 
			"(post.ref6_code != pre.ref6_code)) OR ", 
			"((pre.ref7_code IS NULL AND post.ref7_code IS NOT null) OR", 
			"(post.ref7_code IS NULL AND pre.ref7_code IS NOT null) OR", 
			"(post.ref7_code != pre.ref7_code)) OR ", 
			"((pre.ref8_code IS NULL AND post.ref8_code IS NOT null) OR", 
			"(post.ref8_code IS NULL AND pre.ref8_code IS NOT null) OR", 
			"(post.ref8_code != pre.ref8_code)) OR ", 
			"((pre.mobile_phone IS NULL AND post.mobile_phone IS NOT null) OR", 
			"(post.mobile_phone IS NULL AND pre.mobile_phone IS NOT null) OR", 
			"(post.mobile_phone != pre.mobile_phone)) OR ", 
			"((pre.vat_code IS NULL AND post.vat_code IS NOT null) OR", 
			"(post.vat_code IS NULL AND pre.vat_code IS NOT null) OR", 
			"(post.vat_code != pre.vat_code)) OR ", 
			"((pre.ord_text_ind IS NULL AND post.ord_text_ind IS NOT null) OR", 
			"(post.ord_text_ind IS NULL AND pre.ord_text_ind IS NOT null) OR", 
			"(post.ord_text_ind != pre.ord_text_ind)) ) ", 
			" (INSERT INTO customeraudit VALUES(pre.cmpy_code,", 
			"pre.cust_code,", 
			"pre.name_text,", 
			"pre.addr1_text,", 
			"pre.addr2_text,", 
			"pre.city_text,", 
			"pre.state_code,", 
			"pre.post_code,", 
--@db-patch_2020_10_04--			"pre.country_text,", 
			"pre.country_code,", 
			"pre.language_code,", 
			"pre.type_code,", 
			"pre.sale_code,", 
			"pre.term_code,", 
			"pre.tax_code,", 
			"pre.tax_num_text,", 
			"pre.contact_text,", 
			"pre.tele_text,", 
			"pre.mobile_phone,",
			"pre.email,",						
			"pre.cred_limit_amt,", 
			"pre.inv_level_ind,", 
			"pre.dun_code,", 
			"pre.stmnt_ind,", 
			"pre.territory_code,", 
			"pre.bank_acct_code,", 
			"pre.delete_flag,", 
			"pre.delete_date,", 
			"pre.hold_code,", 
			"pre.ref1_code,", 
			"pre.ref2_code,", 
			"pre.ref3_code,", 
			"pre.ref4_code,", 
			"pre.ref5_code,", 
			"pre.ref6_code,", 
			"pre.ref7_code,", 
			"pre.ref8_code,", 
			"pre.mobile_phone,", 
			"pre.ord_text_ind,", 
			"user,current,'2',' ',", 
			"pre.vat_code)) " 
			PREPARE s2_upd_trig FROM l_trig_text 
			EXECUTE s2_upd_trig 
			LET l_trig_text = 
			"create trigger customertrig3 ", 
			"delete on customer referencing old as pre FOR each row ", 
			" (INSERT INTO customeraudit VALUES(pre.cmpy_code,", 
			"pre.cust_code,", 
			"pre.name_text,", 
			"pre.addr1_text,", 
			"pre.addr2_text,", 
			"pre.city_text,", 
			"pre.state_code,", 
			"pre.post_code,", 
--@db-patch_2020_10_04--			"pre.country_text,", 
			"pre.country_code,", 
			"pre.language_code,", 
			"pre.type_code,", 
			"pre.sale_code,", 
			"pre.term_code,", 
			"pre.tax_code,", 
			"pre.tax_num_text,", 
			"pre.contact_text,", 
			"pre.tele_text,", 
			"pre.mobile_phone,",
			"pre.email,",							
			"pre.cred_limit_amt,", 
			"pre.inv_level_ind,", 
			"pre.dun_code,", 
			"pre.stmnt_ind,", 
			"pre.territory_code,", 
			"pre.bank_acct_code,", 
			"pre.delete_flag,", 
			"pre.delete_date,", 
			"pre.hold_code,", 
			"pre.ref1_code,", 
			"pre.ref2_code,", 
			"pre.ref3_code,", 
			"pre.ref4_code,", 
			"pre.ref5_code,", 
			"pre.ref6_code,", 
			"pre.ref7_code,", 
			"pre.ref8_code,", 
			"pre.mobile_phone,", 
			"pre.ord_text_ind,", 
			"user,current,'3',' ',", 
			"pre.vat_code)) " 
			PREPARE s2_del_trig FROM l_trig_text 
			EXECUTE s2_del_trig 
			ERROR kandoomsg2("U",7014,"Customer") 
	END CASE 
	
END FUNCTION 
#############################################################################
# END FUNCTION trigger_create(p_trig_num)
#############################################################################


#############################################################################
# FUNCTION trigger_drop(l_trig_num)
#
#
#############################################################################
FUNCTION trigger_drop(l_trig_num) 
	DEFINE l_trig_num SMALLINT 
	DEFINE l_drop_text CHAR(200) 
	
	CASE l_trig_num 
		WHEN 1 
			LET l_drop_text = 
				"drop trigger customertrig1;", 
				"drop trigger customertrig2;", 
				"drop trigger customertrig3;" 
			
			WHENEVER ERROR CONTINUE 
			PREPARE s3_customer FROM l_drop_text 
			EXECUTE s3_customer 
			WHENEVER ERROR stop 
			WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
			
			MESSAGE kandoomsg2("U",7015,"Customer") 
	END CASE 
END FUNCTION 
#############################################################################
# END FUNCTION trigger_drop(l_trig_num)
#############################################################################