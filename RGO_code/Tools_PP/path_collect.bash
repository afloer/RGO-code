#!/bin/bash
# Checking if the number of input parameters is correct (2)
if [ ! $# == 2 ]; then
  echo "Please, give the number of the 2 structures to be connected! You should be on the main folder (where the folder All_Structures is located) to run this script!"
  exit
fi

# Reading the input                                  
str1=$1
str2=$2

# Sorting, removing similar entrances and taking the lowest barrier
sort -gk1 All_Structures/Energy_barriers.dat | uniq > ColTemporary_connections
sort -k1 -k2 -k3 ColTemporary_connections > ColTemporary_connections2
awk -F ':' '!x[$1]++' ColTemporary_connections2 > ColTemporary_connections

# Ignoring the connection of the structure to itself
awk '$1 != $3 {print}' ColTemporary_connections > ColTemporary_connections2

# Finding out ALL the possible connections startig with the last structure
declare -a Temp            # Temporary array
declare -a Blacklist       # Array for the black list
count_bl=0               # Counter for the black list
declare -a Str             # Main array
count_total=1              # Main counter

# Starting point - last structure
Str[0]=$str2
sz_Str=${#Str[*]}

# Main loop
for ((i=0;i<sz_Str;i++)) do
   # Checking if the new structure to be analyzed is in the black list
   accept=1
   if [ $i -gt 0 ] ; then
      temp_string=`ls ColTemp-*-$i`
   fi
   for ((j=0;j<count_bl;j++)) do
      if [ "$temp_string" == "${Blacklist[j]}" ] ; then
         accept=-1
      fi
   done
   if [ $accept -ge 0 ] ; then
      # Getting the 1st neighbors close to the analyzed structure
      unset Temp
      Temp=(`grep -e "-> ${Str[i]}" ColTemporary_connections2 | awk '{print $1}'`)
      sz_Temp=${#Temp[*]}
      count_part=$count_total
      for ((l=0;l<sz_Temp;l++)) do
         if [ $i -ne 0 ] ; then
            cp ColTemp-*-$i ColTemp-$i-$count_part
         else
            echo ${Str[i]} >> ColTemp-$i-$count_part
         fi
         echo ${Temp[l]} >> ColTemp-$i-$count_part
         count_part=$[ $count_part + 1 ]
      done
    
      # Putting on the black-list -> connect. already found IN THE SAME PATH/ first-last points
      count_part=$count_total
      for ((l=0;l<sz_Temp;l++)) do
        # First/last points
        if [ "${Temp[l]}" == "$str2" ] || [ "${Temp[l]}" == "$str1" ] ; then
           Blacklist[$count_bl]="ColTemp-$i-$count_part"
           ((count_bl++)) 
        fi   
         
        # All the already found structures (Check if it is correct! 16-05-2013)
        for ((u=0;u<sz_Str;u++)) do
           if [ "${Temp[l]}" == "${Str[u]}" ] ; then
              Blacklist[$count_bl]="ColTemp-$i-$count_part"
              ((count_bl++))
           fi
        done

        count_part=$[ $count_part + 1 ]
      done

      # Keeping track of all the paths
      count_total=$[ $count_total + $sz_Temp ]
      
      # Adding to the main array the new structures   
      for ((l=0;l<sz_Temp;l++)) do
         new_ind=$[ $sz_Str + $l ]
         Str[new_ind]=${Temp[l]}       
      done
      sz_Str=${#Str[*]}
    fi
done

# Putting on the final format only the paths that lead to the final structure
count_total=1
unset Temp
Temp=(`ls ColTemp-*-*`)
sz_Temp=${#Temp[*]}
for ((u=0;u<sz_Temp;u++)) do
   temp_string=`tail -n1 ${Temp[u]}`
   if [ "$temp_string" == "$str1" ] ; then
      sed -n '1!G;h;$p' ${Temp[u]} > Path$count_total.dat
      ((count_total++))
   fi
done

# Cleaning
rm -f ColTemp*

# Calling external "path_single.bash" code to join the xyz files
Temp=(`ls Path*.dat`)
sz_Temp=${#Temp[*]}
for ((u=1;u<=sz_Temp;u++)) do
   ./path_single.bash Path$u.dat Path$u.xyz
done
mkdir -p Paths_Found
mv Path*.xyz Paths_Found

# Post-Processing
cd Paths_Found
nat=`head -n1 Path1.xyz`
((nat=$nat+2))
Temp=(`ls Path*.xyz`)
sz_Temp=${#Temp[*]}
for ((u=0;u<sz_Temp;u++)) do
   awk -v x=$nat '{for (i=2; i<=NR; i=i+x) if (NR == i) print ;}' ${Temp[u]} > ${Temp[u]%.xyz}.en
done
