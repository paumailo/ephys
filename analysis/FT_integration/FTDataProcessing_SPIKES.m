%% Set some variables
tank        = 'SLYTHERIN_VTA_INTEGRATED';
block       = 5;
blockroot   = [tank '-'];


%% Read SPIKEs from Plexon file
[plxfile,path2plx] = uigetfile({'*.plx','Plexon file (*.plx)'}, ...
    'Locate Plexon File');

SPIKE = ft_read_spike(fullfile(path2plx,plxfile));

%% Call custom trial function (trialfun_tdt) to segment SPIKE data
cfg = [];
cfg.tank        = tank;
cfg.blocks      = block;
cfg.blockroot   = blockroot;
cfg.trialdef.prestim    = 0.5;
cfg.trialdef.poststim   = 1;
cfg.trialdef.eventtype  = 'BitM';
cfg.trialdef.eventvalue = 16;
cfg.trialfun            = 'trialfun_tdt';
cfg.timestampspersecond = SPIKE.hdr.ADFrequency;

cfg = ft_definetrial(cfg);
visSPIKE = ft_spike_maketrials(cfg,SPIKE);

cfg = [];
cfg.tank        = tank;
cfg.blocks      = block;
cfg.blockroot   = blockroot;
cfg.trialdef.prestim    = 0.5;
cfg.trialdef.poststim   = 1;
cfg.trialdef.eventtype  = 'BitM';
cfg.trialdef.eventvalue = 32;
cfg.trialfun            = 'trialfun_tdt';
cfg.timestampspersecond = SPIKE.hdr.ADFrequency;

cfg = ft_definetrial(cfg);
audSPIKE = ft_spike_maketrials(cfg,SPIKE);



%% Add waveforms if you like
cfg             = [];
cfg.fsample     = SPIKE.hdr.ADFrequency;
cfg.interpolate = 1; % keep the density of samples as is
cfg.align       = 'no';
[wave, SPIKECleaned] = ft_SPIKE_waveform(cfg,SPIKE);


