function ft = fieldtrip(obj)
% ft = fieldtrip
% Export spikes objectdata for FieldTrip toolbox

cfg = [];
cfg.tank     = obj.name;
cfg.block    = obj.currentblock;
cfg.event    = obj.eventname;
cfg.sortname = obj.sortname;
ft = ft_read_spikes_tdt(cfg);

