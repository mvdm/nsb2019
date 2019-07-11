%%
restoredefaultpath;
addpath(genpath('C:\Users\mvdm\Documents\GitHub\vandermeerlab\code-matlab\shared'));
addpath(genpath('C:\Users\mvdm\Documents\GitHub\vandermeerlab\code-matlab\tasks\Alyssa_Tmaze'));


%%
cd('C:\data\NSB2019\M19-349A-190711_pt1_baseline');

please = []; please.fc = {'CSC2A_spike.ncs'};
CSC = LoadCSC(please);

%%
SCRIPT_Manually_Identify_SWRs; % requires ExpKeys file to work

%%
load(FindFile('*IV.mat'));
ncfs = SWRfreak([],evt,CSC);
SWR = amSWR([],ncfs,CSC);

%%
cfg = [];
cfg.method = 'raw';
cfg.threshold = 3;
cfg.operation =  '>'; % '<', '>'
cfg.merge_thr = 0.04; % merge events closer than this
cfg.minlen = 0.04; % minimum interval length

SWRe = TSDtoIV(cfg, SWR);

%%
cfg = [];
cfg.display = 'iv';
PlotTSDfromIV(cfg, SWRe, CSC)