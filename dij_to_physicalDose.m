function [ dose ] = dij_to_physicalDose(dij,CST,CT)

dose = zeros(222,222,147);
%dose = zeros(dij.dimensions(1),dij.dimensions(2),dij.dimensions(3));
dij_sum = sum(dij,2);
%dij_sum = sum(dij.physicalDose,2);

dicom.voxelISOcenter = MC_getIsoCenter(CST,CT,0);




count=1;
 
    
for v=1:1:147;
%    for v=dij.dimensions(3);
       for j=1:1:222;
      %     for j=dij.dimensions(2);
                  for i=1:1:222;
                  %   for i=dij.dimensions(1)
                      
                    dose(i,j,v) = dij_sum(count);
                    count = count+1;
                    
                  end
       end
end

MC3ddose.DoseISO =  dose(dicom.voxelISOcenter(2),dicom.voxelISOcenter(1),dicom.voxelISOcenter(3));

%dose =(dose/MC3ddose.DoseISO)*100;



end

