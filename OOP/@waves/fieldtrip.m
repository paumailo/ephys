function ft = fieldtrip(obj)
% ft = fieldtrip
% Export current block data for FieldTrip toolbox

cfg = [];
cfg.tank  = obj.name;
cfg.block = obj.currentblock;
cfg.event = obj.eventname;
ft = ft_read_lfp_tdt(cfg.tank,cfg.block);

