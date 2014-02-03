function Rcorr = SchreiberCorr(S)
% Rcorr = SchreiberCorr(S)
%
% Implements spike-train reliability measure introduced by Schreiber et al,
% 2003.
% 
% S is a 2D matrix of binned data with observations in columns and
% samples (bins) in rows.  Typically, the binned data (S) will aready have
% been convolved with a smoothing window, such as a gaussian window (see
% reference).
% 
% Reference: Schreiber et al, 2003 Neurocomputing 52-54, p925-931
% 
% ***** RESULTS OF JITTER TEST DO NOT SEEM TO MATCH SCHREIBER ET AL, 2003
% FIGURE 2A.  NOT SURE WHAT IS WRONG.  USE WITH CAUTION.  DS 1/28/2014 ***
% 
% Daniel.Stolzberg@gmail.com 2014


% S(:,~any(S)) = [];

N = size(S,2);
A = 0;
for i = 1:N
    for j = i+1:N
        A = A + (S(:,i)' * S(:,j) / (norm(S(:,i)) * norm(S(:,j))));
    end
end

Rcorr = 2/(N*(N-1)) * A;





