%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  MBL NSB 2019 MOUSE Photometry Processing Script
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all; clc; close all;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%LOAD AND RUN PARAMETER FILE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

NSB_FPparams

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%MOUSE IDENTIFYING INFORMATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

prompt = {'Enter Human ID:','Enter Mouse ID:','YYMMDD:'};
answer = inputdlg(prompt,'Input');

data = struct; %initialize data structure
    data.humanID = answer{1}; %populate inputs
    data.mouseID = answer{2};
    data.recdate = answer{3};
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%LOAD DATA HERE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

choice = menu('data format?','.csv','.mat');
switch choice
    case 1 
        data = struct; %initialize data structure
            data.humanID = answer{1}; %populate inputs
            data.mouseID = answer{2};
            data.recdate = answer{3};
        
        cd('C:\Users\MBLUser\Desktop\NSB19_mouse\photometry')
        [dataFile,dataPath] = uigetfile('*.csv');
        cd(dataPath)
        opts = detectImportOptions([dataFile],'NumHeaderLines',1); % number of header lines which are to be ignored
        opts.VariableNamesLine = 2; % row number which has variable names
        opts.DataLine = 3; % row number from which the actual data starts
        
        raw = readtable([dataFile],opts); %read in .csv file into table
        
        tidx = [find(string(raw.Properties.VariableNames) == "Time_s_"), ...
            find(string(raw.Properties.VariableNames) == "AIn_1_Dem_AOut_1_"), ...
            find(string(raw.Properties.VariableNames) == "AIn_1_Raw"), ...
            find(string(raw.Properties.VariableNames) == "AIn_2")
            ]; %identify column indices based on variable names
        
        data.raw = struct; %initialize variables
            data.raw.time = table2array(raw(:,tidx(1)))'; %populate data structure with vectors of signal
            %data.raw.demod = table2array(raw(:,tidx(2)))';
            data.raw.FP = table2array(raw(:,tidx(3)))';
            data.raw.refSig = table2array(raw(:,tidx(4)))';
            data.raw.Fs = 1/mean(diff(data.raw.time)); %sampling freq determined based on time stamps 
            data.raw.nFPChan = 1;
        
        dataFile = dataFile(1:end-4); %remove .csv from string

    case 2
        convertH5_FP
        analyzeFP
        
        %[dataFile,dataPath] = uigetfile('*.mat');
        %load(fullfile(dataPath,dataFile));
        
        data.humanID = answer{1}; %populate inputs
        data.mouseID = answer{2};
        data.recdate = answer{3};
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%RUN ANALYSIS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

demodStatus = params.FP.demodStatus;
lpCut = params.FP.lpCut; filtOrder = params.FP.filtOrder;
fitType = params.FP.fitType; winPer = params.FP.winPer;
dsRate = params.dsRate;

nFP = data.raw.nFPChan; Fs = data.raw.Fs;

if demodStatus == 1
    sigEdge = params.FP.sigEdge;
    for n = 1:nFP
        rawFP = data.raw.FP(n,:);
        refSig = data.raw.refSig(n,:);
        demodFP = digitalLIA(rawFP,refSig,Fs,lpCut,filtOrder);
        demodFP(round((sigEdge*Fs)+1):round(end-(sigEdge*Fs))); %Removes the edge of the signal due to unwanted filtering edge effects
        FP = baselineFP(demodFP,fitType,winPer);
        if dsRate ~= 0
            FP = downsample(FP,dsRate);
        end
        data.final.FP(n,:) = FP;
    end
   
else
    for n = 1:nFP
        rawFP = data.raw.FP(n,:);
        FP = filterFP(rawFP,Fs,lpCut,filtOrder,'lowpass');
        FP = baselineFP(FP,fitType,winPer);
        data.final.FP(n,:) = FP;
        if dsRate ~= 0
            FP = downsample(FP,dsRate);
        end
    end
end

data.final.params = params.FP; %save parameters used for analysis
save([data.mouseID,'_',data.recdate,'_FP.mat'],'data'); %save to local folder
%save([dataFile,'.mat'],'data'); %save to local folder
cd('Z:\NSB_2019\03_MouseStriatum\data\photometry\');
save([data.mouseID,'_',data.recdate,'_FP.mat'],'data'); %save to NSB server

clearvars -except data 
