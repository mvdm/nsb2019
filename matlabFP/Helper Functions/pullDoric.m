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
    
    nFiles = size(dataFile,1);

    for n = 1:nFiles
        if iscell(dataFile); csvName = dataFile{n};
        else; csvName = dataFile; end
        
        fh = fopen(csvName); fgetl(fh);
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
        
        raw.data(1,:) = M(:, rawIdx);
        raw.data(2,:) = M(:, refIdx);
        raw.label = {'FP','refSig'};
        raw.Fs     = round(1/mean(diff(out.time)));
        
        data.acq = raw;
        
        h = waitbar(n/nFiles, 'loading data')
        
    end
    
close(h)

end