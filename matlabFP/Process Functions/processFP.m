function [data] = processFP(data,params)
%Process Fiber Photometry
%
%   [data] = processFP(data,params)
%
%   Description: This function is designed to process fiber photometry data
%   for the lab. The function performs demodulation (if selected),
%   filtering, baselining, and downsampling for all photometry traces in
%   the recording. The parameters for the analysis are found in the params
%   structure, which is created from a user-created scripted based on the
%   processParam.m file.
%
%   Input:
%   - data - A data structure specific to the Tritsch Lab. Created using
%   the convertH5_FP script
%   - params - A structure created from a variant of the processParams
%   script
%
%   Output:
%   - data - Updated data structure containing processed data
%
%   Author: Pratik Mistry 2019

nAcq = length(data.acq);
lpCut = params.FP.lpCut; filtOrder = params.FP.filtOrder;
dsRate = params.dsRate;
fitType = params.FP.fitType; winPer = params.FP.winPer;

for n = 1:nAcq
    rawFs = data.acq(n).Fs;
    Fs = rawFs;
    nFP = data.acq(n).nFPchan;
    for x = 1:nFP
        rawFP = data.acq(n).FP(:,x);
        FP = filterFP(rawFP,rawFs,lpCut,filtOrder,'lowpass');
        if dsRate ~= 0
            FP = downsample(FP,dsRate);
            Fs = rawFs/dsRate;
        end
        [FP,baseline] = baselineFP(FP,fitType,winPer);
        L = length(FP);
        data.final(n).FP(1:L,x) = FP;
        data.final(n).FPbaseline(1:L,x) = baseline;
    end
    data.final(n).Fs = Fs;
    data.final(n).time = [1:L]/Fs;
end