#!/bin/bash
# Checking if the number of input parameters is correct (2)
if [ ! $# == 1 ]; then
  echo "Please, give the maximum barrier!"
  exit
fi

cd All_Structures

declare -a Min
Min=(`ls *xyz`)
sz_Min=${#Min[*]}

echo "$sz_Min structures found in total. Reading their energies and names."

declare -a Energies
declare -a Names   
for ((i=0;i<sz_Min;i++)) do
   Energies[i]=`awk 'NR == 2 {print}' ${Min[i]}`
   Names[i]=${Min[i]%.xyz}
done

echo "Energies and names read successfully. Proceeding reading the energy barriers."

# Writing to output
echo "Structure names" > Matrix_connection.dat
for ((i=0;i<sz_Min;i++)) do
   echo -n ${Names[i]}" " >> Matrix_connection.dat
done
echo -e "\n Energy differences" >> Matrix_connection.dat
for ((i=0;i<sz_Min;i++)) do
   en_dif=`echo ${Energies[i]} - ${Energies[0]} | bc`
   printf "%.5f" "$en_dif" >> Matrix_connection.dat
   echo -n " " >> Matrix_connection.dat
done

# Reading Energy_barriers.dat file and getting the barriers
echo -e "\n Barriers" >> Matrix_connection.dat
for ((i=0;i<sz_Min;i++)) do
   for ((j=0;j<sz_Min;j++)) do
      if grep -q -e "${Names[i]} -> ${Names[j]}" Energy_barriers.dat; then
         barrier=`grep -e "${Names[i]} -> ${Names[j]}" Energy_barriers.dat | awk '{print $5}' | sort -rg | tail -n1`
      else
         barrier=$1
      fi
      printf "%.4f" "$barrier" >> Matrix_connection.dat
      echo -n " " >> Matrix_connection.dat
   done
   # Writing to output 
   echo " " >> Matrix_connection.dat
done

