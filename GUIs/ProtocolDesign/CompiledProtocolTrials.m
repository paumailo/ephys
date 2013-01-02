function trials = CompiledProtocolTrials(protocol,varargin)
% cp = CompiledProtocolTrials(h)
% return and/or view compiled protocol trials
%
% Parameter ... Value
%   showgui ... true/false
%     trunc ... truncate to some scalar value. (default = 0, no truncation)
% 
% See also, ProtocolDesign
%
% DJS 2012

argin.showgui = true;
argin.trunc   = 0;

if nargin > 1
    for i = 1:2:length(varargin)
        argin.(varargin{i}) = varargin{i+1};
    end
end

protocol = CompileProtocol(protocol);
C = protocol.COMPILED;

trials = C.trials;
if argin.trunc && size(trials,1) > argin.trunc
    trials = trials(1:argin.trunc,:);
end

% adjust values for table
% trials = cell(size(C.trials));
for i = 1:numel(trials)
    if isnumeric(trials{i})
        trials{i} = num2str(trials{i});
    elseif isstruct(trials{i})
        trials{i} = trials{i}.file;
    else
        trials{i} = trials{i};
    end
end

if argin.showgui, ShowGUI(C,trials); end



function ShowGUI(C,trials)
fh = findobj('type','figure','-and','tag','CPfig');
if isempty(fh)
    fh = figure('tag','CPfig','Position',[200 100 700 400]);
end
figure(fh); % bring to front
sc = size(C.trials,1);
set(fh, ...
    'Name',sprintf('Compiled Protocol: # trials = %d',sc), ...
    'NumberTitle','off');

uitable(fh, ...
    'Units',        'Normalized', ...
    'Position',     [0.025 0.025 0.95 0.95], ...
    'Data',         trials, ...
    'ColumnName',   C.writeparams, ...
    'ColumnWidth',  'auto', ...
    'TooltipString','Presentation Order');



