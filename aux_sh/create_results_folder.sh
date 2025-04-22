#! /usr/bin/env bash


execution_parameters=$1
execution_folder=$2
dataset_names=`cut -f 1 execution_parameters`

mkdir -p $results_folder/integrated $results_folder/datasets


for folder in `ls $execution_folder | grep -v _file`
do
	if [ -s $execution_folder"/"$folder/"tracker" ]
	then
		folder_name=`cat $execution_folder"/"$folder/tracker`
		out_integrated="$results_folder/integrated/$folder_name"
		mkdir -p $out_integrated
		if [ -s $execution_folder"/"$folder/"ranked_genes_all_candidates" ]
		then
			cp $execution_folder"/"$folder/ranked_genes_all_candidates $out_integrated
		fi
		if [ -s $execution_folder"/"$folder/"network_umap.html" ]
		then
			cp $execution_folder"/"$folder/network_umap.html $out_integrated
	    fi
	fi
done


for name in $dataset_names
do
	out_dataset="$results_folder/datasets/$name"
	mkdir -p $out_dataset
	path=`grep -w $name execution_parameters | cut -f 2 | xargs dirname`
	cp $path/../DEG_report.html $out_dataset
	cp $path/../functional_enrichment/functional_report.html $out_dataset
	cp $path/../../../mapping_reports/mapping_report.html $out_dataset
	cp $path/../../../mapping_reports/metric_table $out_dataset
done

