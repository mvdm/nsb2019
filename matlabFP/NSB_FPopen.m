%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  MBL NSB 2019 MOUSE Photometry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% OPEN DATA (**after analysis with NSB_FP script**)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[dataFile,dataPath] = uigetfile('Z:\NSB_2019\03_MouseStriatum\data\photometry\*.mat');
load(fullfile(dataPath,dataFile));
clearvars -except data

time = data.final.time; %time vector
FP = data.final.FP;     %photometry vector
plotTitle = [data.humanID,'_',data.mouseID,'_',data.recdate]; %plot names

