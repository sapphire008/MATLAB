%draw ellipse
phi=pi/3;
theta=1:0.01:4*pi+pi/6;
xc=5;
yc=6;
a=3;
b=9;
X=xc+a*cos(theta)*cos(phi)-b*sin(theta)*sin(phi);
X=X+randn(size(X))/8;
Y=yc+a*cos(theta)*sin(phi)-b*sin(theta)*cos(phi);
Y=Y+randn(size(Y))/8;

A=


plot(X,Y,'o');
hold on;


%%
[semimajor_axis,semiminor_axis,x0,y0,phi2]=ellipse_fit(X,Y);
Xp=x0+semimajor_axis*cos(theta)*cos(phi2)-semiminor_axis*sin(theta)*sin(phi2);
Yp=y0+semimajor_axis*cos(theta)*sin(phi2)-semiminor_axis*cos(theta)*sin(phi2);

plot(Xp,Yp,'k');
hold off;

%%
% 
% Xm=mean(X(:));
% X=X-Xm;
% Ym=mean(Y(:));
% Y=Y-Ym;
% 
% s=max(max(hypot(X',Y')),eps);
% X=X/s;
% Y=Y/s;
% Q_mat=[X;Y]*[X;Y]';
% [eigvec,eigval]=eig(Q_mat);
% 
% a_fit=sqrt(max(eigval(1,1),eigval(2,2)));
% b_fit=sqrt(min(eigval(1,1),eigval(2,2)));
% centroid=mean([X;Y],2);
% 
