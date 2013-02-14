function TTX = TankSelect(varargin)
%   TankSelect
%   TTX = TankSelect
%
%
%   parameters:
%   'TTX',TTX,'Tank',Tank_Name,'Block',Block_Name,'Server',Server_Name
%
%
% DJS 2009

TTX = []; Tank = []; Block = []; Server = [];
for idx = 1:2:length(varargin)
    switch lower(varargin{idx})
        case 'ttx'
            TTX = varargin{idx+1};
        case 'tank'
            Tank = varargin{idx+1};
        case 'block'
            Block = varargin{idx+1};
        case 'server'
            Server = varargin{idx+1};
    end
end

if isempty(Server), Server = []; end
if isempty(TTX)
    TDTcrapwindow = figure;
    set(TDTcrapwindow,'Visible','off');
    TTX = ConnectServer(Server);
end   %connect to server

if ~isempty(Tank)
    if TTX.OpenTank(Tank,'R')
%         display(sprintf('Tank ''%s'' opened successfully',Tank))
    else
        error('Unable to open Tank: ''%s''',Tank)
    end

    if TTX.CheckTank(Tank) == 0
        CloseTTX(TTX);
        error('Tank closed');
%     elseif TTX.CheckTank(Tank) == 82
%         if ~RECORDING
%             CloseTTX(TTX);
%             error('Tank is in record mode.  Stop it and try again');
%         end
    end

    if ~isempty(Block) && ~TTX.SelectBlock(Block)
        CloseTTX(TTX);
        error('Not able to open tank %s!',Block);
    end
    TTX.CreateEpocIndexing;
elseif isempty(Tank) && ~isempty(Block)
    error('If a Block is specified then you must also specify its tank')
end

end
