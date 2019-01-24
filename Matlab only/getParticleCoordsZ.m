function [particleCoords] = getParticleCoordsZ(xyCoords)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Manuel Bedrossian, Caltech
% Date Created: 2018.10.10
%
% This function is intended to display a sequence of images to a user who
% is to select particles of interest in order the Machine Learning Algorithm
% to be trained.
%
% The user will first be shown a single reconstruction a the first time point
% specified in the trainTrange variable, at the center z-plane specified by
% the trainZrange variable. With this image, the user will select eith an in-
% focus or out of foucs particle. (Note: Choose a single partlice)
%
% Next the user will be presented the next chronological image (same z-plane
% but the next image in the time sequence). The user will be asked to then
% select the same particle at this time point.
%
% The user will be asked to repeat this step for a total of 10 time points.
%
% Finally, the user will then be displayed the XZ and YZ cross sections of
% the particles they selected (in order of when they were selected). The
% user will be asked to then locate the particle in the z-direction.
%
% The user will then be asked if they wish to select a new particle. A total
% three particles is required to generate a statisitically significant
% amount of training data.
%
% Although this function is meant to perform tracking in z, the input variable
% contains z values of the approximate z location of the particle
%
% For a detailed list and description of variables please see the read me
% file 'README.md'
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global particleSize
global zDepth
global ds

% First import mean subtracted and filtered reconstructions into an iamge
addpath('./supportingAlgorithms');

% The range of y values to plot
yRange = -1*particleSize:particleSize;
Img = zeros(length(yRange), length(yRange), zDepth);

particleCoords = xyCoords;
xzSlice = zeros(zDepth, length(yRange));
% Loop through all time points for this particle
for t = 1 : size(xyCoords,1)
	xCoord = xyCoords(t,1);
	yCoord = xyCoords(t,2);
	%Assemble an XZ slice of the particle at a particular time
	currentZ = zeros(1, zDepth);
	for i = 0 : zDepth - 1
		currentZ(i+1) = xyCoords(t,3)-(zDepth-1)/2 + i;
		tempDSindex = getDSindex(currentZ(i+1), xyCoords(t,4));
		img = readimage(ds, tempDSindex);
		xzSlice(i+1,:) = img(yCoord+yRange(1):yCoord+yRange(end), xCoord);
        Img(:,:,i+1) = img(yCoord+yRange(1):yCoord+yRange(end), xCoord+yRange(1):xCoord+yRange(end));
	end
	% The XZ slice display is scaled 1:15 because of the non-uniform voxel size between the x and z z-direction
	% Show a volumetric view of the particle
    f = figure(2);
    xSlice = (length(yRange)-1)/2;
    ySlice = (length(yRange)-1)/2;
    zSlice = (zDepth-1)/2;
    h = slice(Img, xSlice, ySlice, zSlice);
    colormap gray
    axis off
    shading interp
    
    h1 = figure(1);
    %imshow(xzSlice, [], 'XData', [0 1], 'YData', [0 15]);
    imagesc(xzSlice)
    colormap gray
	title(sprintf('Select the point at which the particle is in focus (the waist of the PSF). Press ENTER when done. Timepoint %d out of %d', t, size(xyCoords,1)))
	[X,Z] = getpts;
    z = floor(mean(Z));
	particleCoords(t,3) = currentZ(z);
end
close all