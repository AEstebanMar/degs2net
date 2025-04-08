#! /usr/bin/env bash

report_folder=$current_dir/reports
execution_parameters=$current_dir/execution_parameters
dataset_names=`cut -f 1 execution_parameters`

mkdir -p $report_folder/integrated $report_folder/datasets

for name in $dataset_names
do
	out_dataset="$report_folder/datasets/$name"
	mkdir -p $out_dataset
	path=`grep -w $name execution_parameters | cut -f 2 | xargs dirname`
	cp $path/../DEG_report.html $out_dataset
	cp $path/../functional_enrichment/functional_report.html $out_dataset
	cp $path/../../../mapping_reports/mapping_report.html $out_dataset
	cp $path/../../../mapping_reports/metric_table $out_dataset
done

