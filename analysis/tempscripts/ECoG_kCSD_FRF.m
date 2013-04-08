%% Procedure for retrieving LFP data from Tanks


cfg = [];
cfg.tank  = char(TDT_TankSelect);
[cfg.TT,~,TDTfig] = TDT_SetupTT;

% cfg.block = cfg.TT.GetHotBlock;
cfg.block = 1;
cfg.usemym   = false;
cfg.downfs   = 600;
cfg.datatype = 'BlockInfo';
binfo = getTankData(cfg);

cfg.datatype = 'Waves';
data = getTankData(cfg);

delete(cfg.TT)
close(TDTfig)

%% Possibility for filtering different frequency bands



%% Reorganize by freq/level
n = size(data.waves,1);
Fs = data.fsample;
win = [0 0.2];

i = strcmpi('freq',binfo.paramspec); freqs = binfo.epochs(:,i);
i = strcmpi('levl',binfo.paramspec); levls = binfo.epochs(:,i);
ufreq = unique(freqs);
ulevl = unique(levls);
stmon = binfo.epochs(:,end);
stmonsamps = round(stmon * Fs);

svec = round(win(1)*Fs):round(win(2)*Fs);

% Trial-based LFP dims: {trials} samples x channels
tLFP = cell(length(stmonsamps));
for i = 1:length(stmonsamps)
    sind = stmonsamps(i) + svec;
    tLFP{i} = data.waves(sind,:);
end
tvec = svec/Fs;

%% Electrode positions
% It would be nice to have an image processing routine figure out
% coordinates from a picture of the array located on the cortex.
electrode = 'E32-1000-30-200';
elpath = 'C:\MATLAB\work\ephys\analysis\electrode_maps';
elfn = fullfile(elpath,[electrode,'.txt']);
[x,y] = textread(elfn,'%f%f','delimiter',',');
el_pos = [x y];


%% 2D kCSD
tslices = 1:20:length(tvec); % for computing 2D kCSD
for F = 1:length(ufreq)
    for L = 1:length(ulevl)
        tind = ufreq(F) == freqs & ulevl(L) == levls;
        for i = 1:length(tslices)
            pots = cellfun(@(x) x(tslices(i),:),tLFP(tind),'UniformOutput',false);
            pots = cell2mat(pots);
            pots = mean(squeeze(pots),2);
            k = kcsd2d(el_pos, pots);
            kCSD(:,:,i,F,L) = k.CSD_est;
        end
    end
end

%% Now go back to each electrode site and compute kCSD receptive fields


















