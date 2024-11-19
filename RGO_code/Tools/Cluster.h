#include <iostream>
using namespace std;
using std::cout;
#include <fstream>
#include <string>
#include <sstream>
#include <vector>
#include <cstdlib>
#include <cmath>
#include <ctime>
#include <iomanip>
#include <algorithm>
#include "./nr3.h"
#include "./eigensym.h"
#include "./ludcmp.h"

class Cluster {
   public:
      // Constructor
      Cluster ();
      Cluster (string file_name);

      // Operators
      void mirror(int axes);
      void center();
      void rotate(int axes, double angle);
      void rotate(int x, int y, int z, double angle);
      void multiply(double factor);
      void translate(int axes, double magnitude);
      int number_bonds(int atom_number, double threshold);
      int number_bonds(int atom_number, double threshold, string type);
      void exchange(int atom_number1, int atom_number2);
      void sort_chemical();
      void orient();

      // Get-Set-Write
      void write_to(ostream& output);
      void write_to(string filename);
      void writegeom_to(ostream& output);
      double get_energy();
      void set_energy(double);
      void scale_energy(double);
      int get_nat();
      int get_speciesnumber();
      void get_diffspecies(string []);
      double get_coord(int atom_number,int axes);
      string get_species(int atom_number);
      void set_coord(int atom_number,int axes,double value);
      void set_species(int atom_number,string sp);

   private:
      // Variables
      int nat;
      double inv_nat;
      double energy;
      vector<string> species;
      vector<double> coordinates;
      int species_number;
      vector<string> diff_species;

      // Functions
      double distance(double x1,double y1,double z1,double x2,double y2,double z2);
      double distance(int atom_number1, int atom_number2);
      void check_atomnumber(int atom_number);
      void check_axes(int atom_number);
};

// Default constructor
Cluster::Cluster () {
   nat=1;
   inv_nat=1.0/nat;
   energy=0.0;
   species.resize(1,"h");
   coordinates.resize(3,0.0);
   species_number=1; 
   diff_species.resize(1,"h");
}

// Construction from a 'xyz' type of file
Cluster::Cluster (string file_name) {
   string stemp; double dtemp;

   ifstream in(file_name.c_str(),ios::in);
   if ( !in )   {
      cout << "File " << file_name << " not found. Aborting!\n"; exit(1);
   }
   getline(in,stemp);
   stringstream streamtemp(stemp);
   if ( !(streamtemp >> nat) )   {
      cout << "Invalid number of atoms. Aborting.\n"; exit(1);
   }
   
   if ( nat < 0 || nat > 1000000 )   {
      std::cout << "Number of atoms beyond acceptable range. Setting it as one. \n";
      nat = 1; energy = 0.0; species.resize(1,"h"); coordinates.resize(3,0.0);  
   }
   else   {
      getline(in,stemp);
      stringstream streamtemp(stemp);
      if ( !(streamtemp >> energy) )   {
         cout << "Invalid energy in the second line. Aborting.\n"; exit(1);
      }
      try   {
         for (int i = 0; i < nat; i++)   {
            if ( !(in >> stemp) )      throw i;
            else                       species.resize(i+1,stemp);
            for (int j = 1; j < 4; j++)   {
               if ( !(in >> dtemp) )   throw i;
               else                    coordinates.resize(3*i+j,dtemp);      
            }
         }
      }
      catch (int e)   {
         cout << "Error while attempting to read line " << (e+1) << " containing the coordinates of each atom. Please check if the number of atoms is correct. Aborting." << endl;
         exit(1);
      }
   }

   // Determining the number of species and the different species
   int st = 1; bool diff;
   diff_species.resize(st,species[0]);
   for (int i  = 1; i < nat; i++)   {
      diff = true;
      for (int j = 0; j < st; j++)   {
         if ( species[i] == diff_species[j] )
            diff = false;      
      }
      if ( diff )   {
         st++;
         diff_species.resize(st,species[i]);      
      }
   }
   species_number = st;
   sort (diff_species.begin(),diff_species.end());  // Sorting the vector 

   inv_nat=1.0/nat;
}


// Clock-wise rotation
void Cluster::rotate (int axes, double angle) {
   double const phi = angle*3.14159265/180.0;
   int k, l;
   switch (axes) {
   case 0:
      k=1; l=2;
      break;
   case 1:
      k=0; l=2;
      break;
   case 2:
      k=0; l=1;
      break;
   default:
      cout << "Invalid option for rotation. Aborting." << endl; exit(1);
      break;   // If used correctly, rotate never gets here (0-x,1-y,2-z)
   }

   double q1,q2;
   for (int i = 0; i < nat; i++)   {
      q1 = coordinates[3*i+k]; q2 = coordinates[3*i+l]; 
      coordinates[3*i+k] = cos(phi)*q1 + sin(phi)*q2;
      coordinates[3*i+l] = cos(phi)*q2 - sin(phi)*q1;
   }
}
void Cluster::rotate (int x, int y, int z, double angle)   {
   // x,y,z determine the axis of rotation
   double r = sqrt(1.0*(x*x + y*y + z*z));
   double th = acos(z/r);
   double ph = atan2(1.0*y,1.0*x);

   // Puting in the axis, rotating, and coming back to the original axes
   double conv = 180.0/3.14159265;
   rotate(2,ph*conv); rotate(1,-th*conv);
   rotate(2,angle);
   rotate(1,th*conv); rotate(2,-ph*conv); 
} // Check if it is working...

// Translation
void Cluster::translate (int axes, double magnitude) {
   if ( axes == 0 || axes == 1 ||  axes == 2)
      for (int i = 0; i < nat; i++)
         coordinates[3*i+axes] += magnitude;
}

// Scale
void Cluster::multiply (double factor) {
   for (int a = 0; a < 3*nat; a++)
      coordinates[a] *= factor;
}

// Center
void Cluster::center () {
   double qt[]={0.0,0.0,0.0};
   for (int i = 0; i < nat; i++)
      for (int j = 0; j < 3; j++)
         qt[j] += coordinates[3*i+j];

   for (int i = 0; i < nat; i++)
      for (int j = 0; j < 3; j++)
         coordinates[3*i+j] -= qt[j]*inv_nat;

}

// Number of neighbors
int Cluster::number_bonds(int k, double threshold) {
   int number_bonds = 0;
   for (int i = 0; i < nat; i++)
      if (i != k)
         if ( distance(coordinates[3*k],coordinates[3*k+1],coordinates[3*k+2],coordinates[3*i],coordinates[3*i+1],coordinates[3*i+2]) < threshold )
            number_bonds++;
   return number_bonds;
}

int Cluster::number_bonds(int k, double threshold, string type) {
   int number_bonds = 0;
   for (int i = 0; i < nat; i++)
      if (i != k && species[i] == type )
         if ( distance(coordinates[3*k],coordinates[3*k+1],coordinates[3*k+2],coordinates[3*i],coordinates[3*i+1],coordinates[3*i+2]) < threshold )
            number_bonds++;
   return number_bonds;
}

// Mirror-plane
void Cluster::mirror(int plane)   {
   // 0/1/2/3/4/5/6/7 -> x/y/z/xy/xz/yz/xyz
   switch (plane)   {
      case 0:
      case 1:
      case 2:
         for (int g = 0; g < nat; g++)   coordinates[3*g+plane] *= -1.0;
         break;
      case 3:
         for (int g = 0; g < nat; g++)   { coordinates[3*g+0] *= -1.0; coordinates[3*g+1] *= -1.0; }
         break;
      case 4:
         for (int g = 0; g < nat; g++)   { coordinates[3*g+0] *= -1.0; coordinates[3*g+2] *= -1.0; }
         break;
      case 5:
         for (int g = 0; g < nat; g++)   { coordinates[3*g+1] *= -1.0; coordinates[3*g+2] *= -1.0; }
         break;
      case 6:
         for (int g = 0; g < nat; g++)   { coordinates[3*g+0] *= -1.0; coordinates[3*g+1] *= -1.0; coordinates[3*g+2] *= -1.0; }
         break;
      default:
         break;   // In any other case, do nothing
   }
}

// Sort by species
void Cluster::sort_chemical ()   {
   sort(diff_species.begin(),diff_species.end());
   string stemp;
   double coord_temp[3];
   int j_position = 0;
   for (int i = 0; i < species_number; i++)
      for (int j = 0; j < nat; j++)
         if ( species[j] == diff_species[i] )   {
            stemp=species[j];
            for (int k = 0; k < 3; k++)
               coord_temp[k]=coordinates[3*j+k];
            species[j]=species[j_position];
            species[j_position]=stemp;
            for (int k = 0; k < 3; k++)   {
               coordinates[3*j+k]=coordinates[3*j_position+k];
               coordinates[3*j_position+k]=coord_temp[k];
            }
            j_position++;
         }   
}

// Exchange
void Cluster::exchange(int atom_number1, int atom_number2)   {
   check_atomnumber(atom_number1); check_atomnumber(atom_number2);
   string stemp = species[atom_number2];
   double dtemp[] = {coordinates[3*atom_number2+0],coordinates[3*atom_number2+1],coordinates[3*atom_number2+2]};

   species[atom_number2] = species[atom_number1];
   species[atom_number1] = stemp;
   for (int i = 0; i < 3; i++)   {
      coordinates[3*atom_number2+i] = coordinates[3*atom_number1+i]; 
      coordinates[3*atom_number1+i] = dtemp[i];
   }
}

// Get-Set-Write
void Cluster::write_to(ostream& output)   {
   output << nat << "\n  " << setprecision(10) << energy << "  \n";
   for (int i = 0; i < nat;i++)
      output << " " << species[i] << " " << coordinates[3*i+0] << " " << coordinates[3*i+1] << " " << coordinates[3*i+2] <<"\n";
}
void Cluster::write_to(string filename)   {
   ofstream outfile(filename.c_str(),ios::out);   
   outfile << nat << "\n  " << setprecision(10) << energy << "  \n";
   for (int i = 0; i < nat;i++)
      outfile << " " << species[i] << " " << coordinates[3*i+0] << " " << coordinates[3*i+1] << " " << coordinates[3*i+2] <<"\n";
}
void Cluster::writegeom_to(ostream& output)   {
   for (int i = 0; i < nat;i++)
      output << " " << species[i] << " " << coordinates[3*i+0] << " " << coordinates[3*i+1] << " " << coordinates[3*i+2] <<"\n";
}
double Cluster::get_energy()   {   return energy;   }
void Cluster::set_energy(double newvalue)   {   energy = newvalue;   }
void Cluster::scale_energy(double scale)   {   energy *= scale;   }
int Cluster::get_nat()   {   return nat;   }
int Cluster::get_speciesnumber()   {   return species_number;   }
void Cluster::get_diffspecies(string Temp[])   {   
   for (int i = 0; i < species_number; i++)
      Temp[i] = diff_species[i];
}
double Cluster::get_coord(int atom_number,int axes)   {   
   check_atomnumber(atom_number); check_axes(axes);
   return coordinates[3*atom_number+axes];   
}
string Cluster::get_species(int atom_number)   {   
   check_atomnumber(atom_number);
   return species[atom_number];   
}
void Cluster::set_coord(int atom_number,int axes, double value)   {   
   check_atomnumber(atom_number); check_axes(axes);
   coordinates[3*atom_number+axes]=value;   
}
void Cluster::set_species(int atom_number, string sp)   {   
   check_atomnumber(atom_number);
   species[atom_number] = sp;   
}

// Private functions
void Cluster::check_atomnumber(int atom_number)   {
   if ( atom_number < 0 || atom_number >= nat)   {
      cout << "Atom " << (atom_number+1) << " does not exist. Aborting.\n";
      exit(1);
   }
}

void Cluster::check_axes(int axes)   {
   if ( axes < 0 || axes > 2)   {
      cout << "Axes number does not exist (should be 0, 1 or 2 - x, y, z). Aborting.\n";
      exit(1);
   }
}
double Cluster::distance(double x1,double y1,double z1,double x2,double y2,double z2)   {
   return sqrt((x1-x2)*(x1-x2)+(y1-y2)*(y1-y2)+(z1-z2)*(z1-z2));  
}
double Cluster::distance(int atom_number1, int atom_number2)   {
   double Dq[] = {coordinates[3*atom_number1+0],coordinates[3*atom_number1+1],coordinates[3*atom_number1+2]};
   for (int i = 0; i < 3; i++)
      Dq[i] -= coordinates[3*atom_number2+i]; 
   return sqrt(Dq[0]*Dq[0]+Dq[1]*Dq[1]+Dq[2]*Dq[2]);  
}

void Cluster::orient()   {
   // Calculating the inertia tensor
   MatDoub In(3,3);
   for (int k=0;k<3;k++)
      for (int l=0;l<3;l++)
         In[l][k]=0.0;

   for (int k = 0; k < nat; k++)   {
       In[0][0] += coordinates[3*k+1]*coordinates[3*k+1]+coordinates[3*k+2]*coordinates[3*k+2];
       In[1][1] += coordinates[3*k+0]*coordinates[3*k+0]+coordinates[3*k+2]*coordinates[3*k+2];
       In[2][2] += coordinates[3*k+0]*coordinates[3*k+0]+coordinates[3*k+1]*coordinates[3*k+1];
       In[0][1] -= coordinates[3*k+0]*coordinates[3*k+1];
       In[0][2] -= coordinates[3*k+0]*coordinates[3*k+2];
       In[1][2] -= coordinates[3*k+1]*coordinates[3*k+2];
   }
   In[1][0]=In[0][1]; In[2][1]=In[1][2]; In[2][0]=In[0][2];

   // Diagonalizing using the numerical recipe by William H. Press - coordinates jac.v contains the 3 vectors
   Jacobi jac(In);

   // The new 3 vectors
   MatDoub new_q(3,3);
   for (int k=0;k<3;k++)
      for (int l=0;l<3;l++)
         new_q[k][l] = jac.v[k][2-l];

   // Calculating the inverse - the inverse is simply the transpose-coordinates
   MatDoub inv_new_q(3,3);
   LUdcmp lu(new_q);
   lu.inverse(inv_new_q);

   // Rotating to the new axis
   double qq[3]; 
   for (int k=0;k<nat;k++)   {
      for (int l=0;l<3;l++)
         qq[l]=coordinates[3*k+l];            
      coordinates[3*k+0] = inv_new_q[0][0]*qq[0]+inv_new_q[0][1]*qq[1]+inv_new_q[0][2]*qq[2];
      coordinates[3*k+1] = inv_new_q[1][0]*qq[0]+inv_new_q[1][1]*qq[1]+inv_new_q[1][2]*qq[2];
      coordinates[3*k+2] = inv_new_q[2][0]*qq[0]+inv_new_q[2][1]*qq[1]+inv_new_q[2][2]*qq[2];         }
}

