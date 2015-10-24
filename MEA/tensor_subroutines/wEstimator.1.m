% W estimator
function f = wEstimator(W, x, y, u)
f = bsxfun(@minus,(W(1)^2+W(3)^2)*x.^2 + (W(2)^2+W(4)^2)*y.^2+(W(1)*W(2)+W(3)*W(4))*2*x.*y,u);
f = f(:); f = f(isfinite(f)); %debug %disp(f);
end