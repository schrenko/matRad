function [] = dicom_to_egsphant(NAMEoutput,DICOMpath, dim, resolution)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create an egsphant file based on matRad .mad dicom
% call dicom_to_egsphant(NAMEoutput, DICOMpath , dim, resolution)
% input
%     NAMEoutput:    name of outputfile in egsphant format
%     DICOMpath:     name ot paht where dicom CT files (only) are stored
%     dim:           Voxel dimension where egsphant is produced
%                    [X1,X2,Y1,Y2,Z1,Z2] X = Axial L->R, Y = Axial T->B, Z = Sagital L->R
%     resolution:    resolution of egsphant voxel [2,2,2]
% output
%     NAMEoutput.egsphant : text file to use for egsnrc imrt source
%     
% Explanation: 
        % no HU2water conversation
        % Medium (CTmax-CTmin)/(max density -min density)
        % AIR700ICRU   (-974  -1024)/(0.044-0.001)
        % LUNG700ICRU  (-724  -974)/(0.302-0.044)
        % ICRUTISSUE700ICRU (101 -724)/(1.101-0.302)
        % ICRUBONE700ICRU   (1976  101)/2.088-1.101)

        %HU from 0-3000 => 

        % AIR700ICRU   (50  0)/(0.044-0.001)
        % LUNG700ICRU  (300  50)/(0.302-0.044)
        % ICRUTISSUE700ICRU (1125 300)/(1.101-0.302)
        % ICRUBONE700ICRU   (1125  3000)/2.088-1.101)
% Oliver Schrenk
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%define material treshold for conversion ramp:
air.p.min = 0.001; air.p.max = 0.044; air.HU.min = 0; air.HU.max = 50;
lung.p.min = 0.044; lung.p.max = 0.302; lung.HU.min = 50; lung.HU.max = 300;
tissue.p.min = 0.302; tissue.p.max = 1.101; tissue.HU.min = 300; tissue.HU.max = 1125;
bone.p.min = 1.101; bone.p.max = 2.088; bone.HU.min = 1125; bone.HU.max = 3000;

% import CT form PATH
CT = importDicom_noPatient(DICOMpath, resolution);
% set egsphant size
Voxel.dimension = dim; 
Voxel.Xmin = CT.x(Voxel.dimension(1));
Voxel.Xmax = CT.x(Voxel.dimension(2));
Voxel.Ymin = CT.y(Voxel.dimension(3));
Voxel.Ymax = CT.y(Voxel.dimension(4));
Voxel.Zmin = CT.z(Voxel.dimension(5));
Voxel.Zmax = CT.z(Voxel.dimension(6));

% swap X and Y: X egspant is eqal to Y in dicom
phantom.dimension = [Voxel.dimension(2)-Voxel.dimension(1),Voxel.dimension(4)-Voxel.dimension(3),Voxel.dimension(6)-Voxel.dimension(5)];


% create outputfile
egsphant.name = [NAMEoutput '.egsphant'];
fileID = fopen( egsphant.name ,'w');

%write header to outputfile
fprintf(fileID, ' 4\nAIR700ICRU              \nLUNG700ICRU             \nICRUTISSUE700ICRU       \nICRPBONE700ICRU         \n'); 
fprintf(fileID, '   1.00000000       1.00000000       1.00000000       1.00000000    \n'); 
format_of_seq = '  %1.0f  %1.0f   %1.0f\n   ';
fprintf(fileID,format_of_seq,phantom.dimension(1),phantom.dimension(2),phantom.dimension(3)); 

%%write voxel boundaries to outputfile
format_of_seq = '%1.8f       ';

for i=Voxel.dimension(1):1:Voxel.dimension(2)
    % from CT.x (midpoint of voxel to egsphant plan (egsPlan) there for
    % Voxel.dimension(2)+1
    egsPlan = (CT.x(i)-(CT.resolution(1)/2))/10;
    fprintf(fileID,format_of_seq,egsPlan);  
end  

fprintf(fileID,'\n   ');

for i=Voxel.dimension(3):1:Voxel.dimension(4)
    % from CT.x (midpoint of voxel to egsphant plan (egsPlan) there for
    % Voxel.dimension(2)+1
    egsPlan = (CT.y(i)-(CT.resolution(2)/2))/10;
    fprintf(fileID,format_of_seq,egsPlan);
end

fprintf(fileID,'\n  ');

for i=Voxel.dimension(5):1:Voxel.dimension(6)
    % from CT.x (midpoint of voxel to egsphant plan (egsPlan) there for
    % Voxel.dimension(2)+1
    egsPlan = (CT.z(i)-(CT.resolution(3)/2))/10;
    fprintf(fileID,format_of_seq,egsPlan);
end    

fprintf(fileID,'\n');

%define Medium from HU values and write it to outputfile
for a=Voxel.dimension(5):1:Voxel.dimension(6)-1
    for b=Voxel.dimension(3):1:Voxel.dimension(4)-1
        for c=Voxel.dimension(1):1:Voxel.dimension(2)-1
           if CT.cube(b,c,a) <= 50
              CT.material(b,c,a) = 1;    
           fprintf(fileID,'1');
           elseif CT.cube(b,c,a) <= 300 && CT.cube(b,c,a) > 50
              CT.material(b,c,a) = 2;    
              fprintf(fileID,'2');
           elseif CT.cube(b,c,a) <= 1125 && CT.cube(b,c,a) > 300
              CT.material(b,c,a) = 3;    
           fprintf(fileID,'3');
           elseif CT.cube(b,c,a) > 1125
              CT.material(b,c,a) = 4;
           fprintf(fileID,'4');
           end
         end
        fprintf(fileID,'\n');
    end
    fprintf(fileID,'\n');
end

%conversion of HU to density by equiation of Kawrakow
format_of_seq = '   %1.8f    ';

for a=Voxel.dimension(5):1:Voxel.dimension(6)-1
    for b=Voxel.dimension(3):1:Voxel.dimension(4)-1
        for c=Voxel.dimension(1):1:Voxel.dimension(2)-1
           
            if CT.material(b,c,a) == 1
            density = air.p.min +((air.p.max-air.p.min)/(air.HU.max-air.HU.min))*(CT.cube(b,c,a)-air.HU.min); 
            fprintf(fileID,format_of_seq,density);
            elseif CT.material(b,c,a) == 2
            density = lung.p.min +((lung.p.max-lung.p.min)/(lung.HU.max-lung.HU.min))*(CT.cube(b,c,a)-lung.HU.min); 
            fprintf(fileID,format_of_seq,density);    
            elseif CT.material(b,c,a) == 3
            density = tissue.p.min +((tissue.p.max-tissue.p.min)/(tissue.HU.max-tissue.HU.min))*(CT.cube(b,c,a)-tissue.HU.min); 
            fprintf(fileID,format_of_seq,density);    
            elseif CT.material(b,c,a) == 4
            density = bone.p.min +((bone.p.max-bone.p.min)/(bone.HU.max-bone.HU.min))*(CT.cube(b,c,a)-bone.HU.min); 
            fprintf(fileID,format_of_seq,density);  
            end
            
         end
       fprintf(fileID,'\n');
    end
    fprintf(fileID,'\n');
end
            
fclose(fileID);
