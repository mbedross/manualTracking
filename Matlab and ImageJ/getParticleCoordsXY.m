function [particleCoords] = getParticleCoordsXY(zCenter, trackTrange)

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
% the trainZrange_index variable. With this image, the user will select eith an in-
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
% For a detailed list and description of variables please see the read me
% file 'README.md'
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global n
global ds
global zSorted

% First import mean subtracted and filtered reconstructions into an iamge
addpath('C:\Users\manu\Documents\MATLAB\Tracking\Thesis_object_tracking_software\supportingAlgorithms');

dsIndex = getDSindex(zCenter, trackTrange(1))-1; % -1 because the for loop is not 0 indexed
particleCoords = zeros(trackTrange(2)-trackTrange(1)+1, 4);
for i = 1 : trackTrange(2)-trackTrange(1)+1
    h1 = figure(1);
    img = readimage(ds, dsIndex + i);
    imagesc(img)
    title(sprintf('Please select a single particle you wish to track. %0.2f z-plane is shown at frame %d of %d. Press ENTER when youve selected the single particle', zSorted(zCenter), i, trackTrange(2)-trackTrange(1)+1))
    axis equal
    colormap gray
    if i == 1
        axis([0 n(1) 0 n(2)])
        uiwait(msgbox('Find a particle you would like to track and zoom in on it as needed. Press OK when ready to proceed'));
        ax = gca;
        xAxis = ax.XLim;
        yAxis = ax.YLim;
    else
        axis([xAxis(1) xAxis(2) yAxis(1) yAxis(2)])
    end
    [X,Y] = getpts;
    if isempty(X)
        if i==1
            break
        end
    else
        x = floor(mean(X));
        y = floor(mean(Y));
        particleCoords(i,:) = [x, y, zCenter, trackTrange(1)+i-1]; % -1 because i is not 0 indexed
    end
end
close(h1)

% Remove all rows that contain zeros (empty)
particleCoords = particleCoords(any(particleCoords,2),:);