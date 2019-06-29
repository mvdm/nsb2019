function [dF_F,varargout] = baselineFP(sig,fitType,winPer)
%baselinePhotometry - Baseline adjust photometry signal to get dF/F
%   Created By: Pratik Mistry
%   Created On: 30 January 2019
%
%   [dF_F,varargout] = baselineFP(sig,fitType,winPer)
%
%   Description: This code will baseline adjust the photometry signal
%   using a two term exponential or a linear interpolation
%
%   Input:
%   - sig - Trace that needs to be baselined
%   - fitType - Linear Interpolation or Exponential Fit ('linear' or 'exp')
%   - winPer - Percentage to use for creating the sliding window for
%   calculating baseline values
%
%   Output:
%   - dF_F - Baseline adjusted trace (%dF_F)
%   - varargout - Optional fitline output
%
%
    if size(sig,1) == 1
        sig = sig';
    end
    Ls = length(sig);
    L = 1:Ls; L = L';
    win = floor(winPer*Ls);
    X = 1:win:(Ls-win); X = X';
    Y = zeros(length(X),1);
    for i = 1:length(X)
        pVal = prctile(sig(X(i)+1:X(i)+win),10);
        Y(i) = pVal;
    end
    interpFit = interp1(X,Y,L,'linear','extrap');
    if size(interpFit,1)== 1
        interpFit = interpFit';
    end
    switch fitType
        case 'linear'
            baseline = interpFit;
        case 'exp'
            expFit = fit(L,interpFit,'exp2');
            baseline = double(expFit(L));
    end
    dF_F = (sig-baseline)./baseline;
    if nargout == 2
        varargout{1} = baseline;
    end
end