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
        
        
        % @methods
        obj             = update(obj);
        varargout       = plot_waveforms(obj,varargin);
        h               = plot_raster(obj,ax,unitid,parid,parval,win);
        h               = plot_hist(obj,ax,unitid,parid,parval,binvec);
        h               = plot_spikedensity(obj,ax,unitid,parid,parval,win,varargin)
        [h,pars]        = comp_isi(obj,unitid,varargin);
        [raster,pars]   = comp_raster(obj,ax,unitid,parid,parval,win);
        [rfld,pars]     = comp_receptivefld(obj,ax,unitid,parid,parval,win);
        [H,pars]        = comp_hist(obj,unitid,parid,parval,binvec);
        ind             = subset(obj,ids);
        ts              = unit_timestamps(obj,unitid);
        ft              = fieldtrip(obj);
        
    end
        
end










