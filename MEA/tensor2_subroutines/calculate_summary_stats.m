function STAT = calculate_summary_stats(X, dim)
switch dim
    case 0
        STAT.mean = mean(X(:));
        STAT.median = median(X(:));
        STAT.stdev = std(X(:));
        STAT.range = [min(X(:)), max(X(:))];
    otherwise
        STAT.mean = mean(X, dim);
        STAT.median = median(X, dim);
        STAT.stdev = std(X, [], dim);
        STAT.range = cat(dim, min(X, [], dim), max(X, [], dim));
end
end
