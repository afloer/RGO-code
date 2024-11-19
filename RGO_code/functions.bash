#!/bin/bash
# Putting the integer in the right format 
zeros () {
   if [ $1 -lt 10 ] ; then
      echo "0000000000000000000000000000000$1"
   else
      if [ $1 -lt 100 ] ; then
         echo "000000000000000000000000000000$1"  
      else
         if [ $1 -lt 1000 ] ; then
            echo "00000000000000000000000000000$1"  
         else
            if [ $1 -lt 10000 ] ; then
               echo "0000000000000000000000000000$1"  
            else 
               if [ $1 -lt 100000 ] ; then
                  echo "000000000000000000000000000$1"  
               else
                  if [ $1 -lt 1000000 ] ; then
                     echo "00000000000000000000000000$1"  
                  else
                     if [ $1 -lt 10000000 ] ; then
                        echo "0000000000000000000000000$1"  
                     else
                        if [ $1 -lt 100000000 ] ; then
                           echo "000000000000000000000000$1"
                        else
                           if [ $1 -lt 1000000000 ] ; then
                              echo "00000000000000000000000$1"
                           else
                              if [ $1 -lt 10000000000 ] ; then
                                 echo "0000000000000000000000$1"
                              else
                                 if [ $1 -lt 100000000000 ] ; then
                                    echo "000000000000000000000$1"
                                 else 
        			    if [ $1 -lt 1000000000000 ] ; then
                                       echo "00000000000000000000$1"
                                    else 
				       if [ $1 -lt 10000000000000 ] ; then
                                          echo "0000000000000000000$1"
				       else
					  if [ $1 -lt 100000000000000 ] ; then
 					     echo "000000000000000000$1"
                                          else
					     if [ $1 -lt 1000000000000000 ] ; then
  						echo "00000000000000000$1"
					     else
						if [ $1 -lt 10000000000000000 ] ; then
						   echo "0000000000000000$1"
						else
						   if [ $1 -lt 100000000000000000 ] ; then
						      echo "000000000000000$1"
						   else
						      if [ $1 -lt 1000000000000000000 ] ; then
							 echo "00000000000000$1"
             					      else
							 if [ $1 -lt 10000000000000000000 ] ; then
   							    echo "0000000000000$1"
							 else 
							    if [ $1 -lt 100000000000000000000 ] ; then
							       echo "000000000000$1"
							    else
							       if [ $1 -lt 1000000000000000000000 ] ; then
								  echo "00000000000$1"
							       else
								  if [ $1 -lt 10000000000000000000000 ] ; then
								     echo "0000000000$1"
								  else
								     if [ $1 -lt 100000000000000000000000 ] ; then 	
									echo "000000000$1"
								     else
									if [ $1 -lt 1000000000000000000000000 ] ; then
									   echo "00000000$1"
									else
									   if [ $1 -lt 10000000000000000000000000 ] ; then
									      echo "0000000$1"
									   else
									      if [ $1 -lt 100000000000000000000000000 ] ; then
										 echo "000000$1"
									      else
										 if [ $1 -lt 1000000000000000000000000000 ] ; then
										    echo "00000$1"
										 else
										    if [ $1 -lt 10000000000000000000000000000 ] ; then
										       echo "0000$1"
										    else
										       if [ $1 -lt 100000000000000000000000000000 ] ; then
											  echo "000$1"
										       else
											  if [ $1 -lt 1000000000000000000000000000000 ] ; then
											     echo "00$1"
											  else
											     if [ $1 -lt 10000000000000000000000000000000 ] ; then
												echo "0$1"
											     else 
												if [ $1 -lt 100000000000000000000000000000000 ] ; then
												   echo "$1"
												fi
											     fi
											  fi
										       fi
										    fi
										 fi
									      fi
									   fi
									fi
								     fi
								  fi
							       fi
 							    fi
							 fi
						      fi
						   fi
						fi
					     fi
					  fi
				       fi
                                    fi
                                 fi
                              fi
                           fi
                        fi
                     fi
                  fi
               fi
            fi
         fi
      fi
   fi
}

