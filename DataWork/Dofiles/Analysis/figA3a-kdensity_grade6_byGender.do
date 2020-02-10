
/*******************************************************************************
*						PIP								   					   *
*																 			   *
*  PURPOSE:  			Test score distribution by gender			   		   *
*  WRITTEN BY:  		Matteo Ruzzante [mruzzante@worldbank.org]		   	   *
*  Last time modified:  May 2019											   *
*																			   *
********************************************************************************

	** OUTLINE:			
	
	** REQUIRES:   		"${master_dt_fin}/master_studentlevel.dta"
						
	** CREATES:			Figure A3: Impact on Average Test Score by Gender in 6th Grade
						(a) Distribution 
						"${master_fig}/figA3a-kdensity_grade6_byGender.png"
			
	** NOTES:
	
* ---------------------------------------------------------------------------- */

	* Load student level data
	use  	"${master_dt_fin}/master_studentlevel", clear
	
	* Restrict data to 6th graders
	keep if grade == 6 & pool_6EF == 1
			
	* Calculate means (by treatment and gender)
	* ---------------
	sum 	proficiencia_media if student_gender  == 0 & school_treated == 0
	local 	control_F 		=  string(`r(mean)',  "%9.2f")
	sum		proficiencia_media if student_gender  == 0 & school_treated == 1
	local 	treat_F   		=  string(`r(mean)',  "%9.2f")
	sum 	proficiencia_media if student_gender  == 1 & school_treated == 0
	local 	control_M 		=  string(`r(mean)',  "%9.2f")
	sum		proficiencia_media if student_gender  == 1 & school_treated == 1
	local 	treat_M   		=  string(`r(mean)',  "%9.2f")
		
	* Count number of observations
	* ----------------------------
	sum		proficiencia_media if student_gender == 0
	local	N_F		  	 	= `r(N)'
	sum		proficiencia_media if student_gender == 1
	local	N_M		  		= `r(N)'
	
	* Estimate treatment effect
	* -------------------------
	reghdfe proficiencia_media school_treated if student_gender == 0, cl(inep) abs(strata)
	
	mat 	results			= r(table)
	local 	beta_F			= string( _b[school_treated] , "%9.2f")
	local	se_F			= string(_se[school_treated] , "%9.2f")
	local	TE_F			"`beta_F' (`se_F')"	
	local	pvalue_F		= results[4,1]
	
	* Add level of significance
	foreach ttest_p_level in 0.1 0.05 0.01 {

		if `pvalue_F' < `ttest_p_level' ///
			local TE_F "`TE_F'*"
	}
	di "`TE_F'"
	
	reghdfe proficiencia_media school_treated if student_gender == 1, cl(inep) abs(strata)
	
	mat 	results			= r(table)
	local 	beta_M			= string( _b[school_treated] , "%9.2f")
	local	se_M			= string(_se[school_treated] , "%9.2f")
	local	TE_M			"`beta_M' (`se_M')"	
	local	pvalue_M		= results[4,1]
	
	foreach ttest_p_level in 0.1 0.05 0.01 {

		if `pvalue_M' < `ttest_p_level' ///
			local TE_M "`TE_M'*"
	}
	di "`TE_M'"
	
	* Set locals for line colors and width
	* ------------------------------------
	local 	blue			"27 159 171"	//for boys
	local	red 			"242 94 54"		//for girls
	//from Financial Times newsroom
	
	local 	purple			"132 4 252"		//for girls
	local	green			"4 196 172"		//for boys
	//from Telegraph
	
	local	dens_width		0.6
	local	 avg_width		0.5
	
	* Plot graph
	* ----------
	#d	;
	
		// Girls
		gr	tw (kdensity proficiencia_media if student_gender == 0 & school_treated  == 0, color("`red'") lpattern(dash) lwidth(`dens_width') )
			   (kdensity proficiencia_media if student_gender == 0 & school_treated  == 1, color("`red'")				  lwidth(`dens_width') )
			   ,
			    xline(`control_F', lcolor(`red') lpattern(dash) lwidth(`avg_width')) 
			    xline(`treat_F'  , lcolor(`red') 			 	lwidth(`avg_width'))
			    ytitle("Kernel density estimates")
				xtitle("")
			    /*xtitle("Test scores (average)")*/
			    legend(lab(1 "Control") lab(2 "Treatment"))
			    text(0.013 245 "Control mean = `control_F'"
				 			   "Treatment mean = `treat_F'"
							   " "
							   "{&beta} = `TE_F'"
				 			   "N = `N_F'"
				 	,
				 	orient(horizontal)  size(small) justification(center)
				 	fcolor(white) box margin(small)
				 	)
			    ${graphOptions}
				yscale(nofextend)
				xscale(nofextend)
				title("Female Students", margin(b+3))
			    name(girls, replace)
		;
		
		// Boys
		gr	tw (kdensity proficiencia_media if student_gender == 1 & school_treated == 0, color("`blue'")   lpattern(dash) lwidth(`dens_width') )
			   (kdensity proficiencia_media if student_gender == 1 & school_treated == 1, color("`blue'") 			      lwidth(`dens_width') )
			   ,
			    xline(`control_M', lcolor(`blue') lpattern(dash) lwidth(`avg_width')) 
			    xline(`treat_M'  , lcolor(`blue') 				 lwidth(`avg_width'))
			     title("Male Students")
			    ytitle("")
				xtitle("")
			    /*xtitle("Test scores (average)")*/
			    legend(lab(1 "Control") lab(2 "Treatment"))
			    text(0.013 245 "Control mean = `control_M'"
							   "Treatment mean = `treat_M'"
							   " "
							   "{&beta} = `TE_M'"
							   "N = `N_M'"
					 ,
					 orient(horizontal)  size(small) justification(center)
					 fcolor(white) box margin(small)
					 ) 
			    ${graphOptions}
				yscale(nofextend)
				xscale(nofextend)
				title("Male Students", margin(b+3))	
			    name(boys, replace)
		;
		
		// Combine two graphs
		gr	combine girls boys
			,
			graphregion(color(white))
		;
		
		// Export image
		gr	export	 "${master_fig}/figA3a-kdensity_grade6_byGender.png", as(png) replace width(5000)
		;
		
	#d	cr
	
	gr close _all

******************************** End of do-file ********************************
