##ptg22_50_296_100000_abs.bed and ptg22_50_296_100000.matrix are obtained from HiC-pro results
##ptg22_50_296.utg_to_ctg.map are generated by map_utg_to_ctg.pl with Hifiasm results files *.p_ctg.noseq.gfa *.p_utg.noseq.gfa


##draw Hi-C heatmap for contigs
../../matrix2heatmap.py ptg22_50_296_100000_abs.bed ptg22_50_296_100000.matrix 10

##Detect assembly errors in contigs by Hi-C heatmap and unitig breaking points
perl ../../asm_error_check.pl ptg22_50_296_100000_abs.bed ptg22_50_296_100000.matrix ptg22_50_296.utg_to_ctg.map > ptg22_50_296.check

##Detect assembly errors in contigs by only Hi-C heatmap, if the unitig data is not available
perl ../../asm_error_check.pl ptg22_50_296_100000_abs.bed ptg22_50_296_100000.matrix  > ptg22_50_296.check2


