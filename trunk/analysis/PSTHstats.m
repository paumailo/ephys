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

ncols = size(PSTH,2);

% Peak Response
[mag,peakidx] = max(RSP);
rspidx = find(rspIND);
lat = bins(rspidx(peakidx));
[h,p,ci,stats] = ttest2(PRE,mag,alpha,'left');
A.peak.magnitude   = mag; %#ok<*AGROW>
A.peak.latency     = lat + rspwin(1);
A.peak.rejectnullh = h;
A.peak.p           = p;
A.peak.ci          = -ci;
A.peak.stats       = stats;

% Mean Response
[h,p,ci,stats] = vartest2(PRE,RSP,alpha,'left');
mag = mean(RSP);
A.response.magnitude   = mag;
A.response.rejectnullh = h;
A.response.p           = p;
A.response.ci          = ci;
A.response.stats       = stats;


% Response Onset
% thresh = mean(PRE)+std(PRE)*5;

m = mean(PRE(:));
s = std(PRE(:));
thresh = norminv(1-alpha,m,s);
A.onset = nan(1,ncols);
for i = 1:ncols
    sigind = RSP(1:peakidx(i),i) >= thresh;
    if ~any(sigind), continue; end
    idx = find(sigind,1,'first');
    A.onset(i) = rspwin(1) + bins(rspidx(idx));
end
A.response.threshold = thresh;

% Response Offset
A.offset = nan(1,ncols);
for i = 1:ncols
    sigind = RSP(peakidx(i):end,i) >= thresh;
    if ~any(sigind), continue; end
    idx = peakidx(i) + find(sigind,1,'last') - 1;
    A.offset(i) = rspwin(1) + bins(rspidx(idx));
end




