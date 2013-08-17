function varargout = ManageDBAnalysisTools(varargin)
% h = ManageDBAnalysisTools(varargin)

% Edit the above text to modify the response to help ManageDBAnalysisTools

% Last Modified by GUIDE v2.5 17-Aug-2013 13:19:54

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ManageDBAnalysisTools_OpeningFcn, ...
                   'gui_OutputFcn',  @ManageDBAnalysisTools_OutputFcn, ...
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


% --- Executes just before ManageDBAnalysisTools is made visible.
function ManageDBAnalysisTools_OpeningFcn(hObj, ~, h, varargin)
h.output = hObj;

guidata(hObj, h);

CreateDBtable;

ResetProtocols(h);

UpdateAnalysisTools(h);

% --- Outputs from this function are returned to the command line.
function varargout = ManageDBAnalysisTools_OutputFcn(~, ~, h) 
varargout{1} = h.output;













function tools_Callback(hObj, ~, h)
tstr = get_string(hObj);
t = myms(sprintf(['SELECT protocol_id_str FROM db_util.analysis_tools ', ...
    'WHERE tool = "%s"'],tstr));

t = str2num(t); %#ok<ST2NM>

ResetProtocols(h);

UD = get(h.available_protocols,'UserData');

Aid = UD{2};





function add_tool_Callback(~, ~, h) %#ok<DEFNU>
options.WindowStyle = 'modal';
options.Interpreter = 'none';
t = inputdlg('Enter function name:','Add Tool',1,{''},options);
t = char(t);
if isempty(t), return; end

if ~exist(t,'file')
    errordlg(sprintf('The function "%s" was not found on the path.',t), ...
        'Add Tool','modal');
    return
end

mym(['REPLACE db_util.analysis_tools (tool,protocol_id_str) ', ...
     'VALUES ("{S}","[]")'],t);

UpdateAnalysisTools(h);
ResetProtocols(h);


function UpdateAnalysisTools(h)
t = myms('SELECT tool FROM db_util.analysis_tools');
if isempty(t)
    errordlg('No Analysis Tools Found')
    return
else
    set(h.tools,'String',t,'Value',length(t));
end



function ResetProtocols(h)
p = GetDBProtocols;
Aid = p.id;
Bid = [];
set(h.available_protocols,'String',p.listname,'Value',1,'UserData',{p,Aid,Bid});
set(h.valid_protocols,'String','','Value',1);
CheckProtButtons(h);


function CheckProtButtons(h)
s = get(h.available_protocols,'String');
if isempty(s)
    set(h.add_protocol,'Enable','off');
else
    set(h.add_protocol,'Enable','on');
end

s = get(h.valid_protocols,'String');
if isempty(s)
    set(h.remove_protocol,'Enable','off');
else
    set(h.remove_protocol,'Enable','on');
end



function CreateDBtable
mym(['CREATE  TABLE IF NOT EXISTS db_util.analysis_tools (', ...
     'id INT UNSIGNED NOT NULL AUTO_INCREMENT ,', ...
     'tool VARCHAR(45) NOT NULL ,', ...
     'protocol_id_str VARCHAR(45) NOT NULL ,', ...
     'PRIMARY KEY (id, tool) ,', ...
     'UNIQUE INDEX id_UNIQUE (id ASC) );']);


function p = GetDBProtocols
p = mym(['SELECT *,CONCAT(pid," ",alias," - ",name) AS listname ' ,...
         'FROM db_util.protocol_types ', ...
         'ORDER BY pid']);




function UpdateDB(h)
t = get_string(h.tools);
UD = get(h.available_protocols,'UserData');
Bid = UD{3};

if isempty(Bid)
    pstr = '[]';
else
    pstr = mat2str(Bid);
end
 
mym(['UPDATE db_util.analysis_tools SET protocol_id_str = "{S}" ', ...
    'WHERE tool = "{S}"'],pstr,t);


function add_protocol_Callback(~, ~, h) %#ok<DEFNU>
UD = get(h.available_protocols,'UserData');

p   = UD{1};
Aid = UD{2};
Bid = UD{3};

v = get(h.available_protocols,'Value');

Bid(end+1:end+length(v)) = Aid(v);
Aid(v) = [];

UD{2} = Aid;
UD{3} = Bid;

set(h.available_protocols,'String',p.listname(~ismember(1:length(Aid),v)),'Value',1,'UserData',UD);
set(h.valid_protocols,'String',p.listname(ismember(1:length(Aid),v)),'Value',1);
CheckProtButtons(h);
UpdateDB(h);

function remove_protocol_Callback(~, ~, h) %#ok<DEFNU>
UD = get(h.available_protocols,'UserData');

p   = UD{1};
Aid = UD{2};
Bid = UD{3};

v = get(h.valid_protocols,'Value');

Aid(end+1:end+length(v)) = Bid(v);
Bid(v) = [];

UD{2} = Aid;
UD{3} = Bid;

set(h.available_protocols,'String',p.listname(~ismember(1:length(Aid),v)),'Value',1,'UserData',UD);
set(h.valid_protocols,'String',p.listname(ismember(1:length(Aid),v)),'Value',1);
CheckProtButtons(h);
UpdateDB(h);














function Done(h) %#ok<DEFNU>
close(h.figure1);
