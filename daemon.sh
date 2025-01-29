#! /usr/bin/env bash


module=$1
mode=$2
aux_opt=$3
current_dir=`pwd`
aux_sh=$current_dir/aux_sh
source $current_dir/config_daemon
source ~soft_bio_267/initializes/init_autoflow
source ~soft_bio_267/initializes/init_python
export db_path=$current_dir/databases
download_path=$db_path/download


# Module 0 will download the databases, process them and finish by creating the interactome.

if [ "$module" == "0" ] ; then
	echo "Downloading databases"
	mkdir -p $db_path
	# We will first download the protein-protein interaction database from STRING. We will then change STRING IDs to ENSEMBL IDs to create a dictionary ENSEMBL-protein to ENSEMBL-gene.
	wget "https://stringdb-downloads.org/download/protein.links.full.v12.0/9606.protein.links.full.v12.0.txt.gz" -O $download_path'/9606.protein.links.v12.0.txt.gz'
	gzip -d $download_path'/9606.protein.links.v12.0.txt.gz'
	wget "https://stringdb-downloads.org/download/protein.aliases.v12.0/9606.protein.aliases.v12.0.txt.gz" -O $download_path'/9606.protein.aliases.v12.0.txt.gz'
	gzip -d $download_path'/9606.protein.aliases.v12.0.txt.gz'
	# Changing STRING IDs to ENSEMBL IDs
	cut -f 1,2,16 -d ' ' $download_path'/9606.protein.links.v12.0.txt' > $db_path'/human.protein.links.v12.0.txt' # columns that refer to protein1, protein2 and combined_score
	grep 'Ensembl_gene' $download_path'/9606.protein.aliases.v12.0.txt' > $db_path'/dictionary_ENSP_ENSG'
	dict=$db_path'/dictionary_ENSP_ENSG'
	# We now have our dictionary ready. We will now use standard_name_replacer to translate the string interactome database into ENSEMBL genes IDs.
	echo 'Replacing names'
	standard_name_replacer -i $db_path'/human.protein.links.v12.0.txt' -I $dict -s ' ' -c 1,2 -f 1 -t 2 | sed -E "s/ /\t/g" | tail -n+2 > $db_path'/nodes_score.txt'
	echo 'Done :)'
fi

if [ "$module" == "1" ]; then
	mkdir -p exec_degs2net
	execution_parameters=$current_dir/execution_parameters
	datasets=`cut -f 1 $execution_parameters -d "," | tr "\n" ";"`
	echo $input_path
    variables=`echo -e "
    	\\$datasets=$datasets,
    	\\$execution_parameters=$execution_parameters,
    	\\$kernel_path=$exec_path/kernel/netanalyzer_0001,
    	\\$db_path=$db_path,
    	\\$pvalue_cutoff=$pvalue_cutoff,
    	\\$target_genes=$target_genes
    " | tr -d '[:space:]' `
    
    if [ "$mode" == "exec" ] ; then
		echo Launching main workflow
		AutoFlow -w $current_dir/templates/degs2net.af -m '10gb' -c 1 -n 'cal' -V $variables $aux_opt -o exec_degs2net -e -L
	elif [ "$mode" == "check" ] ; then
		flow_logger -w -e exec_degs2net -r all
	elif [ "$mode" == "rescue" ] ; then
		echo Regenerating code
		AutoFlow -w $template -V $variables $aux_opt -o exec_degs2net -v
		echo Launching pending and failed jobs
		flow_logger -w -e exec_degs2net -l -p -b
	fi
fi
