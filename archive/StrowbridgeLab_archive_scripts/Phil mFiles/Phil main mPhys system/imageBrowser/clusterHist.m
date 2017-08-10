% plot a profile of spike heights
% left click to drag cluster boundaries and right click to split cluster
% returns min and max of clusters and reclusters existing spikes assuming
% the standard name 'clusters' for the cluster data
% clusterBounds = clusterHist(spikes, clusters)

function handle = clusterHist(spikes, clusters)
handle = figure;

spikes = squeeze(spikes);
clusters = squeeze(clusters);

[n xout] = hist(spikes(:,2), length(clusters) / 10);
bar(xout, n);
heights = sort(n);
colorPallete = [lines(7); lines(7)];
numUnits = max(clusters);
% draw lines in order
for x = numUnits:-1:1
    tempData = find(clusters == x);
    if isempty(tempData)
        warning(['No spikes found in cluster ' num2str(x) '.']);
        continue
    end
    thisGroup = spikes(tempData,2);
    unitSize(x) = mean(thisGroup);
    line([min(thisGroup) max(thisGroup)], [max(get(gca, 'ylim')) / 2 max(get(gca, 'ylim')) / 2]);
    clusterBounds(x,1) = min(thisGroup);
    clusterBounds(x,2) = max(thisGroup);
    clear thisGroup;
end

set(gcf, 'numbertitle', 'off', 'name', 'Spike Clusters');
kids = get(gca, 'children');
for unitIndex = 1:numUnits
    set(kids(numUnits - unitIndex + 1), 'color', colorPallete(unitIndex + 1, :));
end                

set(gca, 'ylim', [0 1.1 * heights(length(heights) - 1)]);
set(gcf, 'WindowButtonDownFcn', 'setPointer', 'WindowButtonUpFcn', 'changeCluster', 'WindowButtonMotionFcn', 'tracePointer', 'Pointer', 'crosshair')

% put the cluster info there so we can access it
set(gcf, 'userdata', {clusterBounds, 0, inputname(2), inputname(1)});