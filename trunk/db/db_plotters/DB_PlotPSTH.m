function varargout = DB_PlotPSTH(unit_id,varargin)
% varargout = DB_PlotPSTH(unit_id,varargin)

% defaults
binsize   = 0.001;
shapefunc = 'mean';
win       = [-0.05 0.1];
kernel    = gausswin(5); %#ok<NASGU>
convolve  = false;
fh        = [];
resamp    = 1;
kstype    = 'unequal';
ksalpha   = 0.05;

ParseVarargin({'fh','rwin','bwin','convolve','kernel','kstype','ksalpha',...
    'resamp','plotresult','binsize','shapefunc'}, ...
    [],varargin);

block_id = myms(sprintf(['SELECT c.block_id FROM channels c ', ...
                 'INNER JOIN units u ON u.channel_id = c.id ', ...
                 'WHERE u.id = %d'],unit_id));

st = DB_GetSpiketimes(unit_id);
p  = DB_GetParams(block_id);

[data,vals] = shapedata_spikes(st,p,{'Levl'},'win',win,'binsize',binsize,'func',shapefunc);

if convolve
    for i = 1:size(data,2) %#ok<UNRCH>
        mv = max(data(:,i));
        data(:,i) = conv(data(:,i),kernel,'same');
        data(:,i) = data(:,i) / max(data(:,i)) * mv;
    end
end

r = mym('SELECT * FROM analysis_rif WHERE unit_id = {Si}',unit_id);
if isempty(r.unit_id)
    for i = 1:size(data,2)
        t = ComputePSTHfeatures(vals{1},data(:,i),'rwin',rwin,'bwin',bwin, ...
            'resamp',resamp,'kstype',kstype,'ksalpha',ksalpha);
        r.unit_id(i)         = unit_id;
        r.level(i)           = vals{2}(i);
        r.onset_latency(i)   = t.onset.latency;
        r.rising_slope(i)    = t.onset.slope;
        r.offset_latency(i)  = t.offset.latency;
        r.falling_slope(i)   = t.offset.slope;
        r.peak_fr(i)         = t.peak.fr;
        r.peak_latency(i)    = t.peak.latency;
        r.histarea(i)        = t.histarea;
        r.ks_p(i)      = t.stats.p;
        r.ks_stat(i)         = t.stats.ksstat;
        r.prestim_meanfr(i)  = t.baseline.meanfr;
        r.poststim_meanfr(i) = t.response.meanfr;
    end
end
R = r;

if isempty(fh) || ~ishandle(fh), fh = figure; end

figure(fh);
clf(fh);
set(fh,'Name',sprintf('Unit %d',unit_id),'NumberTitle','off', ...
    'HandleVisibility','on','Renderer','Painters','units','normalized');

origpos = get(fh,'position');

data = data / binsize; % convert to mean firing rate


numL = length(R.level);
for i = 1:numL
    h(i) = subplot(numL,1,i); %#ok<AGROW>
    bar(vals{1},data(:,i),'EdgeColor',[0.3 0.3 0.3],'FaceColor',[0.6 0.6 0.6]);
    ylabel(vals{2}(i),'Color',[0 0 1]*double(R.ks_p(i)<0.025));
end
xlabel(h(end),'time (s)');
axis(h,'tight');


y = [0 max(data(:))];
set(h(1:end-1),'xticklabel',[],'ylim',y)
set(h,'TickLength',[0.005 0.01]);

for i = 1:numL
    hold(h(i),'on');
    
    plot(h(i),[0 0],y,'-k');
    
    if R.ks_p(i) < 0.025 && R.onset_latency(i) > 0
%         plot(h(i),[R.onset_latency(i) R.onset_latency(i)],y,  ':g','linewidth',2)
%         plot(h(i),[R.offset_latency(i) R.offset_latency(i)],y,':g','linewidth',2)
        plot(h(i),[R.onset_latency(i) R.offset_latency(i)],[0 0],'-*g','linewidth',2);

        pkval = interp1(vals{1},data(:,i),R.peak_latency(i),'nearest');
        plot(h(i),R.peak_latency(i),pkval,'dg', ...
            'markerfacecolor','g','markersize',5,'linewidth',2)
    end
    
    astr = sprintf(['Onset:  % 3.0fms | Base FR: %0.0fHz\n', ...
                    'Peak:   % 3.0fms | Resp FR: %0.0fHz\n', ...
                    'Offset: % 3.0fms | Peak FR: %0.0fHz\n', ...
                    'Resp Duration: % 3.0fms'], ...
        R.onset_latency(i)*1000,    R.prestim_meanfr(i), ...
        R.peak_latency(i)*1000,     R.poststim_meanfr(i), ...
        R.offset_latency(i)*1000,   R.peak_fr(i), ...
        1000*(R.offset_latency(i) - R.onset_latency(i)));
    
    p = get(h(i),'position');
    annotation('textbox',[p(1),p(2)+p(4)-0.25*p(4) 0.4*p(3) 0.25*p(4)], ...
        'string',astr,'FitHeightToText','off','LineStyle','none','fontsize',6);
    
    
    
    hold(h(i),'off');
end

set(fh,'position',origpos);


varargout{1} = fh;
varargout{2} = h;
varargout{3} = R;
varargout{4} = {data,vals};



























