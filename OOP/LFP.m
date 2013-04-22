classdef LFP < tank
    % LFP data type working off of TDT data tank
    % D = LFP(TANKNAME)
    % D = LFP(TANKNAME,BLOCKNUMBER)
    % D = LFP(TANKNAME,BLOCKNUMBER,EVENTNAME)
    %
    % Inherits TANK class
    %
    % See also, tank, spikes
    
    % DJS 2013

    properties (SetAccess = 'public',GetAccess = 'public')
        eventname = 'Wave'; % Eventname (eg, 'Wave')
        downFs    = 1000;   % Downsample sampling rate 
                            %   used if call to D.downsample method
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
        function obj = LFP(name,block,eventname)
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
                obj.TT.SetGlobals(sprintf('WaveSF=%0.6f',obj.downFs));
                obj.Fs = obj.downFs;
            end
            
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
            
            obj.time = (0:1/obj.Fs:size(obj.data,1)/obj.Fs)';
            
            fprintf(' done\n')
        end
        
        function obj = downsample(obj)
            sstep = round(obj.Fs/obj.downFs);
            if sstep <= 1, return; end
            
            % convert sampling rate
            obj.downFs = obj.Fs/sstep;
            fprintf('\nDownsampling from %0.2f Hz to %0.2f Hz ...', ...
                obj.Fs,obj.downFs)
            obj.Fs = obj.downFs;
            
            % run anti-aliasing filter before downsampling
            nyquist = obj.Fs/2;
            lppb    = nyquist * 0.90;
            [z,p,k] = butter(6,lppb/nyquist,'low');
            [sos,~] = zp2sos(z,p,k);
            obj.data = single(sosfilt(sos,double(obj.data)));
            
            % downsample
            obj.data = obj.data(1:sstep:end,:);
            fprintf(' done\n')
        end
        
        %% Formatting functions -------------------------------------------
        function ft = fieldtrip(obj)
            % ft = fieldtrip
            % Export current block data for FieldTrip toolbox
            
            cfg = [];
            cfg.tank     = obj.name;
            cfg.block    = obj.currentblock;
            cfg.event    = obj.eventname;
            ft = ft_read_lfp_tdt(cfg.tank,cfg.block);
        end
        
        
        
        
    end
    
    
    methods(Hidden = true)
        % TANK class abstract methods
        function obj = updateBlock(obj)
            obj = update(obj);
        end
    end
    
    
    
    
end