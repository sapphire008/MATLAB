%by Dr. Rex Cheung, mainline PA, Spring 2012.
%email: cheung.r100@gmail.com; tel: 215-287-2501
%This program overlays to fixedimage on movingimage to create a landmarks 
%file for landmark-based warping:
%1. Select a point on fixedimage, and a point on movingimage.
%2. Repeat this to the number of points you would like to have for warping.
%3. Call this program to store the odd-numbered cursor_info (contains x and y coordinates)
%   to fixedlandmarks.txt and similarly for the movinglandmarks.txt
%This is a bug-fix of an earlier ImageOverlay

function Ih = ImageOverlay(fixedimage, movingimage, alphavalue)

colormap(gray);
figure(1); h=image(movingimage); hold on;
image(fixedimage,'AlphaData',alphavalue);
title('overlaying movingimage and fixedimage to place fixedlandmarks and movinglandmarks');
