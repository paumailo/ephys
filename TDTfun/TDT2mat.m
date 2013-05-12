function data = TDT2mat(tank, block, varargin)
%TDT2MAT  TDT tank data extraction.
%   blocks = TDT2mat(TANK)
%   data = TDT2mat(TANK, BLOCK) 
%  
%   If the TANK name is the only input then a list of blocks will be
%   returned in a cell array.
%
%   Where TANK and BLOCK are strings, retrieve all data from specified
%   block in struct format.
%
%   data.epocs      contains all epoc store data (onsets, offsets, values)
%   data.snips      contains all snippet store data (timestamps, channels,
%                   and raw data)
%   data.streams    contains all continuous data (sampling rate and raw
%                   data)
%   data.info       contains some additional information about the block
%
%   "parameter", value pairs...
%       "T1" is a scalar, retrieve data starting at T1 (0 for start at
%           beginning of recording).
%       "T2" is a scalar, retrieve data ending at T2 (0 for end at ending
%           of recording).
%       "SILENT" a summary of tank data will be
%           returned if false (default).
%       "TYPE" specifies to return all or subset of datatypes
%                   ex: data = TDT2mat("MyTank","Block-1","TYPE",[1 2]);
%                           > returns epocs and snips data
%           1   ...   all (default)
%           2   ...   epocs
%           3   ...   snips
%           4   ...   streams
%
% Built by TDT, modified by DJS 5/2013

data.epocs   = [];
data.snips   = [];
data.streams = [];
data.info    = [];

T1      = 0;
T2      = 0;
SILENT  = 0;
TYPE    = 1;

for i = 1:2:length(varargin)
    if isscalar(varargin{i+1})
        eval(sprintf('%s = %d;',upper(varargin{i}), varargin{i+1}));
    elseif isvector(varargin{i+1})
        eval(sprintf('%s = [%s];',upper(varargin{i}), num2str(varargin{i+1}(:)')));
    elseif ischar
        eval(sprintf('%s = %s;',upper(varargin{i}), varargin{i+1}));
    end
end

if TYPE == 1, TYPE = 1:4; end

TTXfig = figure('Visible','off','HandleVisibility','off');
TTX = actxcontrol('TTank.X','Parent',TTXfig);

server = 'Local';
if TTX.ConnectServer(server, 'Me') ~= 1
    error(['Problem connecting to Tank server: ' server])
end

if TTX.OpenTank(tank, 'R') ~= 1
    CloseUp(TTX,TTXfig);
    error(['Problem opening tank: ' tank]);
end

blocks{1} = TTX.QueryBlockName(0);
i = 1;
while strcmp(blocks{i}, '') == 0
    i = i+1;
    blocks{i} = TTX.QueryBlockName(i); %#ok<AGROW>
end
blocks(end) = [];

if nargin == 1
    data = blocks;
    return
end

if TTX.SelectBlock(['~' block]) ~= 1
    CloseUp(TTX,TTXfig);
    if ~ismember(block, blocks)
        error(['Block found, but problem selecting it: ' block]);
    end
    error(['Block not found: ' block]);
end

TTX.SetGlobalV('WavesMemLimit',1e9);
TTX.SetGlobalV('MaxReturn',1e6);
TTX.SetGlobalV('T1', T1);
TTX.SetGlobalV('T2', T2);

lStores = TTX.GetEventCodes(0);
for i = 1:length(lStores)
    name = TTX.CodeToString(lStores(i));
    if ~SILENT, fprintf('Store Name:\t%s\n', name); end
    
    TTX.GetCodeSpecs(lStores(i));
    type = TTX.EvTypeToString(TTX.EvType);
    if ~SILENT, fprintf('EvType:\t\t%s\n', type); end
    
    if bitand(TTX.EvType, 33025) == 33025 % catch RS4 header (33073)
        type = 'Stream';
    end
    
    switch type
        case 'Strobe+'
            if ~any(TYPE==2), continue; end
            d = TTX.GetEpocsV(name, T1, T2, 1e6)';
            data.epocs.(name).data  = d(:,1);
            data.epocs.(name).onset = d(:,2);
            if d(:,3) == zeros(size(d(:,3)))
                d(:,3) = [d(2:end,2); inf];
            end
            data.epocs.(name).offset = d(:,2);
            
        case 'Scalar'
            if ~any(TYPE==2), continue; end
            N = TTX.ReadEventsSimple(name);
            data.epocs.(name).data  = TTX.ParseEvV(0, N);
            data.epocs.(name).onset = TTX.ParseEvInfoV(0, N, 6);
            
        case 'Stream'
            if any(TYPE==4)
                TTX.ReadEventsV(0, name, 0, 0, 0, 0, 'ALL');
                data.streams.(name).data = TTX.ReadWavesV(name);
                num_channels = size(data.streams.(name).data,2);
            else
                TTX.SetGlobalV('T1', 0);
                TTX.SetGlobalV('T2', 5);
                TTX.ReadEventsV(2^9, name, 0, 0, 0, 5, 'ALL');
                t = TTX.ReadWavesV(name);
                TTX.SetGlobalV('T1', T1);
                TTX.SetGlobalV('T2', T2);
                num_channels = size(t,2);
            end
            if ~SILENT, fprintf('N channels:\t%d\n', num_channels); end
            data.streams.(name).chan = 1:num_channels;
            data.streams.(name).fs = TTX.EvSampFreq;
            if ~SILENT, fprintf('Data Size:\t%d\n',TTX.EvDataSize); end
            if ~SILENT, fprintf('Samp Rate:\t%f\n',TTX.EvSampFreq); end
            
        case 'Snip'
            if any(TYPE==3)
                N = TTX.ReadEventsV(1e7, name, 0, 0, 0, 0, 'ALL');
                data.snips.(name).data = TTX.ParseEvV(0, N)';
                data.snips.(name).chan = TTX.ParseEvInfoV(0, N, 4);
                data.snips.(name).sort = TTX.ParseEvInfoV(0, N, 5);
                data.snips.(name).ts   = TTX.ParseEvInfoV(0, N, 6);
            else
                TTX.ReadEventsV(2^9, name, 0, 0, 0, 0, 'ALL');
            end
            data.snips.(name).fs = TTX.EvSampFreq;
            if ~SILENT, fprintf('Data Size:\t%d\n',TTX.EvDataSize); end
            if ~SILENT, fprintf('Samp Rate:\t%f\n',TTX.EvSampFreq); end
            
    end
    if ~SILENT, disp(' '); end
end

% get general block info
t1                  = TTX.CurBlockStartTime;
data.info.date      = TTX.FancyTime(t1,'Y-O-D');
data.info.begintime = TTX.FancyTime(t1,'H:M:S');
t2                  = TTX.CurBlockStopTime;
data.info.endtime   = TTX.FancyTime(t2,   'H:M:S');
data.info.duration  = TTX.FancyTime(t2-t1,'H:M:S');
data.info.blockname = block;

data = orderfields(data);

CloseUp(TTX,TTXfig)




function CloseUp(TTX,TTXfig)
TTX.CloseTank;
TTX.ReleaseServer;
close(TTXfig);

