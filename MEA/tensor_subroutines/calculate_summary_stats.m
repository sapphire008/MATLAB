% calculate simple summary stats
function S = calculate_summary_stats(X, dim)
switch dim
    case 0
        S.mean = mean(X(:));
        S.median = median(X(:));
        S.stdev = std(X(:));
        S.range = [min(X(:)), max(X(:))];
    otherwise
        S.mean = mean(X, dim);
        S.median = median(X, dim);
        S.stdev = std(X, [], dim);
        S.range = cat(dim, min(X, [], dim), max(X, [], dim));
end
end