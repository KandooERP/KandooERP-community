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

	Source code beautified by beautify.pl on 2020-01-02 10:35:40	$Id: $
}



# FUNCTION disp_dist_jm displays job management distribution

GLOBALS "../common/glob_GLOBALS.4gl" 

DEFINE formname CHAR(15) 

FUNCTION disp_jm_dist(p_cmpy,p_vouch_num) 
	DEFINE p_cmpy LIKE company.cmpy_code
	DEFINE p_vouch_num LIKE voucher.vouch_code
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_pr_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_dist_amt LIKE voucherdist.dist_amt 
	DEFINE l_idx SMALLINT 
	DEFINE l_rec_jobledger RECORD LIKE jobledger.*
	DEFINE l_arr_jobledger array[300] OF RECORD 
		trans_source_text LIKE jobledger.trans_source_text, 
		job_code LIKE jobledger.job_code, 
		var_code LIKE jobledger.var_code, 
		activity_code LIKE jobledger.activity_code , 
		trans_amt LIKE jobledger.trans_amt , 
		trans_qty LIKE jobledger.trans_qty, 
		charge_amt LIKE jobledger.charge_amt, 
		desc_text LIKE jobledger.desc_text, 
		acct_code LIKE voucherdist.acct_code 
	END RECORD 
	DEFINE l_acct_code LIKE voucherdist.acct_code 
	DEFINE i SMALLINT 

	# read in matching jobledger rows AND DISPLAY the details

	# matches rows on voucherdist with matching rows on jobledger, joinin
	# joins voucherdist TO resource on expense account TO get a SET of resources
	# AND resource TO jobledger on resource code AND voucher number
	# (trans_cource_num). Will get multiple rows IF mult dists with same resource
	# so join on amount as well. This will produce mult rows IF mult dists of
	# same resource FOR same amount so
	# SELECT unique activity, var, job, resource amount.
	## On data entry AND edit, check FOR duplicate activity, var, job AND resource.
	# before exiting INPUT ARRAY WHILE.
	# This allows multiple resources with the same expense code.

	DECLARE c0 CURSOR FOR 
	SELECT * 
	FROM voucher, vendor 
	WHERE voucher.cmpy_code = p_cmpy AND 
	voucher.vouch_code = p_vouch_num AND 
	vendor.cmpy_code = p_cmpy AND 
	vendor.vend_code = voucher.vend_code 
	OPEN c0 
	FETCH c0 INTO l_rec_voucher.*, l_rec_pr_vendor.* 
	IF status = notfound THEN 
		#ERROR "Vendor NOT found"
		LET l_msgresp = kandoomsg("P",9501," ") 
		SLEEP 3 
		CLOSE c0 
		RETURN 
	END IF 
	CLOSE c0 
	DECLARE c1 CURSOR FOR 
	SELECT unique jobledger.*, voucherdist.acct_code 
	FROM jobledger, voucherdist 
	WHERE voucherdist.cmpy_code = p_cmpy AND 
	voucherdist.vouch_code = l_rec_voucher.vouch_code AND 
	jobledger.cmpy_code = p_cmpy AND 
	jobledger.trans_source_num = voucherdist.vouch_code AND 
	jobledger.trans_amt = voucherdist.dist_amt 
	LET l_idx = 0 
	LET l_dist_amt = 0 

	FOREACH c1 INTO l_rec_jobledger.*, l_acct_code 
		LET l_idx = l_idx + 1 
		LET l_dist_amt = l_dist_amt + l_rec_jobledger.trans_amt 
		LET l_arr_jobledger[l_idx].trans_source_text = l_rec_jobledger.trans_source_text 
		LET l_arr_jobledger[l_idx].desc_text = l_rec_jobledger.desc_text 
		LET l_arr_jobledger[l_idx].charge_amt = l_rec_jobledger.charge_amt 
		LET l_arr_jobledger[l_idx].job_code = l_rec_jobledger.job_code 
		LET l_arr_jobledger[l_idx].var_code = l_rec_jobledger.var_code 
		LET l_arr_jobledger[l_idx].activity_code = l_rec_jobledger.activity_code 
		LET l_arr_jobledger[l_idx].trans_amt = l_rec_jobledger.trans_amt 
		LET l_arr_jobledger[l_idx].trans_qty = l_rec_jobledger.trans_qty 
		LET l_arr_jobledger[l_idx].acct_code = l_acct_code 
	END FOREACH 
	CALL set_count(l_idx) 


	OPEN WINDOW j147 with FORM "J147a" 
	CALL windecoration_j("J147a") -- albo kd-767 
	DISPLAY BY NAME l_rec_voucher.vend_code, l_rec_pr_vendor.name_text, 
	l_rec_voucher.vouch_code, l_rec_voucher.goods_amt, l_rec_voucher.dist_amt 
	
	LET l_msgresp = kandoomsg("P",1008," ") # MESSAGE "This IS FOR DISPLAY only, F3/F4 FOR Fwd/Back" ATTRIBUTE(yellow)

	DISPLAY ARRAY l_arr_jobledger TO sr_jobledger.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","vojmwind","display-arr-jobledger") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END DISPLAY 

	CLOSE WINDOW j147 
END FUNCTION 




