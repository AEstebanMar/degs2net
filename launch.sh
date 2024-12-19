#! /usr/bin/env bash

#SBATCH --mem='60gb'
#SBATCH --constraint=cal
#SBATCH --time='10:00:00'
hostname

#source ~soft_bio_267/initializes/init_netanalyzer
source ~soft_bio_267/initializes/init_python

db_path="/mnt/home/users/bio_267_uma/lhurtado/test/databases"

#mkdir -p $db_path

#wget "https://string-db.org/cgi/download?sessionId=bhYDip8oIL59/9606.protein.links.v12.0.txt.gz" -O $db_path'/9606.protein.links.v12.0.txt.gz'
#gzip -d $db_path'/9606.protein.links.v12.0.txt.gz'


stringDB=$db_path'/9606.protein.links.v12.0.txt'
#cut -f 1,2,3 $stringDB > string_parsed_file.txt # en este archivo particular no es necesario porque solo tiene 3 columnas

#Cambiar códigos de STRING a ENSEMBLID

#wget "https://string-db.org/cgi/download?sessionId=bhYDip8oIL59/9606.protein.aliases.v12.0.txt.gz" -O $db_path'/9606.protein.aliases.v12.0.txt.gz'
#gzip -d $db_path'/9606.protein.aliases.v12.0.txt.gz'

grep 'Ensembl_gene' $db_path'/9606.protein.aliases.v12.0.txt' > $db_path'/dictionary_ENSP_ENSG'

#grep 'Ensembl_gene' 9606.protein.aliases.v12.0.txt > dictionary_ENSP_ENSG

dict=$db_path'/dictionary_ENSP_ENSG'

standard_name_replacer -i $stringDB -I $dict -s ' ' -c 1,2 -f 1 -t 2 | sed -E "s/ /\t/g" | tail -n+2 > $db_path'/nodes_score.txt'

#standard_name_replacer -i 9606.protein.links.v12.0.txt -I dictionary_ENSP_ENSG -s ' ' -c 1,2 -f 1 -t 2 | sed -E "s/ /\t/g" | tail -n+2 > nodes_score.txt

text2binary_matrix -i $db_path'/nodes_score.txt' -t pair -O bin -o net

#text2binary_matrix -i nodes_score.txt -t pair -O bin -o net

extract_subgraph.py -i net.npy -n net.lst -s DEG_list -o subgraph.txt

netanalyzer -i subgraph.txt -f pair -b louvain

# we get the following file: louvain_discovered_clusters.txt. We will then use aggregate_column_data from cmdtabs to get each ID cluster 
# followed by all of its genes separated by comas. 

aggregate_column_data -i louvain_discovered_clusters.txt -x 1 -a 2 -s ',' > $db_path'/clusters_aggregated.txt'

#aggregate_column_data -i louvain_discovered_clusters.txt -x 1 -a 2 -s ',' > clusters_aggregated.txt

# Once clusters are aggregated, we will use clusters_to_enrichment.R to do a functional analysis:
source ~soft_bio_267/initializes/init_degenes_hunter # mejor aquí o arriba con los demás?

clusters_to_enrichment.R -i $db_path'/clusters_aggregated.txt' -w 16 -o functional_results -f MF,BP,CC,KEGG,Reactome -k ENSEMBL -O "Human"

#sed -E "s/ /\t/g" results.txt > nodes_score.txt
exit
