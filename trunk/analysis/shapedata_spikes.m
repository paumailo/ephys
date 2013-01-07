function varargout = shapedata_spikes(spiketimes,params,dimparams,varargin)
% data = shapedata_spikes(spiketimes,params,dimparams)
% data = shapedata_spikes(...,'PropertyName',PropertyValue)
% [data,vals] = shapedata_spikes(...) 
%
% PropertyName ... PropertyValue
% 'win'     ... window (eg, [-0.1 0.5]) in seconds
% 'binsize' ... in seconds
% 
% DJS 2013
%
% See also, shapedata_wave

win = [-0.1 0.5];
binsize = 0.001;

for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'win',     win = varargin{i+1};
        case 'binsize', binsize = varargin{i+1};
    end
end

binvec = win(1):binsize:win(2);

% sort spikes by onsets
ons = params.VALS.onset;
raster = cell(size(ons));

% psth:   bins/trials
psth = zeros(length(binvec),length(ons));

for i = 1:length(ons)
    ind = spiketimes-ons(i) >= win(1) & spiketimes-ons(i) < win(2);
    if ~any(ind), continue; end
    raster{i} = spiketimes(ind)-ons(i);
    psth(:,i) = histc(raster{i},binvec);
end


% select parameter for dimensions
for i = 1:length(dimparams)
    vals{i} = unique(params.VALS.(dimparams{i})); %#ok<AGROW>
end

% THERE'S PROBABLY A MORE CLEVER WAY OF DOING THIS...
if length(dimparams) == 1
    % data:    bins/param1
    data = zeros(length(binvec),length(vals{1}));
    for i = 1:length(vals{1})
        ind = params.VALS.(dimparams{1}) == vals{1}(i);
        data(:,i) = mean(psth(:,ind),2);
    end
    
    
elseif length(dimparams) == 2
    % data:    bins/param1/param2
    data = zeros(length(binvec),length(vals{1}),length(vals{2}));
    for i = 1:length(vals{1})
        for j = 1:length(vals{2})
            ind = params.VALS.(dimparams{1}) == vals{1}(i) ...
                & params.VALS.(dimparams{2}) == vals{2}(j);
            data(:,i,j) = mean(psth(:,ind),2);
        end
    end
    
    
elseif length(dimparams) == 3
    % data:    bins/param1/param2/param3
    data = zeros(length(binvec),length(vals{1}),length(vals{2}),length(vals{3}));
    for i = 1:length(vals{1})
        for j = 1:length(vals{2})
            for k = 1:length(vals{3})
                ind = params.VALS.(dimparams{1}) == vals{1}(i) ...
                    & params.VALS.(dimparams{2}) == vals{2}(j) ...
                    & params.VALS.(dimparams{3}) == vals{3}(k);
                data(:,i,j,k) = mean(psth(:,ind),2);
            end
        end
    end

end


varargout{1} = data;
varargout{2} = [{binvec},vals];






