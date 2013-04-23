function [SD,binvec,pars] = comp_spikedensity(obj,unitid,parid,parval,win,varargin)
% SD = comp_spikedensity(unitid,parid,parval,win)
% SD = comp_spikedensity(unitid,parid,parval,win,krndur,krnfcn)
% [SD,binvec] = comp_spikedensity(unitid,...)
%

% set defaults 
krndur = 0.005; 
krnfcn = @gausswin;

if length(varargin) >= 1, krndur = varargin{1};  end
if length(varargin) == 2, krnfcn = varargin{2};  end

N = round(obj.Fs * krndur);

w = window(krnfcn,N);

binvec = win(1):1/obj.Fs:win(2)-1/obj.Fs;

[H,pars] = comp_hist(obj,unitid,parid,parval,binvec);

cH = zeros(size(H));
for i = 1:size(H,2)
    cH(:,i) = conv(H(:,i),w,'same');
end

SD.mean = mean(cH,2);
SD.std  = std(cH,1,2);
SD.sem  = SD.std / sqrt(size(cH,2));
[SD.norm.muhat,SD.norm.sigmahat,SD.norm.muci,SD.norm.sigmaci] = normfit(cH');


