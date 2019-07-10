function [demodnum] = demodstr2num (demod)
%transform cell array with NaN into vector of numeric values
%
% Created By: Jimmie
% Created On: 2019 July
% Description: transform cell array that is extracted from Doric .csv file
% and remove non-numeric values in order to generate matrix double of only
% numerical values
%
% [demodnum] = demodstr2num (demod)
% 
% INPUTS
% 'demod' - cell array extracted from Doric .csv file
% OUPUTS
% 'demodnum' - matrix double with only numerical values
%


num_samples = length(demod) ;
demodnum = NaN(1,num_samples);

for iS = 1:num_samples
     if ~isempty(demod{iS})
         demodnum(iS) = str2num(demod{iS});
     end
end

end