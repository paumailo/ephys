function varargout = DB_PlotPSTH(unit_id,varargin)
% varargout = DB_PlotPSTH(unit_id,varargin)

% defaults
binsize   = 0.001;
shapefunc = 'mean';
win       = [-0.05 0.1];
kernel    = gausswin(5); %#ok<NASGU>
convolve  = false;
fh        = [];


ParseVarargin({'fh','rwin','bwin','convolve','kernel','type',...
    'upsample','plotresult','binsize','shapefunc'}, ...
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
            'upsample',upsample,'type',type,'alpha',alpha);
        r.unit_id(i)         = unit_id;
        r.level(i)           = vals{1};
        r.onset_latency(i)   = t.onset.latency;
        r.rising_slope(i)    = t.onset.slope;
        r.offset_latency(i)  = t.offset.latency;
        r.falling_slope(i)   = t.offset.slope;
        r.peak_latency(i)    = t.peak.latency;
        r.area(i)            = t.area;
        r.ks_p_value(i)      = t.stats.p;
        r.ks_stat(i)         = t.stats.ksstat;
        r.prestim_meanfr(i)  = t.baseline.meanfr;
        r.poststim_meanfr(i) = t.response.meanfr;
    end
end
R = r;

if isempty(fh) || ~ishandle(fh), fh = figure; end

origpos = get(fh,'position');

figure(fh);
clf(fh);
set(fh,'Name',sprintf('Unit %d',unit_id),'NumberTitle','off', ...
    'HandleVisibility','on','Renderer','Painters');

numL = length(R.level);

for i = 1:numL
    h(i) = subplot(numL,1,i); %#ok<AGROW>
    bar(vals{1},data(:,i));
    ylabel(vals{2}(i))
end
xlabel(h(end),'time (s)');

y = cell2mat(get(h,'ylim'));
y = [0 max(y(:))];
set(h(1:end-1),'xticklabel',[],'ylim',y)

for i = 1:numL
    hold(h(i),'on');
    
    plot(h(i),[0 0],y,'-k');
    
    if R.ks_p_value(i) < 0.025 && R.onset_latency(i) > 0
        plot(h(i),[R.onset_latency(i) R.onset_latency(i)],y,  ':g','linewidth',2)
        plot(h(i),[R.offset_latency(i) R.offset_latency(i)],y,':g','linewidth',2)
        plot(h(i),R.peak_latency(i),R.peak_value(i),'*g','markersize',8,'linewidth',1)
    end
    
    hold(h(i),'off');
end

set(fh,'position',origpos);


varargout{1} = fh;
varargout{2} = h;
varargout{3} = R;
varargout{4} = {data,vals};



























