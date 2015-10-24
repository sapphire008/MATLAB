function XY_NN = generate_nearest_neighbor_coord(NN, XY_NN)
if nargin<2, XY_NN = []; end
if numel(NN) == 1, NN = 1:NN; end
for n = NN
    XY_NN = cat(1,XY_NN,[(0:n)',(n:-1:0)']);
end
end