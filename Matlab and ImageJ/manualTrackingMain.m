function [points] = manualTrackingMain(holoDir, type2track)

global masterDir
global zSorted
global n
global type
global ds
global tNF
global zNF
global particleSize
global zDepth
masterDir = holoDir;

addpath('C:\Users\manu\Documents\MATLAB\Tracking\Thesis_object_tracking_software\preProcessing')

% User inputs
particleSize = 30;
numZplanes = 200;
zConversion = 25;          % How many microns is 1 cm in Koala units?
zSeparation = 0.025;         % This is the physical separation between z-slices (in microns)
n = [2048 2048];
pixelPitchX = 360/2048;    % Size of each pixel in the image x direction (in microns)
pixelPitchY = pixelPitchX; % Size of each pixel in the image y direction (in microns)
voxelPitch = [pixelPitchX pixelPitchY zSeparation];
type = type2track;
trackPath = fullfile(holoDir, 'Manual Tracks');
trackDir = dir(trackPath);
Ntracks = length(trackDir)-2;           % minus 2 because of '.' and '..'
%zDepth = 6*ceil((particleSize*pixelPitchX)/zSeparation)+1; % number of z-slices to use while tracking
zDepth = 201;


filePath = fullfile(masterDir, 'MeanStack', type);
[zSorted] = zSteps(filePath);
zNF = length(zSorted);

% First, look through the master directory for duplicate holograms
[dupes] = findDuplicates(masterDir);
fNumbers = 0:length(dupes)-1;
% remove duplicate from times
fNumbers(logical(dupes)) = [];
tNF = length(fNumbers);

% Create a datastore of images
[ds] = createImgDataStore();

[FileName, path] = uiputfile('*.mat','Choose Where to Save Data file');
filename = fullfile(path, FileName);

points = cell(1,1);
points_all = cell(numZplanes,1);
numParticle = 0;
for i = 1 : Ntracks
    % Import the XY data from imageJ's Manual Tracking plugin
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
    z = rmmissing(z);
    
    % Convert time from frame numbers into seconds
    time = fNumbers(time)';
    zCenter = ones(size(time)).*find(zSorted == round(mean(z),1));
    tempCoordsxy = [x y zCenter time];
    tempCoordsxyz = getParticleCoordsZ(tempCoordsxy);
    tempCoordsxyz(:,3) = zSorted(tempCoordsxyz(:,3));
    numParticle = numParticle + 1;
    tempCoordsxyz(:,1:3) = tempCoordsxyz(:,1:3)*[voxelPitch(1), 0, 0; 0, voxelPitch(2), 0; 0, 0, zConversion];
    points{numParticle,1} = tempCoordsxyz;
    % Save workspace
    if exist(filename, 'file') == 2
        save(filename, '-append')
    else
        save(filename)
    end
    track = questdlg('Would you like to track another particle?', 'Track Another Particle?', 'Yes','No','Yes');
    if strcmp(track, 'No')
        break
    end
    if ~isempty(points{1,1})
        points_all{i,1} = points;    % These units are all in microns, time is still in index units
    end
    points = cell(1,1);
end

% Replace indexed time values with units of seconds
[points] = replaceTime(points_all);