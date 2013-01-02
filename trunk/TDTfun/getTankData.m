function varargout = getTankData(cfg)
% varargout = getTankData(cfg)
%
% cfg fields (default):  server    ('Local')
%                           - enumerated server as char string
%                        tank      (no default)
%                           - if tank is registered then only the tank name
%                           is required, otherwise the full path must be
%                           specified.
%                        blocks    ('all')
%                           - scalar or vector with block numbers, or 'all'
%                           as a char string
%                        blockroot ('Block-')
%                           - specifies a root for the tank blocks
%                        channel   ('all')
%                           - scalar or vector with channel numbers, or
%                           'all' as a char string
%                        datatype  ('BlockInfo')
%                           - char string indicating one of the following
%                           to be returned as the first output:
%                               'BlockInfo' - protocol information about
%                               each block of the tank as well as some
%                               general information
%                               'Spikes'    - returns spike times and
%                               spike waveforms
%                               'Waves'     - returns continuously sampled
%                               wave data
%                       silently (false)
%                           - if true then data wil be retrieved without
%                           printing information to the command window
%                       TT
%                           - can be used to pass a reference to an
%                           a TTank ActiveX control object which already
%                           has an establisehd connectionn to the TTank
%                           server.  If not specified, then a temporary
%                           connection to the TTank server will be
%                           established.
%
% OUTPUT:   [data] = getTankData(cfg);
%                           - retrieves data of the type specified in
%                           cfg.datatype field.
%                           - the data output will be organized into a
%                           structured array of N blocks with a fields
%                           corresponding to the desired output data type.
%           [data,cfg] = getTankData(cfg);
%                           - returns cfg structure as well as data.
% 
%  DJS (c) 2009


%% Set Defaults
if ~isfield(cfg,'tank') || ~ischar(cfg.tank)
    error('Tank must be specified as a char string');
end
if ~isfield(cfg,'server'),      cfg.server    = 'Local';        end
if ~isfield(cfg,'blockroot'),   cfg.blockroot = 'Block-';       end
if ~isfield(cfg,'blocks'),      cfg.blocks    = 'all';          end
if ~isfield(cfg,'channel'),     cfg.channel   = 'all';          end
if ~isfield(cfg,'datatype'),    cfg.datatype  = 'BlockInfo';    end
if ~isfield(cfg,'silently'),    cfg.silently  = false;          end

if ~any(strcmpi(cfg.datatype,{'Spikes','BlockInfo','Waves','Stream'}))
    error('''%s'' is an invalid datatype.',cfg.datatype);
end

%% Connect Tank
if ~isfield(cfg,'TT') || isempty(cfg.TT)
    TDTwindow = figure('Visible','off');
    TT = actxcontrol('TTank.X',[0 0 1 1],TDTwindow);
    EXTTT = false;
else
    TT = cfg.TT;
    EXTTT = true;
end
cfg.tank = strtrim(cfg.tank);
TT.ConnectServer(cfg.server,'Me');
TT.OpenTank(cfg.tank, 'R');
if ~cfg.silently, fprintf('\nLoading %s from Tank: ''%s''',cfg.datatype,cfg.tank); end

%% Retrieve Block List
if strcmpi(cfg.blocks,'all')

    blocklist{1} = [];
    bidx = 2;
    TT.QueryBlockName(0);   %initialize block query
    while ~strcmp(blocklist{bidx-1},'')
        blocklist{bidx} = TT.QueryBlockName(bidx-1); %#ok<AGROW>
        bidx = bidx + 1;
    end

    blocklist([1 end])   = [];    % erase first and last empties

    
    [~,id] = strtok(blocklist,'-');
    [~,id] = sort(str2num(char(id)),'descend'); %#ok<ST2NM>
    blocklist = blocklist(id);
%     blocklist = sort(blocklist);

    cfg.blocks = 1:length(blocklist);
else
    if iscell(cfg.blocks)
        blocklist = cfg.blocks;
    elseif ischar(cfg.blocks)
        blocklist = {cfg.blocks};
    else
        for i = 1:length(cfg.blocks)
            blocklist{i} = [cfg.blockroot num2str(cfg.blocks(i))]; %#ok<AGROW>
        end
    end
end


for i = 1:nargout
    varargout{i} = []; %#ok<AGROW>
end

if isempty(blocklist), return; end
cfg.blocklist = blocklist;


TT.ResetGlobals;
TT.SetGlobalV('MaxReturn',5*10^8);

[dataout,cfg] = feval(sprintf('get_%s',lower(cfg.datatype)),TT,cfg,blocklist);


legacy   = str2num(TT.GetTankItem(cfg.tank,'VERSION')) == 10; %#ok<ST2NM>;
tankpath = TT.GetTankItem(cfg.tank,'PT');

for i = 1:length(dataout)
    dataout(i).legacy   = legacy;
    dataout(i).tankpath = tankpath;
end


%% Close Connection
TT.CloseTank;
if ~EXTTT && nargout < 3
    TT.ReleaseServer;
    close(TDTwindow);
end

%% Handle Outputs
if nargout >= 1, varargout{1} = dataout;    end
if nargout >= 2, varargout{2} = cfg;        end
if nargout == 3, varargout{3} = TT;         end



function [dataout,cfg] = get_blockinfo(TT,cfg,blocklist) %#ok<DEFNU>
if ~cfg.silently, fprintf('\n'); end
for bidx = 1:length(cfg.blocks)
    DO.id   = cfg.blocks(bidx); 
    DO.name = blocklist{bidx}; 
    
    DO.Wave = [];
    DO.Snip = [];
    DO.Strm = [];

    if ~cfg.silently, fprintf('Retrieving Block info %d of %d ... ',bidx,length(cfg.blocks)); end

    if ~TT.SelectBlock(blocklist{bidx})
        error(['Unable to select block: ', blocklist{bidx}]);
    end

    TT.CreateEpocIndexing;
    
    events = {'Wave','Strm','STRM','Snip','Spik'};
    for i = 1:length(events)
        ev = events{i};
        n = TT.ReadEventsV(256,ev,0,0,0,0,'NODATA');
        if ~n,  continue;   end
        if strcmp(events{i},'STRM'), ev = 'Strm'; end % ad hoc
        DO.(ev).fsample = TT.ParseEvInfoV(0,1,9);
        
        % make sure there is actually data on the channel
        c = unique(TT.ParseEvInfoV(0,n,4));
        k = 1;
        TT.SetGlobalV('T1',0);  TT.SetGlobalV('T2',1);
        for j = 1:length(c)
            TT.SetGlobalV('Channel',c(j));
            w = TT.ReadWavesV(events{i});
            if any(w)
                DO.(ev).channels(k) = c(j);
                k = k + 1;
            end
        end
        TT.SetGlobalV('T1',0);  TT.SetGlobalV('T2',0); 
    end

    % get general block info
    t1 = TT.CurBlockStartTime;
    DO.date      = TT.FancyTime(t1,'Y-O-D');
    DO.begintime = TT.FancyTime(t1,'H:M:S');
    t2 = TT.CurBlockStopTime;
    DO.endtime   = TT.FancyTime(t2,   'H:M:S');
    DO.duration  = TT.FancyTime(t2-t1,'H:M:S');

    % retrieve protocol ID #
    n = TT.ReadEventsV(1,'PROT',0,0,0,0,'NODATA');
    if n
        protocol = TT.ParseEvV(0,1);
    else
        n = TT.ReadEventsV(1,'Etyp',0,0,0,0,'NODATA');
        if n
            protocol = TT.ParseEvV(0,1);
        else
            fprintf('\n*** Unknown experiment type ***\n')
            protocol = 2000;
%             pstr = inputdlg('Please Enter Protocol #','Unknown Experiment Type');
%             if isempty(pstr)
%                  continue
%             else
%                 protocol = str2num(char(pstr)); %#ok<ST2NM>
%             end
        end
    end
    

    TT.ResetFilters;

    % get Event names
    i = 1;
    while true
        DO.events{i} = TT.GetEpocCode(i-1);
        if isempty(DO.events{i})
            DO.events(i) = [];
            break
        end
        i = i + 1;
    end
    
    % ad hoc fix for mislabeled TMF protocol
    if ismember('CurN',DO.events)
        protocol = 6;
    end
    DO.protocol = protocol;
 
    % List of protocol types 
    % mym('SELECT * FROM db_util.protocol_types')
    switch protocol
        case 0
            DO.protocolname = 'eFRA';
        case 1
            DO.protocolname = 'iFRA';
        case 2
            DO.protocolname = 'Spont';
        case 3
            DO.protocolname = 'RLF';
        case 4
            DO.protocolname = 'LFP';
        case 6
            DO.protocolname = 'TMF';
        case 7
            DO.protocolname = 'FEA';
        case 8
            DO.protocolname = 'FNB';
        case 9
            DO.protocolname = 'OdBal';
        case 10
            DO.protocolname = 'tABR';
        case 11
            DO.protocolname = 'STRF';

            % v--- JOE WALTON'S LEGACY TANKS ---v
        case 20
            tf = TT.GetEpocsV('Freq',0,0,1000);
            if all(tf(1,:)==0)
                % spont protocol used eFRA RPvds with 0 for voltage
                protocol = 2;
                DO.protocolname = 'Spont';
            else
                DO.protocolname = 'eFRA';
            end
        case 25
            DO.protocolname = 'iFRA';
        case 40
            DO.protocolname = 'Gaps';
            % ^---------------------------------^

        case 200
            DO.protocolname = 'eFRA';
            
        case 201
            DO.protocolname = 'Odbal';
            
        case 202
            DO.protocolname = 'FlshT';
            
        case 203
            DO.protocolname = 'FTodb';
            
        otherwise
            DO.protocolname = 'UNKNOWN';
    end

    
    
    DO.epochs = [];
    DO.paramspec = {[]};
    
    % To get a list of param types use:
    %     mym('SELECT * FROM db_util.param_types')
    
    if protocol >= 200
        % generalized for any protocol
        DO.paramspec = DO.events(~ismember(DO.events,{'Tick','Tock','PROT'}));
        if isempty(DO.paramspec)
            dataout(bidx) = DO; %#ok<AGROW>
            clear DO;
            fprintf('* NO PARAMETERS FOUND *\n')
            continue
        end
        for i = 1:length(DO.paramspec)            
            t = TT.GetEpocsV(DO.paramspec{i},0,0,10^6)';
            if i == 1
                ons = t(:,2);
            end
            
            DO.epochs(:,i) = t(:,1);
        end
        DO.epochs(:,end+1)  = ons;
        DO.paramspec{end+1} = 'onset';

      
    else
        % specified for each protocol type
        switch (DO.protocolname)
            case 'Spont'
                ticks  = TT.GetEpocsV('Tick',0,0,10^6)';
                if isnan(ticks)
                    ticks = TT.GetEpocsV('StOn',0,0,10^6)';
                end
                DO.epochs = ticks(:,1);
                DO.paramspec = {'onset'};
                
            case {'eFRA','iFRA','tABR','OdBal'}
                freqs = TT.GetEpocsV('Freq',0,0,10^6)';
                if any(protocol == [20 25]) % Roch legacy tanks
                    levls = TT.GetEpocsV('stdb',0,0,10^6)';
                    ons   = TT.GetEpocsV('StOn',0,0,10^6)';
                    ons(:,[1 4]) = [];
                    
                    if size(ons,1) > size(levls,1)
                        ons(size(levls,1)+1:end,:) = [];
                        warning('Protocol had to be truncated!') %#ok<WNTAG>
                    end
                else
                    %                 freqs = TT.GetEpocsV('Stim',0,0,10^6)';
                    levls = TT.GetEpocsV('Levl',0,0,10^6)';
                    if isnan(freqs)
                        ons = 0;
                    else
                        ons = freqs(:,2:3);
                    end
                end
                
                if isnan(freqs(1)), fprintf('*no params*\n'); continue; end
                
                DO.epochs(:,1)   = freqs(:,1);
                DO.epochs(:,2)   = levls(:,1);
                DO.epochs(:,3:4) = ons;
                DO.paramspec     = {'freq','levl','onset','ofset'};
                
            case 'RLF'
                HPfc   = TT.GetEpocsV('HPfc',0,0,10^6);
                LPfc   = TT.GetEpocsV('LPfc',0,0,10^6);
                levls  = TT.GetEpocsV('Levl',0,0,10^6);
                
                DO.epochs(:,1)   = levls(1,:);
                DO.epochs(:,2)   = HPfc(1,:)';
                DO.epochs(:,3)   = LPfc(1,:)';
                DO.epochs(:,4:5) = levls(2:3,:)';
                DO.paramspec     = {'levl','hpfc','lpfc','onset','ofset'};
                
            case 'TMF'
                freqs = TT.GetEpocsV('Freq',0,0,10^6)';
                levls = TT.GetEpocsV('Levl',0,0,10^6)';
                %             TThi  = TT.GetEpocsV('TThi',0,0,1);
                %             TTlo  = TT.GetEpocsV('TTLo',0,0,10^6);
                CurN  = TT.GetEpocsV('CurN',0,0,10^6)';
                
                mC = max(CurN(:,1));
                k = 1;
                for i = 1:size(CurN,1)
                    if i > 1 && CurN(i,1) > CurN(i-1,1), k = k + 1; end
                    if CurN(i,1) == mC
                        r = round(1 / (CurN(i+1,2)-CurN(i,2)));
                    end
                    rate(i,1) = r; %#ok<AGROW>
                    DO.epochs(i,5) = str2double(sprintf('%d.%g',k,CurN(i,1)));
                end
                DO.epochs(:,1) = levls(:,1);
                
                if isnan(freqs)
                    DO.epochs(:,2) = 0;
                else
                    DO.epochs(:,2) = freqs(:,1);
                end
                
                DO.epochs(:,3) = CurN(:,2);
                DO.epochs(:,4) = rate;
                DO.paramspec = {'levl','freq','onset','rate','idx'};
                
                
                
                %             TTlo(1,:) = TTlo(1,:) + TThi(1);
                %             TTlo(:,levls(1,:)==-100) = -1000;
                
                %             DO.epochs(:,1) = freqs(1,:)'; %#ok<AGROW>
                %             DO.epochs(:,2) = levls(1,:)'; %#ok<AGROW>
                %             DO.epochs(:,3) = freqs(2,:)'; %#ok<AGROW>
                %             DO.epochs(:,4) = freqs(2,:)' + TThi(1);
                %             DO.epochs(:,5) = round((1 ./ (TTlo(1,:)' ./ 1000))*10000)./10000;
                %             k = 1; % pretty hackey... there's probably a better way to do this
                %             for i = 1:size(CurN,2)
                %                 if i > 1 && CurN(1,i) > CurN(1,i-1)
                %                     k = k + 1;
                %                 end
                %                 DO.epochs(i,6) = str2double(sprintf('%d.%g',k,CurN(1,i)));
                %             end
                %             DO.epochs(find(isinf(DO.epochs))) = 0; %#ok<FNDSB>
                %             DO.paramspec   = {'freq','levl','onset','ofset','rate','idx'};
                
            case 'FEA' % FEP *********** needs to be updated in RPvds and here ******
                ticks  = TT.GetEpocsV('Tick',0,0,10^6)';
                DO.epochs = ticks(:,2);
                DO.paramspec = {'onset'};
                
            case 'FNB' % Flash/NB
                t = TT.GetEpocsV('Levl',0,0,10^6)';
                DO.epochs(:,1) = t(:,2);
                DO.epochs(:,2) = t(:,1);
                t = TT.GetEpocsV('SOAm',0,0,10^6)';
                DO.epochs(:,3) = t(:,1);
                
                DO.paramspec = {'onset','Levl','SOAm'};
                
            case 'Gaps' % Gaps (from Walton's protocol)
                GapD = TT.GetEpocsV('GapD',0,0,10^6)';
                sn   = TT.GetEpocsV('BGsn',0,0,10^6)';
                stdb = TT.GetEpocsV('stdb',0,0,10^6)';
                nbdr = TT.GetEpocsV('NBdr',0,0,1);
                nbdrs = num2str(nbdr(1));
                x = find(nbdrs~='0',1,'last')-1;
                nb1d = str2double(nbdrs(1:x-1))   / 1000;
                nb2d = str2double(nbdrs(x+1:end)) / 1000;
                
                
                DO.epochs(:,1) = GapD(:,1) / 1000;
                DO.epochs(:,2) = GapD(:,2);
                DO.epochs(:,3) = sn(:,1);
                DO.epochs(:,4) = stdb(:,1);
                DO.epochs(:,5) = nb1d;
                DO.epochs(:,6) = nb2d;
                DO.epochs(:,7) = nb1d + nb2d + DO.epochs(:,1) + DO.epochs(:,2);
                
                DO.paramspec = {'dur','onset','sn','levl','nb1','nb2','ofset'};
                
            case 'STRF';
                ticks = TT.GetEpocsV('TSig',0,0,10^6)';
                DO.paramspec = {'timesig'};
                if isnan(ticks)
                    DO.epochs = 'NO_TIMING_SIGNAL';
                else
                    DO.epochs = ticks(:,2);
                end
        end
    end
    
    dataout(bidx) = DO; %#ok<AGROW>
    clear DO
    
    if ~cfg.silently, fprintf('done\n'); end
end % bidx

function [dataout,cfg] = get_spikes(TT,cfg,blocklist) %#ok<DEFNU>
TT.SetGlobalV('WavesMemLimit',10^8);

nblocks = length(blocklist);
for bidx = 1:nblocks
    TT.ResetFilters;
    if ~cfg.silently, fprintf('\nGrabbing Spikes from %s...',blocklist{bidx}); end

    if ~TT.SelectBlock(blocklist{bidx})
        error(['Unable to select block: ', blocklist{bidx}]);
    end

    TT.CreateEpocIndexing;

    if ~isfield(cfg,'channel') || isempty(cfg.channel) || strcmpi(cfg.channel,'all')
        n = TT.ReadEventsV(10^6,'Snip',0,0,0,0,'NODATA');
        if ~n
            n = TT.ReadEventsV(10^6,'Spik',0,0,0,0,'NODATA');
        end
        cfg.channel = unique(TT.ParseEvInfoV(0,n,4));
    end

    for cidx = 1:length(cfg.channel)
        if ~cfg.silently, fprintf('\n\tChannel: %d\t(%d of %d) ',cfg.channel(cidx),cidx,length(cfg.channel)); end

        nSnips = TT.ReadEventsV(10^6,'Snip',cfg.channel(cidx),0,0,0,'ALL');
        if ~nSnips
            nSnips = TT.ReadEventsV(10^6,'Spik',cfg.channel(cidx),0,0,0,'ALL');
        end

        dataout(cidx).totalspikes = 0; %#ok<AGROW>

        dataout(cidx).blockspikes(bidx) = nSnips; %#ok<AGROW>
        dataout(cidx).channel = cfg.channel(cidx); %#ok<AGROW>

        % GRAB SPIKES FROM BLOCKS

        if ~cfg.silently, fprintf('# spikes = %d',nSnips); end

        if nSnips > 1
            dataout(cidx).timestamps{bidx} = TT.ParseEvInfoV(0,nSnips,6)'; %#ok<AGROW>
            dataout(cidx).waveforms{bidx}  = TT.ParseEvV(0,nSnips)'; %#ok<AGROW>
        else
            dataout(cidx).timestamps{bidx} = []; %#ok<AGROW>
            dataout(cidx).waveforms{bidx}  = []; %#ok<AGROW>
        end

        dataout(cidx).totalspikes = dataout(cidx).totalspikes + nSnips; %#ok<AGROW>

    end % cidx

    cfg.fsample(bidx) = TT.ParseEvInfoV(0,1,9);
end % bidx
cfg.tankcreation = TT.FancyTime(TT.CurBlockStartTime,'Y-O-D');

if ~cfg.silently, fprintf('\n'); end

function [dataout,cfg] = get_waves(TT,cfg,blocklist) 
TT.SetGlobalV('WavesMemLimit',10^9);

if ~isfield(cfg,'event') || isempty(cfg.event)
    cfg.event = 'Wave';
end

for bidx = 1:length(blocklist)
    TT.ResetFilters;
    if ~cfg.silently, fprintf('\nGrabbing Data from %s...',blocklist{bidx}); end

    if ~TT.SelectBlock(blocklist{bidx})
        error(['Unable to select block: ', blocklist{bidx}]);
    end

    TT.CreateEpocIndexing;

    if strcmpi(cfg.channel,'all') || all(isnan(cfg.channel))
        n = TT.ReadEventsV(256,cfg.event,0,0,0,0,'NODATA');
        cfg.channel = unique(TT.ParseEvInfoV(0,n,4));
    end

    for cidx = 1:length(cfg.channel)
        if ~cfg.silently, fprintf('\n\tChannel: %d\t(%d of %d) ',cfg.channel(cidx),cidx,length(cfg.channel)); end

        TT.SetGlobals(sprintf('Channel=%d',cfg.channel(cidx)));
        DO.waves(:,cidx) = TT.ReadWavesV(cfg.event);
        if (any(isnan(DO.waves(:,cidx))) || all(DO.waves(:,cidx) == 0)) && ~cfg.silently
            fprintf(' ... no data')
        end
    end % cidx

    ind = logical(all(DO.waves==0));
    DO.channels = cfg.channel(~ind);
    DO.waves(:,ind) = [];

    if any(ind) && ~cfg.silently
        fprintf('\n%d channels had no activity, so there were really %d channels',sum(ind),length(DO.channels));
    end

    cfg.fsample(bidx) = TT.ParseEvInfoV(0,1,9);

    dataout(bidx) = DO; %#ok<AGROW>
    clear DO
end % bidx

cfg.tankcreation = TT.FancyTime(TT.CurBlockStartTime,'Y-O-D');

if ~cfg.silently, fprintf('\n'); end

function [dataout,cfg] = get_stream(TT,cfg,blocklist) %#ok<DEFNU>
% cfg.event = 'Strm';
cfg.event = 'STRM'; % ad hoc
[dataout,cfg] = get_waves(TT,cfg,blocklist);





