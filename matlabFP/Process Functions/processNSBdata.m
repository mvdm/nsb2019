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
%


tic
switch acqType
    case 1 
        data = struct; %initialize data structure
        data.acqType = ['doric'];
        
        %cd('C:\Users\MBLUser\Desktop\NSB19_mouse\photometry\doric')
        [dataFile,dataPath] = uigetfile('*.csv','Select .csv Data File','MultiSelect','On'); %load CSV file outputted by doric
        cd(dataPath) %call data path where CSV file is located for reading in table 
        nFiles = length(dataFile);
        
    for n = 1:nFiles
        if iscell(dataFile)
        csvName = dataFile{n};
        else
            csvName = dataFile;
        end
        
        opts = detectImportOptions([csvName],'NumHeaderLines',1); % number of header lines which are to be ignored
            opts.VariableNamesLine = 2; % row number which has variable names
            opts.DataLine = 3; % row number from which the actual data starts
        
            raw = readtable([csvName],opts); %read in .csv file into table
        
        tidx = [find(string(raw.Properties.VariableNames) == "Time_s_"), ...
            find(string(raw.Properties.VariableNames) == "AIn_1_Dem_AOut_1_"), ...
            find(string(raw.Properties.VariableNames) == "AIn_1_Raw"), ...
            find(string(raw.Properties.VariableNames) == "AIn_2")]; %identify column indices based on variable names
               
        temp = struct; %initialize variables
            acqTime = table2array(raw(:,tidx(1))); %populate data structure with vectors of signal
            temp.FP = table2array(raw(:,tidx(3)));
            temp.refSig = table2array(raw(:,tidx(4)));
            temp.Fs = round(1/mean(diff(acqTime))); %sampling freq determined based on time stamps 
            temp.nFPchan = 1;
            
        if ismember('AIn_1_Dem_AOut_2_', raw.Properties.VariableNames) %doric demodulated signal
            ctrIdx = find(string(raw.Properties.VariableNames) == "AIn_1_Dem_AOut_2_");
            temp.control = table2array(raw(:,ctrIdx));
            temp.control = demodstr2num(temp.control)';
        end
         
        if ismember('DI_O_1', raw.Properties.VariableNames) %doric DI signal in digital input channel 1
            dIdx = find(string(raw.Properties.VariableNames) == "DI_O_1");
            temp.dig = table2array(raw(:,dIdx));
        end    
        
        data.acq(n) = temp;
        fprintf('file number %1.0f has been loaded \n', n) 
    end
        
    case 2
        convertH5toFP_nsb %convert .h5 file into .mat file for analysis
        FPfiles = [FPfiles,'.mat'];
        load(fullfile(FPpath,FPfiles));
        data.acqType = ['wavesurfer'];
        data = rmfield(data,'mouse'); data = rmfield(data,'date'); %removes fields used for T-Lab analysis
end

data.humanID = recInfo{1}; %populate inputs to identify data
data.mouseID = recInfo{2};
data.recdate = recInfo{3};
data.experiment = recInfo{4};

fprintf('your data has been loaded into MATLAB - woohoo! \n')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%RUN ANALYSIS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%cd('Z:\NSB_2019\03_MouseStriatum\code\matlabFP\Parameter Files\');
[paramFiles,paramPath] = uigetfile('*.m','Select FP Parameters File','MultiSelect','Off');
if (~iscell(paramFiles))
    paramFiles = {paramFiles};
end
run(fullfile(paramPath,paramFiles{1})); %parameters for signal processing

demodStatus = params.FP.demodStatus;
nFP = data.acq(1).nFPchan; 
Fs = data.acq(1).Fs;
lpCut = params.FP.lpCut; 
filtOrder = params.FP.filtOrder;
fitType = params.FP.fitType; 
winPer = params.FP.winPer;
if params.dsRate ~= 0
    newFs = params.newFs;
    dsRate = floor(Fs/newFs); %downsampling to ~50Hz
else
    dsRate = params.dsRate;
end

%the following lines of code assume a T-Lab style data structure
for a = 1:length(data.acq)
    
if demodStatus == 1
    sigEdge = params.FP.sigEdge;
    for n = 1:nFP
        rawFP = data.acq(a).FP(:,n);
        refSig = data.acq(a).refSig(:,n);
        demodFP = digitalLIA(rawFP,refSig,Fs,lpCut,filtOrder); %lock-in amplifier demodulatiom
        demodFP((sigEdge*Fs)+1:end-(sigEdge*Fs)); %removes the edge of the signal due to unwanted filtering edge effects
        FP = baselineFP(demodFP,fitType,winPer); %baseline adjust photometry to get dF/F
        if dsRate ~= 0
            FP = downsample(FP,dsRate); %downsample to ~50Hz
            data.final(a).Fs = Fs/dsRate;
            data.final(a).params.dsRate = dsRate;
        end
        data.final(a).FP(:,n) = FP;
    end
else
    for n = 1:nFP
        rawFP = data.acq(a).FP(:,n);
        FP = filterFP(rawFP,Fs,lpCut,filtOrder,'lowpass'); %lowpass filter, usually <10Hz
        FP = baselineFP(FP,fitType,winPer); %baseline adjust photometry to get dF/F
        if dsRate ~= 0
            FP = downsample(FP,dsRate); %downsample to ~50Hz
            data.final(a).params.dsRate = dsRate;
            data.final(a).Fs = Fs/dsRate;
        end
        data.final(a).FP(:,n) = FP;
    end
end

if isfield(data.acq(a),'control') && dsRate ~= 0 %isosbestic demodulated signal from Doric software
    data.final(a).control = downsample(data.acq(a).control,dsRate);
end

if isfield(data.acq(a),'control') && dsRate == 0 %isosbestic demodulated signal from Doric software
    data.final(a).control = data.acq(a).control;
end

if isfield(data.acq(a),'trig') && dsRate ~= 0  %trigger/TTL analog input from Wavesurfer software
    data.final(a).trig = downsample(data.acq(a).trig,dsRate);
end

if isfield(data.acq(a),'dig') %process DI signal, generate on and off times
    [data.final(a).digOn, data.final(a).digOff] = getPulseOnsetOffset(data.acq(a).dig, 0.8); %threshold 0.8
    data.final(a).digOn  = data.final(a).digOn/Fs; %convert to seconds
    data.final(a).digOff = data.final(a).digOff/Fs; %convert to seconds
end

data.final(a).params = params.FP; %save parameters used for analysis
data.final(a).time = [(1/data.final(a).Fs):(1/data.final(a).Fs):(length(data.final(a).FP)/data.final(a).Fs)];
data.final(a).time = data.final(a).time(1:length(data.final(a).FP))'; %time vector for plotting

fprintf('file number %1.0f has been processed \n', a)
end
fprintf('your data has been processed - hooray! \n')

toc
end