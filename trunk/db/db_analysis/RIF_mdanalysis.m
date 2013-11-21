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

win = [-0.02 0.1];
binsize = 0.001;

[psth,vals] = shapedata_spikes(h.RF.st,h.RF.P,{'Levl'},'win',[-win(2) win(2)],'binsize',binsize);

mp = max(psth(:));
v = window(@gausswin,5);
cpsth = zeros(size(psth));
for i = 1:size(psth,2)
    cpsth(:,i) = conv(psth(:,i),v,'same');
end
cpsth = cpsth / max(cpsth(:)) * mp;

A = PSTHstats(cpsth,vals{1},'prewin',[-0.02 0], ...
    'rspwin',[0.005 0.08],'alpha',0.001);


h.ax1 = gca;
cla(h.ax1);

PlotRaster(h.ax1,h,win);
PlotPSTH(h.ax1,cpsth,vals,A);



function PlotPSTH(ax,psth,vals,A)
axes(ax);

hold(ax,'on');
mdv = max(diff(vals{2}));
mpsth = max(psth(:));
spsth = psth/mpsth*mdv;
for i = 1:size(psth,2)
    yoffset = vals{2}(i);
    
    if ~isnan(A.response.rejectnullh(i)) && A.response.rejectnullh(i)
        c = [0 0 0];
    else
        c = [0.6 0.6 0.6];
    end
    plot(vals{1},yoffset+spsth(:,i),'-','color',c,'linewidth',2);
    
    if ~isnan(A.peak.rejectnullh(i)) && A.peak.rejectnullh(i)
        peakmag = A.peak.magnitude(i);
        plot(A.peak.latency(i),yoffset+peakmag/mpsth*mdv,'*r');
    end
    
    if ~isnan(A.response.rejectnullh(i)) && A.response.rejectnullh(i)
        plot([A.onset.pk10(i) A.offset.pk10(i)],yoffset+peakmag*[0.10 0.10]/mpsth*mdv,'-r', ...
             [A.onset.pk50(i) A.offset.pk50(i)],yoffset+peakmag*[0.50 0.50]/mpsth*mdv,'-g', ...
             [A.onset.pk90(i) A.offset.pk90(i)],yoffset+peakmag*[0.90 0.90]/mpsth*mdv,'-b', ...
             'linewidth',2);
    end
    plot(vals{1}([1 end]),[yoffset yoffset],'-','color',[0.3 0.3 0.3],'linewidth',0.5);


end
ylim([vals{2}(1) vals{2}(end)+max(diff(vals{2}))]);
plot(ax,[0 0],ylim(ax),'-k');

hold(ax,'off');
box(ax,'on');

ud.psth = psth;
ud.vals = vals;
set(ax,'userdata',ud);



function PlotRaster(ax,h,win)
axes(ax);
% cla(ax)

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
% for i = 1:length(uL)
%     if ~A.response.rejectnullh(i), continue; end
% %     plot(A.onset(i),uL(i),'>',A.offset(i),uL(i),'<','color',[0.5 0.8 0.9],'markersize',5,'markerfacecolor',[0.5 0.8 0.9]);
% %     plot([A.onset(i) A.offset(i)],[uL(i) uL(i)],'-','color',[0.5 0.8 0.9],'linewidth',2);
%     patch([A.onset(i) A.onset(i) A.offset(i) A.offset(i)],[uL(i) uL(i)+dL uL(i)+dL uL(i)], ...
%         [0.9 0.97 1.0],'EdgeColor',[0.9 0.97 1.0]);
%         
% end
for i = 1:length(rast)
    if isempty(rast{i}), continue; end
    md = mod(i,nreps)/nreps*dL;
    plot(rast{i},L(i) + md,'s','color',[0.3 0.3 0.3], ...
        'markersize',1,'markerfacecolor',[0.3 0.3 0.3]);
end

plot(repmat(win,length(uL),1)',[uL uL]','-k');
plot([0 0],[uL(1) uL(end)+dL],'-','color',[0.3 0.3 0.3]);
hold(ax,'off');
box(ax,'on');
d.rast = rast;
d.vals = L;
set(ax,'UserData',d,'clipping','off');
xlim(win); ylim([uL(1) uL(end)+dL]);

%%



























