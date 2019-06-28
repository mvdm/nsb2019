function [T,WV] = LoadSE_NeuralynxP(a,b,c)
% MClust loader for n-trode single electrode files

nChan = 8;

if nargin == 1
    fn = a;
    [t,~] = regexp(fn,'(.+)(\d+).nse','tokens','match');
    [fp,base_fn,~] = fileparts(t{1}{1}); base_fno = str2num(t{1}{2});

    for iChan = 1:nChan
        this_fn = cat(2,fp,filesep,base_fn,num2str(base_fno + iChan - 1),'.nse');
        if iChan == 1 % initialize vars
            [T,this_WV] = LoadSE_NeuralynxNT0(this_fn);
            WV = this_WV(:,1,:);
        else % add to existing vars
            [this_T,this_WV] = LoadSE_NeuralynxNT0(this_fn);

            % initialize new channel with zeros
            WV = cat(2,WV,zeros(size(WV,1),1,size(WV,3)));
            
            % see if any T are overlapping; if so add to matrix in
            % appropriate non-self channel
            [~,IA,IB] = intersect(T,this_T);
            WV(IA,iChan,:) = this_WV(IB,1,:);
            
            % for non overlapping T, initialize new matrix to be
            % concatenated
            nonIB = setdiff(1:length(this_T),IB);
            add_WV = zeros(size(this_T(nonIB),1),iChan,size(this_WV,3));
            add_WV(:,iChan,:) = this_WV(nonIB,1,:);
            
            WV = cat(1,WV,add_WV);

            % update tvec
            add_T = this_T(nonIB);
            T = cat(1,T,add_T);
            
            % sort in time
            [T,sort_idx] = sort(T);
            WV = WV(sort_idx,:,:);
            
        end
    end
elseif nargin == 3
    fn = a;
    [t,~] = regexp(fn,'(.+)(\d+).nse','tokens','match');
    [fp,base_fn,~] = fileparts(t{1}{1}); base_fno = str2num(t{1}{2});

    for iChan = 1:nChan
        this_fn = cat(2,fp,filesep,base_fn,num2str(base_fno + iChan - 1),'.nse');
        if iChan == 1 % initialize vars
            [T,this_WV] = LoadSE_NeuralynxNT0(this_fn);
            WV = this_WV(:,1,:);
        else % add to existing vars
            [this_T,this_WV] = LoadSE_NeuralynxNT0(this_fn); % this should work but doesn't (returns garbage waveforms)

            % initialize new channel with zeros
            WV = cat(2,WV,zeros(size(WV,1),1,size(WV,3)));
            
            % see if any T are overlapping; if so add to matrix in
            % appropriate non-self channel
            [~,IA,IB] = intersect(T,this_T);
            WV(IA,iChan,:) = this_WV(IB,1,:);
            
            % for non overlapping T, initialize new matrix to be
            % concatenated
            nonIB = setdiff(1:length(this_T),IB);
            add_WV = zeros(size(this_T(nonIB),1),iChan,size(this_WV,3));
            add_WV(:,iChan,:) = this_WV(nonIB,1,:);
            
            WV = cat(1,WV,add_WV);

            % update tvec
            add_T = this_T(nonIB);
            T = cat(1,T,add_T);
            
            % sort in time
            [T,sort_idx] = sort(T);
            WV = WV(sort_idx,:,:);
            
        end
    end
    
    % now deal with possible flags
    switch c
        
        case 1 % use specified timestamps
        
            keep = (T == b);
            T = T(keep);
            WV = WV(keep,:,:);
            
        case 2 % use specified idxs
       
            T = T(b);
            WV = WV(b,:,:);
            
        case 3 % range of timestamps
            keep = find(T > b(1) & T < b(2));
            T = T(keep);
            WV = WV(keep,:,:);
            
        case 4 % range of records
            T = T(b(1):b(2));
            WV = WV(b(1):b(2),:,:);
            
        case 5 % return count
            T = length(T);
            
    end
elseif nargin == 2
    % New "get" construction
    if strcmp(a, 'get')
        switch (b)
            case 'ChannelValidity'
                T = zeros(4,1);
                T(1:nChan) = 1; 
                T = logical(T);
                return;
            case 'ExpectedExtension'
                T = '.nse'; return;
            otherwise
                error('Unknown get condition.');
        end
    else
        error('2 argins requires "get" as the first argument.');
    end
end

disp('Loading complete.');