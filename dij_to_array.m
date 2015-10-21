function [DIJdose] = dij_to_array(DIJ,beam)
%% dose to array
%%dosetoArray('Schwein_partly',pln.isoCenter,pln.voxelDimensions,ct.resolution,50);







count=1;


DIJ.DoseArray = zeros(DIJ.dimensions(1), DIJ.dimensions(2), DIJ.dimensions(3));
   

   
           for v=1:1:DIJ.dimensions(3)
            for j=1:1: DIJ.dimensions(2)
              for i=1:1: DIJ.dimensions(1)
         
                 DIJ.DoseArray(i,j,v)= DIJ.physicalDose(count,beam);
                                  
              count=count+1;
              end
            end  
           end 
  

DIJdose = DIJ.DoseArray;

