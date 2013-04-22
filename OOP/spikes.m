classdef spikes < tank
    % Spike data type working off of TDT data tank
    % S = spikes(TANKNAME)
    % S = spikes(TANKNAME,BLOCKNUMBER)
    % S = spikes(TANKNAME,BLOCKNUMBER,EVENTNAME)
    %
    % ex:   S = spikes('ROCKSTAR_V_T_A') % open tank 'ROCKSTAR_V_T_A'
    %       S.blocklist  % get a list of available blocks
    %       S.block = 4; % change block to 4
    %       S.block = 'ROCKSTAR_V_T_A-2'; % Alternative method to change block
    %       S.eventname = 'eNeu'; % change event name; required to retrieve spike data
    %       S.sortname = 'OfflineSort'; % retrieve sortcodes from OpenSorter
    %       S.unitstr   % list of available units
    %
    %       S.get_waveforms = true; % Set to true to retrieve spike waveforms
    %
    % methodsview(S) will get you a list of methods and their parameters.
    %
    % In order to clear a spikes object, use:
    %       delete(S); clear S
    %
    % Inherits TANK class
    %
    % See also, tank, waves
    
    % DJS 2013

    properties (SetAccess = 'public',GetAccess = 'public')
        eventname               % Eventname (eg, 'Snip' or 'eNeu')
        sortname                % Sortname (if using OpenSorter)
        get_waveforms = false;  % Toggle whether or not spike waveforms are collected on updates
    end
    
    properties (SetAccess = 'private',GetAccess = 'public')
        Fs                  % Sampling frequency (Hz)
        channels            % Channel list
        sortcodes           % Sort codes
        units               % Unit ids
        timestamps          % Spike timestamps from block onset        
        waveforms           % Spike waveforms
        unitstr             % Modifiable unit string identifier        
        count               % Spike count total
    end
    
    
    methods
        
        % class constructor
        function obj = spikes(name,block,eventname)
            if nargin >= 1, obj.name = name;            end
            if nargin >= 2, obj.block = block;          end
            if nargin == 3, obj.eventname = eventname;  end            
        end
        
        
        % update
        function obj = update(obj)
            if isempty(obj.block)
                fprintf('update:Must first set a block number (ex: S.block = 3)\n')
                return
            end
            if isempty(obj.eventname)
%                 fprintf('update:Must fist specify eventname (ex: S.eventname = ''Snip'')\n')
                return
            end
            obj = checkTT(obj);
            fprintf('Retrieving data ...')
            obj.TT.CreateEpocIndexing;
            
            if ~isempty(obj.sortname)
                obj.TT.SetUseSortName(obj.sortname);
            end
            
            obj.count = obj.TT.ReadEventsV(1e7,obj.eventname,0,0,0,0,'ALL');
            obj.channels   = obj.TT.ParseEvInfoV(0,obj.count,4)';
            obj.sortcodes  = obj.TT.ParseEvInfoV(0,obj.count,5)';
            obj.timestamps = obj.TT.ParseEvInfoV(0,obj.count,6)';
            obj.Fs         = obj.TT.ParseEvInfoV(0,1,9);

            if obj.get_waveforms
                obj.waveforms = obj.TT.ParseEvV(0,obj.count)';
            else
                obj.waveforms = [];
            end
            
            cs  = [obj.channels obj.sortcodes];
            ucs = unique(cs,'rows');
            
            obj.units   = nan(size(cs,1),1);
            obj.unitstr = cell(size(ucs,1),1);
            for i = 1:size(ucs,1)
                ind = cs(:,1) == ucs(i,1) & cs(:,2) == ucs(i,2);
                obj.units(ind) = i;
                obj.unitstr{i} = sprintf('ch%03.0f_u%02.0f',ucs(i,:));
            end
            
            fprintf(' done\n')
        end
        
        % select unit timestamps
        function ts = unit_timestamps(obj,unitid)
            % Returns timestamps of one or multiple units of the current
            % block.  If one unit is passed in then an Nx1 vector of the
            % unit's time stamps (relative to recording onset) is returned.
            %  If an array of units are passed in, then a cell array of Nx1
            %  vector of unit timestamps are returned.  If unitid == 0,
            %  then all units of the current block will be returned in a
            %  cell array.
            
                       
            if length(unitid) == 1 && unitid == 0
                unitid = unique(obj.units);
            end
            
            if length(unitid) == 1
                ind = subset(obj,unitid);
                ts = obj.timestamps(ind);
            elseif length(unitid) > 1
                ts = cell(length(unitid),1);
                for i = 1:length(unitid)
                    ind = subset(obj,unitid(i));
                    ts{i,1} = obj.timestamps(ind);
                end
            end
        end
        
        
        %% Set/Get functions ----------------------------------------------

        % Set eventname
        function obj = set.eventname(obj,name)
            obj.eventname = name;
            obj = update(obj);
        end
        
        % Set sortname
        function obj = set.sortname(obj,name)
            obj.sortname = name;
            obj = update(obj);
        end
        
        % Set get_waveforms
        function obj = set.get_waveforms(obj,tf)
            obj.get_waveforms = tf;
            if tf, obj = update(obj); end                
        end
        
       
        
        
        
        
        
        
        %% Plotting functions ---------------------------------------------
        % plot spike waveforms
        function varargout = plot_waveforms(obj,varargin)
%           plot_waveforms(unitid)
%           plot_waveforms(unitid,style)
%           plot_waveforms(ax,...)
%           h = plot_waveforms(...)

            style  = 'density'; % default
            ax = gca;
            
            switch length(varargin)
                case 1
                    unitid = varargin{1};
                case 2
                    if ischar(varargin{end})
                        unitid = varargin{1};
                        style  = varargin{2};
                    else
                        ax     = varargin{1};
                        unitid = varargin{2}; 
                    end
                case 3
                    ax     = varargin{1};
                    unitid = varargin{2};
                    style  = varargin{3};
                otherwise
                    error('plot_waveforms:This function requires 2 or 3 inputs')                    
            end
            
            uind = subset(obj,unitid);
            W = obj.waveforms(uind,:);
            if isempty(W)
                fprintf('No waveforms found for unit %d\n',unitid)
                varargout{1} = [];
                return
            end
            W = W * 1000; % V -> mV
            
            svec = 1:size(obj.waveforms,2);
            
            if isnumeric(unitid)
                unitid = obj.unitstr{unitid};
            end
            titlestr = sprintf('%s (%0.0f)',unitid,sum(uind));
            
            cla(ax,'reset');
            
            switch lower(style)
                case 'mean'
                    mw = mean(W);
                    sw = std(W);
                    hold(ax,'on');
                    h(1) = plot(ax,svec,mw+sw,'-k','linewidth',1);
                    h(2) = plot(ax,svec,mw,'-k','linewidth',2);
                    h(3) = plot(ax,svec,mw-sw,'-k','linewidth',1);
                    hold(ax,'off');
                    grid on
                    y = max(abs(ylim(ax)));
                    axis(ax,[svec(1) svec(end) -y y]);
                    
                case 'banded'
                    mw = mean(W);
                    sw = std(W);
                    bw = [mw+sw, fliplr(mw-sw)];
                    sv = [svec,  fliplr(svec)];
                    h = fill(sv,bw,'b','EdgeColor','b');
                    grid on
                    y = max(abs(ylim(ax)));
                    axis(ax,[svec(1) svec(end) -y y]);
                    
                case 'density'
                    y = max(abs(W(:)))*0.75;
                    y = linspace(-y,y,2*size(W,2));
                    bcnt = histc(W,y);
                    bcnt = bcnt ./ max(bcnt(:));
                    bcnt = interp2(bcnt,3,'cubic');
                    h = imagesc(svec,y,bcnt);
                    set(ax,'ydir','normal','clim',[0 1]);
                    box(ax,'on');
                    
                case 'sampling'
                    ridx = randperm(size(W,1));
                    h = plot(svec,W(ridx(1:round(length(ridx)*0.1)),:));
                    grid on
                    y = max(abs(ylim(ax)));
                    axis(ax,[svec(1) svec(end) -y y]);
                    
                otherwise
                    error('plot_wavforms:Undefined plot style ''%s''',style)
            end
            
            ylabel(ax,'Amplitude (mV)');
            xlabel(ax,'Samples');
            title(ax,titlestr,'interpreter','none');
            
            varargout{1} = h;
        end
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        %% Computations ---------------------------------------------------
        function varargout = isi(obj,unitid,varargin)
            % H = isi(unitid)
            % H = isi(unitid)
            % H = isi(unitid,N)
            % H = isi(unitid,N,bins)
            % [H,bins] = isi(...)
            %
            % Compute interspike interval on a unit (or units)
            
            N = 1;
            bins = 0:0.001:0.1;
            
            if length(varargin) >= 1, N = varargin{1};      end
            if length(varargin) == 2, bins = varargin{2};   end
            
            ts = unit_timestamps(obj,unitid);
            if ~iscell(ts), ts = {ts}; end
            
            cbins = repmat({bins},size(ts));
            N     = repmat({N},size(ts));
            
            dts = cellfun(@diff,ts,N,'UniformOutput',false);
            H   = cellfun(@histc,dts,cbins,'UniformOutput',false);
            % keep convention of rows are observations and colums are samples
            H   = cell2mat(H')'; 
            
            varargout{1} = H;
            varargout{2} = bins;
            
            
        end
      
        
        % compute raster
        function [raster,pars] = comp_raster(obj,unitid,parid,win)
            % [raster,pars] = comp_raster(unitid,parid,win)
            % 
            % Computes rasters for each stimulus presentation based on
            % whatever number of parameters (PARID) is specified. WIN is
            % the onset and offset window around the stimulus onset (eg,
            % [-0.01 0.2]).
            
            if nargin < 4 || length(win) ~= 2
                error('comp_raster:The win input must be specified as a 2 value matrix')
            end
            
            ts = unit_timestamps(obj,unitid);
            ons = obj.params(parid(1)).vals(:,2);
            ofs = obj.params(parid(1)).vals(:,2) + win(2);
            irast = cell(length(ons),1);
            for i = 1:length(ons)
                irast{i} = ts(ts >= ons(i) + win(1) & ts < ofs(i))-ons(i);
            end
            
            vals = [obj.params(parid).vals];
            vals = vals(:,1:4:end);
            nvals = size(vals,1);
            
            p = obj.permutepars(parid);
            raster = cell(size(p,1),1);
            k = 1;
            for i = 1:size(p,1)
                ind = all(vals == repmat(p(i,:),nvals,1),2);
                raster{k} = irast(ind);
                k = k + 1;
            end
            pars = p;
            
%             validpars = ~cellfun(@isempty,raster,'uniformoutput',true);
%             raster = raster(validpars);
%             pars = p(validpars,:);
        end
        
        
        % compute receptive field
        function [rfld,pars] = comp_receptivefld(obj,unitid,parid,win)
            if length(parid) ~= 2
                error('comp_receptivefld:Must include 2 parameter ids')
            end
            
            [raster,rpars] = comp_raster(obj,unitid,parid,win);
            
            c = cellfun(@cell2mat,raster,'UniformOutput',false);
            c = cellfun(@length,c,'UniformOutput',true);
            
            upars1 = unique(rpars(:,1));
            upars2 = unique(rpars(:,2));
            
            rfld = reshape(c,length(upars1),length(upars2));
            pars = {upars1, upars2};
        end
        
            
            
            
            
            
            
        
        
        %% Helper functions -----------------------------------------------
        function ind = subset(obj,ids)
            % Returns logical indexes in an array pointing to a subset of
            % data.
            %
            % Can enter one or multiple unit ids (in an array) or unit
            % strings (in a cell array) which will search on unitstr field.
            %
            % Alternatively, the channel number and sortcode can be passed
            % in as two parameters.  eg, ind = subset(3,2); would return
            % logical indexing of unit 2 on channel 3.
            
            if ischar(ids), ids = cellstr(ids); end
            
            if length(ids) == 1 && iscellstr(ids)
                ids = find(ismember(obj.unitstr,ids));
            end
            
            if length(ids) == 1
                ind = obj.units == ids(1);
            elseif length(ids) == 2
                ind = obj.channels == ids(2) & obj.sortcode == ids(2);
            end
        end
        
        
        
        %% Formatting functions -------------------------------------------
        function ft = fieldtrip(obj)
            % ft = fieldtrip
            % Export current block data for FieldTrip toolbox
            
            cfg = [];
            cfg.tank     = obj.name;
            cfg.block    = obj.currentblock;
            cfg.event    = obj.eventname;
            cfg.sortname = obj.sortname;
            ft = ft_read_spikes_tdt(cfg);
        end
        
        
    end
        
end










