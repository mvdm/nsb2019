%% plot NLX and WS data

% run SyncSandbox to get WSdata variable, then do
WSdata.tvec = WSdata.tvec + meanShift;

%%
cfg.fc = {'photo.ncs'};
csc_photo = LoadCSC(cfg);
Fs = csc_photo.cfg.hdr{1}.SamplingFrequency;

%% filter and subsample DA data if desired
fc = 20; % cutoff
[b,a] = butter(6, fc/(Fs/2), 'low');
csc_photo.data = filtfilt(b, a, csc_photo.data);

df = 10;
csc_photo.data = decimate(csc_photo.data, df);
csc_photo.tvec = csc_photo.tvec(1:df:end);
Fs = Fs / df;

csc_photo.data = locdetrend(csc_photo.data, Fs, [10 5]); % global detrend

%% plot
s1 = subplot(211)
plot(csc_photo); title('nlx');
s2 = subplot(212)
plot(WSdata.tvec, WSdata.data(1,:)); title('wavesurfer');
linkaxes([s1 s2], 'x')