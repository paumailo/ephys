function SCRATCH_DB_RRTF
%%
IDs = getpref('DB_BROWSER_SELECTION');  

st = DB_GetSpiketimes(IDs.units);
P  = DB_GetParams(IDs.blocks);

%%

win = [0 0.6];

fpidx = find(diff(P.VALS.Rate))+1;

uRate = P.lists.Rate;

if any(uRate==1), fpidx = [1; fpidx]; end

VALS = structfun(@(x) (x(fpidx)),P.VALS,'UniformOutput',false);

raster = cell(size(VALS.onset));
for i = 1:length(VALS.onset)
    ind = st >= VALS.onset(i) + win(1) & st < VALS.onset(i) + win(2);
    raster{i} = st(ind) - VALS.onset(i);
end

for i = 1:length(uRate)
    ind = VALS.Rate == uRate(i);
    tname = sprintf('RR%dHz',uRate(i));
    trials.(tname) = cell(sum(ind),1);
    trials.(tname) = raster(ind);
    % trials.(tname) = cellfun(@diff,raster(ind),'UniformOutput',false);
end


%%
figure('windowstyle','docked','Color','w');

fn = fieldnames(trials)';
nrows = length(fn);
k = 1;
for f = fn
    f = char(f); %#ok<FXSET>
    x = cell2mat(trials.(f));
    i = num2cell(1:length(trials.(f)))';
    y = cellfun(@(a,b) (ones(size(a))*b),trials.(f),i,'UniformOutput',false);
    y = cell2mat(y);
    
    
    subplot(nrows,1,k);
        
    plot(x,y,'sk','markersize',1,'markerfacecolor','k');
    
    set(gca,'xtick',[],'ytick',[],'xlim',win);
    ylabel(uRate(k));
    k = k + 1;
end

set(gca,'xtickmode','auto');



%% Rayleigh statistics
% Berens, 2009 CircStat: A Matlab toolbox for circular statistics

fn = fieldnames(trials);
alpha     = cell(size(uRate));
R         = nan(size(uRate));
clear stats

for i = 1:length(uRate)
    alpha{i} = (2*pi*cell2mat(trials.(fn{i})))/(1/uRate(i));
    stats(i) = circ_stats(alpha{i});  %#ok<AGROW,NASGU>
    R(i)     = circ_r(alpha{i}); % resultant vector length    
end


%%
figure('windowstyle','docked','Color','w')

% get scaling value for radius
t   = cell(size(alpha));
rho = cell(size(alpha));
for i = 1:length(alpha)
    subplot(5,4,i)
    [t{i},rho{i}] = rose(alpha{i},50);
end
mr = max(cell2mat(rho'));

for i = 1:length(alpha)
    rho{i} = rho{i} ./ mr;
    rho{i}(isnan(rho{i})) = 0;
    subplot(5,4,i)
    h = polar([0 pi],[0 1]);
    delete(h);
    hold on
    polar(t{i},rho{i});   
    hold off
    title(sprintf('%d Hz',uRate(i)));
end

subplot(5,4,17:20)
plot(uRate,R,'-o');
ylim([0 1]);
grid on
ylabel('Resultant Vector Length');
xlabel('Repetition Rate (Hz)');
















