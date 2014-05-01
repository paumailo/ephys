function varargout = findbiggestrun(I,ignoregaps)
% middle = findbiggestrun(I)
% [first,last] = findbiggestrun(I)
% ... = findbiggestrun(I,ignoregaps)
%
% I is a logical vector
%
% Returns the index of the largest run of true values in I.  If
% more than one run exists, then the rounded mean of the indices for these
% runs is returned.
%
% Optionally returns the first and last samples of the biggest run of true
% values.
% 
% Optionally ignore gaps (false) values of at most this value.
% 
% Daniel.Stolzberg@gmail.com   2014


if nargin == 2 && ignoregaps > 0
    [fbwl,fubwl] = MAKEBW(~I);
    s = arrayfun(@(x) (sum(x==fbwl)),fubwl);
    i = s <= ignoregaps;
    I(ismember(fbwl,fubwl(i))) = true;
end


[bwl,ubwl] = MAKEBW(I);

s = arrayfun(@(x) (sum(x==bwl)),ubwl);
[~,i] = max(s);

if nargout == 1
    varargout{1} = round(mean(find(bwl == ubwl(i))));
elseif nargout == 2
    varargout{1} = find(bwl == ubwl(i),1,'first');
    varargout{2} = find(bwl == ubwl(i),1,'last');
end


function [bwl,ubwl] = MAKEBW(I)
bwl = bwlabel(I);
ubwl = unique(bwl);
ubwl(ubwl==0) = [];

