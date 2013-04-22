function h = plot_hist(obj,ax,unitid,parid,parval,binvec)
% h = plot_hist(obj,ax,unitid,parid,parval,binvec)

[h,pars] = comp_hist(obj,unitid,parid,parval,binvec);

if isempty(ax), ax = gca; end

h = bar(binvec,mean(h,2),'k');
axis(ax,'tight');
grid(ax,'on');
box(ax,'on');





