function MC_createImrtsourcefromDicomRP(NAMEdicom, NAMEspectrum, NAMEoutput) 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create of input file for egsnrc IMRT-Source
% call MC_createImrtsourcefromDicomRP(NAMEdicom, NAMEspectrum, NAMEoutput) 
% input:
%     NAMEdicom:    name of RP dicom file 
%     NAMEspectrum: name of spectrum to use in egsnrc 
%     NAMEoutput:   how outputfile is called
%
% output
%     NAMEoutput.imrtsource : text file to use for egsnrc imrt source
%     
% Explanation: 
%       One IMRT consists of a defined number of beams, each irradiated with certain angle.
%       One Beam consists of a defined number of segments, each with a certain MLC setting.
%       One Segment is a collection of a number of rectangles, each rectangle is defined by the leaf opening    
%       and the leaf postition boundaries of a single leaf pair.  
% Oliver Schrenk
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get metadata from dicom file
RPfilename = [NAMEdicom '.dcm'];
metadaten = dicominfo(RPfilename);

%% definition of counters
CTRsegments_in =0;
CTRsegments_out = 0;

%% definition of values
probability = ' 1';         %probaprobability for MLC rectangle
STRbeamNames = '';          %string for list of beam names
STRbeamWeights = '';        %string fot list of beam weights
SUMbeamWeights = 0;         %value to normalize beam weighting to 100


%% open output file
OUTPUTfilename = [NAMEoutput '.imrtsource'];
fileID = fopen( OUTPUTfilename ,'w');


%% get general information about IMRT: number of Beams (numberBEAMS)and Leaf-Pairs (numberLEAFPAIRS)
% get number of irradiated beams found in Tag (300A,0080): Number of Beams
numberBEAMS = metadaten.FractionGroupSequence.Item_1.NumberOfBeams; 
%numberBEAMS = metadaten.FractionGroupSequence.Item_1.NumberOfBeams/2; 

% get number of Leaf-pairs of MLC found in Tag (300A,00BC): Number of Leaf/Jaw Pairs
numberLEAFPAIRS = metadaten.BeamSequence.Item_1.BeamLimitingDeviceSequence.Item_3.NumberOfLeafJawPairs;


%% definition of field sizer determined by Leaf size: additional leaf for openfield (81)
% get number of field sizer determined by Leaf size found in Tag(300A,00BE): Leaf Postition Boundaries
fieldsizeLEAFPAIRS = metadaten.BeamSequence.Item_1.BeamLimitingDeviceSequence.Item_3.LeafPositionBoundaries;
fieldsizeLEAFPAIRS(81)=200;




%% loop through every Beam: read informations from RP dicom and generate .imrtsource output 

for i=1:1:numberBEAMS
            
            
            STRbeamSegmentNames= '';          %string for list of segment names
            STRbeamSegmentWeight = '';   %string for list of segment weights

            % get weight of each beam found in Tag (300A,0086): Beam Meterset
            beam.Weight(i) = eval(['metadaten.FractionGroupSequence.Item_1.ReferencedBeamSequence.Item_' num2str(i) '.BeamMeterset']);
            
            % sum up beam weights
            SUMbeamWeights = SUMbeamWeights +  beam.Weight(i);
            
            % get angle of each beam found in Tag (300A,011E): Gantry Angle
            beam.Angle(i) = eval(['metadaten.BeamSequence.Item_' num2str(i) '.ControlPointSequence.Item_1.GantryAngle']);
            
            % recalculation of angle to egsnrc rotation!
            EGSrotation.X(i) = 90*(2*pi/360);               % always 90°
            EGSrotation.Y(i) = beam.Angle(i)*(2*pi/360);    % depends on beam.Angle
            EGSrotation.Z(i) = 180*(2*pi/360);              % always 180°

            % get number of segments for each beam found in Tag (300A,0110): Number of control points
            beam.NumbSegments(i) = eval(['metadaten.BeamSequence.Item_' num2str(i) '.NumberOfControlPoints']);
            % segments are defined as start and stop postition of MLCs. Therefor beam.NumbSegments needs to be divided by 2
            beam.NumbSegments(i) = beam.NumbSegments(i)/2;
          
            % loop to read segment information
                for j=1:1:beam.NumbSegments(i)
                        % get weigth for each segment of each beam found in Tag (300A,0134): Cumulative Meterset Weight
                        % calculate dose differnce to obtain the weight as
                        % part of 1 instead of cumulative
                        beam.SegmentWeight(i,j) = (eval(['metadaten.BeamSequence.Item_' num2str(i) '.ControlPointSequence.Item_' num2str(j*2) '.CumulativeMetersetWeight'])) - (eval(['metadaten.BeamSequence.Item_' num2str(i) '.ControlPointSequence.Item_' num2str((j*2)-1) '.CumulativeMetersetWeight']));
                        
                        % Segment counter +1
                        CTRsegments_in = CTRsegments_in+1 ;

                            for m=1:1:numberLEAFPAIRS
                                % get leaf settings for each leaf pair as
                                % as rectangle shape of MLC opening defined
                                % by upper left and down right coordinates
                                
                                % get X1 coordinate defined by Leaf Postition Boundaries
                                LEAFdefinedRectangle.LEAFX1(CTRsegments_in, m) = fieldsizeLEAFPAIRS(m)/10;    
                                % get X2 coordinate defined by Leaf Postition Boundaries
                                LEAFdefinedRectangle.LEAFX2(CTRsegments_in, m)=  fieldsizeLEAFPAIRS(m+1)/10;  
                                % get Y1 & Y2 coordinate defined by Leaf opening
                                % found in Tag (300A,011C)
                                LEAFdefinedRectangle.LEAFY1(CTRsegments_in, m)=  eval([ 'metadaten.BeamSequence.Item_' num2str(i) '.ControlPointSequence.Item_' num2str(j*2) '.BeamLimitingDevicePositionSequence.Item_2.LeafJawPositions(m)'])/10;
                                %LEAFdefinedRectangle.LEAFY1(CTRsegments_in, m)=  eval([ 'metadaten.BeamSequence.Item_' num2str(i) '.ControlPointSequence.Item_' num2str(j) '.BeamLimitingDevicePositionSequence.Item_3.LeafJawPositions(m)'])/10;

                                LEAFdefinedRectangle.LEAFY2(CTRsegments_in, m) =  eval([ 'metadaten.BeamSequence.Item_' num2str(i) '.ControlPointSequence.Item_' num2str(j*2) '.BeamLimitingDevicePositionSequence.Item_2.LeafJawPositions(m+80)'])/10;
                               % LEAFdefinedRectangle.LEAFY2(CTRsegments_in, m) =  eval([ 'metadaten.BeamSequence.Item_' num2str(i) '.ControlPointSequence.Item_' num2str(j) '.BeamLimitingDevicePositionSequence.Item_3.LeafJawPositions(m+80)'])/10;

                            end;


                 end;    



                          
            % loop to write to egs imrtsource file
               for l=1:1:beam.NumbSegments(i)
               
                                        
                                        STRbeamRectangleProbability = ''; %string to list probabilities of leaf defined Rectangles 


                                        format_of_seq = ':start source:\n\t library = egs_collimated_source\n\t name = BEAM%1.0f_SEGMENT%1.0f\n';
                                        fprintf(fileID, format_of_seq, i, l); 
                                        format_of_seq = '\t :start source shape:\n\t\t type = point\n\t\t position = 0 0 -100\n\t :stop source shape:\n\n\t\t\t :start target shape:\n\t\t\t\t library = egs_shape_collection\n';
                                        fprintf(fileID, format_of_seq);
                                        % segment counter +1
                                        CTRsegments_out = CTRsegments_out+1; 

                                                                   for m=1:1:numberLEAFPAIRS
                                                                            % only define rectangle if leaf pair is open (!
                                                                            if LEAFdefinedRectangle.LEAFY1(CTRsegments_out, m) ~=  LEAFdefinedRectangle.LEAFY2(CTRsegments_out, m)
                                                                                format_of_seq = '\t\t\t\t\t :start shape:\n\t\t\t\t\t\t library = egs_rectangle\n\t\t\t\t\t\t rectangle = %1.6f %1.6f %1.6f %1.6f \n\t\t\t\t\t :stop shape:\n';
                                                                                % top left corner and buttom right corner
                                                                                fprintf(fileID, format_of_seq, LEAFdefinedRectangle.LEAFY1(CTRsegments_out, m), LEAFdefinedRectangle.LEAFX2(CTRsegments_out, m), LEAFdefinedRectangle.LEAFY2(CTRsegments_out, m),LEAFdefinedRectangle.LEAFX1(CTRsegments_out, m));
                                                                                STRbeamRectangleProbability = strcat(STRbeamRectangleProbability, probability); 
                                                                            end;

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


end;

        
%% weight of Beams normalized to 100 
for i=1:1:numberBEAMS

STRbeamWeights = [STRbeamWeights,' ', num2str((beam.Weight(i)/SUMbeamWeights)*100)];

end;

format_of_seq = ':start source:\n\t library = egs_source_collection\n\t name = IMRT_source\n\t source names = %s\n\t weights = %s\n:stop source:\n\n\t simulation source = IMRT_source\n';
fprintf(fileID, format_of_seq, STRbeamNames, STRbeamWeights); %% weight of Beams

fprintf('IMRT Source file: %s was created! \n\n',OUTPUTfilename);

    


fclose(fileID);