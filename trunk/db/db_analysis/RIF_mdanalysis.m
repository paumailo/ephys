function RIF_mdanalysis(unit_id)
%%

if nargin == 0 || isempty(unit_id)
    unit_id = getpref('DB_BROWSER_SELECTION','units');
end

f = findobj('tag','RF_FreqVsTime');
if isempty(f)
f = figure('Color',[0.98 0.98 0.98],'tag','RF_FreqVsTime');
end
figure(f);
clf(f);
set(f,'Name',sprintf('Unit ID: %d',unit_id),'units','normalized');

h.RF.P  = DB_GetParams(unit_id,'unit');
h.RF.st = DB_GetSpiketimes(unit_id);

guidata(f,h);

win = [-0.1 0.1];
binsize = 0.001;

[psth,vals] = shapedata_spikes(h.RF.st,h.RF.P,{'Levl'},'win',[-win(2) win(2)],'binsize',binsize);

A = PSTHstats(psth,vals{1},'prewin',[-0.1 0],'rspwin',[0 0.1],'alpha',0.01);

h.ax1 = subplot(121);
h.ax2 = subplot(122);

PlotRaster(h.ax1,h,win,A);
Plot2dPSTH(h.ax2,psth,vals,A);



function Plot2dPSTH(ax,psth,vals,A)
v = window(@gausswin,5);
for i = 1:size(psth,2)
    psth(:,i) = conv(psth(:,i),v,'same');
end

axes(ax);
cla(ax)

hold(ax,'on');
mdv = max(diff(vals{2}));
mpsth = max(psth(:));
spsth = psth/mpsth*mdv;
for i = 1:size(psth,2)
    yoffset = vals{2}(i);
    plot(vals{1}([1 end]),[yoffset yoffset],'-','color',[0.3 0.3 0.3],'linewidth',0.5);
    y = vals{2}(i)+spsth(:,i);
    if A.response.rejectnullh(i)
        c = [0 0 0];
    else
        c = [0.6 0.6 0.6];
    end
    plot(vals{1},y,'-','color',c,'linewidth',2);
    
    if A.peak.rejectnullh(i)
        plot(A.peak.latency(i),yoffset+A.peak.magnitude(i)/mpsth*mdv,'*r');
    end
    
    if A.response.rejectnullh(i)
        plot([A.onset(i) A.offset(i)],[yoffset yoffset],'-b','linewidth',2);
        plot(A.onset(i),yoffset,'>b',A.offset(i),yoffset,'<b','markerfacecolor','b');
    end
end
ylim([vals{2}(1) vals{2}(end)+max(diff(vals{2}))]);
plot(ax,[0 0],ylim(ax),'-k');

hold(ax,'off');
box(ax,'on');

ud.psth = psth;
ud.vals = vals;
set(ax,'userdata',ud);



function PlotRaster(ax,h,win,A)
axes(ax);
cla(ax)

VALS = h.RF.P.VALS;
st   = h.RF.st;

nreps = sum(VALS.Levl == VALS.Levl(1));
[L,idx] = sort(VALS.Levl);
uL = unique(L);
dL = mean(diff(uL));
ons  = VALS.onset(idx);
wons = ons + win(1);
wofs = ons + win(2);
rast = cell(size(ons));
for i = 1:length(ons)
    sind = st >= wons(i) & st <= wofs(i);
    rast{i} = st(sind) - ons(i);
end

hold(ax,'on');
for i = 1:length(rast)
    if isempty(rast{i}), continue; end
    md = mod(i,nreps)/nreps*dL;
    plot(rast{i},L(i) + md,'sk','markersize',1,'markerfacecolor','k');
end
plot(repmat(win,length(uL),1)',[uL uL]','-k');
plot([0 0],[uL(1) uL(end)],'-','color',[0.3 0.3 0.3]);
hold(ax,'off');
box on
d.rast = rast;
d.vals = L;
set(ax,'UserData',d);
xlim(win); ylim([uL(1) uL(end)]);

%%



























