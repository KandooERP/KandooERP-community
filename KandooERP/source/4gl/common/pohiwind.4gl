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

	Source code beautified by beautify.pl on 2020-01-02 10:35:27	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 


############################################################
# FUNCTION pohiwind(p_cmpy_code, p_vend, p_ponum, p_linenum)
#
#FUNCTION pohiwind allows the user TO view purchased ORDER line history
############################################################
FUNCTION pohiwind(p_cmpy_code,p_vend, p_ponum,p_linenum) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_vend LIKE poaudit.vend_code
	DEFINE p_ponum LIKE poaudit.po_num 
	DEFINE p_linenum LIKE poaudit.line_num 
	DEFINE l_rec_poaudit RECORD LIKE poaudit.* 
	DEFINE l_arr_rec_st_seq DYNAMIC ARRAY OF #array[100] OF 
	RECORD 
		seq_num LIKE poaudit.seq_num 
	END RECORD 
	DEFINE l_arr_rec_ledg DYNAMIC ARRAY OF #array[100] OF 
	RECORD 
		tran_code LIKE poaudit.tran_code, 
		entry_date LIKE poaudit.entry_date, 
		order_qty LIKE poaudit.order_qty, 
		received_qty LIKE poaudit.received_qty, 
		voucher_qty LIKE poaudit.voucher_qty, 
		unit_cost_amt LIKE poaudit.unit_cost_amt 
	END RECORD 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_idx SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPTIONS DELETE KEY f36, 
	INSERT KEY f36 

	OPEN WINDOW wr105 with FORM "R105" 
	CALL winDecoration_r("R105") 

	LET l_rec_poaudit.po_num = p_ponum 
	LET l_rec_poaudit.line_num = p_linenum 
	LET l_rec_poaudit.vend_code = p_vend 
	SELECT * INTO l_rec_vendor.* FROM vendor 
	WHERE cmpy_code = p_cmpy_code 
	AND vend_code = l_rec_poaudit.vend_code 
	IF status = notfound THEN 
		LET l_msgresp = kandoomsg("U",7001,"Vendor") 
		#7001 Logic Error: Vendor RECORD was NOT found
	END IF 

	DISPLAY BY NAME l_rec_poaudit.vend_code, 
	l_rec_vendor.name_text, 
	l_rec_poaudit.po_num, 
	l_rec_poaudit.line_num 

	DECLARE dledg CURSOR FOR 
	SELECT poaudit.* INTO l_rec_poaudit.* FROM poaudit 
	WHERE poaudit.cmpy_code = p_cmpy_code 
	AND poaudit.po_num = l_rec_poaudit.po_num 
	AND poaudit.line_num = l_rec_poaudit.line_num 
	ORDER BY poaudit.seq_num 
	LET l_idx = 0 

	FOREACH dledg 
		LET l_idx = l_idx + 1 
		#LET scrn = scr_line()
		LET l_arr_rec_st_seq[l_idx].seq_num = l_rec_poaudit.seq_num 
		LET l_arr_rec_ledg[l_idx].tran_code = l_rec_poaudit.tran_code 
		LET l_arr_rec_ledg[l_idx].entry_date = l_rec_poaudit.entry_date 
		LET l_arr_rec_ledg[l_idx].order_qty = l_rec_poaudit.order_qty 
		LET l_arr_rec_ledg[l_idx].received_qty = l_rec_poaudit.received_qty 
		LET l_arr_rec_ledg[l_idx].voucher_qty = l_rec_poaudit.voucher_qty 
		LET l_arr_rec_ledg[l_idx].unit_cost_amt = l_rec_poaudit.unit_cost_amt 
		IF l_idx > 98 THEN 
			LET l_msgresp = kandoomsg("U",6100,l_idx) 
			#6100 First l_idx records selected only
			EXIT FOREACH 
		END IF 
	END FOREACH 

	LET l_msgresp = kandoomsg("U",9113,l_idx) 
	#9113 l_idx records selected
	CALL set_count(l_idx) 
	LET l_msgresp = kandoomsg("U",1007,"") 
	#1007 F3/F4 TO page up/down; Enter on line TO view
	INPUT ARRAY l_arr_rec_ledg WITHOUT DEFAULTS FROM sr_poaudit.* ATTRIBUTE(UNBUFFERED) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","pohiwind","input-arr-ledg") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			#LET scrn = scr_line()
			LET l_rec_poaudit.tran_code = l_arr_rec_ledg[l_idx].tran_code 
			#DISPLAY l_arr_rec_ledg[l_idx].* TO sr_poaudit[scrn].*

		BEFORE FIELD entry_date 
			CALL po_line_detail( p_cmpy_code, p_ponum, p_linenum, l_arr_rec_st_seq[l_idx].seq_num) 
			NEXT FIELD tran_code 
		AFTER FIELD tran_code 
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF l_arr_rec_ledg[l_idx+1].tran_code IS NULL 
				OR arr_curr() >= arr_count() THEN 
					LET l_msgresp=kandoomsg("U",9001,"") 
					#9001 There no more rows...
					NEXT FIELD tran_code 
				END IF 
			END IF 
			# AFTER ROW
			#    DISPLAY l_arr_rec_ledg[l_idx].* TO sr_poaudit[scrn].*




	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
	END IF 

	CLOSE WINDOW wr105 

END FUNCTION 


