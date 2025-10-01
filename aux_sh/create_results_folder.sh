#! /usr/bin/env bash


execution_parameters=$1
execution_folder=$2
dataset_names=`cut -f 1 execution_parameters`

mkdir -p $results_folder/integrated $results_folder/datasets

echo -e "ENSEMBL_CODE\tLogFC\tGENE_SYMBOL\tDATASET" > $results_folder/datasets/ncRNA_annotated_merged
echo -e "ENSEMBL_CODE\tLogFC\tGENE_SYMBOL\tDATASET" > $results_folder/datasets/top_genes_merged
echo -e "CAUSAL_GENE\tSCORE\tNORMALIZED_SCORE\tRANK\tUNIQ_RANK\tSEED_GROUP\tDATASET" > $results_folder/datasets/ranked_clusters_merged
echo -e "CAUSAL_GENE\tSCORE\tNORMALIZED_SCORE\tRANK\tUNIQ_RANK\tSEED_GROUP\tGENE_SYMBOL\tDATASET" > $results_folder/datasets/noncluster_ranked_top_genes_merged
echo -e "CLUSTER_ID\tGENE_SYMBOLS\tDATASET" > $results_folder/datasets/cluster_genes_id_merged

for folder in `ls $execution_folder | grep -v _file`
do
	if [ -s $execution_folder"/"$folder/"tracker" ]
	then
		folder_name=`cat $execution_folder"/"$folder/tracker`
		out_integrated="$results_folder/integrated/$folder_name"
		out_dataset="$results_folder/datasets/$folder_name"
		mkdir -p $out_integrated $out_dataset $out_dataset/files
		if [ -s $execution_folder"/"$folder/"ranked_genes_all_candidates" ]
		then
			cp $execution_folder"/"$folder/ranked_genes_all_candidates $out_integrated
		fi
		if [ -s $execution_folder"/"$folder/"network_umap.html" ]
		then
			cp $execution_folder"/"$folder/network_umap.html $out_integrated
		fi
		if [ -s $execution_folder"/"$folder/functional_results/clusters_func_report.html ]
		then
			cp $execution_folder"/"$folder/functional_results/clusters_func_report.html $out_integrated
	    fi
	    if [ -s $execution_folder"/"$folder/"DEG_list" ]
	    then
	    	cp $execution_folder"/"$folder/DEG_list $results_folder/datasets/$folder_name/files
	    fi
		if [ -s $execution_folder"/"$folder/"ncRNA_annotated" ]
	    then
	    	cat $execution_folder"/"$folder/ncRNA_annotated >> $results_folder/datasets/ncRNA_annotated_merged
	    fi
	    if [ -s $execution_folder"/"$folder/"ranked_clusters" ]
	    then
	    	cat $execution_folder"/"$folder/ranked_clusters >> $results_folder/datasets/ranked_clusters_merged
	    fi
	    if [ -s $execution_folder"/"$folder/"noncluster_ranked_top_genes" ]
	    then
	    	cat $execution_folder"/"$folder/noncluster_ranked_top_genes >> $results_folder/datasets/noncluster_ranked_top_genes_merged
	    fi
	    if [ -s $execution_folder"/"$folder/"cluster_genes" ]
	    then
	    	cat $execution_folder"/"$folder/cluster_genes >> $results_folder/datasets/cluster_genes_id_merged
	    fi    
	fi
	    if [ -s $execution_folder"/"$folder/"all_DEGs_ranked_top_genes" ]
	    then
	    	cp $execution_folder"/"$folder/all_DEGs_ranked_top_genes $results_folder/integrated/all_DEGs_ranked_top_genes	
	    fi	
	   	if [ -s $execution_folder"/"$folder/"network_all.html" ]
	    then
	    	cp $execution_folder"/"$folder/network_all.html $results_folder/integrated
	    fi	
done

for dataset in $dataset_names
do
cat $execution_folder/grep_0000/top_overexp_annotated_$dataset >> $results_folder/datasets/top_genes_merged
cat $execution_folder/grep_0000/top_underexp_annotated_$dataset >> $results_folder/datasets/top_genes_merged
done

for name in $dataset_names
do
	out_dataset="$results_folder/datasets/$name"
	mkdir -p $out_dataset $out_dataset/files
	path=`grep -w $name execution_parameters | cut -f 2 | xargs dirname`
	cp $path/../DEG_report.html $out_dataset
	cp $path/../functional_enrichment/functional_report.html $out_dataset
	cp $path/../../../mapping_reports/mapping_report.html $out_dataset
	cp $path/../../../mapping_reports/metric_table $out_dataset/files/metric_table_$name
	#arreglar el bodrio de arriba cuando este mas libre
	#meto lista diferenciales
done

