function [ DOSE ] = DICOM_doseimport(filename,ct,cst,scalDOSE)
count = 1;
FILELIST.resx = ct.resolution(1);
FILELIST.resy = ct.resolution(2);
FILELIST.resz = ct.resolution(3);

 SIZE= size(ct.cube);
 info = dicominfo(filename);
 numOfFrames = info.NumberOfFrames;
 numOfRows = info.Rows;
 numOfColumns = info.Columns;
 originRes = info.PixelSpacing;
 Pixel = dicomread(filename);

 coordsOfFirstPixel = [info.ImagePositionPatient];
  
 dicom.voxelISOcenter = MC_getIsoCenter(cst,ct,0);

 x = coordsOfFirstPixel(1,1) + info.PixelSpacing(1)*double([0:info.Columns-1]);
 y = coordsOfFirstPixel(2,1) + info.PixelSpacing(2)*double([0:info.Rows-1]');
 z = coordsOfFirstPixel(3,1) + info.GridFrameOffsetVector(:,1)';
 
 
 xi = coordsOfFirstPixel(1,1):FILELIST.resx:(coordsOfFirstPixel(1,1)+info.PixelSpacing(1)*double(info.Columns-1));
 yi = [coordsOfFirstPixel(2,1):FILELIST.resy:(coordsOfFirstPixel(2,1)+info.PixelSpacing(2)*double(info.Rows-1))]';
 zi = coordsOfFirstPixel(3,1):FILELIST.resz:(coordsOfFirstPixel(3,1)+(info.GridFrameOffsetVector(2)-info.GridFrameOffsetVector(1))*(info.NumberOfFrames-1));
 

 for Z = 1:numOfFrames
     for Y = 1:numOfColumns
         for X = 1:numOfRows
        
             ARRAY(X,Y,Z) = Pixel(count);
                        
             count = count+1;
         end
     end
 end
 
 


 interpCt.cube = interp3(x,y,z,double(ARRAY),xi,yi,zi);
 
 MRDOSE = interpCt.cube;

  
  interpCt.x = xi;
  interpCt.y = yi';
  interpCt.z = zi;

  MRDOSEiso =  MRDOSE(dicom.voxelISOcenter(2),dicom.voxelISOcenter(1),dicom.voxelISOcenter(3));

         Voxeldiff.X =(ct.x(1)) - (interpCt.x(1));
         Voxeldiff.Y =(ct.y(1)) - (interpCt.y(1));
         Voxeldiff.Z =(ct.z(1)) - (interpCt.z(1));
        
         Voxeldiff.numberX = abs((round(Voxeldiff.X/(ct.resolution(1)))));
         Voxeldiff.numberY = abs((round(Voxeldiff.Y/(ct.resolution(2)))));
         Voxeldiff.numberZ = abs((round(Voxeldiff.Z/(ct.resolution(3)))));
   
         MRDOSE = circshift(MRDOSE,Voxeldiff.numberX,2);
         MRDOSE = circshift(MRDOSE,Voxeldiff.numberY,1);
         MRDOSE = circshift(MRDOSE,Voxeldiff.numberZ,3);
         
         MRDOSEiso =  MRDOSE(dicom.voxelISOcenter(1),dicom.voxelISOcenter(2),dicom.voxelISOcenter(3));

        % MRDOSE =(MRDOSE/MRDOSEmax)*scalDOSE;


end


function [fileList] = MR_matRad_scanDicomImportFolder( patDir )

            
       try % try to get DicomInfo
            info = dicominfo(patDir);
        catch
            fileList(1,:) = [];
        end
        try
            fileList{1,2} = info.Modality;
        catch
            fileList{1,2} = NaN;
        end
        try
            fileList{1,3} = info.PatientID;
        catch
            fileList{1,3} = NaN;
        end
        try
            fileList{1,4} = info.SeriesInstanceUID;
        catch
            fileList{1,4} = NaN;
        end
        try
            fileList{1,5} = num2str(info.SeriesNumber);
        catch
            fileList{1,5} = NaN;
        end
        try
            fileList{1,6} = info.PatientName.FamilyName;
        catch
            fileList{1,6} = NaN;
        end
        try
            fileList{1,7} = info.PatientName.GivenName;
        catch
            fileList{1,7} = NaN;
        end
        try
            fileList{1,8} = info.PatientBirthDate;
        catch
            fileList{1,8} = NaN;
        end
        try
            if strcmp(info.Modality,'MR')
                fileList{1,9} = num2str(info.PixelSpacing(1));
            else
                fileList{1,9} = NaN;
            end
        catch
            fileList{1,9} = NaN;
        end
        try
            if strcmp(info.Modality,'MR')
                fileList{1,10} = num2str(info.PixelSpacing(2));
            else
                fileList{1,10} = NaN;
            end
        catch
            fileList{1,10} = NaN;
        end
        try
            if strcmp(info.Modality,'CT')
                fileList{1,11} = num2str(info.NumberofFrames);
            else
                fileList{1,11} = NaN;
            end
        catch
            fileList{1,11} = NaN;
        end
            
       

end



function [ fileList, patientList ] = MC_matRad_scanDicomImportFolder( patDir )
%% get all files in search directory

% dicom import needs image processing toolbox -> check if available
if ~license('checkout','image_toolbox')
    error('image processing toolbox and/or corresponding licence not available');
end

% get information about main directory
mainDirInfo = dir(patDir);
% get index of subfolders
dirIndex = [mainDirInfo.isdir];
% list of filenames in main directory
fileList = {mainDirInfo(~dirIndex).name}';
patientList = 0;

% create full path for all files in main directory
if ~isempty(fileList)
    fileList = cellfun(@(x) fullfile(patDir,x),...
        fileList, 'UniformOutput', false);
    
    %% check for dicom files and differentiate patients, types, and series
    numOfFiles = numel(fileList(:,1));
    h = waitbar(0,'Please wait...');
    %h.WindowStyle = 'Modal';
    steps = numOfFiles;
    for i = numOfFiles:-1:1
        waitbar((numOfFiles+1-i) / steps)
        try % try to get DicomInfo
            info = dicominfo(fileList{i});
        catch
            fileList(i,:) = [];
            continue;
        end
        try
            fileList{i,2} = info.Modality;
        catch
            fileList{i,2} = NaN;
        end
        try
            fileList{i,3} = info.PatientID;
        catch
            fileList{i,3} = NaN;
        end
        try
            fileList{i,4} = info.SeriesInstanceUID;
        catch
            fileList{i,4} = NaN;
        end
        try
            fileList{i,5} = num2str(info.SeriesNumber);
        catch
            fileList{i,5} = NaN;
        end
        try
            fileList{i,6} = info.PatientName.FamilyName;
        catch
            fileList{i,6} = NaN;
        end
        try
            fileList{i,7} = info.PatientName.GivenName;
        catch
            fileList{i,7} = NaN;
        end
        try
            fileList{i,8} = info.PatientBirthDate;
        catch
            fileList{i,8} = NaN;
        end
        try
            if strcmp(info.Modality,'CT')
                fileList{i,9} = num2str(info.PixelSpacing(1));
            else
                fileList{i,9} = NaN;
            end
        catch
            fileList{i,9} = NaN;
        end
        try
            if strcmp(info.Modality,'CT')
                fileList{i,10} = num2str(info.PixelSpacing(2));
            else
                fileList{i,10} = NaN;
            end
        catch
            fileList{i,10} = NaN;
        end
        try
            if strcmp(info.Modality,'CT')
                fileList{i,11} = num2str(info.SliceThickness);
            else
                fileList{i,11} = NaN;
            end
        catch
            fileList{i,11} = NaN;
        end
        
        matRad_progress(numOfFiles+1-i, numOfFiles);
        
    end
    close(h)
    
    if ~isempty(fileList)
        patientList = unique(fileList(:,3));
        % check if there is at least one RT struct and one ct file
        % available per patient
        for i = numel(patientList):-1:1
            if sum(strcmp('CT',fileList(:,2)) & strcmp(patientList{i},fileList(:,3))) < 1 || ...
               sum(strcmp('RTSTRUCT',fileList(:,2)) & strcmp(patientList{i},fileList(:,3))) < 1
                patientList(i) = [];
            end
        end
        
        
    else
        msgbox('No DICOM files found in patient directory!', 'Error','error');
        %h.WindowStyle = 'Modal';
        %error('No DICOM files found in patient directory');
    end
else
    h = msgbox('Search folder empty!', 'Error','error');
    %h.WindowStyle = 'Modal';
    %error('Search folder empty')
    
end
end

function ct = MR_matRad_importDicomCt(ctList, resolution, visBool)


  

    info.Width                   = tmpDicomInfo.Width;
    info.Height                  = tmpDicomInfo.Height;
    info.RescaleSlope            = tmpDicomInfo.RescaleSlope;
    info.RescaleIntercept        = tmpDicomInfo.RescaleIntercept;
    
    
    origCt = zeros(info.Height, info.Width, numOfSlices);

    
end


function ct = MC_matRad_importDicomCt(ctList, resolution, visBool)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% matRad function to import dicom ct data
% 
% call
%   ct = matRad_importDicomCt(ctList, resolution, visBool)
%
% input
%   ctList:         list of dicom ct files
%   resolution:   	resolution of the imported ct cube, i.e. this function
%                   will interpolate to a different resolution if desired
%   visBool:        optional: turn on/off visualization
%
% output
%   ct:             matRad ct struct. Note that this 3D matlab array 
%                   contains water euqivalen electron denisities.
%                   Hounsfield units are converted using a standard lookup
%                   table in matRad_calcWaterEqD
%
% References
%   -
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Copyright 2015, Mark Bangert, on behalf of the matRad development team
%
% m.bangert@dkfz.de
%
% This file is part of matRad.
%
% matrad is free software: you can redistribute it and/or modify it under 
% the terms of the GNU General Public License as published by the Free 
% Software Foundation, either version 3 of the License, or (at your option)
% any later version.
%
% matRad is distributed in the hope that it will be useful, but WITHOUT ANY
% WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
% FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
% details.
%
% You should have received a copy of the GNU General Public License in the
% file license.txt along with matRad. If not, see
% <http://www.gnu.org/licenses/>.
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('\nimporting ct-cube...');

%% processing input variables
if nargin < 3
    visBool = 0;
end

% creation of info list
numOfSlices = size(ctList,1);
fprintf('\ncreating info...')
for i = 1:numOfSlices
    tmpDicomInfo = dicominfo(ctList{i,1});
    
    % rmember relevant dicom info - do not record everything as some tags
    % might not been defined for individual files
    info(i).PixelSpacing            = tmpDicomInfo.PixelSpacing;
    info(i).ImagePositionPatient    = tmpDicomInfo.ImagePositionPatient;
    info(i).SliceThickness          = tmpDicomInfo.SliceThickness;
    info(i).ImageOrientationPatient = tmpDicomInfo.ImageOrientationPatient;
    info(i).PatientPosition         = tmpDicomInfo.PatientPosition;
    info(i).Rows                    = tmpDicomInfo.Rows;
    info(i).Columns                 = tmpDicomInfo.Columns;
    info(i).Width                   = tmpDicomInfo.Width;
    info(i).Height                  = tmpDicomInfo.Height;
    info(i).RescaleSlope            = tmpDicomInfo.RescaleSlope;
    info(i).RescaleIntercept        = tmpDicomInfo.RescaleIntercept;
    
    matRad_progress(i,numOfSlices);
end

% adjusting sequence of slices (filenames may not be ordered propperly....
% e.g. CT1.dcm, CT10.dcm, CT100zCoordList = [info.ImagePositionPatient(1,3)]';.dcm, CT101.dcm,...
CoordList = [info.ImagePositionPatient]';
[~, indexing] = sort(CoordList(:,3)); % get sortation from z-coordinates

ctList = ctList(indexing);
info = info(indexing);

%% check data set for consistency
if size(unique([info.PixelSpacing]','rows'),1) > 1
    error('Different pixel size in different CT slices');
end

coordsOfFirstPixel = [info.ImagePositionPatient];
if numel(unique(coordsOfFirstPixel(1,:))) > 1 || numel(unique(coordsOfFirstPixel(2,:))) > 1
    error('Ct slices are not aligned');
end
if sum(diff(coordsOfFirstPixel(3,:))<=0) > 0
    error('Ct slices not monotonically increasing');
end
if numel(unique([info.Rows])) > 1 || numel(unique([info.Columns])) > 1
    error('Ct slice sizes inconsistent');
end


%% checking the patient position
% As of now, the matRad treatment planning system is only valid for
% patients in a supine position. Other orientations (e.g. prone, decubitus
% left/right) are not supported.
% Defined Terms:
% HFP     Head First-Prone                  (not supported)
% HFS     Head First-Supine                 (supported)
% HFDR    Head First-Decubitus Right        (not supported)
% HFDL    Head First-Decubitus Left         (not supported)
% FFDR    Feet First-Decubitus Right        (not supported)
% FFDL    Feet First-Decubitus Left         (not supported)
% FFP     Feet First-Prone                  (not supported)
% FFS     Feet First-Supine                 (supported)

if isempty(regexp(info(1).PatientPosition,'S', 'once'))
    error(['This Patient Position is not supported by matRad.'...
        ' As of now only ''HFS'' (Head First-Supine) and ''FFS'''...
        ' (Feet First-Supine) can be processed.'])    
end

%% creation of ct-cube
fprintf('reading slices...')
origCt = zeros(info(1).Height, info(1).Width, numOfSlices);
for i = 1:numOfSlices
    currentFilename = ctList{i};
    [currentImage, map] = dicomread(currentFilename);
    origCt(:,:,i) = currentImage(:,:); % creation of the ct cube
    
    % draw current ct-slice
    if visBool
        if ~isempty(map)
            image(ind2rgb(uint8(63*currentImage/max(currentImage(:))),map));
            xlabel('x [voxelnumber]')
            ylabel('y [voxelnumber]')
            title(['Slice # ' int2str(i) ' of ' int2str(numOfSlices)])
        else
            image(ind2rgb(uint8(63*currentImage/max(currentImage(:))),bone));
            xlabel('x [voxelnumber]')
            ylabel('y [voxelnumber]')
            title(['Slice # ' int2str(i) ' of ' int2str(numOfSlices)])
        end
        axis equal tight;
        pause(0.1);
    end
    matRad_progress(i,numOfSlices);
end

%% correction if not lps-coordinate-system
% when using the physical coordinates (ctInfo.ImagePositionPatient) to
% arrange the  slices in z-direction, there is no more need for mirroring
% in the z-direction
fprintf('\nz-coordinates taken from ImagePositionPatient\n')

% The x- & y-direction in lps-coordinates are specified in:
% ImageOrientationPatient
xDir = info(1).ImageOrientationPatient(1:3); % lps: [1;0;0]
yDir = info(1).ImageOrientationPatient(4:6); % lps: [0;1;0]
nonStandardDirection = false;

% correct x- & y-direction

if xDir(1) == 1 && xDir(2) == 0 && xDir(3) == 0
    fprintf('x-direction OK\n')
elseif xDir(1) == -1 && xDir(2) == 0 && xDir(3) == 0
    fprintf('\nMirroring x-direction...')
    origCt = flip(origCt,1);
    fprintf('finished!\n')
else
    nonStandardDirection = true;
end
    
if yDir(1) == 0 && yDir(2) == 1 && yDir(3) == 0
    fprintf('y-direction OK\n')
elseif yDir(1) == 0 && yDir(2) == -1 && yDir(3) == 0
    fprintf('\nMirroring y-direction...')
    origCt = flip(origCt,2);
    fprintf('finished!\n')
else
    nonStandardDirection = true;
end

if nonStandardDirection
    fprintf(['Non-standard patient orientation.\n'...
        'CT might not fit to contoured structures\n'])
end

%% interpolate cube
fprintf('\nInterpolating CT cube...');
ct = matRad_interpCtCube(origCt, info, resolution);
fprintf('finished!\n\n');

%% remember some parameters of original dicom
ct.dicomInfo.PixelSpacing            = info(1).PixelSpacing;
                                       tmp = [info.ImagePositionPatient];
ct.dicomInfo.SlicePositions          = tmp(3,:);
ct.dicomInfo.SliceThickness          = [info.SliceThickness];
ct.dicomInfo.ImagePositionPatient    = info(1).ImagePositionPatient;
ct.dicomInfo.ImageOrientationPatient = info(1).ImageOrientationPatient;
ct.dicomInfo.PatientPosition         = info(1).PatientPosition;
ct.dicomInfo.Width                   = info(1).Width;
ct.dicomInfo.Height                  = info(1).Height;
ct.dicomInfo.RescaleSlope            = info(1).RescaleSlope;
ct.dicomInfo.RescaleIntercept        = info(1).RescaleIntercept;

% convert to water equivalent electron densities
%   fprintf('\nconversion of ct-Cube to waterEqD...');
%   ct = matRad_calcWaterEqD(ct);
%   fprintf('finished!\n');

end