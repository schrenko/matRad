function [DVH]=MC_calcandstoreDVH(Outputname,result,cst,lineStyleIndicator)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% matRad dvh calculation
% 
% call
%   matRad_calcDVH(d,cst,lineStyleIndicator)
%
% input
%   result:             resultGUI struct from fluence optimization/sequencing
%   cst:                matRad cst struct
%   lineStyleIndicator: integer (1,2,3,4) to indicate the current linestyle
%                       (hint: use different lineStyles to overlay
%                       different dvhs)
%
% output
%   graphical display of DVH & dose statistics in console   
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

% create new figure and set default line style indicator if not explictly
% specified

fileID = fopen( Outputname ,'w');

if nargin < 3
    figure
    hold on
    lineStyleIndicator = 1;
else
    hold on
end

numOfVois = size(cst,1);

%% calculate and print the dvh
colorMx    = colorcube;
colorMx    = colorMx(1:floor(64/numOfVois):64,:);

lineStyles = {'-',':','--','-.'};

n = 1000;
if sum(strcmp(fieldnames(result),'RBEWeightedDose')) > 0
    dvhPoints = linspace(0,max(result.RBEWeightedDose(:))*1.05,n);
else
    dvhPoints = linspace(0,max(result.physicalDose(:))*1.05,n);
end
dvh       = NaN * ones(1,n);
fprintf(fileID, 'dvhPoints ');
fprintf(fileID, '%d ', dvhPoints);
fprintf(fileID, '\n');

for i = 1:numOfVois
    
    DVH{i,1}=cst{i,2};
    fprintf(fileID,'%s  ',cst{i,2});
    indices     = cst{i,4};
    numOfVoxels = numel(indices);
    if sum(strcmp(fieldnames(result),'RBEWeightedDose')) > 0
        doseInVoi   = result.RBEWeightedDose(indices);   
    else
        doseInVoi   = result.physicalDose(indices);
    end
    
    % fprintf('%3d %20s - Mean dose = %5.2f Gy +/- %5.2f Gy (Max dose = %5.2f Gy, Min dose = %5.2f Gy)\n', ...
    %     cst{i,1},cst{i,2},mean(doseInVoi),std(doseInVoi),max(doseInVoi),min(doseInVoi))

    for j = 1:n
        dvh(j) = sum(doseInVoi > dvhPoints(j));
  %      fprintf(fileID,'%d ',dvh(j));

    end
    dvh = dvh ./ numOfVoxels * 100;
    fprintf(fileID, '%d ', dvh);

    plot(dvhPoints,dvh,'LineWidth',4,'Color',colorMx(i,:), ...
        'LineStyle',lineStyles{lineStyleIndicator},'DisplayName',cst{i,2});
fprintf(fileID, '\n');

end


DVH{i+1,2} = dvhPoints;

% legend
legend('show');

fontSizeValue = 14;

ylim([0 110])
set(gca,'YTick',0:20:120)

grid on
box(gca,'on');
set(gca,'LineWidth',1.5,'FontSize',fontSizeValue);
set(gcf,'Color','w');
ylabel('Volume [%]','FontSize',fontSizeValue)

if sum(strcmp(fieldnames(result),'RBEWeightedDose')) > 0
    xlabel('RBE x Dose [GyE]','FontSize',fontSizeValue)
else
    xlabel('Dose [Gy]','FontSize',fontSizeValue)
end

fclose(fileID);
end