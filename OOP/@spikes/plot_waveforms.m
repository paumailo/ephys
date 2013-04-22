function varargout = plot_waveforms(obj,varargin)
%  plot_waveforms(unitid)
%  plot_waveforms(unitid,style)
%  plot_waveforms(ax,...)
%  h = plot_waveforms(...)

style  = 'density'; % default
ax = gca;

switch length(varargin)
    case 1
        unitid = varargin{1};
    case 2
        if ischar(varargin{end})
            unitid = varargin{1};
            style  = varargin{2};
        else
            ax     = varargin{1};
            unitid = varargin{2};
        end
    case 3
        ax     = varargin{1};
        unitid = varargin{2};
        style  = varargin{3};
    otherwise
        error('plot_waveforms:This function requires 2 or 3 inputs')
end

uind = subset(obj,unitid);
W = obj.waveforms(uind,:);
if isempty(W)
    fprintf('No waveforms found for unit %d\n',unitid)
    varargout{1} = [];
    return
end
W = W * 1000; % V -> mV

svec = 1:size(obj.waveforms,2);

if isnumeric(unitid)
    unitid = obj.unitstr{unitid};
end
titlestr = sprintf('%s (%0.0f)',unitid,sum(uind));

cla(ax,'reset');

switch lower(style)
    case 'mean'
        mw = mean(W);
        sw = std(W);
        hold(ax,'on');
        h(1) = plot(ax,svec,mw+sw,'-k','linewidth',1);
        h(2) = plot(ax,svec,mw,'-k','linewidth',2);
        h(3) = plot(ax,svec,mw-sw,'-k','linewidth',1);
        hold(ax,'off');
        grid on
        y = max(abs(ylim(ax)));
        axis(ax,[svec(1) svec(end) -y y]);
        
    case 'banded'
        mw = mean(W);
        sw = std(W);
        bw = [mw+sw, fliplr(mw-sw)];
        sv = [svec,  fliplr(svec)];
        h = fill(sv,bw,'b','EdgeColor','b');
        grid on
        y = max(abs(ylim(ax)));
        axis(ax,[svec(1) svec(end) -y y]);
        
    case 'density'
        y = max(abs(W(:)))*0.75;
        y = linspace(-y,y,2*size(W,2));
        bcnt = histc(W,y);
        bcnt = bcnt ./ max(bcnt(:));
        bcnt = interp2(bcnt,3,'cubic');
        h = imagesc(svec,y,bcnt);
        set(ax,'ydir','normal','clim',[0 1]);
        box(ax,'on');
        
    case 'sampling'
        ridx = randperm(size(W,1));
        h = plot(svec,W(ridx(1:round(length(ridx)*0.1)),:));
        grid on
        y = max(abs(ylim(ax)));
        axis(ax,[svec(1) svec(end) -y y]);
        
    otherwise
        error('plot_wavforms:Undefined plot style ''%s''',style)
end

ylabel(ax,'Amplitude (mV)');
xlabel(ax,'Samples');
title(ax,titlestr,'interpreter','none');

varargout{1} = h;