function [ DOSE ] = MC_Dicom_doseimport(filename,cst,ct,scalDOSE,boolscal)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% import dose from RD file or MRT measurements of gel dosimetry
% inputs
%       filname: name of dicom dose file
%       ct: Matrad ct structure
% output
%       DOSE: Array of with dose fitted to the ct size
% Oliver Schrenk
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  count = 1;
% read info data from dicom
 info = dicominfo(filename);

% get size and values of dicom  
 numOfFrames = info.NumberOfFrames;
 numOfRows = info.Rows;
 numOfColumns = info.Columns;
 coordsOfFirstPixel = [info.ImagePositionPatient];
 dicomSize = size(ct.cube); 
 

% read dose values from dicom file and write them into rawDose array
 DosePixel = dicomread(filename);
 

 for Z = 1:numOfFrames
     for Y = 1:numOfColumns
         for X = 1:numOfRows
        
             rawDOSE(X,Y,Z) = DosePixel(count);
                        
             count = count+1;
         end
     end
 end
 
 % x,y and z coordinates of dose dicom
 x = coordsOfFirstPixel(1,1) + info.PixelSpacing(1)*double([0:info.Columns-1]);
 y = coordsOfFirstPixel(2,1) + info.PixelSpacing(2)*double([0:info.Rows-1]');
 z = coordsOfFirstPixel(3,1) + info.GridFrameOffsetVector(:,1)';
 
% xi,yi and zi redefine coordinates for interpolation to wished voxel size of matRad ct   
 xi = coordsOfFirstPixel(1,1):ct.resolution(1):(coordsOfFirstPixel(1,1)+info.PixelSpacing(1)*double(info.Columns-1));
 yi = [coordsOfFirstPixel(2,1):ct.resolution(2):(coordsOfFirstPixel(2,1)+info.PixelSpacing(2)*double(info.Rows-1))]';
 zi = coordsOfFirstPixel(3,1):ct.resolution(3):(coordsOfFirstPixel(3,1)+(info.GridFrameOffsetVector(2)-info.GridFrameOffsetVector(1))*(info.NumberOfFrames-1));
 
% interpolation
 interpCt.cube = interp3(x,y,z,double(rawDOSE),xi,yi,zi);
 
% set Array with size of matrad ct file  
 DOSE = zeros(dicomSize(1),dicomSize(2),dicomSize(3));
  
 interpCTsice = size(interpCt.cube);
 % fill array
  for Z = 1:dicomSize(3)
      for Y = 1:dicomSize(2)
          for X = 1:dicomSize(1)
  
            if X <interpCTsice(1) && Y<interpCTsice(2) && Z<interpCTsice(3)
            DOSE(X,Y,Z) = interpCt.cube(X,Y,Z);
            else
            DOSE(X,Y,Z) = 0;   
            end
            
          end
      end
  end
 
 % perform shift of dose value in Array to set them to the right position
  interpCt.x = xi;
  interpCt.y = yi';
  interpCt.z = zi;


  Voxeldiff.X =(ct.x(1)) - (interpCt.x(1));
  Voxeldiff.Y =(ct.y(1)) - (interpCt.y(1));
  Voxeldiff.Z =(ct.z(1)) - (interpCt.z(1));
        
  Voxeldiff.numberX = -(round(Voxeldiff.X/(ct.resolution(1))));
  Voxeldiff.numberY = -(round(Voxeldiff.Y/(ct.resolution(2))));
  Voxeldiff.numberZ = -(round(Voxeldiff.Z/(ct.resolution(3))));
   
  DOSE = circshift(DOSE,Voxeldiff.numberX,2);
  DOSE = circshift(DOSE,Voxeldiff.numberY,1);
  DOSE = circshift(DOSE,Voxeldiff.numberZ,3);
  
  if boolscal == 0
  dicom.voxelISOcenter = MC_getIsoCenter(cst,ct,0);
  DOSEISO =  DOSE(dicom.voxelISOcenter(2),dicom.voxelISOcenter(1),dicom.voxelISOcenter(3));
  DOSE = (DOSE/DOSEISO)*scalDOSE;
  else   
  %scale dose with scaling factor        
  DOSE = DOSE*info.DoseGridScaling;
  end       

end
