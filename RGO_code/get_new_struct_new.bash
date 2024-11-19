#!/bin/bash
# Checking if the number of input parameters is correct (2)
if [ ! $# == 2 ]; then
  echo "Please, give the folder where the new structures are located, the name of the structure to checkition algorithm, the indice, the energy of the 1st structure of the simulation, the cuts in the energy barrier/difference, a temporary indice and the curent directory, the number of processors."
  exit
fi

echo "entro get new"
date

# Reading the input
dir1_name=$PWD/$1                               #tipo Str_0000000xx
dir2_name=$PWD/All_Structures 			#

# Finding out the number of atoms
cd $dir1_name
number_atoms=$2
number_candidates=`wc -l candidatesort | awk '{print $1}'`
lockfile=Structure_file.lock
#timeout=10000 #secondi
exec 200>../$lockfile || exit 1
flock 200 || exit 1
trap 'rm -f ../$lockfile' exit

echo "chiamo aggiungi"
date

number_old_structures=`wc -l ../Structure_file.txt | awk '{print $1}'`
echo "$number_atoms $number_candidates $number_old_structures" | ./aggiungistrutture.x

echo "ho chiamato aggiungi"
date

wait
sleep 2

echo "esco get new"
date

cd ..
