function [dataAcq, dataFinal] = parseDataFile (data)
%Parse data.acq and data.final into two separate structures
%
% [dataAcq, dataFinal] = parseDataFile (data)
%
% Created by: Anya Krok
% Created on: 2019 July 09
% Description: input of T-lab style data structure with two substructures:
%   acq and final, and output of two separate structures. goal is to 
%   decrease file size for future analysis
%

if isfield(data,'acq') && isfield(data,'final') %check that sub-structures exist

dataAcq = data;
dataAcq = rmfield(data,'final');

dataFinal = data;
dataFinal = rmfield(data,'acq');

end

end