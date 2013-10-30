function varargout = DB_Browser(varargin)
% DB_Browser
%
% Browses MySQL Electrophysiology database.
% 
% The database IDs of items selected in the lists of the DB_Browser GUI can
% be accessed externally by the following:
%       IDs = getpref('DB_BROWSER_SELECTION')
%       % IDs will be a structure with fieldnames which correspond to
%       % tables on the database and which have a scalar value
%       % corresponding to the data selected in the browser
%       
% 
% See also, DB_UploadUtility
%
% Daniel.Stolzberg@gmail.com 2013

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
% uiwait(h.DB_Browser);


% --- Outputs from this function are returned to the command line.
function varargout = DB_Browser_OutputFcn(hObj, event, h)  %#ok<INUSL>
% Get default command line output from h structure
varargout{1} = h.output;

h.hierarchy = {'databases','experiments','tanks', ...
    'blocks','channels','units'};
guidata(h.DB_Browser,h);

dbpref = getpref('DB_Browser','databases',[]);

Connect2DB(h,dbpref);


function closeme(hObj,~) %#ok<DEFNU>
% UpdatePrefs(h.hierarchy,h);
delete(hObj);









%% Database
function Connect2DB(h,dbpref,reg)
if nargin == 1, dbpref = []; end

if nargin == 3 && reg
    dbs = DB_Connect(true);
elseif ~myisopen % if connection is lost, reconnect to database
    dbs = DB_Connect;
else
    dbs = dblist;
end

if isempty(dbpref)
    i = get(h.popup_databases,'Value');
    dbpref = dbs{i};
end

mym('use',dbpref);

% this will ensure that all tables and views exist
DB_CreateDatabase(dbpref); 

i = find(ismember(dbs,dbpref));
set(h.popup_databases,'String',dbs,'Value',i);

UpdateLists(h.popup_databases,h);

function UpdateLists(hObj,h)
ord = h.hierarchy;

if hObj == -1, hObj = h.list_blocks; end
if hObj == -2, hObj = h.list_channels;  end

[~,str] = strtok(get(hObj,'tag'),'_');
str(1) = [];
starth = find(strcmp(str,ord));

if strncmp(get(hObj,'tag'),'showall',7)
    starth = starth - 1;
end

set(h.DB_Browser,'Pointer','watch'); drawnow

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
                'AS str FROM tanks WHERE exp_id = {Si} {S} ', ...
                'ORDER BY tank_condition'],id,iustr);
            
        case 'tanks'
            e = mym(['SELECT CONCAT(b.id,". ",p.alias," [",b.block,"]") ', ...
                'AS str FROM blocks b JOIN db_util.protocol_types p ', ...
                'ON b.protocol = p.pid WHERE b.tank_id = {Si} {S} ', ...
                'ORDER BY block'],id,iustr);
            
        case 'blocks'
            e = mym(['SELECT CONCAT(id,". ",target,channel) AS str ', ...
                'FROM channels WHERE block_id = {Si} {S} ORDER BY channel'],id,iustr);
            if get(h.map_channels,'Value')
                elec = DB_GetElectrode(get_listid(h.list_tanks));
                e.str = e.str(elec.map(:));
            end
            
            
        case 'channels'
            if get(h.hide_unclassed_units,'Value')
                e = mym(['SELECT CONCAT(u.id,". ",p.class," (",u.unit_count,")") ', ...
                'AS str FROM units u JOIN class_lists.pool_class p ', ...
                'ON u.pool = p.id WHERE u.channel_id = {Si} {S} ', ...
                'AND p.id > 0 ORDER BY p.id'],id,iustr);
            else
                e = mym(['SELECT CONCAT(u.id,". ",p.class," (",u.unit_count,")") ', ...
                'AS str FROM units u JOIN class_lists.pool_class p ', ...
                'ON u.pool = p.id WHERE u.channel_id = {Si} {S} ', ...
                'ORDER BY p.id'],id,iustr);
            end
            
        case 'units'
            setappdata(h.DB_Browser,ord{i},get_listid(h.(['list_' ord{i}])));
            continue
    end
    
    val = GetListPref(ord{i+1},e.str);
    set(h.(['list_' ord{i+1}]),'String',e.str,'Value',val);
    setappdata(h.DB_Browser,ord{i+1},get_listid(h.(['list_' ord{i+1}])));    
end

for i = 2:length(ord)
	setpref('DB_BROWSER_SELECTION',ord{i},get_listid(h.(['list_' ord{i}])));
end

plot_unit_waveform(id,h);

% update DB_QuickPlot
if ~isempty(findobj('name','DB_QuickPlot'))
    DB_QuickPlot(@RefreshParameters);
end

Check4AnalysisTools(h);

set(h.DB_Browser,'Pointer','arrow');

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
set(h.DB_Browser,'Pointer','watch'); drawnow
id = get_listid(h.list_blocks);
params = DB_GetParams(id);
assignin('base','params',params);
fprintf('Parameters structure in workspace: params\n')
whos params
set(h.DB_Browser,'Pointer','arrow');

function get_lfp_Callback(h) %#ok<DEFNU>
set(h.DB_Browser,'Pointer','watch'); drawnow
id = get_listid(h.list_channels);
[lfp.wave,lfp.tvec] = DB_GetWave(id);
assignin('base','lfp',lfp);
fprintf('LFP structure in workspace: lfp\n')
whos lfp
set(h.DB_Browser,'Pointer','arrow');

function get_spiketimes_Callback(h) %#ok<DEFNU>
set(h.DB_Browser,'Pointer','watch'); drawnow
id = get_listid(h.list_units);
spiketimes = DB_GetSpiketimes(id);
assignin('base','spiketimes',spiketimes);
fprintf('Spiketimes structure in workspace: spiketimes\n')
whos spiketimes
set(h.DB_Browser,'Pointer','arrow');



%% Helper functions

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











%% Analysis tools
function Check4AnalysisTools(h)
natstr = '< NO ANALYSIS TOOLS >';
set(h.list_analysis_tools,'Value',1,'String',natstr,'Enable','off');
set(h.launch_analysis,'Enable','off');

ids = getpref('DB_BROWSER_SELECTION');

bid = myms(sprintf(['SELECT p.id FROM db_util.protocol_types p ', ...
    'JOIN blocks b ON b.protocol = p.pid ', ...
    'WHERE b.id = %d'],ids.blocks));

mym(['CREATE  TABLE IF NOT EXISTS db_util.analysis_tools (', ...
    'id INT UNSIGNED NOT NULL AUTO_INCREMENT ,', ...
    'tool VARCHAR(45) NOT NULL ,', ...
    'protocol_id_str VARCHAR(45) NOT NULL ,', ...
    'PRIMARY KEY (id, tool) ,', ...
    'UNIQUE INDEX id_UNIQUE (id ASC) );']);


at = mym('SELECT * FROM db_util.analysis_tools');
p  = mym('SELECT * FROM db_util.protocol_types');

if isempty(at), return; end

validtools = [];
for i = 1:length(at.protocol_id_str)
    m = str2num(at.protocol_id_str{i}); %#ok<ST2NM>
    if isempty(m) || ~any(m == bid), continue; end
    for j = 1:length(m)
        ind = m(j) == p.id;
        if any(ind)
            validtools{end+1} = at.tool{i}; %#ok<AGROW>
        end
    end
end


if ~isempty(validtools)
    set(h.list_analysis_tools,'Value',1,'String',validtools,'Enable','on');
    set(h.launch_analysis,'Enable','on');    
end


function LaunchAnalysisTool(h) %#ok<DEFNU>
set(h.DB_Browser,'Pointer','watch'); drawnow
tool = get_string(h.list_analysis_tools);
feval(tool);
set(h.DB_Browser,'Pointer','arrow'); drawnow




function ScrollUnits(direction,h) %#ok<DEFNU>
uv = get(h.list_units,'Value');
us = cellstr(get(h.list_units,'String'));

cv = get(h.list_channels,'Value');
cs = cellstr(get(h.list_channels,'String'));

bv = get(h.list_blocks,'Value');
bs = cellstr(get(h.list_blocks,'String'));

tv = get(h.list_tanks,'Value');
ts = cellstr(get(h.list_tanks,'String'));

ntv = tv;
nbv = bv;
ncv = cv;
nuv = uv;

lts = length(ts);
lbs = length(bs);
lcs = length(cs);
lus = length(us);

switch char(direction)
    case 'next'
        if uv == lus
            if cv == lcs
                if bv == lbs
                    if tv == lts
                        ntv = 1;
                        nbv = 1;
                        ncv = 1;
                        nuv = 1;
                    else
                        ntv = tv + 1;
                        nbv = 1;
                        ncv = 1;
                        nuv = 1;
                    end
                else
                    nbv = bv + 1;
                    ncv = 1;
                    nuv = 1;
                end
            else
                ncv = cv + 1;
                nuv = 1;
            end
        else
            nuv = uv + 1;
        end
        
    case 'last'
%         if uv == 1
%             if cv == 1
%                 if bv == 1
%                     if tv == 1
%                         ntv = ltv;
%                         nbv = lbv;
%                         ncv = lcv;
%                         nuv = luv;
%                     else
%                         ntv = ltv - 1;
%                         nbv = lbv;
%                         ncv = lcv;
%                         nuv = luv;
%                     end
%                 else
%                     nbv = lbv - 1;
%                     ncv = lcv;
%                     nuv = luv;
%                 end
%             else
%                 ncv = cv + 1;
%                 nuv = 1;
%             end
%         else
%             nuv = uv + 1;
%         end
end


set(h.list_tanks,   'Value',ntv);
set(h.list_blocks,  'Value',nbv);
set(h.list_channels,'Value',ncv);
set(h.list_units,   'Value',nuv);



UpdateLists(h.list_tanks,h)

















%% External
function LaunchParams(h) %#ok<DEFNU>
block_id = get_listid(h.list_blocks);
DB_ParameterBreakout(block_id);

function LaunchPlot(h) %#ok<INUSD,DEFNU>
% f = DB_GenericPlot(true);
% figure(f)
DB_QuickPlot;


