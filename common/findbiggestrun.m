function idx = findbiggestrun(I)
% idx = findbiggestrun(I)
%
% I is a logical vector
%
% idx is returned as the index of the largest run of true values in I.  If
% more than one run exists, then the rounded mean of the indices fo these
% runs is returned.
%
% Daniel.Stolzberg@gmail.com   2014


bwl = bwlabel(I);
ubwl = unique(bwl);
ubwl(ubwl==0) = [];
s = arrayfun(@(x) (sum(x==bwl)),ubwl);
[~,i] = max(s);
idx = round(mean(find(bwl == ubwl(i))));
