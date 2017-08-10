X = [];
xData = -5:.1:5;
for i = 1:101
    for j = 1:101
        X(end + 1, 1:2) = [xData(i) xData(j)];
    end
end
mu = [0 0];
sigma = [1 0; 0 3];
theta = pi/2;
R = [cos(theta) -sin(theta); sin(theta) cos(theta)];
sigma = R^-1*sigma*R;
p = mvnpdf(X,mu,sigma);

counter =1;
for i = 1:101
    for j = 1:101
        Y(i,j) = p(counter);
        counter = counter+1;
    end
end

figure, surface(xData, xData, Y);
axis tight
