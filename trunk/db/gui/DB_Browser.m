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


function closeme(hObj,h) %#ok<INUSD,DEFNU>
delete(hObj);









%% Database
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

cla(h.axes_unit);

starth = find(strcmp(get(hObj,'tag'),hierarchy)); drawnow
set(h.figure1,'Pointer','watch');
for i = starth:length(hierarchy)
    id = get_listid(h.(hierarchy{i}));
    if isempty(id) 
        set(h.(hierarchy{i}),'Value',1,'String','< NOTHING HERE >');
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
                'FROM channels WHERE block_id = {Si} ORDER BY channel'],id);
            
        case 'list_channels'
            e = mym(['SELECT CONCAT(u.id,". ",p.class," (",u.unit_count,")") ', ...
                'AS str FROM units u JOIN class_lists.pool_class p ', ...
                'ON u.pool = p.id WHERE u.channel_id = {Si}'],id);
        
        case 'list_units'
            e = mym('SELECT * FROM units WHERE id = {Si}',id);
            w = str2num(char(e.pool_waveform{1}')); %#ok<ST2NM>
            s = str2num(char(e.pool_stddev{1}')); %#ok<ST2NM>
            fill([1:length(w) length(w):-1:1],[w+s fliplr(w-s)], ...
                [0.6 0.6 0.6],'Parent',h.axes_unit);
            hold(h.axes_unit,'on');
            plot(h.axes_unit,1:length(w),w,'-k','LineWidth',2)
            hold(h.axes_unit,'off');
            axis(h.axes_unit,'tight');
            y = max(abs(ylim(h.axes_unit)));
            ylim(h.axes_unit,[-y y]);
            continue
    end
    setlistid(h,hierarchy{i+1},e.str);
    drawnow
end
set(h.figure1,'Pointer','arrow');

function get_protocol_Callback(h) %#ok<DEFNU>
set(h.figure1,'Pointer','watch'); drawnow
id = get_listid(h.list_blocks);
params = DB_GetParams(id);
assignin('base','params',params);
fprintf('Parameters structure in workspace: params\n')
whos params
set(h.figure1,'Pointer','arrow');

function get_lfp_Callback(h)
set(h.figure1,'Pointer','watch'); drawnow

set(h.figure1,'Pointer','arrow');


function get_spiketimes_Callback(h)




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
id  = str2num(strtok(str,'.')); 

function id = setlistid(h,name,list)
p = getpref('DB_Browser',name,'');
id = find(strcmp(list,p));
if isempty(id), id = 1; end
set(h.(name),'String',list,'Value',id);











