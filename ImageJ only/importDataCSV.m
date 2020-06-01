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
zSpacing = 1;                          % Conversion from koala units to um
axisLabelSize = 16;
viewAz = 45;
viewEl = 30;
saveFile = 1;                            % Save new excel files?

if saveFile
    trackDir = fullfile(masterFilePath, 'Tracks');
    mkdir(trackDir)
end

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
    zNaN = rmmissing(z);
    if length(zNaN)>1
        [zFilled] = fillmissing(z, 'linear', 'SamplePoints', time, 'EndValues', 'extrap');
    else
        if isempty(zNaN)
            zFilled = zeros(size(z));
        else
            zFilled = ones(size(z)).*zNaN;
        end
    end
     

	% Convert time from frame numbers into seconds
	%time = fNumbers(time);
	time = eTime(time);

	% Convert X and Y coordinates to microns
	X = x.*pixelPitch;
    Y = y.*pixelPitch;
    Z = zFilled.*zSpacing;
    
    % Combine xyzt coordinates into one trajectory variable
    finalData = [X, Y, Z, sort(time)];
    
    % Apply Spline filtering to smooth data
    finalData(:,1) = fnval(csaps(finalData(:,4),finalData(:,1)),finalData(:,4));
    finalData(:,2) = fnval(csaps(finalData(:,4),finalData(:,2)),finalData(:,4));
    
    
    % Calculate Velocities
    diffx = diff(finalData(:,1));
    diffy = diff(finalData(:,2));
    diffz = diff(finalData(:,3));
    difft = diff(finalData(:,4));
    vX = diffx./difft;
    vY = diffy./difft;
    vZ = diffz./difft;
    velZ = [velZ vZ'];
    
    magVel = zeros(size(vX));
    for ii = 1 : length(vX)
        magVel(ii) = norm([vX(ii) vY(ii) vZ(ii)]);
    end
    meanSpeed(i) = mean(magVel);
    disp(meanSpeed(i))
    
    % Calculate turn angles
    theta = zeros(size(time));
    for jj = 1:length(difft)-1
        AB = [diffx(jj) diffy(jj) diffz(jj)];
        BC = [diffx(jj+1) diffy(jj+1) diffz(jj+1)];
        if norm(AB)==0 || norm(BC)==0
            theta(jj) = 0;
        else
            theta(jj) = acos(dot(AB, BC)/(norm(AB)*norm(BC)));
            if theta(jj) < 0.01
                theta(jj) = 0;
            end
        end
    end
    theta = abs(theta);
    angles = [angles; theta];
    turningAngle{i,:} = theta.*(180/pi);
    velocities{i,:} = [vX vY vZ];
    speed{i,:} = magVel;
	tracks{i,:} = finalData;
    
    % Analyze Angle data
    [peaks, locs] = findpeaks(theta.*(180/pi),sort(finalData(:,4)));
    % three reginems to analyze
    % 1. 0-45 degrees
    % 2. 45-135 degrees
    % 3. 135-180 degrees
    locs1 = locs;
    locs2 = locs;
    locs3 = locs;
    locs1(peaks>=45) = [];
    locs2(peaks>=135 | peaks<45)=[];
    locs3(peaks<135)=[];
    diff1 = diff(locs1);
    diff2 = diff(locs2);
    diff3 = diff(locs3);
    avg1 = mean(diff1);
    std1 = std(diff1);
    avg2 = mean(diff2);
    std2 = std(diff2);
    avg3 = mean(diff3);
    std3 = std(diff3);
    reOrientTimeScale_0_45{i,:} = [avg1 std1];
    reOrientTimeScale_45_135{i,:} = [avg2 std2];
    reOrientTimeScale_135_180{i,:} = [avg3 std3];
    
    
    figure(i)
    histogram(theta.*(180/pi), 60, 'Normalization','probability')
    ylabel('Relative Frequency [-]', 'FontSize', axisLabelSize)
    xlabel('Turning Angle [degrees]', 'FontSize', axisLabelSize)
    axis([0 180 0 inf])
    path = fullfile(masterFilePath, sprintf('particle%05d',i));
    savefig(path)
    print(path,'-dpng','-r350')
    
    figure(i)
    plot(finalData(:,4),theta.*(180/pi))
    ylabel('Turning Angle [degrees]')
    xlabel('Time [s]')
    axis([-inf inf 0 180])
    path = fullfile(masterFilePath, sprintf('particle%05d_anglePlot',i));
    savefig(path)
    print(path,'-dpng','-r350')
    
    
    figure(Ntracks+1)
    color_line3(finalData(:,1), finalData(:,2), finalData(:,3), finalData(:,4),'LineWidth', 2);
    hold on;
    
    if saveFile
        fileName = fullfile(trackDir, sprintf('particle%05d.csv',i));
        writematrix(finalData, fileName)
    end
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
path = fullfile(masterFilePath, 'trajectories');
savefig(path)
print(path,'-dpng','-r1000')

save(fullfile(masterFilePath,'tracks.mat'), 'tracks', 'velocities',...
    'turningAngle', 'speed', 'meanSpeed', 'reOrientTimeScale_0_45',...
    'reOrientTimeScale_45_135', 'reOrientTimeScale_135_180')


