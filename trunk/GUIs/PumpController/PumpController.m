function varargout = PumpController(varargin)

% Edit the above text to modify the response to help PumpController

% Last Modified by GUIDE v2.5 16-Feb-2014 21:58:02

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @PumpController_OpeningFcn, ...
    'gui_OutputFcn',  @PumpController_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before PumpController is made visible.
function PumpController_OpeningFcn(hObj, ~, h, varargin)
h.output = hObj;

% elevate Matlab.exe process to a high priority in Windows
[~,~] = dos('wmic process where name="MATLAB.exe" CALL setpriority "high priority"');


InitializeStates(hObj)
InitializeVars(hObj)

% Arduino -----------------------------
GUIDispatch(h.mnu_comselect,h);
Settings = getappdata(hObj,'Settings');
A = ConnectArduino(Settings.COM);
setappdata(hObj,'Arduino',A);


ProgramControl(hObj,h,'starttempmon');
PumpMode(h);
GetTempSched(h.tbl_tempsched);

guidata(hObj, h);

% --- Outputs from this function are returned to the command line.
function varargout = PumpController_OutputFcn(~, ~, h)
varargout{1} = h.output;





%
function InitializeStates(f)
States.Record  = 0;
States.TempMon = 0;
States.Pump    = 0;
States.Manual  = 1;
setappdata(f,'States',States);

function InitializeVars(f)
Time.Data = single([]); 
Time.Start = clock;     setappdata(f,'Time',Time);
Temp.Data = single([]); setappdata(f,'Temp',Temp);
Pump.Data = uint8([]);  setappdata(f,'Pump',Pump);




%
function LocateRecordFile(h,filename)
if nargin == 1 || isempty(filename), filename = cd; end

ft = {'csv','mat'};
[filename,pathname,filteridx] = uiputfile({ ...
    '*.csv','Comma Separated Values (*.csv)'; ...
    '*.mat','MAT-file (*.mat)'}, ...
    'Choose Record File',filename);

if ~filename, return; end


set(h.txt_recordfile,'String',filename,'TooltipString',fullfile(pathname,filename));

set(h.btn_recordcontrol,'Enable','on');

File.filename = filename;
File.pathname = pathname;
File.filetype = ft{filteridx};
File.fullfilename = fullfile(File.pathname,File.filename);
setappdata(h.figure1,'File',File);

setappdata(h.figure1,'RecordCommand','record');





function ProgramControl(hObj,h,command)
f = h.figure1;

if nargin < 3 || isempty(command), command = getappdata(f,'RecordCommand'); end

T = timerfind('Name','PumpControllerTimer');

States = getappdata(f,'States');

        
switch command  
    
    case 'starttempmon'
        ResetVars(f);
        
        % Create new timer to control experiment
        if ~isempty(T), stop(T); delete(T); end
        T = timer(                                          ...
            'BusyMode',         'queue',                    ...
            'ExecutionMode',    'fixedDelay',               ...
            'TasksToExecute',   inf,                        ...
            'Name',             'PumpControllerTimer',      ...
            'TimerFcn',         {@PCT_RunTime,f},   ...
            'StartFcn',         {@PCT_Start,f},     ...
            'StopFcn',          {@PCT_Stop,f},      ...
            'ErrorFcn',         {@PCT_Error,f},     ...
            'StartDelay',       1);
        
        Plot = InitPlot(h.ax_temp);
        setappdata(f,'Plot',Plot);
        
        States.TempMon = 1;
        
        start(T);
        
    case 'stoptempmon'
        States.TempMon = 0;
        set(h.lbl_probetemp,'String','--');
        if ~isempty(T), stop(T); end
        
        
    case 'startrecord'
        ResetVars(f);
        File = getappdata(f,'File');
        if isempty(File) || ~isfield(File,'fullfilename') 
            LocateRecordFile(h);
            File = getappdata(f,'File');
            if isempty(File), return; end
        end
        if ~exist(File.fullfilename,'file')
            b = questdlg(sprintf('The file ''%s'' exists.  Would you like to overwrite it?',File.filename),'File Exists', ...
                'Overwrite','Cancel','Cancel');
            if strcmp(b,'Cancel'), return; end
        end
        if strcmp('csv',File.filetype)
            [File.fid,message] = fopen(File.fullfilename,'w');
            setappdata(f,'File',File);
            if File.fid == -1
                set(hObj,'Enable','off');
                errordlg(message);
                return
            end
        end
                
        Time = getappdata(f,'Time');
        Time.Start = clock; 
        setappdata(f,'Time',Time);
        
        Temp = getappdata(f,'Temp');
        Temp.Fs         = 1;
        Temp.SensorPin  = 0;
        setappdata(f,'Temp',Temp);
        
        WriteHeader(File.fid,Time);
        
        set(h.chk_alsostartrecord,'Enable','off');
        set(h.btn_recordcontrol,'String','Stop');
        Plot = InitPlot(h.ax_temp);
        setappdata(f,'Plot',Plot);
        
        States.Record = 1;
        
        
        
        
    case 'stoprecord'
        ResetVars(f);
        States.Record = 0;
        setappdata(f,'States',States);
        File = getappdata(f,'File');
        if strcmp('csv',File.filetype)
            fclose(File.fid);
        else
            Temp = getappdata(f,'Temp'); %#ok<NASGU>
            Pump = getappdata(f,'Pump'); %#ok<NASGU>
            Time = getappdata(f,'Time'); %#ok<NASGU>
            save(File.fullfilename, ...
                'Temp','Pump','Time');
        end
        File.fid = [];
        setappdata(f,'File',File);
        fprintf('Data saved to file: %s\n',File.fullfilename)
        set(h.chk_alsostartrecord,'Enable','on');
        set(hObj,'String','Record');
        Plot = InitPlot(h.ax_temp);
        setappdata(f,'Plot',Plot);
        
        
    case 'startsched'        
        ResetVars(f);
        Time = getappdata(f,'Time');
        Time.Start = clock;
        setappdata(f,'Time',Time);
        
        Temp = getappdata(f,'Temp');
        Temp.Fs         = 1;
        Temp.SensorPin  = 0;
        setappdata(f,'Temp',Temp);
        
        set(h.tbl_tempsched,'Enable','off');
        set(h.btn_schstart,'String','Stop');
        set(h.btn_schpause,'Enable','on');
        Sched = GetTempSched(h.tbl_tempsched);
        D = Sched.Data;
        D{Sched.Index,1} = ['< ' D{Sched.Index,1}];
        set(h.tbl_tempsched,'Data',D);
        setappdata(f,'Sched',Sched);
        
        States.Manual = 0;
        A = getappdata(f,'Arduino');
        A.SendMessage('SetST:1');
        A.SendMessage(sprintf('SetSP:%0.1f',str2double(Sched.Data{1,2})));
        
    case 'stopsched'
        set(h.tbl_tempsched,'Enable','on');
        set(h.btn_schstart,'String','Start');
        set(h.btn_schpause,'Enable','off');
        Sched = getappdata(f,'Sched');
        set(h.tbl_tempsched,'Data',Sched.Data);
        % might be better to have pump maintain last Setpoint
%         A = getappdata(f,'Arduino');
%         A.SendMessage('SetST:0');
        States.Manual = 1;
end
setappdata(f,'States',States);



function GUIDispatch(hObj,h)
f = h.figure1;

States = getappdata(f,'States');

switch get(hObj,'Tag')
    
    case 'btn_recordcontrol'
        if States.Record
            ProgramControl(hObj,h,'stoprecord');
        else
            File = getappdata(f,'File');
            if isempty(File) || ~isfield(File,'filename')
                LocateRecordFile(h);
                File = getappdata(f,'File');
                if isempty(File) || ~isfield(File,'filename'), return; end
            end
            ProgramControl(hObj,h,'startrecord');
        end
        
    case 'btn_schstart'
        if strcmp(get(hObj,'String'),'Start')
            if States.Record == 0 && get(h.chk_alsostartrecord,'Value')
                ProgramControl(hObj,h,'startrecord');
            end
            ProgramControl(hObj,h,'startsched');
            set(hObj,'String','Stop');
        else
            set(hObj,'String','Start');
            ProgramControl(hObj,h,'stopsched');
        end
    case 'btn_schpause'
        
        
        
    case 'btn_locate'
        LocateRecordFile(h);
        
    case 'btn_updatepumpspeed'
        A    = getappdata(f,'Arduino');
        Pump = getappdata(f,'Pump');
        Pump.Speed = str2num(get(h.txt_pumpspeed,'String')); %#ok<ST2NM>
        A.SendMessage('SetST:0');
        A.SendMessage(sprintf('SetPumpRate:%0.0f',Pump.Speed));
        setappdata(f,'Pump',Pump);
        
        
    case 'mnu_comselect'
        Settings = getappdata(f,'Settings');
        ports = scanports;
        if length(ports) > 1
            [COM,ok] = listdlg('ListString',ports, ...
                'SelectionMode','single','Name','COM ports',...
                'PromptString','Select COM port');
            if ~ok, COM = []; end
        else
            COM = ports;
        end
        Settings.COM = ports{COM};
        setappdata(f,'Settings',Settings);
end




function pan_pumpmode_SelectionChangeFcn(hObj, evnt, h) %#ok<INUSL,DEFNU>
PumpMode(h);

function PumpMode(h)
States = getappdata(h.figure1,'States');
States.Manual = get(h.mode_manual,'Value');
Pump = getappdata(h.figure1,'Pump');
if States.Manual
    Pump.Speed = str2num(get(h.txt_pumpspeed,'String')); %#ok<ST2NM>
    set([h.btn_updatepumpspeed h.txt_pumpspeed],'Enable','on');
    set([h.btn_schstart h.btn_schpause],'Enable','off');
else
    Pump.Speed = 0;
    set([h.btn_updatepumpspeed h.txt_pumpspeed],'Enable','off');
    set([h.btn_schstart h.btn_schpause],'Enable','on');

end
setappdata(h.figure1,'Pump',Pump);


function WriteHeader(fid,Time)
fprintf(fid,'\nStart Date:,%s\n',datestr(Time.Start,'yyyy-mm-dd'));
fprintf(fid,'Start Time:,%s\n',  datestr(Time.Start,'HH:MM:SS'));
fprintf(fid,'Time (sec),Temp (C),Pump Speed\n');



%% Arduino
function A = ConnectArduino(COM)
delete(instrfind('tag','Arduino'));

A = Arduino(COM); % <- make a setting
A.QueryStates = false;
A.AnalogRange = A.C_AnalogRange;

% approx calibration with V-divider 50k-50k resistors from 5V (2/2/14)
% A.AnalogCal = polyfit([59.2 72.4 82.5],[14.7 22.0 27.7],1);
A.AnalogCal = polyfit([58.0 71.2],[23.2 30.3],1);

A.AnalogOpt = 'Cal';

p = polyval(A.AnalogCal, A.AnalogRange);
p = round(p*100)/100;
while A.GetVal('GetML') ~= p(1)
    A.SendMessage(sprintf('MAPLow:%0.2f',p(1)));
    pause(0.1);
end
while A.GetVal('GetMH') ~= p(2)
    A.SendMessage(sprintf('MAPHigh:%0.2f',p(2)));
    pause(0.1);
end







%% Timer functions
function PCT_Start(hObj,~,f)
ResetVars(f);
Temp = getappdata(f,'Temp');
set(hObj,'Period',Temp.Fs);

set(findobj(f,'tag','lbl_probetemp'),'ForegroundColor','g');


function PCT_Stop(~,~,f)
A = getappdata(f,'Arduino');
h = guidata(f);
set(h.lbl_probetemp,'String','--');
while A.GetVal('GetST')
    A.SendMessage('SetST:0'); % turn PID control off
    pause(0.1);
end



function PCT_Error(~,~,f)
A = getappdata(f,'Arduino');
h = guidata(f);
set(h.lbl_probetemp,{'String','ForegroundColor'},{'ERR','r'});
while A.GetVal('GetST')
    A.SendMessage('SetST:0'); % turn PID control off
    pause(0.1);
end



function PCT_RunTime(~,~,f)
h = guidata(f);

States  = getappdata(f,'States');
A       = getappdata(f,'Arduino');
Time    = getappdata(f,'Time');
Temp    = getappdata(f,'Temp');
Pump    = getappdata(f,'Pump');
Plot    = getappdata(f,'Plot');
File    = getappdata(f,'File');
Sched   = getappdata(f,'Sched');

% TX/RX
if States.Record
    set(h.txt_txrx,{'String','ForegroundColor'},{'o','r'}); drawnow
else
    set(h.txt_txrx,{'String','ForegroundColor'},{'o','g'}); drawnow
end

Time.Data(end+1) = single(round(etime(clock,Time.Start)*10)/10);
Temp.Data(end+1) = single(A.readAnalogPin(Temp.SensorPin));
OP = uint8(A.GetVal('GetOP'));
if isempty(OP)
    Pump.Data(end+1) = nan;
else
    Pump.Data(end+1) = OP;
end

if get(h.chk_showpumprate,'Value')
    PlotTemp(Plot,Time,Temp,Pump);
else
    PlotTemp(Plot,Time,Temp);
end

set(h.txt_txrx,'String',''); drawnow

set(h.lbl_probetemp,'String',num2str(Temp.Data(end),'% 2.1f'));



if ~States.Manual
    set(h.txt_pumpspeed,'String',num2str(Pump.Data(end)));
    % Automation code goes here
    if Time.Data(end) >= Sched.NData{Sched.Index,1}
        if Sched.Index == Sched.StopIndex
            set(h.mode_manual,'Value',1);
            ProgramControl([],h,'stopsched');
            PumpMode(h);
            fprintf('Completed Schedule: %s\n',datestr(clock))
%             fprintf('Maintaining Temperature at %0.1f C\n',A.GetVal('GetSP'));
        elseif ~Sched.Check(Sched.Index)
            A.SendMessage(sprintf('SetSP:%0.1f',Sched.NData{Sched.Index,2}));
            fprintf('Setpoint = %0.1f\n',Sched.NData{Sched.Index,2});
            D = Sched.Data;
            D{Sched.Index,1} = ['< ' D{Sched.Index,1}];
            set(h.tbl_tempsched,'Data',D);
            Sched.Check(Sched.Index) = true;
            Sched.Index = Sched.Index + 1;
            setappdata(f,'Sched',Sched);
        end
    end
end

try
    if States.Record == 1 && strcmp(File.filetype,'csv')
        fprintf(File.fid,'%0.0f,%0.1f,%0.1f\n', ...
            Time.Data(end),Temp.Data(end),Pump.Data(end));
    end
end

setappdata(f,'Temp',Temp);
setappdata(f,'Pump',Pump);
setappdata(f,'Time',Time);


function ResetVars(f)
Time = getappdata(f,'Time');
Time.Start = clock;
Time.Index = 1;
Time.Data  = single([]);
setappdata(f,'Time',Time);

Temp = getappdata(f,'Temp');
Temp.Fs         = 1;
Temp.SensorPin  = 0;
Temp.Data       = single([]);
setappdata(f,'Temp',Temp);

Pump = getappdata(f,'Pump');
Pump.Data = uint8([]);
setappdata(f,'Pump',Pump);



% Plotting
function Plot = InitPlot(ax)
c = findobj(ax,'type','surface');
if ~isempty(c), delete(c); end


Plot.TempSurf = surface([1 1],[0; 0],[1 0; 1 0],[1 0; 1 0]);
set(Plot.TempSurf,'EdgeColor',[0 0 0],'FaceColor','interp','linewidth',1, ...
    'meshstyle','row','Parent',ax);


colorbar

set(ax,'ylim',[0 0.1],'zlim',[-5 40]);
view(ax,0,0);

c = findobj(ax,'type','line');
if ~isempty(c), delete(c); end
Plot.Pump = line(0,0.1,0,'color','r','linewidth',2);

set(ax,'ylim',[-5 40],'clim',[-5 40]);
grid(ax,'on');
box(ax,'on');
xlabel(ax,'Time (sec)');
ylabel(ax,'Temperature (\circC)');

Plot.hX = findobj(ancestor(ax,'figure'),'tag','txt_maxx');

Plot.ax = ax;






function PlotTemp(Plot,Time,Temp,Pump)
x = get(Plot.hX,'String');
Plot.X = str2double(x);

ind = Time.Data > Time.Data(end)-Plot.X;

if nargin == 4
    set(Plot.Pump,'xdata',Time.Data(ind),'ydata',ones(sum(ind),1)*0.1,'zdata',Pump.Data(ind));
else
    set(Plot.Pump,'xdata',1,'ydata',0.1,'zdata',1);
end

if sum(ind) > 2
    Xdata = Time.Data(ind);
    Ydata = [0; 1];
    Zdata = [-5*ones(size(Xdata)); double(Temp.Data(ind))];
else
    Xdata = [1 1];
    Ydata = [0; 1];
    Zdata = Ydata*Xdata;
end
Cdata = Zdata;

set(Plot.TempSurf,'xdata',Xdata,'ydata',Ydata,'zdata',Zdata,'cdata',Cdata);
if Time.Data(end) < Plot.X
    set(Plot.ax,'xlim',[1 Plot.X]);
else
    set(Plot.ax,'xlim',[Time.Data(find(ind,1)) Time.Data(end)]);
end


drawnow;






% Temp Control
function Sched = GetTempSched(hObj)
Data = get(hObj,'Data');

Data(cellfun(@isempty,Data(:,1)),:) = [];

if numel(Data) < 2, return; end

ind = cellfun(@(x) (x(1)=='<'),Data(:,1));
if any(ind)
    Data{ind,1}(1:2) = [];
end

% Stop token
Sched.StopIndex = find(cellfun(@(x) (all(x=='X'|x=='x')),Data(:,2)),1);
if isempty(Sched.StopIndex)
    Data{end+1,1} = num2str(str2double(Data{end,1})+10);
    Data{end,2}   = 'X';
    Sched.StopIndex = size(Data,1);
end

nowisnum = cellfun(@str2double,Data);
ind = ~isnan(nowisnum);
if ~all(isnumeric(nowisnum(ind)))
    error('Invalid entry in Temperature Schedule');
end

Sched.Data = Data;
Sched.NData = Data;
Sched.NData(1:end-1) = cellfun(@str2double,Sched.NData(1:end-1),'UniformOutput',false);

Sched.Check = false(size(Data,1),1);

Sched.Index = 1;

bc = repmat({''},10-size(Data,1),2);
set(hObj,'Data',[Data; bc])












function CloseFig(hObj) %#ok<DEFNU>
ProgramControl(hObj,guidata(hObj),'stoptempmon');

A = getappdata(hObj,'Arduino');
try
    delete(A);
end

munlock('Arduino');

delete(hObj);


