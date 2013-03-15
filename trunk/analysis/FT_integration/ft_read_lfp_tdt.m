function LFP = ft_read_lfp_tdt(tank,block,blockroot)

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

% Manually read in continuous 'Wave' data
fprintf('Reading LFP data ...')
cfg = [];
cfg.tank        = tank;
cfg.blocks      = block;
cfg.blockroot   = blockroot;
cfg.usemym      = false;
cfg.datatype    = 'Waves';
W = getTankData(cfg);


for i = 1:length(W.channels)
    LFP.label{i,1} = sprintf('Chan%02.0f',W.channels(i));
end

% downsample continuous data (make a user defined parameter)
sstep = 1;
if W.fsample > 1500
    sstep     = round(W.fsample/1000);
    W.fsample = W.fsample/sstep;
end
LFP.fsample = W.fsample;
LFP.trial = {W.waves(1:sstep:end,:)'};
L         = size(LFP.trial{1},2);
LFP.time  = {linspace(0,(L-1)/LFP.fsample,L)};

fprintf(' done\n')








