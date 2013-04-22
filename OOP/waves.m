classdef waves < tank
    % waves class
    % W = waves(TANKNAME)
    % W = waves(TANKNAME,BLOCKNUMBER)
    % W = waves(TANKNAME,BLOCKNUMBER,EVENTNAME)
    %
    % ex:   W = waves('ROCKSTAR_V_T_A') % open tank 'ROCKSTAR_V_T_A'
    %       W.blocklist  % get a list of available blocks
    %       W.block = 4; % change block to 4
    %       W.block = 'ROCKSTAR_V_T_A-2'; % Alternative method to change block
    %       W.downFs = 610; % set new sampling rate
    %       W = update(W); % downsample to w.downFs
    %       W = deline(W); % remove 60 Hz line noise
    %     
    %       % Get event-related potentials 
    %       evokedW = eventrel(W,[0 0.25]); % samples X channels X events
    %
    %       % close Tank server connection and clear object from workspace
    %       delete(W); clear W
    %       
    % methodsview(W) will get you a list of methods and their parameters.
    % 
    % Inherits TANK class
    %
    % See also, tank, spikes
    
    % DJS 2013

    properties (SetAccess = 'public',GetAccess = 'public')
        eventname = 'Wave'; % Eventname (eg, 'Wave')
        downFs    = 1000;   % Downsample sampling rate 
    end
    
    properties (SetAccess = 'private',GetAccess = 'public')
        Fs                  % Sampling frequency (Hz)
        tankFs              % Original sampling frequency
        channels            % Channel list
        data                % Continuously sampled data
        time                % Time vector
    end

    
    
    
    methods
       
        % clas constructor
        function obj = waves(name,block,eventname)
            if nargin >= 1, obj.name = name;            end
            if nargin >= 2, obj.block = block;          end
            if nargin == 3, obj.eventname = eventname;  end            
        end
        
        % Set eventname
        function obj = set.eventname(obj,name)
            obj.eventname = name;
            obj = update(obj);
        end
        
        
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
            if obj.verbose, fprintf('Retrieving data ...'); end
            obj.TT.CreateEpocIndexing;
            
            obj.TT.SetGlobalV('WavesMemLimit',10^9);

            n = obj.TT.ReadEventsV(2^9,obj.eventname,0,0,0,0,'NODATA');
            obj.channels = unique(obj.TT.ParseEvInfoV(0,n,4))';
            obj.Fs       = obj.TT.ParseEvInfoV(0,1,9);
            obj.tankFs   = obj.Fs;
            
            if obj.downFs < obj.Fs
                sstep = round(obj.Fs/obj.downFs);
                if sstep > 1
                    % convert sampling rate
                    obj.downFs = obj.Fs/sstep;
                    fprintf('\nDownsampling by a factor of %d from %0.2f Hz to %0.2f Hz', ...
                        sstep,obj.Fs,obj.downFs)
                    obj.TT.SetGlobals(sprintf('WaveSF=%0.6f',obj.downFs));
                    obj.Fs = obj.downFs;
                end
            end
            
            obj.data = [];
            for i = 1:length(obj.channels)
                if obj.verbose, fprintf('\n\tChannel: %d\t(%d of %d) ', ...
                    obj.channels(i),i,length(obj.channels)); 
                end
                
                obj.TT.SetGlobals(sprintf('Channel=%d',obj.channels(i)));
                w = obj.TT.ReadWavesV(obj.eventname);             
                if (any(isnan(w)) || all(w == 0)) && obj.verbose
                    fprintf(' ... no data')
                end
                obj.data(:,i) = w;
            end
            clear w
            
            if obj.Fs ~= obj.tankFs
                % run anti-aliasing filter if there was a downsampling
                nyquist = obj.Fs/2;
                lppb    = nyquist * 0.90;
                [z,p,k] = butter(6,lppb/nyquist,'low');
                [sos,~] = zp2sos(z,p,k);
                obj.data = single(sosfilt(sos,double(obj.data)));
            end
            
            obj.time = (0:1/obj.Fs:(size(obj.data,1)-1)/obj.Fs)';
            
            fprintf('\ndone\n')
        end
        
        



        
        
        %% Computations ---------------------------------------------------
        function data = eventrel(obj,win)
            % data = eventrel(win)
            % Organize continuous waves into event-related trials
            %
            % dim order of output matrix: samples X channels X trials
            
            swin = round(win*obj.Fs);
            svec = 0:diff(swin);
            onst = ceil(obj.params(1).vals(:,2)*obj.Fs+swin(1));
            
            if any(onst <= 0)
                error('eventrel:%d window onsets occur before the first sample of the recording', ...
                    sum(onst<=0));
            end
            
            data = zeros(length(svec),size(obj.data,2),length(onst));
            for i = 1:length(onst)
                data(:,:,i) = obj.data(onst(i)+svec,:);
            end
        end
        
        
        
        
        
        
        
        function obj = deline(obj)
            for i = 1:size(obj.data,2)
                fprintf('Removing 60Hz line noise on channel %d of %d ...',i,size(obj.data,2))
                obj.data(:,i) = chunkwiseDeline(obj.data(:,i),obj.Fs,[60 180],2,60,false);
                fprintf(' done\n')
            end
        end
        
        
        
        
        
        
        
        
        %% Formatting functions -------------------------------------------
        function ft = fieldtrip(obj)
            % ft = fieldtrip
            % Export current block data for FieldTrip toolbox
            
            cfg = [];
            cfg.tank  = obj.name;
            cfg.block = obj.currentblock;
            cfg.event = obj.eventname;
            ft = ft_read_lfp_tdt(cfg.tank,cfg.block);
        end
        
    end   
    
end