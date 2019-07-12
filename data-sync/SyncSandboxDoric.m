%%%%%%%%%%%%%%%%%%%%%%%%%%
%% LOAD NEURALYNX DATA %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%
cd('C:\data\NSB2019\349A Photometry&Ephys\2019-07-09_14-32-29_349A');

%% load event timestamps (TTL on and off times)
please = [];
please.eventList = {'TTL Output on AcqSystem1_0 board 0 port 0 value (0x0000).', ...
    'TTL Output on AcqSystem1_0 board 0 port 0 value (0x0001).'};
please.eventLabel = {'TTL_off', 'TTL_on'};

evt = LoadEvents(please);

%% load analog signal (e.g. LFP)
please = []; please.fc = {'CSC1.ncs'};
csc = LoadCSC(please);

NLXdata = csc; NLXdata.data = zeros(size(NLXdata.data));

TTL_high = iv(getd(evt, 'TTL_on'), getd(evt, 'TTL_off'));
[~, TTL_high_idx] = restrict_idx(NLXdata, TTL_high);
NLXdata.data(TTL_high_idx) = 1;

%% plot
subplot(211);
plot(NLXdata, '.');
ylim([-0.1 1.1]); box off;
xlabel('Neuralynx time');

%%%%%%%%%%%%%%%%%%%%%%
%% LOAD DORIC DATA %%%
%%%%%%%%%%%%%%%%%%%%%%

%cd('C:\data\NSB2019\349A Photometry&Ephys\')

fn = FindFile('*.csv');

% find names of columns in csv file (correspond to variables)
fh = fopen(fn);
fgetl(fh); colnames = strsplit(fgetl(fh), ',');
fclose(fh);

tvec_idx = strmatch('Time(s)', colnames);
fp_idx = strmatch('AIn-1 - Dem (AOut-1)', colnames);
ctl_idx = strmatch('AIn-2', colnames);
ttl_idx = strmatch('DI/O-1', colnames);
raw_idx = strmatch('AIn-1 - Raw', colnames);

% load the actual data (may take a while)
M = csvread(fn, 3, 0); % Time(s)	AIn-1 - Dem (AOut-1)	AIn-1 - Dem (AOut-2)	AIn-1 	AIn-2	DI/O-1
M = M(:, 1:6);

% arrange data in mvdmlab data structure
out = tsd;
out.tvec = M(:, tvec_idx);
out.data(1,:) = M(:, fp_idx);
out.data(2,:) = M(:, raw_idx);
out.data(3,:) = M(:, ctl_idx);
%out.label = {'fp', 'ctl'};
out.label = {'fp', 'raw', 'ctl'};

%% detect "pulse on" times in Doric data
ttl_data = M(:, ttl_idx);
clear M;

thr = 0.5;
WSdiff = cat(1, 0, diff(ttl_data));
up_idx = find(WSdiff > thr);

WS_TTL_on = out.tvec(up_idx);

%% plot Doric TTL data
subplot(212);
plot(out.tvec, ttl_data, '.'); box off;
xlabel('Photometry time');

%% if we have unequal numbers of pulses, need to pad the data
wpd = diff(WS_TTL_on);
npd = diff(getd(evt, 'TTL_on'))';

length_diff = length(wpd) - length(npd);
if length_diff < 0 % nlx data longer

    fprintf('WARNING: unequal number of pulses detected (Doric: %d, nlx: %d)\n', length(WS_TTL_on), length(getd(evt, 'TTL_on')));

    wpd = cat(1, wpd, nan(abs(length_diff), 1));
    wpt = cat(1, WS_TTL_on, nan(abs(length_diff), 1));
    npt = getd(evt, 'TTL_on')';
    
elseif length_diff > 0 % ws data longer
    
    fprintf('WARNING: unequal number of pulses detected (Doric: %d, nlx: %d)\n', length(WS_TTL_on), length(getd(evt, 'TTL_on')));
    
    npd = cat(1, npd, nan(abs(length_diff), 1));
    npt = cat(1, getd(evt, 'TTL_on')', nan(abs(length_diff), 1));
    wpt = WS_TTL_on;
    
else
   disp('OK: Equal number of pulses detected.'); 
   wpt = WS_TTL_on;
   npt = getd(evt, 'TTL_on')';
end

%% compute error as a function of pulse shifts (minimum error will be optimum alignment)
align_vec = -floor(length(npd) / 2):ceil(length(npd) / 2); % shifts to loop over
MSE_out = nan(size(align_vec)); % keep track of mean squared errors

for iA = 1:length(align_vec) % main loop
    
    wpd_shifted = circshift(wpd, [align_vec(iA) 0]);
    MSE_out(iA) = nanmean((wpd_shifted - npd).^2); 
    
end

[min_MSE, min_idx] = min(MSE_out); 
alignShift = align_vec(min_idx); % optimum alignment expressed as number of pulses

% actually align the data
wpd_aligned = circshift(wpd, [alignShift 0]);
wpt_aligned = circshift(wpt, [alignShift 0]);

% compute the mean shift across pulses
meanShift = nanmedian(npt - wpt_aligned); % this is the magic number
wpt_corrected = wpt_aligned + meanShift;
wpt_diffs = npt - wpt_corrected;

%% plot some alignment diagnostics
figure;
subplot(221);
plot(align_vec, MSE_out); hold on; plot(align_vec, MSE_out, '.b', 'MarkerSize', 10);
hold on;
plot(alignShift, MSE_out(min_idx), 'or', 'MarkerSize', 10);
ylabel('MSE'); xlabel('dPulse');
title(sprintf('AlignShift = %d', alignShift));

subplot(222);
hist(wpt_diffs);
ylabel('count'); xlabel('nlx - ws dt');
title(sprintf('estimated time difference = %.2f', meanShift)); vline(0);

subplot(223);
plot(wpt_corrected, wpt_diffs, '.k', 'MarkerSize', 10); box off;
ylabel('nlx - ws dt'); xlabel('pulse #'); hline(0);

subplot(224);
plot(wpt_corrected, wpt_diffs, '.k', 'MarkerSize', 10); box off;
ylabel('nlx - ws dt'); xlabel('pulse #'); hline(0); ylim(10e-4 * [-1 1]);

%% plot aligned data on common timebase
figure

subplot(211);
h1 = plot(NLXdata, '.b');
hold on;
h2 = plot(out.tvec + meanShift, ttl_data, '.r'); box off;
ylim([-0.1 1.1]); box off;
xlabel('Neuralynx time');

subplot(212);
h1 = plot(NLXdata, '.b');
hold on;
h2 = plot(out.tvec + meanShift, ttl_data, '.r'); box off;
ylim([-0.1 1.1]); box off;
xlabel('Neuralynx time');
xlim(1.0e+03 * [5.763139369112194   5.763140883404780]);

%% %%%%%%%%%%%%%%%%%%%%%%%
%%% END OF ALIGNMENT %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%

%% decimate photometry data
df = 100;
out2 = tsd; out2.label = out.label;
out2.tvec = out.tvec(1:df:end);
out2.data(1,:) = decimate(out.data(1,:), df);
out2.data(2,:) = decimate(out.data(2,:), df);

Fs = 1 ./ (median(diff(out.tvec)));
Fs2 = Fs / df;

%% plot LFP and DA together
out2.tvec = out2.tvec + meanShift;

figure;
plot(csc.tvec, csc.data);
hold on;
plot(out2.tvec, out2.data(1, :));

%% DA PSD
[P, F] = pwelch(out2.data(1,:), 256, 128, [], 125);