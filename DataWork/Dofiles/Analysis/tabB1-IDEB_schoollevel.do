
/*******************************************************************************
*  Project:				PIP													   *												   
*																 			   *
*  PURPOSE:  			Estimate treatment effect in terms of IDEB			   *
*  WRITTEN BY:  	  	Matteo Ruzzante [mruzzante@worldbank.org]			   *
*  Last time modified:  February 2019										   *
*																			   *
********************************************************************************

	** OUTLINE:			Store OLS estimates
						Store IV estimates
						
						Export table
							
	** REQUIRES:   		"${master_dt_fin}/master_studentlevel.dta"
						
	** CREATES:	   		Table B1: Impact on IDEB
						"${master_tab}/IDEB_schoollevel.tex"
				
* ---------------------------------------------------------------------------- */
	
	use "${master_dt_fin}/master_schoollevel.dta", clear

	foreach gradeNum in 5 6 1 {
		
		* OLS
		* ---
		eststo OLS_grade`gradeNum':			///
			   reghdfe ideb school_treated 	///
			if grade == `gradeNum' 			///
			 , abs(strata) cl(inep)
		
		* Add mean and standard deviation of the control group to the stored estimates
		sum     ideb			 if e(sample) == 1 & school_treated == 0
		estadd  scalar mean	 	  = r(mean)
		estadd  scalar sd	 	  = r(sd)
	}
	
* ---------------------------------------------------------------------------- */

	* Save results in LaTeX
	#d	;
								
		esttab OLS_grade5
			   OLS_grade6
			   OLS_grade1
		using "${master_tab}/IDEB_schoollevel.tex"
		,
		replace tex
		se nocons fragment
		nodepvars nonumbers nomtitles nolines
		noobs nonotes alignment(c)
		
		keep(school_treated)
		coeflabel(school_treated "Treatment")
		stats(N mean sd
				  , lab("\addlinespace[0.5em] Number of observations"
						"Mean dep.\ var.\ control group"
						"SD dep.\ var.\ control group"
						)
					fmt(0 %9.3f %9.3f))
		star(* 0.10 ** 0.05 *** 0.01)
		b(%9.3f) se(%9.3f)
		
		prehead("& (1) & (2) & (3)  \\		 "
				"& 5th & 6th & 10th \\ \hline")
		postfoot("[0.25em] \hline \hline \\ [-1.8ex]")
		;
	#d	cr
	
	filefilter "${master_tab}/IDEB_schoollevel.tex"  		///
			   "${master_tab}/tabB1-IDEB_schoollevel.tex" 	///
			   , from("[1em]") to("") replace		
	sleep		${sleep}
	erase 	   "${master_tab}/IDEB_schoollevel.tex"

	
******************************** End of do-file ********************************
