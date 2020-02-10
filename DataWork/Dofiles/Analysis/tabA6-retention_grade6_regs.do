
/*******************************************************************************
*  Project:				PIP													   *												   
*																 			   *
*  PURPOSE:  			Estimate effect of retention on schooling outcomes	   *
*  WRITTEN BY:  	  	Matteo Ruzzante [mruzzante@worldbank.org]			   *
*  Last time modified:  August 2019											   *
*																			   *
********************************************************************************

	** OUTLINE:			Prepare data
						Store regression results
						Plot coefficients
						Export table
							
	** REQUIRES:   		"${master_dt_fin}/RN_students_panel.dta"
						
	** CREATES:	   		Table A6: Impact of 6th Grade Retention on Student Achievent
						"${master_fig}/tabA6-retention_grade6_regs.png"
			
	** NOTES:
	
* ---------------------------------------------------------------------------- *
* 									Prepare data	   					   	   *
* ---------------------------------------------------------------------------- */
	
	* Load full panel
	use 	"${master_dt_fin}/RN_students_panel.dta", clear
	
	* Keep only 6th graders in 2011
	sort	inep_student 							  year
	by 		inep_student: keep if student_grade[1] == 6
			
	* Count year of completed schooling (not considering 2017 as we don't know where they ended up in 2018)
	egen	schooling   = max(student_grade) if inrange(year, 2011, 2016), by(inep_student)
	
	* Subtract one year if student dropped out in that grade
	replace schooling   = schooling - 1  	 if dropped_once == 1
						
	* Collapse data
	keep if year == 2011
	drop	year

	
//We regress the probability of dropping out once in the student carrer and
//years of schooling with retention in 2011
* ---------------------------------------------------------------------------- *
* 							Store regression results	   					   *
* ---------------------------------------------------------------------------- *
	
	foreach outcomeVar in dropped_once schooling {
		
		if "`outcomeVar'" == "dropped_once" 	 {
			local xTitle 	 "Percentage points"
			local xLab	 	 "xscale(range(0.2 0.3)) xlabel(0.2(0.05)0.3)"
		}	
		if "`outcomeVar'" == "schooling"		 {
			local xTitle 	 "Years of education"
			local xLab	 	 ""
		}
		
		* OLS
		* ---
		reg	   `outcomeVar' 	   retained , 					   cl(inep)
		est 	store 			   ols_`outcomeVar'
		estadd  scalar N_cl  	 = e(N_clust)
		estadd  local  schoolFE ""
		estadd  local  classFE  ""
		local   obs				 = e(N)		  
		di 	   `obs'
		
		* School fixed effects
		* --------------------
		reghdfe `outcomeVar' 	   retained , abs(inep) 		   cl(inep)
		est 	store 		 	   schoolFE_`outcomeVar'
		estadd  scalar N_cl  	 = e(N_clust)
		estadd  local schoolFE 	   "\checkmark"
		estadd  local classFE  	   ""
		
		* Class fixed effects
		* --------------------
		reghdfe `outcomeVar' 	   retained , abs(inep inep_class) cl(inep_class)
		est 	store 		 	   classFE_`outcomeVar'
		estadd  scalar N_cl  	 = e(N_clust)
		estadd  local schoolFE 	   "\checkmark"
		estadd  local classFE  	   "\checkmark"
	}
	
* ---------------------------------------------------------------------------- *	
* 						Export results in tabular format					   *
* ---------------------------------------------------------------------------- *

	#d	;
		esttab 	ols_dropped_once schoolFE_dropped_once classFE_dropped_once
				ols_schooling	 schoolFE_schooling	   classFE_schooling
				
				using "${master_tab}/retention_grade6_regs.tex",
				
				replace tex
				se nocons fragment
				nodepvars nonumbers nomtitles nolines
				noobs nonotes alignment(c)
				coeflabel(retained "\addlinespace[0.75em] Retention in 2011")
				stats(	  N N_cl r2_a schoolFE classFE,
				  lab(	  "\addlinespace[0.75em] Number of observations"
					      "Number of clusters"
						  "Adjusted R-squared"
						  "\addlinespace[0.75em] School fixed effects"
						  "Class fixed effects")
				  fmt(0 0 %9.3f %9.3f %9.3f)
					 )
				star(* 0.10 ** 0.05 *** 0.01)
				b(%9.3f) se(%9.3f)
				
				 prehead("&\multicolumn{3}{c}{\textbf{Dropout}}&\multicolumn{3}{c}{\textbf{Years of completed schooling}} \\"
						 "\cmidrule(lr){2-4} \cmidrule(lr){5-7}"
						 "&(1) &(2) &(3) &(4) &(5) &(6) \\ \hline"
					    )
				 postfoot("[0.25em] \hline \hline \\ [-1.8ex]")	
		;
	#d	cr
	
	* Clean up table
	filefilter  "${master_tab}/retention_grade6_regs.tex"  			///
				"${master_tab}/tabA6-retention_grade6_regs.tex", 	///
				from("[1em]") to("") replace	
	erase 		"${master_tab}/retention_grade6_regs.tex" 	
	
	* Add link to the file (filefilter does not provide it automatically)
	di as text `"Open final file in LaTeX here: {browse "${master_tab}/tabA6-retention_grade6_regs.tex":${master_tab}/tabA6-retention_grade6_regs.tex}"'

	
******************************** End of do-file ********************************
