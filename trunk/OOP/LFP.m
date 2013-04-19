classdef LFP < tank
    % LFP data type working off of TDT data tank
    % D = LFP(TANKNAME)
    % D = LFP(TANKNAME,BLOCKNUMBER)
    % D = LFP(TANKNAME,BLOCKNUMBER,EVENTNAME)
    %
    % Tank name, block number, and event name must be specified before
    % retrieving data using D = D.update;
    %
    % Inherits TANK class
    
    % DJS 2013

    properties (SetAccess = 'public',GetAccess = 'public')
        eventname               % Eventname (eg, 'Snip' or 'eNeu')
    end
    
    properties (SetAccess = 'private',GetAccess = 'public')
        Fs                  % Sampling frequency (Hz)
        channels            % Channel list
        data                % LFP continuously sampled data
    end

    
    
end