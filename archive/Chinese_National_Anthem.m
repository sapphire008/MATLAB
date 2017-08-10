%%%%%%%%%%%%%%%%%%%%%%%%%% ????????? (Matlab?) %%%%%%%%%%%%%%%%%%%%%%
% ???? ??“??”?? ? ???? ?? ??
% by ???? ???? ? ?% matlab ??? ?? ?? QQ?1296445042 
% ???? ID ?zhangbo0037 
% ?????????? date 2013.03.11 ?

clc,clear all
fs = 44100; dt = 1/fs; f0 = 320; T16 = 0.125;
t16 = [0:dt:T16]; [temp m] = size(t16);
t2 = linspace(0,8*T16,8*m); [temp i] = size(t2);
t4 = linspace(0,4*T16,4*m); [temp j] = size(t4);
t8 = linspace(0,2*T16,2*m); [temp k] = size(t8);
t12 = linspace(0,4/3*T16,4/3*m); [temp l] = size(t12);
% Modification functions
mod2 = sin(pi*t2/t2(end));
mod4 = sin(pi*t4/t4(end));
mod8 = sin(pi*t8/t8(end));
mod12 = sin(pi*t12/t12(end));
mod16 = sin(pi*t16/t16(end));

ScaleTable = [2/3 3/4 5/6 15/16 ...
1 9/8 5/4 4/3 3/2 5/3 9/5 15/8 ...
2 9/4 5/2 8/3 3 10/3 15/4 4 ...
1/2 9/16 5/8];

do0g = mod2.*cos(2*pi*ScaleTable(21)*f0*t2);re0g = mod2.*cos(2*pi*ScaleTable(22)*f0*t2);mi0g = mod2.*cos(2*pi*ScaleTable(23)*f0*t2);fa0g = mod2.*cos(2*pi*ScaleTable(1)*f0*t2);so0g = mod2.*cos(2*pi*ScaleTable(2)*f0*t2);la0g = mod2.*cos(2*pi*ScaleTable(3)*f0*t2);ti0g = mod2.*cos(2*pi*ScaleTable(4)*f0*t2);
do1g = mod2.*cos(2*pi*ScaleTable(5)*f0*t2);re1g = mod2.*cos(2*pi*ScaleTable(6)*f0*t2);mi1g = mod2.*cos(2*pi*ScaleTable(7)*f0*t2);fa1g = mod2.*cos(2*pi*ScaleTable(8)*f0*t2);so1g = mod2.*cos(2*pi*ScaleTable(9)*f0*t2);la1g = mod2.*cos(2*pi*ScaleTable(10)*f0*t2);% tb1g = mod2.*cos(2*pi*ScaleTable(11)*f0*t2);ti1g = mod2.*cos(2*pi*ScaleTable(12)*f0*t2);
do2g = mod2.*cos(2*pi*ScaleTable(13)*f0*t2);re2g = mod2.*cos(2*pi*ScaleTable(14)*f0*t2);mi2g = mod2.*cos(2*pi*ScaleTable(15)*f0*t2);fa2g = mod2.*cos(2*pi*ScaleTable(16)*f0*t2);so2g = mod2.*cos(2*pi*ScaleTable(17)*f0*t2);la2g = mod2.*cos(2*pi*ScaleTable(18)*f0*t2);ti2g = mod2.*cos(2*pi*ScaleTable(19)*f0*t2);
do3g = mod2.*cos(2*pi*ScaleTable(20)*f0*t2);
I = zeros(1,i);

do0f = mod4.*cos(2*pi*ScaleTable(21)*f0*t4);re0f = mod4.*cos(2*pi*ScaleTable(22)*f0*t4);mi0f = mod4.*cos(2*pi*ScaleTable(23)*f0*t4);fa0f = mod4.*cos(2*pi*ScaleTable(1)*f0*t4);so0f = mod4.*cos(2*pi*ScaleTable(2)*f0*t4);la0f = mod4.*cos(2*pi*ScaleTable(3)*f0*t4);ti0f = mod4.*cos(2*pi*ScaleTable(4)*f0*t4);
do1f = mod4.*cos(2*pi*ScaleTable(5)*f0*t4);re1f = mod4.*cos(2*pi*ScaleTable(6)*f0*t4);mi1f = mod4.*cos(2*pi*ScaleTable(7)*f0*t4);fa1f = mod4.*cos(2*pi*ScaleTable(8)*f0*t4);so1f = mod4.*cos(2*pi*ScaleTable(9)*f0*t4);la1f = mod4.*cos(2*pi*ScaleTable(10)*f0*t4);% tb1f = mod4.*cos(2*pi*ScaleTable(11)*f0*t4);ti1f = mod4.*cos(2*pi*ScaleTable(12)*f0*t4);
do2f = mod4.*cos(2*pi*ScaleTable(13)*f0*t4);re2f = mod4.*cos(2*pi*ScaleTable(14)*f0*t4);mi2f = mod4.*cos(2*pi*ScaleTable(15)*f0*t4);fa2f = mod4.*cos(2*pi*ScaleTable(16)*f0*t4);so2f = mod4.*cos(2*pi*ScaleTable(17)*f0*t4);la2f = mod4.*cos(2*pi*ScaleTable(18)*f0*t4);ti2f = mod4.*cos(2*pi*ScaleTable(19)*f0*t4);
do3f = mod4.*cos(2*pi*ScaleTable(20)*f0*t4);
J = zeros(1,j);

do0e = mod8.*cos(2*pi*ScaleTable(21)*f0*t8);re0e = mod8.*cos(2*pi*ScaleTable(22)*f0*t8);mi0e = mod8.*cos(2*pi*ScaleTable(23)*f0*t8);fa0e = mod8.*cos(2*pi*ScaleTable(1)*f0*t8);so0e = mod8.*cos(2*pi*ScaleTable(2)*f0*t8);la0e = mod8.*cos(2*pi*ScaleTable(3)*f0*t8);ti0e = mod8.*cos(2*pi*ScaleTable(4)*f0*t8);
do1e = mod8.*cos(2*pi*ScaleTable(5)*f0*t8);re1e = mod8.*cos(2*pi*ScaleTable(6)*f0*t8);mi1e = mod8.*cos(2*pi*ScaleTable(7)*f0*t8);fa1e = mod8.*cos(2*pi*ScaleTable(8)*f0*t8);so1e = mod8.*cos(2*pi*ScaleTable(9)*f0*t8);la1e = mod8.*cos(2*pi*ScaleTable(10)*f0*t8);% tb1e = mod8.*cos(2*pi*ScaleTable(11)*f0*t8);ti1e = mod8.*cos(2*pi*ScaleTable(12)*f0*t8);
do2e = mod8.*cos(2*pi*ScaleTable(13)*f0*t8);re2e = mod8.*cos(2*pi*ScaleTable(14)*f0*t8);mi2e = mod8.*cos(2*pi*ScaleTable(15)*f0*t8);fa2e = mod8.*cos(2*pi*ScaleTable(16)*f0*t8);so2e = mod8.*cos(2*pi*ScaleTable(17)*f0*t8);la2e = mod8.*cos(2*pi*ScaleTable(18)*f0*t8);ti2e = mod8.*cos(2*pi*ScaleTable(19)*f0*t8);
do3e = mod8.*cos(2*pi*ScaleTable(20)*f0*t8);
K = zeros(1,k);
do0d = mod12.*cos(2*pi*ScaleTable(21)*f0*t12);re0d = mod12.*cos(2*pi*ScaleTable(22)*f0*t12);mi0d = mod12.*cos(2*pi*ScaleTable(23)*f0*t12);fa0d = mod12.*cos(2*pi*ScaleTable(1)*f0*t12);so0d = mod12.*cos(2*pi*ScaleTable(2)*f0*t12);la0d = mod12.*cos(2*pi*ScaleTable(3)*f0*t12);ti0d = mod12.*cos(2*pi*ScaleTable(4)*f0*t12);
do1d = mod12.*cos(2*pi*ScaleTable(5)*f0*t12);re1d = mod12.*cos(2*pi*ScaleTable(6)*f0*t12);mi1d = mod12.*cos(2*pi*ScaleTable(7)*f0*t12);fa1d = mod12.*cos(2*pi*ScaleTable(8)*f0*t12);so1d = mod12.*cos(2*pi*ScaleTable(9)*f0*t12);la1d = mod12.*cos(2*pi*ScaleTable(10)*f0*t12);% tb1d = mod12.*cos(2*pi*ScaleTable(11)*f0*t12);ti1d = mod12.*cos(2*pi*ScaleTable(12)*f0*t12);
do2d = mod12.*cos(2*pi*ScaleTable(13)*f0*t12);re2d = mod12.*cos(2*pi*ScaleTable(14)*f0*t12);mi2d = mod12.*cos(2*pi*ScaleTable(15)*f0*t12);fa2d = mod12.*cos(2*pi*ScaleTable(16)*f0*t12);so2d = mod12.*cos(2*pi*ScaleTable(17)*f0*t12);la2d = mod12.*cos(2*pi*ScaleTable(18)*f0*t12);ti2d = mod12.*cos(2*pi*ScaleTable(19)*f0*t12);
do3d = mod12.*cos(2*pi*ScaleTable(20)*f0*t12);
L = zeros(1,l);
do0s = mod16.*cos(2*pi*ScaleTable(21)*f0*t16);re0s = mod16.*cos(2*pi*ScaleTable(22)*f0*t16);mi0s = mod16.*cos(2*pi*ScaleTable(23)*f0*t16);fa0s = mod16.*cos(2*pi*ScaleTable(1)*f0*t16);so0s = mod16.*cos(2*pi*ScaleTable(2)*f0*t16);la0s = mod16.*cos(2*pi*ScaleTable(3)*f0*t16);ti0s = mod16.*cos(2*pi*ScaleTable(4)*f0*t16);
do1s = mod16.*cos(2*pi*ScaleTable(5)*f0*t16);re1s = mod16.*cos(2*pi*ScaleTable(6)*f0*t16);mi1s = mod16.*cos(2*pi*ScaleTable(7)*f0*t16);fa1s = mod16.*cos(2*pi*ScaleTable(8)*f0*t16);so1s = mod16.*cos(2*pi*ScaleTable(9)*f0*t16);la1s = mod16.*cos(2*pi*ScaleTable(10)*f0*t16);% tb1s = mod16.*cos(2*pi*ScaleTable(11)*f0*t16);ti1s = mod16.*cos(2*pi*ScaleTable(12)*f0*t16);
do2s = mod16.*cos(2*pi*ScaleTable(13)*f0*t16);re2s = mod16.*cos(2*pi*ScaleTable(14)*f0*t16);mi2s = mod16.*cos(2*pi*ScaleTable(15)*f0*t16);fa2s = mod16.*cos(2*pi*ScaleTable(16)*f0*t16);so2s = mod16.*cos(2*pi*ScaleTable(17)*f0*t16);la2s = mod16.*cos(2*pi*ScaleTable(18)*f0*t16);ti2s = mod16.*cos(2*pi*ScaleTable(19)*f0*t16);
do3s = mod16.*cos(2*pi*ScaleTable(20)*f0*t16);
M = zeros(1,m);

v1 = [do0e L mi0e so0e so0e M,la0f M so0f M,mi0e M do0e so0d so0d so0d M,mi0f do0f L,so0d so0d so0d so0d so0d so0d,do0f K M so0e,do1f J do1e,do1e M do1e so0d M la0d ti0d M,do1f do1f,J mi1e M do1d re1d mi1d M,so1f L so1f M,mi1e M mi1e do1e M mi1e,so1e M mi1e re1f M,re1f J M la1f M so1f M,re1f M mi1f M,so1e M mi1e K so1e,M mi1e re1d mi1d do1e K,mi1f J M so1e M la1e do1e do1e M,mi1e M mi1e so1e so1e M,re1e re1e re1e la1f ,re1f J so1e,do1f J do1e,mi1f J mi1e,so1f J do1e M mi1e so1e M so1e M,la1f M so1f,L mi1e M do1e so1e so1e so1e,mi1e K do1e J,so1f do1f K mi1e L do1e so1e so1e so1e,mi1e J do1e J,so1f do1f,K so1f do1f,K so1f do1f,do1f];

s = v1;s = s/max(s);sound(s,fs);clc