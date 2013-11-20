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
[mag,peakidx] = max(RSP);
rspidx = find(rspIND);
lat = bins(rspidx(peakidx));
[h,p,ci,stats] = ttest2(PRE,mag,alpha,'left');
A.peak.magnitude   = mag; %#ok<*AGROW>
A.peak.latency     = lat + rspwin(1);
A.peak.rejectnullh = h;
A.peak.p           = p;
A.peak.ci          = ci;
A.peak.stats       = stats;

% Mean Response
[h,p,ci,stats] = vartest2(PRE,RSP,alpha);
mag = mean(RSP);
A.response.magnitude   = mag;
A.response.latency     = lat + rspwin(1);
A.response.rejectnullh = h;
A.response.p           = p;
A.response.ci          = ci;
A.response.stats       = stats;


% Onset
onrsp = RSP(1:peakidx,:);
thresh = repmat(A.response.ci(2,:),size(onrsp,1),1);
sigind = onrsp > thresh;
A.onset  = nan(1,size(sigind,2));
A.offset = nan(1,size(sigind,2));
for i = 1:size(sigind,2)
    idx = find(sigind(:,i),1,'first');
    if ~isempty(idx)
        A.onset(i) = rspwin(1) + bins(rspidx(idx));
    end
    idx = find(sigind(:,i),1,'last');
    if ~isempty(idx)
        A.offset(i) = rspwin(1) + bins(rspidx(idx));
    end
end







