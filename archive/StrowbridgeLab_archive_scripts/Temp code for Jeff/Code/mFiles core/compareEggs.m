function [ICdistance, ICangle, magDifference, allParms] = compareEggs(array1, array2)
    % revised 5 Jan 2015 BWS
    % input arrays have trials as rows
   %ICangle is the angle subtended by the 2 centroids from the origin,
    %expressed in degrees
    %ICdistance is euclidian distance between centroids
    % magDifference is different in magnitudes

    X = mean(array1, 1); % centroid
    Y = mean(array2, 1);
    ICangle = acosd(dot(X,Y)./(norm(X)*norm(Y)));
    ICdistance = norm(X - Y);
    magDifference = abs(norm(array1) - norm(array2));
    allParms = [ICangle ICdistance magDifference];
end