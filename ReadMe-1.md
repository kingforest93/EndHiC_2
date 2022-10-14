## Introduction

**EndHiC is a fast and easy-to-use Hi-C scaffolding tool, using the Hi-C links from contig end regions instead of whole contig regions to assemble large contigs into chromosomal-level scaffolds.** 

**EndHiC takes the HiC-Pro's bin matrix results as input data. After running HiC-Pro, a recommended EndHiC usage for most users is to run endhic.pl with default parameters.** 

## Install and run an example

Download or clone the source code and run EndHiC directly, and a command-line example is shown below:
```
  git clone git@github.com:fanagislab/EndHiC.git

  cd EndHiC/z.testing_data/

  sh work.sh 
```

## 1. Input files (for example, human hifiasm-assembled contigs and the output contact matrix of HiC-Pro)

During the development of EndHiC, we used HiC-Pro v2.11.4 and you can also use the latest version v3.1.0 to process Hi-C sequencing data and get the following matrix files.

- hifiasm.fa.len                
    Includes two column:  contig_id	contig_length	

- humanHiC_100000_abs.bed     
    Generated by Hic-pro, 100-kb bins, bed format file

- humanHiC_100000.matrix        
    Generated by Hic-pro, 100-kb bins, raw matrix file

- humanHiC_100000_iced.matrix   
    Generated by Hic-pro, 100-kb bins, normalized matrix file

## 2. EndHiC programs: (the ranks shows invoking relationship)

endhic.pl							

> endhic_ctgEnd_pipeline.pl

> ctgContact_from_ctgEndContacts.pl
		
> turningpoint_by_lineartransform.pl
		
> scaffold_by_trueCtgContact.pl
		
> cluster_and_classify_GFA.pl
		
> order_and_orient_GFA.pl

### (1) Basic usage [run the above scripts step by step]

run endhic with specified contig end size and specified contact cutoff

step1: calculate the HiC contact values among contigs, using Hi-C links data from fixed-size contig ends
```
ctgContact_from_ctgEndContacts.pl --binsize 100000 --binnum 10 hifiasm.fa.len humanHiC_100000_abs.bed humanHiC_100000.matrix > humanHiC_100000.matrix.100000.10.CtgContact
```

step2: adjust the contig contacts, and perform linear transformation, to find the turning point
```
turningpoint_by_lineartransform.pl humanHiC_100000.matrix.100000.10.CtgContact > humanHiC_100000.matrix.100000.10.CtgContact.adjustTransform 2> humanHiC_100000.matrix.100000.10.CtgContact.turningPoint
```

step3: build contig graph by assigning links to contigs whose contact is larger than a given cutoff, and also satisfy reciprocal best requirement
```
scaffold_by_trueCtgContact.pl   --contacts 147.07 --reciprocalmax  hifiasm.fa.len  humanHiC_100000_iced.matrix.100000.10.CtgContact > humanHiC_100000_iced.matrix.100000.10.CtgContact.overCutoff.1.0.reciprocalMax.gfa 
```

step4: Identify linear and circular topology in the contig graph
```
cluster_and_classify_GFA.pl  humanHiC_100000_iced.matrix.100000.10.CtgContact.overCutoff.1.0.reciprocalMax.gfa > humanHiC_100000_iced.matrix.100000.10.CtgContact.overCutoff.1.0.reciprocalMax.gfa.topology
```

step5: Output cluster results with order and orientation information
```
order_and_orient_GFA.pl --size 2000000 humanHiC_100000_iced.matrix.100000.10.CtgContact.overCutoff.1.0.reciprocalMax.gfa humanHiC_100000_iced.matrix.100000.10.CtgContact.overCutoff.1.0.reciprocalMax.gfa.topology > humanHiC_100000_iced.matrix.100000.10.CtgContact.overCutoff.1.0.reciprocalMax.gfa.cluster
```

### (2) Basic pipeline [run from the above step1 to step5]

run endhic with specified contig end size, in various automatically determined contact cutoff, using Hic-pro raw matrix data
```
endhic_ctgEnd_pipeline.pl --binsize 100000 --binnum 10 hifiasm.fa.len humanHiC_100000_abs.bed humanHiC_100000.matrix
```

run endhic with specified contig end size, in various automatically determined contact cutoff, using Hic-pro normalized matrix data
```
endhic_ctgEnd_pipeline.pl --binsize 100000 --binnum 10 hifiasm.fa.len humanHiC_100000_abs.bed humanHiC_100000_iced.matrix
```

### (3) Standard pipeline [recommend for most users]

Under direcotry 100kb-A/

run endhic with various contig end size, in various automatically determined contact cutoff, using Hic-pro raw and normalized matrix data
```
endhic.pl  hifiasm.fa.len humanHiC_100000_abs.bed humanHiC_100000.matrix humanHiC_100000_iced.matrix
```

### (4) Iterative standard pipeline [if one default round of endhic.pl can't finish]

If a single standard pipeline can't finish the scaffolding task, i.e. the number of resulting clusters is more than that of chromosomes, iterative running of the standard pipeline is recommended. In each loop, the contig end size is increasing. In this way, the problems caused by the repeat sequences on the contig ends will be overcomed.

Below is the second running loop of standard pipeline.

```
Under direcotry 100kb-B/
ln ../100kb-A/humanHiC_100000_abs.bed ./
ln ../100kb-A/humanHiC_100000_iced.matrix ./
ln ../100kb-A/humanHiC_100000.matrix ./
ln ../100kb-A/04.summary_and_merging_results/z.EndHiC.A.results.summary.cluster ./
```

convert the contig bed file to cluster bed file
```
cluster2bed.pl humanHiC_100000_abs.bed z.EndHiC.A.results.summary.cluster  > clusterA_100000_abs.bed  2> clusterA.id.len 
```

run standard endhic pipeline with increasing contig end range
```
endhic.pl --minbinnum 30 --maxbinnum 50 --clustermark B  clusterA.id.len clusterA_100000_abs.bed humanHiC_100000.matrix humanHiC_100000_iced.matrix
```

generate final cluster result file in this loop
```
cluster_merge.pl z.EndHiC.A.results.summary.cluster  04.summary_and_merging_results/z.EndHiC.B.results.summary.transit > 04.summary_and_merging_results/z.EndHiC.B.results.summary.cluster
```

**Note: At most times, Endhic will finish at the chromosomal level scaffolding with one to three running loops. Whether the task is finished or not, we do not suggest running more loops, because as the increasing of contig end size, the signal to noise ratio will drop, the spirit of Endhic do not allow using too larger contig ends.** The recommended endhic parameters in each loop are:

> "endhic.pl --minbinnum 5  --maxbinnum 25  --clustermark A"  (endhic first loop, default)
> 
> "endhic.pl --minbinnum 30 --maxbinnum 50  --clustermark B"  (endhic second loop)
> 
> "endhic.pl --minbinnum 55 --maxbinnum 75  --clustermark C"  (endhic third loop)
> 
> ..........................................................  

## 3. EndHiC output sub-directory and files

### In 01.contig_end_contact_results/

- humanHiC_100000.matrix.*.CtgContact
    Contig contact file, with 7 columns (#CtgId1 CtgId2  EndContact Ctg1Pos Ctg2Pos UsedBinNum1     UsedBinNum2)

- humanHiC_100000.matrix.*.CtgContact.adjustTransform
    Contig contact, adjusted, and linear transformed, to find the turning point

- humanHiC_100000.matrix.*.CtgContact.turningPoint
    Automatically inferred turning point, which will be used as the basic value for the contig contact cutoff

### In 02.GFA_contig_graph_results/

- humanHiC_100000.matrix.*.CtgContact.overCutoff.1.0.gfa
    Contig graph in GFA format, contact value over cutoff, can be viewed in Bandage software

- humanHiC_100000.matrix.*.CtgContact.overCutoff.1.0.reciprocalMax.gfa
    Contig graph in GFA format,  contact value over cutoff, and satisfy reciprocal best, can be viewed in Bandage software

### In 03.cluster_order_orient_results/

- humanHiC_100000.matrix.*.CtgContact.overCutoff.1.0.reciprocalMax.gfa.topology
    Topology of the contig graph, identify linear or circular groups

- humanHiC_100000.matrix.*.CtgContact.overCutoff.1.0.reciprocalMax.gfa.cluster
    Scaffold results, including cluster, order, and orientation information

### In 04.summary_and_merging_results/

- z.EndHiC.A.results.summary
    Summary and analysis results for the first loop, merging all the raw and iced results

- z.EndHiC.A.results.summary.cluster  [Final EndHiC Result]
    Final scaffold results with high robustness, merging all the raw and iced results
    This is recommeded to be the final endhic result.

- z.EndHiC.A.results.summary.cluster.gfa 
    GFA format of the final scaffold results, which can be graphically viewed in Bandage software

#### Instruction of *.summary file:

> Part 1: Number of clusters under each condition

> Part 2: Statistics of all Cluster units

> Part 3: Statistics of merged Cluster units

> Part 4: Statistics of stable (high frequency) cluster units

> Part 5: Statistics of stable cluster units (redundant short contigs removed)

> Part 6: Included contigs, total number, total length 

#### Format of *.cluster file: 

> In total 5 columns
> 
>> column 1: Cluster id, sorted by cluster length

>> column 2: Number of contigs included in this cluster

>> column 3: Cluster length, total length of contigs in this cluster

>> column 4: robustness, i.e. appearance times in the results from various contig end sizes and contact cutoffs
>> 
>> column 5: Included contigs with order and orientation, separated by ";", and "+-" means strands
             e.g. ptg000046l-;ptg000079l+;ptg000058l-;ptg000047l+ (equivalent to ptg000047l-;ptg000058l+;ptg000079l-;ptg000046l+)
>> 	     

## 4. Post-EndHiC programs

### (1) Convert to AGP and Fasta format files

convert cluster format file to AGP format file
```
cluster2agp.pl z.EndHiC.A.results.summary.cluster  hifiasm.fa.len  > scaffolds.agp
```

convert AGP format file to Fasta format file
```
agp2fasta.pl scaffolds.agp  hifiasm.fa > scaffolds.fa
```

### (2) drawing Hi-C heatmap 

draw HiC heatmap for contigs, helpful to find assembly errors in contigs, and break them before running EndHic
```
matrix2heatmap.py humanHiC_1000000_abs.bed humanHiC_1000000.matrix 
```

convert the contig bed file to cluster bed file
```
cluster2bed.pl humanHiC_1000000_abs.bed  z.EndHiC.B.results.summary.cluster > clusterB_1000000_abs.bed  2> clusterB.id.len
```

draw HiC heatmap for endhic scaffolds, helpful to verify the accuracy of EndHic scaffolding
```
matrix2heatmap.py clusterB_1000000_abs.bed humanHiC_1000000.matrix
```

### (3) mapping unclustered short contigs to each cluster

calculate the HiC contact values among contigs, using Hi-C links data from half contig(i.e. max contig end size)
```
perl ../../../ctgContact_from_ctgEndContacts.pl  --binsize 100000  --binnum -1  hifiasm.fa.len  humanHiC_100000_abs.bed  humanHiC_100000.matrix > humanHiC_100000.matrix.halfContig.ctgContact
```

normalize the contig contact by the used bin numbers, only keep the max contact from head vs head, head vs tail, tail vs head, tail vs tail comparisons
```
ctgContact_normalize_distance.pl  --normalize  humanHiC_100000.matrix.halfContig.ctgContact > humanHiC_100000.matrix.halfContig.ctgContact.normalize
```

mapping the unclustered short contigs into Endhic clusters, with specified cutoff
```
shortCtgs_to_cluster.pl --contact 1 --times 2   z.EndHiC.A.results.summary.cluster  hifiasm.fa.len  humanHiC_100000.matrix.halfContig.ctgContact.normalize > shortCtgs.mapped.to.clusters.list
```

## 5. Accuracy verifying programs

### (1) Run endhic using the max contact values from bin pairs of two compared contigs
```
endhic_maxBin_pipeline.pl --binsize 1000000  hifiasm.fa.len humanHiC_100000_abs.bed humanHiC_100000.matrix
```

### (2) Apply Hierarchical clustering algorithm with contig distance converted from Hi-C contact values derived from contig end regions

normalize the contig contact by the used bin numbers, and converted to distance values ranging from 0 to 1
```
ctgContact_normalize_distance.pl humanHiC_100000.matrix.100000.10.CtgContact > humanHiC_100000.matrix.100000.10.CtgContact.distance
```

generate all the middle procedure results of the Hierarchical clustering algorithm
```
hcluster_contigs.pl --verbose -type min humanHiC_100000.matrix.100000.10.CtgContact.distance hifiasm.fa.len > humanHiC_100000.matrix.100000.10.CtgContact.distance.hcluster.one 2> humanHiC_100000.matrix.100000.10.CtgContact.distance.hcluster
```

Find the suitable stop loop, which represents correct chromosomes, by giving expected crhomosome number and minimum chromosome length cutoff
```
hcluster_suitable_stop.pl --chr_num  23 --chr_len  20000000  humanHiC_100000.matrix.100000.10.CtgContact.distance.hcluster  >  humanHiC_100000.matrix.100000.10.CtgContact.distance.hcluster.need
```

### (3) Compare two clusters

only compare the clustering information, not consider order and orientation information
```
cluster_compare.pl  human.contigs.minimap2.cluster  z.EndHiC.A.results.summary.cluster  > z.EndHiC.A.results.summary.cluster.vs.ref
```

### 6. Reference

**Sen Wang, Hengchao Wang, Fan Jiang, Anqi Wang, Hangwei Liu, Hanbo Zhao, Boyuan Yang, Dong Xu, Yan Zhang, Wei Fan. EndHiC: assemble large contigs into chromosomal-level scaffolds using the Hi-C links from contig ends. (2021)**