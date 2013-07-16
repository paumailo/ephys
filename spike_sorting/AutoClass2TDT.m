function AutoClass2TDT(poolfn,varargin)
% AutoClass2TDT(poolfn)
% AutoClass2TDT(poolfn,varargin)
%
% POOLFN is the full path and filename saved by Pooling_GUI2.
%
% Update tank with a new sort code after processing with MClust.
% 
%   parameter       default value
%   ---------       -------------
%   SERVER        = 'Local';        % Tank server
%   SORTNAME      = 'Pooled';       % Name for sort code
%   SORTCONDITION = 'AutoClass';    % Sort condition
% 
% See also, AutoClass2, Pooling_GUI2
% 
% DJS 2013




% defaults are modifiable using varargin parameter, value pairs
SERVER        = 'Local';
SORTNAME      = 'Pooled';
SORTCONDITION = 'AutoClass';

% parse inputs
for i = 1:2:length(varargin)
    eval([upper(varargin{i}) '=varargin{i+1};']);
end

% Parse info about file
[pathstr,poolfn,~] = fileparts(poolfn);

idx = strfind(poolfn,'_Ch_'); idx = idx(end);
tank = poolfn(1:idx-1);

chstr = poolfn(idx+4:find(poolfn=='_',1,'last')-1);
channel = str2num(chstr); %#ok<ST2NM>



% Establish connection to TDT tank
TTXfig = figure('Visible','off','HandleVisibility','off');
TTX = actxcontrol('TTank.X','Parent',TTXfig);

if ~TTX.ConnectServer(SERVER, 'Me')
    error('AutoClass2TDT: Problem connecting to Tank server: %s', SERVER)
end

if ~TTX.OpenTank(tank, 'W')
    CloseUp(TTX,TTXfig);
    error('AutoClass2TDT: Problem opening tank: %s', tank);
end



% load necessary variables from disk
load(fullfile(pathstr,[poolfn '.mat']),'POOLS');

snipfn = fullfile(pathstr,sprintf('%s_%03d_SNIP.mat',tank,channel));
if ~exist(snipfn,'file')
    CloseUp(TTX,TTXfig);
    error('Filename "%s" not found',snipfn)
end
load(snipfn,'cfg');


% update tank sort codes
blocks = cfg.TankCFG.blocklist;
nspikes = [0 cfg.Spikes.blockspikes];
cspikes = [0 cumsum(nspikes(2:end))];
for B = 1:length(blocks)
    
    if ~TTX.SelectBlock(['~' blocks{B}])
        CloseUp(TTX,TTXfig)
        error('AutoClass2TDT: Unable to select block ''%s''',blocks{B})
    end
    
    fprintf('Updating tank "%s"\tblock "%s"  \tchannel % 3d ...',tank,blocks{B},channel)
    
    N = TTX.ReadEventsV(1e6,cfg.TankCFG.event,channel,0,0,0,'IDXPSQ');
    if N == 0
        fprintf(' NO SPIKES\n')
        continue
    end
    
    tqidx = TTX.GetEvTsqIdx;
    
    bvec = cspikes(B)+1:cspikes(B+1);
    
    if bvec(end) > length(POOLS)
        warning('AutoClass2TDT: A mismatch occurred between pooled spikes and spikes in tank.')
        if bvec(1) > length(POOLS), continue; end                
        bvec = bvec(1):length(POOLS);
        tqidx = 1:length(bvec);
    end
    
    SCA = uint32([tqidx; POOLS(bvec)]);
    SCA = SCA(:)';
    
    success = TTX.SaveSortCodes(SORTNAME,cfg.TankCFG.event,channel,SORTCONDITION,SCA);
    
    if ~success
        CloseUp(TTX,TTXfig);
        error('AutoClass2TDT: Unable to update block "%s" on tank "%s" with new sortcode "%s"', ...
            blocks{B},tank,SORTNAME);
    end
    
    
    fprintf(' done\n')
end

CloseUp(TTX,TTXfig)











function CloseUp(TTX,TTXfig)
TTX.CloseTank;
TTX.ReleaseServer;
close(TTXfig);






