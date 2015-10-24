function out = winsor(x,sd)

% remove the mean from X
me = mean(x);
x = x - me;

% replace the outliers
idx = find(abs(x) > sd * std(x));

x(idx) = sign(x(idx)) * sd * std(x);

    