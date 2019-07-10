function data = processBeh(data,params)
%Process Behavior - Process wheel data into velocity and get behavior onset
%and offset indices
%
%   data = processBeh(data,params)
%
%   Description: This function is designed to create velocity traces from
%   rotary wheel data, and it also creates vectors of onset and offset
%   indices based on parameters specified in the params structure
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
%   Author: Pratik Mistry, 2019
%
radius = params.beh.radius; velThres = params.beh.velThres;
winSize = params.beh.winSize;
finalOnset = params.beh.finalOnset;
nAcq = length(data.acq);
for n = 1:nAcq
    if (isfield(data.final(n),'wheel'))
        if (~isempty(data.final(n).wheel))
            wheel = data.final(n).wheel;
        else
            wheel = data.acq(n).wheel;
        end
    else
        wheel = data.acq(n).wheel;
    end
    Fs = data.acq(n).Fs;
    if params.dsRate ~= 0
       wheel = downsample(wheel,params.dsRate);
       Fs = Fs/params.dsRate;
    end
    data.final(n).wheel = wheel;
    data.final(n).Fs = Fs;
    vel = getVel(wheel,radius,Fs,winSize);
    minRest = params.beh.minRestTime * Fs; minRun = params.beh.minRunTime * Fs;
    [onsets,offsets] = getOnsetOffset(vel,velThres,minRest,minRun,finalOnset);
    data.final(n).vel = vel;
    data.final(n).beh.onsetsInd = onsets;
    data.final(n).beh.offsetsInd = offsets;
end