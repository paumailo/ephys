function varargout = shapedata_wave(wave,tvec,params,dimparams,varargin)
% data = shapedata_wave(wave,tvec,params,dimparams)
% data = shapedata_wave(...,'PropertyName',PropertyValue)
% [data,vals] = shapedata_wave(...) 
%
% Reshapes continuously sampled data based on some parameters (dimparams)
%
% PropertyName  ... PropertyValue
% 'win'         ... window (eg, [-0.1 0.5]) in seconds
% 
% Daniel.Stolzberg at gmail com 2013
%
% See also, shapedata_spikes, DB_GetWave


win = [0 0.1];

ParseVarargin('win',[],varargin);

Fs = params.wave_fs;

% sort trials by onsets
ons = params.VALS.onset;

winsamps = floor(Fs*win(1)):round(Fs*win(2));

% tdata:   samples/trials
tdata = zeros(length(winsamps),length(ons));

for i = 1:length(ons)
    idx = find(tvec>=ons(i),1);
    if isempty(idx)
        error('Trigger onset occurred after time vector: trigger# %d',i)
    end
    idx = idx + winsamps;
    tdata(:,i) = wave(idx);
end

for i = 1:length(dimparams)
    vals{i} = unique(params.VALS.(dimparams{i})); %#ok<AGROW>
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






