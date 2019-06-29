%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%      Woodshole FP Analysis Script
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%LOAD AND RUN PARAMETER FILE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%[paramFile,paramPath] = uigetfile('*.m');
%run(fullfile(paramPath,paramFile));

NSB_FPparams.m

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%LOAD DATA HERE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[dataFile,dataPath] = uigetfile('*.mat');
load(fullfile(dataPath,dataFile));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%RUN ANALYSIS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%The following settings will come from parameter file that the user runs at
%the beginning of the script
demodStatus = params.FP.demodStatus;
lpCut = params.FP.lpCut; filtOrder = params.FP.filtOrder;
fitType = params.FP.fitType; winPer = params.FP.winPer;
dsRate = params.dsRate;

nFP = data.raw.nFPChan; Fs = data.raw.Fs;

%The following lines of code assume a data structure used by the Tritsch
%Lab in our FP analysis
if demodStatus == 1
    sigEdge = params.FP.sigEdge;
    for n = 1:nFP
        rawFP = data.raw.FP(n,:);
        refSig = data.raw.refSig(n,:);
        demodFP = digitalLIA(rawFP,refSig,Fs,lpCut,filtOrder);
        demodFP((sigEdge*Fs)+1:end-(sigEdge*Fs)); %Removes the edge of the signal due to unwanted filtering edge effects
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
