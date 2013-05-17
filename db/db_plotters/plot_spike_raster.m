function plot_spike_raster(pref,P,param,cfg)
% plot_spike_raster(pref,P,param,cfg)
% 
% For use with DB_QuickPlot
%
% DJS 2013

% get spike times of selected unit
S = DB_GetSpiketimes(pref.units);

nrows = cfg.nrows;
ncols = cfg.ncols;

win = [cfg.win_on cfg.win_off] / 1000; % ms -> s

% Organize by stimulus onsets
ons = P.VALS.onset;

TS = cell(size(ons));
for i = 1:length(ons)
    ind = S >= ons(i) + win(1) & S < ons(i) + win(2);
    TS{i} = S(ind) - ons(i);
end

% Reorganize by stimulus type
largestdim = 1;
for i = 1:length(param)
    st{i} = sort(P.lists.(param{i}),'descend'); %#ok<AGROW>
    if length(st{i}) > length(st{largestdim})
        largestdim = i;
    end
end
if largestdim == 1, smallestdim = 2; else smallestdim = 1; end

% Plot by stimulus type
RF = cell(size(st{largestdim}));
for i = 1:length(st{largestdim})
    ind = P.VALS.(param{largestdim}) == st{largestdim}(i);
    if length(param) > 1
        ind = ind & P.VALS.(param{smallestdim}) == st{smallestdim};
    end
    RF{i} = TS(ind);
end

binvec = win(1)*1000:cfg.binsize:win(2)*1000-cfg.binsize;
binvec = binvec/1000; % ms -> s

for i = 1:length(st{largestdim})
    pax = subplot(nrows,ncols,i);
    
    % raster   
    lr = cellfun(@length,RF{i},'UniformOutput',true);
    fr = find(lr);
    rm = cellfun(@repmat,num2cell(fr),num2cell(lr(fr)),num2cell(ones(size(fr))),'UniformOutput',false);
    X = cell2mat(RF{i});
    Y = cell2mat(rm);
    plot(pax,X,Y,'sk','markersize',2,'markerfacecolor',[0.6 0.6 0.6],'markeredgecolor','none');
 
    
    
    % histogram
    bincnt = histc(X,binvec);
    hold(pax,'on')
    stairs(binvec,bincnt,'-k','Parent',pax);
    hold(pax,'off')
    
    
    [c,r] = ind2sub([ncols nrows],i);
    
    if r < nrows
        set(pax,'xticklabel',[]);
    end
    
    if c > 1
        set(pax,'yticklabel',[]);
    end
    
    set(pax,'tag',num2str(st{largestdim}(i)),'ylim',[0 length(lr)+1], ...
        'xlim',[win(1) win(2)]);
    
    ax_data.raster    = [X(:),Y(:)];
    ax_data.histogram = [binvec(:),bincnt(:)];
    ax_data.stim_type = param;
    ax_data.stim_val  = st{largestdim}(i);
    
    set(pax,'UserData',ax_data);
end

fig_data.ids = pref;
fig_data.P   = P;
fig_data.cfg = cfg;
set(gcf,'UserData',fig_data);

