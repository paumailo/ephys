function varargout = IO_analysis(varargin)
% IO_ANALYSIS MATLAB code for IO_analysis.fig
%      IO_ANALYSIS, by itself, creates a new IO_ANALYSIS or raises the existing
%      singleton*.
%
%      H = IO_ANALYSIS returns the handle to a new IO_ANALYSIS or the handle to
%      the existing singleton*.
%
%      IO_ANALYSIS('CALLBACK',hObj,eventData,handles,...) calls the local
%      function named CALLBACK in IO_ANALYSIS.M with the given input arguments.
%
%      IO_ANALYSIS('Property','Value',...) creates a new IO_ANALYSIS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before IO_analysis_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to IO_analysis_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help IO_analysis

% Last Modified by GUIDE v2.5 08-Aug-2013 10:24:54

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
set(h.RIF_analysis,'UserData',0)

unitid = varargin{1};
rif = DBGetRIF(unitid);
guidata(hObj, h);

if isempty(rif.unit_id)
    cla(h.axes1)
else       
    h.rif = rif;

    updateplot('rif',h);
    
    h = UpdateRIFFeatures('bestlevel',h);
    
    if ~isempty(rif.FEATURES.transitionpoint) && ~isnan(rif.FEATURES.transitionpoint)
        updateplot('transition',h);
    end
    
    if ~isempty(rif.FEATURES.threshold) && ~isnan(rif.FEATURES.threshold)
        updateplot('threshold',h);
    else
        h = UpdateRIFFeatures('statthreshold',h);
        updateplot('threshold',h);
    end
end


    
% --- Outputs from this function are returned to the command line.
function varargout = IO_analysis_OutputFcn(~, ~, h) 
% Get default command line output from handles structure
varargout{1} = h.output;









%%
function rif = DBGetRIF(unitid)
rif = mym('SELECT * FROM analysis_rif WHERE unit_id = {Si}',unitid);
if isempty(rif.unit_id)
    return
%     error('No unit id %d found on analysis_rif table',unitid)
end
rif.unit_id = rif.unit_id(1);

rif.FEATURES = mym('SELECT * FROM analysis_rif_features WHERE unit_id = {Si}',unitid);



%%
function update_Callback(~, ~, h) %#ok<DEFNU>
CreateDBrifFeaturesTable;

rif = h.rif;

if isempty(rif.FEATURES.threshold) || isempty(rif.FEATURES.transitionpoint)
    rstr = sprintf([ ...
        'REPLACE analysis_rif_features ', ...
        '(unit_id,bestlevel,maxresponse,threshold,transitionpoint,slope,is_good) ', ...
        'VALUES (%d,NULL,NULL,NULL,NULL,NULL,0)'],rif.unit_id);
    mym(rstr);
    fprintf('Updated unit %d with NULLs\n',rif.unit_id)
else
    rstr = sprintf([ ...
        'REPLACE analysis_rif_features ', ...
        '(unit_id,bestlevel,maxresponse,threshold,transitionpoint,slope) ', ...
        'VALUES (%d,%f,%f,%f,%f,%f)'],rif.unit_id, ...
        rif.FEATURES.bestlevel,rif.FEATURES.maxresponse, ...
        rif.FEATURES.threshold,rif.FEATURES.transitionpoint, ...
        rif.FEATURES.slope);
    mym(rstr);
    fprintf('Updated unit %d\n',rif.unit_id);
end
set(h.RIF_analysis,'UserData',1)


function CreateDBrifFeaturesTable
mym(['CREATE TABLE IF NOT EXISTS analysis_rif_features (', ...
  'unit_id INT UNSIGNED NOT NULL ,', ...
  'bestlevel FLOAT NULL ,', ...
  'maxresponse FLOAT NULL ,', ...
  'threshold FLOAT NULL ,', ...
  'transitionpoint FLOAT NULL ,', ...
  'slope FLOAT NULL ,', ...
  'timestamp DATETIME NULL DEFAULT CURRENT_TIMESTAMP ,', ...
  'is_good TINYINT(1)NULL DEFAULT 1 ,', ...
  'PRIMARY KEY (unit_id) ,', ...
  'UNIQUE INDEX unit_id_UNIQUE (unit_id ASC))', ...
  'COMMENT = "Features of rate-intensity functions based on analysis_rif table"']);



%%
function h = UpdateRIFFeatures(feature,h)
rif = h.rif;

feature = char(feature);

switch feature
    case 'bestlevel'
        [rif.FEATURES.maxresponse,b] = max(rif.poststim_meanfr); 
        rif.FEATURES.bestlevel = rif.level(b);
        
    case 'threshold'
        [a,~] = ginput(1);
        a = interp1(rif.level,rif.level,a,'nearest');
        rif.FEATURES.threshold = a;
        
    case 'statthreshold'
        sind = rif.ks_p < 0.025;
        sind = flipud(sind);
        didx = find(sind(2:end) < sind(1:end-1));
        if ~isempty(didx)
            rif.FEATURES.threshold = rif.level(didx);
        end
        
    case 'transition'
        [a,~] = ginput(1);
        a = interp1(rif.level,rif.level,a,'nearest');
        rif.FEATURES.transitionpoint = a;
        if a == max(rif.level)
            p = 0;
        else
            p = polyfit(rif.level(rif.level>=a),rif.poststim_meanfr(rif.level>=a),1);
        end
        rif.FEATURES.slope = p(1);
end
h.rif = rif;
guidata(h.RIF_analysis,h);
updateplot(feature,h);

function updateplot(tag,h) 
tag = char(tag);

rif = h.rif;

ax = h.axes1;
switch tag
    case 'rif'
        cla(ax)
        plot(ax,rif.level,rif.poststim_meanfr,'-o', ...
            'color',[0.2 0.2 0.2],'markersize',10,'markerfacecolor',[0.6 0.6 0.6]);
        grid(ax,'on');
        hold(ax,'on');
        plot(ax,xlim,[0 0],'-k','linewidth',3);
        hold(ax,'off');
        xlabel('Sound Level (dB SPL)');
        ylabel('Firing Rate (Hz)');
        title(sprintf('Unit #%d',rif.unit_id));
        
        set(h.bestlevel,'String','Best level:')
        set(h.threshold,'String','Threshold:')
        set(h.transition,'String','Transition Point:')
        set(h.slope,'String','Slope:')
        
    case 'bestlevel'
        hold(ax,'on');

        plot(ax,rif.FEATURES.bestlevel,rif.FEATURES.maxresponse,'o', ...
            'color',[0.2 0.2 0.2],'markersize',10,'markerfacecolor',[240 160 160]/255);
        hold(ax,'off');
        set(h.bestlevel,'string',sprintf('Best level: %d dB SPL',rif.FEATURES.bestlevel));

    case 'threshold'
        hold(ax,'on');
        do = findobj(ax,'color','c','-and','marker','v');
        if ~isempty(do), delete(do); end
        oc = get(h.threshold,'backgroundcolor');
        set(h.threshold,'backgroundcolor','g');
        plot(ax,rif.FEATURES.threshold,rif.poststim_meanfr(rif.FEATURES.threshold==rif.level), ...
            'vc','markersize',10,'linewidth',3);
        hold(ax,'off');
        set(h.threshold,'backgroundcolor',oc, ...
            'string',sprintf('Threshold: %d dB SPL',rif.FEATURES.threshold));
        
    case 'transition'
        hold(ax,'on');
        do = findobj(ax,'color','g','-and','marker','^');
        if ~isempty(do), delete(do); end
        oc = get(h.threshold,'backgroundcolor');
        set(h.(tag),'backgroundcolor','g');

        plot(ax,rif.FEATURES.transitionpoint,rif.poststim_meanfr(rif.FEATURES.transitionpoint == rif.level), ...
            '^g','markersize',10,'linewidth',3);
        
        do = findobj(ax,'color','r');
        if ~isempty(do), delete(do); end
        
        a = rif.FEATURES.transitionpoint;
        if a == max(rif.level)
            p = 0;
            y = [rif.poststim_meanfr(end) rif.poststim_meanfr(end)];
        else
            p = polyfit(rif.level(rif.level>=a),rif.poststim_meanfr(rif.level>=a),1);
            y = polyval(p,[a max(rif.level)]);
        end
        plot(ax,[a max(rif.level)],y,':r','linewidth',3);
        hold(ax,'off');
        set(h.transition,'backgroundcolor',oc, ...
             'string',sprintf('Transition Point: %d dB SPL',rif.FEATURES.transitionpoint));
        set(h.slope,'string',sprintf('Slope: % 2.3f',p(1)));

end
