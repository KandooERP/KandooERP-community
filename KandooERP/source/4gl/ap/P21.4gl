# Voucher Entry

# What IS the difference between an invoice AND a voucher?
# An invoice FROM a vendor IS the bill that IS received by the purchaser of goods OR services
# FROM an outside supplier. The vendor invoice lists the quantities of items, brief descriptions,
# prices, total amount due, credit terms, where TO remit payment, etc.
#
# A voucher IS an internal document used in a company's accounts payable department in ORDER TO
# collect AND organize the necessary documentation AND approvals before paying a vendor invoice.
# The voucher acts as a cover page TO which the following will be attached: vendor invoice,
# company's purchase ORDER, company's receiving REPORT, AND other information needed TO process
# the vendor invoice for payment.
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
	Source code beautified by beautify.pl on 2020-01-03 13:41:18	$Id: $
}

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_P2_GLOBALS.4gl" 
{
GLOBALS
#DEFINE pr_apparms RECORD LIKE apparms.*
	DEFINE pr_voucher RECORD LIKE voucher.*
	DEFINE glob_rec_vouchpayee RECORD LIKE vouchpayee.*
	DEFINE pa_voucher array[400] OF
		RECORD
			scroll_flag  CHAR(1),
			line_num     SMALLINT,
			vouch_code   LIKE voucher.vouch_code,
			vend_code    LIKE voucher.vend_code,
			inv_text     LIKE voucher.inv_text,
			dist_amt     LIKE voucher.dist_amt,
			total_amt    LIKE voucher.total_amt
		END RECORD
	DEFINE pa_default
		RECORD
			term_code  LIKE voucher.term_code,
			tax_code   LIKE voucher.tax_code,
			vouch_date LIKE voucher.vouch_date,
			year_num   LIKE voucher.year_num,
			period_num LIKE voucher.period_num
		END RECORD
	DEFINE glob_ctl_linetotal SMALLINT
	DEFINE pr_bat_linetotal SMALLINT
	DEFINE glob_ctl_amttotal LIKE voucher.total_amt
	DEFINE pr_bat_amttotal LIKE voucher.total_amt
	DEFINE ps_line_total LIKE voucher.total_amt
	DEFINE pr_temp_text CHAR(60)
	DEFINE cnt SMALLINT
END GLOBALS
}
GLOBALS 
	DEFINE glob_ctl_linetotal SMALLINT 
	DEFINE glob_ctl_amttotal LIKE voucher.total_amt 
	DEFINE glob_rec_voucher RECORD LIKE voucher.* 
	DEFINE glob_rec_vouchpayee RECORD LIKE vouchpayee.* 
	DEFINE glob_rec_pa_default 	RECORD 
		term_code LIKE voucher.term_code, 
		tax_code LIKE voucher.tax_code, 
		vouch_date LIKE voucher.vouch_date, 
		year_num LIKE voucher.year_num, 
		period_num LIKE voucher.period_num 
	END RECORD 

END GLOBALS 
############################################################
# Module Scope Variables
############################################################

############################################################
# MAIN
#
# \brief module P21 allows the user TO enter AND distribute Payables Voucher
############################################################
MAIN 

	#Initial UI Init
	CALL setModuleId("P21") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 
	#now done in CALL init_p_ap() #init P/AP module
	#SELECT * INTO pr_apparms.* FROM apparms
	# WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
	#IF STATUS = NOTFOUND THEN
	#   LET msgresp=kandoomsg("P",5016,"")
	#   EXIT PROGRAM
	#END IF
	CALL create_table("voucherdist","t_voucherdist","","Y") 
	CALL create_table("purchdetl","t_purchdetl","","Y") 
	CALL create_table("poaudit","t_poaudit","","Y") 

	LET glob_ctl_linetotal = NULL 
	LET glob_ctl_amttotal = NULL 

	OPEN WINDOW p125 with FORM "P125" 
	CALL windecoration_p("P125") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	WHILE TRUE 
		CLEAR FORM 
		INITIALIZE glob_rec_pa_default.* TO NULL 

		CALL input_voucher(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,"","","") 
		RETURNING glob_rec_voucher.*, glob_rec_vouchpayee.* 

		CALL voucher_distribution_menu(glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code, glob_rec_voucher.*, glob_rec_vouchpayee.*,'1') 
		RETURNING  glob_rec_voucher.vouch_code
		IF glob_rec_voucher.vouch_code <= 0 THEN 
			EXIT WHILE 
		END IF 
	END WHILE 
	CLOSE WINDOW p125 

END MAIN 



