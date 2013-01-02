function i = findincell(m,n)
% i = findincell(m)
% i = findincell(m,n)
% 
% Helper function finds first n indicies of values in cell array m where
% there may be empty cells. CELL2MAT is ineffective in this case because it
% can not translate the empty cells to a numerical (logical) matrix.
% 
% Often useful following a call to the STRFIND function when the first
% parameter is a cell array.
% 
% DJS (c) 2011

if ~exist('n','var'), n = []; end

nm = false(size(m));

if iscell(m)
    for k = 1:numel(m)
        if isempty(m{k})
            nm(k) = 0;
        else
            nm(k) = 1;
        end
    end
else
    nm = m;
end

if isempty(n)
    i = find(nm);
else
    i = find(nm,n);
end
