function hFig = plotEggs(confInterval, egg1, egg2, egg3, egg4)
    % revised 19 May 2014 BWS for numTrialsx3 eggs
    % set confInterval == 0 for no shaded ellipsoids
    % color sequence: black, red, blue, green
    hFig = figure();
    maxV2 = 0;
    maxV3 = 0;
    maxV4 = 0;
    scatter3(egg1(:,1),egg1(:,2),egg1(:,3), 'MarkerFaceColor', 'k');
    maxV1 = 1.05 * max(max(egg1)); % extra 5% on top side
    if nargin > 2
        hold on;
        scatter3(egg2(:,1),egg2(:,2),egg2(:,3), 'MarkerFaceColor', 'r');
        maxV2 = 1.05 * max(max(egg2)); % extra 5% on top side
    end
    if nargin > 3
        scatter3(egg3(:,1),egg3(:,2),egg3(:,3), 'MarkerFaceColor', 'c');
        maxV3 = 1.05 * max(max(egg3)); % extra 5% on top side
    end
    if nargin > 4
        scatter3(egg4(:,1),egg4(:,2),egg4(:,3), 'MarkerFaceColor', 'm');
        maxV4 = 1.05 * max(max(egg4)); % extra 5% on top side
    end
    maxV = max([maxV1 maxV2 maxV3 maxV4]);
    axis([0 maxV 0 maxV 0 maxV]);
end