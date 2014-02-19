classdef Arduino
    % A = Arduino(comPort)
    %
    % Connects Matlab with Arduino module.  Designed for Arduino Duemilanove,
    % but should work with any module running the MatlabCOM() function.
    %
    % ex: A = Arduino('COM5');
    %
    % Daniel.Stolzberg@gmail.com 2014
    
    properties (GetAccess = 'public', SetAccess = 'immutable')
        Serial          % Serial connection object
        
    end
    
    properties (GetAccess = 'public', SetAccess = 'public')
        comPort         % Communication port (string)
        QueryStates = false;  % Reads current values from analog and digital pins
        % Downside if true is that it takes a few
        % seconds to query states of all pins
        AnalogRange = [0 1023]; % adjust analog signal within range
        AnalogCal   = [];    % 'p' vector returned from call to polyfit
        AnalogOpt   = 'Range';  %'Range' or 'Cal' or 'None'
    end
    
    properties (GetAccess = 'public', SetAccess = 'protected', Dependent = true)
        Analog
        Digital
    end
    
    properties (Constant = true)
        C_AnalogRange = [0 1023];
        C_AnalogAddr  = 0:5;
        C_DigitalAddr = 2:13; % pins 0/1 used for TX/RX
        
    end
    
    methods
        function obj = Arduino(comPort)
            obj.comPort = comPort;
            obj.Serial = serial(comPort);
            set(obj.Serial,'DataBits',8,'StopBits',1,'BaudRate',9600, ...
                'Parity','none','TimeOut',2,'Name',sprintf('Arduino-%s',comPort), ...
                'Tag','Arduino');
            
            fopen(obj.Serial);  % connects to Arduino
            Handshake(obj,20);
            fscanf(obj.Serial,'%u');
            disp('Connection to Arduino has been established')
        end
        
        function obj = delete(obj)
            if ~isempty(instrfind(obj.Serial))
                fclose(obj.Serial);
                delete(instrfind(obj.Serial));
            end
            obj = [];
            disp('Connection to Arduino has been closed');
            
        end
        
        function val = readAnalogPin(obj,pin)
            narginchk(2,2);
            assert(isscalar(pin) & pin >= 0,'Analog pin must be a scalar value >= 0');
            val = GetVal(obj,sprintf('RA:%d',pin));
            val = AnalogDispatch(obj,val);
        end
        
        function val = readDigitalPin(obj,pin)
            narginchk(2,2);
            assert(isscalar(pin) & pin >= 0,'Digital pin must be a scalar value >= 0');
            val = GetVal(obj,sprintf('RD:%0.0f',pin));
        end
        
%         function PinMode(obj,pin,mode)
%             narginchk(3,3);
%             assert(isscalar(pin)  & pin >= 0,'Digital pin must be a scalar value >= 0');
%             assert(isscalar(mode) & mode >= 1 & mode <= 3,'Pin Mode must be 1 (INPUT), 2 (OUTPUT), or 3 (INPUT_PULLUP)');
%             fprintf(obj.Serial,sprintf('PM:%0.0f:%0.0f',pin,mode));
%         end
        
        function SendMessage(obj,message)
            narginchk(2,2);
            Flush(obj);
            fprintf(obj.Serial,message);
            Handshake(obj,1);
        end
        
        
        % Set functions
        function obj = set.AnalogRange(obj,map)
            assert(numel(map)==2,'AnalogRange must have 2 scalar values (ex: Arduino.AnalogRange = [0 1])');
            obj.AnalogRange = map;
        end
        
        
        
        % Get functions
        function val = get.Analog(obj)
            if ~obj.QueryStates, val = []; return; end
            for i = 1:length(obj.C_AnalogAddr)
                val(i) = GetVal(obj,sprintf('RA:%d',obj.C_AnalogAddr(i))); %#ok<AGROW>
            end
            val = AnalogDispatch(obj,val);
        end
        
        function val = get.Digital(obj)
            if ~obj.QueryStates, val = []; return; end
            for i = 1:length(obj.C_DigitalAddr)
                val(i) = readDigitalPin(obj,obj.C_DigitalAddr(i)); %#ok<AGROW>
            end
        end
        
        function Flush(obj)
            if obj.Serial.BytesAvailable == 0, return; end
            fread(obj.Serial,obj.Serial.BytesAvailable,'uchar');
        end
        
        function val = GetVal(obj,str)
            narginchk(2,2);
            SendMessage(obj,str);
            pause(0.05);
            c = fread(obj.Serial,obj.Serial.BytesAvailable-1 ,'uchar');
            val = str2double(char(c'));
            Flush(obj);
        end
        
    end
    

    methods(Access = 'private')

        function val = AnalogDispatch(obj,val)
            switch upper(obj.AnalogOpt)
                case 'RANGE'
                    val = AnalogMap(obj,val);
                    
                case 'CAL'
                    val = Calibrate(obj,val);
                    
                otherwise
                    
            end
        end
        
        
        function Handshake(obj,timeout)
            start_time = clock;
            a = 'b';
            while (a ~= 'a')
                if etime(clock,start_time) > timeout
                    error('Unable to communicate with Arduino.')
                end
                a = fread(obj.Serial,1,'uchar');
            end
            fprintf(obj.Serial, '%c', 'a');
        end
 
        function cval = Calibrate(obj,val,cal)
            % Calculate calibrated value from a calibration curve, cal.
            if nargin == 2 || isempty(cal)
                if ~isempty(obj.AnalogCal)
                    cal = obj.AnalogCal;
                else
                    error('Calibration structure required');
                end
            end
            
            cval = polyval(cal,val);
        end
        
        function mapped = AnalogMap(obj,val,arange)
            % Maps values from Arduino analog range ([0 1023]) to any other
            % range.  val can be a scalar or array.  If specified, arange must
            % be a 2 scalar array.
            %
            % If not specified (or empty), the default value for arange will
            % be the AnalogRange property.
            %    To update: Arduino.AnalogRange = [0 1]
            
            narginchk(2,3);
            if nargin == 2 || isempty(arange), arange = obj.AnalogRange; end
            assert(numel(arange)==2,'arange must have 2 scalar values (ex: arange = [0 1])');
            
            in_min = min(arange);
            in_max = max(arange);
            out_min = min(obj.C_AnalogRange);
            out_max = max(obj.C_AnalogRange);
            
            mapped = (val - in_min) .* (out_max - out_min) ./ (in_max - in_min) + out_min;
        end
    end
    
end


