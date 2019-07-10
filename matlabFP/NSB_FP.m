%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  MBL NSB 2019 MOUSE Photometry Processing Script
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all; clc; close all;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MOUSE IDENTIFYING INFORMATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

prompt = {'Enter Human ID (e.g. AK or G1):','Enter Mouse ID (e.g. 347A):','YYMMDD:','Experiment:'};
recInfo = inputdlg(prompt,'Input');
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LOAD and PROCESS DATA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

acqType = menu('data format?','Doric/.csv','Wavesurfer/.h5');
[dataAll] = processNSBdata (acqType, recInfo);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PARSE DATA STRUCTURE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[dataRaw, data] = parseDataFile (dataAll);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SAVE DATA STRUCTURE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tic
%cd('Z:\NSB_2019\03_MouseStriatum\data\photometry\');    %save to NSB server
save([data.humanID,'_',data.mouseID,'_',data.recdate,'_',data.experiment,'_rawFP.mat'],'dataRaw'); 
save([data.humanID,'_',data.mouseID,'_',data.recdate,'_',data.experiment,'_FP.mat'],'data'); 
toc
clearvars -except data dataRaw
fprintf('your data has been saved! :) \n')