function [SD,pcfg] = comp_spikedensity(obj,cfg)
% [SD,pcfg] = comp_spikedensity(unitid,cfg)
%
% ----- required -----
% unitid ... unit id as a unit id in obj.units or a string from obj.unitstr
% parid  ... parameter id(s) as an index from obj.params or an event name or
%               names
% parval ... parameter value(s) corresponding to obj.params.uvals
%               - there should be a parval correspondind to each parid
% win    ... window to view data as [onset offset], eg: [-0.025 0.2] (in seconds)
%
% ----- optional -----
% krnldur ... duration of kernel in seconds; Default = 0.005;
% krnlfcn ... kernel (window) function. See help window for details. Default = @gausswin
%
%
% DJS 2013

% Check input------------------
reqflds = {'unitid','parid','parval','win'};
reqvald = {@ismatrix,@ismatrix,@ismatrix,@(x) isnumeric(x) & length(x)==2};
optflds = {'binvec','krnldur','krnlfcn'};
optdeft = {0:0.001:0.2,0.005,@gausswin};
opttype = {@isvector,@isscalar,@(x)isa(x,'function_handle')};
pcfg = cfgcheck(cfg,reqflds,reqvald,optflds,optdeft,opttype);
%------------------------------

N = round(obj.Fs * pcfg.krnldur);

w = window(pcfg.krnlfcn,N);

pcfg.binvec = pcfg.win(1):1/obj.Fs:pcfg.win(2)-1/obj.Fs;

H = comp_hist(obj,pcfg);

cH = zeros(size(H));
for i = 1:size(H,2)
    cH(:,i) = conv(H(:,i),w,'same');
end

SD.mean = mean(cH,2);
SD.std  = std(cH,1,2);
SD.sem  = SD.std / sqrt(size(cH,2));
[SD.norm.muhat,SD.norm.sigmahat,SD.norm.muci,SD.norm.sigmaci] = normfit(cH');

SD.cfg = pcfg;



