function varargout = shapedata_spikes(spiketimes,P,dimparams,varargin)
% data = shapedata_spikes(spiketimes,P,dimparams)
% data = shapedata_spikes(...,'PropertyName',PropertyValue)
% [data,vals] = shapedata_spikes(...) 
%
% PropertyName ... PropertyValue
% 'win'     ... window (eg, [-0.1 0.5]) in seconds
% 'binsize' ... in seconds
% 'func'    ... function to compute response magnitude (default = "mean")
% 'returntrials' ... if true, returns an extra dimension with each trial
%                           (default = false)
% 
% Daniel.Stolzberg at gmail com 2013
%
% See also, shapedata_wave, DB_GetSpiketimes, DB_GetParams

win          = [-0.1 0.5];
binsize      = 0.001;
func         = 'mean';
returntrials = false;

ParseVarargin({'win','binsize','func','returntrials'},[],varargin);


binvec = win(1):binsize:win(2)-binsize;

% sort spikes by onsets
ons = P.VALS.onset;
raster = cell(size(ons));

% psth:   bins/trials
psth = zeros(length(binvec),length(ons));

% first rearrange data based on stimulus onsets
for i = 1:length(ons)
    ind = spiketimes-ons(i) >= win(1) & spiketimes-ons(i) < win(2);
    if ~any(ind), continue; end
    raster{i} = spiketimes(ind)-ons(i);
    psth(:,i) = histc(raster{i},binvec);
end


% select parameter for dimensions
for i = 1:length(dimparams)
    vals{i} = unique(P.VALS.(dimparams{i})); %#ok<AGROW>
end

ndp = length(dimparams);

% THERE'S PROBABLY A MORE CLEVER WAY OF DOING THIS...
if returntrials
    if ndp == 1 %#ok<UNRCH>
        % data:    bins/trials/param1
        ind = P.VALS.(dimparams{1}) == vals{1}(1);
        data = zeros(length(binvec),sum(ind),length(vals{1}));
        for i = 1:length(vals{1})
            ind = P.VALS.(dimparams{1}) == vals{1}(i);
            data(:,:,i) = psth(:,ind);
        end
        
        
    elseif ndp == 2
        % data:    bins/trials/param1/param2
        ind = P.VALS.(dimparams{1}) == vals{1}(1) ...
            & P.VALS.(dimparams{2}) == vals{2}(1);
        data = zeros(length(binvec),sum(ind),length(vals{1}),length(vals{2}));
        for i = 1:length(vals{1})
            for j = 1:length(vals{2})
                ind = P.VALS.(dimparams{1}) == vals{1}(i) ...
                    & P.VALS.(dimparams{2}) == vals{2}(j);
                data(:,:,i,j) = psth(:,ind);
            end
        end
        
        
    elseif ndp == 3
        % data:    bins/trials/param1/param2/param3
        ind = P.VALS.(dimparams{1}) == vals{1}(1) ...
            & P.VALS.(dimparams{2}) == vals{2}(1) ...
            & P.VALS.(dimparams{3}) == vals{3}(1);
        data = zeros(length(binvec),sum(ind),length(vals{1}),length(vals{2}),length(vals{3}));
        for i = 1:length(vals{1})
            for j = 1:length(vals{2})
                for k = 1:length(vals{3})
                    ind = P.VALS.(dimparams{1}) == vals{1}(i) ...
                        & P.VALS.(dimparams{2}) == vals{2}(j) ...
                        & P.VALS.(dimparams{3}) == vals{3}(k);
                    data(:,:,i,j,k) = psth(:,ind);
                end
            end
        end
        
    end
    varargout{2} = [{binvec},1:size(data,2),vals];
else
    if ndp == 1
        % data:    bins/param1
        data = zeros(length(binvec),length(vals{1}));
        for i = 1:length(vals{1})
            ind = P.VALS.(dimparams{1}) == vals{1}(i);
            data(:,i) = feval(func,psth(:,ind),2);
        end
        
        
    elseif ndp == 2
        % data:    bins/param1/param2
        data = zeros(length(binvec),length(vals{1}),length(vals{2}));
        for i = 1:length(vals{1})
            for j = 1:length(vals{2})
                ind = P.VALS.(dimparams{1}) == vals{1}(i) ...
                    & P.VALS.(dimparams{2}) == vals{2}(j);
                data(:,i,j) = feval(func,psth(:,ind),2);
            end
        end
        
        
    elseif ndp == 3
        % data:    bins/param1/param2/param3
        data = zeros(length(binvec),length(vals{1}),length(vals{2}),length(vals{3}));
        for i = 1:length(vals{1})
            for j = 1:length(vals{2})
                for k = 1:length(vals{3})
                    ind = P.VALS.(dimparams{1}) == vals{1}(i) ...
                        & P.VALS.(dimparams{2}) == vals{2}(j) ...
                        & P.VALS.(dimparams{3}) == vals{3}(k);
                    data(:,i,j,k) = feval(func,psth(:,ind),2);
                end
            end
        end
        
    end
varargout{2} = [{binvec},vals];    
end

varargout{1} = data;







