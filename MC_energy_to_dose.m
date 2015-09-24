function [MCdose,MCuct] = MC_energy_to_dose(NAME3ddose,CT,PLAN,scalDOSE,limitUCT,boolscal)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create dose and uncertainty array of MC 3ddose file
% call MC_dose_to_array(NAME3ddose,CT,PLAN,scalDOSE,scaleUCT,boolscal)
% input
%     NAME3ddose:   name of 3ddose file 
%     CT: ct structure of matRad
%     PLAN: pln structure of matRad
%     scalDOSE: factor to scale dose in isocenter
%     limitUCT: limit for uncertainty cutoff
%     boolscal: bool if set to 0 dose is normalized to isocenter, set to 1
%     dose is normalized to dose max
% output
%     MCdose: array of dose
%     MCUCT:  array of uncertainty of MC simulation
% Explanation: 
%     Can be used to indroduce MCsimulation to matRad environment
%     to fit 3ddose to matRad dicom X and Y Koordinates neet to be swapped!
% Oliver Schrenk
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

filename1 = [NAME3ddose '.3ddose'];

doseFile = dlmread(filename1);

%get number of 3ddose Voxels in X,Y,Z 
MC3ddose.X = doseFile(1);
MC3ddose.Y = doseFile(2);
MC3ddose.Z = doseFile(3);

%define isocentrum (Right-Left, -Post-Ant,Inf-Sup) -x -y -z of egsinp
%Iso =[21.72, 26.79, -42.32];  
%Iso =[25.04, 17.38, -24.63];  
Iso =[24.26, 19.90, -23.99];  
%% calculate diffence of every voxel's position to isocenter of dicom to define Voxel in isocenter
for ax=1:1:PLAN.voxelDimensions(1)
Isodiff.X(ax) = abs(CT.x(ax)-(Iso(1)*10));
end

for ay=1:1:PLAN.voxelDimensions(2)
Isodiff.Y(ay) = abs(CT.y(ay)-(Iso(2)*10));
end

for az=1:1:PLAN.voxelDimensions(3)
Isodiff.Z(az) = abs(CT.z(az)-(Iso(3)*10));
end

% the smallest Isodiff value defines the Voxel in the Isocenter
dicom.voxelISOcenter.X = find(Isodiff.X==min(Isodiff.X));
dicom.voxelISOcenter.Y = find(Isodiff.Y==min(Isodiff.Y));
dicom.voxelISOcenter.Z = find(Isodiff.Z==min(Isodiff.Z));


%% get values of 3ddose file

% get geometrical position of each 3ddose Voxel
MC3ddose.Voxelpos.X = doseFile(4:MC3ddose.X+4);
MC3ddose.Voxelpos.Y = doseFile(MC3ddose.X+5:MC3ddose.X+MC3ddose.Y+5);
MC3ddose.Voxelpos.Z = doseFile(MC3ddose.X+MC3ddose.Y+6:MC3ddose.X+MC3ddose.Y+MC3ddose.Z+6);

% number of entries to define voxel bounderies
MC3ddose.Voxel = MC3ddose.X+MC3ddose.Y+MC3ddose.Z;
% line wher DoseDiff starts
MC3ddose.Dosestart = MC3ddose.Voxel+7;
% total number of voxel
MC3ddose.NumberofVoxels = MC3ddose.X*MC3ddose.Y*MC3ddose.Z;

% get array of alle dose values 
MC3ddose.dose = doseFile(MC3ddose.Dosestart:MC3ddose.Dosestart+MC3ddose.NumberofVoxels-1);
% define maximal dose und normalize it to  scalDose
MC3ddose.MAX = max(MC3ddose.dose);
% get array for unvertainties of alle 3ddose values
MC3ddose.uncert = doseFile(MC3ddose.Dosestart+MC3ddose.NumberofVoxels:end);

count=1;

% get voxel size of 3ddose voxel 
MC3ddose.resolution(1) = abs(MC3ddose.Voxelpos.X(1) - MC3ddose.Voxelpos.X(2));
MC3ddose.resolution(2) = abs(MC3ddose.Voxelpos.Y(1) - MC3ddose.Voxelpos.Y(2));
MC3ddose.resolution(3) = abs(MC3ddose.Voxelpos.Z(1) - MC3ddose.Voxelpos.Z(2));

%%
%shift 3ddose Array to the right position in dicom
%define empty array for dose and uncertainty with size of matRad (dicom) array
MC3ddose.DoseArray = zeros(PLAN.voxelDimensions(1), PLAN.voxelDimensions(2), PLAN.voxelDimensions(3));
MC3ddose.uncertArray = zeros(PLAN.voxelDimensions(1), PLAN.voxelDimensions(2), PLAN.voxelDimensions(3));

%define how many pixel the 3ddose dose array has to be shifted to fit into
%the matRad array

        Voxeldiff.X =(CT.x(1)/10) - (MC3ddose.Voxelpos.X(1));
        Voxeldiff.Y =(CT.y(1)/10) - (MC3ddose.Voxelpos.Y(1));
        Voxeldiff.Z =(CT.z(1)/10) - (MC3ddose.Voxelpos.Z(1));
       
        Voxeldiff.numberX = abs(round((Voxeldiff.X/(CT.resolution(1)/10))));
        Voxeldiff.numberY = abs(round((Voxeldiff.Y/(CT.resolution(2)/10))));
        Voxeldiff.numberZ = abs(round((Voxeldiff.Z/(CT.resolution(3)/10))));

%if resolution of 3ddose and CT is equal the dose and uncertainty is
%transformed into 3D arra
if (round(MC3ddose.resolution(1)) == round(CT.resolution(1)/10))&(round(MC3ddose.resolution(2)) == round(CT.resolution(2)/10))&(round(MC3ddose.resolution(3)) == round(CT.resolution(3)/10))
    
           for v=1:1:MC3ddose.Z
             for j=1:1:MC3ddose.Y
               for i=1:1:MC3ddose.X 
               
                
%                 if CT.cube(j+Voxeldiff.numberY,i+Voxeldiff.numberX,v+Voxeldiff.numberZ) <= 0.04   
%  
%                  
%                  MC3ddose.DoseArray(j,i,v)= 0;
%                  MC3ddose.uncertArray(j,i,v)= 0; 
%                  
%                  elseif CT.cube(j+Voxeldiff.numberY,i+Voxeldiff.numberX,v+Voxeldiff.numberZ) >= 1.101   
%                      
%                  MC3ddose.DoseArray(j,i,v)= 0;
%                  MC3ddose.uncertArray(j,i,v)= 100;
%                  
%                  else
                 scale = (CT.cube(j+Voxeldiff.numberY,i+Voxeldiff.numberX,v+Voxeldiff.numberZ)*125);    
                 MC3ddose.DoseArray(j,i,v)= MC3ddose.dose(count)/scale;
                 MC3ddose.uncertArray(j,i,v)=MC3ddose.uncert(count);
                 
                % end
                 count=count+1;
              end
            end  
           end 
   

end;    

%%
% shift dose to wright postion 
     MC3ddose.DoseArray = circshift(MC3ddose.DoseArray,Voxeldiff.numberX,2);
     MC3ddose.uncertArray = circshift(MC3ddose.uncertArray,Voxeldiff.numberX,2);

     MC3ddose.DoseArray = circshift(MC3ddose.DoseArray,Voxeldiff.numberY,1);
     MC3ddose.uncertArray = circshift(MC3ddose.uncertArray,Voxeldiff.numberY,1);

     MC3ddose.DoseArray = circshift(MC3ddose.DoseArray,Voxeldiff.numberZ,3);
     MC3ddose.uncertArray = circshift(MC3ddose.uncertArray,Voxeldiff.numberZ,3);

 
 

          
%% define dose in isocenter and normalize to isocenter of boolscal is 0 or max dose if boolscal is 1           
  MC3ddose.ISO =  MC3ddose.DoseArray(dicom.voxelISOcenter.Y,dicom.voxelISOcenter.X,dicom.voxelISOcenter.Z);
  
  if boolscal == 0
  MC3ddose.DoseArray =(MC3ddose.DoseArray/MC3ddose.ISO)*scalDOSE;
  elseif boolscal == 1
  MC3ddose.DoseArray =(MC3ddose.DoseArray/MC3ddose.MAX)*scalDOSE;
  end
  
%% renam name output arrays
  MCdose = MC3ddose.DoseArray;
  MCuct = MC3ddose.uncertArray*100;
 
% clean matrix only show dose of smaller then 130% (rest set to 130%)
% same for uncertainty of smaller then limitUCT
         for v=1:1:PLAN.voxelDimensions(3)
             for j=1:1:PLAN.voxelDimensions(2)
                 for i=1:1:PLAN.voxelDimensions(1)
           
                if MCdose(j,i,v)> scalDOSE*1.3; 
                   MCdose(j,i,v) =scalDOSE*1.3 ;
                end
                
                if MCuct(j,i,v) > limitUCT;
                   MCdose(j,i,v)= 0;
                   MCuct(j,i,v) =  limitUCT ;
                end
                
               end
             end  
         end 
           



