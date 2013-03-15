%% Custom DefineTrial function
cfg = [];
cfg.wonset    = -0.5;
cfg.woffset   = 1;
cfg.tank      = char(TDT_TankSelect);
cfg.blocks    = 5;
cfg.blockroot = [cfg.tank '-'];
cfg.trialfun  = 'trialfun_tdt';

cfg = ft_definetrial(cfg);


%% Read LFPs

LFP = ft_read_lfp_tdt(cfg.tank,cfg.blocks,cfg.blockroot);

% this would be a good place to call ft_preprocessing

% Segment continuous LFP data into trials
% cut out trials which are out of bounds
ind = cfg.trl(:,1) < 1 | cfg.trl(:,2) > size(LFP.trial{1},2); % assuming continuous data;
cfg.trl(ind,:) = [];

LFP = ft_redefinetrial(cfg,LFP);
% LFP.trialinfo  ...  contains event data


%% Limit trials to specific trial type
rcfg = [];
rcfg.trials = LFP.trialinfo == 32;
aLFP = ft_redefinetrial(rcfg,LFP);

rcfg.trials = LFP.trialinfo == 16;
vLFP = ft_redefinetrial(rcfg,LFP);



%% Read spikes from Plexon file

[plxfile,path2plx] = uigetfile({'*.plx','Plexon file (*.plx)'}, ...
    'Locate Plexon File');

spike = ft_read_spike(fullfile(path2plx,plxfile));


%% Make Spike trials

cfg.timestampspersecond = 24414;
spike = ft_spike_maketrials(cfg,spike);


% vspike = ft_redefinetrial(cfg,spike);

% cfg             = [];
% cfg.fsample     = spike.hdr.ADFrequency;
% cfg.interpolate = 1; % keep the density of samples as is
% cfg.align       = 'no';
% [wave, spikeCleaned] = ft_spike_waveform(cfg,spike);


