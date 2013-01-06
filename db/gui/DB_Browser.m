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

h.hierarchy = {'databases','experiments','tanks', ...
    'blocks','channels','units'};
guidata(h.figure1,h);

dbpref = getpref('DB_Browser','databases',[]);

Connect2DB(h,dbpref);


function closeme(hObj,h) %#ok<DEFNU>
UpdatePrefs(h.hierarchy,h);
delete(hObj);









%% Database
function Connect2DB(h,dbpref)
if nargin == 1, dbpref = []; end

if ~myisopen % if connection is lost, reconnect to database
    dbs = DB_Connect;
else
    dbs = dblist;
end

if isempty(dbpref)
    i = get(h.popup_databases,'Value');
    dbpref = dbs{i};
end

mym(['use ' dbpref]);

i = find(ismember(dbs,dbpref));
set(h.popup_databases,'String',dbs,'Value',i);

UpdateLists(h.popup_databases,h);

function UpdateLists(hObj,h)
ord = h.hierarchy;

[~,str] = strtok(get(hObj,'tag'),'_');
str(1) = [];
starth = find(strcmp(str,ord));

if strncmp(get(hObj,'tag'),'showall',7)
    starth = starth - 1;
end

set(h.figure1,'Pointer','watch'); drawnow

UpdatePrefs(ord(starth:end),h);

for i = starth:length(ord)
    if strcmp('databases',ord{i})
        lOrd = h.popup_databases;
    else
        lOrd = h.(['list_' ord{i}]);
    end
    id = get_listid(lOrd);
    
    if isempty(id) && i > 1
        set(lOrd,'Value',1,'String','< NOTHING HERE >');
        if i < length(ord)
            set(h.(['list_' ord{i+1}]),'Value',1,'String','< NOTHING HERE >');
        end
        continue
    end
    
    if i < length(ord)
        
        % THIS SEEMS KIND OF CLUMSY
        saval = get(h.(['showall_' ord{i+1}]),'Value');
        if ~saval
            iustr = 'AND in_use = TRUE';
        else
            iustr = '';
        end
    end
    
    if ~isempty(id)
        check_inuse(ord{i},id,h.(['exclude_' ord{i}]));
    end

    switch ord{i}
        case 'databases'
            if ~isempty(iustr), iustr = 'WHERE in_use = TRUE'; end
            e = mym('SELECT CONCAT(id,". ",name) AS str FROM experiments {S}',iustr);
            
        case 'experiments'
            e = mym(['SELECT CONCAT(id,". ",tank_condition," [",name,"]") ', ...
                'AS str FROM tanks WHERE exp_id = {Si} {S}'],id,iustr);
            
        case 'tanks'
            e = mym(['SELECT CONCAT(b.id,". ",p.alias," [",b.block,"]") ', ...
                'AS str FROM blocks b JOIN db_util.protocol_types p ', ...
                'ON b.protocol = p.pid WHERE b.tank_id = {Si} {S} ', ...
                'ORDER BY block'],id,iustr);
            
        case 'blocks'
            e = mym(['SELECT CONCAT(id,". ",target,channel) AS str ', ...
                'FROM channels WHERE block_id = {Si} {S} ORDER BY channel'],id,iustr);
            
        case 'channels'
            e = mym(['SELECT CONCAT(u.id,". ",p.class," (",u.unit_count,")") ', ...
                'AS str FROM units u JOIN class_lists.pool_class p ', ...
                'ON u.pool = p.id WHERE u.channel_id = {Si} {S}'],id,iustr);
            
        case 'units'
            % plot unit waveform after unit is selected
            continue
    end
    
    val = GetListPref(ord{i+1},e.str);
    set(h.(['list_' ord{i+1}]),'String',e.str,'Value',val);

end

plot_unit_waveform(id,h);

set(h.figure1,'Pointer','arrow');

function UpdatePrefs(ord,h)
vals = cell(size(ord));
for i = 1:length(ord)
    if strcmp('databases',ord{i})
        lOrd = h.popup_databases;
    else
        lOrd = h.(['list_' ord{i}]);
    end
    rstr = get_string(lOrd);
    id = get_listid(lOrd);
    
    switch ord{i}
        case 'databases'
            vals{i} = rstr;
        case 'experiments'
            vals{i} = rstr;
        case 'tanks'
            if isempty(id), continue; end
            e = mym('SELECT tank_condition FROM tanks WHERE id = {Si}',id);
            vals{i} = char(e.tank_condition);
        case 'blocks'
            if isempty(id), continue; end
            e = mym(['SELECT p.alias FROM blocks b ', ...
                'JOIN db_util.protocol_types p ', ...
                'ON b.protocol = p.pid WHERE b.id = {Si}'],id);
            vals{i} = char(e.alias);
        case 'channels'
            if isempty(id), continue; end
            e = mym(['SELECT CONCAT(target,channel) AS str ', ...
                'FROM channels WHERE id = {Si}'],id);
            vals{i} = char(e.str);
        case 'units'
            if isempty(id), continue; end
            e = mym(['SELECT p.class FROM units u ', ...
                'JOIN class_lists.pool_class p ', ...
                'ON u.pool = p.id WHERE u.id = {Si}'],id);
            vals{i} = char(e.class);
    end
end
setpref('DB_Browser',ord,vals);

function val = GetListPref(ord,str)
pref = getpref('DB_Browser',ord,[]);
val = 1;
if isempty(pref), return; end

switch ord
    case {'databases', 'experiments'}
        return

    otherwise
        for j = 1:length(str);
            instr = strfind(str{j},char(pref));
            if instr
                val = j;
                break
            end
        end
        
end

function ExcludeItem(hObj,h) %#ok<DEFNU>
tag = get(hObj,'tag');
table = tag(9:end); % cut out 'exclude_' prefix
id = get_listid(h.(['list_' table]));
DB_InUse(table,id,'toggle');
UpdateLists(hObj,h);

function in_use = check_inuse(table,id,hObj)
in_use = DB_InUse(table,id);
if in_use
    bgc = [0.941 0.941 0.941];
else
    bgc = [1 0.57 0.57];
end
set(hObj,'BackgroundColor',bgc);



%% Get Data
function get_protocol_Callback(h) %#ok<DEFNU>
set(h.figure1,'Pointer','watch'); drawnow
id = get_listid(h.list_blocks);
params = DB_GetParams(id);
assignin('base','params',params);
fprintf('Parameters structure in workspace: params\n')
whos params
set(h.figure1,'Pointer','arrow');

function get_lfp_Callback(h) %#ok<DEFNU>
set(h.figure1,'Pointer','watch'); drawnow
id = get_listid(h.list_channels);
[lfp.wave,lfp.tvec] = DB_GetWave(id);
assignin('base','lfp',lfp);
fprintf('LFP structure in workspace: lfp\n')
whos lfp
set(h.figure1,'Pointer','arrow');

function get_spiketimes_Callback(h) %#ok<DEFNU>
set(h.figure1,'Pointer','watch'); drawnow
id = get_listid(h.list_units);
spiketimes = DB_GetSpiketimes(id);
assignin('base','spiketimes',spiketimes);
fprintf('Spiketimes structure in workspace: spiketimes\n')
whos spiketimes
set(h.figure1,'Pointer','arrow');



%% Helper functions
function rstr = get_string(hObj)
% get currently select string
v = get(hObj,'Value');
s = cellstr(get(hObj,'String'));
if v > length(s), v = 1; end
if isempty(s)
    rstr = '';
else
    rstr = s{v};
end

function id = get_listid(hObj)
% get unique table id from list string
str = get_string(hObj);
id  = str2num(strtok(str,'.'));  %#ok<ST2NM>

function plot_unit_waveform(id,h)
cla(h.axes_unit,'reset');
if isempty(id), return; end
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
