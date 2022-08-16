function BW = roiellipse

%ROIELLIPSE Select a draggable and scalable elliptical region of interest (ROI) in an image
%   Use ROIELLIPSE to select an elliptical region of interest within an
%   image. ROIELLIPSE returns a binary image that you can use as a mask for
%   masked filtering.
%   
%   BW = ROIELLIPSE creates an interactive elliptical tool, associated with 
%   the image displayed in the current figure. You can drag the ellipse interactively 
%   using the mouse, and you can scale the size of the ellipse. When you are
%   done adjusting the ellipse, click on the CONTINUE button on the bottom left
%   of the figure. 
%
%   Written by EUS, May 2015.

uicontrol('Style', 'pushbutton', 'Callback', 'uiresume(gcbf)','String','Continue');
title('Move and scale the ellipse. Press Continue when you are ready...');
h = imellipse(gca,[20 20 10 10]);
uiwait(gcf);
setResizable(h,0);
BW = createMask(h);
