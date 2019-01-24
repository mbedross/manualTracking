function importDataCSV(masterFilePath)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This function is intended to import all CSV files of manually tracked 
% particles and format them into a cell array where each cell is the xyzt 
% coordinates of an individual particle.
%
% The format of the input CSV files are as follows:
%
% Name: particleXXXXX.csv where XXXXX is a one indexed number 
%       (e.g. the 73rd particle would be 'particle00073'
% Columns: 
% 1st columm is the time frame of the track. This is the numerical
% value of the time point after duplicates have been filtered out, not the
% frame number of the filename! This program will look for duplicates and
% find the correct file time of the the frame
% 
% 2nd column: x coordinates in pixels (must be converted to microns)
% 3rd column: y coordinates in pixels (must be converted to microns)
% 4th column: z coordinate in cm (must be converted/interpolated to
% microns)
% 5th column: image pixel value (not necessary/used here)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

addpath('C:\Users\manu\Documents\MATLAB\Tracking\Thesis_object_tracking_software\preProcessing');

% Define the filePath to where the data is stored
trackPath = fullfile(masterFilePath, 'Manual Tracks');
trackDir = dir(trackPath);
Ntracks = length(trackDir)-2;           % minus 2 because of '.' and '..'
pixelPitch = 350/2048;                  % Pixel pitch in microns
zSpacing = 25;                          % Conversion from koala units to um
axisLabelSize = 16;
axisDirection = -1;
viewAz = 45;
viewEl = 30;

% Import timestamp file to convert to seconds
timeFile = fullfile(masterFilePath, 'timestamps.txt');
[stamp, timeOfDay, Date, eTime] = textread(timeFile, '%f %s %s %f');
clear timeOfDay Date stamp
eTime = eTime./1000;

h1 = figure(1);

% Search for duplicate holograms
[dupes] = findDuplicates(masterFilePath);
fNumbers = 1 : length(dupes);
% remove duplicate from times
fNumbers(logical(dupes)) = [];
velZ = zeros(0);
% Loop through all tracks and import/condition and store in cell array
for i = 1 : Ntracks
	fileName = fullfile(trackPath, sprintf('particle%05d.csv', i));
    disp(fileName)
	data = importdata(fileName);
    x = data.data(:,2);
    y = data.data(:,3);
    z = data.data(:,4);
    time = data.data(:,1);
    
    % Interpolate/extrapolate z coordinate values
    [time, ia, ic] = unique(time);
    x = x(ia);
    y = y(ia);
    z = z(ia);
    [zFilled] = fillmissing(z, 'linear', 'SamplePoints', time, 'EndValues', 'extrap');
     

	% Convert time from frame numbers into seconds
	time = fNumbers(time);
	time = eTime(time);

	% Convert X and Y coordinates to microns
	X = x.*pixelPitch;
    Y = y.*pixelPitch;
    
    % Combine xyzt coordinates into one trajectory variable
    finalData = [X, Y, Z, time];
    
    % Calculate Velocities
    diffx = diff(finalData(:,1));
    diffy = diff(finalData(:,2));
    diffz = diff(finalData(:,3));
    difft = diff(finalData(:,4));
    vX = diffx./difft;
    vY = diffy./difft;
    vZ = diffz./difft;
    velZ = [velZ vZ'];
    
    velocities{i,:} = [vX vY vZ];
	tracks{i,:} = finalData;
    
    color_line3(finalData(:,1), finalData(:,2), finalData(:,3), finalData(:,4),'LineWidth', 2);
    hold on;
end

view(viewAz, viewEl)
axis equal
colormap jet
grid on
xlabel('Microns [\mum]', 'FontSize', axisLabelSize)
ylabel('Microns [\mum]', 'FontSize', axisLabelSize)
zlabel('Microns [\mum]', 'FontSize', axisLabelSize)
h = colorbar;
ylabel(h, 'Time [s]', 'FontSize', axisLabelSize)
h2 = figure(2);
histogram(velZ,'Normalization','probability')
ylabel('Relative Frequency [-]', 'FontSize', axisLabelSize)
xlabel('Z-component velocity [\mum/s]', 'FontSize', axisLabelSize)
save(fullfile(masterFilePath,'tracks.mat'), 'tracks', 'velZ')

