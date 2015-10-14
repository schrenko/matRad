function [MCdose,MCuct] = MC_EnergytoArray(NAME3ddose,CT,CST,PLAN,scalDOSE,limitUCT,boolscal)
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
% Important:
%     Needs density file of same name!
% Oliver Schrenk
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

filename1 = [NAME3ddose '.3ddose'];
filename2 = 'Schweinelunge_20150610_BIXEL.density'; %[NAME3ddose '.density'];

binFile = fopen(filename2);

doseFile = dlmread(filename1);

%get number of 3ddose Voxels in X,Y,Z 
endian = fread(binFile,[1],'int8');
MC3ddose.X = fread(binFile,[1],'int32');
MC3ddose.Y = fread(binFile,[1],'int32');
MC3ddose.Z = fread(binFile,[1],'int32');

%define isocentrum (Right-Left, -Post-Ant,Inf-Sup) -x -y -z of egsinp
%Iso =[21.72, 26.79, -42.32];  
%Iso =[25.04, 17.38, -24.63];  
%Iso =[24.26, 19.90, -23.99];  
%dicom.voxelISOcenter = MC_getIsoCenter(CST,CT,0);

%% get values of 3ddose file

% get geometrical position of each 3ddose Voxel
MC3ddose.Voxelpos.X = fread(binFile,[MC3ddose.X+1],'float32')+(CT.resolution(1)/20);
MC3ddose.Voxelpos.Y = fread(binFile,[MC3ddose.Y+1],'float32')+(CT.resolution(2)/20);
MC3ddose.Voxelpos.Z = fread(binFile,[MC3ddose.Z+1],'float32')+(CT.resolution(3)/20);



% total number of voxel
MC3ddose.NumberofVoxels = MC3ddose.X*MC3ddose.Y*MC3ddose.Z;
density = fread(binFile,[MC3ddose.NumberofVoxels],'float32');

% get array of alle dose values 
MC3ddose.dose = doseFile(1:MC3ddose.NumberofVoxels);
% define maximal dose und normalize it to  scalDose
MC3ddose.MAX = max(MC3ddose.dose);
% get array for unvertainties of alle 3ddose values
MC3ddose.uncert = doseFile(MC3ddose.NumberofVoxels+1:end);

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
                          
                  
                 MC3ddose.DoseArray(j,i,v)= MC3ddose.dose(count)/density(count);
                 MC3ddose.uncertArray(j,i,v)=MC3ddose.uncert(count);
                 count=count+1;
               end
               
             end
            end  
           end 
   

    

%%
% shift dose to wright postion 
     MC3ddose.DoseArray = circshift(MC3ddose.DoseArray,Voxeldiff.numberX,2);
     MC3ddose.uncertArray = circshift(MC3ddose.uncertArray,Voxeldiff.numberX,2);

     MC3ddose.DoseArray = circshift(MC3ddose.DoseArray,Voxeldiff.numberY,1);
     MC3ddose.uncertArray = circshift(MC3ddose.uncertArray,Voxeldiff.numberY,1);

     MC3ddose.DoseArray = circshift(MC3ddose.DoseArray,Voxeldiff.numberZ,3);
     MC3ddose.uncertArray = circshift(MC3ddose.uncertArray,Voxeldiff.numberZ,3);

 
 

          
%% define dose in isocenter and normalize to isocenter of boolscal is 0 or max dose if boolscal is 1           
  MC3ddose.DoseISO =  MC3ddose.DoseArray(dicom.voxelISOcenter(2),dicom.voxelISOcenter(1),dicom.voxelISOcenter(3));
  
   if boolscal == 0
   MC3ddose.DoseArray =(MC3ddose.DoseArray/MC3ddose.DoseISO)*scalDOSE;
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
            

                 if MCuct(j,i,v) > limitUCT;
                    MCuct(j,i,v) =  limitUCT ;
                 end
                 
                end
              end  
          end 
            
fclose(binFile);
end

