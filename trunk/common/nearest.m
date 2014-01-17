function Vq = nearest(X,Xq)
% Vq = nearest(X,Xq)
% 
% Convenient version of:
% Vq = interp1(X,1:length(X),Xq,'nearest','extrap');


Vq = interp1(X,1:length(X),Xq,'nearest','extrap');



