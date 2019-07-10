function [data, out] = pullDoric()
%convert Doric .csv file into new data structures
%
% created By: Anya Krok, created On: July 2019
%
% OUTPUT:
% 'data' - raw signals for processing with Tritsch lab analysis
% 'out' - output signals from Doric including Doric demodulation
%
    data = struct; %initialize data structure
    data.acqType = ['doric'];
     
    [dataFile,dataPath] = uigetfile('*.csv','Select .csv Data File','MultiSelect','On'); %load CSV file outputted by doric
    cd(dataPath) %call data path where CSV file is located for reading in table 
    
    nFiles = length(dataFile);

    for n = 1:nFiles
        if iscell(dataFile); csvName = dataFile{n};
        else; csvName = dataFile; end
        
        fh = fopen(csvName);
        colnames = strsplit(fgetl(fh),','); %extract column names
        fclose(fh);
        
        tIdx = strmatch('Time(s)', colnames);
        fpIdx = strmatch('AIn-1 - Dem (AOut-1)', colnames);
        ctlIdx = strmatch('AIn-1 - Dem (AOut-2)', colnames);
        rawIdx = strmatch('AIn-1 - Raw', colnames);
        refIdx = strmatch('AIn-2', colnames);
        ttlIdx = strmatch('DI/O-1', colnames);
        
        M = csvread(csvName, 3, 0); % Time(s)	AIn-1 - Dem (AOut-1)    AIn-1 - Dem (AOut-2)	AIn-1 	AIn-2	DI/O-1
        
        out = struct;
        out.time = M(:, tIdx);
        out.data(1,:) = M(:, fpIdx);
        out.data(2,:) = M(:, ctlIdx);
        out.label = {'fp','ctl'};
        
        ttlData = M(:, ttlIdx);
        [ttlOn, ttlOff] = getSigOnOff(ttlData, out.time, 0.5);
        out.ttlOn = ttlOn;
        out.ttlOff = ttlOff;
        
        raw.FP     = M(:, rawIdx);
        raw.refSig = M(:, refIdx);
        raw.Fs     = round(1/mean(diff(out.time)));
        raw.nFPchan = 1;
        
        data.acq = raw;
        
        waitbar(n/nFiles, 'loading data')
        
    end
end

%         opts = detectImportOptions([csvName],'NumHeaderLines',1); % number of header lines which are to be ignored
%             opts.VariableNamesLine = 2; % row number which has variable names
%             opts.DataLine = 3; % row number from which the actual data starts
%         
%             raw = readtable([csvName],opts); %read in .csv file into table
%         
%         tidx = [find(string(raw.Properties.VariableNames) == "Time_s_"), ...
%             find(string(raw.Properties.VariableNames) == "AIn_1_Dem_AOut_1_"), ...
%             find(string(raw.Properties.VariableNames) == "AIn_1_Raw"), ...
%             find(string(raw.Properties.VariableNames) == "AIn_2")]; %identify column indices based on variable names
%                
%         out = struct; %initialize variables
%             acqTime = table2array(raw(:,tidx(1))); %populate data structure with vectors of signal
%             out.FP = table2array(raw(:,tidx(3)));
%             out.refSig = table2array(raw(:,tidx(4)));
%             out.Fs = round(1/mean(diff(acqTime))); %sampling freq determined based on time stamps 
%             out.nFPchan = 1;
%             
%         if ismember('AIn_1_Dem_AOut_2_', raw.Properties.VariableNames) %doric demodulated signal
%             ctrIdx = find(string(raw.Properties.VariableNames) == "AIn_1_Dem_AOut_2_");
%             out.control = table2array(raw(:,ctrIdx));
%             out.control = demodstr2num(out.control)';
%         end
%          
%         if ismember('DI_O_1', raw.Properties.VariableNames) %doric DI signal in digital input channel 1
%             dIdx = find(string(raw.Properties.VariableNames) == "DI_O_1");
%             temp.dig = table2array(raw(:,dIdx));
%         end    
%         
%         data.acq(n) = out;
     