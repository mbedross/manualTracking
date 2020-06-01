function [finalData]=importDataCSV(masterFilePath)

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
close all

% Define the filePath to where the data is stored
trackPath = fullfile(masterFilePath, 'Manual Tracks');
trackDir = dir(trackPath);
Ntracks = length(trackDir)-2;           % minus 2 because of '.' and '..'
pixelPitch = 360/2048;                  % Pixel pitch in microns
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
angles = zeros(0);
meanSpeed = zeros(1,Ntracks);
% Loop through all tracks and import/condition and store in cell array
for i = 1 : Ntracks
	fileName = fullfile(trackPath, trackDir(i+2).name);
    disp(fileName)
	data = importdata(fileName);
    x = data.data(:,3);
    y = data.data(:,4);
    time = data.data(:,2);
% x = data(:,1);
% y = data(:,2);
% time = data(:,3);
    
    % Interpolate/extrapolate z coordinate values
    [time, ia, ic] = unique(time);
    x = x(ia);
    y = y(ia);
     

	% Convert time from frame numbers into seconds
	%time = fNumbers(time);
	time = eTime(time);

	% Convert X and Y coordinates to microns
	X = x.*pixelPitch;
    Y = y.*pixelPitch;
    
    % Combine xyzt coordinates into one trajectory variable
    finalData = [X, Y, time];
    
    % Calculate Velocities
    diffx = diff(finalData(:,1));
    diffy = diff(finalData(:,2));
    difft = diff(finalData(:,3));
    vX = diffx./difft;
    vY = diffy./difft;
    
    magVel = zeros(size(vX));
    for ii = 1 : length(vX)
        magVel(ii) = norm([vX(ii) vY(ii)]);
    end
    meanSpeed(i) = mean(magVel);
    disp(meanSpeed(i))
    
    % Calculate turn angles
    theta = zeros(size(time));
    for jj = 1:length(difft)-1
        AB = [diffx(jj) diffy(jj)];
        BC = [1 0];   % This is for absolute angle within FOV
        %BC = [diffx(jj+1) diffy(jj+1)];
        if norm(AB)==0 || norm(BC)==0
            theta(jj) = 0;
        else
            theta(jj) = acos(dot(AB, BC)/(norm(AB)*norm(BC)));
            %if theta(jj) < 0.01
            %    theta(jj) = 0;
            %end
            % which quadrant is this headed?
            if (AB(1)<0 && AB(2)<0) || (AB(1)>0 && AB(2)<0) % Third or Fourth Quandrant
                theta(jj) = 2*pi-theta(jj);
            end
        end
    end
    %theta = abs(theta);
    theta(theta==0)=[];
    theta(theta==pi/2)=[];
    theta(theta==pi)=[];
    angles = [angles; theta];
    turningAngle{i,:} = theta.*(180/pi);
    velocities{i,:} = [vX vY];
    speed{i,:} = magVel;
	tracks{i,:} = finalData;
    
%     figure(i)
%     histogram(theta.*(180/pi), 60, 'Normalization','probability')
%     ylabel('Relative Frequency [-]', 'FontSize', axisLabelSize)
%     xlabel('Turning Angle [degrees]', 'FontSize', axisLabelSize)
%     axis([0 180 0 inf])
%     path = fullfile(masterFilePath, sprintf('particle%05d',i));
%     savefig(path)
%     print(path,'-dpng','-r1000')
    
    figure(Ntracks+1)
    %color_line3(finalData(:,1), finalData(:,2), finalData(:,3), finalData(:,4),'LineWidth', 2);
    scatter(finalData(:,1),-1.*finalData(:,2),[],finalData(:,3)); axis([0 360 -360 0])
    %hold on;
end

% view(viewAz, viewEl)
% axis equal
% colormap jet
% grid on
% xlabel('Microns [\mum]', 'FontSize', axisLabelSize)
% ylabel('Microns [\mum]', 'FontSize', axisLabelSize)
% h = colorbar;
% ylabel(h, 'Time [s]', 'FontSize', axisLabelSize)
% path = fullfile(masterFilePath, 'trajectories');
% savefig(path)
% print(path,'-dpng','-r1000')
% h2 = figure(2);
% histogram(angles, 60, 'Normalization','probability')
% ylabel('Relative Frequency [-]', 'FontSize', axisLabelSize)
% xlabel('Turning Angle [degrees]', 'FontSize', axisLabelSize)

angles = angles-pi/4;
polarhistogram(angles, 20)
pax = gca;
pax.FontSize = 16;
thetaticks([0 45 90 135 180 225 270 315])
thetaticklabels({'E', 'NE', 'N','NW', 'W', 'SW', 'S', 'SE'})
rticks([])
rticklabels({})
print(fullfile(masterFilePath,'polarHist.png'),'-dpng','-r1000')
disp('...Total Mean and STD speed is...')
absMean = mean(meanSpeed)
absSTD = std(meanSpeed)
save(fullfile(masterFilePath,'tracks.mat'), 'tracks', 'velocities', 'turningAngle', 'speed', 'meanSpeed', 'angles')


