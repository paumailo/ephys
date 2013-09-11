function varargout = RF_analysis(varargin)
% RF_analysis
% RF_analysis(unit_id)
%
% Two-dimensional receptive field analysis using features of single or
% multiple contours.
%
% See also, RIF_analysis
% 
% Daniel.Stolzberg@gmail.com 2013


% Last Modified by GUIDE v2.5 06-Sep-2013 10:00:08

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @RF_analysis_OpeningFcn, ...
                   'gui_OutputFcn',  @RF_analysis_OutputFcn, ...
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


% --- Executes just before RF_analysis is made visible.
function RF_analysis_OpeningFcn(hObj, ~, h, varargin)
h.output = hObj;


if length(varargin) == 1
    h.unit_id = varargin{1};
else
    h.unit_id = getpref('DB_BROWSER_SELECTION','units');
end

h = InitializeRF(h);

h = UpdatePlot(h);

guidata(hObj, h);



% --- Outputs from this function are returned to the command line.
function varargout = RF_analysis_OutputFcn(hObj, ~, h)  %#ok<INUSL>
varargout{1} = h.output;





















%% GUI functions
function h = InitializeRF(h)
ID = mym('SELECT block FROM v_ids WHERE unit = {Si}',h.unit_id);
P  = DB_GetParams(ID.block);

ind = ~ismember(P.param_type,{'onset','offset','prot'});
set(h.opt_dimx,'String',P.param_type(ind));
set(h.opt_dimy,'String',P.param_type(ind));
set(h.opt_numfields,'String',num2str((0:10)','%d'));

optnames = {'opt_dimx','opt_dimy','opt_xscalelog','opt_threshold', ...
    'opt_smooth2d','opt_interp','opt_cwinon','opt_cwinoff','opt_numfields', ...
    'opt_viewsurf'};
optdefs = {'Freq','Levl',1,'2',1,1,'0','50','1',2};
opts = getpref('RF_analysis_opts',optnames,optdefs);


for i = 1:length(opts)
    if ~(isfield(h,optnames{i}) && ishandle(h.(optnames{i}))), continue; end
    ho = h.(optnames{i});
    style = get(ho,'Style');
    switch style
        case 'checkbox'
            set(ho,'Value',opts{i});
        case 'popupmenu'
            ind = ismember(cellstr(get(ho,'String')),opts{i});
            if any(ind)
                set(ho,'Value',find(ind));
            else
                set(ho,'Value',1);
            end
        case 'edit'
            set(ho,'String',opts{i});
    end
end

IDs = mym('SELECT * FROM v_ids WHERE unit = {Si}',h.unit_id);
h.UNIT.IDs         = IDs;
h.UNIT.spiketimes  = DB_GetSpiketimes(h.unit_id);
h.UNIT.blockparams = DB_GetParams(IDs.block);
h.UNIT.unitprops   = DB_GetUnitProps(h.unit_id,'RF$');









function UpdateOpts(hObj,h) %#ok<DEFNU>
switch get(hObj,'Style')
    case 'checkbox'
        setpref('RF_analysis_opts',get(hObj,'Tag'),get(hObj,'Value'));
    case 'edit'
        setpref('RF_analysis_opts',get(hObj,'Tag'),get(hObj,'String'));
    case 'popupmenu'
        setpref('RF_analysis_opts',get(hObj,'Tag'),get_string(hObj));
end

h = UpdatePlot(h);

guidata(h.figure1,h);






%% Plotting functions
function Cs = UpdateContours(axM,RF,nFields,nstd)
critval = RF.spontmean + RF.spontstd * nstd;

[C,ch] = contour3(axM,RF.xvals,RF.yvals,RF.data,[critval critval]);
set(ch,'EdgeColor',[0.4 0.4 0.4],'LineWidth',2)

if isempty(C)
    Cs.id = [];
    Cs.contour = [];
    Cs.h = [];
    return
end

Cc = CutContours(C);
m = cellfun(@length,Cc);

% find largest contour(s)
[~,k] = sort(m,'descend');
Cc = Cc(k);
ch = ch(k);
if length(Cc) > nFields
    Cc(nFields+1:end) = [];
    delete(ch(nFields+1:end))
    ch(nFields+1:end) = [];
end

for i = 1:length(Cc)
    Cs(i).id      = i;     %#ok<AGROW>
    Cs(i).contour = Cc{i}; %#ok<AGROW>
    Cs(i).h       = ch(i); %#ok<AGROW>
end







function h = UpdatePlot(h)

h.RFfig = findobj('tag','RFfig');
if isempty(h.RFfig)
    h.RFfig = figure('tag','RFfig');
else
    ax = findobj(h.RFfig,'tag','MainAxes');
    opt_viewsurf = get(ax,'View');
    setpref('RF_analysis_opts','opt_viewsurf',opt_viewsurf);
end


IDs = h.UNIT.IDs;
st  = h.UNIT.spiketimes;
P   = h.UNIT.blockparams;

opts = getpref('RF_analysis_opts');

dimx = opts.opt_dimx;
dimy = opts.opt_dimy;

win(1) = str2num(get(h.opt_cwinon,'String')); %#ok<ST2NM>
win(2) = str2num(get(h.opt_cwinoff,'String')); %#ok<ST2NM>

[data,vals] = shapedata_spikes(st,P,{dimy,dimx},'binsize',0.001, ...
    'win',win/1000,'func','sum');

data = data * 1000; % rescale data

% estimate spontaneous activity
spnt = shapedata_spikes(st,P,{dimy,dimx},'binsize',0.001, ...
    'win',[-0.01 0],'func','sum');
spnt = spnt * 1000; % rescale spont
spnt = squeeze(mean(spnt));


% if wants2d
    data = squeeze(mean(data));
% else
    
% end

Nd = ndims(data);
xdim = Nd;
ydim = Nd - 1;
tdim = Nd - 2;

tvals = vals{1};
yvals = vals{2};
xvals = vals{3};


if opts.opt_smooth2d
    % 2D Wiener denoising may work better than S-G filtering
    data = sgsmooth2d(data);
    spnt = sgsmooth2d(spnt);
end

if opts.opt_interp
    data = interp2(data,3,'cubic');
    spnt = interp2(spnt,3,'cubic');
    xvals = interp1(xvals,linspace(1,length(xvals),size(data,xdim)),'linear');
    if opts.opt_xscalelog
        yvals = interp1(logspace(log10(1),log10(length(yvals)),length(yvals)), ...
            yvals,logspace(log10(1),log10(length(yvals)),size(data,ydim)),'pchip');
    else
        yvals = interp1(yvals,linspace(1,length(yvals),size(data,ydim)),'linear');
    end
else
    % for consistency of dimensions
    xvals = xvals';
    yvals = yvals';
end



figure(h.RFfig);
clf(h.RFfig);
set(h.RFfig,'Name',sprintf('Unit %d',IDs.unit),'NumberTitle','off', ...
    'HandleVisibility','on','units','normalized')


axM = subplot('Position',[0.1  0.1  0.6  0.6],'Parent',h.RFfig,'NextPlot','Add','Tag','MainAxes');
axX = subplot('Position',[0.1  0.75 0.6  0.1],'Parent',h.RFfig,'NextPlot','Add','Tag','SumX');
axY = subplot('Position',[0.75 0.1  0.2  0.6],'Parent',h.RFfig,'NextPlot','Add','Tag','SumY');

surf(axM,xvals,yvals,data)

% crossection of receptive field
crsX  = mean(data,ydim);
scrsX = mean(spnt,ydim);
plot(axX,xvals,crsX,'-k','linewidth',2)
plot(axX,xvals,scrsX,':','color',[0.6 0.6 0.6]);

set([axM axX axY],'box','on');
set([axM axY],'xgrid','on','ygrid','on','zgrid','on');

view(axM,opts.opt_viewsurf);
shading(axM,'interp')

set([axM axX],'xlim',[xvals(1) xvals(end)]);
set([axM axY],'ylim',[yvals(1) yvals(end)]);
set(axM,'zlim',[0 max(data(:))]);
if opts.opt_xscalelog
    set([axM axX],'xscale','log');
else
    set([axM axX],'xscale','linear');
end

set(axX,'xaxislocation','top','yaxislocation','right');
set(axY,'xaxislocation','bottom','yaxislocation','right');

xlabel(axM,dimx);  ylabel(axM,dimy); zlabel(axM,'Firing Rate (Hz)');
ylabel(axY,dimy);
ylabel(axX,'mean');

UD.IDs   = IDs;
UD.data  = data;
UD.spnt  = spnt;
UD.spontmean = mean(spnt(:));
UD.spontstd  = std(spnt(:));
UD.opts  = opts;
UD.tvals = tvals;   UD.tdim  = tdim;
UD.xvals = xvals;   UD.xdim  = xdim;
UD.yvals = yvals;   UD.ydim  = ydim;

Cdata = UpdateContours(axM,UD,str2num(opts.opt_numfields),str2num(opts.opt_threshold)); %#ok<ST2NM>

if ~isempty(Cdata(1).id)
    for i = 1:length(Cdata)
        Cdata(i).mask     = ContourMask(Cdata(i).contour,xvals,yvals);
        Cdata(i).Features = ComputeResponseFeatures(data,Cdata(i),xvals,yvals);
        PlotFeatures(axM,axY,data,Cdata(i),xvals,yvals);
    end
end
UD.Cdata = Cdata;

set(axM,'UserData',UD);

h.RFax_main = axM;
h.RFax_crsX = axX;
h.RFax_crsY = axY;
h.RFax_ch = [Cdata.h];



function PlotFeatures(axM,axY,data,Cdata,xvals,yvals)
F = Cdata.Features;
E = F.EXTRAS;

hold(axM,'on');

xi = interp1(xvals,xvals,F.charfreq,'nearest');
yi = interp1(yvals,yvals,F.minthresh,'nearest');
dz = data(yi==yvals,xi==xvals);
plot3(axM,F.charfreq,F.minthresh,dz,'*m','linewidth',2,'markersize',10);

dz = data(yvals==F.bestlevel,xvals==F.bestfreq);
plot3(axM,F.bestfreq,F.bestlevel,dz,'*','linewidth',2,'markersize',10, ...
    'color',[0.8 0.8 0.8]);

hold(axM,'off');

ccodes = lines(10);
ccode = ccodes(Cdata.id,:);

hold(axY,'on');
if ~isempty(E.Qs)
    plot(axY,E.Qs,E.BWy,'-o','color',[0 0 0],'markersize',8, ...
        'markerfacecolor',ccode,'LineWidth',2,'Clipping','off')
end

legend(axY,{'Q vals'},'location','SouthWest')
hold(axY,'off');

% Lfxi = interp1(xvals,xvals,E.bwLf,'nearest');
% Hfxi = interp1(xvals,xvals,E.bwHf,'nearest');
% x = [Lfxi; Hfxi];
% 
% bwyi = interp1(yvals,yvals,E.bwyvals,'pchip');
% dz   = data(ismember(yvals,bwyi),ismember(xvals,x));
% bwyi = [bwyi; bwyi];
% 
% plot3(ax,x,dz,'-m','linewidth',2);







%% Analysis functions
function F = ComputeResponseFeatures(data,Cdata,xvals,yvals)
mdata = nan(size(data));
mdata(Cdata.mask) = data(Cdata.mask);


[F.minthresh,cfi] = min(Cdata.contour(2,:));  % minimum threshold
F.charfreq = Cdata.contour(1,cfi);            % characteristic frequency
F.EXTRAS.cfio = data(:,cfi); %*CharFreq IO function

[F.maxrate,bfi] = max(mdata(:));         % max rate
[bfi,bfj] = ind2sub(size(mdata),bfi);
F.bestfreq    = xvals(bfj);                   % best frequency
F.bestlevel   = yvals(bfi);                   % best response level
F.EXTRAS.bfio = data(:,bfj); %*BestFreq IO function

% compute bandwidths at 5dB steps above minimum threshold
bwlevel = F.minthresh+5:5:max(yvals);
BWy = interp1(yvals,yvals,bwlevel,'nearest');
Lfbw = []; Hfbw = []; F.EXTRAS.Qs = [];
for i = 1:length(BWy)
    yind = BWy(i) == yvals;
    if ~any(Cdata.mask(yind,:)), break; end
    Lfind = find(Cdata.mask(yind,:),1,'first'); Lfbw(i) = xvals(Lfind); %#ok<AGROW>
    Hfind = find(Cdata.mask(yind,:),1,'last');  Hfbw(i) = xvals(Hfind); %#ok<AGROW>
    BW = Hfbw(i) - Lfbw(i);
    Q  = F.charfreq ./ BW;
    F.(sprintf('BW%02ddB',i*5))     = BW;
    F.EXTRAS.(sprintf('Q%ddB',i*5)) = Q;
    F.EXTRAS.Qs(i) = Q;
end
F.EXTRAS.BWy     = BWy;
F.EXTRAS.bwLf    = Lfbw;
F.EXTRAS.bwHf    = Hfbw;
F.EXTRAS.bwyvals = bwlevel;



function mask = ContourMask(C,xvals,yvals)
% mask 2D data matrix within the bounds defined by contour C
yi = interp1(yvals,yvals,C(2,:),'nearest');

[~,inflcty] = min(C(2,:));
LfC = C(:,1:inflcty);        Lfyi = yi(1:inflcty);
HfC = C(:,inflcty+1:end);    Hfyi = yi(inflcty+1:end);


mask = true(length(yvals),length(xvals));

for i = 1:size(LfC,2)
    a = Lfyi(i) == yvals;
    mask(a,:) = mask(a,:) & xvals >= LfC(1,i);
end

for i = 1:size(HfC,2)
    a = Hfyi(i) == yvals;
    mask(a,:) = mask(a,:) & xvals <= HfC(1,i);
end

v = min(yi);
mask(yvals<v,:) = false;


function Cs = CutContours(C)
% cut ContourMatrix C into separate contours
Cs = []; 
if isempty(C), return; end
i = 1; k = 1;
n = size(C,2);
while true
    v = C(2,k);
    Cs{i} = C(:,k+1:k+v); %#ok<AGROW>
    % make sure low x-vals come first on contour
    if Cs{i}(1,1) > Cs{i}(1,end)
        Cs{i} = fliplr(Cs{i}); %#ok<AGROW>
    end
    k = k + v + 1;
    if k > n, break; end
    i = i + 1;
end





function UpdateDB(h) %#ok<DEFNU>

axM = h.RFax_main;

UD = get(axM,'UserData');

if isempty(UD) ||  ~isfield(UD,'Cdata'), return; end

i = 1;
for bw = 5:5:100;
    BWn{i} = sprintf('BW%02ddB',bw); %#ok<AGROW>
    BWd{i} = sprintf('Frequency bandwidth (in Hz) at %d dB above minimum threshold',bw); %#ok<AGROW>
    i = i + 1;
end

n = {'bestfreq','charfreq','minthresh','rftype','spontrate','maxrate','bestlevel'};
d = {'Best Frequency','Characteristic Frequency','Minimum Threshold', ...
'Receptive Field Type','Spontaneous Firing Rate','Maximum Firing Rate in RF', ...
'Best response level'};
n = [n BWn];
d = [d BWd];
DB_CheckAnalysisParams(n,d);


Cdata = UD.Cdata;

for i = 1:length(Cdata)
    cf = Cdata(i).Features;
    R.identity{i}   = sprintf('RFid%02d',Cdata(i).id);
    R.bestfreq(i)   = cf.bestfreq;
    R.charfreq(i)   = cf.charfreq;
    R.minthresh(i)  = cf.minthresh;
    R.spontrate(i)  = UD.spontmean;
    R.maxrate(i)    = cf.maxrate;
    R.bestlevel(i)  = cf.bestlevel;
    %     R.rftype(i)     = c.rftype;
    for j = 1:length(cf.EXTRAS.BWy)
        bwfn = sprintf('BW%02ddB',j*5);
        R.(bwfn)(i) = cf.(bwfn);
    end
end

DB_UpdateUnitProps(h.unit_id,R,'identity',true);









