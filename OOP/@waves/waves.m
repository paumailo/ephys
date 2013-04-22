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
        
        % @methods
        obj = update(obj);
        data = eventrel(obj,win);
        obj = deline(obj);
        ft = fieldtrip(obj);
        
    end   
    
end