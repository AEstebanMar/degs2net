#! /usr/bin/env bash


module=$1
mode=$2
aux_opt=$3
source ~soft_bio_267/initializes/init_autoflow
source ~soft_bio_267/initializes/init_python

export current_dir=`pwd`
export PATH=$current_dir/aux_sh:$PATH
source $current_dir/config_daemon

export db_path=$current_dir/databases
export results_folder=$current_dir/results
export download_path=$db_path/download


# Module 0 will download the databases, process them and finish by creating the interactome.

if [ "$module" == "0" ] ; then
	echo "Downloading databases"
	mkdir -p $download_path
	# We will first download the protein-protein interaction database from STRING and keep the experimental data. 
	# We will then change STRING IDs to ENSEMBL IDs to create a dictionary ENSEMBL-protein to ENSEMBL-gene.
	wget "https://stringdb-downloads.org/download/protein.links.detailed.v12.0/9606.protein.links.detailed.v12.0.txt.gz" -O $download_path'/9606.protein.links.detailed.v12.0.txt.gz'
	gzip -d $download_path'/9606.protein.links.detailed.v12.0.txt.gz'
	wget "https://stringdb-downloads.org/download/protein.aliases.v12.0/9606.protein.aliases.v12.0.txt.gz" -O $download_path'/9606.protein.aliases.v12.0.txt.gz'
	gzip -d $download_path'/9606.protein.aliases.v12.0.txt.gz'
	# Creating ENSP to ENSG dictionary
	grep 'Ensembl_gene' $download_path'/9606.protein.aliases.v12.0.txt' > $db_path'/dictionary_ENSP_ENSG'
	dict=$db_path'/dictionary_ENSP_ENSG'
	# We now have our dictionary ready. We will now use standard_name_replacer to translate the string interactome database into ENSEMBL genes IDs.
	echo 'Replacing names'
	standard_name_replacer -i $download_path'/9606.protein.links.detailed.v12.0.txt' -I $db_path'/dictionary_ENSP_ENSG' -s ' ' -c 1,2 -f 1 -t 2 | sed -E "s/ /\t/g" | awk -F"\t" '$7>='$confidence | awk '{FS=OFS="\t"}{print $1, $2, $7}' | tail -n+2 > $db_path'/string_network.txt'
	echo 'Done :)'
fi


if [ "$module" == "1" ]; then
	wf_execution=$current_dir/exec_degs2net
	mkdir -p $wf_execution
	execution_parameters=$current_dir/execution_parameters
	datasets=`cut -f 1 $execution_parameters | tr "\n" ";"`
	echo $input_path
    variables=`echo -e "
    	\\$datasets=$datasets,
    	\\$execution_parameters=$execution_parameters,
    	\\$db_path=$db_path,
    	\\$pvalue_cutoff=$pvalue_cutoff,
    	\\$results_folder=$results_folder,
    	\\$wf_execution=$wf_execution
    " | tr -d '[:space:]' `
    
    if [ "$mode" == "exec" ] ; then
		echo Launching main workflow
		AutoFlow -w $current_dir/templates/degs2net.af -m '10gb' -c 1 -n 'cal' -V $variables $aux_opt -o $wf_execution -e -L
	elif [ "$mode" == "check" ] ; then
		flow_logger -w -e $wf_execution -r all
	elif [ "$mode" == "rescue" ] ; then
		echo Regenerating code
		AutoFlow -w $template -V $variables $aux_opt -o $wf_execution -v
		echo Launching pending and failed jobs
		flow_logger -w -e $wf_execution -l -p -b
	fi
fi


if [ "$module" == "2" ]; then
	echo Generating reports folder
	create_results_folder.sh $current_dir/execution_parameters $wf_execution
fi

if [ "$module" == "3" ]; then
	source ~soft_bio_267/initializes/init_python
	source ~soft_bio_267/initializes/init_htmlreportR
	def_res=$current_dir/results
	datasets=`cut -f 1 $current_dir/execution_parameters`
	create_metric_table $wf_execution/all_metrics dataset $def_res/all_metrics_table -c $def_res/corrupted_metrics_data
	rm $def_res/all_rankings $def_res/all_samples
	for dataset in DMD_fib; do
		ranked_file=$results_folder"/integrated/"$dataset"/ranked_genes_all_candidates"
		awk "{print $dataset "\t" $0}" $ranked_file >> $def_res/all_rankings
		sample_metrics=$results_folder"/datasets/"$dataset"/metric_table"
		awk "{print $dataset "\t" $0}" $sample_metrics >> $def_res/all_samples
	done
	html_report.R -d "$def_res/all_metrics_table,$def_res/all_rankings,$def_res/all_samples" -t templates/degs2net.txt -o $def_res/degs2net.html
fi
