#! /usr/bin/env bash

source ~soft_bio_267/initializes/init_autoflow
source ~soft_bio_267/initializes/init_netanalyzer
source ~soft_bio_267/initializes/init_python
module=$1
current_dir=`pwd`
aux_sh=$current_dir/aux_sh
export db_path=$current_dir/databases
export download_path=$db_path/download


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
	echo 'Launching text2binary'
	sbatch $aux_sh'/launch_text2binary_matrix'
	echo 'Done :)'
fi

# We now create the interactome  



if [ "$module" == "1" ]; then
	echo "Obtaining DEG_list"





#text2binary_matrix -i nodes_score.txt -t pair -O bin -o net

# To extract a subgraph from the protein interactome, we provide a list of prevalent genes from the project we are analyzing

extract_subgraph.py -i net.npy -n net.lst -s DEG_list -o subgraph.txt

# We now apply netanalyzer to generate clusters of genes: 

netanalyzer -i subgraph.txt -f pair -b louvain

# we get the following file: louvain_discovered_clusters.txt. We will then use aggregate_column_data from cmdtabs to get each ID cluster 
# followed by all of its genes separated by comas. 

aggregate_column_data -i louvain_discovered_clusters.txt -x 1 -a 2 -s ',' > $db_path'/clusters_aggregated.txt'

#aggregate_column_data -i louvain_discovered_clusters.txt -x 1 -a 2 -s ',' > clusters_aggregated.txt

# Once clusters are aggregated, we will use clusters_to_enrichment.R to do a functional analysis:
source ~soft_bio_267/initializes/init_degenes_hunter # mejor aquí o arriba con los demás?

clusters_to_enrichment.R -i $db_path'/clusters_aggregated.txt' -w 16 -o functional_results -f MF,BP,CC,KEGG,Reactome -k ENSEMBL -O "Human"

#sed -E "s/ /\t/g" results.txt > nodes_score.txt

