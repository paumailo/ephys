%% Set some variables
tank        = 'SLYTHERIN_VTA_INTEGRATED';
block       = 5;
blockroot   = [tank '-'];

%% Read continuous LFP from tank
cfg = [];
cfg.tank      = tank;
cfg.blocks    = block;
cfg.blockroot = blockroot;

fullLFP = ft_read_lfp_tdt(cfg.tank,cfg.blocks,cfg.blockroot);

%% Call custom trial function (trialfun_tdt) to segment continuous LFP data
cfg = [];
cfg.tank      = tank;
cfg.blocks    = block;
cfg.blockroot = blockroot;
cfg.trialfun  = 'trialfun_tdt';
cfg.trialdef.prestim    = 0.5;
cfg.trialdef.poststim   = 1;
cfg.trialdef.eventtype  = 'BitM';
cfg.trialdef.eventvalue = 16;     % <-- set event value 
cfg = ft_definetrial(cfg);
visLFP = ft_redefinetrial(cfg,fullLFP);

cfg = [];
cfg.tank      = tank;
cfg.blocks    = block;
cfg.blockroot = blockroot;
cfg.trialfun  = 'trialfun_tdt';
cfg.trialdef.prestim    = 0.5;
cfg.trialdef.poststim   = 1;
cfg.trialdef.eventtype  = 'BitM';
cfg.trialdef.eventvalue = 32;    % <-- set event value 
cfg = ft_definetrial(cfg);
audLFP = ft_redefinetrial(cfg,fullLFP);

clear fullLFP

