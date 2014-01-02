function varargout = PlotDensity(raster,values,varargin)
% PlotDensity(raster,values)
% PlotDensity(raster,values,'Parameter',value)
% D = PlotDensity(raster,values,...)
% [D,h] = PlotDensity(raster,values,...)
% 
% Takes raster input (see PlotRaster) and creates a surface plot of a
% 2D histogram from the data.
% 
% 
% Optional 'Parameter',value pair arguments:
% 
%   'ax'        ...     axis handle (default = gca)
%   'bins'      ...     equally spaced bins
%                       default is determined from data
%   'smoothing' ...     true or false.  If true, a 5x5 gaussian kernel is
%                       convolved with the 2D histogram.
% 
% Daniel.Stolzberg@gmail.com 2014
% 
% See also, PlotRaster



assert(length(varargin)>=2,'Requires atleast 2 inputs.');
assert(iscell(raster),'raster must be a cell array.');
assert(isnumeric(values)&&length(values)==length(raster), ...
    'values must be a numerical array the same size as raster.');

% defaults
ax   = [];
bins = [];
smoothing = true;

ParseVarargin({'ax','bins','smoothing'},[],varargin);

if isempty(ax),   ax = gca; end
if isempty(bins)
    t = cell2mat(raster);
    bins = min(t):0.001:max(t)-0.001;
end


[values,i] = sort(values);
raster     = raster(i);

uvals = unique(values);
nvals = length(uvals);

D = zeros(nvals,length(bins));
for i = 1:nvals
    ind = values == uvals(i);
    t   = cell2mat(raster(ind));
    D(i,:) = histc(t,bins);
end

if smoothing
    gw = gausswin(5);
    mD = max(D(:));
    for i = 1:nvals
        D(i,:) = conv(D(i,:),gw,'same');
    end
    D  = D/max(D(:))*mD;
end

% h = surf(ax,bins,uvals,D);
% shading(ax,'flat'); 
h = imagesc(bins,uvals,D,'parent',ax);
set(ax,'ydir','normal');

view(ax,2)

varargout{1} = D;
varargout{2} = h;




















