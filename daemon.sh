#! /usr/bin/env bash

source ~soft_bio_267/initializes/init_autoflow
module=$1
config_daemon=$current_dir/config_daemon
aux_sh=$current_dir/aux_sh
source $config_daemon
export PATH=$aux_sh:$PATH
export db_path=$current_dir/databases

if [ "$module" == "0" ] ; then
	echo "Downloading databases"
	mkdir -p $db_path
	# We will first download the protein-protein interaction database from STRING. We will then change STRING IDs to ENSEMBL IDs to create a dictionary ENSEMBL-protein to ENSEMBL-gene.
	wget "https://string-db.org/cgi/download?sessionId=bhYDip8oIL59/9606.protein.links.v12.0.txt.gz" -O $db_path'/9606.protein.links.v12.0.txt.gz'
	gzip -d $db_path'/9606.protein.links.v12.0.txt.gz'
	wget "https://string-db.org/cgi/download?sessionId=bhYDip8oIL59/9606.protein.aliases.v12.0.txt.gz" -O $db_path'/9606.protein.aliases.v12.0.txt.gz'
	gzip -d $db_path'/9606.protein.aliases.v12.0.txt.gz'
	# Changing STRING IDs to ENSEMBL IDs
	grep 'Ensembl_gene' $db_path'/9606.protein.aliases.v12.0.txt' > $db_path'/dictionary_ENSP_ENSG'
	#grep 'Ensembl_gene' 9606.protein.aliases.v12.0.txt > dictionary_ENSP_ENSG
	dict=$db_path'/dictionary_ENSP_ENSG'
	# We now have our dictionary ready. We will now use standard_name_replacer to translate the string interactome database into ENSEMBL genes IDs.
	standard_name_replacer -i $stringDB -I $dict -s ' ' -c 1,2 -f 1 -t 2 | sed -E "s/ /\t/g" | tail -n+2 > $db_path'/nodes_score.txt'
	#standard_name_replacer -i 9606.protein.links.v12.0.txt -I dictionary_ENSP_ENSG -s ' ' -c 1,2 -f 1 -t 2 | sed -E "s/ /\t/g" | tail -n+2 > nodes_score.txt
	sbatch launch_text2binary_matrix
fi

# We now create the interactome  


stringDB=$db_path'/9606.protein.links.v12.0.txt'

if [ "$module" == "1" ]; then
	echo "Processing databases"


source ~soft_bio_267/initializes/init_netanalyzer
source ~soft_bio_267/initializes/init_python


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

