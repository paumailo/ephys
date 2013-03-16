function data = ft_read_lfp_tdt(tank,block,blockroot)

if nargin == 0 || isempty(tank),  tank = char(TDT_TankSelect); end
cfg.tank     = tank;
cfg.datatype = 'BlockInfo';
cfg.usemym   = false;
if nargin < 2
    tinfo = getTankData(cfg);
    if isempty(tinfo)
        error('No blocks found in ''%s''',tank)
    end
    [sel,ok] = listdlg('PromptSstring','Select one block', ...
        'SelectionMode','single', ...
        'ListString',num2cell([tinfo.block]));
    if ~ok, return; end
    block = tinfo(sel).block;
end
if nargin < 3, blockroot = 'Block-'; end

% Read in continuous 'Wave' data from the tank
cfg = [];
cfg.tank        = tank;
cfg.blocks      = block;
cfg.blockroot   = blockroot;
cfg.usemym      = false;
cfg.datatype    = 'Waves';
W = getTankData(cfg);


for i = 1:length(W.channels)
    data.label{i,1} = num2str(W.channels(i));
end

% downsample continuous data (make a user defined parameter)
sstep = 1;
if W.fsample > 1500
    sstep     = round(W.fsample/1000);
    W.fsample = W.fsample/sstep;
end
data.fsample    = W.fsample;
data.trial      = {W.waves(1:sstep:end,:)'};
L               = size(data.trial{1},2);
data.time       = {linspace(0,(L-1)/data.fsample,L)};
data.sampleinfo = [1 L];

data = ft_preprocessing([],data);







