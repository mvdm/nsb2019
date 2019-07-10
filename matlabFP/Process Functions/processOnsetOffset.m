function data = processOnsetOffset(data,params)
%Process Onset and Offset Data
%
%   data = processOnsetOffset(data,params)
%
%   Description: This function takes a data structure with velocity traces,
%   onset and offset indicies, and fiber photometry data and aligns
%   photometry to movement onset and offset. This code was organized using
%   functions and lines of code already created by Jeffrey March
%
%   Input:
%   - data - A data structure specific to the Tritsch Lab. Created using
%   the convertH5_FP script that is included in the analysis package
%   - params - A structure created from a variant of the processParams
%   script
%
%   Output:
%   - data - Updated data structure containing final data
%
%   Author: Pratik Mistry, 2019
%
    nAcq = length(data.acq);
    for n = 1:nAcq
        Fs = data.final(n).Fs;
        timeAfter = params.beh.timeAfter * Fs;
        timeBefore = params.beh.timeBefore * Fs;
        timeThres = params.beh.timeThres * Fs;
        vel = data.final(n).vel; vel = abs(vel);
        onSetsInd = data.final(n).beh.onsetsInd; offSetsInd = data.final(n).beh.offsetsInd;
        [onSetsInd,offSetsInd] = adjOnsetOffset(onSetsInd,offSetsInd,timeThres,vel);
        tmpThres = 2*std(vel(offSetsInd(1)+round(Fs):offSetsInd(1)+3*round(Fs)));
        onSetsInd = iterToMin(vel,onSetsInd,tmpThres,1); offSetsInd = iterToMin(vel,offSetsInd,tmpThres,0);
        [onSetsInd,offSetsInd] = adjOnsetOffset(onSetsInd,offSetsInd,timeThres,vel);
        nFP = data.acq(n).nFPchan;
        for x = 1:nFP
            FP = data.final(n).FP(:,x);
            data.final(n).beh = ...
                getOnsetOffsetMat(data.final(n).beh,...
                FP,Fs,vel,timeAfter,timeBefore,onSetsInd,offSetsInd);
        end
        data.final(n).beh.onsetsInd = onSetsInd; data.final(n).beh.offsetsInd = offSetsInd;
        data.final(n).beh.numBouts = length(onSetsInd);
        data.final(n).beh.avgBoutDuration = mean(offSetsInd - onSetsInd)/Fs;
        data.final(n).beh.stdBoutDuration = std(offSetsInd - onSetsInd)/Fs;
    end
end

function [localMinsFinal] = iterToMin(signal, array, threshold, isOnset)

% [localMinsFinal] = iterToMin(signal, array, threshold, isOnset)
%
% Summary: This function iterates towards local minimum values,
% sequentially from a given array of indices
%
% Inputs:
%
% 'signal' - the signal in which we are looking for minimums
% 
% 'array' - the indices of the starting points
%
% 'threshold' - the minimum to iterate toward
%
% 'isOnset' - if true, the iteration goes left, if false, the iteration
% goes right (this is a holdover from using this code for onSetsInd and
% offSetsInd of mouse movement bouts)
% 
% Outputs:
%
% 'localMinsFinal' - an array of the new local minimums, iterated towards
% from the initial 'array' 
%
% Author: Jeffrey March, 2018

localMinsFinal = zeros(size(array)); % initialiaing results array

for i = 1:length(array)
    localMin = array(i);
    threshInd = i;
    
    if length(threshold) == 1
        threshInd = 1;
    end
    
    % Iterating towards the local minimum (direction depends on isOnset)   
    while signal(localMin) > threshold(threshInd)
        localMin = localMin - (isOnset*2 - 1);
        
        % Checking to make sure onset/offset doesn't run off end of signal
        if localMin < 1 || localMin > length(signal)
            localMin = nan;
            break
        end
        
    end
    
    localMinsFinal(i) = localMin;
    
end

end


function beh = getOnsetOffsetMat(beh,FPmat,Fs,vel,timeAfter,timeBefore,onSetInd,offSetInd)
    fRatio = size(FPmat,1)/length(vel);
    dffOnsets = round(onSetInd*fRatio); dffOffsets = round(offSetInd*fRatio);
    for x = 1:size(FPmat,2)
        FP = FPmat(:,x);
        for n = 1:length(dffOnsets)
            beh.DF(x).dfOnsets(n,:) = FP(dffOnsets(n) - ceil(timeBefore*fRatio):dffOnsets(n) + ceil(timeAfter*fRatio));
            beh.DF(x).dfOffsets(n,:) = FP(dffOffsets(n) - ceil(timeBefore*fRatio):dffOffsets(n) + ceil(timeAfter*fRatio));
            behOnsets(n,:) = vel(onSetInd(n) - ceil(timeBefore):onSetInd(n) + ceil(timeAfter));
            behOffsets(n,:) = vel(offSetInd(n) - ceil(timeBefore):offSetInd(n) + ceil(timeAfter));
            beh.DF(x).dfOnsetToOffset{n} = FP(dffOnsets(n) - ceil(timeBefore*fRatio):dffOffsets(n) + ceil(timeAfter*fRatio));
            behOnsetToOffset{n} = vel(onSetInd(n) - ceil(timeBefore):offSetInd(n) + ceil(timeAfter));
            onsetToOffsetTime{n} = (-ceil(timeBefore*fRatio):length(beh.DF(x).dfOnsetToOffset{n}) - 1 - ceil(timeAfter*fRatio))/Fs;
        end
    end
    beh.behOnsets = behOnsets;
    beh.behOffsets = behOffsets;
    beh.behOnsetToOffset =  behOnsetToOffset;
    beh.onsetToOffsetTime =  onsetToOffsetTime;
    beh.timeDF = (-ceil(timeBefore*fRatio):ceil(timeAfter*fRatio))/Fs;
end
