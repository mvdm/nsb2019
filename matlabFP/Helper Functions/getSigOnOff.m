function [sigOn, sigOff] = getSigOnOff(signal, threshold, varargin)
%Extract on and off time points for pulse train signal
%
% Created by: Anya Krok
% Created on: 19 March 2019
% Description: general code for determination of onset and offset of
%   pulse trains based on raw signal from pulse generator
%
% [sigOn, sigOff] = getSigOnOff(signal, threshold, varargin)
%
% INPUT
%   'signal' - pulse signal vector
%   'threshold' - a.u. or V, depends on output of pulse generator
%       arduino(for in vivo): 4V
%       wavesurfer(photometry): 0.15V
%       digital TTL input: 0.8V
%   varargin{1}
%       'time' - use for output to be in seconds
%
% OUTPUT
%   'sigOn' - time or sample points corresponding to 1st value ON
%   'sigOff' - time or sample points corresponding to last value OFF
%

sigDiff = cat(1, 0, diff(signal));
upIdx = find(sigDiff > threshold);
downIdx = find(sigDiff < (-1*threshold));
        
switch nargin
    case 3 %if include time vector, output is in seconds
        time = varargin{1};
        sigOn = time(upIdx);
        sigOff = time(downIdx);
    case 2 %no time vector, output is in samples
        sigOn = upIdx;
        sigOff = downIdx;
end

end
