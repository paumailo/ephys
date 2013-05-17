function plot_evLFP(W,P,param,cfg)
% plot_evLFP(W,P,param,cfg)
% 
% For use with DB_QuickPlot
%
% DJS 2013


win  = [cfg.win_on cfg.win_off] / 1000; % ms -> s
svec = floor(win(1)*P.wave_fs):round(win(2)*P.wave_fs);


% Organize by stimulus onsets
onsamp = round(P.VALS.onset * P.wave_fs);


% Reorganize by stimulus type
largestdim = 1;
for i = 1:length(param)
    st{i} = sort(P.lists.(param{i}),'descend'); %#ok<AGROW>
    if length(st{i}) > length(st{largestdim})
        largestdim = i;
    end
end
if largestdim == 1, smallestdim = 2; else smallestdim = 1; end

% Won: samples X stim type X reps
Won = cell(size(st{largestdim}));
for i = 1:length(st{largestdim})
    ind = P.VALS.(param{largestdim}) == st{largestdim}(i);
    if length(param) > 1
        ind = ind & P.VALS.(param{smallestdim}) == st{smallestdim};
    end
    idx = find(ind);
    Won{i} = zeros(length(idx),length(svec));
    for j = 1:length(idx)
        Won{i}(j,:) = W(onsamp(idx(j))+svec);
    end
end

mWon = cellfun(@mean,Won,'UniformOutput',false);
eWon = cellfun(@std,Won,'UniformOutput',false);

tvec = svec ./ P.wave_fs;
for i = 1:length(mWon)
    pax = subplot(cfg.nrows,cfg.ncols,i);
    
    plot(tvec,mWon{i},'linewidth',1);
    
    
    [c,r] = ind2sub([cfg.ncols cfg.nrows],i);
    
    if r < cfg.nrows
        set(pax,'xticklabel',[]);
    end
    
    if c > 1
        set(pax,'yticklabel',[]);
    end
    
    set(pax,'tag',num2str(st{largestdim}(i)), ...
        'xlim',[win(1) win(2)],'ytick',[]);

    ax_data.trials    = Won{i};
    ax_data.stim_type = param;
    ax_data.stim_val  = st{largestdim}(i);
    
    set(pax,'UserData',ax_data);

end
ch = get(gcf,'children');
y = cell2mat(get(ch,'ylim'));
set(ch,'ylim',[-max(abs(y(:))) max(abs(y(:)))]);


