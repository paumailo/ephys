function varargout = DB_Browser(varargin)
% DB_Browser
%
%
% DJS 2013

% Edit the above text to modify the response to help DB_Browser

% Last Modified by GUIDE v2.5 04-Jan-2013 12:28:43

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @DB_Browser_OpeningFcn, ...
    'gui_OutputFcn',  @DB_Browser_OutputFcn, ...
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


% --- Executes just before DB_Browser is made visible.
function DB_Browser_OpeningFcn(hObj, event, h, varargin) %#ok<INUSL>
% Choose default command line output for DB_Browser
h.output = hObj;

% Update h structure
guidata(hObj, h);

% UIWAIT makes DB_Browser wait for user response (see UIRESUME)
% uiwait(h.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = DB_Browser_OutputFcn(hObj, event, h)  %#ok<INUSL>
% Get default command line output from h structure
varargout{1} = h.output;

dbs = DB_Connect;

lastdb = getpref('DB_Browser','lastdb',dbs{1});

i = find(ismember(dbs,lastdb));
if isempty(i), i = 1; end

% populate databases
set(h.popup_databases,'String',dbs,'Value',i);

Connect2DB(h.popup_databases,h);




% function SetPrefs(h) %#ok<DEFNU>
% objs = findobj(h.figure1,'-regexp','tag','list_','-or','-regexp','tag','popup');
% rstr   = cell(size(objs));
% objstr = cell(size(objs));
% for i = 1:length(objs)
%     objstr{i} = get(objs(i),'tag');
%     rstr{i}   = get_string(objs(i));
% end
% setpref('DB_Browser',objstr,rstr);





%%
function Connect2DB(hObj,h)
if ~myisopen % if connection is lost, reconnect to database
    DB_Connect;
end
rstr = get_string(hObj);
mym(['use ' rstr]);

UpdateLists(h.popup_databases,h);

function UpdateLists(hObj,h)
hierarchy = {'popup_databases','list_experiments','list_tanks', ...
    'list_blocks','list_channels','list_units'};

starth = find(strcmp(get(hObj,'tag'),hierarchy));

for i = starth:length(hierarchy)
    id = get_listid(h.(hierarchy{i}));
    if i < length(hierarchy) && isempty(id)
        set(h.(hierarchy{i+1}),'Value',1,'String','< NOTHING HERE >');
        continue
    end
    switch hierarchy{i}
        case 'popup_databases'
            e = mym('SELECT CONCAT(id,". ",name) AS str FROM experiments');
            
        case 'list_experiments'
            
            e = mym(['SELECT CONCAT(id,". ",tank_condition," [",name,"]") ', ...
                'AS str FROM tanks WHERE exp_id = {Si}'],id);
            
        case 'list_tanks'
            e = mym(['SELECT CONCAT(b.id,". ",p.alias," [",b.block,"]") ', ...
                'AS str FROM blocks b JOIN db_util.protocol_types p ', ...
                'ON b.protocol = p.pid WHERE b.tank_id = {Si}'],id);

        case 'list_blocks'
            e = mym(['SELECT CONCAT(id,". ",target,channel) AS str ', ...
                'FROM channels c WHERE c.block_id = {Si}'],id);
            
        case 'list_channels'
            e = mym(['SELECT CONCAT(u.id,". ",p.class," (",u.unit_count,")") ', ...
                'AS str FROM units u JOIN class_lists.pool_class p ', ...
                'ON u.pool = p.id WHERE u.channel_id = {Si}'],id);
        
        case 'list_units'
            % Get unit info
            continue
    end
    setlistid(h,hierarchy{i+1},e.str);
    drawnow
end







%% Helper functions
function rstr = get_string(hObj)
% get currently select string
v = get(hObj,'Value');
s = cellstr(get(hObj,'String'));
if isempty(s)
    rstr = '';
else
    rstr = s{v};
end

function id = get_listid(hObj)
% get unique table id from list string
str = get_string(hObj);
id  = strtok(str,'.');

function id = setlistid(h,name,list)
p = getpref('DB_Browser',name,'');
id = find(strcmp(list,p));
if isempty(id), id = 1; end
set(h.(name),'String',list,'Value',id);














