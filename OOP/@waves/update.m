function obj = update(obj)
if isempty(obj.block)
    fprintf('update:Must first set a block number (ex: S.block = 3)\n')
    return
end
if isempty(obj.eventname)
    %                 fprintf('update:Must fist specify eventname (ex: S.eventname = ''Snip'')\n')
    return
end
obj = checkTT(obj);
if obj.verbose, fprintf('Retrieving data ...'); end
obj.TT.CreateEpocIndexing;

obj.TT.SetGlobalV('WavesMemLimit',10^9);

n = obj.TT.ReadEventsV(2^9,obj.eventname,0,0,0,0,'NODATA');
obj.channels = unique(obj.TT.ParseEvInfoV(0,n,4))';
obj.Fs       = obj.TT.ParseEvInfoV(0,1,9);
obj.tankFs   = obj.Fs;

if obj.downFs < obj.Fs
    sstep = round(obj.Fs/obj.downFs);
    if sstep > 1
        % convert sampling rate
        obj.downFs = obj.Fs/sstep;
        fprintf('\nDownsampling by a factor of %d from %0.2f Hz to %0.2f Hz', ...
            sstep,obj.Fs,obj.downFs)
        obj.TT.SetGlobals(sprintf('WaveSF=%0.6f',obj.downFs));
        obj.Fs = obj.downFs;
    end
end

obj.data = [];
for i = 1:length(obj.channels)
    if obj.verbose, fprintf('\n\tChannel: %d\t(%d of %d) ', ...
            obj.channels(i),i,length(obj.channels));
    end
    
    obj.TT.SetGlobals(sprintf('Channel=%d',obj.channels(i)));
    w = obj.TT.ReadWavesV(obj.eventname);
    if (any(isnan(w)) || all(w == 0)) && obj.verbose
        fprintf(' ... no data')
    end
    obj.data(:,i) = w;
end
clear w

if obj.Fs ~= obj.tankFs
    % run anti-aliasing filter if there was a downsampling
    nyquist = obj.Fs/2;
    lppb    = nyquist * 0.90;
    [z,p,k] = butter(6,lppb/nyquist,'low');
    [sos,~] = zp2sos(z,p,k);
    obj.data = single(sosfilt(sos,double(obj.data)));
end

obj.time = (0:1/obj.Fs:(size(obj.data,1)-1)/obj.Fs)';

fprintf('\ndone\n')
