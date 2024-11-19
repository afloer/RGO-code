#!/bin/bash
# Checking if the number of input parameters is correct (2)
if [ ! $# == 5 ]; then
  echo "Please, give the full path of the folder that contains the executables (sem, OPTIM, struct_compare.x, freq.bash, get_new_struct.bash), the initial geometry and the cut in the energy barrier/energy differences. In addition, the number of processors to be used."
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
get_new=$full_path/get_new_struct.bash
energy_barrier_cut=$3 
energy_dif_cut=$4 
number_proc=$5 

# Restarting
echo "Restarting the code..."
echo "Reading the exectuables from the folder $full_path."
echo "Running on $number_proc processors."
echo "Cuts in the energy used = $energy_barrier_cut / $energy_dif_cut"

# Finding out the number of atoms/loop 
number_atoms=`head -n1 $2`
number_freq=$[3*$number_atoms-6]

# Getting the first energy
initial_energy=`awk 'NR == 2 {print}' $2`

# Saving the last calculations
mkdir Old_All_Structures/ &> /dev/null
res=`echo rv: $? | awk '{print $2}'`
if [ $res -ne 0 ] ; then
   echo "Folder Old_All_Structures/ already exists. You cannot restart an already restarted calculation without first cleaning the Old_*** directories. Aborting."
   exit
fi
mv All_Structures/*xyz Old_All_Structures
rm -rf All_Structures

declare -a Last
Last=(`ls -d Str_*`)
size_Last=${#Last[*]}
for (( i=0;i<size_Last;i++)) do
   mv ${Last[i]} Old_${Last[i]}
done

# Starting the loop already assuming we have already started the run previously
finish=0
num_tot_structures=1
num_old_structures=0
step=0

# Storing the information of all the already found minima
cd Old_All_Structures
declare -a Old_XYZ_files
Old_XYZ_file=(`ls *xyz`)
size_Old_XYZ_file=${#Old_XYZ_file[*]}
echo "$size_Old_XYZ_file structures found from previous run." 
cd ..

# Preparing the main folders
declare -a XYZ_files
XYZ_files[0]="000000000.xyz"
mkdir All_Structures
cp $2 All_Structures/000000000.xyz

# Starting the main loop
while [ $finish -eq 0  ]; do
   # For each new structure, make the mode following analysis
   for (( i=num_old_structures;i<num_tot_structures;i++)) do
      echo "Analyzing structure ${XYZ_files[i]%.xyz}..."
      evaluation=0
      cp All_Structures/${XYZ_files[i]} .
      struct_file=${XYZ_files[i]%.xyz}
      # See if the structure was already found by previous calculation
      for (( kk=0;kk<size_Old_XYZ_file;kk++)) do 
         $str_rec ${XYZ_files[i]} Old_All_Structures/${Old_XYZ_file[kk]} 0.0001 0.5 > Temporary3_$i
         # If it was found, see if the modes were already evaluated
         if grep -q similar "Temporary3_$i" ; then
            indic=${Old_XYZ_file[kk]%.xyz}
            if [ -d "Old_Str_$indic" ]; then
               # Re-enumerating
               cp -r Old_Str_$indic Str_$struct_file
               cd Str_$struct_file
               renum=(`find -name \*.xyz`)
               size_renum=${#renum[*]}
               for (( ll=0;ll<size_renum;ll++)) do
                  part1=`echo ${renum[ll]} | cut -c 1-12`
                  part2=`echo ${renum[ll]} | cut -c 22-35`
                  mv ${renum[ll]} $part1$struct_file$part2 &> /dev/null
               done
               cd ..
               echo "Structure ${XYZ_files[i]%.xyz} already evaluated!"
               evaluation=1
               kk=size_Old_XYZ_file
            fi
         fi
      done
      rm -f Temporary3_*

      # If it was not already evaluated, proceed
      if [ $evaluation -eq 0 ] ; then
         echo "structure ${XYZ_files[i]%.xyz} not yet evaluated. Making the analysis..."
         for (( l=0;l<2;l++)) do
            for (( j=1;j<=number_freq;j++)) do
               $Sem -j$number_proc $freq $struct_file.xyz $j $l $optim $str_rec $full_path 
#              $freq $struct_file.xyz $j $l $optim $str_rec $full_path 
            done
         done
         $Sem --wait
      fi

      # Checking how many new structures exist in the given folder and storing them in an array
      cd $localdir/Str_$struct_file
      declare -a new_strut
      new_struc=(`find -name \*.xyz`)
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
