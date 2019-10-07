task create_binary_ped {

	File pedfile
	String bin_pedfile_name = "ped_bin"
	String memory

	command {
		$MMAP \
			--ped ${pedfile} \
			--compute_binary_relationship_matrix_by_groups \
			--binary_output_filename ${bin_pedfile_name}
	}

	runtime {
		docker: "kwesterman/mmap-workflow:0.1"
		memory: "${memory} GB"
		continueOnReturnCode: [0, 1]
	}

	output {
		File out = "${bin_pedfile_name}"
	}
}

#task create_binary_gen {
#
#	File dosefile
#	Int dosefile_skip_fields
#	String bin_genfile_name = "geno_bin"
#	String memory
#
#	command {
#		$MMAP \
#			--write_binary_genotype_file \
#			--csv_input_filename ${dosefile} \
#			--num_skip_fields ${dosefile_skip_fields} \
#			--binary_output_filename ${bin_genfile_name}
#	}
#
#	runtime {
#		docker: "kwesterman/mmap-workflow:0.1"
#		memory: "${memory} GB"	
#	}
#	
#	output {
#		File out = "${bin_genfile_name}"
#	}
#}

task run_interaction {

	File pedfile
	File bin_pedfile
	File phenofile
	String? phenotype_id
	String trait
	String covars
	String interaction_var
	File bin_dosefile
	String memory

	command {
		$MMAP \
			--ped ${pedfile} \
			--read_binary_covariance_file ${bin_pedfile} \
			--empirical_sandwich \
			--phenotype_filename ${phenofile} \
			${"--phenotype_id " + phenotype_id} \
			--trait ${trait} \
			--covariates ${covars} \
			--gxe_interaction ${interaction_var} \
			--binary_genotype_filename ${bin_dosefile} \
			--file_suffix results
	}

	runtime {
		docker: "kwesterman/mmap-workflow:0.1"
		memory: "${memory} GB"	
	}

	output {
		File out = "${trait}.results.mle.pval.slim.csv"
	}
}

workflow run_mmap {

	Array[File] bin_dosefiles
	#Int dosefile_skip_fields = 8
	File phenofile
	String? phenotype_id
	File pedfile
	String trait = "BMI"
	String covars = "SEX"
	String interaction_var = "SEX"
	String memory

	call create_binary_ped {
		input:
			pedfile = pedfile,
			memory = memory
	}

	#call create_binary_gen {
	#	input:
	#		dosefile = dosefile,
	#		dosefile_skip_fields = dosefile_skip_fields,
	#		memory = memory
	#}

	scatter (bin_dosefile in bin_dosefiles) {
		call run_interaction {
			input:
				pedfile = pedfile,
				bin_pedfile = create_binary_ped.out,
				phenofile = phenofile,
				phenotype_id = phenotype_id,
				trait = trait,
				covars = covars,
				bin_dosefile = bin_dosefile,
				interaction_var = interaction_var,
				memory = memory
		}
	}	

	#output {
	#	File outfile = run_interaction.out
	#}
}
