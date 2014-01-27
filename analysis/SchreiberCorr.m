function Rcorr = SchreiberCorr(S)
% Rcorr = SchreiberCorr(S)
%
% Implements spike-train reliability measure introduced by Schreiber et al,
% 2003.
% 
% S is a 2D matrix of binned data with observations in columns and
% samples (bins) in rows.  Typically, the binned data (S) will aready have
% been convolved with a smoothing window, such as a gaussian filter, the
% duration of which is depended on the phenomenological time scale of
% interest.
% 
% Reference: Schreiber et al, 2003 Neurocomputing 52-54, p925-931
% 
% Daniel.Stolzberg@gmail.com 2014


S(:,~any(S)) = [];

d = sqrt(sum(S.^2)); % normalize vectors

St = S';

N = size(S,2);
A = 0;
for i = 1:N
    for j = i+1:N
        A = A + (St(i,:) * S(:,j) / (d(i)*d(j)));
    end
end

Rcorr = 2/(N*(N-1)) * A;





