#!/bin/bash
# Checking if the number of input parameters is correct (2)
if [ ! $# == 9 ]; then
  echo "$#"
  echo "Please, give the structure, the desired mode to follow, the direction of the minimization (0 or 1), the optim executable the path to the executables and the executable for the structure recongnition!"
  exit
fi


# Reading the input
file_name=$1
mode=$2
direction=$3
optim=$4
str_rec=$5
path=$6
initial_energy=$7
en_barrier_cut=$8
en_diff_cut=$9

#echo "$mode"


# Importing the required functions
. $path/functions.bash

# Creating the directory associated with the initial structure if it does not already exist
number_atoms=`head -n1 $file_name` #richiede leggere da disco. Non mi piace
init_name=${file_name%.xyz}
init_min_energy=`awk 'NR==2 {print $1}' $file_name` #anche questo si può passare una volta sola per data struttura
freq=$[ 3 * $number_atoms - 6 ]
mode_number=$[ $mode + $direction * $freq ]
mode_name=`zeros $mode_number`
dir_name=Str_${file_name%.xyz}
mkdir -p $dir_name
cd $dir_name

# Creating the directory of the mode / If it exists, stops
mkdir $mode_name &> /dev/null
res=`echo rv: $? | awk '{print $2}'`
if [ $res -ne 0 ] ; then 
   echo "Directory $dir_name/$mode_name already exists. Please erase the directory associated with the mode to proceed. Aborting."
   date
   exit
fi

###### Doing the mode following in one direction ######
cd $mode_name
cp ../../masses .
cp ../../in.lammps .
cp ../../data.lammps .
if [ $direction -eq 0 ] ; then
   echo "MODE $mode $mode" > odata
else
   echo "MODE -$mode -$mode" > odata
fi
cat ../../Template-odata.ev >> odata
awk 'NR > 2 {print $2, $3, $4}' ../../$file_name > start    
output_name=${file_name%.xyz}-$mode_name.out
$optim > $output_name

# Checking for convergence
grep "CONVERGED" $output_name &> /dev/null
res=`echo rv: $? | awk '{print $2}'`
if [ $res -ne 0 ] ; then
   # Cleaning
   rm -f odata masses odata.new odata.read points.final vector.dump *out 
   exit
fi


###### End of mode following ######

###### Starting 1st minimization ######
# Doing with the first pushoff, repeat with another one if the str. does not come back

# Saving the energy and the structure on file
outxyz_name=${file_name%.xyz}-$mode_name.xyz
first_name=${file_name%.xyz}-$mode_name.temp
cat ../../$file_name > $outxyz_name 									    #Struttura iniziale per i file min-TS-min
echo $number_atoms >> $outxyz_name          
cp $output_name original_$output_name
cp odata.new original_odata.new    

en_TStemp=`grep Energy $output_name | awk -v OFMT=%12.1f '{print $6}' | tail -n1`                                         #TS per file min TS min. 
en_TS="$en_TStemp"0
#str_inertia=`awk -v OFMT=%.12g '/inertia/{getline; print $4 "    " $5 "    " $6}' $output_name | tail -n1`
str_inertia=`awk -v OFMT=%12.5f '/inertia/{getline; printf "%12.5f%4s%12.5f%4s%12.5f\n", $4, "    ", $5, "    ", $6}' $output_name | tail -n1`
echo $en_TS $str_inertia >> $outxyz_name
grep -A $number_atoms "POINTS" ./odata.new | awk 'NR > 1 {print}' >> $outxyz_name                           #Fine

# Minimizing the transition state following the direction of the eigenvector
echo "MODE -1" > odata
cat ../../Template-odata.min >> odata
tail -n $number_atoms $outxyz_name | awk '{print $2, $3, $4}' > start
$optim >> $output_name

# Saving the final structure     #A me sembra che qui faccia due volte la stessa cosa salvando le stesse info prima appese a outxyz_name, poi dentro a first
# Forse ho risolto
echo $number_atoms >> $outxyz_name
str_energy1=`grep Energy $output_name | awk '{print $6}' | tail -n1`
#str_inertia1=`awk -v OFMT=%12.5g '/inertia/{getline; print $4 "    " $5 "    " $6}' $output_name | tail -n1`
str_inertia1=`awk -v OFMT=%12.5f '/inertia/{getline; printf "%12.5f%4s%12.5f%4s%12.5f\n", $4, "    ", $5, "    ", $6}' $output_name | tail -n1`
echo $str_energy1 $str_inertia1 >> $outxyz_name
grep -A $number_atoms "POINTS" ./odata.new | awk 'NR > 1 {print}' >> $outxyz_name

echo $number_atoms > $first_name
echo $str_energy1 $str_inertia1 >> $first_name
grep -A $number_atoms "POINTS" ./odata.new | awk 'NR > 1 {print}' >> $first_name  

# Doing it again in the other direction  
cd ..
freq2=$[ 6 * $number_atoms - 12 ]
mode_number2=$[ $mode + $direction * $freq + $freq2 ]
mode_name2=`zeros $mode_number2`
rm -rf $mode_name2
mkdir $mode_name2
cd $mode_name2
cp ../../masses .
cp ../../in.lammps .
cp ../../data.lammps .
cp ../$mode_name/vector.dump .

# Saving the energy and the structure on file
outxyz_name2=${file_name%.xyz}-$mode_name2.xyz
last_name=${file_name%.xyz}-$mode_name2.temp
head_number=$[ 2 * $number_atoms + 4 ]
head -n $head_number ../$mode_name/$outxyz_name > $outxyz_name2

# Minimizing the transition state again but following the direction of the eigenvector
output_name2=${file_name%.xyz}-$mode_name2.out
echo "MODE 1" > odata
cat ../../Template-odata.min >> odata
tail -n $number_atoms $outxyz_name2 | awk '{print $2, $3, $4}' > start
$optim >> $output_name2

# Saving the final structure
echo $number_atoms >> $outxyz_name2
str_energy2=`grep Energy $output_name2 | awk '{print $6}' | tail -n1`
str_inertia2=`awk -v OFMT=%12.5g '/inertia/{getline; printf "%12.5f%4s%12.5f%4s%12.5f\n", $4, "    ", $5, "    ", $6}' $output_name2 | tail -n1`
echo $str_energy2 $str_inertia2 >> $outxyz_name2
grep -A $number_atoms "POINTS" ./odata.new | awk 'NR > 1 {print}' >> $outxyz_name2

echo $number_atoms > $last_name  
echo $str_energy2 $str_inertia2 >> $last_name
grep -A $number_atoms "POINTS" ./odata.new | awk 'NR > 1 {print}' >> $last_name   

###### End of 1st minimization ######

# Checking if one of the two structures found is the initial structure
$str_rec ../../$file_name ../$mode_name/$first_name 0.0001 0.5 > T_${file_name%.xyz}-$mode_name
$str_rec ../../$file_name ../$mode_name2/$last_name 0.0001 0.5 > T_${file_name%.xyz}-$mode_name2
if grep -q similar "T_${file_name%.xyz}-$mode_name"; then
   repeat=0
   if [ "$( echo "$en_TS - $init_min_energy > $en_barrier_cut" | bc )" -eq 0 ] && [ "$( echo "$str_energy2 - $initial_energy > $en_diff_cut" | bc )" -eq 0 ]; then
      echo "$init_name $mode_name2 $str_energy2 $str_inertia2 $en_TS $mode_name2/$outxyz_name2" >> ../candidates
   fi
elif grep -q similar "T_${file_name%.xyz}-$mode_name2"; then 
   repeat=0
   if [ "$( echo "$en_TS - $init_min_energy > $en_barrier_cut" | bc )" -eq 0 ] && [ "$( echo "$str_energy1 - $initial_energy > $en_diff_cut" | bc )" -eq 0 ]; then
      echo "$init_name $mode_name $str_energy1 $str_inertia1 $en_TS $mode_name/$outxyz_name" >> ../candidates
   fi
else
   repeat=1
fi

###### Starting 2nd minimization if necessary ######
if [ $repeat = 1 ]; then
   cd ../$mode_name
   cp original_$output_name $output_name
   cp original_odata.new odata.new
   cat ../../$file_name > $outxyz_name
   echo $number_atoms >> $outxyz_name
   echo $str_energy $str_inertia >> $outxyz_name
   grep -A $number_atoms "POINTS" ./odata.new | awk 'NR > 1 {print}' >> $outxyz_name
   echo "MODE -1" > odata
   cat ../../Template-odata.min2 >> odata
   tail -n $number_atoms $outxyz_name | awk '{print $2, $3, $4}' > start
   $optim >> $output_name
   echo $number_atoms >> $outxyz_name
   str_energy1=`grep Energy $output_name | awk '{print $6}' | tail -n1`
   str_inertia1=`awk -v OFMT=%12.5g '/inertia/{getline; printf "%12.5f%4s%12.5f%4s%12.5f\n", $4, "    ", $5, "    ", $6}' $output_name | tail -n1`
   echo $str_energy1 $str_inertia1 >> $outxyz_name
   grep -A $number_atoms "POINTS" ./odata.new | awk 'NR > 1 {print}' >> $outxyz_name
   echo $number_atoms > $first_name
   echo $str_energy1 $str_inertia1 >> $first_name
   grep -A $number_atoms "POINTS" ./odata.new | awk 'NR > 1 {print}' >> $first_name  
   cd ..
   rm -rf $mode_name2
   mkdir $mode_name2
   cd $mode_name2
   cp ../../masses .
   cp ../../in.lammps .
   cp ../../data.lammps .
   mv ../$mode_name/vector.dump .
   echo "MODE 1" > odata
   cat ../../Template-odata.min2 >> odata
   head -n $head_number ../$mode_name/$outxyz_name > $outxyz_name2
   tail -n $number_atoms $outxyz_name2 | awk '{print $2, $3, $4}' > start    
   $optim >> $output_name2
   echo $number_atoms >> $outxyz_name2
   str_energy2=`grep Energy $output_name2 | awk '{print $6}' | tail -n1`
   str_inertia2=`awk -v OFMT=%12.5g '/inertia/{getline; printf "%12.5f%4s%12.5f%4s%12.5f\n", $4, "    ", $5, "    ", $6}' $output_name2 | tail -n1`
   echo $str_energy2 $str_inertia2 >> $outxyz_name2
   grep -A $number_atoms "POINTS" ./odata.new | awk 'NR > 1 {print}' >> $outxyz_name2
   echo $number_atoms > $last_name  
   echo $str_energy2 $str_inertia2 >> $last_name
   grep -A $number_atoms "POINTS" ./odata.new | awk 'NR > 1 {print}' >> $last_name   
#fi
###### End of 2nd minimization ######

   # Again - Checking if one of the two structures found is the initial structure
   $str_rec ../../$file_name ../$mode_name/$first_name 0.0001 0.5 > T_${file_name%.xyz}-$mode_name
   $str_rec ../../$file_name ../$mode_name2/$last_name 0.0001 0.5 > T_${file_name%.xyz}-$mode_name2
   if grep -q similar "T_${file_name%.xyz}-$mode_name"; then
      repeat=0
      if [ "$( echo "$en_TS - $init_min_energy > $en_barrier_cut" | bc )" -eq 0 ] && [ "$( echo "$str_energy2 - $initial_energy > $en_diff_cut" | bc )" -eq 0 ]; then
         echo "$init_name $mode_name2 $str_energy2 $str_inertia2 $en_TS $mode_name2/$outxyz_name2" >> ../candidates
      fi
   elif grep -q similar "T_${file_name%.xyz}-$mode_name2"; then
      repeat=0
      if [ "$( echo "$en_TS - $init_min_energy > $en_barrier_cut" | bc )" -eq 0 ] && [ "$( echo "$str_energy1 - $initial_energy > $en_diff_cut" | bc )" -eq 0 ]; then
         echo "$init_name $mode_name $str_energy1 $str_inertia1 $en_TS $mode_name/$outxyz_name" >> ../candidates
      fi
   else
      repeat=1
   fi

fi


###### NEB in case we still did not find the original minima ######
((natm1=$number_atoms-1))
((natp2=$number_atoms+2))
if [ $repeat = 1 ]; then

   #echo "debug $mode $direction NEB"

   cd ../$mode_name
   cat ../../Template-odata.neb > odata
   tail -n $number_atoms ../../$file_name | awk '{print $2,$3,$4}' > start
   $path/image.bash $path $outxyz_name guess.xyz > /dev/null # Guess for the NEB
   awk '{print $2,$3,$4}' $first_name | tail -n $number_atoms > finish   
   $optim > out_neb_$mode_name

   # Checking if there is a minima separating these 2 in principle 1st neighbors
   change=0
   badmin=0
   str_max=17
   str_nr=$str_max
   en_pseudomin=1.0
   str_pseudomin=-1
   for ii in {1..16} #16 perché 17 è il numero di immagini nella NEB
   do
     ij=$[ $ii + 1 ]
     #leggi e fai la differenza fra due entrate consecutive
     num1=`sed "${ii}q;d" neb.EofS | awk '{print $2}'`
     num2=`sed "${ij}q;d" neb.EofS | awk '{print $2}'`
     #se la differenza è maggiore di 0 
     #echo "$num2 - $num1"
     if [ "$( echo "$num2 - $num1 > -0.00001" | bc )" -eq 1 ] ; then
       # se change non è più zero -> ci sono minimi in mezzo perché ha iniziato a crescere dopo che decresceva
       if [ $change -eq 1 ] ; then
         badmin=1
         en_pseudomin=$num1
         str_pseudomin=$ii
         change=2
       fi
     #altrimenti poni change=1
     else
       if [ $change -eq 0 ] ; then
         change=1
         en_TS=$num1
         str_nr=$ii
       fi
     fi
   done

   if [ "$( echo "$en_pseudomin > 0.0" | bc )" -eq 1 ] ; then
     en_pseudomin=$num2
     str_pseudomin=$ij
   fi

   echo "$number_atoms" > pseudo_min.xyz
   echo "$en_pseudomin" >> pseudo_min.xyz
   ((str_pseudomin=$str_pseudomin-1))
   ((limit1=$str_pseudomin*$natp2))
   ((limit1=$limit1+3))
   ((limit2=$limit1+$natm1))
   sed -n "$limit1,$limit2 p" neb.0.xyz >> pseudo_min.xyz  

   output_name3="ts_neb_out"

   echo "MODE 0" > odata
   cat ../../Template-odata.ev >> odata
   ((str_nr=$str_nr-1))
   ((limit1=$str_nr*$natp2))
   ((limit1=$limit1+3))
   ((limit2=$limit1+$natm1))
   sed -n "$limit1,$limit2 p" neb.0.xyz | awk '{print $2,$3,$4}' > start  
   $optim > $output_name3

   grep "CONVERGED" $output_name3 &> /dev/null
   res=`echo rv: $? | awk '{print $2}'`
   if [ $res -ne 0 ] ; then
     # Cleaning
   rm -f odata masses odata.new odata.read points.final vector.dump *out
   exit
   fi

   output_name5="min_ts_neb_1_out" 										# o gio riguardatelo che ho fatto sicuramente un casino della madonna

   cat ../../$file_name > $outxyz_name
   echo "$number_atoms" >> $outxyz_name
   #cp $output_name original_$output_name
   cp odata.new original_odata.new
   en_TStemp=`grep Energy $output_name3 | awk -v OFMT=%12.1f '{print $6}' | tail -n1`                                         #TS per file min TS min. 
   en_TS="$en_TStemp"0
   echo $en_TS >> $outxyz_name
   grep -A $number_atoms "POINTS" ./odata.new | awk 'NR > 1 {print}' >> $outxyz_name

   echo "MODE -1" > odata
   cat ../../Template-odata.min >> odata
   tail -n $number_atoms $outxyz_name | awk '{print $2,$3,$4}' > start
   $optim >> $output_name5

   first_name2="first_name2"
   last_name2="last_name2"

   str_energy5=`grep Energy $output_name5 | awk '{print $6}' | tail -n1`
   str_inertia5=`awk -v OFMT=%12.5f '/inertia/{getline; printf "%12.5f%4s%12.5f%4s%12.5f\n", $4, "    ", $5, "    ", $6}' $output_name5 | tail -n1`

   echo $number_atoms > $first_name2
   echo $str_energy5 $str_inertia5 >> $first_name2
   grep -A $number_atoms "POINTS" ./odata.new | awk 'NR > 1 {print}' >> $first_name2

   output_name6="min_ts_neb_2_out"
   
   echo "MODE 1" > odata
   cat ../../Template-odata.min >> odata
   tail -n $number_atoms $outxyz_name | awk '{print $2,$3,$4}' > start
   $optim >> $output_name6

   str_energy6=`grep Energy $output_name6 | awk '{print $6}' | tail -n1`
   str_inertia6=`awk -v OFMT=%12.5f '/inertia/{getline; printf "%12.5f%4s%12.5f%4s%12.5f\n", $4, "    ", $5, "    ", $6}' $output_name6 | tail -n1`

   echo $number_atoms > $last_name2
   echo $str_energy6 $str_inertia6 >> $last_name2
   grep -A $number_atoms "POINTS" ./odata.new | awk 'NR > 1 {print}' >> $last_name2

   $str_rec pseudo_min.xyz $first_name2 0.1 5.0 > T_${file_name%.xyz}-$first_name2
   $str_rec pseudo_min.xyz $last_name2 0.1 5.0 > T_${file_name%.xyz}-$last_name2   

   if grep -q similar "T_${file_name%.xyz}-$first_name2"; then
      if [ "$( echo "$en_TS - $init_min_energy > $en_barrier_cut" | bc )" -eq 0 ] && [ "$( echo "$str_energy5 - $initial_energy > $en_diff_cut" | bc )" -eq 0 ]; then
         cat $first_name2 >> $outxyz_name
         echo "$init_name $mode_name $str_energy5 $str_inertia5 $en_TS $mode_name/$outxyz_name" >> ../candidates
      fi
   elif grep -q similar "T_${file_name%.xyz}-$last_name2"; then
      if [ "$( echo "$en_TS - $init_min_energy > $en_barrier_cut" | bc )" -eq 0 ] && [ "$( echo "$str_energy6 - $initial_energy > $en_diff_cut" | bc )" -eq 0 ]; then
         cat $last_name2 >> $outxyz_name
         echo "$init_name $mode_name $str_energy6 $str_inertia6 $en_TS $mode_name/$outxyz_name" >> ../candidates
      fi
   else
      rm -f *
   fi


   # Repeating to the other mode
   cd ../$mode_name2   
   cat ../../Template-odata.neb > odata
   tail -n $number_atoms ../../$file_name | awk '{print $2,$3,$4}' > start
   $path/image.bash $path $outxyz_name2 guess.xyz > /dev/null # Guess for the NEB
   awk '{print $2,$3,$4}' $last_name | tail -n $number_atoms > finish
   $optim > out_neb_$mode_name2
   # Checking if there is a minima separating these 2 in principle 1st neighbors

   change=0
   badmin=0
   str_max=17
   str_nr=$str_max
   en_pseudomin=1.0
   str_pseudomin=-1
   for ii in {1..16} #16 perché 17 è il numero di immagini nella NEB
   do
     ij=$[ $ii + 1 ]
     #leggi e fai la differenza fra due entrate consecutive
     num1=`sed "${ii}q;d" neb.EofS | awk '{print $2}'`
     num2=`sed "${ij}q;d" neb.EofS | awk '{print $2}'`
     #se la differenza è maggiore di 0 
     #echo "$num2 - $num1"
     if [ "$( echo "$num2 - $num1 > -0.00001" | bc )" -eq 1 ] ; then
       # se change non è più zero -> ci sono minimi in mezzo perché ha iniziato a crescere dopo che decresceva
       if [ $change -eq 1 ] ; then
         badmin=1
         en_pseudomin=$num1
         str_pseudomin=$ii
         change=2
       fi
     #altrimenti poni change=1
     else
       if [ $change -eq 0 ] ; then
         change=1
         en_TS=$num1
         str_nr=$ii
       fi
     fi
   done

   if [ "$( echo "$en_pseudomin > 0.0" | bc )" -eq 1 ] ; then
     en_pseudomin=$num2
     str_pseudomin=$ij
   fi

   echo "$number_atoms" > pseudo_min.xyz
   echo "$en_pseudomin" >> pseudo_min.xyz
   ((str_pseudomin=$str_pseudomin-1))
   ((limit1=$str_pseudomin*$natp2))
   ((limit1=$limit1+3))
   ((limit2=$limit1+$natm1))
   sed -n "$limit1,$limit2 p" neb.0.xyz >> pseudo_min.xyz

   output_name3="ts_neb_out"

   echo "MODE 0" > odata
   cat ../../Template-odata.ev >> odata
   ((str_nr=$str_nr-1))
   ((limit1=$str_nr*$natp2))
   ((limit1=$limit1+3))
   ((limit2=$limit1+$natm1))
   sed -n "$limit1,$limit2 p" neb.0.xyz | awk '{print $2,$3,$4}' > start
   $optim > $output_name3

   grep "CONVERGED" $output_name3 &> /dev/null
   res=`echo rv: $? | awk '{print $2}'`
   if [ $res -ne 0 ] ; then
     # Cleaning
   rm -f odata masses odata.new odata.read points.final vector.dump *out
   exit
   fi

   output_name5="min_ts_neb_1_out"                                                                              # o gio riguardatelo che ho fatto sicuramente un casino della madonna

   cat ../../$file_name > $outxyz_name2
   echo "$number_atoms" >> $outxyz_name2
   #cp $output_name original_$output_name
   cp odata.new original_odata.new
   en_TStemp=`grep Energy $output_name3 | awk -v OFMT=%12.1f '{print $6}' | tail -n1`                                         #TS per file min TS min. 
   en_TS="$en_TStemp"0
   echo $en_TS >> $outxyz_name2
   grep -A $number_atoms "POINTS" ./odata.new | awk 'NR > 1 {print}' >> $outxyz_name2

   echo "MODE -1" > odata
   cat ../../Template-odata.min >> odata
   tail -n $number_atoms $outxyz_name2 | awk '{print $2,$3,$4}' > start
   $optim >> $output_name5

   first_name2="first_name2"
   last_name2="last_name2"

   str_energy5=`grep Energy $output_name5 | awk '{print $6}' | tail -n1`
   str_inertia5=`awk -v OFMT=%12.5f '/inertia/{getline; printf "%12.5f%4s%12.5f%4s%12.5f\n", $4, "    ", $5, "    ", $6}' $output_name5 | tail -n1`

   echo $number_atoms > $first_name2
   echo $str_energy5 $str_inertia5 >> $first_name2
   grep -A $number_atoms "POINTS" ./odata.new | awk 'NR > 1 {print}' >> $first_name2

   output_name6="min_ts_neb_2_out"

   echo "MODE 1" > odata
   cat ../../Template-odata.min >> odata
   tail -n $number_atoms $outxyz_name2 | awk '{print $2,$3,$4}' > start
   $optim >> $output_name6

   str_energy6=`grep Energy $output_name6 | awk '{print $6}' | tail -n1`
   str_inertia6=`awk -v OFMT=%12.5f '/inertia/{getline; printf "%12.5f%4s%12.5f%4s%12.5f\n", $4, "    ", $5, "    ", $6}' $output_name6 | tail -n1`

   echo $number_atoms > $last_name2
   echo $str_energy6 $str_inertia6 >> $last_name2
   grep -A $number_atoms "POINTS" ./odata.new | awk 'NR > 1 {print}' >> $last_name2

   $str_rec pseudo_min.xyz $first_name2 0.1 5.0 > T_${file_name%.xyz}-$first_name2
   $str_rec pseudo_min.xyz $last_name2 0.1 5.0 > T_${file_name%.xyz}-$last_name2

   if grep -q similar "T_${file_name%.xyz}-$first_name2"; then
      if [ "$( echo "$en_TS - $init_min_energy > $en_barrier_cut" | bc )" -eq 0 ] && [ "$( echo "$str_energy5 - $initial_energy > $en_diff_cut" | bc )" -eq 0 ]; then
         cat $first_name2 >> $outxyz_name2
         echo "$init_name $mode_name2 $str_energy5 $str_inertia5 $en_TS $mode_name2/$outxyz_name2" >> ../candidates
      fi
   elif grep -q similar "T_${file_name%.xyz}-$last_name2"; then
      if [ "$( echo "$en_TS - $init_min_energy > $en_barrier_cut" | bc )" -eq 0 ] && [ "$( echo "$str_energy6 - $initial_energy > $en_diff_cut" | bc )" -eq 0 ]; then
         cat $last_name2 >> $outxyz_name2
         echo "$init_name $mode_name2 $str_energy6 $str_inertia6 $en_TS $mode_name2/$outxyz_name2" >> ../candidates
      fi
   else
      rm -f *
   fi

fi
###### End of a NEB ######

# Cleaning
rm -rf odata masses odata.new odata.read points.final vector.dump *out T_* *.temp orig* out* finish guess.xyz neb*
cd ../$mode_name
rm -rf odata masses odata.new odata.read points.final vector.dump *out T_* *.temp orig* out* finish guess.xyz neb*

