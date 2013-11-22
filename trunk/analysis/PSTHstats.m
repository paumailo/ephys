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
A.peak.latency     = lat;
A.peak.rejectnullh = logical(h);
A.peak.p           = p;
A.peak.ci          = -ci;
A.peak.stats       = stats;

% Mean Response
[h,p,ci,stats] = vartest2(PRE,RSP,alpha,'left');
mag = mean(RSP);
A.response.magnitude   = mag;
A.response.rejectnullh = logical(h);
A.response.p           = p;
A.response.ci          = ci;
A.response.stats       = stats;


% Response Onset/Offset
threshlevels = 10:20:90;
thresh = A.peak.magnitude' * threshlevels / 100;
rRSP = RSP(2:end,:) > RSP(1:end-1,:);
fRSP = RSP(2:end,:) < RSP(1:end-1,:);
for i = 1:ncols
    for j = 1:length(threshlevels)
        f = sprintf('pk%d',threshlevels(j));       
        
        sigind = RSP(1:peakidx(i),i) >= thresh(i,j) & rRSP(1:peakidx(i),i);
        if any(sigind)
            idx = find(sigind,1,'first');
            A.onset.(f)(i) = bins(rspidx(idx));
        else
            A.onset.(f)(i) = nan;
        end
        
        
        sigind = RSP(peakidx(i):end-1,i) >= thresh(i,j) & fRSP(peakidx(i):end,i);
        if any(sigind)
            idx = peakidx(i) + find(sigind,1,'last') - 1;
            A.offset.(f)(i) = bins(rspidx(idx));
        else
            A.offset.(f)(i) = nan;
        end
    end
end




