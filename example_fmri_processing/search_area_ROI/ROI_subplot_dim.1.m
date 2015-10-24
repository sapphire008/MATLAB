function subplot_size = ROI_subplot_dim(numplots)
%numplots = 16;

% find nearest square
nearest_set.square.upper = ceil(sqrt(numplots))^2;
nearest_set.square.lower = floor(sqrt(numplots))^2;
%find nearest N x (N+k) composite numbers
NM = (nearest_set.square.lower+1):1:(nearest_set.square.upper-1);
nearest_set.NM = NM(~isprime(NM) & NM>=numplots);
% inspect which number of nearest_set.NM has factors with smallest
% difference
diff_vect = zeros(1,length(nearest_set.NM));
for n = 1:length(diff_vect)
    diff_vect(n) = abs(diff(factor_a_num(nearest_set.NM(n))));
end
[~,IND] = min(diff_vect);
NM_size = nearest_set.NM(IND);%find the number that has the smallest factor difference

if isempty(NM_size)
    subplot_size = [sqrt(nearest_set.square.upper),sqrt(nearest_set.square.upper)];
else
    subplot_size = factor_a_num(NM_size);
end
end

function min_diff_factors = factor_a_num(num)
%factor a number so that the difference between the factors is minimized
if isprime(num)
    min_diff_factors = [1 num];
else
    tmp = 2:(num-1);
    factor1_set = repmat(num,1,length(tmp))./(tmp);
    factor2_set = tmp(round(factor1_set) == factor1_set);
    factor1_set = factor1_set(round(factor1_set) == factor1_set);
    factor_set = [factor1_set',factor2_set'];
    [~,IND] = min(abs(factor1_set'-factor2_set'));
    min_diff_factors = factor_set(IND,:);
end
end