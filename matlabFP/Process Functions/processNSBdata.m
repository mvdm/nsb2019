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
        [data, out] = pullDoric();

    case 2
        convertH5toFP_nsb %convert .h5 file into .mat file for analysis
        FPfiles = [FPfiles,'.mat'];
        load(fullfile(FPpath,FPfiles));
        data.acqType = ['wavesurfer'];
        data = rmfield(data,'mouse'); %removes fields used for T-Lab analysis
        data = rmfield(data,'date'); 
end

data.humanID = recInfo{1}; %populate inputs to identify data
data.mouseID = recInfo{2};
data.recdate = recInfo{3};
data.exp     = recInfo{4};

fprintf('your data has been loaded into MATLAB - woohoo! \n')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% LOAD PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[paramFiles,paramPath] = uigetfile('*.m','Select FP Parameters File','MultiSelect','Off');
if (~iscell(paramFiles))
    paramFiles = {paramFiles};
end
run(fullfile(paramPath,paramFiles{1})); %parameters for signal processing

demodStatus = params.FP.demodStatus;
lpCut       = params.FP.lpCut; 
filtOrder   = params.FP.filtOrder;
fitType     = params.FP.fitType; 
winPer      = params.FP.winPer;
sigEdge     = params.FP.sigEdge;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% PROCESS PHOTOMETRY SIGNAL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for a = 1:length(data.acq)
    
    Fs = data.acq(1).Fs;
    if params.dsRate ~= 0
        dsRate = floor(Fs/params.newFs); %downsampling to new Fs
    else
        dsRate = params.dsRate;
    end

    if demodStatus == 1
        rawFP = data.acq(a).FP(:,n);
        refSig = data.acq(a).refSig(:,n);
        demodFP = digitalLIA(rawFP,refSig,Fs,lpCut,filtOrder); %lock-in amplifier demodulation    
        demodFP((sigEdge*Fs)+1:end-(sigEdge*Fs)); %removes the edge of the signal due to unwanted filtering edge effects
        FP = baselineFP(demodFP,fitType,winPer); 
    else
        rawFP = data.acq(a).FP(:,n);
        FP = filterFP(rawFP,Fs,lpCut,filtOrder,'lowpass'); %lowpass filter, usually <10Hz
        FP = baselineFP(FP,fitType,winPer); 
    end

    if dsRate ~= 0
        FP = downsample(FP,dsRate); %downsample to ~50Hz
        data.final(a).Fs = Fs/dsRate;
        data.final(a).params.dsRate = dsRate;
    end
    
    data.final(a).FP(:,n) = FP; %populate structure
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% PROCESS ADDITIONAL INPUT SIGNALS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if isfield(data.acq(a),'control') && dsRate ~= 0 %isosbestic demodulated signal from Doric software
        data.final(a).control = downsample(data.acq(a).control,dsRate);
    elseif isfield(data.acq(a),'control') && dsRate == 0 %isosbestic demodulated signal from Doric software
        data.final(a).control = data.acq(a).control;
    end

    if isfield(data.acq(a),'dig') %process DI signal, generate on and off times
        [data.final(a).digOn, data.final(a).digOff] = getSigOnOff(data.acq(a).dig, 0.8); %threshold 0.8
        data.final(a).digOn  = data.final(a).digOn/Fs; %convert to seconds
        data.final(a).digOff = data.final(a).digOff/Fs; %convert to seconds
    end

    data.final(a).params = params.FP; %save parameters used for analysis
    data.final(a).time = [(1/data.final(a).Fs):(1/data.final(a).Fs):(length(data.final(a).FP)/data.final(a).Fs)];
    data.final(a).time = data.final(a).time(1:length(data.final(a).FP))'; %time vector for plotting

    h = waitbar(a/length(data.acq), 'processing data');
    
end

close(h)
fprintf('your data has been processed - hooray! \n')

toc
end