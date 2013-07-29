function PLX2TDT(plxfilename)


% defaults are modifiable using varargin parameter, value pairs
SERVER        = 'Local';
BLOCKROOT     = 'Block';
SORTNAME      = 'Pooled';
SORTCONDITION = 'PlexonOSv2';
EVENT         = [];

% load and reconfigure plexon data
[tscounts, ~, ~, ~] = plx_info(plxfilename,1);

tscounts(:,1) = []; % remove empty channel

[npossunits,nchans] = size(tscounts);

n    = zeros(size(tscounts));
ts   = cell(1,nchans);
unit = cell(1,nchans);
for i = 1:nchans
    fprintf('\n\tChannel %d\n',i)
    for j = 1:npossunits
        if ~tscounts(j,i), continue; end
        [n(j,i),~,t,~] = plx_waves(plxfilename,i,j-1);
        fprintf('\t\tunit %d\t# spikes:% 8d\n',j-1,n(j,i))
        
        ts{i}   = [ts{i}; t];
        unit{i} = [unit{i}; ones(n(j,i),1) * (j-1)];       
    end
    
    [ts{i},sidx] = sort(ts{i});
    unit{i}      = unit{i}(sidx);
end



% parse plxfilename for tank and block info
[~,filename,~] = fileparts(plxfilename);
k = strfind(filename,'blocks');
tank = filename(1:k-2);
bstr = filename(k+6:end);
c = textscan(bstr,'_%d');
blocks = cell2mat(c)';




% establish connection tank
TTXfig = figure('Visible','off','HandleVisibility','off');
TTX = actxcontrol('TTank.X','Parent',TTXfig);

if ~TTX.ConnectServer(SERVER, 'Me')
    error(['Problem connecting to Tank server: ' SERVER])
end

if ~TTX.OpenTank(tank, 'W')
    CloseUp(TTX,TTXfig);
    error(['Problem opening tank: ' tank]);
end



% update Tank with new Plexon sort codes
for b = blocks
    blockname = [BLOCKROOT '-' num2str(b)];
    if ~TTX.SelectBlock(blockname)
        CloseUp(TTX,TTXfig)
        error('Unable to select block ''%s''',blockname)
    end

    d = TDT2mat(tank,blockname,'type',3,'silent',true);
    
    if isempty(EVENT)
        if isempty(d.snips)
            warning('No spiking events found in "%s"',blocks{i})
            continue
        end
        EVENT = fieldnames(d.snips);
        EVENT = EVENT{1};
    end

    d = d.snips.(EVENT);

    channels = unique(d.chan);
    
    fprintf('Updating sort "%s" on %s of %s\n',SORTNAME,blockname,tank)
    
    for ch = channels
        ind = d.chan == ch;
        k = sum(ind);
        
        fprintf('\tChannel %d,\t%d units with% 8d spikes ...', ...
            ch,length(unique(unit{ch}(1:k))),k)
        
        SCA = uint32([d.index(1:k); unit{ch}(1:k)']);
        SCA = SCA(:)';
        
        success = TTX.SaveSortCodes(SORTNAME,EVENT,ch,SORTCONDITION,SCA);
        
        if success
            fprintf(' SUCCESS\n')
        else
            fprintf(' FAILED\n')
        end
        
        d.index(ind)  = [];
        d.chan(ind)   = [];
        unit{ch}(1:k) = [];
        
    end
end


CloseUp(TTX,TTXfig)




function CloseUp(TTX,TTXfig)
TTX.CloseTank;
TTX.ReleaseServer;
close(TTXfig);






