function data = processMod(data,params)
%Process Modulated Signals
%
%   data = processMod(data,params)
%
%   Description: This function is designed to process photometry signals
%   acquired using the modulation technique, which involves using a sine
%   wave at high frequency (prime number and not a harmonic of sources of
%   electrical interference -- 60Hz). The bulk of this function handles
%   adjusting the signal and storing it into the appropriate data
%   structures
%
%   NOTE: This code will change to add a visualization component for
%   control signals. If red channel flucuates dramatically, then it will
%   allow you to correct for movement artifact
%
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
%

nAcq = length(data.acq);
lpCut = params.FP.lpCut; filtOrder = params.FP.filtOrder;
fitType = params.FP.fitType; winPer = params.FP.winPer;
sigEdge = params.FP.sigEdge;
for n = 1:nAcq
    nFP = data.acq(n).nFPchan;
    nRefSig = length(data.acq(n).refSigNames);
    refSigNames = data.acq(n).refSigNames;
    Fs = data.acq(n).Fs;
    removeEdge = sigEdge*Fs;
    if params.FP.control == 1
        control = data.acq(n).control;
        control(1:ceil(removeEdge/4)) = [];
        for y = 1:nRefSig
            refName = refSigNames{y}; refName(1:4) = []; refName(refName==' ') = [];
            if isequal(refName,'Control')
                refSig = data.acq(n).refSig(:,y);
            end
        end
        refSig(1:ceil(removeEdge/4)) = [];
        control_demod = digitalLIA(control,refSig,Fs,lpCut,filtOrder);
        data.final(n).control = control_demod(ceil(3*removeEdge/4)+1:end-(removeEdge));
        if params.dsRate ~= 0
            data.final(n).control = downsample(data.final(n).control,params.dsRate);
        end
    end
    for x = 1:nFP
        FP = data.acq(n).FP(:,x);
        FP(1:ceil(removeEdge/4)) = [];
        FPname = data.acq(n).FPnames{x}; FPname(FPname==' ') = [];
        for y = 1:nRefSig
            refName = refSigNames{y}; refName(1:4) = []; refName(refName==' ') = [];
            if isequal(refName,FPname)
                refSig = data.acq(n).refSig(:,y);
            end
        end
        refSig(1:ceil(removeEdge/4)) = [];
        FP_demod = digitalLIA(FP,refSig,Fs,lpCut,filtOrder);
        FP_demod = FP_demod(ceil(3*removeEdge/4)+1:end-(removeEdge));
        if params.dsRate ~= 0
            data.final(n).demod(:,x) = downsample(FP_demod,params.dsRate);
        else
            data.final(n).demod(:,x) = FP_demod;
        end
        if params.FP.control == 0
            [data.final(n).FP(:,x),data.final(n).FPbaseline(:,x)] = ...
                baselineFP(data.final(n).demod(:,x),fitType,winPer);
        else
            [data.final(n).FP(:,x),data.final(n).FPbaseline(:,x)] = ...
                baselineFP(data.final(n).demod(:,x),fitType,winPer);
        end
    end
    if params.wheelStatus == 1
        wheel = data.acq(n).wheel;
        wheel = wheel(removeEdge+1:end-removeEdge);
        data.final(n).wheel = wheel;
    end
    if params.dsRate ~= 0
        Fs = Fs/params.dsRate;
    end
    data.final(n).Fs = Fs;
    data.final(n).time = [1:size(data.final(n).FP,1)]/Fs;
end
