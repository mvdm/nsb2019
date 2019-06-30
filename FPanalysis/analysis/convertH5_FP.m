%% convertH5_FP
%
%   Description: This function will convert as many H5 files into MAT files
%   that follow an organization pattern agreed upon by fellow lab members
%   of the Tritsch Lab. 
%
%   This function requires h5 data files to be in the following format:
%   - AN_ExpDate_Cond_0001.h5
%
%       - AN --> Animal Name
%       - ExpDate --> Experiment Date
%       - Cond --> Conditional (Optional)
%       - 001 --> Experiment index from wavesurfer 
%
%   This script uses an intermediate function called
%   extractH5_WS, which parses the H5 tree. Parts of that function were
%   repurposed from Adam Taylors innate functions to extract data from H5
%   trees. The createFPStruct function will take a data structure created
%   from the extractH5_WS into a data structure with the following format:
%
%   data --> Main data structure
%   - mouseName
%   - expDate
%   - acq(n) -> An array of structures. An acquisition is either multiple
%   sweeps or multiple experiments on the same day
%       - FP --> Matrix of photometry recordings
%       - encoder --> Data from wheel rotary encoder
%       - nFPchan --> Number of FP channesl
%       - FPNames --> Names of the FP channels
%       - Fs --> Sampling Frequency
%       - refSig --> Matrix of Reference signals if performing photometry modulation
%       - control --> red channel control trace
%
%   Author: Pratik Mistry, 2019

%choice = menu('Do you want to convert h5 Files into FP format','Yes','No');
%switch choice
%    case 1
        cd(['C:\Users\MBLUser\Desktop\NSB19_mouse\photometry\wavesurfer']);
        [h5Files,fPath] = uigetfile('*.h5','MultiSelect','On');
        if (~iscell(h5Files))
            h5Files = {h5Files};
        end
        %newPath = uigetdir(fPath,'Select Path for New File');
        %if (newPath==0)
            newPath = fPath;
        %end
        nFiles = length(h5Files);
        initExpDate = [];

        for n = 1:nFiles
            h5Name = h5Files{n};
            [AN,other] = strtok(h5Name,'_');
            [expDate,~] = strtok(other,'_');
            dataWS = extractH5_WS(fullfile(fPath,h5Files{n}));
            data = createFPStruct(dataWS,AN,expDate);
            save(fullfile(newPath,strtok(h5Files{n},'.')),'data');
            AN = []; expDate = []; other = []; h5Name = [];
            data = []; dataWS = []; 
        end
%end

FPfiles = strtok(h5Files{n},'.');
FPpath = newPath;
clearvars -except answer FPfiles FPpath


%{
%% Combine_Files
[choice] = menu('Do you want to combine files?','Yes','No');
switch choice
    case 1
        while(1)
            [fNames,fPath] = uigetfile('*.mat','MultiSelect','On');
            if (~iscell(fNames))
                disp('Only one file selected');
            else
                break;
            end
        end
        nFiles = length(fNames);
        AN = {}; expDate = {}; cond = {}; acq = {};
        for n = 1:nFiles
            [AN{n},other] = strtok(fNames{n},'_'); [expDate{n},other] = strtok(other,'_'); 
            [acq{n},other] = strtok(other,'_');
            if (~isempty(other))
                cond{n} = acq{n};
                [acq{n},~] = strtok(other,'_'); [acq{n},~] = strtok(acq{n},'.');
            end 
        end
        if isequal(AN,fliplr(AN)) && isequal(expDate,fliplr(expDate))
            acqN = str2double(acq);
            [~,acqInd] = sort(acqN);
            nFiles = length(acqInd);
            load(fullfile(fPath,fNames{1}));
            for n = 2:nFiles
                tmpData = getfield(load(fullfile(fPath,fNames{acqInd(n)})),'data');
                data.acq(n) = tmpData.acq;
            end
        end
        if (isempty(cond))
            save(fullfile(fPath,[AN{1},'_',expDate{1}]),'data');
        else
            save(fullfile(fPath,[AN{1},'_',expDate{1},'_',cond{1}]),'data');
        end
end
%}
