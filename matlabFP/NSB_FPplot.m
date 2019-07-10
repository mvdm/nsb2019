%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  MBL NSB 2019 MOUSE Photometry Plotting Script
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all; clc; close all;

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LOAD DATA (**after analysis with NSB_FP script**)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cd('Z:\NSB_2019\03_MouseStriatum\data\photometry\');
NSB_FP_open

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PLOT PHOTOMETRY SIGNAL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fPlot = figure;
plot(time, FP, 'Color', [0 0.5 0])
title(plotTitle,'Interpreter','none')
ylabel('Fluorescence (dF/F)'); xlabel('Time (s)');

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% BAR PLOT PHOTOMETRY SIGNAL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fBar = figure;
bar(time, FP, 10)
title(plotTitle,'Interpreter','none')
ylabel('Fluorescence (dF/F)'); xlabel('Time (s)');

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SAVE PLOTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
choice = menu('save figures?','yes','no');
switch choice
    case 1
        cd(uigetdir(['Z:\NSB_2019\03_MouseStriatum\data\photometry\'],'Directory to Save Figures In'));
        savefig(fPlot, [plotTitle,'_plot.fig']);    saveas(fPlot, [plotTitle,'_plot.tif']);
        savefig(fBar, [plotTitle,'_bar.fig']);      saveas(fBar, [plotTitle,'_bar.tif']);
end