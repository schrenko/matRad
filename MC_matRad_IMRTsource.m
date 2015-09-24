function MC_matRad_IMRTsource(IMRTsourcename,NAMEspectrum,PLN,INFO )
% PLN = pln
% INFO = resultGUI.aparutreinfo
SUMbeamWeights = 0;         %value to normalize beam weighting to 100
CTRsegments_in = 0;
CTRsegments_out = 0;
CTRLEAFpair = 0;

imrt.name = [IMRTsourcename '.imrtsource'];
fileID = fopen(imrt.name ,'w');
probability =' 1';

numberBEAM = PLN.numOfBeams;
numberLEAFPAIRS = INFO.numOfMLCLeafPairs;
STRbeamNames = '';
STRbeamWeights = '';        %string fot list of beam weights


for i=1:1:numberBEAM
            STRbeamSegmentNames= '';          %string for list of segment names
            STRbeamSegmentWeight = '';   %string for list of segment weights

    beam.Weight(i) = 1;
    SUMbeamWeights = SUMbeamWeights + beam.Weight(i);
    beam.Angle(i) = PLN.gantryAngles(i);
    
     % recalculation of angle to egsnrc rotation!
     EGSrotation.X(i) = 90*(2*pi/360);               % always 90°
     EGSrotation.Y(i) = beam.Angle(i)*(2*pi/360);    % depends on beam.Angle
     EGSrotation.Z(i) = 180*(2*pi/360);              % always 180°
     
     beam.NumbSegments(i) = INFO.beam(i).numOfShapes;
    
             for j=1:1:beam.NumbSegments(i)
             CTRLEAFpair = 0;    
                 beam.SegmentWeight(i,j) = INFO.beam(i).shape(j).weight;
                 CTRsegments_in = CTRsegments_in+1 ;

                     for m=1:1:numberLEAFPAIRS
                        if  INFO.beam(i).isActiveLeafPair(m) == 1
                        CTRLEAFpair = CTRLEAFpair+1;
                        LEAFdefinedRectangle.LEAFX1(CTRsegments_in,CTRLEAFpair) = INFO.beam(i).leafPairPos(CTRLEAFpair)/10;
                        LEAFdefinedRectangle.LEAFX2(CTRsegments_in,CTRLEAFpair) = (INFO.beam(i).leafPairPos(CTRLEAFpair)+INFO.bixelWidth)/10;
                        LEAFdefinedRectangle.LEAFY1(CTRsegments_in,CTRLEAFpair) = INFO.beam(i).shape(j).leftLeafPos(CTRLEAFpair)/10;
                        LEAFdefinedRectangle.LEAFY2(CTRsegments_in,CTRLEAFpair) = INFO.beam(i).shape(j).rightLeafPos(CTRLEAFpair)/10;
                       end
                        
                     end
                                
             end
             
             
             
             
             
             
             for l=1:1:beam.NumbSegments(i)
               
                                        
                                        STRbeamRectangleProbability = ''; %string to list probabilities of leaf defined Rectangles 


                                        format_of_seq = ':start source:\n\t library = egs_collimated_source\n\t name = BEAM%1.0f_SEGMENT%1.0f\n';
                                        fprintf(fileID, format_of_seq, i, l); 
                                        format_of_seq = '\t :start source shape:\n\t\t type = point\n\t\t position = 0 0 -100\n\t :stop source shape:\n\n\t\t\t :start target shape:\n\t\t\t\t library = egs_shape_collection\n';
                                        fprintf(fileID, format_of_seq);
                                        % segment counter +1
                                        CTRsegments_out = CTRsegments_out+1; 

                                                                   for m=1:1:CTRLEAFpair
                                                                            % only define rectangle if leaf pair is open (!
                                                                                format_of_seq = '\t\t\t\t\t :start shape:\n\t\t\t\t\t\t library = egs_rectangle\n\t\t\t\t\t\t rectangle = %1.4f %1.4f %1.4f %1.4f \n\t\t\t\t\t :stop shape:\n';
                                                                                % top left corner and buttom right corner
                                                                                fprintf(fileID, format_of_seq, LEAFdefinedRectangle.LEAFY1(CTRsegments_out, m), LEAFdefinedRectangle.LEAFX2(CTRsegments_out, m), LEAFdefinedRectangle.LEAFY2(CTRsegments_out, m),LEAFdefinedRectangle.LEAFX1(CTRsegments_out, m));
                                                                                STRbeamRectangleProbability = strcat(STRbeamRectangleProbability, probability); 

                                                                   end;

                                          beamSegmentName = [' BEAM',num2str(i),'_SEGMENT',num2str(l)];
                                          beamSegmentWeight = [' ', num2str(beam.SegmentWeight(i,l))];
                                          %fill srings  
                                          STRbeamSegmentNames = strcat(STRbeamSegmentNames, beamSegmentName);
                                          STRbeamSegmentWeight = strcat(STRbeamSegmentWeight, beamSegmentWeight);
                                          
                                          format_of_seq = '\n\t probabilities = %s\n\t\t\t:stop target shape:\n\t\t\t charge = 0\n';
                                          fprintf(fileID, format_of_seq, STRbeamRectangleProbability);  

                                          format_of_seq  = '\t\t :start spectrum:\n\t\t\t type = tabulated spectrum\n\t\t\t spectrum file = %s\n\t\t:stop spectrum:\n:stop source:\n\n';  
                                          fprintf(fileID, format_of_seq, NAMEspectrum);  

                 end;

                format_of_seq = ':start source:\n\t library = egs_source_collection\n\t name = BEAM%1.0f \n\t source names = %s\n';
                fprintf(fileID, format_of_seq, i, STRbeamSegmentNames);  
                format_of_seq = '\t weights = %s \n:stop source:\n\n';
                fprintf(fileID, format_of_seq, STRbeamSegmentWeight);  

                format_of_seq = ':start source:\n\t library = egs_transformed_source\n\t name = BEAM%1.0f_ROTATION\n\t source name = BEAM%1.0f\n';
                fprintf(fileID, format_of_seq, i,i);  

                format_of_seq = '\t :start transformation:\n\t\t rotation = %1.6f %1.6f %1.6f\n\t :stop transformation:\n:stop source:\n\n';
                fprintf(fileID, format_of_seq, EGSrotation.X(i), EGSrotation.Y(i), EGSrotation.Z(i) ); %% angle from dicom???

                beamName = [' BEAM',num2str(i),'_ROTATION'];
                STRbeamNames = strcat(STRbeamNames, beamName);

        
        
end

for i=1:1:numberBEAM

  STRbeamWeights = [STRbeamWeights,' ', num2str((beam.Weight(i)/SUMbeamWeights)*100)];

end;

format_of_seq = ':start source:\n\t library = egs_source_collection\n\t name = IMRT_source\n\t source names = %s\n\t weights = %s\n:stop source:\n\n\t simulation source = IMRT_source\n';
fprintf(fileID, format_of_seq, STRbeamNames, STRbeamWeights); %% weight of Beams

    


fclose(fileID);






