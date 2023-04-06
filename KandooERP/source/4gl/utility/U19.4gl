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

	Source code beautified by beautify.pl on 2020-01-03 18:54:41	$Id: $
}



# Obtained FROM Informix Inter-national Users Group (www.iuug.org).

#
# Original IUUG command line arguments AND modification history:
#
# dbdiff2.4gl:  A shortened version of dbutil - a utility TO generate SQL
#        TO make one version of a database match another.
#
#  Placed in the public domain - with no guarantees whatsoever that it
#  will work.  IF it breaks something of yours THEN you should be more
#  careful but it's NMFP.
#
#  This program was written in stolen hours by me AND THEN added
#  TO by the denizens of comp.databases.informix.  It has been tested
#  AND generally accepted as a great utility by that newsgroup, but
#  all of them religiously check the SQL it generates before running it.
#
#  I highly recommend that you perform these same checks.
#
#  Originally written by Jack Parker March, 1994
#  AND Kerry Sainsbury November, 1994 (procedures, triggers)
#  Inspired by Dave Snyder.
#
#
#  Revision 1.2  94/05/30  16:05:31  16:05:31  jparker (Jack Parker)
#    now supports systabauth (-a) AND sysusers (-u)
#    now supports individual OR groups of tables (-t table_spec)
#    now supports on the fly changing of server names
#    Parens added TO ALTER statement TO support other versions of ISQL
#    Added STATUS TO db_check routine
#
#  Revision 1.3  94/09/01  13:39:25  13:39:25  jparker (Jack Parker)
#    Corrected DATETIME/INTERVAL TO PRINT proper END points
#    Corrected DATETIME/INTERVAL TO NOT include parens
#    Now handles DECIMAL(n) AND DECIMAL(n,0)
#    Now handles DESCending indices.
#    Corrected syntax FOR BEFORE in the ALTER TABLE clause
#
#  Revision 1.4  95/06/14  12:49:50  12:49:50  jparker (Jack Parker)
#    s1/s2 switches made TO work again (Cathy Kipp)
#    Typo in incorporating triggers/procedures o_systabs should be o_systables
#    Triggers AND Procedures changed TO use fold_and_push()
#    COLUMN can now be added BEFORE the first existing COLUMN  (Kerry)
#    Typo line 1033 (John Fowler)
#    log() changed TO logg() (J Fowler)
#    Intervals with a precision (e.g. DAY(3) TO DAY) are now handled (jp)
#    Defaulted Constraints, User permissions AND SPLs TO ON.
#    Bug fix - WHEN doing USER AND NOT AUTH would crash - corrected.
#    SPL FUNCTION no longer drops core.
#    General - added support FOR SPL, triggers AND constraints. Some bug fixes.
#
##############################################################################
#

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../utility/U_UT_GLOBALS.4gl" 

#Module Scope Variables
DEFINE gr_params RECORD 
	site_name CHAR(18),# dbserver instance 
	user_name CHAR(18),# user login 
	db_name CHAR(32),# new AND old DATABASE NAME 
	tb_name CHAR(32),# TABLE NAME matches pattern 
	online_sw CHAR(1), # what type OF db engine 
	auth_sw CHAR(1), # authority 
	user_sw CHAR(1), # users 
	const_sw CHAR(1), # CONSTRAINTS 
	trig_sw CHAR(1), # triggers 
	spl_sw CHAR(1), # triggers 
	snapshot_dir CHAR(64),# UNLOAD directory NAME 
	sql_filename CHAR(64) # OUTPUT file NAME 
END RECORD 

DEFINE log_sql_sw SMALLINT # add LOG msgs TO SQL script as comments 
DEFINE quiet_sw SMALLINT # no interaction w/ user. 
DEFINE write_srv SMALLINT # server data needs writing switch 
DEFINE errusage SMALLINT 
DEFINE msg CHAR(80) # communicate w/ user 
DEFINE datatype ARRAY [40] OF CHAR(20) # FOR coltype conversions 
DEFINE datetype ARRAY [16] OF CHAR(11) 
DEFINE intvray ARRAY [16] OF RECORD 
	start_point SMALLINT, 
	end_point SMALLINT 
END RECORD 

DEFINE sql_saved_line CHAR(80)# temp space FOR formatting SQL 
DEFINE sql_idx smallint# INDEX TO same 
DEFINE max_parts smallint# how many COLUMNS TO an INDEX 
DEFINE servers ARRAY [20] OF # alternate servers 
RECORD 
	old_server CHAR(20), 
	new_server CHAR(20) 
END RECORD 

DEFINE gv_systable_unl CHAR(32) 
DEFINE gv_syssyntab_unl CHAR(32) 
DEFINE gv_syscol_unl CHAR(32) 
DEFINE gv_sysview_unl CHAR(32) 
DEFINE gv_sysind_unl CHAR(32) 
DEFINE gv_systabauth_unl CHAR(32) 
DEFINE gv_syscolauth_unl CHAR(32) 
DEFINE gv_sysusers_unl CHAR(32) 
DEFINE gv_sysconstr_unl CHAR(32) 
DEFINE gv_syscoldep_unl CHAR(32) 
DEFINE gv_syschecks_unl CHAR(32) 
DEFINE gv_sysrefs_unl CHAR(32) 
DEFINE gv_systrigg_unl CHAR(32) 
DEFINE gv_systrigb_unl CHAR(32) 
DEFINE gv_sysprocb_unl CHAR(32) 
DEFINE gv_sysproc_unl CHAR(32) # snapshot UNLOAD pathnames 
DEFINE max_servers SMALLINT 
DEFINE logfile CHAR(80)# NAME OF logfile 
DEFINE serverfle CHAR(80) # flat file OF server names "server1|server2" 


###################################################################
# MAIN
#
#
###################################################################
MAIN 
	DEFINE lv_exit_on_start SMALLINT 

	#NB Don't CALL security since its tables may be AT different versions
	#   OR even the ones that need fixing!
	#
	#   Also don't use kandoomsg, kandooword, run_prog etc calls FOR same reason.
	#   ie.  Keep this program self-contained AND version independant.
	#



	CALL setModuleId("U19") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_u_ut() #init utility module 

	INITIALIZE lv_exit_on_start TO NULL 
	LET lv_exit_on_start = fgl_getenv("EXIT_ON_START") 
	IF lv_exit_on_start IS NOT NULL THEN 
		#Used FOR testing, TO check that program can start
		#(duplicate/miising functions, library paths, etc)
		EXIT program (lv_exit_on_start) 
	END IF 


	DEFER interrupt # don't DEFER quit - original program had some poor 
	# subscripting code that could loop forever AND
	# its handy TO be able TO kill it IF it occurs.


	OPEN WINDOW w_u190 with FORM "U190" 
	CALL windecoration_u("U190") 

	CALL init_params() # program init 
	DISPLAY BY NAME gr_params.site_name, 
	gr_params.user_name, 
	gr_params.db_name, 
	gr_params.tb_name, 
	gr_params.online_sw, 
	gr_params.auth_sw, 
	gr_params.user_sw, 
	gr_params.const_sw, 
	gr_params.trig_sw, 
	gr_params.spl_sw, 
	gr_params.snapshot_dir, 
	gr_params.sql_filename 

	MENU "Schema" 
		BEFORE MENU 
			IF NOT super_user(gr_params.user_name) THEN 
				ERROR " You must log on as a Super User TO run this program!" 
				HIDE option "Compare" 
				HIDE option "Snapshot" 
			END IF 

			CALL publish_toolbar("kandoo","U19","menu-schema") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		COMMAND "Compare" "Compare current DB TO previously saved Schema Snapshot" 
			IF input_params() THEN 
				CALL open_log("Begin Compare...") 
				IF load_schema() THEN 
					CALL compare_schema() 
					CALL close_log("Finished Compare.") 
					NEXT option "Exit" 
				ELSE 
					CALL close_log("Error in loading Snapshot files!") 
				END IF 
			END IF 
		COMMAND "Snapshot" "Unload current DB Schema as basis FOR future Compare" 
			IF input_params() THEN 
				CALL open_log("Begin Snapshot...") 
				IF unload_schema() THEN 
					CALL close_log("Finished Snapshot.") 
					NEXT option "Exit" 
				ELSE 
					CALL close_log("Error in unloading Snapshot files!") 
				END IF 
			END IF 
		COMMAND KEY(interrupt, "E") "Exit" "RETURN TO main menu" 
			EXIT MENU 
	END MENU 
	CLOSE WINDOW w_u190 
END MAIN 

###################################################################
# FUNCTION super_user(fv_user_name)
#
# WHILE running this program IS NOT in itself dangerous
# we will none the less restrict access TO users who
# should know what they are doing.
###################################################################
FUNCTION super_user(fv_user_name) 
	DEFINE fv_user_name CHAR(18) 

	LET fv_user_name = upshift(fv_user_name) 
	IF fv_user_name = "ROOT" 
	OR fv_user_name = "INFORMIX" 
	OR fv_user_name = "SYSADMIN" 
	OR fv_user_name = "HUHO" #huho this IS special FOR me FOR testing 
	THEN 
		RETURN true 
	ELSE 
		RETURN false 
	END IF 
END FUNCTION 


###################################################################
# FUNCTION super_user(fv_user_name)
#
# Determine what AND WHERE IS TO be unloaded OR compared.
###################################################################
FUNCTION input_params() 

	MESSAGE " Enter parameters. OK TO continue; CANCEL TO EXIT." 

	OPTIONS 
	INPUT wrap # only proceed IF user explicity presses ok 
	INPUT BY NAME gr_params.online_sw, 
	gr_params.auth_sw, 
	gr_params.user_sw, 
	gr_params.const_sw, 
	gr_params.trig_sw, 
	gr_params.spl_sw, 
	gr_params.snapshot_dir, 
	gr_params.sql_filename 
	WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","U19","input-params") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


	END INPUT 
	OPTIONS 
	INPUT no wrap 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 


###################################################################
# FUNCTION compare_schema()
#
#
###################################################################
FUNCTION compare_schema() 
	DEFINE i SMALLINT 

	CALL db_check(gr_params.db_name) 
	RETURNING errusage 
	START REPORT sql_script TO gr_params.sql_filename 
	LET log_sql_sw = true 
	LET msg = "DB Schema Comparison of '", 
	gr_params.db_name clipped, 
	"' of '", 
	gr_params.site_name clipped, 
	"' as AT ", 
	CURRENT year TO minute 
	CALL put_log(msg) 
	CALL check_tabs() # TABLE changes 
	CALL check_idx() # INDEX changes 
	IF gr_params.auth_sw = "Y" THEN 
		CALL check_auth_general() # permissions 
	END IF 
	IF gr_params.user_sw = "Y" THEN # user privs. 
		CALL check_user() 
	END IF 
	IF gr_params.const_sw = "Y" THEN # CONSTRAINTS 
		CALL check_constr() 
	END IF 
	IF gr_params.trig_sw = "Y" THEN # triggers 
		CALL check_trigs() 
	END IF 
	IF gr_params.spl_sw = "Y" THEN # stored procedures 
		CALL check_spl() 
	END IF 
	LET msg = "END DB Schema Comparison" 
	CALL put_log(msg) 
	FINISH REPORT sql_script 
	LET log_sql_sw = false 
END FUNCTION 


###################################################################
# FUNCTION unload_schema()
#
#
###################################################################
FUNCTION unload_schema() 
	DEFINE os_cmd CHAR(220) 
	DEFINE unl_stmt CHAR(500) 

	WHENEVER any ERROR GOTO exiterr 
	CALL set_filenames() 
	CALL db_check(gr_params.db_name) 
	RETURNING errusage 
	LET msg = " Unloading current DB schema TO ", 
	gr_params.snapshot_dir clipped, 
	"/*.U19" 
	CALL put_log(msg) 
	#database gr_params.db_name
	LET unl_stmt = "SELECT tabname, tabid, tabtype ", 
	"FROM 'informix'.systables WHERE tabid > 99 ", 
	"AND tabname matches '", 
	gr_params.tb_name clipped, 
	"'" 
	DISPLAY "EXIT: disabled code because of <Anton Dickinson> ecp issue with DELIMITER" 
	DISPLAY "see uttility/U19.4gl" 
	EXIT program (1) 
	{
	   unload TO gv_systable_unl unl_stmt
	   LET unl_stmt = "SELECT a.tabid, a.servername, a.dbname, a.owner,  ",
	                  "a.tabname, a.btabid FROM 'informix'.syssyntable a, ",
	                  "'informix'.systables WHERE a.tabid > 99 ",
	                  "AND systables.tabid=a.tabid ",
	                  "AND systables.tabname matches '",
	                  gr_params.tb_name clipped,
	                  "'"
	   unload TO gv_syssyntab_unl unl_stmt
	   LET unl_stmt =
	                 "SELECT a.colname, a.tabid, a.colno, a.coltype, a.collength ",
	                  "FROM 'informix'.syscolumns a, ",
	                  "'informix'.systables WHERE a.tabid > 99 ",
	                  "AND systables.tabid=a.tabid ",
	                  "AND tabname matches '",
	                  gr_params.tb_name clipped,
	                  "'"
	   unload TO gv_syscol_unl unl_stmt
	   LET unl_stmt = "SELECT a.tabid, a.seqno, a.viewtext ",
	                  "FROM 'informix'.sysviews a, 'informix'.systables ",
	                  "WHERE a.tabid > 99 AND systables.tabid=a.tabid ",
	                  "AND tabname matches '",
	                  gr_params.tb_name clipped,
	                  "'"
	   unload TO gv_sysview_unl unl_stmt
	   IF gr_params.online_sw = "Y" THEN
	      LET unl_stmt = "SELECT a.idxname, a.tabid, a.idxtype, a.clustered, ",
	                     "a.part1, a.part2, a.part3, a.part4, a.part5, a.part6, ",
	                     "a.part7, a.part8, a.part9, a.part10, a.part11, ",
	                     "a.part12, a.part13, a.part14, a.part15, a.part16 ",
	                     "FROM 'informix'.sysindexes a, ",
	                     "'informix'.systables WHERE a.tabid > 99 ",
	                     "AND systables.tabid=a.tabid ",
	                     "AND tabname matches '",
	                     gr_params.tb_name clipped,
	                     "'"
	      unload TO gv_sysind_unl unl_stmt
	   ELSE
	      LET unl_stmt = "SELECT a.idxname, a.tabid, a.idxtype, a.clustered, ",
	                     "a.part1, a.part2, a.part3, a.part4, a.part5, a.part6, ",
	                     "a.part7, a.part8 ",
	                     "FROM 'informix'.sysindexes a, ",
	                     "'informix'.systables WHERE a.tabid > 99 ",
	                     "AND systables.tabid=a.tabid ",
	                     "AND tabname matches '",
	                     gr_params.tb_name clipped,
	                     "'"
	      unload TO gv_sysind_unl unl_stmt
	   END IF
	   IF gr_params.auth_sw = "Y" THEN
	      LET unl_stmt = "SELECT a.grantor, a.grantee, a.tabid, a.tabauth ",
	                     "FROM 'informix'.systabauth a, ",
	                     "'informix'.systables WHERE a.tabid > 99 ",
	                     "AND systables.tabid=a.tabid ",
	                     "AND tabname matches '",
	                     gr_params.tb_name clipped,
	                     "'"
	      unload TO gv_systabauth_unl unl_stmt
	      LET unl_stmt =
	                    "SELECT a.grantor, a.grantee, a.tabid, a.colno, a.colauth ",
	                     "FROM 'informix'.syscolauth a, ",
	                     "'informix'.systables WHERE a.tabid > 99 ",
	                     "AND systables.tabid=a.tabid ",
	                     "AND tabname matches '",
	                     gr_params.tb_name clipped,
	                     "'"
	      unload TO gv_syscolauth_unl unl_stmt
	   END IF
	   IF gr_params.user_sw = "Y" THEN
	      unload TO gv_sysusers_unl
	         SELECT username,
	                usertype
	         FROM "informix".sysusers
	   END IF
	   IF gr_params.const_sw = "Y" THEN
	      unload TO gv_sysconstr_unl
	         SELECT constrid,
	                constrname,
	                owner,
	                tabid,
	                constrtype,
	                idxname
	         FROM "informix".sysconstraints
	      unload TO gv_syscoldep_unl
	         SELECT constrid,
	                tabid,
	                colno
	         FROM "informix".syscoldepend
	      unload TO gv_syschecks_unl
	         SELECT constrid,
	                type,
	                seqno,
	                checktext
	         FROM "informix".syschecks
	# Note: updrule, delrule, matchtype, AND pendant are reserved FOR future use
	      unload TO gv_sysrefs_unl
	         SELECT constrid,
	                primary,
	                ptabid,
	                updrule,
	                delrule,
	                matchtype,
	                pendant
	         FROM "informix".sysreferences
	   END IF
	   IF gr_params.trig_sw = "Y" THEN
	      LET unl_stmt = "SELECT a.trigid, a.trigname, a.owner, ",
	                     "a.tabid, a.event, a.old, a.new",
	                     " FROM 'informix'.systriggers a, 'informix'.systables  ",
	                     "WHERE systables.tabid > 99 AND systables.tabid=a.tabid ",
	                     "AND tabname matches '",
	                     gr_params.tb_name clipped,
	                     "'"
	      unload TO gv_systrigg_unl unl_stmt
	      LET unl_stmt = 'SELECT a.trigid, a.datakey, a.seqno, a.data ',
	                     'FROM "informix".systrigbody a, "informix".systriggers, ',
	                     '"informix".systables  ',
	                     'WHERE systables.tabid > 99 ',
	                     'AND systables.tabid=systriggers.tabid ',
	                     'AND systriggers.trigid = a.trigid ',
	                     'AND tabname matches "',
	                     gr_params.tb_name clipped,
	                     '" ',
	                     'AND datakey IN ("D", "A")'
	      unload TO gv_systrigb_unl unl_stmt
	   END IF
	   IF gr_params.spl_sw = "Y" THEN
	      LET unl_stmt = 'SELECT b.procid, b.seqno, b.data ',
	                     'FROM "informix".sysprocbody b ',
	                     'WHERE datakey = "T"'
	      unload TO gv_sysprocb_unl unl_stmt
	      LET unl_stmt = 'SELECT a.procname, a.owner, a.procid ',
	                     'FROM "informix".sysprocedures a '
	      unload TO gv_sysproc_unl unl_stmt
	   END IF
	#close database
	   GOTO exitok
	}
	LABEL exiterr: 
	CALL err_print(status) 
	RETURN false 

	LABEL exitok: 
	RETURN true 

	WHENEVER any ERROR stop 

END FUNCTION 



###################################################################
# FUNCTION load_schema()
#
#
###################################################################
FUNCTION load_schema() 
	DEFINE os_cmd CHAR(220) 
	DEFINE unl_stmt CHAR(500) 

	WHENEVER any ERROR GOTO exiterr 
	LET msg = "Loading Schema Snapshot files..." 
	CALL put_log(msg) 
	CALL set_filenames() 
	#database gr_params.db_name
	# systables
	CREATE temp TABLE o_systables(tabname CHAR(18), 
	tabid INTEGER, 
	tabtype CHAR(1)) 
	with no LOG 
	LOAD FROM gv_systable_unl 
	INSERT INTO o_systables 
	# syssyntable
	CREATE temp TABLE o_syssyntab(tabid INTEGER, servername CHAR(18), dbname 
	CHAR (18), owner CHAR(8), ntabname CHAR(18), btabid 
	INTEGER ) 
	with no LOG 
	LOAD FROM gv_syssyntab_unl 
	INSERT INTO o_syssyntab 
	# syscolumns
	CREATE temp TABLE o_syscols(colname CHAR(18), tabid INTEGER, colno SMALLINT, 
	coltype SMALLINT, collength smallint) 
	with no LOG 
	LOAD FROM gv_syscol_unl 
	INSERT INTO o_syscols 
	CREATE unique INDEX cl1 ON o_syscols(tabid, colname) 
	# sysviews
	CREATE temp TABLE o_sysviews(tabid INTEGER, seqno SMALLINT, viewtext CHAR( 
	64 )) 
	with no LOG 
	LOAD FROM gv_sysview_unl 
	INSERT INTO o_sysviews 
	# sysindexes
	IF gr_params.online_sw = "Y" THEN 
		CREATE temp TABLE o_sysindexes(idxname CHAR(18), tabid INTEGER, idxtype 
		CHAR (1), clustered CHAR(1), part1 SMALLINT, part2 
		SMALLINT, part3 SMALLINT, part4 SMALLINT, part5 
		SMALLINT, part6 SMALLINT, part7 SMALLINT, part8 
		SMALLINT, part9 SMALLINT, part10 SMALLINT, part11 
		SMALLINT, part12 SMALLINT, part13 SMALLINT, part14 
		SMALLINT, part15 SMALLINT, part16 smallint) 
		with no LOG 
	ELSE 
		CREATE temp TABLE o_sysindexes(idxname CHAR(18), tabid INTEGER, idxtype 
		CHAR (1), clustered CHAR(1), part1 SMALLINT, part2 
		SMALLINT, part3 SMALLINT, part4 SMALLINT, part5 
		SMALLINT, part6 SMALLINT, part7 SMALLINT, part8 
		SMALLINT ) 
		with no LOG 
	END IF 
	LOAD FROM gv_sysind_unl 
	INSERT INTO o_sysindexes 
	# systabauth, syscolauth
	IF gr_params.auth_sw = "Y" THEN 
		CREATE temp TABLE o_systabauth(grantor CHAR(8), 
		grantee CHAR(8), 
		tabid INTEGER, 
		tabauth CHAR(8)) 
		with no LOG 
		LOAD FROM gv_systabauth_unl 
		INSERT INTO o_systabauth 
		CREATE temp TABLE o_syscolauth(grantor CHAR(8), 
		grantee CHAR(8), 
		tabid INTEGER, 
		colno SMALLINT, 
		colauth CHAR(3)) 
		with no LOG 
		LOAD FROM gv_syscolauth_unl 
		INSERT INTO o_syscolauth 
	END IF 
	IF gr_params.user_sw = "Y" THEN # user privs. 
		CREATE temp TABLE o_sysusers(username CHAR(8), 
		usertype CHAR(1)) 
		with no LOG 
		LOAD FROM gv_sysusers_unl 
		INSERT INTO o_sysusers 
	END IF 
	# sysconstraints, syscoldepend, syschecks
	IF gr_params.const_sw = "Y" THEN 
		CREATE temp TABLE o_sysconstraints(constrid INTEGER, constrname CHAR 
		(18), owner CHAR(8), tabid INTEGER, 
		constrtype CHAR(1), idxname CHAR(18)) 
		with no LOG 
		LOAD FROM gv_sysconstr_unl 
		INSERT INTO o_sysconstraints 
		CREATE temp TABLE o_syscoldepend(constrid INTEGER, tabid INTEGER, 
		colno smallint) 
		with no LOG 
		LOAD FROM gv_syscoldep_unl 
		INSERT INTO o_syscoldepend 
		CREATE temp TABLE o_syschecks(constrid INTEGER, type CHAR(1), seqno 
		SMALLINT, checktext CHAR(32)) 
		with no LOG 
		LOAD FROM gv_syschecks_unl 
		INSERT INTO o_syschecks 
		# Note: updrule, delrule, matchtype, AND pendant are reserved FOR future use
		CREATE temp TABLE o_sysreferences(constrid INTEGER, prim INTEGER, 
		ptabid INTEGER, updrule CHAR(1), 
		delrule CHAR(1), matchtype CHAR(1), 
		pendant CHAR(1)) 
		with no LOG 
		LOAD FROM gv_sysrefs_unl 
		INSERT INTO o_sysreferences 
	END IF 
	# systriggers, systrigbody
	IF gr_params.trig_sw = "Y" THEN 
		CREATE temp TABLE o_systriggers(trigid INTEGER, trigname CHAR(18), 
		owner CHAR(18), tabid int, event CHAR 
		(1), the_old CHAR(18), the_new CHAR(18)) 
		with no LOG 
		LOAD FROM gv_systrigg_unl 
		INSERT INTO o_systriggers 
		CREATE temp TABLE o_systrigbody(trigid INTEGER, datakey CHAR(1), 
		seqno int, data CHAR(256)) 
		with no LOG 
		LOAD FROM gv_systrigb_unl 
		INSERT INTO o_systrigbody 
	END IF 
	# sysprocgers, sysprocbody
	IF gr_params.spl_sw = "Y" THEN 
		CREATE temp TABLE o_sysprocbody(procid INTEGER, seqno int, data CHAR 
		(256)) 
		with no LOG 
		LOAD FROM gv_sysprocb_unl 
		INSERT INTO o_sysprocbody 
		CREATE temp TABLE o_sysprocedures(procname CHAR(18), owner CHAR(8), 
		procid int) 
		with no LOG 
		LOAD FROM gv_sysproc_unl 
		INSERT INTO o_sysprocedures 
	END IF 
	GOTO exitok 

	LABEL exiterr: 
	CALL err_print(status) 
	RETURN false 

	LABEL exitok: 
	RETURN true 

	WHENEVER any ERROR stop 

END FUNCTION 


###################################################################
# FUNCTION check_tabs()
#
#
###################################################################
FUNCTION check_tabs() 
	DEFINE tabrec 
	RECORD # tables 
		tabname CHAR(18), 
		tabid INTEGER, 
		tabtype CHAR(1) 
	END RECORD 
	DEFINE synrec 
	RECORD # synonyms 
		servername CHAR(18), 
		dbname CHAR(18), 
		ntabname CHAR(18), 
		btabid INTEGER 
	END RECORD 
	DEFINE colrec 
	RECORD # COLUMNS 
		colname CHAR(18), 
		collength SMALLINT, 
		coltype SMALLINT, 
		colno SMALLINT 
	END RECORD # comparison ARRAY 
	DEFINE chk_cols ARRAY [500] OF 
	RECORD 
		o_colname CHAR(18), 
		o_coltype SMALLINT, 
		o_collength SMALLINT, 
		o_colno SMALLINT, 
		n_colname CHAR(18), 
		n_coltype SMALLINT, 
		n_collength SMALLINT, 
		n_colno SMALLINT 
	END RECORD 
	DEFINE exp_col SMALLINT 
	DEFINE sel_stmt CHAR(600) 
	DEFINE tmp_strg CHAR(180) 
	DEFINE strg CHAR(180) 
	DEFINE i SMALLINT # junk variables 
	DEFINE j SMALLINT # junk variables 
	DEFINE k SMALLINT # junk variables 

	LET sql_idx = 1 
	LET msg = "Now detecting tables TO DROP..." 
	CALL put_log(msg) 
	DECLARE drop_curs CURSOR FOR 
	SELECT tabname, 
	tabtype 
	FROM systables 
	WHERE tabid > 99 
	AND tabname matches gr_params.tb_name 
	AND NOT exists(SELECT tabname 
	FROM o_systables 
	WHERE systables.tabname = o_systables.tabname) 
	FOREACH drop_curs INTO tabrec.tabname, 
		tabrec.tabtype 
		CASE tabrec.tabtype 
			WHEN 'T' # TABLE 
				LET strg = "DROP TABLE ", 
				tabrec.tabname clipped, 
				";" 
				OUTPUT TO REPORT sql_script(strg) 
				OUTPUT TO REPORT sql_script("") # blank line 
			WHEN 'S' # SYNONYM 
				LET strg = "DROP SYNONYM ", 
				tabrec.tabname clipped, 
				";" 
				OUTPUT TO REPORT sql_script(strg) 
				OUTPUT TO REPORT sql_script("") # blank line 
			WHEN 'V' # VIEW 
				LET strg = "DROP VIEW ", 
				tabrec.tabname clipped, 
				";" 
				OUTPUT TO REPORT sql_script(strg) 
				OUTPUT TO REPORT sql_script("") # blank line 
				#WHEN 'L'     # SE Log
				#WHEN 'P'     # Private synonym
				# OR synonym in ANSI
		END CASE 
	END FOREACH 
	FREE drop_curs 
	LET msg = "Now detecting tables TO CREATE..." 
	CALL put_log(msg) 
	DECLARE add_curs CURSOR FOR 
	SELECT tabname, 
	tabid, 
	tabtype 
	FROM o_systables 
	WHERE tabname matches gr_params.tb_name 
	AND NOT exists(SELECT tabname 
	FROM systables 
	WHERE systables.tabname = o_systables.tabname) 
	LET sel_stmt = "SELECT colname, collength, coltype, colno FROM o_syscols ", 
	"WHERE tabid = ? ORDER BY colno" 
	PREPARE c_prp FROM sel_stmt 
	LET sel_stmt = "SELECT viewtext, seqno FROM o_sysviews ", 
	"WHERE tabid = ? ORDER BY seqno" 
	DECLARE get_col CURSOR FOR c_prp 
	PREPARE vc FROM sel_stmt 
	DECLARE view_curs CURSOR FOR vc 
	FOREACH add_curs INTO tabrec.tabname, 
		tabrec.tabid, 
		tabrec.tabtype 
		CASE tabrec.tabtype 
			WHEN 'T' # TABLE 
				LET tmp_strg = "CREATE TABLE ", 
				tabrec.tabname clipped, 
				" (" 
				OPEN get_col USING tabrec.tabid # all COLUMNS FOR this TABLE 
				FOREACH get_col INTO colrec.colname, 
					colrec.collength, 
					colrec.coltype, 
					colrec.colno 
					# FORMAT the string FOR this COLUMN
					LET strg = colrec.colname clipped, #column 27, 
					{
					I had TO comment out above "COLUMN" statement, because Querix don't LIKE it:
						|
						|   Variable "COLUMN" NOT defined.
						|
						| Check that variable name has been defined correctly, check GLOBALS file FOR
						| definition.
						|
						| Check error -4369.
						|
						|________________________________________________________^
						|
						|   A grammatical error has been found on line 698, character 58.
						| The CONSTRUCT IS NOT understandable in its context.
						|
						| Check error -4373.
						|
					}
					col_cnvrt(colrec.coltype, colrec.collength) 
					CALL build_sql(strg, tmp_strg, ",") 
				END FOREACH 
				CALL build_sql("END", "", ");") 
			WHEN 'S' # SYNONYM 
				SELECT servername, 
				dbname, 
				ntabname, 
				btabid INTO synrec.servername, 
				synrec.dbname, 
				synrec.ntabname, 
				synrec.btabid 
				FROM o_syssyntab 
				WHERE tabid = tabrec.tabid 
				IF length(synrec.servername) > 0 THEN 
					LET strg = "CREATE SYNONYM ", 
					tabrec.tabname clipped, 
					" FOR ", 
					synrec.dbname clipped, 
					"@", 
					get_server(synrec.servername, tabrec.tabname) clipped, 
					":", 
					synrec.ntabname clipped, 
					";" 
				ELSE 
					IF length(synrec.dbname) > 0 THEN 
						LET strg = "CREATE SYNONYM ", 
						tabrec.tabname clipped, 
						" FOR ", 
						synrec.dbname clipped, 
						":", 
						synrec.ntabname clipped, 
						";" 
					ELSE # in local DATABASE 
						SELECT tabname INTO synrec.ntabname 
						FROM o_systables 
						WHERE tabid = synrec.btabid 
						LET strg = "CREATE SYNONYM ", 
						tabrec.tabname clipped, 
						" FOR ", 
						synrec.ntabname clipped, 
						";" 
					END IF 
				END IF 
				OUTPUT TO REPORT sql_script(strg) 
				OUTPUT TO REPORT sql_script("") # blank line 
			WHEN 'V' # VIEW 
				LET strg = "" 
				OPEN view_curs USING tabrec.tabid 
				FOREACH view_curs INTO tmp_strg, 
					i 
					LET strg = strg clipped, 
					tmp_strg clipped 
					CALL clip_strg(strg) 
					RETURNING tmp_strg, 
					strg 
					CALL build_sql(tmp_strg, "", "") 
				END FOREACH 
				CALL build_sql("END", "", strg) # NEED TO reset the counter 
				#WHEN 'P'   # private synonym OR ANSI syonym
				#WHEN 'L'   # SE log
		END CASE 
	END FOREACH 
	FREE add_curs 
	LET msg = "Now detecting tables TO ALTER..." 
	CALL put_log(msg) 
	DECLARE table_list CURSOR FOR 
	SELECT o_systables.tabid, 
	o_systables.tabname 
	FROM o_systables, 
	systables 
	WHERE systables.tabname = o_systables.tabname 
	AND systables.tabtype = 'T' 
	AND o_systables.tabtype = 'T' 
	AND o_systables.tabname matches gr_params.tb_name 
	ORDER BY tabname 
	LET sel_stmt = 
	'select colname, colno, coltype, collength', 
	' FROM "informix".syscolumns, "informix".systables', 
	' WHERE tabname = ?', 
	' AND "informix".syscolumns.tabid = "informix".systables.tabid', 
	' ORDER BY colno' 
	PREPARE n_c FROM sel_stmt 
	DECLARE n_cols CURSOR FOR n_c 
	FOREACH table_list INTO tabrec.tabid, 
		tabrec.tabname 
		CALL put_progress(tabrec.tabname) 
		LET tmp_strg = "ALTER TABLE ", 
		tabrec.tabname clipped 
		FOR i = 1 TO 500 
			INITIALIZE chk_cols[i].* TO NULL 
		END FOR 
		# Note: j IS NOT a junk variable in this loop.  j points TO last valid
		# COLUMN info found.  i IS junk
		# load old columns INTO array
		LET j = 1 
		OPEN get_col USING tabrec.tabid 
		FOREACH get_col INTO chk_cols[j].o_colname, 
			chk_cols[j].o_collength, 
			chk_cols[j].o_coltype, 
			chk_cols[j].o_colno 
			LET j = j + 1 
		END FOREACH # j points 1 past 
		# load new columns - find match in array
		OPEN n_cols USING tabrec.tabname 
		FOREACH n_cols INTO chk_cols[j].n_colname, 
			chk_cols[j].n_colno, 
			chk_cols[j].n_coltype, 
			chk_cols[j].n_collength 
			FOR i = 1 TO j 
				IF chk_cols[i].o_colname = chk_cols[j].n_colname THEN 
					LET chk_cols[i].n_colname = chk_cols[j].n_colname 
					LET chk_cols[i].n_colno = chk_cols[j].n_colno 
					LET chk_cols[i].n_coltype = chk_cols[j].n_coltype 
					LET chk_cols[i].n_collength = chk_cols[j].n_collength 
					INITIALIZE chk_cols[j].* TO NULL # CLEAR it 
					EXIT FOR 
				END IF 
			END FOR 
			IF i >= j THEN # didn't find a match, j --> valid ROW 
				LET j = j + 1 # j --> NULL ROW 
				IF j > 500 THEN 
					LET msg = "Warning: '", 
					tabrec.tabname clipped, 
					"' table has too many COLUMN differences!" 
					CALL put_log(msg) 
					EXIT FOREACH 
				END IF 
			END IF 
		END FOREACH 
		LET j = j -1 # j now --> LAST valid ROW 
		###################################################################
		# We now have a loaded ARRAY of matching columns FOR this table.  Loop
		# through this ARRAY AND check TO make sure all columns  are the same
		# AND IN THE SAME ORDER.  IF NOT - THEN we need TO fix it.
		###################################################################
		LET exp_col = 1 # expected COLUMN number 
		# loop through array:
		FOR i = 1 TO j 
			# IF colname NULL in old THEN
			# drop COLUMN
			IF chk_cols[i].o_colname IS NULL THEN 
				LET strg = "DROP (", 
				chk_cols[i].n_colname clipped, 
				")" 
				CALL build_sql(strg, tmp_strg, ",") 
				LET exp_col = exp_col + 1 # keep track OF expected colno 
				# IF colname NULL in new THEN add COLUMN
			ELSE 
				IF chk_cols[i].n_colname IS NULL THEN 
					# Have a good look FOR a COLUMN TO ADD BEFORE...   #KJS
					FOR k = i TO j #kjs 
						IF chk_cols[k].n_colname IS NOT NULL THEN #kjs 
							EXIT FOR #kjs 
						END IF #kjs 
					END FOR #kjs 
					IF length(chk_cols[k].n_colname) != 0 THEN #kjs 
						LET strg = col_cnvrt(chk_cols[i].o_coltype, 
						chk_cols[i].o_collength) 
						LET strg = "ADD (", 
						chk_cols[i].o_colname, 
						" ", 
						strg clipped, 
						" BEFORE ", 
						chk_cols[k].n_colname clipped, 
						")" 
					ELSE 
						LET strg = "ADD (", 
						chk_cols[i].o_colname, 
						" ", 
						col_cnvrt(chk_cols[i].o_coltype, 
						chk_cols[i].o_collength) clipped, 
						")" 
					END IF 
					CALL build_sql(strg, tmp_strg, ",") 
				ELSE # o_colname = n_colname - 
					# check type/length/colno
					IF chk_cols[i].n_colno != exp_col THEN # wrong ORDER ! 
						#
						# FIX THIS.  In this CASE what we should do IS generate code TO unload the
						#            table, drop it, recreate it, reload it.  In Next Release?
						#
						LET msg = "WARNING: '", 
						tabrec.tabname clipped, 
						".", 
						chk_cols[i].o_colname clipped, 
						"' COLUMN in the wrong ORDER!" 
						CALL put_log(msg) 
					END IF 
					IF chk_cols[i].o_coltype != chk_cols[i].n_coltype 
					OR chk_cols[i].o_collength != chk_cols[i].n_collength THEN 
						LET strg = "MODIFY (", 
						chk_cols[i].n_colname, 
						" ", 
						col_cnvrt(chk_cols[i].o_coltype, 
						chk_cols[i].o_collength) clipped, 
						")" 
						CALL build_sql(strg, tmp_strg, ",") 
					END IF 
					LET exp_col = exp_col + 1 # expected COLUMN number 
				END IF 
			END IF 
		END FOR # COLUMNS 
		IF sql_idx > 1 THEN 
			CALL build_sql("END", "", ";") 
		END IF 
	END FOREACH # table_list 
	FREE get_col 
END FUNCTION 



###################################################################
# FUNCTION check_idx()
#
# note this routine pays no attention TO the index name, but compares the
# indices based on the columns, AND the ORDER they are in.  So IF indices
# have different names - it doesn't care.
###################################################################
FUNCTION check_idx() 
	DEFINE sel_stmt CHAR(450) 
	DEFINE i SMALLINT 
	DEFINE idxrec 
	RECORD 
		tabname CHAR(18), 
		idxname CHAR(18), 
		tabid INTEGER, 
		idxtype CHAR(1), 
		clustered CHAR(1) 
	END RECORD 
	DEFINE p_colname CHAR(18) 
	DEFINE strg CHAR(306) # 16*18 = 288 + 18*whitespace = 306 
	DEFINE last_idx 
	RECORD 
		tabname CHAR(18), 
		ver SMALLINT, 
		idxname CHAR(18), 
		descr CHAR(306) 
	END RECORD 

	DEFINE curr_idx 
	RECORD 
		tabname CHAR(18), 
		ver SMALLINT, 
		idxname CHAR(18), 
		descr CHAR(306) 
	END RECORD 

	# get old indices
	# WHERE TABLES ALREADY EXIST
	# new tables will be handled shortly
	# dropped tables wont show in this list
	LET msg = "Checking Index differences..." 
	CALL put_log(msg) 
	IF gr_params.online_sw = "Y" THEN 
		LET max_parts = 16 
	ELSE 
		LET max_parts = 8 
	END IF 
	LET sel_stmt = 'select o_systables.tabname, idxname, o_sysindexes.tabid, ', 
	'idxtype, clustered ', 
	'from o_sysindexes, o_systables, "informix".systables ', 
	'where "informix".systables.tabname = o_systables.tabname ', 
	'and o_systables.tabid = o_sysindexes.tabid ', 
	'and o_systables.tabname matches "', 
	gr_params.tb_name clipped, 
	'" ', 
	'and idxname NOT matches " *" ', 
	'order BY 1,2' 
	PREPARE i_c 
	FROM sel_stmt 
	DECLARE o_idx_curs CURSOR FOR i_c 
	# resolve indices INTO names
	# AND load INTO temp table
	CREATE temp TABLE cmp_idx(tabname CHAR(18), 
	ver SMALLINT, 
	idxname CHAR(18), 
	descr CHAR(306)) 
	with no LOG 
	FOREACH o_idx_curs INTO idxrec.* 
		CALL idx_parts(idxrec.idxname, 0) 
		RETURNING strg 
		INSERT INTO cmp_idx(tabname, 
		ver, 
		idxname, 
		descr) 
		VALUES (idxrec.tabname, 
		1, 
		idxrec.idxname, 
		strg) 
	END FOREACH 
	FREE o_idx_curs 
	# get new indices
	IF gr_params.online_sw = "Y" THEN # CURRENT length OF sel_stmt = 424 
		LET sel_stmt = 'select "informix".systables.tabname, idxname, ', 
		'"informix".sysindexes.tabid, idxtype, clustered ', 
		'from "informix".sysindexes, o_systables,', 
		' "informix".systables ', 
		'where "informix".systables.tabname = o_systables.tabname ', 
		'and "informix".systables.tabid = "informix".sysindexes.tabid ', 
		'and idxname NOT matches " *"' 
	ELSE 
		LET sel_stmt = 'select "informix".systables.tabname, idxname, ', 
		'"informix".sysindexes.tabid, idxtype, clustered ', 
		'from "informix".sysindexes, o_systables, "informix".systables ', 
		'where "informix".systables.tabname = o_systables.tabname ', 
		'and "informix".systables.tabid = "informix".sysindexes.tabid ', 
		'and idxname NOT matches " *"' 
	END IF 
	PREPARE i_c2 
	FROM sel_stmt 
	DECLARE n_idx_curs CURSOR FOR i_c2 
	# resolve indices INTO names
	# AND load INTO temp table
	FOREACH n_idx_curs INTO idxrec.* 
		CALL idx_parts(idxrec.idxname, 1) 
		RETURNING strg 
		INSERT INTO cmp_idx (tabname, ver, idxname, descr)values(idxrec.tabname, 2, 
		idxrec.idxname, strg) 
	END FOREACH 
	FREE n_idx_curs 
	###########################################################################
	# Now we've built a table of indices,  common indices should have identical
	# descr strings.  Those that don't need TO get fixed.  Just a touch of brute
	# force...  Pity we can't use a GROUP BY, but we need the idxname still.
	###########################################################################
	# read each index, put the ver=1 ones INTO last_idx (they will be first)
	# put the others INTO curr_idx.
	# whenever curr_idx.ver=2 THEN we should have both loaded.  IF NOT THEN
	# last_idx.* IS NULL - index doesn't exist on old
	# curr_idx.* IS NULL - we've just read a ver=1 AND last_idx IS NOT NULL
	DECLARE idx_curs CURSOR FOR 
	SELECT tabname, 
	ver, 
	idxname, 
	descr 
	FROM cmp_idx 
	ORDER BY tabname, 
	descr, 
	ver 
	INITIALIZE last_idx.* TO NULL 
	FOREACH idx_curs INTO curr_idx.* 
		LET msg = curr_idx.tabname, 
		curr_idx.idxname 
		CALL put_progress(msg) 
		CASE curr_idx.ver 
			WHEN 1 
				IF length(last_idx.idxname) > 0 THEN 
					CALL create_idx(last_idx.idxname) 
					LET last_idx.* = curr_idx.* 
				END IF 
				LET last_idx.* = curr_idx.* 
			WHEN 2 
				IF length(last_idx.descr) = 0 THEN 
					LET msg = "DROP INDEX ", 
					curr_idx.idxname clipped, 
					";" 
					OUTPUT TO REPORT sql_script(msg) 
					OUTPUT TO REPORT sql_script("") 
					CALL put_log(msg) 
				ELSE 
					IF last_idx.descr != curr_idx.descr THEN 
						LET msg = "DROP INDEX ", 
						curr_idx.idxname clipped, 
						";" 
						OUTPUT TO REPORT sql_script(msg) 
						OUTPUT TO REPORT sql_script("") 
						CALL put_log(msg) 
						CALL create_idx(last_idx.idxname) 
						INITIALIZE last_idx.* TO NULL 
					ELSE # same INDEX 
						CALL verify_idx(last_idx.idxname, curr_idx.idxname) 
						INITIALIZE last_idx.* TO NULL 
					END IF 
				END IF 
		END CASE 
	END FOREACH 
	FREE idx_curs 
	# new indices
	DECLARE new_idx CURSOR FOR 
	SELECT idxname 
	FROM o_systables, 
	o_sysindexes 
	WHERE NOT exists( 
	SELECT tabname 
	FROM systables 
	WHERE systables.tabname = o_systables.tabname) 
	AND tabtype = 'T' 
	AND o_systables.tabid = o_sysindexes.tabid 
	AND idxname NOT matches ' *' 
	FOREACH new_idx INTO last_idx.idxname 
		CALL put_progress(last_idx.idxname) 
		CALL create_idx(last_idx.idxname) 
	END FOREACH 

	FREE new_idx 
END FUNCTION 


###################################################################
# FUNCTION create_idx(p_idxname)
#
# create indices
# bummer, don't want TO use that descr line since it's too long
###################################################################
FUNCTION create_idx(p_idxname) 
	DEFINE p_idxname CHAR(18) 
	DEFINE idxrec 
	RECORD 
		tabid INTEGER, 
		tabname CHAR(18), 
		idxtype CHAR(1), 
		clustered CHAR(1) 
	END RECORD 
	DEFINE parts ARRAY [16] OF SMALLINT 
	DEFINE i SMALLINT 
	DEFINE p_colname CHAR(24) 
	DEFINE desc_sw SMALLINT 
	DEFINE strg CHAR(500) 
	DEFINE tmp_strg CHAR(500) 
	DEFINE idx_strg CHAR(500) 

	CALL idx_parts(p_idxname, 0) 
	RETURNING idx_strg 
	IF gr_params.online_sw = "Y" THEN 
		SELECT o_systables.tabid, 
		o_systables.tabname, 
		idxtype, 
		clustered INTO idxrec.* 
		FROM o_sysindexes, 
		o_systables 
		WHERE idxname = p_idxname 
		AND o_sysindexes.tabid = o_systables.tabid 
	ELSE 
		SELECT o_systables.tabid, 
		o_systables.tabname, 
		idxtype, 
		clustered INTO idxrec.* 
		FROM o_sysindexes, 
		o_systables 
		WHERE idxname = p_idxname 
		AND o_sysindexes.tabid = o_systables.tabid 
	END IF 
	# unique?
	IF idxrec.idxtype = 'U' THEN 
		LET tmp_strg = "CREATE UNIQUE" 
	ELSE 
		LET tmp_strg = "CREATE" 
	END IF 
	# clustered?
	IF idxrec.clustered = 'C' THEN 
		SELECT idxname INTO p_colname # re-using other var, ignore NAME 
		FROM "informix".sysindexes 
		WHERE tabid = idxrec.tabid 
		AND clustered = 'C' 
		# FIX THIS - EXCLUDE CURRENT INDEX?  CAN'T BECAUSE OF NAME?
		# Commented out until a better solution IS found.  There IS no garauntee
		# that the index in question IS NOT a) the same one b) still existant.
		#
		#      IF STATUS != NOTFOUND THEN # uh-oh, already a clustered index
		#         LET strg = "ALTER INDEX ", p_colname clipped, " TO NOT CLUSTER;"
		#         OUTPUT TO REPORT sql_script(strg)
		#      END IF
		LET tmp_strg = tmp_strg clipped, 
		" CLUSTER" 
	END IF 
	# tack on index name
	LET tmp_strg = tmp_strg clipped, 
	" INDEX ", 
	p_idxname clipped, 
	" ON ", 
	idxrec.tabname clipped, 
	" (", 
	idx_strg clipped, 
	");" 
	# add columns
	CALL fold_and_push(tmp_strg, 1) 
END FUNCTION 


###################################################################
# FUNCTION verify_idx(o_idx, n_idx)
#
# Same index fields - are they the same type of index?  IF NOT fix.
###################################################################
FUNCTION verify_idx(o_idx, n_idx) 
	DEFINE o_idx CHAR(1) 
	DEFINE n_idx CHAR(18) 
	DEFINE o_clust CHAR(1) 
	DEFINE o_type CHAR(1) 
	DEFINE n_clust CHAR(1) 
	DEFINE n_type CHAR(1) 

	SELECT clustered, 
	idxtype INTO o_clust, 
	o_type 
	FROM o_sysindexes 
	WHERE idxname = o_idx 
	SELECT clustered, 
	idxtype INTO n_clust, 
	n_type 
	FROM "informix".sysindexes 
	WHERE idxname = n_idx 
	# cluster - there had better NOT be another.
	IF o_clust != n_clust 
	AND n_clust = 'C' THEN # bummer 
		# WHAT index jack?
		# find it!
		LET msg = 
		               "{Warning - this command must be run before any other CLUSTER on "
		              ,
		                "this table}"
		OUTPUT TO REPORT sql_script(msg) 
		CALL put_log(msg) 
		LET msg = "ALTER INDEX ", 
		n_idx clipped, 
		" TO NOT CLUSTER;" 
		OUTPUT TO REPORT sql_script(msg) 
		CALL put_log(msg) 
		OUTPUT TO REPORT sql_script("") 
	END IF 
	# unique/duplicate - they better be the same.
	IF o_type != n_type THEN 
		LET msg = "DROP INDEX ", 
		n_idx clipped, 
		";" 
		CALL put_log(msg) 
		OUTPUT TO REPORT sql_script(msg) 
		OUTPUT TO REPORT sql_script("") 
		CALL create_idx(o_idx) 
	END IF 
END FUNCTION 



###################################################################
# FUNCTION check_user()
#
# Compare contents of sysusers AND o_sysusers.
#    drop old OR different.  Add new OR different
###################################################################
FUNCTION check_user() 
	DEFINE usr_rec 
	RECORD 
		username CHAR(8), 
		usertype CHAR(1) 
	END RECORD 
	DEFINE sql_strg CHAR(80) 

	DECLARE drop_user CURSOR FOR 
	SELECT username, 
	usertype 
	FROM sysusers 
	WHERE NOT exists( 
	SELECT username 
	FROM o_sysusers 
	WHERE o_sysusers.username = sysusers.username)union 
	SELECT username, 
	usertype 
	FROM sysusers 
	WHERE exists( 
	SELECT username 
	FROM o_sysusers 
	WHERE o_sysusers.username = sysusers.username 
	AND o_sysusers.usertype != sysusers.usertype) 
	DECLARE add_user CURSOR FOR 
	SELECT username, 
	usertype 
	FROM o_sysusers 
	WHERE NOT exists( 
	SELECT username 
	FROM sysusers 
	WHERE o_sysusers.username = sysusers.username)union 
	SELECT username, 
	usertype 
	FROM o_sysusers 
	WHERE exists( 
	SELECT username 
	FROM sysusers 
	WHERE o_sysusers.username = sysusers.username 
	AND o_sysusers.usertype != sysusers.usertype) 
	INITIALIZE usr_rec.* TO NULL 
	CALL put_log("Generating REVOKE DATABASE PRIVILEGES") 
	FOREACH drop_user INTO usr_rec.username, 
		usr_rec.usertype 
		CASE usr_rec.usertype 
			WHEN "D" 
				LET sql_strg = "REVOKE DBA FROM ", 
				usr_rec.username clipped, 
				";" 
			WHEN "C" 
				LET sql_strg = "REVOKE CONNECT FROM ", 
				usr_rec.username clipped, 
				";" 
			WHEN "R" 
				LET sql_strg = "REVOKE RESOURCE FROM ", 
				usr_rec.username clipped, 
				";" 
		END CASE 
		CALL build_sql("END", sql_strg, ";") 
	END FOREACH 
	INITIALIZE usr_rec.* TO NULL 
	CALL put_log("Generating GRANT DATABASE PRIVILEGES") 
	FOREACH add_user INTO usr_rec.username, 
		usr_rec.usertype 
		CASE usr_rec.usertype 
			WHEN "D" 
				LET sql_strg = "GRANT DBA TO ", 
				usr_rec.username clipped, 
				";" 
			WHEN "C" 
				LET sql_strg = "GRANT CONNECT TO ", 
				usr_rec.username clipped, 
				";" 
			WHEN "R" 
				LET sql_strg = "GRANT RESOURCE TO ", 
				usr_rec.username clipped, 
				";" 
		END CASE 
		CALL build_sql("END", sql_strg, "") 
	END FOREACH 
	FREE drop_user 
	FREE add_user 
END FUNCTION 


###################################################################
# FUNCTION check_auth_general() 
#
# Change table authority/permissions
# compare tables AND drop old OR different.  Add new OR different
# NB.
# have TO do columns first, cause there IS no way TO
# revoke COLUMN level privileges, so I'm going TO have
# TO wipe the entire table first AND THEN re-grant.  would
# be a pain TO do tables AND THEN wipe them FROM colauth()
###################################################################
FUNCTION check_auth_general() 
	DEFINE fn_rec 
	RECORD 
		grantor CHAR(8), 
		grantee CHAR(8), 
		tabauth CHAR(8), 
		tabname CHAR(18), 
		ntabauth CHAR(8) 
	END RECORD 
	DEFINE sql_strg CHAR(80) 

	# Problem: tabid IS NOT guaranteed TO be the same between databases (AND IS
	# really NOT important in that context) - we need tabname
	DECLARE drop_tab CURSOR FOR 
	SELECT grantee, 
	tabname 
	FROM systabauth, 
	systables 
	WHERE systabauth.tabid = systables.tabid 
	AND user = grantor # can't REVOKE those you didn't give 
	AND NOT exists( 
	SELECT grantor, grantee, tabname 
	FROM o_systabauth, o_systables 
	WHERE o_systabauth.tabid = o_systables.tabid 
	AND o_systabauth.grantor = systabauth.grantor 
	AND o_systabauth.grantee = systabauth.grantee 
	AND o_systables.tabname = systables.tabname)union 
	SELECT grantee, 
	tabname 
	FROM systabauth, 
	systables 
	WHERE systabauth.tabid = systables.tabid 
	AND user = grantor # can't REVOKE those you didn't give 
	AND exists( 
	SELECT grantor, grantee, tabname 
	FROM o_systabauth, o_systables 
	WHERE o_systabauth.tabid = o_systables.tabid 
	AND o_systabauth.grantor = systabauth.grantor 
	AND o_systabauth.grantee = systabauth.grantee 
	AND o_systables.tabname = systables.tabname 
	AND o_systabauth.tabauth != systabauth.tabauth) 
	DECLARE add_tab CURSOR FOR 
	SELECT grantor, 
	grantee, 
	tabauth, 
	tabname 
	FROM o_systabauth, 
	o_systables 
	WHERE o_systabauth.tabid = o_systables.tabid 
	AND NOT exists( 
	SELECT grantor, grantee, tabname 
	FROM systabauth, systables 
	WHERE systabauth.tabid = systables.tabid 
	AND o_systabauth.grantor = systabauth.grantor 
	AND o_systabauth.grantee = systabauth.grantee 
	AND o_systables.tabname = systables.tabname)union 
	SELECT grantor, 
	grantee, 
	tabauth, 
	tabname 
	FROM o_systabauth, 
	o_systables 
	WHERE o_systabauth.tabid = o_systables.tabid 
	AND exists( 
	SELECT grantor, grantee, tabname 
	FROM systabauth, systables 
	WHERE systabauth.tabid = systables.tabid 
	AND o_systabauth.grantor = systabauth.grantor 
	AND o_systabauth.grantee = systabauth.grantee 
	AND o_systables.tabname = systables.tabname 
	AND o_systabauth.tabauth != systabauth.tabauth) 
	INITIALIZE fn_rec.* TO NULL 
	CALL put_log("Generating REVOKE TABLE PRIVILEGES") 
	FOREACH drop_tab INTO fn_rec.grantee, 
		fn_rec.tabname 
		LET sql_strg = "REVOKE ALL ON ", 
		fn_rec.tabname clipped, 
		" FROM ", 
		fn_rec.grantee clipped 
		CALL build_sql("END", sql_strg, ";") 
	END FOREACH 
	INITIALIZE fn_rec.* TO NULL 
	CALL put_log("Generating ADD TABLE PRIVILEGES") 
	FOREACH add_tab INTO fn_rec.grantor, 
		fn_rec.grantee, 
		fn_rec.tabauth, 
		fn_rec.tabname 
		# oh boy this IS going TO be fun! 8*2-1 VALUES TO check here.
		IF fn_rec.tabauth[1, 1]matches "[Ss]" THEN 
			CALL priv_grant(MODE_CLASSIC_SELECT, fn_rec.tabname, fn_rec.grantee, 
			fn_rec.grantor, fn_rec.tabauth[1, 1]) 
		END IF 
		IF fn_rec.tabauth[2, 2]matches "[Uu]" THEN 
			CALL priv_grant(MODE_CLASSIC_UPDATE, fn_rec.tabname, fn_rec.grantee, 
			fn_rec.grantor, fn_rec.tabauth[2, 2]) 
		END IF 
		IF fn_rec.tabauth[4, 4]matches "[Ii]" THEN 
			CALL priv_grant(MODE_CLASSIC_INSERT, fn_rec.tabname, fn_rec.grantee, 
			fn_rec.grantor, fn_rec.tabauth[4, 4]) 
		END IF 
		IF fn_rec.tabauth[5, 5]matches "[Dd]" THEN 
			CALL priv_grant(MODE_CLASSIC_DELETE, fn_rec.tabname, fn_rec.grantee, 
			fn_rec.grantor, fn_rec.tabauth[5, 5]) 
		END IF 
		IF fn_rec.tabauth[6, 6]matches "[Xx]" THEN 
			CALL priv_grant("INDEX", fn_rec.tabname, fn_rec.grantee, fn_rec.grantor 
			, fn_rec.tabauth[6, 6]) 
		END IF 
		IF fn_rec.tabauth[7, 7]matches "[Aa]" THEN 
			CALL priv_grant("ALTER", fn_rec.tabname, fn_rec.grantee, fn_rec.grantor 
			, fn_rec.tabauth[7, 7]) 
		END IF 
		IF fn_rec.tabauth[8, 8]matches "[Rr]" THEN 
			CALL priv_grant("REFERENCES", fn_rec.tabname, fn_rec.grantee, 
			fn_rec.grantor, fn_rec.tabauth[8, 8]) 
		END IF 
	END FOREACH 
	FREE drop_tab 
	FREE add_tab 
END FUNCTION 


###################################################################
# FUNCTION priv_grant(priv, tabname, grantee, grantor, g_opt)
#
# Generate grant statement
###################################################################
FUNCTION priv_grant(priv, tabname, grantee, grantor, g_opt) 
	DEFINE priv CHAR(10) 
	DEFINE tabname CHAR(18) 
	DEFINE grantee CHAR(8) 
	DEFINE grantor CHAR(8) 
	DEFINE g_opt CHAR(1) 
	DEFINE sql_strg CHAR(80) 

	LET sql_strg = "GRANT ", 
	priv clipped, 
	" ON ", 
	tabname clipped, 
	" TO ", 
	grantee clipped 
	# IF it IS upper CASE (ASCII 65-90) THEN they
	# have grant option.
	IF g_opt < ascii(91) THEN 
		LET sql_strg = sql_strg clipped, 
		" WITH GRANT OPTION" 
	END IF 
	# creator IS a grantee, but grantor IS blank!
	IF length(grantor) > 0 THEN 
		LET sql_strg = sql_strg clipped, 
		" AS ", 
		grantor clipped, 
		";" 
	ELSE 
		LET sql_strg = sql_strg clipped, 
		";" 
	END IF 
	CALL build_sql("END", sql_strg, "") 
END FUNCTION 


###################################################################
# FUNCTION check_constr()
#
# This IS NOT going TO be pretty.  A constraint IS defined across multiple
# tables identified by multiple keys which are integral TO the current
# database AND do NOT necessarily match the other database (constrid, tabid,
# idxname, colno) the only way TO ensure that we get the right ones AND
# only the right ones IS TO work out the full constraint definition AND
# THEN compare it TO the other databases definitions - sort of LIKE the
# way indexes were done.  This time though, I'm going TO express it in
# sql so that I don't need TO make a second pass TO generate it.
# jp 10/30/94
#
###################################################################
FUNCTION check_constr() 
	DEFINE constr_rec 
	RECORD 
		constr_id INTEGER, 
		constr_name CHAR(18), 
		owner CHAR(8), 
		tabid INTEGER, 
		constrtype CHAR(1), 
		idxname CHAR(18), 
		tabname CHAR(18), 
		the_primary INTEGER 
	END RECORD 
	DEFINE sel_stmt CHAR(2000) 
	DEFINE stmt1 CHAR(500) 
	DEFINE sql_stmt CHAR(500) 
	DEFINE s1 CHAR(100) 
	DEFINE i SMALLINT 
	DEFINE oldnew SMALLINT 
	# get some work space.
	CREATE temp TABLE tmp_constr(constrname CHAR(18), tabname CHAR(18), old_new 
	SMALLINT, constr_def CHAR(500)) 
	with no LOG 
	# 1 - identify each old constraint.
	# handle checks seperately
	IF gr_params.online_sw = "Y" THEN 
		LET sel_stmt = "SELECT o_sysconstraints.constrid, constrname, ", 
		"o_sysconstraints.owner, o_sysconstraints.tabid, constrtype, " 
		, 
		"o_sysconstraints.idxname, tabname, prim ", 
		"FROM o_sysconstraints, o_systables, OUTER o_sysreferences " 
		, 
		"WHERE o_sysconstraints.tabid = o_systables.tabid ", 
		"AND o_sysconstraints.constrid = o_sysreferences.constrid " 
		, 
		"AND constrtype != 'C'" 
	ELSE 
		LET sel_stmt = "SELECT o_sysconstraints.constrid, constrname, ", 
		"o_sysconstraints.owner, o_sysconstraints.tabid, constrtype, " 
		, 
		"o_sysconstraints.idxname, tabname, prim ", 
		"FROM o_sysconstraints, o_systables, o_sysindexes,OUTER o_sysreferences " 
		, 
		"WHERE o_sysconstraints.tabid = o_systables.tabid ", 
		"AND o_sysconstraints.constrid = o_sysreferences.constrid " 
		, 
		"AND constrtype != 'N'", # added BY mf 
		"AND constrtype != 'C'" 
	END IF 
	PREPARE s1 
	FROM sel_stmt 
	DECLARE r_cons_o CURSOR FOR s1 
	# WHILE we're AT it, lets make the CURSOR FOR the new ones too.
	CALL translate("o_", "", sel_stmt) 
	RETURNING sel_stmt 
	CALL translate("prim", "primary", sel_stmt) 
	RETURNING sel_stmt 
	PREPARE s2 
	FROM sel_stmt 
	DECLARE r_cons_n CURSOR FOR s2 
	CALL put_log("Parsing old constraints") 
	FOREACH r_cons_o INTO constr_rec.* 
		CALL pars_cons(constr_rec.*, 0) 
	END FOREACH 
	# Do it again FOR the new ones
	CALL put_log("Parsing new constraints") 
	FOREACH r_cons_n INTO constr_rec.* 
		CALL pars_cons(constr_rec.*, 1) 
	END FOREACH 
	# SELECT unique ones (NOT a SELECT UNIQUE situation mind you)
	CALL put_log("Comparing constraints") 
	DECLARE cm_curs CURSOR FOR 
	SELECT constr_def 
	FROM tmp_constr GROUP BY constr_def 
	having count(*) = 1 
	# we couldn't grab everything AND group by all of them because the old_new
	# switch IS going TO be different
	FOREACH cm_curs INTO sql_stmt 
		SELECT constrname, 
		tabname, 
		old_new INTO constr_rec.constr_name, 
		constr_rec.tabname, 
		oldnew 
		FROM tmp_constr 
		WHERE constr_def = sql_stmt 
		# drop OR add according TO oldnew switch
		IF oldnew = 0 THEN 
			CALL fold_and_push(sql_stmt, 1) 
		ELSE 
			LET msg = "ALTER TABLE ", 
			constr_rec.tabname clipped, 
			" DROP CONSTRAINT ", 
			constr_rec.constr_name clipped, 
			";" 
			OUTPUT TO REPORT sql_script(msg) 
			OUTPUT TO REPORT sql_script("") 
		END IF 
	END FOREACH 
	# Handle syschecks, since they may be VERY long they won't work with the
	# comparison style we just used, match them up against one another INTO a
	# temp table, things NOT matched INTO the table need fixing.
	# find the id of all macthing ones
	CALL put_log("Parsing check constraints") 
	SELECT o_syschecks.constrid old_id, 
	syschecks.constrid new_id 
	FROM o_syschecks, 
	syschecks 
	WHERE o_syschecks.type = 'B' 
	AND syschecks.type = 'B' 
	AND o_syschecks.seqno = syschecks.seqno 
	AND o_syschecks.checktext = syschecks.checktext INTO temp duppedchecks 
	with no LOG 
	# these ones aren't there
	DECLARE new_checks CURSOR FOR 
	SELECT unique constrid 
	FROM syschecks 
	WHERE NOT exists( 
	SELECT new_id 
	FROM duppedchecks) 
	# nor are these ones
	DECLARE old_checks CURSOR FOR 
	SELECT unique constrid 
	FROM o_syschecks 
	WHERE NOT exists( 
	SELECT old_id 
	FROM duppedchecks) 
	# AND we'll need the text FOR the old ones.
	LET s1 = "SELECT checktext, seqno FROM o_syschecks WHERE constrid = ? AND ", 
	"type = 'T' ORDER BY seqno" 
	PREPARE ock 
	FROM s1 
	DECLARE oldchecks CURSOR FOR ock 
	CALL put_log("Generating drops FOR old check constraints") 
	# Lose the bad ones
	FOREACH new_checks INTO constr_rec.constr_id 
		SELECT constrname, 
		tabname INTO constr_rec.constr_name, 
		constr_rec.tabname 
		FROM sysconstraints, 
		systables 
		WHERE sysconstraints.tabid = systables.tabid 
		AND constrid = constr_rec.constr_id 
		LET sql_stmt = 'alter TABLE ', 
		constr_rec.tabname clipped, 
		' DROP constraint ', 
		constr_rec.constr_name clipped, 
		';' 
		OUTPUT TO REPORT sql_script(sql_stmt) 
	END FOREACH 
	# add the new ones
	CALL put_log("Generating adds FOR new check constraints") 
	FOREACH old_checks INTO constr_rec.constr_id 
		SELECT tabname INTO constr_rec.tabname 
		FROM o_sysconstraints, 
		o_systables 
		WHERE o_sysconstraints.tabid = o_systables.tabid 
		AND constrid = constr_rec.constr_id 
		LET sql_stmt = 'alter TABLE ', 
		constr_rec.tabname clipped, 
		' add constraint check' 
		OPEN oldchecks USING constr_rec.constr_id 
		# probably NOT broken on space boundaries....
		# FIX THIS.  This duplicates the functionaility of fold_and_push
		FOREACH oldchecks INTO stmt1 
			LET sql_stmt = sql_stmt clipped, 
			stmt1 
			IF length(sql_stmt) > 450 THEN 
				FOR i = length(sql_stmt) TO 1 step -1 
					IF sql_stmt[i, i] = ' ' THEN # break it here 
						LET stmt1 = sql_stmt[i, 500] # PUT TRAILER INTO stmt1 
						LET sql_stmt = sql_stmt[1, i] # get FIRST part 
						CALL fold_and_push(sql_stmt, 1) # fold AND push 
						LET sql_stmt = stmt1 # reset 
						EXIT FOR # outta here 
					END IF 
				END FOR 
			END IF 
		END FOREACH 
		LET sql_stmt = sql_stmt clipped, 
		";" 
		CALL fold_and_push(sql_stmt, 1) 
	END FOREACH 
END FUNCTION 


###################################################################
# FUNCTION pars_cons(constr_rec, o_n)
#
# A common routine TO generate the text of a constraint (except FOR checks)
#
###################################################################
FUNCTION pars_cons(constr_rec, o_n) 
	DEFINE constr_rec 
	RECORD 
		constr_id INTEGER, 
		constr_name CHAR(18), 
		owner CHAR(8), 
		tabid INTEGER, 
		constrtype CHAR(1), 
		idxname CHAR(18), 
		tabname CHAR(18), 
		the_primary INTEGER 
	END RECORD 
	DEFINE o_n SMALLINT 
	DEFINE sql_stmt CHAR(500) 
	DEFINE i SMALLINT 
	DEFINE j SMALLINT 
	DEFINE p_colname CHAR(18) 
	DEFINE p_tabname CHAR(18) 
	DEFINE col_strng CHAR(330) # 16*20+10_just_in_case 

	# base - all have this
	LET sql_stmt = 'alter TABLE ', 
	constr_rec.tabname clipped, 
	' add constraint' 
	# constraint type
	CASE constr_rec.constrtype 
		WHEN 'P' 
			LET sql_stmt = sql_stmt clipped, 
			' primary key' 
		WHEN 'U' 
			LET sql_stmt = sql_stmt clipped, 
			' unique' 
		WHEN 'R' 
			LET sql_stmt = sql_stmt clipped, 
			' foreign key' 
	END CASE 
	# constraint columns
	CALL idx_parts(constr_rec.idxname, o_n) 
	RETURNING col_strng 
	# add parens
	IF i > 2 THEN 
		LET col_strng = "(", 
		col_strng clipped, 
		")" 
	END IF 
	# add the string TO the SQL stmt
	LET sql_stmt = sql_stmt clipped, 
	col_strng clipped 
	# IF an 'R' THEN add on 'REFERENCES' clause
	IF constr_rec.constrtype = 'R' THEN 
		LET sql_stmt = sql_stmt clipped, 
		' references' 
		IF o_n = 0 THEN # old 
			SELECT idxname INTO p_colname 
			FROM o_sysconstraints, 
			o_sysreferences 
			WHERE o_sysconstraints.constrid = prim 
			AND o_sysreferences.constrid = constr_rec.constr_id 
			SELECT tabname INTO p_tabname 
			FROM o_sysreferences, 
			o_systables 
			WHERE o_sysreferences.ptabid = o_systables.tabid 
			AND o_sysreferences.constrid = constr_rec.constr_id 
		ELSE # new 
			DISPLAY "EXIT: disabled code because of <Anton Dickinson> ecp issue with primary" 
			DISPLAY "see utility/U19.4gl" 
			EXIT program (1) 
			{
			         SELECT idxname INTO p_colname
			            FROM sysconstraints,
			                 sysreferences
			            WHERE sysconstraints.constrid = sysreferences.primary
			             AND sysreferences.constrid = constr_rec.constr_id
			}
			SELECT tabname INTO p_tabname 
			FROM sysreferences, 
			systables 
			WHERE sysreferences.ptabid = systables.tabid 
			AND sysreferences.constrid = constr_rec.constr_id 
		END IF 
		# get COLUMN names
		CALL idx_parts(p_colname, o_n) 
		RETURNING col_strng 
		LET sql_stmt = sql_stmt clipped, 
		" ", 
		p_tabname clipped, 
		" (", 
		col_strng clipped, 
		")" 
	END IF 
	LET sql_stmt = sql_stmt clipped, 
	";" 
	INSERT INTO tmp_constr VALUES (constr_rec.constr_name, 
	constr_rec.tabname, 
	o_n, 
	sql_stmt) 
END FUNCTION 


###################################################################
# FUNCTION check_trigs()
#
# Change Triggers (Kerry Sainsbury)
# Compare contents of systriggers AND o_systriggers,
#     AND contents of systrigbody AND o_systrigbody
#    drop old OR different.  Add new OR different
#
###################################################################
FUNCTION check_trigs() 
	DEFINE l_trigname CHAR(18) 
	DEFINE l_owner CHAR(8) 
	DEFINE sql_strg CHAR(80) 
	DEFINE l_o 
	RECORD 
		trigid int, 
		trigname CHAR(18), 
		owner CHAR(8), 
		tabid int, 
		event char, 
		the_old CHAR(18), 
		the_new CHAR(18), 
		tabname CHAR(18) 
	END RECORD 
	DEFINE l_a 
	RECORD 
		trigid int, 
		trigname CHAR(18), 
		owner CHAR(8), 
		tabid int, 
		event char, 
		the_old CHAR(18), 
		the_new CHAR(18), 
		tabname CHAR(18) 
	END RECORD 
	DEFINE l_os 
	RECORD 
		datakey char, 
		seqno int, 
		data CHAR(256) 
	END RECORD 
	DEFINE l_as 
	RECORD 
		datakey char, 
		seqno int, 
		data CHAR(256) 
	END RECORD 
	DEFINE l_acnt INTEGER 
	DEFINE l_ocnt INTEGER 

	# Drop all triggers that are NOT in o_systriggers...
	DECLARE drop_trigs CURSOR FOR 
	SELECT systriggers.trigname, 
	systriggers.owner, 
	systables.tabname 
	FROM systriggers, 
	systables 
	WHERE systriggers.tabid = systables.tabid 
	AND systriggers.tabid > 99 
	AND tabname matches gr_params.tb_name 
	AND NOT exists( 
	SELECT trigname 
	FROM o_systriggers 
	WHERE o_systriggers.trigname = systriggers.trigname 
	AND o_systriggers.owner = systriggers.owner) 
	CALL put_log("Generating DROP TRIGGERs") 
	FOREACH drop_trigs INTO l_trigname, 
		l_owner 
		LET sql_strg = "DROP TRIGGER '", 
		l_owner clipped, 
		"'.", 
		l_trigname clipped, 
		";" 
		CALL build_sql("END", sql_strg, ";") 
	END FOREACH 
	FREE drop_trigs 
	# Now build a list of all triggers that're in both databases...
	# with the same trigger name AND owner
	DECLARE more_drop_trigs CURSOR FOR 
	SELECT o.trigid, 
	o.trigname, 
	o.owner, 
	o.tabid, 
	o.event, 
	o.the_old, 
	o.the_new, 
	p.tabname, 
	a.trigid, 
	a.trigname, 
	a.owner, 
	a.tabid, 
	a.event, 
	a.the_old, 
	a.the_new, 
	b.tabname 
	FROM o_systriggers o, 
	systriggers a, 
	o_systables p, 
	systables b 
	WHERE o.trigname = a.trigname 
	AND o.owner = a.owner 
	AND o.tabid = p.tabid 
	AND a.tabid = b.tabid 
	FOREACH more_drop_trigs INTO l_o.*, 
		l_a.* 
		-- Do a cheap n nasty check TO see IF triggers are different, based on the
		-- number of lines in each...
		LET l_acnt = 0 
		LET l_ocnt = 0 
		SELECT count(*)INTO l_acnt 
		FROM systrigbody 
		WHERE trigid = l_a.trigid 
		AND datakey in("D", "A") 
		SELECT count(*)INTO l_ocnt 
		FROM o_systrigbody 
		WHERE trigid = l_o.trigid 
		IF l_acnt != l_ocnt THEN # different number OF LINES in trigger 
			LET sql_strg = "DROP TRIGGER '", 
			l_a.owner clipped, 
			"'.", 
			l_a.trigname clipped, 
			";" 
			CALL build_sql("END", sql_strg, ";") 
		ELSE 
			-- Check FOR a subtle change (line count same, but content different)
			DECLARE subtle_curs CURSOR FOR 
			SELECT o.datakey, 
			o.seqno, 
			o.data, 
			a.datakey, 
			a.seqno, 
			a.data 
			FROM o_systrigbody o, 
			systrigbody a 
			WHERE a.trigid = l_a.trigid 
			AND o.trigid = l_o.trigid 
			AND o.seqno = a.seqno 
			AND o.datakey = a.datakey 
			ORDER BY o.datakey, 
			o.seqno 
			FOREACH subtle_curs INTO l_os.*, 
				l_as.* 
				-- IF text of trigger differs...
				IF l_os.data != l_as.data THEN 
					-- THEN throw the old trigger away...
					LET sql_strg = "DROP TRIGGER '", 
					l_a.owner clipped, 
					"'.", 
					l_a.trigname clipped, 
					";" 
					CALL build_sql("END", sql_strg, ";") 
					-- ... AND recreate it in o_'s image...
					CALL create_trigger(l_o.trigid, l_o.trigname) 
					EXIT FOREACH 
				END IF 
			END FOREACH 
			FREE subtle_curs 
		END IF 
	END FOREACH 
	FREE more_drop_trigs 
	-- Finally: Any triggers in o_systriggers that aren't in systriggers
	--          need TO be created...
	CALL put_log("Creating missing TRIGGERs") 
	DECLARE fin_curs CURSOR FOR 
	SELECT trigid, 
	trigname 
	FROM o_systriggers 
	WHERE NOT exists( 
	SELECT trigname, owner 
	FROM systriggers 
	WHERE systriggers.trigname = o_systriggers.trigname 
	AND systriggers.owner = o_systriggers.owner) 
	FOREACH fin_curs INTO l_o.trigid, 
		l_o.trigname 
		CALL create_trigger(l_o.trigid, l_o.trigname) 
	END FOREACH 
	FREE fin_curs 
END FUNCTION 


###################################################################
# FUNCTION create_trigger(l_trigid, l_trigname)
#
#
###################################################################
FUNCTION create_trigger(l_trigid, l_trigname) 
	DEFINE l_trigid int 
	DEFINE l_trigname CHAR(18) 
	DEFINE sql_strg CHAR(8000) 
	DEFINE l_data CHAR(8000) 
	DEFINE l_indata CHAR(256) 
	DEFINE i SMALLINT 
	DEFINE j SMALLINT 
	DEFINE l_lth SMALLINT 
	DEFINE l_ascii_lf CHAR(1) 

	DECLARE build_trig_curs CURSOR FOR 
	SELECT data, 
	datakey, 
	seqno 
	FROM o_systrigbody 
	WHERE trigid = l_trigid 
	AND datakey in("A", "D") # added BY mf 
	ORDER BY datakey desc, # so CREATE part comes FIRST 
	seqno 
	LET l_lth = 0 
	LET l_data = "" 
	LET l_ascii_lf = ascii(10) 
	LET sql_strg = "" 
	FOREACH build_trig_curs INTO l_indata 
		LET l_data[l_lth + 1, 4096] = l_indata 
		LET l_lth = length(l_data) 
		WHILE l_lth > 0 
			FOR i = 1 TO l_lth 
				IF l_data[i] = l_ascii_lf THEN 
					IF i > 1 THEN 
						LET sql_strg = l_data[1, i -1] 
						CALL fold_and_push(sql_strg, 0) 
					END IF 
					IF i != l_lth THEN 
						LET l_data = l_data[i + 1, l_lth] 
					END IF 
					LET l_lth = l_lth - i 
					EXIT FOR 
				END IF 
			END FOR 
			IF i > l_lth THEN # can't find an END OF line 
				EXIT WHILE # so get another chunk OF trigger definition 
			END IF 
		END WHILE 
	END FOREACH 
	LET sql_strg = l_data 
	CALL fold_and_push(sql_strg, 1) 
	FREE build_trig_curs 
END FUNCTION 


###################################################################
# FUNCTION check_spl()
#
# Change Stored Procedures (Kerry Sainsbury)
# Compare contents of sysprocbody AND o_sysprocbody
#    drop old OR different.  Add new OR different
###################################################################
FUNCTION check_spl() 
	DEFINE sql_strg CHAR(80) 
	DEFINE l_ocnt INTEGER 
	DEFINE l_odata CHAR(256) 
	DEFINE l_oprocname CHAR(18) 
	DEFINE l_oprocid INTEGER 
	DEFINE l_acnt INTEGER 
	DEFINE l_adata CHAR(256) 
	DEFINE l_aprocname CHAR(18) 
	DEFINE l_aprocid INTEGER 
	DEFINE l_aowner CHAR(8) 
	-- Drop all spls that are NOT in o_systriggers...
	DECLARE drop_spls CURSOR FOR 
	SELECT procname, 
	owner 
	FROM sysprocedures 
	WHERE NOT exists( 
	SELECT procname 
	FROM o_sysprocedures 
	WHERE o_sysprocedures.procname = sysprocedures.procname 
	AND o_sysprocedures.owner = sysprocedures.owner) 
	CALL put_log("Generating DROP PROCEDUREs") 
	FOREACH drop_spls INTO l_aprocname, 
		l_aowner 
		LET sql_strg = "DROP PROCEDURE '", 
		l_aowner clipped, 
		"'.", 
		l_aprocname clipped, 
		";" 
		CALL build_sql("END", sql_strg, ";") 
	END FOREACH 
	FREE drop_spls 
	-- Now build a list of all procedures that're in both databases...
	-- with the same procedure name AND owner
	DECLARE more_drop_spls CURSOR FOR 
	SELECT o.procid, 
	o.procname, 
	a.procid, 
	a.procname, 
	a.owner 
	FROM o_sysprocedures o, 
	sysprocedures a 
	WHERE o.procname = a.procname 
	AND o.owner = a.owner 
	FOREACH more_drop_spls INTO l_oprocid, 
		l_oprocname, 
		l_aprocid, 
		l_aprocname, 
		l_aowner 
		-- Do a crass check TO see IF the stored procedures are different
		-- (based on the number of lines in each procedure)...
		LET l_ocnt = 0 
		LET l_acnt = 0 
		SELECT count(*)INTO l_ocnt 
		FROM o_sysprocbody 
		WHERE procid = l_oprocid 
		SELECT count(*)INTO l_acnt 
		FROM sysprocbody 
		WHERE procid = l_aprocid 
		AND datakey = "T" 
		IF l_ocnt != l_acnt THEN 
			LET sql_strg = "DROP PROCEDURE '", 
			l_aowner clipped, 
			"'.", 
			l_aprocname clipped, 
			";" 
			CALL build_sql("END", sql_strg, ";") 
			CALL create_procedure(l_oprocid, l_oprocname) 
		ELSE 
			-- Now check FOR a subtle change (line count stays the same, but content
			-- differs)
			DECLARE subtle_splcurs CURSOR FOR 
			SELECT o.data, 
			a.data, 
			o.seqno 
			FROM o_sysprocbody o, 
			sysprocbody a 
			WHERE a.procid = l_aprocid 
			AND o.procid = l_oprocid 
			AND a.seqno = o.seqno 
			AND a.datakey = "T" 
			ORDER BY o.seqno 
			FOREACH subtle_splcurs INTO l_odata, 
				l_adata 
				IF l_odata != l_adata THEN 
					LET sql_strg = "DROP PROCEDURE '", 
					l_aowner clipped, 
					"'.", 
					l_aprocname clipped, 
					";" 
					CALL build_sql("END", sql_strg, ";") 
					CALL create_procedure(l_oprocid, l_oprocname) 
					EXIT FOREACH 
				END IF 
			END FOREACH 
			FREE subtle_splcurs 
		END IF 
	END FOREACH 
	FREE more_drop_spls 
	-- Finally: Any procedures in o_sysprocedures that aren't in sysprocedures
	--          need TO be created...
	CALL put_log("Creating missing PROCEDUREs") 
	DECLARE sfin_curs CURSOR FOR 
	SELECT procid, 
	procname 
	FROM o_sysprocedures 
	WHERE NOT exists( 
	SELECT procname, owner 
	FROM sysprocedures 
	WHERE sysprocedures.procname = o_sysprocedures.procname 
	AND sysprocedures.owner = o_sysprocedures.owner) 
	FOREACH sfin_curs INTO l_oprocid, 
		l_oprocname 
		CALL create_procedure(l_oprocid, l_oprocname) 
	END FOREACH 
	FREE sfin_curs 
END FUNCTION 



###################################################################
# FUNCTION create_procedure(l_procid, l_procname)
#
#
###################################################################
FUNCTION create_procedure(l_procid, l_procname) 
	DEFINE l_procid int 
	DEFINE l_procname CHAR(18) 
	DEFINE sql_strg CHAR(1024) 
	DEFINE l_data CHAR(4096) 
	DEFINE l_indata CHAR(256) 
	DEFINE i INTEGER 
	DEFINE j INTEGER 
	DEFINE l_lth INTEGER 
	DEFINE l_ascii_lf CHAR(1) 
	DEFINE junk SMALLINT 

	LET l_ascii_lf = ascii(10) # informix bug alert!! 
	DECLARE build_spl_curs CURSOR FOR 
	SELECT data, 
	seqno 
	FROM o_sysprocbody 
	WHERE procid = l_procid 
	ORDER BY seqno 
	OUTPUT TO REPORT sql_script("") 
	LET sql_strg = "" 
	# stick line together AND flush TO REPORT all in one fell swoop
	# IF we try TO pass a CR TO fold_and_push we get a dropped core.
	FOREACH build_spl_curs INTO l_indata, 
		junk 
		LET l_data[l_lth + 1, 4096] = l_indata 
		LET l_lth = length(l_data) 
		FOR i = 1 TO l_lth 
			IF l_data[i, i] = l_ascii_lf THEN #<<<----- what about msdos? 
				IF i > 1 THEN # has data 
					LET sql_strg = l_data[1, i -1] # = line - cr 
					CALL fold_and_push(sql_strg, 0) # FLUSH the line 
				ELSE # SKIP over single cr 
					LET l_data = l_data[i + 1, l_lth] # lose the cr 
					LET i = 0 # START FOR over 
					LET l_lth = length(l_data) # reset length 
					# All I want IS TO duplicate that CR we dropped.
					# But every time I try I drop core.
					#               OUTPUT TO REPORT dump_SQL("")
					CONTINUE FOR 
				END IF # flushing the line 
				IF i != l_lth THEN 
					LET l_data = l_data[i + 1, l_lth] 
					LET i = 0 # START FOR over 
					LET l_lth = length(l_data) # reset length 
				END IF # resetting AFTER cr 
			END IF # found a cr 
		END FOR # scanning the STRING 
		# Kerry code. drops core on my box.
		#      LET l_data[l_lth+1,4096]=l_indata
		#      LET l_lth = LENGTH(l_data)
		#      WHILE l_lth > 0
		#         FOR i = 1 TO l_lth
		#            IF l_data[i] = l_ascii_lf THEN   #<<<----- What about MSDOS?
		#               IF i > 1 THEN
		#                  LET sql_strg = l_data[1,i-1]
		#                  CALL fold_and_push(sql_strg,0)
		#               END IF
		#               IF i != l_lth THEN
		#                  LET l_data = l_data[i+1, l_lth]
		#               END IF
		#               LET l_lth = l_lth - i
		#               EXIT FOR
		#            END IF
		#         END FOR
		#         IF i > l_lth THEN  # Can't find an END of line
		#            EXIT WHILE      # so get another chunk of procedure definition
		#         END IF
		#      END WHILE
	END FOREACH 
	LET sql_strg = l_data 
	CALL fold_and_push(sql_strg, 1) 
	FREE build_spl_curs 
END FUNCTION 


######################### Generic functions ##############################


###################################################################
# FUNCTION col_cnvrt(coltype, collength)
#
# Convert coltype/length INTO an SQL descriptor string
###################################################################
FUNCTION col_cnvrt(coltype, collength) 
	DEFINE coltype SMALLINT 
	DEFINE collength SMALLINT 
	DEFINE nonull SMALLINT 
	DEFINE sql_strg CHAR(40) 
	DEFINE tmp_strg CHAR(4) 

	LET coltype = coltype + 1 # datatype[idx] IS offset BY one 
	LET nonull = coltype / 256 # IF > 256 THEN IS no nulls 
		LET coltype = coltype mod 256 # lose the no nulls determinator 
		LET sql_strg = datatype[coltype] 
		CASE coltype 
			WHEN 1 # CHAR 
				LET tmp_strg = collength USING "<<<<" 
				LET sql_strg = sql_strg clipped, 
				" (", 
				tmp_strg clipped, 
				")" 
				# SQL syntax supports float(n) - Informix ignores this
				#      WHEN 4       # float
				#         LET SQL_strg = SQL_strg clipped, " (", ")"
			WHEN 6 # DECIMAL 
				LET sql_strg = sql_strg clipped, 
				" (", 
				fix_nm(collength, 0) clipped, 
				")" 
				# Syntax supports serial(starting_no) - starting_no IS unavaliable
				#      WHEN 7       # serial
				#         LET SQL_strg = SQL_strg clipped, " (", ")"
			WHEN 9 # MONEY 
				LET sql_strg = sql_strg clipped, 
				" (", 
				fix_nm(collength, 0) clipped, 
				")" 
			WHEN 11 # DATETIME 
				LET sql_strg = sql_strg clipped, 
				" ", 
				fix_dt(collength) clipped 
			WHEN 14 # VARCHAR 
				LET sql_strg = sql_strg clipped, 
				" (", 
				fix_nm(collength, 1) clipped, 
				")" 
			WHEN 15 # INTERVAL 
				LET sql_strg = sql_strg clipped, 
				" ", 
				fix_dt(collength) clipped 
		END CASE 
		IF nonull THEN 
			LET sql_strg = sql_strg clipped, 
			" NOT NULL" 
		END IF 
		RETURN sql_strg 
END FUNCTION 


###################################################################
# FUNCTION fix_nm(num, tp)
#
# Turn collength INTO two numbers - RETURN as string
###################################################################
FUNCTION fix_nm(num, tp) 
	DEFINE num INTEGER 
	DEFINE tp SMALLINT 
	DEFINE strg CHAR(8) 
	DEFINE i SMALLINT 
	DEFINE j SMALLINT 
	DEFINE strg1 CHAR(3) 
	DEFINE strg2 CHAR(3) 

	LET i = num / 256 
	LET j = num mod 256 
	LET strg1 = i USING "<<&" 
	LET strg2 = j USING "<<&" 
	IF tp = 0 THEN 
		IF j > i THEN 
			LET strg = strg1 clipped 
		ELSE 
			LET strg = strg1 clipped, 
			", ", 
			strg2 clipped 
		END IF 
	ELSE # VARCHAR IS just the opposite 
		IF i = 0 THEN 
			LET strg = strg2 clipped 
		ELSE 
			LET strg = strg2 clipped, 
			", ", 
			strg1 clipped 
		END IF 
	END IF 
	RETURN strg 
END FUNCTION 




###################################################################
# FUNCTION fix_dt(num)
#
# Turn collength INTO meaningful date info - RETURN as string
###################################################################
FUNCTION fix_dt(num) 
	DEFINE num INTEGER 
	DEFINE i SMALLINT 
	DEFINE j SMALLINT 
	DEFINE k SMALLINT 
	DEFINE len SMALLINT 
	DEFINE strg CHAR(30) 

	LET i = (num mod 16) + 1 # offset again 
	LET j = ((num mod 256) / 16) + 1 # offset again 
	LET k = num / 256 # length OF value 
	# IF this IS an interval THEN life gets interesting, 'k' IS the length of
	# the entire string.  So a YEAR TO DAY IS YYYYMMDD OR 8.  A DAY(3) TO
	# MINUTE IS DDDHHMM OR 7.  We don't know how long the first one IS, but
	# we can work it out by computing the 'should be length' of the string
	# AND THEN adding/subtracting the result FROM the 'should be length' of
	# the major element.
	#
	# Keep in mind --->    YYYYMMDDHHMMSSFFFFF
	#     vs.         j =    1  2 3 4 5 678901
	#
	# I was just working an algorithm TO do this, 4 notepads, 90 minutes, AND 50
	# lines INTO it I realized that I was creating something impossible TO test
	# OR maintain.  Therefore I am opting FOR something a lot simpler.
	#
	# In the GLOBALS I have created an ARRAY of RECORD with start AND END points
	# FOR the major AND minor pieces.  By subtracting the START point of the
	# major element FROM the END point of the minor element I get the 'should be
	# length'
	#
	LET len = intvray[i].end_point - intvray[j].start_point 
	# len should match k. e.g.:
	#    DAY(5) TO MINUTE  ==> k = 9, len = 6
	#    YEAR(6) TO HOUR   ==> k = 12, len = 14
	LET len = k - len # add len TO the major 
	IF len = 0 
	OR j > 11 THEN # IS the default 
		# 12 on have the precision alrdy coded
		LET strg = datetype[j] clipped, 
		" TO ", 
		datetype[i] clipped 
	ELSE # isn't the default 
		# uh-oh, how long IS the default major?
		LET k = intvray[j].end_point - intvray[j].start_point 
		# add in the extra
		LET k = k + len 
		LET strg = datetype[j] clipped, 
		"(", 
		k USING "<<", 
		")", 
		" TO ", 
		datetype[i] clipped 
	END IF 
	RETURN strg 
END FUNCTION 



###################################################################
# FUNCTION proc_arg()
#
# process user args <-- kept FOR future use - needs work
###################################################################
FUNCTION proc_arg() 
	DEFINE opt_ind SMALLINT 
	DEFINE curr_opt CHAR(20) 

	LET gr_params.db_name = "dbname-fixme" 
	LET gr_params.tb_name = "*" 
	LET gr_params.snapshot_dir = fgl_getenv("TMP") 
	IF gr_params.snapshot_dir IS NULL THEN # try nt 
		LET gr_params.snapshot_dir = fgl_getenv("TEMP") 
	END IF 
	IF gr_params.snapshot_dir IS NULL THEN # try informix 
		LET gr_params.snapshot_dir = fgl_getenv("DBTEMP") 
	END IF 
	IF gr_params.snapshot_dir IS NULL THEN # use pwd 
		LET gr_params.snapshot_dir = "." 
	END IF 
	LET gr_params.sql_filename = gr_params.snapshot_dir clipped, 
	"/U19.sql" 
	LET gr_params.online_sw = "Y" 
	LET gr_params.auth_sw = "N" # CHECK TABLE permissions 
	LET gr_params.user_sw = "N" # CHECK users 
	LET gr_params.const_sw = "N" # CHECK CONSTRAINTS 
	LET gr_params.spl_sw = "N" # CHECK spls 
	LET gr_params.trig_sw = "N" 
	LET errusage = 0 
	LET quiet_sw = 0 
	LET opt_ind = 0 
	WHILE (opt_ind <= num_args()) 
		LET opt_ind = opt_ind + 1 
		LET curr_opt = upshift(arg_val(opt_ind)) 
		CASE curr_opt 
			WHEN "-DB" 
				LET opt_ind = opt_ind + 1 
				LET curr_opt = upshift(arg_val(opt_ind)) 
				IF curr_opt = "SE" THEN 
					LET gr_params.online_sw = "N" 
					LET msg = "SE mode selected" 
				ELSE 
					LET msg = "Online mode selected" 
				END IF 
				CALL put_log(msg) 
			WHEN "-OD" 
				LET opt_ind = opt_ind + 1 
				LET gr_params.db_name = arg_val(opt_ind) 
				LET msg = "Old database: ", 
				gr_params.db_name 
				CALL put_log(msg) 
			WHEN "-ND" 
				LET opt_ind = opt_ind + 1 
				LET gr_params.db_name = arg_val(opt_ind) 
				LET msg = "New database: ", 
				gr_params.db_name 
				CALL put_log(msg) 
			WHEN "-C" 
				LET gr_params.const_sw = "N" 
				LET msg = "Constraints off. " 
				CALL put_log(msg) 
			WHEN "-O" 
				LET opt_ind = opt_ind + 1 
				LET gr_params.sql_filename = arg_val(opt_ind) 
				LET msg = "OUTPUT file: ", 
				gr_params.sql_filename clipped 
				CALL put_log(msg) 
			WHEN "-A" 
				LET gr_params.auth_sw = "Y" 
				LET msg = "Authority mode turned on" 
				CALL put_log(msg) 
			WHEN "-U" 
				LET gr_params.user_sw = "N" 
				LET msg = "User mode turned off" 
				CALL put_log(msg) 
			WHEN "-SPL" 
				LET gr_params.spl_sw = "N" 
				LET msg = "Stored Procedures mode turned off" 
				CALL put_log(msg) 
			WHEN "-TRG" 
				LET gr_params.trig_sw = "Y" 
				LET msg = "Triggers mode turned on" 
				CALL put_log(msg) 
			WHEN "-Q" 
				LET quiet_sw = 1 
				LET msg = "Quiet mode turned on" 
				CALL put_log(msg) 
			WHEN "-SVR" 
				LET opt_ind = opt_ind + 1 
				LET serverfle = arg_val(opt_ind) 
				LET msg = "Server file name : ", 
				serverfle clipped 
				CALL put_log(msg) 
			WHEN "-T" 
				LET opt_ind = opt_ind + 1 
				LET gr_params.tb_name = arg_val(opt_ind) 
				LET msg = "Table name : ", 
				gr_params.tb_name clipped 
				CALL put_log(msg) 
			WHEN "-ALL" 
				LET gr_params.const_sw = "Y" 
				LET gr_params.auth_sw = "Y" 
				LET gr_params.user_sw = "Y" 
				LET gr_params.spl_sw = "Y" 
				LET gr_params.trig_sw = "Y" 
			OTHERWISE 
				IF length(curr_opt) > 0 THEN 
					LET errusage = 1 
					EXIT WHILE 
				END IF 
		END CASE 
	END WHILE 
	IF NOT errusage THEN 
		RETURN 
	END IF 
	DISPLAY 'usage:' 
	DISPLAY 'dbutil [-db se|ol] engine type - se OR online (def: ol)' 
	DISPLAY ' [-od] old DATABASE NAME ' 
	DISPLAY ' [-nd] new DATABASE NAME ' 
	DISPLAY ' [-s1] only do segment 1' 
	DISPLAY ' [-s2] only do segment 2' 
	DISPLAY ' [-o] OUTPUT file NAME (def: /tmp/mod_db.sql)' 
	DISPLAY ' [-a] authority tables (permissions)' 
	DISPLAY ' [-c] constraints' 
	DISPLAY ' [-u] users' 
	DISPLAY ' [-spl] stored procedures' 
	DISPLAY ' [-trg] triggers' 
	DISPLAY ' [-t] TABLE NAME specification ' 
	DISPLAY ' [-q] quiet MODE - no interaction ' 
	EXIT program 0 
END FUNCTION 


###################################################################
# FUNCTION db_check(dbname)
#
# # ensure we can OPEN database
###################################################################
FUNCTION db_check(dbname) 
	DEFINE dbname CHAR(64) 
	DEFINE err SMALLINT 

	LET err = 0 
	IF length(dbname) = 0 THEN 
		LET msg = "Must specify database" 
		CALL put_log(msg) 
		LET err = 1 
	END IF 

	WHENEVER ERROR CONTINUE 
	DATABASE dbname 
	IF status != 0 THEN 
		LET msg = "Can't OPEN:", 
		dbname clipped, 
		" Status: ", 
		status 
		CALL put_log(msg) 
		LET err = 1 
	ELSE 
		IF gr_params.online_sw = "Y" THEN 
			SET ISOLATION TO dirty read 
			IF status THEN 
				LET gr_params.online_sw = "N" 
				LET msg = "RESETTING TO SE !", 
				dbname clipped 
				CALL put_log(msg) 
			END IF 
		END IF 
	END IF 
	#close database
	RETURN err 
END FUNCTION 



###################################################################
# FUNCTION init_params()
#
# misc housekeeping - init stuff.
###################################################################
FUNCTION init_params() 
	DEFINE i SMALLINT 
	DEFINE lne CHAR(129) 
	DEFINE retcode INTEGER 

	SELECT user, sitename 
	INTO gr_params.user_name, gr_params.site_name 
	FROM systables WHERE tabid = 1 
	LET datatype[1] = "CHAR" 
	LET datatype[2] = "SMALLINT" 
	LET datatype[3] = "INTEGER" 
	LET datatype[4] = "FLOAT" 
	LET datatype[5] = "SMALLFLOAT" 
	LET datatype[6] = "DECIMAL" 
	LET datatype[7] = "SERIAL" 
	LET datatype[8] = "DATE" 
	LET datatype[9] = "MONEY" 
	LET datatype[10] = "UNKNOWN" 
	LET datatype[11] = "DATETIME" 
	LET datatype[12] = "BYTE" 
	LET datatype[13] = "TEXT" 
	LET datatype[14] = "VARCHAR" 
	LET datatype[15] = "INTERVAL" 
	LET datatype[16] = "UNKNOWN" # little room FOR growth 
	LET datatype[17] = "UNKNOWN" 
	LET datatype[18] = "UNKNOWN" 
	LET datatype[19] = "UNKNOWN" 
	LET datatype[20] = "UNKNOWN" 
	LET datetype[1] = "YEAR" 
	LET intvray[1].start_point = 1 
	LET intvray[1].end_point = 5 # offset BY one FOR easy math 
	LET datetype[3] = "MONTH" 
	LET intvray[3].start_point = 5 
	LET intvray[3].end_point = 7 
	LET datetype[5] = "DAY" 
	LET intvray[5].start_point = 7 
	LET intvray[5].end_point = 9 
	LET datetype[7] = "HOUR" 
	LET intvray[7].start_point = 9 
	LET intvray[7].end_point = 11 
	LET datetype[9] = "MINUTE" 
	LET intvray[9].start_point = 11 
	LET intvray[9].end_point = 13 
	LET datetype[11] = "SECOND" 
	LET intvray[11].start_point = 13 
	LET intvray[11].end_point = 15 
	LET datetype[12] = "FRACTION(1)" 
	LET intvray[12].start_point = 15 
	LET intvray[12].end_point = 16 
	LET datetype[13] = "FRACTION(2)" 
	LET intvray[13].start_point = 16 
	LET intvray[13].end_point = 17 
	LET datetype[14] = "FRACTION(3)" 
	LET intvray[14].start_point = 17 
	LET intvray[14].end_point = 18 
	LET datetype[15] = "FRACTION(4)" 
	LET intvray[15].start_point = 18 
	LET intvray[15].end_point = 19 
	LET datetype[16] = "FRACTION(5)" 
	LET intvray[16].start_point = 19 
	LET intvray[16].end_point = 20 
	CALL proc_arg() 
	# load file of server swaps
	FOR max_servers = 1 TO 20 
		INITIALIZE servers[max_servers].* TO NULL 
	END FOR 
	LET max_servers = 20 # number OF ARRAY elements 
	LET write_srv = 0 
END FUNCTION 


###################################################################
# REPORT sql_script(sql_line)
#
# Easy way TO dump TO file
###################################################################
REPORT sql_script(sql_line) 
	DEFINE sql_line CHAR(80) 

	OUTPUT 
	left margin 0 
	right margin 80 
	top margin 0 
	bottom margin 0 
	PAGE length 1 # no blank LINES please 

	FORMAT 
		ON EVERY ROW 
			PRINT sql_line clipped 
END REPORT 


###################################################################
# FUNCTION build_sql(line_text, start_text, end_text)
#
# A FUNCTION TO handle commas AND start/END pieces
# in a multi-line SQL command, WHERE:
#   line_text = string TO put INTO statement
#   start_text = starting syntax e.g. "ALTER TABLE "
#   end_text = ending stuff TO tack on TO each line e.g. ","
# IF line_text = "END" THEN this IS the last time we'll be here
# FOR this command.
###################################################################
FUNCTION build_sql(line_text, start_text, end_text) 
	DEFINE line_text CHAR(80) 
	DEFINE start_text CHAR(80) 
	DEFINE end_text CHAR(80) 

	IF line_text = "END" THEN 
		IF sql_idx = 1 THEN 
			LET sql_saved_line = start_text, 
			end_text clipped 
		ELSE 
			LET sql_saved_line = sql_saved_line clipped, 
			end_text clipped 
		END IF 
		OUTPUT TO REPORT sql_script(sql_saved_line) 
		OUTPUT TO REPORT sql_script("") # blank line 
		LET sql_saved_line = NULL 
		LET sql_idx = 1 
	ELSE 
		IF sql_idx = 1 THEN # this IS the FIRST time 
			LET sql_saved_line = start_text 
		ELSE 
			LET sql_saved_line = sql_saved_line clipped, 
			end_text 
		END IF 
		OUTPUT TO REPORT sql_script(sql_saved_line) 
		LET sql_saved_line = " ", # indented 
		line_text 
		LET sql_idx = sql_idx + 1 
	END IF 
END FUNCTION 



###################################################################
# FUNCTION clip_strg(strg)
#
# the last word in string may be truncated - so cut off everything up TO
# that last word AND RETURN it, also RETURN the remainder.
###################################################################
FUNCTION clip_strg(strg) 
	DEFINE strg CHAR(80) 
	DEFINE rmdr CHAR(80) 
	DEFINE i SMALLINT 
	DEFINE j SMALLINT 
	DEFINE k SMALLINT 

	LET j = length(strg) 
	IF j > 60 THEN 
		FOR i = j TO 1 step -1 
			# need TO look FOR space OR comma,
			IF strg[i, i] = " " 
			OR strg[i, i] = "," THEN 
				EXIT FOR 
			END IF 
		END FOR 
		IF i = j THEN 
			LET rmdr = "" 
		ELSE 
			LET k = i + 1 
			LET rmdr = strg[k, j] 
			LET strg = strg[1, i] 
		END IF 
	ELSE 
		LET rmdr = "" 
	END IF 
	RETURN strg, 
	rmdr 
END FUNCTION 


###################################################################
# FUNCTION open_log(txt)
#
#
###################################################################
FUNCTION open_log(txt) 
	DEFINE txt CHAR(80) 

	OPEN WINDOW w_log with FORM "U999" attributes(BORDER) 
	CALL windecoration_u("U999") 

	CALL put_log(txt) 
	SLEEP 2 
END FUNCTION 


FUNCTION put_log(txt) 
	DEFINE 
	txt CHAR(80) 

	DISPLAY "" TO lbinfo1 
	DISPLAY "" TO lbinfo2 # reset progress DISPLAY 
	DISPLAY txt clipped TO lbinfo1 
	IF log_sql_sw THEN 
		      LET txt = "{ ",
		                txt clipped,
		                " }"
		OUTPUT TO REPORT sql_script(txt) 
		OUTPUT TO REPORT sql_script("") # add a blank line 
	END IF 
END FUNCTION 


FUNCTION put_progress(txt) 
	DEFINE 
	txt CHAR(80) 

	DISPLAY "" at 2,1 
	DISPLAY txt clipped TO lbinfo2 
END FUNCTION 


FUNCTION close_log(txt) 
	DEFINE 
	txt CHAR(80) 

	CALL put_log(txt) 
	SLEEP 2 
	CLOSE WINDOW w_log 
END FUNCTION 


FUNCTION get_server(old_server, tabname) 
	# Try TO resolve old synonym server vs desired server.
	DEFINE 
	old_server, 
	tabname CHAR(20), 
	i SMALLINT 

	FOR i = 1 TO max_servers 
		# already matched?
		IF old_server = servers[i].old_server THEN 
			EXIT FOR 
		END IF 
		# new match
		IF length(servers[i].old_server) = 0 THEN 
			LET servers[i].old_server = old_server 
			CALL accpt_server(servers[i].old_server, tabname) 
			RETURNING servers[i].new_server 
			EXIT FOR 
		END IF 
		IF i = 20 THEN 
			CALL put_log("Server ARRAY overflow") 
			RETURN old_server 
		END IF 
	END FOR 
	RETURN servers[i].new_server 
END FUNCTION 


FUNCTION accpt_server(serv_name, tabname) 
	# can't resolve it, ask...
	DEFINE 
	serv_name, 
	tabname CHAR(20) 
	IF NOT quiet_sw THEN 
		OPEN WINDOW w_serv with FORM "server" 
		CALL winDecoration_u("server") 

		DISPLAY tabname TO formonly.tabname 
		INPUT serv_name WITHOUT DEFAULTS 
		FROM formonly.serv_name 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","U19","input-serv_name") 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 


		END INPUT 

		CLOSE WINDOW w_serv 
		LET write_srv = 1 
		RETURN serv_name 
	END IF 
END FUNCTION 


FUNCTION fold_and_push(stmt, brk) 
	#        -------------
	# Reformat an extra-long sql statement AND push it out TO the file.
	# Looks FOR imbedded LF AND uses these, ELSE finds a space, comma OR
	# right bracket nearest COLUMN 80 AND splits AFTER it.
	# brk IS a switch TO indicate give OR NOT give a blank line AFTER end,
	# OR whether statement IS a continuation of previous call.
	# This routine may also break a quoted string which IS undesirable at
	# times - Need TO fix this!

	DEFINE 
	stmt, 
	stmt2 CHAR(8000), 
	x CHAR(1), 
	brk, 
	i, 
	j, 
	k, 
	l SMALLINT 

	LET k = length(stmt) 
	WHILE k > 80 # only IF longer than one line 
		LET l = 0 # means we haven't found a place TO break line 
		FOR i = 1 TO k # search forwards FOR best places TO break 
			LET x = stmt[i, i] 
			IF x = "," 
			OR x = ")" 
			OR x = "]" 
			OR x <= " " THEN 
				LET l = i # remember WHERE we found it 
			END IF 
			IF (l > 0 AND i >= 80) # make line as long as possible 
			OR x < " " THEN # lf OR other ctrl character 
				LET i = l 
				EXIT FOR 
			END IF 
		END FOR 
		LET j = i + 1 # START OF NEXT part 
		IF x < " " THEN # ignore ctrl characters 
			LET i = i - 1 
		END IF 
		IF i > 0 THEN 
			LET stmt2 = stmt[1, i] # grab FIRST part... 
		ELSE 
			LET stmt2 = "" 
		END IF 
		OUTPUT TO REPORT sql_script(stmt2) # AND write it 
		IF j <= k THEN 
			LET stmt = stmt[j, k] # grab remaining STRING 
		ELSE 
			LET stmt = "" 
		END IF 
		LET k = length(stmt) 
	END WHILE 
	IF k > 0 THEN # anything left over? 
		OUTPUT TO REPORT sql_script(stmt) 
	END IF 
	IF brk > 0 THEN 
		OUTPUT TO REPORT sql_script("") # add a blank line 
	END IF 
END FUNCTION 


FUNCTION idx_parts(p_idxname, old_new) 
	#        ---------
	# This routine reads the parts[] structure FROM a sysindexes table
	# AND builds a COLUMN list.
	# It IS called FOR indices AND constraints.  Since constraints don't
	# use the 'DESC' verb the parts structure should never have a negative value
	# so don't worry about it.
	#
	DEFINE 
	p_idxname CHAR(18), 
	p_tabname CHAR(18), 
	idxrec RECORD 
		tabid INTEGER, 
		tabname CHAR(18), 
		idxtype CHAR(1), 
		clustered CHAR(1) 
	END RECORD, 
	parts ARRAY [16] OF SMALLINT, 
	i SMALLINT, 
	p_colname CHAR(24), 
	desc_sw SMALLINT, 
	strg, 
	tmp_strg CHAR(80), 
	idx_strng CHAR(500), 
	old_new SMALLINT 

	IF old_new = 0 THEN # old 
		IF gr_params.online_sw = "Y" THEN 
			SELECT o_systables.tabid, 
			o_systables.tabname, 
			idxtype, 
			clustered, 
			part1, 
			part2, 
			part3, 
			part4, 
			part5, 
			part6, 
			part7, 
			part8, 
			part9, 
			part10, 
			part11, 
			part12, 
			part13, 
			part14, 
			part15, 
			part16 INTO idxrec.*, 
			parts[1], 
			parts[2], 
			parts[3], 
			parts[4], 
			parts[5], 
			parts[6], 
			parts[7], 
			parts[8], 
			parts[9], 
			parts[10], 
			parts[11], 
			parts[12], 
			parts[13], 
			parts[14], 
			parts[15], 
			parts[16] 
			FROM o_sysindexes, 
			o_systables 
			WHERE idxname = p_idxname 
			AND o_sysindexes.tabid = o_systables.tabid 
		ELSE 
			SELECT o_systables.tabid, 
			o_systables.tabname, 
			idxtype, 
			clustered, 
			part1, 
			part2, 
			part3, 
			part4, 
			part5, 
			part6, 
			part7, 
			part8 INTO idxrec.*, 
			parts[1], 
			parts[2], 
			parts[3], 
			parts[4], 
			parts[5], 
			parts[6], 
			parts[7], 
			parts[8] 
			FROM o_sysindexes, 
			o_systables 
			WHERE idxname = p_idxname 
			AND o_sysindexes.tabid = o_systables.tabid 
		END IF 
	ELSE # new 
		IF gr_params.online_sw = "Y" THEN 
			SELECT systables.tabid, 
			systables.tabname, 
			idxtype, 
			clustered, 
			part1, 
			part2, 
			part3, 
			part4, 
			part5, 
			part6, 
			part7, 
			part8, 
			part9, 
			part10, 
			part11, 
			part12, 
			part13, 
			part14, 
			part15, 
			part16 INTO idxrec.*, 
			parts[1], 
			parts[2], 
			parts[3], 
			parts[4], 
			parts[5], 
			parts[6], 
			parts[7], 
			parts[8], 
			parts[9], 
			parts[10], 
			parts[11], 
			parts[12], 
			parts[13], 
			parts[14], 
			parts[15], 
			parts[16] 
			FROM sysindexes, 
			systables 
			WHERE idxname = p_idxname 
			AND sysindexes.tabid = systables.tabid 
		ELSE 
			SELECT systables.tabid, 
			systables.tabname, 
			idxtype, 
			clustered, 
			part1, 
			part2, 
			part3, 
			part4, 
			part5, 
			part6, 
			part7, 
			part8 INTO idxrec.*, 
			parts[1], 
			parts[2], 
			parts[3], 
			parts[4], 
			parts[5], 
			parts[6], 
			parts[7], 
			parts[8] 
			FROM sysindexes, 
			systables 
			WHERE idxname = p_idxname 
			AND sysindexes.tabid = systables.tabid 
		END IF 
	END IF 
	LET idx_strng = "" 
	# add columns
	FOR i = 1 TO max_parts 
		LET desc_sw = 0 # switch FOR descending sort 
		IF parts[i] = 0 THEN 
			EXIT FOR 
		ELSE 
			IF parts[i] < 0 THEN # negative indicates a desc 
				LET desc_sw = 1 
				LET parts[i] = 0 - parts[i] # reset TO get col 
			END IF 
		END IF 
		IF old_new = 0 THEN # old 
			SELECT colname INTO p_colname 
			FROM o_syscols 
			WHERE tabid = idxrec.tabid 
			AND colno = parts[i] 
		ELSE 
			SELECT colname INTO p_colname 
			FROM syscolumns 
			WHERE tabid = idxrec.tabid 
			AND colno = parts[i] 
		END IF 
		IF desc_sw THEN # CHECK FOR descending AND fix 
			LET p_colname = p_colname clipped, 
			" DESC" 
		END IF 
		LET idx_strng = idx_strng clipped, 
		" ", 
		p_colname clipped, 
		"," 
	END FOR 
	LET i = length(idx_strng) - 1 
	IF i > 0 THEN # remove LAST comma 
		LET idx_strng = idx_strng[1, i] 
	END IF 
	RETURN idx_strng 
END FUNCTION 


FUNCTION translate(f_old_sub, f_new_sub, f_old_txt) 
	#  p_al012.4gl:  Search AND replace FUNCTION
	#
	#  Searches through a text string (f_old_txt) FOR occurrences of
	#  a substring (f_old_sub). Each occurrence IS replaced with the
	#  new substring (f_new_sub).
	#
	#  Things TO be wary of WHEN you use this FUNCTION:
	#  1. spaces are clipped FROM the right of both substrings before
	#     any processing IS done.
	#  2. IF the "replace with" substring IS longer than the "find"
	#     substring there IS a possibility the result will come back
	#     truncated.

	DEFINE 
	f_old_txt CHAR(512), 
	f_old_sub CHAR(128), 
	f_new_sub CHAR(128) 

	DEFINE 
	l_txt_len SMALLINT, 
	l_old_len SMALLINT, 
	l_new_len SMALLINT, 
	l_old_idx SMALLINT, 
	l_new_idx SMALLINT, 
	l_new_txt CHAR(512) 

	LET l_txt_len = length(f_old_txt) 
	LET l_old_len = length(f_old_sub) 
	LET l_new_len = length(f_new_sub) 
	IF l_txt_len = 0 
	OR l_old_len = 0 THEN 
		RETURN f_old_txt 
	END IF 
	LET l_new_txt = " " 
	LET l_old_idx = 1 
	LET l_new_idx = 1 
	WHILE l_old_idx <= l_txt_len 
		AND l_new_idx <= 512 
		IF l_old_idx + l_old_len - 1 > l_txt_len THEN 
			LET l_new_txt[l_new_idx, 512] = f_old_txt[l_old_idx, l_txt_len] 
			EXIT WHILE 
		END IF 
		IF f_old_txt[l_old_idx, l_old_idx + l_old_len - 1] = f_old_sub THEN 
			# we have found the old substring...
			LET l_new_txt[l_new_idx, 512] = f_new_sub 
			LET l_new_idx = l_new_idx + l_new_len 
			LET l_old_idx = l_old_idx + l_old_len 
			CONTINUE WHILE 
		END IF 
		# OTHERWISE, just another letter TO transfer...
		LET l_new_txt[l_new_idx] = f_old_txt[l_old_idx] 
		LET l_new_idx = l_new_idx + 1 
		LET l_old_idx = l_old_idx + 1 
		CONTINUE WHILE 
	END WHILE 
	RETURN l_new_txt 
END FUNCTION 


FUNCTION set_filenames() 
	#        -------------
	LET gv_systable_unl = gr_params.snapshot_dir clipped, "/systable.U19" 
	LET gv_syssyntab_unl = gr_params.snapshot_dir clipped, "/syssyntab.U19" 
	LET gv_syscol_unl = gr_params.snapshot_dir clipped, "/syscol.U19" 
	LET gv_sysview_unl = gr_params.snapshot_dir clipped, "/sysview.U19" 
	LET gv_sysind_unl = gr_params.snapshot_dir clipped, "/sysind.U19" 
	LET gv_systabauth_unl = gr_params.snapshot_dir clipped, "/systabauth.U19" 
	LET gv_syscolauth_unl = gr_params.snapshot_dir clipped, "/syscolauth.U19" 
	LET gv_sysusers_unl = gr_params.snapshot_dir clipped, "/sysusers.U19" 
	LET gv_sysconstr_unl = gr_params.snapshot_dir clipped, "/sysconstr.U19" 
	LET gv_syscoldep_unl = gr_params.snapshot_dir clipped, "/syscoldep.U19" 
	LET gv_syschecks_unl = gr_params.snapshot_dir clipped, "/syschecks.U19" 
	LET gv_sysrefs_unl = gr_params.snapshot_dir clipped, "/sysrefs.U19" 
	LET gv_systrigg_unl = gr_params.snapshot_dir clipped, "/systrigg.U19" 
	LET gv_systrigb_unl = gr_params.snapshot_dir clipped, "/systrigb.U19" 
	LET gv_sysprocb_unl = gr_params.snapshot_dir clipped, "/sysprocb.U19" 
	LET gv_sysproc_unl = gr_params.snapshot_dir clipped, "/sysproc.U19" 
END FUNCTION 

#END U19


