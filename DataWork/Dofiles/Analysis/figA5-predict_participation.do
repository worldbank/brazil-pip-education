
/*******************************************************************************
*  Project:				PIP													   *												   
*																 			   *
*  PURPOSE:  			Predict test participation							   *		  
*  WRITTEN BY:  	  	Matteo Ruzzante [mruzzante@worldbank.org]			   *
*  Last time modified:  August 2019											   *
*																			   *
********************************************************************************

	** OUTLINE:			Prepare data
						Plot graph
	
	** REQUIRES:   		"${master_dt_fin}/master_studentlevel.dta"
						
	** CREATES:	   		Figure A5: IDEB by Participation to Socio-Emotional Test and Treatment
						"${master_fig}/figA5-predict_participation.png"
			
* --------------------------------------------------------------------------- */
	
	* Load master data at the student level
	use "${master_dt_fin}/master_studentlevel", clear
				
	* Reset estimates and file handles
	est  clear
	file close _all
	
	* Chech that variable 'n_alunos' is correct
	bys	   inep				  : gen test = _N
	assert school_N_students ==     test
	drop 				 		    test
	
	* Identify number of students in classes which were assigned to socio-emotional tests
	egen socio 			= rowmean(agreeab_c consc_c extrav_c neurot_c openness_c)
	egen class_assigned = max(!mi(socio)), by(inep turma)
	
	bys  inep turma: gen class_N_students = _N
		
	* Manually generate percentage of non-missing socio-emotional skills and test scores
	foreach var in socio proficiencia_media {
		
		if "`var'" == "socio" 				{
			local condition "if class_assigned == 1"
			local classId	"turma"
			local countVar  "class_N_students"
		}
		if "`var'" == "proficiencia_media"	{
			local condition ""
			local classId	""
			local countVar  "school_N_students"
		}
		
		egen 	  all_missing_`var'	=   min(missing(`var')) 			, by(inep)
		
		egen	count_missing_`var' = 		  count(`var')  `condition' , by(inep `classId')			 
		gen       pct_missing_`var' = count_missing_`var' / `countVar'
				
		distinct inep if all_missing_`var'
		distinct inep if all_missing_`var' & school_treated == 0
		distinct inep if all_missing_`var' & school_treated == 1
	}
	
		sum 	  pct_missing*
	
	tempfile test_takers
	save	`test_takers'
	
* ---------------------------------------------------------------------------- *	

	local 		 schoolIdentifiers 	inep school_treated polo grade strata
	local 		 schoolVars			school_N_students school_internet school_library school_science_lab school_location
	local        rateVars			promotion_rate_2015 dropout_rate_2015 		//retention_rate_2015
	
	collapse (mean) IDEB* all_missing_* `schoolVars' `rateVars', by(`schoolIdentifiers')
	
	* Define IDEB indicator of interest:
	* As we are only interested in the grades which were treated, and some schools have both EF1 and EF2,
	* we will assign the EF1 score to 5th grade schools and EF2 to 6th grade schools.
	* We do not have information on EM (only for 2017)
	gen 	IDEB_2015 = .
	replace IDEB_2015 = IDEB_EF1_2015 if grade == 5
	replace IDEB_2015 = IDEB_EF2_2015 if grade == 6
	
	recode	  	   all_missing_socio (0 = 1) (1 = 0)
	
	gen   part_T = all_missing_socio == 1 & school_treated == 1
	gen   part_C = all_missing_socio == 1 & school_treated == 0
	gen   miss_T = all_missing_socio == 0 & school_treated == 1
	gen   miss_C = all_missing_socio == 0 & school_treated == 0
		
	reg   IDEB_2015 part_T part_C miss_T miss_C, rob nocons
	local part_T = "T{subscript:p} = " + string(_b[part_T], "%9.2f")
	local part_C = "C{subscript:p} = " + string(_b[part_C], "%9.2f")
	local miss_T = "T{subscript:m} = " + string(_b[miss_T], "%9.2f")
	local miss_C = "C{subscript:m} = " + string(_b[miss_C], "%9.2f")
	
	test  part_T + part_C 	 = miss_T + miss_C
	local part_miss 		 = string(`r(p)', "%9.2f")
	
	test  part_T + miss_T 	 = part_C + miss_C
	local treat_control 	 = string(`r(p)', "%9.2f")
	
	test  part_T 			 = part_C
	local part_treat_control = string(`r(p)', "%9.2f")
	
	#d	;
		gr bar IDEB_2015 , over(all_missing_socio, relab(1 "Missing" 2 "Participating"))
						   asyvar
						   
							    bar( 1, color(eltblue*0.45))
							    bar( 2, color(eltblue))
						 /*blab(bar, format(%9.2f))*/
						   
						   ytitle(IDEB)
						   over(school_treated   , relab(1 "Control" 2 "Treatment"))
						   
						   yscale(nofextend)
						   
						   ${graphOptions}
						   graphregion(margin(t+24))
						   
						   text(4.05 14.5 "`miss_C'")
						   text(4.40 32.5 "`part_C'")
						   text(3.90 67   "`miss_T'")
						   text(4.5  87   "`part_T'")
						   
						   text(5.75 50 "{bf:Group comparisons (t-test)}"
										"H{subscript:0} (T{subscript:p} + T{subscript:m} = C{subscript:p} + C{subscript:m}): p = `treat_control'"
										"H{subscript:0} (T{subscript:p} + C{subscript:p} = T{subscript:m} + C{subscript:m}): p = `part_miss'"
										"H{subscript:0} (T{subscript:p} = C{subscript:p}): p = `part_treat_control'"
										,
										justification(left) linegap(1.5)
										fcolor(white) margin(b+2 t+2 l+1.5 r+1)
										box
								)
		;
	#d	cr
	
	gr export "${master_fig}/figA5_predict_participation.png", replace as(png) width(5000)
	
	
******************************** End of do-file ********************************
