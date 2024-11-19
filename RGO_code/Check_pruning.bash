#!/bin/bash
# Checking if the number of input parameters is correct (2)
if [ ! $# == 3 ]; then
  echo "Please, give the full path of the folder that contains the executables (sem, OPTIM, struct_compare.x, freq.bash, get_new_struct.bash), the cut in the energy barrier/energy differences."
  exit
fi

# Reading the input                                  
localdir=`pwd`
full_path=$1
energy_barrier_cut=$2 
energy_dif_cut=$3 

# Importing the required functions
. $full_path/functions.bash
str_rec=$full_path/struct_compare.x

# Starting
echo "Creating a list of pruned structures..."
echo "Reading the exectuables from the folder $full_path."
echo "Cuts in the energy used = $energy_barrier_cut / $energy_dif_cut"

# Checking how many structures exist
cd All_Structures
declare -a XYZ
XYZ=(`ls *xyz`) 
size_XYZ=${#XYZ[*]}
echo "$size_XYZ structures found from previous run! Proceeding..."

# Convenient variables   
initial_energy=`awk 'NR == 2 {print}' ${XYZ[0]}`
number_atoms=`head -n1 ${XYZ[0]}`
number_modes=$[ 12 * $number_atoms - 24 ]
number_tail=$[ $number_atoms + 2 ]
number_energy=$[ $number_atoms + 4 ]
number_energy2=$[ 2 * $number_atoms + 6]
cd ..

# Main variables
mkdir -p Pruned_Structures
size_old_struc=0                 

# Main loop
for (( i=0;i<size_XYZ;i++)) do
   echo "Analyzing structure ${XYZ[i]%.xyz}..."
   cd Str_${XYZ[i]%.xyz}
   unset new_struc
   declare -a new_struc 
   new_struc=(`find -name \*.xyz | sort`)
   size_new_struc=${#new_struc[*]}
   for ((j=0;j<size_new_struc;j++)) do
      en1=`awk 'NR==2 {print}' ${new_struc[j]}`
      en2=`awk 'NR=='$number_energy' {print}' ${new_struc[j]}`
      en3=`awk 'NR=='$number_energy2' {print}' ${new_struc[j]}`
      energy_barrier=`echo $en2 - $en1 | bc`
      energy_difference=`echo $en3 - $initial_energy | bc`
      condition1=`echo $energy_barrier '>' $energy_barrier_cut | bc -l`
      condition2=`echo $energy_difference '<' $energy_dif_cut | bc -l`
      if [ $condition1 -eq 1 ] && [ $condition2 -eq 1 ]; then
         # Copying the possible structure to a temporary file
         tail -n $number_tail ${new_struc[j]} > Temporary
         if [ $size_old_struc -eq 0 ] ; then
            cp Temporary ../Pruned_Structures/Pr_`zeros $size_old_struc`
            ((size_old_struc++))
         else
            accept=0
            for ((v=0;v<size_old_struc;v++)) do
               $str_rec Temporary ../Pruned_Structures/Pr_`zeros $v` 0.0001 0.5 > Temporary2
               if grep -q similar "Temporary2" ; then
                  accept=1
                  v=$size_old_struc
               fi
            done
            if [ $accept -eq 0 ]; then
               cp Temporary ../Pruned_Structures/Pr_`zeros $size_old_struc`
               ((size_old_struc++))
            fi
         fi
      fi
   done
   cd ../
done
