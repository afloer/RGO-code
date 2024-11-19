#include "./Cluster.h"
bool check_sanity(Cluster geom1, Cluster geom2);
double evaluate_diff(Cluster geom1, Cluster geom2);
double distance_ij(int i, int j, Cluster geom1, Cluster geom2);

// Function to check if 2 structures to be compared are the same type (nat and n_diff_species)
bool check_sanity(Cluster geom1, Cluster geom2)   {
   if ( geom1.get_nat() != geom2.get_nat() )
      return false;
   else   {
      int const species_number1 = geom1.get_speciesnumber();
      int const species_number2 = geom2.get_speciesnumber();
      if (species_number1 != species_number2)
         return false;
      /*else   {
         string species1[species_number1], species2[species_number1];
         geom1.get_diffspecies(species1); geom2.get_diffspecies(species2);
         for (int i = 0; )
      }*/ // Finish to include the check if the number of each different atomic species is the same
   }

   return true;
}

// Sum of the distance between coresponding atoms on each structure
double evaluate_diff(Cluster geom1, Cluster geom2)   {
   double difference = 0.0;
   int limit = (geom1.get_nat() > geom2.get_nat() ? geom2.get_nat() : geom1.get_nat()); // distance between each atom between two structures up to the maximum number of atoms of the structure that has the lower number of atoms
   for (int k = 0; k < limit; k++)
         difference += distance_ij(k,k,geom1,geom2);
   return difference;
}

// Function to evaluate the distance between atom i of structure 1 and atom j of structure 2
double distance_ij(int i, int j, Cluster geom1, Cluster geom2)   {
   if ( i > -1 && i < geom1.get_nat() && j > -1 && j < geom2.get_nat() )   {
      double Dq[] = {geom1.get_coord(i,0),geom1.get_coord(i,1),geom1.get_coord(i,2)};
      for (int k = 0; k < 3; k++)
         Dq[k] -= geom2.get_coord(j,k); 
      return sqrt(Dq[0]*Dq[0]+Dq[1]*Dq[1]+Dq[2]*Dq[2]);  
   }
   else   {
      cout << "Pair " << i << "-" << j << " out of range. Aborting.\n";
      exit(1);
   }
}

// Sorting the first structure with respect to the second
Cluster sorting_comp(Cluster geom1, Cluster geom2)   {
   if ( geom1.get_nat() != geom2.get_nat() )   {
      cout << "Number of atoms of the two structures are different. Error when comparing structures...\n";
      geom1.write_to(cout); cout << "and\n"; geom2.write_to(cout); cout << "Aborting.\n";
      exit(1);
   }

   int const nat = geom1.get_nat();
   int counter_nspe = 0;
   int const species_number = geom1.get_speciesnumber(); 
   string Diff_Spe[species_number]; geom1.get_diffspecies(Diff_Spe); // !No check was made about the number of species!

   // Sorting by distance the coordinate-matrix for each of the species
   for (int ll = 0; ll < species_number; ll++)   {
      int nspe = 0;
      // Counting the number of atoms of this species that exists
      for (int j = 0; j < nat; j++)     
         if ( geom1.get_species(j) == Diff_Spe[ll])
            nspe++;
      int const const_nspe = nspe;

      // Matrix 'Distance' has all the interatomic distances between the two different structures for a specific species
      double Distance[const_nspe][const_nspe];
      for (int i = 0; i < const_nspe; i++)
         for (int j = 0; j < const_nspe; j++)
               Distance[i][j]=distance_ij(counter_nspe+i,counter_nspe+j,geom2,geom1);

      // Temporary arrays containing the pairs
      int LA[const_nspe]; int LB[const_nspe];
      for (int i = 0; i < const_nspe; i++)   {
         LA[i]=-1; LB[i]=-1; 
      }

      // Calculating the minimum of the matrix for each pair
      double rmin; bool acc; int counter = 0;
      while (counter < const_nspe)   {
         rmin = 100.0;
         for (int i = 0; i < const_nspe; i++)
            for (int j = 0; j < const_nspe; j++)
               if ( Distance[i][j] < rmin )   {
                  acc = true;
                  for (int k = 0; k < counter; k++)   {
                     if ( (i == LA[k]) || (j == LB[k]) )
                         acc = false;
                  }
                  if (acc == true)    {
                     rmin = Distance[i][j];
                     LA[counter]=i; LB[counter]=j;
                  }
               }
         counter++;
      }

      // Performing the exchange on the new structure
      if (const_nspe > 1)   {
         Cluster geomtemp = geom1;
         for (int i = 0; i < const_nspe; i++)   {
               geom1.set_species(LA[i]+counter_nspe,geomtemp.get_species(LB[i]+counter_nspe));
            for (int k = 0; k < 3; k++)
               geom1.set_coord(LA[i]+counter_nspe,k,geomtemp.get_coord(LB[i]+counter_nspe,k));
         }
      }
      counter_nspe += const_nspe; 
   }

   return geom1;
}
