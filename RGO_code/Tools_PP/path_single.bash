#!/bin/bash
# Checking if the number of input parameters is correct (2)
if [ ! $# == 2 ]; then
  echo "Please, give the input file containing the structure and the output file!"
  exit
fi

# Reading the inline commands
ifile=$1
ofile=$2

# Getting the number of atoms
nat=`head -n1 All_Structures/*.xyz | tail -n1`
number_nodes=$[ 12 * $nat - 24 ]

# Collecting the indice of each atom
cd All_Structures
declare -a Min
Min=(`ls *xyz | cut -d. -f1`)
sz_Min=${#Min[*]}
cd ..

# Main loop 
lim=`wc -l < $ifile`
for ((i=1;i<lim;i++)) do
   ((j=i+1))
   str1=`sed -n "$i"p $ifile`
   str2=`sed -n "$j"p $ifile`
   str1_nr=`sed -n "$i"p $ifile | sed 's/0*//'`
   str2_nr=`sed -n "$j"p $ifile | sed 's/0*//'`
   # Checking for empty string - Case 000000000
   if [ -z "$str1_nr" ]; then
      str1_nr=0
   fi
   if [ -z "$str2_nr" ]; then
      str2_nr=0
   fi
   # Mode                        
   mode=`grep -e "$str1 -> $str2" All_Structures/Energy_barriers.dat | sort -rgk5 | tail -n1 | awk '{print $8}'`
   # Collecting the minima and TS
   cd Str_$str1
   cd $mode
   cat *xyz >> ../../$ofile
   cd ../../ 
done
