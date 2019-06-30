%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  MBL NSB 2019 MOUSE Photometry Processing Script
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all; clc; close all;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%MOUSE IDENTIFYING INFORMATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

prompt = {'Enter Human ID:','Enter Mouse ID:','YYMMDD:'};
answer = inputdlg(prompt,'Input');
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%LOAD DATA HERE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

choice = menu('data format?','Doric/.csv','Wavesurfer/.h5');
switch choice
    case 1 
        
        NSB_FPparams_mod %load and run params file
        
        data = struct; %initialize data structure
            data.humanID = answer{1}; %populate inputs
            data.mouseID = answer{2};
            data.recdate = answer{3};
        
        cd('C:\Users\MBLUser\Desktop\NSB19_mouse\photometry\Doric')
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
        
        data.acq = struct; %initialize variables
            data.acq.time = table2array(raw(:,tidx(1)))'; %populate data structure with vectors of signal
            %data.acq.demod = table2array(raw(:,tidx(2)))';
            data.acq.FP = table2array(raw(:,tidx(3)))';
            data.acq.refSig = table2array(raw(:,tidx(4)))';
            data.acq.Fs = 1/mean(diff(data.acq.time)); %sampling freq determined based on time stamps 
            data.acq.nFPChan = 1;
       
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %RUN ANALYSIS
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        demodStatus = params.FP.demodStatus;
        lpCut = params.FP.lpCut; filtOrder = params.FP.filtOrder;
        fitType = params.FP.fitType; winPer = params.FP.winPer;
        dsRate = params.dsRate;

        nFP = data.acq.nFPChan; Fs = data.acq.Fs;

        if demodStatus == 1
            sigEdge = params.FP.sigEdge;
            for n = 1:nFP
                rawFP = data.acq.FP(n,:);
                refSig = data.acq.refSig(n,:);
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
                rawFP = data.acq.FP(n,:);
                FP = filterFP(rawFP,Fs,lpCut,filtOrder,'lowpass');
                FP = baselineFP(FP,fitType,winPer);
                data.final.FP(n,:) = FP;
                if dsRate ~= 0
                    FP = downsample(FP,dsRate);
                end
            end
        end

        data.final.params = params.FP; %save parameters used for analysis

    case 2
        convertH5_FP %convert .h5 file into .mat file for analysis
        analyzeFP    %analyze data
        
        data.humanID = answer{1}; %populate inputs
        data.mouseID = answer{2};
        data.recdate = answer{3};
        
        data = rmfield(data,'mouse'); data = rmfield(data,'date');
end

cd('Z:\NSB_2019\03_MouseStriatum\data\photometry\');
save([data.mouseID,'_',data.recdate,'_FP.mat'],'data'); %save to NSB server
cd('C:\Users\MBLUser\Desktop\NSB19_mouse\photometry')
save([data.mouseID,'_',data.recdate,'_FP.mat'],'data'); %save to local folder

clearvars -except data 
