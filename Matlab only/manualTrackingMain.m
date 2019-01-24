function [points] = manualTrackingMain(holoDir, type2track)

global masterDir
global zSorted
global n
global type
global ds
global zDepth
global tNF
global zNF
global particleSize
masterDir = holoDir;

% User inputs
particleSize = 30;
trackZrange = [-15, 25];
trackTrange = [0, 10];     % for example 00034.tiff would be 34
numZplanes = 10;
zConversion = 25;          % How many microns is 1 cm in Koala units?
zSeparation = 2.5;         % This is the physical separation between z-slices (in microns)
n = [2048 2048];
pixelPitchX = 350/2048;    % Size of each pixel in the image x direction (in microns)
pixelPitchY = pixelPitchX; % Size of each pixel in the image y direction (in microns)
pixelPitch = pixelPitchX;
voxelPitch = [pixelPitchX pixelPitchY zSeparation];
zDepth = 2*ceil((particleSize*pixelPitch)/zSeparation)+1; % number of z-slices to use while tracking
zInterval = diff(trackZrange)/numZplanes;
type = type2track;


filePath = fullfile(masterDir, 'Stack', type);
[zSorted] = zSteps(filePath);
zNF = length(zSorted);

% First, look through the master directory for duplicate holograms
[dupes] = findDuplicates(masterDir);
times = 0:length(dupes)-1;
% remove duplicate from times
times(logical(dupes)) = [];
tNF = length(times);
trackTrange = [find(times == trackTrange(1)) find(times == trackTrange(2))];

% Create a datastore of images
[ds] = createImgDataStore();

[FileName, path] = uiputfile('*.mat','Choose Where to Save Data file');
filename = fullfile(path, FileName);

points = cell(1,1);
points_all = cell(numZplanes,1);
for i = 1 : numZplanes
    if i == 1
        zCenter = find(zSorted == trackZrange(1)+zInterval*i/2);
    else
        zCenter = find(zSorted == trackZrange(1)+(zInterval*(i-1)+zInterval/2));
    end
    % Ask user to select coordinates with particles in the FOV
    trainLock = 1;
    numParticle = 0;
    while trainLock
        % Get the bacteria locations in amplitude
        tempCoordsxy = getParticleCoordsXY(zCenter, trackTrange);
        if isempty(tempCoordsxy)
          break  
        end
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
    end
    if ~isempty(points{1,1})
        points_all{i,1} = points;    % These units are all in microns, time is still in index units
    end
    points = cell(1,1);
end

% Replace indexed time values with units of seconds
[points] = replaceTime(points_all);