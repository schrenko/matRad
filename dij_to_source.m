function [ ] = dij_to_source(NAMEoutput,NAMEspectrum,stf,result,boolBeamletORIMRT)

%% open output file
OUTPUTfilename = [NAMEoutput '.imrtsource'];
fileID = fopen( OUTPUTfilename ,'w');
NumberofBixel = 1;

if boolBeamletORIMRT == 0

        for k=1:1:size(stf,2)
            

        EGSrotation.X = 1.570796;
        EGSrotation.Y = (360-stf(k).gantryAngle)*(2*pi/360);
        EGSrotation.Z = 3.141593;

            for i=1:1:stf(k).numOfRays
                    X1(i) =((stf(k).ray(i).rayPos_bev(1)*(-1))-(stf(k).bixelWidth/2))/10;
                    X2(i) =((stf(k).ray(i).rayPos_bev(1)*(-1))+(stf(k).bixelWidth/2))/10;
                    Y1(i) =((stf(k).ray(i).rayPos_bev(3))+(stf(k).bixelWidth/2))/10;
                    Y2(i) =((stf(k).ray(i).rayPos_bev(3))-(stf(k).bixelWidth/2))/10;    
                    % X1 Y1 X2 Y2 

            format_of_seq = ':start source:\n\t library = egs_collimated_source\n\t name = BIXEL%1.0f\n\t :start source shape:\n\t\t type = point\n\t\t position = 0 0 -100\n\t :stop source shape:\n\t';
            fprintf(fileID, format_of_seq,NumberofBixel);
            format_of_seq = ' :start target shape:\n\t\t library = egs_rectangle\n\t\t rectangle = %1.2f %1.2f %1.2f %1.2f\n\t :stop target shape:\n\t\t charge=0\n\t :start spectrum:\n\t\t type = tabulated spectrum\n\t\t spectrum file = %s\n\t :stop spectrum::\n:stop source:\n\n';
            fprintf(fileID, format_of_seq, X1(i),Y1(i),X2(i),Y2(i),NAMEspectrum);

            format_of_seq = ':start source:\n\t library = egs_transformed_source\n\t name = R_BIXEL%1.0f \n\t source name = BIXEL%1.0f\n';
            fprintf(fileID, format_of_seq,NumberofBixel,NumberofBixel);  
            format_of_seq = '\t :start transformation:\n\t\t rotation = %1.6f %1.6f %1.6f\n\t :stop transformation:\n:stop source:\n\n';
            fprintf(fileID, format_of_seq, EGSrotation.X, EGSrotation.Y, EGSrotation.Z); 



            NumberofBixel = NumberofBixel+1; 

            end


    % write to egs imrtsource file


    end

else
 
STRbeamSegmentNames= '';          %string for list of segment names
STRbeamSegmentWeight = '';   %string for list of segment weights   
    

    for k=1:1:size(stf,2)
        
      
  
                                           

        EGSrotation.X = 1.570796;
        EGSrotation.Y = (360-stf(k).gantryAngle)*(2*pi/360);
        EGSrotation.Z = 3.141593;

            for i=1:1:stf(k).numOfRays
                    X1(i) =((stf(k).ray(i).rayPos_bev(1)*(-1))-(stf(k).bixelWidth/2))/10;
                    X2(i) =((stf(k).ray(i).rayPos_bev(1)*(-1))+(stf(k).bixelWidth/2))/10;
                    Y1(i) =((stf(k).ray(i).rayPos_bev(3))+(stf(k).bixelWidth/2))/10;
                    Y2(i) =((stf(k).ray(i).rayPos_bev(3))-(stf(k).bixelWidth/2))/10;    
                    % X1 Y1 X2 Y2 

            format_of_seq = ':start source:\n\t library = egs_collimated_source\n\t name = BIXEL%1.0f\n\t :start source shape:\n\t\t type = point\n\t\t position = 0 0 -100\n\t :stop source shape:\n\t';
            fprintf(fileID, format_of_seq,NumberofBixel);
            format_of_seq = ' :start target shape:\n\t\t library = egs_rectangle\n\t\t rectangle = %1.2f %1.2f %1.2f %1.2f\n\t :stop target shape:\n\t\t charge=0\n\t :start spectrum:\n\t\t type = tabulated spectrum\n\t\t spectrum file = %s\n\t :stop spectrum::\n:stop source:\n\n';
            fprintf(fileID, format_of_seq, X1(i),Y1(i),X2(i),Y2(i),NAMEspectrum);

            format_of_seq = ':start source:\n\t library = egs_transformed_source\n\t name = R_BIXEL%1.0f \n\t source name = BIXEL%1.0f\n';
            fprintf(fileID, format_of_seq,NumberofBixel,NumberofBixel);  
            format_of_seq = '\t :start transformation:\n\t\t rotation = %1.6f %1.6f %1.6f\n\t :stop transformation:\n:stop source:\n\n';
            fprintf(fileID, format_of_seq, EGSrotation.X, EGSrotation.Y, EGSrotation.Z); 
            
            beamSegmentName = [' R_BIXEL',num2str(NumberofBixel)];
            beamSegmentWeight = [' ', num2str(result.w(NumberofBixel))];
            
            STRbeamSegmentNames = strcat(STRbeamSegmentNames, beamSegmentName);
            STRbeamSegmentWeight = strcat(STRbeamSegmentWeight, beamSegmentWeight);


            NumberofBixel = NumberofBixel+1; 

      end

    
    end
    
    
    format_of_seq = ':start source:\n\t library = egs_source_collection\n\t name = IMRT_Source \n\t source names = %s\n\t weights = %s\n:stop source:';
  
    fprintf(fileID, format_of_seq, STRbeamSegmentNames, STRbeamSegmentWeight);

end
fclose(fileID);
      
end

