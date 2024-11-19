#!/bin/bash
# Checking if the number of input parameters is correct (2)
if [ ! $# == 5 ]; then
  echo "Please, give the full path of the folder that contains the executables (sem, OPTIM, struct_compare.x, freq.bash, get_new_struct.bash), the file xyz containint the geometry and the cut in the energy differences. In addition, the number of processors to be used."
  exit
fi

date

# Reading the input                                  
localdir=`pwd`
full_path=$1
optim=$full_path/OPTIM
str_rec=$full_path/struct_compare.x
freq=$full_path/freq.bash       
#Sem=$full_path/sem
Sem=sem
energy_barrier_cut=$3 
energy_dif_cut=$4 
number_proc=$5 

# Starting
echo "Starting the code..."
echo "Reading the exectuables from the folder $full_path."
echo "Running on $number_proc processors."
echo "Cuts in the energy used = $energy_barrier_cut / $energy_dif_cut"
echo "Analyzing structure $2..." 

# Step 0 before the loop
mkdir -p Temporary_Folder
cd Temporary_Folder
cp ../$2 999000000.xyz
cp ../Template* .
cp ../masses  .

# Copying the first structure - If main folder exists, stops
mkdir -p All_Structures
declare -a XYZ_files
XYZ=(`ls ../All_Structures/*xyz`) 
size_XYZ=${#XYZ[*]}
echo "$size_XYZ structures found from previous run! Proceeding..."

# Getting the first energy and setting up convenient variables
initial_energy=`awk 'NR == 2 {print}' 999000000.xyz`
number_atoms=`head -n1 999000000.xyz`
number_freq=$[3*$number_atoms-6]
number_modes=$[ 12 * $number_atoms - 24 ]
number_tail=$[ $number_atoms + 2 ]
number_energy=$[ $number_atoms + 4 ]
number_energy2=$[ 2 * $number_atoms + 6]

# Make the mode following analysis
echo "Making EV-analysis for $2..."
for (( l=0;l<2;l++)) do
   for (( j=1;j<=number_freq;j++)) do
      $Sem -j$number_proc $freq 999000000.xyz $j $l $optim $str_rec $full_path     
#     $freq 999000000.xyz $j $l $optim $str_rec $full_path
   done
done
#$Sem --wait

# Checking how many new structures exist in the given folder and storing them in an array
cd $localdir/Temporary_Folder/Str_999000000
declare -a new_struc
new_struc=(`find -name \*.xyz | sort`)
size_new_struc=${#new_struc[*]}
echo "EV-analysis finished. $size_new_struc possible paths found. Analyzing them..."

# Comparing the new structures with those from previous run
some=0
limit=$[ $size_XYZ - 1 ]
for (( j=0;j<size_new_struc;j++)) do
   en1=`awk 'NR==2 {print}' ${new_struc[j]}`
   en2=`awk 'NR=='$number_energy' {print}' ${new_struc[j]}`
   en3=`awk 'NR=='$number_energy2' {print}' ${new_struc[j]}`
   barrier=`echo $en2 - $en1 | bc`
   diff=`echo $en3 - $en1 | bc`
   condition1=`echo $barrier '<' $energy_barrier_cut | bc -l`
   condition2=`echo $diff '<' $energy_dif_cut | bc -l`
   tail -n $number_tail ${new_struc[j]} > Temporary
   for (( k=0;k<size_XYZ;k++)) do
      $str_rec Temporary ../${XYZ[k]} 0.0001 0.5 > Temporary2
      if grep -q similar Temporary2 ; then
          label=`echo ${XYZ[k]} | cut -c 19-27`
          if [ $condition1 -eq 1 ] && [ $condition2 -eq 1 ]; then
            some=1
            echo "Structure $2 is connected to $label by a barrier of $barrier and energy difference of $diff"
         fi
         k=$size_XYZ
      fi
      if [ $k -eq $limit ]; then
         if [ $condition1 -eq 1 ] && [ $condition2 -eq 1 ]; then
            some=1
            echo "Structure $2 leads to a new structure with a barrier of $barrier and energy difference of $diff"
         fi
      fi
   done
done

# Finishing
if [ $some -eq 0 ]; then
   echo "Nothing new found. End of analysis."
else
   echo "End of analysis."
fi
cd ../../ 
rm -rf Temporary_Folder
date
