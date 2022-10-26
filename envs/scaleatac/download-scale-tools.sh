#!/bin/sh
srcDir=$(dirname -- "$0")
dir=${1:-"$(readlink -f "${srcDir}/../bin")"}
mkdir -p $dir
echo "Downloading to $dir"
curl http://scale.pub.s3.amazonaws.com/scaleTools/cicd/bcParser/master/220720-g504d44d/bc_parser -o $dir/bc_parser && chmod 755 $dir/bc_parser
curl http://scale.pub.s3.amazonaws.com/scaleTools/cicd/scDedup/master/220815-ge8c8e81/sc_dedup -o $dir/sc_dedup && chmod 755 $dir/sc_dedup
curl http://scale.pub.s3.amazonaws.com/scaleTools/cicd/scCounter/master/220720-g7706c38/sc_counter -o $dir/sc_counter && chmod 755 $dir/sc_counter
