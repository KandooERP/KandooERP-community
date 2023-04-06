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

###########################################################################
# Requires
# common/invqwind.4gl
###########################################################################

###########################################################################
# FUNCTION disc_per_head displays invoice header details with the option
# of carrying on AND looking AT line details
###########################################################################

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

###################################################################
# FUNCTION disc_per_head(p_cmpy, p_cust, p_invnum)
#
#
###################################################################
FUNCTION disc_per_head(p_cmpy,p_cust,p_invnum) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_cust LIKE customer.cust_code 
	DEFINE p_invnum LIKE invoicehead.inv_num 
	--DEFINE l_A134 SMALLINT
	DEFINE l_pv_name_text LIKE customer.name_text 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_ref_text CHAR(32) 
	DEFINE l_doc_ind_text CHAR(3) 
	DEFINE l_pr_inv_ref1_text LIKE arparms.inv_ref1_text 
	DEFINE l_name_text LIKE salesperson.name_text 
	DEFINE l_desc_text LIKE territory.desc_text 

	SELECT inv_ref1_text INTO l_pr_inv_ref1_text 
	FROM arparms 
	WHERE cmpy_code = p_cmpy 
	AND parm_code = "1" 

	IF status = notfound THEN 
		CALL fgl_winmessage("#A9107 AP Parameters NOT SET up" , kandoomsg2("A",9107,""),"ERROR") 	#A9107 AP Parameters NOT SET up - Refer menu AZP
		RETURN 
	END IF 

	LET l_ref_text = l_pr_inv_ref1_text clipped, "................" 

	SELECT * INTO l_rec_invoicehead.* 
	FROM invoicehead 
	WHERE cmpy_code = p_cmpy 
	AND inv_num = p_invnum 
	AND cust_code = p_cust 

	IF status = notfound THEN 
		CALL fgl_winmessage("ERROR - Invoice",kandoomsg2("A",7048,p_invnum),"ERFROR") 	#7048 Logic Error: Invoice does NOT exist
		RETURN 
	END IF 

	SELECT * INTO l_rec_customer.* 
	FROM customer 
	WHERE customer.cmpy_code = p_cmpy 
	AND customer.cust_code = p_cust 

	IF status = notfound THEN 
		CALL fgl_winmessage("ERROR - Customer",kandoomsg2("A",9067,""),"ERFROR")  	#A9067 Logic Error: Customer does NOT exist
		RETURN 
	END IF 

	SELECT name_text INTO l_name_text 
	FROM salesperson 
	WHERE cmpy_code = p_cmpy 
	AND sale_code = l_rec_invoicehead.sale_code 

	IF sqlca.sqlcode = 0 THEN 
		LET l_name_text = l_name_text[1,25] 
	END IF 

	SELECT desc_text INTO l_desc_text 
	FROM territory 
	WHERE cmpy_code = p_cmpy 
	AND terr_code = l_rec_invoicehead.territory_code 

	IF sqlca.sqlcode = 0 THEN 
		LET l_desc_text = l_desc_text[1,25] 
	END IF 

	CASE l_rec_invoicehead.inv_ind 
		WHEN "1" 
			LET l_doc_ind_text = "A-R" 
		WHEN "2" 
			LET l_doc_ind_text = "NOR" 
		WHEN "3" 
			LET l_doc_ind_text = TRAN_TYPE_JOB_JOB 
		WHEN "4" 
			LET l_doc_ind_text = "ADJ" 
		WHEN "5" 
			LET l_doc_ind_text = "PRE" 
		OTHERWISE 
			LET l_doc_ind_text = "NOR" 
	END CASE 

	WHENEVER ERROR CONTINUE
	OPEN WINDOW A134 WITH FORM "A134"
	IF status < 0 THEN
		CURRENT WINDOW IS A134
	ELSE
		CALL windecoration_a("A134")
	END IF
	WHENEVER ERROR STOP
#HuHo do not delete this.. original window manager is xxxx we need to sort this out	
--	IF l_A134 < 1 THEN 
--		LET l_A134 = l_A134 + 1 
--		CALL open_window( 'A134', l_A134 ) 
--	ELSE 
--		ERROR kandoomsg2("U",9917,"") 	#9917 Window IS already OPEN
--		RETURN 
--	END IF 

	DISPLAY l_ref_text TO formonly.inv_ref1_text -- attribute(white) 

	IF l_rec_invoicehead.org_cust_code IS NOT NULL THEN 
		SELECT name_text INTO l_pv_name_text 
		FROM customer 
		WHERE cmpy_code = p_cmpy 
		AND cust_code = l_rec_invoicehead.org_cust_code 
		DISPLAY l_pv_name_text 
		TO formonly.org_name_text 

	END IF 

	IF l_rec_invoicehead.rev_date = '31/12/1899' THEN 
		LET l_rec_invoicehead.rev_date = NULL 
	END IF 

	IF l_rec_invoicehead.ship_date = '31/12/1899' THEN 
		LET l_rec_invoicehead.ship_date = NULL 
	END IF 

	IF l_rec_invoicehead.due_date = '31/12/1899' THEN 
		LET l_rec_invoicehead.due_date = NULL 
	END IF 

	IF l_rec_invoicehead.stat_date = '31/12/1899' THEN 
		LET l_rec_invoicehead.stat_date = NULL 
	END IF 

	IF l_rec_invoicehead.paid_date = '31/12/1899' THEN 
		LET l_rec_invoicehead.paid_date = NULL 
	END IF 

	IF l_rec_invoicehead.posted_flag = 'N' THEN 
		LET l_rec_invoicehead.post_date = NULL 
		LET l_rec_invoicehead.jour_num = NULL 
	END IF 

	DISPLAY 
		l_rec_customer.cust_code, 
		l_rec_customer.name_text, 
		l_rec_customer.addr1_text, 
		l_rec_customer.addr2_text, 
		l_rec_customer.city_text, 
		l_rec_customer.state_code, 
		l_rec_customer.post_code, 
		l_rec_invoicehead.name_text, 
		l_rec_invoicehead.addr1_text, 
		l_rec_invoicehead.addr2_text, 
		l_rec_invoicehead.city_text, 
		l_rec_invoicehead.state_code, 
		l_rec_invoicehead.post_code, 
		l_name_text, 
		l_desc_text, 
		l_doc_ind_text 
	TO 
		invoicehead.cust_code, 
		customer.name_text, 
		customer.addr1_text, 
		customer.addr2_text, 
		customer.city_text, 
		customer.state_code, 
		customer.post_code, 
		invoicehead.name_text, 
		invoicehead.addr1_text, 
		invoicehead.addr2_text, 
		invoicehead.city_text, 
		invoicehead.state_code, 
		invoicehead.post_code, 
		salesperson.name_text, 
		territory.desc_text, 
		formonly.doc_ind_text 

	DISPLAY BY NAME 
		l_rec_invoicehead.cust_code, 
		l_rec_invoicehead.org_cust_code, 
		l_rec_invoicehead.purchase_code, 
		l_rec_invoicehead.inv_num, 
		l_rec_invoicehead.inv_date, 
		l_rec_invoicehead.ord_num, 
		l_rec_invoicehead.sale_code, 
		l_rec_invoicehead.territory_code, 
		l_rec_invoicehead.com1_text, 
		l_rec_invoicehead.com2_text, 
		l_rec_invoicehead.goods_amt, 
		l_rec_invoicehead.freight_amt, 
		l_rec_invoicehead.hand_amt, 
		l_rec_invoicehead.tax_amt, 
		l_rec_invoicehead.total_amt, 
		l_rec_invoicehead.paid_amt, 
		l_rec_invoicehead.year_num, 
		l_rec_invoicehead.period_num, 
		l_rec_invoicehead.posted_flag, 
		l_rec_invoicehead.post_date, 
		l_rec_invoicehead.jour_num, 
		l_rec_invoicehead.entry_date, 
		l_rec_invoicehead.rev_date, 
		l_rec_invoicehead.ship_date, 
		l_rec_invoicehead.due_date, 
		l_rec_invoicehead.stat_date, 
		l_rec_invoicehead.paid_date 

	DISPLAY BY NAME l_rec_customer.currency_code attribute(green) 

	#IF promptTF("",kandoomsg2("A",8016,""),1) THEN
	IF eventOptions("DoneDetails","CD") = "D" THEN 	#huho 15.09.2018 - changed TO toolbar events TO make it look better 
		CALL lineshow( p_cmpy, l_rec_invoicehead.cust_code, p_invnum, "" ) 
	END IF 

	# MESSAGE kandoomsg2("U",1,"")
	CALL eventSuspend()

	--CALL close_win( 'A134', l_A134 ) 
	WHENEVER ERROR CONTINUE
	CLOSE WINDOW A134
	WHENEVER ERROR STOP
	
	--LET l_A134 = l_A134 - 1 
	LET int_flag = 0 
	LET quit_flag = 0 

END FUNCTION 
###################################################################
# END FUNCTION disc_per_head(p_cmpy, p_cust, p_invnum)
###################################################################