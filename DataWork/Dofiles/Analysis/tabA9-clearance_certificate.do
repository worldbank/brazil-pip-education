		
/*******************************************************************************
*  Project:				PIP													   *												   
*																 			   *
*  PURPOSE:  			Estimate effect on clearance certificate			   *
*  WRITTEN BY:  	  	Matteo Ruzzante [mruzzante@worldbank.org]			   *
*  Last time modified:  July 2020										  	   *
*																			   *
********************************************************************************
	
	** REQUIRES:   		"${master_dt_fin}/master_schoollevel.dta"
						
	** CREATES:	   		Table A9: Impact on Probability of School Obtaining the Clearance Certificate
						"${master_tab}/tabA9-clerance_certificate.tex"

* ---------------------------------------------------------------------------- */

	* Load data at the teacher level
	use "${master_dt_fin}/master_schoollevel.dta", clear
	
	eststo  all 		: reghdfe school_clearance_certificate school_treated	   ///
						, abs(strata) vce(rob)
	sum	   school_clearance_certificate if e(sample) & school_treated == 0
	estadd scalar mean  = r(mean)
	estadd scalar sd    = r(sd)

	foreach grade in 5 6 1  {
	
		eststo grade`grade' : reghdfe school_clearance_certificate school_treated ///
						   if grade == `grade'									  ///
						    , abs(strata) vce(rob) 
		sum    school_clearance_certificate if e(sample) == 1 & school_treated == 0
		estadd scalar mean  = r(mean)
		estadd scalar sd    = r(sd)
	}
		
	reghdfe school_clearance_certificate school_treated##ib6.grade	  , abs(strata) vce(rob)
	
	local   comparison5 = string(`=_b[1.school_treated#5.grade]*(-1)' , "%9.3f")
	local   comparison1 = string(`=_b[1.school_treated#1.grade]*(-1)' , "%9.3f")
	
	test 				  		   _b[1.school_treated#5.grade] 	  = 0
	local   pvalue5		= string(   r(p)						  	  , "%9.3f")
	test 				  		   _b[1.school_treated#1.grade]		  = 0
	local   pvalue1		= string(   r(p)						      , "%9.3f")
	
	#d	;
		esttab  all grade5 grade6 grade1
				using "${master_tab}/clerance_certificate.tex",
				replace tex se fragment
				nodepvars nonumbers nomtitles nolines noobs nonotes alignment(c)
				coeflabel(school_treated "\addlinespace[0.75em] Treatment")
				stats(N mean sd,
					  lab("\addlinespace[0.5em] Number of observations"
						  "\addlinespace[0.5em] Mean dep.\ var.\ control group"
											   "SD dep.\ var.\ control group")
					  fmt(0 %9.3f %9.3f))
			
				star(* 0.10 ** 0.05 *** 0.01)
				keep(school_treated)
				b(%9.3f) se(%9.3f)
				
				 prehead("&(1) &(2) &(3) &(4)  \\		"
						 "&All &5th &6th &10th \\ \hline")
				postfoot("\addlinespace[1.25em] 	  \multicolumn{5}{l}{ \textit{Treatment effect comparisons by grade:}  						 	   } \\"
					     "					    & &   \multicolumn{2}{c}{ $\reallywidehat{\beta_{6th}} - \reallywidehat{\beta_{5th} } = `comparison5'$ } \\"
						 "					    & &   \multicolumn{2}{c}{ T-test p-value $= `pvalue5'$ 					  			 				   } \\"
						 "\addlinespace[0.5em]  & & & \multicolumn{2}{c}{ $\reallywidehat{\beta_{6th}} - \reallywidehat{\beta_{10th}} = `comparison1'$ } \\"
						 "					    & & & \multicolumn{2}{c}{ T-test p-value $= `pvalue1'$ 					  			 				   } \\"
						 "[0.25em] \hline \hline \\ [-1.8ex]")
		;
	#d	cr
		
	* Remove spaces
	filefilter "${master_tab}/clerance_certificate.tex"			/// 
			   "${master_tab}/clerance_certificate_aux.tex"		///
			   , from("[1em]") to("") replace
	sleep  		${sleep}
	erase 	   "${master_tab}/clerance_certificate.tex"
	
	filefilter "${master_tab}/clerance_certificate_aux.tex"		/// 
			   "${master_tab}/tabA9-clearance_certificate.tex"	///
			   , from("\BS_") to("_") replace
	sleep  		${sleep}
	erase 	   "${master_tab}/clerance_certificate_aux.tex"
	
	
	* Add link to the file (filefilter does not provide it automatically"
	di as text `"Open final file in LaTeX here: {browse "${master_tab}/tabA9-clearance_certificate.tex":${master_tab}/tabA9-clearance_certificate.tex}"'

	
******************************** End of do-file ********************************
