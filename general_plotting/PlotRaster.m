function h = PlotRaster(varargin)
% PlotRaster(raster,values)
% PlotRaster(ax,raster,values)
% PlotRaster(...,colors)
% h = PlotRaster(...)
% 
% Plots raster (a cell array of spike times relative to some event onset) 
% against associated values (numerical array matching size of raster) on 
% the y axis.
%
% colors can be specified for alternating color scheme by value.  colors
% must be an Nx3 matrix of RGB values.
%   ex: PlotRaster(raster,values,[0 0 0; 0.5 0.5 0.5]);
%       - this plots alternating black and gray points
% 
% Optionally returns an array of handles (h) to all points in each cell of
% raster.
% 
% Daniel.Stolzberg@gmail.com 2014
% 
% See also, PlotDensity

nv = length(varargin);
assert(nv>=2 && nv<=4,'Requires between 2 and 4 inputs.');

colors = [0 0 0; 0.5 0.5 0.5];

if nv == 2
    ax = gca;
    raster = varargin{1};
    values = varargin{2};

elseif nv == 3 && isscalar(varargin{1})
    ax     = varargin{1};
    raster = varargin{2};
    values = varargin{3};

elseif nv == 3 && iscell(varargin{1})
    ax = gca;
    raster = varargin{1};
    values = varargin{2};
    colors = varargin{3};
    
elseif nv == 4
    ax = gca;
    raster = varargin{2};
    values = varargin{3};
    colors = varargin{4};
end

assert(iscell(raster),'raster must be a cell array.');
assert(isnumeric(values)&&length(values)==length(raster), ...
    'values must be a numerical array the same size as raster.');
assert(size(colors,2)==3,'colors must be an Nx3 matrix of RGB values.');

raster = raster(:);
values = values(:);

[values,i] = sort(values);
raster     = raster(i);

uvals = unique(values);
nvals = length(uvals);

% spacing
for i = 1:nvals
    ind = values == uvals(i);
    n(i) = sum(ind); %#ok<AGROW>
    if i == nvals
        d = abs(diff(uvals([i i-1])));
    else
        d = abs(diff(uvals([i i+1])));
    end
    values(ind) = values(ind) + d*linspace(0,0.95,n(i))';    
end

cvals = num2cell(values);
cy = cellfun(@(a,b) (a*ones(size(b))),cvals,raster,'UniformOutput',false);

% alternating colors
ncolors = size(colors,1);
k = 1;
for i = 1:nvals
    pcolors(k:k+n(i)-1,:) = repmat(colors(mod(i,ncolors) + 1,:),n(i),1);
    k = k + n(i);
end
colors = num2cell(pcolors,2);

eind = cellfun(@isempty,raster);
raster(eind) = [];
cy(eind)     = [];
colors(eind) = [];

% plot
cla(ax);
h = cellfun(@(x,y) (line(x,y,'Parent',ax)),raster,cy);
set(h,'linestyle','none','markersize',2,'marker','s');
cellfun(@(a,c) (set(a,'markerfacecolor',c,'markeredgecolor',c,'markersize',1)),num2cell(h),colors)

set(ax,'ylim',[values(1) values(end)]);




















