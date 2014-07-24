function [Rcorr,nRcorr] = mdRcorr(data,vals,gwlength)
% Rcorr = mdRcorr(data,vals)
% Rcorr = mdRcorr(data,vals,gwlength)
% [Rcorr,nRcorr] = mdRcorr(data,vals,...)
% 
% Computes Schreiber correlation (Schreiber et al, 2003) for one or two
% dimensional binned data.
% 
% Rcorr (and nRcorr) will be an Nx1 matrix where N is the same size as the
% first parameter in data (size(data,3) or equivalently, length(vals{3}).
% If data is two-dimensional, Rcorr (and nRcorr) will be an NxM matrix
% where M is the same size as the second parameter in data (size(data,4) or
% equivalently, length(vals{4}).
% 
% Both of the required inputs, data and vals, are created from a call to
% SHAPEDATA_SPIKES prior to calling this function.
% 
% ex:
%   st = DB_GetSpiketimes(unit_id);
%   P  = DB_GetParams(unit_id,'unit');
%   [data,vals] = shapedata_spikes(st,P,{'Levl'},'win',[0.0 0.10], ...
%     'binsize',binsize,'returntrials',true);
%   Rcorr = mdRcorr(data,vals);
% 
% ex2:
%   st = DB_GetSpiketimes(unit_id);
%   P  = DB_GetParams(unit_id,'unit');
%   [data,vals] = shapedata_spikes(st,P,{'Levl','Freq'},'win',[0.0 0.05], ...
%     'binsize',binsize,'returntrials',true);
%   Rcorr = mdRcorr(data,vals);
% 
% See also, SchreiberCorr, shapedata_spikes
% 
% Daniel.Stolzberg@gmail.com 2014


assert(nargin>=2,'At least data and vals must be specified')
assert(ndims(data)==numel(vals),'vals must have a number of elements equal to the number of dimensions in data')

% Set defaults
if nargin < 3
    gwlength = 10; % number of samples or bins
end



gw = gausswin(gwlength);

trials = vals{2};
param1 = vals{3};
param2 = [];
if length(vals)==4
    param2 = vals{4};
    Rcorr = zeros(length(param1),length(param2));
else
    Rcorr = zeros(size(param1));
end


nRcorr = zeros(size(Rcorr));

if isempty(param2) % one dimensional data
    for i = 1:length(param1)
        d = squeeze(data(:,:,i));
        S = zeros(size(d));
        for k = trials
            S(:,k) = conv(d(:,k),gw,'same');
        end
        [Rcorr(i),nRcorr(i)] = SchreiberCorr(S);
    end
    
    
else % two dimensional data
    for i = 1:length(param1)
        for j = 1:length(param2)
            d = squeeze(data(:,:,i,j));
            S = zeros(size(d));
            for k = trials
                S(:,k) = conv(d(:,k),gw,'same');
            end
            [Rcorr(i,j),nRcorr(i,j)] = SchreiberCorr(S);
        end
    end
    
end




