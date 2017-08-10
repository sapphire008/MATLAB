function eph_draw_cartesian_axes(ax)
if nargin<1, ax = gca; end

set(ax, 'XAxisLocation', 'origin');
set(ax, 'YAxisLocation', 'origin');
set(ax, 'TickDir', 'out');
box off;

% Manually draw the tick label



set(ax, 'XTickLabelMode', 'manual');
XTickLabel = get(ax, 'XTickLabel');
XTick = get(ax,'XTick');
for x = 1:length(XTickLabel)
    if isempty(XTickLabel{x})
        XTickLabel{x} = num2str(XTick(x));
    end
end
set(ax, 'XTickLabel', XTickLabel);

% mending Ytick label
set(ax, 'YTickLabelMode', 'manual');
YTickLabel = get(ax, 'YTickLabel');
YTick = get(ax, 'YTick');
for y = 1:length(YTickLabel)
    if isempty(YTickLabel{y})
        YTickLabel{y} = num2str(YTick(y));
    end
end
set(ax, 'YTickLabel', YTickLabel);




YTL = get(gca,'yticklabel');
set(gca,'yticklabel',[YTL,repmat('  ',size(YTL,1),1)])
end