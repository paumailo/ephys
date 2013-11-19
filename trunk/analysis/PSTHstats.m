function A = PSTHstats(PSTH,bins,varargin)
% A = PSTHstats(PSTH,bins,varargin)
% 
% 
% alpha  ... 0.01;
% prewin ... [-0.05 0];
% rspwin ... [0 0.05];
% 

alpha  = 0.01;
prewin = [-0.05 0];
rspwin = [0 0.05];

ParseVarargin({'alpha','prewin','rspwin','tail'},[],varargin);

preIND = bins >= prewin(1) & bins < prewin(2);
rspIND = bins >= rspwin(1) & bins < rspwin(2);
PRE = PSTH(preIND,:);
RSP = PSTH(rspIND,:);


% Peak Response
[mag,x] = max(RSP);
idx = find(rspIND);
lat = bins(idx(x));

% for i = 1:size(RSP,2)
%     [h(i),p(i)] = kstest2(PRE(:,i),RSP(:,i),alpha);
% end
[h,p,ci,stats] = ttest2(RSP,mag,alpha);
A.peak.magnitude   = mag; %#ok<*AGROW>
A.peak.latency     = lat;
A.peak.rejectnullh = h;
A.peak.p           = p;
A.peak.ci          = ci;
A.peak.stats       = stats;

% Mean Response
[h,p,ci,stats] = vartest2(PRE,RSP,alpha);
mag = mean(RSP);
A.response.magnitude   = mag;
A.response.latency     = lat;
A.response.rejectnullh = h;
A.response.p           = p;
A.response.ci          = ci;
A.response.stats       = stats;











