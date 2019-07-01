%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  MBL NSB 2019 MOUSE Photometry Processing Script
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all; clc; close all;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MOUSE IDENTIFYING INFORMATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

prompt = {'Enter Human ID:','Enter Mouse ID:','YYMMDD:'};
recInfo = inputdlg(prompt,'Input');
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LOAD and PROCESS DATA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

acqType = menu('data format?','Doric/.csv','Wavesurfer/.h5');
[data] = processNSBdata (acqType, recInfo);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SAVE DATA STRUCTURE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

cd('Z:\NSB_2019\03_MouseStriatum\data\photometry\');    %save to NSB server
save([data.mouseID,'_',data.recdate,'_FP.mat'],'data'); 
cd('C:\Users\MBLUser\Desktop\NSB19_mouse\photometry');  %save to local folder
save([data.mouseID,'_',data.recdate,'_FP.mat'],'data'); 

clearvars -except data 
