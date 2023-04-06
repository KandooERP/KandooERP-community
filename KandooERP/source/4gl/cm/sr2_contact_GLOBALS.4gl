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

	Source code beautified by beautify.pl on 2020-01-03 18:40:32	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl"


GLOBALS 

	DEFINE g_contact RECORD LIKE contact.*, 
	g_address RECORD LIKE address.*, 
	g_contact_address RECORD LIKE contact_address.*, 
	g_contact_mailing RECORD LIKE contact_mailing.*, 
	g_contact_comment RECORD LIKE contact_comment.*, 
	g_comment RECORD LIKE comment.*, 
	g_phone	RECORD LIKE phone.*, 
	g_contact_phone RECORD LIKE contact_phone.*, 
	g_bank_acc RECORD LIKE bank_acc.*, 
	g_contact_bank_acc RECORD LIKE contact_bank_acc.*, 
	g_credit_card RECORD LIKE credit_card.*, 
	g_contact_cc RECORD LIKE contact_cc.*, 
	g_contact_role RECORD LIKE contact_role.*, 
	g_contact_relation RECORD LIKE contact_relation.*, 
	a_comment array[10] OF RECORD 
		comment_line_id LIKE comment.comment_line_id, 
		comment_id LIKE comment.comment_id, 
		comment_text LIKE comment.comment_text 
	END RECORD, 
	p_role RECORD LIKE role.*, 
	p_cc_type RECORD LIKE cc_type.*, 
	p_time_restrict RECORD LIKE time_restrict.*, 
	p_mailing_role RECORD LIKE mailing_role.*, 
	p_mailing_dates	RECORD LIKE mailing_dates.*, 
	c_contact RECORD 
		age LIKE role.role_name 
	END RECORD, 
	c_phone	RECORD 
		time_restrict_name LIKE time_restrict.time_restrict_name, 
		phone_role_name LIKE role.role_name 
	END RECORD, 
	c_bank_acc RECORD 
		acc_role_name LIKE role.role_name 
	END RECORD, 
	
	c_credit_card RECORD 
		cc_type_name LIKE cc_type.cc_type_name, 
		cc_role_name LIKE role.role_name 
	END RECORD, 
	
	ga_grid array[10] OF CHAR (50), 
	gv_null, # NULL returned variable 
	cnt, 
	len, 
	yes, 
	current_form, #contact 
	current_addr_form, #address 
	current_comm_form, #comment 
	current_phone_form, #phone 
	current_bank_acc_form, #bank acc 
	current_cc_form, #credit card 
	current_contact_role_form, #contact role 
	current_contact_relation_form, #contact relations 
	current_contact_mailing_form, #contact mailings 
	comment_arr_full, #numer OF ROWS in comment ARRAY 
	comment_arr_max, #max tows in comment ARRAY 
	d4gl, 
	mswindows, 
	show_valid, 
	show_history, #inverted show_valid 
	age_cursor, 
	exist_age, 
	salutation_cursor, 
	exist_salutation, 
	bank_acc_role_cursor, 
	exist_bank_acc_role, 
	address_role_cursor, 
	exist_address_role, 
	cc_role_cursor, 
	exist_cc_role, 
	cc_type_cursor, 
	exist_cc_type, 
	mail_termination_cursor, 
	exist_mail_termination, 
	phone_role_code_cursor, 
	exist_phone_role_code, 
	relation_cursor, 
	exist_relation, 
	time_restrict_cursor, 
	exist_time_restrict, 
	mailing_role_cursor, 
	exist_mailing_role, 
	mailing_dates_cursor, 
	exist_mailing_dates, 
	comment_cursor, 
	role_cursor, 
	exist_role, 
	last_circle, 
	do_debug, 
	accept_enter 
	SMALLINT, 

	g_trap_status, 
	dummy, 
	INTEGER, 

	g_msg, 
	query_1, 
	last_where_part, #contact 
	last_addr_where_part #address 
	CHAR (800), 

	g_exec_string 
	CHAR(60), 

	#glob_rec_kandoouser.sign_on_code LIKE kandoouser.sign_on_code,

	ex_funcname3, 
	ex_funcname2, 
	ex_funcname1, 
	ex_funcname, 
	this_funcname, 
	g_scrsize 
	CHAR (20) 


END GLOBALS 
