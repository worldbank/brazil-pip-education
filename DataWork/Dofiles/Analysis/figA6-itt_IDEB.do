
/*******************************************************************************
*  Project:				PIP													   *												   
*																 			   *
*  PURPOSE:  			Compare IDEB (with PIP effect) in Brazilian states	   *
*  WRITTEN BY:  	  	Matteo Ruzzante [mruzzante@worldbank.org]			   *
*  Last time modified:  July 2020											   *
*																			   *
********************************************************************************

	** OUTLINE:			Regressions
						Graph
							
	** REQUIRES:   		"${master_dt_fin}/master_schoollevel.dta"
						"${master_dt_fin}/Brazil_IDEB.dta"
						
	** CREATES:	   		Figure A6: Learning Gains in 6th Grade Rescaled to IDEB - Comparison with Other Brazilian States
						"${master_fig}/figA6-itt_IDEB.png"
				
* ---------------------------------------------------------------------------- *
*							Estimate coefficients				   			   *
* ---------------------------------------------------------------------------- */

	use "${master_dt_fin}/master_schoollevel.dta", clear

	foreach gradeNum in 6 {
		
		* OLS
		reghdfe ideb school_treated 						///
			 if grade == `gradeNum' 						///
			  , abs(strata) cl(inep)
		
		matrix results = r(table)
		
		scalar TE_grade`gradeNum'_OLS = results[1,1]
		scalar SE_grade`gradeNum'_OLS = results[2,1]
		scalar  p_grade`gradeNum'_OLS = results[4,1]
	}
	
	scalar list
	
	
* ---------------------------------------------------------------------------- *
*					Graph state averages and treatment effect		   		   *
* ---------------------------------------------------------------------------- */

	use	"${master_dt_fin}/Brazil_IDEB.dta", clear
	
	* Generate high and low points for standard error bars
	foreach estimator in OLS {
		
		gen 	y_grade6_`estimator'  = ideb_2015 + TE_grade6_`estimator' 					if state == "Rio Grande do Norte"
				
		gen   	hiy_`estimator'		  = y_grade6_`estimator' + 1.65 * SE_grade6_`estimator' if state == "Rio Grande do Norte"
		gen  	lowy_`estimator'	  = y_grade6_`estimator' - 1.65 * SE_grade6_`estimator' if state == "Rio Grande do Norte"

		* Transform coefficient in string with two decimals + add stars
		gen 	coefficient_`estimator' = "{&beta}{subscript:ITT}: +"
		replace coefficient_`estimator' = coefficient_`estimator' + string(round(TE_grade6_`estimator',.01), "%9.2f") + "*"   if p_grade6_`estimator'>0.05 & p_grade6_`estimator'<=0.10 & state == "Rio Grande do Norte"
		replace	coefficient_`estimator' = coefficient_`estimator' + string(round(TE_grade6_`estimator',.01), "%9.2f") + "**"  if p_grade6_`estimator'>0.01 & p_grade6_`estimator'<=0.05 & state == "Rio Grande do Norte"
		replace	coefficient_`estimator' = coefficient_`estimator' + string(round(TE_grade6_`estimator',.01), "%9.2f") + "***" if 			     	  		 p_grade6_`estimator'<=0.01 & state == "Rio Grande do Norte"
		replace	coefficient_`estimator' = "{bf:" + coefficient_`estimator' + "}" 											  if 														  state == "Rio Grande do Norte"
	}
	
	* Generate variable for position
	sort	ideb_2015 stateInitials
	
	local 	  xlabArgument ""
	forv 	  labPosition = 1/`=_N' {
		local stateString = stateInitials[`labPosition']
		di 	"`stateString'"
		local xlabArgument `" `xlabArgument' `labPosition' "`stateString'" "'
	}
	di `"`xlabArgument'"'
	
	gen 	barPosition 	= _n
	gen 	bar_position 	= ideb_2015	 						   				if state == "Rio Grande do Norte"
		
	sum 	ideb_2015
	local 	avg_ideb = r(mean)
	
	#d	;
		gr tw (bar 	   y_grade6_OLS		barPosition , color(ebblue)			   			   )
			  (bar 	   ideb_2015		barPosition , color(navy%80)					   )
			  
			  (rcap    hiy_OLS lowy_OLS barPosition , lcolor(maroon) lwidth(medthick)	   )
			  (scatter y_grade6_OLS	 	barPosition , msize(1) mcolor(maroon)
													  msymbol(circle)					   )
													  
			  (scatter hiy_OLS	 		barPosition , msize(0)
													  mlab(coefficient_OLS)
													  mlabpos(12) 	    mlabgap(6)
													  mlabcolor(maroon) mlabsize(medlarge) )
			  ,
			   
			   yline(`avg_ideb', lstyle(foreground))
			   ytitle("")
			   xtitle("")
			   
			   yscale(range(0 5))
			   ylab(0 "" 1 "1" 2 "2" 3 "3" 5 "5"	   , nogrid)
			   ylab(`avg_ideb' `" "Brazil" "median" "' , add)
			   xlab(`xlabArgument', alt)
			   
			   legend(order(1 "PIP ITT effect"
							3 "90% CI"))
			   			   
			   ${graphOptions}
			   xscale(nofextend titlegap(2)) 
			   yscale(nofextend)
		  ;
	#d	cr
	
	gr export "${master_fig}/figA6-itt_IDEB.png", width(5000) as(png) replace
	
	
******************************** End of do-file ********************************
