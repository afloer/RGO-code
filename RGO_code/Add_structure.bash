#!/bin/bash
# Checking if the number of input parameters is correct (2)
if [ ! $# == 5 ]; then
  echo "Please, give the full path of the folder that contains the executables (sem, OPTIM, struct_compare.x, freq.bash, get_new_struct.bash), the initial geometry to add to the database and the cut in the energy differences. In addition, the number of processors to be used."
  exit
fi

date

# Reading the input                                  
localdir=`pwd`
full_path=$1
optim=$full_path/OPTIM
str_rec=$full_path/struct_compare.x
freq=$full_path/freq.bash       
get_new=$full_path/get_new_struct.bash
#Sem=$full_path/sem
Sem=sem
energy_barrier_cut=$3 
energy_dif_cut=$4 
number_proc=$5 

# Importing the required functions
. $full_path/functions.bash

# Starting
echo "Starting the code..."
echo "Reading the exectuables from the folder $full_path."
echo "Running on $number_proc processors."
echo "Cuts in the energy used = $energy_barrier_cut / $energy_dif_cut"

# Checking how many structures exist
cd All_Structures
declare -a XYZ_files
XYZ_files=(`ls *xyz`) 
size_XYZ_files=${#XYZ_files[*]}
echo "$size_XYZ_files structures found from previous run! Proceeding..."
cd ..

# Checking if the structure to be added is new to the database
for ((i=0;i<size_XYZ_files;i++)) do
   $str_rec $2 All_Structures/${XYZ_files[i]} 0.0001 0.5 > Temporary-file
   if grep -q similar "Temporary-file" ; then
      echo "Structure to be added is already on the database. It is equal to All_Structures/${XYZ_files[i]}!"
      exit
   fi
done
rm -f Temporary-file

# Step 0 before the loop
initial_energy=`awk 'NR == 2 {print}' $2`
number_atoms=`head -n1 $2`
number_freq=$[3*$number_atoms-6]
number_modes=$[ 12 * $number_atoms - 24 ]

# Finding out the initial indice
initial_ind=$[$size_XYZ_files*$number_modes+1]
initial_lab=`zeros $initial_ind`

# Copying the first file to the results directory and preparing to start
cp $2 $initial_lab.xyz
cp $initial_lab.xyz All_Structures
num_tot_structures=$[$size_XYZ_files+1]
num_old_structures=$size_XYZ_files
XYZ_files[size_XYZ_files]=$initial_lab.xyz
((size_XYZ_files++))

# Starting EV-following for this new structure
step=0
finish=0
# Starting the main loop
while [ $finish -eq 0  ]; do
   # For each new structure, make the mode following analysis
   for (( i=num_old_structures;i<num_tot_structures;i++)) do
   echo "Analyzing structure ${XYZ_files[i]%.xyz}..."
      cp All_Structures/${XYZ_files[i]} .
      struct_file=${XYZ_files[i]%.xyz}
      for (( l=0;l<2;l++)) do
         for (( j=1;j<=number_freq;j++)) do
            $Sem -j$number_proc $freq $struct_file.xyz $j $l $optim $str_rec $full_path  
#          $freq $struct_file.xyz $j $l $optim $str_rec $full_path
         done
      done
      $Sem --wait

      # Checking how many new structures exist in the given folder and storing them in an array
      cd $localdir/Str_$struct_file
      declare -a new_strut
      new_struc=(`find -name \*.xyz | sort`)
      size_new_struc=${#new_struc[*]}

      # Collecting
      cd ../
      for (( j=0;j<size_new_struc;j++)) do
         $get_new Str_$struct_file ${new_struc[j]} $str_rec $i $initial_energy $energy_barrier_cut $energy_dif_cut $j $full_path 
      done
      rm -f ${XYZ_files[i]}
   done
   num_old_structures=$num_tot_structures
   # Updating the array with the list of xyz files  
   cd $localdir/All_Structures
   XYZ_files=(`ls *.xyz`)
   rm -f Temporary*
   cd ../
   num_tot_structures=${#XYZ_files[*]}
   toperform=$[ $num_tot_structures - $num_old_structures ]
   if [ $num_tot_structures -le $num_old_structures ] ; then
      finish=1
   fi
   echo "Step $step finished. $toperform new structures found. " 
   ((step++))
done
date
