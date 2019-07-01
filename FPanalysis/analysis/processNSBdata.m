function [data] = processNSBdata(acqType, recInfo)
%Process doric (.csv) and wavesurfer (.h5) data acquired for NSB 2019 mouse
%striatum module
%
% function [data] = processNSBdata(acqType, recInfo)
%
% Created By: Anya Krok
% Created On: 30 June 2019
% Description: convert .csv or .h5 into .mat file, demodulate signal based
% on reference modulation signal, generate data structure

switch acqType
    case 1 
        
        cd('C:\Users\MBLUser\Desktop\NSB19_mouse\photometry\doric')
        [dataFile,dataPath] = uigetfile('*.csv','Select .csv Data File','MultiSelect','Off');
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
        
        data = struct; %initialize data structure
        data.acq = struct; %initialize variables
            data.acq.acqType = ['doric'];
            data.acq.time = table2array(raw(:,tidx(1)))'; %populate data structure with vectors of signal
            %data.acq.demod = table2array(raw(:,tidx(2)))';
            data.acq.FP = table2array(raw(:,tidx(3)))';
            data.acq.refSig = table2array(raw(:,tidx(4)))';
            data.acq.Fs = round(1/mean(diff(data.acq.time))); %sampling freq determined based on time stamps 
            data.acq.nFPchan = 1;

    case 2
        convertH5toFP_nsb %convert .h5 file into .mat file for analysis
        FPfiles = [FPfiles,'.mat'];
        load(fullfile(FPpath,FPfiles));
        data.acq.acqType = ['wavesurfer'];
        data = rmfield(data,'mouse'); data = rmfield(data,'date');
end

data.humanID = recInfo{1}; %populate inputs
data.mouseID = recInfo{2};
data.recdate = recInfo{3};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%RUN ANALYSIS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

NSB_FPparams_mod %load and run params file

demodStatus = params.FP.demodStatus;
lpCut = params.FP.lpCut; filtOrder = params.FP.filtOrder;
fitType = params.FP.fitType; winPer = params.FP.winPer;
dsRate = params.dsRate;
nFP = data.acq.nFPchan; Fs = data.acq.Fs;

%The following lines of code assume a data structure used by the Tritsch
%Lab in our FP analysis

if demodStatus == 1
    sigEdge = params.FP.sigEdge;
    for n = 1:nFP
        rawFP = data.acq.FP(:,n);
        refSig = data.acq.refSig(:,n);
        demodFP = digitalLIA(rawFP,refSig,Fs,lpCut,filtOrder);
        demodFP((sigEdge*Fs)+1:end-(sigEdge*Fs)); %Removes the edge of the signal due to unwanted filtering edge effects
        FP = baselineFP(demodFP,fitType,winPer);
        if dsRate ~= 0
            FP = downsample(FP,dsRate);
        end
        data.final.demod(:,n) = demodFP;
        data.final.FP(:,n) = FP;
    end
else
    for n = 1:nFP
        rawFP = data.acq.FP(:,n);
        FP = filterFP(rawFP,Fs,lpCut,filtOrder,'lowpass');
        FP = baselineFP(FP,fitType,winPer);
        data.final.FP(:,n) = FP;
        if dsRate ~= 0
            FP = downsample(FP,dsRate);
        end
    end
end

data.final.params = params.FP; %save parameters used for analysis

end