/* Code that buils interpolated intermediate images from a given set of images */

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

void intermediate(int const const_nat,double [][3],double [][3],double [][3],string []);

/************************************* Main Program *****************************************/
int main(int argc, char* argv[])
{
   if (argc != 3)   {
      cout << "\nPlease, provide the input file (xyz) with all the images and the outpu file. The execution should be something like\n./exec bu.xyz out.xyz\n\n";
      exit(1);
   }

   // Reading the inline input
   char *clabel1 = argv[1];
   char *clabel2 = argv[2];

   // Reading the input file
   ifstream inp(clabel1,ios::in);
   if (!inp)   {
      cout << "File not found. Aborting.\n";
      exit(1);
   }
   int itemp; 
   if ( !(inp >> itemp) )   {
      cout << "Number of atom could not be read. Aborting.\n";
      exit(1);
   }
   int const nat = itemp;
   cout << nat << " atoms read. Proceding...\n";
   string stemp; double dtemp;
   string sp[nat];  // Array with the atomic species
   int size = 0; int nr_images = 0;
   vector<double> Q; // Vector with the coordinates
   do   {
      getline(inp,stemp); getline(inp,stemp);
      for (int i = 0; i < nat; i++)   {
         inp >> stemp; sp[i]=stemp;
         inp >> dtemp; Q.resize(3*i+1+size,dtemp);
         inp >> dtemp; Q.resize(3*i+2+size,dtemp); 
         inp >> dtemp; Q.resize(3*i+3+size,dtemp);  
      }
      getline(inp,stemp);
      size += 3*nat; nr_images++;
   } while (inp >> stemp);
   inp.close();

   // Output - 1st image / intemediate + last image
   ofstream out(clabel2,ios::out);
   int nr_out_images = nr_images-1;
   int ct = 0, ind; double x, y, z;

   // 1st image
   out << nat << "\n\n"; 
   for (int i = 0; i < nat; i++)   {
      ind = i+ct;
      out << sp[i] << " " << Q[3*ind] << " " << Q[3*ind+1] << " " << Q[3*ind+2] << "\n";
   }
   ct += nat;

   // Intermediate_images + Last
   for (int j = 0; j < nr_out_images; j++)   {
      out << nat << "\n\n";
      for (int i = 0; i < nat; i++)   {
         ind = i+ct;
         x=0.5*(Q[3*ind]-Q[3*ind-3*nat])+Q[3*ind-3*nat];
         y=0.5*(Q[3*ind+1]-Q[3*ind-3*nat+1])+Q[3*ind-3*nat+1];
         z=0.5*(Q[3*ind+2]-Q[3*ind-3*nat+2])+Q[3*ind-3*nat+2];
         out << sp[i] << " " << x << " " << " " << y << " " << z << "\n";
      }      
      out << nat << "\n\n";
      for (int i = 0; i < nat; i++)   {
         ind = i+ct;
         out << sp[i] << " " << Q[3*ind] << " " << Q[3*ind+1] << " " << Q[3*ind+2] << "\n";
      }      
      ct += nat;
   }

   cout << "\n";
   return 0;
}

