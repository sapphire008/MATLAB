function [accuracy, corr] = kNNpairwise(egg1, egg2, ks)
    % revised 7 Jan 2015 BWS
    % inputs are two eggs numTrials x numCells
    % ks is the number of values to consider
    
    Y = [ones(size(egg1,1),1); ones(size(egg2,1),1) + 1]; % labels of all training examples 
    X = [egg1;egg2]'; % training data from both eggs combined into numCell x numOverallTrials
   
    %get euclidean distances
    dists = L2_distance(X,X);

    % -- make the "self distance" big so no data point is own neighbor
    distances = dists + eye(size(dists))*100*max(max(dists));

    %sort by distance --- to find nearest
    [ordered_lists, labels] = sort(distances,1,'ascend'); %now it's the (:,i) distances are distances from stuff to point i...

    %get lables of K nearest...
    if ks ==1
        predicted = transpose(Y(labels(1,:)));
    end
    if ks > 1
        topys = Y(labels(1:ks,:));
        predicted = mode(topys);   
    end

    err = sum(predicted~=Y')/length(Y);
    accuracy = 100 * ( 1-err);
    %corr = (predicted == Y');
    corr = sum(predicted == Y') / length(Y);
end

