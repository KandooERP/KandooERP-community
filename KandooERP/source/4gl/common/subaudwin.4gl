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
# common/crhdwind.4gl
# common/inhdwind.4gl
###########################################################################


#   csaudwind.4gl - Provides an scan window of the audit
#      entries FOR a particular subscription.

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

############################################################
# FUNCTION show_subaudit(p_cmpy,p_cust_code,p_ship_code,p_part_code,p_sub_type,p_start_date,p_end_date)
#
#
############################################################
FUNCTION show_subaudit(p_cmpy,p_cust_code,p_ship_code,p_part_code,p_sub_type,p_start_date,p_end_date) 
	DEFINE p_cmpy LIKE company.cmpy_code
	DEFINE p_cust_code LIKE customer.cust_code
	DEFINE p_ship_code LIKE customership.ship_code
	DEFINE p_part_code LIKE product.part_code 
	DEFINE p_sub_type LIKE substype.type_code
	DEFINE p_start_date LIKE subaudit.start_date
	DEFINE p_end_date LIKE subaudit.end_date
	DEFINE l_msgresp LIKE language.yes_flag
	DEFINE l_rec_subhead RECORD LIKE subhead.* 
	DEFINE l_rec_subaudit RECORD LIKE subaudit.*
	DEFINE l_arr_subaudit ARRAY[100] OF RECORD 
		tran_date LIKE subaudit.tran_date, 
		tran_type_ind LIKE subaudit.tran_type_ind, 
		tran_qty LIKE subaudit.tran_qty, 
		unit_amt LIKE subaudit.unit_amt, 
		seq_num LIKE subaudit.seq_num, 
		source_num LIKE subaudit.source_num, 
		comm_text LIKE subaudit.comm_text 
	END RECORD
	DEFINE l_arr_rowid ARRAY[100] OF INTEGER
	DEFINE l_rowid INTEGER 
	DEFINE l_idx SMALLINT 
	DEFINE l_name_text LIKE customer.name_text 
	DEFINE l_sname_text LIKE customership.name_text 
	DEFINE l_desc_text LIKE product.desc_text 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	OPEN WINDOW K154 with FORM "K154" 
	CALL windecoration_k("K154") -- albo kd-767 

	SELECT name_text INTO l_name_text 
	FROM customer 
	WHERE cmpy_code = p_cmpy 
	AND cust_code = p_cust_code 

	SELECT desc_text INTO l_desc_text 
	FROM product 
	WHERE cmpy_code = p_cmpy 
	AND part_code = p_part_code 

	SELECT name_text INTO l_sname_text 
	FROM customership 
	WHERE cmpy_code = p_cmpy 
	AND cust_code = p_cust_code 
	AND ship_code = p_ship_code 

	DISPLAY 
		p_cust_code, 
		l_name_text, 
		p_ship_code, 
		l_sname_text, 
		p_part_code, 
		l_desc_text, 
		p_sub_type, 
		p_start_date, 
		p_end_date 
	TO 
		subcustomer.cust_code, 
		customer.name_text, 
		subcustomer.ship_code, 
		customership.name_text, 
		subcustomer.part_code, 
		product.desc_text, 
		subcustomer.sub_type_code, 
		subcustomer.comm_date, 
		subcustomer.end_date 

	LET l_msgresp = kandoomsg("U",1002,"") #1002 " Searching database - please wait"

	DECLARE c_subaudit CURSOR FOR 
	SELECT rowid,* FROM subaudit 
	WHERE cmpy_code = p_cmpy 
	AND cust_code = p_cust_code 
	AND ship_code = p_ship_code 
	AND part_code = p_part_code 
	AND sub_type_code = p_sub_type 
	AND start_date = p_start_date 
	AND end_date = p_end_date 
	ORDER BY seq_num 

	LET l_idx = 0 
	FOREACH c_subaudit INTO 
		l_rowid, 
		l_rec_subaudit.* 

		LET l_idx = l_idx + 1 
		LET l_arr_subaudit[l_idx].seq_num = l_rec_subaudit.seq_num 
		LET l_arr_subaudit[l_idx].tran_date = l_rec_subaudit.tran_date 
		LET l_arr_subaudit[l_idx].tran_type_ind = l_rec_subaudit.tran_type_ind 
		LET l_arr_subaudit[l_idx].tran_qty = l_rec_subaudit.tran_qty 
		LET l_arr_subaudit[l_idx].unit_amt = l_rec_subaudit.unit_amt 
		LET l_arr_subaudit[l_idx].source_num = l_rec_subaudit.source_num 
		LET l_arr_subaudit[l_idx].comm_text = l_rec_subaudit.comm_text 
		LET l_arr_rowid[l_idx] = l_rowid 

		IF l_idx = 100 THEN 
			LET l_msgresp = kandoomsg("U",6100,l_idx) 
			EXIT FOREACH 
		END IF 
	END FOREACH 

	LET l_msgresp = kandoomsg("U",9113,l_idx) #9113 "l_idx rows selected"
	IF l_idx = 0 THEN 
		LET l_idx = 1 
		INITIALIZE l_arr_subaudit[1].* TO NULL 
	END IF 

	LET l_msgresp = kandoomsg("U",1007,"")#1007 "RETURN TO View
	CALL set_count(l_idx) 

	DISPLAY ARRAY l_arr_subaudit TO sr_subaudit.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","subaudwin","display-arr-subaudit") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON KEY (RETURN) 
			LET l_idx = arr_curr() 
			SELECT * INTO l_rec_subaudit.* 
			FROM subaudit 
			WHERE cmpy_code = p_cmpy 
			AND cust_code = p_cust_code 
			AND ship_code = p_ship_code 
			AND part_code = p_part_code 
			AND sub_type_code = p_sub_type 
			AND start_date = p_start_date 
			AND end_date = p_end_date 
			AND rowid = l_arr_rowid[l_idx] 

			SELECT * INTO l_rec_subhead.* 
			FROM subhead 
			WHERE cmpy_code = p_cmpy 
			AND sub_num = l_rec_subaudit.sub_num 

			CASE 
				WHEN l_rec_subaudit.tran_type_ind = "INV" 
					IF l_rec_subhead.corp_flag = "Y" THEN 
						LET l_rec_subaudit.cust_code = l_rec_subhead.corp_cust_code 
					END IF 
					CALL disc_per_head(
						p_cmpy,l_rec_subaudit.cust_code, 
						l_rec_subaudit.source_num) 

				WHEN l_rec_subaudit.tran_type_ind = "SUB" 
					CALL sub_disp_head(p_cmpy,l_rec_subaudit.cust_code, 
					l_rec_subaudit.source_num) 

				WHEN l_rec_subaudit.tran_type_ind = "CRD"	OR l_rec_subaudit.tran_type_ind = "EDT" 
					IF l_rec_subhead.corp_flag = "Y" THEN 
						LET l_rec_subaudit.cust_code = l_rec_subhead.corp_cust_code 
					END IF 
					
					CALL cr_disp_head(
						p_cmpy,
						l_rec_subaudit.cust_code, 
						l_rec_subaudit.source_num)
						 
				WHEN l_rec_subaudit.tran_type_ind = "ISS" 
					CALL disc_per_head(
						p_cmpy,
						l_rec_subaudit.cust_code, 
						l_rec_subaudit.source_num) 
			END CASE
			 
		ON KEY (tab) 
			LET l_idx = arr_curr() 
			SELECT * INTO l_rec_subaudit.* 
			FROM subaudit 
			WHERE cmpy_code = p_cmpy 
			AND cust_code = p_cust_code 
			AND ship_code = p_ship_code 
			AND part_code = p_part_code 
			AND sub_type_code = p_sub_type 
			AND start_date = p_start_date 
			AND end_date = p_end_date 
			AND rowid = l_arr_rowid[l_idx] 
			
			SELECT * INTO l_rec_subhead.* 
			FROM subhead 
			WHERE cmpy_code = p_cmpy 
			AND sub_num = l_rec_subaudit.sub_num 
			
			CASE 
				WHEN l_rec_subaudit.tran_type_ind = "INV" 
					IF l_rec_subhead.corp_flag = "Y" THEN 
						LET l_rec_subaudit.cust_code = l_rec_subhead.corp_cust_code 
					END IF 
					CALL disc_per_head(
						p_cmpy,
						l_rec_subaudit.cust_code, 
						l_rec_subaudit.source_num) 

				WHEN l_rec_subaudit.tran_type_ind = "SUB" 
					CALL sub_disp_head(
						p_cmpy,
						l_rec_subaudit.cust_code, 
						l_rec_subaudit.source_num) 

				WHEN l_rec_subaudit.tran_type_ind = "CRD"	OR l_rec_subaudit.tran_type_ind = "EDT" 
					IF l_rec_subhead.corp_flag = "Y" THEN 
						LET l_rec_subaudit.cust_code = l_rec_subhead.corp_cust_code 
					END IF
					 
					CALL cr_disp_head(
						p_cmpy,
						l_rec_subaudit.cust_code, 
						l_rec_subaudit.source_num) 

				WHEN l_rec_subaudit.tran_type_ind = "ISS" 
					CALL disc_per_head(p_cmpy,l_rec_subaudit.cust_code, 
					l_rec_subaudit.source_num) 
			END CASE 

	END DISPLAY
	 
	LET int_flag = false 
	LET quit_flag = false 
	CLOSE WINDOW k154 
END FUNCTION 
############################################################
# FUNCTION show_subaudit(p_cmpy,p_cust_code,p_ship_code,p_part_code,p_sub_type,p_start_date,p_end_date)
############################################################