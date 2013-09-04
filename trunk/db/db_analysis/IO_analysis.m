function varargout = IO_analysis(varargin)
% IO_ANALYSIS MATLAB code for IO_analysis.fig
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help IO_analysis

% Last Modified by GUIDE v2.5 30-Aug-2013 12:21:56

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @IO_analysis_OpeningFcn, ...
                   'gui_OutputFcn',  @IO_analysis_OutputFcn, ...
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


% --- Executes just before IO_analysis is made visible.
function IO_analysis_OpeningFcn(hObj, ~, h, varargin)
h.output = hObj;
set(h.IO_analysis,'UserData',0)

n = {'bestlevel','maxresp','threshold','transpoint','monotoneslope','is_good'};
d = {'Level of best response', 'Maximum response', 'Threshold', 'Transition point', ...
    'Monotonicity slope from transition point to highest level', 'Is good quality'};
DB_CheckAnalysisParams(n,d);

unit_id = varargin{1};
h = InitializeIO(unit_id,h);

auv = getpref('IO_analysis','auto_updatedb',0);
set(h.auto_updatedb,'Value',auv);

m = getpref('IO_analysis','metric','peakfr');
s = get(h.metric,'String');
set(h.metric,'Value',find(ismember(s,m)));

guidata(hObj, h);




function h = InitializeIO(unit_id,h)
rif = DBGetRIF(unit_id,get_string(h.metric));

if isempty(rif)
    cla(h.axes1)
    b = questdlg(['Histograms have not been analyzed for this unit. ', ...
        'Would you like to launch RIF_analysis?'], ...
        'IO_analysis','Yes','No','Yes');
    if strcmp(b,'Yes')
        RIF_analysis(unit_id);
    else
        close(h.IO_analysis);
        return
    end
else     
    h.rif = rif;

    updateplot('rif',h);
    
    h = UpdateRIFFeatures('bestlevel',h);
    
    if isfield(rif,'transpoint') && ~isempty(rif.transpoint) && ~isnan(rif.transpoint)
        updateplot('transition',h);
    end
    
    if isfield(rif,'threshold') && ~isempty(rif.threshold) && ~isnan(rif.threshold)
        updateplot('threshold',h);
    else
        h = UpdateRIFFeatures('statthreshold',h);
        updateplot('threshold',h);
    end
    
    if isfield(rif,'is_good') && ~isempty(rif.is_good)
        set(h.quality_good,'Value',rif.is_good);
    else
        set(h.quality_good,'Value',1);
    end
end


    
% --- Outputs from this function are returned to the command line.
function varargout = IO_analysis_OutputFcn(~, ~, h) 
% Get default command line output from handles structure
varargout{1} = h.output;









%%
function rif = DBGetRIF(unit_id,metric)
rif = DB_GetUnitProps(unit_id,'dBRIF$');
if isempty(rif), return; end
% recreate level from group_id
rif.level = cellfun(@sscanf,rif.group_id,repmat({'%f'},size(rif.group_id)));
rif.level = rif.level(:)';

fet = DB_GetUnitProps(unit_id,['RIFIO_' metric]);
if ~isempty(fet)
    for i = fieldnames(fet)'
        i = char(i); %#ok<FXSET>
        rif.(i) = fet.(i);
    end
end
rif.unit_id = unit_id;



%%
function UpdateDB(h,specific)
set(gcf,'Pointer','watch'); drawnow
rif = h.rif;

if nargin == 1
    urif.threshold     = rif.threshold;
    urif.transpoint    = rif.transpoint;
    urif.bestlevel     = rif.bestlevel;
    urif.monotoneslope = rif.monotoneslope;
    urif.is_good       = rif.is_good;
else
    specific = cellstr(specific);
    for i = specific
        i = char(i); %#ok<FXSET>
        if isfield(rif,i)
            urif.(i) = rif.(i);
        end
    end
end

m = get_string(h.metric);
urif.group_id = ['RIFIO_' m];

DB_UpdateUnitProps(rif.unit_id,urif,'group_id',true);

set(h.IO_analysis,'UserData',1)
set(gcf,'Pointer','arrow'); drawnow



%%
function h = UpdateRIFFeatures(feature,h)
rif = h.rif;

feature = char(feature);
metric = strtrim(get_string(h.metric));

switch feature
    case 'bestlevel'
        [rif.maxresponse,b] = max(rif.(metric)); 
        rif.bestlevel = rif.level(b);
        specific = 'bestlevel';

    case 'threshold'
        [a,~] = ginput(1);
        a = interp1(rif.level,rif.level,a,'nearest');
        rif.threshold = a;
        specific = 'threshold';

    case 'statthreshold'
        sind = rif.ksp < 0.025;
        sind = flipud(sind);
        didx = find(sind(2:end) < sind(1:end-1));
        if ~isempty(didx)
            rif.threshold = min(rif.level(didx));
        end
        specific = 'threshold';
        
    case 'transition'
        [a,~] = ginput(1);
        a = interp1(rif.level,rif.level,a,'nearest');
        rif.transpoint = a;
        if a == max(rif.level)
            p = 0;
        else
            ind = rif.level>=a;
            p = polyfit(rif.level(ind),rif.(metric)(ind),1);
        end
        rif.monotoneslope = p(1);
        specific = {'transpoint','monotoneslope'};
end
h.rif = rif;
guidata(h.IO_analysis,h);
updateplot(feature,h);
if get(h.auto_updatedb,'Value'), UpdateDB(h,specific); end


function updateplot(tag,h) 
tag = char(tag);

rif = h.rif;

metric = strtrim(get_string(h.metric));

ax = h.axes1;
switch tag
    case 'rif'
        cla(ax)
        plot(ax,rif.level,rif.(metric),'-o', ...
            'color',[0.2 0.2 0.2],'markersize',10,'markerfacecolor',[0.6 0.6 0.6]);
        grid(ax,'on');
        hold(ax,'on');
%         plot(ax,rif.level,rif.prestimmeanfr,':x','color',[0.6 0.6 0.6]);
        plot(ax,xlim,[0 0],'-k','linewidth',3);
        hold(ax,'off');
        xlabel('Sound Level (dB SPL)');
        ylabel('Firing Rate (Hz)');
        title(sprintf('Unit #%d %s',rif.unit_id,metric));
        
        set(h.bestlevel,'String','Best level:')
        set(h.threshold,'String','Threshold:')
        set(h.transition,'String','Transition Point:')
        set(h.slope,'String','Slope:')
        
    case 'bestlevel'
        hold(ax,'on');

        plot(ax,rif.bestlevel,rif.maxresponse,'o', ...
            'color',[0.2 0.2 0.2],'markersize',10,'markerfacecolor',[240 160 160]/255);
        hold(ax,'off');
        set(h.bestlevel,'string',sprintf('Best level: %d dB SPL',rif.bestlevel));
        
    case 'threshold'
        hold(ax,'on');
        do = findobj(ax,'color','c','-and','marker','v');
        if ~isempty(do), delete(do); end
        oc = get(h.threshold,'backgroundcolor');
        set(h.threshold,'backgroundcolor','g');
        if isfield(rif,'threshold') && ~isempty(rif.threshold)
            plot(ax,rif.threshold,rif.(metric)(rif.threshold==rif.level), ...
                'vc','markersize',10,'linewidth',3);
            hold(ax,'off');
            set(h.threshold,'backgroundcolor',oc, ...
                'string',sprintf('Threshold: %d dB SPL',rif.threshold));
        else
            set(h.threshold,'backgroundcolor',oc,'string','Threshold:');
        end
        
    case 'transition'
        hold(ax,'on');
        do = findobj(ax,'color','g','-and','marker','^');
        if ~isempty(do), delete(do); end
        oc = get(h.threshold,'backgroundcolor');
        set(h.(tag),'backgroundcolor','g');

        plot(ax,rif.transpoint,rif.(metric)(rif.transpoint == rif.level), ...
            '^g','markersize',10,'linewidth',3);
        
        do = findobj(ax,'color','r');
        if ~isempty(do), delete(do); end
        
        a = rif.transpoint;
        if a == max(rif.level)
            p = 0;
            y = [rif.(metric)(end) rif.(metric)(end)];
        else
            p = polyfit(rif.level(rif.level>=a),rif.(metric)(rif.level>=a),1);
            y = polyval(p,[a max(rif.level)]);
        end
        plot(ax,[a max(rif.level)],y,':r','linewidth',3);
        hold(ax,'off');
        set(h.transition,'backgroundcolor',oc, ...
             'string',sprintf('Transition Point: %d dB SPL',rif.transpoint));
        set(h.slope,'string',sprintf('Slope: % 2.3f',p(1)));

end


function quality_options_SelectionChangeFcn(~, evnt, h) %#ok<DEFNU>
h.rif.is_good = evnt.NewValue == h.quality_good;
guidata(h.IO_analysis,h);
auv = get(h.auto_updatedb,'Value');
if auv, UpdateDB(h,'is_good'); end
setpref('IO_analysis','auto_updatedb',auv);


function metric_Callback(h) %#ok<DEFNU>
h = InitializeIO(h.rif.unit_id,h);
guidata(h.IO_analysis, h);
m = get_string(h.metric);
setpref('IO_analysis','metric',m);

