function trl = trialfun_tdt(cfg)
% trl = trialfun_tdt(cfg)
% 
% Returns trl structure for use with FieldTrip
%
% cfg.tank          ...     registered tank name (or full path to tank)
%    .block         ...     scalar integer of a single tank block to process
%    .blockroot     ...     root name of the block (eg, 'Block-')
%    .eventname     ...     name of an event (eg, 'BitM')
%
%    .wonset        ...     onset time (seconds) of window relative to event trigger
%    .woffset       ...     offset time (seconds) of window relative to event trigger
%
% DJS 2013

% check cfg structure
if ~isfield(cfg,'tank'),    error('Missing tank name in cfg');      end
if ~isfield(cfg,'blocks'),  error('Missing blocks number in cfg');   end
if ~isfield(cfg,'blockroot'), cfg.blockroot = [];                   end
if ~isfield(cfg,'eventname'), cfg.eventname = [];                   end


event = ft_read_event_tdt(cfg.tank,cfg.blocks,cfg.blockroot,cfg.eventname);


cfg.usemym = false;
cfg.silently = true;
tinfo = getTankData(cfg);

Fs = min(tinfo.allfsamples); % use lowest sampling rate in data (usually LFP)

if Fs > 1500 % downsample to ~1kHz.  This is done in ft_read_lfp_tdt
    Fs = Fs/round(Fs/1000);
end

% convert wonset and woffset parameters to samples
swonset  = round(cfg.wonset*Fs);
swoffset = round(cfg.woffset*Fs);

esamps = [event.sample];

trl(:,1) = esamps+swonset;
trl(:,2) = esamps+swoffset;
trl(:,3) = swonset;
trl(:,4) = [event.value];


%  The trial definition "trl" is an Nx3 matrix, N is the number of trials.
%   The first column contains the sample-indices of the begin of each trial 
%   relative to the begin of the raw data, the second column contains the 
%   sample-indices of the end of each trial, and the third column contains 
%   the offset of the trigger with respect to the trial. An offset of 0 
%   means that the first sample of the trial corresponds to the trigger. A 
%   positive offset indicates that the first sample is later than the trigger, 
%   a negative offset indicates that the trial begins before the trigger.

