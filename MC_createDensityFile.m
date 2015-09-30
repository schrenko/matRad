function [] = MC_createDensityFile(NAMEoutput,DICOMpath, dim, resolution)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create a binary density file based on matRad .mad + dicom files
% call MC_create_densityfile(NAMEoutput, DICOMpath , dim, resolution)
% input
%     NAMEoutput:    name of outputfile in binary format 
%     DICOMpath:     name ot paht where only dicom CT files are stored
%     dim:           Voxel dimension where denstiy file is extracted
%                    [X1,X2,Y1,Y2,Z1,Z2] X = in Axial view(Left/Right Voxel), Y = in Axial view (Top/Bottom Voxel), Z = in Sagital view (Left/Right Voxel)
%     resolution:    resolution of egsphant voxel [X,Y,Z]
% output
%     NAMEoutput.density : binary file to use for egsnrc simulation
% Explanation: 

        % no HU2water conversation but:
        % Medium            (HUmax-HUmin) / (max density - min density)
        % AIR700ICRU        (-974  -1024) / (0.044 - 0.001)
        % LUNG700ICRU       (-724  -974)  / (0.302 - 0.044)
        % ICRUTISSUE700ICRU (101   -724)  / (1.101 - 0.302)
        % ICRUBONE700ICRU   (1976   101)  / (2.088 - 1.101)

        % HU range from 0-3000 => 

        % AIR700ICRU        (50     0)    / (0.044-0.001)
        % LUNG700ICRU       (300    50)   / (0.302-0.044)
        % ICRUTISSUE700ICRU (1125   300)  / (1.101-0.302)
        % ICRUBONE700ICRU   (1125   3000) / (2.088-1.101)
% Oliver Schrenk
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%define material treshold for conversion ramp:
air.p.min = 0.001; air.p.max = 0.044; air.HU.min = 0; air.HU.max = 50;
lung.p.min = 0.044; lung.p.max = 0.302; lung.HU.min = 50; lung.HU.max = 300;
tissue.p.min = 0.302; tissue.p.max = 1.101; tissue.HU.min = 300; tissue.HU.max = 1125;
bone.p.min = 1.101; bone.p.max = 2.088; bone.HU.min = 1125; bone.HU.max = 3000;

% set egsphant size
Voxel.dimension = dim; 

% swap X and Y: X in density file is eqal to Y in matRad
phantom.dimension = [Voxel.dimension(2)-Voxel.dimension(1),Voxel.dimension(4)-Voxel.dimension(3),Voxel.dimension(6)-Voxel.dimension(5)];

phantom.numbVoxel = phantom.dimension(1)*phantom.dimension(2)*phantom.dimension(3);

% set output file NAMEoutput.density
densityfilename = [NAMEoutput '.density'];
fileID = fopen(densityfilename,'w');
% 0 = big or 1 = little endian
fwrite(fileID,1,'int8');
% number of regions
fwrite(fileID,phantom.dimension,'int32');


% import CT from PATH, no Patient necessary 
CT = MC_importDicom(DICOMpath, resolution);

% calulate postition of planes to define voxel dimensions 
 for i=Voxel.dimension(1):1:Voxel.dimension(2)
     %CT.x (midpoint of voxel) to egsPlane 
     egsPlane = (CT.x(i)-(CT.resolution(1)/2))/10;
     fwrite(fileID,egsPlane,'float32');
 end  
 for i=Voxel.dimension(3):1:Voxel.dimension(4)
     %CT.y (midpoint of voxel) to egsPlane 
     egsPlane = (CT.y(i)-(CT.resolution(2)/2))/10;
     fwrite(fileID,egsPlane,'float32');
 
 end
 for i=Voxel.dimension(5):1:Voxel.dimension(6)
     %CT.y (midpoint of voxel) to egsPlane 
     egsPlane = (CT.z(i)-(CT.resolution(3)/2))/10;
     fwrite(fileID,egsPlane,'float32');
 
 end  



 
% identify ct cube material and set voxel density according to conversion
% ramp
for a=Voxel.dimension(5):1:Voxel.dimension(6)-1
    for b=Voxel.dimension(3):1:Voxel.dimension(4)-1
        for c=Voxel.dimension(1):1:Voxel.dimension(2)-1
            

           if CT.cube(b,c,a) <= 50
            density = air.p.min +((air.p.max-air.p.min)/(air.HU.max-air.HU.min))*(CT.cube(b,c,a)-air.HU.min); 
           elseif CT.cube(b,c,a) <= 300 && CT.cube(b,c,a) > 50
            density = lung.p.min +((lung.p.max-lung.p.min)/(lung.HU.max-lung.HU.min))*(CT.cube(b,c,a)-lung.HU.min); 
           elseif CT.cube(b,c,a) <= 1125 && CT.cube(b,c,a) > 300
            density = tissue.p.min +((tissue.p.max-tissue.p.min)/(tissue.HU.max-tissue.HU.min))*(CT.cube(b,c,a)-tissue.HU.min); 
           elseif CT.cube(b,c,a) > 1125
            density = bone.p.min +((bone.p.max-bone.p.min)/(bone.HU.max-bone.HU.min))*(CT.cube(b,c,a)-bone.HU.min); 
           end
           fwrite(fileID,density,'float32');
         end
    end
end


fprintf('Density file: %s was created! \n\n',densityfilename);
fprintf('Voxel Dimension of %s: X=%d, Y=%d, Z=%d \n', densityfilename, phantom.dimension(1),phantom.dimension(2),phantom.dimension(3));
fprintf('Total number of Voxels: %d \n', phantom.numbVoxel);

            
fclose(fileID);
