function p = permutepars(obj,parid)
% p = permutepars(parid)
%
% Returns permutations along n-parameters
%
% PARID refers to the parameter index in obj.params array.

pars = obj.params(parid);

uvals = {pars.uvals};

p = uvals{1};
% permute values of additional dimensions
for i = 2:length(uvals)
    n = length(uvals{i});
    p = repmat(p',1,n)';
    np = repmat(uvals{i}',size(p,1)/n,1);
    p(:,i) = np(:);
end

