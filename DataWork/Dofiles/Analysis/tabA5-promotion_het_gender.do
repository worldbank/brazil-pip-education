		
/*******************************************************************************
*  Project:				PIP													   *												   
*																 			   *
*  PURPOSE:  			Estimate effect on progression rates by gender		   *
*  WRITTEN BY:  	  	Matteo Ruzzante [mruzzante@worldbank.org]			   *
*  Last time modified:  July 2020										  	   *
*																			   *
********************************************************************************

	** OUTLINE:			Student-level regressions (census data)
	
	** REQUIRES:   		"${master_dt_fin}/RN_students_panel.dta"
						
	** CREATES:	   		Table A5: Impact on Student Progression Rate -- Heterogeneity by Gender
						"${master_tab}/tabA5-promotion_het_gender.tex"
	
* ---------------------------------------------------------------------------- */

	use  "${master_dt_fin}/RN_students_panel.dta", clear
	
	keep if inlist(student_grade , 5, 6, 10)
	
	replace  	   student_grade = 1 if student_grade == 10

	rename  	   student_grade grade
	
	merge m:1 inep grade using "${master_dt_fin}/master_schoollevel.dta", ///
			  nogen keep(match) keepusing(school_treated *rate* strata)
	
	distinct inep
	
	keep if  year == 2016
		
	local 	 studentVars promoted dropped retained
	
* ---------------------------------------------------------------------------- *
*							Split sample by gender				   		   	   *
* ---------------------------------------------------------------------------- *
	
	* Store regressions results with promotion, drop-out, and retention rate
	foreach rateType of local studentVars {
	 	
		eststo 	`rateType'_all: ///
		reghdfe `rateType' school_treated##student_gender, abs(strata) cl(inep)
		
		estadd scalar   diff = _b[1bn.school_treated] + _b[1bn.school_treated#1bn.student_gender]
		
		test   1bn.school_treated + 1bn.school_treated#1bn.student_gender = 0
		estadd scalar p_diff = r(p)
					
		foreach grade in 5 6 1 {
			
			eststo 	`rateType'_grade`grade': ///
			reghdfe `rateType' school_treated##student_gender if grade == `grade', abs(strata) cl(inep)

			estadd scalar   diff = _b[1bn.school_treated] + _b[1bn.school_treated#1bn.student_gender]
			test   1bn.school_treated + 1bn.school_treated#1bn.student_gender = 0
			estadd scalar p_diff = r(p)
		}
	}
	
	foreach rateType of local studentVars {

		#d	;
		esttab  `rateType'_all
				`rateType'_grade5
				`rateType'_grade6
				`rateType'_grade1 	 
				using "${master_tab}/`rateType'.tex",
				
				replace tex
				se fragment
				nodepvars nonumbers nomtitles nolines
				noobs nonotes alignment(c)
				
				keep(	  1.school_treated
						  1.school_treated#1.student_gender
						  1.student_gender
						  _cons)
				order(	  1.school_treated
						  1.school_treated#1.student_gender
						  1.student_gender
						  _cons)
				coeflabel(1.school_treated  				"Treatment"
						  1.school_treated#1.student_gender "Treatment $\times$ Male student"
						  1.student_gender					"Male student"
						  _cons								"\addlinespace[0.5em] Constant")
				stats(diff p_diff,
					  lab("\addlinespace[0.75em] \multicolumn{5}{l}{\textit{Total effect on male students:} Treatment $+$ Treatment $\times$ male student} \\ \hspace{10pt} $\sum \hat{\beta}$" "\hspace{10pt} P-value")
					  fmt(%9.3f %9.3f))
					  
				star(* 0.10 ** 0.05 *** 0.01)
				b(%9.3f) se(%9.3f)
			;
		#d	cr
	}
	
	file close _all
	
	file open progression using "${master_tab}/promotion_het_gender.tex", text write replace
					
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
		
			 "&(1) &(2) &(3) &(4) 					  							 					   \\ 	  			" _n
			 "&All &5th &6th &10th 					  							 					   \\ 		  \hline" _n	 
			 "\addlinespace[0.25em] \multicolumn{5}{c}{\textbf{Probability of student passing}} 	   \\[0.25em] \hline" _n
			 "\addlinespace[0.25em] `promoted'														     [0.75em] \hline" _n
			 "\addlinespace[0.25em] \multicolumn{5}{c}{\textbf{Probability of student dropping out}}   \\[0.25em] \hline" _n
			 "\addlinespace[0.25em] `dropped'  															 [0.75em] \hline" _n
			 "\addlinespace[0.25em] \multicolumn{5}{c}{\textbf{Probability of student being retained}} \\[0.25em] \hline" _n
			 "\addlinespace[0.25em] `retained' 								 							  		  \hline" _n
			 "\hline \\[-1.8ex]"
		;
	#d	cr
	
	file close progression
	
	* Remove spaces
	filefilter "${master_tab}/promotion_het_gender.tex"			/// 
			   "${master_tab}/tabA5-promotion_het_gender.tex"	///
			   , from("[1em]") to("") replace
	erase 	   "${master_tab}/promotion_het_gender.tex"
	
	* Add link to the file (filefilter does not provide it automatically"
	di as text `"Open final file in LaTeX here: {browse "${master_tab}/tabA5-promotion_het_gender.tex":"${master_tab}/tabA5-promotion_het_gender.tex"}"'

	
******************************** End of do-file ********************************
