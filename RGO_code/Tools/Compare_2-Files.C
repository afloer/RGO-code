// Program that reads many structure files, compares them and store only the different ones in a filder called Selected_Str

/************************************ Libraries *****************************************/
#include <iostream>
using namespace std;
using std::cout;
#include <fstream>
#include <string>
#include <sstream>
#include <vector>
#include <cstdlib>
#include <cmath>
#include <iomanip>

/**************************** Functions  and classes*************************************/
#include "./Comparison.h"

/************************************* Main Program *************************************/
int main(int argc, char* argv[])
{
   // Checking the inline parameters given by the user
   if (argc != 5)   {
      cout << "\nPlease, provide the 2 files to be compared and in addition provide the energy and distance thresholds that will determine if two different files are the same. The execution should be something like\n./execute.x 'f1.xyz' 'f2.xyz' 0.3 0.4\n\n";
      exit(1);
   }

   // Reading the inline input
   char *clabel = argv[1];
   string file1 = clabel;
   char *clabel2= argv[2];
   string file2 = clabel2;
   double const En_thr = atof(argv[3]);
   double const Dist_thr = atof(argv[4]);

   // Store in the cluster class 
   Cluster Str1(file1);
   Cluster Str2(file2);

   // If the energy is equal by 1*10-9, then assume they are equal 
   double const energy_limit=0.000000001;
   if ((fabs(Str1.get_energy() - Str2.get_energy()) < energy_limit))  {
      cout << "\nBecause the energy is nearly identical, the structures " << file1 << " and " << file2 << " are assumed to be similar.\n";
      return 0;
   }

   bool different = true;
   double difference = 1000.0, temp_diff;
   if ( fabs(Str1.get_energy() - Str2.get_energy()) < En_thr )  {
      Str1.center(); Str2.center(); 
      // Compare the 2 structures                         
      temp_diff = evaluate_diff(Str2,Str1);
      if ( fabs(Str1.get_energy() - Str2.get_energy()) < En_thr )
         if (temp_diff < difference)
            difference = temp_diff;   
   
      Str1.orient(); Str2.orient();
      // Apply rotation and mirror
      for (int axes = 0; axes < 3; axes++)    {
         for (int angle = 0; angle < 4; angle++)   {
            for (int mir = 7; mir > -1; mir--)   {
               Cluster Str3 = Str2;
               Str3.rotate(axes,angle*90); if ( mir != 7 )    Str3.mirror(mir);
               Cluster Str4 = sorting_comp(Str3,Str1); // Sort S3 with respect to S1
               temp_diff = evaluate_diff(Str4,Str1);
               if (temp_diff < difference)
                  difference = temp_diff; 
               if (difference < Dist_thr)   {
                  different = false;
                  axes=4;angle=5;mir=-2;
               }
            }
         }
      }
   }
   if (difference < Dist_thr) 
     different = false;

   // Checking if the smallest value found is lower than threshold
   cout << "Smallest difference between str. " << file1 << " and " <<  file2 << " is " << difference << endl;

   cout << "\nThe two structures are " << ( different ? "different." : "similar." ) << "\n";
   return 0;
}
