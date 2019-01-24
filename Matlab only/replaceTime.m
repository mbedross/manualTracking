function [points] = replaceTime(inputPoints)

global masterDir

% Import timestamp file to convert to seconds
timeFile = fullfile(masterDir, 'timestamps.txt');
[stamp, timeOfDay, Date, timeMS] = textread(timeFile, '%f %s %s %f');
clear timeOfDay Date stamp
timeMS = timeMS./1000;
numParticle = 0;

for i = 1 : length(inputPoints)
    tempPoints = inputPoints{i,1};
    if ~isempty(tempPoints)
        for j  = 1 : length(tempPoints)
            newTempPoints = tempPoints{j,1};
            newTempPoints(:,4) = timeMS(newTempPoints(:,4));
            points{numParticle+1,1} = newTempPoints;
            numParticle = numParticle+1;
        end
    end
end