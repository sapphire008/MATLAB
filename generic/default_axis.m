function default_axis(h)
if nargin<1 || isempty(h)
    h = gcf;
end
axs = findobj(h,'type','axes');
for n = 1:length(axs)
    set(axs(n), 'tickdir','out')
    set(axs(n), 'box','off')
    set(axs(n), 'fontname','Helvetica');
end
end