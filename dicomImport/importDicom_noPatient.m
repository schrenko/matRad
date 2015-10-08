function [ ct ] = importDicom_noPatient(filepath, resolution)
%IMPORTDICOM_NOPATIENT Summary of this function goes here
%   Detailed explanation goes here
FILELIST.resx = resolution(1);
FILELIST.resy = resolution(2);
FILELIST.resz = resolution(3);
[FILELIST.ct, PATIENTLIST] = matRad_scanDicomImportFolder(filepath);
XYZ_resolution = [FILELIST.resx, FILELIST.resy, FILELIST.resz];
ct = matRad_importDicomCt(FILELIST.ct, resolution); 

end

