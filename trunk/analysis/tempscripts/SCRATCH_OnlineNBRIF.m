%% NBRIF

tank = 'ZAZU_5';
block = 6;

win = [0 0.05];

data = TDT2mat(tank,sprintf('Block-%d',block),'type',[2 3],'silent',true);

%
emap = [17 31 19 23 21 27 23 25 18 32 20 30 22 28 24 26 1 15 3 13 5 11 7 9 2 16 4 14 6 12 8 10];

chans = data.snips.eNeu.chan;

levels = data.epocs.Levl.data;
ulevel = unique(levels);
trials = data.epocs.Levl.onset;
trials = [trials + win(1) trials + win(2)];

if ~exist('emap','var') || isempty(emap)
    emap = unique(chans);
end

ts = data.snips.eNeu.ts;

r = cell(size(trials,1),length(emap));
for i = 1:size(trials,1)
    tsind = ts >= trials(i,1) & ts < trials(i,2);
    for j = 1:length(emap)
        ind = chans == emap(j) & tsind;
        r{i,j} = ts(ind);
    end
end


%
m = nan(length(ulevel),length(emap));
% v = nan(size(m));
for i = 1:length(ulevel)
    ind = levels == ulevel(i);
    for j = 1:length(emap)
        nm = cellfun(@numel,r(ind,j));
        m(i,j) = mean(nm);
%         v(i,j) = var(nm);
    end
end

% % glm
% gfit = zeros(size(m));
% for i = 1:size(m,2)
%     if ~any(m(:,i)), continue; end
%     w = 1./v(:,i);
%     w(isinf(w)) = 0;
%     b = glmfit(ulevel,m(:,i)./max(m(:,i)),'binomial','link','logit','weights',w);
%     gfit(:,i) = glmval(b,ulevel,'logit')*max(m(:,i));
% end


% plot IO

thisname = sprintf('%s_Block-%d',tank,block);
f = findobj('type','figure','-and','name',thisname);
if isempty(f), f = figure('name',thisname); end
figure(f);
[mx,my] = meshgrid(1:length(emap),ulevel);
plot3(mx,my,m,':','linewidth',2)
% plot3(mx,my,m,'-ok',mx,my,gfit,'-')
grid on
axis tight
ylabel('Sound Level (dB SPL)');
xlabel('Mapped Electrode');
zlabel('Mean Spike Count');
title(sprintf('Tank: ''%s'' Block-%d',tank,block));

