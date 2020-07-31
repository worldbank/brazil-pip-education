		
/*******************************************************************************
*  Project:				PIP													   *												   
*																 			   *
*  PURPOSE:  			Estimate heterogeneouts effect on progression rates	   *
*  WRITTEN BY:  	  	Matteo Ruzzante [mruzzante@worldbank.org]			   *
*  Last time modified:  July 2020										  	   *
*																			   *
********************************************************************************

	** OUTLINE:			School-level regressions (SIGEduc data)
						Student-level regressions (census data)
	
	** REQUIRES:   		"${master_dt_fin}/master_schoollevel.dta"
						"${master_dt_fin}/RN_students_panel.dta"
						
	** CREATES:	   		Table A6: Impact on Student Progression Rate -- Heterogeneity by Passing Rate at Baseline
						"${master_tab}/tabA6-promotion_het.tex"

* ---------------------------------------------------------------------------- *
*							School level regression				   			   *
* ---------------------------------------------------------------------------- */
	
	* Load master data at the school level
	use	"${master_dt_fin}/master_schoollevel", replace
	
	* Count number of schools
	count
	
	gen 		promotion_dummy = .
	
	foreach 	grade in 5 6 1 {
	
		sum 		   		      promotion_rate_2015  if grade == `grade', d
		
		scalar  									  	  median_promotion_rate_grade`grade' = `r(p50)'
		replace promotion_dummy = promotion_rate_2015  <  median_promotion_rate_grade`grade'    ///
						   if !mi(promotion_rate_2015) &  grade == `grade'
		replace promotion_dummy = promotion_rate_2015  >= median_promotion_rate_grade`grade'    ///
						   if !mi(promotion_rate_2015) &  grade == `grade'
	}
		
	tab		    promotion_dummy
	
	preserve
	
		   keep promotion_dummy inep
		   
		   tempfile dummyVar
		   save	   `dummyVar'
		
	restore
	
	* Drop all stored estimation results
	est clear
		
	local schoolPrefix promotion dropout retention
	
	* Store regressions results with promotion, drop-out, and retention rate
	foreach rateType of local schoolPrefix {
	 	
		if "`rateType'" == "promotion" local rateTypeStudent "promoted"
	 	if "`rateType'" == "dropout"   local rateTypeStudent "dropped"
		if "`rateType'" == "retention" local rateTypeStudent "retained"
		
		eststo 	`rateType'_all: ///
		reghdfe `rateType'_rate_2016 school_treated##promotion_dummy, abs(strata) vce(rob)
		
		* Add p-value of treatment + interaction term to estimation scalars
		estadd scalar   diff = _b[1bn.school_treated] + _b[1bn.school_treated#1bn.promotion_dummy]
		
		test   1bn.school_treated + 1bn.school_treated#1bn.promotion_dummy = 0
		estadd scalar p_diff = r(p)


		foreach grade in 5 6 1 {
			eststo 	`rateType'_grade`grade': ///
			reghdfe `rateType'_rate_2016 school_treated##promotion_dummy ///
				  if grade == `grade', abs(strata) vce(rob)
			
			estadd scalar   diff = _b[1bn.school_treated] + _b[1bn.school_treated#1bn.promotion_dummy]
			test   1bn.school_treated + 1bn.school_treated#1bn.promotion_dummy = 0
			estadd scalar p_diff = r(p)
		}
	 }
	 
* ---------------------------------------------------------------------------- *
*							Student level regression				   		   *
* ---------------------------------------------------------------------------- *	

	use  "${master_dt_fin}/RN_students_panel.dta", clear
	
	keep if inlist(student_grade , 5, 6, 10)
	
	replace  	   student_grade = 1 if student_grade == 10

	rename  	   student_grade grade
	
	merge m:1 inep grade using "${master_dt_fin}/master_schoollevel.dta", ///
			  nogen keep(match) keepusing(school_treated *rate* strata)
	
	distinct inep
	
	keep if  year == 2016
	
	*save "${master_dt_int}/PIP_students.dta", replace
	
	local 	 studentVars promoted dropped retained
	
	* Turn to percentage points
	foreach  rateType of local studentVars {
	
		replace `rateType' = `rateType' * 100
	}
	
	merge m:1 inep using `dummyVar', nogen keep(match)
	
	* Store regressions results with promotion, drop-out, and retention rate
	foreach rateType of local studentVars {
	 	
		eststo 	`rateType'_all: ///
		reghdfe `rateType' school_treated##promotion_dummy, abs(strata) cl(inep)
		
		estadd scalar   diff = _b[1bn.school_treated] + _b[1bn.school_treated#1bn.promotion_dummy]
		
		test   1bn.school_treated + 1bn.school_treated#1bn.promotion_dummy = 0
		estadd scalar p_diff = r(p)
					
		foreach grade in 5 6 1 {
			
			eststo 	`rateType'_grade`grade': ///
			reghdfe `rateType' school_treated##promotion_dummy if grade == `grade', abs(strata) cl(inep)

			estadd scalar   diff = _b[1bn.school_treated] + _b[1bn.school_treated#1bn.promotion_dummy]
			test   1bn.school_treated + 1bn.school_treated#1bn.promotion_dummy = 0
			estadd scalar p_diff = r(p)
		}
	}
	
	foreach rateType of local studentVars {
	
		if "`rateType'" == "promoted" local schoolPrefix "promotion"
	 	if "`rateType'" == "dropped"  local schoolPrefix "dropout"
		if "`rateType'" == "retained" local schoolPrefix "retention"
		
		#d	;
		esttab `schoolPrefix'_all `schoolPrefix'_grade5 `schoolPrefix'_grade6 `schoolPrefix'_grade1 
				   `rateType'_all	  `rateType'_grade5 	`rateType'_grade6     `rateType'_grade1 	 
				using "${master_tab}/`rateType'.tex",
				
				replace tex
				se fragment
				nodepvars nonumbers nomtitles nolines
				noobs nonotes alignment(c)
				
				keep(	  1.school_treated
						  1.school_treated#1.promotion_dummy
						  1.promotion_dummy
						  _cons)
				order(	  1.school_treated
						  1.school_treated#1.promotion_dummy
						  1.promotion_dummy
						  _cons)
				coeflabel(1.school_treated  				 "Treatment"
						  1.school_treated#1.promotion_dummy "Treatment $\times$ High passing rate at baseline"
						  1.promotion_dummy					 "High passing rate at baseline"
						  _cons								 "\addlinespace[0.5em] Constant")
				stats(diff p_diff,
					  lab("\addlinespace[0.75em] \multicolumn{9}{l}{\textit{Total effect on schools with high passing rate at baseline:} Treatment $+$ Treatment $\times$ high-promotion dummy} \\ \hspace{10pt} $\sum \hat{\beta}$" "\hspace{10pt} P-value")
					  fmt(%9.3f %9.3f))
					  
				star(* 0.10 ** 0.05 *** 0.01)
				b(%9.2f) se(%9.2f)
			;
		#d	cr
	}
	
	file close _all
	
	file open progression using "${master_tab}/promotion_het.tex", text write replace
					
	* Append estimations in unique LaTeX file 															
	foreach var of local studentVars {																	
		
		file open 	`var' using "${master_tab}/`var'.tex", text read
																										
		* Loop over lines of the LaTeX file and save everything in a local								
		local `var' ""																					
			file read  `var' line																		
		while r(eof)==0 { 																				
			local `var' `" ``var'' `line' "'															
			file read  `var' line																		
		}																								
			file close `var'																			
		
		sleep  ${sleep}
		erase "${master_tab}/`var'.tex" 																
	}
			
	* Append all locals as strings, add footnote and end of LaTeX environments
	#d	;
		file write progression
			 
			 "&\multicolumn{4}{c}{\textit{Grade level}} &\multicolumn{4}{c}{\textit{Student level}} \\" _n
			 "						 \cmidrule(lr){2-5}  \cmidrule(lr){6-9}					   " _n
			 "&						 (1) &(2) &(3) &(4)  &(5) &(6) &(7) &(8)  \\		 	   " _n
			 "&						 All &5th &6th &10th &All &5th &6th &10th \\ 		 \hline" _n
			 "\addlinespace[0.25em] &\multicolumn{8}{c}{\textbf{Passing}}	  \\[0.25em] \hline" _n
			 "\addlinespace[0.25em] `promoted' 								    [0.75em] \hline" _n
			 "\addlinespace[0.25em] &\multicolumn{8}{c}{\textbf{Dropout}}     \\[0.25em] \hline" _n
			 "\addlinespace[0.25em] `dropped'								    [0.75em] \hline" _n
			 "\addlinespace[0.25em] &\multicolumn{8}{c}{\textbf{Retention}}   \\[0.25em] \hline" _n
			 "\addlinespace[0.25em] `retained' 								  		     \hline" _n
			 " \hline \\[-1.8ex]"
		;
	#d	cr
	
	file close progression
	
	* Remove spaces
	filefilter "${master_tab}/promotion_het.tex"		/// 
			   "${master_tab}/tabA6-promotion_het.tex"	///
			   , from("[1em]") to("") replace
	erase 	   "${master_tab}/promotion_het.tex"
	
	* Add link to the file (filefilter does not provide it automatically"
	di as text `"Open final file in LaTeX here: {browse "${master_tab}/tabA6-promotion_het.tex":"${master_tab}/tabA6-promotion_het.tex"}"'
	
******************************** End of do-file ********************************
