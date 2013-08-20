function R = ComputePSTHfeatures(t,psth,varargin)
% R = ComputePSTHresult(t,psth)
% R = ComputePSTHresult(t,psth,varargin)
%
% Compute onset, offset, peak, histarea, stats of PSTH response
%
% t     ...     time vector
% psth  ...     binned spiketrain
%
% Optional inputs:
%   'rwin'      ...     response window (default t > 0)
%   'bwin'      ...     baeline window (default t < 0)
%   'resamp'  ...     resamp psth by some factor (default = 0); uses pchip
%                          This may increase sensitivity of KS test
%   'ksalpha'   ...     alpha criterion for KS test (default = 0.05)
%   'kstype'      ...     comparison kstype for KS test (default = 'unequal')
%   'plotresult'...     plots data in new figure (default = false)
% 
% See also, kstest2
%
% DJS 2013


if ~isvector(t),    error('t must be a vector');    end
if ~isvector(psth), error('psth must be a vector'); end

% defaults
rwin        = [t(find(t>0,1)),t(end)];
bwin        = [t(1), t(find(t<0,1,'last'))];
ksalpha     = 0.05;
kstype       = 'unequal';
resamp      = 0;
plotresult  = false;
% critvaln = 3;



ParseVarargin({'rwin','ksalpha','bwin','kstype','resamp','plotresult'},[],varargin);


R = struct('onset',[],'offset',[],'peak',[],'histarea',[],'stats',[], ...
    'baseline',[]);

fs = 1/mean(diff(t)); % estimate sampling (bin) rate
if resamp > 1
    psth = pchip(t,psth,t(1):1/(fs*resamp):t(end));
    t    = linspace(t(1),t(end),length(psth));
    fs   = 1/mean(diff(t)); % reestimate sampling (bin) rate
end

bind = t >= bwin(1) & t <= bwin(2);
rind = t >= rwin(1) & t <= rwin(2);

% stats
[ks.h,ks.p,ks.ksstat] = kstest2(psth(bind),psth(rind),ksalpha,kstype);
R.stats = ks;



% response features--------------------------------------------------------


[baseline.muhat,baseline.sigmahat,baseline.muci,baseline.sigmaci] = normfit(psth(bind));
% R.critval = critvaln * baseline.sigmahat;
R.critval = baseline.muhat;
R.baseline = baseline;

% R.baseline.meanfr = sum(psth(bind))/abs(diff(bwin));
% R.response.meanfr = sum(psth(rind))/abs(diff(rwin));

sigind = findbigrun(psth(rind)>= R.baseline.muhat);

R.onset.rwsample = find(sigind,1);
R.onset.sample   = R.onset.rwsample + find(rind,1);
R.onset.latency  = t(R.onset.sample);

R.offset.rwsample = R.onset.rwsample+find(sigind(R.onset.rwsample:end)==0,1,'first')-2;
if isempty(R.offset.rwsample), R.offset.rwsample = length(sigind)+R.onset.rwsample; end
R.offset.sample   = R.offset.rwsample + find(rind,1) - 1;
R.offset.latency  = t(R.offset.sample);

respidx = R.onset.sample:R.offset.sample;
if isempty(respidx)
    respidx = R.onset.sample;
end
[R.peak.fr,i] = max(psth(respidx));
R.peak.sample    = i + R.onset.sample - 1;
R.peak.latency   = t(R.peak.sample);


% suppress polyfit warnings
warning('off','MATLAB:polyfit:PolyNotUnique')
warning('off','MATLAB:polyfit:RepeatedPointsOrRescale')


R.onset.slope   = 0;
R.onset.yoffset = 0;
if R.onset.sample < R.peak.sample
    risingidx = [R.onset.sample R.peak.sample];
    pt = t(risingidx); pp = psth(risingidx);
    p1 = polyfit(pt(:),pp(:),1);
    R.onset.slope   = p1(1);
    R.onset.yoffset = p1(2);
    % p2 = polyfit([psth(R.onset.sample) R.peak.value],[R.onset.latency R.peak.latency],1);
    % R.onset.estlatency = polyval(p2,R.baseline.muhat);
    % R.onset.fit = polyval(p1,[R.onset.estlatency R.onset.latency R.peak.latency]);
end


R.offset.slope   = 0;
R.offset.yoffset = 0;
if R.offset.sample > R.peak.sample
    fallingidx = [R.peak.sample R.offset.sample];
    pt = t(fallingidx); pp = psth(fallingidx);
    p1 = polyfit(pt(:),pp(:),1);
    R.offset.slope   = p1(1);
    R.offset.yoffset = p1(2);
    % p2 = polyfit([R.peak.value psth(R.offset.sample)],[R.peak.latency R.offset.latency],1);
    % R.offset.estlatency = polyval(p2,R.baseline.muhat);
    % R.offset.fit = polyval(p1,[R.peak.latency R.offset.latency R.offset.estlatency]);
end

warning('on','MATLAB:polyfit:PolyNotUnique')
warning('on','MATLAB:polyfit:RepeatedPointsOrRescale')

idx = R.onset.sample:R.offset.sample;
x  = linspace(R.onset.latency,R.offset.latency,length(idx));
pa = psth(idx);
R.histarea = polyarea(x(:),pa(:));



% MEAN BETWEEN RESPONSE ONSET AND 50 MS FOLLOWING ONSET
idx = R.onset.sample:R.onset.sample+floor(fs*0.05);

if isempty(idx) || length(idx) < 2
    R.baseline.meanfr = -1;
    R.response.meanfr = -1;
else
%         R.baseline.meanfr = sum(psth(bind))/abs(diff(bwin));
%         R.response.meanfr = sum(psth(idx))/diff(t(idx([1 end])));
    R.baseline.meanfr = mean(psth(bind));
    R.response.meanfr = mean(psth(idx));
end

if plotresult, plotdata(t,psth,bind,rind,R); end %#ok<UNRCH>









function plotdata(t,psth,bind,rind,R)
figure;

subplot(211)
stairs(t,psth,'-k','linewidth',2);
hold on
stairs(t(bind),psth(bind),'-b','linewidth',1.5);
stairs(t(rind),psth(rind),'-r','linewidth',1.5);
plot(R.onset.latency,R.critval,'*g','markersize',8,'linewidth',1)
plot(R.offset.latency,R.critval,'*g','markersize',8,'linewidth',1)
plot(R.peak.latency,R.peak.value,'*g','markersize',8,'linewidth',1)
% plot([R.onset.latency R.offset.latency],[R.critval R.critval],':c','linewidth',2);
% plot([R.onset.estlatency t([R.onset.sample R.peak.sample])],R.onset.fit,':c','linewidth',2);
% plot([t([R.peak.sample R.offset.sample]) R.offset.estlatency],R.offset.fit,':c','linewidth',2);
% plot([R.onset.estlatency R.offset.estlatency],[R.baseline.muhat R.baseline.muhat], ...
%     ':cd','linewidth',2);

plot([0 0],ylim,'-k','linewidth',1)
hold off
xlabel('time');

subplot(212)
hold on
h = cdfplot(psth(bind));
set(h,'color','b','linewidth',2);
h = cdfplot(psth(rind));
set(h,'color','r','linewidth',2);
hold off
legend('Baseline','Response','Location','SE');






function rind = findbigrun(ind)
ind(end) = 0;

up = find(ind(1:end-1)<ind(2:end));
dn = find(ind(1:end-1)>ind(2:end));

if isempty(up) || isempty(dn), rind = true(size(ind)); return; end

if dn(1) < up(1), dn(1) = []; end

if length(dn) > length(up)
    dn = dn(1:length(up));
elseif length(up) > length(dn)
    up = up(1:length(dn));
end

runlength = dn-up;

[~,i] = max(runlength);

rind = false(size(ind));

rind(up(i)+1:dn(i)) = 1;









