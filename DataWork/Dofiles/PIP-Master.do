
/*******************************************************************************
*                            ______	    ___   ______						   *
*                           /  _   )   /  /  /  _   )						   *
*                          /  (_)  )  /  /  /  (_)  )						   *
*                         /  _____/  /  /  /  _____/						   *
*                        /  /       /  /  /  /								   *
*                       /__/       /__/  /__/								   *
*													  						   *
*  			  			PIP WORKING PAPER MASTER DO-FILE					   *
*																 			   *
*  WRITTEN BY: 		  	Matteo Ruzzante [mruzzante@worldbank.org]			   *
*  REVIEWED BY:			Abdoul Aziz Adama and Luiza Andrade					   *
*  Last time modified: 	July 2020								   		  	   *
*																			   *
********************************************************************************
	
********************************************************************************
* 							 Select sections to run							   *
********************************************************************************/
	
	local packages		1		//install or update packages
	local folders		1		//set globals with folder paths
	
	local analysis		1		//produce main tables and figures in the main text of the paper
	local supplement	1		//produce supplementary tables and figures in Appendix A
	local envelope		1		//produce tables and figured for back-of-the-envelope calculations in Appendix B
	local online		1		//produce tables and figures in the Online Appendix

********************************************************************************
*          PART 0:  INSTALL PACKAGES AND STANDARDIZE SETTINGS				   *
********************************************************************************
		
	if `packages' {
	
		* List all packages that this project requires
		#d	;
		
			local packageList carryforward 
							  coefplot
							  dataout
							  distinct
							  egenmore
							  estout
							  etime
							  fre
							  fsum
							  ftools   	//needed for 'reghdfe'
							  iefieldkit
							  ietoolkit
							  missings
							  orth_out
							  qreg2
							  reghdfe
							  ritest
			;
		#d	cr
	
		foreach  package of local packageList {
		
			ssc  install `package', replace
		}
		
		* Force an update
		ftools , compile
		reghdfe, compile
		//solve issues with estimations based on previous versions
		//namely, error "class FixedEffects undefined" may arise
		
		* Manually install this package by commenting out the next line and run it
		*findit  dm89_2	  // for dropmiss.ado
		
		* Install package from Urbancic and Gibbons (2017) paper
			* --------------------------------------------------
			* Loads website
			net from "http://www.jcsuarez.com/GSSU"
			
			* Describes package
			net describe GSSU
			
			* Installs commands with sample-weighted average treatment effect estimators
			net install  GSSU
	}
	
	* Set globals
	global repsNum   	10000		//number of replications for randomization inference
	global seedsNum		192289 		//obtained on https://www.random.org/ at 4.55pm on 2/5/2019
  	global sleep	  	1000		//delay code for running so it doesn't crash
	global stataVersion 13.1		//Stata version: change to older version if you don't have the one specified
									//however, beware that this may cause some packages to not work properly
									//and some results to vary.
	
	//In order to reproduce some of the figures, you will need to have
	//Stata version 15 or 16: in particular, you won't be able to use the 
	//feature that adjustes the transparency of elements in graphs
	
	* Standardize settings across users
	ieboilstart , version(${stataVersion})
			   `r(version)'                    
	
	* Start timer
	etime		, start
	   
********************************************************************************
*						PART 1:  SET FOLDER PATH GLOBALS					   *
********************************************************************************

	if `folders' {
		
		* Set directories (root folder) 
		* ---------------
		
		* Matteo Bank
		if  c(username) == 		"WB527265" {
			global github  		"C:/Users/WB527265/Documents/GitHub/brazil-pip-education"
			global dropbox 		"C:/Users/WB527265/Dropbox/RN - PIP/DataWork_WP"
		}
		
		* Matteo PC
		if  c(username) == 		"ruzza" {
			global github  		"C:/Users/ruzza/OneDrive/Documenti/GitHub/brazil-pip-education"
		    global dropbox 		"C:/Users/ruzza/Dropbox/RN - PIP/DataWork_WP"
		}
		
		* Other user
		if 	c(username) == 		"" { //you can find your username by running "di c(username)" in the command window, and then subsitute it here
			global github		""	 //add your paths here
			global dropbox		""
		}
		
		* Subfolders
		* ----------
		global master          	"${dropbox}/MasterData"
			
		global master_dt     	"${master}/DataSets"
		global master_dt_raw	"${master_dt}/Raw"
		global master_dt_int	"${master_dt}/Intermediate"
		global master_dt_fin	"${master_dt}/Final"
		
		global master_out		"${github}/DataWork/Output"
		global master_tab		"${master_out}/Tables"
		global master_fig		"${master_out}/Figures"
		
		global master_do		"${github}/DataWork/Dofiles"
		global master_do_cl		"${master_do}/Cleaning"
		global master_do_con	"${master_do}/Construct"
		global master_do_anl	"${master_do}/Analysis"
		
		macro  list
	}

********************************************************************************
*							PART 2:  RUN DO FILES							   *
******************************************************************************** 
	
	* Set graphical options
	global 		  fontType  "Palatino Linotype"
	gr set window fontface  "${fontType}"
	gr set eps 	  fontface  "${fontType}"
	
	global    controlColor  "edkblue"
	global  treatmentColor  "eltblue"
	global     effectColor  "ebblue"
	
	global 	  graphOptions  "title("") ylab(, angle(horizontal)) graphregion(color(white)) plotregion(color(white))"
	
	* Create folders to store results (if they do not exist yet)
	cap    mkdir 			"${master_out}"
	cap    mkdir 			"${master_tab}"
	cap    mkdir 			"${master_fig}"
	
	* Install own ado-file to compure difference in means by block 
	do 					   	"${master_do}/blockdim.ado"
		
	* Run paper codes so to replicate all tables and figures in both main text and appendices.
	* Cleaning and construct are left out as they contain Personally Identifiable Information
	* on students, teachers, and schools in our experimental sample.
	* The same applies to the map in Figure 4, which was produced in R using school GPS points
	if `analysis'   {
		
		* Figures
		* -------
			
			* Dropout and retention in RN
			do "${master_do_anl}/fig1-grade_comparison.do"
			
			* IDEB
			do "${master_do_anl}/fig2-IDEB_byState.do"
						
			* PIP resource allocation
			do "${master_do_anl}/fig3-grant.do"
			
			* Retention and student attainment as outcome of 6th grade
			do "${master_do_anl}/fig5-retention_grade6.do"
			
			* Implementation by grade
			do "${master_do_anl}/fig6-implementation_byGrade.do"
			
		* Tables
		* ------
		
			* Sample
			do "${master_do_anl}/tab1-sample.do"
			
			* Balance table
			do "${master_do_anl}/tab2-baltab.do"
			//Note that this do-file will take quite a long time to run
			//as it uses randomization inference with 10,000 repetitions.
			//You can comment it out by adding '//' before 'do' in line 201
			
			* Regressions on main outcomes
			do "${master_do_anl}/tab3-test_studentlevel.do"
			do "${master_do_anl}/tab4-promotion.do"
			
			* Mechanisms
			do "${master_do_anl}/tab5-turnover_teacherlevel.do"
			do "${master_do_anl}/tab6-het_turnover.do"
			do "${master_do_anl}/tab7-spillover_other_grades.do"
			do "${master_do_anl}/tab8-socio_studentlevel.do"
		}
	
	if `supplement' {
		
		* Figures
		* -------
		
			* IDEB by participation
			do "${master_do_anl}/figA1-predict_participation.do"

			* Quantile regression on average test score
			do "${master_do_anl}/figA2-qreg_media_grade6.do"
			
			* Distribution and impact by gender
			do "${master_do_anl}/figA3a-kdensity_grade6_byGender.do"
			do "${master_do_anl}/figA3b-qreg_media_grade6_byGender.do"
			
			* Effect in terms of Prova Brasil
			do "${master_do_anl}/figA5-itt_ProvaBrasil.do"
			do "${master_do_anl}/figA6-itt_IDEB.do"
		
		* Tables
		* ------
		
			* Motivation
			do "${master_do_anl}/tabA1-correlates_turnover.do"
			
			* Attrition
			do "${master_do_anl}/tabA2-baltab_participation.do"
			do "${master_do_anl}/tabA3,4-baltab_test_takers_schoollevel.do"
			//note that these do-files will take quite a long time to run
			//as they use randomization inference with 10,000 repetitions
			
			* Heterogeneity by gender and promotion rate
			do "${master_do_anl}/tabA5-promotion_het_gender.do"
			do "${master_do_anl}/tabA6-promotion_het.do"
			
			* Impact of retention in 6th grade on dropout and years of completed schooling
			do "${master_do_anl}/tabA7-retention_grade6_regs.do"
			
			* Drivers of implementation
			do "${master_do_anl}/tabA8-predict_implementation.do"
			
			* Impact on clearance certificate
			do "${master_do_anl}/tabA9-clearance_certificate.do"
	}
	
	if `envelope'   {
		
		* Effect in terms of IDEB
		do "${master_do_anl}/tabB1-IDEB_schoollevel.do"
				
		* Effect on expected earnings
		do "${master_do_anl}/figB1-kdensity_wage.do"
	}
	
	if `online' 	{
		
		* Quantile regressions by subject
		do "${master_do_anl}/figC1-qreg_bySubject_grade6.do"
		
		* Adding controls
		do "${master_do_anl}/tabC1-test_studentlevel_ctrl.do"
		do "${master_do_anl}/tabC8-socio_studentlevel_ctrl.do"
		
		* Blocked difference-in-means
		do "${master_do_anl}/tabC2-test_studentlevel_DIM.do"
		do "${master_do_anl}/tabC9-socio_studentlevel_DIM.do"

		* IWE and RWE estimators
		do "${master_do_anl}/tabC3-test_studentlevel_IWE.do"
		do "${master_do_anl}/tabC4-test_studentlevel_RWE.do"
		do "${master_do_anl}/tabC10-socio_studentlevel_IWE.do"
		do "${master_do_anl}/tabC11-socio_studentlevel_RWE.do"
		
		* School level regressions
		do "${master_do_anl}/tabC5-test_schoollevel.do"
		do "${master_do_anl}/tabC12-socio_schoollevel.do"
		
		* Spillover to other grades - full set of estimates
		do "${master_do_anl}/tabC7-promotion_other_grades.do"
		
		* Regressions on rescaled test scores
		do "${master_do_anl}/tabC6-test_rescaled_studentlevel.do"
	}
	
	* Close all graph windows and end the code
	gr 	   close _all
	
	* Show elapsed time
	etime
	
	// Valeu! :D
