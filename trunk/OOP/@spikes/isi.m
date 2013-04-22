function varargout = isi(obj,unitid,varargin)
% H = isi(unitid)
% H = isi(unitid)
% H = isi(unitid,N)
% H = isi(unitid,N,bins)
% [H,bins] = isi(...)
%
% Compute interspike interval on a unit (or units)

N = 1;
bins = 0:0.001:0.1;

if length(varargin) >= 1, N = varargin{1};      end
if length(varargin) == 2, bins = varargin{2};   end

ts = unit_timestamps(obj,unitid);
if ~iscell(ts), ts = {ts}; end

cbins = repmat({bins},size(ts));
N     = repmat({N},size(ts));

dts = cellfun(@diff,ts,N,'UniformOutput',false);
H   = cellfun(@histc,dts,cbins,'UniformOutput',false);
% keep convention of rows are observations and colums are samples
H   = cell2mat(H')';

varargout{1} = H;
varargout{2} = bins;

