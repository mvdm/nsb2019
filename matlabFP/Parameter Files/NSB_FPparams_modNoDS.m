%% General Parameters
params.dsRate = 0; % Downsampling rate if you want to downsample the signal
%This dsRate will also be applied to all signals during the analysis
%pipeline

%% Demodulation Parameters
%Adjust the demodStatus variable to "1" if you need to demodulate a signal
%from a lock-in amplifier or "0" if it's a normal photometry recording

params.FP.demodStatus = 1; % **1 -- Demodulation** **0 -- No Demodulation**
if params.FP.demodStatus == 1
    params.FP.sigEdge = 60; %Time in seconds of data to be removed from beginning and end of signal
    %The params.sigEdge variable is necessary because it will remove filter
    %edge effects that occur during the demodulation
    params.FP.control = 1; %Are you modulating a control fluorophore (tdTomato)
else
    params.FP.sigEdge = 0;
end

%% Filter Parameters
%params.filtType = 'lowpass'; % Filter type: 'lowpass' or 'highpass' --
%Temporarily removed. We more than likely won't need to highpass filter our
%signals
params.FP.lpCut = 10; % Cut-off frequency for filter
params.FP.filtOrder = 10; % Order of the filter

%% Baseline Parameters
params.FP.fitType = 'linear'; % Fit method or type for baseline either 'linear' or 'exp'
params.FP.winPer = 0.05; % Percent of total signal length that will be used for baseline window

%% Other Parameteres
params.wheelStatus = 0;
params.optoStatus = 0;