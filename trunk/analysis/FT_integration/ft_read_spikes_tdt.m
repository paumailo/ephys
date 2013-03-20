function data = ft_read_spikes_tdt(cfg)
% data = ft_read_spikes_tdt(cfg)
%
% Read continuous (LFP) data from TDT Tank and convert for use with
% FieldTrip toolbox
%
% cfg.tank     ...  Full path to tank and tank name is required if tank is
%                   not registered.  If tank is registered, then just the
%                   tank name is required.
%    .block    ...  Scalar integer of a block number.  If not specified,
%                   then a prompt will appear with a list of blocks from
%                   the tank.
%    .event    ...  Here, event is the name of the spike event such as
%                   'Snip','eNeu','Spik',etc.. (default = 'eNeu')
%    .sortname ...  Name of classification in OpenSorter (optional)
%
%    .chremap  ...  Remap channels (optional)
% 
% See also, trialfun_tdt
%
% DJS 2013

if ~isfield(cfg,'tank'),    error('tank field is required for cfg');    end
if ~isfield(cfg,'event'),   cfg.event = 'eNeu';     end
if ~isfield(cfg,'chremap'), cfg.chremap = [];       end

cfg.datatype = 'BlockInfo';
cfg.usemym   = false;
if ~isfield(cfg,'block') || isempty(cfg.block)
    tinfo = getTankData(cfg);
    if isempty(tinfo)
        error('No blocks found in ''%s''',tank)
    end
    [sel,ok] = listdlg('PromptString','Select one block', ...
        'SelectionMode','single', ...
        'ListString',num2cell([tinfo.block]));
    if ~ok, return; end
    cfg.block = tinfo(sel).block;
end

% Read in Spike data from the tank
cfg.usemym      = false;
cfg.datatype    = 'Spikes';
S = getTankData(cfg);

if isempty(cfg.chremap), cfg.chremap = 1:length(S); end
if ~isequal(length(S),length(cfg.chremap))
    error('The chremap was specified, but does not equal the number of channels in the recording')
end

% Create data structure
for i = 1:length(S)
    data.label{i}           = sprintf('ch%02.0f',S(i).channel);
    data.timestamp{i}       = uint64(round(S(i).fsample*S(i).timestamps{1}'));
    data.unit{i}            = S(i).sortcode{1}';
    data.waveform{i}(1,:,:) = S(i).waveforms{1}';
    data.dimord             = '{chan}_lead_time_spike';
end

% generate a header
data.hdr.ADFrequency = S(1).fsample;
data.hdr.NumDSPChannels = length(S);




















