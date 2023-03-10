#!/bin/bash

sampleID="$1"
mttype="$2" # snp or indel
reference="$3" # mm10 or hg19
somaticbam="$4"
germlinebam="$5"
#panelofnormal="$6" #../31_1_PanelOfNormal_SPark/mm10_b6_4_190226.4s.q0Q0.chr1.mpileup.indel.edit.gz
#below 2 args are optional input for invitro 
#motherbam="$7"
#motherID="$8"

case $3 in
	mm10)	species="mouse";;
	hg19)	species="human";;
esac
case $2 in
	snp)	temp_mttype="snv";;
	indel)	temp_mttype="indel";;
esac


outDir=$(dirname $1)
log=$outDir/$1.$2.annot.log

echo $1 $2 $3 $4 $5 > $log
echo varscan somatic filtering >> $log
(python /home/mjkim/mjkim_universal_filter/01_universe_filter/00_varscan_somaticfilter_mj.py /home/mjkim/exercise_221125/06_VarScan2/$1.varscan.$2.vcf) &>> $log || { c=$?;echo "Error";exit $c; }
echo done >> $log
echo unzip vcf.gz file >>$log
(gzip -dc /home/mjkim/exercise_221125/03_strelka2/$1/results/variants/somatic."$temp_mttype"s.vcf.gz > /home/mjkim/mjkim_universal_filter/01_universe_filter/somatic."$temp_mttype"s.vcf) &>> $log || { c=$?;echo "Error";exit $c; }
echo "done" >>$log
#gz 압축해제 안하면 byte형식 때문에 에러났음
echo "start: union of pass call in varscan2 somatic & strelka2" >>$log
(python /home/mjkim/mjkim_universal_filter/01_universe_filter/00_vcf_combination_by_Youk_$2_mj.py $1 $species 2 /home/mjkim/mjkim_universal_filter/01_universe_filter/somatic."$temp_mttype"s.vcf /home/mjkim/exercise_221125/06_VarScan2/$1.varscan.$2.somatic.vcf) &>> $log || { c=$?;echo "Error";exit $c; }
echo "done" >>$log
rm /home/mjkim/mjkim_universal_filter/01_universe_filter/somatic."$temp_mttype"s.vcf
echo "initial annotation" >> $log
(sh /home/mjkim/mjkim_universal_filter/01_universe_filter/sypark_PointMt_annot_filter/PointMt_annot.sh $1_$2_union_2.vcf $4 $5 /home/mjkim/mjkim_universal_filter/01_universe_filter/sypark_PointMt_annot_filter/src $3) &>> $log || { c=$?;echo "Error";exit $c; }
echo "done" >>$log
#echo "panel of normal annotation" >> $log
#(python /home/users/jhyouk/81_filter_test_LADC/11_universe_filter/02_AddNpanelToVCF_"$2".py $1_$2_union_2.readinfo.readc.rasmy.vcf $6 PanelofNormal $species) &>> $log || { c=$?;echo "Error";exit $c; }
#echo "done" >>$log
#echo "filter1 using sample and germline information"  >>$log
#(python /home/users/jhyouk/81_filter_test_LADC/11_universe_filter/03_$2_filter1.py $1_$2_union_2.readinfo.readc.rasmy_PanelofNormal.vcf) &>> $log || { c=$?;echo "Error";exit $c; } #b6

#from here, invitro culture only"
#echo "annotation of mother cell info"
#(sh /home/users/jhyouk/81_filter_test_LADC/11_universe_filter/sypark_PointMt_annot_filter/motherinfo_PointMt_annot.sh $1_$2_union_2.readinfo.readc.rasmy_PanelofNormal.filter1.vcf $4 $7 /home/users/jhyouk/81_filter_test_LADC/11_universe_filter/sypark_PointMt_annot_filter/src $3) &>> $log || { c=$?;echo "Error";exit $c; }
#echo "done"
#echo "filter2 using mother information"
#(python /home/users/jhyouk/81_filter_test_LADC/11_universe_filter/05_$2_filter2_motherinfo.py $1_$2_union_2.readinfo.readc.rasmy_PanelofNormal.filter1.readc.rasmy.vcf $4 $1.mpileup.100kbcov.covstat $7 $8.mpileup.100kbcov.covstat) &>> $log || { c=$?;echo "Error";exit $c; }
#echo "done"
