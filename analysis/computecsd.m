function CSD = computecsd(PHI,H,N,SIGMA,SPATIALFILTER)
% CSD = computecsd(PHI)
% CSD = computecsd(PHI,H)
% CSD = computecsd(PHI,H,N,SIGMA)
% CSD = computecsd(PHI,H,N,SIGMA,SPATIALFILTER)
% 
% Uses spline iCSD method from iCSD Plotter (Pettersen et al, 2006)
% 
% H is the distance between electrode sites.  If length(H) == 1 then the
% value is used as the distance parameter between electrode sites (rows).
% if length(H) == 2 then the additional value is used as a distance
% parameter in the column dimension which can be used for inter-electrode
% distance.
% 
% SIGMA is the extracellular conductivity (default = 0.3)
% 
% References: Mitzdorf 1985; Pettersen et al., 2006; Szymanski et al., 2009
% 
% 
% DJS (c) 2010


if isempty(whos('H')) || isempty(H), H = 1; end
if isempty(whos('N')) || isempty(N), N = 1; end
if isempty(whos('SIGMA')) || isempty(SIGMA), SIGMA = 0.3; end
if isempty(whos('SPATIALFILTER')) || isempty(SPATIALFILTER), SPATIALFILTER = false; end

yvec = H:H:size(PHI,1)*H;
diam = 5e-4;
cond = 0.3;
cond_top = 0.3;
filter_range = 5e-4;
gauss_sigma = 1e-4;


% compute spline iCSD using Pettersen method (Pettersen et al, 2005)
Fcs = F_cubic_spline(yvec,diam,cond,cond_top);
[zs,CSD] = make_cubic_splines(yvec,PHI,Fcs);

if SPATIALFILTER && gauss_sigma~=0 %filter iCSD
  [~,CSD]=gaussian_filtering(zs,CSD,gauss_sigma,filter_range);
end
CSD = -CSD * 1e-3; % A/m^3 -> muA/mm^3; Flip sign of CSD
% n = floor(size(CSD,1)/size(PHI,1));
% CSD = CSD(n:n:end,:);




