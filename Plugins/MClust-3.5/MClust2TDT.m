function MClust2TDT(datfilename,varargin)
% MClust2TDT(datfilename)
% MClust2TDT(datfilename,'parameter',value)
% 
% Update tank with a new sort code after processing with MClust.
% 
%   parameter       default value
%   ---------       -------------
%   SERVER        = 'Local';        % Tank server
%   BLOCKROOT     = 'Block';        % Block root
%   SORTNAME      = 'MClust';       % Name for sort code
%   SORTCONDITION = 'KlustaKwik';   % Sort condition
% 
% See also, TDT2MClust, MClust
% 
% DJS 2013

% defaults are modifiable using varargin parameter, value pairs
SERVER        = 'Local';
BLOCKROOT     = 'Block';
SORTNAME      = 'MClust';
SORTCONDITION = 'KlustaKwik';

% parse inputs
for i = 1:2:length(varargin)
    eval([upper(varargin{i}) '=varargin{i+1};']);
end

load(datfilename,'-mat'); % data
tank = data.tank;
rootfn = datfilename(1:end-4);

TTXfig = figure('Visible','off','HandleVisibility','off');
TTX = actxcontrol('TTank.X','Parent',TTXfig);

if ~TTX.ConnectServer(SERVER, 'Me')
    error(['Problem connecting to Tank server: ' SERVER])
end

if ~TTX.OpenTank(tank, 'W')
    CloseUp(TTX,TTXfig);
    error(['Problem opening tank: ' tank]);
end



% find units sorted with MClust
unitfiles = dir([rootfn '*.t']);
for i = 1:length(unitfiles)
    sidx = find(unitfiles(i).name=='_',1,'last');
    eidx = find(unitfiles(i).name=='-',1,'last');
    unit = str2num(unitfiles(i).name(sidx+1:eidx-1)); %#ok<ST2NM>
    load(unitfiles(i).name,'-mat'); % TS
    ind = ismember(data.unwrapped_times,TS);
    
    % update Tank with new MClust sort codes 
    for b = data.validblocks
        blockname = [BLOCKROOT '-' num2str(b)];
        if ~TTX.SelectBlock(blockname)
            CloseUp(TTX,TTXfig)
            error('MClust2TDT: Unable to select block ''%s''',blockname)
        end
        bind = ind & data.unwrapped_blocks == b;
        if ~any(bind), continue; end
        
        fprintf('Tank: ''%s'', Block: ''%s'', Channel: %d, Unit: %d has % 7.0f spikes ...', ...
            tank,blockname,data.channel,unit,sum(bind))
        
        SCA = uint32([data.index(bind)'; unit*ones(1,sum(bind))]);
        SCA = SCA(:)';
        
        success = TTX.SaveSortCodes(SORTNAME,data.SnipName,data.channel, ...
            SORTCONDITION,SCA);
        
        if success
            fprintf(' UPDATED\n')
        else
            fprintf(' FAILED\n')
            CloseUp(TTX,TTXfig)
        end
    end 
end

CloseUp(TTX,TTXfig)




function CloseUp(TTX,TTXfig)
TTX.CloseTank;
TTX.ReleaseServer;
close(TTXfig);















