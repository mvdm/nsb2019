%%%%%%%%%%%%%%%%%%%%%%%%%%
%% LOAD NEURALYNX DATA %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%
%cd('Z:\NSB_2019\03_MouseStriatum\data\SyncTests\firstSyncPulseTest\JG_test');
cd('C:\data\NSB2019\M19-347A-190709_syncRecording_restInBoxGoodSWR');

%% load event timestamps (TTL on and off times)
please = [];
please.eventList = {'TTL Output on AcqSystem1_0 board 0 port 2 value (0x0000).', ...
    'TTL Output on AcqSystem1_0 board 0 port 2 value (0x0001).'};
please.eventLabel = {'TTL_off', 'TTL_on'};

evt = LoadEvents(please);

%% load analog signal (e.g. LFP)
please = []; please.fc = {'CSC1A.ncs'};
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
%% LOAD WS DATA %%%%%%
%%%%%%%%%%%%%%%%%%%%%%

rawData = extractH5_WS('M19-347A-190709_DA.h5');
WSdata = tsd;
WSdata.tvec = rawData.sweeps(1).time;
WSdata.data(1,:) = rawData.sweeps(1).acqData;
WSdata.label{1} = 'DA';
WSdata.data(2,:) = rawData.sweeps(1).digData;
WSdata.label{2} = 'TTL';

%%
subplot(212);
plot(WSdata.tvec, getd(WSdata, 'TTL'), '.');
ylim([-0.1 5.1]); box off;
xlabel('Photometry time');
%legend(h, WSdata.label); legend boxoff;

%% detect pulse on times in WS data
thr = 0.5;
WSdiff = cat(2, 0, diff(getd(WSdata, 'TTL')));
up_idx = find(WSdiff > thr);

WS_TTL_on = WSdata.tvec(up_idx);

%% if we have unequal numbers of pulses, need to pad the data
wpd = diff(WS_TTL_on);
npd = diff(getd(evt, 'TTL_on'))';

length_diff = length(wpd) - length(npd);
if length_diff < 0 % nlx data longer

    fprintf('WARNING: unequal number of pulses detected (ws: %d, nlx: %d)\n', length(WS_TTL_on), length(getd(evt, 'TTL_on')));

    wpd = cat(1, wpd, nan(abs(length_diff), 1));
    wpt = cat(1, WS_TTL_on, nan(abs(length_diff), 1));
    npt = getd(evt, 'TTL_on')';
    
elseif length_diff > 0 % ws data longer
    
    fprintf('WARNING: unequal number of pulses detected (ws: %d, nlx: %d)\n', length(WS_TTL_on), length(getd(evt, 'TTL_on')));
    
    npd = cat(1, npd, nan(abs(length_diff), 1));
    npt = cat(1, getd(evt, 'TTL_on')', nan(abs(length_diff), 1));
    wpt = WS_TTL_on;
    
else
   disp('OK: Equal number of pulses detected.'); 
   wpt = WS_TTL_on;
   npt = getd(evt, 'TTL_on')';
end

%% compute error as a function of pulse shifts (minimum error will be optimum alignment)
align_vec = 0:length(npd)-1; % shifts to loop over
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
meanShift = nanmedian(npt(~isnan(wpt_aligned)) - wpt_aligned(~isnan(wpt_aligned))); % this is the magic number
wpt_corrected = wpt + meanShift;
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
title(sprintf('mean time difference = %.2f', meanShift)); vline(0);

subplot(223);
plot(wpt_corrected, wpt_diffs, '.k', 'MarkerSize', 10); box off;
ylabel('nlx - ws dt'); xlabel('pulse #'); hline(0);

%% plot aligned data on common timebase
figure

subplot(211);
h1 = plot(NLXdata, '.b');
hold on;
h2 = plot(WSdata.tvec + meanShift, getd(WSdata, 'TTL'), '.r');
ylim([-0.1 5.1]); box off;
xlabel('Neuralynx time');

subplot(212);
h1 = plot(NLXdata, '.b');
hold on;
h2 = plot(WSdata.tvec + meanShift, getd(WSdata, 'TTL'), '.r');
ylim([-0.1 5.1]); box off;
xlabel('Neuralynx time');
xlim([1129.7 1129.9]);
