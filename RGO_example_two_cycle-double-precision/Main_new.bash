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
optim=$full_path/LMPOPTIM
str_rec=$full_path/struct_compare.x
freq=$full_path/freq_new_precisionegiusta.bash       
get_new=$full_path/get_new_struct_new.bash
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


cp Structure_file.txt /dev/shm/

# Step 0 before the loop
cp $2 00000000000000000000000000000000.xyz
number_atoms=`head -n1 00000000000000000000000000000000.xyz`
number_freq=$[3*$number_atoms-6]
double_nfreq=$[6*$number_atoms-12]
# manca creare Structure_file.txt

# Copying the first structure - If main folder exists, stops
mkdir To_be_analyzed &> /dev/null
res=`echo rv: $? | awk '{print $2}'`
if [ $res -ne 0 ] ; then
   echo "Folder To_be_analyzed already exists. Aborting..."
   exit
fi
declare -a XYZ_files
XYZ_files[0]="00000000000000000000000000000000.xyz"

# Getting the first energy
initial_energy=`awk 'NR == 2 {print $1}' 00000000000000000000000000000000.xyz`

# Copying the first file to the results directory and preparing to start
cp 00000000000000000000000000000000.xyz To_be_analyzed

finish=0
num_tot_structures=1
num_old_structures=0
step=0



open_sem(){
        mkfifo pipe-$$
        exec 3<>pipe-$$
        rm pipe-$$
        local i=$1
        for((;i>0;i--)); do
            printf %s 000 >&3
        done
    }
    
    # run the given command asynchronously and pop/push tokens
run_with_lock(){
        local x
        # this read waits until there is something to read
        read -u 3 -n 3 x && ((0==x)) || exit $x
        (
         (cd $localdir
         local to_analyze=`ls -A To_be_analyzed | head -n1`
         mv To_be_analyzed/$to_analyze . 
         for (( l=0;l<2;l++)) do
            for (( j=1;j<=number_freq;j++)) do
               $freq $to_analyze $j $l $optim $str_rec $full_path $initial_energy $energy_barrier_cut $energy_dif_cut
            done
         done
# Questo non era commentato per fermarsi dopo un ciclo solo   
#         exit
#

         cd $localdir/Str_${to_analyze%.xyz}
         sort -nk1 candidates > candidatesort
         cp $full_path/aggiungistrutture_doublep.x .
         cd ..
         $get_new Str_${to_analyze%.xyz} $number_atoms
         mv $to_analyze Analyzed/ )
        # push the return code of the command to the semaphore
        printf '%.3d' $? >&3
        echo "return code was $?"
        )&
    }
    
open_sem $number_proc

while [ $finish -eq 0 ]; do
   for (( i=num_old_structures;i<num_tot_structures;i++)) do
      run_with_lock
      sleep 1
   done
   wait

#   exit

   num_old_structures=$num_tot_structures
   cd $localdir/To_be_analyzed
   XYZ_files=(`ls *.xyz`)
   toperform=${#XYZ_files[*]}
   num_tot_structures=$((num_old_structures + $toperform))
   if [ $toperform -eq 0 ] ; then
      finish=1
   fi
   echo "Step $step finished. $toperform new structures found. " 
   ((step++))
done
date



