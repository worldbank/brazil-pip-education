*! version 0.1 17MAR2019 Matteo Ruzzante mruzzante@worldbank.org

// Block difference-in-means regression

cap prog drop blockdim
	prog def  blockdim

	syntax varname(numeric) [if] [in],			/// Outcome variable - must be numeric
												///
		TREATment(varname numeric)        		/// Treatment variable - must be categorical
		STRATA(varname numeric)					/// Strata variable - must be categorical
												///
	   [COVARiates(varlist numeric ts fv)]   	/// Control variables - must not be string
	   [*]                           			/// Regression options
	
	// Set minimum version for this command
	version 11
	
	// Preserve current dataset
	preserve
	
		qui {
			
			// Remove observations excluded by if and in
			marksample touse , novarlist
			keep if   `touse'
						
			// Test that the variable listed in treatment() and strata() is not the outcome var
			if `:list treatment in varlist' != 0 {
				noi di as error "{phang}The variable `treatment' listed in option {inp:treatment(`treatment')} is also listed in the outcome variables which is not allowed.{p_end}"
				error 198
			}
			if `:list strata in varlist' != 0 {
				noi di as error "{phang}The variable `strata' listed in option {inp:strata(`strata')} is also listed in the outcome variables which is not allowed.{p_end}"
				error 198
			}
			
			// Test that the variables listed in covariates() are not the outcome var or used as treatment or strata var
			foreach covar in `covariates' {
				if `:list covar in varlist' != 0 {
					noi di as error "{phang}The variable `covar' listed in option {inp:covariates(`covariates')} is also listed in the outcome variables which is not allowed.{p_end}"
					error 198
				}
				if `:list covar in treatment' != 0 {
					noi di as error "{phang}The variable `covar' listed in option {inp:covariates(`covariates')} is also listed as treatment variable in option {inp:treatment(`treatment')} which is not allowed.{p_end}"
					error 198
				}
				if `:list covar in strata' != 0 {
					noi di as error "{phang}The variable `covar' listed in option {inp:covariates(`covariates')} is also listed as strata variable in option {inp:strata(`strata')} which is not allowed.{p_end}"
					error 198
				}
			}
			
			// Generate temporary variables for regression
			tempvar  mean_block 		///
						n_block 		///
						  block_dim
			
			egen 	`mean_block' 	 =  mean(`varlist') , by(`strata') 	//mean of the strata
			egen	   `n_block' 	 = count(`varlist') , by(`strata')	//number of non-missing observations per strata
			 gen  	  	 `block_dim' = 		 `varlist'  - 			   ///difference-in-mean
					`mean_block'
		}
		
		/*
		local 	regOptions `options'
		local suestOptions ""
		
		// If 'vce' or 'cluster' is specified, remove it from options, and only use it later in 'suest'
		if strpos(`options', "vce(" ) > 0 {
		   local   regOptions 	regexr(`options', "\(vce(.)+\)", "")
		   local suestOptions subinstr(`options', "\(vce(.)+\)", "")
		}
		
		if strpos(`options', "cl("		) > 0 | ///
		   strpos(`options', "clu(" 	) > 0 | ///
		   strpos(`options', "clus(" 	) > 0 | ///
		   strpos(`options', "cluster(" ) > 0 {
		   
		   local   regOptions regexr(`options', "\(cluster(.)+\)", "")
		   local suestOptions regexr(`options', "\(cluster(.)+\)", "")
		} 
		*/
		
		
		// Run the blocked regression and store estimates
		reg `block_dim' i.`treatment' `covariates' `if' `in' [aw=`n_block'], `options'
		
		/*
		est store DIM
		
		// Run fixed effect regression and store estimates
	qui	reg `varlist'   i.`treatment' i.`strata' `covariates' `if' `in'    , `regoptions'
		est store FE
		
		// Combine estimates
		suest DIM FE, `suestOptions'
		*/
		
	// Restore original data
	restore
	
// End
end

// Whoop whoop!
