function [points] = replaceTime(inputPoints)

global masterDir

% Import timestamp file to convert to seconds
timeFile = fullfile(masterDir, 'timestamps.txt');
[stamp, timeOfDay, Date, eTime] = textread(timeFile, '%f %s %s %f');
clear timeOfDay Date stamp
eTime = eTime./1000;

points = inputPoints;
for i = 1 : length(inputPoints)
    tempPoints = inputPoints{i,1};
    tempPoints(:,4) = etime(tempPoints(:,4));
    points{i,1} = tempPoints;
end