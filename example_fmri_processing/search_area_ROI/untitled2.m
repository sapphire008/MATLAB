rgb = imread('peppers.png');
figure;
imshow(rgb);
I = rgb2gray(rgb);
hold on;
h = imshow(I);%gray image
hold off;

[M,N] = size(I);
block_size = 50;
P = ceil(M/block_size);
Q = ceil(N/block_size);
alpha_data = checkerboard(block_size,P,Q)>0;
alpha_data = alpha_data(1:M,1:N);
set(h, 'AlphaData',alpha_data);