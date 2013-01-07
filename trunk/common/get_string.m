function rstr = get_string(hObj)
% rstr = get_string(hObj)
%
% get currently select string in a gui control such as popup menu or
% listbox
%
% DJS 2013

v = get(hObj,'Value');
s = cellstr(get(hObj,'String'));
if v > length(s), v = 1; end
if isempty(s)
    rstr = '';
else
    rstr = s{v};
end
