function varargout = shapedata_wave(wave,tvec,params,dimparams,varargin)
% data = shapedata_wave(wave,tvec,params,dimparams)
% data = shapedata_wave(...,'PropertyName',PropertyValue)
% [data,vals] = shapedata_wave(...) 
%
% PropertyName ... PropertyValue
% 'win'     ... window (eg, [-0.1 0.5]) in seconds
% 
% DJS 2013
%
% See also, shapedata_spikes


win = [0 0.1];

for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'win', win = varargin{i+1};
    end
end

Fs = params.wave_fs;

% sort trials by onsets
ons = params.lists.onset;

winsamps = floor(Fs*win(1)):ceil(Fs*win(2));

% tdata:   samples/trials
tdata = zeros(length(winsamps),length(ons));

for i = 1:length(ons)
    idx = find(tvec>=ons(i),1)+winsamps;
    tdata(:,i) = wave(idx);
end

for i = 1:length(dimparams)
    vals{i} = params.lists.(dimparams{i}); %#ok<AGROW>
end

if length(vals) == 1
    % data:    samples/param1
    data = zeros(length(winsamps),length(vals{1}));
    for i = 1:length(vals{1})
        ind = params.VALS.(dimparams{1}) == vals{1}(i);
        data(:,i) = mean(tdata(:,ind),2);
    end
    
    
elseif length(dimparams) == 2
    % data:    samples/param1/param2
    data = zeros(length(winsamps),length(vals{1}),length(vals{2}));
    for i = 1:length(vals{1})
        for j = 1:length(vals{2})
            ind = params.VALS.(dimparams{1}) == vals{1}(i) ...
                & params.VALS.(dimparams{2}) == vals{2}(j);
            data(:,i,j) = mean(tdata(:,ind),2);
        end
    end
    
    
elseif length(dimparams) == 3
    % data:    samples/param1/param2/param3
    data = zeros(length(winsamps),length(vals{1}),length(vals{2}),length(vals{3}));
    for i = 1:length(vals{1})
        for j = 1:length(vals{2})
            for k = 1:length(vals{3})
                ind = params.VALS.(dimparams{1}) == vals{1}(i) ...
                    & params.VALS.(dimparams{2}) == vals{2}(j) ...
                    & params.VALS.(dimparams{3}) == vals{3}(k);
                data(:,i,j,k) = mean(tdata(:,ind),2);
            end
        end
    end

end


varargout{1} = data;
varargout{2} = [{winsamps},vals];






