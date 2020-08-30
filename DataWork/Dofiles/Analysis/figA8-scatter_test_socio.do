		
/*******************************************************************************
*  Project:				PIP													   *												   
*																 			   *
*  PURPOSE:  			Correlation between cognitive and non-cognitive		   *
*  WRITTEN BY:  	  	Matteo Ruzzante [mruzzante@worldbank.org]			   *
*  Last time modified:  July 2020										  	   *
*																			   *
********************************************************************************
	
	** REQUIRES:   		"${master_dt_fin}/master_studentlevel.dta"
						
	** CREATES:	   		Figure A8: Scatter Plot of Cognitive and Socio-Emotional Skills
						"${master_fig}/figA8-scatter_test_socio.png"
	
	** NOTE:			This applies the same coding tricks to estimate and
						store regression coefficients, and then plot them as
						text box in a twoway graph used in
						"figA7a-kdensity_grade6_byGender.do"
	
* --------------------------------------------------------------------------- */

	* Load master data at the student level
	use        "${master_dt_fin}/master_studentlevel", clear
	
	* Generate average of socio-emotional test scores
	egen 	   socio = rowmean(  agreeab_c   consc_c   extrav_c   neurot_c   openness_c)
	
	* Keep sample of test takers
	drop if mi(socio)
	
	* Generate average of socio-emotional test scores (standardized)
	egen 	 z_socio = rowmean(z_agreeab_c z_consc_c z_extrav_c z_neurot_c z_openness_c)
	
	* Estimate correlation coefficient
	reg  prof_media z_socio if school_treated == 0 , cl(inep)
	
	mat 	 results			 = r(table)
	local 	 beta_C				 = string( _b[z_socio] , "%9.3f")
	local	 se_C			     = string(_se[z_socio] , "%9.3f")
	local	 corr_C			       "`beta_C' (`se_C')"	
	local	 pvalue_C			 = results[4,1]
	
	* Add significance lelvel
	foreach ttest_p_level in 0.1 0.05 0.01 {

		if `pvalue_C' < `ttest_p_level' ///
			local corr_C "`corr_C'*"
	}
	
	reg  prof_media z_socio if school_treated == 1 , cl(inep)
	mat 	 results			 = r(table)
	local 	 beta_T				 = string( _b[z_socio] , "%9.3f")
	local	 se_T			     = string(_se[z_socio] , "%9.3f")
	local	 corr_T			       "`beta_T' (`se_T')"	
	local	 pvalue_T			 = results[4,1]
	
	* Add significance lelvel
	foreach ttest_p_level in 0.1 0.05 0.01 {

		if `pvalue_T' < `ttest_p_level' ///
			local corr_T "`corr_T'*"
	}
		
	* Plot scatter plot with linear fits and 95% confidence interval
	#d	;
		tw (lfit    prof_media z_socio if school_treated == 0 , est(cl(inep)) lcolor(${controlColor} ) 	lwidth(medthick) lpattern(dash) )
		   (lfit    prof_media z_socio if school_treated == 1 , est(cl(inep)) lcolor(${treatmentColor}) lwidth(medthick)		   		)
		   (scatter prof_media z_socio if school_treated == 0 ,  color(${controlColor}%70)   msize(small)   						    )
		   (scatter prof_media z_socio if school_treated == 1 ,  color(${treatmentColor}%45) msize(small)   						    )
		   ,
		   ${graphOptions}
		    
		   ytitle("Average test score"		  	  , margin(r+0) )
		   xtitle("Average socio-emotional score" , margin(t+2) )
		   
		   legend(order(3 "Control"
						4 "Treatment"
						)
				  )
				  
		   text(1 3.4 "{&beta}{subscript:C} = `corr_C'"
					     " "
					     "{&beta}{subscript:T} = `corr_T'"
					     ,
					      orient(horizontal)  size(small) justification(center)
					      fcolor(white) lcolor(white) box margin(small)
					      )
						  
			graphregion(margin(r+25)) 
		   ;
	#d	cr
	
	* Export graph in PNG format
	gr export  "${master_fig}/figA8a-scatter_test_socio.png", replace
	
	
	* Replicate the same figure for 6th graders
	* -----------------------------------------
	keep if grade == 6
	
	reg  prof_media z_socio if school_treated == 0 , cl(inep)
	
	mat 	 results			 = r(table)
	local 	 beta_C				 = string( _b[z_socio] , "%9.3f")
	local	 se_C			     = string(_se[z_socio] , "%9.3f")
	local	 corr_C			       "`beta_C' (`se_C')"	
	local	 pvalue_C			 = results[4,1]
	
	foreach ttest_p_level in 0.1 0.05 0.01 {

		if `pvalue_C' < `ttest_p_level' ///
			local corr_C "`corr_C'*"
	}
	
	reg  prof_media z_socio if school_treated == 1 , cl(inep) //abs(strata)
	mat 	 results			 = r(table)
	local 	 beta_T				 = string( _b[z_socio] , "%9.3f")
	local	 se_T			     = string(_se[z_socio] , "%9.3f")
	local	 corr_T			       "`beta_T' (`se_T')"	
	local	 pvalue_T			 = results[4,1]
	
	foreach ttest_p_level in 0.1 0.05 0.01 {

		if `pvalue_T' < `ttest_p_level' ///
			local corr_T "`corr_T'*"
	}
		
	
	#d	;
		tw (lfit    prof_media z_socio if school_treated == 0 , est(cl(inep)) lcolor(${controlColor} ) 	lwidth(medthick) lpattern(dash) )
		   (lfit    prof_media z_socio if school_treated == 1 , est(cl(inep)) lcolor(${treatmentColor}) lwidth(medthick)		   		)
		   (scatter prof_media z_socio if school_treated == 0 ,  color(${controlColor}%70)   msize(small)   						    )
		   (scatter prof_media z_socio if school_treated == 1 ,  color(${treatmentColor}%45) msize(small)   						    )
		   ,
		   ${graphOptions}
		    
		   ytitle("Average test score"		  	  , margin(r+0) )
		   xtitle("Average socio-emotional score" , margin(t+2) )
		   
		   legend(order(3 "Control"
						4 "Treatment"
						)
				  )
				  
			text(1 3 "{&beta}{subscript:C} = `corr_C'"
					     " "
					     "{&beta}{subscript:T} = `corr_T'"
					     ,
					      orient(horizontal)  size(small) justification(center)
					      fcolor(white) lcolor(white) box margin(small)
					      )
						  
			graphregion(margin(r+28))
		   ;
	#d	cr
	
	* Export graph in PNG format
	gr export  "${master_fig}/figA8b-scatter_test_socio_grade6.png", replace
	
	
******************************** End of do-file ********************************
