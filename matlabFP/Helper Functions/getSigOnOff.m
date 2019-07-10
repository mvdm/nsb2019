function [sigOn, sigOff] = getSigOnOff(signal, time, threshold)
%Extract on and off time points for pulse train signal
%
% Created by: Anya Krok
% Created on: 19 March 2019
% Description: general code for determination of onset and offset of
%   pulse trains based on raw signal from pulse generator
%
% [sigOn, sigOff] = getSigOnOff(signal, time, threshold)
%
% INPUT
%   'signal' - pulse signal vector
%   'time' - time vector
%   'threshold' - a.u. or V, depends on output of pulse generator
%       arduino(for in vivo): 4V
%       wavesurfer(photometry): 0.15V
%       digital TTL input: 0.8V
%
% OUTPUT
%   'sigOn' - time points (in seconds) corresponding to 1st value ON
%   'sigOff' - time points (also seconds) corresponding to last value OFF
%

sigDiff = cat(1, 0, diff(signal));

upIdx = find(sigDiff > threshold);
sigOn = time(upIdx);

downIdx = find(sigDiff < (-1*threshold));
sigOff = time(downIdx);

end
